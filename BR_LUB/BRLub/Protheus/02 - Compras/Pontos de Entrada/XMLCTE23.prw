#include 'protheus.ch'

/*/{Protheus.doc} XMLCTE23
// Ponto de entrada dentro do PE MT103DNF durante a rejeição de validação do ICM/ICM/IPI para reconsiderar rejeição
@author Marcelo Alberto Lauschner
@since 15/06/2019
@version 1.0
@return lRet, Logical, Permite reconsiderar rejeição
@type User Function
/*/
User function XMLCTE23()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .F.
	Local	cCodImp		:= ParamIxb[1]	// 1-Codigo imposto
	Local	nDifBase	:= ParamIxb[2]	// 2-Valor Diferença Base
	Local	nDifVlr		:= ParamIxb[3]	// 3-Valor Diferença Imposto
	Local	nXmlBase	:= ParamIxb[4]	// 4-Base Imposto no XML
	Local	nXmlVlr		:= ParamIxb[5]	// 5-Valor Imposto no XML
	Local	nNfeBase	:= ParamIxb[6]	// 6-Base Imposto na Nota Fiscal
	Local	nNfeVlr		:= ParamIxb[7]	// 7-Valor Imposto na Nota Fiscal
	
	
	// Verifica se é lançamento de nota SPED da Atria Filial Paraná
	// 07/11/2021 
	If ( cCodImp $ "CST" .And. ALLTRIM(cEspecie) == "SPED" .And. cEmpAnt+cFilAnt $ "0204" .AND. aCabec[ aScan(aCabec,{|x| AllTrim(x[1])=="F1_FORNECE"}) ][2] $ '002659'  )
		lRet	:= .T. // Força retorno True - pois assume o CST do TES - indiferente o CST que vier do XML 		
	Endif	

	RestArea(aAreaOld)
	
Return lRet
