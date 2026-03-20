#include "ap5mail.ch"
#include "topconn.ch"
#include "protheus.ch"

/*/{Protheus.doc} M450CMAN
(Ponto de entrada na liberação manual de crédito do cliente)
@author MarceloLauschner
@since 27/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M450CMAN()
	
	Local		aAreaOld	:= GetArea()
	Local		nOpcLib		:= ParamIxb[1]
	Local		nReturn		:= 0
	Local		cRecebe		:= ""
	Local		cAssunto	:= ""
	Local		cMensagem	:= ""
	Local		cA1MemoObs	:= ""
	Local		cQru
	Local 		iW
	Private		aPedLog		:= {}
	Private		cMotBlq		:= "Titulos Vencidos " + Space(100)
	
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M450CMAN")
		Return .T.
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If nOpcLib	== 3 	// Rejeita
		nReturn := sfAvalRej()
		If nReturn == 3
			cRecebe		:= GetMv("GM_FINMAIL")
			DbSelectArea("SA3")
			DbSetOrder(1)
			DbSeek(xFilial("SA3")+SA1->A1_VEND)
			cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
			cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
			cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")
			cRecebe += Iif(!Empty(SA3->A3_MENS2),";"+SA3->A3_MENS2,"")
			
			
			cAssunto 	:= "Pedido(s) do Cliente "+ SA1->A1_COD + "/"+SA1->A1_LOJA + "-"+SA1->A1_NOME + " rejeitado(s) pelo financeiro."
			cMensagem	:= "O usuário '" + AllTrim( UsrFullName(__cUserId)) + "' " +Chr(13)+Chr(10)+;
				"rejeitou o crédito dos pedidos do cliente: " +;
				AllTrim(SA1->A1_COD+"/"+SA1->A1_LOJA + " " + SA1->A1_NOME) +;
				" no dia " + Dtoc( Date() ) + " as " + Time() + ". "
			cMensagem 	+= Chr(13)+Chr(10)
			cMensagem 	+= Chr(13)+Chr(10)
			cMensagem 	+= "Motivo: " + cMotBlq
			cMensagem   += Chr(13)+Chr(10)
			
			DbSelectArea("SA1")
			cA1MemoObs	:= SA1->A1_OBSMEMO
			RecLock("SA1",.F.)
			SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim(cUserName) + Chr(13)+Chr(10) + "Rejeitado:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
			MsUnlock()
			// Grava Log
			//		U_GMCFGM01("LR",SC9->C9_PEDIDO,cMensagem,FunName())
			
			cQru := ""
			cQru += "SELECT DISTINCT C9_PEDIDO "
			cQru += " FROM " + RetSqlName("SC9")
			cQru += " WHERE D_E_L_E_T_ = ' ' "
			cQru += "   AND C9_CLIENTE = '" +SA1->A1_COD+ "' "
			cQru += "   AND C9_LOJA = '"+SA1->A1_LOJA+"' "
			cQru += "	AND C9_BLCRED<>'  ' "
			cQru += "	AND C9_BLCRED<>'09' "
			cQru += "	AND C9_BLCRED<>'10' "
			cQru += "	AND C9_BLCRED<>'ZZ' "
			cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
			
			TCQUERY cQru NEW ALIAS "QRU"
			
			While !Eof()
				Aadd(aPedLog,QRU->C9_PEDIDO)
				DbSelectArea("QRU")
				DBSkip()
			Enddo
			QRU->(DbCloseArea())
			//	Grava Log
			For iW := 1 To Len(aPedLog)
				U_GMCFGM01("LR",aPedLog[iW],cMensagem,FunName())
			Next
			
			stSendMail( cRecebe, cAssunto, cMensagem )
		Endif
	Else
		nReturn	:= nOpcLib
	Endif
	RestArea(aAreaOld)
	
Return nReturn > 0


/*/{Protheus.doc} sfAvalRej
(long_description)
@author MarceloLauschner
@since 27/05/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAvalRej()
	
	Local 	oPed2
	Local	cMensagem 	:= ""
	Local	cRecebe 	:= ""
	Local	cAssunto 	:= ""
	Local	cQru
	Local	cA1MemoObs
	Local 	iW
	Local	nReturn		:= 0
	
	DEFINE MSDIALOG oPed2 FROM 000,000 TO 180,370 OF oMainWnd PIXEL TITLE OemToAnsi("Colocar na Pendência os pedidos do cliente-> "+ SA1->A1_NOME+ " ")
	@ 015,010 Say "Motivo Bloqueio para Pendência" of oPed2 Pixel
	@ 022,010 MsGet cMotBlq	Size 150,10 of oPed2 Pixel Valid (Len(Alltrim(cMotBlq)) > 10 )
	@ 070,010 BUTTON "&Pendência TMK" of oPed2 pixel SIZE 50,10 ACTION (nReturn :=  2,oPed2:End() )
	@ 070,065 BUTTON "&Suspensão Financeira" of oPed2 pixel SIZE 50,10 ACTION (nReturn :=  1,oPed2:End() )
	@ 070,120 BUTTON "&Rejeição " of oPed2 pixel SIZE 50,10 ACTION (nReturn := 3, oPed2:End() )
	
	ACTIVATE msDIALOG oPed2 CENTERED
	
	If nReturn == 1
		
		cQru := ""
		cQru += "SELECT DISTINCT C9_PEDIDO "
		cQru += " FROM " + RetSqlName("SC9")
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_CLIENTE = '" +SA1->A1_COD+ "' "
		cQru += "   AND C9_LOJA = '"+SA1->A1_LOJA+"' "
		cQru += "	AND C9_BLCRED<>'  ' "
		cQru += "	AND C9_BLCRED<>'09' "
		cQru += "	AND C9_BLCRED<>'10' "
		cQru += "	AND C9_BLCRED<>'ZZ' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		
		TCQUERY cQru NEW ALIAS "QRU"
		While !Eof()
			Aadd(aPedLog,QRU->C9_PEDIDO)
			DbSelectArea("QRU")
			DBSkip()
		Enddo
		QRU->(DbCloseArea())
		
		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = 'P' "
		cQru += "      ,C9_BLOQUEI = C9_BLCRED "
		cQru += "      ,C9_BLCRED = '09' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_CLIENTE = '" +SA1->A1_COD+ "' "
		cQru += "   AND C9_LOJA = '"+SA1->A1_LOJA+"' "
		cQru += "	AND C9_BLCRED<>'  ' "
		cQru += "	AND C9_BLCRED<>'09' "
		cQru += "	AND C9_BLCRED<>'10' "
		cQru += "	AND C9_BLCRED<>'ZZ' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction
		
		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5")
		cQru += "   SET C5_BLPED = 'P' "
		cQru += "      ,C5_MSGEXP = '"+Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])+"' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_CLIENTE ='" +SA1->A1_COD+ "' "
		cQru += "   AND C5_NUM IN(SELECT C9_PEDIDO "
		cQru += "     	 		    FROM "+RetSqlName("SC9")
		cQru += "       		   WHERE D_E_L_E_T_ = ' ' "
		cQru += "                    AND C9_BLCRED = '09' "
		cQru += "                    AND C9_FLGENVI = 'P' "
		cQru += "                    AND C9_CLIENTE = '"+SA1->A1_COD+"' "
		cQru += "                    AND C9_LOJA = '"+SA1->A1_LOJA +"' "
		cQru += "                    AND C9_FILIAL = '"+xFilial("SC9")+"' )"
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction
		
		//Inserido para buscar os dados dos vendedores com pedidos pendentes para o cliente e enviar o email para eles e não para o vendedor padrão do cadastro.
		cQru := ""
		cQru += " SELECT DISTINCT(C5_VEND1) "
		cQru += "  FROM "+RetSqlName("SC5") 
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_CLIENTE ='" +SA1->A1_COD+ "' "
		cQru += "   AND C5_NUM IN(SELECT C9_PEDIDO "
		cQru += "     	 		    FROM "+RetSqlName("SC9")
		cQru += "       		   WHERE D_E_L_E_T_ = ' ' "
		cQru += "                    AND C9_BLCRED = '09' "
		cQru += "                    AND C9_FLGENVI = 'P' "
		cQru += "                    AND C9_CLIENTE = '"+SA1->A1_COD+"' "
		cQru += "                    AND C9_LOJA = '"+SA1->A1_LOJA +"' "
		cQru += "                    AND C9_FILIAL = '"+xFilial("SC9")+"' )"
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		
		cRecebe		:= GetMv("GM_FINMAIL")
		
		TCQUERY cQru NEW ALIAS "QRU"
		While !Eof()
			DbSelectArea("SA3")
			DbSetOrder(1)
			DbSeek(xFilial("SA3")+QRU->C5_VEND1)
			cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
			cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
			cRecebe += Iif(!Empty(SA3->A3_MENS2),";"+SA3->A3_MENS2,"")
			cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")
			DbSelectArea("QRU")
			DBSkip()
		Enddo
		QRU->(DbCloseArea())
		
		
		/*
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SA1->A1_VEND)
		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")
		*/
		
		cAssunto 	:= "Pedido(s) suspensos/pendentes pelo financeiro."
		cMensagem	:= "O usuário '" + AllTrim( cUserName ) + "' " +Chr(13)+Chr(10)+;
			"bloqueou para manter pendente de análise, o(s) pedido(s) do cliente: " +;
			AllTrim(SA1->A1_COD+"/"+SA1->A1_LOJA + " " + SA1->A1_NOME) +;
			" no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem 	+= "Solução do Problema por conta do Financeiro "
		cMensagem   += Chr(13)+Chr(10)
		
		DbSelectArea("SA1")
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim(UsrFullName(__cUserId)) + Chr(13)+Chr(10) + "Pend.Fin:"+cMotBlq+cA1MemoObs
		MsUnlock()
		// Grava Log
		//	U_GMCFGM01("BF",cPed,cMensagem,FunName())
		//	Grava Log
		For iW := 1 To Len(aPedLog)
			U_GMCFGM01("BF",aPedLog[iW],cMensagem,FunName())
		Next
		
		stSendMail( cRecebe, cAssunto, cMensagem )
	ElseIf nReturn ==2
		
		cQru := ""
		cQru += "SELECT DISTINCT C9_PEDIDO "
		cQru += "  FROM " + RetSqlName("SC9")
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_CLIENTE = '" +SA1->A1_COD+ "' "
		cQru += "   AND C9_LOJA = '"+SA1->A1_LOJA+"' "
		cQru += "	AND C9_BLCRED<>'  ' "
		//	cQru += "	AND C9_BLCRED<>'09' " // Comentado para que seja possivel pedidos que estejam como pendencia Tmk sejam transferidos para Pendencia Financeiro e vice versa
		cQru += "	AND C9_BLCRED<>'10' "
		cQru += "	AND C9_BLCRED<>'ZZ' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		
		TCQUERY cQru NEW ALIAS "QRU"
		While !Eof()
			Aadd(aPedLog,QRU->C9_PEDIDO)
			DbSelectArea("QRU")
			DBSkip()
		Enddo
		QRU->(DbCloseArea())
		
		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = 'T' "
		cQru += "      ,C9_BLOQUEI = C9_BLCRED "
		cQru += "      ,C9_BLCRED = '09' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_CLIENTE = '" +SA1->A1_COD+ "' "
		cQru += "   AND C9_LOJA = '"+SA1->A1_LOJA+"' "
		cQru += "	AND C9_BLCRED<>'  ' "
		//	cQru += "	AND C9_BLCRED<>'09' " // Comentado para que seja possivel pedidos que estejam como pendencia Tmk sejam transferidos para Pendencia Financeiro e vice versa
		cQru += "	AND C9_BLCRED<>'10' "
		cQru += "	AND C9_BLCRED<>'ZZ' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction
		
		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5")
		cQru += "   SET C5_BLPED = 'T' "
		cQru += "      ,C5_MSGEXP = '"+Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])+"' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_CLIENTE ='" +SA1->A1_COD+ "' "
		cQru += "   AND C5_NUM IN(SELECT C9_PEDIDO "
		cQru += "     	 		    FROM "+RetSqlName("SC9")
		cQru += "       		   WHERE D_E_L_E_T_ = ' ' "
		cQru += "                    AND C9_BLCRED = '09' "
		cQru += "                    AND C9_FLGENVI = 'T' "
		cQru += "                    AND C9_CLIENTE = '"+SA1->A1_COD+"' "
		cQru += "					 AND C9_LOJA = '"+SA1->A1_LOJA+"' "
		cQru += "                    AND C9_FILIAL = '"+xFilial("SC9")+"' )"
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction
		
		//Inserido para buscar os dados dos vendedores com pedidos pendentes para o cliente e enviar o email para eles e não para o vendedor padrão do cadastro.
		cQru := ""
		cQru += " SELECT DISTINCT(C5_VEND1) "
		cQru += "  FROM "+RetSqlName("SC5") 
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_CLIENTE ='" +SA1->A1_COD+ "' "
		cQru += "   AND C5_NUM IN(SELECT C9_PEDIDO "
		cQru += "     	 		    FROM "+RetSqlName("SC9")
		cQru += "       		   WHERE D_E_L_E_T_ = ' ' "
		cQru += "                    AND C9_BLCRED = '09' "
		cQru += "                    AND C9_FLGENVI = 'T' "
		cQru += "                    AND C9_CLIENTE = '"+SA1->A1_COD+"' "
		cQru += "                    AND C9_LOJA = '"+SA1->A1_LOJA +"' "
		cQru += "                    AND C9_FILIAL = '"+xFilial("SC9")+"' )"
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		
		cRecebe		:= GetMv("GM_FINMAIL")
		
		TCQUERY cQru NEW ALIAS "QRU"
		While !Eof()
			DbSelectArea("SA3")
			DbSetOrder(1)
			DbSeek(xFilial("SA3")+QRU->C5_VEND1)
			cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
			cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
			cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")
			cRecebe += Iif(!Empty(SA3->A3_MENS2),";"+SA3->A3_MENS2,"")
			
			DbSelectArea("QRU")
			DBSkip()
		Enddo
		QRU->(DbCloseArea())
		
		
		/*cRecebe		:= GetMv("GM_FINMAIL")
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SA1->A1_VEND)
		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")*/
		
		
		cAssunto 	:= "Pedido(s) suspensos/pendentes pelo financeiro."
		cMensagem	:= "O usuário '" + AllTrim( cUserName ) + "' " +Chr(13)+Chr(10)+;
			"bloqueou para manter pendente de análise, o(s) pedido(s) do cliente: " +;
			AllTrim(SA1->A1_COD+"/"+SA1->A1_LOJA + " " + SA1->A1_NOME) +;
			" no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem 	+= "Solução do Problema por conta do setor Telemarketing/Comercial! "
		cMensagem   += Chr(13)+Chr(10)
		
		DbSelectArea("SA1")
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim(UsrFullName(__cUserId)) + Chr(13)+Chr(10) + "Pend.Tmk:"+cMotBlq+cA1MemoObs
		MsUnlock()
		// Grava Log
		For iW := 1 To Len(aPedLog)
			U_GMCFGM01("BT",aPedLog[iW],cMensagem,FunName())
		Next
		
		// Grava Log
		//	U_GMCFGM01("BT",cPed,cMensagem,FunName())
		
		stSendMail( cRecebe, cAssunto, cMensagem )
		
		
	Endif
	
	
Return nReturn


/*/{Protheus.doc} stSendMail
(long_description)
@author MarceloLauschner
@since 27/05/2015
@version 1.0
@param cRecebe, character, (Descrição do parâmetro)
@param cAssunto, character, (Descrição do parâmetro)
@param cMensagem, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
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


