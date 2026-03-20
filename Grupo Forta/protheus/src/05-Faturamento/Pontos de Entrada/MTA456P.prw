#include 'protheus.ch'
#include 'parmtype.ch'



/*/{Protheus.doc} MTA456P
// Ponto de Entrada ao Liberar Crédito de Pedidos
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return lRet,Logical
@type User Function
/*/
User function MTA456P()
	
	Local	aAreaOld	:= GetArea()
	Local	nOpcLib		:= ParamIxb[1]
	Local	nReturn		:= 0
	Local	cPed    	:= SC9->C9_PEDIDO
	
	If nOpcLib	== 3 	// Rejeita
	
		// Grava Log
		U_MLCFGM01("LR",cPed,,FunName())
		
	ElseIf nOpcLib == 4 // Libera Todos
	
		// Grava Log
		U_MLCFGM01("LC",cPed,,FunName())
		
	Endif
	RestArea(aAreaOld)
	
Return nReturn > 0