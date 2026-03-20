#Include 'Protheus.ch'
#INCLUDE "TBICONN.CH"


/*/{Protheus.doc} MLFINM03
Função para gerar Concilia Serasas 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/07/2021
@return variant, return_description
/*/
User Function MLFINM03()

	Local 	cSerasaLib	:= GetNewPar("GF_SRSALIB","0401#")

	If !cFilAnt $ cSerasaLib
		MsgAlert("Rotina liberada somente para rodar nas empresas "+cSerasaLib + ". Caso tenha que liberar mais empresas, adicione/crie o parâmetro GF_SRSALIB","MLFINM03!" )
		Return
	Endif

	sfAjustaSX1("SERARELATO")

	If Pergunte("SERARELATO",.T.)
		Processa( {|| sfExecuta(.T.)},"Gerando dados...")
	Endif

Return


/*/{Protheus.doc} sfExecuta
Executa funções para gerar o arquivo Relato
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/07/2021
@param lFirstEmp, logical, param_description
@return variant, return_description
/*/
Static Function sfExecuta(lFirstEmp)

	Private 	nTamLin, cLin, cCpo
	Private	cArq 		:= AllTrim(MV_PAR04) //"\edi\Serasa\relato\envio\nomearquivo.TXT"
	Private	nHd    		:= Iif(lFirstEmp,fCreate(cArq),FOpen( cArq , FO_READWRITE ))
	Private	cEOL   		:= "CHR(13)+CHR(10)"
	Private nQteReg01	:= 0
	Private	nQteReg05	:= 0
	Private aListSE1	:= {}
	Private lIsHomologa	:= GetNewPar("ML_FINM30H",.T.)
	Private	dLastDay	:= GetNewPar("ML_FINM30D",MV_PAR01)


	// Caso não seja a primeira empresa, vai para o final do arquivo
	If !lFirstEmp
		FSeek( nHd , 0 , FS_END )
	Endif

	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif


	If MV_PAR05 == 1
		If dLastDay >= MV_PAR01
			MsgAlert("A data limite do último arquivo gerado é '"+ DTOC(dLastDay) + "'. Portanto a data inicial deverá ser maior que esta data! Salva no parâmetro 'ML_FINM30D'","'BFFINM30.PRW.sfExecuta' - Data inicial inválida!")

			// Chamado 24.566 - Permite que determinados usuários possam alterar o parâmetro só por acessar a rotina.
			If __cUserId $ GetNewPar("BF_FINM30X","000130#000364") .And. MsgYesNo("Deseja ajustar a data limite Final?")


				aPergs := {}
				aRet 	 := {}

				aAdd(aPergs,{1,"Informe nova Data Final",dLastDay,"","","","",70,.F.})

				If !ParamBox(@aPergs,"Ajustar Data Limite Final.",aRet)
					MsgAlert("Operação cancelada! ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					fClose(nHd)
					Return
				Else
					PutMv("ML_FINM30D",MV_PAR01)
					fClose(nHd)
					Return
				EndIf

			Else
				fClose(nHd)
				Return
			Endif

		Endif

		If MV_PAR02 <= MV_PAR01
			MsgAlert("A data final informada é menor ou igual a data inicial. Intervalo não permitido!","'BFFINM30.PRW.sfExecuta' - Data Final inválida!")
			fClose(nHd)
			Return
		Endif

		If MV_PAR02 >= Date()
			MsgAlert("A data final informada é maior ou igual a dia atual. Intervalo não permitido!","'BFFINM30.PRW.sfExecuta' - Data Final inválida!")
			fClose(nHd)
			Return
		Endif

		// Gera cabeçalho do arquivo
		If !sfHeader()
			fClose(nHd)
			Return
		Endif
		If !sfDetRel()
			fClose(nHd)
			Return
		Endif
		If !sfDetTitulos()
			fClose(nHd)
			Return
		Endif
		If !sfTrailler()
			fClose(nHd)
			Return
		Endif
		// Efetua atualização do registro SE1 de que foi enviado para o Relato
		sfRelAtuSE1(aListSE1)
		// Efetua atualização com a data final da geração da remessa
		PutMv("GF_FATA30D",MV_PAR02)
	Else
		sfReadConcilia()
	Endif

	fClose(nHd)

Return


/*/{Protheus.doc} sfReadConcilia
(Processo de concilianção do arquivo de retorno do Serasa - Relato )
@author MarceloLauschner
@since 25/04/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfReadConcilia()

	Local	nTamFile
	Local 	nPos
	Local 	nLinha
	Local 	nDoc
	Local 	cBuffer
	Local	lIsVldConc		:= .F.
	Local	dDataLimite	:= dDataBase

	Private nFile := FT_FUse(AllTrim(MV_PAR03))

	If nFile == -1
		Help(" ",1,"SemArquivo",,Str(Ferror(),2,0),05,38)
		FT_FUSE()
		Return NIL
	Endif

	//Posiciona na primeria linha
	FT_FGoTop()
	// Retorna o número de linhas do arquivo
	nLast := FT_FLastRec()
	//MsgAlert( nLast )

	While !FT_FEOF()
		cLine  := FT_FReadLn() // Retorna a linha corrente
		//nRecno := FT_FRecno()  // Retorna o recno da Linha
		//MsgAlert( "Linha: " + cLine + " - Recno: " + StrZero(nRecno,3) )
		// Pula para próxima linha
		If Substr(cLine,1,2) =="00" .And. Substr(cLine,37,08) == "CONCILIA"
			lIsVldConc := .T.
			dDataLimite	:= STOD(cLine,45,8)
			dDataLimite := Min(dDataBase,dDataLimite)
		Endif

		// Verifica se passou na validação do tipo de arquivo
		If !lIsVldConc
			MsgAlert("Este arquivo não é um arquivo de Retorno de Conciliação","Arquivo inválido")
			fClose(nHd)
			FT_FUSE()
			Return .F.
		Endif

		If Substr(cLine,1,2) == "01" .And. Substr(cLine,17,2) == "05" // Registro de Dados 01 e Tipo de Dados 05
			cKeySe1	:= Substr(cLine,68,32)

			DbSelectArea("SE1")
			DbSetOrder(1)
			If DbSeek(cKeySE1)
				//SaldoTit( E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_NATUREZ, "R", E1_CLIENTE, mv_par22, E1_EMIS1, ;dFechaBase, E1_LOJA )
				nSaldo	:= 	  	SaldoTit(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE,1,         SE1->E1_EMIS1, dDataLimite,SE1->E1_LOJA)
				If nSaldo <> SE1->E1_SALDO
					//		MsgAlert("Diferença no valor do título nSaldo x e1_saldo "+cKeySE1)
				Endif

				If SE1->E1_SALDO  > 0
					//MsgAlert("Título " + SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) + " cKeySE1:" +cKeySE1 + " nSaldo:"+ cValToChar(nSaldo) + " E1_SALDO: " + cValToChar(SE1->E1_SALDO))
					// Grava data em branco
					cLine	:= Stuff(cLine,58,08,Replicate(" ",8))
				Else
					// Grava para exclusão do título pois não foi encontrado na SE1
					//MsgAlert("Título " + SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) + " cKeySE1:" +cKeySE1 + " nSaldo:"+ cValToChar(nSaldo) + " E1_SALDO: " + cValToChar(SE1->E1_SALDO) + " E1_BAIXA:" + DTOS(SE1->E1_BAIXA))
					cLine	:= Stuff(cLine,58,08,DTOS(SE1->E1_BAIXA))
				Endif
			Else
				// Grava para exclusão do título pois não foi encontrado na SE1
				cLine	:= Stuff(cLine,37,13,Replicate("9",13))
				// Grava data de pagamento em branco para evitar problemas
				cLine	:= Stuff(cLine,58,08,Replicate(" ",8))
			Endif

		Endif

		nTamLin 	:= 130
		cLin    	:= Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
		cCpo 		:=	cLine
		cLin 		:= Stuff(cLin,01,nTamLin,cCpo)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
		//³ linha montada.                                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		If fWrite(nHd,cLin,Len(cLin)) != Len(cLin)
			ConOut("Ocorreu um erro na gravacao do arquivo.'"+cArq+"'")
			fClose(nHd)
			Return .F.
		Endif
		FT_FSKIP()
	End// Fecha o Arquivo
	FT_FUSE()

Return

/*/{Protheus.doc} sfHeader
(Monta cabeçalho do arquivo)
	
@author MarceloLauschner
@since 28/03/2014
@version 1.0		

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfHeader()

	Local	dDataIni	:= MV_PAR01
	Local	dDataFim	:= MV_PAR02
	Local 	cTpPeriodo	:= "S"	// Tipo de período S=Semanal
	Local	lRemNormal	:= MV_PAR05==1


	nTamLin := 130
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	cCpo := Padr("00"												,02)	// S=01-I=001-F=002-T=02 Identificação Registro Header = 00
	cCpo += Padr("RELATO COMP NEGOCIOS"								,20)	// S=02-I=003-F=022-T=20 Constante 'RELATO COMP NEGOCIOS'
	cCpo += Padr(SM0->M0_CGC										,14)	// S=03-I=023-F=036-T=14 CNPJ da empresa conveniada
	cCpo += Padr(Iif(lRemNormal,DTOS(dDataIni),"CONCILIA")			,08)	// S=04-I=037-F=044-T=08 Remessa normal informar Data Inicio AAAAMMDD / Remessa Conciliação informar constante 'CONCILIA'
	cCpo += Padr(DTOS(dDataFim)										,08)	// S=05-I=045-F=052-T=08 Data final do periodo AAAAMMDD
	cCpo += Padr(cTpPeriodo											,01)	// S=06-I=053-F=053-T=01 Periodicidade da remessa = D=Diário M=Mensal S=Semanal Q=Quinzenal
	cCpo += Padr(Space(15)											,15)	// S=07-I=054-F=068-T=15 Reservado Serasa
	cCpo += Padr(Space(03)											,03)	// S=08-I=069-F=071-T=03 Numero identificador do Grupo Relato Segmento ou Brancos
	cCpo += Padr(Space(29)											,29)	// S=09-I=072-F=100-T=29 Branco
	cCpo += Padr("V."												,02)	// S=12-I=101-F=102-T=02 Identificação da versão do Layout Fixo 'V.'
	cCpo += Padr("01"												,02)	// S=13-I=103-F=104-T=02 Numero da Versão do Layout Fixo '01'
	cCpo += Padr(Space(26)											,26)	// S=14-I=105-F=130-T=26 Brancos

	cLin := Stuff(cLin,01,nTamLin,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHd,cLin,Len(cLin)) != Len(cLin)
		ConOut("Ocorreu um erro na gravacao do arquivo.'"+cArq+"'")
		fClose(nHd)
		Return .F.
	Endif

Return .T.



Static Function sfDetRel()

	Local	cTpCliente	:= ""

	Local	cQry := ""

	cQry := "SELECT SUBSTRING(A1_CGC,1,8) A1CGC,MIN(A1_CGC) A1_CGC, MIN(A1_PRICOM) A1_PRICOM, MAX(A1_ULTCOM) A1_ULTCOM "
	cQry += "  FROM "+RetSqlName("SA1") + " A1 "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_PESSOA = 'J'  "
	cQry += "   AND A1_TIPO NOT IN('X') "
	cQry += "   AND A1_MSBLQL != '1' "
	cQry += "   AND A1_COD <> '000000' "
	cQry += "   AND A1_EST NOT IN('EX') "
	cQry += "   AND A1_CGC NOT IN("+sfRetCgcEmp()+") "
	cQry += "   AND A1_PRICOM <> ' ' "
	cQry += "   AND A1_PRICOM < '"+DTOS(MV_PAR02)+"' "
	If MsgYesNo("Gerar lista de clientes apenas do que tiver movimento no intervalo informado?")
		cQry += "   AND EXISTS ("

		cQry += "SELECT E1_FILIAL "
		cQry += "  FROM "+ RetSqlName("SE1") + " E1 "
		cQry += " WHERE E1.D_E_L_E_T_ =' ' "
		cQry += "   AND E1_LOJA = A1_LOJA "
		cQry += "   AND E1_CLIENTE = A1_COD "
		cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry += "   AND (E1_SALDO = E1_VALOR OR (E1_SALDO = 0 AND E1_BAIXA>='"+ DTOS(MV_PAR01) +"' AND E1_BAIXA<='"+ DTOS(MV_PAR02) +"')) "
		cQry += "   AND (E1_FATURA = ' ' OR E1_FATURA != 'NOTFAT' ) "
		cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA','FA','CC') "
		cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
		cQry += "   AND E1_EMISSAO BETWEEN '"+ DTOS(MV_PAR01)+"' AND '"+ DTOS(MV_PAR02)+"' "
		cQry += "   AND E1_RELATO != '1' " // Somente títulos não enviados para o Serasa Relato
		cQry += "UNION ALL "
		cQry += "SELECT E1_FILIAL "
		cQry += "  FROM "+RetSqlName("SE1") + " E1 "
		cQry += " WHERE E1.D_E_L_E_T_ ='*' "
		cQry += "   AND E1_LOJA = A1_LOJA "
		cQry += "   AND E1_CLIENTE = A1_COD "
		cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry += "   AND (E1_FATURA = ' ' OR E1_FATURA != 'NOTFAT' ) "
		cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA','FA','CC') "
		cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
		cQry += "   AND E1_EMISSAO <='"+ DTOS(MV_PAR02)+"' "
		cQry += "   AND E1_RELATO = '1' " // Somente títulos enviados para o Serasa Relato e que foram excluidos do sistema
		cQry += "UNION ALL "
		cQry += "SELECT E1_FILIAL "
		cQry += "  FROM "+RetSqlName("SE1") + " E1 "
		cQry += " WHERE E1.D_E_L_E_T_ =' ' "
		cQry += "   AND E1_LOJA = A1_LOJA "
		cQry += "   AND E1_CLIENTE = A1_COD "
		cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
		cQry += "   AND E1_SALDO = 0 "
		cQry += "   AND E1_BAIXA>='"+ DTOS(MV_PAR01) +"' AND E1_BAIXA<='"+ DTOS(MV_PAR02) +"' "
		cQry += "   AND (E1_FATURA = ' ' OR E1_FATURA != 'NOTFAT' ) "
		cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA','FA','CC') "
		cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
		cQry += "   AND E1_EMISSAO < '"+ DTOS(MV_PAR01)+"' "
		cQry += " )"
	Endif
	cQry += " GROUP BY SUBSTRING(A1_CGC,1,8) "
	cQry += " ORDER BY 1 "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSA1', .F., .T.)

	While !Eof()

		// Clientes com data de última compra há mais de 5 anos são descartadados
		If dDataBase - STOD(QSA1->A1_ULTCOM) > 1825
			DbSelectArea("QSA1")
			DbSkip()
			Loop
		Endif
		If lIsHomologa .And. nQteReg01 > 2000
			Exit
		Endif
		// Se não existir data de compra-não considera
		If Empty(QSA1->A1_PRICOM)
			DbSelectArea("QSA1")
			DbSkip()
			Loop
		Endif

		If (dDataBase - STOD(QSA1->A1_PRICOM) < 365 .And. dDataBase - STOD(QSA1->A1_ULTCOM) < 120 )
			cTpCliente := "2"
		ElseIf (!Empty(QSA1->A1_PRICOM) .And. dDataBase - STOD(QSA1->A1_ULTCOM) < 120 )
			cTpCliente	:= "1"
		Else
			cTpCliente	:= "3"
		Endif

		nQteReg01++

		nTamLin := 130
		cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

		cCpo := Padr("01"												,02)	// S=01-I=001-F=002-T=02 Identificação Registro Dados = 01
		cCpo += Padr(QSA1->A1_CGC										,14)	// S=02-I=003-F=016-T=14 Sacado Pessoa Juridica = CNPJ empresa Cliente
		cCpo += Padr("01"												,02)	// S=03-I=017-F=018-T=02 Tipo de dados = 01=Tempo de relacionamento para sacado pessoa juridica
		cCpo += Padr(QSA1->A1_PRICOM     								,08)	// S=04-I=019-F=026-T=08 Cliente desde AAAAMMDD
		cCpo += Padr(cTpCliente											,01)	// S=05-I=027-F=027-T=01 Tipo de cliente: 1=Antigo;2=Menos de um ano;3=Inativo
		cCpo += Padr(" "												,38)	// S=06-I=028-F=065-T=38 Brancos
		cCpo += Padr(" "												,34)	// S=07-I=066-F=099-T=34 Brancos
		cCpo += Padr(" "												,01)	// S=08-I=100-F=100-T=01 Brancos
		cCpo += Padr(" "												,30)	// S=09-I=101-F=130-T=30 Brancos

		cLin := Stuff(cLin,01,nTamLin,cCpo)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
		//³ linha montada.                                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		If fWrite(nHd,cLin,Len(cLin)) != Len(cLin)
			ConOut("Ocorreu um erro na gravacao do arquivo.'"+cArq+"'")
			fClose(nHd)
			QSA1->(DbCloseArea())
			Return .F.
		Endif
		DbSelectArea("QSA1")
		DbSkip()
	Enddo
	QSA1->(DbCloseArea())
Return .T.



/*/{Protheus.doc} sfDetTitulos
(Monta arquivo com informações de detalhes de títulos)
	
@author MarceloLauschner
@since 13/04/2014
@version 1.0		

@return lógico, Se gravou registros com sucesso retorna verdadeiro

@example
(examples)

@see (links_or_references)
/*/
Static Function sfDetTitulos()

	Local	lExclui	:= .F.
	Local	cE1VALOR	:= ""
	Local	dE1_BAIXA	:= CTOD("")
	Local	cSE1Key	:= ""

	Local	cQry := ""

	cQry := "SELECT A1_CGC,E1_EMISSAO,E1_VALOR,E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VENCREA,E1_RELATO,E1.D_E_L_E_T_ E1DELET, "
	cQry += "       CASE WHEN E1_SALDO = 0 THEN E1_BAIXA ELSE ' ' END E1_BAIXA "
	cQry += "  FROM "+RetSqlName("SA1") + " A1, "+RetSqlName("SE1") + " E1 "
	cQry += " WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_PESSOA = 'J' "
	cQry += "   AND A1_TIPO NOT IN('X') "
	cQry += "   AND A1_MSBLQL != '1' "
	cQry += "   AND A1_EST NOT IN('EX') "
	cQry += "   AND A1_CGC NOT IN("+sfRetCgcEmp()+") "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND E1.D_E_L_E_T_ =' ' "
	cQry += "   AND E1_LOJA = A1_LOJA "
	cQry += "   AND E1_CLIENTE = A1_COD "
	cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
	cQry += "   AND (E1_SALDO = E1_VALOR OR (E1_SALDO = 0 AND E1_BAIXA>='"+ DTOS(MV_PAR01) +"' AND E1_BAIXA<='"+ DTOS(MV_PAR02) +"')) "
	cQry += "   AND (E1_FATURA = ' ' OR E1_FATURA != 'NOTFAT' ) "
	cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA','FA','CC') "
	cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
	cQry += "   AND E1_EMISSAO BETWEEN '"+ DTOS(MV_PAR01)+"' AND '"+ DTOS(MV_PAR02)+"' "
	cQry += "   AND E1_RELATO != '1' " // Somente títulos não enviados para o Serasa Relato
	cQry += "UNION ALL "
	cQry += "SELECT A1_CGC,E1_EMISSAO,E1_VALOR,E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VENCREA,E1_RELATO,E1.D_E_L_E_T_ E1DELET, "
	cQry += "       CASE WHEN E1_SALDO = 0 THEN E1_BAIXA ELSE ' ' END E1_BAIXA "
	cQry += "  FROM "+RetSqlName("SA1") + " A1, "+RetSqlName("SE1") + " E1 "
	cQry += " WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_PESSOA = 'J' "
	cQry += "   AND A1_TIPO NOT IN('X') "
	cQry += "   AND A1_MSBLQL != '1' "
	cQry += "   AND A1_EST NOT IN('EX') "
	cQry += "   AND A1_CGC NOT IN("+sfRetCgcEmp()+") "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND E1.D_E_L_E_T_ ='*' "
	cQry += "   AND E1_LOJA = A1_LOJA "
	cQry += "   AND E1_CLIENTE = A1_COD "
	cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
	cQry += "   AND (E1_FATURA = ' ' OR E1_FATURA != 'NOTFAT' ) "
	cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA','FA','CC') "
	cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
	cQry += "   AND E1_EMISSAO <='"+ DTOS(MV_PAR02)+"' "
	cQry += "   AND E1_RELATO = '1' " // Somente títulos enviados para o Serasa Relato e que foram excluidos do sistema
	cQry += "UNION ALL "
	cQry += "SELECT A1_CGC,E1_EMISSAO,E1_VALOR,E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VENCREA,E1_RELATO,E1.D_E_L_E_T_ E1DELET, "
	cQry += "       CASE WHEN E1_SALDO = 0 THEN E1_BAIXA ELSE ' ' END E1_BAIXA "
	cQry += "  FROM "+RetSqlName("SA1") + " A1, "+RetSqlName("SE1") + " E1 "
	cQry += " WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_PESSOA = 'J' "
	cQry += "   AND A1_TIPO NOT IN('X') "
	cQry += "   AND A1_MSBLQL != '1' "
	cQry += "   AND A1_EST NOT IN('EX') "
	cQry += "   AND A1_CGC NOT IN("+sfRetCgcEmp()+") "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND E1.D_E_L_E_T_ =' ' "
	cQry += "   AND E1_LOJA = A1_LOJA "
	cQry += "   AND E1_CLIENTE = A1_COD "
	cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+"' "
	cQry += "   AND E1_SALDO = 0 "
	cQry += "   AND E1_BAIXA>='"+ DTOS(MV_PAR01) +"' AND E1_BAIXA<='"+ DTOS(MV_PAR02) +"' "
	cQry += "   AND (E1_FATURA = ' ' OR E1_FATURA != 'NOTFAT' ) "
	cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA','FA','CC') "
	cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
	cQry += "   AND E1_EMISSAO < '"+ DTOS(MV_PAR01)+"' "
	cQry += " ORDER BY A1_CGC,E1_PREFIXO,E1_NUM,E1_PARCELA "

	//MemoWrite("c:\temp\mlfinm03.sql",cQry)

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSE1', .F., .T.)

	While !Eof()

		If lIsHomologa .And. nQteReg05 > 2000
			Exit
		Endif

		//         0101           +001             +000123456   +A               +ABC
		cSE1Key	:= QSE1->E1_FILIAL+QSE1->E1_PREFIXO+QSE1->E1_NUM+QSE1->E1_PARCELA+QSE1->E1_TIPO
		// Evita que registros duplicados sejam enviados
		If Ascan(aListSE1,{ |x| x[1] == cSE1Key}) > 0
			DbSelectArea("QSE1")
			DbSkip()
			Loop
		Endif


		nQteReg05++
		nTamLin := 130
		cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao


		Aadd(aListSE1,{cSE1Key,Iif(QSE1->E1_RELATO=="2","1"," ")})
		// Se já enviado em outra remessa para o Relato e o título foi excluído
		If QSE1->E1_RELATO=="1" .And. !Empty(QSE1->E1DELET)
			cE1VALOR	:= Replicate("9",13)
		Else
			cE1VALOR	:= StrZero(QSE1->E1_VALOR*100,13)
		Endif

		cCpo := Padr("01"												,02)	// S=01-I=001-F=002-T=02 Identificação Registro Dados = 01
		cCpo += Padr(StrZero(Val(QSE1->A1_CGC),14)						,14)	// S=02-I=003-F=016-T=14 Sacado Pessoa Juridica = CNPJ empresa Cliente
		cCpo += Padr("05"												,02)	// S=03-I=017-F=018-T=02 Tipo de dados = 05=Titulos para sacado pessoa juridica
		cCpo += Padr(" "												,10)	// S=04-I=019-F=028-T=10 Numero do titulo com até 10 Posições
		cCpo += Padr(QSE1->E1_EMISSAO  									,08)	// S=05-I=029-F=036-T=08 Data emissão título AAAAMMDD
		cCpo += Padr(cE1VALOR											,13)	// S=06-I=037-F=049-T=13 Valor do titulo com 2 casas decimais. Zeros a esquerda. 9999999999999=para exclusão do título
		cCpo += Padr(QSE1->E1_VENCREA									,08)	// S=07-I=050-F=057-T=08 Data de vencimento AAAAMMDD
		cCpo += Padr(QSE1->E1_BAIXA										,08)	// S=08-I=058-F=065-T=08 Data pagamento ou brancos. No arquivo de conciliação do serasa virá com 99999999. No arquivo de envio de conciliação deverá ser enviado a data do pagamento
		cCpo += Padr("#D"												,02)	// S=09-I=066-F=067-T=02 #D indica que o número do título contém mais de 10 posições
		cCpo += Padr(cSE1Key											,32)	// S=09-I=068-F=099-T=32 Informando o numero do titulo neste campo as posições 19 a 28 serão desprezadas
		cCpo += Padr(" "												,01)	// S=10-I=100-F=100-T=01 Brancos
		cCpo += Padr(" "												,24)	// S=11-I=101-F=124-T=24 Reservado Serasa
		cCpo += Padr(" "												,02)	// S=12-I=125-F=126-T=01 Reservado Serasa
		cCpo += Padr(" "												,01)	// S=13-I=127-F=127-T=01 Reservado Serasa
		cCpo += Padr(" "												,01)	// S=14-I=128-F=128-T=01 Reservado Serasa
		cCpo += Padr(" "												,02)	// S=15-I=129-F=130-T=01 Reservado Serasa


		cLin := Stuff(cLin,01,nTamLin,cCpo)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
		//³ linha montada.                                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		If fWrite(nHd,cLin,Len(cLin)) != Len(cLin)
			ConOut("Ocorreu um erro na gravacao do arquivo.'"+cArq+"'")
			fClose(nHd)
			QSE1->(DbCloseArea())
			Return .F.
		Endif

		DbSelectArea("QSE1")
		DbSkip()
	Enddo
	QSE1->(DbCloseArea())
Return .T.


/*/{Protheus.doc} sfTrailler
(long_description)
	
@author MarceloLauschner
@since 13/04/2014
@version 1.0		

@return lRet, Verdadeiro ou falso para execução com sucesso

@example
(examples)

@see (links_or_references)
/*/
Static Function sfTrailler()
	Local		lRet	:= .T.

	nTamLin := 130
	cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao

	cCpo := Padr("99"												,02)	// S=01-I=001-F=002-T=02 Identificação Registro Header = 99
	cCpo += Padr(StrZero(nQteReg01,11)							,11)	// S=02-I=003-F=013-T=11 Quantidade registro 01-Tempo Relacionamento PJ
	cCpo += Padr(" "												,44)	// S=03-I=014-F=057-T=44 Brancos
	cCpo += Padr(StrZero(nQteReg05,11)							,11)	// S=04-I=058-F=068-T=11 Quantidade registros 05-Titulos Pj
	cCpo += Padr(" "												,11)	// S=05-I=069-F=079-T=11 Reservado Serasa
	cCpo += Padr(" "												,11)	// S=06-I=080-F=090-T=11 Reservado Serasa
	cCpo += Padr(" "												,10)	// S=07-I=091-F=100-T=10 Reservado Serasa
	cCpo += Padr(Space(26)										,30)	// S=08-I=101-F=130-T=30 Brancos

	cLin := Stuff(cLin,01,nTamLin,cCpo)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If fWrite(nHd,cLin,Len(cLin)) != Len(cLin)
		ConOut("Ocorreu um erro na gravacao do arquivo.'"+cArq+"'")
		fClose(nHd)
		Return .F.
	Endif

Return lRet

Static Function sfAjustaSX1(cPergXml)

	Local	aAreaOld	:= GetArea()
	Local 	aRegs := {}
	Local 	i,j


	If !FWSX6Util():ExistsParam("GF_FATA30D")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilAnt
		SX6->X6_VAR     := "GF_FATA30D"
		SX6->X6_TIPO    := "D"
		SX6->X6_DESCRIC := "Relato Serasa-Data Final"
		MsUnLock()
		PutMv("GF_FATA30D",FirstDay(dDataBase-180))
	EndIf

	dbSelectArea("SX1")
	dbSetOrder(1)
	cPergXml :=  PADR(cPergXml,Len(SX1->X1_GRUPO))




	//     "X1_GRUPO" 		,"X1_ORDEM"	,"X1_PERGUNT"    			,"X1_PERSPA"				,"X1_PERENG"			,"X1_VARIAVL"	,"X1_TIPO"	,"X1_TAMANHO"		,"X1_DECIMAL"		,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID","X1_VAR01"	,"X1_DEF01"			,"X1_DEFSPA1"		,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"		,"X1_DEF02"			,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"		,"X1_DEFSPA3"		,"X1_DEFENG3"	,"X1_CNT03"		,"X1_VAR04"	,"X1_DEF04"		,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"		,"X1_VAR05"	,"X1_DEF05","X1_DEFSPA5"	,"X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
	Aadd(aRegs,{cPergXml ,"01"			,"01-Data Inicial"			,"01-Data Inicial" 			,"01-Data Inicial"		,"mv_ch1"		,"D"		,8					,0					,0				,"G"		,""			,"mv_par01"	,""					,""					,""				,""			,""				,""					,""					,""					,""			,""			,""				,""					,""				,""				,""			,""				,""				,""				,""				,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPergXml ,"02"			,"02-Data Final"			,"02-Data Final"			,"02-Data Final"				,"mv_ch2"		,"D"		,8					,0					,0				,"G"		,""			,"mv_par02"	,""					,""					,""				,"20400101"	,""				,""					,""					,""					,""			,""			,""				,""					,""				,""				,""			,""				,""				,""				,""				,""			,""			,""				,""				,""			,"" 		,"S"		,""				,""})

	Aadd(aRegs,{cPergXml ,"03"			,"04-Arquivo Origem"		,"04-Arquivo Origem"	 	,"04-Arquivo Origem"	,"mv_ch3"		,"C"		,60					,0					,0				,"G"		,""			,"mv_par03"	,""					,""					,""				,""			,""				,""					,""					,""					,""			,""			,""				,""					,""				,""				,""			,""				,""				,""				,""				,""			,""			,""				,""				,""			,"DIR" 		,"S"		,""				,""})
	Aadd(aRegs,{cPergXml ,"04"			,"04-Arquivo Destino"		,"04-Arquivo Destino"	 	,"04-Arquivo Destino"	,"mv_ch4"		,"C"		,60					,0					,0				,"G"		,""			,"mv_par04"	,""					,""					,""				,""			,""				,""					,""					,""					,""			,""			,""				,""					,""				,""				,""			,""				,""				,""				,""				,""			,""			,""				,""				,""			,"DIR" 		,"S"		,""				,""})
	Aadd(aRegs,{cPergXml ,"05"			,"05-Tipo de Remessa"       ,"05-Tipo de Remessa"  		,"05-Tipo de Remessa"  	,"mv_ch5"		,"N"		,1					,0					,5				,"C"		,""			,"mv_par05"	,"Normal			","Normal"			,"Normal"		,""  		,""				,"Conciliacao"		,"Conciliacao"		,"Conciliacao" 		,""			,""       	,""				,""					,"Rejeitadas"	,""				,""			,""				,""				,""				,""				,""			,""			,"" 			,""				,""			,""			,"S"		,""				,""})


	dbSelectArea("SX1")
	dbSetOrder(1)

	For i:=1 to Len(aRegs)
		If !dbSeek(cPergXml+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Else


			RecLock("SX1",.F.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif

	Next

	RestArea(aAreaOld)

Return



Static Function sfRetCgcEmp

	Local	aAreaSM0	:= SM0->(GetArea())
	Local	aRecSM0		:= {}
	Local	nRecSM0		:= SM0->(Recno())
	Local	cRetSM0		:= ""
	Local 	iX

	dbSelectArea("SM0")
	dbGotop()
	While !Eof()
		If Ascan(aRecSM0,{ |x| x[1] == Substr(SM0->M0_CGC,1,14)}) == 0
			Aadd(aRecSM0,{Substr(SM0->M0_CGC,1,14)})
		EndIf
		SM0->(dbSkip())
	EndDo
	DbSelectArea("SM0")
	DbGoto(nRecSM0)
	// Ordeno por raiz de CNPJ
	aSort(aRecSM0,,,{|x,y| x[1] < y[1] })

	For ix := 1 To Len(aRecSM0)
		If iX > 1
			cRetSM0 += ","
		Endif
		cRetSM0	+= "'"+aRecSM0[iX,1]+"'"
	Next

	RestArea(aAreaSM0)

Return cRetSM0



Static Function sfRelAtuSE1(aSe1)
	Local nx:=0

	dbSelectArea("SE1")
	dbSetOrder(1)
	SET DELETED OFF

	If !Empty(SE1->(FieldPos("E1_RELATO")))
		For nx:=1 to len(aSe1)
			If Dbseek(aSe1[nx,1])
				RecLock("SE1",.F.)
				SE1->E1_RELATO := aSE1[nx,2]
				MsUnlock()
			EndIf
		Next
	EndIf
	SET DELETED ON

Return
