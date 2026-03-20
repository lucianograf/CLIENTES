#Include  'protheus.ch'


/*
Este ponto de entrada pode ser utilizado para inserir novas opções no array aRotina.
*/

User Function MA410MNU()

	aAdd(aRotina,{"Impressao Pedido*"	,"U_ACTVS05R01"	,0,3,0,NIL})

	aAdd(aRotina,{"Espelho Pedido*"		,"U_MLFATC07"	,0,2,0,NIL})

	Aadd(aRotina,{"Log do Pedido*" 		,"U_MLFAT14A"	,0,2,0,Nil})


	IF __CUSERID = "000242" .and. cEmpAnt == "02"
		aAdd(aRotina, { OemToAnsi("Integrar CRM" )     ,'U_PTCRM904(3)' ,0,4, 0} )
	Endif

Return




