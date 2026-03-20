#Include 'Protheus.ch'
#INCLUDE "TBICONN.CH"
#define STR0035  "Ambiente"
#define STR0039  "O primeiro passo é configurar a conexão do Protheus com o serviço."
#define STR0050  "Protocolo"
#define STR0056  "Produção"
#define STR0057  "Homologação"
#define STR0068  "Cod.Ret.NFe"
#define STR0069  "Msg.Ret.NFe"
#define STR0114  "Ok"
#define STR0107  "Consulta NF"
#define STR0129  "Versão da mensagem"

/*/{Protheus.doc} RLFATA01
(Rotina de geração de pedidos de venda para devolução de armazenagem)
@type function
@author Marcelo Alberto Lauschner
@since 09/10/2016
@version 1.0
@return NIl, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function RLFATA01()
	Private cPerg1	 	:= ValidPerg("RLFATA01")

	If Pergunte(cPerg1,.T.)

		While .T.

			If !sfExec()
				Exit
			Endif
		Enddo
	Endif

Return

Static Function sfExec()



	Local lRet			:= .T.													//Variavel de tratamento para o retorno

	Local aAreaOld     	:= GetArea()

	Local bCampo    	:= {|nCPO| Field(nCPO) }

	Local cNumPed
	Local cLanguage		:= "P"

	Local nX        	:= 0

	Local nMaxFor   	:= 0
	Local nPosInfAd		:= 0
	Local aRotinaBkp	:= {}

	If !cEmpAnt $ "06#16"
		MsgInfo("Empresa errada para executar esta rotina!")
		Return
	Endif


	Private aCols   	:= {}
	Private aHeadC6   	:= {}
	Private	lIsRejSef	:= .F.

	Pergunte(cPerg1,.F.)

	// 14/11/2018 - Adicionada verificação para evitar que possa ser escolhido um periodo maior que 30 dias.
	If !RetCodUsr() $ "000130" .And. MV_PAR07 < MV_PAR08 - 2
		MsgAlert("Não é permitido usar intervalo de data maior que 2 dias! Favor ajustar data de intervalo!")
		RestArea(aAreaOld)
		Return .F.
	Endif

	Private	cAliasSZ1 	:= "QSZ1"
	Private cAliasSB6	:= "QSB6"
	Private aColscCust 	:= {}
	Private	aHeader		:= {}
	PRIVATE ALTERA 		:= .F.
	PRIVATE INCLUI 		:= .T.
	PRIVATE cCadastro 	:= "Pedido de Venda"
	Private aRotina 	:=  &("StaticCall(MATA410,MenuDef)")
	Private AHEADGRADE	:= {}
	Private aColsGrade	:= {}
	Private n          	:= 1

	#IFDEF SPANISH
		cLanguage	:= "S"
	#ELSE
		#IFDEF ENGLISH
			cLanguage	:= "E"
		#ENDIF
	#ENDIF

	// Atualiza a sequencia correta do SC5 no SXE e SXF,
	DbSelectArea("SC5")
	DbSetOrder(1)
	Do While .T.
		cNumPed := GetSxeNum("SC5","C5_NUM")
		If !dbSeek( xFilial( "SC5" ) + cNumPed )
			RollBackSX8()
			Exit
		EndIf
		If __lSx8
			ConfirmSx8()
		EndIf
	EndDo

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta aHeader do SC6                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aHeadC6 := {}
	//dbSelectArea("SX3")
	//dbSetOrder(1)
	//MsSeek("SC6",.T.)

	aFields := {}
	aFields := FWSX3Util():GetAllFields("SC6", .T. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		//While ( !Eof() .And. GetSx3Cache(cCampo,"X3_ARQUIVO") == "SC6" )
		If ( X3Uso(GetSx3Cache(cCampo,"X3_USADO")) .And.;
				!Trim(GetSx3Cache(cCampo,"X3_CAMPO"))=="C6_NUM" .And.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) != "C6_QTDEMP" .And.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) != "C6_QTDENT" .And.;
				cNivel >= GetSx3Cache(cCampo,"X3_NIVEL") ) .Or.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO"))=="C6_CONTRAT" .Or. ;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO"))=="C6_ITEMCON"

			Aadd(aHeadC6,{IIF(cLanguage == "P",GetSx3Cache(cCampo,"X3_TITULO"),IIF(cLanguage == "S",GetSx3Cache(cCampo,"X3_TITSPA"),GetSx3Cache(cCampo,"X3_TITENG"))),;
				GetSx3Cache(cCampo,"X3_CAMPO"),;
				GetSx3Cache(cCampo,"X3_PICTURE"),;
				GetSx3Cache(cCampo,"X3_TAMANHO"),;
				GetSx3Cache(cCampo,"X3_DECIMAL"),;
				GetSx3Cache(cCampo,"X3_VALID"),;
				GetSx3Cache(cCampo,"X3_USADO"),;
				GetSx3Cache(cCampo,"X3_TIPO"),;
				GetSx3Cache(cCampo,"X3_ARQUIVO"),;
				GetSx3Cache(cCampo,"X3_CONTEXT") })
		EndIf
		//	dbSelectArea("SX3")
		//	dbSkip()
		//EndDo
	Next nX


	aheader    := aClone(aHeadC6)

	If MV_PAR01==2
		dbSelectArea("SA2")
		dbSetOrder(1)
		If !DbSeek(xFilial("SA2")+MV_PAR05+MV_PAR06)
			MsgAlert("Fornecedor inexistente!")
			Return
		Endif
	Else
		dbSelectArea("SA1")
		dbSetOrder(1)
		If !DbSeek(xFilial("SA1")+MV_PAR02+MV_PAR03)
			MsgAlert("Cliente inexistente!")
			Return
		Endif
	Endif

	dbSelectArea("SE4")
	dbSetOrder(1)
	MsSeek(xFilial("SE4")+MV_PAR04)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Cria as variaveis do Pedido de Venda                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SC5")
	nMaxFor := FCount()
	For nX := 1 To nMaxFor
		M->&(EVAL(bCampo,nX)) := CriaVar(FieldName(nX),.T.)
	Next nX
	M->C5_TIPO    := Iif(MV_PAR01==2,"B","N")
	M->C5_CLIENTE := Iif(MV_PAR01==2,SA2->A2_COD,SA1->A1_COD)
	M->C5_LOJACLI := Iif(MV_PAR01==2,SA2->A2_LOJA,SA1->A1_LOJA)
	M->C5_LOJAENT := Iif(MV_PAR01==2,SA2->A2_LOJA,SA1->A1_LOJA)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Atualiza as informacoes padroes a partir do Cliente                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	a410Cli("C5_CLIENTE",M->C5_CLIENTE,.F.)
	a410Loja("C5_LOJACLI",M->C5_LOJACLI,.F.)
	M->C5_TIPOCLI 	:= "R"
	M->C5_CONDPAG 	:= MV_PAR04
	//M->C5_TABELA  := "300"// Chumbada só para não dar erro ao validar
	M->C5_PROPRI  	:= "1"
	M->C5_DTPROGM 	:= dDataBase
	M->C5_MSGINT  	:= Iif(MV_PAR01==1,"Periodo " + DTOC(MV_PAR07)+ " A " + DTOC(MV_PAR08) ,"Pedido gerado automaticamente")
	M->C5_TPFRETE	:= "S"

	Processa({|| sfZ1AtuSaldos(Iif(MV_PAR01==1,MV_PAR02,MV_PAR05),Iif(MV_PAR01==1,MV_PAR03,MV_PAR06))},"Atualizandos saldos devolvidos... " )


	dbSelectArea("SF4")
	dbSetOrder(1)

	Processa({|| sfMontaDados()},"Gerando lista de produtos.. " )

	nPosInfAd	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_INFAD"})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Grava o Pedido de Venda                                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !Empty(aCols)

		//Begin Transaction
		aHeader := aClone(aHeadC6)
		For nX := 1 To Len(aCols)
			MatGrdMont(nX)
		Next nX
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Variaveis Utilizadas pela Funcao a410Inclui          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


		Pergunte("MTA410",.F.)
		aRotinaBkp := aRotina
		// Se foi confirmado o pedido, atualiza as solicitações de baixa
		//A410Inclui(cAlias,nReg,nOpc,lOrcamento,nStack,aRegSCK,lContrat,nTpContr,cCodCli,cLoja,cMedPMS)
		If SC5->(a410Inclui(Alias(),Recno(),4,.T.,,,.T.)) == 1
			// Efetua atualização dos saldos de retorno de armazenagens
			DbSelectArea("SC6")
			DbSetOrder(1)
			DbSeek(xFilial("SC6")+SC5->C5_NUM)
			While !Eof() .And. SC6->C6_FILIAL+SC6->C6_NUM == xFilial("SC6")+SC5->C5_NUM
				DbSelectArea("SZ2")
				DbGoto(SC6->C6_XKEYSZ2)
				Reclock("SZ2",.F.)
				SZ2->Z2_QTDDEV += SC6->C6_QTDVEN
				MsUnlock()


				// Grava memo na marra
				// Desta forma a impressão dos dados de nota de origem será impressa em cada item no Danfe
				For nX := 1 To Len(aCols)
					If aCols[nX, aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})] == SC6->C6_ITEM
						MSMM(,80,,aCols[nX,nPosInfAd],1,,,'SC6','C6_CODINF')
						Exit
					Endif
				Next
				// Força ajuste do CST do item da nota.
				DbSelectArea("SF4")
				DbSetOrder(1)
				DbSeek(xFilial("SF4")+SC6->C6_TES)
				DbSelectArea("SC6")
				RecLock("SC6",.F.)
				SC6->C6_CLASFIS		:= Substr(SZ2->Z2_CLASFIS,1,1) + SF4->F4_SITTRIB
				MsUnlock()

				DbSelectArea("SC6")
				DbSkip()
			Enddo
			If __lSx8
				ConfirmSx8()
			EndIf
		Else
			RollBackSx8()
			lRet 	:= .F.
		Endif
		aRotina := aRotinaBkp

		//End Transaction

	ElseIf lIsRejSef // Se houve cancelamento autorizado da nota, continua o fluxo

	Else
		MsgAlert("Não há apontamentos pendentes para gerar Pedido de venda para devolução de armazenagem!","Sem apontamentos pendentes")
		lRet 	:= .F.
	EndIf

	RestArea(aAreaOld)

Return lRet


/*/{Protheus.doc} sfMontaDados
(Monta os produtos do pedido de venda )
@type function
@author marce
@since 09/10/2016
@version 1.0
@return Nil, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMontaDados()

	Local cQry
	Local aDadosCfo := {}
	Local cItSC6    	:= StrZero(0,TamSX3("C6_ITEM")[1])
	Local cTes      	:= ""
	Local nX        	:= 0
	Local nY        	:= 0
	Local nUsado    	:= Len(aHeadC6)
	Local nCtAux		:= 0
	Local nItensLimite	:= 99
	Local nQteItemAdd	:= 0
	Local cChvAtu		:= ""
	Local lContVld		:= .F.
	Local nPosLocal		:= 0
	Local cCliNfpNf		:= "00001314#00001333" // Código e Loja dos clientes que devem quebrar os pedidos por cada nota de venda para gerar devolução
	Local lExibeNfOri	:= .F. //MsgYesNo("Mostrar notas de origem? ")
	Local nQteItem		:= 0
	Local nPosQtd		:= 0
	Local nPosClasFis	:= 0
	Local cMenNota 		:= ""
	ProcRegua(nItensLimite+40)


	cQry := ""
	cQry += "SELECT Z1_FILIAL,"
	cQry += "       Z1.R_E_C_N_O_ Z1RECNO,"
	cQry += "       Z1_CHAVE,"
	cQry += "       Z1_EMISSAO,"
	cQry += "       Z1_NOTA,"
	cQry += "       Z1_SERIE,"
	cQry += "       Z1_EMIT,"
	cQry += "       Z1_DEST,"
	cQry += "       Z1_STATUS,"
	cQry += "       Z2_ITEM,"
	cQry += "       Z2_PRODUTO,"
	cQry += "       Z2_QUANT,"
	cQry += "       Z2_QTDDEV,"
	cQry += "       Z2_FCI,"
	cQry += "       Z2_CLASFIS,"
	cQry += "       Z2.R_E_C_N_O_ Z2RECNO,"
	cQry += "       COALESCE((SELECT A7_PRODUTO"
	cQry += "                   FROM " + RetSqlName("SA7") + " A7 "
	cQry += "                  WHERE A7.D_E_L_E_T_ = ' ' "
	cQry += "                    AND A7_CLIENTE = A1_COD "
	cQry += "                    AND A7_LOJA = A1_LOJA"
	cQry += "                    AND A7_CODCLI = Z2_PRODUTO"
	cQry += "                    AND A7_FILIAL = '" + xFilial("SA7")+ "'),"
	cQry += "       COALESCE((SELECT Z3_PRODUTO "
	cQry += "                   FROM " + RetSqlName("SZ3") + " Z3"
	cQry += "                  WHERE D_E_L_E_T_ = ' ' "
	cQry += "                    AND Z3_CGCEMIT = Z1_EMIT "
	cQry += "                    AND Z3_CODCLI = Z2_PRODUTO "
	cQry += "                    AND Z3_CGCDEST = Z1_DEST "
	cQry += "                    AND Z3_CGCDEST <> '" + SM0->M0_CGC + "'"
	cQry += "                    AND Z3_FILIAL = '" + xFilial("SZ3")+ "'),"
	cQry += "                 'XXX')) A7_PRODUTO"
	cQry += "  FROM " + RetSqlName("SZ1") + " Z1," + RetSqlName("SZ2") + " Z2," + RetSqlName("SA1") + " A1 "
	cQry += " WHERE Z1.D_E_L_E_T_ = ' ' "
	cQry += "   AND Z1_FILIAL = '" + xFilial("SZ1") + "' "
	cQry += "   AND Z1_STATUS <> '5' "
	cQry += "   AND Z1_TIPNF = '1' " // Apenas notas de saída
	cQry += "   AND Z1_DEST <> '" + SM0->M0_CGC + "'"
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_CGC = Z1_EMIT"
	cQry += "   AND A1_COD = '" + M->C5_CLIENTE + "'"
	cQry += "   AND A1_LOJA = '" + M->C5_LOJACLI + "'"
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1")+ "'"
	cQry += "   AND Z2.D_E_L_E_T_ = ' '"
	cQry += "   AND Z2_CF NOT IN('5663','1921','1661','5906','5907','5905','5920')"
	cQry += "   AND Z2_ESTOQUE <> 'N' "
	cQry += "   AND Z2_QUANT > Z2_QTDDEV " // Verifica somente o que tem saldo a devolver
	cQry += "   AND Z2_CHAVE = Z1_CHAVE"
	cQry += "   AND Z2_FILIAL = '" + xFilial("SZ2")+ "'"
	cQry += "   AND EXISTS (SELECT F1_DOC"
	cQry += "                 FROM " + RetSqlName("SF1") + " F1 "
	cQry += "                WHERE F1_FORNECE = A1_COD "
	cQry += "                  AND F1_LOJA = A1_LOJA"
	cQry += "                  AND F1.D_E_L_E_T_ = ' '"
	cQry += "                  AND F1_FILIAL = '" +xFilial("SF1")+ "' "
	cQry += "                  AND F1_DTDIGIT <= '" + DTOS(MV_PAR08) + "')"
	cQry += "   AND Z1_EMISSAO BETWEEN '" + DTOS(MV_PAR07)+ "' AND '" + DTOS(MV_PAR08) + "'"
	cQry += "   AND Z1_EMISSAO >= '20200101' " // Fixa data para evitar que consigam pegar periodo anterior até Julho/2018 que não foi corrigido corretamente durante a importação dos dados que vieram da Cloud
	cQry += " ORDER BY Z1_CHAVE,Z2_ITEM"

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasSZ1,.T.,.T.)

	cEstado :=  GetMv("MV_ESTADO")

	While !Eof()

		nCtAux++
		// Zero a Quantidade para novo item
		nQteItem	:= 0

		While nQteItem < (cAliasSZ1)->Z2_QUANT - (cAliasSZ1)->Z2_QTDDEV .And. ((cAliasSZ1)->Z2_QUANT - (cAliasSZ1)->Z2_QTDDEV - nQteItem) > 0

			If cChvAtu <> (cAliasSZ1)->Z1_CHAVE

				// Se não for a primeira nota e o cliente é do tipo que precisa separar por pedido cada nota de faturamento
				// Atribui variável de limite para cair fora no if mais abaixo
				If !Empty(cChvAtu) .And. M->C5_CLIENTE+M->C5_LOJACLI $ cCliNfpNf
					nQteItemAdd := nItensLimite
					// Grava mensagem da nota.
					M->C5_MENNOTA 	:= cMenNota
					(cAliasSZ1)->(DbCloseArea())
					Return
				Endif

				IncProc("Validando Sefaz NFe " +(cAliasSZ1)->Z1_CHAVE )
				FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Validando Sefaz NFe " +(cAliasSZ1)->Z1_CHAVE/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

				If !Empty(cChvAtu)
					Sleep(10*1000) // Espera 10 segundos entre 1 uma nota e outra para consultar Sefaz
				Endif

				If !sfConfSefaz((cAliasSZ1)->Z1_CHAVE)

					If lIsRejSef
						MsgAlert("Nota fiscal cancelada " +(cAliasSZ1)->Z1_CHAVE )
						DbSelectArea("SZ1")
						DbSetOrder(1)
						DbGoto((cAliasSZ1)->Z1RECNO)
						RecLock("SZ1",.F.)
						SZ1->Z1_STATUS	:= "5"
						MsUnlock()
					Endif
					lContVld		:= .F.
					cChvAtu := (cAliasSZ1)->Z1_CHAVE
					dbSelectArea(cAliasSZ1)
					dbSkip()
					Loop
				Else
					lContVld		:= .T.
				Endif
				cChvAtu := (cAliasSZ1)->Z1_CHAVE
			Else
				If !lContVld
					dbSelectArea(cAliasSZ1)
					dbSkip()
					Loop
				Endif
			Endif

			IncProc("Processando " +cItSC6 + "-"+(cAliasSZ1)->A7_PRODUTO)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Posiciona registros                                                     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("SB1")
			dbSetOrder(1)
			If DbSeek(xFilial("SB1")+(cAliasSZ1)->A7_PRODUTO)


				// Verifica limite de itens adicionados
				nQteItemAdd++
				If nQteItemAdd > nItensLimite
					(cAliasSZ1)->(DbCloseArea())
					Return
				Endif
				// Se for a primeira linha deleta
				If nCtAux == 1
					Aadd(aCols,Array(nUsado+1))

					nY	:= Len(aCols)
					n	:= nY
					For nX := 1 To nUsado
						aCols[nY,nX] := CriaVar(aHeadC6[nX,2],.T.)
					Next
					aCols[nY,nUsado+1] := .T.
				Endif

				Aadd(aCols,Array(nUsado+1))

				nY	:= Len(aCols)
				n	:= nY
				aCols[nY,nUsado+1] := .F.



				For nX := 1 To nUsado
					Do Case
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_ITEM" )
							cItSC6 := Soma1(cItSC6)
							aCols[nY,nX] := cItSC6
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_PRODUTO" )
							aCols[nY,nX] := (cAliasSZ1)->A7_PRODUTO
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_QTDVEN" )
							nPosQtd	:= nX
							aCols[nY,nX] := (cAliasSZ1)->Z2_QUANT - (cAliasSZ1)->Z2_QTDDEV - nQteItem
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_UM" )
							aCols[nY,nX] := SB1->B1_UM
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_OPER" )
							aCols[nY,nX] := "DA"
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_LOCAL" )
							//aCols[nY,nX] := SB1->B1_LOCPAD
							nPosLocal	:= nX
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_TES" )

							If MV_PAR01==2
								cTes 	:= MaTesInt(2,"DA",SA2->A2_COD,SA2->A2_LOJA,"F",SB1->B1_COD,"C6_TES")
							Else
								cTes 	:= MaTesInt(2,"DA",SA1->A1_COD,SA1->A1_LOJA,"C",SB1->B1_COD,"C6_TES")
							Endif
							SF4->(DbSeek(xFilial("SF4")+cTes))
							aCols[nY,nX] := cTes
							// Retorna o Acols completo já com as validações feita pela Tes inteligente
							//aCols[nY]	:= aClone(aCols[nY])
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_CF" )

							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Define o CFO                                         ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							aDadosCFO := {}
							Aadd(aDadosCfo,{"OPERNF","S"})
							Aadd(aDadosCfo,{"TPCLIFOR","R"})
							Aadd(aDadosCfo,{"UFDEST"  ,Iif( MV_PAR01==2 ,SA2->A2_EST,SA1->A1_EST)})
							Aadd(aDadosCfo,{"INSCR"   ,Iif( MV_PAR01==2 ,SA2->A2_INSCR,SA1->A1_INSCR)})

							aCols[nY,nX] := MaFisCfo(,SF4->F4_CF,aDadosCfo)
							// Efetua ajuste em caso de cfop incorreto
							If MV_PAR01==1
								If SA1->A1_EST == cEstado  .And. Substr(aCols[nY,nX],1,1) <> "5"
									MsgAlert("Foi necessário ajustar o CFOP de '" + aCols[nY,nX] + "' para '" + "5"+Substr(aCols[nY,nX],2,3) + "' no item '" + cItSC6 + "'. Favor notificar o TI sobre este caso para ser analisado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
									aCols[nY,nX]	:= "5"+Substr(aCols[nY,nX],2,3)
								Endif
							Endif
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_CLASFIS" )
							aCols[nY,nX] := SB1->B1_ORIGEM+SF4->F4_SITTRIB //CodSitTri()
							nPosClasFis	:= nX
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_SEGUM" )
							aCols[nY,nX] := SB1->B1_SEGUM
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_ENTREG" )
							aCols[nY,nX] := dDataBase
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_DESCRI" )
							aCols[nY,nX] := SB1->B1_DESC
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_XKEYSZ2")
							aCols[nY,nX] := (cAliasSZ1)->Z2RECNO
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_FCICOD" )
							aCols[nY,nX] := (cAliasSZ1)->Z2_FCI
						Case ( AllTrim(aHeadC6[nX,2]) == "C6_INFAD")
							aCols[nY,nX] 	:= CriaVar(aHeadC6[nX,2],.T.)
							aCols[nY,nX]  := "Ref. NFE: " + Alltrim((cAliasSZ1)->Z1_NOTA) + "; Série: " + Alltrim((cAliasSZ1)->Z1_SERIE) + ;
								"; Emissão: " + DTOC(STOD((cAliasSZ1)->Z1_EMISSAO)) +  "; Produto: " + Alltrim((cAliasSZ1)->Z2_PRODUTO)+";"

							// Monta texto de mensagem da nota
							If !("Ref. NFE: " + Alltrim((cAliasSZ1)->Z1_NOTA) $ cMenNota)
								cMenNota	+= "Ref. NFE: " + Alltrim((cAliasSZ1)->Z1_NOTA)
							Endif

						OtherWise
							aCols[nY,nX] := CriaVar(aHeadC6[nX,2],.T.)
					EndCase

				Next nX
				//		(cProduto,cLocal,cTpNF,cES,cCliFor,cLoja,nRegistro,cEstoque,cNumPV,nLinha,lExibeNfOri,aCols,aHeader


				aCols[nY,nUsado+1] := !(sfF4Poder3((cAliasSZ1)->A7_PRODUTO,M->C5_TIPO,"S"/*cES*/,M->C5_CLIENTE,M->C5_LOJACLI,nY,lExibeNfOri,@aCols,aHeadC6,(cAliasSZ1)->Z2_FCI,(M->C5_CLIENTE+M->C5_LOJACLI $ cCliNfpNf),(cAliasSZ1)->Z2_CLASFIS ))

				If aCols[nY,nUsado+1]
					MsgAlert("Não há saldo disponível para o código '" +(cAliasSZ1)->Z2_PRODUTO + "' referente a nota " +(cAliasSZ1)->Z1_NOTA + " na quantidade " + cValToChar(aCols[nY,nPosQtd]) + " CST: " + (cAliasSZ1)->Z2_CLASFIS + " FCI: " + (cAliasSZ1)->Z2_FCI ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				Else
					// Efetua o ajuste do CST
					aCols[nY][nPosClasFis]	:= Substr((cAliasSZ1)->Z2_CLASFIS,1,1) + Substr(aCols[nY][nPosClasFis],2,2)
				Endif
				//F4Poder3(cProduto,cLocal,cTpNF,cES,cCliFor,cLoja,nRegistro,cEstoque,cNumPV)

				//aCols[nY,nUsado+1] := !(F4Poder3((cAliasSZ1)->A7_PRODUTO,aCols[nY,nPosLocal], M->C5_TIPO,"S"/*cES*/,M->C5_CLIENTE,M->C5_LOJACLI))

				If aCols[nY,nUsado+1]
					nQteItemAdd--
				Endif

				// Atualizo variável para saber se já foi feita a devida devolução
				nQteItem	+= Iif(aCols[nY,nPosQtd] < 0 , aCols[nY,nPosQtd] * -1 , aCols[nY,nPosQtd])

			Else
				// Só pra cair fora do While
				nQteItem := (cAliasSZ1)->Z2_QUANT - (cAliasSZ1)->Z2_QTDDEV

				MsgAlert("Não há produto cadastrado para o código '" +(cAliasSZ1)->Z2_PRODUTO + "' referente a nota " +(cAliasSZ1)->Z1_NOTA,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		Enddo
		dbSelectArea(cAliasSZ1)
		dbSkip()
	EndDo
	// Grava mensagem da nota.
	M->C5_MENNOTA 	:= cMenNota

	(cAliasSZ1)->(DbCloseArea())

Return


/*/{Protheus.doc} ValidPerg
(Valida a criação de perguntas da rotina)
@type function
@author marce
@since 09/10/2016
@version 1.0
@param cPerg2, character, (Descrição do parâmetro)
@return cPerg1, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ValidPerg(cPerg2)

	Local aAreaOld := GetArea()
	Local aRegs := {}
	Local i,j
	Local cPerg1

	dbSelectArea("SX1")
	dbSetOrder(1)
	// Este tratamanto é necessário pois para a versão 10, o protheus mudou o tamanho do grupo de perguntas de 6 para 10 digitos
	cPerg1 := Padr(cPerg2,10)
	//                               123456789012345                                                                                                                   123456789012345                                            123456789012345                                            123456789012345                                            123456789012345
	//          X1_GRUPO,X1_ORDEM,X1_PERGUNT         ,X1_PERSPA,X1_PERENG,X1_VARIAVL,X1_TIPO,X1_TAMANHO,X1_DECIMAL,X1_PRESEL,X1_GSC,X1_VALID,X1_VAR01  ,X1_DEF01         ,X1_DEFSPA1,X1_DEFENG1,X1_CONT01,X1_VAR02,X1_DEF02         ,X1_DEFSPA2,X1_DEFENG2,X1_CONT02,X1_VAR03,X1_DEF03         ,X1_DEFSPA3,X1_DEFENG3,X1_CONT03,X1_VAR04,X1_DEF04         ,X1_DEFSPA4,X1_DEFENG4,X1_CONT04,X1_VAR05,X1_DEF05,X1_DEFSPA5,X1_DEFENG5,X1_CONT05,X1_F3,X1_PYME,X1_GRPSXG,X1_HELP,X1_PICTURE,X1_IDFIL
	Aadd(aRegs,{cPerg1  ,"01"	   	,"Tipo Pedido"    ,""       ,""       ,"mv_ch1"  ,"N"	,01		   ,0		 ,1		   ,"C"	  ,""	   ,"mv_par01","Normal"			 ,""        ,""	       ,""  	 ,""	  ,"Beneficiamento"	,""	      ,""        ,""	   ,""      ,"               ",""	     ,""	    ,""		  ,""	   ,"               ",""        ,""	       ,""		 ,""	  ,""      ,""        ,"" 		 ,""	   ,""	 ,""	 ,""       ,""     ,""        ,""})
	DbSelectArea("SX3")
	DbSetOrder(2)
	cCampo := ("E1_CLIENTE")
	Aadd(aRegs,{cPerg1  ,"02"      	,"Cód.Cliente" 	 ,""       ,""       ,"mv_ch2"  ,GetSx3Cache(cCampo,"X3_TIPO"),GetSx3Cache(cCampo,"X3_TAMANHO"),GetSx3Cache(cCampo,"X3_DECIMAL"),0,"G","" ,"mv_par02",""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""      ,""        ,""        ,""       ,GetSx3Cache(cCampo,"X3_F3"),"",GetSx3Cache(cCampo,"X3_GRPSXG"),"",GetSx3Cache(cCampo,"X3_PICTURE"),""})
	cCampo1 := ("E1_LOJA")
	Aadd(aRegs,{cPerg1  ,"03"      	,"Loja"           ,""       ,""       ,"mv_ch3"  ,GetSx3Cache(cCampo1,"X3_TIPO"),GetSx3Cache(cCampo1,"X3_TAMANHO"),GetSx3Cache(cCampo1,"X3_DECIMAL"),0,"G","" ,"mv_par03",""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""      ,""        ,""        ,""       ,GetSx3Cache(cCampo1,"X3_F3"),"",GetSx3Cache(cCampo1,"X3_GRPSXG"),"",GetSx3Cache(cCampo1,"X3_PICTURE"),""})
	cCampo2 := ("C5_CONDPAG")
	Aadd(aRegs,{cPerg1  ,"04"      	,"Cond.Pagto"     ,""       ,""       ,"mv_ch4"  ,GetSx3Cache(cCampo2,"X3_TIPO"),GetSx3Cache(cCampo2,"X3_TAMANHO"),GetSx3Cache(cCampo2,"X3_DECIMAL"),0,"G","" ,"mv_par04",""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""      ,""        ,""        ,""       ,GetSx3Cache(cCampo2,"X3_F3"),"",GetSx3Cache(cCampo2,"X3_GRPSXG"),"",GetSx3Cache(cCampo2,"X3_PICTURE"),""})
	DbSelectArea("SX3")
	DbSetOrder(2)
	cCampo3 := ("E2_FORNECE")
	Aadd(aRegs,{cPerg1  ,"05"      	,"Cód.Fornecedor" ,""       ,""       ,"mv_ch5"  ,GetSx3Cache(cCampo3,"X3_TIPO"),GetSx3Cache(cCampo3,"X3_TAMANHO"),GetSx3Cache(cCampo3,"X3_DECIMAL"),0,"G","" ,"mv_par05",""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""      ,""        ,""        ,""       ,GetSx3Cache(cCampo3,"X3_F3"),"",GetSx3Cache(cCampo3,"X3_GRPSXG"),"",GetSx3Cache(cCampo3,"X3_PICTURE"),""})
	cCampo4 := ("E2_LOJA")
	Aadd(aRegs,{cPerg1  ,"06"      	,"Loja"           	,""       ,""       ,"mv_ch6"  ,GetSx3Cache(cCampo4,"X3_TIPO"),GetSx3Cache(cCampo4,"X3_TAMANHO"),GetSx3Cache(cCampo4,"X3_DECIMAL"),0,"G","" ,"mv_par06",""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""               ,""        ,""        ,""       ,""      ,""      ,""        ,""        ,""       ,GetSx3Cache(cCampo4,"X3_F3"),"",GetSx3Cache(cCampo4,"X3_GRPSXG"),"",GetSx3Cache(cCampo4,"X3_PICTURE"),""})
	Aadd(aRegs,{cPerg1  ,"07"		,"Emissão de"		,"Emissão de "	,"Emissão de"			,"mv_ch7"		,"D"		,8					,0					,0				,"G"		,""			,"mv_par07"	,""					,""					,""				,""			,""				,""					,""					,""					,""			,""			,""				,""					,""				,""				,""			,""				,""				,""				,""				,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPerg1  ,"08"		,"Emissão até"		,"Emissão até"	,"Emissão"				,"mv_ch8"		,"D"		,8					,0					,0				,"G"		,""			,"mv_par08"	,""					,""					,""				,""			,""				,""					,""					,""					,""			,""			,""				,""					,""				,""				,""			,""				,""				,""				,""				,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})

	dbSelectArea("SX1")
	dbSetOrder(1)

	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg1+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Else
			RecLock("SX1",.F.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	RestArea(aAreaOld)

Return cPerg1


/*/{Protheus.doc} sfZ1AtuSaldos
(Efetua atualização dos saldos devolvidos - garantindo que o processo esteja com os saldos corretos)
@type function
@author marce
@since 09/10/2016
@version 1.0
@return nil, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfZ1AtuSaldos(cInCli,cInLoja)

	Local	cQry	:= ""

	cQry := "UPDATE " + RetSqlName("SZ2") + " "
	cQry += "   SET Z2_QTDDEV = COALESCE((SELECT SUM(C6_QTDVEN) "
	cQry += "                               FROM " + RetSqlName("SC6") + " C6, " + RetSqlName("SC5") + " C5 "
	cQry += "                              WHERE C6.D_E_L_E_T_ = ' ' "
	//cQry += "                                AND C6_XKEYSZ2 = "+ RetSqlName("SZ2") + ".R_E_C_N_O_ "
	cQry += "                                AND C6_FILIAL = '" + xFilial("SC6") + "'"
	cQry += "                                AND EXISTS ( SELECT YP_TEXTO FROM "+ RetSqlName("SYP") + " YP WHERE YP.D_E_L_E_T_ =' ' AND YP_CHAVE = C6_CODINF AND YP_CAMPO = 'C6_CODINF' AND SUBSTRING(YP_TEXTO,11,9) =SUBSTRING(Z2_CHAVE,26,9) AND YP_FILIAL ='" + xFilial("SYP") + "' )"
	cQry += "                                AND EXISTS ( SELECT YP_TEXTO FROM "+ RetSqlName("SYP") + " YP WHERE YP.D_E_L_E_T_ =' ' AND YP_CHAVE = C6_CODINF AND YP_CAMPO = 'C6_CODINF' AND SUBSTRING(YP_TEXTO,62,15) = TRIM(Z2_PRODUTO) + ';' AND YP_FILIAL ='" + xFilial("SYP") + "' )"
	cQry += "                                AND C6_NUM = C5_NUM "
	cQry += "                                AND C5.D_E_L_E_T_ = ' ' "
	cQry += "                                AND C5_CLIENTE = '" + cInCli + "'"
	cQry += "                                AND C5_LOJACLI = '" + cInLoja + "'"
	cQry += "                                AND C5_FILIAL = '" + xFilial("SC5") + "'),0)"

	//YP_CHAVE 
	//YP_CAMPO = 'C6_CODINF'
	//YP_FILIAL = '  '
	//12345678901234567890123456789012345678901234567890123456789012345678901234567890
	//Ref. NFE: 000006974; Série: 1; Emissão: 30/08/2023; Produto: 15578500000;       

	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND Z2_FILIAL = '" + xFilial("SZ2") + "'"
	cQry += "   AND Z2_CF NOT IN('5663','1921','1661','5906','5907','5905','5920') "
	cQry += "   AND Z2_CHAVE IN ( SELECT Z1_CHAVE "
	cQry += "                       FROM " + RetSqlName("SZ1") + " Z1, " + RetSqlName("SA1") + " A1 "
	cQry += "                      WHERE Z1.D_E_L_E_T_ =' ' "
	cQry += "                        AND Z1_FILIAL = '" + xFilial("SZ1")+ "'"
	cQry += "                        AND Z1_STATUS <> '5' "
	cQry += "                        AND Z1_DEST <> '" + SM0->M0_CGC + "'"
	cQry += "                        AND A1.D_E_L_E_T_ =' ' "
	cQry += "                        AND A1_CGC = Z1_EMIT "
	cQry += "                        AND A1_LOJA = '" + cInLoja + "'"
	cQry += "                        AND A1_COD ='" +cInCli +"'"
	cQry += "                        AND Z1_TIPNF = '1' "
	cQry += "                        AND A1_FILIAL = '" + xFilial("SA1") + "'"
	cQry += "                        AND EXISTS (SELECT F1_DOC"
	cQry += "                                      FROM " + RetSqlName("SF1") + " F1 "
	cQry += "                                     WHERE F1_FORNECE = A1_COD "
	cQry += "                                       AND F1_LOJA = A1_LOJA"
	cQry += "                                       AND F1.D_E_L_E_T_ = ' '"
	cQry += "                                       AND F1_FILIAL = '" +xFilial("SF1")+ "' "
	cQry += "                                       AND F1_DTDIGIT <= '" + DTOS(MV_PAR08) + "')"
	cQry += "                        AND Z1_EMISSAO >= '20200101' " // Fixa data para evitar que consigam pegar periodo anterior até Julho/2018 que não foi corrigido corretamente durante a importação dos dados que vieram da Cloud
	cQry += "                        AND Z1_EMISSAO BETWEEN '" + DTOS(MV_PAR07)+ "' AND '" + DTOS(MV_PAR08) + "')"

	memowrite("c:\edi\rlfata01.sql",cqry)
	Begin Transaction
		nRet	:= TcSqlExec(cQry)
		If nRet <> 0
			MsgAlert(TCSQLError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Endif
	End Transaction

Return


/*/{Protheus.doc} sfF4Poder3
(Atualiza produto com os dados da nota de origem e identificação do poder de terceiros)
@type function
@author marce
@since 09/10/2016
@version 1.0
@param cProduto, character, (Descrição do parâmetro)
@param cTpNF, character, (Descrição do parâmetro)
@param cES, character, (Descrição do parâmetro)
@param cCliFor, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)
@param nLinha, numérico, (Descrição do parâmetro)
@param lExibeNfOri, ${param_type}, (Descrição do parâmetro)
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfF4Poder3(cProduto,cTpNF,cES,cCliFor,cLoja,nLinha,lExibeNfOri,aCols,aHeader,cInFciCod,lInFilFCI,cInClasFis)

	Local aArea     := GetArea()
	Local aOrdem    := {AllTrim(RetTitle("F2_DOC"))+"+"+AllTrim(RetTitle("F2_SERIE")),AllTrim(RetTitle("F2_EMISSAO"))}
	Local aChave    := {"B6_DOC+B6_SERIE","B6_EMISSAO","B6_IDENT"}
	Local aPesq     := {{Space(Len(SD1->D1_DOC+SD1->D1_SERIE)),"@!"},{Ctod(""),"@!"},{Space(Len(SB6->B6_IDENT)),"@!"}}
	Local aHeadTrb  := {}
	Local aStruTrb  := {}
	Local aTmSize   := MsAdvSize( .F. )
	Local aObjects  := {}
	Local aInfo     := {}
	Local aPosObj   := {}
	Local aNomInd   := {}
	Local aSavHead  := aClone(aHeader)
	Local aRegSB6   := {}
	Local cTpCliFor := IIf(cTpNF$"DB","F","C")
	Local cAliasSD1 := "SD1"
	Local cAliasSD2 := "SD2"
	Local cAliasSB6 := "SB6"
	Local cAliasTrb := "F4PODER3"
	Local cNomeTrb  := ""
	Local cQuery    := ""
	Local cQuery1   := ""
	Local cQuery2   := ""
	Local cQuery3   := ""
	Local cCombo    := ""
	Local cTexto1   := ""
	Local cTexto2   := ""
	Local cReadVar  := ReadVar()
	Local nHandle   := GetFocus()
	Local nIX        := 0
	Local nSldQtd   := 0
	Local nSldBru   := 0
	Local nSldLiq   := 0
	Local nOpcA     := 0
	Local nPNfOri   := 0
	Local nPSerOri  := 0
	Local nPItemOri := 0
	Local nPLocal   := 0
	Local nPPrUnit  := 0
	Local nPPrcVen  := 0
	Local nPValor	:= 0
	Local nPQuant   := 0
	Local nPQuant2UM:= 0
	Local nPLoteCtl := 0
	Local nPNumLote := 0
	Local nPDtValid := 0
	Local nPPotenc  := 0
	Local nPValDesc := 0
	Local nPDesc    := 0
	Local nPIdentB6 := 0
	Local nPItem    := 0
	Local nPUnit    := 0
	Local nPTES     := 0
	Local nPosLocal := 0
	Local nQtdLib	:= 0
	Local nPAlmTerc := 0
	Local nPE		:= 0
	Local nPClasFis	:= 0
	Local lQuery    := .F.
	Local lRetorno  := .F.
	Local lProcessa := .T.
	Local xPesq     := ""
	Local cSeekSD7  := ""
	Local oDlg
	Local oPanel
	Local oCombo
	Local oGet
	Local oGetDB
	Local cLocalCQ   := GETMV("MV_CQ")
	Local aArmazensCQ:= {},aTextoCQ:={}
	Local aNew       := {}
	Local aNF        := {}
	Local cNF        := ""
	Local aValNFR    := {}
	Local aValNFD    := {}
	Local aValNf     := {}
	Local nYY        := 0
	Local nXZ,nX         := 0
	Local aA440VCOL  := {}

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ MV_VLDDATA - Valida data de emissao do documento de beneficiamento  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local lVldData   := SuperGetMv("MV_VLDDATA",.F.,.T.)

	Local cNumPV 	:= ""
	Default	lExibeNfOri	:= .F.

	// Ajusta
	cProduto	:= Padr(cProduto,TamSX3("B6_PRODUTO")[1])

	// Ajusta o código de origem 1 para 2
	If Substr(cInClasFis,1,1) == "1"
		cInClasFis	:= "2" + Substr(cInClasFis,2,2)
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Montagem do arquivo temporario dos itens do SD1                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//dbSelectArea("SX3")
	//dbSetOrder(1)
	//DbSeek("SB6")
	//While !Eof() .And. GetSx3Cache(cCampo,"X3_ARQUIVO") == "SB6"
	aFields := {}

	aFields := FWSX3Util():GetAllFields("SB6", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]
		If ( X3USO(GetSx3Cache(cCampo,"X3_USADO")) .And. cNivel >= GetSx3Cache(cCampo,"X3_NIVEL") .And.;
				(IsTriangular() .Or. Trim(GetSx3Cache(cCampo,"X3_CAMPO")) <> "B6_CLIFOR") .And.;
				(IsTriangular() .Or. Trim(GetSx3Cache(cCampo,"X3_CAMPO")) <> "B6_LOJA") .And.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) <> "B6_PRODUTO" .And.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) <> "B6_QUANT" .And.;
				GetSx3Cache(cCampo,"X3_CONTEXT")<>"V" .And.;
				GetSx3Cache(cCampo,"X3_TIPO")<>"M" ) .Or.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) == "B6_DOC" .Or.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) == "B6_SERIE"  .Or.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) == "B6_EMISSAO" .Or.;
				Trim(GetSx3Cache(cCampo,"X3_CAMPO")) == "B6_TIPO"
			Aadd(aHeadTrb,{ TRIM(X3Titulo()),;
				GetSx3Cache(cCampo,"X3_CAMPO"),;
				GetSx3Cache(cCampo,"X3_PICTURE"),;
				GetSx3Cache(cCampo,"X3_TAMANHO"),;
				GetSx3Cache(cCampo,"X3_DECIMAL"),;
				GetSx3Cache(cCampo,"X3_VALID"),;
				GetSx3Cache(cCampo,"X3_USADO"),;
				GetSx3Cache(cCampo,"X3_TIPO"),;
				GetSx3Cache(cCampo,"X3_ARQUIVO"),;
				GetSx3Cache(cCampo,"X3_CONTEXT"),;
				IIf(AllTrim(GetSx3Cache(cCampo,"X3_CAMPO"))$"B6_DOC#B6_SERIE#B6_IDENT","00",GetSx3Cache(cCampo,"X3_ORDEM")) })
			aadd(aStruTRB,{GetSx3Cache(cCampo,"X3_CAMPO"),GetSx3Cache(cCampo,"X3_TIPO"),GetSx3Cache(cCampo,"X3_TAMANHO"),GetSx3Cache(cCampo,"X3_DECIMAL"),IIf(AllTrim(GetSx3Cache(cCampo,"X3_CAMPO"))$"B6_DOC#B6_SERIE","00",GetSx3Cache(cCampo,"X3_ORDEM"))})
			If Trim(GetSx3Cache(cCampo,"X3_CAMPO")) == "B6_PRUNIT"
				Aadd(aHeadTrb,{ OemToAnsi("Valor Liquido"),;
					"B6_PRCVEN",;
					GetSx3Cache(cCampo,"X3_PICTURE"),;
					GetSx3Cache(cCampo,"X3_TAMANHO"),;
					GetSx3Cache(cCampo,"X3_DECIMAL"),;
					GetSx3Cache(cCampo,"X3_VALID"),;
					GetSx3Cache(cCampo,"X3_USADO"),;
					GetSx3Cache(cCampo,"X3_TIPO"),;
					GetSx3Cache(cCampo,"X3_ARQUIVO"),;
					GetSx3Cache(cCampo,"X3_CONTEXT"),;
					GetSx3Cache(cCampo,"X3_ORDEM")})
				aadd(aStruTRB,{"B6_PRCVEN",GetSx3Cache(cCampo,"X3_TIPO"),GetSx3Cache(cCampo,"X3_TAMANHO"),GetSx3Cache(cCampo,"X3_DECIMAL"),GetSx3Cache(cCampo,"X3_ORDEM")})
			EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica a existencia do campo B6_LOTECLT para criar indice de pesq.³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If Trim(GetSx3Cache(cCampo,"X3_CAMPO"))=="B6_LOTECTL"
				aadd(aChave,"B6_LOTECTL")
				aadd(aOrdem,AllTrim(RetTitle("B6_IDENT")))
				aadd(aOrdem,AllTrim(RetTitle("B6_LOTECTL")))
				aadd(aPesq,{Space(Len(SB6->B6_LOTECTL)),""})
			EndIf
		EndIf
		//	dbSelectArea("SX3")
		//	dbSkip()
		//EndDo
	Next nX


	aadd(aStruTRB,{"B6_TOTALL","N",18,2,"99"})
	aadd(aStruTRB,{"B6_TOTALB","N",18,2,"99"})
	aadd(aStruTRB,{"D2_NUMLOTE","C", 6,0,""})
	aadd(aStruTRB,{"D2_LOTECTL","C",10,0,""})
	aadd(aStruTRB,{"D1_NUMLOTE","C", 6,0,""})
	aadd(aStruTRB,{"D1_LOTECTL","C",10,0,""})
	aadd(aStruTrb,{"SD2RECNO" ,"N",18,0,"99"})
	aadd(aStruTrb,{"SD1RECNO" ,"N",18,0,"99"})
	aHeadTrb := aSort(aHeadTrb,,,{|x,y| x[11] < y[11]})
	aStruTrb := aSort(aStruTrb,,,{|x,y| x[05] < y[05]})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajuste das casas decimais conforme a rotina                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SX3")
	dbSetOrder(2)
	DbSeek("D1_VUNIT")
	nIX := aScan(aHeadTrb,{|x| AllTrim(x[2]) == "B6_PRUNIT"})
	If nIX > 0
		aHeadTrb[nIX][3] := GetSx3Cache(cCampo,"X3_PICTURE")
		aHeadTrb[nIX][4] := 	GetSx3Cache(cCampo,"X3_TAMANHO")
		aHeadTrb[nIX][5] := 	GetSx3Cache(cCampo,"X3_DECIMAL")
	EndIf
	nIX := aScan(aHeadTrb,{|x| AllTrim(x[2]) == "B6_PRCVEN"})
	If nIX > 0
		aHeadTrb[nIX][3] := GetSx3Cache(cCampo,"X3_PICTURE")
		aHeadTrb[nIX][4] := 	GetSx3Cache(cCampo,"X3_TAMANHO")
		aHeadTrb[nIX][5] := 	GetSx3Cache(cCampo,"X3_DECIMAL")
	EndIf
	If Rastro(cProduto)
		If DbSeek("D1_LOTECTL")
			Aadd(aHeadTrb,{ TRIM(X3Titulo()),;
				"D1_LOTECTL",;
				GetSx3Cache(cCampo,"X3_PICTURE"),;
				GetSx3Cache(cCampo,"X3_TAMANHO"),;
				GetSx3Cache(cCampo,"X3_DECIMAL"),;
				GetSx3Cache(cCampo,"X3_VALID"),;
				GetSx3Cache(cCampo,"X3_USADO"),;
				GetSx3Cache(cCampo,"X3_TIPO"),;
				GetSx3Cache(cCampo,"X3_ARQUIVO"),;
				GetSx3Cache(cCampo,"X3_CONTEXT"),;
				"98" })
		EndIf
		If DbSeek("D1_NUMLOTE")
			Aadd(aHeadTrb,{ TRIM(X3Titulo()),;
				"D1_NUMLOTE",;
				GetSx3Cache(cCampo,"X3_PICTURE"),;
				GetSx3Cache(cCampo,"X3_TAMANHO"),;
				GetSx3Cache(cCampo,"X3_DECIMAL"),;
				GetSx3Cache(cCampo,"X3_VALID"),;
				GetSx3Cache(cCampo,"X3_USADO"),;
				GetSx3Cache(cCampo,"X3_TIPO"),;
				GetSx3Cache(cCampo,"X3_ARQUIVO"),;
				GetSx3Cache(cCampo,"X3_CONTEXT"),;
				"99" })
		EndIf
	EndIf

	//ARQUIVO TEMPORARIO DE MEMORIA (CTREETMP)
	// Funcao MSOpenTemp ira substituir as duas linhas de codigo abaixo:
	//|--> cNomeTrb := CriaTrab(aStruTRB,.T.)                              |
	//|--> dbUseArea(.T.,__LocalDrive,cNomeTrb,cAliasTRB,.F.,.F.)          |

	//MSOpenTemp(cAliasTRB,aStruTRB,@cNomeTrb)

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	cAliasTRB := GetNextALias()
	oTmpTable := FWTemporaryTable():New(cAliasTRB,aStruTRB)
	oTmpTable:AddIndex( '01',{"B6_DOC","B6_SERIE"})
	oTmpTable:AddIndex( '02',{"B6_EMISSAO"})
	oTmpTable:AddIndex( '03',{"B6_IDENT"})
	oTmpTable:Create()


	//cNomeTrb := CriaTrab(aStruTRB,.T.)
	//dbUseArea(.T.,__LocalDrive,cNomeTrb,cAliasTRB,.F.,.F.)

	dbSelectArea(cAliasTRB)
	//For nIX := 1 To Len(aChave)
	//	aadd(aNomInd,SubStr(cNomeTrb,1,7)+chr(64+nIX))
	//	IndRegua(cAliasTRB,aNomInd[nIX],aChave[nIX])
	//Next nIX
	//dbClearIndex()
	//For nIX := 1 To Len(aNomInd)
	//	dbSetIndex(aNomInd[nIX])
	//Next nIX

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verificacao do aHeader atual                                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nPQuant   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_QTDVEN"})
	nPValor   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_VALOR"})
	nPIdentB6 := aScan(aHeader,{|x| AllTrim(x[2])=="C6_IDENTB6"})
	nPItem    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"} )
	nPUnit    := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRCVEN"} )
	nPTES     := aScan(aHeader,{|x| AllTrim(x[2])=="C6_TES"} )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualizacao do arquivo temporario com base nos itens do SD1         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SB6")
	dbSetOrder(2)
	#IFDEF TOP
		If TcSrvType()<>"AS/400" .And. TcSrvType()<>"iSeries" .And. !("POSTGRES" $ TCGetDB())
			lQuery    := .T.
			cAliasSB6 := "F4PODER3_SQL"
			cAliasSD1 := "F4PODER3_SQL"
			cAliasSD2 := "F4PODER3_SQL"

			If cES == "E"
				cQuery := "SELECT DISTINCT(0) SD1RECNO,SB6.R_E_C_N_O_ SB6RECNO,0 D1_VUNIT,0 D1_TOTAL,0 D1_VALDESC,SD2.R_E_C_N_O_ SD2RECNO,D2_PRCVEN,D2_TOTAL,D2_DESCON, D2_NUMLOTE NUMLOTE,D2_LOTECTL LOTECTL,D2_TIPO,'' D1_TIPO, "
			Else
				cQuery := "SELECT DISTINCT(SD1.R_E_C_N_O_) SD1RECNO,SB6.R_E_C_N_O_ SB6RECNO,D1_VUNIT,D1_TOTAL,D1_VALDESC,0 SD2RECNO,0 D2_PRCVEN,0 D2_TOTAL,0 D2_DESCON,D1_NUMLOTE NUMLOTE,D1_LOTECTL LOTECTL,'' D2_TIPO,D1_TIPO, "
			EndIf
			If SB6->(FieldPos("B6_IDENTB6"))==0
				cQuery += "B6_FILIAL,B6_PRODUTO,B6_CLIFOR,B6_LOJA,B6_PODER3,B6_TPCF,B6_QUANT,B6_QULIB "
			Else
				cQuery += "B6_FILIAL,B6_PRODUTO,B6_CLIFOR,B6_LOJA,B6_PODER3,B6_IDENTB6,B6_TPCF,B6_QUANT,B6_QULIB "
			EndIf
			For nIX := 1 To Len(aHeadTRB)
				If aHeadTRB[nIX][2]<>"B6_PRCVEN"    .AND.;
						aHeadTRB[nIX][2]<>"D2_NUMLOTE"  .AND.;
						aHeadTRB[nIX][2]<>"D2_LOTECTL"  .And.;
						aHeadTRB[nIX][2]<>"D2_TIPO"     .And.;
						aHeadTRB[nIX][2]<>"D1_NUMLOTE"  .AND.;
						aHeadTRB[nIX][2]<>"D1_LOTECTL"  .And.;
						aHeadTRB[nIX][2]<>"D1_TIPO"     .And.;
						aHeadTRB[nIX][2]<>"B6_CLIFOR"   .And.;
						aHeadTRB[nIX][2]<>"B6_LOJA"     .And.;
						aHeadTRB[nIX][2]<>"B6_PODER3"   .And.;
						aHeadTRB[nIX][2]<>"B6_QULIB"
					cQuery += ","+aHeadTRB[nIX][2]+" "
				EndIf
			Next nIX
			cQuery1:= " FROM "+RetSqlName("SB6")+" SB6 ,"
			cQuery1 += RetSqlName("SD1")+" SD1 "
			cQuery1 += "WHERE SB6.B6_FILIAL='"+xFilial("SB6")+"' AND "
			cQuery1 += "SB6.B6_PRODUTO    = '"+cProduto+"' AND "
			If !IsTriangular()
				cQuery1 += "SB6.B6_CLIFOR = '"+cCliFor+"' AND "
				cQuery1 += "SB6.B6_LOJA   = '"+cLoja+"' AND "
			EndIf
			cQuery1 += "SB6.B6_PODER3  = 'R' AND "
			cQuery1 += "SB6.B6_TPCF    = '"+cTpCliFor+"' AND "
			cQuery1 += "SB6.D_E_L_E_T_ = ' ' AND "
			cQuery1 += "SB6.B6_TIPO   = 'D' AND "
			cQuery1 += "SD1.D1_FILIAL = '"+xFilial("SD1")+"' AND "
			cQuery1 += "SD1.D1_NUMSEQ = SB6.B6_IDENT AND "
			If lVldData
				cQuery1 += "SD1.D1_DTDIGIT <= '" + DTOS(dDataBase) + "' AND "
			EndIf
			// Efetua o filtro pelo código FCI para garantir a nota de origem seja pesquisada corretamente
			If lInFilFCI
				cQuery1 += "  ((D1_FCICOD = '" + cInFciCod + "' AND SUBSTR(D1_CLASFIS,1,1) = '" + Substr(cInClasFis,1,1) + "') "
				cQuery1 += "   OR (D1_FCICOD <> '" + cInFciCod + "' AND SUBSTR(D1_CLASFIS,1,1) = '" + Substr(cInClasFis,1,1) + "' ) "
				cQuery1 += "   OR (D1_FCICOD <> '" + cInFciCod + "' AND SUBSTR(D1_CLASFIS,1,1) <> '" + Substr(cInClasFis,1,1) + "' ) "
				cQuery1 += "  ) AND "
			Endif
			cQuery1 += "  SD1.D_E_L_E_T_=' ' "
			cQuery1 += "  AND EXISTS (SELECT B6_FILIAL,"
			cQuery1 += "                     B6_PRODUTO,"
			cQuery1 += "                     B6_IDENT,   "
			cQuery1 += "                     B6_PRUNIT,   "
			cQuery1 += "                     SUM(CASE WHEN B6_PODER3 = 'R' THEN B6_QUANT ELSE 0 END) REMESSA,"
			cQuery1 += "                     SUM(CASE WHEN B6_PODER3 = 'D' THEN B6_QUANT ELSE 0 END) DEVOLVIDO,"
			cQuery1 += "                     SUM(CASE WHEN B6_PODER3 = 'D' THEN -1 * B6_QUANT ELSE B6_QUANT END) SALDO"
			cQuery1 += "                FROM "+RetSqlName("SB6") + " B6A, "+RetSqlName("SF4")+" SF4 "
			cQuery1 += "               WHERE B6A.B6_FILIAL = '"+xFilial("SB6")+"' "
			cQuery1 += "                 AND B6A.D_E_L_E_T_ = ' '"
			cQuery1 += "                 AND B6A.B6_ATEND != 'S' "
			If !IsTriangular()
				cQuery1 += "             AND B6A.B6_CLIFOR = '"+cCliFor+"' "
				cQuery1 += "             AND B6A.B6_LOJA   = '"+cLoja+"' "
			EndIf
			cQuery1 += "                 AND B6A.B6_PRODUTO    = '"+cProduto+"' "
			cQuery1 += "                 AND B6A.B6_IDENT = SB6.B6_IDENT "
			cQuery1 += "                 AND SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
			cQuery1 += "                 AND SF4.F4_CODIGO = B6A.B6_TES "
			cQuery1 += "                 AND SF4.D_E_L_E_T_ = ' ' "
			cQuery1 += "               GROUP BY B6_FILIAL,B6_PRODUTO,B6_IDENT,B6_PRUNIT "
			cQuery1 += "              HAVING SUM(CASE WHEN B6_PODER3 = 'D' THEN -1 * B6_QUANT ELSE B6_QUANT END) > 0)"

			cQuery += cQuery1 + " UNION ALL "
			cQuery += "SELECT DISTINCT(0) SD1RECNO,SB6.R_E_C_N_O_ SB6RECNO,0 D1_VUNIT,0 D1_TOTAL,0 D1_VALDESC,SD2.R_E_C_N_O_ SD2RECNO,D2_PRCVEN,D2_TOTAL,D2_DESCON,D2_NUMLOTE NUMLOTE,D2_LOTECTL LOTECTL, D2_TIPO,'' D1_TIPO, "
			If SB6->(FieldPos("B6_IDENTB6"))==0
				cQuery += "B6_FILIAL,B6_PRODUTO,B6_CLIFOR,B6_LOJA,B6_PODER3,B6_TPCF,B6_QUANT,B6_QULIB "
			Else
				cQuery += "B6_FILIAL,B6_PRODUTO,B6_CLIFOR,B6_LOJA,B6_PODER3,B6_IDENTB6,B6_TPCF,B6_QUANT,B6_QULIB "
			EndIf
			For nIX := 1 To Len(aHeadTRB)
				If aHeadTRB[nIX][2]<>"B6_PRCVEN"    .AND.;
						aHeadTRB[nIX][2]<>"D2_NUMLOTE"  .AND.;
						aHeadTRB[nIX][2]<>"D2_LOTECTL"  .And.;
						aHeadTRB[nIX][2]<>"D2_TIPO"     .And.;
						aHeadTRB[nIX][2]<>"D1_NUMLOTE"  .AND.;
						aHeadTRB[nIX][2]<>"D1_LOTECTL"  .And.;
						aHeadTRB[nIX][2]<>"D1_TIPO"     .And.;
						aHeadTRB[nIX][2]<>"B6_CLIFOR"   .And.;
						aHeadTRB[nIX][2]<>"B6_LOJA"     .And.;
						aHeadTRB[nIX][2]<>"B6_PODER3"   .And.;
						aHeadTRB[nIX][2]<>"B6_QULIB"

					cQuery += ","+aHeadTRB[nIX][2]+" "
				EndIf
			Next nIX
			cQuery2:= " FROM "+RetSqlName("SB6")+" SB6 ,"
			cQuery2 += RetSqlName("SD2")+" SD2 "
			cQuery2 += "WHERE SB6.B6_FILIAL = '"+xFilial("SB6")+"' AND "
			cQuery2 += "SB6.B6_PRODUTO	   = '"+cProduto+"' AND "
			cQuery2 += "SB6.B6_PODER3	   = 'D' AND "
			cQuery2 += "SB6.B6_TPCF         = '"+cTpCliFor+"' AND "
			cQuery2 += "SB6.D_E_L_E_T_	   = ' ' AND "

			If !IsTriangular()
				cQuery2 += "SB6.B6_CLIFOR='"+cCliFor+"' AND "
				cQuery2 += "SB6.B6_LOJA='"+cLoja+"' AND "
			EndIf

			cQuery2 += "SB6.B6_TIPO    ='D' AND "
			cQuery2 += "SD2.D2_FILIAL  ='"+xFilial("SD2")+"' AND "
			// Efetua o filtro pelo código FCI para garantir a nota de origem seja pesquisada corretamente
			If lInFilFCI
				cQuery1 += "  ((D2_FC2COD = '" + cInFciCod + "' AND SUBSTR(D2_CLASFIS,1,1) = '" + Substr(cInClasFis,1,1) + "') "
				cQuery1 += "   OR (D2_FCICOD <> '" + cInFciCod + "' AND SUBSTR(D2_CLASFIS,1,1) = '" + Substr(cInClasFis,1,1) + "' ) "
				cQuery1 += "   OR (D2_FCICOD <> '" + cInFciCod + "' AND SUBSTR(D2_CLASFIS,1,1) <> '" + Substr(cInClasFis,1,1) + "' ) "
				cQuery1 += "  ) AND "
			Endif
			cQuery2 += "SD2.D2_DOC	  = SB6.B6_DOC AND "
			cQuery2 += "SD2.D2_SERIE   = SB6.B6_SERIE AND "
			cQuery2 += "SD2.D2_CLIENTE = SB6.B6_CLIFOR AND "
			cQuery2 += "SD2.D2_LOJA    = SB6.B6_LOJA AND "
			cQuery2 += "SD2.D2_COD     = SB6.B6_PRODUTO AND "
			cQuery2 += "SD2.D2_IDENTB6 = SB6.B6_IDENT AND "
			cQuery2 += "SD2.D2_QUANT	  = SB6.B6_QUANT AND "
			If lVldData
				cQuery2 += "SD2.D2_EMISSAO <= '" + DTOS(dDataBase) + "' AND "
			EndIf
			cQuery2 += "SD2.D_E_L_E_T_=' ' "

			cQuery2 += "  AND EXISTS (SELECT B6_FILIAL,"
			cQuery2 += "                     B6_PRODUTO,"
			cQuery2 += "                     B6_IDENT,   "
			cQuery2 += "                     B6_PRUNIT,   "
			cQuery2 += "                     SUM(CASE WHEN B6_PODER3 = 'R' THEN B6_QUANT ELSE 0 END) REMESSA,"
			cQuery2 += "                     SUM(CASE WHEN B6_PODER3 = 'D' THEN B6_QUANT ELSE 0 END) DEVOLVIDO,"
			cQuery2 += "                     SUM(CASE WHEN B6_PODER3 = 'D' THEN -1 * B6_QUANT ELSE B6_QUANT END) SALDO"
			cQuery2 += "                FROM "+RetSqlName("SB6") + " B6A, "+RetSqlName("SF4")+" SF4 "
			cQuery2 += "               WHERE B6A.B6_FILIAL = '"+xFilial("SB6")+"' "
			cQuery2 += "                 AND B6A.D_E_L_E_T_ = ' '"
			cQuery2 += "                 AND B6A.B6_ATEND != 'S' "
			If !IsTriangular()
				cQuery2 += "             AND B6A.B6_CLIFOR = '"+cCliFor+"' "
				cQuery2 += "             AND B6A.B6_LOJA   = '"+cLoja+"' "
			EndIf
			cQuery2 += "                 AND B6A.B6_PRODUTO    = '"+cProduto+"' "

			cQuery2 += "                 AND B6A.B6_IDENT = SB6.B6_IDENT "
			cQuery2 += "                 AND SF4.F4_FILIAL = '"+xFilial("SF4")+"' "
			cQuery2 += "                 AND SF4.F4_CODIGO = B6A.B6_TES "
			cQuery2 += "                 AND SF4.D_E_L_E_T_ = ' ' "
			cQuery2 += "               GROUP BY B6_FILIAL,B6_PRODUTO,B6_IDENT,B6_PRUNIT "
			cQuery2 += "              HAVING SUM(CASE WHEN B6_PODER3 = 'D' THEN -1 * B6_QUANT ELSE B6_QUANT END) > 0) "

			cQuery := cQuery + cQuery2
			cQuery := ChangeQuery(cQuery)

			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSB6,.T.,.F.)

			For nIX := 1 To Len(aStruTRB)
				If aStruTRB[nIX][2] <> "C" .And. FieldPos(aStruTRB[nIX][1])<>0
					TcSetField(cAliasSB6,aStruTRB[nIX][1],aStruTRB[nIX][2],aStruTRB[nIX][3],aStruTRB[nIX][4])
				EndIf
			Next nIX

			TcSetField(cAliasSD1,"D1_TOTAL","N",TamSx3("D1_TOTAL")[1], TamSx3("D1_TOTAL")[2] )
			TcSetField(cAliasSD1,"D1_VALDESC","N",TamSx3("D1_VALDESC")[1], TamSx3("D1_TOTAL")[2] )
			TcSetField(cAliasSD1,"D2_TOTAL","N",TamSx3("D2_TOTAL")[1], TamSx3("D2_TOTAL")[2] )
			TcSetField(cAliasSD1,"D2_DESCON","N",TamSx3("D2_DESCON")[1], TamSx3("D2_DESCON")[2] )
			TcSetField(cAliasSD1,"SD1RECNO","N",12, 0 )
			TcSetField(cAliasSD1,"SD2RECNO","N",12, 0 )
		Else
	#ENDIF
	If IsTriangular()
		DbSeek(xFilial("SB6")+cProduto)
	Else
		DbSeek(xFilial("SB6")+cProduto+cCliFor+cLoja,.F.)
	EndIf
	#IFDEF TOP
		EndIf
	#ENDIF

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//| Inicia Processo de Calculo  |
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lQuery
		//dbSelectArea(cAliasSB6)
		//dbGotop()
	EndIf

	While !Eof() .And. (cAliasSB6)->B6_FILIAL = xFilial("SB6") .And.  (cAliasSB6)->B6_PRODUTO == cProduto //.And.;
		//IIF(IsTriangular(),.T.,IIf(lQuery,.T.,(cAliasSB6)->B6_CLIFOR == cCliFor .And. (cAliasSB6)->B6_LOJA == cLoja ))


		lProcessa	:= .T.

		If lProcessa

			If !lQuery
				lProcessa := aScan(aRegSB6,SB6->( RecNo() ) ) == 0
			Else
				lProcessa := aScan(aRegSB6,(cAliasSB6)->SB6RECNO)==0
			EndIf

		EndIf

		If lProcessa

			If ((cES == "E" .And. (cAliasSB6)->B6_TIPO == "E") .Or. (cES == "S" .And. (cAliasSB6)->B6_TIPO == "D") ) .And.;
					(cAliasSB6)->B6_TPCF==cTpCliFor
				If !lQuery
					aadd(aRegSB6,SB6->(RecNo()))
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Verificar qual eh a tabela de origem do poder de terceiros          ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If ((cAliasSB6)->B6_TIPO=="D" .And. (cAliasSB6)->B6_PODER3 == "R" ) .Or. ((cAliasSB6)->B6_TIPO=="E" .And. (cAliasSB6)->B6_PODER3 == "D")
						If (cAliasSB6)->B6_PODER3 == "R"
							dbSelectArea("SD1")
							dbSetOrder(4)
							DbSeek(xFilial("SD1")+(cAliasSB6)->B6_IDENT)
						Else
							dbSelectArea("SD1")
							dbSetOrder(1)
							DbSeek(xFilial("SD1")+(cAliasSB6)->B6_DOC+(cAliasSB6)->B6_SERIE+(cAliasSB6)->B6_CLIFOR+(cAliasSB6)->B6_LOJA+(cAliasSB6)->B6_PRODUTO)
							While !Eof() .And. xFilial("SD1") == SD1->D1_FILIAL .And.;
									(cAliasSB6)->B6_DOC       == SD1->D1_DOC .And.;
									(cAliasSB6)->B6_SERIE     == SD1->D1_SERIE .And.;
									(cAliasSB6)->B6_CLIFOR    == SD1->D1_FORNECE .And.;
									(cAliasSB6)->B6_LOJA      == SD1->D1_LOJA .And.;
									(cAliasSB6)->B6_PRODUTO   == SD1->D1_COD

								If (cAliasSB6)->B6_IDENT==SD1->D1_IDENTB6 .And. (cAliasSB6)->B6_QUANT=SD1->D1_QUANT
									Exit
								EndIf

								dbSelectArea("SD1")
								dbSkip()
							EndDo
						EndIf
					Else
						If (cAliasSB6)->B6_PODER3=="R"
							dbSelectArea("SD2")
							dbSetOrder(4)
							DbSeek(xFilial("SD2")+(cAliasSB6)->B6_IDENT)
						Else
							dbSelectArea("SD2")
							dbSetOrder(3)
							DbSeek(xFilial("SD2")+(cAliasSB6)->B6_DOC+(cAliasSB6)->B6_SERIE+(cAliasSB6)->B6_CLIFOR+(cAliasSB6)->B6_LOJA+(cAliasSB6)->B6_PRODUTO)
							While !Eof() .And. xFilial("SD2") == SD2->D2_FILIAL .And.;
									(cAliasSB6)->B6_DOC == SD2->D2_DOC .And.;
									(cAliasSB6)->B6_SERIE == SD2->D2_SERIE .And.;
									(cAliasSB6)->B6_CLIFOR == SD2->D2_CLIENTE .And.;
									(cAliasSB6)->B6_LOJA == SD2->D2_LOJA .And.;
									(cAliasSB6)->B6_PRODUTO == SD2->D2_COD
								If (cAliasSB6)->B6_IDENT==SD2->D2_IDENTB6 .And. (cAliasSB6)->B6_QUANT=SD2->D2_QUANT
									Exit
								EndIf
								dbSelectArea("SD2")
								dbSkip()
							EndDo
						EndIf
					EndIf
				Else
					aadd(aRegSB6,(cAliasSB6)->SB6RECNO)
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Calculo do saldo em valor e quantidade para devolucao de terceiros  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nSldQtd := 0
				nSldBru := 0
				nSldLiq := 0
				If ((cAliasSB6)->B6_TIPO=="D" .And. (cAliasSB6)->B6_PODER3 == "R" ) .Or. ((cAliasSB6)->B6_TIPO=="E" .And. (cAliasSB6)->B6_PODER3 == "D")
					lProcessa := lProcessa .And. (cAliasSD1)->D1_TIPO<>"I"
				Else
					lProcessa := lProcessa .And. (cAliasSD2)->D2_TIPO<>"I"
				EndIf
				If lProcessa
					If (cAliasSB6)->B6_PODER3 == "R" .And. (SB6->(FieldPos("B6_IDENTB6"))==0 .Or. Empty((cAliasSB6)->B6_IDENTB6))
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Na primeira remessa deve-se tirar os valores contidos na interface  ³
						//³ para evitar baixa de saldo maior que o disponivel                   ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						For nIX := 1 To Len(aCols)
							If nIX <> N .And. !aCols[nIX][Len(aHeader)+1] .And. aCols[nIX][nPIdentB6]==(cAliasSB6)->B6_IDENT
								nSldQtd -= aCols[nIX][nPQuant]
								nSldLiq -= aCols[nIX][nPValor]

								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³ Desconsidera a quantidade ja faturada                               ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								If !Empty( cNumPV )
									SC6->( dbSetOrder( 1 ) )
									If SC6->( DbSeek( xFilial( "SC6" ) + cNumPv + aCols[nIX, nPItem ] ) )
										nSldQtd += SC6->C6_QTDENT
										nSldLiq += aCols[nIX,nPUnit] * SC6->C6_QTDENT
										nSldLiq := A410Arred( nSldLiq, "C6_VALOR" )
									EndIf
								EndIf

							EndIf
						Next nIX
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Calculo do saldo do poder de terceiros                              ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						nSldQtd  += (cAliasSB6)->B6_QUANT-(cAliasSB6)->B6_QULIB
					Else
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Calculo do saldo do poder de terceiros                              ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						nSldQtd  -= (cAliasSB6)->B6_QUANT-(cAliasSB6)->B6_QULIB
					EndIf
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Verificar qual eh a tabela de origem do poder de terceiros e calcula³
					//³ o valor total do saldo de poder de/em terceiros                     ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If ((cAliasSB6)->B6_TIPO=="D" .And. (cAliasSB6)->B6_PODER3 == "R" ) .Or. ((cAliasSB6)->B6_TIPO=="E" .And. (cAliasSB6)->B6_PODER3 == "D")
						If (cAliasSB6)->B6_PODER3 == "R"
							nSldLiq += (cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC
							nSldBru += nSldLiq+A410Arred(nSldLiq*(cAliasSD1)->D1_VALDESC/((cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC),"C6_VALOR")
						Else
							nSldLiq -= (cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC
							nSldBru -= Abs(nSldLiq)+A410Arred(Abs(nSldLiq)*(cAliasSD1)->D1_VALDESC/((cAliasSD1)->D1_TOTAL-(cAliasSD1)->D1_VALDESC),"C6_VALOR")
						EndIf
					Else
						If (cAliasSB6)->B6_PODER3 == "R"
							nSldBru += (cAliasSD2)->D2_TOTAL+(cAliasSD2)->D2_DESCON
							nSldLiq += nSldBru-A410Arred(nSldBru*(cAliasSD2)->D2_DESCON/((cAliasSD2)->D2_TOTAL+(cAliasSD2)->D2_DESCON),"C6_VALOR")
						Else
							nSldBru -= (cAliasSD2)->D2_TOTAL+(cAliasSD2)->D2_DESCON
							nSldLiq -= Abs(nSldBru)-A410Arred(Abs(nSldBru)*(cAliasSD2)->D2_DESCON/((cAliasSD2)->D2_TOTAL+(cAliasSD2)->D2_DESCON),"C6_VALOR")
						EndIf
					EndIf
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Atualiza o arquivo temporario com os dados do poder de terceiro     ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					dbSelectArea(cAliasTRB)
					dbSetOrder(3)
					If nSldQtd <> 0 .Or. nSldLiq <> 0
						If (cAliasSB6)->(FieldPos("B6_IDENTB6"))<>0 .And. !Empty((cAliasSB6)->B6_IDENTB6)
							(cAliasTRB)->(DbSeek((cAliasSB6)->B6_IDENTB6))
						Else
							(cAliasTRB)->(DbSeek((cAliasSB6)->B6_IDENT))
						EndIf
						If (cAliasTRB)->(!Found())
							RecLock(cAliasTRB,.T.)
							For nIX := 1 To Len(aStruTRB)
								If !AllTrim(aStruTRB[nIX][1])$"B6_SALDO#B6_TOTALL#B6_TOTALB#B6_QULIB"
									If (cAliasSB6)->(FieldPos(aStruTRB[nIX][1]))<>0 .And. (cAliasTrb)->(FieldPos(aStruTRB[nIX][1]))<>0
										(cAliasTRB)->(FieldPut(nIX,(cAliasSB6)->(FieldGet(FieldPos(aStruTRB[nIX][1])))))
									EndIf
								EndIf
							Next nIX
						Else
							RecLock(cAliasTRB)
						EndIf
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Verifica o documento original para obter alguns dados posteriores   ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If (cAliasSB6)->B6_PODER3 == "R" .And. (SB6->(FieldPos("B6_IDENTB6"))==0 .Or. Empty((cAliasSB6)->B6_IDENTB6))
							For nIX := 1 To Len(aStruTRB)
								If !AllTrim(aStruTRB[nIX][1])$"B6_SALDO#B6_TOTALL#B6_TOTALB#B6_QULIB"
									If (cAliasSB6)->(FieldPos(aStruTRB[nIX][1]))<>0 .And. (cAliasTrb)->(FieldPos(aStruTRB[nIX][1]))<>0
										(cAliasTRB)->(FieldPut(nIX,(cAliasSB6)->(FieldGet(FieldPos(aStruTRB[nIX][1])))))
									EndIf
								EndIf
							Next nIX
							If (cAliasSB6)->B6_TIPO=="D"
								(cAliasTRB)->SD1RECNO := IIf(lQuery,(cAliasSD1)->SD1RECNO,SD1->(RecNo()))
							Else
								(cAliasTRB)->SD2RECNO := IIf(lQuery,(cAliasSD2)->SD2RECNO,SD2->(RecNo()))
							EndIf
						EndIf
						(cAliasTRB)->B6_SALDO += a410Arred(nSldQtd,"C6_QTDVEN")
						(cAliasTRB)->B6_QULIB += a410Arred((cAliasSB6)->B6_QULIB,"C6_QTDVEN")
						(cAliasTRB)->B6_TOTALL+= nSldLiq
						(cAliasTRB)->B6_TOTALB+= nSldBru

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Calcula o valor unitario do poder de terceiros                      ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						(cAliasTRB)->B6_PRCVEN:= a410Arred((cAliasTRB)->B6_TOTALL/((cAliasTRB)->B6_SALDO+(cAliasTRB)->B6_QULIB),"D2_PRCVEN")

						(cAliasTRB)->B6_PRUNIT:= a410Arred((cAliasTRB)->B6_TOTALB/((cAliasTRB)->B6_SALDO+(cAliasTRB)->B6_QULIB),"D2_PRCVEN")
						If (cAliasTRB)->B6_PRUNIT == (cAliasTRB)->B6_PRCVEN .And. Abs((cAliasTRB)->B6_PRCVEN-(cAliasSD1)->D1_VUNIT)<=.01
							(cAliasTRB)->B6_PRUNIT := A410Arred((cAliasSD1)->D1_VUNIT,"C6_PRCVEN")
							(cAliasTRB)->B6_PRCVEN := A410Arred((cAliasSD1)->D1_VUNIT,"C6_PRCVEN")
						EndIf

						(cAliasTRB)->D1_LOTECTL:= IIf(lQuery,(cAliasSD1)->LOTECTL,(cAliasSD1)->D1_LOTECTL)
						(cAliasTRB)->D1_NUMLOTE:= IIf(lQuery,(cAliasSD1)->NUMLOTE,(cAliasSD1)->D1_NUMLOTE)

						MsUnLock()

					EndIf
				EndIf
			EndIf
		EndIf
		dbSelectArea(cAliasSB6)
		dbSkip()
	EndDo

	If lQuery
		/*dbSelectArea(cAliasSB6)
		dbCloseArea()
		If Type("cNomeSb6") <> "U"
		FErase(cNomeSb6 + GetDbExtension()) // Deleting file
		FErase(cNomeSb6+ OrdBagExt()) // Deleting index
		Endif
		dbSelectArea("SB6")*/


		//RQUIVO TEMPORARIO DE MEMORIA (CTREETMP)
		//Funcao MSCloseTemp ira substituir a linha de codigo abaixo:
		// dbCloseArea()
		MSCloseTemp(cAliasSB6,cNomeTrb)

		dbSelectArea("SB6")
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Retira os documentos totalmente devolvidos                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nPQuant   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_QTDVEN"})

	dbSelectArea(cAliasTRB)
	dbClearIndex()
	dbGotop()
	While !Eof()
		If (cAliasTRB)->B6_SALDO == 0
			dbDelete()
		EndIf
		dbSkip()
	EndDo
	Pack
	aNomInd := {}
	For nIX := 1 To Len(aChave)
		aadd(aNomInd,SubStr(cNomeTrb,1,7)+chr(64+nIX))
		//IndRegua(cAliasTRB,aNomInd[nIX],aChave[nIX])
	Next nIX
	//dbClearIndex()
	//For nIX := 1 To Len(aNomInd)
	//	dbSetIndex(aNomInd[nIX])
	//Next nIX
	dbGotop()
	
	PRIVATE aHeader := aHeadTRB
	
	//xPesq := aPesq[(cAliasTRB)->(IndexOrd())][1]
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Posiciona registros                                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cTpCliFor == "C"
		dbSelectArea("SA1")
		dbSetOrder(1)
		DbSeek(xFilial("SA1")+cCliFor+cLoja)
	Else
		dbSelectArea("SA2")
		dbSetOrder(1)
		DbSeek(xFilial("SA2")+cCliFor+cLoja)
	EndIf
	dbSelectArea("SB1")
	dbSetOrder(1)
	DbSeek(xFilial("SB1")+cProduto)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calcula as coordenadas da interface                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aTmSize[1] /= 1.5
	aTmSize[2] /= 1.5
	aTmSize[3] /= 1.5
	aTmSize[4] /= 1.3
	aTmSize[5] /= 1.5
	aTmSize[6] /= 1.3
	aTmSize[7] /= 1.5


	AAdd( aObjects, { 100, 020,.T.,.F.,.T.} )
	AAdd( aObjects, { 100, 060,.T.,.T.} )
	AAdd( aObjects, { 100, 020,.T.,.F.} )
	aInfo   := { aTmSize[ 1 ], aTmSize[ 2 ], aTmSize[ 3 ], aTmSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects,.T.)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Interface com o usuario                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !(cAliasTRB)->(Eof())
		If lExibeNfOri

			DEFINE MSDIALOG oDlg TITLE OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Documentos de Origem Customizado") FROM aTmSize[7],000 TO aTmSize[6],aTmSize[5] OF oMainWnd PIXEL //"Documentos de Origem"
			@ aPosObj[1,1],aPosObj[1,2] MSPANEL oPanel PROMPT "" SIZE aPosObj[1,3],aPosObj[1,4] OF oDlg CENTERED LOWERED
			If !IsTriangular()
				If cTpCliFor == "C"
					cTexto1 := AllTrim(RetTitle("F2_CLIENTE"))+"/"+AllTrim(RetTitle("F2_LOJA"))+": "+SA1->A1_COD+"/"+SA1->A1_LOJA+"  -  "+RetTitle("A1_NOME")+": "+SA1->A1_NOME
				Else
					cTexto1 := AllTrim(RetTitle("F1_FORNECE"))+"/"+AllTrim(RetTitle("F1_LOJA"))+": "+SA2->A2_COD+"/"+SA2->A2_LOJA+"  -  "+RetTitle("A2_NOME")+": "+SA2->A2_NOME
				EndIf
			Else
				cTexto1 := "Operacao Triangular"
			EndIf

			@ 002,005 SAY cTexto1 SIZE aPosObj[1,3],008 OF oPanel PIXEL
			cTexto2 := AllTrim(RetTitle("B1_COD"))+": "+SB1->B1_COD+"/"+SB1->B1_DESC
			@ 012,005 SAY cTexto2 SIZE aPosObj[1,3],008 OF oPanel PIXEL
			oGetDb := MsGetDB():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],1,"Allwaystrue","allwaystrue","",.F., , ,.F., ,cAliasTRB,,,,,,.T.)

			DEFINE SBUTTON FROM aPosObj[3,1]+000,aPosObj[3,4]-030 TYPE 1 ACTION (nOpcA := 1,oDlg:End()) ENABLE OF oDlg
			DEFINE SBUTTON FROM aPosObj[3,1]+012,aPosObj[3,4]-030 TYPE 2 ACTION (nOpcA := 0,oDlg:End()) ENABLE OF oDlg

			@ aPosObj[3,1]+00,aPosObj[3,2]+00 SAY OemToAnsi("Pesquisar por:") PIXEL
			@ aPosObj[3,1]+12,aPosObj[3,2]+00 SAY OemToAnsi("Localizar") PIXEL
			@ aPosObj[3,1]+00,aPosObj[3,2]+40 MSCOMBOBOX oCombo VAR cCombo ITEMS aOrdem SIZE 100,044 OF oDlg PIXEL ;
				VALID ((cAliasTRB)->(dbSetOrder(oCombo:nAt)),(cAliasTRB)->(dbGotop()),xPesq := aPesq[(cAliasTRB)->(IndexOrd())][1],.T.)
			@ aPosObj[3,1]+12,aPosObj[3,2]+40 MSGET oGet VAR xPesq Of oDlg PICTURE aPesq[(cAliasTRB)->(IndexOrd())][2] PIXEL ;
				VALID ((cAliasTRB)->(DbSeek(Iif(ValType(xPesq)=="C",AllTrim(xPesq),xPesq),.T.)),.T.).And.IIf(oGetDb:oBrowse:Refresh()==Nil,.T.,.T.)

			ACTIVATE MSDIALOG oDlg CENTERED

		Else
			nOpcA	:= 1
		Endif
	Else
		//Help(" ",1,"F4NAONOTA")
		lRetorno := .F.
	EndIf

	If nOpcA == 1
		lRetorno := .T.
		aHeader   := aClone(aSavHead)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica os campos a serem atualizados                              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nPNfOri   := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_NFORI"		})
		nPSerOri  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_SERIORI"	})
		nPItemOri := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEMORI"	})
		nPLocal   := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"		})
		nPPrUnit  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"	})
		nPPrcVen  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"	})
		nPQuant   := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"	})
		nPQuant2UM:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_UNSVEN"	})
		nPLoteCtl := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOTECTL"	})
		nPNumLote := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_NUMLOTE"	})
		nPDtValid := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DTVALID"	})
		nPPotenc  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_POTENCI"	})
		nPValor   := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"		})
		nPValDesc := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"	})
		nPIdentB6 := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_IDENTB6"	})
		nPosLocal := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"		})
		nPClasFis := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CLASFIS"	})
		nQtdLib   := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDLIB"	})
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Posiciona registros                                                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SD1->(MsGoto((cAliasTRB)->SD1RECNO))
		SF4->(dbSetOrder(1))
		SF4->(DbSeek(xFilial("SF4")+aCols[nLinha][nPTES]))
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Preenche acols                                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If nPIdentB6 <> 0
			aCols[nLinha][nPIdentB6] := (cAliasTRB)->B6_IDENT
		EndIf
		If nPNfOri <> 0
			aCols[nLinha][nPNfOri] := SD1->D1_DOC
		EndIf
		If nPSerOri <> 0
			aCols[nLinha][nPSerOri] := SD1->D1_SERIE
		EndIf
		If nPItemOri <> 0
			aCols[nLinha][nPItemOri] := SD1->D1_ITEM
		EndIf
		// Efetua a devolução do CST conforme a nota de origem
		If nPClasFis <> 0 .And. lInFilFCI
			aCols[nLinha][nPClasFis] := Substr(cInClasFis,1,1) + Substr(SD1->D1_CLASFIS,2,2)
		Endif

		If nPPrUnit <> 0
			If (cAliasTRB)->B6_PRUNIT == (cAliasTRB)->B6_PRCVEN .And. Abs((cAliasTRB)->B6_PRCVEN-SD1->D1_VUNIT)<=.01
				aCols[nLinha][nPPrUnit] := 0
			Else
				aCols[nLinha][nPPrUnit] := A410Arred((cAliasTRB)->B6_PRUNIT,"C6_PRUNIT")
			EndIf
		EndIf
		If nPPrcVen <> 0
			If (cAliasTRB)->B6_PRUNIT == (cAliasTRB)->B6_PRCVEN .And. Abs((cAliasTRB)->B6_PRCVEN-SD1->D1_VUNIT)<=.01
				aCols[nLinha][nPPrcVen] := A410Arred(SD1->D1_VUNIT,"C6_PRCVEN")
			Else
				aCols[nLinha][nPPrcVen] := A410Arred((cAliasTRB)->B6_PRCVEN,"C6_PRCVEN")
			EndIf
		EndIf


		If nPQuant <> 0 .And. (aCols[nLinha][nPQuant] > (cAliasTRB)->B6_SALDO .Or. aCols[nLinha][nPQuant] == 0 )
			aCols[nLinha][nPQuant] := Min((cAliasTRB)->B6_SALDO,aCols[nLinha][nPQuant]) //A410SNfOri(cCliFor,cLoja,SD1->D1_DOC,SD1->D1_SERIE,"",SD1->D1_COD,(cAliasTRB)->B6_IDENT,aCols[nLinha][nPosLocal])[1])
			//A410SNfOri(cCliFor,cLoja,cNfOri,cSerOri,cItemOri,cProduto,cIdentB6,cLocal,cAliasSD1,aPedido,l410ProcDv)
			If nPQuant2UM <> 0
				aCols[nLinha][nPQuant2UM] := ConvUm(cProduto,aCols[nLinha][nPQuant],0,2)
			EndIf
		EndIf

		If nPValor <> 0
			aCols[nLinha][nPValor] := a410Arred(aCols[nLinha][nPPrcVen] * aCols[nLinha][nPQuant] ,"C6_VALOR")
		Endif

		If nPLocal <> 0
			aCols[nLinha][nPLocal] := SD1->D1_LOCAL
			// Pesquisa os armazens dos movimentos do controle de qualidade
			If SD1->D1_LOCAL == cLocalCQ
				// Monta array com os armazens tratados na movimentacao do CQ
				cSeekSD7   := xFilial('SD7')+SD1->D1_NUMCQ+SD1->D1_COD+SD1->D1_LOCAL
				SD7->(dbSetOrder(1))
				SD7->(dbSeek(cSeekSD7))
				Do While !SD7->(Eof()) .And. cSeekSD7 == SD7->D7_FILIAL+SD7->D7_NUMERO+SD7->D7_PRODUTO+SD7->D7_LOCAL
					If SD7->D7_TIPO >= 1 .And. SD7->D7_TIPO <= 2 .And. SD7->D7_ESTORNO # 'S'
						If aScan(aArmazensCQ,SD7->D7_LOCDEST) == 0
							AADD(aArmazensCQ,SD7->D7_LOCDEST)
						EndIf
					EndIf
					SD7->(dbSkip())
				EndDo
				// Monta texto para apresentacao no combobox
				If Len(aArmazensCQ) > 1
					nOpca:=0
					For nIX:=1 to Len(aArmazensCQ)
						AADD(aTextoCQ,OemToAnsi("Armazem")+" "+aArmazensCQ[nIX])
					Next nIX
					DEFINE MSDIALOG oDlg TITLE OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Selecao de Armazens") From 130,70 To 270,360 OF oMainWnd PIXEL
					@ 05,13 SAY OemToAnsi("Selecione o armazem para devolucao") OF oDlg PIXEL SIZE 110,9
					@ 17,13 TO 42,122 LABEL "" OF oDlg  PIXEL
					@ 23,17 MSCOMBOBOX oCombo VAR cCombo ITEMS aTextoCQ SIZE 100,044 OF oDlg PIXEL ON CHANGE (cLocalCQ:=aArmazensCQ[oCombo:nAt])
					DEFINE SBUTTON FROM 50,072 TYPE 1 Action (nOpca:=1,oDlg:End()) ENABLE OF oDlg PIXEL
					DEFINE SBUTTON FROM 50,099 TYPE 2 ACTION oDlg:End() ENABLE OF oDlg PIXEL
					ACTIVATE MSDIALOG oDlg
					// Utiliza armazem relacionado ao movimento do CQ
					If nOpca == 1
						aCols[nLinha][nPLocal] := cLocalCQ
					EndIf
				ElseIf Len(aArmazensCQ) > 0
					aCols[nLinha][nPLocal] := aArmazensCQ[1]
				EndIf
			EndIf
		EndIf

		If Rastro(cProduto) .And. SF4->F4_ESTOQUE=="S"
			If nPLoteCtl <> 0
				aCols[nLinha][nPLoteCtl] := SD1->D1_LOTECTL
			EndIf
			If nPNumLote <> 0
				aCols[nLinha][nPNumLote] := SD1->D1_NUMLOTE
			EndIf
			If nPDtValid <> 0 .Or. nPPotenc <> 0
				dbSelectArea("SB8")
				dbSetOrder(3)
				If DbSeek(xFilial("SB8")+cProduto+aCols[nLinha][nPLocal]+aCols[nLinha][nPLoteCtl]+IIf(Rastro(cProduto,"S"),aCols[nLinha][nPNumLote],""))
					If nPDtValid <> 0
						aCols[nLinha][nPDtValid] := SB8->B8_DTVALID
					EndIf
					If nPPotenc <> 0
						aCols[nLinha][nPPotenc] := SB8->B8_POTENCI
					EndIf
				Else
					MsgAlert("não achou "+xFilial("SB8")+"|"+cProduto+"|"+aCols[nLinha][nPLocal]+"|"+aCols[nLinha][nPLoteCtl]+"|"+IIf(Rastro(cProduto,"S"),aCols[nLinha][nPNumLote],"Filial+produto+Local+Lote+SubLote"))
				EndIf
			EndIf
		EndIf

		If nPValDesc <> 0 .And. nPPrUnit > 0
			If aCols[nLinha][nPPrUnit]<>0
				aCols[nLinha][nPValDesc] := a410Arred((aCols[nLinha][nPPrUnit]-aCols[nLinha][nPPrcVen])*IIf(aCols[nLinha][nPQuant]==0,1,aCols[nLinha][nPQuant]),"C6_VALDESC")
				//A410MultT("C6_VALDESC",aCols[nLinha][nPValDesc])
			EndIf
		EndIf

		If nQtdLib <> 0
			aCols[nLinha][nQtdLib] := GDFieldGet("C6_QTDVEN",nLinha,NIL,aHeader,aCols)
		Endif



		If !Empty(cReadVar)

			Do Case
				Case cReadVar $ "M->C6_QTDVEN"
					&(cReadVar) := aCols[nLinha][nPQuant]
				Case cReadVar $ "M->C6_UNSVEN"
					&(cReadVar) := aCols[nLinha][nPQuant2UM]
				Case cReadVar $ "M->D1_QUANT"
					&(cReadVar) := aCols[nLinha][nPQuant]
			EndCase
		EndIf
	Else
		aHeader   := aClone(aSavHead)
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Restaura a integridade da rotina                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea(cAliasTRB)
	//ARQUIVO TEMPORARIO DE MEMORIA (CTREETMP)
	// funcao MSCloseTemp ira substituir a linha de codigo abaixo:
	// dbCloseArea()
	/*dbCloseArea()
	FErase(cNomeTrb + GetDbExtension()) // Deleting file
	FErase(cNomeTrb+ OrdBagExt()) // Deleting index
	*/
	//MSCloseTemp(cAliasTRB,cNomeTrb)
	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf


	RestArea(aArea)
	SetFocus(nHandle)

Return(lRetorno)




/*/{Protheus.doc} sfConfSefaz
(Efetua consulta da NFe via Webservice para garantir que a chave eletrônica esteja autorizada)
@type function
@author marce
@since 09/10/2016
@version 1.0
@param cInChave, character, (Descrição do parâmetro)
@return lRet, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfConfSefaz(cInChave)

	Local	lRet		:= .F.

	Local	cURL     	:= PadR(GetNewPar("XM_SPEDURL",GetNewPar("MV_SPEDURL","http://")),250)
	Local 	cMensagem	:= ""
	Local 	oWS
	Local 	cXmlRet		:= ""

	// Verifico se a empresa em cursor tem TSS configurado
	Private	cIdentSPED	:= U_MLTSSENT()


	If !Empty(cIdentSPED)
		// Trecho para validar autorização da NF
		//lRet	:= TMA050SEF(cInChave,Substr(cInChave,26,9),"")
		oWS := WsSPEDAdm():New()
		oWS:cUSERTOKEN := "TOTVS"
		oWS:oWSEMPRESA:cCNPJ       := IIF(SM0->M0_TPINSC==2 .Or. Empty(SM0->M0_TPINSC),SM0->M0_CGC,"")
		oWS:oWSEMPRESA:cCPF        := IIF(SM0->M0_TPINSC==3,SM0->M0_CGC,"")
		oWS:oWSEMPRESA:cIE         := SM0->M0_INSC
		oWS:oWSEMPRESA:cIM         := SM0->M0_INSCM
		oWS:oWSEMPRESA:cNOME       := SM0->M0_NOMECOM
		oWS:oWSEMPRESA:cFANTASIA   := SM0->M0_NOME
		oWS:oWSEMPRESA:cENDERECO   := FisGetEnd(SM0->M0_ENDENT)[1]
		oWS:oWSEMPRESA:cNUM        := FisGetEnd(SM0->M0_ENDENT)[3]
		oWS:oWSEMPRESA:cCOMPL      := FisGetEnd(SM0->M0_ENDENT)[4]
		oWS:oWSEMPRESA:cUF         := SM0->M0_ESTENT
		oWS:oWSEMPRESA:cCEP        := SM0->M0_CEPENT
		oWS:oWSEMPRESA:cCOD_MUN    := SM0->M0_CODMUN
		oWS:oWSEMPRESA:cCOD_PAIS   := "1058"
		oWS:oWSEMPRESA:cBAIRRO     := SM0->M0_BAIRENT
		oWS:oWSEMPRESA:cMUN        := SM0->M0_CIDENT
		oWS:oWSEMPRESA:cCEP_CP     := Nil
		oWS:oWSEMPRESA:cCP         := Nil
		oWS:oWSEMPRESA:cDDD        := Str(FisGetTel(SM0->M0_TEL)[2],3)
		oWS:oWSEMPRESA:cFONE       := AllTrim(Str(FisGetTel(SM0->M0_TEL)[3],15))
		oWS:oWSEMPRESA:cFAX        := AllTrim(Str(FisGetTel(SM0->M0_FAX)[3],15))
		oWS:oWSEMPRESA:cEMAIL      := UsrRetMail(RetCodUsr())
		oWS:oWSEMPRESA:cNIRE       := SM0->M0_NIRE
		oWS:oWSEMPRESA:dDTRE       := SM0->M0_DTRE
		oWS:oWSEMPRESA:cNIT        := IIF(SM0->M0_TPINSC==1,SM0->M0_CGC,"")
		oWS:oWSEMPRESA:cINDSITESP  := ""
		oWS:oWSEMPRESA:cID_MATRIZ  := ""
		oWS:oWSOUTRASINSCRICOES:oWSInscricao := SPEDADM_ARRAYOFSPED_GENERICSTRUCT():New()
		oWS:_URL := AllTrim(cURL)+"/SPEDADM.apw"

		If oWs:ADMEMPRESAS()
			cIdEnt  := oWs:cADMEMPRESASRESULT
		Else
			Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
		EndIf


		oWs:= WsNFeSBra():New()
		oWs:cUserToken   := "TOTVS"
		oWs:cID_ENT    	 := cIdentSPED
		oWs:_URL         := AllTrim(cURL)+"/NFeSBRA.apw"
		oWs:cCHVNFE		 := cInChave

		If oWs:ConsultaChaveNFE()
			cMensagem := ""
			If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cVERSAO)
				cMensagem += STR0129+": "+oWs:oWSCONSULTACHAVENFERESULT:cVERSAO+CRLF
			EndIf
			cMensagem += STR0035+": "+IIf(oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1,STR0056,STR0057)+CRLF //"Produção"###"Homologação"
			cMensagem += STR0068+": "+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE+CRLF
			cMensagem += STR0069+": "+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE+CRLF
			If oWs:oWSCONSULTACHAVENFERESULT:nAMBIENTE==1 .And. !Empty(oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO)
				cMensagem += STR0050+": "+oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO+CRLF
			EndIf

			If !Empty(oWs:oWSCONSULTACHAVENFERESULT:cDIGVAL)
				cMensagem += "Digest Value: "+oWs:oWSCONSULTACHAVENFERESULT:cDIGVAL+CRLF
			EndIf
			// Obtém o XMl da consulta
			cXmlRet	:= 	oWs:oWSCONSULTACHAVENFERESULT:CXML_RET
			//<dhRecbto>2021-12-09T09:43:21-03:00</dhRecbto>
			oDHRecbto		:= XmlParser(cXmlRet,"","","")
			cDtHrRec		:= IIf(Type("oDHRecbto:_retConsSitNFe:_protNFe:_infProt:_dhRecbto:TEXT")<>"U",oDHRecbto:_retConsSitNFe:_protNFe:_infProt:_dhRecbto:TEXT,"")
			nDtHrRec1		:= RAT("T",cDtHrRec)




			// Nota fiscal Autorizada
			If Alltrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "100"
				lRet	:=	.T.
				// Nota fiscal Cancelada - Cancelamento autorizado
			ElseIf Alltrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "101"
				lRet	:=	.F.
				cMensagem	+= CRLF
				cMensagem	+= "Número da Nota " + Substr(cInChave,26,9)
				Aviso(STR0107,cMensagem,{STR0114},3)
				lIsRejSef	:= .T.
			ElseIf Alltrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "526"
				lRet	:=	.T.
				Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+STR0107,cMensagem+Chr(13)+Chr(10)+"Nota fiscal do Fornecedor/Cliente",{"Ok"},3)
			Else
				Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+STR0107,cMensagem+Chr(13)+Chr(10)+"Nota fiscal do Fornecedor/Cliente",{"Ok"},3)
			Endif

			If nDtHrRec1 <> 0 .And. !lIsRejSef
				cDtHrRec1   :=	SubStr(cDtHrRec,nDtHrRec1+1)
				dDtRecib	:=	SToD(StrTran(SubStr(cDtHrRec,1,AT("T",cDtHrRec)-1),"-",""))

				If (Date() - dDtRecib ) == 1
					If (SubHoras(Time(),cDtHrRec1) + 24 ) < 24
						If !MsgYesNo("Nota emitida há menos de 24hs. " + DTOC(dDtRecib) + " " +  Substr(cDtHrRec,12)  + " Deseja efetuar o retorno mesmo assim? ")
							lRet	:= .F.
						Endif
					Endif
				ElseIf  ( Date() - dDtRecib ) == 0
					If !MsgYesNo("Nota emitida há menos de 24hs. " + DTOC(dDtRecib) + " " +  Substr(cDtHrRec,12)  + " Deseja efetuar o retorno mesmo assim? ")
						lRet	:= .F.
					Endif
				Endif
			EndIf

			//	Aviso(STR0107,cMensagem,{STR0114},3)
		Else
			Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{STR0114},3)
			lRet	:= U_MLCNFSEF(cInChave,.T./*lExterna*/)
		EndIf
	Else
		Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{STR0114},3)
	Endif

Return lRet
