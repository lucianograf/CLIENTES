#include "Totvs.ch"
/*/{Protheus.doc} DCVTXI01
Função para retornar os dados de conexão Vtex 
@type function
@version  
@author Marcelo Alberto Lauschnere
@since 30/04/2024
@return variant, return_description
/*/
User Function DCVTXI01()

	Local aHeadOut 		:= {}
	Local cURL  	    := GetNewPar("DC_VTEXURL","https://decantervinhos.myvtex.com")
	
	Local cAppKey	    := GetNewPar("DC_VTEXKEY","vtexappkey-decantervinhos-JQBAGL")
	Local cAppToken		:= GetNewPar("DC_VTEXTOK","KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")

	Aadd(aHeadOut, "Content-Type: application/json")
	Aadd(aHeadOut, "X-VTEX-API-AppKey: "+Alltrim(cAppKey))
	Aadd(aHeadOut, "X-VTEX-API-AppToken: " + Alltrim(cAppToken))

Return {cURL,aHeadOut}
