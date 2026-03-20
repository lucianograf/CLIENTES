#include "totvs.ch"

User Function DCFATG04(nInOpc) 

    Local	aAreaOld	:= SA1->(GetArea())
	Local	cCNPJ   	:= M->A1_CGC
	Local	cA1_COD		:= M->A1_COD
	Local	cA1_LOJA	:= M->A1_LOJA
	Local	cRetValue	:= ""
	Local	cCGCBAse
	Local	nLoja
	Local	nA1Recno	:= SA1->(Recno())
	Default nInOpc      := 1 // 1-Codigo 2-Loja 
	
	// Forço atualização para Juridica se o numero de digitos for maior que 11
	If Len(Alltrim(cCNPJ)) > 11
		M->A1_PESSOA := "J"
	Else
		M->A1_PESSOA := "F"
	Endif
	
	If M->A1_PESSOA == "J" .And. INCLUI
		cA1_LOJA	:= SubStr(cCNPJ,9,4)
		nLoja		:= Val(cA1_LOJA)
		cCGCBase := SubStr(cCNPJ,1,8)
		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+cCGCBase)
			cA1_COD 	:= SA1->A1_COD
			// Efetua loop para evitar duplicidade de Loja, mesmo que não corresponda a loja do CNPJ
			While .T.
				DbSelectArea("SA1")
				DbSetOrder(1)
				If DbSeek(xFilial("SA1")+cA1_COD+cA1_LOJA)
					cA1_LOJA := Soma1(cA1_LOJA)
				Else
					Exit
				Endif
			Enddo
		Endif
		M->A1_COD 	:= cA1_COD
		M->A1_LOJA 	:= cA1_LOJA
		RestArea(aAreaOld)
		
		DbSelectArea("SA1")
		DbGoto(nA1Recno)
    Elseif M->A1_PESSOA == "F" .And. INCLUI

        cA1_LOJA	:= "9999"
		
		cCGCBase := SubStr(cCNPJ,1,11)
		DbSelectArea("SA1")
		DbSetOrder(3)
		If DbSeek(xFilial("SA1")+cCGCBase)
			cA1_COD 	:= SA1->A1_COD
			// Efetua loop para evitar duplicidade de Loja, mesmo que não corresponda a loja do CNPJ
			While .T.
				DbSelectArea("SA1")
				DbSetOrder(1)
				If DbSeek(xFilial("SA1")+cA1_COD+cA1_LOJA)
					cA1_LOJA := StrZero(Val(cA1_LOJA)-1,4) //Soma1(cA1_LOJA)
				Else
					Exit
				Endif
			Enddo
		Endif
		M->A1_COD 	:= cA1_COD
		M->A1_LOJA 	:= cA1_LOJA
		RestArea(aAreaOld)
		
		DbSelectArea("SA1")
		DbGoto(nA1Recno)
	Endif
	
	If nInOpc == 1
        cRetValue   := cA1_COD
    ElseIf nInOpc == 2 
        cRetValue   := cA1_LOJA
    Endif 
	
Return cRetValue
