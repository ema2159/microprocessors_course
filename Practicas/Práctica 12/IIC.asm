#include registers.inc
;***************************************************
;           DECLARACIÓN DE PARÁMETROS	
;***************************************************
DIR_SEC 	EQU $00
DIR_WR		EQU $D0
DIR_RD		EQU $D1
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
T_WRITE_RTC:	DB $00,$59,$09,$06,$23,$11,$18
T_READ_RTC:	DS 7
RW_RTC:		DS 1
CONT_RTI:	DS 1
;***************************************************
;	      PROGRAMA PRINCIPAL
;***************************************************
		ORG $2000
		MOVB #$25,IBFD
		MOVB #$F0,IBCR
		LDS #$3BFF
		CLI 
		MOVB #0,RW_RTC
		MOVB #7,INDEX_RTC
		MOVB DIR_WR,IBDR
		BRA *	

IIC_ISR:	BSET IBSR,$02
		TST RW_RTC
		BNE DOSTUFF
		LDAA INDEX_RTC
		CMPA #7
		BEQ DOSTUFF2
		CMPA #6
		BEQ DOSTUFF3
		LDX #T_WRITE_RTC
		LDAA INDEX_RTC
		MOVB A,X IBDR
		INC INDEX_RTC
		BRA OUT 
DOSTUFF2:	MOVB DIR_SEG,IBDR
		CLR INTEX_RTC
		BRA OUT
DOSTUFF3:	BCLR IBCR,$20
		MOVB #1,RW_RTC
		MOVB ,INDEX_RTC
OUT:		RTI 	


DOSTUFF:	LDAA INDEX_RTC
		



RTI_ISR:	DEC CONT_RTI
		BNE RTI_OUT
		BSET IBCR,$20
		MOVB DIR_WR,IBDR
		MOVB #20,CONT_RTI
RTI_OUT:	BSET CRGFLG,$80
		RTI 

