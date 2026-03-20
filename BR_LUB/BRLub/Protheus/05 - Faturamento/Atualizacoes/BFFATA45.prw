#Include 'Protheus.ch'

//ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))

/*/{Protheus.doc} BFFATA45
(Remanejamento de estoque entre pedidos liberados no crédito )
@author MarceloLauschner
@since 05/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function BFFATA45()

	Local	oDlgSC9
	Local	aButton		:= {}
	Local	aAlter		:= {}
	Local	nOpcLoc		:= 0
	Private	cQryLoc		:= ""
	Private	lAutoExec	:= .F.
	Private	bRefrXmlF	:= {|| .F.}
	Private	oPesqProd,oDescPrd,oQteLib
	Private	cVarProd	:= Space(TamSX3("C9_PRODUTO")[1])
	Private	cDescPrd	:= ""
	Private	nQteLib		:= 0
	Private	lVldClose	:= .F.
	Private aColsBlq	:= {}
	Private	aHeadBlq	:= {}
	Private	bChangeBlq	:= {|| sfRodape()}
	Private oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private oRed		:= LoaDbitmap( GetResources(), "BR_VERMELHO" )

	//IAGO 05/04/2017 Chamado(17720)
	If !U_BFCFGM23(.T.,"BFFATA45"+cEmpAnt+cFilAnt+"001","Alguém está remanejando estoque ou enviando pedido exp.")
		Return
	EndIf

	If cEmpAnt+cFilAnt $ "0205"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial RS é necessário escolher entre o armazém Atria ou Flexsil",{"01-Atria","02-Flexsil"},3)
		Endif

		If nOpcLoc == 2
			cQryLoc += " AND C9_LOCAL = '02' "
		ElseIf nOpcLoc == 1
			cQryLoc += " AND C9_LOCAL = '01' "
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	ElseIf cEmpAnt+cFilAnt $ "XXxx"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial SC é necessário escolher entre o armazém da Transluc ou Superlog",{"01-Transluc","02-Superlog"},3)
		Endif

		If nOpcLoc == 2
			cQryLoc += " AND C9_LOCAL = '02' "
		ElseIf nOpcLoc == 1
			cQryLoc += " AND C9_LOCAL = '01' "
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0208"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial MG é necessário escolher entre o armazém de Lubrificante ou Pneus!",{"01-Lubrificantes","02-Pneus"},3)
		Endif

		If nOpcLoc == 2
			cQryLoc += " AND C9_LOCAL = '02' "
		ElseIf nOpcLoc == 1
			cQryLoc += " AND C9_LOCAL = '01' "
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0204"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial BF-PR é necessário escolher entre o armazém da Texaco ou Michelin!",{"01-Texaco","02-Michelin"},3)
		Endif

		If nOpcLoc == 2
			cQryLoc += " AND C9_LOCAL = '02' "
		ElseIf nOpcLoc == 1
			cQryLoc += " AND C9_LOCAL = '01' "
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	Endif

	If nOpcLoc == 3
		MsgAlert("Não houve seleção de um armazém!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	Endif
	// 1 - Legenda
	Aadd(aHeadBlq		,{"Ok"					,"OK"		   		,"@BMP"     		,1					,0					,""					,				,"C"			,""				,""})

	//DbSelectArea("SX3")
	//DbSetOrder(2)

	//DbSeek("C9_PEDIDO")
	cCampo1 := "C9_PEDIDO"
	// 2 - Numero pedido
	Aadd(aHeadBlq		,{"Pedido"		,GetSx3Cache(cCampo1,"X3_CAMPO")		,GetSx3Cache(cCampo1,"X3_PICTURE")	,GetSx3Cache(cCampo1,"X3_TAMANHO")	,GetSx3Cache(cCampo1,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo1,"X3_TIPO"),"",""})
	Private nPxPedido    := Len(aHeadBlq)

	//DbSeek("C9_QTDLIB")
	cCampo2 := "C9_QTDLIB"
	// 3 - Quantidade Liberada
	Aadd(aHeadBlq		,{"Qte Liberada"	,GetSx3Cache(cCampo2,"X3_CAMPO")	,GetSx3Cache(cCampo2,"X3_PICTURE")	,GetSx3Cache(cCampo2,"X3_TAMANHO")	,GetSx3Cache(cCampo2,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo2,"X3_TIPO"),"",""})
	Private nPxQteLib    := Len(aHeadBlq)

	//DbSeek("C9_XWMSQTE
	cCampo3 := "C9_XWMSQTE"
	// 4 - Nova Quantidade
	Aadd(aHeadBlq		,{"Nova Quantidade"	,GetSx3Cache(cCampo3,"X3_CAMPO")		,GetSx3Cache(cCampo3,"X3_PICTURE")	,GetSx3Cache(cCampo3,"X3_TAMANHO")	,GetSx3Cache(cCampo3,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo3,"X3_TIPO"),"",""})
	Private nPxNewQte    := Len(aHeadBlq)
	Aadd(aAlter,GetSx3Cache(cCampo3,"X3_CAMPO"))

	//DbSeek("C9_QTDLIB2")
	cCampo4 := "C9_QTDLIB2"
	// 5 - Saldo Bloqueado
	Aadd(aHeadBlq		,{"Saldo Bloqueado"	,GetSx3Cache(cCampo4,"X3_CAMPO")		,GetSx3Cache(cCampo4,"X3_PICTURE")	,GetSx3Cache(cCampo4,"X3_TAMANHO")	,GetSx3Cache(cCampo4,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo4,"X3_TIPO"),"",""})
	Private nPxNewSaldo    := Len(aHeadBlq)

	//DbSeek("C9_CLIENTE")
	cCampo5 := "C9_CLIENTE"
	// 6 - Codigo Cliente
	Aadd(aHeadBlq		,{"Cliente"		,GetSx3Cache(cCampo5,"X3_CAMPO")		,GetSx3Cache(cCampo5,"X3_PICTURE")	,GetSx3Cache(cCampo5,"X3_TAMANHO")	,GetSx3Cache(cCampo5,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo5,"X3_TIPO"),"",""})
	Private nPxCliente    := Len(aHeadBlq)

	//DbSeek("C9_LOJA")
	cCampo6 := "C9_LOJA"
	// 7 - Loja
	Aadd(aHeadBlq		,{"Loja"		,GetSx3Cache(cCampo6,"X3_CAMPO")		,GetSx3Cache(cCampo6,"X3_PICTURE")	,GetSx3Cache(cCampo6,"X3_TAMANHO")	,GetSx3Cache(cCampo6,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo6,"X3_TIPO"),"",""})
	Private nPxLoja    := Len(aHeadBlq)

	//DbSeek("A1_NOME")
	cCampo7 := "A1_NOME"
	// 8 - Nome
	Aadd(aHeadBlq		,{"Razao Social"		,GetSx3Cache(cCampo7,"X3_CAMPO")		,GetSx3Cache(cCampo7,"X3_PICTURE")	,GetSx3Cache(cCampo7,"X3_TAMANHO")	,GetSx3Cache(cCampo7,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo7,"X3_TIPO"),"",""})
	Private nPxNome    := Len(aHeadBlq)

	//DbSeek("A1_MUN")
	cCampo8 := "A1_MUN"
	// 9 - Cidade
	Aadd(aHeadBlq		,{"Cidade"		,GetSx3Cache(cCampo8,"X3_CAMPO")		,GetSx3Cache(cCampo8,"X3_PICTURE")	,GetSx3Cache(cCampo8,"X3_TAMANHO")	,GetSx3Cache(cCampo8,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo8,"X3_TIPO"),"",""})
	Private nPxMun    := Len(aHeadBlq)

	//DbSeek("C9_ITEM")
	cCampo9 := "C9_ITEM"
	// 10 - Item
	Aadd(aHeadBlq		,{"Item"		,GetSx3Cache(cCampo9,"X3_CAMPO")		,GetSx3Cache(cCampo9,"X3_PICTURE")	,GetSx3Cache(cCampo9,"X3_TAMANHO")	,GetSx3Cache(cCampo9,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo9,"X3_TIPO"),"",""})
	Private nPxItem   	:= Len(aHeadBlq)

	//DbSeek("C9_SEQUEN")
	cCampo10 := "C9_SEQUEN"
	//11 - Sequencia
	Aadd(aHeadBlq		,{"Seq"		,GetSx3Cache(cCampo10,"X3_CAMPO")		,GetSx3Cache(cCampo10,"X3_PICTURE")	,GetSx3Cache(cCampo10,"X3_TAMANHO")	,GetSx3Cache(cCampo10,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo10,"X3_TIPO"),"",""})
	Private nPxSequen 	:= Len(aHeadBlq)


	//DbSeek("C9_BLEST")
	cCampo11 := "C9_BLEST"
	// 12 - Bloqueio de Estoque
	Aadd(aHeadBlq		,{"Blq.Estoque"		,GetSx3Cache(cCampo11,"X3_CAMPO")		,GetSx3Cache(cCampo11,"X3_PICTURE")	,GetSx3Cache(cCampo11,"X3_TAMANHO")	,GetSx3Cache(cCampo11,"X3_DECIMAL")	,"",,GetSx3Cache(cCampo11,"X3_TIPO"),"",""})
	Private nPxBlEst    := Len(aHeadBlq)

	Define MsDialog oDlgSC9 From 0,0 TO 550,1200  Of oMainWnd Pixel Title OemToAnsi("Realocação de estoques")

	Private oPaneCab := TPanel():New(0,0,"",oDlgSC9,,.F.,.F.,,,600,30,.T.,.F.)
	oPaneCab:align := CONTROL_ALIGN_TOP

	@ 002,002 SAY "Informe o Código do Produto" of oPaneCab Pixel
	@ 015,002 MsGet oPesqProd Var cVarProd Valid sfPesquisa() F3 "SB1" Size 70,10 of oPaneCab pixel
	@ 015,080 MsGet oDescPrd Var cDescPrd Size 150,10 Of oPaneCab Pixel When .F.

	Private oPaneDados := TPanel():New(0,0,"",oDlgSC9,,.F.,.F.,,,200,100,.T.,.F.)
	oPaneDados:align := CONTROL_ALIGN_ALLCLIENT

	Private oGetBlq	:= MsNewGetDados():New(005,;
		005,;
		200,;
		200,;
		GD_UPDATE,;
		"AllwaysTrue()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,;
		"",;
		aAlter,;
	/*nFreeze*/,;
		Len(aColsBlq)/*nMax*/,;
		"U_BFATA45A()"/*cCampoOk*/,;
		"AllwaysTrue()"/*cSuperApagar*/,;
		"AllWaysTrue()"/*cApagaOk*/,;
		oPaneDados,;
		@aHeadBlq,;
		@aColsBlq,;
		bChangeBlq)
	oGetBlq:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT


	Private oPaneRodape := TPanel():New(0,0,"",oPaneDados,,.F.,.F.,,,40,40,.T.,.F.)
	oPaneRodape:align := CONTROL_ALIGN_BOTTOM

	@ 002,002 SAY "Qte Disponível" of oPaneRodape Pixel
	@ 002,045 MsGet oQteLib Var nQteLib Size 50,10 of oPaneRodape pixel When .F.


	Activate MsDialog oDlgSC9 On Init (sfStartIni(oDlgSC9,aButton)) Valid lVldClose

	//IAGO 05/04/2017 Chamado(17720)
	U_BFCFGM23(.F.,"BFFATA45"+cEmpAnt+cFilAnt+"001")

Return

/*/{Protheus.doc} sfStartIni
//TODO Descrição auto-gerada.
@author marce
@since 15/10/2019
@version 1.0
@return ${return}, ${return_description}
@param oInDlg, object, descricao
@param aButton, array, descricao
@type function
/*/
Static Function sfStartIni(oInDlg,aButton)

	If lAutoExec

		// Executa função
		While .T.

			Eval(bRefrXmlF)

		Enddo
		oInDlg:End()
	Else
		EnchoiceBar(oInDlg,{|| Iif(MsgYesNo("Deseja gravar os dados informados?","Confirmação"),sfGrava(oInDlg),Nil)},{|| oInDlg:End()},,aButton)
		oGetBlq:oBrowse:Refresh()
	Endif

Return


/*/{Protheus.doc} sfGrava
(Grava informações marcadas no sistema)
@author MarceloLauschner
@since 05/02/2015
@version 1.0
@param oDlg, objeto, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrava(oInDlg)

	Local		iX
	Local		nContErr	:= 0
	Local		aAreaOld	:= GetArea()
	Local		nQteBlq	:= 0
	Local		nQteLib	:= 0
	Local		nVlrCred	:= 0
	Local 		aLib	 	:= {.T.,.T.,.F.,.F.}
	Local		lExecLib	:= .F.
	Local 		cBkSequen	:= ""
	Local 		cBkEstAvc	:= ""
	Local 		bBlkC9

	DbSelectArea("SC9")
	DbSetOrder(1)

	For iX := 1 To Len(oGetBlq:aCols)
		DbSelectArea("SC9")
		DbSetOrder(1)
		If DbSeek(xFilial("SC9")+oGetBlq:aCols[ix,nPxPedido]+oGetBlq:aCols[ix,nPxItem]+oGetBlq:aCols[ix,nPxSequen])
			// Garante que os itens ainda esteja na mesma configuração de quando a tela foi iniciada
			If Empty(SC9->C9_LIBFAT) .And. !(SC9->C9_BLEST $ "10") .And. Empty(SC9->C9_SERIENF) .And. Empty(SC9->C9_BLCRED)

				If SC9->C9_QTDLIB == oGetBlq:aCols[ix,nPxQteLib]

				Else
					nContErr++
				Endif
			Else
				nContErr++
			Endif
		Endif
	Next
	If nContErr > 0
		MsgAlert("Houveram modificações nos pedidos enquanto esta tela estava aberta. Favor recarregar o produto e edite novamente!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		RestArea(aAreaOld)
		Return
	Else
		For iX := 1 To Len(oGetBlq:aCols)
			DbSelectArea("SC9")
			DbSetOrder(1)
			If DbSeek(xFilial("SC9")+oGetBlq:aCols[ix,nPxPedido]+oGetBlq:aCols[ix,nPxItem]+oGetBlq:aCols[ix,nPxSequen])

				If SC9->(FieldPos("C9_XSEQUEN")) > 0
					cBkSequen	:= Iif(Empty(SC9->C9_XSEQUEN),SC9->C9_SEQUEN,SC9->C9_XSEQUEN)
						
					DbSelectArea("SC5")
					DbSetOrder(1)
					DbSeek(xFilial("SC5")+SC9->C9_PEDIDO)
					cBkEstAvc	:= SC5->C5_XESTAVC
					bBlkC9		:= {|| SC9->C9_XSEQUEN  := cBkSequen , SC9->C9_XESTAVC := cBkEstAvc}
				Else
					cBkSequen	:= ""
					cBkEstAvc	:= ""
					bBlkC9		:= Nil
				Endif
				lExecLib	:= .F.

				If Empty(oGetBlq:aCols[iX,nPxBlEst]) .And. oGetBlq:aCols[iX,nPxNewQte] < oGetBlq:aCols[iX,nPxQteLib]
					nQteBlq	:=	oGetBlq:aCols[iX,nPxNewSaldo]
					nQteLib	:= 	oGetBlq:aCols[iX,nPxNewQte]
					lExecLib	:= .T.
				ElseIf !Empty(oGetBlq:aCols[iX,nPxBlEst]) .And. oGetBlq:aCols[iX,nPxNewQte] > 0
					nQteBlq	:= 	oGetBlq:aCols[iX,nPxNewSaldo]
					nQteLib	:= 	oGetBlq:aCols[iX,nPxNewQte]
					lExecLib	:= .T.
				Endif

				// Se houver diferença entre a quantidade liberada e o disponível - fará alteração na sc9
				If lExecLib
					Begin Transaction
						// Executa Estorno do Item
						SC9->(A460Estorna(/*lMata410*/,/*lAtuEmp*/,@nVlrCred))
						// Cad. item do pedido de venda
						DbSelectArea("SC6")
						DbSetOrder(1)
						If DbSeek(xFilial("SC6")+oGetBlq:aCols[ix,nPxPedido]+oGetBlq:aCols[ix,nPxItem] )     //FILIAL+NUMERO+ITEM

							If nQteLib > 0	// Garante que o Flag de separação vá para o novo item liberado
								MaLibDoFat(SC6->(RecNo()),nQteLib,aLib[1],aLib[2],aLib[3],aLib[4],.F.,.F.,/*aEmpenho*/,bBlkC9/*bBlock*/,/*aEmpPronto*/,/*lTrocaLot*/,/*lOkExpedicao*/,nVlrCred,/*nQtdalib2*/)
							Endif

							// A quantidade a bloquear é liberada com bloqueio de estoque
							If nQteBlq > 0
								MaLibDoFat(SC6->(RecNo()),nQteBlq,.T./*lCredito*/,.F./*lEstoque*/,.F./*lAvCred*/,.F./*lAvEst*/,.F./*lLibPar*/,.F./*lTrfLocal*/,/*aEmpenho*/,bBlkC9/*bBlock*/,/*aEmpPronto*/,/*lTrocaLot*/,/*lOkExpedicao*/,nVlrCred,/*nQtdalib2*/)
							Endif
							SC6->(MaLiberOk({oGetBlq:aCols[ix,nPxPedido]},.F.))

							U_GMCFGM01("LE",;
								oGetBlq:aCols[ix,nPxPedido],;
								"Remanejamento de estoque do Produto "+cVarProd +" Qte liberada: "+Alltrim(Str(nQteLib)) +" Qte bloqueada: "+Alltrim(Str(nQteBlq)),;
								FunName(),;
								,;
								,;
								.T.)
							DbSelectARea("SC5")
							DbSetOrder(1)
							DbSeek(xFilial("SC5")+oGetBlq:aCols[ix,nPxPedido])
							DbSelectArea("SA3")
							DbSetOrder(1)
							DbSeek(xFilial("SA3")+SC5->C5_VEND1)

							U_WFGERAL(U_BFFATM15(SA3->A3_EMTMK,"BFFATM45"),;
								"Remanejamento de estoque do produto "+cVarProd,;
								"Pedido "+oGetBlq:aCols[ix,nPxPedido]+" Produto "+cVarProd +" Qte liberada: "+Alltrim(Str(nQteLib)) +" Qte bloqueada: "+Alltrim(Str(nQteBlq))+Chr(13)+Chr(10)+"Motivo: Remanejamento de estoque!")
						Endif
					End Transaction
				Endif
			Endif
		Next
	Endif

	lVldClose	:= .T.
	oInDlg:End()

Return


/*/{Protheus.doc} sfPesquisa
(Carrega pedidos baseado no produto digitado)
@author MarceloLauschner
@since 05/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfPesquisa()

	Local		cQry 		:= ""
	Local		aAreaOld	:= GetArea()
	Local		cAliasSC9 	:= GetNextAlias()
	Local		aAuxCols	:= {}
	Local		nI
	cDescPrd	:= ""


	aAuxCols	:= {}
	Aadd(aAuxCols,Array(Len(oGetBlq:aHeader)+1))
	aAuxCols[Len(aAuxCols)][Len(oGetBlq:aHeader)+1]	:= .F.
	For nI := 1 To Len(oGetBlq:aHeader)
		DbSelectArea("SX3")
		DbSetOrder(2)
		If DbSeek(oGetBlq:aHeader[nI][2])
			aAuxCols[Len(aAuxCols)][nI] := CriaVar(oGetBlq:aHeader[nI][2],.T.)
		Else
			aAuxCols[Len(aAuxCols)][nI] := ""
		Endif
	Next

	oGetBlq:aCols	:= aClone(aAuxCols)
	//oGetBlq:oBrowse:Refresh()

	DbSelectArea("SB1")
	DbSetOrder(1)
	If DbSeek(xFilial("SB1")+cVarProd)
		If RegistroOK("SB1",.F.)
			cDescPrd	:= SB1->B1_DESC

			cQry := ""
			cQry += "SELECT C9_PEDIDO,C9_ITEM,C9_SEQUEN,C9_QTDLIB,C9_BLEST,C9_CLIENTE,C9_LOJA,"
			cQry += "       A1_NOME,A1_MUN "
			cQry += "  FROM "+RetSqlName("SC9") + " C9, "
			cQry += RetSqlName("SA1")+ " A1, "
			cQry += RetSqlName("SC5") + " C5, "
			cQry += RetSqlName("SC6") + " C6, "
			cQry += RetSqlName("SB1") + " B1, "
			cQry += RetSqlName("SF4") + " F4 "
			cQry += " WHERE A1.D_E_L_E_T_ = ' ' "
			cQry += "   AND A1_LOJA = C9_LOJA "
			cQry += "   AND A1_COD = C9_CLIENTE "
			cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
			cQry += "   AND B1.D_E_L_E_T_ =' ' "
			cQry += "   AND B1.B1_FILIAL = '"+xFilial("SB1") + "' "
			cQry += "   AND B1.B1_COD = C6_PRODUTO "
			// 27.455 - 28/02/2022 - Remanejar estoque TEX IPI somente depois do pedido integrado no estoque avançado.
			If cEmpAnt+cFilAnt == "0201" // Se for Atria SC
				cQry += "  AND CASE WHEN B1.B1_BLOQFAT = 'N' "
				cQry += "                AND B1.B1_CABO IN ('TEX', 'IPI') "
				cQry += "                AND LENGTH(REGEXP_REPLACE(B1.B1_FABRIC, '[^[:digit:]]')) = 8 "
				cQry += "                AND B1.B1_COD NOT IN ('02153.000159', '23722.000159', '43170.000159') "
				cQry += "           THEN C9_XESTAVC "
				cQry += "      ELSE "
				cQry += "        'S' "
				cQry += "      END = 'S' "
			Endif

			cQry += "   AND F4.D_E_L_E_T_ =' ' "
			cQry += "   AND F4_ESTOQUE = 'S' "
			cQry += "   AND F4_CODIGO = C6_TES "
			cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"'"
			cQry += "   AND C6.D_E_L_E_T_ = ' ' "
			cQry += "   AND C6_ITEM = C9_ITEM "
			cQry += "   AND C6_PRODUTO = C9_PRODUTO  "
			cQry += "   AND C6_NUM = C9_PEDIDO "
			cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"'"
			cQry += "   AND C5.D_E_L_E_T_= ' ' "
			cQry += "   AND C5_TIPO = 'N' "
			cQry += "   AND C5_NUM = C9_PEDIDO "
			cQry += "   AND C5_FILIAL = '"+xFilial("SC5")+"' "
			cQry += "   AND C9.D_E_L_E_T_ =  ' ' "
			cQry += cQryLoc
			cQry += "   AND C9_BLCRED = '  ' "
			cQry += "   AND C9_BLEST NOT IN('10') "
			cQry += "   AND C9_SERIENF = '   ' "
			cQry += "   AND C9_LIBFAT = '        ' "
			cQry += "   AND C9_PRODUTO = '"+cVarProd+"' "
			cQry += "   AND C9_FILIAL = '"+xFilial("SC9")+"' "
			cQry += " ORDER BY C9_BLEST,C9_PEDIDO,C9_ITEM "

			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasSC9,.T.,.T.)
			aAuxCols	:= {}

			While !Eof()
				Aadd(aAuxCols,{;
					Iif(Empty((cAliasSC9)->C9_BLEST),oVerde,oRed),;				// 1
				(cAliasSC9)->C9_PEDIDO,;												// 2
				(cAliasSC9)->C9_QTDLIB,;												// 3
				Iif(Empty((cAliasSC9)->C9_BLEST),(cAliasSC9)->C9_QTDLIB,0),;	// 4
				Iif(Empty((cAliasSC9)->C9_BLEST),0,(cAliasSC9)->C9_QTDLIB),;	// 5
				(cAliasSC9)->C9_CLIENTE,;											// 6
				(cAliasSC9)->C9_LOJA,;												// 7
				(cAliasSC9)->A1_NOME,;												// 8
				(cAliasSC9)->A1_MUN,;												// 9
				(cAliasSC9)->C9_ITEM,;												// 10
				(cAliasSC9)->C9_SEQUEN,;												// 11
				(cAliasSC9)->C9_BLEST,;												// 12
				.F.})
				(cAliasSC9)->(DbSkip())
			Enddo
			(cAliasSC9)->(DbCloseArea())

		Else
			MsgAlert("Produto Bloqueado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			oPesqProd:SetFocus()
		Endif
	Else
		MsgAlert("Não existe produto cadastrado com este código!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		oPesqProd:SetFocus()
	Endif

	If !Empty(aAuxCols)
		oGetBlq:aCols	:= aClone(aAuxCols)
	Endif
	oPaneDados:Refresh()
	oGetBlq:oBrowse:Refresh()
	oDescPrd:Refresh()
	RestArea(aAreaOld)
Return


/*/{Protheus.doc} BFATA45A
(Validação do campo digitado no Getdados)
@author MarceloLauschner
@since 05/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFATA45A()

	Local		lRet		:= .T.
	Local		nSaldLib	:= 0
	Local		iX

	// Verifica se o campo em digitação é o da Nova Quantidade
	If ReadVar() == "M->C9_XWMSQTE"
		// Se for de um pedido liberado
		If Empty(oGetBlq:aCols[oGetBlq:nAt,nPxBlEst])

			// Percorre a tela para procurar por saldos utilizados
			For iX := 1 To Len(oGetBlq:aCols)
				// Verifica pedidos que tem item liberado e soma quantidades disponibilizadas
				If Empty(oGetBlq:aCols[iX,nPxBlEst])
					If oGetBlq:nAt # iX
						nSaldLib -= oGetBlq:aCols[iX,nPxNewSaldo]
					Else
						nSaldLib += M->C9_XWMSQTE
					Endif
				Else
					nSaldLib += oGetBlq:aCols[iX,nPxNewQte]
				Endif
			Next
			// Se a quantidade
			If M->C9_XWMSQTE < nSaldLib
				MsgAlert("Saldo foi remanejado para pedidos bloqueados! Reveja a alocação do saldo em pedidos bloqueados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet	:= .F.
				// Se a nova quantidade for maior que a quantidade já liberada não permite continuar
			ElseIf M->C9_XWMSQTE > oGetBlq:aCols[oGetBlq:nAt,nPxQteLib]
				MsgAlert("Quantidade digitada é maior que o valor original!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet	:= .F.
			ElseIf M->C9_XWMSQTE < 0
				MsgAlert("Quantidade negativa não permitida!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet	:= .F.
			ElseIf Mod(M->C9_XWMSQTE,1) > 0
				MsgAlert("Quantidade com fração não permitida!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet	:= .F.
			Else
				oGetBlq:aCols[oGetBlq:nAt,nPxNewSaldo]	:= 	oGetBlq:aCols[oGetBlq:nAt,nPxQteLib] - M->C9_XWMSQTE
				oGetBlq:oBrowse:Refresh()
			Endif
		Else
			// Percorre a tela para procurar por saldos disponíveis
			For iX := 1 To Len(oGetBlq:aCols)
				// Verifica pedidos que tem item liberado e soma quantidades disponibilizadas
				If Empty(oGetBlq:aCols[iX,nPxBlEst])
					nSaldLib += oGetBlq:aCols[iX,nPxNewSaldo]
				Else
					// Verifica pedidos tem bloqueio e soma quantidades já utilizadas
					If oGetBlq:nAt # iX
						nSaldLib -= oGetBlq:aCols[iX,nPxNewQte]
					Endif
				Endif
			Next
			If 	M->C9_XWMSQTE > nSaldLib
				MsgAlert("Quantidade digitada é maior que o saldo disponbilizado pela alteração de pedidos que estavam reservando estoque!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet	:= .F.
			ElseIf M->C9_XWMSQTE < 0
				MsgAlert("Quantidade negativa não permitida!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet	:= .F.
			ElseIf Mod(M->C9_XWMSQTE,1) > 0
				MsgAlert("Quantidade com fração não permitida!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet	:= .F.
			Else
				oGetBlq:aCols[oGetBlq:nAt,nPxNewSaldo]	:= 	oGetBlq:aCols[oGetBlq:nAt,nPxQteLib] - M->C9_XWMSQTE
				oGetBlq:oBrowse:Refresh()
			Endif
		Endif
		If lRet
			sfRodape()
		Endif
	Endif

Return lRet


/*/{Protheus.doc} sfRodape
(Atualiza informação do Rodapé)
@author MarceloLauschner
@since 05/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRodape()
	Local	iX
	nQteLib	:= 0
	For iX := 1 To Len(oGetBlq:aCols)
		// Verifica pedidos que tem item liberado e soma quantidades disponibilizadas
		If Empty(oGetBlq:aCols[iX,nPxBlEst])
			nQteLib += oGetBlq:aCols[iX,nPxNewSaldo]
		Else
			If iX == oGetBlq:nAt .And. ReadVar() == "M->C9_XWMSQTE"
				nQteLib -= M->C9_XWMSQTE
			Else
				nQteLib -= oGetBlq:aCols[iX,nPxNewQte]
			Endif
		Endif
	Next
	oQteLib:Refresh()


Return
