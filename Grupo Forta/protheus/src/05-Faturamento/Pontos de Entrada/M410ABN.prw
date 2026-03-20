
/*/{Protheus.doc} M410ABN
(Ponto Entrada ao abandonar pedido de venda ,Se abandonar inclusão desfaz reserva de Tambores     )
	
@author MarceloLauschner
@since 06/08/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (http://tdn.totvs.com/display/public/mp/M410ABN+-+Cancelamento+de+pedido)
/*/
User Function M410ABN()
	
	Local		aAreaOld	:= GetArea()

	If GetNewPar("GM_ATF3KAU",.T.)
		sfAtuaF3k1()
	Endif 

	RestArea(aAreaOld)

Return 


/*/{Protheus.doc} MLF3KATU
Função de usuário para atualização da F3k 
@type function
@version  
@author Lauschner Consulting - Marcelo Alberto Lauschner
@since 14/09/2025
@return variant, return_description
/*/
User Function MLF3KATU()

	Local		aAreaOld	:= GetArea()

	If GetNewPar("GM_ATF3KAU",.T.)
		
		// SC6 precisa estar posicionado 

		DbSelectArea("SF4")
		DbSetOrder(1)
		DbSeek(xFilial("SF4") + SC6->C6_TES)
		
		sfAtuF3k2()

	Endif 

	RestArea(aAreaOld)

Return 
/*/{Protheus.doc} sfAtuaF3k1
// Função para gravar Produtos na tabela de Ajustes de Códigos
// Foi usado neste ponto de entrada só para fazer uma carga a partir de pedidos já encerrados.  
@author Marcelo Alberto Lauschner
@since 18/04/2019
@version 1.0
@return Nil
@type function
/*/
Static Function sfAtuaF3k1()

	Local	iW
	Local		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local		nPxItem		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})

	For iW := 1 To Len(aCols)
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+M->C5_NUM+aCols[iW,nPxItem]+aCols[iW,nPxProd])
		//DbSeek(xFilial("SC6")+"002793")
		//While !Eof()

		DbSelectArea("SF4")
		DbSetOrder(1)
		DbSeek(xFilial("SF4") + SC6->C6_TES)
		sfAtuF3k2()

		//DbSelectArea("SC6")
		//DbSkip()
		//Enddo
	Next

Return



User Function XXF3KFORCE(cInPedido)

	Local 	cKeyC5		:= xFilial("SC6")+ cInPedido
	Private ALTERA	:= .T.
	Private INCLUI	:= .F.

	//RPCSetType(3)
	//RPCSetEnv("02","04","","","","",{"SC5","SC6","F3K"}) // Abre todas as tabelas.


	DbSelectArea("SC5")
	DbSetOrder(1)
	//Set Filter To C5_NUM $ "216240#"
	//While SC5->(!Eof())
	If DbSeek(xFilial("SC5")+cInPedido)


		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+SC5->C5_NUM)
		While SC6->(!Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == cKeyC5

			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Pedido: " + SC6->C6_NUM + " Item: " + SC6->C6_ITEM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4") + SC6->C6_TES)
			sfAtuF3k2()

			DbSelectArea("SC6")
			DbSkip()
		Enddo
	Endif
	//	DbSelectArea("SC5")
	//	SC5->(DbSkip())
	//Enddo

Return


/*/{Protheus.doc} sfAtuF3k2
// Efetua gravação na tabela F3K
@author Marcelo Alberto Lauschner
@since 18/04/2019
@version 1.0
@return NIl 
@type function
/*/
Static Function sfAtuF3k2()

	Local	aAreaOld	:= GetArea()
	Local	cCodProd	:= SC6->C6_PRODUTO
	Local	cCfopPv		:= SC6->C6_CF
	Local	cCodVlDec	:= ""
	Local	cCodAjust	:= ""
	Local	cTipValor	:= "9"
	Local	cSitTrib	:= Substr(SC6->C6_CLASFIS,2,2)
	Local 	cClasFis	:= Substr(SC6->C6_CLASFIS,1,3)
	Local	lGrvF3K		:= .F.
	Local 	cB1Origem	:= Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_ORIGEM")

	// Se a CST estiver em Branco assume do TES
	If Empty(cClasFis) .Or. Len(Alltrim(cClasFis)) <> 3 
		cClasFis	:= cB1Origem + Posicione("SF4",1,xFilial("SF4") + SC6->C6_TES,"F4_SITTRIB")
		cSitTrib	:= Substr(cClasFis,2,2)
	Endif

	// PR - 0601
	If cFilAnt  $ "0601" .And. (INCLUI .Or. ALTERA)
		//BAUME (0601)
		//CFOP		CST	COD. AJUSTE
		//5102/6102		S/CODIGO
		//5202/6202		S/CODIGO
		//5655			S/CODIGO
		//5656			S/CODIGO
		//5910/6910		S/CODIGO
		//5914		40	PR810071
		//5915/6915	50	PR840007
		//5916/6916	50	PR840007
		//5912/6912	50	PR840005
		//5913/6913	50	PR840005

		If Alltrim(cCfopPv) $ "5914" .And. cSitTrib == "40"
			cCodAjust	:= "PR810071"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5915#6915" .And. cSitTrib == "50"
			cCodAjust	:= "PR840007"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5916#6916" .And. cSitTrib == "50"
			cCodAjust	:= "PR840007"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5912#6912" .And. cSitTrib == "50"
			cCodAjust	:= "PR840005"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5913#6913" .And. cSitTrib == "50"
			cCodAjust	:= "PR840005"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		Endif

		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cSitTrib)
			// Não faz nada por que já existe o cadastro

		ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cSitTrib
			F3K->F3K_VALOR		:= Iif(!Empty(cTipValor),cTipValor,"9")		// 9-Valor Contábil
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())

			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")

		Endif

	// SC - 0401 
	ElseIf cFilAnt $ '0401' .And. (INCLUI .Or. ALTERA)
		//DISTRIBUIDORA (0401)
		//CFOP		CST	COD.AJUSTE
		//5102/6102		S/CODIGO
		//5119/6119		S/CODIGO
		//5202/6202		S/CODIGO
		//5405			S/CODIGO
		//5411/6411		S/CODIGO
		//5655/6655		S/CODIGO
		//5656/6656		S/CODIGO
		//5661/6661		S/CODIGO
		//5910/6910		S/CODIGO
		//5914		90	SC810165
		//5923/6923		S/CODIGO
		//5927			S/CODIGO
		//5949/6949		S/CODIGO
		//5404			S/CODIGO
		//5915/6915	50	SC840007
		//5916/6916	50	SC840008
		//5912/6912	50	SC840021
		//5913/6913	50	SC840021
		//5905	    50  SC840004 0000180

		If Alltrim(cCfopPv) $ "5914" .And. cSitTrib == "90"
			cCodAjust	:= "SC810165"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5915#6915" .And. cSitTrib == "50"
			cCodAjust	:= "SC840007"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5916#6916" .And. cSitTrib == "50"
			cCodAjust	:= "SC840008"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5912#6912" .And. cSitTrib == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5913#6913" .And. cSitTrib == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905#6905" .And. cSitTrib == "50"
			cCodAjust	:= "SC840004"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		Endif

		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cSitTrib)
			// Não faz nada por que já existe o cadastro

		ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cSitTrib
			F3K->F3K_VALOR		:= Iif(!Empty(cTipValor),cTipValor,"9")		// 9-Valor Contábil
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())

			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")

		Endif
	// SC 0301 
	ElseIf cFilAnt $ '0301' .And. (INCLUI .Or. ALTERA)
		//COMERCIAL (0301)
		//CFOP				CST	COD.AJUSTE
		//*5101/6101		S/CODIGO
		//*5102/6102(prod. Importados)	100, 200, 600	SC850065
		//*5102/6102		20	SC820028
		//*5102/6102(não importados)		S/CODIGO
		//*5202/6202		S/CODIGO
		//*5655				110, 210	SC850065
		//*5656				110, 210	SC850065
		//*5901/6901		50	SC840007
		//*5910/6910(prod.importado)	100, 200, 600	SC850065
		//*5910/6910(NÃO IMPORTADO)		S/CODIGO
		//*5912/6912		50	SC840021
		//*5913/6913		50	SC840021
		//*5914				90	SC810165
		//*5915/6915		41	SC840007
		//*5916/6916		41	SC840008
		//*5949/6949(prod.importados)	100, 200, 110, 210	SC850065
		//*5949/6949(não importados)		S/CODIGO
		//*5927				S/CODIGO
		//*6655				110, 130, 210, 230	SC800003
		//*6656				100, 200	SC850065
		//*7102				141, 241	SC800002
		//*7949				141, 241	SC800002
		If Alltrim(cCfopPv) $ "5102#6102" .And. cClasFis $ "100#200#600"
			cCodAjust	:= "SC850065"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5102#6102" .And. cSitTrib == "20"
			cCodAjust	:= "SC820028"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5655#5656" .And. cClasFis $ "110#210"
			cCodAjust	:= "SC850065"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5901#6901" .And. cSitTrib == "50"
			cCodAjust	:= "SC840007"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905#6905" .And. cSitTrib == "50"
			cCodAjust	:= "SC840004"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.		
		ElseIf Alltrim(cCfopPv) $ "5910#6910" .And. cClasFis $ "100#200#600"
			cCodAjust	:= "SC850065"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5912#6912" .And. cSitTrib == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5913#6913" .And. cSitTrib == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5914" .And. cSitTrib == "90"
			cCodAjust	:= "SC810165"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5915#6915" .And. cSitTrib == "41"
			cCodAjust	:= "SC840007"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5916#6916" .And. cSitTrib $ "41#50"
			cCodAjust	:= "SC840008"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5949#6949" .And. cClasFis $ "100#200#110#210"
			cCodAjust	:= "SC850065"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6655" .And. cClasFis $ "110#1303210#230"
			cCodAjust	:= "SC800003"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6656" .And. cClasFis $ "100#200"
			cCodAjust	:= "SC850065"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "7102#7949" .And. cClasFis $ "141#241"
			cCodAjust	:= "SC800002"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		Endif

		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cSitTrib)
			// Não faz nada por que já existe o cadastro

		ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cSitTrib
			F3K->F3K_VALOR		:= Iif(!Empty(cTipValor),cTipValor,"9")		// 9-Valor Contábil
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())

			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")

		Endif
	// SC - 0101 
	ElseIf cFilAnt $ '0101#0104' .And. (INCLUI .Or. ALTERA)
		//FORTA TECH (0101)
		//CFOP			CST	COD.AJUSTE
		//5102/6102			S/CODIGO
		//*5102/6102		20	SC820028
		//5117/6117			S/CODIGO
		//5202/6202			S/CODIGO
		//6552			90	SC810193
		//5554/6554		50	SC840011
		//6557				S/CODIGO
		//5554/6554			S/CODIGO
		//5556/6556			S/CODIGO
		//5908/6908			SC800006
		//5909/6909			SC800006
		//5910/6910			S/CODIGO
		//*5914			90	SC810165
		//5923/6923			S/CODIGO
		//5927				S/CODIGO
		//5933/6933			S/CODIGO
		//5949/6949			S/CODIGO
		//6108				S/CODIGO
		//*5915/6915		50	SC840007
		//*5916/6916		50	SC840008
		//*5912/6912		50	SC840021
		//*5913/6913		50	SC840021
		// 5152/6152 		51 	SC830073 
		// 6910				30  SC800003
		// 6117				30	SC800003
		// 6119				30	SC800003
		// 6655/6656		30	SC800003
		// 5914				40	SC810165
		// 5908/6908		41	SC800006
		// 5949/6949		41	SC800001
		// 5552				40	SC810192
		// 6552				40	SC810193
		// 5557				40	SC810195
		// 7102
	
		If Alltrim(cCfopPv) $ "5152#6152" .And. cSitTrib == "51"
			cCodAjust	:= "SC830073"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf  Alltrim(cCfopPv) $ "5102#6102" .And. cSitTrib == "20"
			cCodAjust	:= "SC820028"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905#6905" .And. cSitTrib == "50"
			cCodAjust	:= "SC840004"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.		
		ElseIf Alltrim(cCfopPv) $ "5912#6912" .And. cSitTrib == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5913#6913" .And. cSitTrib == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5914" .And. cSitTrib == "90"
			cCodAjust	:= "SC810165"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5914" .And. cSitTrib == "40"
			cCodAjust	:= "SC810165"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5915#6915" .And. cSitTrib == "50"
			cCodAjust	:= "SC840007"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5916#6916" .And. cSitTrib == "50"
			cCodAjust	:= "SC840008"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5916#6916" .And. cSitTrib == "41"
			cCodAjust	:= "SC840008"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5949#6949" .And. cClasFis $ "100#200#110#210"
			cCodAjust	:= "SC850065"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5949#6949" .And. cSitTrib == "41"
			cCodAjust	:= "SC800001"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6655" .And. cClasFis $ "110#1303210#230"
			cCodAjust	:= "SC800003"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6656" .And. cClasFis $ "100#200"
			cCodAjust	:= "SC850065"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "7102#7949" .And. cClasFis $ "141#241"
			cCodAjust	:= "SC800002"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "7102" .And. cSitTrib == "41"
			cCodAjust	:= "SC800002"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6910" .And. cSitTrib $ "30"
			cCodAjust	:= "SC800003"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6117" .And. cSitTrib $ "30"
			cCodAjust	:= "SC800003"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6119" .And. cSitTrib $ "30"
			cCodAjust	:= "SC800003"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6655#6656" .And. cSitTrib $ "30"
			cCodAjust	:= "SC800003"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5552" .And. cSitTrib $ "40"
			cCodAjust	:= "SC810192"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6552" .And. cSitTrib $ "40"
			cCodAjust	:= "SC810193"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5554#6554" .And. cSitTrib $ "50"
			cCodAjust	:= "SC840011"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5557" .And. cSitTrib $ "40"
			cCodAjust	:= "SC810195"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
		Endif

		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cSitTrib)
			// Não faz nada por que já existe o cadastro

		ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cSitTrib
			F3K->F3K_VALOR		:= Iif(!Empty(cTipValor),cTipValor,"9")		// 9-Valor Contábil
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())

			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")

		Endif

	Endif
	RestArea(aAreaOld)

Return
