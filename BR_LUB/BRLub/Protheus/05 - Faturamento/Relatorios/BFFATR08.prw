#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFFATR08
(Relatório da primeira compra de clientes por filial+vendedor+data primeira compra)
@author Iago Luiz Raimondi
@since 14/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR08()
	Local oReport
	Local cPerg	:= "BFFATR08"
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
    
	//sfCriaSx1(cPerg)
	Pergunte(cPerg,.F.)
        
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
    
Return


/*/{Protheus.doc} RptDef
(Montagem das colunas e totais)
@author Iago Luiz Raimondi
@since 16/03/2015
@version 1.0
@param cNome, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RptDef(cNome)

	Local oReport := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil
	Local oBreak
	Local oFunction
    
	oReport := TReport():New(cNome,"Clientes novos",cNome,{|oReport| ReportPrint(oReport)},"Relatório da primeira compra de clientes novos")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
    
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"COD_VEND"		,"QRY","Código"     ,"@!",10)
	TRCell():New(oSection1,"NOME_VEND"  	,"QRY","Vendedor"   ,"@!",50)
	
    
	oSection2:= TRSection():New(oReport, "Vendas por vendedor", {"QRY"},, .F., .T.)
	TRCell():New(oSection2,"FILIAL"     ,"QRY","Filial"			,"@!",2)
	TRCell():New(oSection2,"PEDIDO"     ,"QRY","Pedido"    		,"@!",6)
	TRCell():New(oSection2,"NF"    		,"QRY","NFe"   			,"@!",8)
	TRCell():New(oSection2,"COD_CLI"    ,"QRY","Cod.Cli"       	,"@!",6)
	TRCell():New(oSection2,"LOJA_CLI"   ,"QRY","Loja.Cli"       ,"@!",2)
	TRCell():New(oSection2,"NOME_CLI"   ,"QRY","Nome.Cli"       ,"@!",50)
	TRCell():New(oSection2,"EMISSAO"    ,"QRY","Emissão"       	,"@D",10)
	TRCell():New(oSection2,"QTD"   		,"QRY","Qtd"       		,"@E 999,999",7)
	TRCell():New(oSection2,"LITROS"    	,"QRY","Litros"         ,"@E 99,999,999.99",15)
	TRCell():New(oSection2,"TOTAL"    	,"QRY","Valor"         	,"@E 99,999,999.99",15)
	
	TRFunction():New(oSection2:Cell("QTD"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	TRFunction():New(oSection2:Cell("LITROS"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	TRFunction():New(oSection2:Cell("TOTAL"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
		
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)


/*/{Protheus.doc} ReportPrint
(Geração da query e atribuição de valores nas colunas)
@author Iago Luiz Raimondi
@since 16/03/2015
@version 1.0
@param oReport, objeto, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport)

	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local cQry		:= ""
	Local cVend		:= ""
	
	cQry += "SELECT F2.F2_FILIAL AS FILIAL,"
	cQry += "       D2.D2_PEDIDO AS PEDIDO,"
	cQry += "       F2.F2_DOC AS NF,"
	cQry += "       F2.F2_CLIENTE AS COD_CLI,"
	cQry += "       F2.F2_LOJA AS LOJA_CLI,"
	cQry += "       A1.A1_NOME AS NOME_CLI,"
	cQry += "       F2.F2_VEND1 AS COD_VEND,"
	cQry += "       CASE WHEN A3.A3_NOME IS NULL THEN 'SEM VENDEDOR' ELSE A3.A3_NOME END AS NOME_VEND,"
	cQry += "       F2.F2_EMISSAO AS EMISSAO,"
	cQry += "       SUM(D2.D2_QUANT) AS QTD,"
	cQry += "       SUM(D2.D2_QUANT * B1.B1_QTELITS) AS LITROS,
	cQry += "       SUM(D2.D2_TOTAL) AS TOTAL"
	cQry += "  FROM " + RetSqlName("SD2") + " D2"
	cQry += " INNER JOIN " + RetSqlName("SF2") + " F2 ON F2.F2_FILIAL = D2.D2_FILIAL"
	cQry += "                     AND F2.F2_DOC = D2.D2_DOC"
	cQry += "                     AND F2.F2_SERIE = D2.D2_SERIE"
	cQry += " INNER JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_COD = F2.F2_CLIENTE"
	cQry += "                     AND A1.A1_LOJA = F2.F2_LOJA"
	cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 ON B1.B1_FILIAL = D2.D2_FILIAL"
	cQry += "                     AND B1.B1_COD = D2.D2_COD"
	cQry += " INNER JOIN " + RetSqlName("SF4") + " F4 ON F4.F4_FILIAL = D2.D2_FILIAL"
	cQry += "                     AND F4.F4_CODIGO = D2.D2_TES"
	cQry += " LEFT JOIN " + RetSqlName("SA3") + " A3 ON A3.A3_COD = F2.F2_VEND1"
	cQry += " WHERE D2.D_E_L_E_T_ = ' '"
	cQry += "   AND F2.D_E_L_E_T_ = ' '"
	cQry += "   AND A1.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.D_E_L_E_T_ = ' '"
	cQry += "   AND F4.D_E_L_E_T_ = ' '"
	cQry += "   AND F4.F4_DUPLIC = 'S'"
	cQry += "   AND F2.F2_FILIAL BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry += "   AND F2.F2_VEND1 BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
	cQry += "   AND A1.A1_PRICOM BETWEEN '"+ DTOS(MV_PAR05) +"' AND '"+ DTOS(MV_PAR06) +"'"
	If MV_PAR07 == 1 // Texaco/Outros
		cQry += "        AND B1.B1_PROC NOT IN('000473','000449','000455','002334')"
	ElseIf MV_PAR07 == 2 //  Michelin
		cQry += "	      AND B1.B1_PROC IN('000473')"
	ElseIf MV_PAR07 == 3 // Wynns
		cQry += "	      AND B1.B1_PROC IN('000449','000455','002334')"
	Endif
	cQry += "   AND F2.F2_DOC = (SELECT MIN(FF2.F2_DOC)"
	cQry += "                      FROM " + RetSqlName("SF2") + " FF2"
	cQry += "                     WHERE FF2.F2_FILIAL = F2.F2_FILIAL"
	cQry += "                       AND FF2.F2_CLIENTE = F2.F2_CLIENTE"
	cQry += "                       AND FF2.F2_LOJA = F2.F2_LOJA"
	cQry += "                       AND FF2.D_E_L_E_T_ = ' '"
	cQry += "                       AND FF2.F2_TIPO = 'N')"
	cQry += " GROUP BY F2.F2_FILIAL,"
	cQry += "          D2.D2_PEDIDO,"
	cQry += "          F2.F2_DOC,"
	cQry += "          F2.F2_CLIENTE,"
	cQry += "          F2.F2_LOJA,"
	cQry += "          A1.A1_NOME,"
	cQry += "          F2.F2_VEND1,"
	cQry += "          A3.A3_NOME,"
	cQry += "          F2.F2_EMISSAO,"
	cQry += "          A1.A1_PRICOM"
	cQry += " ORDER BY F2.F2_VEND1, F2.F2_DOC"	
        
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
    
	TCQUERY cQry NEW ALIAS "QRY"
    
    //Quebra por vendedor
    cVend := QRY->COD_VEND
      	
	While QRY->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf
    	
		oSection1:Init()
		oSection1:Cell("COD_VEND"):SetValue(QRY->COD_VEND)
		oSection1:Cell("NOME_VEND"):SetValue(QRY->NOME_VEND)
		oSection1:Printline()
		
		While QRY->(!EOF()) .AND. QRY->COD_VEND == cVend
			oSection2:Init()
			oSection2:Cell("FILIAL"):SetValue(QRY->FILIAL)
			oSection2:Cell("PEDIDO"):SetValue(QRY->PEDIDO)
			oSection2:Cell("NF"):SetValue(QRY->NF)
			oSection2:Cell("COD_CLI"):SetValue(QRY->COD_CLI)
			oSection2:Cell("LOJA_CLI"):SetValue(QRY->LOJA_CLI)
			oSection2:Cell("NOME_CLI"):SetValue(QRY->NOME_CLI)
			oSection2:Cell("EMISSAO"):SetValue(STOD(QRY->EMISSAO))
			oSection2:Cell("QTD"):SetValue(QRY->QTD)
			oSection2:Cell("LITROS"):SetValue(QRY->LITROS)
			oSection2:Cell("TOTAL"):SetValue(QRY->TOTAL)
			oSection2:Printline()		
			QRY->(dbSkip())					
		Enddo
		cVend := QRY->COD_VEND		
		oSection2:Finish()
		oSection1:Finish()
		oReport:IncRow()			
	Enddo
	
	oReport:EndPage()
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
Return


/*/{Protheus.doc} sfCriaSx1
(Cria pergunta)
@author Iago Luiz Raimondi
@since 16/03/2015
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg, '01', 'Filial de' , 'Filial de', 'Filial de', 'mv_ch1', 'C', 2, 0, 0, 'G', '', 'SM0', '', '', 'mv_par01')
	PutSx1(cPerg, '02', 'Filial até' , 'Filial até', 'Filial até', 'mv_ch2', 'C', 2, 0, 0, 'G', 'NaoVazio()', 'SM0', '', '', 'mv_par02')
	PutSx1(cPerg, '03', 'Vendedor de' , 'Vendedor de', 'Vendedor de', 'mv_ch3', 'C', 6, 0, 0, 'G', '', 'SA3', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Vendedor até' , 'Vendedor até', 'Vendedor até', 'mv_ch4', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA3', '', '', 'mv_par04')	
	PutSx1(cPerg, '05', 'Prim.Compra de' , 'Prim.Compra de', 'Prim.Compra de', 'mv_ch5', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par05')
	PutSx1(cPerg, '06', 'Prim.Compra até' , 'Prim.Compra até', 'Prim.Compra até', 'mv_ch6', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par06')
	PutSx1(cPerg, '07', 'Segmento','Segmento','Segmento','mv_ch7','N',1,0,0,'C','','','','','mv_par7','Texaco/Outros','Texaco/Outros','Texaco/Outros','','Michelin','Michelin','Michelin','Wynns/Rocol','Wynns/Rocol','Wynns/Rocol','Todos','Todos','Todos')
	
Return
