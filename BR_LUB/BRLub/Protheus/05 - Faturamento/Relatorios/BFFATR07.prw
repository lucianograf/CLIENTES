#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'Colors.ch'

/*/{Protheus.doc} BFFATR06
(Relatório de pedidos, quebrando pelo status da tela BFFATA30)
@author Iago Luiz Raimondi
@since 01/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR07()
	Local oReport
	Local cPerg		:= "BFFATR07"
	Private aStatus := {}
	Private aProgr	:= {}
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
    
	//sfCriaSx1(cPerg)
	Pergunte(cPerg,.F.)
        
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
    
Return


/*/{Protheus.doc} RptDef
(Geração das colunas para receber os valores da query)
@author Iago Luiz Raimondi
@since 03/07/2015
@version 1.0
@param cNome, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RptDef(cNome)

	Local oReport 	:= Nil
	Local oSection1 := Nil
	Local oSection2 := Nil
	Local oSection3 := Nil
	
	Aadd(aStatus,{"Alçada/A Liberar",0,0,0})
	Aadd(aStatus,{"Residuo",0,0,0})
	Aadd(aStatus,{"A Liberar",0,0,0})
	Aadd(aStatus,{"Faturado",0,0,0})
	Aadd(aStatus,{"Crédito/Estoque",0,0,0})
	Aadd(aStatus,{"Crédito",0,0,0})
	Aadd(aStatus,{"Estoque",0,0,0})
	Aadd(aStatus,{"Ok",0,0,0})
	Aadd(aStatus,{"Ok+Expedição",0,0,0})
	    
	oReport := TReport():New(cNome,"Relação de pedidos",cNome,{|oReport| ReportPrint(oReport)},"Relatório de pedido por status")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
    
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"CLIENTE"		,"QRY","Código"     ,"@!",06)
	TRCell():New(oSection1,"LOJA"  			,"QRY","Loja"   	,"@!",02)
	TRCell():New(oSection1,"NOME"  			,"QRY","Nome"    	,"@!",50)
    
	oSection2:= TRSection():New(oReport, "Pedido", {"QRY"},, .F., .T.)
	TRCell():New(oSection2,"NUMERO"       		,"QRY","Pedido"			,"@!",6)
	TRCell():New(oSection2,"EMISSAO"      		,"QRY","Emissão"    	,"@D",10)
	TRCell():New(oSection2,"DATAPRO"    		,"QRY","Dt.Programada"  ,"@D",10)
	TRCell():New(oSection2,"CONDPAG"    		,"QRY","Condição Pag." 	,"@!",20)
	TRCell():New(oSection2,"VENDEDOR"   		,"QRY","Vendedor"       ,"@!",50)
	TRCell():New(oSection2,"VEND03" 	  		,"QRY","Ativo" 	        ,"@!",50)
	
	oSection3:= TRSection():New(oReport, "Itens", {"QRY"},, .F., .T.)
	TRCell():New(oSection3,"PRODUTO"       	,"QRY","Produto"	,"@!",15)
	TRCell():New(oSection3,"DESCRI"      	,"QRY","Descrição"  ,"@!",55)
	TRCell():New(oSection3,"QTD"    		,"QRY","Qtd"   		,"@E 9999999",7)
	TRCell():New(oSection3,"VALOR"    		,"QRY","Valor"  	,"@E 999,999,999.99",15)
	TRCell():New(oSection3,"STATUS"   		,"QRY","Status"     ,"@!",30)
		
		
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)


/*/{Protheus.doc} ReportPrint
(Geração dos valores que será feito input nas colunas. Quebrando primeiro pelo Cliente, depois )
@author Iago Luiz Raimondi
@since 03/07/2015
@version 1.0
@param oReport, objeto, (Objeto de impressao)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport)

	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local oSection3 := oReport:Section(3)
	Local cQry		:= ""
	Local cCliente	:= ""
	
	cQry += "SELECT *"
	cQry += "  FROM (SELECT C5.C5_CLIENTE AS CLIENTE,"
	cQry += "               C5.C5_LOJACLI AS LOJA,"
	cQry += "               A1.A1_NOME AS NOME,"
	cQry += "               C5.C5_NUM AS NUMERO,"
	cQry += "               C5.C5_EMISSAO AS EMISSAO,"
	cQry += "               C5.C5_TIPO AS TIPO,"
	cQry += "               C5.C5_DTPROGM AS DATAPRO,"
	cQry += "               C5.C5_VEND1 AS COD_VEND,"
	cQry += "               C5.C5_VEND3 AS VEND03,"
	cQry += "               A3.A3_NOME AS NOME_VEND,"
	cQry += "               C6_ITEM AS ITEM,"
	cQry += "               C6_PRODUTO AS PRODUTO,"
	cQry += "               B1.B1_DESC AS DESCRI,"
	cQry += "               B1.B1_QTELITS AS LITROS,"
	cQry += "               C5.C5_CONDPAG AS CONDPAG,"
	cQry += "               E4.E4_DESCRI AS CONDPAG_DESC,"
	cQry += "               CASE"
	cQry += "                 WHEN C9_SEQUEN IS NOT NULL THEN"
	cQry += "                  C9_QTDLIB"
	cQry += "                 ELSE"
	cQry += "                  C6_QTDVEN"
	cQry += "               END QTD,"
	cQry += "               CASE"
	cQry += "                 WHEN C9_SEQUEN IS NOT NULL THEN"
	cQry += "                  (C6_VALOR / C6_QTDVEN) * C9_QTDLIB"
	cQry += "                 ELSE"
	cQry += "                  C6_VALOR"
	cQry += "               END VALOR,"
	cQry += "               CASE"
	cQry += "                 WHEN C6_BLQ = 'S' AND C9_SEQUEN IS NULL THEN"
	cQry += "                  'Alçada/A Liberar'"
	cQry += "                 WHEN C6_BLQ = 'R' AND C9_SEQUEN IS NULL THEN"
	cQry += "                  'Residuo'"
	cQry += "                 WHEN C9_SEQUEN IS NULL THEN"
	cQry += "                  'A Liberar'"
	cQry += "                 WHEN C9_NFISCAL != ' ' THEN"
	cQry += "                  'Faturado'"
	cQry += "                 WHEN C9_BLCRED NOT IN ('  ', '10') AND"
	cQry += "                      C9_BLEST NOT IN ('  ', '10') THEN"
	cQry += "                  'Crédito/Estoque'"
	cQry += "                 WHEN C9_BLCRED NOT IN ('  ', '10') THEN"
	cQry += "                  'Crédito'"
	cQry += "                 WHEN C9_BLEST NOT IN ('  ', '10') THEN"
	cQry += "                  'Estoque'"
	cQry += "                 WHEN C9_FLGENVI = 'E' THEN"
	cQry += "                  'Ok+Expedição:' ||"
	cQry += "                  TO_CHAR(TO_DATE(C9_LIBFAT, 'YYYYMMDD'), 'DD/MM/YY') || ' ' ||"
	cQry += "                  C9_BLINF"
	cQry += "                 ELSE"
	cQry += "                  'Ok'"
	cQry += "               END STATUS"
	cQry += "          FROM "+ RetSqlName("SC6") +" C6,"+ RetSqlName("SB2") +" B2,"+ RetSqlName("SC9") +" C9,"+ RetSqlName("SB1") +" B1,"
	cQry += "               "+ RetSqlName("SC5") +" C5,"+ RetSqlName("SA1") +" A1,"+ RetSqlName("SA3") +" A3,"+ RetSqlName("SE4") +" E4 "
	cQry += "         WHERE B2.D_E_L_E_T_ = ' '"
	cQry += "           AND B2_LOCAL = C6_LOCAL"
	cQry += "           AND B2_COD = C6_PRODUTO"
	cQry += "           AND B2_FILIAL = '"+ xFilial("SB2") +"'"
	// Segmento
	If MV_PAR09 <= 3
		cQry += "   AND (SELECT COUNT(C6_PRODUTO) "
		cQry += "          FROM "+RetSqlName("SC6") + " C6B, "+ RetSqlName("SB1") + " B1B "
		cQry += "         WHERE C6B.D_E_L_E_T_ = ' ' "
		cQry += "           AND C6_NUM = C5_NUM "
		cQry += "           AND C6_FILIAL = '" + xFilial("SC6")+ "' "
		cQry += "           AND B1B.D_E_L_E_T_ = ' ' "
		cQry += "           AND B1_COD = C6_PRODUTO "
		If MV_PAR09 == 1 // Texaco/Ipiranga
	//		cQry += "        AND B1_PROC NOT IN('000473','000449','000455','002334')"  
			cQry += "        AND B1_CABO IN ('TEX', 'IPI')  "
		ElseIf MV_PAR09 == 2 //  Michelin
	//		cQry += "	      AND B1_PROC IN('000473')"
	        cQry += "        AND B1_CABO = 'MIC' "
		ElseIf MV_PAR09 == 3 // Wynns
	//		cQry += "	      AND B1_PROC IN('000449','000455','002334')"
	        cQry += "        AND B1_CABO IN ('LUS', 'ROC', 'HOU')  "
		Endif    
		cQry += "           AND B1_FILIAL = '"+xFilial("SB1")+"') > 0 "
	Endif
	cQry += "           AND B1.D_E_L_E_T_ = ' '"
	cQry += "           AND B1_COD = C6_PRODUTO"
	cQry += "           AND B1_FILIAL = '"+ xFilial("SB1") +"'"
	cQry += "           AND C9.D_E_L_E_T_(+) = ' '"
	cQry += "           AND C9_ITEM(+) = C6_ITEM"
	cQry += "           AND C9_PRODUTO(+) = C6_PRODUTO"
	cQry += "           AND C9_PEDIDO(+) = C6_NUM"
	cQry += "           AND C9_FILIAL(+) = '"+ xFilial("SB9") +"'"
	cQry += "           AND C6.D_E_L_E_T_ = ' '"
	cQry += "           AND C6_FILIAL = '"+ xFilial("SC6") +"'"
	cQry += "           AND C5.D_E_L_E_T_ = ' '"
	cQry += "           AND C5.C5_NUM = C6_NUM"
	cQry += "           AND C5_TIPO = 'N' "
	cQry += "           AND C5.C5_FILIAL = '"+ xFilial("SC5") +"'"
	// Emissão De - Até
	cQry += "           AND C5.C5_EMISSAO BETWEEN '"+ DTOS(MV_PAR01) +"' AND '"+ DTOS(MV_PAR02) +"'"
	// Vendedor De - Até
	cQry += "           AND ((C5.C5_VEND1 BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' ) OR (C5.C5_VEND3 BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' )) "
	cQry += "           AND A1.D_E_L_E_T_ = ' '"
	cQry += "           AND A1.A1_LOJA = C5.C5_LOJACLI"
	cQry += "           AND A1.A1_COD = C5.C5_CLIENTE"
	cQry += "           AND A1.A1_FILIAL = '"+ xFilial("SA1") +"'"
	// Enviado
	If MV_PAR08 == 2
		cQry += "   AND C5_BLPED IN('S','M') "
	ElseIf MV_PAR08 == 1
		cQry += "   AND C5_BLPED NOT IN('S','M') "
	Endif
	If !Empty(MV_PAR05) // Assessor(a) De - Até
		cQry += "   AND (A3_OPERADO BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"')  "		
	Endif
	cQry += "           AND A3.D_E_L_E_T_(+) = ' '"
	cQry += "           AND A3.A3_COD(+) = C5.C5_VEND1"
	cQry += "           AND A3.A3_FILIAL(+) = '"+ xFilial("SA3") +"'"
	cQry += "           AND E4.E4_CODIGO(+) = C5.C5_CONDPAG"
	cQry += "           AND E4.E4_FILIAL(+) = '"+ xFilial("SE4") +"'"
	
	cQry += "        UNION"
	
	cQry += "        SELECT C5.C5_CLIENTE AS CLIENTE,"
	cQry += "               C5.C5_LOJACLI AS LOJA,"
	cQry += "               A1.A1_NOME AS NOME,"
	cQry += "               C5.C5_NUM AS NUMERO,"
	cQry += "               C5.C5_EMISSAO AS EMISSAO,"
	cQry += "               C5.C5_TIPO AS TIPO,"
	cQry += "               C5.C5_DTPROGM AS DATAPRO,"
	cQry += "               C5.C5_VEND1 AS COD_VEND,"
	cQry += "               C5.C5_VEND3 AS VEND03,"
	cQry += "               A3.A3_NOME AS NOME_VEND,"
	cQry += "               C6_ITEM AS ITEM,"
	cQry += "               C6_PRODUTO AS PRODUTO,"
	cQry += "               B1.B1_DESC AS DESCRI,"
	cQry += "               B1.B1_QTELITS AS LITROS,"
	cQry += "               C5.C5_CONDPAG AS CONDPAG,"
	cQry += "               E4.E4_DESCRI AS CONDPAG_DESC,"
	cQry += "               C6_QTDVEN - C6_QTDENT QTD,"
	cQry += "               (C6_QTDVEN - C6_QTDENT) * C6_PRCVEN VALOR,"
	cQry += "               CASE"
	cQry += "                 WHEN C6_BLQ = 'S' THEN"
	cQry += "                  'Alçada/A Liberar'"
	cQry += "                 WHEN C6_BLQ = 'R' THEN"
	cQry += "                  'Residuo'"
	cQry += "                 ELSE"
	cQry += "                  'A Liberar'"
	cQry += "               END STATUS"
	cQry += "          FROM "+ RetSqlName("SC6") +" C6,"+ RetSqlName("SB2") +" B2,"+ RetSqlName("SB1") +" B1,"+ RetSqlName("SC5") +" C5,"
	cQry += "               "+ RetSqlName("SA1") +" A1,"+ RetSqlName("SA3") +" A3,"+ RetSqlName("SE4") +" E4 "
	cQry += "         WHERE B2.D_E_L_E_T_ = ' '"
	cQry += "           AND B2_LOCAL = C6_LOCAL"
	cQry += "           AND B2_COD = C6_PRODUTO"
	cQry += "           AND B2_FILIAL = '"+ xFilial("SB2") +"'"
	// Segmento
	If MV_PAR09 <= 3
		cQry += "   AND (SELECT COUNT(C6_PRODUTO) "
		cQry += "          FROM "+RetSqlName("SC6") + " C6B, "+ RetSqlName("SB1") + " B1B "
		cQry += "         WHERE C6B.D_E_L_E_T_ = ' ' "
		cQry += "           AND C6_NUM = C5_NUM "
		cQry += "           AND C6_FILIAL = '" + xFilial("SC6")+ "' "
		cQry += "           AND B1B.D_E_L_E_T_ = ' ' "
		cQry += "           AND B1_COD = C6_PRODUTO "        
		If MV_PAR09 == 1 // Texaco/Ipiranga
	//		cQry += "        AND B1_PROC NOT IN('000473','000449','000455','002334')"  
			cQry += "        AND B1_CABO IN ('TEX', 'IPI')  "
		ElseIf MV_PAR09 == 2 //  Michelin
	//		cQry += "	      AND B1_PROC IN('000473')"
	        cQry += "        AND B1_CABO = 'MIC' "
		ElseIf MV_PAR09 == 3 // Wynns
	//		cQry += "	      AND B1_PROC IN('000449','000455','002334')"
	        cQry += "        AND B1_CABO IN ('LUS', 'ROC', 'HOU')  "
		Endif
    	cQry += "           AND B1_FILIAL = '"+xFilial("SB1")+"') > 0 "
	Endif    
	cQry += "           AND B1.D_E_L_E_T_ = ' '"
	cQry += "           AND B1_COD = C6_PRODUTO"
	cQry += "           AND B1_FILIAL = '"+ xFilial("SB1") +"'"
	cQry += "           AND C5.D_E_L_E_T_ = ' '"
	// Emissão De - Até
	cQry += "           AND C5.C5_EMISSAO BETWEEN '"+ DTOS(MV_PAR01) +"' AND '"+ DTOS(MV_PAR02) +"'"
	// Vendedor De - Até
	cQry += "           AND C5_TIPO = 'N' "
	cQry += "           AND ((C5.C5_VEND1 BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' ) OR (C5.C5_VEND3 BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' )) "
	cQry += "           AND C5.C5_NUM = C6_NUM"
	cQry += "           AND C5.C5_FILIAL = '"+ xFilial("SC5") +"'"
	cQry += "           AND A1.D_E_L_E_T_ = ' '"
	cQry += "           AND A1.A1_LOJA = C5.C5_LOJACLI"
	cQry += "           AND A1.A1_COD = C5.C5_CLIENTE"
	cQry += "           AND A1.A1_FILIAL = '"+ xFilial("SA1") +"'"
	// Enviado
	If MV_PAR08 == 2
		cQry += "   AND C5_BLPED IN('S','M') "
	ElseIf MV_PAR08 == 1
		cQry += "   AND C5_BLPED NOT IN('S','M') "
	Endif
	
	If !Empty(MV_PAR05) // Assessor(a) De - Até
		cQry += "   AND ((A3_OPERADO BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"') "		
	Endif
	cQry += "           AND A3.D_E_L_E_T_(+) = ' '"
	cQry += "           AND A3.A3_COD(+) = C5.C5_VEND1"
	cQry += "           AND A3.A3_FILIAL(+) = '"+ xFilial("SA3") +"'"
	cQry += "           AND E4.E4_CODIGO(+) = C5.C5_CONDPAG"
	cQry += "           AND E4.E4_FILIAL(+) = '"+ xFilial("SE4") +"'"
	cQry += "           AND C6_QTDVEN > NVL((SELECT SUM(C9_QTDLIB)"
	cQry += "                                 FROM "+ RetSqlName("SC9") +" C9"
	cQry += "                                WHERE D_E_L_E_T_ = ' '"
	cQry += "                                  AND C9_ITEM = C6_ITEM"
	cQry += "                                  AND C9_PRODUTO = C6_PRODUTO"
	cQry += "                                  AND C9_PEDIDO = C6_NUM"
	cQry += "                                  AND C9_FILIAL = '"+ xFilial("SC9") +"'),"
	cQry += "                               0)"
	cQry += "           AND C6_QTDENT < C6_QTDVEN"
	cQry += "           AND C6.D_E_L_E_T_ = ' '"
	cQry += "           AND C6_FILIAL = '"+ xFilial("SC6") +"')"
	
	If mv_par10 == 2
		cQry += " WHERE STATUS IN ('Residuo')"
	Else
		// Status
		If MV_PAR07 == 1 // Alçada
			cQry += " WHERE STATUS IN ('Alçada/A Liberar','A Liberar')"
		ElseIf MV_PAR07 == 2 // Crédito
			cQry += " WHERE STATUS IN ('Crédito','Crédito/Estoque')"
		ElseIf MV_PAR07 == 3 // Estoque/Liberado
			cQry += " WHERE STATUS IN ('Estoque','Ok')"
		ElseIf MV_PAR07 == 4 // Estoque/Liberado
			cQry += " WHERE STATUS NOT IN ('Faturado','Residuo')"
		EndIf
	Endif
	
	cQry += " ORDER BY CLIENTE,LOJA,NUMERO"

	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	ENDIF
    
	TCQUERY cQry NEW ALIAS "QRY"
   
   	//Quebra por Cliente/Pedido/Itens
	cCliente := QRY->CLIENTE
	cLoja := QRY->LOJA
	cPedido := QRY->NUMERO
   	
	While QRY->(!EOF())
		
		

		If oReport:Cancel()
			Exit
		EndIf
    	
		oSection1:Init()
		oSection1:Cell("CLIENTE"):SetValue(QRY->CLIENTE)
		oSection1:Cell("LOJA"):SetValue(QRY->LOJA)
		oSection1:Cell("NOME"):SetValue(QRY->NOME)
		oSection1:Printline()
				
		While (QRY->CLIENTE == cCliente .AND. QRY->LOJA == cLoja)
			oSection2:Init()
			oSection2:Cell("NUMERO"):SetValue(QRY->NUMERO)
			oSection2:Cell("EMISSAO"):SetValue(STOD(QRY->EMISSAO))
			oSection2:Cell("DATAPRO"):SetValue(STOD(QRY->DATAPRO))
			oSection2:Cell("CONDPAG"):SetValue(QRY->CONDPAG+"-"+QRY->CONDPAG_DESC)
			oSection2:Cell("VENDEDOR"):SetValue(QRY->COD_VEND+"-"+QRY->NOME_VEND)
			oSection2:Cell("VEND03"):SetValue(QRY->VEND03+"-"+Posicione("SA3",1,xFilial("SA3")+QRY->VEND03,"A3_NOME"))
			oSection2:Printline()
			
			While (QRY->NUMERO == cPedido)
				oSection3:Init()
				oSection3:Cell("PRODUTO"):SetValue(QRY->PRODUTO)
				oSection3:Cell("DESCRI"):SetValue(QRY->DESCRI)
				oSection3:Cell("QTD"):SetValue(QRY->QTD)
				oSection3:Cell("VALOR"):SetValue(QRY->VALOR)
				oSection3:Cell("STATUS"):SetValue(QRY->STATUS)
				oSection3:Printline()
				
				sfSomaStatus(QRY->STATUS,QRY->QTD,QRY->VALOR,(QRY->QTD*QRY->LITROS),STOD(QRY->DATAPRO))
				
				QRY->(dbSkip())
			Enddo
			cPedido := QRY->NUMERO
			
		Enddo
		cCliente := QRY->CLIENTE
		cLoja := QRY->LOJA
		
		//Linha
		oReport:IncRow()
		oSection1:Finish()
		oSection2:Finish()
		oSection3:Finish()
	Enddo
	
	oReport:IncRow()
	oReport:PrintText(PadC("Soma por Status",68),,oSection3:Cell("DESCRI"):ColPos())
	nTotQtd := 0
	nTotVal := 0
	nTotLit := 0
 	For nX := 1 To Len(aStatus)
 		nTotQtd += aStatus[nX][2]
		nTotVal += aStatus[nX][3]
		nTotLit += aStatus[nX][4]
		oReport:PrintText(PadR(aStatus[nX][1],15)+" QTD:"+PadL(cValToChar(aStatus[nX][2]),6)+" VLR:"+PadL(Transform(aStatus[nX][3],"@E 999,999,999.99"),15)+" LITROS:"+PadL(aStatus[nX][4],10),,oSection3:Cell("DESCRI"):ColPos())
	Next
	
	
	
	oReport:IncRow()
	oReport:PrintText(PadL("TOTAL: ->>",15)+" QTD:"+PadL(cValToChar(nTotQtd),6)+" VLR:"+PadL(Transform(nTotVal,"@E 999,999,999.99"),15)+" LITROS:"+PadL(nTotLit,10),,oSection3:Cell("DESCRI"):ColPos())
	
	oReport:IncRow()
	oReport:PrintText(PadC("Soma por data programada",68),,oSection3:Cell("DESCRI"):ColPos())
	oReport:IncRow()
	
	nTotQtd := 0
	nTotVal := 0
	nTotLit := 0
	aSort(aProgr,,,{|x,y| x[1] < y[1] })
 	For nX := 1 To Len(aProgr)
 		nTotQtd += aProgr[nX][2]
		nTotVal += aProgr[nX][3]
		nTotLit += aProgr[nX][4]
		oReport:PrintText(PadR(aProgr[nX][1],15)+" QTD:"+PadL(cValToChar(aProgr[nX][2]),6)+" VLR:"+PadL(Transform(aProgr[nX][3],"@E 999,999,999.99"),15)+" LITROS:"+PadL(aProgr[nX][4],10),,oSection3:Cell("DESCRI"):ColPos())
	Next
	oReport:IncRow()
	
	oReport:EndPage()

	QRY->(DbCloseArea())

Return


/*/{Protheus.doc} sfCriaSx1
(Cria perguntas (Praticamente o mesmo filtro que o BFFATA30))
@author Iago Luiz Raimondi
@since 03/07/2015
@version 1.0
@param cPerg, character, (Descrição da pergunta)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg,'01','Emissão de','Emissão de','Emissão de', 'mv_ch1', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par01')
	PutSx1(cPerg,'02','Emissão até','Emissão até','Emissão até', 'mv_ch2', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par02')
	PutSx1(cPerg,'03','Vendedor de','Vendedor de','Vendedor de', 'mv_ch3', 'C', 6, 0, 0, 'G', '', 'SA3', '', '', 'mv_par03')
	PutSx1(cPerg,'04','Vendedor até','Vendedor até','Vendedor até', 'mv_ch4', 'C', 6, 0, 0, 'G', '', 'SA3', '', '', 'mv_par04')
	PutSx1(cPerg,'05','Assessor(a) de','Assessor(a)de','Assessor(a)de', 'mv_ch5', 'C', 6, 0, 0, 'G', '', 'SU7', '', '', 'mv_par05')
	PutSx1(cPerg,'06','Assessor(a) até','Assessor(a)até','Assessor(a)até', 'mv_ch6', 'C', 6, 0, 0, 'G', '', 'SU7', '', '', 'mv_par06')
	PutSx1(cPerg,'07','Restrição','Restrição','Restrição','mv_ch7','N',1,0,0,'C','','','','','mv_par07','Alçada','Alçada','Alçada','','Crédito','Crédito','Crédito','Estoque/Liberado','Estoque/Liberado','Estoque/Liberado','Pendente','Pendente','Pendente','Todos','Todos','Todos')
	PutSx1(cPerg,'08','Enviado p/Expedição','Enviado p/Expedição','Enviado p/Expedição','mv_ch8','N',1,0,0,'C','','','','','mv_par08','Não Enviado','Não Enviado','Não Enviado','','Enviado','Enviado','Enviado','Ambos','Ambos','Ambos')
	PutSx1(cPerg,'09','Segmento','Segmento','Segmento','mv_ch9','N',1,0,0,'C','','','','','mv_par09','Texaco/Ipiranga','Texaco/Ipiranga','Texaco/Ipiranga','','Michelin','Michelin','Michelin','Lust/Roc/Hou','Lust/Roc/Hou','Lust/Roc/Hou','Todos','Todos','Todos')
	PutSx1(cPerg,'10','Somente Residuo?','Somente Residuo?','Somente Residuo?','mv_cha','N',1,0,0,'C','','','','','mv_par10','Nao','Nao','Nao','','Sim','Sim','Sim')
	
Return


/*/{Protheus.doc} sfSomaStatus
(long_description)
@author informatica4
@since 03/07/2015
@version 1.0
@param cStatus, character, (Descrição do parâmetro)
@param nQtd, numérico, (Descrição do parâmetro)
@param nValor, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSomaStatus(cStatus,nQtd,nValor,nLitros,dDtPrg)

	Local nPos

	If !Empty(cStatus)
		cStatus := AllTrim(Status)
		If "Ok+Expedição" $ cStatus
			cStatus := SubStr(cStatus,1,12)
		EndIf
	
		nPos := aScan(aStatus,{|x| x[1] == cStatus})
		If nPos > 0
			aStatus[nPos][2] += nQtd
			aStatus[nPos][3] += nValor
			aStatus[nPos][4] += nLitros
		Else
			Aadd(aStatus,{cStatus,nQte,nValor,nLitros})
		EndIf
		
		nPos := aScan(aProgr,{|x| x[1] == dDtPrg})
		
		If nPos == 0
			Aadd(aProgr,{dDtPrg,nQtd,nValor,nLitros})
		Else
			aProgr[nPos][2] += nQtd
			aProgr[nPos][3] += nValor
			aProgr[nPos][4] += nLitros
		Endif
	EndIf

Return
