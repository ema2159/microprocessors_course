#include registers.inc
;******************************
;Configuración de Subrutinas
;******************************
		ORG $3E70
		DW RTI_ISR
		ORG $3E4C
		DW PTH_ISR
		ORG $3E64
		DW OC4_ISR
;******************************
;Estructuras de datos
;******************************
		ORG $1000
CONT_MAN:   DS 1
CONT_FREE:  DS 1
LEDS:       DS 1
BRILLO:     DS 1
CONT_DIG:   DS 1
CONT_TICKS: DS 1
DT:         DS 1
CONT_RTI:	DS 1
BANDERAS:	DS 1
		ORG $1010
BCD1:       DS 1
BCD2:       DS 1
DIG1:       DS 1
DIG2:       DS 1
DIG3:       DS 1
DIG4:       DS 1
SEGMENT:    DB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
CONT_7SEG:  DS 1
CONT_DELAY: DS 1
D2ms:       DS 1
D250us:     DS 1
D40uS:      DS 1
CLEAR_LCD:  DS 1
ADD_L1:     DS 1
ADD_L2:     DS 1
INIDSP:     DS 1
MSG_1		DS 1 

		ORG $2000
;************************************************************************
               ;Programa principal y configuración de hadware
;************************************************************************
		;Configurar interrupción RTI
		MOVB #$31,RTICTL
		BSET CRGINT,$80
		;Configuración de segmentos y LEDS
		MOVB #$FF,DDRB
		BSET DDRJ,$02
		BCLR PTJ,$02
		MOVB #$0F,DDRP
		;Configuración de interrupción de key wakepus
		BSET PIEH,$07
		BCLR PPSH,$07
		;Configuración de interrupción Output Compare
		;MOVB #$10,TIOS
		;MOVB #$90,TSCR1
		;MOVB #$03,TSCR2
		;MOVB #$01,TCTL1
		;MOVB #$10,TIE
		MOVB #$90,TSCR1
		MOVB #$20,TIOS
		MOVB #$03,TSCR2
		MOVB #$04,TCTL1
		MOVB #$20,TIE
		;Habilitar instrucciones mascarables
		CLI
		;Configurar stack
		LDS #$3BFF
		;Inicializar las variables
		CLR BANDERAS
		MOVB #01,LEDS
		MOVB #0,PORTB
		CLR CONT_FREE
		CLR CONT_MAN
		CLR BRILLO
		LDD TCNT
		ADDD #60
		STD TC5
		MOVB #100,CONT_TICKS
		MOVB #1,CONT_DIG
		;Programa principal
		MOVB #$01,LEDS
FIN:		JSR BIN_BCD
		JSR BCD_7SEG
		BRA FIN
;************************************************************************
                             ;Subrutina BIN_BCD:
;Esta subrutina sigue el siguiente algoritmo. Por ejemplo, si se tiene un 
;valor de $2A en hexadecimal (42 en decimal), este se carga en el acumula-
;dor D, y se divide entre 10 mediante el índice X, quedando  $0004  en X, 
;y un  resíduo de $0002 en D, que es lo mismo que $02 en B. Luego se pasa
;el valor de X a A, quedando $04 y se desplaza 4 veces a la izquierda pa-
;ra obtener $40. Finalmente se suman A y B, quedando $42, el valor en BCD
;deseado.  
;************************************************************************
BIN_BCD:	LDAB CONT_MAN ;Cargar CONT_MAN en D
		CLRA ;Limpiar parte alta de D
		LDX #10
		IDIV ;D/X = X, r = D
		TFR X,A ;Pasar X a A
		LSLA ;Desplazar 4 veces
		LSLA
		LSLA
		LSLA
		ABA ;Sumar A y B
		BITA #$F0
		BNE NOT_ZERO ;Si el nibble superior es 0, se le guarda $F
		ORAA #$F0
NOT_ZERO:	STAA BCD1
		LDAB CONT_FREE ;Cargar CONT_FREE en D
		CLRA ;Limpiar parte alta de D
		LDX #10
		IDIV ;D/X = X, r = D
		TFR X,A ;Pasar X a A
		LSLA ;Desplazar 4 veces
		LSLA
		LSLA
		LSLA
		ABA ;Sumar A y B
		BITA #$F0
		BNE NOT_ZERO2 ;Si el nibble superior es 0, se le guarda $F
		ORAA #$F0
NOT_ZERO2:	STAA BCD2 
		RTS
		
;************************************************************************
                        ;Subrutina BCD_7SEG:
;Esta subrutina se encarga de tomar los valores en  las  variales BCD1 y 
;BCD2, y se encarga de colocarlas en las variables  DIG1,  DIG2,  DIG3 y 
;DIG4, codificados para ser desplegados en los displays  de  7 segmentos
;************************************************************************

BCD_7SEG:	LDX #SEGMENT ;Cargar la dirección de la tabla SEGMENT en X
		LDAA BCD1   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		MOVB A,X DIG1 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
		LDAA BCD1   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$F0   ;Quedarse solo con el dígito superior
		LSRA
		LSRA
		LSRA
		LSRA
		CMPA #$F ;Si el dígito en BCD es F, no debe desplegarse
		BNE DIG2_ON
		MOVB #$00,DIG2
		BRA TO_BCD2 
DIG2_ON:	MOVB A,X DIG2 ;Buscar en la tabla la representación de 7 segmentos indicada para el valor		
TO_BCD2:	LDAA BCD2   ;Cargar en valor en BDC de CONT_FREE en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		MOVB A,X DIG3 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
		LDAA BCD2   ;Cargar en valor en BDC de CONT_MAN en A
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
		

;************************************************************************
            ;Subrutina de atención a interrupción RTI
;************************************************************************

RTI_ISR:	DEC CONT_RTI
		BNE SALTO
		MOVB #200,CONT_RTI
		BRSET	PTIH,$80,RTI_ASC ;Si PH7=0, CONT_FREE=DESCENDENTE
		LDAA CONT_FREE
		CMPA #0
		BHI DEC_FREE
		MOVB #99,CONT_FREE
		BRA RTI_SALTO1
DEC_FREE:	DEC CONT_FREE
		BRA RTI_SALTO1
RTI_ASC:	LDAA CONT_FREE
		CMPA #99
		BLO INC_FREE
		MOVB #0,CONT_FREE
		BRA RTI_SALTO1
INC_FREE:	INC CONT_FREE
RTI_SALTO1:	BRSET BANDERAS,$01,L2R ;Aquí se define el sentido de los LEDs
		LSL LEDS ;Aquí se desplazan los LEDs hacia la izquierda
		BCC SALTO
		LDAA BANDERAS
		EORA #$01
		STAA BANDERAS
		MOVB #$40,LEDS
		BRA SALTO
L2R:		LSR LEDS ;Aquí se desplazan los LEDs hacia la derecha
		BCC SALTO
		LDAA BANDERAS
		EORA #$01
		STAA BANDERAS
		MOVB #$02,LEDS
SALTO:	BSET CRGFLG,$80
		RTI
		

;************************************************************************
            ;Subrutina de atención a interrupción PTH
;************************************************************************
PTH_ISR:	BRCLR PIFH,$01,PTH2 ;Si no se está presionando botón 1, chequear botón 2
		BRSET	PTIH,$40,PTH_ASC ;Si PH6=0, CONT_MAN=DESCENDENTE
		LDAA CONT_MAN
		CMPA #0
		BHI DEC_MAN
		MOVB #99,CONT_MAN
		BRA PTH_OUT
DEC_MAN:	DEC CONT_MAN
		BRA PTH_OUT
PTH_ASC:	LDAA CONT_MAN
		CMPA #99
		BLO INC_MAN
		MOVB #0,CONT_MAN
		BRA RTI_SALTO1
INC_MAN:	INC CONT_MAN
PTH2:		BRCLR PIFH,$02,PTH3 ;Si no se está presionando botón 1, chequear botón 3
		LDAA BRILLO ;Si brillo es 0, no se puede decrementar más, salir
		BEQ PTH_OUT
		DEC BRILLO	
		BRA PTH_OUT	
PTH3:		LDAA BRILLO ;Si brillo es 100, no se puede incrementar más, salir
		CMPA #100
		BEQ PTH_OUT
		INC BRILLO
		BRA PTH_OUT	
PTH_OUT:	
		BSET PIFH,$03
		RTI


;************************************************************************
            ;Subrutina de atención a interrupción PTH
;************************************************************************
OC4_ISR:	;MOVB #$FE,PTP
		;MOVB #5,PORTB
		DEC CONT_TICKS
		BNE OUT_OC
		MOVB #100,CONT_TICKS 
		BSET PTJ,$02
		BRCLR CONT_DIG,$01,NEXT1
		MOVB #$F7,PTP
		MOVB DIG1,PORTB
NEXT1:	BRCLR CONT_DIG,$02,NEXT2
		MOVB #$FB,PTP
		MOVB DIG2,PORTB
NEXT2:	BRCLR CONT_DIG,$04,NEXT3
		MOVB #$FD,PTP
		MOVB DIG3,PORTB
NEXT3:	BRCLR CONT_DIG,$08,NEXT4
		MOVB #$FE,PTP
		MOVB DIG4,PORTB
NEXT4:	BRCLR CONT_DIG,$10,CHG_DIG
		MOVB #$FF,PTP
		BCLR PTJ,$02
		MOVB LEDS,PORTB
CHG_DIG:	LDAA CONT_DIG
		CMPA #$10
		BLO SHIFT_DIG
		LDAA #$01
		BRA STORE_DIG
SHIFT_DIG:  LSLA
STORE_DIG:	STAA CONT_DIG
		
OUT_OC:	LDD TCNT
		ADDD #60
		STD TC5
		RTI










