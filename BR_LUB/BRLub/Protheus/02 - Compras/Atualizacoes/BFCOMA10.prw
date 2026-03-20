#Include 'Protheus.ch'

/*/{Protheus.doc} BFCOMA10
Ajuste de tabela de preço de fornecedores por meio de arquivo .CSV
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 8/16/2014
/*/
User Function BFCOMA10()


	Private 	dDataLanc	:= dDataBase
	Private 	cArqImp		:= Space(150)
	Private 	oArqIMp,oDescEnt
	Private		cDescEnt	:= Space(50)
	Private		aCols,aHeader
	Private 	aButton		:= {{"VERDE"		,{|| COMA010()}  ,"Tabela Preços"}}
	Private		nPxITEM,nPxCODFOR,nPxLOJFOR,nPxXPRCMV,nPxPRCCOM,nPxCODPRO,nPxXFRETE,nPxDESCRI
	Private 	aSize 		:= MsAdvSize(,.F.,400)

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Importação Tabela Preços de Fornecedores") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

	oDlg:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM


	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	@ 012 ,005  	Say OemToAnsi("Data Vigência Inicial") SIZE 60,9 PIXEl OF oPanel1 FONT oFnt
	@ 011 ,073  	MSGET dDataLanc  Picture "99/99/9999" PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON

	@ 012 ,153   	Say OemToAnsi("Arquivo") SIZE 30,9 PIXEl	OF oPanel1 FONT oFnt
	@ 011 ,191		MSGET oArqIMp VAR cArqImp Picture "@!" PIXEl SIZE 132, 10 OF oPanel1 Valid (cArqImp := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo",,"C:\EDI\",.T., ),Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados..."))

	Processa({|| sfCarrega(@aCols,@aHeader,1) },"Localizando registros...")

	Private oMulti := MsNewGetDados():New(034, 005, 226, 415,GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",;
		,0/*nFreeze*/,10000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,;
	/*cApagaOk*/,oPanel2,@aHeader,@aCols,{|| Nil })

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT


	ACTIVATE MSDIALOG oDlg ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlg,{|| Processa({||sfGrava()},"Efetuando gravações...") , oDlg:End() },{|| oDlg:End()},,aButton))



Return

/*/{Protheus.doc} sfCarrega
Função para carregar dados e estrutura do aCols
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 7/11/2022
@param aCols, array, vetor do aCols
@param aHeader, array, vetor do aHeader
@param nRefrBox, numeric, controle do refresh
/*/
Static Function sfCarrega(aCols,aHeader,nRefrBox)

	Local nUsado     := 0
	Local aCpo       :={"AIB_CODFOR", "AIB_LOJFOR", "AIB_ITEM", "AIB_CODPRF", "AIB_CODPRO", "AIB_DESCRI", "AIB_XPRCMV", "AIB_PRCCOM", "AIB_XFRETE"}
	Local cLinha     := "0000"
	Local lCodPrf    := .F.
	Local cAIBCODPRO := ""
	Local cCampo     := ""
	Local cAlias     := ""
	Local oTmpTable, iX
	local nI         := 0 as numeric
	local nColuna    := 0 as numeric

	aCols			:= 	{}
	aHeader			:=	{}


	// DbSelectArea("SX3")
	// DbSetOrder(2)
	For iX := 1 To Len(aCpo)
		cCampo := aCpo[iX]
		Aadd(aHeader,{AllTrim(GetSx3Cache(cCampo,"X3_TITULO")),;
			GetSx3Cache(cCampo,"X3_CAMPO")		,;
			GetSx3Cache(cCampo,"X3_PICTURE")	,;
			GetSx3Cache(cCampo,"X3_TAMANHO")	,;
			GetSx3Cache(cCampo,"X3_DECIMAL")	,;
			""									,;
			GetSx3Cache(cCampo,"X3_USADO")		,;
			GetSx3Cache(cCampo,"X3_TIPO")		,;
			GetSx3Cache(cCampo,"X3_F3") 		,;
			GetSx3Cache(cCampo,"X3_CONTEXT")	,;
			GetSx3Cache(cCampo,"X3_CBOX")		,;
			"" 									})
		nUsado++
		If nRefrBox == 1
			&("nPx"+Substr(GetSx3Cache(cCampo,"X3_CAMPO"),5,6)) := nUsado
		Endif
	Next
	// Se for chamado a partir da rotina de atualização do arquivo de importação
	If nRefrBox == 2 .And. cArqImp <> Nil .And. File(cArqImp)

		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",680,0 })

		// cNomArq := CriaTrab(aCampos)

		If (Select(cAlias) <> 0)
			dbSelectArea(cAlias)
			(cAlias)->(dbCloseArea())
		Endif

		cAlias := "TRB"
		oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
		oTmpTable:Create()

		dbSelectArea(cAlias)

		// dbUseArea(.T.,,cNomArq,cAlias,nil,.F.)
		// dbSelectArea("TRB")

		Append From (cArqImp) SDF

		ProcRegua(RecCount())

		DbSelectArea(cAlias)
		DbGotop()
		While !Eof()

			IncProc()

			aArrDados	:= StrTokArr(StrTran(StrTran(TRB->LINHA,".",""),",",".")+";",";")

			If Len(aArrDados) >= 4 .And. Alltrim(aArrDados[3]) == "CODFORNECEDOR"
				lCodPrf	:= .T.
			ElseIf Len(aArrDados) >= 4 .And. Val(aArrDados[4]) > 0

				Aadd(aCols,Array(Len(aHeader)+1))
				cLinha	:= Soma1(cLinha)
				aCols[Len(aCols),Len(aHeader)+1]	:= .F.

				For nI := 1 To Len(aHeader)
					If Alltrim(aHeader[nI][2]) == "AIB_ITEM"
						aCols[Len(aCols)][nI]	:= cLinha
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_CODPRF"
						If lCodPrf
							cAIBCODPRO	:= CriaVar("AIB_CODPRO",.T.)
							cQry := "SELECT A5_PRODUTO,A5_CODPRF,B1_DESC "
							cQry += "  FROM " + RetSqlName("SA5") + " A5, " + RetSqlName("SB1")+ " B1 "
							cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
							cQry += "   AND B1_MSBLQL != '1' "
							cQry += "   AND B1_COD = A5_PRODUTO "
							cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
							cQry += "   AND A5.D_E_L_E_T_ = ' ' "
							cQry += "   AND A5_CODPRF LIKE '%" + Alltrim(aArrDados[3]) + "%' "
							cQry += "   AND A5_LOJA = '" + aArrDados[2] + "' "
							cQry += "   AND A5_FORNECE = '" + aArrDados[1] + "' "
							cQry += "   AND A5_FILIAL = '" + xFilial("SA5") + "' "
							cQry += "UNION "
							cQry += "SELECT B1_COD,B1_FABRIC,B1_DESC "
							cQry += "  FROM " + RetSqlName("SB1") + " B1 "
							cQry += " WHERE B1.D_E_L_E_T_ =' ' "
							cQry += "   AND B1_MSBLQL != '1' "
							cQry += "   AND B1_FABRIC LIKE '%" + Alltrim(aArrDados[3]) + "%' "
							cQry += "   AND B1_LOJPROC = '" + aArrDados[2] + "' "
							cQry += "   AND B1_PROC = '" + aArrDados[1] + "' "
							cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "

							dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QSA5",.T.,.T.)

							If !Eof()
								aCols[Len(aCols)][nI]	:= QSA5->A5_CODPRF
								cAIBCODPRO					:= QSA5->A5_PRODUTO
								DbSelectArea("SB1")
								DbSetOrder(1)
								DbSeek(xFilial("SB1")+cAIBCODPRO)
								aCols[Len(aCols),Len(aHeader)+1]	:= !RegistroOk("SB1",.F.)
							Else
								DbSelectArea("SB1")
								DbSetOrder(1)
								DbSeek(xFilial("SB1")+cAIBCODPRO)
								aCols[Len(aCols)][nI]				:= aArrDados[3]
								aCols[Len(aCols),Len(aHeader)+1]	:= .T.
							Endif

							QSA5->(DbCloseArea())
						Endif
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_CODPRO"
						If !lCodPrf
							aCols[Len(aCols)][nI] 	:= CriaVar(aHeader[nI][2],.T.)
							DbSelectArea("SB1")
							DbSetOrder(1)
							If DbSeek(xFilial("SB1")+aArrDados[3])
								aCols[Len(aCols)][nI]	:= SB1->B1_COD
								aCols[Len(aCols),Len(aHeader)+1]	:= !RegistroOk("SB1",.F.)
							Else
								aCols[Len(aCols)][nI]	:= aArrDados[3]
								aCols[Len(aCols),Len(aHeader)+1]	:= .T.
							Endif
						Else
							aCols[Len(aCols)][nI]	:= cAIBCODPRO
						Endif
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_CODFOR"
						aCols[Len(aCols)][nI] :=  AArrDados[1]
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_LOJFOR"
						aCols[Len(aCols)][nI] :=  aArrDados[2]
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_XPRCMV"
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						aCols[Len(aCols)][nI] :=  Val(aArrDados[4])
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_PRCCOM"
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						aCols[Len(aCols)][nI] :=  Val(aArrDados[4])
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_XFRETE"
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						aCols[Len(aCols)][nI] :=  Val(aArrDados[5])
					ElseIf Alltrim(aHeader[nI][2]) == "AIB_DESCRI"
						aCols[Len(aCols)][nI]	:= SB1->B1_DESC
					Else
						//aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
					Endif
				Next

			Endif
			DbSelectArea("TRB")
			DbSkip()
		Enddo

		TRB->(DbCloseArea())

		If Select("QSA2") > 0
			QSA2->(DbCloseArea())
		Endif
		FErase(cNomArq + GetDbExtension()) // Deleting file
		FErase(cNomArq + OrdBagExt()) // Deleting index

	Endif

	If Len(aCols) == 0
		AADD(aCols,Array(Len(aHeader)+1))
		For nColuna := 1 to Len( aHeader )

			If aHeader[nColuna][8] == "C"
				aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
			ElseIf aHeader[nColuna][8] == "D"
				aCols[Len(aCols)][nColuna] := dDataBase
			ElseIf aHeader[nColuna][8] == "M"
				aCols[Len(aCols)][nColuna] := ""
			ElseIf aHeader[nColuna][8] == "N"
				aCols[Len(aCols)][nColuna] := 0
			Else
				aCols[Len(aCols)][nColuna] := .F.
			Endif
			If !Empty(aHeader[nColuna][12])
				//aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
			Endif
			If Alltrim(aHeader[nColuna][2]) == "AIB_ITEM"
				aCols[Len(aCols)][nColuna]	:= "0001"
			Endif

		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
	Endif

Return

/*/{Protheus.doc} sfGrava
Função para efetivar gravação dos dados de tela
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 8/17/2014
/*/
Static Function sfGrava()

	Local aCabec     := {}
	Local aItens     := {}
	Local PARAMIXB1  := 3
	Local PARAMIXB2,PARAMIXB3
	Local aCpyAcols  := aClone(oMulti:aCols)
	Local cForLoj    := ""
	Local cNewCodTab := ""
	Local lPrcMva    := MsgNoYes("Preço informado é o valor final com ST e a importação irá fazer o descalculo?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	local iZ         := 0 as numeric
	PRIVATE lMsErroAuto := .F.

	// Ordena os dados por fornecedor+loja+produto
	aSort(aCpyAcols,,,{|x,y| x[nPxCODFOR]+x[nPxLOJFOR]+x[nPxCODPRO] <  y[nPxCODFOR]+y[nPxLOJFOR]+y[nPxCODPRO]})

	FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, PadC("BFCOMA10-Manutencao da Tabela de Precos de Fornecedor",80)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	For iZ := 1 To Len(aCpyAcols)
		If !aCpyAcols[iZ,Len(oMulti:aHeader)+1]
			If aCpyAcols[iZ,nPxCODFOR]+aCpyAcols[iZ,nPxLOJFOR] <> cForLoj
				If !Empty(cForLoj) .And. Len(aCabec) > 0 .And. Len(aItens) > 0
					Begin Transaction
						PARAMIXB2 := aClone(aCabec)
						PARAMIXB3 := aClone(aItens)
						MSExecAuto({|x,y,z| coma010(x,y,z)},PARAMIXB1,PARAMIXB2,PARAMIXB3)

						If lMsErroAuto
							MostraErro()
						EndIf
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Fim  : "+Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					End Transaction
				Endif
				lMsErroAuto := .F.
				aItens := {}
				aCabec := {}

				// Ajusta o código da tabela
				DbSelectArea("AIA")
				DbSetOrder(1)	//AIA_FILIAL+AIA_CODFOR+AIA_LOJFOR+AIA_CODTAB
				Do While .T.
					cNewCodTab := GetSxeNum("AIA","AIA_CODTAB")
					If !dbSeek( xFilial( "AIA" ) + aCpyAcols[iZ,nPxCODFOR] + aCpyAcols[iZ,nPxLOJFOR] + cNewCodTab )
						Exit
					EndIf
					If __lSx8
						ConfirmSx8()
					EndIf
				EndDo

				Aadd(aCabec,{"AIA_CODFOR",aCpyAcols[iZ,nPxCODFOR],})
				Aadd(aCabec,{"AIA_LOJFOR",aCpyAcols[iZ,nPxLOJFOR],})
				aadd(aCabec,{"AIA_CODTAB",cNewCodTab,})
				Aadd(aCabec,{"AIA_DESCRI","TABELA DE PRECO POR CSV",})
				Aadd(aCabec,{"AIA_DATDE",dDataLanc,})
				//Aadd(aCabec,{"AIA_DATATE",dDataLanc+1,})
			Endif
			// Somente registros não duplicados
			If aScan(aItens,{|x| x[1,2] == aCpyAcols[iZ,nPxCODPRO] }) == 0

				Aadd(aItens,{})
				Aadd(aItens[Len(aItens)],{"AIB_CODPRO",aCpyAcols[iZ,nPxCODPRO],})

				//aadd(aItens[len(aItens)],{"AIB_DESCRI",aCpyAcols[iZ,nPxDESCRI],})
				If lPrcMva
					Aadd(aItens[Len(aItens)],{"AIB_XPRCMV",aCpyAcols[iZ,nPxXPRCMV],})
				Else
					Aadd(aItens[Len(aItens)],{"AIB_PRCCOM",aCpyAcols[iZ,nPxPRCCOM],})
				Endif
				Aadd(aItens[Len(aItens)],{"AIB_XFRETE",aCpyAcols[iZ,nPxXFRETE],})
				aadd(aItens[len(aItens)],{"AIB_DATVIG",dDataBase,})
			Endif
			cForLoj	:= aCpyAcols[iZ,nPxCODFOR]+aCpyAcols[iZ,nPxLOJFOR]
		Endif
	Next

	If !Empty(cForLoj)  .And. Len(aCabec) > 0 .And. Len(aItens) > 0
		Begin Transaction
			PARAMIXB2 := aClone(aCabec)
			PARAMIXB3 := aClone(aItens)
			MSExecAuto({|x,y,z| coma010(x,y,z)},PARAMIXB1,PARAMIXB2,PARAMIXB3)
			If lMsErroAuto
				MostraErro()
			EndIf
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Fim  : "+Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		End Transaction

	Endif

	If __lSx8
		ConfirmSx8()
	EndIf

	FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, PadC("BFCOMA10-Tabela de Precos de Fornecedor",80)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

Return
