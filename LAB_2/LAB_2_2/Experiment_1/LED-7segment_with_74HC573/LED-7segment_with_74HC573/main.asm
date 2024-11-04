;
; LED-7segment_with_74HC573.asm
;
; Created: 10/26/2024 5:47:02 PM
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
COMMON_CATHOD_TABLE:  .DB  0b00001110, 0b00001101, 0b00001011, 0b00000111 


.EQU LED7SEG_PORT = PORTB			; Two 74HC573 ICs (Data and Common Anode) use the same PORT
.EQU LED7SEG_DDR  =  DDRB 
.EQU nLEx_PORT    = PORTD			; Seperate PORT for controling LATCH pin
.EQU nLEx_DDR     =  DDRD 
.EQU nLE0_PIN     = 0 
.EQU nLE1_PIN     = 1 
.DEF LED7_INDEX   = R5

 


MAIN:    RCALL  LED_7SEG_PORT_INIT
		; CLR    R26          ; R26 = Index for LED_0 -> LED_3Start
		 LDI    R26, 3
		 LDI    R27, 0       ; R27 = Number needed to be display (0 to 9)

LOOP:	 CALL   DISPLAY_7SEG
     	 CALL   DELAY_4ms
	;	 INC    R26
		 DEC    R26
		 INC    R27          ; Display 1 to LED_0, then LED_1 = 2, then LED_2 = 3, LED_3 = 4 

		 ANDI   R26, 0x0F
	 ;CPI    R26, 4       ; Return to LED_0, when finished displaying LED_3
		 CPI    R26, 0x0F
		 BRNE   LOOP

		 LDI    R27, 0       ; Initialization for the next scanning cycle
	;	 CLR    R26
		 LDI    R26, 3

		 JMP    LOOP



LED_7SEG_PORT_INIT: 
		PUSH   R20						; Save R20 before using it 
		LDI    R20,   0xFF				; Set LED7SEG port as output 
		OUT    LED7SEG_DDR, R20 

		LDI    R20,   nLEx_DDR			; Set as output for signal each common Anode of 7SEG LEDs
		ORI    R20,   (1 << nLE0_PIN) | (1 << nLE1_PIN) 		
		OUT    nLEx_DDR,  R20 
		POP    R20 
		RET 



; INPUT: R27 = Num
;        R26 = Index (from 0 -> 3, as for LED_0 to LED_3) 

DISPLAY_7SEG: 
		PUSH  R16							; Save R16 and R20 before using it
		PUSH  R20 
		                           
        CLR   R16
		LDI   ZH,  HIGH(BCD_TABLE << 1)		; Z = base address of the look-up table 
		LDI   ZL,  LOW (BCD_TABLE << 1)
		ADD   ZL,  R27						; Add R27 to Z (16-bit)
		ADC   ZH,  R16						; Add carry to ZH if needed
 
	    LPM   R20, Z						; Load the code to the 7SEG pins
		OUT   LED7SEG_PORT,  R20 
		SBI   nLEx_PORT,  nLE0_PIN			; Pulse the latch to update 
		NOP 
		CBI   nLEx_PORT,  nLE0_PIN
		  


		LDI   ZH,  HIGH(COMMON_CATHOD_TABLE << 1)	; Z = base address of the look-up control table  
		LDI   ZL,  LOW (COMMON_CATHOD_TABLE << 1) 
		ADD   ZL,  R26								; Add R27 to Z (16-bit)
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
				 RET                       

     