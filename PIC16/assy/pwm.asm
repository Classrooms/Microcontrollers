; *******************************************************************
; Lesson 8 - PWM
;
; Pulse-Width Modulation (PWM) is a scheme that provides power to a load by switching
; quickly between fully on and fully off states. The PWM signal resembles a square wave
; where the high portion of the signal is considered the on state and the low portion of
; the signal is considered the off state. The high portion, also known as the pulse width,
; can vary in time and is defined in steps. A longer, high on time will illuminate the LED
; brighter. The frequency or period of the PWM does not change. A larger number of
; steps applied, which lengthens the pulse width, also supplies more power to the load.
; Lowering the number of steps applied, which shortens the pulse width, supplies less
; power. The PWM period is defined as the duration of one complete cycle or the total
; amount of on and off time combined.
;
; Rotating the POT will adjust the brightness of a single LED, DS4
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
     banksel        LATC                ;bank3
     clrf           LATC


                                        ;Configure the PWM module
     banksel        CCP2CON             ;bank 5 - use CCP2
     movlw          b'00001100'         ;PWM mode - single output
     movwf          CCP2CON
     movlw          b'00000000'         ;select timer2 as PWM source
     movwf          CCPTMRS
     banksel        PR2                 ;bank0
     movlw          0xFF                ;Frequency at 488Hz. Anything over ~60Hz will get rid of any flicker
     movwf          PR2                 ;PWM Period = [PR2 + 1]*4*Tosc*T2CKPS = [50 + 1] * 4 * (1 / 500KHz) * 1
     clrf           T2CON               ;1:1 postscaler and 1 prescaler
     bsf            T2CON,TMR2ON        ;start the PWM by setting TMR2ON bit
MainLoop:
    call            A2d                 ;begin the Analog to Digital conversion

                                        ;ADRESH and ADRESL are now both full of the ADC result!
                                        ;already in bank0 from the banksel inside of A2d
    movf            ADRESH, w           ;Get the top 8 MSbs (remember that the ADC result is LEFT justified!)
    banksel         CCPR2L
    movwf           CCPR2L
    
                                        ;to fill the 10bit PWM registers, these 2 LSBS will be put into the
                                        ;Duty Cycle Bits (DC2B) of the CCP2CON register which are bits 5 and 4.
                                        ;So we need to shift these LSb into place and OR them with CCP2CON
                                        ; in order to save the settings above and fill these last bits in
    banksel         ADRESL
                                        ;ADRESL =  b'xx000000' where 'xx' are the 2 LSBs from the ADC result
    lsrf            ADRESL, f           ;ADRESL = b'0xx00000'
    lsrf            ADRESL, f           ;ADRESL = b'00xx0000'
    movf            ADRESL, w           ;now move into wreg
    banksel         CCP2CON
	
                                        ;move the 2 LSBs into place without disturbing the rest of CCP2CON settings
    xorwf           CCP2CON, w	;clears bits that are the same and sets bits that are different.
    andlw           B'00110000'	;clears all control bits in WREG so they don't change in the final step
    xorwf           CCP2CON, f          ;changes bits that changed and leaves everything else untouched.
    bra             MainLoop            ;do this forever


A2d:
                                        ;Start the ADC
    nop                                 ;requried ADC delay of 8uS => (1/(Fosc/4)) = (1/(500KHz/4)) = 8uS
    banksel         ADCON0
    bsf             ADCON0, GO          ;start the ADC
    btfsc           ADCON0, GO          ;this bit will be cleared when the conversion is complete
    goto            $-1                 ;keep checking the above line until GO bit is clear

    return

    end