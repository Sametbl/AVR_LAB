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


.EQU  DDR_IN   = DDRA
.EQU  PIN_IN   = PINA
.EQU  PORT_IN  = PORTA
.EQU  DDR_OUT  = DDRC
.EQU  PORT_OUT = PORTC


.ORG 00
		 LDI     R16,      0x00      ; Config PORTA as Input   (DIP switch)
		 OUT     DDR_IN,   R16
		 LDI     R16,      0xFF      ; Config PORTB as Output  (LED bar)
		 OUT     PORT_IN,  R16
		 OUT     DDR_OUT,  R16

		 LDI     R16,      0x00      ; Clear PORTB
		 OUT     PORT_OUT, R16

LOOP:    IN      R17,      PIN_IN     
         COM     R17                 ; State LED bar is inverse of PORT pins 
		 MOV     R18,      R17
		 ANDI    R17,      0x0F      ; Mask the lower nibble of PORTA
		 
	;	 IN      R18,      PIN_IN      
	;	 COM     R18                 ; State LED bar is inverse of PORT pins 
		 SWAP    R18                 ; SWAP the nibble
		 ANDI    R18,      0X0F      ; Mask the higher (swapped) nibble of PORTA

		                             ; Multiply Upper Nibble with Lower Nibble
		 MUL     R17,      R18       ; 4-bit X 4-bit = 8-bit, Result in stored in {R1, R0} 
		 OUT     PORT_OUT, R0        ; Only care about R0 (first 8-bit of the result)
		 RJMP    LOOP
