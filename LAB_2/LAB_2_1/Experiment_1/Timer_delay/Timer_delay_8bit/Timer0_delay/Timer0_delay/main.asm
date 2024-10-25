;
; Timer0_delay.asm
;
; Created: 10/19/2024 5:02:41 PM
; Author : Samet
;


; Last 3 bits of TCCR0B = CS[2:0]
; CS[2:0] = 3'b000  ==> Timer Stop
; CS[2:0] = 3'b001  ==> Prescale = 1
; CS[2:0] = 3'b010  ==> Prescale = 8
; CS[2:0] = 3'b011  ==> Prescale = 64
; CS[2:0] = 3'b100  ==> Prescale = 256
; CS[2:0] = 3'b101  ==> Prescale = 1024
; CS[2:0] = 3'b110  ==> External clk, Negedge
; CS[2:0] = 3'b111  ==> External clk, Posedge
; MAX delay = 262 160 cycles

; Internal clk = 8 MHz
; 1 ms = 8 000 cycles    => Prescaler = 64  , OCR_val = 124   -22
; 10 ms = 80 000 cycles  => Prescaler = 1024, OCR_val = 77    + 107


.EQU   OCR0_val = 77     ; 0 to 255
.EQU   TCCR0B_mode = 0b00000101

start:
				CALL TIMER0_DELAY
				NOP
				NOP
				RJMP start



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



