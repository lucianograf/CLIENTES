/*/{Protheus.doc} MLFATG03
Gatilho pra retornar percentual de comissão do item digitado
@type function
@version  
@author Marcelo Alberto Lauschner
@since 12/05/2022
@param cInProduto, character, param_description
@return variant, return_description
/*/
User Function MLFATG03()

	Local       aAreaOld        := GetArea()
	Local       lVldComis       := GetNewPar("GF_COMISC6",.F.)
	Local       nPrunit         := 0
	Local       nPrcVen         := 0
	Local       cB1ZClCom       := ""
	Local       nPercRet        := 0
    Local       cProduto        := ""

    // Verifica que campo está em edição para pegar os valores de preço de tabela e preço de venda 
    If ReadVar() == "M->C6_PRCVEN"
        nPrcVen     := M->C6_PRCVEN
        nPrunit     := GDFieldGet("C6_PRUNIT",N)
    ElseIf ReadVar() == "M->C6_QTDVEN"
        nPrcVen     := GDFieldGet("C6_PRCVEN",N)
        nPrunit     := GDFieldGet("C6_PRUNIT",N)
    Endif 
    cProduto        := GDFieldGet("C6_PRODUTO",N)

	DbSelectArea("SB1")
	DbSetOrder(1)
	If DbSeek(xFilial("SB1")+cProduto) .And. lVldComis

		cB1ZClCom   := SB1->B1_ZCLCOM

		If (100-( nPrcVen / nPrunit * 100 ))  <= 3  // SE O DESCONTO FOR MENOR QUE 3%
			If cB1ZClCom == 'A'
				nPercRet    := 10
			ElseIf cB1ZClCom == 'B'
				nPercRet    := 7.5
			ElseIf cB1ZClCom == 'C'
				nPercRet    := 5
			Else
				nPercRet    := 0
			Endif

		ElseIf  (100-( nPrcVen / nPrunit * 100 )) <= 4 // ENTRE 3 E 4%
			If cB1ZClCom == 'A'
				nPercRet    := 8
			ElseIf cB1ZClCom == 'B'
				nPercRet    := 5
			ElseIf cB1ZClCom == 'C'
				nPercRet    := 4
			Else
				nPercRet    := 0
			Endif
		ElseIf  (100-( nPrcVen / nPrunit * 100 )) <= 5 // ENTRE 4 E 5%
			If cB1ZClCom == 'A'
				nPercRet    := 6
			ElseIf cB1ZClCom == 'B'
				nPercRet    := 4
			ElseIf cB1ZClCom == 'C'
				nPercRet    := 3
			Else
				nPercRet    := 0
			Endif

		Else
			If cB1ZClCom == 'A'
				nPercRet    := 4
			ElseIf cB1ZClCom == 'B'
				nPercRet    := 3
			ElseIf cB1ZClCom == 'C'
				nPercRet    := 2
			Else
				nPercRet    := 0
			Endif
		Endif
	Endif
	RestArea(aAreaOld)

Return nPercRet
