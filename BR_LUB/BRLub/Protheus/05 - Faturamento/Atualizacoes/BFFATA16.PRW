#include "topconn.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} BFFATA16
Impressão de notas fiscais e boletos
@type function
@version 12.1.33
@author Marcelo Alberto Lauschner
@since 7/4/2015
/*/
User Function BFFATA16()

	Local	lContinua	:= .F.
	Local	lSaida		:= .F.
	Local	aButtons	:= {}
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
	Private oGrey		:= LoaDbitmap( GetResources(), "BR_CINZA" )
	Private oAmarelo	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Private oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	Private aSC9		:= {}
	Private cSc9		:= ""
	Private cVarPesq	:= space(6)
	Private cTranspIni  := Space(6)
	Private cTranspFin  := "ZZZZZZ"
	Private dDatafat 	:= ddatabase
	Private cSerie 		:= PADR( AllTrim( SuperGetMv("GM_SERIENF",,'1') ), TAMSX3('F2_SERIE')[1], ' ' )
	Private dDatasai 	:= ddatabase
	Private aSize 		:= MsAdvSize(,.F.,400)
	Private nOpcLoc		:= 0
	Private nOpcNfe		:= 0

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

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

	oPanel2 := TPanel():New(0,0,'',oDlgPrint, oDlgPrint:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_BOTTOM

	@ 010,005 LISTBOX oSC9 VAR cSc9 ;
	Fields HEADER " ",;    //1
	" ",;                  //2
	"Nota Fis",;           //3
	"R$ Total",;		   //4
	"Portador",;		   //5
	"Pedido",;             //6
	"Emissao",;            //7
	"Nome Cliente",;       //8
	"Dt. Progm.",;         //9
	"Transp",;             //10
	"Cidade",;             //11
	"Rota Transp",;        //12
	"Série NF",;		   //13
	"Coletor",;            //14
	"St.NFE";			   //15
	SIZE 390, 260;
	ON DBLCLICK (InverteSC9()) OF oPanel1 PIXEL

	oSC9:nFreeze := 2
	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{DIS001LEG(),;
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
	
	oSC9:bHeaderClick := {|| Iif(oSC9:ColPos == 2 ,sfMarkAll(),Nil ) }
	

	oSC9:Refresh()

	@ 005,010 BITMAP oBmp RESNAME "BR_VERDE" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 005,020 SAY "- Nao Impresso" of oPanel2 pixel
	@ 015,010 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 015,020 SAY "- Ja Impresso" of oPanel2 pixel
	@ 005,080 BITMAP oBmp RESNAME "BR_AMARELO" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 005,090 SAY "- Reimpresso" of oPanel2 pixel
	@ 015,080 BITMAP oBmp RESNAME "BR_AZUL" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 015,090 SAY "- Não Transmitida" of oPanel2 pixel
	@ 025,080 BITMAP oBmp RESNAME "BR_CINZA" SIZE 16,16 NOBORDER of oPanel2 pixel
	@ 025,090 SAY "- Não Autorizada" of oPanel2 pixel

	@ 002,130 Say "R$ Selecionado" of oPanel2 pixel
	@ 000,170 MsGet oSele Var nSele Size 45,10 Picture "@E 9,999,999.99" of oPanel2 pixel when .F.

	cAgencia 	:= Space(5)
	cConta   	:= Space(10)
	aLocimp     := {"E","F"}
	// Exibe tratativa para impressão de boletos apenas antiga apenas se o plugin de impressão de boletos não estiver instalado
	if !FindFunction( 'U_BOLETOS' )
		
		aPrintBol	:= {"SIM","NÃO"}

		//aBanco  := {"ITAU|341|2938 |361330    |001|"} // Banco + Agencia + Conta + Sub-conta 
		aBanco	:= {"ITAU|341|1293 |997621    |001|"} // 

		@ 001,216 Say "Informe o Banco:" of oPanel2 pixel
		@ 001,260 COMBOBOX oBancoImp Var cBancoimp ITEMS aBanco size 50,12 Valid ((cBancoimp == "BOLPG" .And. nBolpg == 1) .Or. (cBancoImp <> "BOLPG" .And. nBolPg <> 1)) of oPanel2 pixel
		
		@ 001,400 SAY "Imprime Boletos?" of oPanel2 pixel
		@ 001,440 Combobox cPrintBol Items aPrintBol Size 28,10 of oPanel2 pixel

	endif
	@ 001,320 Say "Local Impressão:" of oPanel2 pixel
	@ 001,370 Combobox cLocimp Items aLocimp Size 20,10 of oPanel2 pixel

	aadd(aButtons,{"RELATORIO",{|| sfTransNFe()},"Transmitir","Transmissão"})
	aadd(aButtons,{"RELATORIO",{|| SpedNFe1Mnt()},"Monitor","Monitor Sefaz"})
	aadd(aButtons,{"RELATORIO",{|| SpedNFe6Mnt( aSC9[oSC9:nAt,13]/*cSerie*/,aSC9[oSC9:nAt,3]/*cNotaIni*/,aSC9[oSC9:nAt,3]/*cNotaFim*/,.T. /*lCTe*/)},"Consulta Nfe","Consulta Nfe"})

	ACTIVATE MSDIALOG oDlgPrint ON INIT EnchoiceBar(oDlgPrint,{|| lSaida	:= .T.,oDlgPrint:End()},{|| oDlgPrint:End()},,aButtons)


	If lSaida
		GMDanfe()
	Endif

Return

/*/{Protheus.doc} GMDanfe
Função que prepara os parâmetros e chama impressão do danfe
@type function
@version 12.1.33
@author Marcelo Alberto Laushcner 
@since 6/29/2015
/*/
Static Function GMDanfe()

	Local 	iB,nF
	Local	cLocDir		:= "C:\NF-e\"
	Local	aAreaOld	:= GetArea()
	Local	cIdEnt		:= U_MLTSSENT()
	Local	lPrintAll	:= GetNewPar("BF_FTA16DF",.F.) // Criar o parametro BF_FTA16DF por filial 
	MakeDir(cLocDir)

	Private lFirstDF  	:= .T.
	Private lFirstBL	:= .T.
	Private cPrintName	:= ""
	Private	aRecSE1		:= {}
	Private	aRecSF2		:= {}

	// Função  para ajustar profile de usuário que estiver gravado com problema no grupo de perguntas
	cPerg := "NFSIGW"
	cPerg := PADR(cPerg,Len("X1_GRUPO"))

	// Habilita parametro para que as perguntas e telas de impressão de DANFE e BOLETOS
	For nf := 1 to Len(aSC9)

		If 	aSC9[nf,2]

			dbSelectArea("SF2")
			dbSetOrder(1)
			dbSeek(xFilial("SF2")+aSC9[nf,3]+aSC9[nf,13])

			// Trecho para gerar PDF
			//oPrintSetup:aOptions[PD_VALUETYPE]	 	:= cLocDir
			//oPrintSetup:aOptions[PD_PRINTTYPE]	 	:= IMP_PDF
			//oPrintSetup:aOptions[PD_DESTINATION]    := AMB_SERVER
			
			If lPrintAll
			
				Aadd(aRecSF2,SF2->F2_DOC)
				// Grava as perguntas 
				
				U_GravaSX1(cPerg,"01","000000")
				U_GravaSX1(cPerg,"02","ZZZZZZ")
				U_GravaSX1(cPerg,"03",SF2->F2_SERIE)
				U_GravaSX1(cPerg,"04",2)
				U_GravaSX1(cPerg,"05",2)
				U_GravaSX1(cPerg,"06",2)
				U_GravaSX1(cPerg,"07",SF2->F2_EMISSAO)
				U_GravaSX1(cPerg,"08",SF2->F2_EMISSAO)
				profAdjust( __cUserId, cPerg )
			Else
				
				U_GravaSX1(cPerg,"01",SF2->F2_DOC)
				U_GravaSX1(cPerg,"02",SF2->F2_DOC)
				U_GravaSX1(cPerg,"03",SF2->F2_SERIE)
				U_GravaSX1(cPerg,"04",2)
				U_GravaSX1(cPerg,"05",2)
				U_GravaSX1(cPerg,"06",2)
				U_GravaSX1(cPerg,"07",SF2->F2_EMISSAO)
				U_GravaSX1(cPerg,"08",SF2->F2_EMISSAO)
				profAdjust( __cUserId, cPerg )
				
				If lFirstDF

					oSetup	:= sfSpedDanfe(.T.)

				Else
					
					Pergunte( cPerg, .F. )
					MV_PAR01 := SF2->F2_DOC
					MV_PAR02 := SF2->F2_DOC
					MV_PAR03 := SF2->F2_SERIE
					MV_PAR04 := 2	//[Operacao] NF de Saida
					MV_PAR05 := 2	//[Frente e Verso] Sim
					MV_PAR06 := 2	//[DANFE simplificado] Nao 
					MV_PAR07 := SF2->F2_EMISSAO 
					MV_PAR08 := SF2->F2_EMISSAO 

					cFilePrint := "DANFE_"+cIdEnt+Dtos(MSDate())+StrTran(Time(),":","")
					oDanfe := FWMSPrinter():New(cFilePrint, IMP_PDF, .F., /*cPathInServer*/, .T.)
					//			(cIdEnt		, cVal1		, cVal2	,	oDanfe,	oSetup		, cFilePrint		, lIsLoja	)
					U_PrtNfeSef(cIdEnt		,			,		,	oDanfe,	oSetup		, cFilePrint	, .F. )

				Endif

			Endif

			DbSelectArea("SF2")
			If !Empty(SF2->F2_IMPNF)
				RecLock("SF2",.F.)
				SF2->F2_IMPNF := "R"
				MsUnLock("SF2")
			Else
				RecLock("SF2",.F.)
				SF2->F2_IMPNF := "S"
				MsUnLock()
			Endif


			If cPrintBol == "SIM" .and. ! findFunction( 'U_BOLETOS' )

				DbSelectArea("SE1")
				DbSetOrder(2) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				DbSeek(xFilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_PREFIXO+SF2->F2_DUPL)
				While !Eof() .And. SE1->E1_CLIENTE == SF2->F2_CLIENTE .And. SE1->E1_LOJA == SF2->F2_LOJA .And. SE1->E1_PREFIXO == SF2->F2_PREFIXO .And. SE1->E1_NUM == SF2->F2_DUPL

					// 07/10/2016 - Adicionada verificação se a condição de pagamento é Cartão Crédito - Evitando impressão de boletos 
					If SE1->E1_ORIGEM == "MATA460 "
						DbSelectArea("SC5")
						DbSetOrder(1)
						If DbSeek(xFilial("SC5")+SE1->E1_PEDIDO)		
							If SC5->C5_CONDPAG $ "C01#C02#C03"
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
						U_BFFINA05(.T.,1,aRecSE1[iB],/*lWhen*/)
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
	If lPrintAll
		sfSpedDanfe()
		If Len(aRecSE1) > 0 .and. !findFunction( 'U_BOLETOS' )
			U_BFFINA05(.T./*lAuto*/,1/*nOpc*/,/*nRecSe1*/,(cEmpAnt == "05")/*lWhen*/,aRecSE1)
		Endif			 

	Endif

	RestArea(aAreaOld)
Return

/*/{Protheus.doc} sfSpedDanfe
Função para impressão do Danfe
@type function
@version 12.1.033
@author Marcelo Alberto Lauschner
@since 23/10/2020
@param lOnlySetup, logical, indica se a chamada é apenas para alimentar o objeto do setup do danfe
@return object, oSetup
/*/
Static Function sfSpedDanfe(lOnlySetup)

	Local oDanfe
	Local cFilePrint 	:= ""
	Local oSetup
	Local aDevice  		:= {}
	Local cSession     	:= GetPrinterSession()
	Local nRet 			:= 0
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
	cQry += "SELECT DISTINCT SF2.F2_EMISSAO,SF2.F2_TRANSP,SF2.F2_DOC,SF2.F2_CLIENTE,SF2.F2_LOJA,SF2.F2_SERIE,SF2.F2_IMPNF,SF2.F2_VALBRUT,F2_CHVNFE, "
	cQry += "       SA1.A1_CEP,SA1.A1_NREDUZ,SA1.A1_MUN,SF2.F2_SERIE,SF2.F2_FIMP,A1_BCO1, "
	cQry += "       SC9.C9_PEDIDO,SC9.C9_CARGA, "
	cQry += "       F2_TRANSP + '-'+(SELECT A4_NREDUZ "
	cQry += "          FROM " + RetSqlName("SA4") + " A4 "
	cQry += "         WHERE A4.D_E_L_E_T_ = ' ' "
	cQry += "           AND A4.A4_COD = SF2.F2_TRANSP "
	cQry += "           AND A4.A4_FILIAL = '" + xFilial("SA4") + "' ) AS A4_NREDUZ, "
	If cEmpAnt == "02"
		cQry += "       (SELECT MAX(P.PAB_CTRFIL) "
		cQry += "          FROM " + RetSqlName("PAB") + " P "
		cQry += "         WHERE P.D_E_L_E_T_ = ' ' "
		cQry += "           AND P.PAB_CEP = SA1.A1_CEP "
		cQry += "           AND P.PAB_FILIAL = '" + xFilial("PAB") + "') AS PAB_CTRFIL, "
	Else
		cQry += " ' ' PAB_CTRFIL,"
	Endif
	cQry += "       (SELECT C5.C5_BANCO "
	cQry += "          FROM "+ RetSqlName("SC5") + " C5 "
	cQry += "         WHERE C5.D_E_L_E_T_ = ' ' "
	cQry += "           AND C5.C5_NUM = SC9.C9_PEDIDO "
	cQry += "           AND C5.C5_FILIAL = '" + xFilial("SC5") + "' ) AS C5_BANCO, "
	cQry += "       (SELECT C5.C5_DTPROGM "
	cQry += "          FROM "+ RetSqlName("SC5") + " C5 "
	cQry += "         WHERE C5.D_E_L_E_T_ = ' ' "
	cQry += "           AND C5.C5_NUM = SC9.C9_PEDIDO "
	cQry += "           AND C5.C5_FILIAL = '" + xFilial("SC5") + "' ) AS C5_DTPROGM "
	cQry += "  FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("SC9") + " SC9, " + RetSqlName("SA1") + " SA1  "
	cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SA1.A1_LOJA = SF2.F2_LOJA "
	cQry += "   AND SA1.A1_COD = SF2.F2_CLIENTE "
	cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQry += "   AND SC9.D_E_L_E_T_ = ' ' "
	cQry += "   AND F2_TIPO = 'N' "
	cQry += "   AND SC9.C9_NFISCAL = SF2.F2_DOC "
	cQry += "   AND SC9.C9_SERIENF = SF2.F2_SERIE "
	cQry += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") + "'  "
	cQry += "   AND SF2.F2_TRANSP BETWEEN '"+cTranspini+"' AND '"+cTranspfin+"' "
	cQry += "   AND SF2.D_E_L_E_T_ = ' ' "
	cQry += "   AND SF2.F2_LOJA BETWEEN '  ' AND 'ZZ' "
	cQry += "   AND SF2.F2_CLIENTE BETWEEN ' ' AND 'ZZZZZZ' "
	cQry += "   AND SF2.F2_DOC BETWEEN ' ' AND 'ZZZZZZ' "
	cQry += "   AND SF2.F2_SERIE = '" + cSerie + "' "
	cQry += "   AND SF2.F2_EMISSAO = '" + DTOS(dDatafat)+"' "
	//	cQry += "   AND F2_EMISSAO BETWEEN '201501' AND '20151231'"
	//	cQry += "   AND EXISTS (SELECT D2_FILIAL FROM SD2020 WHERE D_E_L_E_T_ =' ' AND D2_COD IN(SELECT B1_COD FROM SB1020 WHERE B1_DESC LIKE '%MOTUL%' "
	//	cQry += "     AND B1_FILIAL = D2_FILIAL  AND B1_DESC NOT LIKE '%EXPOSITOR%') AND D2_EMISSAO BETWEEN '201501' AND '20151231' "
	//   cQry += "     AND D2_TIPO = 'N' AND D2_CLIENTE = F2_CLIENTE AND D2_LOJA = F2_LOJA AND D2_SERIE = F2_SERIE AND D2_DOC = F2_DOC) " 
	cQry += "   AND SF2.F2_FILIAL = '" + xFilial("SF2") +"' "
	cQry += " ORDER BY 2 "

	TCQUERY cQry NEW ALIAS "QRP"

	Count To nRecCount

	dbselectarea("QRP")
	dbGotop()
	ProcRegua(nRecCount)
	While !Eof()
		IncProc("Processando Nota fiscal -> "+QRP->F2_DOC)

		_nStatus	:= 1

		If Empty(QRP->F2_IMPNF)
			_nStatus	:= 2
		ElseIf QRP->F2_IMPNF = 'S'
			_nStatus	:= 1
		ElseIf QRP->F2_IMPNF = 'R'
			_nStatus	:= 3
		Endif

		//	"F2_FIMP==' ' .AND. AllTrim(F2_ESPECIE)=='SPED'",'VERMELHO' },;	//NF não transmitida
		//    "F2_FIMP=='S'",'VERDE' //NF Autorizada
		//    "F2_FIMP=='T'",'AZUL'  //NF Transmitida
		//    "F2_FIMP=='N'",'PRETO' // NF nao autorizada

		If QRP->F2_FIMP $ "N# "
			_nStatus	:= 4
		EndIf
		If QRP->F2_FIMP $ "D"
			_nStatus	:= 5
		Endif

		AAdd( aSC9, { 	_nStatus,;			// 1  - Cores
		.F.,;								// 2  - Marcado / desmarcado
		QRP->F2_DOC,;						// 3  - Numero Nota fiscal
		QRP->F2_VALBRUT,;					// 4  - Valor Total da NF
		QRP->C5_BANCO,;						// 5  - Banco
		QRP->C9_PEDIDO,; 					// 6  - Numero pedido
		STOD(QRP->F2_EMISSAO),;				// 7  - Data Emissao Nota fiscal
		alltrim(QRP->A1_NREDUZ),; 			// 8  - Nome reduzido Cliente
		STOD(QRP->C5_DTPROGM),; 			// 9  - Data Programada pedido
		QRP->A4_NREDUZ,;					// 10  - Nome reduzido transportadora
		QRP->A1_MUN,;						// 11 - Cidade cliente
		QRP->PAB_CTRFIL,;  					// 12 - Codigo agencia Alfa
		QRP->F2_SERIE ,;  					// 13 - Serie NF
		"",;								// 14 - Numero Carga
		QRP->F2_FIMP})						// 15 - Status da NF-e

		dbSelectArea("QRP")
		dbSkip()
	Enddo

	QRP->(DbCloseArea())

	If Len(aSC9) < 1
		MsgAlert("Nao houveram registros selecionados","Atencao!")
		AADD(aSC9,{_nStatus,.F.,"","","","","","","","","","","","","",.F.})
	Endif

	If lForceRef
		oSC9:SetArray(aSC9)
		oSC9:bLine:={ ||{DIS001LEG(),;
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

/*/{Protheus.doc} sfMarkAll
Função para marcar todas as notas de uma só vez 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 08/11/2021
@return variant, return_description
/*/
Static Function sfMarkAll()

	Local 	nX 
	Local 	nBx 	:= oSC9:nAt 

	For nX  := 1 To Len(aSC9)
		oSC9:nAt	:= nX 
		InverteSC9()
	Next
	oSC9:nAt 	:= nBx 
	oSC9:Refresh()

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

	If aSC9[oSC9:nAt,1] >= 4

		//	"F2_FIMP==' ' .AND. AllTrim(F2_ESPECIE)=='SPED'",'VERMELHO' },;	//NF não transmitida
		//    "F2_FIMP=='S'",'VERDE' //NF Autorizada
		//    "F2_FIMP=='T'",'AZUL'  //NF Transmitida
		//    "F2_FIMP=='N'",'PRETO' // NF nao autorizada
		If aSC9[oSC9:nAt,15] == " "
			If nOpcNfe == 0
				nOpcNfe	:= 1
				aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>0 ,.T., .F.)
			ElseIf nOpcNfe == 1
				aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>0 ,.T., .F.)
			Endif
		ElseIf aSC9[oSC9:nAt,15] == "T"
			MsgAlert("NF transmitida")
		ElseIf aSC9[oSC9:nAt,15] == "N"
			MsgAlert("NF não autorizada","Retorno Sefaz" )
		ElseIf aSC9[oSC9:nAt,15] == "D"
			MsgAlert("NF não autorizada","Retorno Sefaz" )
		Endif

		Return
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

	aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>0 ,.T., .F.)
	nSele := 0

	For x := 1 To Len(aSC9)
		If aSC9[x,2]
			nSele += aSC9[x,4]
		Endif
	Next
	oSele:Refresh()
Return


/*/{Protheus.doc} DIS001LEG
(long_description)
@author MarceloLauschner
@since 29/06/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function DIS001LEG()

	Local	_nRet := 1
	If oSc9:nAt > Len(aSC9)
		oSc9:nAt	:= Len(aSC9)
	Endif

	If 		aSC9[oSc9:nAt,1] == 1
		_nRet	:= oVermelho
	ElseIf	aSC9[oSc9:nAt,1] == 2
		_nRet	:= oVerde
	ElseIf	aSC9[oSc9:nAt,1] == 3
		_nRet	:= oAmarelo
	ElseIf aSC9[oSC9:nAt,1] == 4
		_nRet	:= oAzul
	ElseIf aSC9[oSC9:nAt,1] == 5
		_nRet 	:= oGrey
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

	Local	iX
	Local	cIdEnt		:= U_MLTSSENT()
	Local	cAmbiente	
	Local	cModalidade
	Local	cVersao
	Local	lOk			:= .F. 
	Local	lEnd		:= .F. 
	Local	cError		:= ""
	Local	cModelo		:= "55" 
	Local	cErrorTrans	:= ""
	
	If nOpcNfe <> 1
		Return
	Endif
	
	cAmbiente	:= getCfgAmbiente(@cError, cIdEnt, cModelo)

	if( !empty(cAmbiente))

		cModalidade := getCfgModalidade(@cError, cIdEnt, cModelo)

		if( !empty(cModalidade) )
			cVersao		:= getCfgVersao(@cError, cIdEnt, cModelo)

			lOk := !empty(cVersao)

		endif
	endif

	For iX := 1 To Len(aSC9)

		If 	aSC9[iX,2]

			dbSelectArea("SF2")
			dbSetOrder(1)
			dbSeek(xFilial("SF2")+aSC9[iX,3]+aSC9[iX,13])
			//Function SpedNFeTrf(cAlias,cSerie,cNotaIni,cNotaFim,cIDEnt,cAmbiente,
			//cModalidade,cVersao,lEnd,lCte,lAuto)

			//Function SpedNFeRe2(cSerie,cNotaIni,cNotaFim,lCTe,lRetorno)
			//AutoNfeEnv(/*cEmpresa*/,/*cFilProc*/,/*cWait*/,/*cOpc*/,SF2->F2_SERIE,SF2->F2_DOC,SF2->F2_DOC)
			
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
			
			If !("Você concluiu com sucesso a transmissão do Protheus para o TOTVS Services SPED." $ cRetorno)
				cErrorTrans	+= cRetorno
			Endif

		Endif

	Next
	
	If !Empty(cErrorTrans)
		MsgAlert("Transmissão com problemas." + cErrorTrans,"Transmissão Sefaz!")
	Endif

	MsgAlert("Antes de imprimir estas nota(s) transmitida(s) é necessário consultar no 'Monitor Sefaz' ou 'Consulta Nfe' se há autorização do Danfe!","Conferir Monitor Sefaz")

	Processa({|| CriaArq(.T.) },"Aguarde criando arquivo de trabalho....")
	// Zero variável por que o listbox foi zerado também
	nOpcNfe := 0

Return


/*/{Protheus.doc} profAdjust
Função para ajustar profile do usuário que estiver com problema nos parâmetros
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 9/5/2022
@param cID, character, ID único do usuário no sistema
@param cGrp, character, grupo de perguntas a ser ajustada no profile
@return logical, lDone
/*/
static function profAdjust( cID, cGrp )
	
	local lDone    := .T. as logical
	local cP_NAME  := PADR( cID, 20, ' ' )
	local cP_PROG  := PADR( cGrp, 10, ' ' )
	local cP_TASK  := "PERGUNTE "
	local cP_TYPE  := "MV_PAR "
	local cCont    := ""  as character
	local nCont    := 0   as numeric
	local aCont    := {}  as array
	local cLine    := ""  as character
	local cNewMemo := ""  as character
	local nX       := 0   as numeric
	local cAli     := "ProfAlias"
	local lNeedChg := .F. as logical

	DBSelectArea( "SX1" )
	SX1->( DBSetOrder( 1 ) )		// X1_GRUPO + X1_ORDEM

	if select( cAli ) > 0
		DBSelectArea( cAli )
		( cAli )->( DBSetOrder( 1 ) )		// P_NAME + P_PROG + P_TASK + P_TYPE
		if ( cAli )->( DBSeek( cP_NAME + cP_PROG + cP_TASK + cP_TYPE ) )
			while ( cAli )->P_NAME + ( cAli )->P_PROG + ( cAli )->P_TASK + ( cAli )->P_TYPE ==;
				cP_NAME + cP_PROG + cP_TASK + cP_TYPE
				cCont := ( cAli )->P_DEFS
				nCont := MLCount( cCont )
				if nCont > 0
					For nX := 1 to nCont
						cLine := MemoLine( cCont,,nX )
						if SX1->( DBSeek( cP_PROG + StrZero( nX, 2 ) ) )
							if SubStr( cLine, 01, 01 ) == "C" .and. SubStr( cLine, 01, 01 ) == SX1->X1_TIPO
								cLine := SubStr( cLine, 01, 04 ) + PADR( StrTokArr2( AllTrim(cLine), '#', .T. )[3], SX1->X1_TAMANHO, ' ' )
								lNeedChg := .T.
							endif
						endif
						aAdd( aCont, cLine )
					next nX
				endif
				( cAli )->( DBSkip() )
			enddo
			//VarInfo( 'Profile', aCont )
			if lNeedChg
				aEval( aCont, {|x| cNewMemo += (x + chr(13) + chr(10)) } )
				WriteProfDef(cP_NAME, cP_PROG, cP_TASK, cP_TYPE,; // Chave antiga
							cP_NAME, cP_PROG, cP_TASK, cP_TYPE, ; // Chave nova
							cNewMemo)
			endif
		endif
	endif
return lDone
