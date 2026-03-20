#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "XMLXFUN.CH"

/*/{Protheus.doc} MLFATM04
// Rotina de envio de Arquivo XML 
@author Marcelo Alberto Lauschner
@since 24/08/2019
@version 1.0
@return ${return}, ${return_description}
@param cInNumNf, characters, descricao
@type function
/*/
User Function MLFATM04(cInNumNf,lSetEnv,cInEmp,cInFil)

	Local aOpenTable := {"SF2","SA1","SA4","SX6"}
	Private lAutoExec	:= .T. 
	Default	cInNumNf	:= ""
	Default lSetEnv		:= .F.	
	
	If lSetEnv 

		RPCSetType(3)
		RPCSetEnv(cInEmp,cInFil,"","","","",aOpenTable) // Abre todas as tabelas.	

		If stControle(.F.,"MLFATM04_"+cFilAnt)

			stExecuta("",.T.)		
			
			stControle(.T.,"MLFATM04_"+cFilAnt)
			
			RpcClearEnv() // Limpa o environment	
		Endif 

	Else
		lAutoExec	:= .F. 
		If stControle(.F.,"MLFATM04_"+cFilAnt)

			stExecuta(cInNumNf)
			
			stControle(.T.,"MLFATM04_"+cFilAnt)
			
		Endif 

	Endif

Return


Static Function stControle(lLibera,cInName)

	Local	nTentativas	:= 0
	Default lLibera 	:= .F.
	Default cInName		:= "MYEMAIL"

	
	If !lLibera
		While !LockByName(cInName,.F.,.F.,.T.)
			If lAutoExec
				Sleep(2000)
			Else
				MsAguarde({|| Sleep(1000) }, "Semaforo de processamento... tentativa "+Alltrim(STR(nTentativas)), "Aguarde, rotina sendo executada por outro usuário.")//"Semaforo de processamento... tentativa "##"Aguarde, arquivo sendo alterado por outro usuário."
			Endif
			nTentativas++

			If nTentativas > 100
				If lAutoExec
					Return (.F.)
				Else
					If PswAdmin( , ,RetCodUsr()) == 0 
						If !MsgYesNo("Não foi possível acesso exclusivo para o recebimento de e-mails.Deseja tentar novamente ?") //"Não foi possível acesso exclusivo para edição do Pré-Projeto da proposta. Deseja tentar novamente ?"
							Return .F.
						Else
							Return .T.
						EndIf
					Else
						If MsgYesNo("Não foi possível acesso exclusivo para o recebimento de e-mails.Deseja tentar novamente ?") //"Não foi possível acesso exclusivo para edição do Pré-Projeto da proposta. Deseja tentar novamente ?"
							nTentativas := 0
							Loop
						Else
							Return(.F.)
						EndIf
					Endif
				Endif
			EndIf
		EndDo
	Else
		UnLockByName(cInName,.F.,.F.,.T.)
	Endif

Return .T.


/*/{Protheus.doc} stExecuta
// Executa o envio do XMLs
@author Marcelo Alberto Lauschner
@since 24/08/2019
@version 1.0
@return ${return}, ${return_description}
@param cInNumNf, characters, descricao
@type function
/*/
Static Function stExecuta(cInNumNf,lAuto)

	Local	cQry		:= ""
	Local	nContEnv	:= 0
	Local	aAreaOld	:= GetArea()
	Local	cBody		:= ""
	Default lAuto		:= .F. 
	Private oNFe

	MakeDir("\edi\")
	MakeDir("\edi\xmlsnfe\")

	cDtEnvio    := DTOS(dDataBase-7)  // Sempre envia de 3 dias atrás. Evita que notas canceladas possam ser enviadas.

	cIdent		:= U_MLTSSENT() 

	cQry += "SELECT F2.R_E_C_N_O_ F2RECNO "
	cQry += "  FROM "+RetSqlName("SF2") + " F2 "
	cQry += " WHERE F2.D_E_L_E_T_ =' ' "
	cQry += "   AND F2_EMISSAO >= '"+cDtEnvio+"' "
	cQry += "   AND F2_FILIAL = '"+xFilial("SF2")+"' "
	cQry += "   AND F2_TIPO = 'N' "
	cQry += "   AND F2_XFLGNFE = ' ' "

	If !Empty(cInNumNf)
		cQry += "   AND F2_DOC = '" + cInNumNf + "'"
	Endif
	cQry += "   AND F2_CHVNFE <>  ' ' "
	cQry += "   AND F2_ESPECIE = 'SPED' "


	TCQUERY cQry NEW ALIAS "QRY"

	While !Eof()

		If lAuto
			Sleep(10*1000) 
		Endif 
		DbSelectArea("SF2")
		DbGoTo(QRY->F2RECNO)


		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)

		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SF2->F2_VEND1)

		DbSelectArea("SA4")
		DbSetOrder(1)
		DbSeek(xFilial("SA4")+SF2->F2_TRANSP)

		sfExpXml(cIdEnt,SF2->F2_SERIE,SF2->F2_DOC,SF2->F2_EMISSAO,SA1->A1_CGC)


		cArq	:= "\edi\xmlsnfe\"+Alltrim(SF2->F2_SERIE)+"_"+Alltrim(SF2->F2_DOC)+".xml"

		cArqPdf	:= U_MLDNFPROC(2/*nType 1-Entrada 2-Saída*/,"\edi\xmlsnfe\"/*cPasta*/,SF2->F2_SERIE/*cSerie*/,SF2->F2_DOC/*cNota*/,SF2->F2_EMISSAO)

		//Crio a conexão com o server STMP ( Envio de e-mail )
		oServer := TMailManager():New()


		// Usa SSL na conexao
		If GetMv("XM_SMTPSSL")
			oServer:setUseSSL(.T.)
		Endif

		// Usa TLS na conexao
		If GetNewPar("XM_SMTPTLS",.F.)
			oServer:SetUseTLS(.T.)
		Endif

		oServer:Init( "" ,Alltrim(GetMv("XM_SMTP")), Alltrim(GetMv("XM_SMTPUSR"))	,Alltrim(GetMv("XM_PSWSMTP")),	0	, GetMv("XM_SMTPPOR") )

		//seto um tempo de time out com servidor de 1min
		If oServer:SetSmtpTimeOut( GetMv("XM_SMTPTMT") ) != 0
			Conout( "Falha ao setar o time out" )
			MsgAlert("Falha ao setar o TimeOut")
			QRY->(DbCloseArea())
			RestArea(aAreaOld)
			Return .F.
		EndIf

		//realizo a conexão SMTP
		If oServer:SmtpConnect() != 0
			Conout( "Falha ao conectar" )
			MsgAlert("Falha ao conectar SMTP")
			QRY->(DbCloseArea())
			RestArea(aAreaOld)
			Return .F.
		EndIf

		// Realiza autenticacao no servidor
		If GetMv("XM_SMTPAUT")
			nErr := oServer:smtpAuth(Alltrim(GetMv("XM_SMTPUSR")), Alltrim(GetMv("XM_PSWSMTP")))
			If nErr <> 0
				ConOut("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr))
				MsgAlert("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr))
				oServer:smtpDisconnect()
				QRY->(DbCloseArea())
				RestArea(aAreaOld)
				Return .F.
			Endif
		Endif

		//Apos a conexão, crio o objeto da mensagem
		oMessage := TMailMessage():New()
		//Limpo o objeto
		oMessage:Clear()
		//Populo com os dados de envio
		oMessage:cFrom 		:= GetMv("XM_SMTPDES")
		oMessage:cTo 		:= Alltrim(Lower(SA1->A1_EMAIL))
		oMessage:cCc 		:= "ml-servicos@outlook.com" + Iif(!Empty(SA4->A4_EMAIL),";"+Alltrim(Lower(SA4->A4_EMAIL)),"") + Iif(!Empty(SA3->A3_EMAIL),";"+Alltrim(Lower(SA3->A3_EMAIL)),"")
		oMessage:cSubject 	:= Alltrim("XML-NOTA "+SF2->F2_SERIE+"/"+SF2->F2_DOC+" - " + SM0->M0_NOMECOM)
		oMessage:MsgBodyType( "text/html" )
		oMessage:cBody 		:= "Você está recebendo o XML da Nota Fiscal " +SF2->F2_SERIE+"/"+SF2->F2_DOC+ "<br>" +;
			"<br>"+ "<br>"+;
			"At."+ "<br>" +;
			SM0->M0_NOMECOM + "<br>"  + cBody

		//Adiciono um attach
		If oMessage:AttachFile( cArq ) < 0
			Conout( "Erro ao atachar o arquivo" )
			MsgAlert("Não foi possível anexar o arquivo " + cArq,"Erro" )
			QRY->(DbCloseArea())
			RestArea(aAreaOld)
			Return .F.
		Else
			//adiciono uma tag informando que é um attach e o nome do arq
			oMessage:AddAtthTag( 'Content-Disposition: attachment; filename='+Alltrim(SF2->F2_SERIE)+"_"+Alltrim(SF2->F2_DOC)+'.xml')
		EndIf

		//Adiciono um attach
		If File("\edi\xmlsnfe\"+cArqPdf)
			If oMessage:AttachFile( "\edi\xmlsnfe\"+cArqPdf ) < 0
				Conout( "Erro ao atachar o arquivo" )
				MsgAlert("Não foi possível anexar o arquivo " + cArqPdf,"Erro" )
				QRY->(DbCloseArea())
				RestArea(aAreaOld)
				Return .F.
			Else
				//adiciono uma tag informando que é um attach e o nome do arq
				oMessage:AddAtthTag( 'Content-Disposition: attachment; filename='+cArqPdf)
			EndIf
		Else 
			ConOut("Não encontrado arquivo \edi\xmlsnfe\"+cArqPdf)
		Endif 

		//Envio o e-mail
		If oMessage:Send( oServer ) != 0
			Conout( "Erro ao enviar o e-mail" )
			//MsgAlert("Erro ao enviar o email")
			//RestArea(aAreaOld)
			//Return .F.
		EndIf

		//Disconecto do servidor
		If oServer:SmtpDisconnect() != 0
			Conout( "Erro ao disconectar do servidor SMTP" )
			MsgAlert("Erro ao desconectar do servidor SMTP")
			//RestArea(aAreaOld)
			//Return .F.
		EndIf

		nContEnv++

		// Grava flag
		DbSelectArea("SF2")
		RecLock("SF2",.F.)
		SF2->F2_XFLGNFE		:= "S"
		MsUnlock()

		If nContEnv > 500
			QRY->(DbCloseArea())
			Return
		Endif

		DbSelectArea("QRY")
		DbSkip()
	Enddo

	QRY->(DbCloseArea())

Return

/*/{Protheus.doc} ConvType
// Efetua conversão dos dados para o formato esperado no XML
@author Copiado do NfeSefaz
@since 24/08/2019
@version 1.0
@return ${return}, ${return_description}
@param xValor, , descricao
@param nTam, numeric, descricao
@param nDec, numeric, descricao
@type function
/*/
Static Function ConvType(xValor,nTam,nDec)

	Local cNovo := ""
	DEFAULT nDec := 0
	Do Case
	Case ValType(xValor)=="N"
		If xValor <> 0
			cNovo := AllTrim(Str(xValor,nTam,nDec))
		Else
			cNovo := "0"
		EndIf
	Case ValType(xValor)=="D"
		cNovo := FsDateConv(xValor,"YYYYMMDD")
		cNovo := SubStr(cNovo,1,4)+"-"+SubStr(cNovo,5,2)+"-"+SubStr(cNovo,7)
	Case ValType(xValor)=="C"
		If nTam==Nil
			xValor := AllTrim(xValor)
		EndIf
		DEFAULT nTam := 60
		cNovo := AllTrim(NoAcento(SubStr(xValor,1,nTam)))
	EndCase
Return(cNovo)




Static Function sfExpXml(cIdEnt,cInSerie,cInNota,dInDtEmis,cInCgc)

	Local	cSerDir		:= "\edi\xmlsnfe\"
	Local 	aAreaOld	:= GetArea()
	Local 	cAnexo		:= cSerDir+Alltrim(cInSerie)+"_"+Alltrim(cInNota)+".xml"

	sfXmlExp(cIdEnt,cSerDir,cInSerie+cInNota,cInSerie+cInNota,CtoD("  /  /  "),dDataBase+90,cInCgc,cInCgc,.T.,cAnexo)

	FwLogMsg('INFO', , 'MLMDFEBX', FunName(), '', '01', "Exportada série/nota : " + cInSerie + "/"+ cInNota + " Entidade/Cnpj: " + cIdEnt + "/" + cInCgc , 0, 0, {})

	RestArea(aAreaOld)

Return





Static Function sfXmlExp(cIdEnt,cDirDest,cIdInicial,cIdFinal,dDtInicial,dDtFinal,cCnpjInicial,cCnpjFinal,lTipImp,cAnexo)

	Local 		cURL        := PadR(GetNewPar("MV_SPEDURL","http://"),250)

	Local lDelXml  := .F.
	Local nDIASEXC := 0
	Local nHandle  := 0
	Local cChvNFe  := ""
	Local cDestino := ""
	Local cDrive   := ""
	Local cModelo  := ""
	Local cPrefixo := ""
	Local lFinal   := .F.
	Local aDeleta  := {}
	Local nX       := 0
	Local oWS
	Local oRetorno
	Local oXML
	Local cNFes    := ""
	Local cIdflush := cIdInicial
	Local lFlush   := .T.
	Local lTipoXml := lTipImp

	cDestino := AllTrim(cDirDest)
	SplitPath(cDirDest,@cDrive,@cDestino,"","")
	cDestino := cDrive+cDestino


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicia processamento                                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN        := "TOTVS"
	oWS:cID_ENT           := cIdEnt
	oWS:_URL              := AllTrim(cURL)+"/NFeSBRA.apw"
	oWS:cIdInicial        := cIdflush // cIdInicial
	oWS:cIdFinal          := cIdFinal
	oWS:dDataDe           := dDtInicial
	oWS:dDataAte          := dDtFinal
	oWS:cCNPJDESTInicial  := cCnpjInicial
	oWS:cCNPJDESTFinal    := cCnpjFinal
	oWS:nDiasparaExclusao := nDIASEXC
	lOk := oWS:RETORNANX()
	oRetorno:= oWS:oWsRetornaNxResult

	If lOk
		ProcRegua(Len(oRetorno:OWSNOTAS:OWSNFES5))
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Exporta as notas                                                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		For nX := 1 To Len(oRetorno:OWSNOTAS:OWSNFES5)
			oXml := oRetorno:OWSNOTAS:OWSNFES5[nX]
			oXmlExp   := XmlParser(oRetorno:OWSNOTAS:OWSNFES5[nX]:OWSNFE:CXML,"","","")
			If !Empty(oXml:oWSNFe:cProtocolo)
				cNotaIni := oXml:cID
				cIdflush := cNotaIni
				cNFes := cNFes+cNotaIni+CRLF
				IncProc("ID: "+cNotaIni)

				cChvNFe  := sfGENNfeId(oXml:oWSNFe:cXML,"Id")
				cModelo := cChvNFe
				cModelo := StrTran(cModelo,"NFe","")
				cModelo := StrTran(cModelo,"CTe","")
				cModelo := SubStr(cModelo,21,02)

				Do Case
				Case cModelo == "57"
					cPrefixo := "CTe"
				OtherWise
					cPrefixo := "NFe"
				EndCase

				If lTipoXml
					//nHandle := FCreate(cDestino+cChvNFe+"-proc"+cPrefixo+".xml")
					nHandle := FCreate(cAnexo)
					If nHandle > 0
						cCab1 := '<?xml version="1.0" encoding="UTF-8"?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
						cRodap:= '</nfeProc>'
						FWrite(nHandle,AllTrim(cCab1))
						FWrite(nHandle,AllTrim(oXml:oWSNFe:cXML))
						FWrite(nHandle,AllTrim(oXml:oWSNFe:cXMLPROT))
						FWrite(nHandle,AllTrim(cRodap))
						FClose(nHandle)
						aadd(aDeleta,oXml:cID)
					EndIf
				Else

					nHandle := FCreate(cDestino+cChvNFe+"-"+cPrefixo+".xml")
					If nHandle > 0
						FWrite(nHandle,oXml:oWSNFe:cXML)
						FClose(nHandle)
						aadd(aDeleta,oXml:cID)
					EndIf
					nHandle := FCreate(cDestino+"\"+cChvNFe+"-aut.xml")
					If nHandle > 0
						FWrite(nHandle,oXml:oWSNFe:cXMLPROT)
						FClose(nHandle)
					EndIf
				EndIf
			EndIf
			If oXml:OWSNFECANCELADA<>Nil .And. !Empty(oXml:oWSNFeCancelada:cProtocolo)
				cNotaIni := oXml:cID
				cIdflush := cNotaIni
				cNFes := cNFes+cNotaIni+CRLF
				cChvNFe  := sfGENNfeId(oXml:oWSNFeCancelada:cXML,"Id")
				If !"INUT"$oXml:oWSNFeCancelada:cXML

					If lTipoXml
						nHandle := FCreate(cDestino+cChvNFe+"-proc-can.xml")
						If nHandle > 0
							FWrite(nHandle,AllTrim(oXml:oWSNFeCancelada:cXML))
							FWrite(nHandle,AllTrim(oXml:oWSNFeCancelada:cXMLPROT))
							aadd(aDeleta,oXml:cID)
							FClose(nHandle)
						EndIf
					Else
						nHandle := FCreate(cDestino+cChvNFe+"-ped-can.xml")
						If nHandle > 0
							FWrite(nHandle,oXml:oWSNFeCancelada:cXML)
							FClose(nHandle)
							aadd(aDeleta,oXml:cID)
						EndIf
						nHandle := FCreate(cDestino+"\"+cChvNFe+"-can.xml")
						If nHandle > 0
							FWrite(nHandle,oXml:oWSNFeCancelada:cXMLPROT)
							FClose(nHandle)
						EndIf
					EndIf

				Else

					If lTipoXml
						nHandle := FCreate(cDestino+cChvNFe+"-proc-inu.xml")
						If nHandle > 0
							FWrite(nHandle,oXml:oWSNFeCancelada:cXML)
							FWrite(nHandle,oXml:oWSNFeCancelada:cXMLPROT)
							aadd(aDeleta,oXml:cID)
							FClose(nHandle)
						EndIf
					Else
						nHandle := FCreate(cDestino+cChvNFe+"-ped-inu.xml")
						If nHandle > 0
							FWrite(nHandle,oXml:oWSNFeCancelada:cXML)
							FClose(nHandle)
							aadd(aDeleta,oXml:cID)
						EndIf
						nHandle := FCreate(cDestino+"\"+cChvNFe+"-inu.xml")
						If nHandle > 0
							FWrite(nHandle,oXml:oWSNFeCancelada:cXMLPROT)
							FClose(nHandle)
						EndIf
					EndIf
				EndIf
			EndIf
			If oXml:oWSDPEC <> Nil .And. !Empty(oXml:OWSDPEC:CPROTOCOLO)
				cNotaIni := oXml:cID
				cIdflush := cNotaIni
				cNFes := cNFes+cNotaIni+CRLF
				IncProc("ID: "+cNotaIni)

				cChvNFe  := sfGENNfeId(oXml:oWSNFe:cXML,"Id")
				cModelo := cChvNFe
				cModelo := StrTran(cModelo,"NFe","")
				cModelo := StrTran(cModelo,"CTe","")
				cModelo := SubStr(cModelo,21,02)

				cPrefixo :="DPEC"

				If lTipoXml
					nHandle := FCreate(cDestino+cChvNFe+"-proc"+cPrefixo+".xml")
					If nHandle > 0
						cCab1 := '<?xml version="1.0" encoding="UTF-8"?><nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
						cRodap:= '</nfeProc>'
						FWrite(nHandle,AllTrim(cCab1))
						FWrite(nHandle,AllTrim(oXml:OWSDPEC:cXML))
						FWrite(nHandle,AllTrim(oXml:OWSDPEC:cXMLPROT))
						FWrite(nHandle,AllTrim(cRodap))
						FClose(nHandle)
						aadd(aDeleta,oXml:cID)
					EndIf
				Else
					nHandle := FCreate(cDestino+cChvNFe+"-"+cPrefixo+".xml")
					If nHandle > 0
						FWrite(nHandle,oXml:OWSDPEC:cXML)
						FClose(nHandle)
						aadd(aDeleta,oXml:cID)
					EndIf
					nHandle := FCreate(cDestino+"\"+cChvNFe+"-retDpec.xml")
					If nHandle > 0
						FWrite(nHandle,oXml:OWSDPEC:cXMLPROT)
						FClose(nHandle)
					EndIf
				EndIf
			EndIf
			IncProc()
		Next nX
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Exclui as notas                                                        ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !Empty(aDeleta) .And. lDelXml
			oWS:= WSNFeSBRA():New()
			oWS:cUSERTOKEN        := "TOTVS"
			oWS:cID_ENT           := cIdEnt
			oWS:nDIASPARAEXCLUSAO := nDIASEXC
			oWS:_URL              := AllTrim(cURL)+"/NFeSBRA.apw"
			oWS:oWSNFEID          := NFESBRA_NFES2():New()
			oWS:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
			oWS:nDanfe			  :=0
			For nX := 1 To Len(aDeleta)
				aadd(oWS:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
				Atail(oWS:oWSNFEID:oWSNotas:oWSNFESID2):cID := aDeleta[nX]
			Next nX
			If !oWS:RETORNANOTAS()
				Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Ok"},3)
				lFlush := .F.
			EndIf
		EndIf
		aDeleta  := {}

		If Len(oRetorno:OWSNOTAS:OWSNFES5) == 0 .And. Empty(cNfes)
			Aviso("Totvs Sped Manager","Não há dados",{"Ok"})	//"Totvs Sped Manager"###"Não há dados"
			lFlush := .F.
		EndIf
	Else
		Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3))+CRLF,{"OK"},3)
		lFinal := .T.
	EndIf



Return(.T.)


Static Function sfGENNfeId(cXML,cAttId) 
	Local nAt  := 0
	Local cURI := ""
	Local nSoma:= Len(cAttId)+2

	nAt := At(cAttId+'=',cXml)
	cURI:= SubStr(cXml,nAt+nSoma)
	nAt := At('"',cURI)
	If nAt == 0
		nAt := At("'",cURI)
	EndIf
	cURI:= SubStr(cURI,1,nAt-1)
Return(cUri)
