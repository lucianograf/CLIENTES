#INCLUDE "rwmake.ch"
#INCLUDE "tbiconn.ch"

/*/{Protheus.doc} MA030TOK
(long_description)
@author MarceloLauschner
@since 26/03/2010
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User function MA030TOK()
	Local 	aCamp     	:= {}
	Local 	lRet		:= .T.
	Local 	lContinua 	:= .F.
	Local	aFora     	:= {}
	Local 	aArea 		:= GetArea()
	Local 	ik, nX
	Local 	cVldAltCpo	:= "A1_CGC#A1_INSCR#A1_NOME#A1_NREDUZ#A1_CEP#A1_END#A1_COMPLEM#A1_EST#A1_COD_MUN#A1_MUN#A1_BAIRRO#A1_DDD#A1_TEL#A1_CONTATO#A1_EMAIL#A1_REFCOM1#A1_REFCOM3"
	Local	lAltCpo		:= .F.
	Local   aFields 	:= {}
	Local 	cCampo		:= ""
	Private	cRetCodUsr	:= RetCodUsr()

	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MA030TOK")
		Return .T. 
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If !ALTERA .And. !INCLUI
		RestArea(aArea)
		Return .T.
	Endif

	M->A1_ULTALT  	:= dDatabase
	
	
	//IAGO 16/12/2015 - Ajuste para integracao Accera
	If M->A1_EST == "PR" .And. cEmpAnt == "02"
		If Empty(M->A1_RAMACCE)
			MsgAlert("O preenchimento do campo [Ramo Accera] é obrigatório para clientes do PR!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			RestArea(aArea)
			Return .F.
		EndIf
	Endif


	// dbSelectArea("SX3")
	// dbSetOrder(1)
	// dbSeek("SA1")
	// While !EOF() .And. (x3_arquivo == "SA1")
	// 	If SX3->X3_context <> 'V'
	// 		If Ascan(aFora,Trim(X3_CAMPO)) <= 0
	// 			Aadd(aCamp, { SX3->X3_CAMPO, SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL,SX3->X3_TITULO } )
	// 		Endif
	// 	Endif
	// 	dbSkip()
	// EndDO

	aFields := FWSX3Util():GetAllFields("SA1", .F. /*/lVirtual/*/)
	For nX := 1 to Len(aFields)
		cCampo := aFields[nx]
		If GetSx3Cache(cCampo,"X3_CONTEXT") <> "V" .AND. Ascan(aFora,Trim(GetSx3Cache(cCampo,"X3_CAMPO"))) <= 0
			Aadd(aCamp, {GetSx3Cache(cCampo,"X3_CAMPO")	,;
				GetSx3Cache(cCampo,"X3_TIPO")			,;
				GetSx3Cache(cCampo,"X3_TAMANHO")		,;
				GetSx3Cache(cCampo,"X3_DECIMAL")		,;
				GetSx3Cache(cCampo,"X3_TITULO")			})
		EndIf
	Next nX

	If INCLUI
		sfInclusao(aCamp)  // chama workflow de inclusão de produto
	ElseIf ALTERA
		For ik := 1 To Len(aCamp)
			If &("SA1->"+aCamp[ik,1]) <> &("M->"+aCamp[ik,1])
				lContinua := .T.
				// 04/03/2019 - Chamado 22.670 - Define regra que cliente alterado ajustado o campo de limite crédito automaticamente para 1.99
				If !(cRetCodUsr $ GetNewPar("BF_SA1_USR","000000")) .And. Alltrim(aCamp[ik,1]) $ cVldAltCpo
					lAltCpo			:= .T. 					
				Endif
				//Exit
			Endif
		Next
		
		If lContinua
			lRet := sfAltera(aCamp,lAltCpo)
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
Static Function sfAltera(aCamp,lAltCpo)
	
	Local	cSendMail	:= ""// Chamado 25777 Desativado o envio de email para o setor Crédito "credito1@atrialub.com.br;cobranca1@atrialub.com.br;"
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	oHTML, x
	
	If MsgYesno("Continua alteração?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

		cProcess := "100000"
		cStatus  := "100000"
		oProcess := TWFProcess():New(cProcess,OemToAnsi("Alteração de cadastro de Clientes"))

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Abre o HTML criado                                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If IsSrvUnix()
			If File("/workflow/ma030tok.htm")
				oProcess:NewTask("Gerando HTML","/workflow/ma030tok.htm")
			Else
				FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/ma030tok.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Return
			Endif
		Else
			oProcess:NewTask("Gerando HTML","\workflow\ma030tok.htm")
		Endif

		oProcess:cSubject := "Cliente Alterado-> "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NREDUZ
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
			If &("SA1->"+aCamp[x,1]) <> &("M->"+aCamp[x,1])
				AAdd((oHtml:ValByName("p.col")),(aCamp[x,1]))
				AAdd((oHtml:ValByName("p.camp")),(aCamp[x,5]))

				If aCamp[x,2] == "N"
					AAdd((oHtml:ValByName("p.orig")),Transform(&("SA1->"+aCamp[x,1]),"@E 999,999,999.99"))
					AAdd((oHtml:ValByName("p.nov")),Transform(&("M->"+aCamp[x,1]),"@E 999,999,999.99"))
				Else
					AAdd((oHtml:ValByName("p.orig")),&("SA1->"+aCamp[x,1]))
					AAdd((oHtml:ValByName("p.nov")),&("M->"+aCamp[x,1]))
				Endif

			Endif
		next
		
		If lAltCpo
			AAdd((oHtml:ValByName("p.col"))	,"Alteração de dados Cadastrais")
			AAdd((oHtml:ValByName("p.camp")),"Será necessário revisar")
			AAdd((oHtml:ValByName("p.orig")),"cadastro e restaurar")
			AAdd((oHtml:ValByName("p.nov"))	,"o limite de crédito.")

			AAdd((oHtml:ValByName("p.col"))	,"A1_LC")
			AAdd((oHtml:ValByName("p.camp")),"Limite Crédito")
			AAdd((oHtml:ValByName("p.orig")),Transform(Iif(SA1->A1_LC == 1.99 .And. SA1->A1_VALREMB > 0, SA1->A1_VALREMB, SA1->A1_LC),"@E 999,999,999.99"))
			AAdd((oHtml:ValByName("p.nov"))	,Transform(M->A1_LC,"@E 999,999,999.99")) 
		Endif

		oHtml:ValByName("DATA",DTOC(dDataBase))
		oHtml:ValByName("HORA",Time())

		oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
		If lAltCpo
			cSendMail	+= UsrRetMail(cRetCodUsr)
		Else
			cSendMail	:= UsrRetMail(cRetCodUsr)
		Endif
		
		oProcess:cTo := U_BFFATM15(cSendMail,"MT030TOK")

		oProcess:Start()
		oProcess:Finish()

		// Força disparo dos e-mails pendentes do workflow
		WFSENDMAIL()


		Return(.T.)
	Endif

Return(.F.)


/*/{Protheus.doc} sfInclusao
//Gera Workflow quando for incluído um novo cliente
@author Marcelo Alberto Lauschner
@since 15/08/2017
@version 6

@type function
/*/
Static Function sfInclusao(aCamp)
	
	Local	cSendMail	:= "" // Chamado 25777 Desativado o envio de email para o setor Crédito  "credito1@atrialub.com.br;cobranca1@atrialub.com.br;"
	Local	cProcess
	Local	cStatus
	Local	oProcess
	Local	oHTML
	Local 	x 
	
	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Inclusão de cadastro de Cliente."))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abre o HTML criado                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If IsSrvUnix()
		If File("/workflow/ma030tok.htm")
			oProcess:NewTask("Gerando HTML","/workflow/ma030tok.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/ma030tok.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\ma030tok.htm")
	Endif


	oProcess:cSubject := "Cadastro de Cliente incluído -> "+M->A1_COD+"/"+M->A1_LOJA +"-" +M->A1_NREDUZ
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
	cSendMail	+= UsrRetMail(cRetCodUsr)
	oProcess:cTo := U_BFFATM15(cSendMail,"MT030TOK")

	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return
