#Include 'Protheus.ch'
#Include 'Topconn.ch'

/*/{Protheus.doc} BFFATR11
(Relatório de clientes com proximo agendamento)
@author Iago Luiz Raimondi
@since 19/10/2016
@version 1.0
@return ${return}, ${return_description}
@example (examples)
@see ()
/*/
User Function BFFATR15()
	
	Local oReport
	Local cPerg	:= "BFFATR15"
	
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
@since 19/10/2016
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
	
	oReport := TReport():New(cNome,"Clientes",cNome,{|oReport| ReportPrint(oReport)},"Relatório de clientes com proximo agendamento.")
	oReport:SetLandScape()	
	oReport:SetTotalInLine(.F.)
	
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"CODIGO" 	,"QRY"	,"Código" 	  		,"@E 999999",08)
	TRCell():New(oSection1,"LOJA" 		,"QRY"	,"Loja"      		,"@!",04)
	TRCell():New(oSection1,"NOME" 		,"QRY"	,"Nome"				,"@!",80)
	TRCell():New(oSection1,"NREDUZ" 	,"QRY"	,"Fantasia"			,"@!",30)
	TRCell():New(oSection1,"CEP"	 	,"QRY"	,"Cep"				,"@!",10)
	TRCell():New(oSection1,"ENDERECO" 	,"QRY"	,"Endereço" 		,"@!",60)
	TRCell():New(oSection1,"MUNICIPIO" 	,"QRY"	,"Municipio" 		,"@!",30)
	TRCell():New(oSection1,"ESTADO" 	,"QRY"	,"Estado" 			,"@!",04)
	TRCell():New(oSection1,"BAIRRO" 	,"QRY"	,"Bairro" 			,"@!",30)
	TRCell():New(oSection1,"DDD" 		,"QRY"	,"DDD" 				,"@!",04)
	TRCell():New(oSection1,"TEL" 		,"QRY"	,"Telefone"			,"@!",10)
	TRCell():New(oSection1,"CNPJ"		,"QRY"	,"CNPJ" 			,"@!",30)
	TRCell():New(oSection1,"EMAIL"	 	,"QRY"	,"E-mail" 			,"@!",30)
	TRCell():New(oSection1,"VEND1" 		,"QRY"	,"Vend 1" 			,"@E 999999",08)
	TRCell():New(oSection1,"NOME1" 		,"QRY"	,"Nome 1" 			,"@!",50)	
	TRCell():New(oSection1,"VEND2" 		,"QRY"	,"Vend 2" 			,"@E 999999",08)
	TRCell():New(oSection1,"NOME2" 		,"QRY"	,"Nome 2" 			,"@!",50)
	TRCell():New(oSection1,"VEND3" 		,"QRY"	,"Vend 3" 			,"@E 999999",08)
	TRCell():New(oSection1,"NOME3" 		,"QRY"	,"Nome 3" 			,"@!",50)
	TRCell():New(oSection1,"SEGMENTO" 	,"QRY"	,"Segmento"		 	,"@!",20)
	TRCell():New(oSection1,"ULTCOMP" 	,"QRY"	,"Ult.Compra"		,"@D",20)
	TRCell():New(oSection1,"PROXAGEND" 	,"QRY"	,"Prox.Agend"	 	,"@D",20)
	TRCell():New(oSection1,"ATEND" 		,"QRY"	,"Atendim"	 		,"@!",20)		
		
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)



/*/{Protheus.doc} ReportPrint
(Impressão do relatório)
@author Iago Luiz Raimondi
@since 19/10/2016
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
	
	cQry += "SELECT A1.A1_COD AS CODIGO,"
	cQry += "       A1.A1_LOJA AS LOJA,"
	cQry += "       A1.A1_NOME AS NOME,"
	cQry += "       A1.A1_NREDUZ AS NREDUZ,"
	cQry += "       A1.A1_CEP AS CEP,"
	cQry += "       A1.A1_END AS ENDERECO,"
	cQry += "       A1.A1_MUN AS MUNICIPIO,"
	cQry += "       A1.A1_EST AS ESTADO,"
	cQry += "       A1.A1_BAIRRO AS BAIRRO,"
	cQry += "       A1.A1_DDD AS DDD,"
	cQry += "       A1.A1_TEL AS TEL,"
	cQry += "       A1.A1_CGC AS CNPJ,"
	cQry += "       A1.A1_EMAIL AS EMAIL,"
	cQry += "       A1.A1_VEND AS VEND1,"
	cQry += "       A3.A3_NOME AS NOME1,"
	cQry += "       A1.A1_VEND2 AS VEND2,"
	cQry += "       A33.A3_NOME AS NOME2,"
	cQry += "       A1.A1_VEND3 AS VEND3,"
	cQry += "       A333.A3_NOME AS NOME3,"
	cQry += "       X5.X5_DESCRI AS SEGMENTO,"
	cQry += "       A1.A1_ULTCOM AS ULTCOMP,"
	cQry += "       (SELECT MIN(U6.U6_DATA)"
	cQry += "          FROM "+ RetSqlName("SU6") +" U6"
	cQry += "         WHERE U6.D_E_L_E_T_ = ' '"
	cQry += "           AND U6.U6_FILIAL = ' '"
	cQry += "           AND U6.U6_ENTIDA = 'SA1'"
	cQry += "           AND U6.U6_CODENT = A1.A1_COD || A1.A1_LOJA"
	cQry += "           AND U6.U6_DATA >= TO_CHAR(SYSDATE, 'YYYYMMDD')) AS PROXAGEND,"
	cQry += "       DECODE(A1.A1_GERAT,"
	cQry += "              'D',"
	cQry += "              'Direto',"
	cQry += "              'I',"
	cQry += "              'Indireto',"
	cQry += "              'B',"
	cQry += "              'Bloqueado',"
	cQry += "              'T',"
	cQry += "              'Texaco',"
	cQry += "              'E',"
	cQry += "              'Excluidos',"
	cQry += "              'F',"
	cQry += "              'Filial',"
	cQry += "              'M',"
	cQry += "              'Email Mkt',"
	cQry += "              '') AS ATEND"
	cQry += "  FROM "+ RetSqlName("SA1") +" A1"
	cQry += "  LEFT JOIN "+ RetSqlName("SA3") +" A3 ON A3.A3_FILIAL = ' '"
	cQry += "                     AND A3.A3_COD = A1.A1_VEND"
	cQry += "                     AND A3.D_E_L_E_T_ = ' '"
	cQry += "  LEFT JOIN "+ RetSqlName("SA3") +" A33 ON A33.A3_FILIAL = ' '"
	cQry += "                      AND A33.A3_COD = A1.A1_VEND2"
	cQry += "                      AND A33.D_E_L_E_T_ = ' '"
	cQry += "  LEFT JOIN "+ RetSqlName("SA3") +" A333 ON A333.A3_FILIAL = ' '"
	cQry += "                       AND A333.A3_COD = A1.A1_VEND3"
	cQry += "                       AND A333.D_E_L_E_T_ = ' '"
	cQry += "  LEFT JOIN "+ RetSqlName("SX5") +" X5 ON X5.D_E_L_E_T_ = ' '"
	cQry += "                     AND X5.X5_FILIAL = '01'"
	cQry += "                     AND X5.X5_TABELA = 'T3'"
	cQry += "                     AND X5.X5_CHAVE = A1.A1_SATIV1"
	cQry += " WHERE A1.D_E_L_E_T_ = ' '"
	cQry += "   AND A1.A1_FILIAL = '"+ xFilial("SA1") +"'"
	cQry += "   AND A1.A1_COD BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry += "   AND A1.A1_VEND BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
	cQry += "   AND A1.A1_VEND2 BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"'"
	cQry += "   AND A1.A1_VEND3 BETWEEN '"+ MV_PAR07 +"' AND '"+ MV_PAR08 +"'"
	cQry += "   AND A1.A1_MUN BETWEEN '"+ MV_PAR09 +"' AND '"+ MV_PAR10 +"'"
		
	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	While QRY->(!EOF())
		
		If oReport:Cancel()
			Exit
		EndIf
		
		oSection1:Init()
		oSection1:Cell("CODIGO"):SetValue(QRY->CODIGO)
		oSection1:Cell("LOJA"):SetValue(QRY->LOJA)
		oSection1:Cell("NOME"):SetValue(QRY->NOME)
		oSection1:Cell("NREDUZ"):SetValue(QRY->NREDUZ)
		oSection1:Cell("CEP"):SetValue(QRY->CEP)
		oSection1:Cell("ENDERECO"):SetValue(QRY->ENDERECO)
		oSection1:Cell("MUNICIPIO"):SetValue(QRY->MUNICIPIO)
		oSection1:Cell("ESTADO"):SetValue(QRY->ESTADO)
		oSection1:Cell("BAIRRO"):SetValue(QRY->BAIRRO)
		oSection1:Cell("DDD"):SetValue(QRY->DDD)
		oSection1:Cell("TEL"):SetValue(QRY->TEL)
		oSection1:Cell("CNPJ"):SetValue(QRY->CNPJ)
		oSection1:Cell("EMAIL"):SetValue(QRY->EMAIL)
		oSection1:Cell("VEND1"):SetValue(QRY->VEND1)
		oSection1:Cell("NOME1"):SetValue(QRY->NOME1)
		oSection1:Cell("VEND2"):SetValue(QRY->VEND2)
		oSection1:Cell("NOME2"):SetValue(QRY->NOME2)
		oSection1:Cell("VEND3"):SetValue(QRY->VEND3)
		oSection1:Cell("NOME3"):SetValue(QRY->NOME3)
		oSection1:Cell("SEGMENTO"):SetValue(QRY->SEGMENTO)
		oSection1:Cell("ULTCOMP"):SetValue(StoD(QRY->ULTCOMP))
		oSection1:Cell("PROXAGEND"):SetValue(StoD(QRY->PROXAGEND))
		oSection1:Cell("ATEND"):SetValue(QRY->ATEND)
		
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
@since 19/10/2016
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)
	
	PutSx1(cPerg,'01','Cliente de','Cliente de','Cliente de','mv_ch1','C',Len(CriaVar("A1_COD")),0,0,'G','','SA1','','','mv_par01')
	PutSx1(cPerg,'02','Cliente até','Cliente até','Cliente até','mv_ch2','C',Len(CriaVar("A1_COD")),0,0,'G','NaoVazio()','SA1','','','mv_par02')
	PutSx1(cPerg,'03','Vendedor de','Vendedor de','Vendedor de','mv_ch3','C',Len(CriaVar("A3_COD")),0,0,'G','','SA3','','','mv_par03')
	PutSx1(cPerg,'04','Vendedor até','Vendedor até','Vendedor até','mv_ch4','C',Len(CriaVar("A3_COD")),0,0,'G','NaoVazio()','SA3','','','mv_par04')
	PutSx1(cPerg,'05','Vendedor 2 de','Vendedor 2 de','Vendedor 2 de','mv_ch5','C',Len(CriaVar("A3_COD")),0,0,'G','','SA3','','','mv_par05')
	PutSx1(cPerg,'06','Vendedor 2 até','Vendedor 2 até','Vendedor 2 até','mv_ch6','C',Len(CriaVar("A3_COD")),0,0,'G','NaoVazio()','SA3','','','mv_par06')
	PutSx1(cPerg,'07','Vendedor 3 de','Vendedor 3 de','Vendedor 3 de','mv_ch7','C',Len(CriaVar("A3_COD")),0,0,'G','', 'SA3','','','mv_par07')
	PutSx1(cPerg,'08','Vendedor 3 até','Vendedor 3 até','Vendedor 3 até','mv_ch8','C',Len(CriaVar("A3_COD")),0,0,'G','NaoVazio()','SA3','','','mv_par08')
	PutSx1(cPerg,'09','Cidade de','Cidade de','Cidade de','mv_ch9','C',Len(CriaVar("A1_MUN")),0,0,'G','','','','','mv_par09')
	PutSx1(cPerg,'10','Cidade até','Cidade até','Cidade até','mv_cha','C',Len(CriaVar("A1_MUN")),0,0,'G','NaoVazio()','','','','mv_par10')

Return
