#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'totvs.ch'

/*/{Protheus.doc} GMCOMC08
Tela para consulta de Pedidos de venda em aberto 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 17/10/2020
@return return_type, return_description
/*/
User Function MLFATC08()

Return sfTela()


Static Function sfTela()

	Local 	lRet 			:= .F.
	Local	cIniSearch		:= ""
	Local	nPosColA		:= 0
	Local   aTitleCpo  		:= {}
	Local   aTamCpo    		:= {}
	Local   nXAux
	Local	cCpoAux			:= GetNewPar("DC_XBCPO08","C5_EMISSAO/C5_TRANSP")
	Local	aCpoArr 		:= StrToKarr(StrTran(cCpoAux,"#","/"),"/")
	Private aCpoSB1    		:= {"C5_FILIAL","C5_NUM","C6_ITEM","C5_CLIENTE","C5_LOJACLI","C6_PRODUTO","C6_QTDVEN","C6_PRCVEN","C6_VALOR","B1_DESC","B1_POSIPI","A1_NREDUZ"}
	Private aCBoxCpo		:= {}
	Private oDlg,oPanelTop,oPanelAll,oPanelBot,oPesquisa,oButton,oButton2,oButton3,oButton4
	Private oBrowse
	Private aBrowse := {}
	Private cPesquisa := Space(150)
	Private cFilterAux 		:= ""
	Private cFilIniES		:= ""
	Private cFilDesc		:= ""
	Private oFilterAux
	Private cBoxOrder		:= ""
	Private oBoxOrder
	Private lF3XitPed		:= ReadVar() == "M->XIT_PEDIDO"
	Private cFilXitPed		:= ""
	Private cFilXitCod 		:= ""

	// Verifica campos especificos do cliente
	For nXAux := 1 To Len(aCpoArr)
		If aScan(aCpoSB1,{|x| Alltrim(x) == aCpoArr[nXAux] }) == 0
			Aadd(aCpoSB1,aCpoArr[nXAux])
		Endif
	Next

	// Monta a descrição das colunas
	For nXAux := 1 To Len(aCpoSB1)
		If nXAux == 1
			cBoxOrder	:= FWX3Titulo(aCpoSB1[nXAux])
		Endif
		Aadd(aCBoxCpo,{	aCpoSB1[nXAux],;
			FWSX3Util():GetFieldType(aCpoSB1[nXAux]),;
			GetAVPCombo(aCpoSB1[nXAux])})

		Aadd(aTitleCpo,FWX3Titulo(aCpoSB1[nXAux]))
		// Calcula o tamanho das colunas
		Aadd(aTamCpo,CalcFieldSize(FWSX3Util():GetFieldType(aCpoSB1[nXAux]),TamSX3(aCpoSB1[nXAux])[1],TamSX3(aCpoSB1[nXAux])[2],X3Picture(aCpoSB1[nXAux]) ,FWX3Titulo(aCpoSB1[nXAux]))/3 )
	Next nXAux

	DEFINE DIALOG oDlg TITLE "Consulta de Pedidos de Venda " + Iif(lF3XitPed,"","em Aberto") FROM 001,001 TO 550,1200 PIXEL

	/************************************************************************************/
	/* PAINEL SUPERIOR																	*/
	/************************************************************************************/
	oPanelTop := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,30,.T.,.F.)
	oPanelTop:Align := CONTROL_ALIGN_TOP

	oPesquisa := TGet():New(003,005,{|u| If(PCount() > 0,cPesquisa := u,cPesquisa)},oPanelTop,150,010,,,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"",cPesquisa,,,,,,,"Texto para pesquisa",1 )
	oPesquisa:bLostFocus := {|| MsgRun("Buscando Pedidos de Venda...","Pedidos de Venda",{||sfDados(cPesquisa)})}

	@ 012,160 Say "Ordenar por:" Pixel of oPanelTop
	@ 011,200 MsComboBox oBoxOrder Var cBoxOrder Items aTitleCpo Size 65,11 Pixel Of oPanelTop
	oBoxOrder:bChange	:= {|| sfOrderAcols(oBoxOrder:nAt) }

	oButton 	:= TButton():New(010, 288," Pesquisar ",oPanelTop,{|| MsgRun("Buscando Pedidos de Venda...","Pedidos de Venda",{||sfDados(cPesquisa)})},037,013,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton2 	:= TButton():New(010, 340," Limpar ",oPanelTop,{|| MsgRun("Buscando Pedidos de Venda...","Pedidos de Venda",{|| cPesquisa := Space(150) ,cFilDesc := "", cFilterAux := "",sfDados(cPesquisa)})},037,013,,,.F.,.T.,.F.,,.F.,,,.F. )


	/************************************************************************************/
	/* PAINEL CENTRAL																	*/
	/************************************************************************************/
	oPanelAll:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,200,200,.T.,.F.)
	oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT

	oBrowse := TCBrowse():New(01,01,100,100,,aTitleCpo,aTamCpo,oPanelAll,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrowse:bLDblClick := {|| lRet := sfReturn(oBrowse:aArray,oBrowse:nAt), oDlg:End() }

	oBrowse:bHeaderClick := {||  (nPosColA := oBrowse:ColPos, sfDados(cPesquisa,nPosColA,oBrowse:aArray[oBrowse:nAt,nPosColA]), oBrowse:Refresh()) }
	cCSS :=	 CRLF+"/* Componentes que herdam da TCBrowse:";
		+CRLF+"   BrGetDDb, MsBrGetDBase,MsSelBr, TGridContainer, TSBrowse, TWBrowse */";
		+CRLF+"QTableWidget {";
		+CRLF+"  gridline-color: #632423; /*Cor da grade*/";
		+CRLF+"  color: #000000; /*Cor da fonte*/";
		+CRLF+"  font-size: 11px; /*Tamanho da fonte*/";
		+CRLF+"  background: #FFFFFF; /*Cor do fundo da Grid*/";
		+CRLF+"  alternate-background-color: #C0D9D9; /*Cor do zebrado*/";
		+CRLF+"  selection-background-color: qlineargradient(x1: 0, y1: 0, x2: 0.8, y2: 0.8,";
		+CRLF+"                              stop: 0 #FFFF99, stop: 1 #FFCC00); /*Cor da linha selecionada*/";
		+CRLF+"}";
		+CRLF+"/* Acoes quando a celula for selecionada, aqui mudo a cor de fundo */";
		+CRLF+"QTableView:item:selected:focus {background-color: #FBD5B5} /*Cor da celula selecionada*/"
	oBrowse:SetCss(cCSS)

	oPanelBot := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,20,.T.,.F.)
	oPanelBot:Align := CONTROL_ALIGN_BOTTOM

	oButton2 := TButton():New(05, 005," OK ",oPanelBot,{|| lRet := sfReturn(oBrowse:aArray,oBrowse:nAt), oDlg:End() },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton3 := TButton():New(05, 047," Cancelar "	,oPanelBot,{|| oDlg:End() },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton4 := TButton():New(05, 089," Visualizar "	,oPanelBot,{|| sfConsulta(oBrowse:aArray,oBrowse:nAt) },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )

	@ 05,140 MsGet oFilterAux Var cFilDesc Size 350,10 Pixel Of oPanelBot When .F.

	If Type(ReadVar()) == "C"
		cIniSearch	:= &(ReadVar())

		If lF3XitPed
			cFilXitPed	:= M->XIT_PEDIDO
			cFilXitCod	:= oMulti:aCols[oMulti:nAt,nPxProd]
		Endif
	Endif

	sfDados(cIniSearch)

	ACTIVATE DIALOG oDlg CENTERED ON Init (Iif(lF3XitPed,oBrowse:SetFocus(),Nil))

Return lRet


/*/{Protheus.doc} sfReturn
(Posiciona na SB1 do produto, pois consulta pega SB1->B1_COD como retorno)
@type function
@author Iago Luiz Raimondi
@since 13/10/2016
@version 1.0
@param aArray, array, (Descrição do parâmetro)
@param nPosi, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfReturn(aArray,nPosi)

	Local lRet := .T.

	If lF3XitPed
		DbSelectArea("SC6")
		DbSetOrder(1)
		If DbSeek(aArray[nPosi][1]+aArray[nPosi][2]+aArray[nPosi][3])
			lRet	:= .T.
		Else
			lRet := .F.
		Endif
	Else

		DbSelectArea("SC6")
		DbSetOrder(1)
		If DbSeek(aArray[nPosi][1]+aArray[nPosi][2]+aArray[nPosi][3])

		Else
			lRet := .F.
		Endif
	Endif

Return lRet


Static Function sfOrderAcols(nColOrder)

	Local	cCodSearch	:= oBrowse:aArray[oBrowse:nAt][1] // Fixo coluna 1
	Local	nZ

	aSort(oBrowse:aArray,,,{|x,y| x[nColOrder] < y[nColOrder]} )
	oBrowse:Refresh()

	For nZ := 1 To Len(oBrowse:aArray)
		If oBrowse:aArray[nZ][1] == cCodSearch
			oBrowse:nAt	:= nZ
			Exit
		Endif
	Next

	oBrowse:Refresh()

Return


/*/{Protheus.doc} sfReturn
(AxVisual para produto posicionado)
@type function
@author Iago Luiz Raimondif
@since 13/10/2016
@version 1.0
@param aArray, array, (Descrição do parâmetro)
@param nPosi, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfConsulta(aArray,nPosi)

	Private	ALTERA		:= .F.
	Private	INCLUI		:= .F.

	DbSelectArea("SC5")
	DbSetOrder(1)
	If DbSeek(aArray[nPosi][1]+aArray[nPosi][2]	)
		MATA410(/*xAutoCab*/,/*xAutoItens*/,2/*nOpcAuto*/,/*lSimulacao*/,"A410Visual"/*cRotina*/,/*cCodCli*/,/*cLoja*/)
		lRet := .F.
	Endif


Return


/*/{Protheus.doc} sfDados
(Busca dados e monta array)
@type function
@author Iago Luiz Raimondi
@since 13/10/2016
@version 1.0
@param cTexto, character, (String para filtrar)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfDados(cTexto,nInCol,xInVal)

	Local 	cQry
	Local	aBrowse 	:= {}
	Local 	nI ,nz
	Local	aCbox		:= {}
	Local	cOpcBox		:= ""
	Local	nPosAt		:= 0
	Local	lAddFilCpo	:= .F.
	Default	nInCol		:= 0
	Default xInVal		:= Nil

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif


	cQry := "SELECT "
	For nI := 1 To Len(aCpoSB1)
		If nI > 1
			cQry += ","
		Endif
		cQry += aCpoSB1[nI]
	Next

	cQry += "  FROM " + RetSqlName("SC6") + " C6 "
	cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 "
	cQry += "    ON B1.D_E_L_E_T_ =' ' "
	If SF4->(FieldPos("B1_MSBLQL")) > 0
		cQry += "   AND B1.B1_MSBLQL != '1'"
	Endif
	cQry += "   AND B1_COD = C6_PRODUTO "
	cQry += "   AND B1_FILIAL = '"  + xFilial("SB1")  + "' "
	cQry += " INNER JOIN " + RetSqlName("SA1") + " A1 "
	If SF4->(FieldPos("A1_MSBLQL")) > 0
		cQry += "   AND A1.A1_MSBLQL != '1'"
	Endif
	cQry += "    ON A1.D_E_L_E_T_ =' ' "
	cQry += "   AND A1_LOJA = C6_LOJA "
	cQry += "   AND A1_COD = C6_CLI "
	cQry += "   AND A1_FILIAL = '"  + xFilial("SA1")  + "' "
	cQry += " WHERE C6.D_E_L_E_T_ = ' '"


	If IsInCallStack("U_XMLDCONDOR") .And. Type("cCodForn") == "C" .And. Type("cLojForn") == "C"
		If (aArqXml[oArqXml:nAt,nPosTpNota] $ "B#D")
			// Novo procedimento que permite especificar qual Código e Loja
			If !Empty(CONDORXML->XML_CODLOJ)
				DbSelectArea("SA1")
				DbSetOrder(1)
				DbSeek(xFilial("SA1")+CONDORXML->XML_CODLOJ)
			Else
				DbSelectArea("SA1")
				DbSetOrder(3)
				DbSeek(xFilial("SA1")+CONDORXML->XML_EMIT)
			Endif
			cQry += "   AND C7_FORNECE = '"+cCodForn+"' "

		Else
			// Novo procedimento que permite especificar qual Código e Loja
			If !Empty(CONDORXML->XML_CODLOJ)
				DbSelectArea("SA2")
				DbSetOrder(1)
				DbSeek(xFilial("SA2")+CONDORXML->XML_CODLOJ)
			Else
				DbSelectArea("SA2")
				DbSetOrder(3)
				DbSeek(xFilial("SA2")+CONDORXML->XML_EMIT)
			Endif
			cQry += "   AND C7_FORNECE = '"+cCodForn+"' "

			If Type("lConsLoja") == "L" .And. lConsLoja
				cQry += "   AND C7_LOJA = '"+cLojForn+"' "
			Endif

		Endif

	Endif


	If !Empty(AllTrim(cTexto))
		aArr := StrToKarr(AllTrim(Upper(NoAcento(StrTran(cTexto,"'"," "))))," ")

		cQry += "   AND ("
		cQry += "		 ("

		For nI := 1 To Len(aCpoSB1)


			// Verifica se o campo é tipo Numérico
			If FWSX3Util():GetFieldType(aCpoSB1[nI]) == "C"
				If lAddFilCpo
					cQry += "			     ) OR ("
				Endif

				lAddFilCpo	:= .T.
				For nz := 1 To Len(aArr)
					If nz > 1
						cQry += " AND "
					EndIf
					cQry += " UPPER("+aCpoSB1[ni]+") LIKE '%" + aArr[nz] +"%'"
				Next
			Endif
		Next

		cQry += "       )"
		cQry += "      )"

	EndIf

	If nInCol > 0
		For nI := 1 To Len(aCpoSB1)
			If nI == nInCol
				// Verifica se o campo é tipo Numérico
				If FWSX3Util():GetFieldType(aCpoSB1[nI]) == "N"
					cFilterAux += " AND " + aCpoSB1[ni] + " = " + cValToChar(xInVal)
					cFilDesc	+= " e " + Alltrim(FWX3Titulo(aCpoSB1[ni])) + " = " + Alltrim(cValToChar(xInVal))
				Else
					nPosAt	:= At("=",xInVal)

					cFilterAux += " AND " + aCpoSB1[ni] + " = '" + IIf(nPosAt > 0 , Substr(xInVal,1,nPosAt-1),xInVal) + "' "
					cFilDesc	+= " e " + Alltrim(FWX3Titulo(aCpoSB1[ni])) + " = '" + Alltrim(xInVal) + "' "
				Endif
			Endif
		Next
	Endif

	cQry += cFilterAux
	cQry += cFilIniES

	//cQry += " ORDER BY B1.B1_DESC"
	cQry += " ORDER BY " + cValToChar(oBoxOrder:nAt)

	TCQUERY cQry NEW ALIAS "QRY"

	If QRY->(EOF())
		aTmp := {}
		For nI := 1 To Len(aCpoSB1)
			// Verifica se o campo é tipo Numérico
			If aCBoxCpo[nI][2] == "N" //FWSX3Util():GetFieldType(aCpoSB1[nI]) == "N"
				Aadd(aTmp,0)
			Else
				Aadd(aTmp," ")
			Endif
		Next

		Aadd(aBrowse,aTmp)
	Else
		While QRY->(!EOF())
			aTmp := {}

			For nI := 1 To Len(aCpoSB1)
				aCBox	:= aCBoxCpo[nI][3] //GetAVPCombo(aCpoSB1[nI])
				If Len(aCBox) > 1
					cOpcBox		:=  &("QRY->"+aCpoSB1[nI])
					nPosBox	:= aScan(aCBox,{|x| Alltrim(Substr(x,1,Len(cOpcBox)))  == cOpcBox })
					If nPosBox > 0
						Aadd(aTmp, Alltrim(aCBox[ nPosBox  ]))
					Else
						Aadd(aTmp,&("QRY->"+aCpoSB1[nI]))
					Endif
				ElseIf aCBoxCpo[nI][2] == "D"
					If !Empty(&("QRY->"+aCpoSB1[nI]))
						Aadd(aTmp,STOD(&("QRY->"+aCpoSB1[nI])))
					Else
						Aadd(aTmp,&("QRY->"+aCpoSB1[nI]))
					Endif
				Else
					Aadd(aTmp,&("QRY->"+aCpoSB1[nI]))
				Endif

			Next

			Aadd(aBrowse,aTmp)

			QRY->(dbSkip())
		End
	EndIf


	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	oBrowse:SetArray(aBrowse)
	// Corrige falha quando o número de registros da nova pesquisa for menos que a posição anterior do Browser
	If oBrowse:nAt > Len(aBrowse)
		oBrowse:nAt	:= Len(aBrowse)
	Endif
	oBrowse:bLine := {|| aBrowse[oBrowse:nAt] }

	oBrowse:Refresh()
	oFilterAux:Refresh()

	If !Empty(cTexto)
		oBrowse:SetFocus()
	Endif

Return

/*
Static Function sfSXB()

	Local   cFilSX6 := Space(Len(cFilAnt))

	If FindFunction("U_MLFATC08")
		DbSelectArea("SX6")
		DbSetOrder(1)
		If !DbSeek(cFilSX6+"XM_F3SC7")
			RecLock("SX6",.T.)
			SX6->X6_FIL     	:= cFilSX6
			SX6->X6_VAR     	:= "XM_F3SC7"
			SX6->X6_TIPO    	:= "C"
			SX6->X6_DESCRIC 	:= "Central NF-e/Consulta Padrão F3 "
			SX6->X6_DESC1		:= "Consulta Ped.Compras em Aberto"
			SX6->X6_DESC2		:= "Default SC7"
			MsUnLock()
			PutMv("XM_F3SC7","SC7")
		EndIf



		DbSelectArea("SXB")
		DbSetOrder(1)//XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA
		If DbSeek(Padr("SC6DEC",Len(SXB->XB_ALIAS)) + Padr("1",Len(SXB->XB_TIPO)) + Padr("01",Len(SXB->XB_SEQ)) + Padr("RE",Len(SXB->XB_COLUNA)))
			// Se já existe não faz nada
		Else
			RecLock("SXB",.T.)
			SXB->XB_ALIAS	:= "SC6DEC"
			SXB->XB_TIPO	:= "1"
			SXB->XB_SEQ		:= "01"
			SXB->XB_COLUNA	:= "RE"
			SXB->XB_DESCRI	:= "Ped.Venda Decanter"
			SXB->XB_DESCSPA	:= "Ped.Venda Decanter"
			SXB->XB_DESCENG	:= "Ped.Venda Decanter"
			SXB->XB_CONTEM	:= "SC6"
			SXB->XB_WCONTEM	:= ""
			MsUnlock()
		Endif

		DbSelectArea("SXB")
		DbSetOrder(1)//XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA
		If DbSeek(Padr("SC6DEC",Len(SXB->XB_ALIAS)) + Padr("2",Len(SXB->XB_TIPO)) + Padr("01",Len(SXB->XB_SEQ)) + Padr(" ",Len(SXB->XB_COLUNA)))
			// Se já existe não faz nada
		Else
			RecLock("SXB",.T.)
			SXB->XB_ALIAS	:= "SC6DEC"
			SXB->XB_TIPO	:= "2"
			SXB->XB_SEQ		:= "01"
			SXB->XB_COLUNA	:= " "
			SXB->XB_DESCRI	:= ""
			SXB->XB_DESCSPA	:= ""
			SXB->XB_DESCENG	:= ""
			SXB->XB_CONTEM	:= "U_MLFATC08()"
			SXB->XB_WCONTEM	:= ""
			MsUnlock()
		Endif

		DbSelectArea("SXB")
		DbSetOrder(1)//XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA
		If DbSeek(Padr("SC6DEC",Len(SXB->XB_ALIAS)) + Padr("5",Len(SXB->XB_TIPO)) + Padr("01",Len(SXB->XB_SEQ)) + Padr(" ",Len(SXB->XB_COLUNA)))
			// Se já existe não faz nada
		Else
			RecLock("SXB",.T.)
			SXB->XB_ALIAS	:= "SC6DEC"
			SXB->XB_TIPO	:= "5"
			SXB->XB_SEQ		:= "01"
			SXB->XB_COLUNA	:= " "
			SXB->XB_DESCRI	:= ""
			SXB->XB_DESCSPA	:= ""
			SXB->XB_DESCENG	:= ""
			SXB->XB_CONTEM	:= "SC6->C6_NUM"
			SXB->XB_WCONTEM	:= ""
			MsUnlock()
		Endif

		DbSelectArea("SXB")
		DbSetOrder(1)//XB_ALIAS+XB_TIPO+XB_SEQ+XB_COLUNA
		If DbSeek(Padr("SC6DEC",Len(SXB->XB_ALIAS)) + Padr("5",Len(SXB->XB_TIPO)) + Padr("02",Len(SXB->XB_SEQ)) + Padr(" ",Len(SXB->XB_COLUNA)))
			// Se já existe não faz nada
		Else
			RecLock("SXB",.T.)
			SXB->XB_ALIAS	:= "SC6DEC"
			SXB->XB_TIPO	:= "5"
			SXB->XB_SEQ		:= "02"
			SXB->XB_COLUNA	:= " "
			SXB->XB_DESCRI	:= ""
			SXB->XB_DESCSPA	:= ""
			SXB->XB_DESCENG	:= ""
			SXB->XB_CONTEM	:= "SC6->C6_ITEM"
			SXB->XB_WCONTEM	:= ""
			MsUnlock()
		Endif


		// Só altera a opção do F3 para consulta de produto se o parâmetro estiver no Default
		If AllTrim(GetMv("DC_F3SC6")) == "SC6"
			PutMv("DC_F3SC6","SC6DEC")
		Endif
	Else
		PutMv("DC_F3SC6","SC6DEC")
	Endif
Return*/
