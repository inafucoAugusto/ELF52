Projeto desenvolvido para a disciplina de sistemas microcontrolados.

---------------------------------------------------------------------
		      Utilização dos registradores
- R1:  Leitura da serial.
- R2:  Aux na leitura da serial -> com a utilização de pilha é possível implementar essa variável ao longo do cód.
- R3:  Armazena o primeiro número.
- R4:  Armazena a operação.
- R5:  Armazena o primeiro número.
- R6:  Armazena o resultado da função Make_number. (*)
- R7:  Armazena flag para NAN (not a number). (**)
- R9:  Somente auxiliar.
- R10: Armazena quantos dígitos o número já tem.
- R11: Flag para indicar div por zero ou valor negativo. (***)

(*)   -  Make_number é uma função que concatena a leitura da serial, quando for um número, com o valor passado por 
         R6. O resultado da função é retornado no próprio registrador de entrada, logo, para transmitir o resultado
         para o registrador final desejado será necessário o uso de um MOV R<dst>, R6. Por esse motivo para a utilização 
         da pilha é necessária caso queira usar o registrador R6 para outra finalidade.

(**)  -  Se o input do serial for um número NAN retorna 0 em R7, caso contrário retorna 1

(***) -  Se a divisão for por zero R11 := 2. Se o resultado da subtração entre dois valores for negativa R11 := 1

OBS: Os registradores R7 e R11 também são passivos de uso, porém necessitam do mesmo tratamento de (*)

---------------------------------------------------------------------
		Configuração do Tera Term para o uso

- Para a utilização do programa é preciso realizar algumas configurações na serial.

	Setup -> Serial port

Ao abrir a janela, configurar seguintes parâmetros:

	Port:      Porta a qual a placa está conectada
	Speed:     14400
	Data:      7 bit
	Parity:    even
	Stop Bits: 1 bit

Com isso já deve ser suficiente para o uso.

---------------------------------------------------------------------
			      Modo de uso

- A calculadora aceita operando de apenas 4 dígitos.
 
- Se o usuário digitar os 4 dígitos, o programa irá ignorar qualquer outra leitura até que
o input seja uma operação (+, -, *, /).

- Caso o primeiro número não tenha 4 dígitos, após a entrada da operação o próprio software
encerra o primeiro número e já recebe o segundo operando.

- Se o segundo operando tiver 4 dígitos o próprio programa gera o resultado final, não há
necessidade de requisição de resultado.

- Se o segundo operando não tiver 4 dígitos e o usuário quiser a resposta basta digitar "="
como entrada

- Se a operação for invalida será retornado um erro do tipo "E"

- Para se cancelar a operação basta dar como entrada "C"

- Se for realizada alguma operação sem a entrada de um dos números, o programa irá considerá-los 
Ex.:
	- 1-=1
        - 1/=E
	- 1*=0
	- 1+=0	
 
---------------------------------------------------------------------
				TODO

- Acrescentar lógica para salvar o ultimo resultado em "A" para reutilizar em operações futuras
- Acionar leds da placa conforme input do usuário
- Botão da placa como interrupção para cancelar a operação e limpar o serial



















