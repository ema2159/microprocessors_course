;***********************************************************************
;                             Tarea 4
;Autor:Emmanuel Bustos T.
;Descripción: Este programa consiste en leer e interpretar las entradas 
;brindadas en la tarjeta de training Dragon 12 por el teclado matricial, 
;implementando las subrutinas necesarias.                                                                     
;                 -----------------                                                     
;                 |   |   |   |   |                                                     
;                 | 1 | 2 | 3 | 4 |                                                     
;            PA4--------------------                                           
;                 |   |   |   |   |                                           
;                 | 5 | 6 | 7 | 8 |                                           
;            PA5--------------------                                           
;                 |   |   |   |   |                                           
;                 | B | 9 | 0 | E |                                           
;            PA6--------------------                                           
;                 |   |   |   |   |                                                   
;                 | NA| NA| NA| NA|                                                   
;            PA7-------------------- 
;                     |   |   |   |
;                    PA0 PA1 PA2 PA3
;***********************************************************************
#include registers.inc
					ORG $3E70
					DW RTI_ISR
;******************************
;Estructuras de datos
;******************************
					ORG $1000
PATRON:		DS 1
REB:			DS 1
TECLA:		DS 1
VALOR:		DS 1
BANDERAS:	DS 1
BUFFER:		DS 1
TMP1:			DS 1
TMP2:			DS 1
TMP3:			DS 1
TECLAS:		DB $01,$02,$03,$04,$05,$06,$07,$08,$0B,$09,$0E
;******************************
;Configuración de registros
;******************************
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
				;	BSET PUCR,$01
					;Habilitar instrucciones mascarables
					CLI
					;Configurar stack
					LDS #$3BFF
					BRA *

RTI_ISR:	TST REB
					LBEQ DEC_REB
					MOVB	#$FF,BUFFER
;*********LEER TECLA***************
					MOVB #0,PATRON
					LDAA #$EF
					LDX TECLAS
LOOP_TEC:	LDAB PATRON
					CMPB #4
					BEQ FIN_LEER
					STAA PORTA
					LDAB #0
					MOVB PORTA,PORTB
					BRCLR PORTA,$01,ENC_TEC
					INCB
					MOVB PORTA,PORTB
					BRCLR PORTA,$02,ENC_TEC
					INCB
					MOVB PORTA,PORTB
					BRCLR PORTA,$04,ENC_TEC
					INCB
					MOVB PORTA,PORTB
					BRCLR PORTA,$08,ENC_TEC
					INC PATRON
					ROLA
					BRA	LOOP_TEC
ENC_TEC:	LSL PATRON
					LSL PATRON
					ADDB PATRON
					MOVB B,X BUFFER
				;	MOVB BUFFER,PORTB
FIN_LEER:
;**********************************					
					LDAA #$FF
					CMPA BUFFER
					BEQ TEC_NE
					BRSET BANDERAS,$03,TEC_NE
					BSET BANDERAS,$04
					MOVB #10,REB
					MOVB BUFFER,TECLA
					BRA RTI_RTRN
TEC_NE:		CMPA #$FF
					BEQ RTI_RTRN
					BRSET BANDERAS,$02,IS_VALID
					CMPA BUFFER
					BEQ	TEC_BUFF
					MOVB #$FF,TECLA
					BRA RTI_RTRN
TEC_BUFF:	BSET BANDERAS,$02
					BRA RTI_RTRN
IS_VALID: LDAB BUFFER
					CMPB #$FF
					BNE	RTI_RTRN
					BSET BANDERAS,$01
					BCLR BANDERAS,$06
					BRA RTI_RTRN
DEC_REB:	DEC REB
RTI_RTRN:	RTI












					
					






