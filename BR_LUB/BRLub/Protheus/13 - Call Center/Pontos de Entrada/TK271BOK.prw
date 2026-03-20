#Include 'Protheus.ch'

/*/{Protheus.doc} TK271BOK
(long_description)
@type function
@author Iago Luiz Raimondi
@since 26/06/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TK271BOK()

	Local aArea	 := GetArea()
	
	If Type("M->UA_NUM") != "U"
		If IsInCallStack("TMKA380")
			// IAGO 07/07/2017 Chamado(18445)
			If AlLTrim(SU6->U6_CODENT) == M->UA_CLIENTE+M->UA_LOJA .And. Empty(SU6->U6_XCODSUA)
				//SU6 já está posicionado
				dbSelectArea("SU6")
				RecLock("SU6",.F.)
				SU6->U6_XCODSUA := M->UA_NUM
				MsUnLock()
			EndIf
		EndIf
	EndIf
		
	RestArea(aArea)
	
Return

