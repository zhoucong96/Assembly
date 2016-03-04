; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR		R10, =LED_BASE_ADR	; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

				MOV 	R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 	R3, [r10, #0x20]
				MOV 	R3, #0x0000007C
				STR 	R3, [R10, #0x40] 	; Turn off five LEDs on port 2 
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV		R11, #0xABCD		; Init the random number generator with a non-zero number
				MOV		R0, #0				;Initial all registers
				MOV		R1, #0				
				MOV		R6, #0
				
;SIMPLECOUNTER	
;				BL		DISPLAY_NUM
;				MOV		R0, #1000
;				BL		DELAY
;				ADD		R1,R1,#1
;				B		SIMPLECOUNTER			;Infinite loop of simple counter

LOOP 			BL 		RANDOMNUM 				;Proceed to get random number R11
				BFI		R0, R11, #0, #8			;Get segment of random number to get our needed random number
				MOV		R7, #0x138				;The result of 80000/256 which is max to get 8 second
				MUL		R0, R0,R7				;Multiply the result to get a number between 0 and 8 second
				MOV		R8, #20000				;Initiate the 2 second to be added
				ADD		R0, R8					;Plus the 2 seconds to get a range from 2 to 10 seconds
				BL		DELAY					;Delay a random time
				BL		LED_ON					;After random time, turn the light on
				MOV		R4, #0					;Initiate the counter for response time
				B		POLL					;Start to poll to get respond time

;
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM		STMFD	R13!,{R1, R2, R14}

				MOV		R12, #0					;Initiate R12
				BFI		R12, R1, #0, #5			;Store the 5bit we need for port 2
				RBIT	R12, R12				;Reverse it to corresponde the the LED PIN
				LSR		R12, #25				;We need the bit from 2 to 6
				EOR		R12, #0xffffffff		;For LED, 0 is on and 1 is off
				STR		R12, [R10, #0x40]		;Write into the LED
				
				LSR		R1, #5					;Get the 3bit we need for port 1
				MOV		R12, #0					;Initiate R12
				BFI		R12, R1, #0, #1			;Get the bit for p1.31
				LSL		R1, #1					;The bit we don't want for p1.30
				ORR		R12, R1					;We add the 2bit left we need into it(The bit 30 we don't care) without carry
				RBIT	R12, R12				;Reverse it to write it into 31 to 28(skip 30)
				
				EOR		R12, #0xffffffff		;0 is on 1 is off
				STR		R12, [R10, #0x20]		;Write into port1 LED address
				
; Usefull commaands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations

				LDMFD	R13!,{R1, R2, R15}

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
;   If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RANDOMNUM		STMFD	R13!,{R1, R2, R3, R14}

				AND		R1, R11, #0x8000
				AND		R2, R11, #0x2000
				LSL		R2, #2
				EOR		R3, R1, R2
				AND		R1, R11, #0x1000
				LSL		R1, #3
				EOR		R3, R3, R1
				AND		R1, R11, #0x0400
				LSL		R1, #5
				EOR		R3, R3, R1				; the new bit to go into the LSB is present
				LSR		R3, #15
				LSL		R11, #1
				ORR		R11, R11, R3
				
				LDMFD	R13!,{R1, R2, R3, R15}

POLL			ADD		R4, R4, #1				;Increment the response counter
				MOV		R0, #1					;Polling period is 0.1ms
				BL		DELAY					;
				LDR		R9, =FIO2PIN			;Load the input from the address
				LDR		R9,[R9]					;Load the content into R6 to manipulate
				LSR		R9,R9,#10				;Get the input of the P2.10(See if it is pressed)
				BFI		R6,R9,#0,#1				;We only need the input of p2.10 to see if it is pressed
				TEQ		R6,#0					;If the button is pressed, we end the poll otherwise continue polling
				BNE		POLL
		
				BL		LED_OFF					;Once polling ends, turn of the LED
		
REPEAT			MOV		R7, #4					;Repeat the procedure read 4 segments again
				MOV		R5, R4					;R1 is the content of our counter R4

TIMETONUMBER	MOV		R1, #0
				BFI		R1, R5, #0, #8			;Get 8bit we need
				LSR		R5, #8					;Get next 8 bit we need
				BL		DISPLAY_NUM				;Go to display the 8 bit
				MOV		R0, #20000				;Here,
				BL		DELAY					;We delay to wait for 2 seconds
				SUBS	R7, #1					;We have 4 segments of 32 bit so we need to do 4 times to display
				BNE		TIMETONUMBER
		
				MOV		R0,	#30000				;We need 3 second + 2 second to wait 5 second
				BL		DELAY
				B		REPEAT
;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
DELAY			STMFD	R13!,{R0, R14}

MultipleDelay	TEQ		R0, #0					; test R0 to see if it's 0 - set Zero flag so you can use BEQ, BNE
				MOV		R8, #0x0000007E			; value for 0.1ms

COUNTER											; Loop for the counter which is used for 0.1ms delay
				SUBS 	R8, #1 					; Decrement r0 and set the N,Z,C status bits
				BNE     COUNTER					; If the counter hasn't reached 0 it will go back and continue to count down
				SUBS	R0, #1					; R0 is the multiplier. How many times the of 0.1ms
				BNE		MultipleDelay			; If R0 is not zero then it means we need one more 0.1ms
				BEQ		exitDelay				; If R0 is 0 it means we have counted all 0.1ms
	
exitDelay		LDMFD		R13!,{R0, R15}

; Turn the LED on
LED_ON 	 		STMFD	R13!,{R3, R14}			; preserve R3 and R4 on the R13 stack
				MOV		R3, #0xA0000000			; assign R3 value for turning on 
				STR		R3, [R10, #0x20]		; let p1.28 LED off
				LDMFD	R13!,{R3, R15}			; branch to the address in the Link Register.  Ie return to the caller

; Turn the LED off
LED_OFF			STMFD	R13!,{R3, R14}			; push R3 and Link Register (return address) on stack
				MOV     R3, #0xB0000000 		; assign R3 value for turning off.
				STR 	R3, [R10, #0x20] 		; let p1.28 LED off
				LDMFD	R13!,{R3, R15}			; restore R3 and LR to R15 the Program Counter to return


LED_BASE_ADR	EQU 	0x2009c000 				; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 				; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 				; Address of Pin Select Register 4 for P2[15:0]
FIO2PIN			EQU		0x2009c054				; Address of the input
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 

;---------------------------------------------------------------
;	POST LAB QUESTIONS
;
;	1-  The maximun amount of time which can be encoded in 
;		8 bits is 25.6ms,
;		16 bits is 6.5536s,
;		24 bits is 1677.7216s, and
;		32 bits is 429496.7296s.
;
;	2-  16 bits would be the best for tihis task.
;
