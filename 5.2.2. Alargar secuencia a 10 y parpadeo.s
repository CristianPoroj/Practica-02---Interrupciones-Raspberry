/* Agregar vector de interrupción */
        ADDEXC  0x18, irq_handler    @ Dirección de la rutina de interrupción

/* Configuración de la pila en modo IRQ */
        mov     r0, #0b11010010      @ Modo IRQ, desactivar FIQ e IRQ
        msr     cpsr_c, r0
        mov     sp, #0x8000          @ Inicializar pila para IRQ

/* Configuración de pines GPIO como salida (4, 9, 10, 11, 17, 22 y 27) */
        ldr     r0, =GPBASE
        ldr     r1, =0b00001000000000000001000000000000  @ GPIO 4 y 22
        str     r1, [r0, #GPFSEL0]

        ldr     r1, =0b00000000001000000000000000001001  @ GPIO 9, 10, 11
        str     r1, [r0, #GPFSEL1]

        ldr     r1, =0b00000000001000000000000001000000  @ GPIO 17 y 27
        str     r1, [r0, #GPFSEL2]

/* Programación de temporizador C1 y C3 a 2 microsegundos */
        ldr     r0, =STBASE
        ldr     r1, [r0, #STCLO]     @ Leer contador de tiempo
        add     r1, #2               @ Próxima interrupción en 2 µs
        str     r1, [r0, #STC1]      @ Configurar C1
        str     r1, [r0, #STC3]      @ Configurar C3 (si es necesario)

/* Habilitación de C1 para generar interrupción IRQ */
        ldr     r0, =INTBASE
        mov     r1, #0b0010
        str     r1, [r0, #INTENIRQ1]

/* Habilitación global de interrupciones */
        mov     r0, #0b00010011      @ Modo SVC, FIQ e IRQ activas
        msr     cpsr_c, r0

/* Rutina de manejo de interrupción IRQ */
irq_handler:
        push    {r0, r1, r2}         @ Guardar registros en pila

        ldr     r0, =GPBASE
        ldr     r1, =cuenta

        /* Apagar todos los LEDs */
        ldr     r2, =0b00001000010000100000111000000000
        str     r2, [r0, #GPCLR0]

        /* Verificar si el botón está pulsado */
        ldr     r2, [r0, #GPEDS0]    @ Leer el estado de los botones
        ands    r2, #0b00000000000000000000000000001000  @ Verificar botón específico
        beq     incre                @ Si no está pulsado, saltar a incremento

/* Actualización de variable y LEDs */
conti:
        str     r2, [r1], #-4        @ Guardar en cuenta
        ldr     r2, [r1, +r2, LSL #3] @ Leer patrón de LEDs según cuenta
        str     r2, [r0, #GPSET0]    @ Encender LEDs según patrón

        pop     {r0, r1, r2}         @ Recuperar registros
        subs    pc, lr, #4           @ Retorno de la interrupción

/* Bucle infinito */
bucle:  b       bucle
