; *******************************************************************
; Lesson 9 - Timer0
;
; Timer0 is a counter implemented in the processor. It may be used to count instruction
; cycles or external events, that occur at or below the instruction cycle rate.
; In the PIC18, Timer0 can be used as either an 8-bit or 16-bit counter, or timer. The
; enhanced mid-range core implements only an 8-bit counter.
; This lesson configures Timer0 to count instruction cycles and to set a flag when it rolls
; over. This frees up the processor to do meaningful work rather than wasting instruction
; cycles in a timing loop.
; Using a counter provides a convenient method of measuring time or delay loops as it
; allows the processor to work on other tasks rather than counting instruction cycles.
;
;
; LEDs rotate from right to left, similar to Lesson 3, at a rate of ~.5 seconds.
;
; PIC: 16F1829
; Assembler: MPASM v5.43
; IDE: MPLABX v1.10
;
; Board: PICkit 3 Low Pin Count Demo Board
; Date: 6.1.2012
;
;
; *******************************************************************
; * See Low Pin Count Demo Board User's Guide for Lesson Information*
; *******************************************************************

#include <p16F1829.inc>
     __CONFIG _CONFIG1, (_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF);
     __CONFIG _CONFIG2, (_WRT_OFF & _PLLEN_OFF & _STVREN_OFF & _LVP_OFF);

     errorlevel -302                    ;surpress the 'not in bank0' warning

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

     Org 0
Start:
                                        ;Setup main init
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed to 500KHz
     movwf          OSCCON              ;move contents of the working register into OSCCON

                                        ;Configure the LEDs
     banksel        TRISC               ;bank1
     clrf           TRISC               ;make all of PORTC an output
     banksel        LATC                ;bank2
     movlw          b'00001000'         ;start with DS4 lit
     movwf          LATC

                                        ;Setup Timer0
     banksel        OPTION_REG          ;bank1
     movlw          b'00000111'         ;1:256 prescaler for a delay of: (insruction-cycle * 256-counts)*prescaler = ((8uS * 256)*256) =~ 524mS
     movwf          OPTION_REG

MainLoop:
    btfss           INTCON, TMR0IF      ;did TMR0 roll over yet?
    bra             $-1                 ;wait until TMR0 overflows and sets TMR0IF
    bcf             INTCON, TMR0IF      ;must clear flag in software

                                        ;rotate the LEDs
    banksel         LATC                ;bank2
    lsrf            LATC, f
    btfsc           STATUS,C            ;did the bit rotate into the carry?
    bsf             LATC,3              ;yes, put light DS4 back up

    bra             MainLoop            ;continue forever

    end
