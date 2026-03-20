#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} DECA103
Define o prefixo da SE1 (E1_PREFIXO).

Chamada no parametro MV_1DUPREF.

@author william.farias
@since 27/11/2019
@version 1.0
@example
(examples)
@see (links_or_references)
/*/
User Function DECA103()

	Local cRet := Alltrim(SF2->F2_SERIE)+Substr(SF2->F2_FILIAL,3,2)

	If Alltrim(SF2->F2_SERIE) == 'RPS'
		cRet := "R"+Substr(SF2->F2_FILIAL,3,2)
	EndIf

Return cRet
