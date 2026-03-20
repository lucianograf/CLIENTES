#include "protheus.ch"

/*/{Protheus.doc} M410LIOK
(Validação na linha do pedido de venda )

@author MarceloLauschner
@since 11/11/2013
@version 1.0

@return logico, retorna função GMFATM02 que verifica mudanças de preços

@example
(examples)

@see (links_or_references)
/*/
User Function M410LIOK()
	
	Local	aAreaOld		:= GetArea()
	Local	nPProd  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local	nPTes	  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	Local	nPxPA2NUM		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2NUM"})
	Local	nPxPA2LIN		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2LIN"})
	
	Local	nPPrcMax		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMAX"})
	Local	nPPrcMin		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPRCMIN"})
	Local	nPCodTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
	Local	nPVrUnit   		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	Local	nPxCF			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})
	Local	nPxComis1		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_COMIS1"})
	Local	nPxComis2		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_COMIS2"})
	Local	nPxComis3		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_COMIS3"})
	Local	nPPrcTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	Local	nPNumPc			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_NUMPCOM"})
	Local	nPItemPc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEMPC"})
	Local	lRet			:= .T.
	Local	cVend1			:= M->C5_VEND1
	Local	cVend2			:= M->C5_VEND2
	Local	cVend3			:= M->C5_VEND3
	Local	cCfopTransf		:= "659/658/557/552/409/408/209/208/156/155/152/151" // Válido para Cfops iniciados com 5 e 6 ( 5659/6659 5658/6658 etc.)
	
	Local	nPComis1,nPComis2,nPComis3
	
	//Não esta validando em tela, pois é da empresa 123 Pneu.
	If FWCodEmp() == '10'
		RestArea(aAreaOld)
		Return .T. 
	EndIf
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M410LIOK")
		Return .T. 
	Endif
	
	
	If Type("l410Auto") <> "U" .And. l410Auto
		// Validação adicionada em 30/09/2013 para impedir que o pedido prossiga, em casos que haja controle de tanques e não esteja preenchida a informação de
		If M->C5_TIPO == "N" .And. aCols[n,nPProd] $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
			If !aCols[n,Len(aHeader)+1] .And. (Empty(aCols[n,nPxPA2NUM]) .Or. Empty(aCols[n,nPxPA2LIN]))
				lRet := .F.
			Endif
		Endif
	Endif
	
	// Validação adicionada em 30/09/2013 para impedir que o pedido prossiga, em casos que haja controle de tanques e não esteja preenchida a informação de
	If lRet .And. M->C5_TIPO == "N" .And. aCols[n,nPProd] $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
		If !aCols[n,Len(aHeader)+1] .And. (Empty(aCols[n,nPxPA2NUM]) .Or. Empty(aCols[n,nPxPA2LIN])) .And. !(Alltrim(aCols[n,nPxCF]) $ "5927#5926")// .And. !Alltrim(aCols[n,nPTes]) $ "708"
			If !IsBlind()
				MsgAlert("Este produto requer que haja o controle de Patrimônio. Favor redigitar o item!","Controle de Patrimônio")
			Endif
			lRet := .F.
		Endif
	Endif
	
	// Validação adicionada em 28/02/018 impedir que o pedido prossiga, em casos que haja controle de tanques e não esteja preenchida a informação de 
	If lRet .And. M->C5_TIPO == "B" .And. aCols[n,nPProd] $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
		If !aCols[n,Len(aHeader)+1] .And. (Empty(aCols[n,nPNumPc]) .Or. Empty(aCols[n,nPItemPc])) .And. !(Alltrim(aCols[n,nPxCF]) $ "5927#5926")// .And. !Alltrim(aCols[n,nPTes]) $ "708"
			If !IsBlind()
				MsgAlert("Para este tipo de Pedido com produto que controla Patrimônio é necessário incluir primeiro na tabela PA3!","Controle de Patrimônio")
			Endif
			lRet := .F.
		Endif
	Endif
	
	// Validação adicionada em 05/06/2014 para validar preços minimos e máximos permitidos na digitação de pedidos
	If lRet .And. M->C5_TIPO == "N" .And. !aCols[n,Len(aHeader)+1] .And. !( ("#"+Alltrim(aCols[n][nPProd])+"#") $ GetNewPar("BF_OM10PRX","#AI1590#AI1591#E15020#"))
		
		// Se o CFOP do Item for de Transferência de mercadoria não valida preço mínimo e máximo
		// 29/09/2017 - Chamado 19.040 
		If Substr(aCols[n][nPxCF],2,3) $ cCfopTransf
			// Nenhuma ação necessária
			
		// Efetua as validações referente a tabelas de preços
		ElseIf aCols[n][nPVrUnit] < aCols[n][nPPrcMin]
			// Chamado 27080 - Se for Onix e vier da integração ICMais - só gera alerta se bloquear 			
			If cEmpAnt $ "11" .And. !Empty(M->C5_X_NCENT)
				FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "O preço digitado do produto '"+aCols[n][nPProd]+"' está ABAIXO do preço mínimo R$ " + Transform(aCols[n][nPPrcMin],"@E 999,999.99") + " permitido para esta faixa de preços!" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				MsgAlert("O preço digitado do produto '"+aCols[n][nPProd]+"' está ABAIXO do preço mínimo R$ " + Transform(aCols[n][nPPrcMin],"@E 999,999.99") + " permitido para esta faixa de preços!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Preço abaixo do mínimo desta faixa! Pedido será submetido a análise de Alçadas ! Continua?")
			ElseIf !IsBlind()
				lRet := MsgYesNo("O preço digitado do produto '"+aCols[n][nPProd]+"' está ABAIXO do preço mínimo R$ " + Transform(aCols[n][nPPrcMin],"@E 999,999.99") + " permitido para esta faixa de preços!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Preço abaixo do mínimo desta faixa! Pedido será submetido a análise de Alçadas ! Continua?")
			Endif
			
		ElseIf aCols[n][nPVrUnit] > aCols[n][nPPrcMax]
			If cEmpAnt $ "11" .And. !Empty(M->C5_X_NCENT)
				FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "O preço digitado do produto '"+aCols[n][nPProd]+"' está ACIMA do preço máximo R$ " + Transform(aCols[n][nPPrcMax],"@E 999,999.99") + " permitido para esta faixa de preços!"+ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				MsgAlert("O preço digitado do produto '"+aCols[n][nPProd]+"' está ACIMA do preço máximo R$ " + Transform(aCols[n][nPPrcMax],"@E 999,999.99") + " permitido para esta faixa de preços!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Preço acima do máximo desta faixa!")			
			ElseIf !IsBlind()
				MsgAlert("O preço digitado do produto '"+aCols[n][nPProd]+"' está ACIMA do preço máximo R$ " + Transform(aCols[n][nPPrcMax],"@E 999,999.99") + " permitido para esta faixa de preços!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Preço acima do máximo desta faixa!")
			Endif
			lRet := .F.
		Endif
		
	Endif
	
Return lRet
