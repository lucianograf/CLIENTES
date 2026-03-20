#Include 'Protheus.ch'

/*/{Protheus.doc} TMKACTIVE
(Ponto de entrada na ativação da tela do Callcenter)
@type function
@author marce
@since 22/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TMKACTIVE()
	// Verifica se é Televendas
	If (TkGetTipoAte() $ "245")
		// Verifica se a variável pública já existe e se for diferente o valor dela assume o valor da variável de memória M->UA_CONDPG
		If Type("cCondOld") <> "U" .And. M->UA_CONDPG <> cCondOld
			cCondOld	:= 	M->UA_CONDPG
		Endif
	Endif
Return

