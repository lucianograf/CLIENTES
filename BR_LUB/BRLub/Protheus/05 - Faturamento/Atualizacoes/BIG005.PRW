#INCLUDE "totvs.CH"
#INCLUDE "topconn.ch"
#include "ap5mail.ch"
#INCLUDE "rwmake.ch"
#DEFINE MAXPASSO 4


/*/{Protheus.doc} BIG005
(Enviar workflow da pend๋ncia faturamento  )

@author MarceloLauschner
@since 05/01/2004
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function BIG005(lIsExterno,lInAuto,cInIdUser,cInNumPed,lInIsAprovador)

	Private 	lIsAuto		:= .F.
	Private	cAutNumPed		:= ""
	Private	lExistPed		:= .F.
	Private	lIsAprovador	:= .F.
	Default 	cInIdUser		:= "000000"
	Default	lIsExterno		:= .F.
	Default 	lInAuto		:= .F.
	Default	cInNumPed		:= ""
	Default	lInIsAprovador := .F.

	// Atribui variแvel que identifica que a rotina estแ no automแtico
	lIsAuto		:= lInAuto
	lIsAprovador	:= lInIsAprovador
	If !lIsAuto
		sfExec(lIsExterno)
	Else
		If !Empty(cInIdUser)
			__cUserId	:= cInIdUser
		Endif
		cAutNumPed		:= cInNumPed
		sfExec(lIsExterno)
	Endif


Return

/*/{Protheus.doc} sfExec
(long_description)
@author MarceloLauschner
@since 16/10/2014
@version 1.0
@param lIsExterno, ${param_type}, (Descri็ใo do parโmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExec(lIsExterno)

	Local 	aSize 			:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Local   nAltura 		:= aSize[6]/2.3
	Local	kL
	Local	lSendWF			:= .F.
	Private cMarca
	Private oSC9
	Private oSN
	Private cSN 			:= "Sim"
	Private cBlqCrd		:= "Tudo"
	Private oBlqCrd
	Private aSN 			:= {"Tudo","Blq Credito","Pendente Financeiro","Pendente Comercial","Antecipado","Rejeitado","Liberado","Saldo Pedido","Nใo Liberado","Eliminar Residuos","Alcada"}
	Private aEquip 		:= {"Tudo","BigForta","Lust"}
	Private oDlg5
	Private nValMax		:= 0
	Private cVendPesq		:= Space(TamSX3("A3_COD")[1])
	Private cOperVend		:= Space(TamSX3("A3_OPERADO")[1])
	Private oSumBlEst,oSumBlCrd,oSumBlFin,oSumValLib,oSumValPed
	Private nSumBlEst 	:= nSumBlCrd := nSumBlFin := nSumValLib := nSumValPed := 0
	Private dDataprg		:= dDataBase
	Private nOpcLoc		:= 0
	Private aSC9
	Private aDadEntrega	:= {"2x",CTOD(""),"32","12"}
	Private oDataRota,oStsRota,oDiasFat



	// Executa grava็ใo do Log de Uso da rotina
	U_BFCFGM01()

	oVermelho	:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	oAzul 		:= LoaDbitmap( GetResources(), "BR_AZUL" )
	oAmarelo	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	oCinza		:= LoaDbitmap( GetResources(), "BR_CINZA" )
	oPink		:= LoaDbitmap( GetResources(), "BR_PINK" )
	oLaranja	:= LoaDbitmap( GetResources(), "BR_LARANJA" )
	oPreto		:= LoaDbitmap( GetResources(), "BR_PRETO" )
	oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	aCampos   	:= {}
	cCadastro 	:= OemToAnsi("Workflow Envio pend๊ncia pedidos para faturamento")
	aSC9		:= {}
	cSc9		:= ""
	cVarPesq	:= space(06)
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Cria arquivo de trabalho                                            ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู




	//DEFINE MSDIALOG oDlg FROM 000,000 TO 600,800 OF oMainWnd PIXEL TITLE cCadastro
	DEFINE MSDIALOG oDlg5 TITLE OemToAnsi(cCadastro) FROM 001,001 TO aSize[6] , aSize[5] PIXEL

	oPanel1 := TPanel():New(0,0,'',oDlg5, oDlg5:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	@ 004,010 Say "Visualiza bloqueados ? " of oPanel1 Pixel
	@ 003,070 MsCombobox oBlqEst Var cSN Items {"Sim","Nao"}  Size 30,10 of oPanel1 Pixel
	oBlqEst:bChange	:=  {||  stRefresh(),oSC9:SetFocus() }

	@ 004,250 Say "Pedidos At้ Valor de R$" of oPanel1 Pixel
	@ 004,320 Msget nValMax Valid (stRefresh(),oSC9:SetFocus()) Picture "@E 9,999.99" of oPanel1 Pixel Size 50,10


	@ 004,375 Say "Data Programada" of oPanel1 Pixel
	@ 004,435 MsGet dDataPrg Valid (stRefresh(),oSC9:SetFocus()) of oPanel1 Pixel

	@ 004,120 Say "Filtro de pedidos" of oPanel1 Pixel
	@ 004,175 MsCombobox oBlqCrd Var cBlqCrd Items aSN   of oPanel1 Pixel Size 60,10
	oBlqCrd:bChange	:=  {||  stRefresh(),oSC9:SetFocus() }


	@ 015,010 Button "Espelho "	of oPanel1 pixel SIZE 45,10 ACTION (Processa({|| Espelho(aSC9[oSc9:nAt,3]) },"Gerando espelho"))

	If !lIsExterno .And. (RetCodUsr() $ GetMv("GM_BIG005E") .OR. RetCodUsr() $ GetMv("GM_BIG005R"))
		//Adicionado para que as TMKs nใo tenham acesso a esses bot๕es.
		@ 015,060 BUTTON "Elimina Resํduo"	of oPanel1 pixel SIZE 45,10 Action sfResAll()
		//075         ,010         ,nAltura,aSize[5]/2.04
		@ 015,110 Button "Adiciona Observa็ใo" of oPanel1 Pixel Size 60,10 Action sfTmkObs()
		//		@ 015,175 Button "Libera Al็ada" of oPanel1 Pixel Size 60,10 Action sfLibAlcada()
	EndIf

	@ 015,250 Say "Somente Pedidos Vendedor" of oPanel1 Pixel
	@ 015,320 Msget cVendPesq F3 "SA3" Valid stRefresh() Picture "@!" of oPanel1 Pixel Size 30,10

	@ 015,375 SAY "Pesquisar Pedido" of oPanel1 pixel
	@ 015,435 MSGET cVarPesq Valid BIG005PESQ() Size 35,10 of oPanel1 pixel

	@ 026,250 Say "Asssessora" of oPanel1 Pixel
	@ 026,320 Msget cOperVend F3 "SU7" Valid stRefresh() Picture "@!" of oPanel1 Pixel Size 30,10

	Processa({|| CriaArq(.T.) },"Aguarde criando arquivo de trabalho....")

	@ 039,005 LISTBOX oSC9 VAR cSc9 ;
		Fields HEADER " ",;    //1
	" ",;                     //2
	"Pedido",;                   //3
	"Emissใo",;     		// 4
	"Nome Cliente",;        // 5
	"Dt. Fat.",;            // 6
	"Credito",;             // 7
	"Estoque",;             //8
	"Liberado",;            //9
	"Vlr Pedido",;          //10
	"Vlr Total Pedido",;    //11
	"Vlr Blq Fin",;         //12
	"Mensagem Interna", ;   //13
	"Mensagens Controle",;  //14
	"Vendedor",;            //15
	"Madrinha",;            //16
	"Cond.Pagto",;           //17
	"Cidade",;               //18
	"Transportadora";       //19
	SIZE aSize[5]/2.04,nAltura-48;
		ON DBLCLICK (Processa({||InverteSC9()},"Analisando..")) OF oDlg5 PIXEL
	oSC9:nFreeze := 2
	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{BIG005LEG(),;
		Iif(aSC9[oSC9:nAT,02],oMarked,oNoMarked),;
		aSC9[oSC9:nAT,03],;
		aSC9[oSC9:nAT,04],;
		aSC9[oSC9:nAT,05],;
		aSC9[oSC9:nAT,06],;
		aSC9[oSC9:nAT,07],;
		aSC9[oSC9:nAT,08],;
		aSC9[oSC9:nAT,09],;
		aSC9[oSC9:nAT,10],;
		aSC9[oSC9:nAT,11],;
		aSC9[oSC9:nAT,12],;
		aSC9[oSC9:nAT,13],;
		aSC9[oSC9:nAT,14],;
		aSC9[oSC9:nAT,15],;
		aSC9[oSC9:nAT,16],;
		aSC9[oSC9:nAT,17],;
		aSC9[oSC9:nAT,18],;
		aSC9[oSC9:nAT,19]}}
	oSC9:Refresh()
	oSC9:Align := CONTROL_ALIGN_ALLCLIENT

	oSC9:bChange	:=  {||  sfChangLin() }

	oPanel2 := TPanel():New(0,0,'',oDlg5, oDlg5:oFont, .T., .T.,, ,200,65,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_BOTTOM


	@ 05,010 Say "R$ Bloq.Credito ->" of oPanel2 Pixel
	@ 07,040 Msget oSumBlCrd Var nSumBlCrd Picture "@E 999,999,999.99" Size 50,10 ReadOnly NoBorder of oPanel2 Pixel
	@ 05,095 Say "R$ Bloq.Estoque ->" of oPanel2 Pixel
	@ 07,125 Msget oSumBlEst Var nSumBlEst Picture "@E 999,999,999.99" Size 50,10 ReadOnly NoBorder of oPanel2 Pixel
	@ 05,180 Say "R$ Liberado ->" of oPanel2 Pixel
	@ 07,210 Msget oSumValLib Var nSumValLib Picture "@E 999,999,999.99" Size 50,10 ReadOnly NoBorder of oPanel2 Pixel
	@ 05,265 Say "R$ Pendente ->" of oPanel2 Pixel
	@ 07,295 Msget oSumValPed Var nSumValPed Picture "@E 999,999,999.99" Size 50,10 ReadOnly NoBorder of oPanel2 Pixel
	@ 05,350 Say "R$ Antecipado ->" of oPanel2 Pixel
	@ 07,380 Msget oSumBlFin Var nSumBlFin Picture "@E 999,999,999.99" Size 50,10 ReadOnly NoBorder of oPanel2 Pixel

	//oSumBlEst,oSumBlCrd,oSumBlFin,oSumValLib,oSumValPed
	//@ nMetade+05, 0240 MsGet oTotalXml Var nTotalXml Picture "@E 999,999,999.99" Size 50,10 READONLY COLOR CLR_BLUE noborder of oDlg Pixel

	//nSumBlEst := nSumBlCrd := nSumBlFin := nSumValLib := nSumValPed := 0
	@ 20,010 BITMAP oBmp RESNAME "BR_VERDE" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 20,020 SAY "- Totalmente Liberado" of oPanel2 pixel
	@ 35,010 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 35,020 SAY "- Bloqueado Est/Fin" of oPanel2 pixel
	@ 20,080 BITMAP oBmp RESNAME "BR_AMARELO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 20,090 SAY "- Saldo Pedido" of oPanel2 pixel
	@ 35,080 BITMAP oBmp RESNAME "BR_AZUL" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 35,090 SAY "- Novo c/Bloq Estoque" of oPanel2 pixel
	@ 20,150 BITMAP oBmp RESNAME "BR_CINZA" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 20,160 SAY "- Cr้dito Rejeitado" of oPanel2 pixel
	@ 35,150 BITMAP oBmp RESNAME "BR_PINK" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 35,160 SAY "- Pgto Antecipado" of oPanel2 pixel
	@ 35,210 BITMAP oBmp RESNAME "BR_LARANJA" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 35,220 SAY "- Pendente Financeiro" of oPanel2 pixel
	@ 20,210 BITMAP oBmp RESNAME "BR_PRETO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 20,220 SAY "- Pendente Comercial" of oPanel2 pixel



	If RetCodUsr() $ GetMv("BF_USRSERA")
		@  50,010 BUTTON "Analise Crd.Cliente" of oPanel2 pixel SIZE 60,10 ACTION (stMat450a())
		@  50,075 BUTTON "Libera Pedido" of oPanel2 pixel SIZE 60,10 ACTION (sfMat456())
		@  50,140 BUTTON "Bloq Fin"	of oPanel2 pixel SIZE 60,10 ACTION (Processa({|| BIG005B() },"Bloq Financeiro"))

		If RetCodUsr() $ GetMv("GM_BIG005E")
			@ 027,010 BUTTON "Libera Estoque/Pedido" of oPanel1 pixel SIZE 60,10 ACTION (sfMat455())
			@ 027,075 BUTTON "Bloq. A liberar" of oPanel1 pixel SIZE 60,10 ACTION (U_BIG036())
		Endif
		If RetCodUsr() $ GetMv("GM_BIG005R") .OR. RetCodUsr() $ GetMv("GM_BIG005E")
			@ 027,140 BUTTON "Altera Cabe็alho Pedido"	of oPanel1 pixel SIZE 60,10 ACTION (U_BIG017(),stRefresh())
		EndIf
		@ 015,175 Button "Libera Al็ada" of oPanel1 Pixel Size 60,10 Action sfLibAlcada()

	Else
		If RetCodUsr() $ GetMv("GM_BIG005E")
			@  26,010 BUTTON "Libera Estoque/Pedido" of oPanel1 pixel SIZE 60,10 ACTION (sfMat455())
			@  26,075 BUTTON "Bloq. A liberar" of oPanel1 pixel SIZE 60,10 ACTION (U_BIG036())
		Endif
		If RetCodUsr() $ GetMv("GM_BIG005R") .OR. RetCodUsr() $ GetMv("GM_BIG005E")
			@  26,140 BUTTON "Altera Cabe็alho Pedido"	of oPanel1 pixel SIZE 60,10 ACTION (U_BIG017(),stRefresh())
		EndIf
	Endif
	If RetCodUsr() $ GetMv("BF_USRSERA")
		@  50,205 Button "Altera Cliente" Of oPanel2 Pixel Size 60,10 Action sfAuxSA1(.T.)
	Else
		@  50,205 Button "Visual.Cliente" Of oPanel2 Pixel Size 60,10 Action sfAuxSA1(.F.)
	Endif
	If RetCodUsr() $ GetMv("GM_BIG005E")
		@  50,270 BUTTON "Envia/Atualiza" of oPanel2 pixel SIZE 60,10 ACTION (Processa({|| BIG005A(),stRefresh() },"Enviando E-Mail"))
	Endif
	@  50,335 BUTTON "Cancela" 		of oPanel2 pixel SIZE 60,10 ACTION (oDlg5:End() )

	//{cStsRota,dData,cDiasFat,cPrzEnt}
	@  25,280 Say "Pr๓ximo Faturamento: " color 180 of oPanel2 pixel
	@  25,335 MSGET oDataRota Var aDadEntrega[2] color 190 of oPanel2 pixel When .F.
	@  25,385 MSGET oStsRota Var (aDadEntrega[3]+" - " + aDadEntrega[1]) Size 55,10 color 183 of oPanel2 pixel  When .F.
	@  25,450 MSGET oDiasFat Var aDadEntrega[4] Size 20,10 color 183 of oPanel2 pixel When .F.

	If lIsAuto .And. lExistPed
		// Tento marcar todos os pedidos
		For kL	:= 1 To Len(aSC9)
			oSC9:nAT	:= kL
			InverteSC9()
			// Se marcou, valida variแvel
			If aSC9[oSc9:nAt,2]
				lSendWF	:= .T.
			Endif
		Next
		If lSendWF
			BIG005A()
		Endif
	Endif


	ACTIVATE MSDIALOG oDlg5 Centered On Init (sfStartInit(oDlg5)) //ON INIT IIF(nOpcao == 2 ,Processa({|| CriaTree(oTree,nOpcao,aArraySetor,aArrayVeic,cCarga) },"Processando Monta Carga"),nil)

Return


/*/{Protheus.doc} sfStartIni
(long_description)
@author MarceloLauschner
@since 16/10/2014
@version 1.0
@param lIsAuto, ${param_type}, (Descri็ใo do parโmetro)
@param oDlg5, objeto, (Descri็ใo do parโmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfStartIni(oDlg5)

	If lIsAuto
		oDlg5:End()
	Endif

Return


/*/{Protheus.doc} sfChangLin
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfChangLin()

	Local	cPed    := aSC9[oSc9:nAt,3]

	Dbselectarea("SC5")
	Dbsetorder(1)
	If Dbseek(xFilial("SC5")+cPed)

		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
			aDadEntrega	:= sfCalcRota(SC5->C5_TRANSP,SA1->A1_CEP,SA1->A1_ROTA)
		Endif

		oDiasFat:Refresh()
		oStsRota:Refresh()
		oDataRota:Refresh()
	Endif

Return


/*/{Protheus.doc} stMat450a
(Analise de credito de clientes   )
@author MarceloLauschner
@since 18/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stMat450a()

	Local aAreaOld	:= GetArea()

	MATA450A()

	stRefresh()

	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfAuxSA1
(Auxilia Cadastro de Clientes  )
@author MarceloLauschner
@since 18/06/2012
@version 1.0
@param lAlteraCli, ${param_type}, (Descri็ใo do parโmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAuxSA1(lAlteraCli)

	Local aAreaOld := GetArea()
	Local cCadAux	:= cCadastro

	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+aSC9[oSc9:nAt,3])

	DbSelectarea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

	cCadastro := "[SA1] Visualiza็ใo de Cadastro de Clientes"
	//AxVisual( "SA1", SA1->(Recno()), 2 )
	If lAlteraCli
		cCadastro := "[SA1] Altera Cadastro de Clientes"
		PRIVATE aRotina
		Private aRotAuto := Nil
		Private ALTERA 	:= .T.
		Private INCLUI	:= .F.
		A030Altera("SA1",SA1->(RecNo()),4)
	Else
		A030Visual("SA1",SA1->(RecNo()),1)
	Endif
	cCadastro := cCadAux

	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfMat456
(Libera็ใo de Estoque  )
@author MarceloLauschner
@since 18/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMat456()

	Local		aAreaOld		:= GetArea()
	Local		lExistBlq		:= .F.
	// Declaro o filtro adicional do ponto de entrada M456FIL
	Private 	cFilNumSC9 	:= aSC9[oSc9:nAt,3]
	Private	cFilCliSC9

	DbSelectArea("SC9")
	DbSetOrder(1)
	DbSeek(xFilial("SC9")+cFilNumSC9)
	cFilCliSC9	:= SC9->C9_CLIENTE
	While !Eof() .And. SC9->C9_FILIAL == xFilial("SC9") .And. SC9->C9_PEDIDO == cFilNumSC9
		If SC9->C9_BLCRED == "09"
			lExistBlq	:= .T.
			Exit
		Endif
		DbSelectArea("SC9")
		DbSkip()
	Enddo

	If lExistBlq
		sfLibMt450()
		stRefresh()
	Else
		DbSelectArea("SC9")
		DbSetOrder(1)
		DbSeek(xFilial("SC9")+cFilNumSC9)
		While !Eof() .And. SC9->C9_FILIAL == xFilial("SC9") .And. SC9->C9_PEDIDO == cFilNumSC9
			If !Empty(SC9->C9_BLCRED)
				Exit
			Endif
			DbSelectArea("SC9")
			DbSkip()
		Enddo
		sfLibMt450(.T.)
		stRefresh()
		//MsgInfo("Este pedido nใo tem bloqueio por Pend๊ncia Financeira ou Comercial. Se estiver Bloqueado no Cr้dito, use a rotina de 'Analise de Cr้dito por cliente'","A T E N ว ร O!!")
	Endif


	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfMat455
(Atalho para liberar estoque    )
@author MarceloLauschner
@since 18/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMat455()

	Local	aAreaOld	:= GetArea()

	// Declaro o filtro adicional do ponto de entrada M456FIL
	Private cFilNumSC9 	:= aSC9[oSc9:nAt,3]
	Private	cFilCliSC9

	If cBlqCrd == "Nใo Liberado"

		Mata440()

	Else

		DbSelectArea("SC9")
		DbSetOrder(1)
		DbSeek(xFilial("SC9")+cFilNumSC9)

		cFilCliSC9	:= SC9->C9_CLIENTE

		U_GravaSX1("MTA455","01",2)

		U_GravaSX1("LIBAT2","01",SC9->C9_PEDIDO)
		U_GravaSX1("LIBAT2","02",SC9->C9_PEDIDO)
		U_GravaSX1("LIBAT2","03",SC9->C9_CLIENTE)
		U_GravaSX1("LIBAT2","04",SC9->C9_CLIENTE)


		// Executo a chamado do programa de libera็ใo manual de cr้dito
		MATA455()
	Endif

	stRefresh()

	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfLibAlcada
(Chamada para libera็ใo de Al็ada diretamente na rotina)

@author MarceloLauschner
@since 02/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfLibAlcada()

	Local		aAreaOld		:= GetArea()
	Local		iT
	Private 	cFilNumSC9 	:= aSC9[oSc9:nAt,3]
	Private	cFilCliSC9

	If cBlqCrd == "Alcada" .Or. cBlqCrd == "Nใo Liberado"
		For iT:= 1 To Len(aSC9)
			If aSC9[iT,2]
				U_FOR007(aSC9[iT,3])
				// Declaro o filtro adicional do ponto de entrada M456FIL
				cFilNumSC9	:= aSC9[iT,3]
				DbSelectArea("SC5")
				DbSetOrder(1)
				DbSeek(xFilial("SC5")+cFilNumSC9)

				cFilCliSC9	:= SC5->C5_CLIENTE
				// Ao liberar a al็ada do pedido jแ chama a libera็ใo do mesmo
				Mata440()
			Endif
		Next
		stRefresh()
	Else
		MsgAlert("Esta op็ใo s๓ ้ permitida quando selecionado 'Nใo Liberado' no filtro de pedidos","Op็ใo nใo invแlida!")
	Endif


	RestArea(aAreaOld)

Return


/*/{Protheus.doc} stRefresh
(Atualiza็ใo do listbox  )
@author MarceloLauschner
@since 18/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stRefresh()

	Local aAreaOld	:= GetArea()

	aSC9	:= {}

	Processa({|| CriaArq() },"Atualizando dados...")

	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{BIG005LEG(),;
		Iif(aSC9[oSC9:nAT,02],oMarked,oNoMarked),;
		aSC9[oSC9:nAT,03],;
		aSC9[oSC9:nAT,04],;
		aSC9[oSC9:nAT,05],;
		aSC9[oSC9:nAT,06],;
		aSC9[oSC9:nAT,07],;
		aSC9[oSC9:nAT,08],;
		aSC9[oSC9:nAT,09],;
		aSC9[oSC9:nAT,10],;
		aSC9[oSC9:nAT,11],;
		aSC9[oSC9:nAT,12],;
		aSC9[oSC9:nAT,13],;
		aSC9[oSC9:nAT,14],;
		aSC9[oSC9:nAT,15],;
		aSC9[oSC9:nAT,16],;
		aSC9[oSC9:nAT,17],;
		aSC9[oSC9:nAT,18],;
		aSC9[oSC9:nAT,19]}}
	oSC9:Refresh()
	oSumBlEst:Refresh()
	oSumBlEst:Refresh()
	oSumBlCrd:Refresh()
	oSumBlFin:Refresh()
	oSumValLib:Refresh()
	oSumValPed:Refresh()

	RestArea(aAreaOld)

Return

/*/{Protheus.doc} BIG005A
(Envio de Email dos pedidos selecionados   )
@author MarceloLauschner
@since 18/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function BIG005A()
	Local	mr
	Local	lSendFrimazo	:= cEmpAnt == "05"
	Local	cQrf,cQry,cQre
	Local	oHtml
	Local	oProcess
	Local	cProcess
	Local	cStatus

	If cBlqCrd == "Nใo Liberado" .Or. cBlqCrd == "Eliminar Residuos" .Or. cBlqCrd == "Alcada"
		MsgAlert("Nใo hแ envio de pedidos!!","Nใo Liberado")
		Return
	Endif

	// Cria um novo processo...
	cProcess := "100000"
	cStatus  := "100000"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Confirmacao de envio pend๊ncia"))
	//Abre o HTML criado
	If IsSrvUnix()
		If File("/workflow/liberacao_pendencia.htm")
			oProcess:NewTask("Gerando HTML","/workflow/liberacao_pendencia.htm")
		Else
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Nใo localizou arquivo  /workflow/liberacao_pendencia.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\liberacao_pendencia.htm")
	Endif
	oProcess:cSubject := "Pend๊ncia para separa็ใo " + cEmpAnt + "/" + cFilAnt + "-" + Capital(SM0->M0_NOME)

	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML
	oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
	oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
	oHtml:ValByName("INSC","Inscri็ใo Estadual: " + SM0->M0_INSC)

	nTotal := 0
	cPendencia 	:= "Pend๊ncia para separa็ใo " + cEmpAnt + "/" + cFilAnt + "-" + Capital(SM0->M0_NOME)
	dDataenvi  	:= 0
	nTotpeso 	:= 0
	cPedgr  	:= space(6)

	//While !Eof()
	for mr:= 1 to len(aSC9)

		If aSC9[mr,2]
			cHora := Time()
			IncProc("Processando itens do Pedido...")

			SC9->(dbSeek(xFilial("SC9")+aSC9[mr,3]))

			cQrf := ""
			cQrf += "SELECT C9_ITEM, C9_PEDIDO, C9_SEQUEN, C9_PRODUTO,C9_LOCAL "
			cQrf += "  FROM " +RetSqlName("SC9") + "  "
			cQrf += " WHERE D_E_L_E_T_ = ' ' "
			cQrf += "   AND C9_NFISCAL = '      '  "
			If !lSendFrimazo
				cQrf += "   AND C9_BLEST = ' ' "
			Endif
			cQrf += "   AND C9_BLCRED = ' ' "
			cQrf += "   AND C9_FLGENVI NOT IN ('E','I') "
			cQrf += "   AND C9_PEDIDO = '" +aSC9[mr,3]+ "' "
			cQrf += "   AND C9_FILIAL = '" + xFilial("SC9") +"' "

			TCQUERY cQrf NEW ALIAS "QRF"

			While !eof()

				// Tratativa adicionada em 21/06/2012 por Marcelo Lauschner para distinguir local da pend๊ncia para separar mercadoria.
				//If cEmpAnt+cFilAnt $ "0204"
				//	If QRF->C9_LOCAL == "01"
				//		cPendencia := "SEPARAวรO DO ARMAZษM '01-OL LOGISTICA' "
				//	ElseIf QRF->C9_LOCAL == "02"
				//		cPendencia := "SEPARAวรO DO ARMAZษM '02-AGROLOG' "
				//	Endif
				//Endif
				// Adicionada condi็ใo em 03/07/2013 para considerar mercadorias separadas na BF-RS
				If cEmpAnt+cFilAnt $ "02XX"
					If QRF->C9_LOCAL == "01"
						cPendencia := "SEPARAวรO DO ARMAZษM '01-ATRIA - TEXACO' "
					ElseIf QRF->C9_LOCAL == "02"
						cPendencia := "SEPARAวรO DO ARMAZษM '02-FLEXSIL - MOTUL' "
					Endif
				ElseIf cEmpAnt+cFilAnt $ "XXxx"
					If QRF->C9_LOCAL == "01"
						cPendencia := "SEPARAวรO DO ARMAZษM '01-TRANSLUC' "
					ElseIf QRF->C9_LOCAL == "02"
						cPendencia := "SEPARAวรO DO ARMAZษM '02-SUPERLOG' "
					Endif
				ElseIf cEmpAnt+cFilAnt $ "0208"
					If QRF->C9_LOCAL == "01"
						cPendencia := "SEPARAวรO DO ARMAZษM '01-BETIM' "
					ElseIf QRF->C9_LOCAL == "02"
						cPendencia := "SEPARAวรO DO ARMAZษM '02-UBERLANDIA' "
					Endif
				ElseIf cEmpAnt+cFilAnt $ "0204"
					If QRF->C9_LOCAL == "01"
						cPendencia := "SEPARAวรO DO ARMAZษM '01-TEXACO' "
					ElseIf QRF->C9_LOCAL == "02"
						cPendencia := "SEPARAวรO DO ARMAZษM '02-MICHELIN' "
					Endif
				ElseIf cEmpAnt+cFilAnt $ "1001"
					cPendencia := "SEPARAวรO DO ARMAZษM' "
				Endif

				//If !lIsAuto
				dbSelectArea("SC9")
				dbSetOrder(1)
				dbSeek(xFilial("SC9")+QRF->C9_PEDIDO+QRF->C9_ITEM+QRF->C9_SEQUEN+QRF->C9_PRODUTO)
				RecLock("SC9",.F.)
				SC9->C9_FLGENVI := 'E'
				SC9->C9_LIBFAT  := dDataBase
				SC9->C9_BLINF   := cHora
				msUnLock()
				//Endif

				dbSelectArea("QRF")
				dbSkip()
			Enddo
			QRF->(DbCloseArea())

			oHtml:ValByName("pendencia" ,cPendencia)
			dbselectarea("SC5")
			dbsetorder(1)
			dbseek(xFilial("SC5")+aSC9[mr,3])

			dbselectarea("SA1")
			dbsetorder(1)
			dbseek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
			dbselectarea("SA4")
			dbsetorder(1)
			dbseek(xFilial("SA4")+SC5->C5_TRANSP)

			dbselectarea("SA3")
			dbsetorder(1)
			dbseek(xFilial("SA3")+SC5->C5_VEND1)

			nTotalped := 0
			nPeso := 0
			// Grava Log
			U_GMCFGM01("ED",SC5->C5_NUM,,FunName())

			cQry := ""
			cQry += "SELECT SUM(C9_QTDLIB*C9_PRCVEN)AS TOTALPED "
			cQry += "  FROM " + RetSqlName("SC9") + "   "
			cQry += "WHERE D_E_L_E_T_ = ' ' "
			cQry += "  AND C9_NFISCAL = '      ' "
			If !lSendFrimazo
				cQry += "  AND C9_BLEST = ' ' "
			Endif
			cQry += "  AND C9_BLCRED = ' ' "
			cQry += "  AND C9_PEDIDO = '" +aSC9[mr,3]+ "' "
			cQry += "  AND C9_FILIAL = '" + xFilial("SC9") +"' "

			TCQUERY cQry NEW ALIAS "QRP"

			nTotalped := nTotalped + QRP->TOTALPED

			QRP->(DbCloseArea())

			cQre := ""
			cQre += "SELECT SUM(C9_QTDLIB*B1_PESO)AS PESOPED "
			cQre += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SB1") + " SB1 "
			cQre += " WHERE SB1.D_E_L_E_T_ = ' ' "
			cQre += "   AND SB1.B1_COD = SC9.C9_PRODUTO "
			cQre += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
			cQre += "   AND SC9.C9_NFISCAL = '      '  "
			If !lSendFrimazo
				cQre += "   AND SC9.C9_BLEST = ' ' "
			Endif
			cQre += "   AND SC9.C9_BLCRED = ' ' "
			cQre += "   AND SC9.D_E_L_E_T_ = ' ' "
			cQre += "   AND SC9.C9_PEDIDO = '" +aSC9[mr,3]+ "' "
			cQre += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "


			TCQUERY cQre NEW ALIAS "QRE"

			nPeso := nPeso + QRE->PESOPED

			QRE->(DbCloseArea())

			AAdd((oHtml:ValByName("l.pedido" )),aSC9[mr,3])
			AAdd((oHtml:ValByName("l.cliente" )),SA1->A1_COD + "/" + SA1->A1_LOJA)
			AAdd((oHtml:ValByName("l.clienome" )),SA1->A1_NOME + "M.Int:"+SC5->C5_MSGINT + " M.Nf= " +SC5->C5_MENNOTA)
			//AAdd((oHtml:ValByName("l.clienome" )),SA1->A1_NOME + " M.Nf= " +SC5->C5_MENNOTA)
			AAdd((oHtml:ValByName("l.cidcliped" )),SA1->A1_MUN)
			AAdd((oHtml:ValByName("l.vlped" )),transform(nTotalped,'@E 999,999.99'))
			AAdd((oHtml:ValByName("l.transp" )),SA4->A4_NREDUZ)
			aadd((oHtml:ValByName("l.pendencia" )),transform(nPeso,"@E 999,999.99"))
			aadd((oHtml:ValByName("l.vendedor" )),SA3->A3_COD + "-" + SA3->A3_NREDUZ )
			// Verifico o status conforme a tela
			If aSC9[mr,1] == 3
				Aadd((oHtml:ValByName("l.novosaldo" )),"SALDO" )
			Else
				Aadd((oHtml:ValByName("l.novosaldo" )),"NOVO" )
			Endif

			nTotal += nTotalped
			nTotPeso  += nPeso

			//If !lIsAuto
			DbSelectArea("SC5")
			RecLock("SC5",.F.)
			SC5->C5_BLPED 	:= "S"
			SC5->C5_DTPROGM := IIf(SC5->C5_DTPROGM < dDataBase,dDataBase,SC5->C5_DTPROGM)
			MsUnlock()
			//Endif
		EndIf
	Next

	If nTotal > 0
		oHtml:ValByName("totalpedidolib",transform(nTotal,'@E 999,999.99'))
		oHtml:ValByName("totalpeso",transform(nTotPeso,"@E 999,999.99"))

		oProcess:ClientName(Substr(cUsuario,7,15))

		//cCodEmpFil	:= SM0->M0_CODIGO + SM0->M0_CODFIL // EMPRESA+FILIAL
		//
		oProcess:cTo	:= U_BFFATM15(GetMv("GM_SENPEND"),"BIG005")	// Envio pendencia
		oProcess:Start()
		oProcess:Finish()
		//ConOut("Finalizado processo BIG005 Envio Pendencia " + oProcess:cTo)

		// For็a disparo dos e-mails pendentes do workflow
		WFSENDMAIL()
		
		// IAGO 28/03/2017 Projeto(20) Logistica Reversa
		If cEmpAnt == "02"
			U_BFFATW21()
		Endif

		Alert("Processo Finalizado com Sucesso.")
	Else
		Alert("Nenhum pedido foi marcado. WorkFlow nใo serแ enviado.")
	EndIf

Return


/*/{Protheus.doc} CriaArq
(Montagem do acols do listbox  )
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function CriaArq(lFirst)

	Local 	nReg := 0
	Local	cQry,cQra,cQrc,cQrb,cQrd,cQrf
	Default	lFirst	:= .F.

	nSumBlEst := nSumBlCrd := nSumBlFin := nSumValLib := nSumValPed := 0



	IncProc("Criando Arquivo Temporario...")

	If cBlqCrd == "Nใo Liberado" .Or. cBlqCrd == "Eliminar Residuos"

		cQry := ""
		cQry += "SELECT DISTINCT C5_NUM C9_PEDIDO,C5_CLIENTE,C5_LOJACLI,C5_CONDPAG,"
		cQry += "       C5_EMISSAO,C5_BLPED,A1_NREDUZ,C5_DTPROGM, A1_CEP,A1_NOME,C5_MSGEXP,C5_MSGINT,C5_VEND1, A1_MUN,  "
		cQry += "	CASE WHEN C5_TPFRETE = 'S' THEN 'S=Sem Frete' "
		cQry += "        WHEN C5_TPFRETE = 'C' THEN 'C=CIF' "
		cQry += "        WHEN C5_TPFRETE = 'F' THEN 'F=FOB' "
		cQry += "        WHEN C5_TPFRETE = 'T' THEN 'T=Conta Terceiros' "
		cQry += "     END + '-' + C5_TRANSP + '-' + "
		cQry += "                      ISNULL((SELECT (A4_NREDUZ)
		cQry += "                             FROM " + RetSqlName("SA4") + " A4
		cQry += "                            WHERE A4.D_E_L_E_T_ = ' '
		cQry += "                              AND A4_COD = C5_TRANSP
		cQry += "                              AND A4_FILIAL = '" + xFilial("SA4") + "'),
		cQry += "                       ' ') TRANSP "
		cQry += "  FROM " + RetSqlName("SC5") + " SC5, " + RetSqlName("SA1") + " SA1 "
		cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
	ElseIf cBlqCrd == "Alcada"

		cQry := ""
		cQry += "SELECT DISTINCT C5_NUM C9_PEDIDO,C5_CLIENTE,C5_LOJACLI,C5_CONDPAG,"
		cQry += "       C5_EMISSAO,C5_BLPED,A1_NREDUZ,C5_DTPROGM, A1_CEP,A1_NOME,C5_MSGEXP,C5_MSGINT,C5_VEND1, A1_MUN,  "
		cQry += "	CASE WHEN C5_TPFRETE = 'S' THEN 'S=Sem Frete' "
		cQry += "        WHEN C5_TPFRETE = 'C' THEN 'C=CIF' "
		cQry += "        WHEN C5_TPFRETE = 'F' THEN 'F=FOB' "
		cQry += "        WHEN C5_TPFRETE = 'T' THEN 'T=Conta Terceiros' "
		cQry += "     END + '-' + C5_TRANSP + '-' + "
		cQry += "                      ISNULL((SELECT (A4_NREDUZ)
		cQry += "                             FROM " + RetSqlName("SA4") + " A4
		cQry += "                            WHERE A4.D_E_L_E_T_ = ' '
		cQry += "                              AND A4_COD = C5_TRANSP
		cQry += "                              AND A4_FILIAL = '" + xFilial("SA4") + "'),
		cQry += "                       ' ') TRANSP "
		cQry += "  FROM " + RetSqlName("SC5") + " SC5, " + RetSqlName("SA1") + " SA1 "
		cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
	Else
		cQry := ""
		cQry += "SELECT DISTINCT C5_NUM C9_PEDIDO,C5_CLIENTE,C5_LOJACLI,C5_EMISSAO,C5_BLPED,A1_NREDUZ,C5_DTPROGM, A1_CEP,A1_NOME,C5_MSGEXP,C5_MSGINT,C5_VEND1,C5_CONDPAG, A1_MUN, "
		cQry += "	CASE WHEN C5_TPFRETE = 'S' THEN 'S=Sem Frete' "
		cQry += "        WHEN C5_TPFRETE = 'C' THEN 'C=CIF' "
		cQry += "        WHEN C5_TPFRETE = 'F' THEN 'F=FOB' "
		cQry += "        WHEN C5_TPFRETE = 'T' THEN 'T=Conta Terceiros' "
		cQry += "     END + '-' + C5_TRANSP + '-' + "
		cQry += "	                   	ISNULL((SELECT (A4_NREDUZ)
		cQry += "                             FROM " + RetSqlName("SA4") + " A4
		cQry += "                            WHERE A4.D_E_L_E_T_ = ' '
		cQry += "                              AND A4_COD = C5_TRANSP
		cQry += "                              AND A4_FILIAL = '" + xFilial("SA4") + "'),
		cQry += "                       ' ') TRANSP "
		cQry += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SC5") + " SC5, " + RetSqlName("SA1") + " SA1 "
		cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "

		// Trecho comentado em 03/07/2013 a pedido de Leandro - Nใo existe mais a Agrolog
		// Se for a filial Parana da BigForta e nใo for usuแrio de libera็ใo de cr้dito, irแ efetuar a pergunta sobre qual armaz้m filtrar
		//If cEmpAnt+cFilAnt $ "0204" .And. !RetCodUsr() $ GetMv("BF_USRSERA")
		//	nOpcLoc	:= Aviso("Escolha local de saํda!","Para a filial Curitiba ้ necessแrio escolher entre o armaz้m da OL Logistica ou Agrolog!",{"01-OL Logistica","02-AGrolog"},3)
		//	If nOpcLoc == 2
		//		cQry += " AND C9_LOCAL = '02' "
		//	ElseIf nOpcLoc == 1
		//		cQry += " AND C9_LOCAL = '01' "
		//	Endif
		//Endif

		If cEmpAnt+cFilAnt $ "02xx" .And. !RetCodUsr() $ GetMv("BF_USRSERA")
			If nOpcLoc == 0
				nOpcLoc	:= Aviso("Escolha local de saํda!","Para a filial BF-RS ้ necessแrio escolher entre o armaz้m Atria ou Flexsil",{"01-Atria","02-Flexsil"},3)
			Endif

			If nOpcLoc == 2
				cQry += " AND C9_LOCAL = '02' "
			ElseIf nOpcLoc == 1
				cQry += " AND C9_LOCAL = '01' "
			ElseIf nOpcLoc <> 3
				nOpcLoc := 3
			Endif
		Endif

	Endif
	// Caso seja ativado filtro de pedidos bloqueados no cr้dito
	If cBlqCrd == "Pendente Financeiro"
		cQry += "  AND C5_BLPED = 'P' "
	ElseIf cBlqCrd == "Pendente Comercial"
		cQry += "  AND C5_BLPED = 'T' "
	ElseIf cBlqCrd == "Antecipado"
		cQry += "  AND C5_BLPED = 'F' "
	ElseIf cBlqCrd == "Rejeitado"
		cQry += "  AND C9_BLCRED = '09' AND C9_FLGENVI NOT IN('P','T') "
	ElseIf cBlqCrd == "Saldo Pedido"
		cQry += "  AND ISNULL((SELECT SUM(C6_VALOR) "
		cQry += "             FROM " + RetSqlName("SC6") + " SC6 "
		cQry += "            WHERE D_E_L_E_T_ = ' ' "
		cQry += "              AND SC6.C6_NUM = SC9.C9_PEDIDO "
		cQry += "              AND SC6.C6_FILIAL = '" + xFilial("SC6") + "'),0)  > "
		cQry += "      ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQry += "             FROM " + RetSqlName("SC9") + " C9 "
		cQry += "            WHERE C9.C9_LIBFAT = ' ' "
		cQry += "              AND C9.C9_NFISCAL = ' ' "
		cQry += "              AND C9.D_E_L_E_T_ = ' ' "
		cQry += "              AND C9.C9_PEDIDO = SC9.C9_PEDIDO "
		cQry += "              AND C9.C9_FILIAL = '" + xFilial("SC9") +"'),0) "
	ElseIf cBlqCrd == "Liberado"
		cQry += "  AND ISNULL((SELECT SUM(C6_VALOR) "
		cQry += "             FROM " + RetSqlName("SC6") + " SC6 "
		cQry += "            WHERE D_E_L_E_T_ = ' ' "
		cQry += "              AND SC6.C6_NUM = SC9.C9_PEDIDO "
		cQry += "              AND SC6.C6_FILIAL = '" + xFilial("SC6") + "'),0) <= "
		cQry += "      ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQry += "             FROM " + RetSqlName("SC9") + " C9 "
		cQry += "            WHERE C9.C9_LIBFAT = ' ' "
		cQry += "              AND C9_BLCRED = '  ' "
		cQry += "              AND C9.C9_NFISCAL = ' ' "
		cQry += "              AND C9.D_E_L_E_T_ = ' ' "
		cQry += "              AND C9.C9_PEDIDO = SC9.C9_PEDIDO "
		cQry += "              AND C9.C9_FILIAL = '" + xFilial("SC9") +"'),0) "
	Elseif cBlqCrd == "Blq Credito"
		cQry += "  AND C9_BLCRED NOT IN('  ','10') "
	Endif

	If cBlqCrd == "Nใo Liberado"
		cQry += "   AND ISNULL((SELECT SUM((C6_QTDVEN-C6_QTDENT)*C6_PRCVEN) "
		cQry += "              FROM " + RetSqlName("SC6") + " SC6 "
		cQry += "             WHERE D_E_L_E_T_ = ' ' "
		cQry += "               AND SC6.C6_NUM = SC5.C5_NUM "
		cQry += "               AND C6_BLQ != 'R' "
		cQry += "               AND C6_QTDENT = 0 "
		cQry += "               AND SC6.C6_FILIAL = '" + xFilial("SC6") + "'),0) > 0 "
		cQry += "   AND C5_LIBEROK = ' ' "
		cQry += "   AND C5_EMISSAO >= '"+DTOS(Date()-180)+"' "
	ElseIf cBlqCrd == "Eliminar Residuos"
		cQry += "   AND ISNULL((SELECT SUM((C6_QTDVEN-C6_QTDENT)*C6_PRCVEN) "
		cQry += "              FROM " + RetSqlName("SC6") + " SC6 "
		cQry += "             WHERE D_E_L_E_T_ = ' ' "
		cQry += "               AND SC6.C6_NUM = SC5.C5_NUM "
		cQry += "               AND C6_BLQ != 'R' "
		cQry += "               AND SC6.C6_FILIAL = '" + xFilial("SC6") + "'),0) > 0 "
	ElseIf cBlqCrd == "Alcada"
		cQry += "   AND (( SELECT COUNT(ZS_MOTIVO) "
		cQry += "            FROM "+RetSqlName("SZS") + " ZS, "+RetSqlName("SC6") + " C6B, "+ RetSqlName("SB1") + " B1B "
		cQry += "           WHERE ZS.D_E_L_E_T_ = ' ' "
		cQry += "             AND C6B.D_E_L_E_T_ = ' ' "
		cQry += "             AND C6B.C6_QTDENT < C6B.C6_QTDVEN "
		cQry += "             AND C6B.C6_BLQ != 'R' "
		cQry += "             AND C6B.C6_NUM = C5_NUM "
		cQry += "             AND C6B.C6_FILIAL = '" + xFilial("SC6")+ "' "
		cQry += "             AND B1B.D_E_L_E_T_ = ' ' "
		cQry += "             AND B1B.B1_COD = C6B.C6_PRODUTO "
		cQry += "             AND B1B.B1_FILIAL = '" + xFilial("SB1") + "' "
		//cQry += "             AND ZS_CODFORN = B1B.B1_PROC "
		//cQry += "             AND ZS_LOJAFOR = B1B.B1_LOJPROC "
		cQry += "             AND ZS_TIPPROD = B1B.B1_CABO " // TEX/ROC/HOU/OUT/MIC/LUS
		cQry += "             AND INSTR(C6B.C6_XALCADA,ZS_MOTIVO) > 0  "
		cQry += "             AND ZS_IDUSR1 = '"+RetCodUsr()+"' "	// Usuแrio logado no Sistema
		cQry += "             AND ZS_FILIAL = '"+xFilial("SZS")+"' ) > 0 "
		cQry += "   OR ( SELECT COUNT(ZS_MOTIVO) "
		cQry += "          FROM "+RetSqlName("SZS") + " ZS, "+RetSqlName("SC6") + " C6B "
		cQry += "         WHERE ZS.D_E_L_E_T_ = ' ' "
		cQry += "           AND C6B.C6_QTDENT < C6B.C6_QTDVEN "
		cQry += "           AND C6B.C6_BLQ != 'R' "
		cQry += "           AND C6B.D_E_L_E_T_ = ' ' "
		cQry += "           AND C6B.C6_NUM = C5_NUM "
		cQry += "           AND C6B.C6_FILIAL = '" + xFilial("SC6")+ "' "
		//cQry += "           AND ZS_CODFORN = ' ' "
		//cQry += "           AND ZS_LOJAFOR = ' ' "
		cQry += "           AND ZS_TIPPROD = ' ' " // TEX/ROC/HOU/OUT/MIC/LUS
		cQry += "           AND INSTR(C6B.C6_XALCADA,ZS_MOTIVO) > 0  "
		cQry += "           AND ZS_IDUSR1 = '"+RetCodUsr()+"' "	// Usuแrio logado no Sistema
		cQry += "           AND ZS_FILIAL = '"+xFilial("SZS")+"' ) > 0)"
		cQry += "  AND ISNULL((SELECT SUM(C6_VALOR) "
		cQry += "             FROM " + RetSqlName("SC6") + " SC6 "
		cQry += "            WHERE D_E_L_E_T_ = ' ' "
		cQry += "              AND SC6.C6_NUM = C5_NUM "
		cQry += "              AND SC6.C6_FILIAL = '" + xFilial("SC6") + "'),0)  > "
		cQry += "      ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQry += "             FROM " + RetSqlName("SC9") + " C9 "
		cQry += "            WHERE C9.C9_LIBFAT = ' ' "
		cQry += "              AND C9.C9_NFISCAL = ' ' "
		cQry += "              AND C9.D_E_L_E_T_ = ' ' "
		cQry += "              AND C9.C9_PEDIDO = C5_NUM "
		cQry += "              AND C9.C9_FILIAL = '" + xFilial("SC9") +"'),0) "
	Else
		cQry += "   AND SC5.C5_NUM = SC9.C9_PEDIDO "
		cQry += "   AND SC9.C9_LIBFAT = ' ' "
		cQry += "   AND SC9.C9_FLGENVI NOT IN ('E','I') "
		cQry += "   AND SC9.D_E_L_E_T_ = ' ' "
		cQry += "   AND SC9.C9_SEQCAR = ' ' "
		cQry += "   AND SC9.C9_CARGA = ' ' "
		cQry += "   AND SC9.C9_NFISCAL = '      ' "
		cQry += "   AND SC9.C9_SERIENF = '   ' "
		cQry += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "
	Endif
	cQry += "   AND SA1.A1_LOJA = SC5.C5_LOJACLI "
	cQry += "   AND SA1.A1_COD = SC5.C5_CLIENTE "
	cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQry += "   AND SC5.C5_TIPO = 'N' "
	cQry += "   AND SC5.D_E_L_E_T_ = ' ' "

	If Empty(cAutNumPed)
		cQry += "   AND SC5.C5_DTPROGM <= '" +DTOS(dDataprg)+"' "
	Endif

	If !Empty(cVendPesq)
		cQry += "	AND C5_VEND1 = '"+cVendPesq+"' "
	Endif
	If !Empty(cOperVend)
		cQry += "  AND C5_VEND1 IN(SELECT A3_COD "
		cQry += "                    FROM "+RetSqlName("SA3")+" A3 "
		cQry += "                   WHERE D_E_L_E_T_ =' ' "
		cQry += "                     AND A3_OPERADO = '"+cOperVend+"' "
		cQry += "                     AND A3_FILIAL = '  ') "
	Endif
	// 16/10/2014 - Automแtico para expedi็ใo
	If lIsAuto
		If !Empty(cAutNumPed)
			cQry += "	AND C5_NUM = '"+cAutNumPed+"' "	// Filtra somente o pedido especifico
		Else
			cQry += "   AND C5_XENVFAT = '1' " // Se envia automแtico para o faturamento
		Endif
	Endif

	cQry += "   AND SC5.C5_FILIAL = '" + xFilial("SC5") + "' "
	cQry += " ORDER BY C5_NUM "

	// Adicionada tratativa para fechar area de trabalho temporแria em 17/06/2013
	If Select("QRP") > 0
		DbSelectArea("QRP")
		DbCloseArea()
	Endif

	TCQUERY cQry NEW ALIAS "QRP"

	While !Eof()

		cPedido := QRP->C9_PEDIDO

		IncProc("Processando Pedido N."+cPedido)

		//TOTAL DO PEDIDO //
		If cBlqCrd $"Nใo Liberado#Eliminar Residuos"
			cQra := ""
			cQra += "SELECT SUM((C6_QTDVEN-C6_QTDENT)*C6_PRCVEN) TOTAL , 0 BLREJ "
			cQra += "  FROM " + RetSqlName("SC6") + " SC6 "
			cQra += " WHERE D_E_L_E_T_ = ' ' "
			cQra += "   AND SC6.C6_NUM = '"+cPedido+"' "
			cQra += "   AND C6_BLQ != 'R' "
			cQra += "   AND C6_QTDENT < C6_QTDVEN "
			cQra += "   AND C6_FILIAL = '" + xFilial("SC6") + "' "
		Else
			cQra := ""
			cQra += "SELECT SUM(C9_QTDLIB*C9_PRCVEN)AS TOTAL,SUM(CASE WHEN C9_BLCRED = '09' AND C9_FLGENVI = ' ' THEN C9_QTDLIB*C9_PRCVEN ELSE 0 END) BLREJ "
			cQra += "  FROM " + RetSqlName("SC9") + " SC9 "
			cQra += " WHERE SC9.C9_NFISCAL = '      ' "
			cQra += "   AND SC9.C9_LIBFAT = ' ' "
			cQra += "   AND SC9.D_E_L_E_T_ = ' ' "
			cQra += "   AND SC9.C9_PEDIDO = '"  + cpedido + "' "
			cQra += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "
		Endif

		TCQUERY cQra NEW ALIAS "QRA"


		//TOTAL RETIDO NO CREDITO
		cQrb := ""
		cQrb += "SELECT SUM(C9_QTDLIB*C9_PRCVEN)AS CREDITO "
		cQrb += "  FROM " + RetSqlName("SC9") + " SC9 "
		cQrb += " WHERE SC9.C9_LIBFAT = ' ' "
		cQrb += "   AND SC9.C9_BLCRED NOT IN(' ','10') "
		cQrb += "   AND SC9.C9_NFISCAL = ' ' "
		cQrb += "   AND SC9.D_E_L_E_T_ = ' ' "
		cQrb += "   AND SC9.C9_PEDIDO = '"  + cpedido + "' "
		cQrb += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "

		TCQUERY cQrb NEW ALIAS "QRB"


		// TOTAL LIBERADO
		cQrc := ""
		cQrc += "SELECT SUM(C9_QTDLIB*C9_PRCVEN) AS LIB
		cQrc += "  FROM " + RetSqlName("SC9") + " SC9 "
		cQrc += " WHERE SC9.C9_LIBFAT = ' ' "
		cQrc += "   AND SC9.C9_BLCRED = ' ' "
		cQrc += "   AND SC9.C9_BLEST = ' ' "
		cQrc += "   AND SC9.C9_NFISCAL = ' ' "
		cQrc += "   AND SC9.D_E_L_E_T_ = ' ' "
		cQrc += "   AND SC9.C9_PEDIDO = '"  + cpedido + "' "
		cQrc += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "

		TCQUERY cQrc NEW ALIAS "QRC"


		// retido no estoque
		cQrd := ""
		cQrd += "SELECT SUM(C9_QTDLIB*C9_PRCVEN)AS BLE  "
		cQrd += "  FROM " + RetSqlName("SC9") + " SC9 "
		cQrd += " WHERE SC9.C9_NFISCAL = ' ' "
		cQrd += "   AND SC9.C9_LIBFAT = ' ' "
		cQrd += "   AND SC9.C9_BLEST <> ' ' "
		cQrd += "   AND SC9.C9_BLCRED = ' ' "
		cQrd += "   AND SC9.D_E_L_E_T_ = ' ' "
		cQrd += "   AND SC9.C9_PEDIDO = '"  + cpedido + "' "
		cQrd += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "

		TCQUERY cQrd NEW ALIAS "QRD"


		//TOTAL DO PEDIDO venda  //
		cQra := ""
		cQra += "SELECT SUM(C6_VALOR)AS C6TOTAL "
		cQra += "  FROM " + RetSqlName("SC6") + " SC6 "
		cQra += " WHERE D_E_L_E_T_ = ' ' "
		cQra += "   AND SC6.C6_NUM = '" + cPedido + "' "
		cQra += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' "

		TCQUERY cQra NEW ALIAS "QRE"


		// TOTAL BLOQUEIO FINANCEIRO P/ DEPOSITO ANTECIPADO
		cQrf := ""
		cQrf += "SELECT SUM(C9_QTDLIB*C9_PRCVEN)AS BLFIN "
		cQrf += "  FROM " + RetSqlName("SC9") + " SC9 "
		cQrf += " WHERE SC9.C9_LIBFAT = ' ' "
		cQrf += "   AND SC9.C9_FLGENVI IN('F','T') "
		cQrf += "   AND SC9.C9_NFISCAL = ' ' "
		cQrf += "   AND SC9.D_E_L_E_T_ = ' ' "
		cQrf += "   AND SC9.C9_PEDIDO = '"  + cpedido + "' "
		cQrf += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "

		TCQUERY cQrf NEW ALIAS "QRF"


		_nStatus	:= 1

		If QRC->LIB > 0 .And. QRB->CREDITO <= 0
			IF QRC->LIB  == QRE->C6TOTAL
				_nStatus	:= 2
			Elseif (QRB->CREDITO+QRD->BLE+QRC->LIB) < QRE->C6TOTAL
				_nStatus	:= 3
			Elseif QRD->BLE > 0
				_nStatus  := 4
			Endif
		ELSEIF QRC->LIB == 0 .OR. QRB->CREDITO > 0
			_nStatus	:= 1
		EndIf

		If QRF->BLFIN > 0
			_nStatus	:= 6
		Endif

		IF QRA->BLREJ > 0
			_nStatus	:= 5
		Endif

		If QRA->BLREJ <= 0 .And. QRP->C5_BLPED == "P"
			_nStatus 	:= 7
		Endif

		If QRA->BLREJ <= 0 .And. QRP->C5_BLPED == "T"
			_nStatus 	:= 8
		Endif

		lAdd	:= .F.
		If 	cBlqCrd == "Liberado" .And. QRB->CREDITO <=0 .And. QRF->BLFIN <=0
			lAdd	:= .T.
		ElseIf ((nValMax > 0 .And. QRA->TOTAL < nValMax) .Or. nValMax <= 0)
			lAdd	:= .T.
		Endif

		// Adicionado em 28/10/2014
		// Se automแtico, somente pedidos novos liberados
		If lIsAuto
			If Empty(cAutNumPed)
				lAdd	:= .F.
				If QRC->LIB > 0 .And. QRB->CREDITO <= 0 .And. (QRD->BLE+QRC->LIB) >= QRE->C6TOTAL
					lAdd	:= .T.
				Endif
			Else
				If STOD(QRP->C5_DTPROGM) > dDataprg
					lAdd	:= MsgYesNo("Pedido '"+QRP->C9_PEDIDO+"' estแ com data programada para o dia "+DTOC(STOD(QRP->C5_DTPROGM))+" e talvez fora de rota. Deseja for็ar o envio assim mesmo?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				Endif
			Endif
		Endif

		If lAdd
			If lIsAuto
				lExistPed	:= .T.
			Endif

			AAdd( aSC9, { 	_nStatus,;		// 1
			.F.,;	// 2
			QRP->C9_PEDIDO,;	//3
			STOD(QRP->C5_EMISSAO),;	//4
			QRP->C5_CLIENTE+"/"+QRP->C5_LOJACLI+" "+QRP->A1_NOME + " ( "+Alltrim(QRP->A1_NREDUZ)+" ) ",; 	//5
			STOD(QRP->C5_DTPROGM),; 	//6
			transform( QRB->CREDITO,'@E 999,999.99') ,;		//7
			transform( QRD->BLE,'@E 999,999.99'),;			//8
			transform( QRC->LIB,'@E 999,999.99'),;			//9
			transform( QRA->TOTAL,'@E 999,999.99'),;		//10
			transform( QRE->C6TOTAL,'@E 999,999.99'),;     //11
			transform( QRF->BLFIN,'@E 999,999.99'),;       //12
			QRP->C5_MSGINT,;							   // 13
			QRP->C5_MSGEXP,;									// 14
			Alltrim(QRP->C5_VEND1) + "-"+Posicione("SA3",1,xFilial("SA3")+QRP->C5_VEND1,"A3_NREDUZ"),;
				SA3->A3_OPERADO  + " - " + Posicione("SU7",1,xFilial("SU7")+SA3->A3_OPERADO,"U7_NREDUZ"),;//	Capital(Substr(SA3->A3_EMTMK,1,At("@",SA3->A3_EMTMK)-1)),;
				QRP->C5_CONDPAG + " - " + Posicione("SE4",1,xFilial("SE4")+QRP->C5_CONDPAG,"E4_DESCRI"),;
				Alltrim(QRP->A1_MUN),;
				QRP->TRANSP;
				} )
			nSumBlEst +=  QRD->BLE
			nSumBlCrd +=  QRB->CREDITO
			nSumBlFin +=  QRF->BLFIN
			nSumValLib += QRC->LIB
			nSumValPed += QRA->TOTAL

		Endif

		QRA->(dbCLoseArea())
		QRB->(dbCLoseArea())
		QRC->(dbCLoseArea())
		QRD->(dbCLoseArea())
		QRE->(dbCLoseArea())
		QRF->(dbCLoseArea())

		dbSelectArea("QRP")
		dbSkip()
	Enddo
	QRP->(DbCloseArea())

	ProcRegua(1)
	IncProc("Finalizando...")
	If Len(aSC9) <= 0
		MsgAlert("Nใo houveram pedidos para as condi็๕es selecionadas!","Alerta!")
		AAdd( aSC9, { 	1,;		// 1
		.F.,;	// 2
		"",;	//3
		dDataBase,;	//4                   // Silvana/Lisiane/Marcelo/Cida
		"/" ,; 	//5
		dDataBase,; 	//6
		transform( 0,'@E 999,999.99') ,;		//7
		transform( 0,'@E 999,999.99'),;			//8
		transform( 0,'@E 999,999.99'),;			//9
		transform( 0,'@E 999,999.99'),;		//10
		transform( 0,'@E 999,999.99'),;     //11
		transform( 0,'@E 999,999.99'),;       //12
		" ",;							      //13
		" ",;                                //14
		"",;                                 //15
		"",;                                 //16
		"",;                                 //17
		"",;                                 //18
		"";                                  //19
		} )
		If !lFirst
			oSc9:nAt	:= 0
		Endif
	Endif

Return


/*/{Protheus.doc} InverteSC9
(Marca ou desmarca linha no listbox  )
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function InverteSC9()

	Local oBlq , oVendas , cBlq
	Local nParcelas	:= 0
	Local aCondicoes := {}
	Local nVal7		:= Val(StrTran(StrTran(aSC9[oSC9:nAt,7],".",""),",","."))
	Local nVal9		:= Val(StrTran(StrTran(aSC9[oSC9:nAt,9],".",""),",","."))
	Local nVal10	:= Val(StrTran(StrTran(aSC9[oSC9:nAt,10],".",""),",","."))
	Local nVal11	:= Val(StrTran(StrTran(aSC9[oSC9:nAt,11],".",""),",","."))
	Local nVal12	:= Val(StrTran(StrTran(aSC9[oSC9:nAt,12],".",""),",","."))
	Local cCliLoj	:= ""
	Local iW
	Local cQri
	Local cQry
	Local cQrf
	// Regra conforme solicita็ใo do chamado 23.451
	// Pedidos entre R$ 200,00 a 400,00 cobrar frete de R$ 35,00.
	// Pedidos entre R$ 400,00 a 500,00 cobrar frete de R$ 25,00.
	// Pedidos entre R$ 500,00 a 600,00 cobrar frete de R$ 20,00.
	// Pedidos acima de R$ 600,00 frete CIF.
	Local	cRegFrtMin	:= GetNewPar("BF_VLFRMIN","{{400,35},{500,25},{600,20},{99999999,0}}") // Se necessแrio mudar a regra, s๓ criar o parโmetro com os valores conforme exemplo
	Local	aRegFrtMin	:= {}
	Private cPed    := aSC9[oSc9:nAt,3]
	Private aBlq := {}

	If cBlqCrd == "Nใo Liberado" .Or. cBlqCrd == "Eliminar Residuos"
		aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2],.T., .F.)
		Return
	Endif
	If cBlqCrd <>  "Tudo"
		MsgAlert("Nใo ้ permitida a marca็ใo de pedido para envio se nใo estiver selecionada a op็ใo 'Tudo' no filtro de pedidos!!","Envio bloqueado!")
		Return
	Endif

	If FWCodEmp() <> '10'
		// Processo inserido a Pedido de Marcio Mazzi em 27/01/06 afim de bloquear pedidos ao faturamento que sejam transportadora Alfa e com cobranca.
		Dbselectarea("SC5")
		Dbsetorder(1)
		If Dbseek(xFilial("SC5")+cPed)
			cCliLoj	:= SC5->C5_CLIENTE+SC5->C5_LOJACLI

			aCondicoes  := Condicao(Val(aSC9[oSC9:nAt,9]),SC5->C5_CONDPAG,,dDataBase)
			nParcelas 	:= Len(aCondicoes)

			If SC5->C5_TPFRETE $ "C#F"
				If !ExistCpo("SA4",SC5->C5_TRANSP,1,"SEM TRANSP")
					If !lIsAuto .Or. !Empty(cAutNumPed)
						MsgInfo("Nใo hแ transportadora informada neste pedido. O mesmo nใo poderแ ser faturado!","Pedido bloqueado para Envio!")
					Endif
					Return
				Endif
			Endif
			// Se o tipo de frete for Cif, pois no caso de FOB nใo ้ necessแrio cobrar o adicional de frete.
			If SC5->C5_TPFRETE == "C"
				aRegFrtMin	:= &(cRegFrtMin)

				// Verifica se ao menos 80% do pedido ้ Michelin para validar valor do frete minimo de R$ 500,00 conforme regra comercial da Michelin
				cQrf := "SELECT SUM(C9_QTDLIB*C9_PRCVEN) TOTPED ,SUM(CASE WHEN B1_CABO IN('MOT','MIC','CON') THEN C9_QTDLIB * C9_PRCVEN ELSE 0 END ) SUBMICHELIN "
				cQrf += "  FROM " + RetSqlName("SC9") + " C9," + RetSqlName("SB1") +  " B1 "
				cQrf += " WHERE C9_LIBFAT = ' ' "
				cQrf += "   AND C9_FLGENVI = ' ' "
				cQrf += "   AND C9_BLCRED =  '  ' "
				cQrf += "   AND C9_BLEST = '  '  "
				cQrf += "   AND C9_NFISCAL = ' ' "
				cQrf += "   AND B1.D_E_L_E_T_ = ' ' "
				cQrf += "   AND B1_COD = C9_PRODUTO "
				cQrf += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"
				cQrf += "   AND C9.D_E_L_E_T_ = ' ' "
				cQrf += "   AND C9_PEDIDO = '"  + SC5->C5_NUM + "' "
				cQrf += "   AND C9_FILIAL = '" + xFilial("SC9") +"' "

				TCQUERY cQrf NEW ALIAS "QRF"

				If QRF->SUBMICHELIN > Round(QRF->TOTPED * 0.80,2)
					aRegFrtMin	:= {{499,35},{99999999,0}}
				Endif
				QRF->(DbCloseArea())

				For iW := 1 To Len(aRegFrtMin)
					If nVal9 <= aRegFrtMin[iW,1] .And. SC5->C5_FRETE < aRegFrtMin[iW,2]
						If !lIsAprovador
							MsgAlert("Pedido bloqueado para envio para faturamento, pois o valor do Frete informado de " + Transform(SC5->C5_FRETE,"@E 999,999.99") +;
								" ้ menor que o mํnimo necessแrio de R$ " + Transform(aRegFrtMin[iW,2],"@E 999,999.99"),"Erro 'BIG005/C5_FRETE Menor que o Mํnimo'")
							Return
						Else
							If !MsgYesNo("Pedido bloqueado para envio para faturamento, pois o valor do Frete informado de " + Transform(SC5->C5_FRETE,"@E 999,999.99") +;
									" ้ menor que o mํnimo necessแrio de R$ " + Transform(aRegFrtMin[iW,2],"@E 999,999.99"),"Erro 'BIG005/C5_FRETE Menor que o Mํnimo'")
								Return
							Endif
						Endif
					Endif
				Next
			Endif
			If SC5->C5_BLPED $ "S#M"
				If !lIsAuto .Or. !Empty(cAutNumPed)
					MsgAlert("Pedido enviado para faturamento, nใo pode ser reenviado!!-","BIG005/C5_BLPED=S'")
				Endif
				Return
			ElseIf SC5->C5_BLPED == "F" .And. !(RetCodUsr() $ GetMv("BF_USRSERA"))
				If !lIsAuto .Or. !Empty(cAutNumPed)
					MsgAlert("Pedido bloqueado pelo Financeiro! Solicite ao Departamento Financeiro o envio do Pedido para Faturamento!!","Erro 'BIG005/C5_BLPED=F'")
				Endif
				Return
			ElseIf SC5->C5_BLPED == "F" .And. (RetCodUsr() $ GetMv("BF_USRSERA"))
				If !lIsAuto .Or. !Empty(cAutNumPed)
					MsgAlert("Pedido bloqueado pelo Financeiro! Permissใo concedida a usuแrios do Financeiro, por้m ้ necessแrio liberar para enviar para faturamento!","BIG005/C5_BLPED=F'")
				Endif
				Return
			Endif
		Else
			MsgInfo("Pedido nใo encontrado. Contate o CPD","Erro. Chame o CPD")
		Endif
		//Fim da tratativa da Alfa.
	EndIf

	// Se houver alguma restri็ใo no financeiro, nใo permite enviar pedido
	If nVal7 > 0 .Or.  nVal12 > 0
		If !lIsAuto .Or. !Empty(cAutNumPed)
			MsgInfo("Pedido com restri็ใo no Financeiro. O mesmo nใo poderแ ser faturado!","Pedido bloqueado para Envio!")
		Endif
		Return
	Endif

	// O Sistema
	If FWCodEmp() <> '10'
		If (nVal9 / nParcelas  ) < GetNewPar("BF_VMINDUP",250)
			If !lIsAuto .Or. !Empty(cAutNumPed)
				If !lIsAprovador
					MsgInfo("Pedido com parcelas inferior a R$ " + Transform(GetNewPar("BF_VMINDUP",250),"@E 999,999.99")+". O mesmo nใo poderแ ser faturado!","Pedido bloqueado para Envio!")
					Return
				Else
					If !MsgYesNo("Pedido com parcelas inferior a R$ " + Transform(GetNewPar("BF_VMINDUP",250),"@E 999,999.99")+". Deseja faturar o mesmo ?","Aviso: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						Return
					EndIf
				Endif
			Else
				Return
			Endif
		Endif
	EndIf

	// Adi็ใo de filtro que impede que pedido recem liberado no credito possa ser marcado e enviado ao faturamento
	If !RetCodUsr() $ GetMv("BF_USRSERA")

		cQry := "SELECT Z0_HORA + ':00'  HORA_LIB "
		cQry += "  FROM "+RetSqlName("SZ0")
		cQry += " WHERE Z0_DATA = '"+DTOS(dDataBase)+"' "
		cQry += "   AND Z0_FILIAL= '"+xFilial("SZ0")+"' "
		cQry += "   AND Z0_TIPO = 'LC' "
		cQry += "   AND Z0_PEDIDO ='"+cPed+"' "
		cQry += " ORDER BY R_E_C_N_O_ DESC "

		TCQUERY cQry NEW ALIAS "QZ0"

		If !Eof()
			cDif	:= ElapTime(Alltrim(QZ0->HORA_LIB),Time())
			If (Val(Substr(cDif,1,2)) * 60 + Val(Substr(cDif,4,2))) < 2
				If !lIsAuto .Or. !Empty(cAutNumPed)
					MsgAlert("Pedido '"+cPed+"' foi liberado no cr้dito hแ menos de 02 minuto!")
				Endif
				QZ0->(DbCloseArea())
				Return
			Endif
			//Alert(ElapTime(Alltrim(QZ0->HORA_LIB),Time()) + "-"+Time()+"-"+Alltrim(QZ0->HORA_LIB))
		Endif
		QZ0->(DbCloseArea())
	Endif


	For iW := 1 To Len(aSC9)
		Dbselectarea("SC5")
		Dbsetorder(1)
		If Dbseek(xFilial("SC5")+aSC9[iW,3]) .And. SC5->C5_CLIENTE+SC5->C5_LOJACLI == cCliLoj .And. iW <> oSc9:nAt
			// Se houver restri็ใo no cr้dito de outro pedido do mesmo cliente nใo permite envio
			If Val(StrTran(StrTran(aSC9[iW,12],".",""),",",".")) > 0 .Or. Val(StrTran(StrTran(aSC9[iW,7],".",""),",",".")) > 0
				If !lIsAuto .Or. !Empty(cAutNumPed)
					MsgAlert("O pedido "+aSC9[iW,3]+" do mesmo cliente tem restri็ใo no financeiro. Nใo ้ possํvel enviar!!","Jun็ใo de pedidos!")
				Endif
				Return
			Endif
			If !aSC9[oSc9:nAt,2]
				If !aSC9[iW,2]
					If !lIsAuto .Or. !Empty(cAutNumPed)
						MsgAlert("Voc๊ deverแ marcar o pedido "+aSC9[iW,3]+" tamb้m para envio para o faturamento, pois ้ do mesmo cliente!!","Jun็ใo de pedidos!")
					Endif
				Endif
			Else
				If aSC9[iW,2]
					If !lIsAuto .Or. !Empty(cAutNumPed)
						MsgAlert("Favor desmarcar o pedido "+aSC9[iW,3]+" pois ้ do mesmo cliente. Nใo deve ser enviado pedidos separados para o faturamento !!","Jun็ใo de pedidos!")
					Endif
				Endif
			Endif
		Endif
	Next




	cQrf := ""

	cQrf += "SELECT SUM(C9_QTDLIB*C9_PRCVEN)AS BLFIN "
	cQrf += "  FROM " + RetSqlName("SC9") + " SC9 "
	cQrf += " WHERE SC9.C9_LIBFAT = ' ' "
	cQrf += "   AND SC9.C9_FLGENVI = 'F' "
	cQrf += "   AND SC9.C9_NFISCAL = ' ' "
	cQrf += "   AND SC9.D_E_L_E_T_ = ' ' "
	cQrf += "   AND SC9.C9_PEDIDO = '"  + aSC9[oSc9:nAt,3] + "' "
	cQrf += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") +"' "

	TCQUERY cQrf NEW ALIAS "QRF"

	dbSelectArea("QRF")
	If QRF->BLFIN > 0
		If !lIsAuto .Or. !Empty(cAutNumPed)
			MsgInfo("Pedido com restri็ใo no Financeiro!","Pedido bloqueado para Envio!")
		Endif
		QRF->(DbCloseArea())
		Return
	Endif
	QRF->(DbCloseArea())

	// Se passou por todas as valida็๕es, efetua marca็ใo do pedido
	aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .And. aSC9[oSc9:nAt,1]>1 ,.T., .F.)


	If cSN == "Sim" .And. !lIsAuto

		If Val(aSC9[oSc9:nAt,8]) == 0
			Return
		Endif

		cQri := ""
		cQri += "SELECT C9_QTDLIB,C9_ITEM,C9_SEQUEN,C9_PRODUTO,B1_DESC,B2_RESERVA,B2_QATU,C9_PRCVEN "
		cQri += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SB2") + " SB2 "
		cQri += " WHERE SB2.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB2.B2_LOCAL = '01' "
		cQri += "   AND SB2.B2_COD = SC9.C9_PRODUTO "
		cQri += "   AND SB2.B2_FILIAL = '" + xFilial("SB2") + "' "
		cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB1.B1_COD = SC9.C9_PRODUTO "
		cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
		cQri += "   AND SC9.C9_BLEST <> ' ' "
		cQri += "   AND SC9.C9_NFISCAL = ' '  "
		cQri += "   AND SC9.D_E_L_E_T_ = ' '  "
		cQri += "   AND SC9.C9_PEDIDO = '" + cPed + "'  "
		cQri += "   AND SC9.C9_FILIAL = '" +xFilial("SC9") + "'  "
		cQri += " ORDER BY SC9.C9_ITEM ASC "

		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQri),'QC6', .F., .T.)

		Count to nRecCount

		If nRecCount == 0
			QC6->(dbClosearea())
			Return
		Endif

		Dbselectarea("QC6")
		dbgotop()
		ProcREgua(nRecCount)
		While !Eof()
			IncProc("Processando item -> "+QC6->C9_ITEM)
			Aadd(aBlq,{ QC6->C9_ITEM,QC6->C9_SEQUEN,QC6->C9_PRODUTO,QC6->B1_DESC,;
				Transform(QC6->B2_QATU - QC6->B2_RESERVA,"@E 999,999.99"),;
				Transform(QC6->C9_QTDLIB,"@E 999,999.99"),'BLE',;
				Transform(QC6->C9_PRCVEN,"@E 999,999.99"),;
				Transform(QC6->C9_QTDLIB * QC6->C9_PRCVEN,"@E 999,999.99") } )
			dbSelectArea("QC6")
			dbSkip()
		End

		QC6->(dbClosearea())

		aSort(aBlq,,,{|x,y| x[1]+x[2] < y[1]+y[2]})

		DEFINE MSDIALOG oVendas FROM 000,000 TO 500,800 OF oMainWnd PIXEL TITLE OemToAnsi("Consulta itens bloqueados do pedido "+cPed)
		@ 010,005 LISTBOX oBlq VAR cBlq ;
			Fields HEADER "Item","Seq","C๓digo","Descri็ใo","Saldo Estoque","Qtd Lib","Sts","Pre็o Venda","Total" SIZE 390,220 OF oVendas PIXEL
		oBlq:SetArray(aBlq)
		oBlq:bLine:={ ||{aBlq[oBlq:nAT,01],aBlq[oBlq:nAT,02],aBlq[oBlq:nAT,03],aBlq[oBlq:nAT,04],aBlq[oBlq:nAT,05],;
			aBlq[oBlq:nAT,06],aBlq[oBlq:nAT,07],aBlq[oBlq:nAT,08],aBlq[oBlq:nAT,09]}}
		oBlq:Refresh()
		@ 235,100 BUTTON "&Fecha" of oVendas pixel SIZE 40,15 ACTION (oVendas:End() )

		ACTIVATE msDIALOG oVendas CENTERED

	Endif

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณEspelho   บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Espelho de pedido                                          บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/


Static function Espelho(cPed)
	oProcess := MsNewProcess():New({|lEnd|ESPELH(oProcess,cPed)},"Espelho de pedido estแ sendo gerado","",.F.)
	oProcess:Activate()
Return




/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณEspelh    บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Tela com espelho do pedido                                 บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function ESPELH(oObj,cInPed)

	Local oProcess
	Local oBlq , oPed , cBlq  ,nPrunit
	Local 	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Local   nAltura := aSize[6]/2.3
	Local	z

	Private aBlq := {}
	Private cPed	:= cInPed
	nSomafat := 0
	nSomast  := 0

	DEFINE MSDIALOG oPed FROM 000,000 TO 180,370 OF oMainWnd PIXEL TITLE OemToAnsi("Confirma o numero do pedido-> "+ cPed + "?")
	@ 020,020 Say ("Confirma o pedido n๚mero " + cPed+ " ?") Of oPed Pixel
	@ 035,020 Get cPed Picture "@!" of oPed Pixel
	@ 060,020 BUTTON "&Avan็a" of oPed pixel SIZE 40,15 ACTION (oPed:End() )

	ACTIVATE msDIALOG oPed CENTERED

	lSofat := .F.
	oObj:SetRegua1(MAXPASSO)
	oObj:IncRegua1("Consulta itens liberados e bloqueados")

	cQri := ""
	cQri += "SELECT C9_QTDLIB,C9_ITEM,C9_SEQUEN,C9_PRODUTO,B1_DESC,B2_RESERVA,B2_QATU,C9_FILIAL + C9_PEDIDO + C9_ITEM + C9_SEQUEN C9POS,"
	cQri += "       C9_NFISCAL,C9_PRCVEN,C9_BLEST,C9_BLCRED, B1_COD "
	cQri += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SB2") + " SB2 "
	cQri += " WHERE SB2.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB2.B2_LOCAL = C9_LOCAL "
	cQri += "   AND SB2.B2_COD = SC9.C9_PRODUTO "
	cQri += "   AND SB2.B2_FILIAL = '" + xFilial("SB2") + "' "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD = SC9.C9_PRODUTO "
	cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	If MsgYesNo("Somente a Faturar ?")
		cQri += "  AND SC9.C9_NFISCAL = ' ' "
		lSofat := .T.
	Endif
	cQri += "   AND SC9.D_E_L_E_T_ = ' '  "
	cQri += "   AND SC9.C9_PEDIDO = '" + cPed + "'  "
	cQri += "   AND SC9.C9_FILIAL = '" +xFilial("SC9") + "'  "
	cQri += " ORDER BY SC9.C9_ITEM ASC "


	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQri),'QC6', .F., .T.)

	Count to nRecCount

	oObj:SetRegua2(nREcCount)


	If nRecCount == 0
		//	QC6->(dbClosearea())
		//	Return
	Endif

	Dbselectarea("QC6")
	dbgotop()
	While !Eof()
		oObj:IncRegua2("Processando item "+QC6->C9_ITEM+" do pedido "+cPed)
		If !Empty(QC6->C9_NFISCAL)
			cStatus := "FAT"
		Else
			If !Empty(QC6->C9_BLCRED)
				cStatus := "CRD"
			Elseif !Empty(QC6->C9_BLEST) .And. Empty(QC6->C9_BLCRED)
				cStatus := "BLE"
			Else
				cStatus := "OK"
				nSomafat += (QC6->C9_QTDLIB * QC6->C9_PRCVEN)
				nSomast  += 0
			Endif
		Endif
		Dbselectarea("SC6")
		Dbsetorder(1)
		If Dbseek(xFilial("SC6")+cped+QC6->C9_ITEM)
			nPrunit := SC6->C6_PRUNIT
		Else
			nPrunit := 0.00
		Endif
		Aadd(aBlq,{ QC6->C9_ITEM,;			// 1
		QC6->C9_SEQUEN,;		// 2
		QC6->C9_PRODUTO,;		// 3
		QC6->B1_DESC,;			// 4
		Transform(QC6->B2_QATU - QC6->B2_RESERVA,"@E 999,999.99"),;	// 5
		Transform(QC6->C9_QTDLIB,"@E 999,999.99"),;	//6
		cStatus ,;				// 7
		Transform(QC6->C9_PRCVEN,"@E 999,999.99"),;	// 8
		Transform(QC6->C9_QTDLIB * QC6->C9_PRCVEN,"@E 999,999.99"),; //	9
		QC6->C9_QTDLIB,;		// 10
		Iif(cStatus $ "CRD#BLE",QC6->C9POS,""),;			// 11
		QC6->C9_QTDLIB * QC6->C9_PRCVEN,;	//	12
		nPrunit*QC6->C9_QTDLIB,;				// 13
		QC6->C9_QTDLIB,;					// 14
		Iif(SC6->C6_CF $ "5910 #6910","Bonificada",IIf(SC6->C6_CF $ "5949 #6949","Outras Saidas","Faturamento")),;
			QC6->C9_NFISCAL})

		dbSelectArea("QC6")
		dbSkip()
	EndDo
	QC6->(dbClosearea())

	If lSofat == .F.

		oObj:IncRegua1("Localizando itens nใo liberados.")
		oObj:SetRegua2(0)

		cQri := ""
		cQri += "SELECT C6_QTDVEN,C6_ITEM,C6_PRODUTO,B1_DESC,B2_RESERVA,B2_QATU,C6_BLQ,C6_CF,C6_NOTA,"
		cQri += "       C6_PRCVEN,C6_PRUNIT "
		cQri += "  FROM " + RetSqlName("SC6") + " SC6, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SB2") + " SB2 "
		cQri += " WHERE SB2.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB2.B2_LOCAL = '01' "
		cQri += "   AND SB2.B2_COD = SC6.C6_PRODUTO "
		cQri += "   AND SB2.B2_FILIAL = '" + xFilial("SB2") + "' "
		cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB1.B1_COD = SC6.C6_PRODUTO "
		cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
		cQri += "   AND SC6.D_E_L_E_T_ = ' ' "
		cQri += "   AND SC6.C6_PRODUTO BETWEEN '               ' AND 'ZZZZZZZZZZZZZZZ'  "
		cQri += "   AND SC6.C6_ITEM BETWEEN '  ' AND 'ZZ' "
		cQri += "   AND SC6.C6_NUM = '" + cPed + "' "
		cQri += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' "

		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQri),'QC61', .F., .T.)

		Count to nRecCount

		oObj:SetRegua2(nREcCount+Len(aBlq))

		If nRecCount == 0
			QC61->(dbClosearea())
		Else
			aItems := aClone(aBlq)
			nLib := 0
			nVar  := 0
			Dbselectarea("QC61")
			dbgotop()
			ProcRegua(nReccount)
			While !Eof()
				oObj:IncRegua2("Processando itens "+QC61->C6_ITEM)
				For z := 1 To Len(aItems)
					If aItems[z,1] == QC61->C6_ITEM
						nVar := aItems[z,10]
						nLib += nVar
					Endif
					oObj:IncRegua2("Procurando..")
				Next

				If nLib < QC61->C6_QTDVEN
					cStatus := "A LIB"
					If Alltrim(QC61->C6_BLQ) == "R"
						cStatus	:= "RES"
					Endif
					Aadd(aBlq,{ QC61->C6_ITEM,;  			// 1
					"  ",;						// 2
					QC61->C6_PRODUTO,;			// 3
					QC61->B1_DESC,;				// 4
					Transform(QC61->B2_QATU - QC61->B2_RESERVA,"@E 999,999.99"),;	// 5
					Transform(QC61->C6_QTDVEN - nLib,"@E 999,999.99"),;	// 6
					cStatus ,;					// 7
					Transform(QC61->C6_PRCVEN,"@E 999,999.99"),;	// 8
					Transform((QC61->C6_QTDVEN - nLib) * QC61->C6_PRCVEN,"@E 999,999.99"),;	// 9
					QC61->C6_QTDVEN - nLib,;	// 10
					" ",;
						(QC61->C6_QTDVEN - nLib) * QC61->C6_PRCVEN,;	//	12
					qc61->C6_PRUNIT * (QC61->C6_QTDVEN - nLib),;				// 13
					(QC61->C6_QTDVEN - nLib),;					// 14
					Iif(QC61->C6_CF $ "5910 #6910","Bonificada",IIf(QC61->C6_CF $ "5949 #6949","Outras Saidas","Faturamento")),;
						QC61->C6_NOTA})
				Endif
				nLib := 0
				dbSelectArea("QC61")
				dbSkip()
			End
			QC61->(dbClosearea())
		Endif
	Endif


	If Len(aBlq) <= 0
		MsgAlert("Nใo houverem itens para esta situa็ใo","Aten็ใo!")
		Return
	Endif

	aSort(aBlq,,,{|x,y| x[1]+x[2] < y[1]+y[2]})

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Faz o calculo automatico de dimensoes de objetos     ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cPed)
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

	aSize := MsAdvSize()
	aObjects := {}
	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 015, .t., .f. } )
	aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects )
	aPosGet := MsObjGetPos(aSize[3]-aSize[1],315,{{003,033,160,200,240,263}} )
	nGetLin := aPosObj[3,1]

	DEFINE MSDIALOG oVendas TITLE OemToAnsi("Espelho do pedido "+cPed) From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

	EnChoice( "SC5", SC5->(Recno()), 2, , , , , aPosObj[1],,3,,,"",,,)

	//DEFINE MSDIALOG oVendas FROM 001,001 TO aSize[6] , aSize[5] OF oMainWnd PIXEL TITLE OemToAnsi("Espelho do pedido "+cPed)

	//aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4]
	@ aPosObj[2,1],aPosObj[2,2] LISTBOX oBlq VAR cBlq ;
		Fields HEADER ;
		"Item",;		// 1
	"Seq",;			// 2
	"C๓digo",;		// 3
	"Descri็ใo",;	// 4
	"Saldo Estoque",;// 5
	"Qtd Lib",;		// 6
	"Sts",;			// 7
	"Pre็o Venda",;	// 8
	"Total",;		// 9
	"Qte Lib",;		// 10
	"PosSC9",;      // 11
	"Tipo Faturamento",; //12
	"Nบ Nota";
		SIZE aPosObj[2,4],aPosObj[2,3]-aPosObj[2,1] OF oVendas PIXEL
	oBlq:SetArray(aBlq)
	oBlq:bLine:={ ||{aBlq[oBlq:nAT,01],aBlq[oBlq:nAT,02],aBlq[oBlq:nAT,03],aBlq[oBlq:nAT,04],aBlq[oBlq:nAT,05],;
		aBlq[oBlq:nAT,06],aBlq[oBlq:nAT,07],aBlq[oBlq:nAT,08],aBlq[oBlq:nAT,09],aBlq[oBlq:nAT,10],aBlq[oBlq:nAT,11],aBlq[oBlq:nAT,15],aBlq[oBlq:nAT,16]}}
	oBlq:Refresh()
	aButtons	:= {}
	aadd(aButtons,{"RELATORIO",{|| Impr()},"Imprime","Imprime Pedido"})
	aadd(aButtons,{"BUDGET",{||stResiduo(aBlq[oBlq:nAT,11]),oVendas:End()},"Residuo","Residuo do Item"  })
	aadd(aButtons,{"BUDGET",{||stVerLog(cPed)},"Ver Log","Ver logs do pedido"  })


	aDadosEnt	:= sfCalcRota(SC5->C5_TRANSP,SA1->A1_CEP,SA1->A1_ROTA)

	//{cStsRota,dData,cDiasFat,cPrzEnt}
	@ aPosObj[2,3]+10,160 Say aDadosEnt[3] color 183 of oVendas pixel
	@ aPosObj[2,3]+10,180 SAY aDadosEnt[1] color 183 border  of oVendas pixel
	@ aPosObj[2,3]+10,220 Say "Pr๓ximo Faturamento: " color 180 of oVendas pixel
	@ aPosObj[2,3]+10,275 SAY aDadosEnt[2] color 190 of oVendas pixel


	ACTIVATE msDIALOG oVendas ON INIT EnchoiceBar(oVendas,{|| oVendas:End()},{|| oVendas:End()},,aButtons) CENTERED


Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณBIG005LEG บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Retorna legenda do listbox                                 บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function BIG005LEG()

	Local	_nRet := 1

	If Len(aSC9) <= 0
		If oSc9:nAt > Len(aSC9)
			oSC9:nAt := Len(aSC9)
		Endif
		Return Nil
	Endif

	If oSc9:nAt > Len(aSC9)
		oSC9:nAt := Len(aSC9)
		Alert("Ajuste de tamanho do ListBox")
	ElseIf oSC9:nAt == 0 .And. Len(aSC9) > 0
		oSC9:nAt := 1
	Endif

	If	aSC9[oSc9:nAt,1] == 1
		_nRet	:= oVermelho
	ElseIf	aSC9[oSc9:nAt,1] == 2
		_nRet	:= oVerde
	ElseIf	aSC9[oSc9:nAt,1] == 3
		_nRet	:= oAmarelo
	ElseIf aSC9[oSc9:nAt,1] == 5
		_nRet	:= oCinza
	ElseIf aSC9[oSc9:nAt,1] == 6
		_nRet	:= oPink
	ElseIf aSC9[oSc9:nAt,1] == 7
		_nRet	:= oLaranja
	ElseIf aSC9[oSc9:nAt,1] == 8
		_nRet	:= oPreto
	Else
		_nRet	:= oAzul
	EndIf

Return(_nRet)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณBIG005PESQบAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Pesquisa variavel no listbox                               บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function BIG005PESQ

	Local	nAscan := Ascan(aSC9,{|x|x[3]==cVarPesq})

	If nAscan <=0
		nAscan	:= 1
	EndIF
	oSC9:nAT 	:= nAscan
	cVarPesq	:= space(06)
	oSC9:Refresh()
	oSC9:SetFocus()

Return(.t.)




/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณImpr      บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Chama impressใo de pedido                                  บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function Impr()

	If MsgYesNo("Imprime coluna com estoque?")
		ImpriTmk()
	Else
		ImpriCli()
	Endif

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณImpriTmk  บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Relat๓rio impressใo para formato com estoque               บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function ImpriTmk

	Private cDesc1  := "Este programa tem como objetivo imprimir relatorio "
	Private cDesc2  := "de acordo com os parametros informados pelo usuario."
	Private cDesc3  := "Espelho de pedido"
	Private cPict   := ""
	Private titulo  := "Espelho do pedido -> "+cPed
	Private nLin    := 80
	Private Cabec1  := ""
	Private Cabec2  := ""
	Private imprime := .T.
	Private aOrd    := {}

	Private lEnd        := .F.
	Private lAbortPrint := .F.
	Private limite      := 114
	Private tamanho     := "M"
	Private nomeprog    := "BIG005"
	Private nTipo       := 18
	Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey    := 0
	Private cPerg       := ""
	Private cbtxt       := Space(10)
	Private cbcont      := 00
	Private CONTFL      := 01
	Private m_pag       := 01
	Private wnrel       := "BIG005"
	Private cString     := ""

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Monta a interface padrao com o usuario...                           ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	wnrel := SetPrint(,NomeProg,,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

	If nLastKey == 27
		Return
	Endif

	SetDefault(aReturn,)

	If nLastKey == 27
		Return
	Endif

	nTipo := If(aReturn[4]==1,15,18)

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Processamento. RPTSTATUS monta janela com a regua de processamento. ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return


/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
	ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
	ฑฑบFuno    ณRUNREPORT บ Autor ณ AP6 IDE            บ Data ณ  10/02/03   บฑฑ
	ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
	ฑฑบDescrio ณ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS บฑฑ
	ฑฑบ          ณ monta a janela com a regua de processamento.               บฑฑ
	ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
	ฑฑบUso       ณ Programa principal                                         บฑฑ
	ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
	ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
	฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)
	Local nTot := 0.00
	Local lImpEst := .F.
	Local nGord := 0.00
	Local w,y
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Verifica o cancelamento pelo usuario...                             ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		//	Exit
	Endif

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Impressao do cabecalho do relatorio. . .                            ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	nLin++
	@nLin,020 PSAY "ESPELHO DE PEDIDO"
	nLin++
	nLin++

	dbSelectArea("SC5")
	dbSetOrder(1)
	dbSeek(xFilial("SC5")+cPed)
	dbselectarea("SA4")
	dbsetorder(1)
	dbseek(xFilial("SA4")+SC5->C5_TRANSP)


	dbSelectArea("SA1")
	dbSetOrder(1)
	dbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

	@nLin,000 PSAY "PEDIDO: " + SC5->C5_NUM + " - CIDADE: " + SA1->A1_MUN + " - ROTA: " + SC5->C5_TRANSP
	nLin++
	@nLin,000 Psay "CLIENTE: "+ SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+"  "+SA1->A1_NOME
	nLin++
	@nLin,000 Psay "TRANSP: "+SA4->A4_NREDUZ
	nLin++
	If SC5->C5_CONDPAG == '999'
		cDescPg	:= "CONDIวรO: NEGOCIADA/VENCIMENTOS -> "
		If !Empty(SC5->C5_DATA1)
			cDescPg += DTOC(SC5->C5_DATA1)
		Endif
		If !Empty(SC5->C5_DATA2)
			cDescPg	+= " / " + DTOC(SC5->C5_DATA2)
		Endif
		If !Empty(SC5->C5_DATA3)
			cDescPg	+= " / " + DTOC(SC5->C5_DATA3)
		Endif
		If !Empty(SC5->C5_DATA4)
			cDescPg	+= " / " + DTOC(SC5->C5_DATA4)
		Endif
		@nLin,000 Psay cDescPg
	Else
		aCond 	:= Condicao(1,SC5->C5_CONDPAG,0,SC5->C5_EMISSAO)
		cDescPg	:= "CONDIวรO: "+SC5->C5_CONDPAG+"-"+Posicione("SE4",1,xFilial("SE4")+SC5->C5_CONDPAG,"E4_DESCRI")
		cDescPg2 := ""
		For w := 1 To Len(aCond)
			If w < 4
				cDescPg	+= Iif(w > 1," / "," -> ") + DTOC(aCond[w,1])
			Else
				cDescPg2 += Iif(w > 1," / "," -> ") + DTOC(aCond[w,1])
			Endif
		Next
		@nLin,000 Psay cDescPg
		If !Empty(cDescPg2)
			nLin++
			@nLin,000 Psay cDescPg2
		Endif
	Endif
	nLin++

	If !Empty(lImpEst)
		@nLin,000 PSAY "MSGCLI: " + SA1->A1_OBSCLI
		nLin++
		@nLin,000 PSAY "MSGNF: " + SC5->C5_MENNOTA
		nLin++
		@nLin,000 PSAY "MSGINT: "+ SC5->C5_MSGINT
		nLin++
	Endif
	@nLin,000 Psay "ITEM"
	@nLin,007 Psay "CำDIGO"
	@nLin,023 Psay "DESCRIวรO PRODUTO"
	If !Empty(lImpEst)
		@nLin,064 Psay "SALDO EST"
	Endif
	@nLin,075 Psay "QUANTIDADE"
	@nLin,086 Psay "STATUS"
	@nLin,093 Psay "PREวO VENDA"
	@nLin,103 Psay "TOTAL ITEM"
	@nLin,114 Psay "PREวO UNIT."
	@nLin,125 Psay "GORDURA"
	nLin++
	@nLin,000 Psay repli("-",132)
	nLin++
	For y := 1 To Len(aBlq)
		@nLin,000 Psay Substr(aBlq[y,1],1,2)
		@nLin,003 Psay Substr(aBlq[y,2],1,2)
		@nLin,007 Psay Substr(aBlq[y,3],1,15)
		@nLin,023 Psay Substr(aBlq[y,4],1,40)
		If !Empty(lImpEst)
			@nLin,064 Psay Substr(aBlq[y,5],1,10)
		Endif
		@nLin,075 Psay Substr(aBlq[y,6],1,10)
		@nLin,086 Psay Substr(aBlq[y,7],1,5)
		@nLin,092 Psay Substr(aBlq[y,8],1,10)
		@nLin,103 Psay Substr(aBlq[y,9],1,10)
		@nLin,114 Psay Transform(aBlq[y,13]/aBlq[y,14],"@E 999,999.99")
		@nLin,125 Psay Transform((aBlq[y,12]-aBlq[y,13])/aBlq[y,13]*100,"@E 999.99")
		nLin++
		@nLin,000 Psay repli("-",132)
		@nLin++
		nVar1 := aBlq[y,12]
		nTot +=  nVar1
		nVar2 := (aBlq[y,12]-aBlq[y,13])
		nGord += nVar2
		If nLin > 62 // Salto de Pแgina. Neste caso o formulario tem 55 linhas...
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 8
		Endif
	Next

	@nLin,000 Psay "Total do pedido ---->>"
	@nLin,050 Psay Transform(nTot,"@E 999,999.99")
	nLin++
	@nLin,000 Psay "Gordura------------->>"
	@nLin,050 Psay Transform(nGord,"@E 999,999.99")
	nLin++
	@nLin,000 Psay "AVISO: SE GORDURA NEGATIVO, ULTRAPASSOU O LIMITE DE DESCONTO"
	Roda(0,"","M")
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Finaliza a execucao do relatorio...                                 ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	SET DEVICE TO SCREEN

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Se impressao em disco, chama o gerenciador de impressao...          ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif

	MS_FLUSH()

Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณImpriCli  บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Imprime relat๓rio no formato cliente                       บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static function ImpriCli


	Private cDesc1  := "Este programa tem como objetivo imprimir relatorio "
	Private cDesc2  := "de acordo com os parametros informados pelo usuario."
	Private cDesc3  := "Espelho de pedido"
	Private cPict   := ""
	Private titulo  := "Espelho do pedido -> "+cPed
	Private nLin    := 80
	Private Cabec1  := ""
	Private Cabec2  := ""
	Private imprime := .T.
	Private aOrd    := {}

	Private lEnd        := .F.
	Private lAbortPrint := .F.
	Private limite      := 80
	Private tamanho     := "P"
	Private nomeprog    := "BIG005"
	Private nTipo       := 18
	Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey    := 0
	Private cPerg       := ""
	Private cbtxt       := Space(10)
	Private cbcont      := 00
	Private CONTFL      := 01
	Private m_pag       := 01
	Private wnrel       := "BIG005"
	Private cString     := ""

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Monta a interface padrao com o usuario...                           ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	wnrel := SetPrint(,NomeProg,,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

	If nLastKey == 27
		Return
	Endif

	SetDefault(aReturn,)

	If nLastKey == 27
		Return
	Endif

	nTipo := If(aReturn[4]==1,15,18)

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Processamento. RPTSTATUS monta janela com a regua de processamento. ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	RptStatus({|| RunReport1(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return


/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
	ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
	ฑฑบFuno    ณRUNREPORT บ Autor ณ AP6 IDE            บ Data ณ  10/02/03   บฑฑ
	ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
	ฑฑบDescrio ณ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS บฑฑ
	ฑฑบ          ณ monta a janela com a regua de processamento.               บฑฑ
	ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
	ฑฑบUso       ณ Programa principal                                         บฑฑ
	ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
	ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
	฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
/*/

Static Function RunReport1(Cabec1,Cabec2,Titulo,nLin)
	Local nTot := 0.00
	Local w,y
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Verifica o cancelamento pelo usuario...                             ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		//	Exit
	Endif

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Impressao do cabecalho do relatorio. . .                            ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	nLin++
	@nLin,020 PSAY "ESPELHO DE PEDIDO"
	nLin++
	nLin++

	dbSelectArea("SC5")
	dbSetOrder(1)
	dbSeek(xFilial("SC5")+cPed)
	dbselectarea("SA4")
	dbsetorder(1)
	dbseek(xFilial("SA4")+SC5->C5_TRANSP)

	@nLin,000 PSAY "PEDIDO: " + SC5->C5_NUM + " - CIDADE: " + SA1->A1_MUN + " - ROTA: " + SC5->C5_TRANSP
	nLin++

	If SC5->C5_TIPO $ "D#B"
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		@nLin,000 Psay "CLIENTE: "+ SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+"  "+SA2->A2_NOME
	Else
		dbSelectArea("SA1")
		dbSetOrder(1)
		dbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		@nLin,000 Psay "CLIENTE: "+ SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+"  "+SA1->A1_NOME
	Endif

	nLin++
	@nLin,000 Psay "TRANSP: "+SA4->A4_NREDUZ
	nLin++
	If SC5->C5_CONDPAG == '999'
		cDescPg	:= "CONDIวรO: NEGOCIADA/VENCIMENTOS -> "
		If !Empty(SC5->C5_DATA1)
			cDescPg += DTOC(SC5->C5_DATA1)
		Endif
		If !Empty(SC5->C5_DATA2)
			cDescPg	+= " / " + DTOC(SC5->C5_DATA2)
		Endif
		If !Empty(SC5->C5_DATA3)
			cDescPg	+= " / " + DTOC(SC5->C5_DATA3)
		Endif
		If !Empty(SC5->C5_DATA4)
			cDescPg	+= " / " + DTOC(SC5->C5_DATA4)
		Endif
		@nLin,000 Psay cDescPg
	Else
		aCond 	:= Condicao(1,SC5->C5_CONDPAG,0,SC5->C5_EMISSAO)
		cDescPg	:= "CONDIวรO: "+SC5->C5_CONDPAG+"-"+Posicione("SE4",1,xFilial("SE4")+SC5->C5_CONDPAG,"E4_DESCRI")
		cDescPg2 := ""
		For w := 1 To Len(aCond)
			If w < 4
				cDescPg	+= Iif(w > 1," / "," -> ") + DTOC(aCond[w,1])
			Else
				cDescPg2 += Iif(w > 1," / "," -> ") + DTOC(aCond[w,1])
			Endif
		Next
		@nLin,000 Psay cDescPg
		If !Empty(cDescPg2)
			nLin++
			@nLin,000 Psay cDescPg2
		Endif
	Endif
	nLin++
	@nLin,000 Psay "CำDIGO"
	@nLin,013 Psay "DESCRIวรO PRODUTO"
	@nLin,051 Psay "QTDE"
	@nLin,056 Psay "STS"
	@nLin,062 Psay "R$ VENDA"
	@nLin,074 Psay "TOTAL"
	nLin++
	@nLin,000 Psay repli("-",080)
	nLin++
	For y := 1 To Len(aBlq)
		@nLin,000 Psay Substr(aBlq[y,3],1,13)
		@nLin,013 Psay Substr(aBlq[y,4],1,34)
		@nLin,048 Psay Substr(aBlq[y,6],1,7)
		@nLin,056 Psay Substr(aBlq[y,7],1,5)
		@nLin,060 Psay Substr(aBlq[y,8],1,10)
		@nLin,070 Psay Substr(aBlq[y,9],1,10)
		nLin++
		@nLin,000 Psay repli("-",080)
		@nLin++
		nVar1 := aBlq[y,12]
		nTot +=  nVar1
		If nLin > 62 // Salto de Pแgina. Neste caso o formulario tem 55 linhas...
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 8
		Endif
	Next

	@nLin,000 Psay "Total do pedido ---->>"
	@nLin,050 Psay Transform(nTot,"@E 999,999.99")
	nLin++
	Roda(0,"","P")
	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Finaliza a execucao do relatorio...                                 ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	SET DEVICE TO SCREEN

	//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
	//ณ Se impressao em disco, chama o gerenciador de impressao...          ณ
	//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif

	MS_FLUSH()

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณBIG005B   บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Bloqueio de pedido                                         บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function BIG005B()

	Local 	oPed2
	Local	cMensagem := cRecebe := cAssunto := ""
	Local	cMotBlq	:= Space(100)
	Local	cPed    := aSC9[oSc9:nAt,3]
	Local	aChoice := {"     ","BLOQUEAR","LIBERAR","PGTO ANTECIPADO"}
	Local 	cTipoop := Space(5)

	DEFINE MSDIALOG oPed2 FROM 000,000 TO 180,370 OF oMainWnd PIXEL TITLE OemToAnsi("Bloq/Liber pedido-> "+ cPed + "?")
	@ 020,010 Say "Tipo de Opera็ใo" of oPed2 pixel
	@ 020,80 MsCOMBOBOX cTipoop ITEMS aChoice Size 60,10  of oPed2 pixel
	@ 035,010 Say "Motivo Bloqueio/Libera็ใo" of oPed2 Pixel
	@ 035,080 MsGet cMotBlq	Size 100,10 of oPed2 Pixel
	@ 070,040 BUTTON "&Avan็a" of oPed2 pixel SIZE 40,15 ACTION (oPed2:End() )
	@ 070,090 BUTTON "&Cancela" of oPed2 pixel SIZE 40,15 ACTION (cMotBlq := "", oPed2:End() )

	ACTIVATE msDIALOG oPed2 CENTERED

	If cTipoop == "BLOQUEAR"

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9") + " SET C9_FLGENVI = 'F' "
		cQru += "WHERE D_E_L_E_T_ = ' ' "
		cQru += "AND C9_PEDIDO ='" +cPed+ "' AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5")
		cQru += " SET C5_BLPED = 'F' "
		cQru += "    ,C5_MSGEXP = '"+Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])+"' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_NUM ='" +cPed+ "' "
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5")
		cQru += " SET C5_BLPED = 'F' "
		cQru += "    ,C5_MSGEXP = '"+Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])+"' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_NUM ='" +cPed+ "' "
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "

		cRecebe		:= GetMv("GM_FINMAIL")

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cPed)
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")


		cAssunto 	:= "Pedido "+ cPed + " bloqueado pelo financeiro."
		cMensagem	:= "O usuแrio '" + AllTrim(  UsrFullName(RetCodUsr()) ) + "' " +Chr(13)+Chr(10)+;
			"bloqueou o pedido do cliente do cliente: " +;
			AllTrim( aSC9[oSc9:nAt,5]) +;
			"no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Valor Liberado: " + aSC9[oSC9:nAt,9]
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Mensagem Interna: "+aSC9[oSC9:nAt,13]
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem	+= "Empresa: "+SM0->M0_NOMECOM

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(RetCodUsr())) + Chr(13)+Chr(10) + "Bloqueado:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
		MsUnlock()

		// IAGO 27/10/2015 Chamado(12912)
		// Adicionado WF para nova modalidade de vendedor ativo
		If SA1->(FieldPos("A1_VEND03"))<> 0 .And. !Empty(SA1->A1_VEND03)
			dbSelectArea("SA3")
			dbSetOrder(1)
			If dbSeek(xFilial("SA3")+SA1->A1_VEND03)
				cRecebe += IIf(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
			EndIf
		EndIF

		// Grava Log
		U_GMCFGM01("BF",SC5->C5_NUM,cMensagem,FunName())

		stSendMail( cRecebe, cAssunto, cMensagem )

		stRefresh()	// For็a atualiza็ใo da TEla

	ElseIf  cTipoop == "PGTO ANTECIPADO"

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = 'F' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_PEDIDO ='" +cPed+ "' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		TCSQLExec(cQru)



		cRecebe		:= GetMv("GM_FINMAIL")
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cPed)

		cBkC5Cond	:= SC5->C5_CONDPAG + "|" + SC5->C5_BANCO + "|" + Iif(SC5->C5_XMENOTA == Nil ,'',SC5->C5_XMENOTA)
		RecLock("SC5",.F.)
		SC5->C5_BLPED	:= "F"
		SC5->C5_BANCO	:= "987"
		SC5->C5_CONDPAG	:= "099"
		SC5->C5_MSGEXP 	:= Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])
		SC5->C5_XMENOTA	:= cBkC5Cond
		MsUnlock()

		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")


		cAssunto 	:= "Pedido "+ cPed + " bloqueado pelo financeiro."
		cMensagem	:= "O usuแrio '" + AllTrim(  UsrFullName(RetCodUsr()) ) + "' " +Chr(13)+Chr(10)+;
			"bloqueou o pedido do cliente do cliente: " +;
			AllTrim( aSC9[oSc9:nAt,5]) +;
			"no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Valor Liberado: " + aSC9[oSC9:nAt,9]
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Mensagem Interna: "+aSC9[oSC9:nAt,13]
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: 'PAGAMENTO ANTECIPADO' e " + cMotBlq
		cMensagem 	+= Chr(13)+Chr(10) + " Condi็ใo pagamento alterada para 099-Pagto Antecipado e Banco para 987-Pagamento Antecipado"
		cMensagem   += Chr(13)+Chr(10)
		cMensagem	+= "Empresa: " + SM0->M0_NOMECOM

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(RetCodUsr())) + Chr(13)+Chr(10) + "Bloqueado:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
		MsUnlock()

		// IAGO 27/10/2015 Chamado(12912)
		// Adicionado WF para nova modalidade de vendedor ativo
		If SA1->(FieldPos("A1_VEND03"))<> 0 .And. !Empty(SA1->A1_VEND03)
			dbSelectArea("SA3")
			dbSetOrder(1)
			If dbSeek(xFilial("SA3")+SA1->A1_VEND03)
				cRecebe += IIf(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
			EndIf
		EndIF

		// Grava Log
		U_GMCFGM01("BA",SC5->C5_NUM,cMensagem,FunName())

		stSendMail( cRecebe, cAssunto, cMensagem )

		stRefresh()

	Elseif  cTipoop == "LIBERAR"

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = ' ' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_PEDIDO ='" +cPed+ "' "
		cQru += "   AND C9_FLGENVI != 'P' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5") + " SET C5_BLPED = CASE WHEN C5_BLPED IN('F','P') THEN ' ' ELSE C5_BLPED END "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_NUM ='" +cPed+ "' "
		cQru += "   AND C5_BLPED NOT IN('P','T') "
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cRecebe		:= GetMv("GM_FINMAIL")
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cPed)
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")



		cAssunto 	:= "Pedido "+ cPed + " liberado pelo financeiro."
		cMensagem	:= "O usuแrio '" + AllTrim(  UsrFullName(RetCodUsr()) ) + "' " +Chr(13)+Chr(10)+;
			"liberou o pedido do cliente do cliente : " +;
			AllTrim( aSC9[oSc9:nAt,5]) +;
			"no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Valor Liberado: " + aSC9[oSC9:nAt,9]
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Mensagem Interna: "+aSC9[oSC9:nAt,13]
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem	+= "Empresa: " + SM0->M0_NOMECOM

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(RetCodUsr())) + Chr(13)+Chr(10) + "Liberado:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
		MsUnlock()

		// IAGO 27/10/2015 Chamado(12912)
		// Adicionado WF para nova modalidade de vendedor ativo
		If SA1->(FieldPos("A1_VEND03"))<> 0 .And. !Empty(SA1->A1_VEND03)
			dbSelectArea("SA3")
			dbSetOrder(1)
			If dbSeek(xFilial("SA3")+SA1->A1_VEND03)
				cRecebe += IIf(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
			EndIf
		EndIF

		// Grava Log
		U_GMCFGM01("LA",SC5->C5_NUM,cMensagem,FunName())

		stSendMail( cRecebe, cAssunto, cMensagem )

		If MsgYesNo("Deseja alterar o cabe็alho do Pedido restaurando a condi็ใo de pagamento e banco? ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			U_BIG017(cPed,0)
		Endif
		stRefresh()	// For็a atualiza็ใo da TEla

		cVarPesq := cPed // Atribui variavel de pesquisa
		BIG005PESQ()     // Localiza pedido liberado
		//InverteSC9()	 // Marca pedido

	Endif


Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfTmkObs  บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Interface para adicionar informa็๕es ao pedido             บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfTmkObs()

	Local 	oPed2
	Local	cMensagem := cRecebe := cAssunto := ""
	Local	cMotBlq	:= Space(30)
	Local	cPed    := aSC9[oSc9:nAt,3]


	DEFINE MSDIALOG oPed2 FROM 000,000 TO 180,370 OF oMainWnd PIXEL TITLE OemToAnsi("Observa็ใo TMK para o pedido-> "+ cPed )
	@ 035,010 Say "Observa็ใo" of oPed2 Pixel
	@ 035,080 MsGet cMotBlq	Size 100,10 of oPed2 Pixel
	@ 070,040 BUTTON "&Avan็a" of oPed2 pixel SIZE 40,15 ACTION (oPed2:End() )
	@ 070,090 BUTTON "&Cancela" of oPed2 pixel SIZE 40,15 ACTION (cMotBlq := "", oPed2:End() )

	ACTIVATE msDIALOG oPed2 CENTERED

	If !Empty(cMotBlq)
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cPed)
		cMotBlq	:= Alltrim(cMotBlq) +"|"+ SC5->C5_MSGEXP
		RecLock("SC5",.F.)
		SC5->C5_MSGEXP	:= Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])
		MsUnlock()

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(RetCodUsr())) + Chr(13)+Chr(10) + "ObsTmk:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
		MsUnlock()

		aSC9[oSc9:nAt,14]	:= Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])

	Endif

Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfResAll  บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Eliminar residuos de pedidos selecionados em Loop          บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfResAll()

	Local	cMotBlq	:= Space(150)
	Local	lAchou	:= .F.
	Local	x
	For x:= 1 To Len(aSC9)
		If aSC9[x,2]
			stResiduo(,aSC9[x,3],.F.,@cMotBlq)
			lAchou	:= .T.
		Endif

	Next
	If !lAchou
		stResiduo(,aSC9[oSc9:nAt,3],.F.,@cMotBlq)
	Endif
	stRefresh()

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณstResiduo บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Eliminar residuo de pedido                                 บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function stResiduo(cC9POS,cPedRes,lRefresh,cMotBlq)

	Local 	aAreaOld	:= GetArea()
	Local 	lAllEst		:= cC9POS <> Nil
	Default	cPedRes	    :=  aSC9[oSc9:nAt,3]
	Default lRefresh	:= .T.

	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cPedRes)
	If SC5->C5_BLPED $ "S"
		MsgAlert("Pedido enviado ao Faturamento! Nใo ้ permitida a elimina็ใo de resํduos!","Rotina negada!")
		RestArea(aAreaOld)
		Return
	Endif


	If !lAllEst

		If MsgYesNo("Confirma o Estorno da libera็ใo para todos os itens liberados do pedido para elimina็ใo de resํduo?","Aten็ใo!")
			// Grava Log
			// GMCFGM01(cTipo,cPedido,cObserv,cResp,lBtnCancel,cMotDef)
			cMotBlq	:= U_GMCFGM01("ER",cpedRes,,FunName(),,cMotBlq)[1]

			DbSelectArea("SC6")
			DbSetOrder(1)
			DbGotop()
			DbSeek(xFilial("SC6")+cPedRes)
			While !Eof() .And. SC6->C6_NUM == cPedRes
				RecLock("SC6",.F.)
				SC6->C6_BLQ 	:= " "
				MsUnlock()
				DbSelectArea("SC6")
				dbSkip()
			EndDo


			DbSelectArea("SC9")
			DbSetOrder(1)
			DbGotop()
			DbSeek(xFilial("SC9")+cPedRes)
			While !Eof() .And. SC9->C9_PEDIDO == cPedRes

				If SC9->C9_BLEST <> "10" .And. SC9->C9_BLCRED <> "10" //.And. !(Alltrim(SC9->C9_FLGENVI) $ "E")
					DbSelectArea("SC6")
					DbSetOrder(1)
					If DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM)
						a460Estorna()
					Endif
				EndIf
				DbSelectArea("SC9")
				dbSkip()
			EndDo
		Endif

	ElseIf !Empty(cC9POS)
		DbSelectArea("SC9")
		DbSetOrder(1)
		DbSeek(cC9POS)
		If !Eof()
			If MsgYesNo("Confirma o Estorno da libera็ใo para o iten selecionado do pedido para elimina็ใo de resํduo?","Aten็ใo!")
				// Grava Log
				U_GMCFGM01("ER",Substr(cC9POS,1,6),,FunName())

				If SC9->C9_BLEST <> "10" .And. SC9->C9_BLCRED <> "10" //.And. !(Alltrim(SC9->C9_FLGENVI) $ "E")
					DbSelectArea("SC6")
					DbSetOrder(1)
					If DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM)
						RecLock("SC6",.F.)
						SC6->C6_BLQ 	:= "N"
						MsUnlock()
						a460Estorna()
						MsgAlert("Estorno da libera็ใo do item efetuada! Favor selecionar somente este produto na Tela de residuos!!","A T E N ว ร O !!!")
					Endif
				EndIf
			Endif
		Endif
	Else
		RestArea(aAreaOld)
		Return
	Endif

	cPerg := PADR("MTA500",Len("X1_GRUPO"))

	U_GravaSX1(cPerg,"01",100)
	U_GravaSX1(cPerg,"02",CTOD("  /  /   "))
	U_GravaSX1(cPerg,"03",dDataBase	+7)
	U_GravaSX1(cPerg,"04",cPedRes)
	U_GravaSX1(cPerg,"05",cPedRes)
	U_GravaSX1(cPerg,"06",1)
	U_GravaSX1(cPerg,"07"," ")
	U_GravaSX1(cPerg,"08","ZZZ")
	U_GravaSX1(cPerg,"09",1)
	U_GravaSX1(cPerg,"10",CTOD("  /  /   "))
	U_GravaSX1(cPerg,"11",dDataBase+30)

	Mata500()

	If lRefresh
		stRefresh()
	Endif


	RestArea(aAreaOld)

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณstSendMailบAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Envio de email                                             บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function stSendMail( cMailTo, cAssunto, cMensagem)

	Local	aAreaOld 		:= GetArea()
	Local 	lOk 		:= .F.
	Local	lAutOk 		:= .F.
	Local	lSendOk 	:= .T.

	Local cMailServer := AllTrim(GetNewPar("MV_RELSERV"," "))        // Servidor utilizado para envio do e-mail
	Local cMailConta  := AllTrim(GetNewPar("MV_RELACNT"," "))        // Conta utilizada para envio
	Local cMailSenha  := AllTrim(GetNewPar("MV_RELPSW" ," "))        // Senha da conta de envio
	Local lSmtpAuth   := GetNewPar("MV_RELAUTH", .F.)                // Verifica se deve realizar autentica็ใo
	Local nTimeOut    := GetNewPar("MV_RELTIME", 120)                // Tempo de Espera antes de abortar a Conexใo
	Local cUserAut    := Alltrim(GetNewPar("MV_RELAUSR",cMailConta)) // Usuแrio para Autentica็ใo no Servidor de Email
	Local cSenhAut    := Alltrim(GetNewPar("MV_RELAPSW",cMailSenha)) // Senha para Autentica็ใo no Servidor de Email
	Local lRetMail 		:= .T.

	// Campos a serem repassados no e-mail
	Default cMailTo   := Space(20)
	Default cAssunto  := Space(20)
	Default cMensagem := Space(20)

	cMailTo := U_BFFATM15(cMailTo,"BIG005")


	CONNECT SMTP SERVER cMailServer ACCOUNT cMailConta PASSWORD cMailSenha TIMEOUT nTimeOut RESULT lOk

// Valida existencia de campos necessarios para o envio do e-mail
	If !Empty(cMailServer) .And. !Empty(cMailConta)
		// Verifica autentica็ใo no servidor descrito, se necessario
		If !lAutOk
			If lSmtpAuth
				If !(lAutOk := MailAuth(cUserAut,cSenhAut))
					cMsgSend := "Falha na autentica็ใo do usuแrio no provedor de e-mail"
					lRetMail := .F.
				Endif
			Else
				lAutOk := .T.
			EndIf
		EndIf

		If lRetMail // Caso a autentica็ใo tenha sido efetuada corretamente.
			If lOk  // Caso a conexao com o servidor, esteja estabelecida, e possibilite o envio do e-mail
				SEND MAIL FROM cMailConta TO cMailTo  SUBJECT cAssunto BODY cMensagem RESULT lSendOk  // Efetua envio do e-mail

				If !lSendOk
					Get MAIL ERROR cError // Verifica erro indicado pelo servidor, no ato do envio do e-mail
				Endif

				// Armazena informa็๕es para retorno
				cMsgSend := If(lSendOk, "E-mail enviado com sucesso!", cError) // "E-mail enviado com sucesso!"
				lRetMail := lSendOk
			Else
				cMsgSend := "Erro na conexใo com o servidor SMTP." + CHR(13) + CHR(10) + ; // "Erro na conexใo com o servidor SMTP."
				"Verifique configura็๕es e autentica็๕es do servidor de e-mail." // "Verifique configura็๕es e autentica็๕es do servidor de e-mail."
				lRetMail := .F.
			EndIf
		Endif

		DISCONNECT SMTP SERVER // Finaliza conexao com servidor de e-mail
	Else
		cMsgSend := "As configura็๕es para o acesso ao servidor de e-mail estใo incorretas." + CHR(13) + CHR(10) + ; // "As configura็๕es para o acesso ao servidor de e-mail estใo incorretas."
		"Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW" // "Verifique os parametros MV_RELSERV, MV_RELACNT e MV_RELPSW"
		lRetMail := .F.
	EndIf

	RestArea(aAreaOld)

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfCalcRotaบAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Calcula rota para a tela de espelho de pedido              บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfCalcRota(cCodTransp,cCEP,cA1_ROTA)


	Local	cStsRota 	:= Space(10)
	Local	cRota		:=" "
	Local	nDiaAtu  	:= 0
	Local	nDiaEnt  	:= 0
	Local	dData    	:= dDataBase
	Local	aRota    	:= {}
	Local	aDias    	:= {1,2,3,4,5,6,7}
	Local	cDiasFat 	:= "     "
	Local	cPrzEnt	:= "      "
	Local	x

	Dbselectarea("SA4")
	dbsetorder(1)
	Dbseek(xFilial("SA4")+cCodTransp)

	dbSelectArea("PAB")
	dbSetOrder(1)
	If DbSeek(xFilial("PAB")+cCEP)
		For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
			AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
		Next
		cDiasFat := PAB->PAB_ROTA
		cPrzEnt  := PAB->PAB_PRAZO
	Endif

	If cA1_ROTA <> Nil .And. cA1_ROTA <> " "
		For x := 1 To Len(AllTrim(QRG->A1_ROTA)) Step 1
			AADD(aRota,{SubStr(cA1_ROTA,x,1)})
		Next
	Endif

	nDia := Dow(dDatabase)
	If Len(aRota) > 0
		While .T.
			If nDia > 7
				nDia := 1
			Endif
			nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
			If !Empty(nPos)
				nDiaEnt := Val(aRota[nPos][1])
				If nDiaEnt == Dow(dDatabase)
					dData := dDatabase
				Elseif (nDiaEnt - Dow(dDatabase)) > 0
					dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
				Else
					dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
				Endif
				Exit
			Endif
			nDia++
		End
	Endif

	If dData == dDatabase
		cStsRota := "ษ ROTA"
	Else
		cStsRota := "NรO ษ ROTA"
	Endif

Return {cStsRota,dData,cDiasFat,cPrzEnt}


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfLibMt450บAutor  ณMarcelo Lauschner   บ Data ณ 18/06/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Interface para analise de credito do cliente               บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/


Static Function sfLibMt450(lInDireto)

	Local	aAreaOld	:= GetArea()
	Local 	oPed2
	Local	cMensagem 	:= cRecebe := cAssunto := ""
	Local	cMotBlq	:= "Titulos Vencidos " + Space(100)
	Local	cPed    	:= SC9->C9_PEDIDO
	Local	nReturn	:= 0
	Local 	lContinua	:= .T.
	Local	dLimLib	:= dDataBase
	Private aRotina 	:= {{"Pesquisar","PesqBrw"	, 0 , 1,0,.F.},;	// "Pesquisar"
	{"Automatica","A450LibAut", 0 , 0,0,NIL},;	// "Autom tica"
	{"Manual","A450LibMan", 0 , 0,0,NIL},;	// "Manual"
	{"Legenda","A450Legend", 0 , 3,0,.F.}}	// "Legenda"Private aRotina		:= {}
	Default lInDireto		:= .F.


	DbSelectArea("SC5")
	DbSetOrder(1)
	MsSeek(xFilial("SC5")+cPed)

	DbSelectArea("SA1")
	DbSetOrder(1)
	MsSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

	If lInDireto
		// Grava Log
		U_GMCFGM01("LC",cPed,cMensagem,FunName())

		// Crio variavel necessแria para funcionamento da rotina
		bFiltraBrw	:= {|| .T.}
		// Chamo fun็ใo de libera็ใo do cr้dito do pedido
		A450LibMan()

		Return
	Endif


	DEFINE MSDIALOG oPed2 FROM 000,000 TO 180,470 OF oMainWnd PIXEL TITLE OemToAnsi("Libera็ใo do Pedido ou Transfer๊ncia de Bloqueio do pedido -> "+ cPed + " ")
	@ 015,010 Say "Motivo Bloqueio para Pend๊ncia" of oPed2 Pixel
	@ 022,010 MsGet cMotBlq	Size 150,10 of oPed2 Pixel Valid (Len(Alltrim(cMotBlq)) > 10 )
	@ 050,035 Button "Analise Cliente Sem Libera็ใo" of oPed2 Pixel Size 100,10 Action(a450Tela( @lContinua , .T. , .F.,@dLimLib))
	@ 050,140 BUTTON "Cancela" of oPed2 pixel SIZE 50,10 ACTION (oPed2:End())
	@ 070,010 BUTTON "&Pend๊ncia TMK" of oPed2 pixel SIZE 50,10 ACTION (nReturn :=  2,oPed2:End() )
	@ 070,065 BUTTON "&Suspensใo Financeira" of oPed2 pixel SIZE 50,10 ACTION (nReturn := 1,oPed2:End() )
	@ 070,120 BUTTON "&Rejei็ใo " of oPed2 pixel SIZE 50,10 ACTION (nReturn := 3, oPed2:End() )
	@ 070,175 BUTTON "&Libera " of oPed2 pixel SIZE 50,10 ACTION (nReturn := 4, oPed2:End() )

	ACTIVATE msDIALOG oPed2 CENTERED

	If nReturn == 1

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = 'P' "
		cQru += "      ,C9_BLOQUEI = CASE WHEN C9_BLCRED = '09' THEN C9_BLOQUEI ELSE C9_BLCRED END "
		cQru += "      ,C9_BLCRED = '09' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_PEDIDO = '"+cPed+"' "
		cQru += "	AND C9_BLCRED<>'  ' "
		cQru += "	AND C9_BLCRED<>'10' "
		cQru += "	AND C9_BLCRED<>'ZZ' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5")
		cQru += "   SET C5_BLPED = 'P' "
		cQru += "    ,C5_MSGEXP = '"+Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])+"' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_NUM = '"+cPed+"' "
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cRecebe		:= GetMv("GM_FINMAIL")

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cPed)
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)

		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")


		cAssunto 	:= "Pedido(s) suspenso(s) pelo financeiro."
		cMensagem	:= "O usuแrio '" + AllTrim(  UsrFullName(RetCodUsr()) ) + "' " +Chr(13)+Chr(10)+;
			"suspendou os pedidos do cliente: " +;
			AllTrim(SA1->A1_COD+"/"+SA1->A1_LOJA + " " + SA1->A1_NOME) +;
			" no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem 	+= "Solu็ใo do Problema por conta do Financeiro! "
		cMensagem   += Chr(13)+Chr(10)
		cMensagem	+= "Empresa: "+SM0->M0_NOMECOM

		DbSelectArea("SA1")
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(RetCodUsr())) + Chr(13)+Chr(10) + "Pend.Fin:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
		MsUnlock()

		// Grava Log
		U_GMCFGM01("BF",cPed,cMensagem,FunName())

		stSendMail( cRecebe, cAssunto, cMensagem )
	ElseIf nReturn == 2

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = 'T' "
		cQru += "      ,C9_BLOQUEI = CASE WHEN C9_BLCRED = '09' THEN C9_BLOQUEI ELSE C9_BLCRED END "
		cQru += "      ,C9_BLCRED = '09' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_PEDIDO ='" +cPed+ "' "
		cQru += "	AND C9_BLCRED<>'  ' "
		cQru += "	AND C9_BLCRED<>'10' "
		cQru += "	AND C9_BLCRED<>'ZZ' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5")
		cQru += "   SET C5_BLPED = 'T' "
		cQru += "    ,C5_MSGEXP = '"+Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])+"' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_NUM = '"+cPed+"' "
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cRecebe		:= GetMv("GM_FINMAIL")

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cPed)
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)
		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")


		cAssunto 	:= "Pedido(s) suspenso(s) pelo financeiro."
		cMensagem	:= "O usuแrio '" + AllTrim(  UsrFullName(RetCodUsr()) ) + "' " +Chr(13)+Chr(10)+;
			"suspendou os pedidos do cliente: " +;
			AllTrim(SA1->A1_COD+"/"+SA1->A1_LOJA + " " + SA1->A1_NOME) +;
			" no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem 	+= "Solu็ใo do Problema por conta do setor Telemarketing/Comercial! "
		cMensagem   += Chr(13)+Chr(10)
		cMensagem	+= "Empresa: "+SM0->M0_NOMECOM

		DbSelectArea("SA1")
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(RetCodUsr())) + Chr(13)+Chr(10) + "Pend.Tmk:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
		MsUnlock()
		// Grava Log
		U_GMCFGM01("BT",cPed,cMensagem,FunName())

		stSendMail( cRecebe, cAssunto, cMensagem )

	ElseIf nReturn == 3

		DbSelectArea("SC9")
		DbSetOrder(1)
		DbSeek(xFilial("SC9")+cPed)
		While !Eof() .And. SC9->C9_FILIAL == xFilial("SC9") .And. SC9->C9_PEDIDO == cPed

			//a450Grava(2,.T.,.F.)
			RecLock("SC9",.F.)
			SC9->C9_BLCRED 	:= "09"
			SC9->C9_BLOQUEI	:= "  "
			SC9->C9_FLGENVI	:= " "
			DbSelectArea("SC9")
			DbSkip()
		Enddo

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cPed)
		RecLock("SC5",.F.)
		SC5->C5_MSGEXP 	:= Padr(Substr(DTOS(dDatabase),7,2)+"/"+Substr(DTOS(dDatabase),5,2) + "-" + cMotBlq,TamSX3("C5_MSGEXP")[1])
		SC5->C5_BLPED	:= " "
		MsUnlock()

		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+SC5->C5_VEND1)

		cRecebe		:= GetMv("GM_FINMAIL")
		cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
		cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
		cRecebe += Iif(!Empty(SA3->A3_MENS1),";"+SA3->A3_MENS1,"")

		cAssunto 	:= "Pedido "+ cPed + " rejeitado pelo financeiro."
		cMensagem	:= "O usuแrio '" + AllTrim(  UsrFullName(RetCodUsr()) ) + "' " +Chr(13)+Chr(10)+;
			"rejeitou o pedido do cliente: " +;
			AllTrim(SA1->A1_COD+"/"+SA1->A1_LOJA + " " + SA1->A1_NOME) +;
			" no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem	+= "Empresa: "+SM0->M0_NOMECOM
		DbSelectArea("SA1")
		cA1MemoObs	:= SA1->A1_OBSMEMO
		RecLock("SA1",.F.)
		SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(RetCodUsr())) + Chr(13)+Chr(10) + "Rejei็ใo:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
		MsUnlock()
		// Grava Log
		U_GMCFGM01("LR",cPed,cMensagem,FunName())

		stSendMail( cRecebe, cAssunto, cMensagem )

	ElseIf nReturn == 4 // Libera Todos

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = ' ' "
		cQru += "      ,C9_BLCRED = C9_BLOQUEI "
		cQru += "      ,C9_BLOQUEI = '  '"
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_PEDIDO ='" +cPed+ "' "
		cQru += "   AND C9_BLOQUEI != '  ' "
		cQru += "   AND C9_BLCRED = '09' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC5")
		cQru += "   SET C5_BLPED = ' ' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C5_NUM ='" +cPed+ "' "
		cQru += "   AND C5_FILIAL = '" + xFilial("SC5") +"'  "
		Begin Transaction
			TCSQLExec(cQru)
		End Transaction

		cMensagem	:= "O usuแrio '" + AllTrim(  UsrFullName(RetCodUsr()) ) + "' " +Chr(13)+Chr(10)+;
			"Liberou o pedido do cliente: " +;
			AllTrim(SA1->A1_COD+"/"+SA1->A1_LOJA + " " + SA1->A1_NOME) +;
			" no dia " + Dtoc( Date() ) + " as " + Time() + ". "
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= Chr(13)+Chr(10)
		cMensagem 	+= "Motivo: " + cMotBlq
		cMensagem   += Chr(13)+Chr(10)
		cMensagem	+= "Empresa: "+SM0->M0_NOMECOM

		// Grava Log
		U_GMCFGM01("LC",cPed,cMensagem,FunName())

		// Crio variavel necessแria para funcionamento da rotina
		bFiltraBrw	:= {|| .T.}
		// Chamo fun็ใo de libera็ใo do cr้dito do pedido
		A450LibMan()

	Endif

	RestArea(aAreaOld)

Return nReturn


Static Function stVerLog(cInPedido)

	Private cPedSZ0		:= cInPedido

	dbSelectArea("SZ0")
	dbSetOrder(1)
	Set Filter To Z0_PEDIDO == cPedSZ0 .And. Z0_FILIAL == xFilial("SZ0")

	AxCadastro("SZ0","Historico Pedido - Workflow",".F.",".F.")

	dbSelectArea("SZ0")
	dbSetOrder(1)
	Set Filter To

Return
