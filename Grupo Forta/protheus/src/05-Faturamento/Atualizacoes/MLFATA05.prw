#include "topconn.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"


/*/{Protheus.doc} MLFATA05
(Rotina de impressão das Notas Fiscais e boletos)
@author MarceloLauschner
@since 04/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MLFATA05()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis (NOVAS)                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local	lContinua	:= .F.
	Local	lSaida		:= .F.
	Local	aButtons	:= {}
	Local 	nf
	Private aBanco		:= {}
	Private cMarca
	Private oSC9,oBancoImp
	Private nSele 		:= 0.00
	Private oSele
	Private cBancoimp   := Space(8)
	Private cLocimp     := "F"
	Private cTipo		:= "IMPRESSAO"
	Private cPrintBol	:= "SIM"
	Private nBolPg		:= 0
	Private oVermelho	:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	Private oAzul 		:= LoaDbitmap( GetResources(), "BR_AZUL" )
	Private oCinza		:= LoaDbitmap( GetResources(), "BR_CINZA" )
	Private oAmarelo	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private oPreto		:= LoadBitmap( GetResources(), "BR_PRETO")
	Private oMarrom		:= LoadBitmap( GetResources(), "BR_MARROM")
	Private oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Private oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	Private oBranco    	:= LoadBitmap( GetResources(), "BR_BRANCO" )
	Private aSC9		:= {}
	Private cSc9		:= ""
	Private cVarPesq	:= space(6)
	Private cTranspIni  := Space(6)
	Private cTranspFin  := "ZZZZZZ"
	Private dDatafat 	:= ddatabase
	Private cSerie 		:= Padr(GetNewPar("GF_SERIENF","1"),TamSX3("F2_SERIE")[1])
	Private dDatasai 	:= ddatabase
	Private aSize 		:= MsAdvSize(,.F.,400)
	Private nOpcLoc		:= 0
	Private nOpcNfe		:= 0
	Private lIsUsrLib 	:= RetCodUsr() $ GetNewPar("GF_MFTA5UR","000000") // Id de usuários liberados para Transmissão e impressão de notas e boletos
	Private aRecSF2		:= {}

	If lIsUsrLib
		lIsUsrLib	:= !MsgYesNo("Deseja usar a tela como perfil de Expedição só para impressão de Notas para separação? ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
	Endif

	DEFINE DIALOG oDlgA FROM 000,000 TO 160,400 OF oMainWnd PIXEL TITLE OemToAnsi("Impressão de Notas fiscais")
	@ 05,005 TO 055,195 of oDlgA pixel
	@ 12,018 Say "Transportadora de : " of oDlgA pixel
	@ 10,075 Get cTranspIni Size 25,12  of oDlgA pixel
	@ 12,105 Say "Até : " of oDlgA pixel
	@ 10,120 Get cTranspFin Size 40,12 of oDlgA pixel
	@ 27,018 Say "Data de Emissão : " of oDlgA pixel
	@ 25,075 Get dDatafat of oDlgA pixel
	@ 40,018 Say "Serié Nota : " of oDlgA pixel
	@ 40,075 Get cSerie of oDlgA pixel

	@ 060,018 BUTTON "Continua" Size 40,11 of oDlgA pixel ACTION (lContinua	:= .T. ,oDlgA:End())
	@ 060,070 BUTTON "Aborta" Size 40,11 of oDlgA pixel ACTION (oDlgA:End())

	Activate Dialog oDlgA Centered

	If !lContinua
		Return
	Endif



	Processa({|| CriaArq(.F.) },"Aguarde criando arquivo de trabalho....")

	DEFINE MSDIALOG oDlgPrint TITLE OemToAnsi("Selecione as Notas fiscais para impressão.") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL
	//DEFINE MSDIALOG oDlgPrint FROM 000,000 TO 600,800  PIXEL TITLE OemToAnsi("Selecine as Notas fiscais para impressão.") // OF oMainWnd Pixel
	oDlgPrint:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlgPrint, oDlgPrint:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel2 := TPanel():New(0,0,'',oDlgPrint, oDlgPrint:oFont, .T., .T.,, ,200,50,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_BOTTOM

	@ 010,005 LISTBOX oSC9 VAR cSc9 ;
		Fields HEADER " ",;    //1
	" ",;                  //2
	"Nota Fiscal",;        //3
	"R$ Total",;		   //4
	"Portador",;		   //5
	"Pedido",;             //6
	"Emissão",;            //7
	"Nome Cliente",;       //8
	"Volumes",;        	   //9
	"Transportadora",;     //10
	"Cidade",;             //11
	"Data/Hora Envio Sep.",;//12
	"Série NF",;		   //13
	"Data/Hora Conferência",;	//14
	"St.NFE";			   //15
	SIZE 390, 260;
		ON DBLCLICK (InverteSC9()) OF oPanel1 PIXEL

	oSC9:nFreeze := 2
	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{sfLegenda(),;
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
		aSC9[oSC9:nAt,15]}}

	oSC9:Align := CONTROL_ALIGN_ALLCLIENT

	oSC9:Refresh()

	@ 005,010 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 005,020 SAY "-0 Não conferido" of oPanel2 pixel

	@ 015,010 BITMAP oBmp RESNAME "BR_AZUL" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 015,020 SAY "-1 Não Transmitida" of oPanel2 pixel

	@ 025,010 BITMAP oBmp RESNAME "BR_CINZA" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 025,020 SAY "-2 Não Autorizada" of oPanel2 pixel

	@ 005,080 BITMAP oBmp RESNAME "BR_PRETO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 005,090 SAY "-3 Denegada" of oPanel2 pixel

	@ 015,080 BITMAP oBmp RESNAME "BR_VERDE" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 015,090 SAY "-4 Não Impressa" of oPanel2 pixel

	@ 025,080 BITMAP oBmp RESNAME "BR_AMARELO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 025,090 SAY "-5 Já impresso" of oPanel2 pixel

	@ 035,080 BITMAP oBmp RESNAME "BR_MARROM" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 035,090 SAY "-6 Reimpressa" of oPanel2 pixel

	@ 002,160 Say "R$ Selecionado" of oPanel2 pixel
	@ 013,160 MsGet oSele Var nSele Size 45,10 Picture "@E 9,999,999.99" of oPanel2 pixel when .F.

	cAgencia 	:= Space(5)
	cConta   	:= Space(10)
	aLocimp     := {"E","F"}
	aPrintBol	:= {"SIM","NÃO"}

	If lIsUsrLib

		// Monta Lista de Bancos habilitados
		sfSEEOpc()

		@ 002,216 Say "Informe o Banco:" of oPanel2 pixel
		@ 013,216 COMBOBOX oBancoImp Var cBancoimp ITEMS aBanco size 120,12 of oPanel2 pixel
		@ 001,350 Say "Local Impressão:" of oPanel2 pixel
		@ 013,350 Combobox cLocimp Items aLocimp Size 20,10 of oPanel2 pixel

		@ 001,400 SAY "Imprime Boletos?" of oPanel2 pixel
		@ 013,400 Combobox cPrintBol Items aPrintBol Size 28,10 of oPanel2 pixel

		aadd(aButtons,{"RELATORIO",{|| sfTransNFe()},"Transmitir","Transmissão"})
		aadd(aButtons,{"RELATORIO",{|| sfMonitor()},"Monitor","Monitor Sefaz"})
		aadd(aButtons,{"RELATORIO",{|| SpedNFe6Mnt( aSC9[oSC9:nAt,13]/*cSerie*/,aSC9[oSC9:nAt,3]/*cNotaIni*/,aSC9[oSC9:nAt,3]/*cNotaFim*/,.T. /*lCTe*/)},"Consulta Nfe","Consulta Nfe"})
	Endif

	Aadd(aButtons,{"RELATORIO",{|| sfVerPedido()},"Visualizar Pedido","Ver Pedido"})

	ACTIVATE MSDIALOG oDlgPrint ON INIT EnchoiceBar(oDlgPrint,{|| lSaida	:= .T.,oDlgPrint:End()},{|| oDlgPrint:End()},,aButtons)


	If lIsUsrLib .And. lSaida
		GMDanfe()

	ElseIf !lIsUsrLib .And. lSaida

		For nf := 1 to Len(aSC9)

			If 	aSC9[nf,2]

				dbSelectArea("SF2")
				dbSetOrder(1)
				dbSeek(xFilial("SF2")+aSC9[nf,3]+aSC9[nf,13])
				Aadd(aRecSF2,SF2->(Recno()))

			Endif
		Next
		If Len(aRecSF2) >  0
			/*
			MV_PAR01 - Serie Nota
			MV_PAR02 - Nota Inicial
			MV_PAR03 - Nota Final 
			MV_PAR04 - Vendedor Inicial
			MV_PAR05 - Vendedor Final
			MV_PAR06 - Emissao Inicial
			MV_PAR07 - Emissao Final 
			MV_PAR08 - Quebra página por nota 
			*/
			U_MLFATR02({cSerie,"  ","zzzz"," ","zzzzzz",dDatafat,dDatafat},.T./*lGeraCB7*/)
		Endif
	Endif

Return

/*/{Protheus.doc} sfMonitor
Monitoramento de notas e refresh 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 02/06/2023
@return variant, return_description
/*/
Static Function sfMonitor()

	SpedNFe1Mnt()

	Processa({|| CriaArq(.T.) },"Aguarde criando arquivo de trabalho....")
	// Zero variável por que o listbox foi zerado também
	nOpcNfe := 0

Return

Static Function sfVerPedido()

	Local		aAreaOld	:= GetArea()
	Private	ALTERA		:= .F.
	Private	INCLUI		:= .F.

	DbSelectArea("SC5")
	DbSetOrder(1)
	If DbSeek(xFilial("SC5")+aSC9[oSC9:nAt,6]	)
		MATA410(/*xAutoCab*/,/*xAutoItens*/,2/*nOpcAuto*/,/*lSimulacao*/,"A410Visual"/*cRotina*/,/*cCodCli*/,/*cLoja*/)
	Endif

	RestArea(aAreaOld)

Return


Static Function sfSEEOpc()

	Local	aAreaOld	:= GetArea()

	DbSelectArea("SEE")
	DbSetOrder(1)
	DbSeek(xFilial("SEE"))
	While !Eof() .And. SEE->EE_FILIAL == xFilial("SEE")
		// Se a configuração de banco for do tipo REM-Remessa
		If SEE->EE_EXTEN == "REM"
			//If (SEE->EE_CODIGO == "033" .And. RetCodUsr() $ GetNewPar("GF_IDBL033","000000") ) .Or. SEE->EE_CODIGO <> "033"
			Aadd(aBanco,SEE->EE_OPER + "|" + SEE->EE_CODIGO + "|" + SEE->EE_AGENCIA + "|" + SEE->EE_CONTA + "|" + SEE->EE_SUBCTA)
			//Endif
			//aBanco     := {"ITAU|341|2938 |37576     |001|"} // Banco + Agencia + Conta + Sub-conta
		Endif
		DbSkip()
	Enddo
	RestArea(aAreaOld)

Return

/*/{Protheus.doc} GMDanfe
(long_description)
@author MarceloLauschner
@since 29/06/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function GMDanfe()

	Local 	iB,nF
	Local	lSelNfPrt	:= .F.
	Local	cLocDir		:= "C:\NF-e\"
	Local	aAreaOld	:= GetArea()
	Local	cIdEnt		:= RetIdEnti()
	Local	lPrintAll	:= GetNewPar("GF_FTA05DF",.T.) // Criar o parametro GF_FTA05DF por filial
	MakeDir(cLocDir)

	Private lFirstDF  	:= .T.
	Private lFirstBL	:= .T.
	Private cPrintName	:= ""
	Private	aRecSE1		:= {}
	Private	aRecSF2		:= {}

	// Habilita parametro para que as perguntas e telas de impressão de DANFE e BOLETOS

	For nf := 1 to Len(aSC9)

		If 	aSC9[nf,2]

			lSelNfPrt	:= .T.

			dbSelectArea("SF2")
			dbSetOrder(1)
			dbSeek(xFilial("SF2")+aSC9[nf,3]+aSC9[nf,13])

			cPerg := "NFSIGW"
			cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))



			// Trecho para gerar PDF
			//oPrintSetup:aOptions[PD_VALUETYPE]	 	:= cLocDir
			//oPrintSetup:aOptions[PD_PRINTTYPE]	 	:= IMP_PDF
			//oPrintSetup:aOptions[PD_DESTINATION]    := AMB_SERVER

			If lPrintAll
				Aadd(aRecSF2,SF2->F2_DOC)
				// Grava as perguntas
				U_GravaSX1(cPerg,"01"," ")
				U_GravaSX1(cPerg,"02","ZZZZZZ")
				U_GravaSX1(cPerg,"03",SF2->F2_SERIE)
				U_GravaSX1(cPerg,"04",2)
				U_GravaSX1(cPerg,"05",2)
				U_GravaSX1(cPerg,"06",2)
				U_GravaSX1(cPerg,"07",SF2->F2_EMISSAO)
				U_GravaSX1(cPerg,"08",SF2->F2_EMISSAO)
			Else
				U_GravaSX1(cPerg,"01",SF2->F2_DOC)
				U_GravaSX1(cPerg,"02",SF2->F2_DOC)
				U_GravaSX1(cPerg,"03",SF2->F2_SERIE)
				U_GravaSX1(cPerg,"04",2)
				U_GravaSX1(cPerg,"05",2)
				U_GravaSX1(cPerg,"06",2)
				U_GravaSX1(cPerg,"07",SF2->F2_EMISSAO)
				U_GravaSX1(cPerg,"08",SF2->F2_EMISSAO)

				If lFirstDF

					oSetup	:= sfSpedDanfe(.T.)

				Else
					cFilePrint := "DANFE_"+cIdEnt+Dtos(MSDate())+StrTran(Time(),":","")
					oDanfe := FWMSPrinter():New(cFilePrint, IMP_PDF, .F., /*cPathInServer*/, .T.)
					//			(cIdEnt		, cVal1		, cVal2	,	oDanfe,	oSetup		, cFilePrint		, lIsLoja	)
					U_PrtNfeSef(cIdEnt		,			,		,	oDanfe,	oSetup		, cFilePrint	, .F. )

				Endif

			Endif
			Begin Transaction
				DbSelectArea("SF2")
				If !Empty(SF2->F2_ESPECI4)
					RecLock("SF2",.F.)
					SF2->F2_ESPECI4 := "R"
					MsUnLock("SF2")
				Else
					RecLock("SF2",.F.)
					SF2->F2_ESPECI4 := "S"
					MsUnLock()
				Endif
			End Transaction

			If cPrintBol == "SIM"

				DbSelectArea("SE1")
				DbSetOrder(2) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				DbSeek(xFilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_PREFIXO+SF2->F2_DUPL)
				While !Eof() .And. SE1->E1_CLIENTE == SF2->F2_CLIENTE .And. SE1->E1_LOJA == SF2->F2_LOJA .And. SE1->E1_PREFIXO == SF2->F2_PREFIXO .And. SE1->E1_NUM == SF2->F2_DUPL

					If SE1->E1_ORIGEM == "MATA460 "
						DbSelectArea("SC5")
						DbSetOrder(1)
						If DbSeek(xFilial("SC5")+SE1->E1_PEDIDO)
							If SC5->C5_CONDPAG $ GetNewPar("GF_CPNBOLT","V01#000#099") .Or. SC5->C5_BANCO $ GetNewPar("GF_BCNBOLT","888#777") // Se for um título de Vendor ou cobrança 888  
							// SC5->C5_CONDPAG $ "V01#000#099" .Or. SC5->C5_BANCO $ "888#777"
								DbSelectArea("SE1")
								DbSkip()
								Loop
							Endif
						Endif
					Endif

					Aadd(aRecSE1,SE1->(Recno()))

					DbSelectArea("SE1")
					DbSkip()
				Enddo
				If !lPrintAll
					For iB := 1 To Len(aRecSE1)
						U_MLFINA01(.T.,1,aRecSE1[iB],/*lWhen*/)
					Next
					aRecSE1	:= {}
				Endif
			Endif

			If lFirstDF
				lFirstDF	:= .F.
			Endif
		Endif

	Next

	// Imprime todos os objetos de uma só vez
	If lPrintAll .And. lSelNfPrt

		sfSpedDanfe()

		If Len(aRecSE1) > 0
			U_MLFINA01(.T./*lAuto*/,1/*nOpc*/,/*nRecSe1*/,/*lWhen*/,aRecSE1)
		Endif

	Endif

	// Efetua chamada do Job de transmissão das notas
	//Startjob("U_MLFATM04",GetEnvServer(),.F.,"",.T.,cEmpAnt,cFilAnt)
	// Rotina desativa em 06/05/2023
	Processa({|| U_MLFATM04()},"Aguarde. Enviando e-mail XML/PDF..")

	RestArea(aAreaOld)


Return

User Function MLFATA5X()

	Local 	aRecSE1		:= {}
	Local 	iB 		
	Private cAuxFilE1	:= xFilial("SE1")
	Private lFirstBL	:= .T.

	DbSelectArea("SE1")
	DbSetOrder(1) 
	Set Filter To E1_FILIAL == cAuxFilE1 .And. Empty(E1_CODBAR) .And. E1_SALDO > 0 .And. E1_PORTADO == "341" .And. Alltrim(E1_ORIGEM) == "MATA460" .And. !Empty(E1_NUMBCO)
	While !Eof() 
		If SE1->E1_ORIGEM == "MATA460 " 
			DbSelectArea("SC5")
			DbSetOrder(1)
			If DbSeek(xFilial("SC5")+SE1->E1_PEDIDO)
				If SC5->C5_CONDPAG $ GetNewPar("GF_CPNBOLT","V01#000#099") .Or. SC5->C5_BANCO $ GetNewPar("GF_BCNBOLT","888#777") // Se for um título de Vendor ou cobrança 888  
					DbSelectArea("SE1")
					DbSkip()
					Loop
				Endif
			Endif
		Endif
		
		dbSelectArea("SA6")
		dbsetorder(1)
		dbseek(xFilial("SA6")+SE1->E1_PORTADO+SE1->E1_AGEDEP+SE1->E1_CONTA)

		
		dbSelectArea("SEE")
		dbSetOrder(1)
		If !dbSeek(xFilial("SEE")+SA6->A6_COD+SA6->A6_AGENCIA+SA6->A6_NUMCON+"001")
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif

		If Len(aRecSE1) > 500 
			Exit 
		Endif 
		Aadd(aRecSE1,SE1->(Recno()))

		DbSelectArea("SE1")
		DbSkip()
	Enddo
	DbSelectArea("SE1")
	Set Filter To
	If Len(aRecSE1) > 0 
		U_MLFINA01(.T./*lAuto*/,2/*nOpc*/,aRecSE1[1]/*nRecSe1*/,/*lWhen*/,aRecSE1)
	Endif 
	//	For iB := 1 To Len(aRecSE1)
	//		U_MLFINA01(.T.,2/*reimpressão*/,aRecSE1[iB],/*lWhen*/)
	//	Next	
	//Endif 
		
Return 

Static Function sfSpedDanfe(lOnlySetup)

	Local aIndArq   	:= {}
	Local oDanfe
	Local nHRes  		:= 0
	Local nVRes  		:= 0
	Local nDevice
	Local cFilePrint 	:= ""
	Local oSetup
	Local aDevice  		:= {}
	Local cSession     	:= GetPrinterSession()
	Local nRet 			:= 0
	Local lUsaColab		:= UsaColaboracao("1")
	Local cIdEnt		:= U_MLTSSENT()
	Default lOnlySetup	:= .F.

	If findfunction("U_DANFE_V")
		nRet := U_Danfe_v()
	Elseif findfunction("U_DANFE_VI") // Incluido esta validação pois o cliente informou que não utiliza o DANFEII
		nRet := U_Danfe_vi()
	EndIf

	AADD(aDevice,"DISCO") // 1
	AADD(aDevice,"SPOOL") // 2
	AADD(aDevice,"EMAIL") // 3
	AADD(aDevice,"EXCEL") // 4
	AADD(aDevice,"HTML" ) // 5
	AADD(aDevice,"PDF"  ) // 6

	cFilePrint := "DANFE_"+cIdEnt+Dtos(MSDate())+StrTran(Time(),":","")

	nLocal       	:= If(fwGetProfString(cSession,"LOCAL","SERVER",.T.)=="SERVER",1,2 )
	nOrientation 	:= If(fwGetProfString(cSession,"ORIENTATION","PORTRAIT",.T.)=="PORTRAIT",1,2)
	cDevice     	:= If(Empty(fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.)),"PDF",fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.))
	nPrintType      := aScan(aDevice,{|x| x == cDevice })


	lAdjustToLegacy := .F. // Inibe legado de resolução com a TMSPrinter
	oDanfe := FWMSPrinter():New(cFilePrint, IMP_PDF, lAdjustToLegacy, /*cPathInServer*/, .T.)

	// ----------------------------------------------
	// Cria e exibe tela de Setup Customizavel
	// OBS: Utilizar include "FWPrintSetup.ch"
	// ----------------------------------------------
	//nFlags := PD_ISTOTVSPRINTER+ PD_DISABLEORIENTATION + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
	nFlags := PD_ISTOTVSPRINTER + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
	If ( !oDanfe:lInJob )
		oSetup := FWPrintSetup():New(nFlags, "DANFE")
		// ----------------------------------------------
		// Define saida
		// ----------------------------------------------
		oSetup:SetPropert(PD_PRINTTYPE   , nPrintType)
		oSetup:SetPropert(PD_ORIENTATION , nOrientation)
		oSetup:SetPropert(PD_DESTINATION , nLocal)
		oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
		oSetup:SetPropert(PD_PAPERSIZE   , 2)

	EndIf

	// ----------------------------------------------
	// Pressionado botão OK na tela de Setup
	// ----------------------------------------------
	If oSetup:Activate() == PD_OK // PD_OK =1
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Salva os Parametros no Profile             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		fwWriteProfString( cSession, "LOCAL"      , If(oSetup:GetProperty(PD_DESTINATION)==1 ,"SERVER"    ,"CLIENT"    ), .T. )
		fwWriteProfString( cSession, "PRINTTYPE"  , If(oSetup:GetProperty(PD_PRINTTYPE)==2   ,"SPOOL"     ,"PDF"       ), .T. )
		fwWriteProfString( cSession, "ORIENTATION", If(oSetup:GetProperty(PD_ORIENTATION)==1 ,"PORTRAIT"  ,"LANDSCAPE" ), .T. )

		// Configura o objeto de impressão com o que foi configurado na interface.
		oDanfe:setCopies( val( oSetup:cQtdCopia ) )

		If oSetup:GetProperty(PD_ORIENTATION) == 1
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Danfe Retrato DANFEII.PRW                  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			u_PrtNfeSef(cIdEnt,,,oDanfe, oSetup, cFilePrint)
		Else
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Danfe Paisagem DANFEIII.PRW                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			u_DANFE_P1(cIdEnt,,,oDanfe, oSetup)
		EndIf

	Else
		MsgInfo("Relatório cancelado pelo usuário.")
		Return
	Endif
	If !lOnlySetup
		oSetup := Nil
	Endif
	oDanfe := Nil

Return oSetup

/*/{Protheus.doc} CriaArq
(long_description)
@author MarceloLauschner
@since 29/06/2015
@version 1.0
@param lForceRef, ${param_type}, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function CriaArq(lForceRef)

	Local 	_nStatus 	:= 1
	Local	cQry		:= ""

	If lForceRef
		aSC9	:= {}
	Endif

	// sql alterado por Marcelo em 28/10/05 para ficar mais leve

	cQry := ""
	cQry += "SELECT DISTINCT SF2.F2_EMISSAO,SF2.F2_TRANSP,SF2.F2_DOC,SF2.F2_CLIENTE,SF2.F2_LOJA,SF2.F2_SERIE,SF2.F2_ESPECI4,SF2.F2_VALBRUT,F2_CHVNFE,"
	cQry += "       SA1.A1_CEP,SA1.A1_NREDUZ,SA1.A1_MUN,SF2.F2_SERIE,SF2.F2_FIMP,F2_VOLUME1,A1_BCO1, "
	cQry += "       SC9.C9_PEDIDO,SC9.C9_CARGA, "
	cQry += "       F2_TRANSP + '-' + (SELECT A4_NREDUZ "
	cQry += "          FROM " + RetSqlName("SA4") + " A4 "
	cQry += "         WHERE A4.D_E_L_E_T_ = ' ' "
	cQry += "           AND A4.A4_COD = SF2.F2_TRANSP "
	cQry += "           AND A4.A4_FILIAL = '" + xFilial("SA4") + "' ) AS A4_NREDUZ, "
	cQry += "       (SELECT C5.C5_BANCO "
	cQry += "          FROM "+ RetSqlName("SC5") + " C5 "
	cQry += "         WHERE C5.D_E_L_E_T_ = ' ' "
	cQry += "           AND C5.C5_NUM = SC9.C9_PEDIDO "
	cQry += "           AND C5.C5_FILIAL = '" + xFilial("SC5") + "' ) AS C5_BANCO "
	cQry += "  FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("SC9") + " SC9, " + RetSqlName("SA1") + " SA1  "
	cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SA1.A1_LOJA = SF2.F2_LOJA "
	cQry += "   AND SA1.A1_COD = SF2.F2_CLIENTE "
	cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQry += "   AND SC9.D_E_L_E_T_ = ' ' "
	cQry += "   AND SC9.C9_NFISCAL = SF2.F2_DOC "
	cQry += "   AND SC9.C9_SERIENF = SF2.F2_SERIE "
	cQry += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") + "'  "
	cQry += "   AND SF2.F2_TRANSP BETWEEN '"+cTranspini+"' AND '"+cTranspfin+"' "
	cQry += "   AND SF2.D_E_L_E_T_ = ' ' "
	cQry += "   AND SF2.F2_SERIE = '" + cSerie + "' "
	cQry += "   AND SF2.F2_ESPECIE = 'SPED' "
	cQry += "   AND SF2.F2_EMISSAO = '" + DTOS(dDatafat)+"' "
	cQry += "   AND SF2.F2_FILIAL = '" + xFilial("SF2") +"' "
	cQry += " ORDER BY F2_DOC"

	TCQUERY cQry NEW ALIAS "QRP"

	Count To nRecCount

	dbselectarea("QRP")
	dbGotop()
	ProcRegua(nRecCount)
	While !Eof()
		IncProc("Processando Nota fiscal -> "+QRP->F2_DOC)

		_nStatus	:= 1

		DbSelectArea("CB7")
		DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
		If DbSeek(xFilial("CB7")+Padr(QRP->F2_DOC,TamSX3("F2_DOC")[1])+cSerie)
			If CB7->CB7_STATUS == "9" .Or. (lIsUsrLib .And. QRP->F2_VOLUME1 > 0 ) // Usuário faturista e volumes já calculados

				If QRP->F2_FIMP == " " // Não transmitida
					_nStatus	:= 1
				ElseIf QRP->F2_FIMP == "N"	//	Não Autorizada
					_nStatus	:= 2
				ElseIf QRP->F2_FIMP == "D"	// Nota Denegada
					_nStatus	:= 3
				ElseIf QRP->F2_FIMP == "S"	// Nota Autorizada
					_nStatus	:= 4
					If Empty(QRP->F2_ESPECI4)
						_nStatus	:= 4
					ElseIf Alltrim(QRP->F2_ESPECI4) == 'S' // Nota impressa
						_nStatus	:= 5
					ElseIf Alltrim(QRP->F2_ESPECI4) == 'R' // Nota reimpressa
						_nStatus	:= 6
					Endif
				Endif


				If !lIsUsrLib
					dbSelectArea("QRP")
					dbSkip()
					Loop
				Endif
			Else
				_nStatus	:= 0
			Endif
		Else
			If !lIsUsrLib
				_nStatus	:= 7
			Else
				_nStatus	:= 0
			Endif
		Endif
		//	"F2_FIMP==' ' .AND. AllTrim(F2_ESPECIE)=='SPED'",'VERMELHO' },;	//NF não transmitida
		//    "F2_FIMP=='S'",'VERDE' //NF Autorizada
		//    "F2_FIMP=='T'",'AZUL'  //NF Transmitida
		//    "F2_FIMP=='N'",'PRETO' // NF nao autorizada


		AAdd( aSC9, { 	_nStatus,;			// 1  - Cores
		.F.,;								// 2  - Marcado / desmarcado
		QRP->F2_DOC,;						// 3  - Numero Nota fiscal
		QRP->F2_VALBRUT,;					// 4  - Valor Total da NF
		QRP->C5_BANCO,;						// 5  - Banco
		QRP->C9_PEDIDO,; 					// 6  - Numero pedido
		STOD(QRP->F2_EMISSAO),;				// 7  - Data Emissao Nota fiscal
		alltrim(QRP->A1_NREDUZ),; 			// 8  - Nome reduzido Cliente
		QRP->F2_VOLUME1,;		 			// 9  - Vago
		QRP->A4_NREDUZ,;					// 10  - Nome reduzido transportadora
		QRP->A1_MUN,;						// 11 - Cidade cliente
		DTOC(CB7->CB7_DTEMIS) + " " + CB7->CB7_HREMIS	,;		 	 		// 12 - Vago
		QRP->F2_SERIE ,;  					// 13 - Serie NF
		DTOC(CB7->CB7_DTFIMS)+" " + CB7->CB7_HRFIMS	,;	// 14 - Data hora conferência
		QRP->F2_FIMP})						// 15 - Status da NF-e

		dbSelectArea("QRP")
		dbSkip()
	Enddo

	QRP->(DbCloseArea())

	If Len(aSC9) < 1
		MsgAlert("Nao houveram registros selecionados","Atencao!")
		AADD(aSC9,{_nStatus,.F.,"","","","","","",0,"","","","","","",.F.})
	Endif

	If lForceRef
		oSC9:SetArray(aSC9)
		oSC9:bLine:={ ||{sfLegenda(),;
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
			aSC9[oSC9:nAt,15]}}
	Endif

Return


/*/{Protheus.doc} InverteSC9
(long_description)
@author MarceloLauschner
@since 29/06/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function InverteSC9()

	Local	x

	If !lIsUsrLib
		If !aSC9[oSc9:nAt,2] .And. aSC9[oSC9:nAt,1] <> 7
			If !MsgNoYes("Nota fiscal já impressa para separação. Deseja enviar novamente?","Nota enviada para separação!" )
				Return
			Endif
		Endif
	Else
		If aSC9[oSC9:nAt,1] == 0

			If !RetCodUsr() $ GetNewPar("GF_FATA05A","000000")
				MsgAlert("NF não conferida ainda pela Expedição.","Usuário sem permissão!" )
				Return
			Endif

			//	"F2_FIMP==' ' .AND. AllTrim(F2_ESPECIE)=='SPED'",'VERMELHO' },;	//NF não transmitida
			//    "F2_FIMP=='S'",'VERDE' //NF Autorizada
			//    "F2_FIMP=='T'",'AZUL'  //NF Transmitida
			//    "F2_FIMP=='N'",'PRETO' // NF nao autorizada
			If Empty(aSC9[oSC9:nAt,15])
				If nOpcNfe == 0
					nOpcNfe	:= 1
					aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>0 ,.T., .F.)
				ElseIf nOpcNfe == 1
					aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>0 ,.T., .F.)
				Endif
				Return
			ElseIf Alltrim(aSC9[oSC9:nAt,15]) == "T"
				MsgAlert("NF transmitida")
				Return
			ElseIf Alltrim(aSC9[oSC9:nAt,15]) == "N"
				MsgAlert("NF não autorizada","Retorno Sefaz" )
				Return
			ElseIf Alltrim(aSC9[oSC9:nAt,15]) == "D"
				MsgAlert("NF Denegada","Retorno Sefaz" )
				Return
			Endif

		Endif
		If aSC9[oSC9:nAt,1] == 1

			//	"F2_FIMP==' ' .AND. AllTrim(F2_ESPECIE)=='SPED'",'VERMELHO' },;	//NF não transmitida
			//    "F2_FIMP=='S'",'VERDE' //NF Autorizada
			//    "F2_FIMP=='T'",'AZUL'  //NF Transmitida
			//    "F2_FIMP=='N'",'PRETO' // NF nao autorizada
			If Empty(aSC9[oSC9:nAt,15])
				If nOpcNfe == 0
					nOpcNfe	:= 1
					aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>0 ,.T., .F.)
				ElseIf nOpcNfe == 1
					aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>0 ,.T., .F.)
				Endif
				Return
			ElseIf Alltrim(aSC9[oSC9:nAt,15]) == "T"
				MsgAlert("NF transmitida")
				Return
			ElseIf Alltrim(aSC9[oSC9:nAt,15]) == "N"
				MsgAlert("NF não autorizada","Retorno Sefaz" )
				Return
			ElseIf Alltrim(aSC9[oSC9:nAt,15]) == "D"
				MsgAlert("NF Denegada","Retorno Sefaz" )
				Return
			Endif

		Endif
		If nOpcNfe == 1
			MsgAlert("Houve marcação de notas para transmissão, não sendo permitido marcar nota para impressão. Reabra a rotina marcando somente notas para imprimir!")
			Return
		Endif


		DbSelectArea("SC5")
		DbSetOrder(1)
		If DbSeek(xFilial("SC5")+aSC9[oSC9:nAt,6] )
			If SC5->C5_BANCO == "BPG"
				If nBolPg == 2
					MsgAlert("Este título se refere a um boleto a ser impresso como QUITADO! Mas já estão marcados títulos para impressão normal.")
					Return
				Endif
				nBolPg := 1
				// Força a opção de banco
				cBancoimp	:= "BOLPG"
				oBancoImp:Refresh()
			Else
				If nBolPg == 1
					MsgAlert("Já estão marcados títulos para impressão de boletos como QUITADOS!")
					Return
				Endif
				nBolPg := 2
			Endif
		Endif

	Endif

	aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] ,.T., .F.)
	nSele := 0

	For x := 1 To Len(aSC9)
		If aSC9[x,2]
			nSele += aSC9[x,4]
		Endif
	Next
	oSele:Refresh()

Return


/*/{Protheus.doc} sfLegenda
(long_description)
@author MarceloLauschner
@since 29/06/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfLegenda()

	Local	_nRet := 1
	If oSc9:nAt > Len(aSC9)
		oSc9:nAt	:= Len(aSC9)
	Endif

	If 	aSC9[oSc9:nAt,1] == 0
		_nRet	:= oVermelho
	ElseIf aSC9[oSc9:nAt,1] == 1
		_nRet	:= oAzul
	ElseIf	aSC9[oSc9:nAt,1] == 2
		_nRet	:= oCinza
	ElseIf	aSC9[oSc9:nAt,1] == 3
		_nRet	:= oPreto
	ElseIf aSC9[oSC9:nAt,1] == 4
		_nRet	:= oVerde
	ElseIf aSC9[oSC9:nAt,1] == 5
		_nRet 	:= oAmarelo
	ElseIf aSC9[oSC9:nAt,1] == 6
		_nRet 	:= oMarrom
	ElseIf aSC9[oSC9:nAt,1] == 7
		_nRet 	:= oBranco
	EndIf

Return(_nRet)




/*/{Protheus.doc} sfTransNFe
(long_description)
@author MarceloLauschner
@since 29/06/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTransNFe()

	Local	lRetTrans	:= .T.
	Local	iX

	Local	aAreaOld	:= GetArea()

	Local	cIdEnt		:= U_MLTSSENT()
	Local	cAmbiente
	Local	cModalidade
	Local	cVersao
	Local	lOk			:= .F.
	Local	lEnd		:= .F.
	Local	cError		:= ""
	Local	cModelo		:= "55"
	Local	cErrorTrans	:= ""
	Local 	cRetorno

	cAmbiente	:= getCfgAmbiente(@cError, cIdEnt, cModelo)

	if( !empty(cAmbiente))

		cModalidade := getCfgModalidade(@cError, cIdEnt, cModelo)

		if( !empty(cModalidade) )
			cVersao		:= getCfgVersao(@cError, cIdEnt, cModelo)

			lOk := !empty(cVersao)

		endif
	endif

	If nOpcNfe <> 1
		MsgAlert("Opção inválida.")
		Return
	Endif

	For iX := 1 To Len(aSC9)

		If 	aSC9[iX,2]

			dbSelectArea("SF2")
			dbSetOrder(1) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
			If dbSeek(xFilial("SF2")+aSC9[iX,3]+aSC9[iX,13])

				cRetorno := SpedNFeTrf("SF2",;
					SF2->F2_SERIE/*cSerie*/,;
					SF2->F2_DOC/*cNotaIni*/,;
					SF2->F2_DOC/*cNotaFim*/,;
					cIdEnt,;
					cAmbiente,;
					cModalidade,;
					cVersao,;
					@lEnd,;
					.F./*lCte*/,;
					.T.)

				If !("com sucesso a transmissão do Protheus para o TOTVS Services SPED." $ cRetorno)
					cErrorTrans	+= cRetorno
					lRetTrans	:= .F.
				Endif

			Endif

		Endif

	Next

	If !lRetTrans
		MsgAlert("Transmissão com problemas - " + cErrorTrans,"Transmissão Sefaz!")
	Endif

	MsgAlert("Antes de imprimir estas nota(s) transmitida(s) é necessário consultar no 'Monitor Sefaz' ou 'Consulta Nfe' se há autorização do Danfe!","Conferir Monitor Sefaz")

	Processa({|| CriaArq(.T.) },"Aguarde criando arquivo de trabalho....")
	// Zero variável por que o listbox foi zerado também
	nOpcNfe := 0

	RestArea(aAreaOld)

Return
