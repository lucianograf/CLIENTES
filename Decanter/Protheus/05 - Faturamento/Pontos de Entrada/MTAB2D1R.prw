#Include "TOTVS.CH"
#Include "RWMAKE.CH"
#Include "PROTHEUS.CH"
#INCLUDE 'TOPConn.ch'

/*/{Protheus.doc} MTAB2D1R
Localizado na função B2AtuComD1 - Atualiza os dados do SB2  baseado no SD1 (itens da Nota Fiscal de Entrada).
O ponto de entrada MTAB2D1R é executado no final da função B2AtuComD1, APÓS todas as gravações e pode ser utilizado para complementar a gravação no arq. de Saldos (SB2) ou outras atualizações de arquivos e campos do usuário.
@type function
@author Vamilly - Gilvan Prioto
@since 31/03/2021
@return Nil
/*/
User Function MTAB2D1R()

	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TrayEstq")
		U_TrayEstq(ParamIXB[1], ParamIXB[2], ParamIXB[3]) // Função compilada no Rdmake TPEnt.prw
	EndIf

Return Nil
