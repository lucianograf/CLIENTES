#Include 'Totvs.ch'

/*/{Protheus.doc} M030INC
Ponto-de-Entrada: M030INC - Executado na inclusão do cadastro de clientes
@type function
@version  
@author Marcelo Alberto Lauschner
@since 11/02/2021
/*/
User Function M030INC() 

	If PARAMIXB == 0
		U_AUTOCLVL( "C", SA1->A1_COD, SA1->A1_LOJA ) // 23/06/2014 : TSC681 - Thiago Mota
	Endif

Return 
