#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFESTR01
Rotina possibilita geração do Kardex Aglutinado
@author Iago Luiz Raimondi
@since 26/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFESTR01()

	Local oReport
	Local cPerg  := 'BFESTR01'
	Local cAlias := getNextAlias()

	sfCriaSx1(cPerg)
	Pergunte(cPerg, .F.)

	oReport := ReportDef(cAlias, cPerg)
	oReport:PrintDialog()

Return

/*/{Protheus.doc} ReportPrint
Gera os dados para impressão
@author Iago Luiz Raimondi
@since 26/02/2015
@version 1.0
@param oReport, objeto, (Descrição do parâmetro)
@param cAlias, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportPrint(oReport,cAlias)
              
	Local oSection1 := oReport:Section(1)

	oSection1:BeginQuery()
	
	// MV_PAR01 Tipo =  1-Entrada, 2-Saida
	If (MV_PAR01 == 2)
	
		oSection2 := TRSection():New(oSection1,"Kardex",{cAlias})
		TRCell():New(oSection2,"Filial",	cAlias, "Filial",,2)
		TRCell():New(oSection2,"Nota", 		cAlias, "Nota",,8)
		TRCell():New(oSection2,"Serie", 	cAlias, "Serie",,3)
		TRCell():New(oSection2,"CFOP", 		cAlias, "CFOP",,4)
		TRCell():New(oSection2,"Estoque", 	cAlias, "Estoque",,3)
		TRCell():New(oSection2,"Armazem", 	cAlias, "Armazem",,2)
		TRCell():New(oSection2,"Emissao", 	cAlias, "Emissao",,8)
		TRCell():New(oSection2,"Quantidade", cAlias, "Quantidade",,8)
		TRCell():New(oSection2,"Custo", 	cAlias, "Custo",,10)
		TRCell():New(oSection2,"Valor", 	cAlias, "Valor",,10)
		TRCell():New(oSection2,"Icms", 		cAlias, "Icms",,8)
		TRCell():New(oSection2,"Cofins", 	cAlias, "Cofins",,8)
		TRCell():New(oSection2,"Pis", 		cAlias, "Pis",,8)
		TRCell():New(oSection2,"Bruto", 	cAlias, "Bruto",,10)	
	
		BEGINSQL ALIAS cAlias
		
			column Emissao as date

			SELECT D2_FILIAL AS Filial,
			D2_DOC AS Nota,
			D2_SERIE AS Serie,
			D2_CF AS CFOP,
			D2_ESTOQUE AS Estoque,
			D2_LOCAL AS Armazem,
			D2_EMISSAO AS Emissao,
			SUM(D2_QUANT) AS Quantidade,
			SUM(D2_CUSTO1) AS Custo,
			SUM(D2_TOTAL) AS Valor,
			SUM(D2_VALICM) AS Icms,
			SUM(D2_VALIMP5) AS Cofins,
			SUM(D2_VALIMP6) AS  Pis,
			SUM(D2_VALBRUT) AS Bruto
			FROM %Table:SD2% D2, %Table:SF4% F4
			WHERE F4.%NotDel%
			AND F4_ESTOQUE = 'S'
			AND F4_CODIGO = D2_TES
			AND F4_FILIAL = D2_FILIAL
			AND D2.%NotDel%
			AND D2_COD BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
			AND D2_EMISSAO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
			AND D2_FILIAL != '  '
			GROUP BY D2_FILIAL, D2_DOC, D2_SERIE, D2_CF, D2_ESTOQUE,D2_EMISSAO,D2_LOCAL
			ORDER BY D2_FILIAL, D2_DOC
		ENDSQL
		
	Else
	
		oSection2 := TRSection():New(oSection1,"Kardex",{cAlias})
		TRCell():New(oSection2,"Filial",	cAlias, "Filial",,2)
		TRCell():New(oSection2,"Nota", 		cAlias, "Nota",,8)
		TRCell():New(oSection2,"Serie", 	cAlias, "Serie",,3)
		TRCell():New(oSection2,"CFOP", 		cAlias, "CFOP",,4)
		TRCell():New(oSection2,"Armazem", 	cAlias, "Armazem",,2)
		TRCell():New(oSection2,"Conta", 	cAlias, "Conta",,8)
		TRCell():New(oSection2,"DtDigit", 	cAlias, "DtDigit",,8)
		TRCell():New(oSection2,"Quantidade", cAlias, "Quantidade",,8)
		TRCell():New(oSection2,"Custo", 	cAlias, "Custo",,10)
		TRCell():New(oSection2,"Valor", 	cAlias, "Valor",,10)
		TRCell():New(oSection2,"Icms", 		cAlias, "Icms",,8)
		TRCell():New(oSection2,"Cofins", 	cAlias, "Cofins",,8)
		TRCell():New(oSection2,"Pis", 		cAlias, "Pis",,8)
		
		BEGINSQL ALIAS cAlias
			column DtDigit as date
			SELECT D1_FILIAL AS Filial,
			       D1_DOC AS Nota,
			       D1_SERIE AS Serie,
			       D1_CF AS CFOP,
			       D1_LOCAL AS Armazem,
			       D1_CONTA AS Conta,
			       D1_DTDIGIT AS DtDigit,
			       SUM(D1_QUANT) AS Quantidade,
			       SUM(D1_CUSTO) AS Custo,
			       SUM(D1_TOTAL-D1_VALDESC) AS Valor,
			       SUM(D1_VALICM) AS Icms,
			       SUM(D1_VALIMP5) AS Cofins,
			       SUM(D1_VALIMP6) AS Pis
			  FROM %Table:SD1% D1, %Table:SF4% F4
			 WHERE F4.%NotDel%
			   AND F4_ESTOQUE = 'S'
			   AND F4_CODIGO = D1_TES
			   AND F4_FILIAL = D1_FILIAL
			   AND D1.D_E_L_E_T_ = ' '
			   AND D1_DTDIGIT BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
			   AND D1_COD BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
			   AND D1_FILIAL != '  '
			 GROUP BY D1_FILIAL, D1_DOC, D1_SERIE, D1_CF, D1_DTDIGIT,D1_CONTA,D1_LOCAL
			 ORDER BY D1_FILIAL, D1_DOC
		ENDSQL
	EndIf

	oSection1:EndQuery()
	oReport:SetMeter((cAlias)->(RecCount()))
	oSection1:Print()

Return
 
 
/*/{Protheus.doc} ReportDef
Instancia Objeto e abre tela para impressão
@author Iago Luiz Raimondi
@since 26/02/2015
@version 1.0
@param cAlias, character, (Descrição do parâmetro)
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ReportDef(cAlias,cPerg)

	Local cTitle  := "Relatório Kardex Aglutinado"
	Local cHelp   := "Permite gerar o Kardex aglutinado por periodo ou produto"
	Local oReport
	Private oSection1

	oReport := TReport():New('BFESTR01',cTitle,cPerg,{|oReport| ReportPrint(oReport,cAlias)},cHelp)
	oSection1 := TRSection():New(oReport,"Kardex",{cAlias})

Return(oReport)


/*/{Protheus.doc} sfCriaSx1
Cria perguntas caso não existam
@author Iago Luiz Raimondi
@since 26/02/2015
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg, '01', 'Tipo' , 'Tipo', 'Tipo', 'mv_ch1', 'C', 30, 0, 0, 'C', 'NaoVazio()', '', '', '', 'mv_par01','Entrada','Entrada','Entrada','','Saida','Saida','Saida','')
	PutSx1(cPerg, '02', 'Data de' , 'Data de', 'Data de', 'mv_ch2', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par02')
	PutSx1(cPerg, '03', 'Data até' , 'Data até', 'Data até', 'mv_ch3', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Produto de' , 'Produto de', 'Produto de', 'mv_ch4', 'C', Len(CriaVar("B1_COD")), 0, 0, 'G', '', 'SB1', '', '', 'mv_par04')
	putSx1(cPerg, '05', 'Produto até' , 'Produto até', 'Produto até', 'mv_ch5', 'C', Len(CriaVar("B1_COD")), 0, 0, 'G', 'NaoVazio()', 'SB1', '', '', 'mv_par05')

Return

