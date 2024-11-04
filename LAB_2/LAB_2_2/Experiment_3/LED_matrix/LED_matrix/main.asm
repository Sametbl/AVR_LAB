;
; LED_matrix.asm
;
; Created: 10/27/2024 1:08:42 PM
; Author : Samet
;

.INCLUDE "M324PADEF.INC"  ; INCLUDE ATMEGA324PA DEFINITIONS 

.ORG 0x0000 ; INTERRUPT VECTOR TABLE 
		RJMP RESET_HANDLER ; RESET 

.ORG 0x001A ; Timer 1 Compare A Interrupt Vector
		RJMP TIMER1_COMP_ISR 

; J38 CONNECT TO PORTD 
; CLEAR signal pin to PIN 0 of PORTB 
; SHIFT CLOCK pin to PIN 1 of PORTB 
; LATCH pin to PIN 0 of PORTB 
; SHIFT DATA pin to PIN 3 of PORTB 
 
.EQU SHIFT_REGISTER_PORT = PORTB
.EQU SHIFT_REGISTER_DDR  =  DDRB
.EQU CLEAR_SIGNAL_PIN = 3       ; SET CLEAR SIGNAL PIN TO PIN 3 OF PORTB
.EQU SHIFT_CLK_PIN    = 2       ; SET SHIFT CLOCK PIN TO PIN 2 OF PORTB 
.EQU LATCH_PIN        = 1       ; SET LATCH PIN TO PIN 1 OF PORTB 
.EQU SHIFT_DATA_PIN   = 0       ; SET SHIFT DATA PIN TO PIN 0 OF PORTB 
 
.EQU LEDMATRIX_PORT = PORTD        
.EQU LEDMATRIX_DDR  =  DDRD 



RESET_HANDLER: 
LDI  R16, 0xFF
OUT  DDRC, R16
CLR  R10

		LDI  R16, HIGH(RAMEND)				; Initialize stack pointer 
		OUT  SPH, R16 
		LDI  R16, LOW(RAMEND) 
		OUT  SPL, R16 

		CALL SHIFT_REGISTER_INIT_PORT 
		CALL SHIFT_REGISTER_CLEAR_DATA 
		CALL INIT_TIMER1_CTC				; Start Timer in CTC and enable Compare A Interrupt

		SEI									; Enable global interrupt 
		CALL LEDMATRIX_PORT_INIT 

MAIN: 	JMP  MAIN 


SHIFT_REGISTER_INIT_PORT:							   ; Initialize PORTS as Outputs 
		 PUSH R24 
		 LDI  R24, (1 << CLEAR_SIGNAL_PIN) | (1 << SHIFT_CLK_PIN) | (1 << LATCH_PIN) | (1 << SHIFT_DATA_PIN); 
		 OUT  SHIFT_REGISTER_DDR,  R24                 ; Set SHIFT_REGISTER_PORT as OUTPUT 
		 POP  R24 
		 RET 
 
SHIFT_REGISTER_CLEAR_DATA: 
		 CBI  SHIFT_REGISTER_PORT, CLEAR_SIGNAL_PIN     ; Pulse CLEAR pin of the Shift Register (ACTIVE LOW)                         
		 NOP									 	 
		 SBI  SHIFT_REGISTER_PORT, CLEAR_SIGNAL_PIN    
		 RET 

; Shift out R27 to bar LED 
SHIFT_REGISTER_OUT_DATA:							
		 PUSH R18 
		 CBI  SHIFT_REGISTER_PORT,  SHIFT_CLK_PIN      ; Clk = Low
		 CBI  SHIFT_REGISTER_PORT,  LATCH_PIN			
		 LDI  R18, 8							       ; Counter to track 8-bit shift 
SHIFT_LOOP: 

		 SBRC R27, 7								   ; Check if the MSB of shiftdata is 1 
		 SBI  SHIFT_REGISTER_PORT,  SHIFT_DATA_PIN     ; Set shift data pin to high 
		 NOP
		 SBI  SHIFT_REGISTER_PORT,  SHIFT_CLK_PIN      ; Set shift clock pin to high 
		 LSL  R27								       ; Shift left 
		 CBI  SHIFT_REGISTER_PORT,  SHIFT_CLK_PIN      ; Set shift clock pin to low 
		 NOP
		 CBI  SHIFT_REGISTER_PORT,  SHIFT_DATA_PIN     ; Set shift data pin to low 
		 DEC  R18 
		 BRNE SHIFT_LOOP 

		 SBI  SHIFT_REGISTER_PORT,  LATCH_PIN	       ; Pulse Latch pin to update Output
		 CBI  SHIFT_REGISTER_PORT,  LATCH_PIN			
		 POP  R18 
		 RET 
 

LEDMATRIX_COL_CONTROL: .DB 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01   ; LOOKUP table for column control 
LEDMATRIX_FONT_A:      .DB 0b11111100, 0b00010010, 0b00010001, 0b00010001, 0b00010010, 0b11111100, 0b00000000, 0b00000000    ; LOOKUP TABLE FOR FONT 


.DSEG 
.ORG SRAM_START   ; Starting address is 0x100 
LEDMATRIXBUFFER:     .BYTE 8 
LEDMATRIX_COL_index: .BYTE 1


.CSEG 
.ALIGN 2 

LEDMATRIX_PORT_INIT: 
		 PUSH R20 
		 PUSH R21 
		 LDI  R20,   0xFF						 ; Set PORT as OUTPUT 
		 OUT  LEDMATRIX_DDR,  R20 
		 OUT  LEDMATRIX_PORT, R20                ; Turn off all LED matrix before sending data

		 LDI  R20,   0							 ; COL index START AT 0 
		 LDI  ZH ,   HIGH(LEDMATRIX_COL_index) 
		 LDI  ZL ,   LOW (LEDMATRIX_COL_index) 
		 ST   Z  ,   R20                         ; Initialize Column index VAR to start at 0

		 LDI  ZH ,   HIGH(LEDMATRIX_FONT_A << 1) ; Z Register point to fonta value 
		 LDI  ZL ,   LOW (LEDMATRIX_FONT_A << 1) 
		 LDI  YH ,   HIGH(LEDMATRIXBUFFER)       ; Y Register point to fonta value 
		 LDI  YL ,   LOW (LEDMATRIXBUFFER) 
		 LDI  R20,   8                           ; Column Tracker/Counter


LEDMATRIX_PORT_INIT_LOOP:						 ; COPY FONT TO DISPLAY BUFFER 
		 LPM  R21,   Z+							 ; Load all 8 bytes of Column data for displaying letter A
		 ST   Y+ ,   R21						 ; Store those all 8 bytes of Column data into Y (VAR)
		 DEC  R20                                ; 
		 CPI  R20,   0							 ; If the Final Column is reached Exit Loop

		 BRNE LEDMATRIX_PORT_INIT_LOOP 
		 POP  R21 
		 POP  R20 
		 RET 


; INPUT: R27 CONTAINS THE VALUE TO DISPLAY 
;        R26 CONTAIN THE COL INDEX (3..0) 
LEDMATRIX_DISPLAY_COL:										; DISPLAY A COLLUMN OF LED MATRIX 
		 PUSH R16											; SAVE THE TEMPORARY REGISTER 
		 PUSH R27 

		 LDI  R16,   0xFF
		 OUT  LEDMATRIX_PORT,    R16						; Turn of all LEDs when changing data
		 CALL SHIFT_REGISTER_OUT_DATA                       ; Output of Shift Register = R27

		 LDI  ZH ,   HIGH(LEDMATRIX_COL_CONTROL << 1) 
		 LDI  ZL ,   LOW (LEDMATRIX_COL_CONTROL << 1) 

		 CLR  R16										; Clear R16 to and add only carry from ZL to ZH
		 ADD  ZL,   R26 
		 ADC  ZH,   R16 
		 LPM  R27,  Z 
 ;COM  R27
		 OUT  LEDMATRIX_PORT,    R27 

		 CALL DELAY
		 POP  R27											; RESTORE THE TEMPORARY REGISTER 
		 POP  R16 
		 RET												; RETURN FROM THE FUNCTION 



TIMER1_COMP_ISR: 
		 PUSH R16 
		 PUSH R26 
		 PUSH R27 

		 CLR  R16 

		 LDI  ZH ,   HIGH(LEDMATRIX_COL_index)              ; Column index = 0   (initially)
		 LDI  ZL ,   LOW (LEDMATRIX_COL_index) 
		 LD   R26,   Z                                      ; R26 = Column index
ISR_LOOP_DISPLAY_COL:

		 LDI  ZH ,   HIGH(LEDMATRIXBUFFER)                  ; 
		 LDI  ZL ,   LOW (LEDMATRIXBUFFER) 
		 ADD  ZL ,   R26									; Add the column index to get correct column data
		 ADC  ZH ,   R16 
		 LD   R27,   Z                                      ; Load to column data to R27
		 CALL LEDMATRIX_DISPLAY_COL                         ; Display content in R27 to Shift Register
  
		 INC  R26                                           ; Increment column index
		 CPI  R26,   8 
		 BRNE ISR_LOOP_DISPLAY_COL                          ; Exit and Reset R26 (index) when the last column is reached
								

TIMER1_COMP_ISR_CONT: 
		 LDI  R26,   0		
		 LDI  ZH ,   HIGH(LEDMATRIX_COL_index) 
		 LDI  ZL ,   LOW (LEDMATRIX_COL_index) 
		 ST   Z  ,   R26									; Save the reset column index (R26 = 0)
		 POP  R27 
		 POP  R26 
		 POP  R16 
		 RETI 



.EQU   OCR1A_value = 2500        ; Count 40000 cycles, -1 because it starts from 0
.EQU   TCCR1A_mode = 0b00000000   ; Select CTC mode
.EQU   TCCR1B_mode = 0b00001001   ; No Prescaler

 
INIT_TIMER1_CTC: 
		 PUSH R16 
		 LDI  R16,     HIGH(OCR1A_value)							; Set OCR1A of timer1 = 2500
		 STS  OCR1AH,  R16									
		 LDI  R16,     LOW (OCR1A_value)							
		 STS  OCR1AL,  R16									
		   
		 LDI  R16,     TCCR1A_mode									; Select CTC mode, No Prescale
		 STS  TCCR1A,  R16									
		 LDI  R16,     TCCR1B_mode			
		 STS  TCCR1B,  R16									; Start timer1

		 LDI  R16,     (1 << OCIE1A)						; Enable Output Comare Interrupt for OCR1A
		 STS  TIMSK1,  R16								    

		 POP  R16 
		 RET 
 

DELAY:   PUSH  R16 
AGAIN:	 SBIS  TIFR1,  OCF1A
		 RJMP  AGAIN

		 LDI   R16,   (1 << OCF1A)
		 OUT   TIFR1, R16
		 POP   R16
		 RET
