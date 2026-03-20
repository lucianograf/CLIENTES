#Include 'Protheus.ch'


/*/{Protheus.doc} M410LDEL
(Ponto de entrada para validar a exclusão ou restauração da linha do getdados do pedido de vendas)
@type function
@author marce
@since 19/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M410LDEL()

	Local	aAreaOld		:= GetArea()
	Local	lRet			:= .T.
	Local	nPProd  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local	nPQtd	  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local	nPRegBnf		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	Local	nPCodTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
	Local	nPPrcMax		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMAX"})
	Local	nPPrcMin		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
	Local	nPxPrTab1		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB1"})
	Local	nPxPrTab2		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB2"})
	Local	nPxPrTab3		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB3"})
	Local	nPxPrTab4		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB4"})
	Local	nPxPrTab5		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB5"})
	Local	nPxPrTab6		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB6"})
	Local	nPPrcTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	Local	nPVrUnit		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	Local	nPValDesc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
	Local	nPDesc			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
	Local	nC5XVOLLIT		:= M->C5_XVOLLIT
	Local	nC5XVOLQTE		:= M->C5_XVOLQTE
	Local	nW ,nL
	
	Local	nPosAnt			:= n
	Local	nPosDel			:= Len(aHeader)+1
	Local	iQ
	Local	nDesconto		:= 0
	Local	nXPrcTab		:= 0
	Local	aFxVolumes		:= {}
	Local	aPrTabs			:= {}
	
	// Se o tipo de pedido não for N-Normal não efetua validações. 
	If M->C5_TIPO # "N"
		RestArea(aAreaOld)
		Return lRet
	Endif
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M410LDEL")
		RestArea(aAreaOld)
		Return .T. 
	Endif
	
	// Verifica se a linha é um derivado de Combo
	If !Empty(aCols[n][nPRegBnf]) 
		cRegBoni	:= Substr(aCols[n][nPRegBnf],1,6)
		If !aCols[n][Len(aHeader)+1]
			aCols[n][nPRegBnf]	:= "XXXXXX"
			MsgAlert("Você deletou um item derivado de Combo. Todos os demais produtos do Combo serão deletados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			For iQ := 1 To Len(aCols)
				If iQ <> nPosAnt .And. Substr(aCols[iQ][nPRegBnf],1,6) == cRegBoni
					n	:= iQ
					aCols[n][nPRegBnf]		:= "XXXXXX"
					//lRet	:= .F.
					aCols[n][nPosDel] 		:= .T.
					aCols[iQ][nPosDel]		:= .T.									
				Endif
			Next iQ
		Else 
			MsgAlert("Não permitido recuperar item derivado de Combo que foi deletado!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			lRet	:= .F. 						
		Endif
		n := nPosAnt
		If Type('oGetDad:oBrowse')<>"U"
			oGetDad:oBrowse:Refresh()
			Ma410Rodap()
		Endif
	Endif
	
	// 13/03/2018 
	// Zero o campo totalizador de quantidade de Volumes em Litros e Quantidade
	M->C5_XVOLLIT 	:= 0
	M->C5_XVOLQTE	:= 0
	For nW	:= 1 To Len(aCols)
		If !aCols[nW][Len(aHeader)+1]
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+aCols[nW][nPProd]) .And. aCols[nW][nPCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63#T70"
				If SB1->B1_CABO $ "TEX#ROC#HOU#IPI"
					M->C5_XVOLLIT	+= aCols[nW,nPQtd] * SB1->B1_QTELITS 
				ElseIf SB1->B1_CABO $ "MIC#MOT#CON#AGR#REL#BIK"
					M->C5_XVOLQTE	+= aCols[nW,nPQtd]  
				Endif
			Endif
		Endif
	Next 
	
	// Se houver diferença na quantidade de volumes já digitados anteriormente e a nova contagem 
	If M->C5_XVOLLIT <> nC5XVOLLIT .Or. M->C5_XVOLQTE <> nC5XVOLQTE 
		For nW	:= 1 To Len(aCols)								
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+aCols[nW][nPProd]) .And. aCols[nW][nPCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63"
				// Busca novo preço de tabela
				nXPrcTab := MaTabPrVen(aCols[nW][nPCodTab],aCols[nW][nPProd],aCols[nW][nPQtd],M->C5_CLIENTE,M->C5_LOJACLI,,,1/*nTipo*/,.F. /*lExec*/,,)
				nXPrcTab := Round(U_BFFATX02(M->C5_CONDPAG,.F. /*lSUA*/,.T./*lSC5*/,nXPrcTab,SB1->B1_PROC,.T.,aCols[nW][nPCodTab])[1],TamSX3("C6_PRUNIT")[2])
							
				// 13/03/2018 - Trecho que verifica os preços de Tabela por faixa de volume
				aPrTabs	:= aClone(U_BFFATX01(nXPrcTab,aCols[nW][nPCodTab],SB1->B1_CABO))
							
				aFxVolumes	:= aClone(U_BFFATX01(nXPrcTab,aCols[nW][nPCodTab],SB1->B1_CABO,2))
							
				aCols[nW][nPxPrTab1]	:= aPrTabs[1]
				aCols[nW][nPxPrTab2]	:= aPrTabs[2]
				aCols[nW][nPxPrTab3]	:= aPrTabs[3]
				aCols[nW][nPxPrTab4]	:= aPrTabs[4]
				aCols[nW][nPxPrTab5]	:= aPrTabs[5]
				aCols[nW][nPxPrTab6]	:= aPrTabs[6]
				
				For nL := 1 To Len(aFxVolumes)
					If SB1->B1_CABO $ "TEX#ROC#HOU#IPI"
						If (M->C5_XVOLLIT/20) <= aFxVolumes[nL]
							nXPrcTab	:= aPrTabs[nL]
							Exit
						Endif
					ElseIf  SB1->B1_CABO $ "MIC#MOT#CON#AGR#REL#BIK"
						If M->C5_XVOLQTE <= aFxVolumes[nL]
							nXPrcTab	:= aPrTabs[nL]
							Exit 
						Endif
					Endif
				Next nL 
				
				// Atribui preço mínimo e máximo para validações
				aCols[nW][nPPrcMin]		:= Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("C6_PRUNIT")[2])
				aCols[nW][nPPrcMax]		:= Round(nXPrcTab * 3, 2 )
				aCols[nW][nPPrcTab]		:= nXPrcTab
							
				nDesconto 	:= a410Arred( (aCols[nW][nPPrcTab]* aCols[nW][nPQtd]) - (aCols[nW][nPQtd] * aCols[nW][nPVrUnit]) ,"C6_VALDESC") 
							
							
				If nDesconto > 0
					aCols[nW][nPValDesc] 	:= nDesconto //Round( (nXPrcTab *  aCols[nW][nPDesc]  / 100 ) * aCols[nW][nPQtd],TamSX3("C6_VALDESC")[2])	
					aCols[nW][nPDesc] 		:= a410Arred( nDesconto /  (aCols[nW][nPPrcTab]* aCols[nW][nPQtd]) * 100 , "C6_DESCONT")
				Else
					aCols[nW][nPValDesc] 	:= 0
					aCols[nW][nPDesc] 		:= 0	
				Endif
						
			Endif
		Next
		If Type('oGetDad:oBrowse')<>"U"
			oGetDad:oBrowse:Refresh()
			Ma410Rodap()
		Endif
	Endif
			
	
Return lRet

