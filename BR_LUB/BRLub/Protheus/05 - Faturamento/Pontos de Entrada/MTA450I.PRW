#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"
#include "ap5mail.ch"


Static lFirstSC9	:= .T.
Static cLastSC9		:= ""

/*/{Protheus.doc} MTA450I
(Executado apos atualizacao da liberacao de pedido)
	
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784403)
/*/
User Function MTA450I()
                                     
	Local		aAreaOld		:= GetArea()
	Private 	cObserv			:= Space(100)
	Private 	nLimCred		:= 0
	Private 	nLimAux			:= 0
	Private 	dDatVen			:= dDataBase
	Private 	cRisco			:= ""
	Private		cObsMemo		:= ""
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	If cLastSC9 <> SC9->C9_PEDIDO .Or. lFirstSC9 //SC9->C9_ITEM == "01"
	
  		// Grava Log
		U_GMCFGM01("LC",SC9->C9_PEDIDO,,FunName())
	
		If MsgYesNo("Deseja alterar dados de credito do cliente ?","Informacao")
			
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SC9->C9_CLIENTE+SC9->C9_LOJA)
			
			nLimCred 		:= SA1->A1_LC
			nLimAux			:= SA1->A1_LCFIN 
			dDatVen 		:= SA1->A1_VENCLC
			cRisco 			:= SA1->A1_RISCO
			nAction			:= 0
			cObsMemo		:= SA1->A1_OBSMEMO
		
			DEFINE MSDIALOG oLeTxt TITLE (ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+ OemToAnsi(" Informações do Credito do Cliente")) FROM 001,001 TO 420,585 PIXEL
				
			
			@ 010,018 Say "Cliente->"+SA1->A1_COD+SA1->A1_LOJA+"-"+SA1->A1_NOME Pixel Of oLeTxt
			@ 020,018 Say "Limite de Crédito:" Pixel Of oLeTxt
			@ 020,075 MsGet nLimCred Picture "@E 999,999.99" Size 50,10 Pixel Of oLeTxt
			@ 020,130 Say "Limite Auxiliar:" Pixel Of oLeTxt
			@ 020,187 MsGet nLimAux Picture "@E 999,999.99" Size 50,10 Pixel Of oLeTxt
			@ 030,018 Say "Data Vencimento" Pixel Of oLeTxt
			@ 030,075 MsGet dDatVen  Size 50,10 Pixel Of oLeTxt
			@ 040,018 Say "Risco" Pixel Of oLeTxt
			@ 040,075 Combobox cRisco Items {"A","B","C","D","E","Z"} Size 40,10 Pixel Of oLeTxt
			@ 052,018 Say "Observações" Pixel Of oLeTxt
			@ 052,075 MsGet cObserv Size 205,30 Pixel Of oLeTxt
			@ 090,018 MsGet cObsMemo Size 262,095 Pixel Of oLeTxt When .F.
			@ 195,010 Button "Antecipado" Size 50,10  Action (nAction := 1,oLeTxt:End()) Pixel Of oLeTxt
			@ 195,065 Button "Gravar" Size 50,10 Action (nAction := 2,oLeTxt:End()) Pixel Of oLeTxt
			@ 195,120 Button "Cancelar" Size 50,10 Action oLeTxt:End() Pixel Of oLeTxt
		
			Activate MsDialog oLeTxt Centered
		
			If nAction == 1
				sfAntecipado()
				Alteralc()
			ElseIf nAction == 2
				Alteralc()
			Endif
		
		Endif
	Endif
	lFirstSC9 	:= .F.
	cLastSC9 	:= SC9->C9_PEDIDO

	RestArea(aAreaOld)

Return


/*/{Protheus.doc} Alteralc
(long_description)
	
@author MarceloLauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function Alteralc()

	DbSelectArea("SA1")
	cA1MemoObs	:= SA1->A1_OBSMEMO
	RecLock("SA1",.F.)
	SA1->A1_LC 		:= nLimcred
	SA1->A1_LCFIN 	:= nLimAux
	SA1->A1_VENCLC 	:= dDatVen
	SA1->A1_RISCO 	:= cRisco
	SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(__cUserId)) + Chr(13)+Chr(10) + ""+cObserv+Chr(13)+Chr(10)+cA1MemoObs
	MsUnLock()

	MsgAlert("Entrada de Dados Realizada com sucesso!!","Informacao","INFO")

Return



/*/{Protheus.doc} sfAntecipado
(long_description)
	
@author MarceloLauschner
@since 13/12/2013
@version 1.0		

@return  Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfAntecipado()

	Local 	oPed2
	Local	cMensagem 	:= cRecebe := cAssunto := ""
	Local	cMotBlq		:= Space(100)
	Local	cPed    	:= SC9->C9_PEDIDO
	
	DEFINE MSDIALOG oPed2 TITLE (ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + OemToAnsi("Bloquear por Antecipado o pedido-> "+ cPed + "?")) FROM 001,001 TO 100,370 PIXEL
	
	@ 015,010 Say "Motivo Bloqueio/Liberação" Pixel Of oPed2
	@ 027,010 MsGet cMotBlq	Size 170,10 Valid (Len(Alltrim(cMotBlq)) > 15) Pixel Of oPed2
	@ 040,010 Button "&Grava Antecipado" Size 50,10 ACTION (oPed2:End() ) Pixel Of oPed2
	@ 040,065 Button "&Cancela"  SIZE 50,10 ACTION (cMotBlq := "", oPed2:End() ) Pixel Of oPed2

	ACTIVATE MsDIALOG oPed2 CENTERED

	If !Empty(cMotBlq)
	
		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = 'F' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_PEDIDO ='" +cPed+ "' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
	
		TCSQLExec(cQru)
	                  
		              	
		cRecebe		:= GetMv("GM_FINMAIL")
	
		DbSelectArea("SC5")
		DbSetOrder(1)
		If DbSeek(xFilial("SC5")+cPed)
			RecLock("SC5",.F.)
			SC5->C5_BOX		:= SC5->C5_CONDPAG + SC5->C5_BANCO 
			SC5->C5_BLPED	:= "F"
			SC5->C5_BANCO	:= "987"
			SC5->C5_CONDPAG	:= "099"
			SC5->C5_MSGEXP 	:= Padr(cMotBlq,TamSX3("C5_MSGEXP")[1])
			MsUnlock()
			
			DbSelectArea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3")+SC5->C5_VEND1)
				cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
				cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
				cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")
				cRecebe += Iif(!Empty(SA3->A3_MENS2),";"+SA3->A3_MENS2,"")
			Endif
			
			cAssunto 	:= "Pedido "+ cPed + " bloqueado pelo financeiro."
			cMensagem	:= "O usuário '" + AllTrim(  UsrFullName(__cUserId) ) + "' " +Chr(13)+Chr(10)+;
				"bloqueou o pedido do cliente do cliente: " +;
				AllTrim( SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME) +;
				"no dia " + Dtoc( Date() ) + " as " + Time() + ". "
			cMensagem 	+= Chr(13)+Chr(10)
			cMensagem 	+= "Mensagem Interna: "+SC5->C5_MSGEXP
			cMensagem 	+= Chr(13)+Chr(10)
			cMensagem 	+= "Valor do pedido liberado precisa ser consultado no sistema!"
			cMensagem 	+= Chr(13)+Chr(10)
			cMensagem 	+= "Motivo: 'PAGAMENTO ANTECIPADO' e " + cMotBlq
			cMensagem 	+= Chr(13)+Chr(10) + " Condição pagamento alterada para 099-Pagto Antecipado e Banco para 987-Pagamento Antecipado"
			cMensagem   += Chr(13)+Chr(10)
			cMensagem	+= "Empresa: " + SM0->M0_NOMECOM
	
			DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)		
				cA1MemoObs	:= SA1->A1_OBSMEMO
				RecLock("SA1",.F.)
				SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(__cUserId)) + Chr(13)+Chr(10) + "Bloqueado:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
				MsUnlock()
			Endif
		Endif
		// Grava Log		
		U_GMCFGM01("BA",SC9->C9_PEDIDO,cMensagem,FunName())

		stSendMail(cRecebe,cAssunto,cMensagem)

		MsgAlert("Se houver outros pedidos para o mesmo Cliente, o procedimento de Antecipado deverá ser repetido!", "A T E N Ç Ã O!! ANTECIPADO!!")
	
	Endif

Return



Static Function stSendMail( cMailTo, cAssunto, cMensagem)

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
				SEND MAIL FROM cMailConta TO cMailTo SUBJECT cAssunto BODY cMensagem RESULT lSendOk  // Efetua envio do e-mail

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
