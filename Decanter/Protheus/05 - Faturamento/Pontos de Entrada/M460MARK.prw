#Include "Protheus.ch"
#Include "topconn.ch"
#Include "TbiConn.ch"
#INCLUDE "RWMAKE.CH"

/*/{Protheus.doc} M460MARK 
Validação de pedidos marcados
@type function
@author Vamilly - Gilvan Prioto
@since 31/03/2021
@return Logiscal, lRet,  retornar Falso (.F.), o Sistema cancelará o faturamento de todas as cargas marcadas em tela.
/*/
User Function M460MARK()
Local lRet := .T.

	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TrayMARK")
		lRet := U_TrayMARK(PARAMIXB)  // Função compilada no Rdmake TPEnt.prw
	EndIf

Return lRet
