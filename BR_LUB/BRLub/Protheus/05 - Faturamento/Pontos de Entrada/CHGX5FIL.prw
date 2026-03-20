#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} CHGX5FIL
// Ponto de entrada que Permite alterar a Filial para posicionar na SX5 
@author Marcelo Alberto Lauschner
@since 27/10/2019
@version 1.0
@return cFilRet, Código da filial para pegar o número da nota na SX5
@type function
/*/
User function CHGX5FIL()
	
	Local	cFilRet	 := xFilial("SX5")
	
	// Se o SX5 for compartilhado, efetua verificação pela Filial posicionada 
	If Empty(cFilRet)
		cFilRet		:= cFilAnt
	Endif
	
Return cFilRet