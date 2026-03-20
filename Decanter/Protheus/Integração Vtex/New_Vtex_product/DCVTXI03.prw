#Include 'Totvs.ch'
/*/{Protheus.doc} DCVTXI03
Função para Integração de Produto 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 30/04/2024
@return variant, return_description
/*/
User Function DCVTXI03(cInCodPro,nInOpc)

	Local   cProdID         :=  ""
	Local   cPostRet        := ""
	Local   oJson           :=  JsonObject():New()
	Local   aConectVtx      :=  U_DCVTXI01()
	Local   cUrlVtx         := aConectVtx[1]
	Local   aHeadOut        := aConectVtx[2]
	Local   cPath           := "/api/catalog/pvt/product/"
	Local   oObj
	Local   oRestPrd
	Default nInOpc          := 0

	// Cadastrp de Produto
	DbSelectArea("SB1")
	DbSetOrder(1)
	If !DbSeek(xFilial("SB1") + cInCodPro)
		If nInOpc== 1
			MsgAlert("Não há produto cadastrado para o código informado '" + cInCodPro + "' ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Else
			ProcLogAtu( "ERRO" , "Não há produto cadastrado para o código informado '" + cInCodPro + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Endif
		Return ""
	Endif

	// Ficha Técnica
	DbSelectArea("ZFT")
	DbSetOrder(1) //ZFT_FILIAL+ZFT_COD
	If !DbSeek(xFilial("ZFT") + SB1->B1_ZFT ) .Or. Empty(SB1->B1_ZFT)
		If nInOpc== 1
			MsgAlert("Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Else
			ProcLogAtu( "ERRO" , "Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Endif
		Return ""
	Endif

	// Cadastro de Produtor
	DbSelectArea("Z03")
	DbSetOrder(1) //Z03_FILIAL+Z03_CODIGO
	If !DbSeek(xFilial("Z03") + ZFT->ZFT_PRODUT )  .Or. Empty(ZFT->ZFT_PRODUT)
		If nInOpc== 1
			MsgAlert("Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Else
			ProcLogAtu( "ERRO" ,"Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Endif
		Return ""
	Endif




	// Cadastro de Categorias de Uvas
	DbSelectArea("Z04")
	DbSetOrder(1) //Z04_FILIAL+Z04_CODIGO
	If !DbSeek(xFilial("Z03") + ZFT->ZFT_CLASSI )  .Or. Empty(ZFT->ZFT_PRODUT)  //ZFT_CLASSI = Z04_CODIGO
		//MsgAlert("Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return ""
	Endif

	// Cadastro de Países
	DbSelectArea("SYA")
	DbSetOrder(1) //YA_FILIAL+YA_CODGI
	If !DbSeek(xFilial("SYA") + Z03->Z03_PAIS )  .Or. Empty(Z03->Z03_PAIS)  //YA_CODGI = Z03_PAIS
		//MsgAlert("Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return ""
	Endif

	DbSelectArea("SB2")
	DbSetOrder(1)
	If !DbSeek(xFilial("SB2") + SB1->B1_COD + "02")
		If nInOpc== 1
			MsgAlert("Não há cadastro de estoque do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Else
			ProcLogAtu( "ERRO" ,"Não há cadastro de estoque do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Endif
		Return ""
	Endif

	oJson["Name"]           	:= AllTrim(ZFT->ZFT_DESCR)
	oJson["Title"]				:= NoAcento(AllTrim(ZFT->ZFT_DESCR))
	oJson["CategoryId"]     	:= Z04->Z04_CTVTEX
	oJson["BrandId"]        	:= Z03->Z03_VTEX
	oJson["LinkId"]				:= sfAjust(ZFT->ZFT_DESCR)
	oJson["DepartmentId"]   	:= 1
	oJson["BrandName"]      	:= Alltrim(Z03->Z03_APELID)
	oJson["IsVisible"]      	:= .T.
	oJson["IsActive"]       	:= .T.
	oJson["TaxCode"]        	:= AllTrim(SB1->B1_COD)
	oJson["MetaTagDescription"]	:= AllTrim(ZFT->ZFT_HISTOR)
	oJson["Description"]		:= AllTrim(ZFT->ZFT_HISTOR)
	oJson["RefId"]          	:= AllTrim(SB1->B1_COD)
	oJson["ShowWithoutStock"]	:= .T.
	oJson["Score"]				:= 1

	cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
	oRestPrd := FWRest():New(cUrlVtx)
	oRestPrd:setPath("/api/catalog_system/pvt/products/productgetbyrefid/"+Alltrim(SB1->B1_COD))
	If oRestPrd:Get(aHeadOut)

		cPostRet := oRestPrd:GetResult()
		If nInOpc == 1
			MsgInfo(DecodeUtf8(oRestPrd:GetResult()),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		Endif
		If "Product not found by refId:" $  cPostRet
			oRestPrd:SetPath(cPath)
			oRestPrd:SetPostParams(EncodeUTF8(cBody, "cp1252"))

			If oRestPrd:Post(aHeadOut)
				cPostRet := oRestPrd:GetResult()
				If FWJsonDeserialize(cPostRet,@oObj)
					If SubStr(oRestPrd:GetLastError(),1,3) == '200' .And. ValType(oObj) == "O"
						cProdID := cValToChar(oObj:Id)
						//MsgInfo(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestPrd:GetResult()),,.F. )
					Else
						ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestPrd:GetLastError(),,.F. )
						//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					EndIf
				Else
					ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
					//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				EndIf
			Else
				//MsgAlert(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
			Endif
		Endif
		If FWJsonDeserialize(cPostRet,@oObj)
			If SubStr(oRestPrd:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O" //produto existe deve ser atualizado (PUT)
				cProdID := cValToChar(oObj:Id)
				// Se for uma chamada para só retornar o Id do Produto
				If nInOpc == 2
					Return cProdID
				Endif

				oRestPrd:setPath(cPath + cProdID)
				If oRestPrd:Put(aHeadOut, cBody)
					//MsgInfo(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					//ProcLogAtu(cType,cMsg,cDetalhes,cBatchProc,lCabec,cFilProc)
					ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetResult(),,.F. )
				Else
					//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
				EndIf
			Else //novo produto
				oRestPrd:SetPath(cPath)
				oRestPrd:SetPostParams(EncodeUTF8(cBody, "cp1252"))

				If oRestPrd:Post(aHeadOut)
					cPostRet := oRestPrd:GetResult()
					If FWJsonDeserialize(cPostRet,@oObj)
						If SubStr(oRestPrd:GetLastError(),1,3) == '200' .And. ValType(oObj) == "O"
							cProdID := cValToChar(oObj:Id)
							ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +DecodeUtf8(oRestPrd:GetResult()),,.F. )
							//MsgInfo(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						Else
							//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestPrd:GetLastError(),,.F. )
						EndIf
					Else
						//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestPrd:GetLastError(),,.F. )
					EndIf
				Else
					//MsgAlert(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
				Endif
			Endif
		Else
			//MsgAlert(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
		Endif
	ElseIf  "Product not found by refId:" $  oRestPrd:GetResult()

		cPostRet := oRestPrd:GetResult()
		If nInOpc == 1
			MsgInfo(DecodeUtf8(oRestPrd:GetResult()),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		Endif
		If "Product not found by refId:" $  cPostRet
			oRestPrd:SetPath(cPath)
			oRestPrd:SetPostParams(EncodeUTF8(cBody, "cp1252"))

			If oRestPrd:Post(aHeadOut)
				cPostRet := oRestPrd:GetResult()
				If FWJsonDeserialize(cPostRet,@oObj)
					If SubStr(oRestPrd:GetLastError(),1,3) == '200' .And. ValType(oObj) == "O"
						cProdID := cValToChar(oObj:Id)
						//MsgInfo(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestPrd:GetResult()),,.F. )
					Else
						ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestPrd:GetLastError(),,.F. )
						//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					EndIf
				Else
					ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
					//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				EndIf
			Else
				//MsgAlert(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
			Endif
		Endif
		If FWJsonDeserialize(cPostRet,@oObj)
			If SubStr(oRestPrd:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O" //produto existe deve ser atualizado (PUT)
				cProdID := cValToChar(oObj:Id)
				// Se for uma chamada para só retornar o Id do Produto
				If nInOpc == 2
					Return cProdID
				Endif

				oRestPrd:setPath(cPath + cProdID)
				If oRestPrd:Put(aHeadOut, cBody)
					//MsgInfo(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					//ProcLogAtu(cType,cMsg,cDetalhes,cBatchProc,lCabec,cFilProc)
					ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetResult(),,.F. )
				Else
					//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
				EndIf
			Else //novo produto
				oRestPrd:SetPath(cPath)
				oRestPrd:SetPostParams(EncodeUTF8(cBody, "cp1252"))

				If oRestPrd:Post(aHeadOut)
					cPostRet := oRestPrd:GetResult()
					If FWJsonDeserialize(cPostRet,@oObj)
						If SubStr(oRestPrd:GetLastError(),1,3) == '200' .And. ValType(oObj) == "O"
							cProdID := cValToChar(oObj:Id)
							ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +DecodeUtf8(oRestPrd:GetResult()),,.F. )
							//MsgInfo(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						Else
							//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestPrd:GetLastError(),,.F. )
						EndIf
					Else
						//MsgAlert(oRestPrd:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestPrd:GetLastError(),,.F. )
					EndIf
				Else
					//MsgAlert(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
				Endif
			Endif
		Else
			//MsgAlert(oRestPrd:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
		Endif
	Else
		ProcLogAtu( "ERRO" , cUrlVtx + cPath + cProdID ,  ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +oRestPrd:GetLastError(),,.F. )
	EndIf

Return cProdID


/*/{Protheus.doc} sfAjust
Função para ajustar caracteres especiais por outros padronizados
@type function
@version  
@author marcelo
@since 30/04/2024
@param cInText, character, param_description
@return variant, return_description
/*/
Static Function sfAjust(cInText)

	Local 	cOut 	:= cInText

	cOut 	:= sfStrTran(cOut)
	cOut 	:= NoAcento(cOut)
	cOut 	:= StrTran(cOut,"Ñ","N")
	cOut 	:= StrTran(cOut,"ñ","n")
	cOut 	:= StrTran(cOut," ","-")
	cOut 	:= StrTran(cOut,"/","-")
	cOut 	:= StrTran(cOut,"\","-")
	cOut 	:= StrTran(cOut,">","-")
	cOut 	:= StrTran(cOut,"<","-")
	cOut 	:= StrTran(cOut,"&","-")
	cOut 	:= StrTran(cOut,"#","-")
	cOut 	:= StrTran(cOut,"*","-")
	cOut 	:= StrTran(cOut,"+","-")
	cOut 	:= StrTran(cOut,"%","-")
	cOut 	:= StrTran(cOut,"@","-")
	cOut 	:= StrTran(cOut,"|","-")
	cOut 	:= StrTran(cOut,";","-")
	cOut 	:= StrTran(cOut,"º","-")
	cOut 	:= StrTran(cOut,"ª","-")
	cOut 	:= StrTran(cOut,"°","-")
	cOut    := StrTran(cout,"Á","A")
	cOut    := StrTran(cOut,"è","e")

Return cOut



/*/{Protheus.doc} sfStrTran
Função para efetuar ajustes de Texto para integração 
@type function
@version  
@author marcelo
@since 01/05/2024
@param cInText, character, param_description
@return variant, return_description
/*/
Static Function sfStrTran(cInText)

	Local 	cOut 	:= cInText

	cOut := StrTran(cOut,Chr(13),"")
	cOut := StrTran(cOut,Chr(10),"")
	cOut := StrTran(cOut,Chr(19),"")
	cOut := StrTran(cOut,'"',"")
	cOut := Alltrim(cOut)

Return cOut
/*
    "Id": 1211,
    "Name": "Terranoble Chardonnay Algarrobo 2022",
    "DepartmentId": 1,
    "CategoryId": 3,
    "BrandId": 2000001,
    "LinkId": "Terranoble-Chardonnay-Algarrobo-2022",
    "RefId": "00249622",
    "IsVisible": true,
    "Description": "Belíssimo exemplar de Chardonnay de um dos melhores terroirs do Chile. Nariz elegante e intenso, com frutas brancas frescas (maçã, pera), limão, notas de baunilha e tostado. Bom corpo, com volume e fruta marcante. A acidez crocante aporta equilíbrio à textura cremosa. Longo final.",
    "DescriptionShort": null,
    "ReleaseDate": "2024-04-30T00:00:00",
    "KeyWords": null,
    "Title": "Terranoble Chardonnay Algarrobo 2022",
    "IsActive": true,
    "TaxCode": "00249622",
    "MetaTagDescription": "Belíssimo exemplar de Chardonnay de um dos melhores terroirs do Chile. Nariz elegante e intenso, com frutas brancas frescas (maçã, pera), limão, notas de baunilha e tostado. Bom corpo, com volume e fruta marcante. A acidez crocante aporta equilíbrio à textura cremosa. Longo final.",
    "SupplierId": null,
    "ShowWithoutStock": true,
    "ListStoreId": [
        1
    ],
    "AdWordsRemarketingCode": null,
    "LomadeeCampaignCode": null
    */
