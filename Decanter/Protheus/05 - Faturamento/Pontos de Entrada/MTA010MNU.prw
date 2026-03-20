#Include 'Protheus.ch'

User Function MTA010MNU()

	IF __CUSERID = "000242" .and. cEmpAnt == "02" .and. cFilAnt == "0204"
		AADD(aRotina, {"Integrar CRM", "U_ptCRM902()", 0, 6})
	Endif

Return
