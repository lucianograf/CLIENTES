
/*/{Protheus.doc} MLFATG02
Gatilho no campo C5_TIPOCLI para ajustar o CFOP dos itens do pedido se houver troca do tipo de cliente. 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 04/11/2021
@return variant, return_description
/*/
User Function MLFATG02()

	Local   aAreaOld        := GetArea()
	Local   lRet            := .T.
	Local 	nPTES	   	    := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})			// Posicao do TES
	Local   lContinua       := .F.
	Local   cTesItem        := ""
	Local 	nBkN			:= N 
	Local   x

	// Verifica se é alteração ou inclusão
	If ALTERA .Or. INCLUI 
		lContinua   := .T.
	Endif

	// Se continua o ajuste
	If lContinua

		lContinua   := .F.
		DbSelectArea("SF4")
		DbSetOrder(1)
		
		For x := 1 To Len(aCols)
			// Pega o valor do TES já informado
			cTesItem    := aCols[x,nPTES]
			// Linhas não deletadas
			If !aCols[x][Len(aHeader)+1] .And. !Empty(cTesItem)
				// Pega o valor do TES já informado
				cTesItem    := aCols[x,nPTES]
				SF4->(DbSeek(xFilial("SF4")+cTesItem))
				M->C6_TES	:= cTesItem 
				n			:= x 
				// Chama função padrão que ajusta o campo do TES e CFOP
				A410MultT("M->C6_TES",cTesItem)
				// Executa gatilhos do TES
				If ExistTrigger("C6_TES    ")
					RunTrigger(2,x,,,"C6_TES    ")                    
				Endif
				lContinua   := .T.
			Endif
		Next
		n 	:= nBkN

		If lContinua
			// Verifica se existe Rodapé para atualizar e dar um Refresh no Getdados
			If Type('oGetDad:oBrowse')<>"U"
				oGetDad:oBrowse:Refresh()
				Ma410Rodap()
			Endif
		Endif

	Endif

	RestArea(aAreaOld)

Return lRet
