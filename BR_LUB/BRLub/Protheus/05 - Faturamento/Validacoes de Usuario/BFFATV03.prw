#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATV03
(Função de validação de edição dos campos de itens do pedido de venda. Validação edição quando for Combo)
@type function
@author marce
@since 19/12/2016
@version 1.0
@return lRet, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATV03()
	
	Local	cReadVar	:= ReadVar()
	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local	nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	Local	nPCodPrd	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local	nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2NUM"})
	Local	nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XPA2LIN"})
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
				lRet	:= .F.
				MsgStop("Não é permitido editar o tipo de saída se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_CF"
				lRet	:= .F.
				MsgStop("Não é permitido editar o código fiscal se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf cReadVar == "M->C6_VALOR"
				lRet	:= .F.
				MsgStop("Não é permitido editar o valor total se o produto é derivado de um Combo!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Endif 
	Else
		If cReadVar == "M->C6_PRODUTO"
			If Substr(M->C6_PRODUTO,1,3) == "CB-" 
				lRet	:= .F.
				MsgStop("Não é permitido digitar o código de produto Combo diretamente neste campo. Você deve selecionar o Combo na função específica!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			// Chamado 24.376 - Valida que usuário não pode trocar o produto durante a digitação 
			ElseIf M->C6_PRODUTO <> aCols[n,nPCodPrd] .And. !Empty(aCols[n,nPxPA2NUM]) .And. aCols[n,nPCodPrd]  $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ") 
				lRet	:= .F.
				MsgStop("Não é permitido alterar o código de produto se o original digitado era um Granel. Você deve deletar este item do pedido e adicionar um novo item em nova linha!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Endif
	Endif
	RestArea(aAreaOld)
Return lRet