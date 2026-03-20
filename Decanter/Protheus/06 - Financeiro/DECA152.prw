#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} DECA152

Chama impressao de boleto automatica.

@author TSCB57 - William Farias
@since 28/08/2019
@version 1.0
@return return, return_description
/*/
User Function DECA152(aNota)
	
	Local aArea		:= GetArea()
	Local cPedido	:= ''
	Local lParcial	:= .F.
	Local lTotal	:= .F.
	Local _cNumero  := ""
	Local _cCodCli  := ""
	Local _cLojCli  := ""
	Local _ValorNf  := 0
	Local _cSerie	:= ""
	Local aBoletos	:= {}
	Local aDBF2		:= {}
	Local aSE1		:= {}
	Local nI 		:= 0
	Local nX 		:= 0
	Local cAliasSEE1 := GetNextAlias()
	Local aMvPar := {}
	Local lReimp
	Local lImpBoleto := .F.

	//Salva os parametros
	For nX := 1 To 40
		aAdd( aMvPar, &( "MV_PAR" + StrZero( nX, 2, 0 ) ) )
	Next nX
	
	Public _aS_F_2_	
	If ValType(_aS_F_2_) == "U"
		_aS_F_2_ := {}
	EndIf	
	
	Begin Sequence
		
		dbSelectArea("SF2")
		dbSetOrder(1)
		If !dbSeek(xFilial("SF2")+aNota[5]+aNota[4]+aNota[6]+aNota[7])
			Break
		EndIf
		// Solicitação para que não seja gerado boleto para notas em que o vendedor é o 000138-Ecommerce 
		// 23/08/2022 - Solicitado por Luciano 
		If SF2->F2_VEND1 $ GetNewPar("DC_NOBLVEND","000138#") 
			Break 
		Endif 

		_cNumero  := SF2->F2_DOC
		_cCodCli  := SF2->F2_CLIENTE
		_cLojCli  := SF2->F2_LOJA
		_ValorNf  := SF2->F2_VALFAT
		_cSerie := If(Empty(SF2->F2_PREFIXO),&(GETMV("MV_1DUPREF")),SF2->F2_PREFIXO)
		
		DbSelectArea("SE1")
		DbSetOrder(1)
		If DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DUPL)
			_cSerie += Space(Len(SE1->E1_PREFIXO) - Len(_cSerie))
		EndIf

		// TSC679 - CHARLES REITZ - COMENTADO POIS FOI RESOLVIDO A QUESTAO DA REEIMPRESSÃO 
		//dbSelectArea("SA1")
		//dbSetOrder(1)
		//dbSeek(FWxFilial("SA1")+_cCodCli+_cLojCli)
		//If	(Alltrim(SA1->A1_ZBOLETO) <> "S" .or. SE1->E1_NUMBOR <> " ") //TSC852 - Willian D. - 03/01/2020: Nao imprimir caso tenha Numero de Borderô
		//	Break
		//EndIf
		
		//-------------------------------------------------------------------------------------------------------------
		//±±º Ponto de entrada executado apos a geracao da nota fiscal, obtendo     º±±
		//±±º a lista de titulos a receber para geracao dos boletos.                º±±
		//-------------------------------------------------------------------------------------------------------------
		AADD(_aS_F_2_,{SF2->F2_PREFIXO,SF2->F2_DUPL})
		//-------------------------------------------------------------------------------------------------------------
	
		DbSelectarea("SD2")// SD2 = itens de venda da NF
		DbSetOrder(3) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		DbSeek(xfilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)		//Busca os itens da NF posicionada
		
		// TSC679 CHARLES REITZ - 16/01/2020 - DESCONSIDERA QUANDO O PEDIDO VIER DA INTEGRAÇÃO DO MAGENTO
		DbSelectArea("SC5") //sc6 = itens dos pedidos de venda
		DbSetOrder(1)
		dbSeek(xFilial("SC5")+SD2->D2_PEDIDO)
		iF !Empty(SC5->C5_ZNUMMGT)
			Break
		EndIf

		//Me assegurando que está de acordo com o que foi posicionado
		While SD2->D2_DOC == SF2->F2_DOC .And. SD2->D2_SERIE == SF2->F2_SERIE .And. ;
				SD2->D2_CLIENTE == SF2->F2_CLIENTE .And. ;
				SD2->D2_LOJA 	  == SF2->F2_LOJA .And. SD2->(!Eof()) .And. ;
				SD2->D2_FILIAL  == xFilial("SD2")
			
			cPedido := SD2->D2_PEDIDO

			DbSelectArea("SC6") //sc6 = itens dos pedidos de venda
			DbSetOrder(1)
			 //Busca na SC6 o registro equivalente da SD2
			If dbSeek(xFilial("SC6")+SD2->D2_PEDIDO+SD2->D2_ITEMPV+SD2->D2_COD)
			
				If SC6->C6_QTDVEN <> SC6->C6_QTDENT .AND. SC6->C6_QTDENT >0
					lParcial := .T.
					lTotal   := .F.
				ElseIf SC6->C6_QTDVEN = SC6->C6_QTDENT
					lTotal	  := .T.
					lParcial := .T.
				Else
					lTotal := .F.
				EndIf
	
			EndIf
			SD2->(DbSkip())
		EndDo
		//FIM SF2460I
		
		//INICIO M460NOTA
		If ValType(_aS_F_2_) == "U"
			_aS_F_2_ := {}
		EndIf
	
		// Em teoria sempre vai ter apenas 1 registro no for nao vai ter varios
		DbSelectArea("SE1")
		aDBF2 := dbStruct()
		lReimp	:= .F.

		For nX := 1 To Len(_aS_F_2_)
	
			DbSelectArea("SE1")
			DbSetOrder(1)
	
			If SE1->(DbSeek(xFilial("SE1")+_aS_F_2_[nX][1]+_aS_F_2_[nX][2]))
				While SE1->(!EoF()) .And. SE1->E1_NUM == _aS_F_2_[nX][2] .And. SE1->E1_PREFIXO == _aS_F_2_[nX][1];
				 .And. SE1->E1_FILIAL == xFilial("SE1")

					//TSC679 CHARLES REITZ - 16/01/2020 CASO FOR REIMPRESSAO NAO GERA BORDERO NOVAMENTE
					If !Empty(SE1->E1_NUMBOR )
						lReimp	:= .T.

						// DbSelectArea("SEA")
						// DbSetOrder(1)
						// dbSeek(FWxFilial("SEA")+SE1->(E1_NUMBOR+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
						// Mv_par01 := SE1->E1_PORTADO
						// Mv_par02 := SE1->E1_AGEDEP
						// Mv_par03 := SE1->E1_CONTA
						// Mv_par04 := SEA->EA_SUBCTA
						
					ENDIF
					

					_cCodCli  := SE1->E1_CLIENTE
					_cLojCli  := SE1->E1_LOJA
					
					If !Empty(SE1->E1_PEDIDO)
						dbSelectArea("SC5")
						dbSetOrder(1)
						If dbSeek(FWxFilial("SC5")+SE1->E1_PEDIDO)
							If SC5->C5_ZBOLETO == 'S'
								lImpBoleto := .T.
							EndIf
						EndIf
					EndIf
					
					If Substr(SE1->E1_TIPO,3,1) != '-'
					 	aSE1 := {}
						For nI := 1 To Len(aDBF2)
				 			AADD(aSe1, {aDBF2[nI][1], &("SE1->"+(aDBF2[nI][1]))})
						Next
						AADD(aBoletos, aSE1)

					Endif
					SE1->(DbSkip())
				EndDo
			EndIf
			
			If lReimp  .AND. !FWIsInCallStack("U_PrtNfU") .and. !MSGYESNO( "Boleto da nota fiscal já foi impresso, deseja imprimir novamente?", "Atenção-"+ProcName() )
				Loop
			ENDIF
			If Len(aBoletos) >= 1
				// CASO FOR REIMPRESSÃO, CONSIDERA O QUE ESTIVER NO TITULO
				If !lReimp 
				
					dbSelectArea("SA1")
					dbSetOrder(1)
					dbSeek(FWxFilial("SA1")+_cCodCli+_cLojCli)
//					If	Alltrim(SA1->A1_ZBOLETO) <> "S"
//						Loop
//					EndIf

					If !lImpBoleto
						Loop
					EndIf
					
					If !Empty(SA1->A1_BCO1) .And. !Empty(SA1->A1_ZAGE1) .And. !Empty(SA1->A1_ZCTA1) .And. !Empty(SA1->A1_ZSUBCT1)
						SEE->(DbSetOrder(1))
						SEE->(DbSeek(xFilial("SEE")+SA1->A1_BCO1+SA1->A1_ZAGE1+SA1->A1_ZCTA1+SA1->A1_ZSUBCT1))
						Mv_par01 := SEE->EE_CODIGO
						Mv_par02 := SEE->EE_AGENCIA
						Mv_par03 := SEE->EE_CONTA
						Mv_par04 := SEE->EE_SUBCTA
						//Mv_par23 := 2
					Else
						BeginSql alias cAliasSEE1
							SELECT EE_CODIGO, EE_AGENCIA, EE_CONTA, EE_SUBCTA
							FROM %table:SEE% SEE
							WHERE SEE.D_E_L_E_T_ <> '*'
							AND SEE.EE_FILIAL	= %exp:FWxFilial("SEE")%
							AND SEE.EE_ZBCODIA	= "S"
						EndSql
				
						dbSelectArea(cAliasSEE1)
						dbGoTop()
						If (cAliasSEE1)->(Eof())
							cMsgError := "Não foi encontrado nenhum banco do dia cadastrado. Favor verificar."
							MsgInfo(cMsgError,"Atenção - "+ProcName()+"/"+cValToChar(ProcLine()))
							Loop
						EndIf
						Mv_par01 := (cAliasSEE1)->EE_CODIGO
						Mv_par02 := (cAliasSEE1)->EE_AGENCIA
						Mv_par03 := (cAliasSEE1)->EE_CONTA
						Mv_par04 := (cAliasSEE1)->EE_SUBCTA
						//Mv_par23 := 2
						dbCloseArea()
					EndIf
				EndIf
				Mv_par23 := 2
				U_BOLETOACTVS(aBoletos,lReimp)
			EndIf
			
			aBoletos	:= {}
			
		Next
	
	End Sequence

	_aS_F_2_ := {}
	//FIM M460NOTA
	
	//Restaura os parametros
	For nX := 1 To Len( aMvPar )
		&( "MV_PAR" + StrZero( nX, 2, 0 ) ) := aMvPar[ nX ]
	Next nX
	
	RestArea(aArea)

Return

/*/{Protheus.doc} DECA152B

Envia dados da nota selecionada para imprimir os boletos.

@author TSCB57 - william.farias
@since 28/01/2020
@version 1.0
@example
(examples)
@see (links_or_references)
/*/
User Function DECA152B
	
	Local aNota := {}
	
	aAdd(aNota,"")
	aAdd(aNota,"")
	aAdd(aNota,"")
	aAdd(aNota,SF2->F2_SERIE)
	aAdd(aNota,SF2->F2_DOC)
	aAdd(aNota,SF2->F2_CLIENTE)
	aAdd(aNota,SF2->F2_LOJA)
	
	U_DECA152(aNota)

Return .T.
