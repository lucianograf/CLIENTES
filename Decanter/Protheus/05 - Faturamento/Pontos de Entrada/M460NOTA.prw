#Include 'Protheus.ch'
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPonto Entrada ³POL06A30  ºAutor  ³ACTVS           º Data ³  09/27/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Ponto de entrada 'M460NOTA', executado ao final do processamento de   º±±
±±º todas as notas fiscais selecionadas na markbrowse                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function M460NOTA()

//TSCB57 - William Farias - 28/08/2019:
//Desativado, pois foi implementado impressao automatica de boleto na impressao de danfe.
//	Local aBoletos	:= {}
//	Local aDBF2		:= {}
//	Local aSE1		:= {}
//	Local nI 		:= 0
//	Local nX 		:= 0
//	Local cCodCli	:= ""
//	Local cLojCli	:= ""
//	Local cAliasSEE1 := GetNextAlias()
//
//	Public _aS_F_2_
//
//	Begin Sequence
//
//		If ValType(_aS_F_2_) == "U"
//			_aS_F_2_ := {}
//		EndIf
//	
//		DbSelectArea("SE1")
//		aDBF2 := dbStruct()
//	
//		For nX := 1 To Len(_aS_F_2_)
//	
//			DbSelectArea("SE1")
//			DbSetOrder(1)
//	
//			If DbSeek(xFilial("SE1")+_aS_F_2_[nX][1]+_aS_F_2_[nX][2])
//				While !EoF() .And. SE1->E1_NUM == _aS_F_2_[nX][2] .And. SE1->E1_PREFIXO == _aS_F_2_[nX][1];
//				 .And. SE1->E1_FILIAL == xFilial("SE1")
//	
//					If Substr(SE1->E1_TIPO,3,1) != '-'
//					 	aSE1 := {}
//						For nI := 1 To Len(aDBF2)
//				 			AADD(aSe1, {aDBF2[nI][1], &("SE1->"+(aDBF2[nI][1]))})
//						Next
//						AADD(aBoletos, aSE1)	
//
//						nPosCodCli	:= Ascan( aSE1,{ |X| UPPER( AllTrim(X[1]) )=="E1_CLIENTE" } )
//						nPosLojCli	:= Ascan( aSE1,{ |X| UPPER( AllTrim(X[1]) )=="E1_LOJA" } )		
//						If nPosCodCli <> 0 .And. nPosLojCli <> 0
//							cCodCli	:= aSE1[nPosCodCli][2]
//							cLojCli	:= aSE1[nPosLojCli][2]
//						EndIf
//
//					Endif
//					DbSelectArea("SE1")
//					DbSkip()
//				EndDo
//			EndIf
//			
//			If Len(aBoletos) == 1
//				dbSelectArea("SA1")
//				dbSetOrder(1)
//				dbSeek(FWxFilial("SA1")+cCodCli+cLojCli)
//				If	Alltrim(SA1->A1_ZBOLETO) <> "S"
//					Loop
//				EndIf
//				
//				If !Empty(SA1->A1_BCO1) .And. !Empty(SA1->A1_ZAGE1) .And. !Empty(SA1->A1_ZCTA1) .And. !Empty(SA1->A1_ZSUBCT1)
//					SEE->(DbSetOrder(1))
//					SEE->(DbSeek(xFilial("SEE")+SA1->A1_BCO1+SA1->A1_ZAGE1+SA1->A1_ZCTA1+SA1->A1_ZSUBCT1))
//					Mv_par01 := SEE->EE_CODIGO
//					Mv_par02 := SEE->EE_AGENCIA
//					Mv_par03 := SEE->EE_CONTA
//					Mv_par04 := SEE->EE_SUBCTA
//					Mv_par23 := 1
//				Else
//					BeginSql alias cAliasSEE1
//						SELECT EE_CODIGO, EE_AGENCIA, EE_CONTA, EE_SUBCTA
//						FROM %table:SEE% SEE
//						WHERE SEE.D_E_L_E_T_ <> '*'
//						AND SEE.EE_FILIAL	= %exp:FWxFilial("SEE")%
//						AND SEE.EE_ZBCODIA	= "S"
//					EndSql
//			
//					dbSelectArea(cAliasSEE1)
//					dbGoTop()
//					If (cAliasSEE1)->(Eof())
//						cMsgError := "Não foi encontrado nenhum banco do dia cadastrado. Favor verificar."
//						MsgStop(cMsgError,"Atenção - "+ProcName()+"/"+cValToChar(ProcLine()))
//						Loop
//					EndIf
//					Mv_par01 := (cAliasSEE1)->EE_CODIGO
//					Mv_par02 := (cAliasSEE1)->EE_AGENCIA
//					Mv_par03 := (cAliasSEE1)->EE_CONTA
//					Mv_par04 := (cAliasSEE1)->EE_SUBCTA
//					Mv_par23 := 1
//				EndIf
//	
//				U_BOLETOACTVS(aBoletos)
//				
//			EndIf
//		
//			aBoletos	:= {}
//			
//		Next
//	
//		_aS_F_2_ := {}
//	
//	End Sequence
Return