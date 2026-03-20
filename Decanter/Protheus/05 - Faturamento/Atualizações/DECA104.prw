
/*/{Protheus.doc} DECA104
Função para retornar prefixo de títulos na integração do Loja - Usado no parâemtro MV_LJPREF 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/12/2021
@return variant, return_description
/*/
User Function DECA104()

	Local   cRetPref    := If(Empty(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE)
	Local   aAreaOld    := GetArea()


	If cEmpAnt == "01" //.And. SL1->L1_CLIENTE == '03558806'
        //SELECT DISTINCT L1_SERIE,L1_FILIAL  FROM SL1010  WHERE L1_DOC <>  ' ' 
		//0101	CF1
		//0101	CF2
		//0101	CF3
		//0101	CF4
		//0102	CF1
		//0102	CF2
		//0103	CF1
		//0103	CF2
        
        // cRetPref -> "C" + Final da série do Cupom + Final da Filial 
		If SL1->L1_FILIAL == "0101"
			If SL1->L1_SERIE == 'CF1'
				cRetPref    := 'C11' // C11
			ElseIf SL1->L1_SERIE == "CF2"
				cRetPref    := 'C21' // C12
			ElseIf SL1->L1_SERIE == "CF3"
				cRetPref    := 'C31' // C13
			ElseIf SL1->L1_SERIE == "CF4"
				cRetPref    := 'C41' // C14
			Endif
		ElseIf SL1->L1_FILIAL == "0102"
			If SL1->L1_SERIE == 'CF1'
				cRetPref    := 'C12' // C21
			ElseIf SL1->L1_SERIE == "CF2"
				cRetPref    := 'C22' // C22 
			Endif
		ElseIf SL1->L1_FILIAL == "0103"
			If SL1->L1_SERIE == 'CF1'
				cRetPref    := 'C13' // C31
			ElseIf SL1->L1_SERIE == "CF2"
				cRetPref    := 'C23' // C32
			Endif
		Endif
	Else
		cRetPref    := If(Empty(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE)
	Endif

	RestArea(aAreaOld)

Return cRetPref
