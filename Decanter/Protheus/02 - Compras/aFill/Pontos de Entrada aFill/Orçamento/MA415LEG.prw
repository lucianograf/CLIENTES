
/*/{Protheus.doc} MA415LEG
PE para retornar nova legenda do or�amento x proforma.
@author manowz
@since 09/02/2021
@version 1.0
@return aNovLeg, array com a nova legenda.
@type User Function
/*/
User Function MA415LEG()

	Local aLegenda := {}

	aLegenda := { {'ENABLE'     , 'Orcamento em Aberto' },;
	              {'DISABLE'    , 'Orcamento Baixado'   },;
				  {'BR_PRETO'   , 'Orcamento Cancelado' },;
				  {'BR_AMARELO' , 'Orcamento N�o Or�ado'},;
				  {'BR_AZUL'    , 'Orcamento Aprovado'  },;
				  {'BR_BRANCO'  , 'Orcamento x Proforma'} }
Return aLegenda
