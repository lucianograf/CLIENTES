#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} STMenu
Adiciona botao no menu de venda TOTVSPDV

@author Carlos Eduardo Reinert 
@since 01/10/2019
@return aRet, 	aRet[1][1] - Se Refere: ao Nome no Menu mostrado ao usuário
				aRet[1][2] - Se Refere: à função que sera executada
@see https://tdn.totvs.com/pages/releaseview.action?pageId=152802891
/*/

User Function STMenu()

	Local aRet := {}
	
	AAdd(aRet,{"Consulta Produtos Decanter","U_DECLJ001()"})
	AAdd(aRet,{"Consulta Fidelidade","U_DECLJ002()"})
	
Return aRet
