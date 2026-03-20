#include "totvs.ch"
/*/{Protheus.doc} XMLCTE14
Ponto de entrada Central XML - ajuste de campos para lançamento de CTe
@type function
@version  
@author Marcelo Alberto Lauschner
@since 29/11/2021
@return variant, return_description
/*/
User Function XMLCTE14()

	Local aAreaOld  := GetArea()
	//Local aCabSf1   := ParamIxb[1]
	Local aIteSd1   	:= ParamIxb[2]
	Local lAltNat   	:= .T.
	Local nPosCta   	:= aScan(aIteSd1,{|x| AllTrim(x[1]) == "D1_CONTA"})
	Local nPosNaturez	:= aScan(aCab,{|x| AllTrim(x[1])  == "E2_NATUREZ"})
	Local iD1

	For iD1	:= 1 To Len(aIteSd1)

		nPosCta   := aScan(aIteSd1[iD1],{|x| AllTrim(x[1]) == "D1_CONTA"})

		// Decanter 
		If cEmpAnt == "01"
			// Se a Conta contábil validada no PE XMLCTE09 não for Outras Saídas/Bonificação/Industrialização
			If !(Alltrim(aIteSd1[iD1][nPosCta][2])  $ "410101001#420102037")
				lAltNat	:= .F. 
			Endif
		// HVV
		ElseIf cEmpAnt == "02"
			// Se a Conta contábil validada no PE XMLCTE09 não for Outras Saídas/Bonificação/Industrialização
			If !(Alltrim(aIteSd1[iD1][nPosCta][2])  $ "410101005#410101006#410202008")
				lAltNat	:= .F. 
			Endif
		Endif

		//Iif(cEmpAnt=="01","420102037",Iif(cEmpAnt=="02","410101005","")) // FRETE OUTRAS SAÍDAS/DEMAIS
		//Iif(cEmpAnt=="01","410101001",Iif(cEmpAnt=="02","410101006","")) // FRETE SOBRE BONIFICAÇÃO
		//Iif(cEmpAnt=="01","410101001",Iif(cEmpAnt=="02","410202008","")) // FRETE SOBRE INDUSTRIALIZAÇÃO
		
	Next

	// Só altera a Natureza se nenhuma conta contábil atribuída no PE XMLCTE09 for de Frete sobre vendas. 
	If lAltNat
		If nPosNaturez > 0
			aCab[nPosNaturez,2]	:= "20369"
		Else
			Aadd(aCab,{"E2_NATUREZ"   ,"20369" 		,NIL,NIL})
		Endif
	Endif

	RestArea(aAreaOld)

Return
