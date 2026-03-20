#include "topconn.ch"

/*/{Protheus.doc} MT100GRV
(Ponto de entrada durante gravação de documento entrada. Se exclusão Doc.Entrada exclui Lcto Conta´bil  )

@author MarceloLauschner
@since 16/07/2012
@version 1.0

@return lExp02,Informa se a nota pode ou não ser gravada/excluída.

@example
(User Function MT100GRV()Local lExp01 := PARAMIXB[1]Local lExp02 := .T.//Validações do usuárioReturn lExp01 )

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6085394)
/*/
User Function XMT100GRV()
	
	
	// lRetGrv := ExecBlock("MT100GRV",.F.,.F.,{lDeleta})
	
	Local	aAreaOld		:= GetArea()
	Local	lRetGrv			:= .T.
	Local 	lRet	 		:= .T.
	Local 	aItens 			:= {}
	Local	aCab   			:= {}
	Local	cQry			:= ""
	Local	lVldDeleta		:= !Empty(SF1->F1_DTLANC) .And. ParamIxb[1]
	Local	aRecSD1			:= {}
	// IAGO 16/10/2015 Chamado(12522)
	Local 	cCgc			:= ""
	Local	iZ
	
	Private lMsErroAuto
	Private lMsHelpAuto 	:= .F.
	
	If lVldDeleta
		
		If Empty(SF1->F1_DTLANC)
			RestArea(aAreaOld)
			Return lRetGrv
		Endif
		
		dbSelectArea("SD1")
		dbSetOrder(1)
		dbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)
		While !Eof() .And. xFilial("SD1") == SD1->D1_FILIAL .And. SD1->D1_DOC == SF1->F1_DOC .And. ;
				SD1->D1_SERIE == SF1->F1_SERIE .And. SD1->D1_FORNECE == SF1->F1_FORNECE .And. ;
				SD1->D1_LOJA == SF1->F1_LOJA
			Aadd(aRecSD1,SD1->(Recno()))
			dbSelectArea("SD1")
			dbSkip()
		EndDo 
		
		cQry += "SELECT CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_FILIAL,CT2_LINHA,CT2_MOEDLC,CT2_DC,CT2_DEBITO,CT2_CREDIT,CT2_VALOR,"
		cQry += "        CT2_ORIGEM,CT2_HIST,CT2_CLVLDB,CT2_CLVLCR,CT2_CCC,CT2_CCD "
		cQry += "  FROM "+RetSqlName("CT2") + " CT2 "
		cQry += " WHERE (R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SF1' "
		cQry += "                        AND CTK_RECORI = '"+Alltrim(Str(SF1->(Recno())))+"') "
		cQry += "    OR R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SD1' "
		cQry += "                        AND CTK_RECORI IN( "
		
		For iZ := 1 To Len(aRecSD1)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'"+Alltrim(Str(aRecSD1[iZ]))+"' "
		Next
		cQry += "))"
		
		cQry += "  ) AND D_E_L_E_T_ = ' ' "
		
		TCQUERY cQry NEW ALIAS "QCTK"
		
		If !Eof()
			aCab	:=  { 	{'DDATALANC' ,STOD(QCTK->CT2_DATA) 	,NIL},;
				{'CLOTE' 	 	,QCTK->CT2_LOTE 	,NIL},;
				{'CSUBLOTE'  	,QCTK->CT2_SBLOTE	,NIL},;
				{'CDOC' 	 	,QCTK->CT2_DOC		,NIL}}
		Endif
		
		DbSelectArea("QCTK")
		DbGotop()
		While !Eof()
			
			aAdd(aItens,{  	{'CT2_FILIAL'  	,QCTK->CT2_FILIAL  	, NIL},;
				{'CT2_LINHA'  	,QCTK->CT2_LINHA   	, NIL},;
				{'CT2_MOEDLC'  	,QCTK->CT2_MOEDLC  	, NIL},;
				{'CT2_DC'   		,QCTK->CT2_DC		, NIL},;
				{'CT2_DEBITO'  	,QCTK->CT2_DEBITO	, NIL},;
				{'CT2_CREDIT'  	,QCTK->CT2_CREDIT	, NIL},;
				{'CT2_VALOR'  	,QCTK->CT2_VALOR	, NIL},;
				{'CT2_HIST'  		,QCTK->CT2_HIST 	, NIL},;
				{'CT2_CCD'  		,QCTK->CT2_CCD		, NIL},;
				{'CT2_CCC'  		,QCTK->CT2_CCC		, NIL},;
				{'CT2_CLVLDB'  	,QCTK->CT2_CLVLDB 	, NIL},;
				{'CT2_CLVLCR' 	,QCTK->CT2_CLVLCR	, NIL} } )
			
			//	Aadd(aItens,{	{"CT2_LINHA"	,QCTK->CT2_LINHA	,NIL				},;
				//				{"LINPOS"		,"CT2_LINHA"		,QCTK->CT2_LINHA	}})
			QCTK->(DbSkip())
		Enddo
		QCTK->(DbCloseArea())
		
		// Se não houveram registros retorna antes de tentar excluir o lanaçmento contábil
		If Len(aItens) == 0
			MsgAlert("Não foi localizada informação de contabilização desta nota fiscal para que fosse feita a exclusão contábil desta nota.","Sem registro de contabilização")
			RestArea(aAreaOld)
			Return .T.
		Endif
		
		// Guardo variaveis publicas
		nModBk	:= nModulo
		cModBk	:= cModulo
		xBkTTS	:= __TTSInUse
		// Altero variaveis publicas
		nModulo	:= 34
		cModulo	:= "CTB"
		__TTSInUse := .F.
		
		// Executa a exclusão
		CTBA102(aCab ,aItens, 5)
		
		// Restauro as variaveis
		__TTSInUse := xBkTTS
		nModulo	:= nModBk
		cModulo	:= cModBk
		
		// Verifica se o lanaçmento efetivamente foi excluido
		cQry := "SELECT CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_FILIAL,CT2_LINHA,CT2_MOEDLC,CT2_DC,CT2_DEBITO,CT2_CREDIT,CT2_VALOR,"
		cQry += "        CT2_ORIGEM,CT2_HIST,CT2_CLVLDB,CT2_CLVLCR,CT2_CCC,CT2_CCD "
		cQry += "  FROM "+RetSqlName("CT2") + " CT2 "
		cQry += " WHERE (R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SF1' "
		cQry += "                        AND CTK_RECORI = '"+Alltrim(Str(SF1->(Recno())))+"') "
		cQry += "    OR R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SD1' "
		cQry += "                        AND CTK_RECORI IN( "
		
		For iZ := 1 To Len(aRecSD1)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'"+Alltrim(Str(aRecSD1[iZ]))+"' "
		Next
		cQry += "))"
		
		cQry += " )  AND D_E_L_E_T_ = ' ' "
		
		TCQUERY cQry NEW ALIAS "QCTK"
		
		If !Eof()
			lRetGrv	:= .F.
			MsgAlert('Erro na exclusão do Lançamento Contábil')
		Else
			MsgInfo('Exclusão do Lançamento contábil com Sucesso!')
			// Forço a atualização do Flag de Contabilização da Nota fiscal para evitar que seja chamada a contabilização de exclusão do sistema
			RestArea(aAreaOld)
			DbSelectArea("SF1")
			RecLock("SF1",.F.)
			SF1->F1_DTLANC	:= CTOD("")
			MsUnlock()
			
		EndIf
		QCTK->(DbCloseArea())
		
		If SF1->F1_TIPO $ "B#D" .And. cEmpAnt $ "02" // Somente Atrialub
			// IAGO 16/10/2015 Chamado(12522)
			// Estorna baixa do tanque
			cCgc := Posicione("SA1",1,xFilial("SA1")+SF1->F1_FORNECE+SF1->F1_LOJA,"A1_CGC")
			
			cQryP := "SELECT R_E_C_N_O_ AS RECNO"
			cQryP += "  FROM "+ RetSqlName("PA2") +" PA2"
			cQryP += " WHERE PA2_FILIAL = '"+ xFilial("PA2") +"'"
			cQryP += "   AND PA2_NFRETO = '"+ SF1->F1_DOC +"'"
			cQryP += "   AND PA2_SERRET = '"+ SF1->F1_SERIE +"'"
			cQryP += "   AND PA2_CGCRET = '"+ cCgc +"'"
			cQryP += "   AND D_E_L_E_T_ = ' '"
			
			TCQUERY cQryP NEW ALIAS "QRYP"
			
			While QRYP->(!EOF())
				dbSelectArea("PA2")
				dbGoTo(QRYP->RECNO)
				RecLock("PA2",.F.)
				PA2->PA2_CGCRET	:= " "
				PA2->PA2_NFRETO	:= " "
				PA2->PA2_SERRET	:= " "
				MsUnlock()
				QRYP->(dbSkip())
			End
			
			QRYP->(dbCloseArea())
		Endif
	
	Endif
	
	RestArea(aAreaOld)
	
Return lRetGrv

