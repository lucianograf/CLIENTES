//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
	
//Constantes
#Define STR_PULA		Chr(13)+Chr(10)
	
/*/{Protheus.doc} BRFATR01
Relatório - Faturamento Cliente x Produto 
@author zReport
@since 03/03/2023
@version 1.0
	@example
	u_BRFATR01()
	@obs Função gerada pelo zReport()
/*/
	
User Function BRFATR01()
	Local aArea   := GetArea()
	Local oReport
	Local lEmail  := .F.
	Local cPara   := ""
	Private cPerg := ""
	
	//Definições da pergunta
	cPerg := "BRFATR01"
	
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
	oReport := TReport():New(	"BRFATR01",;		//Nome do Relatório
								"Faturamento Cliente x Produto",;		//Título
								cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, será impresso uma página com os parâmetros, conforme privilégio 101
								{|oReport| fRepPrint(oReport)},;		//Bloco de código que será executado na confirmação da impressão
								)		//Descrição
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetLandscape()
	oReport:SetLineHeight(50)
	oReport:nFontBody := 08
	
	//Criando a seção de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
									"Dados",;		//Descrição da seção
									{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectDad:SetTotalInLine(.F.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha
	
	//Colunas do relatório
	TRCell():New(oSectDad, "D2_FILIAL"  , "QRY_AUX", "Filial",      /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "D2_CLIENTE" , "QRY_AUX", "Cliente",     /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "D2_LOJA"    , "QRY_AUX", "Loja",        /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "A1_NOME"    , "QRY_AUX", "Nome",        /*Picture*/, 60, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "D2_COD"     , "QRY_AUX", "Produto",     /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "B1_DESC"    , "QRY_AUX", "Descricao",   /*Picture*/, 55, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "D2_PRCVEN"  , "QRY_AUX", "Vlr.Unitario",/*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "D2_QUANT"   , "QRY_AUX", "Quantidade",  /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "D2_DOC"     , "QRY_AUX", "Num. Docto.", /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "D2_EMISSAO" , "QRY_AUX", "Emissao",     /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
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
	cQryAux += "SELECT  D2_FILIAL,D2_CLIENTE,D2_LOJA,A1_NOME, D2_COD,B1_DESC,D2_PRCVEN,D2_QUANT,D2_DOC,D2_EMISSAO"		
	cQryAux += "  FROM "+RetSqlName("SD2") + " D2,"+RetSqlName("SA1") + " A1,"+ RetSqlName("SF4") + " F4," + RetSqlName("SB1") + " B1 "		
	cQryAux += " WHERE D2.D_E_L_E_T_ =' '"		
	cQryAux += "   AND B1.D_E_L_E_T_ =' '"		
	cQryAux += "   AND B1_COD = D2_COD"		
	cQryAux += "   AND B1_FILIAL = D2_FILIAL "		
	cQryAux += "   AND F4.D_E_L_E_T_ =' '"		
	cQryAux += "   AND F4_ESTOQUE = 'S'"		
	cQryAux += "   AND F4_DUPLIC = 'S'"		
	cQryAux += "   AND F4_CODIGO = D2_TES"		
	cQryAux += "   AND F4_FILIAL = D2_FILIAL "		
	cQryAux += "   AND A1.D_E_L_E_T_ =' ' "		
	cQryAux += "   AND A1_LOJA = D2_LOJA"		
	cQryAux += "   AND A1_COD = D2_CLIENTE "		
	cQryAux += "   AND A1_FILIAL = '  '"		
	cQryAux += "   AND D2_COD BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR08 + "' "
	cQryAux += "   AND D2_CLIENTE BETWEEN '" + MV_PAR05+"' AND '" + MV_PAR06 + "' "
	cQryAux += "   AND D2_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
	cQryAux += "   AND D2_EMISSAO BETWEEN '" + DTOS(MV_PAR03) + "' AND '"  + DTOS(MV_PAR04) + "' "
	cQryAux += " ORDER BY D2_CLIENTE,D2_LOJA,D2_COD"		
	cQryAux := ChangeQuery(cQryAux)
	
	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)
	TCSetField("QRY_AUX", "D2_EMISSAO", "D")
	
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
