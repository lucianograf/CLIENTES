#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFFATR06 
(Relatório romaneio de carga)
@author Iago Luiz Raimondi / Marcelo Alberto Lauschner 
@since 16/03/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MLFATR06()
	Local 		oReport
	Local 		cPerg		:= "MLFATR06"
	Private		cAlsSZ		:= "SZ2" //IIf(cEmpAnt == "05","SZ2","SZ1")

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
	TRCell():New(oSection2,"F2_PBRUTO"    	,"QRY","Peso Bruto"    	,"@E 99,999.999",10)

	TRFunction():New(oSection2:Cell("F2_PBRUTO"),  /*cID*/, "SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
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
	cQry += "       F2_PBRUTO,"
	cQry += "       A4_COD,"
	cQry += "       A4_NOME,"
	cQry += "       F2_VOLUME1,"
	cQry += "       F2_DOC,"
	cQry += "       F2_VALMERC,"
	cQry += "       F2_FILIAL,"
	cQry += "       D2_PEDIDO,"
	cQry += "       Z2_NOMERES NOMERES,"
	cQry += "       Z2_EMISSAO EMISSAO,"
	cQry += "       Z2_NOMEMOT NOMEMOT,"
	cQry += "       Z2_ROMANEI ROMANEI,"
	cQry += "       ' ' CTRFIL "
	cQry += "  FROM " + RetSqlName("SF2") + " F2 "
    cQry += " INNER JOIN " + RetSqlName("SA1") + " A1 "  
    cQry += "    ON A1.D_E_L_E_T_= ' ' "
	cQry += "   AND A1_LOJA = F2_LOJA "
	cQry += "   AND A1_COD = F2_CLIENTE "
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "'"
	cQry += " INNER JOIN " + RetSqlName(cAlsSZ) + " Z2 "
	cQry += "    ON Z2.D_E_L_E_T_ =' ' "
	cQry += "   AND Z2_ROMANEI BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'
    cQry += "   AND Z2_LOJA = F2_LOJA "
    cQry += "   AND Z2_CLIENTE = F2_CLIENTE "
	cQry += "   AND Z2_NOTAFIS = F2_DOC "
	cQry += "   AND Z2_SERIE = F2_SERIE "
	cQry += "   AND Z2_FILIAL = '" + xFilial(cAlsSZ) + "'"
	cQry += "   AND Z2_EMISSAO BETWEEN '"+ DTOS(MV_PAR03) +"' AND '"+ DTOS(MV_PAR04) +"'
	cQry += "   AND Z2_FILIAL = '" + xFilial("SZ2")+ "' "
	cQry += " INNER JOIN " + RetSqlName("SD2") + " D2 "
	cQry += "    ON D2_SERIE = F2_SERIE "
	cQry += "   AND D2_DOC = F2_DOC "
	cQry += "   AND D2_LOJA = F2_LOJA "
	cQry += "   AND D2_CLIENTE = F2_CLIENTE"
	cQry += "   AND D2_FILIAL = '" + xFilial("SD2")+ "'"	
    cQry += "  LEFT JOIN " + RetSqlName("SA4") + " A4 " 
    cQry += "    ON A4.D_E_L_E_T_  = ' ' "
	cQry += "   AND A4_COD = F2_TRANSP "
	cQry += "   AND A4_FILIAL = '" + xFilial("SA4")+ "'"
	cQry += "   AND D2.D_E_L_E_T_ =' ' "
	cQry += " WHERE F2.D_E_L_E_T_ =' ' "
	cQry += "   AND F2_TRANSP BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"'
	cQry += "   AND F2_FILIAL = '" + xFilial("SF2") + "'"
	cQry += " ORDER BY 15, A1_MUN, A1_NOME, F2_DOC"

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
		oSection1:Cell("A4_NOME"):SetValue(QRY->A4_COD + "-" + QRY->A4_NOME)
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
			oSection2:Cell("F2_PBRUTO"):SetValue(QRY->F2_PBRUTO)
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


