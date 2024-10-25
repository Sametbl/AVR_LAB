;
; Debounced_press_count.asm
;
; Created: 10/21/2024 3:27:24 PM
; Author : Samet
;


;
; Press_count_LCD_andLED_bar.asm
;
; Created: 10/21/2024 2:59:41 PM
; Author : Samet
;


; PORTA  = LCD
; PORTD  = LED bar
; PORTC  = Switch (PC0)
; The button/switch is ACTIVE LOW

.ORG 00

.EQU    PIN_IN  = PINC
.EQU    PORT_IN = PORTC
.EQU    DDR_IN  = DDRC


START:			CBI    DDR_IN, 0              ; Config PC0 as Input
				LDI    R16,    0xFF           ; Config POPRTB as Output
				OUT    DDRD,   R16

				LDI    R17,   0x00			 ; Clear R17 for Counter
				OUT    PORTD, R16			 ; Also Clear PORTB

NO_DEBOUNCE:    
CHECK_PRESS:	SBIC   PINC,  0              ; When not press, PC0 = 1
				RJMP   CHECK_PRESS  

				RCALL  DELAY_50ms
				SBIC   PINC,  0              ; Second check
				RJMP   CHECK_PRESS  

				RCALL  DELAY_50ms
				SBIC   PINC,  0              ; Third check
				RJMP   CHECK_PRESS  

				RCALL  DELAY_50ms
				SBIC   PINC,  0              ; Fourth check
				RJMP   CHECK_PRESS  

				RJMP   PRESSED               ; It is legit after 4 checks


CHECK_RELEASE:  SBIS   PINC,  0              ; When holding/pressing the button, PC0 = 0
				RJMP   CHECK_RELEASE
				RJMP   CHECK_PRESS           ; When released, check for the next press (should be delayed before RJMP)
                
PRESSED:		INC    R17                   ; Increment counter by 1
				OUT    PORTD,   R17          ; Display new counter on LED bar
				RJMP   CHECK_RELEASE         ; Check when the button is release

DELAY_50ms:
				LDI   R22, 3				 ; These counter values are calculated like in ex2_LAB1_2                       
L2:				LDI   R21, 178       
L1:				LDI   R20, 187    
L0:				DEC   R20       
				BRNE  L0          
								 
				DEC   R21        
				BRNE  L1         
								 
				DEC   R22       
				BRNE  L2  					
				RET 

