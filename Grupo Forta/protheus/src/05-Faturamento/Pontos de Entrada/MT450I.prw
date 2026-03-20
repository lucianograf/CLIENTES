#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} MTA450I
// Ponto de entrada ao Liberar crédito de Pedido
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return Nil 
@type User Function
/*/
User Function MTA450I()
                                     
	Local		aAreaOld		:= GetArea()
	Local		oLeTxt
	Local		nAction
	Private 	cObserv			:= Space(100)
	Private 	nLimCred		:= 0
	Private 	dDatVen			:= dDataBase
	Private 	cRisco			:= "D"
	Private		cObsMemo		:= ""
	
	
	If Type("lFirstSC9") <> "L"
		Public lFirstSC9		:= .T.
		Public cLastSC9		:= SC9->C9_PEDIDO
	Endif

	If cLastSC9 <> SC9->C9_PEDIDO .Or. lFirstSC9 //SC9->C9_ITEM == "01"
  		// Grava Log
		U_MLCFGM01("LC",SC9->C9_PEDIDO,,FunName())
	
		If MsgYesNo("Deseja alterar dados de credito do cliente ?","Informacao")
			
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SC9->C9_CLIENTE+SC9->C9_LOJA)
			
			nLimCred 		:= SA1->A1_LC
			dDatVen 		:= SA1->A1_VENCLC
			cRisco 			:= SA1->A1_RISCO
			nAction			:= 0
			cObsMemo		:= SA1->A1_OBSMEMO
		
			DEFINE MSDIALOG oLeTxt TITLE (ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+ OemToAnsi(" Informações do Credito do Cliente")) FROM 001,001 TO 420,585 PIXEL
				
			
			@ 010,018 Say "Cliente->"+SA1->A1_COD+SA1->A1_LOJA+"-"+SA1->A1_NOME Pixel Of oLeTxt
			@ 020,018 Say "Limite de Crédito:" Pixel Of oLeTxt
			@ 020,075 MsGet nLimCred Picture "@E 999,999.99" Size 50,10 Pixel Of oLeTxt
			@ 030,018 Say "Data Vencimento" Pixel Of oLeTxt
			@ 030,075 MsGet dDatVen  Size 50,10 Pixel Of oLeTxt
			@ 040,018 Say "Risco" Pixel Of oLeTxt
			@ 040,075 Combobox cRisco Items {"A","B","C","D","E","Z"} Size 40,10 Pixel Of oLeTxt
			@ 052,018 Say "Observações" Pixel Of oLeTxt
			@ 052,075 MsGet cObserv Size 205,30 Pixel Of oLeTxt
			@ 090,018 MsGet cObsMemo Size 262,095 Pixel Of oLeTxt When .F.
			//@ 195,010 Button "Antecipado" Size 50,10  Action (nAction := 1,oLeTxt:End()) Pixel Of oLeTxt
			@ 195,065 Button "Gravar" Size 50,10 Action (nAction := 2,oLeTxt:End()) Pixel Of oLeTxt
			@ 195,120 Button "Cancelar" Size 50,10 Action oLeTxt:End() Pixel Of oLeTxt
		
			Activate MsDialog oLeTxt Centered
		
			If nAction == 1
				sfAntecipado()
				Alteralc()
			ElseIf nAction == 2
				Alteralc()
			Endif
		
		Endif
	Endif
	lFirstSC9 	:= .F.
	cLastSC9 	:= SC9->C9_PEDIDO

	RestArea(aAreaOld)

Return



/*/{Protheus.doc} Alteralc
// Efetiva gravação dos dados 
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return Nil
@type Static Function
/*/
Static Function Alteralc()
	
	Local	cMsgAlt		:= ""
	
	If SA1->A1_LC <>  nLimcred
		cMsgAlt	:= "Limite de Crédito alterado de R$ " + Alltrim( Transform( SA1->A1_LC,"@E 999,999.99")) + " para R$ " + Alltrim( Transform(nLimCred,"@E 999,999.99"))
		U_MLCFGM01("LC",SC9->C9_PEDIDO,cMsgAlt,FunName())
	Endif
	
	If SA1->A1_RISCO <>  cRisco
		cMsgAlt	:= "Risco de Crédito alterado de  " + SA1->A1_RISCO  + " para R$ " + cRisco
		U_MLCFGM01("LC",SC9->C9_PEDIDO,cMsgAlt,FunName())
	Endif
	
	If SA1->A1_VENCLC <>  dDatVen
		cMsgAlt	:= "Data do Limite de Crédito alterado de " + DTOC(SA1->A1_VENCLC) + " para  " + DTOC(dDatVen)
		U_MLCFGM01("LC",SC9->C9_PEDIDO,cMsgAlt,FunName())
	Endif
	// Grava observação 
	If !Empty(cObserv)
		cMsgAlt	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(__cUserId))  + " Observação durante liberação: " + AllTrim(cObserv)
		U_MLCFGM01("LC",SC9->C9_PEDIDO,cMsgAlt,FunName())
	Endif
	
	DbSelectArea("SA1")
	cA1MemoObs	:= SA1->A1_OBSMEMO
	RecLock("SA1",.F.)
	SA1->A1_LC 		:= nLimcred
	SA1->A1_VENCLC 	:= dDatVen
	SA1->A1_RISCO 	:= cRisco
	SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(__cUserId)) + Chr(13)+Chr(10) + ""+cObserv+Chr(13)+Chr(10)+cA1MemoObs
	MsUnLock()

	MsgAlert("Entrada de Dados Realizada com sucesso!!","Informacao","INFO")

Return



Static Function sfAntecipado()

	Local 	oPed2
	Local	cMensagem 	:= ""
	Local	cRecebe 	:= ""
	Local	cAssunto 	:= ""
	Local	cMotBlq		:= Space(100)
	Local	cPed    	:= SC9->C9_PEDIDO
	Local	cQru
	Local	cA1MemoObs	:= ""
	
	DEFINE MSDIALOG oPed2 TITLE (ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + OemToAnsi("Bloquear por Antecipado o pedido-> "+ cPed + "?")) FROM 001,001 TO 100,370 PIXEL
	
	@ 015,010 Say "Motivo Bloqueio/Liberação" Pixel Of oPed2
	@ 027,010 MsGet cMotBlq	Size 170,10 Valid (Len(Alltrim(cMotBlq)) > 15) Pixel Of oPed2
	@ 040,010 Button "&Grava Antecipado" Size 50,10 ACTION (oPed2:End() ) Pixel Of oPed2
	@ 040,065 Button "&Cancela"  SIZE 50,10 ACTION (cMotBlq := "", oPed2:End() ) Pixel Of oPed2

	ACTIVATE MsDIALOG oPed2 CENTERED

	If !Empty(cMotBlq)
	
		cQru := ""
		cQru += "UPDATE " + RetSqlName("SC9")
		cQru += "   SET C9_FLGENVI = 'F' "
		cQru += " WHERE D_E_L_E_T_ = ' ' "
		cQru += "   AND C9_PEDIDO ='" +cPed+ "' "
		cQru += "   AND C9_FILIAL = '" + xFilial("SC9") +"'  "
	
		TCSQLExec(cQru)
	                  
		              	
		cRecebe		:= GetNewPar("ML_FINMAIL","")
	
		DbSelectArea("SC5")
		DbSetOrder(1)
		If DbSeek(xFilial("SC5")+cPed)
			RecLock("SC5",.F.)
			//SC5->C5_BOX		:= SC5->C5_CONDPAG + SC5->C5_BANCO 
			SC5->C5_BLPED	:= "F"
			//SC5->C5_BANCO	:= "987"
			//SC5->C5_CONDPAG	:= "099"
			//SC5->C5_MSGEXP 	:= Padr(cMotBlq,TamSX3("C5_MSGEXP")[1])
			MsUnlock()
			
			DbSelectArea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3")+SC5->C5_VEND1)
				cRecebe += Iif(!Empty(SA3->A3_EMAIL),";"+SA3->A3_EMAIL,"")
				//cRecebe += Iif(!Empty(SA3->A3_EMTMK),";"+SA3->A3_EMTMK,"")
			Endif
			
			cAssunto 	:= "Pedido "+ cPed + " bloqueado pelo financeiro."
			cMensagem	:= "O usuário '" + AllTrim(  UsrFullName(__cUserId) ) + "' " +Chr(13)+Chr(10)+;
				"bloqueou o pedido do cliente do cliente: " +;
				AllTrim( SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME) +;
				"no dia " + Dtoc( Date() ) + " as " + Time() + ". "
			cMensagem 	+= Chr(13)+Chr(10)
			//cMensagem 	+= "Mensagem Interna: "+SC5->C5_MSGEXP
			cMensagem 	+= Chr(13)+Chr(10)
			cMensagem 	+= "Valor do pedido liberado precisa ser consultado no sistema!"
			cMensagem 	+= Chr(13)+Chr(10)
			//cMensagem 	+= "Motivo: 'PAGAMENTO ANTECIPADO' e " + cMotBlq
			//cMensagem 	+= Chr(13)+Chr(10) + " Condição pagamento alterada para 099-Pagto Antecipado e Banco para 987-Pagamento Antecipado"
			cMensagem   += Chr(13)+Chr(10)
			cMensagem	+= "Empresa: " + SM0->M0_NOMECOM
	
			DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)		
				cA1MemoObs	:= SA1->A1_OBSMEMO
				RecLock("SA1",.F.)
				SA1->A1_OBSMEMO	:= DTOC(Date()) + "/" + Time() + "-"+Alltrim( UsrFullName(__cUserId)) + Chr(13)+Chr(10) + "Bloqueado:"+cMotBlq+Chr(13)+Chr(10)+cA1MemoObs
				MsUnlock()
			Endif
		Endif
		// Grava Log		
		U_MLCFGM01("BA",SC9->C9_PEDIDO,cMensagem,FunName())

		
		MsgAlert("Se houver outros pedidos para o mesmo Cliente, o procedimento de Antecipado deverá ser repetido!", "A T E N Ç Ã O!! ANTECIPADO!!")
	
	Endif

Return

