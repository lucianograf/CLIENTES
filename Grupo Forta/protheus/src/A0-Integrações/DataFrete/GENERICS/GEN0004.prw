#INCLUDE "totvs.ch"


/*
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Programa    | inclusao de dados    | Autor | William Souza - Loranto Tech Knoledge    | Data | Maio./2024  |
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Descricao   | GENERICO - Extração XML danfe     			            		 			                 |
+-------------+----------------------------------------------------------------------------------------------+
| Uso         |                                                                                              |
+-------------+----------------------------------------------------------------------------------------------+
*/

User Function GEN0004(cDocumento, cSerie)

	Local aArea        := GetArea()
	Local cURLTss      := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local oWebServ
	Local cIdEnt       := RetIdEnti()
	Local cTextoXML    := ""
	Local nRet         := 0

	Default cDocumento := ""
	Default cSerie     := ""


	//Se tiver documento
	If !Empty(cDocumento)
		cDocumento := PadR(cDocumento, TamSX3('F2_DOC')[1])
		cSerie     := PadR(cSerie,     TamSX3('F2_SERIE')[1])

		//Instancia a conexão com o WebService do TSS
		oWebServ:= WSNFeSBRA():New()
		oWebServ:cUSERTOKEN        := "TOTVS"
		oWebServ:cID_ENT           := cIdEnt
		oWebServ:oWSNFEID          := NFESBRA_NFES2():New()
		oWebServ:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
		aAdd(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
		aTail(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2):cID := (cSerie+cDocumento)
		oWebServ:nDIASPARAEXCLUSAO := 0
		oWebServ:_URL              := AllTrim(cURLTss)+"/NFeSBRA.apw"

		//Se tiver notas
		If oWebServ:RetornaNotas()

			//Se tiver dados
			If Len(oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3) > 0

				//Se tiver sido cancelada
				If oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA != Nil
					cTextoXML := oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA:cXML

					//Senão, pega o xml normal (foi alterado abaixo conforme dica do Jorge Alberto)
				Else
					cTextoXML := '<?xml version="1.0" encoding="UTF-8"?>'
					cTextoXML += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
					cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
					cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXMLPROT
					cTextoXML += '</nfeProc>'

				EndIf
				nRet := 1
			EndIf

		EndIf
	EndIf
	RestArea(aArea)



Return {nRet,cTextoXML}
