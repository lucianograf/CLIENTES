#INCLUDE "protheus.CH"
#INCLUDE "TOPCONN.CH"
#include "ap5mail.ch"

/*/{Protheus.doc} FINA200
(Ponto de Entrada Retorno Bancario Efetua verificação se os titulos foram pagos com atraso e se houve desconto excessivo)
@author MarceloLauschner
@since 29/09/2011
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FINA200()
	
	Local	aAreaOld	:= GetArea()
	Local	nValJurAtr	:= 0
	Local	cMsgMail	:= ""
	Local	nE1_ValJu	:=  Iif(SE1->E1_VALJUR > 0,SE1->E1_VALJUR,SE1->E1_SALDO*0.0027)
	Local	nE1_Saldo	:=  SE1->E1_SALDO +SE1->E1_ACRESC-SE1->E1_DECRESC
	
	
	// { aValores, nTotAbat, nTotAbImp } )
	
	//Paramixb[1,1]  - Número do título
	//Paramixb[1,2]  - Data da Baixa
	//Paramixb[1,3]  - Tipo do Título
	//Paramixb[1,4]  - Nosso Número
	//Paramixb[1,5]  - Valor da Despesa
	//Paramixb[1,6]  - Valor do Desconto
	//Paramixb[1,7]  - Valor do Abatimento
	//Paramixb[1,8]  - Valor Recebido
	//Paramixb[1,9]  - Valor dos Juros
	//Paramixb[1,10] - Valor da Multa
	//Paramixb[1,11] - Valor de Outras Despesas
	//Paramixb[1,12] - Valor do Crédito
	//Paramixb[1,13] - Data do Crédito
	//Paramixb[1,14] - Ocorrência
	//Paramixb[1,15] - Motivo da Baixa
	//Paramixb[1,16] - Linha inteira -> retornada pelo banco
	
	//Paramixb[2]
	//Paramixb[3]
	
	
	//rede log nao executa
	If Alltrim(SM0->M0_CODIGO) == '06'
		Return 
	Endif
	
	
	If Type("ParamIxb[1]") <> "A"
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "FINA200 -> Variável ParamIxb[1] não é array"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		RestArea(aAreaOld)
		Return
	Endif
	
	If Len(ParamIxb[1]) < 14
		RestArea(aAreaOld)
		Return
	Endif
	
	If AllTrim( Paramixb[1,14] ) == "06"		//liquidação normal
		// Melhoria feita em 21/10/2014
		// Quando a data de baixa for menor que a data de crédito
		/*
		// JEAN - 21/07/2022 - Lori sempre pressiona "não" nessa mensagem
		If Type("dBaixa") <> "U" .And. Type("dDataCred") <> "U"
			If	dBaixa < dDataCred
				If MsgYesNo("Foi encontrada diferença entre a Data da Baixa e a Data Crédito para a baixa do título '"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"'"+Chr(13)+Chr(10)+;
						"Deseja forçar o ajuste da Data da Baixa igual a Data do Crédito?", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					dBaixa	:= dDataCred
					sfSendMail( "credito1@atrialub.com.br;cobranca2@atrialub.com.br;cobranca1@atrialub.com.br", "Divergência na 'Data Baixa' menor que a 'Data Crédito' '"+Alltrim(SM0->M0_NOMECOM)+"' Título:'"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"' ", cMsgMail)
				Endif
			Endif
		Endif
		*/
		// Verifico se o titulo foi pago com atraso e calcula o juros
		If Paramixb[1,2] > SE1->E1_VENCREA
			nE1_ValJu       :=  Round((Paramixb[1,2] - SE1->E1_VENCREA) * nE1_ValJu,2)
			
			If Paramixb[1,9] < nE1_ValJu
				cMsgMail	+= "<<<<<<<   Pagamento em Atraso com Juros Abaixo do Devido   >>>>>>> "+Chr(13)+Chr(10)
				cMsgMail	+= "Título  		: '"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+"' "+Chr(13)+Chr(10)
				cMsgMail	+= "Cliente 		: '"+SE1->E1_CLIENTE+"/"+SE1->E1_LOJA+"-"+SE1->E1_NOMCLI+Chr(13)+Chr(10)
				cMsgMail 	+= "Valor Pago		: R$ "+Transform(Paramixb[1,8],PesqPict("SE5","E5_VALOR"))+Chr(13)+Chr(10)
				cMsgMail	+= "Juros Pagos 	: R$ "+Transform(Paramixb[1,9],PesqPict("SE1","E1_VALJUR"))+Chr(13)+Chr(10)
				cMsgMail	+= "Juros Devidos	: R$ "+Transform(nE1_ValJu,PesqPict("SE1","E1_VALJUR"))+Chr(13)+Chr(10)
				cMsgMail	+= ""+Chr(13)+Chr(10)
				
				nValJurAtr	+= nE1_ValJu - Paramixb[1,9]
				
			Endif
			
			// Além de pagar com atraso se concedeu desconto indevido
			If (Paramixb[1,6]+Paramixb[1,7]) > 0 //(SE1->E1_VALOR*SE1->E1_DESCFIN)/100
				cMsgMail	+= "<<<<<<<   Desconto concedido indevidamente - Atraso no pagamento >>>>>>> "+Chr(13)+Chr(10)
				cMsgMail	+= "Título  		: '"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+"' "+Chr(13)+Chr(10)
				cMsgMail	+= "Cliente 		: '"+SE1->E1_CLIENTE+"/"+SE1->E1_LOJA+"-"+SE1->E1_NOMCLI+Chr(13)+Chr(10)
				cMsgMail	+= "Desc.Pagamento	: R$ "+Transform(Paramixb[1,6],PesqPict("SE1","E1_VALJUR"))+Chr(13)+Chr(10)
				cMsgMail	+= "Abat.Pagamento	: R$ "+Transform(Paramixb[1,7],PesqPict("SE1","E1_VALJUR"))+Chr(13)+Chr(10)
				cMsgMail	+= ""+Chr(13)+Chr(10)
				nValJurAtr	+= Paramixb[1,6]
				nValJurAtr 	+= Paramixb[1,7]
				cMsgMail	+= "<<<<<<<   Ressarcimento de Valores >>>>>>> "+Chr(13)+Chr(10)
				cMsgMail	+= "Soma Ressarcimento	: R$ "+Transform(nValJurAtr,PesqPict("SE1","E1_VALOR"))+Chr(13)+Chr(10)
				cMsgMail	+= ""+Chr(13)+Chr(10)
				
				sfAlert(1,'Desconto concedido',(Paramixb[1,6]+Paramixb[1,7]),cMsgMail)
				
			Endif
			
			If !Empty(cMsgMail)
				cMsgMail	+= "<<<<<<<   Texto para montagem da Carta >>>>>>> "+Chr(13)+Chr(10)
				cMsgMail	+= ""+Chr(13)+Chr(10)
				cMsgMail	+= "Informamos que a NF "+SE1->E1_NUM+"- Nosso Número: "+Alltrim(SE1->E1_NUMBCO)+" Cliente "+Alltrim(Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NOME"))+Chr(13)+Chr(10)
				cMsgMail	+= "com emissão em "+DTOC(SE1->E1_EMISSAO)+" e Vencimento "+DTOC(SE1->E1_VENCREA)+" no valor de R$ "+Transform(SE1->E1_VALOR ,PesqPict("SE1","E1_VALOR"))+","+Chr(13)+Chr(10)
				If SE1->E1_DESCFIN > 0
					cMsgMail	+= "com o desconto do acordo comercial de "+Alltrim(Transform(SE1->E1_DESCFIN ,PesqPict("SE1","E1_DESCFIN"))) +"% para pagamento pontual "
				Endif
				cMsgMail	+= "foi paga pelo cliente em atraso no dia "+Alltrim(DTOC(Paramixb[1,2]))
				
				If Paramixb[1,6] > 0
					cMsgMail	+= " com desconto indevido de R$ "+Alltrim(Transform(Paramixb[1,6],PesqPict("SE1","E1_VALOR")))
				Endif
				If Paramixb[1,7] > 0
					cMsgMail	+= " com abatimento indevido de R$ "+Alltrim(Transform(Paramixb[1,7],PesqPict("SE1","E1_VALOR")))
				Endif
				If Paramixb[1,9] < nE1_ValJu
					cMsgMail	+= " sem os devidos juros no valor de R$"+Alltrim(Transform(nE1_ValJu,PesqPict("SE1","E1_VALJUR")))
				Endif
				
				cMsgMail	+= "."+Chr(13)+Chr(10)
				cMsgMail    += "Solicitamos a sua verificação nos creditando o valor de R$"+ Transform(nValJurAtr,PesqPict("SE1","E1_VALOR"))+" - Banco "+cBanco+" Ag. "+cAgencia+" Conta "+cConta +"."
				cMsgMail	+= Chr(13)+Chr(10)+Chr(13)+Chr(10)
				
				sfAltTit("Atraso/Dif.Baixa R$ "+Alltrim(Transform(nValJurAtr,PesqPict("SE1","E1_VALOR"))))
				
			Endif
		Else
			// Verifico se houve desconto concedido acima do permitido
			If Round(Paramixb[1,6]+Paramixb[1,7],2) > Round((SE1->E1_VALOR*SE1->E1_DESCFIN)/100,2) .and. Round(Paramixb[1,6]+Paramixb[1,7],2) > SE1->E1_DECRESC
				cMsgMail	+= "<<<<<<<   Desconto divergente do esperado  >>>>> "+Chr(13)+Chr(10)
				cMsgMail	+= "Título  		: '"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+"' "+Chr(13)+Chr(10)
				cMsgMail	+= "Cliente 		: '"+SE1->E1_CLIENTE+"/"+SE1->E1_LOJA+"-"+SE1->E1_NOMCLI+Chr(13)+Chr(10)
				cMsgMail	+= "Desc.Pagamento	: R$ "+Transform(Paramixb[1,6],PesqPict("SE1","E1_VALOR"))+Chr(13)+Chr(10)
				cMsgMail	+= "Abat.Pagamento	: R$ "+Transform(Paramixb[1,7],PesqPict("SE1","E1_VALOR"))+Chr(13)+Chr(10)				
				cMsgMail	+= "Desconto Devido	: R$ "+Transform((SE1->E1_VALOR*SE1->E1_DESCFIN)/100 ,PesqPict("SE1","E1_VALOR"))+Chr(13)+Chr(10)
				cMsgMail	+= ""+Chr(13)+Chr(10)
				nValJurAtr	+= (Paramixb[1,6]+Paramixb[1,7]) - (SE1->E1_VALOR*SE1->E1_DESCFIN)/100
				cMsgMail	+= "<<<<<<<   Ressarcimento de Valores >>>>> "+Chr(13)+Chr(10)
				cMsgMail	+= "Soma Ressarcimento	: R$ "+Transform(nValJurAtr,PesqPict("SE1","E1_VALOR"))+Chr(13)+Chr(10)
				cMsgMail	+= ""+Chr(13)+Chr(10)
				cMsgMail	+= "<<<<<<<   Texto para montagem da Carta >>>>>>> "+Chr(13)+Chr(10)
				cMsgMail	+= ""+Chr(13)+Chr(10)
				
				cMsgMail	+= "Informamos que a NF "+SE1->E1_NUM+"- Nosso Número: "+Alltrim(SE1->E1_NUMBCO)+" Cliente "+Alltrim(Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NOME"))+Chr(13)+Chr(10)
				cMsgMail	+= "com emissão em "+DTOC(SE1->E1_EMISSAO)+" e Vencimento "+DTOC(SE1->E1_VENCREA)+" no valor de R$ "+Transform(SE1->E1_VALOR ,PesqPict("SE1","E1_VALOR"))+","+Chr(13)+Chr(10)
				cMsgMail	+= "com direito ao desconto do acordo comercial de "+Alltrim(Transform(SE1->E1_DESCFIN ,PesqPict("SE1","E1_DESCFIN"))) +"% para pagamento pontual. "+Chr(13)+Chr(10)
				cMsgMail	+= "Porém foi paga pelo cliente em no dia "+DTOC(Paramixb[1,2])+" com desconto de R$ "+Alltrim(Transform(Paramixb[1,6],PesqPict("SE1","E1_VALOR")))+" "+Chr(13)+Chr(10)
				cMsgMail	+= " e com abatimento de R$ "+Alltrim(Transform(Paramixb[1,7],PesqPict("SE1","E1_VALOR")))+", acima do permitido."+Chr(13)+Chr(10)
				cMsgMail    += "Solicitamos sua verificação nos creditando o valor de R$"+ Alltrim(Transform(nValJurAtr,PesqPict("SE1","E1_VALOR")))+" - Banco: "+cBanco+" Ag: "+cAgencia+" Conta: "+cConta +"."
				cMsgMail	+= Chr(13)+Chr(10)
				
				sfAlert(1,'Desconto concedido',(Paramixb[1,6]+Paramixb[1,7]),cMsgMail)
				
				sfAltTit("DIF.DESCONTO DEVEDOR$ "+Alltrim(Transform(nValJurAtr,PesqPict("SE1","E1_VALOR"))))
			Endif
		Endif
		If !Empty(cMsgMail)
			sfSendMail( "credito1@atrialub.com.br;cobranca1@atrialub.com.br;cobranca2@atrialub.com.br", "Divergência na Baixa '"+Alltrim(SM0->M0_NOMECOM)+"' Título:'"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"' ", cMsgMail)
		Endif
	Endif
	
	RestArea(aAreaOld)
	
Return


//altera o valor do título
Static Function sfAltTit(_cObs)
	
	DbSelectArea("SE1")
	RecLock( "SE1", .F. )
	SE1->E1_HIST :=	Substr(_cObs +"|"+ AllTrim(SE1->E1_HIST),1,Len(SE1->E1_HIST) )
	MsUnlock()
	
Return


Static Function sfSendMail( cMailTo, cAssunto, cMensagem)

	Local	aAreaOld 		:= GetArea()
	Local 	lOk 		:= .F.
	Local	lAutOk 		:= .F.
	Local	lSendOk 	:= .T.

	Local cMailServer := AllTrim(GetNewPar("MV_RELSERV"," "))        // Servidor utilizado para envio do e-mail
	Local cMailConta  := AllTrim(GetNewPar("MV_RELACNT"," "))        // Conta utilizada para envio
	Local cMailSenha  := AllTrim(GetNewPar("MV_RELPSW" ," "))        // Senha da conta de envio
	Local lSmtpAuth   := GetNewPar("MV_RELAUTH", .F.)                // Verifica se deve realizar autenticação
	Local nTimeOut    := GetNewPar("MV_RELTIME", 120)                // Tempo de Espera antes de abortar a Conexão
	Local cUserAut    := Alltrim(GetNewPar("MV_RELAUSR",cMailConta)) // Usuário para Autenticação no Servidor de Email
	Local cSenhAut    := Alltrim(GetNewPar("MV_RELAPSW",cMailSenha)) // Senha para Autenticação no Servidor de Email
	Local lRetMail 		:= .T.

	// Campos a serem repassados no e-mail
	Default cMailTo   := Space(20)
	Default cAssunto  := Space(20)
	Default cMensagem := Space(20)

	cMailTo := U_BFFATM15(cMailTo,"BIG005")


	CONNECT SMTP SERVER cMailServer ACCOUNT cMailConta PASSWORD cMailSenha TIMEOUT nTimeOut RESULT lOk

// Valida existencia de campos necessarios para o envio do e-mail
	If !Empty(cMailServer) .And. !Empty(cMailConta)
		// Verifica autenticação no servidor descrito, se necessario
		If !lAutOk
			If lSmtpAuth
				If !(lAutOk := MailAuth(cUserAut,cSenhAut))
					cMsgSend := "Falha na autenticação do usuário no provedor de e-mail"
					lRetMail := .F.
				Endif
			Else
				lAutOk := .T.
			EndIf
		EndIf

		If lRetMail // Caso a autenticação tenha sido efetuada corretamente.
			If lOk  // Caso a conexao com o servidor, esteja estabelecida, e possibilite o envio do e-mail
				SEND MAIL FROM cMailConta TO cMailTo  SUBJECT cAssunto BODY cMensagem RESULT lSendOk  // Efetua envio do e-mail

				If !lSendOk
					Get MAIL ERROR cError // Verifica erro indicado pelo servidor, no ato do envio do e-mail
				Endif

				// Armazena informações para retorno
				cMsgSend := If(lSendOk, "E-mail enviado com sucesso!", cError) // "E-mail enviado com sucesso!"
				lRetMail := lSendOk
			Else
				cMsgSend := "Erro na conexão com o servidor SMTP." + CHR(13) + CHR(10) + ; // "Erro na conexão com o servidor SMTP."
				"Verifique configurações e autenticações do servidor de e-mail." // "Verifique configurações e autenticações do servidor de e-mail."
				lRetMail := .F.
			EndIf
		Endif

		DISCONNECT SMTP SERVER // Finaliza conexao com servidor de e-mail
	Else
		cMsgSend := "As configurações para o acesso ao servidor de e-mail estão incorretas." + CHR(13) + CHR(10) + ; // "As configurações para o acesso ao servidor de e-mail estão incorretas."
		"Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW" // "Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW"
		lRetMail := .F.
	EndIf

	RestArea(aAreaOld)

Return

Static Function sfAlert(nTipOcorr,cOcorr,nValOcorr,cMsgOcorr)
	
	Local oDlgBan
	Local aAreaOld		:=	GetArea()
	Local aAreaSA6		:=  SA6->(GetArea())
	Local XDESCONTO  	:= 1
	Local nVlrDesc      := nValOcorr
	
	DEFINE MSDIALOG oDlgBan TITLE "Cliente: " + SE1->E1_CLIENTE + "/" + SE1->E1_LOJA + " - " + SE1->E1_NOMCLI FROM 0, 0 TO 240, 400 PIXEL
	@ 010, 010 SAY "Título:" of oDlgBan pixel
	@ 010, 050 GET (SE1->E1_PREFIXO+"/"+SE1->E1_NUM+"-"+SE1->E1_PARCELA) Size 050,010 WHEN .F. of oDlgBan pixel
	@ 010, 110 SAY "Saldo R$: " of oDlgBan pixel
	@ 010, 145 GET SE1->E1_SALDO Picture "@E 999,999.99" Size 050,010 WHEN .F. of oDlgBan pixel
	@ 025, 010 SAY "Ocorrência:" of oDlgBan pixel
	@ 025, 050 GET cOcorr Size 190,010 WHEN .F. of oDlgBan pixel
	@ 040, 010 SAY "Valor R$:" of oDlgBan pixel
	@ 040, 050 GET nVlrDesc Picture "@E 999,999.99" Size 050,010 WHEN .T. Valid(Iif(nTipOcorr ==  XDESCONTO,nVlrDesc <= nValOcorr,.T.)) of oDlgBan pixel
	@ 055, 010 Get cMsgOcorr Size 130,40 When .F. of oDlgBan pixel
	@ 055, 010 GET oMemo Var cMsgOcorr Memo SIZE 190,40 OF oDlgBan PIXEL 
	
	If nTipOcorr ==  XDESCONTO
		// Atribui o valor do desconto igual ao valor da ocorrencia
		@ 100, 050 Button "Desconto"  Action (nDescont := nValOcorr,oDlgBan:End()) of oDlgBan pixel
	Endif
	@ 100, 160 Button "Cancelar" Action oDlgBan:End() of oDlgBan pixel
	
	ACTIVATE MSDIALOG oDlgBan CENTERED
	
	RestArea( aAreaOld )
	RestArea( aAreaSA6 )
	
Return
