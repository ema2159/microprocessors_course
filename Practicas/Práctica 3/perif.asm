#include	registers.inc
					
					
					ORG $1500
					MOVB #$FF,DDRB
					BSET DDRJ,$02
					BCLR PTJ,$02
					MOVB #$00,DDRH
					MOVB #$0F,DDRP
					MOVB #$0F,PTP
LOOP:			MOVB PTIH,PORTB
					BRA LOOP
