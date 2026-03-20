#Include "TOTVS.CH"
#Include "RWMAKE.CH"
#Include "PROTHEUS.CH"

/*/{Protheus.doc} MSD2520
Esse ponto de entrada está localizado na função A520Dele(). É chamado antes da exclusão do registro no SD2.
@type function
@author Vamilly - Gilvan Prioto
@since 31/03/2021
@return logical, Prossegue ou não com a exclusão.
@obs Analisado e este PE fica dentro da transação.
@see https://tdn.totvs.com/display/public/PROT/MSD2520
/*/
User Function MSD2520() As Logical	
Local lRet := .T.
	
	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TrayMSD2")	
		U_TrayMSD2()  // Função compilada no Rdmake TPEnt.prw
	EndIf

Return lRet
