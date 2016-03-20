;---------------------------------------------------------------
; Console I/O through the on board UART for MSP 430g2553 on the launchpad
; Do not to forget to set the jumpers on the launchpad board to the vertical
; direction for hardware TXD and RXD UART communications.  This program
; uses a hyperterminal program connected to the USB Code Composer
; interface com port .  Use the Device manager under the control panel
; to determine the com port address.  RS232 settings 1 stop, 8 data,
; no parity, 9600 baud, and no handshaking.
;---------------------------------------------------------------

;-------------------------------------------------------------------------------
;            .cdecls C,LIST,"msp430.h"       ; Include device header file
			.cdecls C,LIST,"msp430g2553.h"
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section


; Main Code
;----------------------------------------------------------------
	; This is the stack and variable area of RAM and begins at
	; address 0x1100 can be used for program code or constants
	; .sect ".stack" ; data ram for the stack ; .sect ".const" ; data rom for initialized
	; data constants
	; .sect ".text" ; program rom for code
	; .sect ".cinit" ; program rom for global inits
	; .sect ".reset" ; MSP430 RESET Vector
	; .sect ".sysmem" ; data ram for initialized
	; variables. Use this .sect to
	; put data in RAM
	;data .byte 0x34 ; example of defining a byte
			.bss label, 4 ; allocates 4 bytes of
	; uninitialized memory with the
	; name label
			.word 0x1234 ; example of defining a 16 bit
	; word
	;strg2 .string "Hello World" ; example of a string store in
	; RAM
			.byte 0x0d,0x0a ; add a CR and a LF to the string
			.byte 0x00 ; null terminate the string

			; These following values are used for testing purposes
			.sect ".sysmem"
digits		.word 0x4D61, 0x6B65, 0x2073, 0x7572, 0x6520, 0x746F, 0x2073, 0x7461
			.word 0x7920, 0x7475, 0x6E65, 0x6420, 0x6166, 0x7465, 0x7220, 0x7468
			.word 0x6520, 0x6372, 0x6564, 0x6974, 0x7300

store0		.word 0x0000
store1		.word 0x0001
store2		.word 0x0002
	; This is the constant area flash begins at address 0x3100 can be
	; used for program code or constants
			.sect ".const" ; initialized data rom for
	; constants. Use this .sect to
	; put data in ROM
strg1 		.string "This is a test" ; example of a string stored
	; in ROM
			.byte 0x0d,0x0a ; add a CR and a LF
			.byte 0x00 ; null terminate the string with
	; This is the code area flash begins at address 0x3100 can be
	; used for program code or constants
			.text ; program start
			.global _START ; define entry point
	;----------------------------------------------------------------
STRT 		mov.w #300h,SP ; Initialize 'x1121
							; stackpointer
StopWDT 	mov.w #WDTPW+WDTHOLD,&WDTCTL ; Stop WDT
			call #Init_UART

Mainloop
			mov.b #0x43, R4 ; Display the text "CRLF>" to prompt user input
			call #OUTA_UART
			mov.b #0x52, R4
			call #OUTA_UART
			mov.b #0x4C, R4
			call #OUTA_UART
			mov.b #0x46, R4
			call #OUTA_UART
			mov.b #0x3E, R4
			call #OUTA_UART

			call #INCHAR_UART 	;Take in the command character to select function

			cmp.b #0x4D, R4 	; This activates the Memory Change subroutine
			jeq M

			cmp.b #0x44, R4 	; This activates the Display Memory subroutine
			jeq D

			cmp.b #0x48, R4 	; This activates the Hex Calculator subroutine
			jeq H

			jmp Mainloop		; If none, match, return to command input

M								; Begin Memory Change program
			call #OUTA_UART		; Echo the input character to screen
			mov.w #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Take in the first hexadecimal number
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R8

			mov.w #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Take in the second hexadecimal number
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R9

			cmp.w #0x0020, R9	; Detect if the exit condtion has been found
			jeq NEXT3

			cmp.w #0x006E, R9	; Detect if the "n" function is being used
			jne NEXT1
			dec.w R8			; Subtract 1 from the target address
			mov.w R9, 0(R8)		; Move the intended address to the intended spot in memory
			call #NL
			mov.w #0x4D, R4
			jmp M				; Get ready to accept new address

NEXT1		cmp.w #0x0070, R9	; Detect if the "p" function is being used
			jne NEXT2
			inc.w R8			; Add 1 from the target address
			mov.w R9, 0(R8)		; Move the intend adress to the intended spot in memory
			call #NL
			mov.w #0x4D, R4
			jmp M				; Get ready to accept new address

NEXT2		mov.w R9, 0(R8)		; Detect if the ordinary memory function is being used
			call #NL
			mov.w #0x4D, R4
			jmp M

NEXT3       call #NL
			jmp Mainloop		; Return to the command input

D								; Begin Display Memory program
			call #OUTA_UART		; Echo input character to screen
			mov.w #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Take in first hexadecimal number
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R8

			mov.w #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Take in second hexadecimal number
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R9
			add.w #0x02, R9		; Move just past ending address

			call #NL

			mov.w #0x08, R7		; Set up counters
			mov.w #0x00, R15
			mov.w R8, R10		; Copy intial address

			mov.w R10, R11		; Display first address of the line
			mov.w R10, R12
			mov.w R10, R13
			mov.w R10, R14
			call #DISPLAY

TYPE1
			mov.w @R10, R11		; Display contents of Memory at current address
			mov.w @R10, R12
			mov.w @R10, R13
			mov.w @R10, R14

			call #DISPLAY

			inc.b R15			; Adjust counters for each iteration
			dec.b R7
			add.w #0x02,R10		; Move to next address
			cmp.w R9, R10		; Make sure next address is within specified range
			jge SEPARATOR0		; Move to symbolic section when final address found
			cmp.b #0x00, R7		; If final address isn't found
			jne TYPE1

SEPARATOR0
			mov.b #0x20, R4
			mov.b #0x08, R8
			cmp.b R8, R15		; Detect if 8 words were displayed or the final address was found
			jl SUPPLEMENT		; If less than 8 words were displayed, fill the remaing space

SEPARATOR1
			mov.w R15, R6
			rla.w R6
			sub.w R6, R10
			call #OUTA_UART		; Separate the numeric data from the symbols
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
TYPE2

			mov.w @R10, R6		; Obtain the bytes at each address
			mov.w @R10, R7
			and.w #0xFF00, R6
			rra.w R6
			rra.w R6
			rra.w R6
			rra.w R6
			rra.w R6
			rra.w R6
			rra.w R6
			rra.w R6
			and.w #0x00FF, R6
			mov.b R6, R4
			call #FILTER		; Display the symbols represented by bytes at each address
			and.w #0x00FF, R7
			mov.b R7, R4
			call #FILTER

			dec.b R15
			add.w #0x02, R10	; When finished with current address, move to the next
			cmp.w R9, R10
			jge FIN				; Repeat until all symbols have been displayed
			cmp.b #0x00, R15
			jne TYPE2

			mov.b #0x08, R7		; Reset counters for next line
			mov.b #0x00, R15
			call #NL

			mov.w R10, R11		; Display first address of new line
			mov.w R10, R12
			mov.w R10, R13
			mov.w R10, R14
			call #DISPLAY
			jmp TYPE1

FIN
		    call #NL			; Separate from rest of program and return to function choice
		    call #NL
			jmp Mainloop

H								; Begin hexadecimal calculator program
			call #OUTA_UART		; Display the input character to confirm its use
FUNCTION
			call #INCHAR_UART	; Take in character for add or subtract
			cmp.b #0x41, R4
			jeq A
			cmp.b #0x53, R4
			jeq S
			jmp FUNCTION		; Where the character taken in does not match either, repeat process
A								; Start add program
			call #OUTA_UART		; Echo input character
			mov.b #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Take in first hexadecimal favlue
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R8

			mov.w #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Take in second hexadecimal value
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R9

			add.w R8, R9		; Add values
			push.w R2			; Store current state of flags in stack
			mov.b #0x20, R4		; Display result of operation
			call #OUTA_UART
			mov.b #0x52, R4
			call #OUTA_UART
			mov.b #0x3D, R4
			call #OUTA_UART

			mov.w R9, R11
			mov.w R9, R12
			mov.w R9, R13
			mov.w R9, R14

			call #DISPLAY

			mov.b #0x20, R4		; Display name of operation performed
			call #OUTA_UART
			mov.b #0x41, R4
			call #OUTA_UART
			mov.b #0x44, R4
			call #OUTA_UART
			call #OUTA_UART

			mov.b #0x20, R4
			call #OUTA_UART

			call #STATUS		; Diplay state of status flags in response to opertion performed

			call #NL
			jmp Mainloop		; Return to function select

S								; Start subtract program
			call #OUTA_UART		; Echo input to screen
			mov.b #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Input first hexadecimal character
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R8

			mov.w #0x20, R4
			call #OUTA_UART

			mov.b #0x00, R6		; Input second hexadecimal character
			mov.w #0x0000, R7
			call #SENDER2
			mov.w R7, R9

			sub.w R9, R8		; Subtract values
			push.w R2			; Store state of status flags in response to operation in stack
			mov.b #0x20, R4		; Display result of operation
			call #OUTA_UART
			mov.b #0x52, R4
			call #OUTA_UART
			mov.b #0x3D, R4
			call #OUTA_UART

			mov.w R8, R11
			mov.w R8, R12
			mov.w R8, R13
			mov.w R8, R14

			call #DISPLAY

			mov.b #0x20, R4		; Display name of operation performed
			call #OUTA_UART
			mov.b #0x53, R4
			call #OUTA_UART
			mov.b #0x55, R4
			call #OUTA_UART
			mov.b #0x42, R4
			call #OUTA_UART

			mov.b #0x20, R4
			call #OUTA_UART

			call #STATUS		; Display state of status flags in response to operation

			call #NL
			jmp Mainloop		; Return to function select

DISPLAY							; This function displays a 4 digit hexadecimal address to screen
			and.w #0xF000, R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			rra.w R11
			and.w #0x000F, R11
			mov.b R11, R4
			call #BOOST
			and.w #0x0F00, R12
			rra.w R12
			rra.w R12
			rra.w R12
			rra.w R12
			rra.w R12
			rra.w R12
			rra.w R12
			rra.w R12
			mov.b R12, R4
			call #BOOST
			and.w #0x00F0, R13
			rra.w R13
			rra.w R13
			rra.w R13
			rra.w R13
			mov.b R13, R4
			call #BOOST
			and.w #0x000F, R14
			mov.b R14, R4
			call #BOOST
			mov.b #0x20, R4
			call #OUTA_UART
			ret

FILTER							; Use this subroutine for diplaying the symbols represented by address words
			cmp.b #0x21, R4		; Make sure the value is within the proper range
			jl FILTERE			; Where the value is not within the range, use exit function
			cmp.b #0x7F, R4
			jge FILTERE
			call #OUTA_UART
			ret
FILTERE							; This is the exit subroutine for FILTER
			mov.b #0x2E, R4		; Display a period where an incompatible value is found
			call #OUTA_UART
			ret

BOOST							; This function takes hex values 0-F and converts them to ASCII equivalent symbols for display
			cmp.b #0x0A, R4		; Make sure the value is within hexadecimal range
			jge BOOSTC			; Where a letter must be used, move to BOOSTC
			add.b #0x30, R4		; Add hex value of 30 for 1-9
			call #OUTA_UART
			ret

BOOSTC
			cmp.b #0x10, R4		; Make sure value is within hexadecimal range
			jge BOOSTE			; Where the value is not in range, use exit function
			add.b #0x37, R4		; Add hex value of 37 for A-F
			call #OUTA_UART
			ret

BOOSTE							; Simple exit function for BOOST when value is not in range
			ret

STATUS							; Use this to display state of status flags in response to hex calculator operations
			pop.w R4			; Switch memory spots on stack
			pop.w R2
			push.w R4
			push.w R2
			mov.b #0x43, R4		; Display state of C flag
			call #OUTA_UART
			mov.b #0x3D, R4
			call #OUTA_UART
			pop.w R2
			jc Carry
			push.w R2
			mov.b #0x30, R4		; State of C flag is 0
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART
			jmp hold0
Carry
			push.w R2
			mov.b #0x31, R4		; State of C flag is 1
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART

hold0
			mov.b #0x5A, R4		; Display state of Z flag
			call #OUTA_UART
			mov.b #0x3D, R4
			call #OUTA_UART
			pop.w R2
			jz Zero
			push.w R2
			mov.b #0x30, R4		; State of Z flag is 0
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART
			jmp hold1
Zero
			push.w R2
			mov.b #0x31, R4		; State of Z flag is 1
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART
hold1
			mov.b #0x4E, R4		; Display state of N flag
			call #OUTA_UART
			mov.b #0x3D, R4
			call #OUTA_UART
			pop.w R2
			jn Neg
			push.w R2
			mov.b #0x30, R4		; State of N flag is 0
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART
			jmp hold2
Neg
			push.w R2
			mov.b #0x31, R4		; State of N flag is 1
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART
hold2
			mov.b #0x56, R4		; Display state of V flag
			call #OUTA_UART
			mov.b #0x3D, R4
			call #OUTA_UART
			pop.w R6
			and.w #0x0100, R6
			cmp.w #0x0100, R6
			jeq Vlow
			mov.b #0x30, R4		; State of V flag is 0
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART
			jmp hold3
Vlow
			mov.b #0x31, R4		; State of V flag is 1
			call #OUTA_UART
			mov.b #0x20, R4
			call #OUTA_UART
hold3
			ret

NL								; Function for implementing a new line when called
			mov.w #0x0d, R4
			call #OUTA_UART
			mov.w #0x0a, R4
			call #OUTA_UART
			ret

SUPPLEMENT						; Function for adding more spaces when need for Display Memory program
			sub.b R15, R8
CHECK
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			call #OUTA_UART
			dec.b R8
			cmp.b #0x00, R8
			jne CHECK
			jmp SEPARATOR1
SENDER2							; Function for acquiring a 4 digit hexadecimal number
			call #SENDER1		; Acquire the first two digits
			add.w R6, R7		; Add the two digits to the overall value
			mov.b #0x00, R6
			call #SENDER1		; Acquire the next two digits
			rla.w R7
			rla.w R7
			rla.w R7
			rla.w R7
			rla.w R7
			rla.w R7
			rla.w R7
			rla.w R7
			add.w R6, R7		; Merge values together
			ret

SENDER1							; Function for acquiring a 2 digit hexadecimal number

			call #INCHAR_UART	; Take in an ASCII value for a hex number
			call #CHAR2			; Convert ASCII value to hex number
			add.b R4, R6		; Add digit to overall value
			call #INCHAR_UART	; Take in second ASCII value for hex number
			call #CHAR2			; Conver ASCII value to hex number
			rla.b R6
			rla.b R6
			rla.b R6
			rla.b R6
			add.b R4, R6		; Combine digits into same value
			ret

CHAR2							; Function for detecting ASCII representations of hex numbers
			cmp.w #0x30, R4		; Make sure value is within range
			jl CHARNA			; Where value is not in range, use exit function
			cmp.w #0x3A, R4
			jge CHAR2A
			call #OUTA_UART
			sub #0x30, R4		; For symbols 30-39, subtract hex 30
			ret
CHAR2A
			cmp.w #0x41, R4
			jl CHARNA
			cmp.w #0x47, R4
			jge CHARNA
			call #OUTA_UART
			sub #0x37, R4		; For symbols 41-46, subtract hex 37
			ret
CHARNA
			call #INCHAR_UART	; This exit function asks for user to input value again
			jmp CHAR2			; Unless the values taken in are all hex, they will be repeatedly asked for input

OUTA_UART
;----------------------------------------------------------------
; prints to the screen the ASCII value stored in register 4 and
; uses register 5 as a temp value
;----------------------------------------------------------------
; IFG2 register (1) = 1 transmit buffer is empty,
; UCA0TXBUF 8 bit transmit buffer
; wait for the transmit buffer to be empty before sending the
; data out
			push R5
lpa 		mov.b &IFG2,R5
			and.b #0x02,R5
			cmp.b #0x00,R5
			jz lpa
; send the data to the transmit buffer UCA0TXBUF = A;
			mov.b R4,&UCA0TXBUF
			pop R5
			ret

INCHAR_UART
;----------------------------------------------------------------
; returns the ASCII value in register 4
;----------------------------------------------------------------
; IFG2 register (0) = 1 receive buffer is full,
; UCA0RXBUF 8 bit receive buffer
; wait for the receive buffer is full before getting the data
			push R5
lpb 		mov.b &IFG2,R5
			and.b #0x01,R5
			cmp.b #0x00,R5
			jz lpb
			mov.b &UCA0RXBUF,R4
			pop R5
; go get the char from the receive buffer
			ret

Init_UART
;----------------------------------------------------------------
; Initialization code to set up the uart on the experimenter board to 8 data,
; 1 stop, no parity, and 9600 baud, polling operation
;----------------------------------------------------------------
;---------------------------------------------------------------
; Set up the MSP430g2553 for a 1 MHZ clock speed
; For the version 1.5 of the launchpad MSP430g2553
; BCSCTL1=CALBC1_1MHZ;
; DCOCTL=CALDCO_1MHZ;
; CALDCO_1MHZ and CALBC1_1MHZ is the location in the MSP430g2553
; so that the for MSP430 will run at 1 MHZ.
; give in the *.cmd file
; CALDCO_1MHZ        = 0x10FE;
; CALBC1_1MHZ        = 0x10FF;
			mov.b &CALBC1_1MHZ, &BCSCTL1
			mov.b &CALDCO_1MHZ, &DCOCTL
;--------------------------------------------------------------
; Set up the MSP430g2553 for 1.2 for the transmit pin and 1.1 receive pin
; For the version 1.5 of the launchpad MSP430g2553
; Need to connect the UART to port 1.
; 00 = P1SEL, P1sel2 = off, 01 = primary I/O, 10 = Reserved, 11 = secondary I/O for UART
; P1SEL =  0x06;    // transmit and receive to port 1 bits 1 and 2
; P1SEL2 = 0x06;   // transmit and receive to port 1 bits 1 and 2
;---------------------------------------------------------------
			mov.b #0x06,&P1SEL
			mov.b #0x06,&P1SEL2
; Bits p2.4 transmit and p2.5 receive UCA0CTL0=0
; 8 data, no parity 1 stop, uart, async
			mov.b #0x00,&UCA0CTL0
; (7)=1 (parity), (6)=1 Even, (5)= 0 lsb first,
; (4)= 0 8 data / 1 7 data, (3) 0 1 stop 1 / 2 stop, (2-1) --
; UART mode, (0) 0 = async
; select MLK set to 1 MHZ and put in software reset the UART
; (7-6) 00 UCLK, 01 ACLK (32768 hz), 10 SMCLK, 11 SMCLK
; (0) = 1 reset
; UCA0CTL1= 0x81;
			mov.b #0x81,&UCA0CTL1
; UCA0BR1=0;
; upper byte of divider clock word
			mov.b #0x00,&UCA0BR1
; UCA0BR0=68; ;
; clock divide from a MLK of 1 MHZ to a bit clock of 9600 -> 1MHZ /
; 9600 = 104.16 104 =0x68
			mov.b #0x68,&UCA0BR0
; UCA0BR1:UCA0BR0 two 8 bit reg to from 16 bit clock divider
; for the baud rate
; UCA0MCTL=0x06;
; low frequency mode module 3 modulation pater used for the bit
; clock
			mov.b #0x06,&UCA0MCTL
; UCA0STAT=0;
; do not loop the transmitter back to the receiver for echoing
			mov.b #0x00,&UCA0STAT
; (7) = 1 echo back trans to rec
; (6) = 1 framing, (5) = 1 overrun, (4) =1 Parity, (3) = 1 break
; (0) = 2 transmitting or receiving data
;UCA0CTL1=0x80;
; take UART out of reset
			mov.b #0x80,&UCA0CTL1
;IE2=0;
; turn transmit interrupts off
			mov.b #0x00,&IE2
; (0) = 1 receiver buffer Interrupts enabled
; (1) = 1 transmit buffer Interrupts enabled
;----------------------------------------------------------------
;****************************************************************
;----------------------------------------------------------------
; IFG2 register (0) = 1 receiver buffer is full, UCA0RXIFG
; IFG2 register (1) = 1 transmit buffer is empty, UCA0RXIFG
; UCA0RXBUF 8 bit receiver buffer, UCA0TXBUF 8 bit transmit
; buffer
			ret

;----------------------------------------------------------------
; Interrupt Vectors
;----------------------------------------------------------------
			.sect ".reset" ; MSP430 RESET Vector
			.short STRT
			.end
