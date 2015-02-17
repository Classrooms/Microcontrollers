; *******************************************************************
; Lesson 13 - EEPROM
;
; This lesson will provide code for writing and reading a single byte onto
; the on-board EEPROM. EEPROM is non-volatile memory, meaning that it does
; not lose its value when power is shut off. This is unlike RAM, which will
; lose its value when no power is applied. The EEPROM is useful for storing
; variables that must still be present during no power.
; It is also convenient to use if the entire RAM space is used up.
; Writes and reads to the EEPROM are practically instant and are much faster
; than program memory operations.

; Press the switch to save the LED state and then disconnect the power. When
; power is then applied again, the program will start with that same LED lit.

; When the lesson is first programmed, no LEDs will light up even with movement
; of the POT. When the switch is pressed, the corresponding LED will be lit and
; then the PIC will go to sleep until the switch is pressed again. Each press of
; the switch saves the ADC value into EEPROM. The PIC uses interrupts to wake up
; from sleep, take an ADC reading, save to EEPROM, and then goes back to sleep.
;
; PIC: 16F1829
; Assembler: MPASM V5.43
; IDE: MPLABX v1.0
;
; Hardware: PICkit3 Low Pin Count Demo Board
; Date: 12.2011
;
; *******************************************************************
; * See Low Pin Count Demo Board User's Guide for Lesson Information*
; *******************************************************************

#include <p16F1829.inc>
     __CONFIG _CONFIG1, (_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF);
     __CONFIG _CONFIG2, (_WRT_OFF & _PLLEN_OFF & _STVREN_OFF & _LVP_OFF);

    errorlevel -302                     ;surpress the 'not in bank0' warning

#define     DOWN    0x00                ;when SW1 is pressed, the voltage is pulled down through R3 to ground (GND)
#define     UP      0xFF                ;when SW1 is not pressed, the voltage is pulled up through R1 to Power (Vdd)
#define     EEPROM_ADDR 0x00            ;read from the start of EEPROM where the ADC value will be saved
#define     SWITCH  PORTA, 2            ;pin where SW1 is connected..NOTE: always READ from the PORT and WRITE to the LATCH

    cblock 0x70                         ;shared memory location that is accessible from all banks
Delay1
     endc

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

     Org 0x0000                         ;Reset Vector starts at 0x0000
     bra        Start                   ;main code execution
     Org 0x0004                         ;ISR Vector starts at 0x04
     bra        ISR

Start:
                                        ;Setup main init
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed of 500KHz
     movwf          OSCCON              ;move contents of the working register into OSCCON

                                        ;Configure the LEDs
     clrf           TRISC               ;make all of PORTC an output
     banksel        LATC                ;bank2
     movlw          b'00001000'         ;start with DS4 lit

                                        ;Configure the ADC/Potentimator
     banksel        TRISA               ;bank1
     bsf            TRISA, 4            ;Potentimator is connected to RA4....set as input
     movlw          b'00001101'         ;select RA4 as source of ADC and enable the module (carefull, this is actually AN3)
     movwf          ADCON0
     movlw          b'00010000'         ;left justified - Fosc/8 speed - vref is Vdd
     movwf          ADCON1
     banksel        ANSELA              ;bank3
     bsf            ANSELA, 4           ;analog for ADC

                                        ;Setup SW1 as digital input
     banksel        TRISA               ;bank1
     bsf            TRISA, RA2          ;switch as input
     banksel        ANSELA              ;bank3
     bcf            ANSELA, RA2         ;digital
                                        ;can reference pins by their position in the PORT (2) or name (RA2)


     ;Setup interrupt-on-change for the switch
     bsf            INTCON, IOCIE       ;must set this global enable flag to allow any interrupt-on-change flags to cuase an interrupt
     banksel        IOCAN               ;bank7
     bsf            IOCAN,  IOCAN2      ;when SW1 is pressed, enter the ISR (Note, this is set when a FALLING EDGE is detected)
     bsf            INTCON, GIE         ;must set this global to allow any interrupt to bring the program into the ISR
                                        ;if this is not set, the interrupt flags will still get set, but the ISR will never be entered

    movlw           EEPROM_ADDR         ;read from the first byte where the previous ADC value was saved
    call            EERead              ;read the first byte of EEPROM
    banksel         LATC                ;bank2
    movwf           LATC                ;move ADC result into the LEDs
MainLoop:
    SLEEP                               ;sleep until SW1 is pressed/released
                                        ;The PIC will wake up and immediately enter the ISR when RABIF
                                        ;is set. This will happen with either a rising or falling edge is
                                        ;detected on RA3, or rather SW1
    bra             MainLoop

EERead:
    banksel         EEADRL              ;bank3
    movwf           EEADRL              ;address is in wreg
    bcf             EECON1, EEPGD       ;point to DATA memory
    bcf             EECON1, CFGS        ;access EEPROM
    bsf             EECON1, RD          ;EEPROM read
    movf            EEDATL, w           ;save in wreg
    return                              ;return to MainLoop with answer in wreg

A2d:
                                        ;Start the ADC
    nop                                 ;requried ADC delay of 8uS => (1/(Fosc/4)) = (1/(500KHz/4)) = 8uS
    banksel         ADCON0              ;bank1
    bsf             ADCON0, GO          ;start the ADC
    btfsc           ADCON0, GO          ;this bit will be cleared when the conversion is complete
    goto            $-1                 ;keep checking the above line until GO bit is clear
    swapf           ADRESH, w           ;only save the high nibble
    return
Debounce:
                                        ;delay for approximatly 5ms
    movlw           d'209'              ;(1/(500KHz/4))*209*3 = 5.016mS
    movwf           Delay1
DebounceLoop:
    decfsz          Delay1, f           ;1 instruction to decrement,unless if branching (ie Delay1 = 0)
    bra             DebounceLoop        ;2 instructions to branch

    banksel         PORTA               ;bank0
    btfsc           SWITCH              ;check if switch is still down.
    retfie                              ;exit without doing anything
    call            A2d                 ;Get here if switch is still held down - get the current ADC value
    banksel         LATC                ;bank2
    movwf           LATC                ;display result on the LEDs

                                        ;Writes one byte to EEPROM at EEPROM_ADDR
EEWrite:
    banksel         EEADRL              ;bank3
    movwf           EEDATL              ;move the ADC result into EEDATA (previously saved in wreg)
    movlw           EEPROM_ADDR         ;move the address into wreg
    movwf           EEADRL              ;indicates where to write
    bcf             EECON1, EEPGD       ;point to DATA memory
    bcf             EECON1, CFGS        ;access EEPROM
    bsf             EECON1, WREN        ;enable writes
    bcf             INTCON, GIE         ;ALWAYS disable interrupts before writting to EEPROM!!
                                        ;NOTE: While inside the ISR, GIE will be cleared in hardware automatically, so the above line is not
                                        ;necessary, although it is good practice to always do this anyways. GIE will be set in hardware (if
                                        ;enabled previously) after the ISR is exited

                                        ;REQUIRED SEQUENCE
    movlw           0x55
    movwf           EECON2
    movlw           0xAA
    movwf           EECON2
    bsf             EECON1, WR          ;begin write
                                        ;END REQUIRED SEQUENCE

    bcf             EECON1, WREN        ;disable writes
    btfsc           EECON1, WR          ;wait for write to be complete
    bra             $-1
    bsf             INTCON, GIE         ;re-enable interrupts

    return                              ;return to 'Service_SW1' label


ISR:
    banksel         IOCAF               ;bank7
    btfsc           IOCAF, 2            ;check for IOC flag for switch
    bra             Service_SW1
    retfie                              ;nope, exit ISR

Service_SW1:
    bcf             INTCON, IOCIF
    clrf            IOCAF               ;MUST ALWAYS clear this in software or else stuck in the ISR forever
    call            Debounce            ;delay for 5ms and then check the switch again
    retfie

    end                                 ;end code