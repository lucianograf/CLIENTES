/*/{Protheus.doc} A020CGC
(Validacao de Cnpj e alteração automatica para loja correta)
@author MarceloLauschner
@since 15/01/2013
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function A020CGC()
	
	Local	aAreaOld	:= SA2->(GetArea())
	Local	cCNPJ   	:= M->A2_CGC
	Local	cA2_COD		:= M->A2_COD
	Local	cA2_LOJA	:= M->A2_LOJA
	Local	cCGCBAse
	Local	nLoja
	Local	lForceSA2	:= .F.
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	// Forço atualização para Juridica se o numero de digitos for maior que 11
	If Len(Alltrim(cCNPJ)) > 11
		M->A2_TIPO := "J"
	Else
		M->A2_TIPO := "F"
	Endif
	
	// Forço o ajuste de numeração automatica
	If INCLUI
		DbSelectArea("SA2")
		DbSetOrder(1)
		Do While .T.
			If !dbSeek( xFilial( "SA2" ) + cA2_COD +cA2_LOJA )
				If lForceSA2
					RollBackSX8()
				Endif
				Exit
			EndIf
			lForceSA2	:= .T.
			cA2_COD		:= GetSXENum("SA2","A2_COD")
			If __lSx8
				ConfirmSx8()
			EndIf
		EndDo
	Endif
	
	
	If M->A2_TIPO == "J" .And. INCLUI
		cA2_LOJA	:= SubStr(cCNPJ,9,4)
		nLoja		:= Val(cA2_LOJA)
		// Faço controle se o numero da loja for maior que 100, ajusta pelo Microsiga
		If nLoja >= 100
			cA2_LOJA	:= "99"
			For iW := 1 To (nLoja - 100)
				cA2_LOJA := Soma1(cA2_LOJA)
			Next
		Else
			cA2_LOJA	:= SubStr(cCNPJ,11,2)
		Endif
		cCGCBase := SubStr(cCNPJ,1,8)
		DbSelectArea("SA2")
		DbSetOrder(3)
		If DbSeek(xFilial("SA2")+cCGCBase)
			cA2_COD 	:= SA2->A2_COD
			// Efetua loop para evitar duplicidade de Loja, mesmo que não corresponda a loja do CNPJ
			While .T.
				DbSelectArea("SA2")
				DbSetOrder(1)
				If DbSeek(xFilial("SA2")+cA2_COD+cA2_LOJA)
					cA2_LOJA := Soma1(cA2_LOJA)
				Else
					Exit
				Endif
			Enddo
		Endif
		M->A2_COD 		:= cA2_COD
		M->A2_LOJA 	:= cA2_LOJA
		RestArea(aAreaOld)
	Endif
	
Return A020CGC(M->A2_TIPO, M->A2_CGC)
