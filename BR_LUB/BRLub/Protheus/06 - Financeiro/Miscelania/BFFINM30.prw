#Include 'Protheus.ch'
#INCLUDE "TBICONN.CH"
//#INCLUDE "SERASA.ch"

#DEFINE MQOO_INPUT_AS_Q_DEF	1
#DEFINE MQGMO_WAIT 			1
#DEFINE MQGMO_CONVERT 			16384
#DEFINE LIMITE 				80
#DEFINE MQ_NO_MSG_AVAILABLE 	2033
#DEFINE MQ_NO_WAIT 			0
#DEFINE MQ_MSG_UNDER_CURSOR 	256
#DEFINE XMLSIZE 				65536


#define STR0010 "Data Inicial"
#define STR0011 "Data Final"
Static __cDriver

/*/{Protheus.doc} BFFINM30
(long_description)
	
@author MarceloLauschner
@since 28/03/2014
@version 1.0		

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function BFFINM30()

	Local 	aOpenTable 	:= {"SX6","SA1","SA3","SE4","SE1","SE2"}

	// Verifica se é via Schedule
	If Select("SM0") == 0
		// BigForta Matriz
		RPCSetType(3)
		RPCSetEnv("02","01","","","","",aOpenTable) // Abre todas as tabelas.
		Sleep(3000)
	Endif
	
	PutMv("BF_FATA30D",dDataBase)
	// AjustaSX1()
	
	If Pergunte("SERARELATO",.T.)
		Processa( {|| sfExecuta(.T.)},"Gerando dados...")
	Endif
		
Return


/*/{Protheus.doc} sfExecuta
(Executa funções para gerar o arquivo Relato)
	
@author MarceloLauschner
@since 28/03/2014
@version 1.0
		
@param lFirstEmp, Logico, Se a execução for para multiplas execuções permite adicionar ao arquivo já existente

@return sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfExecuta(lFirstEmp)

	Private 	nTamLin, cLin, cCpo
	Private	cArq 		:= AllTrim(MV_PAR04) //"\edi\Serasa\relato\envio\nomearquivo.TXT"
	Private	nHd    		:= Iif(lFirstEmp,fCreate(cArq),FOpen( cArq , FO_READWRITE ))
	Private	cEOL   		:= "CHR(13)+CHR(10)"
	Private nQteReg01	:= 0
	Private	nQteReg05	:= 0
	Private aListSE1	:= {}
	Private lIsHomologa	:= .F.
	Private	dLastDay	:= GetNewPar("BF_FATA30D",MV_PAR01)
	
	
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
			MsgAlert("A data limite do último arquivo gerado é '"+ DTOC(dLastDay) + "'. Portanto a data inicial deverá ser maior que esta data!","'BFFINM30.PRW.sfExecuta' - Data inicial inválida!")
			
			// Chamado 24.566 - Permite que determinados usuários possam alterar o parâmetro só por acessar a rotina. 
			If __cUserId $ GetNewPar("BF_FINM30X","000130#000364") .And. MsgYesNo("Deseja ajustar a data limite Final?")
		
	
				aPergs := {}
				aRet 	 := {}
	
				aAdd(aPergs,{1,"Informe nova Data Final",dLastDay,"","","","",70,.F.})

				If !ParamBox(@aPergs,"Ajustar Data Limite Final.",aRet)
					MsgAlert("Operação cancelada!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					fClose(nHd)
					Return
				Else
					PutMv("BF_FATA30D",MV_PAR01)
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
		PutMv("BF_FATA30D",MV_PAR02)
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
/*/Static Function sfReadConcilia()

	Local	nTamFile,nPos,nLinha,nDoc,cBuffer
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
	MsgAlert( nLast )

	While !FT_FEOF()   
		cLine  := FT_FReadLn() // Retorna a linha corrente  
		//nRecno := FT_FRecno()  // Retorna o recno da Linha  
		//MsgAlert( "Linha: " + cLine + " - Recno: " + StrZero(nRecno,3) )    
		// Pula para próxima linha  
		If Substr(cLine,1,2) =="00" .And. Substr(cLine,37,08) == "CONCILIA"
			lIsVldConc := .T.
			dDataLimite	:= STOD(cLine,45,8)
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
			If DbSeek(xFilial("SE1")+cKeySE1)
				//nSaldo := 	SaldoTit(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE,SE1->E1_MOEDA, dDataLimite,dDataLimite, SE1->E1_LOJA )	
				nSaldo	:= 	  	SaldoTit(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE,SE1->E1_MOEDA,            , dDataLimite,SE1->E1_LOJA)
				
				If nSaldo > 0
					// Grava data em branco
		 			cLine	:= Stuff(cLine,58,08,Replicate(" ",8))
		 		Else
		 			// Grava para exclusão do título pois não foi encontrado na SE1
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
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Ocorreu um erro na gravacao do arquivo.'"+cArq+"'"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
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
	cCpo += Padr("RELATO COMP NEGOCIOS"						,20)	// S=02-I=003-F=022-T=20 Constante 'RELATO COMP NEGOCIOS'
	cCpo += Padr(SM0->M0_CGC										,14)	// S=03-I=023-F=036-T=14 CNPJ da empresa conveniada
	cCpo += Padr(Iif(lRemNormal,DTOS(dDataIni),"CONCILIA")	,08)	// S=04-I=037-F=044-T=08 Remessa normal informar Data Inicio AAAAMMDD / Remessa Conciliação informar constante 'CONCILIA'
	cCpo += Padr(DTOS(dDataFim)									,08)	// S=05-I=045-F=052-T=08 Data final do periodo AAAAMMDD
	cCpo += Padr(cTpPeriodo										,01)	// S=06-I=053-F=053-T=01 Periodicidade da remessa = D=Diário M=Mensal S=Semanal Q=Quinzenal
	cCpo += Padr(Space(15)										,15)	// S=07-I=054-F=068-T=15 Reservado Serasa
	cCpo += Padr(Space(03)										,03)	// S=08-I=069-F=071-T=03 Numero identificador do Grupo Relato Segmento ou Brancos
	cCpo += Padr(Space(29)										,29)	// S=09-I=072-F=100-T=29 Branco
	cCpo += Padr("V."												,02)	// S=12-I=101-F=102-T=02 Identificação da versão do Layout Fixo 'V.'
	cCpo += Padr("01"												,02)	// S=13-I=103-F=104-T=02 Numero da Versão do Layout Fixo '01'
	cCpo += Padr(Space(26)										,26)	// S=14-I=105-F=130-T=26 Brancos
	 
	cLin := Stuff(cLin,01,nTamLin,cCpo)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
	//³ linha montada.                                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	If fWrite(nHd,cLin,Len(cLin)) != Len(cLin)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Ocorreu um erro na gravacao do arquivo.'"+cArq+"'"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		fClose(nHd)
		Return .F.
	Endif
	
Return .T.



Static Function sfDetRel()
	
	Local	cTpCliente	:= ""
	
	Local	cQry := ""
	
	cQry := "SELECT SUBSTR(A1_CGC,1,8) A1CGC,MIN(A1_CGC) A1_CGC, MIN(A1_PRICOM) A1_PRICOM, MAX(A1_ULTCOM) A1_ULTCOM "
	cQry += "  FROM "+RetSqlName("SA1") + " A1 "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND LENGTH(TRIM(A1_CGC)) = 14 "
	cQry += "   AND A1_TIPO NOT IN('X') "
	cQry += "   AND A1_MSBLQL != '1' "
	cQry += "   AND A1_EST NOT IN('EX') "
	cQry += "   AND A1_CGC NOT IN("+sfRetCgcEmp()+") "
	cQry += "   AND A1_PRICOM < '"+DTOS(MV_PAR02)+"' "
	cQry += " GROUP BY SUBSTR(A1_CGC,1,8) "
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
		cCpo += Padr(QSA1->A1_CGC									,14)	// S=02-I=003-F=016-T=14 Sacado Pessoa Juridica = CNPJ empresa Cliente
		cCpo += Padr("01"												,02)	// S=03-I=017-F=018-T=02 Tipo de dados = 01=Tempo de relacionamento para sacado pessoa juridica
		cCpo += Padr(QSA1->A1_PRICOM     							,08)	// S=04-I=019-F=026-T=08 Cliente desde AAAAMMDD
		cCpo += Padr(cTpCliente										,01)	// S=05-I=027-F=027-T=01 Tipo de cliente: 1=Antigo;2=Menos de um ano;3=Inativo
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
			FWLogMsg("INFO", /*cTransactionId*/, Funname()/*cCategory*/, /*cStep*/, /*cMsgId*/, "Ocorreu um erro na gravacao do arquivo.'"+cArq+"'"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
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
	
	cQry := "SELECT A1_CGC,E1_EMISSAO,E1_VALOR,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VENCREA,E1_RELATO,E1.D_E_L_E_T_ E1DELET, "
	cQry += "       CASE WHEN E1_SALDO = 0 THEN E1_BAIXA ELSE ' ' END E1_BAIXA "
	cQry += "  FROM "+RetSqlName("SA1") + " A1, "+RetSqlName("SE1") + " E1 "
	cQry += " WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND LENGTH(TRIM(A1_CGC)) = 14 "
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
	cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA') "
	cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
	cQry += "   AND E1_EMISSAO BETWEEN '"+ DTOS(MV_PAR01)+"' AND '"+ DTOS(MV_PAR02)+"' "
	cQry += "   AND E1_RELATO != '1' " // Somente títulos não enviados para o Serasa Relato
	cQry += "UNION ALL "
	cQry += "SELECT A1_CGC,E1_EMISSAO,E1_VALOR,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VENCREA,E1_RELATO,E1.D_E_L_E_T_ E1DELET, "
	cQry += "       CASE WHEN E1_SALDO = 0 THEN E1_BAIXA ELSE ' ' END E1_BAIXA "
	cQry += "  FROM "+RetSqlName("SA1") + " A1, "+RetSqlName("SE1") + " E1 "
	cQry += " WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND LENGTH(TRIM(A1_CGC)) = 14 "
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
	cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA') "
	cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
	cQry += "   AND E1_EMISSAO <='"+ DTOS(MV_PAR02)+"' "
	cQry += "   AND E1_RELATO = '1' " // Somente títulos enviados para o Serasa Relato e que foram excluidos do sistema
	cQry += "UNION ALL "
	cQry += "SELECT A1_CGC,E1_EMISSAO,E1_VALOR,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_VENCREA,E1_RELATO,E1.D_E_L_E_T_ E1DELET, "
	cQry += "       CASE WHEN E1_SALDO = 0 THEN E1_BAIXA ELSE ' ' END E1_BAIXA "
	cQry += "  FROM "+RetSqlName("SA1") + " A1, "+RetSqlName("SE1") + " E1 "
	cQry += " WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND LENGTH(TRIM(A1_CGC)) = 14 "
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
	cQry += "   AND E1_TIPO NOT IN('NCC','JR','CH','CHQ','RA') "
	cQry += "   AND E1_TIPO NOT IN ('"+MVIRABT+"','"+MVCSABT+"','"+MVCFABT+"','"+MVPIABT+"','"+ StrTran(MVABATIM,"|","','")+"')"
	cQry += "   AND E1_EMISSAO < '"+ DTOS(MV_PAR01)+"' "
	cQry += " ORDER BY A1_CGC,E1_PREFIXO,E1_NUM,E1_PARCELA "
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSE1', .F., .T.)
			
	While !Eof()
		
		If lIsHomologa .And. nQteReg05 > 2000
			Exit
		Endif
		
		
		cSE1Key	:= QSE1->E1_PREFIXO+QSE1->E1_NUM+QSE1->E1_PARCELA+QSE1->E1_TIPO
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
		cCpo += Padr(StrZero(Val(QSE1->A1_CGC),14)				,14)	// S=02-I=003-F=016-T=14 Sacado Pessoa Juridica = CNPJ empresa Cliente
		cCpo += Padr("05"												,02)	// S=03-I=017-F=018-T=02 Tipo de dados = 05=Titulos para sacado pessoa juridica
		cCpo += Padr(" "												,10)	// S=04-I=019-F=028-T=10 Numero do titulo com até 10 Posições
		cCpo += Padr(QSE1->E1_EMISSAO  								,08)	// S=05-I=029-F=036-T=08 Data emissão título AAAAMMDD
		cCpo += Padr(cE1VALOR										,13)	// S=06-I=037-F=049-T=13 Valor do titulo com 2 casas decimais. Zeros a esquerda. 9999999999999=para exclusão do título
		cCpo += Padr(QSE1->E1_VENCREA								,08)	// S=07-I=050-F=057-T=08 Data de vencimento AAAAMMDD
		cCpo += Padr(QSE1->E1_BAIXA									,08)	// S=08-I=058-F=065-T=08 Data pagamento ou brancos. No arquivo de conciliação do serasa virá com 99999999. No arquivo de envio de conciliação deverá ser enviado a data do pagamento
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
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Ocorreu um erro na gravacao do arquivo.'"+cArq+"'"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
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
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Ocorreu um erro na gravacao do arquivo.'"+cArq+"'"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		fClose(nHd)
		Return .F.
	Endif
	
Return lRet

Static Function AjustaSX1()

	// DbSelectArea("SX6")
	// DbSetOrder(1)
	
	//  
	// If !DbSeek(xFilial("SX6")+"BF_FATA30D")
	// 	RecLock("SX6",.T.)
	// 	SX6->X6_FIL     := xFilial( "SX6" )
	// 	SX6->X6_VAR     := "BF_FATA30D"
	// 	SX6->X6_TIPO    := "D"
	// 	SX6->X6_DESCRIC := "Relato Serasa-Data Final"
	// 	MsUnLock()
	// 	PutMv("BF_FATA30D",dDataBase)
	// EndIf


	// PutSx1( "SERARELATO",;
	// 	"01",;
	// 	STR0010,;
	// 	STR0010,;
	// 	STR0010,;
	// 	"mv_ch1",;
	// 	"D",;
	// 	8,;
	// 	0,;
	// 	0,;
	// 	"G",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"mv_par01",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"")
	// PutSx1( "SERARELATO",;
	// 	"02",;
	// 	STR0011,;
	// 	STR0011,;
	// 	STR0011,;
	// 	"mv_ch2",;
	// 	"D",;
	// 	8,;
	// 	0,;
	// 	0,;
	// 	"G",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"mv_par02",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"")
	// PutSx1( "SERARELATO",;
	// 	"03",;
	// 	"Arq.Origem",;
	// 	"Arq.Origem",;
	// 	"Arq.Origem",;
	// 	"mv_ch3",;
	// 	"C",;
	// 	60,;
	// 	0,;
	// 	0,;
	// 	"G",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"mv_par03",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"")
	// PutSx1( "SERARELATO",;
	// 	"04",;
	// 	"Destino",;
	// 	"Destino",;
	// 	"Destino",;
	// 	"mv_ch4",;
	// 	"C",;
	// 	60,;
	// 	0,;
	// 	0,;
	// 	"G",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"mv_par04",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"")
	// PutSx1( "SERARELATO",;
	// 	"05",;
	// 	"Tipo de Remessa",;
	// 	"Tipo de Remessa",;
	// 	"Tipo de Remessa",;
	// 	"mv_ch5",;
	// 	"N",;
	// 	1,;
	// 	0,;
	// 	0,;
	// 	"C",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"mv_par05",;
	// 	"Normal",;
	// 	"Normal",;
	// 	"Normal",;
	// 	"",;
	// 	"Conciliacao",;
	// 	"Conciliacao",;
	// 	"Conciliacao",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"",;
	// 	"")
	
Return



Static Function sfRetCgcEmp

	Local	aAreaSM0	:= SM0->(GetArea())
	Local	aRecSM0		:= {}
	Local	nRecSM0		:= SM0->(Recno())
	Local	cRetSM0		:= ""

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


User Function SERASA()

	Local aArea		:=  GetArea()
	Local cTitulo	:=	"SERASA - RELATO"
	Local cMsg1		:=	"   Esta rotina tem como objetivo gerar o arquivo pre-formatado para o sistema"
	Local cMsg2		:=	"SERASA/RELATO ( Relatorio de comportamento em Negocios ), conforme os parametos"
	Local cMsg3		:=	"da rotina e o manual de homologacao da SERASA."
	Local cNorma    	:= ""
	Local cDest     	:= ""
	Local cPerg		:= "SERASA"
	Local nOpcA		:= 0
	Local dDataIni  	:= dDataBase
	Local dDataFim  	:= dDataBase
	Local oDlg

	Private SERASA_PERIODO := ""

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta Tabela de Codigos de Unid. de Medida                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	FormBatch(cTitulo,{OemToAnsi(cMsg1),OemToAnsi(cMsg2),OemToAnsi(cMsg3)},;
		{ { 5,.T.,{|o| Pergunte(cPerg,.T.) }},;
		{ 1,.T.,{|o| nOpcA := 1,o:oWnd:End()}},;
		{ 2,.T.,{|o| nOpca := 2,o:oWnd:End()}}})
	If ( nOpcA==1 )
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Preparacao do inicio de processamento do arquivo pre-formatado          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cNorma := AllTrim(MV_PAR03)+".INI"
		cDest  := AllTrim(MV_PAR04)
		dDataIni:= MV_PAR01
		dDataFim:= MV_PAR02
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Ajusta a data inicial e final conforme o periodo identificado           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Do Case
		Case dDataFim-dDataIni >= 16 //Periodicidade Mensal
			SERASA_PERIODO := "Mensal" //"Mensal"
			dDataIni := FirstDay(dDataIni)
			dDataFim := LastDay(dDataIni)
		Case dDataFim-dDataIni >= 8 //Periodicidade Quinzenal
			SERASA_PERIODO := "Quinzenal" //"Quinzenal"
			If Day(dDataIni)>=16
				dDataIni := Stod(SubStr(Dtos(dDataIni),1,6)+"16")
				dDataFim := LastDay(dDataIni)
			Else
				dDataIni := FirstDay(dDataIni)
				dDataFim := Stod(SubStr(Dtos(dDataIni),1,6)+"15")
			EndIf
		Case dDataFim-dDataIni >= 5 //Periodicidade Semanal
			SERASA_PERIODO := "Semanal" //"Semanal"
			While Dow(dDataIni)==2
				dDataIni--
			EndDo
			dDataFim := dDataIni+6
		OtherWise //Periodicidade Diaria
			SERASA_PERIODO := "Diaria" //"Diaria"
			dDataFim := dDataIni
		EndCase
		If MV_PAR01 <> dDataIni .Or. MV_PAR02 <> dDataFim
			MsgInfo("Periodicidade ajustada para: "+SERASA_PERIODO) //"Periodicidade ajustada para: "
		EndIf
		MV_PAR01 := dDataIni
		MV_PAR02 := dDataFim

		Processa({||ProcNorma(cNorma,cDest)})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Reabre os Arquivos do Modulo desprezando os abertos pela Normativa      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbCloseAll()
		OpenFile(SubStr(cNumEmp,1,2))
	EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Restaura area                                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	RestArea(aArea)
Return(.T.)

User Function SERASARpc(nTipo,dDataIni,dDataFim,aArquivo,lSimp,lPrdR)

	Local aArea    		:= GetArea()
	Local aCampos  		:= {}
	Local cAliasSA1		:= "SA1"
	Local cAliasSE1		:= "SE1"
	Local cAliasSE5		:= "SE5"
	Local cQuebra  		:= ""
	Local cQuebra2 		:= ""
	Local cCliente 		:= ""
	Local cLoja    		:= ""
	Local cCNPJ    		:= ""
	Local lQuery   		:= .F.
	Local lPrazo   		:= .F.
	Local lValido  		:= .F.
	Local lValido2 		:= .F.
	Local lFirst   		:= .T.
	Local lSerasa01		:= ExistBlock("SERASA01")
	Local nX       		:= 0
	Local nVlrAcu  		:= 0
	Local dDataAcu 		:= Ctod("")
	Local dVencto  		:= Ctod("")
	Local dEmissao 		:= Ctod("")
	Local dInicio  		:= dDataIni
	Local cAlias 		:= ""
	Local cMVSERASA7	:= SuperGetMv("MV_SERASA7",.F.,5)
	Local oTmpTable

	#IFDEF TOP
		Local aStruSE1 := SE1->(dbStruct())
		Local aStruSE5 := SE5->(dbStruct())
		Local cQuery   := ""
	#ELSE
		Local cIndSE1  := CriaTrab(,.F.)
		Local cIndSE5  := SubStr(cIndSE1,1,7)+"A"
		Local cCondSE1 := ""
		Local cCondSE5 := ""
	#ENDIF

	DEFAULT lSimp := .F.
	DEFAULT lPrdR := .F.

	If nTipo == 1
		If lSimp
			SerasaSimp(dDataIni,dDataFim,aArquivo,lPrdR,lSerasa01)
		Else
			aArquivo := {"","","",""}
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Montagem do Arquivo Temporario - Perfil de Compras            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aadd(aCampos,{"CGC"   ,"C",14,0})
			aadd(aCampos,{"UCOMVL","N",14,2})
			aadd(aCampos,{"UCOMDT","D",08,0})
			aadd(aCampos,{"MFATVL","N",14,2})
			aadd(aCampos,{"MFATDT","D",08,0})
			aadd(aCampos,{"MACUVL","N",14,2})
			aadd(aCampos,{"MACUDT","D",08,0})
	
			// aArquivo[1] := CriaTrab(aCampos,.T.)
	
			// dbUseArea(.T.,__LocalDriver,aArquivo[1],"RPC")
			// IndRegua("RPC",aArquivo[1],"CGC")

			cAlias := "RPC"
			oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
			oTmpTable:Create()

			dbSelectArea(cAlias)
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Montagem do Arquivo Temporario - Pagamento a vista            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aCampos := {}
			aadd(aCampos,{"CGC"    ,"C",14,0})
			aadd(aCampos,{"AAMMPGT","N",06,0})
			aadd(aCampos,{"NUMDUP" ,"C",15,0})
			aadd(aCampos,{"QTPGT " ,"N",05,0})
			aadd(aCampos,{"VLPGT " ,"N",14,2})
			aadd(aCampos,{"DTPGT " ,"D",08,0})
			aadd(aCampos,{"DTVCT " ,"D",08,0})
			aadd(aCampos,{"DTEM  " ,"D",08,0})

			// aArquivo[2] := CriaTrab(aCampos,.T.)
	
			// dbUseArea(.T.,__LocalDriver,aArquivo[2],"RPV")
			// IndRegua("RPV",aArquivo[2],"CGC")

			cAlias := "RPV"
			oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
			oTmpTable:Create()

			dbSelectArea(cAlias)
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Montagem do Arquivo Temporario - Pagamento a prazo            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aCampos := {}
			aadd(aCampos,{"CGC"   ,"C",14,0})
			aadd(aCampos,{"NUMDUP","C",15,0})
			aadd(aCampos,{"DTVC  ","D",08,0})
			aadd(aCampos,{"DTPG  ","D",08,0})
			aadd(aCampos,{"DTEM  ","D",08,0})
			aadd(aCampos,{"VLPG  ","N",14,2})

			// aArquivo[3] := CriaTrab(aCampos,.T.)
	
			// dbUseArea(.T.,__LocalDriver,aArquivo[3],"RPP")

			cAlias := "RPP"
			oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
			oTmpTable:Create()

			dbSelectArea(cAlias)
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Montagem do indice  de acordo com o layout                    ³ 
		//³Ao gerar o Simplificado exclui a data do indice               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			// IndRegua("RPP",aArquivo[3],"CGC+NUMDUP")
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Montagem do Arquivo Temporario - Titulos em aberto            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aCampos := {}
			aadd(aCampos,{"CGC"     ,"C",14,0})
			aadd(aCampos,{"AAMMCOMP","C",06,0})
			aadd(aCampos,{"VLVENC"  ,"N",14,2})
			aadd(aCampos,{"VLAVENC" ,"N",14,2})

			// aArquivo[4] := CriaTrab(aCampos,.T.)
	
			// dbUseArea(.T.,__LocalDriver,aArquivo[4],"RVV")
			// IndRegua("RVV",aArquivo[4],"CGC+AAMMCOMP")

			cAlias := "RVV"
			oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
			oTmpTable:Create()

			dbSelectArea(cAlias)
	
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Calculo da data de inicio de processamento                    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			For nX := 1 To 12
				dDataIni := FirstDay(dDataIni)-1
			Next nX
			dDataIni := FirstDay(dDataIni)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Preparando o processamento dos registros financeiros          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
			#IFNDEF TOP
				ChkFile("SE1",.F.,"SE1_RPC")
	
				cCondSE1 := "E1_FILIAL='"+xFilial("SE1")+"' .AND. "
				cCondSE1 += "DTOS(E1_EMISSAO)>='"+Dtos(dDataIni)+"' .AND. "
				cCondSE1 += "DTOS(E1_EMISSAO)<='"+Dtos(dDataFim)+"' "
				dbSelectArea("SE1")
				IndRegua("SE1",cIndSE1,"E1_FILIAL+E1_CLIENTE+E1_LOJA+DTOS(E1_EMISSAO)",,cCondSe1)
				dbGotop()
				cCondSE5 := "E5_FILIAL='"+xFilial("SE5")+"' .AND. "
				cCondSE5 += "DTOS(E5_DATA)>='"+Dtos(dDataIni)+"' .AND. "
				cCondSE5+= "DTOS(E5_DATA)<='"+Dtos(dDataFim)+"' "
				dbSelectArea("SE5")
				IndRegua("SE5",cIndSE5,"E5_FILIAL+E5_CLIFOR+E5_LOJA+DTOS(E5_DATA)",,cCondSE5)
				dbGotop()
			#ELSE
				lQuery    := .T.
				cAliasSE1 := "SERASA_SE1"
				cAliasSA1 := "SERASA_SE1"
	
				cQuery := "SELECT SA1.A1_CGC,SE1.*"
				cQuery += "FROM "+RetSqlName("SE1")+" SE1, "
				cQuery += RetSqlName("SA1")+" SA1 "
				cQuery += "WHERE "
				cQuery += "SE1.E1_FILIAL='"+xFilial("SE1")+"' AND "
				cQuery += "SE1.E1_EMISSAO>='"+Dtos(dDataIni)+"' AND "
				cQuery += "SE1.E1_EMISSAO<='"+Dtos(dDataFim)+"' AND "
				cQuery += "SE1.D_E_L_E_T_=' ' AND "
				cQuery += "SA1.A1_FILIAL='"+xFilial("SA1")+"' AND "
				cQuery += "SA1.A1_COD=SE1.E1_CLIENTE AND "
				cQuery += "SA1.A1_LOJA=SE1.E1_LOJA AND "
				cQuery += "SE1.E1_TIPO >= '"+MV_PAR07+"' AND "
				cQuery += "SE1.E1_TIPO <= '"+MV_PAR08+"' AND "
				cQuery += "SA1.D_E_L_E_T_=' ' "
				cQuery += "ORDER BY E1_FILIAL,E1_CLIENTE,E1_LOJA,E1_EMISSAO "
	
				cQuery := ChangeQuery(cQuery)
	
				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE1)
				For nX := 1 To Len(aStruSE1)
					If aStruSE1[nX][2]<>"C"
						TcSetField(cAliasSE1,aStruSE1[nX][1],aStruSE1[nX][2],aStruSE1[nX][3],aStruSE1[nX][4])
					EndIf
				Next nX
			#ENDIF
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Processamento dos registros financeiros                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea(cAliasSE1)
			While !(cAliasSE1)->(Eof())
				If !lQuery
					dbSelectArea("SA1")
					dbSetOrder(1)
					MsSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)
				EndIf
				If !(cAliasSE1)->E1_TIPO$+MVRECANT+","+MV_CRNEG .And. IIf(!lSerasa01,.T.,ExecBlock("SERASA01",.F.,.F.,{cAliasSE1}))
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualizando os dados de Perfil de compras                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					dbSelectArea("RPC")
					If MsSeek((cAliasSA1)->A1_CGC)
						RecLock("RPC",.F.)
					Else
						RecLock("RPC",.T.)
					EndIf
					RPC->CGC    := (cAliasSA1)->A1_CGC
					If !(cAliasSE1)->E1_TIPO$MVABATIM+","+MVRECANT+","+MV_CRNEG
						RPC->UCOMVL := (cAliasSE1)->E1_VLCRUZ
						RPC->UCOMDT := (cAliasSE1)->E1_EMISSAO
						RPC->MFATDT := IIF((cAliasSE1)->E1_VLCRUZ>RPC->MFATVL,(cAliasSE1)->E1_EMISSAO,RPC->MFATDT)
						RPC->MFATVL := IIF((cAliasSE1)->E1_VLCRUZ>RPC->MFATVL,(cAliasSE1)->E1_VLCRUZ,RPC->MFATVL)
						MsUnLock()
					EndIf
					If (cAliasSE1)->E1_TIPO$MVABATIM
						dDataAcu := (cAliasSE1)->E1_EMISSAO
						nVlrAcu  -= (cAliasSE1)->E1_VLCRUZ
					Else
						dDataAcu := (cAliasSE1)->E1_EMISSAO
						nVlrAcu  += (cAliasSE1)->E1_VLCRUZ
					EndIf
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualiza compromissos vencidos e a vencer                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If (cAliasSE1)->E1_SALDO > 0
						dbSelectArea("RVV")
						If MsSeek((cAliasSA1)->A1_CGC)
							RecLock("RVV")
						Else
							RecLock("RVV",.T.)
						EndIf
						RVV->CGC      := (cAliasSA1)->A1_CGC
						RVV->AAMMCOMP := Dtos(dDataFim)
						If (cAliasSE1)->E1_VENCREA+cMVSERASA7 <= dDataFim
							RVV->VLVENC  += xMoeda((cAliasSE1)->E1_SALDO,(cAliasSE1)->E1_MOEDA,1)
						Else
							RVV->VLAVENC += xMoeda((cAliasSE1)->E1_SALDO,(cAliasSE1)->E1_MOEDA,1)
						EndIf
						MsUnLock()
					EndIf
				
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Verifica a quebra para verificar nos registros de rebimento   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
					cQuebra := (cAliasSE1)->E1_FILIAL+Dtos((cAliasSE1)->E1_EMISSAO)+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA
					cQuebra2:= (cAliasSE1)->E1_FILIAL+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA
					dEmissao:= (cAliasSE1)->E1_EMISSAO
					cCliente:= (cAliasSE1)->E1_CLIENTE
					cLoja   := (cAliasSE1)->E1_LOJA
					cCNPJ   := (cAliasSA1)->A1_CGC
				EndIf
				dbSelectArea(cAliasSE1)
				dbSkip()
				If (cAliasSE1)->(Eof()) .Or. cQuebra <> (cAliasSE1)->E1_FILIAL+Dtos((cAliasSE1)->E1_EMISSAO)+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Processa os registros de recebimento                          ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					#IFDEF TOP
						lQuery := .T.
						cAliasSE5 := "SERASA_SE5"
	
						cQuery := "SELECT SE5.*,SE1.E1_VENCTO,SE1.E1_VENCREA,SE1.E1_EMISSAO,SE1.E1_TIPO "
						cQuery += "FROM "+RetSqlName("SE5")+" SE5,"
						cQuery += RetSqlName("SE1")+" SE1 "
						cQuery += "WHERE "
						cQuery += "SE5.E5_FILIAL='"+xFilial("SE5")+"' AND "
						cQuery += "SE5.E5_DATA>='"+Dtos(IIf(lFirst,dDataIni,dEmissao))+"' AND "
						If !(cAliasSE1)->(Eof()) .And. cQuebra2 == (cAliasSE1)->E1_FILIAL+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA
							cQuery += "SE5.E5_DATA<'"+DTOS((cAliasSE1)->E1_EMISSAO)+"' AND "
						EndIf
						cQuery += "SE5.E5_CLIFOR='"+cCliente+"' AND "
						cQuery += "SE5.E5_LOJA='"+cLoja+"' AND "
						cQuery += "SE5.D_E_L_E_T_=' ' AND "
						cQuery += "((SE5.E5_TIPODOC IN('VL','BA','V2','CP','LJ') AND "
						cQuery += "SE5.E5_RECPAG='R') OR "
						cQuery += "(SE5.E5_TIPODOC = 'ES' AND SE5.E5_RECPAG='P')) AND "
						cQuery += "SE5.E5_NUMERO<>'"+Space(Len(SE1->E1_NUM))+"' AND "
						cQuery += "SE5.D_E_L_E_T_=' ' AND "
						cQuery += "SE1.E1_FILIAL='"+xFilial("SE1")+"' AND "
						cQuery += "SE1.E1_PREFIXO=SE5.E5_PREFIXO AND "
						cQuery += "SE1.E1_NUM=SE5.E5_NUMERO AND "
						cQuery += "SE1.E1_PARCELA=SE5.E5_PARCELA AND "
						cQuery += "SE1.E1_TIPO=SE5.E5_TIPO AND "
						cQuery += "SE1.E1_CLIENTE=SE5.E5_CLIFOR AND "
						cQuery += "SE1.E1_LOJA=SE5.E5_LOJA AND "
						cQuery += "SE1.E1_FATURA IN('"+Space(Len(SE1->E1_FATURA))+"'"+",'NOTFAT') AND "
						cQuery += "SE1.E1_TIPO >= '"+MV_PAR07+"' AND "
						cQuery += "SE1.E1_TIPO <= '"+MV_PAR08+"' AND "
						cQuery += "SE1.D_E_L_E_T_=' ' "
						cQuery += "ORDER BY E5_FILIAL,E5_CLIFOR,E5_LOJA,E5_DATA"
	
						cQuery := ChangeQuery(cQuery)
	
						dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE5)
						For nX := 1 To Len(aStruSE5)
							If aStruSE5[nX][2]<>"C"
								TcSetField(cAliasSE5,aStruSE5[nX][1],aStruSE5[nX][2],aStruSE5[nX][3],aStruSE5[nX][4])
							EndIf
						Next nX
						TcSetField(cAliasSE5,"E1_VENCTO"  ,"D",08,00)
						TcSetField(cAliasSE5,"E1_VENCREA" ,"D",08,00)
						TcSetField(cAliasSE5,"E1_EMISSAO" ,"D",08,00)
					#ELSE
						dbSelectArea(cAliasSE5)
						MsSeek(xFilial("SE5")+cCliente+cLoja+IIf(lFirst,"",Dtos(dEmissao)),.T.)
					#ENDIF
					While !Eof() .And. xFilial("SE5") == (cAliasSE5)->E5_FILIAL .And.;
							IIf(lFirst,dDataIni,dEmissao) <= (cAliasSE5)->E5_DATA .And.;
							((cAliasSE5)->E5_DATA < (cAliasSE1)->E1_EMISSAO .Or. (cAliasSE1)->(Eof()) .Or. cQuebra2 <> (cAliasSE1)->E1_FILIAL+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA ).And.;
							cCliente == (cAliasSE5)->E5_CLIFOR .And.;
							cLoja == (cAliasSE5)->E5_LOJA
						
	           
						lValido2 := .T.
						lFirst   := .F.
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Retirar os recebimentos do dia do maior acumulo               ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ	
						If !lQuery
							dbSelectArea("SE1_RPC")
							dbSetOrder(1)
							If MsSeek(xFilial("SE1")+(cAliasSE5)->E5_PREFIXO+(cAliasSE5)->E5_NUMERO+(cAliasSE5)->E5_PARCELA+(cAliasSE5)->E5_TIPO+(cAliasSE5)->E5_CLIFOR+(cAliasSE5)->E5_LOJA)
								If SE1_RPC->E1_EMISSAO>=dDataIni
									lValido := .T.
								Else
									lValido := .F.
								EndIf
							Else
								lValido := .F.
								lValido2:= .F.
							EndIf
						
							If SE1_RPC->E1_TIPO < MV_PAR07 .OR. SE1_RPC->E1_TIPO > MV_PAR08
								lValido2:=.F.
							EndIf
						
							If SE1_RPC->E1_TIPO$MVABATIM+","+MVRECANT+","+MV_CRNEG .Or. SE1_RPC->(Eof()) .Or. !(((cAliasSE5)->E5_TIPODOC $ "VL#BA#V2#CP#LJ" .And. (cAliasSE5)->E5_RECPAG == "R") .Or.;
									((cAliasSE5)->E5_TIPODOC == "ES" .And. (cAliasSE5)->E5_RECPAG == "P")) .And.;
									!(SE1_RPC->E1_FATURA=="NOTFAT" .Or. Empty(SE1_RPC->E1_FATURA))
								lValido2:= .F.
							EndIf
	
						Else
							If (cAliasSE5)->E1_TIPO$MVABATIM+","+MVRECANT+","+MV_CRNEG
								lValido2:= .F.
							Else
								lValido := .T.
							EndIf
						EndIf
						If lValido2
							If lValido
								If ((cAliasSE5)->E5_TIPODOC $ "VL#BA#V2#CP#LJ" .And. (cAliasSE5)->E5_RECPAG == "R") .Or.;
										((cAliasSE5)->E5_TIPODOC == "ES" .And. (cAliasSE5)->E5_RECPAG == "P")
									If (cAliasSE5)->E5_TIPODOC <> "ES"
										nVlrAcu -= (cAliasSE5)->E5_VALOR
									Else
										nVlrAcu += (cAliasSE5)->E5_VALOR
									EndIf
								EndIf
							EndIf
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Verifica os pagamentos a vista e a prazo                      ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If !lQuery
								If SE1_RPC->E1_EMISSAO<>(cAliasSE5)->E5_DATA
									lPrazo  := .T.
								Else
									lPrazo := .F.
								EndIf
								dVencto := SE1_RPC->E1_VENCREA
							Else
								lPrazo := (cAliasSE5)->E1_EMISSAO<>(cAliasSE5)->E5_DATA
								dVencto := (cAliasSE5)->E1_VENCREA
							EndIf
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Atualiza pagamentos a prazo                                   ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If (cAliasSE5)->E5_DATA >= dInicio .And. (cAliasSE5)->E5_DATA <= dDataFim
								If lPrazo
									dbSelectArea("RPP")
									If MsSeek(cCNPJ+(cAliasSE5)->E5_PREFIXO+(cAliasSE5)->E5_NUMERO+(cAliasSE5)->E5_PARCELA+(cAliasSE5)->E5_TIPO+(cAliasSE5)->E5_SEQ)
										RecLock("RPP")
									Else
										RecLock("RPP",.T.)
									EndIf
									RPP->CGC    := cCNPJ
									RPP->NUMDUP := (cAliasSE5)->E5_PREFIXO+(cAliasSE5)->E5_NUMERO+(cAliasSE5)->E5_PARCELA+(cAliasSE5)->E5_TIPO+(cAliasSE5)->E5_SEQ
									RPP->DTVC   := dVencto
									RPP->DTPG   := (cAliasSE5)->E5_DATA
									If lQuery
										RPP->DTEM   := (cAliasSE5)->E1_EMISSAO
									Else
										RPP->DTEM   := SE1_RPC->E1_EMISSAO
									EndIf
									If (cAliasSE5)->E5_TIPODOC=="ES"
										RPP->VLPG   -= (cAliasSE5)->E5_VALOR
									Else
										RPP->VLPG   += (cAliasSE5)->E5_VALOR
									EndIf
									MsUnLock()
								Else
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Atualiza pagamentos a vista                                   ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									dbSelectArea("RPV")
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Ao gerar o simplificado separa por titulos                    ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									If MsSeek(cCNPJ)
										RecLock("RPV")
									Else
										RecLock("RPV",.T.)
									EndIf
									RPV->CGC     := cCNPJ
									RPV->AAMMPGT := Val(SubStr(Dtos((cAliasSE5)->E5_DATA),1,6))
									RPV->DTPGT   := (cAliasSE5)->E5_DATA
									RPV->NUMDUP  := (cAliasSE5)->E5_PREFIXO+(cAliasSE5)->E5_NUMERO+(cAliasSE5)->E5_PARCELA+(cAliasSE5)->E5_TIPO+(cAliasSE5)->E5_SEQ
									RPV->DTVCT   := dVencto
									If lQuery
										RPV->DTEM    := (cAliasSE5)->E1_EMISSAO
									Else
										RPV->DTEM    := SE1->E1_EMISSAO
									EndIf
									If (cAliasSE5)->E5_TIPODOC=="ES"
										RPV->QTPGT--
										RPV->VLPGT -= (cAliasSE5)->E5_VALOR
									Else
										RPV->QTPGT++
										RPV->VLPGT += (cAliasSE5)->E5_VALOR
									EndIf
									RPV->QTPGT := Max(0,RPV->QTPGT)
									RPV->VLPGT := Max(0,RPV->VLPGT)
									MsUnLock()
								EndIf
							EndIf
						EndIf
						dbSelectArea(cAliasSE5)
						dbSkip()
					EndDo
					If lQuery
						dbSelectArea(cAliasSE5)
						dbCloseArea()
						dbSelectArea(cAliasSE1)
					EndIf
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualiza o maior acumulo                                      ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If nVlrAcu > RPC->MACUVL
						RecLock("RPC")
						RPC->MACUVL := nVlrAcu
						RPC->MACUDT := dDataAcu
						MsUnLock()
					EndIf
				EndIf
				If (cAliasSE1)->(Eof()) .Or. cQuebra2 <> (cAliasSE1)->E1_FILIAL+(cAliasSE1)->E1_CLIENTE+(cAliasSE1)->E1_LOJA
					nVlrAcu := 0
					lFirst  := .T.
				EndIf
				dbSelectArea(cAliasSE1)
			EndDo
			If lQuery
				dbSelectArea(cAliasSE1)
				dbCloseArea()
				dbSelectArea("SE1")
			EndIf
			dbSelectArea("RPC")
			dbGotop()
		EndIf
	Else
		If !lSimp
			dbSelectArea("RPC")
			dbCloseArea()
			dbSelectArea("RPV")
			dbCloseArea()
			dbSelectArea("RVV")
			dbCloseArea()
		EndIf
		dbSelectArea("RPP")
		dbCloseArea()
		For nX := 1 To Len(aArquivo)
			FErase(aArquivo[nX]+GetDbExtension())
			FErase(aArquivo[nX]+OrdBagExt())
		Next nX
		dbSelectArea("SM0")
	EndIf
	RestArea(aArea)
Return(Nil)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³SERASAList³ Autor ³ Eduardo Riera         ³ Data ³25.05.2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Rotina de comunicacao com o MqSeries desenvolvimendo para    ³±±
±±³          ³integracao com o IP23 da SERASA                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Rotina de comunicacao com o MQseries. Deve ser utilizado na  ³±±
±±³          ³seccao ONSTART do Aplication Server ( AP6 )                  ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³SERASA                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function SERASAListen()

	Local aEmpresa := {}
	Local aMensagem:= {}
	Local lErro    := .F.

	Local lBloqueia:= .F.
	Local lRejeita := .F.
	Local cMsgBlq  := ""
	Local cMsgFea  := ""
	Local cMsgRsk  := ""
	Local cXml     := ""
	Local cAux     := ""
	Local cBloco   := ""
	Local cManager := "ERR"
	Local cServer  := "ERR"
	Local cChannel := "ERR"
	Local cQueuePut:= "ERR"
	Local cQueueGet:= "ERR"
	Local cQueueDyn:= "ERR"
	Local cLogin   := "ERR"
	Local cPassWord:= "ERR"
	Local cNewPass := "ERR"
	Local cSleep   := "120"
	Local nMQhld   := 0
	Local nMQPort1 := 0
	Local nMQPort2 := 0
	Local nMQCode  := 0
	Local nMQErro  := 0
	Local nMQOption:= 0
	Local nX       := 0
	Local nRecno   := 0
	Local nCnt     := 0
	Local nRisco   := 0
	Local nPriNad  := 0


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Iniciando o Listen da SERASA                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Set Dele On

	FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, PadC("SERASA - Produto Resumido ( String de Dados - IP23 )",LIMITE)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Autenticando empresas validas                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbUseArea(.T.,"TOPCONN","SIGAMAT.EMP", "SIGAMAT",.T.,.T.)
	dbSelectArea("SIGAMAT")
	dbGotop()
	While ( !Eof() )
		aadd(aEmpresa,{SIGAMAT->M0_CODIGO+SIGAMAT->M0_CODFIL,SIGAMAT->M0_CODIGO,SIGAMAT->M0_CODFIL })
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, PadR("Started Company: ",20)+SIGAMAT->M0_NOME+"/"+SIGAMAT->M0_FILIAL/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		dbSelectArea("SIGAMAT")
		dbSkip()
	EndDo
	dbSelectArea("SIGAMAT")
	dbCloseArea()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicialiacao do Repositorio                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If IniRepo()
		// ConOut(PadR("Repository: ",20)+"Started")
		FWLogMsg("INFO", /*cTransactionId*/, Funname()/*cCategory*/, /*cStep*/, /*cMsgId*/, PadR("Repository: ",20)+"Started"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		lErro := .T.
	EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicialiacao comunicacao com MqSeries                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cManager  := GetSrvProfString("SERASAMQseriesManager",  cManager)
	cServer   := GetSrvProfString("SERASAMQseriesServer",   cServer)
	cChannel  := GetSrvProfString("SERASAMQseriesChannel",  cChannel)
	cQueuePut := GetSrvProfString("SERASAMQseriesQueuePut",cQueuePut)
	cQueueGet := GetSrvProfString("SERASAMQseriesQueueGet",cQueueGet)
	cQueueDyn := GetSrvProfString("SERASAMQseriesQueueDyn",cQueueDyn)
	cSleep    := GetSrvProfString("SERASAInterval",cSleep)
	If ( "ERR"$cManager .Or. "ERR"$cServer .Or. "ERR"$cChannel .Or. "ERR"$cQueuePut .Or. "ERR"$cQueueGet .Or. "ERR"$cQueueDyn)
		lErro := .T.
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: parameters SERASAManager,SERASAServer,SERASAChannel in Environment - AP6"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Parameters-> "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesServer  : "+cServer/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesManager : "+cManager/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesChannel : "+cChannel/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesQueuePut: "+cQueuePut/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesQueueGet: "+cQueueGet/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesQueueDyn: "+cQueueDyn/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASASleep: "+cQueueDyn/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	ElseIf !MQConnect(cManager,cServer,cChannel,@nMQhld,@nMQCode,@nMQErro)
		lErro := .T.
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: comunication failure with MQseries"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Parameters-> "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesServer  : "+cServer/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesManager : "+cManager/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesChannel : "+cChannel/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             ErrorCode : "+AllTrim(Str(nMQerro,15))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		nMQOption := MQOO_INPUT_AS_Q_DEF
		If MQOpen(@nMQhld,cQueueGet, @nMQPort2, @nMQCode, @nMQErro, @nMQOption,@cQueueDyn)
			// ConOut(PadR("MQseries (Get): ",20)+"Started")
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, PadR("MQseries (Get): ",20)+"Started"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Else
			lErro := .T.
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: comunication failure with MQseries"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Parameters-> "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesServer  : "+cServer/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesManager : "+cManager/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesChannel : "+cChannel/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesQueueGet: "+cQueueGet/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesQueueDyn: "+cQueueDyn/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             ErrorCode : "+AllTrim(Str(nMQerro,15))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Dinamic Queue"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			MQDisconnect(@nMQhld,@nMQCode, @nMQErro)
		EndIf
		nMqOption := 0
		If MQOpen(@nMQhld, cQueuePut, @nMQPort1, @nMQCode, @nMQErro, @nMQOption)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, PadR("MQseries (Put): ",20)+"Started"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Else
			lErro := .T.
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: comunication failure with MQseries"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Parameters-> "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesServer  : "+cServer/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesManager : "+cManager/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesChannel : "+cChannel/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAMQseriesQueuePut: "+cQueuePut/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             ErrorCode : "+AllTrim(Str(nMQerro,15))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			MQDisconnect(@nMQhld,@nMQCode, @nMQErro)
		EndIf
	EndIf
	If ( !lErro )
		cLogin     := PadR(GetSrvProfString("SERASALogin",cLogin),8)
		cPassWord  := PadR(GetSrvProfString("SERASAPassWord",cPassWord),8)
		cNewPass   := PadR(GetSrvProfString("SERASANewPassWord",cNewPass),8)
		If "ERR"$cLogin .Or. "ERR"$cPassWord .Or. "ERR"$cNewpass
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: comunication failure with Serasa"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Parameters-> "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASALogin    : "+cLogin/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASAPassWord : "+cPassWord/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "             SERASANewPassWord : "+cNewPass/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			MQDisconnect(@nMQhld,@nMQCode, @nMQErro)
			lErro := .T.
		EndIf
	EndIf
	If ( !lErro )
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, PadR("Listener: ",20)+"Started"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Processa recebimento/transmissao dos dados                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		While !KillApp()
			dbSelectArea("MSSERASA")
			MsSeek("T1")
			nCnt := 0
			While ( !Eof() .And. MSSERASA->SRZ_CLASSE=="T" .And. MSSERASA->SRZ_STATUS=="1" )
				RpcConOut("Listener SERASA: sending...")

				dbSelectArea("MSSERASA")
				dbSkip()
				nRecNo := MSSERASA->(RecNo())
				dbSkip(-1)

				PREPARE ENVIRONMENT EMPRESA MSSERASA->SRZ_CODEMP FILIAL MSSERASA->SRZ_CODFIL MODULO "FAT"
				Begin Transaction
					RecLock("MSSERASA")
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Transmitindo dados para a SERASA                                   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ			
					If MQPut(@nMQhld,@nMQPort1,@nMQCode,@nMQErro,@nMQOption,cLogin+cPassWord+cNewPass+MSSERASA->SRZ_XML,cQueueDyn)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Recebendo dados da SERASA                                          ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						RpcConOut("Listener SERASA: receiving")
						cXml := Space(XMLSIZE)
						If ( MQGet(@nMQhld,@nMQPort2,@nMQCode,@nMQErro,MQGMO_WAIT+MQGMO_CONVERT,@cXml,XMLSIZE) )
							If SubStr(cXml,1,4)=="#INI"
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Parse da mensagem                                                  ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								aMensagem := {}
								cBloco    := ""
								cAux      := ""
								cXML      := AllTrim(cXML)
								lBloqueia := .F.
								lRejeita  := .F.
								For nX := 1 To Len(cXML)
									cAux := SubStr(cXml,nX,1)
									If cAux == "#" .Or. nX == Len(cXml)
										If !Empty(cBloco)
											aadd(aMensagem,cBloco)
											cBloco := ""
											cBloco += cAux
										Else
											cBloco += cAux
										EndIf
									Else
										cBloco += cAux
									EndIf
								Next nX
								nRisco  := -1
								nPrinad := -1
								cMsgBlq := ""
								cMsgRsk := ""
								cMsgFea := ""
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Interpretacao da mensagem                                          ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								For nX := 1 To Len(aMensagem)
									cBloco := aMensagem[nX]
									While !Empty(cBloco)
										Do Case
										Case SubStr(cBloco,1,4) $ "#INI,#BLC,#FIM"
											cBloco := SubStr(cBloco,9)
											If SubStr(cBloco,1,8) $ "IP23RTMC,IP23RTME,IP23RTMI" //Mensagem de advertencia do lay-out
												FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "MENSAGEM SERASA.: "+SubStr(cBloco,9,79)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
												cBloco := SubStr(cBloco,88)
											EndIf
											If SubStr(cBloco,1,8) == "IP23RTOK" //Mensagem de advertencia do lay-out
												If SubStr(cBloco,45,1)=="S"
													lBloqueia := .T.
												EndIf
											EndIf
											cBloco := ""
										Case SubStr(cBloco,1,8) $ "#L010000" //Dados de Controle da empresa consultada
											If SubStr(cBloco,8,2) <> "02"
												lBloqueia := .T.
												If SubStr(cBloco,8,2)$GetNewPar("MV_SERASA6","00,07,06,09")
													lRejeita := .T.
												EndIf
											EndIf
											cBloco := ""
										Case SubStr(cBloco,1,8) $ "#L010199" //Mensagens de Bloco
											cMsgBlq := AllTrim(SubStr(cBloco,9))
											cBloco := ""
										Case SubStr(cBloco,1,8) $ "#L030103" //Alerta Feature
											cMsgFea := AllTrim(SubStr(cBloco,9))
											cBloco := ""
											lBloqueia := .T.
										Case SubStr(cBloco,1,8) $ "#L070101" //RiskScoring
											nRisco  := Val(SubStr(cBloco,25,4))
											nPriNad := Val(SubStr(cBloco,30,4))
											cBloco := ""
										Case SubStr(cBloco,1,8) $ "#L070199" //Informacoes RiskScoring
											cMsgRsk := AllTrim(SubStr(cBloco,9))
											cBloco := ""
										OtherWise
											cBloco := ""
										EndCase
									EndDo
								Next nX
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Processamento da Mensagem                                          ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								MSSERASA->SRZ_STATUS := "2"
								If SubStr(MSSERASA->SRZ_TAG,Len(SA1->A1_COD)+Len(SA1->A1_LOJA)+1,1)=="Z"
									SerLibCrRS(SubStr(MSSERASA->SRZ_TAG,1,Len(SA1->A1_COD)),SubStr(MSSERASA->SRZ_TAG,Len(SA1->A1_COD)+1,Len(SA1->A1_LOJA)),lBloqueia,lRejeita,nRisco,nPrinad)
								EndIf
								SerMsgRef(SubStr(MSSERASA->SRZ_TAG,1,Len(SA1->A1_COD)),SubStr(MSSERASA->SRZ_TAG,Len(SA1->A1_COD)+1,Len(SA1->A1_LOJA)),cMsgBlq,cMsgFea,cMsgRsk)
							Else
								MSSERASA->SRZ_STATUS := "2"
								FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: "+AllTrim(cXml)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							EndIf
						ElseIf nMQerro == MQ_NO_MSG_AVAILABLE
							MSSERASA->SRZ_STATUS := "2"
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: No Response"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Else
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: comunication failure with MQseries"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "ErrorCode: "+AllTrim(Str(nMQErro,15))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						EndIf
					Else
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: comunication failure with MQseries"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "ErrorCode: "+AllTrim(Str(nMQErro,15))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					EndIf
					MSSERASA->(MsUnLock())
				End Transaction

				dbSelectArea("MSSERASA")
				MsGoto(nRecno)
				RESET ENVIRONMENT
				IniRepo()
				__RpcCalled := Nil
			EndDo
			nX := 0
			While nX < Val(cSleep) .and. !KillApp()
				Sleep(1000)
				nX++
			EndDo
		EndDo
		MQDisconnect(@nMQhld,@nMQCode,@nMQErro)
	Else
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Warning: Listener start failure"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
Return(.T.)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³IniRepo   ³ Autor ³ Eduardo Riera         ³ Data ³25.05.2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Rotina de inicializacao do repositorio das rotinas de integra³±±
±±³          ³cao com o SERASA                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³                                                             ³±±
±±³          ³                                                             ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Serasa                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function IniRepo()

	Local aArea     := GetArea()
	Local aNew      := {}
	Local aOld      := {}
	Local nX        := 0
	Local nY        := 0
	Local cRepName  := ""
	Local cIndRep   := cRepName
	Local lNewStru  := .F.
	Local lRetorno  := .T.

	If ( Select("MSSERASA") == 0 )
		DEFAULT __cDriver := "ERR"
		__cDriver := GetSrvProfString("SERASADriver",__cDriver)
		If ( __cDriver == "ERR")
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro: Configurar parametro SerasaDriver no Environment do AP6"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			lRetorno := .F.
		Else
			cRepName := RetArq(__cDriver,"MSSERASA",.T.)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Inicializa a estrutura do repositorio da Serasa                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aadd(aNew,{"SRZ_CODEMP","C",02,00})
			aadd(aNew,{"SRZ_CODFIL","C",02,00})
			aadd(aNew,{"SRZ_DATA"  ,"D",08,00})
			aadd(aNew,{"SRZ_TIME"  ,"C",08,00})
			aadd(aNew,{"SRZ_CLASSE","C",01,00})
			aadd(aNew,{"SRZ_STATUS","C",01,00})
			aadd(aNew,{"SRZ_XML"   ,"M",10,00})
			aadd(aNew,{"SRZ_TAG"   ,"C",30,00})
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verifica se o arquivo existe                                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If ( !MsFile(cRepName,,__cDriver) )
				dbCreate(cRepName,aNew,__cDriver)
			EndIf
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Abre o repositorio                                                      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbUseArea(.T.,__cDriver,cRepName,"MSSERASA",.T.,.F.)
			If ( !NetErr() )
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Verifica se a estrutura deve ser ajustada                               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				aOld := dbStruct()
				If ( Len(aNew) <> Len(aOld) )
					lNewStru := .T.
				Else
					For nX := 1 To Len(aNew)
						nY := aScan(aOld,{|x| x[1]==aNew[nX][1]})
						If ( nY <> 0 )
							If (aNew[nX][2]<>aOld[nY][2].Or.aNew[nX][3]<>aOld[nY][3].Or.aNew[nX][4]<>aOld[nY][4])
								lNewStru := .T.
								Exit
							EndIf
						Else
							lNewStru := .T.
							Exit
						EndIf
					Next nX
				EndIf
				If ( lNewStru )
					dbSelectArea("MSSERASA")
					dbCloseArea()
					dbUseArea(.T.,__cDriver,cRepName,"MSSERASA",.F.,.F.)
					If ( !NetErr() )
						dbCreate("SRZ.NEW",aNew,__cDriver)
						dbUseArea(.T.,__cDriver,"SRZ.NEW","NEW",.F.,.F.)
						dbSelectArea("MSSERASA")
						dbGotop()
						While ( !Eof() )
							dbSelectArea("NEW")
							dbAppend(.T.)
							For nX := 1 To FCount()
								nY := MSSERASA->(FieldPos(NEW->(FieldName(nX))))
								FieldPut(nX,MSSERASA->(FieldGet(nY)))
							Next nX
							dbRUnLock()
							dbSelectArea("MSSERASA")
							dbSkip()
						EndDo
						dbSelectArea("NEW")
						dbCloseArea()
						dbSelectArea("MSSERASA")
						dbCloseArea()
						FRename(cRepName,"SRZ.OLD")
						If ( FError() <> 0 )
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro: Falha na tentativa de ajustar o Repositorio"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							lRetorno := .F.
						Else
							FRename("SRZ.NEW",cRepName)
							If ( FError() == 0 )
								FErase("SRZ.OLD")
							EndIf
							dbUseArea(.T.,__cDriver,cRepName,"MSSERASA",.F.,.F.)
						EndIf
					Else
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro: Falha na tentativa de ajustar o Repositorio"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						lRetorno := .F.
					EndIf
				EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Verifica a existencia do indice.                                        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				dbSelectArea("MSSERASA")
				cIndRep := "MSSERASA"
				cIndRep := RetArq(__cDriver,cIndRep,.F.)
				If ( !MsFile(cRepName,cIndRep,__cDriver) )
					INDEX ON SRZ_CLASSE+SRZ_STATUS+SRZ_CODEMP+SRZ_CODFIL+SRZ_TAG TAG &(RetFileName(cIndRep)) TO &(FileNoExt(cRepName))
				Else
					dbSetIndex(cIndRep)
				EndIf
			Else
				FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro: Falha na tentativa de criar o Repositorio"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				lRetorno := .F.
			EndIf
		EndIf
	EndIf
	If ( AllTrim(aArea[1]) <> "" )
		RestArea(aArea)
	EndIf
Return(lRetorno)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³SerSolLbCR³ Autor ³ Eduardo Riera         ³ Data ³01.07.2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Rotina de solicitacao de liberacao de credito atraves da ana-³±±
±±³          ³lise de RiskScoring.                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpC1: Codigo do Cliente                                     ³±±
±±³          ³ExpC2: Loja do Cliente                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Esta rotina atualiza o repositorio do Serasa para envio da   ³±±
±±³          ³mensagem atraves do Listen                                   ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Serasa                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
User Function SerSolLbCR()

	Local aArea := GetArea()
	Local cTexto:= ""
	Local lEnvia := SA1->A1_RISCO=="Z"
	Local lEnviou:= .F.
	Local lSerasa:= GetNewPar("MV_SERASA",.F.)
	Local nDias  := GetNewPar("MV_SERASA5",0)

	#IFDEF TOP
		Local cQuery := ""
	#ENDIF

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se eh pessoa juridica para efetuar o envio                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lSerasa .And. Len(AllTrim(SA1->A1_CGC))==14
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Caso nao seja risco Z deve-se verificar a periodicidade de atualizacao  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !lEnvia .And. nDias <> 0
			#IFDEF TOP
				cQuery := "SELECT MAX(AO_DATA) MAXDATA"
				cQuery += "FROM "+RetSqlName("SAO")+" SAO "
				cQuery += "WHERE SAO.AO_FILIAL='"+xFilial("SAO")+"' AND "
				cQuery += "SAO.AO_CLIENTE='"+SA1->A1_COD+"' AND "
				cQuery += "SAO.AO_LOJA='"+SA1->A1_LOJA+"' AND "
				cQuery += "SAO.AO_TIPO='1' AND "
				cQuery += "SAO.AO_NOMINS LIKE '%SERASA%' AND "
				cQuery += "(SAO.AO_NOMFUN LIKE '%MSGBLOCO%' OR "
				cQuery += "SAO.AO_NOMFUN LIKE '%MSGFEATURE%' OR "
				cQuery += "SAO.AO_NOMFUN LIKE '%MSGRISKSCORING%' ) AND "
				cQuery += "SAO.D_E_L_E_T_=' ' "

				cQuery := ChangeQuery(cQuery)

				dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"SERSOLLBCR")

				TcSetField("SERSOLLBCR","MAXDATA","D",8,0)

				If MAXDATA+nDias<=dDataBase
					lEnvia := .T.
				EndIf

				dbCloseArea()
				dbSelectArea("SAO")

			#ELSE
				dbSelectArea("SAO")
				dbSetOrder(1)
				If MsSeek(xFilial("SAO")+SA1->A1_COD+SA1->A1_LOJA+"1")
					While !Eof() .And. SAO->AO_FILIAL == xFilial("SAO") .And.;
							SAO->AO_CLIENTE == SA1->A1_COD .And.;
							SAO->AO_LOJA == SA1->A1_LOJA .And.;
							SAO->AO_TIPO == "1"
						If "SERASA"$Upper(SAO->AO_NOMINS) .And.;
								("MSGBLOCO"$Upper(SAO->AO_NOMFUN) .Or.;
								"MSGFEATURE"$Upper(SAO->AO_NOMFUN) .Or.;
								"MSGRISKSCORING"$Upper(SAO->AO_NOMFUN))
							If SAO->AO_DATA+nDias<=dDataBase
								lEnvia := .T.
								Exit
							EndIf
						EndIf
						dbSelectArea("SAO")
						dbSkip()
					EndDo
				Else
					lEnvia := .T.
				EndIf
			#ENDIF
		EndIf
		If lEnvia
			IniRepo()
			cTexto := "IP23"
			cTexto += "CONC"
			cTexto += "M"
			cTexto += "2"
			cTexto += Space(8)
			cTexto += SubStr(SA1->A1_CGC,1,9)
			cTexto += "2"
			cTexto += "2"
			cTexto += "N"
			cTexto += Space(12)
			cTexto += "0"
			cTexto += "3"
			cTexto += "1"
			cTexto += "S"
			dbSelectArea("MSSERASA")
			dbSetOrder(1)
			If !MsSeek("T1"+cEmpAnt+cFilAnt+SA1->A1_COD+SA1->A1_LOJA)
				RecLock("MSSERASA",.T.)
				MSSERASA->SRZ_CODEMP := cEmpAnt
				MSSERASA->SRZ_CODFIL := cFilAnt
				MSSERASA->SRZ_DATA   := Date()
				MSSERASA->SRZ_TIME   := Time()
				MSSERASA->SRZ_XML    := cTexto
				MSSERASA->SRZ_STATUS := "1"
				MSSERASA->SRZ_CLASSE := "T"
				MSSERASA->SRZ_TAG    := SA1->A1_COD+SA1->A1_LOJA+SA1->A1_RISCO
				MsUnLock()
				lEnviou := .T.
			EndIf
		EndIf
	EndIf
	RestArea(aArea)
Return(lEnviou)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³SerLibCrRS³ Autor ³ Eduardo Riera         ³ Data ³01.07.2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Rotina de liberacao de credito atraves da analise de RiskSco-³±±
±±³          ³ring                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpC1: Codigo do Cliente                                     ³±±
±±³          ³ExpC2: Loja do Cliente                                       ³±±
±±³          ³ExpL3: Indica se o registro devera ser analisado manualmente ³±±
±±³          ³ExpL4: Indica se o registro devera ser rejeitado             ³±±
±±³          ³ExpN5: RiskScoring                                           ³±±
±±³          ³ExpN6: Prinad                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Esta rotina atualiza os dados de liberacao de credito do ERP ³±±
±±³          ³atraves do Listen                                            ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Serasa                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function SerLibCrRS(cCliente,cLoja,lBloqueia,lRejeita,nRisco,nPrinad)

	Local aArea     := GetArea()

	Local lQuery    := .F.
	Local lLibera   := .F.
	Local cAliasSC9 := "SC9"
	Local nLimite   := GetNewPar("MV_SERASA1",0)
	Local nLimite3  := GetNewPar("MV_SERASA3",9999)

	#IFDEF TOP
		Local cQuery    := ""
	#ENDIF

	DEFAULT lBloqueia := .F.
	DEFAULT lRejeita  := .F.
	DEFAULT nRisco    := 0
	DEFAULT nPriNad   := 0

	If nRisco == -1 //.And. nPriNad == -1
		If lRejeita .Or. lBloqueia
			lLibera := .F.
		Endif
	Else
		If !lBloqueia
			If nRisco >= nLimite //.And. nPriNad >= nLimite2
				lLibera := .T.
			EndIf
			If nRisco <= nLimite3 //.And. nPriNad <= nLimite4
				lRejeita := .T.
			EndIf
		EndIf
	EndIf
	If lRejeita .Or. lBloqueia
		lLibera := .F.
	EndIf
	#IFDEF TOP
		cAliasSC9 := "SERLIBCRRS"

		cQuery := "SELECT C9_FILIAL,C9_CLIENTE,C9_LOJA,C9_BLCRED,R_E_C_N_O_ SC9RECNO "
		cQuery += RetSqlName("SC9")+" SC9 "
		cQuery += "WHERE SC9.C9_FILIAL='"+xFilial("SC9")+"' AND "
		cQuery += "SC9.C9_CLIENTE='"+cCliente+"' AND "
		cQuery += "SC9.C9_LOJA='"+cLoja+" AND "
		cQuery += "(SC9.C9_BLCRED<>'"+Space(Len(SC9->C9_BLCRED))+"' AND "
		cQuery += "SC9.C9_BLCRED<>'09') AND "
		cQuery += "SC9.D_E_L_E_T_=' ' "

		cQuery := ChangeQuery(cQuery)

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSC9)
	#ELSE
		dbSelectArea("SC9")
		dbSetOrder(2)
		MsSeek(xFilial("SC9")+cCliente+cLoja)
	#ENDIF
	While (!Eof() .And. (cAliasSC9)->C9_FILIAL == xFilial("SC9") .And.;
			(cAliasSC9)->C9_CLIENTE == cCliente .And.;
			(cAliasSC9)->C9_LOJA == cLoja )
		If (cAliasSC9)->C9_BLCRED <> Space(Len((cAliasSC9)->C9_BLCRED)) .And.;
				(cAliasSC9)->C9_BLCRED <> '09'
			If lQuery
				SC9->(MsGoto((cAliasSC9)->SC9RECNO))
			EndIf
			Begin Transaction
				RecLock("SC9")
				If SC9->C9_BLCRED <> Space(Len(SC9->C9_BLCRED)) .And. SC9->C9_BLCRED <> '09'
					If lLibera
						a450Grava(1,.T.,.F.)
					ElseIf lRejeita
						a450Grava(2,.T.,.F.)
					Else
						If SC9->(FIELDPOS("C9_BLINF"))<>0
							RecLock("SC9")
							SC9->C9_BLINF := "RECOMENDA-SE ANALISE MANUAL - IP23 SERASA"
							MsUnLock()
						EndIf
					EndIf
				EndIf
				MsUnLock()
			End Transaction
		EndIf
		dbSelectArea(cAliasSC9)
		dbSkip()
	EndDo
	If lQuery
		dbSelectArea(cAliasSC9)
		dbCloseArea()
		dbSelectArea("SC9")
	EndIf
	RestArea(aArea)
Return(.T.)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³SerMsgRef ³ Autor ³ Eduardo Riera         ³ Data ³18.07.2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Rotina de atualizacao da referencias do cliente              ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpC1: Codigo do Cliente                                     ³±±
±±³          ³ExpC2: Loja do Cliente                                       ³±±
±±³          ³ExpC3: Mensagem de Bloco                                     ³±±
±±³          ³ExpC4: Alerta - Featureo                                     ³±±
±±³          ³ExpC5: Informacao RiskScoring                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Esta rotina atualiza as referencias do cliente consultado    ³±±
±±³          ³                                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Serasa                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function SerMsgRef(cCliente,cLoja,cMsgBlq,cMsgFea,cMsgRsk)

	Local aArea     := GetArea()
	Local aAreaSAO  := SAO->(GetArea())

	Local lQuery    := .F.
	Local cAliasSAO := "SAO"

	#IFDEF TOP
		Local aStruSAO  := {}
		Local cQuery    := ""
		Local nX        := 0
	#ENDIF

	DEFAULT cMsgBlq := ""
	DEFAULT cMsgFea := ""
	DEFAULT cMsgRsk := ""

	If !Empty(cMsgBlq+cMsgRsk+cMsgFea)
		#IFDEF TOP
			cAliasSAO := "SerMsgRef"
			aStruSAO  := SAO->(dbStruct())
			lQuery    := .T.

			cQuery := "SELECT SAO.*,SAO.R_E_C_N_O_ SAORECNO "
			cQuery += "FROM "+RetSqlName("SAO")+" SAO "
			cQuery += "WHERE SAO.AO_FILIAL='"+xFilial("SAO")+"' AND "
			cQuery += "SAO.AO_CLIENTE='"+SA1->A1_COD+"' AND "
			cQuery += "SAO.AO_LOJA='"+SA1->A1_LOJA+"' AND "
			cQuery += "SAO.AO_TIPO='1' AND "
			cQuery += "SAO.AO_NOMINS LIKE '%SERASA%' AND "
			cQuery += "(SAO.AO_NOMFUN LIKE '%MSGBLOCO%' OR "
			cQuery += "SAO.AO_NOMFUN LIKE '%MSGFEATURE%' OR "
			cQuery += "SAO.AO_NOMFUN LIKE '%MSGRISKSCORING%' ) AND "
			cQuery += "SAO.D_E_L_E_T_=' ' "

			cQuery := ChangeQuery(cQuery)

			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSAO)

			For nX := 1 To Len(aStruSAO)
				If aStruSAO[nX][2] <> "C"
					TcSetField(cAliasSAO,aStruSAO[nX][1],aStruSAO[nX][2],aStruSAO[nX][3],aStruSAO[nX][4])
				EndIf
			Next nX

		#ELSE
			dbSelectArea("SAO")
			dbSetOrder(1)
			MsSeek(xFilial("SAO")+cCliente+cLoja+"1")
		#ENDIF
		While !Eof() .And. (cAliasSAO)->AO_FILIAL == xFilial("SAO") .And.;
				(cAliasSAO)->AO_CLIENTE == cCliente .And.;
				(cAliasSAO)->AO_LOJA == cLoja .And.;
				(cAliasSAO)->AO_TIPO == "1"
			If "SERASA"$Upper((cAliasSAO)->AO_NOMINS)
				Do Case
				Case "MSGBLOCO"$Upper((cAliasSAO)->AO_NOMFUN)
					If lQuery
						SAO->(MsGoto(SAORECNO))
					EndIf
					RecLock("SAO")
					SAO->AO_DATA   := dDataBase
					SAO->AO_OBSERV := cMsgBlq
					MsUnLock()
					cMsgBlq := ""
				Case "MSGFEATURE"$Upper((cAliasSAO)->AO_NOMFUN)
					If lQuery
						SAO->(MsGoto(SAORECNO))
					EndIf
					RecLock("SAO")
					SAO->AO_DATA   := dDataBase
					SAO->AO_OBSERV := cMsgFea
					MsUnLock()
					cMsgFea := ""
				Case "MSGRISKSCORING"$Upper((cAliasSAO)->AO_NOMFUN)
					If lQuery
						SAO->(MsGoto(SAORECNO))
					EndIf
					RecLock("SAO")
					SAO->AO_DATA   := dDataBase
					SAO->AO_OBSERV := cMsgRsk
					MsUnLock()
					cMsgRsk := ""
				EndCase
			EndIf
			If Empty(cMsgBlq+cMsgRsk+cMsgFea)
				Exit
			EndIf
			dbSelectArea(cAliasSAO)
			dbSkip()
		EndDo
		If lQuery
			dbSelectArea(cAliasSAO)
			dbCloseArea()
			dbSelectArea("SAO")
		EndIf
		Do Case
		Case !Empty(cMsgBlq)
			RecLock("SAO",.T.)
			SAO->AO_FILIAL := xFilial("SAO")
			SAO->AO_CLIENTE:= cCliente
			SAO->AO_LOJA   := cLoja
			SAO->AO_TIPO   := "1"
			SAO->AO_NOMINS := "SERASA - IP23"
			SAO->AO_NOMFUN := "MSGBLOCO"
			SAO->AO_DATA   := dDataBase
			SAO->AO_OBSERV := cMsgBlq
			MsUnLock()
		Case !Empty(cMsgFea)
			RecLock("SAO",.T.)
			SAO->AO_FILIAL := xFilial("SAO")
			SAO->AO_CLIENTE:= cCliente
			SAO->AO_LOJA   := cLoja
			SAO->AO_TIPO   := "1"
			SAO->AO_NOMINS := "SERASA - IP23"
			SAO->AO_NOMFUN := "MSGFEATURE"
			SAO->AO_DATA   := dDataBase
			SAO->AO_OBSERV := cMsgFea
			MsUnLock()
		Case !Empty(cMsgRsk)
			RecLock("SAO",.T.)
			SAO->AO_FILIAL := xFilial("SAO")
			SAO->AO_CLIENTE:= cCliente
			SAO->AO_LOJA   := cLoja
			SAO->AO_TIPO   := "1"
			SAO->AO_NOMINS := "SERASA - IP23"
			SAO->AO_NOMFUN := "MSGRISKSCORING"
			SAO->AO_DATA   := dDataBase
			SAO->AO_OBSERV := cMsgRsk
			MsUnLock()
		EndCase
	EndIf
	RestArea(aAreaSAO)
	RestArea(aArea)
Return(.T.)

User Function SerasaSimp(dDataIni,dDataFim,aArquivo,lPrdR,lSerasa01)
	Local cAliasSE1:="SE1"
	Local aCampos  	:= {}
	Local lQuery   	:= .F.
	Local lRet01   	:= .T.
	Local cAlias 	:= ""
	Local oTmpTable

	#IFNDEF TOP
		Local cCondSE1:=""
		Local cCondSE5:=""
		Local cIndSE1  := CriaTrab(,.F.)
		Local cIndSE5  := SubStr(cIndSE1,1,7)+"A"
		Local lVldSA1  := .T.
	#ELSE
		Local cQuery:=""
	#ENDIF

	aArquivo := {"","","",""}

	#IFDEF TOP
		lQuery    := .T.
	#ENDIF

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Cria arquivo de trabalho com os titulos baixados RPP                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aadd(aCampos,{"CGC"   ,"C",14,0})
	aadd(aCampos,{"NUMDUP","C",17,0})
	aadd(aCampos,{"DTVC  ","D",08,0})
	aadd(aCampos,{"DTPG  ","D",08,0})
	aadd(aCampos,{"DTEM  ","D",08,0})
	aadd(aCampos,{"VLPG  ","N",14,2})

	// aArquivo[1] := CriaTrab(aCampos,.T.)

	// dbUseArea(.T.,__LocalDriver,aArquivo[1],"RPP")

	// IndRegua("RPP",aArquivo[1],"CGC+NUMDUP")

	cAlias := "RPP"
	oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
	oTmpTable:Create()

	dbSelectArea(cAlias)

	If lQuery//TOP
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Filtra baixa dos titulos em aberto no periodo informado                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT SA1.A1_TIPO,SA1.A1_EST,SA1.A1_CGC,SE1.E1_VENCREA,SE1.E1_EMISSAO,SE5.E5_PREFIXO,SE5.E5_NUMERO,SE5.E5_PARCELA,SE5.E5_TIPO,SE5.E5_SEQ,SE5.E5_DATA,SE5.E5_VALOR,SE5.E5_TIPODOC,SE1.E1_FILIAL,SE1.E1_CLIENTE,SE1.E1_LOJA,SE1.E1_PREFIXO,SE1.D_E_L_E_T_ AS DELET,SE1.R_E_C_N_O_ AS RECNO FROM "+ RetSQLName("SE1") +" SE1, "+ RetSQLName("SE5") +" SE5, "+ RetSQLName("SA1") +" SA1 WHERE "
		cQuery += "SE5.E5_FILIAL = '"+ xFilial("SE5") +"' AND "
		cQuery += "SE1.E1_FILIAL = '"+ xFilial("SE1") +"' AND "
		cQuery += "SA1.A1_FILIAL = '"+ xFilial("SA1") +"' AND "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Filtra titulos emitidos no periodo e nao baixados, ou baixados apos a    ³
	//³data de termino                                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery += "((SE1.E1_EMISSAO>='"+Dtos(dDataIni)+"' AND SE1.E1_EMISSAO<='"+Dtos(dDataFim)+"' AND ((SE1.E1_VALOR > SE1.E1_SALDO AND SE1.E1_SALDO > 0) OR (SE1.E1_BAIXA > '"+ Dtos(dDataFim) +"'))) OR "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Filtra titulos emitidos anteriormente, com movimentacao dentro do periodo³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery += "(SE1.E1_EMISSAO<'"+Dtos(dDataIni)+"' AND SE1.E1_MOVIMEN>='"+Dtos(dDataIni)+"')) AND "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Filtra baixas realizadas no periodo   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery += "E5_DATA >= '"+Dtos(dDataIni)+"' AND E5_DATA <= '"+Dtos(dDataFim)+"' AND "
		cQuery += "((SE5.E5_TIPODOC IN('VL','BA','V2','CP','LJ') AND SE5.E5_RECPAG='R') OR (SE5.E5_TIPODOC = 'ES' AND SE5.E5_RECPAG='P')) AND "//Filtra documentos
		cQuery += "E5_VALOR > 0 AND "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Une baixas e titulos                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery += "SE5.E5_PREFIXO=SE1.E1_PREFIXO AND "
		cQuery += "SE5.E5_NUMERO=SE1.E1_NUM AND "
		cQuery += "SE5.E5_PARCELA=SE1.E1_PARCELA AND "
		cQuery += "SE5.E5_TIPO=SE1.E1_TIPO AND "
		cQuery += "SE5.E5_CLIFOR=SE1.E1_CLIENTE AND "
		cQuery += "SE5.E5_LOJA=SE1.E1_LOJA AND "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Une clientes e titulos                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery += "SE5.E5_CLIFOR=SA1.A1_COD AND "
		cQuery += "SE5.E5_LOJA=SA1.A1_LOJA AND "
		cQuery += "SE5.D_E_L_E_T_ = ' ' AND "
		cQuery += "SE1.D_E_L_E_T_ = ' ' AND "
		cQuery += "SA1.D_E_L_E_T_ = ' ' "
		If MV_PAR05 == 2
			cQuery += "UNION "
			cQuery += "SELECT SA1.A1_TIPO,SA1.A1_EST,SA1.A1_CGC,SE1.E1_VENCREA,SE1.E1_EMISSAO,SE1.E1_PREFIXO,SE1.E1_NUM AS E5_NUMERO,SE1.E1_PARCELA AS E5_PARCELA,SE1.E1_TIPO AS E5_TIPO,'' AS E5_SEQ,'20010101' AS E5_DATA,0 AS E5_VALOR,'VL' AS E5_TIPODOC,SE1.E1_FILIAL,SE1.E1_CLIENTE,SE1.E1_LOJA,SE1.E1_PREFIXO,SE1.D_E_L_E_T_ AS DELET,SE1.R_E_C_N_O_ AS RECNO FROM "+RetSQLName("SE1")+" SE1 , "+RetSQLName("SA1")+" SA1 WHERE "
			cQuery += "SE1.E1_FILIAL = '"+xFilial("SE1")+"' AND "
			cQuery += "SA1.A1_FILIAL = '"+xFilial("SA1")+"' AND "
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Filtra titulos emitidos no periodo                                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cQuery += "((SE1.E1_EMISSAO>='"+Dtos(dDataIni)+"' AND SE1.E1_EMISSAO<='"+Dtos(dDataFim)+"') OR "
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Filtra titulos emitidos anteriormente, com movimentacao dentro do periodo³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cQuery += "(SE1.E1_EMISSAO<'"+Dtos(dDataIni)+"' AND SE1.E1_MOVIMEN>='"+Dtos(dDataIni)+"')) AND "
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Filtra titulos excluidos mas ja enviados ao Serasa Relato                ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !EMPTY(SE1->(FieldPos("E1_RELATO")))
				cQuery += "(SE1.D_E_L_E_T_ = '*' AND SE1.E1_RELATO = '1') AND "
			EndIF
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Une a tabela de cliente e titulos                                        ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cQuery += "SA1.A1_COD=SE1.E1_CLIENTE AND "
			cQuery += "SA1.A1_LOJA=SE1.E1_LOJA AND "
			cQuery += "SA1.D_E_L_E_T_ = ' ' "
		EndIf
		cQuery += "ORDER BY E1_FILIAL,E1_CLIENTE,E1_LOJA,E5_DATA"
	
		aArquivo[4] := cAliasSE1 := GetNextAlias()
	
		cQuery := ChangeQuery(cQuery)
	
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSE1)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Configura campos especiais            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		TcSetField(cAliasSE1,"E1_VENCREA" ,"D",08,00)
		TcSetField(cAliasSE1,"E1_EMISSAO" ,"D",08,00)
		TcSetField(cAliasSE1,"E5_DATA"    ,"D",08,00)
		TcSetField(cAliasSE1,"E5_VALOR"   ,"N",TamSX3("E5_VALOR")[1],TamSX3("E5_VALOR")[2])

		While !(cAliasSE1)->(Eof())
			dbSelectArea("RPP")

		//Executa ponto de entrada de filtro do SE1		
			If lSerasa01
				lRet01 := ExecBlock("SERASA01",.F.,.F.,{cAliasSE1})
				If valtype(lRet01) != "L"
					lRet01 := .T.
				EndIf
			EndIf

			If If(lPrdR,.T.,(Len(AllTrim((cAliasSE1)->A1_CGC)) == 14)) .And. (cAliasSE1)->A1_TIPO != "X" .And. (cAliasSE1)->A1_EST  != "EX" .And. (cAliasSE1)->A1_CGC  != SM0->M0_CGC .And. (If(MV_PAR09==1,.T.,!((cAliasSE1)->E5_TIPO $ MVIRABT+"|"+MVCSABT+"|"+MVCFABT+"|"+MVPIABT+"|"+MVABATIM))) .And. lRet01
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Atualiza flag do arquivo SE1  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If !Empty(SE1->(FieldPos("E1_RELATO")))
					SE1->( dbGoTo( (cAliasSE1)->RECNO ) )
					If SE1->(Recno())==(cAliasSE1)->RECNO .And. SE1->E1_RELATO != '1'
						RecLock("SE1",.F.)
						SE1->E1_RELATO := '1'
						MsUnlock()
					EndIf
				EndIf
		
				If (cAliasSE1)->E5_TIPODOC != "ES"
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Pesquisa titulo               ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If dbSeek((cAliasSE1)->A1_CGC+(cAliasSE1)->E1_PREFIXO+(cAliasSE1)->E5_NUMERO+(cAliasSE1)->E5_PARCELA+(cAliasSE1)->E5_TIPO)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Soma valor da baixa           ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If Empty((cAliasSE1)->DELET)
							RecLock("RPP",.F.)
							RPP->DTPG   := (cAliasSE1)->E5_DATA
							RPP->VLPG   += (cAliasSE1)->E5_VALOR
							MsUnLock()
						EndIf
					Else
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Inclui titulo                 ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						RecLock("RPP",.T.)
						RPP->CGC    := (cAliasSE1)->A1_CGC
						RPP->NUMDUP := (cAliasSE1)->E1_PREFIXO+(cAliasSE1)->E5_NUMERO+(cAliasSE1)->E5_PARCELA+(cAliasSE1)->E5_TIPO
						RPP->DTVC   := (cAliasSE1)->E1_VENCREA
						RPP->DTEM   := (cAliasSE1)->E1_EMISSAO
						If Empty((cAliasSE1)->DELET)
							RPP->DTPG   := (cAliasSE1)->E5_DATA
							RPP->VLPG   := (cAliasSE1)->E5_VALOR
						Else
							RPP->VLPG   := 99999999999.99//Informa que o registro foi excluido
						EndIf
						MsUnLock()
					EndIf
				ElseIf (cAliasSE1)->E5_TIPODOC == "ES"//Titulo de estorno
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Pesquisa titulo de origem             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If dbSeek((cAliasSE1)->A1_CGC+(cAliasSE1)->E1_PREFIXO+(cAliasSE1)->E5_NUMERO+(cAliasSE1)->E5_PARCELA+(cAliasSE1)->E5_TIPO)
						If (RPP->VLPG-((cAliasSE1)->E5_VALOR)) == 0
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Exclui titulo quando estorno zerar baixa ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							RecLock("RPP",.F.)
							dbDelete()
							MsUnLock()
						Else
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Decrementa valor do estorno   ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If Empty((cAliasSE1)->DELET)
								RecLock("RPP",.F.)
								RPP->VLPG -= (cAliasSE1)->E5_VALOR
								MsUnlock()
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		
			(cAliasSE1)->(dbSkip())
		EndDo
	
		(cAliasSE1)->(dbCloseArea())
	Else//DBF
		cCondSE1 := "E1_FILIAL='"+xFilial("SE1")+"' .AND. "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pesquisa titulos emitidos no periodo  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cCondSE1 += "(DTOS(E1_EMISSAO)>='"+Dtos(dDataIni)+"' .AND. "
		cCondSE1 += "DTOS(E1_EMISSAO)<='"+Dtos(dDataFim)+"' .AND. "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pesquisa titulos com saldo ou com baixa apos o periodo³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cCondSE1 += "((E1_VALOR > E1_SALDO .AND. E1_SALDO > 0) .OR. (DTOS(E1_BAIXA) > '"+Dtos(dDataFim)+"')) .OR. "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pesquisa titulos emitidos antes do periodo mas com movimentacao³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cCondSE1 += "(DTOS(E1_EMISSAO)<'"+Dtos(dDataIni)+"' .AND. "
		cCondSE1 += "DTOS(E1_MOVIMEN)>='"+Dtos(dDataIni)+"'))"
		dbSelectArea("SE1")
		IndRegua("SE1",cIndSE1,"E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA",,cCondSe1)
		dbGotop()
		cCondSE5 := "E5_FILIAL='"+xFilial("SE5")+"' .AND. "
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pesquisa baixas do periodo ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cCondSE5 += "DTOS(E5_DATA)>='"+Dtos(dDataIni)+"' .AND. "
		cCondSE5 += "DTOS(E5_DATA)<='"+Dtos(dDataFim)+"' .AND. "
		cCondSE5 += "((E5_TIPODOC $ 'VLBAV2CPLJ' .AND. E5_RECPAG = 'R') .OR. (E5_TIPODOC = 'ES' .AND. E5_RECPAG = 'P')) .AND. "
		cCondSE5 += "E5_VALOR > 0"
		dbSelectArea("SE5")
		IndRegua("SE5",cIndSE5,"E5_FILIAL+E5_CLIFOR+E5_LOJA+E5_PREFIXO+E5_NUMERO+E5_PARCELA",,cCondSE5)
		dbGotop()
	
		While !SE1->(Eof())
			dbSelectArea("SA1")
			MsSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)//Posiciona no cliente
		
			lVldSA1 := If(lPrdR,.T.,(Len(AllTrim(SA1->A1_CGC))==14))
		
			If lVldSA1
		
			//Executa ponto de entrada de filtro do SE1
				If lSerasa01
					lRet01 := ExecBlock("SERASA01",.F.,.F.,{"SE1"})
					If valtype(lRet01) != "L"
						lRet01 := .T.
					EndIf
				EndIf

				If lRet01
					If !Empty(SE1->(FieldPos("E1_RELATO")))
						RecLock("SE1",.F.)
						SE1->E1_RELATO := '1'
						MsUnlock()
					EndIf
			
					dbSelectArea("SE5")
					dbSeek(xFilial("SE5")+SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA)//Posiciona na baixa
				
					While SE5->E5_CLIFOR == SE1->E1_CLIENTE .And. SE5->E5_LOJA == SE1->E1_LOJA .And. SE5->E5_PREFIXO == SE1->E1_PREFIXO .And. SE5->E5_NUMERO == SE1->E1_NUM .And. SE5->E5_PARCELA == SE1->E1_PARCELA
						dbSelectArea("RPP")
					
						If SE5->E5_TIPODOC != "ES"
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Pesquisa titulo               ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If dbSeek(SA1->A1_CGC+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO)
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Soma valor da baixa           ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								RecLock("RPP",.F.)
								RPP->DTPG   := SE5->E5_DATA
								RPP->VLPG   += SE5->E5_VALOR
								MsUnLock()
							else
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Inclui titulo                 ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								RecLock("RPP",.T.)
								RPP->CGC    := SA1->A1_CGC
								RPP->NUMDUP := SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO
								RPP->DTVC   := SE1->E1_VENCREA
								RPP->DTPG   := SE5->E5_DATA
								RPP->DTEM   := SE1->E1_EMISSAO
								RPP->VLPG   := SE5->E5_VALOR
								MsUnLock()
							EndIf
						ElseIf SE5->E5_TIPODOC == "ES"//Baixa de estorno
						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³Pesquisa titulo de origem             ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If dbSeek(SA1->A1_CGC+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO)
								If (RPP->VLPG-(SE5->E5_VALOR)) == 0
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Exclui titulo quando estorno zerar baixa ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									RecLock("RPP",.F.)
									dbDelete()
									MsUnLock()
								Else
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Decrementa valor do estorno   ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									RecLock("RPP",.F.)
									RPP->VLPG -= SE5->E5_VALOR
									MsUnlock()
								EndIf
							EndIf
						EndIf
					
						SE5->(dbSkip())
					EndDo
				EndIf
			EndIf
		
			SE1->(dbSkip())
		EndDo

		If MV_PAR05 == 2 .And. !EMPTY(SE1->(FieldPos("E1_RELATO")))
			cIndSE1  := CriaTrab(,.F.)
	
			SE1->(dbCloseArea())
			SA1->(dbCloseArea())

			SET DELETED OFF
			cCondSE1 := "E1_FILIAL='"+xFilial("SE1")+"' .AND. "
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Pesquisa titulos emitidos no periodo  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cCondSE1 += "((DTOS(E1_EMISSAO)>='"+Dtos(dDataIni)+"' .AND. "
			cCondSE1 += "DTOS(E1_EMISSAO)<='"+Dtos(dDataFim)+"') .OR. "
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Pesquisa titulos emitidos antes do periodo mas com movimentacao³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cCondSE1 += "(DTOS(E1_EMISSAO)<'"+Dtos(dDataIni)+"' .AND. "
			cCondSE1 += "DTOS(E1_MOVIMEN)>='"+Dtos(dDataIni)+"')) .AND. "
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Pesquisa titulos ja enviados                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			cCondSE1 += "E1_RELATO = '1'"

			IndRegua("SE1",cIndSE1,"E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA",,cCondSe1)

			SA1->(dbSetOrder(1))
		
			While !SE1->(Eof())
				If SE1->(DELETED())
					If SA1->(dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA))
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Inclui titulo                 ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						RecLock("RPP",.T.)
						RPP->CGC    := SA1->A1_CGC
						RPP->NUMDUP := SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO
						RPP->DTVC   := SE1->E1_VENCREA
						RPP->DTEM   := SE1->E1_EMISSAO
						RPP->VLPG   := 99999999999.99//Informa que o registro foi excluido
						MsUnLock()
					EndIf
				EndIf
				SE1->(dbSkip())
			EndDo
			SET DELETED ON
		EndIf

		aArquivo[2]:=cIndSE1
		aArquivo[3]:=cIndSE5
	EndIf

Return


Static Function sfRelAtuSE1(aSe1)
	Local nx:=0

	dbSelectArea("SE1")
	dbSetOrder(1)
	SET DELETED OFF

	If !Empty(SE1->(FieldPos("E1_RELATO")))
		For nx:=1 to len(aSe1)
			If dbseek(xFilial("SE1")+aSe1[nx,1])
				RecLock("SE1",.F.)
				SE1->E1_RELATO := aSE1[nx,2]
				MsUnlock()
			EndIf
		Next
	EndIf
	SET DELETED ON

Return
