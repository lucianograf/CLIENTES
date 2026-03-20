#include 'totvs.ch'

/*/{Protheus.doc} MA040DIN
PE executado após a inclusão de um novo cadastro de vendedor
@type function
@version 12.1.25
@author ICMAIS
@since 24/09/2020
@return return_type, Nil
/*/
User Function MA040DIN()
	
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall )  .And. GetNewPar("BL_ICMAIOK",.F.)

	// Manter o trexo de código a seguir no final do fonte
	If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., Nil )
	EndIf

Return ( Nil )
