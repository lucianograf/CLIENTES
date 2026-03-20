
/*/{Protheus.doc} UZPEMsgNF
Ponto de Entrada para COMPLEMENTAR dados nas mensagens adicionais da NF.
PE aFill
Cliente - Decanter 2024
@type function
@version 1.0
@author manowz
@since 1/17/2024
@param cProc, character, Codigo do Processo
@return variant, Retorna Array com os Dados.
/*/
User Function UZPEMsgNF(cProc)

	Local cICMSDIF	:= ""
	Local nTICMSDIF := 0
	Local nTotFRETE := 0
	Local nTotAFRMM := 0
	Local lICMSDIF  := .F.
	Local aRet		:= {}

	SD1->(dbSetOrder(1))
	If SD1->(dbSeek(xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)))
		While !SD1->(EOF()) .AND. (SD1->(D1_FILIAL + D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA) == (xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)))

			If SD1->D1_ICMSDIF > 0
				lICMSDIF  := .T.
				nTICMSDIF += SD1->D1_ICMSDIF
			Endif

			nTotFRETE 	+= SD1->D1_XFRET
			nTotAFRMM 	+= SD1->D1_XDICM

			SD1->(DBSkip())
		EndDo
	EndIf

	If lICMSDIF
		cICMSDIF := "| ICMS DIFERIDO. ART. 10 DO ANEXO 3 DO RICMS/SC-01.INICIO PRAZO DE"
		cICMSDIF += " VIGENCIA:01/2013, FINAL DO PRAZO: INDETERMINADO. "
	Endif

	aADD(aRet,cICMSDIF)

	aADD(aRet,'| Valor ICMS Diferido....: '+ Alltrim(TransForm(nTICMSDIF,"@E 999,999,999.99")))
	aADD(aRet,'| Valor Frete.......: '+ Alltrim(TransForm(nTotFRETE,"@E 999,999,999.99")))
	aADD(aRet,'| Valor AFRMM.......: '+ Alltrim(TransForm(nTotAFRMM,"@E 999,999,999.99")))

Return aRet
