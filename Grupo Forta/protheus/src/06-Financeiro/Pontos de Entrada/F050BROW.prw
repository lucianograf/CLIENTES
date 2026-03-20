#include "totvs.ch"

/*/{Protheus.doc} F050BROW
(Ponto de Entrada em Rotina FINA050 para adicionar botão )
@author MarceloLauschner
@since 27/05/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function F050BROW()
	//				{ OemToAnsi(STR0002),"FA050Visua", 0 , 2},; //"Visualizar"
	
	Aadd(aRotina, {OemToAnsi("Lançar Cod.Barra"),"U_MLFINA04", 0 , 2})
	
Return
