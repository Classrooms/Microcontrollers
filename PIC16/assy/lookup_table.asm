; *******************************************************************
; Lesson 12 - Table lookup
;
; This shows using a table lookup function to implement a
; binary to gray code conversion.  The POT is read by the A2D,
; The high order 4 bits then are converted to Gray Code and
; displayed on the LEDs.

; The Table Pointer is used to read a single byte in program memory
; The PC is also used to return a value in program memory
;
; Gray coded binary will be reflected on the LEDs in accordance with the POT reading
;
; PIC: 16F1829
; Assembler: MPASM V5.43
; IDE: MPLABX v1.0
;
; Hardware: PICkit3 Low Pin Count Demo Board
; Date: 12.2011
;
;
; *******************************************************************
; * See Low Pin Count Demo Board User's Guide for Lesson Information*
; *******************************************************************

#include <p16F1829.inc>
     __CONFIG _CONFIG1, (_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF);
     __CONFIG _CONFIG2, (_WRT_OFF & _PLLEN_OFF & _STVREN_OFF & _LVP_OFF);

    errorlevel -302             ;surpress the 'not in bank0' warning

;Only uncomment on of these!!
#define     __EnhancedMethod
;#define     __ClassicMethod
;#define     __FSRMethod
;#define     __TableRead

    cblock 0x70                         ;shared memory location that is accessible from all banks
temp
     endc

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

     Org 0x00
Start:
                                        ;Setup main init
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed of 500KHz
     movwf          OSCCON              ;move contents of the working register into OSCCON

                                        ;Configure the LEDs
     clrf           TRISC               ;make all of PORTC an output
     banksel        LATC                ;bank2
     clrf           LATC                ;start with all LEDs off

                                        ;Configure the ADC/Potentimator
     banksel        TRISA               ;bank1
     bsf            TRISA, 4            ;Potentimator is connected to RA4....set as input
     movlw          b'00001101'         ;select RA4 as source of ADC and enable the module (carefull, this is actually AN3)
     movwf          ADCON0
     movlw          b'00010000'         ;left justified - Fosc/8 speed - vref is Vdd
     movwf          ADCON1
     banksel        ANSELA              ;bank3
     bsf            ANSELA, 4           ;analog for ADC

                                        ;Clear the RAM
     clrf           temp

MainLoop:
    call            A2d                 ;get the ADC result
    swapf           ADRESH, w           ;move the high nibble to wreg for LED display
    call            BinaryToGrayCode    ;convert to Grey Code (Note: important that this is CALLED and not BRANCHED to since
                                        ;the 'RETLW' instruction will return here with the conversion in wreg
    banksel         LATC                ;bank2
    movwf           LATC                ;move grey code into LEDs
    banksel         0                   ;bank0
    bra             MainLoop            ;do this forever


A2d:
                                        ;Start the ADC
    nop                                 ;requried ADC delay of 8uS => (1/(Fosc/4)) = (1/(500KHz/4)) = 8uS
    banksel         ADCON0              ;bank1
    bsf             ADCON0, GO          ;start the ADC
    btfsc           ADCON0, GO          ;this bit will be cleared when the conversion is complete
    goto            $-1                 ;keep checking the above line until GO bit is clear

    return

BinaryToGrayCode:
     andlw          0x0F                ;mask off invalid entries
     movwf          temp

                                        ;an #ifdef is a conditional symbol with is evaluated during preprocessing
                                        ;the top of this program will include 4 #define statements which if uncommented, this
                                        ;statement would become true. and the lines of code inbetween the #ifdef and #endif will
                                        ;be evaluated
#ifdef  __EnhancedMethod
                                        ;using the newer (enhanced midrange only) method instead of dealing with PCL directly
     bra       EnhancedMethod
#endif
#ifdef __FSRMethod
    movlw           high TableStart     ;get high order part of the beginning of the table
    movwf           FSR0H
    movlw           low TableStart      ;get lower order part of the table
    addwf           temp, w             ;add offset from ADC conversion
    btfsc           STATUS, C           ;did it overflow?
    incf            FSR0H, f            ;yes: increment high byte
    movwf           FSR0L               ; modify lower byte
    moviw           FSR0++              ;move the value that FSR0 is pointing to into wreg
    return                              ;grey code now in wreg, return to MainLoop
#endif
#ifdef __ClassicMethod
                                        ;Using the Program Counter (PC) directly
     movlw          high TableStart     ;get high order part of the beginning of the table
     movwf          PCLATH
     movlw          low TableStart      ;load starting address of table
     addwf          temp,w              ;add offset from ADC conversion
     btfsc          STATUS,C            ;did it overflow?
     incf           PCLATH,f            ;yes: increment PCLATH
     movwf          PCL                 ;modify PCL
#endif
#ifdef __TableRead
    banksel         EEADRL              ;Select Bank for EEPROM registers

    movlw           high TableStart
    movwf           EEADRH              ;Store MSb of address
    movlw           low TableStart
    addwf           temp, w
    btfsc           STATUS, C           ;did it overflow?
    incf            EEADRH, f
    movwf           EEADRL              ;Store LSB of address

    bcf             EECON1, CFGS        ;Do not select Configuration Space
    bsf             EECON1, EEPGD       ;Select Program Memory
    bcf             INTCON, GIE         ;Disable interrupts
    bsf             EECON1, RD          ;Initiate read
    nop                                 ;Executed
    nop                                 ;Ignored
    bsf             INTCON, GIE         ;Restore interrupts
    movf            EEDATL, w           ;Get LSB of word
    return                              ;return to main loop with the result in wreg
    ;movwf       PROG_DATA_LO ; Store in user location
    ;movf        EEDATH,W ; Get MSb of word
    ;movwf       PROG_DATA_HI ; Store in user location
#endif

                                         ;Use the PIC's flash memory for values that do not change during runtime. This helps to conserve
                                         ;the RAM and is good programming practice
#ifdef __EnhancedMethod
EnhancedMethod:
     brw                                ;branches to the amount currently in wreg (e.g. if wreg = 0x04, we would return with a code
                                        ;of b'0110', or decimal 4
#endif
TableStart:
     retlw          b'0000'             ; 0
     retlw          b'0001'             ; 1
     retlw          b'0011'             ; 2
     retlw          b'0010'             ; 3
     retlw          b'0110'             ; 4
     retlw          b'0111'             ; 5
     retlw          b'0101'             ; 6
     retlw          b'0100'             ; 7
     retlw          b'1100'             ; 8
     retlw          b'1101'             ; 9
     retlw          b'1111'             ; 10
     retlw          b'1110'             ; 11
     retlw          b'1010'             ; 12
     retlw          b'1011'             ; 13
     retlw          b'1001'             ; 14
     retlw          b'1000'             ; 15

    end