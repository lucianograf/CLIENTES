
/*/{Protheus.doc} BFFINM06
(Usado para campo virtual E2_XRATSZR que exibe a chave SZR )
@author MarceloLauschner
@since 26/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFINM06()
	
	Local	cTexRet		:= ""
	Local	aAreaOld	:= GetArea()
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	DbSelectArea("SZR")
	DbSetOrder(2)   // ZR_FILIAL+ZR_KEYSE2
	If DbSeek(xFilial("SZR")+SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA)
		cTexRet	:= SZR->ZR_KEYSE2
	Endif
	
	RestArea(aAreaOld)
	
Return cTexRet
