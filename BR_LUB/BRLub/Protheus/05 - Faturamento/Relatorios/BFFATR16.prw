//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA		Chr(13)+Chr(10)

/*/{Protheus.doc} BFFATR16
Relatório - Faturamento Mensal            
@author zReport
@since 10/01/2018
@version 1.0
@example
u_BFFATR16()
@obs Função gerada pelo zReport()
/*/

User Function BFFATR16()
	Local aAreaOld   := GetArea()
	Local oReport
	Local lEmail  	:= .F.
	Local cPara   	:= ""
	Private cPerg 	:= ""

	//Definições da pergunta
	DbSelectArea("SX1")
	cPerg := "BFFATR16  "
	
	sfValPerg()
	
	//Se a pergunta não existir, zera a variável
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1)) //X1_GRUPO + X1_ORDEM
	If ! SX1->(DbSeek(cPerg))
		cPerg := Nil
	EndIf
	
	If !Pergunte(cPerg,.T.)
		RestArea(aAreaOld)
		Return 
	Endif
	
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

	RestArea(aAreaOld)
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
	oReport := TReport():New(	"BFFATR16",;		//Nome do Relatório
	"Faturamento Mensal",;		//Título
	cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, será impresso uma página com os parâmetros, conforme privilégio 101
	{|oReport| fRepPrint(oReport)},;		//Bloco de código que será executado na confirmação da impressão
	)		//Descrição
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetPortrait()

	//Criando a seção de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a seção pertence
	"Dados",;		//Descrição da seção
	{"QRY_AUX"})		//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectDad:SetTotalInLine(.F.)  //Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Colunas do relatório
	TRCell():New(oSectDad, "VENDEDOR", "QRY_AUX", "Vendedor", /*Picture*/, 70, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "DUPLICATA", "QRY_AUX", "Duplicata", /*Picture*/, 12, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NOTA", "QRY_AUX", "Nota", /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CUSTO", "QRY_AUX", "Custo", /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "FORNECEDOR", "QRY_AUX", "Fornecedor", /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "TOTAL", "QRY_AUX", "Total", /*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
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
	cQryAux += "SELECT VENDEDOR || '-' || NVL((SELECT A3_NREDUZ"		+ STR_PULA
	cQryAux += "                                FROM SA3020"		+ STR_PULA
	cQryAux += "                               WHERE D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "                                 AND A3_COD = VENDEDOR"		+ STR_PULA
	cQryAux += "                                 AND A3_FILIAL = ' '),"		+ STR_PULA
	cQryAux += "                              ' ') VENDEDOR,"		+ STR_PULA
	cQryAux += "       DUPLICATA,"		+ STR_PULA
	cQryAux += "       NOTA,"		+ STR_PULA
	cQryAux += "       SUM(CUSTO) CUSTO,"		+ STR_PULA
	cQryAux += "       FORNECEDOR,"		+ STR_PULA
	cQryAux += "       SUM(TOTAL) TOTAL"		+ STR_PULA
	cQryAux += "  FROM (SELECT F2_VEND1 VENDEDOR,"		+ STR_PULA
	cQryAux += "               F2_DOC NOTA,"		+ STR_PULA
	cQryAux += "               SUM(D2_CUSTO1) CUSTO,"		+ STR_PULA
	cQryAux += "               SUM(D2_TOTAL+D2_ICMSRET+D2_DESPESA+D2_VALFRE) TOTAL,"		+ STR_PULA
	cQryAux += "               CASE"		+ STR_PULA
	cQryAux += "                 WHEN F4_DUPLIC = 'S' THEN"		+ STR_PULA
	cQryAux += "                  'FATURADO'"		+ STR_PULA
	cQryAux += "                 ELSE"		+ STR_PULA
	cQryAux += "                  'BONIF/BRINDE'"		+ STR_PULA
	cQryAux += "               END DUPLICATA,"		+ STR_PULA
	cQryAux += "               CASE"		+ STR_PULA
	cQryAux += "                 WHEN B1_PROC = '000473' THEN"		+ STR_PULA
	cQryAux += "                  'MICHELIN'"		+ STR_PULA
	cQryAux += "                 WHEN B1_PROC = '000468' THEN"		+ STR_PULA
	cQryAux += "                  'TEXACO'"		+ STR_PULA
	cQryAux += "                 ELSE"		+ STR_PULA
	cQryAux += "                  'OUTROS'"		+ STR_PULA
	cQryAux += "               END FORNECEDOR"		+ STR_PULA
	cQryAux += "          FROM SF2020 F2, SD2020 D2, SB1020 B1, SF4020 F4"		+ STR_PULA
	cQryAux += "         WHERE F2_FILIAL IN "+ FormatIN(GetMv("BF_FILIAIS"),"/")		+ STR_PULA
	cQryAux += "           AND F2_EMISSAO BETWEEN '"+DTOS(MV_PAR01)+"' AND '"+DTOS(MV_PAR02)+"'"		+ STR_PULA
	cQryAux += "           AND F2.D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "           AND D2.D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "           AND F4.D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "           AND F4_CODIGO = D2_TES"		+ STR_PULA
	cQryAux += "           AND F4_FILIAL = F2_FILIAL"		+ STR_PULA
	cQryAux += "           AND D2_SERIE = F2_SERIE"		+ STR_PULA
	cQryAux += "           AND D2_DOC = F2_DOC"		+ STR_PULA
	cQryAux += "           AND D2_LOJA = F2_LOJA"		+ STR_PULA
	cQryAux += "           AND D2_CLIENTE = F2_CLIENTE"		+ STR_PULA
	cQryAux += "           AND D2_FILIAL = F2_FILIAL"		+ STR_PULA
	cQryAux += "           AND B1.D_E_L_E_T_ = ' '"		+ STR_PULA
	cQryAux += "           AND D2_TIPO = 'N'"		+ STR_PULA
	cQryAux += "           AND B1_COD = D2_COD"		+ STR_PULA
	cQryAux += "           AND B1_FILIAL = F2_FILIAL"		+ STR_PULA
	cQryAux += "           AND F2_VEND1 BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"'"+ STR_PULA
	cQryAux += "         GROUP BY F2_VEND1, B1_PROC, F4_DUPLIC, F2_DOC)"		+ STR_PULA
	cQryAux += " GROUP BY VENDEDOR, DUPLICATA, FORNECEDOR, NOTA"		+ STR_PULA
	cQryAux += " ORDER BY 3, 2, 1"		+ STR_PULA
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


// Exemplo de uso

Static Function sfValPerg()

	Local	aSx1Cab		:= {"X1_GRUPO",;	//1
							"X1_ORDEM",;	//2
							"X1_PERGUNT",;	//3	
							"X1_VARIAVL",;	//4
							"X1_TIPO",;		//5
							"X1_TAMANHO",;	//6
							"X1_DECIMAL",;	//7
							"X1_PRESEL",;	//8
							"X1_GSC",;		//9
							"X1_VAR01",;	//10	
							"X1_F3"}		//11
							
	Local	aSX1Resp	:= {}
	
							
	Aadd(aSX1Resp,{	cPerg,;					//1
					'01',;					//2
					'Data de?',;			//3
					'mv_ch1',;				//4
					'D',;					//5
					8,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par01',;			//10
					''})					//11
	
	Aadd(aSX1Resp,{	cPerg,;					//1
					'02',;					//2
					'Data Ate?'	,;			//3
					'mv_ch2',;				//4
					'D',;					//5
					8,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par02',;			//10
					''})					//11
					
	Aadd(aSX1Resp,{	cPerg,;					//1
					'03',;					//2
					'Vendedor De?',;		//3
					'mv_ch3',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par03',;			//10
					'SA3'})					//11
	
	Aadd(aSX1Resp,{	cPerg,;					//1
					'04',;					//2
					'Vendedor Até?',;		//3
					'mv_ch4',;				//4
					'C',;					//5
					6,;						//6
					0,;						//7
					0,;						//8
					'G',;					//9	
					'mv_par04',;			//10
					'SA3'})					//11					
	// Grava Perguntas				
    //U_XPUTSX1(aSx1Cab,aSX1Resp,.F./*lForceAtuSx1*/)
    
	
Return
