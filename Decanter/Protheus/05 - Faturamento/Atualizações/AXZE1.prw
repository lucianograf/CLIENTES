
#include "rwmake.ch"
#include "protheus.ch"

/*/{Protheus.doc} AXZE1
Rotina de Cadastro de NSU 
@type function
@version  
@author 
@since 8/24/2023
@return variant, return_description
/*/
User Function AXZE1()
	
	cAlias := "ZE1"
	chkFile(cAlias)
	dbSelectArea(cAlias)
	dbSetOrder(1)
	private cCadastro := "NSU"


	cDelFunc  := ".T."

	aRotina := {;
		{ "Pesquisar", "AxPesqui", 0, 1},;
		{ "Visualizar", "AxVisual", 0, 2},;
		{ "Incluir", "AxInclui", 0, 3},;
		{ "Alterar", "AxAltera", 0, 4},;
		{ "Exlcuir", "AxDeleta", 0, 5};
		}

	dbSelectArea(cAlias)
	mBrowse( 6, 1, 22, 75, cAlias)

return
