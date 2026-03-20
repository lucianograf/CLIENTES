
/*/{Protheus.doc} M450ABRW
(Filtro de clientes no crédito por Estado  )
	
@author MarceloLauschner
@since 07/02/2014
@version 1.0		

@return character, Query auxiliar para filtrar pedidos na analise de crédito por cliente

@example
(examples)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784592)
/*/
User Function M450ABRW()

	//If ExistBlock("M450ABRW")
	//		cQuery := ExecBlock('M450ABRW',.F.,.F.,{ cQuery })
	//	EndIf
	Local		aAreaOld	:= GetArea()
	Local		cQryRet		:= ParamIxb[1]
	Local		cQryAux		:= ""
	Local 		cFilCorr	:= cFilAnt 
	Local 		aSelFil		:= {}
	Local 		cTmpFil		:= ""
	


	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M450ABRW")
		Return cQryRet
	Endif

	If GetNewPar("BF_M450FBR",.T.) .And. __cUserId $ GetNewPar("BF_M450ABR","000130#000077") // .And. MsgYesNo("Deseja listar os clientes de todas as filiais?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		
		If  FindFunction("AdmSelecFil")
			AdmSelecFil("FIC010",17,.F.,@aSelFil,"SC9",(FwModeAccess("SC9",1) == "E"),(FwModeAccess("SC9",2) == "E"),cFilCorr)
		Else
			aSelFil := AdmGetFil(.F.,.F.,"SC9")
		Endif
		If Empty(aSelFil)
			Aadd(aSelFil,cFilCorr)
		Endif	

		cQryAux	+= " AND SC9.C9_FILIAL " + GetRngFil(aSelFil,'SC9',.T.,@cTmpFil) 
		cQryRet += cQryAux
		CtbTmpErase(cTmpFil)
		// Somente usuários previamente definidos poderão liberar pedidos de todos os valores. Demais só terão acesso a pedidos conforme limite de parametro
	ElseIf __cUserId $ GetNewPar("BF_M450ABR","000130#000077")  // Marcelo # Silvana  ( Marcelo por causa de Testes )
		// Mesmo não precisando filtrar os clientes por valor dos pedidos, executa filtro por Filial para restringir clientes com pedidos por filial
		cQryAux	+= " AND SC9.C9_FILIAL = '"+xFilial("SC9")+"' "
		cQryRet += cQryAux
	Else
		cQryAux	+= " AND (SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQryAux += "        FROM "+RetSqlName("SC9") + " C9B "
		cQryAux += "       WHERE C9B.D_E_L_E_T_ = ' ' "
		cQryAux += "         AND C9B.C9_CLIENTE = SC9.C9_CLIENTE "
		cQryAux += "         AND C9B.C9_LOJA = SC9.C9_LOJA "
		cQryAux += "         AND C9B.C9_FILIAL = SC9.C9_FILIAL "
		cQryAux += "         AND C9B.C9_BLCRED NOT IN ('  ','10','ZZ','09' )) <= "+Alltrim(Str(GetNewPar("BF_M450MIN",1000))) // Valor a ser editado por parametro se necessário
		cQryAux	+= " AND SC9.C9_FILIAL = '"+xFilial("SC9")+"' "
		cQryRet += cQryAux
	Endif

	RestArea(aAreaOld)

Return cQryRet

