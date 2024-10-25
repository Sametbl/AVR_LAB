;
; Press_count_LCD_andLED_bar.asm
;
; Created: 10/21/2024 2:59:41 PM
; Author : Samet
;


; PORTA  = LCD
; PORTB  = LED bar
; PORTC  = Switch (PC0)
; The button/switch is ACTIVE LOW

START:			CBI    DDRC,  0              ; Config PC0 as Input
				LDI    R16,   0xFF           ; Config POPRTB as Output
				OUT    DDRB,  R16

				LDI    R17,   0x00			 ; Clear R17 for Counter
				OUT    PORTB, R16			 ; Also Clear PORTB

NO_DEBOUNCE:    
CHECK_PRESS:	SBIC   PINC,  0              ; When not press, PC0 = 1
				RJMP   CHECK_PRESS  
				RJMP   PRESSED

CHECK_RELEASE:  SBIS   PINC,  0              ; When holding/pressing the button, PC0 = 0
				RJMP   CHECK_RELEASE
				RJMP   CHECK_PRESS           ; When released, check for the next press (should be delayed before RJMP)
                
PRESSED:		INC    R17                   ; Increment counter by 1
				OUT    PORTB,   R17          ; Display new counter on LED bar
				RJMP   CHECK_RELEASE         ; Check when the button is release


				
								