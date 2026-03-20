#include 'protheus.ch'
#include 'topconn.ch'


/*/{Protheus.doc} XMLCTE27
//TODO Ponto de entrada para editar valores de variáveis antes de abrir a tela de condições para lançamento de notas. 
@author Marcelo Alberto Lauschner
@since 28/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function XMLCTE27(cTipoNf,cInCond,cInNatF)
		//{"T",@cCondicao,@cNatFin
	
	// As variáveis cInCond e cInNatF são passadas como parâmetro via Referência. 
	
	If cTipoNf == "T"  // Frete sobre vendas
		cInCond		:= "C28"	
		cInNatF		:= "20331" // Frete sobre vendas

    Elseif cTipoNf == "F"  // Frete sobre vendas
		cInCond		:= "C28"	
		cInNatF		:= "20370" // Frete sobre compras
	ElseIf cTipoNf == "N"	// Nota Normal 

	Endif
	 
Return 
