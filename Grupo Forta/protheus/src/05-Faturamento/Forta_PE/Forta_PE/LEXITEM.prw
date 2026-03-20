#include "protheus.ch"
#include "parmtype.ch"

//-------------------------------------------------
/*/{Protheus.doc} ITEM
Ponto de Entrada MVC para a Rotina MATA010.

Utilizado na Lexos para registrar inclusao/alteracao de Produtos a serem Integrados.

@type function
@version 1.0
@author Gruppe Tecnologia

@return Logical

@see https://tdn.totvs.com/display/public/PROT/ADV0041_PE_MVC_MATA010_P12
/*/
//-------------------------------------------------

User Function LEXITEM()

	oFunGenericas := LexosFnGenericas():New()
	oFunGenericas:ZLXPRD()

Return (.T.)
