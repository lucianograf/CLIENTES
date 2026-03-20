#include "protheus.ch"
/*/{Protheus.doc} RM_VEN2
//PEGA CAMPO PARA LAYOUT DO VENDOR  
@author RAFAE MEYER 
@since 04/09/19  
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function RM_VEN2()

	Local	aAreaOld	:= GetArea()
	Local	cParc 		:= "   "

	dbSelectArea("SC5")
	dbSetOrder(1)
	If dbSeek(xFilial("SC5")+SE1->E1_PEDIDO)

		If SC5->C5_ZQPARC > 12 
			cParc := '376' 
		Else
			cParc := '327'
		Endif
	Endif
	
	RestArea(aAreaOld)

Return cParc 