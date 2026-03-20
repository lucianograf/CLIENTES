#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'TOTVS.ch'

/*/{Protheus.doc} MLFATC05
(Consulta produto por codigo ou descrição, )
@type function
@author Iago Luiz Raimondi
@since 13/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MLFATC05()


Return sfTela()


/*/{Protheus.doc} sfTela
(Monta tela de pesquisa)
@type function
@author Iago Luiz Raimondi
@since 13/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTela()

	Local 	lRet := .F.
	Local	cIniSearch	:= ""
	Private oDlg,oPanelTop,oPanelAll,oPanelBot,oPesquisa,oButton,oButton2,oButton3,oButton4
	Private oBrowse
	Private aBrowse := {}
	Private cPesquisa := Space(150)


	DEFINE DIALOG oDlg TITLE "Produtos" FROM 180,180 TO 750,1200 PIXEL

	/************************************************************************************/
	/* PAINEL SUPERIOR																	*/
	/************************************************************************************/
	oPanelTop := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,30,.T.,.F.)
	oPanelTop:Align := CONTROL_ALIGN_TOP

	oPesquisa := TGet():New(003,005,{|u| If(PCount() > 0,cPesquisa := u,cPesquisa)},oPanelTop,205,010,,,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"",cPesquisa,,,,,,,"Código ou Descrição: ",1 )
	oPesquisa:bLostFocus := {|| MsgRun("Buscando produtos...","Produtos",{||sfDados(cPesquisa)})}
	oButton 	:= TButton():New(010, 212," Pesquisar ",oPanelTop,{|| MsgRun("Buscando produtos...","Produtos",{||sfDados(cPesquisa)})},037,013,,,.F.,.T.,.F.,,.F.,,,.F. )

	/************************************************************************************/
	/* PAINEL CENTRAL																	*/
	/************************************************************************************/
	oPanelAll:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,200,200,.T.,.F.)
	oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT

	oBrowse := TCBrowse():New(01,01,100,100,,{'Código','Descrição','Armazém','Estoque','Saldo'},{50,150,50,60,60},oPanelAll,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrowse:bLDblClick := {|| lRet := sfReturn(oBrowse:aArray,oBrowse:nAt), oDlg:End() }

	oPanelBot := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,20,.T.,.F.)
	oPanelBot:Align := CONTROL_ALIGN_BOTTOM

	oButton2 := TButton():New(05, 005," OK ",oPanelBot,{|| lRet := sfReturn(oBrowse:aArray,oBrowse:nAt), oDlg:End() },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton3 := TButton():New(05, 047," Cancelar "	,oPanelBot,{|| oDlg:End() },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton4 := TButton():New(05, 089," Visualizar "	,oPanelBot,{|| sfConsulta(oBrowse:aArray,oBrowse:nAt) },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )

	If ReadVar() == "M->C6_PRODUTO"
		cIniSearch	:= M->C6_PRODUTO
	ElseIf ReadVar() == "M->UB_PRODUTO"
		cIniSearch	:= M->UB_PRODUTO
	ElseIf ReadVar() == "M->D1_COD"
		cIniSearch	:= M->D1_COD
	Endif

	sfDados(cIniSearch)

	ACTIVATE DIALOG oDlg CENTERED

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

	dbSelectArea("SB1")
	dbSetOrder(1)
	If !dbSeek(xFilial("SB1")+aArray[nPosi][1])
		lRet := .F.
	EndIf

Return lRet

/*/{Protheus.doc} sfReturn
(AxVisual para produto posicionado)
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
Static Function sfConsulta(aArray,nPosi)

	dbSelectArea("SB1")
	dbSetOrder(1)
	If dbSeek(xFilial("SB1")+aArray[nPosi][1])
		AxVisual("SB1",SB1->(Recno()),2)
	EndIf

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
Static Function sfDados(cTexto)

	Local cQry
	Local aBrowse := {}


	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	cQry := "SELECT B1.B1_COD AS CODIGO,"
	cQry += "       B1.B1_DESC AS DESCRICAO,"
	cQry += "       COALESCE(B2_LOCAL,'  ') AS ARMAZEM,"
	cQry += "       COALESCE(B2_QATU,0) AS ESTOQUE,"
	cQry += "       COALESCE((B2_QATU - B2_RESERVA - B2_QEMP),0) DISPONIVEL "
	cQry += "  FROM " + RetSqlName("SB1") + " B1 " 
	cQry += "  LEFT JOIN "+ RetSqlName("SB2")  + " B2 "
	cQry += "    ON B2.D_E_L_E_T_ =' ' "
	cQry += "   AND B2.B2_COD = B1.B1_COD "
	cQry += "   AND B2.B2_FILIAL = '" + xFilial("SB2") + "'"
	cQry += " WHERE B1.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.B1_FILIAL = '" + xFilial("SB1") + "'"
	cQry += "   AND B1.B1_MSBLQL != '1'"

	If !Empty(AllTrim(cTexto))
		aArr := StrToKarr(AllTrim(Upper(NoAcento(StrTran(cTexto,"'"," "))))," ")

		cQry += "   AND ("
		cQry += "		 ("
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " B1.B1_DESC LIKE '%" + aArr[nI] + "%'"
		Next
		cQry += "			     ) OR ("
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " B1.B1_COD LIKE '%" + aArr[nI] +"%'"
		Next
		cQry += "       )"
		cQry += "      )"
	EndIf

	cQry += " ORDER BY B1.B1_DESC"

	TCQUERY cQry NEW ALIAS "QRY"

	If QRY->(EOF())
		aTmp := {}
		Aadd(aTmp,"      ")
		Aadd(aTmp,"NENHUM PRODUTO ENCONTRADO")
		Aadd(aTmp,"      ")
		Aadd(aTmp,0)
		Aadd(aTmp,0)

		Aadd(aBrowse,aTmp)
	Else
		While QRY->(!EOF())
			aTmp := {}
			Aadd(aTmp,QRY->CODIGO)
			Aadd(aTmp,QRY->DESCRICAO)
			Aadd(aTmp,QRY->ARMAZEM)
			Aadd(aTmp,QRY->ESTOQUE)
			Aadd(aTmp,QRY->DISPONIVEL)	
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
	oBrowse:bLine := {|| {aBrowse[oBrowse:nAt,01],;
	aBrowse[oBrowse:nAt,02],;
	aBrowse[oBrowse:nAt,03],;
	Transform(aBrowse[oBrowse:nAt,04],"@E 999,999,999.99"),;
	Transform(aBrowse[oBrowse:nAt,05],"@E 999,999,999.99")}}
	oBrowse:Refresh()

	If !Empty(cTexto)
		oBrowse:SetFocus()
	Endif

Return