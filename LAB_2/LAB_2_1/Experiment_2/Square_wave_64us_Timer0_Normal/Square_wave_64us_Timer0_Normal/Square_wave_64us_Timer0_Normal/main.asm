;
; Square_wave_64us_Timer0_Normal.asm
;
; Created: 10/20/2024 1:38:36 PM
; Author : Samet
;


 ; NOTE: The OC0 typically not controlled in Normal mode
 ;       It usually change value when TCNT = OCR, which is only the case in CTC or PWM mode
 ;       The OC0A or OC0B pins on Atmega324PA are pin PB3 and PB4, we will assume OC0 = PB3

start:
				CALL   TIMER0_DELAY
				SBI    DDRB,    3      ; Set PB3 as Output
				CBI    PORTB,   3      ; Clear PB3
				
SQUARE_64us:    SBI    PORTB,   3
				RCALL  TIMER0_DELAY
				CBI    PORTB,   3
				RCALL  TIMER0_DELAY
				RJMP   SQUARE_64us






; Last 3 bits of TCCR0B = CS[2:0]
; CS[2:0] = 3'b000  ==> Timer Stop
; CS[2:0] = 3'b001  ==> Prescale = 1
; CS[2:0] = 3'b010  ==> Prescale = 8
; CS[2:0] = 3'b011  ==> Prescale = 64
; CS[2:0] = 3'b100  ==> Prescale = 256
; CS[2:0] = 3'b101  ==> Prescale = 1024
; Internal clk = 8 MHz
; Total of cycles = Prescale * (256 - TCNT_init) + 21


; Internal clk = 8 MHz    ==>  1 cycle = 0.125 us
; Square wave with T = 64 us  and f = 15625
; ==> We need 32 us delay = 256 cycles - 2 cycles (because of SBI and CBI delay)
.EQU   TCCR0B_mode = 0b00000001
.EQU   TCNT_init   = 23   ; 0 to 255

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



