;***********************************************************************

															;Tarea 3

;***********************************************************************
CR  				EQU $0D
LF  				EQU $0A
FIN 				EQU $00
GETCHAR 		EQU $EE84
PUTCHAR		 	EQU $EE86
PRINTF  		EQU $EE88
						ORG $1000
CANT:				DS 1
INGRESE:		DB CR,LF
						FCC "INGRESE EL VALOR DE CANT (ENTRE 1 Y 9):"
						DB FIN
ERROR1:			DB CR,LF
						FCC "ERROR 1: El número ingresado debe ser un número mayor o igual a 1 y menor igual a 9"
						DB LF,LF,FIN
						ORG $1500
						LDS #$3BFF
						LDX #0
						JSR LEER_CANT
						BRA *
						
;Subrutina recbe un número entre 1 y 9 desde la terminal. Arroja un error mientras se le ingrese algo distinto
LEER_CANT:	LDX #0
						LDD #INGRESE
						JSR [PRINTF,X]
						LDX #0
						JSR [GETCHAR,X]
						CPD #$31        ;Si el caracter ascii es menor a $31, no es un número entre 1 y 9, ir a error
						BLO GOTOERR1
						CPD #$39	       ;Si el caracter ascii es mayor a $39, no es un número entre 1 y 9, ir a error
						BHI GOTOERR1
						JSR [PUTCHAR,X]
						ANDA #0
						RTS
GOTOERR1:		JSR PRINT_ERR1
						BRA LEER_CANT
						
;Subrutina que imprime un mensaje de error
PRINT_ERR1:	LDX #0
						LDD #ERROR1
						JSR [PRINTF,X]
						RTS
						
						
