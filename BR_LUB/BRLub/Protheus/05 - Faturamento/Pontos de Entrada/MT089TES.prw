#include 'protheus.ch'
#include 'parmtype.ch'

//If (ExistBlock("MT089TES"))
//	cRet := ExecBlock("MT089TES",.F.,.F.,{nEntSai,cTpOper,cClieFor,cLoja,cProduto})
//	If Valtype( cRet ) == "C"
//		cQuery := cRet
//		lRet := .F.
//	EndIf
//EndIf


/*/{Protheus.doc} MT089TES
Ponto de entrada para retornar uma query customizada para filtrar os Tipos de Tes Inteligente
@author Marcelo Alberto Lauschner
@since 31/07/2017
@version 1.0
@type function
/*/
User function MT089TES()

	Local	aAreaOld	:= GetArea()
	Local	cRetSql		:= ""
	Local	nEntSai		:= ParamIxb[1]
	Local	cTpOper		:= ParamIxb[2]
	//Local	cClieFor	:= ParamIxb[3]
	//Local	cLoja		:= ParamIxb[4]
	Local	cProduto	:= ParamIxb[5]

	dbSelectArea("SB1")
	dbSetOrder(1)
	dbSeek(xFilial("SB1") + cProduto)

	cRetSql += "SELECT ROW_NUMBER() OVER("
	If SFM->(FieldPos("FM_XTESORI")) <> 0
		cRetSql += " ORDER BY FM_XTESORI DESC,FM_EST DESC,FM_FORNECE DESC,FM_GRPROD DESC,FM_PRODUTO DESC,FM_POSIPI DESC,FM_CLIENTE DESC,FM_TIPOMOV DESC,FM_TIPOCLI DESC "// +SqlOrder(SFM->(IndexKey()))
	Else	
		cRetSql += " ORDER BY FM_EST DESC,FM_FORNECE DESC,FM_GRPROD DESC,FM_PRODUTO DESC,FM_POSIPI DESC,FM_CLIENTE DESC,FM_TIPOMOV DESC,FM_TIPOCLI DESC"// +SqlOrder(SFM->(IndexKey()))
	Endif
	cRetSql += " ) FMSEQ,FM.* " 
	cRetSql += "  FROM (SELECT SFM.* "
	cRetSql	+= "  FROM " + RetSqlName("SFM") + " SFM "
	cRetSql += " WHERE SFM.FM_FILIAL = '" + xFilial("SFM") + "'"
	cRetSql	+= "   AND SFM.FM_TIPO = '" + cTpOper + "'"
	cRetSql += "   AND SFM.D_E_L_E_T_=' ' "
	// Verifica se o campo existe 
	If SFM->(FieldPos("FM_XTESORI")) <> 0
		cRetSql	+= "   AND (SFM.FM_XTESORI = ' ' OR SFM.FM_XTESORI = '" + IIf(nEntSai==1,SB1->B1_TE,SB1->B1_TS)+ "')"
	Endif
	cRetSql	+= "   AND (SFM.FM_PRODUTO = ' ' OR SFM.FM_PRODUTO = '" + SB1->B1_COD + "')"
	cRetSql	+= "   AND (SFM.FM_GRPROD = ' ' OR SFM.FM_GRPROD = '" + SB1->B1_GRTRIB + "')"
	cRetSql	+= "   AND (SFM.FM_POSIPI = ' ' OR SFM.FM_POSIPI = '" + SB1->B1_POSIPI + "')"
	cRetSql += ")  FM "
	
	//CopyToClipBoard( cRetSql )

	RestArea(aAreaOld)

Return cRetSql
