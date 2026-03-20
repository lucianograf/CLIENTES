#Include 'Totvs.ch'
/*/{Protheus.doc} DCVTXI05
Função para integrar regras de venda
@type function
@version  
@author Marcelo Alberto Lauschner
@since 05/08/2024
@param cInCodPro, character, param_description
@param cInIdVtex, character, param_description
@return variant, return_description
/*/
User Function DCVTXI05(cInCodPro,cInIdVtex)

	Local   cBody           := ''
	Local   aConectVtx      := U_DCVTXI01()
	Local   cUrlVtx         := aConectVtx[1]
	Local   aHeadOut        := aConectVtx[2]
	Local   cPath           := "/api/catalog/pvt/product/"
	Local   oRestSales
    Local   lRet            := .F. 
    Default cInIdVtex       := U_DCVTXI03(cInCodPro)

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

	If !Empty(cInIdVtex)
		
		//trade policies / politicas comerciais
        cBody := ''
        oRestSales := FWRest():New(cUrlVtx)
		oRestSales:SetPath(cPath + cInIdVtex + "/salespolicy/1")
		oRestSales:SetPostParams(EncodeUTF8(cBody, "cp1252"))

		If oRestSales:Post(aHeadOut)
			//MsgInfo(oRestSales:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cInIdVtex + "/salespolicy/1" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + DecodeUtf8(oRestSales:GetResult()),,.F. )
			lRet    := .T.
		Else
			//MsgAlert(oRestSales:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ProcLogAtu( "ERRO" , cUrlVtx + cPath + cInIdVtex + "/specification" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSales:GetLastError(),,.F. )
		Endif
    Endif 
Return lRet 
