#include "totvs.ch"

/*/{Protheus.doc} RM_VEN3
//PEGA CAMPO PARA LAYOUT DO VENDOR 
@author RAFAE MEYER   
@since 04/09/19
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User Function RM_VEN3()

	Local	cQry 

	Local	nval_parc 	:= " "

	cQry := "SELECT (SELECT SUM(E1_VALOR) " 
	cQry += "          FROM " + RetSqlName("SE1")+ " SE1 "	
	cQry += "         WHERE SE1.D_E_L_E_T_ <> '*' "
	cQry += "           AND E1_PREFIXO = '" + SE1->E1_PREFIXO + "' "
	cQry += "           AND E1_LOJA = '" + SE1->E1_LOJA + "' "
	cQry += "           AND E1_CLIENTE = '" + SE1->E1_CLIENTE + "' "
	cQry += "           AND E1_FILIAL = '" + xFilial("SE1") + "' "
	cQry += "           AND E1_NUM = '"+ SE1->E1_NUM + "' ) "
	cQry += "       - "
	cQry += "       ISNULL((SELECT SUM(E5_VALOR) "
	cQry += "                 FROM " + RetSqlName("SE5")+ " SE5 "	
	cQry += "                WHERE SE5.D_E_L_E_T_ <> '*' "
	cQry += "                  AND E5_NUMERO = '"+ SE1->E1_NUM +"' "
	cQry += "                  AND E5_LOJA = '" + SE1->E1_LOJA + "' "
	cQry += "                  AND E5_CLIFOR = '" + SE1->E1_CLIENTE + "' "
	cQry += "                  AND E5_PREFIXO = '" + SE1->E1_PREFIXO + "' "
	cQry += "                  AND E5_TIPO = 'NF ' "
	cQry += "                  AND E5_TIPODOC = 'CP' "
	cQry += "                  AND E5_SITUACA <> 'C' "
	cQry += "                  AND SE5.D_E_L_E_T_ <> '*' "
	cQry += "                  AND E5_FILIAL = '" + xFilial("SE5") + "' ),0) AS VALDUP, "
	cQry += "        POWER((1/(1+(C5_ZPJUROS/100))),cast(DATEDIFF(day,CONVERT(datetime,(E1_DATABOR)),CONVERT(datetime,(E1_VENCTO))) as float) / 30) AS INDICE, "
	cQry += "        (SELECT SUM(POWER((1/(1+(C5_ZPJUROS/100))),cast(DATEDIFF(day,CONVERT(datetime,(E1_DATABOR)),CONVERT(datetime,(E1_VENCTO))) as float) / 30))"
	cQry += "           FROM " + RetSqlName("SE1") + " E1 "
	cQry += "           JOIN " + RetSqlName("SC5") + " C5 "
	cQry += "             ON E1_PEDIDO = C5_NUM "
	cQry += "          WHERE E1.D_E_L_E_T_ <> '*' "
	cQry += "            AND C5.D_E_L_E_T_ <> '*' "
	cQry += "            AND E1_NUM = SE1.E1_NUM AND E1_FILIAL = C5_FILIAL) as INDTOT, "
	cQry += "        E1_VALOR AS VALOR, "
	cQry += "        C5_ZQPARC AS QTDPARCELAS, "
	cQry += "        C5_ZVALPAR AS VALPARC, "
	cQry += "        C5_ZPJUROS AS JUROSCOB "
	cQry += "  FROM " + RetSqlName("SE1") +" SE1 "
	cQry += "  JOIN " + RetSqlName("SC5") +" SC5 "
	cQry += "    ON E1_PEDIDO = C5_NUM "
	cQry += "   AND SC5.D_E_L_E_T_ <> '*' "
	cQry += "   AND C5_FILIAL = '" + xFilial("SC5")+ "'"
	cQry += " WHERE E1_NUM = '"+ SE1->E1_NUM +"' "
	cQry += "   AND E1_PARCELA = '" + SE1->E1_PARCELA +"' "
	cQry += "   AND E1_LOJA = '" + SE1->E1_LOJA + "'"
	cQry += "   AND E1_CLIENTE = '" + SE1->E1_CLIENTE + "' "
	cQry += "	AND E1_PREFIXO = '" + SE1->E1_PREFIXO + "' "
	cQry += "   AND E1_FILIAL = '" + xFilial("SE1") + "'"
	cQry += "   AND SE1.D_E_L_E_T_ <> '*' "
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBL",.T.,.T.)
	If TBL->(!Eof())
		nVal_parc	:=  TBL->INDICE * (TBL->VALDUP/TBL->INDTOT)
	Endif		
	TBL->(DbCloseArea())


Return(nVal_parc)