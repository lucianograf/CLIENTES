#Include "totvs.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} BFCTBR01
Relatório de Plano de Contas x Plano Referencial
@type function
@version 
@author Marcelo Alberto Lauschner
@since 30/04/2020
@return return_type, return_description
/*/
User Function BFCTBR01()

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
	oReport := TReport():New(	"BFCTBR01",;		//Nome do Relatório
		"Rel Plano Contas X Referencial",;		//Título
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
	TRCell():New(oSectDad, "CT1_CONTA"	, "QRY_AUX", "Cod Conta"	, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_DESC01"	, "QRY_AUX", "Desc Moeda 1"	, /*Picture*/, 40, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_CLASSE"	, "QRY_AUX", "Classe Conta"	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_BLOQ"	, "QRY_AUX", "Cta Bloq"		, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_CTASUP"	, "QRY_AUX", "Cta Superior"	, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_DTEXIS"	, "QRY_AUX", "Dt Ini Exist"	, /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_SPEDST"	, "QRY_AUX", "SPED Sint."	, /*Picture*/, 1, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_NATCTA"	, "QRY_AUX", "Nat. Conta"	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CVD_CODPLA"	, "QRY_AUX", "Plano Ref."	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CVD_CTAREF"	, "QRY_AUX", "Conta Ref."	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Return oReport

/*/{Protheus.doc} fRepPrint
Função que imprime o relatório 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 30/04/2020
@param oReport, object, param_description
@return return_type, return_description
/*/
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
	cQryAux += "SELECT"
	cQryAux += "    CT1_CONTA,"
	cQryAux += "    CT1_DESC01,"
	cQryAux += "    CASE WHEN CT1_CLASSE = '1' THEN '1=SINTÉTICA' WHEN CT1_CLASSE = '2' THEN '2=ANALÍTICA' ELSE '  ' END CT1_CLASSE,"
	cQryAux += "    CASE WHEN CT1_BLOQ =  '1' THEN  '1=BLOQUEADA' WHEN CT1_BLOQ =  '2' THEN  '2=NÃO BLOQUEADA' ELSE ' ' END  CT1_BLOQ,"
	cQryAux += "    CT1_CTASUP,"
	cQryAux += "    CT1_DTEXIS,"
	cQryAux += "    CT1_SPEDST,"
	cQryAux += "    CASE WHEN CT1_NATCTA =  '01' THEN '01=CONTA ATIVO' WHEN CT1_NATCTA = '02' THEN '02=CONTA PASSIVO' WHEN CT1_NATCTA = '03' THEN '03=PATRIMONIO LIQUIDO' WHEN CT1_NATCTA=  '04' THEN '04=CONTA DE RESULTADO'"
	cQryAux += "         WHEN CT1_NATCTA =  '05' THEN '05=CONTA DE COMPENSAÇÃO' WHEN CT1_NATCTA = '09' THEN  '09=OUTRAS' ELSE  ' ' END  CT1_NATCTA,"
	cQryAux += "    NVL(CVD_CODPLA, ' ') CVD_CODPLA,"
	cQryAux += "    NVL(CVD_CTAREF, ' ') CVD_CTAREF"
	cQryAux += "  FROM " + RetSqlName("CT1") + " CT1"
	cQryAux += "  LEFT JOIN " + RetSqlName("CVD") + " CVD "
	cQryAux += "    ON CVD.D_E_L_E_T_ = ' '"
	cQryAux += "                            AND CVD_CONTA = CT1_CONTA"
	cQryAux += "                            AND CVD_FILIAL = ' '"
	cQryAux += " WHERE CT1.D_E_L_E_T_ = ' '"
	cQryAux += "   AND CT1_FILIAL = '" + xFilial("CT1")+ "'"
	cQryAux += "ORDER BY 1,2 "
	cQryAux := ChangeQuery(cQryAux)

	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)
	TCSetField("QRY_AUX", "CT1_DTEXIS", "D")

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
