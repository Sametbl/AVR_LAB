;
; Square_wave_1KHz.asm
;
; Created: 10/17/2024 4:51:13 PM
; Author : Samet
;



; The internal clock of atmega324PA is 8MHz   => Each cycle = 0.125 us
; f = 1KHz  => T = 1 ms
; => We need 0.5 ms delay  =  4000

.ORG 00

.EQU   A = 1
.EQU   B = 5
.EQU   C = 121
; Total cycles of "DELAY" subroutine = 3ABC + 3BC + 3C + 6
; MAX delay = 49 939 971 cycles


MAIN:
				   SBI     DDRA,  0     ; PA0 = Output
				   CBI     PORTA, 0     ; Clear PA0

SQUARE_WAVE:       SBI     PORTA, 0     ; PA0 on
                   RCALL   DELAY        ; Delay 0.5 ms
				   CBI     PORTA, 0     ; PA0 off
				   RCALL   DELAY        ; Delay 0.5 ms
				   RJMP    SQUARE_WAVE
	


DELAY:                    ; # of Cycle of Instr 
		LDI   R22, C      ; +1                      
L2:     LDI   R21, B      ; +1              }      
L1:	    LDI   R20, A      ; +1        }  
L0:		DEC   R20         ; +1  } L0 = 3A 
		BRNE  L0          ; +2  }
		                  ; -1        } L1 = B* (L0 + 4 -1) = 3AB + 3B  
		DEC   R21         ; +1        }
		BRNE  L1          ; +2        }
		                  ; -1              } L2 = C* (L1 + 4 -1) = 3ABC + 3BC + 3C
		DEC   R22         ; +1              }
		BRNE  L2  		  ; +2              }
		                  ; -1                      } +3 and +3 for the first 3 LDI
		RET               ; +4                      } 

; ====>  Total cycle of "DELAY" = 3ABC + 3BC + 3C + 6