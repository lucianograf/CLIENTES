#include 'totvs.ch'
/*/{Protheus.doc} DECG001
Recalcular o preço de venda com base no campo customizado de desconto
@author charles.totvs
@since 07/01/2020
@version undefined
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function DECV001()

	Local nPrcLista	:= 0
	Local nQteVen	:= 0
	Local nY
	Local nPrcDesc
	Local nBk


	// Item
	If Alltrim(ReadVar())=="M->C6_ZDESITE"
		nPerDesc	:= M->C6_ZDESITE
		nPrcLista	:= GdFieldGet("C6_PRUNIT")

		nPPrcVen	:=	FtDescCab(nPrcLista,{M->C5_DESC1,M->C5_DESC2,M->C5_DESC3,M->C5_DESC4})
		nPrcDesc := a410Arred(nPPrcVen*(1-nPerDesc/100), "C6_PRCVEN")
		GDFieldPut("C6_PRCVEN",nPrcDesc,n)

		M->C6_PRCVEN := nPrcDesc
		cReadAnt := __ReadVar
		__ReadVar := "M->C6_PRCVEN"
		A410MultT(__ReadVar,M->C6_PRCVEN)
		__ReadVar := cReadAnt

		// Efetua Refresh do Rodapé da tela
		If Type('oGetDad:oBrowse')<>"U"
			oGetDad:oBrowse:Refresh()
			Ma410Rodap()
		Endif

	Else // Cabeçalho

		// Salva variável de Linha
		nBk 	:= n

		// Percorre os itens
		For nY := 1 To Len(aCols)
			n	:= nY
			nPerDesc	:= GdFieldGet("C6_ZDESITE",nY)
			nPrcLista	:= GdFieldGet("C6_PRUNIT",nY)
			nQteVen		:= GdFieldGet("C6_QTDVEN",nY)

			nPPrcVen	:=	FtDescCab(nPrcLista,{M->C5_DESC1,M->C5_DESC2,M->C5_DESC3,M->C5_DESC4})
			nPrcDesc	:= 	a410Arred(nPPrcVen*(1-nPerDesc/100), "C6_PRCVEN")

//			MsgAlert("nY: " + cValToChar(nY) + " nPPrcVen: " + cValToChar(nPPrcVen) + " nPrcLista: " + cValToChar(nPrcLista) + " nPerDesc: " + cValToChar(nPerDesc)  + " nPrcDesc: " + cValToChar(nPrcDesc))
			GDFieldPut("C6_PRCVEN",nPrcDesc,nY)

			M->C6_PRCVEN := nPrcDesc
			cReadAnt := __ReadVar
			__ReadVar := "M->C6_PRCVEN"
			A410MultT(__ReadVar,M->C6_PRCVEN)
			__ReadVar := cReadAnt

		Next
		// Restaura posição
		n	:= nBk

		// Efetua Refresh do Rodapé da tela
		If Type('oGetDad:oBrowse')<>"U"
			oGetDad:oBrowse:Refresh()
			Ma410Rodap()
		Endif
	EndIf

Return .T.

/*/{Protheus.doc} U_DCV0001A
Função para calcular o percentual de desconto - Usado em gatilho no campo C6_PRCVEN 
@type function
@version 
@author Marcelo Alberto Lauschner 
@since 17/09/2020
@return return_type, return_description
/*/
Function U_DCV0001A()

	Local	nPrcLista	:= GdFieldGet("C6_PRUNIT")
	Local	nPPrcVen	:= 0
	Local	nPerDesc	:= 0

	// Obtém o preço de venda com os descontos de cabeçalho 
	nPPrcVen	:=	FtDescCab(nPrcLista,{M->C5_DESC1,M->C5_DESC2,M->C5_DESC3,M->C5_DESC4})

	// Calcula o percentual de desconto 
	nPerDesc	:= Round( ( 1 - (M->C6_PRCVEN / nPPrcVen )) * 100 , TamSX3("C6_ZDESITE")[1])
	
	If nPerDesc	<= 0
		nPerDesc 	:= 0
	ElseIf nPerDesc >= 100
		nPerDesc	:= 0
	Endif 

Return nPerDesc
