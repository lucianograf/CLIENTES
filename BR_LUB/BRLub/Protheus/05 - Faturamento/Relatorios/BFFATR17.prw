//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
	
//Constantes
#Define STR_PULA		Chr(13)+Chr(10)
	
/*/{Protheus.doc} BFFATR17
Relatório - Pedidos de Venda Abaixo Minimo
@author Marcelo Alberto Lauschner
@since 05/05/2018
@version 1.0
	@example
	u_BFFATR17()
	@obs Função gerada pelo zReport()
/*/
	
User Function BFFATR17()
	Local aArea   := GetArea()
	Local oReport
	Local lEmail  := .F.
	Local cPara   := ""
	Private cPerg := ""
	
	//Definições da pergunta
	cPerg := "BFFATR17  "
	
	//Se a pergunta não existir, zera a variável
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1)) //X1_GRUPO + X1_ORDEM
	If ! SX1->(DbSeek(cPerg))
		cPerg := Nil
	EndIf
	Pergunte(cPerg,.T.)
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
	Local oSectDad 	:= Nil
	Local oBreak 	:= Nil
	Local oFunTot1 	:= Nil
	Local oFunTot2	:= Nil
	
	//Criação do componente de impressão
	oReport := TReport():New(	"BFFATR17",;		//Nome do Relatório
								"Pedidos de Venda Abaixo Minimo",;		//Título
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
	TRCell():New(oSectDad, "C5_FILIAL"		, "QRY_AUX", "Filial"		, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "C5_NUM"			, "QRY_AUX", "Numero"		, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "C5_EMISSAO"		, "QRY_AUX", "DT Emissao"	, /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "C5_CLIENTE"		, "QRY_AUX", "Cliente"		, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "C5_LOJACLI"		, "QRY_AUX", "Loja"			, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A1_NOME"		, "QRY_AUX", "Nome"			, /*Picture*/, 70,/*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A1_MUN"			, "QRY_AUX", "Municipio"	, /*Picture*/, 30,/*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A1_EST"			, "QRY_AUX", "Estado"		, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "C5_TRANSP"		, "QRY_AUX", "Transp."		, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "TRANSPORTADORA"	, "QRY_AUX", "Transportadora", /*Picture*/,32,/*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A4_VLRMIN"		, "QRY_AUX", "Valor Minimo"	, /*Picture*/, 15,/*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "C6_VALOR"		, "QRY_AUX", "Vlr.Total"	, /*Picture*/, 15,/*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "C5_FRETE"		, "QRY_AUX", "Frete"		, /*Picture*/, 15,/*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	
	//Definindo a quebra
	oBreak := TRBreak():New(oSectDad,{|| QRY_AUX->(C5_FILIAL+C5_TRANSP) },{|| "SEPARACAO DO RELATORIO" })
	oSectDad:SetHeaderBreak(.T.)
	
	//Totalizadores
	oFunTot1 := TRFunction():New(oSectDad:Cell("C6_VALOR"),,"SUM",oBreak,,/*cPicture*/)
	oFunTot1:SetEndReport(.F.)
	
	oFunTot2 := TRFunction():New(oSectDad:Cell("C5_FRETE"),,"SUM",oBreak,,/*cPicture*/)
	oFunTot2:SetEndReport(.F.)
	
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
	cQryAux += "SELECT C5_FILIAL,"		+ STR_PULA
	cQryAux += "       C5_NUM,"		+ STR_PULA
	cQryAux += "       C5_EMISSAO,"		+ STR_PULA
	cQryAux += "       C5_CLIENTE,"		+ STR_PULA
	cQryAux += "       C5_LOJACLI,"		+ STR_PULA
	cQryAux += "       A1_NOME,"		+ STR_PULA
	cQryAux += "       A1_MUN,"		+ STR_PULA
	cQryAux += "       A1_EST,"		+ STR_PULA
	cQryAux += "       C5_TRANSP,"		+ STR_PULA
	cQryAux += "       NVL(A4_NREDUZ, ' ') TRANSPORTADORA,"		+ STR_PULA
	cQryAux += "       A4.A4_VLRMIN,"		+ STR_PULA
	cQryAux += "       SUM(C6_VALOR) C6_VALOR,"		+ STR_PULA
	cQryAux += "       C5_FRETE"		+ STR_PULA
	cQryAux += "  FROM SC5020 C5, SC6020 C6, SA4020 A4,SA1020 A1"		+ STR_PULA
	cQryAux += " WHERE C5_EMISSAO BETWEEN '"+ DTOS(MV_PAR01)+"' AND '" + DTOS(MV_PAR02)+ "'  "+  STR_PULA
	cQryAux += "   AND C5_FILIAL BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "		+ STR_PULA
	cQryAux += "   AND C5_NUM = C6_NUM"		+ STR_PULA
	cQryAux += "   AND C5.D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "   AND C6.D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "   AND C6_FILIAL = C5_FILIAL"		+ STR_PULA
	cQryAux += "   AND A1.D_E_L_E_T_ =' ' "		+ STR_PULA
	cQryAux += "   AND A1_COD = C5_CLIENTE"		+ STR_PULA
	cQryAux += "   AND A1_LOJA = C5_LOJACLI"		+ STR_PULA
	cQryAux += "   AND A1_FILIAL  = '  '"		+ STR_PULA
	cQryAux += "   AND A4.D_E_L_E_T_(+) = ' '"		+ STR_PULA
	cQryAux += "   AND A4_COD(+) = C5_TRANSP"		+ STR_PULA
	cQryAux += "   AND A4_FILIAL(+) = '  '"		+ STR_PULA
	cQryAux += "   AND C5_TIPO = 'N'"		+ STR_PULA
	cQryAux += "   AND C6_CF NOT IN ('6949', '5908', '5910', '5920')"		+ STR_PULA
	cQryAux += " GROUP BY C5_FILIAL, C5_NUM, C5_TRANSP, A4_NREDUZ, A4_VLRMIN, C5_CLIENTE,C5_LOJACLI,C5_FRETE,C5_EMISSAO,A1_NOME,A1_MUN,A1_EST"		+ STR_PULA
	cQryAux += "HAVING SUM(C6_VALOR) < NVL(A4_VLRMIN, 0)"		+ STR_PULA
	cQryAux += " ORDER BY C5_TRANSP, C5_FILIAL, C5_NUM"		+ STR_PULA
	cQryAux := ChangeQuery(cQryAux)
	
	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)
	TCSetField("QRY_AUX", "C5_EMISSAO", "D")
	
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
