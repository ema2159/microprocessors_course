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
K:					DW	20
CANT4:			DS  2
SAVEA:			DS	2
DATOS:			DW $1100
DIV4:				DW $1200
						ORG $1100
						DB -4,8,4,16,-16,32,-32,5,-5,-64,1,2,3,9,120,7,17,8,-9,-8
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
						BEQ NOT_SIGNED				;Si la variable es positiva se continúa, si es negativa se obtiene su complemento a 2
						NEGA 									
NOT_SIGNED:	LSRA									;Se hace un desplazamiento a la derecha sobre A 2 veces, verificando cada vez la bandera de Carry
						BCS NOT_DIV4					;Si Carry es 1 en cualquiera de los casos, el número no es divisible entre 4, omitir
						LSRA
						BCS NOT_DIV4
						INC CANT4							;Si A es divisible entre 4, se incrementa CANT4
						MOVW SAVEA, 1,Y+  		;Guardar A si es divisible entre 4
NOT_DIV4:		CPX K									;Si se cubrieron todos los elementos, terminar
						BNE LOOP
						BRA * 
						
						
						
						
						
						

						
