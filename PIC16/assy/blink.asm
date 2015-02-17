; *******************************************************************
; Lesson 2 - "Blink"
;
; One way to create a delay is to spend time decrementing a value. In assembly, the timing
; can be accurately programmed since the user will have direct control on how the
; code is executed. In ?C?, the compiler takes the ?C? and compiles it into assembly before
; creating the file to program to the actual PIC MCU (HEX file). Because of this, it is hard
; to predict exactly how many instructions it takes for a line of ?C? to execute.
;
;
; DS1 blinks at a rate of approximately 1.5 seconds.
;
;
; PIC: 16F1829
; Assembler: MPASM v5.43
; IDE: MPLABX v1.10
;
; Board: PICkit 3 Low Pin Count Demo Board
; Date: 6.1.2012
;
; *******************************************************************
; * See Low Pin Count Demo Board User's Guide for Lesson Information*
; *******************************************************************

    #include <p16F1829.inc>

     __CONFIG _CONFIG1, (_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF);
     __CONFIG _CONFIG2, (_WRT_OFF & _PLLEN_OFF & _STVREN_OFF & _LVP_OFF);

    errorlevel -302                     ;supress the 'not in bank0' warning
    cblock 0x70                         ;shared memory location that is accessible from all banks
Delay1                                  ;Define two file registers for the delay loop in shared memory
Delay2         
     endc

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

    ORG 0
Start:
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed of 500KHz ->correlates to (1/(500K/4)) for each instruction
     movwf          OSCCON              ;move contents of the working register into OSCCON
     bcf            TRISC,0             ;make IO Pin C0 an output for DS1
     banksel        LATC                ;bank2
     clrf           LATC                ;start by turning off all of the LEDs
MainLoop:
    bsf             LATC, 0             ;turn on DS1
     
OndelayLoop:
     decfsz         Delay1,f            ;Waste time.
     bra            OndelayLoop         ;The Inner loop takes 3 instructions per loop * 256 loops = 768 instructions
     decfsz         Delay2,f            ;The outer loop takes an additional 3 instructions per lap * 256 loops
     bra            OndelayLoop         ;(768+3) * 256 = 197376 instructions / 125K instructions per second = 1.579 sec.
     bcf            LATC,0              ;Turn off LED C0 - NOTE: do not need to switch banks with 'banksel' since bank2 is still selected
OffDelayLoop:
     decfsz         Delay1,f            ;same delay as above
     bra            OffDelayLoop
     decfsz         Delay2,f
     bra            OffDelayLoop
     bra            MainLoop            ;Do it again...

     end