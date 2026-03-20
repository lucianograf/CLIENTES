#include "totvs.ch"
/*/{Protheus.doc} StValPro
description
@type function
@version  
@author Marcelo Alberto Lauschner
@since 24/10/2022
@return variant, return_description
/*/
User Function StValPro()

	Local cCodItem := PARAMIXB[1] // Codigo do produto
    //Local nQuant := PARAMIXB[2] // Quantidade
	Local lRet := .T.

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+cCodItem)
	If !empty(SB1->B1_DESBSE3)
		MsgInfo("Atencao: "+SB1->B1_DESBSE3," Observacao ")
	EndIf

	If STDGPBasket("SL1", "L1_VEND") == '000001' .AND. cFilAnt $ "0101#0108"
		Alert("Informe um VENDEDOR válido antes de registrar produtos!!!")
		lRet := .F.
	EndIf

Return lRet
