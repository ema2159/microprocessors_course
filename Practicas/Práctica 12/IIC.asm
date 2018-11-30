#include registers.inc
;***************************************************
;           DECLARACIÓN DE PARÁMETROS	
;***************************************************
DIR_SEG 	EQU $00
DIR_WR		EQU $D0
DIR_RD		EQU $D1
;***************************************************
;	DEFINICIÓN DE VECTOR DE INTERRUPCIÓN
;***************************************************
		ORG $3E66
		DW OC4_ISR
		ORG $3E40
		DW IIC_ISR
		ORG $3E70
               DW RTI_ISR
;***************************************************
;       DEFINICIÓN DE MENSAJE Y VARIABLES	
;***************************************************
		ORG $1000
T_WRITE_RTC:	DB $00,$57,$11,$06,$23,$11,$18
		ORG $1010
T_READ_RTC:	DS 7
RW_RTC:		DS 1
CONT_RTI:	DS 1
INDEX_RTC:	DS 1
LEDS:       	DS 1
BRILLO:     	DS 1
CONT_DIG:   	DS 1
CONT_TICKS: 	DS 1
DT:         	DS 1
BANDERAS:	DS 1 ;X:X:X:X:X:REFRESH_MAN:REFRESH_FREE:LED_DIR
BCD1:       	DS 1
BCD2:       	DS 1
DIG1:       	DS 1
DIG2:       	DS 1
DIG3:       	DS 1
DIG4:       	DS 1
SEGMENT:    	DB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
CONT_7SEG:  	DS 2
CONT_DELAY: 	DS 1
;***************************************************
;	      PROGRAMA PRINCIPAL
;***************************************************
		ORG $2000
		;Configuración de segmentos y LEDS
		MOVB #$FF,DDRB
		BSET DDRJ,$02
		BCLR PTJ,$02
		MOVB #$00,LEDS
		MOVB #$0F,DDRP
		;Configuración de interrupción Output Compare
		MOVB #$90,TSCR1
		MOVB #$10,TIOS
		MOVB #$03,TSCR2
		MOVB #$01,TCTL1
		MOVB #$10,TIE
		;Configuración de Brillo
		MOVB #100,BRILLO
		;Configuración de IIC
		MOVB #$25,IBFD
		MOVB #$F0,IBCR
		LDS #$3BFF
		CLI 
		MOVB #0,RW_RTC
		MOVB #7,INDEX_RTC
		MOVB #DIR_WR,IBDR
MAIN_LOOP:	TST RW_RTC
		BEQ MAIN_LOOP
		MOVB #$80,CRGINT
		MOVB #$6B,RTICTL
		MOVB #20,CONT_RTI
;MAIN_LOOP2:	BRCLR T_READ_RTC,$01,BLINKON
;		BCLR PORTB,$01	
;		BRA MAINOUT
;BLINKON:	BSET PORTB,$01
MAIN_LOOP2:	MOVB T_READ_RTC+1,BCD1
		MOVB T_READ_RTC+2,BCD2
		BRCLR T_READ_RTC,$01,BLINKON
		BCLR DIG1,$80	
		BCLR DIG4,$80	
		BRA MAINOUT
BLINKON:	BSET DIG1,$80	
		BSET DIG4,$80	
MAINOUT:	BRA MAIN_LOOP2	


IIC_ISR:	BSET IBSR,$02
		TST RW_RTC
		BNE DOSTUFF
		LDAA INDEX_RTC
		CMPA #7
		BEQ DOSTUFF2
		CMPA #6
		BEQ DOSTUFF3
		LDX #T_WRITE_RTC
		LDAA INDEX_RTC
		MOVB A,X IBDR
		INC INDEX_RTC
		BRA OUT  
DOSTUFF2:	MOVB #DIR_SEG,IBDR
		CLR INDEX_RTC
		BRA OUT
DOSTUFF3:	BCLR IBCR,$20
		MOVB #1,RW_RTC
		MOVB #7,INDEX_RTC
		BRA OUT
DOSTUFF:	LDAA INDEX_RTC
		CMPA #7
		BNE IIC_NXT1
		MOVB #DIR_SEG,IBDR
		BRA INC_INDEX
IIC_NXT1:	CMPA #8
		BNE IIC_NXT2
		BSET IBCR,$04	
		MOVB #DIR_RD,IBDR
		BRA INC_INDEX
IIC_NXT2:	CMPA #9
		BNE IIC_NXT3
		BCLR IBCR,$10
		CLR INDEX_RTC
		BCLR IBCR,$04
		LDAA IBDR
		BRA OUT
IIC_NXT3:	LDX #T_READ_RTC
		LDAA INDEX_RTC
		CMPA #5
		BLO IIC_NXT4
		CMPA #6
		BNE IIC_STUFF
		BCLR IBCR,$08
		BSET IBCR,$10
		BCLR IBCR,$20
		MOVB #7,INDEX_RTC
		MOVB IBDR A,X
		BRA OUT
IIC_STUFF:	BSET IBCR,$08
IIC_NXT4:	MOVB IBDR A,X
INC_INDEX:	INC INDEX_RTC
OUT:		RTI 	


		
RTI_ISR:	DEC CONT_RTI
		BNE RTI_OUT
		BSET IBCR,$20
		MOVB #DIR_WR,IBDR
		MOVB #20,CONT_RTI
RTI_OUT:	BSET CRGFLG,$80
		RTI 



OC4_ISR:	LDD CONT_7SEG ;Cargar el contador de refrescamiento de 7SEG
		ADDD #1
		CPD #500     ;Si este ya contó 100mS, refrescar valores
		BNE NOT_RFRSH ;Si no, continuar
		JSR BCD_7SEG
		LDD #0
NOT_RFRSH:	STD CONT_7SEG
		LDAA #100 ;Cargar en a el valor de N para calcular DT
		SUBA BRILLO ;Calcular DT = N-K
		STAA DT 
		LDAA CONT_TICKS 
		CMPA DT ;Si CONT_TICKS=DT, cumplido ciclo de trabajo, bajar señal
		BHI OC_BRIGHT
		MOVB #00,PORTB
OC_BRIGHT:	DEC CONT_TICKS ;Si CONT_TICKS=0, pasar a siguiente display
		BNE OUT_OC 
		MOVB #100,CONT_TICKS  
		BSET PTJ,$02  ;Apagar LEDS
		BRCLR CONT_DIG,$01,OC_NEXT1 ;Si bit 1 de CONT_DIG encendido encender display 1
		MOVB #$F7,PTP
		MOVB DIG3,PORTB
OC_NEXT1:	BRCLR CONT_DIG,$02,OC_NEXT2 ;Si bit 2 de CONT_DIG encendido encender display 2
		MOVB #$FB,PTP
		MOVB DIG4,PORTB
OC_NEXT2:	BRCLR CONT_DIG,$04,OC_NEXT3 ;Si bit 3 de CONT_DIG encendido encender display 3
		MOVB #$FD,PTP
		MOVB DIG1,PORTB
OC_NEXT3:	BRCLR CONT_DIG,$08,OC_NEXT4 ;Si bit 4 de CONT_DIG encendido encender display 4
		MOVB #$FE,PTP
		MOVB DIG2,PORTB
OC_NEXT4:	BRCLR CONT_DIG,$10,CHG_DIG ;Si bit 5 de CONT_DIG encendido encender LEDs
		MOVB #$FF,PTP
		BCLR PTJ,$02
		MOVB LEDS,PORTB
CHG_DIG:	LDAA CONT_DIG 
		CMPA #$10   ;Si se está en LEDs (00010000) pasar a display 1 (00000001)
		BLO SHIFT_DIG
		LDAA #$01
		BRA STORE_DIG
SHIFT_DIG:	LSLA ;Se desplaza CONT_DIG para ir cambiando de display (00000001 = display 1, 00000010 = display 2...)
STORE_DIG:	STAA CONT_DIG
OUT_OC:		LDAA CONT_DELAY
		BEQ DELAY_ZERO
		DEC CONT_DELAY ;Se decrementa CONT_DELAY siempre que no sea cero
DELAY_ZERO:	LDD TCNT ;Ajustar el OC del canal 4
		ADDD #60
		STD TC4
		RTI 





BCD_7SEG:	LDX #SEGMENT ;Cargar la dirección de la tabla SEGMENT en X
		LDAA BCD2   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		MOVB A,X DIG1 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
		LDAA BCD2   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$F0   ;Quedarse solo con el dígito superior
		LSRA 
		LSRA 
		LSRA 
		LSRA 
		CMPA #$F ;Si el dígito en BCD es F, no debe desplegarse
		BNE DIG2_ON
		MOVB #$00,DIG2
		BRA TO_BCD1 
DIG2_ON:	MOVB A,X DIG2 ;Buscar en la tabla la representación de 7 segmentos indicada para el valor		
TO_BCD1:	LDAA BCD1   ;Cargar en valor en BDC de CONT_FREE en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		MOVB A,X DIG3 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
		LDAA BCD1   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$F0   ;Quedarse solo con el dígito superior
		LSRA 
		LSRA 
		LSRA 
		LSRA 
		CMPA #$F ;Si el dígito en BCD es F, no debe desplegarse
		BNE DIG4_ON
		MOVB #$00,DIG4
		BRA OUT_7SEG 
DIG4_ON:	MOVB A,X DIG4 ;Buscar en la tabla la representación de 7 segmentos indicada para el valor
OUT_7SEG:	RTS 
