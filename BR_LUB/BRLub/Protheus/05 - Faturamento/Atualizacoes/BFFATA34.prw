#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFFATA34
(Função de retorno da liberação ou rejeição do pedido de venda enviado para aprovação)
@author MarceloLauschner
@since 31/05/2014
@version 1.0
@param nInOpc, numérico, (Descrição do parâmetro)
@param oProcess, objeto, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA34(nInOpc,oProcess)
	
	ConOut("Processei função BFFATA34 "+cValToChar(nInOpc))
	If nInOpc == 2
		sfReturn(oProcess)
	ElseIf nInOpc == 1
		ConOut("Time-out para execução do processo")
	ElseIf nInOpc == 3
		sfRetSUA(oProcess)
	Endif
	// Efetua chamada de rotina de manutenção dos arquivos Htmls controlados pela tabela SZT
	sfMntSZT()
	
Return

/*/{Protheus.doc} sfReturn
(long_description)
@author MarceloLauschner
@since 31/05/2014
@version 1.0
@param oProcess, objeto, (Processo email original)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfReturn(oProcess)
	
	Local 	cNum      	:= oProcess:oHtml:RetByName('C5_NUM')
	Local 	cAprova   	:= oProcess:oHtml:RetByName('APROVACAO')
	Local 	cObs      	:= oProcess:oHtml:RetByName('C5_MSGEXP')
	Local 	cUser     	:= oProcess:oHtml:RetByName('USUARIO')
	Local 	cEmail    	:= oProcess:oHtml:RetByName('EMAILUSER')
	Local 	iW 
	Local	cQry 		:= ""
	Local	lRet		:= .T.
	Local	cXAlcada	:= ""
	Local	aAlcadas	:= {}
	Local	aSC6Recno	:= {}
	Local	cC6XAlcada	:= ""
	Local	lLib		:= .F.
	Local   iQ
	Local	cAuxAlc
	Local	cBkProcess
	Local	oProcessA
	Local	oProcessB
	Local	cHtmlModelo
	Local 	cProcess
	Local	cProcessB
	Local	cStatus
	Local	cSuperv
	Local	cGeren
	
	DbSelectArea("SC5")
	DbSetOrder(1)
	If !dbSeek(xFilial("SC5")+cNum)
		Return
	Endif
	
	cBkProcess	:= oProcess:fProcessID
	
	// Atualiza registro do nome do arquivo
	DbSelectArea("SZT")
	DbSetOrder(1)
	DbSeek(xFilial("SZT")+cBkProcess)
	While !Eof() .And. SZT->ZT_ID == Padr(cBkProcess,Len(SZT->ZT_ID))
		cObs	+= "/"+Alltrim(SZT->ZT_OBSERV)
		RecLock("SZT",.F.)
		SZT->ZT_DTLIB	:= Date()
		SZT->ZT_HRLIB	:= Time()
		SZT->ZT_STSRET	:= cAprova
		SZT->ZT_OBSERV	:= cObs
		MsUnlock()
		DbSkip()
	Enddo
	
	If cAprova == "N" .Or. SC5->C5_LIBEROK == "S" 	// pedido nao foi aprovado ou já está liberado
		
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessA := TWFProcess():New(cProcess,OemToAnsi("Pedido de Vendas nao Liberado"))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_pedido.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_pedido.htm"
		Endif
		//Abre o HTML criado
		oProcessA:NewTask("Pedido de Vendas Rejeitado " + cNum, cHtmlModelo , .T.)
		
		oProcessA:cSubject := "Pedido de Vendas "+IIf(SC5->C5_LIBEROK == "S","Analisado ","Rejeitado ") + cNum
		//oProcessA:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs
		
		oProcessA:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessA:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessA:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessA:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessA:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessA:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessA:oHTML:ValByName("tiporetorno"		,IIf(SC5->C5_LIBEROK == "S" ,"Análise ","Rejeição ")	)
		oProcessA:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessA:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessA:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessA:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessA:oHTML:ValByName("motivo"			,IIf(SC5->C5_LIBEROK == "S","Pedido de venda analisado, porém já liberado anteriormente!"," ") + oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessA:oHTML:ValByName("data"			,Date()		)
		oProcessA:oHTML:ValByName("hora"			,Time()		)
		oProcessA:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		
		// 21/09/2015 - Adiciona e-mail do Supervisor na rejeição de Pedido de Venda
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
			
		cSuperv	:= SA3->A3_SUPER
		cGeren	:= SA3->A3_GEREN
		
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cGeren)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
			
		If !Empty(cEmail)
			cEmail := U_BFFATM15(cEmail+";glauco@brlub.com.br","BFFATA34")
		Else
			cEmail :=  "marcelo@centralxml.com.br"
		Endif
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
		oProcessA:cTo := cRecebe
		oProcessA:Start()
		oProcessA:Finish()
		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
		
		// Grava Log
		U_GMCFGM01(	"FL"/*cTipo*/,;
			cNum/*cPedido*/,;
			cEmail,;//oProcess:oHtml:RetByName('EMAILUSER')/*cObserv*/,;
			FunName()/*cResp*/,;
			/*lBtnCancel*/,;
			oProcess:oHtml:RetByName('C5_MSGEXP')/*cMotDef*/,;
			.T./*lAutoExec*/,;
			cUser)
		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		
		U_BFFATA35("P"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"1"/*cZ9EVENTO*/,oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/)

		Return
		
	ElseIf cAprova == "A"
			
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessA := TWFProcess():New(cProcess,OemToAnsi("Pedido de Vendas " + cNum + " solicitado aprovação de alçada Gerência de Pricing"))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_pedido.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_pedido.htm"
		Endif
		//Abre o HTML criado
		oProcessA:NewTask("Pedido de Vendas Rejeitado " + cNum, cHtmlModelo , .T.)
		
		oProcessA:cSubject := "Pedido de Vendas " + cNum + " solicitado aprovação de alçada Gerência de Pricing"
		//oProcessA:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs
		
		oProcessA:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessA:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessA:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessA:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessA:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessA:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessA:oHTML:ValByName("tiporetorno"		,"Alçada "	)
		oProcessA:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessA:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessA:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessA:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessA:oHTML:ValByName("motivo"			,"Solicitada alçada de Gerência de Pricing. " + oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessA:oHTML:ValByName("data"			,Date()		)
		oProcessA:oHTML:ValByName("hora"			,Time()		)
		oProcessA:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		// 24/09/2015 - Adiciona e-mail do Supervisor na solicitação de alçada superior
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		cEmail	+= ";" + Alltrim(SA3->A3_EMTMK)
		
		cSuperv	:= SA3->A3_SUPER
		cGeren	:= SA3->A3_GEREN
		
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
			
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cGeren)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif

		If !Empty(cEmail)
			oProcessA:cTo := U_BFFATM15(cEmail+";glauco@brlub.com.br","BFFATA34")
		Else
			oProcessA:cTo :=  "marcelo@centralxml.com.br"
		Endif
		oProcessA:Start()
		oProcessA:Finish()
		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
		
		// Grava Log
		U_GMCFGM01(	"FL"/*cTipo*/,;
			cNum/*cPedido*/,;
			oProcess:oHtml:RetByName('EMAILUSER')/*cObserv*/,;
			FunName()/*cResp*/,;
			/*lBtnCancel*/,;
			oProcess:oHtml:RetByName('C5_MSGEXP')/*cMotDef*/,;
			.T./*lAutoExec*/,;
			cUser)
		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		U_BFFATA35("P"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"8"/*cZ9EVENTO*/,oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/,"A"/*cZ9PRCRET*/)
		
		
		Return
	ElseIf cAprova == "D"
		
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessA := TWFProcess():New(cProcess,OemToAnsi("Pedido de Vendas "+cNum+" solicitado aprovação de alçada Diretoria "))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_pedido.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_pedido.htm"
		Endif
		//Abre o HTML criado
		oProcessA:NewTask("Pedido de Vendas Rejeitado " + cNum, cHtmlModelo , .T.)
		
		oProcessA:cSubject := "Pedido de Vendas "+cNum+" solicitado aprovação de alçada Diretoria "
		//oProcessA:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs
		
		oProcessA:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessA:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessA:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessA:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessA:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessA:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessA:oHTML:ValByName("tiporetorno"		,"Alçada "	)
		oProcessA:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessA:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessA:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessA:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessA:oHTML:ValByName("motivo"			,"Solicitada a aprovação de alçada da Diretoria. " + oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessA:oHTML:ValByName("data"			,Date()		)
		oProcessA:oHTML:ValByName("hora"			,Time()		)
		oProcessA:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		
		// 24/09/2015 - Adiciona e-mail do Supervisor na solicitação de alçada superior
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		cEmail	+= ";" + Alltrim(SA3->A3_EMTMK)
		
		cSuperv	:= SA3->A3_SUPER
		cGeren	:= SA3->A3_GEREN
		
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cGeren)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif

		If !Empty(cEmail)
			oProcessA:cTo := U_BFFATM15(cEmail+";glauco@brlub.com.br","BFFATA34")
		Else
			oProcessA:cTo :=  "marcelo@centralxml.com.br"
		Endif
		oProcessA:Start()
		oProcessA:Finish()
		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
		
		// Grava Log
		U_GMCFGM01(	"LR"/*cTipo*/,;
			cNum/*cPedido*/,;
			oProcess:oHtml:RetByName('EMAILUSER')/*cObserv*/,;
			FunName()/*cResp*/,;
			/*lBtnCancel*/,;
			oProcess:oHtml:RetByName('C5_MSGEXP')/*cMotDef*/,;
			.T./*lAutoExec*/,;
			cUser)
		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		U_BFFATA35("P"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"9"/*cZ9EVENTO*/,oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/,"D"/*cZ9PRCRET*/)
		
		Return
	Endif
	
	DbSelectArea("SC5")
	DbSetOrder(1)
	If dbSeek(xFilial("SC5")+cNum)
		
		// 14/09/2016 - Adiciona e-mail do Supervisor na liberação do Pedido de Venda
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
			
		cSuperv	:= SA3->A3_SUPER
		cGeren	:= SA3->A3_GEREN
		
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cGeren)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		
		// Procura por todos os motivos de bloqueio de alçada no pedido
		cQry := "SELECT C6_XALCADA,R_E_C_N_O_ C6RECNO "
		cQry += "  FROM "+RetSqlName("SC6") + " C6 "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND C6_QTDENT < C6_QTDVEN "	// Somente Pendente
		cQry += "   AND C6_BLQ != 'R' "				// Não Eliminado Residuo
		cQry += "   AND C6_NUM = '"+cNum+"' "
		cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"'"
		
		TCQUERY cQry NEW ALIAS "QRSC6"
		
		While !Eof()
			cXAlcada	+= Alltrim(QRSC6->C6_XALCADA)+"#"
			Aadd(aSC6Recno,QRSC6->C6RECNO)
			DbSkip()
		Enddo
		QRSC6->(DbCloseArea())
		// Transformo os dados num Vetor
		// A6#B3#B1#A6#B3#
		cXAlcada 	:= StrTran(cXAlcada,"|","")
		aAlcadas	:= StrTokArr((Alltrim(cXAlcada)+"#"),"#")
		
		If !Empty(aAlcadas)
			cQry := "SELECT ZS_MOTIVO,ZS_IDUSR1,ZS_DESC "
			cQry += "  FROM "+RetSqlName("SZS") + " ZS "
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND ZS_MOTIVO IN("
			For iQ := 1 To Len(aAlcadas)
				If iQ > 1
					cQry += ","
				Endif
				cQry += "'"+ Alltrim(aAlcadas[iQ]) +"'"
			Next
			cQry += " )
			cQry += "   AND ZS_IDUSR1 = '"+cUser+"' "	// Usuário logado no Sistema
			cQry += "   AND ZS_FILIAL = '"+xFilial("SZS")+"'"
			
			TCQUERY cQry NEW ALIAS "QZS"
			
			While !Eof()
				For iQ := 1 To Len(aSC6Recno)
					DbSelectArea("SC6")
					DbGoto(aSC6Recno[iQ])
					//cC6XAlcada		:= SC6->C6_XALCADA
					//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO+"#","")
					//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO,"")
					//cC6XAlcada 	:= StrTran(cC6XAlcada,"|","")
					RecLock("SC6",.F.)
					//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
					//SC6->C6_XALCADA	:= cC6XAlcada
					SC6->C6_XALCADA		:= sfMotAlc(SC6->C6_XALCADA,QZS->ZS_MOTIVO)
					// Se já existir alguma alçada do item apenas concatena alçada
					If !Empty(SC6->C6_XLIBALC)
						// Se o liberador não constar ainda na lista
						If !(cUser $ SC6->C6_XLIBALC )
							cAuxAlc			:= Alltrim(SC6->C6_XLIBALC)
							SC6->C6_XLIBALC	:= cAuxAlc + "#"+cUser
						Endif
					Else
						SC6->C6_XLIBALC	:= SC5->C5_CLIENTE+"|"+SC5->C5_LOJACLI+"|"+SC5->C5_CONDPAG+"|"+SC6->C6_PRODUTO+"|"+ SC6->C6_TES+"|"+ cValToChar(SC6->C6_QTDVEN)+"|"+ cValToChar(SC6->C6_PRCVEN) + "|" + cUser
					Endif
					
					If Empty(SC6->C6_XALCADA)
						SC6->C6_BLQ	:= "N"
					Endif
					MsUnlock()
				Next
				lLib	:= .T.
				DbSelectArea("QZS")
				DbSkip()
			Enddo
			QZS->(DbCloseArea())
		Endif
	Endif
	
	// Verifica se deve ajustar os campos como pedido já liberado 
	If !lLib
		For iQ := 1 To Len(aSC6Recno)
		
			DbSelectArea("SC6")
			DbGoto(aSC6Recno[iQ])
		
			RecLock("SC6",.F.)
			//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
			// Se já existir alguma alçada do item apenas concatena alçada
			If !Empty(SC6->C6_XLIBALC)
				// Se o liberador não constar ainda na lista
				If !(cUser $ SC6->C6_XLIBALC )
					cAuxAlc			:= Alltrim(SC6->C6_XLIBALC)
					SC6->C6_XLIBALC	:= cAuxAlc+"#"+cUser
				Endif
			ElseIf Empty(SC6->C6_XALCADA)
				SC6->C6_XLIBALC	:= SC5->C5_CLIENTE+"|"+SC5->C5_LOJACLI+"|"+SC5->C5_CONDPAG+"|"+SC6->C6_PRODUTO+"|"+ SC6->C6_TES+"|"+ cValToChar(SC6->C6_QTDVEN)+"|"+ cValToChar(SC6->C6_PRCVEN) + "|" + cUser
			Endif
			
			If Empty(SC6->C6_XALCADA)
				SC6->C6_BLQ	:= "N"
			Endif
			MsUnlock()
			
			If !Empty(SC6->C6_XALCADA)
				U_WFGERAL("marcelo@centralxml.com.br","Pedido de Venda "+SC6->C6_NUM + " com problema de liberação" ,"|"+SC6->C6_XALCADA+"|"+SC6->C6_XLIBALC)
			Endif			
		Next
	Endif
	
	For iQ := 1 To Len(aSC6Recno)
		DbSelectArea("SC6")
		DbGoto(aSC6Recno[iQ])
		If SC6->C6_BLQ <> "N"
			U_GMCFGM01("LF",cNum,"Item "+SC6->C6_ITEM+"-"+SC6->C6_PRODUTO+" não foi liberado. Pendência de alçada "+SC6->C6_XALCADA,FunName()/*cResp*/,/*lBtnCancel*/,oProcess:oHtml:RetByName('C5_MSGEXP')/*cMotDef*/,.T./*lAutoExec*/,cUser)
			ConOut("BFFATA34.PRW - Pedido "+cNum+" Item "+SC6->C6_ITEM+"-"+SC6->C6_PRODUTO+" não foi liberado. Pendência de alçada "+SC6->C6_XALCADA )
			//MsgAlert("Item "+SC6->C6_ITEM+"-"+SC6->C6_PRODUTO+" não foi liberado. Pendência de alçada "+SC6->C6_XALCADA,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
			lRet	:= .F.
		Endif
	Next
	
	If lRet
		// Grava Log
		U_GMCFGM01(	"LF"/*cTipo*/,;
			cNum/*cPedido*/,;
			oProcess:oHtml:RetByName('DESTINATARIOS')/*cObserv*/,;
			FunName()/*cResp*/,;
			/*lBtnCancel*/,;
			oProcess:oHtml:RetByName('C5_MSGEXP')/*cMotDef*/,;
			.T./*lAutoExec*/,;
			cUser)
		
		ConOut("Chamando função de liberação do pedido Ma410LbNfs em BFFATA34.PRW")
		
		Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)
		
		U_GMCFGM01(	"LP"/*cTipo*/,;
			cNum/*cPedido*/,;
			oProcess:oHtml:RetByName('DESTINATARIOS')/*cObserv*/,;
			FunName()/*cResp*/,;
			/*lBtnCancel*/,;
			oProcess:oHtml:RetByName('C5_MSGEXP')/*cMotDef*/,;
			.T./*lAutoExec*/,;
			cUser)
		
		U_BFFATA35("P"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"4"/*cZ9EVENTO*/,oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/)
	Endif
	
	//ConOut("montando workflow")
	// Cria um novo processo...
	cProcess := "100000"
	cStatus  := "100000"
	oProcessB := TWFProcess():New(cProcess,OemToAnsi("Pedido de Vendas Liberado"))
	
	//Abre o HTML criado
	If IsSrvUnix()
		// Arquivo html template utilizado para montagem da aprovação
		cHtmlModelo	:= "/workflow/retorno_alcada_pedido.htm"
		If !File(cHtmlModelo)
			ConOut("Não localizou arquivo "+cHtmlModelo)
			Return
		Endif
	Else
		cHtmlModelo	:= "\workflow\retorno_alcada_pedido.htm"
	Endif
	//Abre o HTML criado
	oProcessB:NewTask("Pedido de Vendas Liberado " + cNum, cHtmlModelo , .T.)
	oProcessB:cSubject := "Pedido de Vendas Liberado " + cNum
	oProcessB:oHTML:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
	oProcessB:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oProcessB:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oProcessB:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
	oProcessB:oHTML:ValByName("USUARIO"		,oProcess:oHtml:RetByName('USUARIO')		)
	oProcessB:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
	
	oProcessB:oHTML:ValByName("tiporetorno"	,"Liberação "	)
	oProcessB:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
	oProcessB:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
	oProcessB:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
	oProcessB:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
	oProcessB:oHTML:ValByName("motivo"			,oProcess:oHtml:RetByName('C5_MSGEXP')	)
	
	oProcessB:oHTML:ValByName("data"			,Date()		)
	oProcessB:oHTML:ValByName("hora"			,Time()		)
	oProcessB:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
	
	If !Empty(cEmail)
		oProcessB:cTo :=  U_BFFATM15(cEmail,"BFFATA34")
	Else
		oProcessB:cTo := "marcelo@centralxml.com.br"
	Endif
	
	
	oProcessB:Start()
	oProcessB:Finish()
	
	ConOut("Pedido Liberado: "+cNum)
	
	
	oProcess:Finish()
	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()
	
Return






/*/{Protheus.doc} sfRetSUA
(long_description)
@author MarceloLauschner
@since 29/10/2014
@version 1.0
@param oProcess, objeto, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRetSUA(oProcess)
	
	Local 	cNum      	:= oProcess:oHtml:RetByName('C5_NUM')
	Local 	cAprova   	:= oProcess:oHtml:RetByName('APROVACAO')
	Local 	cObs      	:= oProcess:oHtml:RetByName('C5_MSGEXP')
	Local 	cUser     	:= oProcess:oHtml:RetByName('USUARIO')
	Local 	cEmail    	:= oProcess:oHtml:RetByName('EMAILUSER')
	Local	cQry 		:= ""
	Local	cXAlcada	:= ""
	Local	aAlcadas	:= {}
	Local	aSC6Recno	:= {}
	Local	cC6XAlcada	:= ""
	Local	lLib		:= .F.
	Local	cCtrlAlc	:= ""
	Local   j,iQ
	Local	cBkProcess
	Local	cProcess
	Local	oProcessA
	Local	oProcessB
	Local	oProcessC
	Local	cStatus
	Local	cHtmlModelo
	Local	cSuperv
	Local	cAuxAlc
	
	DbSelectArea("SUA")
	DbSetOrder(1)
	If !dbSeek(xFilial("SUA")+cNum)
		Return
	Endif
	
	cBkProcess	:= oProcess:fProcessID
	
	// Atualiza registro do nome do arquivo
	DbSelectArea("SZT")
	DbSetOrder(1)
	DbSeek(xFilial("SZT")+cBkProcess)
	While !Eof() .And. SZT->ZT_ID == Padr(cBkProcess,Len(SZT->ZT_ID))
		cObs	+= "/"+ Alltrim(SZT->ZT_OBSERV)
		RecLock("SZT",.F.)
		SZT->ZT_DTLIB	:= Date()
		SZT->ZT_HRLIB	:= Time()
		SZT->ZT_STSRET	:= cAprova
		SZT->ZT_OBSERV	:= cObs
		MsUnlock()
		DbSkip()
	Enddo
	
	If cAprova == "N" .Or. !Empty(SUA->UA_NUMSC5) 	// Orçamento não aprovado ou já transformado em pedido de venda
		
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessA := TWFProcess():New(cProcess,OemToAnsi("Orçamento Televendas não Liberado"))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_orcamento.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_orcamento.htm"
		Endif
		//Abre o HTML criado
		oProcessA:NewTask("Orçamento TeleVendas Rejeitado " + cNum, cHtmlModelo , .T.)
		
		oProcessA:cSubject := "Orçamento TeleVendas Rejeitado " + cNum
		//oProcessA:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs
		
		oProcessA:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessA:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessA:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessA:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessA:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessA:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessA:oHTML:ValByName("tiporetorno"		,"Rejeição "	)
		oProcessA:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessA:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessA:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessA:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessA:oHTML:ValByName("motivo"			,oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessA:oHTML:ValByName("data"			,Date()		)
		oProcessA:oHTML:ValByName("hora"			,Time()		)
		oProcessA:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		
		// 21/09/2015 - Adiciona e-mail do Supervisor na rejeição de Pedido de Venda
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SUA->UA_VEND)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
			// Verifica se o e-mail do Gerente está preenchido e envia alerta para o mesmo
			If !Empty(SA3->A3_MENS2)
				cEmail	+= ";" + Alltrim(SA3->A3_MENS2)
			Endif
		Endif
		cSuperv	:= SA3->A3_SUPER
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
			
		
		If !Empty(cEmail)
			oProcessA:cTo := U_BFFATM15(cEmail+";glauco@brlub.com.br","BFFATA34")
		Else
			oProcessA:cTo :=  "marcelo@centralxml.com.br"
		Endif
			
		oProcessA:Start()
		oProcessA:Finish()

		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
		
		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		U_BFFATA35("O"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"3"/*cZ9EVENTO*/,"Orçamento TeleVendas Rejeitado. " +oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/)
		
		Return
	ElseIf cAprova == "A"
			
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessA := TWFProcess():New(cProcess,OemToAnsi("Orçamento de Televendas nao Liberado"))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_orcamento.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_orcamento.htm"
		Endif
		//Abre o HTML criado
		oProcessA:NewTask( "Orçamento Televendas " + cNum + " solicitado aprovação de alçada Gerência de Pricing", cHtmlModelo , .T.)
		
		oProcessA:cSubject := "Orçamento Televendas " + cNum + " solicitado aprovação de alçada Gerência de Pricing"
		//oProcessA:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs
		
		oProcessA:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessA:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessA:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessA:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessA:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessA:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessA:oHTML:ValByName("tiporetorno"		,"Alçada "	)
		oProcessA:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessA:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessA:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessA:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessA:oHTML:ValByName("motivo"			,"Solicitada alçada de Gerência de Pricing " + oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessA:oHTML:ValByName("data"			,Date()		)
		oProcessA:oHTML:ValByName("hora"			,Time()		)
		oProcessA:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		
		// 24/09/2015 - Adiciona e-mail do Supervisor na solicitação de alçada superior
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SUA->UA_VEND)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		cEmail	+= ";" + Alltrim(SA3->A3_EMTMK)
		
		cSuperv	:= SA3->A3_SUPER
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
			
		If !Empty(cEmail)
			oProcessA:cTo := U_BFFATM15(cEmail+";glauco@brlub.com.br","BFFATA34")
		Else
			oProcessA:cTo :=  "marcelo@centralxml.com.br"
		Endif
		oProcessA:Start()
		oProcessA:Finish()
		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
		
		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		U_BFFATA35("O"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"8"/*cZ9EVENTO*/,oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/,"A"/*cZ9PRCRET*/)
		
		Return
	ElseIf cAprova == "D"
		
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessA := TWFProcess():New(cProcess,OemToAnsi("Pedido de Vendas nao Liberado"))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_orcamento.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_orcamento.htm"
		Endif
		//Abre o HTML criado
		oProcessA:NewTask("Orçamento Televendas "+cNum+" solicitado aprovação de alçada Diretoria ", cHtmlModelo , .T.)
		
		oProcessA:cSubject := "Orçamento Televendas "+cNum+" solicitado aprovação de alçada Diretoria "
		//oProcessA:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs
		
		oProcessA:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessA:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessA:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessA:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessA:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessA:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessA:oHTML:ValByName("tiporetorno"		,"Alçada "	)
		oProcessA:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessA:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessA:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessA:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessA:oHTML:ValByName("motivo"			,"Solicitada a aprovação de alçada da Diretoria " + oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessA:oHTML:ValByName("data"			,Date()		)
		oProcessA:oHTML:ValByName("hora"			,Time()		)
		oProcessA:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		
		// 24/09/2015 - Adiciona e-mail do Supervisor na solicitação de alçada superior
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SUA->UA_VEND)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		cEmail	+= ";" + Alltrim(SA3->A3_EMTMK)
		
		cSuperv	:= SA3->A3_SUPER
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
			
		
		If !Empty(cEmail)
			oProcessA:cTo := U_BFFATM15(cEmail+";glauco@brlub.com.br","BFFATA34")
		Else
			oProcessA:cTo :=  "marcelo@centralxml.com.br"
		Endif
		oProcessA:Start()
		oProcessA:Finish()
		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
		
		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		U_BFFATA35("O"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"9"/*cZ9EVENTO*/,oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/,"D"/*cZ9PRCRET*/)
		Return
	Endif
	
	DbSelectArea("SUA")
	DbSetOrder(1)
	If dbSeek(xFilial("SUA")+cNum)
		
		
		// 14/09/2016 - Adiciona e-mail do Supervisor na liberação do Orçamento
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SUA->UA_VEND)
			
		cSuperv	:= SA3->A3_SUPER
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cSuperv)
		If !Empty(SA3->A3_EMAIL)
			cEmail	+= ";" + Alltrim(SA3->A3_EMAIL)
		Endif
		
		// Procura por todos os motivos de bloqueio de alçada no pedido
		cQry := "SELECT UB_XALCADA,R_E_C_N_O_ UBRECNO "
		cQry += "  FROM "+RetSqlName("SUB") + " UB "
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND UB_NUM = '"+cNum+"' "
		cQry += "   AND UB_FILIAL = '"+xFilial("SUB")+"'"
		cQry += " ORDER BY UB_ITEM "
		
		TCQUERY cQry NEW ALIAS "QRSUB"
		
		While !Eof()
			cXAlcada	+= Alltrim(QRSUB->UB_XALCADA)+"#"
			Aadd(aSC6Recno,QRSUB->UBRECNO)
			DbSelectArea("QRSUB")
			DbSkip()
		Enddo
		QRSUB->(DbCloseArea())
		// Transformo os dados num Vetor
		// A6#B3#B1#A6#B3#
		// Verifica se existe o sinal de # para montagem do vetor por substr ou strtokarr
		If At("#",cXAlcada) <= 0
			For j := 1 To Len(cXAlcada)
				If Mod(j,2) == 1
					Aadd(aAlcadas,Substr(cXAlcada,j,2))
				Endif
			Next
		Else
			cXAlcada 	:= StrTran(cXAlcada,"|","")
			cXAlcada	+= "#"
			aAlcadas	:= StrTokArr(cXAlcada,"#")
		Endif
		
		If !Empty(aAlcadas)
			cQry := "SELECT ZS_MOTIVO,ZS_IDUSR1,ZS_DESC "
			cQry += "  FROM "+RetSqlName("SZS") + " ZS "
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND ZS_MOTIVO IN("
			For iQ := 1 To Len(aAlcadas)
				If iQ > 1
					cQry += ","
				Endif
				cQry += "'"+ Alltrim(aAlcadas[iQ]) +"'"
			Next
			cQry += " )
			cQry += "   AND ZS_IDUSR1 = '"+cUser+"' "	// Usuário logado no Sistema
			cQry += "   AND ZS_FILIAL = '"+xFilial("SZS")+"'"
			cQry += " ORDER BY ZS_MOTIVO "
			
			TCQUERY cQry NEW ALIAS "QZS"
			
			While !Eof()
				For iQ := 1 To Len(aSC6Recno)
					DbSelectArea("SUB")
					DbGoto(aSC6Recno[iQ])
					//cC6XAlcada	:= SUB->UB_XALCADA
					//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO+"#","")
					//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO,"")
					//cC6XAlcada 	:= StrTran(cC6XAlcada,"|","")
					RecLock("SUB",.F.)
					//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
					//SUB->UB_XALCADA	:= cC6XAlcada
					SUB->UB_XALCADA	:= sfMotAlc(SUB->UB_XALCADA,QZS->ZS_MOTIVO)
					// Se já existir alguma alçada do item apenas concatena alçada
					If !Empty(SUB->UB_XLIBALC)
						// Se o liberador não constar ainda na lista
						If !(cUser $ SUB->UB_XLIBALC )
							cAuxAlc			:= Alltrim(SUB->UB_XLIBALC)
							SUB->UB_XLIBALC	:= cAuxAlc+"#"+cUser
						Endif
					Else
						SUB->UB_XLIBALC	:= SUA->UA_CLIENTE+"|"+SUA->UA_LOJA+"|"+SUA->UA_CONDPG+"|"+SUB->UB_PRODUTO+"|"+SUB->UB_TES+"|"+ cValToChar(SUB->UB_QUANT)+"|"+ cValToChar(SUB->UB_VRUNIT) + "|" + cUser
					Endif
					If Empty(SUB->UB_XALCADA)
						SUB->UB_XPRCMIN	:= SUB->UB_VRUNIT
						SUB->UB_XPRCMAX	:= SUB->UB_VRUNIT
					Endif
					SUB->(MsUnlock())
					
					//If !Empty(SUB->UB_XALCADA)
					//	StaticCall(XMLDCONDOR,stSendMail,"informatica1@atrialub.com.br","Orçamento Televendas "+SUB->UB_NUM + " com problema de liberação" ,"|" + cXAlcada +"|"+SUB->UB_XALCADA+"|"+SUB->UB_XLIBALC)
					//Endif		
					
				Next
				lLib	:= .T.
				DbSelectArea("QZS")
				DbSkip()
			Enddo
			QZS->(DbCloseArea())
		Endif
	Endif
	
	/*
	If !lLib
		For iQ := 1 To Len(aSC6Recno)
			DbSelectArea("SUB")
			DbGoto(aSC6Recno[iQ])
			//cC6XAlcada	:= SUB->UB_XALCADA
			//cC6XAlcada 	:= StrTran(cC6XAlcada,"#","")
			//cC6XAlcada 	:= StrTran(cC6XAlcada,"|","")
			RecLock("SUB",.F.)
			//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
			//SUB->UB_XALCADA	:= cC6XAlcada
			SUB->UB_XALCADA	:= sfMotAlc(SUB->UB_XALCADA,QZS->ZS_MOTIVO)
			// Se já existir alguma alçada do item apenas concatena alçada
			If !Empty(SUB->UB_XLIBALC)
				// Se o liberador não constar ainda na lista
				If !(cUser $ SUB->UB_XLIBALC )
					cAuxAlc			:= Alltrim(SUB->UB_XLIBALC)
					SUB->UB_XLIBALC	:= cAuxAlc+"#"+cUser
				Endif
			Else
				SUB->UB_XLIBALC	:= SUA->UA_CLIENTE+"|"+SUA->UA_LOJA+"|"+SUA->UA_CONDPG+"|"+SUB->UB_PRODUTO+"|"+SUB->UB_TES+"|"+ cValToChar(SUB->UB_QUANT)+"|"+ cValToChar(SUB->UB_VRUNIT) + "|" + cUser
			Endif
			If Empty(SUB->UB_XALCADA)
				SUB->UB_XPRCMIN	:= SUB->UB_VRUNIT
				SUB->UB_XPRCMAX	:= SUB->UB_VRUNIT
			Endif
			MsUnlock()
			
			If !Empty(SUB->UB_XALCADA)
				StaticCall(XMLDCONDOR,stSendMail,"informatica1@atrialub.com.br","Orçamento Televendas "+SUB->UB_NUM + " com problema de liberação" ,"|"+SUB->UB_XALCADA+"|"+SUB->UB_XLIBALC)
			Endif			
		Next
	Endif
	*/
	// Percorro todos os itens do orçamento para ver se tem pendencia de alçadas ou não
	For iQ := 1 To Len(aSC6Recno)
		DbSelectArea("SUB")
		DbGoto(aSC6Recno[iQ])
		If !Empty(SUB->UB_XALCADA)
			cCtrlAlc	+= "Produto: " + SUB->UB_PRODUTO + " Alçada "+SUB->UB_XALCADA + Chr(13) + Chr(10)
		Endif
	Next
	
	// Não havendo nenhuma restrição de alçadas pendente
	If Empty(cCtrlAlc)
		
		U_BFFATA35("O"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"4"/*cZ9EVENTO*/,"Orçamento TeleVendas Liberado "+ oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/)
		
		
		//ConOut("montando workflow")
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessB := TWFProcess():New(cProcess,OemToAnsi("Orçamento TeleVendas Liberado"))
		
		//Abre o HTML criado
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_orcamento.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_orcamento.htm"
		Endif
		//Abre o HTML criado
		oProcessB:NewTask("Orçamento TeleVendas Liberado " + cNum, cHtmlModelo , .T.)
		oProcessB:cSubject := "Orçamento de Vendas Liberado " + cNum
		oProcessB:oHTML:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
		oProcessB:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessB:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessB:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessB:oHTML:ValByName("USUARIO"		,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessB:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessB:oHTML:ValByName("tiporetorno"	,"Liberação "	)
		oProcessB:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessB:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessB:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessB:oHTML:ValByName("A1_NOME"		,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessB:oHTML:ValByName("motivo"			,oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessB:oHTML:ValByName("data"			,Date()		)
		oProcessB:oHTML:ValByName("hora"			,Time()		)
		oProcessB:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		
		If !Empty(cEmail)
			oProcessB:cTo :=  U_BFFATM15(cEmail,"BFFATA34")
		Else
			oProcessB:cTo :=  "marcelo@centralxml.com.br"
		Endif
		
		
		oProcessB:Start()
		oProcessB:Finish()
		
		ConOut("Orçamento Liberado: "+cNum)
	Else
		// Cria um novo processo...
		cProcess := "100000"
		cStatus  := "100000"
		oProcessC := TWFProcess():New(cProcess,OemToAnsi("Orçamento Televendas não Liberado"))
		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			cHtmlModelo	:= "/workflow/retorno_alcada_orcamento.htm"
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			cHtmlModelo	:= "\workflow\retorno_alcada_orcamento.htm"
		Endif
		//Abre o HTML criado
		oProcessC:NewTask("Orçamento TeleVendas alçada insuficiente " + cNum, cHtmlModelo , .T.)
		
		oProcessC:cSubject := "Orçamento TeleVendas não aprovado por falta de alçadas " + cNum
		//oProcessC:cBody    := "O Pedido de Vendas " + cNum + " esta bloqueado para faturamento "+Chr(13)+cObs
		
		oProcessC:oHTML:ValByName("NOMECOM"			,AllTrim(SM0->M0_NOMECOM))
		oProcessC:oHTML:ValByName("ENDEMP"			,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcessC:oHTML:ValByName("COMEMP"			,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcessC:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcessC:oHTML:ValByName("USUARIO"			,oProcess:oHtml:RetByName('USUARIO')		)
		oProcessC:oHtml:ValByName("EMAILUSER"		,oProcess:oHtml:RetByName('emailuser') 	)
		
		oProcessC:oHTML:ValByName("tiporetorno"		,"Alçada insuficiente "	)
		oProcessC:oHTML:ValByName("C5_CLIENTE"		,oProcess:oHtml:RetByName('C5_CLIENTE')	)
		oProcessC:oHTML:ValByName("C5_LOJACLI"		,oProcess:oHtml:RetByName('C5_LOJACLI')	)
		oProcessC:oHTML:ValByName("A1_NOME"			,oProcess:oHtml:RetByName('A1_NOME')	)
		oProcessC:oHTML:ValByName("C5_NUM"			,oProcess:oHtml:RetByName('C5_NUM')	)
		oProcessC:oHTML:ValByName("motivo"			,cCtrlAlc + " - " + oProcess:oHtml:RetByName('C5_MSGEXP')	)
		
		oProcessC:oHTML:ValByName("data"			,Date()		)
		oProcessC:oHTML:ValByName("hora"			,Time()		)
		oProcessC:oHTML:ValByName("rdmake"			,FunName()+"."+ProcName(0)	)
		
		If !Empty(cEmail)
			oProcessC:cTo := U_BFFATM15(cEmail+";glauco@brlub.com.br;marcelo@centralxml.com.br","BFFATA34")
		Else
			oProcessC:cTo := U_BFFATM15("glauco@brlub.com.br;marcelo@centralxml.com.br","BFFATA34")
		Endif
		
		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		U_BFFATA35("O"/*cZ9ORIGEM*/,cNum/*cZ9NUM*/,"3"/*cZ9EVENTO*/,"Orçamento TeleVendas não aprovado por falta de alçadas. " + cCtrlAlc +oProcess:oHtml:RetByName('C5_MSGEXP')/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUser/*cZ9USER*/)
		
		oProcessC:Start()
		oProcessC:Finish()
		
		ConOut("Orçamento rejeitado: "+cNum)
		
	Endif
	oProcess:Finish()
	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()
	
Return


/*/{Protheus.doc} sfMntSZT
(Efetua rotina de manutenção de limpeza dos arquivos html dos workflows de aprovação)
@author MarceloLauschner
@since 02/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMntSZT()
	
	Local		aAreaOld		:= GetArea()
	Local		cQry			:= ""
	
	cQry += "SELECT CASE "
	cQry += "        WHEN ZT_STSRET = 'S' THEN 'A' "
	cQry += "        WHEN ZT_STSRET = 'N' THEN 'R' "
	cQry += "        WHEN ZT_STSRET = ' ' THEN 'E' "
	cQry += "       END STS, "
	cQry += "       ZT_FILE, "
	cQry += "       SUBSTRING(ZT_FILE,1,28) DIR_FILE,"
	cQry += "       R_E_C_N_O_ ZTRECNO "
	cQry += "  FROM " + RetSqlName("SZT")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND ZT_DATA <= '"+DTOS(Date()-30)+"' "
	cQry += "   AND ZT_STSRET IN(' ','S','N') " // S=Aprovado;N=Rejeitado;E=Del Html s/ret;A=Del Html Aprovado;R=Del Html Rejeitado
	cQry += "   AND ZT_FILIAL = '"+xFilial("SZT")+"'"
	
	TCQUERY cQry NEW ALIAS "QZT"
	
	While !Eof()
		
		If File(Alltrim(Lower(QZT->ZT_FILE)))
			ConOut(Alltrim(Lower(QZT->ZT_FILE)))
			// Apago o arquivo html
			fErase(Alltrim(Lower(QZT->ZT_FILE)))
			// Atualizo como já processado
		Endif
		
		DbSelectArea("SZT")
		DbGoto(QZT->ZTRECNO)
		RecLock("SZT",.F.)
		SZT->ZT_STSRET := QZT->STS
		MsUnlock()
		
		DbSelectArea("QZT")
		Dbskip()
	Enddo
	QZT->(DbCloseArea())
	
	RestArea(aAreaOld)
	
Return

/*/{Protheus.doc} sfMotAlc
//Função que remove corretamente os bloqueios de alçadas 
@author Marcelo Alberto Lauschner 
@since 29/06/2018
@version 1.0
@return cReturn 	, characters, String com a alçada final podendo ser vazia. Para os dois exemplos de parametro abaixo o retorno será "A3#E9#E4#"
@param 	cInAlcadas	, characters, Lista de motivos de bloqueios. Exemplo "A3#B9#E9#E4"
@param 	cInMotOk	, characters, Código do Motivo que será removido. Exemplo "B9". 
@type function
/*/
Static Function sfMotAlc(cInAlcadas,cInMotOk)
	
	Local	cRetAlcada	:= ""
	Local	nLenItem	:= 0
	Local	aItem		:= {}
	Local	iZ 
	Local	lRecursivo	:= .F. 
	//Len(aItem)
	cInAlcadas	:= StrTran(cInAlcadas,"|","")
	If "#" $ cInAlcadas
		aItem		:= StrTokArr(cInAlcadas+"#","#")
		nLenItem	:= Len(aItem)
		
		For iZ := 1 To nLenItem
			If aItem[iZ] == cInMotOk
				aDel(aItem,iZ)
				aSize(aItem,nLenItem-1)
				nLenItem	:= Len(aItem)
				lRecursivo	:= .T. 
				Exit
			Endif
		Next
		For iZ := 1 To Len(aItem)
			If !Empty(aItem[iZ])
				cRetAlcada	+= aItem[iZ]+"#"
			Endif
		Next
		If lRecursivo
			cRetAlcada	:= sfMotAlc(cRetAlcada,cInMotOk)		
		Endif
	ElseIf !Empty(cInAlcadas)
		For iZ := 1 To Len(cInAlcadas) Step 2 
			cRetAlcada	+= Substr(cInAlcadas,iZ,2) + "#"
		Next
		cRetAlcada	:= sfMotAlc(cRetAlcada,cInMotOk)	
	Endif
				
Return cRetAlcada
