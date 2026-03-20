#include "totvs.ch"
/*/{Protheus.doc} BFFATM16
(Validar condição de pagamento digitada  )

@author MarceloLauschner
@since 21/08/2013
@version 1.0

@param cInCond, character, (Descrição do parâmetro)

@return logico, se a condição de pagamento está liberada ou não

@example
(examples)

@see (links_or_references)
/*/
User Function BFFATM16(cInCond)

	Local	aAreaOld		:= GetArea()
	Local	aPrTabs			:= {}
	Local	aFxVolumes		:= {}
	Local	lRet			:= .T.
	Local	nDias			:= 0

	Local	nPPrcMin		:= 0
	Local	nPPrcMax		:= 0
	Local	nPCodTab		:= 0
	Local	nPPrcTab		:= 0
	Local	nPProd  		:= 0
	Local	nPQtd   		:= 0
	Local	nPVrUnit   		:= 0
	Local	nPVlrItem  		:= 0
	Local	nPValDesc  		:= 0
	Local	nPDesc			:= 0
	Local	nPRegBnf		:= 0
	Local	nPxPrTab1,nPxPrTab2,nPxPrTab3,nPxPrTab4,nPxPrTab5,nPxPrTab6	:= 0
	Local	nPAcre			:= 0
	Local	nPxFlgAlc		:= 0
	Local	nX,nW,nL
	Local	aCond			:= {}
	Local	nSumPrz			:= 0
	Local	nPValAcre		:= 0
	Local	nXPrcTab		:= 0
	Local	nDesconto		:= 0
	Local	cCodUsr			:= RetCodUsr()
	Local 	cCodCli			:= ""
	Local 	cLojCli 		:= ""
	Local 	cCondPgDef		:= "   "
	local 	lConfirm 		:= .F. as logical
	Default	cInCond			:= "128"

	If IsInCallStack("U_BIG017") .And. cCodUsr $ GetNewPar("BF_USRSERA","000000")
		Return .T.
	Endif

	// Verifica quem é o cliente/loja
	If ReadVar() == "M->UA_CONDPG"
		cCodCli		:= M->UA_CLIENTE
		cLojCli		:= M->UA_LOJA
	ElseIf ReadVar() == "M->C5_CONDPAG"
		cCodCli		:= M->C5_CLIENTE
		cLojCli		:= M->C5_LOJACLI
	Endif

	// Verifica se o cliente tem condição de pagamento padrão
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+cCodCli+cLojCli)
	cCondPgDef		:= SA1->A1_COND

	If !(cCodUsr $ GetNewPar("BF_USRSE4","000073#000103")) // Se não for usuários "Leandro/Greice"
		DbSelectArea("SE4")
		DbSetOrder(1)
		If DbSeek(xFilial("SE4")+cInCond)

			If cCondPgDef == cInCond
				If !IsBlind()
					MsgAlert("Condição de pagamento igual ao cadastro!","Condição de pagamento não autorizada!")
				Endif
			Endif
			// Efetua validação pelo prazo médio
			If lRet
				aCond 	:= Condicao(1,cInCond,0,dDataBase)
				For nX := 1 to Len(aCond)
					nDias 	+= aCond[nX][1] - dDatabase
					//Verifica se algum vencimento ultrapassa os 100 dias de prazo e impede o uso
					If aCond[nX][1] - dDatabase >= 100  .And. !(cInCond $ GetNewPar("GM_PSE4LIB","XXX"))
						If !IsBlind()
							MsgAlert("Não é mais autorizada inclusão de pedidos com prazo maior ou igual à 100 dias!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						Endif
						lRet	:= .F.
						Exit
					Endif
				Next
				// Calcula Prazo médio e atualiza a condição de pagamento por demanda.
				nSumPrz		:=0
				For nX := 1 to Len(aCond)
					nSumPrz 	+= aCond[nX][1] - dDatabase
				Next
				nSumPrz := Round(nSumPrz / Len(aCond),1)
				DbSelectArea("SE4")
				If Empty(SE4->E4_TABELA)
					RecLock("SE4",.F.)
					If nSumPrz <= 7
						SE4->E4_TABELA	:=	"T07"
					ElseIf nSumPrz <= 14
						SE4->E4_TABELA	:= "T14"
					ElseIf nSumPrz <= 21
						SE4->E4_TABELA	:= "T21"
					ElseIf nSumPrz <= 28
						SE4->E4_TABELA	:= "T28"
					ElseIf nSumPrz <= 35
						SE4->E4_TABELA  := "T35"
					ElseIf nSumPrz <= 42
						SE4->E4_TABELA	:= "T42"
					ElseIf nSumPrz <= 49
						SE4->E4_TABELA	:= "T49"
					ElseIf nSumPrz <= 56
						SE4->E4_TABELA	:= "T56"
					ElseIf nSumPrz <= 63
						SE4->E4_TABELA	:= "T63"
					ElseIf nSumPrz <= 70
						SE4->E4_TABELA	:= "T70"
					Else 
						SE4->E4_TABELA	:= "T70"
					Endif					
					MsUnlock()
				Endif
				// Atualiza prazo médio da condição 	
				If Empty(SE4->E4_PRZMEDI)
					RecLock("SE4",.F.)
					SE4->E4_PRZMEDI 	:= Int(nSumPrz)
					MsUnlock()
				Endif
			Endif
		Else
			Return lRet	:= .F.
		Endif
	Endif

	// Se estiver em digitação de orçamento
	If ReadVar() == "M->UA_CONDPG" .And. lRet
		nPPrcMax		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
		nPPrcMin		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
		nPxFlgAlc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XALCADA"})

		If Type("cCondOld") == "U"
			Public 	cCondOld	:= M->UA_CONDPG
		Endif
		// Se a condição de pgamento foi alterada com alteração do prazo médio, força o zeramento de todos os itens
		If cInCond <> cCondOld
			If !sfVldSE4(cInCond,cCondOld) 
				lConfirm := IsBlind() .or. MsgNoYes("A alteração da condição de pagamento implicou em mudança do PRAZO MÉDIO que é diferente da condição antiga! Deseja continuar com alteração, pois todos os itens terão que ser redigitados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Condição alterada.")
				If lConfirm
					nPProd		:= aPosicoes[1][2]			// Produto
					nPQtd     	:= aPosicoes[4][2]			// Quantidade
					nPVrUnit  	:= aPosicoes[5][2]			// Valor unitario
					nPVlrItem 	:= aPosicoes[6][2]			// Valor do item
					nPDesc 		:= aPosicoes[9][2]			// % Desconto
					nPValDesc 	:= aPosicoes[10][2]			// $ Desconto em Valor
					nPPrcTab 	:= aPosicoes[15][2]			// Preço Tabela
					nPAcre 		:= aPosicoes[13][2]			// % Acrescimo
					nPValAcre 	:= aPosicoes[14][2]			// $ Acrescimo em Valor

					nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
					nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
					nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
					nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})
					nPxPrTab1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB1"})
					nPxPrTab2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB2"})
					nPxPrTab3	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB3"})
					nPxPrTab4	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB4"})
					nPxPrTab5	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB5"})
					nPxPrTab6	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB6"})

					For nW	:= 1 To Len(aCols)
						If !Empty(aCols[nW][nPRegBnf]) .And. !aCols[nW][Len(aHeader)+1]
							MsgStop("Foi encontrado derivado de Combo na linha " + cValToChar(nW)+ ". Antes de alterar a condição de pagamento você deve deletar todos os Combos!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Combo localizado! ")
							M->UA_CONDPG 	:= cCondOld
							RestArea(aAreaOld)
							Return lRet
						Endif
					Next

					For nW	:= 1 To Len(aCols)
						DbSelectArea("SB1")
						DbSetOrder(1)
						If DbSeek(xFilial("SB1")+aCols[nW][nPProd]) .And. aCols[nW][nPCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63" .And. !aCols[nW][Len(aHeader)+1]
							// Atribui novo código de tabela baseado no prazo selecionado
							aCols[nW][nPCodTab]			:= SE4->E4_TABELA

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
								ElseIf  SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK#AGR"
									If M->UA_XVOLQTE <= aFxVolumes[nL]
										nXPrcTab	:= aPrTabs[nL]
										Exit
									Endif
								Endif
							Next nL

							// Atribui preço mínimo e máximo para validações
							aCols[nW][nPPrcMin]		:= Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("C6_PRUNIT")[2])
							aCols[nW][nPPrcMax]		:= Round(nXPrcTab * 3, 2 )
							aCols[nW][nPxFlgAlc]	:= "" // Zera as aprovações e submete o orçamento a nova liberação por que a condição de pagamento foi alterada.

							aCols[nW][nPPrcTab]		:= nXPrcTab

							nDesconto 	:= a410Arred((aCols[nW][nPPrcTab]*aCols[nW][nPQtd]) - (aCols[nW][nPQtd] * aCols[nW][nPVrUnit]) ,"UB_VALDESC")

							If nDesconto > 0
								aCols[nW][nPValDesc] 	:= nDesconto
								aCols[nW][nPDesc] 		:= Round(nDesconto / (aCols[nW][nPPrcTab]*aCols[nW][nPQtd]), TamSX3("UB_DESC")[2] )
								aCols[nW][nPValAcre] 	:= 0
								aCols[nW][nPAcre]		:= 0
							Else
								aCols[nW][nPValDesc] 	:= 0
								aCols[nW][nPDesc] 		:= 0
								aCols[nW][nPAcre]		:= Round((nDesconto * -1) / (aCols[nW][nPPrcTab]*aCols[nW][nPQtd]), TamSX3("UB_ACRE")[2] )
								aCols[nW][nPValAcre] 	:= nDesconto * -1
							Endif


							MaFisAlt("IT_QUANT",aCols[nW][nPQtd],nW)
							MaFisAlt("IT_PRCUNI",aCols[nW][nPVrUnit],nW)
							MaFisAlt("IT_VALMERC",aCols[nW][nPVlrItem],nW)

							Eval(bListRefresh)
						Endif
					Next
				Else
					M->UA_CONDPG 	:= cCondOld
				Endif
			Endif
			cCondOld	:= M->UA_CONDPG
		Endif
	ElseIf ReadVar() == "M->C5_CONDPAG" .And. lRet

		nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMAX"})
		nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
		nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
		nPPrcTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
		nPProd  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
		nPQtd   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
		nPVrUnit   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
		nPPrcTab   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
		nPVlrItem  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
		nPValDesc  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
		nPDesc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
		nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
		nPxPrTab1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB1"})
		nPxPrTab2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB2"})
		nPxPrTab3	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB3"})
		nPxPrTab4	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB4"})
		nPxPrTab5	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB5"})
		nPxPrTab6	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB6"})


		// Se a condição de pgamento foi alterada com alteração do prazo médio, força o zeramento de todos os itens
		If cInCond <> M->C5_XCONDPG
			If !sfVldSE4(cInCond,M->C5_XCONDPG) .And. !IsBlind()

				For nW	:= 1 To Len(aCols)
					If !Empty(aCols[nW][nPRegBnf]) .And. !aCols[nW][Len(aHeader)+1]
						MsgStop("Foi encontrado derivado de Combo na linha " + cValToChar(nW)+ ". Antes de alterar a condição de pagamento você deve deletar todos os Combos!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Combo localizado! ")
						M->C5_CONDPAG 	:= M->C5_XCONDPG
						RestArea(aAreaOld)
						Return lRet
					Endif
				Next

				If MsgNoYes("A alteração da condição de pagamento implicou em mudança do PRAZO MÉDIO que é diferente da condição antiga! Deseja continuar com alteração, pois todos os itens terão que ser redigitados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Condição alterada.")

					For nW	:= 1 To Len(aCols)
						DbSelectArea("SB1")
						DbSetOrder(1)
						If DbSeek(xFilial("SB1")+aCols[nW][nPProd]) .And. aCols[nW][nPCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63" .And. !aCols[nW][Len(aHeader)+1]
							// Atribui novo código de tabela baseado no prazo selecionado
							aCols[nW][nPCodTab]			:= SE4->E4_TABELA

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
								ElseIf  SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK#AGR"
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
								nDesconto				:= a410Arred( nDesconto / nXPrcTab * 100 , "C6_DESCONT")
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
				Else
					M->C5_CONDPAG 	:= M->C5_XCONDPG
					lRet	:= .F.
				Endif
			Endif
		Endif
		M->C5_XCONDPG	:= M->C5_CONDPAG
	Endif

	RestArea(aAreaOld)

Return lRet



/*/{Protheus.doc} sfVldSE4
(long_description)
@type function
@author marce
@since 09/10/2015
@version 1.0
@param cInCondNew, character, (Descrição do parâmetro)
@param cInCondOld, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldSE4(cInCondNew,cInCondOld)

	Local	lRet		:= .T.
	Local	aCondOld	:= Condicao(100,IIf(cInCondOld == Nil,"128",cInCondOld),0,dDataBase)
	Local	aCondNew	:= Condicao(100,Iif(cInCondNew == Nil,"128",cInCondNew),0,dDataBase)
	Local	nPrzNew	:= 0
	Local	nPrzOld	:= 0
	Local	nNParNew	:= Len(aCondNew)
	Local	nPParOld	:= Len(aCondOld)
	Local	nX
	// Calcula Prazo Médio da condição pagamento antiga
	For nX := 1 To nPParOld
		nPrzOld 	+= aCondOld[nX][1] - dDatabase
	Next
	nPrzOld	:= Int(nPrzOld/nPParOld)

	// Calcula Prazo Médio da nova condição de pagamento
	For nX := 1 To nNParNew
		nPrzNew 	+= aCondNew[nX][1] - dDatabase
	Next
	nPrzNew	:= Int(nPrzNew/nNParNew)

	If nPrzNew <> nPrzOld
		lRet	:= .F.
	Endif

Return lRet
