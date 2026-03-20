#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MTA410
// Ponto de Entrada na confirmação de pedido de venda. 
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return  lRet, Logical , Retorna .T./.f. se o pedido pode ser incluido/alterado
@type User Function
/*/
User function MTA410()

	Local	lRet		:= .T. 
	Local	aAreaOld	:= GetArea()
	Local	cTp			:= "IP"

	DbSelectArea("SZ0")
	DbSetOrder(1)
	If DbSeek(xFilial("SZ0")+M->C5_NUM)
		cTp := 'AP'
	Else
		cTp := 'IP'
	Endif

	// Grava Log generico
	U_MLCFGM01(cTp,M->C5_NUM,,FunName())


Return lRet