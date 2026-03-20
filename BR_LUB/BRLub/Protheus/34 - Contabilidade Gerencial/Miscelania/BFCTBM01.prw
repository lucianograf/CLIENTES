#include "totvs.ch"


/*/{Protheus.doc} BFCTBM01
(Função Genérica para devolver Centro de Custo nos lançamentos padronizados conforme o segmento de venda do produto e vendedor)
@type function
@author marce
@since 27/09/2016
@version 1.0
@param cInLP, character, (Descrição do parâmetro)
@param cInAlias, character, (Descrição do parâmetro)
@param cInFornece, character, (Descrição do parâmetro)
@param cInB1Cabo, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCTBM01(cInLP,cInAlias,cInFornece,cInB1Cabo)
	
	//Local		aAreaOld	:= GetArea()
	Local		cCustoRet	:= "101110140007        "
	Default		cInFornece	:= ""	// SB1->B1_PROC = Codigo Fornecedor Padrão
	Default 	cInB1Cabo	:= "" 	// SB1->B1_CABO = Código Segmento de venda do produto TEX/MIC/LUS/ROC/HOU/OUT
	// Segmento vendedor - TX/MI/LL/IN
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	/*
	If cInLP == "610" // LP de Documento de Saida - Inclusao de Documento Itens
		If cInAlias == "SA3"
			// Chamado 6677 - Tratativa de verificar se o produto é Granel
			If SB1->B1_COD $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
				//cCustoRet	:= "101120180001"
				cCustoRet	:= "101810110001"
			Else
				If Empty(cInB1Cabo)
					cInB1Cabo	:= SB1->B1_CABO
				Endif
				DbSelectArea("SF2")
				DbSetOrder(1)
				If DbSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
					DbSelectArea("SA3")
					DbSetOrder(1)
					If DbSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
						cCustoRet	:= SA3->A3_CC
						// Adicionado em 03/06/2013 - Verifica se há fornecedor informado pela chamada do lancamento, se existe o campo e se tem conteudo o Centro Custo auxiliar do vendedor
						If !Empty(cInFornece)
							// Verifica ainda se o codigo do fornecedor pertence ao grupo que irá usar o centro de custo auxiliar
							If cInFornece $ "000473"
								cCustoRet	:= SA3->A3_XCC
							Endif
						Endif
						If !Empty(cInB1Cabo) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
							If SA3->(FieldPos("A3_XCC_CAR")) > 0 .And. !Empty(SA3->A3_XCC_CAR) .And. cInB1Cabo $ "CAR"
								cCustoRet	:= SA3->A3_XCC_CAR
							ElseIf SA3->(FieldPos("A3_XCC_MOT")) > 0 .And. !Empty(SA3->A3_XCC_MOT) .And. cInB1Cabo $ "MOT"
								cCustoRet	:= SA3->A3_XCC_MOT
							ElseIf SA3->(FieldPos("A3_XCC_IPI")) > 0 .And. !Empty(SA3->A3_XCC_IPI) .And. cInB1Cabo $ "IPI"
								cCustoRet	:= SA3->A3_XCC_IPI
							ElseIf SA3->(FieldPos("A3_XCC_CON")) > 0 .And. !Empty(SA3->A3_XCC_CON) .And. cInB1Cabo $ "CON"
								cCustoRet	:= SA3->A3_XCC_CON
							ElseIf cInB1Cabo $ "MIC#CAR#MOT#CON#REL#BIK" // Produto Michelin e CARCARE
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= SA3->A3_XCC
								ElseIf SA3->A3_XSEGEMP == "CO" // Vendedor Continental
									cCustoRet	:= SA3->A3_XCC_CON
								ElseIf SA3->A3_XSEGEMP == "LL" // Vendedor Lust
									cCustoRet	:= Iif(Empty(SA3->A3_XCC),"103220120007" ,SA3->A3_XCC)//
								Endif
							ElseIf cInB1Cabo $ "LUS" // Produto Lust
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= "101610120033"
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif
		Endif
	ElseIf cInLP == "620" // LP de Documento de Saida - Inclusao de Documento Total
		If cInAlias == "SA3"
			DbSelectArea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
				cCustoRet	:= SA3->A3_CC
			Endif
		Endif
	ElseIf cInLP == "678" // LP de Documento de Saida - Custo da Mercadoria Vendida
		If cInAlias == "SA3"
			DbSelectArea("SB1")
			DbSetOrder(1)
			MsSeek(xFilial("SB1")+SD2->D2_COD)
			// Chamado 6677 - Tratativa de verificar se o produto é Granel
			If SB1->B1_COD $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
				//cCustoRet	:= "101120180001"
				cCustoRet	:= "101810110001"
			Else
				If Empty(cInB1Cabo)
					cInB1Cabo	:= SB1->B1_CABO
				Endif
				
				DbSelectArea("SF2")
				DbSetOrder(1)
				If DbSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
					DbSelectArea("SA3")
					DbSetOrder(1)
					If DbSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
						cCustoRet	:= SA3->A3_CC
						// Adicionado em 03/06/2013 - Verifica se há fornecedor informado pela chamada do lancamento, se existe o campo e se tem conteudo o Centro Custo auxiliar do vendedor
						If !Empty(cInFornece) .And. SA3->(FieldPos("A3_XCC")) > 0 .And. !Empty(SA3->A3_XCC)
							// Verifica ainda se o codigo do fornecedor pertence ao grupo que irá usar o centro de custo auxiliar
							If cInFornece $ "000473"
								cCustoRet	:= SA3->A3_XCC
							Endif
						Endif
						If !Empty(cInB1Cabo) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
							If SA3->(FieldPos("A3_XCC_CAR")) > 0 .And. !Empty(SA3->A3_XCC_CAR) .And. cInB1Cabo $ "CAR"
								cCustoRet	:= SA3->A3_XCC_CAR
							ElseIf SA3->(FieldPos("A3_XCC_MOT")) > 0 .And. !Empty(SA3->A3_XCC_MOT) .And. cInB1Cabo $ "MOT"
								cCustoRet	:= SA3->A3_XCC_MOT
							ElseIf SA3->(FieldPos("A3_XCC_IPI")) > 0 .And. !Empty(SA3->A3_XCC_IPI) .And. cInB1Cabo $ "IPI"
								cCustoRet	:= SA3->A3_XCC_IPI
							ElseIf SA3->(FieldPos("A3_XCC_CON")) > 0 .And. !Empty(SA3->A3_XCC_CON) .And. cInB1Cabo $ "CON"
								cCustoRet	:= SA3->A3_XCC_CON
							ElseIf cInB1Cabo $ "MIC#CAR#MOT#CON#REL#BIK" // Produto Michelin e CARCARE
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= SA3->A3_XCC
								ElseIf SA3->A3_XSEGEMP == "CO" // Vendedor Continental
									cCustoRet	:= SA3->A3_XCC_CON
								ElseIf SA3->A3_XSEGEMP == "LL" // Vendedor Lust
									cCustoRet	:= Iif(Empty(SA3->A3_XCC),"103220120007" ,SA3->A3_XCC)
								Endif
							ElseIf cInB1Cabo $ "LUS" // Produto Lust
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= "101610120033"
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif
		Endif
	ElseIf cInLP == "650" // LP de Documento de Entrada - Inclusão de Documento Entrada Itens
		If cInAlias == "SA3" .And. SF1->F1_TIPO == "D" // Devolução de Vendas
			DbSelectArea("SD2")
			DbSetOrder(3)
			If MsSeek(xFilial("SD2")+SD1->D1_NFORI+SD1->D1_SERIORI+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_COD+SD1->D1_ITEMORI)
				DbSelectArea("SB1")
				DbSetOrder(1)
				MsSeek(xFilial("SB1")+SD2->D2_COD)
				cInB1Cabo	:= SB1->B1_CABO
				// Chamado 6677 - Tratativa de verificar se o produto é Granel
				If SB1->B1_COD $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
					//cCustoRet	:= "101120180001"
					cCustoRet	:= "101810110001"
				Else
					DbSelectArea("SF2")
					DbSetOrder(1)
					MsSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
					DbSelectArea("SA3")
					DbSetOrder(1)
					If MsSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
						cCustoRet	:= SA3->A3_CC
						// Adicionado em 03/06/2013 - Verifica se há fornecedor informado pela chamada do lancamento, se existe o campo e se tem conteudo o Centro Custo auxiliar do vendedor
						If !Empty(cInFornece) .And. SA3->(FieldPos("A3_XCC")) > 0 .And. !Empty(SA3->A3_XCC)
							// Verifica ainda se o codigo do fornecedor pertence ao grupo que irá usar o centro de custo auxiliar
							If cInFornece $ "000473"
								cCustoRet	:= SA3->A3_XCC
							Endif
						Endif
						If !Empty(cInB1Cabo) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
							If SA3->(FieldPos("A3_XCC_CAR")) > 0 .And. !Empty(SA3->A3_XCC_CAR) .And. cInB1Cabo $ "CAR"
								cCustoRet	:= SA3->A3_XCC_CAR
							ElseIf SA3->(FieldPos("A3_XCC_MOT")) > 0 .And. !Empty(SA3->A3_XCC_MOT) .And. cInB1Cabo $ "MOT"
								cCustoRet	:= SA3->A3_XCC_MOT
							ElseIf SA3->(FieldPos("A3_XCC_IPI")) > 0 .And. !Empty(SA3->A3_XCC_IPI) .And. cInB1Cabo $ "IPI"
								cCustoRet	:= SA3->A3_XCC_IPI
							ElseIf SA3->(FieldPos("A3_XCC_CON")) > 0 .And. !Empty(SA3->A3_XCC_CON) .And. cInB1Cabo $ "CON"
								cCustoRet	:= SA3->A3_XCC_CON
							ElseIf cInB1Cabo $ "MIC#CAR#MOT#CON#REL#BIK" // Produto Michelin e CARCARE
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= SA3->A3_XCC
								ElseIf SA3->A3_XSEGEMP == "CO" // Vendedor Continental
									cCustoRet	:= SA3->A3_XCC_CON
								ElseIf SA3->A3_XSEGEMP == "LL" // Vendedor Lust
									cCustoRet	:= Iif(Empty(SA3->A3_XCC),"103220120007" ,SA3->A3_XCC)
								Endif
							ElseIf cInB1Cabo $ "LUS" // Produto Lust
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= "101610120033"
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif
		ElseIf cInAlias == "SA3" .And. SF1->F1_TIPO == "C" // Complemento de Preços
			If Alltrim(SF1->F1_ESPECIE) $ "CTE#CTR"
				DbSelectArea("SD2")
				DbSetOrder(3)
				If MsSeek(xFilial("SD2")+SD1->D1_NFORI+SD1->D1_SERIORI+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_COD+SD1->D1_ITEMORI)
					DbSelectArea("SB1")
					DbSetOrder(1)
					MsSeek(xFilial("SB1")+SD2->D2_COD)
					cInB1Cabo	:= SB1->B1_CABO
					// Chamado 6677 - Tratativa de verificar se o produto é Granel
					If SB1->B1_COD $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
						//cCustoRet	:= "101120180001"
						cCustoRet	:= "101810110001"
					Else
						DbSelectArea("SF2")
						DbSetOrder(1)
						MsSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
						DbSelectArea("SA3")
						DbSetOrder(1)
						If MsSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
							cCustoRet	:= SA3->A3_CC
						Endif
						If !Empty(cInB1Cabo) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
							If SA3->(FieldPos("A3_XCC_CAR")) > 0 .And. !Empty(SA3->A3_XCC_CAR) .And. cInB1Cabo $ "CAR"
								cCustoRet	:= SA3->A3_XCC_CAR
							ElseIf SA3->(FieldPos("A3_XCC_MOT")) > 0 .And. !Empty(SA3->A3_XCC_MOT) .And. cInB1Cabo $ "MOT"
								cCustoRet	:= SA3->A3_XCC_MOT
							ElseIf SA3->(FieldPos("A3_XCC_IPI")) > 0 .And. !Empty(SA3->A3_XCC_IPI) .And. cInB1Cabo $ "IPI"
								cCustoRet	:= SA3->A3_XCC_IPI
							ElseIf SA3->(FieldPos("A3_XCC_CON")) > 0 .And. !Empty(SA3->A3_XCC_CON) .And. cInB1Cabo $ "CON"
								cCustoRet	:= SA3->A3_XCC_CON
							ElseIf cInB1Cabo $ "MIC#CAR#MOT#CON#REL#BIK" // Produto Michelin e CARCARE
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= SA3->A3_XCC
								ElseIf SA3->A3_XSEGEMP == "CO" // Vendedor Continental
									cCustoRet	:= SA3->A3_XCC_CON
								ElseIf SA3->A3_XSEGEMP == "LL" // Vendedor Lust
									cCustoRet	:= Iif(Empty(SA3->A3_XCC),"103220120007" ,SA3->A3_XCC)
								Endif
							ElseIf cInB1Cabo $ "LUS" // Produto Lust
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= "101610120033"
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif
		ElseIf cInAlias == "SD1" // Complemento de Preços
			If Alltrim(cEspecie) $ "CTE#CTR"
				DbSelectArea("SD2")
				DbSetOrder(3)
				If MsSeek(xFilial("SD2")+SD1->D1_NFORI+SD1->D1_SERIORI+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_COD+SD1->D1_ITEMORI)
					DbSelectArea("SB1")
					DbSetOrder(1)
					MsSeek(xFilial("SB1")+SD2->D2_COD)
					cInB1Cabo	:= SB1->B1_CABO
					
					// Chamado 6677 - Tratativa de verificar se o produto é Granel
					If SB1->B1_COD $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
						//cCustoRet	:= "101120180001"
						cCustoRet	:= "101810110001"
					Else
						DbSelectArea("SF2")
						DbSetOrder(1)
						MsSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
						DbSelectArea("SA3")
						DbSetOrder(1)
						If MsSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
							cCustoRet	:= SA3->A3_CC
						Endif
						If !Empty(cInB1Cabo) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
							If SA3->(FieldPos("A3_XCC_CAR")) > 0 .And. !Empty(SA3->A3_XCC_CAR) .And. cInB1Cabo $ "CAR"
								cCustoRet	:= SA3->A3_XCC_CAR
							ElseIf SA3->(FieldPos("A3_XCC_MOT")) > 0 .And. !Empty(SA3->A3_XCC_MOT) .And. cInB1Cabo $ "MOT"
								cCustoRet	:= SA3->A3_XCC_MOT
							ElseIf SA3->(FieldPos("A3_XCC_IPI")) > 0 .And. !Empty(SA3->A3_XCC_IPI) .And. cInB1Cabo $ "IPI"
								cCustoRet	:= SA3->A3_XCC_IPI
							ElseIf SA3->(FieldPos("A3_XCC_CON")) > 0 .And. !Empty(SA3->A3_XCC_CON) .And. cInB1Cabo $ "CON"
								cCustoRet	:= SA3->A3_XCC_CON
							ElseIf cInB1Cabo $ "MIC#CAR#MOT#CON#REL#BIK" // Produto Michelin e CARCARE
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= SA3->A3_XCC
								ElseIf SA3->A3_XSEGEMP == "CO" // Vendedor Continental
									cCustoRet	:= SA3->A3_XCC_CON
								ElseIf SA3->A3_XSEGEMP == "LL" // Vendedor Lust
									cCustoRet	:= Iif(Empty(SA3->A3_XCC),"103220120007" ,SA3->A3_XCC)
								Endif
							ElseIf cInB1Cabo $ "LUS" // Produto Lust
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= "101610120033"
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif
			
		Endif
	ElseIf cInLP == "640" // LP de Documento de Entrada - Inclusão de Documento Devolução/Beneficiamento Itens
		If cInAlias == "SA3" .And. SD1->D1_TIPO == "D"
			DbSelectArea("SD2")
			DbSetOrder(3)
			If MsSeek(xFilial("SD2")+SD1->D1_NFORI+SD1->D1_SERIORI+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_COD+SD1->D1_ITEMORI)
				DbSelectArea("SB1")
				DbSetOrder(1)
				MsSeek(xFilial("SB1")+SD2->D2_COD)
				// Chamado 6677 - Tratativa de verificar se o produto é Granel
				If SB1->B1_COD $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
					//cCustoRet	:= "101120180001"
					cCustoRet	:= "101810110001"
				Else
					DbSelectArea("SF2")
					DbSetOrder(1)
					MsSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
					DbSelectArea("SA3")
					DbSetOrder(1)
					If MsSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
						cCustoRet	:= SA3->A3_CC
						// Adicionado em 03/06/2013 - Verifica se há fornecedor informado pela chamada do lancamento, se existe o campo e se tem conteudo o Centro Custo auxiliar do vendedor
						If !Empty(cInFornece) .And. SA3->(FieldPos("A3_XCC")) > 0 .And. !Empty(SA3->A3_XCC)
							// Verifica ainda se o codigo do fornecedor pertence ao grupo que irá usar o centro de custo auxiliar
							If cInFornece $ "000473"
								cCustoRet	:= SA3->A3_XCC
							Endif
						Endif
						If !Empty(cInB1Cabo) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
							If SA3->(FieldPos("A3_XCC_CAR")) > 0 .And. !Empty(SA3->A3_XCC_CAR) .And. cInB1Cabo $ "CAR"
								cCustoRet	:= SA3->A3_XCC_CAR
							ElseIf SA3->(FieldPos("A3_XCC_MOT")) > 0 .And. !Empty(SA3->A3_XCC_MOT) .And. cInB1Cabo $ "MOT"
								cCustoRet	:= SA3->A3_XCC_MOT
							ElseIf SA3->(FieldPos("A3_XCC_IPI")) > 0 .And. !Empty(SA3->A3_XCC_IPI) .And. cInB1Cabo $ "IPI"
								cCustoRet	:= SA3->A3_XCC_IPI
							ElseIf SA3->(FieldPos("A3_XCC_CON")) > 0 .And. !Empty(SA3->A3_XCC_CON) .And. cInB1Cabo $ "CON"
								cCustoRet	:= SA3->A3_XCC_CON
							ElseIf cInB1Cabo $ "MIC#CAR#MOT#CON#REL#BIK" // Produto Michelin e CARCARE
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= SA3->A3_XCC
								ElseIf SA3->A3_XSEGEMP == "CO" // Vendedor Continental
									cCustoRet	:= SA3->A3_XCC_CON
								ElseIf SA3->A3_XSEGEMP == "LL" // Vendedor Lust
									cCustoRet	:= Iif(Empty(SA3->A3_XCC),"103220120007" ,SA3->A3_XCC)
								Endif
							ElseIf cInB1Cabo $ "LUS" // Produto Lust
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= "101610120033"
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif
		Endif
	ElseIf cInLP == "641" // LP de Documento de Entrada - Inclusão de Documento Devolução/Beneficiamento Itens Rateio
		If cInAlias == "SA3"
			DbSelectArea("SD2")
			DbSetOrder(3)
			If MsSeek(xFilial("SD2")+SD1->D1_NFORI+SD1->D1_SERIORI+SD1->D1_FORNECE+SD1->D1_LOJA+SD1->D1_COD+SD1->D1_ITEMORI)
				DbSelectArea("SB1")
				DbSetOrder(1)
				MsSeek(xFilial("SB1")+SD2->D2_COD)
				// Chamado 6677 - Tratativa de verificar se o produto é Granel
				If SB1->B1_COD $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
					//cCustoRet	:= "101120180001"
					cCustoRet	:= "101810110001"
				Else
					DbSelectArea("SF2")
					DbSetOrder(1)
					MsSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
					DbSelectArea("SA3")
					DbSetOrder(1)
					If MsSeek(xFilial("SA3")+SF2->F2_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
						cCustoRet	:= SA3->A3_CC
						// Adicionado em 03/06/2013 - Verifica se há fornecedor informado pela chamada do lancamento, se existe o campo e se tem conteudo o Centro Custo auxiliar do vendedor
						If !Empty(cInFornece) .And. SA3->(FieldPos("A3_XCC")) > 0 .And. !Empty(SA3->A3_XCC)
							// Verifica ainda se o codigo do fornecedor pertence ao grupo que irá usar o centro de custo auxiliar
							If cInFornece $ "000473"
								cCustoRet	:= SA3->A3_XCC
							Endif
						Endif
						If !Empty(cInB1Cabo) .And. SA3->(FieldPos("A3_XSEGEMP")) > 0
							If SA3->(FieldPos("A3_XCC_CAR")) > 0 .And. !Empty(SA3->A3_XCC_CAR) .And. cInB1Cabo $ "CAR"
								cCustoRet	:= SA3->A3_XCC_CAR
							ElseIf SA3->(FieldPos("A3_XCC_MOT")) > 0 .And. !Empty(SA3->A3_XCC_MOT) .And. cInB1Cabo $ "MOT"
								cCustoRet	:= SA3->A3_XCC_MOT
							ElseIf SA3->(FieldPos("A3_XCC_IPI")) > 0 .And. !Empty(SA3->A3_XCC_IPI) .And. cInB1Cabo $ "IPI"
								cCustoRet	:= SA3->A3_XCC_IPI
							ElseIf SA3->(FieldPos("A3_XCC_CON")) > 0 .And. !Empty(SA3->A3_XCC_CON) .And. cInB1Cabo $ "CON"
								cCustoRet	:= SA3->A3_XCC_CON
							ElseIf cInB1Cabo $ "MIC#CAR#MOT#CON#REL#BIK" // Produto Michelin e CARCARE
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= SA3->A3_XCC
								ElseIf SA3->A3_XSEGEMP == "CO" // Vendedor Continental
									cCustoRet	:= SA3->A3_XCC_CON
								ElseIf SA3->A3_XSEGEMP == "LL" // Vendedor Lust
									cCustoRet	:= Iif(Empty(SA3->A3_XCC),"103220120007" ,SA3->A3_XCC)
								Endif
							ElseIf cInB1Cabo $ "LUS" // Produto Lust
								If SA3->A3_XSEGEMP == "MI" // Vendedor Michelin
									cCustoRet	:= "101610120033"
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif
		Endif
	ElseIf cInLP == "523" // LP de Contas a Receber - Baixas de Titulos Cobranca Caucionada
		If cInAlias == "SA3"
			DbSelectArea("SA3")
			DbSetOrder(1)
			If MsSeek(xFilial("SA3")+SE1->E1_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
				cCustoRet	:= SA3->A3_CC
			Endif
		Endif
	ElseIf cInLP == "520" // LP de Contas a Receber - Baixas de Titulos em Carteira
		If cInAlias == "SA3"
			DbSelectArea("SA3")
			DbSetOrder(1)
			If MsSeek(xFilial("SA3")+SE1->E1_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
				cCustoRet	:= SA3->A3_CC
			Endif
		Endif
	ElseIf cInLP == "521" // LP de Contas a Receber - Baixas de Titulos Cobrança Simples
		If cInAlias == "SA3"
			DbSelectArea("SA3")
			DbSetOrder(1)
			If MsSeek(xFilial("SA3")+SE1->E1_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
				cCustoRet	:= SA3->A3_CC
			Endif
		Endif
	ElseIf cInLP == "527" // LP de Contas a Receber - Cancelamento de Baixas de Titulos
		If cInAlias == "SA3"
			DbSelectArea("SA3")
			DbSetOrder(1)
			If MsSeek(xFilial("SA3")+SE1->E1_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
				cCustoRet	:= SA3->A3_CC
			Endif
		Endif
	ElseIf cInLP == "596" // LP de Contas a Receber - Compensação Contas a Receber
		If cInAlias == "SA3"
			DbSelectArea("SA3")
			DbSetOrder(1)
			If MsSeek(xFilial("SA3")+SE1->E1_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
				cCustoRet	:= SA3->A3_CC
			Endif
		Endif
	ElseIf cInLP == "588" // LP de Contas a Receber - Estorno de Compensação Contas a Receber
		If cInAlias == "SA3"
			DbSelectArea("SA3")
			DbSetOrder(1)
			If MsSeek(xFilial("SA3")+SE1->E1_VEND1) .And. SA3->(FieldPos("A3_CC")) > 0
				cCustoRet	:= SA3->A3_CC
			Endif
		Endif
	Endif
	
	RestArea(aAreaOld)
	*/
	// Fixado inicialmente para conseguir finalizar contabilização
	cCustoRet := "00"
Return cCustoRet
