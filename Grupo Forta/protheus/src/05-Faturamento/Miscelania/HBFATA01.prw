#Include 'Protheus.ch'
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} HBFATA01
(Rotina para importação de Tabelas de preços de venda a partir de arquivos CSV)
@type function
@author Marcelo Alberto Lauschner
@since 11/06/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function HBFATA01()


	Private 	dDataLanc	:= dDataBase
	Private 	cArqImp		:= Space(150)
	Private 	oArqIMp
	Private		aCols,aHeader
	Private 	aButton		:= {{"VERDE"		,{|| OMSA010()}  ,"Tabela Preços"}}
	Private 	aSize := MsAdvSize(,.F.,400)


	DEFINE MSDIALOG oDlg TITLE OemToAnsi("Importação Tabela Preços de Venda") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

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
	/*cApagaOk*/,oPanel2,@aHeader,@aCols)

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT


	ACTIVATE MSDIALOG oDlg ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlg,{|| Processa({|| (sfAtuRodp(),sfGrvDados(oMulti,"DA1"))},"Efetuando gravações...") , oDlg:End() },{|| oDlg:End()},,aButton))

Return 




/*/{Protheus.doc} sfCarrega
(Monta aCols e aHeader para o Getdados)
@type function
@author marce
@since 11/06/2016
@version 1.0
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@param nRefrBox, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCarrega(aCols,aHeader,nRefrBox)

	Local	nUsado		:=  0
	Local	aCpo		:=  {"DA1_CODTAB","DA1_CODPRO","DA1_DESCRI","DA1_ITEM","DA1_PRCVEN","DA1_ATIVO","DA1_DATVIG","DA1_TPOPER","DA1_DTALT","DA1_PRCANT","DA1_FILIAL","DA1_MOEDA"}
	Local	nPosCod		:=  1
	Local	nPosItem	:=  4
	Local	lTabRows	:= .F.	// Indica se o arquivo está no formato de preços em linhas
	Local	lTabCols	:= .F.  // Indica se o arquivo está no formato de preços em colunas
	Local	aTbRef		:= {}
	Local	cUsado		:= ""
	Local	nRecDA1		:= 0
	Local	iX,nX,nI,nColuna,iCodTb,nZ
	aCols			:= 	{}
	aHeader			:=	{}


	DbSelectArea("SX3")
	DbSetOrder(2)
	For iX := 1 To Len(aCpo)
		If DbSeek(aCpo[iX])
			Aadd(aHeader,{ AllTrim(X3Titulo()),;
			SX3->X3_CAMPO	,;
			SX3->X3_PICTURE,;
			SX3->X3_TAMANHO,;
			SX3->X3_DECIMAL,;
			Iif(aCpo[Ix] $ "DA1_PRCVEN" ,"AllwaysTrue()" ,"AllwaysFalse()")	,;
			SX3->X3_USADO	,;
			SX3->X3_TIPO	,;
			SX3->X3_F3 		,;
			SX3->X3_CONTEXT,;
			SX3->X3_CBOX	,;
			""}) //SX3->X3_RELACAO })
			nUsado++
			If nRefrBox == 1
				&("nPx"+Substr(SX3->X3_CAMPO,5,6)) := nUsado
			Endif
			If aCpo[Ix] == "DA1_DESCRI"
				cUsado	:= SX3->X3_USADO
			Endif

		Endif
	Next

	DbSelectArea("SX2")
	DbSetOrder(1)
	If DbSeek("DA1")
		AADD( aHeader, { "Alias WT","DA1_ALI_WT", "", 09, 0,, cUsado, "C", "DA1", "V"} )
		AADD( aHeader, { "Recno WT","DA1_REC_WT", "", 09, 0,, cUsado, "N", "DA1", "V"} )
	Endif

	DbSelectArea("DA1")
	DbSetOrder(1)
	// Se for chamado a partir da rotina de atualização do arquivo de importação
	If nRefrBox == 2 .And. cArqImp <> Nil .And. File(cArqImp)

		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",680,0 })

		cNomArq := CriaTrab(aCampos)

		If (Select("TRB") <> 0)
			dbSelectArea("TRB")
			dbCloseArea()
		Endif
		dbUseArea(.T.,,cNomArq,"TRB",nil,.F.)

		dbSelectArea("TRB")
		Append From (cArqImp) SDF

		ProcRegua(RecCount())

		DbSelectArea("TRB")
		DbGotop()
		While !Eof()

			IncProc()

			aArrDados	:= StrTokArr(TRB->LINHA+";",";")
			// Layout Esperado
			// CODTAB;CODPRO;PRCVEN;
			// T07;123456789012345;125,50;
			If Alltrim(aArrDados[1]) == "CODTAB" .And. Alltrim(aArrDados[2]) == "CODPRO" .And. Alltrim(aArrDados[3]) == "PRCVEN"
				lTabRows	:= .T.				
			ElseIf Alltrim(aArrDados[1]) == "CODPROD" 
				lTabCols	:= .T.
				For nZ := 2 To Len(aArrDados)
					Aadd(aTbRef,aArrDados[nZ])
				Next

			ElseIf lTabRows .And. Len(aArrDados) >= 3 //.And. Val(StrTran(StrTran(aArrDados[3],".",""),",",".")) > 0

				Aadd(aCols,Array(Len(aHeader)+1))

				aCols[Len(aCols),Len(aHeader)+1]	:= .F.

				nRecDA1		:= 0

				For nI := 1 To Len(aHeader)

					If IsHeadRec(aHeader[nI][2])
						aCols[Len(aCols)][nI] := nRecDA1
					ElseIf IsHeadAlias(aHeader[nI][2])
						aCols[Len(aCols)][nI] := "DA1"						
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_CODPRO"

						aCols[Len(aCols)][nI]				:= Padr(aArrDados[2],Len(DA1->DA1_CODPRO))

						DbSelectArea("SB1")
						DbSetOrder(1)
						If DbSeek(xFilial("SB1")+aArrDados[2])
							aCols[Len(aCols),Len(aHeader)+1]	:= .F.							
						Else
							aCols[Len(aCols),Len(aHeader)+1]	:= .T.
						Endif

					ElseIf Alltrim(aHeader[nI][2]) == "DA1_ITEM"
						aCols[Len(aCols)][nI] 	:= CriaVar(aHeader[nI][2],.T.)
						DbSelectArea("DA1")
						DA1->(DbSetOrder(1))
						If DbSeek(xFilial("DA1")+ Padr(AArrDados[1],Len(DA1->DA1_CODTAB)) + Padr(aArrDados[2],Len(DA1->DA1_CODPRO)) )
							cItem 		:= DA1->DA1_ITEM
							nRecDA1		:= DA1->(Recno())
						Else
							DA1->(dbSetOrder(3))
							DA1->(MsSeek(xFilial("DA1")+ Padr(AArrDados[1],Len(DA1->DA1_CODTAB))+"ZZZZ",.T.))
							dbSkip(-1)	  
							cItem := Soma1(DA1->DA1_ITEM)

							If aScan(aCols,{|x| Upper(Alltrim(x[nPosCod])) == Padr(AArrDados[1],Len(DA1->DA1_CODTAB)) })	>  0

								For nX := 1 to Len(aCols)                     
									If !aCols[nX][Len(aHeader)+1]
										If aCols[nX][nPosCod] == Padr(AArrDados[1],Len(DA1->DA1_CODTAB)) .And. Len(aCols) <> nX
											DA1->(dbSetORder(3))
											If !DA1->(MsSeek(xFilial("DA1")+Padr(AArrDados[1],Len(DA1->DA1_CODTAB))+aCols[nX][nPosItem],.T.))
												cItem := Soma1(cItem)
											Endif	
										Endif
									Endif		
								Next nX
							Endif
						Endif
						aCols[Len(aCols)][nI]	:= cItem

					ElseIf Alltrim(aHeader[nI][2]) == "DA1_CODTAB"
						aCols[Len(aCols)][nI] :=  Padr(AArrDados[1],Len(DA1->DA1_CODTAB))
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_PRCVEN"
						If At(",",aArrDados[3]) > 0
							aCols[Len(aCols)][nI] :=  Val(StrTran(StrTran(aArrDados[3],".",""),",","."))
						Else
							aCols[Len(aCols)][nI] :=  Val(aArrDados[3])
						Endif
						// se o preço for zerado deixa o item deletado
						If aCols[Len(aCols)][nI] <= 0
							aCols[Len(aCols),Len(aHeader)+1]	:= .T.
						Endif
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_DESCRI"
						aCols[Len(aCols)][nI]	:= SB1->B1_DESC
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_DATVIG"
						aCols[Len(aCols)][nI]	:= Iif(nRecDA1 > 0,DA1->DA1_DATVIG,dDataLanc)
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_FILIAL"
						aCols[Len(aCols)][nI]	:= xFilial("DA1")
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_DTALT"
						aCols[Len(aCols)][nI]	:= dDataBase
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_PRCANT"
						aCols[Len(aCols)][nI]	:= Iif(nRecDA1 > 0,DA1->DA1_PRCVEN,0)
					ElseIf Alltrim(aHeader[nI][2]) == "DA1_MOEDA"
						aCols[Len(aCols)][nI]	:= 1
					Else
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
					Endif
				Next
			ElseIf lTabCols //.And.  Val(StrTran(StrTran(aArrDados[2],".",""),",",".")) > 0

				For iCodTb	:= 1 To Len(aTbRef)

					nRecDA1		:= 0
					Aadd(aCols,Array(Len(aHeader)+1))

					aCols[Len(aCols),Len(aHeader)+1]	:= .F.

					For nI := 1 To Len(aHeader)

						If IsHeadRec(aHeader[nI][2])
							aCols[Len(aCols)][nI] := nRecDA1
						ElseIf IsHeadAlias(aHeader[nI][2])
							aCols[Len(aCols)][nI] := "DA1"		
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_CODPRO"

							aCols[Len(aCols)][nI]			:= Padr(aArrDados[1],Len(DA1->DA1_CODPRO))

							DbSelectArea("SB1")
							DbSetOrder(1)
							If DbSeek(xFilial("SB1")+aCols[Len(aCols)][nI])
								aCols[Len(aCols),Len(aHeader)+1]	:= .F.							
							Else
								aCols[Len(aCols),Len(aHeader)+1]	:= .T.
							Endif

						ElseIf Alltrim(aHeader[nI][2]) == "DA1_ITEM"
							aCols[Len(aCols)][nI] 	:= CriaVar(aHeader[nI][2],.T.)
							DbSelectArea("DA1")
							DbSetOrder(1)
							If DbSeek(xFilial("DA1")+ Padr(aTbRef[iCodTb],Len(DA1->DA1_CODTAB)) + Padr(aArrDados[1],Len(DA1->DA1_CODPRO)) )
								cItem 		:= DA1->DA1_ITEM
								nRecDA1		:= DA1->(Recno())
							Else
								DA1->(dbSetOrder(3))
								DA1->(MsSeek(xFilial("DA1")+ Padr(aTbRef[iCodTb],Len(DA1->DA1_CODTAB))+"ZZZZ",.T.))
								dbSkip(-1)	  
								cItem := Soma1(DA1->DA1_ITEM)

								If aScan(aCols,{|x| Upper(Alltrim(x[nPosCod])) == Padr(aTbRef[iCodTb],Len(DA1->DA1_CODTAB)) })	>  0

									For nX := 1 to Len(aCols)                     
										If !aCols[nX][Len(aHeader)+1]
											If aCols[nX][nPosCod] == Padr(aTbRef[iCodTb],Len(DA1->DA1_CODTAB)) .And. Len(aCols) <> nX
												DA1->(dbSetORder(3))
												If !DA1->(MsSeek(xFilial("DA1")+ Padr(aTbRef[iCodTb],Len(DA1->DA1_CODTAB))+ aCols[nX][nPosItem],.T.))
													cItem := Soma1(cItem)
												Endif	
											Endif
										Endif		
									Next nX
								Endif
							Endif
							aCols[Len(aCols)][nI]	:= cItem

						ElseIf Alltrim(aHeader[nI][2]) == "DA1_CODTAB"
							aCols[Len(aCols)][nI] :=  Padr(aTbRef[iCodTb],Len(DA1->DA1_CODTAB))
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_PRCVEN"
							If At(",",aArrDados[iCodTb+1]) > 0
								aCols[Len(aCols)][nI] :=  Val(StrTran(StrTran(aArrDados[iCodTb+1],".",""),",","."))
							Else
								aCols[Len(aCols)][nI] :=  Val(aArrDados[iCodTb+1]) // +1 por que a primeira coluna é o código
							Endif
							// se o preço for zerado deixa o item deletado
							If aCols[Len(aCols)][nI] <= 0
								aCols[Len(aCols),Len(aHeader)+1]	:= .T.
							Endif
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_DESCRI"
							aCols[Len(aCols)][nI]	:= SB1->B1_DESC
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_DATVIG"
							aCols[Len(aCols)][nI]	:= Iif(nRecDA1 > 0,DA1->DA1_DATVIG,dDataLanc)
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_FILIAL"
							aCols[Len(aCols)][nI]	:= xFilial("DA1")
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_DTALT"
							aCols[Len(aCols)][nI]	:= dDataBase
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_PRCANT"
							aCols[Len(aCols)][nI]	:= Iif(nRecDA1 > 0,DA1->DA1_PRCVEN,0)
						ElseIf Alltrim(aHeader[nI][2]) == "DA1_MOEDA"
							aCols[Len(aCols)][nI]	:= 1
						Else
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Endif
					Next
				Next	
			Endif
			DbSelectArea("TRB")
			DbSkip()
		Enddo

		TRB->(DbCloseArea())


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
			//aCols[Len(aCols)][nColuna] := CriaVar(aHeader[nColuna][2],.T.)

			If Alltrim(aHeader[nColuna][2]) == "DA1_ITEM"
				aCols[Len(aCols)][nColuna]	:= "0001"
			Endif

		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
		sfAtuRodp()
	Endif

Return




/*/{Protheus.doc} sfGrvDados
(Efetua gravação dos dados)
@type function
@author marce
@since 11/06/2016
@version 1.0
@param oInGet, objeto, (Descrição do parâmetro)
@param cInAlias, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrvDados(oInGet,cInAlias)

	Local	nLenCols	:= 0
	Local	nLenHead	:= 0
	Local	nX,nY

	// Cria valores dinânimcos
	// Número de linha do Getdados
	nLenCols	:= Len(oInGet:aCols)
	// Número de colunas do Getdados
	nLenHead	:= Len(oInGet:aHeader)
	Begin Transaction 	
		For nX := 1 To nLenCols
			DbSelectArea(cInAlias)
			//If !(oInGet:aCols[nX,Len(oInGet:aHeader)+1])

			// Procura se o registro já existe na tabela ou não	
			For nY := 1 To nLenHead
				If IsHeadRec(oInGet:aHeader[nY][2])
					If oInGet:aCols[nX,nY] > 0
						(cInAlias)->(MsGoto(oInGet:aCols[nX,nY]))
						RecLock(cInAlias,.F.)
					ElseIf !(oInGet:aCols[nX,Len(oInGet:aHeader)+1])
						RecLock(cInAlias,.T.)
					EndIf
					Exit
				Endif
			Next nY
			// Se for exclusão
			If (oInGet:aCols[nX,Len(oInGet:aHeader)+1] .And. oInGet:aCols[nX,nY] > 0)
				(cInAlias)->(dbDelete())
				MsUnlock()
			ElseIf !(oInGet:aCols[nX,Len(oInGet:aHeader)+1])
				For nY := 1 To nLenHead
					If oInGet:aHeader[nY][10] # "V"
						(cInAlias)->(FieldPut(FieldPos(oInGet:aHeader[nY][2]),oInGet:aCols[nX][nY]))
					EndIf
				Next nY
				DA1_INDLOT		:= "000000000999999.99"
				DA1_QTDLOT 		:= 999999.99
				MsUnlock()	
			Endif
			//Endif
		Next nX
	End Transaction 
	MsgInfo("Dados gravados com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

Return


/*/{Protheus.doc} sfAtuRodp
(Atualiza informações de rodapé)
@type function
@author Marcelo Alberto Lauschner
@since 13/06/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuRodp()

	Local	nQteReg		:= 0
	Local	nQteDel		:= 0
	Local	nQteDes		:= 0
	Local	nQteNew		:= 0
	Local	nQteUPd		:= 0
	Local	nColRec		:= 0
	Local	nY,nX
	
	nLenCols	:= Len(oMulti:aCols)
	// Número de colunas do Getdados
	nLenHead	:= Len(oMulti:aHeader)
	
	// Identifica a coluna com Recno 
	For nY := 1 To nLenHead
		If IsHeadRec(oMulti:aHeader[nY][2])
			nColRec	:= nY
		Endif
	Next nY

	For nX := 1 To nLenCols

		nQteReg++
		// Se for exclusão
		If (oMulti:aCols[nX,nLenHead+1] .And. oMulti:aCols[nX,nColRec] > 0)
			nQteDel++
			// Se for Alteração
		ElseIf !(oMulti:aCols[nX,nLenHead+1]) .And. oMulti:aCols[nX,nColRec] > 0
			nQteUPd++
			// Se for Inclusão
		ElseIf !(oMulti:aCols[nX,nLenHead+1])
			nQteNew++			
		Else	
			nQteDes++
		Endif
		
	Next nX

	MsgInfo("Total de Registros = " + cValToChar(nQteReg) + Chr(13)+Chr(10)+;
	"Total de Descartados = " + cValToChar(nQteDes) + Chr(13)+Chr(10)+;
	"Total de Exclusões = " + cValToChar(nQteDel) + Chr(13)+Chr(10)+;
	"Total de Alterações = " + cValToChar(nQteUPd) + Chr(13)+Chr(10)+;
	"Total de Inclusões = " + cValToChar(nQteNew) ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
Return

