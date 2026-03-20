#include 'protheus.ch'

User Function teste()
    Local oWsdl			:= TWsdlManager():New()
    oWsdl:lSSLInsecure := .T.
    oWsdl:SetAuthentication("trezo","apolo17")

    if !oWsdl:ParseURL("https://homolog.decanter.com.br/api/v2_soap?wsdl")
        cMsgError	:=	 "Não foi possível realizar conexão com o servidor"+chr(13)+chr(10)+oWsdl:cError
        FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
        MsgAlert(cMsgError,Procname())
        Break
    endif

    IF !oWsdl:SetOperation( "login" )
			cMsgError	:=	 "Não foi possível realizar conexão com o servidor."+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
			MsgAlert(cMsgError,Procname())
			Break
    ENDIF


    if !oWsdl:SetValue( 0,"totvs")
        cMsgError	:=	 "Não foi possível definir usuário para montagem do xml"+chr(13)+chr(10)+oWsdl:cError
        FWLogMsg("ERROR","LAST",'1',"LOGIN",,"MAGENTO",cMsgError)
        MsgAlert(cMsgError,Procname())
        Break
    endif
    if !oWsdl:SetValue( 1,"6Dz9lKDlEnIs")
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


return
