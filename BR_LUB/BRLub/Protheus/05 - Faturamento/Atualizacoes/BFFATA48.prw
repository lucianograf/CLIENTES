#Include 'Protheus.ch'
#INCLUDE "TopConn.ch"

/*/{Protheus.doc} BFFATA48
(Rotina permite geracao do frete por cidade atraves do modelo2, assim facilitando sua inclusao e edicao)
@author informatica4
@since 18/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA48()

	Private cCadastro := "Tabela de Preços de Frete Transportadoras X Cidades"
	Private aRotina := {}


	aRotina := {{ OemToAnsi("Pesquisa") ,"AxPesqui", 0 , 1},;
		{ OemToAnsi("Incluir") ,"U_FATA48A(3)", 0 , 3},;
		{ OemToAnsi("Altera"),"U_FATA48A(4)", 0 , 4 },;
		{ OemToAnsi("Copiar"),"U_FATA48A(5)", 0 , 4 }}

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	dbSelectArea("SZK")
	dbGotop()
	mBrowse( 6,1,22,75,"SZK",,,,,,)

Return


/*/{Protheus.doc} FATA48A
(Monta tela e carrega os dados)
@author informatica4
@since 21/08/2015
@version 1.0
@param nOpc, numérico, (2=Visualizar,3=Incluir,4=Alterar,5=Copiar)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FATA48A(nOpc)

	Local	nI,nX,nY
	Local	aArea := GetArea()
	Local	cUsado

	// Cabecalho
	aC := {}
	Aadd(aC,{"cTab",{25,10},"Cod.Tab.","@!",,,.F.})
	Aadd(aC,{"cNomeTab",{25,70},"Nome Tab.","@!",,,.T.})
	// Inclusao
	If nOpc = 3
		dDataIni := dDataBase
		dDataFim := dDataBase
		cTransp  := Space(Len(CriaVar("ZK_TRANSP")))
		cNomeTab := Space(Len(CriaVar("ZK_NOMETB")))
		cTab 	 := GetMv("BF_FATA48N")
		PutMv("BF_FATA48N",Soma1(GetMv("BF_FATA48N")))
		Aadd(aC,{"cTransp",{25,250},"Transp.","@!",,"SA4",.T.})
		// Alteracao
	ElseIf nOpc == 4
		dDataIni := SZK->ZK_DTINI
		dDataFim := SZK->ZK_DTFIM
		cTransp  := SZK->ZK_TRANSP
		cNomeTab := SZK->ZK_NOMETB
		cTab 	 := SZK->ZK_TABELA
		cTabBkp  := SZK->ZK_TABELA
		Aadd(aC,{"cTransp",{25,250},"Transp.","@!",,"SA4",.F.})
		// Copia
	Else
		dDataIni := dDataBase
		dDataFim := dDataBase
		cTransp  := SZK->ZK_TRANSP
		cNomeTab := SZK->ZK_NOMETB
		cTab 	 := GetMv("BF_FATA48N")
		PutMv("BF_FATA48N",Soma1(GetMv("BF_FATA48N")))
		cTabBkp  := SZK->ZK_TABELA
		Aadd(aC,{"cTransp",{25,250},"Transp.","@!",,"SA4",.T.})
	EndIf
	Aadd(aC,{"dDataIni",{25,330},"Data Inicio",,,,.T.})
	Aadd(aC,{"dDataFim",{25,410},"Data Fim",,,,.T.})

	// Rodape
	aR:={}

	// Botoes
	aButton := {{"REPLICAR", {||sfReplicar()}, "Replicar...", "Replicar" , {|| .T.}}}

	// Validacoes
	cLinhaOk := ".T."
	cTudoOk := ".T."

	// Monta aHeader
	aHeader := {}
	aFields := {}

	//dbSelectArea("SX3")
	//dbSetOrder(1)
	//If DbSeek("SZK")

	aFields := FWSX3Util():GetAllFields("SZK", .T. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		//While !Eof() .And. SX3->X3_ARQUIVO == "SZK"
		If !(Alltrim(cCampo) $ "ZK_FILIAL#ZK_TRANSP#ZK_TABELA#ZK_NOMETB#ZK_DTINI#ZK_DTFIM#ZK_NOMETR")
			Aadd(aHeader,{ GetSx3Cache(cCampo,"X3_TITULO") ,;
				GetSx3Cache(cCampo,"X3_CAMPO")	,;
				GetSx3Cache(cCampo,"X3_PICTURE") ,;
				GetSx3Cache(cCampo,"X3_TAMANHO") ,;
				GetSx3Cache(cCampo,"X3_DECIMAL") ,;
				GetSx3Cache(cCampo,"X3_VALID")	,;
				GetSx3Cache(cCampo,"X3_USADO")	,;
				GetSx3Cache(cCampo,"X3_TIPO")	,;
				GetSx3Cache(cCampo,"X3_F3") 		,;
				GetSx3Cache(cCampo,"X3_CONTEXT") ,;
				GetSx3Cache(cCampo,"X3_CBOX")	,;
				GetSx3Cache(cCampo,"X3_RELACAO")	,;
				GetSx3Cache(cCampo,"X3_WHEN")	,;
				GetSx3Cache(cCampo,"X3_VISUAL")	,;
				GetSx3Cache(cCampo,"X3_VLDUSER")	,;
				GetSx3Cache(cCampo,"X3_PICTVAR")	,;
				IIf(!Empty(GetSx3Cache(cCampo,"X3_OBRIGAT")),.T.,.F.)})
		Endif
		If GetSx3Cache(cCampo,"X3_CAMPO") == "ZK_NOMMUN"
			cUsado	:= GetSx3Cache(cCampo,"X3_USADO")
		Endif

	Next nX

	//Endif

	AADD( aHeader, { "Alias WT","SZK_ALI_WT", "", 09, 0,, cUsado, "C", "SZK", "V"} )
	AADD( aHeader, { "Recno WT","SZK_REC_WT", "", 09, 0,, cUsado, "N", "SZK", "V"} )

	// Monta aCols
	aCols := {}
	// Inclusao cria acols com todas cidades do estado selecionado
	If nOpc == 3
		aRet := {}
		aPergs := {{1,"Estado",Space(2),"@!",'.T.',,'.T.',40,.F.}}
		If ParamBox(aPergs ,"Parametros",aRet)
			dbSelectArea("CC2")
			CC2->(dbGoTop())
			While CC2->(!EOF())
				If aRet[1] == CC2->CC2_EST
					// Cria linha
					Aadd(aCols,Array(Len(aHeader)+1))
					aCols[Len(aCols)][Len(aHeader)+1] := .F.

					// Preenche ela vazia
					For nI := 1 To Len(aHeader)
						If IsHeadRec(aHeader[nI][2])
							aCols[Len(aCols)][nI] := 0
						ElseIf IsHeadAlias(aHeader[nI][2])
							aCols[Len(aCols)][nI] := "SZK"
						Else
							aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
						Endif
					Next nI

					// Preenche conteudos somente em algumas colunas
					For nI := 1 To Len(aHeader)
						If Alltrim(aHeader[nI][2]) == "ZK_EST"
							aCols[Len(aCols)][nI]	:= CC2->CC2_EST
						ElseIf Alltrim(aHeader[nI][2]) == "ZK_CODMUN"
							aCols[Len(aCols)][nI]	:= CC2->CC2_CODMUN
						ElseIf Alltrim(aHeader[nI][2]) == "ZK_NOMMUN"
							aCols[Len(aCols)][nI]	:= CC2->CC2_MUN
						EndIf
					Next
				EndIf
				CC2->(dbSkip())
			End
		Else
			Return
		EndIf
		//Alteracao e Visualizacao, cria acols com todos os registros da tabela selecionada
	ElseIf nOpc == 4
		dbSelectArea("SZK")
		SZK->(dbGoTop())
		While SZK->(!EOF())
			If SZK->ZK_TABELA == cTabBkp .AND. SZK->ZK_FILIAL == xFilial("SZK")
				// Cria linha
				Aadd(aCols,Array(Len(aHeader)+1))
				aCols[Len(aCols)][Len(aHeader)+1] := .F.
				For nI := 1 To Len(aHeader)
					If IsHeadRec(aHeader[nI][2])
						aCols[Len(aCols)][nI] := SZK->(Recno())
					ElseIf IsHeadAlias(aHeader[nI][2])
						aCols[Len(aCols)][nI] := "SZK"
					ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
						aCols[Len(aCols)][nI] := FieldGet(FieldPos(aHeader[nI][2]))
					Else
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
					Endif

					If Alltrim(aHeader[nI][2]) == "ZK_NOMMUN"
						aCols[Len(aCols)][nI]	:= Posicione("CC2",1,xFilial("CC2")+SZK->ZK_EST+SZK->ZK_CODMUN,"CC2_MUN")
					EndIf
				Next
			EndIf
			SZK->(dbSkip())
		End

		RestArea(aArea)
		//Copy
	Else
		nOpc	:= 4
		dbSelectArea("SZK")
		SZK->(dbGoTop())
		While SZK->(!EOF())
			If SZK->ZK_TABELA == cTabBkp .AND. SZK->ZK_FILIAL == xFilial("SZK")
				// Cria linha
				Aadd(aCols,Array(Len(aHeader)+1))
				aCols[Len(aCols)][Len(aHeader)+1] := .F.
				// Preenche array vazio
				For nI := 1 To Len(aHeader)
					If IsHeadRec(aHeader[nI][2])
						aCols[Len(aCols)][nI] := 0
					ElseIf IsHeadAlias(aHeader[nI][2])
						aCols[Len(aCols)][nI] := "SZK"
					ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
						aCols[Len(aCols)][nI] := FieldGet(FieldPos(aHeader[nI][2]))
					Else
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
					Endif
					If Alltrim(aHeader[nI][2]) == "ZK_NOMMUN"
						aCols[Len(aCols)][nI]	:= Posicione("CC2",1,xFilial("CC2")+SZK->ZK_EST+SZK->ZK_CODMUN,"CC2_MUN")
					EndIf
				Next nI

			EndIf
			SZK->(dbSkip())
		End

		RestArea(aArea)
	EndIf

	lRetMod2 := Modelo2("Frete",aC,aR,{120,0,20,30},nOpc,cLinhaOk,cTudoOk,,,,,,.T.,.T.,aButton)

	//Confirmou
	If lRetMod2

		If dDataFim < dDataIni
			MsgAlert("Data Fim não pode ser menor que Data Inicio. Favor ajustar.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		EndIf

		If !sfValDate(cTransp,dDataIni,cTab)
			MsgAlert("Existe uma tabela com vigência supeior a data inicio. Favor verificar.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		EndIf


		If nOpc != 2 .AND. MsgYesNo("Confirma a "+Iif(nOpc == 3,"inclusão","cópia/alteração")+" dos registros?")


			// Número de linha do Getdados
			nLenCols	:= Len(aCols)
			// Número de colunas do Getdados
			nLenHead	:= Len(aHeader)
			// Alias do Getdados
			cAliasNz	:= "SZK"

			For nX := 1 To nLenCols
				DbSelectArea(cAliasNz)
				// Procura se o registro já existe na tabela ou não
				For nY := 1 To nLenHead
					If IsHeadRec(aHeader[nY][2])
						If aCols[nX,nY] > 0
							(cAliasNz)->(MsGoto(aCols[nX,nY]))
							RecLock(cAliasNz,.F.)
						ElseIf !(aCols[nX,nLenHead+1])
							RecLock(cAliasNz,.T.)
						EndIf
						Exit
					Endif
				Next nY

				// Se for exclusão
				If (aCols[nX,nLenHead+1] .And. aCols[nX,nY] > 0)
				(cAliasNz)->(dbDelete())
				MsUnlock()
				ElseIf !(aCols[nX,nLenHead+1])
				&(cAliasNz+"->ZK_FILIAL")	:= xFilial(cAliasNz)
				&(cAliasNz+"->ZK_TRANSP")	:= cTransp 
				&(cAliasNz+"->ZK_TABELA")	:= cTab
				&(cAliasNz+"->ZK_NOMETB")	:= cNomeTab
				&(cAliasNz+"->ZK_DTINI")	:= dDataIni
				&(cAliasNz+"->ZK_DTFIM")	:= dDataFim

				For nY := 1 To nLenHead
					If aHeader[nY][10] # "V"
						(cAliasNz)->(FieldPut(FieldPos(aHeader[nY][2]),aCols[nX][nY]))
					EndIf
				Next nY
				MsUnlock()
			Endif
			Next nX
		Endif
	EndIf
Return


/*/{Protheus.doc} sfReplicar
(Replica todas as informações da primeira linha.)
@author informatica4
@since 21/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfReplicar()

	Local	nU

	If MsgYesNo("Deseja replicar todos os campos?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		nFrPeso 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_FRPESO"})
		nPeso 		:= 0
		nFrVal 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_FRVALOR"})
		nVal 		:= 0
		nGris 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_GRIS"})
		nGri 		:= 0
		nTaxa 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_TAXA"})
		nTax 		:= 0
		nTxExtra 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_TXEXTRA"})
		nTxExt 		:= 0
		nFrMin 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_FRMIN"})
		nMin 		:= 0
		nPedagio	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_PEDAG"})
		nPedag 		:= 0
		nIcmIncl	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_ICMINCL"})
		nIcm		:= 0
		nValCo 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_VALCOBR"})
		nCob 		:= 0
		nMinTon 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_MINTON"})
		nTon 		:= 0

		For nU := 1 To Len(aCols)
			If !aCols[nU][Len(aHeader)+1]
				If nU == 1
					nPeso 	 := aCols[nU][nFrPeso]
					nVal 	 := aCols[nU][nFrVal]
					nGri 	 := aCols[nU][nGris]
					nTax 	 := aCols[nU][nTaxa]
					nTxExt	 := aCols[nU][nTxExtra]
					nMin 	 := aCols[nU][nFrMin]
					nPedag	 := aCols[nU][nPedagio]
					nIcm 	 := aCols[nU][nIcmIncl]
					nCob 	 := aCols[nU][nValCo]
					nTon 	 := aCols[nU][nMinTon]
				Else
					aCols[nU][nFrPeso] 	:= nPeso
					aCols[nU][nFrVal] 	:= nVal
					aCols[nU][nGris] 	:= nGri
					aCols[nU][nTaxa] 	:= nTax
					aCols[nU][nTxExtra] := nTxExt
					aCols[nU][nFrMin] 	:= nMin
					aCols[nU][nPedagio] := nPedag
					aCols[nU][nIcmIncl] := nIcm
					aCols[nU][nValCo] 	:= nCob
					aCols[nU][nMinTon] 	:= nTon
				EndIf
			EndIf
		Next


	EndIf

Return


User Function BFATA48B()

	Local nPosCel
	Local nVlrAux
	Local nU
	Local lRet 		:= .T.

	If MsgYesNo("Deseja replicar apenas a coluna atual '" + ReadVar() + "' ?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

		If ReadVar() == "M->ZK_FRPESO"
			nPosCel 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_FRPESO"})
			nVlrAux			:= M->ZK_FRPESO
		ElseIf ReadVar() == "M->ZK_FRVALOR"
			nPosCel 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_FRVALOR"})
			nVlrAux 		:= M->ZK_FRVALOR
		ElseIf ReadVar() == "M->ZK_GRIS"
			nPosCel 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_GRIS"})
			nVlrAux 		:= M->ZK_GRIS
		ElseIf ReadVar() == "M->ZK_TAXA"
			nPosCel 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_TAXA"})
			nVlrAux 		:= M->ZK_TAXA
		ElseIf ReadVar() == "M->ZK_TXEXTRA"
			nPosCel 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_TXEXTRA"})
			nVlrAux 		:= M->ZK_TXEXTRA
		ElseIf ReadVar() == "M->ZK_FRMIN"
			nPosCel 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_FRMIN"})
			nVlrAux 		:= M->ZK_FRMIN
		ElseIf ReadVar() == "M->ZK_PEDAG"
			nPosCel	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_PEDAG"})
			nVlrAux 		:= M->ZK_PEDAG
		ElseIf ReadVar() == "M->ZK_VALCOBR"
			nPosCel 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_VALCOBR"})
			nVlrAux 		:= M->ZK_VALCOBR
		ElseIf ReadVar() == "M->ZK_MINTON"
			nPosCel 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZK_MINTON"})
			nVlrAux 		:= M->ZK_MINTON
		Endif
		If nPosCel > 0
			For nU := n To Len(aCols)
				If !aCols[nU][Len(aHeader)+1]
					If nU == 1
						//nVlrAux 	 := aCols[nU][nPosCel]
					Else
						aCols[nU][nPosCel] 	:= nVlrAux
					EndIf
				EndIf
			Next
		Endif
	Endif

Return lRet

/*/{Protheus.doc} sfValDate
(Valida se a data de fim de outra tabela, está concorrente com cadastrada)
@author informatica4
@since 24/08/2015
@version 1.0
@param cTransp, character, (Descrição do parâmetro)
@param cTab, character, (Descrição do parâmetro)
@param dDate, data, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfValDate(cTransp,dDate,cTab)

	Local lRet := .T.
	Default cTransp := "      "
	Default cTab := "   "

	cQry := ""
	cQry += "SELECT MAX(ZK_DTFIM) AS DATA"
	cQry += "  FROM "+RetSqlName("SZK")
	cQry += " WHERE ZK_FILIAL = '"+xFilial("SZK")+"'"
	cQry += "   AND ZK_TRANSP = '"+cTransp+"'"
	cQry += "   AND ZK_TABELA != '"+cTab+"'"
	cQry += "   AND D_E_L_E_T_ = ' '"

	TCQUERY cQry NEW ALIAS "QRY"

	If QRY->(!EOF()) .AND. STOD(QRY->DATA) >= dDate
		lRet := .F.
	EndIf

	QRY->(dbCloseArea())

Return lRet
