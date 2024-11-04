;
; Switch_times_9_on_7segment.asm
;
; Created: 10/26/2024 7:56:21 PM
; Author : Samet
;


;  J34 CONNECT TO PORTD 
;  NLE0 CONNECT TO PB4 
;  NLE1 CONNECT TO PB5 
;  OUTPUT: NONE 


.ORG 0x00
		JMP   MAIN


; Lookup table for 7-segment codes
BCD_TABLE:   .DB  0xC0, 0xF9,0xA4,0xB0,0x99,0x92,0x82,0xF8,0x80,0x90,0x88,0x8 

; Lookup table for LED control 
COMMON_CATHODE_TABLE:  .DB  0b00001110, 0b00001101, 0b00001011, 0b00000111 


.EQU LED7SEG_PORT = PORTB			; Two 74HC573 ICs (Data and Common Anode) use the same PORT
.EQU LED7SEG_DDR  =  DDRB 
.EQU nLEx_PORT    = PORTD			; Seperate PORT for controling LATCH pin
.EQU nLEx_DDR     =  DDRD 
.EQU nLE0_PIN     = 0 
.EQU nLE1_PIN     = 1 

.EQU DIP_SWITCH_PORT  = PORTA
.EQU DIP_SWITCH_DDR   = DDRA
.EQU DIP_SWITCH_PIN   = PINA



MAIN:    RCALL  LED_7SEG_PORT_INIT
	     LDI    R24,  0x00                 ; Set Input PORT for DIP switch
 		 OUT    DIP_SWITCH_DDR,   R24


		 LDI    R24,  0xFF				   ; Enable pull-up resistors for DIP swtich
		 OUT    DIP_SWITCH_PORT,  R24     
		 

READ:	 LDI    R20,  0x09				   ; For multiplication by 9 
	     IN     R21,  DIP_SWITCH_PIN    ; Input from 0 to 15
		 COM    R21
		 
         MUL    R21,  R20               ; Result is store in R1 and R0, Result = [0, 2295]

		 LDI    R24,   3                ; The thousands-digit
		 MOV    YH,    R1               ; Perform Y/X = Result / 1000 
		 MOV    YL,    R0 
		 LDI    XH,    0x03
		 LDI    XL,    0xE8
		 CALL   DIVISION                ; R17:R16 = Quotient
		                                ; R19:R18 = Remainder


		 MOV    R25,   R16				; Display quotient (R16 surely < 10)
		 CALL   DISPLAY_7SEG
     	 CALL   DELAY_4ms 

		 LDI    R24,   2	            ; Next: the hundreds-digit
		 MOV    YH,    R19              ; Perform Y/X = Remainder / 100 
		 MOV    YL,    R18 
		 LDI    XH,    0x00
		 LDI    XL,    0x64



		 CALL   DIVISION                ; R17:R16 = Quotient
		                                ; R19:R18 = Remainder
		 MOV    R25,   R16				; Display quotient (R16 surely < 10)

		 CALL   DISPLAY_7SEG
     	 CALL   DELAY_4ms 


		 LDI    R24,   1	            ; Next: the tenth-digit
		 MOV    YH,    R19              ; Perform Y/X = Result / 10 
		 MOV    YL,    R18 
		 LDI    XH,    0x00
		 LDI    XL,    0x0A
		 CALL   DIVISION                ; R17:R16 = Quotient
		                                ; R19:R18 = Remainder
		 MOV    R25,   R16				; Display quotient (R16 surely < 10)

		 CALL   DISPLAY_7SEG
     	 CALL   DELAY_4ms 

		 LDI    R24,   0	            ; Next: the last digit
		 MOV    R25,   R18              ; Display remainder
		 CALL   DISPLAY_7SEG
		 CALL   DELAY_4ms 

		 JMP    READ

; Y divide by X,
; Quotient  = R17:R16
; Remainder = R19:R18
DIVISION:      PUSH  YH
			   PUSH  YL
			   PUSH  XH
			   PUSH  XL
			   PUSH  R10

			   CLR   R10     ; R10 = 0
			   CLR   R17     ; To count "quotient"
			   CLR   R16

DIVISION_LOOP: 			   
			   MOV   R18, YL
			   MOV   R19, YH 		  ; Save Remainder (Useful for the last iteration)

			   SUB   YL,  XL          ; Y - X 
			   SBC   YH,  XH     
			   BRMI  DIVISION_STOP    ; If negative, exit
			   INC   R16
               ADC   R17, R10         ; R17 + carry from INC R18
			   RJMP  DIVISION_LOOP


DIVISION_STOP: POP   R10
			   POP   XL
			   POP   XH
			   POP   YL
			   POP   YH
			   RET






LED_7SEG_PORT_INIT: 
		PUSH   R20						; Save R20 before using it 
		LDI    R20,   0xFF				; Set LED7SEG port as output 
		OUT    LED7SEG_DDR, R20 

		LDI    R20,   nLEx_DDR			; Set as output for signal each common Anode of 7SEG LEDs
		ORI    R20,   (1 << nLE0_PIN) | (1 << nLE1_PIN) 		
		OUT    nLEx_DDR,  R20 
		POP    R20 
		RET 




; INPUT: R25 = Num
;        R24 = Index (from 0 -> 3, as for LED_0 to LED_3) 

DISPLAY_7SEG: 
		PUSH  R16							; Save R16 and R20 before using it
		PUSH  R20 
		                           
        CLR   R16
		LDI   ZH,  HIGH(BCD_TABLE << 1)		; Z = base address of the look-up table 
		LDI   ZL,  LOW (BCD_TABLE << 1)
		ADD   ZL,  R25						; Add R25 to Z (16-bit)
		ADC   ZH,  R16						; Add carry to ZH if needed
 
	    LPM   R20, Z						; Load the code to the 7SEG pins
		OUT   LED7SEG_PORT,  R20 
		SBI   nLEx_PORT,  nLE0_PIN			; Pulse the latch to update 
		NOP 
		CBI   nLEx_PORT,  nLE0_PIN
		  


		LDI   ZH,  HIGH(COMMON_CATHODE_TABLE << 1)	; Z = base address of the look-up control table  
		LDI   ZL,  LOW (COMMON_CATHODE_TABLE << 1) 
		ADD   ZL,  R24								; Add R25 to Z (16-bit)
		ADC   ZH,  R16								; Add carry to ZH if needed

		LPM   R20, Z								; Load the code to the 7SEG pins
		OUT   LED7SEG_PORT,  R20 
		SBI   nLEx_PORT,  nLE1_PIN					; Pulse the latch to update 
		NOP 
		CBI   nLEx_PORT,  nLE1_PIN 

		POP   R20									; Restore the temporary register 
		POP   R16
		RET
		 
		 


.EQU   TCCR0B_mode = 0b00000100
.EQU   TCNT_init   = 100   ; 0 to 255 
DELAY_4ms: 
				 PUSH   R16
				 LDI    R16,    TCNT_init	     ; Set initial value for Timer (TNCT)
			     OUT    TCNT0,  R16            

				 LDI    R16,    0b00000000	     ; Choose Normal mode
				 OUT    TCCR0A, R16         
				 LDI    R16,    TCCR0B_mode	     ; Choose Prescale and start Timer
				 OUT    TCCR0B, R16            

AGAIN:           SBIS   TIFR0,  TOV0             ; Check for Overflow
                 RJMP   AGAIN              
				                               
				 LDI    R16,    0		         ; Stop the TImer
				 OUT    TCCR0B, R16           
				 LDI    R16,    (1 << TOV0)      ; Clear TImer overflow flag
				 OUT    TIFR0,  R16      
				 
				 POP    R16      
				 RET                       
