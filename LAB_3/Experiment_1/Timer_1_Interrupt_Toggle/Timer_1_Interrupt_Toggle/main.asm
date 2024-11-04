;
; Timer_1_Interrupt_Toggle.asm
;
; Created: 11/2/2024 4:52:39 PM
; Author : Samet
;

.ORG 0x0000     ; Reset vector
		JMP    MAIN

.ORG 0x001E     ; Timer1 Overflow Interrupt vector
		JMP    ISR_TIMER1_OF 


MAIN:			LDI    R16,   HIGH(RAMEND)   ; Initialize Stack, for Good practice
				OUT    SPH,   R16
				LDI    R16,   LOW(RAMEND)
				OUT    SPL,   R16

				SBI    DDRC,   0            ; Set PC0 as Output 
				CBI    PORTC,  0            ; Clear PC0

				LDI    R16, (1 << TOIE1)    ; Enable Timer1 Overflow Interrupt
			    STS    TIMSK1, R16

				CALL   TIMER1_INIT          ; Config and start Timer1
				SEI                         ; Enable Global interrupt


INF_LOOP:		RJMP   INF_LOOP             ; Do  "other tasks", let ISR generate 1 KHz wave 


	

; Internal clk = 8 MHz  <==> 0.125  ns per cycle
; f = 1 KHz ==> T = 1 ms 
; We need 0.5 ms delay ==> 4000 cycles
; In Normal mode, TCNT will start (reset) at 65535 - 4000 = 61535

.EQU   TCNT1_INIT  = 61552        ; Adjusted to match 1 KHz frequency on simulation
.EQU   TCCR1A_mode = 0b00000000   ; Normal mode
.EQU   TCCR1B_mode = 0b00000001   ; No Prescaler mode


TIMER1_INIT:	 LDI    R16, HIGH(TCNT1_INIT)	; Initialize Timer1 value
			     STS    TCNT1H,  R16            
				 LDI    R16, LOW (TCNT1_INIT)	
			     STS    TCNT1L,  R16            

				 LDI    R16,     TCCR1A_mode	; Enable OC1A and Mode 
				 STS    TCCR1A,  R16             
				 LDI    R16,     TCCR1B_mode    ; Start Timer	 
				 STS    TCCR1B,  R16            
				 RET


              

ISR_TIMER1_OF:   PUSH   R16						; Reserved register values
				 PUSH   R17
		 		 
				 LDI    R16, HIGH(TCNT1_INIT)	; Reset Timer1 value
			     STS    TCNT1H,  R16            
				 LDI    R16, LOW (TCNT1_INIT)	 
			     STS    TCNT1L,  R16            

				 IN     R16,   PINC             ; Read state of PC0
				 LDI    R17,   (1 << PC0)       ; Create a mask for PC0
				 EOR    R16,   R17              ; Toggle PC0
				 OUT    PORTC, R16  

				 POP    R17						; Restore register values
				 POP    R16
				 RETI                          
