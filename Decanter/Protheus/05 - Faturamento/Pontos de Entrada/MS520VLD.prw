/*/{Protheus.doc} MS520VLD
Ponto de entrada para validar Exclusão de notas Fiscal 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/04/2022
@return variant, return_description
/*/
User Function MS520VLD()

	Local   aRetVld
	Local   aAreaOld        := GetArea()
	Local   lRet            := .T.

	// Gravo log de motivo para exclusão da nota 
    aRetVld		:= U_DCCFGM02("CN",SF2->F2_DOC,,FunName(),.T.)
    lRet    := aRetVld[2]

    RestArea(aAreaOld)

Return lRet
