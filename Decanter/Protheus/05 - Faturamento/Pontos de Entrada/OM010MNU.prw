/*/{Protheus.doc} OM010MNU
Ponto de entrada para adicionar botões na rotina de Preços de Venda - OMSA010 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 10/11/2020
@return return_type, return_description
/*/
User Function OM010MNU()

	Aadd(aRotina,{ OemToAnsi("Importar CSV"),"U_MLFATM01"			    ,0,         4			,32,NIL})

	Aadd(aRotina,{ OemToAnsi("Reajuste em Lotes"),"U_MLFATA15"			,0,         4			,33,NIL})

Return
