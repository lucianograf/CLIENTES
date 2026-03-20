
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "AP5MAIL.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "APWEBEX.CH"
#INCLUDE "APWEBSRV.CH"
#INCLUDE "SHELL.CH"

/*/{ProtUser eus.doc} DECFAT06E
    Job para enviar e-mail de itens excluidos
    @type  Function
    @author Jonivani Pereira
    @since 11/08/2023
    @version 1.0
    /*/
User Function DECAT006(aParam)
	Local lSend       := .F. as logical
	Local nX          := 0   as numeric
	Local cCodEmp     := aParam[1] //FWCodEmp() 
	Local cCodFil     := aParam[2] //FWCodFil()
	Local cCodPed     := aParam[3] //SC5->C5_NUM
	Local cCodCli     := aParam[4] //SC5->C5_CLIENTE
    Private aItens    := {}  as array
	Private cAnexo    := ""  as Character
	Private cAssunto  := ""  as Character
	Private cBCC      := ""  as Character
	Private cCC       := ""  as Character
	Private cFrom     := ""  as Character
	Private cMensagem := ""  as Character
	Private cPara     := ""  as Character
	Private cTitulo   := ""  as Character
	Private lJob      := (Type( "oMainWnd" ) <> "O")
	
	RpcClearEnv()
	RpcSetType(3)
	RpcSetEnv(cCodEmp,cCodFil,,,'FAT')

		ConOut( "DECFAT06 - Start - " + cValToChar(Date()) + " - " + cValToChar(Time()) ) 
		
		// Alterar o staus e retornar dados a ser enviado porDECFAT6S email
		DECFAT6D(cCodFil, cCodPed, cCodCli)

		// Sem arquivos para enviar finalizar a função.
		If Len(aItens) == 0
			ConOut( "DECFAT06 - END - " + cValToChar(Date()) + " - " + cValToChar(Time()) + " Sem dados para enviar por e-mail" ) 
			If !lJob
				FWAlertError("Sem dados a serem enviao por e-mail", "Sem dados")
			Endif
			RpcClearEnv()
			Return
		EndIf

		cAnexo   := ""
		cTitulo  := "FALTA ESTOQUE"
		cAssunto := "Falta Estoque Pedido: " + cValToChar(aItens[1][5]) // Pedido
		cPara    := AllTrim(aItens[1][19]) // Email do vendedor
		cCC      := AllTrim(aItens[1][22]) // E-mail copia informado na tela do indicador

		// Retona o Layout do e-mail e com os dados incluido no HTML
		cMensagem := DECFAT6H(aItens, cTitulo)
		
		// envia o e-mail
		lSend := DECFAT6S(cPara, cAssunto, cMensagem, cAnexo, cFrom, cCC, cBCC)
		
		// Se e-mail enviado atualiza a data de envio e hora
		If lSend
			DbSelectArea("ZZO")
			ZZO->(DBSetOrder(1)) // ZZO_FILIAL+ZZO_PEDIDO+ZZO_ITEM+ZZO_CODROD
			For nX:= 1 to Len(aItens)
				If ZZO->(DBSeek(xFilial("ZZO") + Padr(aItens[nX][5] ,TamSX3("ZZO_PEDIDO")[1]) + Padr(aItens[nX][6] ,TamSX3("ZZO_ITEM")[1]) + Padr(aItens[nX][7] ,TamSX3("ZZO_CODROD")[1])))
					//Exclui o registro
					Begin Transaction
						RecLock('ZZO', .F.)
							ZZO->ZZO_STATUS := "3"
							ZZO->ZZO_DTENV  := Date()
							ZZO->ZZO_HRENV  := Time()
						ZZO->(MsUnlock())
					End Transaction
				EndIf
			Next
		EndIf

		ConOut( "DECFAT06 - End - " + cValToChar(Date()) + " - " + cValToChar(Time()) ) 

	RpcClearEnv()
Return 


/*/{Protheus.doc} DECFAT6D
    Função para buscar os itens a serem enviados no e-mail
	Retona os dados para envio do e-mail.
    @type  Function
    @author Jonivani Pereira
    @since 11/08/2023
    @version 1.0
    @param 
        cCodFilal, Character, filial
        cCodPedido, Character, pedido
        cCodCli, Character, codigo cliente
/*/
Static Function DECFAT6D(cCodFil, cCodPed, cCodCli)
    Local cAlias  := GetNextAliAs()
	Local cAliasB  := GetNextAliAs()
	
    //Buscar os intesn do pedido.
    BeginSql AliAs cAlias
		%NoParser%
        SELECT 
			  ZZO_FILIAL
			, ZZO_ID    
			, ZZO_CODCLI
			, ZZO_CLIENT
			, ZZO_PEDIDO
			, ZZO_ITEM  
			, ZZO_CODROD
			, ZZO_DESPRO
			, ZZO_QUANT 
			, ZZO_PRCVEN
			, ZZO_VALOR 
			, ZZO_DTPED 
			, ZZO_USREXC
			, ZZO_DTEXCL
			, ZZO_HREXCL
			, ZZO_OBSERV
			, ZZO_VEND  
			, ZZO_NOMEVD
			, ZZO_EMAILV
			, ZZO_ENVMAI
			, ZZO_MTEXCL
			, ZZO_QTDFAL
			, ZZO_EMACOP
		FROM 
			%table:ZZO% ZZO WITH(NOLOCK)
		WHERE 
			ZZO.%notdel% 
            AND ZZO.ZZO_FILIAL = %exp:cCodFil%
            AND ZZO_CODCLI = %exp:cCodCli%
            AND ZZO_PEDIDO = %exp:cCodPed%
			AND ZZO_STATUS = '1'
		ORDER BY 
			ZZO_ITEM
    EndSql

	// Alterar o status para 2 Como finalizado.
	If Len(cAlias) > 0
        (cAlias)->(DbGoTop())
		DbSelectArea("ZZO")
        ZZO->(DBSetOrder(1)) // ZZO_FILIAL+ZZO_PEDIDO+ZZO_ITEM+ZZO_CODROD 
        While !(cAlias)->(Eof()) 
			If ZZO->(DBSeek(xFilial("ZZO") + Padr((cAlias)->ZZO_PEDIDO ,TamSX3("ZZO_PEDIDO")[1]) + Padr((cAlias)->ZZO_ITEM ,TamSX3("ZZO_ITEM")[1]) + Padr((cAlias)->ZZO_CODROD ,TamSX3("ZZO_CODROD")[1])))
				//Exclui o registro
				Begin Transaction
					RecLock('ZZO', .F.)
						ZZO->ZZO_STATUS  := "2"
					ZZO->(MsUnlock())
				End Transaction
			EndIf
            (cAlias)->(Dbskip())
        EndDo  
        (cAlias)->(DbCloseArea())
    EndIf


	// Buscar os itens a ser enviado no e-mail
	BeginSql AliAs cAliasB
		%NoParser%
        SELECT 
			  ZZO_FILIAL
			, ZZO_ID    
			, ZZO_CODCLI
			, ZZO_CLIENT
			, ZZO_PEDIDO
			, ZZO_ITEM  
			, ZZO_CODROD
			, ZZO_DESPRO
			, ZZO_QUANT 
			, ZZO_PRCVEN
			, ZZO_VALOR 
			, ZZO_DTPED 
			, ZZO_USREXC
			, ZZO_DTEXCL
			, ZZO_HREXCL
			, ZZO_OBSERV
			, ZZO_VEND  
			, ZZO_NOMEVD
			, ZZO_EMAILV
			, ZZO_ENVMAI
			, ZZO_MTEXCL
			, ZZO_QTDFAL
			, ZZO_EMACOP
		FROM 
			%table:ZZO% ZZO WITH(NOLOCK)
		WHERE 
			ZZO.%notdel% 
            AND ZZO.ZZO_FILIAL = %exp:cCodFil%
            AND ZZO_CODCLI = %exp:cCodCli%
            AND ZZO_PEDIDO = %exp:cCodPed%
            AND ZZO_STATUS = '2' // Finalizado
            AND ZZO_ENVMAI = '1' // Enviar e-mail
			AND ZZO_DTENV = "" 
			AND ZZO_HRENV = ""
		ORDER BY 
			ZZO_ITEM
    EndSql

    If Len(cAliasB) > 0
        (cAliasB)->(DbGoTop())
        While !(cAliasB)->(Eof())  
			AAdd(aItens,{(cAliasB)->ZZO_FILIAL ,;//[1]
                         (cAliasB)->ZZO_ID     ,;//[2]
                         (cAliasB)->ZZO_CODCLI ,;//[3]
                         (cAliasB)->ZZO_CLIENT ,;//[4]
                         (cAliasB)->ZZO_PEDIDO ,;//[5]
                         (cAliasB)->ZZO_ITEM   ,;//[6]
                         (cAliasB)->ZZO_CODROD ,;//[7]
                         (cAliasB)->ZZO_DESPRO ,;//[8]
                         (cAliasB)->ZZO_QUANT  ,;//[9]
                         (cAliasB)->ZZO_PRCVEN ,;//[10]
                         (cAliasB)->ZZO_VALOR  ,;//[11]
                         (cAliasB)->ZZO_DTPED  ,;//[12]
                         (cAliasB)->ZZO_USREXC ,;//[13]
                         (cAliasB)->ZZO_DTEXCL ,;//[14]
                         (cAliasB)->ZZO_HREXCL ,;//[15]
                         (cAliasB)->ZZO_OBSERV ,;//[16]
                         (cAliasB)->ZZO_VEND   ,;//[17]
                         (cAliasB)->ZZO_NOMEVD ,;//[18]
                         (cAliasB)->ZZO_EMAILV ,;//[19]
                         (cAliasB)->ZZO_ENVMAI ,;//[20]
                         (cAliasB)->ZZO_QTDFAL ,;//[21]
                         (cAliasB)->ZZO_EMACOP ,;//[22]
                         (cAliasB)->ZZO_MTEXCL}) //[23]

            (cAliasB)->(Dbskip())
        EndDo  
        (cAliasB)->(DbCloseArea())
    EndIf

Return 


/*/{Protheus.doc} DECFAT6H
    Função para buscar o arquivo layut html 
    @type  Function
    @author Jonivani Pereira
    @since 11/08/2023
    @version 1.0
/*/
Static Function DECFAT6H(aItens, cTitulo)
	Local cHtmlCompleto := ""
	Local cHtmlTable    := ""
	Local cBodyTable    := ""
	Local cArqIndex     := "\html\decanter\relitensexcl\index.html"
	Local cArqItens     := "\html\decanter\relitensexcl\bodyTable.html"
	Local nI            := 0


	//Carrega Index
    oFileIndex := FWFileReader():New(cArqIndex)
    If (oFileIndex:Open())
    	While (oFileIndex:hasLine())
    	  //Conout(oFile:GetLine())
    	  cHtmlCompleto += oFileIndex:GetLine()
    	EndDo
    	oFileIndex:Close()
    Endif

	//Carrega matriz de itens da tabela
    oFileTable := FWFileReader():New(cArqItens)
    If (oFileTable:Open())
		While (oFileTable:hasLine())
		//Conout(oFile:GetLine())
		cHtmlTable += oFileTable:GetLine()
		EndDo
		oFileTable:Close()
    Endif

	cHtmlCompleto := StrTran(cHtmlCompleto,"@TITULO@"  			, cTitulo)
	cHtmlCompleto := StrTran(cHtmlCompleto,"@PEDIDO@"			, aItens[1][5])
	cHtmlCompleto := StrTran(cHtmlCompleto,"@DATA_PEDIDO@"		, cValToChar(STOD(aItens[1][12])))
	cHtmlCompleto := StrTran(cHtmlCompleto,"@CLIENTE@"			, aItens[1][3] + " - " + aItens[1][4])
	cHtmlCompleto := StrTran(cHtmlCompleto,"@VENDEDOR@"			, aItens[1][17] + " - " + aItens[1][18])

	// Tabela de notas 
	For nI := 1 to len(aItens)
		cBodyTable += cHtmlTable
		cBodyTable := StrTran(cBodyTable, "@CODIGO@" 			, aItens[nI][7] ) //[2] 
		cBodyTable := StrTran(cBodyTable, "@DESCRICAO@" 		, aItens[nI][8] ) //[3] 
		cBodyTable := StrTran(cBodyTable, "@QTD_VEND@" 		 	, cValToChar(aItens[nI][9] )) //[4] 
		cBodyTable := StrTran(cBodyTable, "@QTD_FALTA@" 		, cValToChar(aItens[nI][21])) //[8] 
		cBodyTable := StrTran(cBodyTable, "@USUARIO_EXCLUIU@" 	, aItens[1][13]) //[8] 
		cBodyTable := StrTran(cBodyTable, "@DATA_EXCLUSAO@" 	, cValToChar(STOD(aItens[1][14]))) //[9] 
		cBodyTable := StrTran(cBodyTable, "@HORA_EXCLUSAO@" 	, aItens[nI][15]) //[10]
		cBodyTable := StrTran(cBodyTable, "@OBSERVACAO@"    	, aItens[nI][16]) //[11]
	Next
						
	cHtmlCompleto := StrTran(cHtmlCompleto,"@BODYTABLE@", cBodyTable)
	
Return cHtmlCompleto

/*/{Protheus.doc} DECFAT6S
    Função para enviar e-mail
    @type  Function
    @author Jonivani Pereira
    @since 11/08/2023
    @version 1.0
    /*/
Static Function DECFAT6S(cPara, cAssunto, cMensagem, cAnexo,cFrom, cCC, cBCC)
    Local oServer     := Nil
	Local oMessage    := Nil
	Local nErr        := 0
	local cPopAddr    := SEPARA(GetMV("MV_RELSERV"),":")[1]    // Endereco do servidor POP3
	local cSMTPAddr   := SEPARA(GetMV("MV_RELSERV"),":")[1]    // Endereco do servidor SMTP
	local cPOPPort    := 110                                   // Porta do servidor POP  110
	local cSMTPPort   := 587                                   // Porta do servidor SMTP 587
	Local nSMTPTime   := GetMV("MV_RELTIME")                   // Timeout SMTP           120
	local cUser       := ALLTRIM(GetMV("MV_RELACNT"))          // Usuario que ira realizar a autenticacao totvs.decanter@gmail.com
	local cPass       := ALLTRIM(GetMV("MV_RELPSW"))           // Senha do usuario paogcgvresnobdco
    Local lTest       := SuperGetMV("DC_SENDTST",.F., .T.)       //[.T.] Envia para e-mail controlado.,[.F.] Envia e-mail para email de vendedor.
	
	Default cPara     := ""
	Default cCC       := ""
	Default cBCC      := ""
	Default cAssunto  := ""
	Default cMensagem := ""
	Default cAnexo    := "" // O caminho desse arquivo tem que estar dentro de qualquer pasta do ROOTPATH (Normalmente Protheus_Data)

	cBCC := GetMV("DC_MAILADT") // E-mail auditoria


	// Se for teste envia para e-mail controlado
    If lTest
        cPara := "jonivani.pereira@vamilly.com.br"
        //cCC   := "jonivani@gmail.com"
        //cBCC  := "jonivani_ricardo@hotmail.com"
    EndIf	

	If Empty(cPara)
		conout("[ERROR]Email destino não definido.")
		If !lJob
			Alert("[ERROR]Email destino não definido.")
		Endif
		return .F.
	EndIf

	// Instancia um novo TMailManager
	oServer := tMailManager():New()

	// Usa SSL na conexao
	oServer:SetUseSSL(.T.)
	conout("[SendEmail]->SSL")
	
    oServer:SetUseTls(.T.)
	conout("[SendEmail]->SSL->TLS")

	// Inicializao
	oServer:init(cPopAddr, cSMTPAddr, cUser, cPass, cPOPPort, cSMTPPort)

	// Define o Timeout SMTP
	if oServer:SetSMTPTimeout(nSMTPTime) != 0
		conout("[ERROR] Falha ao definir timeout")
		If !lJob
			Alert("[ERROR] Falha ao definir timeout")
		Endif
		return .F.
	endif

	// Conecta ao servidor
	nErr := oServer:smtpConnect()
	if nErr <> 0
		conOut("[ERROR] Falha ao conectar: " + oServer:getErrorString(nErr))
		If !lJob
        	Alert("[ERROR] Falha ao conectar: " + oServer:getErrorString(nErr))
		EndIf
		oServer:smtpDisconnect()
		return .F.
	endif

	// Realiza autenticacao no servidor
	nErr := oServer:smtpAuth(cUser, cPass)

	if nErr <> 0
		conOut("[ERROR] Falha ao autenticar: " + oServer:getErrorString(nErr))
		If !lJob
        	Alert("[ERROR] Falha ao autenticar: " + oServer:getErrorString(nErr))
		EndIf
		oServer:smtpDisconnect()
		return .F.
	endif

	// Cria uma nova mensagem (TMailMessage)
	oMessage           := tMailMessage():New()
	oMessage:clear()
	oMessage:cFrom     := cUser 
	oMessage:cTo       := cPara
	oMessage:cCC       := cCC
	oMessage:cBCC      := cBCC
	oMessage:cSubject  := cAssunto
	oMessage:cBody     := cMensagem
    oMessage:MsgBodyType("text/html")

	If !Empty(cAnexo)
		xRet := oMessage:AttachFile( cAnexo )
		if xRet < 0
			cMsg := "Could not attach file " + cAnexo
			conout( cMsg )
			return
		endif
	EndIf

	// Envia a mensagem
	nErr := oMessage:send(oServer)
	if nErr <> 0
		conout("[ERROR] Falha ao enviar: " + oServer:getErrorString(nErr))
		If !lJob
        	Alert("[ERROR] Falha ao enviar: " + oServer:getErrorString(nErr))
		EndIf
		conout("DECFAT6S->e-mail não enviados: " + cValToChar(cPara))
		oServer:smtpDisconnect()
		return .F.
	Else
		conout("DECFAT6S->e-mail enviados: " + cValToChar(cPara))
	endif

	// Disconecta do Servidor
	oServer:smtpDisconnect()
    
Return .T.