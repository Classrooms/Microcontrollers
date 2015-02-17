; *******************************************************************
; Lesson 1 - "Hello World"
;
; The LEDs are connected to input-outpins (I/O) RC0 through RC3. First, the I/O pin
; must be configured for an output. In this case, when one of these pins is driven high
; (RC0 =  1 ), the LED will turn on. These two logic levels are derived from the power pins
; of the PIC MCU. Since the PIC device?s power pin (VDD) is connected to 5V and the
; source (VSS) to ground (0V), a ? 1 ? is equivalent to 5V, and a ?0 ? is 0V.
;
;
; This turns on DS1 LED on the Low Pin Count Demo Board.
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

    #include <p16F1829.inc>                    ;for PIC specific registers. This links register names to their
                                           ;respective addresses and banks
     __CONFIG _CONFIG1, (_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF);
     __CONFIG _CONFIG2, (_WRT_OFF & _PLLEN_OFF & _STVREN_OFF & _LVP_OFF);

    errorlevel -302                        ;supress the 'not in bank0' warning

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

    ORG 0
Start:
     banksel        TRISC                  ;select bank1
     bcf            TRISC,0                ;make IO Pin, C0, an output
     banksel        LATC                   ;select bank2
     clrf           LATC                   ;inititilize the LATCH by turning off everything
     bsf            LATC,0                 ;turn on LED C0 (DS1)
     goto           $                      ;sit here forever!

    end