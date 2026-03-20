#include 'protheus.ch'

/*
P.E. após a Alteração do Contato.
Será efetuada a chamada da integração com CRM

Obs.: Na Inclusao do contato nao será chamada a integração, 
pois preciso do relacionamento para poder integrar
*/

user function TMKALTU5()

	// Chama Integração de Contatos com o CRM
	IF cEmpAnt == "02" .and. cFilAnt == "0204"
		FwMsgRun(NIL, {|| U_PTCRM901(.T.)}, "Aguarde", "Processando integração com CRM")
	endif
	
return
