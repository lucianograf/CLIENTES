#Include 'Protheus.ch'



/*/{Protheus.doc} BFFATR01
(Relatório de acumulado de vendas)
@author MarceloLauschner
@since 25/04/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR01()
	
	
	Local 		oReport
	Private 	cPerg1	  	:= ValidPerg("BFFATR01")
	Private 	cAliasS1  	:= GetNextAlias()
	Private	lIsAllFil	:= __cUserId $ GetNewPar("BF_FATR01A","000204#000117#000130") // Chamado 10575
	Private	MV04_ALL	:= 1	// 1-Todos
	Private	MV04_AUT	:= 2	// 2-Automotivo
	Private	MV04_IND	:= 3	// 3-Industrial
	Private	MV04_MIC	:= 4	// 4-Michelin
	Private	MV04_WYN	:= 5	// 5-Wynns
	
	oReport	:= ReportDef()
	oReport:PrintDialog()
	
	
Return


Static Function ReportDef()
	
	Local oReport,oSection1
	Local clNomProg		:= "BFFATR01"
	Local clTitulo 		:= "Relatório de Acumulado de Vendas"
	Local clDesc   		:= "Relatório de Acumulado de Vendas"
	
	Pergunte(cPerg1,.T.)
	//oReport  := TReport():New( cReport, cTitulo, "ATR210" , { |oReport| ATFR210Imp( oReport, cAlias1, cAlias2, aOrdem ) }, cDescri )
	
	oReport:=TReport():New(clNomProg,clTitulo,,{|oReport| ReportPrint(oReport)},clDesc)
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage	:= .T.		// Não imprime pagina de parametros
	oReport:SetLandScape()
	
	oSection1 := TRSection():New(oReport,"",{},{})
	//TRSection():New( oReport, STR0014 ,{}, aOrd ) // "Entidade Contabil"
	oSection1:SetColSpace(0)
	oSection1:SetTotalInLine(.F.)
	
	//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock)
	
	TRCell():New(oSection1,"C5VEND1" 	,,"Vend."		,""			 		,6,.T.,{|| cVend })
	TRCell():New(oSection1,"A3_NREDUZ"	,,,,,,{|| cDescVend })
	
	TRCell():New(oSection1,"TXDLITROS"  ,,"Tx.Lits"		,"@E 999,999"			,7	,.T.,{|| nTxDLitros 	})
	TRCell():New(oSection1,"TXDVALOR"   ,,"Tx.R$ Vlr"		,"@E 9,999,999.99"	,12	,.T.,{|| nTxDValor 	})
	TRCell():New(oSection1,"TXDUNID"	,,"Tx.R$/Lit"		,"@E 9,999.99"		,8	,.T.,{|| nTxDUnid 	})
	TRCell():New(oSection1,"TXDVLSN"	,,"Tx.Lit.SN"		,"@E 999,999"			,7	,.T.,{|| nTxDVlSn 	})
	TRCell():New(oSection1,"MCDQUANT"	,,"Mc.Quant."		,"@E 999,999"			,7	,.T.,{|| nMcDQuant 	})
	TRCell():New(oSection1,"MCDVALOR"	,,"Mc.Valor"		,"@E 999,999.99"		,10	,.T.,{|| nMcDValor 	})
	TRCell():New(oSection1,"MCDUNID"	,,"Mc.R$/Un"		,"@E 9,999.99"		,8	,.T.,{|| nMcDUnid  	})
	TRCell():New(oSection1,"WYDQUANT"	,,"Wy.Quant."		,"@E 9,999.99"		,8	,.T.,{|| nWyDQuant	})
	TRCell():New(oSection1,"WYDVALOR"	,,"Wy.R$ Valor"	,"@E 999,999.99"		,10	,.T.,{|| nWyDValor 	})
	TRCell():New(oSection1,"WYDUNID"	,,"Wy.R$/Unid"	,"@E 9,999.99"		,8	,.T.,{|| nWyDUnid		})
	TRCell():New(oSection1,"OUDQUANT"	,,"Ou.Quant."		,"@E 9,999.99"		,8	,.T.,{|| nOuDQuant	})
	TRCell():New(oSection1,"OUDVALOR"	,,"Ou.R$ Valor"	,"@E 999,999.99"		,10	,.T.,{|| nOuDValor	})
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	TRCell():New(oSection1,"HODLITROS"  ,,"Ho.Lits"		,"@E 999,999"			,7	,.T.,{|| nHoDLitros 	})
	TRCell():New(oSection1,"HODVALOR"   ,,"Ho.R$ Vlr"		,"@E 9,999,999.99"	,12	,.T.,{|| nHoDValor 	})
	TRCell():New(oSection1,"HODUNID"	,,"Ho.R$/Lit"		,"@E 9,999.99"		,8	,.T.,{|| nHoDUnid 	})
	
	TRCell():New(oSection1,"TXPLITROS"  ,,"Tx.Lits"		,"@E 9,999,999"		,10	,.T.,{|| nTxPLitros 	})
	TRCell():New(oSection1,"TXPVALOR"   ,,"Tx.R$ Vlr"		,"@E 99,999,999.99"	,13	,.T.,{|| nTxPValor 	})
	TRCell():New(oSection1,"TXPUNID"	,,"Tx.R$/Lit"		,"@E 9,999.99"		,8	,.T.,{|| nTxPUnid 	})
	TRCell():New(oSection1,"TXPVLSN"	,,"Tx.Lit.SN"		,"@E 999,999"			,7	,.T.,{|| nTxPVlSn 	})
	TRCell():New(oSection1,"MCPQUANT"	,,"Mc.Quant."		,"@E 999,999"			,7	,.T.,{|| nMcPQuant 	})
	TRCell():New(oSection1,"MCPVALOR"	,,"Mc.Valor"		,"@E 99,999,999.99"	,13	,.T.,{|| nMcPValor 	})
	TRCell():New(oSection1,"MCPUNID"	,,"Mc.R$/Un"		,"@E 9,999.99"		,8	,.T.,{|| nMcPUnid  	})
	TRCell():New(oSection1,"WYPQUANT"	,,"Wy.Quant."		,"@E 99,999,999.99"	,13	,.T.,{|| nWyPQuant	})
	TRCell():New(oSection1,"WYPVALOR"	,,"Wy.R$ Valor"	,"@E 999,999.99"		,10	,.T.,{|| nWyPValor 	})
	TRCell():New(oSection1,"WYPUNID"	,,"Wy.R$/Unid"	,"@E 9,999.99"		,8	,.T.,{|| nWyPUnid		})
	TRCell():New(oSection1,"OUPQUANT"	,,"Ou.Quant."		,"@E 9,999.99"		,8	,.T.,{|| nOuPQuant	})
	TRCell():New(oSection1,"OUPVALOR"	,,"Ou.R$ Valor"	,"@E 999,999.99"		,10	,.T.,{|| nOuPValor	})
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	TRCell():New(oSection1,"HOPLITROS"  ,,"Ho.Lits"		,"@E 9,999,999"		,10	,.T.,{|| nHoPLitros 	})
	TRCell():New(oSection1,"HOPVALOR"   ,,"Ho.R$ Vlr"		,"@E 99,999,999.99"	,13	,.T.,{|| nHoPValor 	})
	TRCell():New(oSection1,"HOPUNID"	,,"Ho.R$/Lit"		,"@E 9,999.99"		,8	,.T.,{|| nHoPUnid 	})
	
	TRCell():New(oSection1,"GRPVALOR"	,,"R$ Geral"		,"@E 99,999,999.99"	,13	,.T.,{|| nGrValor	})
	
	//TRFunction():New(oSection1:Cell("F2_VALFAT"),/* cID */,"SUM",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	
	oBreakFil  := TRBreak():New(oSection1, {|| cFilRel } , {|| "SUBTOTAL --> "+cNomFil })
	oBreakSup  := TRBreak():New(oSection1, {|| cSuper } , {|| "SUBTOTAL --> "+cNomSup })
	
	TRFunction():New(oSection1:Cell("TXDLITROS"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXDVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("TXDUNID"),""/* cID */,"ONPRINT",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{|| 150 }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXDVLSN"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCDQUANT"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCDVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("MCDUNID"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYDQUANT"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYDVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("WYDUNID"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUDQUANT"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUDVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	TRFunction():New(oSection1:Cell("HODLITROS"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("HODVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	
	TRFunction():New(oSection1:Cell("TXPLITROS"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXPVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("TXPUNID"),""/* cID */,"ONPRINT",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{|| 150 }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXPVLSN"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCPQUANT"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCPVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("MCPUNID"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYPQUANT"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYPVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("WYPUNID"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUPQUANT"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUPVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	TRFunction():New(oSection1:Cell("HOPLITROS"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("HOPVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("GRPVALOR"),""/* cID */,"SUM",oBreakFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
	
	TRFunction():New(oSection1:Cell("TXDLITROS"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXDVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("TXDUNID"),""/* cID */,"ONPRINT",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,{|| 150 }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXDVLSN"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCDQUANT"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCDVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("MCDUNID"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYDQUANT"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYDVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("WYDUNID"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUDQUANT"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUDVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	TRFunction():New(oSection1:Cell("HODLITROS"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("HODVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	
	TRFunction():New(oSection1:Cell("TXPLITROS"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXPVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("TXPUNID"),""/* cID */,"ONPRINT",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,{|| 150 }/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("TXPVLSN"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCPQUANT"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("MCPVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("MCPUNID"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("PRPUNID"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYPQUANT"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("WYPVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("WYPUNID"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUPQUANT"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("OUPVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	TRFunction():New(oSection1:Cell("HOPLITROS"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("HOPVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	TRFunction():New(oSection1:Cell("GRPVALOR"),""/* cID */,"SUM",oBreakSup/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/)
	//TRFunction():New(oSection1:Cell("VAL_CORR"),""        ,"SUM",oBreak2            ,          ,            ,            ,.F.               ,.F.)
	
Return(oReport)


Static Function ReportPrint( oReport )
	
	Local 	oSection1 		:= oReport:Section(1)
	Local		cPrintT	:= ""
	Local		cExpSql	:= ""
	Private	cDescVend	:=	""
	Private	aTotSup	:= 	{}
	Private	nTxDLitros	:= 	0
	Private	nTxDSubLts	:=	0
	Private	nTxDValor	:= 	0
	Private	nTxDSubVlr	:=	0
	Private	nTxDUnid	:= 	0
	Private	nTxDVlSn	:= 	0
	Private	nMcDQuant	:= 	0
	Private	nMcDValor	:= 	0
	Private	nMcDUnid	:= 	0
	Private	nWyDQuant	:= 	0
	Private	nWyDValor	:= 	0
	Private	nWyDUnid	:= 	0
	Private	nOuDQuant	:= 	0
	Private	nOuDValor	:= 	0
	Private	nOuDUnid	:= 	0
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	Private	nHoDLitros	:= 	0
	Private	nHoDValor	:= 	0
	Private	nHoDUnid	:= 	0
	Private	nTxPLitros	:= 	0
	Private	nTxPSubLts	:=	0
	Private	nTxPValor	:= 	0
	Private	nTxPSubVlr	:=	0
	Private	nTxPUnid	:= 	0
	Private	nTxPVlSn	:= 	0
	Private	nMcPQuant	:= 	0
	Private	nMcPValor	:= 	0
	Private	nMcPUnid	:= 	0
	Private	nWyPQuant	:= 	0
	Private	nWyPValor	:= 	0
	Private	nWyPUnid	:= 	0
	Private	nOuPQuant	:= 	0
	Private	nOuPValor	:= 	0
	Private	nOuPUnid	:= 	0
	//IAGO 19/10/2016 Chamado(16093) HOUGHTON
	Private	nHoPLitros	:= 	0
	Private	nHoPValor	:= 	0
	Private	nHoPUnid	:= 	0
	
	Private	nGrValor	:= 	0
	Private	cVend		:= 	""
	Private	cSuper		:= 	""
	Private	cFilRel	:= 	""
	Private	cNomFil	:=	""
	Private	cNomSup	:= 	""
	
	If lIsAllFil
		cExpSql	:= "% BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'%"
	Else
		cExpSql	:= "% = '"+cFilAnt+"'%"
	Endif
	
	If MV_PAR04 == MV04_ALL			// 1-Todos
		cExpMv04 	:= "%%"
	ElseIf MV_PAR04 == MV04_AUT		// 2-Automotivo
		cExpMv04 	:= "% AND B1_PROC NOT IN('000473','000449','000455','002334') AND A3_SUPER != '000900' %"
	ElseIf MV_PAR04 == MV04_IND		// 3-Industrial
		cExpMv04 	:= "% AND A3_SUPER = '000900' %"
		// Alterada a forma de visualizar Industrial para sempre mostrar filiais 
		cExpSql	:= "% BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'%"
	ElseIf MV_PAR04 == MV04_MIC		// 4-Michelin
		cExpMv04	:= "% AND B1_PROC = '000473' %"
	ElseIf MV_PAR04 == MV04_WYN		// 5-Wynns
		cExpMv04	:= "% AND B1_PROC IN('000449','000455','002334')% "
	Endif
	
	
	oSection1:Init()
	
	BeginSql Alias cAliasS1
		COLUMN C5_EMISSAO AS DATE
		COLUMN C5_DTPROGM AS DATE
		SELECT	DECODE(C5_FILIAL,'01','FILIAL SC','04','FILIAL PR','05','FILIAL RS','07','FILIAL SP','08','FILIAL MG') FILIAL,
		DECODE(A3_SUPER,'000900','INDUSTRIAL','AUTOMOTIVO') SUPERVISOR,
		C5_VEND1,
		A3_NREDUZ,
		C5_EMISSAO,
		C5_DTPROGM,
		B1_PROC,
		B1_COD,
		B1_GRUPO,
		B1_QTELITS,
		C6_BLQ,
		C6_QTDVEN,
		C6_QTDENT,
		C6_PRCVEN,
	CASE WHEN C6_PRODUTO IN(SELECT PSN_COD FROM bf_prod_sn ) THEN 'SN' ELSE '  ' END LINHA_SN
		FROM %Table:SF4%  SF4, %Table:SA3%  SA3, %Table:SB1%  SB1, %Table:SC6%  SC6, %Table:SC5% SC5
		WHERE SF4.%NotDel%
		AND SF4.F4_DUPLIC = 'S'
		AND SF4.F4_ESTOQUE = 'S'
		AND SF4.F4_CODIGO = SC6.C6_TES
		AND SF4.F4_FILIAL = SC6.C6_FILIAL
		AND SA3.D_E_L_E_T_(+) = ' '
		AND SA3.A3_COD(+) = SC5.C5_VEND1
		AND SA3.A3_FILIAL(+) = ' '
		AND SB1.D_E_L_E_T_ = ' '
		AND SB1.B1_COD = SC6.C6_PRODUTO
		AND SB1.B1_FILIAL = SC6.C6_FILIAL
		AND SC6.%NotDel%
		AND SC6.C6_NUM = SC5.C5_NUM
		AND SC6.C6_FILIAL = SC5.C5_FILIAL
		AND SC5.%NotDel%
		AND SC5.C5_DTPROGM <= %Exp:DTOS(LastDay(MV_PAR02))%
		AND SC5.C5_EMISSAO BETWEEN %Exp:DTOS(MV_PAR01)% AND %Exp:DTOS(MV_PAR02)%
		AND SC5.C5_TIPO = 'N'
		%Exp:cExpMv04%
		AND SC5.C5_FILIAL %Exp:cExpSql%
		ORDER BY 2,1,3,5
	EndSql
	
	oReport:SetMeter(RecCount())
	
	While !Eof()
		
		oReport:IncMeter()
		
		//If cVend == "000407"
		//Endif
		If !Empty(cVend) .And. cVend <> (cAliasS1)->C5_VEND1
			
			nTxDUnid	:= 	Round(nTxDValor/nTxDLitros,2)
			nMcDUnid	:= 	Round(nMcDValor/nMcDQuant,2)
			nWyDUnid	:=	Round(nWyDValor/nWyDQuant,2)
			// IAGO 19/10/2016 Chamado(16093) HOUGHTON
			nHoDUnid	:= 	Round(nHoDValor/nHoDLitros,2)
			nTxPUnid	:= 	Round(nTxPValor/nTxPLitros,2)
			nMcPUnid	:= 	Round(nMcPValor/nMcPQuant,2)
			nWyPUnid	:=	Round(nWyPValor/nWyPQuant,2)
			// IAGO 19/10/2016 Chamado(16093) HOUGHTON
			nHoPUnid	:= 	Round(nHoPValor/nHoPLitros,2)
			
			//cPrintT	+= cVend + " " + cValTochar(nTxDLitros) + " " + cValtochar(nTxPLitros)+Chr(13)+Chr(10)
			
			oSection1:PrintLine()
			
			nTxDValor		:= 	0
			nTxDLitros		:= 	0
			nTxDUnid		:=	0
			nTxDVlSn		:= 	0
			nMcDQuant		:=	0
			nMcDValor		:=	0
			nMcDUnid		:=	0
			nWyDQuant		:=	0
			nWyDValor		:=	0
			nWyDUnid		:=	0
			nOuDQuant		:=	0
			nOuDValor		:=	0
			//IAGO 19/10/2016 Chamado(16093) HOUGHTON
			nHoDLitros		:= 	0
			nHoDValor		:= 	0
			nHoDUnid		:= 	0
			nTxPValor		:= 	0
			nTxPLitros		:= 	0
			nTxPUnid		:=	0
			nTxPVlSn		:= 	0
			nMcPQuant		:=	0
			nMcPValor		:=	0
			nMcPUnid		:=	0
			nWyPQuant		:=	0
			nWyPValor		:=	0
			nWyPUnid		:=	0
			nOuPQuant		:=	0
			nOuPValor		:=	0
			//IAGO 19/10/2016 Chamado(16093) HOUGHTON
			nHoPLitros		:= 	0
			nHoPValor		:= 	0
			nHoPUnid		:= 	0
			nGrValor		:= 	0
		Endif
		
		If !Empty(cFilRel) .And. cFilRel <> (cAliasS1)->FILIAL
			cNomFil	:=	cFilRel
		Endif
		If !Empty(cSuper) .And. cSuper <> (cAliasS1)->SUPERVISOR
			cNomSup		:= 	cSuper
		Endif
		If (cAliasS1)->C5_EMISSAO == MV_PAR03
			If (cAliasS1)->LINHA_SN == 'SN'
				nTxDVlSn		+= (cAliasS1)->B1_QTELITS * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			Endif
			
			If (cAliasS1)->B1_PROC $ "000468"
				nTxDValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
				nTxDLitros		+= (cAliasS1)->B1_QTELITS * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			ElseIf (cAliasS1)->B1_PROC $ "000473" .And. AllTrim((cAliasS1)->B1_COD) != "385736"
				nMcDQuant		+= Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
				nMcDValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			ElseIf (cAliasS1)->B1_PROC $ "000449#000455#002334"
				nWyDQuant		+= Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
				nWyDValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			//IAGO 19/10/2016 Chamado(16093) HOUGHTON
			ElseIf (cAliasS1)->B1_PROC $ "004748"
				nHoDValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
				nHoDLitros		+= (cAliasS1)->B1_QTELITS * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			Else
				nOuDQuant		+= Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
				nOuDValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			Endif
			
		Endif
		If (cAliasS1)->LINHA_SN == 'SN'
			nTxPVlSn		+= (cAliasS1)->B1_QTELITS * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
		Endif
		
		If (cAliasS1)->B1_PROC $ "000468"
			nTxPValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			nTxPLitros		+= (cAliasS1)->B1_QTELITS * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
		ElseIf (cAliasS1)->B1_PROC $ "000473" .And. AllTrim((cAliasS1)->B1_COD) != "385736"
			nMcPQuant		+= Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			nMcPValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
		ElseIf (cAliasS1)->B1_PROC $ "000449#000455#002334"
			nWyPQuant		+= Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			nWyPValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
		//IAGO 19/10/2016 Chamado(16093) HOUGHTON
		ElseIf (cAliasS1)->B1_PROC $ "004748"
			nHoPValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			nHoPLitros		+= (cAliasS1)->B1_QTELITS * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
		Else
			nOuPQuant		+= Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
			nOuPValor		+= (cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
		Endif
		
		nGrValor			+= 	(cAliasS1)->C6_PRCVEN * Iif( "R" $ (cAliasS1)->C6_BLQ,(cAliasS1)->C6_QTDENT, (cAliasS1)->C6_QTDVEN)
		
		cDescVend		:= (cAliasS1)->A3_NREDUZ
		cFilRel			:= (cAliasS1)->FILIAL
		cVend 			:= (cAliasS1)->C5_VEND1
		cSuper			:= (cAliasS1)->SUPERVISOR
		
		DbSelectArea(cAliasS1)
		(cAliasS1)->(DbSkip())
	Enddo
	If !Empty(cFilRel)
		cNomFil	:=	cFilRel
	Endif
	If !Empty(cSuper)
		cNomSup		:= 	cSuper
	Endif
	
	// última linha do vendedor também precisa ser gerado 
	If !Empty(cVend) 
		
		nTxDUnid	:= 	Round(nTxDValor/nTxDLitros,2)
		nMcDUnid	:= 	Round(nMcDValor/nMcDQuant,2)
		nWyDUnid	:=	Round(nWyDValor/nWyDQuant,2)
		//IAGO 19/10/2016 Chamado(16093) HOUGHTON
		nHoDUnid	:= 	Round(nHoDValor/nHoDLitros,2)
		
		nTxPUnid	:= 	Round(nTxPValor/nTxPLitros,2)
		nMcPUnid	:= 	Round(nMcPValor/nMcPQuant,2)	
		nWyPUnid	:=	Round(nWyPValor/nWyPQuant,2)
		//IAGO 19/10/2016 Chamado(16093) HOUGHTON
		nHoPUnid	:= 	Round(nHoPValor/nHoPLitros,2)
		
		//cPrintT	+= cVend + " " + cValTochar(nTxDLitros) + " " + cValtochar(nTxPLitros)+Chr(13)+Chr(10)
		
		oSection1:PrintLine()
		
		nTxDValor		:= 	0
		nTxDLitros		:= 	0
		nTxDUnid		:=	0
		nTxDVlSn		:= 	0
		nMcDQuant		:=	0
		nMcDValor		:=	0
		nMcDUnid		:=	0
		nWyDQuant		:=	0
		nWyDValor		:=	0
		nWyDUnid		:=	0
		nOuDQuant		:=	0
		nOuDValor		:=	0
		//IAGO 19/10/2016 Chamado(16093) HOUGHTON
		nHoDLitros		:= 	0
		nHoDValor		:= 	0
		nHoDUnid		:= 	0
		nTxPValor		:= 	0
		nTxPLitros		:= 	0
		nTxPUnid		:=	0
		nTxPVlSn		:= 	0
		nMcPQuant		:=	0
		nMcPValor		:=	0
		nMcPUnid		:=	0
		nWyPQuant		:=	0
		nWyPValor		:=	0
		nWyPUnid		:=	0
		nOuPQuant		:=	0
		nOuPValor		:=	0
		//IAGO 19/10/2016 Chamado(16093) HOUGHTON
		nHoPLitros		:= 	0
		nHoPValor		:= 	0
		nHoPUnid		:= 	0
		nGrValor		:= 	0
	Endif
	
	oSection1:Finish()
	
	//Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" cPrintT",cPrintT,{"Ok"},3)
	
Return



/*/{Protheus.doc} ValidPerg
(long_description)
@author MarceloLauschner
@since 19/11/2014
@version 1.0
@param cPerg2, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ValidPerg(cPerg2)
	
	Local aAreaOld := GetArea()
	Local aRegs := {}
	Local i,j
	Local cPerg1
	
	dbSelectArea("SX1")
	dbSetOrder(1)
	// Este tratamanto é necessário pois para a versão 10, o protheus mudou o tamanho do grupo de perguntas de 6 para 10 digitos
	cPerg1 := cPerg2
	//                               123456789012345                                                                                                                   123456789012345                                            123456789012345                                            123456789012345                                            123456789012345
	
	//     "X1_GRUPO" ,"X1_ORDEM"	,"X1_PERGUNT"    			,"X1_PERSPA"				,"X1_PERENG"			,"X1_VARIAVL"	,"X1_TIPO"	,"X1_TAMANHO"		,"X1_DECIMAL"		,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID","X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01","X1_VAR02","X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02","X1_VAR03","X1_DEF03"	,"X1_DEFSPA3"		,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04","X1_VAR05","X1_DEF05","X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05","X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
	Aadd(aRegs,{cPerg1 ,"01"			,"Emissão de"				,"Emissão de "	 		,"Emissão de"			,"mv_ch1"		,"D"		,8					,0					,0				,"G"		,""			,"mv_par01"	,""				,""				,""				,""			,""			,""					,""					,""					,""			,""			,""				,""					,""				,""				,""				,""				,""				,""				,""			,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg1 ,"02"			,"Emissão até"			,"Emissão até"			,"Emissão"				,"mv_ch2"		,"D"		,8					,0					,0				,"G"		,""			,"mv_par02"	,""				,""				,""				,""			,""			,""					,""					,""					,""			,""			,""				,""					,""				,""				,""				,""				,""				,""				,""			,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg1 ,"03"			,"Dia"						,"Dia"						,"Dia"					,"mv_ch3"		,"D"		,8					,0					,0				,"G"		,""			,"mv_par03"	,""				,""				,""				,""			,""			,""					,""					,""					,""			,""			,""				,""					,""				,""				,""				,""				,""				,""				,""			,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg1 ,"04"			,"Segmento"				,"Segmento"    			,"Segmento"  			,"mv_ch4"		,"N"    	,1					,0					,1				,"C"		,""			,"mv_par04"	,"Todos"    	,"Todos"      ,"Todos"	    ,""	   	,""			,"Automotivo"    	,"Automotivo"    	,"Automotivo"    	,""	       ,""			,"Industrial" ,"Industrial"    	,"Industrial"	,""				,""				,"Michelin"	,"Michelin"	,"Michelin"	,""			,""			,"Wynns"	,"Wynns"		,"Wynns"		,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg1 ,"05"			,"Filial de"				,"Filial de "	 			,"Filial de"			,"mv_ch5"		,"C"		,Len(cFilAnt)		,0					,0				,"G"		,""			,"mv_par05"	,""				,""				,""				,""			,""			,""					,""					,""					,""			,""			,""			,""					,""				,""			,""			,""				,""				,""				,""			,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg1 ,"06"			,"Filial Até"				,"Filial Até"	 			,"Filial Até"			,"mv_ch6"		,"C"		,Len(cFilAnt)		,0					,0				,"G"		,""			,"mv_par06"	,""				,""				,""				,""			,""			,""					,""					,""					,""			,""			,""			,""					,""				,""			,""			,""				,""				,""				,""			,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})
	
	dbSelectArea("SX1")
	dbSetOrder(1)
	
	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg1+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
			/*Else
			RecLock("SX1",.F.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock() */
		Endif
	Next
	
	RestArea(aAreaOld)
	
Return cPerg1
