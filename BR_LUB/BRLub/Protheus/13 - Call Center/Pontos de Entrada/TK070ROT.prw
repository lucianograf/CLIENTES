#Include 'Protheus.ch'


/*/{Protheus.doc} TK070ROT
(Adiciona rotina customizada no menu)
@type function
@author Iago Luiz Raimondi
@since 31/03/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function TK070ROT()

	Local aMenu := {}
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	Aadd(aMenu,{"Vincular Cliente*","U_BFTMKM05()",0,6,,.T.})

Return aMenu

	