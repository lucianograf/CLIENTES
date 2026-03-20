#include 'totvs.ch'

/*/{Protheus.doc} FT050MNU
PE para adição de novos botões na rotina de cadastro de metas de venda
@type function
@version 12.1.25
@author ICMAIS
@since 26/09/2019
@return array, aNewBtn
/*/
User Function FT050MNU()
	
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)
    local aRet      := {} 

    // Valida existência do PE ICmais antes de realizar a chamada
	If lPEICMAIS
		aRet := ExecBlock( 'T'+ cFunCall, .F., .F.,Nil )
	EndIf
	
Return ( aRet )
