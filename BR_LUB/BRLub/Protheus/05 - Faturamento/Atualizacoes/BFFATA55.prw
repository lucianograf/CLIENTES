#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'FileIO.ch'

/*/{Protheus.doc} BFFATA55
(Rotina de analise desempenho transportadora. Inclui data de entrega e sabera se atendeu o prazo da rota)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA55()

	Private cCadastro := "Performance Transportadora"

	Private aRotina := {{"Pesquisar","AxPesqui",0,1},;
		{"Visualizar","AxVisual",0,2},;
		{"Incluir","U_FATA55I",0,3},;
		{"Alterar","AxAltera",0,4},;
		{"Excluir","AxDeleta",0,5},;
		{"Relatório","U_FATA55R",0,3},;
		{"Importa EDI","U_FATA55E",0,3}}

	If !cEmpAnt $ "02#11"
		MsgAlert("Rotina só liberada para ser executada na empresa 02-Atrialub",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	Endif

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	dbSelectArea("SZU")
	dbSetOrder(1)

	mBrowse( 6,1,22,75,"SZU")

Return


/*/{Protheus.doc} FATA55I
(Tela de inclusão)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FATA55I()

	Private oDlg
	Private oMulti
	Private oPanelTop,oPanelAll
	Private aCols 	:= {}
	Private aHeader := {}
	Private aPergs 	:= {}
	Private aRet	:= {}
	// 1 - MsGet
	//[2] : Descrição
	//[3] : String contendo o inicializador do campo
	//[4] : String contendo a Picture do campo
	//[5] : String contendo a validação
	//[6] : Consulta F3
	//[7] : String contendo a validação When
	//[8] : Tamanho do MsGet
	//[9] : Flag .T./.F. Parâmetro Obrigatório ?

	Aadd(aPergs,{1,"Emissão de"		,CToD(Space(8))	,""		,"","",".T.",50,.T.})
	Aadd(aPergs,{1,"Emissão até"	,dDataBase		,""		,"","",".T.",50,.T.})
	Aadd(aPergs,{1,"Transportadora"	,Space(6)		,"@!"	,"Vazio() .Or. ExistCpo('SA4')","SA4",".T.",6,.F.})
	Aadd(aPergs,{1,"Número Nota"	,Space(9)		,"@!"	,"","",".T.",50,.F.})

	If ParamBox(@aPergs,"Parametros",aRet)

		DEFINE DIALOG oDlg TITLE "Inclusão Performance Transportadora" FROM 000,000 TO 400,700 PIXEL

		Private cCodTr	:= MV_PAR03

		sfCarrega(@aCols,@aHeader,.T.)

		Private cNomTr	:= Posicione("SA4",1,xFilial("SA4")+cCodTr,"A4_NOME")

		oDlg:lMaximized := .T.

		/************************************************************************************/
		/* PAINEL SUPERIOR																	*/
		/************************************************************************************/
		oPanelTop := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,40,.T.,.F.)
		oPanelTop:Align := CONTROL_ALIGN_TOP

		oTGet1 		:= TGet():New(12,05,{||cCodTr},oPanelTop,030,09,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,cCodTr,,,,,,,"Código: ",2)
		oTGet2 		:= TGet():New(12,70,{||cNomTr},oPanelTop,150,09,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cNomTr,,,,,,,"Nome: ",2)

		/************************************************************************************/
		/* PAINEL CENTRAL																	*/
		/************************************************************************************/
		oPanelAll:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,200,200,.T.,.F.)
		oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT


		oMulti := MsNewGetDados():New(034,005,226,415,GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
			"AllwaysTrue()"/*cTudoOk*/,"",,0/*nFreeze*/,10000/*nMax*/,;
			"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,/*cApagaOk*/,;
			oPanelAll,@aHeader,@aCols,{||})
		oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
		oMulti:oBrowse:Refresh()


		ACTIVATE DIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg,{||sfInclui(@oMulti:aHeader,@oMulti:aCols),oDlg:End()},{||oDlg:End()}) , oMulti:oBrowse:SetFocus())

	EndIf

Return


/*/{Protheus.doc} sfCarrega
(Carrega dados)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@param lInclui, ${param_type}, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCarrega(aCols,aHeader,lConsulta)
	Local	iX,nI
	Private aCampos := {"F2_DOC","F2_SERIE","F2_CLIENTE","F2_LOJA","A1_NOME","A1_MUN","F2_EMISSAO"}
	Private cQry	:= ""

	// Monta aHeader se não existir
	If Len(aHeader) == 0

		// Únicas colunas editaveis
		Aadd(aHeader,{"DT Ocorren","ZU_DATAENT","",TamSX3("ZU_DATAENT")[1],0,"",,"D","","R","",""})
		Aadd(aHeader,{"HR Ocorren","ZU_HORAENT","@E 99:99",TamSX3("ZU_HORAENT")[1],0,"",,"C","","R","",""})
		Aadd(aHeader,{"Ocorrencia","ZU_OCORREN","",TamSX3("ZU_OCORREN")[1],0,"!Vazio() .AND. ExistCpo('SX5','ZA'+M->ZU_OCORREN)",,"C","SX5ZA","R","",""})
		Aadd(aHeader,{"Observação","ZU_OBS","@!",100,0,"",,"C","","R","",""})


		DbSelectArea("SX3")
		DbSetOrder(2)
		For iX := 1 To Len(aCampos)
			If DbSeek(aCampos[iX])
				Aadd(aHeader,{ AllTrim(X3Titulo()),;
					GetSx3Cache(aCampos[iX],"X3_CAMPO")	,;
					GetSx3Cache(aCampos[iX],"X3_PICTURE"),;
					GetSx3Cache(aCampos[iX],"X3_TAMANHO"),;
					GetSx3Cache(aCampos[iX],"X3_DECIMAL"),;
					"",;//SX3->X3_VALID
					GetSx3Cache(aCampos[iX],"X3_USADO")	,;
					GetSx3Cache(aCampos[iX],"X3_TIPO")	,;
					GetSx3Cache(aCampos[iX],"X3_F3") 		,;
					GetSx3Cache(aCampos[iX],"X3_CONTEXT"),;
					GetSx3Cache(aCampos[iX],"X3_CBOX")	,;
					"",; //SX3->X3_RELACAO
					"",; //SX3->X3_WHEN
					"V"})
			EndIf
		Next

	EndIf

	If lConsulta
		cQry += "SELECT DISTINCT F2.F2_DOC AS NOTA,"
		cQry += "       F2.F2_SERIE AS SERIE,"
		cQry += "       F2.F2_CLIENTE AS CODCLI,"
		cQry += "       F2.F2_LOJA AS LOJCLI,"
		cQry += "       A1.A1_NOME AS NOMCLI,"
		cQry += "       A1.A1_MUN AS CIDADE,"
		cQry += "       F2_TRANSP AS TRANSP,"
		cQry += "       F2.F2_EMISSAO AS EMISSAO,"
		cQry += "       ' ' AS ENTREGA,"
		cQry += "       ' ' AS HORA,"
		cQry += "       ' ' AS OCORREN,"
		cQry += "       ' ' AS OBS"
		cQry += "  FROM " + RetSqlName("SF2") + " F2"
		cQry += " INNER JOIN " + RetSqlName("SA1") + " A1"
		cQry += "    ON A1.D_E_L_E_T_ = ' '"
		cQry += "   AND A1.A1_FILIAL = '"+ xFilial("SA1") +"'"
		cQry += "   AND A1.A1_COD = F2.F2_CLIENTE"
		cQry += "   AND A1.A1_LOJA = F2.F2_LOJA"
		cQry += " INNER JOIN " + RetSqlName("SD2") + " D2"
		cQry += "    ON D2.D_E_L_E_T_ = ' '"
		cQry += "   AND D2.D2_FILIAL = F2.F2_FILIAL"
		cQry += "   AND D2.D2_DOC = F2.F2_DOC"
		cQry += "   AND D2.D2_SERIE = F2.F2_SERIE"
		cQry += " INNER JOIN " + RetSqlName("SF4") + " F4"
		cQry += "    ON F4.D_E_L_E_T_ = ' '"
		cQry += "   AND F4.F4_FILIAL = D2.D2_FILIAL"
		cQry += "   AND F4.F4_CODIGO = D2.D2_TES"
		cQry += "   AND F4.F4_XTPMOV NOT IN('BA','VS','TF','RT','TA','RC','RA','SP','TE')"
		cQry += " WHERE F2.D_E_L_E_T_ = ' '"
		cQry += "   AND F2.F2_FILIAL = '"+ xFilial("SF2") +"'"
		cQry += "   AND F2.F2_EMISSAO BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"'"
		If !Empty(MV_PAR04)
			cQry += "   AND F2_DOC = '" + MV_PAR04+ "'"
		Else
			If !Empty(MV_PAR03)
				cQry += "   AND F2.F2_TRANSP = '"+ MV_PAR03 +"'"
			Endif
		Endif
		cQry += "   AND F2.F2_TIPO = 'N'"
		cQry += "   AND (F2.F2_FILIAL,F2.F2_DOC,F2.F2_SERIE) NOT IN (SELECT ZU.ZU_FILIAL,ZU.ZU_NOTA,ZU.ZU_SERIE FROM "+ RetSqlName("SZU") +" ZU WHERE ZU.D_E_L_E_T_ = ' ')"
		cQry += " ORDER BY F2.F2_DOC"

		If Select("QRY") <> 0
			QRY->(DbCloseArea())
		EndIf

		TCQUERY cQry NEW ALIAS "QRY"

		While QRY->(!EOF())

			Aadd(aCols,Array(Len(aHeader)+1))
			aCols[Len(aCols),Len(aHeader)+1]	:= .F.
			If !Empty(MV_PAR04)
				MV_PAR03	:= QRY->TRANSP
				cCodTr		:= QRY->TRANSP
			Endif
			For nI := 1 To Len(aHeader)
				If Alltrim(aHeader[nI][2]) == "F2_DOC"
					aCols[Len(aCols)][nI]	:= QRY->NOTA
				ElseIf Alltrim(aHeader[nI][2]) == "F2_SERIE"
					aCols[Len(aCols)][nI]	:= QRY->SERIE
				ElseIf Alltrim(aHeader[nI][2]) == "F2_CLIENTE"
					aCols[Len(aCols)][nI]	:= QRY->CODCLI
				ElseIf Alltrim(aHeader[nI][2]) == "F2_LOJA"
					aCols[Len(aCols)][nI]	:= QRY->LOJCLI
				ElseIf Alltrim(aHeader[nI][2]) == "A1_NOME"
					aCols[Len(aCols)][nI]	:= QRY->NOMCLI
				ElseIf Alltrim(aHeader[nI][2]) == "A1_MUN"
					aCols[Len(aCols)][nI]	:= QRY->CIDADE
				ElseIf Alltrim(aHeader[nI][2]) == "F2_EMISSAO"
					aCols[Len(aCols)][nI]	:= SToD(QRY->EMISSAO)
				ElseIf Alltrim(aHeader[nI][2]) == "ZU_DATAENT"
					aCols[Len(aCols)][nI]	:= CToD("  /  /  ")
				ElseIf Alltrim(aHeader[nI][2]) == "ZU_HORAENT"
					aCols[Len(aCols)][nI]	:= "00:00"
				ElseIf Alltrim(aHeader[nI][2]) == "ZU_OCORREN"
					aCols[Len(aCols)][nI]	:= Space(2)
				ElseIf Alltrim(aHeader[nI][2]) == "ZU_OBS"
					aCols[Len(aCols)][nI]	:= Space(200)
				EndIf
			Next

			QRY->(dbSkip())
		End

		If Select("QRY") <> 0
			QRY->(DbCloseArea())
		EndIf

	EndIf

Return


/*/{Protheus.doc} sfInclui
(Loop para inclusão)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@param aHeader, array, (Descrição do parâmetro)
@param aCols, array, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfInclui(aHeader,aCols)

	Local nCount := 0
	Local nI

	If !MsgYesNo("Deseja realmente incluir os registros?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf
	Private aLog	:= {}
	Private nPosDoc := aScan(aHeader,{|x| AllTrim(x[2]) == "F2_DOC"})
	Private nPosSer := aScan(aHeader,{|x| AllTrim(x[2]) == "F2_SERIE"})
	Private nPosEnt := aScan(aHeader,{|x| AllTrim(x[2]) == "ZU_DATAENT"})
	Private nPosHra := aScan(aHeader,{|x| AllTrim(x[2]) == "ZU_HORAENT"})
	Private nPosOco := aScan(aHeader,{|x| AllTrim(x[2]) == "ZU_OCORREN"})
	Private nPosObs := aScan(aHeader,{|x| AllTrim(x[2]) == "ZU_OBS"})

	For nI := 1 To Len(aCols)
		// Verifica se preencheu data ocorrencia,hora ocorrencia e ocorrencia
		If !Empty(DToS(aCols[nI][nPosEnt])) .And. Len(aCols[nI][nPosHra]) == 5 .And. !Empty(aCols[nI][nPosOco])
			// Verifica se a linha não foi deletada
			If !aCols[Len(aCols),Len(aHeader)+1]
				If sfGravaSZU(" ",aCols[nI][nPosDoc],aCols[nI][nPosSer],DToS(aCols[nI][nPosEnt]),aCols[nI][nPosHra],aCols[nI][nPosOco],aCols[nI][nPosObs])
					++nCount
				EndIf
			EndIf
		Else
			Aadd(aLog,{"A NF [ "+ aCols[nI][nPosDoc] +"/"+ aCols[nI][nPosSer] +" ] não foi gravada por que não foi informado data de entrega!"})
		EndIf
	Next
	If Len(aLog) > 0
		sfMsgInfo()
	Endif
	If nCount > 0
		MsgAlert(cValToChar(nCount)+" registro(s) incluído(s) com sucesso.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	Else
		MsgAlert("Nenhum registro foi incluso.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf

Return


/*/{Protheus.doc} sfGravaSZU
(Grava SZU)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@param cNota, character, (Descrição do parâmetro)
@param cSerie, character, (Descrição do parâmetro)
@param cDataEnt, character, (Descrição do parâmetro)
@param cObs, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGravaSZU(cArq,cNota,cSerie,cDataEnt,cHoraEnt,cOcorr,cObs)

	dbSelectArea("SF2")
	dbSetOrder(1)
	If dbSeek(xFilial("SF2")+cNota+cSerie)
		If SF2->F2_EMISSAO > SToD(cDataEnt)
			//MsgAlert("A NF [ "+ cNota +"/"+ cSerie +" ] está com data de emissão maior do que a entrega. Favor ajustar manualmente.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Aadd(aLog,{"A NF [ "+ cNota +"/"+ cSerie +" ] está com data de emissão maior do que a entrega. Favor ajustar manualmente."})
			Return .F.
		Else
			dbSelectArea("SZU")
			dbSetOrder(1)
			If dbSeek(xFilial("SZU")+cNota+cSerie)
				//MsgAlert("Já existe registro com esse número [ "+ cNota +"/"+ cSerie +" ] no sistema.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				Aadd(aLog,{"Já existe registro com esse número [ "+ cNota +"/"+ cSerie +" ] no sistema."})
				Return .F.
			Else
				RecLock("SZU",.T.)
				SZU->ZU_FILIAL 	:= xFilial("SZU")
				SZU->ZU_ARQUIVO	:= cArq
				SZU->ZU_NOTA	:= cNota
				SZU->ZU_SERIE	:= cSerie
				SZU->ZU_DATAENT	:= SToD(cDataEnt)
				SZU->ZU_HORAENT	:= cHoraEnt
				SZU->ZU_OCORREN	:= cOcorr
				SZU->ZU_OBS		:= cObs
				MsUnLock()
			EndIf
		EndIf
	Else
		Aadd(aLog,{"Não foi encontrado nenhuma NFe emitida com esse número ["+ cNota +"/"+ cSerie +"]."})
		//MsgAlert("Não foi encontrado nenhuma NFe emitida com esse número ["+ cNota +"/"+ cSerie +"].",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return .F.
	EndIf

Return .T.

/*/{Protheus.doc} FATA55R
(Relatório para desempenho das transportadoras)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FATA55R()

	Local oReport
	Local cPerg	:= "BFFATA55"

	//sfCriaSx1(cPerg)

	Pergunte(cPerg,.F.)

	oReport := RptDef(cPerg)
	oReport:PrintDialog()

Return

/*/{Protheus.doc} RptDef
(Monta colunas)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@param cNome, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RptDef(cNome)

	Local oReport 	:= Nil
	Local oSection1	:= Nil
	Local oSection2	:= Nil
	Local oBreak
	Local oFunction

	oReport := TReport():New(cNome,"Desempenho Transportadoras",cNome,{|oReport| ReportPrint(oReport)},"Relatório de desempenho de transportadora.")
	oReport:SetLandScape()
	oReport:SetTotalInLine(.F.)

	oSection1 := TRSection():New(oReport, "Analitico", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"NOTA" 		,"QRY"	,"Nota Fiscal" 	  	,"@!",30)
	TRCell():New(oSection1,"SERIE" 		,"QRY"	,"Serie"      		,"@!",12)
	TRCell():New(oSection1,"CODCLI" 	,"QRY"	,"Cliente" 			,"@!",20)
	TRCell():New(oSection1,"LOJCLI" 	,"QRY"	,"Loja"				,"@!",10)
	TRCell():New(oSection1,"NOMCLI"		,"QRY"	,"Nome" 			,"@!",80)
	TRCell():New(oSection1,"CIDADE"	 	,"QRY"	,"Cidade" 			,"@!",50)
	TRCell():New(oSection1,"CODTRAN" 	,"QRY"	,"Tranp" 			,"@!",20)
	TRCell():New(oSection1,"NOMTRAN" 	,"QRY"	,"Nome" 			,"@!",50)
	TRCell():New(oSection1,"VALOR" 		,"QRY"	,"Valor" 			,"@E 999,999,999.99",50)
	TRCell():New(oSection1,"PESOBRU" 	,"QRY"	,"Peso Bru." 		,"@E 999,999,999.99",30)
	TRCell():New(oSection1,"VOLUME" 	,"QRY"	,"Volume" 			,"@!",30)
	TRCell():New(oSection1,"FRETE" 		,"QRY"	,"Vlr.Frete" 		,"@E 999,999,999.99",50)
	TRCell():New(oSection1,"ROTA"	 	,"QRY"	,"Rota" 			,"@!",50)
	TRCell():New(oSection1,"EMISSAO" 	,"QRY"	,"Emissão" 			,"@D",50)
	TRCell():New(oSection1,"EXPEDIC" 	,"QRY"	,"Dt.Exped" 		,"@D",50)
	TRCell():New(oSection1,"PRAZO" 		,"QRY"	,"Prazo" 			,"@!",20)
	TRCell():New(oSection1,"PREVENT" 	,"QRY"	,"Previsão" 		,"@D",50)
	TRCell():New(oSection1,"ENTREGA" 	,"QRY"	,"Entrega" 			,"@D",50)
	TRCell():New(oSection1,"HORA" 		,"QRY"	,"Horario" 			,"@!",10)
	TRCell():New(oSection1,"OCORREN" 	,"QRY"	,"Ocorrência"		,"@!",100)
	TRCell():New(oSection1,"ATRASO"		,"QRY"	,"Atraso" 			,"@E 99999",10)
	TRCell():New(oSection1,"OBS" 		,"QRY"	,"Obs" 				,"@!",200)

	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)

	oSection2 := TRSection():New(oReport, "Entregas Com Atraso - Análise", {},, .F., .T.)
	TRCell():New(oSection2,"CIDADE" 		,	,"Cidade" 	  		,"@!"				,30	)
	TRCell():New(oSection2,"QTENFS" 		,	,"Quant.Notas" 		,"@E 999,999"		,9	)
	TRCell():New(oSection2,"QTEPRZ" 		,	,"N.Ent.Prazo"		,"@E 999,999"		,9  )
	TRCell():New(oSection2,"PNFPRZ" 		,	,"% Ent.Prazo" 	  	,"@E 999.99%"		,9	)
	TRCell():New(oSection2,"QTEATR1" 		,	,"N.Atraso 1 Dia" 	,"@E 999,999"		,9	)
	TRCell():New(oSection2,"PNFATR1" 		,	,"% "  				,"@E 999.99%"		,9	)
	TRCell():New(oSection2,"QTEATRZ" 		,	,"N Atr > 1 Dia"	,"@E 999,999"		,9	)
	TRCell():New(oSection2,"PNFATRZ" 		,	,"% "  				,"@E 999.99%"		,9	)
	TRCell():New(oSection2,"QTEPEN" 		,	,"N.Sem Entrega" 	,"@E 999,999"		,9	)
	TRCell():New(oSection2,"PNFPEN" 		,	,"% Sem Entrega"  	,"@E 999.99%"		,9	)
	TRCell():New(oSection2,"VLRFAT" 		,	,"R$ Faturado" 		,"@E 99,999,999.99"	,14	)
	TRCell():New(oSection2,"VLRFRE" 		,	,"R$ Frete"		  	,"@E 999,999.99"	,11	)
	TRCell():New(oSection2,"PVLFRE" 		,	,"% Frete" 		 	,"@E 999.99%"		,9	)
	TRCell():New(oSection2,"QTVOLU" 		,	,"Qtd Volume"	 	,"@E 999,999"		,9	)
	TRCell():New(oSection2,"qTPESO" 		,	,"Kg Peso B"	 	,"@E 999,999.99"	,11	)

Return oReport

/*/{Protheus.doc} ReportPrint
(Preenche valores)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@param cNome, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport)

	Local 	oSection1 	:= oReport:Section(1)
	Local   oSection2	:= oReport:Section(2)
	Local 	cQry		:= ""
	Local 	aSection2	:= {}
	Local	nI
	Local	dDtExped	:= Nil
	Local	nQtdDFind	:= 0
	Local	dAtraso		:= Nil
	Local 	nAtraso
	Local	nDias
	Local	nVlrFrete	:= 0
	Local	nPosEnt		:= 0
	Local	aEntAtr		:= {}
	Local	nPxCidade	:= 1
	Local	nPxQtdNf	:= 2
	Local	nPxEntPrz	:= 3
	Local	nPxAtrz1	:= 4
	Local	nPxAtrzN	:= 5
	Local	nPxPend		:= 6
	Local	nPxVlrFat	:= 7
	Local	nPxVlFret	:= 8
	Local	nPxVolum	:= 9
	Local	nPxPeso		:= 10
	Local	aEntTot		:= {"Total Geral Análise de Entregas",0,0,0,0,0,0,0,0,0}

	cQry += "SELECT *"
	cQry += "  FROM ("
	If MV_PAR05 == 1 .OR. MV_PAR05 == 3
		cQry += "		 SELECT DISTINCT F2.F2_DOC AS NOTA,"
		cQry += "               F2.F2_SERIE AS SERIE,"
		cQry += "               F2.F2_CLIENTE AS CODCLI,"
		cQry += "               F2.F2_LOJA AS LOJCLI,"
		cQry += "               A1.A1_NOME AS NOMCLI,"
		cQry += "               A1.A1_MUN AS CIDADE,"
		cQry += "               F2.F2_TRANSP AS CODTRAN,"
		cQry += "               A4.A4_NOME AS NOMTRAN,"
		cQry += "               F2.F2_EMISSAO AS EMISSAO,"
		cQry += "               F2.F2_VALBRUT AS VALOR,"
		cQry += "       		F2.F2_PBRUTO  AS PESOBRU,"
		cQry += "        		F2.F2_VOLUME1 AS VOLUME,"
		cQry += "               PAB.PAB_PRAZO AS PRAZO,"
		cQry += "               PAB.PAB_ROTA AS ROTA,"
		cQry += "               ' ' AS ENTREGA,"
		cQry += "               ' ' AS HORA,"
		cQry += "               ' ' AS OCORREN,"
		cQry += "               ' ' AS OBS,"
		cQry += "               F2.F2_FRETE AS FRETE"
		cQry += "          FROM "+ RetSqlName("SF2") +" F2"
		cQry += "         INNER JOIN "+ RetSqlName("SA1") +" A1"
		cQry += "            ON A1.D_E_L_E_T_ = ' '"
		cQry += "           AND A1.A1_FILIAL = '"+ xFilial("SA1") +"'"
		cQry += "           AND A1.A1_COD = F2.F2_CLIENTE"
		cQry += "           AND A1.A1_LOJA = F2.F2_LOJA"
		cQry += "         INNER JOIN "+ RetSqlName("SA4") +" A4"
		cQry += "            ON A4.D_E_L_E_T_ = ' '"
		cQry += "           AND A4.A4_FILIAL = '"+ xFilial("SA4") +"'"
		cQry += "           AND A4.A4_COD = F2.F2_TRANSP"
		cQry += " 		  INNER JOIN " + RetSqlName("SD2") + " D2"
		cQry += "    		 ON D2.D_E_L_E_T_ = ' '"
		cQry += "   	    AND D2.D2_FILIAL = F2.F2_FILIAL"
		cQry += "   		AND D2.D2_DOC = F2.F2_DOC"
		cQry += "   		AND D2.D2_SERIE = F2.F2_SERIE"
		cQry += " 		  INNER JOIN " + RetSqlName("SF4") + " F4"
		cQry += "    		 ON F4.D_E_L_E_T_ = ' '"
		cQry += "   		AND F4.F4_FILIAL = D2.D2_FILIAL"
		cQry += "   		AND F4.F4_CODIGO = D2.D2_TES"
		cQry += "   		AND F4.F4_XTPMOV NOT IN('BA','VS','TF','RT','TA','RC','RA','SP','TE')"
		cQry += "          LEFT JOIN "+ RetSqlName("PAB") +" PAB"
		cQry += "            ON PAB.D_E_L_E_T_ = ' '"
		cQry += "           AND PAB.PAB_FILIAL = '"+ xFilial("PAB") +"'"
		cQry += "           AND PAB.PAB_CEP = A1.A1_CEP"
		cQry += "           AND PAB.PAB_TRANSP = F2.F2_TRANSP"
		cQry += "         WHERE F2.D_E_L_E_T_ = ' '"
		cQry += "           AND F2.F2_FILIAL = '"+ xFilial("SF2") +"'"
		cQry += "           AND F2.F2_EMISSAO BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"'"
		cQry += "           AND F2.F2_TRANSP BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
		cQry += "           AND F2.F2_TIPO = 'N'"
		cQry += "           AND (F2.F2_FILIAL, F2.F2_DOC, F2.F2_SERIE) NOT IN"
		cQry += "               (SELECT ZU.ZU_FILIAL, ZU.ZU_NOTA, ZU.ZU_SERIE"
		cQry += "                  FROM "+ RetSqlName("SZU") +" ZU"
		cQry += "                 WHERE ZU.D_E_L_E_T_ = ' ')"
	EndIf

	If MV_PAR05 == 3
		cQry += "        UNION ALL"
	EndIf

	If MV_PAR05 == 2 .OR. MV_PAR05 == 3
		cQry += "        SELECT F2.F2_DOC     AS NOTA,"
		cQry += "               F2.F2_SERIE   AS SERIE,"
		cQry += "               F2.F2_CLIENTE AS CODCLI,"
		cQry += "               F2.F2_LOJA    AS LOJCLI,"
		cQry += "               A1.A1_NOME    AS NOMCLI,"
		cQry += "               A1.A1_MUN     AS CIDADE,"
		cQry += "               F2.F2_TRANSP  AS CODTRAN,"
		cQry += "               A4.A4_NOME    AS NOMTRAN,"
		cQry += "               F2.F2_EMISSAO AS EMISSAO,"
		cQry += "               F2.F2_VALBRUT AS VALOR,"
		cQry += "       		F2.F2_PBRUTO  AS PESOBRU,"
		cQry += "        		F2.F2_VOLUME1 AS VOLUME,"
		cQry += "               PAB.PAB_PRAZO AS PRAZO,"
		cQry += "               PAB.PAB_ROTA AS ROTA,"
		cQry += "               ZU.ZU_DATAENT AS ENTREGA,"
		cQry += "               ZU.ZU_HORAENT AS HORA,"
		cQry += "               ZU.ZU_OCORREN||'-'||X5.X5_DESCRI AS OCORREN,"
		cQry += "               ZU.ZU_OBS     AS OBS,"
		cQry += "               F2.F2_FRETE AS FRETE"
		cQry += "          FROM "+ RetSqlName("SF2") +" F2"
		cQry += "         INNER JOIN "+ RetSqlName("SA1") +" A1"
		cQry += "            ON A1.D_E_L_E_T_ = ' '"
		cQry += "           AND A1.A1_FILIAL = '"+ xFilial("SA1") +"'"
		cQry += "           AND A1.A1_COD = F2.F2_CLIENTE"
		cQry += "           AND A1.A1_LOJA = F2.F2_LOJA"
		cQry += "         INNER JOIN "+ RetSqlName("SA4") +" A4"
		cQry += "            ON A4.D_E_L_E_T_ = ' '"
		cQry += "           AND A4.A4_FILIAL = '"+ xFilial("SA4") +"'"
		cQry += "           AND A4.A4_COD = F2.F2_TRANSP"
		cQry += "          LEFT JOIN "+ RetSqlName("PAB") +" PAB"
		cQry += "            ON PAB.D_E_L_E_T_ = ' '"
		cQry += "           AND PAB.PAB_FILIAL = '"+ xFilial("PAB") +"'"
		cQry += "           AND PAB.PAB_CEP = A1.A1_CEP"
		cQry += "           AND PAB.PAB_TRANSP = F2.F2_TRANSP"
		cQry += "         INNER JOIN "+ RetSqlName("SZU") +" ZU"
		cQry += "            ON ZU.D_E_L_E_T_ = ' '"
		cQry += "           AND ZU.ZU_FILIAL = F2.F2_FILIAL"
		cQry += "           AND ZU.ZU_NOTA = F2.F2_DOC"
		cQry += "           AND ZU.ZU_SERIE = F2.F2_SERIE"
		cQry += "         INNER JOIN "+ RetSqlName("SX5") +" X5"
		cQry += "            ON X5.D_E_L_E_T_ = ' '"
		cQry += "           AND X5.X5_FILIAL = F2.F2_FILIAL"
		cQry += "           AND X5.X5_TABELA = 'ZA'"
		cQry += "           AND X5.X5_CHAVE = ZU.ZU_OCORREN"
		cQry += "         WHERE F2.D_E_L_E_T_ = ' '"
		cQry += "           AND F2.F2_FILIAL = '"+ xFilial("SF2") +"'"
		cQry += "           AND F2.F2_EMISSAO BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"'"
		cQry += "           AND F2.F2_TRANSP BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
		cQry += "           AND F2.F2_TIPO = 'N'"
	EndIf
	cQry += " ) ORDER BY NOTA, SERIE"


	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf

	TCQUERY cQry NEW ALIAS "QRY"

	While QRY->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf

		dDtExped	:= sfGetDtExp(SToD(QRY->EMISSAO)/*dInEmissao*/,;
			QRY->CODCLI/*cInCliente*/,;
			QRY->LOJCLI/*cInLoja*/,;
			QRY->NOTA/*cInNota*/,;
			QRY->SERIE/*cInSerie*/)

		oSection1:Init()
		oSection1:Cell("NOTA"):SetValue(QRY->NOTA)
		oSection1:Cell("SERIE"):SetValue(QRY->SERIE)
		oSection1:Cell("CODCLI"):SetValue(QRY->CODCLI)
		oSection1:Cell("LOJCLI"):SetValue(QRY->LOJCLI)
		oSection1:Cell("NOMCLI"):SetValue(QRY->NOMCLI)
		oSection1:Cell("CIDADE"):SetValue(QRY->CIDADE)
		oSection1:Cell("CODTRAN"):SetValue(QRY->CODTRAN)
		oSection1:Cell("NOMTRAN"):SetValue(QRY->NOMTRAN)
		oSection1:Cell("EMISSAO"):SetValue(SToD(QRY->EMISSAO))
		oSection1:Cell("EXPEDIC"):SetValue(dDtExped)
		oSection1:Cell("VALOR"):SetValue(QRY->VALOR)
		oSection1:Cell("PESOBRU"):SetValue(QRY->PESOBRU)
		oSection1:Cell("VOLUME"):SetValue(QRY->VOLUME)
		oSection1:Cell("PRAZO"):SetValue(QRY->PRAZO)
		oSection1:Cell("ENTREGA"):SetValue(SToD(QRY->ENTREGA))
		oSection1:Cell("HORA"):SetValue(QRY->HORA)
		oSection1:Cell("OCORREN"):SetValue(QRY->OCORREN+"-"+Posicione("SX5",1,xFilial("SX5")+"ZA"+QRY->OCORREN,"X5_DESCRI"))
		oSection1:Cell("OBS"):SetValue(QRY->OBS)
		oSection1:Cell("ROTA"):SetValue(QRY->ROTA)
		// Calcula frete, desconta digitado pelo vendedor QRY->FRETE
		nVlrFrete	:= U_BFFATM22(SToD(QRY->EMISSAO),QRY->CODCLI,QRY->LOJCLI,QRY->CODTRAN,QRY->VALOR,QRY->PESOBRU,QRY->FRETE)
		oSection1:Cell("FRETE"):SetValue(nVlrFrete)

		nPosEnt		:= aScan(aEntAtr,{|x| x[1] == QRY->CIDADE })

		If nPosEnt == 0
			Aadd(aEntAtr,{QRY->CIDADE,0,0,0,0,0,0,0,0,0})
			nPosEnt := Len(aEntAtr)
		Endif
		// Incrementa numero de notas da cidade
		aEntAtr[nPosEnt][nPxQtdNf]++
		aEntTot[nPxQtdNf]++

		aEntAtr[nPosEnt][nPxVlrFat]	+= QRY->VALOR
		aEntTot[nPxVlrFat]	+= QRY->VALOR

		aEntAtr[nPosEnt][nPxVlFret]	+= nVlrFrete
		aEntTot[nPxVlFret]	+= nVlrFrete

		aEntAtr[nPosEnt][nPxVolum]	+= QRY->VOLUME
		aEntTot[nPxVolum]	+= QRY->VOLUME

		aEntAtr[nPosEnt][nPxPeso] += QRY->PESOBRU
		aEntTot[nPxPeso] += QRY->PESOBRU

		// Calcula tempo atraso
		If !Empty(QRY->PRAZO)
			If !Empty(QRY->ENTREGA)
				nDias 	:= Val(QRY->PRAZO)/24
				dAtraso := dDtExped //SToD(QRY->EMISSAO)
				nQtdDFind	:= 0
				//Proxima rota
				While !(AllTrim(Str(DOW(dAtraso))) $ AllTrim(QRY->ROTA))
					dAtraso += 1
				EndDo

				For nI := 1 To nDias
					//Pula Prazo
					dAtraso += 1
					//Sabado ou domingo, pula
					If DOW(dAtraso) == 7
						dAtraso += 2
					ElseIf DOW(dAtraso) == 1
						dAtraso += 1
					EndIf
				Next
				oSection1:Cell("PREVENT"):SetValue(dAtraso)
				nDias	:= SToD(QRY->ENTREGA) - dAtraso // - dDtExped

				For nI := 1 To nDias
					//Pula Prazo
					//Sabado ou domingo, pula
					If DOW(dAtraso+nI) == 7
						nQtdDFind++
					ElseIf DOW(dAtraso+nI) == 1
						nQtdDFind++
					EndIf
				Next


				nAtraso := SToD(QRY->ENTREGA) - dAtraso

				oSection1:Cell("ATRASO"):SetValue(nAtraso - nQtdDFind)
				// Se for atraso
				If ( nAtraso - Iif(nAtraso <= 0,0,nQtdDFind)) > 1
					aEntAtr[nPosEnt][nPxAtrzN]++
					aEntTot[nPxAtrzN]++
				ElseIf ( nAtraso - Iif(nAtraso <= 0,0,nQtdDFind)) > 0
					aEntAtr[nPosEnt][nPxAtrz1]++
					aEntTot[nPxAtrz1]++
				Else
					aEntAtr[nPosEnt][nPxEntPrz]++
					aEntTot[nPxEntPrz]++
				Endif
			Else
				// Sem entrega
				aEntAtr[nPosEnt][nPxPend]++
				aEntTot[nPxPend]++
				oSection1:Cell("ATRASO"):SetValue("")
				oSection1:Cell("PREVENT"):SetValue("")
			EndIf
		Else
			// Com entrega e sem prazo considera no Prazo
			If !Empty(QRY->ENTREGA)
				aEntAtr[nPosEnt][nPxEntPrz]++
				aEntTot[nPxEntPrz]++
			Else
				// Sem entrega
				aEntAtr[nPosEnt][nPxPend]++
				aEntTot[nPxPend]++
			Endif
			oSection1:Cell("PREVENT"):SetValue("")
			oSection1:Cell("ATRASO"):SetValue("")
		EndIf


		oSection1:Printline()
		QRY->(dbSkip())

	Enddo
	oSection1:Finish()
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf

	aSort(aEntAtr,,,{|x,y| x[1] < y[1] })
	oSection2:Init()
	For nI	:= 1 To Len(aEntAtr)
		oSection2:Cell("CIDADE"):SetValue(aEntAtr[nI,nPxCidade])
		oSection2:Cell("QTENFS"):SetValue(aEntAtr[nI,nPxQtdNf])
		oSection2:Cell("QTEPRZ"):SetValue(aEntAtr[nI,nPxEntPrz])
		oSection2:Cell("PNFPRZ"):SetValue(Round(aEntAtr[nI,nPxEntPrz]/aEntAtr[nI,nPxQtdNf]*100,2))
		oSection2:Cell("QTEATR1"):SetValue(aEntAtr[nI,nPxAtrz1])
		oSection2:Cell("PNFATR1"):SetValue(Round(aEntAtr[nI,nPxAtrz1]/aEntAtr[nI,nPxQtdNf]*100,2))
		oSection2:Cell("QTEATRZ"):SetValue(aEntAtr[nI,nPxAtrzN])
		oSection2:Cell("PNFATRZ"):SetValue(Round(aEntAtr[nI,nPxAtrzN]/aEntAtr[nI,nPxQtdNf]*100,2))
		oSection2:Cell("QTEPEN"):SetValue(aEntAtr[nI,nPxPend])
		oSection2:Cell("PNFPEN"):SetValue(Round(aEntAtr[nI,nPxPend]/aEntAtr[nI,nPxQtdNf]*100,2))
		oSection2:Cell("VLRFAT"):SetValue(aEntAtr[nI,nPxVlrFat])
		oSection2:Cell("VLRFRE"):SetValue(aEntAtr[nI,nPxVlFret])
		oSection2:Cell("PVLFRE"):SetValue(Round(aEntAtr[nI,nPxVlFret] / aEntAtr[nI,nPxVlrFat] * 100,2))
		oSection2:Cell("QTVOLU"):SetValue(aEntAtr[nI,nPxVolum])
		oSection2:Cell("QTPESO"):SetValue(aEntAtr[nI,nPxPeso])
		oSection2:Printline()
	Next
	// Imprime somatória
	oReport:ThinLine()
	oSection2:Cell("CIDADE"):SetValue(aEntTot[nPxCidade])
	oSection2:Cell("QTENFS"):SetValue(aEntTot[nPxQtdNf])
	oSection2:Cell("QTEPRZ"):SetValue(aEntTot[nPxEntPrz])
	oSection2:Cell("PNFPRZ"):SetValue(Round(aEntTot[nPxEntPrz]/aEntTot[nPxQtdNf]*100,2))
	oSection2:Cell("QTEATR1"):SetValue(aEntTot[nPxAtrz1])
	oSection2:Cell("PNFATR1"):SetValue(Round(aEntTot[nPxAtrz1]/aEntTot[nPxQtdNf]*100,2))
	oSection2:Cell("QTEATRZ"):SetValue(aEntTot[nPxAtrzN])
	oSection2:Cell("PNFATRZ"):SetValue(Round(aEntTot[nPxAtrzN]/aEntTot[nPxQtdNf]*100,2))
	oSection2:Cell("QTEPEN"):SetValue(aEntTot[nPxPend])
	oSection2:Cell("PNFPEN"):SetValue(Round(aEntTot[nPxPend]/aEntTot[nPxQtdNf]*100,2))
	oSection2:Cell("VLRFAT"):SetValue(aEntTot[nPxVlrFat])
	oSection2:Cell("VLRFRE"):SetValue(aEntTot[nPxVlFret])
	oSection2:Cell("PVLFRE"):SetValue(Round(aEntTot[nPxVlFret]/aEntTot[nPxVlrFat]*100,2))
	oSection2:Cell("QTVOLU"):SetValue(aEntTot[nPxVolum])
	oSection2:Cell("QTPESO"):SetValue(aEntTot[nPxPeso])


	oSection2:Printline()

	oSection2:Finish()

	oReport:EndPage()



Return


Static Function sfGetDtExp(dInEmissao,cInCliente,cInLoja,cInNota,cInSerie)

	Local	aAreaOld	:= GetArea()
	Local	dDtExp		:= dInEmissao
	Local	cQry		:= ""

	cQry += "SELECT Z1_EMISSAO "
	cQry += "  FROM " + RetSqlName("SZ1") + " Z1 "
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND Z1_MSFIL = '" + cFilAnt + "'"
	cQry += "   AND Z1_CLIENTE = '" + cInCliente +  "'"
	cQry += "   AND Z1_LOJA = '" + cInLoja + "'"
	cQry += "   AND Z1_NOTAFIS = '" + cInNota + "'"
	cQry += "   AND Z1_SERIE = '" + cInSerie + "'"
	cQry += "   AND Z1_FILIAL = '" + xFilial("SZ1") + "'"
	cQry += " ORDER BY Z1_EMISSAO DESC "

	TcQuery cQry New Alias "QSZ1"

	If !Eof()
		dDtExp	:= STOD(QSZ1->Z1_EMISSAO)
	Endif
	QSZ1->(DbCloseArea())
	RestArea(aAreaOld)

Return dDtExp


/*/{Protheus.doc} FATA55I
(Importa arquivo conforme layout PROCEDA OCORRENCIA)
@type function
@author Iago Luiz Raimondi
@since 30/01/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FATA55E()

	Local aPergs 	:= {}
	Local aRet		:= {}
	Local nCount	:= 0
	Local cIdArq	:= " "
	Local oFile
	Private aLog	:= {}

	aAdd(aPergs,{6,"Buscar arquivo",Space(50),"","","",80,.F.,"Todos os arquivos texto (*.txt) |*.txt"})

	If !ParamBox(@aPergs,"Parametros ",aRet)
		MsgAlert("Operação cancelada!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf

	oFile := FWFileReader():New(MV_PAR01)
	If oFile:Open()
		While oFile:hasLine()
			cLinha := oFile:GetLine()

			// Pega IDENTIFICAÇÃO DO DOCUMENTO
			If Substr(cLinha,1,3) == "340"
				cIdArq := Substr(cLinha,4,14)
			EndIf

			// Pega OCORRENCIAS DE ENTREGA
			If Substr(cLinha,1,3) == "342"
				If Substr(cLinha,4,14) == SM0->M0_CGC
					// IAGO 20/07/2017 Chamado(18581)
					If !Empty(Substr(cLinha,35,4) + Substr(cLinha,33,2) + Substr(cLinha,31,2))
						// Motivos de entrega avaliados pela Patrick SC
						//01 Entrega Realizada Normalmente
						//02 Entrega Fora da Data Programada
						//19 Reentrega Solicitada pelo Cliente
						//22 Reentrega sem Cobrança do Cliente
						//24 Mercadoria Reentregue ao Cliente Destino
						//29 Cliente Retira Mercadoria na Transportadora
						//31 Entrega com Indenização Efetuada

						If Substr(cLinha,29,2) $ "01#02#19#22#24#29#31"
							cArq		:= cIdArq
							cNota		:= sfVldMsc(Substr(cLinha,21,8))
							cSerie		:= Substr(cLinha,18,3)
							cDataEnt	:= Substr(cLinha,35,4) + Substr(cLinha,33,2) + Substr(cLinha,31,2)
							cHoraEnt	:= Substr(cLinha,39,2) +":"+ Substr(cLinha,41,2)
							cOcorr		:= Substr(cLinha,29,2)
							cObs		:= Substr(cLinha,45,70)
							If sfGravaSZU(cArq,cNota,cSerie,cDataEnt,cHoraEnt,cOcorr,cObs)
								++nCount
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		End
		oFile:Close()
		If Len(aLog) > 0
			sfMsgInfo()
		Endif

		If nCount >= 0
			MsgAlert(cValToChar(nCount)+" registro(s) incluído(s) com sucesso.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Else
			MsgAlert("Nenhum registro foi incluso.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		EndIf

	Else
		MsgStop("Não foi possível abrir o arquivo : ERRO "+Str(fError(),4),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf

Return


/*/{Protheus.doc} sfVldMsc
(long_description)
@type function
@author Iago Luiz Raimondi
@since 27/02/2017
@version 1.0
@param cNota, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldMsc(cNota)

	Local cNewNota 	:= ""
	Default cNota 	:= ""

	If SM0->M0_CODFIL $ "01#04#05#"
		cNewNota := PadR(PadL(cValToChar(Val(cNota)),6,"0"),9," ")
	Else
		cNewNota := PadL(cValToChar(Val(cNota)),9,"0")
	EndIf

Return cNewNota


/*/{Protheus.doc} sfCriaSx1
(Cria perguntas da rotina)
@type function
@author Iago Luiz Raimondi
@since 21/12/2016
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg,'01','Emissão de','Emissão de','Emissão de','mv_ch1','D',8,0,0,'G','','','','','mv_par01')
	PutSx1(cPerg,'02','Emissão até','Emissão até','Emissão até','mv_ch2','D',8,0,0,'G','','','','','mv_par02')
	PutSx1(cPerg,'03','Transp. de','Transp de','Transp de','mv_ch3','C',Len(CriaVar("A4_COD")),0,0,'G','','SA4','','','mv_par03')
	PutSx1(cPerg,'04','Transp. até','Transp até','Transp até','mv_ch4','C',Len(CriaVar("A4_COD")),0,0,'G','NaoVazio()','SA4','','','mv_par04')
	PutSx1(cPerg,'05','Tipo','Tipo','Tipo','mv_ch5','N',1,0,0,'C','','','','','mv_par05','Pendente','Pendente','Pendente','','Entregue','Entregue','Entregue','Todos','Todos','Todos')

Return


/*/{Protheus.doc} sfMsgInfo
//TODO Função para exibir Mensagens de uma só vez
@author Marcelo Alberto Lauschner
@since 10/11/2018
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfMsgInfo()

	Local	oBrowser
	Local	oDlgUsr
	Local	bLine

	DEFINE DIALOG oDlgUsr TITLE "Mensagens de Logs" FROM 0,0 To 619,664 Pixel

	@ 5, 5 LISTBOX oBrowser ;
		FIELDS	"" ;
		HEADER "Mensagem";
		SIZE 322, 290 OF oDlgUsr PIXEL

	bLine := { || { ;
		aLog[ oBrowser:nAt,1 ]} }

	oBrowser:SetArray( aLog )
	oBrowser:bLine := bLine


	ACTIVATE DIALOG oDlgUsr //CENTERED ON INIT ( EnchoiceBar( oDlgUsr, { || oDlgUsr:End() }, {||  oDlgUsr:End()}  ) )


Return
