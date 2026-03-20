#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} SPCOBREC
Ponto de entrada para preencher o campo F6_COBREC 
@type function
@version 
@author Diana Kistner 
@since 03/12/2020
@return return_type, return_description
/*/
User function SPCOBREC()
/* 
Paramixb[1] => Tipo GNRE
Paramixb[2] => ESTADO da GNRE
*/

	Local cTipoImp  := Paramixb[1]  // Tipo de Imposto (3 - ICMS ST ou B - Difal e Fecp de Difal)
	//Local cEstado   := Paramixb[2]  // Estado da GNRE
	Local cCod      := ""           // Codigo a ser gravado no campo F6_COBREC

    // Se o tipo de imposto for B-Difal e Fecp Difal 
	If cTipoImp == "B"
		If SF6->F6_FECP == '2'
			cCod := "003"
		Else
			cCod := "006"
		Endif
	Else
		If SF6->F6_FECP = '2'
			cCod := "999"
		Else
			cCod := "006"
		Endif
	EndIf

Return cCod
