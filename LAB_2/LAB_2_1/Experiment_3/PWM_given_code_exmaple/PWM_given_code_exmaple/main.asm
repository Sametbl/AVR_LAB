;
; PWM_given_code_exmaple.asm
;
; Created: 10/20/2024 3:19:46 PM
; Author : Samet
;



.ORG 00 
MAIN:		 CALL  INITTIMER0 

HALT: 		 RJMP  HALT 

INITTIMER0: 
			 LDI   R16,    (1 << PB3) | (1 << PB4)			; SET OC0A (PB3) AND OC0B (PB4) PINS AS OUTPUTS 
			 OUT   DDRB,   R16	

			 LDI   R16,    (1 << COM0B1)|(1 << COM0A1) | (1 << WGM00)|(1 << WGM01) 
			 OUT   TCCR0A, R16								; SETUP TCCR0A 

			 LDI   R16,    (1 << CS01) 
			 OUT   TCCR0B, R16								; SETUP TCCR0B 

			 LDI   R16,    100 
			 OUT   OCR0A,  R16								; OCRA = 100 

			 LDI   R16,    75  
			 OUT   OCR0B,  R16								;OCRB = 75 
			 RET