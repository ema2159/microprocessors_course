#include registers.inc 
;******************************
;Configuración de Subrutinas
;******************************



		MOVB #$C2,ATD0CTL2
LOOP1:		LDAA #200
		DBNE A,LOOP1
		MOVB #$20,ATD0CTL3
		MOVB #$93,ATD0CTL4
		MOVB #$93,ATD0CTL5
		LDS #$4000
		CLI
		BRA *
		
ATD0_ISR:	LDD ADR00H
		ADD ADR01H			
		ADD ADR02H			
		ADD ADRR3H			
		LSRD 
		LSRD 
		STAB RESULT
		
		MOVB #$93,ATD0CTLS
	
	


	 
