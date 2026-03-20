#INCLUDE "topconn.ch"


/*/{Protheus.doc} SF2520E
(Ponto de entrada antes da exclusão da NFe e depois de passar pelas validações MaCanDelF2 / MA521VerSC6 / MS520VLD )
@type function
@author marce
@since 14/06/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function SF2520E()

	Local		aAreaOld		:= GetArea()
	Local	 	cFunCall  		:= SubStr(ProcName(0),3)
	Local 		lPEICMAIS 		:= ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)
	Local 		lUsrPrtDnf		:= __cUserId $ GetNewPar("GM_USRPTDF",__cUserId)
	Local 		lFirstItem		:= .T.
	Private 	lRetorno 		:= .T.
	Private		aRecSD2			:= {}


	Dbselectarea("SD2")
	Dbsetorder(3)
	Dbseek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
	While !Eof() .and. SD2->D2_FILIAL == xFilial("SD2") .and. SD2->D2_DOC == SF2->F2_DOC .and. SD2->D2_SERIE == SF2->F2_SERIE .And.;
			SD2->D2_CLIENTE == SF2->F2_CLIENTE .And. SD2->D2_LOJA == SF2->F2_LOJA

		// Alimenta vetor para localizar CTK de lançamentos contábeis
		Aadd(aRecSD2,SD2->(Recno()))

		If !Empty(SD2->D2_PEDIDO) .And. lUsrPrtDnf .And. lFirstItem


			// Gravo Flag de Impressao da Danfe no Pedido, permitindo que o mesmo possa ser alterado novamente
			DbSelectArea("SC5") //Pedidos de Venda
			DbSetOrder(1)
			DbSeek(xFilial("SC5")+SD2->D2_PEDIDO)
			Dbselectarea("SC5")
			If SC5->(FieldPos("C5_BLPED")) <> 0
				If MsgYesNo("Deseja voltar o pedido para o TMK?","SF2520E - Voltar pedido TMK")
					RecLock("SC5",.F.)
					SC5->C5_BLPED := "I"
					MsUnlock()
				Endif
			Endif
			lFirstItem	:= .F.
		Endif

		Dbselectarea("SD2")
		Dbskip()
	Enddo

	// Efetua chamada para exclusão do Lançamento Contábil
	sfDelCT2()

	// Manter o trexo de código a seguir no final do fonte
	If lPEICMAIS
		xRet := ExecBlock( 'T'+ cFunCall, .F., .F., )
	EndIf

	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfDelCT2
(Localiza CT2 e efetua exclusão via ExecAuto CTBA102)
@author MarceloLauschner
@since 22/11/2011
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfDelCT2()

	Local	aAreaOld	:= GetArea()
	Local 	lRet	 	:= .T.
	Local 	aItens 		:= {}
	Local	aCab   		:= {}
	Local	cQry		:= ""
	Local	iz

	PRIVATE lMsErroAuto	:= .F.

	If Empty(SF2->F2_DTLANC)
		U_WFGERAL("marcelo@centralxml.com.br","Cancelada a nota fiscal "+SF2->F2_SERIE+"/"+SF2->F2_DOC," Sem exclusão do lançamento contábil da NF "+SF2->F2_SERIE+"/"+SF2->F2_DOC + " Empresa/Filial: "+cEmpAnt+"/"+cFilAnt)
		RestArea(aAreaOld)
		Return lRet
	Endif
	cQry += "SELECT CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_FILIAL,CT2_LINHA,CT2_MOEDLC,CT2_DC,CT2_DEBITO,CT2_CREDIT,CT2_VALOR,CT2_ORIGEM,CT2_HIST "
	cQry += "  FROM "+RetSqlName("CT2") + " CT2 "
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND (R_E_C_N_O_ IN(SELECT CTK_RECDES "
	cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
	cQry += "                      WHERE CTK_LOTE = '8820' "
	cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
	cQry += "                        AND CTK_DATA = '"+DTOS(SF2->F2_DTLANC)+"' "
	cQry += "                        AND D_E_L_E_T_ = ' ' "
	cQry += "                        AND CTK_RECDES != ' ' "
	cQry += "                        AND CTK_TABORI = 'SF2' "
	cQry += "                        AND CTK_RECORI = '"+Alltrim(Str(SF2->(Recno())))+"') "
	cQry += "    OR R_E_C_N_O_ IN(SELECT CTK_RECDES "
	cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
	cQry += "                      WHERE CTK_LOTE = '8820' "
	cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
	cQry += "                        AND CTK_DATA = '"+DTOS(SF2->F2_DTLANC)+"' "
	cQry += "                        AND D_E_L_E_T_ = ' ' "
	cQry += "                        AND CTK_RECDES != ' ' "
	cQry += "                        AND CTK_TABORI = 'SD2' "
	cQry += "                        AND CTK_RECORI IN( "

	For iZ := 1 To Len(aRecSD2)
		If iZ > 1
			cQry += ","
		Endif
		cQry += "'"+Alltrim(Str(aRecSD2[iZ]))+"' "
	Next
	cQry += ")))"

	TCQUERY cQry NEW ALIAS "QCTK"

	If !Eof()
		aCab	:=  { 	{'DDATALANC' ,STOD(QCTK->CT2_DATA) 	,NIL},;
			{'CLOTE' 	 ,QCTK->CT2_LOTE 	,NIL},;
			{'CSUBLOTE'  ,QCTK->CT2_SBLOTE	,NIL},;
			{'CDOC' 	 ,QCTK->CT2_DOC		,NIL},;
			{'CPADRAO' 	 ,' ' 				,NIL},;
			{'NTOTINF'   ,0 				,NIL},;
			{'NTOTINFLOT',0 				,NIL} }
	Endif

	While !Eof()

		aAdd(aItens,{  	{'CT2_FILIAL'  	,QCTK->CT2_FILIAL	, NIL},;
			{'CT2_LINHA'   	,QCTK->CT2_LINHA  	, NIL},;
			{'CT2_MOEDLC'  	,QCTK->CT2_MOEDLC	, NIL},;
			{'CT2_DC'   	,QCTK->CT2_DC	  	, NIL},;
			{'CT2_DEBITO'  	,QCTK->CT2_DEBITO	, NIL},;
			{'CT2_CREDIT'   ,QCTK->CT2_CREDIT 	, NIL},;
			{'CT2_VALOR'  	,QCTK->CT2_VALOR	, NIL},;
			{'CT2_ORIGEM' 	,QCTK->CT2_ORIGEM	, NIL},;
			{'CT2_HP'   	,' '   				, NIL},;
			{'CT2_HIST'   	,QCTK->CT2_HIST		, NIL} } )

		QCTK->(DbSkip())
	Enddo
	QCTK->(DbCloseArea())

	If Len(aItens) == 0
		Return .T.
	Endif

	MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} ,aCab ,aItens, 5) // 5-Exclusão

	If lMsErroAuto <> Nil
		If !lMsErroAuto
			lRet	:= .T.
			If !IsBlind()
				MsgInfo('Exclusão do Lançamento contábil com Sucesso!',"SF2520E - Exclusão de Nota")
			EndIf
		Else
			lRet	:= .F.
			If !IsBlind()
				MsgAlert('Erro na exclusão do Lançamento Contábil',"SF2520E - Exclusão de Nota")
			Endif
		EndIf
	EndIf

	// Forço a atualização do Flag de Contabilização da Nota fiscal para evitar que seja chamada a contabilização de exclusção do sistema
	DbSelectArea("SF2")
	RecLock("SF2",.F.)
	SF2->F2_DTLANC	:= CTOD("")
	MsUnlock()

	RestArea(aAreaOld)

Return lRet


