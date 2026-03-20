#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MA030TOK
//TODO Ponto de Entrada que valida a Inclusão / Alteração / Exclusão de cadastro de clientes
@author Marcelo Alberto Lauschner
@since 11/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MA030TOK()

	Local		lRet		:= .T. 
	Local		aAreaOld	:= GetArea()
	Local 		aSM0		:= FwLoadSM0()
	Local		cFilZ00		:= xFilial("Z00")
	Local 		nX 

	If Empty(cFilZ00)
		// Posiciona na tabela de Controle de integração Agili e força o preenchimento de valores para sincronização
		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA1" + xFilial("SA1") + M->(A1_COD+A1_LOJA))
			RecLock("Z00",.F.)
			Z00->Z00_INTEGR 	:= " "			// - Status Integração
			MsUnlock()
		Endif

	Else
		// Replica alteração para todas as filiais se existir o registro já na Z00
		For nX := 1 To Len(aSM0)

			// Posiciona na tabela de Controle de integração Agili e força o preenchimento de valores para sincronização
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(aSM0[nX,SM0_CODFIL] + "SA1" + xFilial("SA1") + M->(A1_COD+A1_LOJA))
				RecLock("Z00",.F.)
				Z00->Z00_INTEGR 	:= " "			// - Status Integração
				MsUnlock()
			Endif

		Next nX

	Endif

	RestArea(aAreaOld)

Return lRet
