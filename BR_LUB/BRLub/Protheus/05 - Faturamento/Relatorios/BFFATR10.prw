#Include 'Protheus.ch'
#Include 'TopConn.ch'


/*/{Protheus.doc} BFFATR09
(Relatório Cadastros Gerais Bf e Atria)
@author Iago Luiz Raimondi
@since 26/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR10()
	Local oReport
	Local cPerg	:= "BFFATR10"
	
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
@since 26/10/2015
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
		 
	oReport := TReport():New(cNome,"Relatório Cadastros Gerais Bf e Atria",cNome,{|oReport| ReportPrint(oReport)},"Relatório Cadastros Gerais Bf e Atria")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
	oReport:SetLandScape() 
    
	oSection1 := TRSection():New(oReport, "Cab", {"QRY"},, .F., .T.)
	TRCell():New(oSection1,"EMPRESA"		,"QRY","Empresa"    ,"@!",30)
	TRCell():New(oSection1,"TIPO_CADASTRO"  ,"QRY","Tipo Cad" 	,"@!",50)
	TRCell():New(oSection1,"CODIGO"  		,"QRY","Código"   	,"@!",50)
	TRCell():New(oSection1,"LOJA"  			,"QRY","Loja"   	,"@!",50)
	TRCell():New(oSection1,"RAZAO_SOCIAL"  	,"QRY","Razao Soc" 	,"@!",50)
	TRCell():New(oSection1,"CONTATOS"  		,"QRY","Contato"   	,"@!",50)
	TRCell():New(oSection1,"CPF_CNPJ"  		,"QRY","Cpf/Cnpj"   ,"@!",50)
	TRCell():New(oSection1,"UF"  			,"QRY","UF"   		,"@!",50)
	TRCell():New(oSection1,"MUNICIPIO"  	,"QRY","Mun"	   	,"@!",50)
	TRCell():New(oSection1,"BAIRRO"  		,"QRY","Bairro"   	,"@!",50)
	TRCell():New(oSection1,"ENDERECO"  		,"QRY","End."   	,"@!",50)
	TRCell():New(oSection1,"CEP"  			,"QRY","Cep"   	 	,"@!",50)
	TRCell():New(oSection1,"FONE"  			,"QRY","Fone"   	,"@!",50)
	TRCell():New(oSection1,"ULT_COMPRA"  	,"QRY","Ult.Compra" ,"@!",50)
	TRCell():New(oSection1,"CLASSIFICACAO"  ,"QRY","Class"   	,"@!",50)
	TRCell():New(oSection1,"SEGMENTO"  		,"QRY","Segmento"   ,"@!",50)
	TRCell():New(oSection1,"GRUPO"  		,"QRY","Grupo"   	,"@!",50)
	TRCell():New(oSection1,"SUBGRUPO"  		,"QRY","Sub.Grupo"  ,"@!",50)
	TRCell():New(oSection1,"CODVEND"  		,"QRY","Cod.Vend1"  ,"@!",50)
	TRCell():New(oSection1,"VENDEDOR"  		,"QRY","Vendedor1"  ,"@!",50)
	TRCell():New(oSection1,"CODVEND2"  		,"QRY","Cod.Vend2"  ,"@!",50)
	TRCell():New(oSection1,"VENDEDOR2"  	,"QRY","Vendedor2"  ,"@!",50)
	TRCell():New(oSection1,"CODVEND3"  		,"QRY","Cod.Vend3"  ,"@!",50)
	TRCell():New(oSection1,"VENDEDOR3"  	,"QRY","Vendedor3"  ,"@!",50)
	TRCell():New(oSection1,"BLOQUEADO"  	,"QRY","Bloq"   	,"@!",50)
	TRCell():New(oSection1,"CODLJ_CLI"  	,"QRY","Cod.Lj.Cli" ,"@!",50)
	TRCell():New(oSection1,"EMAIL_CONT"  	,"QRY","Email Cont" ,"@!",50)
	
	
	oSection1:SetTotalText(" ")
	oSection1:SetPageBreak(.F.)
	
Return(oReport)


/*/{Protheus.doc} ReportPrint
(Geração da query e atribuição de valores nas colunas)
@author Iago Luiz Raimondi
@since 26/10/2015
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
	cQry += "SELECT EMPRESA,TIPO_CADASTRO,CODIGO,LOJA,RAZAO_SOCIAL,CONTATOS,CPF_CNPJ,UF,MUNICIPIO,BAIRRO,ENDERECO,CEP,"
	cQry += "       FONE,ULT_COMPRA,CLASSIFICACAO,SEGMENTO,GRUPO,SUBGRUPO,CODVEND,VENDEDOR,CODVEND2,VENDEDOR2,CODVEND3,"
	cQry += "       VENDEDOR3,BLOQUEADO,CODLJ_CLI,EMAIL_CONT"
	cQry += "  FROM BIGFORTA.BF_ATRIA_CADASTROS_GERAIS A"
	cQry += " WHERE A.CODVEND BETWEEN  '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"'"
	cQry += "   AND A.CODVEND2 BETWEEN  '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"'"
	cQry += "   AND A.CODVEND3 BETWEEN  '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"'"
	
	If MV_PAR07 == 1 
		cQry += "   AND A.TIPO_CADASTRO = 'CLIENTE'"
	ElseIf MV_PAR07 == 2
		cQry += "   AND A.TIPO_CADASTRO = 'PROSPECT'"
	EndIf
	
           
	TCQUERY cQry NEW ALIAS "QRY"
    
	While QRY->(!EOF())

		If oReport:Cancel()
			Exit
		EndIf
    	
		oSection1:Init()
		oSection1:Cell("EMPRESA"):SetValue(QRY->EMPRESA)
		oSection1:Cell("TIPO_CADASTRO"):SetValue(QRY->TIPO_CADASTRO)
		oSection1:Cell("CODIGO"):SetValue(QRY->CODIGO)
		oSection1:Cell("LOJA"):SetValue(QRY->LOJA)
		oSection1:Cell("RAZAO_SOCIAL"):SetValue(QRY->RAZAO_SOCIAL)
		oSection1:Cell("CONTATOS"):SetValue(QRY->CONTATOS)
		oSection1:Cell("CPF_CNPJ"):SetValue(QRY->CPF_CNPJ)
		oSection1:Cell("UF"):SetValue(QRY->UF)
		oSection1:Cell("MUNICIPIO"):SetValue(QRY->MUNICIPIO)
		oSection1:Cell("BAIRRO"):SetValue(QRY->BAIRRO)
		oSection1:Cell("ENDERECO"):SetValue(QRY->ENDERECO)
		oSection1:Cell("CEP"):SetValue(QRY->CEP)
		oSection1:Cell("FONE"):SetValue(QRY->FONE)
		oSection1:Cell("ULT_COMPRA"):SetValue(QRY->ULT_COMPRA)
		oSection1:Cell("CLASSIFICACAO"):SetValue(QRY->CLASSIFICACAO)
		oSection1:Cell("SEGMENTO"):SetValue(QRY->SEGMENTO)
		oSection1:Cell("GRUPO"):SetValue(QRY->GRUPO)
		oSection1:Cell("SUBGRUPO"):SetValue(QRY->SUBGRUPO)
		oSection1:Cell("CODVEND"):SetValue(QRY->CODVEND)
		oSection1:Cell("VENDEDOR"):SetValue(QRY->VENDEDOR)
		oSection1:Cell("CODVEND2"):SetValue(QRY->CODVEND2)
		oSection1:Cell("VENDEDOR2"):SetValue(QRY->VENDEDOR2)
		oSection1:Cell("CODVEND3"):SetValue(QRY->CODVEND3)
		oSection1:Cell("VENDEDOR3"):SetValue(QRY->VENDEDOR3)
		oSection1:Cell("BLOQUEADO"):SetValue(QRY->BLOQUEADO)
		oSection1:Cell("CODLJ_CLI"):SetValue(QRY->CODLJ_CLI)
		oSection1:Cell("EMAIL_CONT"):SetValue(QRY->EMAIL_CONT)
		
		oSection1:Printline()
		QRY->(dbSkip())			
	Enddo
	
	QRY->(DbCloseArea())
	
	oSection1:Finish()
	oReport:EndPage()
Return


/*/{Protheus.doc} sfCriaSx1
(Cria pergunta)
@author Iago Luiz Raimondi
@since 26/10/2015
@version 1.0
@param cPerg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaSx1(cPerg)

	PutSx1(cPerg, '01', 'Vendedor1 de' , 'Vendedor1 de' , 'Vendedor1 de' , 'mv_ch1', 'C', 6, 0, 0, 'G', '', 'SA3', '', '', 'mv_par01')
	PutSx1(cPerg, '02', 'Vendedor1 até', 'Vendedor1 até', 'Vendedor1 até', 'mv_ch2', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA3', '', '', 'mv_par02')
	PutSx1(cPerg, '03', 'Vendedor2 de' , 'Vendedor2 de' , 'Vendedor2 de' , 'mv_ch3', 'C', 6, 0, 0, 'G', '', 'SA3', '', '', 'mv_par03')
	PutSx1(cPerg, '04', 'Vendedor2 até', 'Vendedor2 até', 'Vendedor2 até', 'mv_ch4', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA3', '', '', 'mv_par04')
	PutSx1(cPerg, '05', 'Vendedor3 de' , 'Vendedor3 de' , 'Vendedor3 de' , 'mv_ch5', 'C', 6, 0, 0, 'G', '', 'SA3', '', '', 'mv_par05')
	PutSx1(cPerg, '06', 'Vendedor3 até', 'Vendedor3 até', 'Vendedor3 até', 'mv_ch6', 'C', 6, 0, 0, 'G', 'NaoVazio()', 'SA3', '', '', 'mv_par06')
	PutSx1(cPerg, '07', 'Tipo','Tipo','Tipo','mv_ch7','N',1,0,0,'C','','','','','mv_par7','Cliente','Cliente','Cliente','','Prospect','Prospect','Prospect','Todos','Todos','Todos')
	
	
Return
