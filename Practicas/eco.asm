;***********************************************************************
														;PROGRAMA ECO
													;Práctica de clase		
;***********************************************************************
CR EQU $0D
LF EQU $0A
FIN EQU $00
						ORG $1000
VALOR1:			DS	1
VALOR2:			DS	2
VALOR3:			DS	3
GETCHAR:		EQU $EE84
PUTCHAR:		EQU $EE86
PRINTF:			EQU $EE88
MSG1:				FCC "LOS VALORES ORDENADOS SON:"
						DB CR,LF,LF,LF,FIN
MSG2:				FCC "VALOR1: %d, VALOR2: %d, VALOR3: %d"
						DB LF,LF,FIN
						ORG $1100
						MOVB #43, VALOR1
						MOVB #54, VALOR2
						MOVB #65, VALOR3
						LDS #$3BFF
						LDX #$0000
						LDD #MSG1
						JSR [PRINTF,X]
						CLRA
						LDAB VALOR3
						PSHD
						CLRA
						LDAB VALOR2
						PSHD
						CLRA
						LDAB VALOR1
						PSHD
						LDD #MSG2
						LDX #0
						JSR [PRINTF,X]
						LDX #0
ECO:				JSR [GETCHAR,X]
						JSR [PUTCHAR,X]
						BRA ECO
				END
