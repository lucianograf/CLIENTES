#include "protheus.ch"
#include "parmtype.ch"
//-------------------------------------------------
/*/{Protheus.doc} OS010GRV
Ponto de Entrada para a Rotina OMSA010.

Utilizado na Lexos para registrar inclusao/alteracao 
de Tabelas de Precos a serem Integrados.

@type function
@version 1.0
@author Gustavo Schumann - Gruppe

@return Nil

@see https://tdn.totvs.com/pages/releaseview.action?pageId=631329310
/*/
//-------------------------------------------------

User Function LEXOS010GRV() 
Local oFunGenericas

	oFunGenericas := LexosFnGenericas():New()
	oFunGenericas:ZLXPRC()

Return Nil
