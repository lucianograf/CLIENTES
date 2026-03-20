#Include 'Totvs.ch'
/*/{Protheus.doc} DCVTXI06
Função para integrar Dados logísticos do Produto
@type function
@version  
@author Marcelo Alberto Lauschner
@since 05/08/2024
@param cInCodPro, character, param_description
@param cInIdVtex, character, param_description
@param nInOpc, numeric, param_description
@return variant, return_description
/*/
User Function DCVTXI06(cInCodPro,cInIdVtex,nInOpc)

	Local   cBody           := ''
	Local   aConectVtx      := U_DCVTXI01()
	Local   cUrlVtx         := aConectVtx[1]
	Local   aHeadOut        := aConectVtx[2]
	Local   cPath           := "/api/catalog/pvt/stockkeepingunit"
	Local   oRestSpec
	Local   oObj
	Local   oJson           :=  JsonObject():New()
	Local 	nSKUId			:= 0
	Default cInIdVtex       := U_DCVTXI03(cInCodPro)
	Default nInOpc 			:= 0

	// Cadastrp de Produto
	DbSelectArea("SB1")
	DbSetOrder(1)
	If !DbSeek(xFilial("SB1") + cInCodPro)
		//MsgAlert("Não há produto cadastrado para o código informado '" + cInCodPro + "' ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há produto cadastrado para o código informado '" + cInCodPro + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Ficha Técnica
	DbSelectArea("ZFT")
	DbSetOrder(1) //ZFT_FILIAL+ZFT_COD
	If !DbSeek(xFilial("ZFT") + SB1->B1_ZFT ) .Or. Empty(SB1->B1_ZFT)
		//MsgAlert("Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Produtor
	DbSelectArea("Z03")
	DbSetOrder(1) //Z03_FILIAL+Z03_CODIGO
	If !DbSeek(xFilial("Z03") + ZFT->ZFT_PRODUT )  .Or. Empty(ZFT->ZFT_PRODUT)
		//MsgAlert("Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Categorias de Uvas
	DbSelectArea("Z04")
	DbSetOrder(1) //Z04_FILIAL+Z04_CODIGO
	If !DbSeek(xFilial("Z03") + ZFT->ZFT_CLASSI )  .Or. Empty(ZFT->ZFT_PRODUT)  //ZFT_CLASSI = Z04_CODIGO
		//MsgAlert("Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Países
	DbSelectArea("SYA")
	DbSetOrder(1) //YA_FILIAL+YA_CODGI
	If !DbSeek(xFilial("SYA") + Z03->Z03_PAIS )  .Or. Empty(Z03->Z03_PAIS)  //YA_CODGI = Z03_PAIS
		//MsgAlert("Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	If !Empty(cInIdVtex)
		nSKUId := 0
		
		oJson["ProductId"]			:= Val(cInIdVtex)
		oJson["Name"]     			:= AllTrim(ZFT->ZFT_DESCR)
		oJson["RefId"]     			:= AllTrim(SB1->B1_COD)
		oJson["IsActive"]       	:= .T.
		oJson["PackagedHeight"] 	:= SB5->B5_ALTURLC
		oJson["PackagedLength"] 	:= SB5->B5_COMPRLC
		oJson["PackagedWidth"]  	:= SB5->B5_LARGLC
		oJson["PackagedWeightKg"]	:= SB1->B1_PESBRU
		oJson["ActivateIfPossible"]	:= .T.
		cBody := EncodeUTF8(oJson:ToJson(), "cp1252")

		//verificar primeiro se já existe
		oRestSpec := FWRest():New(cUrlVtx)
		oRestSpec:setPath(cPath + "?refId="+AllTrim(SB1->B1_COD))
		If oRestSpec:Get(aHeadOut)

			If nInOpc == 1 
				MsgInfo(DecodeUtf8(oRestSpec:GetResult()),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				Return 
			Endif 
			//SKU existe deve atualizar
			sPostRet := oRestSpec:GetResult()
			If FWJsonDeserialize(sPostRet,@oObj)
				If SubStr(oRestSpec:GetLastError(),1,3) == '200' .And. ValType(oObj) == "O"
					nSKUId := oObj:Id
					oRestSpec:SetPath(cPath+"/"+Alltrim(cValToChar(nSKUId)))

					If oRestSpec:Put(aHeadOut, cBody)
						sPostRet := oRestSpec:GetResult()
						If FWJsonDeserialize(sPostRet,@oObj)
							If SubStr(oRestSpec:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O"
								nSKUId := oObj:Id
								//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
								ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath+"/"+Alltrim(cValToChar(nSKUId)) , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
							Else
								//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
								ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
							EndIf
						Else
							//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
						EndIf
					Else
						//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError() + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
					Endif
				Else
					ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
				Endif
			Else
				//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
			Endif
		Else
			oJson["ProductId"]			:= Val(cInIdVtex)
			oJson["Name"]     			:= AllTrim(ZFT->ZFT_DESCR)
			oJson["RefId"]     			:= AllTrim(SB1->B1_COD)
			oJson["IsActive"]       	:= .F.
			oJson["PackagedHeight"] 	:= SB5->B5_ALTURLC
			oJson["PackagedLength"] 	:= SB5->B5_COMPRLC
			oJson["PackagedWidth"]  	:= SB5->B5_LARGLC
			oJson["PackagedWeightKg"]	:= SB1->B1_PESBRU
			oJson["ActivateIfPossible"]	:= .T.
			cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
		
			//criar SKU
			oRestSpec:SetPath(cPath)
			oRestSpec:SetPostParams(cBody)
			if oRestSpec:Post(aHeadOut)
				sPostRet := oRestSpec:GetResult()
				If FWJsonDeserialize(sPostRet,@oObj)
					If SubStr(oRestSpec:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O"
						nSKUId := oObj:Id
						//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath+"/"+Alltrim(cValToChar(nSKUId)) , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
					Else
						//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
					EndIf
				Else
					//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
				EndIf
			Else
				//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "ERRO" , cUrlVtx + cPath  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
			Endif
		Endif
	Endif

Return nSKUId
