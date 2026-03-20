#Include 'Protheus.ch'

/*/{Protheus.doc} TKEVALI
(Validação da linha dos produtos na tela de atendimento televendas)
@author MarceloLauschner
@since 05/06/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TKEVALI()
	
	Local	aAreaOld		:= GetArea()
	Local	aAreaSB1		:= SB1->(GetArea())
	Local 	nPProd    		:= aPosicoes[1][2]					// Posicao do Produto
	Local 	nPQtd     		:= aPosicoes[4][2]					// Posicao da Quantidade
	Local 	nPVrUnit  		:= aPosicoes[5][2]					// Posicao do Valor Unitario
	// Local 	nPVlrItem 		:= aPosicoes[6][2]					// Posicao do Valor do item
	Local 	nPTes	    	:= aPosicoes[11][2]					// Posicao do Tes
	Local 	lRetPe     		:= .T.								// Retorno da funcao
	// Local 	nValAnt4		:= M->UA_DESC4						// Valor anterior do desconto em cascata
	// Local 	nValAnt3		:= M->UA_DESC3						// Valor anterior do desconto em cascata
	// Local 	nValAnt2		:= M->UA_DESC2						// Valor anterior do desconto em cascata
	// Local 	nValAnt1		:= M->UA_DESC1						// Valor anterior do desconto em cascata
	Local	lIsAuto			:= IsBlind()
	local   lFV             := IsInCallStack( 'U_ICGERPED' )
	Local	nPPrcMax		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMAX"})
	Local	nPPrcMin		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPRCMIN"})
	Local	nPCodTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
	// Local	nPPrcTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_PRCTAB"})
	// Local	nPxComis1		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS1"})
	// Local	nPxComis2		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS2"})
	// Local	nPxComis3		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS3"})
	// Local	nPRegBnf		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})
	// Local	nPxFlex			:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XFLEX"})
	// Local	nPVlrTampa		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XVLRTAM"})
	Local	nPosLocal		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_LOCAL"})
	Local	nCF				:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_CF"})
	Local	aContLocal	:= {0,0}	// Posição 1 - Armazém 01 / Posição 2  - Armazém 02
	Local	nPosLin			:= 1
	Local	nX
	Local	nMxFor			:= 0
	Local	cVend1			:= ""
	Local	cVend2			:= ""
	// Local	cVend3			:= M->UA_VEND03 //SA1->A1_VEND03
	// Local	nPComis1 		:= 0
	// Local	nPComis2 		:= 0
	// Local	nPComis3 		:= 0
	// Local	nPxPA2NUM		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2NUM"})
	// Local	nPxPA2LIN		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XPA2LIN"})
	Local	cCfopTransf		:= "659/658/557/552/409/408/209/208/156/155/152/151" // Válido para Cfops iniciados com 5 e 6 ( 5659/6659 5658/6658 etc.)
	Local	nSumVolum		:= 0
	Local   cMV_ESTADO		:= GetMv("MV_ESTADO")
	Local 	iX 

	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If Type("cCondOld") == "U"
		Public 	cCondOld	:= M->UA_CONDPG
	Endif
	
	If !U_BFCFGM25("TKEVALI")
		RestArea(aAreaOld)
		Return .T. 
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
	// 09/03/2018 - Sumarizo os volumes do pedido
	For iX := 1 To Len(aCols)
		DbSelectArea("SB1")
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+aCols[iX][nPProd])
			If SB1->B1_PROC == "000468" .And. aCols[iX][nPQtd] > 0
				nSumVolum	+= (aCols[iX][nPQtd] * SB1->B1_QTELITS ) / 20 
			Endif
		Endif 
	Next
	RestArea(aAreaSB1)
	
	// Se for validação do cabeçalho- irá validar todas as linhas
	If FwIsInCallStack("TK273GETOK")
		nMxFor		:= Len(aCols)
		
		// Deleta automaticametne a linha pois usuário não tem capacidade de interpretar o erro e faltou treinamento
		// Chamado 22.975 
		If Val(M->UA_OPER) == 3 // Atendimento
			For nX	:= nPosLin To nMxFor
				If Empty(aCols[nX][nPProd])
					aCols[nX][Len(aHeader)+1]	:= .T. 
				Endif
			Next nX 
		Endif
		
		// IAGO 23/06/2015 Chamado(11396)
		If !lIsAuto .And. Empty(cVend1) .and. Val(M->UA_OPER) <> 1 .and. !lFV
			if !lFV
				Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Sem vendedor!","Campo de vendedor não está preenchido.","Favor verificar o cadastro do cliente!")
			endif
		EndIf
		
		If !lIsAuto .And. !Empty(M->UA_OPER) .And. Val(M->UA_OPER) == 1 // 1=Faturamento
			If (dDataBase - M->UA_EMISSAO) > 14 .and. !lFV
				lRetPe	:= .F.
				if ! lIsAuto 
					Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Orcamento expirou","Este orçamento já está emitido há mais de 14 dias no sistema.","Não será possível converter o mesmo em Pedido de Venda! Favor incluir novo orçamento para gerar um novo processo de liberação de alçadas")
				else
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - Este orçamento já está emitido há mais de 14 dias no sistema. Não será possível converter o mesmo em Pedido de Venda! Favor incluir novo orçamento para gerar um novo processo de liberação de alçadas" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				endif								
			Endif
		Endif
		
		// 30/09/2018 - Valida que seja informado obrigatoriamente o número da Ordem de Compra
		If M->UA_CLIENTE $ "013581"
			If ( Empty(M->UA_XPEDCLI) .Or. Len(Alltrim(M->UA_XPEDCLI)) <> 10 ) .and. !lFV
				lRetPe	:= .F.
				If !lIsAuto
					Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),"Pedido digitado para um cliente 'Dpaschoal' e não foi informado o campo 'O.C. Cliente' com 10 dígitos. ","Favor preencher e Confirmar novamente!")
				Else
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - Pedido digitado para um cliente 'Dpaschoal' e não foi informado o campo 'O.C. Cliente' com 10 dígitos. Favor preencher e Confirmar novamente!" +ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Endif
			Endif
		Endif
				
		// 06/07/2016 - Calculo de comissão baseado em desconto médio do pedido
		// Efetua o calculo de comissões
		U_BFFATM32(.F./*lIsSC5*/,.T./*lIsSUA*/,cVend1/*cInVend1*/,cVend2/*cInVend2*/,aCols/*aInAcols*/,M->UA_CLIENTE/*cInCli*/,M->UA_LOJA/*cInLoja*/,M->UA_EMISSAO/*dInEmissao*/)
		
	Else
		// Somente valida a linha em questão
		nPosLin		:= N
		nMxFor		:= nPosLin
	Endif
	
	For nX	:= nPosLin To nMxFor
		
		If !aCols[nX][Len(aHeader)+1]
			If  !Empty(M->UA_OPER) .And. Val(M->UA_OPER) <> 3  // 1=Faturamento;2=Orcamento;3=Atendimento
				If 	Empty(aCols[nX][nPProd]) 	.Or. Empty(aCols[nX][nPVrUnit]) .Or. Empty(aCols[nX][nPTes])
					Help(" ",1,"A010VAZ")
					lRetPe := .F.
					FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - Produto, Valor unitário ou tes em branco ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Endif
			Endif
			If Val(M->UA_OPER) <> 3	// Se não for atendimento -
				// Efetua as validações
				// Se o CFOP do Item for de Transferência de mercadoria não valida preço mínimo e máximo
				// 29/09/2017 - Chamado 19.040 
				if !lFV
					If lRetPe .And. Substr(aCols[nX][nCF],2,3) $ cCfopTransf
						// Nenhuma ação necessária
					
					ElseIf lRetPe .And. Round(aCols[nX][nPVrUnit],2) < Round(aCols[nX][nPPrcMin],2)
						// Se estiver na menor faixa de preço e for orçamento, exibirá apenas alerta sem bloqueio
						If aCols[nX][nPCodTab] $ "M01#0AA#T07#T14#T21#T28#T35#T42#T49#T56#T63#T70" .And. Val(M->UA_OPER) == 2 // Orcamento
							If !lIsAuto
								Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" PRECO MINIMO","O produto '"+aCols[nX][nPProd]+"' está ABAIXO do preço mínimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " para a faixa de volumes na tabela '"+aCols[nX][nPCodTab]+"'!","Este atendimento está sujeito a liberação de alçadas!")
							Else
								FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/,"TKEVALI.PRW - Valor digitado " + cValToChar(Round(aCols[nX][nPVrUnit],2)) + " - Valor minimo " + cValToChar(Round(aCols[nX][nPPrcMin],2)) + " - Valor Máximo " + cValToChar( Round(aCols[nX][nPPrcMax],2)) /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							Endif
							// 21/09/2015 - Permite que Granel passe na validação de preço abaixo da 0AA mesmo como 1-Faturamento
						ElseIf aCols[nX][nPCodTab] $ "M01#0AA" .And. Val(M->UA_OPER) == 1 .And. aCols[nX][nPProd] $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
							If !lIsAuto
								Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" PRECO MINIMO","O produto '"+aCols[nX][nPProd]+"' está ABAIXO do preço mínimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " para a faixa '0AA' ou 'M01'! ","Sujeito a liberação de alçadas!")
							Endif
						Else
							If !lIsAuto
								Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" PRECO MINIMO","O preço digitado do produto '"+aCols[nX][nPProd]+"' está ABAIXO do preço mínimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " permitido para esta faixa de preços!","Atendimento estará sujeito a liberação de alçadas!")
							Else
								FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - O preço digitado do produto '"+aCols[nX][nPProd]+"' está ABAIXO do preço mínimo R$ " + Transform(aCols[nX][nPPrcMin],"@E 999,999.99") + " permitido para esta faixa de preços! " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							Endif
							lRetPe	:= .F.
						Endif
					ElseIf lRetPe .And. Round(aCols[nX][nPVrUnit],2) > Round(aCols[nX][nPPrcMax],2)
						If !lIsAuto
							MsgAlert("O preço digitado do produto '"+aCols[nX][nPProd]+"' está ACIMA do preço máximo R$ " + Transform(aCols[nX][nPPrcMax],"@E 999,999.99") + " permitido para esta faixa de preços!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Preço acima do máximo desta faixa!")
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW - O preço digitado do produto '"+aCols[nX][nPProd]+"' está ACIMA do preço máximo R$ " + Transform(aCols[nX][nPPrcMax],"@E 999,999.99") + " permitido para esta faixa de preços!" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Endif
						lRetPe	:= .F.
					Endif
				endif
				
				If aCols[nX,nPosLocal] == "01"
					aContLocal[1] += 1
				ElseIf aCols[nX,nPosLocal] == "02"
					aContLocal[2] += 1
				Endif
				
				If aContLocal[1] > 0 .And. aContLocal[2] > 0
					If !lIsAuto
						Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" ARMAZENS DIFERENTES", "Este pedido contém produtos digitados em armazéns diferentes. ", "A digitação deve ser feita somente usando o mesmo armazém para todos os itens ou em pedidos separados OBRIGATORIAMENTE!")
					Else
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW - Este pedido contém produtos digitados em armazéns diferentes. A digitação deve ser feita somente usando o mesmo armazém para todos os itens ou em pedidos separados OBRIGATORIAMENTE!!" = ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) /*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					Endif
					lRetPe	:= .F.
				Endif
				// 30/04/2017 - Chamado 18042 - Validar CFOP na digitação do orçamento também. 
				DbSelectArea("SA1")
				DbSetOrder(1)
				MsSeek(xFilial("SA1")+M->UA_CLIENTE+M->UA_LOJA)
				If SA1->A1_EST $ cMV_ESTADO
					If aCols[nX][nCF] > "6000"
						If !lIsAuto
							Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Cfop", "CFOP inválido para o produto '"+aCols[nX][nPProd]+"'", "Venda para dentro do estado não permite CFOP maior que 6000")
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - CFOP inválido para o produto '"+aCols[nX][nPProd]+"'" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Endif
						lRetPe	:= .F.
					Endif
				Else
					If aCols[nX][nCF] < "6000"
						If !lIsAuto
							Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" CFOP","CFOP inválido para o produto '"+aCols[nX][nPProd]+"'","Venda para fora do estado deve usar CFOP maior que 6000")
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "TKEVALI.PRW  - CFOP inválido para o produto '"+aCols[nX][nPProd]+"'" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Endif
						lRetPe	:= .F.
					Endif
				Endif
				
				
			Endif
			// 28/10/2016 - Chamado 16236 - Calcular ST forçado para produto bonificado PR
			If lRetPe .And. cFilAnt == "03" .And. aCols[nX][nPProd] == Padr("42100300",TamSX3("UB_PRODUTO")[1]) .And. M->UA_TIPOCLI == "R"
				Hlp(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" TP CLIENTE", "Foi encontrado o produto '42100300' digitado neste pedido/orçamento e o Tipo do Cliente é diferente de 'Solidario' ", "Altere o campo 'Tipo de Cliente' para 'S-Solidário' ")
				lRetPe	:= .F.
			Endif
		Endif
	Next
	
	RestArea(aAreaOld)
Return lRetPe

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/04/2024
@param cTitle, character, Titulo da janela
@param cFail, character, Informações sobre a falha
@param cHelp, character, Informações com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )
