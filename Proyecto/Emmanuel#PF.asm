;******************************************************
;           UCR                 II-2018
;
;           PROYECTO FINAL: Medidor 623
;
;Autor: Emmanuel Bustos Torres
;Carné: B51296
;Curso: Microproccesadores IE-623
;Descripción:
;******************************************************
#include registers.inc

;******************************************************
;     Configuración de vectores de interrupción
;******************************************************
	;	ORG $3E4C
	;	DW PTH_ISR
		ORG $3E66
		DW OC4_ISR
		ORG $3E70
		DW RTI_ISR
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
;******************************************************
;            Declaración de variables
;******************************************************
		ORG $1000
PATRON:		DS 1
REB:		DS 1
TECLA:		DS 1
VALOR:		DS 1
BAND_TEC:	DS 1   ;X:X:X:X:VALOR:PRIMERA:VALIDA:TECL_LISTA
BANDERAS	DS 1   ;X:X:Corto:Largo:Dist:S2:S1:C/M
BUFFER:		DS 1
TMP1:		DS 1
TMP2:		DS 1
TMP3:		DS 1
TECLAS:		DB $01,$02,$03,$04,$05,$06,$07,$08,$0B,$09,$00,$0E
Lmax:   	DS 1
Lmin:	  	DS 1
LEDS:       	DS 1
BRILLO:     	DS 1,
CONT_DIG:   	DS 1
CONT_TICKS: 	DS 1
DT:         	DS 1
CONT_RTI:	DS 1
BCD1:       	DS 1
BCD2:       	DS 1
DIG1:       	DS 1
DIG2:       	DS 1
DIG3:       	DS 1
DIG4:       	DS 1
INIDSP:         DB 4,FUNCTION_SET,FUNCTION_SET,ENTRY_MODE_SET,DISPLAY_ON
SEGMENT:    	DB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
CONT_7SEG:  	DS 2
CONT_DELAY: 	DS 1
D2ms:       	DB 100
D260us:     	DB 13
D40us:      	DB 2
VELOC:		DS 1
LONG:		DS 1
Ticks_VEL:	DS 2
Ticks_LONG:	DS 2
CONFIG_MSG1:	FCC " CONFIGURACION  "
		DB EOM
CONFIG_MSG2:	FCC "   Lmax:Lmin    "
		DB EOM
STOP_MSG1:	FCC "    Medidor     "
		DB EOM
STOP_MSG2:	FCC "      623       "
		DB EOM
MED_MSG1:	FCC "   Esperando    "
		DB EOM
MED_MSG2:	FCC "    Tronco      "
		DB EOM
;******************************************************
;     Programa principal y configuración inicial
;******************************************************
		ORG $1500
		;Configurar interrupción RTI
		MOVB #$31,RTICTL
		BSET CRGINT,$80
		;Configuración de interrupción Output Compare
		MOVB #$90,TSCR1
		MOVB #$10,TIOS
		MOVB #$03,TSCR2
		MOVB #$01,TCTL1
		MOVB #$10,TIE
		;Configuración de pantalla LCD
		MOVB #$FF,DDRK
		;Configuración de segmentos y LEDS
		MOVB #$FF,DDRB
		BSET DDRJ,$02
		BCLR PTJ,$02
		MOVB #$0F,DDRP
		;Configurar la mitad de los bits de teclado como entrada y la otra mitad como salida
		MOVB #$F0,DDRA
		;Habilitar resistencias de pullup
		BSET PUCR,$01
		;Habilitar instrucciones mascarables
		CLI
		;Configurar stack
		LDS #$3BFF
		;Inicializar las variables
		MOVB #$01,BAND_TEC  
		MOVB #01,LEDS
		MOVB #0,PORTB
		CLR Lmin
		CLR Lmax
		MOVB #200,CONT_RTI ;Inicializar contador de interrupción RTI
		MOVB #100,BRILLO ;Inicializar brillo
		LDD TCNT
		ADDD #60
		STD TC4
		MOVB #100,CONT_TICKS
		MOVB #1,CONT_DIG
		;Programa principal
		MOVB #$00,LEDS
		JSR INIT_DSPL
		MOVB #10,REB
		MOVB #$00,BAND_TEC
		MOVB #$FF,TMP1 ;Se colocan las variables temporales en $FF
		MOVB #$FF,TMP2 ;para indicar que se encuentran vacías 
		CLR VALOR
		MOVW #1000,Ticks_VEL
		MOVW #2300,Ticks_LONG
LOOP_FIN:	BRSET PTIH,$40,PH61 ;Se verifica el modo del medidor mediante los Dip switches
		BRCLR PTIH,$80,M_STOP ;Si ambos switches PH6 y PH7 están en 0, se entra en modo stop
		BRA M_CONFIG ;Si los switches son distintos entre sí, se entra en modo config
PH61:		BRSET PTIH,$80,M_MEDICION ;Si ambos switches PH6 y PH7 están en 1, se entra en modo medicion
M_CONFIG:	JSR CONFIG
		BRA LOOP_FIN
M_MEDICION:	JSR MEDICION	
		BRA LOOP_FIN
M_STOP:		JSR STOP
		BRA LOOP_FIN


;******************************************************
;		Subrutina medicion
;******************************************************
MEDICION:	LDAA LEDS
		CMPA #$02
		BEQ MED_CONT
		MOVB #$02,LEDS
		JSR CALCULAR
		JSR BIN_BCD
		;MOVB VELOC,BCD1
		;MOVB DIST,BCD2
		LDX #MED_MSG1
		LDY #MED_MSG2
		JSR CARG_LCD
MED_CONT:	RTS 
 
;******************************************************
;		Subrutina config
;******************************************************
CONFIG:		BSET BANDERAS,$01
		BSET CRGINT,$80
		LDAA LEDS
		CMPA #$01
		BEQ CONFIG_CONT
		MOVB #$01,LEDS
		CLR BCD1
		CLR BCD2
		JSR BCD_7SEG
		LDX #CONFIG_MSG1
		LDY #CONFIG_MSG2
		JSR CARG_LCD
CONFIG_CONT:	BRCLR BAND_TEC,$01,CONF_NOT_TEC
		JSR TECLADO
CONF_NOT_TEC:	BRCLR BAND_TEC,$08,END_CONFIG
CONFIG_MIN:	BRCLR BAND_TEC,$01,CONF_NOT_TEC2
		JSR TECLADO
CONF_NOT_TEC2:	LDAA VALOR
		CMPA #7
		BHI CONFIG_MIN
		CMPA #3
		BLO CONFIG_MIN
		MOVB VALOR,Lmin
		MOVB VALOR,BCD1
		JSR BCD_7SEG
		CLR VALOR
CONFIG_MAX:	BRCLR BAND_TEC,$01,CONF_NOT_TEC3
		JSR TECLADO	
CONF_NOT_TEC3:	LDAA VALOR
		CMPA #7
		BHI CONFIG_MAX
		CMPA Lmin
		BLO CONFIG_MAX
		MOVB VALOR,Lmax
		MOVB VALOR,BCD2
		JSR BCD_7SEG
		CLR VALOR
		BCLR BAND_TEC,$08
END_CONFIG:	BCLR CRGINT,$80
		RTS 

;******************************************************
;		Subrutina stop
;******************************************************
STOP:		LDAA LEDS
		CMPA #$04
		BEQ STOP_CONT
		MOVB #$04,LEDS
		MOVB #$FF,BCD1
		MOVB #$FF,BCD2
		LDX #STOP_MSG1
		LDY #STOP_MSG2
		JSR CARG_LCD
STOP_CONT:	RTS 

;******************************************************
;               SUBRUTINA TECLADO
;Esta subrutina se encarga de manejar la lógica corres-
;pondiente al teclado, guardando las teclas presionadas
;en variables temporales hasta que el usuario  presione
;la tecla ENTER, o decida  borrar la tecla que presionó
;haciendo uso de la tecla BORRAR.
;******************************************************
TECLADO:	LDAA TECLA ;Se carga la tecla obtenida en la subrutina RTI
		LDAB TMP1  ;Se carga TMP1
		CMPB #$FF  ;Si TMP1 contiene $FF, está vacío
		BNE TMP1FULL ;Si está lleno chequear siguiente espacio
		CMPA #$09  ;Si TECLA es mayor a 9, debe ser o B o E
		BHI RET_TECL ;Si es la primera tecla y es B o E, no se debe hacer nada
		MOVB TECLA,TMP1 ;Si es algún valor de 0 a 9, guardar en TMP1
		BRA RET_TECL 
TMP1FULL:	LDAB TMP2 ;Se verifica si TMP2 está vacío
		CMPB #$FF
		BNE TMP2FULL ;Si esá lleno, verificar la tecla que fue presionada
		CMPA #$09    ;Si está vacío verificar si es un valor de 0 a 9
		BHI B_OR_E   ;Si no, debe ser B o E
		MOVB TECLA,TMP2 ;Si es un valor de 0 a 9 guardar
		BRA RET_TECL 
B_OR_E:		CMPA #$0B ;Si es B colocar FF en TMP1 (indicar que está vacío)
		BNE NOT_B
		MOVB #$FF,TMP1
		BRA RET_TECL
NOT_B:		MOVB TMP1,VALOR ;Si es E, almacenar TMP1 en VALOR
		BSET BAND_TEC,$08 ;Indicar que se guardó un VALOR
		MOVB #$FF,TMP1 ;Vaciar TMP1
		BRA RET_TECL
TMP2FULL:	CMPA #$09 ;Si ambos temporales están llenos, verificar el valor de la última tecla presionada
		BHI B_OR_E2 ;Si esta es mayor a 9, es B o E
		BRA RET_TECL ;Si e algún valor de 0 a 9, salir
B_OR_E2:	CMPA #$0B ;Si es B colocar FF en TMP2 para vaciarlo
		BNE NOT_B2
		MOVB #$FF,TMP2
		BRA RET_TECL
NOT_B2:		LDAA TMP1 ;Si no, calcular el valor correspondiente mediante los temporales
		LDAB #10
		MUL 
		ADDB TMP2
		STAB VALOR ;y guardarlo en VALOR
		BSET BAND_TEC,$08 ;Indicar que un nuevo valor fue guardado
		MOVB #$FF,TMP1 ;Vaciar los temporales
		MOVB #$FF,TMP2
RET_TECL:	BCLR BAND_TEC,$01 ;Borrar bandera de tecla lista
		RTS 

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
BIN_BCD:	LDAB LONG ;Cargar Lmax en D
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
		LDAB VELOC ;Cargar Lmin en D
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
		LDAA BCD2   ;Cargar en valor en BDC de Lmax en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		CMPA #$F ;Si el dígito en BCD es F, no debe desplegarse
		BNE DIG1_ON
		MOVB #$00,DIG1
		BRA TO_DIG2 
DIG1_ON:	MOVB A,X DIG1 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
TO_DIG2:	LDAA BCD2   ;Cargar en valor en BDC de Lmax en A
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
TO_BCD1:	LDAA BCD1   ;Cargar en valor en BDC de Lmin en A
		ANDA #$0F   ;Quedarse solo con el dígito inferior
		CMPA #$F ;Si el dígito en BCD es F, no debe desplegarse
		BNE DIG3_ON
		MOVB #$00,DIG3
		BRA TO_DIG4 
DIG3_ON:	MOVB A,X DIG3 ;Buscar en la tabla la representación de 7 segmentos indicada para representar el valor
TO_DIG4:	LDAA BCD1   ;Cargar en valor en BDC de Lmax en A
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


;******************************************************
;		Subrutina CALCULAR
;******************************************************
CALCULAR:	LDD #5000 ;Se carga en D 5m x (1mS)^-1
		LDX Ticks_VEL 
		IDIV ;Se obtiene 5m / ((1mS)xTicks_VEL), correspondiente a la velocidad
		TFR X,A ;Se transfiere el resultado a A
		STAA VELOC ;Se guarda el resultado en VELOC
		LDAB VELOC
		CLRA ;Cargar VELOC en D (D = A:B = 00:VELOC) 
		LDY Ticks_LONG
		EMUL ;Se obtiene VELOC x Ticks_LONG 
		LDX #1000 
		IDIV ;Se obtiene VELOC x (Ticks_LONG / 1000) que es igual a VELOC x (Ticks_LONG x 1mS)
		TFR X,B ;Se transfiere el resultado a B
		STAB LONG ;Se guarda el resultado en LONG
		RTS 

;******************************************************
;           SUBRUTINA DE INTERRUPCIÓN RTI
;******************************************************
RTI_ISR:	TST REB
		LBNE DEC_REB ;Verificar si ya se terminó el período de rebotes
		MOVB #$FF,BUFFER
		MOVB #0,PATRON 
		LDAA #$EF ;Cargar en A el valor para chequear la primera fila del teclado
		LDX #TECLAS ;Cargar la tabla de teclas
LOOP_TEC:	LDAB PATRON
		CMPB #3 ;Verificar si ya se revisaron las tres filas del teclado
		BEQ FIN_LEER ;Si sí, ir a fin
		STAA PORTA ;Escribir en los primeros 4 bits del puerto A el valor correspondiente (E,D,B,7) para chequear la fila correspondiente
		LDAB #0
		BRCLR PORTA,$01,ENC_TEC ;Ver si alguno de los botones en la fila correspondiente fue presionado
		INCB 
		BRCLR PORTA,$02,ENC_TEC
		INCB 
		BRCLR PORTA,$04,ENC_TEC
		INCB 
		BRCLR PORTA,$08,ENC_TEC
		INC PATRON ;Pasar a chequear siguiente fila
		ROLA 
		BRA LOOP_TEC
ENC_TEC:	LSL PATRON 
		LSL PATRON
		ADDB PATRON ;Obtener el índice indicado para obtener el valor correspondiente de la tabla
		MOVB B,X BUFFER ;Acceder a la tabla por direccionamiento indexado por acumulador
FIN_LEER: 
		LDAA #$FF
		CMPA BUFFER ;Ver si se presionó alguna tecla
		BEQ TEC_NE ;Si no, saltar
		BRSET BAND_TEC,$04,TEC_NE ;Si PRIMERA = 1, continuar 
		BSET BAND_TEC,$04 ;Si no, colocar PRIMERA en 1
		MOVB #10,REB ;Activar rebotes
		MOVB BUFFER,TECLA ;Mover BUFFER a TECLA
		BRA RTI_RTRN ;Salir de la subrutina
TEC_NE:		LDAA TECLA ;Verificar si TECLA es $FF
		CMPA #$FF
		BEQ RTI_RTRN ;Si sí, salir
		BRSET BAND_TEC,$02,IS_VALID ;Si TECLA es válida, proceder a guardar
		CMPA BUFFER ;Verificar si TECLA es igual a BUFFER después de la supresión de rebotes
		BEQ TEC_BUFF ;Si sí, proceder
		MOVB #$FF,TECLA ;Si no, colocar TECLA en $FF y poner PRIMERA en 0
		BCLR BAND_TEC,$04
		BRA RTI_RTRN
TEC_BUFF:	BSET BAND_TEC,$02 ;Si TECLA y BUFFER son iguales, activar VALID
		BRA RTI_RTRN
IS_VALID:	LDAB BUFFER ;Verificar si la tecla fue liberada
		CMPB #$FF ;Si no, salir
		BNE RTI_RTRN 
		BSET BAND_TEC,$01 ;Si sí, colocar TECL_LISTA en 1
		BCLR BAND_TEC,$06 ;COLOCAR PRIMERA y VALID en 0
		BRA RTI_RTRN
DEC_REB:	DEC REB ;Decrementar rebotes
RTI_RTRN:	BSET CRGFLG,$80 ;Levantar bandera de RTI
		RTI 

;************************************************************************
            ;Subrutina de atención a interrupción OC4
;************************************************************************
OC4_ISR:	LDD CONT_7SEG ;Cargar el contador de refrescamiento de 7SEG
		ADDD #1
		CPD #500     ;Si este ya contó 100mS, refrescar valores
		BNE NOT_RFRSH ;Si no, continuar
		JSR BCD_7SEG
		LDD #0
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
