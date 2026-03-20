#INCLUDE "totvs.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} BIG012
Função que busca os pedidos pendentes por filial e dispara para o supervisor via e-mail
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 3/5/2014
/*/
User Function BIG012()

	Local aOpenTable := {"SC5","SA3","SC9","SA1","SE4","SA4","PAB","SB1","SB2","SC6"}
	local aEmpFil    := {} as array
	local nX := 0 as numeric
	local aIniEmp    := { "14","01" }

	If Select("SM0") == 0
		RPCSetType(3)
		RPCSetEnv( aIniEmp[01],aIniEmp[02],"","","","",{}) // Abre todas as tabelas.
		aEmpFil := FWLoadSM0( )
		RpcClearEnv() // Limpa o environment
		If len( aEmpFil )
			For nX := 1 to len( aEmpFil )
				If aEmpFil[nX][1] == "14"
					RPCSetType(3)
					RPCSetEnv( aEmpFil[nX][1],aEmpFil[nX][5] ,"","","","",aOpenTable) // Abre todas as tabelas.
					If GetNewPar("BR_BIG12EX",.T.)
						stExecuta()
					Endif
					RpcClearEnv() // Limpa o environment
				Endif
			Next nX
		Endif

	Else
		If !MsgNoYes("Deseja realmente rodar as pendencias??",'Está certo(a) disso?')
			Return
		Endif
		stExecuta()
	Endif


Static Function stExecuta

	Private oHtml
	Private oProcess
	Private nSCrd := 0.00
	Private nTCrd := 0.00
	Private nSBle := 0.00
	Private nTBle := 0.00
	Private nSok  := 0.00
	Private nTok  := 0.00
	Private nSpend := 0.00
	Private nTpend := 0.00
	Private nTotPed := 0.00
	Private nNf    := 0
	Private _Rodape := .F.
	Private nContaped := 0

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	cQry := ""
	cQry += "SELECT "
	cQry += "       (SELECT "
	cQry += "          CASE WHEN TRIM(A3_MENS1) <> '' THEN CONCAT(TRIM(A3_MENS1),';', TRIM(A3_MENS2)) ELSE TRIM(A3_MENS2) END "
	cQry += "          FROM "+ RetSqlName("SA3") + " V2 "
	cQry += "         WHERE V2.D_E_L_E_T_ = ' ' "
	cQry += "           AND V2.A3_COD = SC5.C5_VEND1 "
	cQry += "           AND V2.A3_FILIAL = '" + xFilial("SA3") + "' ) AS EMAIL_SUPERVISOR , "
	cQry += "       (SELECT MAX(P.PAB_ROTA) "
	cQry += "          FROM "+ RetSqlName("PAB") + " P "
	cQry += "         WHERE P.D_E_L_E_T_ = ' ' "
	cQry += "           AND P.PAB_CEP = SA1.A1_CEP "
	cQry += "           AND P.PAB_FILIAL = '" + xFilial("PAB") + "' ) AS PAB_ROTA, "
	cQry += "       (SELECT A4_NREDUZ "
	cQry += "          FROM "+ RetSqlName("SA4") + " T "
	cQry += "         WHERE T.D_E_L_E_T_ = ' ' "
	cQry += "           AND T.A4_COD = SC5.C5_TRANSP "
	cQry += "           AND T.A4_FILIAL = '" + xFilial("SA4") + "') AS T_TRANSP, "
	cQry += "       C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_ITEM,C9_SEQUEN,C9_PRODUTO,C9_FLGENVI,C9_QTDLIB,C9_PRCVEN,C9_BLEST,C9_BLCRED,C9_NFISCAL,C6_QTDVEN, "
	cQry += "       B2_QATU, "
	cQry += "       (SELECT SUM(C6_VALOR) "
	cQry += "          FROM "+ RetSqlName("SC6") + " SC6 "
	cQry += "         WHERE SC6.D_E_L_E_T_ = ' ' "
	cQry += "           AND SC6.C6_NUM = SC9.C9_PEDIDO "
	cQry += "           AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' )AS TOTALPED, "
	cQry += "        V1.A3_NREDUZ AS V1_NREDUZ,SC5.C5_VEND1,SC5.C5_VEND2,SC5.C5_LOJACLI,SC5.C5_TABELA,SC5.C5_CONDPAG,SC5.C5_TRANSP,SC5.C5_EMISSAO,SC5.C5_DTPROGM,"
	cQry += "        SC5.C5_MSGINT,SC5.C5_MENNOTA, V1.A3_EMAIL AS EMAILV, V1.A3_SUPER AS SUPERV, "
	cQry += "        SB1.B1_COD,SB1.B1_DESC,SB1.B1_UM,SB1.B1_LOCAL, "
	cQry += "        SE4.E4_DESCRI, "
	cQry += "        SA1.A1_NOME,SA1.A1_DDD,SA1.A1_TEL,SA1.A1_CONTATO,SA1.A1_MUN,SA1.A1_CEP,SA1.A1_ROTA,SA1.A1_OBSCLI "
	cQry += "   FROM "+ RetSqlName("SC9") + " SC9, "+ RetSqlName("SC6") + " SC6, "+ RetSqlName("SC5") + " SC5, "+ RetSqlName("SB1") + " SB1, "+ RetSqlName("SB2") + " SB2, "
	cQry += RetSqlName("SE4") + " SE4, "+RetSqlName("SA1") + " SA1, "+RetSqlName("SA3") + " V1 "
	cQry += "  WHERE V1.D_E_L_E_T_ = ' ' "
	cQry += "    AND V1.A3_COD = SC5.C5_VEND1 "
	cQry += "    AND V1.A3_FILIAL = '" + xFilial("SA3") + "' "
	cQry += "    AND SA1.D_E_L_E_T_ = ' ' "
	cQry += "    AND SA1.A1_LOJA = SC9.C9_LOJA "
	cQry += "    AND SA1.A1_COD = SC9.C9_CLIENTE "
	cQry += "    AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	cQry += "    AND SE4.D_E_L_E_T_ = ' ' "
	cQry += "    AND SE4.E4_CODIGO = SC5.C5_CONDPAG "
	cQry += "    AND SE4.E4_FILIAL = '" + xFilial("SE4") + "' "
	cQry += "    AND SB1.D_E_L_E_T_ = ' ' "
	cQry += "    AND SB1.B1_COD = SC9.C9_PRODUTO "
	cQry += "    AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry += "    AND SB2.D_E_L_E_T_ = ' ' "
	cQry += "    AND SB2.B2_LOCAL = C9_LOCAL "
	cQry += "    AND SB2.B2_COD = SC9.C9_PRODUTO "
	cQry += "    AND SB2.B2_FILIAL = '" + xFilial("SB2") + "' "
	cQry += "    AND SC5.D_E_L_E_T_ = ' ' "
	cQry += "    AND SC5.C5_NUM = SC9.C9_PEDIDO  "
	cQry += "    AND SC5.C5_TIPO = 'N'  "
	cQry += "    AND SC5.C5_FILIAL = '" + xFilial("SC5") +"' "
	cQry += "    AND SC6.D_E_L_E_T_ = ' ' "
	cQry += "    AND SC6.C6_PRODUTO = SC9.C9_PRODUTO "
	cQry += "    AND SC6.C6_ITEM = SC9.C9_ITEM "
	cQry += "    AND SC6.C6_NUM = SC9.C9_PEDIDO "
	cQry += "    AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' "
	cQry += "    AND SC9.D_E_L_E_T_ = ' ' "
	cQry += "    AND SC9.C9_SEQCAR = ' ' "
	cQry += "    AND SC9.C9_CARGA = ' ' "
	cQry += "    AND SC9.C9_NFISCAL = ' ' "
	cQry += "    AND SC9.C9_SERIENF = ' ' "
	cQry += "    AND SC9.C9_FILIAL = '" + xFilial("SC9") + "' "
	cQry += "  ORDER BY SC5.C5_VEND1,SC5.C5_VEND2,SC9.C9_CLIENTE,SC9.C9_LOJA,SC9.C9_PEDIDO,SC9.C9_ITEM,SC9.C9_SEQUEN "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRA', .F., .T.)

	cEmSup			:= ""
	cVend_tmk   	:= ""
	cPedido     	:= ""
	cPed			:= ""
	cMennota    	:= ""
	cMsgInt     	:= ""
	cObscli		:= ""
	cCondPag		:= ""
	nTotPed     	:= 0.00

	While !Eof()
		IncProc("Processando.."+QRA->C5_VEND1 + "/"+ QRA->C5_VEND2 + "/" + QRA->C9_PEDIDO )

		If nContaped > 10
			sfEnvWF(cEmSup)
			nContaped :=0
			_AbreWork(QRA->C5_VEND1 + "-"+QRA->V1_NREDUZ,cEmpAnt)
			_Rodape := .F.
		Endif

		If cVend_tmk <> QRA->C5_VEND1 + QRA->C5_VEND2

			If !Empty(cVend_tmk)
				nContaped :=0
				sfRodape(cMennota,cMsgInt,cObscli,cPed,cCondPag,nTotped)
				sfEnvWF(cEmSup)
				nTCrd := 0.00
				nTBle := 0.00
				nTok  := 0.00
				nTpend := 0.00
			Endif
			nContaped :=0
			_AbreWork(QRA->C5_VEND1 + "-"+QRA->V1_NREDUZ,cEmpAnt)
			_Rodape := .F.

		Endif

		If cPedido <> QRA->C5_VEND1 + QRA->C5_VEND2 + QRA->C9_PEDIDO
			nContaped++
			If !Empty(_Rodape)
				sfRodape(cMennota,cMsgInt,cObscli,cPed,cCondPag,nTotPed)
			Endif
			nSCrd := 0.00
			nSBle := 0.00
			nSok  := 0.00
			nSpend := 0.00
			nNf    := 0

			sfCabPed()
			_Rodape := .T.
		Endif

		sfAddItens()



		cVend_tmk 	:= QRA->C5_VEND1 + QRA->C5_VEND2
		cPedido   	:= QRA->C5_VEND1 + QRA->C5_VEND2 + QRA->C9_PEDIDO
		cPed      	:= QRA->C9_PEDIDO
		cMennota  	:= QRA->C5_MENNOTA
		cMsgInt   	:= QRA->C5_MSGINT
		cObscli		:= QRA->A1_OBSCLI
		cCondPag	:= QRA->C5_CONDPAG
		nTotPed 	:= QRA->TOTALPED

		cEmSup 		:= Alltrim(QRA->EMAIL_SUPERVISOR)     //Alimenta variavel com email do supervisor

		Dbselectarea("QRA")
		Dbskip()
	Enddo

	If !Empty(cPedido)
		sfRodape(cMenNota,cMsgInt,cObsCli,cPed,cCondPag,nTotPed)
	Endif

	If !Empty(cVend_tmk)
		sfEnvWF(cEmSup)
	Endif

	QRA->(dbCLoseArea())


Return


Static Function _AbreWork(cVend1,cCodEmp)
	
	// Cria um novo processo...
	cProcess := "100002"
	cStatus  := "100002"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Envio diário pendência de pedidos"))
	//Abre o HTML criado
	oProcess:NewTask(cStatus,"\workflow\pendencia_tmk.htm")

	oProcess:cSubject := "Pendência por vendedor -->>"+cVend1
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML

	oHtml:ValByName("empresa" ,"Empresa-> "+AllTrim(FWFilialName(cEmpAnt,cFilAnt,1)))


Return


Static Function sfCabPed()

	Local 	x
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica da de entrega                                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCEP		:= QRA->A1_CEP
	nDiaAtu  := 0
	nDiaEnt  := 0
	dData    := dDataBase
	aRota    := {}
	aDias    := {1,2,3,4,5,6,7}


	If !Empty(QRA->PAB_ROTA)
		For x := 1 To Len(AllTrim(QRA->PAB_ROTA)) Step 1
			AADD(aRota,{SubStr(QRA->PAB_ROTA,x,1)})
		Next
	Endif

	IF !Empty(QRA->A1_ROTA)
		For x := 1 To Len(AllTrim(QRA->A1_ROTA)) Step 1
			AADD(aRota,{SubStr(QRA->A1_ROTA,x,1)})
		Next
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
	nEnvns := 0
	nNf 	:= 0
	dbSelectArea("SC9")
	dbsetorder(1)
	dbSeek(xFilial("SC9")+QRA->C9_PEDIDO)
	While !Eof() .And. SC9->C9_PEDIDO == QRA->C9_PEDIDO .And. SC9->C9_ITEM >= "01"

		If Empty(SC9->C9_NFISCAL) .And. Empty(SC9->C9_BLEST) .And. Empty(SC9->C9_BLCRED) .And. !Empty(SC9->C9_LIBFAT)
			nEnvns:= nEnvns + 1
		else
			nEnvns := nEnvns + 0
		Endif
		IF SC9->C9_NFISCAL <> " "
			nNf := nNf + 1
		else
			nNf := nNf + 0
		Endif
		dbSelectArea("SC9")
		dbSkip()
	Enddo



	AAdd((oHtml:ValByName("l.colu1" )),"NºPed:")
	If nEnvns == 0
		AAdd((oHtml:ValByName("l.colu2" )),'<font size=2 color=#FF0000 >'+transform(QRA->C9_PEDIDO,"@E 999999")+'</font>')
	Else
		AAdd((oHtml:ValByName("l.colu2" )),'<font size=2 color=#0033CC >'+transform(QRA->C9_PEDIDO,"@E 999999")+"Enviado"+'</font>')
	Endif
	AAdd((oHtml:ValByName("l.colu3" )),QRA->C9_CLIENTE + "/" +QRA->C9_LOJA + " - " + QRA->A1_NOME )
	AAdd((oHtml:ValByName("l.colu4" ))," ")
	AAdd((oHtml:ValByName("l.colu5" )),"Tab:")
	AAdd((oHtml:ValByName("l.colu6" )),QRA->C5_TABELA)
	AAdd((oHtml:ValByName("l.colu7" )),"Cond:")
	AAdd((oHtml:ValByName("l.colu8" )),QRA->C5_CONDPAG)
	AAdd((oHtml:ValByName("l.colu9" )),'<font color=#0000FF >'+alltrim(QRA->E4_DESCRI)+'</font>')
	AAdd((oHtml:ValByName("l.colu10" )),QRA->V1_NREDUZ)
	AAdd((oHtml:ValByName("l.colu11" ))," ")

	AAdd((oHtml:ValByName("l.colu1" )),"DDD: "+QRA->A1_DDD)
	AAdd((oHtml:ValByName("l.colu2" )),"Fone: "+QRA->A1_TEL)
	AAdd((oHtml:ValByName("l.colu3" )),QRA->A1_CONTATO +" - " +QRA->A1_MUN)
	AAdd((oHtml:ValByName("l.colu4" ))," ")
	AAdd((oHtml:ValByName("l.colu5" ))," ")
	AAdd((oHtml:ValByName("l.colu6" ))," ")
	AAdd((oHtml:ValByName("l.colu7" )),QRA->PAB_ROTA)
	AAdd((oHtml:ValByName("l.colu8" )),QRA->C5_TRANSP)
	AAdd((oHtml:ValByName("l.colu9" )),QRA->T_TRANSP)
	AAdd((oHtml:ValByName("l.colu10" )),dData)
	If date() = dData
		AAdd((oHtml:ValByName("l.colu11" )),'<font color =#006600 >'+"ROTA"+'</font>')
	Else
		AAdd((oHtml:ValByName("l.colu11" )),'<font color =#FF0000 >'+"NÃO É ROTA"+'</font>')
	Endif



	AAdd((oHtml:ValByName("l.colu1" ))," ")
	AAdd((oHtml:ValByName("l.colu2" )),STOD(QRA->C5_EMISSAO))
	AAdd((oHtml:ValByName("l.colu3" )),STOD(QRA->C5_DTPROGM))
	AAdd((oHtml:ValByName("l.colu4" ))," ")
	AAdd((oHtml:ValByName("l.colu5" ))," ")
	AAdd((oHtml:ValByName("l.colu6" ))," ")
	AAdd((oHtml:ValByName("l.colu7" ))," ")
	AAdd((oHtml:ValByName("l.colu8" ))," ")
	IF  nNf >= 1
		AAdd((oHtml:ValByName("l.colu9" )),'<font color =#FF0000 >'+"SALDO PEDIDO"+'</font>')
	ELSE
		AAdd((oHtml:ValByName("l.colu9" )),'<font color =#FF0000 >'+"PEDIDO NOVO"+'</font>')
	Endif
	AAdd((oHtml:ValByName("l.colu10" ))," ")
	AAdd((oHtml:ValByName("l.colu11" ))," ")



	AAdd((oHtml:ValByName("l.colu1" )),"Item")
	AAdd((oHtml:ValByName("l.colu2" )),"Código")
	AAdd((oHtml:ValByName("l.colu3" )),"Descrição")
	AAdd((oHtml:ValByName("l.colu4" )),"UM")
	AAdd((oHtml:ValByName("l.colu5" )),"Est")
	AAdd((oHtml:ValByName("l.colu6" )),"Dig")
	AAdd((oHtml:ValByName("l.colu7" )),"Lib")
	AAdd((oHtml:ValByName("l.colu8" )),"Sts")
	AAdd((oHtml:ValByName("l.colu9" )),"Preço Venda")
	AAdd((oHtml:ValByName("l.colu10" )),"Total")
	AAdd((oHtml:ValByName("l.colu11" )),"Parcial")

Return


Static Function sfAddItens()

	AAdd((oHtml:ValByName("l.colu1" )),QRA->C9_ITEM)
	AAdd((oHtml:ValByName("l.colu2" )),QRA->C9_PRODUTO)
	AAdd((oHtml:ValByName("l.colu3" )),QRA->B1_DESC)
	AAdd((oHtml:ValByName("l.colu4" )),QRA->B1_UM)
	AAdd((oHtml:ValByName("l.colu5" )),QRA->B2_QATU)
	AAdd((oHtml:ValByName("l.colu6" )),QRA->C6_QTDVEN)
	AAdd((oHtml:ValByName("l.colu7" )),QRA->C9_QTDLIB)
	IF QRA->C9_NFISCAL <> " "
		AAdd((oHtml:ValByName("l.colu8" )),'<font color=#0000FF >'+"FAT"+'</font>')
	ELSE
		IF  QRA->C9_BLCRED <> " "
			AAdd((oHtml:ValByName("l.colu8" )),'<font  color=#FF0000 >'+"CRD"+'</font>')
			nScrd := nScrd + QRA->C9_QTDLIB * QRA->C9_PRCVEN
			nTcrd := nTcrd + QRA->C9_QTDLIB * QRA->C9_PRCVEN

		ELSE
			IF QRA->C9_BLEST <> " "
				AAdd((oHtml:ValByName("l.colu8" )),'<font color=#0000FF >'+"BLE"+'</font>')
				nSble := nSble + QRA->C9_QTDLIB * QRA->C9_PRCVEN
				nTble := nTble + QRA->C9_QTDLIB * QRA->C9_PRCVEN

			Else
				AAdd((oHtml:ValByName("l.colu8" )),'<font color=#006600 >'+"OK"+'</font>')
				nSok := nSok + QRA->C9_QTDLIB * QRA->C9_PRCVEN
				nTok := nTok + QRA->C9_QTDLIB * QRA->C9_PRCVEN
			Endif
		Endif
	ENDIF
	nSpend := nSpend + QRA->C9_QTDLIB * QRA->C9_PRCVEN
	nTpend := nTpend + QRA->C9_QTDLIB * QRA->C9_PRCVEN
	AAdd((oHtml:ValByName("l.colu9" )),transform(QRA->C9_PRCVEN,"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.colu10" )),transform(QRA->C9_QTDLIB * QRA->C9_PRCVEN,"@E 999,999,999.99"))
	If QRA->C9_QTDLIB < QRA->C6_QTDVEN
		AAdd((oHtml:ValByName("l.colu11" )),'<font color =#FF0000 >'+"Parcial"+'</font>')
	Else
		AAdd((oHtml:ValByName("l.colu11" )),"Inteiro")
	Endif

Return

Static Function sfRodape(cMsgNota,cMsgInt,cObsCli,cNumPed,cCondpag,nTotPed)

	AAdd((oHtml:ValByName("l.colu1" ))," ")
	AAdd((oHtml:ValByName("l.colu2" )),"Mens. Nota:")
	AAdd((oHtml:ValByName("l.colu3" )),cMsgNota)
	AAdd((oHtml:ValByName("l.colu4" ))," ")
	AAdd((oHtml:ValByName("l.colu5" ))," ")
	AAdd((oHtml:ValByName("l.colu6" ))," ")
	If nScrd >0
		AAdd((oHtml:ValByName("l.colu7" )),"Crd:")
		AAdd((oHtml:ValByName("l.colu8" )),'<font color =#FF0000 >'+transform(nScrd,"@E 999,999,999.99")+'</font>')
	Else
		AAdd((oHtml:ValByName("l.colu7" ))," ")
		AAdd((oHtml:ValByName("l.colu8" ))," ")
	Endif

	AAdd((oHtml:ValByName("l.colu9" ))," ")
	AAdd((oHtml:ValByName("l.colu10" )),transform(nSpend,"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.colu11" ))," ")

	AAdd((oHtml:ValByName("l.colu1" ))," ")
	AAdd((oHtml:ValByName("l.colu2" )),"Mens. Interna:")
	AAdd((oHtml:ValByName("l.colu3" )),cMsgInt)
	AAdd((oHtml:ValByName("l.colu4" ))," ")
	AAdd((oHtml:ValByName("l.colu5" ))," ")
	AAdd((oHtml:ValByName("l.colu6" ))," ")
	If nSble >0
		AAdd((oHtml:ValByName("l.colu7" )),"Ble:")
		AAdd((oHtml:ValByName("l.colu8" )),'<font color =#0000FF >'+transform(nSble,"@E 999,999,999.99")+'</font>')
	Else
		AAdd((oHtml:ValByName("l.colu7" ))," ")
		AAdd((oHtml:ValByName("l.colu8" ))," ")
	Endif

	AAdd((oHtml:ValByName("l.colu9" ))," ")
	AAdd((oHtml:ValByName("l.colu10" ))," ")
	AAdd((oHtml:ValByName("l.colu11" ))," ")

	AAdd((oHtml:ValByName("l.colu1" ))," ")
	AAdd((oHtml:ValByName("l.colu2" )),"Obs. Cliente:")
	AAdd((oHtml:ValByName("l.colu3" )),cObsCli)
	AAdd((oHtml:ValByName("l.colu4" ))," ")
	AAdd((oHtml:ValByName("l.colu5" ))," ")
	AAdd((oHtml:ValByName("l.colu6" ))," ")
	If nSok >0
		AAdd((oHtml:ValByName("l.colu7" )),"OK:")
		AAdd((oHtml:ValByName("l.colu8" )),'<font color =#006600 >'+transform(nSok,"@E 999,999,999.99")+'</font>')
	Else
		AAdd((oHtml:ValByName("l.colu7" ))," ")
		AAdd((oHtml:ValByName("l.colu8" ))," ")
	Endif

	AAdd((oHtml:ValByName("l.colu9" )),"Total Ped:")


	AAdd((oHtml:ValByName("l.colu10" )),transform(nTotPed,"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.colu11" ))," ")

	AAdd((oHtml:ValByName("l.colu1" )),"-")
	AAdd((oHtml:ValByName("l.colu2" )),"-----")
	nCond := cCondpag
	IF nNf >= 1
		If nSok >0 .and. nSok <70
			AAdd((oHtml:ValByName("l.colu3" )),'<font face=Comic Sans MS color =#800000 >'+"SALDO PEDIDO ABAIXO MÍNIMO!!EXCLUIR OU ACRESCENTAR ITENS!! "+'</font>')
		Else
			If nSok >=70 .and. nSok <200
				If nCond >='128'
					AAdd((oHtml:ValByName("l.colu3" )),'<font face=Comic Sans MS color =#800000 >'+"ALTERAR CONDIÇÃO DE PAGAMENTO!!!! 07;14;21 OU 28 DIAS!!"+'</font>')
				Else
					AAdd((oHtml:ValByName("l.colu3" )),"----------------------- ")
				Endif
			Else
				AAdd((oHtml:ValByName("l.colu3" )),"----------------------- ")

			Endif
		ENDIF
	Else
		AAdd((oHtml:ValByName("l.colu3" )),"----------------------- ")
	Endif


	AAdd((oHtml:ValByName("l.colu4" )),"-")
	AAdd((oHtml:ValByName("l.colu5" )),"-")
	AAdd((oHtml:ValByName("l.colu6" )),"-")
	AAdd((oHtml:ValByName("l.colu7" )),"-")
	AAdd((oHtml:ValByName("l.colu8" )),"-")
	AAdd((oHtml:ValByName("l.colu9" )),"----")
	AAdd((oHtml:ValByName("l.colu10" )),"---")
	AAdd((oHtml:ValByName("l.colu11" )),"----")

Return



Static Function sfEnvWF(cEmSup)
	Local iW 

	AAdd((oHtml:ValByName("l.colu1" )),"-")
	AAdd((oHtml:ValByName("l.colu2" )),"-")
	AAdd((oHtml:ValByName("l.colu3" )),"TOTAIS VENDEDOR:"+cEmSup)
	AAdd((oHtml:ValByName("l.colu4" )),"-")
	AAdd((oHtml:ValByName("l.colu5" )),"-")
	AAdd((oHtml:ValByName("l.colu6" )),"-")
	AAdd((oHtml:ValByName("l.colu7" )),"-")
	AAdd((oHtml:ValByName("l.colu8" )),"CRD")
	AAdd((oHtml:ValByName("l.colu9" )),"ESTOQUE")
	AAdd((oHtml:ValByName("l.colu10" )),"OK")
	AAdd((oHtml:ValByName("l.colu11" )),"GERAL")
	AAdd((oHtml:ValByName("l.colu1" )),"-")
	AAdd((oHtml:ValByName("l.colu2" )),"-")
	AAdd((oHtml:ValByName("l.colu3" )),"-")
	AAdd((oHtml:ValByName("l.colu4" )),"-")
	AAdd((oHtml:ValByName("l.colu5" )),"-")
	AAdd((oHtml:ValByName("l.colu6" )),"-")
	AAdd((oHtml:ValByName("l.colu7" )),"-")
	AAdd((oHtml:ValByName("l.colu8" )),transform(nTcrd,"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.colu9" )),transform(nTble,"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.colu10" )),transform(nTok,"@E 999,999,999.99"))
	AAdd((oHtml:ValByName("l.colu11" )),transform(nTpend,"@E 999,999,999.99"))

	//AAdd((oHtml:ValByName("l.colu3" )),cEmSup)

	oProcess:ClientName(Substr(cUsuario,7,15))
	
	// Trata a limpeza dos e-mails repetidos 
	cRecebe := IIf(!Empty(cEmSup),cEmSup+";","")	
	aOutMails	:= StrTokArr(cRecebe,";")
	cRecebe	:= ""
	For iW := 1 To Len(aOutMails)
		If !Empty(cRecebe)
			cRecebe += ";"
		Endif
		If IsEmail(aOutMails[iW]) .And. !(Alltrim(Upper(aOutMails[iW])) $ cRecebe)
			cRecebe	+= Upper(aOutMails[iW])
		Endif
	Next
	oProcess:cTo := cRecebe
	
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()

Return

