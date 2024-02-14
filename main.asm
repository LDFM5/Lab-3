;******************************************************************************
; Universidad del Valle de Guatemala
; Programación de Microcrontroladores
; Proyecto: Lab2
; Archivo: main.asm
; Hardware: ATMEGA328p
; Created: 6/02/2024 19:49:14
; Author : Luis Furlán
;******************************************************************************
; Encabezado
;******************************************************************************

.include "M328PDEF.inc"
.cseg //Indica inicio del código
.org 0x00 //Indica el RESET
;******************************************************************************
; Stack
;******************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16 
LDI R17, HIGH(RAMEND)
OUT SPH, R17
;******************************************************************************
; Configuración
;******************************************************************************
Setup:
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 ;HABILITAMOS EL PRESCALER
	LDI R16, 0b0000_0100
	STS CLKPR, R16 ; DEFINIMOS UNA FRECUENCIA DE 1MGHz

	LDI R16, 0b0011_0000 ; CONFIGURAMOS LOS PULLUPS en PORTC
	OUT PORTC, R16	; HABILITAMOS EL PULLUPS
	LDI R16, 0b0000_1000
	OUT DDRC, R16	;Puertos C (entradas y salidas)

	LDI R16, 0xFF
	OUT DDRD, R16	;Puertos D (entradas y salidas)
	LDI R16, 0x1F
	OUT DDRB, R16	;Puertos B (entradas y salidas)

	CALL timer0 ; activar el timer 0

	// Representaciones de los números hexadecimales para el display
	tabla: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71 

	//Se define ZL y ZH y luego se muestra en el display el primer valor de la tabla que sería el 3F (0)
Main:
	LDI ZH, HIGH(tabla << 1)
	LDI ZL, LOW(tabla << 1)
	LPM R19, Z
	SBRS R19, 0
	CBI	PORTD, PD2
	SBRC R19, 0
	SBI PORTD, PD2
	SBRS R19, 1
	CBI	PORTD, PD3
	SBRC R19, 1
	SBI PORTD, PD3
	SBRS R19, 2
	CBI	PORTD, PD4
	SBRC R19, 2
	SBI PORTD, PD4
	SBRS R19, 3
	CBI	PORTD, PD5
	SBRC R19, 3
	SBI PORTD, PD5
	SBRS R19, 4
	CBI	PORTD, PD6
	SBRC R19, 4
	SBI PORTD, PD6
	SBRS R19, 5
	CBI	PORTD, PD7
	SBRC R19, 5
	SBI PORTD, PD7
	SBRS R19, 6
	CBI	PORTB, PB0
	SBRC R19, 6
	SBI PORTB, PB0

	;Limpiar registros
	CLR R16
	CLR R17
	CLR R18
	CLR R21
	CLR R22
	CLR R23

	LDI R20, 0x10

Loop:

	IN R16, TIFR0 ; banderas en donde se encuentra la de overflow a R16 
	SBRS R16, TOV0 ; Si está encendida la bandera de overflow no regresa al loop
	RJMP Loop

	LDI R16, 98 ; Cargar el valor calculado en donde debería iniciar.
	OUT TCNT0, R16
	SBI TIFR0, TOV0 ; Apagar la bandera de overflow

	;--------------------
	;Chequeo de antirebote
	MOV R18, R21
	IN R21, PINC
	CP R21, R18
	BREQ timer_cont
	CALL Delay
	IN R21, PINC
	CP R18, R21
	BREQ timer_cont

	SBRS R21, PC4	;botón 1
	RJMP dec_disp
	SBRS R21, PC5	;botón 2
	RJMP inc_disp
	;--------------------
timer_cont:

	CPI R16, 0x0F ; si el contador llega a los 4 bits se reinicia el contador
	BRNE incrementar
	RJMP  reset

;******************************************************************************
; Subrutinas (funciones)
;******************************************************************************
timer0:
	OUT TCCR0A, R16 ; modo normal

	LDI R16, (1 << CS02) | (1 << CS00)
	OUT TCCR0B, R16 ; prescaler 1024

	LDI R16, 98 ; valor calculado donde inicia a contar
	OUT TCNT0, R16
	RET

;******************************************************************************

incrementar: //Incrementa el contador binario
	CPI R22, 10 // Realiza 10 vueltas antes de incrementar para que incremente cada segundo en vez de cada 100 ms
	BREQ incr
	INC R22
	RJMP Loop
incr:
	INC R17
	CLR R22
	RJMP leds

;******************************************************************************

reset:
	LDI R17, 0x00 //resetea el contador binario
	RJMP leds

;******************************************************************************

leds: //muestra el valor del contador en las leds
	CALL alarma
	SBRS R17, 0
	CBI	PORTB, PB1
	SBRC R17, 0
	SBI PORTB, PB1
	SBRS R17, 1
	CBI	PORTB, PB2
	SBRC R17, 1
	SBI PORTB, PB2
	SBRS R17, 2
	CBI	PORTB, PB3
	SBRC R17, 2
	SBI PORTB, PB3
	SBRS R17, 3
	CBI	PORTB, PB4
	SBRC R17, 3
	SBI PORTB, PB4
	RJMP Loop

;******************************************************************************

inc_disp: //incrementa el valor del display
	INC ZL
	INC R23
	CPI R19, 0x71
	BREQ reset_disp
	LPM R19, Z
	RJMP display7
reset_disp: //Si llega a F lo resetea para que continue en 0
	LDI ZL, LOW(tabla << 1)
	LPM R19, Z
	CLR R23
	RJMP display7


;******************************************************************************

dec_disp: // decrementa el valor del diplay
	DEC ZL
	DEC R23
	CPI R19, 0x3F
	BREQ top_disp
	LPM R19, Z
	RJMP display7
top_disp: //Si llega a 0 regresa el contador a F para que continue desde ahí
	ADD ZL, R20
	LPM R19, Z
	LDI R23, 0x0F
	RJMP display7

;******************************************************************************

display7: //Muestra el valor del contador en el display
	SBRS R19, 0
	CBI	PORTD, PD2
	SBRC R19, 0
	SBI PORTD, PD2
	SBRS R19, 1
	CBI	PORTD, PD3
	SBRC R19, 1
	SBI PORTD, PD3
	SBRS R19, 2
	CBI	PORTD, PD4
	SBRC R19, 2
	SBI PORTD, PD4
	SBRS R19, 3
	CBI	PORTD, PD5
	SBRC R19, 3
	SBI PORTD, PD5
	SBRS R19, 4
	CBI	PORTD, PD6
	SBRC R19, 4
	SBI PORTD, PD6
	SBRS R19, 5
	CBI	PORTD, PD7
	SBRC R19, 5
	SBI PORTD, PD7
	SBRS R19, 6
	CBI	PORTB, PB0
	SBRC R19, 6
	SBI PORTB, PB0
	RJMP timer_cont

;******************************************************************************

delay: //delay para el anti-rebote
	LDI R16, 100
Ldelay:
	DEC R16
	BRNE Ldelay ; Se repite si no es igual a 0
	RET

;******************************************************************************

alarma: //Alarma que avisa cuando el contador binario y del display son iguales.
	CP R17, R23 //Compara si son iguales
	BREQ alarm
	RET
alarm: //Sí son iguales reinicia el contador binario
	CLR R17
	SBIS PORTC, PC3 //Dependiendo del estado de la led decide si encender o apargarla
	RJMP encender
	RJMP apagar
encender: //Enciende la led si estaba apagada
	SBI PORTC, PC3
	RET
apagar: //apaga la led si estaba encendida
	CBI PORTC, PC3
	RET