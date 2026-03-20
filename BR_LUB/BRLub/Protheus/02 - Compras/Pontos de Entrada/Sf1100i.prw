#INCLUDE "totvs.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} SF1100I
(Envio do relatorio de divergencia )
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function SF1100I()

	Local 	aAreaOld	:= GetArea()
	Local	lExistDiff	:= .F.
	Local	x
	Local 	iW 
	Local	oHtml
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	cQry
	Local 	cMailLust 	:= AllTrim(GetNewPar("BL_MLPROLU",""))
	Local 	cMailRocol 	:= AllTrim(GetNewPar("BL_MLPRORH","laercio@brlub.com.br;sandro@brlub.com.br"))
	Local 	cMailDest 	:= AllTrim(GetNewPar("BL_MLPROAL","glauco@brlub.com.br"))
	Local 	cTextWFTxt 	:= ""
	Local 	cMailWfTxt 	:= GetNewPar("BL_MLWFTXT","marcelo@centralxml.com.br")

		/* Solicitação da diretoria para enviar o wf para outras pessoas de acordo com o produto
			- Se for produto "Lust" continuar enviando para glauco@brlub.com.br, criar parametro para cadastrar envio de outras pessoas possíveis no futuro				
			- Se for produto "Rocol" ou "Houghton" enviar para laercio@brlub.com.br e sandro@brlub.com.br, criar parametro para facilitar alteração
		*/ 

	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("SF1100I")
		Return .T.
	Endif

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	If SF1->F1_TIPO $"C#I#P"
		RestArea(aAreaOld)
		Return
	Endif

	If SF1->F1_SERIE == "U  "
		RestArea(aAreaOld)
		Return
	Endif

	// 04/01/2018
	// Chamado 19.625 - Não gerar relatório de divergências para lançamentos de CTEs
	If Alltrim(SF1->F1_ESPECIE) $ "CTE#CTR"
		RestArea(aAreaOld)
		Return
	Endif



	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cPedidos := ""
	Private aPedidos := {}
	Private nTotal   := 0.00
	Private nTotalc  := 0
	Private nTotalg  := 0
	Private lVer     := .T.
	Private cNfdev   := Space(TamSX3("F1_DOC")[1])
	Private nCusprev := 0

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicio do processamento                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	//DbSelectArea("SF1")
	//DbSetOrder(1)
	//DbSeek(xFilial("SF1")+"000026421")
	If SF1->F1_TIPO == "N" .And. Alltrim(SF1->F1_ESPECIE) $ "SPED"

		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcess := TWFProcess():New(cProcess,OemToAnsi("Relatorio de Divergencia das Notas Fiscais de Entrada"))

		//Abre o HTML criado
		If IsSrvUnix()
			If File("/workflow/relatorio_de_divergencia.htm")
				oProcess:NewTask("Gerando HTML","/workflow/relatorio_de_divergencia.htm")
			Else
				//ConOut("Não localizou arquivo  /workflow/relatorio_de_divergencia.htm")
				Return
			Endif
		Else
			oProcess:NewTask("Gerando HTML","\workflow\relatorio_de_divergencia.htm")
		Endif

		oProcess:cSubject := "Relatorio de Divergencia da Nota Fiscal Nº --> "  + AllTrim(SF1->F1_DOC) + " " + SF1->F1_SERIE
		oProcess:bReturn  := ""
		oHTML := oProcess:oHTML

		// Preenche os dados do cabecalho
		oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
		oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
		oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
		oHtml:ValByName("INSC","Inscrição Estadual: " + SM0->M0_INSC)

		oHtml:ValByName("CNOTA",AllTrim(SF1->F1_DOC) + " " + SF1->F1_SERIE )
		oHtml:ValByName("EMIS",SF1->F1_EMISSAO )
		oHtml:ValByName("DIASDEC",dDataBase - SF1->F1_EMISSAO)

		dbSelectArea("SE4")
		dbSetOrder(1)
		If dbSeek(xFilial("SE4")+SF1->F1_COND)
			oHtml:ValByName("CCONDICAO","(" + AllTrim(SF1->F1_COND) + ") " + SE4->E4_DESCRI)
		Else
			oHtml:ValByName("CCONDICAO","")
		Endif

		dbSelectArea("SA2")
		dbSetOrder(1)
		If dbSeek(xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA)
			oHtml:ValByName("CFORNECE",SF1->F1_FORNECE + " - " + AllTrim(SA2->A2_NOME) + " - Fabrica " + SF1->F1_LOJA)
		Endif

		dbSelectArea("SD1")
		dbSetOrder(1)
		dbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)
		While !Eof() .And. xFilial("SD1") == SD1->D1_FILIAL .And. SD1->D1_DOC == SF1->F1_DOC .And. ;
				SD1->D1_SERIE == SF1->F1_SERIE .And. SD1->D1_FORNECE == SF1->F1_FORNECE .And. ;
				SD1->D1_LOJA == SF1->F1_LOJA

			AAdd((oHtml:ValByName("it.item")),SD1->D1_ITEM)

			dbSelectArea("SB1")
			dbSetOrder(1)
			If dbSeek(xFilial('SB1')+SD1->D1_COD)
				AAdd((oHtml:ValByName("it.desc")),SD1->D1_COD + " " + SB1->B1_DESC)
			Else
				AAdd((oHtml:ValByName("it.desc")),SD1->D1_COD)
			Endif

			// 10/07/2024 - Direciona email para usuários específicos conforme tipo de produto
			If "LT LUST " $ SB1->B1_DESC .And. !cMailLust $ cMailDest
				If !Empty(cMailDest)
					cMailDest	+= ";"
				Endif
				cMailDest	+= cMailLust
			Endif

			If ("ROCOL " $ SB1->B1_DESC .Or. "HOUGHTON " $ SB1->B1_DESC).And. !cMailRocol $ cMailDest
				If !Empty(cMailDest)
					cMailDest	+= ";"
				Endif
				cMailDest	+= cMailRocol
			Endif


			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4")+SD1->D1_TES)

			If SF4->F4_ESTOQUE == "S" .And. SD1->D1_QUANT > 0 
				cTextWFTxt	+= "Item: " + SD1->D1_ITEM + " Quantidade: " + cValToChar(SD1->D1_QUANT) + " Produto: " + SB1->B1_COD + SB1->B1_DESC + Chr(13) + Chr(10)
			Endif

			dbSelectArea("SC7")
			dbSetOrder(4)//FILIAL+PRODUTO+NUMERO+ITEM+SEQUENCIA
			If dbSeek(xFilial("SC7")+SD1->D1_COD+SD1->D1_PEDIDO+SD1->D1_ITEMPC)
				AAdd((oHtml:ValByName("it.qped")),Transform(SC7->C7_QUANT,'@E 999,999.9'))

				If SD1->D1_QUANT <> SC7->C7_QUANT
					AAdd((oHtml:ValByName("it.qent")),'<font color="#FF0000">' + Transform(SD1->D1_QUANT,'@E 999,999.9')+'</font>')
					lExistDiff	:= .T.
				Else
					AAdd((oHtml:ValByName("it.qent")),Transform(SD1->D1_QUANT,'@E 999,999.9'))
				Endif
				AAdd((oHtml:ValByName("it.vped")),Transform(SC7->C7_PRECO,'@E 999,999.99'))
				nD1Vuni	:= Round(SD1->D1_VUNIT,2)
				nC7Prc	:= Round(SC7->C7_PRECO,2)

				If (nD1Vuni - nC7Prc) > 0.02 .Or. (nC7Prc - nD1Vuni) > 0.02
					AAdd((oHtml:ValByName("it.vnf")) ,'<font color="#FF0000">' + Transform(SD1->D1_VUNIT,'@E 99,999,999.99')+'</font>')
					lExistDiff	:= .T.
				Else
					AAdd((oHtml:ValByName("it.vnf")) ,Transform(SD1->D1_VUNIT,'@E 99,999,999.99'))
				Endif
				// CUSTO
				//nCusprev := SC7->C7_PRECO+((SC7->C7_PRECO*(1+(SB1->B1_PICMENT/100)))*IIF(Substr(SD1->D1_CF,1,1)="2",0.12,0.17))-(SC7->C7_PRECO*IIF(Substr(SD1->D1_CF,1,1)="2",0.12,0.17))

				cQry := "SELECT ROUND(AVG((D1_TOTAL - D1_VALDESC + CASE WHEN F4_INCSOL = 'S' THEN D1_ICMSRET ELSE 0 END + CASE WHEN F4.F4_DESTACA = 'S' THEN D1_VALIPI ELSE 0 END ) /D1_QUANT) ,2) MED_CUSTO"
				cQry += "  FROM " + RetSqlName("SD1") + " D1, " + RetSqlName("SF4") + " F4 "
				cQry += " WHERE F4.D_E_L_E_T_ = ' ' "
				cQry += "   AND F4_CODIGO = D1_TES "
				cQry += "   AND F4_FILIAL = '" + xFilial("SF4") + "'"
				cQry += "   AND D1.D_E_L_E_T_ =' ' "
				cQry += "   AND D1_DTDIGIT < '" + DTOS(SD1->D1_DTDIGIT)+"' "
				cQry += "   AND D1_DTDIGIT >= '"+DTOS(SD1->D1_DTDIGIT-90) + "' "
				cQry += "   AND D1_COD = '" + SD1->D1_COD + "' "
				cQry += "   AND D1_QUANT  > 0 "
				cQry += "   AND D1_LOCAL = '" + SD1->D1_LOCAL + "' "
				cQry += "   AND D1_FORNECE = '" + SD1->D1_FORNECE + "'"
				cQry += "   AND D1_LOJA = '" + SD1->D1_LOJA + "'"
				cQry += "   AND D1_FILIAL = '" + xFilial("SD1")+"' "

				TcQuery cQry New Alias "QSD1"

				//AAdd((oHtml:ValByName("it.cuspr")),Transform(nCusprev,'@E 999,999.99'))
				If !Eof()
					AAdd((oHtml:ValByName("it.cuspr")),Transform(QSD1->MED_CUSTO,'@E 99,999,999.9999'))
				Else
					AAdd((oHtml:ValByName("it.cuspr")),Transform(0,'@E 99,999,999.99'))
				Endif
				QSD1->(DbCloseArea())

				//If (SD1->D1_CUSTO+SD1->D1_VALICM) <> nCusprev
				//	AAdd((oHtml:ValByName("it.cusnf")) ,'<font color="#FF0000">'+Transform((SD1->D1_CUSTO+SD1->D1_VALICM),'@E 999,999.99')+'</font>')
				//Else
				//	AAdd((oHtml:ValByName("it.cusnf")) ,Transform(SD1->D1_VUNIT,'@E 999,999.99'))
				//Endif
				AAdd((oHtml:ValByName("it.cusnf")) ,Transform(ROUND((SD1->D1_TOTAL - SD1->D1_VALDESC + Iif(SF4->F4_INCSOL=='S',SD1->D1_ICMSRET,0) + Iif(SF4->F4_DESTACA=='S',SD1->D1_VALIPI,0)) / SD1->D1_QUANT ,2),'@E 999,999.99'))


				If SD1->D1_DTDIGIT <> SC7->C7_DATPRF
					AAdd((oHtml:ValByName("it.dnf")) ,'<font color="#FF0000">'+DTOC(SD1->D1_DTDIGIT)+'</font>')
				Else
					AAdd((oHtml:ValByName("it.dnf")) ,DTOC(SD1->D1_DTDIGIT))
				Endif

				AAdd((oHtml:ValByName("it.dped")),DTOC(SC7->C7_DATPRF))

				AAdd((oHtml:ValByName("it.obs")) ,SD1->D1_LOCAL+ " - " +SC7->C7_OBS)

				//nTotal += (SC7->C7_QUANT * SC7->C7_PRECO) - (SD1->D1_QUANT * SD1->D1_VUNIT)
				nTotal += (SD1->D1_TOTAL - SD1->D1_VALDESC + Iif(SF4->F4_INCSOL=='S',SD1->D1_ICMSRET,0) + Iif(SF4->F4_DESTACA=='S',SD1->D1_VALIPI,0))
				DbSelectArea("SF4")
				DbSetOrder(1)
				DbSeek(xFilial("SF4")+SC7->C7_TES)

				nC7TotBru := Round((SC7->C7_TOTAL + Iif(SF4->F4_INCSOL=='S',SC7->C7_ICMSRET,0) + Iif(SF4->F4_DESTACA=='S',SC7->C7_VALIPI,0)) /SC7->C7_QUANT ,4)

				AAdd((oHtml:ValByName("it.cusped")) ,Transform(nC7TotBru,'@E 99,999,999.99'))

				nD1TotBru := Round((SD1->D1_TOTAL - SD1->D1_VALDESC + Iif(SF4->F4_INCSOL=='S',SD1->D1_ICMSRET,0) + Iif(SF4->F4_DESTACA=='S',SD1->D1_VALIPI,0))/SD1->D1_QUANT,4)

				nTotalc += (SD1->D1_QUANT * nC7TotBru) - (SD1->D1_QUANT * nD1TotBru)
				nTotalg += (SC7->C7_QUANT * nC7TotBru) - (SD1->D1_QUANT * nD1TotBru)

				lVer := .T.
				For x := 1 To Len(aPedidos)
					If aPedidos[x][1] == SD1->D1_PEDIDO
						lVer := .F.
					Endif
				Next
				If lVer
					AADD(aPedidos,{SD1->D1_PEDIDO,SC7->C7_COND})
				Endif
			Else
				AAdd((oHtml:ValByName("it.qent")),Transform(SD1->D1_QUANT,'@E 999,999'))
				AAdd((oHtml:ValByName("it.vnf")) ,Transform(SD1->D1_VUNIT,'@E 999,999.99'))
				AAdd((oHtml:ValByName("it.dnf")) ,DTOC(SF1->F1_EMISSAO))
				AAdd((oHtml:ValByName("it.qped")),0)
				AAdd((oHtml:ValByName("it.vped")),0)
				AAdd((oHtml:ValByName("it.cuspr")),Transform(0,'@E 99,999,999.99'))
				AAdd((oHtml:ValByName("it.cusnf")) ,Transform(ROUND((SD1->D1_TOTAL - SD1->D1_VALDESC + Iif(SF4->F4_INCSOL=='S',SD1->D1_ICMSRET,0) + Iif(SF4->F4_DESTACA=='S',SD1->D1_VALIPI,0)) / SD1->D1_QUANT ,2),'@E 999,999.99'))
				AAdd((oHtml:ValByName("it.cusped")) ,Transform(0,'@E 99,999,999.99'))
				AAdd((oHtml:ValByName("it.dped"))," ")
				AAdd((oHtml:ValByName("it.obs")) ,'<font color="#FF0000">SEM PEDIDO</font>')
			Endif

			// 31/10/2019 - Verifica se precisa criar os códigos de Declatórios de Ajuste
			If SD1->D1_FORMUL == "S"
				sfGrvF3K()
			Endif

			// Chamado 25.488 - Gravar o número da chapa já informado no Doc.Entrada
			If SD1->(FieldPos("D1_XIDCHAP")) > 0
				If !Empty(SD1->D1_CBASEAF) .And. !Empty(SD1->D1_XIDCHAP)
					DbSelectArea("SN1")
					DbSetOrder(1) // N1_FILIAL+N1_CBASE+N1_ITEM
					If DbSeek(xFilial("SN1")+SD1->D1_CBASEAF)
						RecLock("SN1",.F.)
						SN1->N1_CHAPA 	:= SD1->D1_XIDCHAP
						MsUnlock()
					Endif
				Endif
			Endif

			dbSelectArea("SD1")
			dbSkip()
		Enddo

		For x := 1 To Len(aPedidos)
			dbSelectArea("SE4")
			dbSetOrder(1)
			If dbSeek(xFilial("SE4")+aPedidos[x][2])
				cPedidos += aPedidos[x][1] + " (" + AllTrim(SE4->E4_DESCRI)+ "), "
			Else
				cPedidos += aPedidos[x][1] + ", "
			Endif
		Next

		oHtml:ValByName("CPEDIDO",cPedidos)
		oHtml:ValByName("NTOTAL" ,Transform(nTotal,'@E 999,999.99'))
		oHtml:ValByName("NTOTALC",Transform(nTotalc,"@E 999,999.99"))
		oHtml:ValByName("NTOTALG",Transform(nTotalg,"@E 999,999.99"))

		oProcess:ClientName(Substr(cUsuario,7,15))

		cSendMail 	:= U_BFFATM15(cMailDest,"SF1100I")
		// Trata a limpeza dos e-mails repetidos 
		cRecebe := IIf(!Empty(cSendMail),cSendMail+";","")	
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

		// 10/07/2024 - Envia WF simplificado
		If !Empty(cTextWFTxt)
			U_WFGERAL( cMailWfTxt ,;
				"Empresa:" + cEmpAnt+"/"+ cFilAnt + "Recebimento da Nota Fiscal Nº --> "  + AllTrim(SF1->F1_DOC) + " " + SF1->F1_SERIE + " " + SA2->A2_NREDUZ ,;
				cTextWFTxt,;
				"SF1100I")
		Endif

		// Se for nota tipo B=Beneficiamento
	ElseIf SF1->F1_TIPO == "B"

		dbSelectArea("SD1")
		dbSetOrder(1)
		dbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)
		While !Eof() .And. xFilial("SD1") == SD1->D1_FILIAL .And. SD1->D1_DOC == SF1->F1_DOC .And. ;
				SD1->D1_SERIE == SF1->F1_SERIE .And. SD1->D1_FORNECE == SF1->F1_FORNECE .And. ;
				SD1->D1_LOJA == SF1->F1_LOJA
			// Verifica se é nota de formulário próprio para executar regra de cadastro de Ajuste de Valores declaratórios
			If SD1->D1_FORMUL == "S"
				sfGrvF3K()
			Endif

			dbSelectArea("SD1")
			dbSkip()
		Enddo

	ElseIf SF1->F1_TIPO == "D"

		cProcess := "100000"
		cStatus  := "100000"
		oProcess := TWFProcess():New(cProcess,OemToAnsi("Relatorio de Devolucoes"))

		//Abre o HTML criado
		If IsSrvUnix()
			If File("/workflow/relatorio_de_devolucoes.htm")
				oProcess:NewTask("Gerando HTML","/workflow/relatorio_de_devolucoes.htm")
			Else
				FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/relatorio_de_devolucoes.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Return
			Endif
		Else
			oProcess:NewTask("Gerando HTML","\workflow\relatorio_de_devolucoes.htm")
		Endif
		oProcess:cSubject := "NF Devolucao Nº --> " + SF1->F1_SERIE  + " " + AllTrim(SF1->F1_DOC) + "  " + SM0->M0_NOMECOM
		oProcess:bReturn  := ""
		oHTML := oProcess:oHTML

		// Preenche os dados do cabecalho
		oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
		oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
		oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
		oHtml:ValByName("INSC","Inscrição Estadual: " + SM0->M0_INSC)
		oHtml:ValByName("CNOTA",SF1->F1_SERIE + " " + AllTrim(SF1->F1_DOC)  )

		dbSelectArea("SA1")
		dbSetOrder(1)
		If dbSeek(xFilial("SA1")+SF1->F1_FORNECE+SF1->F1_LOJA)
			oHtml:ValByName("CFORNECE",SF1->F1_FORNECE + " - " + AllTrim(SA1->A1_NOME) + " - Loja " + SF1->F1_LOJA)
		Endif

		dbSelectArea("SD1")
		dbSetOrder(1)
		dbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)
		While !Eof() .And. xFilial("SD1") == SD1->D1_FILIAL .And. SD1->D1_DOC == SF1->F1_DOC .And. ;
				SD1->D1_SERIE == SF1->F1_SERIE .And. SD1->D1_FORNECE == SF1->F1_FORNECE .And. ;
				SD1->D1_LOJA == SF1->F1_LOJA

			AAdd((oHtml:ValByName("it.item")),SD1->D1_ITEM)

			dbSelectArea("SB1")
			dbSetOrder(1)
			If dbSeek(xFilial('SB1')+SD1->D1_COD)
				AAdd((oHtml:ValByName("it.desc")),SD1->D1_COD + " " + SB1->B1_DESC)
			Else
				AAdd((oHtml:ValByName("it.desc")),SD1->D1_COD)
			Endif
			// Caso seja a filial Big CTBA, considero armazém 01 e 02 como normais, nas demais somente o 01
			If (SD1->D1_LOCAL $ "01#02" .And. cEmpAnt+cFilAnt == "0204") .Or. SD1->D1_LOCAL == "01"
				AAdd((oHtml:ValByName("it.obs")) ,SD1->D1_LOCAL+" MERCADORIA OK")
			Else
				AAdd((oHtml:ValByName("it.obs")) ,SD1->D1_LOCAL+ " MERCADORIA IMPROPRIA")
			Endif
			AAdd((oHtml:ValByName("it.qent")),Transform(SD1->D1_QUANT,'@E 999,999'))
			AAdd((oHtml:ValByName("it.vnf")) ,Transform(SD1->D1_VUNIT,'@E 999,999.99'))
			AAdd((oHtml:ValByName("it.tot")) ,Transform(SD1->D1_TOTAL,'@E 999,999.99'))
			AAdd((oHtml:ValByName("it.dnf")) ,DTOC(dDataBase))
			AAdd((oHtml:ValByName("it.cfop")), SD1->D1_CF)

			nTotal += (SD1->D1_QUANT * SD1->D1_VUNIT)

			AADD(aPedidos,{SD1->D1_NFORI})

			cQry := ""
			cQry += "SELECT D2_VALPROM/D2_QUANT AS VALUN, (D2_VALPTOS/D2_QUANT) AS VALPTO, F2_VEND1 AS VENDEDOR "
			cQry += "  FROM " + RetSqlName("SD2")+ " SD2, " + RetSqlName("SF2") + " SF2 "
			cQry += " WHERE SF2.D_E_L_E_T_ = ' ' "
			cQry += "   AND F2_DOC = D2_DOC "
			cQry += "   AND F2_SERIE = D2_SERIE "
			cQry += "   AND F2_FILIAL = D2_FILIAL "
			cQry += "   AND SD2.D_E_L_E_T_ = ' ' "
			cQry +=	"   AND (D2_VALPROM >0 OR D2_VALPTOS>0) "
			cQry += "   AND D2_COD = '" + SD1->D1_COD + "' "
			cQry += "   AND D2_LOJA = '" + SD1->D1_LOJA + "' "
			cQry += "   AND D2_CLIENTE = '" + SD1->D1_FORNECE + "' "
			cQry += "   AND D2_SERIE = '"+SD1->D1_SERIORI + "' "
			cQry += "   AND D2_DOC = '" + SD1->D1_NFORI + "' "
			cQry += "   AND D2_FILIAL = '"+ xFilial("SD2") + "' "

			// Mantida a opção de verificar se o alias está aberto, para evitar erros durante a inclusão de notas
			// Porém esta rotina fecha o alias QRY logo abaixo
			If Select("QRY") <> 0
				dbSelectArea("QRY")
				dbCloseArea()
			Endif

			TCQUERY cQry NEW ALIAS "QRY"
			dbSelectArea("QRY")
			dbGoTop()
			If !Empty(QRY->VALUN)
				// Caso tenha promocoes na devolucao
				RecLock("SZA",.T.)
				SZA->ZA_FILIAL 	:= xFilial("SZA")//SD1->D1_FILIAL
				SZA->ZA_DOC  	:= SD1->D1_DOC
				SZA->ZA_VEND	:= QRY->VENDEDOR
				SZA->ZA_PRODUTO := SD1->D1_COD
				SZA->ZA_DATA 	:= dDataBase
				SZA->ZA_CLIENTE := SD1->D1_FORNECE
				SZA->ZA_LOJA 	:= SD1->D1_LOJA
				SZA->ZA_QTDORI 	:= -SD1->D1_QUANT
				SZA->ZA_VALOR  	:= -SD1->D1_QUANT * QRY->VALUN
				SZA->ZA_PONTOS 	:= -SD1->D1_QUANT * QRY->VALPTO / 10
				SZA->ZA_OBSERV 	:= "DEVOLUCAO NF: " + SD1->D1_NFORI
				SZA->ZA_ITEM    := SD1->D1_ITEM
				SZA->ZA_TIPOMOV := "D"
				SZA->ZA_REFEREN := "T"
				SZA->ZA_ORIGEM  := "D"
				MsUnLock("SZA")
			Endif
			QRY->(dbCloseArea())

			cQry := ""
			cQry += "SELECT (D2_XVALPAG/D2_QUANT) AS VALUN, (D2_XVALMKT/D2_QUANT) AS VALMK, F2_VEND1 AS VENDEDOR "
			cQry += "  FROM " + RetSqlName("SD2")+ " SD2, " + RetSqlName("SF2") + " SF2 "
			cQry += " WHERE SF2.D_E_L_E_T_ = ' ' "
			cQry += "   AND F2_DOC = D2_DOC "
			cQry += "   AND F2_SERIE = D2_SERIE "
			cQry += "   AND F2_FILIAL = D2_FILIAL "
			cQry += "   AND SD2.D_E_L_E_T_ = ' ' "
			cQry +=	"   AND (D2_XVALPAG > 0 OR D2_XVALMKT > 0) "
			cQry += "   AND D2_COD = '" + SD1->D1_COD + "' "
			cQry += "   AND D2_LOJA = '" + SD1->D1_LOJA + "' "
			cQry += "   AND D2_CLIENTE = '" + SD1->D1_FORNECE + "' "
			cQry += "   AND D2_SERIE = '"+SD1->D1_SERIORI + "' "
			cQry += "   AND D2_DOC = '" + SD1->D1_NFORI + "' "
			cQry += "   AND D2_FILIAL = '"+ xFilial("SD2") + "' "

			// Mantida a opção de verificar se o alias está aberto, para evitar erros durante a inclusão de notas
			// Porém esta rotina fecha o alias QRY logo abaixo
			If Select("QRY") <> 0
				dbSelectArea("QRY")
				dbCloseArea()
			Endif

			TCQUERY cQry NEW ALIAS "QRY"
			dbSelectArea("QRY")
			dbGoTop()
			If !Empty(QRY->VALUN)
				// Caso tenha promocoes na devolucao
				RecLock("SZA",.T.)
				SZA->ZA_FILIAL 	:= xFilial("SZA")//SD1->D1_FILIAL
				SZA->ZA_DOC  	:= SD1->D1_DOC
				SZA->ZA_VEND	:= QRY->VENDEDOR
				SZA->ZA_PRODUTO := SD1->D1_COD
				SZA->ZA_DATA 	:= dDataBase
				SZA->ZA_CLIENTE := SD1->D1_FORNECE
				SZA->ZA_LOJA 	:= SD1->D1_LOJA
				SZA->ZA_QTDORI 	:= -SD1->D1_QUANT
				SZA->ZA_VALOR  	:= -SD1->D1_QUANT * QRY->VALUN
				SZA->ZA_PONTOS 	:= 0
				SZA->ZA_OBSERV 	:= "DEVOLUCAO NF: " + SD1->D1_NFORI
				SZA->ZA_ITEM    := SD1->D1_ITEM
				SZA->ZA_TIPOMOV := "D"
				SZA->ZA_REFEREN := "F"
				SZA->ZA_ORIGEM  := "D"
				MsUnLock("SZA")
			Endif
			If !Empty(QRY->VALMK)
				// Caso tenha promocoes na devolucao
				RecLock("SZA",.T.)
				SZA->ZA_FILIAL 	:= xFilial("SZA")//SD1->D1_FILIAL
				SZA->ZA_DOC  	:= SD1->D1_DOC
				SZA->ZA_VEND	:= QRY->VENDEDOR
				SZA->ZA_PRODUTO := SD1->D1_COD
				SZA->ZA_DATA 	:= dDataBase
				SZA->ZA_CLIENTE := SD1->D1_FORNECE
				SZA->ZA_LOJA 	:= SD1->D1_LOJA
				SZA->ZA_QTDORI 	:= -SD1->D1_QUANT
				SZA->ZA_VALOR  	:= -SD1->D1_QUANT * QRY->VALMK
				SZA->ZA_PONTOS 	:= 0
				SZA->ZA_OBSERV 	:= "DEVOLUCAO NF: " + SD1->D1_NFORI
				SZA->ZA_ITEM    := SD1->D1_ITEM
				SZA->ZA_TIPOMOV := "D"
				SZA->ZA_REFEREN := "M"
				SZA->ZA_ORIGEM  := "D"
				MsUnLock("SZA")
			Endif
			QRY->(dbCloseArea())
			// 31/10/2019 - Verifica se precisa criar os códigos de Declatórios de Ajuste
			If SD1->D1_FORMUL == "S"
				sfGrvF3K()
			Endif

			dbSelectArea("SD1")
			dbSkip()
		EndDo

		For x := 1 To Len(aPedidos)
			cPedidos += aPedidos[x][1] + ", "
		Next

		oHtml:ValByName("CPEDIDO",cPedidos)
		oHtml:ValByName("NTOTAL" ,Transform(nTotal,'@E 999,999.99'))

		oProcess:ClientName(Substr(cUsuario,7,15))

		cMailDest :="fiscal@brlub.com.br"
	
		cSendMail 	:= U_BFFATM15(cMailDest,"SF1100I")
		// Trata a limpeza dos e-mails repetidos 
		cRecebe := IIf(!Empty(cSendMail),cSendMail+";","")	
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
	

		If SF1->F1_FORMUL == "S"
			cNfdev := Substr(cPedidos,1,TamSX3("F1_DOC")[1])
		Else
			cNfdev := SF1->F1_DOC
		Endif

		oProcess:Start()
		oProcess:Finish()

		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()

		/*
		@ 200,1 TO 380,395 DIALOG oDlg3 TITLE OemToAnsi("Informacoes Gerais")
		@ 02,10 TO 070,190
		@ 10,018 Say "Número da nota de origem:"
		@ 10,100 Get cNfdev SIZE 40,10
		@ 75,150 BUTTON "Continuar" SIZE 40,15 ACTION Close(oDlg3)

		ACTIVATE MSDIALOG oDlg3 CENTERED

		Dbselectarea("SZ3")
		Dbsetorder(1)
		If dbseek(xFilial("SZ3")+SF1->F1_FORNECE+SF1->F1_LOJA+cNfdev)

			dbSelectArea("SZ3")
			RecLock("SZ3",.F.)
			SZ3->Z3_BXESCF   := SubStr(cUsuario,7,15)
			SZ3->Z3_BXDESCF := dDataBase
			SZ3->Z3_BXHESCF	:= time()
			MSUnLock("SZ3")
			MsgAlert("Baixa de autorização Escrita Fiscal efetuada!","Informacao")
		Else
			MsgAlert("Erro 2- Dados não gravados na autorização!!","Informacao")

		Endif
		*/

	Endif



Return

/*/{Protheus.doc} sfGrvF3K
// Verifica a necessidade criar os códigos de Ajustes Declaratórios na F3K
@author Marcelo Alberto Lauschner
@since 31/10/2019
@version 1.0
@return Nil 
@type function
/*/
Static Function sfGrvF3K()

	Local	aAreaOld	:= GetArea()
	Local	cCodProd	:= SD1->D1_COD
	Local	cCfopPv		:= SD1->D1_CF
	Local	cCodVlDec	:= ""
	Local	cCodAjust	:= ""
	Local	cTipValor	:= ""
	Local	cClasFis	:= Substr(SD1->D1_CLASFIS,2,2)
	Local	lGrvF3K		:= .F.

	// Se a CST estiver em Branco assume do TES
	If Empty(cClasFis)
		cClasFis	:= Posicione("SF4",1,xFilial("SF4") + SD1->D1_TES,"F4_SITTRIB")
	Endif

	// VENDA DIFERIMENTO PARCIAL
	If Alltrim(cCfopPv) $ "1202" .And. cClasFis == "51"
		cCodAjust	:= "RS052158"
		cCodVlDec	:= "0000170"
		lGrvF3K		:= .T.
		cTipValor	:= "4"
	ElseIf Alltrim(cCfopPv) $ "XXXXXXX" .And. cClasFis == "41"
		cCodAjust	:= "RS051514"
		cCodVlDec	:= "0001003"
		lGrvF3K		:= .T.
	Endif
	DbSelectArea("F3K")
	DbSetOrder(1)
	If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cClasFis)
		// Não faz nada por que já existe o cadastro

	ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes
		DbSelectArea("F3K")
		RecLock("F3K",.T.)
		F3K->F3K_FILIAL		:= xFilial("F3K")
		F3K->F3K_PROD		:= cCodProd
		F3K->F3K_CFOP		:= cCfopPv
		F3K->F3K_CODAJU		:= cCodAjust
		F3K->F3K_CST		:= cClasFis
		F3K->F3K_VALOR		:= "9"	// 9-Valor Contábil
		F3K->F3K_CODREF		:= cCodVlDec
		F3K->(MsUnlock())

		U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")

	Endif

	RestArea(aAreaOld)
Return
