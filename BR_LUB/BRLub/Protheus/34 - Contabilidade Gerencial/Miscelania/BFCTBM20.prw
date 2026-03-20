#Include 'Protheus.ch'

User Function BFCTBM20()

	Local 		cNewCod  	:= Space(TamSX3("CTT_CUSTO")[1])
	Local 		oCodAtu,oNewCod
	Local 		oDlg
	Local 		cSenhaDig 	:= Space(20)
	Local	 	cCodAtu  	:= Space(TamSX3("CTT_CUSTO")[1])
	Local		dDataIni	:= FirstDay(dDataBase)
	Local		dDataFim	:= LastDay(dDataBase)


	DEFINE MSDIALOG oDlg Title OemToAnsi("Executar Atualização de Centros de Custos 'DE -> PARA'") FROM 001,001 TO 210,450 PIXEL

	@ 005,010 Say ("Digite a Senha: ") Pixel Of oDlg
	@ 005,050 MsGet cSenhaDig Valid PesqSenha(cSenhaDig) Picture "@!" PassWord Pixel Of oDlg

	@ 020,010 Say ("Informe o Código atual Centro Custo ") Pixel Of oDlg
	@ 032,010 MsGet oCodAtu Var cCodAtu Valid  ExistCpo("CTT",cCodAtu,1) Size 70,10 Picture "@!" F3 "CTT" Pixel Of oDlg
	@ 020,110 Say ("Informe o novo Código de Centro de Custo") Pixel Of oDlg
	@ 032,110 MsGet oNewCos Var cNewCod Valid  (ExistCpo("CTT",cNewCod,1) .And. cNewCod <> cCodAtu) Size 70,10 Picture "@!" F3 "CTT" Pixel Of oDlg
	
	@ 050,010 Say ("Informe o período para atualizar") Pixel Of oDlg
	@ 062,010 MsGet oDataIni Var dDataIni Size 40,10 Pixel Of oDlg
	@ 062,060 MsGet oDataFim Var dDataFim Size 40,10 Pixel Of oDlg
	
	@ 090,060 BUTTON "Cancela" Size 45,10	 Action (oDlg:End()) Pixel Of oDlg
	@ 090,010 BUTTON "Confirma" Size 45,10	 Action (Processa({|| ProcSB1(cCodAtu,cNewCod,dDataIni,dDataFim)},"Processando..."), oDlg:End())	Pixel Of oDlg
					
	ACTIVATE MsDialog oDlg Centered


Return


Static Function PesqSenha(cInSenha)
           
	Local bRet := .F.
   
                                                  
	If UPPER(Alltrim(cInSenha)) == UPPER(Alltrim("altcttdepara"+DTOS(dDataBase)))
		bRet := .T.
	Endif

Return bRet


Static Function ProcSB1(cInCodAtu,cInNewCod,dInDataIni,dInDataFim)
	Local	cQry 		:= ""
	Local	cCT2Doc	:= ""
	Local	aCab		:= {}
	Local	aItensDel	:= {}
	Local	aItensInc	:= {}

	cQry += "SELECT CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_FILIAL,CT2_LINHA,CT2_MOEDLC,"
	cQry += "       CT2_DC,CT2_DEBITO,CT2_CREDIT,CT2_VALOR,CT2_ORIGEM,CT2_HIST,"
	cQry += "       CASE WHEN CT2_CCD = '"+cInCodAtu+"' THEN '"+cInNewCod+"' ELSE CT2_CCD END CT2_CCD,"
	cQry += "       CASE WHEN CT2_CCC = '"+cInCodAtu+"' THEN '"+cInNewCod+"' ELSE CT2_CCC END CT2_CCC"
	cQry += "  FROM "+RetSqlName("CT2") + " CT2 "
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND CT2_DATA BETWEEN '" + DTOS(dInDataIni) + "' AND '" + DTOS(dInDataFim) + "' "
	cQry += "   AND CT2_FILIAL = '"+xFilial("CT2")+"' "
	cQry += "   AND (CT2_FILIAL,CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC) IN ( "
	cQry += "SELECT CT2_FILIAL,CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC "
	cQry += "  FROM "+RetSqlName("CT2") + " CT2 "
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND CT2_DATA BETWEEN '" + DTOS(dInDataIni) + "' AND '" + DTOS(dInDataFim) + "' "
	cQry += "   AND (CT2_CCD = '"+cInCodAtu+"' OR CT2_CCC = '"+cInCodAtu+"' )"
	cQry += "   AND CT2_FILIAL = '"+xFilial("CT2")+"') "
	cQry += " ORDER BY CT2_FILIAL,CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QCT2', .F., .T.)

	While !Eof()

		If cCT2Doc <> QCT2->CT2_FILIAL+QCT2->CT2_DATA+QCT2->CT2_LOTE+QCT2->CT2_SBLOTE+QCT2->CT2_DOC
			If !Empty(cCT2Doc)
				If !sfCtba102(aCab,aItensDel,aItensInc)
					Exit
				Endif
				aCab		:= {}
				aItensDel	:= {}
				aItensInc	:= {}
			Endif
			
			aCab	:=  { ;
				{'DDATALANC' 	,STOD(QCT2->CT2_DATA) 	,NIL},;
				{'CLOTE' 	 	,QCT2->CT2_LOTE 			,NIL},;
				{'CSUBLOTE'  	,QCT2->CT2_SBLOTE			,NIL},;
				{'CDOC' 	 	,QCT2->CT2_DOC			,NIL},;
				{'CPADRAO' 	,' ' 						,NIL},;
				{'NTOTINF'   	,0 							,NIL},;
				{'NTOTINFLOT'	,0 							,NIL} }
		Endif
	   
		cCT2Doc :=  QCT2->CT2_FILIAL+QCT2->CT2_DATA+QCT2->CT2_LOTE+QCT2->CT2_SBLOTE+QCT2->CT2_DOC
	   
		If Alltrim(cInNewCod) $ Alltrim(QCT2->CT2_CCC)+"#"+Alltrim(QCT2->CT2_CCD) .And. QCT2->CT2_VALOR > 0.01
			Aadd(aItensDel,{ ;
				{'CT2_FILIAL'  	,QCT2->CT2_FILIAL		, NIL},;
				{'CT2_LINHA'   	,QCT2->CT2_LINHA  	, NIL},;
				{'CT2_MOEDLC'  	,QCT2->CT2_MOEDLC		, NIL},;
				{'CT2_DC'   		,QCT2->CT2_DC 		, NIL},;
				{'CT2_DEBITO'  	,QCT2->CT2_DEBITO		, NIL},;
				{'CT2_CREDIT'   	,QCT2->CT2_CREDIT 	, NIL},;
				{'CT2_VALOR'  	,QCT2->CT2_VALOR-0.01		, NIL},;
				{'CT2_CCD'		  	,QCT2->CT2_CCD		, NIL},;
				{'CT2_CCC' 	  	,QCT2->CT2_CCC	 	, NIL},;
				{'CT2_ORIGEM' 	,QCT2->CT2_ORIGEM		, NIL},;
				{'CT2_HIST'   	,QCT2->CT2_HIST		, NIL}})
				Aadd(aItensDel[Len(aItensDel)],{'LINPOS'      	,'CT2_LINHA'        	,QCT2->CT2_LINHA}	)
			
			Aadd(aItensDel,{ ;
				{'CT2_FILIAL'  	,QCT2->CT2_FILIAL		, NIL},;
				{'CT2_LINHA'   	,"xxx"				  	, NIL},;
				{'CT2_MOEDLC'  	,QCT2->CT2_MOEDLC		, NIL},;
				{'CT2_DC'   		,QCT2->CT2_DC 		, NIL},;
				{'CT2_DEBITO'  	,QCT2->CT2_DEBITO		, NIL},;
				{'CT2_CREDIT'   	,QCT2->CT2_CREDIT 	, NIL},;
				{'CT2_VALOR'  	,0.01					, NIL},;
				{'CT2_CCD'		  	,QCT2->CT2_CCD		, NIL},;
				{'CT2_CCC' 	  	,QCT2->CT2_CCC	 	, NIL},;
				{'CT2_ORIGEM' 	,QCT2->CT2_ORIGEM		, NIL},;
				{'CT2_HIST'   	,QCT2->CT2_HIST		, NIL} } )
		
			If QCT2->CT2_DC $ "1#3"
				Aadd(aItensDel[Len(aItensDel)],{'CT2_CLVLDB'	, cFilAnt	, NIL})
			Endif
			If QCT2->CT2_DC $ "2#3"
				Aadd(aItensDel[Len(aItensDel)],{'CT2_CLVLCR'	, cFilAnt	, NIL})
			Endif
		
		Else

			Aadd(aItensDel,{ ;
				{'CT2_FILIAL'  	,QCT2->CT2_FILIAL		, NIL},;
				{'CT2_LINHA'   	,QCT2->CT2_LINHA  	, NIL},;
				{'CT2_MOEDLC'  	,QCT2->CT2_MOEDLC		, NIL},;
				{'CT2_DC'   		,QCT2->CT2_DC 		, NIL},;
				{'CT2_DEBITO'  	,QCT2->CT2_DEBITO		, NIL},;
				{'CT2_CREDIT'   	,QCT2->CT2_CREDIT 	, NIL},;
				{'CT2_VALOR'  	,QCT2->CT2_VALOR		, NIL},;
				{'CT2_CCD'		  	,QCT2->CT2_CCD		, NIL},;
				{'CT2_CCC' 	  	,QCT2->CT2_CCC	 	, NIL},;
				{'CT2_ORIGEM' 	,QCT2->CT2_ORIGEM		, NIL},;
				{'CT2_HP'   		,' '   				, NIL},;
				{'CT2_CONVER'		,'15555'				, NIL},;
				{'CT2_HIST'   	,QCT2->CT2_HIST		, NIL},;
				{'LINPOS'      	,'CT2_LINHA'        	,QCT2->CT2_LINHA} } )
			If QCT2->CT2_DC $ "1#3"
				Aadd(aItensDel[Len(aItensDel)],{'CT2_CLVLDB'	, cFilAnt	, NIL})
			Endif
			If QCT2->CT2_DC $ "2#3"
				Aadd(aItensDel[Len(aItensDel)],{'CT2_CLVLCR'	, cFilAnt	, NIL})
			Endif
		
		Endif
		Aadd(aItensInc,{ ;
			{'CT2_FILIAL'  	,QCT2->CT2_FILIAL		, NIL},;
			{'CT2_LINHA'   	,QCT2->CT2_LINHA  	, NIL},;
			{'CT2_MOEDLC'  	,QCT2->CT2_MOEDLC		, NIL},;
			{'CT2_DC'   		,QCT2->CT2_DC	  		, NIL},;
			{'CT2_DEBITO'  	,QCT2->CT2_DEBITO		, NIL},;
			{'CT2_CREDIT'   	,QCT2->CT2_CREDIT 	, NIL},;
			{'CT2_VALOR'  	,QCT2->CT2_VALOR		, NIL},;
			{'CT2_CCD'		  	,QCT2->CT2_CCD		, NIL},;
			{'CT2_CCC' 	  	,QCT2->CT2_CCC	 	, NIL},;
			{'CT2_ORIGEM' 	,QCT2->CT2_ORIGEM		, NIL},;
			{'CT2_HP'   		,' '   				, NIL},;
			{'CT2_CONVER'		,'15555'				, NIL},;
			{'CT2_HIST'   	,QCT2->CT2_HIST		, NIL},;
			{'LINPOS'      	,'CT2_LINHA'        	,QCT2->CT2_LINHA} } )
			// Adiciono Classe de Valor 
		If QCT2->CT2_DC $ "1#3"
			Aadd(aItensInc[Len(aItensInc)],{'CT2_CLVLDB'	, cFilAnt	, NIL})
		Endif
		If QCT2->CT2_DC $ "2#3"
			Aadd(aItensInc[Len(aItensInc)],{'CT2_CLVLCR'	, cFilAnt	, NIL})
		Endif
			 
		DbSelectArea("QCT2")
		DbSkip()
	Enddo
	QCT2->(DbCloseArea())

	If !Empty(cCT2Doc)
		sfCtba102(aCab,aItensDel,aItensInc)
	Endif
    
Return


Static Function sfCtba102(aInCab,aInDelItens,aInIncItens)

	Local		lRet		:= .T.
	Local		cMaxItem	:= "001"
	Private	lMsErroAuto	:= .F.
	// Forço a correção do item
	For iD := 1 To Len(aInDelItens)
		If cMaxItem < aInDelItens[iD,2,2] .And. aInDelItens[iD,2,2] <> "xxx"
			cMaxItem	:= aInDelItens[iD,2,2]
		Endif
	Next
	
	For iD := 1 To Len(aInDelItens)
		If aInDelItens[iD,2,2] == "xxx"
			cMaxItem	:= Soma1(cMaxItem)
			aInDelItens[iD,2,2]	:= cMaxItem
		Endif
	Next
	
// Primeiro excluo o lançamento, pois o CTBA102 automático não trabalha com centro de custo. Após testes foi descoberto esta falha
	Begin Transaction
		MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} ,aInCab ,aInDelItens, 4) // 5- Exclusão
	End Transaction

	If lMsErroAuto <> Nil
		If !lMsErroAuto
			lRet	:= .T.
			If !IsBlind()
				MsgInfo('Exclusão do Lançamento contábil com Sucesso!')
			EndIf
		Else
			lRet	:= .F.
			If !IsBlind()
				MostraErro()
			Endif
		EndIf
	EndIf
/*
	lMsErroAuto	:= .F.

	Begin Transaction
		MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} ,aInCab ,aInIncItens, 4) //3-Inclusão
	End Transaction

	If lMsErroAuto <> Nil
		If !lMsErroAuto
			lRet	:= .T.
			If !IsBlind()
				MsgInfo('Inclusão do Lançamento contábil com Sucesso!')
			EndIf
		Else
			lRet	:= .F.
			If !IsBlind()
				MostraErro()
			Endif
		EndIf
	EndIf
	*/
Return lRet

