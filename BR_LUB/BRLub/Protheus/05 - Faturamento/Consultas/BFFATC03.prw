#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'TOTVS.ch'

/*/{Protheus.doc} BFFATC03
(Consulta cliente por codigo loja ou cnpj ou nome e cidade)
@type function
@author Iago Luiz Raimondi
@since 12/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATC03()
	
	Local	lFilBroker		:= IsInCallStack("U_BFFATA61") 

Return sfTela(lFilBroker)


/*/{Protheus.doc} sfTela
(Monta tela de pesquisa)
@type function
@author Iago Luiz Raimondi
@since 12/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTela(lFilBroker)

	Local 	lRet := .F.
	Local	cIniSearch	:= ""
	Private oDlg,oPanelTop,oPanelAll,oPanelBot,oPesquisa,oButton,oButton2,oButton3,oButton4
	Private oBrowse
	Private aBrowse 	:= {}
	Private cPesquisa 	:= Space(120)
	Private cCidade 	:= Space(50)
	Private cCadastro	:= "Cadastro de Clientes"
	
	
	DEFINE DIALOG oDlg TITLE "Clientes" FROM 180,180 TO 550,1000 PIXEL
	
	/************************************************************************************/
	/* PAINEL SUPERIOR																	*/
	/************************************************************************************/
	oPanelTop := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,30,.T.,.F.)
	oPanelTop:Align := CONTROL_ALIGN_TOP
		
	oPesquisa := TGet():New(003,005,{|u| If(PCount() > 0,cPesquisa := u,cPesquisa)},oPanelTop,265,010,,,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"",cPesquisa,,,,,,,"Código/CNPJ/Nome: ",1 )
	oPesquisa := TGet():New(003,275,{|u| If(PCount() > 0,cCidade := u,cCidade)},oPanelTop,90,010,,,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"",cCidade,,,,,,,"Cidade: ",1 )
	oPesquisa:bLostFocus := {|| MsgRun("Buscando clientes...","Clientes",{||sfDados(cPesquisa,cCidade,lFilBroker)})}
	oButton 	:= TButton():New(010, 368," Pesquisar ",oPanelTop,{|| MsgRun("Buscando clientes...","Clientes",{||sfDados(cPesquisa,cCidade,lFilBroker)})},037,013,,,.F.,.T.,.F.,,.F.,,,.F. )
		
	/************************************************************************************/
	/* PAINEL CENTRAL																	*/
	/************************************************************************************/
	oPanelAll:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,200,200,.T.,.F.)
	oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT
		
	oBrowse := TCBrowse():New(01,01,100,100,,{'Código','Loja','Nome','CNPJ','Telefone','UF/Cidade'},{30,20,120,70,50,60},oPanelAll,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrowse:bLDblClick := {|| lRet := sfReturn(oBrowse:aArray,oBrowse:nAt), oDlg:End() }
        
	oPanelBot := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,20,.T.,.F.)
	oPanelBot:Align := CONTROL_ALIGN_BOTTOM
		
	oButton2 := TButton():New(05, 005," OK ",oPanelBot,{|| lRet := sfReturn(oBrowse:aArray,oBrowse:nAt), oDlg:End() },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton3 := TButton():New(05, 047," Cancelar "	,oPanelBot,{|| oDlg:End() },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton4 := TButton():New(05, 089," Visualizar "	,oPanelBot,{|| sfConsulta(oBrowse:aArray,oBrowse:nAt) },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
    
    
    If ReadVar() == "M->UA_CLIENTE"
    	cIniSearch	:= M->UA_CLIENTE
    ElseIf ReadVar() == "M->C5_CLIENTE"
		cIniSearch	:= M->C5_CLIENTE
	Endif
	      
	sfDados(cIniSearch,"",lFilBroker)
 	
	ACTIVATE DIALOG oDlg CENTERED

Return lRet


/*/{Protheus.doc} sfReturn
(Posiciona na SA1 do cliente, pois consulta pega SA1->A1_COD+SA1->A1_LOJA como retorno)
@type function
@author Iago Luiz Raimondi
@since 12/12/2016
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

	dbSelectArea("SA1")
	dbSetOrder(1)
	If !dbSeek(xFilial("SA1")+aArray[nPosi][1]+aArray[nPosi][2])
		lRet := .F.
	EndIf

Return lRet

/*/{Protheus.doc} sfReturn
(AxVisual para cliente posicionado)
@type function
@author Iago Luiz Raimondi
@since 12/12/2016
@version 1.0
@param aArray, array, (Descrição do parâmetro)
@param nPosi, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfConsulta(aArray,nPosi)

	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+aArray[nPosi][1]+aArray[nPosi][2])
		AxVisual("SA1",SA1->(Recno()),2)
	EndIf

Return


/*/{Protheus.doc} sfDados
(Busca dados e monta array)
@type function
@author Iago Luiz Raimondi
@since 12/12/2016
@version 1.0
@param cTexto, character, (String para filtrar)
@param cTexto2, character, (String para filtrar)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfDados(cTexto,cTexto2,lFilBroker)

	Local cQry
	Local aBrowse := {}
	Local nI


	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	cQry := "SELECT A1.A1_COD AS CODIGO, A1.A1_LOJA AS LOJA, A1.A1_NOME AS NOME, A1.A1_CGC AS CGC, A1.A1_TEL AS TEL,A1.A1_MUN CIDADE,A1.A1_EST UF"
	cQry += " FROM " + RetSqlName("SA1") + " A1"
	cQry += " WHERE A1.D_E_L_E_T_ = ' '"
	cQry += "   AND A1.A1_FILIAL = '" + xFilial("SA1") + "'"
	cQry += "   AND A1.A1_MSBLQL != '1'"
	
	// 05/03/2020 - Melhoria para filtrar clientes 
	If lFilBroker
		cQry += "  AND A1_XBROKER = 'U'" // Somente cliente como Broker ativado 
	Endif
	// Efetua ajuste do Texto antes de fazer a conversão StrTokArr
	cTexto	:= AllTrim(Upper(NoAcento(StrTran(cTexto,"'"," "))))
	
	If !Empty(AllTrim(cTexto))
		aArr := StrToKarr(cTexto," ")
	
		cQry += "   AND ("
		cQry += "		 ("
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " A1.A1_COD + A1.A1_LOJA LIKE '%" + aArr[nI] + "%'"
		Next
		cQry += "			     ) OR ("
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " A1.A1_CGC LIKE '%" + aArr[nI] +"%'"
		Next
		cQry += "			     ) OR ("
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " A1.A1_NREDUZ LIKE '%" + aArr[nI] +"%'"
		Next
		cQry += "			     ) OR ("
		// IAGO 13/12/2016 Chamado(16643)
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " A1.A1_TEL LIKE '%" + aArr[nI] +"%'"
		Next
		cQry += "			     ) OR ("
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " A1.A1_NOME LIKE '%" + aArr[nI] +"%'"
		Next
		cQry += "       )"
		cQry += "      )"
	EndIf
	
	cTexto2	:= AllTrim(Upper(NoAcento(StrTran(cTexto2,"'"," "))))
			   
	If !Empty(AllTrim(cTexto2))
		aArr := StrToKarr(cTexto2," ")
	
		cQry += "   AND ("
		cQry += "		 ("
		For nI := 1 To Len(aArr)
			If nI > 1
				cQry += " AND "
			EndIf
			cQry += " A1.A1_MUN LIKE '%" + aArr[nI] + "%'"
		Next
		cQry += "			)" 
		cQry += "      )"
	EndIf

	cQry += " ORDER BY A1.A1_NOME"

	//Quando for primeira pesquisa, não carrega dados
	If Empty(AllTrim(cTexto)) .AND. Empty(AllTrim(cTexto2))
		aTmp := {}
		Aadd(aTmp,"      ")
		Aadd(aTmp,"  ")
		Aadd(aTmp,"NENHUM CLIENTE ENCONTRADO")
		Aadd(aTmp,"              ")
		Aadd(aTmp,"      ")
		Aadd(aTmp,"      ")
	
		Aadd(aBrowse,aTmp)
	Else
		TCQUERY cQry NEW ALIAS "QRY"

		If QRY->(EOF())
			aTmp := {}
			Aadd(aTmp,"      ")
			Aadd(aTmp,"  ")
			Aadd(aTmp,"NENHUM CLIENTE ENCONTRADO")
			Aadd(aTmp,"              ")
			Aadd(aTmp,"      ")
			Aadd(aTmp,"      ")
	
			Aadd(aBrowse,aTmp)
		Else
			While QRY->(!EOF())
				aTmp := {}
				Aadd(aTmp,QRY->CODIGO)
				Aadd(aTmp,QRY->LOJA)
				Aadd(aTmp,QRY->NOME)
				Aadd(aTmp,QRY->CGC)
				Aadd(aTmp,QRY->TEL)
				Aadd(aTmp,QRY->UF + "-"+ Alltrim(QRY->CIDADE))	
				Aadd(aBrowse,aTmp)
			
				QRY->(dbSkip())
			End
		EndIf
	EndIf
	

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	oBrowse:SetArray(aBrowse)
	// Corrige falha quando o número de registros da nova pesquisa for menos que a posição anterior do Browser
	If oBrowse:nAt > Len(aBrowse)
		oBrowse:nAt	:= Len(aBrowse)
	Endif
	oBrowse:bLine := {||{aBrowse[oBrowse:nAt,01],;
		aBrowse[oBrowse:nAt,02],;
		aBrowse[oBrowse:nAt,03],;
		aBrowse[oBrowse:nAt,04],;
		aBrowse[oBrowse:nAt,05],;
		aBrowse[oBrowse:nAt,06]}}
	oBrowse:Refresh()
	
	If !Empty(cTexto)
		oBrowse:SetFocus()
	Endif
	
Return
