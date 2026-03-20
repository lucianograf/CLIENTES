#Include 'Totvs.ch'

/*/{Protheus.doc} M020INC
Ponto de entrada executado na inclusão do cadastro de fornecedores
@type function
@version  1.00
@author TSC681 - Thiago Mota
@since 23/06/2014
/*/
User Function M020INC()
	
	// Cria classe valor automaticamente 
	U_AUTOCLVL( "F", SA2->A2_COD, SA2->A2_LOJA ) // 23/06/2014 : TSC681 - Thiago Mota

	If GetNewPar("DC_INMAXOK",.F.)
		U_XFLAG("SA2")
	Endif 
	
Return

