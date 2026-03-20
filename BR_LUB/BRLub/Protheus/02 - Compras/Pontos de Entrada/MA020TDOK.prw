#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MA020TDOK
//Validação do cadastro de fornecedor
@author Marcelo Alberto Lauschner
@since 19/06/2017
@version 6

@type function
/*/
User function MA020TDOK()
	
	Local	lRet	:= .T.
	// Efetua a chamada da função que atualiza o código e loja
	lRet	:= U_A020CGC()
	
	
Return lRet