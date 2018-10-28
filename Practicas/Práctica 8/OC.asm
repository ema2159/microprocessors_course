#include registers.inc
			ORG $3E64
			DW OC_ISR
			ORG $1000
LEDS:			DS 1
CONT_INT:		DB 100
			ORG $1500 
			;Configuración de interrupción Output Compare
			MOVB #$90,TSCR1
			MOVB #$20,TIOS
			MOVB #$03,TSCR2
			MOVB #$04,TCTL1
			MOVB #$20,TIE
			;Configuración de hardware
			MOVB #$FF,DDRB
			BSET DDRJ,$02
			BCLR PTJ,$02
			MOVB #$0F,PTP
			LDS #$3BFF
			CLI
			MOVB #$01,LEDS
			MOVB #100,CONT_INT
			MOVB #0,PORTB
			LDD TCNT
			ADDD #6816
			STD TC5
			BRA *
			
OC_ISR:		DEC CONT_INT
			BNE SALTO
			MOVB #100,CONT_INT
			MOVB LEDS,PORTB
			LSL LEDS
			BNE SALTO
			MOVB #01,LEDS
SALTO:		LDD TCNT
			ADDD #6816
			STD TC5
			RTI
