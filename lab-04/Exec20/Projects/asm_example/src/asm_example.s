        PUBLIC  __iar_program_start
        PUBLIC  GPIOJ_Handler
        EXTERN  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

;=========================================================================;
;       - Os registradores das portas sao acessados por meio de LDR e STR ;
;       - tabela 10-7 pagina 757                                          ;
;=========================================================================;

SYSCTL_RCGCGPIO_R       EQU     0x400FE608              ; Run-mode Clock Gating -> Inicializacao -> Habilita clock
SYSCTL_PRGPIO_R         EQU     0x400FEA08              ; Peripheral Ready      -> Inicializacao -> Indica se a porta GPIO está pronta para uso
PORTF_BIT               EQU     0000000000100000b       ; Define que pode se escrever 5bits na porta f -> datasheet
PORTJ_BIT               EQU     0000000100000000b       ; Define que pode se escrever 8bits na porta j -> datasheet
PORTN_BIT               EQU     0001000000000000b       ; Define que pode se escrever 8bits na porta n -> datasheet

; declaração dos pinos GPIO -> pg 755, 756, 757, 759 datasheet
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400                  ; GPIO_DIR (Direction) -> entrada ou saida
GPIO_PUR                EQU     0x0510  
GPIO_DEN                EQU     0x051C                  ; GPIO_DEN (Digital Enable) -> Habilitar funcao digital
GPIO_ICR                EQU     0x041C                  ; ACK da interrupcao -> precisa dela para poder realizar uma nova interrup.
GPIO_IS                 EQU     0x0404                  ; borda ou nivel
GPIO_IBE                EQU     0x0408                  ; borda
GPIO_IEV                EQU     0x040C                  ; borda de subida ou descida
GPIO_IM                 EQU     0x0410                  ; habilitar interrupcao
GPIO_RIS                EQU     0x0414                  ; indica se houve condicoes para interrup. mesmo sem GPIO_IM 
GPIO_MIS                EQU     0x0418                  ; indica se houve cond para ativar interrup. e a mesma esta declarada em GPIO_IM

; definicoes NVIC
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
NVIC_UNPEND1            EQU     0x0284
NVIC_PRI12              EQU     0x0430

; Bits para controle dos leds
LEDN_1                   EQU     00010b
LEDN_2                   EQU     00001b
LEDF_2                   EQU     00001b
LEDF_1                   EQU     10000b

; Tempo de delay
DELAY                    EQU     0x005F

;=======================================================;
;       -> Interrupacao da porta J                      ;
;       -> Interrupt: POTJ - 0011b                      ;
;       -> Aux:       R3                                ;
;       -> Retorno:   R11                               ;
;=======================================================;
GPIOJ_Handler:
        PUSH {R3}

        MOV R0, #00000011b
        LDR R1, =GPIO_PORTJ_BASE
        STR R0, [R1, #GPIO_ICR]

        LDR R3, [R1, #GPIO_MIS]                         ; verifica se a interrup foi pela porta 01b
        CMP R3, #0001b
        IT EQ
          ADDEQ R11, R11, #1

        CMP R3, #0010b                                  ; verifica se a interrup foi pela porta 10b
        IT EQ
          SUBEQ R11, R11, #1
          
        POP {R3}
        BX LR

__iar_program_start
        
;; main program begins here
main    MOV R0, #(PORTN_BIT)
        BL Enable_port                                  ; habilita a porta n

        MOV R0, #(PORTF_BIT)
        BL Enable_port                                  ; habilita a portra f

        MOV R0, #(PORTJ_BIT)
        BL Enable_port                                  ; habilita a portra j

        LDR R0, =GPIO_PORTN_BASE                        ; Endereço de memoria base da porta N
        MOV R1, #000000011b                             ; bits a seram habilitados da porta N    
        BL Enable_GPIO_output                           ; habilita os bits 0 e 1 da porta N
        BL Digital_write_low

        LDR R0, =GPIO_PORTF_BASE                        ; Endereço de memoria base da porta J
        MOV R1, #000010001b                             ; bits a seram habilitados da porta J    
        BL Enable_GPIO_output                           ; habilita os bits 0 e 4 da porta J
        BL Digital_write_low

        LDR R0, =GPIO_PORTJ_BASE                        ; Endereço de memoria base da porta J
        MOV R1, #000000011b                             ; bits a seram habilitados da porta J    
        BL Enable_digital_input                         ; habilita os bits 0 e 4 da porta J
        BL Digital_write_low
        
        BL Button_int_conf
      
        MOV R3, #0                                      ; Variavel usada como contador

loop:   
        MOV R3, R11
        BL binary_led
        B loop

;=======================================================;
;       -> Habilita o GPIO que estiver na porta R0      ;
;       -> Input: R0, R1                                ;
;       -> Aux:   R2                                    ;
;=======================================================;
Enable_port:                                            ; -> habilita o GPIO da porta R0 
        LDR R2, =SYSCTL_RCGCGPIO_R                      ; carrega o valor de SYSCTL_RCGCGPIO_R em R2
        LDR R1, [R2]                                    ; carrega o valor que R2 "aponta" em R1
        ORR R1, R0                                      ; operação de OU com R1 e R0
        STR R1, [R2]                                    ; carrega o valor de R1 em R2
check      
        LDR R2, =SYSCTL_PRGPIO_R                        ; carrega SYSCTL_PRGPIO_R em R2
        LDR R1, [R2]                                    ; carrega o valor que R2 "aponta" em R1
        TST R1, R0                                      ; verifica se o clock esta ativo
        BEQ check                                       ; se ainda nao estiver ativo volta para check
        BX LR                                           ; se estiver volta para chamada

;===============================================================================;
;       -> Habilita o GPIO que estiver na porta R0                              ;
;       -> Input: R0, R1                                                        ;
;          R0 -> endereco base da porta a ser habilitada                        ;
;          R1 -> contem os bits da porta que poderam ser acessados              ;
;       -> Aux:   R2                                                            ;
;===============================================================================;
Enable_GPIO_output:
        LDR R2, [R0, #GPIO_DIR]                         ; R2 = [R0 + #GPIO_DIR]
        ORR R2, R1                                      ; R2 ou R1 e salva em R2
        STR R2, [R0, #GPIO_DIR]                         ; [R0 + #GPIO_DIR] = R2 
        
        LDR R2, [R0, #GPIO_DEN]                         ; R2 = [R0 + #GPIO_DEN]
        ORR R2, R1                                      ; R2 ou R1 e salva em R2
        STR R2, [R0, #GPIO_DEN]                         ; [R0 + #GP IO_DEN] = R2 
        BX LR

;===============================================================================;
;       -> Habilita o GPIO que estiver na porta R0                              ;
;       -> Input: R0, R1                                                        ;
;          R0 -> endereco base da porta a ser habilitada                        ;
;          R1 -> contem os bits da porta que poderam ser acessados              ;
;===============================================================================;
Enable_digital_input:
        LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1                                      ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1                                      ; declara função como digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1                                      ; "ativa" resitor de pull-up
	STR R2, [R0, #GPIO_PUR]
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
;       -> Escreve a leitura digital na porta R2                                ;
;       -> Input: R0, R1                                                        ;
;          R0 -> endereco base da porta a ser lida                              ;
;          R1 -> contem os bits da porta que poderam ser acessados - "mascara"  ; 
;===============================================================================;
Digital_read:
        LDR  R2, [R0, R1, LSL #2]
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
        
Button_int_conf:
        MOV R2, #000000011b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        BIC R0, R0, R2 ; desabilita interrup.
        STR R0, [R1, #GPIO_IM]
        
        LDR R0, [R1, #GPIO_IS]
        BIC R0, R0, R2 ; interrup por transicao
        STR R0, [R1, #GPIO_IS]
        
        LDR R0, [R1, #GPIO_IBE]
        BIC R0, R0, R2 ; uma transi??o apenas
        STR R0, [R1, #GPIO_IBE]
        
        LDR R0, [R1, #GPIO_IEV]
        BIC R0, R0, R2 ; transi??o de descida
        STR R0, [R1, #GPIO_IEV]
        
        LDR R0, [R1, #GPIO_ICR]
        ORR R0, R0, R2 ; limpeza de pend?ncias
        STR R0, [R1, #GPIO_ICR]
        
        LDR R0, [R1, #GPIO_IM]
        ORR R0, R0, R2 ; habilita interrup??es no port GPIO J
        STR R0, [R1, #GPIO_IM]

        MOV R2, #0xE0000000 ; prioridade mais baixa para a IRQ51
        LDR R1, =NVIC_BASE
        
        LDR R0, [R1, #NVIC_PRI12]
        ORR R0, R0, R2 ; define prioridade da IRQ51 no NVIC
        STR R0, [R1, #NVIC_PRI12]

        MOV R2, #10000000000000000000b ; bit 19 = IRQ51
        MOV R0, R2 ; limpa pend?ncias da IRQ51 no NVIC
        STR R0, [R1, #NVIC_UNPEND1]

        LDR R0, [R1, #NVIC_EN1]
        ORR R0, R0, R2 ; habilita IRQ51 no NVIC
        STR R0, [R1, #NVIC_EN1]
        
        BX LR

        END