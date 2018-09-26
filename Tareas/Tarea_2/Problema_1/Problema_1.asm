;***********************************************************************
;												Programa Ordenar datos
;***********************************************************************

		;FECHA: 28 DE SEPTIEMBRE, 2018
		;AUTOR: EMMANUEL BUSTOS TORRES 
		
;Descripción: Este programa consiste en un programa que ordena de mayor a 
;menor una lista de números, eliminando los elementos repetidos;
						ORG $1000
CANT:	  		Dw 31
ARRAYEND:		DW 0 ;Se guarda la última posición de memoria
DATOS: 		  DW $1100
ORDEN:  	  DW $1120
						ORG $1100
						DB 02,32,43,24,53,22,43,12,43,32,43,13,03,42,05,23,12,32,41,75,70,65,45,34,23,32,13,53,65,34,76
						ORG	$1500
						;Primero se implementa un bubblesort sobre los CANT datos guardados en la posición DATOS en el índice X como posición inicial, utilizándolo como pivote
						LDD CANT		
						ADDD DATOS ;Se guarda en tiempo de ejecución la posición final del arreglo de datos, además, almacena de una vez (CANT)-1 en B, útil para recorrer el arreglo
						SUBD #1
						STD ARRAYEND
LOOP1:			LDY DATOS			
LOOP2:			LDAA 1,Y+			;Se carga el contenido de Y en A y se deja apuntando Y al siguiente elemento
						CMPA 0,Y			;Se comparan ambos elementos
						BGE NO_SWAP		;Si el elemento n es mayor al n+1, se intercambian
						MOVB 0,Y -1,Y	
						STAA 0,Y  
NO_SWAP:		CPY ARRAYEND	;Verificar si el índice Y alcanzó el penúltimo elemento del arreglo, comparándolo con X predecrementado el cual apuntará a la penúltima posición del arreglo
						BLT LOOP2
						DBNE B, LOOP1
						;Luego se recorre desde el inicio copiando los elementos, omitiendo los repetidos
						LDAB CANT+1
						LDY DATOS
						LDX ORDEN
LOOP3:			LDAA 1,Y+						
						CMPA -1,X
						BEQ NOT_STORE 
						STAA 1,X+
NOT_STORE:	DBNE B, LOOP3	
						BRA *
				
		
				
				
				
				
