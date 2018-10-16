#include	registers.inc
;************************************************************************
									;Programa de prueba de interrupción IRQ
;************************************************************************
							ORG $1000
LEDS					DS 1
							ORG $FFF2
							DW IRQ_ISR
							
							
							ORG $1500 
							MOVB #$FF,DDRB
							BSET DDRJ,$02
							BCLR PTJ,$02
							BSET IRQCR,$40
							LDS	 #$3BFF
							CLI
							MOVB #$00,PORTB
							BRA	*
							
IRQ_ISR				MOVB LEDS,PORTB
							LSL LEDS
							BNE  SALTO
							MOVW #1,LEDS
SALTO:				RTI
							
