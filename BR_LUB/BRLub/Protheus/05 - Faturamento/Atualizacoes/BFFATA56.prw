#Include 'Protheus.ch'

User Function DIS154()
	
Return U_BFFATA56()


/*/{Protheus.doc} BFFATA56
(Auxilia Cadastro Tabela de Fretes de Transportadoras )
@author MarceloLauschner
@since 18/02/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA56()
	
	
	Private cCadastro := "Tabela de Preços de Frete Transportadoras X Cidades"
	Private aRotina := {}
	
	aRotina := {{ OemToAnsi("Pesquisa") ,"AxPesqui", 0 , 1},;
		{ OemToAnsi("Visualiza") ,"AxVisual", 0 , 2},;
		{ OemToAnsi("Incluir") ,"AxInclui", 0 , 3},;
		{ OemToAnsi("Dinamico") ,"U_BFATA56A", 0 , 3},;
		{ OemToAnsi("Copia") ,"U_BFATA56B", 0 , 3},;
		{ OemToAnsi("Altera"),"AxAltera", 0 , 4 } ,;
		{ OemToAnsi("Excluir"), "AxDeleta", 0 , 5 }}
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	dbSelectArea("SZK")
	dbGotop()
	
	mBrowse( 6,1,22,75,"SZK",,,,,,)
	
Return


User Function BFATA56A(cAlias,nReg,nOpc)
	
	INCLUI := .T.
	ALTERA := .F.
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Envia para processamento dos Gets          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nOpcA:=0
	
	Begin Transaction
		nOpcA:=AxInclui( cAlias, nReg, nOpc,,,,)
	End Transaction
	DbCommit()
	dbSelectArea("SZK")
	nReg := Recno()
	If nOpca == 1
		Begin Transaction
			
			dbSelectArea("SZK")
			
			cZK_TRANSP	:= SZK->ZK_TRANSP	//CHAR(6)           '      '
			cZK_TABELA  := SZK->ZK_TABELA	//CHAR(3)           '   '
			nZK_FRVALOR := SZK->ZK_FRVALOR	//NUMBER            0.0
			nZK_FRPESO  := SZK->ZK_FRPESO	//NUMBER            0.0
			nZK_GRIS    := SZK->ZK_GRIS		//NUMBER            0.0
			nZK_TAXA    := SZK->ZK_TAXA		//NUMBER            0.0
			nZK_TXEXTRA := SZK->ZK_TXEXTRA	//NUMBER            0.0
			nZK_FRMIN   := SZK->ZK_FRMIN	//NUMBER            0.0
			nZK_PEDAG   := SZK->ZK_PEDAG	//NUMBER            0.0
			cZK_ICMINCL := SZK->ZK_ICMINCL	//CHAR(1)           ' '
			cZK_NOMETB  := SZK->ZK_NOMETB	//CHAR(20)          '                    '
			nZK_VALCOBR := SZK->ZK_VALCOBR	//NUMBER            0.0
			nZK_MINTON  := SZK->ZK_MINTON	//NUMBER            0.0
			dZK_DTINI   := SZK->ZK_DTINI	//CHAR(8)           '        '
			dZK_DTFIM   := SZK->ZK_DTFIM	//CHAR(8)           '        '
			cZK_EST		:= SZK->ZK_EST
			cZK_CODMUN	:= SZK->ZK_CODMUN
			
			
			DbSelectArea("CC2")
			DbSetOrder(1)
			DbSeek(xFilial("CC2")+cZK_EST)
			While !Eof() .And. CC2->CC2_EST == cZK_EST
				If CC2->CC2_CODMUN <> cZK_CODMUN
					DbSelectArea("SZK")
					RecLock("SZK",.T.)
					SZK->ZK_FILIAL	:= xFilial("SZK")
					SZK->ZK_TRANSP	:= cZK_TRANSP	//CHAR(6)           '      '
					SZK->ZK_TABELA  := cZK_TABELA	//CHAR(3)           '   '
					SZK->ZK_FRVALOR := nZK_FRVALOR	//NUMBER            0.0
					SZK->ZK_FRPESO  := nZK_FRPESO	//NUMBER            0.0
					SZK->ZK_GRIS    := nZK_GRIS		//NUMBER            0.0
					SZK->ZK_TAXA    := nZK_TAXA		//NUMBER            0.0
					SZK->ZK_TXEXTRA := nZK_TXEXTRA	//NUMBER            0.0
					SZK->ZK_FRMIN   := nZK_FRMIN	//NUMBER            0.0
					SZK->ZK_PEDAG   := nZK_PEDAG	//NUMBER            0.0
					SZK->ZK_ICMINCL := cZK_ICMINCL	//CHAR(1)           ' '
					SZK->ZK_NOMETB  := cZK_NOMETB	//CHAR(20)          '                    '
					SZK->ZK_VALCOBR := nZK_VALCOBR	//NUMBER            0.0
					SZK->ZK_MINTON  := nZK_MINTON	//NUMBER            0.0
					SZK->ZK_EST     := CC2->CC2_EST	//CHAR(2)           '  '
					SZK->ZK_CODMUN  := CC2->CC2_CODMUN	//CHAR(5)           '     '
					SZK->ZK_DTINI   := dZK_DTINI	//CHAR(8)           '        '
					SZK->ZK_DTFIM   := dZK_DTFIM	//CHAR(8)           '        '
					MsUnlock()
				Endif
				DbSelectArea("CC2")
				DbSkip()
			Enddo
		End Transaction
		MsgAlert("Gravação Finalizada","A L E R T A!")
	Endif
	
Return

User Function BFATA56B(cAlias,nReg,nOpc)

	Local aParamSA2   := {{|| sfRegMem()},{|| .T.},{|| .T.},{|| .T.}}
	
	INCLUI	:= .T.
	ALTERA	:= .F.
	
	dbSelectArea("SZK")
	nReg := Recno()
	
	
	
	Begin Transaction
		//AxInclui("SA2",1,Nil,/*aAcho*/,/*cFunc*/,/*aCpos*/,"A020TudoOk()",.T.,/*cTransact*/,/*aButtons*/,aParamSA2,/*aAuto*/,/*lVirtual*/,/*lMaximized*/,/*cTela*/,/*lPanelFin*/,/*oFather*/,/*aDim*/,/*uArea*/)
		nOpcA:=AxInclui( cAlias, 1, Nil,/*aAcho*/,/*cFunc*/,/*aCpos*/,/**/,.T.,/*cTransact*/,/*aButtons*/,aParamSA2,)
	End Transaction
	
	DbCommit()
	
Return

Static Function sfRegMem()

	M->ZK_TRANSP  	:= SZK->ZK_TRANSP	//CHAR(6)           '      '
	M->ZK_NOMETR 	:= POSICIONE("SA4",1,XFILIAL("SA4")+SZK->ZK_TRANSP,"A4_NREDUZ")                       
	M->ZK_TABELA  	:= SZK->ZK_TABELA	//CHAR(3)           '   '
	M->ZK_FRVALOR 	:= SZK->ZK_FRVALOR	//NUMBER            0.0
	M->ZK_FRPESO  	:= SZK->ZK_FRPESO	//NUMBER            0.0
	M->ZK_GRIS    	:= SZK->ZK_GRIS		//NUMBER            0.0
	M->ZK_TAXA    	:= SZK->ZK_TAXA		//NUMBER            0.0
	M->ZK_TXEXTRA 	:= SZK->ZK_TXEXTRA	//NUMBER            0.0
	M->ZK_FRMIN   	:= SZK->ZK_FRMIN	//NUMBER            0.0
	M->ZK_PEDAG   	:= SZK->ZK_PEDAG	//NUMBER            0.0
	M->ZK_ICMINCL 	:= SZK->ZK_ICMINCL	//CHAR(1)           ' '
	M->ZK_NOMETB  	:= SZK->ZK_NOMETB	//CHAR(20)          '                    '
	M->ZK_VALCOBR 	:= SZK->ZK_VALCOBR	//NUMBER            0.0
	M->ZK_MINTON  	:= SZK->ZK_MINTON	//NUMBER            0.0
	M->ZK_DTINI   	:= SZK->ZK_DTINI	//CHAR(8)           '        '
	M->ZK_DTFIM   	:= SZK->ZK_DTFIM	//CHAR(8)           '        '
	M->ZK_EST		:= SZK->ZK_EST
	M->ZK_CODMUN	:= SZK->ZK_CODMUN
	M->ZK_NOMMUN	:= POSICIONE("CC2",1,XFILIAL("CC2")+SZK->ZK_EST+SZK->ZK_CODMUN,"CC2_MUN")          
	
Return
