#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} FORTA002
Validação do preço lista.
Tela de Pedidos de Venda e Orçamento.

Validação de usuário nos campos C6_PRODUTO e C6_QTDVEN.

@author TSCB57 - WILLIAM FARIAS
@since 31/07/2019
@version 1.0
@return logic
/*/
User Function FORTA002()

	Local aArea		:= GetArea()
	Local lRet		:= .T.
	Local nValFatFin	:= 1 //Fator
	Local nValVend		:= 0
	Local cBanco
	Local nPrUnit
	Local cCondPag
	Local cCodTab
	Local	nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	
	// Se a linha for derivada de Combo
	If nPRegBnf > 0 .And. !Empty(aCols[n][nPRegBnf])
		lRet	:= .F. 
	ElseIf ( FWIsInCallStack("A410Inclui") .Or. FWIsInCallStack("A410Altera"))
		
		cCondPag	:= M->C5_CONDPAG
		cCodTab		:= M->C5_TABELA
		cCliente	:= M->C5_CLIENTE
		cLoja		:= M->C5_LOJACLI
		cBanco      := M->C5_BANCO
		
		dbSelectArea("SE4")
		dbSetOrder(1)
		If dbSeek(FwxFilial("SE4")+cCondPag)
			If cBanco == "777"
				nValFatFin := 1
			Else 
				nValFatFin := SE4->E4_ZFATFIN
			Endif
		EndIf
		
		cCodProd	:= GDFieldGet("C6_PRODUTO"	, N) 
		If Empty(cCodProd)
			cCodProd := M->C6_PRODUTO
		EndIf
		
		If !Empty(cCodProd)
			nValVend	:= MaTabPrVen(cCodTab,cCodProd,1,cCliente,cLoja,1,date())
			nPrUnit		:= nValVend * nValFatFin
			GDFieldPut("C6_PRUNIT", nPrUnit, N)
		EndIf
	
	EndIf
	
	
	RestArea(aArea)
		
Return lRet
