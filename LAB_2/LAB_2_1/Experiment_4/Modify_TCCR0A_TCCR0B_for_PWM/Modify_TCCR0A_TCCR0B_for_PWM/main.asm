;
; Modify_TCCR0A_TCCR0B_for_PWM.asm
;
; Created: 10/20/2024 3:31:01 PM
; Author : Samet
;


.EQU      TCCR0A_org_ex3  =  0b10100011    ; Same as table 1
.EQU      TCCR0B_org_ex3  =  0b00000010

.EQU      TCCR0A_table_1  =  0b10100011    ; {COM0A1, COM0A0} = {COM0B1, COM0B0} = 2'b10
.EQU      TCCR0B_table_1  =  0b00000010    ; {WGM02, WGM01, WGM 00} = 3'b011
										   ; {CS02,  CS01,  CS00}   = 3'b010

.EQU      TCCR0A_table_2  =  0b10100011    ; {COM0A1, COM0A0} = {COM0B1, COM0B0} = 2'b10
.EQU      TCCR0B_table_2  =  0b00001010    ; {WGM02, WGM01, WGM 00} = 3'b111
										   ; {CS02,  CS01,  CS00}   = 3'b010

.EQU      TCCR0A_table_3  =  0b10100001    ; {COM0A1, COM0A0} = {COM0B1, COM0B0} = 2'b10
.EQU      TCCR0B_table_3  =  0b00000010    ; {WGM02, WGM01, WGM 00} = 3'b001
										   ; {CS02,  CS01,  CS00}   = 3'b010


.ORG 00 
MAIN:		 CALL  INITTIMER0 

HALT: 		 RJMP  HALT 

INITTIMER0: 
			 LDI   R16,    (1 << PB3) | (1 << PB4)			; SET OC0A (PB3) AND OC0B (PB4) PINS AS OUTPUTS 
			 OUT   DDRB,   R16	

			 LDI   R16,    TCCR0A_table_3
			 LDI   R17,    TCCR0B_table_3 
			 OUT   TCCR0A, R16								; SETUP TCCR0A 
			 OUT   TCCR0B, R17								; SETUP TCCR0B 

			 LDI   R16,    100 
			 OUT   OCR0A,  R16								; OCRA = 100 

			 LDI   R16,    75  
			 OUT   OCR0B,  R16								; OCRB = 75 
			 RET
