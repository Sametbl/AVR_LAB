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







.ORG 0x0000     ; Reset vector
		JMP    MAIN

.ORG 0x001A     ; Timer1 Compare Match A vector
		JMP    COMPARE_MATCH


; Lookup table for 7-segment codes
BCD_TABLE:   .DB  0xC0, 0xF9,0xA4,0xB0,0x99,0x92,0x82,0xF8,0x80,0x90,0x88,0x8 

; Lookup table for LED control 
COMMON_ANODE_TABLE:  .DB  0b00000001, 0b00000010, 0b00000100, 0b00001000 

; Store the BCD value to display 
LED7_NUM:   .DB  0x04, 0x03, 0x02, 0x01  



.EQU LED7SEG_PORT = PORTB			; Two 74HC573 ICs (Data and Common Anode) use the same PORT
.EQU LED7SEG_DDR  =  DDRB 
.EQU nLEx_PORT    = PORTD			; Seperate PORT for controling LATCH pin
.EQU nLEx_DDR     =  DDRD 
.EQU nLE0_PIN     = 0 
.EQU nLE1_PIN     = 1 
.DEF LED7_INDEX   = R5

 
MAIN:	LDI    R16,   HIGH(RAMEND)		; Initialize Stach, for good practice
		OUT    SPH,   R16
		LDI    R16,   LOW(RAMEND)
		OUT    SPL,   R16

		SBI    DDRC,   0				; Set PC0 as Output 
		CBI    PORTC,  0				; Clear PC0	
		 
		LDI    R16,    0				; Initialize LED7_INDEX (R5)
		MOV    LED7_INDEX,  R16	

		RCALL  LED_7SEG_PORT_INIT

		LDI    R16, (1 << OCIE1A)		; Enable Timer1 Output Compare Match A Interrupt
		STS    TIMSK1, R16

		CALL   TIMER1_INIT				; Select CTC mode, start Timer
		SEI								; Enable Global interrupt


INF_LOOP: JMP INF_LOOP					; Do "other tasks", let to ISR display 7-segment LEDs



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
		  


		LDI   ZH,  HIGH(COMMON_ANODE_TABLE << 1)	; Z = base address of the look-up control table  
		LDI   ZL,  LOW (COMMON_ANODE_TABLE << 1) 
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
		 
		 


; Internal clk = 8 MHz  <==> 0.125  ns per cycle
; Refresh rate = 50 Hz ===> Refresh period = 20 ms
; For four 7-segment LEDs, there is 5 ms delay before next LED is lit up 
; We need 5 ms delay ==> 40000 cycles ==> OCRA = 40000, Prescaler = 1


.EQU   TCNT1_INIT  = 0            ; Initialize Timer
.EQU   OCR1A_value = 39999        ; Count 40000 cycles, -1 because it starts from 0
.EQU   TCCR1A_mode = 0b00000000   ; Select CTC mode
.EQU   TCCR1B_mode = 0b00001001   ; No Prescaler


TIMER1_INIT:
		PUSH   R16	 
		LDI    R16, HIGH(TCNT1_INIT)	; Initialize Timer1 value
		STS    TCNT1H,  R16            
		LDI    R16, LOW (TCNT1_INIT)	
		STS    TCNT1L,  R16            

		LDI    R16, HIGH(OCR1A_value)	; Set Compare Register A value
		STS    OCR1AH,  R16            
		LDI    R16, LOW (OCR1A_value)	
		STS    OCR1AL,  R16            


		LDI    R16,     TCCR1A_mode		; Choose mode CTC
		STS    TCCR1A,  R16             
		LDI    R16,     TCCR1B_mode		; Start Timer	 
		STS    TCCR1B,  R16     
		POP    R16       
		RET


              
COMPARE_MATCH:  
		PUSH R16
		PUSH R26 
		PUSH R27 
		CLR  R16							; Clear R16, to add carry to ZH

		MOV  R26,  LED7_INDEX				; R26 = Index

		LDI  ZH,   HIGH(LED7_NUM << 1)		; Z = List of number to display
		LDI  ZL,   LOW (LED7_NUM << 1) 

		ADD  ZL,   R26						; Z* = Z* + Index
		ADC  ZH,   R16 
		LPM  R27,  Z 

		CALL DISPLAY_7SEG					; Display Number
  
		CPI  R26,  3
		BRNE TIMER1_COMP_ISR_CONT			; If LED7_INDEX = 0, Reset it to 3 
		LDI  R26,  -1						; Else, decrease LED7_INDEX 

TIMER1_COMP_ISR_CONT:  
		INC  R26                              
		MOV  LED7_INDEX, R26				; Save LED7_INDEX

		IN   R26,    PINC					; Get the state of PC0
		LDI  R27,    (1 << PINC0)			; Set a mask to toggle PC0
		EOR  R26,    R27					; Apply Mask and toggle PC0
		OUT  PORTC,  R26 

		POP  R27
		POP  R26
		POP  R16
		RETI 
			