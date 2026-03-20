
/*/{Protheus.doc} MLFATA12
Cadastro de campanhas de venda Forta 
@type function
@version  
@author marce
@since 08/08/2023
@return variant, return_description
/*/
User Function MLFATA12()

	dbSelectArea("Z03")
	dbSetOrder(1)

	AxCadastro("Z03","Cadastros de Campanhas de Vendas Grupo Forta",".T.",".T.")

Return
