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
LONG				DB 10
CANT:				DS 1
CONT:				DB 0
DATOS_FIN:	DS 2
LONG_CUAD:	DB 15
SAVEX:			DS 2
SAVEY:			DS 2
SAVED:			DS 2
XVAR:				DS 2
RVAR:				DS 2
TVAR:				DS 2
ENT_POINT:	DS 2
						ORG $1020
DATOS:			DB 4,9,18,4,27,63,12,32,36,15
						ORG $1050
CUAD:				DB 1,4,9,16,25,36,49,64,81,100,121,144,169,196,225
						ORG $1100
ENTERO:			DS 1
						ORG $1200			;Aquí se guardan los mensajes a imprimir y demás
INGRESE:		DB CR,LF
						FCC "INGRESE EL VALOR DE CANT (ENTRE 1 Y 9): "
						DB FIN
ERROR1:			DB CR,LF
						FCC "ERROR 1: El número ingresado debe ser un número mayor o igual a 1 y menor igual a 9"
						DB LF,LF,FIN
PRINT_ENT:	DB CR,LF
						FCC "ENTERO:"
						DB FIN
ENT_NUM:		FCC " %d"
						DB FIN
;************************************************************************
												;INICIO DEL PROGRAMA
;************************************************************************
						ORG $1500
;Programa principal:
						LDS #$3BFF
						LDD #DATOS 
						MOVW #ENTERO,ENT_POINT
						ADDB LONG						;Calcular y guardar la última posición de DATOS
						STD  DATOS_FIN			;Calcular y guardar la última posición de DATOS
						JSR LEER_CANT
						JSR	BUSCAR
						LDD #PRINT_ENT
						LDX 0
						JSR [PRINTF,X] 
						MOVW #ENTERO,ENT_POINT		
PRINTFINAL: CLRA
						LDY ENT_POINT     ;Siempre se conserva END_POINT y no se usa solo Y porque la subrutina de print destruye todos los índices y acumuladores
						LDAB 0,Y
						PSHD
						LDD #ENT_NUM
						LDX 0
						JSR [PRINTF,X]
						PULD
						INC ENT_POINT+1
						DEC CONT 
						TST CONT
						BNE PRINTFINAL
						BRA *
						
;Subrutina recbe un número entre 1 y 9 desde la terminal. Arroja un error mientras se le ingrese algo distinto
LEER_CANT:	LDX #0
						LDD #INGRESE
						JSR [PRINTF,X]	;Imprime mensaje de ingreso de CANT	
						LDX #0
						JSR [GETCHAR,X] ;Recibe caracter del teclado
						CPD #$31        ;Si el caracter ascii es menor a $31, no es un número entre 1 y 9, ir a error
						BLO GOTOERR1
						CPD #$39	      ;Si el caracter ascii es mayor a $39, no es un número entre 1 y 9, ir a error
						BHI GOTOERR1
						ANDB #$0F
						STAB CANT
						ORAB #$30
						JSR [PUTCHAR,X] ;Imprime caracter en la terminal
						RTS
GOTOERR1:		JSR PRINT_ERR1	;Si el caracter no es un valor del0 al 9, imprimir un mensaje de error
						BRA LEER_CANT
						
;Subrutina que imprime un mensaje de error
PRINT_ERR1:	LDX #0
						LDD #ERROR1
						JSR [PRINTF,X]
						RTS
						
;Subrutina que busca números DATOS en CUAD
BUSCAR:			LDX #DATOS
SEARCH:			LDAA LONG_CUAD
						LDY #CUAD
						LDAB 1,X+
CUAD_COMP:	CMPB 1,Y+
						BNE	 NOT_SQRT
						INC CONT
						STX SAVEX
						JSR RAIZ
						LDX SAVEX
						DEC CANT
						BEQ	ALL_FOUND
						BRA CHECKX
NOT_SQRT:		DBNE A,CUAD_COMP
CHECKX			CPX	DATOS_FIN	
						BNE	SEARCH
ALL_FOUND:	RTS

;Subrutina que calcula la raíz cuadrada de un número mediante el algoritmo babilónico
RAIZ:				STD SAVED    ;Conservar el valor de D que será necesitado después
						CLRA 
						STD XVAR     ;Guardar valor al que se le desea sacar raíz en XVAR
						STD RVAR
SQRT_LOOP:	MOVW RVAR,TVAR ;Implementación de algoritmo babilónico usando variables x,r y t
						LDD  XVAR
						LDX  RVAR
						IDIV			;Se divide x entre r
						TFR X,D		;Se transfiere el resultado a D para poder operar
						ADDD RVAR	;Se suma r al resultado anterior
						LSRD			;Se divide entre dos
						STD RVAR	;Se guarda variable en r
						CPD	TVAR
						BNE SQRT_LOOP ;No se retorna hasta que las variables t y r sean iguales
						LDX ENT_POINT
						STAB 0,X			  ;Se guarda la raíz encontrada en el último espacio disponible del arreglo entero
						INC ENT_POINT+1 ;Se incrementa ENT_POINT (El +1 se debe a que ENT_POINT es un word, y se quiere incrementar el byte menos significativo de dicha dirección)
						LDD	SAVED
						RTS
						
						
