#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFFATM23
(Rotina para liberação automática de estoque )
@author MarceloLauschner
@since 04/11/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATM23(aInParam,lAuto)



	Local 		aOpenTable 	:= {"SA1","SC9","SC5","SA3"}
	Local		cInEmp
	Local		cInFil
	Default	lAuto			:= .F.
	
	If lAuto .And. aInParam[1] $ "14" // Verifica para ser executado somente na empresa 02 e 11
		RPCSetType(3)
		RPCSetEnv(aInParam[1],aInParam[2],"","","","",aOpenTable) // Abre todas as tabelas.
		Sleep(10000)
		sfExec()
		RpcClearEnv() // Limpa o environment
		Return
	Endif
	
	// Verifica se é via Schedule
	If Select("SM0") == 0
		
		RPCSetType(3)
		RPCSetEnv("14","01","","","","",aOpenTable) // Abre todas as tabelas.
		Sleep(10000)
		sfExec()
		RpcClearEnv() // Limpa o environment
		
		
		RPCSetType(3)
		RPCSetEnv("14","02","","","","",aOpenTable) // Abre todas as tabelas.
		Sleep(10000)
		sfExec()
		RpcClearEnv() // Limpa o environment

		RPCSetType(3)
		RPCSetEnv("14","03","","","","",aOpenTable) // Abre todas as tabelas.
		Sleep(10000)
		sfExec()
		RpcClearEnv() // Limpa o environment

		RPCSetType(3)
		RPCSetEnv("14","04","","","","",aOpenTable) // Abre todas as tabelas.
		Sleep(10000)
		sfExec()
		RpcClearEnv() // Limpa o environment
		
		
	ElseIf cEmpAnt $ "14"
		If MsgYesNo("Deseja rodar o processo de liberação automática de estoques?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			sfExec()
		Endif
	Endif
	
Return

/*/{Protheus.doc} sfExec
(Execução do processo )
@author MarceloLauschner
@since 04/11/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExec()
	
	Local	cQry		:= ""
	Local 	nVlrCred 	:= 0
	Local	nQteBkNew	:= 0
	Local	nQteBlq	:= 0
	Local	cC9BLINF	:= ""
	Local	cC9FLGENVI	:= ""
	Local	dC9LIBFAT	:= CTOD("")
	Local	cSendMail	:= ""
	Local	cAssunto	:= ""
	Local	cBody		:= ""
	Local	aBlckSC9	:= {|| SC9->C9_BLINF := cC9BLINF,SC9->C9_FLGENVI := cC9FLGENVI,SC9->C9_LIBFAT := dC9LIBFAT}

	If cEmpAnt == "14"
		aBlckSC9	:= {|| SC9->C9_BLINF := cC9BLINF,SC9->C9_FLGENVI := cC9FLGENVI,SC9->C9_LIBFAT := dC9LIBFAT  }
	Endif 
	// Permite o impedimento da execução da rotina caso seja necessário por meio de parametro
	If !(GetNewPar("BF_FTM23EX",.F.))
		Return 
	Endif
	
	
	
	cQry := "SELECT C9_PEDIDO,C9_CLIENTE,COUNT(*) NBLQ,SUM(CASE WHEN C9_BLCRED =  '  ' THEN 0 ELSE 1 END ) NCRED"
	cQry += "  FROM "+RetSqlName("SC9") + " C9 ,"+RetSqlName("SC5") + " C5 "
	cQry += " WHERE C9_BLEST NOT IN('  ','10') "
	cQry += "   AND C9_BLCRED NOT IN('10') "	
	cQry += "   AND (SELECT SUM(B2_QATU-B2_RESERVA) "
	cQry += "          FROM "+RetSqlName("SB2")
	cQry += "         WHERE D_E_L_E_T_ = ' ' "
	cQry += "           AND B2_LOCAL = C9_LOCAL "
	cQry += "           AND B2_COD = C9_PRODUTO "
	cQry += "           AND B2_FILIAL = '"+ xFilial("SB2") + "' ) > 0 "
	cQry += "   AND C5.D_E_L_E_T_ = ' '"
	cQry += "   AND C5_NUM = C9_PEDIDO "
	cQry += "   AND C5_FILIAL = '" + xFilial("SC5") + "'"
	cQry += "   AND C9.D_E_L_E_T_ =' ' "
    cQry += "   AND C9_NFISCAL = ' ' "
	cQry += "   AND C9_SERIENF = ' ' "
	cQry += "   AND C9_LIBFAT = ' ' "
	cQry += "   AND C9_FILIAL = '"+xFilial("SC9")+"' "
	cQry += " GROUP BY C9_PEDIDO,C9_CLIENTE "
	// Garante que somente pedidos não faturados e sem bloqueio nenhum de crédito sejam avaliados 
	cQry += " HAVING SUM(CASE WHEN C9_BLCRED =  '  ' THEN 0 ELSE 1 END ) <= 0"
	cQry += " ORDER BY C9_PEDIDO "
	
	TcQuery cQry New Alias "QC9"
	
	While QC9->(!Eof())
		
		// Efetua a liberação do Semaforo do pedido
		If sfChekLock(.T.,"BFFATM23_"+QC9->C9_PEDIDO)
		
			cQry := "SELECT C9.R_E_C_N_O_ C9RECNO,C9_PEDIDO,C9_LOCAL,C9_QTDLIB,C9_ITEM,C9_SEQUEN,C9_PRODUTO,C9_XWMSEDI,C9_XWMSPED,C9_BLINF,C9_FLGENVI,C9_LIBFAT,C9_XWMSQTE,C9_ORDSEP,B2_QATU,B2_RESERVA"
			cQry += "  FROM " + RetSqlName("SC9") + " C9," +RetSqlName("SB2") + " B2 "
			cQry += " WHERE B2.D_E_L_E_T_ = ' ' "
			cQry += "   AND B2_QATU-B2_RESERVA > 0"
			cQry += "   AND B2_LOCAL = C9_LOCAL "
			cQry += "   AND B2_COD = C9_PRODUTO "
			cQry += "   AND B2_FILIAL = '"+xFilial("SB2")+"' "
			cQry += "   AND C9.D_E_L_E_T_ = ' ' "
			cQry += "   AND C9_NFISCAL = '  ' "
			cQry += "   AND C9_BLEST NOT IN('  ','10') "
			cQry += "   AND C9_BLCRED = '  ' "
			cQry += "   AND C9_LIBFAT = ' ' "  // Não enviado para Expedição
			cQry += "   AND C9_CLIENTE = '"+QC9->C9_CLIENTE+"' "
			cQry += "   AND C9_PEDIDO =  '" +QC9->C9_PEDIDO+"' "
			cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
			cQry += " ORDER BY C9_ITEM,C9_SEQUEN "
			
			TCQUERY cQry NEW ALIAS "QRC9"
			
			While QRC9->(!Eof())
				
				
				nQteBlq 	:= QRC9->C9_QTDLIB
				
				DbSelectArea("SB2")
				DbSetOrder(1)
				DbSeek(xFilial("SB2")+QRC9->C9_PRODUTO+QRC9->C9_LOCAL)
				
				nQteBkNew	:= SB2->B2_QATU - SB2->B2_RESERVA
				
				nQteBkNew	:= IIf(nQteBkNew > nQteBlq,nQteBlq,nQteBkNew) // Garante que não exceda a quantidade do item
				
				// 11/09/2015 - Verifica se é produto Granel para que não haja liberação parcial
				If QRC9->C9_PRODUTO $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")
					// Se o inteiro da divisão for o mínimo para 1 unidade não libera
					If (nQteBkNew/159) < 1
						nQteBkNew	:= 0
					Endif
				Endif
				 
				// Existindo saldo de estoque para liberar o item
				If nQteBkNew > 0 
					DbSelectArea ("SC9")
					DbGoto(QRC9->C9RECNO) 
					If !Eof()
					//DbSetOrder(1)
					//If DbSeek(xfilial("SC9")+QRC9->C9_PEDIDO+QRC9->C9_ITEM+QRC9->C9_SEQUEN+QRC9->C9_PRODUTO)
						cC9BLINF	:= SC9->C9_BLINF
						cC9FLGENVI	:= SC9->C9_FLGENVI
						dC9LIBFAT	:= SC9->C9_LIBFAT
						
						
						// Executa Estorno do Item
						SC9->(A460Estorna(/*lMata410*/,/*lAtuEmp*/,@nVlrCred))
						// Cad. item do pedido de venda
						DbSelectArea("SC6")
						SC6->(DbSetOrder(1))
						SC6->(DbSeek(xFilial("SC6")+QRC9->C9_PEDIDO+QRC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM
						
						// Se a quantidade conferida for maior que zero -- evita que quantidades zeradas possam ser liberadas.
						If nQteBkNew > 0	// Garante que o Flag de separação vá para o novo item liberado
							// ³ExpN1: Registro do SC6                                      ³±±
							// ³ExpN2: Quantidade a Liberar                                 ³±±
							// ³ExpL3: Bloqueio de Credito                                  ³±±
							// ³ExpL4: Bloqueio de Estoque                                  ³±±
							// ³ExpL5: Avaliacao de Credito                                 ³±±
							// ³ExpL6: Avaliacao de Estoque                                 ³±±
							// ³ExpL7: Permite Liberacao Parcial   
							// ³ExpL8: Tranfere Locais automaticamente                      ³±±
							// ³ExpA9: Empenhos ( Caso seja informado nao efetua a gravacao ³±±
							// ³       apenas avalia ).                                     ³±±
							// ³ExpbA: CodBlock a ser avaliado na gravacao do SC9           ³±±
							
							MaLibDoFat(SC6->(RecNo()),;
										nQteBkNew,;
										.T. /*lCredito*/,;
										.T. /*lEstoque*/,;
										.F. /*lAvCred*/,;
										.T. /*lAvEst*/,;
										.F. /*lLibPar*/,;
										.F. /*lTrfLocal*/,;
										/*aEmpenho*/,;
										aBlckSC9/*bBlock*/,;
										/*aEmpPronto*/,;
										/*lTrocaLot*/,;
										/*lOkExpedicao*/,;
										0/*nVlrCred*/,;
										/*nQtdalib2*/)
						Endif
						// A quantidade não separada é liberada com bloqueio de estoque
						nQteBlq	-= nQteBkNew
						If nQteBkNew > 0 .And. nQteBlq > 0
							MaLibDoFat(SC6->(RecNo()),;
										nQteBlq,;
										.T./*lCredito*/,;
										.F./*lEstoque*/,;
										.F./*lAvCred*/,;
										.F./*lAvEst*/,;
										.F./*lLibPar*/,;
										.F./*lTrfLocal*/,;
										/*aEmpenho*/,;
										aBlckSC9/*bBlock*/,;
										/*aEmpPronto*/,;
										/*lTrocaLot*/,;
										/*lOkExpedicao*/,;
										0/*nVlrCred*/,;
										/*nQtdalib2*/)
						Endif
						SC6->(MaLiberOk({QRC9->C9_PEDIDO},.F.))
						
						U_GMCFGM01("LE",;
						QRC9->C9_PEDIDO,;
						"Liberação parcial e automática do Produto "+QRC9->C9_PRODUTO +" Qte liberada: "+Alltrim(Str(nQteBkNew)) +" Qte bloqueada: "+Alltrim(Str(nQteBlq)),;
						FunName(),;
						,;
						,;
						.T.)
						DbSelectArea("SC5")
						DbSetOrder(1)
						DbSeek(xFilial("SC5")+QRC9->C9_PEDIDO)
						DbSelectArea("SA3")
						DbSetOrder(1)
						DbSeek(xFilial("SA3")+SC5->C5_VEND1)
						cSendMail	:= U_BFFATM15(SA3->A3_EMTMK,"BFFATM23")
						//cRecebe, cAssunto, cMensagem, lExibSend, cArqAttAch, cAttachName )
						cAssunto	:= "Alteração de quantidade em pedido liberado "+QRC9->C9_PEDIDO + " "+cFilAnt+" "+SM0->M0_NOME
						cBody		:= "Produto "+QRC9->C9_PRODUTO +" Qte liberada: "+Alltrim(Str(nQteBkNew)) +" Qte bloqueada: "+Alltrim(Str(nQteBlq))+Chr(13)+Chr(10)+"Motivo: Liberação automática!" 
						U_WFGERAL(cSendMail,cAssunto,cBody)
					Endif
				Endif
				DbSelectArea("QRC9")
				DbSkip()
			Enddo
			QRC9->(DbCloseArea())
			
			cQry := ""
			cQry += "SELECT C6_NUM,C5_EMISSAO,C6_PRODUTO,C6_QTDVEN "
	  		cQry += "  FROM ( "
	  		cQry += "SELECT C6_NUM,"
	  		cQry += "       C5_EMISSAO, "
	  		cQry += "       C6_PRODUTO,"
	  		cQry += "       C6_QTDVEN,"
	  		cQry += "       C6_QTDENT,"
	  		cQry += "       C6_BLQ,"
	  		cQry += "       ISNULL((SELECT SUM(C9_QTDLIB) "
	  		cQry += "             FROM "+RetSqlName("SC9") + " C9 "
	  		cQry += "            WHERE C9.D_E_L_E_T_ = ' ' "
	  		cQry += "              AND C9_PRODUTO = C6_PRODUTO "
	  		cQry += "              AND C9_ITEM = C6_ITEM "
	  		cQry += "              AND C9_PEDIDO = C5_NUM "
	  		cQry += "              AND C9_FILIAL = '"+xFilial("SC9")+"' ),"
	  		cQry += "           0) C9_QTDLIB "
	  		cQry += "  FROM "+RetSqlName("SC6")+" C6,"+RetSqlName("SC5")+ " C5 "
	  		cQry += " WHERE C6.D_E_L_E_T_ = ' ' "
	  		cQry += "   AND C6_NUM = C5_NUM "
	  		cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
	  		cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	  		cQry += "   AND C5_NUM = '"+QC9->C9_PEDIDO+"' "
	  		cQry += "   AND C5_FILIAL = '"+xFilial("SC5")+"') TBL "
	  		cQry += " WHERE C9_QTDLIB > C6_QTDVEN "
	  		cQry += "   AND C9_QTDLIB <> 0 "
			
			TCQUERY cQry NEW ALIAS "QER9"
			
			If !Eof()
				cSendMail	:= U_BFFATM15("marcelo@centralxml.com.br","BFFATM23")
				U_WFGERAL(cSendMail,"Erro de liberação de estoque Filial: "+cFilAnt + " - Pedido: " +QC9->C9_PEDIDO,;
				"Erro de liberação de estoque Filial: "+cFilAnt + " - Pedido: " +QC9->C9_PEDIDO+ " Produto "+QER9->C6_PRODUTO,"BFFATM23")
			Endif
			QER9->(DbCloseArea())
		Endif 
		// Efetua a liberação do Semaforo do pedido
		sfChekLock(.F.,"BFFATM23_"+QC9->C9_PEDIDO)
		
		DbSelectArea("QC9")
		DbSkip()
	Enddo
	QC9->(DbCloseArea())
	
	
Return




/*/{Protheus.doc} sfChekLock
(long_description)
@type function
@author Marcelo Alberto Lauschner
@since 13/03/2017
@version 1.0
@return logico
@example
(examples)
@see (links_or_references)
/*/
Static Function sfChekLock(lLock,cKeyLock)

	Local	nTentativas	:= 0

	If lLock

		cFTM23US := GetNewPar("BF_FTM23US","000002")

		While !LockByName(cKeyLock,.F.,.F.,.T.)
			
			Sleep(1000)
			
			FwLogMsg('INFO', , 'MYEMAIL', ProcName(), '', cEmpAnt, "Semaforo de processamento... tentativa "+ALLTRIM(STR(nTentativas)), "Lock "+cKeyLock+" em uso por outro usuário." , 0, 0, {})
			
			nTentativas++

			If nTentativas > 2
				// Se for o Administrador força a liberação do bloqueio
				If __cUserId $ cFTM23US 
				//	If MsgYesNo("Não foi possível acesso exclusivo para rotina de envio de pedidos. Forçar acesso mesmo assim ?")
					UnLockByName(cKeyLock,.F.,.F.,.T.)
					Return .T.
				//	Endif

				//	If !MsgYesNo("Lock "+cKeyLock+" em uso por outro usuário. Tentar novamente?")
				//		Return .F.
				//	Endif 
				//	nTentativas := 0
				//	Loop
				Else
					Return(.F.)
				EndIf
			EndIf
		EndDo

	Else
		UnLockByName(cKeyLock,.F.,.F.,.T.)
	Endif

Return .T.

