#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MT410BRW
//TODO Ponto de Entrada ao acessar rotina Pedidos de Venda ( MATA410 ) 
@author Marcelo Alberto Lauschner
@since 11/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MT410BRW()

	Local		lRestAjil		:= GetNewPar("GF_RESTONL",.T.) // Só criar o parâmetro por filial como tipo Lógico

	// Permite que seja desativada a funcionalidade em caso de problemas 
	If lRestAjil
		// Faz chamada para importação dos pedidos 
		U_GETPVC()

		// Faz chamada de atualização de clientes 
		U_RESTCLI()

		// Faz chamada de amarração de clientes x vendedor 
		U_RESTPOR()
	Endif

return