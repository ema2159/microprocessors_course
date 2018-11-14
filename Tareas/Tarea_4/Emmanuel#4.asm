;***********************************************************************
;                             Tarea 4
;Autor: Emmanuel Bustos T.
;Versión: 1.0
;Fecha: 20 de Octubre, 2018
;Descripción: Este programa consiste  en leer e interpretar las entradas 
;brindadas en la tarjeta de training Dragon 12 por el teclado matricial, 
;implementando diversos tipos de  subrutinas. El programa lee las entra-
;das del teclado mediante  una  subrutina en una interrupción mascarable
;RTI, y mediante la subrutina TECLADO almacena los valores leídos en una
;variable tipo byte llamada VALOR, almacenando primero uno o dos valores
;en  variables  temporales  las  cuales se guardarán en valor una vez se 
;haya presionado la tecla ENTER.  Además, se puede hacer uso de la tecla
;BORRAR para limpiar el contenido de una o dos de las variables tempora-
;les  antes  de  guardarlas en VALOR. Por último, el contenido de VALOR 
;será mostrado mediante la subrutina LEDS, en los LEDs  incorporados  en
;la tarjeta Dragon 12. A continuación se muestra un diagrama ilustrativo
;del formato del teclado:                                          
;                     -----------------                                                     
;                     |   |   |   |   |                                                     
;                     | 1 | 2 | 3 | 4 |                                                     
;           PA4($EF)--------------------                                         
;                     |   |   |   |   |                                           
;                     | 5 | 6 | 7 | 8 |                                           
;           PA5($DF)--------------------                                           
;                     |   |   |   |   |                                           
;                     | B | 9 | 0 | E |                                           
;           PA6($7F)--------------------                                           
;                       |   |   |   |
;                      PA0 PA1 PA2 PA3
;               BRCLR: $01 $02 $04 $08
;***********************************************************************
#include registers.inc
		ORG $3E70
		DW RTI_ISR
;******************************
;Estructuras de datos
;******************************
		ORG $1000
PATRON:		DS 1
REB:		DS 1
TECLA:		DS 1
VALOR:		DS 1
BANDERAS:	DS 1   ;Se usará una bandera adicional para los LEDs, por lo que BANDERAS entonces será X:X:X:X:LEDS_LISTOS:PRIMERA:VALIDA:TECL_LISTA
BUFFER:		DS 1
TMP1:		DS 1
TMP2:		DS 1
TMP3:		DS 1
TECLAS:		DB $01,$02,$03,$04,$05,$06,$07,$08,$0B,$09,$00,$0E
;*******Configuración de registros********
		ORG $1500
		;Configurar interrupción RTI
		MOVB #$31,RTICTL
		BSET CRGINT,$80
		;Configurar LEDS
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
;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
		;PROGRAMA PRINCIPAL
;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
		;Inicializar distintas variables
		MOVB #10,REB
		MOVB #$00,BANDERAS
		MOVB #$FF,TMP1 ;Se colocan las variables temporales en $FF
		MOVB #$FF,TMP2 ;para indicar que se encuentran vacías 
LOOP_FIN:	BRCLR BANDERAS,$01,NOT_TEC
		JSR TECLADO
		BRCLR BANDERAS,$08,NOT_TEC
		JSR LEDS
NOT_TEC:	BRA LOOP_FIN

;************SUBRUTINA TECLADO*************
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
		BSET BANDERAS,$08
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
		LDAB #16
		MUL 
		ADDB TMP2
		STAB VALOR
		BSET BANDERAS,$08
		MOVB #$FF,TMP1
		MOVB #$FF,TMP2
RET_TECL:	BCLR BANDERAS,$01
		RTS 
;********FIN DE SUBRUTINA TECLADO********

;*************SUBRUTINA LEDS*************

LEDS:		MOVB VALOR,PORTB
		BCLR BANDERAS,$08
		RTS 
;*********FIN DE SUBRUTINA LEDS**********


;******SUBRUTINA DE INTERRUPCIÓN RTI*****
RTI_ISR:	TST REB
		LBNE DEC_REB
		MOVB	#$FF,BUFFER
;***************LEER TECLA***************
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
;*********FIN LEER TECLA************
		LDAA #$FF
		CMPA BUFFER
		BEQ TEC_NE
		BRSET BANDERAS,$04,TEC_NE
		BSET BANDERAS,$04
		MOVB #10,REB
		MOVB BUFFER,TECLA
		BRA RTI_RTRN
TEC_NE:		LDAA TECLA 
		CMPA #$FF
		BEQ RTI_RTRN
		BRSET BANDERAS,$02,IS_VALID
		CMPA BUFFER
		BEQ	TEC_BUFF
		MOVB #$FF,TECLA
		BCLR BANDERAS,$04
		BRA RTI_RTRN
TEC_BUFF:	BSET BANDERAS,$02
		BRA RTI_RTRN
IS_VALID:	LDAB BUFFER
		CMPB #$FF
		BNE	RTI_RTRN
		BSET BANDERAS,$01
		BCLR BANDERAS,$06
		BRA RTI_RTRN
DEC_REB:	DEC REB
RTI_RTRN:	BSET CRGFLG,$80
		RTI 
;***FIN DE SUBRUTINA DE INTERRUPCIÓN RTI***
