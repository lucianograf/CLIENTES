//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA		Chr(13)+Chr(10)


/*/{Protheus.doc} BFFINR01
//Relatório Títulos em Aberto - Clientes x Títulos 
@author Marcelo Alberto Lauschner
@since 06/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function BFFINR01()
	Local aArea   := GetArea()
	Local oReport
	Local lEmail  := .F.
	Local cPara   := ""
	Private cPerg := ""

	//Definições da pergunta
	cPerg := "BFFINR01  "

	//Se a pergunta não existir, zera a variável
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1)) //X1_GRUPO + X1_ORDEM
	If ! SX1->(DbSeek(cPerg))
		cPerg := Nil
	EndIf

	//Cria as definições do relatório
	oReport := fReportDef()

	If !Pergunte(cPerg,.T.)
		Return 
	Endif
	//Será enviado por e-Mail?
	If lEmail
		oReport:nRemoteType := NO_REMOTE
		oReport:cEmail := cPara
		oReport:nDevice := 3 //1-Arquivo,2-Impressora,3-email,4-Planilha e 5-Html
		oReport:SetPreview(.F.)
		oReport:Print(.F., "", .T.)
		//Senão, mostra a tela
	Else
		oReport:PrintDialog()
	EndIf

	RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
| Func:  fReportDef                                                             |
| Desc:  Função que monta a definição do relatório                              |
*-------------------------------------------------------------------------------*/

Static Function fReportDef()
	Local 	oReport
	Local 	oSectDad 	:= Nil
	Local	oSectCli	:= Nil
	Local	oSectEnd	:= Nil
	Local 	oBreak 		:= Nil

	//Criação do componente de impressão
	oReport := TReport():New(	"BFFINR01",;		//Nome do Relatório
	"Relatorio Títulos a Receber - Clientes x Titulo",;		//Título
	cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, será impresso uma página com os parâmetros, conforme privilégio 101
	{|oReport| fRepPrint(oReport)},;		//Bloco de código que será executado na confirmação da impressão
	)		//Descrição
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetLandscape()
	oReport:SetLineHeight(50)
	oReport:nFontBody := 08

	oSectCli := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
	"Clientes",;		//Descrição da seção
	{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectCli:SetTotalInLine(.F.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	oSectEnd := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
	"Endereço",;		//Descrição da seção
	{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectCli:SetTotalInLine(.F.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Criando a seção de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
	"Dados",;		//Descrição da seção
	{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectDad:SetTotalInLine(.F.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Colunas do relatório
	TRCell():New(oSectCli, "A1_COD"		, "QRY_AUX", "Código"		, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectCli, "A1_LOJA"	, "QRY_AUX", "Loja"			, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectCli, "A1_NOME"	, "QRY_AUX", "Nome"			, /*Picture*/, 50, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectCli, "A1_NREDUZ"	, "QRY_AUX", "N Fantasia"	, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectCli, "A1_CGC"		, "QRY_AUX", "CNPJ/CPF"		, /*Picture*/, 19, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectCli, "A1_CONTATO"	, "QRY_AUX", "Contato"		, /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectCli, "A1_EMAIL"	, "QRY_AUX", "E-Mail"		, /*Picture*/, 50, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

	TRCell():New(oSectEnd, "A1_DDD"		, "QRY_AUX", "DDD"			, /*Picture*/, 3, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectEnd, "A1_TEL"		, "QRY_AUX", "Telefone"		, /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectEnd, "A1_END"		, "QRY_AUX", "Endereco"		, /*Picture*/, 80, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectEnd, "A1_BAIRRO"	, "QRY_AUX", "Bairro"		, /*Picture*/, 30, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectEnd, "A1_MUN"		, "QRY_AUX", "Municipio"	, /*Picture*/, 30, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectEnd, "A1_EST"		, "QRY_AUX", "Estado"		, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectEnd, "A1_CEP"		, "QRY_AUX", "CEP"			, /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

	TRCell():New(oSectDad, "E1_PREFIXO"	, "QRY_AUX", "Prefixo"		, /*Picture*/, 3, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "E1_NUM"		, "QRY_AUX", "No. Titulo"	, /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "E1_PARCELA"	, "QRY_AUX", "Parcela"		, /*Picture*/, 1, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "E1_EMISSAO"	, "QRY_AUX", "DT Emissao"	, /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "E1_SALDO"	, "QRY_AUX", "Saldo"		, /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "E1_VENCREA"	, "QRY_AUX", "Vencto Real"	, /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "E1_PORTADO"	, "QRY_AUX", "Portador"		, /*Picture*/, 3, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VEND1"		, "QRY_AUX", "Vend1"		, /*Picture*/, 78, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VEND2"		, "QRY_AUX", "Vend2"		, /*Picture*/, 78, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VEND3"		, "QRY_AUX", "Vend3"		, /*Picture*/, 78, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Return oReport

/*-------------------------------------------------------------------------------*
| Func:  fRepPrint                                                              |
| Desc:  Função que imprime o relatório                                         |
*-------------------------------------------------------------------------------*/

Static Function fRepPrint(oReport)
	Local aArea    	:= GetArea()
	Local cQryAux  	:= ""
	Local oSectDad 	:= Nil
	Local oSectCli	:= Nil
	Local oSectEnd	:= Nil
	Local nAtual   	:= 0
	Local nTotal   	:= 0
	Local cCliAtu	:= ""

	//Pegando as seções do relatório
	oSectCli := oReport:Section(1)
	oSectEnd := oReport:Section(2)
	oSectDad := oReport:Section(3)

	//Montando consulta de dados
	If SA1->(FieldPos("A1_VEND2")) > 0
		cQryAux := ""
		cQryAux += "SELECT E1.E1_PREFIXO,"		+ STR_PULA
		cQryAux += "       E1.E1_NUM,"			+ STR_PULA
		cQryAux += "       E1.E1_PARCELA ,"		+ STR_PULA
		cQryAux += "       E1.E1_EMISSAO,"		+ STR_PULA
		cQryAux += "       E1.E1_SALDO,"		+ STR_PULA
		cQryAux += "       E1.E1_VENCREA,"		+ STR_PULA
		cQryAux += "       E1.E1_PORTADO,"		+ STR_PULA
		cQryAux += "       E1.E1_CLIENTE,"		+ STR_PULA
		cQryAux += "       E1.E1_LOJA,"			+ STR_PULA
		cQryAux += "       A1.A1_COD,"			+ STR_PULA
		cQryAux += "       A1.A1_LOJA,"			+ STR_PULA
		cQryAux += "       A1.A1_NOME,"			+ STR_PULA
		cQryAux += "       A1.A1_NREDUZ,"		+ STR_PULA
		cQryAux += "       A1.A1_CGC,"			+ STR_PULA
		cQryAux += "       A1.A1_CONTATO,"		+ STR_PULA
		cQryAux += "       A1.A1_EMAIL,"		+ STR_PULA
		cQryAux += "       A1.A1_DDD,"			+ STR_PULA
		cQryAux += "       A1.A1_TEL,"			+ STR_PULA
		cQryAux += "       A1.A1_END,"			+ STR_PULA
		cQryAux += "       A1.A1_BAIRRO,"		+ STR_PULA
		cQryAux += "       A1.A1_MUN,"			+ STR_PULA
		cQryAux += "       A1.A1_EST,"			+ STR_PULA
		cQryAux += "       A1.A1_CEP,"			+ STR_PULA
		cQryAux += "       A1.A1_VEND || '-' || A3.A3_NOME AS VEND1,"		+ STR_PULA
		cQryAux += "       A1.A1_VEND2 || '-' || A33.A3_NOME AS VEND2,"		+ STR_PULA
		cQryAux += "       A1.A1_VEND3 || '-' || A333.A3_NOME AS VEND3"		+ STR_PULA
		cQryAux += "  FROM " + RetSqlName("SE1") + " E1 "		+ STR_PULA
		cQryAux += " INNER JOIN "+RetSqlName("SA1")+" A1 ON A1.A1_FILIAL = '"+xFilial("SA1")+"'"		+ STR_PULA
		cQryAux += "                     AND A1.A1_COD = E1.E1_CLIENTE"		+ STR_PULA
		cQryAux += "                     AND A1.A1_LOJA = E1.E1_LOJA"		+ STR_PULA
		cQryAux += "                     AND A1.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += "  LEFT JOIN " + RetSqlName("SA3") + " A3 ON A3.A3_FILIAL = '"+xFilial("SA3")+"'"		+ STR_PULA
		cQryAux += "                     AND A3.A3_COD = A1.A1_VEND"		+ STR_PULA
		cQryAux += "                     AND A3.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += "  LEFT JOIN " + RetSqlName("SA3") + " A33 ON A33.A3_FILIAL = '"+xFilial("SA3")+"'"		+ STR_PULA
		cQryAux += "                      AND A33.A3_COD = A1.A1_VEND2"		+ STR_PULA
		cQryAux += "                      AND A33.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += "  LEFT JOIN " + RetSqlName("SA3") + "  A333 ON A333.A3_FILIAL = '"+xFilial("SA3")+"'"		+ STR_PULA
		cQryAux += "                       AND A333.A3_COD = A1.A1_VEND3"		+ STR_PULA
		cQryAux += "                       AND A333.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += " WHERE E1.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += "   AND E1.E1_FILIAL = '"+xFilial("SE1")+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VENCREA >= '"+DTOS(MV_PAR01)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VENCREA <= '"+DTOS(MV_PAR02)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_EMISSAO >= '"+DTOS(MV_PAR03)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_EMISSAO <= '"+DTOS(MV_PAR04)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_CLIENTE >= '"+MV_PAR05+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_CLIENTE <= '"+MV_PAR06+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND >= '"+MV_PAR07+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND <= '"+MV_PAR08+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND2 >= '"+MV_PAR09+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND2 <= '"+MV_PAR10+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND3 >= '"+MV_PAR11+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND3 <= '"+MV_PAR12+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_SALDO > 0"		+ STR_PULA
		cQryAux += "   AND E1.E1_TIPO NOT IN ('NCC', 'RA ')"		+ STR_PULA
		cQryAux += " ORDER BY E1_CLIENTE,E1_LOJA,E1_VENCREA,E1_PREFIXO,E1_NUM"

	Else
		cQryAux := ""
		cQryAux += "SELECT E1.E1_PREFIXO,"		+ STR_PULA
		cQryAux += "       E1.E1_NUM,"			+ STR_PULA
		cQryAux += "       E1.E1_PARCELA ,"		+ STR_PULA
		cQryAux += "       E1.E1_EMISSAO,"		+ STR_PULA
		cQryAux += "       E1.E1_SALDO,"		+ STR_PULA
		cQryAux += "       E1.E1_VENCREA,"		+ STR_PULA
		cQryAux += "       E1.E1_PORTADO,"		+ STR_PULA
		cQryAux += "       E1.E1_CLIENTE,"		+ STR_PULA
		cQryAux += "       E1.E1_LOJA,"			+ STR_PULA
		cQryAux += "       A1.A1_COD,"			+ STR_PULA
		cQryAux += "       A1.A1_LOJA,"			+ STR_PULA
		cQryAux += "       A1.A1_NOME,"			+ STR_PULA
		cQryAux += "       A1.A1_NREDUZ,"		+ STR_PULA
		cQryAux += "       A1.A1_CGC,"			+ STR_PULA
		cQryAux += "       A1.A1_CONTATO,"		+ STR_PULA
		cQryAux += "       A1.A1_EMAIL,"		+ STR_PULA
		cQryAux += "       A1.A1_DDD,"			+ STR_PULA
		cQryAux += "       A1.A1_TEL,"			+ STR_PULA
		cQryAux += "       A1.A1_END,"			+ STR_PULA
		cQryAux += "       A1.A1_BAIRRO,"		+ STR_PULA
		cQryAux += "       A1.A1_MUN,"			+ STR_PULA
		cQryAux += "       A1.A1_EST,"			+ STR_PULA
		cQryAux += "       A1.A1_CEP,"			+ STR_PULA
		cQryAux += "       A1.A1_VEND || '-' || A3.A3_NOME AS VEND1,"		+ STR_PULA
		cQryAux += "       ' ' VEND2,"		+ STR_PULA
		cQryAux += "       ' ' VEND3"		+ STR_PULA
		cQryAux += "  FROM " + RetSqlName("SE1") + " E1 "		+ STR_PULA
		cQryAux += " INNER JOIN "+RetSqlName("SA1")+" A1 ON A1.A1_FILIAL = '"+xFilial("SA1")+"'"		+ STR_PULA
		cQryAux += "                     AND A1.A1_COD = E1.E1_CLIENTE"		+ STR_PULA
		cQryAux += "                     AND A1.A1_LOJA = E1.E1_LOJA"		+ STR_PULA
		cQryAux += "                     AND A1.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += "  LEFT JOIN " + RetSqlName("SA3") + " A3 ON A3.A3_FILIAL = '"+xFilial("SA3")+"'"		+ STR_PULA
		cQryAux += "                     AND A3.A3_COD = A1.A1_VEND"		+ STR_PULA
		cQryAux += "                     AND A3.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += " WHERE E1.D_E_L_E_T_ = ' '"		+ STR_PULA
		cQryAux += "   AND E1.E1_FILIAL = '"+xFilial("SE1")+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VENCREA >= '"+DTOS(MV_PAR01)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VENCREA <= '"+DTOS(MV_PAR02)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_EMISSAO >= '"+DTOS(MV_PAR03)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_EMISSAO <= '"+DTOS(MV_PAR04)+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_CLIENTE >= '"+MV_PAR05+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_CLIENTE <= '"+MV_PAR06+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND >= '"+MV_PAR07+"'"		+ STR_PULA
		cQryAux += "   AND A1.A1_VEND <= '"+MV_PAR08+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VEND2 >= '"+MV_PAR09+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VEND2 <= '"+MV_PAR10+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VEND3 >= '"+MV_PAR11+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_VEND3 <= '"+MV_PAR12+"'"		+ STR_PULA
		cQryAux += "   AND E1.E1_SALDO > 0"		+ STR_PULA
		cQryAux += "   AND E1.E1_TIPO NOT IN ('NCC', 'RA ')"		+ STR_PULA
		cQryAux += " ORDER BY E1_CLIENTE,E1_LOJA,E1_VENCREA,E1_PREFIXO,E1_NUM"

	Endif
	cQryAux := ChangeQuery(cQryAux)

	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)
	TCSetField("QRY_AUX", "E1_EMISSAO", "D")
	TCSetField("QRY_AUX", "E1_VENCREA", "D")

	//Enquanto houver dados
	QRY_AUX->(DbGoTop())
	While ! QRY_AUX->(Eof())
		//Incrementando a régua
		nAtual++
		oReport:SetMsgPrint("Imprimindo registro "+cValToChar(nAtual)+" de "+cValToChar(nTotal)+"...")
		oReport:IncMeter()

		If cCliAtu <> QRY_AUX->E1_CLIENTE+QRY_AUX->E1_LOJA
			If !Empty(cCliAtu)
				oSectCli:Finish()
				oSectEnd:Finish()
				oSectDad:Finish()
			Endif
			oSectCli:Init()
			oSectEnd:Init()
			oSectCli:PrintLine()
			oSectEnd:PrintLine()
			oSectDad:Init()

		Endif 
		//Imprimindo a linha atual
		oSectDad:PrintLine()

		cCliAtu	:=  QRY_AUX->E1_CLIENTE+QRY_AUX->E1_LOJA
		QRY_AUX->(DbSkip())
	EndDo

	oSectDad:Finish()
	oSectEnd:Finish()
	oSectCli:Finish()

	QRY_AUX->(DbCloseArea())

	RestArea(aArea)
Return