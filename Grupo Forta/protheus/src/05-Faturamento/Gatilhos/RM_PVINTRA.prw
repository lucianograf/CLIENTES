#include 'totvs.ch'
#include "rwmake.ch"

/*/{Protheus.doc} RM_PVINTRA
(Calcula preço de venda liquido para empresas do GrupoForta )

@author Rafael Meyer
@since 14/04/2021
@version 1.0
@return logico,
@example - teste.
(examples)
@see (links_or_references)
/*/
User Function RMPVINTR()

	Local nPrcCust 	:= 0
	Local nPrcVen := 0.00
	Local cProduto := Space(15)
	Local nP

	For nP:=1 to len(aHeader)
		If trim(aHeader[nP][2])=='C6_PRCVEN'
			nPrcVen 	:= aCols[n][nP]
		EndIf
		If trim(aHeader[nP][2])=='C6_PRODUTO'
			cProduto	:= aCols[n][nP]
		EndIf
	Next

	If cFilAnt == '0301' .and. M->C5_TABELA == '999'

		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+cProduto)

		DbSelectArea("SB2")
		DbSetOrder(1)
		DbSeek(xFilial("SB2")+cProduto+SB1->B1_LOCPAD)

		nPrcCust := SB2->B2_CM1

		// SE VENDA PARA FORTA FTA OU BAUME
		If M->C5_CLIENTE == '002410' .or. M->C5_CLIENTE == '016147'  
			If Substr(SB1->B1_POSIPI,1,4) == '2710'
				nPrcVen :=  nPrcCust*1.21
			Elseif Substr(SB1->B1_POSIPI,1,4) == '3403'
				nPrcVen :=  nPrcCust*1.25
			Elseif Substr(SB1->B1_POSIPI,1,4) == '8421'
				nPrcVen :=  nPrcCust*1.209
			Else
				nPrcVen :=  nPrcCust*1.34
			Endif
		Endif

		If M->C5_CLIENTE == '004679' // SE VENDA PARA DISTR FORTA
			If Substr(SB1->B1_POSIPI,1,4) == '8421'
				nPrcVen :=  nPrcCust*1.209
			Else
				nPrcVen :=  nPrcCust*1.34
			Endif			
		Endif
		
		
		// SE VENDA PARA FORTA TECH

		If M->C5_CLIENTE == '000101'
			If Substr(SB1->B1_POSIPI,1,4) == '2710'
				nPrcVen :=  nPrcCust*1.22
			Elseif Substr(SB1->B1_POSIPI,1,4) == '8421'
				nPrcVen :=  nPrcCust*1.209
			Else
				nPrcVen :=  nPrcCust*1.215
			EndIf
		Endif


// se venda para a HMCR4
	ElseIf cFilAnt == '0401' .and. M->C5_CLIENTE == '005961' .and. M->C5_LOJACLI == '02'

		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+cProduto)

		DbSelectArea("SB2")
		DbSetOrder(1)
		DbSeek(xFilial("SB2")+cProduto+'01')

		nPrcCust := SB2->B2_CM1

		If Substr(SB1->B1_POSIPI,1,4) == '4011'
			nPrcVen :=  nPrcCust/0.98
		Else
			nPrcVen :=  nPrcCust*1.235
		EndIf


	ElseIf cFilAnt == '0101' .and. M->C5_TABELA == '999' .and. M->C5_CLIENTE == '000001'

		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+cProduto)

		DbSelectArea("SB2")
		DbSetOrder(1)
		DbSeek(xFilial("SB2")+cProduto+SB1->B1_LOCPAD)

		nPrcCust := SB2->B2_CM1

		nPrcVen :=  nPrcCust * 1.309758

	Endif

return (nPrcVen)
