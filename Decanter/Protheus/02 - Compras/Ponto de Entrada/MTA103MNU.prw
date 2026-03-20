#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MTA103MNU
(Adiciona botoes no menu da rotina de Documento de Entrada - Mata103)
@author TSC679 - CHARLES REITZ
@since 01/08/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6085783)
/*/
User Function XMTA103MNU()

	Aadd(aRotina,{ "Imp. Nf-e Xml Arquivo*", "U_IXMLSEF(,'2','2')", 0 , 3, 0, .F.})

Return
