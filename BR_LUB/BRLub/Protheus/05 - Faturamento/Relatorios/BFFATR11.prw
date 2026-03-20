#Include 'Protheus.ch'
#Include 'Topconn.ch'

/*/{Protheus.doc} BFFATR11
(Relatório de Comparativo de Faturamento Texaco)
@author MarceloLauschner
@since 02/12/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR11()
	
	
	Local oReport
	Local cPerg	:= "BFFATR11"
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	//sfCriaSx1(cPerg)
	
	Pergunte(cPerg,.F.)
	
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
	
Return

/*/{Protheus.doc} RptDef
(Montagem da seção)
@author MarceloLauschner
@since 02/12/2015
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
	
	oReport := TReport():New(cNome,"Comparativo Texaco",cNome,{|oReport| ReportPrint(oReport)},"Relatório de Comparativo Faturamento Texaco")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
	
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"FILIAL"	  			,"QRY","Filial" 		  	,"@!",09)
	TRCell():New(oSection1,"TIPO_INFORMACAO"	,"QRY","Tipo"    	 		,"@!",20)
	TRCell():New(oSection1,"LITROS"	  			,"QRY","Qte Litros"		   	,"@E 99,999,999",11)
	TRCell():New(oSection1,"FAT_BRUTO"			,"QRY","Faturado"		   	,"@E 99,999,999.99",14)
	TRCell():New(oSection1,"LITROS_SN"		  	,"QRY","Litros SN"			,"@E 99,999,999",11)
	TRCell():New(oSection1,"FAT_SN"				,"QRY","Faturado SN" 		,"@E 99,999,999.99",14)
	
	
	//TRFunction():New(oSection2:Cell("QTD"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	//TRFunction():New(oSection2:Cell("LITROS"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	//TRFunction():New(oSection2:Cell("TOTAL"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)



/*/{Protheus.doc} ReportPrint
(Impressão do relatório)
@author MarceloLauschner
@since 02/12/2015
@version 1.0
@param oReport, objeto, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport)
	
	Local 	oSection1 	:= oReport:Section(1)
	Local 	cQry		:= ""
	Local	cFilImp		:= ""
	
	cQry += "SELECT 'Faturamento' TIPO_INFORMACAO,"
	cQry += "       'Filial '||D2_FILIAL FILIAL,"
	cQry += "       SUM(B1_QTELITS * D2_QUANT) LITROS,"
	cQry += "       SUM(D2_VALBRUT) FAT_BRUTO,"
	cQry += "       SUM(CASE WHEN D2_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN (D2_QUANT * B1_QTELITS) ELSE 0 END) LITROS_SN,"
	cQry += "       SUM(CASE WHEN D2_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN D2_VALBRUT ELSE 0 END) FAT_SN"
	cQry += "  FROM SD2020 D2 INNER JOIN SB1020 B1"
	cQry += "    ON B1_FILIAL = D2_FILIAL"
	cQry += "   AND B1_COD = D2_COD"
	cQry += " INNER JOIN SF4020 F4"
	cQry += "    ON F4_FILIAL = D2_FILIAL"
	cQry += "   AND F4_CODIGO = D2_TES"
	cQry += " WHERE F4_ESTOQUE = 'S'"
	cQry += "   AND B1_BLOQFAT = 'N'"
	cQry += "   AND B1_PROC = '000468'"
	cQry += "   AND F4.D_E_L_E_T_ = ' '"
	cQry += "   AND D2_CF NOT IN('5663','5905')"
	cQry += "   AND D2.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.D_E_L_E_T_ = ' '"
	cQry += "   AND F4.D_E_L_E_T_ = ' '"
	cQry += "   AND D2_TIPO  = 'N' "
	cQry += "   AND D2_EMISSAO BETWEEN '" + DTOS(MV_PAR01)+"' AND '"+ DTOS(MV_PAR02)+"' "
	cQry += " GROUP BY 1,D2_FILIAL "
	cQry += "UNION ALL "
	cQry += "SELECT 'Entradas' TIPO_INFORMACAO,"
	cQry += "       'Filial '||D1_FILIAL FILIAL,"
	cQry += "       SUM(D1_QUANT * B1_QTELITS) LITROS,"
	cQry += "       SUM(D1_TOTAL+D1_ICMSRET+D1_VALIPI) VALOR_BRUTO,"
	cQry += "       SUM(CASE WHEN D1_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN (D1_QUANT * B1_QTELITS) ELSE 0 END) LITROS_SN,"
	cQry += "       SUM(CASE WHEN D1_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN D1_TOTAL+D1_ICMSRET+D1_VALIPI ELSE 0 END) VALOR_BRUTO_SN"
	cQry += "  FROM SD1020 D1"
	cQry += " INNER JOIN SB1020 B1"
	cQry += "    ON B1_FILIAL = D1_FILIAL"
	cQry += "   AND B1_COD = D1_COD"
	cQry += " INNER JOIN SF4020 F4"
	cQry += "    ON F4_FILIAL = D1_FILIAL"
	cQry += "   AND F4_CODIGO = D1_TES"
	cQry += " INNER JOIN SF1020 F1"
	cQry += "    ON F1_FILIAL = D1_FILIAL"
	cQry += "   AND F1_LOJA = D1_LOJA"
	cQry += "   AND F1_FORNECE = D1_FORNECE"
	cQry += "   AND F1_SERIE = D1_SERIE"
	cQry += "   AND F1_DOC = D1_DOC"
	cQry += " WHERE F4_ESTOQUE = 'S'"
	cQry += "   AND F4_XTPMOV NOT IN('AI','TE')"
	cQry += "   AND D1.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.D_E_L_E_T_ = ' '"
	cQry += "   AND F4.D_E_L_E_T_ = ' '"
	cQry += "   AND F1.D_E_L_E_T_  = ' '"
	cQry += "   AND F1_STATUS <> ' '"
	//cQry += "   AND B1_PROC = '000468'"
	cQry += "   AND D1_FORNECE = '000468' " // Alterado para trazer faturamento do Fornecedor Chevron e não produtos com fornecedor padrão Chevron
	cQry += "   AND B1_BLOQFAT = 'N' "
	cQry += "   AND D1_TIPO NOT IN('D','B','C')"
	cQry += "   AND D1_CF NOT IN('1907','1912','1906','1909','1664','1409')"
	cQry += "   AND D1_EMISSAO BETWEEN  '" + DTOS(MV_PAR01)+"' AND '"+ DTOS(MV_PAR02)+"' "
	cQry += " GROUP BY 1,D1_FILIAL "
	cQry += "UNION ALL "
	cQry += "SELECT 'Estoque Armz ' || B2_LOCAL TIPO_INFORMACAO,"
	cQry += "       'Filial '||B2_FILIAL FILIAL,"
	cQry += "       SUM((B2_QATU - B2_RESERVA) * B1_QTELITS) LITROS,"
	cQry += "       SUM((B2_QATU - B2_RESERVA)* B2_CM1) VALOR_BRUTO,"
	cQry += "       SUM(CASE WHEN B2_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN ((B2_QATU - B2_RESERVA) * B1_QTELITS) ELSE 0 END) LITROS_SN,"
	cQry += "       SUM(CASE WHEN B2_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN (B2_QATU - B2_RESERVA)* B2_CM1 ELSE 0 END) VALOR_BRUTO_SN"
	cQry += "  FROM SB1020 B1"
	cQry += " INNER JOIN SB2020 B2"
	cQry += "    ON B2_FILIAL = B1_FILIAL"
	cQry += "   AND B2_COD = B1_COD"
	cQry += " WHERE B2.D_E_L_E_T_ = ' '"
	cQry += "   AND B2_QATU <> 0"
	cQry += "   AND B1_BLOQFAT = 'N'"
	cQry += "   AND B1_PROC = '000468'"
	cQry += "   AND B1.D_E_L_E_T_ = ' '"
	cQry += " GROUP BY 1,B2_FILIAL,B2_LOCAL "
	cQry += "UNION ALL "
	cQry += "SELECT 'Est.Reservado ' || B2_LOCAL TIPO_INFORMACAO,"
	cQry += "       'Filial '||B2_FILIAL FILIAL,"
	cQry += "       SUM(B2_RESERVA * B1_QTELITS) LITROS,"
	cQry += "       SUM(B2_RESERVA* B2_CM1) VALOR_BRUTO,"
	cQry += "       SUM(CASE WHEN B2_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN (B2_RESERVA * B1_QTELITS) ELSE 0 END) LITROS_SN,"
	cQry += "       SUM(CASE WHEN B2_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN B2_RESERVA* B2_CM1 ELSE 0 END) VALOR_BRUTO_SN"
	cQry += "  FROM SB1020 B1"
	cQry += " INNER JOIN SB2020 B2"
	cQry += "    ON B2_FILIAL = B1_FILIAL"
	cQry += "   AND B2_COD = B1_COD"
	cQry += " WHERE B2.D_E_L_E_T_ = ' '"
	cQry += "   AND B2_QATU <> 0"
	cQry += "   AND B1_BLOQFAT = 'N'"
	cQry += "   AND B1_PROC = '000468'"
	cQry += "   AND B1.D_E_L_E_T_ = ' '"
	cQry += " GROUP BY 1,B2_FILIAL,B2_LOCAL "
	cQry += "UNION ALL "
	cQry += "SELECT 'Em Trânsito' TIPO_INFORMACAO,"
	cQry += "       'Filial '||  B1_FILIAL  FILIAL,"
	cQry += "       SUM(XIT_QTE * B1_QTELITS) LITROS,"
	cQry += "       SUM(XIT_TOTNFE+XIT_VALIPI+XIT_VALRET) VALOR_BRUTO,"
	cQry += "       SUM(CASE WHEN B1_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN (XIT_QTE * B1_QTELITS) ELSE 0 END) LITROS_SN,"
	cQry += "       SUM(CASE WHEN B1_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN XIT_TOTNFE+XIT_VALIPI+XIT_VALRET ELSE 0 END) VALOR_BRUTO_SN"
	cQry += "  FROM CONDORXML AA"
	cQry += " INNER JOIN CONDORXMLITENS  AB"
	cQry += "    ON XML_CHAVE = XIT_CHAVE"
	cQry += " INNER JOIN SA2020 A2"
	cQry += "    ON A2_CGC = XML_EMIT"
	cQry += " INNER JOIN SB1020 B1"
	cQry += "    ON XIT_CODPRD = B1_COD"
	cQry += " WHERE XML_REJEIT = ' '"
	cQry += "   AND A2_COD = '000468'"
	cQry += "   AND AB.D_E_L_E_T_ = ' '"
	cQry += "   AND AA.D_E_L_E_T_ = ' '"
	cQry += "   AND XML_DEST IN('06032022000110','06032022000462','06032022000543','06032022000705','06032022000896')"
	cQry += "   AND XML_CONFCO <> ' '"
	cQry += "   AND XML_LANCAD = ' '"
	cQry += "   AND XML_TIPODC = 'N'"
	cQry += "   AND B1_BLOQFAT = 'N'"
	cQry += "   AND XML_EMISSA BETWEEN '" + DTOS(MV_PAR01)+"' AND '"+ DTOS(MV_PAR02)+"' "
	cQry += "   AND B1_FILIAL = SUBSTR(XML_DEST,11,2) "
	cQry += "GROUP BY B1_FILIAL,1 "
	cQry += "UNION ALL "
	cQry += "SELECT 'Pré-notas' TIPO_INFORMACAO,"
	cQry += "       'Filial '||D1_FILIAL FILIAL,"
	cQry += "       SUM(D1_QUANT * B1_QTELITS) LITROS,"
	cQry += "       SUM(D1_TOTAL+D1_ICMSRET+D1_VALIPI) VALOR_BRUTO,"
	cQry += "       SUM(CASE WHEN D1_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN (D1_QUANT * B1_QTELITS) ELSE 0 END) LITROS_SN,"
	cQry += "       SUM(CASE WHEN D1_COD IN(SELECT PSN_COD FROM BF_PROD_SN) THEN D1_TOTAL+D1_ICMSRET+D1_VALIPI ELSE 0 END) VALOR_BRUTO_SN"
	cQry += "  FROM SD1020 D1"
	cQry += " INNER JOIN SB1020 B1"
	cQry += "    ON B1_FILIAL = D1_FILIAL"
	cQry += "   AND B1_COD = D1_COD"
	cQry += " INNER JOIN SF1020 F1"
	cQry += "    ON F1_FILIAL = D1_FILIAL"
	cQry += "   AND F1_LOJA = D1_LOJA"
	cQry += "   AND F1_FORNECE = D1_FORNECE"
	cQry += "   AND F1_SERIE = D1_SERIE"
	cQry += "   AND F1_DOC = D1_DOC"
	cQry += " WHERE D1.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.D_E_L_E_T_ = ' '"
	cQry += "   AND F1.D_E_L_E_T_ =' '"
	cQry += "   AND F1_STATUS = ' '"
	cQry += "   AND B1_PROC = '000468'"
	cQry += "   AND B1_BLOQFAT = 'N'"
	cQry += "   AND D1_TIPO NOT IN('D','B','C')"
	cQry += "   AND D1_CF NOT IN('1907','1912','1906','1909','1664','1409')"
	cQry += "   AND D1_EMISSAO BETWEEN '" + DTOS(MV_PAR01)+"' AND '"+ DTOS(MV_PAR02)+"' "
	cQry += " GROUP BY 1,D1_FILIAL"
	cQry += " ORDER BY 2,1"
	
	
	MemoWrite("\log_sqls\bffatr11.sql",cQry)
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	oSection1:Init()
	
	While QRY->(!EOF())
		
		If oReport:Cancel()
			Exit
		EndIf
		
		If cFilImp <> QRY->FILIAL
			If !Empty(cFilImp)
				oSection1:Finish()
				oReport:IncRow()
				oSection1:Init()
			Endif
		Endif
		
		oSection1:Cell("FILIAL"):SetValue(QRY->FILIAL)
		oSection1:Cell("TIPO_INFORMACAO"):SetValue(QRY->TIPO_INFORMACAO)
		oSection1:Cell("LITROS"):SetValue(QRY->LITROS)
		oSection1:Cell("FAT_BRUTO"):SetValue(QRY->FAT_BRUTO)
		oSection1:Cell("LITROS_SN"):SetValue(QRY->LITROS_SN)
		oSection1:Cell("FAT_SN"):SetValue(QRY->FAT_SN)
		oSection1:Printline()
		cFilImp := QRY->FILIAL
		
		QRY->(dbSkip())
		
	Enddo
	oSection1:Finish()
	oReport:EndPage()
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
Return



/*/{Protheus.doc} sfCriaSx1
(Cria perguntas da rotina)
@author MarceloLauschner
@since 02/12/2015
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)
	
	PutSx1(cPerg, '01', 'Data Inicial   ' , 'Data Inicial  ', 'Data Inicial ', 'mv_ch1', 'D', 8, 0, 0, 'G', ''          , '', '', '', 'mv_par01')
	PutSx1(cPerg, '02', 'Data Final     ' , 'Data Final    ', 'Data Final   ', 'mv_ch2', 'D', 8, 0, 0, 'G', ''          , '', '', '', 'mv_par02')
	
Return
