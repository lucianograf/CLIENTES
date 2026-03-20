
/*/{Protheus.doc} A030CGC
(Validacao de Cnpj e alteração automatica para loja correta)
@author MarceloLauschner
@since 10/09/2010
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function A030CGC()
	
	Local	aAreaOld	:= SA1->(GetArea())
	Local	cCNPJ   	:= M->A1_CGC
	Local	cA1_COD		:= M->A1_COD
	Local	cA1_LOJA	:= M->A1_LOJA
	Local	lRet		:= .T.
	Local  	nBkModulo	:= nModulo
	Local	cCGCBAse
	Local	nLoja
	Local	nA1Recno	:= SA1->(Recno())
	Local 	iW 
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	// Forço atualização para Juridica se o numero de digitos for maior que 11
	If Len(Alltrim(cCNPJ)) > 11
		M->A1_PESSOA := "J"
	Else
		M->A1_PESSOA := "F"
	Endif
	
	If M->A1_PESSOA == "J" .And. INCLUI
		cA1_LOJA	:= SubStr(cCNPJ,9,4)
		nLoja		:= Val(cA1_LOJA)
		// Faço controle se o numero da loja for maior que 100, ajusta pelo Microsiga
		If nLoja >= 100
			cA1_LOJA	:= "99"
			For iW := 1 To (nLoja - 100)
				cA1_LOJA := Soma1(cA1_LOJA)
			Next
		Else
			cA1_LOJA	:= SubStr(cCNPJ,11,2)
		Endif
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
	Endif
	
	nModulo := 6  // Alteramos o módulo durante a inclusão do cliente para que ele não valide através do parâmetro MV_TMKVCGC, impedindo incluir um cliente cujo CNPJ já existe no cadastro de prospect.
	lRet := A030CGC(M->A1_PESSOA, M->A1_CGC)
	
	nModulo := nBkModulo
	
Return lRet
