        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
;; main program begins here
main    MOV R0, #13
        BL Fatorial
        B Stop
 
;###############################################;
;                  Fatorial                     ;
;       - Entrada:      R0                      ;
;       - Saída:        R0                      ;
;       - Auxiliares: R1, R3                    ;
;###############################################;
Fatorial
        PUSH {R1, R3}
        MOV R1, R0
        CMP R1, #0              ; -> Usado para apenas evitar o caso de 0!
        ITTT EQ                  ; 0! = 1
          MOVEQ R0, #1
          POPEQ {R1, R3}
          BXEQ LR
        SUB R1, #1              ; -> Cria um aux, aux=r0-1, como valor inicial de um fatorial
loop_Fatorial
        CMP R1, #1
        ITT EQ
          POPEQ {R1, R3}
          BXEQ LR
        MULS R0, R1             ; -> r0:=r0*r1
        ADDS R3, R0, R0         ; -> Verefica se o valor atual, contido em r0, multiplicado por 2
        ITTT VS                 ; var dar overflow - 2 é o "menor" valor a ser multiplicado
          MOVVS R0, #-1         ; -> O valor de R0 fica em -1, pois "estoura" o limite de 32 bits
          POPVS {R1, R3}
          BXVS LR
        SUB R1, #1              ; -> Subtrai o valor do aux em 1 para que r0 seja multiplicado pelo mesmo
        B loop_Fatorial
Stop
        B Stop
        
        
        
        
        ;; main program ends here
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
