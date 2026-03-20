#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MLFATA02
// Rotina para consulta de Log de Pedidos 
@author Marcelo Alberto Lauschner 
@since 14/08/2019
@version 1.0
@return Nil
@type User Function
/*/
User function MLFATA02()


	Local cVldAlt := ".F." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
	Local cVldExc := ".F." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.

	dbSelectArea("SZ0")
	dbSetOrder(1)

	AxCadastro("SZ0","Historico e Logs de Pedido",cVldAlt,cVldExc)

Return