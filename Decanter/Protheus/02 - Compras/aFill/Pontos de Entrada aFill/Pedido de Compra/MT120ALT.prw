#INCLUDE "URZUM.CH"

/*/{Protheus.doc} MT120ALT
//Ponto de Entrada para analisar Altera��o e Exclus�o de Pedido Importado no Padr�o
@author urzum
@since 16/08/2018
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function MT120ALT()

	Local lRet := U_UzxPCBrow("MT120ALT",PARAMIXB[1])

Return(lRet)