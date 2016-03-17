;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2014
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
				EXPORT 		EINT3_IRQHandler 	; without this the interupt routine will not be found
				; The EINT3_IRQHandler is only defined in the startup file.
				ENTRY 

__MAIN

;Here is to set EINT3 channel. In user manual page 83 we can find the table
				LDR			R10, =ISER0
				MOV			R1, #0x200000		; Setting bit 21 of ISER0
				STR			R1, [R10]			; Storing the right value into ISER0 in order to enable EINT3
				LDR			R10, =IO2IntEnf		;Base address of the falling edge enable
				MOV			R1, #0x400			;10th pin
				STR			R1, [R10]
				
; The following lines are similar to previous labs.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR	; R10 is a  pointer to the base address for the LEDs
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 
				;Initiate all registers
				MOV			R1, #0
				MOV			R2, #0
				MOV			R3, #0
				MOV			R5, #0
				MOV			R4, #0
				MOV			R6, #1				;Flag is setup
				MOV			R7, #0
;Set a flag R4 to indicate if there is an interrupt
;R4 = 1 if unpressed. pressed if R4 = 0
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number		
		
GET_RANNUM		BL			RNG
				MOV			R6, #1				;Set R4 to check interrupt
				MOV			R4, #0				;Reassign R4 to be 0 for new random number
				BFI			R4, R11, #0, #4		;Get random number
				MOV			R5, #13				;250/15 to get factor
				MUL			R4, R4, R5			;multiply back the factor
				ADD			R4, #50				;Here we get 5 to 25 seconds				
				MOV			R8, R4				;R8 is the number we need to display

CHECKINT		TEQ			R6, #0				;check the flag
				BEQ			GET_RANNUM			;Get random number if flag is set
				MOV			R7, R8				;We use R7 to display
				BL			DISPLAY_NUM			;display number
				MOV			R0, #10				;1 second delay
				BL			DELAY
				SUBS		R8, #10				;Decrement by 1 second
				BPL			CHECKINT			;once the number is less than 0 we go to main program
				
FLASH 			TEQ			R6, #0				;check the flag
				BEQ			GET_RANNUM			;If interrupt, get new random number
				MOV			R0, #1				;The following code is for flashing
				BL			LED_ON
				BL			DELAY
				MOV			R0, #1
				BL			LED_OFF
				BL			DELAY
				B			FLASH
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD		R13!,{R1-R3, R15}
				
;Turn on all LED
LED_ON 	 		STMFD		R13!,{R3, R14}		; preserve R3 and R4 on the R13 stack
				MOV			R3, #0x00000000		; assign R3 value for turning on 
				STR			R3, [R10, #0x20]	; let p1.28 LED off
				MOV			R3, #0x0
				STR			R3, [R10, #0x40]
				LDMFD		R13!,{R3, R15}		
; Turn ALL LED off
LED_OFF			STMFD		R13!,{R3, R14}		; push R3 and Link Register (return address) on stack
				MOV     	R3, #0xB0000000 	; assign R3 value for turning off.
				STR 		R3, [R10, #0x20] 	; let p1.28 LED off
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40]
				LDMFD		R13!,{R3, R15}		; restore R3 and LR to R15 the Program Counter to return	

;Display number				
DISPLAY_NUM		STMFD		R13!,{R1, R2, R14}
				EOR			R7, #0xFFFFFFFF		; 1s complement the input, bitwise to be output, 0 is on, 1 is off
				BFI			R1,	R7, #0, #5		; 5 bits of the 8, starting from the least significant, will be displayed on port 2
				RBIT		R1, R1				; Reverse bits to obtain the correct order
				LSR			R1, #25				; Shift to right 15 bit such that bit 0 and 1 is empty prior to write to port 2
				STR			R1, [R10, #0x40]	; We display the 5 bits on port 2;
				LSR			R7, #5				; discard the 5 first bit
				MOV			R1, #0				; Clear R1 and R2
				MOV			R2, #0				;
				BFI			R2, R7, #0, #1		; Move bit 5 to R2 for later use
				LSR			R7, #1				; LSL 1 place to leave the most significant bits and the one after of the 8 bits
				BFI			R1, R7, #0,	#2		; Store the last 2 bit
				LSL			R1, #2				; Free 2 space such port 1 will have correct bit stored in 31, 29, 28
				ADD			R1, R2				; Complete port 1's bit
				RBIT		R1,	R1				; Reverse the bit to obtain correct order
				STR			R1, [R10, #0x20]	; We display the 3 bits on port 1
				LDMFD		R13!,{R1, R2, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 1ms * R0 times
;*------------------------------------------------------------------- 
DELAY			STMFD		R13!,{R0, R2, R14}
MultipleDelay	TEQ			R0, #0				; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE
				MOV			R2, #0x0001F400		; value for 0.1S

COUNTER											; Loop for the counter which is used for 0.1ms delay
				SUBS 		R2, #1 				; Decrement r0 and set the N,Z,C status bits
				BNE     	COUNTER				; If the counter hasn't reached 0 it will go back and continue to count down
				SUBS		R0, #1				; R0 is the multiplier. How many times the of 0.1ms
				BNE			MultipleDelay		; If R0 is not zero then it means we need one more 0.1ms
				BEQ			exitDelay;
exitDelay		LDMFD		R13!,{R0, R2, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
				STMFD 		R13!, {R3,R10, R14} ; Use this command if you need it  
				MOV			R6, #0				;set flag that interrupt has been set up
				LDR			R10, =IO2INTCLR		;Set the clear to clear interrupt
				MOV			R3, #0x400			;10th pin
				STR			R3, [R10]			;clear the interrupt
				LDMFD 		R13!, {R3,R10, R15} ; Use this command if you used STMFD (otherwise use BX LR) 

;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16] GPIO
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0] GPIO
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 

;The intClr address is in user manual page 123
IO2INTCLR		EQU		0x400280AC		; Interrupt Port 2 Clear Register
FIO2PIN 		EQU 	0x2009c054
				ALIGN 

				END 
