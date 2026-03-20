#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------
/*/{Protheus.doc} M460MARK
Ponto de Entrada MVC para a Rotina MATA461.

Utilizado na Lexos para validar se o pedido de venda já foi 
confirmado o pagamento, caso contrário impede o faturamento.

@type function
@version 1.0
@author Gruppe Tecnologia

@return Logical

@see https://tdn.totvs.com/pages/releaseview.action?pageId=6784189
/*/
//-------------------------------------------------

User Function LEXM4MARK()
	Local cMark     := PARAMIXB[1] // MARCA UTILIZADA
	Local lInvert   := PARAMIXB[2] // SELECIONOU "MARCA TODOS"
	Local lRet      := .T.
	Local oFunGenericas
	Local aArea     := GetArea()
	
	oFunGenericas := LexosFnGenericas():New()
	lRet := oFunGenericas:ValidaPagamentoM460MARK(cMark)

	RestArea(aArea)

Return lRet
