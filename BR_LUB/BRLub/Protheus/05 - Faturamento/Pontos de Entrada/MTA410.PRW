#include "totvs.ch"

/*/{Protheus.doc} MTA410
(Enviar liberacao de pedidos via email  )
@author Leonardo J Koerich Jr
@since 27/11/2003
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MTA410()

	Local	aAreaOld	:= GetArea()
	Local 	nDesconto	:= 0.00
	Local	nTotDesc	:= 0.00
	Local 	nPeso    	:= 0.00
	Local	cDescE4		:= ""
	Local 	nPrzMed 	:= 0.00
	Local	nValTamp	:= 0
	Local	nTotPed		:= 0
	Local 	aItems		:= aClone(aCols)
	Local 	nTotCfop  	:= 0.00

	Local 	nItem     	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	Local 	nProduto  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local 	nQtdVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local 	nPrcVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	Local 	nPrUnit   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	Local 	nValor    	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
	Local 	nBlq      	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_BLQ"})
	Local 	nValDesc  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
	Local 	nTes      	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	Local	nCF       	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})
	Local 	nQtdLib   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDLIB"})
	Local	nClasFis	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CLASFIS"})
	Local	nPosLocal	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
	Local	nPosTampa	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XVLRTAM"})
	Local	nPxFlgAlc	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XALCADA"})
	Local 	cCfop     	:= Space(5)
	Local 	cObs      	:= ""
	Local 	cObsHtml  	:= ""
	Local 	lNea 		:= .F.
	Local	aContImp	:= {0,0}	// Posicao 1 - Conta demais produtos normais / Posicao 2 conta produtos importados
	Local	aContLocal	:= {0,0}	// Posição 1 - Armazém 01 / Posição 2  - Armazém 02
	Local	aMotBloq	:= {}
	Local	nT			:= n
	Local   x,nX
	Local	nY
	Local 	iW 
	Local	cCliPed		:= ""
	Local	lPrcTabFull	:= .F.
	Local	lPedRemessa	:= .F.
	Local	cEmail		:= ""
	Local	cRetAlc		:= ""
	Local	cUfEmit		:= GetMv("MV_ESTADO")
	Local	cAssessor	:= ""
	Local 	aCabPrd		:= {0,0,0} // 1- Produtos Lust 2-Produtos Pneus 3-Demais
	Private	lExibeMsg	:= !(INCLUI .And. !Empty(M->C5_PEDPALM)) // Se for inclusão e vier via Palm

	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MTA410")
		Return .T.
	Endif

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	// Se o Tipo de pedido for B=Beneficiamento D=Devolução descarta tratativas
	If M->C5_TIPO $ "D#B"
		RestArea(aAreaOld)
		Return(.T.)
	Endif

	DbSelectArea("SZ0")
	DbSetOrder(1)
	If DbSeek(xFilial("SZ0")+M->C5_NUM)
		cTp := 'AP'
	Else
		cTp := 'IP'
	Endif

	// Grava Log generico
	U_GMCFGM01(cTp,M->C5_NUM,,FunName())

	// Se tratando de Alteração de pedido, muda o status do pedido para situação inicial
	If ALTERA
		DbSelectArea("SC5")
		DbSetOrder(1)
		If DbSeek(xFilial("SC5")+M->C5_NUM)
			// Garante que se o pedido foi enviado por outra estação para a expedição, quem o estiver alterando não irá mais conseguir concluir a alteração
			If SC5->C5_BLPED == "S"
				If lExibeMsg
					MsgAlert("Este pedido "+SC5->C5_NUM+" não pode ser alterado por que está com o Status de 'Enviado para faturamento'. Favor verificar o log do pedido e junto à expedição o retorno do mesmo para continuar a alteração","Pedido enviado para faturamento")
				Else
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Este pedido "+SC5->C5_NUM+" não pode ser alterado por que está com o Status de 'Enviado para faturamento'. Favor verificar o log do pedido e junto à expedição o retorno do mesmo para continuar a alteração"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Endif
				RestArea(aAreaOld)
				Return .F.
			Endif
		Endif
		// Limpo o campo caso esteja preenchido por ocorrencia anterior
		M->C5_BLPED	:= " "
	Endif

	// Apenas garante que o cliente correto esteja posicionado
	DbSelectArea("SA1")
	DbSetOrder(1)
	MsSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)

	
	// Efetua correção do campo em tempo de execução para atualizar corretamente devido a pedidos oriundos de Tablet e Web
	DbSelectArea("SA3")
	DbSetOrder(1)
	If MsSeek(xFilial("SA3")+M->C5_VEND1)
		M->C5_XEMPFXC		:= SA3->A3_XSEGEMP+SA3->A3_XTPVEND
		lPrcTabFull		:= SA3->A3_XSEGEMP $ "LL" // Verifico se o pedido é oriundo do segmento Lust
	Endif

	// Força limpar o código de vendedor para não calcular base de comissão duplicada
	If M->C5_VEND2 == M->C5_VEND1
		M->C5_VEND2	:= " "
	Endif
	If M->C5_VEND3	== M->C5_VEND1
		M->C5_VEND3	:= " "
	Endif
	If !Empty(M->C5_VEND3) .And. M->C5_VEND3 == M->C5_VEND2
		M->C5_VEND3	:= " "
	Endif

	//-------------------------------------------------------------------------------------------------
	// Efetua validações que impedirão do pedido ser finalizado ou gerar alertas de bloqueio
	//-------------------------------------------------------------------------------------------------
	For x := 1 To Len(aItems)
		If !aItems[x][Len(aHeader)+1]
			// Validacao incluida em 11/05/2010 afins de evitar que sejam incluidos pedidos com erros de TES
			If SA1->A1_EST $ cUfEmit
				If aItems[x,nCF] > "6000"
					If 	lExibeMsg
						MsgAlert("CFOP invalido no pedido, para o item "+aItems[x,nItem] , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
					Endif
					RestArea(aAreaOld)
					Return .F.
				Endif
			Else
				If aItems[x,nCF] < "6000"
					If lExibeMsg
						MsgAlert("CFOP invalido no pedido, para o item "+aItems[x,nItem] , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
					Endif
					RestArea(aAreaOld)
					Return .F.
				Endif
			Endif

			// Adicionada validação que verifica se origem e situação tributarica estão corretas
			// 21/10/2011
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+aItems[x,nProduto])

			//aCabPrd		:= {0,0,0} // 1- Produtos Lust 2-Produtos Pneus 3-Demais
			If SB1->B1_CABO $ "MIC#CON#AGR#OUT#AGR#BIK#REL"
				aCabPrd[2]++
			ElseIf SB1->B1_CABO $ "LUS#ADT"
				aCabPrd[1]++
			Else
				aCabPrd[3]++
			Endif

			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4")+aItems[x,nTes])

			If aItems[x,nClasFis] <> (SB1->B1_ORIGEM+SF4->F4_SITTRIB)
				If lExibeMsg
					MsgAlert("Situação tributária inválida no pedido, para o item '"+aItems[x,nItem]+"'. Encontrado '"+aItems[x,nClasFis]+"' e esperado é '"+SB1->B1_ORIGEM+SF4->F4_SITTRIB+"' ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" CST incompátivel!" )
				Endif
				RestArea(aAreaOld)
				Return .F.
			Endif

			// Validação adicionada em 19/12/2012 afins de verifica se há produtos que devam ser faturados pela série 3 de NFe
			If Substr(SB1->B1_COD,1,1) == "I" .And. SB1->B1_GRUPO $ GetNewPar("BF_GRPIMPT","1135#1160#1161#1162#1163#1170#1180")
				// Soma na posicao 2 os itens importados
				aContImp[2]	+= 1
			Else
				// Soma na posicao demais itens
				aContImp[1]	+= 1
			Endif

			If aItems[x,nPosLocal] == "01"
				aContLocal[1] += 1
			ElseIf aItems[x,nPosLocal] == "02"
				aContLocal[2] += 1
			Endif

			If aContLocal[1] > 0 .And. aContLocal[2] > 0
				If lExibeMsg
					MsgAlert("Este pedido contém produtos digitados em armazéns diferentes. A digitação deve ser feita somente usando o mesmo armazém para todos os itens ou em pedidos separados OBRIGATORIAMENTE!!","Produtos concomitantes não permitidos")
				Endif
				RestArea(aAreaOld)
				Return .F.
			Endif


			
		Endif

		//	Se o pedido for de Remessa de Vasilhames não precisa liberação de alçada
		If SF4->F4_XTPMOV $ "VS"
			lPedRemessa	:= .T.
		ElseIf lPedRemessa
			lPedRemessa	:= .F.	// Atribui falso
			MsgAlert("Pedido digitado com itens de remessa de vasilhames e também encontrado TES que possuí outro tipo de operação",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Remessa Vasilhame!")
			RestArea(aAreaOld)
			Return .F.
		Endif

		nTotPed	+= aItems[x,nValor]
	
	Next

	
	// Se identificado que o pedido é de Simples remessa
	If lPedRemessa
		For x := 1 To Len(aCols)
			aCols[x][nBlq]  := "N"
			// Forço a quantidade liberada
			If aCols[x][nQtdLib] > 0
				aCols[x][nQtdLib] := aCols[x][nQtdLib]
			Else
				aCols[x][nQtdLib] := aCols[x][nQtdVen]
			Endif
		Next
		RestArea(aAreaOld)
		Return .T.
	Endif

	// 06/07/2016 - Calculo de comissão baseado em desconto médio do pedido
	// Efetua o calculo de comissões
	U_BFFATM32(.T./*lIsSC5*/,.F./*lIsSUA*/,M->C5_VEND1/*cInVend1*/,M->C5_VEND2/*cInVend2*/,aCols/*aInAcols*/,M->C5_CLIENTE/*cInCli*/,M->C5_LOJACLI/*cInLoja*/,M->C5_EMISSAO/*dInEmissao*/)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria um novo processo...                                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cProcess := "000002"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Liberacao Pedido de Vendas"))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abre o HTML criado                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cStatus  := "100000"

	If IsSrvUnix()
		If File("/workflow/lib_pedido_fat.htm")
			oProcess:NewTask("Gerando HTML","/workflow/lib_pedido_fat.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/lib_pedido_fat.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\lib_pedido_fat.htm")
	Endif

	//oProcess:NewTask(cStatus,"\WORKFLOW\LIBERACAO_PEDIDO.HTM")
	oProcess:cSubject := "Liberação Pedido de Vendas --> " + M->C5_NUM
	oProcess:bReturn  := ""

	oHTML := oProcess:oHTML

	oHtml:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
	oHtml:ValByName("NUMERO"		,M->C5_NUM)
	oHtml:ValByName("EMISSAO"		,DTOC(M->C5_EMISSAO))


	cNea  	:= SA1->A1_SATFORT

	If cNea >= "R4020" .and. cNea <= "R4052"
		oHtml:ValByName("CLIENTE"	,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+ SA1->A1_NOME+'<font color=#FF0000>'+" <<< CLIENTE NUCLEO NEA >>>>"+'</font>')
		lNea := .T.
	Else
		oHtml:ValByName("CLIENTE"	,SA1->A1_COD+"/"+SA1->A1_LOJA+" - "+ Alltrim(SA1->A1_NOME) + "  CGC/CPF:" +  Transform( SA1->A1_CGC, Iif(SA1->A1_PESSOA == "J","@r 99.999.999/9999-99","@r 999.999.999-99")))
		lNea := .F.
	Endif

	oHtml:ValByName("ENDERECO"		,Alltrim(SA1->A1_END)+" "+SA1->A1_COMPLEM )
	oHtml:ValByName("MUNICIPIO"		,AllTrim(SA1->A1_MUN) + " / " + SA1->A1_EST + " CEP:" + Transform(SA1->A1_CEP,"@R 99999-999"))
	oHtml:ValByName("MINT"			,M->C5_MSGINT)
	oHtml:ValByName("MNOTA"			,M->C5_MENNOTA)

	If M->C5_CONDPAG == '999'
		If !Empty(M->C5_DATA1)
			oHtml:ValByName("DATA1",M->C5_DATA1)
		Endif
		If !Empty(M->C5_DATA2)
			oHtml:ValByName("DATA2",M->C5_DATA2)
		Endif
		If !Empty(M->C5_DATA3)
			oHtml:ValByName("DATA3",M->C5_DATA3)
		Endif
		If !Empty(M->C5_DATA4)
			oHtml:ValByName("DATA4",M->C5_DATA4)
		Endif
	Endif

	dbSelectArea("SA3")
	dbSetOrder(1)
	If MsSeek(xFilial("SA3")+M->C5_VEND1)
		oHtml:ValByName("VENDEDOR",M->C5_VEND1 + "/"+SA3->A3_NREDUZ)
	Else
		oHtml:ValByName("VENDEDOR",M->C5_VEND1)
	Endif

	aSort(aItems,,,{|x,y| x[nCF]+x[nItem] < y[nCF]+y[nItem]})


	aFisGet	:= {}
	//dbSelectArea("SX3")
	//dbSetOrder(1)
	//MsSeek("SC6")
	//While !Eof().And.X3_ARQUIVO=="SC6"
	aFields := {}
	aFields := FWSX3Util():GetAllFields("SC6", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cValid := UPPER(GetSx3Cache(cCampo,"X3_VALID")+ GetSx3Cache(cCampo,"X3_VLDUSER"))
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGet,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGet,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		//	dbSkip()
		//EndDo
	Next nX
	aSort(aFisGet,,,{|x,y| x[3]<y[3]})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Busca referencias no SC5                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aFisGetSC5	:= {}
	
	aFields := {}
	aFields := FWSX3Util():GetAllFields("SC5", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cValid := UPPER(GetSx3Cache(cCampo,"X3_VALID")+ GetSx3Cache(cCampo,"X3_VLDUSER"))

		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		//	dbSkip()
		//EndDo
	Next nX

	aSort(aFisGetSC5,,,{|x,y| x[3]<y[3]})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicializa a funcao fiscal                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	MaFisSave()
	MaFisEnd()
	MaFisIni(	IIf(!Empty(cCliPed),cCliPed,Iif(Empty(M->C5_CLIENT),M->C5_CLIENTE,M->C5_CLIENT)),;// 1-Codigo Cliente/Fornecedor
		M->C5_LOJAENT,;		// 2-Loja do Cliente/Fornecedor
		IIf(M->C5_TIPO$'DB',"F","C"),;				// 3-C:Cliente , F:Fornecedor
		M->C5_TIPO,;				// 4-Tipo da NF
		M->C5_TIPOCLI,;		// 5-Tipo do Cliente/Fornecedor
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		"MATA461",;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		{"",""})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Realiza alteracoes de referencias do SC5         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aFisGetSC5) > 0
		dbSelectArea("SC5")
		For nY := 1 to Len(aFisGetSC5)
			If !Empty(&("M->"+Alltrim(aFisGetSC5[ny][2])))
				MaFisAlt(aFisGetSC5[ny][1],&("M->"+Alltrim(aFisGetSC5[ny][2])),,.F.)
			EndIf
		Next nY
	Endif
	//-------------------------------------------------------------------------------------------------
	nT	:= 0
	For x := 1 To Len(aItems)

		If !aItems[x][Len(aHeader)+1]
			If cCfop <> aItems[x][nCF]
				If !Empty(cCfop)
					AAdd((oHtml:ValByName("P.IT")),"")
					AAdd((oHtml:ValByName("P.PRODUTO")),"")
					AAdd((oHtml:ValByName("P.ESTOQUE")),"")
					AAdd((oHtml:ValByName("P.QUANT")),"")
					AAdd((oHtml:ValByName("P.PRCTAB")),"")
					AAdd((oHtml:ValByName("P.PRCVEN")),"")
					AAdd((oHtml:ValByName("P.TAM")),"")

					cNumSx5	:= Posicione("SX5",1,xFilial("SX5")+"13"+cCfop,"X5_DESCRI")
					
					If !Empty(cNumSx5)
						AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop+"--"+cNumSx5)
					Else
						AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
					Endif
					AAdd((oHtml:ValByName("P.VALOR"))		,Transform(nTotCfop,"@E 999,999,999.99"))
					nTotCfop := 0.00
				Endif
				cCfop := aItems[x][nCF]
			Endif

			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+aItems[x][nProduto])

				DbSelectArea("SB2")
				DbSetOrder(1)
				If dbSeek(xFilial("SB2")+aItems[x][nProduto]+aItems[x][nPosLocal])
					AAdd((oHtml:ValByName("P.ESTOQUE"))	,SB2->B2_QATU-SB2->B2_RESERVA)
				Else
					AAdd((oHtml:ValByName("P.ESTOQUE"))	,"0000")
				Endif


				SF4->(dbSetOrder(1))
				SF4->(MsSeek(xFilial("SF4")+aItems[x][nTes]))

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Calcula o preco de lista                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

				nValMerc  := (aItems[x][nQtdVen])*aItems[x][nPrcVen]
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Calcula o preco de lista                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nValMerc  := aItems[x][nValor]
				nPrcLista := aItems[x][nPrUnit]

				nAcresUnit:= A410Arred(aItems[x][nPrcVen]*M->C5_ACRSFIN/100,"D2_PRCVEN")
				nAcresFin := A410Arred(aItems[x][nQtdVen]*nAcresUnit,"D2_TOTAL")
				nValMerc  += nAcresFin
				nDesconto := a410Arred(nPrcLista*aItems[x][nQtdVen],"D2_DESCON")-nValMerc
				nDesconto := IIf(nDesconto<=0,aItems[x][nValDesc],nDesconto)
				nDesconto := Max(0,nDesconto)
				nPrcLista += nAcresUnit
				//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
				If cPaisLoc=="BRA" .or. GetNewPar('MV_DESCSAI','1') == "2"
					nValMerc  += nDesconto
				Endif
				// Incremento váriavel corretamente
				nT++

				MaFisAdd(	SB1->B1_COD,;  			// 1-Codigo do Produto ( Obrigatorio )
					aItems[x][nTES],;	   					// 2-Codigo do TES ( Opcional )
					aItems[x][nQtdVen],; 	 			// 3-Quantidade ( Obrigatorio )
					aItems[x][nPrUnit],;		  			// 4-Preco Unitario ( Obrigatorio )
					nDesconto,;	 						// 5-Valor do Desconto ( Opcional )
					"",;	   								// 6-Numero da NF Original ( Devolucao/Benef )
					"",;									// 7-Serie da NF Original ( Devolucao/Benef )
					0,;										// 8-RecNo da NF Original no arq SD1/SD2
					0,;										// 9-Valor do Frete do Item ( Opcional )
					0,;										// 10-Valor da Despesa do item ( Opcional )
					0,;										// 11-Valor do Seguro do item ( Opcional )
					0,;										// 12-Valor do Frete Autonomo ( Opcional )
					nValMerc,;								// 13-Valor da Mercadoria ( Obrigatorio )
					0,;										// 14-Valor da Embalagem ( Opiconal )
					,;										// 15
					,;										// 16
					Iif(nItem>0,aItems[x,nItem],""),; 	// 17
					0,;										// 18-Despesas nao tributadas - Portugal
					0,;										// 19-Tara - Portugal
					aItems[x,nCF],; 						// 20-CFO
					{},;	           					// 21-Array para o calculo do IVA Ajustado (opcional)
					"")

				nTotDesc += MaFisRet(nT,"IT_DESCONTO")

				AAdd((oHtml:ValByName("P.IT"))			,aItems[x][nItem])
				AAdd((oHtml:ValByName("P.PRODUTO"))		,aItems[x][nProduto])
				AAdd((oHtml:ValByName("P.DESCRICAO"))	,SB1->B1_STS+"-"+SB1->B1_DESC)


				AAdd((oHtml:ValByName("P.QUANT"))		,Transform(aItems[x][nQtdVen],'@E 999,999,999'))
				AAdd((oHtml:ValByName("P.PRCTAB"))		,Transform(aItems[x][nPrUnit],"@E 999,999,999.99"))

				nValTamp	:= aItems[x][nPosTampa]

				AAdd((oHtml:ValByName("P.TAM"))			,Transform(nValTamp,"@E 9,999.99"))

				nImpostos	:= MaFisRet(nT,"IT_VALIPI")+MaFisRet(nT,"IT_VALSOL")

				nTotCfop += aItems[x][nValor] + Iif(lPrcTabFull,nImpostos,0)

				AAdd((oHtml:ValByName("P.VALOR"))		,Transform(aItems[x][nValor]+Iif(lPrcTabFull,nImpostos,0),"@E 999,999,999.99"))

				AAdd((oHtml:ValByName("P.PRCVEN"))		,Transform(aItems[x][nPrcVen]+IIf(lPrcTabFull,nImpostos/aItems[x][nQtdVen],0),"@E 999,999,999.99"))

				nAlqImp	:= ((MaFisRet(nT,"IT_VALICM")/aItems[x][nQtdVen])+(MaFisRet(nT,"IT_VALPS2")/aItems[x][nQtdVen])+(MaFisRet(nT,"IT_VALCF2")/aItems[x][nQtdVen]))/aItems[x][nPrcVen]*100

				nPeso		+= aItems[x][nQtdVen]*SB1->B1_PESBRU

			Endif
		Endif
	Next

	If !Empty(cCfop)
		AAdd((oHtml:ValByName("P.IT"))			,"")
		AAdd((oHtml:ValByName("P.PRODUTO"))	,"")
		AAdd((oHtml:ValByName("P.ESTOQUE"))	,"")
		AAdd((oHtml:ValByName("P.QUANT"))		,"")
		AAdd((oHtml:ValByName("P.PRCTAB"))		,"")
		AAdd((oHtml:ValByName("P.PRCVEN"))		,"")
		AAdd((oHtml:ValByName("P.TAM"))			,"")

		cNumSx5	:= Posicione("SX5",1,xFilial("SX5")+"13"+cCfop,"X5_DESCRI")
		
		If !empty(cNumSx5)
			AAdd((oHtml:ValByName("P.DESCRICAO")),cCfop+"--"+cNumSx5)
		Else
			AAdd((oHtml:ValByName("P.DESCRICAO")),cCfop)
		Endif
		AAdd((oHtml:ValByName("P.VALOR"))		,Transform(nTotCfop,"@E 999,999,999.99"))
		nTotCfop := 0.00
	Endif

	MaFisAlt("NF_FRETE"		,M->C5_FRETE)
	MaFisAlt("NF_VLR_FRT"	,M->C5_VLR_FRT)
	MaFisAlt("NF_SEGURO"	,M->C5_SEGURO)
	MaFisAlt("NF_AUTONOMO"	,M->C5_FRETAUT)
	MaFisAlt("NF_DESPESA"	,M->C5_DESPESA)


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Indenizacao por valor                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If M->C5_PDESCAB > 0
		MaFisAlt("NF_DESCONTO",A410Arred(MaFisRet(,"NF_VALMERC")*M->C5_PDESCAB/100,"C6_VALOR")+MaFisRet(,"NF_DESCONTO"))
	EndIf

	If M->C5_DESCONT > 0
		MaFisAlt("NF_DESCONTO",Min(MaFisRet(,"NF_VALMERC")-0.01,nTotDesc+M->C5_DESCONT),/*nItem*/,/*lNoCabec*/,/*nItemNao*/,GetNewPar("MV_TPDPIND","1")=="2" )
	EndIf


	oHtml:ValByName("TOTAL"			,Transform(MaFisRet(,"NF_TOTAL"),"@E 999,999,999.99"))
	oHtml:ValByName("TOTPESO"		,Transform(nPeso,"@E 999,999.99"))
	oHtml:ValByName("FATURA"		,Transform(MaFisRet(,"NF_BASEDUP"),"@E 999,999.99"))

	oHtml:ValByName("RDMAKE"		,"MTA410.PRW")
	oHtml:ValByName("DATA"			,Date())
	oHtml:ValByName("HORA"			,Time())


	// Validação das regras de Alçadas antes do Fim da função fiscal para poder pegar variáveis
	//BFFATM21(cInTipo,nTotDup					,nTotPed				 ,nPrzMed ,cDescE4 ,aInCols		 ,aInHeader				)
	nVlrFrete	:= U_BFFATM22(M->C5_EMISSAO/*dInData*/,M->C5_CLIENTE/*cInCodCli*/,M->C5_LOJACLI/*cInLojCli*/,M->C5_TRANSP/*cInTransp*/,MaFisRet(,"NF_TOTAL")/*nInVlrMerc*/,nPeso/*nInPeso*/,M->C5_FRETE/*nInVlrFrete*/)

	lRetAlc	:= U_BFFATM21("MC5"  ,MaFisRet(,"NF_BASEDUP"),MaFisRet(,"NF_TOTAL"),@nPrzMed,@cDescE4,aClone(aItems),aClone(aHeader),@cRetAlc,@aMotBloq,nVlrFrete)

	oHtml:ValByName("CONDICAO"		,cDescE4+" - Média: "+Transform(nPrzMed,"@E 999,999,999")+" Dias")
	oHtml:ValByName("FRETEZK"		,Transform(nVlrFrete,"@E 999,999.99"))
	oHtml:ValByName("FRETEPERCZK"	,Transform(nVlrFrete/MaFisRet(,"NF_TOTAL"),"@E 999.99"))
	// Chamado 18713 - Informar Frete manualmente digitado no Pedido
	oHtml:ValByName("FRETEINF"		,Transform(M->C5_FRETE,"@E 999,999.99"))

	MaFisEnd()
	MaFisRestore()

	// Avalia os responsáveis de liberação por fornecedor
	For x := 1 To Len(aCols)
		If !aCols[x][Len(aHeader)+1]
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+aCols[x][nProduto])
				DbSelectArea("SZS")
				DbSetOrder(2)
				DbSeek(xFilial("SZS")+SB1->B1_PROC+SB1->B1_LOJPROC)
				While !Eof() .And. SZS->ZS_FILIAL+SZS->ZS_CODFORN+SZS->ZS_LOJAFOR == xFilial("SZS")+SB1->B1_PROC+SB1->B1_LOJPROC
					If !(UsrRetMail(SZS->ZS_IDUSR1) $ cEmail) .And. SZS->ZS_MOTIVO $ aCols[x,nPxFlgAlc]
						cEmail	+= UsrRetMail(SZS->ZS_IDUSR1)+";"
					Endif
					DbSelectArea("SZS")
					DbSkip()
				Enddo
			Endif
		Endif
	Next

	cObs     := ""
	cObsHtml := ""
	For x := 1 To Len(aMotBloq)
		cObs += Alltrim(aMotBloq[x][1])+ CRLF
		cObsHtml += Alltrim(aMotBloq[x][1])+"<p></p>"
	Next


	Dbselectarea("SA3")
	Dbsetorder(1)
	Dbseek(xFilial("SA3")+M->C5_VEND1)
	cEmail	+= ";"+SA3->A3_MENS1
	cEmail	+= ";"+SA3->A3_MENS2


	//aCabPrd		:= {0,0,0} // 1- Produtos Lust 2-Produtos Pneus 3-Demais
	cEmail += ";"+Alltrim(SA3->A3_EMTMK)

	// Grava Log

	//U_GMCFGM01(Iif(INCLUI,"IP","AP"),M->C5_NUM,"Enviado para: "+oProcess:cTo ,FunName())

	// Se o retorno da liberação de alçadas foi ok, já libera o pedido
	If lRetAlc
		// Adicionada verificação se o cliente está com Risco=E e limite crédito R$ 1,00
		// Desta forma o Financeiro define o cliente como Antecipado
		// IAGO 11/08/2016 Chamado(15525)
		//If SA1->A1_RISCO $ "E" .And. SA1->A1_LC == 1
		If SA1->A1_RISCO $ "E" .And. SA1->A1_LC == 1 .And. !INCLUI
			lRetAlc := .F.
		Endif
		// Condição de pagamento antecipado
		// IAGO 11/08/2016 Chamado(15525)
		//If M->C5_CONDPAG $ "099"
		If M->C5_CONDPAG $ "099" .And. !INCLUI
			lRetAlc := .F.
		Endif

		If lRetAlc
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
			U_BFFATA35("P"/*cZ9ORIGEM*/,M->C5_NUM/*cZ9NUM*/,"6"/*cZ9EVENTO*/,"Liberação automática do pedido sem restrição de alçadas"/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)

			U_GMCFGM01("LP"/*cTipo*/,M->C5_NUM/*cPedido*/,"Liberação automática sem restrição alçada"/*cObserv*/,FunName()/*cResp*/,/*lBtnCancel*/,/*cMotDef*/,.T./*lAutoExec*/)
		Else
			For x := 1 To Len(aCols)
				aCols[x][nBlq]  	:=	"S"
				aCols[x][nQtdLib] 	:=	0
			Next
			If !IsBlind()
				MsgAlert("Este pedido está em Situação de Antecipado. Será necessário o Crédito liberar a Alçada deste pedido! ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
			U_BFFATA35("P"/*cZ9ORIGEM*/,M->C5_NUM/*cZ9NUM*/,"6"/*cZ9EVENTO*/,"Pedido não liberado automaticamente. Situação de antecipado."/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)
			// Adiciona mensagem de Bloqueio por antecipado
			cObs 	 += Alltrim("Pedido com Situação de Antecipado. Solicite liberação de Alçada para o Departamento de Crédito!")+ CRLF
			cObsHtml += Alltrim('Pedido com Situação de Antecipado. Solicite liberação de Alçada para o Departamento de Crédito!')
			cEmail	+= ";cobranca1@atrialub.com.br;"
		Endif
	Else
		For x := 1 To Len(aCols)
			aCols[x][nBlq]  	:=	"S"
			aCols[x][nQtdLib] 	:=	0
		Next
		U_BFFATA35("P"/*cZ9ORIGEM*/,M->C5_NUM/*cZ9NUM*/,"6"/*cZ9EVENTO*/,"Pedido com restrição de alçadas '"+cObs+"'"/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)
	Endif

	oHtml:ValByName("MOTIVOS",cObsHtml)

	oHtml:ValByName("DATA"			,DTOC(dDataBase))
	oHtml:ValByName("HORA"			,Time())
	oHtml:ValByName("USUARIO"		,cUserName)


	If !Empty(UsrRetMail(__cUserId))
		oHtml:ValByName("EMAILUSER",UsrRetMail(__cUserId))
		cEmail += ";"+UsrRetMail(__cUserId)
	Endif
	
	// 10/07/2024 - Envia o também para um email customizado por parâmetro 
	If !Empty(GetNewPar("BL_MAILWFP",""))
		cEmail += ";"+GetNewPar("BL_MAILWFP","")
	Endif 

	cEmail := U_BFFATM15(cEmail,"MTA410")
	// Trata a limpeza dos e-mails repetidos 
	cRecebe := IIf(!Empty(cEmail),cEmail+";","")	
	aOutMails	:= StrTokArr(cRecebe,";")
	cRecebe	:= ""
	For iW := 1 To Len(aOutMails)
		If !Empty(cRecebe)
			cRecebe += ";"
		Endif
		If IsEmail(aOutMails[iW]) .And. !(Alltrim(Upper(aOutMails[iW])) $ cRecebe)
			cRecebe	+= Upper(aOutMails[iW])
		Endif
		Next
	oProcess:cTo := cRecebe
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()


	RestArea(aAreaOld)

Return(.T.)

