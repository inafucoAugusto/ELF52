        PUBLIC  __iar_program_start
        EXTERN  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608                  
SYSCTL_RCGCGPIO_R       EQU     0x400FE608              ; Run-mode Clock Gating -> Inicializacao -> Habilita clock
SYSCTL_PRGPIO		EQU     0x0A08          
SYSCTL_PRGPIO_R		EQU     0x400FEA08              ; Peripheral Ready      -> Inicializacao -> Indica se a porta GPIO está pronta para uso
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
; System Control bit definitions
PORTA_BIT               EQU     000000000000001b        ; Define quantos bits que pode se escrever na porta a -> datasheet
PORTF_BIT               EQU     0000000000100000b       ; Define quantos bits que pode se escrever na porta f -> datasheet
PORTJ_BIT               EQU     0000000100000000b       ; Define quantos bits que pode se escrever na porta j -> datasheet
PORTN_BIT               EQU     0001000000000000b       ; Define quantos bits que pode se escrever na porta n -> datasheet
UART0_BIT               EQU     00000001b               ; Define quantos bits que pode se escrever na porta o -> datasheet

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400                  ; GPIO_DIR (Direction) -> entrada ou saida
GPIO_IS                 EQU     0x0404                  ; borda ou nivel
GPIO_IBE                EQU     0x0408                  ; borda
GPIO_IEV                EQU     0x040C                  ; borda de subida ou descida
GPIO_IM                 EQU     0x0410                  ; habilitar interrupcao
GPIO_RIS                EQU     0x0414                  ; indica se houve condicoes para interrup. mesmo sem GPIO_IM 
GPIO_MIS                EQU     0x0418                  ; indica se houve cond para ativar interrup. e a mesma esta declarada em GPIO_IM
GPIO_ICR                EQU     0x041C                  ; ACK da interrupcao -> precisa dela para poder realizar uma nova interrup.
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C                  ; GPIO_DEN (Digital Enable) -> Habilitar funcao digital
GPIO_PCTL               EQU     0x052C

; UART definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8

;UART bit definitions
TXFE_BIT                EQU     10000000b               ; TX FIFO full
RXFF_BIT                EQU     01000000b               ; RX FIFO empty
BUSY_BIT                EQU     00001000b               ; Busy

; Tempo de delay
DELAY                    EQU     0x005F                 ; tempo de delay

; PROGRAMA PRINCIPAL

__iar_program_start

;; ideias
;; - r3 tem primeiro numero
;; - r4 tem a operação
;; - r5 tem o segundo numero
;; func para realzir operação e jogar direto no terminal, usar p9lha para alocar memoresa
;; - r6 como aux para saber expoente do numero
;; - r10 -> conta quantos digito tem essa porra
;; - r11 -> flag aux para positivo e div por zero -> 1 negativo, 2 -> div por zero

main:   
        MOV R2, #(UART0_BIT)
	BL UART_enable                                  ; habilita UART0

        MOV R0, #(PORTA_BIT)
	BL Enable_port                                  ; habilita clock ao port A -> GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b                              ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF                                   ; máscara das funções especiais no port A (bits 1 e 0)
        MOV R2, #0x11                                   ; funções especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R2, =UART_PORT0_BASE
        BL UART_config                                  ; configura periférico UART0

        LDR R0, =UART_PORT0_BASE                        ; nao lembro para o que servia
        
                                                        ; recepção e envio de dados pela UART utilizando sondagem (polling)
                                                        ; resulta em um "eco": dados recebidos são retransmitidos pela UART
loop:
        BL Reset_all
Make_num1:
        BL Serial_read
        MOV R6, R3
        
        CMP R1, #61
        IT NE
          BLNE Serial_write
        ITT EQ
          BLEQ New_line
          BEQ loop
          
        BL Check_operation                               
        CMP R4, #0
        ITT HI
        MOVHI R10, #0
        BHI Make_num2
        
        CMP R10, #4                                      ; menor que 4 digitos
        ITT PL
          BLPL New_line
          BPL loop
        ITTT LO
          BLLO Make_number                              ; r6 = r3*10+r1 // R10++
          MOVLO R3, R6                                  ; r3 = r6
          BLO Make_num1

Make_num2:
        CMP R10, #4
        ITTT PL
          BLPL Calculate
          BLPL New_line
          BPL loop

        BL Serial_read
        MOV R6, R5
        
        CMP R1, #61
        ITTT EQ
                                                        ; todo: fazerr função para inprimir numero usando div
          BLEQ Calculate                                ; Dentro da func que printa o resutado
          BLEQ New_line
          BEQ loop
          
        ;; TODO: EVITAR NOVAS OPERAÇÕES
          
        CMP R10, #4                                      ; menor que 4 digitos
        ITTTT LO
          BLLO Serial_write
          BLLO Make_number                              ; r6 = r5*10+r1 // R10++
          MOVLO R5, R6                                  ; r5 = r6
          BLO Make_num2

        B loop  

;===============================================================================;
;===============================================================================;
Serial_read:
        LDR R2, [R0, #UART_FR]                          ; status da UART
        TST R2, #RXFF_BIT                               ; Verifica se o receptor 
        BEQ Serial_read
        LDR R1, [R0]                                    ; Le a resial e joga em R1
        BX LR
;===============================================================================;
;===============================================================================;
Serial_write:    
        LDR R2, [R0, #UART_FR]                          ; status da UART
        TST R2, #TXFE_BIT                               ; transmissor vazio?
        BEQ Serial_write
        
        STR R1, [R0]                                    ; escreve no registrador de dados da UART0 (transmite)
        BX LR

;===============================================================================;
;                  -> Habilita UART que estiver no registrador R2               ;
;                  -> Input: R2                                                 ;
;                  -> Aux:   R0, R1                                             ;
;===============================================================================;
UART_enable:                                            ; -> habilita UART0
        PUSH {R0, R1}
        LDR R0, =SYSCTL_BASE                            ; carrega o valor de SYSCTL_BASE em R0
	LDR R1, [R0, #SYSCTL_RCGCUART]                  ; R1 = [R0 + #SYSCTL_RCGCUART]
	ORR R1, R2                                      ; R2 ou R1 e salva em R1
	STR R1, [R0, #SYSCTL_RCGCUART]                  ; [R0, #SYSCTL_RCGCUART] = R1

waitu	LDR R1, [R0, #SYSCTL_PRUART]                    ; R1 = [R0 + #SYSCTL_PRUART]
	TEQ R1, R2                                      ; Verifica se clock da UART0 está abilitado
	BNE waitu
        
return_UART_enable
        POP {R1}
        POP {R0}
        BX LR

;===============================================================================;
;                  -> Configuracao da UART que estiver no registrador R2        ;
;                  -> Input: R2                                                 ;
;                  -> Aux:   R1                                                 ;
;===============================================================================;
UART_config:
        PUSH {R1}
        LDR R1, [R2, #UART_CTL]                         ; R1 = [R0 + #SYSCTL_RCGCUART]
        BIC R1, #0x01                                   ; desabilita UART (bit UARTEN = 0)
        STR R1, [R2, #UART_CTL]                         ; [R2, #UART_CTL] = R1

        ; clock = 16MHz, baud rate = 9600 bps
        MOV R1, #69                                    ; R1 = #69
        STR R1, [R2, #UART_IBRD]                        ; [R2, #UART_IBRD] = R1
        MOV R1, #29                                     ; R1 = #29
        STR R1, [R2, #UART_FBRD]                        ; [R2, #UART_FBRD] = R1
        
        ; 8 bits, 1 stop, no parity, FIFOs disabled, no interrupts
        MOV R1, #0x60                                   ; R1 = #0x60
        STR R1, [R2, #UART_LCRH]                        ; [R2, #UART_LCRH] = R1
        
        ; clock source = system clock
        MOV R1, #0x00                                   ; R1 = #0x00   
        STR R1, [R2, #UART_CC]                          ; [R2, #UART_CC] = R1
        
        LDR R1, [R2, #UART_CTL]                         ; R1 = [R2, #UART_CTL] 
        ORR R1, #0x01                                   ; R1 = R1 OU R0 -> habilita UART (bit UARTEN = 1)
        STR R1, [R2, #UART_CTL]                         ; [R2, #UART_CTL] = R1
        
        POP {R1}
        BX LR

;===============================================================================;
;                -> Habilita a função especial do GPIO no registrador R0        ;
;                -> Input: R0, R1                                               ;
;                -> Aux:   R2                                                   ;
;===============================================================================;
GPIO_special:
        PUSH {R2}
	LDR R2, [R0, #GPIO_AFSEL]                       ; R2 = [R0, #GPIO_AFSEL]
	ORR R2, R1                                      ; R2 = R2 ou R1            
	STR R2, [R0, #GPIO_AFSEL]                       ; [R0, #GPIO_AFSEL] = R2

	LDR R2, [R0, #GPIO_DEN]                         ; R2 = [R0, #GPIO_DEN]
	ORR R2, R1                                      ; R2 = R2 ou R1 
	STR R2, [R0, #GPIO_DEN]                         ; [R0, #GPIO_DEN] = R2

        POP {R2}
        BX LR

;===============================================================================;
;                -> Seleciona a função especial do GPIO no registrador R0       ;
;                -> Input: R0, R1                                               ;
;                -> Aux:   R3                                                   ;
;===============================================================================;
GPIO_select:
        PUSH {R3}
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]
        POP {R3}
        BX LR

;===============================================================================;
;                  -> Habilita o GPIO que estiver na porta R0                   ;
;                  -> Input: R0                                                 ;
;                  -> Aux:   R1, R2                                             ;
;===============================================================================;
Enable_port:                                            ; -> habilita o GPIO da porta R0
        PUSH {R1, R2}
        LDR R2, =SYSCTL_RCGCGPIO_R                      ; carrega o valor de SYSCTL_RCGCGPIO_R em R2
        LDR R1, [R2]                                    ; carrega o valor que R2 "aponta" em R1
        ORR R1, R0                                      ; operação de OU com R1 e R0
        STR R1, [R2]                                    ; carrega o valor de R1 em R2
check      
        LDR R2, =SYSCTL_PRGPIO_R                        ; carrega SYSCTL_PRGPIO_R em R2
        LDR R1, [R2]                                    ; carrega o valor que R2 "aponta" em R1
        TST R1, R0                                      ; verifica se o clock esta ativo
        BEQ check                                       ; se ainda nao estiver ativo volta para check

return_Enable_port
        POP {R2}
        POP {R1}
        BX LR                                           ; se estiver volta para chamada

;===============================================================================;
;       recebe um numero base + um numero para colocar no final   
;       R1-> CONTEM O PROXIMO NUMERO
;       R6-> recebe r3 ou r4
;===============================================================================;
Make_number:
        PUSH {R7, R8}
        MOV R8, #0x30
        MOV R7, #10
        MUL R6, R6, R7
        SUB R1, R1, R8
        ADD R6, R6, R1
        ADD R10, R10, #1
        POP {R7, R8}
        BX LR

;===============================================================================;
;               -> Printa na serial o valor contido em r1                                              
;               -> r7, r8 E r9 como aux PARA OPERAÇÕES
;               -> 
;===============================================================================;
Show_result:
        PUSH {LR}
        PUSH {R7, R8}                                   ; Conserva os registradores

        MOV R7, #0xaa                                   ; Dado de stop para pilha
        PUSH {R7}                                       ; aplica na pilha o stop  
        MOV R7, #10

        CMP R11, #2
        ITTT EQ
          MOVEQ R1, #69                                 ; Em hexa - 'E' (0x45) eh sem graça
          PUSHEQ {R1}
          BEQ Print_result
        
        CMP R11, #1                                     ; compara com a flag
        ITTTT EQ
          PUSHEQ {R1}
          MOVEQ R1, #45                                 ; printa '-'
          BLEQ Serial_write
          POPEQ {R1}
        
        CMP R1, #0
        ITTT EQ
        ADDEQ R1, R1, #0x30
        PUSHEQ {R1}
        BEQ Print_result
        
Decomposition:
        CMP R1, #0
        BEQ Print_result
        
        UDIV R8, R1, R7
        MUL R9, R8, R7 
        SUB R9, R1, R9
        ADD R9, R9, #0x30
        PUSH {R9}
        MOV R1, R8
        B Decomposition

Print_result
        POP {R1}
        CMP R1, #0xaa
        IT EQ
        BEQ End_show_result
        BL Serial_write
        B Print_result

End_show_result:
        POP {R7, R8}
        POP {PC}

;===============================================================================;
;                                             
;===============================================================================;
New_line:
        PUSH {R1, LR}
        MOV R1, #10
        BL Serial_write
        MOV R1, #13
        BL Serial_write
        POP {R1, PC}

;===============================================================================;
;               -> Reseta todas as variáveis do ambiente                                           
;===============================================================================;
Reset_all:
       MOV R1, #0
       MOV R2, #0
       MOV R3, #0
       MOV R4, #0
       MOV R5, #0
       MOV R6, #0
       MOV R10, #0
       MOV R11, #0
       BX LR
;===============================================================================;
;               -> Reseta todas as variáveis do ambiente                                           
;===============================================================================;
Check_operation:
        CMP R1, #42                             ; MULTIPICACAO
        ITT EQ
          MOVEQ R2, #0
          MOVEQ R4, #1
          
        CMP R1, #43                             ; SOMA
        ITT EQ
          MOVEQ R2, #0
          MOVEQ R4, #2
          
        CMP R1, #45                             ; SUB
        ITT EQ
          MOVEQ R2, #0
          MOVEQ R4, #3
          
        CMP R1, #47                             ; DIV
        ITT EQ
          MOVEQ R2, #0
          MOVEQ R4, #4
        BX LR
;===============================================================================;
;               -> axecuta a operação de r4 entre r3 e r5                                            
;               -> resposta da operação fica em r1
;===============================================================================;
Calculate
        PUSH {LR}
        
        MOV R1, #61
        BL Serial_write
        
        CMP R4, #1                             ; MULTIPICACAO
        IT EQ
          MULEQ R1, R3, R5
          
        CMP R4, #2                             ; SOMA
        IT EQ
          ADDEQ R1, R3, R5
          
        CMP R4, #3                             ; SUB
        IT EQ
          BLEQ Execute_sub
          
        CMP R4, #4                             ; DIV
        IT EQ
          BLEQ Execute_div

        BL Show_result

        POP {PC}
        
;===============================================================================;
;===============================================================================;
Execute_sub:  
        SUBS R1, R3, R5
        ITTT MI
          MOVMI R11, #1
          MVNMI R1, R1
          ADDMI R1, R1, #1
        BX LR
     
;===============================================================================;
;===============================================================================;
Execute_div:
        UDIV R1, R3, R5
        CMP R5, #0
        IT EQ
          MOVEQ R11, #2
        BX LR

      
        END
