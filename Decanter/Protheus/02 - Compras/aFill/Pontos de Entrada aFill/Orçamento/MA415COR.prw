
/*/{Protheus.doc} MA415COR
PE para alterar a legenda do or�amento vinculado a proforma.
@author manowz
@since 09/02/2021
@version 1.0
@return aNovLeg, array com a nova legenda.
@type User Function
/*/
User Function MA415COR()

	Local aCores := {}

	aCores := { {"SCJ->CJ_STATUS=='A' .AND. SCJ->CJ_XPROFNUM != '      ' ","BR_BRANCO" },;
				{"SCJ->CJ_STATUS=='A'" , "ENABLE"    },;	   //Orcamento em Aberto
				{"SCJ->CJ_STATUS=='B'" , "DISABLE"   },;   //Orcamento Baixado
				{"SCJ->CJ_STATUS=='C'" , "BR_PRETO"  },;   //Orcamento Cancelado
				{"SCJ->CJ_STATUS=='D'" , "BR_AMARELO"},;   //Orcamento nao Orcado
				{"SCJ->CJ_STATUS=='E'" , "BR_AZUL"   } }   //Orcamento aprovado Par�metros
				
Return aCores
