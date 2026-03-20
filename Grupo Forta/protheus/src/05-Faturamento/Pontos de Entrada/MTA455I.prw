#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MTA455I
//  Ponto de Entrada ao liberar estoque de pedido
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return lRet, Logical
@type User Function
/*/
User function MTA455I()
	Local	lRet	:= .T. 
	
	// Grava Log de Pedido
	U_MLCFGM01("LE",SC9->C9_PEDIDO,,FunName())
	
Return lRet