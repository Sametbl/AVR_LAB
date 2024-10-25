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
		 LDI     R16,      0x00    ; Config PORTA as Input   (DIP switch)
		 OUT     DDR_IN,   R16
		 LDI     R16,      0xFF   ; Config PORTB as Output  (LED bar)
		 OUT     PORT_IN,  R16
		 OUT     DDR_OUT,  R16

		 LDI     R16,      0x00   ; Clear PORTB
		 OUT     PORT_OUT, R16

LOOP:    IN      R17,      PIN_IN      
         COM     R17              ; State LED bar is inverse of PORT pins 
		 MOV     R18,      R17

		 ANDI    R17,      0x0F   ; Mask the lower nibble of PORTA
		 SWAP    R17              ; Swap or shift left, so that sign bit is MSB
		 ASR     R17              ; Arithmetic right shift 4 times
		 ASR     R17
		 ASR     R17
		 ASR     R17
		 
		 ANDI    R18,      0XF0   ; Mask the higher (swapped) nibble of PORTA
		 ASR     R18              ; The sign bit is already MSB
		 ASR     R18              ; Arithmetic right shift 4 times
		 ASR     R18
		 ASR     R18

		 		                  ; Multiply Upper Nibble with Lower Nibble
		 MULS    R17,      R18    ; 4-bit X 4-bit = 8-bit, Result = {R1, R0} 
		 OUT     PORT_OUT, R0     ; Only care about R0 (first 8-bit of the result)
		 RJMP    LOOP

