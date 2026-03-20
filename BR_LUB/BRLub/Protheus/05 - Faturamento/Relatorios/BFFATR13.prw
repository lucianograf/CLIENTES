#Include 'Protheus.ch'
#Include 'Topconn.ch'

/*/{Protheus.doc} BFFATR11
(Relatório de quantidade envase feito por tanque)
@author Iago Luiz Raimondi
@since 02/08/2016
@version 1.0
@return ${return}, ${return_description}
@example (examples)
@see ()
/*/
User Function BFFATR13()
	
	Local oReport
	Local cPerg	:= "BFFATR13"
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	//sfCriaSx1(cPerg)
	
	Pergunte(cPerg,.F.)
	
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
	
Return

/*/{Protheus.doc} RptDef
(Montagem da seção)
@author Iago Luiz Raimondi
@since 02/08/2016
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
	
	oReport := TReport():New(cNome,"Relação de envases",cNome,{|oReport| ReportPrint(oReport)},"Relatório de envases por tanque.")
	oReport:SetLandScape()	
	oReport:SetTotalInLine(.F.)
	
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"FILIAL" ,"QRY","Filial" 	  	,"@!",02)
	TRCell():New(oSection1,"PROD" 	,"QRY","Produto"      	,"@!",20)
	TRCell():New(oSection1,"DESCR" 	,"QRY","Descrição"		,"@!",50)
	TRCell():New(oSection1,"CHAPA" ,"QRY","Chapa"		 	,"@!",12)
	TRCell():New(oSection1,"QTDENV" ,"QRY","Qtd.Env."    	,"@E 999999",6)
		
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)



/*/{Protheus.doc} ReportPrint
(Impressão do relatório)
@author Iago Luiz Raimondi
@since 02/08/2016
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
	
	
	cQry += "SELECT N1.N1_FILIAL AS FILIAL,"
	cQry += "       N1.N1_PRODUTO AS PROD,"
	cQry += "       N1.N1_DESCRIC AS DESCR,"
	cQry += "       N1.N1_CHAPA AS CHAPA,"
	cQry += "       (SELECT COUNT(*)"
	cQry += "          FROM PA2020 PA2"
	cQry += "         WHERE PA2.D_E_L_E_T_ = ' '"
	cQry += "           AND PA2.PA2_FILIAL = N1.N1_FILIAL"
	cQry += "           AND PA2.PA2_CHAPA = N1.N1_CHAPA"
	cQry += "           AND PA2.PA2_DATFIM != ' ') AS QTDENV"
	cQry += "  FROM "+ RetSqlName("SN1") +" N1"
	cQry += " WHERE N1.D_E_L_E_T_ = ' '"
	cQry += "   AND N1.N1_BAIXA = ' '"
	cQry += "   AND N1.N1_PRODUTO IN ('AI1591', 'AI1590')"
	cQry += "   AND N1.N1_FILIAL BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
	cQry += " UNION ALL "
	cQry += "SELECT ATB.ATB_FIL AS FILIAL,"
	cQry += "       ATB.ATB_CODIGO AS PROD,"
	cQry += "       ATB.ATB_DESCRI AS DESCR,"
	cQry += "       ATB.ATB_CHAPA AS CHAPA,"
	cQry += "       (SELECT COUNT(*)"
	cQry += "          FROM PA2020 PA2"
	cQry += "         WHERE PA2.D_E_L_E_T_ = ' '"
	cQry += "           AND PA2.PA2_FILIAL = ATB.ATB_FIL"
	cQry += "           AND PA2.PA2_CHAPA = ATB.ATB_CHAPA"
	cQry += "           AND PA2.PA2_DATFIM != ' ') AS QTDENV"
	cQry += "  FROM BIGFORTA.BIGFORTA_ATFTB ATB"
	cQry += " WHERE ATB.ATB_FIL BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
		
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
		oSection1:Cell("PROD"):SetValue(QRY->PROD)
		oSection1:Cell("DESCR"):SetValue(QRY->DESCR)
		oSection1:Cell("CHAPA"):SetValue(QRY->CHAPA)
		oSection1:Cell("QTDENV"):SetValue(QRY->QTDENV)
		
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
(Cria perguntas da rotina)
@author Iago Luiz Raimondi
@since 02/08/2016
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)
	
	PutSx1(cPerg, '01', 'Filial de', 'Filial de', 'Filial de', 'mv_ch1', 'C', 2, 0, 0, 'G', ''          , 'SM0', '', '', 'mv_par01')
	PutSx1(cPerg, '02', 'Filial até', 'Filial até', 'Filial até', 'mv_ch2', 'C', 2, 0, 0, 'G', 'NaoVazio()', 'SM0', '', '', 'mv_par02')
	
Return
