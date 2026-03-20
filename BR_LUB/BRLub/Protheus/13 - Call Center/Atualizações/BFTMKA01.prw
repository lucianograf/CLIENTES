
/*/{Protheus.doc} BFTMKA01
(Calcula preço de venda liquido baseado em preço com ST/IPI )
	
@author Marcelo Lauschner
@since 10/01/2013
@version 1.0		

@return logico, 

@example
(examples)

@see (links_or_references)
/*/
User Function BFTMKA01()

	Local	nXPrcFull	:= 0
	Local	nXPrcAux	:= 0
	Local	aAreaOld	:= GetArea()
	Local	lEmpUsrTb	:= !(cEmpAnt $ "02")
	Local	nx			:= 0
	Local	ny			:= 0
	Local 	nPProd		:= 0
	Local 	nPQtd     	:= 0
	Local 	nPVrUnit  	:= 0
	Local 	nPVlrItem 	:= 0
	Local 	nPDesc 	:= 0
	Local 	nPValDesc 	:= 0
	Local	nPPrcTab	:= 0
	Local 	nPAcre 	:= 0
	Local 	nPValAcre 	:= 0
	Local	nPTes		:= 0
	Local	nPCfo		:= 0
	Local	nPLocal	:= 0
	Local	nPItem		:= 0
	Local	nT			:= n
	Local	cCliPed	:= ""
	Local	nPCodTab	:= 0
	Local	nPPrcMax	:= 0
	Local	nPPrcMin	:= 0	
	
	
	// Avalia se é de CallCenter
	If Type("M->UB_XUPRCVE") <> "U" .And. !lProspect
	
		nPProd		:= aPosicoes[1][2]			// Produto
		nPQtd     	:= aPosicoes[4][2]			// Quantidade
		nPVrUnit  	:= aPosicoes[5][2]			// Valor unitario
		nPVlrItem 	:= aPosicoes[6][2]			// Valor do item
		nPDesc 		:= aPosicoes[9][2]			// % Desconto
		nPValDesc 	:= aPosicoes[10][2]			// $ Desconto em Valor
		nPPrcTab 	:= aPosicoes[15][2]			// Preço Tabela
		nPAcre 		:= aPosicoes[13][2]			// % Acrescimo
		nPValAcre 	:= aPosicoes[14][2]			// $ Acrescimo em Valor
		nPTes		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_TES"})
		nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
		nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
		nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
	
		DbSelectArea("SB1")
		DbSetOrder(1)
		MsSeek(xFilial("SB1")+aCols[nT][nPProd])
        
        SF4->(MsSeek(xFilial("SF4")+aCols[nT][nPTES]))
                
		nXPrcAux			:= aCols[nT][nPPrcTab]
		nXPrcFull			:= M->UB_XUPRCVE
		// Verifica se há calculo do IPI na saída 
		nPIPI				:= IIf(SF4->F4_DESTACA == "S",MaFisRet(nT,"IT_ALIQIPI"),0)
		// Verifica se há destaca do ST na Saída
		nPICMENT			:= IIf(SF4->F4_INCSOL == "S",MaFisRet(nT,"IT_MARGEM"),0)
		
		nPICM 				:= MaFisRet(nT,"IT_ALIQICM")
		//AC17AL17AM17BA17CE17DF17ES17GO17MA17MG18MS17MT17PA17PB17PE17PI17PR18RJ19RN17RO17RR17RS17SC17SE17SP18TO17   
		If nPICMENT > 0
			nALQUF		:= Val(Substr(GetMv("MV_ESTICM"),AT(SA1->A1_EST,GetMv("MV_ESTICM"))+2,2))
		Else
			nALQUF		:= 0
			nPICM		:= 0
		Endif
		//		X*(1,05)*(1,5663)=197,35
		// Faço o descalculo do preço do item
		aCols[nT][nPVrUnit] := Round(nXPrcFull / ((1+((1+(nPIPI/100))*(1+(nPICMENT/100))*(nALQUF/100)))-(1+(nPICM/100)-(1+(nPIPI/100)))),2)
   		//	                                     ((1+((1+(F11/100  ))*(1+(F13     /100))*(F14   /100)))-(1+(F12  /100)-(1+(F11  /100))))
   		//	=G16 /                               ((1+((1+(F11  /100) *(1+(F13     /100))*(F14   /100)))-(1+(F12  /100)-(1+(F11  /100))))
    
 
				
		// Recalcula o Valor de Desconto
		aCols[nT][nPValDesc] := Round( (nXPrcAux - aCols[nT][nPVrUnit]) * aCols[nT][nPQtd],TamSX3("UB_VALDESC")[2])
		If aCols[nT][nPValDesc] < 0
			aCols[nT][nPValDesc]	:= 0
		Endif
		// Recalcula o Percentual de desconto
		aCols[nT][nPDesc] := Round( aCols[nT][nPValDesc] / (nXPrcAux * aCols[nT][nPQtd]) * 100,TamSX3("UB_DESC")[2])
		
		// Recalcula o Valor do Acrescimo
		aCols[nT][nPValAcre] := Round( (aCols[nT][nPVrUnit] - nXPrcAux) * aCols[nT][nPQtd],TamSX3("UB_VALACRE")[2])
		If 	aCols[nT][nPValAcre] < 0
			aCols[nT][nPValAcre] 	:= 0
		Endif
		// Recalcula o Percentual de Acrescimo
		aCols[nT][nPAcre] := Round( aCols[nT][nPValAcre] / (nXPrcAux * aCols[nT][nPQtd]) * 100,TamSX3("UB_ACRE")[2])
		
		aCols[nT][nPVrUnit] := A410Arred(nXPrcAux - (aCols[nT][nPValDesc] / aCols[nT][nPQtd]) + (aCols[nT][nPValAcre] / aCols[nT][nPQtd]),"UB_VLRITEM")
			
		aCols[nT][nPVlrItem]:= A410Arred(aCols[nT][nPQtd] * aCols[nT][nPVrUnit],"UB_VLRITEM")
				
		MaFisAlt("IT_QUANT",aCols[nT][nPQtd],nT)
		MaFisAlt("IT_PRCUNI",aCols[nT][nPVrUnit],nT)
		MaFisAlt("IT_VALMERC",aCols[nT][nPVlrItem],nT)
				

		Eval(bListRefresh)

	ElseIf Type("M->C6_XUPRCVE") <> "U"
	
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
		nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
	
		DbSelectArea("SB1")
		DbSetOrder(1)
		MsSeek(xFilial("SB1")+aCols[nT][nPProd])
                
		nXPrcAux			:= aCols[nT][nPPrcTab]
		nXPrcFull			:= M->C6_XUPRCVE
		//-------------------------------------------------------------------------------------------------------------------------------------------------------------------

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Busca referencias no SC6                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aFisGet	:= {}
		dbSelectArea("SX3")
		dbSetOrder(1)
		MsSeek("SC6")
		While !Eof().And.X3_ARQUIVO=="SC6"
			cValid := UPPER(X3_VALID+X3_VLDUSER)
			If 'MAFISGET("'$cValid
				nPosIni 	:= AT('MAFISGET("',cValid)+10
				nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
				cReferencia := Substr(cValid,nPosIni,nLen)
				aAdd(aFisGet,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
			EndIf
			If 'MAFISREF("'$cValid
				nPosIni		:= AT('MAFISREF("',cValid) + 10
				cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
				aAdd(aFisGet,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
			EndIf
			dbSkip()
		EndDo
		aSort(aFisGet,,,{|x,y| x[3]<y[3]})

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Busca referencias no SC5                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aFisGetSC5	:= {}
		dbSelectArea("SX3")
		dbSetOrder(1)
		MsSeek("SC5")
		While !Eof().And.X3_ARQUIVO=="SC5"
			cValid := UPPER(X3_VALID+X3_VLDUSER)
			If 'MAFISGET("'$cValid
				nPosIni 	:= AT('MAFISGET("',cValid)+10
				nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
				cReferencia := Substr(cValid,nPosIni,nLen)
				aAdd(aFisGetSC5,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
			EndIf
			If 'MAFISREF("'$cValid
				nPosIni		:= AT('MAFISREF("',cValid) + 10
				cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
				aAdd(aFisGetSC5,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
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

		nValMerc  := (aCols[nT][nPQtd])*aCols[nT][nPVrUnit]
		nPrcLista := aCols[nT][nPPrcTab]
		nDesconto := a410Arred(nPrcLista*(aCols[nT][nPQtd]),"D2_DESCON")-nValMerc
		nDesconto := IIf(nDesconto<=0,aCols[nT][nPValDesc],nDesconto)

		MaFisAdd(	cProduto,;   		// 1-Codigo do Produto ( Obrigatorio )
		aCols[nT][nPTES],;	   		// 2-Codigo do TES ( Opcional )
		aCols[nT][nPQtd],; 	 		// 3-Quantidade ( Obrigatorio )
		aCols[nT][nPPrcTab],;		// 4-Preco Unitario ( Obrigatorio )
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
		aCols[nT,nPCfo],; 			// 20-CFO
		{},;	           			// 21-Array para o calculo do IVA Ajustado (opcional)
		"")								// 22-Codigo Retencao - Equador

		//-------------------------------------------------------------------------------------------------------------------------------------------------------------------

	
		nPIPI		:= MaFisRet(1,"IT_ALIQIPI")
		nPICMENT	:= MaFisRet(1,"IT_MARGEM")
		nPICM 		:= MaFisRet(1,"IT_ALIQICM")
		//AC17AL17AM17BA17CE17DF17ES17GO17MA17MG18MS17MT17PA17PB17PE17PI17PR18RJ19RN17RO17RR17RS17SC17SE17SP18TO17                                                                                                                                                  
		If nPICMENT > 0
			nALQUF		:= Val(Substr(GetMv("MV_ESTICM"),AT(SA1->A1_EST,GetMv("MV_ESTICM"))+2,2))
		Else
			nALQUF		:= 0
			nPICM		:= 0
		Endif

		//		X*(1,05)*(1,5663)=197,35
		// Faço o descalculo do preço do item                                                                                                     
		
		MaFisEnd()
		MaFisRestore()
		
		
		aCols[nT][nPVrUnit] := Round(nXPrcFull / ((1+((1+(nPIPI/100))*(1+(nPICMENT/100))*(nALQUF/100)))-(1+(nPICM/100)-(1+(nPIPI/100)))),2)
	
		nPrcAnt := aCols[nT][nPVrUnit]
				
		If nPrcAnt < nXPrcAux
			aCols[nT][nPValDesc] 	:= Round( (nXPrcAux - nPrcAnt) * aCols[nT][nPQtd],TamSX3("C6_VALDESC")[2])
			aCols[nT][nPDesc] 		:= Round( aCols[nT][nPValDesc] / (aCols[nT][nPPrcTab]*aCols[nT][nPQtd]) * 100,TamSX3("C6_DESCONT")[2])
			aCols[nT][nPVrUnit] 		:= A410Arred(nXPrcAux - (aCols[nT][nPValDesc] / aCols[nT][nPQtd]),"D2_PRCVEN")
		Else
			aCols[nT][nPValDesc] 	:= 0
			aCols[nT][nPDesc] 		:= 0
		Endif
				
		aCols[nT][nPVlrItem]	:= A410Arred(aCols[nT][nPQtd] * aCols[nT][nPVrUnit],"C6_VALOR")
		
		// Se houver MVA para o produto
		If cFilAnt $ "01#04#05#07#08#09" .And. nPICMENT > 0
			aCols[nT][nPPrcMin]	:= nPrcAnt
		Endif
				
		MaFisAlt("IT_QUANT",aCols[nT][nPQtd],nT)
		MaFisAlt("IT_PRCUNI",aCols[nT][nPVrUnit],nT)
		MaFisAlt("IT_VALMERC",aCols[nT][nPVlrItem],nT)
				
		If Type('oGetDad:oBrowse')<>"U"
			oGetDad:oBrowse:Refresh()
			Ma410Rodap()
		Endif
		
	Endif

	RestArea(aAreaOld)

Return .T.


