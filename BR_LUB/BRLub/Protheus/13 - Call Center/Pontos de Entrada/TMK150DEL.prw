#include 'protheus.ch'

/*/{Protheus.doc} TMK150DEL
PE ao final da exclusão do pedido ou do orçamento do call center
@type function
@version 1.0
@author ICmais
@since 10/30/2021
/*/
User Function TMK150DEL()

    Local aArea     := GetArea()
    Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.) 
	
	// Manter o trexo de código a seguir no final do fonte
	If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., PARAMIXB )
	EndIf

    RestArea( aArea )

Return Nil
