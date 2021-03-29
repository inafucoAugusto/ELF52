        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
; main program begins here
; -> A ideia é decompor um número (R1) em potencias de 2 e deslocar n bits,
; onde n é o expoente de 2, o valor de R0.
; Ex.: R0=14, R1=13
; R1(binario) = 1101 = s^3+2^2+2^0
; Cada valor de expoente contido na equação acima é o numero de bits deslocados
; de R0 para que se tenha o resultado;
; R2 = R0*R1 = R0(<<3)+R0(<<2)+R0(<<0)
  
main    MOV R0, #14
        MOV R1, #13
        PUSH {R1}
        BL Mul16b
        MOV R0, #0x0001

Mul16b:
        MOV R2, R0
operacao
        CMP R1, #0
        BEQ bla
        LSRS R1, R1, #1         ; -> Deslocando r1 para a direita
        ITT CS                  ; -> So vai realizar a operação de deslocamento de o carry for igual 
          LSLCS R4, R0, R3      ; a 1
          ADDCS R2, R2, R4
        ADD R3, R3, #1          ; -> Valor do expoente s^n
        B operacao
bla
        SUBS R2, R0
        POP {R1}
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
