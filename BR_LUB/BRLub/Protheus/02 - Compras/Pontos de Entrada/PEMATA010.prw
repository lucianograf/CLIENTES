#Include "Protheus.ch"
#Include "FWMVCDef.ch"
#include 'parmtype.ch'

/*/{Protheus.doc} ITEM
Ponto de entrada em MVC para cadastro de produtos (MATA010).
@author Marcelo Alberto Lauschner
@since 14/03/2019
@version 1.0
@type function
@Reference http://tdn.totvs.com/display/public/PROT/ADV0041_PE_MVC_MATA010_P12
/*/
User Function ITEM()

	Local aParam 	:= ParamIXB
	Local cIDExec	:= ""
	Local cIDForm	:= ""
	Local lOk		:= .T.
	Local nOper		:= 0
	Local oModel	:= Nil
	// Integração ICMAis
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)
	Local cTabela   := SuperGetMV("BF_TABPREC",.F.,"300")

	Begin Sequence
		If !Empty(aParam)
			oModel 	:= aParam[1]
			cIDExec := aParam[2]
			cIDForm	:= aParam[3]
			nOper 	:= oModel:GetOperation()
			If cIDExec  == "FORMPOS"
				If IsBlind()
					lOk	:= sfVldCad(nOper)
				ElseIf lOk :=  ApMsgYesNo("Deseja continuar?")
					lOk	:= sfVldCad(nOper)
				Endif
			EndIf

			If (cIDExec == "MODELCOMMITTTS")
				nOpc := oModel:GetOperation() // PEGA A OPERAÇÃO
				If nOpc == 4
					If FWCodEmp() == '10'
						_cCod   := oModel:GETVALUE("SB1MASTER","B1_COD")
						DbSelectArea('DA1')
						DbSetOrder(1)
						If DbSeek(xFilial('DA1')+cTabela+_cCod)
							RecLock('DA1', .F.)
							DA1->DA1_ZTIME  := Time()
							DA1->DA1_ZDATAL := dDataBase
							DA1->(MsUnlock())
							lRet := U_PNUCGPRD(_cCod)
						EndIf
					EndIf
				EndIf
			EndIf

		EndIf

	End Sequence

	// Integração ICMais
	// Verifica se conseguiu receber valor do PARAMIXB
	If aParam <> NIL 
		// Manter o trecho de código a seguir no final do fonte
		If lPEICMAIS .and. lOk
			lOk := ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
		EndIf
	EndIf

Return lOk


/*/{Protheus.doc} sfVldCad
// Efetua verificação se houve alteração ou não do Produto e dispara WF
@author Marcelo Alberto Lauschner
@since 14/03/2019
@version 1.0
@return Logical, lRet , Informa se houve o envio normal do WF
@param nInOpc, numeric, descricao
@type function
/*/
Static Function sfVldCad(nInOpc)
	Local 	aCamp     	:= {}
	Local 	lRet		:= .T.
	Local 	lContinua 	:= .F.
	Local	aFora     	:= {}
	Local 	aArea 		:= GetArea()
	Local 	aFields		:= {}
	Local 	cCampo		:= ""
	Local 	ik, nX


	// dbSelectArea("SX3")
	// dbSetOrder(1)
	// dbSeek("SB101")
	// While !EOF() .And. (x3_arquivo == "SB1")
	// 	If SX3->X3_context <> 'V'
	// 		If Ascan(aFora,Trim(X3_CAMPO)) <= 0
	// 			Aadd(aCamp, { SX3->X3_CAMPO, SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL,SX3->X3_TITULO } )
	// 		Endif
	// 	Endif
	// 	dbSkip()
	// EndDO

	aFields := FWSX3Util():GetAllFields("SB1", .F. /*/lVirtual/*/)
	For nX := 1 to Len(aFields)
		cCampo := aFields[nx]
		If GetSx3Cache(cCampo,"X3_CONTEXT") <> "V"
			If Ascan(aFora,Trim(GetSx3Cache(cCampo,"X3_CAMPO"))) <= 0
				Aadd(aCamp, {GetSx3Cache(cCampo,"X3_CAMPO"),GetSx3Cache(cCampo,"X3_TIPO"),GetSx3Cache(cCampo,"X3_TAMANHO"), GetSx3Cache(cCampo,"X3_DECIMAL"),GetSx3Cache(cCampo,"X3_TITULO")} )
			EndIf
		EndIf
	Next nX

	If nInOpc == 3
		sfInclusao(aCamp)  // chama workflow de inclusão de produto
	ElseIf nInOpc == 4
		For ik := 1 To Len(aCamp)
			If &("SB1->"+aCamp[ik,1]) <> &("M->"+aCamp[ik,1])
				lContinua := .T.
				Exit
			Endif
		Next

		If lContinua
			lRet := sfAltera(aCamp)
		Endif
	Endif

	RestArea(aArea)

Return lRet


/*/{Protheus.doc} sfAltera
//Envio de Workflow quando o cliente for alterado e com os dados que foram alterados
@author marce
@since 15/08/2017
@version 6
@param aCamp, array, descricao
@type function
/*/
Static Function sfAltera(aCamp)

	// Local 	lContinua 	:= .F.
	Local	cSendMail	:= "fiscal2@atrialub.com.br;fiscal1@atrialub.com.br;"
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	oHTML
	Local	x
	Local 	iW 

	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Alteração de cadastro de Clientes"))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abre o HTML criado                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If IsSrvUnix()
		If File("/workflow/produto_mt010.htm")
			oProcess:NewTask("Gerando HTML","/workflow/produto_mt010.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/produto_mt010.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\produto_mt010.htm")
	Endif

	oProcess:cSubject := "Produto Alterado-> "+SB1->B1_COD+"-"+SB1->B1_DESC
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML

	// Preenche os dados do cabecalho
	oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
	oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
	oHtml:ValByName("INSC","Inscrição Estadual: " + SM0->M0_INSC)

	For x := 1 To Len(aCamp)
		If &("SB1->"+aCamp[x,1]) <> &("M->"+aCamp[x,1])
			AAdd((oHtml:ValByName("p.col")),(aCamp[x,1]))
			AAdd((oHtml:ValByName("p.camp")),(aCamp[x,5]))

			If aCamp[x,2] == "N"
				AAdd((oHtml:ValByName("p.orig")),Transform(&("SB1->"+aCamp[x,1]),"@E 999,999,999.99"))
				AAdd((oHtml:ValByName("p.nov")),Transform(&("M->"+aCamp[x,1]),"@E 999,999,999.99"))
			Else
				AAdd((oHtml:ValByName("p.orig")),&("SB1->"+aCamp[x,1]))
				AAdd((oHtml:ValByName("p.nov")),&("M->"+aCamp[x,1]))
			Endif

		Endif
	next



	oHtml:ValByName("DATA",DTOC(dDataBase))
	oHtml:ValByName("HORA",Time())

	oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))

	cSendMail	+= UsrRetMail(__cuserId)
	
	cSendMail 	:= U_BFFATM15(cSendMail,"PEMATA010")
	// Trata a limpeza dos e-mails repetidos 
	cRecebe := IIf(!Empty(cSendMail),cSendMail+";","")	
	aOutMails	:= StrTokArr(cRecebe,";")
	cRecebe	:= ""
	For iW := 1 To Len(aOutMails)
		If !Empty(cRecebe)
			cRecebe += ";"
		Endif
		If IsEmail(aOutMails[iW]) .And. !(Alltrim(Upper(aOutMails[iW])) $ cRecebe)
			cRecebe	+= Upper(aOutMails[iW])
		Endif
	Next
	oProcess:cTo := cRecebe

	oProcess:Start()
	oProcess:Finish()
	
	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return


/*/{Protheus.doc} sfInclusao
//Gera Workflow quando for incluído um novo cliente
@author Marcelo Alberto Lauschner
@since 15/08/2017
@version 6

@type function
/*/
Static Function sfInclusao(aCamp)

	Local	cSendMail	:= "fiscal2@atrialub.com.br;fiscal1@atrialub.com.br;"
	// Local 	lContinua 	:= .F.
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	oHTML
	Local	x


	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Inclusão de cadastro de Cliente."))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abre o HTML criado                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If IsSrvUnix()
		If File("/workflow/produto_mt010.htm")
			oProcess:NewTask("Gerando HTML","/workflow/produto_mt010.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/produto_mt010.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\produto_mt010.htm")
	Endif


	oProcess:cSubject := "Cadastro de Produto incluído -> "+M->B1_COD+"-" +M->B1_DESC
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML

	// Preenche os dados do cabecalho
	oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
	oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
	oHtml:ValByName("INSC","Inscrição Estadual: " + SM0->M0_INSC)


	For x := 1 To Len(aCamp)
		AAdd((oHtml:ValByName("p.col")),(aCamp[x,1]))
		AAdd((oHtml:ValByName("p.camp")),(aCamp[x,5]))

		If aCamp[x,2] == "N"
			AAdd((oHtml:ValByName("p.orig")),"")
			AAdd((oHtml:ValByName("p.nov")),Transform(&("M->"+aCamp[x,1]),"@E 999,999,999.99"))
		Else
			AAdd((oHtml:ValByName("p.orig")),"")
			AAdd((oHtml:ValByName("p.nov")),&("M->"+aCamp[x,1]))
		Endif


	next


	oHtml:ValByName("DATA",DTOC(dDataBase))
	oHtml:ValByName("HORA",Time())

	oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
	cSendMail	+= UsrRetMail(__cuserId)
	oProcess:cTo := U_BFFATM15(cSendMail,"PEMATA010")

	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return
