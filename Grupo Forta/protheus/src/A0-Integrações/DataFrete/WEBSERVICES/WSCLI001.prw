#INCLUDE "totvs.ch"

/*
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Programa    | integração de dados  | Autor | William Souza - Loranto Tech Knowledge   | Data | Maio./2024  |
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Descricao   | Client para integração ao software da COUPA   			            		 			     |
+-------------+----------------------------------------------------------------------------------------------+
| Uso         |                                                                                              |
+-------------+----------------------------------------------------------------------------------------------+
*/

User function WSCLI001(_cJson,_cEndpoint,_cAPI)

	//Local cServer   := iif(_cAPI == "DFWSCF",GetMV("MV_XDFSRV1"),GetMV("MV_XDFSRV2"))
	//Local cServer   := iif(_cAPI == "DFWSCF","https://apresentacao.api.datafreteapi.com","https://services.v1.datafreteapi.com")
	//Local cChave    := "6a0307fb-6583-44e7-a219-854218bb3998"//GetMV("MV_XDFCHV")                                      // URL (IP) DO SERVIDOR
	Local cServer   := iif(_cAPI == "DFWSCF",GetMV("MV_XDFSRV1"),GetMV("MV_XDFSRV2"))
	Local cChave    := GetMV("MV_XDFCHV")
	Local oRest     := FwRest():New(cServer)                                      // CLIENTE PARA CONSUMO REST
	Local aHeader   := {}
	Local cRetorno  := ""
	Local aRet      := {}                                              // CABEÇALHO DA REQUISIÇÃO

// PREENCHE CABEÇALHO DA REQUISIÇÃO
	AAdd(aHeader, "Content-Type: application/json; charset=UTF-8")
	AAdd(aHeader, "Accept: application/json")
	AAdd(aHeader, "X-api-key:"+ cChave)
	AAdd(aHeader, "User-Agent: Chrome/65.0 (compatible; Protheus " + GetBuild() + ")")

// INFORMA O RECURSO E INSERE O JSON NO CORPO (BODY) DA REQUISIÇÃO
	if(_cAPI != "DFWSCF")
		oRest:SetPath(_cEndpoint)
	Endif
	oRest:SetPostParams(_cJson)

// REALIZA O MÉTODO POST E VALIDA O RETORNO
	oRest:Post(aHeader)
	if oRest:ORESPONSEH:CSTATUSCODE == "200"
		cRetorno := "1"
	Else
		cRetorno := "2"
	EndIf

Return aRet := {cRetorno,oRest:GetResult()}
