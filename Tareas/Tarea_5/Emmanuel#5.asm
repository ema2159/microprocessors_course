#include registers.inc
		ORG $3E70
		DW RTI_ISR
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
		;Habilitar instrucciones mascarables
		CLI
		;Configurar stack
		LDS #$3BFF
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



RTI_ISR:	BRSET	PTIH,$80,L2R ;Si PH7=0, CONT_FREE=DESCENDENTE
		DEC CONT_FREE
		BNE SALTO
		MOVB #200,CONT_FREE
		MOVB LEDS,PORTB
		LSL LEDS
		BNE SALTO
		MOVB #01,LEDS
L2R:		INC CONT_FREE ;Si PH7=0, CONT_FREE=ASCENDENTE
		LDAA CONT_FREE
		CMPA #200
		BNE SALTO
		MOVB #0,CONT_FREE
		MOVB LEDS,PORTB
		LSR LEDS
		BNE SALTO
		MOVB #$80,LEDS                
SALTO:	BSET CRGFLG,$80
		RTI
