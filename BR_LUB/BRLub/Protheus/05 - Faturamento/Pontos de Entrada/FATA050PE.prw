#include 'totvs.ch'
#include 'parmtype.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} FATA050
PE modelo MVC da rotina de cadastro de Metas de Vendas
@type function
@version 12.1.25
@author ICMAIS
@since 04/03/2021
@return variadic, xRet
/*/
User Function FATA050()
	
	Local aParam    := PARAMIXB
	Local xRet      := .T.
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)  
	
	// Verifica se conseguiu receber valor do PARAMIXB
	If aParam <> NIL

		// Manter o trexo de código a seguir no final do fonte
		if lPEICMAIS
			xRet := ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
		EndIf
		
	EndIf
	
Return ( xRet )
