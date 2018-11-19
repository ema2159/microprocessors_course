#include registers.inc
;***************************************************
;           DECLARACIÓN DE PARÁMETROS	
;***************************************************

BR 		EQU 14400	
NP 		EQU $0C
EOM 		EQU $00
;***************************************************
;	DEFINICIÓN DE VECTOR DE INTERRUPCIÓN
;***************************************************
		ORG $3E54
		DW SCI_ISR
;***************************************************
;       DEFINICIÓN DE MENSAJE Y VARIABLES	
;***************************************************
		ORG $1000
MSG: 		FCC "Emma is cool"
		DB EOM
OFFSET:		DS 1	
;***************************************************
;	      PROGRAMA PRINCIPAL
;***************************************************
		ORG $2000
		MOVW #156,SC1BDH
		MOVB #$48,SC1CR2
		LDS #$3BFF
		CLI
		CLR OFFSET		
HERE:		BRSET SC1SR1,$80,HERE
		LDAA SC1SR1
		MOVB #NP,SC1DRL
		BRA *	

SCI_ISR:	LDAA SC1SR1
		LDX #MSG
		LDAB OFFSET
		LDAA B,X
		CMPA EOM
		BEQ CLEARSTUFF  
		STAA SC1DRL
		INC OFFSET
		BRA OUT
CLEARSTUFF:	MOVB #$00,SC1CR2 ;Apagar interfaz
OUT:		RTI		
