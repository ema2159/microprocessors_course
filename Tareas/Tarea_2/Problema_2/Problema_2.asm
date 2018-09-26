;***********************************************************************
;												Máscaras y negativos
;***********************************************************************

		;FECHA: 28 DE SEPTIEMBRE, 2018
		;AUTOR: EMMANUEL BUSTOS TORRES 
		
;Descripción: Este programa toma dos tablas
						ORG $1000
LONG				DW 10
NUM					DW $1100
MASK				DW $1200
SAVEY				DW			 ;Variable que se utilia para guardar posición de Y
RES_POINT   DW $2000 ;Puntero que se usa para ir guardando los resultados de las máscaras
RESULT			DW $2000
						ORG $1100
						DB 1,2,3,5,4,6,8,9,10
						ORG $1200
						DB $80,$80,$80,$80,1,$80,1,1,1,1
						ORG $3000
						LDX NUM
						LDD MASK
						ADDD LONG
						TFR D Y
LOOP1:			LDAA 1,X+
						ORAA 1,-Y 
						CMPA #0
						BGE NO_NEG
						STY SAVEY
						LDY	RES_POINT
						STAA 1,Y+
						STY RES_POINT
						LDY SAVEY
NO_NEG:			CPY MASK
						BNE LOOP1
						BRA *
						
						
