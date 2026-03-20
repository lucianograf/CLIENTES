//Bibliotecas
#Include "Protheus.ch"
#Include "RWMake.ch"
#Include "Ap5Mail.ch"

Static nVez := 1 //Se for caixas no hotmail.com / outlook.com, deve-se rodar a rotina duas vezes seguidas, pois ele nÃ£o consegue "mover" de pasta na primeira vez

/*/{Protheus.doc} DECMail
Função para buscar anexos de e-Mails da Locaweb / Uol
@author Arthur Voltolini
@since 30/09/2022
@version 1.0
@type function
@obs Abaixo algumas observacoes:
 
    1 - Essa funcao utiliza a classe tMailManager com contas IMAP
    2 - Essa rotina baixa emails para a pasta \gfe\ dentro da Protheus Data
/*/

User Function DECMail(lIsRecursivo)
	Local cArqSem     := "\gfe\semaforo_email.lck"
    Default lIsRecursivo    := .F. 
	Private lJobPvt   := .F.

	If nVez <= 2
		//Alert("DECMail -  Processo iniciado - "+Time())
        FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Processo iniciado - "+Time())
		//Se nao tiver aberto o dicionario (rotina executada sem abrir o Protheus)
		If Select("SX2") <= 0
			RPCClearEnv()

			RPCSetEnv("01","01")
			lJobPvt := .T.

		ElseIf !lIsRecursivo
			If ! MsgYesNo("Deseja acessar a caixa de entrada e baixar os arquivos TXT?", "ATENCAO")
				Return
			EndIf
		EndIf

		//Se existir o samáforo, da mensagem de erro
		If File(cArqSem)
			//Alert("DECMail -  samáforo existente (" + MemoRead(cArqSem) + ") - "+Time())

			//Mostrando mensagem
			If ! lJobPvt
				Aviso("ATENCAO", "Semáforo existente (Processo iniciado em " + MemoRead(cArqSem) + ")")
			EndIf

		Else
			//Chamando o processamento de dados
			Processa({|| fProcessa() }, "Processando...")

			//Mostrando mensagem de conclusão
			If ! lJobPvt
				Aviso("ATENCAO", "Processo concluido.")
			EndIf

			FErase(cArqSem)
		EndIf

		//Para caixas Hotmail, rodar 2x para mover de pasta
		nVez++
		u_DECMail(.T./*lIsRecursivo*/)
	EndIf

    FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Processo finalizado - "+Time())
Return

/*---------------------------------------------------------------*
 | Func.: fProcessa                                              |
 | Desc.: funcao de processamento para buscar os arquivos        |
 *---------------------------------------------------------------*/
 
Static Function fProcessa()
    Private cDirBase  := GetSrvProfString("RootPath", "")
    Private cDirOco   := "\gfe\ocorre\"
    Private cDirDoc   := "\gfe\doccob\"  
    Private cDirXml   := "\gfe\xml\"  
    Private cConta    := ''
    Private cSenha    := ''
    Private cSrvFull  := ''
    Private cServer   := ''
    Private nPort     := 0
 
    //Definindo dados da conta
    cConta    := "gfe.decanter@gmail.com"
    cSenha    := "zxumimnfzcvhrloz"
    cSrvFull  := "smtp.gmail.com:993"
    cServer   := Iif(':' $ cSrvFull, SubStr(cSrvFull, 1, At(':', cSrvFull)-1), cSrvFull)
    nPort     := Iif(':' $ cSrvFull, Val(SubStr(cSrvFull, At(':', cSrvFull)+1, Len(cSrvFull))), 110)
     
    //Se o ultimo caracter nao for barra, retira ela
    If SubStr(cDirBase, Len(cDirBase), 1) == '\'
        cDirBase := SubStr(cDirBase, 1, Len(cDirBase)-1)
    EndIf
     
    cDirFullO := cDirBase + cDirOco
    cDirFullD := cDirBase + cDirDoc
    cDirFullC := cDirBase + cDirXml

    fBaixa()
Return
 
/*---------------------------------------------------------------*
 | Func.: fBaixa                                                 |
 | Desc.: Função que baixa as mensagens do e-Mail                |
 *---------------------------------------------------------------*/
 
Static Function fBaixa()
    Local aArea := GetArea()
    Local cArqINI
    Local cBkpConf
    Local nRet
    Local nNumMsg
    Local nMsgAtu
    Local oManager
    Local oMessage
    Local nAnexoAtu
    Local nTotAnexo
    Local aInfAttach
    Local lOk
    Local lEntrou

    Local aMailOco := StrTokArr(GetMV("DC_OCOREN"),";")
    Local aMailDoc := StrTokArr(GetMV("DC_DOCCOB"),";")
    
    //Altera o arquivo appserver.ini, deixando como IMAP
    cArqINI  := GetSrvIniName()
    cBkpConf := GetPvProfString( "MAIL", "Protocol", "", cArqINI )
    WritePProString('MAIL', 'PROTOCOL', 'IMAP', cArqINI)
 
    //Cria a conxao base no gerenciamento
    oManager := TMailMng():New( 1, 3, 6 , .T. )

    oManager:cUser := cConta
    oManager:cPass := cSenha
    oManager:cSrvAddr   := cServer
    oManager:cSMTPAddr  := cServer
    oManager:nSrvTimeout := 80

    nRet := oManager:Connect()

        If nRet != 0 
            Alert("DECMail - ERROR - " + StrZero(nRet, 6), oManager:GetErrorString(nRet))
            FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Falha ao Conectar no E-amil - "+oManager:GetErrorString(nRet)) 
        Else
            //Alert("DECMail -  Sucesso ao conectar" )
 
            //Busca o numero de mensagens na caixa de entrada
            nNumMsg := 0
            oManager:GetNumMsgs(@nNumMsg)
             
            If nNumMsg > 0
                ProcRegua(nNumMsg)
                 
                For nMsgAtu := 1 To nNumMsg
                    IncProc("Baixando e-Mail " + cValToChar(nMsgAtu) + " de " + cValToChar(nNumMsg) + "...")
                     
                    //Buscando a mensagem atual
                    oMessage := tMailMessage():new()
                    oMessage:Clear()
                    oMessage:Receive2(oManager, nMsgAtu)
 
                    //Busca o total de Anexos
                    nTotAnexo := oMessage:GetAttachCount()
                     
                    //Limpando a flag
                    lOk := .T.
                    lEntrou := .F.
                     
                    //Percorre todos os anexos
                    For nAnexoAtu := 1 To nTotAnexo
                        aInfAttach := oMessage:GetAttachInfo(nAnexoAtu)
                         
                        //Se tiver conteúdo, e for do tipo XML
                        If !Empty(aInfAttach[4]) .And. Upper(Right(AllTrim(aInfAttach[4]),4)) == '.TXT' .OR. !Empty(aInfAttach[1]) .And. Upper(Right(AllTrim(aInfAttach[1]),4)) == '.TXT'
                            lEntrou := .T.
                             
                            //Salva o arquivo na pasta correta
                            IF !Empty(aInfAttach[4])
                                If "OCOREN" $ Upper(aInfAttach[4]) .OR. aScan(aMailOco, {|x| AllTrim(x) $ Upper(aInfAttach[4])}) > 0
                                    oMessage:SaveAttach(nAnexoAtu, cDirFullO + aInfAttach[4])
                                    //DCXCOPY(cDirOco + aInfAttach[1],cDirOco+"enviados\"+aInfAttach[1],.T.)
                                    FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Anexo salvo")    
                                ElseIf "DOCCOB" $ Upper(aInfAttach[4]) .OR. aScan(aMailDoc,{|x| AllTrim(x) $ Upper(aInfAttach[4])}) > 0
                                    oMessage:SaveAttach(nAnexoAtu, cDirFullD + aInfAttach[4])
                                    FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Anexo salvo") 
                                Else
                                    lOk := .F.
                                EndIf
                            ElseIf !Empty(aInfAttach[1])
                                 If "OCOREN" $ Upper(aInfAttach[1]) .OR. aScan(aMailOco, {|x| AllTrim(x) $ Upper(aInfAttach[1])}) > 0
                                    oMessage:SaveAttach(nAnexoAtu, cDirFullO + aInfAttach[1])
                                    //DCXCOPY(cDirOco + aInfAttach[1],cDirOco+"enviados\"+aInfAttach[1],.T.)
                                    FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Anexo salvo")    
                                ElseIf "DOCCOB" $ Upper(aInfAttach[1]) .OR. aScan(aMailDoc,{|x| AllTrim(x) $ Upper(aInfAttach[1])}) > 0
                                    oMessage:SaveAttach(nAnexoAtu, cDirFullD + aInfAttach[1])
                                    FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Anexo salvo") 
                                Else
                                    lOk := .F.
                                EndIf
                            EndIf
                        ElseIf !Empty(aInfAttach[1]) .And. Upper(Right(AllTrim(aInfAttach[1]),4)) == '.XML' .OR.!Empty(aInfAttach[4]) .And. Upper(Right(AllTrim(aInfAttach[4]),4)) == '.XML'
                            lEntrou := .T.
                            If !Empty(aInfAttach[1])
                                oMessage:SaveAttach(nAnexoAtu, cDirFullC + aInfAttach[1])
                                FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Anexo salvo")    
                            ElseIf !Empty(aInfAttach[4])
                                oMessage:SaveAttach(nAnexoAtu, cDirFullC + aInfAttach[4])
                                FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Anexo salvo") 
                            EndIf   
                        EndIf
 
                    Next nAnexoAtu

                    If lEntrou
                       nRet := oManager:MoveMsg( nMsgAtu, "Importados" )
                        if nRet <> 0
                            conout( nRet )
                            conout( oManager:GetErrorString( nRet ) )
                        endif
                    ElseIf ! (oManager:MoveMsg(nMsgAtu, "Processados"))
                        if nRet <> 0
                            conout( nRet )
                            conout( oManager:GetErrorString( nRet ) )
                        endif                          
                    EndIf

 
                Next nMsgAtu                
            Else
                FWLogMsg("INFO","",'1',"DECMail",,"DECMail","Não existem mensagens para processamento...") 
            EndIf
 
            //Desconecta do servidor IMAP
            oManager:Disconnect()
        EndIf
     
    //Volta a configuracao de Protocol no arquivo appserver.ini
    WritePProString('MAIL', 'PROTOCOL', cBkpConf, cArqINI)
     
    RestArea(aArea)
Return

Static Function DCXCOPY(cDe,cPara,lExclui)
    Default lExclui := .F.

	__CopyFile(cDe,cPara)

	FRenameEX(cPara,cPara,Nil)

	IF lExclui
        Ferase(cDe)
    EndIF    

Return
