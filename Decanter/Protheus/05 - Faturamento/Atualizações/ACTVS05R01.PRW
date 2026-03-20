#Include "Topconn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"
#DEFINE NULTIMALINHA	2500
#DEFINE NMARGESQUERDA	0050
#DEFINE NMARGDIREITA	2300
#define DMPAPER_A4
#define DMPAPER_LETTER


/*/{Protheus.doc} ACTVS05R01
Relatorio Pedido de Vendas
@type function
@author Decanter 
@since 10/06/2021
@return return_type, return_description
/*/
User Function ACTVS05R01()

	Local 	lSetupPrn 	:= Type("oSetupRel") <> "U"
	Private cUsrAux 	:= UsrRetName(RetCodUsr())
	Private oFont1      := TFont():New( "Arial",,15,,.t.,,,,,.t. )
	Private oFont2      := TFont():New( "Arial",,11,,.F.,,,,,.f. )
	Private oFont3      := TFont():New( "Arial",,11,,.t.,,,,,.f. )
	Private oFont6      := TFont():New( "Arial",,13,,.T.,,,,,.f. )
	Private oFont7      := TFont():New( "Arial",,13,,.F.,,,,,.f. )
	Private oFontCab    := TFont():New( "Arial",,18,,.t.,,,,,.F. )
	Private oFontCabN   := TFont():New( "Arial",,18,,.t.,,,,,.f. )
	Private cStartPath  := GetSrvProfString("Startpath","")
	Private cFileLogo   := cStartPath+"\logoped.bmp" //"lgmid.png" // IIf(cEmpAnt=="01","\logo01.png","\logo02.png")
	Private nLin		:= NULTIMALINHA + 1
	Private cVendedor   := "" , cContato := "", cDepto := ""
	Private lPrinted	:= .F.
	Private nPagina		:= 1
	Private nTotal		:= 0
	Private nValIpi		:= 0
	Private nValorST    := 0
	Private cCliente, cLoja, cCliEnt, cLojaEnt, cNum, cCondPag, cCodVen, lPedido
	Private cAliasItem, cPrefixoItem, cValidade, cPedOrc, cMsgContDe, cMsgContAte
	Private dEmissao, dEntrega, cMsgVendedor, cPrazo, cMsgInt
	Private cEndEmpAx, cMunEmpAx, cEstEmpAx, cCepEmpAx, cTelEmpAx, cFaxEmpAx, cTabela
	Private cObs1, cObs2, cObs3, cObs4, cObsSim := "", cFrase
	Private cPerg 		:= "DECPED"
	Private cAliasTemp 	:= "DEC05R01"
	Private oPrint


	// Verifica se existe o arquivo de Logo por empresa
	If File(cStartPath+"\logoped_"+cEmpAnt+".bmp" )
		cFileLogo	:= cStartPath+"\logoped_"+cEmpAnt+".bmp"
	Endif

	cDir1 :=  "\pedidos\" //Alltrim(GetMV("MV_ZDIRXML"))

	//Verifico se existe a pasta temp e pasta processados. Caso não tenha eu crio as duas:
	If !ExistDir( Alltrim(cDir1) )
		MakeDir( Alltrim(cDir1) )
	EndIf

	mv_par01 := SC5->C5_NUM
	mv_par02 := SC5->C5_NUM

	//FWMsPrinter(): New ( < cFilePrintert >            , [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] ) --> oPrinter
	oPrint:=FWMSPrinter():New("ped_"+SC5->C5_NUM+".pdf" ,IMP_SPOOL  ,                   ,                 , lSetupPrn,    , , , , ,)   //TMSPrinter():New()
	oPrint:SetResolution(72)
	oPrint:SetPortrait()
	oPrint:SetPaperSize(9)
	//oPrint:SetPaperSize(DMPAPER_LETTER)
	oPrint:SetMargin(60,60,60,60)
	
	If lSetupPrn
		oPrint:lServer := oSetupRel:GetProperty(PD_DESTINATION)==AMB_SERVER
		// ----------------------------------------------
		// Define saida de impressão
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
		If oPrint:cPrinter == Nil
			Return
		Endif
	Endif
	oPrint:StartPage()
	//oPrint:SetPortrait()  //modo retrato
	//oPrint:Setup()

	RptStatus({|lEnd| sfImprime(@lEnd)},"Imprimindo........")

	//oPrint:Preview()
	oPrint:EndPage()

	oPrint:Print()

	
	//move para o diretorio do parametro
	//CpyS2T("\orcam\"+"ped_"+SC5->C5_NUM+".pdf", "c:\orcam\" )

Return


/*/{Protheus.doc} sfImprime
Funcao auxiliar chamada pela RptStatus. A funcao RptStatus monta a janela com a regua de processamento. 
@type function
@author Decanter 
@since 10/06/2021
@param lEnd, logical, param_description
@return return_type, return_description
/*/
Static Function sfImprime(lEnd)

	Local cItem, cMcCod, cLocal, cDescri, cUm, nQtdVen, nPrcVen, nValor, cNcm, dEmis2
	Local nQtdLin	:= 1
	Local nTamLin	:= 113
	Local nCntLin
	Local lUsaLocal	:= (SuperGetMV("MV_LOCALIZ") == "S")

	cQuery := "	select C5_NUM "
	cQuery += "	from " + RetSqlName("SC5")+" "
	cQuery += "	where C5_FILIAL = '"+xFilial("SC5")+"' and D_E_L_E_T_ = ' ' "
	If !Empty(mv_par01)
		cQuery += "	and C5_NUM >=  '"+mv_par01+"'"
	EndIf
	If !Empty(mv_par02)
		cQuery += "	and C5_NUM <=  '"+mv_par02+"'"
	EndIf

	//If !Empty(mv_par03)
	//	cQuery += "	and C5_EMISSAO >= '"+Dtos(mv_par03)+"'"
	//EndIf
	//If !Empty(mv_par04)
	//	cQuery += "	and C5_EMISSAO <= '"+Dtos(mv_par04)+"'"
	//EndIf
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
		SC5->(dbSeek(xFilial("SCJ")+(cAliasTemp)->C5_num))

		lPrinted := .F.
		nLin		:= NULTIMALINHA + 1

		cNum		:= SC5->C5_num
		cAliasItem	:= "SC6"
		cPrefixoItem:= "SC6->C6_"
		dEmissao	:= SC5->C5_emissao
		cCliente	:= SC5->C5_cliente
		cLoja		:= SC5->C5_lojacli
		cCliEnt 	:= SC5->C5_client
		cLojaEnt	:= SC5->C5_lojaent
		cCondPag	:= SC5->C5_condpag
		dEMIS2      := SC5->C5_emissao
		cTransp     := Posicione("SA4",1,xFilial("SA4")+SC5->C5_TRANSP,"A4_NOME")
		cVendedor   := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME")
		//cEmailV     := Posicione("SA3",1,xFilial("SA3")+SCJ->CJ_VENDEDO,"A3_EMAIL")
		//cTelVend    := "("+AllTrim(Posicione("SA3",1,xFilial("SA3")+SCJ->CJ_VENDEDO,"A3_DDDTEL"))+") "+;
			//				Transform(Posicione("SA3",1,xFilial("SA3")+SCJ->CJ_VENDEDO,"A3_TEL"),PesqPict("SA1","A1_TEL"))
		//dDtEntrega  := SCJ->CJ_FECENT
		//dValidade   := SCJ->CJ_VALIDA
		//cVolumes    := SCJ->CJ_VOLUME
		cMsgInt		:= SC5->C5_ZMSGINT

		cTpFrete    := ""
		If AllTrim(SC5->C5_TPFRETE) == "C"
			cTpFrete := "CIF"
		ElseIf AllTrim(SC5->C5_TPFRETE) == "F"
			cTpFrete := "FOB"
		ElseIf AllTrim(SC5->C5_TPFRETE) == "T"
			cTpFrete := "Terceiros"
		ElseIf AllTrim(SC5->C5_TPFRETE) == "S"
			cTpFrete := "Sem Frete"
		EndIf

		cCodVen		:= ""
		cValidade	:= ""
		cPedOrc		:= "Pedido: "
		cMsgContDe	:= ""
		cMsgContAte	:= ""
		lPedido		:= .T.

		cFrase		:= "Optante Simples Nacional: "
		cObsSim		:= IIf (Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE,"A1_SIMPLES")== '1', cFrase+"SIM", cFrase+"NÃO")
		cPrazo		:= ""
		cTabela     := SC5->C5_TABELA
		nFrete      := SC5->C5_FRETE
		nDespesa    := SC5->C5_DESPESA
		nSeguro     := SC5->C5_SEGURO


		//cCotCli     := SCJ->CJ_COTCLI
		cObs        := "" //SC5->C5_OBSERV

		cEndEmpAx	:= SM0->M0_endent
		cMunEmpAx	:= SM0->M0_cident
		cEstEmpAx	:= SM0->M0_estent
		cCepEmpAx	:= SM0->M0_cepent
		cTelEmpAx	:= SM0->M0_tel
		cFaxEmpAx	:= SM0->M0_fax

		// Posiciona no cliente
		SA1->(dbSetOrder(1))
		SA1->(dbSeek(xFilial("SA1")+cCliente+cLoja))

		// Posiciona na condicao de pagamento
		SE4->(dbSetOrder(1))
		SE4->(dbSeek(xFilial("SE4")+cCondpag))

		//If !Empty(cCodVen)
		//	cVendedor := Posicione("SA3",1,xFilial("SA3")+cCodVen,"A3_NOME")
		//Endif

		// Posiciona nos itens
		(cAliasItem)->(dbSetOrder(1))
		(cAliasItem)->(dbSeek(xFilial(cAliasItem)+cNum,.T.))

		//dEntrega	:= &(cPrefixoItem+"entreg")

		nTotal := 0
		nValIpi := 0
		nST_tot := 0

		cSql := " SELECT SUM(C6_VALOR) AS TOTAL FROM " + RetSqlName("SC6")
		cSql += " WHERE D_E_L_E_T_ = '' AND C6_NUM = '" + cNum  + "'"
		cSql := ChangeQuery(cSql)
		
		TcQuery cSql New Alias "__C6"
		nTotIt := __C6->TOTAL
		__C6->(dbCloseArea())

		lAgrFrete := .F.
		nFretAdic := 0
		nItem := 0
		nBaseIPI := 0

		nValIpi  := 0
		nST_tot  := 0
		nTotalNf := 0
		nValorM  := 0
		nTotM    := 0
		nTotDesc := 0

		cQry := "SELECT C6.R_E_C_N_O_ C6RECNO "
		If lUsaLocal
			cQry += ",MAX(DC.DC_LOCALIZ) DC_LOCALIZ "
		EndIf
		cQry += "  FROM " + RetSqlName("SC6") + " C6 "
		If lUsaLocal 
			cQry += "LEFT JOIN "+RetSqlName("SDC") + " DC "
			cQry += "  ON DC.DC_PEDIDO = C6_NUM "
			cQry += " AND DC.DC_ITEM = C6.C6_ITEM "
			cQry += " AND DC.D_E_L_E_T_ = ' ' "
		EndIf
		cQry += " WHERE C6.D_E_L_E_T_ =' ' "
		cQry += "   AND C6_NUM = '"+cNum  + "' "
		cQry += "   AND C6_FILIAL = '" + xFilial("SC6") + "' "

		If lUsaLocal
			cQry += " GROUP BY C6.R_E_C_N_O_ "
			cQry += " ORDER BY 2,1"
		Else 
			cQry += " ORDER BY C6_ITEM "
		EndIf

		TcQuery cQry New Alias "QSC6" 

		// Comeca a varrer os itens do pedido/orcamento
		While QSC6->(!EOF()) 

			DbSelectArea("SC6")
			DbGoto(QSC6->C6RECNO)
			If !lPrinted
				sfCabec()
				lPrinted := .T.
			EndIf

			// Funcao de controle para quebra de pagina
			sfControl()

			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+&(cPrefixoItem+"produto")))

			nIPI := 0
			SF4->(dbSetOrder(1))
			If SF4->(dbSeek(xFilial("SF4")+&(cPrefixoItem+"tes")))
				If  SF4->F4_ipi == "S"
					nIPI := SB1->B1_ipi
				Endif
				IF SF4->F4_IPIFRET = 'S'
					lAgrFrete := .T.
				Else
					lAgrFrete := .F.
				EndIf
			Endif

			cItem       := &(cPrefixoItem+"item")
			cMcCod      := &(cPrefixoItem+"produto")
			cLocal      := &(cPrefixoItem+"local")
			cDescri     := POSICIONE("SB1",1,xFilial("SB1")+cMcCod,"B1_DESC")
			cUm         := &(cPrefixoItem+"um")
			nQtdVen     := &(cPrefixoItem+"qtdven")
			nPrcVen     := &(cPrefixoItem+"prcven")
			nValor      := &(cPrefixoItem+"valor")
			nValorM     := &(cPrefixoItem+"valor")
			dEntrega    := &(cPrefixoItem+"entreg")
			cNCM        := POSICIONE("SB1",1,xFilial("SB1")+cMcCod,"B1_POSIPI")
			//cCotCli     := &(cPrefixoItem+"pedcli")

			//inicializa Função de Cálculo dos Impostos
			MaFisIni(SA1->A1_COD,SA1->A1_LOJA,"C","N",SA1->A1_TIPO,,,,,'MATA461',,,,SA1->A1_GRPTRIB)

			//Calculo de Impostos
			cTes   := &(cPrefixoItem+"tes")

			cCFOP  := Posicione("SF4",1,xFilial("SF4")+cTes,"F4_CF")
			_EstCli := Posicione("SA1",1,xFilial("SA1")+cCliente+cLoja,"A1_EST")
			If _EstCli # cEstEmpAx
				cCFOP := "6"+SubStr(cCFOP,2,3)
			Else
				cCFOP := "5"+SubStr(cCFOP,2,3)
			EndIf

			nDes   := &(cPrefixoItem+"VALDESC")
			nFreAgr := 0
			If lAgrFrete
				nPerc := nValor/nTotIt
				nFreAgr := nFrete * nPerc
				nFretAdic += nFreAgr
			EndIf

			_nitem := MaFisAdd(cMcCod,cTes,nQtdVen,nPrcVen,nDes,'','',,nFreAgr,0,0,0,nValor,0)
			nBaseIPI += MaFisRet(_nitem,"IT_BASEIPI")

			nValorST    := (MaFisRet(1,"IT_VALSOL" )/nQtdVen)
			nValorIPI    := (nPrcVen) /100 * ((MaFisRet(_nitem,"IT_ALIQIPI")) )

			nLin += 30
			nValor    := (nQtdVen * (nPrcVen + nValorIPI + nValorST))
			nValUnIPI := (nPrcVen + nValorIPI)

//			nValIpi += (nValorIPI * nQtdVen)
			nValIpi += (nPrcVen * nQtdVen) /100 * ((MaFisRet(_nitem,"IT_ALIQIPI")) )


			nST_tot += (nValorST * nQtdVen)
			nTotalNf += nValor
			cDsc1 :=  POSICIONE("SB1",1,xFilial("SB1")+cMcCod,"B1_DESC")

			oPrint:Say(nLin+10, 0080       , cItem                                ,oFont2)
			oPrint:Say(nLin+10, 0130       , ALLTRIM(cMcCod)                      ,oFont2)
			oPrint:Say(nLin+10, 0285       , ALLTRIM(cLocal)                      ,oFont2)
			oPrint:Say(nLin+10, 0353       , SUBSTR(cDsc1,0,60) 				  ,oFont2)

			//oPrint:SayAlign(nLin-20, 0780  , Transform(nQtdVen,"@E 9,999.99999")      ,oFont2,500,,,1,) //,,,,1)
			//oPrint:SayAlign(nLin-20, 1000  , Transform(nPrcVen,"@E 99,999,999.999999")    ,oFont2,500,,,1,) //,,,,1)
			//oPrint:SayAlign(nLin-20, 1210  , Transform(nValorM,"@E 99,999,999.99")   ,oFont2,500,,,1,) //,,,,1)
			//Novo
			oPrint:Say(nLin+10,	1380	,Transform(nQtdVen							,"@E 9,999.99999")		,oFont2) //,,,,1)
			//oPrint:SayAlign(nLin+10,	1080	, Transform(nQtdVen,"@E 9,999.99999"),oFont2,,,, 1/*nAlignHorz*/,)
			oPrint:Say(nLin+10,	1530	, Transform(nPrcVen							,"@E 99,999,999.99")	,oFont2) //,,,,1)
			oPrint:Say(nLin+10,	1705	, Transform(nValorM							,"@E 99,999,999.99")	,oFont2) //,,,,1)
			oPrint:Say(nLin+10,	1965	, Transform(MaFisRet(_nitem,"IT_ALIQICM")	,  "@E 99")				,oFont2)
			oPrint:Say(nLin+10,	2000	, Transform(MaFisRet(_nitem,"IT_VALSOL")	,  "@E 99,999,999.99")	,oFont2)
			oPrint:Say(nLin+10,	2220	, Transform(MaFisRet(_nitem,"IT_ALIQIPI")	,  "@E 99.99")				,oFont2)
			//oPrint:Say(nLin+10,	2160	, ALLTRIM(STR( DateDiffDay( dEMIS2 ,dEntrega ))) + " Dias"      ,oFont2)
			//oPrint:Say(nLin+10,	2030	, DToC(dEntrega) ,oFont2)

			//Antigo
//        oPrint:Say(		nLin+10, 1050	, Transform(nQtdVen,"@E 9,999.99999"),oFont2) //,,,,1)
//        //oPrint:SayAlign(nLin+10, 1080	, Transform(nQtdVen,"@E 9,999.99999"),oFont2,,,, 1/*nAlignHorz*/,)
//        oPrint:Say(nLin+10, 1210  , Transform(nPrcVen,"@E 99,999,999.999999")    ,oFont2) //,,,,1)
//        oPrint:Say(nLin+10, 1450  , Transform(nValorM,"@E 99,999,999.99")        ,oFont2) //,,,,1)
//        oPrint:Say(nLin+10, 1670       , Transform(MaFisRet(_nitem,"IT_ALIQICM"),  "@E 99" )           ,oFont2)
//        oPrint:Say(nLin+10, 1730       , Transform(MaFisRet(_nitem,"IT_VALSOL") ,  "@E 99,999,999.99" ) ,oFont2)
//        oPrint:Say(nLin+10, 1950       , Transform(MaFisRet(_nitem,"IT_ALIQIPI"),  "@E 99" )           ,oFont2)
//        //oPrint:Say(nLin+10, 2160       , ALLTRIM(STR( DateDiffDay( dEMIS2 ,dEntrega ))) + " Dias"      ,oFont2)
//        oPrint:Say(nLin+10, 2030       , DToC(dEntrega) ,oFont2)

			IF !EMPTY(SUBSTR(cDsc1,61,20))
				nLin += 40
				oPrint:Say(nLin, 0310       , SUBSTR(cDsc1,61,20) 				  ,oFont2)
			ELSE
				nLin += 60
			ENDIF

			nItem ++
			nTotal   += nValor
			nTotM    += nValorM

			QSC6->(dbSkip())

			MaFisEnd()//finaliza a Função de Cálculo dos Impostos do item

		EndDo
		QSC6->(DbCloseArea())


		//TSCB57 - William Farias - INICIO
		If !Empty(cMsgInt)
			nLin += 30
			oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )
			nLin += 40
			oPrint:Say(nLin	,0080	,"Mensagem Interna:"	,oFont6)
			nLin += 30
			//oPrint:Say(nLin	,0080	,cMsgInt        		,oFont2)
			nQtdLin := MLCount(cMsgInt, nTamLin)// Quantidade de linhas do texto
			For nCntLin:=1 To nQtdLin
				// Imprime a linha
				oPrint:Say(nLin, 0080, MemoLine(cMsgInt, nTamLin, nCntLin), oFont2)
				If nCntLin < nQtdLin
					nLin += 25
				EndIf
			Next nCntLin
		EndIf
		//TSCB57 - FIM

		nLin += 30
		oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )

		nLin += 40
		oPrint:Say(nLin+10, 0060 , "No.Itens "  ,oFont6)
		oPrint:Say(nLin+10, 0300 , Transform(nItem,"@E 999")        ,oFont7)

		oPrint:Say(nLin+10, 0700 , "Vlr.IPI"    ,oFont6)
		oPrint:Say(nLin+10, 1000 , Transform(nValIpi,"@E 9,999,999.99")    ,oFont7)

		oPrint:Say(nLin+10, 1200 , "Despesa"    ,oFont6)
		oPrint:Say(nLin+10, 1400 , Transform(nDespesa,"@E 9,999,999.99")     ,oFont7)

		oPrint:Say(nLin+10, 1600 , "PRODUTOS (R$)"    ,oFont6)
		oPrint:Say(nLin+10, 1980 , Transform(nTotM,"@E 99,999,999.99")    ,oFont7)

		nLin += 30
		oPrint:Say(nLin+10, 0060 , "Subst.Trib "  ,oFont6)
		oPrint:Say(nLin+10, 0300 , Transform(nST_tot,"@E 99,999,999.99")    ,oFont7)

		oPrint:Say(nLin+10, 0700 , "Desconto"    ,oFont6)
		oPrint:Say(nLin+10, 1000 , Transform(nTotDesc,"@E 9,999,999.99")    ,oFont7)

		oPrint:Say(nLin+10, 1200 , "Frete"    ,oFont6)
		oPrint:Say(nLin+10, 1400 , Transform(nFrete,"@E 9,999,999.99")     ,oFont7)

		nTotalNf := (nTotalNf + nFrete + nDespesa + nSeguro)
		oPrint:Say(nLin+10, 1600 , "TOTAL (R$)"    ,oFont6)
		oPrint:Say(nLin+10, 1980 , Transform((nTotalNf),"@E 999,999,999.99") ,oFont7)

		nLin += 40
		oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )

		nLin += 40
		oPrint:Say(nLin+10, 0060 , "CONDIÇÕES COMERCIAIS"  ,oFontCabN)

		nLin += 50
		oPrint:Say(nLin+10, 0060 , "Cond. Pag"  ,oFont6)
		oPrint:Say(nLin+10, 0300,  Alltrim(SE4->E4_descri)  ,oFont7)

		//oPrint:Say(nLin+10, 1200 , "Cot.Cliente"  ,oFont6)
		//oPrint:Say(nLin+10, 1400,  cCotCli        ,oFont7)

		nLin += 40
		oPrint:Say(nLin+10, 0060 , "Transp."  ,oFont6)
		oPrint:Say(nLin+10, 0300,  cTransp    ,oFont7)

		//oPrint:Say(nLin+10, 1200 , "Entrega"        ,oFont6)
		//oPrint:Say(nLin+10, 1400,  Dtoc(dDtEntrega) ,oFont7)

		nLin += 40
		oPrint:Say(nLin+10, 0060 , "Frete"  ,oFont6)
		oPrint:Say(nLin+10, 0300,  cTpFrete ,oFont7)

		//oPrint:Say(nLin+10, 1200 , "Volumes"  ,oFont6)
		//oPrint:Say(nLin+10, 1400,  Transform(cVolumes,"@E 999")   ,oFont7)

		nLin += 40
		oPrint:Say(nLin+10, 0060 , "Vendedor"  ,oFont6)
		oPrint:Say(nLin+10, 0300 , cVendedor,oFont6)
		//oPrint:Say(nLin+10, 0060 , "Impostos"  ,oFont6)
		//oPrint:Say(nLin+10, 0300,  ""          ,oFont7)

		//oPrint:Say(nLin+10, 1200 , "Seguro"  ,oFont6)
		//oPrint:Say(nLin+10, 1400,  Transform(nSeguro,"@E 9,999,999.99")   ,oFont7)

		nLin += 40
		//oPrint:Say(nLin+10, 1200 , "Orçamento Válido Até: "+DToC(dValidade)  ,oFont6)
		//oPrint:Say(nLin+10, 1400,  Transform(nSeguro,"@E 9,999,999.99")   ,oFont7)

		nLin += 40
		//oPrint:Say(nLin+10, 0060 , "Observações"  ,oFont6)
		//oPrint:Say(nLin+10, 0300,  SubStr(cObs,1,100)           ,oFont7)
		//nLin := 40
		//oPrint:Say(nLin+10, 0300,  SubStr(cObs,101,100)         ,oFont7)

		//nLin += 160
		//oPrint:Say(nLin+10, 0300,  "Prazo de entrega, conforme coluna 'ENTREGA' em DIAS"  ,oFont7)
		//nLin += 40
		//oPrint:Say(nLin+10, 0300,  "Validade da Proposta: 20 dias"  ,oFont7)
		//nLin += 40
		//oPrint:Say(nLin+10, 0300,  "Garantia de peças de reposição: 03 (três) meses a contar da data de faturamento, condicionado à nossa avaliação"  ,oFont7)

		nLin += 70
		//oPrint:Say(nLin+10, 0060 , "ASSINATURAS"  ,oFontCabN)

		nLin += 70
		//oPrint:Say(nLin+10, 0060 , "_______________________________________________________",oFont6)
		//oPrint:Say(nLin+10, 1200 , "_______________________________________________________",oFont6)

		nLin += 40
		//oPrint:Say(nLin+10, 0060 , Alltrim(SA1->A1_nome),oFont6)
		//oPrint:Say(nLin+10, 1200 , SM0->M0_nomecom,oFont6)

		nLin += 30
		//oPrint:Say(nLin+10, 1200 , cVendedor,oFont6)
		nLin += 30
		//oPrint:Say(nLin+10, 1200 , cEmailV,oFont6)
		nLin += 30
		//oPrint:Say(nLin+10, 1200 , cTelVend,oFont6)



    /*
    oPrint:Box( nLin,  1600         , nLin + 60, 2130           )
    oPrint:Box( nLin,  2130         , nLin + 60, NMARGDIREITA   )

    nLin += 30

    oPrint:Say(nLin+10, 1610    ,   "IPI   =============> "        ,oFont6)
    oPrint:Say(nLin+10, 2130    ,   Transform(nValIpi,"@E 999,999,999.99"),oFont6)

    nLin += 30

    // Imprime o Total ST
    oPrint:Box( nLin,  1600         , nLin + 60, 2130           )
    oPrint:Box( nLin,  2130         , nLin + 60, NMARGDIREITA   )

    nLin += 30

    oPrint:Say(nLin+10, 1610    ,   "ICMS ST =========> "      ,oFont6)
    oPrint:Say(nLin+10, 2130    ,   Transform(nST_tot,"@E 999,999,999.99"),oFont6)

    nLin += 30

    // Imprime o Total ST
    oPrint:Box( nLin,  1600         , nLin + 60, 2130           )
    oPrint:Box( nLin,  2130         , nLin + 60, NMARGDIREITA   )

    nLin += 30

    oPrint:Say(nLin+10, 1610    ,   "Frete  ===========> "     ,oFont6)
    oPrint:Say(nLin+10, 2130    ,   Transform(nFrete,"@E 999,999,999.99"),oFont6)

    nLin += 30

    // Imprime o Total com Ipi
    oPrint:Box( nLin,  1600         , nLin + 60, 2130           )
    oPrint:Box( nLin,  2130         , nLin + 60, NMARGDIREITA   )

    nLin += 30

    oPrint:Say(nLin+10, 1610    ,   "Total  ===========> "                         ,oFont6)
    oPrint:Say(nLin+10, 2120    ,   Transform((nTotalNf),"@E 999,999,999.99") ,oFont6)

    nLin += 100

	oPrint:Box( nLin,  NMARGESQUERDA, nLin + 310, NMARGDIREITA	)

		If !Empty(cObsSim)
		nLin += 50
		oPrint:Say(nLin+10,070,cObsSim,oFont3)
		endif

	nLin += 50
	oPrint:Say(nLin+10,070," “A responsabilidade de  verificar sobre o imposto 'substituição tributária' de ICMS  na entrada de mercadoria em seu estado," ,oFont6)
	nLin += 50
	oPrint:Say(nLin+10,070," é por conta do cliente. Favor verificar com seu contador” " ,oFont6)
    */

		oPrint:EndPage()
		nPagina	:= 1
		(cAliasTemp)->(dbSkip())
		If !(cAliasTemp)->(EOF())
			oPrint:StartPage()
		EndIf
	EndDo

Return

/*/{Protheus.doc} sfCabec
Funcao para imprimir o cabecalho do orcamento / pedido. 
@type function
@author Decanter 
@since 10/06/2021
/*/
Static Function sfCabec()


	nLin := 70
	nLiN := 120

	oPrint:SayBitmap( nLin, 50, cFileLogo , 350, 280 )

	nLin += 50
	oPrint:Say(nLin+10,600,SUBSTR((SM0->M0_nomecom),0,44),oFontCabN)
	nLin += 50
	oPrint:Say(nLin+10,600,cEndEmpAx,oFontCabN)
	nLin += 50
	oPrint:Say(nLin+10,600,"CEP: "+Transform(cCepEmpAx,PesqPict("SA1","A1_CEP"))+" - "+Alltrim(cMunEmpAx)+"/"+cEstEmpAx,oFontCabN)
	nLin += 50
	oPrint:Say(nLin+10,600,"TEL: "+cTelEmpAx,oFontCabN) //+"        FAX: "+cFaxEmpAx,oFont6)
	nLin += 50
//oPrint:Say(nLin+10,600,"financeiro@fromtherm.com.br",oFontCabN)
	nLin += 50
	oPrint:Say(nLin+10,600,"CNPJ: "+Transform(SM0->M0_cgc,PesqPict("SA1","A1_CGC"))+Space(10)+"Insc.Est."+Transform(SM0->M0_INSC,"@R 999.999.999"),oFontCabN)

	nLin += 50
	oPrint:Say(nLin+10,070,"Pedido: ",oFontCabN)
	oPrint:Say(nLin+10,370,SC5->C5_num,oFontCabN)


// 	oPrint:Say(nLin+10,1700,"Emissão: "+Dtoc(dEmissao),oFontCabN) 
	oPrint:Say(nLin+10,1200,"Emissão: "+Dtoc(dEmissao),oFontCabN)  //André alteração
	oPrint:Say(nLin+10,1700,"Hr Impressão: "+Time(),oFontCabN) //André Alteração

	nLin += 50
	oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )

	nLin += 50
	oPrint:Say(nLin+10,070,"DADOS DO CLIENTE",oFontCabN)

	nLin += 40
	oPrint:Say(nLin+10,070,"Nome ",oFont6)
	oPrint:Say(nLin+10,270,SUBSTR(Alltrim(SA1->A1_nome),0 , 44 ),oFont7)
	cTelCli1 := "(" + StrZero(val(SubStr(SA1->A1_TEL,1,2)),2) + ") "
	oPrint:Say(nLin+10,1700,"Fone",oFont6)
	oPrint:Say(nLin+10,1900,cTelCli1+Alltrim(Transform(SubStr(SA1->A1_tel,3,10),"@R 999999999")),oFont7)

	nLin += 40
	oPrint:Say(nLin+10,070,"Contato ",oFont6)
	oPrint:Say(nLin+10,270,AllTrim(SA1->A1_CONTATO),oFont7)

	nLin += 40
	oPrint:Say(nLin+10,070,"Cidade ",oFont6)
	oPrint:Say(nLin+10,270,AllTrim(SA1->A1_MUN),oFont7)
	oPrint:Say(nLin+10,1700,"Cep ",oFont6)
	oPrint:Say(nLin+10,1900,Transform(SA1->A1_CEP,PesqPict("SA1","A1_CEP")),oFont7)

	nLin += 40
	oPrint:Say(nLin+10,070,"Endereco ",oFont6)
	oPrint:Say(nLin+10,270,AllTrim(SA1->A1_END),oFont7)
	oPrint:Say(nLin+10,1700,"UF ",oFont6)
	oPrint:Say(nLin+10,1900,SA1->A1_EST,oFont7)

	nLin += 40
	oPrint:Say(nLin+10,070,"Bairro ",oFont6)
	oPrint:Say(nLin+10,270,AllTrim(SA1->A1_BAIRRO),oFont7)
	If Len(AllTrim(SA1->A1_CGC)) == 11
		oPrint:Say(nLin+10,1700,"CPF ",oFont6)
		oPrint:Say(nLin+10,1900,Transform(SA1->A1_CGC,"@R 999.999.999-99"),oFont7)
	Else
		oPrint:Say(nLin+10,1700,"CNPJ ",oFont6)
		oPrint:Say(nLin+10,1900,Transform(SA1->A1_CGC,PesqPict("SA1","A1_CGC")),oFont7)
	EndIf

	nLin += 40
	oPrint:Say(nLin+10,070,"Email ",oFont6)
	oPrint:Say(nLin+10,270,AllTrim(SA1->A1_EMAIL),oFont7)
	oPrint:Say(nLin+10,1700,"Insc.Est. ",oFont6)
	oPrint:Say(nLin+10,1900,SA1->A1_INSCR,oFont7)

	If cCliente+cLoja # cCliEnt+cLojaEnt
		cNomeEnt := Posicione("SA1",1,xFilial("SA1")+cCliEnt+cLojaEnt,"A1_NOME")
		cCNPJEnt := Posicione("SA1",1,xFilial("SA1")+cCliEnt+cLojaEnt,"A1_CGC")
		cEndeEnt := Posicione("SA1",1,xFilial("SA1")+cCliEnt+cLojaEnt,"A1_END")
		cMuniEnt := Posicione("SA1",1,xFilial("SA1")+cCliEnt+cLojaEnt,"A1_MUN")
		cEstaEnt := Posicione("SA1",1,xFilial("SA1")+cCliEnt+cLojaEnt,"A1_EST")
		nLin += 50
		oPrint:Say(nLin+10,070,"CLIENTE DE ENTREGA",oFontCabN)
		nLin += 40
		oPrint:Say(nLin+10,070,AllTrim(cNomeEnt)+" CNPJ: "+cCNPJEnt,oFont7)
		nLin += 40
		oPrint:Say(nLin+10,070,AllTrim(cEndeEnt),oFont7)
		nLin += 40
		oPrint:Say(nLin+10,070,AllTrim(cMuniEnt)+"-"+cEstaEnt,oFont7)
	EndIf

	nLin += 40
	oPrint:Box( nLin,NMARGESQUERDA,nLin,NMARGDIREITA )
	nLin += 40
	oPrint:Say(nLin+10,070,"PRODUTOS",oFontCabN)

// Imprime o cabecalho dos itens
	nLin += 40
/*
oPrint:Say(nLin+10, 0060 , "Codigo"    ,oFont6)
oPrint:Say(nLin+10, 0230 , "Descricao" ,oFont6)
oPrint:Say(nLin+10, 0230 , "NCM"       ,oFont6)
oPrint:Say(nLin+10, 1270 , "Qtde."     ,oFont6)
oPrint:Say(nLin+10, 1740 , "Unit."     ,oFont6)
oPrint:Say(nLin+10, 1870 , "Total"     ,oFont6)
*/

//Novo
	oPrint:Say(nLin+10, 0080 , "It"        	,oFont6)
	oPrint:Say(nLin+10, 0135 , "Código"    	,oFont6)
	oPrint:Say(nLin+10, 0270 , "Arm" 		,oFont6)
	oPrint:Say(nLin+10, 0353 , "Descrição" 	,oFont6)
//oPrint:Say(nLin+10, 0940 , "CFOP"      ,oFont6)
//oPrint:Say(nLin+10, 1080 , "NCM"       ,oFont6)
	oPrint:Say(nLin+10, 1422 , "Qtde."     ,oFont6)
	oPrint:Say(nLin+10, 1600 , "Unit."     ,oFont6)
	oPrint:Say(nLin+10, 1770 , "Total"     ,oFont6)
	oPrint:Say(nLin+10, 1935 , "ICMS%"    ,oFont6)
	oPrint:Say(nLin+10, 2065 , "ICMS-ST"   ,oFont6)
	oPrint:Say(nLin+10, 2210 , "IPI%"     ,oFont6)
//oPrint:Say(nLin+10, 2020 , "Entrega"   ,oFont6)

//Antigo
//oPrint:Say(nLin+10, 0080 , "It"        ,oFont6)
//oPrint:Say(nLin+10, 0130 , "Codigo"    ,oFont6)
//oPrint:Say(nLin+10, 0350 , "Descricao" ,oFont6)
////oPrint:Say(nLin+10, 0940 , "CFOP"      ,oFont6)
////oPrint:Say(nLin+10, 1080 , "NCM"       ,oFont6)
//oPrint:Say(nLin+10, 1100 , "Qtde."     ,oFont6)
//oPrint:Say(nLin+10, 1290 , "Unit."     ,oFont6)
//oPrint:Say(nLin+10, 1500 , "Total"     ,oFont6)
//oPrint:Say(nLin+10, 1620 , "ICMS %"    ,oFont6)
//oPrint:Say(nLin+10, 1770 , "ICMS ST"   ,oFont6)
//oPrint:Say(nLin+10, 1920 , "IPI %"     ,oFont6)
//oPrint:Say(nLin+10, 2020 , "Entrega"   ,oFont6)

//nLin := 950 //1030

	nLin += 40

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Funcao para controle de quebra de pagina.                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function sfControl()
	*****************************
	If nLin > NULTIMALINHA
		nPagina++
		nLin += 60
		oPrint:Say( nLin , 950, "*** CONTINUA NA PÁGINA :"+Transform(nPagina,"@E 99")+" ***", oFont6, 100 )
		oPrint:EndPage()
		oPrint:StartPage()
		sfCabec()
	EndIf

Return
