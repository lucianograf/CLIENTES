#Include 'Totvs.ch'
/*/{Protheus.doc} DCVTXI09
Função para integração de tabelas de preço
@type function
@version  
@author Marcelo Alberto Lauschner
@since 05/08/2024
@param cInCodPro, character, param_description
@param cInIdVtex, character, param_description
@param nInOpc, numeric, param_description
@return variant, return_description
/*/
User Function DCVTXI09(cInCodPro,cInIdVtex,nInOpc,nIdSkuVtex)

	Local   cBody           := ''
	Local   aConectVtx      := U_DCVTXI01()
	Local   cUrlVtx         := "https://api.vtex.com" //aConectVtx[1]
	Local   aHeadOut        := aConectVtx[2]
	Local   cPath           := "/decantervinhos/pricing/prices/""
	Local   oRestSpec
	Local   oObj
	Local   oJson           :=  JsonObject():New()
	Local 	iX
	Local 	aDA1Opc 		:={{"301","enotecabnu"}}//,{"201","enotecabnu"},{"203","enotecasp"}}//,{"301","enotecabnu"}}
	Default cInIdVtex       := U_DCVTXI03(cInCodPro)
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

	If !Empty(cInIdVtex) .And. !Empty(nIdSkuVtex)

		For iX := 1 To Len(aDA1Opc)

			DbSelectArea("DA1")
			DbSetOrder(1)//DA1_FILIAL+DA1_CODTAB+DA1_CODPRO+DA1_INDLOT+DA1_ITEM
			If DbSeek(xFilial("DA1")+aDA1Opc[iX,1] + SB1->B1_COD)

				//Inclusao/alteracao tabela de preco
				If aDA1Opc[iX,1] =='301'

					oRestSpec := FWRest():New(cUrlVtx)
					
					oRestSpec:SetPath(cPath + cValToChar(nIdSkuVtex))
					//oRestSpec:SetPath("/decantervinhos/pricing/prices/"+alltrim(str(cSKUId)))

					oJson   :=  JsonObject():New()
					oJson["basePrice"]	:= DA1->DA1_PRCVEN
					oJson["listPrice"]  := DA1->DA1_PRCVEN
					oJson["costPrice"] 	:= DA1->DA1_PRCVEN
					cBody := EncodeUTF8(oJson:ToJson(), "cp1252")

					If oRestSpec:Put(aHeadOut,cBody)
						If SubStr(oRestSpec:GetLastError(),1,3) == '200'
							//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath + cValToChar(nIdSkuVtex)  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + cBody + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
						Else
							//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "ERRO" , cUrlVtx +  cPath + cValToChar(nIdSkuVtex)  , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
						EndIf
					Else
						ProcLogAtu( "ERRO" , cUrlVtx +  cPath + cValToChar(nIdSkuVtex) , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetResult() + " " +  DecodeUtf8(oRestSpec:GetLastError()),,.F. )
					Endif
				ElseIf aDA1Opc[iX,1] $ "201#203"
					oRestSpec := FWRest():New(cUrlVtx)
					oRestSpec:SetPath(cPath + cValToChar(nIdSkuVtex) + "/fixed/"+aDA1Opc[iX,2] )
					//oRestClient:setPath("/decantervinhos/pricing/prices/"+cItem+"/fixed/"+cEnoteca )
					oJson   :=  JsonObject():New()
					oJson["value"]			:= DA1->DA1_PRCVEN
					oJson["markup"]  		:= 1
					oJson["listPrice"] 		:= 1.02
					oJson["minQuantity"] 	:= 1
					oJsonDate := JsonObject():New()
					oJsonDate["from"] 		:= sfDAteJson(dDataBase-90)
					oJsonDate["to"]			:= sfDAteJson(dDataBase+360)
					
					oJson["dateRange"]		:= oJsonDate
					//oJson["dateRange"]		:= '{"from":"2021-12-30T22:00:00-03:00","to":"2099-01-30T22:00:00-04:00"}'
					
					cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
					oRestSpec:SetPostParams(cBody)

					If oRestSpec:POST(aHeadOut)

						sPostRet := oRestSpec:GetResult()
						If FWJsonDeserialize(sPostRet,@oObj)
							If SubStr(oRestSpec:GetLastError(),1,3) == '200'
								MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
								ProcLogAtu( "MENSAGEM" , cUrlVtx +  cPath +cValToChar(nIdSkuVtex) , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + cBody + " " + DecodeUtf8(oRestSpec:GetResult()),,.F. )
							Else
								MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
								ProcLogAtu( "ERRO" , cUrlVtx +  cPath +cValToChar(nIdSkuVtex) , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSpec:GetLastError()),,.F. )
							EndIf
						Else
							MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
							ProcLogAtu( "ERRO" , cUrlVtx +  cPath +cValToChar(nIdSkuVtex) , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetResult() + " " +  DecodeUtf8(oRestSpec:GetLastError()),,.F. )
						Endif
					Else
						ProcLogAtu( "ERRO" , cUrlVtx +  cPath +cValToChar(nIdSkuVtex) , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetResult() + " " +  DecodeUtf8(oRestSpec:GetLastError()),,.F. )
					Endif
				Endif
			Endif
		Next
	Endif

Return


Static Function sfDAteJson(dInDate,nDayAdd,cInTime)

    Local	cDateRet	:= Substr(DTOS( Date() ),1,4) + "-" + Substr(DTOS( Date() ),5,2) + "-" + Substr(DTOS( Date() ),7,2) +  "T"+ Time()
    Default	nDayAdd 	:= 0
    Default cInTime		:= "00:00:00"

    cDateRet	:= Substr(DTOS( dInDate+nDayAdd ),1,4) + "-" + Substr(DTOS( dInDate+nDayAdd ),5,2) + "-" + Substr(DTOS( dInDate+nDayAdd ),7,2) +  "T" + cInTime

Return cDateRet
