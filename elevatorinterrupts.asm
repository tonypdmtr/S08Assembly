;*******************************************************************************
; Code for simulating an elevator's action
; Uses 4 LEDs as current floor indicator, a 7 segment display
; as an indicator for the desired floor controled by two buttons
; managed with KBI interrupts, then a button activates the IRQ
; interrupt to start a secuence that takes the active LED to the
; desired floor using retards to light up the LEDs.
; Sebastian Cubides & David Fonseca
; May,2019
;*******************************************************************************

                    #Uses     mc9s08qg8.inc

                    xref      __SEG_END_SSTACK    ; symbol defined by the linker for the end of the stack

;*******************************************************************************
                    #RAM
;*******************************************************************************

actual              rmb       1
objetivo            rmb       1
var                 rmb       1
chicharra           rmb       1

;*******************************************************************************
                    #ROM
;*******************************************************************************

piso                fcb       %00010000,%10000000,%10010000,%01000000
pisoLED             fcb       %00001000,%00000100,%00000010,%00000001
mask7seg            fcb       %00001111
maskLED             fcb       %11110000

;*******************************************************************************

Start               proc
                    ldhx      #__SEG_END_SSTACK   ; initialize the stack pointer
                    txs
                    cli                           ; enable interrupts

                    lda       #$02                ; desactivar watchdog, dejar modo BKGD enabled
                    sta       SOPT1               ; BKGD jamas disabled

                    mov       #%11111100,PTADD    ; puerto A bit0 & bit1 como entrada, bit3 salida
                    lda       #$03                ; cargar hex 01 en acumulador
                    sta       PTAPE               ; habilitar pull-up en pin0 & pin1 de PTA
                                                  ; puerto en estado natural en 1 logico
                                                  ; boton presionado lo pone en 0 logico
;                   mov       #%00001000,PTAD
                    mov       #%11111111,PTBDD    ; puerto B bit2 como salida1
                    mov       #%00011000,PTBD     ; bit2 del puerto B en 1 logico
                    mov       #$00,actual         ; inicializar variable en 0
                    mov       #$00,objetivo       ; inicializar variable en 0
                    mov       #$00,var            ; inicializar variable en 0
                    mov       #$00,chicharra      ; inicializar variable en 0
          ;-------------------------------------- ; configuracion modulo IRQ
                    mov       #%00010010,IRQSC    ; configuracion registro IRQ Status and Control
                              ; | |||||________IRMOD, interrupción generada solo por flanco de bajada
                              ; | ||||_________IRQIE, habilitar interrupcion por IRQ
                              ; | |||__________IRQACK, acknowledge de interrucpión, para limpiar bandera IRQF
                              ; | ||___________IRQF, bit de solo lectura, bandera que indica cuando ocurre un evento IRQ
                              ; | |____________IRQPE, habilitar la función IRQ en el pin designado, pin 1 en el QG8
                              ; |
                              ; |______________IRQPDD, pull-up del pin habilitado por defecto cuando IRQPE es 1
          ;-------------------------------------- ; KBI configuration
;                   lda       #%00000011          ; PTA Pull Enable
;                   sta       PTAPE               ; activar resistencias internas de Pull-up

                    lda       #%00000000          ; KBI Edge Select
                    sta       KBIES               ; interrupción por flanco de entrada en los pines KBIP0 & KBPI1

                    lda       #%00000011          ; KBI Pin Enable
                    sta       KBIPE               ; habilitacion solo de pines 0,1 como fuentes de KBI
          ;-------------------------------------- ; KBI Status and Control
                    bset      2,KBISC             ; 1 en KBACK para evitar falsar interrupciones antes de iniciar el modulo
                    bclr      0,KBISC             ; 0 en KBMOD para generar interrupcion solo por flancos
                    bset      1,KBISC             ; 1 en KBIE para activar las interrupciones por KBI
          ;-------------------------------------- ; rti_cfg:
;                   lda       #%00010111
                              ; |||| |||________RTIS, arreglo de 3 bits para seleccionar el tiempo entre interrupcion,
                              ; |||| ||_________usando un reloj interno dedicado de 1khz,
                              ; |||| |__________111 para interrupción cada 1.024 segundos (segun tabla datasheet)
                              ; ||||
                              ; ||||____________RTIE, habilitar interrupcion por RTI
                              ; |||_____________RTICLKS, seleccion clock fuente de RTI, 0 para seleccionar reloj 1 khz dedicado
                              ; ||______________RTIACK, acknowledge de interrucpión, para limpiar bandera RTIF
                              ; |_______________RTIF, bit de solo lectura, bandera que indica cuando ocurre un evento RTI
;                   sta       SRTISC              ; System Real Time Interrupt Status and Control
;                   bra       MainLoop

;*******************************************************************************

MainLoop            proc
Loop@@              ...       Insert your code here
                    nop
                    bra       Loop@@

;*******************************************************************************
; rutina para atender la IRQ

IRQ_Handler         proc
                    bset      2,IRQSC             ; limpiar bandera al poner en 1 el bit, acknowledge interrupcion
          ;-------------------------------------- ; para permitir alguna interrupción futura
                    lda       PTBD
                    sta       var                 ; cargar estado del puerto B en var

                    lda       mask7seg            ; Cargar en A mascara de puerto (00001111)
                    and       var                 ; AND mascara y valor del puerto
                    sta       var                 ; Colocar el valor enmascarado en var

                    clrh
                    ldx       objetivo            ; cargar objetivo en el X

                    lda       pisoLED,X           ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    cmp       var                 ; Comparar A con var (piso objetivo con piso actual) CCR bit N updated
;                   sta       var
                    bgt       Disminuir@@         ; branch si el piso actual es menor al requerido
                    blt       Aumentar@@          ; branch si el piso actual es mayor al requerido
                    rti                           ; return from interrupt, retomar el punto desde donde
          ;-------------------------------------- ; se activo la interrupcion
Disminuir@@         clra
                    cbeq      actual,Done@@       ; para que no se pase de 0(1) el contador
                    dec       actual

                    lda       PTBD
                    sta       var                 ; cargar estado del puerto B en var

                    lda       maskLED             ; Cargar en A mascara de puerto (11110000)
                    and       var                 ; AND mascara y valor del puerto
                    sta       var                 ; Colocar el valor enmascarado en var
                    clrh
                    ldx       actual              ; cargar actual en el X

                    lda       pisoLED,x           ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    ora       var                 ; OR entre valor enmascarado y valor buscado
                    sta       PTBD                ; Cargar nuevo valor en puerto

                    jsr       Delay
          ;-------------------------------------- ; Validar si se llegó al valor o no
                    clrh
                    ldx       actual              ; cargar actual en el X

                    lda       pisoLED,x           ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    sta       var                 ; Cargar en var el valor del piso actual

                    clrh
                    ldx       objetivo            ; cargar objetivo en el X

                    lda       pisoLED,x           ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    cmp       var                 ; Comparar el valor enmascarado con el valor a colocar CCR updated
                    bgt       Disminuir@@         ; Si A(objetivo) es menor a var(actual) (i.e. 0010 > 0100) hacer branch

                    lda       #%00010111
                    sta       SRTISC
                    rti

Aumentar@@          lda       #3
                    cbeq      actual,Done@@       ; para que no se pase de 3(4) el contador

                    inc       actual

                    lda       PTBD
                    sta       var                 ; cargar estado del puerto B en var

                    lda       maskLED             ; Cargar en A mascara de puerto (11110000)
                    and       var                 ; AND mascara y valor del puerto
                    sta       var                 ; Colocar el valor enmascarado en var
                    clrh
                    ldx       actual              ; cargar actual en el X

                    lda       pisoLED,X           ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    ora       var                 ; OR entre valor enmascarado y valor buscado
                    sta       PTBD                ; Cargar nuevo valor en puerto
                    jsr       Delay

                    clrh
                    ldx       actual              ; cargar actual en el X

                    lda       pisoLED,X           ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    sta       var                 ; Cargar en var el valor del piso actual

                    clrh
                    ldx       objetivo            ; cargar objetivo en el X

                    lda       pisoLED,X           ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    cmp       var                 ; Comparar el valor enmascarado con el valor a colocar CCR updated
                    blt       Aumentar@@          ; Si A(objetivo) es menor a var(actual) (i.e. 0010 > 0100) hacer branch

                    lda       #%00010111
                    sta       SRTISC
Done@@              rti

;*******************************************************************************

Delay               proc
                    lda       #$41                ; cargar 0xff en acumulador
Loop@@              psha                          ; push lo del acumulador en el stack
                    lda       #$40                ; cargar 0x15 en acumulador
_1@@                psha                          ; push lo del acumulador en el stack
                    lda       #$f0                ; ;cargar 0xff en acumulador
                    dbnza     *                   ; decrement Acumulador, branch a etiqueta * if not zero
                    pula                          ; sacar lo del stack y ponerlo en el acumulador
                    dbnza     _1@@                ; decrement Acumulador, branch a etiqueta _1@@ if not zero
                    pula                          ; sacar lo del stack y ponerlo en el acumulador
                    dbnza     Loop@@              ; decrement Acumulador, branch a etiqueta Loop@@ if not zero
                    rts                           ; return from subroutine, volver a desde donde se llamo la subrutina

;*******************************************************************************
; rutina para atender la KBI

KBI_Handler         proc
                    bset      2,KBISC             ; limpiar bandera al poner en 1 el bit, acknowledge interrupcion
          ;-------------------------------------- ; para permitir alguna interrupción futura
                    brclr     0,PTAD,Mas@@        ; preguntar que pin generó la interrupcion KBI y ejecutar acción
                    brclr     1,PTAD,Menos@@
                    rti                           ; return from interrupt, retomar el punto desde donde
          ;-------------------------------------- ; se activo la interrupcion
Mas@@               lda       #3
                    cbeq      objetivo,Done@@     ; para que no se pase de 3(4) el contador
                    inc       objetivo

                    lda       PTBD
                    sta       var                 ; cargar estado del puerto B en var

                    lda       mask7seg            ; Cargar en A mascara de puerto (00001111)
                    and       var                 ; AND mascara y valor del puerto
                    sta       var                 ; Colocar el valor enmascarado en var
                    clrh
                    ldx       objetivo            ; cargar objetivo en el X

                    lda       piso,X              ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    ora       var                 ; OR entre valor enmascarado y valor buscado
                    sta       var
                    sta       PTBD                ; Cargar nuevo valor en puerto
                    rti                           ; return from interrupt
          ;--------------------------------------
Menos@@             clra
                    cbeq      objetivo,Done@@     ; para que no se pase de 0(1) el contador
                    dec       objetivo

                    lda       PTBD
                    sta       var                 ; cargar estado del puerto B en var

                    lda       mask7seg            ; Cargar en A mascara de puerto
                    and       var                 ; AND mascara y valor del puerto
                    sta       var                 ; Colocar el valor enmascarado en var
                    clrh
                    ldx       objetivo            ; cargar objetivo en el X

                    lda       piso,X              ; Cargar el codigo del piso objetivo en A, offset de X para escoger el piso
                    ora       var                 ; OR entre valor enmascarado y valor buscado
                    sta       PTBD                ; Cargar nuevo valor en puerto
Done@@              rti

;*******************************************************************************
; rutina para antender la interrupcion por RTI

RTI_Handler         proc
                    lda       #2                  ; cargar 2 en acumulador
                    cbeq      chicharra,ClrCh@@   ; para poner limite en incremento de var hasta 2

                    lda       #%01010111          ; limpiar bandera al poner en 1 el bit, acknowledge interrupcion
                    ora       SRTISC              ; para permitir la siguiente interrupción ya que es periódica
                    sta       SRTISC

                    lda       PTAD
                    sta       var                 ; cargar estado del puerto B en var

                    lda       #%00001000          ; Cargar en A mascara de puerto (00001000)
                    and       var                 ; AND mascara y valor del puerto
                    sta       var                 ; Colocar el valor enmascarado en var

                    lda       #%00001000
                    eor       var
                    sta       var                 ; Alternar pin3
                    lda       PTAD
                    and       #%11110111
                    ora       var

                    sta       PTAD                ; Cargar nuevo valor en puerto
                    inc       chicharra
                    rti                           ; return from interrupt, retomar el punto desde donde
          ;-------------------------------------- ; se activó la interrupcion
ClrCh@@             mov       #$00,chicharra      ; resear var
                    lda       #%01000111          ; limpiar bandera al poner en 1 el bit, acknowledge interrupcion

                    sta       SRTISC
                    rti
