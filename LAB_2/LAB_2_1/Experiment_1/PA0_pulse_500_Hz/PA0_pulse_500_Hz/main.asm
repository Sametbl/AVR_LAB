;
; PA0_pulse_500_Hz.asm
;
; Created: 10/19/2024 5:14:53 PM
; Author : Samet
;



; Internal clk = 8 MHz
; f = 500 Hz   ==> T = 2 ms (Period between each pulse)
; 2 ms = 16 000 cycles    => Prescale = 64 , OCR_val = 249 +22
 
.EQU   OCR0_val = 249     ; 0 to 255
.EQU   TCCR0B_mode = 0b00000011

start:
				SBI    DDRA,    0      ; Set PA0 as Output
				CBI    PORTA,   0      ; Clear PA0
				
PULSE_500Hz:    SBI    PORTA,   0
				CBI    PORTA,   0
				RCALL  TIMER0_DELAY
				RJMP   PULSE_500Hz

TIMER0_DELAY:								    ; (+3) For CALL to here  
				 LDI    R16,    0				; (+1) Clear Timer
			     OUT    TCNT0,  R16             ; (+1)

				 LDI    R16,    OCR0_val        ; (+1) Set OCR
				 OUT    OCR0A,  R16             ; (+1)

				 LDI    R16,    0B00000010		; (+1) Choose CTC mode
				 OUT    TCCR0A, R16             ; (+1)
				 LDI    R16,    TCCR0B_mode		; (+1) Choose mode and start Timer
				 OUT    TCCR0B, R16             ; (+1)

AGAIN:           SBIS   TIFR0,  OCF0A           ; }  (Number of cycles = Prescale * OCR)
                 RJMP   AGAIN                   ; }
				                                ; (+2) when Skipped
				 LDI    R16,    0				; (+1) Stop Timer
				 OUT    TCCR0B, R16             ; (+1)
				 LDI    R16,    (1 << OCF0A)    ; (+1) Clear TOV flag
				 OUT    TIFR0,  R16             ; (+1)
				 RET                            ; (+4)
; ===> Total of cycles = Prescale * (OCR + 1) + 21



