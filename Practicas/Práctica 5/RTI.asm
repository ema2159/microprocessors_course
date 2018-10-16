#include	registers.inc
					ORG $3E70
					DW RTI_ISR
					ORG $1000
LEDS:			DS 1
CONT_INT:	DS 100
					ORG $1500
					MOVB #$FF,DDRB
					BSET DDRJ,$02
					BCLR PTJ,$02
					MOVB #$0F,PTP
					MOVB #$22,RTICTL
					BSET CRGINT,$80
					CLI
					LDS #$3BFF
					MOVB #$01,LEDS
					MOVB #100,CONT_INT
					BRA *
					
RTI_ISR:				DEC CONT_INT
					BNE SALTO
					MOVB #100,CONT_INT
					MOVB LEDS,PORTB
					LSL LEDS
					BNE SALTO
					MOVB #01,LEDS
SALTO:				BSET CRGFLG,$80
					RTI
