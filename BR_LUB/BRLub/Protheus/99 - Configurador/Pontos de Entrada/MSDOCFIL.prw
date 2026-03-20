#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MSDOCFIL
// Avalia se o registro do banco de Conhecimento foi incluído pelo usuário do Financeiro 
@author marce
@since 22/10/2017
@version 6

@type function
/*/
User function MSDOCFIL()
	Local	lRet		:= .T.
	Local	aAreaOld	:= GetArea()
	Local	cAC9UsrGi	:= ""
	Local	cAC9UsrId	:= ""
	Local	nRecAC9		:= ParamIxb[1]
	
	DbSelectArea("AC9")
	DbGoto(nRecAC9)
		
	// Se acionado para a entidade Clientes
	If AC9->AC9_ENTIDA == "SA1" .And. AC9->(FieldPos("AC9_USERGI")) > 0 

		// Localica usuário que inseriu o registro 
		cAC9UsrGi := FWLeUserlg("AC9_USERGI",1)
		PswOrder(2)// pesquisar pelo nome do usuário
		If PswSeek( cAC9UsrGi, .T. )    
			cAC9UsrId := PswID()
		Endif

		// Registros antigos sem log de usuários
		If Empty(cAC9UsrId)
			lRet	:= .T.			
		// Sendo usuário do Financeiro é liberado acesso a todos os registros	
		ElseIf (__cUserId $ GetMv("BF_USRSERA"))
			lRet	:= .T.
		// Sendo usuário diferente Financeiro e o registro incluído pelo financeiro - bloqueia
		ElseIf !(__cUserId $ GetMv("BF_USRSERA")) .And. (cAC9UsrId $ GetMv("BF_USRSERA"))
			lRet	:= .F.
		Endif
	Endif 

	RestArea(aAreaOld)
Return lRet

/*
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada pata filtro do usuario. Se retornar .T. considera o   ³
//³ registro do AC9, senao pula o registro.                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lMsDocFil
lRet := ExecBlock("MSDOCFIL",.F.,.F.,{AC9->(Recno())})
If ValType(lRet) <> "L"
lRet := .T.
EndIf
EndIf	
*/
