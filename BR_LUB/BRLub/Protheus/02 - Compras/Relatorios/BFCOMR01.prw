#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFCOMR01
(Relatório de entradas por fornecedor)
@author Iago Luiz Raimondi
@since 20/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCOMR01()
	Local oReport
	Local cPerg	:= "BFCOMR01"
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
    
	sfCriaSx1(cPerg)
	Pergunte(cPerg,.F.)
        
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
    
Return


/*/{Protheus.doc} RptDef
(Montagem das colunas e totais)
@author Iago Luiz Raimondi
@since 20/07/2015
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
    
	oReport := TReport():New(cNome,"Entradas por fornecedor",cNome,{|oReport| ReportPrint(oReport)},"Relatório de entradas por fornecedor")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
    
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"FILIAL"    		,"QRY","Filial"    ,"@!",2)
	TRCell():New(oSection1,"FORNECE"			,"QRY","Fornecedor" ,"@!",6)
	TRCell():New(oSection1,"LOJA_FORNECE"  	,"QRY","Loja"   	,"@!",2)
	TRCell():New(oSection1,"EMISSAO"   		,"QRY","Emissão"    ,"@D",10)
	TRCell():New(oSection1,"NF"    			,"QRY","Nf"         ,"@!",10)
	TRCell():New(oSection1,"SERIE"    		,"QRY","Série"      ,"@!",5)
	TRCell():New(oSection1,"PROD"    		,"QRY","Cod.Prod"   ,"@!",15)
	TRCell():New(oSection1,"DESC_PROD"    	,"QRY","Desc.Prod"  ,"@!",40)
	TRCell():New(oSection1,"COD_FABRIC"    	,"QRY","Cod.Fabric"   ,"@!",15)	
	TRCell():New(oSection1,"QTD"    		,"QRY","Qtd"        ,"@E 999,999.99",10)
	TRCell():New(oSection1,"VUNIT"    		,"QRY","Valor Unit" ,"@E 99,999,999.99",15)	
	TRCell():New(oSection1,"TOTAL"    		,"QRY","Valor Total","@E 99,999,999.99",15)
	TRCell():New(oSection1,"LITROS"    		,"QRY","Litros"     ,"@E 99,999,999.99",15)		
		
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)


/*/{Protheus.doc} ReportPrint
(Geração da query e atribuição de valores nas colunas)
@author Iago Luiz Raimondi
@since 20/07/2015
@version 1.0
@param oReport, objeto, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport)

	Local oSection1 := oReport:Section(1)
	Local cQry		:= ""

	cQry += "SELECT D1.D1_FILIAL AS FILIAL,"
	cQry += "       D1.D1_FORNECE AS FORNECE,"
	cQry += "       D1.D1_LOJA AS LOJA_FORNECE,"
	cQry += "       D1.D1_EMISSAO AS EMISSAO,"
	cQry += "       D1.D1_DOC AS NF,"
	cQry += "       D1.D1_SERIE AS SERIE,"
	cQry += "       D1.D1_COD AS PROD,"
	cQry += "       B1.B1_DESC AS DESC_PROD,"
	cQry += "		B1.B1_FABRIC AS COD_FABRIC,"
	cQry += "       D1.D1_QUANT AS QTD,"
	cQry += "       D1.D1_VUNIT AS VUNIT,"
	cQry += "       D1.D1_TOTAL AS TOTAL,"
	cQry += "       (D1.D1_QUANT * B1.B1_QTELITS) AS LITROS"
	cQry += "  FROM "+ RetSqlName("SD1") + " D1"
	cQry += " INNER JOIN "+ RetSqlName("SF1") + " F1 ON F1.F1_FILIAL = D1.D1_FILIAL"
	cQry += "                     AND F1.F1_DOC = D1.D1_DOC"
	cQry += "                     AND F1.F1_SERIE = D1.D1_SERIE"
	cQry += "                     AND F1.F1_FORNECE = D1.D1_FORNECE"
	cQry += "                     AND F1.F1_LOJA = D1.D1_LOJA"
	cQry += " INNER JOIN "+ RetSqlName("SB1") + " B1 ON B1.B1_FILIAL = D1.D1_FILIAL"
	cQry += "                     AND B1.B1_COD = D1.D1_COD"
	cQry += " WHERE D1.D_E_L_E_T_ = ' '"
	cQry += "   AND B1.D_E_L_E_T_ = ' '"
	cQry += "   AND F1.D_E_L_E_T_ = ' '"
	cQry += "   AND D1.D1_FORNECE BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
	cQry += "   AND D1.D1_LOJA BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"'"
	cQry += "   AND D1.D1_EMISSAO BETWEEN '"+ DTOS(MV_PAR07) +"' AND '"+ DTOS(MV_PAR08) +"'"
	cQry += "   AND D1.D1_FILIAL BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry += "   AND B1.B1_TIPO != 'MP'"
	cQry += "   AND F1.F1_TIPO = 'N'"
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
    
	TCQUERY cQry NEW ALIAS "QRY"
	      	
	While QRY->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf
    	
		oSection1:Init()
		oSection1:Cell("FILIAL"):SetValue(QRY->FILIAL)
		oSection1:Cell("FORNECE"):SetValue(QRY->FORNECE)
		oSection1:Cell("LOJA_FORNECE"):SetValue(QRY->LOJA_FORNECE)
		oSection1:Cell("EMISSAO"):SetValue(STOD(QRY->EMISSAO))
		oSection1:Cell("NF"):SetValue(QRY->NF)
		oSection1:Cell("SERIE"):SetValue(QRY->SERIE)
		oSection1:Cell("PROD"):SetValue(QRY->PROD)
		oSection1:Cell("DESC_PROD"):SetValue(QRY->DESC_PROD)
		oSection1:Cell("COD_FABRIC"):SetValue(QRY->COD_FABRIC)
		oSection1:Cell("QTD"):SetValue(QRY->QTD)
		oSection1:Cell("VUNIT"):SetValue(QRY->VUNIT)
		oSection1:Cell("TOTAL"):SetValue(QRY->TOTAL)
		oSection1:Cell("LITROS"):SetValue(QRY->LITROS)
		oSection1:Printline()		
	
		QRY->(dbSkip())		
		
	Enddo
	
	oSection1:Finish()
	oReport:EndPage()
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
Return


/*/{Protheus.doc} sfCriaSx1
(Cria pergunta)
@author Iago Luiz Raimondi
@since 20/07/2015
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
	PutSx1(cPerg, '03', 'Fornecedor de' , 'Fornecedor de', 'Fornecedor de', 'mv_ch3', 'C', 6, 0, 0, 'G', '', 'SA2', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Fornecedor até' , 'Fornecedor até', 'Fornecedor até', 'mv_ch4', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA2', '', '', 'mv_par04')	
	PutSx1(cPerg, '05', 'Loja de' , 'Loja de', 'Loja de', 'mv_ch5', 'C', 2, 0, 0, 'G', '', '', '', '', 'mv_par05')
	PutSx1(cPerg, '06', 'Loja até' , 'Loja até', 'Loja até', 'mv_ch6', 'C', 2, 0, 0, 'G', 'NaoVazio()', '', '', '', 'mv_par06')
	PutSx1(cPerg, '07', 'Emissão de' , 'Emissão de', 'Emissão de', 'mv_ch7', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par07')
	PutSx1(cPerg, '08', 'Emissão até' , 'Emissão até', 'Emissão até', 'mv_ch8', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par08')
		
Return
