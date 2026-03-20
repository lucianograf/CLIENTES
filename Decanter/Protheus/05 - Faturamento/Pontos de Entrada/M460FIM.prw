#Include 'Protheus.ch'
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPonto Entrada ³M460FIM   ºAutor  ³ACTVS           º Data ³  09/27/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Ponto de entrada executado na preparacao do documento, com objetivo   º±±
±±º de chamar outro ponto de entrada de impressao de boletos              º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function M460FIM()
	local oRestClient as object
	local aHeadOut as array
	Local aAreaSD2 := sd2->(GetArea())
	Local aAreaSC5 := sc5->(GetArea())
	Local cPedido, cPedVtex  := ''
	Local oJson
	Local nVlrPedido	:= 0
	Private cURL  	    := GetMv("MA_VTEXURL"	,,"https://decantervinhos.myvtex.com")

	/*
    Integração com CRM Simples
    */
    IF cEmpAnt == "02" .and. cFilAnt == "0204"
		FwMsgRun(NIL, {|| U_PTCRM905(3)}, "Aguarde", "Processando integração com CRM")
	Endif 
    /*
    FIM Integração com CRM Simples
    */

	//Caso o fonte tenha sido chamado pelo pedido de venda
	If AllTrim(funname()) $ "MATA410/MATA461"
		U_M460NOTA()
	EndIf

	//Pega o pedido
	DbSelectArea("SD2")
	SD2->(DbSetorder(3))
	If SD2->(DbSeek(SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)))
		cPedido := SD2->D2_PEDIDO
	Endif

	//Se tiver pedido
	If !Empty(cPedido)
		DbSelectArea("SC5")
		SC5->(DbSetorder(1))
		//Se posiciona pega o tipo de pagamento
		If SC5->(DbSeek(FWxFilial('SC5')+cPedido))
			cPedVtex 	:= Alltrim(SC5->C5_ZNUMMGT)
			nVlrPedido	:= SC5->C5_ZVLRLIB
		Endif

		//Se tiver pedido VTEX
		If !Empty(cPedVtex)
			aHeadOut := {}
			Aadd(aHeadOut, "Content-Type: application/json")
			Aadd(aHeadOut, "X-VTEX-API-AppKey: vtexappkey-decantervinhos-JQBAGL")
			Aadd(aHeadOut, "X-VTEX-API-AppToken: KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")


			oJson := JsonObject():New()

			oJson["type"] := "Output"
			oJson["issuanceDate"] := Year2Str(Date()) + "-" + Month2Str(Date()) + "-" + Day2Str(Date()) //Year2Str(Date()) + "-" + Month(Date()) + "-" + Day(Date())
			oJson["invoiceNumber"]:= SF2->F2_DOC
			
			If nVlrPedido <> SF2->F2_VALFAT 
				oJson["invoiceValue"]	:= nVlrPedido * 100
			Else
				nVlrPedido	:= SF2->F2_VALFAT
				oJson["invoiceValue"] 	:= SF2->F2_VALFAT * 100
			Endif

			While !SD2->(Eof()) .And. xFilial("SD2") == SD2->D2_FILIAL .And.;
					SF2->F2_SERIE  == SD2->D2_SERIE  .And.;
					SF2->F2_DOC    == SD2->D2_DOC

				oJson['items'] := JSonObject():New()
				oJson['items']['id'] 		:= fBuscaProduto(SD2->D2_COD)//BUSCAR DO PRODUTO
				oJson['items']['price'] 	:= SD2->D2_VALBRUT * 100
				oJson['items']['quantity'] 	:= SD2->D2_QUANT
				nVlrPedido -= SD2->D2_VALBRUT	
				
				U_DCVTXI2G(SD2->D2_COD)			
				
				DbSelectArea("SD2")
				SD2->(DbSkip())
			Enddo
			// Atribuo no último item a diferença resultante entre o total do pedido e
			//oJson['items']['price']  += nVlrPedido

			cBody := EncodeUTF8(oJson:ToJson(), "cp1252")

			oRestClient := FWRest():New(cUrl)
			oRestClient:SetPath("/api/oms/pvt/orders/"+cPedVtex+"/invoice")
			oRestClient:SetPostParams(cBody)
			if oRestClient:Post(aHeadOut)
				sPostRet := oRestClient:GetResult()
			Endif

		Endif
	Endif 

	

	RestArea(aAreaSD2)
	RestArea(aAreaSC5)
Return

Static function fBuscaProduto(cCodigo)
	LOCAL nRet := 1
	Local cAliasSB1	:= GetNextAlias()

	BeginSql alias cAliasSB1
		SELECT B1_CODVTEX
			FROM %table:SB1% SB1
			WHERE SB1.B1_COD = %exp:cCodigo%
			  AND SB1.%NotDel%
           	  AND B1_FILIAL = %xFilial:SB1%
	EndSql

	If !(cAliasSB1)->(Eof())
		nRet := (cAliasSB1)->B1_CODVTEX
	ENDIF

return nRet

