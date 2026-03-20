#Include 'Protheus.ch'


/*/{Protheus.doc} MT119TOK
Ponto de entrada com objetivo de customizar a validação executada pela função TudoOk da rotina de Despesa de Importação.
@author Iago Luiz Raimondi
@since 28/01/2015
@version 1.0
@return ${lRet}, ${Retorno lógico determinando o resultado da validação customizada para permitir continuar (.T.) ou não permitir (.F.).}
@example
Possibilita validar o total da despesa de importação para que somente seja gerada se for inferior a R$200,00.
@see http://tdn.totvs.com/pages/releaseview.action?pageId=6085705
/*/
User Function MT119TOK()

	Local lRet := .T.

	If ExistBlock("MT103DNF")
		lRet := ExecBlock("MT103DNF",.F.,.F.,{aNFEDanfe})
	Endif

Return lRet

