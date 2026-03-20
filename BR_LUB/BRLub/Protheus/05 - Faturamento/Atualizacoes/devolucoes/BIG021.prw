#INCLUDE "rwmake.ch"
//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 05/04/2010 - Marcelo Lauschner - Codigo Revisado
//
//-------------------------------------------------------------------------------------------------
/*/{Protheus.doc} BIG021
//CADASTRO DE DEVOLUÇÕES         
@author marce
@since 09/02/205
@version 6

@type function
/*/
User Function BIG021()

	Private cCadastro		:= "Consulta de Autorizações de Devolução"
	Private aRotina         := {{'Procurar','AxPesqui',0,1},;
	{'Visualisar','AxVisual',0,2},;
	{'Relatório','U_BFFATR18',0,7}}

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	dbSelectArea("SZ3")
	dbSetOrder(1)

	MBrowse(6,1,22,75,"SZ3",,,,,,)


Return