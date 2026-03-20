#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFESTR03
(Relatório no formato para importação do inventário
ATENÇÃO: !!!!Trabalhar em conjunto com o fonte BFESTA02!!!!)
@author Iago Luiz Raimondi
@since 11/01/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (BFESTA02)
/*/
User Function BFESTR03()
	Local oReport
	Local cPerg	:= "BFESTR03"
	Private aStatus := {}
    
	sfCriaSx1(cPerg)
	Pergunte(cPerg,.F.)
        
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
    
Return


/*/{Protheus.doc} BFESTR03
(Montagem do objeto oReport)
@author Iago Luiz Raimondi
@since 11/01/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RptDef(cNome)

	Local oReport 	:= Nil
	Local oSection1 := Nil
	    
	oReport := TReport():New(cNome,"Inventário",cNome,{|oReport| ReportPrint(oReport)},"Relatório de inventário")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
    
	oSection1 := TRSection():New(oReport, "Rel.Inventário", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"FILIAL"		,"QRY","Filial"     ,"@E 99",2)
	TRCell():New(oSection1,"ARMAZEM"	,"QRY","Armazém"    ,"@E 99",2)
	TRCell():New(oSection1,"FABRICANTE" ,"QRY","Fabricante"	,"@!",12)
	TRCell():New(oSection1,"CODFAB"  	,"QRY","Cod.Fab"	,"@!",12)
	TRCell():New(oSection1,"CODIGO"  	,"QRY","Codigo"    	,"@!",50)
    TRCell():New(oSection1,"DESCRICAO"  ,"QRY","Descrição"  ,"@!",150)
    TRCell():New(oSection1,"QUANTIDADE" ,"QRY","Quantidade" ,"@E 99999999",9)
    
    
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)


/*/{Protheus.doc} BFESTR02
(Query dos produtos com estoque e custo)
@author Iago Luiz Raimondi
@since 11/01/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport)

	Local oSection1 := oReport:Section(1)
	Local cQry		:= ""

	cQry += "SELECT B1_FILIAL AS FILIAL,"
	cQry += "       B1_LOCPAD AS ARMAZEM,"
	cQry += "       TRIM(B1_PROC) AS COD_FOR,"
	cQry += "       CASE WHEN B1_FABRIC = ' ' THEN 'SEM CODIGO' ELSE TRIM(B1_FABRIC) END  AS COD_FAB,"
	cQry += "       TRIM(B1_COD) AS CODIGO,"
	cQry += "       TRIM(B1_DESC) AS DESCRICAO"
	cQry += "  FROM "+ RetSqlName("SB1") +" B1"
	cQry += " WHERE B1.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.B1_MSBLQL != '1'"
	cQry += "   AND B1.B1_FILIAL = '"+ xFilial("SB1") +"'"
	cQry += "   AND B1.B1_LOCPAD BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry += "   AND B1.B1_PROC BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
	cQry += "   AND B1.B1_COD BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"'"
	If MV_PAR07 == 1 // Normal
		cQry += "   AND B1.B1_BLOQFAT = 'N'"
	ElseIf MV_PAR07 == 2 // Ativo Fixo
		cQry += "   AND B1.B1_BLOQFAT = 'A'"
	ElseIf MV_PAR07 == 3 // Mat.Consumo
		cQry += "   AND B1.B1_BLOQFAT = 'C'"
	ElseIf MV_PAR07 == 4 // Promocional
		cQry += "   AND B1.B1_BLOQFAT = 'P'"
	EndIf
	cQry += " ORDER BY B1.B1_FILIAL, B1.B1_LOCPAD, B1.B1_DESC"
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	ENDIF
    
	TCQUERY cQry NEW ALIAS "QRY"
      	
    oSection1:Init() 	
	While QRY->(!EOF())	
	
		If oReport:Cancel()
			Exit
		EndIf
		
		oSection1:Cell("FILIAL"):SetValue(QRY->FILIAL)
		oSection1:Cell("ARMAZEM"):SetValue(QRY->ARMAZEM)
		oSection1:Cell("FABRICANTE"):SetValue(QRY->COD_FOR)
		oSection1:Cell("CODFAB"):SetValue(QRY->COD_FAB)
		oSection1:Cell("CODIGO"):SetValue(QRY->CODIGO)
		oSection1:Cell("DESCRICAO"):SetValue(QRY->DESCRICAO)
		oSection1:Cell("QUANTIDADE"):SetValue(" ")	
		oSection1:Printline()

		//Linha
		//oReport:IncRow()
		
		QRY->(dbSkip())
	Enddo	
	oSection1:Finish()
	
	oReport:EndPage()

	QRY->(DbCloseArea())

Return


/*/{Protheus.doc} BFESTR02
(Cria pergunta na SX1)
@author Iago Luiz Raimondi
@since 11/01/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg,'01','Armazém de','Armazém de','Armazém de', 'mv_ch1', 'C', 2, 0, 0, 'G', '', 'NNR', '', '', 'mv_par01')
	PutSx1(cPerg,'02','Armazém até','Armazém até','Armazém até', 'mv_ch2', 'C', 2, 0, 0, 'G', 'NaoVazio()', 'NNR', '', '', 'mv_par02')
	PutSx1(cPerg,'03','Fornecedor de','Fornecedor de','Fornecedor de', 'mv_ch3', 'C', Len(CriaVar("A2_COD")), 0, 0, 'G', '', 'SA2', '', '', 'mv_par03')
	PutSx1(cPerg,'04','Fornecedor até','Fornecedor até','Fornecedor até', 'mv_ch4', 'C', Len(CriaVar("A2_COD")), 0, 0, 'G', 'NaoVazio()', 'SA2', '', '', 'mv_par04')
	PutSx1(cPerg,'05','Produto de','Produto de','Produto de', 'mv_ch5', 'C', Len(CriaVar("B1_COD")), 0, 0, 'G', '', 'SB1', '', '', 'mv_par05')
	PutSx1(cPerg,'06','Produto até','Produto até','Produto até', 'mv_ch6', 'C', Len(CriaVar("B1_COD")), 0, 0, 'G', 'NaoVazio()', 'SB1', '', '', 'mv_par06')
	PutSx1(cPerg,'07','Tipo Prod.','Tipo Prod.','Tipo Prod.','mv_ch7','N', 1, 0, 0, 'C', '', '', '', '', 'mv_par07' ,'Normal','Normal','Normal','','Ativo Fixo','Ativo Fixo','Ativo Fixo','Mat.Consumo','Mat.Consumo','Mat.Consumo','Brinde','Brinde','Brinde','Todos','Todos','Todos')

Return
