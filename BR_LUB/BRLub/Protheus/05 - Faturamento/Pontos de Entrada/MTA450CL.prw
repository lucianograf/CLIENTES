#include "topconn.ch"

/*/{Protheus.doc} MTA450CL
Ponto de entrada após liberação de crédito por cliente. 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 23/08/2021
@return variant, return_description
/*/
User Function MTA450CL()

	Local   aAreaOld    := GetArea()

	// Empresa Atrialub - SC
	If cEmpAnt $ "02" .And. cFilAnt == "01"
		// Se a data programada do pedido for mais de 2 dias e não tiver sido integrado com a Iconic ainda.
		If SC5->C5_DTPROGM > Date()+2 .And. Empty(SC5->C5_XESTAVC)
			stAjustC9(SC5->C5_NUM)
		Endif
	Endif

	RestArea(aAreaOld)

Return


/*/{Protheus.doc} stAjustC9
Efetua ajuste do pedido de venda estornando a liberação dos itens
@type function
@version  
@author Marcelo Alberto Lauschner
@since 23/08/2021
@param cPedFat, character, param_description
@return variant, return_description
/*/
Static Function stAjustC9(cPedFat)

	Local 	cQry 	 := ""
	Local   nQteBlq	 := 0
	Local 	nVlrCred := 0

	cQry += "SELECT C9_QTDLIB,C9_PRODUTO,C9_PEDIDO,C9_ITEM,C9_SEQUEN "
	cQry += "  FROM " + RetSqlName("SC9") + " C9," + RetSqlName("SB1") + " B1 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_CABO IN('TEX','IPI') "
	cQry += "   AND B1_COD = C9_PRODUTO "
	cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry += "   AND C9.D_E_L_E_T_ =' ' "
	cQry += "   AND C9_NFISCAL = '  ' "
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_PEDIDO =  '" +cPedFat+"' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "

	TcQuery cQry NEW ALIAS "QRC9"

	While !Eof()

		DbSelectArea ("SC9")
		DbSetOrder(1)
		If DbSeek(xfilial("SC9")+QRC9->C9_PEDIDO+QRC9->C9_ITEM+QRC9->C9_SEQUEN+QRC9->C9_PRODUTO)

			nQteBlq     := SC9->C9_QTDLIB

			// Executa Estorno do Item
			SC9->(A460Estorna(/*lMata410*/,/*lAtuEmp*/,@nVlrCred))
			// Cad. item do pedido de venda
			DbSelectArea("SC6")
			SC6->(DbSetOrder(1))
			SC6->(DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM

			// A quantidade é liberada com bloqueio de estoque
			MaLibDoFat(SC6->(RecNo()),nQteBlq,.T./*lCredito*/,.F./*lEstoque*/,.F./*lAvCred*/,.F./*lAvEst*/,.F./*lLibPar*/,.F./*lTrfLocal*/,/*aEmpenho*/,/*bBlock*/,/*aEmpPronto*/,/*lTrocaLot*/,/*lOkExpedicao*/,nVlrCred,/*nQtdalib2*/)

			SC6->(MaLiberOk({SC9->C9_PEDIDO},.F.))
		Endif

		DbSelectArea("QRC9")
		DbSkip()
	Enddo
	QRC9->(DbCloseArea())

Return
