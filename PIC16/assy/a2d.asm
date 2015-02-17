; *******************************************************************
; Lesson 4 - "Analog to Digital"
;
; This shows how to read the A2D converter and display the
; High order parts on the 4 bit LED display.
; The pot on the Low Pin Count Demo board varies the voltage
; coming in on in A0.
;
; The A2D is referenced to the same Vdd as the device, which
; is nominally is 5V.  The A2D returns the ratio of the voltage
; on Pin RA0 to 5V.  The A2D has a resolution of 10 bits, with 1024 
; representing 5V and 0 representing 0V.
;
;
; The top four MSbs of the ADC are mirrored onto the LEDs. Rotate the potentiometer
; to change the display.
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

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------


    ORG 0                               ;start of code at address 0x0000
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
     bsf            ANSELA, 4           ;analog for ADC

                                        ;Configure the LEDs
     banksel        TRISC               ;bank1
     clrf           TRISC               ;make all of PORTC an output
     banksel        LATC                ;select the bank where LATC is
     movlw          b'00001000'         ;start the rotation by setting DS1 ON
     movwf          LATC                ;write contents of the working register to the latch
MainLoop:
                                        ;Start the ADC
    nop                                 ;requried ADC delay of 8uS => (1/(Fosc/4)) = (1/(500KHz/4)) = 8uS
    banksel         ADCON0
    bsf             ADCON0, GO          ;start the ADC
    btfsc           ADCON0, GO          ;this bit will be cleared when the conversion is complete
    goto            $-1                 ;keep checking the above line until GO bit is clear

                                        ;Grab Results and write to the LEDs
    swapf           ADRESH, w           ;Get the top 4 MSbs (remember that the ADC result is LEFT justified!)
    banksel         LATC
    movwf           LATC                ;move into the LEDs
    bra             MainLoop

    end                                 ;end code