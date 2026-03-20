
/*/{Protheus.doc} BFTMKM01
(Retorna multiplo de litros para produtos a Granel )
	
@author Marcelo Lauschner
@since 06/05/2013
@version 1.0		

@return numérico, quantidade múltipla se for tambor

@example
(examples)

@see (links_or_references)
/*/
User Function BFTMKM01()
                
// (aCols[n,aPosicoes[15][2]]-aCols[n,aScan(aHeader,{|x| AllTrim(x[2])=="UB_XUPRCVE"})])*M->UB_QUANT   
	Local	aAreaOld	:= GetArea()
	Local	nPProd		:= aPosicoes[1][2]			// Produto
	Local	cCodProd	:= aCols[n,nPProd]
	Local	nQteRet		:= M->UB_QUANT
	Local	nPQtd     	:= aPosicoes[4][2]			// Quantidade
	Local	nPVrUnit  	:= aPosicoes[5][2]			// Valor unitario
	Local	nPVlrItem 	:= aPosicoes[6][2]			// Valor do item
	Local	nPDesc 		:= aPosicoes[9][2]			// % Desconto
	Local	nPValDesc 	:= aPosicoes[10][2]			// $ Desconto em Valor
	Local	nPPrcTab 	:= aPosicoes[15][2]			// Preço Tabela
	Local	nPAcre 		:= aPosicoes[13][2]			// % Acrescimo
	Local	nPValAcre 	:= aPosicoes[14][2]			// $ Acrescimo em Valor
	Local	nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2NUM"})
	Local	nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2LIN"})
	Local	nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})	
	Local	nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
	Local	nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
	Local	nPxPrTab1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB1"})
	Local	nPxPrTab2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB2"})
	Local	nPxPrTab3	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB3"})
	Local	nPxPrTab4	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB4"})
	Local	nPxPrTab5	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB5"})
	Local	nPxPrTab6	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB6"})
	Local	nUAXVOLLIT	:= M->UA_XVOLLIT
	Local	nUAXVOLQTE	:= M->UA_XVOLQTE
	Local	cNextAlias
	Local 	nSaldo
	Local	nW,nL
	Local	nXPrcTab	:= 0
	Local	aPrTabs		:= {}
	Local	aFxVolumes	:= {}
	Local	nDesconto	:= 0
 
// Se o código do produto conter a nomenclatura de embalagem de 159 litros
//If ".000159" $ cCodProd 
	If cCodProd $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
	// Força o valor da variável de quantidade, evitando que se digite zerado
		If nQteRet == 0
			nQteRet := 1
		Endif
		If M->UA_OPER <> "1"
			If !IsBlind()
				MsgAlert("Não é permitido digitar Orçamento/Atendimento para este produto devido o controle de Rastreabilidade","Produto com rastreabilidade!")
			Endif
			nQteRet	:= 0
			M->UB_QUANT	:= nQteRet
			aCols[n,nPQtd]	:= nQteRet
			Tk273Calcula("UB_QUANT")
			aCols[n,Len(aHeader)+1]	:= .T.
		Endif
		
		// Evita erro de não existir os campos ainda na base de produção
		If nPxPA2NUM > 0 .And. M->UA_OPER == "1"
		
			// Somente se ainda não houve a amarração com o item da produção
			If Empty(aCols[n,nPxPA2NUM]) .And. Empty(aCols[n,nPxPA2LIN])
				cNextAlias	:= GetNextAlias()
				BeginSql Alias cNextAlias
					SELECT PA2_NUM,PA2_LINHA,PA2.R_E_C_N_O_ PA2RECNO
					FROM %Table:PA2% PA2
					WHERE PA2.%NotDel%
					AND PA2_FILIAL = %xFilial:PA2%
					AND PA2_CODPRO = %Exp:cCodProd%
					AND PA2_NFRETO = ' '
					AND PA2_NUMNF = ' '
					AND PA2_PEDIDO = ' '
					AND PA2_RESERV = ' '
					AND PA2_DATFIM != ' '
					AND PA2_DTFIRM != ' '
					ORDER BY PA2_NUM,PA2_LINHA
				EndSql
				If !Eof()
				// Atualizo o Acols com o registro reservado
					aCols[n,nPxPA2NUM]	:= (cNextAlias)->PA2_NUM
					aCols[n,nPxPA2LIN]	:= (cNextAlias)->PA2_LINHA
					DbSelectarea("PA2")
					DbGoto((cNextAlias)->PA2RECNO)
					RecLock("PA2",.F.)
					PA2->PA2_RESERV	:= "SUA"+M->UA_NUM
					MsUnlock()
					
					// IAGO 20/10/2015 Chamado(12606)
					// Avisa saldo de tanques 
					nSaldo := 0
					DbSelectarea(cNextAlias)
					While !EOF()
						nSaldo++
						dbSkip()
					End
					If !!IsBlind()
						MsgInfo("Contando com este, saldo atual de "+ cValToChar(nSaldo) +" tanque(s) envasado(s)!","Aviso: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					EndIf
				Else
					If !IsBlind()
						MsgAlert("Não há estoque deste tambor envasado no momento. Possíveis causas podem ser o uso do tambor envasado em outro atendimento, item deletado neste mesmo atendimento, ou falta de envasamento de tambores","Falta Envasados!")
					Endif
					nQteRet			:= 0
					M->UB_QUANT		:= nQteRet
					aCols[n,nPQtd]	:= nQteRet
					aCols[n,nPxPA2NUM]	:= " "
					aCols[n,nPxPA2LIN]	:= " "
					Tk273Calcula("UB_QUANT")
					aCols[n,Len(aHeader)+1]	:= .T.
				Endif
				(cNextAlias)->(DbCloseArea())
			Endif
		Endif
	// Se a quantidade digitada não for um múltiplo de 159 - qte padrão para estes produtos
		If nQteRet <> 159
		//nQteRet		:= nQteRet * 159   
			nQteRet			:= 159	// A partir de 01/08/2013 a quantidade sempre deverá ser de um Tambor por item,por causa da rastreabilidade
			M->UB_QUANT		:= nQteRet
			aCols[n,nPQtd]	:= nQteRet
			Tk273Calcula("UB_QUANT")
		Endif
	Endif
	
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
					M->UA_XVOLLIT	+= IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) * SB1->B1_QTELITS 
				ElseIf SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK" // Michelin / Moto / Continental 
					M->UA_XVOLQTE	+= IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) 
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
				nXPrcTab := MaTabPrVen(aCols[nW][nPCodTab],aCols[nW][nPProd],IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) ,M->UA_CLIENTE,M->UA_LOJA,,,1/*nTipo*/,.F. /*lExec*/,,)
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
					ElseIf  SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK"
						If M->UA_XVOLQTE <= aFxVolumes[nL]
							nXPrcTab	:= aPrTabs[nL]
							Exit 
						Endif
					Endif
				Next nL 

				// Atribui preço mínimo e máximo para validações
				aCols[nW][nPPrcMin]		:= Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("C6_PRUNIT")[2])
				aCols[nW][nPPrcMax]		:= Round(nXPrcTab * 3, 2 )

				aCols[nW][nPPrcTab]		:= nXPrcTab

				nDesconto 	:= a410Arred((aCols[nW][nPPrcTab]*aCols[nW][nPQtd]) - (IIf(nW # n, aCols[nW,nPQtd] , nQteRet )  * aCols[nW][nPVrUnit]) ,"UB_VALDESC")

				If nDesconto > 0
					aCols[nW][nPValDesc] 	:= nDesconto
					aCols[nW][nPDesc] 		:= Round(nDesconto / (aCols[nW][nPPrcTab] * IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) ) * 100, TamSX3("UB_DESC")[2] )
					aCols[nW][nPValAcre] 	:= 0
					aCols[nW][nPAcre]		:= 0
				Else
					aCols[nW][nPValDesc] 	:= 0
					aCols[nW][nPDesc] 		:= 0
					aCols[nW][nPAcre]		:= Round((nDesconto * -1) / (aCols[nW][nPPrcTab]*IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) ) * 100, TamSX3("UB_ACRE")[2] )
					aCols[nW][nPValAcre] 	:= nDesconto * -1
				Endif
			
				MaFisAlt("IT_QUANT",IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) ,nW)
				MaFisAlt("IT_PRCUNI",aCols[nW][nPVrUnit],nW)
				MaFisAlt("IT_VALMERC",aCols[nW][nPVlrItem],nW)

				Eval(bListRefresh)
			Endif
		Next nW
	Endif

	RestArea(aAreaOld)

	RestArea(aAreaOld)

Return nQteRet


/*/{Protheus.doc} BFTMKM02
(Validar digitação de quantidades em Pedido de Venda  )
	
@author MarceloLauschner
@since 08/08/2013
@version 1.0		

@return numerico, quantidade multipla se for tambor

@example
(examples)

@see (links_or_references)
/*/
User Function BFTMKM02()
                
// (aCols[n,aPosicoes[15][2]]-aCols[n,aScan(aHeader,{|x| AllTrim(x[2])=="UB_XUPRCVE"})])*M->UB_QUANT   
	Local	aAreaOld	:= GetArea()
	Local	nPProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})			// Produto
	Local	cCodProd	:= aCols[n,nPProd]
	Local	nQteRet		:= M->C6_QTDVEN
	Local	nPQtd     	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})			// Quantidade
	Local	nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2NUM"})
	Local	nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2LIN"})
	Local	nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
	Local	nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMAX"})
	Local	nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
	Local	nPxPrTab1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB1"})
	Local	nPxPrTab2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB2"})
	Local	nPxPrTab3	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB3"})
	Local	nPxPrTab4	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB4"})
	Local	nPxPrTab5	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB5"})
	Local	nPxPrTab6	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB6"})
	Local	nPPrcTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	Local	nPVrUnit	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	Local	nPValDesc	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
	Local	nPDesc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
	Local	cNextAlias
	Local 	nSaldo		
	Local	nC5XVOLLIT	:= M->C5_XVOLLIT
	Local	nC5XVOLQTE	:= M->C5_XVOLQTE
	Local	nW ,nL
	Local	nXPrcTab	:= 0
	Local	aPrTabs		:= {}
	Local	aFxVolumes	:= {}
	Local	nDesconto	:= 0
 
	
	Local	nPxCF		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})
	
// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

// Se o código do produto conter a nomenclatura de embalagem de 159 litros
//If ".000159" $ cCodProd 
	If cCodProd $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  .And. !Alltrim(aCols[n,nPxCF]) $ "5926#5927"
	// Parametro precisa ter o tamanho do código do produto
	// Força o valor da variável de quantidade, evitando que se digite zerado
		If nQteRet == 0
			nQteRet := 1
		Endif
	
	// Evita erro de não existir os campos ainda na base de produção
		If nPxPA2NUM > 0
		// Somente se ainda não houve a amarração com o item da produção
			If Empty(aCols[n,nPxPA2NUM]) .And. Empty(aCols[n,nPxPA2LIN]) .And. M->C5_TIPO == "N" // Somente pedidos normais podem alocar reserva
				cNextAlias	:= GetNextAlias()
				BeginSql Alias cNextAlias
					SELECT PA2_NUM,PA2_LINHA,PA2.R_E_C_N_O_ PA2RECNO
					FROM %Table:PA2% PA2
					WHERE PA2.%NotDel%
					AND PA2_FILIAL = %xFilial:PA2%
					AND PA2_CODPRO = %Exp:cCodProd%
					AND PA2_NFRETO = ' '
					AND PA2_NUMNF = ' '
					AND PA2_PEDIDO = ' '
					AND PA2_RESERV = ' '
					AND PA2_DATFIM != ' '
					AND PA2_DTFIRM != ' '
					ORDER BY PA2_NUM,PA2_LINHA
				EndSql
				If !Eof()
				// Atualizo o Acols com o registro reservado
					aCols[n,nPxPA2NUM]	:= (cNextAlias)->PA2_NUM
					aCols[n,nPxPA2LIN]	:= (cNextAlias)->PA2_LINHA
					DbSelectarea("PA2")
					DbGoto((cNextAlias)->PA2RECNO)
					RecLock("PA2",.F.)
					PA2->PA2_RESERV	:= "SC5"+M->C5_NUM
					MsUnlock()
					
					// IAGO 20/10/2015 Chamado(12606)
					// Avisa saldo de tanques 
					nSaldo := 0
					dbSelectArea(cNextAlias)
					While !EOF()
						nSaldo++
						dbSkip()
					End
					If !IsBlind()
						MsgInfo("Contando com este, saldo atual de "+ cValToChar(nSaldo) +" tanque(s) envasado(s)!","Aviso: "+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					EndIf
				Else
					aCols[n,nPxPA2NUM]	:= " "
					aCols[n,nPxPA2LIN]	:= " "
					If !IsBlind()
						MsgAlert("Não há estoque deste tambor envasado no momento. Possíveis causas podem ser o uso do tambor envasado em outro atendimento, item deletado neste mesmo atendimento, ou falta de envasamento de tambores","Falta Envasados!")
					Endif
					nQteRet			:= 0
					aCols[n,nPQtd]	:= 0
					M->C6_QTDVEN	:= 0
					A410ReCalc()

				Endif
				(cNextAlias)->(DbCloseArea())
			Endif
		Endif
	// Se a quantidade digitada não for um múltiplo de 159 - qte padrão para estes produtos
		If nQteRet <> 159
		//nQteRet		:= nQteRet * 159   
			nQteRet			:= 159	// A partir de 01/08/2013 a quantidade sempre deverá ser de um Tambor por item,por causa da rastreabilidade
			aCols[n,nPQtd]	:= nQteRet
			M->C6_QTDVEN		:= nQteRet
			A410ReCalc()
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
					M->C5_XVOLLIT	+= IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) * SB1->B1_QTELITS 
				ElseIf SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK" // Michelin / Moto / Continental
					M->C5_XVOLQTE	+= IIf(nW # n, aCols[nW,nPQtd] , nQteRet ) 
				Endif
			Endif
		Endif
	Next 
	
	// Se houver diferença na quantidade de volumes já digitados anteriormente e a nova contagem 
	If M->C5_XVOLLIT <> nC5XVOLLIT .Or. M->C5_XVOLQTE <> nC5XVOLQTE 
		For nW	:= 1 To Len(aCols)								
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1")+aCols[nW][nPProd]) .And. aCols[nW][nPCodTab] $ "T07#T14#T21#T28#T35#T42#T49#T56#T63" .And. !aCols[nW][Len(aHeader)+1]
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
					ElseIf  SB1->B1_CABO $ "MIC#MOT#CON#REL#BIK" // Michelin / Moto / Continental
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
							
	RestArea(aAreaOld)

Return nQteRet
