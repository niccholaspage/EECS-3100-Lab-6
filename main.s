;*******************************************************************
; main.s
; Author: Nicholas Nassar
; Date Created: 10/20/2020
; Last Modified: 10/22/2020
; Section Number: 002
; Instructor: Devinder Kaur
; Lab number: 6
; Brief description of the program
; If the switch is pressed, the LED toggles at 8 Hz.
; Hardware connections
;   PE1 is switch input  (1 means pressed, 0 means not pressed)
;   PE0 is LED output (1 activates external LED on protoboard) 
; Overall functionality is similar to Lab 5, with three changes:
;   1) Initialize SysTick with RELOAD 0x00FFFFFF 
;   2) Add a heartbeat to PF2 that toggles every time through loop 
;   3) Add debugging dump of input, output, and time
; Operation
;	1) Make PE0 an output and make PE1 an input. 
;	2) The system starts with the LED on (make PE0 =1). 
;   3) Wait about 62 ms
;   4) If the switch is pressed (PE1 is 1), then toggle the LED
;      once, else turn the LED on. 
;   5) Steps 3 and 4 are repeated over and over
;*******************************************************************

SWITCH                  EQU 0x40024004  ;PE0
LED                     EQU 0x40024008  ;PE1
SYSCTL_RCGCGPIO_R       EQU 0x400FE608
SYSCTL_RCGC2_GPIOE      EQU 0x00000010  ;port E Clock Gating Control
SYSCTL_RCGC2_GPIOF      EQU 0x00000020  ;port F Clock Gating Control
GPIO_PORTE_DATA_R       EQU 0x400243FC
GPIO_PORTE_DIR_R        EQU 0x40024400
GPIO_PORTE_AFSEL_R      EQU 0x40024420
GPIO_PORTE_PUR_R        EQU 0x40024510
GPIO_PORTE_DEN_R        EQU 0x4002451C
GPIO_PORTF_DATA_R       EQU 0x400253FC
GPIO_PORTF_DIR_R        EQU 0x40025400
GPIO_PORTF_AFSEL_R      EQU 0x40025420
GPIO_PORTF_PUR_R        EQU 0x40025510
GPIO_PORTF_DEN_R        EQU 0x4002551C
GPIO_PORTF_AMSEL_R      EQU 0x40025528
GPIO_PORTF_PCTL_R       EQU 0x4002552C
GPIO_PORTF_LOCK_R  	    EQU 0x40025520
GPIO_PORTF_CR_R         EQU 0x40025524
NVIC_ST_CTRL_R          EQU 0xE000E010
NVIC_ST_RELOAD_R        EQU 0xE000E014
NVIC_ST_CURRENT_R       EQU 0xE000E018
GPIO_PORTE_AMSEL_R      EQU 0x40024528
GPIO_PORTE_PCTL_R       EQU 0x4002452C

	THUMB
	AREA    DATA, ALIGN=4
SIZE	EQU    50
;You MUST use these two buffers and two variables
;You MUST not change their names
DataBuffer	SPACE	SIZE*4
TimeBuffer	SPACE	SIZE*4
DataPt		SPACE	4
TimePt		SPACE	4
;These names MUST be exported
	EXPORT DataBuffer  
	EXPORT TimeBuffer  
	EXPORT DataPt [DATA,SIZE=4] 
	EXPORT TimePt [DATA,SIZE=4]
    
	ALIGN
	AREA    |.text|, CODE, READONLY, ALIGN=2
	THUMB
	EXPORT  Start
	IMPORT  TExaS_Init

Start
	BL   TExaS_Init  ; running at 80 MHz, scope voltmeter on PD3
	; SYSCTL_RCGCGPIO_R = 0x30 for Port F & E
	MOV R0, #0x30
	LDR R1, =SYSCTL_RCGCGPIO_R
	STR R0, [R1]
	; initialize Port E
InitPortE
	
	LDR R0, [R1] ; Delay before continuing

	; GPIO_PORTE_AMSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AMSEL_R
	STR R0, [R1]
	
	; GPIO_PORTE_PCTL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_PCTL_R
	STR R0, [R1]

	; GPIO_PORTE_DIR_R = 0x01
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DIR_R
	STR R0, [R1]

	; GPIO_PORTE_AFSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AFSEL_R
	STR R0, [R1]

	; GPIO_PORTE_DEN_R = 0x03
	MOV R0, #0x03
	LDR R1, =GPIO_PORTE_DEN_R
	STR R0, [R1]
	
	; Turns LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
InitPortF
	; initialize Port F
	LDR R0, [R1] ; Delay before continuing

	; Before writing to the CR register,
	; we must first unlock Port F.
	; Since we can't write a 32-bit constant
	; directly, we use MOV & MOVT together to
	; do it in two 16-bit parts.
	; GPIO_PORTF_LOCK_R = 0x4C4F434B
	MOV R0, #0x434B
	MOVT R0, #0x4C4F
	LDR R1, =GPIO_PORTF_LOCK_R
	STR R0, [R1]

	; GPIO_PORTF_CR_R = 0x04
	MOV R0, #0x04
	LDR R1, =GPIO_PORTF_CR_R
	STR R0, [R1]

	; GPIO_PORTF_AMSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_AMSEL_R
	STR R0, [R1]
	
	; GPIO_PORTF_PCTL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_PCTL_R
	STR R0, [R1]

	; GPIO_PORTF_DIR_R = 0x04
	MOV R0, #0x04
	LDR R1, =GPIO_PORTF_DIR_R
	STR R0, [R1]

	; GPIO_PORTF_AFSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_AFSEL_R
	STR R0, [R1]

	; GPIO_PORTF_PUR_R = 0x10
	MOV R0, #0x00
	LDR R1, =GPIO_PORTF_PUR_R
	STR R0, [R1]

	; GPIO_PORTF_DEN_R = 0x18
	MOV R0, #0x04
	LDR R1, =GPIO_PORTF_DEN_R
	STR R0, [R1]

	; initialize debugging dump, including SysTick
	BL Debug_Init


	CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop
	BL   Debug_Capture
	;heartbeat
	BL Heartbeat
	; Delay
	BL Delay62ms
	  
	; input PE1 test output PE0
	LDR R1, =GPIO_PORTE_DATA_R ; Load the address of Port E data into R1
	LDR R0, [R1] ; Load the value at the address in R1 into R0
	LSR R0, #1 ; Shift the register 1 bit to the right, since we only care about pin 1
	CBNZ R0, Toggle_LED_PortE ; Since the switch is on, we toggle the LED
	; The switch is off, so turn the LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	B    loop

Toggle_LED_PortE ; Toggles the LED
	; Read Port E data so we can check if LED is on or not
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R0, [R1] ; Load the value at the address in R1 into R0
	AND R0, #0x01 ; Clear all bits except for bit zero
	CBZ R0, Turn_LED_On_PortE ; If the LED is off, then we turn it on
	; Otherwise, turn the LED off
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	B loop ; Loop again!

Turn_LED_On_PortE
	; Turns LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	B loop ; Loop again!

; A subroutine that delays for 62 ms then returns to the original line
Delay62ms
	; MOV R12, #0xD000 ; set R12 to our big number to get us our 62 ms delay
	; MOVT R12, #0x12 ; Needed so we can fill the upper halfword of the register too
	; Number updated! Due to new debugging code, we have to shorten our delay.
	MOV R12, #0xB000
	MOVT R12, #0xC
WaitForDelay
	SUBS R12, R12, #0x01 ; Subtract one from the register
	BNE WaitForDelay ; If the value isn't zero, go back to waiting for the delay
	BX LR ; We did it, we finished waiting! So we go back to where we were before calling this.

Heartbeat
	PUSH {R0, R1} ; save R0 and R1
	LDR R1, =GPIO_PORTF_DATA_R ; Load address of Port F data into R1
	LDR R0, [R1] ; Load actual data into R0
	CMP R0, #0x00 ; Check if R0 is 0, meaning the LED is off.
	BEQ Turn_On_LED_PortF ; turn the LED on if it is off
	; Otherwise, just turn off the LED
	MOV R0, #0x00 ; Move 0x00 into data to turn the LED off
	LDR R1, =GPIO_PORTF_DATA_R ; Load the address of Port F data into R1
	STR R0, [R1] ; Store 0x00 into GPIO_PORTF_DATA_R
	POP {R0, R1} ; restore R0 and R1
	BX LR ; go back to caller
Turn_On_LED_PortF
	MOV R0, #0x04 ; Move 0x04 into data to turn the LED on
	LDR R1, =GPIO_PORTF_DATA_R ; Load the address of Port F data into R1
	STR R0, [R1] ; Store 0x04 into GPIO_PORTF_DATA_R
	POP {R0, R1} ; restore R0 and R1
	BX LR ; go back to caller

;------------Debug_Init------------
; Initializes the debugging instrument
; Note: push/pop an even number of registers so C compiler is happy
Debug_Init
	PUSH {R0-R3} ; Save R0-R3
	; Place 0xFFFF FFFF into all elements of DataBuffer
	LDR R0, =DataBuffer
DataArray_Init
	MOV R2, #0 ; Our count - we start at the first element in the array
	MOV R1, #0xFFFFFFFF ; We will be filling the array with 0xFFFF FFFF
DataArray_Loop
	STR R1, [R0] ; Store 0xFFFF FFFF into the current element in the array
	ADD R2, #1 ; Increment our count by 1
	CMP R2, #SIZE ; Compare our count to size
	BEQ DataContinue ; If its equal, continue.
	; Otherwise, loop again after incrementing R0.
	ADD R0, #4 ; Add 4 to R0 for the next address.
	B DataArray_Loop ; Loop again!

DataContinue
	; Place 0xFFFF FFFF into all elements of TimeBuffer
	LDR R0, =TimeBuffer
TimeArray_Init
	MOV R2, #0 ; Our count - we start at the first element in the array
	MOV R1, #0xFFFFFFFF ; We will be filling the array with 0xFFFF FFFF
TimeArray_Loop
	STR R1, [R0] ; Store 0xFFFF FFFF into the current element in the array
	ADD R2, #1 ; Increment our count by 1
	CMP R2, #SIZE ; Compare our count to size
	BEQ TimeContinue ; If its equal, continue.
	; Otherwise, loop again after incrementing R0.
	ADD R0, #4 ; Add 4 to R0 for the next address.
	B TimeArray_Loop ; Loop again!

TimeContinue
	LDR R0, =DataBuffer	; Load address of data buffer into R0
	LDR R1, =DataPt		; Load address of data pointer into R0
	STR R0, [R1] ; Point DataPt to the address of the data buffer

	LDR R0, =TimeBuffer	; Load address of time buffer into R0
	LDR R1, =TimePt		; Load address of time pointer into R0
	STR R0, [R1] ; Point TimePt to the address of the time buffer

	; init SysTick
	LDR R1, =NVIC_ST_CTRL_R
	MOV R0, #0 ; disable SysTick during setup
	STR R0, [R1]
	LDR R1, =NVIC_ST_RELOAD_R ; R1 = &NVIC_ST_RELOAD_R
	LDR R0, =0x00FFFFFF; ; maximum reload value
	STR R0, [R1] ; [R1] = R0 = NVIC_ST_RELOAD_M
	LDR R1, =NVIC_ST_CURRENT_R ; R1 = &NVIC_ST_CURRENT_R
	MOV R0, #0 ; any write to current clears it
	STR R0, [R1] ; clear counter
	LDR R1, =NVIC_ST_CTRL_R ; enable SysTick with core clock
	MOV R0, #0x05
	STR R0, [R1] ; ENABLE and CLK_SRC bits set
	; end init SysTick

	POP {R0-R3} ; Restore R0-R3

	BX LR

;------------Debug_Capture------------
; Dump Port E and time into buffers
; Note: push/pop an even number of registers so C compiler is happy
Debug_Capture
	; Estimating intrusiveness:
	; Debug_Capture contains 30 instructions
	; 30 * 2 cycles * 12.5 nanoseconds = 750 nanoseconds
	; Total delay: 62 ms + 0.00075 ms = 62.00075 ms
	; 0.00075 ms / 62.00075 ms = 0.00001209662 * 100 = 0.001209662% intrusiveness
	; Therefore, the instrusiveness was incredibly small.
	; Step 1. Save registers:
	PUSH { R0-R4, R12 }
	
	; Step 2. Return immediately if the buffers are full
	LDR R12, =DataPt ; Loads the address of the data pointer into R0
	LDR R0, [R12] ; Loads the actual data pointer into R0
	LDR R1, =DataBuffer ; Loads the address of the data buffer into R1
	LDR R2, =SIZE ; Load the size of our buffer into R1
	LSL R2, #0x02 ; Multiply our size by 4, for 4 bytes, utilizing a logical shift of 2 bits
	ADD R1, R2 ; Add the beginning data buffer address and buffer size together
	CMP R0, R1 ; Compare the address of our actual data pointer to the address at the end of the buffer
	BHS Debug_Capture_Done ; If its greater or equal, we are done, no data capture!
	
	; Unnecessary because buffers are both written to at same time
	; Step 2b. TimePt check
	; LDR R12, =TimePt ; Loads the address of the data pointer into R0
	; LDR R0, [R12] ; Loads the actual data pointer into R0
	; LDR R1, =TimeBuffer ; Loads the address of the data buffer into R1
	; LDR R2, =SIZE ; Load the size of our buffer into R1
	; LSL R2, #0x02 ; Multiply our size by 4, for 4 bytes, utilizing a logical shift of 2 bits
	; ADD R1, R2 ; Add the beginning data buffer address and buffer size together
	; CMP R0, R1 ; Compare the address of our actual data pointer to the address at the end of the buffer
	; BHS Debug_Capture_Done ; If its greater, we are done, no data capture!

	; Step 3. Read Port E data
	LDR R12, =GPIO_PORTE_DATA_R ; Load the address of where GPIO_PORTE_DATA is located
	LDR R0, [R12] ; Put the value of GPIO_PORTE_DATA into R0

	; Step 3. Read NVIC_ST_CURRENT data
	LDR R12, =NVIC_ST_CURRENT_R ; Load the address of where NVIC_ST_CURRENT_R is located
	LDR R1, [R12] ; Put the value of NVIC_ST_CURRENT into R1
	
	; Step 4. Mask capturing just bits 0 and 1 of the Port E data
	AND R0, #0x03
	
	; Step 5. Shift Port E data bit 1 to 4, leave bit 0 in 0 position
	TST R0, #0x01 ; Check if bit 0 in data is on
	LSL R0, #0x03 ; Shift to the left 3 bits
	ANDNE R0, #0x10 ; Clear bit 3 if original bit 0 was on
	ORRNE R0, #0x01 ; Set bit 0 to 1 if original bit 0 was on

	; Step 6. Dump modified data into DataBuffer
	; We want to store our current data at the correct element of the data buffer:
	LDR R12, =DataPt ; Load the address of memory where our data pointer is into R0
	LDR R2, [R12] ; Load the value DataPt points to into R2
	STR R0, [R2] ; Store our modified data into R2
	
	; Step 7. Increment DataPt to next address
	ADD R2, #4 ; Increment our pointer by 4
	STR R2, [R12] ; Store our pointer into DataPt

	; Step 8. Dump time into TimeBuffer
	; We want to store our current time at the correct element of the time buffer:
	LDR R12, =TimePt ; Load the address of memory where our time pointer is into R0
	LDR R3, [R12] ; Load the value TimePt points to into R3
	STR R1, [R3] ; Store the value NVIC_ST_CURRENT into the data TimePt points to

	; Step 9. Increment TimePt to next address
	ADD R3, #4 ; Increment our pointer by 4
	STR R3, [R12] ; Store our pointer into TimePt

Debug_Capture_Done
	; Step 10. Restore saved registers and return
	POP { R0-R4, R12 }
	BX LR ; Go back to the caller!


    ALIGN      ; make sure the end of this section is aligned
    END        ; end of file
        