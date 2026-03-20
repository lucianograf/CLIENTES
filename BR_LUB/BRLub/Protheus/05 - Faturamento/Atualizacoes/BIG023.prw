#INCLUDE "topconn.ch"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} BIG023
(Cadastro de Autorizações de Devolução)
@author Rafael Meyer 
@since  data indefinida
@version 
@return Nil
@example
(examples)
@see (links_or_references)
/*/


/*/{Protheus.doc} BIG023
// Cadastro de Autorizações de Devolução 
@author Marcelo Alberto Lauschner
@since 09/03/2019
@version 1.0
@return 
@type User Function
/*/
User Function BIG023()

	Local	oDlg1
	Local	aItems 		:= {"Incluir","Alterar"}
	Local	cCombo 		:= ""
	Local	cCodCli		:= Space(6)
	Local	cLojCli		:= "01"
	Local 	cNumNfDev	:= Space(9)

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()


	DEFINE MSDIALOG oDlg1 FROM 000,000 TO 200,390 OF oMainWnd PIXEL TITLE OemToAnsi("Parametros para lançar devoluções")
	@ 02,10 TO 070,190  of oDlg1 pixel
	@ 11,018 Say "Selecione: " of oDlg1 pixel
	@ 10,100 COMBOBOX cCombo ITEMS aItems SIZE 50,09  of oDlg1 pixel
	@ 25,018 Say "Informe Cliente"  of oDlg1 pixel
	@ 24,100 Get cCodCli picture "@!" size 30,09 of oDlg1 pixel
	@ 39,018 Say "Informe Loja" of oDlg1 pixel
	@ 38,100 Get cLojCli picture "@!" size 10,09 of oDlg1 pixel
	@ 53,018 Say "Informe Nº NF Dev" of oDlg1 pixel
	@ 52,100 Get cNumNfDev picture "@E 999999999" size 25,09 of oDlg1 pixel
	@ 75,050 BUTTON "Continuar"  of oDlg1 pixel SIZE 40,15 ACTION (sfExec(cCombo,cCodCli,cLojCli,cNumNfDev),oDlg1:End())
	@ 75,100 BUTTON "Fechar"  of oDlg1 pixel SIZE 40,15 ACTION (oDlg1:End() )

	ACTIVATE MsDIALOG oDlg1 CENTERED

Return


/*/{Protheus.doc} Baixa
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExec(cCombo,cCodCli,cLojCli,cNumNfDev)

	Local	oInc,oAlt
	Local	cGravar		:= "1"
	Local	aTipMotivo 	:= {"1=Devolução total Nf Entrega","2=Devolução Parcial c/NF Cliente","3=Devolução Total c/NF Cliente","4=Devolução NF Avulsa","5=Devolução c/NF Entrada"}
	Local	cTipMotivo 	:= "1"
	Local 	cNumNfOrig	:= Space(9)
	Local 	cMotivo 	:= Space(300)

	Local 	cObsDevo	:= Space(100)
	Local	nVlrNfDev	:= 0.00	
	Local	cNomResp  	:= Space(40)

	Local	nCustDev	:= 0
	Local	nRecSZ3		:= 0


	If cCombo == "Incluir"


		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verificar Usuario para cadastrar devolução                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If RetCodUsr() $ "000130#"+GetMv("BF_AUTDEVO")
			cGravar  := "2"
		Endif

		If cGravar == "1"
			MsgAlert("Você não tem permissão para cadastrar/incluir autorizações de devolução!!",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
			Return(.F.)
		Endif

		DEFINE MSDIALOG oInc FROM 000,000 TO 300,530 OF oMainWnd PIXEL TITLE OemToAnsi("Inclusão de autorização de devolução")
		@ 02,08 TO 140,260 of oInc pixel
		@ 11,012 Say "Número NF Dev:" of oInc pixel
		@ 10,062 Get cNumNfDev picture "@E 999999999" size 20,09 of oInc pixel

		@ 11,120 Say "Valor NF Dev" of oInc pixel
		@ 10,170 Get nVlrNfDev  Picture "@E 999,999,999.99" size 60,09 of oInc pixel

		@ 24,012 Say "Cliente" of oInc pixel
		@ 23,062 get cCodCli Size 30,09 Valid ExistCpo("SA1",cCodCli+cLojCli)  of oInc pixel
		@ 23,095 Get cLojCli Valid ExistCpo("SA1",cCodCli+cLojCli) picture "@!" size 10,09 of oInc pixel

		@ 24,120 Say "NF origem Dev" of oInc pixel
		@ 23,170 Get cNumNfOrig Valid sfVldNfOrig(cCodCli,cLojCli,cNumNfDev,cNumNfOrig,@nCustDev) Picture "@E 999999999" size 40,09 of oInc pixel

		@ 34,012 Say "Motivo" of oInc pixel
		@ 43,012 Get cMotivo SIZE 240,09 of oInc pixel

		@ 66,012 Say "Tipo Devolução" of oInc pixel
		@ 65,062 Combobox cTipMotivo Items aTipMotivo SIZE 95,09 of oInc pixel

		@ 81,012 Say "Observação " of oInc pixel
		@ 80,062 Get cObsDevo size 190,09 of oInc pixel

		@ 94,012 Say "Responsável" of oInc pixel
		@ 93,062 Get cNomResp Size 70,09 of oInc pixel

		@ 106,012 Say "Informe o Custo" of oInc pixel
		@ 106,062 Get nCustDev Picture "@E 999,999.99" size 50,09 of oInc pixel

		@ 123,012 BUTTON "&Confirmar"  of oInc pixel size 40,13 Action (Iif(sfIncluir(cNumNfDev,cCodCli,cLojCli,cNumNfOrig,cMotivo,cTipMotivo,cNomResp,nVlrNfDev,cObsDevo,nCustDev),oInc:End(),Nil))
		@ 123,062 BUTTON "&Abortar"  of oInc pixel size 40,13 ACTION (oInc:End())

		Activate msDialog oInc Centered

		Return

	ElseIf cCombo == "Alterar"


		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verificar Usuario para cadastrar devolução                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		If RetCodUsr() $ "000130#"+GetMv("BF_AUTDEVO")
			cGravar  := "2"
		Endif

		If cGravar == "1"
			MsgAlert("Voce não tem permissao para cadastrar/incluir autorizações de devolução!!",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
			Return(.F.)
		Endif

		Dbselectarea("SZ3")
		dbsetorder(1)
		If Dbseek(xFilial("SZ3")+cCodCli+cLojCli+cNumNfDev)
			cNumNfDev 	:= SZ3->Z3_NFDEV
			nVlrNfDev	:= SZ3->Z3_VALOR
			cCodCli		:= SZ3->Z3_CLIENTE
			cLojCli 	:= SZ3->Z3_LOJA
			cNumNfOrig  := SZ3->Z3_NFORIG
			cMotivo		:= SZ3->Z3_MOTIVO
			cObsDevo	:= SZ3->Z3_CONTIPO
			cNomResp	:= SZ3->Z3_RESPDEV
			cTipMotivo 	:= SZ3->Z3_TIPODEV
			nCustDev	:= SZ3->Z3_CUSTFIN
			nRecSZ3		:= SZ3->(Recno())

			If !Empty(SZ3->Z3_BXDESCF)
				MsgAlert("Alteração não permitida por que esta autorização de devolução já teve a nota fiscal lançada pelo setor de Escrita Fiscal em " + DTOC(SZ3->Z3_BXDESCF) + " por " + SZ3->Z3_BXESCF + "!",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
				Return .F. 
			Endif
		Else
			MsgAlert("Dados informados não conferem!! Verifique Código/Loja ou se Número NF estão corretamente preenchidos. Favor completar dados!!.",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif

		DEFINE MSDIALOG oAlt FROM 000,000 TO 300,530 OF oMainWnd PIXEL TITLE OemToAnsi("Inclusão de autorização de devolução")
		@ 02,08 TO 140,260 of oAlt pixel
		@ 10,012 Say "Número NF Dev:" of oAlt pixel
		@ 10,062 Get cNumNfDev  Valid sfVldNfOrig(cCodCli,cLojCli,cNumNfDev,cNumNfOrig,@nCustDev,.T.) Picture "@E 999999999" size 20,09 of oAlt Pixel 

		@ 10,120 Say "Valor NF Dev" of oAlt pixel
		@ 10,170 Get nVlrNfDev  Picture "@E 999,999,999.99" size 60,09 of oAlt pixel

		@ 24,012 Say "Cliente" of oAlt pixel
		@ 23,062 get cCodCli size 30,09 of oAlt pixel When .F.
		@ 23,095 Get cLojCli Valid ExistCpo("SA1",cCodCli+cLojCli) picture "@!" size 10,09 of oAlt pixel  When .F.

		@ 24,120 Say "NF origem Dev" of oAlt pixel
		@ 23,170 Get cNumNfOrig Valid sfVldNfOrig(cCodCli,cLojCli,cNumNfDev,cNumNfOrig,@nCustDev,.T.) Picture "@E 999999999" size 40,09 of oAlt pixel

		@ 34,012 Say "Motivo" of oAlt pixel
		@ 43,012 Get cMotivo SIZE 240,09 of oAlt pixel

		@ 66,012 Say "Tipo Devolução" of oAlt pixel
		@ 65,062 Combobox cTipMotivo Items aTipMotivo SIZE 95,09 of oAlt pixel

		@ 81,012 Say "Observação tipo devolução" of oAlt pixel
		@ 80,062 Get cObsDevo size 120,09 of oAlt pixel

		@ 094,012 Say "Responsável" of oAlt pixel
		@ 093,062 Get cNomResp Size 50,09 of oAlt pixel

		@ 106,012 Say "Informe o Custo" of oAlt pixel
		@ 106,062 Get nCustDev Picture "@E 999,999.99" size 50,09 of oAlt pixel

		@ 123,012 BUTTON "Confirmar"  of oAlt pixel size 40,13 ACTION (IIf(sfAlterar(nRecSZ3,cCodCli,cLojCli,cNumNfDev,cNumNfOrig,cMotivo,cTipMotivo,cObsDevo,nVlrNfDev,cNomResp,nCustDev),oAlt:End(),Nil))
		@ 123,062 BUTTON "Abortar"  of oAlt pixel size 40,13 ACTION oAlt:End()
		Activate msDialog oAlt Centered

		Return
	Endif
Return


/*/{Protheus.doc} sfVldNfOrig
// Validação da digitação do campo do número da nota de origem
@author Marcelo Alberto Lauschner
@since 02/03/2019
@version 1.0
@return Logical, retorna se a nota é do cliente informado ou não 
@type Static Function
/*/
Static Function sfVldNfOrig(cCodCli,cLojCli,cNumNfDev,cNumNfOrig,nCustDev,lIsAltera)

	Local	lRet		:= .F. 
	Local	cQry 		:= ""
	Default	lIsAltera	:= .F.

	Dbselectarea("SZ3")
	Dbsetorder(1)
	If Dbseek(xFilial("SZ3")+cCodCli+cLojCli+cNumNfDev) .And. !lIsAltera
		lRet	:= .F. 
		MsgAlert("Autorização de Devolução já cadastrada com este número de nota de Origem para este cliente",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
	Else
		cQry := "SELECT F2_DOC,F2_SERIE,F2_EMISSAO,F2_VEND1,F2_CLIENTE,F2_LOJA,F2_TRANSP,F2_VALBRUT,F2_PBRUTO,F2_FRETE"
		cQry += "  FROM " + RetSqlName("SF2") + " F2 "
		cQry += " WHERE D_E_L_E_T_ =' ' " 
		cQry += "   AND F2_FILIAL = '" + xFilial("SF2") + "' "
		cQry += "   AND F2_CLIENTE = '" +cCodCli+ "' "
		cQry += "   AND F2_LOJA = '" + cLojCli + "' "
		cQry += "   AND F2_DOC = '"  + cNumNfOrig +  "' "

		TcQuery cQry New Alias "QF2" 

		If !Eof()
			lRet	:= .T. 

			nCustDev	:= U_BFFATM22(STOD(QF2->F2_EMISSAO)/*dInData*/,;
			QF2->F2_CLIENTE/*cInCodCli*/,;
			QF2->F2_LOJA/*cInLojCli*/,;
			QF2->F2_TRANSP/*cInTransp*/,;
			QF2->F2_VALBRUT/*nInVlrMerc*/,;
			QF2->F2_PBRUTO/*nInPeso*/,;
			QF2->F2_FRETE/*nInVlrFrete*/)

		Else
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
			{"Número de nota fiscal informada '" + cNumNfOrig + "' está incorreta!"},;
			5,;
			{"Verifique se o número da nota digitado corretamente com 6 ou 9 dígitos.",;
			"Confira o Código e Loja do cliente informados pois esta nota não existe para este cliente/loja."},;
			5) 
		Endif
		QF2->(DbCloseArea())
	Endif

Return lRet

/*/{Protheus.doc} sfIncluir
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return Logical
@example
(examples)
@see (links_or_references)
/*/
Static Function sfIncluir(cNumNfDev,cCodCli,cLojCli,cNumNfOrig,cMotivo,cTipMotivo,cNomResp,nVlrNfDev,cObsDevo,nCustDev)
	
	Local	nNumAut	:= 0
	Do Case
		Case Empty(cNumNfDev)
		MsgAlert("Número de nota fiscal não preenchido. Favor completar dados!!.",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
		Return(.F.)
		Case nVlrNfDev < 1
		MsgAlert("Valor da nota fiscal não preenchido. Favor completar dados!!.",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
		Return(.F.)
		Case Empty(cLojCli)
		MsgAlert("Loja do cliente não preenchido. Favor completar dados!!.",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
		Return(.F.)
		Case Empty(cMotivo)
		MsgAlert("Motivo da devolução não preenchido. Favor completar dados!!.",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
		Return(.F.)
		Case Empty(cObsDevo)
		MsgAlert("Observação sobre o tipo de devolução não preenchido. Favor completar dados!!.",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
		Return(.F.)
		Case Empty(cNomResp)
		MsgAlert("Responsável pela devolução não preenchido. Favor completar dados!!.",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
		Return(.F.)

	EndCase

	Dbselectarea("SZ3")
	Dbsetorder(1)
	If Dbseek(xFilial("SZ3")+cCodCli+cLojCli+cNumNfDev)
		MsgAlert("Autorização já cadastrada com este número de nota para este cliente",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))
		Return .F.
	Else
		nNumAut := GetMv("MV_NUMDEV")

		dbSelectArea("SZ3")

		RecLock("SZ3",.T.)
		SZ3->Z3_FILIAL	:= xFilial("SZ3")
		SZ3->Z3_NFDEV	:= cNumNfDev
		SZ3->Z3_CLIENTE := cCodCli
		SZ3->Z3_LOJA	:= cLojCli
		SZ3->Z3_NFORIG  := cNumNfOrig
		SZ3->Z3_MOTIVO	:= cMotivo
		SZ3->Z3_TIPODEV	:= cTipMotivo
		SZ3->Z3_CONTIPO := cObsDevo
		SZ3->Z3_VALOR	:= nVlrNfDev
		SZ3->Z3_RESPDEV := cNomResp
		SZ3->Z3_INCTMK  := Substr(UsrRetName(RetCodUsr()),1,15)
		SZ3->Z3_INCDATA := dDatabase
		SZ3->Z3_INCHORA := Time()
		SZ3->Z3_CUSTFIN := nCustDev
		SZ3->Z3_NUMSEQ  := Strzero(nNumAut,6)
		MSUnLock()



		nNumaut := nNumaut + 1

		PutMv("MV_NUMDEV",nNumAut)

		sfSendWF(.F.)

		MsgInfo("WF ENVIADO - Número da Autorização: "+Strzero(nNumAut,6)+ "!!",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))

	Endif
Return .T. 

/*/{Protheus.doc} Alterar
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return Logical 
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAlterar(nRecSZ3,cCodCli,cLojCli,cNumNfDev,cNumNfOrig,cMotivo,cTipMotivo,cObsDevo,nVlrNfDev,cNomResp,nCustDev)

	Do Case
		Case nVlrNfDev < 1
		MsgAlert("Valor da nota fiscal não preenchido. Favor completar dados!!.","Atencao!")
		Return .F.
		Case Empty(cMotivo)
		MsgAlert("Motivo da devolução não preenchido. Favor completar dados!!.","Atencao!")
		Return .F.
		Case Empty(cObsDevo)
		MsgAlert("Observação sobre o tipo de devolução não preenchido. Favor completar dados!!.","Atencao!")
		Return .F.
		Case Empty(cNomResp)
		MsgAlert("Responsável pela devolução não preenchido. Favor completar dados!!.","Atencao!")
		Return .F.

	EndCase

	Dbselectarea("SZ3")
	DbGoto(nRecSZ3)
	
	RecLock("SZ3",.F.)
	SZ3->Z3_NFDEV	:= cNumNfDev
	SZ3->Z3_CLIENTE := cCodCli
	SZ3->Z3_LOJA	:= cLojCli
	SZ3->Z3_NFORIG  := cNumNfOrig
	SZ3->Z3_MOTIVO	:= cMotivo
	SZ3->Z3_TIPODEV	:= cTipMotivo
	SZ3->Z3_CONTIPO := cObsDevo
	SZ3->Z3_VALOR	:= nVlrNfDev
	SZ3->Z3_RESPDEV := cNomResp
	SZ3->Z3_CUSTFIN := nCustDev
	MSUnLock()

	MsgAlert("Dados Alterados com Sucesso. Novo workflow de inclusão de autorização de devolução enviado!!","Informacao","INFO")

	sfSendWF(.T.)

	MsgInfo("WF ENVIADO - Número da Autorização: "+  SZ3->Z3_NUMSEQ + "!!",FunName() + "."+ProcName(0) + "." + Alltrim(Str(ProcLine(0))))

Return .T. 


/*/{Protheus.doc} sfSendWF
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return Nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSendWF(lAltera)

	Local	cProcess
	Local	cStatus
	Local 	oProcess
	Local	oHtml
	Local	cDescTpDev	:= ""
	Local 	iW 
	Default	lAltera		:= .F. 

	// Cria um novo processo...
	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Envio de autorização de devolução"))
	//Abre o HTML criado
	If IsSrvUnix()
		If File("/workflow/aut_dev.htm")
			oProcess:NewTask("Gerando HTML","/workflow/aut_dev.htm")
		Else
			ConOut("Não localizou arquivo  /workflow/aut_dev.htm")
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\aut_dev.htm")
	Endif

	oProcess:cSubject :=  Iif(lAltera,"Autorização Devolução Alterada/Cliente ","Autorização Devolução/Cliente:") + SZ3->Z3_CLIENTE + "/"+SZ3->Z3_LOJA+" NF Dev: "+SZ3->Z3_NFDEV
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML

	If SZ3->Z3_TIPODEV == "1"
		cDescTpDev :="Devolução total Nf Entrega"
	Elseif SZ3->Z3_TIPODEV == "2"
		cDescTpDev := "Devolução Parcial c/NF Cliente"
	Elseif 	SZ3->Z3_TIPODEV == "3"
		cDescTpDev := "Devolução Total c/NF Cliente"
	Elseif SZ3->Z3_TIPODEV == "4"
		cDescTpDev := "Devolução NF Avulsa"
	Else
		cDescTpDev := "Devolução c/NF Entrada"
	Endif

	dbSelectarea("SA1")
	Dbsetorder(1)
	dbseek(xFilial("SA1")+SZ3->Z3_CLIENTE+SZ3->Z3_LOJA)

	dbSelectarea("SA4")
	Dbsetorder(1)
	dbseek(xFilial("SA4")+SA1->A1_TRANSP)



	oHtml:ValByName("empresa"	, AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("tmkdev"	, SZ3->Z3_INCTMK)
	oHtml:ValByName("datadev"	, SZ3->Z3_INCDATA)
	oHtml:ValByName("horadev"	, SZ3->Z3_INCHORA)
	oHtml:ValByName("nfdev"		, SZ3->Z3_NFDEV )
	oHtml:ValByName("vlrnf"		, Transform(SZ3->Z3_VALOR,"@E 999,999,999.99"))
	oHtml:ValByName("nfodev"	, SZ3->Z3_NFORIG)
	oHtml:ValByName("cliedev"	, SZ3->Z3_CLIENTE+"/"+SZ3->Z3_LOJA+" - " + SA1->A1_NOME)
	oHtml:ValByName("mundev"	, SA1->A1_END+"Bairro:"+SA1->A1_BAIRRO+"Cidade:"+SA1->A1_MUN)
	oHtml:ValByName("transpdev"	, SA4->A4_COD+" / "+SA4->A4_NREDUZ)
	oHtml:ValByName("custdev"	, Transform(SZ3->Z3_CUSTFIN,"@E 999,999.99"))
	oHtml:ValByName("motdev"	, Substr(SZ3->Z3_MOTIVO,1,80))
	oHtml:ValByName("motdev1"	, Substr(SZ3->Z3_MOTIVO,81,90))
	oHtml:ValByName("motdev2"	, Substr(SZ3->Z3_MOTIVO,170,80))
	oHtml:ValByName("tipdev"	, SZ3->Z3_TIPODEV + "-" + cDescTpDev)
	oHtml:ValByName("contipodev", SZ3->Z3_CONTIPO)
	oHtml:ValByName("respdev"	, SZ3->Z3_RESPDEV)
	oHtml:ValByName("incaltdev"	, "Autorização Devolução Nº: " + SZ3->Z3_NUMSEQ +  Iif(lAltera," Alterada por: "," Incluída por: ") + UsrRetName(RetCodUsr()))
	oHtml:ValByName("dtaltdev"	, dDatabase)
	oHtml:ValByName("horaaltdev", Time())

	dbSelectarea("SA3")
	Dbsetorder(1)
	dbseek(xFilial("SA3")+SA1->A1_VEND)


	cEmail := U_BFFATM15(AllTrim(GetMv("MV_LIBDEV"))+";"+ SA3->A3_EMTMK,"BIG023")
	// Trata a limpeza dos e-mails repetidos 
	cRecebe := IIf(!Empty(cEmail),cEmail+";","")	
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

	If !Empty(UsrRetMail(RetCodUsr()))
		oProcess:cCc := UsrRetMail(RetCodUsr())
	Endif
	
	//oProcess:cTo	:= "marcelolauschner@hotmail.com"

	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return
