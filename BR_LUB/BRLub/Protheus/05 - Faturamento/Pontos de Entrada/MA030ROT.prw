#include 'totvs.ch'
#Include "FWMVCDef.ch"


//====================================================================================================================\\

/*/{Protheus.doc} MA030ROT
@description
INCLUSÃO DE NOVAS ROTINAS
Após a criação do aRotina, para adicionar novas rotinas ao programa.
Para adicionar mais rotinas, adicionar mais subarrays ao array. No advanced este número é limitado.
Deve se retornar um array onde cada subarray é uma linha a ser adicionada ao aRotina padrão.

@author		Lucas Farias
@since		18 de abril de 2017
@version	1.0
@return		aRetorno, Array, retorna o array com menu de funções adicionais.
/*/
//====================================================================================================================\\

//User Function MA030ROT()
User Function CRM980MDef()
	Local aRetorno := {}

	If RetCodUsr() $ GetNewPar("BF_A030ROT","000204#000130#000402#000349#000307") // Jonathan/Marcelo/Matheus/Viviane/Iago
		AAdd( aRetorno, { "Potencial Vendas", "U_ATFATA01(SA1->A1_COD,SA1->A1_LOJA)", MODEL_OPERATION_VIEW, 0 } )
		AAdd( aRetorno, { "Importar Potencial", "U_ATFATX01()", MODEL_OPERATION_VIEW, 0 } )
	ElseIf  RetCodUsr() $ GetMv("BF_USRSERA") // Usuário perfil Financeiro - Acessar alguns campos específicos
		AAdd( aRetorno, { "Alteração Financeira", "VIEWDEF.BFFATA66", MODEL_OPERATION_VIEW, 0 } )
	Endif

	// Efetua verificação se o SX3 está correto
	sfCheckX3()


Return aRetorno


User Function MA030ROT()

	Local aRetorno := {}

	If RetCodUsr() $ GetNewPar("BF_A030ROT","000204#000130#000402#000349#000307") // Jonathan/Marcelo/Matheus/Viviane/Iago
		AAdd( aRetorno, { "Potencial Vendas", "U_ATFATA01(SA1->A1_COD,SA1->A1_LOJA)", 2, 0 } )
		AAdd( aRetorno, { "Importar Potencial", "U_ATFATX01()", 2, 0 } )
	ElseIf  RetCodUsr() $ GetMv("BF_USRSERA") // Usuário perfil Financeiro - Acessar alguns campos específicos
		AAdd( aRetorno, { "Alteração Financeira", "VIEWDEF.BFFATA66", 2, 0 } )
	Endif
	// Efetua verificação se o SX3 está correto
	sfCheckX3()


Return aRetorno


/*/{Protheus.doc} sfCheckX3
// Função para deixar o campo X3_VALID do A1_CGC ajustado para sempre forçar o ajuste da validação
@author Marcelo Alberto Lauschner
@since 10/05/2019
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfCheckX3()

	Local	aAreaSX3	:= SX3->(GetArea())
	Local	cVldSX3A1	:= ""
	Local	nX

	//DbSelectArea("SX3")
	//DbSetOrder(2)
	//DbSeek("A1_CGC")
	cCampo := "A1_CGC"
	cVldSX3A1	:= GetSX3Cache(cCampo, "X3_VALID") 

	// Verifica se a validação SX3 está ajustada para a Customização da Empresa
	//Vazio() .Or. IIF( M->A1_TIPO == "X", .T., (CGC(M->A1_CGC) .And. U_A030CGC(M->A1_PESSOA, M->A1_CGC) .And. A030VldUCod() ))
	//If !("U_A030CGC" $ cVldSX3A1) .And. ("A030CGC" $ cVldSX3A1)
	//	cVldSX3A1	:= StrTran(cVldSX3A1,"A030CGC","U_A030CGC")
	//	DbSelectArea("SX3")
	//	DbSetOrder(2)
	//	DbSeek("A1_CGC")
	//	RecLock("SX3",.F.)
	//	SX3->X3_VALID	:= cVldSX3A1
	//	MsUnlock()
	//Endif

	//Vazio() .Or. IIF( M->A2_TIPO == 'X', .T., (CGC(M->A2_CGC) .And. U_A020CGC(M->A2_TIPO, M->A2_CGC) .And. A020VldUCod()))

	//DbSelectArea("SX3")
	//DbSetOrder(2)
	//DbSeek("A2_CGC")
	cCampo := "A2_CGC"
	cVldSX3A1	:= GetSX3Cache(cCampo, "X3_VALID") 

	// Verifica se a validação SX3 está ajustada para a Customização da Empresa
	//Vazio() .Or. IIF( M->A2_TIPO == 'X', .T., (CGC(M->A2_CGC) .And. U_A020CGC(M->A2_TIPO, M->A2_CGC) .And. A020VldUCod()))
	//If !("U_A020CGC" $ cVldSX3A1) .And. ("A020CGC" $ cVldSX3A1)
	//	cVldSX3A1	:= StrTran(cVldSX3A1,"A020CGC","U_A020CGC")
	//	DbSelectArea("SX3")
	//	DbSetOrder(2)
	//	DbSeek("A2_CGC")
	//	RecLock("SX3",.F.)
	//	SX3->X3_VALID	:= cVldSX3A1
	//	MsUnlock()
	//Endif

	/*
	For nX := 1 To 7
		DbSelectArea("SX3")
		DbSetOrder(2)
		DbSeek("A1_SATIV"+cValToChar(nx))
		cVldSX3A1	:= SX3->X3_PICTURE

		If !("@!" $ cVldSX3A1)
			cVldSX3A1	:= "@!"
			DbSelectArea("SX3")
			DbSetOrder(2)
			DbSeek("A1_SATIV"+cValToChar(nx))
			RecLock("SX3",.F.)
			SX3->X3_PICTURE	:= cVldSX3A1
			MsUnlock()
		Endif
	Next nX
	*/

	RestArea(aAreaSX3)

Return

