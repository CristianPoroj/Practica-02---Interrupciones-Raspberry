/* Configuración de vectores de interrupción y el manejo de IRQ */
        ADDEXC  0x18, irq_handler   @ Dirección de la rutina de interrupción

/* Inicializo la pila en modo IRQ */
        mov     r0, #0b11010010     @ Modo IRQ con interrupciones FIQ&IRQ desactivadas
        msr     cpsr_c, r0
        mov     sp, #0x8000         @ Dirección de la pila para el modo IRQ

/* Configuración de pines GPIO como salida */
        ldr     r0, =GPBASE
        ldr     r1, =0b00001000000000000001000000000000  @ GPIO 4 y 22 como salida
        str     r1, [r0, #GPFSEL0]

        ldr     r1, =0b00000000001000000000000000001001  @ GPIO 9, 10 y 11 como salida
        str     r1, [r0, #GPFSEL1]

        ldr     r1, =0b00000000001000000000000001000000  @ GPIO 17 y 27 como salida
        str     r1, [r0, #GPFSEL2]

/* Configuración de temporizador para generar una interrupción en 2 microsegundos */
        ldr     r0, =STBASE
        ldr     r1, [r0, #STCLO]    @ Obtengo el tiempo actual
        add     r1, #2              @ Siguiente interrupción en 2 µs
        str     r1, [r0, #STC1]     @ Programo la interrupción en C1
        str     r1, [r0, #STC3]     @ Programo la interrupción en C3 (redundante)

/* Habilito C1 para generar una interrupción IRQ */
        ldr     r0, =INTBASE
        mov     r1, #0b0010
        str     r1, [r0, #INTENIRQ1]

/* Habilito interrupciones globalmente */
        mov     r0, #0b00010011     @ Modo SVC con interrupciones FIQ&IRQ activas
        msr     cpsr_c, r0

/* Manejo de la interrupción */
irq_handler:
        push    {r0, r1, r2}        @ Guarda registros en la pila

        ldr     r0, =GPBASE
        ldr     r1, =cuenta

        /* Apago todos los LEDs */
        ldr     r2, =0b00001000010000100000111000000000
        str     r2, [r0, #GPCLR0]

        /* Actualizo el contador de secuencia de LEDs */
        ldr     r2, [r1]            @ Leo la variable "cuenta"
        subs    r2, #1              @ Decremento la cuenta
        moveq   r2, #6              @ Si es 0, reinicio a 6
        str     r2, [r1]            @ Escribo el nuevo valor en "cuenta"

        /* Configuro el patrón de LEDs en función de la cuenta */
        ldr     r2, [r1, +r2, LSL #3] @ Obtengo la secuencia de LEDs
        str     r2, [r0, #GPSET0]   @ Actualizo el estado de los LEDs

        /* Restablezco el estado de la interrupción de C1 */
        ldr     r0, =STBASE
        mov     r2, #0b0010
        str     r2, [r0, #STCS]

        /* Programo la siguiente interrupción en 500 ms */
        ldr     r2, [r0, #STCLO]    @ Tiempo actual
        ldr     r1, =500000         @ Intervalo de 500 ms
        add     r2, r1              @ Próxima interrupción en 500 ms
        str     r2, [r0, #STC1]     @ Programo la interrupción en C1

        /* Restaura registros y finaliza interrupción */
        pop     {r0, r1, r2}
        subs    pc, lr, #4          @ Retorno de la interrupción

/* Bucle infinito */
bucle:  b       bucle
