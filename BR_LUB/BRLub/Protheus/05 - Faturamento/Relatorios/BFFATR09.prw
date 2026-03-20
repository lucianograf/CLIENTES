#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFFATR09
(Relatório de devolução de armazenagem)
@author Iago Luiz Raimondi
@since 02/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR09()
	Local oReport
	Local cPerg	:= "BFFATR09"
	
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
@since 02/10/2015
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
	Local oBreak
	Local oFunction
    
	oReport := TReport():New(cNome,"Relatório de devolução de armazenagem",cNome,{|oReport| ReportPrint(oReport)},"Relatório de devolução de armazenagem")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
    
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"COD"		,"QRY","Código"     ,"@!",30)
	TRCell():New(oSection1,"DESCR"  	,"QRY","Descrição"   ,"@!",50)
	TRCell():New(oSection1,"SOMA"  		,"QRY","Quantidade"   ,"@E 9999999",12)
	
    TRFunction():New(oSection1:Cell("SOMA"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
		
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
	
	// Busca todos os registros
	cQry := ""
	cQry += "SELECT D2_COD AS COD, B1_DESC AS DESCR, SUM(D2_QUANT) AS SOMA"
	cQry += "  FROM "+ RetSqlName("SD2") + " D2, "+ RetSqlName("SB1") + " B1"
	cQry += " WHERE B1.D_E_L_E_T_ = ' '"
	cQry += "   AND B1_COD = D2_COD"
	cQry += "   AND B1_FILIAL = '"+ xFilial("SB1") +"'"
	cQry += "   AND D2.D_E_L_E_T_ = ' '"
	cQry += "   AND D2_COD IN (SELECT D2_COD"
	cQry += "                    FROM SD2020"
	cQry += "                   WHERE D2_CLIENTE = '"+ MV_PAR03 +"'"
	cQry += "                     AND D2_FILIAL = '"+ xFilial("SB1") +"'"
	cQry += "                     AND D2_EMISSAO >= '"+ DToS(MV_PAR04) +"'"
	cQry += "                     AND D2_LOCAL BETWEEN  '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"')"
	cQry += "   AND D2_ESTOQUE = 'S'"
	cQry += "   AND D2_LOCAL BETWEEN  '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry += "   AND D2_FILIAL = '"+ xFilial("SD2") +"'"
	cQry += "   AND D2_EMISSAO BETWEEN '"+ DToS(MV_PAR04) +"' AND '"+ DToS(MV_PAR05) +"'"
	cQry += " GROUP BY D2_COD, B1_DESC"	
           
	TCQUERY cQry NEW ALIAS "QRY"
    
	While QRY->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf
    	
		oSection1:Init()
		oSection1:Cell("COD"):SetValue(QRY->COD)
		oSection1:Cell("DESCR"):SetValue(QRY->DESCR)
		oSection1:Cell("SOMA"):SetValue(QRY->SOMA)
		oSection1:Printline()
		QRY->(dbSkip())			
	Enddo
	
	QRY->(DbCloseArea())
	
	oSection1:Finish()
	
	
	// Busca apenas o numero das nfs referente aos registros gerados acima.
	cQry2 := ""
	cQry2 += "SELECT DISTINCT D2_DOC"
	cQry2 += "  FROM "+ RetSqlName("SD2") + " D2, "+ RetSqlName("SB1") + " B1"
	cQry2 += " WHERE B1.D_E_L_E_T_ = ' '"
	cQry2 += "   AND B1_COD = D2_COD"
	cQry2 += "   AND B1_FILIAL = '"+ xFilial("SB1") +"'"
	cQry2 += "   AND D2.D_E_L_E_T_ = ' '"
	cQry2 += "   AND D2_COD IN (SELECT D2_COD"
	cQry2 += "                    FROM SD2020"
	cQry2 += "                   WHERE D2_CLIENTE = '"+ MV_PAR03 +"'"
	cQry2 += "                     AND D2_FILIAL = '"+ xFilial("SB1") +"'"
	cQry2 += "                     AND D2_EMISSAO >= '"+ DToS(MV_PAR04) +"'"
	cQry2 += "                     AND D2_LOCAL BETWEEN  '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"')"
	cQry2 += "   AND D2_ESTOQUE = 'S'"
	cQry2 += "   AND D2_LOCAL BETWEEN  '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry2 += "   AND D2_FILIAL = '"+ xFilial("SD2") +"'"
	cQry2 += "   AND D2_EMISSAO BETWEEN '"+ DToS(MV_PAR04) +"' AND '"+ DToS(MV_PAR05) +"'"
	
	TcQuery cQry2 New Alias "QRY2"
	
	aNotas := {}
	While QRY2->(!EOF())
		Aadd(aNotas,AllTrim(QRY2->D2_DOC))
		QRY2->(dbSkip())			
	Enddo	
	oReport:PrintText(" Ref.NF: ",,oSection1:Cell("COD"):ColPos())
	nX := 1
	cNotas := ""
	For nI := 1 To Len(aNotas)
		cNotas += aNotas[nI]+" | "
		nX++		
		If nX == 15 .OR. nI == Len(aNotas)
			oReport:PrintText(" "+cNotas,,oSection1:Cell("COD"):ColPos())
			cNotas := ""
			nX := 1
		EndIf
	Next
	
	QRY2->(DbCloseArea())
	
	
	oReport:EndPage()
Return


/*/{Protheus.doc} sfCriaSx1
(Cria pergunta)
@author Iago Luiz Raimondi
@since 02/10/2015
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg, '01', 'Armazém de' , 'Armazém de' , 'Armazém de' , 'mv_ch1', 'C', 2, 0, 0, 'G', '', 'NNR', '', '', 'mv_par01')
	PutSx1(cPerg, '02', 'Armazém até', 'Armazém até', 'Armazém até', 'mv_ch2', 'C', 2, 0, 0, 'G', 'NaoVazio()', 'NNR', '', '', 'mv_par02')
	PutSx1(cPerg, '03', 'Fornecedor' , 'Fornecedor' , 'Fornecedor' , 'mv_ch3', 'C', 6, 0, 0, 'G', '', 'SA2', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Emissão de' , 'Emissão de' , 'Emissão de' , 'mv_ch4', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par04')
	PutSx1(cPerg, '05', 'Emissão até', 'Emissão até', 'Emissão até', 'mv_ch5', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par05')
	
Return
