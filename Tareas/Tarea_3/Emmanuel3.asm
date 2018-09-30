;***********************************************************************

															;Tarea 3
		;FECHA: 28 DE SEPTIEMBRE, 2018
		;AUTOR: EMMANUEL BUSTOS TORRES 
		;CARNÉ: B51296
;Descripción: Este programa recibe dos tablas, una conteniendo datos en
;forma de números y la otra conteniendo los posibles valores con raíz
;cuadrada entera que puede tener la primera tabla. El programa recibe
;un parámetro desde el teclado mediante el cual se indica la cantidad
;de valores con raíz cuadrada entera se quieren encontrar en el arreglo, 
;los busca en la tabla de datos, contando cuantos logra encontrar,
;y guardándolos en un arreglo, para posteriormente imprimirlos

;***********************************************************************
CR  				EQU $0D
LF  				EQU $0A
FIN 				EQU $00
GETCHAR 		EQU $EE84
PUTCHAR		 	EQU $EE86
PRINTF  		EQU $EE88
						ORG $1000
LONG				DB 13
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
DATOS:			DB 4,9,18,4,27,63,12,32,36,15,100,169,225
						ORG $1050
CUAD:				DB 1,4,9,16,25,36,49,64,81,100,121,144,169,196,225
						ORG $1100
ENTERO:			DS 1
						ORG $1200			;Aquí se guardan los mensajes a imprimir y demás
INGRESE:		DB CR,LF,LF
						FCC "INGRESE EL VALOR DE CANT (ENTRE 1 Y 9): "
						DB FIN
ERROR1:			DB CR,LF,LF
						FCC "ERROR 1: El número ingresado debe ser un número mayor o igual a 1 y menor igual a 9"
						DB FIN
PRINT_CONT:	DB CR,LF,LF
						FCC "CANTIDAD DE VALORES ENCONTRADOS: %d"
						DB FIN
PRINT_ENT:	DB CR,LF,LF
						FCC "ENTERO:"
						DB FIN
ENT_NUM:		FCC " %d"
						DB FIN
;************************************************************************
												;INICIO DEL PROGRAMA
;************************************************************************
						ORG $1500
;Programa principal:
INICIO:			LDS #$3BFF
						LDD #DATOS 
						MOVW #ENTERO,ENT_POINT
						ADDB LONG						;Calcular y guardar la última posición de DATOS
						STD  DATOS_FIN			;Calcular y guardar la última posición de DATOS
						JSR LEER_CANT
						JSR	BUSCAR
						JSR PRNTENTERO
						BRA INICIO
						
						
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
GOTOERR1:		JSR PRINT_ERR1	;Si el caracter no es un valor del 0 al 9, imprimir un mensaje de error
						BRA LEER_CANT
						
;Subrutina que imprime un mensaje de error
PRINT_ERR1:	LDX #0
						LDD #ERROR1
						JSR [PRINTF,X]
						RTS
						
;Subrutina que busca números DATOS en CUAD
BUSCAR:			LDX #DATOS			;Se deja apuntando a X a DATOS
SEARCH:			LDAA LONG_CUAD	;Se carga en A la cantidad de elementos en CUAD
						LDY #CUAD				;Se deja apuntando Y a CUAD
						LDAB 1,X+				;Se carga un dato y se incrementa X
CUAD_COMP:	CMPB 1,Y+				;Se compara el dato con uno de los valores de CUAD y se incrementa Y
						BNE	 NOT_SQRT   ;Si no son iguales, seguir, si sí, se encontró un dato con raiz entera
						INC CONT				
						STX SAVEX				;Respaldar puntero X
						JSR RAIZ				;Saltar a sub rutina de cálculo de raíz
						LDX SAVEX				;Recuperar puntero X
						DEC CANT				;Decrementar la cantidad de números por encontrar
						BEQ	ALL_FOUND		;Si ya se encontraron todos proseguir
						BRA CHECKX			
NOT_SQRT:		DBNE A,CUAD_COMP ;Seguir a comparar con el siguiente valor en CUAD
CHECKX			CPX	DATOS_FIN		 ;Se verifica si ya se buscó en todo el arreglo de datos
						BNE	SEARCH			 ;Si no, continuar con el siguiente dato	
ALL_FOUND:	RTS							 ;Si  sí, retornar

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
					
					
;Subrutina Print entero
PRNTENTERO:	CLRA
						LDAB CONT ;Se guarda CONT en el stack para paswarlo como parámetro al print
						PSHD
						LDD #PRINT_CONT ;Se guarda el mensaje en D
						LDX 0
						JSR [PRINTF,X] ;Se imprime la cantidad de números encontrados
						LEAS 2,SP
						LDD #PRINT_ENT	
						LDX 0
						JSR [PRINTF,X] ;Se imprime "ENTERO: "
						MOVW #ENTERO,ENT_POINT	;Se deja al puntero ENT_POINT apuntando al inicio del arreglo entero
PRINTFINAL: CLRA
						LDY ENT_POINT     ;Siempre se conserva END_POINT y no se usa solo Y porque la subrutina de print destruye todos los índices y acumuladores
						LDAB 0,Y
						PSHD							;Se pasa como parámetro el número a imprimir
						LDD #ENT_NUM
						LDX 0
						JSR [PRINTF,X]		;Se imprime el número deseado
						LEAS 2,SP
						INC ENT_POINT+1		;Se incrementa el puntero que recorre al arreglo entero
						DEC CONT 					;Se decrementa cont
						TST CONT					;Si CONT es cero, ya se imprimieron todos los números. Regresar
						BNE PRINTFINAL		;sino, imprimir siguiente número
						RTS
			
