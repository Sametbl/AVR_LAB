;
; Timer1_delay.asm
;
; Created: 10/19/2024 4:59:01 PM
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


; Internal clk = 8 MHz
; 1 ms   = 8 000 cycels     => Prescale = 1   , OCR_val = 7966    + 1 
; 10 ms  = 80 000 cycels    => Prescale = 8   , OCR_val = 9995    + 1
; 100 ms = 800 000 cycels   => Prescale = 64  , OCR_val = 12498   + 1
; 1 s    = 8 000 000 cycels => Prescale = 256 , OCR_val = 31249   - 1

.EQU   OCR1_val = 31249     ; 1 to 65535
.EQU   TCCR1B_mode = 0b00001100

start:
				CALL TIMER1_DELAY
				NOP
				NOP
				RJMP start






TIMER1_DELAY:								    ; (+3) For CALL to here  
				 LDI    R16,     0				; (+1) Clear Timer
			     STS    TCNT1H,  R16            ; (+2)
			     STS    TCNT1L,  R16            ; (+2)

				 LDI    R16,     HIGH(OCR1_val) ; (+1) Set OCR
				 STS    OCR1AH,  R16            ; (+2)
				 LDI    R16,     LOW(OCR1_val)  ; (+1)
				 STS    OCR1AL,  R16            ; (+2)

				 LDI    R16,     0b00000000		; (+1)
				 STS    TCCR1A,  R16            ; (+2)
				 LDI    R16,     TCCR1B_mode	; (+1) Choose mode and start Timer
				 STS    TCCR1B,  R16            ; (+2) Choose CTC mode  -------- 20 cycles

AGAIN:           SBIS   TIFR1,  OCF1A           ; }  (Number of cycles = Prescale * OCR)
                 RJMP   AGAIN                   ; }
				                                ; (+4) the last iteration that satisfied condition
				 LDI    R16,    0				; (+1) Stop Timer
				 STS    TCCR1B, R16             ; (+2)
				 LDI    R16,    (1 << OCF1A)    ; (+1) Clear TOV flag
				 OUT    TIFR1,  R16             ; (+1)
				 RET                            ; (+4)
; ===> Total of cycles = Prescale * (OCR + 1) + 33


