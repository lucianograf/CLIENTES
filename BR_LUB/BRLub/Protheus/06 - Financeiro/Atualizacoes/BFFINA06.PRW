#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} BFFINA06
//TODO Descrição auto-gerada.
@author marce
@since 22/06/2018
@version 1.0
@return Nil 
@type function
/*/
User Function BFFINA06()

	Local		lContinua	:= .F.
	Local		oDlg1
	Local	 	cArq 		:= Space(30)
	Local	 	cBord 		:= Space(6)

	@ 001,001 TO 180,395 DIALOG oDlg1 TITLE OemToAnsi("Geração de Arquivo Sispag - Safra") 
	@ 002,010 TO 070,190
	@ 010,018 SAY "Nome do Arquivo:"
	@ 010,120 Get cArq Size 40,10
	@ 030,018 SAY "Informe o Bordero:"
	@ 030,120 Get cBord Size 10,10
	@ 075,133 BMPBUTTON TYPE 01 Action(lContinua := .T.,oDlg1:End())
	@ 075,163 BMPBUTTON TYPE 02 ACTION oDlg1:End()

	ACTIVATE MSDIALOG oDlg1 CENTERED

	If lContinua
		sfExec(cArq,cBord)
	Endif

Return Nil


/*/{Protheus.doc} sfExec
(Funcao que executa a geracao do arquivo apos confirmar)
@author Marcelo Alberto Lauschner
@since 13/12/2013
@version 1.0
@return Sem retorno
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExec(cArq,cBord)

	Local		cEOL      	:= "CHR(13)+CHR(10)"
	Local		nTamLin
	Local		cLin
	Local		cCpo
	Local		cQry
	Private 	nX1,nX2,nX3,nX4
	Private		aDoc 		:= {}
	Private 	aDetImp 	:= {}
	Private		aTit 		:= {}
	Private		aCon 		:= {}
	Private		aDetCon 	:= {}
	Private 	nRegs  		:= 0
	Private 	nConta 		:= 0
	Private		cTp 		:= Space(4)
	Private		nValpg 		:= 0
	Private		nContTot 	:= 0
	Private 	nContLot 	:= 0
	Private 	cArqTxt 	:= "C:\EDI\SAFRA\"+AllTrim(cArq)+".TXT"
	Private 	nHdl      	:= fCreate(cArqTxt)
	
	MakeDir("C:\EDI\SAFRA\")
	
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
	If DbSeek(xFilial("SEE")+"422" + "0067 " + "0136450   " +"001")
		RecLock("SEE",.F.)
		SEE->EE_ULTDSK	:= StrZero(Val(SEE->EE_ULTDSK)+1,6)
		MsUnlock()
	Else
		MsgAlert("Não foi encontrada a configuração de Parâmetros para a conta '422-0067-0136450' ")
		Return .F.
	Endif

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	// Layout contido na página 08 Sispag Febraban 240
	cCpo := "422"      																					//	001-003 9(03) G001 Codigo do Banco
	cCpo += "0000"    																					//	004-007 9(04) G002 Codigo do Lote
	cCpo += "0"      																					//	008-008 9(01) G003 Tipo de Registro
	cCpo += Space(9) 																					//	009-017 X(09) G004 Brancos
	cCpo += "2" 																						// 	018-018 9(01) G005 Tipo de inscriçã0 1=CPF 2=CNPJ
	cCpo += StrZero(Val(SM0->M0_CGC),14)																// 	019-032 9(14) G006 A CONFIRMAR CGC
	cCpo += Space(20)   																				// 	033-052 X(20) G007 Código do Convênio Banco
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)									 							// 	053-057 9(05) G008 Agencia (5)
	cCpo += Space(1)    																				// 	058-058 X(01) G009 DV Agencia 
	cCpo += StrZero(Val(Substr(SEE->EE_CONTA,1,6)),12)		                           					// 	059-070 9(12) G010 Conta
	cCpo += "0"		    																				// 	071-071 X(01) G011 DV Conta Branco
	cCpo += "0"									                                   						//	072-072 9(01) G012 DV Ag./Conta
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  																// 	073-102 X(30) G013 Razao Social
	cCpo += Padr("BANCO SAFRA S/A",30)  																// 	103-132 X(30) G014 Nome Banco
	cCpo += Space(10) 																					// 	133-142 X(10) G004 Branco
	cCpo += "1" 																						// 	143-143 9(01) G015 1= Remessa 2=Retorno
	cCpo += GravaData(dDataBase,.F.,5)																	//	144-151 9(08) G016 Data geração do arquivo DDMMAAAA
	cCpo += Alltrim(StrTran(Time(),":"))																// 	152-157 9(06) G017 Hora geração HHMMSS
	cCpo += StrZero(Val(SEE->EE_ULTDSK),6)																//	158-163 9(06) G018 Sequencia de Geração do arquivo
	cCpo += "103"		 																				//	164-166 9(03) G019 N da Versão Layout
	cCpo += Replicate("0",5) 																			//	167-171 9(05) G020 Densidade - Zeros
	cCpo += Space(20)																					// 	172-191 X(20) G021 Uso Reservado Banco	
	cCpo += Space(20)																					// 	192-211 X(20) G021 Uso Reservado Empresa
	cCpo += Space(29)																					//	212-240 X(69) G004 Uso Exclusivo Febraban - Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
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

		If QRY->E2_FORNECE $ ("UNIAO #INPS  ") // Impostos sem codigo de barras
			MsgInfo("Título de Imposto " + QRY->E2_PREFIXO + " " + QRY->E2_NUM + " Não será adicionado ao arquivo Safra pois o Banco não trabalha com Pagto Imposto2!")
		Elseif !Empty(QRY->E2_CODBAR) .And. Substr(QRY->E2_CODBAR,1,1) = "8" // Titulos concessionarias
			MsgInfo("Título de Imposto " + QRY->E2_PREFIXO + " " + QRY->E2_NUM + " Não será adicionado ao arquivo Safra pois o Banco não trabalha com Pagto de Faturas de Concessionárias!")
		Elseif !Empty(QRY->E2_CODBAR) .And. Len(Alltrim(QRY->E2_CODBAR)) < 48 // Titulos com codigo de Barras
			Aadd(aTit,{;
			QRY->E2_PREFIXO,;			//	1
			QRY->E2_NUM,;				//	2
			QRY->E2_PARCELA,;			//	3
			QRY->E2_TIPO,;				//	4
			QRY->E2_FORNECE,;			//	5
			QRY->E2_LOJA})				//	6

		Else  // DOCS E TEDS
			Aadd(aDoc,{;
			QRY->E2_PREFIXO,;			//	1
			QRY->E2_NUM,;				//	2
			QRY->E2_PARCELA,;			//	3
			QRY->E2_TIPO,;				//	4
			QRY->E2_FORNECE,;			//	5
			QRY->E2_LOJA})				//	6

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

	sfTrailer(nHdl,nContLot,nContTot)

	fClose(nHdl)
	
	MsgInfo("Arquivo Gerado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	
	ShellExecute("open","C:\EDI\SAFRA\","","C:\EDI\SAFRA\",1)
	
Return

/*/{Protheus.doc} sfDoc
(Grava registros referente a DOCs e TEDs)
@author MarceloLauschner
@since 12/12/2013
@version 1.0
@return Sem retorno
@example
(examples)
@see (links_or_references)
/*/
Static function sfDoc()

	Local		cEOL      	:= "CHR(13)+CHR(10)"
	Local		x
	Local		cIdTit		
	Local		cTipPg		:= ""
	Local		cForPg		:= ""
	Local		aDetDoc		:= {}
	Local		nX1
	Local		cTp			:= ""
	Local		cCodCamC	:= "018"
	
	nConta := 0
	nValpg := 0

	For x := 1 To Len(aDoc)

		// Posiciona no Título
		DbSelectArea("SE2")
		DbSetOrder(1)	//E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA		
		If dbSeek(xFilial("SE2")+aDoc[x][1]+aDoc[x][2]+aDoc[x][3]+aDoc[x][4]+aDoc[x][5]+aDoc[x][6])
			// Verifica se o título tem IDCNAB
			// Para permitir a tratativa no retorno bancário
			sfGrvE2IDCNAB()
			// Posiciona no Fornecedor
			DbSelectArea("SA2")
			DbSetOrder(1) // A2_FILIAL+A2_COD+A2_LOJA
			If dbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)

				cIdtit  := aDoc[x][1]+aDoc[x][2]+aDoc[x][3]+aDoc[x][4]+aDoc[x][5]+aDoc[x][6]

				If Alltrim(SE2->E2_NATUREZ)=="SALARIOS" .And. SA2->A2_BANCO == '422' 
					cTipPg := "30"	// Pagamento de Salários
				Else
					cTipPg := "20"	// Pagamento de Fornecedor
				Endif

				If SA2->A2_BANCO == '422'	//Forma de Pagamento Safra
					cForPg 		:= "01"		// CREDITO EM CONTA CORRENTE/SALARIO
					cCodCamC	:= "000"
				ElseIf SE2->E2_SALDO >= 250	//VER QUESTAO DO ACRES E DECRES
					cForPg 		:= "41"		// TED OUTRO TITULAR
					cCodCamC	:= "018"
				Else
					cForPg 		:= "03" 		// DOC/TED (1)(2),
					cCodCamC	:= "700"
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
					SE2->E2_IDCNAB,;		// 	14
					SA2->A2_END,;			//  15
					SA2->A2_NR_END,;		//  16
					SA2->A2_COMPLEM,;		//  17
					SA2->A2_BAIRRO,;		//  18
					SA2->A2_MUN,;			//  19
					SA2->A2_CEP,;			//  20
					SA2->A2_EST,;			//  21
					SE2->E2_MULTA,;			//  22
					SE2->E2_JUROS,;			//  23	
					cCodCamC})				//  24
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
			sfCabDoc(nX1,aDetDoc)
		Endif
		cTp := aDetDoc[nX1,1]+aDetDoc[nX1,2]
		sfSegmA(aDetDoc,nX1)
		sfSegmB(aDetDoc,nX1)
	Next

	sfTreiDoc()

Return



/*/{Protheus.doc} sfCabDoc
(Monta texto do Cabeçalho para os registros DOC/TED)
@author Marcelo Lauschner
@since 12/12/2013
@version 1.0
@return Sem retorno
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCabDoc(nX1,aDetDoc)

	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	nTamLin
	Local	cLin
	Local	cCpo
	Local	cQry
	
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++

	// Layout contido na página 09 Sispag Febraban 240
	cCpo := "422"      																					//	001-003 9(03) G001 Codigo do Banco
	cCpo += Strzero(nContLot,4)																			//	004-007 9(04) G002 Codigo do Lote
	cCpo += "1"      																					//	008-008 9(01) G003 Tipo de Registro
	cCpo += "C"      																					//	009-009 X(01) G028 Tipo de Operacao = C credito
	cCpo += aDetDoc[nX1,1]  																			//	010-011 9(02) G025 Tipo de Pagamento
	cCpo += aDetDoc[nX1,2] 																				// 	012-013 9(02) G029 Forma de Lançamento 
	cCpo += "046" 																						// 	014-016 9(03) G030 lay out do lote
	cCpo += Space(1)   																					// 	017-017 X(01) G004 Brancos
	cCpo += "2" 																						// 	018-018 9(01) G005 Tipo de inscricao em debitada 1=CPF 2=CGC
	cCpo += StrZero(Val(SM0->M0_CGC),14) 																// 	019-032 9(14) G006 CNPJ empresa Debitada
	cCpo += Space(20)   																				// 	033-052 X(20) G007 Código do Convênio Banco
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)									 							// 	053-057 9(05) G008 Agencia (5)
	cCpo += Space(1)    																				// 	058-058 X(01) G009 DV Agencia 
	cCpo += StrZero(Val(Substr(SEE->EE_CONTA,1,6)),12)		                           					// 	059-070 9(12) G010 Conta
	cCpo += "0"		    																				// 	071-071 X(01) G011 DV Conta Branco
	cCpo += Space(1)							                                   						//	072-072 9(01) G012 DV Ag./Conta
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  																// 	073-102 X(30) G013 Razao Social


	cCpo += Space(40) 																					// 	103-142 X(40) G031 Mensagem
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 																// 	143-172 X(30) G032 Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  																//	173-177 9(05) G032 Numero do Local
	cCpo += Space(15)   																				// 	178-192 X(15) G032 Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  																// 	193-212 X(20) G032 Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,5)																	// 	213-217 9(08) G034 CEP
	cCpo += Substr(SM0->M0_CEPCOB,6,3)																	// 	218-220 9(03) G035 CEP
	cCpo += Substr(SM0->M0_ESTCOB,1,2)																	// 	221-222 X(02) G036 Sigla do Estado
	cCpo += Space(2)																					//  223-224 9(02) P014 01-Debito em Conta Corrente 
	cCpo += Space(6)      																				// 	225-230 X(06) G004 Brancos
	cCpo += Space(10)  																					//	231-240 X(10) G059 Ocorrencias - Branco

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif

Return .T. 


/*/{Protheus.doc} sfDetDoc
(Monta dados de detalhes do grupo DOC/TED)
@author Marcelo Lauschner
@since 12/12/2013
@version 1.0
@return Sem retorno
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSegmA(aDetDoc,nX1)

	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	nTamLin
	Local	cCpo
	Local	cLin
	Local	cQry 
	
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 25 Sispag Febraban 240
	cCpo := "422"      																					//	001-003 9(03) G001 Codigo do Banco
	cCpo += Strzero(nContLot,4)																			//	004-007 9(04) G002 Codigo do Lote
	cCpo += "3"      																					//	008-008 9(01) G003 Tipo de Registro
	cCpo += Strzero(nConta,5)	  																		//	009-013 9(05) G038 Numero de registro
	cCpo += "A" 																						// 	014-014 X(01) G039 Segmento
	cCpo += "0" 																						// 	015-015 9(01) G060 Tipo de Movimento - Inclusao
	cCpo += "00" 																						// 	016-017 9(02) G061 Codigo Instrução Movimento '00' = Inclusão de Registro Detalhe Liberado 
	cCpo += aDetDoc[nX1,24]																				// 	018-020 9(03) P001 Zeros
	cCpo += aDetDoc[nX1,4]  																			// 	021-023 9(03) P002 Banco do Favorecido
	cCpo += Strzero(Val(aDetDoc[nX1,5]),5) 																// 	024-028 9(05) G008 Agencia do favorecido
	cCpo += Space(1)  																					// 	029-029 X(01) G009 DV da Agencia Brancos
	cCpo += Strzero(Val(aDetDoc[nX1,6]),12) 															// 	030-041 9(12) G010 Conta
	If Len(Alltrim(aDetDoc[nX1,7])) == 2
		cCpo += Padr(Substr(Alltrim(aDetDoc[nX1,7]),1,2),2)												//  042-042 X(01) G011 Complemento - Brancos
																										//  043-043 X(01) G012 DAC da Agencia/Conta creditada
	Else
		cCpo += Space(1)  																				// 	042-042 X(01) G011 Complemento - Brancos
		cCpo += Padr(Substr(Alltrim(aDetDoc[nX1,7]),1,1),1)												// 	043-043 X(01) G012 DAC da Agencia/Conta creditada
	Endif
	cCpo += Substr(aDetDoc[nX1,8],1,30)																	// 	044-073 X(30) G013 Nome do Favorecido
	cCpo += Padr(aDetDoc[nX1,14],20)																	// 	074-093 X(20) G014 Nro Doc empresa
	cCpo += GravaData(aDetDoc[nX1,9],.F.,5)																//	094-101 9(08) P009 Data de pagto - DDMMAAAA
	cCpo += "BRL" 																						// 	102-104 X(03) G040 Moeda
	cCpo += Replicate("0",15) 																			// 	105-119 9(15) G041 Quantidade da MoedaZeros
	cCpo += Strzero(((aDetDoc[nX1,10]-aDetDoc[nX1,11]+aDetDoc[nX1,12])*100),15)							// 	120-134 9(13)V9(02) P010 Valor Pgto
	cCpo += Space(20) 																					// 	135-154 X(20) G043 Brancos
	cCpo += Replicate("0",8) 																			// 	155-162 9(08) P003 Data Efetiva - Zeros
	cCpo += Replicate("0",15) 																			// 	163-177 9(13)V9(02) P004 Valor Efetivo Zeros
	cCpo += Space(40) 																					// 	178-217 X(40) G031 Informação 2
	cCpo += Space(2)																					// 	218-219 X(02) P005 Finalidade Doc
	cCpo += Space(5)																					// 	220-224 X(05) P011 Finalidade TED
	cCpo += Space(2)																					// 	225-226 X(02) P013 Complemento Finalidade pgto
	cCpo += Space(3)   																					// 	227-229 X(03) G004 Brancos
	cCpo += "0" 																						// 	230-230 X(01) P006 Aviso ao Favorecedo - 0=Não Emite Aviso
	cCpo += Space(10) 																					// 	231-240 X(10) G059 Ocorrencias

	cLin := Stuff(cLin,01,240,cCpo)
	//	MsgAlert(cValToChar(aDetDoc[nX1,10]) + " - " + cValToChar(aDetDoc[nX1,11]) + " - " + cValToChar(aDetDoc[nX1,12]))

	nValpg += aDetDoc[nX1,10]-aDetDoc[nX1,11]+aDetDoc[nX1,12]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif


Return .T. 


Static Function sfSegmB(aDetDoc,nX1)

	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	nTamLin
	Local	cCpo
	Local	cLin
	Local	cQry 

	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 25 Sispag Febraban 240
	cCpo := "422"      																					//	001-003 9(03) 	G001 Codigo do Banco
	cCpo += Strzero(nContLot,4)																			//	004-007 9(04) 	G002 Codigo do Lote
	cCpo += "3"      																					//	008-008 9(01) 	G003 Tipo de Registro
	cCpo += Strzero(nConta,5)	  																		//	009-013 9(05) 	G038 Numero de registro
	cCpo += "B" 																						// 	014-014 X(01) 	G039 Segmento
	cCpo += Space(3)																					// 	015-017 X(03) 	G004 Brancos Uso Exclusivo Frebraban
	cCpo += Iif(Len(aDetDoc[nX1,13]) == 14,"2",IIf(Len(aDetDoc[nX1,13]) == "9","1","9"))				// 	018-018 9(01) 	G005 Tipo de Inscrição Favorecido '0' = Isento / Não Informado  1' = CPF  '2' = CGC / CNPJ '3' = PIS / PASEP '9' = Outros 
	cCpo += aDetDoc[nX1,13]      																		// 	019-032 9(14) 	G006 N Inscrição do Favorecido
	cCpo += Padr(aDetDoc[nX1,15],30)																	// 	033-062 X(30) 	G032 Nome da Rua,Av Favorecido
	cCpo +=	StrZero(Val(aDetDoc[nX1,16]),5)																// 	063-067 9(05) 	G032 Numero do Local
	cCpo += Padr(aDetDoc[nX1,17],15)																	// 	068-082 X(15) 	G032 Complemento 
	cCpo += Padr(aDetDoc[nX1,18],15)																	// 	083-097 X(15) 	G032 Bairro
	cCpo += Padr(aDetDoc[nX1,19],20)																	// 	098-117 X(20) 	G033 Cidade
	cCpo += Padr(aDetDoc[nX1,20],8)																		// 	118-125 X(08) 	G034/G035 CEP e Complemento CEP
	cCpo += Padr(aDetDoc[nX1,21],2)																		// 	126-127 X(02) 	G036 Sigla do Estado
	
	cCpo += GravaData(aDetDoc[nX1,9],.F.,5)																// 	128-135 9(08) 	G044 Data do Vencimento ( Nominal )
	cCpo += Strzero(((aDetDoc[nX1,10]-aDetDoc[nX1,11]+aDetDoc[nX1,12])*100),15)							// 	136-150 9(13)V2 G042 Valor do Documento
	cCpo += Strzero(0,15)					 															// 	151-165 9(13)V2 G045 Valor do Abatimento
	cCpo += Strzero(0,15)					 															// 	166-180 9(13)V2 G046 Valor do Desconto
	cCpo += Strzero(((aDetDoc[nX1,23])*100),15)															// 	181-195 9(13)V2 G047 Valor da Mora
	cCpo += Strzero(((aDetDoc[nX1,22])*100),15)															// 	196-210 9(13)V2 G048 Valor da Multa
	
	cCpo += Padr(aDetDoc[nX1,3],15)																		//  211-225 X(15) 	P008 Código/Documento Favorecido
	cCpo += "0"	 																						// 	226-226 X(01) 	P006 Código adotado pela FEBRABAN para identificar a necessidade de emissão de aviso de pagamento ao Favorecido.
																											//'0' = Não Emite Aviso
																											//'2' = Emite Aviso Somente para o Remetente
																											//'5' = Emite Aviso Somente para o Favorecido
																											//'6' = Emite Aviso para o Remetente e Favorecido
																											//'7' = Emite Aviso para o Favorecido e 2 Vias para o Remetente
	cCpo += Space(6) 																					// 	227-232 X(06) 	P012 Uso Exclusivo para o SIAPE
	cCpo += Space(8)																					// 	233-240 X(08) 	P015 Código ISPB
	
	cLin := Stuff(cLin,01,240,cCpo)
	//	MsgAlert(cValToChar(aDetDoc[nX1,10]) + " - " + cValToChar(aDetDoc[nX1,11]) + " - " + cValToChar(aDetDoc[nX1,12]))


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif


Return .T. 



/*/{Protheus.doc} sfTreiDoc
(Monta trailer do grupo DOC/TED)

@author Marcelo Lauschner
@since 12/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfTreiDoc()

	Local	nTamLin	
	Local	cCpo
	Local	cLin
	Local	cEOL      	:= "CHR(13)+CHR(10)"

	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL 	// Variavel para criacao da linha do registros para gravacao

	// Layout contido na página 18 Sispag Febraban 240
	
	cCpo := "422"      																					//	G001 001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																			//	G002 004-007 9(04) Codigo do Lote
	cCpo += "5"      																					//	G003 008-008 9(01) Tipo de Registro
	cCpo += Space(9) 																					// 	G004 009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 																		// 	G057 018-023 9(06) Numero de arquivos
	cCpo += Strzero((nValpg*100),18)  																	// 	P057 024-041 9(16)V9(02) Valor total dos pagamentos
	cCpo += Replicate("0",18) 																			// 	G058 042-059 9(13)V9(05) Somatória de Quantidade de MoedasZeros
	cCpo += Replicate("0",6)																			//  G066 060-065 9(06) 	Número Aviso de Débito	
	cCpo += Space(165)																					// 	G004 066-230 X(165) Uso Exclusivo FEBRABAN/CNAB Brancos
	cCpo += Space(10) 																					// 	G059 231-240 X(10) 	Brancos

	nContTot += nConta+2
	nConta := 0
	nValpg := 0



	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif

Return .T. 



//******************************************************************
// PAGAMENTO DE TITULOS E BLOQUETOS
//******************************************************************

/*/{Protheus.doc} sfTit
(long_description)

@author Marcelo Lauschner
@since 13/12/2013
@version 1.0

@return Sem Retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfTit()

	Local	cIdTit
	Local	aDetTit		:= {}
	Local	nX3
	Local	cTp	 		:= Space(2)
	Local	x
	
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

				If Substr(SE2->E2_CODBAR,1,3) == "422"    //Tipo de Pagamento
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
					"31",;						//	1
					cIdtit,;					//	2
					SE2->E2_CODBAR,;			//	3
					SA2->A2_NOME,;				//	4
					SE2->E2_VENCREA,;			//	5
					SE2->E2_SALDO,;				//	6
					SE2->E2_DECRESC,;			//	7
					SE2->E2_ACRESC,;			//	8
					SE2->E2_IDCNAB,;			// 	9
					SA2->A2_CGC})				// 10
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
			sfCabTit(nX3,aDetTit)
		Endif
		cTp := aDetTit[nX3,1]
		
		sfDetTiT(nX3,aDetTit)
		
		sfSegJ52(nX3,aDetTit)
	Next

	sfTreiTit()

Return


/*/{Protheus.doc} sfCabTit
(long_description)

@author Marcelo Lauschner
@since 13/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfCabTit(nX1,aDetTit)

	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	nTamLin
	Local	cCpo
	Local	nLin
	Local	cLin
	Local	cQry

	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++

	// Layout contido na página 09 Sispag Febraban 240
	cCpo := "422"      																					//	001-003 9(03) G001 Codigo do Banco
	cCpo += Strzero(nContLot,4)																			//	004-007 9(04) G002 Codigo do Lote
	cCpo += "1"      																					//	008-008 9(01) G003 Tipo de Registro
	cCpo += "C"      																					//	009-009 X(01) G028 Tipo de Operacao = C credito
	cCpo += "20"			  																			//	010-011 9(02) G025 Tipo de Pagamento
	cCpo += aDetTit[nX1,1] 																				// 	012-013 9(02) G029 Forma de Lançamento 
	cCpo += "040" 																						// 	014-016 9(03) G030 lay out do lote
	cCpo += Space(1)   																					// 	017-017 X(01) G004 Brancos
	cCpo += "2" 																						// 	018-018 9(01) G005 Tipo de inscricao em debitada 1=CPF 2=CGC
	cCpo += StrZero(Val(SM0->M0_CGC),14) 																// 	019-032 9(14) G006 CNPJ empresa Debitada
	cCpo += Space(20)   																				// 	033-052 X(20) G007 Código do Convênio Banco
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)									 							// 	053-057 9(05) G008 Agencia (5)
	//TODO Verificar se o DV da Agencia precisa ser informado
	cCpo += Space(1)    																				// 	058-058 X(01) G009 DV Agencia 
	cCpo += StrZero(Val(Substr(SEE->EE_CONTA,1,6)),12)		                           					// 	059-070 9(12) G010 Conta
	cCpo += "0"			   																				// 	071-071 X(01) G011 DV Conta Branco
	cCpo += Space(1)							                                   						//	072-072 9(01) G012 DV Ag./Conta
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  																// 	073-102 X(30) G013 Razao Social


	cCpo += Space(40) 																					// 	103-142 X(40) G031 Mensagem
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 																// 	143-172 X(30) G032 Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  																//	173-177 9(05) G032 Numero do Local
	cCpo += Space(15)   																				// 	178-192 X(15) G032 Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  																// 	193-212 X(20) G032 Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,5)																	// 	213-217 9(08) G034 CEP
	cCpo += Substr(SM0->M0_CEPCOB,6,3)																	// 	218-220 9(03) G035 CEP
	cCpo += Substr(SM0->M0_ESTCOB,1,2)																	// 	221-222 X(02) G036 Sigla do Estado
	cCpo += Space(8)      																				// 	223-230 X(06) G004 Brancos
	cCpo += Space(10)  																					//	231-240 X(10) G059 Ocorrencias - Branco

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif


Return .T. 


/*/{Protheus.doc} sfDetTit
(long_description)

@author MarceloLauschner
@since 13/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfDetTit(nX3,aDetTit)

	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	cCpo
	Local	cLin
	Local	nTamLin

	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nConta++
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 20 Sispag Febraban 240
	cCpo := "422"      																					//	001-003 9(03) 		G001 Codigo do Banco
	cCpo += StrZero(nContLot,4)																			//	004-007 9(04) 		G002 Codigo do Lote
	cCpo += "3"      																					//	008-008 9(01) 		G006 Tipo de Registro
	cCpo += StrZero(nConta,5)	  																		//	009-013 9(05) 		G038 Numero de registro
	cCpo += "J" 																						// 	014-014 X(01) 		G039 Segmento
	cCpo += "0" 																						// 	015-015 9(01) 		G060 Tipo de Movimento - '0' = Indica INCLUSÃO
	cCpo += "00"																						//	016-017 9(02)		G061 Código da Instruação para Movimento - '00' = Inclusão de Registro Detalhe Liberado
	cCpo += Substr(aDetTit[nX3,3],1,44)			 														// 	018-061 9(01) 		G063 Códigod de Barras
	cCpo += Substr(aDetTit[nX3,4],1,30) 																// 	062-091 X(30) 		G013 Nome do Favorecido
	cCpo += GravaData(aDetTit[nX3,5],.F.,5) 															// 	092-099 9(08) 		G044 Data Vencimento DDMMAAAA
	cCpo += Strzero((aDetTit[nX3,6]*100),15) 															// 	100-114 9(13)V9(02) G042 Saldo
	cCpo += Strzero((aDetTit[nX3,7]*100),15) 															// 	115-129 9(13)V9(02) L002 Descontos
	cCpo += Strzero((aDetTit[nX3,8]*100),15) 															//	130-144 9(13)V9(02) L003 Acrescimos
	cCpo += GravaData(aDetTit[nX3,5],.F.,5)																// 	145-152 9(08) 		P009 Data Pagamento DDMMAAAA
	cCpo += StrZero(((aDetTit[nX3,6]-aDetTit[nX3,7]+aDetTit[nX3,8])*100),15) 							// 	153-167 9(13)V9(02) P010 Valor do Pagamento
	cCpo += Replicate("0",15) 																			// 	168-182 9(15) 		G041 Quantidade da Moeda - Zeros
	cCpo += Padr(aDetTit[nX3,9],20)																		// 	183-202 X(20) 		G064 Id tit na empresa
	cCpo += Space(20) 																					// 	203-222 X(20) 		G043 No Doc.Atribuído pelo Banco - Brancos
	cCpo += "09"	 																					// 	223-224 X(02) 		G065 Código da Moeda - Brancos
	cCpo += Space(6) 																					// 	225-230 X(6) 		G004 Brancos
	cCpo += Space(10) 																					// 	231-240 X(10) 		G059 Código de Ocorrências p/retorno - Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	nValpg += aDetTit[nX3,6]-aDetTit[nX3,7]+aDetTit[nX3,8]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif

Return .T. 



/*/{Protheus.doc} sfSegJ52
//Geração do registro J-52 Obrigatório para pagamento de Boletos a partir de Julho/2017
//http://download.itau.com.br/bankline/SISPAG_CNAB.pdf
@author Marcelo Alberto Lauschner
@since 15/07/2017
@version 6

@type function
/*/
Static Function sfSegJ52(nX3,aDetTit)
	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	cCpo
	Local	cLin
	Local	nTamLin
	
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	// Layout contido na página 22 Sispag Febraban 240
	//Observações:  
	//A partir do dia 10/07/2017, o registro detalhe J-52 passará a ser obrigatório para pagamentos de boletos 
	//emitidos pelo Itaú e por outros bancos (formas “30 – boletos Itaú” e “31 – boletos outros bancos”).
	//O registro deve vir sempre após o respectivo segmento J. Caso utilize o segmento B e C 
	//obedecer à ordem dos registros (J, J-52, B, C).
	//O que muda a partir do dia 10/07/2017?  A partir dessa data, os boletos incluídos ou agendados para 
	//pagamento sem preenchimento correto do registro detalhe J-52, serão rejeitados (ocorrência “BI” – CNPJ / CPF do favorecido no segmento J-52 ou BI inválido).

	cCpo := "422"      																		//	001-003 9(03) G001 Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) G002 Codigo do Lote
	cCpo += "3"      																		//	008-008 9(01) G003 Tipo de Registro
	cCpo += StrZero(nConta,5)	  															//	009-013 9(05) G038 Numero de registro
	cCpo += "J" 																			// 	014-014 X(01) G039 Código Segmento Detalhe Reg.Detalhe
	cCpo += " " 																			// 	015-015 X(01) G004 Uso Exclusivo Febraban - Brancos
	cCpo += "00" 																			// 	016-017 9(02) C004 Código do Movimento - Inclusao
	cCpo += "52"																			//  018-019 9(02) G057 Identificação Registro Opcional
	cCpo += "2"																				//  020-020 9(01) G005 Tipo de Inscrição do Pagador 1-Cpf / 2-Cnpj
	cCpo += StrZero(Val(SM0->M0_CGC),15)													// 	021-035 9(15) G006 Número de Inscrição do Pagador Nota 36 
	cCpo += Substr(SM0->M0_NOMECOM,1,40)  													// 	036-075 X(40) G013 Nome do Pagador
	cCpo += IIf(Len(Alltrim(aDetTit[nX3,10])) < 14,"1","2" )								// 	076-076 9(01) G005 Tipo de Inscrição do Beneficiário 1-Cpf / 2-Cnpj
	cCpo += StrZero(Val(aDetTit[nX3,10]),15)												// 	077-091 9(15) G006 Número de Inscrição do Beneficiário Nota 36
	cCpo += Substr(aDetTit[nX3,4],1,40) 													// 	092-131 X(40) G013 Nome do Beneficiário
	cCpo += "0"																				// 	132-132	9(01) G005 Tipo de Incrição do Sacador Avalista 1-Cpf / 2-Cnpj
	cCpo += StrZero(0,15)																	//	133-147 9(15) G006 Número de Inscrição do Sacador Avalista Nota 36
	cCpo += Space(40)																		// 	148-187 X(40) G013 Nome do Sacador Avalista
	cCpo += Space(53)																		//	188-240	X(53) G004 Brancos - Complemento de Registro
	
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

/*/{Protheus.doc} sfTreiTit
(long_description)

@author MarceloLauschner
@since 13/12/2013
@version 1.0

@return Sem Retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfTreiTit()

	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	nTamLin
	Local	cLin
	Local	cCpo

	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	// Layout contido na página 26 Sispag Febraban 240
	cCpo := "422"      																		//	001-003 9(03) 		G001 Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) 		G002 Codigo do Lote
	cCpo += "5"      																		//	008-008 9(01) 		G003 Tipo de Registro
	cCpo += Space(9) 																		// 	009-017 X(09) 		G004 Brancos
	cCpo += StrZero(nConta+2,6) 															// 	018-023 9(06) 		G057 Numero de arquivos
	cCpo += Strzero((nValpg*100),18)  														// 	024-041 9(16)V9(02) L001 Valor total dos pagamentos
	cCpo += Replicate("0",18) 																// 	042-059 9(18)		G058 Zeros
	cCpo += Space(171) 																		// 	060-230 X(171) 		G004 Uso Exclusivo Febraban - Brancos
	cCpo += Space(10) 																		// 	231-240 X(10) 		G059 Código de Ocorrências para REtorno - Brancos

	nContTot += nConta+2
	nConta := 0
	nValpg := 0



	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif

Return .T. 


/*/{Protheus.doc} sfTrailer
(long_description)

@author MarceloLauschner
@since 13/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfTrailer(nHdl,nContLot,nContTot)

	Local	cEOL      	:= "CHR(13)+CHR(10)"
	Local	nTamLin
	Local	cLin
	Local	cCpo
	
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 18 Sispag Febraban 240
	cCpo := "422"      																					//	G001 001-003 9(03) Codigo do Banco
	cCpo += "9999" 																						//	G002 004-007 9(04) Codigo do Lote Default 9999 no Trailler Arquivo
	cCpo += "9"      																					//	G003 008-008 9(01) Tipo de Registro
	cCpo += Space(9) 																					// 	G004 009-017 X(09) Brancos
	cCpo += StrZero(nContLot,6) 																		// 	G049 018-023 9(06) Quantidade de lotes
	cCpo += StrZero(nContTot+2,6) 																		// 	G056 024-029 9(06) Quantidade total de registros
	cCpo += StrZero(0,6)																				//  G037 030-035 9(06) Quantidade de contas p/Conc.(Lotes)
	cCpo += Space(205) 																					// 	G004 036-240 X(205) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If MsgYesNo("Ocorreu um erro na gravação do arquivo. Continua?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return .F. 
		Endif
	Endif

Return .T. 


/*/{Protheus.doc} sfGrvE2IDCNAB
(long_description)

@author MarceloLauschner
@since 26/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

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
