#include registers.inc
			ORG $3E5E
			DW TOI_ISR
			ORG $1000
LEDS:			DS 1
CONT_INT:		DS 100
			ORG $1500
			MOVB #$FF,DDRB
			BSET DDRJ,$02
			BCLR PTJ,$02
			MOVB #$0F,PTP
			BSET TSCR1,$80
			BSET TSCR2,$81
			CLI
			LDS #$3BFF
			MOVB #$01,LEDS
			MOVB #100,CONT_INT
			BRA *
			
TOI_ISR:		DEC CONT_INT
			BNE SALTO
			MOVB #100,CONT_INT
			MOVB LEDS,PORTB
			LSL LEDS
			BNE SALTO
			MOVB #01,LEDS
SALTO:		BSET TFLG2,$80
			RTI
