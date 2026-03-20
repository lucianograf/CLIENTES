
#Include "PROTHEUS.CH"

/*/{Protheus.doc} SPDNFDANF
Este ponto de entrada está localizado no momento do monitoramento da nota fiscal eletrônica depois da gravação das tabelas SF2, SF3 e SFT.
@type function
@author Vamilly - Gilvan Prioto
@since 31/03/2021
@obs Preenche a chave da NF no pedido da Gestão de pedidos caso esta esteja transmitida.
/*/
User Function SPDNFDANF()

	// Tray
	If cEmpAnt $ "02" .And. FindFunction("U_TraySPDN")		
		U_TraySPDN(ParamIXB) // Função compilada no Rdmake TPEnt.prw
	EndIf
	
Return Nil
