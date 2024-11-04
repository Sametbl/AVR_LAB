;
; Debounced_press_count.asm
;
; Created: 10/21/2024 3:27:24 PM
; Author : Samet
;



.ORG 00
.EQU    DDR_IN   = DDRC
.EQU    PORT_IN  = PORTC
.EQU    PIN_IN   = PINC

.EQU    LED_DDR_OUT  = DDRD
.EQU    LED_PORT_OUT = PORTD

.EQU	LCDPORT = PORTA  ; SET SIGNAL PORT REG TO PORTA
.EQU	LCDPORTDIR = DDRA   ; SET SIGNAL PORT DIR REG TO PORTA
.EQU	LCDPORTPIN = PINA	; SET CLEAR SIGNAL PORT PIN REG TO PORTA
.EQU	LCD_RS	= PINA0
.EQU	LCD_RW	= PINA1
.EQU	LCD_EN	= PINA2
.EQU	LCD_D7	= PINA7
.EQU	LCD_D6	= PINA6
.EQU	LCD_D5	= PINA5
.EQU	LCD_D4	= PINA4

.DEF	LCDDATA = R16


GROUP:       .DB    "LT.VY & TT.TOAN", 0
COUNTER_MSG: .DB    "COUNTER: ", 0
NUMBER:      .DB    "0123456789"


START:			CBI     DDR_IN,  0				; Config Button as Input
				SBI     PORT_IN, 0				; Enable pull-up resistor

				LDI     R16,     0xFF			; Config LED_BAR as Output
				OUT     LED_DDR_OUT,  R16

				LDI     R17,     0x00			; Clear R17 for Counter
				OUT     LED_PORT_OUT, R16		; Also Clear LED_BAR output

			    CALL    LCD_INIT				; Initialize LCD pinouts

DISPLAY_GROUP_MEMBER_NAME:
				LDI     R16, 0					; 
				LDI     R17, 0
				CALL	LCD_MOVE_CURSOR 

				LDI     ZH, HIGH(GROUP)        ; POINT TO THE INFORMATION THAT IS TO BE DISPLAYED
				LDI     ZL, LOW(GROUP)
				CALL    LCD_SEND_STRING
				LDI		R16,1
				LDI		R17,0
				CALL	LCD_MOVE_CURSOR 
				LDI     ZH, HIGH(COUNTER_MSG)        ; POINT TO THE INFORMATION THAT IS TO BE DISPLAYED
				LDI     ZL, LOW(COUNTER_MSG)
				CALL    LCD_SEND_STRING

				CLR R2
				CALL NUMBER_ON_LCD

				LDI    R17,      0x00		   ; Clear R17 for Counter


DEBOUNCE:    
CHECK_PRESS:	SBIC   PIN_IN,  0			; When not press, PC0 = 1
				RJMP   CHECK_PRESS  

				RCALL  DELAY_10ms
				SBIC   PIN_IN,  0			; Second check
				RJMP   CHECK_PRESS  

				RCALL  DELAY_10ms
				SBIC   PIN_IN,  0			; Third check
				RJMP   CHECK_PRESS  

				RJMP   PRESSED				; It is legit after 4 checks


CHECK_RELEASE:  SBIS   PIN_IN,  0			; When holding/pressing the button, PC0 = 0
				RJMP   CHECK_RELEASE
				RJMP   CHECK_PRESS			; When released, check for the next press (should be delayed before RJMP)
   

PRESSED:		INC    R17					; Increment counter by 1
				OUT    LED_PORT_OUT,   R17	; Display new counter on LED bar
				MOV    R2, R17
				CALL   NUMBER_ON_LCD
				CALL   DELAY_10ms
				RJMP   CHECK_RELEASE		; Check when the button is release





.DEF    Dividend  = R27
.DEF    Divisor   = R26
.DEF    Quotient  = R25
.DEF    Remainder = R24


; Display number of R2 (8-bit, 0 to 155
NUMBER_ON_LCD:   PUSH  R17
				 PUSH  R2

				 MOV   Dividend,  R2			
				 LDI   Divisor,   100
				 RCALL DIVISION
				 MOV   R5,        Quotient		; 3rd digit

				 MOV   Dividend,  Remainder
				 LDI   Divisor,   10
				 RCALL DIVISION
				 MOV   R4,        Quotient		; 2nd digit
				 MOV   R3,        Remainder		; 1st digit

				 LDI   R16, 0xCB				; Set cursor to Row = , Col =
				 CALL  LCD_SEND_COMMAND
				 MOV   R2, R5					
				 CALL  LCD_SEND_CHAR		; Diplay 1 digit store in R2


				 LDI   R16, 0xCC				; Set cursor to Row = , Col =
				 CALL  LCD_SEND_COMMAND
				 MOV   R2, R4
				 CALL  LCD_SEND_CHAR		; Diplay 1 digit store in R2


				 LDI   R16, 0xCD				; Set cursor to Row = , Col =
				 CALL  LCD_SEND_COMMAND
				 MOV   R2, R3
				 CALL  LCD_SEND_CHAR		; Diplay 1 digit store in R2

				 LDI   R16, 0x0C				; Turn of cursor
				 CALL  LCD_SEND_COMMAND
				 POP   R2
				 POP   R17
				 RET



DIVISION:      PUSH  Dividend		; R27 = Dividend
			   PUSH  Divisor		; R26 = Divisor
			   CLR   Quotient		; To count "quotient"
			   CLR   Remainder

DIVISION_LOOP: 			   
			   MOV   Remainder, Dividend	; Save the last Remainder (Useful for the last iteration)
			   SUB   Dividend,  Divisor		; Y - X 
			   BRMI  DIVISION_STOP			; If negative, exit
			   INC   Quotient
			   RJMP  DIVISION_LOOP

DIVISION_STOP: POP   Divisor
			   POP   Dividend
			   RET


LCD_MOVE_CURSOR:

			CPI		R16,   0				     ; Check if first row
			BRNE	LCD_MOVE_CURSOR_SECOND
			ANDI	R17,   0x0F                  ; Set the State of RS and RW pins 
			ORI		R17,   0x80                  ; R17 = DDRAM location of beginning of first Row
			MOV		R16,   R17                   ; Save that location to R16
			CALL    LCD_SEND_COMMAND		     ; Send command to LCD to move cursor 
			RET

LCD_MOVE_CURSOR_SECOND:
			CPI		R16,   1					 ; Check if second row
			BRNE	LCD_MOVE_CURSOR_EXIT		 ; ELSE EXIT 
			ANDI	R17,   0x0F					 ; Set the State of RS and RW pins 
			ORI		R17,   0xC0					 ; R17 = DDRAM location of beginning of second Row
			MOV		R16,   R17					 ; Save that location to R16
			CALL    LCD_SEND_COMMAND			 ; Send command to LCD to move cursor 
LCD_MOVE_CURSOR_EXIT:
		    RET		





LCD_SEND_CHAR:
    PUSH  ZH							; PRESERVE POINTER REGISTERS
    PUSH  ZL
	PUSH  LCDDATA
	PUSH  R2
	
 	LDI   ZH, HIGH(NUMBER << 1)			; Point to the information that is to be displayed
	LDI   ZL, LOW (NUMBER << 1) 
    ADD   ZL, R2
	CLR   R2
	ADC   ZH, R2
    LPM   LCDDATA,  Z					; GET A CHARACTER

    CALL  LCD_SEND_DATA					; DISPLAY THE CHARACTER

    POP   R2
	POP	  LCDDATA
    POP   ZL							; RESTORE POINTER REGISTERS
    POP   ZH
    RET






LCD_SEND_STRING:
			PUSH    ZH                           ; Preserve pointer registers
			PUSH    ZL
			PUSH	LCDDATA
												
			LSL     ZL                           ; LSL + ROL = Shift left for 16-bit Z reigster for the LPM instruction
			ROL     ZH

LCD_SEND_STRING_LOOP:							 ; Write the string of characters to DDRAM 
			LPM     LCDDATA,   Z+                ; Get a character
			CPI     LCDDATA,   0                 ; Check for end of string
			BREQ    LCD_SEND_STRING_DONE         ; If Null character ==> DONE
			CALL    LCD_SEND_DATA                ; Display the character
			RJMP    LCD_SEND_STRING_LOOP         ; Not DONE, send another character

LCD_SEND_STRING_DONE:
			POP		LCDDATA						 ; RESTORE POINTER REGISTERS
			POP     ZL                        
			POP     ZH
			RET



LCD_INIT:
			LDI    R16,   0b11110111			; Set PA7 -> PA4 as Output, PA2 -> PA0 as output
			OUT    LCDPORTDIR,  R16
									
			CALL   DELAY_10ms					; WAIT FOR LCD TO POWER UP
			CALL   DELAY_10ms
											
			LDI    R16,   0x02					; FUNCTION SET: 4-bit, 2 lines, 5x7 dot interface
			CALL   LCD_SEND_COMMAND

			LDI    R16,   0x28					; FUNCTION SET: enable 5x7 mode for chars 
			CALL   LCD_SEND_COMMAND
			LDI    R16,   0x0E					; DISPLAY CONTROL: DISPLAY ON, CURSOR ON
			CALL   LCD_SEND_COMMAND
			LDI    R16,   0x01					; Clear display and DDRAM contents
			CALL   LCD_SEND_COMMAND
			LDI    R16,   0x80					; Return Cursor to the beginning
			CALL   LCD_SEND_COMMAND
			RET



LCD_WAIT_BUSY:
			PUSH   R16
			LDI    R16,   0b00000111			; Set PA7-PA4 as Input, PA2-PA0 as Output
			OUT    LCDPORTDIR,  R16
			LDI	   R16,   0b11110010			; Set RS = 0, RW = 1 for read the busy flag
			OUT	   LCDPORT,     R16
			NOP

LCD_WAIT_BUSY_LOOP:
			SBI    LCDPORT,  LCD_EN				; Pulse LCD_EN and read the flag
			NOP
			NOP
			IN     R16,     LCDPORTPIN
			CBI    LCDPORT,  LCD_EN
			NOP

			SBI    LCDPORT,  LCD_EN             ; Pulse LCD_EN again
			NOP
			NOP
			CBI    LCDPORT,  LCD_EN
			NOP

			ANDI   R16,   0x80                  ; Extract PA7 = busy flag
			CPI	   R16,   0x80                  ; Check if busy flag is set 
			BREQ   LCD_WAIT_BUSY_LOOP

			LDI    R16,   0b11110111			; Set PA7-PA4 as Output, PA2-PA0 as Output
			OUT    LCDPORTDIR, R16
			LDI	   R16,   0b00000000			; Set RS = 0, RW = 1 for read the busy flag
			OUT	   LCDPORT,    R16	
			POP	   R16
			RET

LCD_SEND_DATA:
			PUSH   R17
			CALL   LCD_WAIT_BUSY				; Check if lcd is busy
			MOV	   R17,   R16					; Save the command				
														
			ANDI   R17,   0xF0					; Extact the Upper nibble of Command
			ORI	   R17,   0x01					; Also Set RS = 1 and RW = 0 to write to lcd
		
			OUT    LCDPORT,  R17				; Send data to LCD
			NOP
			
			SBI    LCDPORT,  LCD_EN		    	; Pulse ENABLE pin
			NOP
			CBI    LCDPORT,  LCD_EN
			NOP									; DELAY FOR COMMAND EXECUTION

			SWAP   R16							; Swap Higher Nibble to Lower Nibble of Commmand
			ANDI   R16,  0xF0                   ; And extract the Lower Nibble of the Command similarly
			ORI	   R16,  0x01					; Also Set RS = 1 and RW = 0 to write to lcd
		

			OUT    LCDPORT,  R16				; Send command to LCD

			NOP									; Pulse ENABLE pin
			SBI    LCDPORT,  LCD_EN
			NOP
			CBI    LCDPORT,  LCD_EN
			POP    R17
			RET


LCD_SEND_COMMAND:
			PUSH   R17
			CALL   LCD_WAIT_BUSY				; Check if LCD is busy 
			MOV    R17,  R16					; Save the command	
		
			ANDI   R17,  0xF0					; Extact the Upper nibble of Command
												; Also Set RS = 1 and RW = 0 to write to lcd
			
			OUT    LCDPORT,  R17				; Send command to LCD
			NOP
			NOP
		
			SBI    LCDPORT,  LCD_EN				; Pulse ENABLE pin
			NOP
			NOP
			CBI    LCDPORT,  LCD_EN

			SWAP   R16							; Swap Higher Nibble to Lower Nibble of Commmand
			ANDI   R16,  0xF0                   ; And extract the Lower Nibble of the Command similarly
			OUT    LCDPORT,  R16				; Send command to LCD

			SBI    LCDPORT,  LCD_EN			    ; Pulse ENABLE pin
			NOP
			NOP
			CBI	   LCDPORT,  LCD_EN
			POP	   R17

			RET



DELAY_10MS:                  
		LDI   R22, 30                  
L2:     LDI   R21, 172     
L1:	    LDI   R20, 5   
L0:		DEC   R20        
		BRNE  L0      
		                
		DEC   R21    
		BRNE  L1        
		               
		DEC   R22    
		BRNE  L2  	
		               
		RET            
