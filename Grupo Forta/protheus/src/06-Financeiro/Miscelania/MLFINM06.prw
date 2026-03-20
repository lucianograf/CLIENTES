#include "TopConn.ch"
#include "totvs.ch"
#Include 'RestFul.CH'

WSRESTFUL FortaXB2ESistema DESCRIPTION "Integração Protheus Grupo Forta X B2E Sistemas" FORMAT APPLICATION_JSON

	//WsData site 				as Char
	//WsData numeroDaTransacao	as Int
	//WsData nInVlrNF 			as Number

	WSMETHOD PUT B2ECallBack;
		DESCRIPTION "Recebimento de Callback de Propostas integradas com o Software B2E Sistemas";
		WSSYNTAX "/api/v1/b2ecallback/";
		PATH "api/v1/b2ecallback/" TTALK "v1"


END WSRESTFUL


WsMethod Put B2ECallBack WsReceive Wsservice FortaXB2ESistema

	Local	cJSON		:= Self:GetContent()
	Local 	oParseJSON	:= Nil
	Local 	aUpdTblB2E	:= {}
	Local 	cIdUnqTb2	:= GetSxeNum("T_B2EWEBHK","TB2_NIDUNQ")
	

	//		"CodigoProposta":  "CodigoInstituicao": "Sucesso": true, "PropostaProcessada": true, false "StatusProposta": { "Id":  ** 4 ** , "Nome": "APROVADO AUTOMATICAMENTE", "Descricao": " APROVADO AUTOMATICAMENTE " "Score": 785, "LimiteConcedido": 20000.00 } “InformacoesAdicionais": {             "Grupo": "string",             "Nome": "string",             "Valor": "string"                 }

	If !Empty(cJSON)
		
		Aadd(aUpdTblB2E,{"TB2_NIDUNQ",cIdUnqTb2})

		If DecodeUTF8(cJSON) == Nil
			cJSON	:= Self:GetContent()
		Else
			cJSON	:= DecodeUTF8(cJSON)
		Endif
		// Deserializa o Json
		FWJsonDeserialize(cJson, @oParseJSON)
		
		//{ 
		//	"PropostaId": "string", [IDENTIFICADOR INTERNO DA PROPOSTA DE USO NA B2E] 
		Aadd(aUpdTblB2E,{"TB2_IDB2E",oParseJSON["PropostaId"]})
		//	“CodigoProposta”: “”, [IDENTIFICADOR DA PROPOSTA NO CLIENTE] 
		Aadd(aUpdTblB2E,{"TB2_CDPROP",oParseJSON["“CodigoProposta”"]})
		//	"CodigoInstituicao": "00000000-0000-0000-0000-000000000000", 
		Aadd(aUpdTblB2E,{"TB2_CDINST",oParseJSON["CodigoInstituicao"]})
		//	"Sucesso": true, 
		Aadd(aUpdTblB2E,{"TB2_SUCESS",cValToChar(oParseJSON["Sucesso"])})
		//	"Mensagens": [ 
		//		{ 
		//		"Tipo": 0, 
		//		"Codigo": "string", 
		//		"Descricao": "string", 
		//		"ValorInformado": "string" 
		//		} 
		//	], 
		//	"PropostaProcessada": true, 
		Aadd(aUpdTblB2E,{"TB2_PPROCE",cValToChar(oParseJSON["Sucesso"])})
		//	"StatusProposta": { 
		//		"Id": 0, 
		Aadd(aUpdTblB2E,{"TB2_STS_ID",cValToChar(oParseJSON["StatusProposta"]["Id"])})
		//		"Nome": "string", 
		Aadd(aUpdTblB2E,{"TB2_STS_NM",oParseJSON["StatusProposta"]["Nome"]})
		//		"Descricao": "string" 
		Aadd(aUpdTblB2E,{"TB2_STS_DS",oParseJSON["StatusProposta"]["Descricao"]})
		//	}, 
		//	"Score": 0, 
		Aadd(aUpdTblB2E,{"TB2_STS_SC",oParseJSON["Score"]})
		//	"LimiteConcedido": 0, 
		Aadd(aUpdTblB2E,{"TB2_STS_LC",oParseJSON["LimiteConcedido"]})
		//	"Alertas": [ 
		//		{ 
		//		"Id": "", 
		//		"Descricao": "string", 
		//		"Resultado": true 
		//		} 
		//	], 
		//	"InformacoesAdicionais": [ 
		//		{ 
		//		"Grupo": "string", 
		//		"Nome": "string", 
		//		"Valor": "string" 
		//		} 
		//	] 
		//	} 
		
//	sfUpdate("T_B2EWEBHK"+cEmpAnt/*cInTble*/,aUpdTblB2E/*aInUpd*/,oBody:toJson()/*cInJson*/)

//aUpdAuxTbl

//T_B2EWEBIA"+cEmpAnt

// Define a resposta
		::SetStatus(200)
		::SetContentType("application/json")
		::SetResponse(FWJsonSerialize(aListRet,.F.,.F.))

	Else
		::SetStatus(403)
	Endif


Return .T.
