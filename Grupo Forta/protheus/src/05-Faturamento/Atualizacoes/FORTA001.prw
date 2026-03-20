#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} FORTA001
Valida preco lista ao alterar condição de pagamento e tabela de preço.
Tela de Pedidos de Venda e Orçamento.

Validação de usuário nos campos C5_CONDPAG e C5_TABELA.

@author TSCB57 - WILLIAM FARIAS
@since 31/07/2019
@version 1.0
@return logic
/*/
User Function FORTA001()

	Local aArea		:= GetArea()
	Local lRet		:= .T.
	Local nX
	Local cCondPag
	Local cCodTab
	Local cBanco
	Local nValFatFin	:= 1
	Local nValVend		:= 0
	Local nPrUnit

	//Pedido de Venda
	If FWIsInCallStack("A410Inclui") .Or. FWIsInCallStack("A410Altera")
		
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

		nX := 0
		For nX := 1 to len(aCols)
			cCodProd	:= GDFieldGet("C6_PRODUTO"	, nX) 
			If !Empty(cCodProd)
				nValVend		:= MaTabPrVen(cCodTab,cCodProd,1,cCliente,cLoja,1,date())
				nPrUnit	:= nValVend * nValFatFin
				GDFieldPut("C6_PRUNIT", nPrUnit, nX)
			EndIf
		Next

	EndIf
	
	//Orçamento
//	If FWIsInCallStack("A415Inclui") .Or. FWIsInCallStack("A415Altera")
//
//		cCondPag	:= M->CJ_CONDPAG
//		cCodTab		:= M->CJ_TABELA
//		cCliente	:= M->CJ_CLIENTE
//		cLoja		:= M->CJ_LOJA
//
//		dbSelectArea("SE4")
//		dbSetOrder(1)
//		If dbSeek(FwxFilial("SE4")+cCondPag)
//			nValFatFin := SE4->E4_ZFATFIN
//		EndIf
//		If !Empty(cCodTab)
//			nX := 0
//			For nX := 1 to len(aCols)
//				cCodProd	:= GDFieldGet("CK_PRODUTO"	, nX) 
//				If !Empty(cCodProd)
//					nValVend		:= MaTabPrVen(cCodTab,cCodProd,1,cCliente,cLoja,1,date())
//					//nValorL	:=	FtDescCab(nValor,{SA1->A1_DESC,SA1->A1_ZDESMKT,0,nDescCondPg,0},1) 	
//					nPrUnit	:= nValVend * nValFatFin
//					GDFieldPut("CK_PRUNIT", nPrUnit, nX)
//				EndIf
//			Next
//		EndIf
//	EndIf
	RestArea(aArea)

Return lRet