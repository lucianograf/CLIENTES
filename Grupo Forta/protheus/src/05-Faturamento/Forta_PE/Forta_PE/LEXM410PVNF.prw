#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"

//-------------------------------------------------
/*/{Protheus.doc} M410PVNF
Ponto de Entrada MVC para a Rotina MATA010.

Utilizado na Lexos para validar se o pedido de venda já foi 
confirmado o pagamento, caso contrário impede o faturamento.

@type function
@version 1.0
@author Gruppe Tecnologia

@return Logical

@see https://tdn.totvs.com/pages/releaseview.action?pageId=6784152
/*/
//-------------------------------------------------

User Function LEXM4PVNF()
Local lRet		:= .t.
Local aArea		:= GetArea()
Local oFunGenericas

oFunGenericas := LexosFnGenericas():New()
lRet := oFunGenericas:ValidaPagamentoM410PVNF()

RestArea(aArea)

Return lRet
