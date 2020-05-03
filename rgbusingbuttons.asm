;*******************************************************************************
; UNIVERSIDAD NACIONAL DE COLOMBIA - INGENIERÍA MECATRÓNICA
; With this code and the appropiate setup you can control
; an RGB LED by fully enlighten each of it's channels with a
; button.
; Pay special attention to the connections diagram
; SEBASTIAN CUBIDES & DAVID FONSECA
;*******************************************************************************

                    #Uses     mc9s08qg8.inc

                    xref      __SEG_END_SSTACK    ; symbol defined by the linker for the end of the stack

;*******************************************************************************
                    #RAM
;*******************************************************************************

btnst               fcb       1                   ; variable para estado de boton

;*******************************************************************************
                    #ROM
;*******************************************************************************

Start               proc
                    ldhx      #__SEG_END_SSTACK   ; initialize the stack pointer
                    txs
                    lda       #$02                ; desactivar watchdog, dejar modo BKGD enabled
                    sta       SOPT1               ; BKGD jamas disabled
                    mov       #%11111000,PTADD    ; puerto A bit0,1 & 2 como entrada
                    lda       #$07                ; cargar hex 07 en acumulador (ultimos 3 bits en 1)
                    sta       PTAPE               ; habilitar pull-up en pin0,pin1 & pin2 de PTA
; puerto en estado natural en 1 logico
; boton presionado lo pone en 0 logico
                    mov       #$07,btnst          ; dar un estado inicial a variable de boton
                    mov       #%00001110,PTBDD    ; puerto B bit1,bit2 & bit3 como salida
                    mov       #%00001110,PTBD     ; bit1,bit2 & bit3 del puerto B en 1 logico

MainLoop            brclr     0,PTAD,boton        ; (DIR)pregunta si boton esta presionado, osea bit en 0,
; dado el caso salta a rutina boton
                    brclr     1,PTAD,boton2       ; (DIR)pregunta si boton esta presionado, osea bit en 0
                    brclr     2,PTAD,boton3       ; (DIR)pregunta si boton esta presionado, osea bit en 0
                    bra       MainLoop

boton               lda       PTBD                ; (DIR)cargar estado actual del puerto B en acumulador.
                    eor       #%00000010          ; (IMM)operación XOR entre el acumulador y el numero indicado
; hacer esta operación con ese bit en especifico resulta en alternar el bit
; correspondiente, resultado se guarda en el acumulador.
                    sta       PTBD                ; (DIR)guardar en PTBD lo presente en el acumulador
still
                    nop
                    brclr     0,PTAD,still        ; (DIR)compare el acumulador con btnst, branch if equal a etiqueta still
; haciendo esta comparacion le decimos a el MCU que espere a que dejemos de
; pulsar el boton para continuar y asi completar la acción de alternar el estado
; del puerto o del LED en este caso
                    nop                           ; no operation para tener una pequqeña pausa
                    bra       MainLoop            ; (REL)devuelta al MainLoop.

boton2              lda       PTBD                ; (DIR)cargar estado actual del puerto B en acumulador.
                    eor       #%00000100          ; (IMM)operación XOR entre el acumulador y el numero indicado
; hacer esta operación con ese bit en especifico resulta en alternar el bit
; correspondiente, resultado se guarda en el acumulador.
                    sta       PTBD                ; (DIR)guardar en PTBD lo presente en el acumulador
still2              nop
                    brclr     1,PTAD,still2       ; compare el acumulador con btnst, branch if equal a etiqueta still
; haciendo esta comparacion le decimos a el MCU que espere a que dejemos de
; pulsar el boton para continuar y asi completar la acción de alternar el estado
; del puerto o del LED en este caso
                    nop                           ; no operation para tener una pequqeña pausa
                    bra       MainLoop            ; devuelta al MainLoop.

boton3              lda       PTBD                ; cargar estado actual del puerto B en acumulador.
                    eor       #%00001000          ; operación XOR entre el acumulador y el numero indicado
; hacer esta operación con ese bit en especifico resulta en alternar el bit
; correspondiente, resultado se guarda en el acumulador.
                    sta       PTBD                ; guardar en PTBD lo presente en el acumulador

still3              nop
                    brclr     2,PTAD,still3       ; compare el acumulador con btnst3, branch if equal a etiqueta still
; haciendo esta comparacion le decimos a el MCU que espere a que dejemos de
; pulsar el boton para continuar y asi completar la acción de alternar el estado
; del puerto o del LED en este caso
                    nop                           ; no operation para tener una pequqeña pausa
                    bra       MainLoop            ; devuelta al MainLoop.
