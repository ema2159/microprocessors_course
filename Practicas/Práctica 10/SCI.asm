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
MSG: 		FCC "papas y chayotes"
		DB EOM
OFFSET:		DS 1	
;***************************************************
;	      PROGRAMA PRINCIPAL
;***************************************************
		ORG $2000
		MOVW #104,SC1BDH
		MOVB #$48,SC1CR2
		LDS #$3BFF
		CLI
		LDAA SC1SR1
		MOVB #NP,SC1DRL
		CLR OFFSET		
		BRA *	

SCI_ISR:	LDAA SC1SR1
		LDAB OFFSET
		LDX #MSG
		LDAA B,X
		CMPA EOM
		BEQ CLEARSTUFF  
		STAA SC1DRL
		INC OFFSET
		BRA OUT
CLEARSTUFF:	CLR SC1CR2 ;Apagar interfaz
OUT:		RTI		
