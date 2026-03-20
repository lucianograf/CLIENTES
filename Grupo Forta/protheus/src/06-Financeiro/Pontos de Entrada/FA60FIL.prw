#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} FA60FIL
//  Ponto de Entrada para filtrar os títulos para gerar Borderô
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return cRetFil, String, Expressão Advpl para filtro na SE1

@type function
/*/
User function FA60FIL()
	
	Local	cRetFil
	
	cRetFil	:= "SE1->E1_PORTADO == '" + SA6->A6_COD + "' .And. SE1->E1_AGEDEP == '" + SA6->A6_AGENCIA + "' .And. SE1->E1_CONTA == '" + SA6->A6_NUMCON +  "'"

Return cRetFil