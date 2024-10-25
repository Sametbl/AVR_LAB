;
; Square_wave_1Khz_duty_cycle.asm
;
; Created: 10/20/2024 3:59:14 PM
; Author : Samet
;



; Internal clk = 8 MHz   ==> 1 cycle = 0.125 us
; f = 1 KHz  ==> T = 1 ms = 8000 cycles

.EQU      TCCR0A_value  =  0b00100001    ; {COM0B1, COM0B0} = 2'b10
.EQU      TCCR0B_value  =  0b00001011    ; {WGM02, WGM01, WGM 00} = 3'b101
								         ; {CS02,  CS01,  CS00}   = 3'b010

; Duty cycle = 100 * (256 - OCR)/256 
.EQU      OCR0A_value  =  62
.EQU      OCR0B_value  =  15



.ORG 00 
MAIN:		 CALL  INIT_TIMER0 

HALT: 		 RJMP  HALT 

INIT_TIMER0: 
			 LDI   R16,    (1 << PB4)				; SET OC0B (PB4) PINS AS OUTPUTS 
			 OUT   DDRB,   R16	

			 LDI   R16,    TCCR0A_value
			 LDI   R17,    TCCR0B_value 
			 OUT   TCCR0A, R16						; SETUP TCCR0A 
			 OUT   TCCR0B, R17						; SETUP TCCR0B 

			 LDI   R16,    OCR0A_value  
			 OUT   OCR0A,  R16						; OCRA = 

			 LDI   R16,    OCR0B_value  
			 OUT   OCR0B,  R16						; OCRB =  

			 RET
