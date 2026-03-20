#Include 'Protheus.ch'
#DEFINE MAXGETDAD 4096
#DEFINE MAXSAVERESULT 4096

/*/{Protheus.doc} BFFATA39
(long_description)
@author MarceloLauschner
@since 18/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA39()
	
	Private cCadastro := OemToAnsi("Manutencao das Regras de Combos - Bonificação")
	Private aRotina   := MenuDef()
	
	
	// Endereca para a funcao MBrowse
	
	DbSelectArea("ACQ")
	DbSetOrder(1)
	MsSeek(xFilial("ACQ"))
	
	mBrowse(06,01,22,75,"ACQ")
	
	// Restaura a Integridade da Rotina
	
	DbSelectArea("ACQ")
	DbSetOrder(1)
	DbClearFilter()
	
Return


/*/{Protheus.doc} BFFATA40
(long_description)
@author MarceloLauschner
@since 18/09/2014
@version 1.0
@param cAlias, character, (Descrição do parâmetro)
@param nReg, numérico, (Descrição do parâmetro)
@param nOpc, numérico, (Descrição do parâmetro)
@param xPar, variável, (Descrição do parâmetro)
@param lCopia, ${param_type}, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA40(cAlias,nReg,nOpc,xPar,lCopia)
	
	Local aArea     	:= GetArea()
	Local aPosObj   	:= {}
	Local aObjects  	:= {}
	Local aSize     	:= {}
	Local aInfo     	:= {}
	Local nUsado    	:= 0
	Local nX        	:= 0
	Local nOpcA     	:= 0
	Local nSaveSx8  	:= GetSx8Len()
	Local lContinua 	:= .T.
	Local lGrade 		:= ACR->(FieldPos("ACR_ITEMGR")) > 0 .And. MaGrade()
	
	Local oDlg
	Local cSeek  		:= Nil
	Local cWhile 		:=	Nil
	
	Private oGrade 	:= MsMatGrade():New("oGrade",,"ACR_LOTE",,".T.",,{{"ACR_LOTE",.T. ,,.T. }})
	Private oGetD
	Private aHeader 	:= {}
	Private aCols   	:= {}
	Private aTELA[0][0],aGETS[0]
	
	DEFAULT INCLUI := .F.
	DEFAULT lCopia := .F.
	
	nOper := aRotina[ nOpc, 4 ]
	
	INCLUI := ( nOper == 3 .And. !lCopia )
	
	
	// Inicializa as variaveis da Enchoice                                     
	
	If INCLUI
		RegToMemory( "ACQ", .T., .F. )
	EndIf
	
	If !INCLUI
		If SoftLock("ACQ")
			RegToMemory( "ACQ", .F., .F. )
		Else
			lContinua := .F.
		EndIf
	EndIf
	
	If lContinua
		
		cSeek  := xFilial("ACR")+M->ACQ_CODREG
		cWhile := "ACR->ACR_FILIAL + ACR->ACR_CODREG"
		
		FillGetDados(	nOpc , "ACR", 1, cSeek ,;
			{||&(cWhile)}, {|| Iif (ACR->ACR_FILIAL + ACR->ACR_CODREG==xFilial("ACR")+M->ACQ_CODREG,.T.,.F.) }, /*aNoFields*/,;
			/*aYesFields*/, /*lOnlyYes*/,/* cQuery*/, /*bMontAcols*/, IIf(nOpc<>3,.F.,.T.),;
			/*aHeaderAux*/, /*aColsAux*/,{|| Fat090Item()} , /*bBeforeCols*/,;
			/*bAfterHeader*/, /*cAliasQry*/)
		
		If lGrade
			aCols := aColsGrade(oGrade,aCols,aHeader,"ACR_CODPRO","ACR_ITEM","ACR_ITEMGR",aScan(aHeader,{|x| AllTrim(x[2]) == "ACR_DESPRO"}))
		EndIf
		
		dbSelectArea( "ACQ" )
		If lCopia
			M->ACQ_CODREG := CriaVar("ACQ_CODREG",.T.)
		EndIf
		
		
		dbSelectArea("ACR")
		
		
		// Faz o calculo automatico de dimensoes de objetos     
		
		aSize := MsAdvSize()
		AAdd( aObjects, { 100, 100, .T., .T. } )
		AAdd( aObjects, { 200, 200, .T., .T. } )
		aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 5, 5 }
		aPosObj := MsObjSize( aInfo, aObjects,.T.)
		
		DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],0 To aSize[6],aSize[5] of oMainWnd PIXEL
		EnChoice( "ACQ", nReg, nOpc,,,,,aPosObj[1], , 3, , , , , ,.F. )
		//MsGetDados(): New ( < nTop>, < nLeft>, < nBottom>, < nRight>, < nOpc>, [ cLinhaOk], [ cTudoOk], [ cIniCpos], [ lDeleta], [ aAlter], [ nFreeze], [ lEmpty], [ nMax], [ cFieldOk], [ cSuperDel], [ uPar], [ cDelOk], [ oWnd], [ lUseFreeze], [ cTela] ) --> oGetDados
		oGetD := MsGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],nOpc,"U_BFFATA41()","U_BFFATA42()","+ACR_ITEM",(nOper==4 .Or. nOper==3),,1,,MAXGETDAD,"U_BFATA39A()",,,"U_BFATA39D()")
		ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpcA := 1,If(oGetd:TudoOk(),If(!Obrigatorio(aGets,aTela),nOpcA := 0,oDlg:End()),nOpcA := 0)},{||oDlg:End()})
		
		//Rotina de Gravacao da Tabela de preco                         
		If nOpcA == 1 .And. nOpc > 2
			Begin Transaction
				If lGrade
					aCols := aGradeCols(oGrade,aCols,aHeader,"ACR_CODPRO","ACR_ITEMGR","ACR_LOTE","ACR_ITEM")
				EndIf
				Ft090Grv(nOpc-2,lCopia)
				While (Getsx8Len() > nSaveSx8)
					ConfirmSx8()
				EndDo
				EvalTrigger()
			End Transaction
		EndIf
	EndIf
	 //Restaura a entrada da Rotina                                  
	While (GetSx8Len() > nSaveSx8)
		RollBackSxE()
	EndDo
	MsUnLockAll()
	FreeUsedCode()
	RestArea(aArea)
	
Return(nOpcA)

User Function BFFATA41()
	
	Local aArea     	:= GetArea()
	Local lRetorno  	:= .T.
	Local nPProd    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_CODPRO"})
	Local nPOper    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_OPER"})
	Local nUsado    	:= Len(aHeader)
	Local nPCompKit		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_PRCFIX"})
	Local nPQte			:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_QUANT"})
	Local nPPrcVen		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_XPRCVE"})
	Local nPPerc		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_LOTE"})
	Local nX        	:= 0
	Local nTotPerc		:= 0
	Local nValCombo		:= 0
	
	For nX := 1 To Len(aCols)
		If !aCols[nX][nUsado+1]
			If aCols[nX,nPCompKit] == "1"
				nValCombo	+= aCols[nX,nPQte] * aCols[nX,nPPrcVen]
			Endif
		EndIf
	Next nX
	
	M->ACQ_LOTE	:=  nValCombo
				
	If !aCols[n][nUsado+1]
		Do Case
			Case nPProd == 0
				lRetorno := .F.
				Help(" ",1,"OBRIGAT",,RetTitle("ACR_CODPRO"),4)
			Case Empty(aCols[n][nPProd])
				lRetorno := .F.
				Help(" ",1,"OBRIGAT",,RetTitle("ACR_CODPRO"),4)
			OtherWise
			
		EndCase
		//Verifica se nao ha valores duplicados                                   
		
		If lRetorno
			If nPProd <> 0
				For nX := 1 To Len(aCols)
					If !aCols[nX][nUsado+1]
						If aCols[nX,nPCompKit] == "1"
							aCols[nX,nPPerc]	:= Round(aCols[nX,nPQte] * aCols[nX,nPPrcVen] / nValCombo * 100,6)
						Endif
						
						If nX <> N 
							If ( aCols[nX][nPProd]+aCols[nX][nPOper]==aCols[N][nPProd]+aCols[N][nPOper] )
								lRetorno := .F.
								Help(" ",1,"JAGRAVADO")
							EndIf
						EndIf
					Endif
				Next nX
			EndIf
		EndIf
	EndIf
	RestArea(aArea)
	oGetD:oBrowse:Refresh()
	
Return(lRetorno)

User Function BFFATA42()
	
	Local lRetorno 		:= .T.
	Local nX        	:= 0	
	Local nPProd    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_CODPRO"})
	Local nPOper    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_OPER"})
	Local nUsado    	:= Len(aHeader)
	Local nPCompKit		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_PRCFIX"})
	Local nPQte			:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_QUANT"})
	Local nPPrcVen		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_XPRCVE"})
	Local nPPerc		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_LOTE"})
	
	
	For nX := 1 To Len(aCols)
		If nX <> N .And. !aCols[nX][nUsado+1]
			If ( aCols[nX][nPProd]+aCols[nX][nPOper]==aCols[N][nPProd]+aCols[N][nPOper] )
				lRetorno := .F.
				Help(" ",1,"JAGRAVADO")
			EndIf
		EndIf
	Next nX
	
Return(lRetorno)

User Function BFATA39A()

	Local lRetorno		:= .T.
	Local cReadVar		:= ReadVar()
	Local aArea     	:= GetArea()
	Local lRetorno  	:= .T.
	Local nPProd    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_CODPRO"})
	Local nPOper    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_OPER"})
	Local nUsado    	:= Len(aHeader)
	Local nPCompKit		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_PRCFIX"})
	Local nPQte			:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_QUANT"})
	Local nPPrcVen		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_XPRCVE"})
	Local nPPerc		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_LOTE"})
	Local nX        	:= 0
	Local nTotPerc		:= 0
	Local nValCombo		:= 0
	
	If !(cReadVar $ "M->ACR_QUANT#M->ACR_XPRCVE")
		Return lRetorno
	Endif
	
	If cReadVar == "M->ACR_QUANT"
		aCols[n][nPQte]	:= M->ACR_QUANT
	Endif
	
	If cReadVar == "M->ACR_XPRCVE"
		aCols[n][nPPrcVen]	:= M->ACR_XPRCVE
	Endif
	
	For nX := 1 To Len(aCols)
		If !aCols[nX][nUsado+1]
			If aCols[nX,nPCompKit] == "1"
				nValCombo	+= aCols[nX,nPQte] * aCols[nX,nPPrcVen]
			Endif
		EndIf
	Next nX
	
	M->ACQ_LOTE	:=  nValCombo
				
	If !aCols[n][nUsado+1]
		
		For nX := 1 To Len(aCols)
			If !aCols[nX][nUsado+1]
				If aCols[nX,nPCompKit] == "1"
					aCols[nX,nPPerc]	:= Round(aCols[nX,nPQte] * aCols[nX,nPPrcVen] / nValCombo * 100,6)
				Endif
						
				If nX <> N 
					If ( aCols[nX][nPProd]+aCols[nX][nPOper]==aCols[N][nPProd]+aCols[N][nPOper] )
						lRetorno := .F.
						Help(" ",1,"JAGRAVADO")
					EndIf
				EndIf
			Endif
		Next nX
	EndIf
	RestArea(aArea)
	oGetD:oBrowse:Refresh()
	
	
Return lRetorno

User Function BFATA39D()

	Local	lRetorno	:= .T.
	Local aArea     	:= GetArea()
	Local lRetorno  	:= .T.
	Local nPProd    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_CODPRO"})
	Local nPOper    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_OPER"})
	Local nUsado    	:= Len(aHeader)
	Local nPCompKit		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_PRCFIX"})
	Local nPQte			:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_QUANT"})
	Local nPPrcVen		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_XPRCVE"})
	Local nPPerc		:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_LOTE"})
	Local nX        	:= 0
	Local nTotPerc		:= 0
	Local nValCombo		:= 0
	
	For nX := 1 To Len(aCols)
		If !aCols[nX][nUsado+1]
			If aCols[nX,nPCompKit] == "1"
				nValCombo	+= aCols[nX,nPQte] * aCols[nX,nPPrcVen]
			Endif
		EndIf
	Next nX
	
	M->ACQ_LOTE	:=  nValCombo
				
	For nX := 1 To Len(aCols)
		If !aCols[nX][nUsado+1]
			If aCols[nX,nPCompKit] == "1"
				aCols[nX,nPPerc]	:= Round(aCols[nX,nPQte] * aCols[nX,nPPrcVen] / nValCombo * 100,6)
			Endif
		Endif
	Next nX
	
	RestArea(aArea)
	oGetD:oBrowse:Refresh()
	
Return lRetorno

Static Function Fat090Item()

	Local nX := 0

	If Len(aCols) == 1
		For nX := 1 To Len(aHeader)
			If AllTrim(aHeader[nX,2]) == "ACR_ITEM"
				Acols[Len(Acols)][nX] := StrZero(1,Len(ACR->ACR_ITEM))
			EndIf
		Next nX
	EndIf

Return(.T.)


Static Function Ft090Grv(nOpcao,lCopia)
	
	Local aArea     	:= GetArea()
	Local lGravou   	:= .F.
	Local aRegNo    	:= {}
	Local nPProd    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_CODPRO"})
	Local nPLote    	:= aScan(aHeader,{|x| AllTrim(x[2])=="ACR_LOTE"})
	Local nX        	:= 0
	Local nY        	:= 0
	Local nUsado    	:= Len(aHeader)
	Local bCampo 		:= {|nCPO| Field(nCPO) }
	Local cItem     	:= Repl("0",Len(ACR->ACR_ITEM))
	Local cProcesCab 	:= "023"												//Codigo do processo que sera utilizado para enviar a tabela ACQ
	Local cProcesIte 	:= "024"												//Codigo do processo que sera utilizado para enviar a tabela ACR
	Local cChaveCab	:=	""								   					//Chave utilizada na busca
	Local cChaveIte	:= ""													//Chave utilizada na busca
	Local cTabelaCab 	:= "ACQ"												//Tabela enviada no processo Off-line
	Local cTabelaIte 	:= "ACR"												//Tabela enviada no processo Off-line
	
	If nPProd > 0 .And. nPLote  > 0
		aCols := aSort(aCols,,,{|x,y| x[nPProd]+StrZero(x[nPLote ],18,2) < y[nPProd]+StrZero(y[nPLote ],18,2)})
	EndIf
	
	Do Case
	Case nOpcao <> 3
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Grava o Cabecalho                                             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("ACQ")
		dbSetOrder(1)
		If MsSeek(xFilial("ACQ")+M->ACQ_CODREG)
			RecLock("ACQ",.F.)
		Else
			RecLock("ACQ",.T.)
		EndIf
		For nX := 1 TO FCount()
			FieldPut(nX,M->&(EVAL(bCampo,nX)))
		Next nX
		ACQ->ACQ_FILIAL := xFilial("ACQ")
		MsUnLock()
		
		//Insere o registro na integracao
		If FindFunction("Om010CabOk")
			cChaveCab:= xFilial("ACQ") + ACQ->ACQ_CODREG
			Om010CabOk(cProcesCab, cChaveCab, cTabelaCab)
		Endif
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Guarda os registro para reaproveita-los                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("ACR")
		dbSetOrder(1)
		MsSeek(xFilial("ACR")+M->ACQ_CODREG)
		While ( !Eof() .And. xFilial("ACR") == ACR->ACR_FILIAL .And. M->ACQ_CODREG == ACR->ACR_CODREG )
			aAdd(aRegNo,RecNo())
			dbSelectArea("ACR")
			dbSkip()
		EndDo
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Grava os itens                                                ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nX := 1 To Len(aCols)
			If !lCopia .And. !Empty(aCols[nX,nUsado])
				dbSelectArea("ACR")
				dbGoto(aCols[nX,nUsado])
				RecLock("ACR")
				nY := aScan(aRegNo,{|x| x == aCols[nX,nUsado]})
				aDel(aRegNo,nY)
				aSize(aRegNo,Len(aRegNo)-1)
			ElseIf !aCols[nX][nUsado+1]
				RecLock("ACR",.T.)
			EndIf
			If (!aCols[nX][nUsado+1])
				For nY := 1 to Len(aHeader)
					If aHeader[nY][10] <> "V"
						ACR->(FieldPut(FieldPos(aHeader[nY][2]),aCols[nX][nY]))
					EndIf
				Next nY
				ACR->ACR_FILIAL := xFilial("ACR")
				ACR->ACR_CODREG := M->ACQ_CODREG
				lGravou := .T.
			ElseIf !lCopia .And. !Empty(aCols[nX][nUsado])
				ACR->(dbDelete())
			EndIf
			MsUnLock()
			
			//Insere o registro na integracao
			If FindFunction("Om010IteOk")
				cChaveIte:= xFilial("ACR") + ACR->ACR_CODREG + ACR->ACR_ITEM
				Om010IteOk(cProcesIte, cChaveIte, cTabelaIte, nX, nUsado)
			EndIf
			
		Next nX
		dbSelectArea("ACR")
		//Deleta registros alterados por outro produto
		For nX := 1 To Len(aRegNo)
			dbGoto(aRegNo[nX])
			RecLock("ACR",.F.)
			dbDelete()
			MsUnLock()
		Next nX
	Case nOpcao == 3
		dbSelectArea("ACR")
		dbSetOrder(1)
		MsSeek(xFilial("ACR")+M->ACQ_CODREG)
		While ( !Eof() .And. xFilial("ACR") == ACR->ACR_FILIAL .And. M->ACQ_CODREG == ACR->ACR_CODREG )
			RecLock("ACR")
			dbDelete()
			
			//Insere o registro na integracao
			If FindFunction("Om010IteOk")
				cChaveIte:= xFilial("ACR") + ACR->ACR_CODREG + ACR->ACR_ITEM
				Om010IteOk(cProcesIte, cChaveIte, cTabelaIte, nX, nUsado)
			EndIf
			
			MsUnLock()
			dbSelectArea("ACR")
			dbSkip()
		EndDo
		dbSelectArea("ACQ")
		dbSetOrder(1)
		If MsSeek(xFilial("ACQ")+M->ACQ_CODREG)
			RecLock("ACQ")
			dbDelete()
			
			//Insere o registro na integracao
			If FindFunction("Om010CabOk")
				cChaveCab:= xFilial("ACQ") + ACQ->ACQ_CODREG
				Om010CabOk(cProcesCab, cChaveCab, cTabelaCab)
			EndIf
			
			MsUnLock()
		EndIf
	OtherWise
	 
	EndCase
Return(lGravou)


Static Function MenuDef()
	
	aRotina := {	{ OemToAnsi("Pesquisar"),"AxPesqui"	,0,1,0,.F.},;	  			//"Pesquisar"
	{ OemToAnsi("Visualizar"),"U_BFFATA40" ,0,2,0,NIL},;	//"Visualizar"
	{ OemToAnsi("Incluir"),"U_BFFATA40" ,0,3,0,NIL},;	//"Incluir"
	{ OemToAnsi("Alterar"),"U_BFFATA40" ,0,4,0,NIL},;	//"Alterar"
	{ OemToAnsi("Excluir"),"U_BFFATA40" ,0,5,0,NIL},;	//"Excluir"
	{ OemToAnsi("Copiar"),"U_BFFATA44",0,3,0,NIL}}		//"Copiar"
	
Return(aRotina)


/*/{Protheus.doc} BFFATA44
(long_description)
@author MarceloLauschner
@since 22/09/2014
@version 1.0
@param cAlias, character, (Descrição do parâmetro)
@param nReg, numérico, (Descrição do parâmetro)
@param nOpc, numérico, (Descrição do parâmetro)
@param xPar, variável, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
			User Function BFFATA44(cAlias,nReg,nOpc,xPar)

		Return U_BFFATA40(cAlias,nReg,nOpc,xPar,.T. /*lCopia*/)




