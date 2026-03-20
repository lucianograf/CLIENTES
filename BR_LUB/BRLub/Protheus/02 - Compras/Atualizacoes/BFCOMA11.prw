#Include 'Protheus.ch'
#Include 'TopConn.ch'
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} BFCOMA11
Rotina que possibilita geração do pedido de venda de remessa de armazenagem, da marcação de vários documentos de entrada
@type function
@version 12.1.33
@author Iago Luiz Raimondi
@since 2/25/2015
/*/
User Function BFCOMA11()

	Local aAreaOld		:= GetArea()
	Local cTitulo		:= OemToAnsi("Seleção de Doc.Entrada para Remessa de Armazenagem")
	Local lConf 		:= .F.
	Private oDlg
	Private oSF1
	Private cPerg		:= "BFCOMA11"
	Private aSF1 		:= {}
	Private oENABLE		:= LoaDbitmap( GetResources(), "ENABLE" )
	Private oDISABLE	:= LoaDbitmap( GetResources(), "DISABLE" )
	Private oBR_LARANJA	:= LoaDbitmap( GetResources(), "BR_LARANJA" )
	Private oBR_VIOLETA	:= LoaDbitmap( GetResources(), "BR_VIOLETA" )
	Private oBR_CINZA	:= LoaDbitmap( GetResources(), "BR_CINZA" )
	Private oBR_AMARELO := LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private oBR_PRETO 	:= LoadBitmap( GetResources(), "BR_PRETO" )
	Private oNoMarked	:= LoadBitmap( GetResources(), "LBNO" )
	Private oMarked 	:= LoadBitmap( GetResources(), "LBOK" )
	Private aSize 		:= MsAdvSize()
	Private aObjects 	:= {}
	Private aPosObj		:= {}
	Private aPosGet     := {}
	Private cVarPesq	:= Space(6)

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	ValidPerg()

	If !Pergunte(cPerg,.T.)
		Return
	Endif

	//Processa({|| sfCriaArq() },"Aguarde! Selecionando notas fiscais...")
	sfCriaArq()

	If Len(aSF1) < 1  // Evita que abra a tela se não houver pedidos a serem faturados.
		MsgInfo("Não foi encontrado nenhum Doc.Entrada para geração do Pedido de Venda, favor revisar os filtros.","Aviso: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		AAdd( aSF1, { 1,;		// 1
		.F.,;		// 2
		"",;		// 3
		"",;		// 4
		"",;		// 5
		"",; 		// 6
		CTOD("  /  /  "),; 		// 7
		CTOD("  /  /  "),;		// 8
		0,;			// 9
		0,;			// 10
		0,;			// 11
		" "})
	Endif

	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 015, .t., .f. } )

	aInfo := {aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects )

	aPosGet := MsObjGetPos(aSize[3]-aSize[1],315,{{003,033,160,200,240,263}} )

	DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL
	oDlg:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_BOTTOM

	@ aPosObj[1,1], aPosObj[1,2] LISTBOX oSF1 VAR cSF1 Fields HEADER ;
		" ",; 	//1
	" ",;	//2
	"Numero Nota",;	//3
	"Série",;	//4
	"Fornecedor/Cliente",;	//5
	"Razão Social",;	//6
	"Emissão Nota",;	//7
	"Data Lançamento",;	//8
	"Valor Mercadoria",;	//9
	"Valor Total Nota",;	//10
	"RecnoSF1",;	// 11
	"Pedido Remessa";
		SIZE aPosObj[2,4], aPosObj[2,3]-30 ON DBLCLICK (sfDblClick()) OF oPanel1 PIXEL
	oSF1:nFreeze := 3
	oSF1:SetArray(aSF1)

	oSF1:bLine:={ ||{sfLegenda(aSF1[oSF1:nAT,01]),;
		Iif(aSF1[oSF1:nAT,02],oMarked,oNoMarked),;
		aSF1[oSF1:nAT,03],;
		aSF1[oSF1:nAT,04],;
		aSF1[oSF1:nAT,05],;
		aSF1[oSF1:nAT,06],;
		aSF1[oSF1:nAT,07],;
		aSF1[oSF1:nAT,08],;
		Transform(aSF1[oSF1:nAT,09],"@E 999,999,999.99"),;
		Transform(aSF1[oSF1:nAT,10],"@E 999,999,999.99"),;
		aSF1[oSF1:nAT,11],;
		aSF1[oSF1:nAt,12]}}
	oSF1:Align := CONTROL_ALIGN_ALLCLIENT
	oSF1:Refresh()

	@ 010,010 SAY "Pesquisar Nota" of oPanel2 pixel
	@ 010,060 MSGET cVarPesq Valid stVldPeSF1() of oPanel2 pixel
	@ 010,100 BUTTON "Legenda" of oPanel2 Pixel Size 60,15 Action (cCadastro := "Legenda Documentos de Entrada",A103Legenda())
	@ 010,170 BUTTON "Visualiza Nota" of oPanel2 Pixel Size 60,15 Action sfViewSF1(aSF1[oSF1:nAT,11],2)
	@ 010,240 BUTTON "Imprime Nota" of oPanel2 Pixel Size 60,15 Action sfViewSF1(aSF1[oSF1:nAT,11],6)
	@ 010,310 BUTTON "&Criar Ped.Venda" 	 of oPanel2 pixel SIZE 60,15 ACTION (lConf := .T.,oDlg:End())
	@ 010,380 BUTTON "&Sair" of oPanel2 pixel SIZE 60,15 ACTION (oDlg:End() )


	ACTIVATE MSDIALOG oDlg CENTERED

	If lConf
		sfPedVen()
	EndIf
	RestARea(aAreaOld)

Return

/*/{Protheus.doc} sfPedVen
Função que gera o pedido de venda na tela 
@type function
@version 1.0
@author Marcelo Alberto Lauschner
@since 31/01/2021
/*/
Static Function sfPedVen()

	Local 	lFatur 		:= .F.
	Local 	aRet 		:= {}
	Local 	aPed 		:= {}
	Local 	nVolume 	:= 0
	Local 	nCont	,nX
	Local	cIdEnt		:= U_MLTSSENT()
	Local	cAmbiente
	Local	cModalidade
	Local	cVersao
	Local	lOk			:= .F.
	Local	lEnd		:= .F.
	Local	cError		:= ""
	Local	cModelo		:= "55"
	Local	cErrorTrans	:= ""
	Local	aFields		:= {}
	Local	cCampo		:= ""


	cAmbiente	:= getCfgAmbiente(@cError, cIdEnt, cModelo)

	if( !empty(cAmbiente))

		cModalidade := getCfgModalidade(@cError, cIdEnt, cModelo)

		if( !empty(cModalidade) )
			cVersao		:= getCfgVersao(@cError, cIdEnt, cModelo)

			lOk := !empty(cVersao)

		endif
	endif

	lMarcou 		:= .F.
	cNfMsg  		:= ""

	// IAGO	05/10/2015 Chamado(12607)
	// Removido vinculo com SF4, pois pre-nota nao tem TES. Os valores não são usados em nenhum lugar (F4_INCSOL,F4_DESTACA)
	// A TES é gerada pela TES Inteligente (MaTesInt)
	cQry := ""
	//cQry += " SELECT D1_COD,D1_QUANT,D1_TOTAL,D1_VALDESC,F4_INCSOL,F4_DESTACA,D1_ICMSRET,D1_VALIPI "
	//cQry += "   FROM "+ RetSqlName("SD1") + " D1," +RetSqlName("SF4") + " F4 "
	cQry += " SELECT D1_COD,D1_QUANT,D1_TOTAL,D1_VALDESC,D1_ICMSRET,D1_VALIPI "
	cQry += "   FROM "+ RetSqlName("SD1") + " D1 "
	cQry += "  WHERE D1.D_E_L_E_T_ = ' ' "
	//cQry += "    AND F4.D_E_L_E_T_ = ' ' "
	//cQry += "    AND F4_CODIGO = D1_TES "
	//cQry += "    AND F4_FILIAL = '" + xFilial("SF4")+ "'"
	cQry += "    AND D1_FILIAL = '"+ xFilial("SD1") +"' "
	cQry += "    AND ("

	For nCont := 1 To Len(aSF1)
		If (aSF1[nCont][2])
			If (lMarcou)
				cQry += " OR "
			EndIf
			cQry += " D1_DOC = '"+aSF1[nCont][3]+"' AND D1_SERIE = '"+aSF1[nCont][4]+"' AND D1_FORNECE+'/'+D1_LOJA = '"+aSF1[nCont][5]+"'"
			cNfMsg += AllTrim(aSF1[nCont][3])+"-"+ AllTrim(aSF1[nCont][4])+"/"
			lMarcou := .T.
		EndIf
	Next
	cQry += " )"


	// Se foi marcado algum documento, monta aHeader e aCols
	If lMarcou
		aPergs := {}
		aRet 	:= {}
		aColsC6 := {}

		Aadd(aPergs,{1,"Fornecedor",Space(6),,"EXISTCPO('SA2')","SA2",".T.",6,.T.})
		Aadd(aPergs,{1,"Loja",Space(2),"@",'.T.',,".T.",2,.T.})

		If !ParamBox(@aPergs,"Parametros ",aRet)
			MsgAlert("Operação cancelada.","Alerta: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		EndIf

		// Cria array com campos da SC6
		bCampo := {|nCPO| Field(nCPO) }
		aHeadC6 := {}



		aFields := FWSX3Util():GetAllFields("SC6", .T. /*/lVirtual/*/)
		For nX := 1 to Len(aFields)
			cCampo := aFields[nX]
			If (X3USO(GetSx3Cache(cCampo,"X3_USADO")) .AND. ;
					!Trim(cCampo)=="C6_NUM" .And.;
					Trim(cCampo) != "C6_QTDEMP" .And.;
					Trim(cCampo) != "C6_QTDENT" .And.;
					cNivel >= GetSx3Cache(cCampo,"X3_NIVEL") ) .Or.;
					Trim(cCampo)=="C6_CONTRAT" .Or. ;
					Trim(cCampo)=="C6_ITEMCON"

				Aadd(aHeadC6,{AllTrim(GetSx3Cache(cCampo,"X3_TITULO")),;
					GetSx3Cache(cCampo,"X3_CAMPO")		,;
					GetSx3Cache(cCampo,"X3_PICTURE")	,;
					GetSx3Cache(cCampo,"X3_TAMANHO")	,;
					GetSx3Cache(cCampo,"X3_DECIMAL")	,;
					GetSx3Cache(cCampo,"X3_VALID")		,;
					GetSx3Cache(cCampo,"X3_USADO")		,;
					GetSx3Cache(cCampo,"X3_TIPO")		,;
					GetSx3Cache(cCampo,"X3_ARQUIVO")	,;
					GetSx3Cache(cCampo,"X3_CONTEXT")	})
			Endif
		Next nX
		aHeader    := aClone(aHeadC6)

		// Conta e cria variáveis de memória
		dbSelectArea("SC5")
		nMaxFor := FCount()
		For nX := 1 To nMaxFor
			M->&(EVAL(bCampo,nX)) := CriaVar(FieldName(nX),.T.)
		Next nX

		//Preenche variáveis
		PRIVATE ALTERA := .F.
		PRIVATE INCLUI := .T.
		M->C5_TIPO    := "B"
		M->C5_CLIENTE := MV_PAR01
		M->C5_LOJACLI := MV_PAR02
		M->C5_LOJAENT := MV_PAR02
		a410Cli("C5_CLIENTE",M->C5_CLIENTE,.F.)
		// IAGO 05/05/2015 - Quando nao pesquisa via f3, desposiciona loja
		M->C5_LOJACLI := MV_PAR02
		a410Loja("C5_LOJACLI",M->C5_LOJACLI,.F.)
		M->C5_TIPOCLI := "R"
		M->C5_CONDPAG := "128" // Chumbada só para não dar erro ao validar
		M->C5_TABELA  := "300" // Chumbada só para não dar erro ao validar
		M->C5_PROPRI  := "1"
		M->C5_DTPROGM := dDataBase
		M->C5_MSGINT  := "Ped. Gerado aut. Remessa Armaz.: "+cNfMsg
		nUsado := Len(aHeadC6)
		cSeq := "01"

		TCQUERY cQry NEW ALIAS "QRY"

		While QRY->(!Eof())

			// Posiciona nos registros
			dbSelectArea("SA2")
			dbSetOrder(1)
			MsSeek(xFilial("SA2")+M->C5_CLIENTE+M->C5_LOJACLI)

			dbSelectArea("SB1")
			dbSetOrder(1)
			MsSeek(xFilial("SB1")+QRY->D1_COD)

			dbSelectArea("SF4")
			dbSetOrder(1)
			MsSeek(xFilial("SF4")+SB1->B1_TS)

			Aadd(aColsC6,Array(nUsado+1))
			nY := Len(aColsC6)
			aColsC6[nY,nUsado+1] := .F.

			//Preenche cada campo com seu devido conteudo
			For nX := 1 To nUsado
				Do Case
				Case ( AllTrim(aHeadC6[nX,2]) == "C6_ITEM" )
					aColsC6[nY,nX] := cSeq
					cSeq := Soma1(cSeq)

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_PRODUTO" )
					aColsC6[nY,nX] := QRY->D1_COD

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_UM" )
					aColsC6[nY,nX] := SB1->B1_UM

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_QTDVEN" )
					aColsC6[nY,nX] := QRY->D1_QUANT

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_PRCVEN" )
					aColsC6[nY,nX] := Round((QRY->D1_TOTAL-QRY->D1_VALDESC+QRY->D1_VALIPI+QRY->D1_ICMSRET)/QRY->D1_QUANT,TamSX3("C6_PRCVEN")[2])

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_VALOR" )
					aColsC6[nY,nX] := a410Arred(GDFieldGet("C6_QTDVEN",nY,NIL,aHeadC6,aColsC6)*GDFieldGet("C6_PRCVEN",nY,NIL,aHeadC6,aColsC6),"C6_VALOR")

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_OPER" )
					aColsC6[nY,nX] := "RA"

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_TES" )
					// Obrigatório [aCols] e [n] para rotina MaTesInt()
					aCols	:= aClone(aColsC6)
					n := Len(aCols)
					cTes 	:= MaTesInt(2,"RA",SA2->A2_COD,SA2->A2_LOJA,"F",SB1->B1_COD,"C6_TES")
					If (cTes != nil)
						SF4->(MsSeek(xFilial("SF4")+cTes))
					Else
						cTes := "   "
					EndIf
					aColsC6[nY,nX] := cTes

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_CF" )
					aDadosCFO := {}
					Aadd(aDadosCfo,{"OPERNF","S"})
					Aadd(aDadosCfo,{"TPCLIFOR","R"})
					Aadd(aDadosCfo,{"UFDEST"  ,SA2->A2_EST})
					Aadd(aDadosCfo,{"INSCR"   ,SA2->A2_INSCR})
					aColsC6[nY,nX] := MaFisCfo(,SF4->F4_CF,aDadosCfo)

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_SEGUM" )
					aColsC6[nY,nX] := SB1->B1_SEGUM

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_LOCAL" )
					aColsC6[nY,nX] := SB1->B1_LOCPAD

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_VALDESC" )
					aColsC6[nY,nX] := 0

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_DESCONT" )
					aColsC6[nY,nX] := 0

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_ENTREG" )
					aColsC6[nY,nX] := dDataBase

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_DESCRI" )
					aColsC6[nY,nX] := SB1->B1_DESC

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_PRUNIT" )
					aColsC6[nY,nX] := Round((QRY->D1_TOTAL-QRY->D1_VALDESC+QRY->D1_VALIPI+QRY->D1_ICMSRET)/QRY->D1_QUANT,TamSX3("C6_PRCVEN")[2])

				Case ( AllTrim(aHeadC6[nX,2]) == "C6_QTDLIB" )
					aColsC6[nY,nX] := QRY->D1_QUANT

				OtherWise
					aColsC6[nY,nX] := CriaVar(aHeadC6[nX,2],.T.)

				EndCase
			Next nX

			// Volume
			nVolume += QRY->D1_QUANT

			QRY->(dbSkip())
		EndDo

		// A pedidos do Eduardo RS, preencher volume.
		M->C5_ESPECI1 := "DIVERSOS"
		M->C5_VOLUME1 := nVolume

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		Endif

		// Abre tela do pedido de venda com os campos preenchidos
		Begin Transaction
			aCols   := aColsC6
			aHeader := aHeadC6

			// Variaveis Utilizadas pela Funcao a410Inclui
			PRIVATE ALTERA := .F.
			PRIVATE INCLUI := .T.
			PRIVATE cCadastro := "Pedido de Venda"
			Pergunte("MTA410",.F.)


			// Se foi confirmado o pedido, atualiza as solicitações de baixa
			If SC5->(a410Inclui(Alias(),Recno(),4,.T.,,,.T.)) == 1
				lFatur := .T.
				cPedido := SC9->C9_PEDIDO
			Else
				MsgAlert('Operação foi cancelada. Pedido de venda não foi gerado !',"Alerta: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		End Transaction

		//Faturar fora do Transaction
		aPed := {}
		If lFatur
			aPed := &("StaticCall(FPDC_002,stGravaF2,cPedido,.T.)")
			// Chamado 17913 - Gravar informação de que a nota foi processada
			For nCont := 1 To Len(aSF1)
				If (aSF1[nCont][2])
					DbSelectArea("SF1")
					DbGoto(aSF1[nCont][11])
					RecLock("SF1",.F.)
					SF1->F1_ESPECI3	:= cPedido
					MsUnlock()
				EndIf
			Next
		EndIf

		If ( !(Alltrim(Lower(GetEnvServer())) $ "desenvolvimento" ) .AND. Len(aPed)>0 )
			//AutoNfeEnv(/*cEmpresa*/,/*cFilProc*/,/*cWait*/,/*cOpc*/,SC9->C9_SERIENF,SC9->C9_NFISCAL,SC9->C9_NFISCAL)
			cRetorno := SpedNFeTrf("SF2",;
				SC9->C9_SERIENF/*cSerie*/,;
				SC9->C9_NFISCAL/*cNotaIni*/,;
				SC9->C9_NFISCAL/*cNotaFim*/,;
				cIdEnt,;
				cAmbiente,;
				cModalidade,;
				cVersao,;
				@lEnd,;
				.F./*lCte*/,;
				.T.)

			If !("Você concluíu com sucesso a transmissão do Protheus para o TOTVS Services SPED." $ cRetorno)
				cErrorTrans	+= cRetorno
			Endif
			Sleep(10000)
			MsgInfo('Nf gerada. Nf: '+SC9->C9_NFISCAL+' Serie: '+SC9->C9_SERIENF,"Aviso: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			// Impressão DANFE
			sfImpDanfe(SC9->C9_NFISCAL,SC9->C9_SERIENF)
		EndIf
	Else
		MsgAlert("Não foi marcado nenhum Doc.Entrada para gerar o pedido de venda.","Alerta: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf

Return


/*/{Protheus.doc} sfImpDanfe
(long_description)
@author Iago Luiz Raimondi
@since 26/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfImpDanfe(cNumNota,cSerie)

	Local	cIdEnt	:=	U_MLTSSENT()

	cPerg := "NFSIGW"
	// cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))
	cPerg :=  PADR(cPerg,10)

	U_GravaSX1(cPerg,"01",cNumNota)
	U_GravaSX1(cPerg,"02",cNumNota)
	U_GravaSX1(cPerg,"03",cSerie)
	U_GravaSX1(cPerg,"04",2)

	// ajusta profile para evitar que a informação gravada seja corrompida
	profAdjust( __cUserId, cPerg )

	oPrintSetup	:= FWPrintSetup():New(0,"Impressão de DAnfe")
	oPrintSetup:aOptions[PD_DESTINATION]    := AMB_CLIENT
	oPrintSetup:aOptions[PD_PRINTTYPE]	 	:= IMP_SPOOL
	oPrintSetup:aOptions[PD_ORIENTATION]	:= PORTRAIT
	oPrintSetup:aOptions[PD_PAPERSIZE]		:= DMPAPER_A4
	oPrintSetup:aOptions[PD_PREVIEW]		:= .T.
	//			oPrintSetup:aOptions[PD_VALUETYPE]		:= "PDF_Printer"
	oPrintSetup:aOptions[PD_MARGIN]			:= {60,60,60,60}
	//#DEFINE PD_MARGIN				7

	Pergunte( cPerg, .F. )
	MV_PAR01 := cNumNota
	MV_PAR02 := cNumNota
	MV_PAR03 := cSerie
	MV_PAR04 := 2
	MV_PAR05 := 2	//[Frente e Verso] Sim
	MV_PAR06 := 2	//[DANFE simplificado] Nao
	MV_PAR07 := StoD('20100101')
	MV_PAR08 := StoD('20491231')

	oDanfe 	:= FWMSPrinter():New("DANFE_"+cIdEnt+DTOS(dDataBase)+Alltrim(Str(Randomize(1,10000))),oPrintSetup:aOptions[PD_PRINTTYPE]/*nDevice*/,.F./*lAdjustToLegacy]*/,/*cPathInServer*/,.F./*lDisabeSetup*/,.T./*lTReport*/,@oPrintSetup,oPrintSetup:aOptions[PD_VALUETYPE]/*cPrinter*/,.F./*lServer*/)
	oDanfe:SetResolution(78) //Tamanho estipulado para a Danfe
	oDanfe:SetPortrait()
	oDanfe:SetPaperSize(DMPAPER_A4)
	oDanfe:SetMargin(60,60,60,60)
	oDanfe:lServer := oPrintSetup:GetProperty(PD_DESTINATION)==AMB_SERVER
	oDanfe:Setup()

	If oDanfe:nDevice == IMP_PDF
		oPrintSetup:aOptions[PD_PRINTTYPE]	:= oDanfe:nDevice
		oPrintSetup:aOptions[PD_VALUETYPE]	:= oDanfe:cPathPDF
	ElseIf oDanfe:nDevice == IMP_SPOOL
		oPrintSetup:aOptions[PD_VALUETYPE]	:= oDanfe:cPrinter
	Endif

	cArqDel	:= Alltrim(oDanfe:cFilePrint)
	FreeObj(oDanfe)
	oDanfe := Nil
	fErase(cArqDel)

	oDanfe 	:= FWMSPrinter():New("DANFE_"+cIdEnt+DTOS(dDataBase)+Alltrim(Str(Randomize(1,10000))),oPrintSetup:aOptions[PD_PRINTTYPE]/*nDevice*/,.F./*lAdjustToLegacy]*/,/*cPathInServer*/,.F./*lDisabeSetup*/,.F./*lTReport*/,@oPrintSetup,oPrintSetup:aOptions[PD_VALUETYPE]/*cPrinter*/,.F./*lServer*/)

	If oPrintSetup:aOptions[PD_VALUETYPE] == Nil
		RestArea(aAreaOld)
		Return
	Endif

	U_PrtNfeSef(cIdEnt,,,oDanfe,oPrintSetup)

Return

/*/{Protheus.doc} sfViewSF1
(long_description)
@author Iago Luiz Raimondi
@since 25/02/2015
@version 1.0
@param nPosRec, numérico, (Descrição do parâmetro)
@param nOpc, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfViewSF1(nPosRec,nOpc)

	Local	aRest	:= {nModulo,cModulo}
	nModulo	:= 2
	cModulo	:= "COM"

	DbSelectArea("SF1")
	DbSetOrder(1)
	Goto(nPosRec)

	If nOpc == 6
		A103Impri( "SF1", nPosRec, nOpc )
	Else
		Mata103( , , nOpc ,)
	Endif

	nModulo	:= aRest[1]
	cModulo	:= aRest[2]
Return


/*/{Protheus.doc} sfCriaArq
(long_description)
@author Iago Luiz Raimondi
@since 25/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaArq()

	Local cCliente,cLoja,cCEP,cRota,nDiaAtu,nDiaEnt,dData,aRota,aDias
	Local nReg 			:= 0
	Local nStatus 		:= 0
	Local nValBrut 		:= nValMerc := 0
	Local cMV_CONFFIS 	:= SuperGetMV("MV_CONFFIS")

	cQry := ""
	cQry += "SELECT F1_DOC,F1_SERIE,F1_FORNECE,F1_LOJA,F1_EMISSAO,F1_DTDIGIT,F1_VALMERC,F1_VALBRUT,F1_TIPO,F1_ESPECI3,F1_STATUS,R_E_C_N_O_ RECSF1 "
	cQry += "  FROM " + RetSqlName("SF1") + " F1 "
	cQry += " WHERE F1.D_E_L_E_T_ = ' ' "
	// Valida a primeira pergunta - Tipo de Documento
	If MV_PAR01 == 1 //Devolução
		cQry += "  AND F1_TIPO = 'D' "
	ElseIf MV_PAR01 == 2  // Normal
		cQry += "  AND F1_TIPO = 'N' "
	ElseIf MV_PAR01 == 3  // Beneficiamento
		cQry += "  AND F1_TIPO = 'B' "
	Else
		cQry += "  AND F1_TIPO IN('B','D','N') "  // Tipos Frete/Complemento Preço/Complemento IPI/ICMS não serão suportados
	Endif

	// Valida a segunda até quinta perguntas
	cQry += "   AND F1_FORNECE BETWEEN '"+MV_PAR02+"' AND '"+MV_PAR04+"' "
	cQry += "   AND F1_LOJA BETWEEN '"+MV_PAR03+"' AND '" +MV_PAR05+"' "

	// Valida a sexta e sétima perguntas
	cQry += "   AND F1_EMISSAO BETWEEN '"+Alltrim(DTOS(MV_PAR06))+"' AND '"+Alltrim(DTOS(MV_PAR07))+"' "

	// Valida a pergunta 11 e 12
	cQry += "   AND F1_DTDIGIT BETWEEN '"+Alltrim(DTOS(MV_PAR11))+"' AND '"+Alltrim(DTOS(MV_PAR12))+"' "

	// Valida a oitava pergunta
	If MV_PAR08 == 1
		cQry += "   AND F1_STATUS != ' ' "
	ElseIf MV_PAR08 == 2
		cQry += "   AND F1_STATUS = ' ' "
	Endif
	// 05/03/2020 - Adicionada condição para filtrar apenas notas mercantis
	cQry += "   AND F1_ESPECIE IN('SPED','NFA')"

	// 04/03/2021 - adicionda condição para só trazer notas que atualizam estoque
	If MsgYesNo("Filtrar notas que atualizam estoque?","Filtro de notas!")
		cQry += "   AND EXISTS (SELECT D1_COD "
		cQry += "                 FROM " + RetSqlName("SD1") + " D1, " + RetSqlName("SF4") + " F4 "
		cQry += "                WHERE D1.D_E_L_E_T_ =' ' "
		cQry += "                  AND D1_LOJA = F1_LOJA "
		cQry += "                  AND D1_FORNECE = F1_FORNECE "
		cQry += "                  AND D1_SERIE = F1_SERIE "
		cQry += "                  AND D1_DOC = F1_DOC "
		cQry += "                  AND D1_FILIAL = '"+xFilial("SD1") + "' "
		cQry += "                  AND F4.D_E_L_E_T_ = ' ' "
		cQry += "                  AND F4_ESTOQUE = 'S' "
		cQry += "                  AND F4_CODIGO = D1_TES "
		cQry += "                  AND F4_FILIAL = '"+xFilial("SF4")+"' )"
	Endif
	// Valida a nona e décima perguntas
	cQry += "   AND ((F1_TIPO IN('D','B') AND EXISTS "
	cQry += "                (SELECT A1_NOME "
	cQry += "                   FROM "+RetSqlName("SA1") + " A1 "
	cQry += "                  WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "                    AND A1_CGC BETWEEN '"+MV_PAR09+"' AND '"+MV_PAR10+"' "
	cQry += "                    AND A1_LOJA = F1_LOJA "
	cQry += "                    AND A1_COD = F1_FORNECE "
	cQry += "                    AND A1_FILIAL = '"+xFilial("SA1")+"')) "
	cQry += "                OR (F1_TIPO IN('N') AND EXISTS "
	cQry += "                (SELECT A2_NOME "
	cQry += "                   FROM "+RetSqlName("SA2") + " A2 "
	cQry += "                  WHERE A2.D_E_L_E_T_ = ' ' "
	cQry += "                    AND A2_CGC BETWEEN '"+MV_PAR09+"' AND '"+MV_PAR10+"' "
	cQry += "                    AND A2_LOJA = F1_LOJA "
	cQry += "                    AND A2_COD = F1_FORNECE "
	cQry += "                    AND A2_FILIAL = '"+xFilial("SA2")+"'))) "
	cQry += "   AND F1_FILIAL = '" + xFilial("SF1") +"' "
	cQry += " ORDER BY F1_FORNECE,F1_LOJA,F1_DTDIGIT,F1_DOC "

	TCQUERY cQry NEW ALIAS "QRP"

	Count to nReg

	dbselectarea("QRP")
	dbGotop()
	//ProcRegua(nReg)
	While !Eof()

		//IncProc("Processando Nota Fiscal Nº-> "+QRP->F1_DOC)

		If QRP->F1_TIPO $ "D#B" // Devolução ou Beneficiamento
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+QRP->F1_FORNECE+QRP->F1_LOJA)
		Else
			dbSelectArea("SA2")
			dbSetOrder(1)
			dbSeek(xFilial("SA2")+QRP->F1_FORNECE+QRP->F1_LOJA)
		Endif

		nStatus	:= 1

		// Verifica se há o controle de conferencia Fisica
		If cMV_CONFFIS == "S" .And. SF1->(FieldPos("F1_STATCON")) > 0
			If (QRP->F1_STATCON=="1" .Or. EMPTY(QRP->F1_STATCON)) .And. Empty(QRP->F1_STATUS)
				nStatus	:=	1	//'ENABLE' 		},;	// NF Nao Classificada
			ElseIf (QRP->F1_STATCON=="1" .Or. EMPTY(QRP->F1_STATCON)) .And. QRP->F1_TIPO=="N"
				nStatus	:= 	2	//'DISABLE'		},;	// NF Normal
			ElseIf QRP->F1_STATUS=="B"
				nStatus	:= 	3	//'BR_LARANJA'	},;	// NF Bloqueada
			ElseIf QRP->F1_STATUS=="C"
				nStatus :=  4 	// 'BR_VIOLETA'	},;	// NF Bloqueada s/classf.
			ElseIf (QRP->F1_STATCON=="1" .Or. EMPTY(QRP->F1_STATCON)) .And. QRP->F1_TIPO=="B"
				nStatus :=  5	// 'BR_CINZA'	},;	// NF de Beneficiamento
			ElseIf (QRP->F1_STATCON=="1" .Or. EMPTY(QRP->F1_STATCON)) .AND. QRP->F1_TIPO=="D"
				nStatus :=  6	// 'BR_AMARELO'	},;	// NF de Devolucao
			ElseIf QRP->F1_STATCON<>"1" .And. !EMPTY(QRP->F1_STATCON) .And. Empty(QRP->F1_STATUS)
				nStatus :=  7   // 'BR_PRETO'	}} 	// NF Bloq. para Conferencia
			Endif
		Else
			If Empty(QRP->F1_STATUS)
				nStatus	:= 	1	// 'ENABLE'		},;	// NF Nao Classificada
			ElseIf QRP->F1_STATUS=="B"
				nStatus := 	3	// 'BR_LARANJA'	},;	// NF Bloqueada
			ElseIf QRP->F1_STATUS=="C"
				nStatus :=  4 	// 'BR_VIOLETA'   },;	// NF Bloqueada s/classf.
			ElseIf QRP->F1_TIPO=="N"
				nStatus := 	2	// 'DISABLE'   	},;	// NF Normal
			ElseIf QRP->F1_TIPO=="B"
				nStatus := 	5	// 'BR_CINZA'  	},;	// NF de Beneficiamento
			ElseIf QRP->F1_TIPO=="D"
				nStatus := 	6	// 'BR_AMARELO'	} }	// NF de Devolucao
			Endif
		Endif

		If Empty(QRP->F1_VALBRUT)
			cQry := "SELECT SUM(D1_TOTAL-D1_VALDESC) VALMERC,"
			cQry += "       SUM(D1_TOTAL-D1_VALDESC+D1_VALIPI+D1_ICMSRET+D1_DESPESA+D1_VALFRE) VALBRUT "
			cQry += "  FROM "+RetSqlName("SD1")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND D1_LOJA = '"+QRP->F1_LOJA+"' "
			cQry += "   AND D1_FORNECE = '"+QRP->F1_FORNECE+"' "
			cQry += "   AND D1_SERIE = '"+QRP->F1_SERIE+"' "
			cQry += "   AND D1_DOC = '"+QRP->F1_DOC+"' "
			cQry += "   AND D1_FILIAL = '"+xFilial("SD1")+"' "

			TCQUERY cQry NEW ALIAS "QSD1"

			nValMerc := QSD1->VALMERC
			nValBrut := QSD1->VALBRUT
			QSD1->(DbCloseArea())
		Else
			nValMerc	:= QRP->F1_VALMERC
			nValBrut	:= QRP->F1_VALBRUT
		Endif

		AAdd( aSF1, { 	nStatus,;							// 1
		.F.,;													// 2
		QRP->F1_DOC,;								        	// 3
		QRP->F1_SERIE,;										// 4
		QRP->F1_FORNECE +"/"+QRP->F1_LOJA,;					//5
		IIf(QRP->F1_TIPO $ "D#B",SA1->A1_NOME,SA2->A2_NOME),;// 6
		STOD(QRP->F1_EMISSAO),; 								// 7
		STOD(QRP->F1_DTDIGIT),;								// 8
		nValMerc,;							  					// 9
		nValBrut,;								 				// 10
		QRP->RECSF1,;											// 11
		QRP->F1_ESPECI3})									//	12 -

		dbSelectArea("QRP")
		dbSkip()
	Enddo

	QRP->(DbCloseArea())
	//ProcRegua(1)
	//IncProc("Finalizando...")

Return

/*/{Protheus.doc} sfDblClick
(long_description)
@author Iago Luiz Raimondi
@since 25/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfDblClick()

	// Verifica se já tem pedido de remessa e se o item ainda não está marcado
	If !Empty(aSF1[oSF1:nAt,12]) .And. !aSF1[oSF1:nAt,2]
		If !MsgYesNo("Para esta nota fiscal já tem pedido de venda de remessa. Deseja continuar assim mesmo?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		Endif
	Endif

	aSF1[oSF1:nAt,2] := Iif(!aSF1[oSF1:nAt,2] .and. aSF1[oSF1:nAt,1]>=1 ,.T., .F.)

Return


/*/{Protheus.doc} sfLegenda
(long_description)
@author Iago Luiz Raimondi
@since 25/02/2015
@version 1.0
@param nStatus, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfLegenda(nStatus)

	nRet := 1

	If nStatus	==	1
		nRet := oENABLE		// NF Nao Classificada
	ElseIf nStatus	== 	2
		nRet := oDISABLE	// NF Normal
	ElseIf nStatus	== 	3
		nRet := oBR_LARANJA	// NF Bloqueada
	ElseIf nStatus 	==  4
		nRet := oBR_VIOLETA	// NF Bloqueada s/classf.
	ElseIf nStatus  ==  5
		nRet := oBR_CINZA	// NF de Beneficiamento
	ElseIf nStatus  ==  6
		nRet := oBR_AMARELO // NF de Devolucao
	ElseIf nStatus  ==  7
		nRet := oBR_PRETO	// NF Bloq. para Conferencia
	Endif

Return nRet

/*/{Protheus.doc} stVldPeSF1
(long_description)
@author Iago Luiz Raimondi
@since 25/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stVldPeSF1()

	Local nAscan := Ascan(aSF1,{|x|x[3]==cVarPesq})

	If nAscan <=0
		nAscan	:= 1
	Endif
	oSF1:nAT 	:= nAscan
	cVarPesq	:= space(06)
	oSF1:Refresh()
	oSF1:SetFocus()

Return

/*/{Protheus.doc} ValidPerg
(long_description)
@author Iago Luiz Raimondi
@since 25/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ValidPerg()

	Local _sAlias := Alias()
	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)
	cPergXml :=  PADR(cPerg,Len(SX1->X1_GRUPO))
	//"X1_GRUPO","X1_ORDEM","X1_PERGUNT","X1_PERSPA","X1_PERENG","X1_VARIAVL","X1_TIPO","X1_TAMANHO","X1_DECIMAL","X1_PRESEL","X1_GSC","X1_VALID","X1_VAR01","X1_DEF01","X1_DEFSPA1","X1_DEFENG1","X1_CNT01","X1_VAR02","X1_DEF02","X1_DEFSPA2","X1_DEFENG2","X1_CNT02","X1_VAR03","X1_DEF03","X1_DEFSPA3","X1_DEFENG3","X1_CNT03"	,"X1_VAR04","X1_DEF04","X1_DEFSPA4","X1_DEFENG4","X1_CNT04"	,"X1_VAR05","X1_DEF05","X1_DEFSPA5","X1_DEFENG5","X1_CNT05","X1_F3","X1_PYME","X1_GRPSXG","X1_HELP"
	Aadd(aRegs,{cPerg ,"01"		,"Tipo Documento"       ,"Tipo Documento"   ,"Tipo Documento"   ,"mv_ch1"	,"N"	,1				,0				,1				,"C"		,""			,"mv_par01"	,"Devolução","Devolução"	,"Devolução"	,""			,""			,"Normal"       ,"Normal"			,"Normal"			,""			,""			,"Beneficiamento","Benefi"	,"Beneficiamento",""		,""			,"Todas"	,"Todas"		,"Todas"		,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"02"		,"Fornecedor de"		,"Fornecedor de "	 ,"Fornecedor de"	,"mv_ch2"	,"C"	,6				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA2" 		,"S"		,"001"			,""})
	Aadd(aRegs,{cPerg ,"03"		,"Loja "				,"Loja "			,"Loja "			,"mv_ch3"	,"C"	,2				,0				,0				,"G"		,""			,"mv_par03"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"04"		,"Fornecedor Até"		,"Fornecedor Até"	 ,"Fornecedor Até"	,"mv_ch4"	,"C"	,6				,0				,0				,"G"		,""			,"mv_par04"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA2" 		,"S"		,"001"			,""})
	Aadd(aRegs,{cPerg ,"05"		,"Loja "				,"Loja "			,"Loja Até"			,"mv_ch5"	,"C"	,2				,0				,0				,"G"		,""			,"mv_par05"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"06"		,"Emissão de"			,"Emissão de "	 	,"Emissão de"		,"mv_ch6"	,"D"	,8				,0				,0				,"G"		,""			,"mv_par06"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"07"		,"Emissão até"			,"Emissão até"		,"Emissão"			,"mv_ch7"	,"D"	,8				,0				,0				,"G"		,""			,"mv_par07"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"08"		,"Status da Nota"       ,"Status"           ,"Status"	        ,"mv_ch8"	,"N"	,1				,0				,1				,"C"		,""			,"mv_par08"	,"Nota Fiscal","Nota Fiscal","Nota Fiscal"	,""	        ,""			,"Pré-nota"		,"Pré-nota"			,"Pré-nota" 		,""			,""         ,"Ambas"	,"Ambas"		,"Ambas"		,""			,""			,""			,""				,""				,""			,""			,""			,"" 		,""				,""			,""			,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"09"		,"CNPJ Forn.de"			,"Fornecedor de "	 ,"Fornecedor de"	,"mv_ch9"	,"C"	,14				,0				,0				,"G"		,""			,"mv_par09"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"10"		,"CNPJ Forn.Até"		,"Fornecedor Até"	 ,"Fornecedor Até"	,"mv_cha"	,"C"	,14				,0				,0				,"G"		,""			,"mv_par10"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"11"		,"Digitação de"			,"Digitação de "	,"Digitação de"		,"mv_chb"	,"D"	,8				,0				,0				,"G"		,""			,"mv_par11"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg ,"12"		,"Digitação até"		,"Digitação até"	,"Digitação Até"	,"mv_chc"	,"D"	,8				,0				,0				,"G"		,""			,"mv_par12"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})

	For i:=1 to Len(aRegs)
		If !dbSeek(cPergXml+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock("SX1")
		Endif
	Next

	dbSelectArea(_sAlias)

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
