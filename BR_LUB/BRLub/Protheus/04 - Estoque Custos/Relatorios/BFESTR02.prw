#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFESTR02
(Relatório de estoque com informações de litros e custo + imp.saida)
@author Iago Luiz Raimondi
@since 07/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFESTR02()
	Local oReport
	Local cPerg	:= "BFESTR02"
	Private aStatus := {}
    
	sfCriaSx1(cPerg)
	Pergunte(cPerg,.F.)
        
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
    
Return


/*/{Protheus.doc} BFESTR02
(Montagem do objeto oReport)
@author Iago Luiz Raimondi
@since 07/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RptDef(cNome)

	Local oReport 	:= Nil
	Local oSection1 := Nil
	    
	oReport := TReport():New(cNome,"Estoque geral",cNome,{|oReport| ReportPrint(oReport)},"Relatório de estoque")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
    
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"CODIGO"			,"QRY","Código"     	,"@!",20)
	TRCell():New(oSection1,"ARMAZEM"		,"QRY","Armazém"     	,"@!",2)
	TRCell():New(oSection1,"FORNECEDOR"  	,"QRY","Fornecedor"		,"@!",8)
	TRCell():New(oSection1,"FABRIC"  		,"QRY","Cod.Fabric."	,"@!",12)
	TRCell():New(oSection1,"DESCRICAO"  	,"QRY","Descrição"    	,"@!",50)
    TRCell():New(oSection1,"FISICO"  		,"QRY","Qtd.Físico"    	,"@E 99999999",8)
    TRCell():New(oSection1,"LITROS"  		,"QRY","Qtd.Litros"    	,"@E 99999999",8)
    TRCell():New(oSection1,"DISPONIVEL"  	,"QRY","Qtd.Disp"    	,"@E 99999999",8)
    TRCell():New(oSection1,"LITROS_DISPO"  	,"QRY","Litros.Disp"    ,"@E 99999999",8)
    TRCell():New(oSection1,"CUSTO"  		,"QRY","Custo+Imp.Saida","@E 999,999,999.99",15)
    TRCell():New(oSection1,"KARDEX"  		,"QRY","Custo Kardex"   ,"@E 999,999,999.99",15)
    
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)


/*/{Protheus.doc} BFESTR02
(Query dos produtos com estoque e custo)
@author Iago Luiz Raimondi
@since 07/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport)

	Local oSection1 := oReport:Section(1)
	Local cQry		:= ""

	cQry += "SELECT B1_COD AS CODIGO,"
	cQry += "       B1_DESC AS DESCRICAO,"
	cQry += "       B2_LOCAL AS ARMAZEM,"
	cQry += "       B1_PROC AS FORNECEDOR,"
	cQry += "       B1_FABRIC AS FABRIC,"
	cQry += "       B2.B2_QATU AS FISICO,"
	cQry += "       (B2.B2_QATU * B1.B1_QTELITS) AS LITROS,"
	cQry += "       (B2.B2_QATU - B2.B2_RESERVA) AS DISPONIVEL,"
	cQry += "       ((B2.B2_QATU - B2.B2_RESERVA) * B1.B1_QTELITS) AS LITROS_DISPO,"
	cQry += " 		CASE"
	cQry += "      		WHEN B2.B2_CM1 + (B2.B2_CM1 * ((B1.B1_PPIS + B1.B1_PCOFINS) / 100)) != 0 THEN"
	cQry += "            B2.B2_CM1 + (B2.B2_CM1 * ((B1.B1_PPIS + B1.B1_PCOFINS) / 100))"
	cQry += "      	ELSE"
	cQry += "       	B1.B1_CUSTD"
	cQry += "    	END AS CUSTO,"
	cQry += "       B2_CM1 AS KARDEX"
	cQry += "  FROM "+ RetSqlName("SB1") + " B1"
	cQry += " INNER JOIN "+ RetSqlName("SB2") + " B2 ON B2.B2_FILIAL = B1.B1_FILIAL"
	cQry += "                     AND B2.B2_COD = B1.B1_COD"
	cQry += " WHERE B1.D_E_L_E_T_ = ' '"
	cQry += "   AND B2.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.B1_MSBLQL != '1'"
	cQry += "   AND B1.B1_FILIAL = '"+ xFilial("SB1") +"'"
	cQry += "   AND B1.B1_COD BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
	cQry += "   AND B1.B1_PROC BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"'"
	cQry += "   AND B2.B2_LOCAL BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'"
	cQry += " ORDER BY B1.B1_COD, B2_LOCAL"
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	ENDIF
    
	TCQUERY cQry NEW ALIAS "QRY"
      	
    oSection1:Init() 	
	While QRY->(!EOF())	
	
		If oReport:Cancel()
			Exit
		EndIf
		
		oSection1:Cell("CODIGO"):SetValue(QRY->CODIGO)
		oSection1:Cell("ARMAZEM"):SetValue(QRY->ARMAZEM)
		oSection1:Cell("FORNECEDOR"):SetValue(QRY->FORNECEDOR)
		oSection1:Cell("FABRIC"):SetValue(QRY->FABRIC)
		oSection1:Cell("DESCRICAO"):SetValue(QRY->DESCRICAO)
		oSection1:Cell("FISICO"):SetValue(QRY->FISICO)
		oSection1:Cell("LITROS"):SetValue(QRY->LITROS)
		oSection1:Cell("DISPONIVEL"):SetValue(QRY->DISPONIVEL)
		oSection1:Cell("LITROS_DISPO"):SetValue(QRY->LITROS_DISPO)
		oSection1:Cell("CUSTO"):SetValue(Round(QRY->CUSTO,2))
		oSection1:Cell("KARDEX"):SetValue(Round(QRY->KARDEX,2))	
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
@since 07/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg,'01','Produto de','Produto de','Produto de', 'mv_ch1', 'C', Len(CriaVar("B1_COD")), 0, 0, 'G', '', 'SB1', '', '', 'mv_par01')
	PutSx1(cPerg,'02','Produto até','Produto até','Produto até', 'mv_ch2', 'C', Len(CriaVar("B1_COD")), 0, 0, 'G', '', 'SB1', '', '', 'mv_par02')
	PutSx1(cPerg,'03','Fornecedor de','Fornecedor de','Fornecedor de', 'mv_ch3', 'C', Len(CriaVar("A2_COD")), 0, 0, 'G', '', 'SA2', '', '', 'mv_par03')
	PutSx1(cPerg,'04','Fornecedor até','Fornecedor até','Fornecedor até', 'mv_ch4', 'C', Len(CriaVar("A2_COD")), 0, 0, 'G', '', 'SA2', '', '', 'mv_par04')
	PutSx1(cPerg,'05','Armazém de','Armazém de','Armazém de', 'mv_ch5', 'C', 2, 0, 0, 'G', '', 'NNR', '', '', 'mv_par05')
	PutSx1(cPerg,'06','Armazém até','Armazém até','Armazém até', 'mv_ch6', 'C', 2, 0, 0, 'G', '', 'NNR', '', '', 'mv_par06')

Return