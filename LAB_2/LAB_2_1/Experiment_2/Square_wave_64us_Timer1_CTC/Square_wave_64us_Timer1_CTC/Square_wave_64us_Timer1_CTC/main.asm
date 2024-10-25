;
; Square_wave_64us_Timer1_CTC.asm
;
; Created: 10/20/2024 2:32:17 PM
; Author : Samet
;



; Internal clk = 8 MHz
.EQU   OCR1_val = 220     ; 1 to 65535      -2 cycles due to RJMP LOOP
.EQU   TCCR1B_mode = 0b00001001


START:			LDI    R16, 0xFF
				OUT    DDRD,     R16      ; Set OC1A  =  PD5 as Output   ( But it different pin in SimulIDE)
LOOP:			CALL   TIMER1_DELAY       ; {COM1A1, COM1A0} = 2'b01 ==> Toggle OC1A   when TCNT1 = OCR1A
				RJMP   LOOP



TIMER1_DELAY:								    ; (+3) For CALL to here  
				 LDI    R16,     0				; (+1) Clear Timer
			     STS    TCNT1H,  R16            ; (+2)
			     STS    TCNT1L,  R16            ; (+2)

				 LDI    R16,     HIGH(OCR1_val) ; (+1) Set OCR
				 STS    OCR1AH,  R16            ; (+2)
				 LDI    R16,     LOW(OCR1_val)  ; (+1)
				 STS    OCR1AL,  R16            ; (+2)

				 LDI    R16,     0b01000000		; (+1) Enable OC1A in toggle mode
				 STS    TCCR1A,  R16            ; (+2)
				 LDI    R16,     TCCR1B_mode	; (+1) Choose CTC mode
				 STS    TCCR1B,  R16            ; (+2)   -------- At this point: 20 cycles

AGAIN:           SBIS   TIFR1,  OCF1A           ; }  (Number of cycles = Prescale * OCR)
                 RJMP   AGAIN                   ; }
				                                ; (+4) the last iteration that satisfied condition
				 LDI    R16,    0				; (+1) Stop Timer
				 STS    TCCR1B, R16             ; (+2)
				 LDI    R16,    (1 << OCF1A)    ; (+1) Clear TOV flag
				 OUT    TIFR1,  R16             ; (+1)
				 RET                            ; (+4)
; ===> Total of cycles = Prescale * (OCR + 1) + 33