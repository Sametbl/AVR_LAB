;
; Motor_control.asm
;
; Created: 11/3/2024 12:33:51 AM
; Author : Samet
;
;
; COMPARE_MATCH_50Hz_7_segment.asm
;
; Created: 11/2/2024 7:16:43 PM
; Author : Samet
;
;
; COMPARE_MATCH_with_1ms_interrupt.asm
;
; Created: 11/2/2024 6:51:00 PM
; Author : Samet
;






.CSEG
.ORG 0x0000     ; Reset vector
		JMP    MAIN

.ORG 0x000E     ; Pin Change Interrupt for PORTB
		JMP    ISR_PORTB_PIN_CHANGE


; All control switch and buttons are in same PORT 
.EQU    INPUT_CTRL_PORT = PORTD
.EQU    INPUT_CTRL_DDR  =  DDRD
.EQU    INPUT_CTRL_PIN  =  PIND
.EQU    SPEED_UP_PIN         = PIND0    ; ACTIVE LOW
.EQU    SPEED_DOWN_PIN       = PIND1    ; ACTIVE LOW
.EQU    ON_OFF_MOTOR_PIN     = PIND2    ; ACTIVE LOW
.EQU    MOTOR_DIRECTION_PIN  = PIND3    ; ACTIVE LOW


.EQU    OUTPUT_CTRL_PORT = PORTA
.EQU    OUTPUT_CTRL_DDR  =  DDRA
.EQU    OUTPUT_CTRL_PIN  =  PINA
.EQU    L298N_IN1_PIN    = PINA0
.EQU    L298N_IN2_PIN    = PINA1
.EQU    L298N_ENA_PIN    = PINA2




MAIN:
		
     	LDI    R16, 0xFF
		OUT    DDRC, R16
		SBI    DDRB, 4

		CLR    R0
		CALL   MOTOR_INIT
		CALL   TIMER0_INIT
		SEI

LOOP:   JMP    LOOP






MOTOR_INIT:  PUSH  R16
             LDI   R16, (1 << L298N_IN1_PIN) | (1 << L298N_IN2_PIN) | (1 << L298N_ENA_PIN)
			 OUT   OUTPUT_CTRL_DDR, R16

			 LDI   R16, 0x00                       ; Set Switches and Button as Input
			 OUT   INPUT_CTRL_DDR,  R16

			 LDI   R16, (1 << SPEED_UP_PIN) | (1 << SPEED_DOWN_PIN) | (1 << ON_OFF_MOTOR_PIN) | (1 << MOTOR_DIRECTION_PIN)
			 OUT   INPUT_CTRL_PORT, R16            ; Enable Pull-up resistor
			 STS   PCMSK3,          R16            ; Also Set PIN CHANGE mask 

			 LDI   R16,             (1 << PCIE3)   ; Enable Pin Chnage Interrupt
			 STS   PCICR,           R16            
			 
			 POP   R16
			 RET

			



; Internal clk = 8 MHz  <==> 0.125  ns per cycle
; Refresh rate = 50 Hz ===> Refresh period = 20 ms
; For four 7-segment LEDs, there is 5 ms delay before next LED is lit up 
; We need 5 ms delay ==> 40000 cycles


.EQU   TCNT0_INIT  = 0            ; Initialize Timer
.EQU   OCR0A_value = 125    
.EQU   OCR0B_value = 100
.EQU   TCCR0A_mode = 0b11100011   
.EQU   TCCR0B_mode = 0b00001011   ; Choose Normal mode

TIMER0_INIT:     PUSH   R16	 
				 LDI    R16,     TCNT0_INIT	     ; Initialize Timer1 value
				 OUT    TCNT0,   R16
			
				 LDI    R16,     OCR0A_value	 ; Set Compare Register A value
			     OUT    OCR0A,   R16            
				 LDI    R16,     OCR0B_value	
			     OUT    OCR0B,   R16            

				 LDI    R16,     TCCR0A_mode	; Choose mode CTC
				 OUT    TCCR0A,  R16             
				 LDI    R16,     TCCR0B_mode    ; Start Timer	 
				 OUT    TCCR0B,  R16     
				 POP    R16       
				 RET



ISR_PORTB_PIN_CHANGE:
			     PUSH   R16
				 PUSH   R17

				 SBIS   INPUT_CTRL_PIN,    SPEED_UP_PIN       
				 RJMP   SPEED_UP
				 SBIS   INPUT_CTRL_PIN,    SPEED_DOWN_PIN      
				 RJMP   SPEED_DOWN

				 SBIC   INPUT_CTRL_PIN,    ON_OFF_MOTOR_PIN      ; Check motor Power switch
				 RJMP   MOTOR_OFF
				 SBI    OUTPUT_CTRL_PORT,  L298N_ENA_PIN       ; Turn-on ENA pin, Stop motor

				 SBIC   INPUT_CTRL_PIN,    MOTOR_DIRECTION_PIN   ; Check Direction
				 RJMP   COUNTER_CLOCKWISE
				 SBI    OUTPUT_CTRL_PORT,  L298N_IN1_PIN
				 CBI    OUTPUT_CTRL_PORT,  L298N_IN2_PIN
				 RJMP   ISR_EXIT
	 
COUNTER_CLOCKWISE: 
                 CBI    OUTPUT_CTRL_PORT,  L298N_IN1_PIN
				 SBI    OUTPUT_CTRL_PORT,  L298N_IN2_PIN
				 RJMP   ISR_EXIT

MOTOR_OFF:       CBI    OUTPUT_CTRL_PORT,  L298N_ENA_PIN       ; Turn-on ENA pin, Stop motor
				 RJMP   ISR_EXIT


SPEED_UP:    	 IN     R17,   OCR0B
				 LDI    R16,   6
				 ADD    R17,   R16
				 IN     R16,   OCR0A
				 CP     R17,   R16
				 BRCC   ISR_EXIT
				 OUT    OCR0B, R17
				 RJMP   ISR_EXIT

SPEED_DOWN:      IN     R17,   OCR0B
				 LDI    R16,   6
				 SUB    R17,   R16
				 IN     R16,   OCR0A
				 CP     R17,   R16
				 BRCC   ISR_EXIT
				 OUT    OCR0B, R17
				 RJMP   ISR_EXIT

ISR_EXIT:		 POP    R17
				 POP    R16
                 RETI






				 				 

              
