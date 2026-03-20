

/*/{Protheus.doc} M410STTS
(Ao gravar o pedido de venda, atualiza vinculo com a PA2)

@author MarceloLauschner
@since 02/12/2013
@version 1.0

@return Sem retorno esperado

@example
(examples)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784166)
/*/
User Function M410STTS()

	Local		aAreaOld	:= GetArea()
	Local		iW
	Local		nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_XPA2NUM"})
	Local		nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_XPA2LIN"})
	Local		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local		nPxCFO		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_CF"})
	Local 		_nOper 		:= PARAMIXB[1]


	If FWCodEmp() == '10' .AND. _nOper == 5
		U_PPEDCANC(M->C5_NUM)
	EndIf

	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M410STTS")
		Return .T.
	Endif

	If INCLUI .Or. ALTERA .Or. Alltrim(Upper(ProcName(2))) == "A410DELETA"

		For iW := 1 To Len(aCols)
			If Alltrim(aCols[iW,nPxProd]) $ GetNewPar("BF_PRODPCP","43170.000159#02153.000159")
				// Evita erro de não existir os campos ainda na base de produção
				If nPxPA2NUM > 0
					DbSelectArea("PA2")
					DbSetOrder(3)
					If DbSeek(xFilial("PA2")+aCols[iW,nPxPA2NUM]+aCols[iW,nPxPA2LIN])
						// Se a linha estiver deletada
						If aCols[iW,Len(aHeader)+1] .Or. Alltrim(Upper(ProcName(2))) == "A410DELETA"
							RecLock("PA2",.F.)
							PA2->PA2_RESERV	:= " "
							PA2->PA2_PEDIDO	:= " "
							PA2->PA2_NUMNF 	:= " "
							PA2->PA2_SERIE	:= " "
							PA2->PA2_CGCREM := " "
							MsUnlock()
						Else
							RecLock("PA2",.F.)
							PA2->PA2_PEDIDO	:= M->C5_NUM
							MsUnlock()
						Endif
					Endif
				Endif
			Endif
		Next

	Endif

	// Efetua chamada do envio do Link de aprovação do pedido caso seja inclusão ou alteração
	If (INCLUI .Or. ALTERA) //.And. !IsBlind()
		U_BFFATA30(.T./*lAuto*/,M->C5_NUM/*cInPed*/,1/*nInPedOrc*/)
	Endif



	RestArea(aAreaOld)

Return
