#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} MT100GE2

Localização.: Function A103AtuSE2 - Rotina que efetua a integração entre o documento de entrada e os títulos financeiros a pagar,após a gravação de cada parcela.
Finalidade...: Complementar a gravação na tabela dos títulos financeiros a pagar.

@author charles.reitz
@since 28/01/2020
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/

user function MT100GE2()

	If (INCLUI .OR. ALTERA)

		//SE2->(RecLock("SE2",.F.))

		//Grava obsservações informadas no documento de entrada no título gerado para o financeiro
		If Type("cCondicao")=="C" .AND. !Empty(cCondicao)
			SE2->E2_ZCONPAG	:=	cCondicao
		EndIf

		//SE2->(MsUnlock())
	EndIf


return