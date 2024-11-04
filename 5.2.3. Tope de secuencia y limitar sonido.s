/* Configuración de vectores de interrupción */
        ADDEXC  0x18, irq_handler    @ Vector para IRQ
        ADDEXC  0x1c, fiq_handler    @ Vector para FIQ

/* Inicialización de la pila en modos FIQ, IRQ y SVC */
        mov     r0, #0b11010001      @ Cambiar a modo FIQ, desactivar FIQ e IRQ
        msr     cpsr_c, r0
        mov     sp, #0x4000          @ Inicializar pila para FIQ

        mov     r0, #0b11010010      @ Cambiar a modo IRQ, desactivar FIQ e IRQ
        msr     cpsr_c, r0
        mov     sp, #0x8000          @ Inicializar pila para IRQ

        mov     r0, #0b11010011      @ Cambiar a modo SVC, desactivar FIQ e IRQ
        msr     cpsr_c, r0
        mov     sp, #0x8000000       @ Inicializar pila para SVC

/* Configuración de GPIOs 4, 9, 10, 11, 17, 22 y 27 como salida */
        ldr     r0, =GPBASE
        ldr     r1, =0b00001000000000000001000000000000  @ Configurar GPIO 4 y 22
        str     r1, [r0, #GPFSEL0]

        ldr     r1, =0b00000000001000000000000000001001  @ Configurar GPIO 9, 10, 11
        str     r1, [r0, #GPFSEL1]

        ldr     r1, =0b00000000001000000000000001000000  @ Configurar GPIO 17 y 27
        str     r1, [r0, #GPFSEL2]

/* Encender LEDs en los pines configurados (GPIOs 4 y 22) */
        mov     r1, #0b00000000000000000000001000000000  @ Estado de encendido inicial
        str     r1, [r0, #GPSET0]

/* Habilitar interrupciones en GPIO 2 y 3 (botones) */
        mov     r1, #0b00000000000000000000000000001100  @ Pines GPIO 2 y 3
        str     r1, [r0, #GPFEN0]                        @ Habilitar detección de flanco

/* Configurar temporizador C1 para una interrupción en 2 microsegundos */
        ldr     r0, =STBASE
        ldr     r1, [r0, #STCLO]     @ Leer el contador de tiempo actual
        add     r1, #2               @ Agregar 2 microsegundos
        str     r1, [r0, #STC1]      @ Configurar C1

/* Habilitar interrupción en GPIOs para IRQ */
        ldr     r0, =INTBASE
        mov     r1, #0b00000000000100000000000000000000  @ Habilitar IRQ para GPIOs
        str     r1, [r0, #INTENIRQ2]

/* Habilitar temporizador C1 para FIQ */
        mov     r1, #0b10000001      @ Activar FIQ para temporizador C1
        str     r1, [r0, #INTFIQCON]

/* Habilitar interrupciones globalmente en modo SVC */
        mov     r0, #0b00010011      @ Cambiar a modo SVC, habilitar FIQ e IRQ
        msr     cpsr_c, r0

/* Rutina de interrupción FIQ */
fiq_handler:
        ldr     r8, =GPBASE
        ldr     r9, =bitson

        /* Cambiar estado del altavoz invirtiendo el bit en 'bitson' */
        ldr     r10, [r9]
        eors    r10, #1              @ Invertir el bit de estado
        str     r10, [r9], #4        @ Guardar nuevo estado de 'bitson'

        /* Leer el valor de cuenta y secuencia */
        ldr     r10, [r9]
        ldr     r9, [r9, +r10, LSL #3]

        /* Control del altavoz basado en el estado de 'bitson' */
        mov     r10, #0b10000        @ Máscara para GPIO 4 (altavoz)
        streq   r10, [r8, #GPSET0]   @ Encender altavoz si bitson es 1
        strne   r10, [r8, #GPCLR0]   @ Apagar altavoz si bitson es 0

        /* Resetear el estado de interrupción de C3 */
        ldr     r8, =STBASE
        mov     r10, #0b1000
        str     r10, [r8, #STCS]

        /* Configurar el siguiente retardo basado en el valor de secuencia */
        ldr     r10, [r8, #STCLO]    @ Leer el contador actual
        add     r10, r9              @ Sumar el retardo según secuencia
        str     r10, [r8, #STC3]     @ Configurar temporizador C3

        /* Retorno de la interrupción FIQ */
        subs    pc, lr, #4           @ Salida de la rutina de interrupción FIQ

/* Bucle infinito */
bucle:  b       bucle
