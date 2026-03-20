#Include 'Protheus.ch'

/*/{Protheus.doc} )
(Ponto de entrada na eliminação de residuos por item)
@author MarceloLauschner
@since 21/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MT500ANT()
	Local	lRet		:= .T.
	Local	aAreaOld	:= GetArea()
	
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MT500ANT")
		Return .T.
	Endif
	
	
	If SC6->C6_PRODUTO $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")	
		
		// Excluo o vinculo da PA2
		DbSelectArea("PA2")
		DbSetOrder(3)
		If DbSeek(xFilial("PA2")+SC6->C6_XPA2NUM+SC6->C6_XPA2LIN)
		
			DbSelectArea("PA2")
			RecLock("PA2",.F.)
			PA2->PA2_RESERV	:= " "
			PA2->PA2_PEDIDO	:= " "
			PA2->PA2_NUMNF 	:= " "
			PA2->PA2_SERIE	:= " "
			PA2->PA2_CGCREM := " "
			MsUnlock()
		Endif
	Endif
	
	
	// Excluo o vinculo da SC6
	DbSelectArea("SC6")
	RecLock("SC6",.F.)
	SC6->C6_XPA2NUM	:= ""
	SC6->C6_XPA2LIN	:= ""
	MsUnlock()
	
	RestArea(aAreaOld)
	
Return lRet

