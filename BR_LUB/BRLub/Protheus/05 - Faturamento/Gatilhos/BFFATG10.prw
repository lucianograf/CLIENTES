#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATG10
(Calcula preço de Venda pela Margem 1 digitada no cadastro de tabela de preços)
@author MarceloLauschner
@since 08/08/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATG10()
	
	Local		aAreaOld	:= GetArea()
	Local		nPrcRet	:= Iif(Type("M->DA1_PRCVEN") <> "U",M->DA1_PRCVEN,0)
	
	If MV_PAR01==2 .And. Type("M->DA1_MG1") <> "U" .And. M->DA1_MG1 > 0
		DbSelectArea("SB1") 	
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+MV_PAR02)
			DbSelectArea("SB2")
			DbSetOrder(1)
			If DbSeek(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD)
				nPrcRet	:= Round(SB2->B2_CM1 / ( 100 - M->DA1_MG1) * 100,TamSX3("DA1_PRCVEN")[2])
			Endif
		Endif
	Endif
	
	RestArea(aAreaOld)
	
Return nPrcRet

