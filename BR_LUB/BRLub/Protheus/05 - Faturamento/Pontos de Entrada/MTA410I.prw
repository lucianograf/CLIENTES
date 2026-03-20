#INCLUDE "topconn.ch"
#INCLUDE "rwmake.ch"

/*/{Protheus.doc} MTA410I
(Ponto de entrada na inclusão de pedido de venda)
	Este ponto de entrada pertence à rotina de pedidos de venda, MATA410(). 
	Está localizado na rotina de gravação do pedido, A410GRAVA().
	 É executado durante a gravação do pedido, após a atualização de cada item.
	
@author MarceloLauschner
@since 04/12/2013
@version 1.0		

@return Sem retorno esperado

@example
(examples)

@see (links_or_references)
/*/
User Function MTA410I()
	
	Local	aAreaOld	:= GetArea()
	Local	cCodProd	:= SC6->C6_PRODUTO
	Local	cCfopPv		:= SC6->C6_CF
	Local	cCodVlDec	:= ""
	Local	cCodAjust	:= ""
	Local	cTipValor	:= "9"
	Local	cClasFis	:= Substr(SC6->C6_CLASFIS,2,2)
	Local	lGrvF3K		:= .F. 
	Local 	cPosIpi		:= Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_POSIPI")
	
	// Se a CST estiver em Branco assume do TES 
	If Empty(cClasFis)
		cClasFis	:= Posicione("SF4",1,xFilial("SF4") + SC6->C6_TES,"F4_SITTRIB")
	Endif
	
	// Se for Atrialub RS - Chamado 22.800 - Inclui automaticamente produtos na tabela F3K conforme regra de CFOP 
	If SM0->M0_ESTENT == 'RS' .And. (INCLUI .Or. ALTERA)
		lGrvF3K := .F.
		// Chamado 25993 - REvisão dos códigos de Ajuste x cfop x cst 
		// 5114	Remessa consignação			90	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS                                                                                                                                                                                                                    
		// 5405	VENDA MERC ST				60	OUTROS			RS052427	ANEXO V.B - AP.II,S.III,XX-PECAS,COMP.E ACES.P/PROD.AUTOP.                                                                                                                                                                                                  
		// 5655	VENDA LUBRIFICANTE ST		60	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS                                                                                                                                                                                                                    
		// 5656	VENDA LUB - Consumidor Fina 60	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS                                                                                                                                                                                                                   
		// 5663	Remessa Armazenagem			41	NÃO-INCIDÊNCIA	RS051510	ANEXO V.A - LIVRO I,11,XI -ARMAZEM-GERAL                                                                                                                                                                                                                    
		// 5905	Remessa Armazenagem			41	NÃO-INCIDÊNCIA	RS051510	ANEXO V.A - LIVRO I,11,XI -ARMAZEM-GERAL                                                                                                                                                                                                                    

		// VENDA DIFERIMENTO PARCIAL
		// Chamado 25816 - 19/04/2021
		If Alltrim(cCfopPv) $ "5102" .And. cClasFis == "51"
			cCodAjust	:= "RS052158"
			cCodVlDec	:= "0000170"
			cTipValor	:= "4"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5114" .And. cClasFis == "90"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5554#5908#6552#5910" .And. cClasFis == "41"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001003"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6659" .And. cClasFis == "41"
			cCodAjust	:= "RS051502"
			cCodVlDec	:= "0001001" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905#5663" .And. cClasFis == "41"
			cCodAjust	:= "RS051510"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905" 
			cCodAjust	:= "RS051511"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		// VENDA/BAIXA ATIVO
		ElseIf Alltrim(cCfopPv) $ "5551" .And. cClasFis == "40"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5911" .And. cClasFis == "40" 
			cCodAjust	:= "RS051004"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5906#5907#5665"
			cCodAjust	:= "RS051512"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5920" .And. cClasFis == "40"
			cCodAjust	:= "RS051011"
			cCodVlDec	:= "0001002" // Remessa de Vasilhames e Sacarias
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5405" .And. cClasFis == "60"
			cCodAjust	:= "RS052427"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5656#5655" .And. cClasFis == "60"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf cEmpAnt == "11" .And. Alltrim(cPosIpi) $ "84213990#84219999#84814000#84212100#84212300" .And.  Alltrim(cCfopPv) $ "5927#5910" .And. cClasFis == "60"
			cCodAjust	:= "RS052427"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf cEmpAnt == "11" .And. Alltrim(cPosIpi) $ "27101932#27101931" .And.  Alltrim(cCfopPv) $ "5910" .And. cClasFis == "60"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5119#5656#5655#5910#5912#5923#5927#5949" .And. cClasFis == "60"
			cCodAjust	:= "RS052001"
			cCodVlDec	:= "0001002" 
			lGrvF3K		:= .T.
		Endif
		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cClasFis)
			// Não faz nada por que já existe o cadastro 
			
		ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes	
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cClasFis
			F3K->F3K_VALOR		:= Iif(!Empty(cTipValor),cTipValor,"9")		// 9-Valor Contábil 
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())
			
			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")
			
		Endif
	//Se for Atrialub PR - Inclui automaticamente produtos na tabela F3K conforme regra de CFOP 
	ElseIf SM0->M0_ESTENT == 'PR' .And. (INCLUI .Or. ALTERA)
		lGrvF3K := .F.
		// VENDA DIFERIMENTO PARCIAL
		If Alltrim(cCfopPv) $ "5102" .And. cClasFis == "51"
			cCodAjust	:= "PR830001"
			cCodVlDec	:= "0000170"
			lGrvF3K		:= .T.
			cTipValor	:= "8"
		// REMESSA BRINDE
		ElseIf Alltrim(cCfopPv) $ "5910" .And. cClasFis == "41"
			cCodAjust	:= "PR809999"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// BONIFICAÇÃO DIFERIMENTO PARCIAL
		ElseIf Alltrim(cCfopPv) $ "5910" .And. cClasFis == "51"
			cCodAjust	:= "PR830001"
			cCodVlDec	:= "0000170" 
			lGrvF3K		:= .T.
			cTipValor	:= "8"
		// REM. ARMAZENAGEM
		ElseIf Alltrim(cCfopPv) $ "5905" .And. cClasFis == "50"
			cCodAjust	:= "PR840009"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.			
		// REM. ARMAZENAGEM
		ElseIf Alltrim(cCfopPv) $ "5663" .And. cClasFis == "50"
			cCodAjust	:= "PR840009"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.
		// REMESSA VASILHAME
		ElseIf Alltrim(cCfopPv) $ "5920" .And. cClasFis == "40"
			cCodAjust	:= "PR810171"
			cCodVlDec	:= "0000180" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// TRANSF. ATIVO
		ElseIf Alltrim(cCfopPv) $ "5555" .And. cClasFis == "41"
			cCodAjust	:= "PR800014"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// VENDA/BAIXA ATIVO
		ElseIf Alltrim(cCfopPv) $ "5551" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REM. EXPOSIÇÃO OU FEIRA
		ElseIf Alltrim(cCfopPv) $ "5914" .And. cClasFis == "40"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000180" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// RET. VASILHAME
		ElseIf Alltrim(cCfopPv) $ "5921" .And. cClasFis == "40"
			cCodAjust	:= "PR810171"
			cCodVlDec	:= "0000180" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA COMODATO
		ElseIf Alltrim(cCfopPv) $ "5908" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA TROCA - ATIVO
		ElseIf Alltrim(cCfopPv) $ "5949" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// BAIXA DE AVARIA
		ElseIf Alltrim(cCfopPv) $ "5927" .And. cClasFis == "41"
			cCodAjust	:= "PR800021"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA USO FORA DA EMPRESA
		ElseIf Alltrim(cCfopPv) $ "5554" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA CONSERTO
		ElseIf Alltrim(cCfopPv) $ "5915" .And. cClasFis == "50"
			cCodAjust	:= "PR840014"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// REMESSA CONSERTO
		ElseIf Alltrim(cCfopPv) $ "5916" .And. cClasFis == "50"
			cCodAjust	:= "PR840014"
			cCodVlDec	:= "0000190" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		// TRANSFERENCIA INTERESTADUAL DE LUBRIFICANTE 
		ElseIf Alltrim(cCfopPv) $ "6659" .And. cClasFis == "41"
			cCodAjust	:= "PR800003"
			cCodVlDec	:= "0000200" 
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		Endif
		
		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cClasFis)
			// Não faz nada por que já existe o cadastro 
			
		ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes	
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cClasFis
			F3K->F3K_VALOR		:= cTipValor 
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())
			
			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")
			
		Endif
	// Se for Redelog RS - Chamado 22.800 - Inclui automaticamente produtos na tabela F3K conforme regra de CFOP 
	ElseIf SM0->M0_ESTENT == 'RS' .And. (INCLUI .Or. ALTERA)
		lGrvF3K := .F.
		If Alltrim(cCfopPv) $ "5554#5908#6552"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001003"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905"
			cCodAjust	:= "RS051511"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5906#5907#5665"
			cCodAjust	:= "RS051512"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5920"
			cCodAjust	:= "RS051011"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		Endif
		DbSelectArea("F3K")
		DbSetOrder(1)
		If DbSeek(xFilial("F3K")+cCodProd+cCfopPv+cCodAjust+cClasFis)
			// Não faz nada por que já existe o cadastro 
			
		ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes	
			DbSelectArea("F3K")
			RecLock("F3K",.T.)
			F3K->F3K_FILIAL		:= xFilial("F3K")
			F3K->F3K_PROD		:= cCodProd
			F3K->F3K_CFOP		:= cCfopPv
			F3K->F3K_CODAJU		:= cCodAjust
			F3K->F3K_CST		:= cClasFis
			F3K->F3K_VALOR		:= "9"	// 9-Valor Contábil 
			F3K->F3K_CODREF		:= cCodVlDec
			F3K->(MsUnlock())
			
			U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"MTA410I")
			
		Endif		
	Endif
	RestArea(aAreaOld)

Return 
