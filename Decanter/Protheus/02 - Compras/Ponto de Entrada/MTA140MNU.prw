#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MTA140MNU
(Adiciona botoes no menu da rotina de Pre Nota - Mata140)
@author TSC679 - CHARLES REITZ
@since 07/12/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6085783)
/*/
User Function MTA140MNU()

	Aadd(aRotina,{ "Imp. Nf-e Xml Arquivo*", "U_IXMLSEF(,'2','1')", 0 , 3, 0, .F.})
	
Return