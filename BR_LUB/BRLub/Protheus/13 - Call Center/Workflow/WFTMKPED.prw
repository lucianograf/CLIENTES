#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} WFTMKPED
Workflow de Pedido Oriundo do Callcente
@type function
@author Marcelo Alberto Lauschner
@since 17/09/2014
/*/
User Function WFTMKPED()

	sfAtriaLub()

Return

Static Function sfAtrialub()

	Local	aAreaOld	:= GetArea()
	Local 	aAreaSUB	:= SUB->(GetArea())
	Local 	aAreaSUA 	:= SUA->(GetArea())
	Local 	nPeso    	:= 0.00
	Local	cDescE4	:= ""
	Local 	nPrzMed 	:= 0.00
	Local 	nPxItem		:= Ascan(aHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})        	// Pega a posição do campo ITEM no aHeader
	Local	nPxCF		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_CF"})
	Local	cAssessor	:= ""
	Local	cRetAlc	:= ""
	Local	lPrcTabFull	:= Substr(SUA->UA_XEMPFXC,1,2) $ "LL" // Verifico se o pedido é oriundo do segmento Lust
	Local	aMotBloq	:= {}
	Local	aItems		:= aClone(aCols)
	Local	cCfop		:= ""
	Local	nTotCfop	:= 0
	Local	nI,x
	Local 	nTotOrc 	:= 0
	Local 	nTotDupl 	:= 0
	Local 	aCabPrd		:= {0,0,0} // 1- Produtos Lust 2-Produtos Pneus 3-Demais

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()


	DbSelectArea("SUA")

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA)

	cNea  		:= SA1->A1_SATFORT

	cProcess := "100000"
	cStatus  := "100000"

	oProcess := TWFProcess():New("PED001",OemToAnsi("Liberacao Pedido de Vendas"))

	If IsSrvUnix()
		If File("/workflow/lib_pedido.htm")
			oProcess:NewTask("Gerando HTML","/workflow/lib_pedido.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/lib_pedido.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\lib_pedido.htm")
	Endif

	oProcess:cSubject := "Liberação Pedido de Vendas --> " + SUA->UA_NUMSC5
	oProcess:bReturn  := ""

	oHTML := oProcess:oHTML

	oHtml:ValByName("NOMECOM"	,AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP"	,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP"	,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE"		,"Fone/Fax: " + SM0->M0_TEL)
	oHtml:ValByName("EMISSAO"	,SUA->UA_EMISSAO)

	If cNea >= "R4020" .and. cNea <= "R4052"
		lNea := .T.
		oHtml:ValByName("CLIENTE",SA1->A1_COD+"/"+SA1->A1_LOJA+" - " +SA1->A1_NOME+'<font color=#FF0000>'+" <<< CLIENTE NUCLEO NEA >>>>"+'</font>')
	Else
		lNea := .F.
		oHtml:ValByName("CLIENTE",SA1->A1_COD+"/"+SA1->A1_LOJA+" - " +SA1->A1_NOME + "  CGC/CPF:" +  Transform( SA1->A1_CGC, Iif(SA1->A1_PESSOA == "J","@r 99.999.999/9999-99","@r 999.999.999-99")))
	Endif

	DbSelectArea("SE4")
	DbSetOrder(1)
	DbSeek(xFilial("SE4")+SUA->UA_CONDPG)

	oHtml:ValByName("NUMERO"		,SUA->UA_NUMSC5)
	oHtml:ValByName("ENDERECO"	,SA1->A1_END + " - Bairro: " + SA1->A1_BAIRRO )
	oHtml:ValByName("MUNICIPIO"	,SA1->A1_MUN+" / " + SA1->A1_EST + " CEP:" + Transform(SA1->A1_CEP,"@R 99999-999"))
	oHtml:ValByName("USUARIO"	,cUserName)
	oHtml:ValByName("MINT"		,SUA->UA_MSGINT)
	oHtml:ValByName("MNOTA"		,SUA->UA_MENNOTA)


	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+SUA->UA_VEND)
	oHtml:ValByName("VENDEDOR","Vendedor--->>>"+SUA->UA_VEND+"-"+SA3->A3_NREDUZ)

	cAssessor  	:= SA3->A3_ACESSOR

	DbSelectArea("SF4")
	DbSetOrder(1)

	aSort(aItems,,,{|x,y| x[nPxCF]+x[nPxItem] < y[nPxCF]+y[nPxItem]})

	//Preenchendo itens
	For nI	:= 1 To Len(aItems)

		If !aItems[nI,Len(aHeader)+1]
			DbSelectArea("SUB")
			DbSetOrder(1)
			If DbSeek(xFilial("SUB") + M->UA_NUM + aItems[nI][nPxItem])

				If cCfop <> aItems[nI][nPxCF]
					If !Empty(cCfop)
						AAdd((oHtml:ValByName("P.IT")),"")
						AAdd((oHtml:ValByName("P.PRODUTO")),"")
						AAdd((oHtml:ValByName("P.ESTOQUE")),"")
						AAdd((oHtml:ValByName("P.QUANT")),"")
						AAdd((oHtml:ValByName("P.PRCTAB")),"")
						AAdd((oHtml:ValByName("P.PRCVEN")),"")
						AAdd((oHtml:ValByName("P.TAM")),"")

						// dbSelectArea("SX5")
						// dbSetOrder(1)
						// If dbSeek(xFilial("SX5")+"13"+cCfop)
						// 	AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop+"--"+SX5->X5_DESCRI)
						// Else
						// 	AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
						// Endif
						If !Empty(POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI"))
							cCfop += "--"+POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI")
						EndIf

						AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
						AAdd((oHtml:ValByName("P.VALOR"))		,Transform(nTotCfop,"@E 999,999,999.99"))
						nTotCfop := 0.00
					Endif
					cCfop := aItems[nI][nPxCF]
				Endif

				DbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+SUB->UB_PRODUTO)

				//aCabPrd		:= {0,0,0} // 1- Produtos Lust 2-Produtos Pneus 3-Demais
				If SB1->B1_CABO $ "MIC#CON#AGR#OUT#REL#BIK"
					aCabPrd[2]++
				ElseIf SB1->B1_CABO $ "LUS#ADT"
					aCabPrd[1]++
				Else
					aCabPrd[3]++
				Endif

				AAdd((oHtml:ValByName("P.IT")) 			,SUB->UB_ITEM)
				AAdd((oHtml:ValByName("P.PRODUTO" ))	,AllTrim(SUB->UB_PRODUTO))
				AAdd((oHtml:ValByName("P.DESCRICAO" )) 	,SB1->B1_STS+"-"+AllTrim(SB1->B1_DESC))

				dbSelectArea("SB2")
				dbSetOrder(1)
				If dbSeek(xFilial("SB2")+SUB->UB_PRODUTO+SUB->UB_LOCAL)
					AAdd((oHtml:ValByName("P.ESTOQUE"))	,SB2->B2_QATU-SB2->B2_RESERVA)
				Else
					AAdd((oHtml:ValByName("P.ESTOQUE"))	,"0000")
				Endif

				AAdd((oHtml:ValByName("P.QUANT" )) 		,Transform(SUB->UB_QUANT,"@E 999,999,999"))
				AAdd((oHtml:ValByName("P.PRCTAB" )) 		,Transform(SUB->UB_PRCTAB,"@E 999,999.99"))

				nImpostos	:= MaFisRet(nI,"IT_VALIPI")+MaFisRet(nI,"IT_VALSOL")

				If lPrcTabFull
					AAdd((oHtml:ValByName("P.VALOR"))		,Transform(SUB->UB_VLRITEM+nImpostos,"@E 999,999,999.99"))
					AAdd((oHtml:ValByName("P.PRCVEN" )) 	,Transform(SUB->UB_VRUNIT+(nImpostos/SUB->UB_QUANT),"@E 999,999.99"))
				Else
					AAdd((oHtml:ValByName("P.VALOR"))		,Transform(SUB->UB_VLRITEM,"@E 999,999,999.99"))
					AAdd((oHtml:ValByName("P.PRCVEN" )) 	,Transform(SUB->UB_VRUNIT,"@E 999,999.99"))
				Endif

				AAdd((oHtml:ValByName("P.TAM"))			,Transform(SUB->UB_XVLRTAM	,"@E 9,999.99"))

				nTotCfop 	+= SUB->UB_VLRITEM + Iif(lPrcTabFull,nImpostos,0)

				nPeso		+= SUB->UB_QUANT*SB1->B1_PESBRU
			Endif
			// Verifica se o item no pedido foi gravado conforme o orçamento televendas
			DbSelectArea("SC6")
			DbSetOrder(1)
			If DbSeek(xFilial("SC6") + SUB->UB_NUMPV + SUB->UB_ITEMPV )
				// Se não estiver gravado - gera uma linha com observação
			Else
				AAdd((oHtml:ValByName("P.IT")),SUB->UB_ITEMPV)
				AAdd((oHtml:ValByName("P.PRODUTO")),SUB->UB_PRODUTO)
				AAdd((oHtml:ValByName("P.ESTOQUE")),"")
				AAdd((oHtml:ValByName("P.QUANT")),Transform(SUB->UB_QUANT,"@E 999,999,999"))
				AAdd((oHtml:ValByName("P.PRCTAB")),"")
				AAdd((oHtml:ValByName("P.PRCVEN")),"")
				AAdd((oHtml:ValByName("P.TAM")),"")
				AAdd((oHtml:ValByName("P.DESCRICAO"))	,"PRODUTO COM PROBLEMA DE GRAVAÇÃO NO PEDIDO DE VENDA - NÃO GRAVOU O ITEM NO PEDIDO - SOMENTE FICOU NO ORÇAMENTO TELEVENDAS")
				AAdd((oHtml:ValByName("P.VALOR"))		,Transform(0,"@E 999,999,999.99"))
			Endif
			nTotOrc 	:= SUB->UB_VLRITEM
			
			DbSelectArea("SF4")
			DbSetOrder(1)
			If DbSeek(xFilial("SF4") + SUB->UB_TES )
				If SF4->F4_DUPLIC == "S"
					nTotDupl 	+= SUB->UB_VLRITEM
				Endif
			Endif
		Else

		Endif


	Next

	If !Empty(cCfop)
		AAdd((oHtml:ValByName("P.IT")),"")
		AAdd((oHtml:ValByName("P.PRODUTO")),"")
		AAdd((oHtml:ValByName("P.ESTOQUE")),"")
		AAdd((oHtml:ValByName("P.QUANT")),"")
		AAdd((oHtml:ValByName("P.PRCTAB")),"")
		AAdd((oHtml:ValByName("P.PRCVEN")),"")
		AAdd((oHtml:ValByName("P.TAM")),"")

		If !Empty(POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI"))
			cCfop += "--"+POSICIONE("SX5",1,xFilial('SX5')+"13"+cCfop,"X5_DESCRI")//FWGetSX5("13",cCfop)
		EndIf

		AAdd((oHtml:ValByName("P.DESCRICAO"))	,cCfop)
		AAdd((oHtml:ValByName("P.VALOR"))		,Transform(nTotCfop,"@E 999,999,999.99"))
		nTotCfop := 0.00
	Endif

	
	nVlrFrete	:= U_BFFATM22(SUA->UA_EMISSAO/*dInData*/,SUA->UA_CLIENTE/*cInCodCli*/,SUA->UA_LOJA/*cInLojCli*/,SUA->UA_TRANSP/*cInTransp*/,nTotOrc/*nInVlrMerc*/,nPeso/*nInPeso*/,SUA->UA_FRETE/*nInVlrFrete*/)

	lRetAlc	:= U_BFFATM21("SUA"  ,nTotDupl,nTotOrc,@nPrzMed,@cDescE4,aClone(aCols),aClone(aHeader),@cRetAlc,@aMotBloq,nVlrFrete)


	oHtml:ValByName("CONDICAO"		,cDescE4+" - Média: "+Transform(nPrzMed,"@E 999,999,999")+" Dias")

	oHtml:ValByName("TOTAL"			,Transform(MaFisRet(,"NF_TOTAL"),"@E 999,999,999.99"))
	oHtml:ValByName("TOTPESO"		,Transform(nPeso,"@E 999,999.99"))
	oHtml:ValByName("FATURA"		,Transform(MaFisRet(,"NF_BASEDUP"),"@E 999,999.99"))

	cObs     := ""
	cObsHtml := ""
	For x := 1 To Len(aMotBloq)
		cObs += aMotBloq[x][1]+Chr(13)+Chr(10)
		cObsHtml += aMotBloq[x][1]+"<p></p>"
	Next


	oHtml:ValByName("MOTIVOS",cObsHtml)

	oHtml:ValByName("RDMAKE"		,"WFTMKPED.PRW")
	oHtml:ValByName("DATA"			,Date())
	oHtml:ValByName("HORA"			,Time())


	// Atribui e-mail do vendedor da inclusão do Pedido de venda a partir do Televendas
	// 15/10/2015 - Chamado 12784
	If SUA->UA_TMK == "4"
		cEmail 	:= Alltrim(SA3->A3_EMAIL)
	Else
		cEmail	:= ""
	Endif

	cEmail 	+= ";"+Alltrim(SA3->A3_EMAIL) // Adiciona o Email do Vendedor - Chamado 24.371 07/02/2020 - Solicitação Jonathan
	cEmail	+= Iif(Empty(cEmail),"",";") + Alltrim(SA3->A3_MENS2) // Adiciona e-mail do Gerente

	//Posiciona no SA3 no cadastro de vendedor da Assesssora e pega o email dela.
	//aCabPrd		:= {0,0,0} // 1- Produtos Lust 2-Produtos Pneus 3-Demais
	cEmail += ";"+Alltrim(SA3->A3_EMTMK)


	// Verifica se o usuário do sistema tem e-mail cadastrado e concatena e-mail
	If !Empty(UsrRetMail(__cUserId))
		oHtml:ValByName("EMAILUSER",UsrRetMail(__cUserId))
		If !UsrRetMail(__cUserId) $ cEmail
			//oProcess:cCc := UsrRetMail(__cUserId)
			cEmail += ";"+UsrRetMail(__cUserId)
		Endif
	Endif

	// 10/07/2024 - Envia o também para um email customizado por parâmetro
	If !Empty(GetNewPar("BL_MAILWFP",""))
		cEmail += ";"+GetNewPar("BL_MAILWFP","")
	Endif

	oProcess:cTo := U_BFFATM15(cEmail,"WFTMKPED")
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

	U_GMCFGM01(Iif(INCLUI,"IP","AP"),SUA->UA_NUMSC5,"Enviado para: "+oProcess:cTo+ " Inclusão de pedido via Callcenter"+Chr(13)+Chr(10) ,FunName())

	MsgInfo("Workflow de Inclusão de Pedido enviado para: " + oProcess:cTo , ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Workflow")


	If lRetAlc
		U_BFFATA35("O"/*cZ9ORIGEM*/,SUA->UA_NUM/*cZ9NUM*/,"7"/*cZ9EVENTO*/,"Liberação automática do Pedido de Origem CallCenter sem restrição de alçadas"/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)
		U_BFFATA35("P"/*cZ9ORIGEM*/,SUA->UA_NUMSC5/*cZ9NUM*/,"7"/*cZ9EVENTO*/,"Liberação automática do Pedido de Origem CallCenter sem restrição de alçadas"/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)
	Else
		U_BFFATA35("P"/*cZ9ORIGEM*/,SUA->UA_NUMSC5/*cZ9NUM*/,"6"/*cZ9EVENTO*/,"Pedido de origem Callcenter com restrição de alçadas '"+cRetAlc+"'"/*cZ9DESCR*/,oProcess:cTo /*cZ9DEST*/,cUserName/*cZ9USER*/)

		// Efetua chamada do envio do Link de aprovação do pedido
		// Chamada foi transferida para o PE TMKVFIM
		//U_BFFATA30(.T./*lAuto*/,SUA->UA_NUMSC5/*cInPed*/,1/*nInPedOrc*/)

	Endif

	RestArea(aAreaOld)
	RestArea(aAreaSUA)
	RestArea(aAreaSUB)

Return

