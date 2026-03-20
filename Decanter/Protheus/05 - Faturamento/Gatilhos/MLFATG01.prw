#include 'totvs.ch'

/*/{Protheus.doc} MLFATG01
(Calcula preço de venda liquido baseado em preço com ST/IPI )

@author Marcelo Lauschner
@since 10/01/2013
@version 1.0
@return logico,
@example
(examples)
@see (links_or_references)
/*/
User Function MLFATG01()
    
    Local       nBk             := n
	Local       iX
	Local       nPUprc          := aScan(aHeader,{|x| Alltrim(x[2]) == "C6_XUPRCVE"})
    Local       nBkUpr          := M->C6_XUPRCVE
	Private     cRat,nRatDesp,nRatFret,nRatSeg,nRatNTrb,nRatTara
	Private     aRatVlrs

	If !sfOpenSx3(cEmpAnt)
		Return .F. 
	Endif 


	aRatVlrs        := sfRatFrete(M->C5_NUM,1,nBk)

	If aRatVlrs[1]+aRatVlrs[2]+aRatVlrs[3] > 0
		For iX := 1 To Len(aCols)
			If !aCols[iX,Len(aHeader)+1]				
				If iX == nBk
					aCols[iX,nPUprc]	:= M->C6_XUPRCVE
				Endif		
				sfExecAtu(iX)                				
			Endif
		Next
		N := nBk
       
	Else
		// Força o preenchimento do valor no aCols antes de chamar a função, pois o valor ainda está em validação apenas. 
		aCols[n,nPUprc]	:= M->C6_XUPRCVE
		sfExecAtu(n)
	Endif

Return .T.


Static Function sfExecAtu(nLinAtu)

	Local	nXPrcFull	:= 0
	Local	nXPrcAux	:= 0
	Local	nPrcBrut	:= 0
	Local	aAreaOld	:= GetArea()
	Local 	nRet 		:= 0
	Local	ny			:= 0
	Local 	nPProd		:= 0
	Local 	nPQtd     	:= 0
	Local 	nPVrUnit  	:= 0
	Local 	nPVlrItem 	:= 0
	Local 	nPDesc 		:= 0
	Local 	nPValDesc 	:= 0
	Local	nPPrcTab	:= 0
	Local 	nPAcre 		:= 0
	Local 	nPValAcre 	:= 0
	Local	nPTes		:= 0
	Local	nPCfo		:= 0
	Local	nPLocal		:= 0
	Local   nPUprc      := 0
	Local	nPItem		:= 0
	Local   nFretRat    := 0
	Local   nSegRat     := 0
	Local   nDescRat    := 0
	Local   nDespRat    := 0
	Local	nT			:= nLinAtu
	Local	cCliPed		:= ""



	nPProd  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	nPQtd   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	nPVrUnit  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	nPPrcTab  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	nPVlrItem 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
	nPValDesc 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
	nPDesc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
	nPTes		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	nPCfo		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})
	nPLocal		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
	nPItem		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	nPUprc      := aScan(aHeader,{|x| Alltrim(x[2]) == "C6_XUPRCVE"})

	nFretRat    := 0
	nSegRat     := 0
	nDescRat    := 0
	nDespRat    := 0



	DbSelectArea("SB1")
	DbSetOrder(1)
	MsSeek(xFilial("SB1")+aCols[nT][nPProd])

	nXPrcAux			:= aCols[nT][nPPrcTab]
	nXPrcFull			:= Iif(aCols[nT][nPUprc] > 0 ,aCols[nT][nPUprc],aCols[nT][nPPrcTab])
	//-------------------------------------------------------------------------------------------------------------------------------------------------------------------

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Busca referencias no SC6                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aFisGet	:= {}
	dbSelectArea("QSX3")
	dbSetOrder(1)
	MsSeek("SC6")
	While !Eof().And.QSX3->X3_ARQUIVO=="SC6"
		cValid := UPPER(QSX3->X3_VALID+QSX3->X3_VLDUSER)
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGet,{cReferencia,QSX3->X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGet,{cReferencia,QSX3->X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		dbSkip()
	EndDo
	aSort(aFisGet,,,{|x,y| x[3]<y[3]})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Busca referencias no SC5                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aFisGetSC5	:= {}
	dbSelectArea("QSX3")
	dbSetOrder(1)
	MsSeek("SC5")
	While !Eof().And.QSX3->X3_ARQUIVO=="SC5"
		cValid := UPPER(QSX3->X3_VALID+QSX3->X3_VLDUSER)
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGetSC5,{cReferencia,QSX3->X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGetSC5,{cReferencia,QSX3->X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		dbSkip()
	EndDo
	aSort(aFisGetSC5,,,{|x,y| x[3]<y[3]})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicializa a funcao fiscal                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MaFisSave()
	MaFisEnd()
	MaFisIni(IIf(!Empty(cCliPed),cCliPed,Iif(Empty(M->C5_CLIENT),M->C5_CLIENTE,M->C5_CLIENT)),;// 1-Codigo Cliente/Fornecedor
	M->C5_LOJAENT,;		// 2-Loja do Cliente/Fornecedor
	IIf(M->C5_TIPO$'DB',"F","C"),;				// 3-C:Cliente , F:Fornecedor
	M->C5_TIPO,;				// 4-Tipo da NF
	M->C5_TIPOCLI,;		// 5-Tipo do Cliente/Fornecedor
	Nil,;
		Nil,;
		Nil,;
		Nil,;
		"MATA461",;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		{"",""})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Realiza alteracoes de referencias do SC5         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aFisGetSC5) > 0
		dbSelectArea("SC5")
		For ny := 1 to Len(aFisGetSC5)
			If !Empty(&("M->"+Alltrim(aFisGetSC5[ny][2])))
				MaFisAlt(aFisGetSC5[ny][1],&("M->"+Alltrim(aFisGetSC5[ny][2])),,.F.)
			EndIf
		Next
	Endif


	cProduto := aCols[nT][nPProd]
	SB2->(dbSetOrder(1))
	SB2->(MsSeek(xFilial("SB2")+SB1->B1_COD+aCols[nT][nPLocal]))
	SF4->(dbSetOrder(1))
	SF4->(MsSeek(xFilial("SF4")+aCols[nT][nPTES]))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Calcula o preco de lista                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	nValMerc  := 10000 * aCols[nT][nPQtd] //(aCols[nT][nPQtd])*aCols[nT][nPVrUnit]
	nPrcLista := 10000 //aCols[nT][nPPrcTab]
	nDesconto := 0//a410Arred(nPrcLista*(aCols[nT][nPQtd]),"D2_DESCON")-nValMerc
	nDesconto := IIf(nDesconto< 0,0,nDesconto)

	MaFisAdd(	cProduto,;   		// 1-Codigo do Produto ( Obrigatorio )
	aCols[nT][nPTES],;	   			// 2-Codigo do TES ( Opcional )
	aCols[nT][nPQtd],; 	 			// 3-Quantidade ( Obrigatorio )
	nPrcLista,;						// 4-Preco Unitario ( Obrigatorio )
	nDesconto,; 					// 5-Valor do Desconto ( Opcional )
	"",;	   						// 6-Numero da NF Original ( Devolucao/Benef )
	"",;							// 7-Serie da NF Original ( Devolucao/Benef )
	0,;								// 8-RecNo da NF Original no arq SD1/SD2
	0,;								// 9-Valor do Frete do Item ( Opcional )
	0,;								// 10-Valor da Despesa do item ( Opcional )
	0,;								// 11-Valor do Seguro do item ( Opcional )
	0,;								// 12-Valor do Frete Autonomo ( Opcional )
	nValMerc,;						// 13-Valor da Mercadoria ( Obrigatorio )
	0,;								// 14-Valor da Embalagem ( Opiconal )
	,;								// 15
	,;								// 16
	Iif(nPItem>0,aCols[nT,nPItem],""),; //17
	0,;								// 18-Despesas nao tributadas - Portugal
	0,;								// 19-Tara - Portugal
	aCols[nT,nPCfo],; 				// 20-CFO
	{},;	           				// 21-Array para o calculo do IVA Ajustado (opcional)
	"")								// 22-Codigo Retencao - Equador

	//-------------------------------------------------------------------------------------------------------------------------------------------------------------------

	nVlrFinal	:= MaFisRet(,"NF_TOTAL")
	nCoeficient	:= nValMerc / nVlrFinal
	//		X*(1,05)*(1,5663)=197,35
	// Faço o descalculo do preço do item

	MaFisEnd()
	MaFisRestore()

	aRatVlrs        		:= sfRatFrete(M->C5_NUM,1,nT)

	nXPrcFull               += aRatVlrs[1] // Frete
	nXPrcFull               += aRatVlrs[2] // Seguro
	nXPrcFull               += aRatVlrs[3] // Despesa

	aCols[nT][nPVrUnit] 	:= Round(nXPrcFull * nCoeficient ,TamSX3("C6_PRCVEN")[2])

	aCols[nT][nPVrUnit]     -= aRatVlrs[1] // Frete
	aCols[nT][nPVrUnit]     -= aRatVlrs[2] // Seguro
	aCols[nT][nPVrUnit]     -= aRatVlrs[3] // Despesa

	aCols[nT][nPVlrItem]	:= A410Arred(aCols[nT][nPQtd] * aCols[nT][nPVrUnit],"D2_TOTAL")

	nPrcAnt := aCols[nT][nPVrUnit]

	If nPrcAnt < nXPrcAux
		aCols[nT][nPValDesc] 	:= Round( (nXPrcAux - nPrcAnt) * aCols[nT][nPQtd],TamSX3("C6_VALDESC")[2])
		aCols[nT][nPDesc] 		:= Round( aCols[nT][nPValDesc] / (aCols[nT][nPPrcTab]*aCols[nT][nPQtd]) * 100,TamSX3("C6_DESCONT")[2])
		//	aCols[nT][nPVrUnit] 	:= A410Arred(nXPrcAux - (aCols[nT][nPValDesc] / aCols[nT][nPQtd]),"D2_PRCVEN")
	Else
		aCols[nT][nPValDesc] 	:= 0
		aCols[nT][nPDesc] 		:= 0
	Endif


	If Type('oGetDad:oBrowse')<>"U"
		oGetDad:oBrowse:Refresh()
		Ma410Rodap()
	Endif

	RestArea(aAreaOld)

Return .T.


/*/{Protheus.doc} sfRet
Função que calcula o valor do produto com impostos 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 13/11/2020
@param cInTipo, character, param_description
@param cInTpCli, character, param_description
@param cInFor, character, param_description
@param cInLoj, character, param_description
@param cInCodPro, character, param_description
@param nInPrc, numeric, param_description
@param cInTes, character, param_description
@return return_type, return_description
/*/
Static Function sfRet(cInTipo,cInTpCli,cInFor,cInLoj,cInCodPro,nInPrc,cInTes)


	Local	aAreaOld		:= GetArea()
	Local	nCustRet		:= 0
	Local	nItemFis		:= 0
	Local	cTipo			:= "N"


	MaFisSave()
	MaFisEnd()

	MaFisIni(cInFor,;														// 1-Codigo Cliente/Fornecedor
	cInLoj,;															// 2-Loja do Cliente/Fornecedor
	cInTipo,;															// 3-C:Cliente , F:Fornecedor
	cTipo,;																// 4-Tipo da NF
	cInTpCli,;															// 5-Tipo do Cliente/Fornecedor
	Iif(cInTipo=="C",Nil,MaFisRelImp("MT100",{"SF1","SD1"})),;			// 6-Relacao de Impostos que suportados no arquivo
	Nil,;																// 7-Tipo de complemento
	Nil,;																// 8-Permite Incluir Impostos no Rodape .T./.F.
	Nil,;																// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
	Iif(cInTipo=="C","MATA461","MATA100"),;								// 10-Nome da rotina que esta utilizando a funcao
	Nil,;																// 11-Tipo de documento
	Nil,;  																// 12-Especie do documento
	Nil)																// 13- Codigo e Loja do Prospect

	nItemFis++

	MaFisAdd(	cInCodPro,;  						// 1-Codigo do Produto ( Obrigatorio )
	cInTes,;									// 2-Codigo do TES ( Opcional )
	1,; 										// 3-Quantidade ( Obrigatorio )
	nInPrc,;									// 4-Preco Unitario ( Obrigatorio )
	0,;	 										// 5-Valor do Desconto ( Opcional )
	"",;	   									// 6-Numero da NF Original ( Devolucao/Benef )
	"",;										// 7-Serie da NF Original ( Devolucao/Benef )
	0,;											// 8-RecNo da NF Original no arq SD1/SD2
	0,;											// 9-Valor do Frete do Item ( Opcional )
	0,;											// 10-Valor da Despesa do item ( Opcional )
	0,;											// 11-Valor do Seguro do item ( Opcional )
	0,;											// 12-Valor do Frete Autonomo ( Opcional )
	nInPrc,;									// 13-Valor da Mercadoria ( Obrigatorio )
	0,;											// 14-Valor da Embalagem ( Opiconal )
	,;											// 15
	,;											// 16
	,; 											// 17
	0,;											// 18-Despesas nao tributadas - Portugal
	0,;											// 19-Tara - Portugal
	,; 											// 20-CFO
	{},;	           							// 21-Array para o calculo do IVA Ajustado (opcional)
	"")

	nCustRet	:= MaFisRet(,"NF_TOTAL")

	MaFisRestore()

	RestArea(aAreaOld)

Return nCustRet





Static Function sfRatFrete(cNumPed,nQtdLib,nLinPos)

	LOCAL nParFrete   	:= 0
	LOCAL nParSeguro  	:= 0
	LOCAL nParDespesa 	:= 0
	LOCAL lFreteMoe 	:= Iif(GetMv("MV_FRETMOE") == "S",.T.,.F.)
	Local nPosPed		:= 0
	Local nPesoTot 		:= 0
	Local nValTot 		:= 0
	Local nValItem 		:= 0
	Local nPesoItem		:= 0
	Local aArea			:= GetArea()
	Local nTaxaFrete 	:= 0
	Local nParDesNTr 	:= 0
	Local nParTara 		:= 0
	Local nRatNTrb 		:= 0
	Local nRatTara 		:= 0
	Local nFator4		:= 0
	Local nFator5		:= 0
	Local nPProd    	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local nPQtd   	    := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local nPVrUnit  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	Local nPPrcTab  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	Local nPVlrItem 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
	Local nPValDesc 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
	Local nPDesc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
	Local nPTes		    := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	Local nPCfo		    := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})
	Local nPLocal		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
	Local nPItem		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	Local nPUprc        := aScan(aHeader,{|x| Alltrim(x[2]) == "C6_XUPRCVE"})

	nTaxaFrete := M->C5_TXMOEDA

	If nTaxaFrete <=0
		nTaxaFrete:= Recmoeda(dDatabase,M->C5_MOEDA)
	EndIf

	If cRat == Nil
		cRat  	:= GetNewPar("MV_RATDESP","FR=1;DESP=1;SEG=1")
		nRatDesp := Val(Substr(cRat,AT("DESP=" ,cRat)+5,1))
		nRatFret := Val(Substr(cRat,AT("FR="   ,cRat)+3,1))
		nRatSeg  := Val(Substr(cRat,AT("SEG="  ,cRat)+4,1))
		nRatNTrb := Val(Substr(cRat,AT("NTRB="  ,cRat)+5,1))
		nRatTara := Val(Substr(cRat,AT("TARA="  ,cRat)+5,1))
	Endif

	aPedTots	:=	{}

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Se a variavel lfrete estiver com .T. ele ira converter o valor do frete / despesa     ³
	//³ e seguro da moda 1  para a moeda do pedido                                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nParfrete   += Iif(lFreteMoe .And. M->C5_MOEDA > 1,;
		xMoeda(Iif(M->C5_TPFRETE=="F",M->C5_FRETE,0),1,M->C5_MOEDA,dDataBase,8,nTaxaFrete ),;
		M->C5_FRETE)

	nParSeguro  += Iif(lFreteMoe .And. M->C5_MOEDA > 1,;
		xMoeda(M->C5_SEGURO,1,M->C5_MOEDA,dDataBase,8,nTaxaFrete),;
		M->C5_SEGURO)
	nParDespesa += Iif(lFreteMoe .And. M->C5_MOEDA > 1,;
		xMoeda(M->C5_DESPESA,1,M->C5_MOEDA,dDataBase,8,nTaxaFrete),;
		M->C5_DESPESA)

	nPosPed	:=	Ascan(aPedTots,{|x| x[1] == cNumPed})
	DbSelectArea('SB1')
	DbSetOrder(1)

	If nPosPed == 0

		For nI := 1 To Len(aCols)
			If !aCols[nI,Len(aHeader)+1]

				If !(AllTrim(aCols[nI,nPTes]) $ SuperGetMV("MV_BONUSTS"))
					SB1->(MsSeek(xFilial()+aCols[nI,nPProd]))
					nPesoTot	+=	SB1->B1_PESO * aCols[nI,nPQtd]
					nValTot	    +=  aCols[nI,nPVrUnit] * aCols[nI,nPQtd]

					If nI == nLinPos
						nPesoItem	:=	nQtdLib * SB1->B1_PESO
						nValItem	:=	nQtdLib * aCols[nI,nPVrUnit]
					Endif
				EndIf
			Endif
		Next
		AAdd(aPedTots,{M->C5_NUM,nPesoTot,nValTot})
		nPosPed	:=	Len(aPedTots)
	Endif

	nFator1	:=	If(nRatFret == 2.And.aPedTots[nPosPed][2] >0 ,(nPesoItem/aPedTots[nPosPed][2]),(nValItem/aPedTots[nPosPed][3]))
	nFator2	:=	If(nRatSeg  == 2.And.aPedTots[nPosPed][2] >0 ,(nPesoItem/aPedTots[nPosPed][2]),(nValItem/aPedTots[nPosPed][3]))
	nFator3	:=	If(nRatDesp == 2.And.aPedTots[nPosPed][2] >0 ,(nPesoItem/aPedTots[nPosPed][2]),(nValItem/aPedTots[nPosPed][3]))


Return( { nParFrete*nFator1,nParSeguro*nFator2,nParDespesa*nFator3} )



/*/{Protheus.doc} sfOpenSx3
Abertura da tabela SX3 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 24/03/2021
@param cEmp, character, param_description
@return return_type, return_description
/*/
Static Function sfOpenSx3(cEmp)

	Local lOk	:=	.T.
	If Select("QSX3") > 0
		QSX3->(DBCloseArea())
	Endif
	OpenSxs(,,,,cEmp,"QSX3","SX3",,.F.)

	If Select("QSX3") == 0
		lOk := .F.
	Endif

Return lOk
