//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"

//Constantes
#Define STR_PULA		Chr(13)+Chr(10)


/*/{Protheus.doc} BFFATR18
// Relatório de Controle de Autorizações de Devoluções 
@author Marcelo Alberto Lauschner 
@since 02/03/2019
@version 1.0
@return Nil
@type Static Function
/*/
User Function BFFATR18()
	
	Local aArea   := GetArea()
	Local oReport
	Local lEmail  := .F.
	Local cPara   := ""
	Private cPerg := ""

	//Definições da pergunta
	cPerg := "BFFATR18  "
	
	sfValPerg(cPerg)
	
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

	//Criação do componente de impressão
	oReport := TReport():New(	"BFFATR18",;//Nome do Relatório
	"Relatorio Controle Devolucoes",;		//Título
	cPerg,;									//Pergunte ... Se eu defino a pergunta aqui, será impresso uma página com os parâmetros, conforme privilégio 101
	{|oReport| fRepPrint(oReport)},;		//Bloco de código que será executado na confirmação da impressão
	)										//Descrição
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) 			//Folha A4
	oReport:SetLandscape()
	oReport:SetLineHeight(40)
	oReport:nFontBody := 6

	//Criando a seção de dados
	oSectDad := TRSection():New(	oReport,;	//Objeto TReport que a seção pertence
	"Dados",;									//Descrição da seção
	{"QRY_AUX"})								//Tabelas utilizadas, a primeira será considerada como principal da seção
	oSectDad:SetTotalInLine(.F.)  				//Define se os totalizadores serão impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Colunas do relatório
	TRCell():New(oSectDad, "DAT_EMI", "QRY_AUX", "Dt.Aut."		,"99/99/9999" /*Picture*/, 10, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "HOR_EMI", "QRY_AUX", "Hora"			, /*Picture*/, 5, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NF_ORIG", "QRY_AUX", "Nf Origem"	, /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "DT_ORIG", "QRY_AUX", "Dt.NF Dev"	, "99/99/9999"/*Picture*/, 10, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NF_DEVO", "QRY_AUX", "Nf Devol."	, /*Picture*/, 9, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "COD_CLI", "QRY_AUX", "C.Cliente"	, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "LOJ_CLI", "QRY_AUX", "Loj.Cli." 	, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NOM_CLI", "QRY_AUX", "Nome Cliente"	, /*Picture*/, 70, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "EST_CLI", "QRY_AUX", "UF Cliente"	, /*Picture*/, 2, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "COD_VEN", "QRY_AUX", "Cód.Vend."	, /*Picture*/, 6, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "NOM_VEN", "QRY_AUX", "Nome Vendedor", /*Picture*/, 25, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "RES_DEV", "QRY_AUX", "Responsável"	, /*Picture*/, 30, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "MOT_DEV", "QRY_AUX", "Motivo"		, /*Picture*/, 300, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "DES_DEV", "QRY_AUX", "Desc.Motivo"	, /*Picture*/, 100, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "TIP_DEV", "QRY_AUX", "Tipo Devolução",/*Picture*/, 30, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VLR_DEV", "QRY_AUX", "Valor Devolução", "@E 999,999,999.99"/*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "VLR_CUS", "QRY_AUX", "Custo Devolução", "@E 999,999,999.99"/*Picture*/, 15, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

	//Totalizadores
	oFunTot1 := TRFunction():New(oSectDad:Cell("VLR_DEV"),,"SUM",,,/*cPicture*/)
	oFunTot1:SetEndReport(.F.)
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
	cQryAux += "SELECT Z3_INCDATA DAT_EMI,"		
	cQryAux += "       Z3_INCHORA HOR_EMI,"		
	cQryAux += "       Z3_NFORIG  NF_ORIG,"		
	cQryAux += "       F2_EMISSAO DT_ORIG,"		 
	cQryAux += "       Z3_NFDEV   NF_DEVO,"		 
	cQryAux += "       Z3_CLIENTE COD_CLI,"		 
	cQryAux += "       Z3_LOJA    LOJ_CLI,"		 
	cQryAux += "       A1_NOME    NOM_CLI,"		 
	cQryAux += "       A1_EST     EST_CLI,"		 
	cQryAux += "       F2_VEND1   COD_VEN,"		 
	cQryAux += "       A3_NREDUZ  NOM_VEN,"		 
	cQryAux += "       Z3_RESPDEV RES_DEV,"		 
	cQryAux += "       Z3_MOTIVO  MOT_DEV,"		 
	cQryAux += "       Z3_CONTIPO DES_DEV,"		 
	cQryAux += "       CASE "		 
	cQryAux += "         WHEN Z3_TIPODEV = '1' THEN '1-DEVOLUÇÃO TOTAL NF ENTREGA'"		 
	cQryAux += "         WHEN Z3_TIPODEV = '2' THEN '2-DEVOLUÇÃO PARCIAL NF CLIENTE'"		 
	cQryAux += "         WHEN Z3_TIPODEV = '3' THEN '3-DEVOLUÇÃO TOTAL C/NF CLIENTE'"		 
	cQryAux += "         WHEN Z3_TIPODEV = '4' THEN '4-DEVOLUÇÃO NF AVULSA'"		 
	cQryAux += "       END TIP_DEV,"		 
	cQryAux += "       Z3_VALOR   VLR_DEV, "	 
	cQryAux += "       Z3_CUSTFIN VLR_CUS "		 	
	cQryAux += "  FROM " + RetSqlName("SZ3") + "  Z3"		 
	cQryAux += "  LEFT JOIN SA1020 A1"		 
	cQryAux += "    ON A1.D_E_L_E_T_ =' ' "		 
	cQryAux += "   AND A1_LOJA = Z3_LOJA"		 
	cQryAux += "   AND A1_COD = Z3_CLIENTE"		 
	cQryAux += "   AND A1_FILIAL = '" + xFilial("SA1") + "'"		 
	cQryAux += "  LEFT JOIN " + RetSqlName("SF2") + " F2"		 
	cQryAux += "    ON F2.D_E_L_E_T_ =' ' "		 
	cQryAux += "   AND F2_CLIENTE = Z3_CLIENTE"		 
	cQryAux += "   AND F2_LOJA = Z3_LOJA "		 
	cQryAux += "   AND F2_DOC = Z3_NFORIG"		 
	cQryAux += "   AND F2_FILIAL = '" + xFilial("SF2") + "'"		 
	cQryAux += "  LEFT JOIN " + RetSqlName("SA3") + " A3"		 
	cQryAux += "    ON A3.D_E_L_E_T_ = ' ' "		 
	cQryAux += "   AND A3_COD = F2_VEND1"		 
	cQryAux += "   AND A3_FILIAL = '" + xFilial("SA3") + "' "		 
	cQryAux += " WHERE Z3.D_E_L_E_T_ = ' ' "		 
	cQryAux += "   AND Z3_FILIAL = '" + xFilial("SZ3") + "'"		 
	cQryAux += "   AND Z3_INCDATA BETWEEN '" + DTOS(MV_PAR01)+ "' AND '" + DTOS(MV_PAR02) + "'"		 
	
	cQryAux := ChangeQuery(cQryAux)

	//Executando consulta e setando o total da régua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)
	TcSetField("QRY_AUX","DAT_EMI","D")
	TcSetField("QRY_AUX","DT_ORIG","D")
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


Static Function sfValPerg(cPerg)

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
	// Grava Perguntas				
    //U_XPUTSX1(aSx1Cab,aSX1Resp,.F./*lForceAtuSx1*/)
    
	
Return
