
/*/{Protheus.doc} M440STTS
Ponto de entrada na Liberação do Pedido de Venda 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/04/2022
@return variant, return_description
/*/
User Function M440STTS()

    // Grava Log
	U_DCCFGM02("LP",SC5->C5_NUM,"",FunName())

Return
