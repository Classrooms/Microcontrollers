; *******************************************************************
; Lesson 7 - Reversible LEDs
;
; This lesson combines all of the previous lessons in using the button to reverse the 
; direction of rotation when the button is pressed. The speed of rotation is controlled 
; using the potentiometer.
;
; The program needs to keep track of rotation direction and new code needs to be added
; to rotate in the other direction. Lesson 5 rotates right and checks for a '1' in the carry
; bit to determine when to restart the sequence. In Lesson 7, the program needs to rotate
; both ways and check for a '1' in bit 4 of the display when rotating to the left. When the
; '1' shows up in bit 4 of LATC, it will be re-inserted into bit  0 .
;
; The debounce routine is more in-depth in this lesson because we need to keep in mind
; of the scenario of the switch being held down for long periods of time. If SW1 is held
; down, the LEDs would change direction rapidly, making the display look like it is out of
; control. The above flowchart will only change direction on the first indication of a solid
; press and then ignore the switch until it is released and pushed again. The switch must
; be pressed for at least the time it takes for the program to check the switch in its loop.
; Since the PIC MCU is running at 500 kHz, this will seem instantaneous.
;
; LEDs will rotate at a speed that is proportional to the ADC value. The switch will toggle
; the direction of the LEDs
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

#define     DOWN    0x00                ;when SW1 is pressed, the voltage is pulled down through R3 to ground (GND)
#define     UP      0xFF                ;when SW1 is not pressed, the voltage is pulled up through R1 to Power (Vdd)
#define     SWITCH  PORTA, 2            ;pin where SW1 is connected..NOTE: always READ from the PORT and WRITE to the LATCH

#define     LED_RIGHT   1               ;keep track of LED direction
#define     LED_LEFT    0

    errorlevel -302                     ;surpress the 'not in bank0' warning

    cblock 0x70                         ;shared memory location that is accessible from all banks
Delay1                                  ;delay loop for debounce and LED delay
Delay2                                  ;delay loop for LED delay
Direction                               ;either 1 or 0 depending on what direction LEDs are going
Previous_Direction                      ;don't keep toggling the direction if the switch is held down
     endc

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------


     ORG 0                              ;start of code
Start:
                                        ;Setup main init
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed of 500KHz
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

                                        ;Setup SW1 as digital input
     banksel        TRISA               ;bank1
     bsf            TRISA, RA2          ;switch as input
     banksel        ANSELA              ;bank3
     bcf            ANSELA, RA2         ;digital
                                        ;can reference pins by their position in the PORT (2) or name (RA2)

                                        ;Configure the LEDs
     banksel        TRISC               ;bank1
     clrf           TRISC               ;make all of PORTC an output
     banksel        LATC                ;bank2
     movlw          b'00001000'         ;start with  DS1 ON
     movwf          LATC

     movlw          LED_RIGHT           ;start with LEDs shifting to the right
     movwf          Direction

     ;Clear the RAM
     clrf           Previous_Direction
     clrf           Delay1
     clrf           Delay2

MainLoop:

     call           A2d                 ;get the ADC result
                                        ;top 8 MSbs are now in the working register (Wreg)
     movwf          Delay2              ;move ADC result into the outer delay loop
     call           CheckIfZero         ;if ADC result is zero, load in a value of '1' or else the delay loop will decrement starting at 255
     call           DelayLoop           ;delay the next LED from turning ON
     call           Debounce            ;check if SW1 was pressed
     call           Rotate              ;rotate the LEDs

     bra            MainLoop            ;do this forever


Debounce:
    banksel         PORTA               ;bank0
    btfsc           SWITCH              ;check if switch is down
    bra             SwitchNotDown
                                        ;delay for approximatly 5ms
    movlw           d'209'              ;(1/(500KHz/4))*209*3 = 5.016mS
    movwf           Delay1
DebounceLoop:
    decfsz          Delay1, f           ;1 instruction to decrement,unless if branching (ie Delay1 = 0)
    bra             DebounceLoop        ;2 instructions to branch

                                        ;no need to bank again...already in PORTA bank from above
    btfsc           SWITCH              ;check if switch is still down.
    bra             SwitchNotDown       ;failed the debounce test
ToggleDirection:                        ;switch is still down, toggle LED direction if previous direction != current direction
    movlw           DOWN                ;load wreg with '0'
    subwf           Previous_Direction, w  ;exit if SW1 was held down
    btfsc           STATUS, Z
    return                              ;exit with no toggling of LED direction

    movlw           0xFF                ;get here if button was just pressed
    xorwf           Direction, f        ;toggle direction states by using the XOR instruction and saving in RAM
    movlw           DOWN
    movwf           Previous_Direction  ;don't enter here again until switch is released and then pressed again
    return
SwitchNotDown:
    movlw           UP                  ;move 0xFF into wreg
    movwf           Previous_Direction
    return                              ;return back to the MainLoop where 'Debounce' was called

CheckIfZero:
     movlw          d'0'                ;load wreg with '0'
     subwf          Delay2, w           ;subtract wreg with the ADC result and save in wreg
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
     decfsz         Delay1,f            ;will always be decrementing 255 here
     goto           DelayLoop           ;The Inner loop takes 3 instructions per loop * 255 loops (required delay)
     decfsz         Delay2,f            ;The outer loop takes and additional 3 instructions per lap * X loops (X = top 8 MSbs from ADC conversion)
     goto           DelayLoop

     return

Rotate:
     banksel        LATC                ;change to Bank2
     movlw          LED_RIGHT           ;check what direction currently in
     subwf          Direction, w        ;be sure to save in wreg so as to not corrupt 'Direction'
     btfsc          STATUS, Z
     bra            RotateRight         ;rotating right
     bra            RotateLeft


RotateRight:
     lsrf           LATC, f             ;logical shift right
     btfsc          STATUS,C            ;did the bit rotate into the carry?
     bsf            LATC,3              ;yes, put it into bit 3.
     bra            MainLoop
RotateLeft:
     lslf           LATC, f             ;logical shift left
     btfsc          LATC, 4             ;did it rotate out of the LED display?
     bsf            LATC, 0             ;yes, put in bit 0
     bra            MainLoop

     end                                ;end code