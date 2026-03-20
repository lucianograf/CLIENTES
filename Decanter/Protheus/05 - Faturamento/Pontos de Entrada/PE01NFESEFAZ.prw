#include 'TOTVS.ch'
#include 'Protheus.ch'
Static lC5_ZOBSENT := SC5->(FieldPos("C5_ZOBSENT"))>0
Static lC5_ZMENNOT := SC5->(FieldPos("C5_ZMENNOT"))>0

/*/{Protheus.doc} PE01NFESEFAZ


Utilizar esse PE para tratar customizacoes na danfe,
evitar de alterar o NFESEFAZ E DANFEII,
facilitando uma possivel atualizacao dos fontes,
nao sendo necessario sincronizar customizacao.


PE01NFESEFAZ - Manipulao em dados do produto

aRetorno(array_of_record)
//O retorno deve ser exatamente nesta ordem e passando o contedo completo dos arrays//pois no rdmake nfesefaz  atribuido o retorno completo para as respectivas variveis//Ordem:// aRetorno[1] -> aProd// aRetorno[2] -> cMensCli// aRetorno[3] -> cMensFis// aRetorno[4] -> aDest// aRetorno[5] -> aNota

@author TSC679 - CHARLES REITZ
@since 1/01/2015
/*/
//TSCB57 - William Farias: Efetuado conciliação de fontes após virada para versão 12.1.23
//User Function PE01NFESEFAZ()
//
//Local aParam := PARAMIXB //{aProd,cMensCli,cMensFis,aDest,aNota,aInfoItem,aDupl,aTransp,aEntrega,aRetirada,aVeiculo,aReboque,aNfVincRur,aEspVol,aNfVinc,AdetPag,aObsCont}
//Local aObsCont := aParam[17] //aObsCont
//
//aAdd(aObsCont,{ "TF_NUM_PNF_REF",; //xCampo
//SF2->F2_DOC}) //xTexto
//
//aAdd(aObsCont,{ "TF_SER_PNF_REF",; //xCampo
//SF2->F2_SERIE}) //xTexto
//
//aAdd(aObsCont,{ "TF_RASTREIO",; //xCampo
//"*"}) //xTexto
//
//aParam[17] := aObsCont
//
//Return aParam
//TSCB57 - FIM

User Function PE01NFESEFAZ()
	Local nDoc 	 	:= SF2->F2_DOC
	Local nSerie	:= SF2->F2_SERIE
	Local cCliente	:= SF2->F2_CLIENTE
	Local cLoja		:= SF2->F2_LOJA
	Local nItem		:= {}
	Local aRetorno  := {}
	Local aArea		:= GetArea()
	Local aAreaSF2	:= SF2->(GetArea())
	Local aAreaSA1	:= SA1->(GetArea())
	Local cPedAux	:= ""
	Local i			:= 0
	Local cMsgAux	:= ""
	Local _Apv		:= 0
	Local _aProd	:= aclone(PARAMIXB[1]) //Produto
	Local cItmTmp	:= ""
	Local cItmAux	:= ""
	Local	aNota 		:= aParam[5]                
	Local aProd     := PARAMIXB[1]
	
//TSCB57 - William Farias em 04/12/2019 - INICIO
//Comentado regra conforme solicitação do Mário.
//	aAdd(PARAMIXB[17],{ "TF_NUM_PNF_REF",; //xCampo
//	SF2->F2_DOC}) //xTexto
//	
//	aAdd(PARAMIXB[17],{ "TF_SER_PNF_REF",; //xCampo
//	SF2->F2_SERIE}) //xTexto
//	
//	aAdd(PARAMIXB[17],{ "TF_RASTREIO",; //xCampo
//	"*"}) //xTexto
//TSCB57 - FIM

	//NOTA FISCAL DE SAIDA (SF2)
	//Tratamento para nota de saida, aNota[4] = 1
	//caso for aNota[4] = 0 e entrada
	If LEN(PARAMIXB[5])>0 .AND. PARAMIXB[5][4] == "1"

		For i := 1 to len(PARAMIXB[6])
			dbSelectArea("SC5")
			SC5->(dbSetOrder(1))
			If SC5->(MsSeek(xFilial("SC5")+PARAMIXB[6][i][1]))
			 	If !(ALLTRIM(SC5->C5_NUM) $ cPedAux)
			 		cPedAux  +=  Iif(Empty(cPedAux),"","/") + Alltrim(SC5->C5_NUM)

					//TSC679 CHARLES REITZ - 14/01/2020 - Criado campo separado para informações adicionadis do pedido do cliente	
					iF lC5_ZMENNOT
						PARAMIXB[2]	+= Alltrim(SC5->C5_ZMENNOT)
					eNDiF

			 		If lC5_ZOBSENT .AND. !Empty(SC5->C5_ZOBSENT)
			 			cPedAux	+=	" - Endereço de Entrega:"+Alltrim(C5_ZOBSENT)
			 		EndIf
			 	EndIf
			EndIf
		Next
		
		dbSelectArea("SC5")
		SC5->(dbSetOrder(1))
		If SC5->(MsSeek(xFilial("SC5")+alltrim(PARAMIXB[6][1][1])))
			For _Apv:=1 To Len(_aProd)
				SC6->(dbSetOrder(1))
				If SC6->(MsSeek( xFilial("SC6")+_aProd[_Apv][38]+_aProd[_Apv][39]+_aProd[_Apv][2])) 
					If !Empty(SC6->C6_NUMPCOM)
						cItmTmp += ALLTRIM(SC6->C6_NUMPCOM)
					EndIF
					If !Empty(SC6->C6_ITEMPC)
						cItmTmp += "/"+ALLTRIM(SC6->C6_ITEMPC)
					EndIF
					If _Apv < Len(_aProd) .And. !Empty(SC6->C6_NUMPCOM)
						cItmTmp += " - "'
					EndIf
				EndIF
			Next
			// Grava Log
			U_DCCFGM02("TS",SC5->C5_NUM,"",FunName())

		EndIf
		
		If !Empty(cPedAux)
			cMsgAux	:= CRLF+"Numero do Pedido: " + cPedAux
			If !Empty(cItmTmp)
				cItmAux += CRLF+"Ped. Cliente: " + cItmTmp
				cMsgAux += cItmAux
			EndIf
			PARAMIXB[2] += cMsgAux
		ElseIf !Empty(cItmTmp)
			cItmAux += CRLF+"Ped. Cliente: " + cItmTmp
			PARAMIXB[2] += cItmAux
		EndIf

	Else

	EndIf

	RestArea(aAreaSA1)
	RestArea(aAreaSF2)
	RestArea(aArea)
Return PARAMIXB
