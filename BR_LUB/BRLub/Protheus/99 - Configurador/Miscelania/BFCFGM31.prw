#Include 'Protheus.ch'
#Include "topconn.ch"

/*/{Protheus.doc} BFCFGM31
(Importação de cadastro de produtos a partir de planilha CSV)
@type function
@author marce
@since 31/10/2016
@version 1.0
@param cCodProd, character, (Descrição do parâmetro)
@param cInDescForn, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCFGM31(cCodProd,cInDescForn)

	Local		cInB1COD	:= cCodProd
	Local		cInB1DESC	:= cInDescForn
	Private 	cArqImp	:= Space(150)
	Private 	oArqIMp,oDescEnt
	Private		aCols,aHeader
	Private 	aButton		:= {{"VERDE"		,{|| MATA010()}  ,"Cadastro Produtos"}}
	Private 	aSize := MsAdvSize(,.F.,400)


	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Importação de Produtos") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

	//oDlg:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM


	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	If cInB1Cod == Nil
		@ 012 ,020   	Say OemToAnsi("Arquivo") SIZE 30,9 PIXEl	OF oPanel1 FONT oFnt
		@ 011 ,090		MSGET oArqIMp VAR cArqImp Picture "@!" PIXEl SIZE 132, 10 OF oPanel1 Valid (cArqImp := cGetFile( "Todos os Arquivos (*.*) | *.*", "Selecione o Arquivo",,"C:\EDI\",.T., ),Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados..."))
	Endif

	Processa({|| sfCarrega(@aCols,@aHeader,1,cInB1COD,cInB1DESC) },"Localizando registros...")

	Private oMulti := MsNewGetDados():New(034, 005, 226, 415,GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",;
		,0/*nFreeze*/,10000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,;
		/*cApagaOk*/,oPanel2,@aHeader,@aCols,)

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT


	ACTIVATE MSDIALOG oDlg ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlg,{|| Processa({||sfExec()},"Efetuando gravações...") , oDlg:End() },{|| oDlg:End()},,aButton))



Return



/*/{Protheus.doc} sfCarrega
(Monta aHeader e aCols para o Getdados)
@type function
@author marce
@since 18/10/2016
@version 1.0
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@param nRefrBox, numérico, (Descrição do parâmetro)
@param cInB1COD, character, (Descrição do parâmetro)
@param cInB1DESC, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCarrega(aCols,aHeader,nRefrBox,cInB1COD,cInB1DESC)

	Local	cCpo		:=  "B1_COD#B1_DESC#B1_XCODMIS#B1_POSIPI#B1_CEST"
	Local	iZZ
	Local	nI, nX, oTmpTable
	Local	nColuna
	Local 	nColCodMis	:= 0
	Local	lCodPrf		:= .F.
	Local	aVetCampos	:= {}
	Local	lExistPrd	:= .F.
	Local	nRecSB1		:= 0
	Local 	aFields 		:= {}
	Local 	cCampo 		:= ""

	aCols			:= 	{}
	aHeader			:=	{}

	// DbSelectArea("SX3")
	// DbSetOrder(1)
	// DbSeek("SB1")
	// While !Eof() .And. SX3->X3_ARQUIVO == "SB1"
	// 	If X3Obrigat(SX3->X3_CAMPO) .Or. Alltrim(SX3->X3_CAMPO) $ cCpo
	// 		Aadd(aHeader,{ AllTrim(X3Titulo()),;
	// 			SX3->X3_CAMPO	,;
	// 			SX3->X3_PICTURE,;
	// 			SX3->X3_TAMANHO,;
	// 			SX3->X3_DECIMAL,;
	// 			"",;//SX3->X3_VALID	,;
	// 			SX3->X3_USADO	,;
	// 			SX3->X3_TIPO	,;
	// 			SX3->X3_F3 		,;
	// 			SX3->X3_CONTEXT,;
	// 			SX3->X3_CBOX	,;
	// 			SX3->X3_RELACAO })
	// 	Endif
	// 	If Alltrim(SX3->X3_CAMPO) == "B1_COD"
	// 		cUsado	:= SX3->X3_USADO
	// 	Endif
	// 	DbSkip()
	// Enddo

	aFields := FWSX3Util():GetAllFields("SB1", .F. /*/lVirtual/*/)
	For nX := 1 to Len(aFields)
		cCampo := aFields[nx]
		If X3Obrigat(cCampo) .Or. Alltrim(cCampo) $ cCpo
			Aadd(aHeader,{ AllTrim(X3Titulo())		,;
				GetSx3Cache(cCampo,"X3_CAMPO")		,;
				GetSx3Cache(cCampo,"X3_PICTURE")	,;
				GetSx3Cache(cCampo,"X3_TAMANHO")	,;
				GetSx3Cache(cCampo,"X3_DECIMAL")	,;
				""									,;//SX3->X3_VALID	,;
				GetSx3Cache(cCampo,"X3_USADO")		,;
				GetSx3Cache(cCampo,"X3_TIPO")		,;
				GetSx3Cache(cCampo,"X3_F3") 		,;
				GetSx3Cache(cCampo,"X3_CONTEXT")	,;
				GetSx3Cache(cCampo,"X3_CBOX")		,;
				GetSx3Cache(cCampo,"X3_RELACAO") 	})
		EndIf
		If Alltrim(GetSx3Cache(cCampo,"X3_CAMPO")) == "B1_COD"
			cUsado	:= GetSx3Cache(cCampo,"X3_USADO")
		Endif
	Next nX

	DbSelectArea("SX2")
	DbSetOrder(1)
	If DbSeek("SB1")
		AADD( aHeader, { "Alias WT","SB1_ALI_WT", "", 09, 0,, cUsado, "C", "SB1", "V","",""} )
		AADD( aHeader, { "Recno WT","SB1_REC_WT", "", 09, 0,, cUsado, "N", "SB1", "V","",""} )
	Endif

	// Se for chamado a partir da rotina de atualização do arquivo de importação
	If nRefrBox == 2 .And. cArqImp <> Nil .And. File(cArqImp)

		nColCodMis	:= aScan(aHeader,{|x| AllTrim(x[2]) == "B1_XCODMIS"})
		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",680,0 })

		// cNomArq := CriaTrab(aCampos)

		//If (Select("TRB") <> 0)
		//	dbSelectArea("TRB")
		//	dbCloseArea()
		//Endif
		// dbUseArea(.T.,,cNomArq,"TRB",nil,.F.)
		If(Type('oTmpTable') <> 'U')
			oTmpTable:Delete()
			FreeObj(oTmpTable)
		EndIf

		oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
		oTmpTable:AddIndex("01", {"LINHA"})
		oTmpTable:Create()

		dbSelectArea(cAlias)
		Append From (cArqImp) SDF

		ProcRegua(RecCount())

		DbSelectArea(cAlias)
		DbGotop()
		While !Eof()

			IncProc()
			//Nº	Campo	Descrição	Tipo	Tam.	Dec.	Obrig.
			//01	REG	Texto fixo contendo "0200".	C	004	-	O
			//02	COD_ITEM	Código do item. (1)	C	060	-	O
			//03	DESCR_ITEM	Descrição do item.	C	-	-	O
			//04	COD_BARRA	Representação alfanumérico do código de barra do produto, se houver.	C	-	-	OC
			//05	COD_ANT_ITEM	Código anterior do item com relação à última informação apresentada.	C	060	-	N (informar no 0205)
			//06	UNID_INV	Unidade de medida utilizada na quantificação de estoques.	C	006	-	O
			//07	TIPO_ITEM	Tipo do item - Atividades Industriais, Comerciais e Serviços:
			//00: Mercadoria para Revenda;
			//	01: Matéria-Prima;
			//	02: Embalagem;
			//	03: Produto em Processo;
			//	04: Produto Acabado;
			//	05: Subproduto;
			//	06: Produto Intermediário;
			//	07: Material de Uso e Consumo;
			//	08: Ativo Imobilizado;
			//	09: Serviços;
			//	10: Outros insumos;
			//	99: Outras.	N	2	-	O
			//08	COD_NCM	Código da Nomenclatura Comum do Mercosul (NCM) (2) (3).	C	008*	-	OC
			//09	EX_IPI	Código EX, conforme a TIPI.	C	003	-	OC
			//10	COD_GEN	Código do gênero do item, conforme a Tabela 4.2.1 (4).	N	002*	-	OC
			//11	COD_LST	Código do serviço conforme lista do Anexo I da Lei Complementar Federal nº 116/2003.	C	005	-	OC
			//12	ALIQ_ICMS	Alíquota de ICMS aplicável ao item nas operações internas.	N	006	02	OC
			//13	CEST	Código Especificador da Substituição Tributária (5).	N	007*	-	OC
			cLinhaAtu 	:= (cAlias)->LINHA
			cLinhaAtu 	:= StrTran(cLinhaAtu,Chr(13)+Chr(10),"")
			cLinhaAtu 	:= StrTran(cLinhaAtu,Chr(13),"")
			cLinhaAtu 	:= StrTran(cLinhaAtu,Chr(10),"")
			cLinhaAtu	:= StrTran(cLinhaAtu,"|||","| | |")
			cLinhaAtu	:= StrTran(cLinhaAtu,"||","| |")
			aArrDados	:= StrTokArr(cLinhaAtu+"|","|")

			If Len(aArrDados) >= 1 .And. Alltrim(aArrDados[2]) == "B1_COD"
				aVetCampos	:= aClone(aArrDados)
				lCodPrf	:= .T.
			ElseIf aArrDados[1] <> "0200"
				// Ignora registros que não sejam 0200
			ElseIf Len(aArrDados) >= 1 .And. !Empty(Alltrim(aArrDados[2])) .And. lCodPrf

				Aadd(aCols,Array(Len(aHeader)+1))

				aCols[Len(aCols),Len(aHeader)+1]	:= .F.

				nRecSB1	:= 0

				For nI := 1 To Len(aHeader)
					nPosVet	:= 0
					For iZZ := 1 To Len(aVetCampos)
						If Alltrim(aVetCampos[iZZ]) == Alltrim(aHeader[nI][2])
							nPosVet	:= iZZ
						Endif
					Next
					If IsHeadRec(aHeader[nI][2])
						aCols[Len(aCols)][nI] := nRecSB1
					ElseIf IsHeadAlias(aHeader[nI][2])
						aCols[Len(aCols)][nI] := "SB1"

					ElseIf Alltrim(aHeader[nI][2]) == "B1_COD"
						If lCodPrf
							aCols[Len(aCols)][nI] 	:= CriaVar(aHeader[nI][2],.T.)
							cQry := "SELECT B1.R_E_C_N_O_ B1RECNO,B1_COD"
							cQry += "  FROM " + RetSqlName("SB1")  + " B1 "
							cQry += " WHERE D_E_L_E_T_ =' ' "
							cQry += "   AND B1_FILIAL = '"+xFilial("SB1") + "' "
							cQry += "   AND (B1_COD = '" + aArrDados[nPosVet] + "' OR B1_XCODMIS = '" + aArrDados[nPosVet] + "' )"

							TcQuery cQry New Alias "QSB1"

							If !Eof()
								nRecSB1	:= QSB1->B1RECNO
								aCols[Len(aCols)][nI]				:= QSB1->B1_COD
								aCols[Len(aCols)][nColCodMis]		:= aArrDados[nPosVet]
								aCols[Len(aCols),Len(aHeader)+1]	:= .T.
								lExistPrd	:= .T.
							Else
								aCols[Len(aCols)][nI]				:= aArrDados[nPosVet]
								aCols[Len(aCols)][nColCodMis]		:= aArrDados[nPosVet]
								aCols[Len(aCols),Len(aHeader)+1]	:= .F.
								lExistPrd	:= .F.
							Endif
							QSB1->(DbCloseArea())
						Endif
					Else

						If aHeader[nI][8] == "C" .And. nPosVet > 0 //.And. Len(aArrDados) == nI
							If Alltrim(aHeader[nI][2]) == "B1_CODBAR"
								aCols[Len(aCols)][nI]	:= 	Substr(aArrDados[nPosVet],1,12)
							ElseIf Alltrim(aHeader[nI][2]) == "B1_UM"
								If aArrDados[nPosVet] == "UND"
									aCols[Len(aCols)][nI]	:=  "UN"
								ElseIf aArrDados[nPosVet] == "P?"
									aCols[Len(aCols)][nI]	:=  "PC"
								ElseIf aArrDados[nPosVet] == "GRAM"
									aCols[Len(aCols)][nI]	:=  "G"
								Else
									aCols[Len(aCols)][nI]	:=  aArrDados[nPosVet]
								Endif
							Else
								aCols[Len(aCols)][nI]	:= 	Padr(aArrDados[nPosVet],aHeader[nI][4])
							Endif

						ElseIf aHeader[nI][8] == "N" .And. nPosVet > 0 //.And. Len(aArrDados) >= nI
							aCols[Len(aCols)][nI] 	:= Val(StrTran(StrTran(aArrDados[nPosVet],".",""),",","."))
						Else
							If lExistPrd
								aCols[Len(aCols)][nI]	:= SB1->(&(aHeader[nI][2]))
							ElseIf Alltrim(aHeader[nI][2]) == "B1_XCODMIS"

							Else
								aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
							Endif
							If Alltrim(aHeader[nI][2]) == "B1_TIPO"
								aCols[Len(aCols)][nI]	:= 	"MP"
							ElseIf Alltrim(aHeader[nI][2]) == "B1_UM"
								aCols[Len(aCols)][nI]	:= 	"UN"
							ElseIf Alltrim(aHeader[nI][2]) == "B1_TE"
								aCols[Len(aCols)][nI]	:= 	"001"
							ElseIf Alltrim(aHeader[nI][2]) == "B1_CONTA"
								aCols[Len(aCols)][nI]	:= 	"110206001"
							ElseIf Alltrim(aHeader[nI][2]) == "B1_ORIGEM"
								aCols[Len(aCols)][nI]	:= 	"0"
							ElseIf Alltrim(aHeader[nI][2]) == "B1_LOCPAD"
								aCols[Len(aCols)][nI]	:= 	"01"
							Endif

						Endif
					Endif
					//"B1_COD","B1_DESC","B1_TIPO","B1_LOCPAD","B1_CODBAR","B1_POSIPI","B1_ORIGEM","B1_UM","B1_PESO","B1_PESBRU"}
				Next

			Endif
			DbSelectArea(cAlias)
			DbSkip()
		Enddo

		//(cAlias)->(DbCloseArea())
		If(Type('oTmpTable') <> 'U')
			oTmpTable:Delete()
			FreeObj(oTmpTable)
		EndIf

		// FErase(cNomArq + GetDbExtension()) // Deleting file
		// FErase(cNomArq + OrdBagExt()) // Deleting index
		// Se for chamado a partir da rotina de atualização do arquivo de importação
	ElseIf nRefrBox == 2

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

			If Alltrim(aHeader[nColuna][2]) == "B1_COD"
				aCols[Len(aCols)][nColuna]	:= cInB1COD
			ElseIf Alltrim(aHeader[nColuna][2]) == "B1_DESC"
				aCols[Len(aCols)][nColuna]	:= cInB1DESC
			Endif

		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
	Endif

Return


/*/{Protheus.doc} sfExec
(Efetua a gravação dos dados
@type function
@author marce
@since 18/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExec()

	Local	aCabec	:= {}
	Local	iX
	Local	iA
	Local	lAtuItens 	:= .T. // MsgYesNo("Grava atualização?" )
	Local	nOpcGrv		:= 3
	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.

	ProcRegua(Len(oMulti:aCols))
	For iX := 1 To Len(oMulti:aCols)

		IncProc("Gravando... " +oMulti:aCols[iX,1])

		If !(oMulti:aCols[iX,Len(oMulti:aHeader)+1])
			nOpcGrv := 0
			aCabec 	:= {}
			For iA := 1 To Len(oMulti:aHeader)
				If IsHeadRec(oMulti:aHeader[iA][2])
					If oMulti:aCols[iX,iA] > 0 .And. lAtuItens
						nOpcGrv 	:= 4
					Else
						nOpcGrv		:= 3
					Endif
				ElseIf IsHeadAlias(oMulti:aHeader[iA][2])

				Else
					Aadd(aCabec,{oMulti:aHeader[iA,2],oMulti:aCols[iX,iA] ,Nil})
				Endif

			Next

			lMsErroAuto := .F.
			If nOpcGrv > 0
				MSExecAuto({|x,y| Mata010(x,y)}, aCabec, nOpcGrv)

				If lMsErroAuto
					MostraErro()
				Endif
			Endif

		Endif

	Next

Return

