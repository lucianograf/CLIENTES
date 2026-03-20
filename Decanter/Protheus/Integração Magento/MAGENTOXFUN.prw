#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MAGENTOXFUN

Gera o token de autenticação com o Magento

@author charles.totvs
@since 09/05/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function MAGEAuth()
	Local oWsdl			:= TWsdlManager():New()
	Local cUrlWSDL  	:= GetMv("MA_URLWSDL"	,,"https://homolog.decanter.com.br/api/v2_soap?wsdl")
	Local cAuthUser		:= GetMv("MA_USUARIO"	,,"totvs")
	Local cAuthPass		:= GetMv("MA_TOKENAC"	,,"6Dz9lKDlEnIs")
	Local lHttpAuth		:= GetMv("MA_HTTPAUT"	,,.T.)
	Local cHttpUser		:= GetMv("MA_HTTPUSE"	,,"trezo")
	Local cHttpPass		:= GetMv("MA_HTTPPAS"	,,"apolo17")
	Local lVerboseOn	:= GetMv("MA_SAVEXML"	,,.F.)
	Local cTime			:= Time()
	Local lRet			:=	.F.
	Local cTokenRet		:= ""
	Local oXML 			:= nil

	FWLogMsg("INFO","",'1',"LOGIN",,"MAGENTO","Efetuando login Magento")

	Begin Sequence

		//oWsdl:lProcResp := .F.
		//oWsdl:lCompressed := .T.
		oWsdl:lSSLInsecure := .T.
		//oWsdl:lUseNSPrefix := .T.
		//oWsdl:lRemEmptyTags := .T.
		//oWsdl:bNoCheckPeerCert := .T.
		oWsdl:lVerbose := lVerboseOn

		// Verifica se precisa de autenticação no HTTP
		If lHttpAuth
			FWLogMsg("INFO","LAST",'1',"LOGIN",,"MAGENTO","Efetuado autenticação com HTTP")
			oWsdl:SetAuthentication(cHttpUser,cHttpPass)
		EndIf

		// Faz o parse de uma URL
		if !oWsdl:ParseURL(cUrlWSDL)
			cMsgError	:=	 "Não foi possível realizar conexão com o servidor"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
			MsgAlert(cMsgError,Procname())
			Break
		endif

		// Seta a operação a ser utilizada
		IF !oWsdl:SetOperation( "login" )
			cMsgError	:=	 "Não foi possível realizar conexão com o servidor."+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
			MsgAlert(cMsgError,Procname())
			Break
		ENDIF

		// Define o valor de cada parâmeto necessário
		if !oWsdl:SetValue( 0,cAuthUser)
			cMsgError	:=	 "Não foi possível definir usuário para montagem do xml"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
			MsgAlert(cMsgError,Procname())
			Break
		endif
		if !oWsdl:SetValue( 1,cAuthPass)
			cMsgError	:=	 "Não foi possível definir senha para montagem do xml"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
			MsgAlert(cMsgError,Procname())
			Break
		endif
		FWLogMsg("DEBUG","LAST",'1',"LOGIN",,"MAGENTO",oWsdl:GetSoapMsg())

		// Envia a mensagem SOAP ao servidor
		if !oWsdl:SendSoapMsg()
			cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
			MsgAlert(cMsgError,Procname())
			Break
		endif

		FWLogMsg("DEBUG","LAST",'1',"LOGIN",,"MAGENTO",oWsdl:GetSoapResponse())

		//http://tdn.totvs.com/display/tec/TXmlManager%3ADOMParentNode
		//http://tdn.totvs.com/display/tec/TXmlManager%3AXPathGetNodeValue
		//oXML	:=	TXMLManager():New()
		//if !oXML:Parse( oWsdl:GetSoapResponse() )
		//	conout( "Errors on Parse!" )
		//else
		//	conout( "No errors on Parse!" )
		//endif
		cError		:=	""
		cWarning	:= ""
		oXml := XmlParser( oWsdl:GetSoapResponse() , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
			MsgAlert(cMsgError,Procname())
			Break
		EndIf

		cTokenRet	:=	oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_LOGINRESPONSE:_LOGINRETURN:TEXT
		oXML:= NIL
		FreeObj(oXML)

		FWLogMsg("INFO","LAST",'1',"LOGIN",,"MAGENTO",oWsdl:GetSoapResponse())
		FWLogMsg("INFO","LAST",'1',"LOGIN",,"MAGENTO","Token de Acesso Magento:"+cTokenRet)


	End Sequence

	FWLogMsg("INFO","LAST",'1',"LOGIN",,"MAGENTO","Login magento finalizado!")

	oWsdl	:= nil
	FreeObj(oWsdl)
Return cTokenRet


/*/{Protheus.doc} MAGENTOXFUN

Funções genericas

@author charles.totvs
@since 30/04/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
user function MAGENTOXFUN()
return

/*/{Protheus.doc} MXFLog

Rotina responsavel por realizar o log na tabela de monitor

@author charles.totvs
@since 06/05/2019
@version undefined
@param cTipoLog, characters, descricao
@param cRotina, characters, descricao
@param cMsgLog, characters, descricao
@param cDataOut, characters, descricao
@param cDataIn, characters, descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function MXFLog(cTipoLog,cRotina,cMsgLog,cDataOut,cDataIn)

	If lIsBlind


	Else

	EndIf
	//Criar uma tabela para isso ... precisa fazer
	//cTipoLog 1:Alert (vermelho) / 2:Warmings (amarelo)
	//cRotina
	//cMsgLog: mensagem
	//cDataOut: dataSaida (envio para o webservice)
	//cDataIn: dataEntrada (retorno do webservice)

Retur lRet



/*/{Protheus.doc} PutUsrLock
Grava usurio que est com lock no arquivo
@author charles.reitz
@since 31/08/2017
@version undefined
@param cLockName, characters, descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function PutUsrLock(cLockName)
	//aInfoUsr := PswRet()
	If File("\semaforo\"+cLockName+".lck")
		FERASE("\semaforo\"+cLockName+".lck")
	EndIf
	nHandle := FCREATE("\semaforo\"+cLockName+".lck", 0)
	If nHandle <> -1
		fopen("\semaforo\"+cLockName+".lck",64)
		FWrite(nHandle,cUserName, 25) // Insere texto no arquivo
		fclose(nHandle) // Fecha arquivo
	EndIf
Return

/*/{Protheus.doc} GetUsrLock
Pega o usurio que est com lock e apresenta
@author charles.reitz
@since 31/08/2017
@version undefined
@param cLockName, characters, descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function GetUsrLock(cLockName)
	Local cUsuArq	:=	""

	nHandle := fopen("\semaforo\"+cLockName+".lck", 64 )
	If nHandle <> -1
		FRead( nHandle, cUsuArq, 25 )
		fclose(nHandle) // Fecha arquivo
	EndIf
	msgInfo("Rotina está"+chr(65533)+" sendo utilizada pelo usu"+chr(65533)+"rio "+cUsuArq,"Aten"+chr(65533)+chr(65533)+"o - "+FunName())

Return


/*/{Protheus.doc} DelUsrLock
Deleta o controle de semafaro
@author charles.reitz
@since 31/08/2017
@version undefined
@param cLockName, characters, descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function DelUsrLock(cLockName)
	Local cUsuArq	:=	""

	nHandle := fopen("\semaforo\"+cLockName+".lck", 64 )
	If nHandle <> -1		
		FRead( nHandle, cUsuArq, 25 )
		fclose(nHandle) // Fecha arquivo
		If Alltrim(cUsuArq) == Alltrim(cUserName)
			FERASE("\semaforo\"+cLockName+".lck")
		EndIf
	Endif

Return
