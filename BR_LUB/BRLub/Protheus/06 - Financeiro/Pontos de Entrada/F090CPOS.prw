#Include 'Protheus.ch'


/*/{Protheus.doc} F090CPOS
(Ponto de entrada que permite retornar quais campos da tabela SE2 irão aparecer na Baixa Automática)
@type function
@author marce
@since 03/05/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function F090CPOS()

	Local	aCampos		:= ParamIxb
	Local	aRet		:= {}
	Local	iW
	Local	cCpoLib		:= "E2_OK#E2_SALDO#E2_PREFIXO#E2_NUM#E2_PARCELA#E2_FORNECE#E2_LOJA#E2_NOMFOR#E2_EMISSAO#E2_VENCTO#E2_VENCREA#E2_IDCNAB#E2_NUMBOR#E2_BCOPAG#E2_HIST#E2_TIPO#E2_ACRESC#E2_DECRESC#"
	
	For iw	:= 1 To Len(aCampos)
		If Alltrim(aCampos[iW,1]) $ cCpoLib
			Aadd(aRet,aCampos[iW])
		Endif
	Next
	
Return aRet

