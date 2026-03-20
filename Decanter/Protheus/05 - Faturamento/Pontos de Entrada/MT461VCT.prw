#INCLUDE "RWMAKE.CH"
#INCLUDE 'TOPConn.ch'

/*/{Protheus.doc} MT461VCT
O ponto de entrada permite alterar o valor e o vencimento do título  gerado no momento de geração da nota fiscal.
@type function
@author Vamilly - Gilvan Prioto
@since 31/03/2021
@return Array, aTitulo,  array com dados do título
/*/
User Function MT461VCT()
Local aVencto   := {}

	// Tray
	If FindFunction("U_TrayMT46")
		aVencto := U_TrayMT46(PARAMIXB)  // Função compilada no Rdmake TPEnt.prw
	EndIf

Return aVencto
