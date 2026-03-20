#include "protheus.ch"
#include "rwmake.ch"

User Function M410ALOK()

_lRet := .t.
If Funname() == "MATA410"
	If !FwIsInCallStack("A410COPIA")
		If SC5->C5_SITDEC <> "6"
			If SC5->C5_SITDEC == "1" .Or. SC5->C5_LIBEROK == "S"
				MsgStop("Pedido Liberado ou Em Fase de Montagem!!! Não será permitida Alteração.")
				_lRet := .f.
			EndIf
		EndIf
	EndIf
EndIf

Return _lRet