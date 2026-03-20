

/*/{Protheus.doc} FA050FIN
(Preencher historico de titulos de impostos  )
	
@author MarceloLauschner
@since 11/03/2013  
@version 1.0		

@return Sem retorno esperado

@example
(examples)

@see (http://tdn.totvs.com/display/public/mp/FA050FIN+-+Tratamento+dos+dados+no+Contas+a+Pagar+--+11854)
/*/
User Function FA050FIN()//RFINR13(cAlias,_nReg)

	Local	nRegOrig		:= SE2->(Recno())
	Local	cTitPai		:= SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA
	Local	cNomPai		:= Alltrim(SE2->E2_NOMFOR)
	Local	aAreaSE2		:= SE2->(GetArea())
	
	
	//rede log nao executa
	If Alltrim(SM0->M0_CODIGO) == '06'
		Return 
	Endif
	


	If SE2->E2_IRRF > 0 .Or. SE2->E2_INSS > 0
		DbSelectArea("SE2")
		DbSetOrder(1)
		DbSeek(xFilial("SE2")+Substr(cTitPai,1,Len(SE2->E2_PREFIXO)+Len(SE2->E2_NUM)))
		While !Eof() .And. SE2->E2_PREFIXO+SE2->E2_NUM == Substr(cTitPai,1,Len(SE2->E2_PREFIXO)+Len(SE2->E2_NUM))
			If Alltrim(SE2->E2_TITPAI) == Alltrim(cTitPai)
				RecLock("SE2",.F.)
				SE2->E2_HIST	:= Iif(SE2->E2_TIPO == "INS","INSS ",Iif(SE2->E2_TIPO == "TX ".And. Alltrim(SE2->E2_NATUREZ) == "IRF","IRRF ","")) +cNomPai+"-"+Alltrim(cTitPai)
				MsUnlock()
			Endif
			SE2->(DbSkip())
		Enddo
		DbSelectArea("SE2")
		DbGoto(nRegOrig)
 	
	Endif

	RestArea(aAreaSE2)

Return
