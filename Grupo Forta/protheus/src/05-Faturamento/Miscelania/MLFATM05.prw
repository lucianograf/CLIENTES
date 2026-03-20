#include 'protheus.ch'
#include 'parmtype.ch'

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


/*/{Protheus.doc} MLFATM05
// Função responsável por efetuar a leitura de XMLs de uma Caixa Postal e gravar na ZD2 - Itens Nota fiscal Broker ( Iconic x Atrialub )
@author Marcelo Alberto Lauschner
@since 11/07/2019
@version 1.0
@return Nil
@type User Function
/*/
User function MLFATM05()

	// Garante que a importação só ocorre pela empresa/filial específica

	// Verifica se a execução está no agendamento
	If IsBlind()

		sfCriaSX6()

		sfRecMail()

	ElseIf MsgYesNO("Deseja realmente executar o processo de importação de e-mails da caixa postal 'Broker'? ")

		sfCriaSX6()

		sfRecMail()
	Endif


Return


/*/{Protheus.doc} SchedDef
// Permite que a função possa ser colocada no agendamento do Schedule
@author Marcelo Alberto Lauschner
@since 15/07/2019
@version 1.0
@return
@type function
/*/
Static Function SchedDef()

	Local	aOrd	:= {}
	Local	aParam	:= {}

	Aadd(aParam,"P")
	Aadd(aParam,"PARAMDEF")
	Aadd(aParam,"")
	Aadd(aParam,aOrd)
	Aadd(aParam,)

Return aParam



/*/{Protheus.doc} sfCriaSX6
// Função que os parâmetros usados na rotina, Conta de Email e servidores de acesso
@author Marcelo Alberto Lauschner
@since 11/07/2019
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfCriaSX6()

	Local 	cFilX6 	:= xFilial("ZD2")

	DbSelectArea("SX6")
	DbSetOrder(1)
	// Configuração para POP3/IMAP
	If !DbSeek(cFilX6+"GF_M40TCPM")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilX6
		SX6->X6_VAR     := "GF_M40TCPM"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "BFFATM40-Broker/Protocolo de Email"
		MsUnLock()
		PutMv("GF_M40TCPM",GetMv("XM_TCPMAIL"))
	EndIf

	// Servidor POP
	If !DbSeek(cFilX6+"GF_M40SPOP")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilX6
		SX6->X6_VAR     := "GF_M40SPOP"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "BFFATM40-Broker/Servidor POP"
		MsUnLock()
		PutMv("GF_M40SPOP",GetMv("XM_POP"))
	EndIf

	// Porta POP3/POPS 110/465
	If !DbSeek(cFilX6+"GF_M40PORT")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilX6
		SX6->X6_VAR     := "GF_M40PORT"
		SX6->X6_TIPO    := "N"
		SX6->X6_DESCRIC := "BFFATM40-Broker/Porta POP"
		MsUnLock()
		PutMv("GF_M40PORT",GetMv("XM_POPPORT"))
	EndIf

	// Conta usuário POP
	If !DbSeek(cFilX6+"GF_M40USER")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilX6
		SX6->X6_VAR     := "GF_M40USER"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "BFFATM40-Broker/Usuário POP"
		MsUnLock()
		PutMv("GF_M40USER","xmltww@grupoforta.com.br")
	EndIf

	// Senha usuário POP
	If !DbSeek(cFilX6+"GF_M40PSWD")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilX6
		SX6->X6_VAR     := "GF_M40PSWD"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "BFFATM40-Broker/Senha POP"
		MsUnLock()
		PutMv("GF_M40PSWD","XmlBrid@6655")
	EndIf

	// Usa SSL
	If !DbSeek(cFilX6+"GF_M40USSL")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilX6
		SX6->X6_VAR     := "GF_M40USSL"
		SX6->X6_TIPO    := "L"
		SX6->X6_DESCRIC := "BFFATM40-Broker/POP Usa SSL"
		MsUnLock()
		PutMv("GF_M40USSL",GetMv("XM_POPSSL"))
	EndIf

Return



/*/{Protheus.doc} sfRecMail
//  Função responsável por se conectar a caixa postal e efetuar o recebimento dos e-mails e anexos
@author Marcelo Alberto Lauschner
@since 11/07/2019
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfRecMail()

	Local	y
	Local	nI
	Local 	nW
	Local	cSubjectAux		:= ""
	Local	cBodyAux		:= ""
	Local	cToAux			:= ""
	Local	cAttInfo		:= ""

	Local	nRet3,nRet4,nRet5
	Local	cBarLinx		:= IIf(IsSrvUnix(),"/","\")
	Local	cDirNfe    		:= IIf(IsSrvUnix(),StrTran( GetNewPar("XM_DIRXML",cBarLinx+"nf-e"+cBarLinx),"\","/"),GetNewPar("XM_DIRXML",cBarLinx+"nf-e"+cBarLinx))
	Local	cDirMailNfe 	:= cDirNfe + "mail" + cBarLinx	//	IIf(IsSrvUnix(),cDirNfe+"mail/", cDirNfe+"Mail\")
	Local   cDirXmlOld		:= cDirNfe + "importados" + cBarLinx + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2)+cBarLinx
	Local   cRootPath		:= GetSrvProfString ("RootPath","\indefinido")
	Local	lAutoExec		:= IsBlind()
	Local	cLeftNil		:= GetNewPar("XM_LEFTNIL","0")
	Local	aSize 			:= MsAdvSize()
	Local	nRet1			:= MakeDir(cDirNfe)
	Local	nRet2 			:= MakeDir(cDirMailNfe)
	Local	oServer
	Local	oMessage
	Local	nTam
	Local	nContOk
	Local	cChave
	Local	lRetGrv 		:= .T.
	Local	lSave			:= .T.
	Local	cFileSave		:= ""
	Local	cXmlSave		:= ""
	Local	cAttachName		:= ""
	Local	cAttXmlName		:= ""
	Local	cMsgRetMail		:= ""
	Local	aAttInfo		:= {}
	Local	cArqAttAch
	Local	cText
	Local	cTextAux

	//Crio uma nova conexão, agora de POP
	oServer 	:= TMailManager():New()


	// Usa SSL na conexao
	If GetMv("GF_M40USSL")
		oServer:setUseSSL(.T.)
	Endif


	// Efetua conexão com o servidor de e-mail
	oServer:Init( Alltrim(GetMv("GF_M40SPOP")),"", Alltrim(GetMv("GF_M40USER"))	,Alltrim(GetMv("GF_M40PSWD")), GetMv("GF_M40PORT") ,0)

	// Verifica o protoco de email
	If  Alltrim(GetNewPar("GF_M40TCPM","POP3")) == "POP3"
		If oServer:SetPopTimeOut( 60 ) != 0
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao setar o time out"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return .F.
		EndIf

		If oServer:PopConnect() != 0
			FWLogMsg("INFO", /*cTransactionId*/, Funname()/*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao conectar"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return .F.
		EndIf
	Else

		If oServer:IMAPConnect() != 0
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao conectar"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Alert("Falha ao conectar Imap")
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

	nRet5 := 0
	// Cria o Diretorio se precisar
	If !(ExistDir(cDirNfe + StrZero(Year(Date()),4)))
		nRet3	:= MakeDir(cDirNfe + StrZero(Year(Date()),4))
	Endif

	If !(ExistDir(cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) ))
		nRet4	:= MakeDir(cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) )
	Endif
	If !(ExistDir(cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2)))
		nRet5	:= MakeDir(cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2))
	Endif

	If nRet5 <> 0
		If lAutoExec
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não foi possível criar o diretório. Erro: " + cValToChar( FError() )/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Else
			Aviso( "Não possível criar o diretório. "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))), + cValToChar( FError() ) + Chr(13)+;
				cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2), { "Ok" }, 2 )
		Endif
	Endif

	ProcRegua(nTam)

	//MsgInfo("Entrei mensagem " + cValToChar(nI) + " / " + cValToChar(nTam),"MLFATM05 - Receber email")

	For nI := 1 To nTam


		//IncProc("Recebendo email "+Alltrim(Str(nI)) + " / " + Alltrim(Str(nTam))+ ". Aguarde!" )
		oMessage 	:= TMailMessage():New()
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
		nW 	:=  oMessage:getAttachCount()

		//MsgInfo("Vou deletar a mensagem" + cValToChar(nI) + " / " + cValToChar(nTam),"MLFATM05 - Receber email")


		For y := 1 To nW

			aAttInfo:= oMessage:getAttachInfo(y)

			//MsgInfo("Lendo anexo " + cValToChar(y) + " / " + cValToChar(nW),"MLFATM05 - Receber email")
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
				cXmlSave	:= cRootPath + cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2)+ cBarLinx + cAttXmlName
				cArqAttAch	:= cDirNfe + StrZero(Year(Date()),4) + cBarLinx + StrZero(Month(Date()),2) + cBarLinx + StrZero(Day(Date()),2)+ cBarLinx + cAttXmlName

				lSave 		:= oMessage:SaveAttach(y,cXmlSave)

				cText 		:= oMessage:getAttach(y)

				cTextAux	:= cText

				If lSave
					lRetGrv	:= .F.
					cTextAux	:= Upper(cTextAux)
					cTextAux	:= StrTran(cTextAux, Chr(13)+ Chr(10),"")
					cTextAux	:= StrTran(cTextAux, Chr(10),"")

					// Verifica se é nota fiscal eletronica
					// Validação simplificada
					If (At("<NFEPROC",cTextAux) > 0 .And. At("<CSTAT>100</CSTAT>",cTextAux) > 0) .Or. (At('<UF>EX</UF>',cTextAux) > 0)
						//Aviso("Entrou para Gravar Xml NFe!",cTextAux,{"Ok"},3)
						Begin Transaction
							lRetGrv := sfGrvXmlNfe(cText,@cMsgRetMail)
						End Transaction
					Endif

				ElseIf !Empty(cText)
					cMsgRetMail	+= "Erro ao gravar o arquivo'" + cXmlSave + "' Valor variável cText: '" +cText+ "'"
				Endif
			Endif
		Next y

		//MsgInfo("Sai da leitura de anexos da mensagem " + cValToChar(nI) + " / " + cValToChar(nTam),"MLFATM05 - Receber email")



		If !lRetGrv .And. !Empty(cMsgRetMail)
			MsgAlert(cMsgRetMail)
		Endif
		oServer:DeleteMsg( nI )

	Next nI

	If  Alltrim(GetNewPar("GF_M40TCPM","POP3")) == "POP3"
		//Diconecto do servidor POP
		oServer:POPDisconnect()
	Else
		//Diconecto do servidor IMAP
		oServer:IMAPDisconnect()
	Endif

Return


/*/{Protheus.doc} sfGrvXmlNfe
//TODO Descrição auto-gerada.
@author Marcelo Alberto Lauschner
@since 15/07/2019
@version 1.0
@return ${return}, ${return_description}
@param cText, characters, descricao
@param lMail, logical, descricao
@param oMessage, object, descricao
@param oServer, object, descricao
@param cMsgRetMail, characters, descricao
@type function
/*/
Static Function sfGrvXmlNfe(cText,cMsgRetMail)

	Local	cTxtGrv		:= cText
	Local	cVldSch		:= cText
	Local	cAviso		:= ""
	Local	cErro		:= ""
	Local	lAcept  	:= .F.
	Local	cParcela	:= " "
	Local	nX
	Local 	nForC
	Local	nPosIni
	Local	cTxtAux		:= ""
	Local	cDirSchema 	:= IIf(IsSrvUnix(),"/schemas/", "\schemas\")
	Local	cNavegado	:= ""
	Local	oDlgSef
	Local	oTIBrowser
	Local	cChave
	Local	cData
	Local	dData
	Local	cCgcEmit	:= ""
	Local	cCodFilEmit	:= ""
	Local	cCodFilDest	:= ""
	Private oIdent
	Private oDestino
	Private oEmitente
	Private oNfe
	Private oNF
	Private oDet
	Private oCobr
	Private oICM
	Private oIPI
	Private oPIS
	Private oCOF
	Private nPx

	//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cText,{"Ok"},3)

	FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("| Recebimento de XML - NFe - Função BFFATM40 ",59)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

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
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

		cMsgRetMail	+= "Erro de XmlParser - '"+cErro+"' "
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("| Erro de XmlParser - '"+cErro+"'",59)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Return .F.
	Endif

	If !Empty(cAviso) .Or. (ValAtrib("oNFe:_NfeProc:_nfeProc:_NFe") == "U" .And. ValAtrib("oNFe:_InfNfe")== "U" .And. ValAtrib("oNFe:_NfeProc:_NFe")== "U" .And. ValAtrib("oNFe:_NFe")== "U") //.Or. At("UTF-8",Upper(cTxtGrv)) == 0
		U_MLXSNDML(GetNewPar("XM_MAILADM","marcelolauschner@gmail.com"),"Importação xml "+IIf(!Empty(cAviso)," aviso="+cAviso,"forçou ajuste UTF-8") ,'"'+cTxtGrv+'"')

		cErro		:= ""
		cAviso		:= ""
		cTxtGrv		:= sfDecodeUtf(cTxtGrv)
		cTxtGrv		:= sfRemoveCrlf(cTxtGrv)

		If At("UTF-8",Upper(cTxtGrv)) > 0
			cTxtGrv := sfHTMLEnc(cTxtGrv)
		Endif
		cTxtGrv 	:= NoAcento(cTxtGrv)
		cTxtAux   	:= EnCodeUtf8(cTxtGrv)
		If ValAtrib("cTxtAux") <> "U"
			cTxtGrv	:= EnCodeUtf8(cTxtGrv)
		Endif

		oNfe := XmlParser(cTxtGrv,"_",@cAviso,@cErro)


		If !Empty(cErro)
			MsgAlert(cErro+chr(13)+cAviso,"Erro ao validar schema do Xml")
			cMsgRetMail	+= "Erro XmlParser '"+cErro+"' "
			U_WFGERAL(GetNewPar("XM_MAILADM","marcelolauschner@gmail.com"),"Importação xml - "+cErro ,'"'+cTxtGrv+'"')
			FWLogMsg("INFO", /*cTransactionId*/, Funname()/*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("| Erro de XmlParser - '"+cErro+"'",59)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return .F.
		Endif

		If !Empty(cAviso)
			MsgAlert(cErro+chr(13)+cAviso,"Aviso ao validar schema do Xml")
			U_WFGERAL(GetNewPar("XM_MAILADM","marcelolauschner@gmail.com"),"Importação xml Aviso: "+ cAviso ,'"'+cTxtGrv+'"')
			//	Return .F.
		Endif


		cVldSch	:= Alltrim(EnCodeUtf8(NoAcento(sfDecodeUtf(cVldSch),.T.)))

	Endif

	FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("| "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),59)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	If File(cDirSchema+"nfe_v"+NfeIdSPED(cVldSch,"versao")+".xsd")
		//Aviso("Xml",Alltrim(EnCodeUtf8(NoAcento(sfDecodeUtf(cVldSch)))),{"Xml"},3           )
		//cVldSch	:= Alltrim(EnCodeUtf8(NoAcento(sfDecodeUtf(cVldSch),.T.)))
		cVldSch		:= sfDecodeUtf(cVldSch)
		cVldSch 	:= NoAcento(cVldSch,.T.)
		cTxtAux   	:= EnCodeUtf8(cVldSch)
		If ValAtrib("cTxtAux") <> "U"
			cVldSch	:= EnCodeUtf8(cVldSch)
		Endif

		cErro		:= ""
		cAviso		:= ""

		If 	At('<UF>EX</UF>',Upper(cText)) == 0 .And. !XmlSVldSchema( cVldSch, cDirSchema+"nfe_v"+NfeIdSPED(cVldSch,"versao")+".xsd", @cErro, @cAviso )

			//MsgAlert(cErro+chr(13)+cAviso,"Erro ao validar schema do Xml")

			// Adicionada exceção que permite importar XML´s de Sistema de Importação que Gera XML no Layout da NF-e porém sem ser autorizada e nem ter CHAVE
			If At('<UF>EX</UF>',Upper(cText)) == 0
				cNavegado	:= "http://www.sefaz.rs.gov.br/NFE/NFE-VAL.aspx"

				If !IsBlind()
					Aviso("XML com Schema Inválido! Copie o Texto abaixo e cole na próxima tela!",cText,{"Ok"},3)
					//Aviso("XML com Schema Inválido! Copie o Texto abaixo e cole na próxima tela!",cVldSch,{"Ok"},3)

					Define MsDialog oDlgSef From 0,0 TO aSize[6] , aSize[5]  Pixel Title "Web Browser"
					@ 005,010 Say "Xml" of oDlgSef Pixel
					@ 015,010 MsGet oNavegado Var cNavegado Size 300,05 Of oDlgSef Pixel
					oTIBrowser:= TIBrowser():New(025,010, aSize[5]/2.04,aSize[6]/2, cNavegado, oDlgSef )

					// parametro que permite o aceite de xml fora do schema xsd
					//If GetNewPar("XM_VLSCHFC",.T.)
					@ 010, 440 Button oBtnSair PROMPT "Aceitar" Size 40,10 Action(lAcept  := .T.,oDlgSef:End()) Of oDlgSef Pixel
					//Endif

					@ 010, 490 Button oBtnSair PROMPT "Sair" Size 40,10 Action(oDlgSef:End()) Of oDlgSef Pixel

					Activate MsDialog oDlgSef Centered

					oDlgSef := Nil
				Else
					lAcept	:= GetNewPar("XM_VLSCHFC",.T.)
				Endif

				cMsgRetMail	+= "Schema inválido do XML Aviso:'"+cAviso+"' - Erro :'"+cErro+"' "

				If !lAcept
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("| Schema inválido - '"+cAviso+"-"+cErro+"'",59)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					Return .F.
				Endif

			Else
				If !IsBlind()
					If At('<UF>EX</UF>',Upper(cText)) > 0
						Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"Nota com UF=Exterior",cText,{"Ok"},3)
					Else
						Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"XML sem ID da Chave !",cText,{"Ok"},3)
					Endif
				Endif
			Endif
		Else
			//Aviso("XML com Schema Validado!",cText,{"Ok"},3)
		Endif
	Endif

	If ValAtrib("oNFe:_NfeProc:_NFe") <> "U"
		oNF := oNFe:_NFeProc:_NFe
	ElseIf ValAtrib("oNFe:_NFe")<> "U"
		oNF := oNFe:_NFe
	ElseIf ValAtrib("oNFe:_InfNfe")<> "U"
		oNF := oNFe
	ElseIf ValAtrib("oNFe:_NfeProc:_nfeProc:_NFe") <> "U"
		oNF := oNFe:_nfeProc:_NFeProc:_NFe
	Else
		cMsgRetMail	+= "Importação XML - Erro de oNFe "
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("| Erro de oNfe - '"+cErro+"'",59)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Return .F.
	Endif

	oIdent     	:= oNF:_InfNfe:_IDE
	oEmitente  	:= oNF:_InfNfe:_Emit
	oDestino   	:= oNF:_InfNfe:_Dest

	If ValAtrib("oNF:_InfNfe:_Cobr") <> "U"
		oCobr		:= oNF:_InfNfe:_Cobr
	Endif
	// Procura a chave conforme o escopo da formatação do xml
	If ValAtrib("oNFe:_NfeProc:_protNFe") <> "U"
		cChave := oNFe:_NFeProc:_protNFe:_infProt:_chNFe:TEXT
	ElseIf ValAtrib("oNFe:_protNFe")<> "U"
		cChave := oNFe:_protNFe:_infProt:_chNFe:TEXT
	ElseIf ValAtrib("oNFe:_NfeProc:_nfeProc:_protNFe") <> "U"
		cChave := oNFe:_nfeProc:_NFeProc:_protNFe:_infProt:_chNFe:TEXT
	Else
		cChave	:= oEmitente:_CNPJ:TEXT+Padr(oIdent:_serie:TEXT,TamSX3("F1_SERIE")[1]) + Right(StrZero(0,(TamSX3("F1_DOC")[1]) -Len(Trim(oIdent:_nNF:TEXT)) )+oIdent:_nNF:TEXT,TamSX3("F1_DOC")[1])
	Endif

	If ValAtrib("oEmitente:_CNPJ") <> "U"
		cCgcEmit   	:= oEmitente:_CNPJ:TEXT							// CHAR(16)          '                '
		cCodFilEmit	:= oEmitente:_enderEmit:_UF:TEXT
	ElseIf ValAtrib("oEmitente:_CPF") <> "U"
		cCgcEmit   	:= oEmitente:_CPF:TEXT							// CHAR(16)          '                '
		cCodFilEmit	:= oEmitente:_enderEmit:_UF:TEXT
	Endif

	If ValAtrib("oDestino:_enderDest") <> "U"
		cCodFilDest   	:= oDestino:_enderDest:_UF:TEXT					// CHAR(16)          '                '
	Endif


	// Se a raiz do CNPJ não estiver na lista de CNPJs autorizados, o xml será ignorado
	//If !(Substr(cCgcEmit,1,8) $ GetNewPar("GF_M40ACGC","05524572"))
	//	MsgInfo("Cnpj não liberado " + cCgcEmit)
	//	Return .F.
	//Endif
	If ValAtrib("oIdent:_dhEmi") <> "U"
		// <dhEmi>2014-04-15T12:02:46-03:00
		cData 	:=	Alltrim(Substr(oIdent:_dhEmi:TEXT,1,10))
	Else
		//<dEmi>2014-04-10
		cData	:=	Alltrim(oIdent:_dEmi:TEXT)
	Endif
	cData	:= StrTran(cData,"-","")
	dData	:=	STOD(cData) //CTOD(Right(cData,2)+'/'+Substr(cData,6,2)+'/'+Left(cData,4))

	If dData < Date() - 150
		// Não faz nada -
	ElseIf !sfConfSefaz(cChave)
		cMsgRetMail	+= "Importação XML - Nota não autorizada! "
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, Padr("|Nota não autorizada '"+cChave+"'",99)+"|"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Return .F.
	Endif

	oDet       	:= oNF:_InfNfe:_Det

	oDet := IIf(ValAtrType(oDet)=="O",{oDet},oDet)



	DbSelectArea("ZD2")
	DbSetOrder(2) // ZD2_FILIAL+ZD2_CHVNFE+ZD2_ITEM

	// Inicio loop nos itens da nota
	For nX := 1 To Len(oDet)
		nPx	:= nX


		DbSelectArea("ZD2")
		DbSetOrder(2) // ZD2_FILIAL+ZD2_CHVNFE+ZD2_ITEM
		If DbSeek( xFilial("ZD2") + Padr(cChave,Len(ZD2->ZD2_CHVNFE)) + StrZero(nX,2))
			RecLock("ZD2",.F.)
		Else
			RecLock("ZD2",.T.)
		Endif
		ZD2->ZD2_FILIAL		:= xFilial("ZD2") 									// CHAR(2)
		ZD2->ZD2_ITEM    	:= StrZero(nX,2)									// CHAR(2)
		ZD2->ZD2_COD      	:= Right(oDet[nX]:_Prod:_cProd:TEXT,15)				// CHAR(15)
		ZD2->ZD2_GRUPO    	:= ""												// CHAR(4)
		ZD2->ZD2_DESCRI   	:= oDet[nX]:_Prod:_xProd:TEXT 						// CHAR(60)
		ZD2->ZD2_UM       	:= oDet[nX]:_Prod:_uCom:TEXT						// CHAR(15)
		ZD2->ZD2_QUANT    	:= Val(oDet[nX]:_Prod:_qCom:TEXT)					// NUMBER            0.0
		ZD2->ZD2_PRUNIT   	:= Val(oDet[nX]:_Prod:_vUnCom:TEXT)					// NUMBER            0.0
		ZD2->ZD2_PRCVEN   	:= Val(oDet[nX]:_Prod:_vUnCom:TEXT)					// NUMBER            0.0

		ZD2->ZD2_TOTAL    	:= Val(oDet[nX]:_Prod:_vProd:TEXT)					// NUMBER            0.0
		ZD2->ZD2_CUSTO1   	:= Val(oDet[nX]:_Prod:_vProd:TEXT)					// NUMBER            0.0
		ZD2->ZD2_CF       	:= oDet[nX]:_Prod:_CFOP:TEXT						// CHAR(5)           '     '

		If ValAtrib("oDet[nPX]:_Imposto:_IPI:_IPITRIB")<> "U"
			oIPI := oDet[nx]:_Imposto:_IPI:_IPITRIB
			ZD2->ZD2_BASIPI   	:= Iif(ValAtrib("oIPI:_vBC")<>"U",Val(oIPI:_vBC:TEXT),0)	// NUMBER            0.0
			ZD2->ZD2_IPI      	:= Iif(ValAtrib("oIPI:_pIPI")<>"U",Val(oIPI:_pIPI:TEXT),0)	// NUMBER            0.0
			ZD2->ZD2_VALIPI   	:= Iif(ValAtrib("oIPI:_vIPI")<>"U",Val(oIPI:_vIPI:TEXT),0)	// NUMBER            0.0
		Endif

		// Captura a informação do ICMS
		Do Case
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS00")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS00
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS10")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS10
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS20")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS20
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS30")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS30
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS40")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS40
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS51")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS51
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS60")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS60
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS70")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS70
		Case ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMS90")<> "U"
			oICM:=oDet[nX]:_Imposto:_ICMS:_ICMS90
		EndCase
		//	Efetua verificação pelas Tags do Simples Nacional
		If ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMSSN101") <> "U"
			oICM	:= oDet[nX]:_Imposto:_ICMS:_ICMSSN101
		ElseIf ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMSSN102") <> "U"
			oICM	:= oDet[nX]:_Imposto:_ICMS:_ICMSSN102
		ElseIf ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMSSN201") <> "U"
			oICM	:= oDet[nX]:_Imposto:_ICMS:_ICMSSN201
		ElseIf ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMSSN202") <> "U"
			oICM	:= oDet[nX]:_Imposto:_ICMS:_ICMSSN202
		ElseIf ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMSSN500") <> "U"
			oICM	:= oDet[nX]:_Imposto:_ICMS:_ICMSSN500
		ElseIf ValAtrib("oDet[nPX]:_Imposto:_ICMS:_ICMSSN900") <> "U"
			oICM	:= oDet[nX]:_Imposto:_ICMS:_ICMSSN900
		Endif

		If ValAtrib("oICM")<> "U"
			If ValAtrib("oICM:_vBC") <> "U"
				ZD2->ZD2_BASICM   	:= Val(oICM:_vBC:TEXT)						// NUMBER            0.0
			Endif
			If ValAtrib("oICM:_pICMS") <> "U" .And. Val(oICM:_pICMS:TEXT) < 100
				ZD2->ZD2_PICM     	:= Val(oICM:_pICMS:TEXT)					// NUMBER            0.0
			Endif
			If ValAtrib("oICM:_vICMS") <> "U"
				ZD2->ZD2_VALICM   	:= Val(oICM:_vICMS:TEXT)					// NUMBER            0.0
			Endif
			If ValAtrib("oICM:_vBCST") <> "U"
				ZD2->ZD2_BRICMS   	:= Val(oICM:_vBCST:TEXT)					// NUMBER            0.0
			Endif
			If ValAtrib("oICM:_pMVAST") <> "U"
				ZD2->ZD2_MARGEM   	:= Val(oICM:_pMVAST:TEXT)					// NUMBER            0.0
			Endif
			If ValAtrib("oICM:_pICMSST") <> "U"
				ZD2->ZD2_ALIQSO   	:= Val(oICM:_pICMSST:TEXT)					// NUMBER            0.0
			Endif
			If ValAtrib("oICM:_vICMSST") <> "U"
				ZD2->ZD2_ICMSRE  	:= Val(oICM:_vICMSST:TEXT)					// NUMBER            0.0
			Endif
			If ValAtrib("oICM:_orig") <> "U" .And. ValAtrib("oICM:_CST") <> "U"
				ZD2->ZD2_CLASFI   	:= Padr(Alltrim(oICM:_orig:TEXT)+Alltrim(oICM:_CST:TEXT),TamSX3("D2_CLASFIS")[1])	// CHAR(3)           '   '
			Endif

		Endif

		If ValAtrib("oDet[nPX]:_Prod:_vDesc")<> "U"
			ZD2->ZD2_DESC     	:= Val(oDet[nX]:_Prod:_vDesc:TEXT) 				// NUMBER            0.0
		Endif

		If ValAtrib("oDet[nPX]:_Prod:_vFrete") <> "U"
			ZD2->ZD2_VALFRE   	:= Val(oDet[nX]:_Prod:_vFrete:TEXT)				// NUMBER            0.0
		Endif
		If ValAtrib("oDet[nPX]:_Prod:_vOutro")<> "U"
			ZD2->ZD2_DESPES   	:= Val(oDet[nX]:_Prod:_vOutro:TEXT)				// NUMBER            0.0
		Endif
		If ValAtrib("oDet[nPX]:_Prod:_vSeg")<> "U"
			ZD2->ZD2_SEGURO   	:= Val(oDet[nX]:_Prod:_vSeg:TEXT)				// NUMBER            0.0
		Endif

		If ValAtrib("oDestino:_CNPJ") <> "U"
			ZD2->ZD2_CGCCLI   	:= oDestino:_CNPJ:TEXT							// CHAR(16)          '                '
		ElseIf ValAtrib("oDestino:_CPF") <> "U"
			ZD2->ZD2_CGCCLI   	:= oDestino:_CPF:TEXT							// CHAR(16)          '                '
		Endif

		
		// Verifica se o CNPJ existe como cadastro de cliente já atribuí um código
		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+ZD2->ZD2_CGCCLI)
			ZD2->ZD2_CLIENT   	:= SA1->A1_COD									// CHAR(6)           '      '
			ZD2->ZD2_LOJA     	:= SA1->A1_LOJA									// CHAR(2)           '  '
			ZD2->ZD2_VEND1    	:= U_MLFATG05(2,SA1->A1_COD,SA1->A1_LOJA)	//SA1->A1_VEND									// CHAR(6)           '      '
		Endif
		ZD2->ZD2_DOC      	:= Right(StrZero( 0,( TamSX3("F2_DOC")[1]) - Len(Trim(oIdent:_nNF:TEXT)) ) + oIdent:_nNF:TEXT,TamSX3("F2_DOC")[1]) // CHAR(9)           '         '
		ZD2->ZD2_SERIE    	:= Padr(oIdent:_serie:TEXT,TamSX3("F2_SERIE")[1])	// CHAR(3)           '   '

		If ValAtrib("oIdent:_dhEmi") <> "U"
			// <dhEmi>2014-04-15T12:02:46-03:00
			cData 	:=	Alltrim(Substr(oIdent:_dhEmi:TEXT,1,10))
		Else
			//<dEmi>2014-04-10
			cData	:=	Alltrim(oIdent:_dEmi:TEXT)
		Endif
		cData	:= StrTran(cData,"-","")
		dData	:=	STOD(cData) //CTOD(Right(cData,2)+'/'+Substr(cData,6,2)+'/'+Left(cData,4))

		ZD2->ZD2_EMISSA   	:= dData										// CHAR(8)           '        '
		ZD2->ZD2_EST      	:= oDestino:_enderDest:_UF:TEXT						// CHAR(2)           '  '
		ZD2->ZD2_TIPO     	:= "N"	// Até que se prove o contrário!!!			// CHAR(1)           ' '

		// Efetua a gravação dos dados referente ao PIS
		If ValAtrib("oDet[nPX]:_Imposto:_PIS:_PISAliq")<> "U" .And. Val(oDet[nX]:_Imposto:_PIS:_PISAliq:_pPIS:TEXT) < 100
			oPIS := oDet[nX]:_Imposto:_PIS:_PISAliq
			ZD2->ZD2_BSIMP5   	:= Val(oPIS:_vBC:TEXT)							// NUMBER            0.0
			ZD2->ZD2_ALIMP5		:= Val(oPIS:_pPIS:TEXT)							// NUMBER            0.0
			ZD2->ZD2_VLIMP5		:= Val(oPIS:_vPIS:TEXT)							// NUMBER            0.0
		ElseIf ValAtrib("oDet[nPX]:_Imposto:_PIS:_PISOutr")<> "U" .And. ValAtrib("oDet[nX]:_Imposto:_PIS:_PISOutr:_pPIS") <> "U" .And. Val(oDet[nX]:_Imposto:_PIS:_PISOutr:_pPIS:TEXT) < 100
			oPIS:=oDet[nX]:_Imposto:_PIS:_PISOutr
			ZD2->ZD2_BSIMP5   	:= Val(oPIS:_vBC:TEXT)							// NUMBER            0.0
			ZD2->ZD2_ALIMP5		:= Val(oPIS:_pPIS:TEXT)							// NUMBER            0.0
			ZD2->ZD2_VLIMP5		:= Val(oPIS:_vPIS:TEXT)							// NUMBER            0.0
		Endif

		If ValAtrib("oDet[nPX]:_Imposto:_COFINS:_COFINSAliq")<> "U" .And. Val(oDet[nX]:_Imposto:_COFINS:_COFINSAliq:_pCOFINS:TEXT) < 100
			oCOF := oDet[nX]:_Imposto:_COFINS:_COFINSAliq
			ZD2->ZD2_BSIMP6		:= Val(oCOF:_vBC:TEXT)							// NUMBER            0.0
			ZD2->ZD2_ALIMP6 	:= Val(oCOF:_pCOFINS:TEXT)						// NUMBER            0.0
			ZD2->ZD2_VLIMP6		:= Val(oCOF:_vCOFINS:TEXT)						// NUMBER            0.0
		ElseIf ValAtrib("oDet[nX]:_Imposto:_COFINS:_COFINSOutr")<> "U" .And. ValAtrib("oDet[nX]:_Imposto:_COFINS:_COFINSOutr:_pCOFINS") <> "U" .And. Val(oDet[nX]:_Imposto:_COFINS:_COFINSOutr:_pCOFINS:TEXT) < 100
			oCOF := oDet[nX]:_Imposto:_COFINS:_COFINSOutr
			ZD2->ZD2_BSIMP6		:= Val(oCOF:_vBC:TEXT)							// NUMBER            0.0
			ZD2->ZD2_ALIMP6 	:= Val(oCOF:_pCOFINS:TEXT)						// NUMBER            0.0
			ZD2->ZD2_VLIMP6		:= Val(oCOF:_vCOFINS:TEXT)						// NUMBER            0.0
		Endif

		If ValAtrib("oDet[nPX]:_Prod:_nFCI") <> "U"
			ZD2->ZD2_FCICOD   	:= oDet[nX]:_Prod:_nFCI:TEXT					// CHAR(36)          '                                    '
		Endif
		ZD2->ZD2_CHVNFE   	:= cChave											// CHAR(44)          '                                            '
		ZD2->ZD2_CGCEMI 	:= cCgcEmit											// CHAR(16)
		ZD2->ZD2_XFIL		:= IIf(cCodFilDest == "SC","01",IIf(cCodFilDest=="PR","04",Iif(cCodFilDest=="RS","05",IIf(cCodFilDest=="07","SP",IIf(cCodFilDest=="08","MG",IIf(cCodFilDest=="09","RJ",cCodFilDest))))))
		ZD2->(MsUnlock())
	Next

	If ValAtrib("oCobr:_dup") <> "U"
		// Neste trecho carrego um array contendo os vencimentos e valores das parcelas contidos no XML e permito levar para o Documento de entrada
		nSumSE2		:= 0
		oDup  		:= oCobr:_dup
		oDup 		:= IIf(ValAtrType(oDup)=="O",{oDup},oDup)
		lOnlyDup	:= Len(oDup) == 1

		For nForC := 1 To Len(oDup)
			nP := nForC

			If ValAtrib("oDup[nP]:_vDup") <> "U" .And. ValAtrib("oDup[nP]:_dVenc") <> "U"
				dVencPXml	:= STOD(StrTran(Alltrim(oDup[nP]:_dVenc:TEXT),"-",""))

				If lOnlyDup
					cParcela := " "
				Else
					cParcela := IF(nP>1,MaParcela(cParcela),IIF(Empty(cParcela),"A",cParcela))
				Endif
				// Verificou que a chave j[a existe na base
				DbSelectARea("ZD3")
				DbSetOrder(1)
				If DbSeek(xFilial("ZD3")+cChave+cParcela)

				Else
					RecLock("ZD3",.T.)
					ZD3->ZD3_FILIAL	:= xFilial("ZD3")
					ZD3->ZD3_CHVNFE	:= cChave
					ZD3->ZD3_NUMNF	:= ZD2->ZD2_DOC
					ZD3->ZD3_CLIENT	:= ZD2->ZD2_CLIENT
					ZD3->ZD3_LOJA	:= ZD2->ZD2_LOJA
					ZD3->ZD3_PARCEL	:= cParcela
					ZD3->ZD3_VENCTO	:= STOD(StrTran(Alltrim(oDup[nP]:_dVenc:TEXT),"-",""))
					ZD3->ZD3_VALOR	:= Val(oDup[nP]:_vDup:TEXT)
					ZD3->ZD3_SALDO	:= Val(oDup[nP]:_vDup:TEXT)
					MsUnlock()
				Endif
			Endif
		Next nForC
	Endif


Return .T.




/*/{Protheus.doc} sfRemoveCrlf
(long_description)
@author MarceloLauschner
@since 04/03/2014
@version 1.0
@param cInXml, character, XML a ser reconstruido
@return character , Xml refeito sem as quebras de linha
@example
(examples)

@see (links_or_references)
/*/
Static Function sfRemoveCrlf(cInXml,lVldSchema)

	Local		cRet		:= ""
	Local		aXml		:= {}
	Local		ix
	Local		nCnt77		:= 0
	Local		nCnt75 		:= 0
	Local		nCnt74		:= 0
	Local		cVArAux		:= ""
	Local		nTamXml		:= 0
	Local		cError		:= ""
	Local		cWarning	:= ""
	Local		cStrAux		:= ""
	Local 		nPosDATA
	Local 		nPosIni
	Local 		nPosFin
	Local		cTxtAux		:= ''
	Default		lVldSchema	:= .F.

	// 22/08/2017 - Corrige informação errada vindo de XMLs
	//<infAdProd><[CDATA[<OC: 71096/>]]></infAdProd>
	//<infAdProd><[CDATA[<OC: 116131/>< FCI:3DE1CE21-9F05-4C25-8D46-9E5C093792FA/>]]></infAdProd>
	//cRet 	:= StrTran(cRet,"<[CDATA[<","")
	//cRet 	:= StrTran(cRet,"/>]]>","")
	//cRet 	:= StrTran(cRet,"/>]]>","")

	If "CDATA[" $ cInXml .And. lVldSchema
		//cInXml := XmlC14N( cInXml, "", @cError , @cWarning  )
		nPosDATA := At('<![CDATA[',cInXml)

		If (nPosDATA <> 0)
			//MsgAlert(cValToChar(nPosDATA))
			nPosIni := At('<![CDATA[',cInXml) //At('<',SubStr(cInXml,nPosDATA+1))+1
			cStrAux := SubStr(cInXml,nPosIni)
			nPosFin := Rat("]]>",cStrAux)
			//MsgAlert(cValToChar(nPosIni) + " " + cValToChar(nPosFin))
			cStrAux := SubStr(cInXml,nPosIni,nPosFin + Len("]]>")-1)
			//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cStrAux,{"Ok"},3)

			cStrAux := Alltrim(stripTags(cStrAux,.F.))

			//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cStrAux,{"Ok"},3)

			cInXml 	:= Stuff(cInXml,nPosIni,nPosFin+ Len("]]>")-1,cStrAux)

			//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cInXml,{"Ok"},3)
		EndIf

		/*cInXml 	:= StrTran(cInXml,"<[CDATA[<","")
		cInXml 	:= StrTran(cInXml,"/>]]>","")
		cInXml 	:= StrTran(cInXml,"<![CDATA[","")
		cInXml 	:= StrTran(cInXml,"]]>","")*/
	Endif

	aXml	:=	StrTokArr(cInXml,Chr(13))

	// Verifico primeiro para ver se o texto está formato com quebras de linhas forçadas
	For iX := 1 To Len(aXml)
		If Len(aXml[iX]) == 77
			nCnt77++
		Endif
		If Len(aXml[iX]) == 75
			nCnt75++
		Endif
		If Len(aXml[iX]) == 74
			nCnt74++
		Endif
	Next

	For iX := 1 To Len(aXml)
		If lVldSchema
			cRet += Alltrim(StrTran(aXml[iX],Chr(10),''))
		Else
			cRet += StrTran(aXml[iX],Chr(10),'')
		Endif
		// Se a quebra de linha for com menos de 77 colunas, adiciona um espaço no texto
		If (Len(aXml[iX]) < 77 .And. Len(StrTran(aXml[iX],Chr(10),'')) > 0 ) .And. nCnt77 > 15
			cRet += ' '
			// Se a quebra de linhas for com menos de 75 de colunas adiciona um espaço no texto
		ElseIf (Len(aXml[iX]) < 75) .And. Len(StrTran(aXml[iX],Chr(10),'')) > 0  .And. nCnt75 > 15 .And. nCnt77 == 0
			cRet += ' '
		ElseIf (Len(aXml[iX]) < 74) .And. Len(StrTran(aXml[iX],Chr(10),'')) > 0  .And. nCnt74 > 15 .And. nCnt77 == 0 .And. nCnt75 == 0
			cRet += ' '
		Endif

	Next

	// 19/03/2017 - Se não houve o ajuste forçado por quebra de linha com 77 caracteres, verifica se há outras quebras de linha
	If nCnt77 == 0 .And. nCnt75 == 0 .And. nCnt74 == 0
		cRet	:= ""
		aXml	:=	StrTokArr(cInXml,Chr(13))

		For iX := 1 To Len(aXml)
			cVarAux	:= aXml[iX] //!
			cVarAux := StrTran(cVarAux,"!",'') // Substitui sinal exclamação inserido no arquivo
			cVarAux := StrTran(cVarAux,Chr(13)+" ",'')		// Remove CRLF e espaço
			cVarAux := StrTran(cVarAux,Chr(10)+" ",'')		// Remove CRLF e espaço

			If Substr(cVArAux,1,1) == " "					// Se a linha tiver um espaço no começo, remove pois resultou de uma formatação errada.
				cRet += Substr(cVarAux,2)
			Else
				cRet += cVarAux
			Endif
		Next
	Endif


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

	// 21/02/2019 - Remove duplicidade de Enconding
	If At('<?xml version="1.0" encoding="UTF-8"?>',cRet) > 0 .And. At('<?xml version="1.0" encoding="utf-8" ?>',cRet) > 0
		cRet	:= StrTran(cRet,'<?xml version="1.0" encoding="UTF-8"?>','')
	Endif


	// 29/11/2018 - Corrigi tags que iniciam com espaço
	//<xObs>_        _  ICMS ISENTO CONFORME ITEM 144   O valor aproximado de tributos incidentes sobre o preco deste servico e de R$ 49.24</xObs>
	nPosIni := At('<xObs>',cRet)
	If nPosIni > 0
		nPosIni += Len('<xObs>')
		cStrAux := SubStr(cRet,nPosIni)
		nPosFin := Rat("</xObs>",cStrAux)
		cStrAux := SubStr(cRet,nPosIni,nPosFin + Len("</xObs>")-1)
		cStrAux := Alltrim(StrTran(cStrAux,"_",""))
		cRet 	:= Stuff(cRet,nPosIni,nPosFin + Len("</xObs>")-1,cStrAux)
	Endif

	cRet	:= StrTran(cRet, Chr(13)+ Chr(10),"")
	cRet	:= StrTran(cRet, Chr(10),"")

	cRet	:= StrTran(cRet, "_","-")
	cRet 	:= StrTran(cRet,"ï»¿","")


Return cRet


/*/{Protheus.doc} NoAcento
(Remove vogais acentuadas Função copiada do NfeSefaz )
@author MarceloLauschner
@since 01/12/2011
@version 1.0
@param cString, character, (Descrição do parâmetro)
@param lVldSch, ${param_type}, (Descrição do parâmetro)
@return cBuffer, Texto formatado
@example
(examples)
@see (links_or_references)
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
	Local		cOutros		:= "ºª"
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
			nY:= At(cChar,cOutros)
			If nY > 0
				cBuffer := StrTran(cBuffer,cChar," ")
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
		Case ValAtrType(xString)=="C"

			cBuffer := Strtran(cBuffer, "&amp;","&" )
			cBuffer := Strtran(cBuffer, "&quot;",'"')
			cBuffer := Strtran(cBuffer, "&lt;","<")
			cBuffer := Strtran(cBuffer, "&gt;",">")

			//A maiúsculo com acento agudo	Á	&Aacute;
			//E maiúsculo com acento agudo	É	&Eacute;
			//I maiúsculo com acento agudo	Í	&Iacute;
			//O maiúsculo com acento agudo	Ó	&Oacute;
			//U maiúsculo com acento agudo	Ú	&Uacute;
			//A minúsculo com acento agudo	á	&aacute;
			//E minúsculo com acento agudo	é	&eacute;
			//I minúsculo com acento agudo	í	&iacute;
			//O minúsculo com acento agudo	ó	&oacute;
			//U minúsculo com acento agudo	ú	&uacute;
			//A maiúsculo com acento circunflexo	Â	&Acirc;
			//E maiúsculo com acento circunflexo	Ê	&Ecirc;
			//O maiúsculo com acento circunflexo	Ô	&Ocirc;
			//A minúsculo com acento circunflexo	â	&acirc;
			//E minúsculo com acento circunflexo	ê	&ecirc;
			//O minúsculo com acento circunflexo	ô	&ocirc;
			//A maiúsculo com crase	À	&Agrave;
			//A minúsculo com crase	à	&agrave;
			//U maiúsculo com trema	Ü	&Uuml;
			//U minúsculo com trema	ü	&uuml;
			//C cedilha maiúsculo	Ç	&Ccedil;
			//C cedilha minúsculo	ç	&ccedil;
			//A com til maiúsculo	Ã	&Atilde;
			//O com til maiúsculo	Õ	&Otilde;
			//A com til minúsculo	ã	&atilde;
			//O com til minúsculo	õ	&otilde;
			//N com til maiúsculo	Ñ	&Ntilde;
			//N com til minúsculo	ñ	&ntilde;
			//E comercial	&	&amp;
			//Aspa dupla	"	&quot;
			//Aspa simples	'	&#039;
			//Menor que	<	&lt;
			//Maior que	>	&gt;

		Case ValAtrType(xString)=="N"
			cBuffer := Str(xString)
	EndCase


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
@see (links_or_references)
/*/
Static Function sfDecodeUtf(xString,lInverte)

	Local	cBuffer		:= ""  //Ã‰ Ã€ Ãü Ãë Ãç
	Local	aAcento		:= {"á" , "à", "â", "ã", "ä", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ó", "ò", "ô", "õ", "ö", "ú", "ù", "û", "ü", "ç","Á", "À", "Â", "Ã", "Ä", "É", "È", "Ê", "Ë" , "Í" ,"Í"			, "Ì" , "Î","Ï" ,"Ó", "Ò" , "Ô", "Õ", "Ö","Ú" ,"Ù" ,"Û", "Ü" ,"Ç"          , "Ç" ,"Á" ,"É" ,"Ç"	 ,"Á"				,"Ã"  ,"Õ" ,"Á"  ," "	}
	Local	aUtf8 		:= {"Ã¡","Ã ","Ã¢","Ã£","Ã¤","Ã©","Ã¨","Ãª","Ã«","Ã­","Ã¬","Ã®","Ã¯","Ã³","Ã²","Ã´","Ãµ","Ã¶","Ãº","Ã¹","Ã»","Ã¼","Ã§","Ã?","Ã€","Ã‚","Ãƒ","Ã„","Ã‰","Ãˆ","ÃŠ","Ã‹","Ã?" ,"Ã"+chr(141), "ÃŒ","ÃŽ","Ã?","Ã“","Ã’","Ã”","Ã•","Ã–","Ãš","Ã™","Ã›","Ãœ","Ç"+Chr(135) , "Ã‡","Ãü","Ãë","Ãç" ,"Ã"+chr(129)+"S"  ,"Ãâ", "Ãò","Ãü",""	}
	Local	iC,iU
	Local	lExistUtf8	:= .F.
	Default	lInverte	:= .F.

	Aadd(aAcento,"É" )
	Aadd(aUtf8  ,"Ã‰")

	Aadd(aAcento,"º")
	Aadd(aUtf8	,"Âº")

	Aadd(aAcento,"Á")
	Aadd(aUtf8  ,"Ã" + Chr(129))

	Aadd(aAcento,"É")
	Aadd(aUtf8  ,"Â"+Chr(144))

	Aadd(aAcento,"Á")
	Aadd(aUtf8, Chr(65) + Chr(186) )


	Do Case
		Case ValAtrType(xString) == "C"
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
		Case ValAtrType(xString) == "N"
			cBuffer	:= Str(xString)
	EndCase

Return cBuffer



/*/{Protheus.doc} sfConfSefaz
(Efetua consulta da NFe via Webservice para garantir que a chave eletrônica esteja autorizada)
@type function
@author marce
@since 09/10/2016
@version 1.0
@param cInChave, character, (Descrição do parâmetro)
@return lRet, ${return_description}
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

		// Trecho para validar autorização da NF
		cMensagem:= ""
		oWs:= WsNFeSBra():New()
		oWs:cUserToken   := "TOTVS"
		oWs:cID_ENT    	 := cIdentSPED
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
				lRet	:= .F.
				//	Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+STR0107,cMensagem+Chr(13)+Chr(10)+"Nota fiscal do Fornecedor/Cliente",{"Ok"},3)
			Endif
			//	Aviso(STR0107,cMensagem,{STR0114},3)
		Else
			lRet	:= .F.
			//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{STR0114},3)
		EndIf
	Else
		lRet 	:= .F.
		//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{STR0114},3)
	Endif

Return lRet

Static Function ValAtrib(atributo)
Return (Type(atributo) )

Static Function ValAtrType(atributo)
Return (ValType(atributo) )
