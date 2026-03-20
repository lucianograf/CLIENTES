#include 'totvs.ch'

/*/{Protheus.doc} MLCOMM01
//TODO Gerar interface para listar valores para gerar nota de importação
@author Marcelo Alberto Lauschner
@since 07/04/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MLCOMM01()

	Private		cChave		:= ""


	Private 	oDlgImp
	Private 	cArqImp		:= Space(150)
	Private		aCols,aHeader
	Private 	aSize := MsAdvSize(,.F.,400)
	Private 	aButton		:= {{"VERDE"		,{|| MATA103()}  ,"Doc.Entrada"},{"VERDE"		,{|| MATA140()}  ,"PreNota"}}
	Private		cCodFor		:= Space(TamSX3("F1_FORNECE")[1])
	Private		cLojFor		:= Space(TamSX3("F1_LOJA")[1])
	Private		cNatFin		:= Space(TamSX3("E2_NATUREZ")[1])
	Private 	cCondicao	:= Space(TamSX3("F1_COND")[1])
	Private		aTotRdpe 	:= {{0,0,0,0},{0,0,0,0}}
	Private		oTotRdp		:= {,,}

	DEFINE MSDIALOG oDlgImp TITLE OemToAnsi("Importação Planilha para geração de Nota de Importação") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

	oDlgImp:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlgImp, oDlgImp:oFont, .T., .T.,, ,200,45,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlgImp, oDlgImp:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlgImp, oDlgImp:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM


	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	@ 012 ,005  	Say OemToAnsi("Fornecedor") SIZE 60,9 PIXEl OF oPanel1 FONT oFnt
	@ 011 ,073  	MSGET cCodFor  Picture PesqPict("SF1","F1_FORNECE") Valid (ExistCpo("SA2",cCodFor)) F3 "SA2" PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON

	@ 025 ,005  	Say OemToAnsi("Loja") SIZE 60,9 PIXEl OF oPanel1 FONT oFnt
	@ 024 ,073  	MSGET cLojFor  Picture PesqPict("SF1","F1_LOJA") Valid (ExistCpo("SA2",cCodFor+cLojFor)) PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON



	@ 012,180 Say OemToAnsi("Cond.Pagto") SIZE 60,9 PIXEl OF oPanel1 FONT oFnt
	@ 011,260 MsGet cCondicao F3 "SE4" Valid (Vazio() .Or. ExistCpo("SE4",cCondicao)) Size 30,10 Pixel of oDlgImp

	If GetMv("MV_NFENAT") 
		@ 025,180 Say "Informe a Natureza" Pixel of oDlgImp
		@ 024,260 MsGet cNatFin F3 "SED" Valid ExistCpo("SED",cNatFin) Size 60,10 Pixel of oDlgImp
	Endif

	@ 012 ,300   	Say OemToAnsi("Arquivo") SIZE 30,9 PIXEl	OF oPanel1 FONT oFnt
	@ 011 ,330		MSGET oArqIMp VAR cArqImp Picture "@!" PIXEl SIZE 132, 10 OF oPanel1 Valid (cArqImp := cGetFile( "Arquivos CSV(*.csv) | *.csv", "Selecione o Arquivo",,"C:\EDI\",.T., ),Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados..."))



	Processa({|| sfCarrega(@aCols,@aHeader,1) },"Localizando registros...")

	Private oMulti := MsNewGetDados():New(034, 005, 226, 415,GD_INSERT+GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"+D1_ITEM",;
		,0/*nFreeze*/,10000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,;
		/*cApagaOk*/,oPanel2,@aHeader,@aCols,{|| sfAtuRodp() })

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	@ 011 ,008  SAY OemToAnsi("+(A) Valor Produtos :") Of oPanel3 PIXEL	FONT oFnt
	@ 010 ,065 	MSGET oTotRdp[1] 	VAR aTotRdpe[1][1]	Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL

	@ 011 ,190 	SAY OemToAnsi("+(B)  R$ Despesa  :") Of oPanel3 PIXEL	FONT oFnt
	@ 010 ,240	MSGET oTotRdp[2] 	VAR aTotRdPe[1][2]	Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL

	@ 041 ,190	SAY OemToAnsi("=(A+B) R$ Total :") Of oPanel3 PIXEL FONT oFnt
	@ 040 ,240	MSGET oTotRdp[3] VAR aTotRdPe[1][3] Picture "@E 999,999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL


	ACTIVATE MSDIALOG oDlgImp ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlgImp,{|| Processa({||sfGrvDados()},"Efetuando gravações...") , oDlgImp:End() },{|| oDlgImp:End()},,aButton))

Return

/*/{Protheus.doc} sfCarrega
Efetua a montagem do aCols
@type function
@version
@author Marcelo Alberto Lauschner
@since 06/05/2020
@param aCols, array, param_description
@param aHeader, array, param_description
@param nRefrBox, numeric, param_description
@return return_type, return_description
/*/
Static Function sfCarrega(aCols,aHeader,nRefrBox)

	Local	nUsado		:=  0
	Local	aCpo		:=  { "D1_ITEM","D1_COD","D1_DESCR","D1_QUANT","D1_LOCAL","D1_VUNIT","D1_TOTAL","D1_VALDESC","D1_TES","D1_SEGURO","D1_DESPESA","D1_VALFRE","D1_ALIQII",;
		"D1_II","D1_BASEIPI","D1_IPI","D1_VALIPI","D1_BASEICM","D1_PICM",;
		"D1_VALICM","D1_BASIMP6","D1_ALQIMP6","D1_VALIMP6","D1_BASIMP5","D1_ALQIMP5","D1_VALIMP5","D1_CLASFIS",;
		"CD5_NDI","CD5_DTDI","CD5_LOCDES","CD5_UFDES","CD5_DTDES","CD5_DOCIMP",;
		"CD5_NADIC","CD5_SQADIC","CD5_TPIMP","CD5_LOCAL","CD5_VTRANS","CD5_INTERM","CD5_BSPIS","CD5_ALPIS","CD5_VLPIS","CD5_BSCOF",;
		"CD5_ALCOF","CD5_VLCOF","CD5_DTPCOF","CD5_DTPPIS","CD5_CODEXP","CD5_LOJEXP","CD5_CODFAB","CD5_LOJFAB","CD5_BCIMP","CD5_DSPAD","CD5_VDESDI","CD5_VLRII",;
		"CD5_VAFRMM","CD5_VLRIOF","CD5_CNPJAE","CD5_UFTERC"}
	Local	aCpoAux			:= {}
	Local	aColsAdd		:= {}
	Local	cUsado			:= ""
	Local	iX,nI,nColuna,nY,nR
	Local	aArrDados		:= {}
	Local	aCabDados		:= {}
	Local	cItem			:= "0000"
	Local 	nZ
	aCols			:= 	{}
	aHeader			:=	{}

	Aadd(aCpoAux,{"D1_TOTAL"  ,"CD5_BCIMP"})
	Aadd(aCpoAux,{"D1_DESPESA","CD5_DSPAD"})
	Aadd(aCpoAux,{"D1_BASIMP6","CD5_BSPIS"})
	Aadd(aCpoAux,{"D1_ALQIMP6","CD5_ALPIS"})
	Aadd(aCpoAux,{"D1_VALIMP6","CD5_VLPIS"})
	Aadd(aCpoAux,{"D1_BASIMP5","CD5_BSCOF"})
	Aadd(aCpoAux,{"D1_ALQIMP5","CD5_ALCOF"})
	Aadd(aCpoAux,{"D1_VALIMP5","CD5_VLCOF"})
	Aadd(aCpoAux,{"D1_II"  	  ,"CD5_VLRII"})
	Aadd(aCpoAux,{"CD5_DTDI"  ,"CD5_DTPCOF"})
	Aadd(aCpoAux,{"CD5_DTDI"  ,"CD5_DTPPIS"})


	DbSelectArea("SX3")
	DbSetOrder(2)
	For iX := 1 To Len(aCpo)
		If DbSeek(aCpo[iX])

			Aadd(aHeader,{ AllTrim(GetSx3Cache(aCpo[iX], 'X3_TITULO')),;
				GetSx3Cache(aCpo[iX], 'X3_CAMPO'),;
				GetSx3Cache(aCpo[iX], 'X3_PICTURE'),;
				GetSx3Cache(aCpo[iX], 'X3_TAMANHO'),;
				GetSx3Cache(aCpo[iX], 'X3_DECIMAL'),;
				"AllwaysTrue()"	,;
				GetSx3Cache(aCpo[iX], 'X3_USADO'),;
				GetSx3Cache(aCpo[iX], 'X3_TIPO'),;
				GetSx3Cache(aCpo[iX], 'X3_F3'),;
				GetSx3Cache(aCpo[iX], 'X3_CONTEXT'),;
				Iif(Substr(GetSx3Cache(aCpo[iX], 'X3_CBOX'),1,1) == "#",&(Substr(GetSx3Cache(aCpo[iX], 'X3_CBOX'),2)),GetSx3Cache(aCpo[iX], 'X3_CBOX')) 	,;
				""})
			nUsado++
			If aCpo[iX] == "D1_COD"
				cUsado	:= GetSx3Cache(aCpo[iX], 'X3_USADO')
			Endif
			&("n"+StrTran(GetSx3Cache(aCpo[iX], 'X3_CAMPO'),"_",""))	:= nUsado
		Endif
	Next



	If nRefrBox == 2 .And. cArqImp <> Nil .And. File(cArqImp)

		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",1024,0 })

		If(Type('oTmpTRB') <> 'U')
			oTmpTRB:Delete()
			FreeObj(oTmpTRB)
		EndIf
		cNomArq := "TRB"

		If (Select("TRB") <> 0)
			dbSelectArea("TRB")
			TRB->(dbCloseArea())
		Endif
		
		oTmpTRB := FWTemporaryTable():New(cNomArq,aCampos)
		oTmpTRB:Create()

		dbSelectArea("TRB")
		Append From (cArqImp) SDF

		ProcRegua(RecCount())

		DbSelectArea("TRB")
		DbGotop()
		While !Eof()

			IncProc()
			cLinhaTrb	:= TRB->LINHA
			cLinhaTrb	:= StrTran(cLinhaTrb,'"',"")
			cLinhaTrb	:= StrTran(cLinhaTrb,";;","; ;")
			cLinhaTrb	:= StrTran(cLinhaTrb,";;","; ;")
			cLinhaTrb	:= StrTran(cLinhaTrb,";;","; ;")
			cLinhaTrb	:= StrTran(cLinhaTrb,";;","; ;")
			cLinhaTrb	:= StrTran(cLinhaTrb,";;","; ;")
			cLinhaTrb	+= ";"
			aArrDados	:= StrTokArr(cLinhaTrb,";")
			If Alltrim(aArrDados[1]) == "D1_COD"
				aCabDados	:= aClone(aArrDados)
			ElseIf Len(aArrDados) > 0 .And. !Empty(aArrDados[1]) .And. !Empty(aArrDados[2]) .And. Len(aArrDados) >= Len(aCabDados)
				aColsAdd	:= {}
				Aadd(aCols,Array(Len(aHeader)+1))

				aCols[Len(aCols),Len(aHeader)+1]	:= .F.

				For nI := 1 To Len(aHeader)

					If Alltrim(aHeader[nI][2]) == "D1_ITEM"
						cItem	:= Soma1(cItem)
						aCols[Len(aCols)][nI]				:= cItem
						Aadd(aColsAdd,nI)
					ElseIf Alltrim(aHeader[nI][2]) $ "CD5_CODEXP#CD5_CODFAB"
						aCols[Len(aCols)][nI]				:= cCodFor
						// Adiciona o número da coluna
						Aadd(aColsAdd,nI)
					ElseIf Alltrim(aHeader[nI][2]) $ "CD5_LOJEXP#CD5_LOJFAB"
						aCols[Len(aCols)][nI]				:= cLojFor
						// Adiciona o número da coluna
						Aadd(aColsAdd,nI)
					Endif

					For nZ := 1 To Len(aCabDados)
					
						If Alltrim(aHeader[nI][2]) == Alltrim(aCabDados[nZ])
							If Alltrim(aHeader[nI][2]) == "D1_COD"
								aCols[Len(aCols)][nI]				:= Padr(aArrDados[nZ],TamSX3("D1_COD")[1])
								// Adiciona o número da coluna
								Aadd(aColsAdd,nI)

								DbSelectArea("SB1")
								DbSetOrder(1)
								If DbSeek(xFilial("SB1")+aCols[Len(aCols)][nI])
									aCols[Len(aCols),Len(aHeader)+1]	:= .F.
								Else
									aCols[Len(aCols),Len(aHeader)+1]	:= .T.
								Endif
							ElseIf Alltrim(aHeader[nI][8]) == "N"
								aCols[Len(aCols)][nI] 	:= Val(StrTran(StrTran(aArrDados[nZ],".",""),",","."))
								// Adiciona o número da coluna
								Aadd(aColsAdd,nI)
							ElseIf Alltrim(aHeader[nI][8]) == "D"
								aCols[Len(aCols)][nI] 	:= CTOD(aArrDados[nZ])
								// Adiciona o número da coluna
								Aadd(aColsAdd,nI)
							ElseIf Alltrim(aHeader[nI][8]) == "C"
								aCols[Len(aCols)][nI] 	:= Padr(aArrDados[nZ],aHeader[nI][4])
								// Adiciona o número da coluna
								Aadd(aColsAdd,nI)
							Else
								aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
								// Adiciona o número da coluna
								Aadd(aColsAdd,nI)
							Endif

							For nY := 1 To Len(aCpoAux)
								If Alltrim(aCpoAux[nY,1]) == Alltrim(aHeader[nI][2]) //	:= {{"D1_DESPESA","CD5_DSPAD"},{"D1_BASIMP6","CD5_BSPIS"}})
									For nR := 1 To Len(aHeader)
										If Alltrim(aHeader[nR][2]) == Alltrim(aCpoAux[nY,2])
											If Alltrim(aHeader[nR][8]) == "N"
												aCols[Len(aCols)][nR] 	:= Val(StrTran(StrTran(aArrDados[nZ],".",""),",","."))
												// Adiciona o número da coluna
												Aadd(aColsAdd,nR)
											ElseIf Alltrim(aHeader[nR][8]) == "D"
												aCols[Len(aCols)][nR] 	:= CTOD(aArrDados[nZ])
												// Adiciona o número da coluna
												Aadd(aColsAdd,nR)
											ElseIf Alltrim(aHeader[nR][8]) == "C"
												aCols[Len(aCols)][nR] 	:= Padr(aArrDados[nZ],aHeader[nR][4])
												// Adiciona o número da coluna
												Aadd(aColsAdd,nR)
											Else
												aCols[Len(aCols)][nR] := CriaVar(aHeader[nR][2],.T.)
												// Adiciona o número da coluna
												Aadd(aColsAdd,nR)
											Endif
										Endif
									Next
								Endif
							Next nY
						Endif
					Next
				Next

				// Percorre as colunas para ver o que foi atualizado ou não
				For nI := 1 To Len(aHeader)
					nR := aScan(aColsAdd,{|x| x == nI})
					If nR == 0
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
					Endif
				Next nI

			Endif
			DbSelectArea("TRB")
			DbSkip()
		Enddo

		TRB->(DbCloseArea())
		
		If(Type('oTmpTRB') <> 'U')
			oTmpTRB:Delete()
			FreeObj(oTmpTRB)
		EndIf
		
	Endif

	If Len(aCols) == 0
		AADD(aCols,Array(Len(aHeader)+1))
		For nColuna := 1 to Len( aHeader )
			
			If Alltrim(aHeader[nColuna][2]) == "D1_ITEM"
				cItem	:= Soma1(cItem)
				aCols[Len(aCols)][nColuna]	:= cItem
			ElseIf aHeader[nColuna][8] == "C"
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


		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
		sfAtuRodp()
	Endif

Return

/*/{Protheus.doc} sfAtuRodp
Atualização informações no rodapé da Tela.
@type function
@version
@author Marcelo Alberto Lauschner
@since 06/05/2020
@return return_type, return_description
/*/
Static Function sfAtuRodp()

	Local nX

	aTotRdpe 	:= {{0,0,0,0},{0,0,0,0}}


	For nX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[nX,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[nX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_COD" })])
			aTotRdPe[1,1]	+= oMulti:aCols[nX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_TOTAL" })]
			aTotRdPe[1,2]	+= oMulti:aCols[nX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_DESPESA" })]
			// Soma total
			aTotRdPe[1,3]	+= oMulti:aCols[nX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_TOTAL" })]
			aTotRdPe[1,3]	+= oMulti:aCols[nX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_DESPESA" })]
			aTotRdPe[1,3]	+= oMulti:aCols[nX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_VALFRE" })]

		Endif
	Next

	oTotRdp[1]:Refresh()
	oTotRdp[2]:Refresh()
	oTotRdp[3]:Refresh()

Return
/*/{Protheus.doc} sfGrvDados
Efetua a gravação dos dados da Nota Fiscal.
@type function
@version
@author Marcelo Alberto Lauschner
@since 06/05/2020
@return return_type, return_description
/*/
Static Function sfGrvDados

	Local		aCabec		:= {}
	Local		aLinha		:= {}
	Local		aItems		:= {}
	Local 		nForG

	// Alimenta variável com o valor do tipo
	cTipo	:= "N"
	DbSelectArea("SA2")
	DbSetOrder(1)
	DbSeek(xFilial("SA2")+cCodFor+cLojFor)

	Aadd(aCabec,{"F1_TIPO"   	,cTipo									,Nil,Nil})

	Aadd(aCabec,{"F1_FORMUL" 	,"S"									,Nil,Nil})
	Aadd(aCabec,{"F1_DOC"    	,Space(TamSX3("F1_DOC")[1])				,Nil,Nil})
	Aadd(aCabec,{"F1_SERIE"     ,Space(TamSX3("F1_SERIE")[1])	 		,Nil,Nil})
	Aadd(aCabec,{"F1_EMISSAO"	,dDataBase								,Nil,Nil})
	Aadd(aCabec,{"F1_FORNECE"	,cCodFor								,Nil,Nil})
	Aadd(aCabec,{"F1_LOJA"   	,cLojFor								,Nil,Nil})

	Aadd(aCabec,{"F1_ESPECIE"	,Padr("SPED",TamSX3("F1_ESPECIE")[1])	,Nil,Nil})
	Aadd(aCabec,{"F1_EST"		,SA2->A2_EST							,Nil,Nil})
	Aadd(aCabec,{"F1_COND"		,cCondicao		    					,Nil,Nil})
	Aadd(aCabec,{"E2_NATUREZ"   ,cNatFin								,NIL,NIL})

	// Inicio loop nos itens da nota
	For nForG := 1 To Len(oMulti:aCols)
		nIX := nForG
		If !oMulti:aCols[nIX,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_COD" })])
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_COD" })])

			aLinha := {}

			Aadd(aLinha,{"D1_FILIAL"	, xFilial("SD1")						,Nil,Nil})
			Aadd(aLinha,{"D1_ITEM"		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_ITEM" })]				,Nil,Nil})
			Aadd(aLinha,{"D1_COD"		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_COD" })]				,Nil,Nil})

			Aadd(aLinha,{"D1_QUANT"		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_QUANT" })]			,Nil,Nil})

			Aadd(aLinha,{"D1_VUNIT"		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_VUNIT" })]			,Nil,Nil})

			Aadd(aLinha,{"D1_TOTAL"  	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_TOTAL" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_TES"		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_TES" })]				,Nil,Nil})

			Aadd(aLinha,{"D1_LOCAL"		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_LOCAL" })]			,Nil,Nil})

			Aadd(aLinha,{"D1_SEGURO"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_SEGURO" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_DESPESA"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_DESPESA" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_VALFRE"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_VALFRE" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_ALIQII" 	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_ALIQII" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_II"  		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_II" })]				,Nil,Nil})
			Aadd(aLinha,{"D1_BASEIPI"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_BASEIPI" })	]		,Nil,Nil})
			Aadd(aLinha,{"D1_IPI"		, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_IPI" })]				,Nil,Nil})
			Aadd(aLinha,{"D1_VALIPI"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_VALIPI" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_BASEICM"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_BASEICM" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_PICM"	 	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_PICM" })]				,Nil,Nil})
			Aadd(aLinha,{"D1_VALICM" 	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_VALICM" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_BASIMP6"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_BASIMP6" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_ALQIMP6"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_ALQIMP6" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_VALIMP6"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_VALIMP6" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_BASIMP5"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_BASIMP5" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_ALQIMP5"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_ALQIMP5" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_VALIMP5"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_VALIMP5" })]			,Nil,Nil})
			Aadd(aLinha,{"D1_CLASFIS"	, oMulti:aCols[nIX,aScan(oMulti:aHeader,{|x| Alltrim(x[2]) == "D1_CLASFIS" })]			,Nil,Nil})

			Aadd(aItems,aLinha)
		Endif
	Next

	Mata103(aClone(aCabec), aClone(aItems) , 3 , .T.)


Return
