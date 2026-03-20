#Include "Urzum.ch"

/*/{Protheus.doc} XFISLF
Este Ponto de Entrada permite altera��es das refer�ncias fiscais, conforme regra espec�fica do cliente.
@type   : User Function
@author : aFill
@since  : 29/11/2021
@version: 1.00
@link 	: http://tdn.totvs.com/pages/releaseview.action?pageId=6077129
/*/
User Function XFISLF()

	Local nItem := ParamIXB[1]

	U_UZXFISLF(nItem)

Return
