;***************************************************
;		Tarea #6
;Autor: Emmanuel Bustos Torres
;Descripción: Esta tarea consiste en la utilización 
;de la interfaz de comunicación serial SCI y el con-
;vertidor analógico digital, mediante los cuales se
;simula un sistema de control de nivel para un tanque
;***************************************************
#include registers.inc
;***************************************************
;           DECLARACIÓN DE PARÁMETROS	
;***************************************************

BR 		EQU 14400	
NP 		EQU $0C
EOM 		EQU $00
BS		EQU $08
NL		EQU $0A
CR		EQU $0D
ESC		EQU $1B
LETTERA		EQU $41
BAR		EQU $5B
;***************************************************
;	DEFINICIÓN DE VECTORES DE INTERRUPCIÓN
;***************************************************
		ORG $3E52
		DW ATD0_ISR
		ORG $3E54
		DW SCI_ISR
		ORG $3E70
		DW RTI_ISR
		ORG $1000
;***************************************************
;       DEFINICIÓN DE MENSAJE Y VARIABLES	
;***************************************************
		ORG $1000
Nivel_PROM:	DS 1
NIVEL:		DS 1
VOLUMEN:	DS 1
CONT_RTI:	DS 1
BANDERAS:	DS 1 ; X:X:X:X:ÚLTIMA_LÍNEA:TANQUE_VACÍO:TANQUE_LLENO:INITIAL_MSG
VOL_MSG:	DB BS,BS,BS,BS,BS,BS
		DS 3
		FCC " m3"
		DB EOM
MSG: 		FCC " MEDIDOR DE VOLUMEN DE TANQUE"
		DB NL,CR
		FCC "VOLUMEN:       "
		DB EOM

LLENO_MSG:	DB NL,CR
		FCC "TANQUE LLENO, BOMBA APAGADA"
		DB ESC,BAR,1,LETTERA ;Código ANSI para subir el cursor
		DB CR
		FCC "VOLUMEN:       "
		DB EOM
VACIO_MSG:	DB NL,CR
		FCC "ALARMA, NIVEL BAJO         "
		DB ESC,BAR,1,LETTERA ;Código ANSI para subir el cursor
		DB CR
		FCC "VOLUMEN:       "
		DB EOM
NORMAL_MSG:	DB NL,CR
		FCC "                           "
		DB ESC,BAR,1,LETTERA ;Código ANSI para subir el cursor
		DB CR
		FCC "VOLUMEN:       "
		DB EOM
OFFSET:		DS 1	
;***************************************************
;	      PROGRAMA PRINCIPAL
;***************************************************
		ORG $2000
		;Configuración de interrupción RTI
		MOVB #$7F,RTICTL
		BSET CRGINT,$80
		;Configuración de interrupción SCI
		MOVW #78,SC1BDH
		MOVB #$12,SC1CR1
		MOVB #$48,SC1CR2
		;Configuración de interrupción de convertidor A/D
		MOVB #$C2,ATD0CTL2
		LDAA #200
AD_CONF:	DBNE A,AD_CONF
		MOVB #$28,ATD0CTL3
		MOVB #$93,ATD0CTL4
		MOVB #$87,ATD0CTL5
		;Configuración del relay
		BSET DDRE,$04
		;Cargar Stack
		LDS #$3BFF
		;Habilitar interrupiones mascarables
		CLI
		CLR OFFSET	
		CLR BANDERAS
		LDAA SC1SR1
		MOVB #NP,SC1DRL
		MOVB #8,CONT_RTI
		BRA *	
;***************************************************
;             SUBRUTINA CALCULO
;***************************************************
		;Cálculo de nivel
CALCULO:	LDAA Nivel_PROM
		LDAB #20 ;Como valor de plena escala de sensor es 20
		MUL ;se obtiene NIVEL = Nivel_PROM x (20/255)
		LDX #255
		IDIV 
		TFR X,B
		STAB NIVEL ;Se guarda nivel
		;Cálculo de volumen
		LDY #1256 ;2 x 3,14 x 4 x 100
		EMUL 
		LDX #100 ;Se divide entre 100 pues previamente se multiplicó por 100
		IDIV 
		TFR X,B
		STAB VOLUMEN ;Se guarda volumen
		;Generación de caracteres ASCII para impresión de volumen
		LDY #(VOL_MSG+6)
		LDX #100
		IDIV ;Se obtienen las centenas dividiendo volmen entre 100, las decenas y unidades se quedan en el resíduo (D)
		TFR X,A 
		ORAA #$30
		STAA 1,Y+ ;Se guardan las centenas en formato ASCII
		CLRA 
		LDX #10
		IDIV ;Se obtienen las decenas dividiendo lo restante entre 10, quedando las decenas en X y las unidades en D
		TFR X,A 
		ORAA #$30
		STAA 1,Y+ ;Se guardan las decenas en formato ASCII
		ORAB #$30
		STAB 0,Y  ;Se guardan las unidades en formato ASCII
		;Banderas de lleno o vacío
		LDAA VOLUMEN
		CMPA #169 ;Se verifica si ya se alcanzó el 90% de la capacidad volumétrica del tanque
		BLO CALC_NXT1
		BSET BANDERAS,$02 ;Si sí, se levanta la bandera respectiva
		BRA CALC_OUT
CALC_NXT1:	CMPA #18 ;Se verifica si ya se se está por debajo del 10% de la capacidad volumétrica del tanque
		BHI CALC_NXT2 
		BSET BANDERAS,$04 ;Si sí, se levanta la bandera respectiva
		BRA CALC_OUT
CALC_NXT2:	CMPA #37
		BLO CALC_OUT
		BCLR BANDERAS,$06 ;Si el tanque se encuentra en un nivel normal, se mantienen las dos banderas en bajo
CALC_OUT:	RTS 

;***************************************************
;	      INTERRUPCION RTI
;***************************************************
RTI_ISR:	TST CONT_RTI
		BNE DEC_RTI ;Si no ha terminado el intervalo de un segundo, proceder a descontar y salir
		JSR CALCULO ;Obtener volumen en formato ASCII y levantar banderas necesarias
		BRCLR BANDERAS,$02,RTI_NXT1 ;Si la bandera de tanque lleno está levantada, abrir relé
		BCLR PORTE,$04 
		BRA RTI_NXT1
RTI_NXT1:	BRCLR BANDERAS,$04,RTI_NXT2 ;Si la bandera de tanque vacío está levantada, cerrar relé
		BSET PORTE,$04
RTI_NXT2:	MOVB #$48,SC1CR2 ;Habilitar interfaz SCI
		MOVB #8,CONT_RTI ;Guardar contador para duración de 1 segundo
		BRA SALTO 
DEC_RTI:	DEC CONT_RTI 
SALTO:		BSET CRGFLG,$80
		RTI 
;***************************************************
;	      INTERRUPCION SCI
;***************************************************
SCI_ISR:	;BRCLR SC1SR1,$80,SCI_OUT
		BRSET BANDERAS,$01,SCI_NXT1 ;Si la bandera de mensaje inicial está en bajo, imprimir mensaje inicial, si no, seguir
		LDAA SC1SR1 
		LDX #MSG ;Cargar mensaje
		LDAB OFFSET
		LDAA B,X ;Imprimir caracter a caracter el mensaje inicial
		CMPA EOM
		BEQ CLEAR_MSG1 ;Si se está en el final del mensaje inicial, pasar a levantar bandera de inicial y apagar interfaz
		STAA SC1DRL
		INC OFFSET
		LBRA SCI_OUT
CLEAR_MSG1:	MOVB #$00,SC1CR2 ;Apagar interfaz
		BSET BANDERAS,$01
		CLR OFFSET
		LBRA SCI_OUT
SCI_NXT1:	BRSET BANDERAS,$08,SCI_NXT2 ;Si la bandera de impresión de mensaje inferior está levantada, proceder a imprimir mensaje según banderas
		LDAA SC1SR1 
		LDX #VOL_MSG ;Cargar mensaje de volumen
		LDAB OFFSET
		LDAA B,X ;Imprimir caracter a caracter el mensaje inicial
		CMPA EOM
		BEQ CLEAR_MSG2 ;Si se está en el final del mensaje inicial, pasar a levantar bandera de inicial y apagar interfaz
		STAA SC1DRL
		INC OFFSET
		BRA SCI_OUT
CLEAR_MSG2:	MOVB #$00,SC1CR2 ;Apagar interfaz
		BSET BANDERAS,$08 ;Esta bandera se levanta para indicar que se debe imprimir el mensaje inferior
		CLR OFFSET
		BRA SCI_OUT
SCI_NXT2:	BRCLR BANDERAS,$02,SCI_NXT3 ;Si bandera de tanque lleno levantada, imprimir mensaje de tanque lleno, sino, seguir
		LDAA SC1SR1 
		LDX #LLENO_MSG ;Cargar mensaje de volumen
		LDAB OFFSET
		LDAA B,X ;Imprimir caracter a caracter el mensaje de tanque lleno
		CMPA EOM
		BEQ CLEAR_MSG3 
		STAA SC1DRL
		INC OFFSET
		BRA SCI_OUT
CLEAR_MSG3:	BCLR BANDERAS,$08 ;Limpiar bandera de mensaje inferior
		CLR OFFSET
		BRA SCI_OUT
SCI_NXT3:	BRCLR BANDERAS,$04,SCI_NXT4 ;Si bandera de tanque vacío levantada, imprimir mensaje de tanque vacío, sino, seguir
		LDAA SC1SR1 
		LDX #VACIO_MSG ;Cargar mensaje de volumen
		LDAB OFFSET
		LDAA B,X ;Imprimir caracter a caracter el mensaje de alarma de tanque vacío
		CMPA EOM
		BEQ CLEAR_MSG4 
		STAA SC1DRL
		INC OFFSET
		BRA SCI_OUT
CLEAR_MSG4:	BCLR BANDERAS,$08 ;Limpiar bandera de mensaje inferior
		CLR OFFSET
		BRA SCI_OUT
SCI_NXT4:	LDAA SC1SR1 ;Si ninguna bandera está levantada, limpiar mensaje inferior 
		LDX #NORMAL_MSG ;Cargar mensaje de volumen
		LDAB OFFSET
		LDAA B,X ;Imprimir una serie de espacios para borrar mensajes de alarma presentes en caso de haberlos
		CMPA EOM
		BEQ CLEAR_MSG5 
		STAA SC1DRL
		INC OFFSET
		BRA SCI_OUT
CLEAR_MSG5:	BCLR BANDERAS,$08 ;Limpiar bandera de mensaje inferior
		CLR OFFSET
		BRA SCI_OUT
SCI_OUT:	RTI		
;************************************************************************
                      ;Subrutina ATD0_ISR
;************************************************************************
ATD0_ISR:	LDD ADR00H ;Sumar cinco mediciones
		ADDD ADR01H			
		ADDD ADR02H			
		ADDD ADR03H			
		ADDD ADR04H 	
		LDX #5 
		IDIV  ;Obtener el promedio dividiendo entre 5
		TFR X,B 
		STAB Nivel_PROM ;Guardar el resultado en Nivel_PROM
		MOVB #$87,ATD0CTL5 ;Volver a leer canal
		RTI	
