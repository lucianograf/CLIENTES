#Include 'Totvs.ch'
/*/{Protheus.doc} DCVTXI08
Função para integração de estoque
@type function
@version  
@author Marcelo Alberto Lauschner
@since 05/08/2024
@param cInCodPro, character, param_description
@param cInIdVtex, character, param_description
@param nInOpc, numeric, param_description
@param nInIdSkuVtex, numeric, param_description
@return variant, return_description
/*/
User Function DCVTXI08(cInCodPro,cInIdVtex,nInOpc,nInIdSkuVtex)

	Local   cBody           := ''
	Local   aConectVtx      := U_DCVTXI01()
	Local   cUrlVtx         := aConectVtx[1]
	Local   aHeadOut        := aConectVtx[2]
	Local   cPath           := "/api/logistics/pvt/inventory/skus/"
	Local   oRestSpec
	Local   oObj
	Local   oJson           :=  JsonObject():New()
	Local 	lRet 			:= .F.
	Default cInIdVtex       := U_DCVTXI03(cInCodPro)
	Default nInIdSkuVtex	:= U_DCVTXI06(cInCodPro,cInIdVtex)
	Default nInOpc 			:= 0

	// Cadastrp de Produto
	DbSelectArea("SB1")
	DbSetOrder(1)
	If !DbSeek(xFilial("SB1") + cInCodPro)
		//MsgAlert("Não há produto cadastrado para o código informado '" + cInCodPro + "' ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há produto cadastrado para o código informado '" + cInCodPro + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return lRet
	Endif

	// Ficha Técnica
	DbSelectArea("ZFT")
	DbSetOrder(1) //ZFT_FILIAL+ZFT_COD
	If !DbSeek(xFilial("ZFT") + SB1->B1_ZFT ) .Or. Empty(SB1->B1_ZFT)
		//MsgAlert("Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return lRet
	Endif

	// Cadastro de Produtor
	DbSelectArea("Z03")
	DbSetOrder(1) //Z03_FILIAL+Z03_CODIGO
	If !DbSeek(xFilial("Z03") + ZFT->ZFT_PRODUT )  .Or. Empty(ZFT->ZFT_PRODUT)
		//MsgAlert("Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return lRet
	Endif

	// Cadastro de Categorias de Uvas
	DbSelectArea("Z04")
	DbSetOrder(1) //Z04_FILIAL+Z04_CODIGO
	If !DbSeek(xFilial("Z03") + ZFT->ZFT_CLASSI )  .Or. Empty(ZFT->ZFT_PRODUT)  //ZFT_CLASSI = Z04_CODIGO
		//MsgAlert("Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return lRet
	Endif

	// Cadastro de Países
	DbSelectArea("SYA")
	DbSetOrder(1) //YA_FILIAL+YA_CODGI
	If !DbSeek(xFilial("SYA") + Z03->Z03_PAIS )  .Or. Empty(Z03->Z03_PAIS)  //YA_CODGI = Z03_PAIS
		//MsgAlert("Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return lRet
	Endif

	DbSelectArea("SB2")
	DbSetOrder(1) 
	If !DbSeek(xFilial("SB2") + SB1->B1_COD + "02")
		//MsgAlert("Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há estoque para o código do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return lRet
	Endif

	If !Empty(nInIdSkuVtex)
		cBody := ''
		//ESTOQUE
		oRestSpec := FWRest():New(cUrlVtx)
		oJson["unlimitedQuantity"]	:= .F.
		oJson["quantity"] 			:= SB2->B2_QATU - SB2->B2_RESERVA
		cBody := EncodeUTF8(oJson:ToJson(), "cp1252")

		oRestSpec:SetPath(cPath + Alltrim(cValToChar(nInIdSkuVtex))+"/warehouses/1fd47f1") //criar parametro para warehouse (1fd47f1)

		If oRestSpec:Put(aHeadOut, cBody)
			sPostRet := oRestSpec:GetResult()
			If FWJsonDeserialize(sPostRet,@oObj)
				If SubStr(oRestSpec:GetLastError(),1,3) == '200'
					//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/warehouses/1fd47f1" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + cBody + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
					lRet 	:= .T.
				Else
					//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/warehouses/1fd47f1" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
				EndIf
			Else
				//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/warehouses/1fd47f1" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
			Endif
		Else
			//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValTochar(nInIdSkuVtex)) +"/warehouses/1fd47f1" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
		Endif
	Endif

Return lRet
