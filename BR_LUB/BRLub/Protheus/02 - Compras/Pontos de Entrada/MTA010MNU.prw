#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MTA010MNU
//Ponto de entrada para adicionar mais botões na rotina MATA010 - Cadastro de produtos
@author Marcelo Alberto Lauschner
@since 03/11/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MTA010MNU()	
		
		Aadd(aRotina,{OemtoAnsi("Replicar Produtos"), "U_BFCOMA12", 0, 4, 2, .F.})	

Return
