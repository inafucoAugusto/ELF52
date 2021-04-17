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


__iar_program_start
        
;; main program begins here
main    MOV R0, #(PORTN_BIT)
        BL Enable_port                 ; habilita a porta n

        LDR R0, =GPIO_PORTN_BASE        ; carrega o valor (endereço de memoria) GPIO_PORTN_BASE em R0
        MOV R1, #000000011b             ; coloca o valor de 0011b em binario no registrador R1    
        BL Enable_GPIO_output           ; esse valor 0011b indica quais bits da porta n poderam ser acessados
                                        ; os bits 0 e 1 são os bits dos leds da placa
        
        LDR R0, =GPIO_PORTN_BASE        ; linha repetida
        MOV R1, #000000011b             ; máscara dos LEDs D1 e D2 -> indica que apenas os bits 0x0011b do registrador poderao ser usados
                                        ; aqui vc passa os mesmos bits que estarao abilitados na sua porta
        MOV R2, #000000001b             ; padrão de acionamento    -> os valores que quer escrever nesses bits


loop:   BL Digital_write                ; aciona LEDs D1 e D2

        PUSH {R0}
        MOVT R0, #0x003F
        BL Delay                        ; atraso (determina frequência de acionamento)
        POP {R0}
        
        EOR R2, R2, #11b                ; OU exclusivo -> 0||1 = 1, 0||0=0, 1||1=0
        B loop


Enable_port:                           ; -> habilita o GPIo da porta N %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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


Enable_GPIO_output:
        LDR R2, [R0, #GPIO_DIR]         ; R2 = [R0 + #GPIO_DIR]
        ORR R2, R1                      ; R2 ou R1 e salva em R2
        STR R2, [R0, #GPIO_DIR]         ; [R0 + #GPIO_DIR] = R2 
        
        LDR R2, [R0, #GPIO_DEN]         ; R2 = [R0 + #GPIO_DEN]
        ORR R2, R1                      ; R2 ou R1 e salva em R2
        STR R2, [R0, #GPIO_DEN]         ; [R0 + #GPIO_DEN] = R2 
        
        BX LR
        
Digital_write:
        STR R2, [R0, R1, LSL #2]        ; R1 = 0x00000003 ou 0011b -> R1, LSL #2 = 0x0000000C ou 1100
                                        ; [R0 + 0x0000000C] = [40064003] = R2
        BX LR
        
Delay:
        CBZ R0, finish_daley
        SUB R0, R0, #1
        B Delay
finish_daley:
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
