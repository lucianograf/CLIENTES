/*/{Protheus.doc} AUTCLINI
Sincroniza cadastro de clientes e fornecedores com cadastro de classes de valor
@type function
@author Marcelo Alberto Lauschner
@since 24/10/2022
@return variant, Sem retorno 
/*/
User Function AUTCLINI()

	MsAguarde({|lEnd| AtuCad() },"Incluindo classes de Valor","Aguarde, incluindo classes de valor para todos os clientes e fornecedores",.F.)

Return

/*/{Protheus.doc} AtuCad
Inclui nos cadastros de cliente e fornecedor
@type function
@author Marcelo Alberto Lauschner
@since 24/10/2022
@return variant, Sem Retorno
/*/
Static Function AtuCad()
	Local nQtCli:= 0
	Local nQtFor:= 0

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbGoTop()
	while ( SA1->(!Eof()) )
		U_AUTOCLVL( "C", SA1->A1_COD, SA1->A1_LOJA )
		nQtCli++
		SA1->(dbSkip())
	End

	DbSelectArea("SA2")
	DbSetOrder(1)
	DbGoTop()
	while ( SA2->(!Eof()) )
		U_AUTOCLVL( "F", SA2->A2_COD, SA2->A2_LOJA )
		nQtFor++
		SA2->(dbSkip())
	End

	MsgInfo("Sincronização terminada" + CRLF + ;
			cValToChar(nQtCli) + " clientes sincronizados" + CRLF + ;
			cValToChar(nQtFor) + " fornecedores sincronizados","Atualização de Cadastro" )

Return ( Nil )
