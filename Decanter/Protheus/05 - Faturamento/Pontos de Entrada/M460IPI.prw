#Include "Protheus.ch"
#Include "TbiConn.ch"

/*/{Protheus.doc} M460IPI 
M460IPI - Retorno do valor de IPI na geração da nota fiscal
Variaveis disponiveis: VALORIPI  BASEIPI  QUANTIDADE  ALIQIPI  BASEIPIFRETE
@type function
@author Vamilly - Gilvan Prioto
@since 10/11/2021
/*/
User Function M460IPI()

	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TrayMIPI")
		VALORIPI := U_TrayMIPI(VALORIPI)  // Função compilada no Rdmake TPEnt.prw
	EndIf

Return VALORIPI
