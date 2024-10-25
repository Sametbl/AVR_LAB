;
; DIP_switch_LED.asm
;
; Created: 10/17/2024 2:06:44 PM
; Author : Samet
;


; DIP switch OFF => Input HIGH  => LED off
; DIP switch ON  => Input LOW   => LED on 
; PORTA = Switch  (Input)
; PORTB = LED     (Output)

.EQU  DDR_IN   = PORTA
.EQU  PIN_IN   = PINA
.EQU  DDR_OUT  = DDRC
.EQU  PORT_OUT = PORTC


.ORG 00
		 LDI     R16,      0x00   ; Config PORTA as Input   (DIP Switch)
		 OUT     DDR_IN,   R16
		 LDI     R16,      0xFF   ; Config PORTB as Output  (LED bar)
		 OUT     DDR_OUT,  R16

		 LDI     R16,      0x00   ; Clear PORTB
		 OUT     PORT_OUT, R16

LOOP:    IN      R17,      PIN_IN ; R17 = PORTA
         COM     R17              ; State of LED bar is inverse of PORT pins
		 OUT     PORT_OUT, R17    ; Assign COM(PORTA) to LED bar
		 RJMP    LOOP
