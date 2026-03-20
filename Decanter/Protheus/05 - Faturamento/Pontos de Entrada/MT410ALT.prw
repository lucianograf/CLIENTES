/*/{Protheus.doc} MT410ALT
Ponto de entrada ao alterar pedido de Venda 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/04/2022
@return variant, return_description
/*/
User Function MT410ALT()

	// Grava Log
	U_DCCFGM02("AP",SC5->C5_NUM,"",FunName())

Return
