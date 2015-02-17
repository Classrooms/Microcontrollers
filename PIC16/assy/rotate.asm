; *******************************************************************
; Lesson 3 - "Rotate"
;
; This lesson will introduce shifting instructions as well as bit-oriented skip operations to
; move the LED display.
;
; LEDs rotate from right to left at a rate of 1.5s
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
Delay1                                  ;define two file registers for the delay loop in shared memory
Delay2
     endc

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

    ORG 0                               ;start of code
Start:
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed of 500KHz
     movwf          OSCCON              ;move contents of the working register into OSCCON
     clrf           TRISC               ;make all of PORTC an output
     banksel        LATC                ;select the bank where LATC is (bank2)
     movlw          b'00001000'         ;start the rotation by setting DS4 ON
     movwf          LATC                ;write contents of the working register to the latch
MainLoop:
OndelayLoop:
     decfsz         Delay1,f            ;Waste time.
     goto           OndelayLoop         ;The Inner loop takes 3 instructions per loop * 256 loopss = 768 instructions
     decfsz         Delay2,f            ;The outer loop takes an additional 3 instructions per lap * 256 loops
     goto           OndelayLoop         ;(768+3) * 256 = 197376 instructions / 125K instructions per second = 1.579 sec.

Rotate:
    lsrf            LATC,F              ;shift the LEDs and turn on the next LED to the right
    btfsc           STATUS,C            ;did the bit rotate into the carry (i.e. was DS1 just lit?)
    bsf             LATC, 3             ;yes, it did and now start the sequence over again by turning on DS4
    goto            MainLoop            ;repeat this program forever

    end                                 ;end code section