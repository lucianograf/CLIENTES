#include 'totvs.ch'
#include 'parmtype.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} FATA110
PE modelo MVC da rotina Grupo de Vendas
@type function
@version 12.1.25
@author ICMAIS
@since 19/09/2019
@return variadic, xRet
/*/
User Function FATA110()
	
	Local aParam    := PARAMIXB
	Local xRet      := .T.
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall )  .And. GetNewPar("BL_ICMAIOK",.F.)
	
	// Verifica se conseguiu receber valor do PARAMIXB
	If aParam <> NIL

		// Manter o trexo de código a seguir no final do fonte
		If lPEICMAIS
			xRet := ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
		EndIf
		
	EndIf
	
Return ( xRet )
