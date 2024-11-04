;
; Timer0_Normal_mode.asm
;
; Created: 10/20/2024 2:04:13 PM
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
; => MAX delay = 32,77 ms 
.EQU   TCCR0B_mode = 0b00000100
.EQU   TCNT_init   = 100   ; 0 to 255

start:
				CALL   TIMER0_DELAY


TIMER0_DELAY:								    ; (+3) For CALL to here  
				 LDI    R16,    TCNT_init		; (+1) Init Timer
			     OUT    TCNT0,  R16             ; (+1)

				 LDI    R16,    0b00000000		; (+1) Choose Normal mode
				 OUT    TCCR0A, R16             ; (+1)
				 LDI    R16,    TCCR0B_mode		; (+1) Choose mode and start Timer
				 OUT    TCCR0B, R16             ; (+1)

AGAIN:           SBIS   TIFR0,  TOV0            ; }  (Number of cycles = Prescale * (256 - TCNT_init) )
                 RJMP   AGAIN                   ; }
				                                ; (+4) In the last iteration Skipped
				 LDI    R16,    0				; (+1) Stop Timer
				 OUT    TCCR0B, R16             ; (+1)
				 LDI    R16,    (1 << TOV0)    ; (+1) Clear TOV flag
				 OUT    TIFR0,  R16             ; (+1)
				 RET                            ; (+4)
; ===> Total of cycles = Prescale * (256 - TCNT_init) + 21



