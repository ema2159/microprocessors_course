#include registers.inc 
		ORG $FFD2
		DW ATD0_ISR
;******************************
;Configuración de variables	 
;******************************
		ORG $1000
RESULT:		DS 1
;******************************
;Configuración de Subrutinas
;******************************


		ORG $2000
		MOVB #$C2,ATD0CTL2
		LDAA #200
LOOP1:		DBNE A,LOOP1
		MOVB #$20,ATD0CTL3
		MOVB #$93,ATD0CTL4
		MOVB #$84,ATD0CTL5
		LDS #$4000
		CLI
		BRA *
		
ATD0_ISR:	LDD ADR00H
		ADDD ADR01H			
		ADDD ADR02H			
		ADDD ADR03H			
		LSRD 
		LSRD 
		STAB RESULT
		
		MOVB #$84,ATD0CTL5
		RTI	
	
			
