#include "topconn.ch"
#include "protheus.ch"

/*/{Protheus.doc} XMLCTE04
(Retorna centro de custo para as notas de frete pela Central XML - Customização atende necessidade retornar Centro de Custo de Vendedor Michelin)
	
@author MarceloLauschner
@since 27/01/2014
@version 1.0		

@return Character, Centro de custo do vendedor

@example
(examples)

@see (links_or_references)
/*/
User Function XMLCTE04()
	
	Local	cCCustoRet	:= ""
	
	If "41566683" $ SM0->M0_CGC // Atrialub ou Onix 
		cCCustoRet	:=  sfExecAtria()		
	Endif
	
	If Empty(cCCustoRet)		
		cCCustoRet	:= ParamIxb[1]
	Endif
	
Return cCCustoRet	


/*/{Protheus.doc} sfExecAtria
(Busca o Centro de Custo de maior proporção de Faturamento na Nota - Especifico Atrialub)
@type function
@author marce
@since 16/05/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExecAtria()
	
	Local	cQry 		:= ""
	Local	cCentroA3	:= ""
	Local	aAreaOld	:= GetArea()
	
	cQry := "SELECT A3_CC,A3_XCC,SUM(CASE WHEN B1_PROC = '000473' THEN D2_TOTAL ELSE 0 END) MICHELIN,SUM(D2_TOTAL) TOTAL "
	cQry += "  FROM "+RetSqlName("SF2")+" F2,"+RetSqlName("SA3")+" A3,"+RetSqlName("SD2")+ " D2, " + RetSqlName("SB1") +" B1 "
	cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
	cQry += "   AND A3_COD = F2_VEND1 "
	cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"' "
	cQry += "   AND B1.D_E_L_E_T_ =  ' ' "
	cQry += "   AND B1_COD = D2_COD "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "   AND D2.D_E_L_E_T_ =' ' "
	cQry += "   AND D2_LOJA = F2_LOJA "
	cQry += "   AND D2_CLIENTE = F2_CLIENTE "
	cQry += "   AND D2_SERIE = F2_SERIE "
	cQry += "   AND D2_DOC = F2_DOC "
	cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
	cQry += "   AND F2.D_E_L_E_T_ = ' ' "
	cQry += "   AND F2_DOC = '"+SF2->F2_DOC+"' "
	cQry += "   AND F2_SERIE = '"+SF2->F2_SERIE+"' "
	cQry += "   AND F2_FILIAL = '"+SF2->F2_FILIAL+"' "
	cQry += " GROUP BY A3_CC,A3_XCC "

	TcQuery cQry New Alias "QF2"
	
	If !Eof()
		If QF2->MICHELIN / QF2->TOTAL * 100  > 50 // Se mais de 50% da nota for Michelin
			cCentroA3	:= Iif(Empty(QF2->A3_XCC),QF2->A3_CC,QF2->A3_XCC)
		Else
			cCentroA3	:= QF2->A3_CC 
		Endif
	Endif
	QF2->(DbCloseArea())

	RestArea(aAreaOld)
	
Return cCentroA3


