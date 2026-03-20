#Include 'Protheus.ch'
#include "topconn.ch"
#INCLUDE "XmlXFun.Ch"
//#include "spednfe.ch"
#define STR0035  "Ambiente"
#define STR0039  "O primeiro passo é configurar a conexão do Protheus com o serviço."
#define STR0050  "Protocolo"
#define STR0056  "Produção"
#define STR0057  "Homologação"
#define STR0068  "Cod.Ret.NFe"
#define STR0069  "Msg.Ret.NFe"
#define STR0114  "Ok"
#define STR0107  "Consulta NF"
#define STR0129  "Versão da mensagem"
#define STR0414  "Sem manifestação"
#define STR0415  "Confirmada"
#define STR0416  "Desconhecida"
#define STR0417  "Não realizada"
#define STR0418  "Ciência"
#define STR0419  "210200 - Confirmação da Operação"
#define STR0420  "210210 - Ciência da Operação"
#define STR0421  "210220 - Desconhecimento da Operação"
#define STR0422  "210240 - Operação não Realizada"

/*/{Protheus.doc} RLFATA02
(Rotina de importação de e-mails de clientes para gerar processo de devolução de armazenagem)
@type function
@author Marcelo Alberto Lauschner
@since 09/10/2016
@version 1.0
/*/
User Function RLFATA02()


	If !cEmpAnt $ "06#16"
		MsgInfo("Empresa errada para executar esta rotina!")
		Return
	Endif


	Private	cBarLinx		:= IIf(IsSrvUnix(),"/","\")
	Private	cDirNfe    		:= IIf(IsSrvUnix(),StrTran( GetNewPar("XM_DIRXML",cBarLinx+"nf-e"+cBarLinx),"\","/"),GetNewPar("XM_DIRXML",cBarLinx+"nf-e"+cBarLinx))	//	IIf(IsSrvUnix(),"/nf-e/", "\Nf-e\"))
	Private cRootPath		:= GetSrvProfString ("RootPath","\indefinido")
	Private	lAutoExec		:= IsBlind()
	Private	cLeftNil		:= GetNewPar("XM_LEFTNIL","0")
	Private aSize 			:= MsAdvSize()

	If IsBlind()
		sfRecMail()
	ElseIf MsgYesNO("Deseja realmente executar o processo? ")
		//sfCriaSX6()

		sfRecMail()
	Endif

Return

Static Function SchedDef()
	Local	aOrd	:= {}
	Local	aParam	:= {}

	Aadd(aParam,"P")
	Aadd(aParam,"PARAMDEF")
	Aadd(aParam,"")
	Aadd(aParam,aOrd)
	Aadd(aParam,)

Return aParam

// Parametros a serem criados
// RL_POPSSL
// RL_POP
// RL_POPUSR
// RL_PSWPOP
// RL_POPPORT
// RL_TCPMAIL

/*/{Protheus.doc} sfRecMail
(Executa processo de recebimento dos e-mails)
@type function
@author marce
@since 09/10/2016
@version 1.0
/*/
Static Function sfRecMail()

	Local	y
	Local	nI
	Local	cSubjectAux		:= ""
	Local	cBodyAux		:= ""
	Local	cToAux			:= ""
	Local	cAttInfo		:= ""


	If !sfChekLock(.T./*lLock*/,cFilAnt/*cKeyLock*/)
		Return
	Endif

	//Crio uma nova conexão, agora de POP
	oServer 	:= TMailManager():New()
	oMessage 	:= TMailMessage():New()
	// Usa SSL na conexao
	If GetMv("RL_POPSSL")
		oServer:setUseSSL(.T.)
	Endif

	// Usa TLS na conexao
	If GetNewPar("RL_SMTPTLS",.T.)
		oServer:SetUseTLS(.T.)
	Endif

	oServer:Init( Alltrim(GetMv("RL_POP")),"", Alltrim(GetMv("RL_POPUSR"))	,Alltrim(GetMv("RL_PSWPOP")), GetMv("RL_POPPORT") ,0)

	If  Alltrim(GetNewPar("RL_TCPMAIL","POP3")) == "POP3"
		If oServer:SetPopTimeOut( 60 ) != 0
			Conout( "Falha ao setar o time out" )
			sfChekLock(.F./*lLock*/,cFilAnt/*cKeyLock*/)
			Return .F.
		EndIf

		If oServer:PopConnect() != 0
			Conout( "Falha ao conectar" )
			sfChekLock(.F./*lLock*/,cFilAnt/*cKeyLock*/)
			Return .F.
		EndIf
	Else

		If oServer:IMAPConnect() != 0
			Conout( "Falha ao conectar" )
			Alert("Falha ao conectar Imap")
			sfChekLock(.F./*lLock*/,cFilAnt/*cKeyLock*/)
			Return .F.
		Else
			//Alert("Conexão IMAP OK!")
		EndIf
	Endif

	//Recebo o número de mensagens do servidor
	nTam	:= 0
	oServer:GetNumMsgs( @nTam )

	If nTam == 0
		If !lAutoExec
			MsgAlert("Não há e-mails a receber!")
		Endif
	Endif
	nContOk	:= 0



	ProcRegua(nTam)

	lUSsl 		:= GetMv("XM_SMTPSSL")
	lSmtp 		:= GetNewPar("XM_SMTPTLS",.F.)
	lSmt2 		:= GetMv("XM_SMTP")
	lSMTPUSR 	:= GetMv("XM_SMTPUSR")
	lPSWSMTP 	:= GetMv("XM_PSWSMTP")
	lSMTPPOR 	:= GetMv("XM_SMTPPOR")
	SMTPTMT 	:= GetMv("XM_SMTPTMT")
	SMTPAUT 	:= GetMv("XM_SMTPAUT")
	SMTPDES 	:= GetMv("XM_SMTPDES")
	MAILADM 	:= GetNewPar("XM_MAILADM","marcelolauschner@gmail.com")
	POPUSR 		:= GetMv("XM_POPUSR")

	For nI := 1 To nTam


		IncProc("Recebendo email "+Alltrim(Str(nI)) + " / " + Alltrim(Str(nTam))+ ". Aguarde!" )

		Sleep(10*1000) // Espera 10 segundos entre emails para evitar sobrecarga na consulta Sefaz dos xmls

		//Limpo o objeto da mensagem
		oMessage:Clear()
		//Recebo a mensagem do servidor
		oMessage:Receive( oServer, nI )
		cChave	:= " "



		// Declaro variavel para enviar retorno ou não
		cMsgRetMail	:= ""
		//Escrevo no server os dados do e-mail recebido



		nContOk++

		lRetGrv 	:= .T.
		lSave		:= .T.
		cFileSave	:= ""
		cXmlSave	:= ""
		cAttachName	:= ""
		cAttXmlName	:= ""


		For y := 1 to oMessage:getAttachCount()

			aAttInfo:= oMessage:getAttachInfo(y)
			// Analisa se há informaçaõ de anexo e se o arquivo anexo é um XML
			//Estrutura de retorno:
			//  Nome				Descrição
			//1 ShortName			O nome do attachment.
			//2 Type				O tipo do anexo, por exemplo, text/plain ou image/x-png.
			//3 Disposition			Tipo do arquivo.
			//4 DispositionName		Nome do tipo de arquivo.
			//5 ID					Identificação do anexo.
			//6 Location			Local físico do anexo.
			//7 *Size Tamanho do anexo.* Parâmetro Size só estará disponível em versão superior a 7.00.131227A.

			cAttInfo	:= 	aAttInfo[1]
			//For iH := 1 To Len(aAttInfo)
			//	MsgAlert(aAttInfo[iH],cValToChar(iH))
			//Next
			// Se o ShortName estiver em branco procura pelo DispositionName
			If Empty(cAttInfo)
				cAttInfo	:= aAttInfo[4]
			Endif
			// Se o ShortName e DispositionName estiverem em branco procura pelo Type
			If Empty(cAttInfo)
				cAttInfo	:= SubStr( aAttInfo[2], At( "/", aAttInfo[2] ) + 1, Len( aAttInfo[2] ) )
			Endif

			If  At("XML",UPPER(cAttInfo)) > 0
				cAttXmlName	:= cAttInfo
				cAttXmlName	:= Lower(cAttXmlName)
				// Removendo letras invalidas para o nome do arquivo
				cAttXmlName	:= StrTran(cAttXmlName,"<","")
				cAttXmlName	:= StrTran(cAttXmlName,">","")
				cAttXmlName	:= StrTran(cAttXmlName,"-","")
				cAttXmlName	:= StrTran(cAttXmlName,"/","")
				cAttXmlName := StrTran(cAttXmlName,'"','')
				cAttXmlName := StrTran(cAttXmlName,"'","")
				cAttXmlName := StrTran(cAttXmlName,"name=","")
				//cXmlSave		:= cRootPath+cDirNfe+DTOS(Date())+IIf(IsSrvUnix(),"/","\")+cAttXmlName
				//cXmlSave		:= cRootPath + cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2)+ cBarLinx + cAttXmlName
				cXmlSave		:= cRootPath + cDirNfe + cBarLinx + cAttXmlName
				//cArqAttAch		:= cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2)+ cBarLinx + cAttXmlName
				cArqAttAch		:= cDirNfe + cBarLinx + cAttXmlName

				lSave 			:= oMessage:SaveAttach(y,cXmlSave)
				//Alert(cRootPath+cDirNfe+cAttInfo)

				cText 		:= oMessage:getAttach(y)

				cTextAux	:= cText

				// Se o anexo contiver tag de arquivo xml
				//              Autorizado o uso da NF-e
				//				     <cStat>100</cStat><xMotivo>Autorizado
				//				<xMotivo>Autorizado o uso de NF-e
				//<cStat>100</cStat><xMotivo>Autorizado o uso de NF-e</
				//<cStat>100</cStat><xMotivo>Autorizado o uso de NF-e
				If lSave
					//Aviso("Leitura do XML - Emailmar!",cText,{"Ok"},3)
					lRetGrv	:= .F.
					cTextAux	:= Upper(cTextAux)
					cTextAux	:= StrTran(cTextAux, Chr(13)+ Chr(10),"")
					cTextAux	:= StrTran(cTextAux, Chr(10),"")

					// Verifica se é nota fiscal eletronica
					// Validação simplificada
					If (At("<NFEPROC",cTextAux) > 0 .And. At("<CSTAT>100</CSTAT>",cTextAux) > 0) .Or. (At('<UF>EX</UF>',cTextAux) > 0)
						//Aviso("Entrou para Gravar Xml NFe!",cTextAux,{"Ok"},3)
						Begin Transaction
							lRetGrv := sfGrvXmlNfe(cText,.T.,oMessage,oServer)
						End Transaction
					Endif

				ElseIf !Empty(cText)
					U_WFGERAL( MAILADM ,"Erro ao gravar o arquivo'"+cXmlSave+"'" ,'"'+cText+'"')
				Endif
			Endif
		Next y



		cBodyAux		:= oMessage:cBody
		cSubjectAux		:= oMessage:cSubject
		cToAux			:= oMessage:cTo

		oServer:DeleteMsg( nI )


		If !lRetGrv .And. !Empty(cMsgRetMail)


			//Crio a conexão com o server SMTP ( Envio de e-mail )
			oServer2 := TMailManager():New()

			// Usa SSL na conexao
			If lUSsl
				oServer2:setUseSSL(.T.)
			Endif

			// Usa TLS na conexao
			If lSmtp
				oServer2:SetUseTLS(.T.)
			Endif

			oServer2:Init( ""		,Alltrim( lSmt2 ), Alltrim( lSMTPUSR )	,Alltrim( lPSWSMTP ),	0			, lSMTPPOR  )

			//seto um tempo de time out com servidor de 1min
			If oServer2:SetSmtpTimeOut( SMTPTMT ) != 0
				Conout( "Falha ao setar o time out" )
			EndIf

			//realizo a conexão SMTP
			If oServer2:SmtpConnect() != 0
				Conout( "Falha ao conectar" )
			EndIf

			// Realiza autenticacao no servidor
			If SMTPAUT
				nErr := oServer2:smtpAuth(Alltrim(lSMTPUSR), Alltrim(lPSWSMTP))
				If nErr <> 0
					ConOut("[ERROR]Falha ao autenticar: " + oServer2:getErrorString(nErr))
					Alert("[ERROR]Falha ao autenticar: " + oServer2:getErrorString(nErr))
					oServer2:smtpDisconnect()
				Endif
			Endif
			//Apos a conexão, crio o objeto da mensagem
			oMessage2 := TMailMessage():New()
			//Limpo o objeto
			//Populo com os dados de envio
			oMessage2:cFrom 		:= SMTPDES
			oMessage2:cTo 			:= MAILADM
			// Efetua tratativa para avisar outros destinatários do email de que o email foi rejeitado
			cCcEmail	:= StrTran(StrTran(cToAux,Alltrim( POPUSR),""),";;",";")
			If !Empty(Alltrim(cCcEmail))
				//	oMessage2:cCc 			:= cCcEmail
			Endif

			oMessage2:cSubject 		:= OemToAnsi("Resposta automática de rejeição do Email->"+cSubjectAux)
			oMessage2:MsgBodyType( "text" )
			oMessage2:cBody 		:= OemToAnsi("Email de resposta automática. Não foi possível ler o XML de seu e-mail enviado." + Chr(13)+Chr(10)+cMsgRetMail+ Chr(13)+Chr(10)+cBodyAux + Chr(13)+Chr(10)+"'"+cText+"'")

			//Adiciono um attach
			If oMessage2:AttachFile( cArqAttAch) < 0
				Conout( "Erro ao atachar o arquivo " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
				//	MsgAlert("Não foi possível anexar o arquivo.","Erro" )
			Else
				//adiciono uma tag informando que é um attach e o nome do arq
				oMessage2:AddAtthTag( 'Content-Disposition: attachment; filename='+Alltrim(cAttachName)+"'")
			EndIf

			//Envio o e-mail
			If oMessage2:Send( oServer2 ) != 0
				Conout( "Erro ao enviar o e-mail " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
			EndIf

			//Disconecto do servidor
			If oServer2:SmtpDisconnect() != 0
				Conout( "Erro ao disconectar do servidor SMTP " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
			EndIf

			FreeObj(oServer2)

		Endif



	Next nI



	//Deleto todas as mensagens do servidor
	//	For nI := 1 To nContOk
	//		oServer:DeleteMsg( nI )
	//	Next
	If  Alltrim(GetNewPar("RL_TCPMAIL","POP3")) == "POP3"
		//Diconecto do servidor POP
		oServer:POPDisconnect()
	Else
		//Diconecto do servidor IMAP
		oServer:IMAPDisconnect()
	Endif

	sfChekLock(.F./*lLock*/,cFilAnt/*cKeyLock*/)

Return



Static Function sfChekLock(lLock,cKeyLock)

	Local	nTentativas	:= 0

	If lLock
		While !LockByName("RLFATA02"+cKeyLock,.F.,.F.,.T.)
			MsAguarde({|| Sleep(1000 ) }, "Semaforo de processamento... tentativa "+ALLTRIM(STR(nTentativas)), "Aguarde, arquivo sendo alterado por outro usuário.")//"Semaforo de processamento... tentativa "##"Aguarde, arquivo sendo alterado por outro usuário."
			nTentativas++

			If nTentativas > 3600
				If MsgYesNo("Não foi possível acesso exclusivo. Deseja tentar novamente ?") //"Não foi possível acesso exclusivo para edição do Pré-Projeto da proposta. Deseja tentar novamente ?"
					nTentativas := 0
					Loop
				Else
					Return (.F.)
				EndIf
			EndIf
		EndDo

	Else
		UnLockByName("RLFATA02"+cKeyLock,.F.,.F.,.T.)
	Endif

Return .T.


/*/{Protheus.doc} sfGrvXmlNfe
(Efetua gravação do arquivo xml nas tabelas SZ1 e SZ2)
@type function
@author marce
@since 09/10/2016
@version 1.0
@param cText, character, (Descrição do parâmetro)
/*/
Static Function sfGrvXmlNfe(cText,lMail,oMessage,oServer)

	Local	cTxtGrv		:= cText
	Local	cVldSch		:= cText
	Local	cAviso		:= ""
	Local	cErro		:= ""
	Local	lAcept  	:= .F.
	Local	nX
	//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cText,{"Ok"},3)

	ConOut("+"+Replicate("-",58)+"+")
	ConOut(Padr("| Recebimento de XML - NFe - Função RLFATA02 ",59)+"|")
	ConOut(Padr("| Inicio: "+Time(),59)+"|")

	// <nfeProc versao="2.00" xmlns="http://www.portalfiscal.inf.br/nfe"><NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe Id=
	//<nfeProc versao="2.00" xmlns="http://www.portalfiscal.inf.br/nfe"><NFe><infNFe Id=
	// Se encontrada apenas a tag <NFe> adiciona Atributo
	// Solução adicionada em 21/03/12 para resolver problema de validação de Schema do Microsiga
	If ( nPosIni := At("<NFe>",cVldSch)) > 0
		//<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe
		cVldSch := '<NFe xmlns="http://www.portalfiscal.inf.br/nfe">'+Substr(cVldSch,nPosINi+5)

		// Faz o ajuste do XML também para evitar erro de xml parser
		cTxtGrv := Substr(cTxtGrv,1,nPosIni-1)+cVldSch

	Endif

	If ( nPosIni := At("<NFe",cVldSch)) > 0
		//<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe
		cVldSch := Substr(cVldSch,nPosINi)

	Endif
	If ( nPosIni := At("</infNFe>",cVldSch)) > 0
		cVldSch := Substr(cVldSch,1,nPosINi+8)
		cVldSch += "</NFe>"

	Endif

	// Avalia necessita de retirar caracteres
	cVldSch 	:= sfRemoveCrlf(cVldSch)
	cText		:= sfRemoveCrlf(cText)

	cAviso	:= ""
	cErro	:= ""
	oNfe := XmlParser(cText,"_",@cAviso,@cErro)

	If !Empty(cErro)
		ConOut(Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|")

		cMsgRetMail	+= "Erro de XmlParser - '"+cErro+"' "
		ConOut(Padr("| Erro de XmlParser - '"+cErro+"'",59)+"|")
		ConOut("+"+Replicate("-",58)+"+")
		Return .F.
	Endif
	ConOut(Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|")

	If !Empty(cAviso) .Or. (Type("oNFe:_NfeProc:_nfeProc:_NFe") == "U" .And. Type("oNFe:_InfNfe")== "U" .And. Type("oNFe:_NfeProc:_NFe")== "U" .And. Type("oNFe:_NFe")== "U") //.Or. At("UTF-8",Upper(cTxtGrv)) == 0

		U_WFGERAL(GetNewPar("XM_MAILADM","marcelolauschner@gmail.com"),"Importação xml "+IIf(!Empty(cAviso)," aviso="+cAviso,"forçou ajuste UTF-8") ,'"'+cTxtGrv+'"')

		cErro		:= ""
		cAviso		:= ""
		cTxtGrv		:= sfDecodeUtf(cTxtGrv)
		cTxtGrv		:= sfRemoveCrlf(cTxtGrv)

		If At("UTF-8",Upper(cTxtGrv)) > 0
			cTxtGrv := sfHTMLEnc(cTxtGrv)
		Endif
		cTxtGrv 	:= NoAcento(cTxtGrv)
		cTxtAux   	:= EnCodeUtf8(cTxtGrv)
		If Type("cTxtAux") <> "U"
			cTxtGrv	:= EnCodeUtf8(cTxtGrv)
		Endif

		oNfe := XmlParser(cTxtGrv,"_",@cAviso,@cErro)

		ConOut(Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|")

		If !Empty(cErro)
			MsgAlert(cErro+chr(13)+cAviso,"Erro ao validar schema do Xml")
			cMsgRetMail	+= "Erro XmlParser '"+cErro+"' "
			ConOut(Padr("| Erro de XmlParser - '"+cErro+"'",59)+"|")
			ConOut("+"+Replicate("-",58)+"+")
			Return .F.
		Endif

		If !Empty(cAviso)
			MsgAlert(cErro+chr(13)+cAviso,"Aviso ao validar schema do Xml")
			U_WFGERAL(GetNewPar("XM_MAILADM","marcelolauschner@gmail.com"),"Importação xml Aviso: "+ cAviso ,'"'+cTxtGrv+'"')
			//	Return .F.
		Endif


		cVldSch	:= Alltrim(EnCodeUtf8(NoAcento(sfDecodeUtf(cVldSch),.T.)))

	Endif

	ConOut(Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|")

	If Type("oNFe:_NfeProc:_NFe") <> "U"
		oNF := oNFe:_NFeProc:_NFe
	ElseIf Type("oNFe:_NFe")<> "U"
		oNF := oNFe:_NFe
	ElseIf Type("oNFe:_InfNfe")<> "U"
		oNF := oNFe
	ElseIf Type("oNFe:_NfeProc:_nfeProc:_NFe") <> "U"
		oNF := oNFe:_nfeProc:_NFeProc:_NFe
	Else
		//MsgAlert("Não foi possível importar email do texto: "+cTxtGrv)
		cMsgRetMail	+= "Importação XML - Erro de oNFe "
		//Aviso("Erro de oNFe cText",cText,{"Ok"},3)
		//Aviso("Erro de oNFe cTxtGrv",cTxtGrv,{"Ok"},3)

		ConOut(Padr("| Erro de oNfe - '"+cErro+"'",59)+"|")
		ConOut("+"+Replicate("-",58)+"+")
		Return .F.
	Endif

	ConOut(Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|")

	oIdent     	:= oNF:_InfNfe:_IDE
	oEmitente  	:= oNF:_InfNfe:_Emit
	oDestino   	:= oNF:_InfNfe:_Dest

	// Procura a chave conforme o escopo da formatação do xml
	If Type("oNFe:_NfeProc:_protNFe") <> "U"
		cChave := oNFe:_NFeProc:_protNFe:_infProt:_chNFe:TEXT
	ElseIf Type("oNFe:_protNFe")<> "U"
		cChave := oNFe:_protNFe:_infProt:_chNFe:TEXT
	ElseIf Type("oNFe:_NfeProc:_nfeProc:_protNFe") <> "U"
		cChave := oNFe:_nfeProc:_NFeProc:_protNFe:_infProt:_chNFe:TEXT
	Else
		cChave	:= oEmitente:_CNPJ:TEXT+Padr(oIdent:_serie:TEXT,TamSX3("F1_SERIE")[1]) + Right(StrZero(0,(TamSX3("F1_DOC")[1]) -Len(Trim(oIdent:_nNF:TEXT)) )+oIdent:_nNF:TEXT,TamSX3("F1_DOC")[1])
	Endif

	ConOut(Padr("| "+cChave,59)+"|")


	DbSelectArea("SZ1")
	DbSetOrder(1)

	lExistChv := !DbSeek(xFilial("SZ1") + cChave)

	// Verificou que a chave já existe na base
	If !lExistChv
		// Identificou que a nota fiscal já esta lançada
		ConOut(Padr("Já existe o documento. Não houve o recebimento do XML",59)+"|")
		ConOut("+"+Replicate("-",58)+"+")
		Return .F.

	Endif

	RecLock("SZ1",lExistChv)

	SZ1->Z1_FILIAL 		:= xFilial("SZ1")
	SZ1->Z1_CHAVE		:= cChave
	SZ1->Z1_XML			:= cText
	SZ1->Z1_STATUS		:= Iif(sfConfSefaz(cChave),"1","5") // Se o documento não estiver Ok na Sefaz importa como Cancelado para eventuais ajustes manuais
	SZ1->Z1_TIPNF		:= oIdent:_tpNf:Text // Tipo do Documento Fiscal (0 - entrada; 1 - saída)

	If Type("oEmitente:_CNPJ") <> "U"
		SZ1->Z1_EMIT		:= oEmitente:_CNPJ:TEXT
	ElseIf Type("oEmitente:_CPF") <> "U"
		SZ1->Z1_EMIT		:= oEmitente:_CPF:TEXT
	Endif

	If Type("oDestino:_CNPJ") <> "U"
		SZ1->Z1_DEST			:= oDestino:_CNPJ:TEXT
	ElseIf Type("oDestino:_CPF") <> "U"
		SZ1->Z1_DEST		:= oDestino:_CPF:TEXT
	Endif

	If cLeftNil $ " #0" 		// 0=Padrão(Soh Num c/zeros)
		SZ1->Z1_SERIE		:= Padr(oIdent:_serie:TEXT,TamSX3("F1_SERIE")[1])
		SZ1->Z1_NOTA		:= Right(StrZero(0,(TamSX3("F1_DOC")[1]) -Len(Trim(oIdent:_nNF:TEXT)) )+oIdent:_nNF:TEXT,TamSX3("F1_DOC")[1])
	ElseIf cLeftNil == "1" 	// 1=Num e Serie
		SZ1->Z1_SERIE		:= Right(StrZero(0,(TamSX3("F1_SERIE")[1])-Len(Trim(oIdent:_serie:TEXT)))+oIdent:_serie:TEXT,TamSX3("F1_SERIE")[1])
		SZ1->Z1_NOTA		:= Right(StrZero(0,(TamSX3("F1_DOC")[1]) -Len(Trim(oIdent:_nNF:TEXT)) )+oIdent:_nNF:TEXT,TamSX3("F1_DOC")[1])
	ElseIf cLeftNil == "2"	// 2=Sem preencher zeros
		SZ1->Z1_SERIE		:= Padr(oIdent:_serie:TEXT,TamSX3("F1_SERIE")[1])
		SZ1->Z1_NOTA		:= Padr(oIdent:_nNF:TEXT,TamSX3("F1_DOC")[1])
	Endif

	If Type("oIdent:_dhEmi") <> "U"
		// <dhEmi>2014-04-15T12:02:46-03:00
		cData 	:=	Alltrim(Substr(oIdent:_dhEmi:TEXT,1,10))
	Else
		//<dEmi>2014-04-10
		cData	:=	Alltrim(oIdent:_dEmi:TEXT)
	Endif
	cData	:= StrTran(cData,"-","")
	dData	:=	STOD(cData) //CTOD(Right(cData,2)+'/'+Substr(cData,6,2)+'/'+Left(cData,4))
	SZ1->Z1_EMISSAO			:= dData

	MsUnlock()


	ConOut(Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|")

	oDet       	:= oNF:_InfNfe:_Det

	oDet := IIf(ValType(oDet)=="O",{oDet},oDet)



	DbSelectArea("SZ2")
	DbSetOrder(1)

	// Inicio loop nos itens da nota
	For nX := 1 To Len(oDet)
		nPx	:= nX
		lExistChv := !DbSeek(Padr(cChave,Len(SZ2->Z2_CHAVE)) + StrZero(nX,3))
		RecLock("SZ2",lExistChv)
		SZ2->Z2_FILIAL		:= xFilial("SZ2")
		SZ2->Z2_CHAVE		:= cChave
		SZ2->Z2_ITEM		:= StrZero(nX,3)
		SZ2->Z2_PRODUTO		:= oDet[nX]:_Prod:_cProd:TEXT
		SZ2->Z2_QUANT		:= Val(oDet[nX]:_Prod:_qCom:TEXT)
		SZ2->Z2_CF			:= oDet[nX]:_Prod:_CFOP:TEXT
		// 07/07/2019 - Melhoria para gravar o campo de código FCI
		If Type("oDet[nPx]:_Prod:_nFCI") <> "U"
			SZ2->Z2_FCI			:= oDet[nX]:_Prod:_nFCI:TEXT
		Endif

		// Efetua leitura da Tag infAdProd veri
		If Type("oDet[nPx]:_infAdProd") <> "U"
			If "|At.Estoque:S|" $ Alltrim(oDet[nPx]:_infAdProd:TEXT)
				SZ2->Z2_ESTOQUE := "S"
			Else
				SZ2->Z2_ESTOQUE	:= IIf("06032022" $ SZ1->Z1_EMIT ,"N","S")
			Endif
		Else
			SZ2->Z2_ESTOQUE	:= IIf("06032022" $ SZ1->Z1_EMIT ,"N","S")
		Endif

		Do Case
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS00")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS00
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS10")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS10
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS20")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS20
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS30")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS30
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS40")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS40
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS51")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS51
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS60")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS60
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS70")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS70
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMS90")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMS90
		Case Type("oDet[nPX]:_Imposto:_ICMS:_ICMSST")<> "U"
			oICM:=oDet[nPX]:_Imposto:_ICMS:_ICMSST
		EndCase

		//	Efetua verificação pelas Tags do Simples Nacional
		If Type("oDet[nPX]:_Imposto:_ICMS:_ICMSSN101") <> "U"
			oICM	:= oDet[nPX]:_Imposto:_ICMS:_ICMSSN101
		ElseIf Type("oDet[nPX]:_Imposto:_ICMS:_ICMSSN102") <> "U"
			oICM	:= oDet[nPX]:_Imposto:_ICMS:_ICMSSN102
		ElseIf Type("oDet[nPX]:_Imposto:_ICMS:_ICMSSN201") <> "U"
			oICM	:= oDet[nPX]:_Imposto:_ICMS:_ICMSSN201
		ElseIf Type("oDet[nPX]:_Imposto:_ICMS:_ICMSSN202") <> "U"
			oICM	:= oDet[nPX]:_Imposto:_ICMS:_ICMSSN202
		ElseIf Type("oDet[nPX]:_Imposto:_ICMS:_ICMSSN500") <> "U"
			oICM	:= oDet[nPX]:_Imposto:_ICMS:_ICMSSN500
		ElseIf Type("oDet[nPX]:_Imposto:_ICMS:_ICMSSN900") <> "U"
			oICM	:= oDet[nPX]:_Imposto:_ICMS:_ICMSSN900
		Endif

		If Type("oICM")<> "U"
			If Type("oICM:_orig") <> "U" .And. Type("oICM:_CST") <> "U"
				SZ2->Z2_CLASFIS		:= Padr(Alltrim(oICM:_orig:TEXT)+Alltrim(oICM:_CST:TEXT),TamSX3("D1_CLASFIS")[1])
			Endif
		Endif
		MsUnlock()
	Next

	ConOut(Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|")

	ConOut(Padr("| Fim: "+Time(),59)+"|")
	ConOut("+"+Replicate("-",58)+"+")


Return .T.


/*/{Protheus.doc} sfCriaSX6
(Cria parametros da rotina)
@type function
@author marce
@since 09/10/2016
@version 1.0
/*/
//Static Function sfCriaSX6()
//
//	DbSelectArea("SX6")
//	DbSetOrder(1)
//	// Configuração para POP3/IMAP
//	If !DbSeek(cFilAnt+"RL_TCPMAIL")
//		RecLock("SX6",.T.)
//		SX6->X6_FIL     := xFilial( "SX6" )
//		SX6->X6_VAR     := "RL_TCPMAIL"
//		SX6->X6_TIPO    := "C"
//		SX6->X6_DESCRIC := "Central NF-e/Protocolo de Email"
//		MsUnLock()
//		PutMv("RL_TCPMAIL",GetMv("XM_TCPMAIL"))
//	EndIf
//
//	// Servidor POP
//	If !DbSeek(cFilAnt+"RL_POP   ")
//		RecLock("SX6",.T.)
//		SX6->X6_FIL     := xFilial( "SX6" )
//		SX6->X6_VAR     := "RL_POP"
//		SX6->X6_TIPO    := "C"
//		SX6->X6_DESCRIC := "Central NF-e/Servidor POP"
//		MsUnLock()
//		PutMv("RL_POP",GetMv("XM_POP"))
//	EndIf
//
//	// Porta POP3/POPS 110/465
//	If !DbSeek(cFilAnt+"RL_POPPORT")
//		RecLock("SX6",.T.)
//		SX6->X6_FIL     := xFilial( "SX6" )
//		SX6->X6_VAR     := "RL_POPPORT"
//		SX6->X6_TIPO    := "N"
//		SX6->X6_DESCRIC := "Central NF-e/Porta POP"
//		MsUnLock()
//		PutMv("RL_POPPORT",GetMv("XM_POPPORT"))
//	EndIf
//
//	// Conta usuário POP
//	If !DbSeek(cFilAnt+"RL_POPUSR")
//		RecLock("SX6",.T.)
//		SX6->X6_FIL     := xFilial( "SX6" )
//		SX6->X6_VAR     := "RL_POPUSR"
//		SX6->X6_TIPO    := "C"
//		SX6->X6_DESCRIC := "Central NF-e/Usuário POP"
//		MsUnLock()
//		PutMv("RL_POPUSR",GetMv("XM_POPUSR"))
//	EndIf
//
//	// Senha usuário POP
//	If !DbSeek(cFilAnt+"RL_PSWPOP")
//		RecLock("SX6",.T.)
//		SX6->X6_FIL     := xFilial( "SX6" )
//		SX6->X6_VAR     := "RL_PSWPOP"
//		SX6->X6_TIPO    := "C"
//		SX6->X6_DESCRIC := "Central NF-e/Senha POP"
//		MsUnLock()
//		PutMv("RL_PSWPOP",GetMv("XM_PSWPOP"))
//	EndIf
//
//	// Usa SSL
//	If !DbSeek(cFilAnt+"RL_POPSSL")
//		RecLock("SX6",.T.)
//		SX6->X6_FIL     := xFilial( "SX6" )
//		SX6->X6_VAR     := "RL_POPSSL"
//		SX6->X6_TIPO    := "L"
//		SX6->X6_DESCRIC := "Central NF-e/POP Usa SSL"
//		MsUnLock()
//		PutMv("RL_POPSSL",GetMv("XM_POPSSL"))
//	EndIf
//
//Return



/*/{Protheus.doc} sfRemoveCrlf
(Remove quebras de linhas )
@type function
@author marce
@since 09/10/2016
@version 1.0
@param cInXml, character, (Descrição do parâmetro)
/*/
Static Function sfRemoveCrlf(cInXml)

	Local		cRet	:= ""
	Local		aXml	:= {}
	Local		ix
	Local		nCnt77	:= 0
	Local		nCnt75 	:= 0

	//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cInXml,{"Ok"},3)

	aXml	:=	StrTokArr(cInXml,Chr(13))

	// Verifico primeiro para ver se o texto está formato com quebras de linhas forçadas
	For iX := 1 To Len(aXml)
		If Len(aXml[iX]) == 77
			nCnt77++
		Endif
		If Len(aXml[iX]) == 75
			nCnt75++
		Endif
	Next

	For iX := 1 To Len(aXml)
		cRet += StrTran(aXml[iX],Chr(10),'')
		// Se a quebra de linha for com menos de 77 colunas, adiciona um espaço no texto
		If (Len(aXml[iX]) < 77) .And. nCnt77 > 0
			cRet += ' '
		Endif
		If (Len(aXml[iX]) < 75) .And. nCnt75 > 0
			cRet += ' '
		Endif
	Next

	// Caso não tenha havido nenhuma quebra de linha, retorna informação original.
	If Empty(cRet)
		cRet := cInXml
	Endif

	// 17/12/2014 - Melhoria a pedido da Concretomix para corrigir falha de xmls com espaço nas tags
	cRet	:= StrTran(cRet,"</ ","</")
	cRet	:= StrTran(cRet,"</Re ference>","</Reference>")
	cRet	:= StrTran(cRet,">< veicTransp","><veicTransp")
	cRet	:= StrTran(cRet,"<Dige stValue>","<DigestValue>")
	cRet	:= StrTran(cRet,">5 3<",">53<")
	cRet   	:= StrTran(cRet," & "," &amp; ")
	cRet  	:= StrTran(cRet,"T&A","T&amp;A")
	cRet	:= StrTran(cRet, Chr(195) + Chr(152),"0")
	cRet	:= StrTran(cRet, Chr(216) , "0" )
	cRet	:= StrTran(cRet, "?<?xml","<?xml")
	cRet	:= StrTran(cRet,"infModalversaoModal","infModal versaoModal")
	// 15/06/2017 - Corrige uma falha de arquivo XMLs enviados por um fornecedor TRANSMENDES TRANSPORTES RODOVIARIOS LTDA ME
	cRet	:= StrTran(cRet,"</xNome><UF/><tpProp>0</tpProp>","</xNome><tpProp>0</tpProp>")
	// 19/07/2017 - Corrige leitura de Tag não convertida

	// 25/07/2017
	cRet	:= StrTran(cRet,"</det><detnItem=","</det><det nItem=")

	// 10/08/2017
	cRet	:= StrTran(cRet,"<vICMS>0>","")

	//01/03/2018
	cRet	:= StrTran(cRet,'xCampo="Lei da TransparC*ncia','xCampo="Lei da Transparencia')
	// Adiciona uma tag de fechamento
	If At("</nfeProc",cRet) > 0 .And. At("</nfeProc>",cRet) == 0
		cRet += ">"
	Endif

	// 11/04/2018
	// Adiciona uma tag de fechamento
	If At("</nfePro",cRet) > 0 .And. At("</nfeProc>",cRet) == 0
		cRet += "c>"
	Endif
	// Adiciona uma tag de fechamento
	If At("</cteProc",cRet) > 0 .And. At("</cteProc>",cRet) == 0
		cRet += ">"
	Endif
	// Adiciona uma tag de fechamento
	If At("</ctePro",cRet) > 0 .And. At("</cteProc>",cRet) == 0
		cRet += "c>"
	Endif

	// 23/05/2018 - Adiciona uma tag de fechamento
	If At("<procEventoNFe",cRet) > 0 .And. At("</procEventoNFe",cRet) > 0 .And. At("</procEventoNFe>",cRet) == 0
		cRet := Alltrim(cRet) + ">"
	Endif

	// 03/05/2018 - Adiciona uma tag de fechamento
	If At("<procEventoNFe",cRet) > 0 .And. At("</procEventoNFe>",cRet) == 0
		cRet := Alltrim(cRet) + "e>"
	Endif
	// 06/07/2018 - Adiciona uma tag de Fechamento
	If At("<procEventoCTe",cRet) > 0 .And. At("</procEventoCTe>",cRet) == 0
		cRet := Alltrim(cRet) + ">"
	Endif

	// 02/09/2017 - Corrige formato do XML para evitar Aviso do Xmlparser
	cRet	:= StrTran(cRet,"version='1.0'",'version="1.0"')
	cRet	:= StrTran(cRet,"encoding='UTF-8'",'encoding="UTF-8"')


	cRet	:= StrTran(cRet, Chr(13)+ Chr(10),"")
	cRet	:= StrTran(cRet, Chr(10),"")

	cRet	:= StrTran(cRet, "_"," ")
	cRet 	:= StrTran(cRet,"ï»¿","")
	//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cRet,{"Ok"},3)

Return cRet

/*/{Protheus.doc} NoAcento
Remove vogais acentuadas Função copiada do NfeSefaz
@type function
@author Marcelo Alberto Lauschner
@since 16/02/2021
/*/
Static Function NoAcento(cString,lVldSch)
	Local 		cChar  		:= ""
	Local 		nX     		:= 0
	Local 		nY     		:= 0
	Local 		cVogal 		:= "aeiouAEIOU"
	Local 		cAgudo 		:= "áéíóú"+"ÁÉÍÓÚ"
	Local 		cCircu 		:= "âêîôû"+"ÂÊÎÔÛ"
	Local 		cTrema 		:= "äëïöü"+"ÄËÏÖÜ"
	Local 		cCrase 		:= "àèìòù"+"ÀÈÌÒÙ"
	Local 		cTio   		:= "ãõÃÕ"
	Local 		cCecid 		:= "çÇ"
	Local 		cCrlf	 	:= Chr(13)
	Local 		cRet		:= Chr(10)
	Local 		cBuffer		:= cString
	Default		lVldSch		:= .F.

	For nX:= 1 To Len(cString)
		cChar := SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase+cCrlf +cRet
			nY:= At(cChar,cAgudo)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,SubStr("aoAO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,SubStr("cC",nY,1))
			EndIf
			nY:= At(cChar,cCrlf)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,"")
			EndIf
			nY:= At(cChar,cRet)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar,"")
			EndIf
		Endif

	Next
	/*If lVldSch
	For nX:=1 To Len(cBuffer)
	cChar := SubStr(cString, nX, 1)
	If Asc(cChar) < 32 .Or. Asc(cChar) > 123
	cString:=StrTran(cString,cChar,"")
	Endif
	Next nX
	Endif*/
	//If lIsDebug
	//	Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cBuffer,{"Ok"},3)
	//Endif

Return cBuffer


/*/{Protheus.doc} sfHTMLEnc
(Converte UTF8 para ASCII)
@type function
@author marce
@since 07/07/2012
@version 1.0
@param xString, variável, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfHTMLEnc(xString)

	Local cBuffer := xString

	Do Case
		Case ValType(xString)=="C"

			cBuffer := Strtran(cBuffer, "&amp;","&" )
			cBuffer := Strtran(cBuffer, "&quot;",'"')
			cBuffer := Strtran(cBuffer, "&lt;","<")
			cBuffer := Strtran(cBuffer, "&gt;",">")
		Case ValType(xString)=="N"
			cBuffer := Str(xString)
	EndCase

	//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" sfHTMLEnc",cBuffer,{"Ok"},3)

Return cBuffer


/*/{Protheus.doc} sfDecodeUtf
(Remover acentuação UTF-8 e manter formatação como o Windows interpreta o visual do XML)
@author MarceloLauschner
@since 26/04/2014
@version 1.0
@param xString, variável, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
/*/
Static Function sfDecodeUtf(xString)

	Local	cBuffer		:= ""  //Ã‰ Ã€ Ãü Ãë Ãç
	Local	aAcento		:= {"á" , "à", "â", "ã", "ä", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ó", "ò", "ô", "õ", "ö", "ú", "ù", "û", "ü", "ç","Á", "À", "Â", "Ã", "Ä", "É", "È", "Ê", "Ë" , "Í" ,"Í"			, "Ì" , "Î","Ï" ,"Ó", "Ò" , "Ô", "Õ", "Ö","Ú" ,"Ù" ,"Û", "Ü" ,"Ç"          , "Ç" ,"Á" ,"É" ,"Ç"	 ,"Á"				,"Ã"  ,"Õ" ,"Á"  ," "	}
	Local	aUtf8 		:= {"Ã¡","Ã ","Ã¢","Ã£","Ã¤","Ã©","Ã¨","Ãª","Ã«","Ã­","Ã¬","Ã®","Ã¯","Ã³","Ã²","Ã´","Ãµ","Ã¶","Ãº","Ã¹","Ã»","Ã¼","Ã§","Ã?","Ã€","Ã‚","Ãƒ","Ã„","Ã‰","Ãˆ","ÃŠ","Ã‹","Ã?" ,"Ã"+chr(141), "ÃŒ","ÃŽ","Ã?","Ã“","Ã’","Ã”","Ã•","Ã–","Ãš","Ã™","Ã›","Ãœ","Ç"+Chr(135) , "Ã‡","Ãü","Ãë","Ãç" ,"Ã"+chr(129)+"S"  ,"Ãâ", "Ãò","Ãü",""	}
	Local	iC,iU
	Local	lExistUtf8	:= .F.

	Aadd(aAcento,"É" )
	Aadd(aUtf8  ,"Ã‰")

	Aadd(aAcento,"Á")
	Aadd(aUtf8  ,"Ã" + Chr(129))

	//0xA0 0x20 0x4b 0x4D

	Do Case
		Case ValType(xString) == "C"
			For iC := 1 To Len(xString)
				lExistUtf8		:= .F.
				For iU := 1 To Len(aAcento)
					If Substr(xString,iC,2) == aUtf8[iU]
						cBuffer	+= aAcento[iU]
						lExistUtf8		:= .T.
						iC++ // Acrescenta 1 ao contador por que são 2 caracteres substituidos
					Endif
				Next
				If !lExistUtf8
					cBuffer	+= Substr(xString,iC,1)
				Endif
			Next
		Case ValType(xString) == "N"
			cBuffer	:= Str(xString)
	EndCase
	//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cBuffer,{"Ok"},3)

Return cBuffer



/*/{Protheus.doc} sfConfSefaz
(Efetua consulta da NFe via Webservice para garantir que a chave eletrônica esteja autorizada)
@type function
@author marce
@since 09/10/2016
@version 1.0
@param cInChave, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfConfSefaz(cInChave)

	Local	lRet	:= .T.

	Local	cURL     	:= PadR(GetNewPar("MV_SPEDURL","http://"),250)
	// Verifico se a empresa em cursor tem TSS configurado
	Local	cIdentSPED	:= Iif(GetNewPar("XM_TSSEXIS",.T.),U_MLTSSENT()," ")

	If !Empty(cIdentSPED)

		oWS := WsSPEDAdm():New()
		oWS:cUSERTOKEN := "TOTVS"
		oWS:oWSEMPRESA:cCNPJ       := IIF(SM0->M0_TPINSC==2 .Or. Empty(SM0->M0_TPINSC),SM0->M0_CGC,"")
		oWS:oWSEMPRESA:cCPF        := IIF(SM0->M0_TPINSC==3,SM0->M0_CGC,"")
		oWS:oWSEMPRESA:cIE         := SM0->M0_INSC
		oWS:oWSEMPRESA:cIM         := SM0->M0_INSCM
		oWS:oWSEMPRESA:cNOME       := SM0->M0_NOMECOM
		oWS:oWSEMPRESA:cFANTASIA   := SM0->M0_NOME
		oWS:oWSEMPRESA:cENDERECO   := FisGetEnd(SM0->M0_ENDENT)[1]
		oWS:oWSEMPRESA:cNUM        := FisGetEnd(SM0->M0_ENDENT)[3]
		oWS:oWSEMPRESA:cCOMPL      := FisGetEnd(SM0->M0_ENDENT)[4]
		oWS:oWSEMPRESA:cUF         := SM0->M0_ESTENT
		oWS:oWSEMPRESA:cCEP        := SM0->M0_CEPENT
		oWS:oWSEMPRESA:cCOD_MUN    := SM0->M0_CODMUN
		oWS:oWSEMPRESA:cCOD_PAIS   := "1058"
		oWS:oWSEMPRESA:cBAIRRO     := SM0->M0_BAIRENT
		oWS:oWSEMPRESA:cMUN        := SM0->M0_CIDENT
		oWS:oWSEMPRESA:cCEP_CP     := Nil
		oWS:oWSEMPRESA:cCP         := Nil
		oWS:oWSEMPRESA:cDDD        := Str(FisGetTel(SM0->M0_TEL)[2],3)
		oWS:oWSEMPRESA:cFONE       := AllTrim(Str(FisGetTel(SM0->M0_TEL)[3],15))
		oWS:oWSEMPRESA:cFAX        := AllTrim(Str(FisGetTel(SM0->M0_FAX)[3],15))
		oWS:oWSEMPRESA:cEMAIL      := UsrRetMail(RetCodUsr())
		oWS:oWSEMPRESA:cNIRE       := SM0->M0_NIRE
		oWS:oWSEMPRESA:dDTRE       := SM0->M0_DTRE
		oWS:oWSEMPRESA:cNIT        := IIF(SM0->M0_TPINSC==1,SM0->M0_CGC,"")
		oWS:oWSEMPRESA:cINDSITESP  := ""
		oWS:oWSEMPRESA:cID_MATRIZ  := ""
		oWS:oWSOUTRASINSCRICOES:oWSInscricao := SPEDADM_ARRAYOFSPED_GENERICSTRUCT():New()
		oWS:_URL := AllTrim(cURL)+"/SPEDADM.apw"

		If oWs:ADMEMPRESAS()
			cIdEnt  := oWs:cADMEMPRESASRESULT
		Else
			Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
		EndIf

		// Trecho para validar autorização da NF
		cMensagem:= ""
		oWs:= WsNFeSBra():New()
		oWs:cUserToken   := "TOTVS"
		oWs:cID_ENT    	 := cIdEnt
		ows:cCHVNFE		 := cInChave
		oWs:_URL         := AllTrim(cURL)+"/NFeSBRA.apw"

		If oWs:ConsultaChaveNFE()
			cMensagem := ""
			If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cVERSAO)
				cMensagem += STR0129+": "+oWs:oWSCONSULTACHAVENFERESULT:cVERSAO+CRLF
			EndIf
			cMensagem += STR0035+": "+IIf(oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1,STR0056,STR0057)+CRLF //"Produção"###"Homologação"
			cMensagem += STR0068+": "+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE+CRLF
			cMensagem += STR0069+": "+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE+CRLF
			If oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1 .And. !Empty(oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO)
				cMensagem += STR0050+": "+oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO+CRLF
			EndIf
			// Nota fiscal Autorizada
			If Alltrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "100"
				lRet	:=	.T.
				// Nota fiscal Cancelada - Cancelamento autorizado
			ElseIf Alltrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "101"
				lRet	:=	.F.
			Else
				Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+STR0107,cMensagem+Chr(13)+Chr(10)+"Nota fiscal do Fornecedor/Cliente",{"Ok"},3)
			Endif
			//	Aviso(STR0107,cMensagem,{STR0114},3)
		Else
			Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{STR0114},3)
		EndIf
	Else
		Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{STR0114},3)
	Endif

Return lRet
