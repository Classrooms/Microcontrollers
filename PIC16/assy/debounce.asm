; *******************************************************************
; Lesson 6 - Switch Debounce
;
; This lesson uses a simple software delay routine to avoid the initial noise on the switch 
; pin. The code will delay for only 5 ms, but should overcome most of the noise. The 
; required delay amount differs with the switch being used. Some switches are worse 
; than others.

; This lesson also introduces the  #define preprocessing symbol in both ?C? and assem-bly. 
; Hard coding pin locations is bad practice. Values that may be changed in the future 
; should always be defined once in preprocessing. Imagine if another user wanted to use 
; these lessons in a different PIC device and all of the pins changed! This would require 
; going into the code and finding every instance of any pin reference.

; When the switch is held down, DS1 will be lit. When the switch is not held down, all
; LEDs are OFF.
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

;#define     DOWN    0                  ;when SW1 is pressed, the voltage is pulled down through R3 to ground (GND)
;#define     UP      1                  ;when SW1 is not pressed, the voltage is pulled up through R1 to Power (Vdd)

#define     SWITCH  PORTA, 2            ;pin where SW1 is connected..NOTE: always READ from the PORT and WRITE to the LATCH
#define     LED     LATC, 0             ;DS1

    errorlevel -302                     ;surpress the 'not in bank0' warning

    cblock 0x70                         ;shared memory location that is accessible from all banks
Delay1                                  ;delay loop for debounce
     endc

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

    ORG 0                              ;start of code
Start:
                                        ;Setup main init
    banksel         OSCCON              ;bank1
    movlw           b'00111000'         ;set cpu clock speed to 500KHz
    movwf           OSCCON              ;move contents of the working register into OSCCON
                                        ;Setup SW1 as digital input
    bsf             TRISA, RA2          ;switch as input
    banksel         ANSELA              ;bank3
    bcf             ANSELA, RA2         ;digital
                                        ;can reference pins by their position in the PORT (2) or name (RA2)

                                        ;Configure the LEDs
    banksel         TRISC               ;bank1
    clrf            TRISC               ;make all of PORTC an output
    banksel         LATC                ;bank2
    clrf            LATC                ;start with all LEDs off
MainLoop:
    banksel         PORTA               ;get into Bank0
    btfsc           SWITCH              ;defined above....notice how the PORT is being read and not the LATCH
    bra             LedOff              ;switch is not pressed - turn OFF the LED
    bra             Debounce            ;switch is held down, pin needs to be debounced

LedOn:
    banksel         LATC                ;get into Bank2
    bsf             LED                 ;turn ON the LED
    bra             MainLoop            ;go back to MainLoop
LedOff:
    banksel         LATC                ;get into Bank2
    bcf             LED                 ;turn OFF the LED
    bra             MainLoop            ;go back to MainLoop

Debounce:
                                        ;delay for approximatly 5ms
    movlw           d'209'              ;(1/(500KHz/4))*209*3 = 5.016mS
    movwf           Delay1
DebounceLoop:
    decfsz          Delay1, f           ;1 instruction to decrement,unless if branching (ie Delay1 = 0)
    bra             DebounceLoop        ;2 instructions to branch

    banksel         PORTA               ;bank0
    btfss           SWITCH              ;check if switch is still down. If not, skip the next instruction and simply return to MainLoop
    bra             LedOn               ;switch is still down, turn on the LED
    bra             MainLoop
    
    end                                 ;end code