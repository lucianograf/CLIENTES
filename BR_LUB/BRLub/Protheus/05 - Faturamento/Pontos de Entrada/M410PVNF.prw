#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} M410PVNF
//Ponto de entrada para validar Faturamento de pedido na rotina Mata410 - Preparar Doc.Saída.
@author Marcelo Alberto Lauschner
@since 22/08/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function M410PVNF ()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local 	cNumPed  	:= SC5->C5_NUM
	Local	cQry		:= ""
	Local	cUfEmit		:= GetMv("MV_ESTADO")
	local   lContOnline := GetNewPar("GM_CTBONLN",.T.)

	// Verifica se é empresa Frimazo
	If cEmpAnt == "05"

		If SC5->C5_TIPO $"D#B"
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

			If SA2->A2_EST	<> cUfEmit .And. !SC5->C5_TPFRETE $ "F#S" .And. (SC5->C5_TRANSP == "001   " .Or. Empty(SC5->C5_TRANSP))
				If Empty(SC5->C5_VEICULO)
					MsgAlert("O Pedido tem destino Interestadual e não foi informado o veículo para geração do MDF-e!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					lRet	:= .F.
				Endif
			Endif
		Else
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

			If SA1->A1_EST	<> cUfEmit .And. !SC5->C5_TPFRETE $ "F#S" .And. (SC5->C5_TRANSP == "001   " .Or. Empty(SC5->C5_TRANSP))
				If Empty(SC5->C5_VEICULO)
					MsgAlert("O Pedido tem destino Interestadual e não foi informado o veículo para geração do MDF-e!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					lRet	:= .F.
				Endif
			Endif
		Endif

		If SC5->C5_BLPED == "F"
			MsgAlert("O Pedido está bloqueado pelo Financeiro como Pagto Antecipado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			lRet := .F.
		Endif
		// Verifica se o parametro de Controle de Rastro estiver ativo
		If GetMv("MV_RASTRO") =="S"

			cQry := "SELECT C6_PRODUTO,C6_QTDVEN "
			cQry += "  FROM " + RetSqlName("SC6") + " C6," + RetSqlName("SB1") + " B1," + RetSqlName("SF4") + " F4 "
			cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
			cQry += "   AND B1_COD = C6_PRODUTO "
			cQry += "   AND B1_RASTRO = 'L' "
			cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"
			cQry += "   AND F4.D_E_L_E_T_ = ' ' "
			cQry += "   AND F4_ESTOQUE = 'S' "
			cQry += "   AND F4_CODIGO = C6_TES "
			cQry += "   AND F4_FILIAL = '" + xFilial("SF4")+ "'"
			cQry += "   AND C6.D_E_L_E_T_ = ' ' "
			cQry += "   AND C6_LOTECTL = ' ' "
			cQry += "   AND C6_NUM = '" + cNumPed + "'"
			cQry += "   AND C6_FILIAL = '" + xFilial("SC6")+ "'"

			TcQuery cQry NEW ALIAS "QRYC6"

			If QRYC6->(!Eof())
				MsgAlert("O Pedido possui produtos com controle de Lote e os lote não foram definidos no Pedido, indicando que não foi feita a conferência do pedido!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				lRet := .F.
			Endif
			QRYC6->(dbCloseArea())
		Endif
		
		// 20/09/2020 - Efetua chamada que faz a aglutinação de produtos por lote no pedido de venda - remanejando a SDC 
		If !(SC5->C5_TIPO $"D#B")
			If SA1->(FieldPos("A1_XCLAGLT")) > 0  
				If SA1->A1_XCLAGLT == "S"
					sfAjustSDC()
				Endif 
			ElseIf SC5->C5_CLIENTE $ GetNewPar("FZ_CLAGLTI","000288#000280#000885#000862#000989#000646#001041#001035") // Criar parâmetro para adicioanr mais clientes 
				// Angeloni / Madero / Oesa / Bello / Grupo Fartura  / Cooper / EBS Comper / SDB Comper
				sfAjustSDC()
			Endif 
		Endif 
	EndIf

	// Força a contabilização Online - Chamado 21.591
	If lContOnline
		//³ mv_par01 Mostra Lan‡.Contab     ?  Sim/Nao                         ³
		U_GravaSx1("MT460A","01",2)
		//³ mv_par02 Aglut. Lan‡amentos     ?  Sim/Nao                         ³
		U_GravaSx1("MT460A","02",1)
		//³ mv_par03 Lan‡.Contab.On-Line    ?  Sim/Nao                         ³
		U_GravaSx1("MT460A","03",1)

	Endif

	RestArea(aAreaOld)

Return lRet

/*/{Protheus.doc} sfAjustSDC
Função que visa ajustar o pedido de venda mudando os itens digitados efetuando aglutinação 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 20/09/2020
@return return_type, return_description
/*/
Static Function sfAjustSDC()

	Local	aAreaOld		:= GetArea()
	Local	cNxtSC9
	Local 	cNumPed 	 	:= SC5->C5_NUM
	Local	aStruSC9		:= SC9->(dbStruct())
	Local	aStruSC6		:= SC6->(dbStruct())
	Local	aStruSDC		:= SDC->(dbStruct())

	Local	aElimSC9		:= Array(Len(aStruSC9))
	Local	aElimSC6		:= Array(Len(aStruSC6))
	Local	aElimSDC		:= Array(Len(aStruSDC))

	Local	aNewSC9			:= {}
	Local	aNewSC6			:= {}
	Local	aNewSDC			:= {}

	Local 	nLastSC6Rec		:= 0
	Local	nLastSC9Rec		:= 0

	Local 	cCpoSumSC9		:= "C9_QTDLIB #C9_QTDLIB2"
	Local	cCpoSumSC6		:= "C6_QTDVEN #C6_VALOR  #C6_QTDLIB #C6_QTDLIB2#C6_UNSVEN #C6_QTDENT #C6_QTDENT2#C6_QTDEMP #C6_QTDEMP2"
	Local	cCpoZerSC6		:= "C6_ITEM   #C6_LOCALIZ"
	Local	cCpoZerSC9		:= "C9_ITEM   #C9_SEQUEN "
	Local	cCpoZerSDC		:= "DC_ITEM   #DC_SEQ    "
	Local	cNxtItem 		:= sfMaxItem(cNumPed) // Obtém o último item do pedido
	Local	cAgrpPrdLot		:= ""
	Local 	nY,nZ,nX

	// Efetua consulta dos registros SC9 -
	// Com Lote / Com localização / Liberado Estoque / Liberado Crédito / Sem Poder 3/ Sem Bloqueio WMS / Atualiza estoque 
	cNxtSC9	:= GetNextAlias()
	BeginSql Alias cNxtSC9
			COLUMN C9_DATALIB AS DATE
			COLUMN C9_DTVALID AS DATE
			COLUMN C9_DATENT  AS DATE
			SELECT C9_FILIAL,C9_PEDIDO,C9_ITEM,C9_CLIENTE,C9_LOJA,C9_PRODUTO,C9_QTDLIB,C9_DATALIB,C9_SEQUEN,C9_GRUPO,C9_PRCVEN,C9_AGREG,C9_LOTECTL,
			       C9_NUMLOTE,C9_NUMSERI,C9_DTVALID,C9_LOCAL,C9_TPCARGA,C9_QTDLIB2,C9_DATENT,C9_RETOPER,C9_TPOP,C9_BLEST,C9_BLCRED
			  FROM %Table:SC9% C9 , %Table:SC6% C6 , %Table:SF4% F4
			 WHERE C9_FILIAL = %xFilial:SC9%
			   AND C9_PEDIDO  = %Exp:cNumPed%
			   AND C9_BLEST = '  '
			   AND C9_BLCRED = '  '
			   AND C9_IDENTB6 = ' '
			   AND C9_RESERVA = ' '
			   AND C9_BLWMS = ' '
			   AND C9_LOTECTL <>  ' '
			   AND C9.%NotDel%
			   AND F4.%NotDel% 
			   AND F4_ESTOQUE = 'S'
			   AND F4_CODIGO = C6_TES
			   AND F4_FILIAL = %xFilial:SF4%
			   AND C6.%NotDel%
			   AND C6_LOCALIZ <>  ' ' 
			   AND C6_ITEM = C9_ITEM
			   AND C6_PRODUTO = C9_PRODUTO 
			   AND C6_NUM = C9_PEDIDO 
			   AND C6_FILIAL = %xFilial:SC6% 
			 ORDER BY C9_PRODUTO,C9_LOTECTL,C9_ITEM,C9_SEQUEN
	EndSql

	While (cNxtSC9)->(!Eof())

		DbSelectArea("SC9")
		DbSetOrder(1)
		DbSeek((cNxtSC9)->(C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED) )
		// Efetua consulta dos registro SDC
		DbSelectArea("SDC")
		DbSetOrder(1) // DC_FILIAL+DC_PRODUTO+DC_LOCAL+DC_ORIGEM+DC_PEDIDO+DC_ITEM+DC_SEQ+DC_LOTECTL+DC_NUMLOTE+DC_LOCALIZ+DC_NUMSERI
		If DbSeek(xFilial("SDC")+(cNxtSC9)->(C9_PRODUTO+C9_LOCAL)+"SC6"+(cNxtSC9)->(C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_LOTECTL+C9_NUMLOTE))

			DbSelectArea("SC6")
			DbSetOrder(1) // --C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
			If DbSeek(xFilial("SC6")+(cNxtSC9)->(C9_PEDIDO+C9_ITEM+C9_PRODUTO))

				For nY := 1 To Len(aStruSDC)
					If aStruSDC[nY][2] # "V"
						aElimSDC[nY] 	:= SDC->(FieldGet(FieldPos(aStruSDC[nY][1])))
					EndIf
				Next nY

				For nY := 1 To Len(aStruSC9)
					If aStruSC9[nY][2] # "V"
						aElimSC9[nY] 	:= SC9->(FieldGet(FieldPos(aStruSC9[nY][1])))
					EndIf
				Next nY

				For nY := 1 To Len(aStruSC6)
					If aStruSC6[nY][2] # "V"
						aElimSC6[nY] 	:= SC6->(FieldGet(FieldPos(aStruSC6[nY][1])))
					EndIf
				Next nY

				Aadd(aNewSDC,{SC6->C6_FILIAL,SC6->C6_NUM,SC6->C6_ITEM,SC6->C6_PRODUTO,SC9->C9_SEQUEN,SC6->C6_TES,SC9->C9_LOTECTL,SC9->C9_NUMLOTE,aClone(aElimSDC)})
				Aadd(aNewSC9,{SC6->C6_FILIAL,SC6->C6_NUM,SC6->C6_ITEM,SC6->C6_PRODUTO,SC9->C9_SEQUEN,SC6->C6_TES,SC9->C9_LOTECTL,SC9->C9_NUMLOTE,aClone(aElimSC9)})
				Aadd(aNewSC6,{SC6->C6_FILIAL,SC6->C6_NUM,SC6->C6_ITEM,SC6->C6_PRODUTO,SC9->C9_SEQUEN,SC6->C6_TES,SC9->C9_LOTECTL,SC9->C9_NUMLOTE,aClone(aElimSC6)})


				DbSelectArea("SC6")
				RecLock("SC6",.F.)
				DbDelete()
				MsUnlock()

				DbSelectArea("SDC")
				RecLock("SDC",.F.)
				DbDelete()
				MsUnlock()

				DbSelectArea("SC9")
				RecLock("SC9",.F.)
				DbDelete()
				MsUnlock()

			Endif
		Endif

		(cNxtSC9)->(DbSkip())
	Enddo
	(cNxtSC9)->(DbCloseArea())


	For nY := 1 To Len(aNewSC6)

		// Verifica agrupamento - Filial+Pedido+Produto+Tes+Lote
		If cAgrpPrdLot <>  (aNewSC6[nY,1]+aNewSC6[nY,2]+aNewSC6[nY,4]+aNewSC6[nY,6]+aNewSC6[nY,7]+aNewSC6[nY,8])

			cNxtItem		:= Soma1(cNxtItem)

			DbSelectArea("SC6")
			RecLock("SC6",.T.)
			For nZ := 1 To Len(aStruSC6)
				// Verifica os campos que não devem ser replicados
				If !(Padr(aStruSC6[nZ][1],10) $ cCpoZerSC6)
					SC6->(FieldPut(FieldPos(aStruSC6[nZ][1]),aNewSC6[nY,9,nZ]))
				Endif

			Next nZ
			SC6->C6_ITEM	:= cNxtItem
			SC6->(MsUnlock())

			nLastSC6Rec	:= SC6->(Recno())

			DbSelectArea("SC9")
			RecLock("SC9",.T.)
			For nZ := 1 To Len(aStruSC9)
				// Verifica os campos que não devem ser replicados
				If !(Padr(aStruSC9[nZ][1],10) $ cCpoZerSC9)
					SC9->(FieldPut(FieldPos(aStruSC9[nZ][1]),aNewSC9[nY,9,nZ]))
				Endif
			Next nZ
			SC9->C9_ITEM	:= cNxtItem
			SC9->C9_SEQUEN	:= "01"
			MsUnlock()
			nLastSC9Rec	:= SC9->(Recno())

		Else
			DbSelectArea("SC6")
			// Só garante que vai posicionar no registro correto da SC6
			If SC6->(Recno()) <> nLastSC6Rec
				DbGoto(nLastSC6Rec)
			Endif
			RecLock("SC6",.F.)

			For nZ := 1 To Len(aStruSC6)
				// Verifica os campos que devem ser incrementados
				If Padr(aStruSC6[nZ][1],10) $ cCpoSumSC6
					&("SC6->"+aStruSC6[nZ][1]) 	+= aNewSC6[nY,9,nZ]
				Endif
			Next nZ
			MsUnlock()

			DbSelectArea("SC9")
			// Só garante que vai posicionar no registro correto da SC9
			If SC9->(Recno()) <> nLastSC9Rec
				DbGoto(nLastSC9Rec)
			Endif
			RecLock("SC9",.F.)

			For nZ := 1 To Len(aStruSC9)
				// Verifica os campos que devem ser incrementados
				If Padr(aStruSC9[nZ][1],10) $ cCpoSumSC9
					&("SC9->"+aStruSC9[nZ][1]) 	+= aNewSC9[nY,9,nZ]
				Endif
			Next nZ
			MsUnlock()

		Endif

		// Efetua a gravação da SDC detalhada, pois só mudou o campo Item, porém valores como endereço, lote permancecem como original 
		DbSelectArea("SDC")
		RecLock("SDC",.T.)
		For nZ := 1 To Len(aStruSDC)
			// Verifica os campos que não devem ser replicados
			If !(aStruSDC[nZ][1] $ cCpoZerSDC)
				SDC->(FieldPut(FieldPos(aStruSDC[nZ][1]),aNewSDC[nY,9,nZ]))
			Endif
		Next nZ
		SDC->DC_ITEM	:= cNxtItem
		SDC->DC_SEQ		:= "01"
		MsUnlock()

		 cAgrpPrdLot :=  (aNewSC6[nY,1]+aNewSC6[nY,2]+aNewSC6[nY,4]+aNewSC6[nY,6]+aNewSC6[nY,7]+aNewSC6[nY,8])

	Next nY

	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfMaxItem
Função para obter o último Item do pedido de venda
@type function
@version 
@author Marcelo Alberto Lauschner
@since 20/09/2020
@param cNumPed, character, param_description
@return return_type, return_description
/*/
Static Function sfMaxItem(cNumPed)

	Local	aAreaOld	:= GetArea()
	Local	cNxtSC6		:= GetNextAlias()
	Local 	cNextItem	:= StrZero(1,TamSx3("C6_ITEM")[1])

	BeginSql Alias cNxtSC6
		SELECT MAX(C6_ITEM) C6_ITEM
		  FROM %Table:SC6% C6
		 WHERE C6_FILIAL = %xFilial:SC6%
		   AND C6_NUM  = %Exp:cNumPed%
		   AND C6.%NotDel%
	EndSql

	If !Eof()
		cNextItem	:= (cNxtSC6)->C6_ITEM
	Endif
	(cNxtSC6)->(DbCloseArea())

	RestArea(aAreaOld)

Return cNextItem

