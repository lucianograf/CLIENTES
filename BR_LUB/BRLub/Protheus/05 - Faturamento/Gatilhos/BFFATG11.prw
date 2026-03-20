#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATG11
(Retorna margem 1 ao digitar preço de venda no cadastro de tabela de preços)
@author MarceloLauschner
@since 08/08/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATG11()
	
	Local		aAreaOld	:= GetArea()
	Local		nPrcRet	:= Iif(Type("M->DA1_MG1") <> "U",M->DA1_MG1,0)
	
	If MV_PAR01==2 .And. Type("M->DA1_PRCVEN") <> "U" .And. M->DA1_PRCVEN > 0
		DbSelectArea("SB1")
		DbSetOrder(1)
		If DbSeek(xFilial("SB1")+MV_PAR02)
			DbSelectArea("SB2")
			DbSetOrder(1)
			If DbSeek(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD)
				nPrcRet	:= Round((M->DA1_PRCVEN - SB2->B2_CM1) / M->DA1_PRCVEN * 100 ,2)
			Endif
		Endif
	Endif
	
	RestArea(aAreaOld)
	
Return nPrcRet
