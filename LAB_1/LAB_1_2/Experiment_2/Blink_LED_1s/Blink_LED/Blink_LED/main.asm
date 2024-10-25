;
; Square_wave_1KHz.asm
;
; Created: 10/17/2024 4:51:13 PM
; Author : Samet
;







; The internal clock of atmega324PA is 8MHz   => Each cycle = 0.125 us
; 1 s    = 8 000 000 cycles  => A = 52, B = 215, C = 234

.ORG 00


; Total cycles of "DELAY" subroutine = 3ABC + 3BC + 3C + 6
; MAX delay = 49 939 971 cycles


MAIN:
				   SBI     DDRA,  0     ; PA0 = LED = Output
				   CBI     PORTA, 0     ; Clear PA0

BLINKING:	       SBI     PORTA, 0     ; PA0 = 1, LED on
                   RCALL   DELAY        ; Delay 1s
				   CBI     PORTA, 0     ; PA0 = 0, LED off
				   RCALL   DELAY        ; Delay 1 s
				   RJMP    BLINKING

DELAY:                    ; # of Cycle of Instr 
		LDI   R22, 52      ; +1                      
L2:     LDI   R21, 215      ; +1              }      
L1:	    LDI   R20, 234      ; +1        }  
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