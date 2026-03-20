#include "rwmake.ch"
#include "topconn.ch"


/*/{Protheus.doc} FOR007
(Liberação de Alçada de pedidos)

@author MarceloLauschner
@since 02/12/2013
@version 1.0

@param cInPedido, character, (Descrição do parâmetro)

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function FOR007(cInPedido,cInTipo)

	Local		lRet		:= .F.
	Private 	cPedido   	:= Space(6)
	Private 	oNomCli
	Private 	cNomCli	  	:= Space(60)
	Private 	cEmCli	  	:= Space(100)
	Private 	cEmCont	  	:= Space(100)

	If cInTipo == Nil
		cInTipo		:= "P"
	Endif
	If !cEmpAnt $ "14"
		MsgInfo("Esta empresa não usa o conceito de liberação de Alçadas!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	Endif

	// Se existir passagem de parametro
	If cInPedido <> Nil
		cPedido	:= cInPedido
	Endif

	@ 001,001 TO 100,400 DIALOG oDlg TITLE IIf(cInTipo=="P","Pedido","Orçamento")

	@ 005,005 Say "Digite " + IIf(cInTipo=="P","Pedido","Orçamento") Color 255
	@ 005,045 Get cPedido Valid sfVldPed(cPedido,cInTipo) Size 30,12
	@ 020,005 Say "Cliente"
	@ 020,025 Get cNomCli Object oNomCli Size 165,12 When .F.

	@ 035,060 BUTTON "Cancela" SIZE 40,10 Action(Close(oDlg))
	@ 035,010 BUTTON "Confirma" SIZE 40,10 Action(Close(oDlg),lRet := sfPedido(cInTipo))

	ACTIVATE MSDIALOG oDlg CENTERED

Return lRet


/*/{Protheus.doc} sfVldPed
(long_description)

@author MarceloLauschner
@since 02/12/2013
@version 1.0

@param cNumPed, character, (Descrição do parâmetro)

@return logico, se permite a liberação do pedido

@example
(examples)

@see (links_or_references)
/*/
Static Function sfVldPed(cNumPed,cInTipo)

	Local	cQry 		:= ""
	Local	lRet		:= .T.

	If cInTipo == "P"
		dbSelectArea("SC5")
		dbSetOrder(1)
		If dbSeek(xFilial("SC5")+cNumPed)

			If SC5->C5_TIPO $"D#B"
				cNomCli	:= SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+"-"+Posicione("SA2",1,xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_NOME")
			Else
				cNomCli	:= SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+"-"+Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
			Endif
			oNomCli:Refresh()

			If SC5->(FieldPos("C5_BOX")) > 0 .And. Alltrim(SC5->C5_BOX) $ "MP" .And. !__cUserId $ GetNewPar("BF_FOR07MP","000164#000073#000194")  // Rodrigo/Leandro/Marlon
				MsgAlert("Você não tem alçada para liberar este pedido!. Autorizados somente pelo 'Depto de Compras'!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Sem acesso")
				lRet	:= .F.
			Endif

			cEmCli := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_EMAIL")

			// Efetua verificação de Email pela função de validação de e-mails
			If lRet .And. SC5->C5_TIPO == "N"
				lRet := U_GMTMKM01(cEmCli,cEmCli,SA1->A1_MSBLQL,.T./*lValdAlcada*/)
			Endif

			// Evita que pedido que já esteja liberado posso ser manipulado
			If SC5->C5_LIBEROK == "S"
				MsgAlert("Este pedido já está liberado. Não é possível liberar alçada novamente!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Pedido liberado")
				lRet	:= .F.
			Endif

			If lRet
				cQry := "SELECT COUNT(*) NEXIST "
				cQry += "  FROM "+RetSqlName("SC6") + " C6 "
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND C6_BLQ = 'R' "
				cQry += "   AND C6_NUM = '"+cNumPed+"' "
				cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"'"

				TCQUERY cQry NEW ALIAS "QRSC6"

				If QRSC6->NEXIST > 0
					MsgAlert("Pedido já possuí itens eliminados por Resíduo! Favor acessar a rotina Pedidos de Venda e Altere o pedido para depois liberar Alçada!","Informação")
					lRet	:= .F.
				Endif
				QRSC6->(DbCloseArea())
			Endif
		Else
			MsgAlert("Pedido Inexistente","Não existe")
			lRet 	:= .F.
		Endif
	ElseIf cInTipo == "O" 
		dbSelectArea("SUA")
		dbSetOrder(1)
		If dbSeek(xFilial("SUA")+cNumPed)

			cNomCli	:= SUA->UA_CLIENTE+"/"+SUA->UA_LOJA+"-"+Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_NOME")
			oNomCli:Refresh()

			cEmCli := Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_EMAIL")

			// Efetua verificação de Email pela função de validação de e-mails
			If SUA->UA_OPER == "2"
				lRet := U_GMTMKM01(cEmCli,cEmCli,SA1->A1_MSBLQL,.T./*lValdAlcada*/)
			Else
				lRet	:= .F.
			Endif


			If lRet
				cQry := "SELECT COUNT(*) NEXIST "
				cQry += "  FROM "+RetSqlName("SUB") + " UB "
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND UB_XALCADA != ' ' "
				cQry += "   AND UB_NUM = '"+cNumPed+"' "
				cQry += "   AND UB_FILIAL = '"+xFilial("SUB")+"'"

				TCQUERY cQry NEW ALIAS "QRSUB"

				If QRSUB->NEXIST == 0
					MsgAlert("Este orçamento de televendas não tem itens pendentes para liberação de alçadas!","Informação")
					lRet	:= .F.
				Endif
				QRSUB->(DbCloseArea())
			Endif
		Else
			MsgAlert("Orçamento Televendas Inexistente","Não existe")
			lRet 	:= .F.
		Endif
	Endif

Return lRet


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Libera pedido                                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


/*/{Protheus.doc} Pedido
(long_description)

@author Marcelo Lauschner
@since 02/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfPedido(cInTipo)

	Local	cQry 		:= ""
	Local	lRet		:= .T.
	Local	cXAlcada	:= ""
	Local	aAlcadas	:= {}
	Local	aSC6Recno	:= {}
	Local	cC6XAlcada	:= ""
	Local	lLib		:= .F.
	Local	cCtrlAlc	:= ""
	Local 	j
	Local 	iQ 


	If cInTipo == "P"
		dbSelectArea("SC5")
		dbSetOrder(1)
		If dbSeek(xFilial("SC5")+cPedido)

			// Procura por todos os motivos de bloqueio de alçada no pedido
			cQry := "SELECT C6_XALCADA,R_E_C_N_O_ C6RECNO "
			cQry += "  FROM "+RetSqlName("SC6") + " C6 "
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND C6_QTDENT < C6_QTDVEN "	// Somente Pendente
			cQry += "   AND C6_BLQ != 'R' "				// Não Eliminado Residuo
			//fcQRy += "   AND C6_XALCADA != ' ' "
			cQry += "   AND C6_NUM = '"+cPedido+"' "
			cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"'"

			TCQUERY cQry NEW ALIAS "QRSC6"

			While !Eof()
				cXAlcada	+= Alltrim(QRSC6->C6_XALCADA)+"#"
				Aadd(aSC6Recno,QRSC6->C6RECNO)
				DbSkip()
			Enddo
			QRSC6->(DbCloseArea())
			// Transformo os dados num Vetor
			// A6#B3#B1#A6#B3#

			// Verifica se existe o sinal de # para montagem do vetor por substr ou strtokarr
			If At("#",cXAlcada) <= 0
				For j := 1 To Len(cXAlcada)
					If Mod(j,2) == 1
						Aadd(aAlcadas,Substr(cXAlcada,j,2))
					Endif
				Next
			Else
				cXAlcada 	:= StrTran(cXAlcada,"|","")
				aAlcadas	:= StrTokArr((Alltrim(cXAlcada)+"#"),"#")
			Endif

			If !Empty(aAlcadas)
				cQry := "SELECT ZS_MOTIVO,ZS_IDUSR1,ZS_DESC "
				cQry += "  FROM "+RetSqlName("SZS") + " ZS "
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND ZS_MOTIVO IN("
				For iQ := 1 To Len(aAlcadas)
					If iQ > 1
						cQry += ","
					Endif
					cQry += "'"+ Alltrim(aAlcadas[iQ]) +"'"
				Next
				cQry += " )
				cQry += "   AND ZS_IDUSR1 = '"+__cUserId+"' "	// Usuário logado no Sistema
				cQry += "   AND ZS_FILIAL = '"+xFilial("SZS")+"'"

				TCQUERY cQry NEW ALIAS "QZS"

				While !Eof()
					For iQ := 1 To Len(aSC6Recno)
						DbSelectArea("SC6")
						DbGoto(aSC6Recno[iQ])
						//cC6XAlcada		:= SC6->C6_XALCADA
						//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO+"#","")
						//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO,"")
						//cC6XAlcada 	:= StrTran(cC6XAlcada,"|","")
						RecLock("SC6",.F.)
						//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
						//SC6->C6_XALCADA	:= cC6XAlcada
						SC6->C6_XALCADA	:= sfMotAlc(SC6->C6_XALCADA,QZS->ZS_MOTIVO)
						// Se já existir alguma alçada do item apenas concatena alçada
						If !Empty(SC6->C6_XLIBALC)
							// Se o liberador não constar ainda na lista
							If !(__cUserId $ SC6->C6_XLIBALC )
								cAuxAlc			:= Alltrim(SC6->C6_XLIBALC)
								SC6->C6_XLIBALC	:= cAuxAlc+"#"+__cUserId
							Endif
						Else
							SC6->C6_XLIBALC	:= SC5->C5_CLIENTE+"|"+SC5->C5_LOJACLI+"|"+SC5->C5_CONDPAG+"|"+SC6->C6_PRODUTO+"|"+SC6->C6_TES+"|"+ cValToChar(SC6->C6_QTDVEN)+"|"+ cValToChar(SC6->C6_PRCVEN) + "|" + __cUserId
						Endif

						If Empty(SC6->C6_XALCADA)
							SC6->C6_BLQ	:= "N"
						Endif
						MsUnlock()
					Next
					lLib	:= .T.
					DbSelectArea("QZS")
					DbSkip()
				Enddo
				QZS->(DbCloseArea())
			Endif
		Endif

	//	 Trecho não é mais necessário. O Cadastro de motivos de liberações precisa ser feito na SZS 
		If !lLib
			For iQ := 1 To Len(aSC6Recno)
				DbSelectArea("SC6")
				DbGoto(aSC6Recno[iQ])
				RecLock("SC6",.F.)
				//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
				SC6->C6_XALCADA	:= sfMotAlc(cC6XAlcada,"XX")
				// Se já existir alguma alçada do item apenas concatena alçada
				If !Empty(SC6->C6_XLIBALC)
					// Se o liberador não constar ainda na lista
					If !(__cUserId $ SC6->C6_XLIBALC )
						cAuxAlc			:= Alltrim(SC6->C6_XLIBALC )
						SC6->C6_XLIBALC	:= cAuxAlc+"#"+__cUserId
					Endif
				Else
					SC6->C6_XLIBALC	:= SC5->C5_CLIENTE+"|"+SC5->C5_LOJACLI+"|"+SC5->C5_CONDPAG+"|"+SC6->C6_PRODUTO+"|"+SC6->C6_TES+"|"+ cValToChar(SC6->C6_QTDVEN)+"|"+ cValToChar(SC6->C6_PRCVEN) + "|" + __cUserId
				Endif

				If Empty(SC6->C6_XALCADA)
					SC6->C6_BLQ	:= "N"
				Endif
				MsUnlock()
			Next
		Endif
		
		
		For iQ := 1 To Len(aSC6Recno)
			DbSelectArea("SC6")
			DbGoto(aSC6Recno[iQ])
			If SC6->C6_BLQ <> "N"
				U_GMCFGM01("LF",cPedido,"Item "+SC6->C6_ITEM+"-"+SC6->C6_PRODUTO+" não foi liberado. Pendência de alçada "+SC6->C6_XALCADA,FunName())
				MsgAlert("Item "+SC6->C6_ITEM+"-"+SC6->C6_PRODUTO+" não foi liberado. Pendência de alçada "+SC6->C6_XALCADA,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
				lRet	:= .F.
			Endif
		Next
		If lRet
			MsgAlert("Pedido "+cPedido+" Liberado.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
			// Grava Log
			U_GMCFGM01("LF",cPedido,,FunName())
		Endif
	Else
		DbSelectArea("SUA")
		DbSetOrder(1)
		If dbSeek(xFilial("SUA")+cPedido)

			// Procura por todos os motivos de bloqueio de alçada no pedido
			cQry := "SELECT UB_XALCADA,R_E_C_N_O_ UBRECNO "
			cQry += "  FROM "+RetSqlName("SUB") + " UB "
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND UB_NUM = '"+cPedido+"' "
			cQry += "   AND UB_FILIAL = '"+xFilial("SUB")+"'"

			TCQUERY cQry NEW ALIAS "QRSUB"

			While !Eof()
				cXAlcada	+= Alltrim(QRSUB->UB_XALCADA)+"#"
				Aadd(aSC6Recno,QRSUB->UBRECNO)
				DbSkip()
			Enddo
			QRSUB->(DbCloseArea())
			// Transformo os dados num Vetor
			// A6#B3#B1#A6#B3#
			// Verifica se existe o sinal de # para montagem do vetor por substr ou strtokarr
			If At("#",cXAlcada) <= 0
				For j := 1 To Len(cXAlcada)
					If Mod(j,2) == 1
						Aadd(aAlcadas,Substr(cXAlcada,j,2))
					Endif
				Next
			Else
				cXAlcada 	:= StrTran(cXAlcada,"|","")
				aAlcadas	:= StrTokArr((Alltrim(cXAlcada)+"#"),"#")
			Endif

			If !Empty(aAlcadas)
				cQry := "SELECT ZS_MOTIVO,ZS_IDUSR1,ZS_DESC "
				cQry += "  FROM "+RetSqlName("SZS") + " ZS "
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND ZS_MOTIVO IN("
				For iQ := 1 To Len(aAlcadas)
					If iQ > 1
						cQry += ","
					Endif
					cQry += "'"+ Alltrim(aAlcadas[iQ]) +"'"
				Next
				cQry += " )
				cQry += "   AND ZS_IDUSR1 = '"+__cUserId+"' "	// Usuário logado no Sistema
				cQry += "   AND ZS_FILIAL = '"+xFilial("SZS")+"'"

				TCQUERY cQry NEW ALIAS "QZS"

				While !Eof()
					For iQ := 1 To Len(aSC6Recno)
						DbSelectArea("SUB")
						DbGoto(aSC6Recno[iQ])
						//cC6XAlcada	:= SUB->UB_XALCADA
						//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO+"#","")
						//cC6XAlcada 	:= StrTran(cC6XAlcada,QZS->ZS_MOTIVO,"")
						//cC6XAlcada 	:= StrTran(cC6XAlcada,"|","")
						RecLock("SUB",.F.)
						//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
						//SUB->UB_XALCADA	:= cC6XAlcada
						SUB->UB_XALCADA	:= sfMotAlc(SUB->UB_XALCADA,QZS->ZS_MOTIVO)
						// Se já existir alguma alçada do item apenas concatena alçada
						If !Empty(SUB->UB_XLIBALC)
							// Se o liberador não constar ainda na lista
							If !(__cUserId $ SUB->UB_XLIBALC )
								cAuxAlc			:= Alltrim(SUB->UB_XLIBALC)
								SUB->UB_XLIBALC	:= cAuxAlc+"#"+__cUserId
							Endif
						Else
							SUB->UB_XLIBALC	:= SUA->UA_CLIENTE+"|"+SUA->UA_LOJA+"|"+SUA->UA_CONDPG+"|"+SUB->UB_PRODUTO+"|"+SUB->UB_TES+"|"+ cValToChar(SUB->UB_QUANT)+"|"+ cValToChar(SUB->UB_VRUNIT) + "|" + __cUserId
						Endif
						If Empty(SUB->UB_XALCADA)
							SUB->UB_XPRCMIN	:= SUB->UB_VRUNIT
							SUB->UB_XPRCMAX	:= SUB->UB_VRUNIT
						Endif
						MsUnlock()
					Next
					lLib	:= .T.
					DbSelectArea("QZS")
					DbSkip()
				Enddo
				QZS->(DbCloseArea())
			Endif
		Endif

		/* Trecho desativado por que as alçadas precisam existir na SZS 
		If !lLib
			For iQ := 1 To Len(aSC6Recno)
				DbSelectArea("SUB")
				DbGoto(aSC6Recno[iQ])
				cC6XAlcada	:= SUB->UB_XALCADA
				cC6XAlcada 	:= StrTran(cC6XAlcada,"#","")
				cC6XAlcada 	:= StrTran(cC6XAlcada,"|","")
				RecLock("SUB",.F.)
				//Cliente | Loja | Cond Pagamento | Produto | Quantidade | Preço | Alçada | Aprovador
				SUB->UB_XALCADA	:= cC6XAlcada
				// Se já existir alguma alçada do item apenas concatena alçada
				If !Empty(SUB->UB_XLIBALC)
					// Se o liberador não constar ainda na lista
					If !(__cUserId $ SUB->UB_XLIBALC )
						cAuxAlc			:= Alltrim(SUB->UB_XLIBALC)
						SUB->UB_XLIBALC	:= cAuxAlc+"#"+__cUserId
					Endif
				Else
					SUB->UB_XLIBALC	:= SUA->UA_CLIENTE+"|"+SUA->UA_LOJA+"|"+SUA->UA_CONDPG+"|"+SUB->UB_PRODUTO+"|"+SUB->UB_TES+"|"+ cValToChar(SUB->UB_QUANT)+"|"+ cValToChar(SUB->UB_VRUNIT) + "|" + __cUserId
				Endif
				If Empty(SUB->UB_XALCADA)
					SUB->UB_XPRCMIN	:= SUB->UB_VRUNIT
					SUB->UB_XPRCMAX	:= SUB->UB_VRUNIT
				Endif
				MsUnlock()
			Next
		Endif
		*/

		// Percorro todos os itens do orçamento para ver se tem pendencia de alçadas ou não
		For iQ := 1 To Len(aSC6Recno)
			DbSelectArea("SUB")
			DbGoto(aSC6Recno[iQ])
			If !Empty(SUB->UB_XALCADA)
				cCtrlAlc	+= "Produto: " + SUB->UB_PRODUTO + " Alçada "+SUB->UB_XALCADA + Chr(13) + Chr(10)
				MsgAlert("Item "+SUB->UB_ITEM+"-"+SUB->UB_PRODUTO+" não foi liberado. Pendência de alçada "+SUB->UB_XALCADA,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação")
				lRet	:= .F.
			Endif
		Next

		// Não havendo nenhuma restrição de alçadas pendente
		If Empty(cCtrlAlc)
			U_BFFATA35("O"/*cZ9ORIGEM*/,cPedido/*cZ9NUM*/,"4"/*cZ9EVENTO*/,"Orçamento TeleVendas Liberado - Alçada manual "/*cZ9DESCR*/,""/*cZ9DEST*/,__cUserId/*cZ9USER*/)		
		Endif

	Endif
Return lRet



/*/{Protheus.doc} sfMotAlc
//Função que remove corretamente os bloqueios de alçadas 
@author Marcelo Alberto Lauschner 
@since 29/06/2018
@version 1.0
@return cReturn 	, characters, String com a alçada final podendo ser vazia. Para os dois exemplos de parametro abaixo o retorno será "A3#E9#E4#"
@param 	cInAlcadas	, characters, Lista de motivos de bloqueios. Exemplo "A3#B9#E9#E4"
@param 	cInMotOk	, characters, Código do Motivo que será removido. Exemplo "B9". 
@type function
/*/
Static Function sfMotAlc(cInAlcadas,cInMotOk)
	
	Local	cRetAlcada	:= ""
	Local	nLenItem	:= 0
	Local	aItem		:= {}
	Local	iZ 
	Local	lRecursivo	:= .F. 
	//Len(aItem)
	cInAlcadas	:= StrTran(cInAlcadas,"|","")
	If "#" $ cInAlcadas
		aItem		:= StrTokArr(cInAlcadas+"#","#")
		nLenItem	:= Len(aItem)
		
		For iZ := 1 To nLenItem
			If aItem[iZ] == cInMotOk
				aDel(aItem,iZ)
				aSize(aItem,nLenItem-1)
				nLenItem	:= Len(aItem)
				lRecursivo	:= .T. 
				Exit
			Endif
		Next
		For iZ := 1 To Len(aItem)
			If !Empty(aItem[iZ])
				cRetAlcada	+= aItem[iZ]+"#"
			Endif
		Next
		If lRecursivo
			cRetAlcada	:= sfMotAlc(cRetAlcada,cInMotOk)		
		Endif
	ElseIf !Empty(cInAlcadas)
		For iZ := 1 To Len(cInAlcadas) Step 2 
			cRetAlcada	+= Substr(cInAlcadas,iZ,2) + "#"
		Next
		cRetAlcada	:= sfMotAlc(cRetAlcada,cInMotOk)	
	Endif
				
Return cRetAlcada

