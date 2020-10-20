;*******************************************************************
; main.s
; Author: ***update this***
; Date Created: 11/18/2016
; Last Modified: 11/18/2016
; Section Number: ***update this***
; Instructor: ***update this***
; Lab number: 6
; Brief description of the program
;   If the switch is presses, the LED toggles at 8 Hz
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
ArrayIndex	SPACE	4
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

Start BL   TExaS_Init  ; running at 80 MHz, scope voltmeter on PD3
      ; initialize Port E
      ; initialize Port F
      ; initialize debugging dump, including SysTick
	  ; ?????:
	  BL Debug_Init


      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  BL   Debug_Capture
      ;heartbeat
      ; Delay
      ;input PE1 test output PE0
	  B    loop

;------------Debug_Init------------
; Initializes the debugging instrument
; Note: push/pop an even number of registers so C compiler is happy
Debug_Init
	
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

	BX LR

;------------Debug_Capture------------
; Dump Port E and time into buffers
; Note: push/pop an even number of registers so C compiler is happy
Debug_Capture
	; We want to store our current time at the correct element of the time buffer:
	LDR R0, =TimePt ; Load the address of memory where our time pointer is into R0
	LDR R1, [R0] ; Load the value TimePt points to into R1
	LDR R2, =NVIC_ST_CURRENT_R ; Load the address of where NVIC_ST_CURRENT_R is located
	LDR R3, [R2] ; Put the value of NVIC_ST_CURRENT into R3
	STR R3, [R1] ; Store the value NVIC_ST_CURRENT into the data TimePt points to

	ADD R1, #4 ; Increment our pointer by 4
	STR R1, [R0] ; Store our pointer into TimePt
	BX LR


    ALIGN      ; make sure the end of this section is aligned
    END        ; end of file
        