#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

User Function M460MARK()
	Local cMark     := PARAMIXB[1] // MARCA UTILIZADA
	Local lInvert   := PARAMIXB[2] // SELECIONOU "MARCA TODOS"
	Local lRet      := .T.

    // Integração LEXOS HUB - INICIO
    If ExistBlock("LEXM4MARK")
        ExecBlock("LEXM4MARK", .F., .F., {cMark,lInvert})
    EndIf
    // Integração LEXOS HUB - FIM

Return lRet

