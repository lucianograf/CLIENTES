/*/{Protheus.doc} FTQTDMIN
Ponto de entrada que permite retornar .T. mesmo que o lote do produto não seja atendido
@type function
@version 
@author Marcelo Alberto Lauschner
@since 16/10/2020
@return return_type, return_description
/*/
User Function FTQTDMIN()

	Local   aAreaOld    := GetArea()
	Local   lRet        := .F.
	Local   cC6Oper     := GdFieldGet('C6_OPER',n)
	Local   cUaOper     := GdFieldGet('UA_OPER',n)

	// Quando o tipo de operação no item for digitado como Baixa de avaria, libera outras quantidades
	If cC6Oper <>  Nil
		If cC6Oper $ GetNewPar("BF_FTVA01","BA#B ")
			lRet    := .T.
		Endif
	Endif

	If cUaOper <>  Nil
		If cUaOper $ GetNewPar("BF_FTVA01","BA#B ")
			lRet    := .T.
		Endif
	Endif


	RestArea(aAreaOld)

Return lRet
