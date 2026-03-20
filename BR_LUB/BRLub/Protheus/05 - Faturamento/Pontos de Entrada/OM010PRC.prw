#include "protheus.ch"
//#INCLUDE "FIVEWIN.CH"
#include "topconn.ch"

/*/{Protheus.doc} OM010PRC
(Ponto de Entrada que retorna o preço conforme regras  )

@author MarceloLauschner
@since 05/02/2012
@version 1.0

@return nResult, Retorna preço de Venda

@example
(examples)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6091277)
/*/
User Function OM010PRC()


	Local	aAreaOld	:= GetArea()
	Local	lEmpUsrTb	:= !(cEmpAnt $ "14")
	Local	nX	
	Local	nY	
	Local	nA	
	Local 	nPProd		:= 0
	Local 	nPQtd     	:= 0
	Local 	nPVrUnit  	:= 0
	Local 	nPVlrItem 	:= 0
	Local 	nPDesc 		:= 0
	Local 	nPValDesc 	:= 0
	Local	nPPrcTab	:= 0
	Local 	nPAcre 		:= 0
	Local 	nPValAcre 	:= 0
	Local	nPItem		:= 0
	Local	nPVlrTampa	:= 0
	Local	nPxComis1	:= 0
	Local	nPxComis2	:= 0
	Local	nPxComis3	:= 0
	Local	nPxUprcVe	:= 0

	Local	nPTpMov	:= 0

	Local		aDA0xSA2	:= {;
	{"400","000473"},;
	{"400","001609"},;
	{"500","000449"},;
	{"500","000455"},;
	{"500","004688"},; // Adicionado em 03/07/2020 
	{"500","002334"},;
	{"500","002993"},;
	{"300","XXXXXX"}}
	Local		nPrzCond	:= 0
	Local		nXPrctab	:= 0
	Local		cProduto	:= ParamIxb[2]
	Local		nQtde		:= ParamIxb[3]
	Local		cCliente	:= ParamIxb[4]
	Local		cLoja		:= ParamIxb[5]
	Local		nMoeda		:= ParamIxb[6] //Moeda
	Local		dDataVld	:= ParamIxb[7] //Data de Validade
	Local		nTipo		:= ParamIxb[8] //Tipo (1=Preço/2 = Fator de acréscimo ou desconto)
	Local		lIsAuto		:= IsBlind()
	Local		lRetPrc		:= .F.
	Local		lOkRadMenu	:= .F.
	Local		nPCodTab	:= nPPrcMax := nPPrcMin := nPVlrTampa	:= 0
	Local		nValTampa	:= 0
	Local		nPComis1	:= 0
	Local		nPComis2	:= 0
	Local		nPComis3	:= 0
	Local		nPComisAux	:= 0
	Local		nPxFlex		:= 0 
	Local		nPxPrTab1,nPxPrTab2,nPxPrTab3,nPxPrTab4,nPxPrTab5,nPxPrTab6	:= 0
	Local		nPTes,nPPrcMax,nPPrcMin
	Local		cNotDA0		:= IIf((Type("M->UA_CLIENTE") <> "U"),"'ET1','EM1','WA1'","") // Não carrega na tela tabelas de integrações b2b
	Local		cVend1		:= ""
	Local		cVend2		:= ""
	Local		nContAux	:= 0
	Local		aArrTamp
	Local		cQry
	Local		iM,iT,iZ,iP
	Private		aRadioPrc	:= {}// Vetor que será alimentado com a lista de preços possíveis para o produto
	Private		aRadioAux	:= {}
	Private		aRadioTamp	:= {}
	Private		aAuxRadTam	:= {}
	Private		nRadioPrc	:= 1
	Private		nRadTamp	:= 1
	Private		oDlgPrc,oPrcMin1,oPrcMin2,oPrcMin3,oPrcMin4,oPrcMin5,oPrcMin6,oSimulaPrc,oRadio,oRadTamp,oPrTab1,oPrTab2,oPrTab3,oPrTab4,oPrTab5,oPrTab6
	Private		nSimulaPrc	:= 0
	Private		cTabPreco 	:= ParamIxb[1]
	Private 	aTotRdpe	:= {0,0,0,0,0,0,0,0,0,0,0,0}

	// Se a empresa não usar a opção de preços ajustados por faixa de volumes e prazos ou se for um pedido de Venda do Tipo diferente de Normal
	If lEmpUsrTb .Or. (Type("M->C5_TIPO") <> "U" .And. M->C5_TIPO <> "N")
		Return nXPrcTab := MaTabPrVen(cTabPreco,cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,IIf(Type("lProspect") == "L",lProspect,))
	Endif

	// Se for produto de remessa de vasilhame não passa pela validação pois o preço virá do campo B1_PRV1
	If ("#"+ Alltrim(cProduto)+"#") $ GetNewPar("BF_OM10PRX","#AI1590#AI1591#E15020#")
		Return nXPrcTab := MaTabPrVen(cTabPreco,cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,IIf(Type("lProspect") == "L",lProspect,))
	Endif


	// Avalia se é de CallCenter
	If Type("M->UA_CLIENTE") <> "U"

		aArrTamp	:= U_BFTMKA07(cCliente,cLoja,cProduto,M->UA_REEMB,,,3)
		nValTampa	:= aArrTamp[1]

		nPProd		:= aPosicoes[1][2]			// Produto
		nPQtd     	:= aPosicoes[4][2]			// Quantidade
		nPVrUnit  	:= aPosicoes[5][2]			// Valor unitario
		nPVlrItem 	:= aPosicoes[6][2]			// Valor do item
		nPDesc 		:= aPosicoes[9][2]			// % Desconto
		nPValDesc 	:= aPosicoes[10][2]			// $ Desconto em Valor
		nPTes	    := aPosicoes[11][2]			// Posicao do Tes
		nPPrcTab 	:= aPosicoes[15][2]			// Preço Tabela
		nPAcre 		:= aPosicoes[13][2]			// % Acrescimo
		nPValAcre 	:= aPosicoes[14][2]			// $ Acrescimo em Valor
		nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
		nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
		nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
		nPVlrTampa	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XVLRTAM"})
		nPTpMov		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_OPER"})
		nPItem		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})
		nPxComis1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS1"})
		nPxComis2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS2"})
		nPxUprcVe	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XUPRCVE"})
		nPxFlex		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XFLEX"})
		nPxPrTab1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB1"})
		nPxPrTab2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB2"})
		nPxPrTab3	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB3"})
		nPxPrTab4	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB4"})
		nPxPrTab5	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB5"})
		nPxPrTab6	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRTAB6"})

		// Avalia se o ponto de entrada é chamado pela alteração de quantidade
		If ReadVar() == "M->UB_QUANT"
			lRetPrc	:= .T.
		Endif

		If RetCodUsr() $ GetNewPar("BF_USAVEN3","000000")
			cVend1	:= M->UA_VEND
			cVend2	:= Posicione("SA3",1,xFilial("SA3")+cVend1,"A3_ACESSOR")
		Else
			cVend1	:= M->UA_VEND
			cVend2	:= Posicione("SA3",1,xFilial("SA3")+cVend1,"A3_ACESSOR")
		Endif

		// Se o Vendedor 2 for o próprio vendedor não irá retornar valor de comissão
		If cVend2 == cVend1
			cVend2 := ""
		Endif

		// Regra de preço é somente por cliente, não podendo ser aplicada quando for Prospect
		If !lProspect
			DbSelectArea("SA1")
			DbSetOrder(1)
			If MsSeek(xFilial("SA1")+cCliente+cLoja)
				// Verifica se o cliente possui tabela de preços especifica - nos 3 segmentos
				If (SA1->A1_TABELA >= "301" .And. SA1->A1_TABELA <= "3ZZ") .Or.;	// Tabela por cliente Texaco
				(SA1->A1_TABELA >= "401" .And. SA1->A1_TABELA <= "4ZZ") .Or.;	// Tabela por cliente Michelin
				(SA1->A1_TABELA >= "501" .And. SA1->A1_TABELA <= "5ZZ") 	// Tabela por cliente Wynns

					// Retorna apenas o preço posicionado pois a edição está no campo UB_QUANT
					If lRetPrc //.And. !lIsAuto
						nXPrcTab 	:= aCols[n][nPPrcTab]
						RestArea(aAreaOld)
						Return nXPrcTab
					Endif

					// Obtem o preço padrão do Produto indiferente a Regra de negocio
					nXPrcTab := MaTabPrVen(SA1->A1_TABELA,cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,lProspect)
					nXPrcTab := Round(sfPrazo(M->UA_CONDPG,.T. /*lSUA*/,.F./*lSC5*/,nXPrcTab,SB1->B1_PROC,.T./*lPrzDA0*/,SA1->A1_TABELA)[1],TamSX3("UB_VRUNIT")[2])

					nPComis1	:= 0

					If Empty(cVend2)
						nPComis2	:= 0
					Else
						nPComis2	:= 0
					Endif
					DbSelectArea("DA0")
					DbSetOrder(1)
					DbSeek(xFilial("DA0")+SA1->A1_TABELA)

					// Garanto que os preços mínimos e código de tabela tenham sido atribuídos para validações em outros campos
					aCols[n][nPCodTab]	:= SA1->A1_TABELA
					aCols[n][nPPrcMax]	:= Iif(DA0->DA0_XACRES > 0 ,  Round(nXPrcTab * (100 + DA0->DA0_XACRES )/100 ,TamSX3("UB_VRUNIT")[2]), nXPrcTab )
					aCols[n][nPPrcMin]	:= nXPrcTab
					aCols[n][nPVlrTampa]:= aArrTamp[1]
					aCols[n][nPxFlex]	:= aArrTamp[2]
					aCols[n][nPxComis1]	:= nPComis1
					aCols[n][nPxComis2]	:= nPComis2
					// Se houve preço para o item já retorna
					If nXPrcTab > 0
						RestArea(aAreaOld)
						Return nXPrcTab
					Endif
					// Caso o preço esteja zerado na tabela do cliente, continua validação na tabela normal
					If nXPrcTab == 0 .And. !lIsAuto
						MsgAlert("Produto não tem preço cadastrado na Tabela '"+SA1->A1_TABELA+"' que é a tabela de preços para este cliente! ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					Endif
				Endif
			Endif
		Endif


		// Verifica o prazo médio da condição de pagamento
		nPrzCond := sfPrazo(M->UA_CONDPG,.T. /*lSUA*/,.F./*lSC5*/,nXPrcTab,SB1->B1_PROC)[2]

		DbSelectArea("SB1")
		DbSetOrder(1)
		If Dbseek(xFilial("SB1")+cProduto)
			// Retorna apenas o preço posicionado pois a edição está no campo UB_QUANT
			If lRetPrc // .And. !lIsAuto
				nXPrcTab 	:= aCols[n][nPPrcTab]
				RestArea(aAreaOld)
				Return nXPrcTab
			Endif


			Aadd(aRadioTamp,"R$ 0,00 - Sem Pagamento de Tampas")
			Aadd(aAuxRadTam,{0,0,0})


			For iM	:= 1 To IIf(M->UA_REEMB $ "P",6,1) // Se for Padrão Texaco percorre 6 opções de Preço

				aArrVlrTamp	:= U_BFTMKA07(cCliente,cLoja,cProduto,M->UA_REEMB,,cValToChar(iM),3)
				nValTampa	:= aArrVlrTamp[1]
				If nValTampa > 0
					Aadd(aRadioTamp,"R$ "+ Alltrim(Transform(aArrVlrTamp[1],"@E 999,999.99"))+" p/" +SB1->B1_UM + IIf(SB1->B1_PROC =="000468"," - R$ " + Alltrim(Transform(aArrVlrTamp[1]/(Iif(SB1->B1_QTELITS<=0,1,SB1->B1_QTELITS)),"@E 999.99"))+" p/Litro","")  + " + (R$" + Transform(aArrVlrTamp[2],"@E 999.99")+" Custo)")
					Aadd(aAuxRadTam,{iM,aArrVlrTamp[1],aArrVlrTamp[2]})
				Endif
			Next 
			// Se o cliente for Customizado Texaco/Wynn e existir preço para o cliente, já seleciona o valor da tampa
			If M->UA_REEMB $ "W#T#P" .And. Len(aAuxRadTam) > 1
				nRadTamp	:= Len(aAuxRadTam)
			Endif

			nContAux	:= 0

			// Procura pela tabela Padrão do Fornecedor
			For iT := 1 To Len(aDA0xSA2)
				// Concatena lista de tabelas que não deverão ser pesquisadas novamente
				If !Empty(cNotDA0)
					cNotDA0	+= ","
				Endif 
				cNotDA0 += "'"+aDA0xSA2[iT,1]+"'"

				If SB1->B1_PROC == aDA0xSA2[iT,2] .Or. aDA0xSA2[iT,2] == "XXXXXX"
					nXPrcTab := MaTabPrVen(aDA0xSA2[iT,1],cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,lProspect)
					nXPrcTab := Round(sfPrazo(M->UA_CONDPG,.T. /*lSUA*/,.F./*lSC5*/,nXPrcTab,SB1->B1_PROC)[1],TamSX3("UB_VRUNIT")[2])
					If nXPrcTab > 0


						//nXPrcTab += nValTampa

						nPComis1	:= 0 

						If Empty(cVend2)
							nPComis2	:= 0
						Else
							nPComis2	:= 0
						Endif
						Aadd(aRadioPrc,aDA0xSA2[iT,1]+ "   R$"+Alltrim(Transform(nXPrcTab,"@E 999,999.99"))+ "   Comissão "+Alltrim(Transform(IIf(Empty(cVend2),nPComis1,nPComis2) ,"@E 999.99"))+" %")
						Aadd(aRadioAux,{	nXPrcTab,;
						Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("UB_VRUNIT")[2]),;
						Round(nXPrcTab * 3 ,TamSX3("UB_VRUNIT")[2]) ,;
						nPComis1,;
						nPComis2,;
						0,;
						aDA0xSA2[iT,1],;
						aClone(sfVolume(nXPrcTab,aDA0xSA2[iT,1],SB1->B1_CABO))})

						// Posiciona na tabela 
						nRadioPrc	:= Len(aRadioAux)

					Endif
				Endif
			Next


			// Procura pela tabelas especifica 00P - Promoções
			nXPrcTab := MaTabPrVen("00P",cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,lProspect)

			// Concatena lista de tabelas que não deverão ser pesquisadas novamente
			If !Empty(cNotDA0)
				cNotDA0	+= ","
			Endif 
			cNotDA0 += "'00P'"

			If nXPrcTab > 0
				Aadd(aRadioPrc,"00P  R$"+Alltrim(Transform(nXPrcTab,"@E 999,999.99")))
				// Adiciona preço Tabela - Preço Minimo - Preço Máximo
				Aadd(aRadioAux,{	nXPrcTab,; // 	Preço Tabela
				nXPrcTab,; 		//  	Não haverá desconto nem acréscimo neste item
				nXPrcTab,; 		// 		Não haverá acréscimo neste item
				0,;
				0,;
				0,;
				"00P",;
				{nXPrcTab,nXPrcTab,nXPrcTab,nXPrcTab,nXPrcTab,nXPrcTab}})
			Endif



			// Procura por outras tabelas de preços possívelmente cadastradas e liberadas
			cQry := "SELECT DA0_CODTAB"
			cQry += "  FROM "+RetSqlName("DA0")+" DA0"
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND DA0_ATIVO = '1' "
			cQry += "   AND DA0_DATDE <= '"+DTOS(Date())+"' "
			cQry += "   AND (DA0_DATATE = '        ' OR DA0_DATATE >= '"+DTOS(Date())+"') "
			cQry += "   AND DA0_CODTAB NOT BETWEEN '301' AND '3ZZ' "
			cQry += "   AND DA0_CODTAB NOT BETWEEN '401' AND '4ZZ' "
			cQry += "   AND DA0_CODTAB NOT BETWEEN '501' AND '5ZZ' "
			cQry += "   AND DA0_CODTAB NOT IN("+cNotDA0+") "
			cQry += "   AND DA0_FILIAL = '"+xFilial("DA0")+"'"

			TCQUERY cQry NEW ALIAS "QDA0"

			While !Eof()
				nXPrcTab := MaTabPrVen(QDA0->DA0_CODTAB,cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,lProspect)
				nXPrcTab := Round(sfPrazo(M->UA_CONDPG,.T. /*lSUA*/,.F./*lSC5*/,nXPrcTab,SB1->B1_PROC,.T.,QDA0->DA0_CODTAB)[1],TamSX3("UB_VRUNIT")[2])

				If nXPrcTab > 0
					//nXPrcTab += nValTampa

					nPComis1	:= 0

					If Empty(cVend2)
						nPComis2	:= 0
					Else
						nPComis2	:= 0
					Endif

					Aadd(aRadioPrc,QDA0->DA0_CODTAB+"   R$ "+Alltrim(Transform(nXPrcTab,"@E 999,999.99"))+ "   Comissão "+Alltrim(Transform(IIf(Empty(cVend2),nPComis1,nPComis2) ,"@E 999.99"))+" %")
					// Adiciona preço Tabela - Preço Minimo - Preço Máximo
					Aadd(aRadioAux,{	nXPrcTab,; // 	Preço Tabela
					Iif(QDA0->DA0_CODTAB $"M01#M02#M03#M04#F01/F02/F03",nXPrcTab,Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("UB_VRUNIT")[2])),;
					Iif(QDA0->DA0_CODTAB $"F01/F02/F03",nXPrcTab,Round(nXPrcTab * 3 ,TamSX3("UB_VRUNIT")[2])),;
					nPComis1,;
					nPComis2,;
					0,;
					QDA0->DA0_CODTAB,;
					aClone(sfVolume(nXPrcTab,QDA0->DA0_CODTAB,SB1->B1_CABO))})

					// Posiciona na tabela 
					nRadioPrc	:= Len(aRadioAux)

				Endif
				DbSelectArea("QDA0")
				QDA0->(DbSkip())
			Enddo
			QDA0->(DbCloseArea())

			If !lIsAuto .And. Len(aRadioPrc) > 0
				// Zero o Preço, forçando uma escolha
				nXPrcTab 	:= 0
				aItems		:= {}

				cQry := ""
				cQry += "SELECT D2_DOC,D2_SERIE,D2_EMISSAO,D2_QUANT,D2_PRCVEN,D2_CF,D2_VALPROM "
				cQry += "  FROM "+RetSqlName("SD2") + " D2, " + RetSqlName("SF4") + " F4 "
				cQry += " WHERE F4.D_E_L_E_T_ = ' ' "
				cQry += "   AND F4_DUPLIC = 'S' "
				cQry += "   AND F4_ESTOQUE = 'S' "
				cQry += "   AND F4_CODIGO = D2_TES "
				cQry += "   AND F4_FILIAL = '"+xFilial("SF4") + "' "
				cQry += "   AND D2.D_E_L_E_T_ =' ' "
				cQry += "   AND D2_EMISSAO >= '"+DTOS(Date()-180)+"' "						
				cQry += "   AND D2_COD = '"+cProduto+"' "
				cQry += "   AND D2_CLIENTE = '"+cCliente+"' "
				cQry += "   AND D2_LOJA = '"+cLoja+"' "
				cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
				cQry += " ORDER BY D2_EMISSAO DESC,D2_DOC DESC "

				TCQUERY cQry NEW ALIAS "QSD2"

				While !Eof()
					Aadd(aItems,{;
					QSD2->D2_SERIE+"/"+QSD2->D2_DOC,;
					DTOC(STOD(QSD2->D2_EMISSAO)),;
					QSD2->D2_QUANT,;
					QSD2->D2_PRCVEN,;
					QSD2->D2_VALPROM/QSD2->D2_QUANT,;
					(QSD2->D2_VALPROM/QSD2->D2_QUANT)/(Iif(SB1->B1_QTELITS <= 0,1,SB1->B1_QTELITS)),;
					QSD2->D2_CF})
					QSD2->(DbSkip())
				Enddo
				QSD2->(DbCloseArea())

				// Se não houve adição de dados, monta linha em branco
				If Len(aItems) == 0
					Aadd(aItems,{;
					"/",;
					"  /  /   ",;
					0,;
					0,;
					0,;
					0,;
					" "})
				Endif
				cCSS:= "QTableView{ alternate-background-color: LightSkyBlue; background: white; selection-background-color: #669966 }"

				// configura pintura do Header da TGrid
				cCSS+= "QHeaderView::section { background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #616161, stop: 0.5 #505050, stop: 0.6 #434343,  stop:1 #656565); color: white; padding-left: 4px; border: 1px solid #6c6c6c; }"

				aHeadData	:= {}

				Aadd(aHeadData,{"Série/Nota"	, 80 , CONTROL_ALIGN_LEFT })
				Aadd(aHeadData,{"Emissão"		, 100, CONTROL_ALIGN_CENTER })
				Aadd(aHeadData,{"Quantidade"	, 100, CONTROL_ALIGN_RIGHT ,"@E 999,999.99"} )
				Aadd(aHeadData,{"Preço Unitário", 100, CONTROL_ALIGN_RIGHT ,"@E 999,999.99"} )
				Aadd(aHeadData,{"R$ Tampa"      , 100, CONTROL_ALIGN_RIGHT ,"@E 999,999.99"} )
				Aadd(aHeadData,{"R$ Tampa p/Litro", 100, CONTROL_ALIGN_RIGHT ,"@E 9,999.99"} )
				Aadd(aHeadData,{"CFOP"			, 50, CONTROL_ALIGN_RIGHT } )

				
				DEFINE MSDIALOG oDlgPrc Title OemToAnsi("Selecione um Preço de Tabela para este produto") FROM 001,001 TO 550,680 PIXEL

				//@ 20,10 RADIO oRadio Var nRadioPrc Items aRadioPrc Size 80,20 Of oDlgPrc Pixel
				//   oOrigem := TRadMenu():New(30,10,aOrigem,BSetGet(nOrigem),oPanel,,,,,,,,100,8,,,,.T.)
				oPanel2 := TPanel():New(0,0,'',oDlgPrc, oDlgPrc:oFont, .T., .T.,, ,200,140,.T.,.T. )
				oPanel2:Align := CONTROL_ALIGN_TOP

				oPanel3 := TPanel():New(0,0,'',oDlgPrc, oDlgPrc:oFont, .T., .T.,, ,200,120,.T.,.T. )
				oPanel3:Align := CONTROL_ALIGN_ALLCLIENT

				@ 003,010 Say "Preço Desejado" Of oPanel2 Pixel
				@ 002,060 MsGet oSimulaPrc 	Var nSimulaPrc Valid sfSimulaPrc(2) Picture "@E 999,999.99" Of oPanel2 SIZE 45,11 Pixel



				@ 125,010 Button oBtnOk PROMPT "Confirma" Size 40,10 Action( lOkRadMenu := .T.,oDlgPrc:End() ) Of oPanel2 Pixel
				@ 125,060 Button oBtnCanc PROMPT "Cancela" Size 40,10 Action( oDlgPrc:End()) Of oPanel2 Pixel

				@ 015,010 Say "Preço Tabela" Of oPanel2 Pixel
				oRadio:= tRadMenu():New(025,10,aRadioPrc,BSetGet(nRadioPrc),oPanel2  ,,{|| sfRefMinMax(3) },,,,,,100,70,,,,.T.)

				
				@ 005,150 Say "Preço Tampa" Of oPanel2 Pixel
				oRadTamp	:= tRadMenu():New(015,150,aRadioTamp,BSetGet(nRadTamp),oPanel2  ,,{|| sfRefMinMax(2) },,,,,,180,70,,,,.T.)


				@ 076,010 Say "1ª Faixa Volume" Of oPanel2 Pixel
				@ 084,010 MsGet oPrTab1 Var aTotRdpe[1]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,010 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,010 MsGet oPrcMin1 Var aTotRdpe[2]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,060 Say "2ª Faixa Volume" Of oPanel2 Pixel
				@ 084,060 MsGet oPrTab2 Var aTotRdpe[3]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,060 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,060 MsGet oPrcMin2 Var aTotRdpe[4]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,110 Say "3ª Faixa Volume" Of oPanel2 Pixel
				@ 084,110 MsGet oPrTab3 Var aTotRdpe[5]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,110 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,110 MsGet oPrcMin3 Var aTotRdpe[6]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,160 Say "4ª Faixa Volume" Of oPanel2 Pixel
				@ 084,160 MsGet oPrTab4 Var aTotRdpe[7]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,160 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,160 MsGet oPrcMin4 Var aTotRdpe[8]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,210 Say "5ª Faixa Volume" Of oPanel2 Pixel
				@ 084,210 MsGet oPrTab5 Var aTotRdpe[9]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,210 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,210 MsGet oPrcMin5 Var aTotRdpe[10]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,260 Say "6ª Faixa Volume" Of oPanel2 Pixel
				@ 084,260 MsGet oPrTab6 Var aTotRdpe[11]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,260 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,260 MsGet oPrcMin6 Var aTotRdpe[12]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel


				oGrid2 := BFCFGM20():New(oPanel3,aItems,aHeadData)
				//oGrid:SetFreeze(0)
				oGrid2:SetCSS(cCSS)

				// Forço atualização dos Get´s

				sfRefMinMax(1)

				//oRadio:bChange := {|| ChgCtrl(nRadCh,oGet3,oSay6)}
				ACTIVATE MsDialog oDlgPrc Centered

				If lOkRadMenu
					nXPrcTab 			:= aRadioAux[nRadioPrc,1]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
					aCols[n][nPCodTab]	:= Substr(aRadioPrc[nRadioPrc],1,3)
					aCols[n][nPPrcMax]	:= aRadioAux[nRadioPrc,3]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
					aCols[n][nPPrcMin]	:= aRadioAux[nRadioPrc,2]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
					aCols[n][nPVlrTampa]:= aAuxRadTam[nRadTamp][2] 					 // U_BFTMKA07(cCliente,cLoja,cProduto) // Localiza preço de tampa
					aCols[n][nPxFlex]	:= aAuxRadTam[nRadTamp][3]
					aCols[n][nPxComis1]	:= aRadioAux[nRadioPrc,4]
					aCols[n][nPxComis2]	:= aRadioAux[nRadioPrc,5]
					aCols[n][nPxUprcVe]	:= nSimulaPrc	//	Atualiza com o preço simulado
					aCols[n][nPxPrTab1]	:= aRadioAux[nRadioPrc,8,1]
					aCols[n][nPxPrTab2]	:= aRadioAux[nRadioPrc,8,2]
					aCols[n][nPxPrTab3]	:= aRadioAux[nRadioPrc,8,3]
					aCols[n][nPxPrTab4]	:= aRadioAux[nRadioPrc,8,4]
					aCols[n][nPxPrTab5]	:= aRadioAux[nRadioPrc,8,5]
					aCols[n][nPxPrTab6]	:= aRadioAux[nRadioPrc,8,6]
				Else
					nXPrcTab := 0
					aCols[n][nPCodTab]	:= " "
					aCols[n][nPPrcMax]	:= 0
					aCols[n][nPPrcMin]	:= 0
					aCols[n][nPVlrTampa]:= 0
					aCols[n][nPxFlex]	:= 0
					aCols[n][nPxComis1]	:= 0
					aCols[n][nPxComis2]	:= 0
					aCols[n][nPxUprcVe]	:= 0
					aCols[n][nPxPrTab1]	:= 0
					aCols[n][nPxPrTab2]	:= 0
					aCols[n][nPxPrTab3]	:= 0
					aCols[n][nPxPrTab4]	:= 0
					aCols[n][nPxPrTab5]	:= 0
					aCols[n][nPxPrTab6]	:= 0
				Endif

				//On Init EnchoiceBar(oDlgPrc,{||nXPrcTab := aRadioAux[nRadioPrc],oDlgPrc:End() },{||nXPrcTab := 0 , oDlgPrc:End()})

			ElseIf lIsAuto .And. Len(aRadioAux) > 0 .And. Type("aXUBPRCVEN") <> "U"
				For iP := 1 To Len(aXUBPRCVEN)
					If aCols[n][nPItem] == aXUBPRCVEN[iP,1] .And. Empty(aXUBPRCVEN[iP,6])//  1-Item 2-Produto 3-Recno DA1 4-Tampa 5-Custo Tampa 6-Regra Bonificação 7-Preço Digitado
						lAddSub	:= .F.
						DbSelectArea("DA1")
						DbGoto(aXUBPRCVEN[iP,3])

						For iZ := 1 To Len(aRadioAux)
							// Melhoria 12/05/2015 - Comparação de preço na Tabela 0AA reduzindo 30% para permitir a inclusão de item quando importação Tablet
							//If (nValTampa+aXUBPRCVEN[iP,2]) >= Iif(lIsAuto .And. Substr(aRadioPrc[iZ],1,3) ="0AA" ,aRadioAux[iZ,2]*0.30,aRadioAux[iZ,2]) // Se preço do Palm for >= ao preço mínimo por tabela - assume faixa
							//	ConOut(aXUBPRCVEN[iP,2])
							//	ConOut(aRadioAux[iZ,2])
							//	ConOut(aRadioAux[iZ,7])
							//	ConOut(DA1->DA1_CODTAB)
							//	ConOut(aCols[n][nPItem])

							// Equipara a tabela do Tablet e também se o preço digitado fica entre o preço minimo e máximo vigente no sistema
							If aRadioAux[iZ,7] == DA1->DA1_CODTAB .And. ;
							(aXUBPRCVEN[iP,2]-aXUBPRCVEN[iP,4]-aXUBPRCVEN[iP,5]) >= aRadioAux[iZ,2] .And.;
							(aXUBPRCVEN[iP,2]-aXUBPRCVEN[iP,4]-aXUBPRCVEN[iP,5]) <= aRadioAux[iZ,3]

								nXPrcTab 				:= aRadioAux[iZ,1]+aXUBPRCVEN[iP,4]+aXUBPRCVEN[iP,5]
								aCols[n][nPCodTab]		:= Substr(aRadioPrc[iZ],1,3)
								aCols[n][nPPrcMax]		:= aRadioAux[iZ,3]+aXUBPRCVEN[iP,4]+aXUBPRCVEN[iP,5]//+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
								aCols[n][nPPrcMin]		:= aRadioAux[iZ,2]+aXUBPRCVEN[iP,4]+aXUBPRCVEN[iP,5]//+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]//-nValTampa
								aCols[n][nPVlrTampa]	:= aXUBPRCVEN[iP,4]//aAuxRadTam[nRadTamp][2]	//nValTampa // Localiza preço de tampa
								aCols[n][nPxFlex]		:= aXUBPRCVEN[iP,5]//aAuxRadTam[nRadTamp][3]
								aCols[n][nPxComis1]		:= aRadioAux[iZ,4]
								aCols[n][nPxComis2]		:= aRadioAux[iZ,5]
								aCols[n][nPxPrTab1]		:= aRadioAux[iZ,8,1]
								aCols[n][nPxPrTab2]		:= aRadioAux[iZ,8,2]
								aCols[n][nPxPrTab3]		:= aRadioAux[iZ,8,3]
								aCols[n][nPxPrTab4]		:= aRadioAux[iZ,8,4]
								aCols[n][nPxPrTab5]		:= aRadioAux[iZ,8,5]
								aCols[n][nPxPrTab6]		:= aRadioAux[iZ,8,6]
								lAddSub	:= .T.
								Exit
							Endif
						Next
						// Se o item não foi adicionado pela rotina anterior, procura simplesmente por qualquer tabela de preço que se enquadre
						If !lAddSub
							For iZ := 1 To Len(aRadioAux)
								// IAGO 13/06/2016 Não considerar 00P na busca.
								If aRadioAux[iZ][7] != "00P"									
									// Melhoria 12/05/2015 - Comparação de preço na Tabela 0AA reduzindo 30% para permitir a inclusão de item quando importação Tablet
									//MemoWrite("/log_sqls/om010prc_"+m->ua_pedpalm+"_"+aRadioAux[iZ,7]+".txt","Erro OM010PRC não adicionou preço de tabela "+ cValTochar(aRadioAux[iZ,1])+" Tamanho aRadioAux "+ cValTochar(Len(aRadioAux)) + " Preço " + cValTochar(aXUBPRCVEN[iP,2]) + " Tampa " + cValTochar(aXUBPRCVEN[iP,4]) + " Custo " + cValToChar(aXUBPRCVEN[iP,5]) )
									//If aXUBPRCVEN[iP,2]-aXUBPRCVEN[iP,4]-aXUBPRCVEN[iP,5] >= Iif(aRadioAux[iZ,7] == "0AA" ,aRadioAux[iZ,2]*0.20,aRadioAux[iZ,2]) // Se preço do Palm for >= ao preço mínimo por tabela - assume faixa
									If aXUBPRCVEN[iP,2]-aXUBPRCVEN[iP,4]-aXUBPRCVEN[iP,5] >= aRadioAux[iZ,2]*0.50 

										nXPrcTab 				:= aRadioAux[iZ,1]+aXUBPRCVEN[iP,4]+aXUBPRCVEN[iP,5]
										aCols[n][nPCodTab]		:= aRadioAux[iZ,7]
										aCols[n][nPPrcMax]		:= aRadioAux[iZ,3]+aXUBPRCVEN[iP,4]+aXUBPRCVEN[iP,5]//+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
										aCols[n][nPPrcMin]		:= aRadioAux[iZ,2]+aXUBPRCVEN[iP,4]+aXUBPRCVEN[iP,5] //+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
										aCols[n][nPVlrTampa]	:= aXUBPRCVEN[iP,4] //aAuxRadTam[nRadTamp][2]	//nValTampa // Localiza preço de tampa
										aCols[n][nPxFlex]		:= aXUBPRCVEN[iP,5] //aAuxRadTam[nRadTamp][3]
										aCols[n][nPxComis1]		:= aRadioAux[iZ,4]
										aCols[n][nPxComis2]		:= aRadioAux[iZ,5]
										aCols[n][nPxPrTab1]		:= aRadioAux[iZ,8,1]
										aCols[n][nPxPrTab2]		:= aRadioAux[iZ,8,2]
										aCols[n][nPxPrTab3]		:= aRadioAux[iZ,8,3]
										aCols[n][nPxPrTab4]		:= aRadioAux[iZ,8,4]
										aCols[n][nPxPrTab5]		:= aRadioAux[iZ,8,5]
										aCols[n][nPxPrTab6]		:= aRadioAux[iZ,8,6]
										lAddSub	:= .T.
										Exit
									Endif
								EndIf
							Next
						Endif		
						If !lAddSub
							MemoWrite("/log_sqls/om010prc_"+m->ua_pedpalm+".txt","Erro OM010PRC não adicionou preço de tabela! Tamanho aRadioAux "+ cValTochar(Len(aRadioAux)) + " Preço " + cValTochar(aXUBPRCVEN[iP,2]) + " Tampa " + cValTochar(aXUBPRCVEN[iP,4]) + " Custo " + cValToChar(aXUBPRCVEN[iP,5]) )
						Endif				
					ElseIf aCols[n][nPItem] == aXUBPRCVEN[iP,1] .And. !Empty(aXUBPRCVEN[iP,6])//  1-Item 2-Produto 3-Recno DA1 4-Tampa 5-Custo Tampa 6-Regra Bonificação
						nXPrcTab	:= aXUBPRCVEN[iP,7]
					Endif
				Next
			Endif
		Endif
	ElseIf Type("M->C5_CLIENTE") <> "U"



		nPProd  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
		nPQtd   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
		nPVrUnit   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
		nPPrcTab   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
		nPVlrItem  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
		nPValDesc  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
		nPDesc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
		nPTpMov		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_OPER"})

		nPCodTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
		nPPrcMax	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMAX"})
		nPPrcMin	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
		nPVlrTampa	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XVLRTAM"})
		nPxFlgTab	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XFLGTAB"})
		nPItem		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
		nPxComis1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_COMIS1"})
		nPxComis2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_COMIS2"})
		nPxUprcVe	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XUPRCVE"})
		nPxFlex		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XFLEX"})
		nPxPrTab1	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB1"})
		nPxPrTab2	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB2"})
		nPxPrTab3	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB3"})
		nPxPrTab4	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB4"})
		nPxPrTab5	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB5"})
		nPxPrTab6	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRTAB6"})

		// Avalia se o ponto de entrada é chamado pela alteração de quantidade
		//If ReadVar() == "M->C6_QTDVEN"
		lRetPrc	:= .T.
		//Endif
		If ReadVar() == "M->C6_PRODUTO"
			lRetPrc	:= .F.
			//MsgAlert("Entrei readvar |" +aCols[n][nPxFlgTab]+"|","Valor nPxFlgTab")
			If aCols[n][nPxFlgTab] == "S"
				nXPrcTab	:= aCols[n][nPPrcTab]
				aCols[n][nPxFlgTab]	:= " "
				RestArea(aAreaOld)
				Return nXPrcTab
			Endif
			aCols[n][nPxFlgTab]	:= "S"
		Endif

		cVend1	:= M->C5_VEND1
		cVend2	:= M->C5_VEND2

		// Se o Vendedor 2 for o próprio vendedor não irá retornar valor de comissão
		If cVend2 == cVend1
			cVend2 := ""
		Endif

		aArrTamp	:= U_BFTMKA07(cCliente,cLoja,cProduto,M->C5_REEMB,,,3)

		// Regra adicionada em 16/01/2013 solicitada por Daniel e Big
		// Verifica faixa de volumes padrão do Cliente
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+cCliente+cLoja)
			// Verifica se o cliente possui tabela de preços especifica - nos 3 segmentos
			If (SA1->A1_TABELA >= "301" .And. SA1->A1_TABELA <= "3ZZ") .Or.;	// Tabela por cliente Texaco
			(SA1->A1_TABELA >= "401" .And. SA1->A1_TABELA <= "4ZZ") .Or.;	// Tabela por cliente Michelin
			(SA1->A1_TABELA >= "501" .And. SA1->A1_TABELA <= "5ZZ") 	// Tabela por cliente Wynns

				// Retorna apenas o preço posicionado pois a edição está no campo c6_qtdven
				If lRetPrc //.And. !lIsAuto
					nXPrcTab 	:= aCols[n][nPPrcTab]
					RestArea(aAreaOld)
					Return nXPrcTab
				Endif

				// Obtem o preço padrão do Produto indiferente a Regra de negocio
				nXPrcTab := MaTabPrVen(SA1->A1_TABELA,cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,)
				nXPrcTab := Round(sfPrazo(M->C5_CONDPAG,.F. /*lSUA*/,.T./*lSC5*/,nXPrcTab,SB1->B1_PROC,.T./*lPrzDA0*/,SA1->A1_TABELA)[1],TamSX3("C6_PRUNIT")[2])

				nPComis1	:= 0

				If Empty(cVend2)
					nPComis2	:= 0
				Else
					nPComis2	:= 0
				Endif
				DbSelectArea("DA0")
				DbSetOrder(1)
				DbSeek(xFilial("DA0")+SA1->A1_TABELA)
				// Garanto que os preços mínimos e código de tabela tenham sido atribuídos para validações em outros campos
				aCols[n][nPCodTab]	:= SA1->A1_TABELA
				aCols[n][nPPrcMax]	:= Iif(DA0->DA0_XACRES > 0 ,  Round(nXPrcTab * (100 + DA0->DA0_XACRES ) /100 ,TamSX3("UB_VRUNIT")[2]), nXPrcTab )
				aCols[n][nPPrcMin]	:= nXPrcTab
				aCols[n][nPVlrTampa]:= aArrTamp[1]
				aCols[n][nPxFlex]	:= aArrTamp[2]
				aCols[n][nPxComis1]	:= nPComis1
				aCols[n][nPxComis2]	:= nPComis2

				// Se houve preço para o item já retorna
				If nXPrcTab > 0
					RestArea(aAreaOld)
					Return nXPrcTab
				Endif
				// Caso não tenha preço exibe alerta e continuará buscando das tabelas normais
				If nXPrcTab == 0 .And. !lIsAuto .And. !IsInCallStack("U_WEBIMPPD")
					MsgAlert("Produto não tem preço cadastrado na Tabela '"+SA1->A1_TABELA+"' que é a tabela de preços para este cliente! ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				Endif
			Endif
		Endif

		// Verifica o prazo médio da condição de pagamento
		nPrzCond := sfPrazo(M->C5_CONDPAG,.F. /*lSUA*/,.T./*lSC5*/,nXPrcTab,SB1->B1_PROC)[2]

		DbSelectArea("SB1")
		DbSetOrder(1)
		If Dbseek(xFilial("SB1")+cProduto)
			// Retorna apenas o preço posicionado pois a edição está no campo c6_qtdven
			If lRetPrc // .And. !lIsAuto
				nXPrcTab 	:= aCols[n][nPPrcTab]
				RestArea(aAreaOld)
				Return nXPrcTab
			Endif

			Aadd(aRadioTamp,"R$ 0,00 - Sem Pagamento de Tampas")
			Aadd(aAuxRadTam,{0,0,0})


			For iM	:= 1 To IIf(M->C5_REEMB $ "P",6,1) // Se for Padrão Texaco percorre 6 opções de Preço				

				aArrVlrTamp	:= U_BFTMKA07(cCliente,cLoja,cProduto,M->C5_REEMB,,cValToChar(iM),3)
				nValTampa	:= aArrVlrTamp[1]
				If nValTampa > 0
					Aadd(aRadioTamp,"R$ "+ Alltrim(Transform(aArrVlrTamp[1],"@E 999,999.99"))+" p/" +SB1->B1_UM + IIf(SB1->B1_PROC =="000468"," - R$ " + Alltrim(Transform(aArrVlrTamp[1]/(Iif(SB1->B1_QTELITS<=0,1,SB1->B1_QTELITS)),"@E 999.99"))+" p/Litro","")  + " + (R$" + Transform(aArrVlrTamp[2],"@E 999.99")+" Custo)")
					Aadd(aAuxRadTam,{iM,aArrVlrTamp[1],aArrVlrTamp[2]})
				Endif
			Next 

			// Se o cliente for Customizado Texaco/Wynn e existir preço para o cliente, já seleciona o valor da tampa
			If M->C5_REEMB $ "W#T" .And. Len(aAuxRadTam) > 1
				nRadTamp	:= Len(aAuxRadTam)
			Endif


			// Procura pela tabela Padrão do Fornecedor
			For iT := 1 To Len(aDA0xSA2)
				// Concatena lista de tabelas que não deverão ser pesquisadas novamente
				If !Empty(cNotDA0)
					cNotDA0	+= ","
				Endif 
				cNotDA0 += "'"+aDA0xSA2[iT,1]+"'"

				If SB1->B1_PROC == aDA0xSA2[iT,2] .Or. aDA0xSA2[iT,2] == "XXXXXX"
					nXPrcTab 	:= MaTabPrVen(aDA0xSA2[iT,1],cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,)
					nXPrcTab 	:= Round(sfPrazo(M->C5_CONDPAG,.F. /*lSUA*/,.T./*lSC5*/,nXPrcTab,SB1->B1_PROC)[1],TamSX3("C6_PRUNIT")[2])
					If nXPrcTab > 0

						//nXPrcTab 	+= nValTampa

						nPComis1	:= 0

						If Empty(cVend2)
							nPComis2	:= 0
						Else
							nPComis2	:= 0
						Endif

						Aadd(aRadioPrc,aDA0xSA2[iT,1]+ "   R$"+Alltrim(Transform(nXPrcTab,"@E 999,999.99"))+ "   Comissão "+Alltrim(Transform(IIf(Empty(cVend2),nPComis1,nPComis2) ,"@E 999.99"))+" %")
						Aadd(aRadioAux,{	nXPrcTab,;
						Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("C6_PRUNIT")[2]),;
						Round(nXPrcTab * 3,TamSX3("C6_PRUNIT")[2]),;
						nPComis1,;
						nPComis2,;
						0,;
						aDA0xSA2[iT,1],;
						aClone(sfVolume(nXPrcTab,aDA0xSA2[iT,1],SB1->B1_CABO))})
						// Posiciona na tabela 
						nRadioPrc	:= Len(aRadioAux)
					Endif
				Endif
			Next

			// Procura pela tabelas especifica 00P - Promoções
			nXPrcTab := MaTabPrVen("00P",cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,)

			// Concatena lista de tabelas que não deverão ser pesquisadas novamente
			If !Empty(cNotDA0)
				cNotDA0	+= ","
			Endif 
			cNotDA0 += "'00P'"

			If nXPrcTab > 0
				Aadd(aRadioPrc,"00P  R$"+Alltrim(Transform(nXPrcTab,"@E 999,999.99")))
				// Adiciona preço Tabela - Preço Minimo - Preço Máximo
				Aadd(aRadioAux,{	nXPrcTab,; // 	Preço Tabela
				nXPrcTab,; 		//
				nXPrcTab,; 		// 		Não haverá acréscimo neste item
				0,;
				0,;
				0,;
				"00P",;
				{nXPrcTab,nXPrcTab,nXPrcTab,nXPrcTab,nXPrcTab,nXPrcTab}})
			Endif


			// Procura por outras tabelas de preços possívelmente cadastradas e liberadas
			cQry := "SELECT DA0_CODTAB"
			cQry += "  FROM "+RetSqlName("DA0")+" "
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND DA0_ATIVO = '1' "
			cQry += "   AND DA0_DATDE <= '"+DTOS(Date())+"' "
			cQry += "   AND (DA0_DATATE = '        ' OR DA0_DATATE >= '"+DTOS(Date())+"') "
			cQry += "   AND DA0_CODTAB NOT BETWEEN '301' AND '3ZZ' "
			cQry += "   AND DA0_CODTAB NOT BETWEEN '401' AND '4ZZ' "
			cQry += "   AND DA0_CODTAB NOT BETWEEN '501' AND '5ZZ' "
			cQry += "   AND DA0_CODTAB NOT IN("+cNotDA0+") "
			cQry += "   AND DA0_FILIAL = '"+xFilial("DA0")+"'"


			TCQUERY cQry NEW ALIAS "QDA0"

			While !Eof()
				nXPrcTab := MaTabPrVen(QDA0->DA0_CODTAB,cProduto,nQtde,cCliente,cLoja,nMoeda,dDataVld,nTipo,.F. /*lExec*/,,)
				nXPrcTab := Round(sfPrazo(M->C5_CONDPAG,.F. /*lSUA*/,.T./*lSC5*/,nXPrcTab,SB1->B1_PROC,.T.,QDA0->DA0_CODTAB)[1],TamSX3("C6_PRUNIT")[2])
				If nXPrcTab > 0

					//nXPrcTab += nValTampa

					nPComis1	:= 0

					If Empty(cVend2)
						nPComis2	:= 0
					Else
						nPComis2	:= 0
					Endif

					Aadd(aRadioPrc,QDA0->DA0_CODTAB+"   R$"+Alltrim(Transform(nXPrcTab,"@E 999,999.99"))+ "   Comissão "+Alltrim(Transform(IIf(Empty(cVend2),nPComis1,nPComis2) ,"@E 999.99"))+" %")
					// Adiciona preço Tabela - Preço Minimo - Preço Máximo
					Aadd(aRadioAux,{	nXPrcTab,; // 	Preço Tabela
					Iif(QDA0->DA0_CODTAB $"M01#M02#M03#M04#F01/F02/F03",nXPrcTab,Round(nXPrcTab * (100-SB1->B1_DESCMAX)/100,TamSX3("C6_PRUNIT")[2])),;
					Iif(QDA0->DA0_CODTAB $"F01/F02/F03",nXPrcTab,Round(nXPrcTab * 3,TamSX3("C6_PRUNIT")[2])),;
					nPComis1,;
					nPComis2,;
					0,;
					QDA0->DA0_CODTAB,;
					aClone(sfVolume(nXPrcTab,QDA0->DA0_CODTAB,SB1->B1_CABO))})
					// Posiciona na tabela 
					nRadioPrc	:= Len(aRadioAux)
				Endif
				DbSelectArea("QDA0")
				QDA0->(DbSkip())
			Enddo
			QDA0->(DbCloseArea())

			If !lIsAuto .And. Len(aRadioPrc) > 0
				// Zero o Preço, forçando uma escolha
				nXPrcTab 	:= 0
				aItems		:= {}

				cQry := ""
				cQry += "SELECT D2_DOC,D2_SERIE,D2_EMISSAO,D2_QUANT,D2_PRCVEN,D2_CF,D2_VALPROM "
				cQry += "  FROM "+RetSqlName("SD2") + " D2, " + RetSqlName("SF4") + " F4 "
				cQry += " WHERE F4.D_E_L_E_T_ = ' ' "
				cQry += "   AND F4_DUPLIC = 'S' "
				cQry += "   AND F4_ESTOQUE = 'S' "
				cQry += "   AND F4_CODIGO = D2_TES "
				cQry += "   AND F4_FILIAL = '"+xFilial("SF4") + "' "
				cQry += "   AND D2.D_E_L_E_T_  = ' ' "
				cQry += "   AND D2_EMISSAO >= '"+DTOS(Date()-180)+"' "				
				cQry += "   AND D2_COD = '"+cProduto+"' "
				cQry += "   AND D2_CLIENTE = '"+cCliente+"' "
				cQry += "   AND D2_LOJA = '"+cLoja+"' "
				cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
				cQry += " ORDER BY D2_EMISSAO DESC,D2_DOC DESC "

				TCQUERY cQry NEW ALIAS "QSD2"

				While !Eof()
					Aadd(aItems,{;
					QSD2->D2_SERIE+"/"+QSD2->D2_DOC,;
					DTOC(STOD(QSD2->D2_EMISSAO)),;
					QSD2->D2_QUANT,;
					QSD2->D2_PRCVEN,;
					QSD2->D2_VALPROM/QSD2->D2_QUANT,;
					(QSD2->D2_VALPROM/QSD2->D2_QUANT)/(Iif(SB1->B1_QTELITS <= 0,1,SB1->B1_QTELITS)),;
					QSD2->D2_CF})
					QSD2->(DbSkip())
				Enddo
				QSD2->(DbCloseArea())

				// Se não houve adição de dados, monta linha em branco
				If Len(aItems) == 0
					Aadd(aItems,{;
					"/",;
					"  /  /   ",;
					0,;
					0,;
					0,;
					0,;
					" "})
				Endif
				cCSS:= "QTableView{ alternate-background-color: LightSkyBlue; background: white; selection-background-color: #669966 }"

				// configura pintura do Header da TGrid
				cCSS+= "QHeaderView::section { background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #616161, stop: 0.5 #505050, stop: 0.6 #434343,  stop:1 #656565); color: white; padding-left: 4px; border: 1px solid #6c6c6c; }"

				aHeadData	:= {}

				Aadd(aHeadData,{"Série/Nota"	, 80 , CONTROL_ALIGN_LEFT })
				Aadd(aHeadData,{"Emissão"		, 100, CONTROL_ALIGN_CENTER })
				Aadd(aHeadData,{"Quantidade"	, 100, CONTROL_ALIGN_RIGHT ,"@E 999,999.99"} )
				Aadd(aHeadData,{"Preço Unitário", 100, CONTROL_ALIGN_RIGHT ,"@E 999,999.99"} )
				Aadd(aHeadData,{"R$ Tampa"      , 100, CONTROL_ALIGN_RIGHT ,"@E 999,999.99"} )
				Aadd(aHeadData,{"R$ Tampa p/Litro", 100, CONTROL_ALIGN_RIGHT ,"@E 9,999.99"} )
				Aadd(aHeadData,{"CFOP"			, 50, CONTROL_ALIGN_RIGHT } )



				DEFINE MSDIALOG oDlgPrc Title OemToAnsi("Selecione um Preço de Tabela para este produto") FROM 001,001 TO 550,680 PIXEL

				//@ 20,10 RADIO oRadio Var nRadioPrc Items aRadioPrc Size 80,20 Of oDlgPrc Pixel
				//   oOrigem := TRadMenu():New(30,10,aOrigem,BSetGet(nOrigem),oPanel,,,,,,,,100,8,,,,.T.)
				oPanel2 := TPanel():New(0,0,'',oDlgPrc, oDlgPrc:oFont, .T., .T.,, ,200,140,.T.,.T. )
				oPanel2:Align := CONTROL_ALIGN_TOP

				oPanel3 := TPanel():New(0,0,'',oDlgPrc, oDlgPrc:oFont, .T., .T.,, ,200,120,.T.,.T. )
				oPanel3:Align := CONTROL_ALIGN_ALLCLIENT

				@ 003,010 Say "Preço Desejado" Of oPanel2 Pixel
				@ 002,060 MsGet oSimulaPrc 	Var nSimulaPrc Valid sfSimulaPrc(2) Picture "@E 999,999.99" Of oPanel2 SIZE 45,11 Pixel

				@ 015,010 Say "Preço Tabela" Of oPanel2 Pixel

				@ 125,010 Button oBtnOk PROMPT "Confirma" Size 40,10 Action( lOkRadMenu := .T.,oDlgPrc:End() ) Of oPanel2 Pixel
				@ 125,060 Button oBtnCanc PROMPT "Cancela" Size 40,10 Action( oDlgPrc:End()) Of oPanel2 Pixel

				@ 015,010 Say "Preço Tabela" Of oPanel2 Pixel
				oRadio:= tRadMenu():New(025,10,aRadioPrc,BSetGet(nRadioPrc),oPanel2  ,,{|| sfRefMinMax(3) },,,,,,100,70,,,,.T.)

				
				@ 005,150 Say "Preço Tampa" Of oPanel2 Pixel
				oRadTamp	:= tRadMenu():New(015,150,aRadioTamp,BSetGet(nRadTamp),oPanel2  ,,{|| sfRefMinMax(2) },,,,,,180,70,,,,.T.)


				@ 076,010 Say "1ª Faixa Volume" Of oPanel2 Pixel
				@ 084,010 MsGet oPrTab1 Var aTotRdpe[1]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,010 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,010 MsGet oPrcMin1 Var aTotRdpe[2]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,060 Say "2ª Faixa Volume" Of oPanel2 Pixel
				@ 084,060 MsGet oPrTab2 Var aTotRdpe[3]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,060 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,060 MsGet oPrcMin2 Var aTotRdpe[4]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,110 Say "3ª Faixa Volume" Of oPanel2 Pixel
				@ 084,110 MsGet oPrTab3 Var aTotRdpe[5]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,110 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,110 MsGet oPrcMin3 Var aTotRdpe[6]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,160 Say "4ª Faixa Volume" Of oPanel2 Pixel
				@ 084,160 MsGet oPrTab4 Var aTotRdpe[7]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,160 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,160 MsGet oPrcMin4 Var aTotRdpe[8]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,210 Say "5ª Faixa Volume" Of oPanel2 Pixel
				@ 084,210 MsGet oPrTab5 Var aTotRdpe[9]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,210 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,210 MsGet oPrcMin5 Var aTotRdpe[10]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 076,260 Say "6ª Faixa Volume" Of oPanel2 Pixel
				@ 084,260 MsGet oPrTab6 Var aTotRdpe[11]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel

				@ 098,260 Say "R$ Mínimo" Of oPanel2 Pixel
				@ 105,260 MsGet oPrcMin6 Var aTotRdpe[12]	Picture "@E 999,999,999.99" Of oPanel2 READONLY SIZE 45 ,11 Pixel


				oGrid2 := BFCFGM20():New(oPanel3,aItems,aHeadData)
				//oGrid:SetFreeze(0)
				oGrid2:SetCSS(cCSS)

				// Forço atualização dos Get´s
				sfRefMinMax(1)

				//oRadio:bChange := {|| ChgCtrl(nRadCh,oGet3,oSay6)}
				ACTIVATE MsDialog oDlgPrc Centered

				If lOkRadMenu
					nXPrcTab 				:= aRadioAux[nRadioPrc,1]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
					aCols[n][nPCodTab]		:= Substr(aRadioPrc[nRadioPrc],1,3)
					aCols[n][nPPrcMax]		:= aRadioAux[nRadioPrc,3]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
					aCols[n][nPPrcMin]		:= aRadioAux[nRadioPrc,2]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
					aCols[n][nPVlrTampa]	:= aAuxRadTam[nRadTamp][2] 					 // U_BFTMKA07(cCliente,cLoja,cProduto) // Localiza preço de tampa
					aCols[n][nPxFlex]		:= aAuxRadTam[nRadTamp][3]
					aCols[n][nPxComis1]		:= aRadioAux[nRadioPrc,4]
					aCols[n][nPxComis2]		:= aRadioAux[nRadioPrc,5]
					aCols[n][nPxUprcVe]		:= nSimulaPrc	//	Atualiza com o preço simulado
					aCols[n][nPxPrTab1]		:= aRadioAux[nRadioPrc,8,1]
					aCols[n][nPxPrTab2]		:= aRadioAux[nRadioPrc,8,2]
					aCols[n][nPxPrTab3]		:= aRadioAux[nRadioPrc,8,3]
					aCols[n][nPxPrTab4]		:= aRadioAux[nRadioPrc,8,4]
					aCols[n][nPxPrTab5]		:= aRadioAux[nRadioPrc,8,5]
					aCols[n][nPxPrTab6]		:= aRadioAux[nRadioPrc,8,6]

				Else
					nXPrcTab := 0
					aCols[n][nPCodTab]	:= " "
					aCols[n][nPPrcMax]	:= 0
					aCols[n][nPPrcMin]	:= 0
					aCols[n][nPVlrTampa]:= 0
					aCols[n][nPxFlex]	:= 0
					aCols[n][nPxComis1]	:= 0
					aCols[n][nPxComis2]	:= 0
					aCols[n][nPxUprcVe]	:= 0
					aCols[n][nPxPrTab1]	:= 0
					aCols[n][nPxPrTab2]	:= 0
					aCols[n][nPxPrTab3]	:= 0
					aCols[n][nPxPrTab4]	:= 0
					aCols[n][nPxPrTab5]	:= 0
					aCols[n][nPxPrTab6]	:= 0


				Endif

				//On Init EnchoiceBar(oDlgPrc,{||nXPrcTab := aRadioAux[nRadioPrc],oDlgPrc:End() },{||nXPrcTab := 0 , oDlgPrc:End()})

			ElseIf lIsAuto .And. Len(aRadioAux) > 0 .And. Type("aXC6PRCVEN") <> "U"


				// IAGO 25/06/2015
				// Ordena array pelo preço, pois o primeiro que encontrar, pega; >>>APENAS AUXILIAR<<<
				ASort(aRadioAux,,,{|x,y|x[2]>y[2]})

				For iP := 1 To Len(aXC6PRCVEN)
					If aCols[n][nPItem] == aXC6PRCVEN[iP,1] .And. Empty(aXC6PRCVEN[iP,6])//  1-Item 2-Produto 3-Recno DA1 4-Tampa 5-Custo Tampa 6-Regra Bonificação 7-Preço Digitado
						lAddSc6	:= .F.
						DbSelectArea("DA1")
						DbGoto(aXC6PRCVEN[iP,3])

						For iZ := 1 To Len(aRadioAux)

							//If (nValTampa+aXC6PRCVEN[iP,2]) >= aRadioAux[iZ,2] .Or. (SB1->B1_BLOQFAT == "P" .And. Substr(aRadioPrc[iZ],1,3) == "00P")  // Se preço do Palm for >= ao preço mínimo por tabela - assume faixa
							// 25/09/2015 - Aceita diferença de até 2 centavos 
							If (aRadioAux[iZ,2] - aXC6PRCVEN[iP,2]) < 0.02 .And. ( aRadioAux[iZ,2] - aXC6PRCVEN[iP,2] ) >= 0
								aRadioAux[iZ,2]	:= aXC6PRCVEN[iP,2]
							Endif
							If aRadioAux[iZ,7] == DA1->DA1_CODTAB
								nXPrcTab 				:= aRadioAux[iZ,1]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]
								aCols[n][nPCodTab]		:= Iif(aXC6PRCVEN[iP,3] > 0 , DA1->DA1_CODTAB,Substr(aRadioPrc[iZ],1,3))
								aCols[n][nPPrcMax]		:= aRadioAux[iZ,3]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]//+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
								aCols[n][nPPrcMin]		:= aRadioAux[iZ,2]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]//aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]//-nValTampa
								aCols[n][nPVlrTampa]	:= aXC6PRCVEN[iP,4] //aAuxRadTam[nRadTamp][2]	//nValTampa // Localiza preço de tampa
								aCols[n][nPxFlex]		:= aXC6PRCVEN[iP,5] //aAuxRadTam[nRadTamp][3]
								aCols[n][nPxComis1]		:= aRadioAux[iZ,4]
								aCols[n][nPxComis2]		:= aRadioAux[iZ,5]
								aCols[n][nPxPrTab1]		:= aRadioAux[iZ,8,1]
								aCols[n][nPxPrTab2]		:= aRadioAux[iZ,8,2]
								aCols[n][nPxPrTab3]		:= aRadioAux[iZ,8,3]
								aCols[n][nPxPrTab4]		:= aRadioAux[iZ,8,4]
								aCols[n][nPxPrTab5]		:= aRadioAux[iZ,8,5]
								aCols[n][nPxPrTab6]		:= aRadioAux[iZ,8,6]

								lAddSc6	:= .T.
								Exit
							Endif
						Next

						If !lAddSc6
							For iZ := 1 To Len(aRadioAux)
								If (aXC6PRCVEN[iP,2]-aXC6PRCVEN[iP,4]-aXC6PRCVEN[iP,5]) >= aRadioAux[iZ,2] .Or. (SB1->B1_BLOQFAT == "P" .And. Substr(aRadioPrc[iZ],1,3) == "00P")  // Se preço do Palm for >= ao preço mínimo por tabela - assume faixa
									nXPrcTab 				:= aRadioAux[iZ,1]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]
									aCols[n][nPCodTab]		:= Substr(aRadioPrc[iZ],1,3)
									aCols[n][nPPrcMax]		:= aRadioAux[iZ,3]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]
									If aXC6PRCVEN[iP,8] <> Nil .And. aXC6PRCVEN[iP,8] == "M"
										aCols[n][nPPrcMin]		:= aXC6PRCVEN[iP,2]
									Else
										aCols[n][nPPrcMin]		:= aRadioAux[iZ,2]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]
									Endif
									aCols[n][nPVlrTampa]	:= aXC6PRCVEN[iP,4]//aAuxRadTam[nRadTamp][2]	//nValTampa // Localiz preço de tampa
									aCols[n][nPxFlex]		:= aXC6PRCVEN[iP,5]//aAuxRadTam[nRadTamp][3]
									aCols[n][nPxComis1]		:= aRadioAux[iZ,4]
									aCols[n][nPxComis2]		:= aRadioAux[iZ,5]
									aCols[n][nPxPrTab1]		:= aRadioAux[iZ,8,1]
									aCols[n][nPxPrTab2]		:= aRadioAux[iZ,8,2]
									aCols[n][nPxPrTab3]		:= aRadioAux[iZ,8,3]
									aCols[n][nPxPrTab4]		:= aRadioAux[iZ,8,4]
									aCols[n][nPxPrTab5]		:= aRadioAux[iZ,8,5]
									aCols[n][nPxPrTab6]		:= aRadioAux[iZ,8,6]

									lAddSc6	:= .T.
									Exit
								Endif
							Next
						Endif

						If !lAddSc6
							MemoWrite("/log_sqls/om010prc_"+m->C5_pedpalm+".txt","Erro OM010PRC não adicionou preço de tabela! Tamanho aRadioAux "+ cValTochar(Len(aRadioAux)) + " Preço " + cValTochar(aXC6PRCVEN[iP,2]) + " Tampa " + cValTochar(aXC6PRCVEN[iP,4]) + " Custo " + cValToChar(aXC6PRCVEN[iP,5]) )

							// 
							If Len(aRadioAux) == 1
								iP	:= 1
								iZ 	:= 1
								nXPrcTab 				:= aRadioAux[iZ,1]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]
								aCols[n][nPCodTab]		:= Substr(aRadioPrc[iZ],1,3)
								aCols[n][nPPrcMax]		:= aRadioAux[iZ,3]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]
								If aXC6PRCVEN[iP,8] <> Nil .And. aXC6PRCVEN[iP,8] == "M"
									aCols[n][nPPrcMin]		:= aXC6PRCVEN[iP,2]
								Else
									aCols[n][nPPrcMin]		:= aRadioAux[iZ,2]+aXC6PRCVEN[iP,4]+aXC6PRCVEN[iP,5]
								Endif
								aCols[n][nPVlrTampa]	:= aXC6PRCVEN[iP,4]//aAuxRadTam[nRadTamp][2]	//nValTampa // Localiz preço de tampa
								aCols[n][nPxFlex]		:= aXC6PRCVEN[iP,5]//aAuxRadTam[nRadTamp][3]
								aCols[n][nPxComis1]		:= aRadioAux[iZ,4]
								aCols[n][nPxComis2]		:= aRadioAux[iZ,5]
								aCols[n][nPxPrTab1]		:= aRadioAux[iZ,8,1]
								aCols[n][nPxPrTab2]		:= aRadioAux[iZ,8,2]
								aCols[n][nPxPrTab3]		:= aRadioAux[iZ,8,3]
								aCols[n][nPxPrTab4]		:= aRadioAux[iZ,8,4]
								aCols[n][nPxPrTab5]		:= aRadioAux[iZ,8,5]
								aCols[n][nPxPrTab6]		:= aRadioAux[iZ,8,6]
								lAddSc6	:= .T.

							Endif 
						Endif
					ElseIf aCols[n][nPItem] == aXC6PRCVEN[iP,1] .And. !Empty(aXC6PRCVEN[iP,6])//  1-Item 2-Produto 3-Recno DA1 4-Tampa 5-Custo Tampa 6-Regra Bonificação
						nXPrcTab	:= aXC6PRCVEN[iP,7]
					Endif
				Next
			Endif
		Endif
	Endif

	RestArea(aAreaOld)

Return nXPrcTab




/*/{Protheus.doc} sfRefMinMax
(Atualiza valores exibidos )
@author MarceloLauschner
@since 25/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function sfRefMinMax(nOpc,nDescMax)

	Default	nOpc		:= 1
	Default nDescMax	:= SB1->B1_DESCMAX

	If aRadioAux[nRadioPrc,7] == "00P" 
		nRadTamp	:= 1
		nDescMax	:= 0
	Endif

	// Se for primeira carga atualiza preço de Venda com preço de tabela e mais o valor por tampa
	If nOpc == 1
		nSimulaPrc	:= aRadioAux[nRadioPrc,1]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
		oSimulaPrc:Refresh()
	// Se Troca de preço de tampa, ajusta faixa de preço conforme preço de venda
	ElseIf nOpc == 2
		sfSimulaPrc(nOpc)
		nSimulaPrc	:= aRadioAux[nRadioPrc,1]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
		oSimulaPrc:Refresh()
	// Opção se alterada a faixa de preço
	ElseIf nOpc == 3
		nSimulaPrc	:= aRadioAux[nRadioPrc,1]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
		oSimulaPrc:Refresh()
	Endif

	aTotRdpe[1]	:= aRadioAux[nRadioPrc,8,1]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	aTotRdpe[2]	:= aRadioAux[nRadioPrc,2]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	
	aTotRdpe[3]	:= aRadioAux[nRadioPrc,8,2]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	aTotRdpe[4]	:= Round( aRadioAux[nRadioPrc,8,2] * (100 - nDescMax ) / 100 , TamSX3("UB_VRUNIT")[2])
	aTotRdpe[4] += aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	
	aTotRdpe[5]	:= aRadioAux[nRadioPrc,8,3]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	aTotRdpe[6]	:= Round( aRadioAux[nRadioPrc,8,3] * (100 - nDescMax ) / 100 , TamSX3("UB_VRUNIT")[2])
	aTotRdpe[6] += aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	
	aTotRdpe[7]	:= aRadioAux[nRadioPrc,8,4]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	aTotRdpe[8]	:= Round( aRadioAux[nRadioPrc,8,4] * (100 - nDescMax ) / 100 , TamSX3("UB_VRUNIT")[2])
	aTotRdpe[8] += aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	
	aTotRdpe[9]	 := aRadioAux[nRadioPrc,8,5]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	aTotRdpe[10] := Round( aRadioAux[nRadioPrc,8,5] * (100 - nDescMax ) / 100 , TamSX3("UB_VRUNIT")[2])
	aTotRdpe[10] += aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	
	aTotRdpe[11] := aRadioAux[nRadioPrc,8,6]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	aTotRdpe[12] := Round( aRadioAux[nRadioPrc,8,6] * (100 - nDescMax ) / 100 , TamSX3("UB_VRUNIT")[2])
	aTotRdpe[12] += aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3]
	

	oPrTab1:Refresh()
	oPrTab2:Refresh()
	oPrTab3:Refresh()
	oPrTab4:Refresh()
	oPrTab5:Refresh()
	oPrTab5:Refresh()
	oPrcMin1:Refresh()
	oPrcMin2:Refresh()
	oPrcMin3:Refresh()
	oPrcMin4:Refresh()
	oPrcMin5:Refresh()
	oPrcMin6:Refresh()

Return


Static Function sfSimulaPrc(nOpc)
	Local	nL 	
	Default	nOpc		:= 1

	// Percorro os preços para forçar a faixa de preço em função do preço simulado
	For nL 	:= 1 To Len(aRadioAux)
		If nOpc == 1
			If (aRadioAux[nL,2]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3] <= nSimulaPrc .And. aRadioAux[nL,3]+aAuxRadTam[nRadTamp][2]+aAuxRadTam[nRadTamp][3] >= nSimulaPrc) .Or.;
			aRadioAux[nL,7] == "0AA"
				nRadioPrc	:= nL
				oRadio:Refresh()
				sfRefMinMax(4)
				Return 
			Endif
		ElseIf nOpc == 2
			If (aRadioAux[nL,2] <= (nSimulaPrc-aAuxRadTam[nRadTamp][2]-aAuxRadTam[nRadTamp][3]) .And. aRadioAux[nL,3] >= (nSimulaPrc-aAuxRadTam[nRadTamp][2]-aAuxRadTam[nRadTamp][3])) .Or.;
			aRadioAux[nL,7] == "0AA"
				nRadioPrc	:= nL
				oRadio:Refresh()
				sfRefMinMax(4)
				Return 
			Endif
		Endif
	Next 

Return 


Function U_BFFATX02(cCond,lSUA,lSC5,nPrcVend,cProcPad,lPrzDA0,cCodTab)

Return sfPrazo(cCond,lSUA,lSC5,nPrcVend,cProcPad,lPrzDA0,cCodTab)

/*/{Protheus.doc} sfPrazo
(Efetua o calculo preço aplicando o prazo médio da condição de pagamento)

@author MarceloLauschner
@since 23/01/2014
@version 1.0

@param cCond, character, (Codigo da condição de pagamento)
@param lSUA, logico, (Oriundo do Callcenter)
@param lSC5, logico, (Oriundo do Faturamento)
@param nPrcVend, numerico, (Preço de tabela)
@param cProcPad, character, (Fornecedor padrão do Produto)
@param lPrzDA0, Logico, (Calcula prazo médio pela Tabela de preços)
@param cCodTab, character, (Codigo da tabela de preços)

@return numero, Valor novo do preço de Tabela

@example
(examples)

@see (links_or_references)
/*/
Static Function sfPrazo(cCond,lSUA,lSC5,nPrcVend,cProcPad,lPrzDA0,cCodTab)

	Local   	aCond   		:= {}
	Local 		nSumPrz			:= 0
	Local		nPrcRetur		:= nPrcVend
	Local		nX,iD 
	Local		lVolDA0			:= .F. 
	Default 	lPrzDA0 		:= .F.
	Default 	cCodTab			:= "300"

	// Data fixa - Callcenter
	If cCond == '999' .And. lSUA
		IF !Empty(M->UA_DATA1)
			AADD(aCond,{M->UA_DATA1,1})
		EndIf
		IF !Empty(M->UA_DATA2)
			AADD(aCond,{M->UA_DATA2,1})
		EndIf
		IF !Empty(M->UA_DATA3)
			AADD(aCond,{M->UA_DATA3,1})
		EndIf
		IF !Empty(M->UA_DATA4)
			AADD(aCond,{M->UA_DATA4,1})
		EndIf
		// Data Fixa - Faturamento
	ElseIf cCond == '999' .And. lSC5
		IF !Empty(M->C5_DATA1)
			AADD(aCond,{M->C5_DATA1,1})
		EndIf
		IF !Empty(M->C5_DATA2)
			AADD(aCond,{M->C5_DATA2,1})
		EndIf
		IF !Empty(M->C5_DATA3)
			AADD(aCond,{M->C5_DATA3,1})
		EndIf
		IF !Empty(M->C5_DATA4)
			AADD(aCond,{M->C5_DATA4,1})
		EndIf
	Else
		// Condição de pagamento geral
		aCond := Condicao(100,cCond,0,dDatabase,0)
	Endif

	// Calcula Prazo médio
	For nX := 1 to Len(aCond)
		nSumPrz 	+= aCond[nX][1] - dDatabase
	Next
	nSumPrz := Round(nSumPrz / Len(aCond),1)

	If cCond == "C01"
		nSumPrz	:= 56
	ElseIf cCond == "C02"
		nSumPrz	:= 28
	ElseIf cCond == "C03"
		nSumPrz	:= 56
	Endif
	// Calcular preço de tabela por prazo se definido campo na DA0
	// Coteudo do campo DA0_XPRZME esperado: {{7,0.98},{14,0.99},{28,1},{35,1.01}}
	// Array com o prazo médio e o percentual a ser considerado em ordem crescente de prazo médio
	DbSelectArea("DA0")
	DbSetOrder(1)
	DbSeek(xFilial("DA0")+cCodTab)
	If DA0->(FieldPos("DA0_XPRZME")) > 0
		aPrzDA0	:= &(DA0->DA0_XPRZME)
		If Type("aPrzDA0") == "A"
			For iD := 1 To Len(aPrzDA0)
				If nSumPrz <= aPrzDA0[iD,1]
					nPrcRetur	:= nPrcVend * aPrzDA0[iD,2]
					lPrzDA0	:= .T.
					Exit
				Endif
			Next
		Endif
	Endif


	If !lPrzDA0
		//07 Dias = -1,5% s/28dd
		//14 Dias = -1,0% s/28dd
		//21 Dias = -0,5% s/28dd
		//28 Dias = 0,0% s/28dd
		//35 Dias = 1,0% s/28dd
		//42 Dias = 2,0% s/28dd
		//49 Dias = 3,0% s/28dd
		//56 Dias = 4,0% s/28dd

		If nSumPrz <= 7
			nPrcRetur 	:= nPrcVend * 0.985
		ElseIf nSumPrz <= 14
			nPrcRetur 	:= nPrcVend * 0.99
		ElseIf nSumPrz <= 21
			nPrcRetur 	:= nPrcVend * 0.995
		ElseIf nSumPrz <= 28
			nPrcRetur 	:= nPrcVend 
		ElseIf nSumPrz <= 35
			nPrcRetur 	:= nPrcVend * 1.01
		ElseIf nSumPrz <= 42
			nPrcRetur 	:= nPrcVend * 1.02
		ElseIf nSumPrz <= 49
			nPrcRetur 	:= nPrcVend * 1.03
		Else
			nPrcRetur 	:= nPrcVend * 1.04
		Endif
	Endif

	nPrcRetur	:= Round(nPrcRetur,2)




Return {nPrcRetur,nSumPrz}


Function U_BFFATX01(nInPrcVend,cCodTab,cInTpPrd,nOpcOut)

Return sfVolume(nInPrcVend,cCodTab,cInTpPrd,nOpcOut)

Static Function sfVolume(nInPrcVend,cCodTab,cInTpPrd,nOpcOut)

	Local		aAreaOld		:= GetArea()
	Local		nPrcReturn		:= 0
	Local		nX,iD 
	Local		lVolDA0			:= .F.
	Local		aPrcReturn		:= {0/*_XPRTAB1*/,0/*_XPRTAB2*/,0/*_XPRTAB3*/,0/*_XPRTAB4*/,0/*_XPRTAB5*/,0/*_XPRTAB6*/} // 6 Preços por faixa de volumes 
	Local		aFxVolRet		:= {}
	Default 	cCodTab			:= "300"
	Default 	cInTpPrd		:= "TEX"
	Default		nOpcOut			:= 1

	// Calcular preço de tabela por volume definido campo na DA0
	// Conteudo do campo DA0_XVOLUM esperado: {{"TEX#ROC#HOU",{5,1},{10,0.99},{20,0.98},{50,0.97},{99999,0.96}},{"MIC",{8,1},{20,0.99},{100,0.98},{99999,0.97}}} 
	// Array com intervalo de volumes ( Qte / 20 )  e o percentual a ser considerado em ordem crescente de volume
	DbSelectArea("DA0")
	DbSetOrder(1)
	DbSeek(xFilial("DA0")+cCodTab)
	If DA0->(FieldPos("DA0_XVOLUM")) > 0
		aVolDA0	:= &(DA0->DA0_XVOLUM)
		If Type("aVolDA0") == "A"
			For iD := 1 To Len(aVolDA0)
				If cInTpPrd $ aVolDA0[iD][1] 
					For nX := 2 To Len(aVolDA0[iD])
						// Se o Tipo de Produto estiver na configuração de volumes
						// TEX = Texaco HOU=Hougton ROC=Roccol MIC=Michelin 
						// Se o número de elementos do vetor da Tabela de preços não for maior que 6 elementos pré definidos
						If iD <= Len(aPrcReturn )
							aPrcReturn[nX-1] 	:= Round(nInPrcVend * aVolDA0[iD,nX,2],2)
							lVolDA0	:= .T.
						Endif
						Aadd(aFxVolRet,aVolDA0[iD,nX,1]) // Monta vetor com valores da faixa de volume {5,10,20,50,9999} 
					Next
				Endif				
			Next
		Endif
	Endif

	If !lVolDA0
		aPrcReturn[1] 	:= Round(nInPrcVend * 1   ,2)
		aPrcReturn[2] 	:= Round(nInPrcVend * 0.99,2)
		aPrcReturn[3] 	:= Round(nInPrcVend * 0.98,2)
		aPrcReturn[4] 	:= Round(nInPrcVend * 0.97,2)
		aPrcReturn[5] 	:= Round(nInPrcVend * 0.96,2)
	Endif

	RestArea(aAreaOld)

	If nOpcOut == 2
		Return aFxVolRet		
	Endif

Return aPrcReturn 


