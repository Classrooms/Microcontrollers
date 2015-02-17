; *******************************************************************
; Lesson 5 - "Variable Speed Rotate"
;
; This lesson combines all of the previous lessons to produce a variable speed rotating
; LED display that is proportional to the ADC value. The ADC value and LED rotate
; speed are inversely proportional to each other.
;
; Rotate the POT counterclockwise to see the LEDs shift faster.
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


    ORG 0                               ;start of code
Start:
                                        ;Setup main init
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed
     movwf          OSCCON              ;move contents of the working register into OSCCON

                                        ;Configure the ADC/Potentimator
                                        ;already in bank1
     bsf            TRISA, 4            ;Potentimator is connected to RA4....set as input
     movlw          b'00001101'         ;select RA4 as source of ADC and enable the module (carefull, this is actually AN3)
     movwf          ADCON0
     movlw          b'00010000'         ;left justified - Fosc/8 speed - vref is Vdd
     movwf          ADCON1
     banksel        ANSELA              ;bank3
     bsf            ANSELA, 4            ;analog for ADC

     ;Configure the LEDs
     banksel        TRISC		;bank1
     clrf           TRISC               ;make all of PORTC an output
     banksel        LATC                ;bank2
     movlw          b'00001000'         ;start the rotation by setting DS4 ON
     movwf          LATC                ;write contents of the working register to the latch
MainLoop:
     call           A2d                 ;get the ADC result
                                        ;top 8 MSbs are now in the working register (Wreg)
     movwf          Delay2              ;move ADC result into the outer delay loop
     call           CheckIfZero         ;if ADC result is zero, load in a value of '1' or else the delay loop will decrement starting at 255
     call           DelayLoop           ;delay the next LED from turning ON
     call           Rotate              ;rotate the LEDs

     bra            MainLoop            ;do this forever

CheckIfZero:
     movlw          d'0'                ;load wreg with '0'
     xorwf          Delay2, w           ;XOR wreg with the ADC result and save in wreg
     btfss          STATUS, Z           ;if the ADC result is NOT '0', then simply return to MainLoop
     return                             ;return to MainLoop
     movlw          d'1'                ;ADC result IS '0'. Load delay routine with a '1' to avoid decrementing a rollover value of 255
     movwf          Delay2              ;move it into the delay location in shared memory (RAM)
     return                             ;return to MainLoop

A2d:
    ;Start the ADC
    nop                                 ;requried ADC delay of 8uS => (1/(Fosc/4)) = (1/(500KHz/4)) = 8uS
    banksel         ADCON0
    bsf             ADCON0, GO          ;start the ADC
    btfsc           ADCON0, GO          ;this bit will be cleared when the conversion is complete
    goto            $-1                 ;keep checking the above line until GO bit is clear
    movf            ADRESH, w           ;Get the top 8 MSbs (remember that the ADC result is LEFT justified!)

    return      

DelayLoop:
                                        ;Delay amount is determined by the value of the ADC
    decfsz         Delay1,f             ;will always be decrementing 255 here
    goto           DelayLoop            ;The Inner loop takes 3 instructions per loop * 255 loops (required delay)
    decfsz         Delay2,f             ;The outer loop takes and additional 3 instructions per lap * X loops (X = top 8 MSbs from ADC conversion)
    goto           DelayLoop

    return

Rotate:
    banksel        LATC                 ;change to Bank2
    lsrf           LATC                 ;logical shift right
    btfsc          STATUS,C             ;did the bit rotate into the carry?
    bsf            LATC,3               ;yes, put it into bit 3.

    return

    end                                 ;end code