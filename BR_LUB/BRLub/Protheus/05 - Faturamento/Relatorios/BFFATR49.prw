#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFFATR49
(Relatório de Movimentação de promoções SZA - Tampas / Marketing / F&I)
@author MarceloLauschner
@since 19/11/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR49()
	
	
	Local oReport
	Local cPerg	:= "BFFATR49"
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	//sfCriaSx1(cPerg)
	Pergunte(cPerg,.F.)
	
	oReport := RptDef(cPerg)
	oReport:PrintDialog()
	
Return


/*/{Protheus.doc} RptDef
(Montagem do relatório)
@author MarceloLauschner
@since 16/11/2015
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
	
	oReport := TReport():New(cNome,"Movimentos Promoções",cNome,{|oReport| ReportPrint(oReport)},"Relatório de movimentações de Promoções")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
	
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"ZA_CLIENTE"		,"QRY","Código"    	 		,"@!",6)
	TRCell():New(oSection1,"ZA_LOJA"	  	,"QRY","Loja" 			  	,"@!",2)
	TRCell():New(oSection1,"A1_NOME"	  	,"QRY","Razão Social"   	,"@!",50)
	TRCell():New(oSection1,"A1_MUN"		  	,"QRY","Cidade" 			,"@!",50)
	TRCell():New(oSection1,"nSaldAnt"	 	,""	  ,"Saldo Anterior" 	,"@E 999,999.99",12)
	
	oSection2:= TRSection():New(oReport, "Movimentos Tampas por cliente", {"QRY"},, .F., .T.)
	
	TRCell():New(oSection2,"ZA_CLIENTE"		,"QRY","Código"    	 		,"@!",6)
	TRCell():New(oSection2,"ZA_LOJA"	  	,"QRY","Loja" 			  	,"@!",2)
	TRCell():New(oSection2,"ZA_REFEREN" 	,"QRY","Referencia"    		,"@!",12)
	TRCell():New(oSection2,"ZA_TIPOMOV" 	,"QRY","Tipo Mov."    		,"@!",10)
	TRCell():New(oSection2,"ZA_DATA" 		,"QRY","Data" 		   		,"@!",10)
	TRCell():New(oSection2,"ZA_DOC"	  		,"QRY","Documento" 		  	,"@!",9)
	TRCell():New(oSection2,"ZA_PRODUTO"	  	,"QRY","Produto" 		  	,"@!",15)
	TRCell():New(oSection2,"ZA_VALOR"     	,"QRY","Valor"				,"@E 999,999.99",12)
	TRCell():New(oSection2,"nSaldMov"     	,""   ,"Saldo Mov"			,"@E 999,999.99",12)
	TRCell():New(oSection2,"ZA_OBSERV"     	,"QRY","Observação"    		,"@!",60)
	TRCell():New(oSection2,"cUsrDig"   	    ,""   ,"Usuário"    		,"@!",15)
	
	//TRFunction():New(oSection2:Cell("QTD"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	//TRFunction():New(oSection2:Cell("LITROS"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	//TRFunction():New(oSection2:Cell("TOTAL"),/*cID*/,"SUM", /*oBreak*/, /*cTitle*/, /*cPicture*/, /*uFormula*/,.T. /*lEndSection*/, .F./*lEndReport*/, /*lEndPage*/)
	
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
	
	Local 	oSection1 	:= oReport:Section(1)
	Local 	oSection2 	:= oReport:Section(2)
	Local 	cQry		:= ""
	Local 	cCliLj		:= ""
	Local	nSaldAnt	:= 0
	Local	nSaldMov	:= 0
	
	cQry += "SELECT ZA_CLIENTE,ZA_LOJA,A1_NOME,A1_MUN,ZA_VALOR,ZA_OBSERV,ZA_PRODUTO,ZA_DOC,"
	cQry += "       SUBSTR(ZA_USERLGI,2,1) || SUBSTR(ZA_USERLGI,2,1) || SUBSTR(ZA_USERLGI,15,1) || SUBSTR(ZA_USERLGI,6,1) || SUBSTR(ZA_USERLGI,10,1) || SUBSTR(ZA_USERLGI,14,1) ZA_USERLGI,"
	cQry += "       ZA.R_E_C_N_O_ ZARECNO,"
	cQry += "       DECODE(ZA_TIPOMOV,'C','C=Crédito','D','D=Débito',ZA_TIPOMOV || '=Outros')ZA_TIPOMOV,"
	cQry += "       ZA_DATA,"
	cQry += "       DECODE(ZA_REFEREN,'T','T=Tampas','M','M=Marketing','F','F=F&I',ZA_REFEREN || '=Outros') ZA_REFEREN "
	cQry += "  FROM " + RetSqlName("SZA") +" ZA," + RetSqlName("SA1") + " A1 "
	cQry += " WHERE A1.D_E_L_E_T_ =' ' "
	cQry += "   AND A1_LOJA = ZA_LOJA "
	cQry += "   AND A1_COD = ZA_CLIENTE "
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1")+ "'"
	cQry += "   AND ZA.D_E_L_E_T_ = ' ' "
	cQry += "   AND ZA_DATA BETWEEN '"+ DTOS(MV_PAR05) +"' AND '"+ DTOS(MV_PAR06) +"'"
	If mv_par07 == 1 // 1=Tampas 2=F&I 3=Marketing 4=Todos
		cQry += "	AND ZA_REFEREN = 'T' "
	ElseIf mv_par07 == 2
		cQry += "	AND ZA_REFEREN = 'F' "
	ElseIf mv_par07 == 3
		cQry += "	AND ZA_REFEREN = 'M' "
	Endif
	If mv_par08 == 1 // 1=Credito 2=Debito 3=Ambos
		cQry += "   AND ZA_TIPOMOV = 'C' "
	ElseIf mv_par08 == 2
		cQry += "   AND ZA_TIPOMOV = 'D' "
	Endif
	cQry += "   AND ZA_CLIENTE BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
	cQry += "   AND ZA_MSFIL BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry += "   AND ZA_FILIAL = '" + xFilial("SZA")+ "' "
	cQry += " ORDER BY ZA_CLIENTE,ZA_LOJA "
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	//Quebra por cliente
	cCliLj := QRY->ZA_CLIENTE+QRY->ZA_LOJA
	
	While QRY->(!EOF())
		
		If oReport:Cancel()
			Exit
		EndIf
		
		// Consulta saldo anterior do cliente considerando mesmos filtros de referencias
		cQry := " "
		cQry += "SELECT "
		cQry += "       SUM(ZA_VALOR) AS SALDOANT "
		cQry += "  FROM " + RetSqlName("SZA") + "  SZA "
		cQry += " WHERE SZA.D_E_L_E_T_ =' '  "
		cQry += "   AND ZA_DATA < '" + DTOS(MV_PAR05) +"' " 
		
		If mv_par07 == 1 // 1=Tampas 2=F&I 3=Marketing 4=Todos
			cQry += "	AND ZA_REFEREN = 'T' "
		ElseIf mv_par07 == 2
			cQry += "	AND ZA_REFEREN = 'F' "
		ElseIf mv_par07 == 3
			cQry += "	AND ZA_REFEREN = 'M' "
		Endif
		
		cQry += "   AND ZA_LOJA = '" + QRY->ZA_LOJA +"' "
		cQry += "   AND ZA_CLIENTE = '" + QRY->ZA_CLIENTE + "' "
		cQry += "   AND ZA_FILIAL = '"+xFilial("SZA") + "' "
		cQry += "   AND ZA_MSFIL BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
		
		TCQUERY cQry NEW ALIAS "QSLD"
		
		nSaldAnt	:= QSLD->SALDOANT
		nSaldMov	:= QSLD->SALDOANT
		
		QSLD->(DbCloseArea())
		
		oSection1:Init()
		oSection1:Cell("ZA_CLIENTE"):SetValue(QRY->ZA_CLIENTE)
		oSection1:Cell("ZA_LOJA"):SetValue(QRY->ZA_LOJA)
		oSection1:Cell("A1_NOME"):SetValue(QRY->A1_NOME)
		oSection1:Cell("A1_MUN"):SetValue(QRY->A1_MUN)
		oSection1:Cell("nSaldAnt"):SetValue(nSaldAnt)
		oSection1:Printline()
		
		While QRY->(!EOF()) .AND. QRY->ZA_CLIENTE+QRY->ZA_LOJA == cCliLj
			oSection2:Init()
			
			DbSelectArea( "SZA" )
			DbGoto(QRY->ZARECNO)		
	
			nSaldMov	+= QRY->ZA_VALOR
			
			oSection2:Cell("ZA_CLIENTE"):SetValue(QRY->ZA_CLIENTE)
			oSection2:Cell("ZA_LOJA"):SetValue(QRY->ZA_LOJA)
			oSection2:Cell("ZA_DOC"):SetValue(QRY->ZA_DOC)
			oSection2:Cell("ZA_PRODUTO"):SetValue(QRY->ZA_PRODUTO)
			oSection2:Cell("ZA_REFEREN"):SetValue(QRY->ZA_REFEREN)
			oSection2:Cell("ZA_DATA"):SetValue(STOD(QRY->ZA_DATA))
			oSection2:Cell("ZA_TIPOMOV"):SetValue(QRY->ZA_TIPOMOV)
			oSection2:Cell("ZA_VALOR"):SetValue(QRY->ZA_VALOR)
			oSection2:Cell("nSaldMov"):SetValue(nSaldMov)
			oSection2:Cell("ZA_OBSERV"):SetValue(QRY->ZA_OBSERV)
			oSection2:Cell("cUsrDig"):SetValue(UsrRetName(QRY->ZA_USERLGI))			 
			oSection2:Printline()
			QRY->(dbSkip())
		Enddo
		cCliLj := QRY->ZA_CLIENTE+QRY->ZA_LOJA
		oSection2:Finish()
		oSection1:Finish()
		oReport:IncRow()
	Enddo
	
	oReport:EndPage()
	
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
Return


/*/{Protheus.doc} sfCriaSx1
(Criar perguntas da rotina)
@author MarceloLauschner
@since 16/11/2015
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)
	
	PutSx1(cPerg, '01', 'Filial de      ' , 'Filial de     ', 'Filial de    ', 'mv_ch1', 'C', 2, 0, 0, 'G', ''          , 'SM0', '', '', 'mv_par01')
	PutSx1(cPerg, '02', 'Filial até     ' , 'Filial até    ', 'Filial até   ', 'mv_ch2', 'C', 2, 0, 0, 'G', 'NaoVazio()', 'SM0', '', '', 'mv_par02')
	PutSx1(cPerg, '03', 'Cliente de     ' , 'Cliente de    ', 'Cliente de   ', 'mv_ch3', 'C', 6, 0, 0, 'G', ''          , 'SA1', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Cliente até    ' , 'Cliente até   ', 'Cliente até  ', 'mv_ch4', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA1', '', '', 'mv_par04')
	PutSx1(cPerg, '05', 'Data Inicial   ' , 'Data Inicial  ', 'Data Inicial ', 'mv_ch5', 'D', 8, 0, 0, 'G', ''          , '', '', '', 'mv_par05')
	PutSx1(cPerg, '06', 'Data Final     ' , 'Data Final    ', 'Data Final   ', 'mv_ch6', 'D', 8, 0, 0, 'G', ''          , '', '', '', 'mv_par06')
	PutSx1(cPerg, '07', 'Tipo Promoção  ' , 'Tipo Promoção ', 'Tipo Promoção', 'mv_ch7', 'N', 1, 0, 0, 'C', ''          , '', '', '', 'mv_par07' ,'Tampas' ,'Tampas' ,'Tampas ','','F&I','F&I','F&I','Marketing','Marketing','Marketing','Todos','Todos','Todos')
	PutSx1(cPerg, '08', 'Deb/Cred       ' , 'Deb/Cred      ', 'Deb/Cred     ', 'mv_ch8', 'N', 1, 0, 0, 'C', ''          , '', '', '', 'mv_par08' ,'Credito','Credito','Credito','','Debito','Debito','Debito','Ambos','Ambos','Ambos')
	
Return
