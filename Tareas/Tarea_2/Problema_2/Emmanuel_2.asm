;***********************************************************************
;												Máscaras y negativos
;***********************************************************************

		;FECHA: 28 DE SEPTIEMBRE, 2018
		;AUTOR: EMMANUEL BUSTOS TORRES 
		
;Descripción: Este programa toma dos tablas, recorrienda una desde la primera 
;posición a la última y la segunda desde la última a la primera, aplicando una
;operación OR a entre los términos que se van obteniendo de dicha manera, y 
;guardando los números negativos en una posición de memoria definida
						ORG $1000
LONG				DW 10
NUM					DW $1100
MASK				DW $1200
SAVEY				DS 2			 ;Variable que se utilia para guardar posición de Y
RES_POINT   DS 2 			 ;Puntero que se usa para ir guardando los resultados de las máscaras. No se utiliza RESULT para recorrer pues no se desea perder esa dirección
RESULT			DW $2000
						ORG $1100
						DB 1,2,3,5,4,6,8,9,10,15 ;Tabla de números
						ORG $1200
						DB $80,$80,$80,$80,1,$80,1,1,1,1 ;tabla de máscaras
						ORG $3000
						MOVW RESULT, RES_POINT ;Inicializar puntero para recorrer resultado
						LDX NUM
						LDD MASK		
						ADDD LONG
						TFR D Y			;Se deja apuntando al registro Y al último elemento de la tabla de máscaras
LOOP1:			LDAA 1,X+
						ORAA 1,-Y 	
						CMPA #0				
						BGE NO_NEG			;Se realiza la operación lógica OR y se verifica si el resultado obtenido es negativo y si sí, se guarda
						STY SAVEY				;Se almacena en una variable temporal Y pues va a ser utilizado y no se desea perder la posición a la que apunta
						LDY	RES_POINT		;Se almacena en Y la última posición del arreglo de resultado
						STAA 1,Y+				;Se guarda A en dicha posición y se corre la variable que apunta a la última posición disponible en el arreglo de resultados en 1
						STY RES_POINT		;Se actualiza en memoria dicha variable
						LDY SAVEY				;Se recupera el índice Y
NO_NEG:			CPY MASK				;Se verifica si ya se recorrieron las tablas en su totalidad
						BNE LOOP1
						BRA *
						
						
