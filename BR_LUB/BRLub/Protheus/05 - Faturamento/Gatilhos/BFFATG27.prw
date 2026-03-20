#INCLUDE "rwmake.ch"

/*/{Protheus.doc} BFFATG27
(Gatilho ao digitar código de produto em pedido de venda)
@author MarceloLauschner
@since 26/01/2015
@version 1.0
@return Número, Quantidade em estoque caso seja produto promocional ou queima de estoque
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATG27()
	
	Local	cProduto	:= Space(15)
	Local	nEstoque 	:= 0
	Local	cSts     	:= Space(1)
	Local	cBlq     	:= Space(1)
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If !Type("M->C6_PRODUTO") == "C"
		Return(0)
	Endif
	
	cProduto    := M->C6_PRODUTO
	
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+cProduto)
	
	cSts  := SB1->B1_STS
	cBlq  := SB1->B1_BLOQFAT
	
	DbSelectArea("SB2")
	DbSetOrder(1)
	DbSeek(xFilial("SB2")+cProduto+SB1->B1_LOCPAD)
	
	// Se for execauto não executa gatilho
	If IsBlind()
		nEstoque := 0
	ElseIf cBlq $ "N# " // Se for Normal
		nEstoque := 0
		If cSts == "F"
			If (SB2->B2_QATU - SB2->B2_RESERVA) == 0
				MsgInfo("Produto fora de linha sem estoque.Favor avisar cliente!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
			Else
				nEstoque := (SB2->B2_QATU - SB2->B2_RESERVA)
				MsgInfo("Produto fora de linha com quantidade disponível para venda conforme quantidade preenchida no campo Quantidade!!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
			Endif
		Endif
	Elseif cBlq == "P" // Se Promocional
		If cSts == "F"
			nEstoque := (SB2->B2_QATU - SB2->B2_RESERVA)
			MsgInfo("Produto promocional e fora de linha com estoque disponível para venda conforme quantidade preenchida no campo Quantidade!!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
		Endif
	Elseif cBlq == "Q"
		nEstoque := (SB2->B2_QATU - SB2->B2_RESERVA)
		If cSts <> "F"
			If nEstoque == 0
				MsgInfo("Produto de queima sem estoque.Favor avisar cliente!","Informação")
			Else
				MsgInfo("Produto de queima de estoque com quantidade disponível para venda conforme quantidade preenchida no campo Quantidade!!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
			Endif
		Else
			If nEstoque == 0
				MsgInfo("Produto de queima e fora de linha sem estoque.Favor avisar cliente!","Informação")
			Else
				MsgInfo("Produto de queima de estoque e fora de linha com quantidade disponível para venda conforme quantidade preenchida no campo Quantidade!!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
			Endif
		Endif
	Endif
	
	// Trecho adicionado em 14/08/2010 por Marcelo Lauschner
	// Para corrigir erro de troca de TES que acontece no DIS045.PRW, que altera o código da TES, porém não executa a trigger para atualizar os demais campos
	// dependentes do que vem da informação do c6_tes
	// Posiciona o Tes antes do gatilho
	SF4->(dbSeek(xFilial("SF4")+aCols[n,aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})]))
	If ExistTrigger("C6_TES    ")
		RunTrigger(2,n,,,"C6_TES    ")
	EndIf
	
Return(nEstoque)
