#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFFISR01
(Relatório de Notas Fiscais Eletrônicas sem Retorno de Monitoramento Sefaz)
@type function
@author Marcelo Alberto Lauschner
@since 23/11/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFISR01()

	Local oReport
	Local cPerg	:= "BFFISR01"
	
	Pergunte(cPerg,.F.)
	
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
	
return Nil

/*/{Protheus.doc} RptDef
(Monta colunas do relatório)
@type function
@author Marcelo Alberto Lauschner
@since 23/11/2015
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
	
	oReport := TReport():New(cNome,"Notas Fiscais Eletrônicas sem Monitoramento Sefaz",cNome,{|oReport| ReportPrint(oReport)},"Relatório de Notas Fiscais Eletrônicas sem Monitoramento Sefaz")
	oReport:SetPortrait()
	
	oReport:SetTotalInLine(.F.)
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"F3_FILIAL"	  	,"QRY","Filial" 		  	,"@!",2)
	TRCell():New(oSection1,"F3_EMISSAO"	  	,"QRY","Emissão" 		  	,"@!",10)
	TRCell():New(oSection1,"F3_NFISCAL"	  	,"QRY","Num NF" 		  	,"@!",9)
	TRCell():New(oSection1,"F3_SERIE"		,"QRY","Série" 				,"@!",3)
	TRCell():New(oSection1,"F3_OBSERV"		,"QRY","Observação"			,"@!",30)
	TRCell():New(oSection1,"F3_CFO"			,"QRY","CFOP" 				,"@!",5)
	TRCell():New(oSection1,"F3_FORMUL"		,"QRY","F.Prop"				,"@!",1)
	TRCell():New(oSection1,"F3_CODRSEF"		,"QRY","Cod.Ret.Sef" 		,"@!",3)
	TRCell():New(oSection1,"F3_ESPECIE"		,"QRY","Especie"	 		,"@!",5)
	TRCell():New(oSection1,"F3_CLIEFOR"		,"QRY","Cli/For" 			,"@!",6)
	TRCell():New(oSection1,"F3_LOJA"		,"QRY","Loja" 				,"@!",2)
	
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)


/*/{Protheus.doc} ReportPrint
(Executa relatório)
@type function
@author marce
@since 23/11/2015
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
	Local	cAgrupa		:= ""
	
	
	cQry += "SELECT F3_FILIAL,"
	cQry += "       F3_EMISSAO,"
	cQry += "		F3_NFISCAL,"
	cQry += "		F3_SERIE,"
	cQry += "		F3_OBSERV,"
	cQry += "		F3_CFO,"
	cQry += "		F3_FORMUL,"
	cQry += "		F3_CODRSEF,"
	cQry += "		F3_ESPECIE,"
	cQry += "		F3_CLIEFOR,"
	cQry += "		F3_LOJA"
	cQry += "  FROM " + RetSqlName("SF3") + " F3 "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "	AND F3_ENTRADA BETWEEN '" + DTOS(MV_PAR03) + "' AND '" + DTOS(MV_PAR04) + "' "
	cQry += "	AND F3_FILIAL BETWEEN '" + MV_PAR01+ "' AND '" + MV_PAR02 + "' "
	cQry += "	AND F3_CODRSEF != '100' "
	cQry += "	AND F3_ESPECIE IN ('SPED', 'CTE')"
	cQry += "	AND (F3_CFO > '5' OR (F3_CFO <= '5' AND F3.F3_FORMUL = 'S'))"
	cQry += "	AND NOT (F3_OBSERV = 'NF CANCELADA' AND F3_CODRSEF IN ('101', '102'))"
	cQry += "	AND NOT (F3_OBSERV = 'NF INUTILIZADA' AND F3_CODRSEF = '102')"
	cQry += " 	AND NOT (F3_OBSERV = 'NF DENEGADA' AND F3_CODRSEF = '302')"
	cQry += "	AND NOT (F3_OBSERV = 'NF DENEGADA' AND F3_CFO > '5' AND"
	cQry += "	F3_CODRSEF IN ('205') AND NOT EXISTS"
	cQry += "	(SELECT F2_DOC"
	cQry += "	   FROM " + RetSqlName("SF2") + " F2 "
	cQry += "	  WHERE F2.D_E_L_E_T_ = ' '"
	cQry += "	    AND F2_LOJA = F3_LOJA"
	cQry += "	    AND F2_CLIENTE = F3_CLIEFOR"
	cQry += "	    AND F2_SERIE = F3_SERIE"
	cQry += "		AND F2_DOC = F3_NFISCAL"
	cQry += "		AND F2_FILIAL = F3_FILIAL))"
	cQry += "		AND NOT (F3_OBSERV = 'NF CANCELADA' AND F3_CFO > '5' AND"
	cQry += "		F3_CODRSEF IN ('232') AND NOT EXISTS"
	cQry += "		(SELECT F2_DOC"
	cQry += "		   FROM " + RetSqlName("SF2") + " F2 "
	cQry += "		  WHERE F2.D_E_L_E_T_ = ' '"
	cQry += "		    AND F2_LOJA = F3_LOJA"
	cQry += "			AND F2_CLIENTE = F3_CLIEFOR"
	cQry += "			AND F2_SERIE = F3_SERIE"
	cQry += "			AND F2_DOC = F3_NFISCAL"
	cQry += "			AND F2_FILIAL = F3_FILIAL))"
	cQry += "			AND NOT (F3_CFO > '5' AND F3_CODRSEF = '690' AND EXISTS"
	cQry += "			(SELECT F2_DOC"
	cQry += "			   FROM " + RetSqlName("SF2") + " F2 "
	cQry += "			  WHERE F2.D_E_L_E_T_ = ' '"
	cQry += "			    AND F2_LOJA = F3_LOJA"
	cQry += "				AND F2_CLIENTE = F3_CLIEFOR"
	cQry += "				AND F2_SERIE = F3_SERIE"
	cQry += "				AND F2_DOC = F3_NFISCAL"
	cQry += "				AND F2_FILIAL = F3_FILIAL))"
	cQry += " ORDER BY F3_FILIAL, F3_SERIE, F3_NFISCAL"
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	cAgrupa	:= QRY->F3_FILIAL
	
	While QRY->(!EOF())
		
		
		oSection1:Init()
		
		While cAGrupa == QRY->F3_FILIAL
			oSection1:Cell("F3_FILIAL"):SetValue(QRY->F3_FILIAL)
			oSection1:Cell("F3_EMISSAO"):SetValue(STOD(QRY->F3_EMISSAO))
			oSection1:Cell("F3_NFISCAL"):SetValue(QRY->F3_NFISCAL)
			oSection1:Cell("F3_SERIE"):SetValue(QRY->F3_SERIE)
			oSection1:Cell("F3_OBSERV"):SetValue(QRY->F3_OBSERV)
			oSection1:Cell("F3_CFO"):SetValue(QRY->F3_CFO)
			oSection1:Cell("F3_FORMUL"):SetValue(QRY->F3_FORMUL)
			oSection1:Cell("F3_CODRSEF"):SetValue(QRY->F3_CODRSEF)
			oSection1:Cell("F3_ESPECIE"):SetValue(QRY->F3_ESPECIE)
			oSection1:Cell("F3_CLIEFOR"):SetValue(QRY->F3_CLIEFOR)
			oSection1:Cell("F3_LOJA"):SetValue(QRY->F3_LOJA)
			oSection1:Printline()
			QRY->(dbSkip())
		Enddo
		oSection1:Finish()
		oReport:IncRow()
			
		cAgrupa	:= QRY->F3_FILIAL
		
	Enddo
	
	
	oReport:EndPage()
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
	
Return


