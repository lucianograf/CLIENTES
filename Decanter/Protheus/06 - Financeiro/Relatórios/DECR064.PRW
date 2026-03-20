#INCLUDE "PROTHEUS.CH"
/*/{Protheus.doc} User Function DECR064
 
 Relação de bordero sintético contas a receber por dia 

@type  Function
@author CHARLES REITZ
@since 28/01/2020
/*/
User Function DECR064()
    Local oReport

    oReport:=ReportDef()
    oReport:PrintDialog()
Return

Static Function ReportDef()

    Local oReport
    Local cReport 	:= "DECR064" 				// Nome do relatorio
    Local cDescri 	:= "Relatório com relação de borderô a receber diário"
    Local cTitulo 	:= "Relação de bordero a receber diário" 					//"Emiss„o de Borderos de Pagamentos"
    Local cPerg		:= ""					// Nome do grupo de perguntas
    Local aRet		:= {}
    Local aPergPar	:=	{}
    Local lCanSave	:=	.T.
    Local lUserSave	:=	.T.


    aAdd(aPergPar ,{1,"Data De",date()-1,"",'.T.',"",'.T.',80,.T.})
    aAdd(aPergPar ,{1,"Data Ate",date(),"",'.T.',"",'.T.',80,.T.})
    If !ParamBox(aPergPar, "Modelo", @aRet, /*bOk*/, /*aButtons*/, /*lCentered*/, /*nPosx*/,/*nPosy*/,/*oPanel*/ ,procName()+"01" /*cLoad*/, lCanSave, lUserSave)
        Return
    endif

    oReport := TReport():New(cReport, cTitulo, cPerg, {|oReport| ReportPrint(oReport)}, cDescri)
	oReport:SetTotalInLine(.F.)
    oReport:cFontBody := "Arial"
    oReport:oPage:nPaperSize := 7
    oReport:lEdit	:=	.F.

    oSection1 := TRSection():New(oReport, "Borderos")
    oSection1:SetTotalInLine(.F.)
    TRCell():New(oSection1,"EA_DATABOR"		,"SEA",,,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    TRCell():New(oSection1,"EA_NUMBOR"		,"SEA",,,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    TRCell():New(oSection1,"EA_PORTADO"		,"SEA",,,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    TRCell():New(oSection1,"EA_AGEDEP"		,"SEA",,,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    TRCell():New(oSection1,"EA_NUMCON"		,"SEA",,,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    TRCell():New(oSection1,"EA_TRANSF"		,"SEA",,,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    TRCell():New(oSection1,"TITULOS"		,"SE1","Tot.Títulos",,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    TRCell():New(oSection1,"E1_SALDO"		,"SE1",,,,/*lPixel*/,,,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFont*/,/*lBold*/)
    
    TRFunction():New(oSection1:Cell("E1_SALDO"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
    



Return oReport



Static Function ReportPrint(oReport)
    Private cAliasQry := GetNextAlias()
    //MakeSqlExpr(oReport:uParam)

    oReport:Section(1):BeginQuery()
    BeginSql Alias cAliasQry
        SELECT EA_DATABOR,EA_NUMBOR,EA_PORTADO , EA_AGEDEP, EA_NUMCON, EA_TRANSF, COUNT(1) TITULOS, SUM(E1_SALDO) E1_SALDO
        FROM %table:SEA% SEA
        INNER JOIN %table:SE1% SE1
        ON SE1.D_E_L_E_T_       = ''
        AND E1_FILIAL           = %xFilial:SE1%
        AND E1_PREFIXO          = EA_PREFIXO 
        AND E1_NUM              = EA_NUM
        AND E1_PARCELA          = EA_PARCELA
        AND E1_TIPO             = EA_TIPO
        WHERE EA_CART           = 'R'
        //AND EA_TRANSF           = 'S'
        AND EA_DATABOR BETWEEN %EXP: MV_PAR01% AND %EXP: MV_PAR02 %
        AND SEA.D_E_L_E_T_ = ''
        AND EA_FILIAL = %xFilial:SEA%
        GROUP BY EA_DATABOR,EA_NUMBOR, EA_PORTADO , EA_AGEDEP, EA_NUMCON, EA_CART, EA_TRANSF
        ORDER BY 1,2,3
    EndSql
    oReport:Section(1):EndQuery()
    oReport:Section(1):Print()
Return

