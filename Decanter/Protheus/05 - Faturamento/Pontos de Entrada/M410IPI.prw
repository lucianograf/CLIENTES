#Include "Protheus.ch"
#Include "TbiConn.ch"

/*/{Protheus.doc} M410IPI 
M460IPI - Retorno do valor de IPI na planilha financeira do pedido de venda
Variaveis disponiveis: VALORIPI  BASEIPI  QUANTIDADE  ALIQIPI  BASEIPIFRETE
@type function
@author Vamilly - Gilvan Prioto
@since 10/11/2021
/*/
User Function M410IPI()

	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TrayMIPI")
		VALORIPI := U_TrayMIPI(VALORIPI)  // Função compilada no Rdmake TPEnt.prw
	EndIf

Return VALORIPI
