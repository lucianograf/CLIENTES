#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} TK271END
PE executado ao final do processo de gravação dos dados da rotina de teleatendimentos
@type function
@version 1.0
@author ICmais
@since 11/3/2021
/*/
User Function TK271END()

	Local aArea     := GetArea()
	Local cFunCall  := SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)

	If	SUA->UA_OPER == "1"

		// Chama função que replica dados da SUA/SUB para SC5/SC6
		sfAtuPed()

		// Verifica se houve a gravação do evento 7-Liberação automática de Pedido vindo do Callcenter
		DbSelectArea("SZ9")
		DbSetOrder(2)	// Origem+Num+Evento
		If DbSeek(xFilial("SZ9")+"O"+SUA->UA_NUM+"7");	//Evento 7-Liberação automática
			.Or. DbSeek(xFilial("SZ9")+"O"+SUA->UA_NUM+"4")
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Chamando função de liberação do pedido Ma410LbNfs em TMKVFIM.PRW "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			DbSelectArea("SC5")
			DbSetOrder(1)
			DbSeek(xFilial("SC5")+SUA->UA_NUMSC5)

			// Faço a liberação de alçada dos itens, pois não houveram restrições
			DbSelectArea("SC6")
			DbSetOrder(1)
			DbSeek(xFilial("SC6") + SC5->C5_NUM )
			While !SC6->(Eof()) .And. SC6->C6_FILIAL+SC6->C6_NUM == xFilial("SC6")+SC5->C5_NUM
				RecLock("SC6",.F.)
				SC6->C6_BLQ	:= "N"
				MsUnlock()
				SC6->(DbSkip())
			Enddo
			DbSelectArea("SC5")
			Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)

			U_GMCFGM01(	"LP"/*cTipo*/,;
				SC5->C5_NUM/*cPedido*/,;
				"Pedido liberado automático sem restrições de alçada"/*cObserv*/,;
				FunName()/*cResp*/,;
				/*lBtnCancel*/,;
				""/*cMotDef*/,;
				.T./*lAutoExec*/,;
				cUserName)

			U_BFFATA35("P"/*cZ9ORIGEM*/,SC5->C5_NUM/*cZ9NUM*/,"4"/*cZ9EVENTO*/,"Pedido liberado sem restrição de alçadas"/*cZ9DESCR*/,""/*cZ9DEST*/,cUserName/*cZ9USER*/)
		ElseIf DbSeek(xFilial("SZ9")+"P"+SUA->UA_NUMSC5+"6")
			U_BFFATA30(.T./*lAuto*/,SUA->UA_NUMSC5/*cInPed*/,1/*nInPedOrc*/)
		Endif
	ElseIf SUA->UA_OPER == "2"
		U_BFFATA30(.T./*lAuto*/,SUA->UA_NUM/*cInPed*/,2/*nInPedOrc*/)
	ElseIf SUA->UA_OPER == "3"
		If !IsBlind()
			MsgInfo("Atendimento "+SUA->UA_NUM+" gravado com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Endif
	EndIf

	// Manter o trexo de código a seguir no final do fonte
	If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., Nil )
	EndIf

	RestArea( aArea )

Return Nil

/*/{Protheus.doc} BIGATUPE
(Replica informações do Atendimento para o Pedido de venda - Cabeçalho e itens)

@author MarceloLauschner
@since 30/01/2014
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfAtuPed()

	Local 	aAreaOld	:= GetArea()
	Local	cVend2		:= ""

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	dbSelectArea("SUA")
	//Campos a serem atualizados
	dbSelectArea("SC5")
	dbSetOrder(1)

	If	SC5->(dbSeek(xFilial("SC5")+SUA->UA_NUMSC5))
		cVend2	:=	Posicione("SA3",1,xFilial("SA3")+SUA->UA_VEND,"A3_ACESSOR")

		RecLock("SC5",.F.)
		SC5->C5_DTPROGM		:=	sfCalcRota(SUA->UA_DTPROGM)//SUA->UA_DTPROGM
		SC5->C5_MSGINT		:=	SUA->UA_MSGINT
		SC5->C5_MENNOTA		:=	SUA->UA_MENNOTA
		SC5->C5_USUPED		:=	SUA->UA_USUATEN
		SC5->C5_DIASENT		:=	SUA->UA_DIASENT
		SC5->C5_VEND3		:=	Iif(SUA->UA_VEND03 <> SUA->UA_VEND .And. SUA->UA_VEND03 <> cVend2,SUA->UA_VEND03," ") //Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_VEND03")
		SC5->C5_PARC1		:=	SUA->UA_PARC1
		SC5->C5_PARC2		:=	SUA->UA_PARC2
		SC5->C5_PARC3		:=	SUA->UA_PARC3
		SC5->C5_PARC4		:=	SUA->UA_PARC4
		SC5->C5_DATA1		:=	SUA->UA_DATA1
		SC5->C5_DATA2		:=	SUA->UA_DATA2
		SC5->C5_DATA3		:=	SUA->UA_DATA3
		SC5->C5_DATA4		:=	SUA->UA_DATA4
		SC5->C5_A1VPTMK		:=	Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_GERAT")  //Adicionado Daniel 03/02/11
		SC5->C5_REEMB		:=	SUA->UA_REEMB
		SC5->C5_XEMPFXC		:= 	SUA->UA_XEMPFXC // Segmento de negocio + Tipo de vendedor (BF/LL + R/C/S/A)
		SC5->C5_PEDPALM 	:= 	SUA->UA_PEDPALM //Pedido de tablet que originou o orçamento/pedido
		SC5->C5_XENVFAT		:= 	SUA->UA_XENVFAT
		SC5->C5_XVOLLIT		:=  SUA->UA_XVOLLIT
		SC5->C5_XVOLQTE		:=  SUA->UA_XVOLQTE
		SC5->C5_BANCO		:=	SUA->UA_BANCO
		SC5->C5_PROPRI		:=	SUA->UA_TMK
		SC5->C5_VEND2		:=	Iif(cVend2 <> SUA->UA_VEND,cVend2," ")
		SC5->C5_TRANSP		:=	IIf(!Empty(SUA->UA_TRANSP) .Or. (Empty(SUA->UA_TRANSP) .And. SUA->UA_TPFRETE == "S"),SUA->UA_TRANSP,Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_TRANSP"))
		SC5->C5_XPEDCLI		:= 	SUA->UA_XPEDCLI
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
			SC6->C6_XFLEX	:= 	SUB->UB_XFLEX	// Valor adicional de custo da tampa
			SC6->C6_XCODTAB	:= 	SUB->UB_XCODTAB	// Codigo da Tabela de preços
			SC6->C6_COMIS1	:=	SUB->UB_COMIS1
			SC6->C6_COMIS2	:= 	SUB->UB_COMIS2
			SC6->C6_COMIS3	:= 	SUB->UB_COMIS3
			SC6->C6_XPRCMIN	:= 	SUB->UB_XPRCMIN	// Preço minimo para validações
			SC6->C6_XPRCMAX	:=	SUB->UB_XPRCMAX	// Preço Máximo para validações
			SC6->C6_XREGBNF	:= 	SUB->UB_XREGBNF	// Código da Regra de Bonificação.
			SC6->C6_XPRTAB1	:=  SUB->UB_XPRTAB1
			SC6->C6_XPRTAB2	:=  SUB->UB_XPRTAB2
			SC6->C6_XPRTAB3	:=  SUB->UB_XPRTAB3
			SC6->C6_XPRTAB4	:=  SUB->UB_XPRTAB4
			SC6->C6_XPRTAB5	:=  SUB->UB_XPRTAB5
			SC6->C6_XPRTAB6	:=  SUB->UB_XPRTAB6
			SC6->C6_XVLRTAM	:=	SUB->UB_XVLRTAM	// Valor da tampa para reembolso validações
			SC6->C6_XLIBALC	:=	SUB->UB_XLIBALC	//
			SC6->C6_XALCADA	:= 	SUB->UB_XALCADA	//
			SC6->C6_BLQ		:= 	"S"					// Sempre grava todo pedido bloqueado na Alçada
			MsUnlock()
		EndIf
		
		dbSelectArea("SUB")
		DbSkip()
	EndDo
	
	U_GMCFGM01("IP",SUA->UA_NUMSC5,,FunName())

	// Efetua chamada que atualiza dados de Valores declaratórios 
	U_XXF3KFORCE(SUA->UA_NUMSC5)

	
	RestArea(aAreaOld)
	
Return



/*/{Protheus.doc} sfCalcRota
(Calcula a data programa para entrega)
@author MarceloLauschner
@since 14/08/2015
@version 1.0
@param dInDtProgm, data, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function sfCalcRota(dInDtProgm)
	
	Local		aAreaOld	:= GetArea()
	Local		cCliente 	:= SUA->UA_CLIENTE
	Local		cLoja    	:= SUA->UA_LOJA
	Local		cCEP		:=" "
	Local		cRota		:=" "
	Local		nDiaAtu  	:= 0
	Local		nDiaEnt  	:= 0
	Local		dData    	:= dDataBase
	Local		aRota    	:= {}
	Local		aDias    	:= {1,2,3,4,5,6,7}
	Local 		x
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica da de entrega                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+cCliente+cLoja)
		cCEP := SA1->A1_CEP
		
		IF SA1->A1_ROTA <> " "
			cRota := SA1->A1_ROTA
		endif
		
		dbSelectArea("PAB")
		dbSetOrder(1)
		If dbSeek(xFilial("PAB")+cCEP)
			cRota := PAB->PAB_ROTA
			For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
				AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
			Next
		Endif
		
		IF SA1->A1_ROTA <> " "
			For x := 1 To Len(AllTrim(SA1->A1_ROTA)) Step 1
				AADD(aRota,{SubStr(SA1->A1_ROTA,x,1)})
			Next
		Endif
		//Endif
	Endif
	
	nDia := Dow(dDatabase)
	If Len(aRota) > 0
		While .T.
			If nDia > 7
				nDia := 1
			Endif
			nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
			If !Empty(nPos)
				nDiaEnt := Val(aRota[nPos][1])
				If nDiaEnt == Dow(dDatabase)
					dData := dDatabase
				Elseif (nDiaEnt - Dow(dDatabase)) > 0
					dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
				Else
					dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
				Endif
				Exit
			Endif
			nDia++
		End
	Endif
	// Se a data programada no Orçamento for maior que a data calculada, mantém o valor, caso contrário assume o valor do calculo da rota
	If dInDtProgm > dData
		dData	:= dInDtProgm
	Endif
	
	RestArea(aAreaOld)
Return dData
