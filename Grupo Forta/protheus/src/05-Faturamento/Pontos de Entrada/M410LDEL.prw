#Include 'Protheus.ch'


/*/{Protheus.doc} M410LDEL
(Ponto de entrada para validar a exclusão ou restauração da linha do getdados do pedido de vendas)
@type function
@author marce
@since 19/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M410LDEL()

	Local	aAreaOld		:= GetArea()
	Local	lRet			:= .T.
	Local	nPProd  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local	nPQtd	  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local	nPRegBnf		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	Local	nPCodTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
	Local	nPPrcTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	Local	nPVrUnit		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	Local	nPValDesc		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
	Local	nPDesc			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
	Local	nW ,nL
	
	Local	nPosAnt			:= n
	Local	nPosDel			:= Len(aHeader)+1
	Local	iQ
	Local	nDesconto		:= 0
	Local	nXPrcTab		:= 0
	Local	aFxVolumes		:= {}
	Local	aPrTabs			:= {}
	
	// Se o tipo de pedido não for N-Normal não efetua validações. 
	If M->C5_TIPO # "N"
		RestArea(aAreaOld)
		Return lRet
	Endif
	
	// Verifica se a linha é um derivado de Combo
	If !Empty(aCols[n][nPRegBnf]) 
		cRegBoni	:= Substr(aCols[n][nPRegBnf],1,6)
		If !aCols[n][Len(aHeader)+1]
			aCols[n][nPRegBnf]	:= "XXXXXX"
			MsgAlert("Você deletou um item derivado de Combo. Todos os demais produtos do Combo serão deletados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			For iQ := 1 To Len(aCols)
				If iQ <> nPosAnt .And. Substr(aCols[iQ][nPRegBnf],1,6) == cRegBoni
					n	:= iQ
					aCols[n][nPRegBnf]		:= "XXXXXX"
					//lRet	:= .F.
					aCols[n][nPosDel] 		:= .T.
					aCols[iQ][nPosDel]		:= .T.									
				Endif
			Next iQ
		Else 
			MsgAlert("Não permitido recuperar item derivado de Combo que foi deletado!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			lRet	:= .F. 						
		Endif
		n := nPosAnt
		If Type('oGetDad:oBrowse')<>"U"
			oGetDad:oBrowse:Refresh()
			Ma410Rodap()
		Endif
	Endif			
	
Return lRet

