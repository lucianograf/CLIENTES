#INCLUDE "rwmake.ch"
#INCLUDE "AP5MAIL.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} BFFATM11
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@param cNumNf, character, (Descrição do parâmetro)
@param cSerNf, character, (Descrição do parâmetro)
@param cXOpLog, character, (Descrição do parâmetro)
@param cInPedido, character, (Descrição do parâmetro)
@param cInOrdSep, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function BFFATM11(cNumNf,cSerNf,cXOpLog,cInPedido,cInOrdSep)
	
	Local aAreaOld := GetArea()
	Local lCanExec := GetNewPar( 'MV_X_ENEDI',.F. )
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	// Se não for para executar nesta filial 
	If !lCanExec
		If cNumNf == Nil
			MsgAlert("Está rotina é somente para a Filial Curitiba!","Empresa não autorizada!")
		Endif
		RestArea(aAreaOld)
		Return
	Endif
	
	
	// Tratativa para valores nulos
	If cXOpLog == Nil
		nOpcLog	:= Aviso("Escolha tipo de EDI","É necessário escolher o tipo de EDI a ser enviado. Opção 'Nota fiscal' é para o modelo de separação baseado no programa 'Fatu_novo'. Ordem de separação é para o novo formato de separação a partir do pedido de venda para posterior faturamento ",{"Nota Fiscal","Ord.Separação"},3)
		If nOpcLog == 1
			cXOpLog		:= "B"
		ElseIf nOpcLog ==2
			cXOpLog		:= "P"
		Else
			Return
		Endif
	Endif
	
	If cNumNf == Nil
		cNumNf		:= Space(TamSX3("F2_DOC")[1])
	Endif
	
	If cSerNf == Nil
		cSerNf		:= Padr(GetNewPar("GM_SERIENF","2"),TamSX3("F2_SERIE")[1])
	Endif
	
	If cInPedido == Nil
		cInPedido		:= Space(TamSX3("C9_PEDIDO")[1])
	Endif
	
	If cInOrdSep == Nil
		cInOrdSep		:= Space(TamSX3("C9_ORDSEP")[1])
	Endif
	
	
	
	
	Private oGeraTxt
	Private oNumExp,oSerExp
	Private cNumExp		:= cNumNf
	Private cSerExp		:= cSerNf
	Private cNumPed		:= cInPedido
	Private cOrdSep		:= cInOrdSep
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Montagem da tela de processamento.                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	
	If  cXOpLog $ "B#X"
		If Empty(cNumNf)
			
			@ 200,1 TO 380,380 DIALOG oGeraTxt TITLE OemToAnsi("Geração de Arquivo Texto")
			@ 02,10 TO 080,180
			@ 10,018 Say " Este programa ira gerar um arquivo texto, conforme os parame- "
			@ 18,018 Say " tros definidos  pelo usuario,  com os registros do arquivo de "
			@ 26,018 Say " Nota fiscal de Saída                                          "
			@ 40,018 Say " Número Nota"
			@ 40,055 Get cNumExp Picture "@!" Size 45,10
			@ 55,018 Say " Série"
			@ 55,055 Get cSerExp Picture "@!" Size 20,10
			@ 68,078 BUTTON "Remessa" size 30,12 Action (sfRemSF2(),Close(oGeraTxt)) // Remessa para armazenagem
			@ 68,118 BUTTON "Sep.NF" size 30,12 Action (sfSepSF2(),Close(oGeraTxt))  // Remessa para separação
			@ 68,158 BUTTON "Cancela" Size 30,12 Action Close(oGeraTxt)
			
			Activate Dialog oGeraTxt Centered
		Else
			If cXOpLog == "B"
				sfRemSF2()  // Remessa de armazenagem
			Else
				sfSepSF2()  // Remessa para separação
			Endif
		Endif
		
	ElseIf cXOpLog $ "P"  // EDI para separação por Ordem de separação de Pedido,,,,,,,
		If Empty(cNumPed)
			
			@ 200,1 TO 380,380 DIALOG oGeraTxt TITLE OemToAnsi("Geração de Arquivo Texto")
			@ 02,10 TO 080,180
			@ 10,018 Say " Este programa ira gerar um arquivo texto, conforme os parame- "
			@ 18,018 Say " tros definidos  pelo usuario,  com os registros do arquivo de "
			@ 26,018 Say " Ordem de Separação                                            "
			@ 40,018 Say " Pedido"
			@ 40,055 Get cNumPed Picture "@!" Size 40,10
			@ 55,018 Say " Ordem"
			@ 55,055 Get cOrdSep Picture "@!" Size 40,10
			@ 67,055 BUTTON "Sep.Pedido" size 30,12 Action (sfSepSC9(),Close(oGeraTxt))
			//@ 70,098 BMPBUTTON TYPE 01 ACTION (OkGeraAgr(),Close(oGeraTxt))
			//@ 70,128 BMPBUTTON TYPE 01 ACTION (OkGeraOll(),Close(oGeraTxt))
			@ 67,090 BUTTON "Cancela" Size 30,12 Action Close(oGeraTxt)
			
			Activate Dialog oGeraTxt Centered
		Else
			sfSepSC9()
		Endif
	Endif
	
	RestArea(aAreaOld)
	
Return


/*/{Protheus.doc} sfRemSF2
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRemSF2()
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria o arquivo texto                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Private cArq	:= "DR"+StrZero(Val(cSerExp),3)+StrZero(Val(cNumExp),12)+SM0->M0_CGC+".txt"
	MakeDir(IIf(IsSrvUnix(),"/Edi/ollogremes/", "\Edi\ollogremes\"))
	Private cLocDir	:= IIf(IsSrvUnix(),"/Edi/ollogremes/", "\Edi\ollogremes\")
	Private nHdl    := fCreate(cLocDir+cArq)
	
	Private cEOL    := "CHR(13)+CHR(10)"
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	If nHdl == -1
		MsgAlert("O arquivo de nome "+cLocDir+cArq+" nao pode ser executado! Verifique os parametros.","Atencao!")
		Return
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a regua de processamento                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Processa({|| RunOlLog("R") },"Processando...")
	
	sfSendMaOl("Remessa para separação!","Nota fiscal "+cNumExp+" de remessa de armazenagem "+SM0->M0_NOMECOM,cLocDir+cArq)
	
Return


/*/{Protheus.doc} sfSepSF2
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSepSF2()
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria o arquivo texto                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private cArq	:= "DR"+StrZero(Val(cSerExp),3)+StrZero(Val(cNumExp),12)+SM0->M0_CGC+".txt"
	MakeDir(IIf(IsSrvUnix(),"/Edi/ollog/", "\Edi\ollog\"))
	Private cLocDir	:= IIf(IsSrvUnix(),"/Edi/ollog/", "\Edi\ollog\")
	Private nHdl    := fCreate(cLocDir+cArq)
	
	Private cEOL    := "CHR(13)+CHR(10)"
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	If nHdl == -1
		MsgAlert("O arquivo de nome "+cLocDir+cArq+" nao pode ser executado! Verifique os parametros.","Atencao!")
		Return
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a regua de processamento                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Processa({|| RunOlLog("S") },"Processando...")
	
	sfSendMaOl("Remessa para separação!","Nota fiscal "+cNumExp+" de remessa p/separação "+SM0->M0_NOMECOM,cLocDir+cArq)
	
Return



/*/{Protheus.doc} sfSepSC9
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSepSC9()
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria o arquivo texto                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private cArq	:= "DR"+StrZero(Val(cOrdSep),15)+SM0->M0_CGC+".txt"
	MakeDir(IIf(IsSrvUnix(),"/Edi/ollog/", "\Edi\ollog\"))
	Private cLocDir	:= IIf(IsSrvUnix(),"/Edi/ollog/", "\Edi\ollog\")
	Private nHdl    := fCreate(cLocDir+cArq)
	
	Private cEOL    := "CHR(13)+CHR(10)"
	If Empty(cEOL)
		cEOL := CHR(13)+CHR(10)
	Else
		cEOL := Trim(cEOL)
		cEOL := &cEOL
	Endif
	
	If nHdl == -1
		MsgAlert("O arquivo de nome "+cLocDir+cArq+" nao pode ser executado! Verifique os parametros.","Atencao!")
		Return
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a regua de processamento                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Processa({|| sfExpEdi() },"Processando...")
	
	sfSendMaOl("Remessa para separação!","Pedido:"+cNumPed+" Ordem:"+cOrdSep+" p/separação "+SM0->M0_NOMECOM,cLocDir+cArq)
	
Return


/*/{Protheus.doc} RunOlLog
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@param cInTipo, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RunOlLog(cInTipo)
	
	Local nTamLin, cLin, cCpo
	Local	cQry	:= ""
	
	If cInTipo == "S"
		cQry += "SELECT D2_COD,D2_QUANT,D2_EMISSAO,D2_PEDIDO,LPAD(TO_NUMBER(D2_DOC),6,'0') D2_DOC, D2_SERIE,D2_CF, B1_UM, D2_ITEM, A1_NOME NOME, F2_VOLUME1, "
		cQry += "NVL((SELECT MAX(A4_NOME) "
		cQry += "             FROM " +RetSqlName("SA4") + " A4 "
		cQry += "            WHERE A4.D_E_L_E_T_ = ' ' "
		cQry += "              AND A4_COD = F2_TRANSP "
		cQry += "              AND A4_FILIAL = '"+xFilial("SA4")+"'), "
		cQry += "           'RETIRA') A4_NOME, "
		cQry += "NVL((SELECT MAX(A4_CGC) "
		cQry += "             FROM " +RetSqlName("SA4") + " A4 "
		cQry += "            WHERE A4.D_E_L_E_T_ = ' ' "
		cQry += "              AND A4_COD = F2_TRANSP "
		cQry += "              AND A4_FILIAL = '"+xFilial("SA4")+"'), "
		cQry += "           'RETIRA') A4_CGC, "
		cQry += "       NVL((SELECT MAX(C9_CARGA) "
		cQry += "              FROM "+RetSqlName("SC9") + " C9 "
		cQry += "             WHERE C9.D_E_L_E_T_ = ' ' "
		cQry += "               AND C9_PRODUTO = D2_COD "
		cQry += "               AND C9_ITEM = D2_ITEMPV "
		cQry += "               AND C9_PEDIDO = D2_PEDIDO "
		cQry += "               AND C9_SERIENF = D2_SERIE "
		cQry += "               AND C9_NFISCAL = D2_DOC "
		cQry += "               AND C9_FILIAL = '"+xFilial("SC9") +"'),'      ') C9_CARGA "
		cQry += "  FROM "+RetSqlName("SD2") + " D2, "+RetSqlName("SB1") + " B1, " +RetSqlName("SF2") + " F2, " +RetSqlName("SA1") + " A1 "
		cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1.B1_COD = D2_COD "
		cQry += "   AND B1.B1_FILIAL = '"+xFilial("SB1")+"' "
		cQry += "   AND A1.D_E_L_E_T_ = ' ' "
		cQry += "   AND A1_LOJA = F2_LOJA "
		cQry += "   AND A1_COD = F2_CLIENTE "
		cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+" ' "
		cQry += "   AND D2.D_E_L_E_T_ = ' ' "
		cQry += "   AND D2_LOJA = F2_LOJA "
		cQry += "   AND D2_CLIENTE = F2_CLIENTE "
		cQry += "   AND D2_DOC = F2_DOC "
		cQry += "   AND D2_SERIE = F2_SERIE "
		cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+" ' "
		cQry += "   AND F2_SERIE = '"+cSerExp+"' "
		cQry += "   AND F2_DOC = '"+cNumExp+"' "
		cQry += "   AND F2_FILIAL = '"+xFilial("SF2")+"' "
		cQry += " ORDER BY D2_ITEM "
	ElseIf cInTipo == "R"
		cQry += "SELECT D2_COD,D2_QUANT,D2_EMISSAO,D2_PEDIDO,LPAD(TO_NUMBER(D2_DOC),6,'0') D2_DOC, D2_SERIE,D2_CF, B1_UM, D2_ITEM, A2_NOME NOME, F2_VOLUME1, "
		cQry += "NVL((SELECT MAX(A4_NOME) "
		cQry += "             FROM " +RetSqlName("SA4") + " A4 "
		cQry += "            WHERE A4.D_E_L_E_T_ = ' ' "
		cQry += "              AND A4_COD = F2_TRANSP "
		cQry += "              AND A4_FILIAL = '"+xFilial("SA4")+"'), "
		cQry += "           'RETIRA') A4_NOME, "
		cQry += "NVL((SELECT MAX(A4_CGC) "
		cQry += "             FROM " +RetSqlName("SA4") + " A4 "
		cQry += "            WHERE A4.D_E_L_E_T_ = ' ' "
		cQry += "              AND A4_COD = F2_TRANSP "
		cQry += "              AND A4_FILIAL = '"+xFilial("SA4")+"'), "
		cQry += "           'RETIRA') A4_CGC, "
		cQry += "       NVL((SELECT MAX(C9_CARGA) "
		cQry += "              FROM "+RetSqlName("SC9") + " C9 "
		cQry += "             WHERE C9.D_E_L_E_T_ = ' ' "
		cQry += "               AND C9_PRODUTO = D2_COD "
		cQry += "               AND C9_ITEM = D2_ITEMPV "
		cQry += "               AND C9_PEDIDO = D2_PEDIDO "
		cQry += "               AND C9_SERIENF = D2_SERIE "
		cQry += "               AND C9_NFISCAL = D2_DOC "
		cQry += "               AND C9_FILIAL = '"+xFilial("SC9") +"'),'      ') C9_CARGA "
		cQry += "  FROM "+RetSqlName("SD2") + " D2, "+RetSqlName("SB1") + " B1, " +RetSqlName("SF2") + " F2, " +RetSqlName("SA2") + " A2 "
		cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1.B1_COD = D2_COD "
		cQry += "   AND B1.B1_FILIAL = '"+xFilial("SB1")+"' "
		cQry += "   AND A2.D_E_L_E_T_ = ' ' "
		cQry += "   AND A2_LOJA = F2_LOJA "
		cQry += "   AND A2_COD = F2_CLIENTE "
		cQry += "   AND A2_FILIAL = '"+xFilial("SA1")+" ' "
		cQry += "   AND D2.D_E_L_E_T_ = ' ' "
		cQry += "   AND D2_LOJA = F2_LOJA "
		cQry += "   AND D2_CLIENTE = F2_CLIENTE "
		cQry += "   AND D2_DOC = F2_DOC "
		cQry += "   AND D2_SERIE = F2_SERIE "
		cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+" ' "
		cQry += "   AND F2.D_E_L_E_T_ = ' ' "
		cQry += "   AND F2_TIPO = 'B' "
		cQry += "   AND F2_SERIE = '"+cSerExp+"' "
		cQry += "   AND F2_DOC = '"+cNumExp+"' "
		cQry += "   AND F2_FILIAL = '"+xFilial("SF2")+"' "
		cQry += " ORDER BY D2_ITEM "
	EndIf
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	If !EOF()
		
		nTamLin := 254
		cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
		
		cCpo := "6"
		cLin := Stuff(cLin,01,01,cCpo)
		
		cCpo := StrZero(Val(SM0->M0_CGC),14)
		cLin := Stuff(cLin,02,14,cCpo)
		
		cCpo := StrZero(0,14)
		cLin := Stuff(cLin,16,14,cCpo)
		
		cCpo := PADR(DTOC(Date()),10)
		cLin := Stuff(cLin,30,10,cCpo)
		
		cCpo := PADR(QRY->D2_PEDIDO,20)
		cLin := Stuff(cLin,40,20,cCpo)
		
		cCpo := "2"
		cLin := Stuff(cLin,60,01,cCpo)
		
		cCpo := PADR(QRY->D2_DOC,09)
		cLin := Stuff(cLin,61,09,cCpo)
		
		cCpo := PADR(QRY->D2_SERIE,03)
		cLin := Stuff(cLin,70,03,cCpo)
		
		cCpo := Space(10)
		cLin := Stuff(cLin,73,10,cCpo)
		
		cCpo := StrZero(0,13)
		cLin := Stuff(cLin,83,13,cCpo)
		
		cCpo := Space(14)
		cLin := Stuff(cLin,96,14,cCpo)
		
		cCpo := StrZero(Val(QRY->A4_CGC),14)
		cLin := Stuff(cLin,110,14,cCpo)
		
		cCpo := PADR(QRY->NOME,30)
		cLin := Stuff(cLin,124,30,cCpo)
		
		cCpo := PADR(QRY->A4_NOME,30)
		cLin := Stuff(cLin,154,30,cCpo)
		
		cCpo := StrZero(QRY->F2_VOLUME1,5)
		cLin := Stuff(cLin,184,5,cCpo)
		
		If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
			If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
				//Exit
			Endif
		Endif
		
		While !EOF()
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Incrementa a regua                                                  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			
			IncProc()
			
			
			nTamLin := 254
			cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
			
			
			cCpo := "7"
			cLin := Stuff(cLin,01,01,cCpo)
			
			cCpo := PADR(QRY->D2_PEDIDO,20)
			cLin := Stuff(cLin,02,20,cCpo)
			
			cCpo := PADR(QRY->D2_COD,30)
			cLin := Stuff(cLin,22,30,cCpo)
			
			cCpo := Space(30)
			cLin := Stuff(cLin,52,30,cCpo)
			
			cCpo := PADR(QRY->B1_UM,3)
			cLin := Stuff(cLin,82,3,cCpo)
			
			cCpo := StrZero(QRY->D2_QUANT*10000,13)
			cLin := Stuff(cLin,85,13,cCpo)
			
			cCpo := Space(59)
			cLin := Stuff(cLin,98,59,cCpo)
			
			cCpo := PADR(QRY->D2_ITEM,3)
			cLin := Stuff(cLin,157,3,cCpo)
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
			//³ linha montada.                                                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			
			If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
				If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
					Exit
				Endif
			Endif
			
			QRY->(dbSkip())
		EndDo
	Endif
	QRY->(DbCloseArea())
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ O arquivo texto deve ser fechado, bem como o dialogo criado na fun- ³
	//³ cao anterior.                                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	fClose(nHdl)
	
Return





/*/{Protheus.doc} sfExpEdi
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function sfExpEdi()
	
	Local nTamLin, cLin, cCpo
	Local	cQry	:= ""
	
	cQry += "SELECT C9_QTDLIB,"
	cQry += "       B1_UM,"
	cQry += "       C9_PRODUTO,"
	cQry += "       C9_PEDIDO,"
	cQry += "       C9_ORDSEP,"
	cQry += "		A1_CGC,"
	cQry += "       A1_NOME NOME,"
	cQry += "       C9_ITEM||SUBSTR(C9_SEQUEN,2,1) C9_ITEM,"
	cQry += "       C9_ITEM ITEM,"
	cQry += "NVL((SELECT MAX(A4_CGC) "
	cQry += "             FROM " +RetSqlName("SA4") + " A4 "
	cQry += "            WHERE A4.D_E_L_E_T_ = ' ' "
	cQry += "              AND A4_COD = C5_TRANSP "
	cQry += "              AND A4_FILIAL = '"+xFilial("SA4")+"'), "
	cQry += "           '0') A4_CGC, "
	cQry += "NVL((SELECT MAX(A4_NREDUZ) "
	cQry += "             FROM " +RetSqlName("SA4") + " A4 "
	cQry += "            WHERE A4.D_E_L_E_T_ = ' ' "
	cQry += "              AND A4_COD = C5_TRANSP "
	cQry += "              AND A4_FILIAL = '"+xFilial("SA4")+"'), "
	cQry += "           '0') A4_NOME "
	cQry += "  FROM "+RetSqlName("SC9") + " C9, "+RetSqlName("SB1") + " B1, " +RetSqlName("SC5") + " C5, " +RetSqlName("SA1") + " A1 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1.B1_COD = C9_PRODUTO "
	cQry += "   AND B1.B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_LOJA = C5_LOJACLI "
	cQry += "   AND A1_COD = C5_CLIENTE "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+" ' "
	cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_LOJACLI = C9_LOJA "
	cQry += "   AND C5_CLIENTE = C9_CLIENTE "
	cQry += "   AND C5_NUM = C9_PEDIDO "
	cQry += "   AND C5_FILIAL = '"+xFilial("SC5")+" ' "
	cQry += "   AND C9.D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_ORDSEP = '"+cOrdSep+"' "
	cQry += "   AND C9_PEDIDO = '"+cNumPed+"' "
	cQry += "   AND C9_FILIAL = '"+xFilial("SC5")+"' "
	cQry += " ORDER BY C9_ITEM "
	
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	If !EOF()
		
		nTamLin := 254
		cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
		
		cCpo := "6"
		cLin := Stuff(cLin,01,01,cCpo)			// 	1 Identificador de registro A (01) O 001 001 Fixo 6
		
		cCpo := StrZero(Val(SM0->M0_CGC),14)
		cLin := Stuff(cLin,02,14,cCpo)			// 	2 CNPJ cliente N (14) O 002 015 Sem pontos, traços e barras
		
		cCpo := StrZero(0,14)
		cLin := Stuff(cLin,16,14,cCpo)          //	3 CNPJ armazém N (14) C 016 029 Sem pontos, traços e barras
		
		cCpo := PADR(DTOC(Date()),10)
		cLin := Stuff(cLin,30,10,cCpo)       	//	4 Data expedição A (10) O 030 039 Formato: DD/MM/AAAA
		
		cCpo := PADR(QRY->C9_PEDIDO,20)
		cLin := Stuff(cLin,40,20,cCpo)          //	5 Número do pedido A (20) C 055 074
		
		cCpo := "2"
		cLin := Stuff(cLin,60,01,cCpo)          //	6 Natureza de operação A (01) O Informar 2 para venda, 3 para Transferência,4 para devolução e 5 para retorno simbólico
		
		cCpo := StrZero(Val(QRY->C9_ORDSEP),9)
		//cCpo := PADR(" ",09)
		cLin := Stuff(cLin,61,09,cCpo)         	//	7 Nota fiscal de venda A (09) C 087 095
		
		cCpo := PADR("000",03)
		cLin := Stuff(cLin,70,03,cCpo)         	//	8 Série da nota fiscal de venda A (3) C 096 098
		
		cCpo := Space(10)
		cLin := Stuff(cLin,73,10,cCpo)      	//	9 Emissão da nota fiscal de venda A (10) C 099 108 Formato: DD/MM/AAAA
		
		cCpo := StrZero(0,13)
		cLin := Stuff(cLin,83,13,cCpo)       	//	10 Valor da nota fiscal de venda N (9,4) C 109 121
		
		//cCpo := StrZero(Val(QRY->A1_CGC),14)
		cCpo := Space(14)
		cLin := Stuff(cLin,96,14,cCpo)    		//	11 CNPJ/CPF do cliente final A (14) C 122 135 Sem pontos, traços e barras
		
		cCpo := StrZero(Val(QRY->A4_CGC),14)
		cLin := Stuff(cLin,110,14,cCpo)         //	12 CNPJ/CPF da transportadora A (14) C 135 148 Sem pontos, traços e barras
		
		cCpo := PADR(QRY->NOME,30)
		cLin := Stuff(cLin,124,30,cCpo)
		
		cCpo := PADR(QRY->A4_NOME,30)
		cLin := Stuff(cLin,154,30,cCpo)
		
		cCpo := StrZero(0,5)
		cLin := Stuff(cLin,184,5,cCpo)
		
		If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
			If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
				//Exit
			Endif
		Endif
		DbSelectArea("QRY")
		While !EOF()
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Incrementa a regua                                                  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			
			IncProc()
			
			
			nTamLin := 254
			cLin    := Space(nTamLin)+cEOL // Variavel para criacao da linha do registros para gravacao
			
			
			cCpo := "7"
			cLin := Stuff(cLin,01,01,cCpo) 		//	1 Identificador de registro A (01) O 001 001 Fixo 7
			
			cCpo := PADR(QRY->C9_PEDIDO,20)
			cLin := Stuff(cLin,02,20,cCpo)    	//	2 Número do pedido A (20) O 002 021
			
			cCpo := PADR(QRY->C9_PRODUTO,30)
			cLin := Stuff(cLin,22,30,cCpo)		//	3 Código da mercadoria A (30) O 022 051
			
			cCpo := Space(30)
			cLin := Stuff(cLin,52,30,cCpo)		//	4 Código de barra da mercadoria A (30) C 052 071
			
			cCpo := PADR(QRY->B1_UM,3)
			cLin := Stuff(cLin,82,3,cCpo)  		//	5 Unidade de Medida A (3) O 072 074
			
			cCpo := StrZero(QRY->C9_QTDLIB*10000,13)
			cLin := Stuff(cLin,85,13,cCpo)      //	6 Quantidade N (9,4) O 075 087
			
			
			cQry := " SELECT C6_XPA2NUM,C6_XPA2LIN,PA2_NUM,PA2_CHAPA,PA2_LACRE "
			cQry += "   FROM "+RetSqlName("SC6")+" C6,"+RetSqlName("PA2")+" PA2 "
			cQry += "  WHERE PA2.D_E_L_E_T_ = ' ' "
			cQry += "    AND PA2.PA2_PEDIDO = C6_NUM "
			cQry += "    AND PA2.PA2_LINHA = C6_XPA2LIN "
			cQry += "    AND PA2.PA2_NUM = C6_XPA2NUM "
			cQry += "    AND PA2.PA2_FILIAL = '"+xFilial("PA2")+"' "
			cQry += "    AND C6_NUM = '"+QRY->C9_PEDIDO+"' "
			cQry += "    AND C6_ITEM = '"+QRY->ITEM+"' "
			cQry += "    AND C6_PRODUTO = '"+QRY->C9_PRODUTO+"' "
			cQry += "    AND C6_FILIAL = '"+xFilial("SC6")+"' "
			cQry += "    AND C6.D_E_L_E_T_ = ' ' "
			
			TCQUERY cQry NEW ALIAS "QPA2"
			
			If !Eof()
				cCpo := StrZero(Val(QPA2->PA2_CHAPA),5)
			Else
				cCpo := Space(5)
			Endif
			
			QPA2->(DbCloseArea())
			
			cLin := Stuff(cLin,98,59,cCpo)     	// 	7 Lote A (20) C 088 107
			
			//	8 Número de Série A (20) C 108 127
			//	9 Data de Validade A (10) C 128 137 Formato: DD/MM/AAAA
			//	10 Nota fiscal de armazenagem I (09) C 138 146
			cCpo := PADR(QRY->C9_ITEM,3)
			cLin := Stuff(cLin,157,3,cCpo)
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Gravacao no arquivo texto. Testa por erros durante a gravacao da    ³
			//³ linha montada.                                                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			
			If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
				If !MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
					Exit
				Endif
			Endif
			DbSelectArea("QRY")
			dbSkip()
		EndDo
	Endif
	QRY->(DbCloseArea())
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ O arquivo texto deve ser fechado, bem como o dialogo criado na fun- ³
	//³ cao anterior.                                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	fClose(nHdl)
	
Return


/*/{Protheus.doc} sfSendMaOl
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@param cMensagem, character, (Descrição do parâmetro)
@param cAssunto, character, (Descrição do parâmetro)
@param cAnexo, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function sfSendMaOl(cMensagem,cAssunto,cAnexo)
	
	Local 	cServer   	:= GETMV("MV_RELSERV")
	Local 	cAccount  	:= AllTrim(GETMV("MV_WFMAIL"))
	Local 	cPassword 	:= AllTrim(GETMV("MV_WFPASSW"))
	Local 	cEnvia    	:= AllTrim(GETMV("MV_WFMAIL"))
	Local 	cRecebe		:= U_BFFATM15("pedido@exoduslogistica.com.br;exoduslogistica@gmail.com","BFFATM11")
	
	
	CONNECT SMTP SERVER cServer ACCOUNT cAccount PASSWORD cPassword Result lConectou
	
	If lConectou
		SEND MAIL FROM cEnvia;
			TO cRecebe;
			SUBJECT cAssunto;
			BODY cMensagem;
			ATTACHMENT cAnexo;
			RESULT lEnviado
		If !lEnviado
			cMensagem := ""
			GET MAIL ERROR cMensagem
			Alert(cMensagem)
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "ERRO SMTP EM: " + cAssunto/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Else
			DISCONNECT SMTP SERVER
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, cAssunto/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Endif
	Else
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "ERRO SMTP EM: " + cAssunto/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		MsgAlert("Erro ao se conectar no servidor: " + cServer,"")
	Endif
	
Return
