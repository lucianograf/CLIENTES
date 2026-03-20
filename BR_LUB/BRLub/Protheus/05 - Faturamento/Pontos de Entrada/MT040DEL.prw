#include 'totvs.ch'

/*/{Protheus.doc} MT040DEL
PE executado após deleção de um cadastro de vendedor
@type function
@version 12.1.25
@author ICMAIS
@since 26/09/2020
@return return_type, Nil
/*/
User Function MT040DEL()
	
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.) 

	// Manter o trexo de código a seguir no final do fonte
	if lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., Nil )
	EndIf
	
Return ( Nil )
