#include "totvs.ch"


/*/{Protheus.doc} BFFATM17
(Validar digitação de Armazens no CallCenter e Pedido Venda)
	
@author MarceloLauschner
@since 31/05/2012
@version 1.0		

@return logico, centro de custo e conta contábil

@example
(examples)

@see (links_or_references)
/*/
User Function BFFATM17()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local	nPxCampo	:= 0
	Local	cValAtu		:= ""
	Local	lAlter		:= .F.				// Altera local em todos os itens?
	Local	iX


	If ReadVar() == "M->C7_CONTA"
		nPxCampo	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C7_CONTA"})
		cValAtu		:= M->C7_CONTA
	ElseIf ReadVar() == "M->C7_CC"
		nPxCampo	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C7_CC"})
		cValAtu		:= M->C7_CC
	Else
		RestArea(aAreaOld)
	Return lRet
	Endif

	For iX := 1 To Len(aCols)
		If !aCols[iX,Len(aHeader)+1]
			If cValAtu <> aCols[iX,nPxCampo] .And. iX # n
				lAlter	:= .T.
				Exit
			Endif
		Endif
	Next

	If lAlter
		If MsgYesNo("O valor digitado é diferente do valor contido nas outras linhas! Deseja replicar o novo valor para os demais?","Valor diferente do padrão!")
			For iX := 1 To Len(aCols)
				If  !aCols[iX,Len(aHeader)+1] .And. iX # n
					aCols[iX,nPxCampo]	:= cValAtu
				Endif
			Next
		Else
			lRet	:= .T.
		Endif
	Endif

	RestArea(aAreaOld)

Return lRet

