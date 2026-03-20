#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} M440STTS
// Ponto de entrada na liberação do pedido de venda
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return Nil
@type User Function
/*/
User function M440STTS()
	
	U_MLCFGM01("LP",SC5->C5_NUM,"",FunName())
	
Return