#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} ONFINA02
Rotina para geração do arquivo sispag de pagamentos para banco Itaú
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 12/14/2013
/*/
User Function ONFINA02()
	
	Local lContinua  := .F.

	Private cArq     := Space(30)
	Private cBord    := Space(6)
	Private dDtPagto := dDataBase
	Private cBco     := Space( TAMSX3( 'A6_COD'     )[1] )
	Private cAge     := Space( TAMSX3( 'A6_AGENCIA' )[1] )
	Private cCta     := Space( TAMSX3( 'A6_NUMCON'  )[1] )

  
	@ 200,1 TO 400,450 DIALOG oDlg1 TITLE OemToAnsi("Envio de Pedido")
	@ 02,10 TO 085,220
	@ 10,018 SAY "Nome do Arquivo:"
	@ 10,080 Get cArq Size 40,10
	
	@ 30,018 SAY "Informe o Bordero:"
	@ 30,080 Get cBord Size 10,10
	
	@ 45,018 SAY "Data Validação Pagto:"
	@ 45,080 Get dDtPagto Size 40,10
	
	@ 60,018 SAY "Banco/Agencia/Conta:"
	@ 60,080 Get cBco Size 20,10 VALID cBco == '341' F3 "SA6"
	@ 60,110 Get cAge Size 30,10 WHEN .F.
	@ 60,150 Get cCta Size 40,10 WHEN .F.

	@ 90,150 BMPBUTTON TYPE 01 Action(lContinua := .T.,oDlg1:End())
	@ 90,190 BMPBUTTON TYPE 02 ACTION oDlg1:End()

	ACTIVATE MSDIALOG oDlg1 CENTERED

	If lContinua
		sfExec()
	Endif

Return

/*/{Protheus.doc} sfExec
Executa geração do arquivo após confirmação do usuário
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 12/13/2013
/*/
Static Function sfExec()

	Local		lAddReg		:= .F.
	Local		cLin
	Local		cCpo
	Local		cQry

	Private 	nX1,nX2,nX3,nX4
	Private		aDoc 		:= {}
	Private		aDetDoc 	:= {}
	Private 	aImp 		:= {}
	Private 	aDetImp 	:= {}
	Private		aTit 		:= {}
	Private		aDetTit 	:= {}
	Private		aCon 		:= {}
	Private		aDetCon 	:= {}
	Private 	nRegs  		:= 0
	Private 	nConta 		:= 0
	Private		cTp 		:= Space(4)
	Private		nValpg 		:= 0
	Private		nContTot 	:= 0
	Private 	nContLot 	:= 0
	Private 	cEOL      	:= "CHR(13)+CHR(10)"

	
	MakeDir("C:\EDI\ITAU\")
	
	Private 	cArqTxt 	:= "C:\EDI\ITAU\"+AllTrim(cArq)+".TXT"
	Private 	nHdl      	:= fCreate(cArqTxt)

	// Cria o arquivo texto                                                
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
	dbSetOrder(1)			// EE_FILIAL + EE_CODIGO + EE_AGENCIA + EE_CONTA
	If !DbSeek(xFilial("SEE")+ cBco + cAge + cCta )
		MsgAlert("Não foi encontrada a configuração de Parâmetros para o banco <b>"+ cBco +"</b>, agência <b>"+ cAge +"</b> e conta <b>"+ cCta +"</b>!", 'Parâmetros de Banco não Localizados')
		Return .F.
	Endif

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 08 Sispag Febraban 240
	cCpo := "341"      																//	001-003 9(03) Codigo do Banco
	cCpo += "0000"    																//	004-007 9(04) Codigo do Lote
	cCpo += "0"      																//	008-008 9(01) Tipo de Registro
	cCpo += Space(6) 																//	009-014 X(06) Brancos
	cCpo += "080"   																//	015-017 9(03) Layout
	cCpo += "2" 																	// 	018-018 9(01) Tipo de inscriçã0 1=CPF 2=CNPJ
	cCpo += SM0->M0_CGC 															// 	019-032 9(14) A CONFIRMAR CGC
	cCpo += Space(20)   															// 	033-052 X(20) Brancos
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)									 		// 	053-057 9(05) Agencia (5)
	cCpo += Space(1)    															// 	058-058 X(01) Branco
	cCpo += "0000000"+ Substr(SEE->EE_CONTA,1,5)                           			// 	059-070 9(12) Conta
	cCpo += Space(1)    															// 	071-071 X(01) Branco
	cCpo += Substr(SEE->EE_CONTA,6,1)                                   			//	072-072 9(01) Digitocc
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  											// 	073-102 X(30) Razao Social
	cCpo += Padr("BANCO ITAU S/A",30)  												// 	103-132 X(30) Nome Banco
	cCpo += Space(10) 																// 	133-142 X(10) Branco
	cCpo += "1" 																	// 	143-143 9(01) 1= Remessa 2=Retorno
	cCpo += GravaData(dDataBase,.F.,5)												//	144-151 9(08) Data geração do arquivo DDMMAAAA
	cCpo += Alltrim(StrTran(Time(),":"))											// 	152-157 9(06) Hora geração HHMMSS
	cCpo += Replicate("0",9) 														//	158-166 9(09) Zeros
	cCpo += Replicate("0",5) 														//	167-171 9(05) Densidade - Zeros
	cCpo += Space(69)																//	172-240 X(69) Brancos

	cLin := Stuff(cLin,01,240,cCpo)

	// Gravacao no arquivo texto. Testa por erros durante a gravacao da  
	// linha montada.                                                      
	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		MsgAlert("Ocorreu um erro na gravacao do arquivo, o processo será abortado!","Atencao!")
		return Nil
	Endif

	// Pagamento de arquivo texto.                                        
	cQry := " "
	cQry += "SELECT E2_FORNECE,E2_LOJA,E2_PREFIXO,E2_NUM,E2_PARCELA,E2_TIPO,E2_CODBAR,E2_NOMFOR,E2_VENCREA "
	cQry += "  FROM " + RetSqlName("SE2") +" E2 "
	cQry += " WHERE E2_NUMBOR =  '"+cBord+"' "
	cQry += "   AND E2_FILIAL = '" + xFilial("SE2") + "' "
	cQry += "   AND D_E_L_E_T_ = ' ' "
	cQry += "   AND E2_SALDO > 0 "
	cQry += "   AND E2_TIPO NOT IN('NDF','PR') "

	If Select("QRY") > 0
		QRY->(dbCloseArea())
	Endif

	TCQUERY cQry NEW ALIAS "QRY"

	Count To nRegs
	
	dbSelectArea("QRY")
	dbGotop()
	ProcRegua(nRegs)
	While !Eof()
		If STOD(QRY->E2_VENCREA) > dDtPagto
			lAddReg		:= .F.
			If MsgYesNo("Encontrado Título ("+QRY->E2_PREFIXO + "." +  QRY->E2_NUM + "-" + QRY->E2_PARCELA + "-"+ QRY->E2_FORNECE+ "/" + QRY->E2_LOJA + "-" + QRY->E2_NOMFOR +") com Vencimento Real (" + DTOC(STOD(QRY->E2_VENCREA))+ ") maior que a data de validação informada. Deseja aceitar o título? ","Data pagamento acima do estipulado")
				lAddReg	:= .T.
			Endif
		Else
			lAddReg		:= .T.
		Endif
		If !lAddReg
			// Criar lista de rejeitados posteriormente
			
		ElseIf QRY->E2_FORNECE $ ("UNIAO #INPS  ") // Impostos sem codigo de barras
			// PROCURA TITULO PAI
			Aadd(aImp,{;
				QRY->E2_PREFIXO,;		//	1
			QRY->E2_NUM,;				//	2
			QRY->E2_PARCELA,;			//	3
			QRY->E2_TIPO,;				//	4
			QRY->E2_FORNECE,;			//	5
			QRY->E2_LOJA})				//	6
		Elseif !Empty(QRY->E2_CODBAR) .And. Substr(QRY->E2_CODBAR,1,1) = "8" // Titulos concessionarias
			Aadd(aCon,{;
				QRY->E2_PREFIXO,;		//	1
			QRY->E2_NUM,;				//	2
			QRY->E2_PARCELA,;			//	3
			QRY->E2_TIPO,;				//	4
			QRY->E2_FORNECE,;			//	5
			QRY->E2_LOJA})				//	6
		Elseif !Empty(QRY->E2_CODBAR) .And. Len(Alltrim(QRY->E2_CODBAR)) < 48 // Titulos com codigo de Barras
			Aadd(aTit,{;
				QRY->E2_PREFIXO,;		//	1
			QRY->E2_NUM,;				//	2
			QRY->E2_PARCELA,;			//	3
			QRY->E2_TIPO,;				//	4
			QRY->E2_FORNECE,;			//	5
			QRY->E2_LOJA})				//	6
		
		Else  // DOCS E TEDS
			Aadd(aDoc,{;
				QRY->E2_PREFIXO,;		//	1
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

	If Len(aCon) > 0
		sfCon()
	Endif

	If len(aImp) > 0
		sfImp()
	Endif

	sfTrailer()

	fClose(nHdl)
	
	MsgInfo("Arquivo Gerado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	
	ShellExecute("open","C:\EDI\ITAU\","","C:\EDI\ITAU\",1)
	
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
	Local		cTipPg		:= ""
	Local		cForPg		:= ""
	Local 		x
	Local 		nX1 


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
				
				// Tipo de Pagametno
				If SA2->A2_TIPCTA == "2" .And. SA2->A2_BANCO == '341' 
					cTipPg := "30" // Salários 
				ElseIf Alltrim(SE2->E2_NATUREZ)=="SALARIOS" .And. SA2->A2_BANCO == '341'     ////Tipo de Pagamento
					cTipPg := "30"  // Salários
				Else
					cTipPg := "20"	// Fornecedores 
				Endif
	
				// Forma de Pagamento
				If SA2->A2_BANCO == '341'//Forma de Pagamento ITAU
					cForPg := "01"			
				ElseIf SE2->E2_SALDO > 0 ////30/11/2018 chamado 22.173 alterado para tudo ser TED -  VER QUESTAO DO ACRES E DECRES // O valor anterior era de R$ 5.000,00
					cForPg := "41"	// TED OUTRO TITULAR
				Else
					cForPg := "03" 	// DOC C
				Endif
				
				 
				If !Empty(SA2->A2_BANCO) 
					Aadd(aDetDoc,{;
						cTipPg,;			//	1
					cForPg,;				//	2
					cIdtit,;				//	3
					SA2->A2_BANCO,;			//	4
					SA2->A2_AGENCIA,;		//	5
					SA2->A2_NUMCON,;		//	6
					SA2->A2_DVCTA,;			//	7
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
			sfCabDoc(nX1)
		Endif
		cTp := aDetDoc[nX1,1]+aDetDoc[nX1,2]
		sfDetDoc(nX1)
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
Static Function sfCabDoc(nX1)
	
	Local	cCpo
	Local	cLin
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	// Layout contido na página 09 Sispag Febraban 240
	cCpo := "341"      																		//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "1"      																		//	008-008 9(01) Tipo de Registro
	cCpo += "C"      																		//	009-009 X(01) Tipo de Operacao = C credito
	cCpo += aDetDoc[nX1,1]  																//	010-011 9(02) Tipo de Pagamento
	cCpo += aDetDoc[nX1,2] 																	// 	012-013 9(02)	Credito em Conta Itau
	cCpo += "040" 																			// 	014-016 9(03) lay out do lote
	cCpo += Space(1)   																		// 	017-017 X(01) Brancos
	cCpo += "2" 																			// 	018-018 9(01) Tipo de inscricao em debitada 1=CPF 2=CGC
	cCpo += SUBS(SM0->M0_CGC,1,14)   														// 	019-032 9(14) CNPJ empresa Debitada
	cCpo += Space(4)      																	// 	033-036 X(04) Idenficação do lançamento no extrato - Brancos
	cCpo += Space(16) 																		// 	034-052 X(16) Brancos
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)  												//	053-057 9(05) Agencia (5)
	cCpo += Space(1)      																	// 	058-058 X(01) Brancos
	cCpo += "0000000"+SUBSTR(SEE->EE_CONTA,1,5)                           					// 	059-070 9(12) Conta
	cCpo += Space(1)    																	// 	071-071 X(01) Branco
	cCpo += Substr(SEE->EE_CONTA,6,1)                                   					// 	072-072 9(01) Digitocc
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  													// 	073-102 X(30) Razao Social
	cCpo += Space(30) 																		// 	103-132 X(30) Finalidade
	cCpo += Space(10) 																		// 	133-142 X(10) Historico CC
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 													// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  													//	173-177 9(05) Numero do Local
	cCpo += Space(15)   																	// 	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  													// 	193-212 X(20) Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,8)														// 	213-220 9(08) CEP
	cCpo += Substr(SM0->M0_ESTCOB,1,2)														// 	221-222 X(02) Sigla do Estado
	cCpo += Space(8)      																	// 	223-230 X(08) Brancos
	cCpo += Space(10)  																		//	231-240 X(10) Ocorrencias - Branco

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
Static Function sfDetDoc(nX1)

	Local		cCpo
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 11 Sispag Febraban 240
	cCpo := "341"      																		//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																		//	008-008 9(01) Tipo de Registro
	cCpo += Strzero(nConta,5)	  															//	009-013 9(05) Numero de registro
	cCpo += "A" 																			// 	014-014 X(01) Segmento
	cCpo += "000" 																			// 	015-017 9(03) Tipo de Movimento - Inclusao
	cCpo += "000"       																	// 	018-020 Zeros
	If aDetDoc[nX1,4] == "341" // Nota 11 Conta corrente do Favorecido
		cCpo += aDetDoc[nX1,4]  															// 	021-023 9(03) Banco do Favorecido
		cCpo += "0"  																		// 	024-024 9(01) Zeros
		cCpo += Strzero(Val(aDetDoc[nX1,5]),4)												// 	025-028 9(04) Agencia do favorecido
		cCpo += Space(1)  																	// 	029-029 X(01) Brancos
		cCpo += Replicate("0",7) 															//	030-035 9(06) Zeros
		cCpo += Strzero(Val(aDetDoc[nX1,6]),5)												// 	036-041 9(06) Conta
		cCpo += Space(1)  																	// 	042-042 X(01) Brancos
		cCpo += Padr(Substr(Alltrim(aDetDoc[nX1,7]),1,1),1)									// 	043-043 9(01) Digito
	Else
		cCpo += aDetDoc[nX1,4]  															// 	021-023 9(03) Banco do Favorecido
		cCpo += Strzero(Val(aDetDoc[nX1,5]),5) 												// 	024-028 9(05) Agencia do favorecido
		cCpo += Space(1)  																	// 	029-029 X(01) Brancos
		cCpo += Strzero(Val(aDetDoc[nX1,6]),12) 											// 	030-041 9(12) Conta
		If Len(Alltrim(aDetDoc[nX1,7])) == 2
			cCpo += Padr(Substr(Alltrim(aDetDoc[nX1,7]),1,2),2)								// 042-042 X(01) Complemento - Brancos
																							// 043-043 X(01) DAC da Agencia/Conta creditada
		Else
			cCpo += Space(1)  																// 	042-042 X(01) Complemento - Brancos
			cCpo += Padr(Substr(Alltrim(aDetDoc[nX1,7]),1,1),1)								// 	043-043 X(01) DAC da Agencia/Conta creditada
		Endif
	Endif
	cCpo += Substr(aDetDoc[nX1,8],1,30)														// 	044-073 X(30) Nome do Favorecido
	cCpo += StrZero(Val(aDetDoc[nX1,14]),20)												// 	074-093 X(20) Nro Doc empresa
	cCpo += GravaData(aDetDoc[nX1,9],.F.,5)													//	094-101 9(08) Data de pagto - DDMMAAAA
	cCpo += "REA" 																			// 	102-104 X(03) Moeda
	cCpo += Replicate("0",15) 																// 	105-119 9(15) Zeros
	cCpo += Strzero(((aDetDoc[nX1,10]-aDetDoc[nX1,11]+aDetDoc[nX1,12])*100),15)				// 	120-134 9(13)V9(02) Valor Pgto
	cCpo += Space(15) 																		// 	135-149 X(15) Brancos
	cCpo += Space(5) 																		// 	150-154 X(05) Brancos
	cCpo += Replicate("0",8) 																// 	155-162 9(08) Data Efetiva - Zeros
	cCpo += Replicate("0",15) 																// 	163-177 9(13)V9(02) Valor Efetivo Zeros
	cCpo += Space(18) 																		// 	178-195 X(18) Finalidade - Brancos
	cCpo += Space(2) 																		// 	196-197 X(02) Brancos
	cCpo += Replicate("0",6) 																// 	198-203 9(06) Zeros
	cCpo += Substr(aDetDoc[nX1,13],1,14) 													// 	204-217 9(14) CGC /CPF
	cCpo += Space(2)																		// 	218-219 X(02) Finalidade Doc
	If aDetDoc[nX1,1] == "30"	// Nota 26 - Finalidade TED 00004-Pagamento Salarios 00010=Credito em conta
		cCpo += "00004"																		// 	220-224 X(05) Finalidade TED
	Else
		cCpo += "00010"																		// 	220-224 X(05) Finalidade TED
	Endif
	cCpo += Space(5)   																		// 	225-229 X(05)	Brancos
	cCpo += "0" 																			// 	230-230 X(01) Aviso ao Favorecedo
	cCpo += Space(10) 																		// 	231-240 X(10) Ocorrencias

	cLin := Stuff(cLin,01,240,cCpo)
	nValpg += aDetDoc[nX1,10]-aDetDoc[nX1,11]+aDetDoc[nX1,12]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!") 
		
		Endif
	Endif


Return


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

	Local	cCpo	
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 18 Sispag Febraban 240
	cCpo := "341"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "5"      																		//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 																		// 	009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 															// 	018-023 9(06) Numero de arquivos
	cCpo += Strzero((nValpg*100),18)  														// 	024-041 9(16)V9(02) Valor total dos pagamentos
	cCpo += Replicate("0",18) 																// 	042-059 Zeros
	cCpo += Space(171)																		// 	060-230 X(171) Brancos
	cCpo += Space(10) 																		// 	231-240 X(10) Brancos
	
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

	Local	nXa	
	Local	aArSA2Old	
	Local	nDifSE2		:= 0
	Local 	x 
	Local 	nX3

	cTp 	:= Space(2)
	nConta 	:= 0
	nValpg 	:= 0

	For x:= 1 To Len(aTit)
	
		DbSelectArea("SE2")
		DbSetOrder(1)
		If dbSeek(xFilial("SE2")+aTit[x][1]+aTit[x][2]+aTit[x][3]+aTit[x][4]+aTit[x][5]+aTit[x][6])
			// Verifica se o título tem IDCNAB 
			// Para permitir a tratativa no retorno bancário
			sfGrvE2IDCNAB()
			
			DbSelectArea("SA2")
			DbSetOrder(1)
			If DbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
				
				// 24/08/2017 - Caso encontre o Beneficiário padrão preenchido no cadastro do Fornecedor, posiciona no registro SA2 do Beneficiário
				// para levar informação correta para o registro J52
				aArSA2Old	:= SA2->(GetArea())
				If !Empty(SA2->A2_XJ52COD+SA2->A2_XJ52LOJ)
					DbSelectArea("SA2")
					DbSetOrder(1)
					If DbSeek(xFilial("SA2")+SA2->A2_XJ52COD+SA2->A2_XJ52LOJ)
					
					Else
						RestArea(aArSA2Old)
					Endif
				Endif
				cIdtit  	:= aTit[x][1]+aTit[x][2]+aTit[x][3]+aTit[x][4]+aTit[x][5]+aTit[x][6]
				nDifSE2		:= (SE2->E2_VALOR - SE2->E2_SALDO)
				//              924 - 624 = 300
				If Substr(SE2->E2_CODBAR,1,3) == "341"    //Tipo de Pagamento
					Aadd(aDetTit,{;
						"30",;					//	1
					cIdtit,;					//	2
					SE2->E2_CODBAR,;			//	3
					SA2->A2_NOME,;				//	4
					SE2->E2_VENCTO,;			//	5
					SE2->E2_VALOR,;				//	6
					Iif(nDifSE2 > 0 , nDifSE2,0)+SE2->E2_DECRESC,;//	7
					SE2->E2_ACRESC,;			//	8
					SE2->E2_IDCNAB,;			//	9
					SA2->A2_CGC,;				//	10
					SE2->E2_VENCREA})			//  11
				Else
					Aadd(aDetTit,{;
						"31",;					//	1
					cIdtit,;					//	2
					SE2->E2_CODBAR,;			//	3
					SA2->A2_NOME,;				//	4
					SE2->E2_VENCTO,;			//	5
					SE2->E2_VALOR,;				//	6
					Iif(nDifSE2 > 0 , nDifSE2,0)+SE2->E2_DECRESC,;			//	7
					SE2->E2_ACRESC,;			//	8
					SE2->E2_IDCNAB,;			// 	9
					SA2->A2_CGC,;				//	10
					SE2->E2_VENCREA})			//  11
				Endif
				RestArea(aArSA2Old)
			Endif
		Endif
		
	Next

	aSort(aDetTit,,,{|x,y| x[1] < y[1]})

	For nX3 := 1 To Len(aDetTit)
		If Alltrim(cTp) <> Alltrim(aDetTit[nX3,1])
	
			If nX3 > 1
				sfTreiTit()
			Endif
			sfCabTit(nX3)
		Endif
		cTp := aDetTit[nX3,1]
		sfDetTiT(nX3)
		// 15/07/2017 - Adicionada validação J-52
		sfSegJ52(nX3)
		
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
Static Function sfCabTit(nX3)

	Local	cCpo
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	// Layout contido na página 19 Sispag Febraban 240
	cCpo := "341"      																		//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "1"      																		//	008-008 9(01) Tipo de Registro
	cCpo += "C"      																		//	009-009 X(01) Tipo de Operacao = C credito
	cCpo += "20"    																		//	010-011 9(02) Tipo de Pagamento
	cCpo +=  aDetTit[nX3,1] 																// 	012-013 9(02) Forma de Pagamento
	cCpo += "030" 																			// 	014-016 9(03) lay out do lote
	cCpo += Space(1)   																		// 	017-017 X(01) Brancos
	cCpo += "2" 																			// 	018-018 9(01) Tipo de inscricao em debitada 1=CPF 2=CGC
	cCpo += Substr(SM0->M0_CGC,1,14)  	 													// 	019-032 CNPJ empresa Debitada
	cCpo += Space(20)      																	// 	033-052 X(20) Brancos
	cCpo += StrZero(Val(SEE->EE_AGENCIA),5)  												// 	053-057 9(05) Agencia (5)
	cCpo += Space(1)      																	// 	058-058 X(01) Brancos
	cCpo += "0000000" + Substr(SEE->EE_CONTA,1,5)                           				// 	059-070 9(12) Conta
	cCpo += Space(1)    																	// 	071-071 X(01) Branco
	cCpo += Substr(SEE->EE_CONTA,6,1)                                   					// 	072-072 9(01) Digitocc
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  													//	073-102 X(30) Razao Social
	cCpo += Space(30) 																		// 	103-132 X(30) Finalidade
	cCpo += Space(10) 																		// 	133-142 X(10) Historico CC
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 													// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  													//	173-177 9(05) Numero do Local
	cCpo += Space(15)   																	// 	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  													// 	193-212 X(20) Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,8)														// 	213-220 9(08) CEP
	cCpo += Substr(SM0->M0_ESTCOB,1,2)														//	221-222 X(02) Sigla Estado
	cCpo += Space(8)      																	// 	223-230 X(08) Brancos
	cCpo += Space(10)  																		//	231-240 X(10) Brancos

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
Static Function sfDetTit(nX3)
	Local	cCpo	
	
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 20 Sispag Febraban 240
	cCpo := "341"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																		//	008-008 9(01) Tipo de Registro
	cCpo += StrZero(nConta,5)	  															//	009-013 9(05) Numero de registro
	cCpo += "J" 																			// 	014-014 X(01) Segmento
	cCpo += "000" 																			// 	015-017 9(03) Tipo de Movimento - Inclusao
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
	cCpo += Strzero((aDetTit[nX3,6]*100),15) 												// 	100-114 9(013)V9(02) Valor do Título (NOMINAL)
	cCpo += Strzero((aDetTit[nX3,7]*100),15) 												// 	115-129 9(013)V9(02) Descontos
	cCpo += Strzero((aDetTit[nX3,8]*100),15) 												//	130-144 9(013)V9(02) Acrescimos
	cCpo += GravaData(aDetTit[nX3,11],.F.,5)												// 	145-152 9(08) Data Pagamento DDMMAAAA
	cCpo += StrZero(((aDetTit[nX3,6]-aDetTit[nX3,7]+aDetTit[nX3,8])*100),15) 				// 	153-167 9(13)V9(02) Valor do Pagamento
	cCpo += Replicate("0",15) 																// 	168-182 9(15) Zeros
	cCpo += Padr("0000000000"+Substr(aDetTit[nX3,9],1,20),20)								// 	183-202 X(20) Id tit na empresa
	cCpo += Space(13) 																		// 	203-215 X(13) Brancos
	cCpo += Space(15) 																		// 	216-230 X(15) Brancos
	cCpo += Space(10) 																		// 	231-240 X(10) Brancos

	cLin := Stuff(cLin,01,240,cCpo)
	
	nValpg += aDetTit[nX3,6]-aDetTit[nX3,7]+aDetTit[nX3,8]

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
		If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
		
		Endif
	Endif


Return



/*/{Protheus.doc} sfSegJ52
//Geração do registro J-52 Obrigatório para pagamento de Boletos a partir de Julho/2017
//http://download.itau.com.br/bankline/SISPAG_CNAB.pdf
@author Marcelo Alberto Lauschner
@since 15/07/2017
@version 6

@type function
/*/
Static Function sfSegJ52(nX3)
	
	Local	cCpo
	
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

	cCpo := "341"      																		//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)																//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																		//	008-008 9(01) Tipo de Registro
	cCpo += StrZero(nConta,5)	  															//	009-013 9(05) Numero de registro
	cCpo += "J" 																			// 	014-014 X(01) Código Segmento Detalhe Reg.Detalhe
	cCpo += "000" 																			// 	015-017 9(03) Tipo de Movimento - Inclusao
	cCpo += "52"																			//  018-019 9(02) Identificação Registro Opcional
	cCpo += "2"																				//  020-020 9(01) Tipo de Inscrição do Pagador 1-Cpf / 2-Cnpj
	cCpo += StrZero(Val(SM0->M0_CGC),15)													// 	021-035 9(15) Número de Inscrição do Pagador Nota 36 
	cCpo += Substr(SM0->M0_NOMECOM,1,40)  													// 	036-075 X(40) Nome do Pagador
	cCpo += IIf(Len(Alltrim(aDetTit[nX3,10])) < 14,"1","2" )								// 	076-076 9(01) Tipo de Inscrição do Beneficiário 1-Cpf / 2-Cnpj
	cCpo += StrZero(Val(aDetTit[nX3,10]),15)												// 	077-091 9(15) Número de Inscrição do Beneficiário Nota 36
	cCpo += Substr(aDetTit[nX3,4],1,40) 													// 	092-131 X(40) Nome do Beneficiário
	cCpo += "2"																				// 	132-132	9(01) Tipo de Incrição do Sacador Avalista 1-Cpf / 2-Cnpj
	cCpo += StrZero(0,15)																	//	133-147 9(15) Número de Inscrição do Sacador Avalista Nota 36
	cCpo += Space(40)																		// 	148-187 X(40) Nome do Sacador Avalista
	cCpo += Space(53)																		//	188-240	X(53) Brancos - Complemento de Registro
	
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
	Local	cCpo
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	
	// Layout contido na página 26 Sispag Febraban 240
	cCpo := "341"      														//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "5"      														//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 														// 	009-017 X(09) Brancos
	cCpo += StrZero(nConta+2,6) 											// 	018-023 9(06)	Numero de arquivos
	cCpo += Strzero((nValpg*100),18)  										// 	024-041 9(16)V9(02) Valor total dos pagamentos
	cCpo += Replicate("0",18) 												// 	042-059 9(18) Zeros
	cCpo += Space(171) 														// 	060-230 X(171) Brancos
	cCpo += Space(10) 														// 	231-240 X(10) Brancos
	
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


/*/{Protheus.doc} sfCon
(Pagamento de concessionárias e tributos com códigos de barra)
	
@author MarceloLauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfCon()

	Local 	x
	Local 	nX4 	
	cTp 			:= Space(2)
	nConta 			:= 0
	nValpg 			:= 0
	
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
						"2216",;				//	1
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
						"2217",;				//	1
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
						"2291",;				//	1
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
						"2013",;				//	1
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
			sfCabCon(nX4)
		Endif
		cTp := aDetCon[nX4,1]
		sfDetCon(nX4)
	Next

	sfTreiCon()

Return


/*/{Protheus.doc} sfCabCon
(Registro Header de lote - Pagamento de Contas de Concessionárias e Tributos com códigos de barras)
	
@author MarceloLauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfCabCon(nX4)

	Local	cCpo
	
	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	// Layout contido na página 27 Sispag Febraban 240
	cCpo := "341"      														//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "1"     	 													//	008-008 9(01) Tipo de Registro
	cCpo += "C"      														//	009-009 X(01) Tipo de Operacao = C credito
	cCpo += Substr(aDetCon[nX4,1],1,2)    									//	010-011 9(02) Tipo de Pagamento
	cCpo += Substr(aDetCon[nX4,1],3,2)										// 	012-013 9(02) Forma de Pagamento
	cCpo += "030" 															// 	014-016 9(03) lay out do lote
	cCpo += Space(1)   														// 	017-017 X(01) Brancos
	cCpo += "2" 															// 	018-018 9(01) Tipo de inscricao em debitada 1=CPF 2=CGC
	cCpo += Substr(SM0->M0_CGC,1,14)   										//	019-032 9(14) CNPJ empresa Debitada
	cCpo += Space(20)      													// 	033-052 X(20) Brancos
	cCpo += StrZero(Val(SEE->EE_AGENCIA),5)  								// 	053-057 9(05) Agencia (5)
	cCpo += Space(1)      													// 	058-058 X(01) Brancos
	cCpo += "0000000" + Substr(SEE->EE_CONTA,1,5) 	        				// 	059-070 9(12) Conta
	cCpo += Space(1)    													// 	071-071 X(01) Branco
	cCpo += Substr(SEE->EE_CONTA,6,1)                                		// 	072-072 9(01) Digitocc
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  									// 	073-102 X(30) Razao Social
	cCpo += Space(30) 														// 	103-132 X(30) Finalidade
	cCpo += Space(10) 														// 	133-142 X(10) Historico CC
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 									// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  									//	173-177 9(05) Numero do Local
	cCpo += Space(15)   													//	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  									// 	193-212 X(20) Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,8)										//	213-220 9(08) CEP
	cCpo += Substr(SM0->M0_ESTCOB,1,2)										// 	221-222 X(02) Sigla do Estado
	cCpo += Space(8)      													// 	223-230 X(08) Brancos
	cCpo += Space(10)  														//	231-240 X(10) Brancos

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


/*/{Protheus.doc} sfDetCon
(Registro Detalhe - Segmento O - Obrigatório -Pagamento de Contas de Concessionárias e Tributos com Códigos de barras)
	
@author MarceloLauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfDetCon(nX4)
	Local	cCpo	
	
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 28 Sispag Febraban 240
	cCpo := "341"      														//	001-003 9(03) Codigo do Banco
	cCpo += StrZero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "3"      														//	008-008 9(01) Tipo de Registro
	cCpo += StrZero(nConta,5)	  											//	009-013 9(06) Numero de registro
	cCpo += "O" 															// 	014-014 X(01) Segmento
	cCpo += "000" 															// 	015-017 9(03) Tipo de Movimento - Inclusao
	cCpo += Substr(aDetCon[nX4,3],1,48) 									//	018-065 X(48) Codigo de Barras
	cCpo += Substr(aDetCon[nX4,4],1,30) 									// 	066-095 X(30) Nome concessionaria / contribuinte
	cCpo += GravaData(aDetCon[nX4,5],.F.,5)									// 	096-103 9(08) Data Vencimento
	cCpo += "REA" 															//	104-106 X(03) Moeda
	cCpo += Replicate("0",15) 												// 	107-121 9(07)V9(08) Quantidade da moeda
	cCpo += Strzero(((aDetCon[nX4,6]-aDetCon[nX4,7]+aDetCon[nX4,8])*100),15)// 	122-136 9(13)V9(02) Valor do Pagamento
	cCpo += GravaData(aDetCon[nX4,5],.F.,5)									// 	137-144 9(08) Data Pagamento
	cCpo += Replicate("0",15) 												// 	145-159 9(13)V9(02) Valor efetivo - Zeros
	cCpo += Space(3) 														// 	160-162 X(03) Complemento - Brancos
	cCpo += Space(9) 														// 	163-171 X(09) Numero Nota fiscal - Brancos
	cCpo += Space(3)														// 	172-174 X(03) Brancos
	cCpo += Padr("0000000000"+Substr(aDetCon[nX4,9],1,20),20)				// 	175-194 X(20) Id tit na empresa
	cCpo += Space(21) 														// 	195-215 X(21) Brancos
	cCpo += Space(15) 														//	216-230 X(15) Nosso Numero -  Brancos
	cCpo += Space(10) 														// 	231-240 X(10) Brancos

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


/*/{Protheus.doc} sfTreiCon
(Registro Trailler de Lote - Pagamento de contas de concessionarias e tributos com códigos de barra)
	
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfTreiCon()
	Local	cCpo

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 30 Sispag Febraban 240
	cCpo := "341"      														//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "5"      														//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 														// 	009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 											// 	018-023 9(06) Numero de arquivos
	cCpo += Strzero((nValpg*100),18)  										// 	024-041 9(16)V9(02) Valor total dos pagamentos
	cCpo += Replicate("0",15) 												// 	042-056 9(07)V9(08) Soma de quantidade moeda - Zeros
	cCpo += Space(174) 														// 	057-230 X(174) Brancos
	cCpo += Space(10) 														// 	231-240 X(10) Brancos
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


/*/{Protheus.doc} sfImp
(Funcao para montar array com  - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
	
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfImp()

	Local		cIdTit		:= ""	// Id do Titulo
	Local		cCodPai 	:= Space(6)
	Local		cNomePai 	:= Space(30)
	Local		cCnpjPai 	:= Space(14)
	Local		cQra
	Local 		x
	Local 		nX2 
	
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
		
				If aImp[x][5] == "UNIAO "
					cQra += "AND E2_PARCIR <> ' ' "
				Elseif aImp[x][5] == "INPS  "
					cQra += "AND E2_PARCINS <> ' ' "
				Endif


				TCQUERY cQra NEW ALIAS "QRA"
	
				dbSelectArea("QRA")
				dbGotop()
	
				If !Empty(QRA->A2_COD)
					cCodPai 	:= QRA->A2_COD
					cNomePai 	:= Substr(QRA->A2_NOME,1,30)
					cCnpjpai 	:= Substr(QRA->A2_CGC,1,14)
				Endif
		
				If Alltrim(SE2->E2_FORNECE) == "UNIAO"    //Tipo de Pagamento = DARF
					Aadd(aDetImp,{;
						"16",;				//	1
					cIdTit,;				//	2
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
				ElseIf Alltrim(SE2->E2_FORNECE) == "INPS"    //Tipo de Pagamento = GPS
					Aadd(aDetImp,{;
						"17",;				//	1
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
			sfCabimp(nX2)
		Endif
		cTp := aDetImp[nX2,1]
		sfDetimp(nX2)
	Next

	sfTreiimp()

Return


/*/{Protheus.doc} sfCabImp
(Registro Header de Lote - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
	
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfCabImp(nX2)
	
	Local	cCpo

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	nContLot ++
	// Layout contido na página 31 Sispag Febraban 240
	cCpo := "341"      														//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "1"      														//	008-008 9(01) Tipo de Registro
	cCpo += "C"      														//	009-009 X(01) Tipo de Operacao = C credito
	cCpo += "22"    														//	010-011 9(02) Tipo de Pagamento
	cCpo +=  aDetImp[nX2,1] 												// 	012-013 9(02) Forma de Pagamento
	cCpo += "030" 															// 	014-016 9(03) lay out do lote
	cCpo += Space(1)  											 			// 	017-017 X(01) Brancos
	cCpo += "2" 															// 	018-018 9(01) Tipo de inscricao em debitada
	cCpo += SUBS(SM0->M0_CGC,1,14)   										// 	019-032 9(14) CNPJ empresa Debitada
	cCpo += Space(20)      													// 	033-052 X(20) Brancos
	cCpo += Strzero(VaL(SEE->EE_AGENCIA),5)  								// 	053-057 9(05) Agencia (5)
	cCpo += Space(1)     	 												// 	058-058 X(01) Brancos
	cCpo += "0000000"+SUBSTR(SEE->EE_CONTA,1,5)                      		// 	059-070 9(12) Conta
	cCpo += Space(1)    													// 	071-071 X(01) Branco
	cCpo += SUBSTR(SEE->EE_CONTA,6,1)                                 		// 	072-072 9(01) Digitocc
	cCpo += Substr(SM0->M0_NOMECOM,1,30)  									// 	073-102 X(30) Razao Social
	cCpo += Space(30) 														// 	103-132 X(30) Finalidade
	cCpo += Space(10) 														// 	133-142 X(10) Historico CC
	cCpo += Substr(SM0->M0_ENDCOB,1,30) 									// 	143-172 X(30) Endereco da empresa
	cCpo += Substr(SM0->M0_COMPCOB,1,5)  									//	173-177 9(05) Numero do Local
	cCpo += Space(15)   													// 	178-192 X(15) Complemento
	cCpo += Substr(SM0->M0_CIDCOB,1,20)  									//	193-212 X(20) Municipio
	cCpo += Substr(SM0->M0_CEPCOB,1,8)										//	213-220 9(08) CEP
	cCpo += Substr(SM0->M0_ESTCOB,1,2)										//	221-222 X(02) Sigla Estado
	cCpo += Space(8)     									 				// 	223-230 X(08) Brancos
	cCpo += Space(10)  														//	231-240 X(10) Brancos


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


/*/{Protheus.doc} sfDetimp
(Registro Detalhe - Segmento N - Obrigatorio - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
	
@author MarceloLauschner
@since 13/12/2013
@version 1.0		

@return Sem Retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfDetimp(nX2)

	Local	cCpo
	
	nConta ++

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 32 Sispag Febraban 240
	cCpo := "341"      																//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)														//	004-007 9(04) Codigo do Lote
	cCpo += "3"      																//	008-008 9(01) Tipo de Registro
	cCpo += Strzero(nConta,5)	  													//	009-013 9(05) Numero de registro
	cCpo += "N" 																	// 	014-014 X(01) Segmento
	cCpo += "000" 																	// 	015-017 9(03) Tipo de Movimento - Inclusao
	// Anexo C - Pagina 63
	If aDetImp[nX2,1] == "16" // Se DARF
		cCpo += "02"																//	018-019 9(02) Identificacao Tributo
		cCpo += Substr(aDetImp[nX2,3],1,4)											//	020-023 9(04) Codigo receita
		cCpo += "2"																	// 	024-024 9(01) Tipo Inscricao 1=CPF 2=CGC
		cCpo += SUBS(SM0->M0_CGC,1,14)   											// 	025-038 9(14) CNPJ empresa Debitada
		cCpo += GravaData(LastDay(aDetImp[nX2,9]),.F.,5) 							//	039-046 9(08) Periodo de Apuracao
		cCpo += Space(17) 															// 	047-063 9(17) Numero de referencia
		cCpo += Strzero(((aDetImp[nX2,6]-aDetImp[nX2,7]+aDetImp[nX2,8])*100),14) 	// 	064-077 9(12)V9(02) Valor do Pagamento
		cCpo += Replicate("0",14) 													// 	078-091 9(12)V9(02) Valor Multa
		cCpo += Replicate("0",14) 													// 	092-105 9(12)V9(02) Valor dos Juros
		cCpo += Strzero(((aDetImp[nX2,6]-aDetImp[nX2,7]+aDetImp[nX2,8])*100),14) 	// 	106-119 9(12)V9(02) Valor do Pagamento
		cCpo += GravaData(aDetImp[nX2,5],.F.,5)										//	120-127 9(08) Data Vencimento
		cCpo += GravaData(aDetImp[nX2,5],.F.,5)										// 	128-135 9(08) Data Pagamento
		cCpo += Space(30)															// 	136-165 X(30) Complemento - Brancos
		cCpo += Substr(SM0->M0_NOMECOM,1,30)  										// 	166-195 X(30) Contribuinte Razao Social
	Elseif aDetImp[nX2,1] == "17" // Se INSS=GPS
		cCpo += "01"																// 	018-019 9(02) Identificacao Tributo
		cCpo += "2631" 																// 	020-023 9(04) Codigo de pagamento
		cCpo += Substr(GravaData(LastDay(aDetImp[nX2,9]),.F.,5),3,6)				//	024-029 9(06) Periodo de Apuracao
		// Se tiver titulo Pai
		If !Empty(aDetImp[nX2,10])
			cCpo += Substr(aDetImp[nX2,12],1,14)  									// 	030-043 9(14) CNPJ empresa Debitada
		Else
			cCpo += Substr(SM0->M0_CGC,1,14)   										// 	030-043 9(14) CNPJ empresa Debitad
		Endif
		cCpo += Strzero(((aDetImp[nX2,6]-aDetImp[nX2,7]+aDetImp[nX2,8])*100),14) 	// 	044-057 9(12)V9(02) Valor do Pagamento
		cCpo += Replicate("0",14) 													// 	058-071 9(12)V9(02) Outras entidades
		cCpo += Replicate("0",14) 													// 	072-085 9(12)V9(02) Correcao monetaris
		cCpo += Strzero(((aDetImp[nX2,6]-aDetImp[nX2,7]+aDetImp[nX2,8])*100),14) 	// 	086-099 9(12)V9(02) Valor arrecadado
		cCpo += GravaData(aDetImp[nX2,5],.F.,5)										// 	100-107 9(08) Data Pagamento
		cCpo += Space(8)															// 	108-115 X(08) Complemento
		cCpo += Space(50)															// 	116-165 X(50) Informacoes Complementares
		// Se tiver titulo Pai
		If !Empty(aDetImp[nX2,10])
			cCpo += Substr(aDetImp[nX2,11],1,30)   									// 	166-195 X(30) Nome empresa Debitada
		Else
			cCpo += Substr(SM0->M0_NOMECOM,1,30)   									// 	166-195 X(30) Nome empresa Debitad
		Endif
	Endif
	cCpo += Padr("0000000000"+Substr(aDetImp[nX2,13],1,20),20)						// 	196-215 X(20) Id tit na empresa
	cCpo += Space(15) 																//	216-230 X(15) Nosso numero - Brancos
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

	nValpg += aDetImp[nX2,6]-aDetImp[nX2,7]+aDetImp[nX2,8]

Return


/*/{Protheus.doc} sfTreiImp
(Registro Trailler de Lote - Pagamento de Tributos sem código de barras e FGTS - GRF/GRRF/GRDE com código de barras)
	
@author Marcelo Lauschner
@since 13/12/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (links_or_references)
/*/
Static Function sfTreiImp()
	
	Local	cCpo

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 36 Sispag Febraban 240
	cCpo := "341"      														//	001-003 9(03) Codigo do Banco
	cCpo += Strzero(nContLot,4)												//	004-007 9(04) Codigo do Lote
	cCpo += "5"      														//	008-008 9(01) Tipo de Registro
	cCpo += Space(9) 														// 	009-017 X(09) Brancos
	cCpo += Strzero(nConta+2,6) 											// 	018-023 9(06) Numero de arquivos
	cCpo += Strzero((nValpg*100),14)  										// 	024-037 9(12)V9(02) Valor total dos pagamentos
	cCpo += Replicate("0",14) 												// 	038-051 9(12)V9(02) Valor total de outras entidades
	cCpo += Replicate("0",14) 												// 	052-065 9(12)V9(02) Valor total multa mora
	cCpo += Strzero((nValpg*100),14)  										// 	066-079 9(12)V9(02) Valor total dos pagamentos
	cCpo += Space(151) 														// 	080-230 X(151) Brancos
	cCpo += Space(10) 														// 	231-240 X(10) Brancos
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

/// TRAILER DO ARQUIVO //////////
////////////////////////////////

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
Static Function sfTrailer()
	
	Local	cCpo

	nTamLin := 240
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
	// Layout contido na página 37 Sispag Febraban 240
	cCpo := "341"      														//	001-003 9(03) Codigo do Banco
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
