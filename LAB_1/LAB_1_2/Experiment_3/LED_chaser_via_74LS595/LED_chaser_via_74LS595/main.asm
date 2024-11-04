;
; LED_chaser_via_74LS595.asm
;
; Created: 10/17/2024 6:31:59 PM
; Author : Samet
;




; The internal clock of atmega324PA is 8MHz
; =>  Each cycle  =  0.125 us
; 500 ms = 4 000 000 cycles   => A = 22, B = 230, C = 252

; PA0 = SRCLK
; PA1 = RCLK
; PA2 = DS or SER (serial input)
; PA3 = SRCLR  (active LOW clear shift register)

.ORG 00

MAIN:
			  LDI     R16,    0x0F   ; Config P0 -> P3 as OUTPUT
			  OUT     DDRA,   R16

			  CBI     PORTA,  3      ; Pulse SRCLR pin to (clear shift register)
			  SBI     PORTA,  3      ; SRCLR pin is ACTIVE LOW

CHASE_UP:     LDI     R17,    0x08
              SBI     PORTA,  2      ; PA2 = SER = 1
              
LOOP_UP:      SBI     PORTA,  0      ; pulse PA0 = SRCLK
			  CBI     PORTA,  0 

			  SBI     PORTA,  1      ; pulse PA1 = RCLK
			  CBI     PORTA,  1     

			  RCALL   DELAY          ; Delay 500 ms
			  DEC     R17 
			  BRNE    LOOP_UP
			  RJMP    CHASE_DOWN



CHASE_DOWN:   LDI     R17,    0x08
              CBI     PORTA,  2      ; PA2 = SER = 0
              
LOOP_DOWN:    SBI     PORTA,  0      ; pulse PA0 = SRCLK
			  CBI     PORTA,  0 

			  SBI     PORTA,  1      ; pulse PA1 = RCLK
			  CBI     PORTA,  1     

			  RCALL   DELAY
			  DEC     R17 
			  BRNE    LOOP_DOWN
			  RJMP    CHASE_UP



DELAY:                    ; # of Cycle of Instr 
		LDI   R22, 22     ; +1                      
L2:     LDI   R21, 230    ; +1              }      
L1:	    LDI   R20, 252    ; +1        }  
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