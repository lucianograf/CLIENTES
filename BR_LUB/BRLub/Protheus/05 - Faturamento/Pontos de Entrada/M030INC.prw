#include 'totvs.ch'

/*/{Protheus.doc} M030INC
PE executado após inclusão de um cliente quando a rotina não utiliza modelo MVC
@type function
@version 12.1.25
@author ICMAIS
@since 26/09/2019
@return return_type, Nil
/*/
User Function M030INC()
	
	Local aParam    := PARAMIXB
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall )  .And. GetNewPar("BL_ICMAIOK",.F.)

	// Manter o trexo de código a seguir no final do fonte
	If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
	EndIf
	
Return ( Nil )
