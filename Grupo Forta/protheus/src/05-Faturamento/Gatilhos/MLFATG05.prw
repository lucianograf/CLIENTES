#include "Totvs.ch"
/*/{Protheus.doc} MLFATG05
Função para retornar campo ou valor do código de vendedor conforme empresa/filial em uso 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 04/01/2023
@param nInOpcOut, numeric, param_description
@param cInCliCd, character, param_description
@param cInCliLj, character, param_description
@return variant, return_description
/*/
User Function MLFATG05(nInOpcOut,cInCliCd,cInCliLj)

	Local       xOutValor       := Nil
	Local       aAreaOld        := GetArea()
	Local       cCpoVend        := GetNewPar("GF_CPOVEND","A1_VEND")
	Default     nInOpcOut       := 1    // 1=Campo SA1 2-
	Default     cInCliCd        := ""
	Default     cInCliLj        := ""

	// Se deve retornar o nome do campo
	If nInOpcOut   == 1
		xOutValor   := cCpoVend
		// Se deve retornar o valor do código de vendedor do cadastro do cliente
	ElseIf nInOpcOut == 2
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+cInCliCd+cInCliLj)
		xOutValor   := &("SA1->"+cCpoVend)
	ElseIf nInOpcOut == 3
        xOutValor   := ""
		If cFilAnt == "0101" // Forta EQT
			xOutValor += "   AND ((A3_COD BETWEEN '000600' AND '0007ZZ') OR (A3_COD BETWEEN '000500' AND '0005ZZ')) "
		ElseIf cFilAnt == "0201" // Forta FTA
			xOutValor += "   AND A3_COD BETWEEN '000500' AND '0005ZZ' AND A3_COD NOT IN('000510')"
		ElseIf cFilAnt == "0301" // Forta Importadora
			xOutValor += "   AND A3_COD IN('000510')"
		ElseIf cFilAnt == "0401" // Dcondor
			xOutValor += "   AND A3_COD BETWEEN '000100' AND '0001ZZ' "
		ElseIf cFilAnt == "0601" // Baumen 
			xOutValor += "   AND A3_COD BETWEEN '000200' AND '0002ZZ' "
		Endif
    
	Endif

	RestArea(aAreaOld)

Return xOutValor
