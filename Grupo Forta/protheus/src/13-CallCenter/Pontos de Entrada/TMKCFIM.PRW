#INCLUDE "totvs.CH"
#INCLUDE "AP5MAIL.CH"

// Função de Ponto de Entrada após gravar o atendimento TElecobrança
//U_TMKCFIM(M->ACF_CODIGO)

/*/{Protheus.doc} TMKCFIM
Ponto de Entrada ao Finalizar Telecobrança
@type function
@version
@author Marcelo Alberto Lauschner
@since 07/07/2011
@param cInCodigoACF, character, param_description
@return return_type, return_description
/*/
User Function TMKCFIM(cInCodigoACF)

	Local	lContinua	:= .F.
	Local 	iW 
	Private	oCbSituacao,oDlg1,oDtRetorno,oDtDeposito
	Private	dDtRetorno	:= CTOD("  /  /  ")
	Private	dDtDeposito	:= CTOD("  /  /  ")
	Private	cComb	:= aCols[n,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})]

	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Informações adicionais para Finalização do Atendimento de Cobrança") From 000,000 to 220,500 of oMainWnd PIXEL

	@ 005,005 To 095,248 of oDlg1 Pixel
	@ 017,015 Say "Informe uma Situação" of oDlg1 Pixel
	@ 015,075 Combobox oCbSituacao Var cComb ITEMS {"1=Serasa","2=Inad.Nova","3=Retornar Ligação","4=Novo c/Histórico","5=Cartório","6=Agendado Depósito","7=Protestado","8=Sem Status"} Valid sfCbox() of oDlg1 Pixel Size 80,11
	@ 032,015 Say "Data Retorno" of oDlg1 Pixel
	@ 030,075 Msget oDtRetorno Var dDtRetorno Size 040,11 of oDlg1 Pixel
	oDtRetorno:Disable()
	@ 047,015 Say "Agendado Depósito" of oDlg1 Pixel
	@ 045,075 Msget oDtDeposito Var dDtDeposito  Size 040,11 of oDlg1 Pixel
	oDtDeposito:Disable()
	@ 097,050 BUTTON "&Grava"  of oDlg1 pixel SIZE 60,12 ACTION (IIf(sfVld(),(lContinua := .T.,oDlg1:End())	,MsgAlert("Inconsistência na gravação de dados","TMKCFIM.sfVld")))
	@ 097,120 BUTTON "&Cancela" of oDlg1 pixel SIZE 60,12 ACTION (MsgAlert("Nenhum Status será salvo para o cliente e os títulos!","A T E N Ç Ã O!!"), oDlg1:End() )

	ACTIVATE MSDIALOG oDlg1 CENTERED


	If lContinua

		U_MLDBSLCT("CONDORTMKC",.F.,1)
		If DbSeek(cEmpAnt+cFilAnt+M->ACF_CLIENT+M->ACF_LOJA)
			RecLock("CONDORTMKC",.F.)
			CONDORTMKC->CTC_ULTACF	:= dDataBase
			CONDORTMKC->CTC_RETORN	:= dDtRetorno
			CONDORTMKC->CTC_AGEDEP	:= dDtDeposito
			CONDORTMKC->CTC_STATUS	:= cComb
			MsUnlock()
		Endif
		cMensagem	:= ""

		For iW := 1 To Len(aCols)
			DbSelectArea("SK1")
			DbSetOrder(1)                             //ACG_PREFIX+ACG_TITULO+ACG_PARCEL+ACG_TIPO+ACG_FILORI
			If DbSeek(xFilial("SK1")+aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TITULO"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PARCEL"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TIPO"})]+;
					aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_FILORI"})])

				// Efetuo a verifiacação se há titulo marcado para Serasa e valida se não estava marcado ainda
				If aCols[iW,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})] $ "1" .And. SK1->K1_XSTATUS # "1"
					RecLock("CONDORTMKC",.F.)
					CONDORTMKC->CTC_DTSERA	:= dDataBase
					CONDORTMKC->CTC_NSERAS	+= 1
					MsUnlock()
				Endif

				// Efetuo verificação se há titulo marcado para ser enviado para Cartorio
				If aCols[iW,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})] $ "5" .And. SK1->K1_XSTATUS # "5" // Enviado Cartorio e se o Status do Titulo ainda não era de Cartorio
					If Empty(cMensagem)
						cMensagem	+= "Empresa  :"+Capital(SM0->M0_NOMECOM)
						cMensagem 	+= CRLF
						cMensagem	+= "Solicitação feita pelo Atendimento Telecobrança Nº :"+M->ACF_CODIGO
						cMensagem 	+= CRLF
						cMensagem	+= "Operador Microsiga:"+cUserName
						cMensagem 	+= CRLF
					Endif
					cMensagem	+= "Titulo: Prefixo/Número/Parcela/Tipo: "+	aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})]+ "/"+ ;
						aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TITULO"})]+"/"+;
						aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PARCEL"})]+"/"+;
						aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TIPO"})]

					cMensagem 	+= CRLF
					DbSelectArea("SE1")
					DbSetOrder(1)                             //ACG_PREFIX+ACG_TITULO+ACG_PARCEL+ACG_TIPO+ACG_FILORI
					If DbSeek(xFilial("SE1")+aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PREFIX"})]+;
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TITULO"})]+;
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_PARCEL"})]+;
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_TIPO"})])
						cE1_HIST	:= SE1->E1_HIST
						RecLock("SE1",.F.)
						SE1->E1_HIST	:= Substr("Solicitado Cartório Via Telecobrança Nº:"+M->ACF_CODIGO+" em:"+DTOC(dDataBase) +"|"+cE1_HIST,1,Len(SE1->E1_HIST))
						MsUnlock()
						If Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_HIST"}) > 0
							aCols[iw,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_HIST"})]	:= SE1->E1_HIST
						Endif
					Endif
				Endif
				DbSelectArea("SK1")
				RecLock("SK1",.F.)
				SK1->K1_XSTATUS	:= aCols[iW,Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})]
				MsUnlock()

			Endif
		Next
		If !Empty(cMensagem)
			cRecebe		:= UsrRetMail(__cUserId)
			//cRecebe		:= "marcelo@gmeyer.com.br"
			cAssunto 	:= "Envio de Títulos para Cartório do Cliente '"+M->ACF_CLIENT+"/"+M->ACF_LOJA+" " +Alltrim(Posicione("SA1",1,xFilial("SA1")+M->ACF_CLIENT+M->ACF_LOJA,"A1_NOME"))
			stSendMail( cRecebe, cAssunto, cMensagem )
		Endif

	Endif


Return


/*/{Protheus.doc} sfVld
Valido as datas do Dialog ao encerrar atendimento, impedindo que a data	agendada seja menor que a atual
@type function
@version
@author Marcelo Alberto Lauschner
@since 07/07/2011
@return return_type, return_description
/*/
Static Function sfVld()

	If cComb == "6"
		Return dDtDeposito >= dDataBase
	Elseif cComb	== "3"
		Return dDtRetorno  >= dDataBase
	Endif

Return .T.


/*/{Protheus.doc} sfCbox
Valido o Foco dos Gets de data conforme opção do Combobox
@type function
@version
@author Marcelo Alberto Lauschner
@since 07/07/2011
@return return_type, return_description
/*/
Static Function sfCbox()

	// Desabilito os dois campos de data
	oDtDeposito:Disable()
	dDtDeposito	:= CTOD("  /  /  ")
	oDtDeposito:Refresh()
	oDtRetorno:Disable()
	dDtRetorno	:= CTOD("  /  /  ")
	oDtRetorno:Refresh()

	// Somente habilito os campos de data conforme seleção
	If cComb == "6"
		oDtDeposito:Enable()
		oDtDeposito:SetFocus()
	Elseif cComb	== "3"
		oDtRetorno:Enable()
		oDtRetorno:SetFocus()
	Endif

Return .T.

/*/{Protheus.doc} stSendMail
Efetua envio de email (No caso de Títulos para Cartorio)
@type function
@version
@author Marcelo Alberto Lauschner
@since 07/07/2011
@param cRecebe, character, param_description
@param cAssunto, character, param_description
@param cMensagem, character, param_description
@return return_type, return_description
/*/
Static Function stSendMail( cRecebe, cAssunto, cMensagem , cArqAttAch , cAttachName)


	//Crio a conexão com o server SMTP ( Envio de e-mail )
	Local	oServer2 	:= TMailManager():New()
	Local	cCorpoM		:= ""
	Default	cArqAttAch	:= ""
	Default cAttachName	:= ""

	// Usa SSL na conexao
	If GetMv("XM_SMTPSSL")
		oServer2:setUseSSL(.T.)
	Endif

	// Usa TLS na conexao
	If GetNewPar("XM_SMTPTLS",.F.)
		oServer2:SetUseTLS(.T.)
	Endif

	oServer2:Init( ""		,Alltrim(GetMv("XM_SMTP")), Alltrim(GetMv("XM_SMTPUSR"))	,Alltrim(GetMv("XM_PSWSMTP")),	0			, GetMv("XM_SMTPPOR") )

	//seto um tempo de time out com servidor de 1min
	If oServer2:SetSmtpTimeOut( GetMv("XM_SMTPTMT") ) != 0
		FwLogMsg('INFO', , 'TMKCFIM', ProcName(), '', cEmpAnt, "Falha ao setar o Time out" , 0, 0, {})
	EndIf

	//realizo a conexão SMTP
	If oServer2:SmtpConnect() != 0
		FwLogMsg('INFO', , 'TMKCFIM', ProcName(), '', cEmpAnt, "Falha ao Conectar SMTP" , 0, 0, {})
	EndIf

	// Realiza autenticacao no servidor
	If GetMv("XM_SMTPAUT")
		nErr := oServer2:smtpAuth(Alltrim(GetMv("XM_SMTPUSR")), Alltrim(GetMv("XM_PSWSMTP")))
		If nErr <> 0
			FwLogMsg('INFO', , 'TMKCFIM', ProcName(), '', cEmpAnt, "[ERROR]Falha ao autenticar: " + oServer2:getErrorString(nErr) , 0, 0, {})
			MsgAlert("[ERROR]Falha ao autenticar: " + oServer2:getErrorString(nErr),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			oServer2:smtpDisconnect()
		Endif
	Endif
	//Apos a conexão, crio o objeto da mensagem
	oMessage2 := TMailMessage():New()
	//Limpo o objeto
	//Populo com os dados de envio
	oMessage2:cFrom 		:= "Inadimplência Grupo Forta<"+Alltrim(GetMv("XM_SMTPUSR"))+">" // GetMv("XM_SMTPDES")
	oMessage2:cTo 			:= cRecebe
	oMessage2:cSubject 		:= OemToAnsi(cAssunto)

	cCorpoM	:= ""
	cCorpoM += "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'> "
	cCorpoM += "<html xmlns='www.w3.org/1999/xhtml'> "
	cCorpoM += "<head> "
	cCorpoM += "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1' /> "
	cCorpoM += "<style type='text/css'> "
	cCorpoM += "<!-- "
	cCorpoM += "body,td,th { "
	cCorpoM += "	font-family: Arial, Helvetica, sans-serif; "
	cCorpoM += "	font-size: 12pt; "
	cCorpoM += "} "
	cCorpoM += "--> "
	cCorpoM += "</style></head> "
	cCorpoM += "<body> "
	cCorpoM += "<br><br>"
	cCorpoM += AllTrim(OemToAnsi(cMensagem))
	cCorpoM += "<br>"
	cCorpoM += "<br>"
	cCorpoM += "Este email é disparado automaticamente pela rotina Gerenciador Inadimplência - Favor não Responder."
	cCorpoM += "<br>"
	cCorpoM += "________________________________________________________________________"
	cCorpoM += "<br>"

	cCorpoM += "</body> "
	cCorpoM += "</html>"

	oMessage2:MsgBodyType( "text/html" )
	oMessage2:cBody 		:= cCorpoM //OemToAnsi("Email de resposta automática. Não foi possível ler o XML de seu e-mail enviado." + CRLF+cMsgRetMail+ CRLF+cBodyAux + CRLF+"'"+cText+"'")

	//Adiciono um attach
	If !Empty(cArqAttAch)
		If oMessage2:AttachFile( cArqAttAch) < 0
			FwLogMsg('INFO', , 'TMKCFIM', ProcName(), '', cEmpAnt, "Erro ao anexar o arquivo: " +cArqAttAch , 0, 0, {})
			//	MsgAlert("Não foi possível anexar o arquivo.","Erro" )
		Else
			//adiciono uma tag informando que é um attach e o nome do arq
			oMessage2:AddAtthTag( 'Content-Disposition: attachment; filename='+Alltrim(cAttachName))
		EndIf
	Endif

	//Envio o e-mail
	If oMessage2:Send( oServer2 ) != 0
		FwLogMsg('INFO', , 'TMKCFIM', ProcName(), '', cEmpAnt, "Erro ao enviar o email " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) , 0, 0, {})
	EndIf

	//Disconecto do servidor
	If oServer2:SmtpDisconnect() != 0
		FwLogMsg('INFO', , 'TMKCFIM', ProcName(), '', cEmpAnt, "Erro ao disconectar do servidor SMTP " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) , 0, 0, {})
	EndIf

	FreeObj(oServer2)

	If !Empty(cArqAttAch)
		fErase(cArqAttAch)
	Endif 

Return
