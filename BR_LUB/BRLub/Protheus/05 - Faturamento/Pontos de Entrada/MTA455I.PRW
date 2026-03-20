
/*/{Protheus.doc} MTA455I
(Registrar no Z0 a hora da Liberação de Estoque  )
@author Leonardo J Koerich Jr
@since 27/11/03
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MTA455I()

	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MTA455I")
		Return .T.
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	// Grava Log e pergunta motivo
	U_GMCFGM01("LE",SC9->C9_PEDIDO,,FunName())
	
Return(.T.)
