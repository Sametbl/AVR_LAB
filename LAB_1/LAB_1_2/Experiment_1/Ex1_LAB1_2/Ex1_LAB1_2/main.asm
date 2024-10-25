;
; Ex1_LAB1_2.asm
;
; Created: 10/17/2024 4:01:24 PM
; Author : Samet
;



.INCLUDE "M324PADEF.INC"
.ORG	00
	     LDI    R16,    0X01
	     OUT    DDRA,   R16      ; PA0= Output
START:
         SBI    PORTA,  PINA0    ; PA0 = 1 , for 2 cycle (until CBI done executing)
         CBI    PORTA,  PINA0    ; PA0 = 0 , for 3 cycles (until RJMP and SBI done executing)
         RJMP   START            ; Duty cycle = Time_on/Total_time = 2/5 = 40%

