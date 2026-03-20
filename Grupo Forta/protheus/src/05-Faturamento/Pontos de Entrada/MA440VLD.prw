#include 'protheus.ch'

/*/{Protheus.doc} MA440VLD
// Ponto de Entrada que valida venda em clientes com restrições
@author Rafaek Meyer
@since 11/04/2021
@version 1.0
@return
@type User Function
/*/
User Function MA440VLD()

	Local nPOSPRODUTO 	:= aSCAN(aHEADER,{|x| UPPER(ALLTRIM(x[2])) == "C6_PRODUTO"})
	Local nPOSTES 	 	:= aSCAN(aHEADER,{|x| UPPER(ALLTRIM(x[2])) == "C6_TES"})
	Local i
	Local lRet 			:= .T.
	Local cTesBlqSol 	:= GetNewPar("GF_TSBLQSL","ZZZ") 	// Informar os TES que devem ser validados se precisa mudar o tipo de cliente no pedido para calcular difal

	// Tipos de pedidos - somente Normais
	If SC5->C5_TIPO == "N"

		// Percorre os itens
		For I := 1 To Len(aCOLS)

			SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+aCols[I,nPOSPRODUTO]))

			// 19/12/2022 - Verifica na empresa 03 se o tipo de Pedido não for S-Solidário
			DbSelectArea("SF4")
			DbSetOrder(1)
			If DbSeek(xFilial("SF4")+aCols[i,nPOSTES])
				If SF4->F4_CODIGO $ cTesBlqSol
					MsgAlert("Tipo de Pedido não está configurado como S-Solidário sendo que o TES '"+Alltrim(SF4->F4_CODIGO)+ " que está incluso no parâmetro 'GF_TSBLQSL' obriga que o pedido seja configurado desta forma. Produto '" + Alltrim(SB1->B1_COD) + "'. Revise a configuração do pedido de Venda - MA440VLD ")
					lRet:= .F.
				Endif
			Endif
		Next

		// 04/11/2021 - Valida se o tipo de cliente no pedido é correspondente ao tipo de cliente no cadastro e não for como Solidário o pedido
		If SC5->C5_TIPOCLI <> SA1->A1_TIPO .And. SC5->C5_TIPOCLI <> "S"
			MsgAlert("O tipo de cliente no Pedido está como '" + SC5->C5_TIPOCLI + "' porém consta no cadastro do cliente como '" + SA1->A1_TIPO + "'. Para liberar o pedido é necessário voltar na alteração do pedido de venda e corrigir o tipo de cliente!","A T E N Ç Ã O!! - MA440VLD")
			lRet 	:= .F.
		Endif

		// 04/11/2021 - Verifica se é na empresa Forta Tech - Cliente SC - Com IE e não Isento
		If cFilAnt == "0101" .And. SA1->A1_EST == "SC" .And. (!"ISENT" $ SA1->A1_INSCR .And. !Empty(SA1->A1_INSCR))
			lRet 	:=	MsgYesNo("Cliente de SC com Inscrição Estadual. Verifique se a venda deve ocorrer mesmo por esta Empresa/Filial!","A T E N Ç Ã O!! - MA440VLD")
		Endif
	Endif

Return lRet
