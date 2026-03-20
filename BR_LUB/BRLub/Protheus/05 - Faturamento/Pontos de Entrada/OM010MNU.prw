#include 'totvs.ch'

/*/{Protheus.doc} OM010MNU
PE para adicionar novos botões à rotina de tabela de preços
@type function
@version 12.1.25
@author ICMAIS
@since 21/09/2020
@return array, aBotoes
/*/
User Function OM010MNU()
    
    local aArea     := GetArea()
    local cFunCall  := SubStr(ProcName(0),3)
	local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)

    If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., Nil )
	EndIf

    restArea( aArea )

Return ( Nil )
