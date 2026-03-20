#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} M040SE1

Grava dados adicionais na SE1 quando oriundo do faturamento MATA460

@author charles.totvs
@since 04/06/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
user function M040SE1()
	Local aSaveSC5	:=	SC5->(GetArea())
	Local aSaveSF2	:=	SF2->(GetArea())
	Local aSaveSD2	:= 	SD2->(GetArea())

	If FWISInCallStack("A040DupRec") .AND. 	 FWISInCallStack("MaNfs2Fin")
		dbSelectArea("SD2")
		dbSetOrder(3)
		if msSeek(FWXFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE)
			dbSelectArea("SC5")
			dbSetOrder(1)
			If msSeek(FWxFilial("SC5")+SD2->D2_PEDIDO)
				SE1->E1_ZCONPAG	:= SC5->C5_CONDPAG
			EndIf
		EndIf
	EndIF

	SC5->(RestArea(aSaveSC5))
	SF2->(RestArea(aSaveSF2))
	SD2->(RestArea(aSaveSD2))
return