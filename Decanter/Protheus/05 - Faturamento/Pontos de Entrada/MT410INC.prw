/*/{Protheus.doc} MT410INC
Ponto de entrada ao incluir pedido de venda
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/04/2022
@return variant, return_description
/*/
User Function MT410INC()
	// Grava Log
	U_DCCFGM02("IP",SC5->C5_NUM,"",FunName())

Return
