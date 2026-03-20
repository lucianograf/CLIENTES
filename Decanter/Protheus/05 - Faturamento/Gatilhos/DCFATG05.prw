#include "totvs.ch"
/*/{Protheus.doc} DCFATG05
Gatilho para replicar informação de entidades contábeis no pedido de venda. 
@type function
@version  
@author marcelo
@since 12/22/2022
@return variant, return_description
/*/
User Function DCFATG05()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local	nPxCampo	:= 0
	Local	cValAtu		:= ""
	Local	lAlter		:= .F.				// Altera local em todos os itens?
	Local	iX


	If ReadVar() == "M->C6_CONTA"
		nPxCampo	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_CONTA"})
		cValAtu		:= M->C6_CONTA
	ElseIf ReadVar() == "M->C6_CC"
		nPxCampo	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_CC"})
		cValAtu		:= M->C6_CC
	ElseIf ReadVar() == "M->C6_ITEMCTA"
		nPxCampo	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_ITEMCTA"})
		cValAtu		:= M->C6_ITEMCTA
	ElseIf ReadVar() == "M->C6_CLVL"
		nPxCampo	:= aScan(aHeader,{|x| Alltrim(x[2]) == "C6_CLVL"})
		cValAtu		:= M->C6_CLVL
	Else
		RestArea(aAreaOld)
		Return lRet
	Endif
    
    // Se o campo existir e não for ExecAuto 
	If nPxCampo > 0 .And. !IsBlind() 
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
	Endif

	RestArea(aAreaOld)

Return lRet
