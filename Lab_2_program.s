;*----------------------------------------------------------------------------
;* Name:    Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: Eric Praetzel and Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
		THUMB 		; Declare THUMB instruction set 
                AREA 		My_code, CODE, READONLY 	; 
                EXPORT 		__MAIN 		; Label __MAIN is used externally q
		ENTRY 
__MAIN
; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;
; Turn off all LEDs 
		MOV 		R2, #0xC000
		MOV 		R3, #0xB0000000	
		MOV 		R4, #0x0
		MOVT 		R4, #0x2009
		ADD 		R4, R4, R2 		; 0x2009C000 - the base address for dealing with the ports
		STR 		R3, [r4, #0x20]	; Turn off the three LEDs on port 1
		MOV 		R3, #0x0000007C
		STR 		R3, [R4, #0x40] ; Turn off five LEDs on port 2 

ResetLUT
		LDR         R5, =InputLUT   ; assign R5 to the address at label LUT

; read the next character
NextChar
        LDRB        R0, [R5]		; Read a character to convert to Morse
       	ADD         R5, #1      	; point to next value for number of delays, jump by 1 byte
		TEQ         R0, #0      	; If we hit 0 (null at end of the string) then reset to the start of lookup table
		BNE			ProcessChar		; If we have a character process it
		MOV			R0, #4			; delay 4 extra spaces (7 total) between words
		BL			DELAY
		BEQ         ResetLUT

; Process the character
ProcessChar	
		BL			CHAR2MORSE			; convert ASCII to Morse pattern in R1		
		B			CheckForFirstOne	; go to the CheckForFisrtOne subroutine

; First - loop until we have a 1 bit to send
CheckForFirstOne
		MOV			R6, #0x80000000		; Init R6 with the value for the bit, 15th, which we wish to test
		LSL			R1, R1, #1			; shift R1 left by 1, store in R1
		ANDS		R7, R1, R6			; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
		BEQ			CheckForFirstOne	; branch back to continue to find the first one if it's zero
		LSR			R1, R1, #1			; now we get first one and wo need it to be shifted back.
		BNE			ConvertCharToLight 	; we get first one so we go to lighten the led

; convert the character to the LED light signal
ConvertCharToLight TEQ R1, #0	; test if R1 is 0 to see if we still have character
		BEQ			EndOfChar   		; if it has no more character so it's the end and we need 3 spaces for it
		MOV			R6, #0x80000000		; Init R6 with the value for the bit, 15th, which we wish to test
		LSL			R1, R1, #1			; shift R1 left by 1, store in R1
		ANDS		R7, R1, R6			; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
		BNE			DashOrDot			; we need led to turn on and we need to see if it's long or short
		BEQ			Blank				; since it's 0 so we just need it to blank for 1 delay

; this subroutine implement a 500ms blank between characters
Blank		
		MOV			R0, #1				; In case of blank we just need one delay of led to be turned off
		BL			LED_OFF    			; We turn the led off
		BL			DELAY				; with one delay
		B			ConvertCharToLight	; then after doing this we go back to continue to turn light for remaining chracters
		
; this subtoutine is called when we want to light up a LED
; call the LED_ON subroutine and delay for 500ms
; go back to the ConvertCharToLight subroutine afterwards
DashOrDot	
		MOV			R0, #1				; In case of turning on the led we just use one space for each one
		BL			LED_ON				; turn the led light
		BL			DELAY				; we just need one delay
		B			ConvertCharToLight	; we go back to finish characters left
	
; this subroutine is called when we reach the end of a character
; call the LED_OFF subroutine and delay for 500ms*3
; go to the next character afterwards
EndOfChar
		BL			LED_OFF			; at the end of the caracter we turn off led
		MOV			R0, #3			; we need 3 spaces
		BL			DELAY			; use the delay
		B			NextChar		; now we go to the find next chracter to blink

; convert ASCII character to Morse pattern
; pass ASCII character in R0, output in R1
; index into MorseLuT must be by steps of 2 bytes
CHAR2MORSE	
		STMFD		R13!,{R0, R14}	; push Link Register (return address) on stack	
		SUB			R0, #0x41		; First we subtract R0 by 41 to get an index
		ADD			R0, R0			; The steps we need to find corresponding character
		LDR         R9, =MorseLUT	; Load the lookup table
		LDRH		R1, [R0, R9]	; Load halfword of the morse pattern
		LDMFD		R13!,{R0, R15}	; restore LR to R15 the Program Counter to return

; Turn the LED on
LED_ON 	 
		STMFD		R13!,{R3, R14}	; preserve R3 and R4 on the R13 stack
		MOV			R3, #0xA0000000	; assign R3 value for turning on 
		STR			R3, [R4, #0x20]	; let p1.28 LED off
		LDMFD		R13!,{R3, R15}	; branch to the address in the Link Register.  Ie return to the caller

; Turn the LED off
LED_OFF	
		STMFD		R13!,{R3, R14}	; push R3 and Link Register (return address) on stack
		MOV         R3, #0xB0000000 ; assign R3 value for turning off.
		STR 		R3, [r4, #0x20] ; let p1.28 LED off
		LDMFD		R13!,{R3, R15}	; restore R3 and LR to R15 the Program Counter to return

; Delay 500ms * R0 times
DELAY			
		STMFD		R13!,{R2, R14}	; push R2 and Link Register (return address) on stack

MultipleDelay
		TEQ			R0, #0			; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE
		MOV			R8, #0x00080000		; value for 500ms

; Delay for 500ms
counter								; Loop for the counter which is used for 500ms delay
		SUBS 		R8, #1 			; Decrement r0 and set the N,Z,C status bits
		BNE         counter			; If the counter hasn't reached 0 it will go back and continue to count down
		SUBS		R0, #1			; R0 is the multiplier. How many times the of 500ms
		BNE			MultipleDelay	; If R0 is not zero then it means we need one more 500ms
		BEQ			exitDelay		; If R0 is 0 it means we have counted all 500ms
	
exitDelay	
		LDMFD		R13!,{R2, R15}	; Now we compeleted delay so we exit the subroutine for delay

; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
InputLUT	DCB		"CZHZW", 0	; strings must be stored, and read, as BYTES

		ALIGN				; make sure things fall on word addresses
MorseLUT 
		DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
		DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
		DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
		DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
		DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
		DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
		DCW 	0x1D77, 0x775 			; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

		END 
