

/*/{Protheus.doc} M455FIL
(Ponto de entrada para filtrar pedido se acionado por outras rotinas)
@author MarceloLauschner
@since 12/12/2010
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M455FIL()
	
	Local cReturn	:= ""
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M455FIL")
		Return ".T."
	Endif	
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If Type("cFilNumSC9") <> "C"
		cFilNumSC9	:= ""
	Endif
	If Type("cFilCliSC9") <> "C"
		cFilCliSC9	:= ""
	Endif
	
	If !Empty(cFilNumSC9) .Or. !Empty(cFilCliSC9)
		cReturn += " SC9->C9_FILIAL=='"+xFilial("SC9")+"'.And."
		cReturn += "(SC9->C9_BLCRED=='  '.And. SC9->C9_BLEST <>'  ') "
		cReturn += " .And. (SC9->C9_PEDIDO == '"+cFilNumSC9+"' .Or. SC9->C9_CLIENTE == '"+cFilCliSC9+"') "
	Endif
	
Return cReturn
