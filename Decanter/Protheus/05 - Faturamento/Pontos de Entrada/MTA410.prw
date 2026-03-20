
/*/{Protheus.doc} MTA410
Ponto de entrada no final do pedido de venda 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 17/05/2021
@return return_type, return_description
/*/
User Function MTA410()

	Local   aAreaOld    := GetArea()
	Local   x
	Local 	y
	Local   nBlq        := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_BLQ"})
	Local   nQtdLib   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDLIB"})
	Local 	nQtdVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local 	nItem     	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	Local 	nProduto  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local 	nPosTes  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	Local 	nPosTpOp  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_OPER"})
	Local   lRet        := .T.
	Local 	aItems		:= aClone(aCols)
	Local 	aContBonf	:= {} // Variável para controlar se existe bonificação de um mesmo produto na nota

	// Somente pedidos tipo Normal e Oriundos do Máxima
	If M->C5_TIPO == "N" .And. !Empty(M->C5_XXPEDMA)

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)

		If SA1->(FieldPos("A1_ZAUTO")) > 0 .And. SA1->A1_ZAUTO == "1" .And. cEmpAnt $ "01#02" .And. INCLUI

			For x := 1 To Len(aCols)
				aCols[x][nBlq]  := "N"
				// Forço a quantidade liberada
				If aCols[x][nQtdLib] == 0
					aCols[x][nQtdLib] := aCols[x][nQtdVen]
				Endif

				DbSelectArea("SC6")
				DbSetOrder(1)
				If DbSeek(xFilial("SC6")+M->C5_NUM+aCols[x][nItem]+aCols[x][nProduto])
					aCols[x][nQtdLib]	-= SC6->C6_QTDENT
				Endif
			Next

		Else
			For x := 1 To Len(aCols)
				//aCols[x][nBlq]  	:= "S"
				aCols[x][nQtdLib] 	:= 0
			Next
		Endif
		// Se for pedido Normal - Empresa Decanter 	 - Vendedor Vtex - não for origem importação Vtex
	ElseIf M->C5_TIPO == "N" .And. cEmpAnt == "01" .And. M->C5_VEND1=="000138" .And. !Empty(M->C5_ZNUMMGT) .And. !FwIsInCallStack("U_VTEX_ORDER")
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
			// Se o risco do cliente for A e for pessoa fisica - Ajusta para submeter cliente á análise crédito
			If SA1->A1_RISCO == "A" .And. SA1->A1_PESSOA == "F"
				RecLock("SA1",.F.)
				SA1->A1_RISCO 		:= "B"
				MsUnlock()

				U_WFGERAL("marcelo@centralxml.com.br"/*cEmail*/,"Alteração de Risco do cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NREDUZ/*cTitulo*/,;
					"Alteração automática de Risco A para B do cadastro do cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NREDUZ+ " durante alteração manual do pedido "+M->C5_NUM+" por usuário "+cUserName+" oriundo do VTEX  "/*cTexto*/,"MTA410"/*cRotina*/,/*cAnexo*/)
			Endif
		Endif
		// Se for pedido Normal - Empres Decanter = Vendedor Vtex - Origem na importação Vtex
	ElseIf M->C5_TIPO == "N" .And. cEmpAnt == "01" .And. M->C5_VEND1=="000138" .And. !Empty(M->C5_ZNUMMGT) .And. FwIsInCallStack("U_VTEX_ORDER")
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
			// Se o risco do cliente não for A e for pessoa Fisica - Ajusta para importar o pedido liberado
			If SA1->A1_RISCO <> "A"  .And. SA1->A1_PESSOA == "F"
				RecLock("SA1",.F.)
				SA1->A1_RISCO 		:= "A"
				If !Empty(SA1->A1_VENCLC)
					SA1->A1_VENCLC 	:= CTOD("") // Zera a data de vencimento do limite por demanda
				Endif
				MsUnlock()

				U_WFGERAL("marcelo@centralxml.com.br"/*cEmail*/,"Alteração de Risco do cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NREDUZ/*cTitulo*/,;
					"Alteração automática de Risco para A do cadastro do cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NREDUZ+ " durante inclusão/alteração do pedido "+M->C5_NUM+" na importação VTEX pelo usuário "+cUserName/*cTexto*/,"MTA410"/*cRotina*/,/*cAnexo*/)
			Endif
		Endif

	Endif

	// 04/05/2023 - Validação de Motivo de Bonificação - Chamado 1255 e 1574 
	If cEmpAnt $ "01#02" .And. M->C5_TIPO == "N" .And. !IsBlind() .And. Alltrim(Upper(FunName())) $  "MATA410"
		If M->C5_ZOPRMAX $ "05#VB" .And. Empty(M->C5_ZMOTIVO)
			MsgAlert ("Favor preencher o campo 'MOTIVO DA BONIFICAÇÃO' !! ","Informe Motivo de Bonificação")
			lRet	:= .F.			
		Endif 
	Endif 

	// Validação para engatilhar o tipo de operação para TES inteligente em pedidos com item bonificado e item como venda 
	If cEmpAnt $ "01#02" .And. M->C5_TIPO == "N"
		For x := 1 To Len(aItems)
			If !aItems[x][Len(aHeader)+1]

				DbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+aItems[x,nProduto])

				DbSelectArea("SF4")
				DbSetOrder(1)
				DbSeek(xFilial("SF4")+aItems[x,nPosTes])

				For y := 1 To Len(aItems)
					If !aItems[y][Len(aHeader)+1] .And. y # x

						// Se for o mesmo produto em outra linha e o TES esteja para não Gerar Duplicata
						If aItems[x,nProduto] == aItems[y,nProduto] .And. SF4->F4_DUPLIC == "N" .And. aItems[x,nPosTpOp] == "03" .And. !aItems[y,nPosTpOp] $ "03#BV"
							Aadd(aContBonf,{aItems[x,nItem],;
								aItems[x,nProduto],;
								aItems[x,nPosTes],;
								aItems[x,nPosTpOp],;
								x})
						Endif
					Endif
				Next
			Endif
		Next

		If Len(aContBonf) > 0
			For x := 1 To Len(aContBonf)
				n := aContBonf[x,5]
				aCols[n,nPosTpOp]	:= "BV"
				cTesItem				:= MaTesInt(2,"BV",M->C5_CLIENTE,M->C5_LOJACLI,"C",aCols[n,nProduto],"C6_TES")

				A410MultT("M->C6_TES",cTesItem)
				aCols[n,nPosTes] 	:= cTesItem

				If ExistTrigger("C6_TES    ")
					RunTrigger(2,n)
				Endif
			Next
		Endif

	Endif

	RestArea(aAreaOld)

Return lRet
