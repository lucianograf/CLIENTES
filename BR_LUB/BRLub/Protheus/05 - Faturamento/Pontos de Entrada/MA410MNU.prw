#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MA410MNU
//Ponto de entrada para adicionar botões no aRotina
@author Marcelo Alberto Lauschner
@since 16/07/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/ 
User function MA410MNU()

	// Chamado 21.246 
	If cEmpAnt $ "05#13"

		AAdd( aRotina, {"#Alterar Cab.Pedido *"	,"VIEWDEF.BFFATA65"		, 0 , 4,0,NIL})//4-Alteracao

		aAdd(aRotina,{ OemToAnsi("Espelho Pedido") ,"U_FZFATR04",0,0,0 ,NIL} )

		aAdd(aRotina,{ OemToAnsi("Liberar Pedido") ,"StaticCall(MA410MNU,sfMata440)",0,0,0 ,NIL} )

		Aadd(aRotina,{ "Espelho Itens Nota Fiscal","U_FZPCPR02()", 0 , 0 , 0 , Nil})				
	
	Endif

Return


/*/{Protheus.doc} sfMata440
//TODO Função para liberar o pedido de Venda
@author 
@since 16/01/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfMata440()

	// Verifico se o pedido está bloqueado por Regras
	
	If U_FOR007(SC5->C5_NUM)
			
		Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)
			
		U_GMCFGM01("LP"/*cTipo*/,SC5->C5_NUM/*cPedido*/,/*cObserv*/,FunName()/*cResp*/,/*lBtnCancel*/,/*cMotDef*/,/*lAutoExec*/)
		
	Endif
		
Return 
