
/*/{Protheus.doc} TMKVOK
(Ponto de entrada ao confirmar Televendas)
@author MarceloLauschner
@since 09/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function TMKVOK()
	
	Local 	aAreaOld	:= GetArea()
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	// Movido para o PE TMKVFIM 
	/*DbSelectArea("SUA")
	// Se for Orçamento
	If	M->UA_OPER == "2"
		U_WFTMKORC()
	//	Se for Faturamento
	ElseIf	M->UA_OPER == "1"
		U_WFTMKPED()
	EndIf
	*/	
	// Grava data limite
	RecLock("SUA",.F.)
	SUA->UA_DTLIM := M->UA_DTLIM
	MsUnlock()
	
	RestArea(aAreaOld)
	
Return
