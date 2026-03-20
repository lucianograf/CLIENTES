#Include 'Protheus.ch'


/*/{Protheus.doc} BFCOMV02 (Validação para não permitir bloquear produto com estoque)
@type function
@author Iago Luiz Raimondi
@since 12/07/2016
@version 1.0
@return ${return}, ${return_description}
@see (links_or_references)
/*/
User Function BFCOMV02()

	Local aArea := GetArea()
	Local cProd := M->B1_COD
	Local cArmz := M->B1_LOCPAD
	Local lRet	:= .T.
	
	dbSelectArea("SB2")
	dbSetOrder(1)
	If dbSeek(xFilial("SB2") + cProd + cArmz)
		If SB2->B2_QATU != 0
			lRet := .F.
			MsgAlert("Produto possui saldo de " + cValToChar(SB2->B2_QATU) + ", portanto não poderá ser bloqueado. Entre em contato com o setor FISCAL para ajuste.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		EndIf
	EndIF
	
	RestArea(aArea)

Return lRet

