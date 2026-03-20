#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFFATR06
(Relatório romaneio de carga)
@author Iago Luiz Raimondi
@since 16/03/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR06()
	Local 		oReport
	Local 		cPerg		:= "BFFATR06"
	Private		cAlsSZ		:= IIf(cEmpAnt == "05","SZ2","SZ1")

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	//sfCriaSx1(cPerg)
	Pergunte(cPerg,.F.)

	oReport := RptDef(cPerg)
	oReport:PrintDialog()

Return


/*/{Protheus.doc} RptDef
(long_description)
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


	oReport := TReport():New(cNome,"Romaneio",cNome,{|oReport| ReportPrint(oReport)},"Descrição do relatório")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)

	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	oSection1:SetColSpace(0)

	TRCell():New(oSection1,"ROMANEI"		,"QRY","Romaneio"       ,"@!",40)
	TRCell():New(oSection1,"EMISSAO"  		,"QRY","Data Emissão"   ,"@!",30)
	TRCell():New(oSection1,"A4_NOME"  		,"QRY","Transportadora" ,"@!",50)

	oSection2:= TRSection():New(oReport, "Romaneio", {"QRY"},, .F., .T.)
	oSection1:SetColSpace(1)

	TRCell():New(oSection2,"CTRFIL"   		,"QRY","Sigla"			,"@!",3)
	TRCell():New(oSection2,"A1_MUN"       	,"QRY","Municipio"		,"@!",30)
	TRCell():New(oSection2,"A1_EST"      	,"QRY","UF"    			,"@!",2)
	TRCell():New(oSection2,"A1_NOME"    	,"QRY","Razão Social"   ,"@!",50)
	TRCell():New(oSection2,"A1_NREDUZ"    	,"QRY","Fantasia"       ,"@!",30)
	TRCell():New(oSection2,"F2_VOLUME1"   	,"QRY","Volume"         ,"@E 999999",10)
	TRCell():New(oSection2,"D2_PEDIDO"    	,"QRY","Pedido"         ,"@!",10,.T.)
	TRCell():New(oSection2,"F2_DOC"    		,"QRY","NF Cliente"    	,"@!",11,.T.)
	TRCell():New(oSection2,"F2_VALMERC"   	,"QRY","Valor NF"       ,"@E 99,999,999.99",13)
	TRCell():New(oSection2,"F2_PLIQUI"    	,"QRY","Peso"         	,"@E 99,999.999",10)

	TRFunction():New(oSection2:Cell("F2_PLIQUI"),  /*cID*/, "SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	TRFunction():New(oSection2:Cell("F2_VALMERC"), /*cID*/, "SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	TRFunction():New(oSection2:Cell("F2_VOLUME1"), /*cID*/, "SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)

	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)

Return(oReport)


/*/{Protheus.doc} ReportPrint
(long_description)
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
	Local cRoman	:= ""
	Local cDescLocRet	:= ""

	cQry += "SELECT DISTINCT A1_MUN,"
	cQry += "       A1_EST,"
	cQry += "       A1_NOME,"
	cQry += "       A1_NREDUZ,"
	cQry += "       F2_PLIQUI,"
	cQry += "       A4_NOME,"
	cQry += "       F2_VOLUME1,"
	cQry += "       F2_DOC,"
	cQry += "       F2_VALMERC,"
	cQry += "       F2_FILIAL,"
	cQry += "       D2_PEDIDO,"
	cQry += "       Z1_NOMERES NOMERES,"
	cQry += "       Z1_EMISSAO EMISSAO,"
	cQry += "       Z1_NOMEMOT NOMEMOT,"
	cQry += "       Z1_ROMANEI ROMANEI,"
	cQry += "       ISNULL(PAB_CTRFIL,'###') CTRFIL "

	cQry += "  FROM " + RetSqlName("SF2") + " F2 " 
	cQry += " INNER JOIN " + RetSqlName("SA1") + " A1 "
	cQry += "    ON A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_LOJA = F2_LOJA "
	cQry += "   AND A1_COD = F2_CLIENTE "
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "'"
	cQry += " INNER JOIN " + RetSqlName("SD2") + " D2 " 
	cQry += "    ON D2.D_E_L_E_T_ =' ' "
    cQry += "   AND D2_SERIE = F2_SERIE "
	cQry += "   AND D2_DOC = F2_DOC "
	cQry += "   AND D2_LOJA = F2_LOJA "	
	cQry += "   AND D2_CLIENTE = F2_CLIENTE"
	cQry += "   AND D2_FILIAL = '" + xFilial("SD2")+ "'"
	
	cQry += " INNER JOIN " + RetSqlName(cAlsSZ) + " Z1 " 
	cQry += "    ON Z1.D_E_L_E_T_ =' ' "
	cQry += "   AND Z1_ROMANEI BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'
	cQry += "   AND Z1_NOTAFIS = F2_DOC "
	cQry += "   AND Z1_SERIE = F2_SERIE "
	cQry += "   AND Z1_FILIAL = '" + xFilial(cAlsSZ) + "'"
	cQry += "   AND Z1_EMISSAO BETWEEN '"+ DTOS(MV_PAR03) +"' AND '"+ DTOS(MV_PAR04) +"'
	cQry += "   AND Z1_MSFIL IN('XX',F2_FILIAL) "
	cQry += "  LEFT JOIN " + RetSqlName("SA4") + " A4 " 
	cQry += "    ON A4.D_E_L_E_T_  = ' ' "
	cQry += "   AND A4_COD  = F2_TRANSP " 
	cQry += "   AND A4_FILIAL  = '" + xFilial("SA4")+ "'"
	cQry += "  LEFT JOIN " + RetSqlName("PAB") + " PAB "
	cQry += "    ON PAB.D_E_L_E_T_ = ' ' "
	cQry += "   AND PAB_CEP = A1_CEP "
	cQry += "   AND PAB_FILIAL = '" +xFilial("PAB")+ "'"
	
	If cEmpAnt+cFilAnt $ "0208"
		nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial MG é necessário escolher entre o armazém de Lubrificante ou Pneus!",{"01-Lubrificantes","02-Pneus"},3)
		cDescLocRet	:= ""
		If nOpcLoc == 2
			cQry += " AND D2_LOCAL = '02' "
			cDescLocRet	:= "Pneus"
		ElseIf nOpcLoc == 1
			cQry += " AND D2_LOCAL = '01' "
			cDescLocRet	:= "Lubrificantes"
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0204"
		nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial PR é necessário escolher entre o armazém da Texaco ou Continental",{"01-Texaco","02-Continental","03-Pneus Agro"},3)

		If nOpcLoc == 2
			cQry += " AND D2_LOCAL = '02' "
			cQry += " AND NOT EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = D2_COD AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"
			cDescLocRet	:= "Continental"
		ElseIf nOpcLoc == 1
			cQry += " AND D2_LOCAL = '01' "
			cDescLocRet	:= "Texaco / Diversos"
		Elseif nOpcLoc == 3
			cQry += "  AND EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = D2_COD AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"
		Else
			nOpcLoc := 4
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0201"
		nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial SC é necessário escolher entre o armazém da Texaco ou Continental",{"01-Texaco","02-Continental","03-Pneus Agro"},3)

		If nOpcLoc == 2
			cQry += " AND D2_LOCAL = '02' "
			cQry += " AND NOT EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = D2_COD AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"
			cDescLocRet	:= "Continental"
		ElseIf nOpcLoc == 1
			cQry += " AND D2_LOCAL = '01' "
			cDescLocRet	:= "Texaco / Diversos"
		Elseif nOpcLoc == 3
			cQry += "  AND EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = D2_COD AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"
		Else
			nOpcLoc := 4
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0205"
		nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial RS é necessário escolher entre o armazém da Texaco ou Continental",{"01-Texaco","02-Continental","03-Pneus Agro"},3)

		If nOpcLoc == 2
			cQry += " AND D2_LOCAL = '02' "
			cQry += " AND NOT EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = D2_COD AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"
			cDescLocRet	:= "Continental"
		ElseIf nOpcLoc == 1
			cQry += " AND D2_LOCAL = '01' "
			cDescLocRet	:= "Texaco / Diversos"
		Elseif nOpcLoc == 3
			cQry += "  AND EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = D2_COD AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"
		Else
			nOpcLoc := 4
		Endif
	Endif
	
	cQry += " WHERE F2.D_E_L_E_T_ =' ' "
	cQry += "   AND F2_TRANSP BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"'
	cQry += "   AND F2_FILIAL = '" + xFilial("SF2") + "'"  

	cQry += " ORDER BY Z1_ROMANEI, A1_MUN, A1_NOME, F2_DOC"

	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	ENDIF

	TCQUERY cQry NEW ALIAS "QRY"

	//Quebra por Romaneio
	cRoman :=  QRY->ROMANEI

	While QRY->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf

		cMotori := QRY->NOMEMOT
		cRespon := QRY->NOMERES

		oSection1:Init()
		oSection1:Cell("ROMANEI"):SetValue(QRY->ROMANEI)
		oSection1:Cell("EMISSAO"):SetValue(STOD(QRY->EMISSAO))
		oSection1:Cell("A4_NOME"):SetValue(QRY->A4_NOME)
		oSection1:Printline()
		oSection2:Init()
		nNotas := 0
		nRepet := 1
		cNome := ""
		lFirst := .T.
		While QRY->ROMANEI == cRoman
			If (cNome != AllTrim(QRY->A1_NOME) .And. !lFirst)
				oReport:ThinLine()
				nRepet++
			EndIf
			oSection2:Cell("CTRFIL"):SetValue(QRY->CTRFIL)
			oSection2:Cell("A1_MUN"):SetValue(QRY->A1_MUN)
			oSection2:Cell("A1_EST"):SetValue(QRY->A1_EST)
			oSection2:Cell("A1_NOME"):SetValue(QRY->A1_NOME)
			oSection2:Cell("A1_NREDUZ"):SetValue(QRY->A1_NREDUZ)
			oSection2:Cell("F2_VOLUME1"):SetValue(QRY->F2_VOLUME1)
			oSection2:Cell("D2_PEDIDO"):SetValue(QRY->D2_PEDIDO)
			oSection2:Cell("F2_DOC"):SetValue(QRY->F2_DOC)
			oSection2:Cell("F2_VALMERC"):SetValue(QRY->F2_VALMERC)
			oSection2:Cell("F2_PLIQUI"):SetValue(QRY->F2_PLIQUI)
			oSection2:Printline()

			lFirst := .F.
			cNome := AllTrim(QRY->A1_NOME)
			nNotas++
			QRY->(dbSkip())
		EndDo
		cRoman := QRY->ROMANEI

		oReport:IncRow()
		If !Empty(cDescLocRet)
			oReport:PrintText(" Minuta específica para produtos : "+ cDescLocRet ,,oSection2:Cell("A1_MUN"):ColPos())
		Endif 
		oReport:PrintText(" Nro de Notas: "+cValToChar(nNotas),,oSection2:Cell("A1_MUN"):ColPos())
		oReport:PrintText(" Nro de Entregas: "+cValToChar(nRepet),,oSection2:Cell("A1_MUN"):ColPos())
		oReport:PrintText("Assinatura:        _______________________________________",,oSection2:Cell("F2_VOLUME1"):ColPos())
		oReport:PrintText(" Nome Mot: "+cMotori,,oSection2:Cell("A1_MUN"):ColPos())
		oReport:PrintText("Assinatura:        _______________________________________",,oSection2:Cell("F2_VOLUME1"):ColPos())
		oReport:PrintText(" Nome Resp: "+cRespon,,oSection2:Cell("A1_MUN"):ColPos())

		oSection2:Finish()
		oReport:EndPage()
		oSection1:Finish()
	Enddo

	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	ENDIF
Return


/*/{Protheus.doc} sfCriaSx1
(long_description)
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

	PutSx1(cPerg, '01', 'Romaneio de' , 'Romaneio de', 'Romaneio de', 'mv_ch1', 'C', Len(CriaVar("Z1_ROMANEI")), 0, 0, 'G', '', '', '', '', 'mv_par01')
	putSx1(cPerg, '02', 'Romaneio até' , 'Romaneio até', 'Romaneio até', 'mv_ch2', 'C', Len(CriaVar("Z1_ROMANEI")), 0, 0, 'G', 'NaoVazio()', '', '', '', 'mv_par02')
	PutSx1(cPerg, '03', 'Emissão de' , 'Emissão de', 'Emissão de', 'mv_ch3', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Emissão até' , 'Emissão até', 'Emissão até', 'mv_ch4', 'D', 8, 0, 0, 'G', '', '', '', '', 'mv_par04')
	PutSx1(cPerg, '05', 'Transportadora de' , 'Transportadora de', 'Transportadora de', 'mv_ch5', 'C', Len(CriaVar("F2_TRANSP")), 0, 0, 'G', '', 'SA4', '', '', 'mv_par05')
	putSx1(cPerg, '06', 'Transportadora até' , 'Transportadora até', 'Transportadora até', 'mv_ch6', 'C', Len(CriaVar("F2_TRANSP")), 0, 0, 'G', 'NaoVazio()', 'SA4', '', '', 'mv_par06')
	//	PutSX1 - Criação de pergunta no arquivo SX1 ( < cGrupo>, < cOrdem>, < cPergunt>, < cPergSpa>, < cPergEng>, < cVar>, < cTipo>, < nTamanho>, [ nDecimal], [ nPreSel], < cGSC>, [ cValid], [ cF3], [ cGrpSXG], [ cPyme], < cVar01>, [ cDef01], [ cDefSpa1], [ cDefEng1], [ cCnt01], [ cDef02], [ cDefSpa2], [ cDefEng2], [ cDef03], [ cDefSpa3], [ cDefEng3], [ cDef04], [ cDefSpa4], [ cDefEng4], [ cDef05], [ cDefSpa5], [ cDefEng5], [ aHelpPor], [ aHelpEng], [ aHelpSpa], [ cHelp] ) --> Nil
Return
