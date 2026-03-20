
/*/{Protheus.doc} TMKVFIM
(Ponto de entrada ao finalizar Atendimento Callcenter )
@author Marcelo Lauschner
@since 02/12/2013
@version 1.0
@return Sem retorno
@example
(User Function TMKVFIM(cNumAtend, cNumPedido)Alert('Passou pelo ponto de entrada TMKVFIM.')Return)
@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6787791)
/*/
User Function TMKVFIM()

	DbSelectArea("SUA")
	
	If	SUA->UA_OPER == "1"
		// Chama função que replica dados da SUA/SUB para SC5/SC6
		sfAtuPed()
		
			
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+SUA->UA_NUMSC5)
			
		// Faço a liberação de alçada dos itens, pois não houveram restrições
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6") + SC5->C5_NUM )
		While !Eof() .And. SC6->C6_FILIAL+SC6->C6_NUM == xFilial("SC6")+SC5->C5_NUM
			RecLock("SC6",.F.)
			SC6->C6_BLQ	:= "N"
			MsUnlock()
			DbSkip()
		Enddo
		
		DbSelectArea("SC5")
		Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)

			U_MLCFGM01(	"LP"/*cTipo*/,;
				SC5->C5_NUM/*cPedido*/,;
				"Pedido liberado automático sem restrições de alçada"/*cObserv*/,;
				FunName()/*cResp*/,;
				/*lBtnCancel*/,;
				""/*cMotDef*/,;
				.T./*lAutoExec*/,;
				cUserName)
			
	ElseIf SUA->UA_OPER == "2"
	//	U_BFFATA30(.T./*lAuto*/,SUA->UA_NUM/*cInPed*/,2/*nInPedOrc*/)	
	ElseIf SUA->UA_OPER == "3"
		If !IsBlind()
			MsgInfo("Atendimento "+SUA->UA_NUM+" gravado com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Endif 
	EndIf
	
Return

Static Function sfAtuPed()
	
	Local 	aAreaOld	:= GetArea()
	
	
	DbSelectArea("SUA")
	DbSelectArea("SC5")
	DbSetOrder(1)
	If	SC5->(dbSeek(xFilial("SC5")+SUA->UA_NUMSC5))
		
		RecLock("SC5",.F.)
		SC5->C5_ZMSGINT		:=	SUA->UA_ZMSGINT 
		SC5->C5_MENNOTA		:=	SUA->UA_MENNOT 
		SC5->C5_IDAJILI 	:= 	SUA->UA_IDAJILI  //Pedido de tablet que originou o orçamento/pedido
		SC5->C5_TPFRETE 	:=  SUA->UA_TPFRETE 
		SC5->C5_BANCO		:=	SUA->UA_BANCO
		SC5->C5_TRANSP		:=	IIf(!Empty(SUA->UA_TRANSP) .Or. (Empty(SUA->UA_TRANSP) .And. SUA->UA_TPFRETE == "S"),SUA->UA_TRANSP,Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_TRANSP"))
		MSUnlock()
	EndIf
	
	dbSelectArea("SC6")
	dbSetOrder(1)
	
	dbSelectArea("SUB")
	dbSetOrder(1)
	SUB->(DbGoTop())
	SUB->(dbSeek( SUA->UA_FILIAL + SUA->UA_NUM ))
	While !Eof() .AND. SUB->UB_FILIAL + SUB->UB_NUM == SUA->UA_FILIAL + SUA->UA_NUM
		
		dbSelectArea("SC6")
		If	SC6->(DbSeek( xFilial() + SUA->UA_NUMSC5 + SUB->UB_ITEM ) )
			
			RecLock("SC6",.F.)
			SC6->C6_PRUNIT	:=	SUB->UB_PRCTAB
			If SUB->(FieldPos("UB_COMIS1")) > 0 
				SC6->C6_COMIS1	:=	SUB->UB_COMIS1
			Endif 
			If SUB->(FieldPos("UB_COMIS2")) > 0 
				SC6->C6_COMIS2	:=	SUB->UB_COMIS2
			Endif 
			If SUB->(FieldPos("UB_COMIS3")) > 0 
				SC6->C6_COMIS3	:=	SUB->UB_COMIS3
			Endif 
			SC6->C6_BLQ			:= 	"S"					// Sempre grava todo pedido bloqueado na Alçada
			SC6->C6_IDAJILI		:= SUB->UB_IDAJILI 
			MsUnlock()
		EndIf
		
		dbSelectArea("SUB")
		DbSkip()
	EndDo
	
	U_MLCFGM01("IP",SUA->UA_NUMSC5,,FunName())
	
	RestArea(aAreaOld)
	
Return

