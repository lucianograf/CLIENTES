#Include 'Protheus.ch'

/*/{Protheus.doc} BFESTA02
(Rotina para importação de registro de inventário. Importa através de arquivo .csv
ATENÇÃO: !!!!Trabalhar em conjunto com o fonte BFESTR03!!!!)
@author Iago Luiz Raimondi
@since 12/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFESTA02()



	Private		aCols := {}
	Private 	aHeader := {}
	Private		oDlg,oPanel1,oPanel2,oPanel3,oTGet1,oTButton1
	Private 	aSize := MsAdvSize(,.F.,400)
	Private		dDate := dDataBase
	Private 	cArqImp := Space(150)

	Define MsDialog oDlg Title OemToAnsi("Importação Tabela Inventário") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM


	oSay		:= TSay():New(012,030,{||"Data: "},oPanel1,,,,,,.T.,,,200,20)
	oTGet1 		:= TGet():New(010,050,{|u|If(PCount()== 0,dDate,dDate := u) },oDlg,060,010,"@D",,0,16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"dDate")

	oSay		:= TSay():New(012,130,{||"Arquivo: "},oPanel1,,,,,,.T.,,,200,20)
	oTGet2 		:= TGet():New(010,160,{||cArqImp},oDlg,150,010,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,cArqImp)
	oTButton1 	:= TButton():New(010,300,"Buscar",oDlg,{||cArqImp := cGetFile('*.csv',"Selecione o arquivo para importa o inventário",1,'C:\EDI\',.F.,,.F.,.T.),MsgRun("Processando arquivo .csv","Aguarde",{|| CarregaArq(cArqImp,@oMulti:aHeader,@oMulti:aCols) })},40,12,,,.F.,.T.,.F.,,.F.,,,.F. )

	CarregaArq(cArqImp,@aHeader,@aCols)

	Private oMulti := MsNewGetDados():New(005,005,aSize[4],aSize[3],GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",;
		,0/*nFreeze*/,10000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,;
		/*cApagaOk*/,oPanel2,@aHeader,@aCols)

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	Activate MSDIALOG oDlg On Init (EnchoiceBar(oDlg,{||MsgRun("Importando arquivo .csv","Aguarde",{||ConfirmaReg(@oMulti:aCols,@oMulti:aHeader),oDlg:End()})},{|| oDlg:End()}))


Return


/*/{Protheus.doc} CarregaArq
(Monta aCols para aprensar no MsNewGetDados)
@author Iago Luiz Raimondi
@since 13/08/2015
@version 1.0
@param aArray, array, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function CarregaArq(cArqImp,aHeader,aCols)

	Local aCampos :={"B7_FILIAL", "B7_LOCAL", "B1_PROC", "B1_FABRIC", "B7_COD", "B7_DESC", "B7_QUANT"}
	Local iX, nI, i
	local nColuna := 0 as numeric
	// Dinamico, assim nao depende do excel
	Private nPosFil 	:= aScan(aCampos,"B7_FILIAL")
	Private nPosLoc 	:= aScan(aCampos,"B7_LOCAL")
	Private nPosFor 	:= aScan(aCampos,"B1_PROC")
	Private nPosFab 	:= aScan(aCampos,"B1_FABRIC")
	Private nPosCod 	:= aScan(aCampos,"B7_COD")
	Private nPosDesc	:= aScan(aCampos,"B7_DESC")
	Private nPosQtd 	:= aScan(aCampos,"B7_QUANT")

	// Monta aHeader
	If Len(aHeader) == 0
		DbSelectArea("SX3")
		DbSetOrder(2)
		For iX := 1 To Len(aCampos)
			If X3USO(GetSx3Cache(cCampo,"X3_USADO"))
				Aadd(aHeader,{AllTrim(GetSx3Cache(cCampo,"X3_TITULO")),;
					GetSx3Cache(cCampo,"X3_CAMPO")		,;
					GetSx3Cache(cCampo,"X3_PICTURE")	,;
					GetSx3Cache(cCampo,"X3_TAMANHO")	,;
					GetSx3Cache(cCampo,"X3_DECIMAL")	,;
					GetSx3Cache(cCampo,"X3_VALID")		,;
					GetSx3Cache(cCampo,"X3_USADO")		,;
					GetSx3Cache(cCampo,"X3_TIPO")		,;
					GetSx3Cache(cCampo,"X3_F3") 		,;
					GetSx3Cache(cCampo,"X3_CONTEXT")	,;
					GetSx3Cache(cCampo,"X3_CBOX")		,;
					GetSx3Cache(cCampo,"X3_RELACAO") 	})
			EndIf
			//If DbSeek(aCampos[iX])
			//	Aadd(aHeader,{ AllTrim(X3Titulo()),;
			//		SX3->X3_CAMPO	,;
			//		SX3->X3_PICTURE,;
			//		SX3->X3_TAMANHO,;
			//		SX3->X3_DECIMAL,;
			//		"",;//SX3->X3_VALID	,;
			//		SX3->X3_USADO	,;
			//		SX3->X3_TIPO	,;
			//		SX3->X3_F3 		,;
			//		SX3->X3_CONTEXT,;
			//		SX3->X3_CBOX	,;
			//		""})//SX3->X3_RELACAO })
			//Endif
		Next
	EndIf

	// Monta aCols
	aCols := {}
	If File(cArqImp)

		If (Select("TRB") <> 0)
			TRB->(dbCloseArea())
		Endif

		aTab := {}
		AADD(aTab,{ "LINHA" ,"C",680,0 })

		cAlias := "TRB"
		oTmpTable := FWTemporaryTable():New(cAlias,aTab)
		oTmpTable:Create()
		dbSelectArea(cAlias)

		//dbSelectArea("TRB")
		//Append From (cArqImp) SDF

		//DbSelectArea("TRB")
		DbGotop()

		lFirst := .T.
		While TRB->(!EOF())
			If lFirst
				TRB->(dbSkip())
				TRB->(dbSkip())
				lFirst := !lFirst
				Loop
			EndIf

			aArrDados	:= StrTokArr(TRB->LINHA,";")

			// ULTIMA LINHA, SAI LOOP
			If Len(aArrDados) == 0 .OR. Empty(TRB->LINHA)
				Exit
			EndIf

			// LINHA INVALIDA, IGNORA
			If Len(aArrDados) < Len(aCampos)
				cErro := ""
				For i := 1 To Len(aArrDados)
					cErro += aArrDados[i]+" "
				Next
				MsgAlert("Linha inválida, não será importado !!! Dados: "+ AllTrim(cErro))
				TRB->(dbSkip())
				Loop
			EndIf

			// QUANTIDADE VAZIO, IGNORA
			If AllTrim(aArrDados[nPosQtd]) == ""
				TRB->(dbSkip())
				Loop
			EndIf

			/* DEVE IMPORTAR COM ZERO
			If AllTrim(aArrDados[nPosQtd]) == "0"
				TRB->(dbSkip())
				Loop
			EndIf
			*/

			If aArrDados[nPosFil] != cFilAnt
				If MsgYesNo("A filial do registro, não corresponde a filial posicionada. O registro não será inserido. Deseja Continuar ?")
					TRB->(dbSkip())
					Loop
				Else
					Exit
				EndIf
			EndIf

			Aadd(aCols,Array(Len(aHeader)+1))
			aCols[Len(aCols),Len(aHeader)+1]	:= .F.

			For nI := 1 To Len(aHeader)
				If Alltrim(aHeader[nI][2]) == "B7_FILIAL"
					aCols[Len(aCols)][nI]	:= aArrDados[nPosFil]
				ElseIf Alltrim(aHeader[nI][2]) == "B1_FABRIC"
					aCols[Len(aCols)][nI]	:= aArrDados[nPosFab]
				ElseIf Alltrim(aHeader[nI][2]) == "B1_PROC"
					aCols[Len(aCols)][nI]	:= aArrDados[nPosFor]
				ElseIf Alltrim(aHeader[nI][2]) == "B7_COD"
					aCols[Len(aCols)][nI]	:= aArrDados[nPosCod]
				ElseIf Alltrim(aHeader[nI][2]) == "B7_DESC"
					aCols[Len(aCols)][nI]	:= aArrDados[nPosDesc]
				ElseIf Alltrim(aHeader[nI][2]) == "B7_LOCAL"
					aCols[Len(aCols)][nI]	:= aArrDados[nPosLoc]
				ElseIf Alltrim(aHeader[nI][2]) == "B7_QUANT"
					aCols[Len(aCols)][nI]	:= Val(aArrDados[nPosQtd])
				EndIf
			Next

			// Deleta linha caso produto estiver bloqueado
			dbSelectArea("SB1")
			If dbSeek(aCols[Len(aCols)][nPosFil]+aCols[Len(aCols)][nPosCod])
				If SB1->B1_MSBLQL = '1'
					aCols[Len(aCols),Len(aHeader)+1]	:= .T.
				EndIf
			Else
				aCols[Len(aCols),Len(aHeader)+1]	:= .T.
			EndIf

			TRB->(dbSkip())
		End
	Else
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
		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	EndIf

	If (Select("TRB") <> 0)
		TRB->(dbCloseArea())
	Endif

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
	EndIf

Return

/*/{Protheus.doc} ConfirmaReg
(Monta array para gravação do registro via Static Function GravaReg, recebe aCols como parâmetro)
@author Iago Luiz Raimondi
@since 13/08/2015
@version 1.0
@param aCols, array, (Recebe aAcols do MsNewGetDados)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ConfirmaReg(aCols,aHeader)

	local nI := 0 as numeric
	Private aArray := {}
	Private nErros := 0

	// Dinamico, assim nao depende das colunas no CSV
	Private nPosCod := aScan(aHeader,{|x| AllTrim(x[2]) == "B7_COD"})
	Private nPosFil := aScan(aHeader,{|x| AllTrim(x[2]) == "B7_FILIAL"})
	Private nPosQtd := aScan(aHeader,{|x| AllTrim(x[2]) == "B7_QUANT"})
	Private nPosLoc := aScan(aHeader,{|x| AllTrim(x[2]) == "B7_LOCAL"})



	For nI := 1 To Len(aCols)
		If !aCols[nI][Len(aCols[nI])]
			dbSelectArea("SB1")
			If dbSeek(aCols[nI][nPosFil]+aCols[nI][nPosCod])
				If SB1->B1_MSBLQL != '1'
					aArray := {{"B7_FILIAL" , aCols[nI][nPosFil]		,Nil},;
						{"B7_COD"		,aCols[nI][nPosCod]			,Nil},;
						{"B7_DOC"		,DtoS(Date())+"X"			,Nil},;
						{"B7_QUANT"		,aCols[nI][nPosQtd]			,Nil},;
						{"B7_LOCAL"		,aCols[nI][nPosLoc]			,Nil},;
						{"B7_DATA"		,dDate						,Nil}}
					dbSelectArea("SB2")
					dbSetOrder(1)
					If !dbSeek(aCols[nI][nPosFil]+SB1->B1_COD+aCols[nI][nPosLoc])
						//IAGO 10/08/2016 Chamado(15512)
						//CriaSB2(aCols[nI][nPosCod],aCols[nI][nPosLoc])
						CriaSB2(SB1->B1_COD,aCols[nI][nPosLoc])
						MsgInfo("Sistema acabou de criar o armazém "+aCols[nI][nPosLoc]+" para o produto "+aCols[nI][nPosCod])
					EndIf

					If !GravaReg(aArray)
						nErros++
						MsgAlert("Erro de importação, elemento "+ cValToChar(nI))
					EndIf
				Else
					nErros++
					MsgAlert("Erro de importação, produto "+ aCols[nI][nPosCod]+ " está bloqueado na filial "+ aCols[nI][nPosFil])
				EndIf
			Else
				nErros++
				MsgAlert("Erro de importação, produto "+ aCols[nI][nPosCod]+ " não foi encontrado na filial "+ aCols[nI][nPosFil])
			EndIf
		EndIf
	Next

	MsgInfo("Importação finalizada"+ Iif(nErros > 0,", porem com "+ cValToChar(nErros) +" erro(s)."," com sucesso."))

Return

/*/{Protheus.doc} GravaReg
(Grava array recebido por parametro via execauto)
@author Iago Luiz Raimondi
@since 13/08/2015
@version 1.0
@param aArray, array, (Recebe array para gravar via execauto)
@return ${lReturn}, ${Retorno da gravação via execauto}
@example
(examples)
@see (http://tdn.totvs.com/pages/releaseview.action;jsessionid=A4367A92C5328525A2CC55CB4F8D1389?pageId=51250512)
/*/
Static Function GravaReg(aArray)

	Local lReturn       := .F.
	local nX            := 0 as numeric
	Default aArray      := {}
	Private lMsHelpAuto := .F.
	Private lMsErroAuto := .F.

	If Len(aArray) > 0

		Begin Transaction
			MSExecAuto({|x,y,z| MATA270(x,y,z)},aArray,.T.,3)
		End Transaction

		If lMsErroAuto
			MostraErro()
			// Envia erro por e-mail
			cMensagem := ""
			aLog := GetAutoGRLog()
			For nX := 1 To Len(aLog)
				cMensagem += aLog[nX]+"<br>"
			Next nX
			U_WFGERAL("informatica1@atrialub.com.br;marcelo@centralxml.com.br","Erro Importação Inventário",cMensagem,"BFESTA02")
		EndIf
		lReturn := !lMsErroAuto
	EndIf

Return lReturn

