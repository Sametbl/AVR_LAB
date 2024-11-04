
; Step 1: Initialize LCD
;    - Choose mode: 4-bit   or   8-bit							 Command = 
;    - Choose dot matrix size: usually 5x7 for each character.	 Command = 0x38
;    - Turn on Display and Cursor Blinking:						 Command = 0x0E
;    - Clear Diplsay											 Command = 0x01
;    - Set Cursor to first row and line							 COmmand = 0x80 




;.INCLUDE "M324PDEF.INC"  ; INCLUDE ATMEGA324PA DEFINITIONS
.DSEG   ; Data Segment
COURSE_NAME:		.DB         "EX VXL-AVR",  0
COURSE_TIME:		.DB         "GROUP: 01",   0


.CSEG   ; Code segment
.ORG 0x0000 ; INTERRUPT VECTOR TABLE
			JMP     RESET_HANDLER		 ; RESET
.EQU	LCDPORT    = PORTA			     ; Set signal port reg to porta
.EQU	LCDPORTDIR = DDRA				 ; Set signal port dir reg to porta
.EQU	LCDPORTPIN = PINA				 ; Set clear signal port pin reg to porta
.EQU	LCD_RS     = PINA0
.EQU	LCD_RW     = PINA1
.EQU	LCD_EN	   = PINA2
.EQU	LCD_D7	   = PINA7
.EQU	LCD_D6	   = PINA6
.EQU	LCD_D5	   = PINA5
.EQU	LCD_D4	   = PINA4


;******************************* PROGRAM ID *******************************
.ORG    INT_VECTORS_SIZE

RESET_HANDLER:
			CALL	LCD_INIT

			LDI		R16,   0                     ; R16 = 0 ==> Cursor = first row
			LDI		R17,   0                     ; R17 = 0, To set RW = 0 and RS = 0 for writing Command		
			CALL	LCD_MOVE_CURSOR 
			LDI     ZH,    HIGH(COURSE_NAME)     ; Point to the information that is to be displayed
			LDI     ZL,    LOW(COURSE_NAME)
			CALL    LCD_SEND_STRING

			LDI		R16,   1                     ; R16 = 1 ==> Cursor = second row
			LDI		R17,   0                     ; R17 = 0, To set RW = 0 and RS = 0 for writing Command
			CALL	LCD_MOVE_CURSOR 
			LDI     ZH,    HIGH(COURSE_TIME)     ; POINT TO THE INFORMATION THAT IS TO BE DISPLAYED
			LDI     ZL,    LOW(COURSE_TIME)
			CALL    LCD_SEND_STRING

			LDI     R16,   0X0C                  ; FUNCTION: Display ON, Cursor OFF
			CALL    LCD_SEND_COMMAND
START:   	RJMP    START						 ; Basically HALT the program
	

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



.DEF	LCDDATA = R16
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



DELAY_10ms:                 
		LDI   R22, 30		; These values are calculated similarly in experiment 2           
L2:     LDI   R21, 172     
L1:	    LDI   R20, 5     
L0:		DEC   R20    
		BRNE  L0      
		                 
		DEC   R21    
		BRNE  L1         
		                 
		DEC   R22     
		BRNE  L2  		
		                 
		RET              
