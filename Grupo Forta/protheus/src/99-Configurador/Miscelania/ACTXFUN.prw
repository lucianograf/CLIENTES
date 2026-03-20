#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBEX.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#include "fileio.ch"
Static _oSEmAXACT := nil
/*/{Protheus.doc} xMPad

Apresenta no Appserver as mensagens

@author TSC679 - CHARLES REITZ
@since 13/11/2013
@version 1.0

@return cMsg, Mensagem formatada

/*/

User FUnction xMPad(_cMFunc,_cTipM,_cMsg1,_cMsg2,_cAgrupLog)
	//Local aMsg			:=	{	"[START]",;//tipo 1
	//							"[INFO ]",;	//tipo 2
	//							"[ERROR]",;	//tipo 3
	//							"[ENDED]";//tipo 4
	//						}
	Local 	cMsg		:=	""
	Local cTime			:=	TIME()
	Local cTimeEnd		:=	""
	Local nTotPos		:=	0
	Local aOldArray		:=	{}
	Local lConsoleLog	:=	.T.
	Default _cTipM		:=	"START"
	Default _cMFunc		:=	""
	Default _cMsg1		:=	""
	Default _cMsg2		:=	""
	Default _cAgrupLog	:=	""
	Static START 		:=	1
	Static INFO 		:=	2
	Static ERROR 		:=	3
	Static ENDED 		:=	4

	//Verifica se ira apresentar as mensagens no console de transacoes de funcoes
	lConsoleLog	:=	If(GetPvProfString("general","TraceLogZ","",GetADV97())=="2",.F.,.T.)
	lSavTrLog	:=	If(GetPvProfString("general","TraceSaveLogZ","",GetADV97())=="2",.F.,.T.)

	//Controle do tempo de execucao
	If Type("aACTimePerf")=="U"
		//COntrole o tempo de execucao de uma determinada funcao
		Public aACTimePerf	:= 	{}
	EndIf

	//Inicia contagem com o START
	If _cTipM	== "START"
		/*
		[1]Tempo Inicial
		[2]Tempo Final
		[3]Tempo Percorrido
		*/
		aAdd(aACTimePerf,{Time(),,})
	EndIf

	//Finaliza com END a contagem
	If _cTipM	== "ENDED"	.AND. Len(aACTimePerf) <> 0
		nTotPos	:=	Len(aACTimePerf)
		aACTimePerf[nTotPos][2]	:=	cTime
		aACTimePerf[nTotPos][3]	:=	elaptime(aACTimePerf[nTotPos][1],aACTimePerf[nTotPos][2])
		cTimeEnd	:= " Ini:"+aACTimePerf[nTotPos][1]+"|Fim:"+aACTimePerf[nTotPos][2]+"|Elaptime:"+aACTimePerf[nTotPos][3]
		aOldArray	:= aClone(aACTimePerf)
		aACTimePerf	:=	{}
		aScan(aOldArray,{|x|If(len(aACTimePerf)+1<nTotPos, aadd(aACTimePerf,{x[1],x[2],x[3]}),)   })
	EndIf

	//msg start ended info erro
	cMsg	+=	"["+_cTipM+"]"//aMsg[&(_cTipM)]
	//thread
	cMsg	+=	"[Thread "+cvaltochar(ThreadID())+"]"
	//Monta a Data na Linha
	cMsg	+=	"["+DTOC(DATE())+" "+cTime+"]"
	//Funcao que esta sendo rodada
	cMsg	+=	"["+_cMFunc+"] "
	//Mensagem 1
	cMsg	+=	_cMsg1+If(Empty(_cMsg2),"","-")
	//Mensagem 2
	cMsg	+=	_cMsg2
	//COntagem
	cMsg	+=	If(_cTipM=="ENDED",cTimeEnd,"")
	//Apresenta a mensagem no console

	//define se mostra no console.log
	If lConsoleLog
		conout(cMsg)
	EndIF

	//Save em um log separado
	If lSavTrLog
		cPath	:= "\log"
		cPath2	:= "\xmpad"
		cFile	:= _cAgrupLog+"_"+dtos(date())+".log"
		cFilePath	:=	cPath+cPath2+"\"+cFile
		If !ExistDir(cPath)
			MakeDir(cPath)
		EndIf
		If !ExistDir(cPath+cPath2)
			MakeDir(cPath+cPath2)
		EndIf
		nHandle := FOPEN(cFilePath, FO_WRITE)
		If nHandle <> -1//escreve no arquivo
			fSeek(nHandle,0,FS_END)
			FWrite(nHandle,cMsg+chr(13)+chr(10))
		Else//criar o arquivo caso nao achar
			nHandle := FCREATE(cFilePath)
			if nHandle <> -1
				FWrite(nHandle,cMsg+chr(13)+chr(10))
			EndIf
		EndIf
		FClose(nHandle)

	EndIf

Return cMsg

/*/{Protheus.doc} msgAtoC

Altera array de mensagem para uma string

@author TSC679 - CHARLES REITZ
@since 19/03/2014
@version 1.0
/*/
User Function msgAtoC(aMsgArray)
	Local cMsg			:=	""
	Local cRlf			:=	Chr(13)+Chr(10)
	Local nTotFor		:=	Len(aMsgArray)
	Local nX

	For nX := 1 To nTotFor
		If ValType(aMsgArray[nX]) == "C"
		cMsg += aMsgArray[nX] + cRlf
		EndIF
	Next nX

Return cMsg

/*/{Protheus.doc} PrePoEnv

Prepara ambiente com a ampresa para o JOB poder
ter acesso as tabelas do sistema

@author TSC679 - CHARLES REITZ
@since 19/03/2014
@version 1.0
/*/
User Function PrePoEnv()

	If Select("SM0") == 0
		U_xMPad("U_PrePoEnv","START")

		cEmpFil	:=	GetPvProfString(getWebJob(),"PrepareIn","",GetADV97()) //Formato 01,01

		U_xMPad("U_PrePoEnv","INFO","Prep. Emp.: "+cEmpFil+" Vend.:"+HttpSession->USR_VEN[2][2]+" "+HttpSession->USR_VEN[2][3])
		RpcSetType(3)
		//PREPARE ENVIRONMENT EMPRESA substr(cEmpFil,1,2) FILIAL substr(cEmpFil,4,4)
		RpcSetEnv(substr(cEmpFil,1,2),substr(cEmpFil,4,4),,,,,{"SC5", "SA1", "SA3", "SED", "SC6", "SFM", "SF4"})
		SetLoopLock(.F.)///// Seta que RecLock, em caso de falha, nao vai fazer retry automatico
		SetAbendLock(.F.)
					
		U_xMPad("U_PrePoEnv","ENDED")
	EndIF
	cPaisLoc := "BRA"
	lRet	:=	.T.

Return lRet

//#########################################
//
//Funcoes Utilizadas para Evio de Email
//
//#########################################
/*/{Protheus.doc} ConSmtp

Faz a conexão do servidor

Para funcionar deverá chamar na sequencia as funcoes
U_MailSmtp() -> Para conectar
U_MailSend() -> Para enviar o email, passandos os paremtros
U_MailOFF()  -> Para desconectar do servidor.

@author TSC679 - CHARLES REITZ
@since 21/08/2014
@version 1.0
@return nil, nulo
/*/
User Function MailSmtp()
	Local lRet					:=	.F.
	Local nI      				:= 	0
	Local cMailConta			:= Alltrim(GetMv("MV_RELACNT"))
	Local cMailSenha			:= Alltrim(GetMv("MV_RELPSW"))
	Local lMailAuth				:= GetMv("MV_RELAUTH")
	Local cUsrAuth				:=Alltrim(GetMv("MV_RELACNT"))// Alltrim(GetMv("MV_RELAUSR"))
	//Local cPassAuth				:=	Alltrim(GetMv("MV_RELPSW"))
	Local cMailServer			:= SubStr(Alltrim(GetMv("MV_RELSERV")),1,At(":",Alltrim(GetMv("MV_RELSERV")))-1)
	Local nSendPort				:=	val(SubStr(Alltrim(GetMv("MV_RELSERV")),At(":",Alltrim(GetMv("MV_RELSERV")))+1,Len(Alltrim(GetMv("MV_RELSERV")))))
	//Local cMailServer			:= Alltrim(GetMv("MV_RELSERV"))
	Local lUseSSL				:= GetMv("MV_RELSSL")
	Local lUseTLS				:= GetMv("MV_RELTLS")
	Local nTimeout				:=	GetMv("MV_RELTIME")
	Local xRet					:=	""
	Local cMsg					:=	""
	Local lRet := .F.


	If nSendPort  == 0
		nSendPort	:=	587
	EndIf

	//default port for SMTPS protocol with TLS
	Begin Sequence
		//Cria a conex„o com o server STMP ( Envio de e-mail )
		_oSEmAXACT := TMailManager():New()
		_oSEmAXACT:SetUseSSL(lUseSSL)
		_oSEmAXACT:SetUseTLS(lUseTLS)

		//xRet := _oSEmAXACT:Init( "", cMailServer, cMailConta, cMailSenha, 0, nSendPort )
		xRet := _oSEmAXACT:Init( "", cMailServer, cMailConta, cMailSenha, 0,nSendPort)
		If xRet != 0
			cMsg := "Could not initialize SMTP server: " + _oSEmAXACT:GetErrorString( xRet )
			GeraLogTxt(cMsg)
			MsgAlert(cMsg)
			conout( cMsg )
			Break
		EndIf

		//seta um tempo de time out com servidor de 1min
		xRet := _oSEmAXACT:SetSMTPTimeout( nTimeout )
		if xRet != 0
			cMsg := "Could not set " + cProtocol + " timeout to " + cValToChar( nTimeout )
			GeraLogTxt(cMsg)
			MsgAlert(cMsg)
			conout( cMsg )
			Break
		endif

		// estabilish the connection with the SMTP server
		xRet := _oSEmAXACT:SMTPConnect()
		if xRet <> 0
			cMsg := "Could not connect on SMTP server: " + _oSEmAXACT:GetErrorString( xRet )
			GeraLogTxt(cMsg)
			MsgAlert(cMsg)
			conout( cMsg )
			Break
		endif

		// authenticate on the SMTP server (if needed)
		xRet := _oSEmAXACT:SmtpAuth( cUsrAuth, cMailSenha )
		if xRet <> 0
			cMsg := "Could not authenticate on SMTP server: " + _oSEmAXACT:GetErrorString( xRet )
			GeraLogTxt(cMsg)
			MsgAlert(cMsg)
			conout( cMsg )
			_oSEmAXACT:SMTPDisconnect()
			Break
		endif

		lRet := .T.
	End Sequence
Return lRet

/*/{Protheus.doc} ConSmtp

Envia email

@author TSC679 - CHARLES REITZ
@since 21/08/2014
@version 1.0
@return nil, nulo
/*/
User Function MailSend(cFrom,cTo,cCC,cBcc,cSubject,cBody,aAnexoMail,cReplyTo,cMailTest)
	Local cErro			:=	""
	Local oMessage		:=	""
	Local nX			:=	""
	Local lTeste	:=	!(If(Upper(GetEnvServer())$Upper(Alltrim(SuperGetMv("FF_ENVPROD",.T.,"ENVIRONMENT/PORTAL"))),.T.,.F.))
	Local lErroUnico:=	Type("_cMUncMErr") == "C"
	Private lRet		:=	.F.
	Default aAnexoMail	:=	{}
	Default cFrom		:=	GetMV("MV_RELFROM",.F.,"")
	Default cTo			:=	""
	Default cCC			:=	""
	Default cBcc		:=	""
	Default cSubject	:=	""
	Default cBody		:=	""
	Default cReplyTo	:=	""
	Default cMailTest 	:=  ""

	Begin Sequence
		//Para testes
		If lTeste
			cTo	:=	cFrom+";"+cMailTest
			cCC :=  cFrom+";"+cMailTest
			cSubject	:=	"[TESTE] "+cSubject
			cMsg	:=	"Identificamos que voce esta em um ambiente de teste, sera enviado email de teste. De:"+cFrom+"Para:"+cTo

			If lErroUnico
				_cMUncMErr	:= cMsg+chr(13)+chr(10)
			Else
				MsgInfo(cMsg,"[ACTXFUN]")
			EndIf
			GeraLogTxt(cMsg)
		EndIf

		If Empty(cFrom)
			cMsg	:= "Remetente não informado"
			If lErroUnico
				_cMUncMErr	:= cMsg+chr(13)+chr(10)
			Else
				MsgInfo(cMsg,"[ACTXFUN]")
			EndIf
			GeraLogTxt(cMsg)
			Break
		EndIf

		oMessage := TMailMessage():New()

		//Limpa o objeto
		oMessage:Clear()

		//Popula com os dados de envio
		oMessage:cFrom              := cFrom
		oMessage:cTo                := cTo
		oMessage:cCc                := cCC
		oMessage:cBcc               := cBcc
		oMessage:cSubject           := cSubject
		oMessage:cBody              :=	cBody
		oMessage:cReplyTo 			:= cReplyTo
		For nX := 1 To Len(aAnexoMail)
			oMessage:AttachFile(aAnexoMail[nX] )
		Next
		oMessage:MsgBodyType( "text/html" )

		//Envia o e-mail
		xRet := oMessage:Send( _oSEmAXACT )
		if xRet <> 0
			cMsg := "De:"+alltrim(oMessage:cFrom)+CRLF+"Para:"+ alltrim(oMessage:cTo) +CRLF+"CC:"+alltrim(oMessage:cCc)+CRLF+"CCo:"+alltrim(oMessage:cBcc)+CRLF+"Assunto:"+alltrim(oMessage:cSubject)+CRLF+"Não é possível enviar mensagem: " + _oSEmAXACT:GetErrorString( xRet )
			GeraLogTxt(cMsg)
			If lErroUnico
				_cMUncMErr	:= cMsg+chr(13)+chr(10)
			Else
				MsgInfo(cMsg,"[ACTXFUN]")
			EndIf
			conout(cMsg)
			Break
		endif

		cMsg := "De:"+alltrim(oMessage:cFrom)+CRLF+"Para:"+ alltrim(oMessage:cTo) +CRLF+"CC:"+alltrim(oMessage:cCc)+CRLF+"CCo:"+alltrim(oMessage:cBcc)+CRLF+"Assunto:"+alltrim(oMessage:cSubject)+CRLF+ _oSEmAXACT:GetErrorString( xRet )
		GeraLogTxt(cMsg)

		lRet:=.T.
	End Sequence

Return lRet

/*/{Protheus.doc} ConSmtp

Desconecta conta

@author TSC679 - CHARLES REITZ
@since 21/08/2014
@version 1.0
@return nil, nulo
/*/
User Function MailOff()
	Local lRet	:=	.F.
	Local cMsg	:=	""

	xRet := _oSEmAXACT:SMTPDisconnect()
	if xRet <> 0
		cMsg := "Não È possÌvel disconectar do servidor: " + _oSEmAXACT:GetErrorString( xRet )
		GeraLogTxt(cMsg)
		MsgAlert(cMsg)
		conout( cMsg )
	endif
	_oSEmAXACT	:=	nil
Return nil

/*/{Protheus.doc} Ger_aLogAcMailTxt

Grava Log de transacao

@author TSC679 CHARLES REITZ
@since 24/04/2014
@version 1.0

@return cMes, Valor do mes em string
/*/
Static Function GeraLogTxt(_cLogAcMail)
	Local cDate			:=	dtoS(date())
	Local cLocal 		:= "\log\MAIL\"+cDate+".log"
	Local nHandle 		:= 0

	If !ExistDir('\log\')
		MakeDir('\log\')
	EndIF
	If !ExistDir('\log\MAIL')
		MakeDir('\log\MAIL\')
	EndIF

	If File(cLocal)
		nHandle := FOPEN(cLocal, FO_READWRITE)
		If nHandle == -1
			conout("Erro ao criar gravar - ferror " + Str(Ferror())+cLocal)
		Else //se existir arqruivo adicionar abaixo
			Escreve(nHandle,_cLogAcMail)
		Endif
	Else
		nHandle := fCreate(cLocal,FO_READWRITE)
		If nHandle = -1
			conout("Erro ao criar arquivo - ferror " + Str(Ferror())+" "+cLocal)
		Else   // escreve a hora atual do servidor em string no arquivo
			Escreve(nHandle,_cLogAcMail)
		EndIf
	EndIf
Return

/*/{Protheus.doc} Escreve

Escreve no arquivo

@author TSC679 CHARLES REITZ
@since 24/04/2014
@version 1.0
/*/
Static Function Escreve(nHandle,_cLogAcMail)
	Local cData 		:= dtos(date())+"_"+strtran(time(),':','',1)
	Local cCodUsuario	:= __CUSERID //RETCODUSR()
	Local cNomUsuario	:= CUSERNAME //UsrRetName(cCodUsuario)
	Local _ni   := 1
	Local cMsg	:=	""

	cMsg	+=	CRLF+replicate("-",150)+CRLF+"["+cData+"] Usuario: "+cCodUsuario+"/"+cNomusuario+CRLF+replicate("-",150)
	//FOR _ni := 1 to Len(_aLogAcMail)
	cMsg	+=	CRLF+_cLogAcMail
	//NEXT _ni
	fSeek(nHandle,0,2)
	FWrite(nHandle,cMsg)
	FClose(nHandle)
Return nil

/*/{Protheus.doc} A050PEnv

Função utilizada pela GRID para subir o ambiente da empresa

@type function
@author TSC679 - CHARLES REITZ
@since 04/05/2016
@version 1.0
/*/
User Function GRAbrEnv(aParms)
	Local aTime			:= {}
	Local cEmpParm  	:= Alltrim(aParms[1])	// Empresa conectada 	--> cEmpAnt
	Local cFilParm  	:= Alltrim(aParms[2])	// Filial conectada 	--> cFilAnt
	Local dDataParm 	:= aParms[3]	// Data Base			--> dDataBase
	//Local cUserA 		:= 	// Data Base			--> dDataBase
	Local cTimeIni		:= Time()
	Local nTimeIni		:= Seconds()
	Local cTimeFim		:= ""
	Local nTimeFim		:= 0
	Local nQtdTime		:= 0
	Local cMsgErro      := ""
	Local cLogServer	:=	""

	RpcSetType(3)
	RpcSetEnv(cEmpParm,cFilParm)
	RstMvBuff()
	U_A050OpTb()
	dDataBase		:=	dDataParm
	cTimeFim		:= Time()
	nTimeFim		:= Seconds()

	cLogServer += "============================================================================"+ chr(13)+chr(10)
	cLogServer += SM0->M0_CODIGO +"/"+SM0->M0_CODFIL+" - DataBase:"+dtoc(dDataBase)+ chr(13)+chr(10)
	cLogServer += "Tempo Final: " + cTimeFim + chr(13)+chr(10)
	cLogServer += "Tempo Execucao: " + SecsToTime(nTimeFim - nTimeIni) + chr(13)+chr(10)
	cLogServer += "============================================================================"+ chr(13)+chr(10)
	Conout( cLogServer )

Return .T.

/*/{Protheus.doc} A050AmbR

Funcao utilizada pela grid para resetar o ambiente da emprsea

@type function
@author TSC679 - CHARLES REITZ
@since 04/05/2016
@version 1.0
/*/
User Function GRAbrRet()
	CONOUT("============================================================================")
	conout("*Fechando Ambiente Empresa:"+SM0->M0_CODIGO+" Filial"+SM0->M0_CODFIL)
	RpcClearEnv()
	CONOUT("============================================================================")
Return  .T.

/*/{Protheus.doc} TempRest

Faz o calculo de tempo restante para um processo

@author TSC679 - CHARLES REITZ
@since 12/07/2016
@param nTotaisP, numeric, descricao
@param nIncrement, numeric, descricao
@param nTimeIni, numeric, usar a funcao seconds()
@return return, return_description
/*/
User Function TempRest(nTotaisP,nIncrement,nTimeIni)
	Local cTempoRest	:=	""
	Local nHoraRest		:=	0
	LOcal nSecAtual		:=	seconds()
	Local aRetFun		:=	{nil,nil,nil,nil}
	Local nSecAux		:= 0

	If KillApp()
		MsgInfo("Sistema será finalizado.","Atenção - "+ProcName())
		KillApp(.T.)
	EndIf
	//retorna o tempo restante em horas
	//nHoraRest	:=	noROund(((nTotaisP/nIncrement*(nSecAtual-nTimeIni))/60)/60,2)
	nSecAux		:=	Round(((nSecAtual-nTimeIni)/nIncrement)*(nTotaisP-nIncrement),2)
	nHoraRest	:=  Round((nSecAux/60)/60,2)
	aRetFun[1]	:=	U_zVal2Hor(nHoraRest,":")

	//retorna a previsão final da hora
	nHoraFinal	:=	ROund(((nSecAux+nSecAtual)/60)/60,2)
	aRetFun[2]	:=	U_zVal2Hor(nHoraFinal,":") //Previsao Final - Hora
	aRetFun[3]	:=	ROund((100*nIncrement)/nTotaisP,2) //Percentual Conclusão
	aRetFun[4]	:=	cValToChar(nIncrement)+"/"+cValToChar(nTotaisP)+" - "+cValToChar(aRetFun[3])+"% | Prev.Rest.:"+aRetFun[1]+" - Prev.Final:"+aRetFun[2]

Return aRetFun

/*/{Protheus.doc} zVal2Hora
Converte valor numérico (ex.: 15.30) para hora (ex.: 15:30)
@author Atilio
@since 20/09/2014
@version 1.0
@param [nValor], Numérico, Valor numérico correspondente as horas
@param [cSepar], Caracter, Caracter de separação (ex.: 'h', ':', etc)
@return cHora, Variável que irá armazenar as horas
@example
u_zVal2Hora(1.50, 'h') //01h30
u_zVal2Hora(1.50, ':') //01:30
/*/
User Function zVal2Hor(nValor, cSepar)
	Local cHora := ""
	Local cMinutos := ""
	Default cSepar := ":"
	Default nValor := -1

	cHora := Alltrim(Transform(nValor, "@E 99.99"))

	//Se o tamanho da hora for menor que 5, adiciona zeros a esquerda
	If Len(cHora) < 5
		cHora := Replicate('0', 5-Len(cHora)) + cHora
	EndIf

	//Fazendo tratamento para minutos
	cMinutos := SubStr(cHora, At(',', cHora)+1, 2)
	cMinutos := StrZero((Val(cMinutos)*60)/100, 2)

	//Atualiza a hora com os novos minutos
	cHora := SubStr(cHora, 1, At(',', cHora))+cMinutos

	//Atualizando o separador
	cHora := StrTran(cHora, ',', cSepar)

Return cHora

/*/{Protheus.doc} SaveInfo

Funçõa que gera um arquivo conforme agrupador, porém com data e hora

@author charles.reitz
@since 08/11/2016
@version undefined
@param cString, characters, informacao grava no arquuvo
@param cAgrupador, characters, código do agrupado, pode ser o nome da função
@return return, nil
/*/
User Function ZSaveLog(cString,cIdLog,cAgrupador)
	Local cNomeArq 	:= ""
	Local xCRLF		:=	Chr(13)+chr(10)
	Local oFWriter	:=	nil
	Local cFileName
	Default cIdLog	:=	""
	Default cAgrupador	:=	ProcName(1) //caso não passar, pega o nome do fonte anterior a essa rotina como agrupador

	cFileName	:=	dtos(date())+"_"+StrTran(time(),":","")+If(Empty(cIdLog),"","_")+cIdLog+".log"
	If !ExistDir('\log\')
		MakeDir('\log\')
	EndIF
	If !ExistDir('\log\'+cAgrupador+"\")
		MakeDir('\log\'+cAgrupador+"\")
	EndIF

	cNomeArq	:=	"\log\"+cAgrupador+"\"+cFileName

	oFWriter := FWFileWriter():New(cNomeArq,.T.)
	If !oFWriter:Create()
		MsgStop(oFWriter:Error():Message,"Atenção - "+ProcName())
		Conout(oFWriter:Error():Message+" Atenção - "+ProcName())
		Return
	EndIf

	oFWriter:Write(cString+xCRLF)
	oFWriter:Close()
	oFWriter:=nil

Return {cNomeArq,cFileName}

/*/{Protheus.doc} logAtoC
Converte arrai para string

@author charles.reitz
@since 22/12/2016
@version undefined
@param aAutoErro, array, descricao
@type function
/*/
User Function ZArToStr(aAutoErro)
	Local cRet := ""
	Local _ni   := 1

	FOR _ni := 1 to Len(aAutoErro)
		cRet += chr(13)+chr(10)+AllTrim(aAutoErro[_ni])
	NEXT _ni

RETURN cRet

User Function zLinAtuM()
Return " ("+cvaltochar(procline(1))+") "


