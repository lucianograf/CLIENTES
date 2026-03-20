#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"


User Function ITEM()
	Local aParam	:= PARAMIXB
	Local lRet		:= .T.
	Local oObj		:= ""
	Local cIdPonto	:= ""
	Local cIdModel	:= ""

	If (aParam <> NIL)
		oObj 	 := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]

		If cIdPonto == "FORMCOMMITTTSPOS"
            // Integração LEXOS HUB - INICIO
            If ExistBlock("LEXITEM")
                ExecBlock("LEXITEM", .F., .F., {})
            EndIf
            // Integração LEXOS HUB - FIM
		EndIf
	EndIf

Return (lRet)
