#Include 'Protheus.ch'

/*/{Protheus.doc} DCCFGM01
Função para Controle de Semáforo - Criar e Retirar Trava
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/06/2021
@param lLock, logical, param_description
@param cKey, character, param_description
@param cMsg, character, param_description
@param lTrvEmp, logical, param_description
@param lTrvFil, logical, param_description
@param lExeAuto, logical, param_description
@return return_type, return_description
/*/
User Function DCCFGM01(lLock,cKey,cMsg,lTrvEmp,lTrvFil,lExeAuto)

	Local	nTentativas	:= 0
	
	Default lLock		:= .F.
	Default cKey 		:= "DCCFGM01"
	Default cMsg		:= "Aguarde, arquivo sendo alterado por outro usuário."
	Default	lTrvEmp		:= .F.
	Default lTrvFil		:= .F. 
	Default lExeAuto	:= .F. 
	
	If lLock
		While !LockByName(cKey,lTrvEmp,lTrvFil,.T.)
			If lExeAuto
				Sleep(1000)
			Else
				MsAguarde({|| Sleep(1000) }, "Semaforo de processamento... tentativa "+AllTrim(Str(nTentativas)), cMsg)
			Endif
			nTentativas++
			
			If nTentativas > 5
				If !lExeAuto .And. MsgYesNo("Não foi possível acesso exclusivo à rotina. Deseja tentar novamente ?")
					nTentativas := 0
					Loop
				Else
					Return .F.
				EndIf
			EndIf
		EndDo

		FWLogMsg("INFO",,'1',"DCCFGM01",,"DCCFGM","Criado semáforo para a chave '"+cKey+"' ")
	Else
		UnLockByName(cKey,lTrvEmp,lTrvFil,.T.)
        FWLogMsg("INFO",,'1',"DCCFGM01",,"DCCFGM","Liberado semáforo para a chave '"+cKey+"' ")
	Endif

Return .T.

