#include "totvs.ch"
/*/{Protheus.doc} TMKVDEL
(Efetua o recalculo dos preços tabela e venda mantendo os descontos já digitados )

@author MarceloLauschner
@since 22/01/2014
@version 1.0		

@return logico, 

@example
(examples)

@see (links_or_references)
/*/
User Function TMKVDEL()

	//Return .T.

	//Static Function sfTmkvDel

	Local		lRet		:= .T. 
	Local		cCliente	:= M->UA_CLIENTE
	Local		cLoja		:= M->UA_LOJA	
	Local		aAreaOld	:= GetArea()
	Local		nW			:= 0
	Local		nPProd		:= aPosicoes[1][2]			// Produto
	Local		nPQtd     	:= aPosicoes[4][2]			// Quantidade
	Local		nPVrUnit  	:= aPosicoes[5][2]			// Valor unitario
	Local		nPVlrItem 	:= aPosicoes[6][2]			// Valor do item
	Local		nPDesc 		:= aPosicoes[9][2]			// % Desconto
	Local		nPValDesc 	:= aPosicoes[10][2]			// $ Desconto em Valor
	Local		nPPrcTab 	:= aPosicoes[15][2]			// Preço Tabela
	Local		nPAcre 		:= aPosicoes[13][2]			// % Acrescimo
	Local		nPValAcre 	:= aPosicoes[14][2]			// $ Acrescimo em Valor
	Local 		nPosAnt		:= n
	Local		nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2NUM"})
	Local		nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2LIN"})
	Local		nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})   
	Local		nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})	
	Local		nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
	Local		nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
	Local		nPxPrTab1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB1"})
	Local		nPxPrTab2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB2"})
	Local		nPxPrTab3	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB3"})
	Local		nPxPrTab4	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB4"})
	Local		nPxPrTab5	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB5"})
	Local		nPxPrTab6	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB6"})
	Local		nUAXVOLLIT	:= M->UA_XVOLLIT
	Local		nUAXVOLQTE	:= M->UA_XVOLQTE
	Local		cRegBoni	:= ""
	Local		iQ,nL
	Local		nXPrcTab	:= 0
	Local		aPrTabs		:= {}
	Local		aFxVolumes	:= {}
	Local		nDesconto	:= 0
	
	If Type("cCondOld") == "U"
		Public 	cCondOld	:= M->UA_CONDPG
	Endif
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("TMKVDEL")
		RestArea(aAreaOld)
		Return .T. 
	Endif
	
	
	
	If !lProspect
		DbSelectArea("SA1")
		DbSetOrder(1)
		If MsSeek(xFilial("SA1")+cCliente+cLoja)
			// Verifica se o cliente possui tabela de preços especifica - nos 3 segmentos
			If (SA1->A1_TABELA >= "301" .And. SA1->A1_TABELA <= "3ZZ") .Or.;	// Tabela por cliente Texaco
			(SA1->A1_TABELA >= "401" .And. SA1->A1_TABELA <= "4ZZ") .Or.;	// Tabela por cliente Michelin
			(SA1->A1_TABELA >= "501" .And. SA1->A1_TABELA <= "5ZZ") 	// Tabela por cliente Wynns					
				RestArea(aAreaOld)
				Return 
			Endif
		Endif
	Endif

	// Forço a verificação ao deletar um item
	If aCols[n][nPProd] $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
		If (M->UA_OPER <> "1" .Or. Empty(aCols[n,nPxPA2NUM]) .Or. Empty(aCols[n,nPxPA2LIN])) .And. !aCols[n][Len(aHeader)+1]
			aCols[n,Len(aHeader)+1]	:= .T.
			M->UB_QUANT	:= aCols[n,nPQtd]
			Tk273Calcula("UB_QUANT")
		Endif
	Endif

	// Verifica se a linha é um derivado de Combo
	If !Empty(aCols[n][nPRegBnf]) 
		cRegBoni	:= Substr(aCols[n][nPRegBnf],1,6)
		If aCols[n][Len(aHeader)+1]
			aCols[n][nPRegBnf]	:= "XXXXXX"
			MsgAlert("Você deletou um item derivado de Combo. Todos os demais produtos do Combo serão deletados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			For iQ := 1 To Len(aCols)
				If iQ <> nPosAnt .And. Substr(aCols[iQ][nPRegBnf],1,6) == cRegBoni
					n	:= iQ
					aCols[n][nPRegBnf]			:= "XXXXXX"
					aCols[n][Len(aHeader)+1]	:= .T.
					MaFisDel(n,aCols[n][Len(aCols[n])])
					//TK273DelTlv(0, Iif(INCLUI,3,Iif(ALTERA,4,2)))							
				Endif
			Next iQ
		Else
			MsgAlert("Não permitido recuperar item derivado de Combo que foi deletado!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			aCols[n][Len(aHeader)+1]	:= .T.
			MaFisDel(n,aCols[n][Len(aCols[n])])						
		Endif

	Endif
	n := nPosAnt

	// 13/03/2018 
	// Zero o campo totalizador de quantidade de Volumes em Litros e Quantidade
	M->UA_XVOLLIT 	:= 0
	M->UA_XVOLQTE	:= 0
	For nW	:= 1 To Len(aCols)
		If !aCols[nW][Len(aHeader)+1]
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+aCols[nW][nPProd]) .And. aCols[nW][nPCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63#T70"
				If SB1->B1_CABO $ "TEX#ROC#HOU#IPI"
					M->UA_XVOLLIT	+= aCols[nW,nPQtd] * SB1->B1_QTELITS 
				ElseIf SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK" // Michelin / Moto / Continental 
					M->UA_XVOLQTE	+= aCols[nW,nPQtd]
				Endif
			Endif
		Endif
	Next 

	// Se houver diferença na quantidade de volumes já digitados anteriormente e a nova contagem 
	If M->UA_XVOLLIT <> nUAXVOLLIT .Or. M->UA_XVOLQTE <> nUAXVOLQTE 
		For nW	:= 1 To Len(aCols)								
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+aCols[nW][nPProd]) .And. aCols[nW][nPCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63" .And. !aCols[nW][Len(aHeader)+1]
				// Atribui novo código de tabela baseado no prazo selecionado

				// Busca novo preço de tabela
				nXPrcTab := MaTabPrVen(aCols[nW][nPCodTab],aCols[nW][nPProd],aCols[nW][nPQtd],M->UA_CLIENTE,M->UA_LOJA,,,1/*nTipo*/,.F. /*lExec*/,,)
				nXPrcTab := Round(U_BFFATX02(M->UA_CONDPG,.T. /*lSUA*/,.F./*lSC5*/,nXPrcTab,SB1->B1_PROC,.T.,aCols[nW][nPCodTab])[1],TamSX3("C6_PRUNIT")[2])

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
						If (M->UA_XVOLLIT/20) <= aFxVolumes[nL]
							nXPrcTab	:= aPrTabs[nL]
							Exit
						Endif
					ElseIf  SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK" // Michelin / Moto / Continental 
						If M->UA_XVOLQTE <= aFxVolumes[nL]
							nXPrcTab	:= aPrTabs[nL]
							Exit 
						Endif
					Endif
				Next nL 

				// Atribui preço mínimo e máximo para validações
				aCols[nW][nPPrcMin]		:= Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("UB_VRUNIT")[2])
				aCols[nW][nPPrcMax]		:= Round(nXPrcTab * 3, 2 )

				aCols[nW][nPPrcTab]		:= nXPrcTab

				nDesconto 	:= a410Arred((aCols[nW][nPPrcTab]*aCols[nW][nPQtd]) - (aCols[nW][nPQtd] * aCols[nW][nPVrUnit]) ,"UB_VALDESC")

				If nDesconto > 0
					aCols[nW][nPValDesc] 	:= nDesconto
					aCols[nW][nPDesc] 		:= Round(nDesconto / (aCols[nW][nPPrcTab]*aCols[nW][nPQtd]) * 100, TamSX3("UB_DESC")[2] )
					aCols[nW][nPValAcre] 	:= 0
					aCols[nW][nPAcre]		:= 0
				Else
					aCols[nW][nPValDesc] 	:= 0
					aCols[nW][nPDesc] 		:= 0
					aCols[nW][nPAcre]		:= Round((nDesconto * -1) / (aCols[nW][nPPrcTab]*aCols[nW][nPQtd]) * 100, TamSX3("UB_ACRE")[2] )
					aCols[nW][nPValAcre] 	:= nDesconto * -1
				Endif
			
				MaFisAlt("IT_QUANT",aCols[nW][nPQtd],nW)
				MaFisAlt("IT_PRCUNI",aCols[nW][nPVrUnit],nW)
				MaFisAlt("IT_VALMERC",aCols[nW][nPVlrItem],nW)

				Eval(bListRefresh)
			Endif
		Next
	Endif

	RestArea(aAreaOld)

	Eval(bListRefresh)

Return lRet


