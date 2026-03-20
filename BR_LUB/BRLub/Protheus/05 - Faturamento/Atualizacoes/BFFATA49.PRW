#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


User Function BIG047()
	
Return U_BFFATA49()


/*/{Protheus.doc} BFFATA49
(Auxilia Cadastro de Tabela de Valores de tampas )
@author Marcelo Lauschner
@since 07/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA49()
	
	Private cCadastro := "Manutenção Pagamento Promoções"
	
	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2}  ,;
		{"Incluir","AxInclui",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5},;
		{"Relatorio","U_BFFATR49()",0,2}}
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	DbSelectArea("SZA")
	DbSetOrder(1)
	
	DbSelectArea("SZA")
	
	mBrowse( 6,1,22,75,"SZA")
	
Return


   