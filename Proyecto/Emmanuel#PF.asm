;******************************************************
;           UCR                 II-2018
;
;           PROYECTO FINAL: Medidor 623
;
;Autor: Emmanuel Bustos Torres
;Carné: B51296
;Curso: Microproccesadores IE-623
;Descripción:
;******************************************************
#include registers.inc

;******************************************************
;     Configuración de vectores de interrupción
;******************************************************
	;	ORG $3E4C
	;	DW PTH_ISR
		ORG $3E66
		DW OC4_ISR
		ORG $3E70
		DW RTI_ISR
;******************************
;Definición de comandos
;******************************
FUNCTION_SET 	EQU $28
ENTRY_MODE_SET 	EQU $06
DISPLAY_ON	EQU $0C
CLEAR_DISPLAY 	EQU $01
RETURN_HOME 	EQU $02
DDRAM_ADDR1 	EQU $80
DDRAM_ADDR2 	EQU $C0
;******************************
;Definición de caracteres
;******************************
EOM:		EQU $00
CR  		EQU $0D
LF  		EQU $0A
;******************************************************
;            Declaración de variables
;******************************************************
		ORG $1000
PATRON:		DS 1
REB:		DS 1
TECLA:		DS 1
VALOR:		DS 1
BAND_TEC:	DS 1   ;Se usará una bandera adicional para los LEDs, por lo que BAND_TEC entonces será X:X:X:X:LEDS_LISTOS:PRIMERA:VALIDA:TECL_LISTA
BANDERAS	DS 1   ;X:X:Corto:Largo:Dist:S2:S1:C/M
BUFFER:		DS 1
TMP1:		DS 1
TMP2:		DS 1
TMP3:		DS 1
TECLAS:		DB $01,$02,$03,$04,$05,$06,$07,$08,$0B,$09,$00,$0E
CONT_MAN:   	DS 1
CONT_FREE:  	DS 1
LEDS:       	DS 1
BRILLO:     	DS 1
CONT_DIG:   	DS 1
CONT_TICKS: 	DS 1
DT:         	DS 1
CONT_RTI:	DS 1
BCD1:       	DS 1
BCD2:       	DS 1
DIG1:       	DS 1
DIG2:       	DS 1
DIG3:       	DS 1
DIG4:       	DS 1
SEGMENT:    	DB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
CONT_7SEG:  	DS 2
CONT_DELAY: 	DS 1
D2ms:       	DB 100
D260us:     	DB 13
D40us:      	DB 2
;******************************************************
;     Programa principal y configuración inicial
;******************************************************
		ORG $1500
		;Configurar interrupción RTI
		MOVB #$31,RTICTL
		BCLR CRGINT,$80
		;Configuración de interrupción Output Compare
		MOVB #$90,TSCR1
		MOVB #$10,TIOS
		MOVB #$03,TSCR2
		MOVB #$01,TCTL1
		MOVB #$10,TIE
		;Configuración de pantalla LCD
		MOVB #$FF,DDRK
		;Configuración de segmentos y LEDS
		MOVB #$FF,DDRB
		BSET DDRJ,$02
		BCLR PTJ,$02
		MOVB #$0F,DDRP
		;Configurar la mitad de los bits de teclado como entrada y la otra mitad como salida
		MOVB #$F0,DDRA
		;Habilitar resistencias de pullup
		BSET PUCR,$01
		;Habilitar instrucciones mascarables
		CLI
		;Configurar stack
		LDS #$3BFF
		;Inicializar las variables
		MOVB #$01,BAND_TEC  
		MOVB #01,LEDS
		MOVB #0,PORTB
		CLR CONT_FREE
		CLR CONT_MAN
		MOVB #200,CONT_RTI ;Inicializar contador de interrupción RTI
		MOVB #100,BRILLO ;Inicializar brillo
		LDD TCNT
		ADDD #60
		STD TC4
		MOVB #100,CONT_TICKS
		MOVB #1,CONT_DIG
		;Programa principal
		MOVB #$01,LEDS
		MOVB #10,REB
		MOVB #$00,BAND_TEC
		MOVB #$FF,TMP1 ;Se colocan las variables temporales en $FF
		MOVB #$FF,TMP2 ;para indicar que se encuentran vacías 
		CLR VALOR
LOOP_FIN:	BRSET	PTIH,$40,PH61 ;Se verifica el modo del medidor mediante los Dip switches
		BRCLR	PTIH,$80,M_STOP ;Si ambos switches PH6 y PH7 están en 0, se entra en modo stop
		BRA M_CONFIG ;Si los switches son distintos entre sí, se entra en modo config
PH61:		BRSET	PTIH,$80,M_MEDICION ;Si ambos switches PH6 y PH7 están en 1, se entra en modo medicion
M_CONFIG:	JSR CONFIG
		BRA LOOP_FIN
M_MEDICION:	JSR MEDICION	
		BRA LOOP_FIN
M_STOP:		JSR STOP
		BRA LOOP_FIN
		BRCLR BAND_TEC,$01,NOT_TEC
		JSR TECLADO
		MOVB VALOR,CONT_FREE
NOT_TEC:	BRA LOOP_FIN


;******************************************************
;		Subrutina medicion
;******************************************************
MEDICION:	MOVB #11,CONT_FREE
		RTS 
;******************************************************
;		Subrutina config
;******************************************************
CONFIG:		BSET BANDERAS,$01
		
		RTS 
;******************************************************
;		Subrutina stop
;******************************************************
STOP:		MOVB #33,CONT_FREE
		RTS 

;******************************************************
;               SUBRUTINA TECLADO
;Esta subrutina se encarga de manejar la lógica corres-
;pondiente al teclado, guardando las teclas presionadas
;en variables temporales hasta que el usuario  presione
;la tecla ENTER, o decida  borrar la tecla que presionó
;haciendo uso de la tecla BORRAR.
;******************************************************
TECLADO:	LDAA TECLA
		LDAB TMP1
		CMPB #$FF
		BNE TMP1FULL
		CMPA #$09
		BHI RET_TECL
		MOVB TECLA,TMP1
		BRA RET_TECL
TMP1FULL:	LDAB TMP2
		CMPB #$FF
		BNE TMP2FULL
		CMPA #$09
		BHI B_OR_E
		MOVB TECLA,TMP2
		BRA RET_TECL
B_OR_E:		CMPA #$0B
		BNE NOT_B
		MOVB #$FF,TMP1
		BRA RET_TECL
NOT_B:		MOVB TMP1,VALOR
		BSET BAND_TEC,$08
		MOVB #$FF,TMP1
		BRA RET_TECL
TMP2FULL:	CMPA #$09
		BHI B_OR_E2
		BRA RET_TECL
B_OR_E2:	CMPA #$0B
		BNE NOT_B2
		MOVB #$FF,TMP2
		BRA RET_TECL
NOT_B2:		LDAA TMP1
		LDAB #10
		MUL 
		ADDB TMP2
		STAB VALOR
		BSET BAND_TEC,$08
		MOVB #$FF,TMP1
		MOVB #$FF,TMP2
RET_TECL:	BCLR BAND_TEC,$01
		RTS 

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

;******************************************************
;           SUBRUTINA DE INTERRUPCIÓN RTI
;******************************************************
RTI_ISR:	TST REB
		LBNE DEC_REB
		MOVB #$FF,BUFFER
		MOVB #0,PATRON
		LDAA #$EF
		LDX #TECLAS
LOOP_TEC:	LDAB PATRON
		CMPB #3
		BEQ FIN_LEER
		STAA PORTA
		LDAB #0
		BRCLR PORTA,$01,ENC_TEC
		INCB 
		BRCLR PORTA,$02,ENC_TEC
		INCB 
		BRCLR PORTA,$04,ENC_TEC
		INCB 
		BRCLR PORTA,$08,ENC_TEC
		INC PATRON
		ROLA 
		BRA LOOP_TEC
ENC_TEC:	LSL PATRON
		LSL PATRON
		ADDB PATRON
		MOVB B,X BUFFER
FIN_LEER: 
		LDAA #$FF
		CMPA BUFFER
		BEQ TEC_NE
		BRSET BAND_TEC,$04,TEC_NE
		BSET BAND_TEC,$04
		MOVB #10,REB
		MOVB BUFFER,TECLA
		BRA RTI_RTRN
TEC_NE:		LDAA TECLA 
		CMPA #$FF
		BEQ RTI_RTRN
		BRSET BAND_TEC,$02,IS_VALID
		CMPA BUFFER
		BEQ TEC_BUFF
		MOVB #$FF,TECLA
		BCLR BAND_TEC,$04
		BRA RTI_RTRN
TEC_BUFF:	BSET BAND_TEC,$02
		BRA RTI_RTRN
IS_VALID:	LDAB BUFFER
		CMPB #$FF
		BNE RTI_RTRN
		BSET BAND_TEC,$01
		BCLR BAND_TEC,$06
		BRA RTI_RTRN
DEC_REB:	DEC REB
RTI_RTRN:	BSET CRGFLG,$80
		RTI 

;************************************************************************
            ;Subrutina de atención a interrupción OC4
;************************************************************************
OC4_ISR:	LDD CONT_7SEG ;Cargar el contador de refrescamiento de 7SEG
		ADDD #1
		CPD #500     ;Si este ya contó 100mS, refrescar valores
		BNE NOT_RFRSH ;Si no, continuar
		JSR BIN_BCD
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

