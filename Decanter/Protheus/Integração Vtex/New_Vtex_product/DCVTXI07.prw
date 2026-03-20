#Include 'Totvs.ch'
/*/{Protheus.doc} DCVTXI07
Função para integração de Códigos de barra
@type function
@version  
@author Marcelo Alberto Lauschner
@since 05/08/2024
@param cInCodPro, character, param_description
@param cInIdVtex, character, param_description
@param nInIdSkuVtex, numeric, param_description
@param nInOpc, numeric, param_description
@return variant, return_description
/*/
User Function DCVTXI07(cInCodPro,cInIdVtex,nInIdSkuVtex,nInOpc)

	Local   cBody           := ''
	Local   aConectVtx      := U_DCVTXI01()
	Local   cUrlVtx         := aConectVtx[1]
	Local   aHeadOut        := aConectVtx[2]
	Local   cPath           := "/api/catalog/pvt/stockkeepingunit"
	Local   oRestSpec
	Local   oObj
	Local 	cEanVtex 		:= ""
	Default cInIdVtex       := U_DCVTXI03(cInCodPro)
	Default nInIdSkuVtex	:= U_DCVTXI06(cInCodPro,cInIdVtex)
	Default nInOpc 			:= 0

	// Cadastrp de Produto
	DbSelectArea("SB1")
	DbSetOrder(1)
	If !MsSeek(xFilial("SB1") + cInCodPro)
		//MsgAlert("Não há produto cadastrado para o código informado '" + cInCodPro + "' ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há produto cadastrado para o código informado '" + cInCodPro + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Ficha Técnica
	DbSelectArea("ZFT")
	DbSetOrder(1) //ZFT_FILIAL+ZFT_COD
	If !MsSeek(xFilial("ZFT") + SB1->B1_ZFT ) .Or. Empty(SB1->B1_ZFT)
		//MsgAlert("Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Produtor
	DbSelectArea("Z03")
	DbSetOrder(1) //Z03_FILIAL+Z03_CODIGO
	If !MsSeek(xFilial("Z03") + ZFT->ZFT_PRODUT )  .Or. Empty(ZFT->ZFT_PRODUT)
		//MsgAlert("Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Categorias de Uvas
	DbSelectArea("Z04")
	DbSetOrder(1) //Z04_FILIAL+Z04_CODIGO
	If !MsSeek(xFilial("Z03") + ZFT->ZFT_CLASSI )  .Or. Empty(ZFT->ZFT_PRODUT)  //ZFT_CLASSI = Z04_CODIGO
		//MsgAlert("Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Países
	DbSelectArea("SYA")
	DbSetOrder(1) //YA_FILIAL+YA_CODGI
	If !MsSeek(xFilial("SYA") + Z03->Z03_PAIS )  .Or. Empty(Z03->Z03_PAIS)  //YA_CODGI = Z03_PAIS
		//MsgAlert("Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	If !Empty(nInIdSkuVtex)
		nSKUId := 0

		cBody := ''

		//verificar primeiro se já existe
		oRestSpec := FWRest():New(cUrlVtx)
		oRestSpec:setPath(cPath + "/"+AllTrim(cValToChar(nInIdSkuVtex)) +"/ean")
		// Se já existe Ean para o Produto
		If oRestSpec:Get(aHeadOut)
			If nInOpc == 1
				MsgInfo(DecodeUtf8(oRestSpec:GetResult()),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				Return
			Endif

			sPostRet := oRestSpec:GetResult()
			If FWJsonDeserialize(sPostRet,@oObj)
				If SubStr(oRestSpec:GetLastError(),1,3) == '200' .And. ValType(oObj) == "A" .And. Len(oObj) > 0
					cEanVtex := oObj[1]
					// Se o que estiver cadastrado no Vtex for diferente do Protheus  - Deleta
					If AllTrim(SB1->B1_CODGTIN) <> cEanVtex
						oRestSpec:SetPath(cPath+"/"+cValToChar(nInIdSkuVtex) + "/ean")
						// Deleta os códigos Ean vinculados ao produto
						If oRestSpec:Delete(aHeadOut,"")

							//criar o Ean novo
							If !Empty(SB1->B1_CODGTIN)
								oRestSpec:setPath(cPath + "/"+AllTrim(cValToChar(nInIdSkuVtex)) +"/ean/"+AllTrim(SB1->B1_CODGTIN))
								oRestSpec:SetPostParams(cBody)
								if oRestSpec:Post(aHeadOut)
									sPostRet := oRestSpec:GetResult()
									If SubStr(oRestSpec:GetLastError(),1,3) == '200'
										//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
										ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
									Else
										//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
										ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean"  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
									EndIf
								Else
									//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
									ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean"  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
								Endif
							Endif
						Else
							//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean"  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
						EndIf
					Else
						//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex))  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +  AllTrim(SB1->B1_CODGTIN) + " " + cValToChar(nInIdSkuVtex) + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
					Endif
				Else
					//criar o Ean novo
					If !Empty(SB1->B1_CODGTIN)
						oRestSpec:setPath(cPath + "/"+AllTrim(cValToChar(nInIdSkuVtex)) +"/ean/"+AllTrim(SB1->B1_CODGTIN))
						oRestSpec:SetPostParams(cBody)
						if oRestSpec:Post(aHeadOut)
							sPostRet := oRestSpec:GetResult()
							If SubStr(oRestSpec:GetLastError(),1,3) == '200'
								//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
								ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
							Else
								//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
								ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean"  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
							EndIf
						Else
							//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean"  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
						Endif
					Endif
				Endif
			Else
				//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex))  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
			Endif
		ElseIf nInOpc == 1
			MsgInfo(DecodeUtf8(oRestSpec:GetResult()),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		ElseIf !Empty(SB1->B1_CODGTIN)
			cBody := ''

			//criar SKU
			oRestSpec:setPath(cPath + "/"+AllTrim(cValToChar(nInIdSkuVtex)) +"/ean/"+AllTrim(SB1->B1_CODGTIN))
			oRestSpec:SetPostParams(cBody)
			if oRestSpec:Post(aHeadOut)
				sPostRet := oRestSpec:GetResult()
				If FWJsonDeserialize(sPostRet,@oObj)
					If SubStr(oRestSpec:GetLastError(),1,3) == '200' .And. ValType(oObj) == "A"
						cEanVtex := oObj[1]
						//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) +"/ean/"+cEanVtex , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
					Else
						//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) + "/ean/"+AllTrim(SB1->B1_CODGTIN)  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
					EndIf
				Else
					//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) + "/ean/"+AllTrim(SB1->B1_CODGTIN)  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
				EndIf
			Else
				//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "ERRO" , cUrlVtx +  cPath + "/" + AllTrim(cInIdVtex) + "/ean/"+AllTrim(SB1->B1_CODGTIN)  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + cUrlVtx +  cPath + "/" + AllTrim(cValToChar(nInIdSkuVtex)) + "/ean/"+AllTrim(SB1->B1_CODGTIN)  + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
			Endif
		Endif
	Endif

Return cEanVtex
