

/*/{Protheus.doc} FA050ALT
(Ponto de entrada para validar alteração de titulso SE2 )
@author MarceloLauschner
@since 30/07/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FA050ALT()
	
	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	
	
	//rede log nao executa
	If Alltrim(SM0->M0_CODIGO) == '06'
		Return .T.
	Endif
	
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	DbSelectArea("SA2")
	DbSetOrder(1)
	If SA2->(FieldPos("A2_XOBRGRT")) > 0 .And. !(Alltrim(SE2->E2_FATURA) $ "NOTFAT")
		DbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
		If SA2->A2_XOBRGRT ==  "S"
			DbSelectArea("SZR")
			DbSetOrder(2)   // ZR_FILIAL+ZR_KEYSE2
			If !DbSeek(xFilial("SZR")+SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA)
				MsgAlert("O título de Prefixo+Número+Parcela+Tipo+Fornecedor+Loja '"+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA+"' não será alterado pois este fornecedor está configurado para forçar o cadastro de desmembramentos por títulos, e não há cadastro de rateios para este título! Volte até a rotina 'Contas a Pagar/Desm.Rateio' e efetue o cadastro do desmembramento!","Desmembramento obrigatório não encontrado!")
				lRet	:= .F.
			Endif
		Endif
	Endif
	RestArea(aAreaOld)
	
Return lRet
