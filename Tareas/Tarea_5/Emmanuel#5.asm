#include registers.inc
;******************************
;Configuración de Subrutinas
;******************************
		ORG $3E70
		DW RTI_ISR
		ORG $3E4C
		DW PTH_ISR
		ORG $3E66
		DW OC4_ISR
;******************************
;Definición de comandos
;******************************
FUNCTION_SET 	EQU $28
ENTRY_MODE_SET 	EQU $06
DISPLAY_ON	EQU $0C
CLEAR_DISPLAY 	EQU $01
RETURN_HOME 	EQU $02
DDRAM_ADDR1 	EQU $80
DDRAM_ADDR2 	EQU $C0

;******************************
;Definición de caracteres
;******************************
EOM:		EQU $00
CR  		EQU $0D
LF  		EQU $0A
;******************************
;Estructuras de datos
;******************************
		ORG $1000
CONT_MAN:   	DS 1
CONT_FREE:  	DS 1
LEDS:       	DS 1
BRILLO:     	DS 1
CONT_DIG:   	DS 1
CONT_TICKS: 	DS 1
DT:         	DS 1
CONT_RTI:	DS 1
BANDERAS:	DS 1 ;X:X:X:X:X:REFRESH_MAN:REFRESH_FREE:LED_DIR
		ORG $1010
BCD1:       	DS 1
BCD2:       	DS 1
DIG1:       	DS 1
DIG2:       	DS 1
DIG3:       	DS 1
DIG4:       	DS 1
SEGMENT:    	DB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
CONT_7SEG:  	DS 2
CONT_DELAY: 	DS 1
D2ms:       	DB 100
D260us:     	DB 13
D40us:      	DB 2
CLEAR_LCD:  	DS 1
ADD_L1:		DS 1
ADD_L2: 	DS 1
INIDSP:     	DB 4,FUNCTION_SET,FUNCTION_SET,ENTRY_MODE_SET,DISPLAY_ON
MAN_MSG_1:	FCC "CONT MAN: UP  "
		DB EOM
FREE_MSG_1:	FCC "CONT FREE: UP  "
		DB EOM
MAN_MSG_2:	FCC "CONT MAN: DOWN"
		DB EOM
FREE_MSG_2:	FCC "CONT FREE: DOWN" 
		DB EOM

		ORG $2000
;************************************************************************
               ;Programa principal y configuración de hadware
;************************************************************************
		;Configurar interrupción RTI
		MOVB #$31,RTICTL
		BSET CRGINT,$80
		;Configuración de segmentos y LEDS
		MOVB #$FF,DDRB
		BSET DDRJ,$02
		BCLR PTJ,$02
		MOVB #$0F,DDRP
		;Configuración de interrupción de key wakepus
		BSET PIEH,$07
		BCLR PPSH,$07
		;Configuración de interrupción Output Compare
		MOVB #$90,TSCR1
		MOVB #$10,TIOS
		MOVB #$03,TSCR2
		MOVB #$01,TCTL1
		MOVB #$10,TIE
		;Configuración de pantalla LCD
		MOVB #$FF,DDRK
		;Habilitar instrucciones mascarables
		CLI
		;Configurar stack
		LDS #$3BFF
		;Inicializar las variables
		MOVB #$01,BANDERAS  
		MOVB #01,LEDS
		MOVB #0,PORTB
		CLR CONT_FREE
		CLR CONT_MAN
		MOVB #6,BRILLO ;Inicializar brillo
		LDD TCNT
		ADDD #60
		STD TC4
		MOVB #100,CONT_TICKS
		MOVB #1,CONT_DIG
		;Programa principal
		MOVB #$01,LEDS
		JSR INIT_DSPL
		LDX #FREE_MSG_1 ;Se carga la primera tabla con los caracteres a imprimir
		LDY #MAN_MSG_1 ;Se carga la segunda tabla con los caracteres a imprimir
		JSR CARG_LCD
		
FIN:		JSR REFRSH_LCD  
		BRA FIN





;************************************************************************
                             ;Subrutina BIN_BCD:
;Esta subrutina sigue el siguiente algoritmo. Por ejemplo, si se tiene un 
;valor de $2A en hexadecimal (42 en decimal), este se carga en el acumula-
;dor D, y se divide entre 10 mediante el índice X, quedando  $0004  en X, 
;y un  resíduo de $0002 en D, que es lo mismo que $02 en B. Luego se pasa
;el valor de X a A, quedando $04 y se desplaza 4 veces a la izquierda pa-
;ra obtener $40. Finalmente se suman A y B, quedando $42, el valor en BCD
;deseado.  
;************************************************************************
BIN_BCD:	LDAB CONT_MAN ;Cargar CONT_MAN en D
		CLRA ;Limpiar parte alta de D
		LDX #10
		IDIV ;D/X = X, r = D
		TFR X,A ;Pasar X a A
		LSLA ;Desplazar 4 veces
		LSLA 
		LSLA 
		LSLA 
		ABA ;Sumar A y B
		BITA #$F0
		BNE NOT_ZERO ;Si el nibble superior es 0, se le guarda $F
		ORAA #$F0
NOT_ZERO:	STAA BCD1
		LDAB CONT_FREE ;Cargar CONT_FREE en D
		CLRA ;Limpiar parte alta de D
		LDX #10
		IDIV ;D/X = X, r = D
		TFR X,A ;Pasar X a A
		LSLA ;Desplazar 4 veces
		LSLA 
		LSLA 
		LSLA 
		ABA ;Sumar A y B
		BITA #$F0
		BNE NOT_ZERO2 ;Si el nibble superior es 0, se le guarda $F
		ORAA #$F0
NOT_ZERO2:	STAA BCD2 
		RTS 
		
;************************************************************************
                        ;Subrutina BCD_7SEG:
;Esta subrutina se encarga de tomar los valores en  las  variales BCD1 y 
;BCD2, y se encarga de colocarlas en las variables  DIG1,  DIG2,  DIG3 y 
;DIG4, codificados para ser desplegados en los displays  de  7 segmentos
;************************************************************************

BCD_7SEG:	LDX #SEGMENT ;Cargar la dirección de la tabla SEGMENT en X
		LDAA BCD2   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		MOVB A,X DIG1 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
		LDAA BCD2   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$F0   ;Quedarse solo con el dígito superior
		LSRA 
		LSRA 
		LSRA 
		LSRA 
		CMPA #$F ;Si el dígito en BCD es F, no debe desplegarse
		BNE DIG2_ON
		MOVB #$00,DIG2
		BRA TO_BCD1 
DIG2_ON:	MOVB A,X DIG2 ;Buscar en la tabla la representación de 7 segmentos indicada para el valor		
TO_BCD1:	LDAA BCD1   ;Cargar en valor en BDC de CONT_FREE en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		MOVB A,X DIG3 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
		LDAA BCD1   ;Cargar en valor en BDC de CONT_MAN en A
		ANDA #$F0   ;Quedarse solo con el dígito superior
		LSRA 
		LSRA 
		LSRA 
		LSRA 
		CMPA #$F ;Si el dígito en BCD es F, no debe desplegarse
		BNE DIG4_ON
		MOVB #$00,DIG4
		BRA OUT_7SEG 
DIG4_ON:	MOVB A,X DIG4 ;Buscar en la tabla la representación de 7 segmentos indicada para el valor
OUT_7SEG:	RTS 
		

;************************************************************************
            ;Subrutina de atención a interrupción RTI
;************************************************************************

RTI_ISR:	DEC CONT_RTI
		BNE SALTO
		MOVB #200,CONT_RTI
		BRSET	PTIH,$40,RTI_ASC ;Si PH6=0, CONT_FREE=DESCENDENTE
		LDAA CONT_FREE
		CMPA #0
		BHI DEC_FREE ;Si se intenta decrementar CONT_FREE cuando este es 0, se pasa a 99
		MOVB #99,CONT_FREE 
		BRA RTI_SALTO1
DEC_FREE:	DEC CONT_FREE
		BRA RTI_SALTO1
RTI_ASC:	LDAA CONT_FREE
		CMPA #99
		BLO INC_FREE ;Si se intenta incrementar CONT_FREE cuando este es 99, se pasa a 0
		MOVB #0,CONT_FREE
		BRA RTI_SALTO1
INC_FREE:	INC CONT_FREE
RTI_SALTO1:	BRSET BANDERAS,$01,L2R ;Aquí se define el sentido de los LEDs
		LSL LEDS ;Aquí se desplazan los LEDs hacia la izquierda
		BCC SALTO
		LDAA BANDERAS
		EORA #$01
		STAA BANDERAS
		MOVB #$40,LEDS
		BRA SALTO
L2R:		LSR LEDS ;Aquí se desplazan los LEDs hacia la derecha
		BCC SALTO
		LDAA BANDERAS
		EORA #$01
		STAA BANDERAS
		MOVB #$02,LEDS
SALTO:		BSET CRGFLG,$80
		RTI 
		

;************************************************************************
            ;Subrutina de atención a interrupción PTH
;************************************************************************
PTH_ISR:	BRCLR PIFH,$01,PTH2 ;Si no se está presionando botón 1, chequear botón 2
		BRSET	PTIH,$80,PTH_ASC ;Si PH7=0, CONT_MAN=DESCENDENTE
		LDAA CONT_MAN
		CMPA #0
		BHI DEC_MAN ;Si se intenta decrementar CONT_MAN cuando este es 0, se pasa a 99
		MOVB #99,CONT_MAN
		BRA PTH_OUT
DEC_MAN:	DEC CONT_MAN
		BRA PTH_OUT
PTH_ASC:	LDAA CONT_MAN
		CMPA #99
		BLO INC_MAN ;Si se intenta incrementar CONT_FREE cuando este es 99, se pasa a 0
		MOVB #0,CONT_MAN
		BRA PTH_OUT
INC_MAN:	INC CONT_MAN
		BRA PTH_OUT
PTH2:		BRCLR PIFH,$02,PTH3 ;Si no se está presionando botón 1, chequear botón 3
		LDAA BRILLO ;Si brillo es 0, no se puede decrementar más, salir
		BEQ PTH_OUT
		DEC BRILLO	
		BRA PTH_OUT	
PTH3:		LDAA BRILLO ;Si brillo es 100, no se puede incrementar más, salir
		CMPA #100
		BEQ PTH_OUT
		INC BRILLO
		BRA PTH_OUT	
PTH_OUT:	
		BSET PIFH,$07
		RTI 


;************************************************************************
            ;Subrutina de atención a interrupción OC4
;************************************************************************
OC4_ISR:	LDD CONT_7SEG ;Cargar el contador de refrescamiento de 7SEG
		ADDD #1
		CPD #5000     ;Si este ya contó 100mS, refrescar valores
		BNE NOT_RFRSH ;Si no, continuar
		JSR BIN_BCD
		JSR BCD_7SEG
NOT_RFRSH:	STD CONT_7SEG
		LDAA #100 ;Cargar en a el valor de N para calcular DT
		SUBA BRILLO ;Calcular DT = N-K
		STAA DT 
		LDAA CONT_TICKS 
		CMPA DT ;Si CONT_TICKS=DT, cumplido ciclo de trabajo, bajar señal
		BHI OC_BRIGHT
		MOVB #00,PORTB
OC_BRIGHT:	DEC CONT_TICKS ;Si CONT_TICKS=0, pasar a siguiente display
		BNE OUT_OC 
		MOVB #100,CONT_TICKS  
		BSET PTJ,$02  ;Apagar LEDS
		BRCLR CONT_DIG,$01,OC_NEXT1 ;Si bit 1 de CONT_DIG encendido encender display 1
		MOVB #$F7,PTP
		MOVB DIG3,PORTB
OC_NEXT1:	BRCLR CONT_DIG,$02,OC_NEXT2 ;Si bit 2 de CONT_DIG encendido encender display 2
		MOVB #$FB,PTP
		MOVB DIG4,PORTB
OC_NEXT2:	BRCLR CONT_DIG,$04,OC_NEXT3 ;Si bit 3 de CONT_DIG encendido encender display 3
		MOVB #$FD,PTP
		MOVB DIG1,PORTB
OC_NEXT3:	BRCLR CONT_DIG,$08,OC_NEXT4 ;Si bit 4 de CONT_DIG encendido encender display 4
		MOVB #$FE,PTP
		MOVB DIG2,PORTB
OC_NEXT4:	BRCLR CONT_DIG,$10,CHG_DIG ;Si bit 5 de CONT_DIG encendido encender LEDs
		MOVB #$FF,PTP
		BCLR PTJ,$02
		MOVB LEDS,PORTB
CHG_DIG:	LDAA CONT_DIG 
		CMPA #$10   ;Si se está en LEDs (00010000) pasar a display 1 (00000001)
		BLO SHIFT_DIG
		LDAA #$01
		BRA STORE_DIG
SHIFT_DIG:	LSLA ;Se desplaza CONT_DIG para ir cambiando de display (00000001 = display 1, 00000010 = display 2...)
STORE_DIG:	STAA CONT_DIG
OUT_OC:		LDAA CONT_DELAY
		BEQ DELAY_ZERO
		DEC CONT_DELAY ;Se decrementa CONT_DELAY siempre que no sea cero
DELAY_ZERO:	LDD TCNT ;Ajustar el OC del canal 4
		ADDD #60
		STD TC4
		RTI 

;************************************************************************
            ;Subrutina Delay
;************************************************************************
DELAY:		 TST CONT_DELAY	
		 BNE DELAY
		 RTS 

;************************************************************************
            ;Subrutina SEND_CMND
;************************************************************************
SEND_CMND:	PSHA 
		ANDA #$F0 ;Se deja solo el nibble superior del comando a ejecutar
		LSRA 
		LSRA 
		STAA PORTK
		BCLR PORTK,$01 ;Se habilita el envío de comandos
		BSET PORTK,$02 ;Se escribe sobre la LCD
		MOVB D260us,CONT_DELAY
		JSR DELAY
		BCLR PORTK,$02 ;Se deshabilita escritura sobre la LCD
		PULA 
		ANDA #$0F ;Se deja solo el nibble inferior del comando a ejecutar
		LSLA 
		LSLA 
		STAA PORTK
		BSET PORTK,$02 ;Se escribe sobre la LCD
		MOVB D260us,CONT_DELAY
		JSR DELAY
		BCLR PORTK,$02 ;Se deshabilita escritura sobre la LCD
		RTS 

;************************************************************************
            ;Subrutina SEND_DATA
;************************************************************************
SEND_DATA:	PSHA 
		ANDA #$F0 ;Se deja solo el nibble superior del dato a enviar
		LSRA 
		LSRA ;Se deja el nibble superior en la posición PORTK.5-PORTK.2
		STAA PORTK
		BSET PORTK,$01 ;Se habilita el envío de datos
		BSET PORTK,$02 ;Se escribe sobre la LCD
		MOVB D260us,CONT_DELAY 
		JSR DELAY
		BCLR PORTK,$02 ;Se deshabilita escritura sobre la LCD
		PULA 
		ANDA #$0F ;Se deja solo el nibble inferior del dato a enviar
		LSLA 
		LSLA ;Se deja el nibble inferior en la posición PORTK.5-PORTK.2
		STAA PORTK
		BSET PORTK,$01 ;Se habilita envío de datos
		BSET PORTK,$02 ;Se escribe sobre la LCD
		MOVB D260us,CONT_DELAY
		JSR DELAY
		BCLR PORTK,$02 ;Se deshabilita escritura sobre la LCD
		RTS 


;************************************************************************
                      ;Subrutina INIT_DSPL
;************************************************************************
INIT_DSPL:	LDX #INIDSP+1 ;Se carga en X la tabla que contiene los comandos de inicialización
		LDAB #0 ;Se carga 0 en B
COMMANDS:	LDAA B,X ;Se accede a la tabla de comandos mediante direccionamiento indexado por acumulador
		JSR SEND_CMND ;Se ejecuta cada comando
		MOVB D40us,CONT_DELAY
		JSR DELAY
		INCB 
		CMPB INIDSP ;Si ya se ejecutaron todos los comandos de la tabla, terminar comandos de inicialización
		BNE COMMANDS
		LDAA #CLEAR_DISPLAY ;Cargar comando de limpiar pantalla
		JSR SEND_CMND ;Ejecutar comando de limpiar pantalla
		MOVB D2ms,CONT_DELAY
		JSR DELAY
		RTS 

;************************************************************************
                      ;Subrutina CARG_LCD
;************************************************************************
CARG_LCD:	LDAA #DDRAM_ADDR1	;Se carga la dirección de la primera posición de la primera fila de la LCD
		JSR SEND_CMND ;Se ejecuta el comando
		MOVB D40uS,CONT_DELAY
		JSR DELAY
CARG_1:		LDAA 1,X+ ;Se carga cada caracter en A
		BEQ CARG_2 ;Si se encuentra un caracter de EOM ($00) se terminó de imprimir la primera fila
		JSR SEND_DATA ;Se imprime cada caracter
		MOVB D40us,CONT_DELAY
		JSR DELAY
		BRA CARG_1 
CARG_2:		LDAA #DDRAM_ADDR2 ;Se carga la dirección de la primera posición de la segunda fila de la LCD
		JSR SEND_CMND
		MOVB D40us,CONT_DELAY 
		JSR DELAY
CARG_3:		LDAA 1,Y+ ;Se carga cada caracter en A
		BEQ OUT_CARG ;Si se encuentra un caracter de EOM ($00) se terminó de imprimir la primera fila
		JSR SEND_DATA ;Se imprime cada caracter
		MOVB D40us,CONT_DELAY
		JSR DELAY
		BRA CARG_3
OUT_CARG:	RTS 
		
		
		
;************************************************************************
;                   Subrutina REFRSH_LCD
;************************************************************************
REFRSH_LCD:	BRSET PTIH,$40,FREE_ASC ;Si PH6=0, CONT_FREE=DESCENDENTE
		BRCLR BANDERAS,$02,FREE_OUT ;Se verifica si ya está desplegado en la pantalla "DOWN", sino desplegar y cambiar bandera
		LDAA #DDRAM_ADDR1 ;Se carga la dirección de la primera posición de la primera fila de la LCD
		JSR SEND_CMND ;Se ejecuta el comando
		MOVB D40uS,CONT_DELAY
		JSR DELAY
		LDX #FREE_MSG_2
FREE_1:		LDAA 1,X+ ;Se carga cada caracter en A
		BEQ FREE_2 ;Si se encuentra un caracter de EOM ($00) se terminó de imprimir la primera fila
		JSR SEND_DATA ;Se imprime cada caracter
		MOVB D40us,CONT_DELAY
		JSR DELAY
		BRA FREE_1
FREE_2:		BCLR BANDERAS,$02 ;Actualizar bandera		 
		BRA FREE_OUT
FREE_ASC:	BRSET BANDERAS,$02,FREE_OUT ;Se verifica si ya está desplegado en la pantalla "UP", sino desplegar y cambiar bandera 
		LDAA #DDRAM_ADDR1	;Se carga la dirección de la primera posición de la primera fila de la LCD
		JSR SEND_CMND ;Se ejecuta el comando
		MOVB D40uS,CONT_DELAY
		JSR DELAY
		LDX #FREE_MSG_1
FREE_3:		LDAA 1,X+ ;Se carga cada caracter en A
		BEQ FREE_4 ;Si se encuentra un caracter de EOM ($00) se terminó de imprimir la primera fila
		JSR SEND_DATA ;Se imprime cada caracter
		MOVB D40us,CONT_DELAY
		JSR DELAY
		BRA FREE_3
FREE_4:		BSET BANDERAS,$02 ;Actualizar bandera	
FREE_OUT:	BRSET PTIH,$80,MAN_ASC ;Si PH6=0, CONT_FREE=DESCENDENTE
		BRCLR BANDERAS,$04,MAN_OUT ;Se verifica si ya está desplegado en la pantalla "DOWN", sino desplegar y cambiar bandera
		LDAA #DDRAM_ADDR2 ;Se carga la dirección de la primera posición de la primera fila de la LCD
		JSR SEND_CMND ;Se ejecuta el comando
		MOVB D40uS,CONT_DELAY
		JSR DELAY
		LDX #MAN_MSG_2
MAN_1:		LDAA 1,X+ ;Se carga cada caracter en A
		BEQ MAN_2 ;Si se encuentra un caracter de EOM ($00) se terminó de imprimir 
		JSR SEND_DATA ;Se imprime cada caracter
		MOVB D40us,CONT_DELAY
		JSR DELAY
		BRA MAN_1
MAN_2:		BCLR BANDERAS,$04 ;Actualizar bandera	 
		BRA MAN_OUT
MAN_ASC:	BRSET BANDERAS,$04,MAN_OUT ;Se verifica si ya está desplegado en la pantalla "UP", sino desplegar y cambiar bandera
		LDAA #DDRAM_ADDR2	;Se carga la dirección de la primera posición de la segunda fila de la LCD
		JSR SEND_CMND ;Se ejecuta el comando
		MOVB D40uS,CONT_DELAY
		JSR DELAY
		LDX #MAN_MSG_1
MAN_3:		LDAA 1,X+ ;Se carga cada caracter en A
		BEQ MAN_4 ;Si se encuentra un caracter de EOM ($00) se terminó de imprimir
		JSR SEND_DATA ;Se imprime cada caracter
		MOVB D40us,CONT_DELAY
		JSR DELAY
		BRA MAN_3
MAN_4:		BSET BANDERAS,$04 ;Actualizar bandera	 
MAN_OUT:	RTS 

