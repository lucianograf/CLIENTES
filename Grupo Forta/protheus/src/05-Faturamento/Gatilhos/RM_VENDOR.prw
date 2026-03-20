#INCLUDE "rwmake.ch"

/*/{Protheus.doc} RM_VEN
//PEGA CAMPO PARA LAYOUT DO VENDOR
@author RAFAE MEYER
@since 04/09/19
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function RM_VEN()

	Local	aAreaOld	:= GetArea()
	Local	nTaxa 		:= 0

	dbSelectArea("SC5")
	dbSetOrder(1)
	If dbSeek(xFilial("SC5")+SE1->E1_PEDIDO)
		nTaxa := SC5->C5_ZPJUROS
	Endif
	
	RestArea(aAreaOld)
	
Return nTaxa