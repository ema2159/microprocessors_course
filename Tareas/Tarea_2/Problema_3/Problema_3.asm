;***********************************************************************
;							Programa encuentra números divisibles entre 4
;***********************************************************************

		;FECHA: 28 DE SEPTIEMBRE, 2018
		;AUTOR: EMMANUEL BUSTOS TORRES 
		
;Descripción: Este programa consiste en recorrer un arreglo
;y guarda en una posición de memoria determinada los números del arreglo 
;que son divisibles entre 4, además de guardar en otra posición la cantidad
;de números divisibles entre 4 que se encuentren
						ORG $1000
K:					DW	9
CANT4:			DW
SAVEA:			DW
DATOS:			DW $1100
DIV4:				DW $1200
						ORG $1100
						DB -4,8,4,16,-16,32,-32,5,-5
						ORG $1300
						LDD K
						ADDD DATOS
						STD K			;Se reutiliza K para guardar la última posición del arreglo
						LDY DIV4 
						LDX DATOS
LOOP:				LDAA 1,X+
						STAA SAVEA						;Guardar el número en caso de necesitar ser guardado;
						TAB
						ANDB #$80
						TSTB 
						BEQ NOT_SIGNED						
						NEGA 
NOT_SIGNED:	LSRA
						BCS NOT_DIV4
						LSRA
						BCS NOT_DIV4
						INC CANT4
						MOVW SAVEA, 1,Y+  ;Guardar A si es divisible entre 4
NOT_DIV4:		CPX K
						BNE LOOP
						BRA * 
						
						
						
						
						
						

						
