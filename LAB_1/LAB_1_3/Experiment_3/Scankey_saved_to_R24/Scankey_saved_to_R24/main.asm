;
; Scankey_saved_to_R24.asm
;
; Created: 10/21/2024 5:53:36 PM
; Author : Samet
;


; ATmega324PA keypad scan function 
; Scans a 4x4 keypad connected to PORTC
; Column 3 to 0 connect to Px3 -> Px0 
; Row    3 tp 0 connect to Px7 -> Px4 
; Returns the key value (0-15) or 0xFF if no key is pressed 


.ORG 0x0000   ; Reset Vector
		JMP   MAIN


.EQU    DDR_KP   = DDRB
.EQU    PORT_KP  = PORTB
.EQU    PIN_KP   = PINB

.EQU    LED_DDR_OUT  = DDRD
.EQU    LED_PORT_OUT = PORTD

.EQU	LCDPORT    = PORTA  ; SET SIGNAL PORT REG TO PORTA
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
KEYPAD_MSG:  .DB    "COUNTER: ", 0
NUMBER:      .DB    "0123456789"




MAIN:		LDI    R16,      0xFF             ; PORTB = Output (LED bar)
			OUT    LED_DDR_OUT,  R16

			LDI    R20,      0b00001111		  ; Set Upper 4 bits (Row) of PORTC as Input with pull-up, lower 4 bits as Output (Column)
			OUT    DDR_KP,   R20 

			CALL   LCD_INIT						; Initialize LCD pinouts
			CALL   DISPLAY_GROUP_MEMBER_NAME

			CLR    R2
			CALL   NUMBER_ON_LCD


LOOP:       RCALL  KEYPAD_SCAN				  ; Number display is store in R24
			RCALL  DELAY_10MS
			OUT    LED_PORT_OUT, R24
			MOV    R2,           R24
			CALL   NUMBER_ON_LCD				  ; Display number on LCD
			RJMP   LOOP



KEYPAD_SCAN: 
			LDI   R21,   0b11110111			 ; Initial Column Mask (OULL UO registors ???????)
			LDI   R22,   3					 ; R22 = Col, start check from Column 4, then 3, 2 , 1 (Because the Mask start with PC3 = 0) 

KEYPAD_SCAN_LOOP: 
			OUT   PORT_KP, R21				 ; Scan current col - Enable pull up resistor and Set Unread Column HIGH
			NOP								 ; Need to have 1us delay to stablize 

			SBIC  PIN_KP,  4				 ; Check Row 0 
			RJMP  KEYPAD_SCAN_CHECK_ROW2 
			LDI   R24,   0				 	 ; Row 0 is PRESSED
			RJMP  KEYPAD_SCAN_FOUND

KEYPAD_SCAN_CHECK_ROW2: 
			SBIC  PIN_KP,  5					 ; Check ROW 1 
			RJMP  KEYPAD_SCAN_CHECK_ROW3 
			LDI   R24,   1					 ; Row 1 IS PRESSED 
			RJMP  KEYPAD_SCAN_FOUND 

KEYPAD_SCAN_CHECK_ROW3: 
			SBIC  PIN_KP,  6					 ; Check Row 2 
			RJMP  KEYPAD_SCAN_CHECK_ROW4 
			LDI   R24,   2					 ; Row 2 IS PRESSED 
			RJMP  KEYPAD_SCAN_FOUND 

KEYPAD_SCAN_CHECK_ROW4: 
			SBIC  PIN_KP,  7					 ; CHECK ROW 3 
			RJMP  KEYPAD_SCAN_NEXT_COL 
			LDI   R24,   3					 ; ROW 3 IS PRESSED 
			RJMP  KEYPAD_SCAN_FOUND 
 
KEYPAD_SCAN_NEXT_COL: 
			CPI   R22,  0					 ; Check if the last COL (1) have been scanned 
			BREQ  KEYPAD_SCAN_NOT_FOUND 
 
			ROR   R21						 ; Shift Col mask to scan next row 
			DEC   R22						 ; Increase Col Index 
			RJMP  KEYPAD_SCAN_LOOP 
 
KEYPAD_SCAN_FOUND: 
											 ; KEY CODE = Row * 4 + Col 
			LSL   R24						 ; Shift Left 2 times to multiply it by 4 
			LSL   R24 
			ADD   R24,   R22				 ; Add row value to column value 
			RET 
 
KEYPAD_SCAN_NOT_FOUND: 
			LDI   R24,   0xFF				 ; No key pressed 
			RET 





DISPLAY_GROUP_MEMBER_NAME:
				LDI     R16, 0					 
				LDI     R17, 0
				CALL	LCD_MOVE_CURSOR 

				LDI     ZH, HIGH(GROUP)				; POINT TO THE INFORMATION THAT IS TO BE DISPLAYED
				LDI     ZL, LOW (GROUP)
				CALL    LCD_SEND_STRING
				LDI		R16, 1
				LDI		R17, 0
				CALL	LCD_MOVE_CURSOR 
				LDI     ZH, HIGH(KEYPAD_MSG)		; POINT TO THE INFORMATION THAT IS TO BE DISPLAYED
				LDI     ZL, LOW (KEYPAD_MSG)
				CALL    LCD_SEND_STRING
				RET




.DEF    Dividend_H  = R29
.DEF    Dividend_L  = R28

.DEF    Divisor_H   = R27
.DEF    Divisor_L   = R26

.DEF    Quotient_H  = R25
.DEF    Remainder_H = R24

.DEF    Quotient_L  = R23
.DEF    Remainder_L = R22


; Display number of R2 (8-bit, 0 to 255)
NUMBER_ON_LCD:   PUSH  R17
				 PUSH  R2

				 LDI   Dividend_H,  0
				 MOV   Dividend_L,  R2		
				 LDI   Divisor_H,   0
				 LDI   Divisor_L,   100
				 RCALL DIVISION
				 MOV   R5,        Quotient_L		; 3rd digit

				 LDI   Dividend_H,  0
				 MOV   Dividend_L,  Remainder_L	
				 LDI   Divisor_H,   0
				 LDI   Divisor_L,   10
				 RCALL DIVISION
				 MOV   R4,        Quotient_L		; 2nd digit
				 MOV   R3,        Remainder_L		; 1st digit

				 LDI   R16, 0xCB				; Set cursor to Row = , Col =
				 CALL  LCD_SEND_COMMAND
				 MOV   R2, R5					
				 CALL  LCD_SEND_CHAR			; Diplay 1 digit store in R2


				 LDI   R16, 0xCC				; Set cursor to Row = , Col =
				 CALL  LCD_SEND_COMMAND
				 MOV   R2, R4
				 CALL  LCD_SEND_CHAR			; Diplay 1 digit store in R2


				 LDI   R16, 0xCD				; Set cursor to Row = , Col =
				 CALL  LCD_SEND_COMMAND
				 MOV   R2, R3
				 CALL  LCD_SEND_CHAR			; Diplay 1 digit store in R2

				 LDI   R16, 0x0C				; Turn of cursor
				 CALL  LCD_SEND_COMMAND
				 POP   R2
				 POP   R17
				 RET


DIVISION:      PUSH  Dividend_H
			   PUSH  Dividend_L
			   PUSH  Divisor_H
			   PUSH  Divisor_L
			   PUSH  R16

			   CLR   Quotient_H     ; To count "quotient"
			   CLR   Quotient_L
			   CLR   R16

DIVISION_LOOP: 			   
			   MOV   Remainder_H,  Dividend_H
			   MOV   Remainder_L,  Dividend_L		  ; Save Remainder (Useful for the last iteration)

			   SUB   Dividend_L,   Divisor_L          ; Y - X 
			   SBC   Dividend_H,   Divisor_H     
			   BRMI  DIVISION_STOP					 ; If negative, exit
			   INC   Quotient_L   
               ADC   Quotient_H,   R16				 ; + carry from INC R18
			   RJMP  DIVISION_LOOP


DIVISION_STOP: POP   R16
			   POP   Divisor_L
			   POP   Divisor_H
			   POP   Dividend_L
			   POP   Dividend_H
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
