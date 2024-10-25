;
; DIP_switch_LED.asm
;
; Created: 10/17/2024 2:06:44 PM
; Author : Samet
;


; PA0 = button (active LOW)
; PA1 = LED    (one of the LED bar)
; Press and hold => LED turns ON
; Release        => LED turns OFF

.ORG 00
				 CBI     DDRA,  0         ; Config PA0 as Input   (Active low switch)
				 SBI     DDRA,  1         ; Config PA1 as Output  (LED)

				 SBI     PORTA, 0         ; Enable pull up resistor
				 CBI     PORTA, 1         ; clear PA1

CHECK_PRESS:     SBIS    PINA,  0         ; Button is ACTIVE-LOW
                 RJMP    LED_ON
				 RJMP    CHECK_PRESS      ; Wait for the button to be pressed
				 
CHECK_RELEASE:   SBIC    PINA,  0        
				 RJMP    LED_OFF		  ; Looping while holding the button
				 RJMP    CHECK_RELEASE    ; Wait for the button to be released 

LED_ON:          SBI     PORTA, 1         ; Turn on LED then check for release
				 RCALL   DELAY
                 RJMP    CHECK_RELEASE 

LED_OFF:         CBI     PORTA, 1         ; Turn off LED then check for the next press
				 RCALL   DELAY
                 RJMP    CHECK_PRESS 



DELAY:                    ; # of Cycle of Instr 
		LDI   R22, 3      ; +1                      
L2:     LDI   R21, 178      ; +1              }      
L1:	    LDI   R20, 187      ; +1        }  
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
