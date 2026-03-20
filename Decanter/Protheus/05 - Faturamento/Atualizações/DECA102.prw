#Include 'Protheus.ch'
/*/{Protheus.doc} DECA102
Valida se Tipo Operacao informado é diferente de "01"

Adicionar chamada na validacao de usuario do campo C6_OPER.

@author TSCB57 - William Farias
@since 12/08/2019
@version 1.0
@return logic
/*/
User Function DECA102()

	Local aArea		:= GetArea()
	Local lRet		:= .T.
	Local cOperRot 	:= Alltrim(	M->C6_OPER)

	If FWIsInCallStack("A410Inclui") .Or. FWIsInCallStack("A410Altera")
//		If cOperRot == "01"
//			lRet := .F.
//			MsgAlert("Verificar tipo operação informado, 01 não é permitido.", "Atenção - "+ProcName())
//		EndIf
	EndIf
	
	RestArea(aArea)
		
Return lRet