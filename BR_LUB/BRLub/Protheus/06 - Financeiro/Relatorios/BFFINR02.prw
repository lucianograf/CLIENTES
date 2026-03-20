//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA		Chr(13)+Chr(10)

/*/{Protheus.doc} BFFINR02
Relatório - Relatorio Hospedagens         
@author zReport
@since 22/11/2019
@version 1.0
@example
u_BFFINR02()
@obs Função gerada pelo zReport()
/*/

User Function BFFINR02()

	Local 	aArea   := GetArea()
	Local 	oReport
	Local 	lEmail  := .F.
	Local 	cPara   := ""
	Private cPerg 	:= ""

	//Definições da pergunta
	cPerg := "BFFINR02  "

	//Se a pergunta não existir, zera a variável
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1)) //X1_GRUPO + X1_ORDEM
	If ! SX1->(DbSeek(cPerg))
		cPerg := Nil
	EndIf

	//Cria as definições do relatório
	oReport := fReportDef()

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
	Local oReport
	Local oSectDad := Nil
	Local oBreak := Nil

	//Criação do componente de impressão
	oReport := TReport():New(	"BFFINR02",;		//Nome do Relatório
	"Relatorio Hospedagens",;		//Título
	cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, será impresso uma página com os parâmetros, conforme privilégio 101
	{|oReport| fRepPrint(oReport)},;		//Bloco de código que será executado na confirmação da impressão
	)		//Descrição
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetLandscape()

	//Criando a seção de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
	"Dados",;		//Descrição da seção
	{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectDad:SetTotalInLine(.F.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Colunas do relatório
	TRCell():New(oSectDad, "COLABORADOR"	, "QRY_AUX", "Colaborador"	, /*Picture*/, 14, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "HOTEL"			, "QRY_AUX", "Hotel"		, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NF"				, "QRY_AUX", "Num.Nota"		, /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VALOR_NF"		, "QRY_AUX", "Valor Nota"	, "@E 999,999,999.99"/*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "EMISSAO_NF"		, "QRY_AUX", "Data Emissão"	, /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "QTD_JANTA"		, "QRY_AUX", "Qtd Janta"	, /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CENTRO_CUSTO"	, "QRY_AUX", "Centro Custo"	, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NOME_CCUSTO"	, "QRY_AUX", "Nome Custo"	, /*Picture*/, 40, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "FORNECEDOR"		, "QRY_AUX", "Fornecedor"	, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "LOJA"			, "QRY_AUX", "Loja"			, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "RAZAO"			, "QRY_AUX", "Razão"		, /*Picture*/, 60, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Return oReport

/*-------------------------------------------------------------------------------*
| Func:  fRepPrint                                                              |
| Desc:  Função que imprime o relatório                                         |
*-------------------------------------------------------------------------------*/

Static Function fRepPrint(oReport)
	Local aArea    := GetArea()
	Local cQryAux  := ""
	Local oSectDad := Nil
	Local nAtual   := 0
	Local nTotal   := 0

	//Pegando as seções do relatório
	oSectDad := oReport:Section(1)

	//Montando consulta de dados
	cQryAux := ""
	cQryAux += "SELECT D1_PART COLABORADOR,D1_HOTEL HOTEL,D1_DOC NF,D1_TOTAL VALOR_NF,TO_DATE(D1_EMISSAO,'YYYYMMDD') EMISSAO_NF,D1_REFEIC QTD_JANTA,"		+ STR_PULA
	cQryAux += "       D1_CC CENTRO_CUSTO, NVL(CTT_DESC01,' ') NOME_CCUSTO,D1_FORNECE FORNECEDOR,D1_LOJA LOJA,A2_NOME RAZAO "		+ STR_PULA
	cQryAux += "  FROM " + RetSqlName("SD1") + " D1"		+ STR_PULA
	cQryAux += "  LEFT JOIN " + RetSqlName("CTT") + " CTT "		+ STR_PULA
	cQryAux += "    ON CTT.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "   AND CTT_CUSTO = D1_CC"		+ STR_PULA
	cQryAux += "   AND CTT_FILIAL = '"+xFilial("CTT")+"' "		+ STR_PULA
	cQryAux += "  JOIN " + RetSqlName("SA2") + " A2"		+ STR_PULA
	cQryAux += "    ON A2.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "   AND A2_LOJA = D1_LOJA"		+ STR_PULA
	cQryAux += "   AND A2_COD = D1_FORNECE"		+ STR_PULA
	cQryAux += "   AND A2_FILIAL = '"+xFilial("SA2")+"'"		+ STR_PULA
	cQryAux += " WHERE D1.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "   AND D1_EMISSAO  BETWEEN '"+ DTOS(MV_PAR01) +"' AND '" + DTOS(MV_PAR02)+ "'"		+ STR_PULA
	cQryAux += "   AND D1_DTDIGIT BETWEEN '"+ DTOS(MV_PAR03) +"' AND '" + DTOS(MV_PAR04)+ "'"		+ STR_PULA
	cQryAux += "   AND D1_HOTEL <>  ' ' "		+ STR_PULA
	cQryAux += "   AND D1_FILIAL = '"+xFilial("SD1")+"' "		+ STR_PULA
	

	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)

	//Enquanto houver dados
	oSectDad:Init()
	QRY_AUX->(DbGoTop())
	While ! QRY_AUX->(Eof())
		//Incrementando a régua
		nAtual++
		oReport:SetMsgPrint("Imprimindo registro "+cValToChar(nAtual)+" de "+cValToChar(nTotal)+"...")
		oReport:IncMeter()

		//Imprimindo a linha atual
		oSectDad:PrintLine()

		QRY_AUX->(DbSkip())
	EndDo
	oSectDad:Finish()
	QRY_AUX->(DbCloseArea())

	RestArea(aArea)
Return
