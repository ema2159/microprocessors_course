#include registers.inc
;******************************
;Configuración de Subrutinas
;******************************
		ORG $3E70
		DW RTI_ISR
		ORG $3E4C
		DW PTH_ISR
;******************************
;Estructuras de datos
;******************************
		ORG $1000
CONT_MAN:   DS 1
CONT_FREE:  DS 1
LEDS:       DS 1
BRILLO:     DS 1
CONT_DIG:   DS 1
C0NT_TICKS: DS 1
DT:         DS 1
CONT_RTI:	DS 1
BANDERAS:	DS 1
		ORG 1010
BCD1:       DS 1
BCD2:       DS 1
DIG1:       DS 1
DIG2:       DS 1
DIG3:       DS 1
DIG4:       DS 1
SEGMENT:    DS 1
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
		;Configuración de interrupción de key wakepus
		BSET PIEH,$07
		BCLR PPSH,$07
		;Habilitar instrucciones mascarables
		CLI
		;Configurar stack
		LDS #$3BFF
		;Inicializar las variables
		CLR BANDERAS
		MOVB #01,LEDS
		CLR PORTB
		CLR CONT_FREE
		CLR CONT_MAN
		CLR BRILLO
		;Programa principal
		MOVB #$01,LEDS
		MOVB #100,CONT_FREE
		BRA *
;************************************************************************
                             ;Subrutina BCD:
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
		BRA *

;************************************************************************
            ;Subrutina de atención a interrupción RTI
;************************************************************************

RTI_ISR:	DEC CONT_RTI
		BNE SALTO
		MOVB #200,CONT_RTI
		BRSET	PTIH,$80,RTI_ASC ;Si PH7=0, CONT_FREE=DESCENDENTE
		DEC CONT_FREE
		BRA RTI_SALTO1
RTI_ASC:	INC CONT_FREE
RTI_SALTO1:	;MOVB LEDS,PORTB
		BRSET BANDERAS,$01,L2R ;Aquí se define el sentido de los LEDs
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
		DEC CONT_MAN
		MOVB CONT_MAN, PORTB
		BRA SALIR
PTH_ASC:	INC CONT_MAN
		MOVB CONT_MAN, PORTB
		BRA SALIR
PTH2:		BRCLR PIFH,$02,PTH3 ;Si no se está presionando botón 1, chequear botón 3
		LDAA BRILLO ;Si brillo es 0, no se puede decrementar más, salir
		BEQ SALIR
		DEC BRILLO
		MOVB BRILLO, PORTB	
		BRA SALIR	
PTH3:		LDAA BRILLO ;Si brillo es 100, no se puede incrementar más, salir
		CMPA #100
		BEQ SALIR
		INC BRILLO
		MOVB BRILLO, PORTB	
		BRA SALIR	
SALIR:	
		BSET PIFH,$03
		RTI

