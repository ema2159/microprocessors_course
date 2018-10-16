;********************
;               Programa prueba de interrupcion Key Wakeups
;********************
#include registers.inc

;********************
								ORG $3E4C
								DW PTH_ISR

;***Estructuras de datos***********
        ORG $1000
LEDS    DS 1 ;contiene el patron de los leds


;**Configuracion de hardware*********

        ORG $1100
        MOVB #$FF,DDRB    ;poner puerto B como salida
        BSET DDRJ,$02
        BCLR PTJ,$02
        BSET PIEH,$01
        BCLR PPSH,$01
       
        LDS #$3BFF
        CLI

;***Programa principal*****
        MOVB #$00, PORTB
        MOVB #$01, LEDS
        BRA *

 ;**Subrutina de atencion a interrupciones*

PTH_ISR
        MOVB LEDS, PORTB
        LSL LEDS
        BNE SALIR
        MOVB #$01, LEDS

SALIR   BSET PIFH,1
				RTI
