#Include "Protheus.ch"


User Function FileEco(lReport)

	Local aParam	:= {}
	Local aRetPar 	:= {}
	Local oLayout 	:= GetLayout()
	Local _cFile	:= ""
	Private aData 	:= {}
	Private _cBanc	:= ""
	Private _cAgen	:= ""
	Private _cCont	:= ""
	Default lReport	:= .F.

	aAdd(aParam, {1,"Banco",Space(TamSx3("A6_COD")[1]),"",".T.","SA6",".T.",50,.T.})
	aAdd(aParam, {1,"Agencia",Space(TamSx3("A6_AGENCIA")[1]),"",".T.","",".T.",50,.T.})
	aAdd(aParam, {1,"Conta",Space(TamSx3("A6_NUMCON")[1]),"",".T.","",".T.",50,.T.})
	aAdd(aParam, {6, "Arquivo", Space(250), "", "", ".F.", 80, .T., "Arq. Integracao|*.csv", "", GETF_LOCALHARD + GETF_NETWORKDRIVE})

	While .T.
		If ParamBox(aParam, "Integracao Ecommerce - PAGARME", @aRetPar, , , , , , , "Integracao", .T., .T.)
			_cBanc :=aRetPar[1]
			_cAgen :=aRetPar[2]
			_cCont :=aRetPar[3]
			_cFile :=aRetPar[4]

			if !File(_cFile)
				FwAlertInfo("Arquivo invalido!")
				loop
			endif

			if !U_GSEEK("SA6",1,xFilial("SA6")+_cBanc+_cAgen+_cCont)
				FwAlertInfo("Dados do banco, agencia e conta invalidos!")
				loop
			endif

			FWMsgRun(, {|oMsg| ReadFile(oMsg,_cFile , oLayout)}, "Processando", "Importando arquivo...")
			FWMsgRun(, {|oMsg| ProcFile(oMsg, lReport)}, "Processando", "Processando arquivo...")

			Report(oLayout, aData)
		else
			exit
		EndIf
	enddo

Return


Static Function GetLayout()

	Local cJSON	:= ""
	Local oJSON := Nil

/*
	cJSON += '['
	cJSON += '	{"Field": "NSU", 	"Init": 5,		"Type": "C", "Size": 12, 	"Decimal": 0, "Picture": "@!",	 				"Title": "Id.Transacao"},'
	cJSON += '	{"Field": "INST", 	"Init": 6,		"Type": "N", "Size": 2,		"Decimal": 0, "Picture": "@E 99", 				"Title": "Parcela"},'
	cJSON += '	{"Field": "VALUE",	"Init": 8,		"Type": "N", "Size": 11,	"Decimal": 2, "Picture": "@E 9,999,999,999.99",	"Title": "Valor Bruto"},'
	cJSON += '	{"Field": "TXADM",	"Init": 12,		"Type": "N", "Size": 11, 	"Decimal": 2, "Picture": "@E 9,999,999,999.99",	"Title": "Taxa"},'
	cJSON += '	{"Field": "NETVL", 	"Init": 13,		"Type": "N", "Size": 11, 	"Decimal": 2, "Picture": "@E 9,999,999,999.99",	"Title": "Valor Líquido"},'
	cJSON += '	{"Field": "DTPAY", 	"Init": 1,		"Type": "D", "Size": 8, 	"Decimal": 0, "Picture": "@D", 					"Title": "Data do Crédito"},'
	cJSON += '	{"Field": "STATUS", "Init": 0,		"Type": "C", "Size": 22, 	"Decimal": 0, "Picture": "@!", 					"Title": "Status"}'
	cJSON += ']'
*/
	cJSON += '['
	cJSON += '	{"Field": "NSU", 	"Init": 4,		"Type": "C", "Size": 12, 	"Decimal": 0, "Picture": "@!",	 				"Title": "Id.Transacao"},'
	cJSON += '	{"Field": "INST", 	"Init": 5,		"Type": "N", "Size": 2,		"Decimal": 0, "Picture": "@E 99", 				"Title": "Parcela"},'
	cJSON += '	{"Field": "VALUE",	"Init": 7,		"Type": "N", "Size": 11,	"Decimal": 2, "Picture": "@E 9,999,999,999.99",	"Title": "Valor Bruto"},'
	cJSON += '	{"Field": "TXADM",	"Init": 11,		"Type": "N", "Size": 11, 	"Decimal": 2, "Picture": "@E 9,999,999,999.99",	"Title": "Taxa"},'
	cJSON += '	{"Field": "NETVL", 	"Init": 12,		"Type": "N", "Size": 11, 	"Decimal": 2, "Picture": "@E 9,999,999,999.99",	"Title": "Valor Líquido"},'
	cJSON += '	{"Field": "DTPAY", 	"Init": 1,		"Type": "D", "Size": 8, 	"Decimal": 0, "Picture": "@D", 					"Title": "Data do Crédito"},'
	cJSON += '	{"Field": "STATUS", "Init": 0,		"Type": "C", "Size": 22, 	"Decimal": 0, "Picture": "@!", 					"Title": "Status"}'
	cJSON += ']'

	// Cria JSON de retorno.
    oJSON := JSONObject():New()
	// Realiza o parser do JSON.
    oJSON:FromJSON(cJSON)

Return oJSON


Static Function ReadFile(oMsg, cPathFile, oLayout)

	Local aLines	:= {}
	Local cLine		:= ""
	Local nField	:= 0
	Local nLine		:= 0
	Local oFile		:= Nil
	Local _aLinha	:= {}

	oFile := FWFileReader():New(cPathFile)

	If oFile:Open()
		aLines := oFile:GetAllLines()
		oFile:Close()

		For nLine := 2 To Len(aLines)
			oMsg:SetText("Realizando leitura do arquivo (" + cValToChar(nLine) + "/" + cValToChar(Len(aLines)) + ")")
			oMsg:CtrlRefresh()
			cLine := aLines[nLine]
			_aLinha	:= StrTokArr(cLine, ";")
			// Somente registros detalhe.
			//If _aLinha[2] == "Transação"
			If _aLinha[3] == "Transação" .or.  _aLinha[3] == "Crédito"
				// Nova linha.
				AAdd(aData, JSONObject():New())

				For nField := 1 To Len(oLayout)
					If oLayout[nField]["Init"] > 0
						// Coleta o conteúdo conforme o layout.
						cValue := _aLinha[oLayout[nField]["Init"]]
						ATail(aData)[oLayout[nField]["Field"]] := CToType(cValue, oLayout[nField])
					EndIf
				Next nField
				ATail(aData)["STATUS"] := "Título não encontrado"
			EndIf
		Next nLine
	Else
		ShowHelpDlg("NoOpen", {"Não foi possível abrir o arquivo informado."}, 1, {"Tente novamente."}, 1)
	EndIf

	FreeObj(oFile)

Return


Static Function CToType(cValue, oJSON)

	If oJSON["Type"] == "N"
		cValue:= StrTran(cValue,".","")
		cValue:= StrTran(cValue,",",".")
		uValue := Val(cValue)
		/*If oJSON["Decimal"] > 0
			uValue := uValue/(10^oJSON["Decimal"])
		EndIf*/
	ElseIf oJSON["Type"] == "D"
		cValue:=Subs(cValue,1,10)
		uValue := CToD(cValue)
	Else
		uValue := cValue
	EndIf

Return uValue


Static Function ProcFile(oMsg, lReport)

	Local nCount	:= 0
	//Local nValTx	:= 0
	Local oSE1		:= Nil
	Local _nRPed 	:= 0

	DBSelectArea("SC5")
	DBSelectArea("SE1")

	For nCount := 1 To Len(aData)
		_nRPed 	:= GetNF(aData[nCount]["NSU"])
		If _nRPed>0
			If !(oSE1 := GetTitPV(aData[nCount], lReport)) == Nil
				SE1->(DBGoTo(oSE1["RECNO"]))

				If !lReport .And. BxTit(@aData[nCount])
					//nValTx += aData[nCount]["TXADM"]
				EndIf
			else
				aData[nCount]["STATUS"] :='Titulo não localizado na SE1 ou Baixado Anteriormente!'
			endif
		else
			aData[nCount]["STATUS"] :='Pedido não localizado'
		EndIf
	Next nCount

	// Gera movimentação bancária com as taxas.
	/*If nValTx > 0
		MovBankTx(nValTx)
	EndIf*/

Return


Static Function GetTitPV(oJSON, lReport)

	Local cFilter 	:= ""
	Local oSE1		:= Nil
	Local _cParc 	:= oJSON["INST"]

	if Empty(_cParc) .or. Alltrim(_cParc)=="-" 
		_cParc:= ''
	else
		_cParc:=strzero(_cParc,2)
	endif


	cFilter := "E1_FILIAL = '" + XFilial('SE1') + "'"
	cFilter += ".And. E1_PEDIDO = '" + SC5->C5_NUM + "'"
	cFilter += ".And. (E1_PARCELA = '" + PadR(_cParc, TamSX3("E1_PARCELA")[1]) + "' .Or. Empty(E1_PARCELA)) "
	//cFilter += ".And. E1_VALOR = " + cValToChar(oJSON["VALUE"])

	DBSelectArea("SE1")
	SE1->(DBGoTop())
	SE1->(DBSetFilter(&("{|| " + cFilter + "}"), cFilter))
	SE1->(DBGoTop())

	If !SE1->(EOF())
		oJSON["STATUS"] := IIf(Empty(SE1->E1_BAIXA), "Valor Recebido", "Baixado anteriormente")
		If !lReport .and. !Empty(SE1->E1_BAIXA)
			Return oSE1
		EndIf
		oSE1 := JSONObject():New()
		oSE1["RECNO"] := SE1->(Recno())
		oSE1["VALUE"] := SE1->E1_VALOR
	EndIf

Return oSE1


Static Function BxTit(oJSON)

	Local aBaixa 		:= {}
	Local nValTx:= 0
	Local dDat:= dDatabase
	Private lMsErroAuto := .F.

	dDatabase:= IIF(SE1->E1_EMISSAO>oJSON["DTPAY"],SE1->E1_EMISSAO,oJSON["DTPAY"])

	AAdd(aBaixa, {"E1_PREFIXO",		SE1->E1_PREFIXO,	Nil})
	AAdd(aBaixa, {"E1_NUM",			SE1->E1_NUM,		Nil})
	AAdd(aBaixa, {"E1_TIPO",		SE1->E1_TIPO,		Nil})
	AAdd(aBaixa, {"AUTMOTBX",		"NOR",				Nil})
	AAdd(aBaixa, {"AUTBANCO",		_cBanc,	Nil})
	AAdd(aBaixa, {"AUTAGENCIA",		_cAgen,		Nil})
	AAdd(aBaixa, {"AUTCONTA",		_cCont,		Nil})
	AAdd(aBaixa, {"AUTDTBAIXA",		dDataBase,			Nil})
	AAdd(aBaixa, {"AUTDTCREDITO",	dDataBase,			Nil})
	AAdd(aBaixa, {"AUTHIST",		"PAGTO ECOMM",	Nil})
	AAdd(aBaixa, {"AUTJUROS"    ,0                      ,Nil,.T.})
	AAdd(aBaixa, {"AUTVALREC",		SE1->E1_VALOR,		Nil})

	MSExecAuto({|x, y| FINA070(x, y)}, aBaixa, 3)

	oJSON["STATUS"] := IIf(lMsErroAuto, "Erro ao baixar título", "Valor Recebido")

	nValTx :=oJSON["TXADM"]
	
	MovBankTx(nValTx)

	dDatabase:= dDat
Return !lMsErroAuto


Static Function MovBankTx(nValue)

	Local aSE5		:= {}
	Local cAgencia 	:= _cAgen//SuperGetMV("SL_AGEBNO", .F.)
	Local cBanco 	:= _cBanc//SuperGetMV("SL_BCOBNO", .F.)
	Local cConta 	:= _cCont//SuperGetMV("SL_CTABNO", .F.)
	Local cNaturez 	:= SuperGetMV("DC_NATBNO", .F.,"20413")

	nValue:= IIF(nValue<0,nValue*-1,nValue)

	Private lMsErroAuto := .F.

	AAdd(aSE5, {"E5_DATA",		dDataBase,			Nil})
    AAdd(aSE5, {"E5_MOEDA",		"M1",				Nil})
    AAdd(aSE5, {"E5_VALOR",		nValue,				Nil})
    AAdd(aSE5, {"E5_NATUREZ",	cNaturez,			Nil})
    AAdd(aSE5, {"E5_BANCO",		cBanco,				Nil})
    AAdd(aSE5, {"E5_AGENCIA",	cAgencia,			Nil})
    AAdd(aSE5, {"E5_CONTA",		cConta,				Nil})
	AAdd(aSE5, {"E5_HISTOR",	Alltrim(SE1->E1_NUM)+" TX",	Nil})

	    //AAdd(aSE5, {"E5_HISTOR",	_ctxt/*"TAXAS ECOMM"*/,	Nil})

	MSExecAuto({|x, y, z| FINA100(x, y, z)}, 0, aSE5, 3)

	if lMsErroAuto
		MostraErro()
	endif

Return !lMsErroAuto


Static Function Report(aHeader, aData)

	Local aLines	:= {}
	Local nCol		:= 0
	Local nLine 	:= 0
	Local oReport 	:= Nil

	For nLine := 1 To Len(aData)
		AAdd(aLines, Array(Len(aHeader)))
		For nCol := 1 To Len(aHeader)
			ATail(aLines)[nCol] := aData[nLine][aHeader[nCol]["Field"]]
		Next nCol
	Next nLine

	oReport := DefReport(aHeader, aLines)
	oReport:PrintDialog()

Return


Static Function DefReport(aHeader, aData)

	Local nField	:= 0
	Local oReport 	:= Nil

	oReport := TReport():New("Pagamentos e-commerce",;
							"Relatório de Conferência",;
							"",;
							{|oReport| Print(oReport, aHeader, aData)})
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) // Folha A4.
	oReport:SetPortrait()

	oSection := TRSection():New(oReport, "Dados")

	// Cria colunas do relatório.
	For nField := 1 To Len(aHeader)
		TRCell():New(oSection, aHeader[nField]["Field"], , aHeader[nField]["Title"], aHeader[nField]["Picture"], aHeader[nField]["Size"])
	Next nField

Return oReport


Static Function Print(oReport, aHeader, aData)

	Local bBlock	:= {||}
	Local nCol		:= 0
	Local nLine 	:= 0
	Local oSection 	:= oReport:Section(1)

	oReport:SetMeter(Len(aData))

	oSection:Init()

	For nLine := 1 To Len(aData)
		// Aborta se a impressão for cancelada.
		If oReport:Cancel()
			Exit
		EndIf

		For nCol := 1 To Len(aHeader)
			If aHeader[nCol]["Type"] == 'D'
				bBlock := &("{|| '" + DToC(aData[nLine][nCol]) + "'}")
			ElseIf aHeader[nCol]["Type"] == 'N'
				bBlock := &("{|| " + cValToChar(aData[nLine][nCol]) + "}")
			Else
				bBlock := &("{|| '" + aData[nLine][nCol] + "'}")
			EndIf
			oSection:Cell(aHeader[nCol]["Field"]):SetBlock(bBlock)
		Next

		oReport:SetMsgPrint("Imprimindo registros " + cValToChar(nLine) + "/" + cValToChar(Len(aData)))
		oReport:IncMeter()

		oSection:PrintLine()
	Next nLine

	oSection:Finish()

Return

/*/{Protheus.doc} GetNF
	(long_description)
	@type  Static Function
	@author user
	@since 10/05/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function GetNF(_cID)
Local _cQuery:=" "
Local _cAlias	
Local _nRPed := 0

	_cQuery+=" select C5_NUM, C5_NOTA, R_E_C_N_O_ REC from "+RetSqlName("SC5")+" C5 "
	_cQuery+=" where C5_FILIAL='"+xFilial("SC5")+"' and C5_XTID='"+_cID+"' "
	_cQuery+=" and C5.D_E_L_E_T_=' ' "

	_cAlias:= U_ExeQry(_cQuery)

	if !(_cAlias)->(Eof())
		_nRPed:= (_cAlias)->REC
		DBSELECTAREA( "SC5" )
		DbGoTo(_nRPed)
		(_cAlias)->(DbSkip())
	EndIF

	U_GCLOSEA(_cAlias)

Return _nRPed

/*/{Protheus.doc} User Function FileEcoT
	(long_description)
	@type  Function
	@author user
	@since 23/05/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
User Function FileEcoT()
_cBanc:= 'VP'
_cAgen:= '00000'
_cCont:= '0000000000'


MovBankTx(10)
	
Return 
