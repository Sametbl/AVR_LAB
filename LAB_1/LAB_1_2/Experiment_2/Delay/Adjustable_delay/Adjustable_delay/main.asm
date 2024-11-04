;
; Adjustable_delay.asm
;
; Created: 10/17/2024 4:08:47 PM
; Author : Samet
;


; Total cycles of "DELAY" subroutine = 3ABC + 3BC + 3C + 6
; MAX delay = 49 939 971 cycles
; The internal clock of atmega324PA is 8MHz
; =>  Each cycle  =  0.125 us

; 1 ms   = 8000 cyles        => A = 1, B = 6, C = 205
; 10 ms  = 80 000 cycles     => A = 30, B = 172, C = 5 
; 100 ms = 800 000 cycles    => A = 11, B = 167, C = 133
; 1 s    = 8 000 000 cycles  => A = 52, B = 215, C = 234
; 500 ms = 4 000 000 cycles  => A = 22, B = 230, C = 252
; 50  ms = 400 000   cycles  => A = 3 , B = 178, C = 187
.ORG 00

.EQU   A = 11
.EQU   B = 167
.EQU   C = 133

MAIN_NPC:
        RCALL DELAY
		NOP
		NOP
	



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