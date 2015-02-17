; *******************************************************************
; Lesson 11 - Indirect addressing
;
; This lesson covers a very important topic of indirect addressing. The code uses indirect
; addressing to implement a moving average filter. This lesson adds a moving average 
; filter to the Analog-to-Digital code in Lesson 4. The moving average keeps a list of the 
; last ADC values (n) and averages them together. The filter needs two parts: A circular 
; queue and a function to calculate the average. 
;
; Twisting the potentiometer changes the value read by the Analog-to-Digital converter. 
; The filtered value is then sent to the LED display.
;
; This lesson provides the same outcome as Lesson 4. The user rotates the POT to see
; the LEDs rotate. The top four MSbs of the ADC value are reflected onto the LEDs.
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

     errorlevel -302      ;surpress the 'not in bank0' warning

    cblock 0x70
Display          ; define a variable to hold the diplay
Queue:8          ; 8 bytes to hold last 8 entries
RunningSum:2     ; sum of last 8 entries
Round:2          ; divide by 8 and round.
temp
    endc

    ; -------------------LATC-----------------
    ; Bit#:  -7---6---5---4---3---2---1---0---
    ; LED:   ---------------|DS4|DS3|DS2|DS1|-
    ; -----------------------------------------

     Org 0
Start:
                                        ;Setup main init
     banksel        OSCCON              ;bank1
     movlw          b'00111000'         ;set cpu clock speed of 500KHz
     movwf          OSCCON              ;move contents of the working register into OSCCON

                                        ;Configure the LEDs
     clrf            TRISC              ;make all of PORTC an output
     banksel         LATC               ;bank2
     clrf            LATC               ;start with all LEDs off

                                        ;Configure the ADC/Potentimator
     banksel        TRISA               ;bank1
     bsf            TRISA, 4            ;Potentimator is connected to RA4....set as input
     movlw          b'00001101'         ;select RA4 as source of ADC and enable the module (carefull, this is actually AN3)
     movwf          ADCON0
     movlw          b'00010000'         ;left justified - Fosc/8 speed - vref is Vdd
     movwf          ADCON1
     banksel        ANSELA              ;bank3
     bsf            ANSELA, 4           ;analog for ADC

                                        ;Init the Filter
     call           FilterInit          ;init the moving average filter
MainLoop:
     call           A2d                 ;start the ADC
     call           Filter              ;send it to the filter
     movwf          Display             ;save the filtered value
     swapf          Display,w           ;swap the nybbles to put the high order
     banksel        LATC                ;bank2
     movwf          LATC                ;into the low order nybble on Port C
     goto           MainLoop

A2d:
                                        ;Start the ADC
    nop                                 ;requried ADC delay of 8uS => (1/(Fosc/4)) = (1/(500KHz/4)) = 8uS
    banksel         ADCON0              ;bank1
    bsf             ADCON0, GO          ;start the ADC
    btfsc           ADCON0, GO          ;this bit will be cleared when the conversion is complete
    goto            $-1                 ;keep checking the above line until GO bit is clear
    movf            ADRESH, w           ;Get the top 8 MSbs (remember that the ADC result is LEFT justified!)

    return

                                        ;keeps a running sum.
                                        ;Before inserting a new value into the queue, the oldest is subtracted
                                        ;from the running sum.  Then the new value is inserted into the array
                                        ;and added to the running sum.
                                        ;Assumes the FSR is not corrupted elsewhere in the program.  If the FSR
                                        ;may be used elsewhere, this module should maintain a copy for it's
                                        ;own use and reload the FSR before use.
FilterInit:
                                        ;the 'high' and 'low' operators are used to return one byte of a multi-byte
				;label value. This is done to handle dynamic pointer calculations. Recall that
				;FSR0 is 16 bits wide (2 bytes).
     movlw          low Queue           ;point to the Queue holding the ADC values
     movwf          FSR0L
     movlw          high Queue          ;point to the Queue holding the ADC values
     movwf          FSR0H
     clrf           RunningSum
     clrf           RunningSum+1
     clrf           Queue
     clrf           Queue+1
     clrf           Queue+2
     clrf           Queue+3
     clrf           Queue+4
     clrf           Queue+5
     clrf           Queue+6
     clrf           Queue+7
     return
                                        ;We already know the address of 'Queue' from the above 'cblock'. FSRO will
				;be pointing to the address of 0x001, hence the 'high' byte should be 0x000
				;and only the lower byte needs to be incremented. Still good practice to check
				;for overflows, however.
Filter:
     movwf          temp                ;save

     movf           INDF0,w             ;subtract the current out of the sum. INDFO holds the value that FSRO pair is pointing to!
     subwf          RunningSum,f
     btfss          STATUS,C            ;was there a borrow?
     decf           RunningSum+1,f      ;yes, take it from the high order byte

     movf           temp,w
     movwf          INDF0               ;store in table
     addwf          RunningSum,f        ;Add into the sum
     btfsc          STATUS,C
     incf           RunningSum+1,f

     incf           FSR0L, f            ;incrememnt to next byte offset in queue
     btfsc	STATUS, C		;did it cause a carry? (should not happen in this demo snippet)
     incf           FSR0H, f		;yes, add it to the high byte of FSR0

     movf           FSR0, w		;get current offset into queue (this will load WREG with the address that FSR0 is pointing to!)
     xorlw          Queue+8             ;did it overflow out of the size of queue? (XOR the address of the last byte in the Queue with what FSR0 is pointing to)
     btfsc          STATUS, Z		;if FSR0 is pointing to the last address in the Queue (byte 8), then reset it
     call           FilterAssign        ;yes: reset the pointer to the 0 byte in the Queue

     bcf            STATUS,C            ;clear the carry
     rrf            RunningSum+1, w
     movwf          Round+1
     rrf            RunningSum, w        ;divide by 2 and copy to a version we can corrupt
     movwf          Round

     bcf            STATUS, C            ;clear the carry
     rrf            Round+1, f
     rrf            Round, f             ;divide by 4

     bcf            STATUS, C            ;clear the carry
     rrf            Round+1, f
     rrf            Round, f             ;divide by 8

     btfsc          STATUS, C            ;use the carry bit to round
     incf           Round, f
     movf           Round, w             ;load Wreg with the answer
     return

FilterAssign:
     movlw          low Queue           ;point to the Queue holding the ADC values
     movwf          FSR0L
     movlw          high Queue          ;point to the Queue holding the ADC values
     movwf          FSR0H
     return

     end