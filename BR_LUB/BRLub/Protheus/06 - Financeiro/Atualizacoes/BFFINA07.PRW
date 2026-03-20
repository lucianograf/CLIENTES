#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} sfExec (Function responsável pela geração do cnab pagar HSBC)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
User Function BFFINA07()

	Local		lContinua	:= .F.	
	Private 	cArq 		:= Space(30)
	Private 	cBord 		:= Space(6)
	
	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Geração remessa HSBC")
	@ 02,10 TO 070,190
	@ 10,018 SAY "Nome do Arquivo:"
	@ 10,120 GET cArq Size 40,10
	@ 30,018 SAY "Informe o Bordero:"
	@ 30,120 GET cBord Size 10,10
	@ 75,133 BMPBUTTON TYPE 01 Action(lContinua := .T.,oDlg1:End())
	@ 75,163 BMPBUTTON TYPE 02 ACTION oDlg1:End()

	ACTIVATE MSDIALOG oDlg1 CENTERED

	If lContinua
		sfExec()
	Endif
		
Return

/*/{Protheus.doc} sfExec (Funcao que executa a geracao do arquivo apos confirmar)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfExec()

	Private 	nX1,nX2,nX3,nX4,nX5
	Private		aDoc 		:= {}
	Private		aDetDoc 	:= {}
	Private 	aImp 		:= {}
	Private 	aDetImp 	:= {}
	Private		aTit 		:= {}
	Private		aDetTit 	:= {}
	Private		aDarf 		:= {}
	Private		aDetDarf 	:= {}
	Private		aCon 		:= {}
	Private		aDetCon 	:= {}
	Private 	nRegs  		:= 0
	Private 	nConta 		:= 0
	Private		cTp 		:= Space(4)
	Private		nValpg 		:= 0
	Private		nContTot 	:= 0
	Private 	nContLot 	:= 0
	Private 	cEOL      	:= "CHR(13)+CHR(10)"
	
	MakeDir("C:\EDI\HSBC\")
	
	Private 	cArqTxt 	:= "C:\EDI\HSBC\"+AllTrim(cArq)+".TXT"
	Private 	nHdl      	:= fCreate(cArqTxt)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria o arquivo texto                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif

	If nHdl == -1
		MsgAlert("O arquivo de nome "+AllTrim(cArqTxt)+" nao pode ser executado!","Atencao!")
		Return
	Endif

	dbSelectArea("SEE")
	dbSetOrder(1)
	If !DbSeek(xFilial("SEE")+"3990398 0204890   ")
		MsgAlert("Não foi encontrada a configuração de Parâmetros para a conta '399-0398-0204890' ")
		Return .F.
	Endif

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																//	001-003 9(03) Codigo do Banco
	cCpo += "0000"    																//	004-007 9(04) Codigo do Lote
	cCpo += "0"      																//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 																//	009-017 X(09) Brancos
	cCpo += "2"																		//	018-018 9(01) Tipo Inscr. Empresa 1=CPF/2=CNPJ
	cCpo += SM0->M0_CGC 															// 	019-032 9(14) Nr. Inscr. Empresa
	cCpo += "892882"																// 	033-038 9(06) Número do Contrato
	cCpo += Space(14) 																//	039-052 X(14) Brancos
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)									 		// 	053-057 9(05) Agencia
	cCpo += Space(1) 																//	058-058 X(01) Brancos 
	cCpo += "000000"+ Substr(SEE->EE_CONTA,1,6)                           			// 	059-070 9(12) Conta
	cCpo += Substr(SEE->EE_CONTA,7,1)                                   			//	071-071 X(01) Dig.Verif.Conta
	cCpo += Space(1)    															// 	072-072 X(01) Brancos
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  											// 	073-102 X(30) Razao Social
	cCpo += Padr("HSBC BANK BRASIL S/A",30)  										// 	103-132 X(30) Nome Banco
	cCpo += Space(10) 																// 	133-142 X(10) Brancos
	cCpo += "1" 																	// 	143-143 9(01) Cod.Arquivo 1= Remessa
	cCpo += GravaData(dDataBase,.F.,5)												//	144-151 9(08) Data geração do arquivo DDMMAAAA
	cCpo += Alltrim(StrTran(Time(),":"))											// 	152-157 9(06) Hora geração HHMMSS
	cCpo += Replicate("0",6) 														//	158-163 9(06) Nr.Seq.Arquivo (Nao controla)
	cCpo += "020"   																//	164-166 9(03) Nr.Versao Layout	
	cCpo += "01600"			 														//	167-171 9(05) Dens.Grav.Arq
	cCpo += "CPG"			 														//	172-174 X(03) Sigla do App
	cCpo += "Y2K"			 														//	175-177 X(03) Ident.Ano 2000
	cCpo += Space(14) 																// 	178-191 X(14) Brancos
	cCpo += Space(49) 																// 	192-240 X(49) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		//			Exit
		Endif
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Pagamento de arquivo texto.                                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cQry := " "
	cQry += "SELECT E2_FORNECE,E2_LOJA,E2_PREFIXO,E2_NUM,E2_PARCELA,E2_TIPO,E2_CODBAR "
	cQry += "  FROM " + RetSqlName("SE2") +" E2 "
	cQry += " WHERE E2_NUMBOR =  '"+cBord+"' "
	cQry += "   AND E2_FILIAL = '" + xFilial("SE2") + "' "
	cQry += "   AND D_E_L_E_T_ = ' ' "
	cQry += "   AND E2_SALDO > 0 "
	cQry += "   AND E2_TIPO NOT IN('NDF','PR') "

	If Select("QRY") <> 0
		dbSelectArea("QRY")
		dbCloseArea("QRY")
	Endif

	TCQUERY cQry NEW ALIAS "QRY"

	Count To nRegs
	
	dbSelectArea("QRY")
	dbGotop()
	ProcRegua(nRegs)
	While !Eof()
	
		If QRY->E2_FORNECE $ ("INPS  ") // Impostos sem codigo de barras
			// PROCURA TITULO PAI
			Aadd(aImp,{;
				QRY->E2_PREFIXO,;		//	1
				QRY->E2_NUM,;			//	2
				QRY->E2_PARCELA,;		//	3
				QRY->E2_TIPO,;			//	4
				QRY->E2_FORNECE,;		//	5
				QRY->E2_LOJA})			//	6
		Elseif QRY->E2_FORNECE $ ("UNIAO ")
			Aadd(aDarf,{;
				QRY->E2_PREFIXO,;		//	1
				QRY->E2_NUM,;			//	2
				QRY->E2_PARCELA,;		//	3
				QRY->E2_TIPO,;			//	4
				QRY->E2_FORNECE,;		//	5
				QRY->E2_LOJA})			//	6
		Elseif !Empty(QRY->E2_CODBAR) .And. Substr(QRY->E2_CODBAR,1,1) = "8" // Titulos concessionarias
			Aadd(aCon,{;
				QRY->E2_PREFIXO,;		//	1
				QRY->E2_NUM,;			//	2
				QRY->E2_PARCELA,;		//	3
				QRY->E2_TIPO,;			//	4
				QRY->E2_FORNECE,;		//	5
				QRY->E2_LOJA})			//	6
		Elseif !Empty(QRY->E2_CODBAR) .And. Len(Alltrim(QRY->E2_CODBAR)) < 48 // Titulos com codigo de Barras
			Aadd(aTit,{;
				QRY->E2_PREFIXO,;		//	1
				QRY->E2_NUM,;			//	2
				QRY->E2_PARCELA,;		//	3
				QRY->E2_TIPO,;			//	4
				QRY->E2_FORNECE,;		//	5
				QRY->E2_LOJA})			//	6
		Else  // DOCS E TEDS
			Aadd(aDoc,{;
				QRY->E2_PREFIXO,;		//	1
				QRY->E2_NUM,;			//	2
				QRY->E2_PARCELA,;		//	3
				QRY->E2_TIPO,;			//	4
				QRY->E2_FORNECE,;		//	5
				QRY->E2_LOJA})			//	6
		Endif
	
		dbSelectArea("QRY")
		dbSkip()
	Enddo

	QRY->(DbCloseArea())
	
	If Len(aDoc) > 0
		sfDoc()
	Endif

	If Len(aTit) > 0
		sfTit()
	Endif

	If Len(aCon) > 0
		sfCon()
	Endif
	
	If Len(aDarf) > 0
		MsgAlert("Existe(m) título(s) do fornecedor 'UNIAO' no bordero. O título não será gerado no arquivo.")
		// Funcao está pronta, mas não ira pagar Darf via bordero
		//sfDarf()
	Endif

	If Len(aImp) > 0
		MsgAlert("Existe(m) título(s) do fornecedor 'INPS' no bordero. O título não será gerado no arquivo.")
		// Funcao está pronta, mas não ira pagar Impostos via bordero
		//sfImp()
	Endif

	sfTrailer()

	fClose(nHdl)
	
	MsgInfo("Arquivo Gerado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	
	ShellExecute("open","C:\EDI\HSBC\","","C:\EDI\HSBC\",1)
	
Return

/*/{Protheus.doc} sfDoc (Grava registros referente a DOCs e TEDs)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static function sfDoc()
	Local		cTipPg		:= ""
	Local		cForPg		:= ""

	nConta := 0
	nValpg := 0

	For x := 1 To Len(aDoc)
	
		// Posiciona no Título
		DbSelectArea("SE2")
		DbSetOrder(1)
		If dbSeek(xFilial("SE2")+aDoc[x][1]+aDoc[x][2]+aDoc[x][3]+aDoc[x][4]+aDoc[x][5]+aDoc[x][6])
			// Verifica se o título tem IDCNAB 
			// Para permitir a tratativa no retorno bancário
			sfGrvE2IDCNAB()
			
			// Posiciona no Fornecedor
			DbSelectArea("SA2")
			DbSetOrder(1)
			If dbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
	
				cIdtit  := aDoc[x][1]+aDoc[x][2]+aDoc[x][3]+aDoc[x][4]+aDoc[x][5]+aDoc[x][6]
	
				cTipPg := "20"
			
				If SA2->A2_BANCO == '399'//Forma de Pagamento HSBC
					cForPg := "01"
				Else
					cForPg := "03" 	// DOC C
				Endif
				
				If !Empty(SA2->A2_BANCO)
					Aadd(aDetDoc,{;
						cTipPg,;				//	1
						cForPg,;				//	2
						cIdtit,;				//	3
						SA2->A2_BANCO,;			//	4
						SA2->A2_AGENCIA,;		//	5
						SA2->A2_NUMCON,;		//	6
						SA2->A2_DIGCC,;			//	7
						SA2->A2_NOME,;			//	8
						SE2->E2_VENCREA,;		//	9
						SE2->E2_SALDO,;			//	10
						SE2->E2_DECRESC,;		//	11
						SE2->E2_ACRESC,;		//	12
						SA2->A2_CGC,;			//	13
						SE2->E2_IDCNAB})		// 	14
				Endif
			Endif
		Endif
	Next

	aSort(aDetDoc,,,{|x,y| x[1]+x[2] < y[1]+y[2]})

	For nX1 := 1 To Len(aDetDoc)
		If Alltrim(cTp) <> Alltrim(aDetDoc[nX1,1]+aDetDoc[nX1,2])
			If nX1 > 1
				sfTreiDoc()
			Endif
			sfCabDoc()
		Endif
		cTp := aDetDoc[nX1,1]+aDetDoc[nX1,2]
		sfDetDoc()
		// Complemento obrigatorio 
		sfComDoc()
	Next

	sfTreiDoc()

Return



/*/{Protheus.doc} sfCabDoc (Monta linha do Cabeçalho para os registros DOC/TED)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfCabDoc()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	
	cCpo := "399"      															//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)													//	004-007 9(04) Codigo do Lote
	cCpo += "1"      															//	008-008 9(01) Tipo de Registro
	cCpo += "C"      															//	009-009 X(01) Tipo de Operacao C=Credito
	cCpo += "20"			  													//	010-011 9(02) Tipo de Pagamento 20=Pagamento Fornecedores
	cCpo += aDetDoc[nX1,2] 														// 	012-013 9(02) Forma de Lançamento
	cCpo += "020" 																// 	014-016 9(03) Nr.Versao Layout
	cCpo += Space(1)   															// 	017-017 X(01) Brancos
	cCpo += "2" 																// 	018-018 9(01) Tipo Inscr.Empresa 1=CPF 2=CNPJ
	cCpo += SM0->M0_CGC				   											// 	019-032 9(14) Nr. Inscr.Empresa
	cCpo += "892882"															// 	033-038 9(06) Número do Contrato
	cCpo += Space(14)      														// 	039-052 X(14) Brancos
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)  									//	053-057 9(05) Agencia 
	cCpo += Space(1)      														// 	058-058 X(01) Brancos
	cCpo += "000000"+ Substr(SEE->EE_CONTA,1,6)                           		// 	059-070 9(12) Conta
	cCpo += Substr(SEE->EE_CONTA,7,1)                                   		//	071-071 X(01) Dig.Verif.Conta
	cCpo += Space(1)    														// 	072-072 X(01) Brancos
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  										// 	073-102 X(30) Razao Social
	cCpo += Space(40)    														// 	103-142 X(40) Mensagem Marketing
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 										// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  										//	173-177 X(05) Numero do Local
	cCpo += Space(15)   														// 	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  										// 	193-212 X(20) Cidade
	cCpo += Substr(SM0->M0_CEPCOB,1,5)											// 	213-217 9(05) CEP
	cCpo += Substr(SM0->M0_CEPCOB,6,3)											// 	218-220 9(03) CEP Complemento
	cCpo += Substr(SM0->M0_ESTCOB,1,2)											// 	221-222 X(02) Sigla do Estado
	cCpo += "N" 											     				// 	223-223 X(01) Emissao em lote S=Sim ou N=Nao
	cCpo += Space(17)  															//	224-240 X(10) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfDetDoc (Monta linha de detalhes para os registros DOC/TED)	
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfDetDoc()

	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																		//	008-008 9(01) Tipo de Registro
	cCpo += Strzero(nConta,5)	  															//	009-013 9(05) Numero de registro
	cCpo += "A" 																			// 	014-014 X(01) Segmento
	cCpo += "0" 																			// 	015-015 9(01) Tipo de Movimento
	cCpo += "00"       																		// 	016-017 9(02) Cod.Instrução para Mov.
	cCpo += "018"       																	// 	018-020 9(03) 018-TED,700-DOC
	cCpo += aDetDoc[nX1,4]  																// 	021-023 9(03) Banco do Favorecido
	cCpo += Strzero(Val(aDetDoc[nX1,5]),5) 													// 	024-028 9(05) Agencia do favorecido
	cCpo += Space(1)	  																	// 	029-029 X(01) Brancos
	If Len(Alltrim(aDetDoc[nX1,7])) == 2
		cCpo += StrZero(Val(aDetDoc[nX1,6]),11)+Substr(Alltrim(aDetDoc[nX1,7]),1,1)			// 	030-041 9(12) Conta
		cCpo += Substr(Alltrim(aDetDoc[nX1,7]),2,1)											// 	042-042 X(01) Digito
	Else
		cCpo += StrZero(Val(aDetDoc[nX1,6]),12)												// 	030-041 9(12) Conta
		cCpo += PadR(Alltrim(aDetDoc[nX1,7]),1)												// 	042-043 9(01) Digito	
	EndIf
	cCpo += Space(1)  																		// 	043-043 X(01) Brancos
	cCpo += Substr(aDetDoc[nX1,8],1,30)														// 	044-073 X(30) Nome do Favorecido
	cCpo += Strzero(Val(aDetDoc[nX1,14]),16)												//  074-089 X(16) Nr.Docto.Atribuido IDCNAB
	cCpo += Space(4)  																		// 	090-093 X(04) Brancos 	
	cCpo += GravaData(aDetDoc[nX1,9],.F.,5)													//	094-101 9(08) Data de pagto - DDMMAAAA
	cCpo += "R$ " 																			// 	102-104 X(03) Moeda
	cCpo += Space(17)	  																	// 	105-121 X(17) Brancos
	cCpo += Strzero((aDetDoc[nX1,10]-aDetDoc[nX1,11]+aDetDoc[nX1,12])*100,13)				// 	122-134 9(11)V9(02) Valor Pgto
	cCpo += "N" 																			// 	135-135 X(01) Comp.Pag
	cCpo += Space(30) 																		// 	136-165 X(30) Pagador Efetivo
	cCpo += Space(12) 																		// 	166-177 X(12) Brancos
	cCpo += Space(40) 																		// 	178-217 X(40) Informação 2
	cCpo += Space(2)																		// 	218-219 X(02) Comp.Tipo Serv DOC 
	cCpo += "00010"																			// 	220-224 X(05) Comp.Tipo Serv TED Anexo T
	cCpo += "CC"	 																		// 	225-226 X(02) Codigo Finalidade Comp. CC ou PP
	cCpo += Space(3) 																		// 	227-229 X(03) CNAB
	cCpo += "0"		 																		// 	230-230 9(01) Aviso
	cCpo += Space(10) 																		// 	231-240 X(10) Brancos
	
	cLin := Stuff(cLin,01,240,cCpo)
	
	nValpg += aDetDoc[nX1,10]-aDetDoc[nX1,11]-aDetDoc[nX1,12]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif


Return

/*/{Protheus.doc} sfComDoc (Monta linha de complemento para os registros DOC/TED)	
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfComDoc()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																		//	008-008 9(01) Tipo de Registro
	cCpo += Strzero(nConta,5)	  															//	009-013 9(05) Numero de registro
	cCpo += "B" 																			// 	014-014 X(01) Segmento
	cCpo += Space(3) 																		// 	015-017 X(03) Brancos
	cCpo += IIf(Len(aDetDoc[nX1,13]) == 14,"1","2")											// 	018-018 9(01) CNPJ ou CPF Favorecido
	cCpo += PadR(aDetDoc[nX1,13],14)														// 	019-032 9(14) Numero Favorecido
	cCpo += Space(30)																		// 	033-062 X(30) Rua Favorecido
	cCpo += Space(5)																		// 	063-067 X(05) Nr Favorecido
	cCpo += Space(15)																		// 	068-082 X(15) Comp. Favorecido
	cCpo += Space(15)																		// 	083-097 X(15) Bairro Favorecido
	cCpo += Space(20)																		// 	098-117 X(20) Cidade Favorecido
	cCpo += Space(5)																		// 	118-122 X(05) CEP Favorecido	
	cCpo += Space(3)																		// 	123-125 X(03) Comp. CEP Favorecido
	cCpo += Space(2)																		// 	126-127 X(02) Sigla Estado
	cCpo += Space(105)																		// 	128-232 X(105) Brancos
	cCpo += Space(8)																		// 	233-240 X(08) Sigla Estado

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return



/*/{Protheus.doc} sfTreiDoc (Monta linha de trailer para os registros DOC/TED)	
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfTreiDoc()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "5"      																		//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 																		// 	009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 															// 	018-023 9(06) Numero de arquivos
	cCpo += Space(3) 																		// 	024-026 X(03) Brancos
	cCpo += Strzero(nValpg*100,15)  														// 	027-041 9(13)V9(02) Valor total dos pagamentos
	cCpo += Space(199)																		// 	042-240 X(199) Brancos
	
	nContTot += nConta+2
	nConta := 0
	nValpg := 0

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return

/*/{Protheus.doc} sfTit (Grava registros referente a Liq.Titulo Codigo Barras (Boleto))
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfTit()

	cTp 	:= Space(2)
	nConta 	:= 0
	nValpg 	:= 0

	For x:=1 To Len(aTit)
	
		DbSelectArea("SE2")
		DbSetOrder(1)
		If dbSeek(xFilial("SE2")+aTit[x][1]+aTit[x][2]+aTit[x][3]+aTit[x][4]+aTit[x][5]+aTit[x][6])
			// Verifica se o título tem IDCNAB 
			// Para permitir a tratativa no retorno bancário 
			sfGrvE2IDCNAB()
			
			DbSelectArea("SA2")
			DbSetOrder(1)
			If DbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
	
				cIdtit  := aTit[x][1]+aTit[x][2]+aTit[x][3]+aTit[x][4]+aTit[x][5]+aTit[x][6]
	
				If Substr(SE2->E2_CODBAR,1,3) == "399"    //Tipo de Pagamento
					Aadd(aDetTit,{;
						"30",;						//	1
						cIdtit,;					//	2
						SE2->E2_CODBAR,;			//	3
						SA2->A2_NOME,;				//	4
						SE2->E2_VENCREA,;			//	5
						SE2->E2_SALDO,;				//	6
						SE2->E2_DECRESC,;			//	7
						SE2->E2_ACRESC,;			//	8
						SE2->E2_IDCNAB,;			//	9
						SA2->A2_CGC})				// 10
				Else
					Aadd(aDetTit,{;
						"31",;					//	1
						cIdtit,;				//	2
						SE2->E2_CODBAR,;		//	3
						SA2->A2_NOME,;			//	4
						SE2->E2_VENCREA,;		//	5
						SE2->E2_SALDO,;			//	6
						SE2->E2_DECRESC,;		//	7
						SE2->E2_ACRESC,;		//	8
						SE2->E2_IDCNAB,;		// 	9
						SA2->A2_CGC})			// 10
				Endif
			Endif
		Endif
		
	Next

	aSort(aDetTit,,,{|x,y| x[1] < y[1]})

	For nX3 := 1 To Len(aDetTit)
		If Alltrim(cTp) <> Alltrim(aDetTit[nX3,1])
			If nX3 > 1
				sfTreiTit()
			Endif
			sfCabTit()
		Endif
		cTp := aDetTit[nX3,1]
		sfDetTit()
		If (aDetTit[nX3,6]-aDetTit[nX3,7]+aDetTit[nX3,8]) >= 250000
			sfComTit()
		EndIf
	Next

	sfTreiTit()

Return


/*/{Protheus.doc} sfCabTit (Monta linha do Cabeçalho para os registros BOLETO)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfCabTit()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	
	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "1"      																		//	008-008 9(01) Tipo de Registro
	cCpo += "C"      																		//	009-009 X(01) Tipo de Operacao = C credito
	cCpo += "01"    																		//	010-011 9(02) Tipo de Servico
	cCpo +=  aDetTit[nX3,1] 																// 	012-013 9(02) Forma de Pagamento
	cCpo += "020" 																			// 	014-016 9(03) Lay Out do Lote
	cCpo += Space(1)   																		// 	017-017 X(01) Brancos
	cCpo += "2" 																			// 	018-018 9(01) Tipo de inscricao em debitada 1=CPF 2=CNPJ
	cCpo += Substr(SM0->M0_CGC,1,14)  	 													// 	019-032 9(14) CNPJ empresa Debitada
	cCpo += "892882"  	 																	// 	033-038 9(06) Nr.Contrato
	cCpo += Space(14)      																	// 	039-052 X(14) Brancos
	cCpo += StrZero(Val(SEE->EE_AGENCIA),5)  												// 	053-057 9(05) Agencia (5)
	cCpo += Space(1)      																	// 	058-058 X(01) Brancos
	cCpo += "000000" + Substr(SEE->EE_CONTA,1,6)    	                       				// 	059-070 9(12) Conta
	cCpo += Substr(SEE->EE_CONTA,7,1)      	    	                         				// 	071-071 9(01) Digitocc	
	cCpo += Space(1)    																	// 	072-072 X(01) Branco
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  													//	073-102 X(30) Razao Social
	cCpo += Space(40) 																		// 	103-142 X(40) Finalidade
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 													// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  													//	173-177 9(05) Numero do Local
	cCpo += Space(15)   																	// 	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  													// 	193-212 X(20) Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,5)														// 	213-217 9(05) CEP
	cCpo += Substr(SM0->M0_CEPCOB,6,3)														// 	218-220 9(03) CEP Complemento
	cCpo += Substr(SM0->M0_ESTCOB,1,2)														//	221-222 X(02) Sigla Estado
	cCpo += "N"		      																	// 	223-223 X(01) Comp.Pag
	cCpo += Space(17)  																		//	224-240 X(17) Brancos	

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif


Return


/*/{Protheus.doc} sfDetTit (Monta linha do Detalhe para os registros BOLETO)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfDetTit()
	
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "3"    																			//	008-008 9(01) Tipo de Registro
	cCpo += StrZero(nConta,5)	  															//	009-013 9(05) Numero de registro
	cCpo += "J" 																			// 	014-014 X(01) Segmento
	cCpo += "0" 																			// 	015-015 9(03) Tipo de Movimento - Inclusao
	cCpo += "00" 																			// 	016-017 9(03) Codigo Inst.Mov
	cCpo += Substr(aDetTit[nX3,3],1,3) 														//	018-020 9(03) Codigo de Barras - Codigo Banco favorecido
	cCpo += Substr(aDetTit[nX3,3],4,1) 														// 	021-021 9(01) Moeda
	cCpo += Substr(aDetTit[nX3,3],5,1) 														// 	022-022 9(01) Dig Verificador
	If Val(Alltrim(Substr(aDetTit[nX3,3],6,4))) == 0
		cCpo += Replicate("0",4)															//	023-026 9(04) Fator de Vencimento
	Else
		cCpo += Substr(aDetTit[nX3,3],6,4) 													// 	023-026 9(04) Fator Vencimento
	Endif
	If Empty(Substr(aDetTit[nX3,3],10,10))
		cCpo += Replicate("0",10)															//	027-036 9(08)V9(02) Codigo de Barras - Valor
	Else
		cCpo += Substr(aDetTit[nX3,3],10,10) 												//	027-036 9(08)V9(02) Codigo de Barras - Valor
	Endif
	cCpo += Substr(aDetTit[nX3,3],20,25)  													//	037-061 9(25) Codigo de Barras - Campo livre
	cCpo += Substr(aDetTit[nX3,4],1,30) 													// 	062-091 X(30) Nome do Favorecido
	cCpo += GravaData(aDetTit[nX3,5],.F.,5) 												// 	092-099 9(08) Data Vencimento DDMMAAAA
	cCpo += Space(2)																		//  100-101 X(02) Brancos	
	cCpo += Strzero(aDetTit[nX3,6]*100,13) 													// 	102-114 9(011)V9(02) Saldo
	cCpo += Space(2)																		//  115-116 X(02) Brancos
	cCpo += Strzero(aDetTit[nX3,7]*100,13) 													// 	117-129 9(011)V9(02) Descontos
	cCpo += Space(2)																		//  130-131 X(02) Brancos
	cCpo += Strzero(aDetTit[nX3,8]*100,13) 													//	132-144 9(011)V9(02) Acrescimos
	cCpo += GravaData(aDetTit[nX3,5],.F.,5)													// 	145-152 9(08) Data Pagamento DDMMAAAA
	cCpo += Space(2)																		//  153-154 X(02) Brancos
	cCpo += StrZero((aDetTit[nX3,6]-aDetTit[nX3,7]+aDetTit[nX3,8])*100,13) 					// 	155-167 9(11)V9(02) Valor do Pagamento
	cCpo += Space(2)																		//  168-169 X(02) Brancos
	cCpo += Replicate("0",13) 																// 	170-182 9(7)V9(06) Qtde Moeda
	cCpo += Padr("0000000000"+Substr(aDetTit[nX3,9],1,20),20)								// 	183-202 X(20) Cód.Ref.Sacado
	cCpo += Space(20) 																		// 	203-222 X(20) Brancos
	cCpo += Space(02) 																		// 	223-224 X(02) Brancos
	cCpo += "N" 																			// 	225-225 X(02) Comp.Pag
	cCpo += Space(15) 																		// 	226-240 X(15) Brancos

	cLin := Stuff(cLin,01,240,cCpo)
	
	nValpg += aDetTit[nX3,6]-aDetTit[nX3,7]-aDetTit[nX3,8]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif


Return

/*/{Protheus.doc} sfComTit (Monta linha do Complemento para os registros BOLETO)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfComTit()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "3"    																			//	008-008 9(01) Tipo de Registro
	cCpo += StrZero(nConta,5)	  															//	009-013 9(05) Numero de registro
	cCpo += "J" 																			// 	014-014 X(01) Segmento
	cCpo += Space(1) 																		// 	015-015 9(01) CNAB Brancos
	cCpo += Space(2) 																		// 	016-017 9(02) Cod.Movimento Brancos
	cCpo += "52" 																			// 	018-019 9(02) Fixo 52
	cCpo += "1"																				// 	020-020 9(01) CNPJ ou CPF Sacado
	cCpo += StrZero(SM0->M0_CGC,15)															// 	021-035 9(15) Numero Sacado
	cCpo += Substr(SM0->M0_NOMECOM,1,40)													// 	036-075 9(40) Nome Sacado
	cCpo += IIf(Len(aDetTit[nX3,10]) == 14,"1","2")											// 	076-076 9(01) CNPJ ou CPF Cedente
	cCpo += StrZero(aDetTit[nX3,10],15)   													// 	077-091 9(15) Numero Cedente
	cCpo += PadR(aDetTit[nX3,4],40)															//	092-131 X(40) Nome Cedente
	cCpo += Space(1)																		// 	132-132 9(01) CNPJ ou CPF Sacador
	cCpo += Space(15)																		// 	133-147 9(15) Numero Sacador
	cCpo += Space(40)																		// 	148-187 9(40) Nome Sacador
	cCpo += Space(53) 																		// 	188-240 X(53) Brancos

	cLin := Stuff(cLin,01,240,cCpo)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif


Return


/*/{Protheus.doc} sfTreiTit (Monta linha do Trailer para os registros BOLETO)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfTreiTit()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	// Layout contido na página 26 Sispag Febraban 240
	cCpo := "399"      														//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "5"      														//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 														// 	009-017 X(09) Brancos
	cCpo += StrZero(nConta+2,6) 											// 	018-023 9(06)	Numero de arquivos
	cCpo += Space(3) 														// 	024-026 X(03) Brancos
	cCpo += Strzero(nValpg*100,15)  										// 	027-041 9(13)V9(02) Valor total dos pagamentos
	cCpo += Space(1) 														// 	042-042 X(01) Brancos
	cCpo += Replicate("0",15) 												// 	043-057 9(15) Qtde Moedas
	cCpo += Space(183) 														// 	058-240 X(183) Brancos
	
	nContTot += nConta+2
	nConta := 0
	nValpg := 0

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfCon (Grava registros referente a Liq.Titulo Concessionárias)
@author Iago Luiz Raimondi
@since 23/06/2016
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfCon()

	cTp 	:= Space(2)
	nConta 	:= 0
	nValpg 	:= 0

	For x := 1 To Len(aCon)
	
		DbSelectArea("SE2")
		DbSetOrder(1)
		IF DbSeek(xFilial("SE2")+aCon[x][1]+aCon[x][2]+aCon[x][3]+aCon[x][4]+aCon[x][5]+aCon[x][6])
			// Verifica se o título tem IDCNAB 
			// Para permitir a tratativa no retorno bancário
			sfGrvE2IDCNAB()
			
			DbSelectArea("SA2")
			DbSetOrder(1)
			If DbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
	
				cIdtit  := aCon[x][1]+aCon[x][2]+aCon[x][3]+aCon[x][4]+aCon[x][5]+aCon[x][6]
	
				If Alltrim(SE2->E2_FORNECE) $ ("UNIAO ")    //Tipo de Pagamento = DARF
					Aadd(aDetCon,{;
						"2211",;				//	1
					cIdtit,;					//	2
					SE2->E2_CODBAR,;			//	3
					SM0->M0_NOMECOM,;			//	4
					SE2->E2_VENCTO,;			//	5
					SE2->E2_SALDO,;				//	6
					SE2->E2_DECRESC,;			//	7
					SE2->E2_ACRESC,;			//	8
					SE2->E2_IDCNAB})			//	9
				ElseIf Alltrim(SE2->E2_FORNECE) $ ("INPS  ")    //Tipo de Pagamento = GPS
					Aadd(aDetCon,{;
						"2211",;				//	1
					cIdtit,;					//	2
					SE2->E2_CODBAR,;			//	3
					SM0->M0_NOMECOM,;			//	4
					SE2->E2_VENCTO,;			//	5
					SE2->E2_SALDO,;				//	6
					SE2->E2_DECRESC,;			//	7
					SE2->E2_ACRESC,;			//	8
					SE2->E2_IDCNAB})			//	9
				ElseIf Alltrim(SE2->E2_FORNECE) == "ESTADO"    //Tipo de Pagamento = ESTADO
					Aadd(aDetCon,{;
						"2211",;				//	1
					cIdtit,;					//	2
					SE2->E2_CODBAR,;			//	3
					SM0->M0_NOMECOM,;			//	4
					SE2->E2_VENCTO,;			//	5
					SE2->E2_SALDO,;				//	6
					SE2->E2_DECRESC,;			//	7
					SE2->E2_ACRESC,;			//	8
					SE2->E2_IDCNAB})			//	9
				Else
					Aadd(aDetCon,{;
						"2003",;				//	1
					cIdtit,;					//	2
					SE2->E2_CODBAR,;			//	3
					SA2->A2_NOME,;				//	4
					SE2->E2_VENCTO,;			//	5
					SE2->E2_SALDO,;				//	6
					SE2->E2_DECRESC,;			//	7
					SE2->E2_ACRESC,;			//	8
					SE2->E2_IDCNAB})			//	9
				Endif
			Endif
		Endif
	Next

	aSort(aDetCon,,,{|x,y| x[1] < y[1]})

	For nX4 := 1 To Len(aDetCon)
		If Alltrim(cTp) <> Alltrim(aDetCon[nX4,1])
	
			If nX4 > 1
				sfTreiCon()
			Endif
			sfCabCon()
		Endif
		cTp := aDetCon[nX4,1]
		sfDetCon()
	Next

	sfTreiCon()

Return


/*/{Protheus.doc} sfCabCon (Registro Header de lote - Pagamento de Contas de Concessionárias e Tributos com códigos de barras)
@author MarceloLauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfCabCon()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	cCpo := "399"      														//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "1"     	 													//	008-008 9(01) Tipo de Registro
	cCpo += "C"      														//	009-009 X(01) Tipo de Operacao = C credito
	cCpo += Substr(aDetCon[nX4,1],1,2)    									//	010-011 9(02) Tipo de Pagamento
	cCpo += Substr(aDetCon[nX4,1],3,2)										// 	012-013 9(02) Forma de Pagamento
	cCpo += "020" 															// 	014-016 9(03) lay out do lote
	cCpo += Space(1)   														// 	017-017 X(01) Brancos
	cCpo += "2" 															// 	018-018 9(01) Tipo de inscricao em debitada 1=CPF 2=CGC
	cCpo += Substr(SM0->M0_CGC,1,14)   										//	019-032 9(14) CNPJ empresa Debitada
	cCpo += "892882"														// 	033-038 X(06) Num.Contrato
	cCpo += Space(14)      													// 	039-052 X(14) Brancos
	cCpo += StrZero(Val(SEE->EE_AGENCIA),5)  								// 	053-057 9(05) Agencia (5)
	cCpo += Space(1)      													// 	058-058 X(01) Brancos
	cCpo += "000000" + Substr(SEE->EE_CONTA,1,6) 	        				// 	059-070 9(12) Conta
	cCpo += Substr(SEE->EE_CONTA,7,1)										// 	071-071 X(01) Dig.Conta
	cCpo += Space(1)	 	 				                              	// 	072-072 X(01) Brancos
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  									// 	073-102 X(30) Razao Social
	cCpo += Space(40) 														// 	103-142 X(40) Brancos
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 									// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  									//	173-177 9(05) Numero do Local
	cCpo += Space(15)   													//	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  									// 	193-212 X(20) Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,5)										//	213-217 9(05) CEP
	cCpo += Substr(SM0->M0_CEPCOB,6,3)										//	213-217 9(03) CEP Complemento
	cCpo += Substr(SM0->M0_ESTCOB,1,2)										// 	221-222 X(02) Sigla do Estado
	cCpo += "N"																// 	223-223 X(01) Comp.Pag
	cCpo += Space(17)      													// 	224-240 X(37) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfDetCon (Registro Detalhe - Segmento O - Obrigatório -Pagamento de Contas de Concessionárias e Tributos com Códigos de barras)
@author MarceloLauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfDetCon()
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      														//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "3"      														//	008-008 9(01) Tipo de Registro
	cCpo += StrZero(nConta,5)	  											//	009-013 9(06) Numero de registro
	cCpo += "O" 															// 	014-014 X(01) Segmento
	cCpo += "0" 															// 	015-015 9(01) Tipo de Movimento - Inclusao
	cCpo += "00" 															// 	016-017 9(02) Instr.Movimento - Inclusao
	cCpo += Substr(aDetCon[nX4,3],1,44) 									//	018-061 X(44) Codigo de Barras
	cCpo += Substr(aDetCon[nX4,4],1,30) 									// 	062-091 X(30) Nome concessionaria / contribuinte
	cCpo += GravaData(aDetCon[nX4,5],.F.,5)									// 	092-099 9(08) Data Vencimento
	cCpo += GravaData(aDetCon[nX4,5],.F.,5)									// 	100-107 9(08) Data Pagamento
	cCpo += Strzero((aDetCon[nX4,6]-aDetCon[nX4,7]+aDetCon[nX4,8])*100,15)	// 	108-122 9(13)V9(02) Valor do Pagamento
	cCpo += Strzero(Val(aDetCon[nX4,9]),16)									// 	123-138 X(16) Id tit na empresa
	cCpo += Space(4) 														// 	139-142 X(04) Brancos
	cCpo += Space(19) 														//	143-161 X(19) Nosso Numero
	cCpo += "N"		 														//	162-162 X(01) Comp.Pag 
	cCpo += Space(78) 														// 	163-240 X(78) Brancos	

	cLin := Stuff(cLin,01,240,cCpo)
	nValpg += aDetCon[nX4,6]-aDetCon[nX4,7]+aDetCon[nX4,8]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfTreiCon (Registro Trailler de Lote - Pagamento de contas de concessionarias e tributos com códigos de barra)
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfTreiCon()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	cCpo := "399"      														//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "5"      														//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 														// 	009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 											// 	018-023 9(06) Numero de arquivos
	cCpo += Space(3) 														// 	024-026 X(3) Brancos
	cCpo += Strzero(nValpg,15)  											// 	027-041 9(13)V9(02) Valor total dos pagamentos
	cCpo += Space(199) 														// 	042-240 X(199) Brancos
	
	nContTot += nConta+2
	nConta := 0
	nValpg := 0


	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfImp (Funcao para montar array com  - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfImp()

	Local		cIdTit		:= ""	// Id do Titulo
	Local		cCodPai 	:= Space(6)
	Local		cNomePai 	:= Space(30)
	Local		cCnpjPai 	:= Space(14)
	
	nConta 	:= 0
	nValpg 	:= 0

	
	For X := 1 to len(aImp)
			
		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+aImp[x][1]+aImp[x][2]+aImp[x][3]+aImp[x][4]+aImp[x][5]+aImp[x][6])
			// Verifica se o título tem IDCNAB 
			// Para permitir a tratativa no retorno bancário
			sfGrvE2IDCNAB()
			
			DbSelectArea("SA2")
			DbSetOrder(1)
			If DbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
	
				cIdTit  := aImp[x][1]+aImp[x][2]+aImp[x][3]+aImp[x][4]+aImp[x][5]+aImp[x][6]
	
				cCodPai 	:= Space(6)
				cNomePai 	:= Space(30)
				cCnpjPai 	:= Space(14)

				cQra := " "
				cQra += "SELECT A2_COD, A2_NOME, A2_CGC "
				cQra += "  FROM " + RetSqlName("SA2") + " A2, " + RetSqlName("SE2") + " E2 "
				cQra += " WHERE E2_FILIAL = '" + xFilial("SE2") + "' "
				cQra += "   AND A2.D_E_L_E_T_ = ' ' "
				cQra += "   AND E2_FORNECE = A2_COD "
				cQra += "   AND E2_LOJA = A2_LOJA "
				cQra += "   AND E2.D_E_L_E_T_ = ' ' "
				cQra += "   AND E2_NUM =  '"+aImp[x][2]+"' "
				cQra += "   AND E2_PREFIXO = '"+aImp[x][1]+"' "
				cQra += "   AND E2_EMISSAO = '"+DTOS(SE2->E2_EMISSAO)+"' "
				cQra += "   AND E2_PREFIXO || E2_NUM || E2_TIPO || E2_FORNECE || E2_LOJA  = '"+SE2->E2_TITPAI+"' "
				cQra += "AND E2_PARCINS <> ' ' "

				TCQUERY cQra NEW ALIAS "QRA"
	
				dbSelectArea("QRA")
				dbGotop()
	
				If !Empty(QRA->A2_COD)
					cCodPai 	:= QRA->A2_COD
					cNomePai 	:= Substr(QRA->A2_NOME,1,30)
					cCnpjpai 	:= Substr(QRA->A2_CGC,1,14)
				Endif
		
				If Alltrim(SE2->E2_FORNECE) == "INPS"    //Tipo de Pagamento = GPS
					Aadd(aDetImp,{;
						"17",;					//	1
						cIdtit,;				//	2
						SE2->E2_CODRET,;		//	3
						SM0->M0_NOMECOM,;		//	4
						SE2->E2_VENCTO,;		//	5
						SE2->E2_SALDO,;			//	6
						SE2->E2_DECRESC,;		//	7
						SE2->E2_ACRESC,;		//	8
						SE2->E2_EMISSAO,;		//	9
						cCodPai,;				//	10
						cNomePai,;				//	11
						cCnpjpai,;				//	12
						SE2->E2_IDCNAB})		//	13
				Endif
			Endif
		Endif
	Next
	
	aSort(aDetImp,,,{|x,y| x[1] < y[1]})
	
	For nX2 := 1 To Len(aDetImp)
		If Alltrim(cTp) <> Alltrim(aDetImp[nX2,1])
	
			If nX2 > 1
				sfTreiImp()
			Endif
			sfCabimp()
		Endif
		cTp := aDetImp[nX2,1]
		sfDetImp()
	Next

	sfTreiImp()

Return


/*/{Protheus.doc} sfCabImp (Registro Header de Lote - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfCabImp()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	cCpo := "399"      															//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)													//	004-007 9(04) Codigo do Lote
	cCpo += "1"      															//	008-008 9(01) Tipo de Registro
	cCpo += "C"      															//	009-009 X(01) Tipo de Operacao C=Credito
	cCpo += "22"			  													//	010-011 9(02) Tipo de Pagamento 20=Pagamento Fornecedores
	cCpo += aDetImp[nX2,1] 														// 	012-013 9(02) Forma de Lançamento
	cCpo += "020" 																// 	014-016 9(03) Nr.Versao Layout
	cCpo += Space(1)   															// 	017-017 X(01) Brancos
	cCpo += "2" 																// 	018-018 9(01) Tipo Inscr.Empresa 1=CPF 2=CNPJ
	cCpo += SUBS(SM0->M0_CGC,1,14)   											// 	019-032 9(14) Nr. Inscr.Empresa
	cCpo += "892882"															// 	033-038 9(06) Número do Contrato
	cCpo += Space(14)      														// 	039-052 X(14) Brancos
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)  									//	053-057 9(05) Agencia 
	cCpo += Space(1)      														// 	058-058 X(01) Brancos
	cCpo += "000000"+ Substr(SEE->EE_CONTA,1,6)                           		// 	059-070 9(12) Conta
	cCpo += Substr(SEE->EE_CONTA,7,1)                                   		//	071-071 X(01) Dig.Verif.Conta
	cCpo += Space(1)    														// 	072-072 X(01) Brancos
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  										// 	073-102 X(30) Razao Social
	cCpo += Space(40)    														// 	103-142 X(40) Mensagem Marketing
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 										// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  										//	173-177 X(05) Numero do Local
	cCpo += Space(15)   														// 	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  										// 	193-212 X(20) Cidade
	cCpo += Substr(SM0->M0_CEPCOB,1,5)											// 	213-217 9(05) CEP
	cCpo += Substr(SM0->M0_CEPCOB,6,3)											// 	218-220 9(03) CEP Complemento
	cCpo += Substr(SM0->M0_ESTCOB,1,2)											// 	221-222 X(02) Sigla do Estado
	cCpo += "N" 		     													// 	223-223 X(01) Emissao em lote S=Sim ou N=Nao
	cCpo += Space(17)  															//	224-240 X(10) Brancos
	
	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfDetimp (Registro Detalhe - Segmento N - Obrigatorio - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
@author MarceloLauschner
@since 13/12/2013
@version 1.0		
@return Sem Retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfDetImp()
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)														//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																//	008-008 9(01) Tipo de Registro
	cCpo += Strzero(nConta,5)	  													//	009-013 9(05) Numero de registro
	cCpo += "D" 																	// 	014-014 X(01) Segmento
	cCpo += Space(25) 																// 	015-039 9(25) Brancos
	cCpo += SUBS(SM0->M0_CGC,1,14)   												// 	040-053 9(14) Cnpj Contribuinte
	cCpo += Substr(aDetImp[nX2,3],1,4)												//	054-057 9(04) Codigo receita
	cCpo += Substr(GravaData(LastDay(aDetImp[nX2,9]),.F.,5),3,6) 					//	058-063 9(08) Periodo Competencia
	cCpo += Strzero((aDetImp[nX2,6]-aDetImp[nX2,7]+aDetImp[nX2,8])*100,15) 			// 	064-078 9(13)V9(02) Valor do INSS
	cCpo += Replicate("0",15) 														// 	079-093 9(13)V9(02) Valor outras entidades
	cCpo += Replicate("0",15) 														// 	094-108 9(13)V9(02) Valor Atu.Monetaria
	cCpo += Space(132) 																// 	109-240 X(132) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

	nValpg += aDetImp[nX2,6]-aDetImp[nX2,7]+aDetImp[nX2,8]

Return

/*/{Protheus.doc} sfTreiImp (Registro Trailler de Lote - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)	
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfTreiImp()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "5"      																		//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 																		// 	009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 															// 	018-023 9(06) Numero de arquivos
	cCpo += Space(3) 																		// 	024-026 X(03) Brancos
	cCpo += Strzero(nValpg,15)  															// 	027-041 9(13)V9(02) Valor total dos pagamentos
	cCpo += Space(199)																		// 	042-240 X(199) Brancos

	nContTot += nConta+2
	nConta := 0
	nValpg := 0


	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return

/*/{Protheus.doc} sfImp (Funcao para montar array com  - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfDarf()

	Local		cIdTit		:= ""	// Id do Titulo
	
	nConta 	:= 0
	nValpg 	:= 0
	
	For X := 1 to len(aDarf)
			
		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+aDarf[x][1]+aDarf[x][2]+aDarf[x][3]+aDarf[x][4]+aDarf[x][5]+aDarf[x][6])
			// Verifica se o título tem IDCNAB 
			// Para permitir a tratativa no retorno bancário
			sfGrvE2IDCNAB()
			
			DbSelectArea("SA2")
			DbSetOrder(1)
			If DbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
	
				cIdTit  := aDarf[x][1]+aDarf[x][2]+aDarf[x][3]+aDarf[x][4]+aDarf[x][5]+aDarf[x][6]
	
				If Alltrim(SE2->E2_FORNECE) == "UNIAO"    //Tipo de Pagamento = DARF
					Aadd(aDetDarf,{;
						"16",;				//	1
					cIdTit,;				//	2
					SE2->E2_CODRET,;		//	3
					SM0->M0_NOMECOM,;		//	4
					SE2->E2_VENCTO,;		//	5
					SE2->E2_SALDO,;			//	6
					SE2->E2_DECRESC,;		//	7
					SE2->E2_ACRESC,;		//	8
					SE2->E2_EMISSAO,;		//	9
					SE2->E2_IDCNAB})		//	10
				Endif
			Endif
		Endif
	Next
	
	aSort(aDetDarf,,,{|x,y| x[1] < y[1]})
	
	For nX5 := 1 To Len(aDetDarf)
		If Alltrim(cTp) <> Alltrim(aDetDarf[nX5,1])
			If nX5 > 1
				sfTreiDarf()
			Endif
			sfCabDarf()
		Endif
		cTp := aDetDarf[nX5,1]
		sfDetDarf()
	Next

	sfTreiimp()

Return


/*/{Protheus.doc} sfCabDarg (Registro Header de Lote - Pagamento de Tributos DARF)
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfCabDarf()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	cCpo := "399"      															//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)													//	004-007 9(04) Codigo do Lote
	cCpo += "1"      															//	008-008 9(01) Tipo de Registro
	cCpo += "C"      															//	009-009 X(01) Tipo de Operacao C=Credito
	cCpo += "22"			  													//	010-011 9(02) Tipo de Pagamento 20=Pagamento Fornecedores
	cCpo += aDetDarf[nX5,1] 													// 	012-013 9(02) Forma de Lançamento
	cCpo += "020" 																// 	014-016 9(03) Nr.Versao Layout
	cCpo += Space(1)   															// 	017-017 X(01) Brancos
	cCpo += "2" 																// 	018-018 9(01) Tipo Inscr.Empresa 1=CPF 2=CNPJ
	cCpo += SUBS(SM0->M0_CGC,1,14)   											// 	019-032 9(14) Nr. Inscr.Empresa
	cCpo += "892882"															// 	033-038 9(06) Número do Contrato
	cCpo += Space(14)      														// 	039-052 X(14) Brancos
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)  									//	053-057 9(05) Agencia 
	cCpo += Space(1)      														// 	058-058 X(01) Brancos
	cCpo += "000000"+ Substr(SEE->EE_CONTA,1,6)                           		// 	059-070 9(12) Conta
	cCpo += Substr(SEE->EE_CONTA,7,1)                                   		//	071-071 X(01) Dig.Verif.Conta
	cCpo += Space(1)    														// 	072-072 X(01) Brancos
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  										// 	073-102 X(30) Razao Social
	cCpo += Space(40)    														// 	103-142 X(40) Mensagem Marketing
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 										// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  										//	173-177 X(05) Numero do Local
	cCpo += Space(15)   														// 	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  										// 	193-212 X(20) Cidade
	cCpo += Substr(SM0->M0_CEPCOB,1,5)											// 	213-217 9(05) CEP
	cCpo += Substr(SM0->M0_CEPCOB,6,3)											// 	218-220 9(03) CEP Complemento
	cCpo += Substr(SM0->M0_ESTCOB,1,2)											// 	221-222 X(02) Sigla do Estado
	cCpo += "N"			     													// 	223-223 X(01) Emissao em lote S=Sim ou N=Nao
	cCpo += Space(17)  															//	224-240 X(17) Brancos
	
	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfDetimp (Registro Detalhe - Segmento N - Obrigatorio - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
@author MarceloLauschner
@since 13/12/2013
@version 1.0		
@return Sem Retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfDetDarf()
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	cCpo := "399"      																//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)														//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																//	008-008 9(01) Tipo de Registro
	cCpo += Strzero(nConta,5)	  													//	009-013 9(05) Numero de registro
	cCpo += "N" 																	// 	014-014 X(01) Segmento
	cCpo += "0" 																	// 	015-015 9(03) Tipo de Movimento - Inclusao
	cCpo += "00" 																	// 	016-017 9(03) Codigo Inst.Mov
	cCpo += StrZero(Val(aDetDarf[nX5,10]),16)										// 	018-033 9(16) Seu Numero
	cCpo += Space(4) 																// 	034-037 9(04) Brancos
	cCpo += Space(20)																// 	038-057 9(20) Nosso Numero ????????????
	cCpo += Substr(SM0->M0_NOMECOM,1,30)											// 	058-087 9(30) Nome Contribuinte
	cCpo += GravaData(aDetDarf[nX5,5],.F.,5)   										// 	088-095 9(08) Data Pag
	cCpo += Strzero((aDetDarf[nX5,6]-aDetDarf[nX5,7]+aDetDarf[nX5,8])*100,15) 		// 	096-110 9(13)V9(02) Valor Pag
	cCpo += PadR(Substr(aDetDarf[nX5,3],1,4),6)										//	111-116 9(06) Codigo receita
	cCpo += "01" 																	// 	117-118 9(01) Tipo de inscricao Contribuinte 01=CNPJ 02=CPF
	cCpo += Substr(SM0->M0_CGC,1,14)  	 											// 	119-132 9(14) CNPJ empresa Debitada
	cCpo += "16"  	 																// 	133-134 9(02) Identif.Tributo
	cCpo += GravaData(LastDay(aDetDarf[nX5,9]),.F.,5) 								//	135-142 9(08) Periodo Apuração
	cCpo += Space(17)																//	143-159 X(17) Num.Referencia
	cCpo += Strzero(aDetDarf[nX5,6]*100,15) 										// 	160-174 9(13)V9(02) Valor Principal
	cCpo += Replicate("0",15) 														// 	175-189 9(13)V9(02) Valor Multa
	cCpo += Strzero(aDetDarf[nX5,8],15) 											// 	190-204 9(13)V9(02) Valor Juros Encargos
	cCpo += GravaData(aDetDarf[nX5,5],.F.,5)   										// 	205-212 9(08) Data Vencimento
	cCpo += Space(17) 																// 	213-229 X(17) Brancos
	cCpo += "N" 																	// 	230-230 X(01) Compr.Pag
	cCpo += Space(10) 																// 	231-240 X(10) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

	nValpg += aDetDarf[nX5,6]-aDetDarf[nX5,7]+aDetDarf[nX5,8]

Return


/*/{Protheus.doc} sfTreiDarf (Registro Trailler de Lote - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfTreiDarf()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	cCpo := "399"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "5"      																		//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 																		// 	009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 															// 	018-023 9(06) Numero de arquivos
	cCpo += Space(3) 																		// 	024-026 X(03) Brancos
	cCpo += Strzero(nValpg,15)  															// 	027-041 9(13)V9(02) Valor total dos pagamentos
	cCpo += Space(199)																		// 	042-240 X(199) Brancos

	nContTot += nConta+2
	nConta := 0
	nValpg := 0


	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return

/*/{Protheus.doc} sfTrailer (long_description)
@author MarceloLauschner
@since 13/12/2013
@version 1.0		
@return Sem retorno
@example (examples)
@see (links_or_references)
/*/
Static Function sfTrailer()

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	cCpo := "399"      														//	001-003 9(03) Codigo do Banco
	cCpo += "9999" 															//	004-007 9(04) Codigo do Lote
	cCpo += "9"      														//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 														// 	009-017 X(09) Brancos
	cCpo += Strzero(nContLot,6) 											// 	018-023 9(06) Quantidade de lotes
	cCpo += Strzero(nContTot+2,6) 											// 	024-029 9(06) Quantidade total de registros
	cCpo += Space(211) 														// 	030-240 X(211) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		Endif
	Endif

Return


/*/{Protheus.doc} sfGrvE2IDCNAB (long_description)
@author MarceloLauschner
@since 26/12/2013
@version 1.0		
@return Sem retorno 
@example (examples)
@see (links_or_references)
/*/
Static Function sfGrvE2IDCNAB()

	Local	cIdCnab
	Local	aOrdSE2

	If Empty(SE2->E2_IDCNAB) // So gera outro identificador, caso o titulo ainda nao o tenha
			// Gera identificador do registro CNAB no titulo enviado
		cIdCnab := GetSxENum("SE2", "E2_IDCNAB","E2_IDCNAB"+cEmpAnt,11)
				
		dbSelectArea("SE2")
		aOrdSE2 := SE2->(GetArea())
		dbSetOrder(11)
		While SE2->(MsSeek(xFilial("SE2")+cIdCnab))
			If ( __lSx8 )
				ConfirmSX8()
			EndIf
			cIdCnab := GetSxENum("SE2", "E2_IDCNAB","E2_IDCNAB"+cEmpAnt,11)
		EndDo
			
		SE2->(RestArea(aOrdSE2))
		Reclock("SE2")
		SE2->E2_IDCNAB := cIdCnab
		MsUnlock()
		ConfirmSx8()
	Endif
		
Return
