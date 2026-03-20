//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA		Chr(13)+Chr(10)

/*/{Protheus.doc} ONFATR01
Relatório de produtos sem preço de venda - Específico Onix 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/11/2021
@return variant, return_description
/*/
User Function ONFATR01()

	Local aArea   := GetArea()
	Local oReport
	Local lEmail  := .F.
	Local cPara   := ""
	Private cPerg := ""

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
	oReport := TReport():New(	"ONFATR01",;		//Nome do Relatório
								"Relatorio produtos sem preco",;		//Título
								cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, será impresso uma página com os parâmetros, conforme privilégio 101
								{|oReport| fRepPrint(oReport)},;		//Bloco de código que será executado na confirmação da impressão
								)		//Descrição
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetLandscape()
	oReport:SetLineHeight(60)
	oReport:nFontBody := 12
	
	//Criando a seção de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
									"Dados",;		//Descrição da seção
									{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectDad:SetTotalInLine(.F.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha
	
	//Colunas do relatório
	TRCell():New(oSectDad, "B1_FILIAL"  , "QRY_AUX", "Filial", /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "B1_COD"     , "QRY_AUX", "Codigo", /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "B1_DESC"    , "QRY_AUX", "Descricao", /*Picture*/, 55, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "B1_CABO"    , "QRY_AUX", "Seg.Venda", /*Picture*/, 3, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "B1_GRUPO"   , "QRY_AUX", "Grupo", /*Picture*/, 4, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

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
	cQryAux += "SELECT B1_FILIAL ,"		+ STR_PULA
	cQryAux += "       B1_COD ,"		+ STR_PULA
	cQryAux += "       B1_DESC ,"		+ STR_PULA
	cQryAux += "       B1_CABO ,"		+ STR_PULA
	cQryAux += "       B1_GRUPO  "		+ STR_PULA
	cQryAux += "  FROM ("		+ STR_PULA
	cQryAux += "SELECT B1_FILIAL,B1_COD,B1_DESC,B1_TIPO,B1_CABO,B1_GRUPO,"		+ STR_PULA
	cQryAux += "       NVL((SELECT COUNT(*) "		+ STR_PULA
	cQryAux += "              FROM " + RetSqlName("DA1") +"  D1 "		+ STR_PULA
	cQryAux += "             WHERE D1.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "               AND DA1_CODPRO = B1_COD"		+ STR_PULA
	cQryAux += "               AND DA1_CODTAB = 'T28'"		+ STR_PULA
	cQryAux += "               AND DA1_FILIAL = B1_FILIAL),-1) EXIST_TAB_T28,"		+ STR_PULA
	cQryAux += "       NVL((SELECT MAX(DA1_PRCVEN)"		+ STR_PULA
	cQryAux += "              FROM " + RetSqlName("DA1") +" D1 "		+ STR_PULA
	cQryAux += "             WHERE D1.D_E_L_E_T_ =' '"		+ STR_PULA
	cQryAux += "               AND DA1_CODPRO = B1_COD"		+ STR_PULA
	cQryAux += "               AND DA1_CODTAB = 'T28'"		+ STR_PULA
	cQryAux += "               AND DA1_FILIAL = B1_FILIAL),-1) PRC_TAB_T28"		+ STR_PULA
	cQryAux += "  FROM " + RetSqlName("SB1") +" B1 "		+ STR_PULA
	cQryAux += " WHERE B1.D_E_L_E_T_ = ' ' "		+ STR_PULA
	cQryAux += "   AND SUBSTR(B1_COD,1,2) NOT IN('AI','MC')"		+ STR_PULA
	cQryAux += "   AND SUBSTR(B1_COD,1,4) NOT IN('SERV')"		+ STR_PULA
	cQryAux += "   AND B1_COD NOT IN('PEDAGIO','TELEFONE','FRETE')"		+ STR_PULA
	cQryAux += "   AND B1_CODISS = ' ' ) "		+ STR_PULA
	cQryAux += " WHERE EXIST_TAB_T28 <> 1"		+ STR_PULA
	cQryAux := ChangeQuery(cQryAux)
	
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
