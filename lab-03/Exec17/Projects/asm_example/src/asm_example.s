        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

;========================================================================;
;       - Os registradores das portas sao acessados por meio de LDR e STR
;       https://www.ic.unicamp.br/~celio/mc404-2013/armhomepage.html
; tabela 10-7 pagina 757

SYSCTL_RCGCGPIO_R       EQU     0x400FE608              ; Run-mode Clock Gating -> Inicializacao -> Habilita clock
SYSCTL_PRGPIO_R         EQU     0x400FEA08              ; Peripheral Ready      -> Inicializacao -> Indica se a porta GPIO está pronta para uso
PORTF_BIT               EQU     0000000000100000b       ; Define que pode se escrever 5bits na porta f -> datasheet
PORTJ_BIT               EQU     0000000100000000b       ; Define que pode se escrever 8bits na porta j -> datasheet
PORTN_BIT               EQU     0001000000000000b       ; Define que pode se escrever 8bits na porta n -> datasheet

; declaração dos pinos GPIO -> pg 755, 756, 757, 759 datasheet
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400          ; GPIO_DIR (Direction) -> entrada ou saida
GPIO_PUR                EQU     0x0510  
GPIO_DEN                EQU     0x051C          ; GPIO_DEN (Digital Enable) -> Habilitar funcao digital

; Bits para controle dos leds
LEDN_1                   EQU     00010b
LEDN_2                   EQU     00001b
LEDF_2                   EQU     00001b
LEDF_1                   EQU     10000b

; Tempo de delay
DELAY                    EQU     0x005F

__iar_program_start
        
;; main program begins here
main    MOV R0, #(PORTN_BIT)
        BL Enable_port                  ; habilita a porta n

        MOV R0, #(PORTJ_BIT)
        BL Enable_port                  ; habilita a portra j

        LDR R0, =GPIO_PORTN_BASE        ; Endereço de memoria base da porta N
        MOV R1, #000000011b             ; bits a seram habilitados da porta N    
        BL Enable_GPIO_output           ; habilita os bits 0 e 1 da porta N
        BL Digital_write_low

        LDR R0, =GPIO_PORTF_BASE        ; Endereço de memoria base da porta J
        MOV R1, #000010001b             ; bits a seram habilitados da porta J    
        BL Enable_GPIO_output           ; habilita os bits 0 e 4 da porta J
        BL Digital_write_low
        
        MOV R3, #0b
loop:   
        
        ADD R3, R3, #1
        Bl binary_led
        B loop


;=======================================================;
;       -> Habilita o GPIO que estiver na porta R0      ;
;       -> Input: R0, R1                                ;
;       -> Aux:   R2                                    ;
;=======================================================;
Enable_port:                            ; -> habilita o GPIO da porta R0 
        LDR R2, =SYSCTL_RCGCGPIO_R      ; carrega o valor de SYSCTL_RCGCGPIO_R em R2
        LDR R1, [R2]                    ; carrega o valor que R2 "aponta" em R1
        ORR R1, R0                      ; operação de OU com R1 e R0
        STR R1, [R2]                    ; carrega o valor de R1 em R2
check      
        LDR R2, =SYSCTL_PRGPIO_R        ; carrega SYSCTL_PRGPIO_R em R2
        LDR R1, [R2]                    ; carrega o valor que R2 "aponta" em R1
        TST R1, R0                      ; verifica se o clock esta ativo
        BEQ check                       ; se ainda nao estiver ativo volta para check
        BX LR                           ; se estiver volta para chamada

;===============================================================================;
;       -> Habilita o GPIO que estiver na porta R0                              ;
;       -> Input: R0, R1                                                        ;
;          R0 -> endereco base da porta a ser habilitada                        ;
;          R1 -> contem os bits da porta que poderam ser acessados              ;
;       -> Aux:   R2                                                            ;
;===============================================================================;
Enable_GPIO_output:
        LDR R2, [R0, #GPIO_DIR]         ; R2 = [R0 + #GPIO_DIR]
        ORR R2, R1                      ; R2 ou R1 e salva em R2
        STR R2, [R0, #GPIO_DIR]         ; [R0 + #GPIO_DIR] = R2 
        
        LDR R2, [R0, #GPIO_DEN]         ; R2 = [R0 + #GPIO_DEN]
        ORR R2, R1                      ; R2 ou R1 e salva em R2
        STR R2, [R0, #GPIO_DEN]         ; [R0 + #GP IO_DEN] = R2 
        
        BX LR
        
;===============================================================================;
;       -> Escreve a saida digital na porta R0                                  ;
;       -> Input: R0, R1, R2                                                    ;
;          R0 -> endereco base da porta a ser habilitada                        ;
;          R1 -> contem os bits da porta que poderam ser acessados - "mascara"  ;
;          R2 -> valor a ser escritos nas portas indicadas aptas por R1         ;
;===============================================================================;
Digital_write:
        STR R2, [R0, R1, LSL #2]
        BX LR
        
 ;===============================================================================;
;       -> Escreve 0 em todos os bits da porta R0                                ;
;       -> Input: R0, R1, R2                                                     ;
;          R0 -> endereco base da porta a ser habilitada                         ;
;          R1 -> contem os bits da porta que poderam ser acessados - "mascara"   ;
;          R2 -> valor a ser escritos nas portas indicadas aptas por R1          ;
;================================================================================;
Digital_write_low:
        PUSH {R2}
        MOV R2, #000000000b
        STR R2, [R0, R1, LSL #2]
        POP {R2}
        BX LR

;===============================================================================;
;       -> decrementa o valor contido em R0                                     ;
;       -> Input: R0                                                            ;
;          R0 -> "tempo" de delay                                               ;
;===============================================================================;
Delay:
        PUSH {R0}
        MOVT R0, #(DELAY)
Delay_loop
        CBZ R0, finish_daley
        SUB R0, R0, #1
        B Delay_loop
finish_daley:
        POP {R0}
        BX LR
        
;===============================================================================;
;       -> Liga os leds no valor binario                                        ;
;       -> Input: R3                                                            ;
;       -> Liga os leds no valor binario                                        ;
;       -> Liga os leds no valor binario                                        ;
;===============================================================================;
binary_led:
        ;; leds da porta n
        PUSH {LR, R2, R4}
        AND R2, R3, #0011b
        LSR R4, R2, #1
        LSL R2, R2, #1
        ADD R2, R4
        LDR R0, =GPIO_PORTN_BASE
        MOV R1, #000000011b
        BL Digital_write
        

        ;; leds da porta f
        AND R4, R3, #0100b
        LSL R2, R4, #2
        AND R4, R3, #1000b
        LSR R4, R4, #3
        ADD R2, R4
        
        LDR R0, =GPIO_PORTF_BASE
        MOV R1, #000010001b
        BL Digital_write
        POP {R4, R2}
        BL Delay
        POP {LR}
        BX LR
        
        

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
