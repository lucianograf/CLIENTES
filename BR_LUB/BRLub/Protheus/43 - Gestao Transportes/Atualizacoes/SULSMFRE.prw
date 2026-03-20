#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWEVENTVIEWCONSTS.CH"
#INCLUDE "FWADAPTEREAI.CH"

#DEFINE __UFORI  01
#DEFINE __ALQORI 02
#DEFINE __PROPOR 03

#DEFINE SMMARCA	   1
#DEFINE SMCODTRAN  2
#DEFINE SMNOMETRAN 3
#DEFINE SMVALOR    4
#DEFINE SMPRAZO    5

#DEFINE SMEHXROTA  6
#DEFINE SMXROTA    7
#DEFINE SMEXISTMP  8
#DEFINE SMDATA     9
//             1,2          ,3           ,4      ,5       ,6      ,7      ,8  ,9      
//aAdd (aRet, { ,SA4->A4_COD,SA4->A4_NOME,nVlrFrt,nPrevEnt,lEhRota,cEhRota,.T.,dDataEnt})

User Function SULSMFRE(cInAlias,nInRecno,nOpcX,nInOpc,cCodTransX,nVGfeVlrOut)

	Local aArea 		:= GetArea()
	Local oModelSim  	:= FWLoadModel("GFEX010")
	Local oModelNeg  	:= oModelSim:GetModel("GFEX010_01")
	Local oModelAgr  	:= oModelSim:GetModel("DETAIL_01")  // oModel do grid "Agrupadores"
	Local oModelDC   	:= oModelSim:GetModel("DETAIL_02")  // oModel do grid "Doc Carga"
	Local oModelIt   	:= oModelSim:GetModel("DETAIL_03")  // oModel do grid "Item Carga"
	Local oModelTr   	:= oModelSim:GetModel("DETAIL_04")  // oModel do grid "Trechos"
	Local oModelInt  	:= oModelSim:GetModel("SIMULA")     // oModel do field que dispara a simulaÃ¨Â±Â«o
	Local oModelCal1 	:= oModelSim:GetModel("DETAIL_05")  // oModel do calculo do frete
	Local oModelCal2 	:= oModelSim:GetModel("DETAIL_06")  // oModel das informaÃ¥Â¯Â¤es complemetares do calculo
	Local nCont      	:= 0
	Local cCdClFr		:= "" //-- simulacao de frete: considerar todas a negociacoes cadastradas no GFE.
	Local cTpOp			:= "" //-- simulacao de frete: considerar todas a negociacoes cadastradas no GFE.
	Local cTpDoc		:= ''
	Local nItem			:= 0
	Local cCGCTran		:= ''
	Local nVlrFrt		:= 0
	Local nPrevEnt		:= 0
	Local aRet			:= {}
	Local nNumCalc		:= 0
	Local nClassFret	:= 0
	Local nTipOper		:= 0
	Local cTrecho		:= ""
	Local cTabela		:= ""
	Local cNumNegoc		:= ""
	Local cRota			:= ""
	Local dDatValid		:= ""
	Local cFaixa		:= ""
	Local cTipoVei		:= ""
	Local cEhRota		:= ""
	Local lEhRota		:= .F.
	Local cCgc := ''
	Local nAltura		:= 0
	Local nVolume		:= 0
	Local cRadio		:= "2" // 1=Considera Tab.Frete em Negociacao; 2=Considera apenas Tab.Frete Aprovadas
	Local cCodCli
	Local cLojCli
	Local cNumPed
	Local cTipoPed
	Local cTpFrete 
	Local cNuCidOr
	Local cAliasRota
	Local nPxItem
	Local nPxProduto
	Local nPxQtdVen
	Local nPxPrcVen
	Local nPxValor
	Local nI
	Local lBkAltera 	:= Iif(Type("ALTERA")=="L",ALTERA,.F.)
	Local lBkInclui 	:= Iif(Type("INCLUI")=="L",INCLUI,.F.)
	Local lMvTpFrete	:= SuperGetMV("MV_XGFETIP",.F.,.T.) // Tipo do frete na simulação do pedido, .T.=Valor .F.=Prazo

	Default cCodTransX	:= Space(6)
	Default nInOpc		:= 0
	Default nVGfeVlrOut	:= 0
	Private lIsGfeOn 	:= GetNewPar("BF_GFEAVLR",.F.) // Criar o parâmetro para ativar alteração de transportadora e retornar valor de frete para função BFFATM22
	Private lAtuGfeTr 	:= GetNewPar("BF_GFEATTR",.F.) // Verifica se pode ou não alterar transportadora automaticametne
	Private cInBkTransp := cCodTransX

	If nInOpc == 1 // Pedido de venda  - Tela
		cCodCli 	:= M->C5_CLIENTE
		cLojCli 	:= M->C5_LOJACLI
		cNumPed 	:= M->C5_NUM
		cTipoPed	:= M->C5_TIPO
		cTpFrete	:= M->C5_TPFRETE 
	ElseIf nInOpc == 2 // Pedido de Venda - Externa - Sem tela
		cCodCli 	:= SC5->C5_CLIENTE
		cLojCli 	:= SC5->C5_LOJACLI
		cNumPed 	:= SC5->C5_NUM
		cTipoPed	:= SC5->C5_TIPO
		cTpFrete	:= SC5->C5_TPFRETE 
	ElseIf nInOpc == 3 // Orçamento Televendas
		cCodCli 	:= M->UA_CLIENTE
		cLojCli 	:= M->UA_LOJA
		cNumPed 	:= M->UA_NUM
		cTipoPed	:= "N"
		cTpFrete	:= M->UA_TPFRETE 
	ElseIf nInOpc == 4 // Orçamento Televendas
		cCodCli 	:= SUA->UA_CLIENTE
		cLojCli 	:= SUA->UA_LOJA
		cNumPed 	:= SUA->UA_NUM
		cTipoPed	:= "N"
		cTpFrete	:= SUA->UA_TPFRETE 
	ElseIf nInOpc == 5 // Nota fiscal de saída
		cCodCli 	:= SF2->F2_CLIENTE
		cLojCli 	:= SF2->F2_LOJA
		cNumPed 	:= SF2->F2_DOC+SF2->F2_SERIE
		cTipoPed	:= "N"
		cTpFrete	:= SF2->F2_TPFRETE 
	ElseIf nInOpc == 6 // Pedido de Venda - Externa Com Tela
		cCodCli 	:= SC5->C5_CLIENTE
		cLojCli 	:= SC5->C5_LOJACLI
		cNumPed 	:= SC5->C5_NUM
		cTipoPed	:= SC5->C5_TIPO
		cTpFrete	:= SC5->C5_TPFRETE 
	ElseIf nInOpc == 7 // Pedido de Venda - Externa sem Tela
		cCodCli 	:= SC5->C5_CLIENTE
		cLojCli 	:= SC5->C5_LOJACLI
		cNumPed 	:= SC5->C5_NUM
		cTipoPed	:= SC5->C5_TIPO
		cTpFrete	:= SC5->C5_TPFRETE 
		If !lIsGfeOn
			Return 
		Endif 
	Else
		Return
	Endif

	// Tipo de pedidos que não sejam N=Normal não são considerados.
	If !cTipoPed $ "N"
		Return
	Endif

	// Se o tipo de Frete informado no Orçamento/Pedido não for C=CIF não efetua cálculo de frete para também não atribuir nenhuma transportadora ao pedido 
	If !cTpFrete $ "C"
		Return 
	Endif 

	// Verifica se o CNPJ da empresa está cadastrado na GU3
	cEmissor 	:= IIF(MTA410ChkEmit(SM0->M0_CGC),SM0->M0_CGC, Posicione("GU3", 11, xFilial("GU3") + SM0->M0_CGC, "GU3_CDEMIT") )// sfRetEmit(xFilial("SF2")) )
	//Posicione("GU3", 11, xFilial("GU3") + SM0->M0_CGC, "GU3_CDEMIT")// MTA410ChkEmit(SM0->M0_CGC)

	// Verifica se o código e loja do cliente informado tem cadastro na GU3
	cDestin		:= GFExIntCod(cCodCli,cLojCli,1,,)

	cTpDoc 		:= "NFS"

	DbSelectArea("SA1")
	DbSetOrder(1)
	SA1->(dbSeek(xFilial("SA1")+cCodCli+ cLojCli))

	cNuCidOr := AllTrim(TMS120CdUf(SA1->A1_EST, "1") + SA1->A1_COD_MUN)

	oModelSim:SetOperation(3) //Seta como inclusão
	oModelSim:Activate()
	oModelNeg:LoadValue('CONSNEG' , cRadio) //
	IncProc()

	//Agrupadores - Nao obrigatorio
	oModelAgr:LoadValue('GWN_CDCLFR', cCdClFr)  	//classificacao de frete
	oModelAgr:LoadValue('GWN_CDTPOP', cTpOp)   		//tipo da operacao
	oModelAgr:LoadValue('GWN_DOC'   , "ROMANEIO")

	//Documento de Carga
	oModelDC:LoadValue('GW1_EMISDC', cEmissor) 		//codigo do emitente - chave
	oModelDC:LoadValue('GW1_NRDC'  , cNumPed ) 		//numero da nota - chave
	oModelDC:LoadValue('GW1_CDTPDC', cTpDoc) 		//tipo do documento - chave
	oModelDC:LoadValue('GW1_CDREM' , cEmissor )  	//remetente
	oModelDC:LoadValue('GW1_CDDEST', cDestin )   	//destinatario


	oModelDC:LoadValue('GW1_TPFRET', "1") 			//1-CIF 2-CIF redesp 3-FOB 4-FOB redesp 5-Consignado
	oModelDC:LoadValue('GW1_ICMSDC', "1")
	oModelDC:LoadValue('GW1_USO'   , "1")
	oModelDC:LoadValue('GW1_QTUNI' , 1)
	//Trechos
	oModelTr:LoadValue('GWU_EMISDC', cEmissor)													//codigo do emitente - chave
	oModelTr:LoadValue('GWU_NRDC'  , cNumPed) 													//numero da nota - chave
	oModelTr:LoadValue('GWU_CDTPDC', cTpDoc)													// tipo do documento - chave
	oModelTr:LoadValue('GWU_SEQ'   , "01")    													//sequencia - chave
	oModelTr:LoadValue('GWU_NRCIDD', cNuCidOr)  // codigo da cidade para o calculo


	If nInOpc == 1 // Pedido de venda  - Tela

		nPxItem     	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
		nPxProduto  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
		nPxQtdVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
		nPxPrcVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
		nPxValor    	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})

		For nI := 1 To Len(aCols)
			If !aCols[nI][Len(aHeader)+1]
				nItem += 1
				nAltura := Posicione("SB5",1,xFilial("SB5")+aCols[nI][nPxProduto],"B5_ALTURA")
				nVolume := (nAltura * SB5->B5_LARG * SB5->B5_COMPR) * aCols[nI][nPxQtdVen]
				SB1->(DbSetOrder(1))
				SB1->(dbSeek(xFilial("SB1")+aCols[nI][nPxProduto]))
				//Produtos
				oModelIt:LoadValue('GW8_CDTPDC'	,cTpDoc) 									// tipo do documento - chave
				oModelIt:LoadValue('GW8_EMISDC'	,cEmissor)									// codigo do emitente - chave
				oModelIt:LoadValue('GW8_NRDC'  	,cNumPed  ) 								// numero da nota - chave
				oModelIt:LoadValue('GW8_ITEM'  	,aCols[nI][nPxItem]) 				   		// codigo do item
				oModelIt:LoadValue('GW8_DSITEM'	,Substr(SB1->B1_DESC,1,TamSX3("GW8_DSITEM")[1]) )  							// descricao do item
				oModelIt:LoadValue('GW8_CDCLFR'	,cCdClFr)    								// classificacao de frete
				oModelIt:LoadValue('GW8_VOLUME'	,nVolume) 									// Volume
				oModelIt:LoadValue('GW8_PESOR' 	,(aCols[nI][nPxQtdVen])*(SB1->B1_PESBRU)  ) // peso real
				oModelIt:LoadValue('GW8_VALOR' 	,aCols[nI][nPxValor])     					// Valor do item
				oModelIt:LoadValue('GW8_QTDE'  	,aCols[nI][nPxQtdVen] )     				// Quantidade do item
				oModelIt:LoadValue('GW8_TRIBP' 	,"1" )
				oModelIt:AddLine(.T.)
			Endif
		Next
		// Desativa o Log
		sfGFEX010Slg(0)
		//0: Não apresentar
		//1: Somente erros
		//2: Sempre

	ElseIf nInOpc == 2  .Or.  nInOpc == 6 // Pedido de Venda - Externa
		aAreaSC6 := SC6->(GetArea())
		aAreaSC5 := SC5->(GetArea())
		dbSelectArea("SC6")
		dbSetOrder(1)
		SC6->(dbSeek(xFilial("SC6")+cNumPed))

		While !Eof() .And. SC6->(C6_FILIAL+C6_NUM) == xFilial("SC6")+cNumPed

			nItem += 1
			nAltura := Posicione("SB5",1,xFilial("SB5")+SC6->C6_PRODUTO,"B5_ALTURA")
			nVolume := (nAltura * SB5->B5_LARG * SB5->B5_COMPR) * SC6->C6_QTDVEN
			SB1->(DbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+SC6->C6_PRODUTO))
			//Produtos
			oModelIt:LoadValue('GW8_CDTPDC'	,cTpDoc) 									// tipo do documento - chave
			oModelIt:LoadValue('GW8_EMISDC'	,cEmissor)									//codigo do emitente - chave
			oModelIt:LoadValue('GW8_NRDC'  	,cNumPed  ) 								//numero da nota - chave
			oModelIt:LoadValue('GW8_ITEM'  	,SC6->C6_ITEM ) 				       		//codigo do item
			oModelIt:LoadValue('GW8_DSITEM'	,Substr(SB1->B1_DESC,1,TamSX3("GW8_DSITEM")[1]) )  		//descricao do item
			oModelIt:LoadValue('GW8_CDCLFR'	,cCdClFr)    											//classificacao de frete
			oModelIt:LoadValue('GW8_VOLUME'	,nVolume) 												//Volume
			oModelIt:LoadValue('GW8_PESOR' 	,(SC6->C6_QTDVEN-SC6->C6_QTDENT)*(SB1->B1_PESBRU)  ) 	//peso real
			oModelIt:LoadValue('GW8_VALOR' 	,(SC6->C6_QTDVEN-SC6->C6_QTDENT)*SC6->C6_PRCVEN)     	//valor do item
			oModelIt:LoadValue('GW8_QTDE'  	,(SC6->C6_QTDVEN-SC6->C6_QTDENT) )     					//valor do item
			oModelIt:LoadValue('GW8_TRIBP' 	,"1" )
			oModelIt:AddLine(.T.)
			DbSelectArea("SC6")
			SC6->(DbSkip())
		EndDo

		If  nInOpc == 6 .And. PswAdmin( , ,RetCodUsr()) == 0
			sfGFEX010Slg(2)
		Else
			sfGFEX010Slg(1)
		Endif
		//0: Não apresentar
		//1: Somente erros
		//2: Sempre

		RestArea(aAreaSC6)
		RestArea(aAreaSC5)

	ElseIf nInOpc == 3 // Orçamento Televendas


		nPxItem     	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_ITEM"})
		nPxProduto  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_PRODUTO"})
		nPxQtdVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_QUANT"})
		nPxPrcVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_PRCVEN"})
		nPxValor    	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_VLRITEM"})

		For nI := 1 To Len(aCols)
			If !aCols[nI][Len(aHeader)+1]
				nItem += 1
				nAltura := Posicione("SB5",1,xFilial("SB5")+aCols[nI][nPxProduto],"B5_ALTURA")
				nVolume := (nAltura * SB5->B5_LARG * SB5->B5_COMPR) * aCols[nI][nPxQtdVen]
				SB1->(DbSetOrder(1))
				SB1->(dbSeek(xFilial("SB1")+aCols[nI][nPxProduto]))
				//Produtos
				oModelIt:LoadValue('GW8_CDTPDC'	,cTpDoc) 									// tipo do documento - chave
				oModelIt:LoadValue('GW8_EMISDC'	,cEmissor)									// codigo do emitente - chave
				oModelIt:LoadValue('GW8_NRDC'  	,cNumPed  ) 								// numero da nota - chave
				oModelIt:LoadValue('GW8_ITEM'  	,aCols[nI][nPxItem]) 				   		// codigo do item
				oModelIt:LoadValue('GW8_DSITEM'	,Substr(SB1->B1_DESC,1,TamSX3("GW8_DSITEM")[1]) )  							// descricao do item
				oModelIt:LoadValue('GW8_CDCLFR'	,cCdClFr)    								// classificacao de frete
				oModelIt:LoadValue('GW8_VOLUME'	,nVolume) 									// Volume
				oModelIt:LoadValue('GW8_PESOR' 	,(aCols[nI][nPxQtdVen])*(SB1->B1_PESBRU)  ) // peso real
				oModelIt:LoadValue('GW8_VALOR' 	,aCols[nI][nPxValor])     					// Valor do item
				oModelIt:LoadValue('GW8_QTDE'  	,aCols[nI][nPxQtdVen] )     				// Quantidade do item
				oModelIt:LoadValue('GW8_TRIBP' 	,"1" )
				oModelIt:AddLine(.T.)
			Endif
		Next
		// Desativa o Log
		sfGFEX010Slg(0)
		//0: Não apresentar
		//1: Somente erros
		//2: Sempre

	ElseIf nInOpc == 4 // Orçamento Televendas

		aAreaSUB 	:= SUB->(GetArea())
		aAreaSUA 	:= SUA->(GetArea())

		dbSelectArea("SUB")
		dbSetOrder(1)
		SUB->(dbSeek(xFilial("SUB")+cNumPed))

		While !Eof() .And. SUB->(UB_FILIAL+UB_NUM) == xFilial("SUB")+cNumPed

			nItem += 1
			nAltura := Posicione("SB5",1,xFilial("SB5")+SUB->UB_PRODUTO,"B5_ALTURA")
			nVolume := (nAltura * SB5->B5_LARG * SB5->B5_COMPR) * SUB->UB_QUANT
			SB1->(DbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+SUB->UB_PRODUTO))
			//Produtos
			oModelIt:LoadValue('GW8_CDTPDC'	,cTpDoc) 									// tipo do documento - chave
			oModelIt:LoadValue('GW8_EMISDC'	,cEmissor)									// codigo do emitente - chave
			oModelIt:LoadValue('GW8_NRDC'  	,cNumPed ) 									// numero da nota - chave
			oModelIt:LoadValue('GW8_ITEM'  	,SUB->UB_ITEM ) 				       		// codigo do item
			oModelIt:LoadValue('GW8_DSITEM'	,Substr(SB1->B1_DESC,1,TamSX3("GW8_DSITEM")[1]))  							// descricao do item
			oModelIt:LoadValue('GW8_CDCLFR'	,cCdClFr)    								// classificacao de frete
			oModelIt:LoadValue('GW8_VOLUME'	,nVolume) 									// Volume
			oModelIt:LoadValue('GW8_PESOR' 	,(SUB->UB_QUANT)*(SB1->B1_PESBRU)  ) 		// peso real
			oModelIt:LoadValue('GW8_VALOR' 	,SUB->UB_VLRITEM )     						// valor do item
			oModelIt:LoadValue('GW8_QTDE'  	,SUB->UB_QUANT )     						// Quantidade do item
			oModelIt:LoadValue('GW8_TRIBP' 	,"1" )
			oModelIt:AddLine(.T.)
			DbSelectArea("SUB")
			SUB->(DbSkip())
		EndDo
		// Desativa o Log
		sfGFEX010Slg(0)
		//0: Não apresentar
		//1: Somente erros
		//2: Sempre

		RestArea(aAreaSUA)
		RestArea(aAreaSUB)

	ElseIf nInOpc == 5 // Nota fiscal de saída

		aAreaSD2 	:= SD2->(GetArea())
		aAreaSF2 	:= SF2->(GetArea())

		dbSelectArea("SD2")
		dbSetOrder(3)//D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		cCodCli 	:= SF2->F2_CLIENTE
		cLojCli 	:= SF2->F2_LOJA
		cNumPed 	:= SF2->F2_DOC+SF2->F2_SERIE

		SD2->(dbSeek(xFilial("SD2")+cNumPed + cCodCli + cLojCli))

		While !Eof() .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == xFilial("SD2")+cNumPed + cCodCli + cLojCli

			nItem += 1
			nAltura := Posicione("SB5",1,xFilial("SB5")+SD2->D2_COD,"B5_ALTURA")
			nVolume := (nAltura * SB5->B5_LARG * SB5->B5_COMPR) * SD2->D2_QUANT
			SB1->(DbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+SD2->D2_COD))
			//Produtos
			oModelIt:LoadValue('GW8_CDTPDC'	,cTpDoc) 									// tipo do documento - chave
			oModelIt:LoadValue('GW8_EMISDC'	,cEmissor)									//codigo do emitente - chave
			oModelIt:LoadValue('GW8_NRDC'  	,cNumPed  ) 								//numero da nota - chave
			oModelIt:LoadValue('GW8_ITEM'  	,SD2->D2_ITEM ) 				       		//codigo do item
			oModelIt:LoadValue('GW8_DSITEM'	,Substr(SB1->B1_DESC,1,TamSX3("GW8_DSITEM")[1]) )  							//descricao do item
			oModelIt:LoadValue('GW8_CDCLFR'	,cCdClFr)    								//classificacao de frete
			oModelIt:LoadValue('GW8_VOLUME'	,nVolume) 									//Volume
			oModelIt:LoadValue('GW8_PESOR' 	,(SD2->D2_QUANT)*(SB1->B1_PESBRU)  ) 		//peso real
			oModelIt:LoadValue('GW8_VALOR' 	,SD2->D2_VALBRUT )     						//valor do item
			oModelIt:LoadValue('GW8_QTDE'  	,SD2->D2_QUANT )     						//valor do item
			oModelIt:LoadValue('GW8_TRIBP' 	,"1" )
			oModelIt:AddLine(.T.)
			DbSelectArea("SD2")
			SD2->(DbSkip())
		EndDo

		// Desativa o Log
		sfGFEX010Slg(0)
		//0: Não apresentar
		//1: Somente erros
		//2: Sempre

		RestArea(aAreaSD2)
		RestArea(aAreaSF2)

	ElseIf nInOpc == 7 // Pedido de Venda - Externa sem Tela e só dados liberados da SC9
		aAreaSC6 := SC6->(GetArea())
		aAreaSC5 := SC5->(GetArea())
		dbSelectArea("SC9")
		dbSetOrder(1)
		SC9->(dbSeek(xFilial("SC9")+cNumPed))

		While !Eof() .And. SC9->(C9_FILIAL+C9_PEDIDO) == xFilial("SC9")+cNumPed

			// Somente se o item não tiver Bloqueio de estoque e crédito/apto para faturar
			If Empty(SC9->(C9_BLCRED+C9_BLEST))
				nItem += 1
				nAltura := Posicione("SB5",1,xFilial("SB5")+SC6->C6_PRODUTO,"B5_ALTURA")
				nVolume := (nAltura * SB5->B5_LARG * SB5->B5_COMPR) * SC6->C6_QTDVEN
				SB1->(DbSetOrder(1))
				SB1->(dbSeek(xFilial("SB1")+SC9->C9_PRODUTO))
				//Produtos
				oModelIt:LoadValue('GW8_CDTPDC'	,cTpDoc) 												// tipo do documento - chave
				oModelIt:LoadValue('GW8_EMISDC'	,cEmissor)												//codigo do emitente - chave
				oModelIt:LoadValue('GW8_NRDC'  	,cNumPed  ) 											//numero da nota - chave
				oModelIt:LoadValue('GW8_ITEM'  	,Substr(SC9->C9_ITEM+SC9->C9_SEQUEN,1,TamSX3("GW8_ITEM")[1]) ) 				       		//codigo do item
				oModelIt:LoadValue('GW8_DSITEM'	,Substr(SB1->B1_DESC,1,TamSX3("GW8_DSITEM")[1]) )  		//descricao do item
				oModelIt:LoadValue('GW8_CDCLFR'	,cCdClFr)    											//classificacao de frete
				oModelIt:LoadValue('GW8_VOLUME'	,nVolume) 												//Volume
				oModelIt:LoadValue('GW8_PESOR' 	,(SC9->C9_QTDLIB)*(SB1->B1_PESBRU)  ) 					//peso real
				oModelIt:LoadValue('GW8_VALOR' 	,(SC9->C9_QTDLIB)*SC9->C9_PRCVEN)    				 	//valor do item
				oModelIt:LoadValue('GW8_QTDE'  	,(SC9->C9_QTDLIB) )    				 					//valor do item
				oModelIt:LoadValue('GW8_TRIBP' 	,"1" )
				oModelIt:AddLine(.T.)
			Endif
			DbSelectArea("SC9")
			SC9->(DbSkip())
		EndDo

		sfGFEX010Slg(0)
		//0: Não apresentar
		//1: Somente erros
		//2: Sempre

		RestArea(aAreaSC6)
		RestArea(aAreaSC5)
	Endif

	// Dispara a simulação
	oModelInt:SetValue("INTEGRA" ,"A")
	IncProc()

	//Verifica se há linhas no model do calculo, se não há linhas significa que a simulação falhou
	If oModelCal1:GetQtdLine() > 1 .Or. !Empty( oModelCal1:GetValue('C1_NRCALC'  ,1) )
		//Percorre o grid, cada linha corresponde a um calculo diferente
		For nCont := 1 to oModelCal1:GetQtdLine()
			oModelCal1:GoLine( nCont )

			nVlrFrt	 		:= oModelCal1:GetValue('C1_VALFRT'  ,nCont )
			nPrevEnt  		:= 99 //oModelCal1:GetValue('C1_DTPREN'  ,nCont ) - ddatabase

			nNumCalc		:= oModelCal2:GetValue("C2_NRCALC" 	,1 )  // "Número Cálculo"
			nClassFret		:= oModelCal2:GetValue("C2_CDCLFR" 	,1 )  // "Class Frete"
			nTipOper		:= oModelCal2:GetValue("C2_CDTPOP" 	,1 )  // "Tipo Operação
			cTrecho			:= oModelCal2:GetValue("C2_SEQ" 	,1 )  // "Trecho"
			cCGCTran		:= oModelCal2:GetValue("C2_CDEMIT" 	,1 )  // "Emit Tabela"
			cTabela			:= oModelCal2:GetValue("C2_NRTAB" 	,1 )  // "Nr tabela "
			cNumNegoc		:= oModelCal2:GetValue("C2_NRNEG" 	,1 )  // "Nr Negoc"
			cRota			:= oModelCal2:GetValue("C2_NRROTA" 	,1 )  // "Rota"
			dDatValid		:= oModelCal2:GetValue("C2_DTVAL" 	,1 )  // "Data Validade"
			cFaixa			:= oModelCal2:GetValue("C2_CDFXTV" 	,1 )  // "Faixa"
			cTipoVei		:= oModelCal2:GetValue("C2_CDTPVC" 	,1 )  // "Tipo Veículo"

			// Apresenta se eh rota (frequência)
			cEhRota := "Não encontrada frequência"
			lEhRota := .F.
			dDataEnt := SToD("")

			cAliasRota := GetNextAlias()
			BeginSql Alias cAliasRota
				SELECT GUN.GUN_XROTA AS ROTA, GUN.GUN_PRAZO AS PRAZO
				FROM %Table:GUN% GUN
				WHERE GUN.GUN_FILIAL = %Exp:xFilial("GUN")%
				AND GUN.GUN_CDTRP = %Exp:cCGCTran%
				AND GUN.GUN_NRCIDS = %Exp:cNuCidOr%
				AND GUN.%NotDel%
			EndSql

			If (cAliasRota)->(!Eof())
				lEhRota 	:= cValToChar(DOW(Date())) $ AllTrim((cAliasRota)->ROTA)
				cEhRota 	:= IIf(lEhRota,"É rota = "+(cAliasRota)->ROTA,"Não é rota = "+(cAliasRota)->ROTA)
				nPrevEnt 	:= sfRetPrazo((cAliasRota)->ROTA,(cAliasRota)->PRAZO)
				dDataEnt	:= DataValida(dDatabase+nPrevEnt,.T.)
			EndIf
			(cAliasRota)->(dbCloseArea())

			SA4->(dbSetOrder(3))
			If SA4->(dbSeek(xFilial("SA4")+sfRetCGc(cCGCTran)))
				aAdd (aRet, {,SA4->A4_COD,SA4->A4_NOME,nVlrFrt,nPrevEnt,lEhRota,cEhRota,.T.,dDataEnt})
			Else
				cCGC := sfRetCGc(cCGCTran)
				If SA4->(dbSeek(xFilial("SA4")+cCGC))
					AADD (aRet, {,SA4->A4_COD,SA4->A4_NOME,nVlrFrt,nPrevEnt,lEhRota,cEhRota,.T.,dDataEnt})
				Else
					AADD (aRet, {,cCGCTran,"Transportadora não cadastrada no Microsiga Protheus!",nVlrFrt,nPrevEnt,lEhRota,cEhRota,.F.,dDataEnt}) //--"Transportadora n? cadastrada no Microsiga Protheus!!!"
				EndIf
			EndIf
		Next nCont

		If Len(aRet) > 1 // Soh ordena caso tenha mais de uma
			If lMvTpFrete // Valor
				aSort(aRet,,,{|x,y| StrZero(x[4],15,2)+cValToChar(x[5]) < StrZero(y[4],15,2)+cValToChar(y[5]) }) // Valor
			Else // Prazo
				aSort(aRet,,,{|x,y| cValToChar(x[5])+StrZero(x[4],15,2) < cValToChar(y[5])+StrZero(y[4],15,2) }) // Prazo + Valor
			EndIf
		EndIf

		// Já marca o primeiro item que vem no menor valor
		If Len(aRet) > 0
			aRet[1,1]	:= '1'
		Endif

		sfRetSiml(nInOpc,aRet,@cCodTransX,@nVGfeVlrOut)

	ElseIf nInOpc == 6 // Forca abrir tela mesmo sem ter trecho ou transp.
		AADD (aRet, {," ","Transportadora não cadastrada no Microsiga Protheus!",0,0,.F.,"",.F.,CTOD("")})
		sfRetSiml(nInOpc,aRet,@cCodTransX,@nVGfeVlrOut)
	EndIf

	// Restaura valores
	ALTERA	:= lBkAltera
	INCLUI	:= lBkInclui

	RestArea(aArea)

Return

/*/{Protheus.doc} sfRetSiml
Calcular dias de prazo c/ base na rota
@type function
@version 1
@author Iago Luiz Raimondi
@since 31/10/2022
@param cRota, character, param_description
@param nPrazo, number, param_description
@return variant, return_description
/*/
Static Function sfRetPrazo(cRota,nPrazo)

	Local nCalc := 0
	Local nDOW

	// Soh calcula se tiver rota
	If !Empty(cRota)

		//Dia da semana (1 2 3 4 5 6 7)
		nDOW := DOW(Date())

		//Enquanto não estiver na coleta, soma um dia no prazo
		While (!cValToChar(nDOW) $ AllTrim(cRota))
			//Sab volta pra domingo
			If nDOW >= 7
				nDOW := 1
			EndIf
			nDOW++		 
			nCalc += 1
		EndDo
		//Adiciona prazo
		nCalc += nPrazo

	EndIf

Return nCalc

/*/{Protheus.doc} sfRetSiml
Retorno da simulação do frete 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 15/08/2022
@param aListBox, array, param_description
@param cCodTransX, character, param_description
@return variant, return_description
/*/
Static Function sfRetSiml(nInOpc,aListBox,cCodTransX,nVGfeVlrOut) // Adaptação da função a410RetSml

	Local aSize     	:= {}
	Local aObjects  	:= {}
	Local aInfo     	:= {}
	Local aPosObj   	:= {}
	Local oOk       	:= LoadBitMap(GetResources(),"LBOK")
	Local oNo       	:= LoadBitMap(GetResources(),"LBNO")
	Local oBtn01
	Local oBtn02
	Local oBtn03
	Local nItemMrk		:= 0
	Local nOpca			:= 0
	Local oDlgGfe	 	:= Nil
	Local oGet01
	Local oGet02
	Local cTxtLog 		:= ""

	Local lFrtCmb		:= .F.
	Local nPrzTransp 	:= 0
	Local cRotaTransp 	:= ""
	Local dDtProgram	:= CTOD("") 

	Default aListBox	:= {}
	Default cCodTransX	:= Space(6)
	Default nVGfeVlrOut	:= 0

	Private cCodTrn 	:= Space(6)
	Private cNomTrns 	:= ""

	Private oListBox	:= Nil
	Private aRotMark:= {}

	// Se for com Interface
	If (nInOpc == 1 .Or. nInOpc == 3 .Or. nInOpc == 6) .And. !IsBlind()

		aSize    	:= MsAdvSize(.F. )
		aObjects 	:= {}

		aAdd( aObjects, { 100, 000, .T., .F., .T.  } )
		aAdd( aObjects, { 100, 100, .T., .T. } )
		aAdd( aObjects, { 100, 005, .T., .T. } )
		aAdd( aObjects, { 100, 005, .T., .T. } )

		aInfo   := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ]*0.60, aSize[ 4 ]*0.68, 3, 3, .T.  }
		aPosObj := MsObjSize( aInfo, aObjects, .T. )

		DEFINE MSDIALOG oDlgGfe TITLE 'Simulação de Frete' From aSize[7],0 to aSize[6]*0.68,aSize[5]*0.61 OF oMainWnd PIXEL //--"SimulaÃ¨Â±Â«o de Frete"

		oPanel := TPanel():New(aPosObj[1,1],aPosObj[1,2],"",oDlgGfe,,,,,CLR_WHITE,(aPosObj[1,3]), (aPosObj[1,4]), .T.,.T.)

		//-- Cabecalho dos campos do Monitor.
		@ aPosObj[2,1],aPosObj[2,2] LISTBOX oListBox Fields HEADER " ","Código","Nome Transp.","Valor do Frete","Prazo de Entrega (Dias)","É rota?","Previsão Entrega" SIZE aPosObj[2,4]-aPosObj[2,2],aPosObj[2,3]-aPosObj[2,1] PIXEL //--"Nome Transp.","Valor do Frete","Cod.Transp.","Prazo de Entrega (Dias)"

		oListBox:SetArray( aListBox )
		oListBox:bLDblClick := { || a410MrkSml(aListBox,@nItemMrk,@cCodTransX,,@nVGfeVlrOut,@nPrzTransp,@cRotaTransp,@dDtProgram) }
		oListBox:bLine      := { || { Iif(aListBox[ oListBox:nAT,SMMARCA 	] == '1',oOk,oNo),;
			aListBox[ oListBox:nAT,SMCODTRAN	],;
			aListBox[ oListBox:nAT,SMNOMETRAN	],;
			Transform(aListBox[ oListBox:nAT,SMVALOR	   	],"@E 999,999.99"),;
			aListBox[ oListBox:nAT,SMPRAZO	   	],;
			aListBox[ oListBox:nAT,SMXROTA		],;
			aListBox[ oListBox:nAT,SMDATA	   	] }}

		@ aPosObj[3,1]+1,002 SAY "Transp." OF oDlgGfe PIXEL
		@ aPosObj[3,1],030 MSGET oGet01 VAR cCodTrn F3 "SA4" SIZE 040, 007 WHEN lFrtCmb VALID ( (Empty(cCodTrn) .Or. ExistCpo("SA4",cCodTrn,1)), Iif(!Empty(cCodTrn),cNomTrns := Posicione("SA4",1,xFilial("SA4")+cCodTrn,"A4_NOME"),cNomeTrns := "")) OF oDlgGfe PIXEL
		@ aPosObj[3,1],075 MSGET oGet02 VAR cNomTrns SIZE 100, 007 WHEN .F. OF oDlgGfe PIXEL

		//-- Botoes da tela do monitor.
		@ aPosObj[4,1],001 BUTTON oBtn01	PROMPT 'CONFIRMAR'	WHEN Iif(!lFrtCmb,.T.,Iif(lFrtCmb .And. !Empty(cCodTrn),.T.,.F.)) Action (nOpca := 1, oDlgGfe:End()) OF oDlgGfe PIXEL SIZE 035,012	//-- "Confirmar"
		@ aPosObj[4,1],040 BUTTON oBtn02	PROMPT 'SAIR'		Action oDlgGfe:End() OF oDlgGfe PIXEL SIZE 035,012	//-- "Sair"
		@ aPosObj[4,1],105 BUTTON oBtn03	PROMPT 'FRETE COMBINADO'	Action (lFrtCmb := !lFrtCmb, cCodTrn := Space(6), cNomTrns := " " ) OF oDlgGfe PIXEL SIZE 060,012	//-- "Confirmar"

		ACTIVATE MSDIALOG oDlgGfe CENTERED On Init a410MrkSml(aListBox,@nItemMrk,@cCodTransX,Iif(Len(aListBox) > 0 ,1,Nil),@nVGfeVlrOut,@nPrzTransp,@cRotaTransp,@dDtProgram)


	ElseIf Len(aListBox) > 0 // Se tiver dados assume o menor valor calculado
		cCodTransX 	:=  aListBox[1,SMCODTRAN]
		nVGfeVlrOut	:=  aListBox[1,SMVALOR]
		nPrzTransp 	:= 	aListBox[1,SMPRAZO]
		cRotaTransp := 	aListBox[1,SMXROTA]
		dDtProgram	:=  sfCalcRota(dDataBase,cRotaTransp)
		nOpca := 1
	Endif

	If nOpca == 1

		// Caso frete combinado, aceita o que vier
		If lFrtCmb
			If !Empty(cCodTrn)
				cCodTransX 	:=  cCodTrn
			Else
				MsgAlert("Quando for frete combinado, é obrigatório ter transportadora. Operação cancelada!")
				Return
			EndIf
		EndIf

		If nInOpc == 1
			If SC5->(FieldPos("C5_XGFEVLR")) > 0
				If lIsGfeOn
					cTxtLog	:= "Alteração de dados Rotina de Cálculo de Frete"
					cTxtLog	+= Chr(13)+Chr(10) + "Valor do frete de "+cValToChar(M->C5_XGFEVLR) + " para: " + cValToChar(nVGfeVlrOut)
					M->C5_XGFEVLR 	:= 	nVGfeVlrOut		// Grava valor do custo do frete
					cTxtLog	+= Chr(13)+Chr(10) + "Transportadora de "+M->C5_TRANSP + " para: " + cCodTransX
					If lAtuGfeTr
						M->C5_TRANSP   	:= cCodTransX  			// Grava transportadora na SC5
					Endif
					If Empty(M->C5_DTPROGM)
						M->C5_DTPROGM		:=  dDtProgram
					Endif 
				Else
					nVGfeVlrOut		:= 0
					cCodTransX		:= cInBkTransp
				Endif

				If !Empty(cTxtLog)

					// Grava Log
					U_GMCFGM01(	"AT"/*cTipo*/,;
						M->C5_NUM/*cPedido*/,;
						cTxtLog/*cObserv*/,;
						FunName()/*cResp*/,;
						/*lBtnCancel*/,;
						/*cMotDef*/,;
						.T./*lAutoExec*/,;
						/*cUserName*/)
					Endif

			Endif

		ElseIf nInOpc == 2 .Or. nInOpc == 6	// Pedido de venda - Grava direto no Pedido
			If SC5->(FieldPos("C5_XGFEVLR")) > 0

				If lIsGfeOn
					Reclock("SC5",.F.)
					If Empty(SC5->C5_XGFEVLR) .And. !lAtuGfeTr
						cTxtLog	:= "Alteração de dados Rotina de Cálculo de Frete"
						cTxtLog	+= Chr(13)+Chr(10) + "Valor do frete de "+cValToChar(SC5->C5_XGFEVLR) + " para: " + cValToChar(nVGfeVlrOut)
						SC5->C5_XGFEVLR 	:= 	nVGfeVlrOut		// Grava valor do custo do frete
						If Empty(SC5->C5_DTPROGM) 
							SC5->C5_DTPROGM		:=  dDtProgram
						Endif 
						// Se ainda não tinha sido calculado o valor do frete ou se é alteração pelo simula GFE da expedição
					ElseIf (Empty(SC5->C5_XGFEVLR) .And. lAtuGfeTr) .Or. nInOpc == 6
						cTxtLog	:= "Alteração de dados Rotina de Cálculo de Frete"
						cTxtLog	+= Chr(13)+Chr(10) + "Transportadora de "+SC5->C5_TRANSP + " para: " + cCodTransX
						SC5->C5_TRANSP   := cCodTransX  			// Grava transportadora na SC5
						cTxtLog	+= Chr(13)+Chr(10) + "Valor do frete de "+cValToChar(SC5->C5_XGFEVLR) + " para: " + cValToChar(nVGfeVlrOut)
						SC5->C5_XGFEVLR 	:= 	nVGfeVlrOut		// Grava valor do custo do frete
						If Empty(SC5->C5_DTPROGM)
							SC5->C5_DTPROGM		:=  dDtProgram
						Endif 
					Endif
					MsUnlock()
				Else
					nVGfeVlrOut		:= 0
					cCodTransX		:= cInBkTransp
				Endif

				If !Empty(cTxtLog)
					// Grava Log
					U_GMCFGM01(	"AT"/*cTipo*/,;
						SC5->C5_NUM/*cPedido*/,;
						cTxtLog/*cObserv*/,;
						FunName()/*cResp*/,;
						/*lBtnCancel*/,;
						/*cMotDef*/,;
						.T./*lAutoExec*/,;
						/*cUserName*/)
					Endif
			Endif
		ElseIf nInOpc == 3
			If SUA->(FieldPos("UA_XGFEVLR")) > 0
				If Empty(M->UA_XGFEVLR)
					M->UA_XGFEVLR 	:= 	nVGfeVlrOut		// Grava valor do custo do frete
				Endif
				If lIsGfeOn
					If lAtuGfeTr
						M->UA_TRANSP   	:= cCodTransX  //Grava transportadora na SC5
						If Empty(M->UA_DTPROGM)
							M->UA_DTPROGM	:=  dDtProgram
						Endif 
					Endif
				Else
					nVGfeVlrOut		:= 0
					cCodTransX		:= cInBkTransp
				Endif
			Endif
		ElseIf nInOpc == 4	// Orçamento televendas -  Grava direto no Orçamento
			If SUA->(FieldPos("UA_XGFEVLR")) > 0

				Reclock("SUA",.F.)
				If Empty(SUA->UA_XGFEVLR)
					SUA->UA_XGFEVLR 	:= 	nVGfeVlrOut		// Grava valor do custo do frete
				Endif
				If lIsGfeOn
					If lAtuGfeTr
						SUA->UA_TRANSP  	:= cCodTransX  //Grava transportadora na SC5
						If Empty(SUA->UA_DTPROGM	)
							SUA->UA_DTPROGM		:=  dDtProgram
						Endif 
					Endif
				Else
					nVGfeVlrOut		:= 0
					cCodTransX		:= cInBkTransp
				Endif
				MsUnlock()
			Endif
		Elseif  nInOpc == 5 // Nota fiscal de saída
			If SF2->(FieldPos("F2_XGFEVLR")) > 0
				// Grava o valor do frete
				// o Campo Valor do Frete é preenchido pelo PE M460FIM a partir da SC5 - Se estiver zerado ajusta se necessário

				If Empty(SF2->F2_XGFEVLR)
					Reclock("SF2",.F.)
					cTxtLog	+= Chr(13)+Chr(10) + "Valor do frete de "+cValToChar(SF2->F2_XGFEVLR) + " para: " + cValToChar(nVGfeVlrOut)

					SF2->F2_XGFEVLR 	:= 	nVGfeVlrOut		// Grava valor do custo do frete
					If lIsGfeOn
						// Transportadora não pode ser alterada
						//	"F2_FIMP==' ' .AND. AllTrim(F2_ESPECIE)=='SPED'",'VERMELHO' },;	//NF não transmitida
						//    "F2_FIMP=='S'",'VERDE' //NF Autorizada
						//    "F2_FIMP=='T'",'AZUL'  //NF Transmitida
						//    "F2_FIMP=='N'",'PRETO' // NF nao autorizada
						// Se a nota ainda não foi transmitida ainda permite o Ajuste
						If Alltrim(SF2->F2_ESPECIE) == "SPED" .And. Empty(SF2->F2_FIMP) .And. lAtuGfeTr
							cTxtLog	+= Chr(13)+Chr(10) + "Transportadora de "+M->C5_TRANSP + " para: " + cCodTransX

							SF2->F2_TRANSP   := cCodTransX  //Grava transportadora na SC5
						Endif

					Else
						nVGfeVlrOut		:= 0
						cCodTransX		:= cInBkTransp
					Endif
					MsUnlock()
					cTxtLog += Chr(13)+Chr(10) + "Na nota fiscal : " + SF2->F2_DOC
					// Grava Log
					U_GMCFGM01(	"TF"/*cTipo*/,;
						SF2->F2_DOC/*cPedido*/,;
						cTxtLog/*cObserv*/,;
						FunName()/*cResp*/,;
						/*lBtnCancel*/,;
						/*cMotDef*/,;
						.T./*lAutoExec*/,;
						/*cUserName*/)


				Else
					nVGfeVlrOut		:= SF2->F2_XGFEVLR
					cCodTransX		:= SF2->F2_TRANSP
				Endif
			Endif
		ElseIf nInOpc == 7 // Pedido de venda - Grava direto no Pedido
			If SC5->(FieldPos("C5_XGFEVLR")) > 0
				// Só grava log de alteração se houve alguma mudança de dados ao que já estava gravado
				If SC5->C5_XGFEVLR <> nVGfeVlrOut .Or. SC5->C5_TRANSP <> cCodTransX
					If lIsGfeOn
						Reclock("SC5",.F.)
						If !lAtuGfeTr
							cTxtLog	:= "Alteração de dados Rotina de Cálculo de Frete"
							cTxtLog	+= Chr(13)+Chr(10) + "Valor do frete de "+cValToChar(SC5->C5_XGFEVLR) + " para: " + cValToChar(nVGfeVlrOut)
							SC5->C5_XGFEVLR 	:= 	nVGfeVlrOut		// Grava valor do custo do frete
						Else
							cTxtLog	:= "Alteração de dados Rotina de Cálculo de Frete"
							cTxtLog	+= Chr(13)+Chr(10) + "Transportadora de "+SC5->C5_TRANSP + " para: " + cCodTransX
							SC5->C5_TRANSP   := cCodTransX  			// Grava transportadora na SC5
							cTxtLog	+= Chr(13)+Chr(10) + "Valor do frete de "+cValToChar(SC5->C5_XGFEVLR) + " para: " + cValToChar(nVGfeVlrOut)
							SC5->C5_XGFEVLR  	:= 	nVGfeVlrOut		// Grava valor do custo do frete
							If Empty(SC5->C5_DTPROGM)
								SC5->C5_DTPROGM		:=  dDtProgram
							Endif 
						Endif
						MsUnlock()
					Else
						nVGfeVlrOut		:= 0
						cCodTransX		:= cInBkTransp
					Endif

					If !Empty(cTxtLog)
						// Grava Log
						U_GMCFGM01(	"AT"/*cTipo*/,;
							SC5->C5_NUM/*cPedido*/,;
							cTxtLog/*cObserv*/,;
							FunName()/*cResp*/,;
						/*lBtnCancel*/,;
						/*cMotDef*/,;
							.T./*lAutoExec*/,;
						/*cUserName*/)
						Endif
				Endif
			Endif

		Endif

	Endif

Return


/*/{Protheus.doc} sfRetCGc
Função para retornar o CNPJ do participante da GU3  
@type function
@version  
@author Marcelo Alberto Lauschner
@since 15/08/2022
@param cCodEmit, character, param_description
@return variant, return_description
/*/
Static Function sfRetCGc(cCodEmit)

	Local cCGC  := ""
	Local aArea := GetArea()

	dbSelectArea("GU3")
	dbSetOrder(1)

	If DBSeek(xFilial("GU3") + cCodEmit)
		cCGC := GU3->GU3_IDFED
	EndIf

	RestArea( aArea )

Return cCGC


/*/{Protheus.doc} sfRetEmit
Função para retornar o código do emitente a partir da Filial 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 15/08/2022
@param cFil, character, param_description
@return variant, return_description
/*/
Static Function sfRetEmit(cFil)

	Local aAreaGW0
	Local aArea := GetArea()
	Local cCodGFE := ""

	aAreaGW0 := GW0->( GetArea() )
	dbSelectArea("GW0")
	GW0->( dbSetOrder(1) )
	GW0->( DbSeek( Space( TamSx3("F2_FILIAL")[1] )+PadR( "FILIALEMIT",TamSx3("GW0_TABELA")[1] )+PadR( cFil,TamSx3("GW0_CHAVE")[1] ) ) )
	If !GW0->( EOF() ) .And. GW0->GW0_FILIAL == Space( TamSx3("F2_FILIAL")[1] );
			.And. GW0->GW0_TABELA == PadR( "FILIALEMIT",TamSx3("GW0_TABELA")[1] );
			.And. GW0->GW0_CHAVE == PadR( cFil,TamSx3("GW0_CHAVE")[1] )

		cCodGFE := PadR( GW0->GW0_CHAR01,TamSx3("GW1_EMISDC")[1] )
	EndIf
	RestArea( aAreaGW0 )

	RestArea( aArea )

Return cCodGFE


/*/{Protheus.doc} a410MrkSml
Função para marcar a opção de transportadora 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/08/2022
@param aListBox, array, param_description
@param nItemMrk, numeric, param_description
@param cCodTrans, character, param_description
@param nItem, numeric, param_description
@param nGfeVlr, numeric, param_description
@return variant, return_description
/*/
Static Function a410MrkSml(aListBox,nItemMrk,cCodTrans,nItem,nGfeVlr,nPrzTransp,cRotaTransp,dDtProgram)

	Default nItem   	:= oListBox:nAt

	Default aListBox	:= {}
	Default nItemMrk	:= 0 	//Item j?marcado
	Default cCodTrans	:= Space(6)

	If nItemMrk == 0  //Nenhum Item Marcado em Mem?ia
		If aListBox[nItem,SMEXISTMP]
			cCodTrans 				:=  aListBox[nItem,SMCODTRAN]
			nGfeVlr					:=  aListBox[nItem,SMVALOR]
			nPrzTransp 				:= 	aListBox[nItem,SMPRAZO]
			cRotaTransp 			:= 	aListBox[nItem,SMXROTA]
			dDtProgram				:=  sfCalcRota(dDataBase,cRotaTransp)
			aListBox[nItem,SMMARCA] := '1'
			nItemMrk 				:= nItem
		Else
			MsgAlert("Transportadora não cadastrada no Microsiga Protheus!")	//--"Transportadora n? cadastrada no Microsiga Protheus!"
		EndIf
	ElseIf nItemMrk == nItem //Item J?Marcado
		aListBox[nItem,SMMARCA] := '2'
		nItemMrk 	:= 0
		cCodTrans 	:=  ""
		nGfeVlr		:=  0
		nPrzTransp 	:= 	0
		cRotaTransp := 	""
		dDtProgram	:= CTOD("")

	Else //Marca o Item selecionado e desmarca o Item j?marcado anteriormente.
		If aListBox[nItem,SMEXISTMP]
			aListBox[nItem,SMMARCA] 	:= '1'
			aListBox[nItemMrk,SMMARCA] 	:= '2'
			nItemMrk 					:= nItem
			cCodTrans 					:=  aListBox[nItem,SMCODTRAN]
			nGfeVlr						:=  aListBox[nItem,SMVALOR]
			nPrzTransp 					:= 	aListBox[nItem,SMPRAZO]
			cRotaTransp 				:= 	aListBox[nItem,SMXROTA]
			dDtProgram					:=  sfCalcRota(dDataBase,cRotaTransp)

		Else
			MsgAlert("Transportadora não cadastrada no Microsiga Protheus!")	//--"Transportadora n? cadastrada no Microsiga Protheus!"
		EndIf
	EndIf

	oListBox:Refresh()

Return

/*/{Protheus.doc} sfGFEX010Slg
Função para desativar a exibição do Log 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 15/08/2022
@return variant, return_description
/*/
Static Function sfGFEX010Slg(nExibeLog)

	Default   nExibeLog   := 0
	//__nLogProc := nExibeLog
	//User Function GFEX0101
	//Local nRet := 1
	//0: Não apresentar
	//1: Somente erros
	//2: Sempre
	//Return nRet

	// Chama Função que seta o tipo de log que será exibido/ou não
	GFEX010Slg(nExibeLog)

Return



Static Function sfCalcRota(dInDtProgm,cInDiasRota)
	
	Local		aAreaOld	:= GetArea()
	Local		cRota		:=" "
	Local		nDiaEnt  	:= 0
	Local		dData    	:= dDataBase
	Local		aRota    	:= {}
	Local 		x

	If cInDiasRota == "Não encontrada frequência"
		Return dData
	EndIf
	
	cRota := cInDiasRota
	For x := 1 To Len(AllTrim(cRota)) Step 1
		AADD(aRota,{SubStr(cRota,x,1)})
	Next
	
	nDia := Dow(dDatabase)
	If Len(aRota) > 0
		While .T.
			If nDia > 7
				nDia := 1
			Endif
			nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
			If !Empty(nPos)
				nDiaEnt := Val(aRota[nPos][1])
				If nDiaEnt == Dow(dDatabase)
					dData := dDatabase
				Elseif (nDiaEnt - Dow(dDatabase)) > 0
					dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
				Else
					dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
				Endif
				Exit
			Endif
			nDia++
		End
	Endif
	
	If dInDtProgm > dData
		dData	:= dInDtProgm
	Endif
	
	RestArea(aAreaOld)

Return dData
