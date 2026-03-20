#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATV03
(Função de validação de edição dos campos de itens do pedido de venda. Validação edição quando for Combo)
@type function
@author marce
@since 19/12/2016
@version 1.0
/*/
User Function BFFATV03()
	
	Local	cReadVar	:= ReadVar() 
	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local	nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	Local	nPRegUbBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XREGBNF"})
	Local	cRegBoni	:= ""
	
	// Se a linha for derivada de Combo
	If nPRegBnf > 0 .And. !Empty(aCols[n][nPRegBnf])
		cRegBoni	:= Substr(aCols[n][nPRegBnf],1,6)
		// Se o código do combo for válido ( não alterado pela função TMKVDEL que zera o código se o combo foi deletado)
		If cRegBoni <> "XXXXXX"
			If cReadVar == "M->C6_PRODUTO"
				lRet	:= .F.
				MsgStop("Não é permitido editar o código de produto se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_OPER"
				lRet	:= .F.
				MsgStop("Não é permitido editar o tipo de operação se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_QTDVEN"
				lRet	:= .F.
				MsgStop("Não é permitido editar a quantidade se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_XUPRCVE"
				lRet	:= .F.
				MsgStop("Não é permitido editar o preço de venda se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_PRCVEN"
				lRet	:= .F.
				MsgStop("Não é permitido editar o preço de venda se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_VALOR"
				lRet	:= .F.
				MsgStop("Não é permitido editar o valor total do produto se o mesmo é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_DESCONT"
				lRet	:= .F.
				MsgStop("Não é permitido editar o percentual de desconto se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_VALDESC"
				lRet	:= .F.
				MsgStop("Não é permitido editar o valor do desconto se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_TES"
				//lRet	:= .F.
				lRet := MsgNoYes("Não é permitido editar o tipo de saída se o produto é derivado de um Combo! Deseja continuar a edição mesmo assim?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_CF"
				lRet	:= .F.
				MsgStop("Não é permitido editar o código fiscal se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Endif 
	ElseIf nPRegUbBnf > 0 .And. !Empty(aCols[n][nPRegUbBnf])
		cRegBoni	:= Substr(aCols[n][nPRegUbBnf],1,6)
		// Se o código do combo for válido ( não alterado pela função TMKVDEL que zera o código se o combo foi deletado)
		If cRegBoni <> "XXXXXX"
			If cReadVar == "M->UB_PRODUTO"
				lRet	:= .F.
				MsgStop("Não é permitido editar o código de produto se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_OPER"
				lRet	:= .F.
				MsgStop("Não é permitido editar o tipo de operação se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_QUANT"
				lRet	:= .F.
				MsgStop("Não é permitido editar a quantidade se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_XUPRCVE"
				lRet	:= .F.
				MsgStop("Não é permitido editar o preço de venda se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_VRUNIT"
				lRet	:= .F.
				MsgStop("Não é permitido editar o preço de venda se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_VLRITEM"
				lRet	:= .F.
				MsgStop("Não é permitido editar o valor total do produto se o mesmo é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_DESC"
				lRet	:= .F.
				MsgStop("Não é permitido editar o percentual de desconto se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_VALDESC"
				lRet	:= .F.
				MsgStop("Não é permitido editar o valor do desconto se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_TES"
				//lRet	:= .F.
				lRet 	:= MsgNoYes("Não é permitido editar o tipo de saída se o produto é derivado de um Combo! Deseja continuar mesmo assim?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->UB_CF"
				lRet	:= .F.
				MsgStop("Não é permitido editar o código fiscal se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Endif 
	Else
		If cReadVar == "M->C6_PRODUTO"
			If Substr(M->C6_PRODUTO,1,3) == "CB-" 
				lRet	:= .F.
				MsgStop("Não é permitido digitar o código de produto Combo diretamente neste campo. Você deve selecionar o Combo na função específica!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		ElseIf cReadVar == "M->C6_PRODUTO"
			If Substr(M->UB_PRODUTO,1,3) == "CB-" 
				lRet	:= .F.
				MsgStop("Não é permitido digitar o código de produto Combo diretamente neste campo. Você deve selecionar o Combo na função específica!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Endif
	Endif
	RestArea(aAreaOld)
Return lRet
