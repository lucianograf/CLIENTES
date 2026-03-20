#Include 'Protheus.ch'
#Include 'Topconn.ch'

/*/{Protheus.doc} BFFATR11
(Relatório de Recargas solicitadas pelo vendedor no RecargaWEB)
@author Iago Luiz Raimondi
@since 25/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
User Function BFFATR12()
	
	
	Local oReport
	Local cPerg	:= "BFFATR12"
	
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
@since 25/04/2015
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
	
	oReport := TReport():New(cNome,"Relação de recargas",cNome,{|oReport| ReportPrint(oReport)},"Relatório de recargas solicitadas pelo vendedor.")
	oReport:SetLandScape()	
	oReport:SetTotalInLine(.F.)
	
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"COD_CLI" ,"QRY","Cliente" 	  ,"@!",12)
	TRCell():New(oSection1,"LOJ_CLI" ,"QRY","Loja"    	  ,"@!",08)
	TRCell():New(oSection1,"NOM_CLI" ,"QRY","Razão Social","@!",60)
	TRCell():New(oSection1,"COD_CON" ,"QRY","Contato" 	  ,"@!",12)
	TRCell():New(oSection1,"NOM_CON" ,"QRY","Nome"    	  ,"@!",40)
	TRCell():New(oSection1,"COD_VEN" ,"QRY","Vendedor"	  ,"@!",06)
	TRCell():New(oSection1,"NOM_VEN" ,"QRY","Nome"		  ,"@!",40)
	TRCell():New(oSection1,"DAT_INC" ,"QRY","Dt.Inclusão" ,"@!",12)
	TRCell():New(oSection1,"USR_APR" ,"QRY","Usr.Aprov"	  ,"@!",40)
	TRCell():New(oSection1,"DAT_APR" ,"QRY","Dt.Aprov"	  ,"@!",12)
	TRCell():New(oSection1,"USR_PAG" ,"QRY","Usr.Pagam"	  ,"@!",40)
	TRCell():New(oSection1,"DAT_PAG" ,"QRY","Dt.Pagam"	  ,"@!",12)
	TRCell():New(oSection1,"USR_REJ" ,"QRY","Usr.Rejei"	  ,"@!",40)
	TRCell():New(oSection1,"DAT_REJ" ,"QRY","Dt.Rejei"	  ,"@!",12)
	TRCell():New(oSection1,"VALOR"	 ,"QRY","Valor"	 	  ,"@E 99,999,999.99",14)
	TRCell():New(oSection1,"VALORCTAXA"	 ,"QRY","Valor C/Taxa"	 	  ,"@E 99,999,999.99",14)
	TRCell():New(oSection1,"STATUS"	 ,"QRY","Status"	  ,"@!",20)
	TRCell():New(oSection1,"OBS"	 ,"QRY","Obs"	 	  ,"@!",40)	
		
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)



/*/{Protheus.doc} ReportPrint
(Impressão do relatório)
@author Iago Luiz Raimondi
@since 25/04/2016
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
	
	cQry += "SELECT R.COD_CLI AS COD_CLI,"
	cQry += "       R.LOJA_CLI AS LOJ_CLI,"
	cQry += "       A1.A1_NOME AS NOM_CLI,"
	cQry += "       R.COD_CONT AS COD_CON,"
	cQry += "       U5.U5_CONTAT AS NOM_CON,"
	cQry += "       U5.U5_CPF AS CPF_CON,"
	cQry += "       R.COD_VEND AS COD_VEN,"
	cQry += "       A3.A3_NOME AS NOM_VEN,"
	cQry += "       TO_CHAR(DATA_INC, 'YYYYMMDD') AS DAT_INC,"
	cQry += "       USER_APR AS USR_APR,"
	cQry += "       TO_CHAR(DATA_APR, 'YYYYMMDD') AS DAT_APR,"
	cQry += "       USER_PAG AS USR_PAG,"
	cQry += "       TO_CHAR(DATA_PAG, 'YYYYMMDD') AS DAT_PAG,"
	cQry += "       USER_REJ AS USR_REJ,"
	cQry += "       TO_CHAR(DATA_REJ, 'YYYYMMDD') AS DAT_REJ,"
	cQry += "       VALOR AS VALOR,"
	cQry += "       STATUS AS STATUS,"
	cQry += "       OBS AS OBS"
	cQry += "  FROM RECARGAWEB.RECARGA_ENVIO R"
	cQry += " INNER JOIN "+ RetSqlName("SA1") +" A1 ON A1.A1_FILIAL = ' '"
	cQry += "                     AND A1.A1_COD = R.COD_CLI"
	cQry += "                     AND A1.A1_LOJA = R.LOJA_CLI"
	cQry += " INNER JOIN "+ RetSqlName("SU5") +" U5 ON U5.U5_FILIAL = ' '"
	cQry += "                     AND U5.U5_CODCONT = R.COD_CONT"
	cQry += " INNER JOIN "+ RetSqlName("SA3") +" A3 ON A3.A3_FILIAL = ' '"
	cQry += "                     AND A3.A3_COD = R.COD_VEND"
	cQry += " WHERE A1.D_E_L_E_T_ = ' '"
	cQry += "   AND U5.D_E_L_E_T_ = ' '"
	cQry += "   AND A3.D_E_L_E_T_ = ' '"
	cQry += "   AND TO_CHAR(R.DATA_INC, 'YYYYMMDD') BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"'"
	cQry += "   AND R.COD_CLI BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
	cQry += "   AND R.LOJA_CLI BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"'"
	cQry += "   AND R.COD_VEND BETWEEN '"+ MV_PAR07 +"' AND '"+ MV_PAR08 +"'"
		
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	While QRY->(!EOF())
		
		If oReport:Cancel()
			Exit
		EndIf
		
		oSection1:Init()
		oSection1:Cell("COD_CLI"):SetValue(QRY->COD_CLI)
		oSection1:Cell("LOJ_CLI"):SetValue(QRY->LOJ_CLI)
		oSection1:Cell("NOM_CLI"):SetValue(QRY->NOM_CLI)
		oSection1:Cell("COD_CON"):SetValue(QRY->COD_CON)
		oSection1:Cell("NOM_CON"):SetValue(QRY->NOM_CON)
		oSection1:Cell("COD_VEN"):SetValue(QRY->COD_VEN)
		oSection1:Cell("NOM_VEN"):SetValue(QRY->NOM_VEN)
		oSection1:Cell("DAT_INC"):SetValue(SToD(QRY->DAT_INC))
		oSection1:Cell("USR_APR"):SetValue(QRY->USR_APR)
		oSection1:Cell("DAT_APR"):SetValue(SToD(QRY->DAT_APR))
		oSection1:Cell("USR_PAG"):SetValue(QRY->USR_PAG)
		oSection1:Cell("DAT_PAG"):SetValue(SToD(QRY->DAT_PAG))
		oSection1:Cell("USR_REJ"):SetValue(QRY->USR_REJ)
		oSection1:Cell("DAT_REJ"):SetValue(SToD(QRY->DAT_REJ))
		oSection1:Cell("VALOR"):SetValue(QRY->VALOR)
		oSection1:Cell("VALORCTAXA"):SetValue(Round(QRY->VALOR+(QRY->VALOR*.05),2))
		If QRY->STATUS = 1
			oSection1:Cell("STATUS"):SetValue("Aguard.Aprov")
		ElseIf QRY->STATUS = 2
			oSection1:Cell("STATUS"):SetValue("Aguard.Pag")
		ElseIf QRY->STATUS = 3
			oSection1:Cell("STATUS"):SetValue("Pag.Efetuado")
		Else
			oSection1:Cell("STATUS"):SetValue("Rejeitado")
		EndIf
		oSection1:Cell("OBS"):SetValue(QRY->OBS)
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
@since 25/04/2016
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)
	
	PutSx1(cPerg, '01', 'Data de' ,'Data de', 'Data de', 'mv_ch1', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par01')
	PutSx1(cPerg, '02', 'Data até' ,'Data até', 'Data até', 'mv_ch2', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par02')
	PutSx1(cPerg, '03', 'Cliente de' ,'Cliente de' , 'Cliente de' , 'mv_ch3', 'C', 6, 0, 0, 'G', '', 'SA1', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Cliente até','Cliente até', 'Cliente até', 'mv_ch4', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA1', '', '', 'mv_par04')
	PutSx1(cPerg, '05', 'Loja de' , 'Loja de' , 'Loja de' , 'mv_ch5', 'C', 2, 0, 0, 'G', '', '', '', '', 'mv_par05')
	PutSx1(cPerg, '06', 'Loja até', 'Loja até', 'Loja até', 'mv_ch6', 'C', 2, 0, 0, 'G', 'NaoVazio()', '', '', '', 'mv_par06')
	PutSx1(cPerg, '07', 'Vendedor de' , 'Vendedor de' , 'Vendedor de' , 'mv_ch7', 'C', 6, 0, 0, 'G', '', 'SA3', '', '', 'mv_par07')
	PutSx1(cPerg, '08', 'Vendedor até', 'Vendedor até', 'Vendedor até', 'mv_ch8', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA3', '', '', 'mv_par08')
	
Return
