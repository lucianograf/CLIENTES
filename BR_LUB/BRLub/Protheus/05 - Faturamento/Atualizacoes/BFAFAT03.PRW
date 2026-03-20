#include "protheus.ch"

/*/{Protheus.doc} BFAFAT03
(Alteração rápida de email no cadastro de clientes )
@author MarceloLauschner
@since 24/06/2010
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFAFAT03()

	Local		aAreaOld		:= GetArea()
	Local		lContinua		:= .F.
	Private		cCodCli			:= Space(TamSx3("A1_COD")[1])
	Private   	cLojCli			:= Space(TamSx3("A1_LOJA")[1])
	Private		cNomCli			:= Space(TamSx3("A1_NOME")[1])
	Private		cEmail			:= Space(TamSx3("A1_EMAIL")[1])
	Private 	nPotLits := nPotPneus	:= 0
	Private   	oEmail,oNomCli,oDlg1,oPotLits,oPotPneus,oSayPLits,oSayPPneus,oObs
	//IAGO 21/10/2016 Chamado(16148)
	Private 	cObs			:= Space(TamSx3("A1_OBSCLI")[1])

	If type("M->UA_CLIENTE") == "C"
		If !lProspect .And. !Empty(M->UA_CLIENTE)
			cCodCli		:= M->UA_CLIENTE
			cLojCli		:= M->UA_LOJA
		Endif
	Endif

	DEFINE MSDIALOG oDlg1 Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Alteração rápida de clientes") FROM 001,001 TO 240,427 Pixel

	@ 10,018 Say "Código do Cliente" of oDlg1 Pixel 
	@ 10,070 MsGet cCodCli F3 "SA1" of oDlg1 Pixel
	@ 10,108 MsGet cLojCli Valid stValSA1()  of oDlg1 Pixel
	@ 22,018 Say "Nome do Cliente"  of oDlg1 Pixel
	@ 22,070 MsGet oNomCli Var cNomCli Size 130,12 of oDlg1 Pixel When .F.
	@ 36,018 Say "Novo E-Mail"  of oDlg1 Pixel
	@ 36,070 MsGet oEmail Var cEmail Size 130,12 of oDlg1 Pixel
	//IAGO 21/10/2016 Chamado(16148)
	@ 50,018 Say "Observação"  of oDlg1 Pixel
	@ 50,070 MsGet oObs Var cObs Size 130,12 of oDlg1 Pixel
	oSayPLits:= TSay():New(64,018,{||"Potencial Litros (" + cValToChar(SA1->A1_POTENC) +")"},oDlg1,,,,                 ,,.T.,,,200,12)
	@ 64,070 MsGet oPotLits Var nPotLits Picture "@E 999.999"  Size 40,12  of oDlg1 Pixel
	oSayPPneus:= TSay():New(78,018,{||"Potencial Pneus (" + cValToChar(SA1->A1_POTENC2) + ")"},oDlg1,,,,                  ,,.T.,,,200,12)
	@ 78,070 MsGet oPotPneus Var nPotPneus Size 40,12 Picture "@E 999.999"  of oDlg1 Pixel

	@ 104,050 Button "Confirma" Size 35,12 Action (lContinua := .T.,oDlg1:End())  of oDlg1 Pixel
	@ 104,090 Button "Cancela"  Size 35,12 Action oDlg1:End()  of oDlg1 Pixel


	stValSA1()

	Activate Dialog oDlg1 Centered


	If lContinua
		If U_GMTMKM01(cEmail/*cInEmail*/,/*cInOldEmail*/,/*cA1MSBLQL*/,.F./*lValdAlcada*/,.T./*lExibeAlerta*/,"")		
			stGrava()
		Endif
	Endif

	RestArea(aAreaOld)

Return

/*/{Protheus.doc} stValSA1
(long_description)
@author MarceloLauschner
@since 21/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stValSA1()
	Local		lRet := .F.

	DbSelectArea("SA1")
	DbSetOrder(1)
	If DbSeek(xFilial("SA1")+cCodCli+cLojCli)
		cEmail := SA1->A1_EMAIL
		oEmail:Refresh()
		cNomCli := SA1->A1_NOME
		oNomCli:Refresh()
		//IAGO 21/10/2016 Chamado(16148)
		cObs := SA1->A1_OBSCLI
		oObs:Refresh()
		nPotLits	:= SA1->A1_POTENC
		oPotLits:Refresh()
		nPotPneus	:= SA1->A1_POTENC2
		oPotPneus:Refresh()
		oSayPLits:cCaption := "Potencial Litros (" + cValToChar(SA1->A1_POTENC) +")" 
		oSayPLits:Refresh() 
		oSayPPneus:cCaption := "Potencial Pneus (" + cValToChar(SA1->A1_POTENC2) +")" 
		oSayPPneus:Refresh() 
		lRet := .T.
	Else
		MsgAlert("Código de Cliente/Loja inexistente",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" - Atenção!")
	EndIf

Return lRet


/*/{Protheus.doc} stGrava
(long_description)
@author MarceloLauschner
@since 21/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stGrava()
	
	Local	aCamp	:= {}
	Local	lAltCpo	:= .F. 
	
	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+cCodCli+cLojCli)
		
		Aadd(aCamp, { "A1_EMAIL","C", TamSX3("A1_EMAIL")[1],TamSX3("A1_EMAIL")[2],RetTitle("A1_EMAIL"), SA1->A1_EMAIL,cEmail } )
		Aadd(aCamp, { "A1_POTENC","N", TamSX3("A1_POTENC")[1],TamSX3("A1_POTENC")[2],RetTitle("A1_POTENC"), SA1->A1_POTENC,nPotLits } )
		Aadd(aCamp, { "A1_POTENC2","N", TamSX3("A1_POTENC2")[1],TamSX3("A1_POTENC2")[2],RetTitle("A1_POTENC2"), SA1->A1_POTENC2,nPotPneus } )
		Aadd(aCamp, { "A1_OBSCLI","C", TamSX3("A1_OBSCLI")[1],TamSX3("A1_OBSCLI")[2],RetTitle("A1_OBSCLI"), SA1->A1_OBSCLI,cObs } )
		
		Reclock("SA1",.F.)	
		SA1->A1_EMAIL 	:= cEmail
		SA1->A1_POTENC	:= nPotLits
		SA1->A1_POTENC2	:= nPotPneus
		SA1->A1_OBSCLI	:= cObs
		MSUnLock()
		sfAltera(aCamp,lAltCpo)
		MsgInfo("Entrada de Dados Realizada com sucesso!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" - Concluído")
		
	Else
		MsgAlert("Código de Cliente/Loja inexistente",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" - Atenção!")
	Endif

Return



Static Function sfAltera(aCamp,lAltCpo)

	Local 	lContinua 	:= .F.
	Local	cSendMail	:= "credito1@atrialub.com.br;cobranca1@atrialub.com.br;"
	Local	cProcess
	Local	cStatus
	Local 	oProcess
	Local	oHTML
	Local	x
	Local 	iw 

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
			ConOut("Não localizou arquivo  /workflow/ma030tok.htm")
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
		If aCamp[x,6] <> aCamp[x,7]
			AAdd((oHtml:ValByName("p.col")),(aCamp[x,1]))
			AAdd((oHtml:ValByName("p.camp")),(aCamp[x,5]))

			If aCamp[x,2] == "N"
				AAdd((oHtml:ValByName("p.orig")),Transform(aCamp[x,6],"@E 999,999,999.99"))
				AAdd((oHtml:ValByName("p.nov")),Transform(aCamp[x,7],"@E 999,999,999.99"))
			Else
				AAdd((oHtml:ValByName("p.orig")),aCamp[x,6])
				AAdd((oHtml:ValByName("p.nov")),aCamp[x,7])
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
		AAdd((oHtml:ValByName("p.orig")),Transform(SA1->A1_VALREMB,"@E 999,999,999.99"))
		AAdd((oHtml:ValByName("p.nov"))	,Transform(SA1->A1_LC,"@E 999,999,999.99")) 
	Endif

	oHtml:ValByName("DATA",DTOC(dDataBase))
	oHtml:ValByName("HORA",Time())

	oHtml:ValByName("USUARIO",SubStr(cUsuario,7,15))
	cSendMail	+= UsrRetMail(__cuserId)

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

Return .F.
