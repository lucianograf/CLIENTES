
/*/{Protheus.doc} TMKVHO
(P.E. para impedir carregar orcamento que já gerou pedido )
	
@author MarceloLauschner
@since 28/03/2011
@version 1.0
		
@param cNumPed, character, (Descrição do parâmetro)

@return logico, impede carga do pedido na tela

@example
(examples)

@see (links_or_references)
/*/
User Function TMKVHO(cNumPed)

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.

	DbSelectArea("SUA")
	DbSetOrder(1)
	If Dbseek(xFilial("SUA")+cNumPed)
		If !Empty(SUA->UA_NUMSC5)
			MsgAlert("Este atendimento já se transformou em pedido de venda. Não é mais permitido alterar!","Permissão Negada. 'TMKVHO' ")
			lRet	:= .F.
		Endif
	Endif

	RestArea(aAreaOld)

Return (lRet)
