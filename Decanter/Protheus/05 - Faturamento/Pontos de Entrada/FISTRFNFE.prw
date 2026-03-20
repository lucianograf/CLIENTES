#include 'protheus.ch'

/*
Este ponto de entrada tem por finalidade incluir novos botões na rotina SPEDNFE().
*/

User Function FISTRFNFE()

	AADD(aRotina,{'DANFE Selecionada*','U_UNIM007' ,0,2,0,NIL})
	AADD(aRotina,{'Boleto*','U_DECA152B' ,0,2,0,NIL})

	IF __CUSERID = "000242" .and. cEmpAnt == "02" .and. cFilAnt == "0204"
		aadd(aRotina,{'Integrar CRM','U_PTCRM905(3)' , 0 , 4,0,NIL})
	Endif

Return Nil
