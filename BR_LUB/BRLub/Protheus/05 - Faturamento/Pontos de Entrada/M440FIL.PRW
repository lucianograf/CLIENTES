
/*/{Protheus.doc} M440FIL
( P.E. para filtrar pedidos na Liberação baseado no BIG005)
@author MarceloLauschner
@since 07/04/2013
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M440FIL()
	
	Local	cRet	:= ".T."
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M440FIL")
		Return ".T."
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If Type("cFilNumSC9") <> "U"
		cRet	:= "C5_NUM == '"+cFilNumSC9+"' .And. C5_FILIAL = '"+cFilAnt+"' "
	Endif
	
Return cRet
