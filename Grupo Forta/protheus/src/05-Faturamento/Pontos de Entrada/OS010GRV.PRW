#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

User Function OS010GRV() 
Local nTipo		:= PARAMIXB[1]
Local oFunGenericas

If nTipo == 1
    // Integração LEXOS HUB - INICIO
    If ExistBlock("LEXOS010GRV")
        ExecBlock("LEXOS010GRV", .F., .F., {})
    EndIf
    // Integração LEXOS HUB - FIM
EndIf

Return Nil
