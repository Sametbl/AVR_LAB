.include "m324Pdef.inc"  ; Include Atmega324P definitions
.org 0x0000 ; interrupt vector table
rjmp reset_handler ; reset
.equ	LCDPORT = PORTA  ; Set signal port reg to PORTA
.equ	LCDPORTDIR = DDRA   ; Set signal port dir reg to PORTA
.equ	LCDPORTPIN = PINA	; Set clear signal port pin reg to PORTA
.equ	LCD_RS	= PINA0
.equ	LCD_RW	= PINA1
.equ	LCD_EN	= PINA2
.equ	LCD_D7	= PINA7
.equ	LCD_D6	= PINA6
.equ	LCD_D5	= PINA5
.equ	LCD_D4	= PINA4
;******************************* Program ID *********************************
.org    INT_VECTORS_SIZE
course_name:
.db         "EX VXL-AVR",0
course_time:
.db         "LT.VY & TT.TOAN",0
reset_handler:
	CALL	LCD_Init
; display the first line of information
    LDI     ZH, high(course_name)        ; point to the information that is to be displayed
    LDI     ZL, low(course_name)
    CALL    LCD_Send_String
	LDI		r16,1
	LDI		r17,0
	CALL	LCD_Move_Cursor 
	LDI    ZH, high(course_time)        ; point to the information that is to be displayed
    LDI      ZL, low(course_time)
    CALL    LCD_Send_String
	LDI    r16,0x0C
	CALL    LCD_Send_Command
start:
    RJMP start

	

LCD_Move_Cursor:

    CPI	    r16,0	;check if first row
	BRNE	LCD_Move_Cursor_Second
	ANDI	r17, 0x0F
	ORI  	r17,0x80    
	MOV		r16,r17
    ; Send command to LCD
    CALL LCD_Send_Command
	RET
LCD_Move_Cursor_Second:
	 CPI	r16,1	;check if second row
	 BRNE	LCD_Move_Cursor_Exit	;else exit 
	 ANDI	r17, 0x0F
	 ORI	r17,0xC0   
	 MOV	r16,r17 
    ; Send command to LCD
    CALL LCD_Send_Command
LCD_Move_Cursor_Exit:
    ; Return from function
    RET

.def	LCDData = r16
LCD_Send_String:
    PUSH    ZH                              ; preserve pointer registers
    PUSH    ZL
	PUSH	LCDData

; fix up the pointers for use with the 'lpm' instruction
    LSL     ZL                              ; shift the pointer one bit left for the lpm instruction
    ROL     ZH
; write the string of characters
LCD_Send_String_01:
    LPM     LCDData, Z+                        ; get a character
    CPI     LCDData,  0                        ; check for end of string
    BREQ    LCD_Send_String_02          ; done

; arrive here if this is a valid character
    CALL    LCD_Send_Data          ; display the character
    RJMP    LCD_Send_String_01          ; not done, send another character

; arrive here when all characters in the message have been sent to the LCD module
LCD_Send_String_02:
	POP		LCDData
    POP     ZL                              ; restore pointer registers
    POP     ZH
    RET



	LCD_Init:
    ; Set up data direction register for Port A
    LDI r16, 0b11110111  ; set PA7-PA4 as outputs, PA2-PA0 as output
    OUT LCDPORTDIR, r16
    ; Wait for LCD to power up
    CALL	DELAY_10MS
	CALL	DELAY_10MS
    
    ; Send initialization sequence
	LDI r16, 0x02    ; Function Set: 4-bit interface
    CALL LCD_Send_Command
    LDI r16, 0x28    ; Function Set: enable 5x7 mode for chars 
    CALL LCD_Send_Command
	LDI r16, 0x0E    ; Display Control: Display OFF, Cursor ON


	CALL LCD_Send_Command
    LDI r16, 0x01    ; Clear Display
    CALL LCD_Send_Command
    LDI r16, 0x80    ; Clear Display
    CALL LCD_Send_Command
    RET

	LCD_wait_busy:
	PUSH	r16
	LDI     r16, 0b00000111  ; set PA7-PA4 as input, PA2-PA0 as output
    OUT LCDPORTDIR, r16
	LDI	r16,0b11110010	; set RS=0, RW=1 for read the busy flag
	OUT	LCDPORT, r16
	NOP
 LCD_wait_busy_loop:
      SBI LCDPORT, LCD_EN
      NOP
	  NOP
	  IN r16, LCDPORTPIN
	  CBI LCDPORT, LCD_EN
	  NOP
      SBI LCDPORT, LCD_EN
      NOP
	  NOP
      CBI LCDPORT, LCD_EN
	  NOP
	  ANDI	r16,0x80
	  CPI   r16,0x80
	  BREQ	LCD_wait_busy_loop
	  LDI r16, 0b11110111  ; set PA7-PA4 as output, PA2-PA0 as output
      OUT LCDPORTDIR, r16
	  LDI	r16,0b00000000	; set RS=0, RW=1 for read the busy flag
	  OUT	LCDPORT, r16	
	  POP	r16
	  RET

LCD_Send_Data:
	PUSH	r17
	CALL	LCD_wait_busy	;check if LCD is busy
	MOV		r17,r16		;save the command				
    ; Set RS high to select data register
    ; Set RW low to write to LCD
	ANDI	r17,0xF0
	ORI	    r17,0x01
    ; Send data to LCD
    OUT LCDPORT, r17   
	NOP
    ; Pulse enable pin
    SBI LCDPORT, LCD_EN
    NOP
    CBI LCDPORT, LCD_EN
    ; Delay for command execution
	;send the lower nibble
	NOP
    SWAP	r16
	ANDI	r16,0xF0
	; Set RS high to select data register
    ; Set RW low to write to LCD
	ANDI	r16,0xF0
	ORI 	r16,0x01
    ; Send command to LCD
    OUT    LCDPORT, r16
	NOP
    ; Pulse enable pin
    SBI LCDPORT, LCD_EN
    NOP
    CBI LCDPORT, LCD_EN
	POP	r17
    RET

	LCD_Send_Command:
	PUSH	r17
	CALL	LCD_wait_busy	; check if LCD is busy 
	MOV  	r17,r16		;save the command				
    ; Set RS low to select command register
    ; Set RW low to write to LCD
	ANDI	r17,0xF0
    ; Send command to LCD
    OUT    LCDPORT, r17  
    NOP
	NOP
    ; Pulse enable pin
    SBI LCDPORT, LCD_EN
    NOP
    NOP
    CBI LCDPORT, LCD_EN
    SWAP	r16
	ANDI	r16,0xF0
    ; Send command to LCD
    OUT LCDPORT, r16   
    ; Pulse enable pin
    SBI LCDPORT, LCD_EN
	NOP
	NOP
	CBI	LCDPORT, LCD_EN
	POP	r17
    RET

DELAY_10MS:
    LDI R20,80    ;1MC
LP2:LDI R22,250  ;1MC
LP:
	NOP          ;1MC
	DEC R22      ;1MC
	BRNE LP      ;1/2MC
	DEC R20      ;1MC
	BRNE LP2     ;1/2MC
     RET