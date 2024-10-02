; Definir los registros de control y los pines de los componentes
SYSCTL_RCGCGPIO_R    EQU 0x400FE608
GPIO_PORTB_DATA_R    EQU 0x400053FC
GPIO_PORTE_DATA_R    EQU 0x400243FC
GPIO_PORTB_DIR_R     EQU 0x40005400
GPIO_PORTE_DIR_R     EQU 0x40024400
GPIO_PORTB_DEN_R     EQU 0x4000551C
GPIO_PORTE_DEN_R     EQU 0x4002451C
LED_V                EQU 0x02    ; PE1
LED_R                EQU 0x04    ; PE2
BUZZER               EQU 0x08    ; PE3

; Pines para el TM1637
CLK                  EQU 0x08    ; PB3
DIO                  EQU 0x10    ; PB4

    AREA    codigo, CODE, READONLY
    THUMB
    EXPORT Start

Start
    ; Habilitar reloj para puertos B y E
    LDR R1, =SYSCTL_RCGCGPIO_R
    LDR R0, [R1]
    ORR R0, R0, #0x12     ; Habilitar puerto B y puerto E
    STR R0, [R1]
    NOP
    NOP

    ; Configurar pines PB y PE como digitales
    LDR R1, =GPIO_PORTB_DEN_R
    LDR R0, [R1]
    ORR R0, R0, #0x1F    ; Habilitar pines PB0 a PB4 como digitales
    STR R0, [R1]

    LDR R1, =GPIO_PORTE_DEN_R
    LDR R0, [R1]
    ORR R0, R0, #0x0E    ; Habilitar pines PE1, PE2, PE3 como digitales
    STR R0, [R1]

    ; Configurar pines PE1, PE2, PE3 como salidas
    LDR R1, =GPIO_PORTE_DIR_R
    LDR R0, [R1]
    ORR R0, R0, #0x0E    ; Configurar PE1, PE2, PE3 como salidas
    STR R0, [R1]

    ; Inicializar DS1302 y TM1637
    BL initRTC
    BL initTM1637

Loop
    ; Leer hora y minutos del RTC
    BL readTime
    MOV R4, R0            ; Guardar minutos en R4
    MOV R5, R1            ; Guardar horas en R5

    ; Mostrar hora en el TM1637
    BL updateDisplay

    ; Comprobar condiciones para la alarma
    CMP R5, #18           ; Verificar si es la hora 18 (6 PM)
    BNE CheckOtherTime

    CMP R4, #00           ; Verificar si los minutos están entre 00 y 05
    BGE AlarmOneMinute
    CMP R4, #05
    BLT AlarmOneMinute

    CMP R4, #06           ; Verificar si es exactamente 18:06
    BEQ AlarmFullMinute

    CMP R4, #10           ; Verificar si los minutos están entre 10 y 11
    BGE AlarmOneMinute
    CMP R4, #11
    BLT AlarmOneMinute

    ; Si no está en ninguno de los intervalos, enciende el LED rojo
    LDR R1, =GPIO_PORTE_DATA_R
    LDR R0, [R1]
    BIC R0, R0, #0x0E     ; Apagar BUZZER y LED verde
    ORR R0, R0, #LED_R    ; Encender LED rojo
    STR R0, [R1]

    B ContinueLoop

CheckOtherTime
    ; Aquí se puede agregar lógica adicional si es necesario
    B ContinueLoop

AlarmOneMinute
    ; Llama a la alarma por 1 minuto
    MOV R0, #1
    BL triggerAlarm
    B ContinueLoop

AlarmFullMinute
    ; Llama a la alarma por 60 segundos
    MOV R0, #60
    BL triggerAlarm

ContinueLoop
    ; Esperar 500 ms antes de la siguiente iteración
    BL delay500ms
    B Loop

; Subrutina para activar la alarma
triggerAlarm
    ; R0 contiene la duración en segundos
    PUSH {LR}             ; Guardar el valor de retorno
    MOV R1, #5            ; Multiplicar el tiempo por 5 para 200 ms de intervalos
    MUL R0, R0, R1

TriggerLoop
    LDR R1, =GPIO_PORTE_DATA_R
    LDR R2, [R1]
    ORR R2, R2, #LED_V    ; Encender LED verde
    ORR R2, R2, #BUZZER   ; Encender BUZZER
    BIC R2, R2, #LED_R    ; Apagar LED rojo
    STR R2, [R1]

    BL delay100ms         ; Espera 100 ms

    LDR R2, [R1]
    BIC R2, R2, #LED_V    ; Apagar LED verde
    BIC R2, R2, #BUZZER   ; Apagar BUZZER
    STR R2, [R1]

    BL delay100ms         ; Espera otros 100 ms

    SUBS R0, R0, #1       ; Reducir el contador
    BNE TriggerLoop

    POP {LR}              ; Restaurar el valor de retorno
    BX LR

; Subrutinas para inicializar el RTC y el TM1637
initRTC
    ; Inicialización del DS1302 (debe ser implementado)
    BX LR

initTM1637
    LDR R1, =GPIO_PORTB_DIR_R
    LDR R0, =GPIO_PORTB_DATA_R
    ; Configurar pines para el TM1637
    LDR R2, [R1]
    ORR R2, R2, #CLK      ; Configurar PB3 como salida
    ORR R2, R2, #DIO      ; Configurar PB4 como salida
    STR R2, [R1]
    ; Aquí puedes implementar la inicialización básica, como configurar el brillo
    BX LR

; Subrutina para leer la hora y los minutos del RTC
readTime
    ; Leer la hora y minutos del DS1302 (debe ser implementado)
    ; Almacenar los minutos en R0 y las horas en R1
    BX LR

; Subrutina para actualizar la pantalla del TM1637
updateDisplay
    PUSH {R0, R1, LR}          ; Guardar R0, R1 y el valor de retorno
    
    LDR R0, =GPIO_PORTB_DATA_R ; Dirección del puerto de datos del TM1637
    
    ; Comenzar a enviar datos al TM1637
    MOV R1, #0x40              ; Comando de escritura
    STR R1, [R0]               ; Enviar comando

    ; Enviar los dígitos de la hora y minutos
    MOV R1, R5                 ; Cargar horas
    STR R1, [R0]               ; Enviar horas
    MOV R1, R4                 ; Cargar minutos
    STR R1, [R0]               ; Enviar minutos

    ; Finaliza la comunicación
    MOV R1, #0x80              ; Comando de finalización
    STR R1, [R0]               ; Enviar comando

    POP {R0, R1, PC}           ; Restaurar R0, R1 y volver

; Subrutinas para retardos
delay100ms
    LDR R1, =1000000          ; Ajusta el valor según la frecuencia del reloj
DelayLoop100
    NOP                       ; No operación
    SUBS R1, R1, #1          ; Decrementar R1
    BNE DelayLoop100          ; Repetir hasta que R1 llegue a 0
    BX LR                     ; Retornar

delay500ms
    LDR R1, =5000000          ; Ajusta el valor para 500 ms
DelayLoop500
    NOP                       ; No operación
    SUBS R1, R1, #1          ; Decrementar R1
    BNE DelayLoop500          ; Repetir hasta que R1 llegue a 0
    BX LR                     ; Retornar

    END
