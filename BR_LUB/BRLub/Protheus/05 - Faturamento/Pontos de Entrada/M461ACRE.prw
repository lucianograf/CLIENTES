/*/{Protheus.doc} M461ACRE
Ponto de entrada para retornar valor de acréscimo ao pedido de venda
Mas que será usado para Zerar o valor de desconto da SC6 antes dos cálculos fiscais 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 20/11/2022
@return variant, return_description
/*/
User Function M461ACRE() 

	// Exemplo da chamada do PE 
	//If ( aEntry[EP_M461ACRE] )
	//	nAcresFin := Execblock("M461ACRE",.f.,.f.,{nPrcVen,nPrUnit,nAcresFin})
	//Endif 

	//Local 	nInPrcVen 		:= ParamIxb[1]
	//Local 	nInPrunit 		:= ParamIxb[2]
	Local 	nInAcresFin		:= ParamIxb[3]
	Local 	aAreaOld 		:= GetArea() 

	
	// Se considera ou a diferença do preço de lista como desconto 
	If SuperGetMV("MV_NDESCTP",,.F.)
		DbSelectArea("SC6")
		RecLock("SC6",.F.)
		SC6->C6_VALDESC := 0 
		SC6->C6_DESCONT	:= 0
		MsUnlock()
	Endif 

	RestArea(aAreaOld)

Return nInAcresFin 
