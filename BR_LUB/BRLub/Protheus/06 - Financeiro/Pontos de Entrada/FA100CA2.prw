#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} FA100CA2
//TODO Ponto de entrada na Exclusão/Estorno de movimento bancário
@author Marcelo Alberto Lauschner
@since 09/06/2019
@version 1.0
@return lRet, Logical , Retorna .T./.F. se o movimento poderá ser excluído ou estornado
@type User Function
/*/
User function FA100CA2()
	Local	lRet	:= .T.
	Local	nInOpc	:= ParamIxb[1]
	
	If nInOpc == 5 .And. !RetCodUsr() $ GetNewPar("BR_FA100US","000027#000002")  // Se for Exclusão não permitirá movimento pois o sistema não está excluindo o movimento corretamente
		MsgInfo("Não é permitida fazer a exclusão de Movimentos bancários. Use a opção Cancelar, que irá gerar um movimento de Estorno!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		lRet	:= .F. 
	Endif
	
Return lRet
