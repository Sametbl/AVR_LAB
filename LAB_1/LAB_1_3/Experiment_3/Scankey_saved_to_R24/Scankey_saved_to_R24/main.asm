;
; Scankey_saved_to_R24.asm
;
; Created: 10/21/2024 5:53:36 PM
; Author : Samet
;


; ATmega324PA keypad scan function 
; Scans a 4x4 keypad connected to PORTC
; Column 3 to 0 connect to PA3 -> PA0 
; Row    3 tp 0 connect to PA7 -> PA4 
; Returns the key value (0-15) or 0xFF if no key is pressed 

START:		LDI    R16,   0xFF                ; PORTB = Output (LED bar)
			OUT    DDRB,  R16

			LDI    R20,   0b00001111		  ; Set Upper 4 bits (Row) of PORTC as Input with pull-up, lower 4 bits as Output (Column)
			OUT    DDRC,  R20 

LOOP:       RCALL  KEYPAD_SCAN
			OUT    PORTB, R24
			RJMP   LOOP

HALT:		RJMP   HALT

KEYPAD_SCAN: 
			LDI   R21,   0b00000111			 ; Initial Column Mask (OULL UO registors ???????)
			LDI   R22,   4					 ; R22 = Col, start check from Column 4, then 3, 2 , 1 (Because the Mask start with PC3 = 0) 

KEYPAD_SCAN_LOOP: 
			OUT   PORTC, R21				 ; Scan current col - Enable pull up resistor and Set Unread Column HIGH
			NOP								 ; Need to have 1us delay to stablize 

			SBIC  PINC,  4					 ; Check Row 0 
			RJMP  KEYPAD_SCAN_CHECK_ROW2 
			LDI   R24,   0				 	 ; Row 0 is PRESSED
			RJMP  KEYPAD_SCAN_FOUND

KEYPAD_SCAN_CHECK_ROW2: 
			SBIC  PINC,  5					 ; Check ROW 1 
			RJMP  KEYPAD_SCAN_CHECK_ROW3 
			LDI   R24,   1					 ; Row 1 IS PRESSED 
			RJMP  KEYPAD_SCAN_FOUND 

KEYPAD_SCAN_CHECK_ROW3: 
			SBIC  PINC,  6					 ; Check Row 2 
			RJMP  KEYPAD_SCAN_CHECK_ROW4 
			LDI   R24,   2					 ; Row 2 IS PRESSED 
			RJMP  KEYPAD_SCAN_FOUND 

KEYPAD_SCAN_CHECK_ROW4: 
			SBIC  PINC,  7					 ; CHECK ROW 3 
			RJMP  KEYPAD_SCAN_NEXT_COL 
			LDI   R24,   3					 ; ROW 3 IS PRESSED 
			RJMP  KEYPAD_SCAN_FOUND 
 
KEYPAD_SCAN_NEXT_COL: 
			CPI   R22,  1					 ; Check if the last COL (1) have been scanned 
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