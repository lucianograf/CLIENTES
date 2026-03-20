#Include 'Protheus.ch'

/*/{Protheus.doc} TMKDADOS
(Ponto de entrada para validar tela de condição de pagamento e transportadora)
@type function
@author marce
@since 21/12/2016
@version 1.0
@param cCodPagto, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TMKDADOS(cCodPagto)
	
	Local	lRet	:= .T.

	If Type("cCondOld") <> "U" .And. cCodPagto <> cCondOld
		MsgAlert("A condição de pagamento foi modificada! Favor manter a condição '"+cCondOld + "'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"Alteração de Condição Pagamento!")		
		Return .F.
	ElseIf Type("M->UA_CONDPG") <> "U" .And. cCodPagto <> M->UA_CONDPG
		MsgAlert("A condição de pagamento foi modificada! Favor manter a condição '"+M->UA_CONDPG + "'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"Alteração de Condição Pagamento!")		
		Return .F.
	Endif

	
Return lRet

