#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} BFFATG14
// Validação para executar gatilhos do SA1
@author Marcelo Alberto Lauschner
@since 04/03/2019
@version 1.0
@return Logical - Retorna se o Gatilho deve ser executado ou não
@type function
/*/
User function BFFATG14()
	
	Local	lRet	:= .F. 
	
	// Se for Alteração de cliente e o usuário não estiver no parâmetro de usuários permitidos
	// Retorna .T. para executar o Gatilho dos campos 
	If ALTERA .And. !(RetCodUsr() $ GetNewPar("BF_SA1_USR","000000"))
		// Se o limite de crédito ainda 
		If SA1->A1_LC > 2
			M->A1_VALREMB	:= SA1->A1_LC
		Endif
		lRet	:= .T. 
	Endif
	
Return lRet	