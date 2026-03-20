#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} A410EXC
// Ponto de Entrada para Grava Log de Exclusão do Pedido de Venda. 
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return Logical 
@type User Function
/*/
User function A410EXC()
	
Return U_MLCFGM01("EP",SC5->C5_NUM,,FunName(),.T.)[2]