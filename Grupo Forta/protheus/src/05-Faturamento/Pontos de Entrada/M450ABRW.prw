
/*/{Protheus.doc} M450ABRW
Ponto de Entrada para filtrar clientes na rotina de Análise Crédito Pedido 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/07/2021
@return variant, Query auxiliar para filtrar pedidos na analise de crédito por cliente
@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784592)
/*/
User Function M450ABRW()
	
	//If ExistBlock("M450ABRW")
	//		cQuery := ExecBlock('M450ABRW',.F.,.F.,{ cQuery })
	//	EndIf
	Local		aAreaOld	:= GetArea()	
	Local		cQryRet		:= ParamIxb[1]
	Local		cQryAux		:= ""
	
	
	// Somente usuários previamente definidos poderão liberar pedidos de todos os valores. Demais só terão acesso a pedidos conforme limite de parametro
	If __cUserId $ GetNewPar("GF_M450ABR","000000")  // Marcelo # Silvana  ( Marcelo por causa de Testes ) 
		// Mesmo não precisando filtrar os clientes por valor dos pedidos, executa filtro por Filial para restringir clientes com pedidos por filial
		cQryAux	+= " AND SC9.C9_FILIAL = '"+xFilial("SC9")+"' "
		cQryRet += cQryAux 		
	Else                                                                      
		cQryAux	+= " AND (SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQryAux += "        FROM "+RetSqlName("SC9") + " C9B "
		cQryAux += "       WHERE C9B.D_E_L_E_T_ = ' ' "
		cQryAux += "         AND C9B.C9_PEDIDO = SC9.C9_PEDIDO "
		cQryAux += "         AND C9B.C9_CLIENTE = SC9.C9_CLIENTE "
		cQryAux += "         AND C9B.C9_LOJA = SC9.C9_LOJA "                                     
		cQryAux += "         AND C9B.C9_FILIAL = SC9.C9_FILIAL "
		cQryAux += "         AND C9B.C9_BLCRED NOT IN ('  ','10','ZZ','09' )) > 0 "
		cQryAux	+= " AND SC9.C9_FILIAL = '"+xFilial("SC9")+"' "
		cQryRet += cQryAux 		
	Endif
	
	RestArea(aAreaOld)

Return cQryRet 
	
	