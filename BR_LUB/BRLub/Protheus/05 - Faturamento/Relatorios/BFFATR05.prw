#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} DIS092
(Compara Fretes)
@author MarceloLauschner
@since 22/11/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function DIS092()
	
Return U_BFFATR05()

/*/{Protheus.doc} BFFATR05
(long_description)
@author MarceloLauschner
@since 22/11/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATR05()
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Private		aCab     	:= {}
	Private		aItem    	:= {}
	Private		aTotItem 	:= {}
	Private 	aChoice 	:= {"","C","R","S"}
	Private 	cTipoarq   	:= Space(1)
	Private 	cTransp   	:= Space(6)
	Private 	cTipoCTE  	:= Padr("CTR",TamSX3("F1_ESPECIE")[1])
	Private 	cTesCTE  	:= Padr("048",TamSX3("D1_TES")[1])
	Private 	cTesMalote  := Padr("164",TamSX3("D1_TES")[1])
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Montagem da tela de processamento.                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	@ 01,001 TO 190,380 DIALOG oLeTxt TITLE OemToAnsi("Leitura de Arquivo Texto")
	@ 02,010 TO 080,190
	@ 10,018 Say " Este programa irá validar as faturas de Frete "
	@ 34,018 Say "Transp p Validacao"
	@ 34,065 GET  cTransp PICTURE "@!" When .T. Size 40,20 Valid Iif(!Empty(cTransp),ExistCpo("SA4",cTransp,1,"N. INVALIDO"),.F.) F3 "SA4"
	@ 80,065 BUTTON "Confirma" Size 50,15 ACTION Processa({|| Validar()},"Validando Informacoes")
	@ 80,128 BUTTON "Cancela" Size 50,15 Action oLeTxt:End()
	
	Activate Dialog oLeTxt Centered
	
Return


/*/{Protheus.doc} Validar
(long_description)
@author MarceloLauschner
@since 26/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Validar()
	
	Local a
	Local oTmpTable := NIL

	cPathori := "C:\EDI\TRANSP\"
	cTipo    := "*.*"
	aFiles   := Directory(cPathOri + cTipo)
	
	Close(oLeTxt)
	
	For a := 1 To Len(aFiles)
		
		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",680,0 })
		
		//cNomArq := CriaTrab(aCampos)
		
		If (Select("TRB") <> 0)
			dbSelectArea("TRB")
			dbCloseArea("TRB")
		Endif
		//dbUseArea(.T.,,cNomArq,"TRB",nil,.F.)
		oTmpTable := FWTemporaryTable():New("TRB",aCampos)
		oTmpTable:Create()
		
		If !File(Alltrim("C:\EDI\TRANSP\" + aFiles[a][1]))
			MsgInfo("Arquivo texto nao existente.Programa cancelado","Informa‡ao")
			Return
		Endif
		
		dbSelectArea("TRB")
		Append From (Alltrim("C:\EDI\TRANSP\" + aFiles[a][1])) SDF
		
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicializa a regua de processamento                                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Processa({|| sfGrvTbl()},"Registrando dados no banco de dados....")
		
		Processa({|| RunCont2() },"Processando...")
		FErase(cNomArq + GetDbExtension()) // Deleting file
		FErase(cNomArq + OrdBagExt()) // Deleting index
	Next
	
	MsgInfo("Validacao concluida!!","Informacao")
	oLeTxt:End()
	
Return
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Copia o arquivo de trabalho e depois apaga                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

/*/{Protheus.doc} RunCont2
(long_description)
@author MarceloLauschner
@since 26/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RunCont2()
	
	Local	nCont354		:= 0
	Local	cQry			:= ""
	Local	cQryF2			:= ""
	Local	cQryF1			:= ""
	Local	cNumCte			:= ""
	Local	nValCte			:= 0
	Local	nTmF1Doc		:= TamSX3("F1_DOC")[1]
	Local	nTmF2Doc		:= TamSX3("F2_DOC")[1]
	Private aRejeita 		:= {}
	Private nConta 			:= 0
	Private nValorConbrado 	:= 0
	Private nValDevido		:= 0
	Private nValMerc		:= 0
	Private nValPeso		:= 0
	Private cCgcTransp		:= ""
	
	If !(cFilAnt $ "07#08")
		nTmF2Doc	:= 6
	Endif
	
	cSERIENF :=  GetMv("GM_SERIENF")

	dbSelectArea("TRB")
	ProcRegua(RecCount()) // Numero de registros a processar
	dbGoTop()
	While !Eof()
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Incrementa a regua                                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		
		IncProc("Registro: "+Substr(TRB->LINHA,25,06))
		
		If Substr(TRB->LINHA,01,03) == "322"
			
			
			nConta++
			
			dbSelectArea("SA4")
			dbSetOrder(1)
			If dbSeek(xFilial("SA4")+cTransp)
			
			Else
				MsgInfo("Transportadora Nao Encontrada","Informacao")
				Return
			Endif
			
			lExistCte	:= .F.
			
			cQry := "SELECT R_E_C_N_O_ AS NRECNO "
			cQry += "  FROM CONDORXML "                    ///40569
			cQry += " WHERE XML_CHAVE LIKE '%"+Alltrim(cValToChar(Val(Alltrim(Substr(TRB->LINHA,19,12)))))+"%' " // Concatena a Serie e Numero do documento
			cQry += "   AND XML_CHAVE LIKE '%"+Substr(TRB->LINHA,205,14)+"57%' " // Concatena com 57 para identificar somente Xml´s de CTE´s
			cQry += "   AND XML_EMIT = '"+Substr(TRB->LINHA,205,14)+"' "
			cQry += "   AND XML_EMISSA >= '" + DTOS(Date() - 180) + "'" 
			
			TCQUERY cQry NEW ALIAS "QCOND"
			
			If !Eof()
				lExistCte := .T.
			Endif
			QCOND->(DbCloseArea())
			
			cQry  := ""
			
			cQryF2 := " "
			cQryF2 += "SELECT F2_CLIENTE||'/'||F2_LOJA || ' ' || TO_DATE(MAX(F2_EMISSAO),'YYYYMMDD') CLIENTE,"
			cQryF2 += "       F2_CLIENTE,"
			cQryF2 += "       F2_LOJA,"
			cQryF2 += "       SUM(F2_CUSTOFR)AS CSTFR,"
			cQryF2 += "       SUM(F2_VALBRUT) AS VALMER,"
			cQryF2 += "       SUM(F2_PBRUTO) PESO, "
			cQryF2 += "       NVL((SELECT COUNT(*) "
			cQryF2 += "              FROM "+RetSqlName("SF2") + " B "
			cQryF2 += "             WHERE D_E_L_E_T_ = ' ' "
			cQryF2 += "               AND B.F2_EMISSAO IN(SELECT F2_EMISSAO "
			cQryF2 += "                                     FROM "+ RetSqlName("SF2") + " C "
			cQryF2 += "                                    WHERE C.D_E_L_E_T_ = ' ' "
			cQryF2 += "                                      AND C.F2_DOC IN ('"+StrZero(Val(Substr(TRB->LINHA,236,8)),nTmF2Doc)+"')"
			cQryF2 += "                                      AND C.F2_FILIAL = '"+xFilial("SF2")+"') "
			cQryF2 += "               AND B.F2_CLIENTE = A.F2_CLIENTE "
			cQryF2 += "               AND B.F2_LOJA = A.F2_LOJA "
			cQryF2 += "               AND B.F2_FILIAL = '"+xFilial("SF2")+"' ),0) QTE_REAL "
			cQryF2 += "  FROM "+ RetSqlName("SF2") + " A "
			cQryF2 += " WHERE D_E_L_E_T_ = ' ' "
			If !Empty(Substr(TRB->LINHA,233,3))
				cQryF2 += " AND F2_SERIE IN ('"+Substr(TRB->LINHA,233,3)+"','" + cSERIENF  + "')
			Endif
			cQryF2 += "   AND F2_DOC IN ('XX'"
			
			cQryF1 := " UNION ALL "
			cQryF1 += "SELECT F1_FORNECE||'/'||F1_LOJA || ' ' || TO_DATE(MAX(F1_DTDIGIT),'YYYYMMDD') CLIENTE,"
			cQryF1 += "       F1_FORNECE F2_CLIENTE,"
			cQryF1 += "       F1_LOJA F2_LOJA,"
			cQryF1 += "       0 AS CSTFR,"
			cQryF1 += "       SUM(F1_VALBRUT) AS VALMER,"
			cQryF1 += "       SUM(F1_PBRUTO) PESO, "
			cQryF1 += "       NVL((SELECT COUNT(*) "
			cQryF1 += "              FROM "+RetSqlName("SF1") + " B "
			cQryF1 += "             WHERE D_E_L_E_T_ = ' ' "
			cQryF1 += "               AND B.F1_EMISSAO IN(SELECT F1_EMISSAO "
			cQryF1 += "                                     FROM "+ RetSqlName("SF1") + " C "
			cQryF1 += "                                    WHERE C.D_E_L_E_T_ = ' ' "
			cQryF1 += "                                      AND C.F1_DOC IN ('"+StrZero(Val(Substr(TRB->LINHA,236,8)),nTmF2Doc)+"')"
			cQryF1 += "                                      AND C.F1_FILIAL = '"+xFilial("SF1")+"') "
			cQryF1 += "               AND B.F1_FORNECE = A.F1_FORNECE "
			cQryF1 += "               AND B.F1_LOJA = A.F1_LOJA "
			cQryF1 += "               AND B.F1_FILIAL = '"+xFilial("SF1")+"' ),0) QTE_REAL "
			cQryF1 += "  FROM "+ RetSqlName("SF1") + " A "
			cQryF1 += " WHERE D_E_L_E_T_ = ' ' "
			If !Empty(Substr(TRB->LINHA,233,3))
				cQryF1 += " AND F1_SERIE IN ('"+Substr(TRB->LINHA,233,3)+"','" + cSERIENF + "')
			Endif
			cQryF1 += "   AND F1_DOC IN ('XX'"
			
			cNotas	:= ""
			
			If !Empty(Val(Substr(TRB->LINHA,236,8)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,236,8)),nTmF2Doc)+"'"
				cNotas 	+= "/"+ cValToChar(Val(Substr(TRB->LINHA,236,8)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,236,9)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,236,9)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,236,9)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,238,6)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,238,6)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,238,6)))
			Endif
			
			
			If !Empty(Val(Substr(TRB->LINHA,247,8)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,247,8)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,247,8)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,248,9)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,248,9)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,248,9)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,249,6)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,249,6)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,249,6)))
			Endif
			
			If !Empty(Val(Substr(TRB->LINHA,258,8)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,258,8)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,258,8)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,260,9)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,260,9)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,260,9)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,260,6)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,260,6)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,260,6)))
			Endif
			
			If !Empty(Val(Substr(TRB->LINHA,269,8)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,269,8)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,269,8)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,272,9)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,272,9)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,272,9)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,271,6)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,271,6)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,271,6)))
			Endif
			
			If !Empty(Val(Substr(TRB->LINHA,280,8)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,280,8)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,280,8)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,284,9)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,284,9)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,284,9)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,282,6)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,282,6)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,282,6)))
			Endif
			
			If !Empty(Val(Substr(TRB->LINHA,296,9)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,296,9)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,296,9)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,291,8)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,291,8)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,291,8)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,293,6)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,293,6)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,293,6)))
			Endif
			
			If !Empty(Val(Substr(TRB->LINHA,308,9)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,308,9)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,308,9)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,302,8)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,302,8)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,302,8)))
			ElseIf !Empty(Val(Substr(TRB->LINHA,304,6)))
				cQry += ",'" + StrZero(Val(Substr(TRB->LINHA,304,6)),nTmF2Doc)+"'"
				cNotas 	+= "/"+cValToChar(Val(Substr(TRB->LINHA,304,6)))
			Endif
			
			cQry += " )
			
			cQryF2 += cQry
			cQryF2 += " AND F2_FILIAL = '" + xFilial("SF2") + "' "
			cQryF2 += "GROUP BY F2_CLIENTE,F2_LOJA "
			
			cQryF1 += cQry
			cQryF1 += " AND F1_FILIAL = '" + xFilial("SF1") + "' "
			cQryF1 += "GROUP BY F1_FORNECE,F1_LOJA "
			
			TCQUERY cQryF2+cQryF1 NEW ALIAS "QRY"
			
			lAdd := .F.
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+QRY->F2_CLIENTE+QRY->F2_LOJA)
			
			DbSelectArea("QRY")
			If Eof()
				AADD(aRejeita,{	Strzero(Val(Substr(TRB->LINHA,19,12)),9),;	// 1
				"CF SEM NF ",;                              	// 2
				" ",;                                       	// 3
				Substr(TRB->LINHA,47,15),;                  	// 4
				QRY->VALMER,;                               	// 5
				cNotas,;                                    	// 6
				QRY->CLIENTE ,;                             	// 7
				"1",;                                       	// 8
				QRY->QTE_REAL ,;                            	// 9
				QRY->PESO,;                                 	// 10
				lExistCte,;                                	// 11
				SA1->A1_MUN})	   							     	// 12 	
				lAdd := .T.
			Endif
			
			If  !lAdd .And. Val(Substr(TRB->LINHA,47,15))/100 > (QRY->CSTFR+0.01)
				AADD(aRejeita,{	Strzero(Val(Substr(TRB->LINHA,19,12)),9),; 	// 1
				"FRETE ACIMA DO VALOR",;                    	// 2
				QRY->CSTFR,;                                	// 3
				Substr(TRB->LINHA,47,15),;                  	// 4
				QRY->VALMER,;                               	// 5
				cNotas,;                                    	// 6
				QRY->CLIENTE ,;                             	// 7
				"1",;                                       	// 8
				QRY->QTE_REAL,;                             	// 9
				QRY->PESO,;                                 	// 10
				lExistCte,;                               	// 11
				SA1->A1_MUN})										// 12	
				lAdd := .T.	
			Endif		
			If  !lAdd .And. Val(Substr(TRB->LINHA,47,15))/100 < (QRY->CSTFR-0.02)
				AADD(aRejeita,{	Strzero(Val(Substr(TRB->LINHA,19,12)),9),;	// 1
				"FRETE ABAIXO DO VALOR",;                   	// 2
				QRY->CSTFR,;                                	// 3
				Substr(TRB->LINHA,47,15),;                  	// 4
				QRY->VALMER,;                               	// 5
				cNotas,;                                    	// 6
				QRY->CLIENTE ,;                             	// 7
				"1",;                                       	// 8
				QRY->QTE_REAL,;                             	// 9
				QRY->PESO,;                                 	// 10
				lExistCte,;                                	// 11
				SA1->A1_MUN})										// 12
				lAdd := .T.
			Endif
			
			
			If !lAdd
				AADD(aRejeita,{	Strzero(Val(Substr(TRB->LINHA,19,12)),9),;	// 1
				"<COMPARAÇÃO OK>",;                         	// 2
				QRY->CSTFR,;                                	// 3
				Substr(TRB->LINHA,47,15),;                  	// 4
				QRY->VALMER,;                               	// 5
				cNotas,;                                    	// 6
				QRY->CLIENTE,;                              	// 7
				"0",;                                       	// 8
				QRY->QTE_REAL,;                             	// 9
				QRY->PESO,;                                 	// 10
				lExistCte,;                                	// 11
				SA1->A1_MUN})										// 12
			Endif
			
			nValorConbrado  += Val(Substr(TRB->LINHA,47,15))/100
			nValDevido		+= QRY->CSTFR
			nValPeso		+= QRY->PESO
			nValMerc		+= QRY->VALMER
			
			QRY->(DbCloseArea())
			cQry := ""
		Endif
		
		// Processa arquivo de faturas
		If Substr(TRB->LINHA,01,03)== "351"
			//IDENTIFICADOR DE REGISTRO				N 	3	01	M	"351"
			//C.G.C.									N 	14	04	M
			//RAZÃO SOCIAL							A 	40	18	C
			//FILLER									A 	113	58	C	PREENCHER COM BRANCOS
			cCgcTransp		:= Substr(TRB->LINHA,04,14)
			
			DbSelectArea("SA4")
			DbSetOrder(3)
			If !DbSeek(xFilial("SA4")+cCgcTransp)
				MsgAlert("CNPJ informado na fatura não encontrado em cadastro de Transportadoras","Cnpj não cadastrado!")
				Return
			Endif
			dbSelectArea("TRB")
			dbSkip()
			Loop
		Endif
		
		If Substr(TRB->LINHA,01,03) == "353"
			
			// Verifica se já houve a montagem de query do cte anterior
			If !Empty(cQry)
				
				cQry += " )"
				cQry += " AND F2_FILIAL = '" + xFilial("SF2") + "' "
				cQry += "GROUP BY F2_CLIENTE,F2_LOJA "
				
				TCQUERY cQry NEW ALIAS "QRY"
				
				DbSelectArea("SA1")
				DbSetOrder(1)
				DbSeek(xFilial("SA1")+QRY->F2_CLIENTE+QRY->F2_LOJA)
			
				lAdd := .F.
				
				DbSelectArea("QRY")
				If Eof()
					AADD(aRejeita,{cNumCte,;						// 1
					"CF SEM NF ",;                              	// 2
					" ",;                                       	// 3
					cValTochar(nValCte*100),; 	                 	// 4
					QRY->VALMER,;                               	// 5
					cNotas,;                                    	// 6
					QRY->CLIENTE ,;                             	// 7
					"1",;                                       	// 8
					QRY->QTE_REAL ,;                            	// 9
					QRY->PESO,;                                 	// 10
					lExistCte,; 	                              	// 11
					SA1->A1_MUN})									// 12	
					lAdd := .T.
				Endif
				
				If  !lAdd .And. nValCte > (QRY->CSTFR+0.01)
					AADD(aRejeita,{	cNumCte,; 						// 1
					"FRETE ACIMA DO VALOR",;                    	// 2
					QRY->CSTFR,;                                	// 3
					cValTochar(nValCte*100),;                	  	// 4
					QRY->VALMER,;                               	// 5
					cNotas,;                                    	// 6
					QRY->CLIENTE ,;                             	// 7
					"1",;                                       	// 8
					QRY->QTE_REAL,;                             	// 9
					QRY->PESO,;                                 	// 10
					lExistCte,;	                             		// 11
					SA1->A1_MUN})									// 12
					lAdd := .T.
				Endif
				If  !lAdd .And. nValCte < (QRY->CSTFR-0.02)
					AADD(aRejeita,{	cNumCte,;						// 1
					"FRETE ABAIXO DO VALOR",;                   	// 2
					QRY->CSTFR,;                                	// 3
					cValTochar(nValCte*100),;                  		// 4
					QRY->VALMER,;                               	// 5
					cNotas,;                                    	// 6
					QRY->CLIENTE ,;                             	// 7
					"1",;                                       	// 8
					QRY->QTE_REAL,;                             	// 9
					QRY->PESO,;                                 	// 10
					lExistCte,;                              	  	// 11
					SA1->A1_MUN})									// 12
					lAdd := .T.
				Endif
				
				
				If !lAdd
					AADD(aRejeita,{	cNumCte,;						// 1
					"<COMPARAÇÃO OK>",;                         	// 2
					QRY->CSTFR,;                                	// 3
					cValTochar(nValCte*100),;                   	// 4
					QRY->VALMER,;                               	// 5
					cNotas,;                                    	// 6
					QRY->CLIENTE,;                              	// 7
					"0",;                                       	// 8
					QRY->QTE_REAL,;                             	// 9
					QRY->PESO,;                                 	// 10
					lExistCte,;                                		// 11
					SA1->A1_MUN})									// 12
				Endif
				
				nValDevido		+= QRY->CSTFR
				nValPeso		+= QRY->PESO
				nValMerc		+= QRY->VALMER
				
				QRY->(DbCloseArea())
				cQry := ""
				nCont354	:= 0
			Endif
			
			nValCte			:= Val(Substr(TRB->LINHA,31,15))/100
			nValorConbrado  += nValCte//Val(Substr(TRB->LINHA,47,15))/100
			
			//FILIAL EMISSORA DO DOCUMENTO			A 	10	04	M	IDENTIFICAÇÃO DA UNIDADE EMISSORA
			//SÉRIE DO CONHECIMENTO					A 	5	14	C
			//NÚMERO DO CONHECIMENTO					A 	12	19	M
			//FILLER									A 	140	31	C	PREENCHER COM BRANCOS
			
			//353001       001  000000595247000000000003450
			//12345678901234567890123456789012345678901234567890123456789
			//         1         2         3         4         5
			lExistCte	:= .F.
			cNumCte	:= StrZero(Val(Alltrim(Substr(TRB->LINHA,19,12))),nTmF1Doc)
			cQry1 := "SELECT R_E_C_N_O_ AS NRECNO "
			cQry1 += "  FROM CONDORXML "                    ///40569
			cQry1 += " WHERE XML_CHAVE LIKE '%"+cNumCte+"%' " // Numero do documento
			cQry1 += "   AND XML_CHAVE LIKE '%"+cCgcTransp+"57%' " // Concatena com 57 para identificar somente Xml´s de CTE´s
			cQry1 += "   AND XML_EMIT = '"+cCgcTransp+"' "
			
			TCQUERY cQry1 NEW ALIAS "QCOND"
			
			If !Eof()
				lExistCte := .T.
			Endif
			QCOND->(DbCloseArea())
			
			dbSelectArea("TRB")
			dbSkip()
			Loop
		Endif
		
		If Substr(TRB->LINHA,01,03) == "354"
			//IDENTIFICADOR DE REGISTRO				N 	3	01	M	"354"
			//SÉRIE									A 	3	04	C
			//NÚMERO DA NOTA FISCAL					N 	8	07	M
			//DATA DE EMISSÃO DA NOTA FISCAL		N 	8	15	M	DDMMAAAA
			//PESO DA NOTA FISCAL					N 5,2	23	M
			//VALOR DA MERCADORIA NA NOTA FISCAL	N 13,2	30	M
			//CGC DO EMISSOR DA NOTA FISCAL			N 14	45	C
			//FILLER									A 112	59	C	PREENCHER COM BRANCOS
			//3541  0002296113112014000940000000000013672806032022000543
			//3541  0002296213112014000060000000000000413406032022000543
			//123456789012345678901234567890123456789012345678901234567890
			//         1         2         3         4         5         6
			
			//353001       001  000000595248000000000003008
			//3541  0002297913112014000940000000000012165506032022000543
			nCont354++
			nConta++
			
			If nCont354 == 1
				cQry := " "
				cQry += "SELECT F2_CLIENTE||'/'||F2_LOJA || ' ' || TO_DATE(MAX(F2_EMISSAO),'YYYYMMDD') CLIENTE,"
				cQry += "       F2_CLIENTE,"
				cQry += "       F2_LOJA,"
				cQry += "       SUM(F2_CUSTOFR)AS CSTFR,"
				cQry += "       SUM(F2_VALBRUT) AS VALMER,"
				cQry += "       SUM(F2_PBRUTO) PESO, "
				cQry += "       NVL((SELECT COUNT(*) "
				cQry += "              FROM "+RetSqlName("SF2") + " B "
				cQry += "             WHERE D_E_L_E_T_ = ' ' "
				cQry += "               AND B.F2_EMISSAO IN(SELECT F2_EMISSAO "
				cQry += "                                     FROM "+ RetSqlName("SF2") + " C "
				cQry += "                                    WHERE C.D_E_L_E_T_ = ' ' "
				cQry += "                                      AND C.F2_DOC IN ('"+ StrZero(Val(Alltrim(Substr(TRB->LINHA,7,8))),IIf(cFilAnt$"07",9,6)) +"')"
				cQry += "                                      AND C.F2_FILIAL = '"+xFilial("SF2")+"') "
				cQry += "               AND B.F2_CLIENTE = A.F2_CLIENTE "
				cQry += "               AND B.F2_LOJA = A.F2_LOJA "
				cQry += "               AND B.F2_FILIAL = '"+xFilial("SF2")+"' ),0) QTE_REAL "
				cQry += "  FROM "+ RetSqlName("SF2") + " A "
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				If !Empty(Substr(TRB->LINHA,4,3))
					cQry += " AND F2_SERIE IN ('"+Substr(TRB->LINHA,4,3)+"','" + cSERIENF + "')
				Endif
				cQry += "   AND F2_DOC IN ('"+StrZero(Val(Alltrim(Substr(TRB->LINHA,7,8))),IIf(cFilAnt$"07#08",9,6))+"'"
				cNotas 	:= StrZero(Val(Alltrim(Substr(TRB->LINHA,7,8))),IIf(cFilAnt$"07#08",9,6))
			Else
				cQry += "   ,'"+StrZero(Val(Alltrim(Substr(TRB->LINHA,7,8))),IIf(cFilAnt$"07#08",9,6))+"'"
				cNotas 	+= "/"+StrZero(Val(Alltrim(Substr(TRB->LINHA,7,8))),IIf(cFilAnt$"07#08",9,6))
			Endif
		Endif
		dbSelectArea("TRB")
		dbSkip()
	End
	// Verifica se já houve a montagem de query do cte anterior
	If !Empty(cQry)
		
		cQry += " ) "
		//cQry += " AND F2_SERIE IN '2' "
		cQry += " AND F2_FILIAL = '" + xFilial("SF2") + "' "
		cQry += "GROUP BY F2_CLIENTE,F2_LOJA "
		
		TCQUERY cQry NEW ALIAS "QRY"
		
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+QRY->F2_CLIENTE+QRY->F2_LOJA)
				
		lAdd := .F.
		DbSelectArea("QRY")
		If Eof()
			AADD(aRejeita,{cNumCte,;						// 1
			"CF SEM NF ",;                              	// 2
			" ",;                                       	// 3
			cValTochar(nValCte*100),;                 	 	// 4
			QRY->VALMER,;                               	// 5
			cNotas,;                                    	// 6
			QRY->CLIENTE ,;                             	// 7
			"1",;                                       	// 8
			QRY->QTE_REAL ,;                            	// 9
			QRY->PESO,;                                 	// 10
			lExistCte,;                                		// 11
			SA1->A1_MUN})									// 12
			lAdd := .T.
		Endif
		
		If  !lAdd .And. nValCte > (QRY->CSTFR+0.01)
			AADD(aRejeita,{	cNumCte,; 						// 1
			"FRETE ACIMA DO VALOR",;                    	// 2
			QRY->CSTFR,;                                	// 3
			cValTochar(nValCte*100),;            	      	// 4
			QRY->VALMER,;                               	// 5
			cNotas,;                                    	// 6
			QRY->CLIENTE ,;                             	// 7
			"1",;                                       	// 8
			QRY->QTE_REAL,;                             	// 9
			QRY->PESO,;                                 	// 10
			lExistCte ,;                              		// 11
			SA1->A1_MUN})									// 12
			lAdd := .T.
		Endif
		If  !lAdd .And. nValCte < (QRY->CSTFR-0.02)
			AADD(aRejeita,{	cNumCte,;						// 1
			"FRETE ABAIXO DO VALOR",;                   	// 2
			QRY->CSTFR,;                                	// 3
			cValTochar(nValCte*100),;               	   	// 4
			QRY->VALMER,;                               	// 5
			cNotas,;                                    	// 6
			QRY->CLIENTE ,;                             	// 7
			"1",;                                       	// 8
			QRY->QTE_REAL,;                             	// 9
			QRY->PESO,;                                 	// 10
			lExistCte,;                              	  	// 11
			SA1->A1_MUN})									// 12
			lAdd := .T.
		Endif
		
		
		If !lAdd
			AADD(aRejeita,{	cNumCte,;						// 1
			"<COMPARAÇÃO OK>",;                         	// 2
			QRY->CSTFR,;                                	// 3
			cValTochar(nValCte*100),;                 		// 4
			QRY->VALMER,;                               	// 5
			cNotas,;                                    	// 6
			QRY->CLIENTE,;                              	// 7
			"0",;                                       	// 8
			QRY->QTE_REAL,;                             	// 9
			QRY->PESO,;                                 	// 10
			lExistCte,;                              	  	// 11
			SA1->A1_MUN})									// 12
		Endif
		
		nValCte		:= Val(Substr(TRB->LINHA,31,15))/100
		nValorConbrado  += nValCte//Val(Substr(TRB->LINHA,47,15))/100
		nValDevido		+= QRY->CSTFR
		nValPeso		+= QRY->PESO
		nValMerc		+= QRY->VALMER
		
		QRY->(DbCloseArea())
	Endif

	If len(aRejeita) > 0
		Impr()
	ElseIf nConta <= 0
		MsgInfo("Não houve leitura de registros válidos para conferência, verifique o layout!")
	Else
		MsgInfo("Nao Houveram Incosistencias","Informacao")
	Endif
	
Return

Static Function Impr()
	
	Private cDesc1  := "Este programa tem como objetivo imprimir relatorio "
	Private cDesc2  := "de acordo com os parametros informados pelo usuario."
	Private cDesc3  := "IMPORTACAO DE CONHECIMENTOS DE FRETE"
	Private cPict   := ""
	Private titulo  := "IMPORTACAO DE CONHECIMENTOS DE FRETE"
	Private nLin    := 0		
	Private Cabec1  := " No CTe     Motivo                    R$  Devido R$ Cobrado R$ Mercadoria Peso Kg % Frete Cód/Loja  Data       Cidade                        XML?   No NFe Notas Cliente "
				//		 123456     1234567890123456789012345 1234567890 1234567890 1234567890123 1234567 1234567 123456/12 12/12/1234 12345678901234678901234567890 123456 123456 123456789012345678901234567890123456789
				//		 123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890	
	Private Cabec2  := ""
	Private imprime := .T.
	Private aOrd    := {}
	
	Private lEnd        := .F.
	Private lAbortPrint := .F.
	Private CbTxt       := ""
	Private limite      := 220
	Private tamanho     := "G"
	Private nomeprog    := "BFFATR05"
	Private nTipo       := 18
	Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey    := 0
	Private cPerg       := "BFFATR05"
	Private cbtxt       := Space(10)
	Private cbcont      := 00
	Private CONTFL      := 01
	Private m_pag       := 01
	Private wnrel       := "BFFATR05"
	Private cString     := "SE1"
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta a interface padrao com o usuario...                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	wnrel := SetPrint(,NomeProg,,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)
	
	If nLastKey == 27
		Return
	Endif
	
	SetDefault(aReturn,)
	
	If nLastKey == 27
		Return
	Endif
	
	nTipo := If(aReturn[4]==1,15,18)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
Return


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFun‡„o    ³RUNREPORT º Autor ³ AP6 IDE            º Data ³  10/02/03   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS º±±
±±º          ³ monta a janela com a regua de processamento.               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Programa principal                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)
	Local _pedido := ""
	Local _flg    := ""
	Local nFlg    := 0
	Local lRodape :=  .F.
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica o cancelamento pelo usuario...                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		//	Exit
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Impressao do cabecalho do relatorio. . .                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	nLin := Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	
	aSort(aRejeita,,,{|x,y| x[8]+x[7]+x[1] < y[8]+y[7]+y[1]})
	dbSelectArea("SA4")
	dbSetOrder(2)
	nLin++
	@nLin,000 PSAY " CÓDIGO: " + SA4->A4_COD + " TRANSFORTADORA: " + SA4->A4_NOME
	nLin++
	
	For x:= 1 to len(aRejeita)
		             
		@nLin,001 Psay aRejeita[x,1]
		@nLin,012 Psay Substr(aRejeita[x,2],1,25)
		@nLin,038 Psay Transform(aRejeita[x,3],"@E 999,999.99")
		@nLin,049 Psay Transform(Val(aRejeita[x,4])/100,"@E 999,999.99")
		@nLin,062 Psay Transform(aRejeita[x,5],"@E 99,999,999.99")
		@nLin,074 Psay Transform(aRejeita[x,10],"@E 999,999")
		@nLin,082 Psay Transform(Round(Val(aRejeita[x,4])/aRejeita[x,5],2),"@E 999.99%" )
		@nLin,090 Psay Substr(aRejeita[x,7],1,9)
		@nLin,100 Psay DTOC(STOD(Substr(aRejeita[x,7],11,8)))
		@nLin,111 Psay Substr(aRejeita[x,12],1,30)
		@nLin,141 Psay Iif(aRejeita[x,11],"XML OK","      ")
		@nLin,148 Psay aRejeita[x,9]
		// A1_MUN C(30)
		@nLin,155 Psay aRejeita[x,6]
		
		nLin++
		
		If nLin > 60 // Salto de Página. Neste caso o formulario tem 55 linhas...
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 8
		Endif
	Next
	nLin++
	@nLin,001 Psay "Número CTRC's: " + Transform(nConta,"@E 999")
	nLin++
	@nLin,001 Psay "Valor Devido : " + Transform(nValDevido,"@E 999,999.99")
	nLin++
	@nLin,001 Psay "Valor Cobrado: " + Transform(nValorConbrado,"@E 999,999.99")
	nLin++
	@nLin,001 Psay Replicate("-",80)
	nLin++
	@nLin,001 Psay "Diferença    : " + Transform(nValDevido-nValorConbrado,"@E 999,999.99")
	
	nLin++
	@nLin,001 Psay Replicate("-",80)
	nLin++
	@nLin,001 Psay "Valor Merc.  : " + Transform(nValMerc,"@E 999,999,999.99")
	nLin++
	@nLin,001 Psay "Peso KG      : " + Transform(nValPeso,"@E 999,999,999.99")
	nLin++
	@nLin,001 Psay "%Méd.Frete Cobrado: " + Transform(nValorConbrado / nValMerc * 100,"@E 99,999.99")
	
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a execucao do relatorio...                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	SET DEVICE TO SCREEN
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se impressao em disco, chama o gerenciador de impressao...          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif
	
	MS_FLUSH()
	
Return




Static Function sfGrvTbl()
	
	Local	cQry3	:= ""
	Local	cQry2	:= ""
	Local	cQry1 	:= "INSERT INTO BIGFORTA.CONDOR_LOG_EDI_TRANSP(	 CET_FILEMI,"+;	//	CHAR(10)
	"CET_SERIE,"+;	//	CHAR(5)
	"CET_NUM,"+;	//	CHAR(12)
	"CET_EMISSA,"+;	//	CHAR(8)
	"CET_CONDFR,"+;	//	CHAR(1)
	"CET_PESO,"+;	//	NUMBER
	"CET_VALFRE,"+;	//	NUMBER
	"CET_BASICM,"+;	//	NUMBER
	"CET_PICM,"+;	//	NUMBER
	"CET_VALICM,"+;	//	NUMBER
	"CET_FRPESO,"+;	//	NUMBER
	"CET_FRVLR,"+;	//	NUMBER
	"CET_SECCAT,"+;	//	NUMBER
	"CET_ITR,"+;	//		NUMBER
	"CET_DESPAC,"+;	//	NUMBER
	"CET_PEDAGI,"+;	//	NUMBER
	"CET_ADEME,"+;	//	NUMBER
	"CET_ST,"+;	//		CHAR(1)
	"CET_NATOPE,"+;	//	CHAR(3)
	"CET_CGCEMI,"+;	//	CHAR(14)
	"CET_CGCEMB,"+;	//	CHAR(14)
	"CET_SERNF1,"+;	//	CHAR(3)
	"CET_NUMNF1,"+;	//	CHAR(8)
	"CET_SERNF2,"+;	//	CHAR(3)
	"CET_NUMNF2,"+;	//	CHAR(8)
	"CET_SERNF3,"+;	//	CHAR(3)
	"CET_NUMNF3,"+;	//	CHAR(8)
	"CET_SERNF4,"+;	//	CHAR(3)
	"CET_NUMNF4,"+;	//	CHAR(8)
	"CET_SERNF5,"+;	//	CHAR(3)
	"CET_NUMNF5,"+;	//	CHAR(8)
	"CET_SERNF6,"+;	//	CHAR(3)
	"CET_NUMNF6,"+;	//	CHAR(8)
	"CET_ACAODC)VALUES "	//	CHAR(1)
	
	// Executa a verificação se a tabela de log já existe
	sfCreatTbl()
	
	DbSelectArea("TRB")
	DbGoTop()
	While !Eof()
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Incrementa a regua                                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		
		IncProc("Gravando Log: "+Substr(TRB->LINHA,25,06))
		
		If Substr(TRB->LINHA,01,03) == "322"
			cQry3 := "SELECT COUNT(*) NREG "
			cQry3 += "  FROM BIGFORTA.CONDOR_LOG_EDI_TRANSP	"
			cQry3 += " WHERE CET_CGCEMI = '"+Substr(TRB->LINHA,205,14)+"' "
			cQry3 += "   AND CET_CGCEMB = '"+Substr(TRB->LINHA,219,14)+"' "
			cQry3 += "   AND CET_SERIE = '"+Substr(TRB->LINHA,14,5)+"' "
			cQry3 += "	 AND CET_NUM = '"+Substr(TRB->LINHA,19,12)+"' "
			
			TCQUERY cQry3 NEW ALIAS "QRREG"
			
			If QRREG->NREG == 0
				
				cQry2 := ""
				//No	CAMPO	FORMATO	POSIÇÃO	STATUS	NOTAS
				//1.		IDENTIFICADOR DE REGISTRO	N 3	001	M	"322"
				
				//2.		FILIAL EMISSORA DO CONHECIMENTO	A 10	004	C
				cQry2	+= "('"+Substr(TRB->LINHA,4,10) +"',"
				//3.		SÉRIE DO CONHECIMENTO	A 5	014	C
				cQry2   += "'"+Substr(TRB->LINHA,14,5)+"',"
				//4.		NÚMERO DO CONHECIMENTO	A 12	019	M
				cQry2   += "'"+Substr(TRB->LINHA,19,12)+"',"
				//5.		DATA DE EMISSÃO	N 8	031	M	DDMMAAAA
				cQry2   += "'"+Substr(TRB->LINHA,31,8)+"',"
				//6.		CONDIÇÃO DE FRETE	A 1	039	M	C = CIF; F = FOB
				cQry2   += "'"+Substr(TRB->LINHA,39,1)+"',"
				//7.		PESO TRANSPORTADO	N 5,2	040	M
				cQry2   +=  Str(Val(Substr(TRB->LINHA,40,7))/100)+","
				//8.		VALOR TOTAL DO FRETE	N 13,2	047	M
				cQry2   +=  Str(Val(Substr(TRB->LINHA,47,15))/100)+","
				//9.		BASE DE CÁLCULO PARA APURAÇÃO ICMS	N 13,2	062	M
				cQry2   +=  Str(Val(Substr(TRB->LINHA,62,15))/100)+","
				//10.		% DE TAXA DO ICMS	N 2,2	077	M
				cQry2   +=  Str(Val(Substr(TRB->LINHA,77,4))/100)+","
				//11.		VALOR DO ICMS	N 13,2	081	M
				cQry2   +=  Str(Val(Substr(TRB->LINHA,81,15))/100)+","
				//12.		VALOR DO FRETE POR PESO/VOLUME	N 13,2	096	M
				cQry2   +=  Str(Val(Substr(TRB->LINHA,96,15))/100)+","
				//13.		FRETE VALOR	N 13,2	111	M
				cQry2   +=  Str(Val(Substr(TRB->LINHA,111,15))/100)+","
				//14.		VALOR SEC - CAT	N 13,2	126	C
				cQry2   +=  Str(Val(Substr(TRB->LINHA,126,15))/100)+","
				//15.		VALOR ITR	N 13,2	141	C
				cQry2   +=  Str(Val(Substr(TRB->LINHA,141,15))/100)+","
				//16.		VALOR DO DESPACHO	N 13,2	156	C
				cQry2   +=  Str(Val(Substr(TRB->LINHA,156,15))/100)+","
				
				//No	CAMPO	FORMATO	POSIÇÃO	STATUS	NOTAS
				//17.		VALOR DO PEDÁGIO	N 13,2	171	C
				cQry2   +=  Str(Val(Substr(TRB->LINHA,171,15))/100)+","
				//18.		VALOR ADEME	N 13,2	186	C
				cQry2   +=  Str(Val(Substr(TRB->LINHA,186,15))/100)+","
				//19.		SUBSTITUIÇÃO TRIBUTÁRIA?	N 1	201	M	1 = SIM; 2 = NÃO
				cQry2   += "'"+Substr(TRB->LINHA,201,1)+"',"
				//20.		NATUREZA DE OPERAÇÃO	N 3	202	M
				cQry2   += "'"+Substr(TRB->LINHA,202,3)+"',"
				//21.		C.G.C. DO EMISSOR DO CONHECIMENTO	N 14	205	M	SEM PONTOS E BARRA
				cQry2   += "'"+Substr(TRB->LINHA,205,14)+"',"
				//22.		C.G.C. DA EMBARCADORA	N 14	219	M	SEM PONTOS E BARRA
				cQry2   += "'"+Substr(TRB->LINHA,219,14)+"',"
				//NOTAS COMPONENTES DO CONHECIMENTO  -  ATÉ 40 OCORRÊNCIAS DE DADOS DE NOTAS
				//23.		SÉRIE DA NOTA FISCAL - 1	A 3	233	C
				cQry2   += "'"+Substr(TRB->LINHA,233,3)+"',"
				//24.		NÚMERO DA NOTA FISCAL - 1	N 8	236	M
				cQry2   += "'"+Substr(TRB->LINHA,236,8)+"',"
				//25.		SÉRIE DA NOTA FISCAL - 2	A 3	244	C
				cQry2   += "'"+Substr(TRB->LINHA,244,3)+"',"
				//26.		NÚMERO DA NOTA FISCAL - 2	N 8	247	C
				cQry2   += "'"+Substr(TRB->LINHA,247,8)+"',"
				//27.		SÉRIE DA NOTA FISCAL - 3	A 3	255	C
				cQry2   += "'"+Substr(TRB->LINHA,255,3)+"',"
				//28.		NÚMERO DA NOTA FISCAL - 3	N 8	258	C
				cQry2   += "'"+Substr(TRB->LINHA,258,8)+"',"
				//29.		SÉRIE DA NOTA FISCAL - 4	A 3	266	C
				cQry2   += "'"+Substr(TRB->LINHA,266,3)+"',"
				//30.		NÚMERO DA NOTA FISCAL - 4	N 8	269	C
				cQry2   += "'"+Substr(TRB->LINHA,269,8)+"',"
				//31.		SÉRIE DA NOTA FISCAL - 5	A 3	277	C
				cQry2   += "'"+Substr(TRB->LINHA,277,3)+"',"
				//101.		NÚMERO DA NOTA FISCAL - 5	N 8	280	C
				cQry2   += "'"+Substr(TRB->LINHA,280,8)+"',"
				//102.		SÉRIE DA NOTA FISCAL - 6	A 3	288	C
				cQry2   += "'"+Substr(TRB->LINHA,288,3)+"',"
				//103.		NÚMERO DA NOTA FISCAL - 6	N 8	291	C
				cQry2   += "'"+Substr(TRB->LINHA,291,8)+"',"
				//104.		AÇÃO DO DOCUMENTO	A 1	673	C	I = INCLUIR;C = COMPLEMENTAR eE = EXCLUIR
				//105.		TIPO DO CONHECIMENTO	A 1	674	C	N = NORMAL eC = COMPLEMENTARE = Normal EntradaS = Normal SaídaT = Normal de Transferencia internaX = Complementar de entrada
				//Y = Complementar de Saída
				//Z = Complementar de Transfer. Interna
				//D = Complementar de Devolução
				//R = Complementar de Reentrega
				cQry2   += "'"+Substr(TRB->LINHA,674,1)+"')"
				
				
				TCSQLEXEC(cQry1+cQry2)
			Endif
			QRREG->(DbCloseArea())
		Endif
		DbSelectArea("TRB")
		DbSkip()
	Enddo
	
Return

Static Function sfCreatTbl
	
	Local	cQry	:= ""
	
	cQry := "SELECT NVL(COUNT(*),0) NREG "
	cQry += "  FROM USER_TABLES "
	cQry += " WHERE TABLE_NAME = 'CONDOR_LOG_EDI_TRANSP' "
	
	TCQUERY cQry NEW ALIAS "QRLG"
	
	If QRLG->NREG == 0
		cQry := 'CREATE TABLE "BIGFORTA"."CONDOR_LOG_EDI_TRANSP" '
		cQry += '	("CET_FILEMI" 	CHAR(10) NOT NULL,'
		cQry += '	"CET_SERIE"		CHAR(5) NOT NULL,'
		cQry += '	"CET_NUM" 		CHAR(12) NOT NULL,'
		cQry += '	"CET_EMISSA"	CHAR(8) NOT NULL,'
		cQry += '	"CET_CONDFR" 	CHAR(1) NOT NULL,'
		cQry += '	"CET_PESO"		NUMBER NOT NULL,'
		cQry += '	"CET_VALFRE"	NUMBER NOT NULL,'
		cQry += '	"CET_BASICM" 	NUMBER NOT NULL,'
		cQry += '	"CET_PICM"	 	NUMBER NOT NULL,'
		cQry += '	"CET_VALICM"	NUMBER NOT NULL,'
		cQry += '	"CET_FRPESO" 	NUMBER NOT NULL,'
		cQry += '	"CET_FRVLR" 	NUMBER NOT NULL,'
		cQry += '	"CET_SECCAT"	NUMBER NOT NULL,'
		cQry += '	"CET_ITR" 		NUMBER NOT NULL,'
		cQry += '	"CET_DESPAC" 	NUMBER NOT NULL,'
		cQry += '	"CET_PEDAGI" 	NUMBER NOT NULL,'
		cQry += '	"CET_ADEME" 	NUMBER NOT NULL,'
		cQry += '	"CET_ST" 		CHAR(1) NOT NULL,'
		cQry += '	"CET_NATOPE" 	CHAR(3) NOT NULL,'
		cQry += '	"CET_CGCEMI" 	CHAR(14) NOT NULL,'
		cQry += '	"CET_CGCEMB" 	CHAR(14) NOT NULL,'
		cQry += '	"CET_SERNF1" 	CHAR(3) NOT NULL,'
		cQry += '	"CET_NUMNF1" 	CHAR(8) NOT NULL,'
		cQry += '	"CET_SERNF2" 	CHAR(3) NOT NULL,'
		cQry += '	"CET_NUMNF2" 	CHAR(8) NOT NULL,'
		cQry += '	"CET_SERNF3" 	CHAR(3) NOT NULL,'
		cQry += '	"CET_NUMNF3" 	CHAR(8) NOT NULL,'
		cQry += '	"CET_SERNF4" 	CHAR(3) NOT NULL,'
		cQry += '	"CET_NUMNF4" 	CHAR(8) NOT NULL,'
		cQry += '	"CET_SERNF5" 	CHAR(3) NOT NULL,'
		cQry += '	"CET_NUMNF5" 	CHAR(8) NOT NULL,'
		cQry += '	"CET_SERNF6" 	CHAR(3) NOT NULL,'
		cQry += '	"CET_NUMNF6" 	CHAR(8) NOT NULL,'
		cQry += '	"CET_ACAODC" 	CHAR(1) NOT NULL)'
		cQry += '    TABLESPACE "BIG_D" '
		TcSQLExec(cQry)
		
		cQry := 'CREATE INDEX BIGFORTA.CONDOR_LOG_EDI_TRANSP_IDX ON "BIGFORTA"."CONDOR_LOG_EDI_TRANSP" (CET_CGCEMI,CET_CGCEMB,CET_SERIE,CET_NUM) '
		
		TcSQLExec(cQry)
		
	Endif
	QRLG->(DbCloseArea())
	
	
