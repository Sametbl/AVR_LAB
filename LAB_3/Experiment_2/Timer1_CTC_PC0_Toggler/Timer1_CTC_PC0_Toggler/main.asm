;
; Timer1_CTC_PC0_Toggler.asm
;
; Created: 11/2/2024 6:34:50 PM
; Author : Samet
;


; Search in "m324Pdef.inc" for the correct Interrupt Vector
 
.ORG 0x0000     ; Reset vector
		JMP    MAIN

.ORG 0x001A     ; Timer1 Compare Match A Interrupt vector
		JMP    COMPARE_MATCH


MAIN:			LDI    R16,   HIGH(RAMEND)   ; Initialize Stach, for good practice
				OUT    SPH,   R16
				LDI    R16,   LOW(RAMEND)
				OUT    SPL,   R16

				SBI    DDRC,   0             ; Set PC0 as Output 
				CBI    PORTC,  0             ; Clear PC0

				LDI    R16, (1 << OCIE1A)    ; Enable Output Compare Match A for Timer1
			    STS    TIMSK1, R16

				CALL   TIMER1_INIT           ; Select CTC mode and start Timer
				SEI                          ; Enable Global interrupt

INF_LOOP:		RJMP   INF_LOOP              ; Do "other tasks", let ISR generate 100 Hz pulse


			

; Internal clk = 8 MHz  <==> 0.125  ns per cycle
; f = 100 Hz ==> T = 10 ms  ==> 80000
; 80000 cycles  ==> OCR1A = 10000,   Prescaler = 8

.EQU   TCNT1_INIT  = 0            ; Initialize Timer, start at 0
.EQU   OCR1A_value = 9999         ; Adjusted to match the desired frequency on simulation
.EQU   TCCR1A_mode = 0b00000000   ; Choose mode CTC
.EQU   TCCR1B_mode = 0b00001010   ; No Prescaler


TIMER1_INIT:	 LDI    R16, HIGH(TCNT1_INIT)	; Initialize Timer1 value, not necessary
			     STS    TCNT1H,  R16            
				 LDI    R16, LOW (TCNT1_INIT)	
			     STS    TCNT1L,  R16            

				 LDI    R16, HIGH(OCR1A_value)	; Set OCR1A value
			     STS    OCR1AH,  R16            
				 LDI    R16, LOW (OCR1A_value)	
			     STS    OCR1AL,  R16            


				 LDI    R16,     TCCR1A_mode	; Select CTC mode
				 STS    TCCR1A,  R16             
				 LDI    R16,     TCCR1B_mode    ; Start Timer	 
				 STS    TCCR1B,  R16            
				 RET


              
COMPARE_MATCH: 	 SBI    PORTC,   0				; Pulse PC0
				 ;NOP
				 CBI    PORTC,   0		
				 RETI                          
