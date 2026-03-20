#Include "Topconn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"
#DEFINE NULTIMALINHA	2500
#DEFINE NMARGESQUERDA	0050
#DEFINE NMARGDIREITA	2300

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ DEC05R02 บ     ฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบ    - Relatorio Pick List -                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑAutor: Fernando Sutter บฑฑ Data: 17/07/2019                             บฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function DEC05R02()

	Local 	lSetupPrn 	:= Type("oSetupRel") <> "U"
	Private oFont6      := TFont():New( "Arial",,13,,.T.,,,,,.f. )
	Private oFont9      := TFont():New( "Arial",,15,,.F.,,,,,.f. )
	Private oFont7      := TFont():New( "Arial",,13,,.F.,,,,,.f. )
	Private oFont8      := TFont():New( "Arial",,15,,.F.,,,,,.f. )
	Private oFontCabN   := TFont():New( "Arial",,18,,.t.,,,,,.f. )
	Private oFontCabN2  := TFont():New( "Arial",,26,,.t.,,,,,.f. )
	Private cStartPath  := GetSrvProfString("Startpath","")
	Private cFileLogo   := cStartPath+"\logoped.bmp" //"lgmid.png" // IIf(cEmpAnt=="01","\logo01.png","\logo02.png")
	Private nLin		:= 1//NULTIMALINHA + 1
	Private lPrinted	:= .F.
	Private nPagina		:= 1
	Private cAliasTemp 	:= "DEC05R01"
	Private cDirTmpFat 	:= ALLTRIM(GETTEMPPATH())
	Private oPrint
	Private lPrintDesc	:= .F. // Imprime descri็ใo do Produto no lugar de n๚mero de caixas/fator e saldo estoque
	Private aColPoIt 	:= Iif(lPrintDesc,{80,180,580,0850,1080,1350},{80,300,700,0975,1300,1650, 1950})

	// Verifica se existe o arquivo de Logo por empresa
	If File(cStartPath+"\logoped_"+cEmpAnt+".bmp" )
		cFileLogo	:= cStartPath+"\logoped_"+cEmpAnt+".bmp"
	Endif

/*
	IF (SC5->C5_SITDEC != '2')
	MsgAlert("Pick List liberado apenas para pedidos em montagem.", "Aten็ใo")
	RETURN
	ENDIF
*/
	cDir1 :=  "\pedidos\" //Alltrim(GetMV("MV_ZDIRXML"))

//Verifico se existe a pasta temp e pasta processados. Caso nใo tenha eu crio as duas:
	If !ExistDir( Alltrim(cDir1) )
		MakeDir( Alltrim(cDir1) )
	EndIf

	mv_par01 := SC5->C5_NUM
	mv_par02 := SC5->C5_NUM
	//FWMsPrinter(): New ( < cFilePrintert >            , [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] ) -->
	oPrint:=FWMSPrinter():New("pick_"+SC5->C5_NUM+".pdf",IMP_SPOOL ,                   ,                  ,.T.,            ,     ,            ,           ,             ,        ,)   //TMSPrinter():New()
	//oPrint:=FWMSPrinter():New("pick_"+SC5->C5_NUM+".pdf",6,.T.)
	oPrint:SetResolution(72)
	oPrint:SetPortrait()
	oPrint:SetPaperSize(9)
	oPrint:SetMargin(60,60,60,60)

	If lSetupPrn
		oPrint:lServer := oSetupRel:GetProperty(PD_DESTINATION)==AMB_SERVER
		// ----------------------------------------------
		// Define saida de impressใo
		// ----------------------------------------------
		If oSetupRel:GetProperty(PD_PRINTTYPE) == IMP_SPOOL
			oPrint:nDevice := IMP_SPOOL
			// ----------------------------------------------
			// Salva impressora selecionada
			// ----------------------------------------------
			fwWriteProfString(GetPrinterSession(),"DEFAULT", oSetupRel:aOptions[PD_VALUETYPE], .T.)
			oPrint:cPrinter := oSetupRel:aOptions[PD_VALUETYPE]
		ElseIf oSetupRel:GetProperty(PD_PRINTTYPE) == IMP_PDF
			oPrint:nDevice := IMP_PDF
			// ----------------------------------------------
			// Define para salvar o PDF
			// ----------------------------------------------
			oPrint:cPathPDF := oSetupRel:aOptions[PD_VALUETYPE]
		Endif
	Else
		oPrint:cPathPDF:= ALLTRIM(GETTEMPPATH())
		if oPrint:cPrinter == Nil
			Return
		endif
	Endif

	oPrint:StartPage()

	RptStatus({|lEnd| sfImprime(@lEnd)},"Imprimindo........")

	oPrint:EndPage()

	oPrint:Print()

	CpyT2S( cDirTmpFat+"pick_"+SC5->C5_NUM+".pdf", cDir1 )

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Funcao auxiliar chamada pela RptStatus. A funcao RptStatus บฑฑ
ฑฑบ          ณ monta a janela com a regua de processamento.               บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function sfImprime(lEnd)

	Local cItem, cMcCod, cUm, nQtdVen, nNumItens, nSomaQuant, nFatConv, nNumDeCaix, cEndere, nSomaCaixa, cSldEnd
	Local cTipConv
	Local lUsaLocal	:= (SuperGetMV("MV_LOCALIZ") == "S")
	Local cAliasNew	:= "SC9"
	Local nQtdLin	:= 1
	Local nTamLin	:= 95
	Local nCntLin
	nNumItens := 0
	nSomaQuant := 0
	nSomaCaixa := 0

	cQuery := "	select C5_NUM "
	cQuery += "	from " + RetSqlName("SC5")+" "
	cQuery += "	where C5_FILIAL = '"+xFilial("SC5")+"' and D_E_L_E_T_ = ' ' "

	If !Empty(mv_par01)
		cQuery += "	and C5_NUM >=  '"+mv_par01+"'"
	EndIf

	If !Empty(mv_par02)
		cQuery += "	and C5_NUM <=  '"+mv_par02+"'"
	EndIf

	cQuery += "	order by C5_NUM "

	If (Select(cAliasTemp) <> 0)
		dbSelectArea(cAliasTemp)
		dbCloseArea()
	Endif

	cQuery := ChangeQuery(cQuery)
	TCQuery cQuery NEW ALIAS &cAliasTemp

	(cAliasTemp)->(dbGoTop())

	While !(cAliasTemp)->(Eof())

		SC5->(dbSetOrder(1))
		SC5->(dbSeek(xFilial("SC5")+(cAliasTemp)->C5_num))

		lPrinted := .F.
		//nLin		:= NULTIMALINHA + 1

		dEmissao	:= SC5->C5_emissao
		cCliente	:= SC5->C5_cliente
		cLoja		:= SC5->C5_lojacli
		cTransp     := Posicione("SA4",1,xFilial("SA4")+SC5->C5_TRANSP,"A4_NOME")
		cMsgInt		:= SC5->C5_ZMSGINT

		// Posiciona no cliente
		SA1->(dbSetOrder(1))
		SA1->(dbSeek(xFilial("SA1")+cCliente+cLoja))

		cAliasNew := GetNextAlias()
		cQuery := "SELECT SC9.R_E_C_N_O_ SC9REC,"
		cQuery += "SC9.C9_PEDIDO,SC9.C9_FILIAL,SC9.C9_QTDLIB,SC9.C9_PRODUTO, "
		cQuery += "SC9.C9_LOCAL,SC9.C9_LOTECTL,SC9.C9_POTENCI,"
		cQuery += "SC9.C9_NUMLOTE,SC9.C9_DTVALID,SC9.C9_NFISCAL,SC9.C9_ITEM,SC9.C9_NUMSERI "

		If lUsaLocal
			cQuery += ",SDC.DC_LOCALIZ,SDC.DC_QUANT,SDC.DC_QTDORIG"
		EndIf

		cQuery += " FROM "
		cQuery += RetSqlName("SC9") + " SC9 "

		If lUsaLocal
			cQuery += "LEFT JOIN "+RetSqlName("SDC") + " SDC "
			cQuery += "ON SDC.DC_PEDIDO=SC9.C9_PEDIDO AND SDC.DC_ITEM=SC9.C9_ITEM AND SDC.DC_SEQ=SC9.C9_SEQUEN AND SDC.D_E_L_E_T_ = ' '"
		EndIf

		cQuery += "WHERE SC9.C9_FILIAL  = '"+xFilial("SC9")+"'"
		cQuery += " AND  SC9.C9_PEDIDO >= '"+mv_par01+"'"
		cQuery += " AND  SC9.C9_PEDIDO <= '"+mv_par02+"'"
		cQuery += " AND  C9_BLEST = ' '  " // 13/01/2021 - Filtra Restri็๕es de estoque e jแ faturados
		cQuery += " AND  C9_BLCRED = '  ' " // 13/01/2021 - Filtra restri็๕es de Cr้dito e jแ faturados
		cQuery += " AND SC9.D_E_L_E_T_ = ' '"
		cQuery += "ORDER BY SC9.C9_FILIAL,SC9.C9_PEDIDO,SC9.C9_CLIENTE,SC9.C9_LOJA,

		If lUsaLocal
			cQuery += " SDC.DC_LOCALIZ,"
		EndIf

		cQuery += "SC9.C9_PRODUTO,SC9.C9_LOTECTL,SC9.C9_NUMLOTE,SC9.C9_DTVALID"
		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasNew,.T.,.T.)

		(cAliasNew)->(dbGoTop())

		While (cAliasNew)->(!Eof())
			If !lPrinted
				sfCabec()
				lPrinted := .T.
			EndIf

			// Funcao de controle para quebra de pagina
			sfControl()

			cItem       := (cAliasNew)->C9_ITEM
			cMcCod      := (cAliasNew)->C9_PRODUTO

			IF lUsaLocal
				cEndere     := (cAliasNew)->DC_LOCALIZ
				nQtdVen     := Iif((cAliasNew)->DC_QUANT>0,(cAliasNew)->DC_QUANT,(cAliasNew)->C9_QTDLIB)

				dbSelectArea("SBF")
				dbSetOrder(1)
				If dbSeek(FWxFilial("SBF")+(cAliasNew)->C9_LOCAL+(cAliasNew)->DC_LOCALIZ+(cAliasNew)->C9_PRODUTO+(cAliasNew)->C9_NUMSERI+(cAliasNew)->C9_LOTECTL+(cAliasNew)->C9_NUMLOTE)
					cSldEnd := STR(SBF->BF_QUANT-nQtdVen)
				Else
					cSldEnd := " "
				EndIf

			ELSE
				cEndere     := "S/E"
				cSldEnd 	:= " "
				nQtdVen     := (cAliasNew)->C9_QTDLIB
			ENDIF

			cUm         := POSICIONE("SB1",1,xFilial("SB1")+cMcCod,"B1_UM")
			nFatConv    := POSICIONE("SB1",1,xFilial("SB1")+cMcCod,"B1_CONV")
			cTipConv    := POSICIONE("SB1",1,xFilial("SB1")+cMcCod,"B1_TIPCONV")
			cDescPrd	:= Posicione("SB1",1,xFilial("SB1")+cMcCod,"B1_DESC")
			nNumDeCaix  := IIF(cTipConv == "M", nQtdVen * nFatConv, nQtdVen/nFatConv)
			nNumItens += 1

			nSomaCaixa	+= nNumDeCaix

			IF cUm == 'GF'
				nSomaQuant += nQtdVen
			ENDIF


			//Imprime a linha com os itens
			// aColPoIt := {80,300,700,0975,1220,1500}
			oPrint:Say(nLin+10, aColPoIt[1]       , cItem                          ,oFont9)
			oPrint:Say(nLin+10, aColPoIt[2]       , cEndere                        ,oFont9)
			oPrint:Say(nLin+10,  aColPoIt[3]       , STR(nQtdVen)                  ,oFont9)
			//oPrint:Say(nLin+10, 1040       , ALLTRIM(cUm)                          ,oFont6)
			oPrint:Say(nLin+10,  aColPoIt[4]       , ALLTRIM(cMcCod)               ,oFont9)
			If lPrintDesc
				oPrint:Say(nLin+10,  aColPoIt[5]       , STR(nFatConv)              ,oFont6)
				oPrint:Say(nLin+10,  aColPoIt[6]       , cDescPrd					,oFont6)
			Else
				oPrint:Say(nLin+10,  aColPoIt[5]       , STR(nFatConv)                 ,oFont9)
				oPrint:Say(nLin+10,  aColPoIt[6]       , STR(nNumDeCaix,16,2)          ,oFont9)
				//oPrint:Say(nLin+10,  aColPoIt[7]       , cSldEnd                       ,oFont6)
			Endif
			nLin += 60
			(cAliasNew)->(dbSkip())

		EndDo

		nLin += 40

		//Formulแrio de uso interno
		oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )
		nLin += 40
		oPrint:Say(nLin+10, 0060 , "Total de Itens da Listagem: " + ALLTRIM(STR(nNumItens))  ,oFont8)
		nLin += 40
		oPrint:Say(nLin+10, 0060 , "Total de Garrafas (UM: GF): " + ALLTRIM(STR(nSomaQuant))  ,oFont8)
		nLin += 40
		oPrint:Say(nLin+10, 0060 , "Total de Caixas: " + ALLTRIM(STR(nSomaCaixa,16,2))  ,oFont8)

		nLin += 110
		oPrint:Say(nLin, 0060, "Montado por: ", oFont8)
		oPrint:Box(nLin - 50, 0400, nLin + 30, 1200)
		oPrint:Say(nLin, 1230, "Conferido por: ", oFont8)
		oPrint:Box(nLin - 50, 1500, nLin + 30, 2100)

		nLin += 110
		oPrint:Say(nLin, 0060, "Quantidade Volumes: ", oFont8)
		oPrint:Box(nLin-50, 0575, nLin+30, 1200)
		oPrint:Say(nLin, 1230, "Tipo Volume: ", oFont8)
		oPrint:Say(nLin, 1500, "Palete", oFont8)
		oPrint:Box(nLin-50, 1650, nLin+30, 1750)
		oPrint:Say(nLin, 1775, "Total CX: ", oFont8)
		oPrint:Box(nLin-50, 1950, nLin+30, 2100)

		nLin += 110
		oPrint:Say(nLin, 1500, "Caixa", oFont8)
		oPrint:Box(nLin-50, 1650, nLin+30, 1750)

		nLin += 110
		oPrint:Say(nLin, 0060, "Liberado Faturamento: ", oFont8)
		oPrint:Say(nLin, 725, "Sim", oFont8)
		oPrint:Box(nLin-50, 800, nLin+30, 900)
		oPrint:Say(nLin, 1025, "Nใo", oFont8)
		oPrint:Box(nLin-50, 1100, nLin+30, 1200)


		//TSCB57 - William Farias - INICIO
		If !Empty(cMsgInt)
			nLin += 40
			oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )
			nLin += 50
			oPrint:Say(nLin	,0080	,"Mensagem Interna:"	,oFont6)
			nLin += 40
			nQtdLin := MLCount(cMsgInt, nTamLin)// Quantidade de linhas do texto
			For nCntLin:=1 To nQtdLin
				// Imprime a linha
				oPrint:Say(nLin, 0080, MemoLine(cMsgInt, nTamLin, nCntLin), oFont8)
				If nCntLin < nQtdLin
					nLin += 35
				EndIf
			Next nCntLin
		EndIf
		//TSCB57 - FIM


		oPrint:EndPage()
		nPagina	:= 1
		(cAliasTemp)->(dbSkip())

		If !(cAliasTemp)->(EOF())
			oPrint:StartPage()
		EndIf

	EndDo

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Funcao para imprimir o cabecalho do orcamento / pedido.    บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function sfCabec()

	Local cLocal, cLocDescri

	nLin := 70
	nLiN := 120

	oPrint:SayBitmap( nLin, 50, cFileLogo , 300, 210 )
	oPrint:Say(nLin + 30, 420, "Listagem de Produtos para Montagem", oFontCabN)
	oPrint:Say(nLin + 40,1800, SC5->C5_num, oFontCabN2)
	nLin += 50
	oPrint:Say(nLin+25,600,SUBSTR((SM0->M0_nomecom),0,44),oFontCabN)

	nLin += 50
	nLin += 200
	nLin += 50

	oPrint:Say(nLin+10,070,"Nome ",oFont7)
	oPrint:Say(nLin+10,350,SUBSTR(Alltrim(SA1->A1_nome),0 , 44 ),oFont8)
	oPrint:Say(nLin+10,1650,"Deposito ",oFont7)

	cLocal := Posicione("SC6",1,xFilial("SC6")+SC5->C5_num,"C6_LOCAL")
	cLocDescri := Posicione("NNR",1,xFilial("NNR")+cLocal, "NNR_DESCRI")

	oPrint:Say(nLin+10,1850, cLocal,oFont8)

	nLin += 40
	oPrint:Say(nLin+10,070,"Contato ",oFont7)
	oPrint:Say(nLin+10,350,AllTrim(SA1->A1_CONTATO),oFont8)
//	oPrint:Say(nLin+10,1650,"Digitador ",oFont7)
//	oPrint:Say(nLin+10,1850,UsrRetName(RetCodUsr()),oFont8)
	oPrint:Say(nLin+10,1650,"Usr Inclusใo ",oFont7)
	oPrint:Say(nLin+10,1850,SC5->C5_LOGINC,oFont8)

	nLin += 40
	oPrint:Say(nLin+10,070,"Cidade ",oFont7)
	oPrint:Say(nLin+10,350,AllTrim(SA1->A1_MUN) + " - " + Alltrim(SA1->A1_EST),oFont8)
	oPrint:Say(nLin+10,1650,"Emissใo ",oFont7)
	oPrint:Say(nLin+10,1850,Dtoc(dEmissao),oFont8)

	nLin += 40
	oPrint:Say(nLin+10,070,"Endereco ",oFont7)
	oPrint:Say(nLin+10,350,AllTrim(SA1->A1_END),oFont8)
	oPrint:Say(nLin+10,1650,"Impressใo ",oFont7)
	oPrint:Say(nLin+10,1850,DTOC(Date()),oFont8)

	nLin += 40
	oPrint:Say(nLin+10,070,"Transportadora ",oFont7)
	oPrint:Say(nLin+10,350,AllTrim(cTransp),oFont8)
	oPrint:Say(nLin+10,1650,"Hr Impressใo ",oFont7)
	oPrint:Say(nLin+10,1850,Time(),oFont8)
	nLin += 40
	oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )
	nLin += 40
	oPrint:Say(nLin+10,070,"PRODUTOS",oFontCabN)

	nLin += 40

// Imprime o cabecalho dos itens
	oPrint:Say(nLin+10, aColPoIt[1] , "Item"        				,oFont6)
	oPrint:Say(nLin+10, aColPoIt[2] , "Endere็amento"    			,oFont7)
	oPrint:Say(nLin+10, aColPoIt[3] , "Quantidade" 					,oFont6)
	//oPrint:Say(nLin+10, 0975 , "Unid. Medida"     ,oFont6)
	oPrint:Say(nLin+10, aColPoIt[4] , "C๓digo Prod."     			,oFont6)
	If lPrintDesc
		oPrint:Say(nLin+10, aColPoIt[5] , "Quant.p/Caixa"   	  	,oFont6)
		oPrint:Say(nLin+10, aColPoIt[6] , "Descri็ใo Produto"     	,oFont6)

	Else
		oPrint:Say(nLin+10, aColPoIt[5] , "Quant. por Caixa"    	,oFont6)
		oPrint:Say(nLin+10, aColPoIt[6] , "Quant. de Caixa"    		,oFont6)
		//oPrint:Say(nLin+10, aColPoIt[7] , "Saldo Endere็o"    		,oFont6)
	Endif
	nLin += 40

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDescricao ณ Funcao para controle de quebra de pagina.                  บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function sfControl()

	If nLin > NULTIMALINHA
		nPagina++
		nLin += 60
		oPrint:Say( nLin , 950, "*** CONTINUA NA PมGINA :"+Transform(nPagina,"@E 99")+" ***", oFont6, 100 )
		oPrint:EndPage()
		oPrint:StartPage()
		sfCabec()
	EndIf

Return
