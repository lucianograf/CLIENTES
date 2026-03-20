#INCLUDE "TOPCONN.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} RLFINA03

(long_description)
@author MarceloLauschner
@since 09/02/2015
@version 1.0
@param lAuto, ${param_type}, (Descrição do parâmetro)
@param nOpc, numérico, (Descrição do parâmetro)
@param nRecSe1, numérico, (Descrição do parâmetro)
@param lWhen, ${param_type}, (Descrição do parâmetro)
@return nil
@example
(examples)
@see (links_or_references)
/*/
User Function RLFINA06(lAuto,nOpc,nRecSe1,lWhen,aRecSE1)

	Private aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Private nAltura 	:= aSize[6]/2.3
	Private oSE1
	Private dDataini	:= dDatabase
	Private dDatafin    := dDatabase
	Private dDataReimp	:= dDataBase
	Private nSoma       := 0.00
	Private oSoma
	Private aChoice 	:= {"IMPRESSAO","REIMPRESSAO"}
	Private cAgencia 	:= Space(5)
	Private cAgsiga 	:= Space(5)
	Private cAgImpBol	:= Space(6)
	Private cConta   	:= Space(10)
	Private cCedente	:= Space(10)
	Private cVencAjust	:= "Não"
	Private cMultaAjust	:= "Sim"
	Private nE1_Saldo	:= 0
	Private nE1_ValJu	:= 0
	Private nE1_VlMulta	:= 0
	Private cRadical	:= ""
	Private cMatricula  := ""
	Private cAgBic		:= ""
	Private aBanco

	If Type("cBancoImp") == "U"
		Private cBancoImp   := Space(8)
		Private cLocImp     := "F"
	Endif

	aBanco     := {"ITAU"}//{"BRADESCO","ITAU3","SANTD","BBRASIL","VOTOR","BOLPG","SAFRA","BICBANCO","BCABC","ITAU5"}

	Private oVermelho	:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	Private oAzul 		:= LoaDbitmap( GetResources(), "BR_AZUL" )
	Private oAmarelo	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Private oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	Private aSe1		:= {}
	Private cSe1		:= ""
	Private cVarPesq	:= Space(TamSX3("E1_NUM")[1])
	Private cTipo 		:= "IMPRESSAO"
	Private cCRBV		:= ""
	Private nBolPg		:= 0
	Default lAuto		:= .F.
	Default nOpc		:= 1
	Default	lWhen		:= .F.

	// Executa gravação do Log de Uso da rotina
	//	U_BFCFGM01()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria arquivo de trabalho (NOVO)                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !lAuto .And. !lWhen
		DEFINE MSDIALOG oDlg1 FROM 000,000 TO 180,400 OF oMainWnd PIXEL TITLE OemToAnsi("Tipo de operação!")
		@ 002,010 TO 060,190 of oDlg1 pixel
		@ 010,018 Say "Selecione o tipo de Operação: " of oDlg1 pixel
		@ 010,095 COMBOBOX cTipo ITEMS aChoice Size 60,10 of oDlg1 pixel
		@ 070,095 BUTTON "Continua" Size 50,15 of oDlg1 pixel ACTION(sfStart(lAuto),oDlg1:End())
		@ 070,030 BUTTON "Aborta" Size 50,15 of oDlg1 pixel ACTION (oDlg1:End())
		Activate MsDialog oDlg1 Centered
	Else
		cTipo		:= aChoice[nOpc]
		sfStart(lAuto,nRecSe1,lWhen,aRecSE1)
	Endif

Return

/*/{Protheus.doc} sfStart
(Montagem da Interface de seleção de titulos para boletos )
@author MarceloLauschner
@since 06/02/2015
@version 1.0
@param lAuto, ${param_type}, (Descrição do parâmetro)
@param nRecSe1, numérico, (Descrição do parâmetro)
@param lWhen, ${param_type}, (Descrição do parâmetro)
@return nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfStart(lAuto,nRecSe1,lWhen,aRecSE1)

	Local	aAreaSE1	:= SE1->(GetArea())
	//alert("passo 2")
	If cTipo == "REIMPRESSAO"

		If lAuto
			DbSelectArea("SE1")
			DbGoto(nRecSe1)
			cBancoImp 	:= "ITAU" //aBanco[aScan(aBanco,{|x| Padr(x,5) == Padr(SE1->E1_BCOIMP,5)})]
			dDataini 	:= SE1->E1_EMISSAO
			dDatafin 	:= SE1->E1_EMISSAO
		Else
			stTelaRee()
		Endif
	ElseIf cTipo == "IMPRESSAO"
		If lAuto .And. nRecSe1 <> Nil
			DbSelectArea("SE1")
			DbGoto(nRecSe1)
			dDataini 	:= SE1->E1_EMISSAO
			dDatafin 	:= SE1->E1_EMISSAO
		Endif
	Endif

	Processa({|| sfCriaArq(lAuto,nRecSe1,aRecSE1) },"Aguarde criando arquivo de trabalho....")
	If !lAuto .Or. lWhen
		DEFINE MSDIALOG oDlg FROM 000,000 TO aSize[6],aSize[5] OF oMainWnd PIXEL TITLE OemToAnsi("Selecine os títulos para impressão de Boletos!")
		// 1   2      3          4         5       6      7                8        9            10      11
		@ 010,005 LISTBOX oSe1 VAR cSe1 ;
			Fields HEADER " ",;
			" ","Duplicata",;
			"Parcela",;
			"Prefixo",;
			"Banco",;
			"Nome Cliente",;
			"Emissao",;
			"Vencimento",;
			"Valor",;
			"Cidade",;
			"Sald",;
			"Tipo" ;
			SIZE aSize[5]/2.04,nAltura-38 ON DBLCLICK (sfInverte()) OF oDlg PIXEL
		oSE1:nFreeze := 2
		oSE1:SetArray(aSE1)
		oSE1:bLine:={ ||{sfLegend(),;
			Iif(aSE1[oSE1:nAT,02],oMarked,oNoMarked),;
			aSE1[oSE1:nAT,03],;
			aSE1[oSE1:nAT,04],;
			aSE1[oSE1:nAT,05],;
			aSE1[oSE1:nAT,06],;
			aSE1[oSE1:nAT,07],;
			aSE1[oSE1:nAT,08],;
			aSE1[oSE1:nAT,09],;
			aSE1[oSE1:nAT,10],;
			aSE1[oSE1:nAT,11],;
			aSE1[oSE1:nAT,12],;
			aSE1[oSE1:nAT,13]}}
		oSE1:Refresh()
		@ nAltura,010 BITMAP oBmp RESNAME "BR_VERDE" SIZE 16,16 NOBORDER of oDlg pixel
		@ nAltura,020 SAY "- Qualquer Banco" of oDlg pixel
		@ nAltura+010,010 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER of oDlg pixel
		@ nAltura+010,020 SAY "- Sem Boleto NF" of oDlg pixel
		@ nAltura,080 BITMAP oBmp RESNAME "BR_AMARELO" SIZE 16,16 NOBORDER of oDlg pixel
		@ nAltura,090 SAY "- Obrig Boleto" of oDlg pixel
		@ nAltura+010,080 BITMAP oBmp RESNAME "BR_AZUL" SIZE 16,16 NOBORDER of oDlg pixel
		@ nAltura+010,090 SAY "- Sem Funcao" of oDlg pixel

		@ nAltura-020,010 SAY "Duplicata N." of oDlg pixel
		@ nAltura-023,050 MSGET cVarPesq Valid sfPesq() of oDlg pixel

		If cTipo == "REIMPRESSAO"
			@ nAltura+005,350 BUTTON "Imprime Boleto" Size 45,12 of oDlg pixel Action (Imprime(),oDlg:End())
			@ nAltura-018,130 Say "Vencimento e Valor Ajustados? " of oDlg Pixel
			@ nAltura-020,210 ComboBox cVencAjust Items {"Não","Sim"} Size 40,10 of oDlg Pixel
			@ nAltura-018,260 Say "Novo vencimento" of oDlg Pixel
			@ nAltura-020,310 MsGet dDataReimp Size 50,12 of oDlg Pixel When cVencAjust == "Sim"
			@ nAltura-018,380 Say "Considera Multa? " of oDlg Pixel
			@ nAltura-020,450 ComboBox cMultaAjust Items {"Não","Sim"} Size 40,10 of oDlg Pixel When cVencAjust == "Sim"
		Else
			@ nAltura+005,350 BUTTON "Imprime Boleto" SIZE 45,12 of oDlg pixel ACTION (Processa({|| stImpNew() },"Gerando Dados "),oDlg:End() )
			@ nAltura-020,150 Say "Soma dos títulos marcados :" of oDlg pixel
			@ nAltura-023,230 Msget oSoma Var nSoma Size 45,12  of oDlg pixel Picture "@E 999,999.99"  When .f.
		Endif

		@ nAltura+005,280 BUTTON "Cancela" 	SIZE 45,12	of oDlg pixel  ACTION (oDlg:End() )

		ACTIVATE MSDIALOG oDlg CENTERED
	Else
		If Len(aSE1) > 0
			Imprime()
		Endif
	Endif

	RestArea(aAreaSE1)

Return


/*/{Protheus.doc} sfCriaArq
(Gera os dados para montagem do Listbox dos titulos )
@author MarceloLauschner
@since 06/01/2012
@version 1.0
@param lAuto, ${param_type}, (Descrição do parâmetro)
@param nRecSe1, numérico, (Descrição do parâmetro)
@return Nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCriaArq(lAuto,nRecSe1,aRecSE1)

	Local 	nReg 	:= 0
	Local   cQry    := ""
	Local	nSts	:= 0
	Local	iS
	Default	aRecSE1	:= {}
	Default nRecSE1	:= 0

	//alert("passo 3")

	If cTipo == "NOVO_BANCO"
		cQry := ""
		cQry += "SELECT E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,A1_BCO1 "
		cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1 "
		cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
		cQry += "   AND SA1.D_E_L_E_T_ = ' ' "
		cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
		cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"' "
		cQry += "   AND SE1.E1_CLIENTE = SA1.A1_COD "
		cQry += "   AND SE1.E1_LOJA = SA1.A1_LOJA "
		cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-') "
		cQry += "   AND SE1.E1_NUMBOR = ' ' "
		cQry += "   AND SE1.E1_SALDO > 0 "
		cQry += "   AND SE1.E1_SITUACA = '0' "
		cQry += "   AND SE1.E1_NUMBCO <> ' ' "
		cQry += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "
	Elseif cTipo == "IMPRESSAO"
		If !lAuto .And. MsgYesNo("Impressão de boletos à partir de notas fiscais já impressas ?")
			cQry := ""
			cQry += "SELECT E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,A1_BCO1"
			cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1, "+ RetSqlName("SF2") +" SF2 "
			cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
			cQry += "   AND A1_LOJA= E1_LOJA "
			cQry += "   AND A1_COD = E1_CLIENTE "
			//cQry += "   AND SF2.F2_FILIAL = SUBSTR(SE1.E1_PREFIXO,2,2) "
			cQry += "   AND SF2.D_E_L_E_T_ = ' ' "
			//	cQry += "   AND SF2.F2_FIMP = 'S' "
			cQry += "   AND F2_PREFIXO = E1_PREFIXO "
			cQry += "   AND SF2.F2_DOC = SE1.E1_NUM "
			cQry += "   AND SF2.F2_FILIAL = '" + xFilial("SF2") +"' "
			cQry += "   AND SE1.D_E_L_E_T_ = ' ' "
			cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-') "
			cQry += "   AND SE1.E1_NUMBOR = ' ' "
			cQry += "   AND SE1.E1_PORTADO = ' ' "
			cQry += "   AND SE1.E1_NUMBCO = ' ' "
			cQry += "   AND SE1.E1_SALDO >0 "
			cQry += "   AND SE1.E1_SITUACA = '0' "
			cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"' "
			cQry += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "

		Else
			cQry := ""
			cQry += "SELECT E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,A1_BCO1 "
			cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1  "
			cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.D_E_L_E_T_ = ' '  "
			//	cQry += "   AND A1_BCO1 IN('400') " // Melhoria feita em 14/10/2013 para evitar que boletos, que somente boletos obrigatórios em anexo a nota sejam impressos
			cQry += "   AND A1_COD =  SE1.E1_CLIENTE "
			cQry += "   AND A1_LOJA = SE1.E1_LOJA "
			cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
			cQry += "   AND SE1.E1_SALDO > 0 "
			If lAuto
				If Len(aRecSE1) > 0
					cQry += " AND ("
					For iS	:= 1 To Len(aRecSE1)
						If iS > 1
							cQry += " OR "
						Endif
						cQry += " SE1.R_E_C_N_O_ = "+Alltrim(Str(aRecSE1[iS]))
					Next
					cQry += " ) "
				Else
					cQry += " AND SE1.R_E_C_N_O_ = "+Alltrim(Str(nRecSE1))
				Endif
			Endif
			cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-') "
			cQry += "   AND E1_NUMBCO = ' ' "
			cQry += "   AND SE1.E1_PORTADO = ' ' "
			cQry += "   AND SE1.E1_NUMBOR = ' ' "
			cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"' "
			cQry += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "
		Endif

	Elseif cTipo == "REIMPRESSAO"
		If !lAuto .And. MsgYesNo("Reimpressão de boletos à partir de notas fiscais?")
			cQry := ""
			cQry += "SELECT E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,A1_BCO1 "
			cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1, "+ RetSqlName("SF2") +" SF2 "
			cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.A1_COD = SE1.E1_CLIENTE "
			cQry += "   AND SA1.A1_LOJA = SE1.E1_LOJA "
			cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
			cQry += "   AND SF2.D_E_L_E_T_ = ' ' "
			cQry += "   AND SF2.F2_DOC = SE1.E1_NUM "
			cQry += "   AND SF2.F2_PREFIXO = SE1.E1_PREFIXO "
			cQry += "   AND SF2.F2_FILIAL = '"+ xFilial("SF2") +"'  "
			cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-') "
			cQry += "   AND SE1.E1_BCOIMP = '"+Substr(cBancoImp,1,5)+"' "
			cQry += "   AND SE1.E1_SALDO > 0 "
			cQry += "   AND SE1.E1_EMISSAO BETWEEN '" + DTOS(dDataini)+ "' AND '" + DTOS(dDatafin)+ "' "
			cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"'  "
			cQry += "ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "
		Else

			cQry := ""
			cQry += "SELECT E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,A1_BCO1 "
			cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1 "
			cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.A1_LOJA = SE1.E1_LOJA "
			cQry += "   AND SA1.A1_COD =  SE1.E1_CLIENTE "
			cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
			If lAuto
				cQry += " AND SE1.R_E_C_N_O_ = "+Alltrim(Str(nRecSE1))
			Else
				cQry += "   AND SE1.E1_BCOIMP = '"+Substr(cBancoImp,1,5)+"' "
				cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-', 'IS-') "
				cQry += "   AND SE1.E1_SALDO > 0 "
				cQry += "   AND SE1.E1_EMISSAO BETWEEN '" + Dtos(dDataini)+ "' AND '" + Dtos(dDatafin)+ "' "
				cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"'  "
			Endif
			cQry += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "
		Endif

	Endif
	//	alert(cQry)
	//	memowrite("C:\TOTVS\ITAU.TXT", cQry)
	TCQUERY cQry NEW ALIAS "QRP"

	Count to nReg

	dbselectarea("QRP")
	dbGotop()
	ProcRegua(nReg)
	While !Eof()
		IncProc("Processando Pedido N."+QRP->E1_NUM)
		nSts	:= 1        // não envia boleto - cobrança
		If QRP->A1_BCO1 == '100' .OR. Empty(QRP->A1_BCO1)   // opcional envio de boleto
			nSts	:= 2
		EndIf
		If QRP->A1_BCO1 == '200' // Boleto via correio
			nSts	:= 1
		EndIf
		If QRP->A1_BCO1 = '400'  // Boleto obrigatório anexo
			nSts	:= 3
		EndIf

		AAdd( aSE1, { 	nSts,;		// 1
		lAuto,;						// 2
		QRP->E1_NUM,;					//3
		QRP->E1_PARCELA,;				//4
		QRP->E1_PREFIXO,; 			//5
		QRP->A1_BCO1,;				//6
		ALLTRIM(QRP->A1_NREDUZ),;	// 7
		Stod(QRP->E1_EMISSAO),;	 	//8
		Stod(QRP->E1_VENCREA),;		//9
		Transform(QRP->E1_SALDO,'@E 999,999.99'),;		//10
		QRP->A1_MUN ,; 				//11
		QRP->E1_SALDO,;             // 12
		QRP->E1_TIPO })            	//13
		dbSelectArea("QRP")
		dbSkip()
	Enddo

	If Len(aSE1) < 1
		If !lAuto
			MsgAlert("Nao houveram regsitros selecionados","Atencao!")
			AADD(aSE1,{1,.F.,"","","","","","","","","",0,"",.F.})
		Endif
	Endif

	QRP->(DbCloseArea())

Return



/*/{Protheus.doc} sfInverte
(Inverte seleção listbox)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfInverte()

	DbSelectArea("SE1")
	dbsetorder(1)
	Dbseek(xFilial("SE1")+aSE1[oSE1:nAt,5]+aSE1[oSE1:nAt,3]+aSE1[oSE1:nAt,4]+aSE1[oSE1:nAt,13]) // Filial+Prefixo+Numero+Parcela+Tipo
	If SE1->E1_ORIGEM == "MATA460 "
		DbSelectArea("SC5")
		DbSetOrder(1)
		If DbSeek(xFilial("SC5")+SE1->E1_PEDIDO)

			If SC5->C5_CONDPAG $ "C01#C02#C03"
				MsgAlert("Este título foi gerado a partir de uma venda com Cartão Crédito! Não permitida a impressão de boletos.")
				aSE1[oSE1:nAt,2]	:= .F.
				Return
			ElseIf SC5->C5_BANCO == "BPG"
				If nBolPg == 2
					MsgAlert("Este título se refere a um boleto a ser impresso como QUITADO! Mas já estão marcados títulos para impressão normal.")
					Return
				Endif
				nBolPg := 1
			Else
				If nBolPg == 1
					MsgAlert("Já estão marcados títulos para impressão de boletos como QUITADOS!")
					Return
				Endif
				nBolPg := 2
			Endif
		Endif
	Endif


	aSE1[oSE1:nAt,2] := Iif(!aSE1[oSE1:nAt,2] .and. aSE1[oSE1:nAt,1]>1 ,.T.,.F.)
	//aSE1[oSE1:nAt,2] := Iif(!aSE1[oSE1:nAt,2] .And. (__cUserId $ GetMv("BF_USRSERA") .Or. aSE1[oSE1:nAt,1] > 1 ),.T.,.F.)

	If cTipo <> "REIMPRESSAO"
		sfAtuSoma()    // chama função que atualiza valores das duplicatas marcadas
		oSoma:Refresh()
	Endif

Return



/*/{Protheus.doc} sfAtuSoma
(Soma os titulos selecionados para exibir na tela    )
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuSoma()

	Local nSm := 0.00
	Local mr

	nSoma := 0.00

	For mr:= 1 to len(aSe1)
		If aSe1[mr,2] // se marcados
			nSm := aSE1[mr,12]      // transforma saldo em variavel
			nSoma := nSoma + nSm    // soma duplicatas marcadas
		Endif
	Next

Return


/*/{Protheus.doc} sfLegend
(Retorna a cor do status de cada linha  )
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return objeto
@example
(examples)
@see (links_or_references)
/*/
Static Function sfLegend()

	Local	nRetLeg := 1

	If	aSE1[oSe1:nAt,1] 	 == 1
		nRetLeg	:= oVermelho
	ElseIf	aSE1[oSe1:nAt,1] == 2
		nRetLeg	:= oVerde
	ElseIf	aSE1[oSe1:nAt,1] == 3
		nRetLeg	:= oAmarelo
	Else
		nRetLeg	:= oAzul
	EndIf

Return(nRetLeg)


/*/{Protheus.doc} sfPesq
(Procura título no listbox)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return logico
@example
(examples)
@see (links_or_references)
/*/
Static Function sfPesq()

	nAscan := Ascan(aSE1,{|x|Alltrim(x[3])==Alltrim(cVarPesq)})

	If nAscan <=0
		nAscan	:= 1
	EndIF
	oSE1:nAT 	:= nAscan
	cVarPesq	:= Space(TamSX3("E1_NUM")[1])
	oSE1:Refresh()
	oSE1:SetFocus()

Return .T.


/*/{Protheus.doc} stImpNew
(Interface para escolha de banco quando de nova impressão de boletos)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return Nil
@example
(examples)
@see (links_or_references)
/*/
Static Function stImpNew()


	DEFINE MSDIALOG oDlg2 FROM 000,000 TO 180,400 OF oMainWnd PIXEL TITLE OemToAnsi("Parametros de Banco e Impressora!")
	@ 02,10 TO 060,190 of oDlg2 pixel
	@ 010,018 Say "Informe o Banco:" of oDlg2 pixel
	@ 010,080 COMBOBOX cBancoImp ITEMS aBanco size 50,12 of oDlg2 pixel
	@ 035,018 Say "Local Impressão:" of oDlg2 pixel
	@ 035,080 Combobox cLocImp Items {"E","F","C"} Size 20,10 of oDlg2 pixel
	@ 070,090 BUTTON "Continua" size 40,15 of oDlg2 pixel ACTION (Processa({|| Imprime() },"Aguarde imprimindo...."),oDlg2:End() )
	@ 070,018 BUTTON "Aborta" size 40,15 of oDlg2 pixel ACTION (oDlg2:End())
	Activate MsDialog oDlg2 Centered

Return

/*/{Protheus.doc} stTelaRee
(Reimpressão de boletos - Selecionar banco já impresso para filtrar registros)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return nil
@example
(examples)
@see (links_or_references)
/*/
Static Function stTelaRee()


	DEFINE MSDIALOG oDlg2 FROM 000,000 TO 180,400 OF oMainWnd PIXEL TITLE OemToAnsi("Informacao para Impressao")
	@ 02,10 TO 060,190 of oDlg2 pixel
	@ 010,018 Say "Informe o Banco:" of oDlg2 pixel
	@ 010,080 COMBOBOX cBancoImp ITEMS aBanco size 50,12 of oDlg2 pixel
	@ 025,018 Say "Local Impressão:" of oDlg2 pixel
	@ 025,080 Combobox cLocImp Items {"E","F","C"} Size 20,10 of oDlg2 pixel
	@ 045,018 Say "Data de: "
	@ 045,080 Get dDataini of oDlg2 pixel
	@ 045,105 Say "Até dia: "
	@ 045,130 Get dDatafin of oDlg2 pixel
	@ 070,090 BUTTON "Continua" size 40,15 of oDlg2 pixel ACTION (oDlg2:End() )
	@ 070,018 BUTTON "Aborta" size 40,15 of oDlg2 pixel ACTION (oDlg2:End())

	Activate MsDialog oDlg2 Centered

Return


/*/{Protheus.doc} sfChekLock
(long_description)
@type function
@author marce
@since 13/03/2017
@version 1.0
@return logico
@example
(examples)
@see (links_or_references)
/*/
Static Function sfChekLock(lLock,cKeyLock)

	Local	nTentativas	:= 0

	If lLock
		While !LockByName("BFFINA05"+cKeyLock,.F.,.F.,.T.)
			MsAguarde({|| Sleep(1000 ) }, "Semaforo de processamento... tentativa "+ALLTRIM(STR(nTentativas)), "Aguarde, arquivo sendo alterado por outro usuário.")//"Semaforo de processamento... tentativa "##"Aguarde, arquivo sendo alterado por outro usuário."
			nTentativas++

			If nTentativas > 3600
				If MsgYesNo("Não foi possível acesso exclusivo para impressão de boletos. Deseja tentar novamente ?") //"Não foi possível acesso exclusivo para edição do Pré-Projeto da proposta. Deseja tentar novamente ?"
					nTentativas := 0
					Loop
				Else
					Return (.F.)
				EndIf
			EndIf
		EndDo

	Else
		UnLockByName("BFFINA05"+cKeyLock,.F.,.F.,.T.)
	Endif

Return .T.

/*/{Protheus.doc} Imprime
(Função de impressão do boleto)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return nil
@example
(examples)
@see (links_or_references)
/*/
Static Function Imprime()

	Local	nForA
	Local	wI
	Local	nAcreVal	:= 0
	Private cBarra		:= ""
	Private cLinha		:= ""
	Private cBarraImp 	:= space(50)
	Private cBarraFim	:= ""
	Private cCampo		:= ""
	Private cNossoNum	:= ""
	Private cMsgImp1 	:= ""
	Private cMsgImp2 	:= ""
	Private cMsgImp3 	:= ""
	Private cMsgImp4	:= ""
	Private nFatorVen	:= 0
	Private aInstrucoes	:= {}
	Private cInstr01   	:= " "
	Private cInstr02    := " "
	Private cInstr03    := " "
	Private cInstr04    := " "
	Private cInstr05	:= " "
	Private cInstr06	:= " "

	Private nHeight		:= 15
	Private lBold		:= .F.
	Private lUnderLine	:= .F.
	Private lPixel		:= .T.
	Private cDigVer		:= ""
	Private cDigBarra	:= ""
	Private	nAjuste		:= 100
	Private oPrn
	Private oFont01  	:= TFont():New( "Courier New" ,,09,,.t.,,,,,.f. )
	Private	oFont02		:= TFont():New( "Arial"       ,,04,,.T.,,,,,.f. )
	Private oFont03		:= TFont():New( "Arial"       ,,06,,.f.,,,,,.f. )
	Private oFont04		:= TFont():New( "Arial"       ,,07,,.T.,,,,,.f. )
	Private oFont05		:= TFont():New( "Arial"       ,,09,,.F.,,,,,.f. )
	Private oFont06		:= TFont():New( "Arial"       ,,09,,.T.,,,,,.f. )
	Private oFont07		:= TFont():New( "Arial"       ,,10,,.t.,,,,,.f. )
	Private oFont08		:= TFont():New( "Arial"       ,,12,,.f.,,,,,.f. )
	Private oFont09		:= TFont():New( "Arial"       ,,13,,.T.,,,,,.f. )
	Private oFont10		:= TFont():New( "Arial Black" ,,16,,.t.,,,,,.f. )
	Private oFont11		:= TFont():New( "Arial"       ,,18,,.t.,,,,,.f. )

	dbSelectArea("SA6") //Cadastro dos bancos.
	DbSetOrder(1)

	If nBolPg == 2 .And. cBancoImp == "BOLPG"
		MsgAlert("Os títulos selecionados para impressão não se referem a pedidos que solicitam impressão de boletos como QUITADOS")
		Return
	ElseIf nBolPg == 1 .And. cBancoImp <> "BOLPG"
		MsgAlert("Não foi selecionado o banco 'BOLPG' mas os títulos selecionados para impressão se referem a pedidos que solicitam impressão de boletos como QUITADOS")
		Return
	ElseIf nBolPg == 0 .And. cBancoImp == "BOLPG"
		MsgAlert("Os títulos selecionados para impressão não se referem a pedidos que solicitam impressão de boletos como QUITADOS")
		Return
	Endif
	If cBancoImp == "BOLPG"
		If !MsgYesNo("Voce selecionou um portador que irá imprimir boleto(s) quitado(s)! Deseja continuar?")
			Return
		Endif
		cBanco   := "BPG"
		cAgencia := ".    "
		cAgsiga  := ".    "
		cAgImpBol := ".     "
		cConta   := ".         "
	Endif
	cBancoImp	:= Alltrim(cBancoImp)

	If cEmpAnt == "06"

		If cBancoImp == "ITAU"    //redelog itau
			cBanco   := "341"
			cAgencia := "1293"
			cAgsiga  := "1293 "
			cConta   := "309538    "
		Endif
	ElseIf cEmpAnt == "16"
		If cBancoImp == "ITAU"    // ATSA
			cBanco   := "341"
			cAgencia := "1293"
			cAgsiga  := "1293 "
			cConta   := "363196    "
		Endif
	Endif

	// Verifica se pode ser feito o Lock de impressão
	If !sfChekLock(.T.,cBancoImp)
		Return
	Endif


	oPrn := TMSPrinter():New()
	// Condição que verifica se o parametro de impressão via listbox está ativado ou não
	If Type("lFirstBL") == "L"
		If lFirstBL
			oPrn:Setup()
			lFirstBL	:= .F.
		Endif
	Else
		oPrn:Setup()
	Endif

	oPrn:StartPage()

	For nForA:= 1 to len(aSe1)
		mr := nForA
		If 	aSe1[mr,2]
			IncProc("Processando Boletos...")


			oPrn:StartPage()

			dbSelectArea("SA6")
			dbsetorder(1)
			dbseek(xFilial("SA6")+cBanco+cAgsiga+cConta)

			// Zero as instruções
			aInstrucoes	:= {}
			cInstr01 := cInstr02 := cInstr03 := cInstr04 := cInstr05 := cInstr06 := ""


			cNumConta		:= SUBS(SA6->A6_NUMCON,1,7)

			dbSelectArea("SEE")
			dbSetOrder(1)
			If !dbSeek(xFilial("SEE")+SA6->A6_COD+SA6->A6_AGENCIA+SA6->A6_NUMCON+"001")
				Alert("Nao achou configuracao de banco")
				Loop
			Endif



			dbSelectArea("SE1")
			dbsetorder(1)
			Dbseek(xFilial("SE1")+aSE1[mr,5]+aSE1[mr,3]+aSE1[mr,4]+aSE1[mr,13]) // Filial+Prefixo+Numero+Parcela+Tipo



			If Empty(SE1->E1_BCOIMP) .or. cTipo == "NOVO_BANCO"
				If cTipo == "NOVO_BANCO"
					MsgInfo("Descarte o boleto anterior!","Atenção!")
				Endif
				Dbselectarea("SE1")
				RecLock("SE1",.F.)
				SE1->E1_PORTADO := cBanco
				SE1->E1_AGEDEP 	:= cAgsiga //cAgencia
				SE1->E1_CONTA 	:= cConta
				SE1->E1_BCOIMP 	:= Substr(cBancoImp,1,5)
				SE1->E1_NUMBCO 	:= ' '
				MsUnLock()
			Endif

			If cBanco == "237"

				If Empty(SE1->E1_NUMBCO)
					nfaxatu := 0
					nfaxatu := Val(SEE->EE_FAXATU)
					nfaxatu := nfaxatu + 1
					dbSelectArea("SEE")
					RecLock("SEE",.F.)
					SEE->EE_FAXATU 	:= Strzero(nfaxatu,11)
					MsunLock()
					cNossoNum 		:= Substr(SEE->EE_FAXATU,1,11)
				Else
					cNossoNum 		:= Substr(SE1->E1_NUMBCO,1,11)
				Endif

			ElseIf cBanco == "246"

				If Empty(SE1->E1_NUMBCO)
					nfaxatu := 0
					nfaxatu := Val(SEE->EE_FAXATU)
					nfaxatu := nfaxatu + 1
					dbSelectArea("SEE")
					RecLock("SEE",.F.)
					SEE->EE_FAXATU 	:= Strzero(nfaxatu,10)
					MsunLock()
					cNossoNum 		:= Substr(SEE->EE_FAXATU,1,10)
				Else
					cNossoNum 		:= Substr(SE1->E1_NUMBCO,1,10)
				Endif
			ElseIf cBanco == "001"

				If Empty(SE1->E1_numbco)
					nfaxatu := 0
					nfaxatu := Val(see->ee_faxatu)
					nfaxatu := nfaxatu + 1
					dbSelectArea("SEE")
					RecLock("SEE",.F.)
					SEE->EE_FAXATU := Strzero(nfaxatu,10)
					MsunLock()
					cNossoNum 		:= Substr(SEE->EE_FAXATU,1,10)
				Else
					cNossoNum 		:= Substr(SE1->E1_numbco,1,10)
				Endif

			Elseif cBanco == "341"
				If Empty(SE1->E1_numbco)
					nfaxatu := 0
					nfaxatu := val(see->ee_faxatu)
					nfaxatu := nfaxatu + 1
					dbSelectArea("SEE")
					reclock("SEE",.F.)
					see->ee_faxatu := strzero(nfaxatu,8)
					msunlock()
					cNossoNum 		:= Substr(SEE->EE_FAXATU,1,8)  //STRZERO(val(subs(cNossoNum1,1,1)
				Else
					cNossoNum 		:= Substr(SE1->E1_numbco,1,8)
				Endif
			Elseif cBanco == "745"
				If Empty(SE1->E1_NUMBCO)
					nFaxAtu := 0
					nFaxAtu := Val(SEE->EE_FAXATU)
					nFaxAtu++
					DbSelectArea("SEE")
					RecLock("SEE",.F.)
					SEE->EE_FAXATU := StrZero(nFaxAtu,11)
					MsUnlock()
					cNossoNum 		:= Substr(SEE->EE_FAXATU,1,11)
				Else
					cNossoNum 		:= Substr(SE1->E1_NUMBCO,1,11)
				Endif
			Elseif cBanco == "422"

				If Empty(SE1->E1_numbco)
					nFaxAtu := 0
					nFaxAtu := val(SEE->EE_FAXATU)
					nFaxAtu := nFaxAtu + 1
					RecLock('SEE',.F.)
					SEE->EE_FAXATU := StrZero(nFaxAtu,8)
					MsUnlock()
					cNossoNum 		:= Substr(SEE->EE_FAXATU,1,8)
				Else
					cNossoNum 		:= Substr(SE1->E1_numbco,1,8)
				Endif
			ElseIf cBanco == "033"

				If Empty(SE1->E1_numbco)
					nfaxatu := 0
					nfaxatu := Val(see->ee_faxatu)
					nfaxatu := nfaxatu + 1
					dbSelectArea("SEE")
					RecLock("SEE",.F.)
					SEE->EE_FAXATU := Strzero(nfaxatu,12)
					MsunLock()
					cNossoNum 		:= Substr(SEE->EE_FAXATU,1,12)
				Else
					cNossoNum 		:= Substr(SE1->E1_numbco,1,12)
				Endif
				// BicBanco - 05/01/2012
			Elseif cBanco == "320"

				If Empty(SE1->E1_NUMBCO)
					nFaxAtu := 0
					nFaxAtu := Val(SEE->EE_FAXATU)
					nFaxAtu := nFaxAtu + 1
					RecLock('SEE',.F.)
					SEE->EE_FAXATU  := StrZero(nFaxAtu,6)
					MsUnlock()
					cNossoNum 	    := Substr(SEE->EE_FAXATU,1,6)
				Else
					cNossoNum 		:= Substr(SE1->E1_NUMBCO,1,6)
				Endif
			Elseif cBanco == "399"
				// HSBC - 07/05/2015
				If Empty(SE1->E1_NUMBCO)
					nFaxAtu := 0
					nFaxAtu := Val(SEE->EE_FAXATU)
					nFaxAtu := nFaxAtu + 1
					RecLock('SEE',.F.)
					SEE->EE_FAXATU  := StrZero(nFaxAtu,10)
					MsUnlock()
					cNossoNum 	    := Substr(SEE->EE_FAXATU,1,10)
				Else
					cNossoNum 		:= Substr(SE1->E1_NUMBCO,1,10)
				Endif

			Endif

			If Val(SEE->EE_FAXFIM) - Val(SEE->EE_FAXATU) < 1000
				MsgAlert("Favor avisar ao financeiro pois a Faixa atual de Nosso Número está com menos de 1000 (Um Mil) números disponíveis para emissão de boletos para este Banco!","A T E N Ç Ã O!!!")
			Endif
			DbSelectArea("SA1")
			DbSetOrder(1)
			SA1->(dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))


			nDescFin		:= 0
			nDescFin		:= (SE1->E1_VALOR*SE1->E1_DESCFIN)/100
			If cVencAjust == "Não"
				nE1_ValJu		:= Iif(SE1->E1_VALJUR > 0,SE1->E1_VALJUR,SE1->E1_SALDO*0.0020)
				nTotAbImp		:= SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"V",SE1->E1_BAIXA)
				nE1_Saldo		:= SE1->E1_SALDO+SE1->E1_ACRESC-SE1->E1_DECRESC - nTotAbImp //(Iif(SA1->A1_RECIRRF $ "1",SE1->E1_IRRF,0)+Iif(SA1->A1_RECISS $ "1",SE1->E1_ISS,0))
				nE1_Saldo 		+= nAcreVal
				nE1_VlMulta		:= Round(SEE->EE_XPMULTA * nE1_Saldo / 100, 2)
			Else
				nE1_ValJu		:= Iif(SE1->E1_VALJUR > 0,SE1->E1_VALJUR,SE1->E1_SALDO*0.0020)
				nTotAbImp		:= SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"V",SE1->E1_BAIXA)
				nE1_Saldo		:= SE1->E1_SALDO +SE1->E1_ACRESC-SE1->E1_DECRESC - nTotAbImp //(Iif(SA1->A1_RECIRRF $ "1",SE1->E1_IRRF,0)+Iif(SA1->A1_RECISS $ "1",SE1->E1_ISS,0))
				nE1_Saldo 		+= nAcreVal

				If SE1->E1_VENCREA >= dDataReimp
					nE1_VlMulta		:= Round(SEE->EE_XPMULTA * nE1_Saldo / 100, 2)
				Else
					If cMultaAjust == "Sim"
						nE1_VlMulta		:= Iif(SE1->E1_VLMULTA == 0,Round(SEE->EE_XPMULTA * nE1_Saldo / 100, 2),SE1->E1_VLMULTA)
						nE1_Saldo       += nE1_VlMulta
					Endif
					nE1_Saldo       += (dDataReimp - SE1->E1_VENCREA) * nE1_ValJu
					// Zero a multa pois foi somada no valor do título ajustado
					nE1_VlMulta		:= 0
				Endif

			Endif

			// Arredondamento
			nE1_Saldo	:= Round(nE1_Saldo,2)

			// 18/01/2017
			If 	nE1_VlMulta > 0 .And. SE1->E1_VLMULTA == 0
				Dbselectarea("SE1")
				RecLock("SE1",.F.)
				SE1->E1_VLMULTA	:= nE1_VlMulta
				MsUnLock()
			Endif

			If nE1_ValJu > 0
				If cBancoImp <> "BOLPG"
					cInstr01      := "Juros/Mora ao dia R$ " + Alltrim(Transform(nE1_ValJu,"@E 999,999.99"))+"  Após a data do vencimento"
				Endif
			Else
				If cBancoImp <> "BOLPG"
					cInstr01      := "Juros/Mora ao dia R$ "+Alltrim(Transform(nE1_Saldo*0.0027,"@E 999,999.99")) + "  Após a data do vencimento"
				Endif
			Endif
			If nDescFin > 0
				cInstr02      := "Desconto de: "+ Transform(nDescFin,"@E 999,999.99")+"  Até a data do vencimento"
			Else
				cInstr02      := " "
			EndIf

			If 	cBancoImp <> "BOLPG"
				cInstr03      := "Sujeito a protesto após 2 dias úteis do não pagamento" //MV_PAR08
				// Trecho comentado após homologação do banco 03/11/2017
				//If cBancoImp == "SAFRA"
				//	cInstr03      := "Sujeito a protesto após 10 dias úteis do não pagamento" // Lembrando que o tipo de cobrança da conta informado é vinculada, a quantidade de dias para protesto é automático, sendo default o prazo de 10 dias corridos,
				//Endif
			Endif

			If nE1_VlMulta > 0
				cInstr05	:= "Valor da Multa por atraso R$ " + Alltrim(Transform(nE1_VlMulta,"@E 999,999.99"))
			Else
				cInstr05	:= " "
			Endif

			If cVencAjust == "Não"
				If SE1->E1_VENCREA >= CTOD("22/02/2025")  // Regra que verifica o fator de vencimento a partir de 2025
					// 22/02/2025 = Fator 1000
					// 23/02/2025 = Fator 1001
					nFatorVen       := SE1->E1_VENCREA - CTOD("22/02/2025")+1000   // acha a diferenca em dias para o fator de vencimento
				Else
					nFatorVen       := SE1->E1_VENCREA - CTOD("07/10/1997")   // acha a diferenca em dias para o fator de vencimento
				Endif


			Else

				If dDataReimp >= CTOD("22/02/2025")
					nFatorVen       := dDataReimp - CTOD("22/02/2025")+1000   // acha a diferenca em dias para o fator de vencimento
				Else
					nFatorVen       := dDataReimp - CTOD("07/10/1997")   // acha a diferenca em dias para o fator de vencimento
				Endif
			Endif

			// Adiciona observação se o boleto for Itau
			// 22/02/2014
			If cBancoImp $ "ITAU" //"ITAU3#ITAU5"
				cInstr04	:= "(TODAS AS INFORMAÇÕES DESTE BOLETO SÃO DE EXCLUSIVA RESPONSABILIDADE DO BENEFICIÁRIO)"
			Endif
			If nAcreVal > 0
				cInstr06	:= "Despesa Administrativa de R$ " + Alltrim(Transform(nAcreVal,"@E 999.99")) + " inclusa no Boleto"
			Endif

			// Adiciona mensagem de Valor Incluso no boleto
			If !Empty(cInstr06)
				Aadd(aInstrucoes,{cInstr06,oFont06})
			Endif
			// Adiciona mensagem de Multa
			If !Empty(cInstr05)
				Aadd(aInstrucoes,{cInstr05,oFont06})
			Endif
			// Adiciona mensagem de Juros
			If !Empty(cInstr01)
				Aadd(aInstrucoes,{cInstr01,oFont06})
			Endif
			// Adiciona mensagem de Desconto
			If !Empty(cInstr02)
				Aadd(aInstrucoes,{cInstr02,oFont06})
			Endif
			// Adiciona mensagem de Protesto
			If !Empty(cInstr03)
				Aadd(aInstrucoes,{cInstr03,oFont06})
			Endif
			// Adiciona mensagem de Responsabilidade Beneficiario - Itau
			If !Empty(cInstr04)
				Aadd(aInstrucoes,{cInstr04,oFont03})
			Endif


			cLinha          := " "

			If cBanco == "237"

				cDigVer := sf237Dig()  // calculo dos digitos verificadores do nosso numero.

				If Empty(SE1->E1_numbco)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_numbco   := cNossoNum+cDigVer
					SE1->E1_NRBCORI := cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif
				If cBancoImp == "ABC"
					//3          //4                           //8
					cBarra	:= cBanco+If(SE1->E1_MOEDA==1,'9','0')
					cBarra += StrZero(nFatorVen,4)
					cBarra += Substr(STRZERO(nE1_Saldo,16,2),6,8)
					cBarra += Substr(STRZERO(nE1_Saldo,16,2),15,2)
					cBarra += Substr(cAgencia,1,4)
					cBarra += Substr(cCarteira,1,2)
					cBarra += StrZero(VAL(cNossoNum),11)
					cBarra += cNumConta
					cBarra += "0"
				Else
					//3          //4                           //8
					cBarra	:=cBanco+If(SE1->E1_MOEDA==1,'9','0')+strzero(nFatorVen,4);
						+SUBS(STRZERO(nE1_Saldo,16,2),6,8)+SUBS(STRZERO(nE1_Saldo,16,2),15,2);
						+cAgencia+Substr(cCarteira,2,1)+STRZERO(VAL(cNossoNum),11)+cNumConta+"0"
				endif
				sf237DAC()

				sf237Bar()

				cBMapABN        := "\IMAGENS\LOGOBRADESCO.BMP"

			ElseIf cBanco == "246"
				// A funcao sf246_DV calcula o digito verificador do nosso número
				//AAAA			O código da agência do título, sem dv.
				//CCC			O código da carteira (por exemplo, 121)
				//NNNNNNNNNN 	            O nosso número, sem DV

				cDigVer	:= sf246_DV(Substr(cAgencia,1,4)+cCarteira+cNossoNum)

				If Empty(SE1->E1_NUMBCO)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_NUMBCO    := cNossoNum+cDigVer
					SE1->E1_NRBCORI   := cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif

				// 246 9 1 6859 0000001225 0001 110 5021431 00010679557
				// 246 9 6 6859 0000001225 0001 110 5021431 00106795600
				// 246 9 9 6859 0000001137 0001 110 5021431 00106795610
				// Banco
				cBarra := "246"																// 01-03 Identificacao do banco - 246 - ABC
				// Moeda
				cBarra += If(SE1->E1_MOEDA==1,'9','0')										// 04-04 - Moeda 9-REAL 0-Variável
				//DAC - Digito de AutoConferencia											// 05-05 - Digito Verificador a ser calculado abaixo
				// Vencimento
				cBarra += StrZero(nFatorVen,4)												// 06-09 - Fator de Vencimento
				// Valor
				cBarra += StrZero((nE1_Saldo)*100,10) 										// 10-19 - Valor do titulo
				// Campo Livre
				cBarra +=  Substr(cAgencia,1,4)                                             // 01–04 - 4  Código da Agência (Sem DV)
				cBarra +=  cCarteira                                                        // 05–07 - 3  Número da Carteira do Título
				cBarra +=  cOperacao                                                        // 08-14 - 7  Número da Operação
				cBarra +=  cNossoNum+cDigVer                                                // 15-25 - 11 Nosso Número (Com DV)

				cDigBarra 	:= sf246_DAC(cBarra)	  	// calculo dos digito verificador do codigo barra para a posicao 5 do codigo de barra


				cBarraFim  	:= Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)

				//Posição 01-03 = Identificação do banco (246 = ABC)
				cBar1	:= Substr(cBarraFim,1,3)					//
				//Posição 04-04 = Código de moeda (9 = Real)
				cBar1	+= Substr(cBarraFim,4,1)					//
				//Posição 05-09 = 5 primeiras posições do campo livre (posições 20 a 24 do código de barras)
				cBar1 	+= Substr(cBarraFim,20,5)					// Cinco primeiras posições do Campo Livre
				//Posição 10-10 = Dígito verificador do primeiro campo
				cBar1   += sf246DvLD(cBar1)							// Digito verificador da 1º campo da linha digitavel

				//Posição 11-20 = 6ª a 15ª posições do campo livre (posições 25 a 34 do código de barras)
				cBar2	:= Substr(cBarraFim,25,10)					// Posição 6 a 15 do Campo Livre
				//Posição 21-21 = Dígito verificador do segundo campo
				cBar2   += sf246DvLD(cBar2)							// Digito verificador do 2º campo da linha digitavel

				//Posição 22-31 = 16ª a 25ª posições do campo livre (posições 35 a 44 do código de barras)
				cBar3   := Substr(cBarraFim,35,10)					// Posicao 16 a 25 do Campo Livre
				//Posição 32-32 = Dígito verificador do terceiro campo
				cBar3   += sf246DvLD(cBar3)							// Digito verificador do 3º campo da linha digitavel

				//Posição 33-33 = Dígito verificador geral (posição 5 do código de barras)
				cBar4	:= cDigBarra								// Digito Verificador Codigo Barras

				//Posição 34-37 = Fator de vencimento (posições 6 a 9 do código de barras)
				cBar5   := Substr(cBarraFim,6,4)					//
				//Posição 38-47 = Valor nominal do título (posições 10 a 19 do código de barras)
				cBar5	+= Substr(cBarraFim,10,10)					// Valor do titulo


				cLinha := Substr(cBar1,1,5) + "." + Substr(cBar1,6,5) + " "
				cLinha += Substr(cBar2,1,5) + "." + Substr(cBar2,6,6) + " "
				cLinha += Substr(cBar3,1,5) + "." + Substr(cBar3,6,6) + " "
				cLinha += cBar4 + " "
				cLinha += cBar5

				cBMapABN        := "\IMAGENS\BBABC.BMP"
			ElseIf cBanco == "001"

				If Empty(SE1->E1_numbco)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_numbco   := cNossoNum
					SE1->E1_NRBCORI := cNossoNum
					MsUnlock("SE1")
				Endif
				//3          //4                           //8
				cBarra :=cBanco+If(SE1->E1_MOEDA==1,'9','0')+strzero(nFatorVen,4);
					+SUBS(STRZERO(nE1_Saldo,16,2),6,8)+SUBS(STRZERO(nE1_Saldo,16,2),15,2)+"000000";
					+Substr(SEE->EE_CODEMP,1,7)+STRZERO(VAL(cNossoNum),10)+"17";

				sf237DAC()

				sf001Bar()

				cBMapABN        := "\IMAGENS\LOGOBB.BMP"

			Elseif cBanco == "341"

				cDigVer := sf341DV()  // calculo dos digitos verificadores do nosso numero.

				If Empty(SE1->E1_numbco)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_numbco   	:= cNossoNum+cDigVer
					SE1->E1_NRBCORI 	:= cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif
				//341 9 1 7272 0000350000 109 00000001 4 1293 216865 000
				cBarra	:=SE1->E1_PORTADO
				cBarra	+= If(SE1->E1_MOEDA==1,'9','0')
				cBarra 	+= Strzero(nFatorVen,4)
				cBarra  += StrZero(nE1_Saldo*100,10)						// 5 - Pos 10a19	Valor nominal
				cBarra 	+= "109"
				cBarra 	+= Substr(cNossoNum,1,8)+cDigVer
				cBarra	+= cAgencia + Substr(cConta,1,6)
				cBarra 	+= "000"

				sf341DAC()

				sf341Bar()

				cBMapABN        := "\IMAGENS\LOGOITAU.BMP"

			Elseif cBanco == "745"

				cDigVer := st745_DV(cNossoNum,0)  // calculo dos digitos verificadores do nosso numero.

				If Empty(SE1->E1_numbco)
					DbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_NUMBCO   	:= cNossoNum+cDigVer
					SE1->E1_NRBCORI 	:= cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif
				//745 9 3 301017194401800200000000943346150000000100
				//745 9 3 4615 0000000100 3 301 071944 01 8 000000000094

				cBarra	:= "745"		                    				// 1 - Pos 1 a 3 	Identificacao Banco
				cBarra  += If(SE1->E1_MOEDA==1,'9','0')						// 2 - Pos 4		Moeda
				cBarra  += StrZero(nFatorVen,4)                         	// 4 - Pos 6 a 9 	Fator Vencimento
				cBarra  += StrZero(nE1_Saldo*100,10)						// 5 - Pos 10a19	Valor nominal
				cBarra  += "3"												// 6 - Pos 20		3-Cobranca c/registro/sem registro
				cBarra  += U_CITIBANK("BOL",,10)							// 7 - Pos 21a23 	3 ultimos digitos da identificacao no Citibank posicao 44 a 46
				cBarra  += U_CITIBANK("BOL",,4)								// 8 - Pos 24a29	Base Conta Cosmos
				cBarra  += U_CITIBANK("BOL",,5)								// 9 - Pos 30a31  Sequencia Conta Cosmos
				cBarra	+= U_CITIBANK("BOL",,6)								// 10- Pos 32     Digito verificador Conta Cosmos
				cBarra	+= cNossoNum+cDigVer								// 11- Pos 33a44  Nosso numero

				cDigBarra := st745_DV(cBarra,1)  // calculo dos digito verificador do codigo barra para a posicao 5nosso numero.

				cBarraFim  := Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)

				cBar1	:= "745"												// Pos 1 a 3		Banco Citibank
				cBar1	+= If(SE1->E1_MOEDA==1,'9','0')						// Pos 4			9 - Valor Obrigatorio R$
				cBar1   += "3"												// Pos 5 			3-Cobrancao com registro-sem registro
				cBar1 	+= U_CITIBANK("BOL",,10)								// Pos 6 a 8		3 ultimos digitos da identificacao no Citibank
				cBar1	+= U_CITIBANK("BOL",,7)								// Pos 9			1º digito da base
				cBar1   += st745DvLD(cBar1)									// pos 10			Digito verificador da 1º campo da linha digitavel

				cBar2	:= U_CITIBANK("BOL",,8)	 							// Pos 11a15		2 a 6º digito da Base
				cBar2   += U_CITIBANK("BOL",,5)								// Pos 16a17		Sequencia da Conta Cosmos
				cBar2   += U_CITIBANK("BOL",,6)								// Pos 18	       Digito verificador Conta Cosmos
				cBar2	+= Substr(SE1->E1_NUMBCO,1,2)						// Pos 19a20		2 primeiros digitos do nosso numero
				cBar2   += st745DvLD(cBar2)									// Pos 21			Digito verificador do 2º campo da linha digitavel

				cBar3   := Substr(SE1->E1_NUMBCO,3,10)						// Pos 22a31		10 ultimos digitos do nosso numero
				cBar3   += st745DvLD(cBar3)									// Pos 32			Digito verificador do 3º campo da linha digitavel

				cBar4	:= cDigBarra											// Pos 33			Digito Verificador Codigo Barras
				cBar4   += " "
				cBar4	+= StrZero(nFatorVen,4)								// Pos 34a37		Fator de vencimento
				cBar4   += StrZero(nE1_Saldo*100,10)						// Pos 38a47		Valor do titulo


				cLinha := Substr(cBar1,1,5) + "." + Substr(cBar1,6,5) + " "
				cLinha += Substr(cBar2,1,5) + "." + Substr(cBar2,6,6) + " "
				cLinha += Substr(cBar3,1,5) + "." + Substr(cBar3,6,6) + " "
				cLinha += cBar4

				cBMapABN        := "\IMAGENS\CITIBK.BMP"

			ElseIf cBanco == "422"  .And. cBancoImp == "SAFBR" // Usa correspondente Bradesco
				//+cDigVer+"-"+cDcb
				cDigVer  := sf422Dig()  // calculo dos digitos verificadores do nosso numero SAFRA.
				cDcb	 := sf237Dig()   // calculo dos digitos verificadores do nosso numero BRADESCO.

				If Empty(SE1->E1_numbco)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_numbco    := cNossoNum+cDigVer
					SE1->E1_NRBCORI   := cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif

				// Banco
				cBarra := "237"												//	01-03 Identificacao do banco - 237 - Corresponde Bradesco
				cBarra += If(SE1->E1_MOEDA==1,'9','0')						// 04-04 - Moeda
				//DAC - Digito de AutoConferencia							// 05-05 - Digito Verificador a ser calculado abaixo
				cBarra += StrZero(nFatorVen,4)								// 06-09 - Fator de Vencimento
				cBarra += StrZero((nE1_Saldo)*100,10) 						// 10-19 Valor do titulo
				// Campo Livre
				cBarra += "3114"												// 20-23 - Agencia Cedente - Fixo 3114
				cBarra += "09"												// 24-25 - Carteira - Fixo 09
				cBarra += Substr(DTOS(SE1->E1_EMISSAO),3,2)				// 26-27 - Ano de emissao do Boleto
				cBarra += StrZero(Val(cNossoNum),8)+cDigVer				// 28-36 - Nosso numero + Digito verificador, 9 digitos
				cBarra += "0176300"											// 37-43 - Conta do Cedente - Fixo 0176300
				cBarra += "0"													// 44-44 - Zero Fixo 0

				cDigBarra 	:= st745_DV(cBarra,1,1)  // calculo dos digito verificador do codigo barra para a posicao 5 do codigo de barra

				cBarraFim  	:= Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)

				cBar1	:= "237"												// 237-Banco Bradesco - Correspondente
				cBar1	+= If(SE1->E1_MOEDA==1,'9','0')						// 9 - Moeda
				cBar1   += Substr(cBarra,19,5)								// 5 primeiras posicoes do campo livre
				cBar1   += st745DvLD(cBar1)									// Digito verificador da 1º campo da linha digitavel

				cBar2	:= Substr(cBarra,24,10)	 							// 6 a 15 posicao do campo livre
				cBar2   += st745DvLD(cBar2)									// Digito verificador do 2º campo da linha digitavel

				cBar3   := Substr(cBarra,34,10)								// 16 a 25 posicao do campo livre
				cBar3   += st745DvLD(cBar3)									// Digito verificador do 3º campo da linha digitavel

				cBar4	:= cDigBarra											// Digito Verificador Codigo Barras

				cBar5   := Substr(cBarra,5,4)								// Fator de vencimento
				cBar5   += Substr(cBarra,9,10)								// Valor do titulo


				cLinha := Substr(cBar1,1,5) + "." + Substr(cBar1,6,5) + " "
				cLinha += Substr(cBar2,1,5) + "." + Substr(cBar2,6,6) + " "
				cLinha += Substr(cBar3,1,5) + "." + Substr(cBar3,6,6) + " "
				cLinha += cBar4 + " "
				cLinha += cBar5

				cBMapABN        := "\IMAGENS\LOGOBRADESCO.BMP"

			ElseIf cBanco == "422"   // Banco Safra

				cDigVer  := sf422DV(cNossoNum)  // calculo dos digitos verificadores do nosso numero SAFRA.

				If Empty(SE1->E1_numbco)
					DbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_NUMBCO    := cNossoNum+cDigVer
					SE1->E1_NRBCORI   := cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif
				//			422 9 1 5119 0000064900 7 00200 000001894 312700016 2
				cBarra := "422"												// 01-03 Identificacao do banco - 237 - Corresponde Bradesco
				cBarra += If(SE1->E1_MOEDA==1,'9','0')						// 04-04 - Moeda
				//DAC - Digito de AutoConferencia							// 05-05 - Digito Verificador a ser calculado abaixo
				cBarra += StrZero(nFatorVen,4)								// 06-09 - Fator de Vencimento
				cBarra += StrZero(nE1_Saldo*100,10) 						// 10-19 Valor do titulo
				// Campo Livre
				cBarra += "7"												// 20-20 - Sistema - Fixo 7                             12345 678901234
				cBarra += cAgencia+cCedente									// 21-34 - Cliente - Código Cedente = Agencia + Conta   06700.002033771
				cBarra += StrZero(Val(cNossoNum),8)	+cDigVer				// 35-43 - Nosso numero 8 digitos
				cBarra += "2"												// 44-44 - Conta do Cedente - Fixo 0176300

				cDigBarra 	:= sf422DAC(cBarra)  // calculo dos digito verificador do codigo barra para a posicao 5 do codigo de barra

				cBarraFim  	:= Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)

				cBar1	:= "422"												// 422-Banco Safra
				cBar1	+= If(SE1->E1_MOEDA==1,'9','0')						// 9 - Moeda
				cBar1   += Substr(cBarra,19,5)								// 5 primeiras posicoes do campo livre
				cBar1   += sf422DvLD(cBar1)									// Digito verificador da 1º campo da linha digitavel

				cBar2	:= Substr(cBarra,24,10)	 							// 6 a 15 posicao do campo livre
				cBar2   += sf422DvLD(cBar2)									// Digito verificador do 2º campo da linha digitavel

				cBar3   := Substr(cBarra,34,10)								// 16 a 25 posicao do campo livre
				cBar3   += sf422DvLD(cBar3)									// Digito verificador do 3º campo da linha digitavel

				cBar4	:= cDigBarra											// Digito Verificador Codigo Barras

				cBar5   := Substr(cBarra,5,4)								// Fator de vencimento
				cBar5   += Substr(cBarra,9,10)								// Valor do titulo


				cLinha := Substr(cBar1,1,5) + "." + Substr(cBar1,6,5) + " "
				cLinha += Substr(cBar2,1,5) + "." + Substr(cBar2,6,6) + " "
				cLinha += Substr(cBar3,1,5) + "." + Substr(cBar3,6,6) + " "
				cLinha += cBar4 + " "
				cLinha += cBar5

				cBMapABN        := "\IMAGENS\LOGOSAFRA.BMP"

			ElseIf cBanco == "033"   // SANTANDER

				cDigVer	:= sf033_DV(cNossoNum,0)  // calculo do digito verificador - Nosso número conforme Faixa Disponivel e 0(zero) pois para resto igual a 1 ou 0 o digito será zero

				If Empty(SE1->E1_numbco)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_numbco    := cNossoNum+cDigVer
					SE1->E1_NRBCORI   := cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif
				// Banco
				cBarra := "033"																//	01-03 Identificacao do banco - 033 -
				// Moeda
				cBarra += If(SE1->E1_MOEDA==1,'9','8')										// 04-04 - Moeda
				//DAC - Digito de AutoConferencia											// 05-05 - Digito Verificador a ser calculado abaixo
				// Vencimento
				cBarra += StrZero(nFatorVen,4)												// 06-09 - Fator de Vencimento
				// Valor
				cBarra += StrZero((nE1_Saldo)*100,10) 										// 10-19 Valor do titulo
				// Campo Livre
				cBarra += "9"																// 20-20 - Fixo "9"
				cBarra += Padr(cCedente,7)													// 21-27 - Codigo do Cedente padrão Santander Banespa
				cBarra += cNossoNum+cDigVer													// 28-40 - Nosso numero + Digito verificador, 13 digitos
				cBarra += "0"																// 41-41 - IOS Seguradoras - Demais clientes fixo "0"
				cBarra += "201"																// 42-44 - Tipo Modalidade Carteira - 101-Cobranca Simples Rápida COM registro
				//										- 102-Cobrança Simples - SEM Registro
				//                                  - 201-Penhor Rápida com Registro
				cDigBarra 	:= sf033_DV(cBarra,1)	  	// calculo dos digito verificador do codigo barra para a posicao 5 do codigo de barra
				//			Alert(cDigBarra)
				cBarraFim  	:= Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)
				//033 9 9 2222 1
				//604 0000000 0
				//00002 7 0 101 9
				//1 4864 0000022708

				cBar1	:= "033"									// 01-03 033- Banco Santander
				cBar1	+= If(SE1->E1_MOEDA==1,'9','8')				// 04-04 9 - Moeda 9=Real 8=Outras moedas
				cBar1  += "9"										// 05-05 Fixo "9"
				cBar1  += Padr(Substr(cCedente,1,4),4)				// 06-09 Código Cedente Padrão Santander Banespa
				cBar1  += sf033DvLD(cBar1)							// Digito verificador da 1º campo da linha digitavel

				cBar2	:= Padr(Substr(cCedente,5,3),3)				// 11-13 Restante do Código do Cedente Padrão Santander
				cBar2  += Substr(cNossoNum,1,7)					// 14-20 7 Primeiros campos do Nosso Número
				cBar2  += sf033DvLD(cBar2)							// Digito verificador do 2º campo da linha digitavel

				cBar3  := Substr(cNossoNum,8,5)+cDigVer			// 22-27 Restante do Nosso Número+DigitoVerificador
				cBar3  += "0"										// 28-28 IOS Seguradoras - Demais Clientes Fixo "0"
				cBar3  += "201"									// 29-31 Tipo de Modalidade Carteira	- 101- Cobrança Simples Rápida COM Registro
				// 																							- 102- Cobrança Simples SEM Registro
				//																							- 201- Penhor
				cBar3  += sf033DvLD(cBar3)							// 32-32  Digito verificador do 3º campo da linha digitavel

				cBar4	:= cDigBarra								// 33-33 Digito Verificador Codigo Barras

				cBar5	:= StrZero(nFatorVen,4)						// 34-36 Fator de Vencimento
				cBar5	+= StrZero((nE1_Saldo)*100,10) 				// 37-47 Valor do titulo


				cLinha := Substr(cBar1,1,5) + "." + Substr(cBar1,6,5) + " "
				cLinha += Substr(cBar2,1,5) + "." + Substr(cBar2,6,6) + " "
				cLinha += Substr(cBar3,1,5) + "." + Substr(cBar3,6,6) + " "
				cLinha += cBar4 + " "
				cLinha += cBar5

				cBMapABN        := "\IMAGENS\LOGOSANTANDER.BMP"
				// BicBanco - 05/01/2012
			ElseIf cBanco == "320"   // BICBANCO

				// A funcao sf320DvNN calcula o digito verificar para o envio de arquivo de remessa, concatenando Agencia Bic+Nosso Numero
				cDigVer	:= sf320DvNN(cAgBic,cNossoNum)

				If Empty(SE1->E1_NUMBCO)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_NUMBCO    := cNossoNum+cDigVer
					SE1->E1_NRBCORI   := cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif

				// A função sf320_DV calcula o digito verificador concatenando Carteira+Radical+Matricula+Nosso Numero
				cDigVer	:= sf320_DV(cNossoNum)


				// Banco
				cBarra := "237"																// 01-03 Identificacao do banco - 237 - Correspondente
				// Moeda
				cBarra += If(SE1->E1_MOEDA==1,'9','0')										// 04-04 - Moeda
				//DAC - Digito de AutoConferencia											// 05-05 - Digito Verificador a ser calculado abaixo
				// Vencimento
				cBarra += StrZero(nFatorVen,4)												// 06-09 - Fator de Vencimento
				// Valor
				cBarra += StrZero((nE1_Saldo)*100,10) 										// 10-19 Valor do titulo
				// Campo Livre
				cBarra += cAgencia															// 20-23 - Agência Cedente
				cBarra += cCarteira															// 24-25 - Carteira
				cBarra += cRadical															// 26-27 - Radical ( Agencia )
				cBarra += cMatricula														// 28-30 - Matrícula(Cód. Informado Pelo Suporte a clientes)
				cBarra += cNossoNum															// 31-36 - Número do Nosso Número ( Sem o Digito Verificador )
				cBarra += StrZero(Val(cConta),7)											// 37-43 - Conta do Cedente ( Sem o Digito Verificador, completar com zeros a esquerda quando necessário )
				cBarra += "0"																// 44-44 - Zero

				//237 9 1 5214 0000001000 4150 16 32 200 093220 0000320 0

				cDigBarra 	:= sf320_DAC(cBarra)	  	// calculo dos digito verificador do codigo barra para a posicao 5 do codigo de barra


				cBarraFim  	:= Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)

				//Posição 01-03 = Identificação do banco (001 = Banco do Brasil)
				cBar1	:= Substr(cBarraFim,1,3)					//
				//Posição 04-04 = Código de moeda (9 = Real)
				cBar1	+= Substr(cBarraFim,4,1)					//
				//Posição 05-09 = 5 primeiras posições do campo livre (posições 20 a 24 do código de barras)
				cBar1 	+= Substr(cBarraFim,20,5)					// Cinco primeiras posições do Campo Livre
				//Posição 10-10 = Dígito verificador do primeiro campo
				cBar1   += sf320DvLD(cBar1)							// Digito verificador da 1º campo da linha digitavel

				//Posição 11-20 = 6ª a 15ª posições do campo livre (posições 25 a 34 do código de barras)
				cBar2	:= Substr(cBarraFim,25,10)					// Posição 6 a 15 do Campo Livre
				//Posição 21-21 = Dígito verificador do segundo campo
				cBar2   += sf320DvLD(cBar2)							// Digito verificador do 2º campo da linha digitavel

				//Posição 22-31 = 16ª a 25ª posições do campo livre (posições 35 a 44 do código de barras)
				cBar3   := Substr(cBarraFim,35,10)					// Posicao 16 a 25 do Campo Livre
				//Posição 32-32 = Dígito verificador do terceiro campo
				cBar3   += sf320DvLD(cBar3)							// Digito verificador do 3º campo da linha digitavel

				//Posição 33-33 = Dígito verificador geral (posição 5 do código de barras)
				cBar4	:= cDigBarra								// Digito Verificador Codigo Barras

				//Posição 34-37 = Fator de vencimento (posições 6 a 9 do código de barras)
				cBar5   := Substr(cBarraFim,6,4)					//
				//Posição 38-47 = Valor nominal do título (posições 10 a 19 do código de barras)
				cBar5	+= Substr(cBarraFim,10,10)					// Valor do titulo


				cLinha := Substr(cBar1,1,5) + "." + Substr(cBar1,6,5) + " "
				cLinha += Substr(cBar2,1,5) + "." + Substr(cBar2,6,6) + " "
				cLinha += Substr(cBar3,1,5) + "." + Substr(cBar3,6,6) + " "
				cLinha += cBar4 + " "
				cLinha += cBar5

				cBMapABN        := "\IMAGENS\LOGOBRADESCO.BMP"

			ElseIf cBanco == "399"   // HSBC

				// A funcao sf399DV calcula o digito verificador do nosso número
				cDigVer	:= sf399_DV(cNossoNum)

				If Empty(SE1->E1_NUMBCO)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_NUMBCO    := cNossoNum+cDigVer
					SE1->E1_NRBCORI   := cNossoNum+cDigVer
					MsUnlock("SE1")
				Endif
				// 399 9 1 6436 0000012350 74977000010 0398 0204890 00 1

				// Banco
				cBarra := "399"																// 01-03 Identificacao do banco - 399 - HSBC
				// Moeda
				cBarra += If(SE1->E1_MOEDA==1,'9','0')										// 04-04 - Moeda
				//DAC - Digito de AutoConferencia											// 05-05 - Digito Verificador a ser calculado abaixo
				// Vencimento
				cBarra += StrZero(nFatorVen,4)												// 06-09 - Fator de Vencimento
				// Valor
				cBarra += StrZero((nE1_Saldo)*100,10) 										// 10-19 - Valor do titulo
				// Campo Livre
				cBarra += cNossoNum+cDigVer 												// 20-30 - Número Bancário(Nosso Número)
				cBarra += Substr(cAgencia,1,4)												// 31-34 - Código da Agência
				cBarra += Substr(cConta,1,7)												// 35-41 - Conta de Cobranca
				cBarra += cCarteira															// 42-43 - Código Carteira = '00'
				cBarra += '1'																	// 44-44 - Código Aplicativo da Cobrança (COB) = '1'


				cDigBarra 	:= sf399_DAC(cBarra)	  	// calculo dos digito verificador do codigo barra para a posicao 5 do codigo de barra


				cBarraFim  	:= Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)

				//Posição 01-03 = Identificação do banco (399 = HSBC)
				cBar1	:= Substr(cBarraFim,1,3)					//
				//Posição 04-04 = Código de moeda (9 = Real)
				cBar1	+= Substr(cBarraFim,4,1)					//
				//Posição 05-09 = 5 primeiras posições do campo livre (posições 20 a 24 do código de barras)
				cBar1 	+= Substr(cBarraFim,20,5)					// Cinco primeiras posições do Campo Livre
				//Posição 10-10 = Dígito verificador do primeiro campo
				cBar1   += sf399DvLD(cBar1)							// Digito verificador da 1º campo da linha digitavel

				//Posição 11-20 = 6ª a 15ª posições do campo livre (posições 25 a 34 do código de barras)
				cBar2	:= Substr(cBarraFim,25,10)					// Posição 6 a 15 do Campo Livre
				//Posição 21-21 = Dígito verificador do segundo campo
				cBar2   += sf399DvLD(cBar2)							// Digito verificador do 2º campo da linha digitavel

				//Posição 22-31 = 16ª a 25ª posições do campo livre (posições 35 a 44 do código de barras)
				cBar3   := Substr(cBarraFim,35,10)					// Posicao 16 a 25 do Campo Livre
				//Posição 32-32 = Dígito verificador do terceiro campo
				cBar3   += sf399DvLD(cBar3)							// Digito verificador do 3º campo da linha digitavel

				//Posição 33-33 = Dígito verificador geral (posição 5 do código de barras)
				cBar4	:= cDigBarra								// Digito Verificador Codigo Barras

				//Posição 34-37 = Fator de vencimento (posições 6 a 9 do código de barras)
				cBar5   := Substr(cBarraFim,6,4)					//
				//Posição 38-47 = Valor nominal do título (posições 10 a 19 do código de barras)
				cBar5	+= Substr(cBarraFim,10,10)					// Valor do titulo


				cLinha := Substr(cBar1,1,5) + "." + Substr(cBar1,6,5) + " "
				cLinha += Substr(cBar2,1,5) + "." + Substr(cBar2,6,6) + " "
				cLinha += Substr(cBar3,1,5) + "." + Substr(cBar3,6,6) + " "
				cLinha += cBar4 + " "
				cLinha += cBar5

				cBMapABN        := "\IMAGENS\LOGOHSBC.BMP"
			Endif

			If cEmpAnt == "06"
				cBMapEmp		:= "\imagens\redelog.bmp"
			ElseIf cEmpAnt == "16"
				cBMapEmp		:= "\imagens\atsa.bmp"
			Else 
				cBMapEmp		:= "\imagens\redelog.bmp"
			Endif 

			oPrn:Say ( 000 , 0000, " ", oFont07,100 ) // startando a impressora
			If cBancoImp $ "ITAU" //"ITAU3#ITAU5#HSBC"
				oPrn:Say ( 050 , 1800, "RECIBO DO PAGADOR", oFont07,100)
			ElseIf cBancoImp $ "SAFRA"
				oPrn:Say ( 050 , 1800, "RECIBO DO PAGADOR", oFont07,100)
			Else
				oPrn:Say ( 050 , 1800, "RECIBO DO SACADO",oFont07,100)
			Endif
			oPrn:Box ( 090 , 0200, 1900, 2180)
			oPrn:SayBitmap( 95, 210,cBMapEmp,300,160 )
			oPrn:Say ( 160, 900, SM0->M0_NOMECOM,oFont09,100)
			oPrn:Say ( 260, 230, ALLTRIM(SM0->M0_ENDENT)+'  Bairro: '+ALLTRIM(SM0->M0_BAIRENT)+'  '+ALLTRIM(SM0->M0_CIDENT)+' - ';
				+ALLTRIM(SM0->M0_ESTENT)+'  CEP: '+ALLTRIM(SM0->M0_CEPENT)+'  CNPJ: '+SUBS(SM0->M0_CGC,1,2)+"."+SUBS(SM0->M0_CGC,3,3);
				+"."+SUBS(SM0->M0_CGC,6,3)+"/"+SUBS(SM0->M0_CGC,9,4)+"-"+SUBS(SM0->M0_CGC,13,2),oFont05,100)
			oPrn:line( 300, 200, 0301, 2180)
			oPrn:line( 500, 200, 0501, 2180)
			oPrn:line( 300, 1800, 0500, 1801)
			oPrn:Say ( 355, 1870, "VENCIMENTO",oFont07,100)
			cNome   := SA1->A1_NOME
			oPrn:Say( 0350, 0240, SE1->E1_CLIENTE + " - " + ALLTRIM(cNome), oFont01,100  )
			oPrn:Say( 0390, 0240, ALLTRIM(SA1->A1_END), oFont01,100  )

			If cVencAjust == "Não"
				oPrn:Say( 0420, 1900, DTOC(SE1->E1_VENCREA) , oFont07,100  )   //Vencimento do Titulo
			Else
				oPrn:Say( 0420, 1900, DTOC(dDataReimp) , oFont07,100  )   //Vencimento do Titulo
			Endif

			oPrn:Say( 0430, 0240, substr(SA1->A1_CEP,1,5)+"-"+substr(SA1->A1_CEP,6,3)+"  "+ALLTRIM(SA1->A1_BAIRRO)+" - "+ALLTRIM(SA1->A1_MUN)+"   "+SA1->A1_EST, oFont01,100  )
			oPrn:Say(  560, 0220,cMsgImp1  ,oFont08,095 )
			oPrn:Say(  610, 0220,cMsgImp2  ,oFont08,095 )
			oPrn:Say(  660, 0220,cMsgImp3  ,oFont08,095 )
			oPrn:Say(  710, 0220,cMsgImp4  ,oFont08,095 )

			If cBancoImp $ "SAFRA"
				oPrn:Say(  760, 0220,"ESTE BOLETO REPRESENTA DUPLICATA CEDIDA FIDUCIARIAMENTE",oFont08,095 )
				oPrn:Say(  810, 0220,"AO BANCO SAFRA S/A, FICANDO VEDADO O PAGAMENTO DE ",oFont08,095 )
				oPrn:Say(  860, 0220,"QUALQUER OUTRA FORMA QUE NÃO ATRAVÉS DO PRESENTE BOLETO.",oFont08,095 )
			Endif

			/*
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄAIXAÄÄÄÄAIXAÄÄÄÄAIXAAIXA³
			//³                                                 ³
			//³       MONTA PARTE INFERIOR DO RECIBO / CAIXA    ³
			//³                                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄAIXAÄÄÄÄAIXAÄÄÄÄAIXAÄÄÄÄAI
			*/
			// Monta box do boleto
			//        lin   col   lin   col
			//      oPrn:Box (1380, 0200, 1900, 2180)


			// Monta linhas horizontais
			//        lin   col   lin   col
			oPrn:Line(1230, 1720, 1230, 2180)
			oPrn:Line(1300, 1720, 1300, 2180)
			oPrn:Line(1380, 1720, 1380, 2180)
			oPrn:Line(1450, 1720, 1450, 2180)
			oPrn:Line(1520, 0200, 1520, 2180)
			oPrn:Line(1590, 1720, 1590, 2180)
			oPrn:Line(1660, 1720, 1660, 2180)
			oPrn:Line(1730, 1720, 1730, 2180)
			oPrn:Line(1800, 0200, 1801, 2180)
			oPrn:Line(1230, 1720, 1900, 1720)
			If cBancoImp $  "ITAU" //"ITAU3#ITAU5#HSBC"
				oPrn:Say( 1235, 1730, "Codigo Beneficiário"		,oFont03,100 )
			ElseIf cBancoImp $ "SAFRA"
				oPrn:Say( 1235, 1730, "Agência/Código do Beneficiário"		,oFont03,100 )
			ElseIf cBancoImp $ "HSBC#BCABC"
				oPrn:Say( 1235, 1730, "Agencia/Código do Cedente"		,oFont03,100 )
			Else
				oPrn:Say( 1235, 1730, "Codigo Cedente "        ,oFont03,100  )
			Endif

			If cBancoImp == "HSBC"
				oPrn:Say( 1310, 1730, "Para Uso do Banco"      ,oFont03,100  )
			Else
				oPrn:Say( 1310, 1730, "Nº. Documento "         ,oFont03,100  )
			Endif
			oPrn:Say( 1385, 1730, "Nosso Número "          ,oFont03,100  )  //adicionado
			oPrn:Say( 1455, 1730, "Valor do Documento "    ,oFont03,100  )

			If cBanco == "237"
				//			oPrn:Say( 1265, 1880, Substr(ALLTRIM(SA6->A6_AGENCIA),1,4)+"-"+Substr(ALLTRIM(SA6->A6_AGENCIA),5,1)+'/'+subs(SA6->A6_NUMCON,1,7)+"-"+subs(SA6->A6_NUMCON,8,1) ,oFont01,100 )   //Codigo do Cedente "2232-/0004778-3"
				oPrn:Say( 1265, 1800, cAgImpBol+'/'+subs(SA6->A6_NUMCON,1,7)+"-"+subs(SA6->A6_NUMCON,8,1) ,oFont01,100 )   //Codigo do Cedente "2232-/0004778-3"
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+" "+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )   //Vencimento do Titulo
				oPrn:Say( 1410, 1800, cCarteira+"/"+cNossoNum+"-"+cDigVer                , oFont01,100  )

			ElseIf cBanco == "246"

				oPrn:Say( 1265, 1800, cAgImpBol+'/'+SA6->A6_NUMCON 									,oFont01,100 )   	// Agencia/Codigo Cedente  00019/002206596
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+" "+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )   	// Numero Documento
				oPrn:Say( 1410, 1800, cCarteira+"/"+cNossoNum+"-"+cDigVer             				,oFont01,100  )	// Nosso numero 00019/110/0010679556-D
			ElseIf cBanco == "001"
				oPrn:Say( 1265, 1730, ALLTRIM(SA6->A6_AGENCIA)+"-7"+'/'+"0000000"+subs(SA6->A6_NUMCON,1,5)+"-"+subs(SA6->A6_NUMCON,6,1) ,oFont01,100 )   //Codigo do Cedente "2232-/0004778-3"
				oPrn:Say( 1340, 1880, SE1->E1_PREFIXO+" "+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )   //Vencimento do Titulo
				oPrn:Say( 1410, 1730, Substr(SEE->EE_CODEMP,1,7)+cNossoNum                , oFont01,100  )

			Elseif cBanco == "341"

				oPrn:Say( 1265, 1800, ALLTRIM(SA6->A6_AGENCIA)+'/'+subs(SA6->A6_NUMCON,1,5)+"-"+subs(SA6->A6_NUMCON,6,1) ,oFont01,100 )   //Codigo do Cedente "2232-/0004778-3"
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )   //Vencimento do Titulo
				oPrn:Say( 1410, 1800, /*If(SM0->M0_CODIGO == "01","109",)+"*/"109 /"+cNossoNum+"-"+cDigVer                , oFont01,100  )

			Elseif cBanco == "745"

				oPrn:Say( 1265, 1800, ALLTRIM(SA6->A6_AGENCIA)+'/'+U_CITIBANK("BOL",,11) ,oFont01,100 )  // Agencia/Conta Cosmos
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )
				oPrn:Say( 1410, 1800, cNossoNum+"."+cDigVer                , oFont01,100  )

			ElseIf cBanco == "422" .And. cBancoImp == "SAFBR" // Usa correspondente Bradesco
				oPrn:Say( 1265, 1800, "3114-3"+'/'+"0176300-8",oFont01,100 )
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+" "+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )   //Vencimento do Titulo
				oPrn:Say( 1410, 1800, "09/"+Substr(DTOS(SE1->E1_EMISSAO),3,2)+StrZero(Val(cNossoNum),8)+cDigVer+"-"+cDcb, oFont01,100  )
				// Adicionado em 29/08/2011
			ElseIf cBanco == "422" // Banco Safra
				oPrn:Say( 1265, 1800, cAgencia+"/"+Substr(cCedente,1,8)+"-"+Substr(cCedente,9,1)	,oFont01,100 )		// Agência/Código do Cedente
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+" "+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100 )  	// Nº Documento
				oPrn:Say( 1410, 1800, StrZero(Val(cNossoNum),8)+"-"+cDigVer							,oFont01,100 )		// Nosso Número

			ElseIf cBanco == "033"
				oPrn:Say( 1265, 1800, Alltrim(SA6->A6_AGENCIA)+'/'+cCedente,oFont01,100 )   // Codigo do Cedente "0083-3/1007041"
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+" "+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )
				oPrn:Say( 1410, 1800, StrZero(Val(cNossoNum),7)+" "+cDigVer							,oFont01,100 )

			ElseIf cBanco == "320"
				oPrn:Say( 1265, 1800, Alltrim(SA6->A6_AGENCIA)+"-"+SA6->A6_DVAGE+'/'+AllTrim(SA6->A6_NUMCON)+"-"+SA6->A6_DVCTA,oFont01,100 )   // Codigo do Cedente "4150-5/0000320-4"
				// Exceção do Bic que imprimi somente o Numero e parcela pois na posição 111 a 120 é levada esta informação
				oPrn:Say( 1340, 1800, SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )
				oPrn:Say( 1410, 1800, cCarteira+"/"+cRadical+cMatricula+cNossoNum+"-"+cDigVer  		,oFont01,100 )

			ElseIf cBanco == "399"
				oPrn:Say( 1265, 1800, Alltrim(SA6->A6_AGENCIA)+" "+AllTrim(SA6->A6_NUMCON),oFont01,100 )   // Codigo do Cedente "0398 1234567"
				oPrn:Say( 1410, 1800, cNossoNum+cDigVer  							,oFont01,100 )

			Endif

			oPrn:Say( 1480, 1870, Iif(cBanco == "399","R$","")+Transform(nE1_Saldo,"@E 999,999.99") , oFont01,100  )   // Valor do Documento
			If nDescFin > 0
				oPrn:Say( 1550, 1870, Transform(nDescFin,"@E 999,999.99"), oFont01,100 ) // Valor do Desconto
			Endif

			If cBancoImp == "BOLPG"
				oPrn:Say(1545, 1870, Transform(nE1_Saldo,"@E 999,999.99"), oFont01,100 )
			Endif

			oPrn:Say( 1525, 0220, "Instruções "            	,oFont03,100  )

			// Impressão dinâmica
			For wI := 1 To Len(aInstrucoes)
				oPrn:Say( 1505+(wI*40), 0240, aInstrucoes[wI,1]				,aInstrucoes[wI,2],100  )
			Next wI

			/*oPrn:Say( 1545, 0240, cInstr05					,oFont06,100  )
			oPrn:Say( 1585, 0240, cInstr01               	,oFont06,100  )
			oPrn:Say( 1625, 0240, cInstr02               	,oFont06,100  )
			oPrn:Say( 1665, 0240, cInstr03               	,oFont06,100  )
			oPrn:Say( 1705, 0240, cInstr04               	,oFont03,100  )*/
			
			If cBanco <> "320"
				oPrn:Say( 1755, 0240, "Referente " + Alltrim(SE1->E1_TIPO) + " " + Alltrim(SE1->E1_SERIE) + "/" + SE1->E1_NUM  ,oFont06,100  )
			Endif
			
			oPrn:Say( 1525, 1730, "(-) Desconto/Abatimento "          ,oFont03,100  )
			oPrn:Say( 1595, 1730, "(-) Outras deduções "   ,oFont03,100  )
			oPrn:Say( 1665, 1730, "(+) Mora/Multa/Juros "  ,oFont03,100  )
			oPrn:Say( 1735, 1730, "(+) Outros Acrecimos "  ,oFont03,100  )
			oPrn:Say( 1805, 1730, "(=) Valor Cobrado "     ,oFont03,100  )
			
			If cBancoImp == "BOLPG"
				oPrn:Say(1845, 1870, Transform(0.00,"@E 999,999.99"),oFont01,100)
			Endif
			
			If cBanco = "237"
				oPrn:Say( 1815, 0220, "BRADESCO",oFont10,100)
				oPrn:Say( 1815, 1100, "237-2",oFont11,100)
				
			Elseif cBanco == "001"
				oPrn:Say( 1815, 0220, "BANCO DO BRASIL",oFont10,100)
				oPrn:Say( 1815, 1100, "001-9",oFont11,100)
				
			Elseif cBanco == "341"
				oPrn:Say( 1815, 0220, "Banco Itaú SA",oFont10,100)
				oPrn:Say( 1815, 1100, "341-7",oFont11,100)
				
			Elseif cBanco == "745"
				oPrn:Say( 1815, 0220, "CITIBANK",oFont10,100)
				oPrn:Say( 1815, 1100, "745-5",oFont11,100)
				
			ElseIf cBanco = "422" .And. cBancoImp == "SAFBR" // Usa correspondente Bradesco
				oPrn:Say( 1815, 0220, "BRADESCO",oFont10,100)
				oPrn:Say( 1815, 1100, "237-2",oFont11,100)
				// Adicionado em 29/08/2011
			ElseIf cBanco = "422" // Banco Safra
				oPrn:Say( 1815, 0220, "BANCO SAFRA SA",oFont10,100)
				oPrn:Say( 1815, 1100, "422-7",oFont11,100)
				
			ElseIf cBanco = "033"
				oPrn:Say( 1815, 0220, "SANTANDER",oFont10,100)
				oPrn:Say( 1815, 1100, "033-7",oFont11,100)
				// BicBanco 05/01/2012
			ElseIf cBanco = "320"
				oPrn:Say( 1815, 0220, "BRADESCO",oFont10,100)
				oPrn:Say( 1815, 1100, "237-2",oFont11,100)
				
			ElseIf cBanco = "399"
				oPrn:Say( 1815, 0220, "HSBC",oFont10,100)
				oPrn:Say( 1815, 1100, "399-9",oFont11,100)
			Endif
			oPrn:Say( 1900, 1800, "AUTENTICACAO MECANICA",oFont04,100  )
			oPrn:Say( 2000+nAjuste, 0100,Repli(".",390),oFont03,100  )
			
			oPrn:Box (2180+nAjuste, 0200, 3100+nAjuste, 2180)
			
			// Monta linhas horizontais
			oPrn:Line(2290+nAjuste, 0200, 2290+nAjuste, 2180)
			oPrn:Line(2360+nAjuste, 0200, 2360+nAjuste, 2180)
			oPrn:Line(2430+nAjuste, 0200, 2430+nAjuste, 2180)
			oPrn:Line(2500+nAjuste, 0200, 2500+nAjuste, 2180)
			oPrn:Line(2845+nAjuste, 0200, 2845+nAjuste, 2180)
			
			oPrn:Line(2570+nAjuste, 1720, 2570+nAjuste, 2180)
			oPrn:Line(2640+nAjuste, 1720, 2640+nAjuste, 2180)
			oPrn:Line(2710+nAjuste, 1720, 2710+nAjuste, 2180)
			oPrn:Line(2780+nAjuste, 1720, 2780+nAjuste, 2180)
			
			// Monta linha verticais
			//        lin   		col   lin   		col
			oPrn:Line(2100+nAjuste, 0550, 2180+nAjuste, 0550)
			oPrn:Line(2100+nAjuste, 0730, 2180+nAjuste, 0730)
			
			oPrn:Line(2180+nAjuste, 1720, 2845+nAjuste, 1720)
			
			If cBanco $ "033"
				oPrn:Line(2360+nAjuste, 0500, 2431+nAjuste, 0500)
				// Ajuste especifico BicBanco
			ElseIf cBanco $ "320"
				oPrn:Line(2431+nAjuste, 0430, 2501+nAjuste, 0430)
				oPrn:Line(2360+nAjuste, 0500, 2501+nAjuste, 0500)
			Else
				oPrn:Line(2360+nAjuste, 0500, 2501+nAjuste, 0500)
			Endif
			oPrn:Line(2360+nAjuste, 0900, 2501+nAjuste, 0900)
			oPrn:Line(2360+nAjuste, 1100, 2431+nAjuste, 1100)
			oPrn:Line(2360+nAjuste, 1400, 2501+nAjuste, 1400)
			oPrn:Line(2430+nAjuste, 0700, 2501+nAjuste, 0700)
			
			If cBanco == "237"
				oPrn:SayBitmap( 2060+nAjuste, 090,cBMapABN,600,150 )
				oPrn:Say( 2105+nAjuste, 0560, "237-2"                  ,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   ,oFont09,150)
				//			oPrn:Say( 2320+nAjuste, 1800, Substr(ALLTRIM(SA6->A6_AGENCIA),1,4)+"-"+Substr(ALLTRIM(SA6->A6_AGENCIA),5,1)+'/'+subs(SA6->A6_NUMCON,1,7)+"-"+subs(SA6->A6_NUMCON,8,1) ,oFont01,100 )   //Codigo do Cedente "2232-/0004778-3"
				oPrn:Say( 2320+nAjuste, 1800, cAgImpBol+'/'+subs(SA6->A6_NUMCON,1,7)+"-"+subs(SA6->A6_NUMCON,8,1) ,oFont01,100 )   //Codigo do Cedente "2232-/0004778-3"
				oPrn:Say( 2390+nAjuste, 1800, cCarteira+"/"+cNossoNum+"-"+cDigVer            , oFont01,100  )
				oPrn:Say( 2460+nAjuste, 0560, cCarteira                       , oFont01,100  )   //Carteira
			ElseIf cBanco == "246"
				oPrn:SayBitmap( 2080+nAjuste, 0200,cBMapABN,90,90 )
				oPrn:Say( 2105+nAjuste, 0560, "246-1"                  ,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   ,oFont09,150)
				
				oPrn:Say( 2320+nAjuste, 1800, cAgImpBol+'/'+SA6->A6_NUMCON							,oFont01,100 )   	// Agencia/Codigo Cedente  00019/002206596
				oPrn:Say( 2390+nAjuste, 1800, cCarteira+"/"+cNossoNum+"-"+cDigVer     				,oFont01,100  )		// Nosso numero 00019/110/0010679556-D
				oPrn:Say( 2460+nAjuste, 0320, SEE->EE_CODEMP                  						,oFont01,100  )   	// Uso do Banco
				oPrn:Say( 2460+nAjuste, 0560, cCarteira      	            						,oFont01,100  )   	// Carteira				
				
			ElseIf cBanco == "001"
				oPrn:SayBitmap( 2060+nAjuste, 0210,cBMapABN,300,150 )
				oPrn:Say( 2105+nAjuste, 0560, "001-9"                  ,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   ,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1730, ALLTRIM(SA6->A6_AGENCIA)+"-7"+'/'+"0000000"+subs(SA6->A6_NUMCON,1,5)+"-"+subs(SA6->A6_NUMCON,6,1), oFont01,100  )   //Codigo do Cedente "2232-2/0004778-3"
				oPrn:Say( 2390+nAjuste, 1730, Substr(SEE->EE_CODEMP,1,7)+cNossoNum         , oFont01,100  )
				oPrn:Say( 2460+nAjuste, 0560, "17-019"                       , oFont01,100  )   //Carteira
				
			Elseif cBanco == "341"
				oPrn:SayBitmap( 2060+nAjuste, 0220,cBMapABN,95,95)
				oPrn:Say( 2105+nAjuste, 0320, "Banco Itaú SA",oFont06,100)
				oPrn:Say( 2105+nAjuste, 0560, "341-7"                  ,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   ,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, ALLTRIM(SA6->A6_AGENCIA)+'/'+subs(SA6->A6_NUMCON,1,5)+"-"+subs(SA6->A6_NUMCON,6,1), oFont01,100  )   //Codigo do Cedente "2232-2/0004778-3"
				oPrn:Say( 2390+nAjuste, 1800, /*If(SM0->M0_CODIGO == "01","109",)+*/"109 /"+cNossoNum+"-"+cDigVer            , oFont01,100  )
				oPrn:Say( 2460+nAjuste, 0560, /*If(SM0->M0_CODIGO == "01","109",)*/"109" , oFont01,100  )   //Carteira
				
			Elseif cBanco == "745"
				oPrn:SayBitmap( 2060+nAjuste, 0220,cBMapABN,232,71)
				oPrn:Say( 2105+nAjuste, 0560, "745-5"                  ,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   ,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, ALLTRIM(SA6->A6_AGENCIA)+'/'+U_CITIBANK("BOL",,11), oFont01,100  )   //Codigo do Cedente "2232-2/0004778-3"
				oPrn:Say( 2390+nAjuste, 1800, cNossoNum+"."+cDigVer            , oFont01,100  )
				oPrn:Say( 2460+nAjuste, 0560, U_CITIBANK("BOL",,10) , oFont01,100  )   //Carteira
			ElseIf cBanco == "422" .And. cBancoImp == "SAFBR" // Usa correspondente Bradesco
				oPrn:SayBitmap( 2060+nAjuste, 0220,cBMapABN,300,150 )
				oPrn:Say( 2105+nAjuste, 0560, "237-2"                  	,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   	,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, "3114-3"+'/'+"0176300-8"	, oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1800, "09/"+Substr(DTOS(SE1->E1_EMISSAO),3,2)+StrZero(Val(cNossoNum),8)+cDigVer+"-"+cDcb, oFont01,100   )
				oPrn:Say( 2460+nAjuste, 0220, "CIP130 "             		, oFont01,100  )   //Uso do Banco
				oPrn:Say( 2460+nAjuste, 0560, "09"                       , oFont01,100  )   //Carteira
				// Adicionado em 29/08/2011
			ElseIf cBanco == "422" // Banco Safra
				
				oPrn:Say( 2105+nAjuste, 0220, "BANCO SAFRA SA",oFont01,100)
				oPrn:Say( 2105+nAjuste, 0560, "422-7"                  										,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   										,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, cAgencia+"/"+Substr(cCedente,1,8)+"-"+Substr(cCedente,9,1)	,oFont01,100)	// Agência/Código do Cedente
				oPrn:Say( 2390+nAjuste, 1800, StrZero(Val(cNossoNum),8)+"-"+cDigVer							,oFont01,100)	// Nosso Número
				oPrn:Say( 2460+nAjuste, 0560, cCarteira                       								,oFont01,100)   //Carteira
			ElseIf cBanco == "033"
				oPrn:SayBitmap( 2090+nAjuste, 0200,cBMapABN,300,85 )
				oPrn:Say( 2105+nAjuste, 0560, "033-7"                  	,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   	,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, Alltrim(SA6->A6_AGENCIA)+'/'+cCedente, oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1800, StrZero(Val(cNossoNum),7)+" "+cDigVer, oFont01,100   )
				oPrn:Say( 2460+nAjuste, 0220, cCarteira         		, oFont01,100  )   //Uso do Banco
				
			ElseIf cBanco = "320"
				oPrn:SayBitmap( 2090+nAjuste, 0200,cBMapABN,300,85 )
				oPrn:Say( 2105+nAjuste, 0560, "237-2"                  	,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   	,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, Alltrim(SA6->A6_AGENCIA)+"-"+SA6->A6_DVAGE+'/'+AllTrim(SA6->A6_NUMCON)+"-"+SA6->A6_DVCTA , oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1800, cCarteira+"/"+cRadical+cMatricula+cNossoNum+"-"+cDigVer, oFont01,100   )
				oPrn:Say( 2460+nAjuste, 0220, "EXPRESSA"           		, oFont01,100  )   //Uso do Banco
				oPrn:Say( 2460+nAjuste, 0440, "521"           		, oFont01,100  )   //Uso do Banco
				oPrn:Say( 2460+nAjuste, 0560, cCarteira            		,oFont01,100)   //Carteira
				
			ElseIf cBanco = "399"
				oPrn:SayBitmap( 2090+nAjuste, 0200,cBMapABN,300,85 )
				oPrn:Say( 2105+nAjuste, 0560, "399-9"                  	,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   	,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, Alltrim(SA6->A6_AGENCIA)+" "+AllTrim(SA6->A6_NUMCON) , oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1800, cNossoNum+cDigVer			, oFont01,100   )
				oPrn:Say( 2460+nAjuste, 0220, ""  			         		, oFont01,100  )   //Uso do Banco
				oPrn:Say( 2460+nAjuste, 0440, "" 		   	       		, oFont01,100  )   //Uso do Banco
				oPrn:Say( 2460+nAjuste, 0560, "CSB"	            		,oFont01,100)   //Carteira

			ElseIf cBancoImp == "BOLPG"
				oPrn:Say( 2105+nAjuste, 0745, "TÍTULO QUITADO"       ,oFont09,150)
				
			Endif
			
			
			oPrn:Say( 2185+nAjuste, 0220, "Local de Pagamento "       ,oFont03,100  )
			oPrn:Say( 2185+nAjuste, 1730, "Vencimento "               ,oFont03,100  )
			If cBancoImp = "ABC"
				oPrn:Say( 2235+nAjuste, 0240, "Pagável preferencialmente nas agências do bradesco ",oFont07,100  )   //Cedente
			ElseIf cBancoImp = "HSBC"
				oPrn:Say( 2235+nAjuste, 0240, "Pagar em qualquer agência bancária até o vencimento ou canais eletrônicos do HSBC",oFont07,100  )   //Cedente
			Else
				If cBancoImp == "BOLPG"
					oPrn:Say( 2235+nAjuste, 0240 , SM0->M0_NOMECOM,oFont07,100 )
				Else
					If cBancoImp $ "ITAU3#ITAU5"
						oPrn:Say( 2235+nAjuste, 0240, "Até o vencimento pague preferencialmente no Itaú;Após o vencimento pague somente no Itaú",oFont06,100)
					Else
						oPrn:Say( 2235+nAjuste, 0240, "Pagável em qualquer banco até o vencimento ",oFont07,100  )   //Cedente
					Endif
				Endif
			Endif
			If cVencAjust == "Não"
				oPrn:Say( 2235+nAjuste, 1900, DTOC(SE1->E1_VENCREA)         ,oFont07,100  )   //Vencimento do Titulo
			Else
				oPrn:Say( 2235+nAjuste, 1900, DTOC(dDataReimp)             	,oFont07,100  )   //Vencimento do Titulo
			Endif
			If cBancoImp $ "ITAU" //"ITAU3#ITAU5#HSBC"
				oPrn:Say( 2295+nAjuste, 0220, "Beneficiário"				,oFont03,100 )
				oPrn:Say( 2295+nAjuste, 1730, "Codigo Beneficiário"			,oFont03,100 )
			ElseIf cBancoImp == "SAFRA"
				oPrn:Say( 2295+nAjuste, 0220, "Beneficiário"				,oFont03,100 )
				oPrn:Say( 2295+nAjuste, 1730, "Agência/Código Beneficiário"	,oFont03,100 )
			ElseIf cBancoImp == "HSBC"
				oPrn:Say( 2295+nAjuste, 0220, "Cedente"					,oFont03,100 )
				oPrn:Say( 2295+nAjuste, 1730, "Agência/Código Cedente"	,oFont03,100 )
			Else
				oPrn:Say( 2295+nAjuste, 0220, "Cedente "               ,oFont03,100  )
				oPrn:Say( 2295+nAjuste, 1730, "Codigo Cedente "        ,oFont03,100  )
			Endif		
			
			If cBancoImp == "VOTOR"
				oPrn:Say( 2320+nAjuste, 0240, "BANCO VOTORANTIM S.A",oFont01,100  )   	//Cedente
			ElseIf cBancoImp == "SAFBR"
				oPrn:Say( 2320+nAjuste, 0240, "BANCO SAFRA S.A",oFont01,100  )   		//Cedente
			ElseIf cBancoImp == "BICBANCO"
				oPrn:Say( 2320+nAjuste, 0240, "BCO INDL E COML S/A - BICBANCO - 07.450.604/0001-89",oFont01,100  )   		//Cedente
			ElseIf cBancoImp == "HSBC"
				oPrn:Say( 2320+nAjuste, 0240, Alltrim(SM0->M0_NOMECOM) +" "+ Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"),oFont01,100  )   			//Cedente			
			Else
				oPrn:Say( 2320+nAjuste, 0240, SM0->M0_NOMECOM,oFont01,100  )   			//Cedente
			Endif
			
			oPrn:Say( 2365+nAjuste, 0220, "Data Documento "        ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 0510, "Nº. Documento "         ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 0910, "Espécie Doc. "          ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 1110, "Aceite "                ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 1410, "Data do Processamento " ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 1730, "Nosso Número "          ,oFont03,100  )
			
			oPrn:Say( 2390+nAjuste, 0240, DTOC(SE1->E1_EMISSAO)       , oFont01,100  )
			If cBanco == "320"
				oPrn:Say( 2390+nAjuste, 0530, SE1->E1_NUM+" "+SE1->E1_PARCELA , oFont01,100  )
				// Exceção do Bic que imprimi somente o Numero e parcela pois na posição 111 a 120 é levada esta informação
			Else
				oPrn:Say( 2390+nAjuste, 0530, SE1->E1_PREFIXO+SE1->E1_NUM+" "+SE1->E1_PARCELA , oFont01,100  )
			Endif
			oPrn:Say( 2390+nAjuste, 1440, DTOC(DDATABASE)        	    	, oFont01,100  )
			If cBanco == "745"
				oPrn:Say( 2390+nAjuste, 0970, "DMI"           	        	, oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1230, "N"                        	, oFont01,100  )
			ElseIf cBanco == "399"
				oPrn:Say( 2390+nAjuste, 0970, "PD"       		            	, oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1230, "NÃO"  	                   	, oFont01,100  )			
			Else
				oPrn:Say( 2390+nAjuste, 0970, "DM"                    		, oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1230, "N"                       	, oFont01,100  )			
			Endif
			
			
			// Ajuste especifico para impressao de boletos Santander
			If cBanco == "033"
				oPrn:Say( 2435+nAjuste, 0220, "Carteira"           ,oFont03,100  )
				// Ajuste especifico Boleto BicBanco
			ElseIf cBanco == "320"
				oPrn:Say( 2435+nAjuste, 0220, "Uso do Banco "      ,oFont03,100  )
				oPrn:Say( 2435+nAjuste, 0460, "CIP"                ,oFont03,100  )
				oPrn:Say( 2435+nAjuste, 0510, "Carteira "          ,oFont03,100  )
			Else
				oPrn:Say( 2435+nAjuste, 0220, "Uso do Banco "      ,oFont03,100  )
				oPrn:Say( 2435+nAjuste, 0510, "Carteira "          ,oFont03,100  )
			Endif
			oPrn:Say( 2435+nAjuste, 0710, "Especie "               ,oFont03,100  )
			oPrn:Say( 2435+nAjuste, 0910, "Quantidade "            ,oFont03,100  )
			oPrn:Say( 2435+nAjuste, 1410, "Valor "                 ,oFont03,100  )
			oPrn:Say( 2435+nAjuste, 1730, "Valor do Documento "    ,oFont03,100  )
			
			oPrn:Say( 2460+nAjuste, 0770, Iif(cBanco == "399","REAL","R$") , oFont01,100  )
			oPrn:Say( 2460+nAjuste, 1870, Iif(cBanco == "399","R$","")+Transform(nE1_Saldo,"@E 999,999.99") , oFont01,100  )
			
			oPrn:Say( 2505+nAjuste, 0220, "Instruções "            ,oFont03,100  )
			oPrn:Say( 2505+nAjuste, 1730, "(-) Desconto "          ,oFont03,100  )
			
			If nDescFin > 0
				oPrn:Say( 2530+nAjuste, 1870, Transform(nDescFin,"@E 999,999.99"), oFont01,100 ) // Valor do Desconto
			Endif
			
			If cBancoImp == "BOLPG"
				oPrn:Say(2530+nAjuste, 1870, Transform(nE1_Saldo,"@E 999,999.99"), oFont01,100 )
			Endif
			For wI := 1 To Len(aInstrucoes)
				oPrn:Say( 2495+(wI*40)+nAjuste, 0240, aInstrucoes[wI,1]				,aInstrucoes[wI,2],100  )
			Next wI 
			/*
			oPrn:Say( 2535+nAjuste, 0240, cInstr05               ,oFont06,100  )
			oPrn:Say( 2575+nAjuste, 0240, cInstr01               ,oFont06,100  )
			oPrn:Say( 2615+nAjuste, 0240, cInstr02               ,oFont06,100  )
			oPrn:Say( 2655+nAjuste, 0240, cInstr03               ,oFont06,100  )
			oPrn:Say( 2695+nAjuste, 0240, cInstr04               ,oFont03,100  )
			*/
			If cBancoImp = "VOTOR"
				oPrn:Say( 2740+nAjuste, 0240,"Titulo entregue em cessão fiduciária em favor do cedente acima"  ,oFont08,100 )
			Elseif cBancoImp $ "ABC#BCABC"
				oPrn:Say( 2740+nAjuste, 0240,"Título transferido ao Banco ABC Brasil S/A"  ,oFont08,100 )
			ElseIf cBancoImp = "BICBANCO"
				// Comentado pois somente era necessa´rio na homologação
				//	oPrn:Say( 2710+nAjuste, 0240,"Título cedido Fiduciariamente, não pagar diretamente a ",oFont06,100 )
				oPrn:Say( 2740+nAjuste, 0240,SM0->M0_NOMECOM,oFont06,100 )
				oPrn:Say (2775+nAjuste, 0240, ALLTRIM(SM0->M0_ENDENT)+'  Bairro: '+ALLTRIM(SM0->M0_BAIRENT)+'  '+ALLTRIM(SM0->M0_CIDENT)+' - ';
					+ALLTRIM(SM0->M0_ESTENT)+'  CEP: '+ALLTRIM(SM0->M0_CEPENT),oFont03,100)
				oPrn:Say (2810+nAjuste, 0240,'CNPJ: '+SUBS(SM0->M0_CGC,1,2)+"."+SUBS(SM0->M0_CGC,3,3)+"."+SUBS(SM0->M0_CGC,6,3)+"/"+SUBS(SM0->M0_CGC,9,4)+"-"+SUBS(SM0->M0_CGC,13,2),oFont03,100)
			Endif

			If cBanco == "745"
				// Montagem do calculo do CRBV (Codigo de Recebimento de boleto Vencido)
				cVs		:= StrZero(nE1_Saldo*100,10)	// V1V2V3V4V5V6V7V8V9V10
				cFs		:= StrZero(nFatorVen,4)				// F1F2F3F4
				cJs		:= StrZero(Round(SE1->E1_VALJUR /nE1_Saldo * 30 * 100,2)*100,4) 	// J1J2J3J4
				cDs		:= U_CITIBANK("BOL",,14)			// D1D2
				cMs		:= "0000"							// M1M2M3M4
				cIs		:= "00"								// I1I2
				cEs		:= U_CITIBANK("BOL",,13)			// E1E2

				cCRBV1 := cEs            					// E1E2
				cCRBV1 += Substr(cVs,1,2)					// V1V2
				cCRBV1 += Substr(cFs,1,2)					// F1F2
				cCRBV1 += Substr(cJs,1,1)					// J1
				cCRBV1 += st745_DV(cCRBV1,0)				// X1 Digito verificador modulo 11

				cCRBV2 := Substr(cJs,2,1)					// J2
				cCRBV2 += Substr(cVs,3,2)					// V3V4
				cCRBV2 += Substr(cIs,1,2)					// I1I2
				cCRBV2 += Substr(cDs,1,2)					// D1D2
				cCRBV2 += st745_DV(cCRBV2,0)				// X2 Digito Verificador modulo 11

				cCRBV3 := Substr(cVs,5,2)					// V5V6
				cCRBV3 += Substr(cVs,3,2)					// M1M2
				cCRBV3 += Substr(cJs,3,2)					// J3J4
				cCRBV3 += Substr(cVs,7,1)					// V7
				cCRBV3 += st745_DV(cCRBV3,0)				// X3 Digito Verificador modulo 11

				cCRBV4 := Substr(cVs,8,1)					// V8
				cCRBV4 += Substr(cFs,3,2)					// F3F4
				cCRBV4 += Substr(cMs,3,2)					// I1I2
				cCRBV4 += Substr(cVs,9,2)					// V9V10
				cCRBV4 += st745_DV(cCRBV4,0)				// X4 Digito Verificador modulo 11

				oPrn:Say( 2740+nAjuste,240 ,"Após vencimento acesse www.citibank.com.br/boletos e obtenha o boleto pagável em qualquer banco",oFont04,100  )
				oPrn:Say( 2800+nAjuste,600 ,"CRBV: "+ cCRBV1+cCRBV2+cCRBV3+cCRBV4,oFont06,100  )

			Endif

			If cBanco <> "320"
				oPrn:Say( 2800+nAjuste, 0240, "Referente " + Alltrim(SE1->E1_TIPO) + " " + Alltrim(SE1->E1_SERIE) + "/" + SE1->E1_NUM  ,oFont06,100  )
			Endif
			If cBancoImp == "BOLPG"
				oPrn:Say(2800+nAjuste, 1870, Transform(0.00,"@E 999,999.99"),oFont01,100)
			Endif
			oPrn:Say( 2575+nAjuste, 1730, "(-) Outras deduções "   ,oFont03,100  )
			oPrn:Say( 2645+nAjuste, 1730, "(+) Mora/Multa/Juros "  ,oFont03,100  )
			oPrn:Say( 2715+nAjuste, 1730, "(+) Outros Acrecimos "  ,oFont03,100  )
			oPrn:Say( 2785+nAjuste, 1730, "(=) Valor Cobrado "     ,oFont03,100  )

			If cBancoImp $ "ITAU" //"ITAU3#ITAU5#HSBC"
				oPrn:Say( 2845+nAjuste, 0220, "Pagador", 					oFont03,100 )
			ElseIf cBancoImp $ "SAFRA"
				oPrn:Say( 2845+nAjuste, 0220, "Pagador", 					oFont03,100 )
			Else
				oPrn:Say( 2845+nAjuste, 0220, "Sacado"                 ,oFont03,100  )
			Endif
			oPrn:Say( 2870+nAjuste, 0240, SE1->E1_CLIENTE + " - " + ALLTRIM(cNome) , oFont01,100  )

			If !Empty(SA1->A1_CEPC)
				oPrn:Say( 2910+nAjuste, 0280, ALLTRIM(SA1->A1_ENDCOB), oFont01,100  )
				oPrn:Say( 2950+nAjuste, 0280, substr(SA1->A1_CEPC,1,5)+"-"+substr(SA1->A1_CEPC,6,3)+"  "+ALLTRIM(SA1->A1_BAIRROC)+" - "+ALLTRIM(SA1->A1_MUNC)+"   "+SA1->A1_ESTC, oFont01,100  )
			Else
				oPrn:Say( 2910+nAjuste, 0280, ALLTRIM(SA1->A1_END), oFont01,100  )
				oPrn:Say( 2950+nAjuste, 0280, substr(SA1->A1_CEP,1,5)+"-"+substr(SA1->A1_CEP,6,3)+"  "+ALLTRIM(SA1->A1_BAIRRO)+" - "+ALLTRIM(SA1->A1_MUN)+"   "+SA1->A1_EST, oFont01,100  )
			Endif

			If SA1->A1_PESSOA == "J"
				oPrn:Say( 2990+nAjuste, 0280, "CNPJ: "+SUBS(SA1->A1_CGC,1,2)+"."+SUBS(SA1->A1_CGC,3,3)+"."+SUBS(SA1->A1_CGC,6,3)+"/"+SUBS(SA1->A1_CGC,9,4)+"-"+SUBS(SA1->A1_CGC,13,2), oFont01,100  )
			Else
				oPrn:Say( 2990+nAjuste, 0280, "CPF: "+SUBS(SA1->A1_CGC,1,3)+"."+SUBS(SA1->A1_CGC,4,3)+"."+SUBS(SA1->A1_CGC,7,3)+"-"+SUBS(SA1->A1_CGC,10,2), oFont01,100  )
			Endif
			If cBancoImp = "VOTOR"
				oPrn:Say( 3050+nAjuste, 0240, "SACADOR/AVALISTA: "+SM0->M0_NOMECOM+" -- CNPJ: 82.656.463/0001-70" ,oFont06,100  )
			Endif
			If cBancoimp == "SAFBR"
				oPrn:Say( 3050+nAjuste, 0240, "SACADOR/AVALISTA: "+SM0->M0_NOMECOM+" -- CNPJ: "+Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")  ,oFont06,100  )
			Endif
			If cBancoimp =="SAFRA"
				oPrn:Say( 3050+nAjuste, 0240, "SACADOR/AVALISTA: "+Space(Len(SM0->M0_NOMECOM))+" -- CNPJ: "+Space(18)  ,oFont06,100  )
			Endif

			If cBancoimp =="BICBANCO"
				oPrn:Say( 3050+nAjuste, 0240, "SACADOR/AVALISTA: "+Alltrim(SM0->M0_NOMECOM)+" CNPJ: "+Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")  ,oFont06,100  )
			Endif

			oPrn:Say( 3110+nAjuste, 1800, "AUTENTICACAO MECANICA",oFont04,100  )
			oPrn:Say( 3140+nAjuste, 1750, "FICHA DE COMPENSAÇÃO",oFont05,100  )


			//colocacao do codigo de barras incorreto
			If cBancoImp <> "BOLPG"
				If cLocImp =="F"
					MSBAR("INT25",27.7,2.10,AllTrim(cBarraFim),oPrn,.F.,NIL,.T.,NIL,NIL,NIL,oFont02,NIL,.F.)//rafael
				Else
					MSBAR("INT25",14.2,1.3,AllTrim(cBarraFim),oPrn,.F.,NIL,.T.,0.011,1,.F.,oFont02,NIL,.F.)//rafael
				Endif
			Else
				//        lin   col   lin   col
				oPrn:Line(1900, 0200, 0090, 2180)
				oPrn:Line(3100+nAjuste, 0200, 2180+nAjuste, 2180)

			Endif
			oPrn:EndPage()
		Endif

	Next nForA

	// Libera só depois de imprimir todos os boletos
	sfChekLock(.F.,cBancoImp)

	//cFileHtml := "\treport\boleto.htm"
	//oPrn:SaveAsHTML( cFileHtml )

	If Type("lFirstDF") == "L"
		oPrn:Print()
	Else
		oPrn:Preview()
		MS_Flush()
	Endif



Return


/*/{Protheus.doc} sf237Bar
(Cria linha digitável )
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return logico
@example
(examples)
@see (links_or_references)
/*/
Static Function sf237Bar()      // BRADESCO

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Primeiro Campo.                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cLinha:=""
	nDigito:=0

	// banco+moeda+(nosso numero,1,5)
	cCampo	:=	SE1->E1_PORTADO+if(SE1->E1_MOEDA==1,'9','0')+SUBS(cBarra,19,5)
	sf237Dig1()

	cLinha:=cLinha+SE1->E1_PORTADO+If(SE1->E1_MOEDA==1,'9','0')+Subs(cBarra,19,1)+"."+Subs(cBarra,20,4)+Str(nDigito,1)+Space(2)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Segundo Campo.                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCampo:=subs(cBarra,24,10)
	sf237Dig2()
	cLinha:=cLinha+Subs(cBarra,24,5)+"."+Subs(cBarra,29,1)+Subs(cBarra,30,1)+Subs(cBarra,31,3)+Str(nDigito,1)+Space(2)


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Terceiro Campo.                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCampo:=Subs(cBarra,34,5)+Subs(cBarra,39,5)
	sf237Dig3()
	cLinha:=cLinha+Subs(cBarra,34,5)+'.'+Subs(cBarra,39,5)+Str(nDigito,1)+Space(2)
	//cLinha:=cLinha+Subs(cBarra,34,5)+'.'+Subs(cBarra,39,1)+Subs(cBarra,40,1)+Subs(cBarra,41,3)+Str(nDigito,1)+Space(2)
	//cLinha:=cLinha+cCampo+Space(2)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Quarto Campo.                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Val(Subs(cBarra,05,4))==0 .OR. SE1->E1_MOEDA != 1
		cCampo:="0000"+Strzero(Val(Subs(cBarra,09,10)),10)
	Else
		cCampo:=Str(Val(Subs(cBarra,05,14)),14)
	Endif
	cLinha:=cLinha+subs(cBarraFim,5,1)+" "+cCampo
	li := 0
Return(.T.)


/*/{Protheus.doc} sf001Bar
(Cria linha digitável)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return logico
@example
(examples)
@see (links_or_references)
/*/
Static Function sf001Bar()  // Banco do Brasil

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Primeiro Campo.                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cLinha:=""
	nDigito:=0

	// banco+moeda+(nosso numero,1,5)
	cCampo:=Substr(cBarrafim,1,4)+SUBS(cBarra,19,5)
	sf237Dig1()

	cLinha:=Substr(cBarrafim,1,4)+Substr(cBarrafim,20,1)+"."+Subs(cBarrafim,21,4)+Str(nDigito,1)+Space(2)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Segundo Campo.                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCampo:=subs(cBarra,24,10)
	sf237Dig2()
	cLinha:=cLinha+Subs(cBarrafim,25,5)+"."+Subs(cBarrafim,30,5)+Str(nDigito,1)+Space(2)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Terceiro Campo.                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCampo:=Subs(cBarra,34,5)+Subs(cBarra,39,5)
	sf237Dig3()
	cLinha:=cLinha+Subs(cBarrafim,35,5)+'.'+Subs(cBarrafim,40,5)+Str(nDigito,1)+Space(2)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Quarto Campo.                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Val(Subs(cBarra,05,4))==0 .OR. SE1->E1_MOEDA != 1
		cCampo:="0000"+Strzero(Val(Subs(cBarra,09,10)),10)
	Else
		cCampo:=Str(Val(Subs(cBarra,05,14)),14)
	Endif
	cLinha:=cLinha+subs(cBarraFim,5,1)+" "+cCampo
	li := 0
Return(.T.)


/*/{Protheus.doc} sf237Dig1
(Calcula digito verificador 1 da linha digitável)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return logico, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sf237Dig1()

	nCont:=0
	nDv1:=val(subs(cCampo, 1,1)) * 2
	nDv2:=val(subs(cCampo, 2,1)) * 1
	nDv3:=val(subs(cCampo, 3,1)) * 2
	nDv4:=val(subs(cCampo, 4,1)) * 1
	nDv5:=val(subs(cCampo, 5,1)) * 2
	nDv6:=val(subs(cCampo, 6,1)) * 1
	nDv7:=val(subs(cCampo, 7,1)) * 2
	nDv8:=val(subs(cCampo, 8,1)) * 1
	nDv9:=val(subs(cCampo, 9,1)) * 2

	ncont:=iif(nDv1 >=10,Val(subs(str(nDv1,2),1,1))+Val(subs(str(ndv1,2),2,1)),nDv1)+nDv2+;
		iif(nDv3 >=10,Val(subs(str(nDv3,2),1,1))+Val(subs(str(ndv3,2),2,1)),nDv3)+nDv4+;
		iif(nDv5 >=10,Val(subs(str(nDv5,2),1,1))+Val(subs(str(ndv5,2),2,1)),nDv5)+nDv6+;
		iif(nDv7 >=10,Val(subs(str(nDv7,2),1,1))+Val(subs(str(ndv7,2),2,1)),nDv7)+nDv8+;
		iif(nDv9 >=10,Val(subs(str(nDv9,2),1,1))+Val(subs(str(ndv9,2),2,1)),nDv9)

	nResto:=Mod(nCont,10)

	nDigito:= 10 - nResto

	if nDigito == 10
		nDigito := 0
	endif

Return(.t.)


/*/{Protheus.doc} sf237Dig2
(Calcula digito verificador 2 da linha digitável)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return logico, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sf237Dig2()
	nCont:=0
	nDv1:=val(subs(cCampo, 1,1)) * 1
	nDv2:=val(subs(cCampo, 2,1)) * 2
	nDv3:=val(subs(cCampo, 3,1)) * 1
	nDv4:=val(subs(cCampo, 4,1)) * 2
	nDv5:=val(subs(cCampo, 5,1)) * 1
	nDv6:=val(subs(cCampo, 6,1)) * 2
	nDv7:=val(subs(cCampo, 7,1)) * 1
	nDv8:=val(subs(cCampo, 8,1)) * 2
	nDv9:=val(subs(cCampo, 9,1)) * 1
	nDv0:=val(subs(cCampo,10,1)) * 2

	ncont:=nDv1+iif(nDv2 >=10,Val(subs(str(nDv2,2),1,1))+Val(subs(str(ndv2,2),2,1)),nDv2)+;
		nDv3+iif(nDv4 >=10,Val(subs(str(nDv4,2),1,1))+Val(subs(str(ndv4,2),2,1)),nDv4)+;
		nDv5+iif(nDv6 >=10,Val(subs(str(nDv6,2),1,1))+Val(subs(str(ndv6,2),2,1)),nDv6)+;
		nDv7+iif(nDv8 >=10,Val(subs(str(nDv8,2),1,1))+Val(subs(str(ndv8,2),2,1)),nDv8)+;
		nDv9+iif(nDv0 >=10,Val(subs(str(nDv0,2),1,1))+Val(subs(str(ndv0,2),2,1)),nDv0)

	nResto:=Mod(nCont,10)

	nDigito:= 10 - nResto

	if nDigito == 10
		nDigito := 0
	endif

Return(.t.)


/*/{Protheus.doc} sf237Dig3
(Cria digito verificador 3 da linha digitável)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return logico
@example
(examples)
@see (links_or_references)
/*/
Static Function sf237Dig3()
	nCont:=0
	nDv1:=val(subs(cCampo, 1,1)) * 1
	nDv2:=val(subs(cCampo, 2,1)) * 2
	nDv3:=val(subs(cCampo, 3,1)) * 1
	nDv4:=val(subs(cCampo, 4,1)) * 2
	nDv5:=val(subs(cCampo, 5,1)) * 1
	nDv6:=val(subs(cCampo, 6,1)) * 2
	nDv7:=val(subs(cCampo, 7,1)) * 1
	nDv8:=val(subs(cCampo, 8,1)) * 2
	nDv9:=val(subs(cCampo, 9,1)) * 1
	nDv0:=val(subs(cCampo,10,1)) * 2

	ncont:=nDv1+iif(nDv2 >=10,Val(subs(str(nDv2,2),1,1))+Val(subs(str(ndv2,2),2,1)),nDv2)+;
		nDv3+iif(nDv4 >=10,Val(subs(str(nDv4,2),1,1))+Val(subs(str(ndv4,2),2,1)),nDv4)+;
		nDv5+iif(nDv6 >=10,Val(subs(str(nDv6,2),1,1))+Val(subs(str(ndv6,2),2,1)),nDv6)+;
		nDv7+iif(nDv8 >=10,Val(subs(str(nDv8,2),1,1))+Val(subs(str(ndv8,2),2,1)),nDv8)+;
		nDv9+iif(nDv0 >=10,Val(subs(str(nDv0,2),1,1))+Val(subs(str(ndv0,2),2,1)),nDv0)

	nResto:=Mod(nCont,10)

	nDigito:= 10 - nResto

	if nDigito == 10
		nDigito := 0
	endif

Return(.t.)


/*/{Protheus.doc} sf237DAC
(Calcula digito de auto conferência para o código de barras)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sf237DAC()

	Private	nCont			:= 0
	Private	cBarraImp       := Substr(cBarra,1,43)

	nCont 	:= sf237Mod11()

	nResto := MOD(ncont,11)
	nDigitoImp := 11 - nResto

	if nResto <= 1 .or. nResto > 9
		nDigitoImp := 1
	EndIf

	cBarraFim := subs(cBarra,1,4) + strzero(nDigitoImp,1) + subs(cBarra,5,43)
Return



/*/{Protheus.doc} sf237Mod11
(Calculo módulo 11 para o DAC)
@author MarceloLauschner
@since 11/02/2015
@version 1.0
@return numerico
@example
(examples)
@see (links_or_references)
/*/
Static Function sf237Mod11()

	nCont   := 0.00
	nCont   := nCont+(Val(Subs(cBarraImp,43,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,42,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,41,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,40,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,39,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,38,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,37,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,36,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,35,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,34,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,33,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,32,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,31,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,30,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,29,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,28,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,27,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,26,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,25,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,24,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,23,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,22,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,21,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,20,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,19,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,18,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,17,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,16,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,15,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,14,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,13,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,12,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,11,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,10,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,09,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,08,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,07,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,06,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,05,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,04,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,03,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,02,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,01,1))*4)

Return nCont

//========================================================================
// CDIGITONOSS0
//========================================================================
Static Function sf237Dig()

	Local	cDvn := ""
	Local	nSoma1,nSoma2,nSoma3,nSoma4,nSoma5,nSoma6,nSoma7,nSoma8,nSoma9,nSoma10,nSoma11,nSoma12,nSoma13,nSomTot,nDigito

	If cBanco == "422"
		cNum1	:= cCarteira+Substr(DTOS(SE1->E1_EMISSAO),3,2)+StrZero(Val(cNossoNum),8)+cDigVer
	Else
		cNum1	:= cCarteira+Substr(cNossoNum,1,11)//+cAgencia+cNumConta
	Endif

	nSoma1 := val(subs(cNum1,1,1))*2
	nSoma2 := val(subs(cNum1,2,1))*7
	nSoma3 := val(subs(cNum1,3,1))*6
	nSoma4 := val(subs(cNum1,4,1))*5
	nSoma5 := val(subs(cNum1,5,1))*4
	nSoma6 := val(subs(cNum1,6,1))*3
	nSoma7 := val(subs(cNum1,7,1))*2
	nSoma8 := val(subs(cNum1,8,1))*7
	nSoma9 := val(subs(cNum1,9,1))*6
	nSoma10:= val(subs(cNum1,10,1))*5
	nSoma11:= val(subs(cNum1,11,1))*4
	nSoma12:= val(subs(cNum1,12,1))*3
	nSoma13:= val(subs(cNum1,13,1))*2

	nSomTot := nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8+nSoma9+nSoma10+nSoma11+nSoma12+nSoma13
	nDigito := Int(nSomtot/11)
	nDigito := nSomTot - (nDigito * 11)

	If nDigito == 0
		cDvn := "0"
	Else
		nDigito := 11 - nDigito
		cDvn    := Iif(nDigito == 10,"P",Substr(Str(nDigito,1),1,1))
	Endif

Return(cDvn)



/*/
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
	±±³Fun‡…o    ³ BOLLINDIG³ Autor ³ Marcelo B. Abe        ³ Data ³ 25.04.95 ³±±
	±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
	±±³Descri‡…o ³ Faz o Calculo da Linha Digitavel.                          ³±±
	±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
	±±³Uso       ³ BOLLINDIG                                                  ³±±
	±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
// Substituido pelo assistente de conversao do AP5 IDE em 01/08/00 ==> FUNCTION BOLLINDIG
Static Function sf341Bar()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Primeiro Campo.                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cLinha:=""
	nDigito:=0

	// banco+moeda+(nosso numero,1,5)
	cCampo:=SE1->E1_PORTADO+if(SE1->E1_MOEDA==1,'9','0')+Subs(cBarra,19,3)+Subs(cBarra,22,2)         //34191.0900
	sf341Dig1()
	cLinha:=cLinha+SE1->E1_PORTADO+If(SE1->E1_MOEDA==1,'9','0')+Subs(cBarra,19,1)+"."+Subs(cBarra,20,2)+Subs(cBarra,22,2)+;
		Str(nDigito,1)+Space(2)     //34191.09008

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Segundo Campo.                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCampo:=subs(cBarra,24,6)+subs(cBarra,30,1)+subs(cBarra,31,3)
	sf341Dig2()
	cLinha:=cLinha+Subs(cBarra,24,5)+"."+Subs(cBarra,29,1)+subs(cBarra,30,1)+subs(cBarra,31,3)+;   //09873.651294
	Str(nDigito,1)+Space(2)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Terceiro Campo.                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cCampo:=Subs(cBarra,34,1)+subs(cBarra,35,6)+subs(cBarra,41,3)
	sf341Dig3()
	cLinha:=cLinha+Subs(cBarra,34,1)+subs(cBarra,35,4)+'.'+Subs(cBarra,39,5)+Str(nDigito,1)+Space(2)  //31115.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Calculo do Quarto Campo.                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	// dv codigo barras + fator vencto + valor
	If cBanco # "341" .and. Val(Subs(cBarra,06,4))==0 .OR. SE1->E1_MOEDA != 1
		cCampo:="0000"+Strzero(Val(Subs(cBarra,10,10)),10)
	Else
		cCampo:=Str(Val(Subs(cBarra,5,14)),14)
	Endif
	cLinha:=cLinha+subs(cBarraFim,5,1)+" "+cCampo
	li := 0
Return(.T.)

//========================================================================
// DIGITO                                                              ³±±
//========================================================================
Static Function sf341Dig1()

	nCont:=0
	nDv1:=val(subs(cCampo, 1,1)) * 2
	nDv2:=val(subs(cCampo, 2,1)) * 1
	nDv3:=val(subs(cCampo, 3,1)) * 2
	nDv4:=val(subs(cCampo, 4,1)) * 1
	nDv5:=val(subs(cCampo, 5,1)) * 2
	nDv6:=val(subs(cCampo, 6,1)) * 1
	nDv7:=val(subs(cCampo, 7,1)) * 2
	nDv8:=val(subs(cCampo, 8,1)) * 1
	nDv9:=val(subs(cCampo, 9,1)) * 2

	ncont:=iif(nDv1 >=10,Val(subs(str(nDv1,2),1,1))+Val(subs(str(ndv1,2),2,1)),nDv1)+nDv2+;
		iif(nDv3 >=10,Val(subs(str(nDv3,2),1,1))+Val(subs(str(ndv3,2),2,1)),nDv3)+nDv4+;
		iif(nDv5 >=10,Val(subs(str(nDv5,2),1,1))+Val(subs(str(ndv5,2),2,1)),nDv5)+nDv6+;
		iif(nDv7 >=10,Val(subs(str(nDv7,2),1,1))+Val(subs(str(ndv7,2),2,1)),nDv7)+nDv8+;
		iif(nDv9 >=10,Val(subs(str(nDv9,2),1,1))+Val(subs(str(ndv9,2),2,1)),nDv9)

	nResto:=Mod(nCont,10)

	nDigito:= 10 - nResto

	if nDigito == 10
		nDigito := 0
	endif

Return(.t.)


Static Function sf341Dig2()
	nCont:=0
	nDv1:=val(subs(cCampo, 1,1)) * 1
	nDv2:=val(subs(cCampo, 2,1)) * 2
	nDv3:=val(subs(cCampo, 3,1)) * 1
	nDv4:=val(subs(cCampo, 4,1)) * 2
	nDv5:=val(subs(cCampo, 5,1)) * 1
	nDv6:=val(subs(cCampo, 6,1)) * 2
	nDv7:=val(subs(cCampo, 7,1)) * 1
	nDv8:=val(subs(cCampo, 8,1)) * 2
	nDv9:=val(subs(cCampo, 9,1)) * 1
	nDv0:=val(subs(cCampo,10,1)) * 2

	ncont:=nDv1+iif(nDv2 >=10,Val(subs(str(nDv2,2),1,1))+Val(subs(str(ndv2,2),2,1)),nDv2)+;
		nDv3+iif(nDv4 >=10,Val(subs(str(nDv4,2),1,1))+Val(subs(str(ndv4,2),2,1)),nDv4)+;
		nDv5+iif(nDv6 >=10,Val(subs(str(nDv6,2),1,1))+Val(subs(str(ndv6,2),2,1)),nDv6)+;
		nDv7+iif(nDv8 >=10,Val(subs(str(nDv8,2),1,1))+Val(subs(str(ndv8,2),2,1)),nDv8)+;
		nDv9+iif(nDv0 >=10,Val(subs(str(nDv0,2),1,1))+Val(subs(str(ndv0,2),2,1)),nDv0)

	nResto:=Mod(nCont,10)

	nDigito:= 10 - nResto

	if nDigito == 10
		nDigito := 0
	endif

Return(.t.)

Static Function sf341Dig3()
	nCont:=0
	nDv1:=val(subs(cCampo, 1,1)) * 1
	nDv2:=val(subs(cCampo, 2,1)) * 2
	nDv3:=val(subs(cCampo, 3,1)) * 1
	nDv4:=val(subs(cCampo, 4,1)) * 2
	nDv5:=val(subs(cCampo, 5,1)) * 1
	nDv6:=val(subs(cCampo, 6,1)) * 2
	nDv7:=val(subs(cCampo, 7,1)) * 1
	nDv8:=val(subs(cCampo, 8,1)) * 2
	nDv9:=val(subs(cCampo, 9,1)) * 1
	nDv0:=val(subs(cCampo,10,1)) * 2

	ncont:=nDv1+iif(nDv2 >=10,Val(subs(str(nDv2,2),1,1))+Val(subs(str(ndv2,2),2,1)),nDv2)+;
		nDv3+iif(nDv4 >=10,Val(subs(str(nDv4,2),1,1))+Val(subs(str(ndv4,2),2,1)),nDv4)+;
		nDv5+iif(nDv6 >=10,Val(subs(str(nDv6,2),1,1))+Val(subs(str(ndv6,2),2,1)),nDv6)+;
		nDv7+iif(nDv8 >=10,Val(subs(str(nDv8,2),1,1))+Val(subs(str(ndv8,2),2,1)),nDv8)+;
		nDv9+iif(nDv0 >=10,Val(subs(str(nDv0,2),1,1))+Val(subs(str(ndv0,2),2,1)),nDv0)

	nResto:=Mod(nCont,10)

	nDigito:= 10 - nResto

	if nDigito == 10
		nDigito := 0
	endif

Return(.t.)

//========================================================================
// CDIGITOCHAVE
//========================================================================
Static Function sf341DAC()
	******************************
	nCont			:= 0
	cBarraImp       := space(43)
	cBarraImp       := Subs(cBarra,1,43)

	sf341Mod11()

	nResto := MOD(ncont,11)
	nDigitoImp := 11 - nResto

	if nResto <= 1 .or. nResto > 9
		nDigitoImp := 1
	EndIf

	cBarraFim := subs(cBarra,1,4) + strzero(nDigitoImp,1) + subs(cBarra,5,43)
Return

//========================================================================
// CALCULAMODULO11
//========================================================================
Static Function sf341Mod11()

	nCont   := 0.00
	nCont   := nCont+(Val(Subs(cBarraImp,43,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,42,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,41,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,40,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,39,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,38,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,37,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,36,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,35,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,34,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,33,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,32,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,31,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,30,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,29,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,28,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,27,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,26,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,25,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,24,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,23,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,22,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,21,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,20,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,19,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,18,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,17,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,16,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,15,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,14,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,13,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,12,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,11,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,10,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,09,1))*4)
	nCont   := nCont+(Val(Subs(cBarraImp,08,1))*5)
	nCont   := nCont+(Val(Subs(cBarraImp,07,1))*6)
	nCont   := nCont+(Val(Subs(cBarraImp,06,1))*7)
	nCont   := nCont+(Val(Subs(cBarraImp,05,1))*8)
	nCont   := nCont+(Val(Subs(cBarraImp,04,1))*9)
	nCont   := nCont+(Val(Subs(cBarraImp,03,1))*2)
	nCont   := nCont+(Val(Subs(cBarraImp,02,1))*3)
	nCont   := nCont+(Val(Subs(cBarraImp,01,1))*4)

Return

//========================================================================
// CDIGITONOSS0
//========================================================================
Static Function sf341DV()
	Local nForA

	cDvn := ""

	cNumBco := Substr(SEE->EE_AGENCIA,1,4)+Substr(SEE->EE_CONTA,1,5)+"109"+cNossoNum
	nValsoma	:= 0
	nDig01 := Val(Substr(cNumBco,01,1))
	nDig02 := Val(Substr(cNumBco,02,1))
	nDig03 := Val(Substr(cNumBco,03,1))
	nDig04 := Val(Substr(cNumBco,04,1))
	nDig05 := Val(Substr(cNumBco,05,1))
	nDig06 := Val(Substr(cNumBco,06,1))
	nDig07 := Val(Substr(cNumBco,07,1))
	nDig08 := Val(Substr(cNumBco,08,1))
	nDig09 := Val(Substr(cNumBco,09,1))
	nDig10 := Val(Substr(cNumBco,10,1))
	nDig11 := Val(Substr(cNumBco,11,1))
	nDig12 := Val(Substr(cNumBco,12,1))
	nDig13 := Val(Substr(cNumBco,13,1))
	nDig14 := Val(Substr(cNumBco,14,1))
	nDig15 := Val(Substr(cNumBco,15,1))
	nDig16 := Val(Substr(cNumBco,16,1))
	nDig17 := Val(Substr(cNumBco,17,1))
	nDig18 := Val(Substr(cNumBco,18,1))
	nDig19 := Val(Substr(cNumBco,19,1))
	nDig20 := Val(Substr(cNumBco,20,1))

	nConta := AllTrim(Str(nDig01*1)) + AllTrim(Str(nDig02*2)) + AllTrim(Str(nDig03*1));
		+ AllTrim(Str(nDig04*2)) + AllTrim(Str(nDig05*1)) + AllTrim(Str(nDig06*2));
		+ AllTrim(Str(nDig07*1)) + AllTrim(Str(nDig08*2)) + AllTrim(Str(nDig09*1));
		+ AllTrim(Str(nDig10*2)) + AllTrim(Str(nDig11*1)) + AllTrim(Str(nDig12*2));
		+ AllTrim(Str(nDig13*1)) + AllTrim(Str(nDig14*2)) + AllTrim(Str(nDig15*1));
		+ AllTrim(Str(nDig16*2)) + AllTrim(Str(nDig17*1)) + AllTrim(Str(nDig18*2));
		+ AllTrim(Str(nDig19*1)) + AllTrim(Str(nDig20*2))

	For nForA := 1 To Len(nConta)
		nValsoma += Val(Substr(nConta,nForA,1))
	Next

	cDV  := Mod(nValsoma,10)
	If cDv == 0
		nDv := 0
	Else
		nDV  := 10 - cDV
	Endif
	cDvn := Substr(Str(nDv,1),1,1)

return(cDvn)





// Calcula digito verificador Modulo11 para Banco Citibank, tanto NossoNumero como CodigoBarra e tambem Safra
Static Function st745_DV(cInCod,nMod,nModBrad)
	// cInCod --> Pode ser 11 numeros do Nosso Numero ou 43 digitos do codigo Barra, ou CRBV
	// nMod	  --> 0=> Nosso Numero 1=> Codigo Barra

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo
	nSumDv	:= Mod(nSumDv,11)

	// Validacao para o Bradesco/Safra -> SE na divisao o resto for 0,10 ou 1 o DAC sera sempre 1
	If nModBrad <> Nil
		If nSumDv > 9
			nSumDev := nModBrad
		Endif
	Endif

	If nSumDv <= 1
		nSumDv := nMod
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)


// Calculo do digito verificador Modulo 10 da linha digitavel Banco Citibank / Safra
Static Function st745DvLD(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)
	Local   nResult	:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv
	Endif

Return StrZero(nSumDv,1)

//========================================================================
// CDIGITONOSS0 - BANCO SAFRA
//========================================================================
Static Function sf422Dig()

	Local	nDvnsf := 0
	Local	cNossoNum1	:= Substr(cNossoNum,1,8)
	Local	nSoma1 		:= Val(Substr(cNossoNum1,1,1))*9
	Local	nSoma2 		:= Val(Substr(cNossoNum1,2,1))*8
	Local	nSoma3 		:= Val(Substr(cNossoNum1,3,1))*7
	Local	nSoma4 		:= Val(Substr(cNossoNum1,4,1))*6
	Local	nSoma5 		:= Val(Substr(cNossoNum1,5,1))*5
	Local	nSoma6 		:= Val(Substr(cNossoNum1,6,1))*4
	Local	nSoma7 		:= Val(Substr(cNossoNum1,7,1))*3
	Local	nSoma8 		:= Val(Substr(cNossoNum1,8,1))*2

	Local 	nSomTot := nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8
	Local	nResto  := Int(nSomtot/11)

	nResto := nSomTot - (nResto * 11)

	If nResto == 0
		nDvnsf := 1
	Elseif nResto == 1
		nDvnsf := 0
	Else
		nDvnsf := 11 - nResto
	Endif

Return(Str(nDvnsf,1))


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/01/2011
// Nome função: sf033_DV
// Parametros : 1 - Codigo a calcular digito verificador
//				2 - Digito se resto 0 ou 1 (Para Nosso número será 0(zero) para 0/1)
//										   (Para DAV será 1(um) para 0/1)
// Objetivo   : Retornar digito verificador Modulo 11 Nosso Numero e Codigo Barra do Banco Santander
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf033_DV(cInCod,nResto)
	// cInCod --> Pode ser 13 numeros do Nosso Numero ou 43 digitos do codigo Barra

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,11)
	//Alert(nSumDv)
	// Se o resto for igual 0,1 ou 10 o digito será = 1(um) ou
	// Se o resto for igual 0,1 o digito será 0(zero)
	If nSumDv > 9
		nSumDv := 1
	ElseIf nSumDv <= 1
		nSumDv := nResto
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/01/2011
// Nome função: sf033DvLD
// Parametros : Codigo a calcular digito verificador
// Objetivo   : Retornar digito verificador Modulo 10 da Linha Digitavel do Banco Santander
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sf033DvLD(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)
	Local   nResult	:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv
	Endif

Return StrZero(nSumDv,1)




//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 29/08/2011
// Nome função: st422DV
// Parametros : Codigo a calcular digito verificador do DV do Nosso Número do Banco Safra
// Objetivo   : Retornar digito verificador Modulo 11 do Nosso Número Safra
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf422DV(cInCod)


	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	// Resto da Divisão
	nSumDv	:= Mod(nSumDv,11)

	// Se Resto for Zero, o DV será Um
	// Se Resto for Um, o DV será Zero
	If nSumDv == 0    	// Igual a 0
		nSumDv := 1		// Sempre será um
	ElseIf nSumDv == 1  // Igual a Um
		nSumDv := 0 	// Sempre será  Zero
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 29/08/2011
// Nome função: sf422dVLD()
// Parametros : 1 - Codigo a calcular digito verificador
// Objetivo   : Retornar digito verificador Modulo 11 Nosso Numero e Codigo Barra do Banco Santander
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf422DvLD(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)
	Local   nResult	:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	// Quando resto da divisão for Zero o Digito será Zero
	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv // Subtrai de Dez o Resto da divisão
	Endif

Return StrZero(nSumDv,1)



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 29/08/2011
// Nome função: st422DAC
// Parametros : Codigo a calcular digito verificador do DAC do Banco Safra
// Objetivo   : Retornar digito verificador Modulo 11 do Codigo Barras Safra
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf422DAC(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,11)
	// Se o resto for igual 0,1 ou 10 o digito será = 1(um)

	If nSumDv > 9   	// Igual a 10
		nSumDv := 1		// Sempre será um
	ElseIf nSumDv <= 1  // Igual a Zero ou Um
		nSumDv := 1 	// Sempre será um
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)




//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 05/01/2012
// Nome função: sf320_DV
// Parametros : 1 - Codigo a calcular digito verificador
//				2 - Digito se resto 0 ou 1 (Para Nosso número será 0(zero) para 0/1)
//										   (Para DAV será 1(um) para 0/1)
// Objetivo   : Retornar digito verificador Modulo 11 Nosso Numero e Codigo Barra do Banco BicBanco
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf320_DV(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local	cRetDv	:= "0"
	Local	cValCod	:= cCarteira + cRadical + cMatricula + cInCod
	Local   nSubr   := Len(cValCod)

	While .T.
		nSumDv  += Val(Substr(cValCod,nSubr--,1)) * nPeso++
		If nPeso > 7	// Base 7 conforme Manual BicBanco
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,11)
	//Alert(nSumDv)
	// Se o resto da divisão for igual 1 despreza a diferença entre o dividendo menos o resto que será 10 e considerar o digito como "P"
	// Se o resto da divisao for igual 0 despreza o calculo de subtração entre o dividendo e resto e considera "0" como dígito
	If nSumDv == 1
		cRetDv := "P"
	ElseIf nSumDv == 0
		cRetDv	:= "0"
	Else
		cRetDv := StrZero(11 - nSumDv,1)
	Endif

Return cRetDv



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 05/01/2012
// Nome função: sf320
// Parametros : Codigo a calcular digito verificador
// Objetivo   : Retornar digito verificador Modulo 10 da Linha Digitavel do Banco BicBanco
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sf320DvLD(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)
	Local   nResult	:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv
	Endif

Return StrZero(nSumDv,1)


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 05/01/2012
// Nome função: sf320_DAC
// Parametros : Codigo a calcular digito verificador do DAC do Banco BicBanco
// Objetivo   : Retornar digito verificador Modulo 11 do Codigo Barras BicBanco
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf320_DAC(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,11)
	// Se o resto for igual 0,1 ou 10 o digito será = 1(um)

	If nSumDv > 9   	// Igual a 10
		nSumDv := 1		// Sempre será um
	ElseIf nSumDv <= 1  // Igual a Zero ou Um
		nSumDv := 1 	// Sempre será um
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 05/01/2012
// Nome função:
// Parametros : 1 - Código da Agencia
//				2 - Nosso Número
// Objetivo   : Retornar Nosso Número com digito verificador
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf320DvNN(cInAgencia,cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local	cRetDv	:= "0"
	Local	cValCod	:= cInAgencia+cInCod
	Local   nSubr   := Len(cValCod)
	// Configuraão 	AAA 		= Código da Agencia Bic
	//			    NNNNNN		= Nosso Numero
	// 				D			= Digito a ser calculado
	// Calculo do digito = Modulo 11

	While .T.
		nSumDv  += Val(Substr(cValCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,11)
	// Se resto for
	If nSumDv == 1
		cRetDv := "0"
	ElseIf nSumDv == 0
		cRetDv	:= "1"
	ElseIf nSumDv == 10
		cRetDv	:= "1"
	Else
		cRetDv := StrZero(11 - nSumDv,1)
	Endif

Return cRetDv



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/05/2015
// Nome função: sf399_DV
// Parametros : 1 - Codigo a calcular digito verificador
//				  2 - Digito se resto 0 ou 1 (Para Nosso número será 0(zero) para 0/1)
// Objetivo   : Retornar digito verificador Modulo 11 Nosso Numero HSBC
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf399_DV(cInCod)

	Local	nSumDv		:= 0
	Local	nPeso		:= 2
	Local	cRetDv		:= "0"
	Local	cValCod	:= cInCod //cCarteira + cRadical + cMatricula + cInCod
	Local  nSubr   	:= Len(cValCod)

	While .T.
		nSumDv  += Val(Substr(cValCod,nSubr--,1)) * nPeso++
		If nPeso > 7	// Base 7 conforme manual do hsbc
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo
	// Resto da divisão Módulo 11
	nSumDv	:= Mod(nSumDv,11)
	// Nota: Quando o resto da divisão for igual a '0' ou '1', o Digito verificador será sempre '0'
	If nSumDv <= 1
		cRetDv	:= "0"
	Else
		cRetDv := StrZero(11 - nSumDv,1)
	Endif

Return cRetDv



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/05/2015
// Nome função: sf399_DAC
// Parametros : Codigo a calcular digito verificador do DAC do Banco HSBC
// Objetivo   : Retornar digito verificador Modulo 11 do Codigo Barras HSBC
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf399_DAC(cInCod)

	Local	nSumDv		:= 0
	Local  nPeso		:= 2
	Local  nSubr   	:= Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo
	// Módulo 11 - Resto da divisão
	nSumDv	:= Mod(nSumDv,11)
	// Se o resto for igual 0,1 ou 10 o digito será = 1(um)

	If nSumDv > 9   	// Igual a 10
		nSumDv := 1		// Sempre será um
	ElseIf nSumDv <= 1  // Igual a Zero ou Um
		nSumDv := 1 	// Sempre será um
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/05/2015
// Nome função: sf399DvLD
// Parametros : Codigo a calcular digito verificador 
// Objetivo   : Retornar digito verificador Modulo 10 da Linha Digitavel do Banco hsbc
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sf399DvLD(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)
	Local   nResult	:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv
	Endif

Return StrZero(nSumDv,1)




//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 14/06/2016
// Nome função: sf246_DV
// Parametros : 1 - Codigo a calcular digito verificador
//				2 - Digito se resto 0 ou 1 (Para Nosso número será 0(zero) para 0/1)
// Objetivo   : Retornar digito verificador Modulo 10 Nosso Numero ABC
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf246_DV(cInCod)

	Local	nSumDv		:= 0
	Local	nPeso		:= 2
	Local	cValCod		:= cInCod //cCarteira + cRadical + cMatricula + cInCod
	Local  	nSubr   	:= Len(cValCod)
	Local   nResult		:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv
	Endif

Return StrZero(nSumDv,1)



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 14/06/2016
// Nome função: sf246_DAC
// Parametros : Codigo a calcular digito verificador do DAC do Banco ABC
// Objetivo   : Retornar digito verificador Modulo 11 do Codigo Barras ABC
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf246_DAC(cInCod)

	Local	nSumDv		:= 0
	Local  nPeso		:= 2
	Local  nSubr   		:= Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo
	// Módulo 11 - Resto da divisão
	nSumDv	:= Mod(nSumDv,11)
	// Se o resto for igual 0,1 ou 10 o digito será = 1(um)

	If nSumDv > 9   	// Igual a 10
		nSumDv := 1		// Sempre será um
	ElseIf nSumDv <= 1  // Igual a Zero ou Um
		nSumDv := 1 	// Sempre será um
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 14/06/2016
// Nome função: sf246DvLD
// Parametros : Codigo a calcular digito verificador 
// Objetivo   : Retornar digito verificador Modulo 10 da Linha Digitavel do Banco ABC
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sf246DvLD(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)
	Local   nResult	:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv
	Endif

Return StrZero(nSumDv,1)



/*/{Protheus.doc} sfExec070
(Efetua baixa parcial referente Crédito F&I do Cliente durante a impressão do boleto)
@type function
@author marce
@since 19/04/2017
@version 1.0
@param cE1PREFIXO, character, (Descrição do parâmetro)
@param cE1NUM, character, (Descrição do parâmetro)
@param cE1PARCELA, character, (Descrição do parâmetro)
@param cE1TIPO, character, (Descrição do parâmetro)
@param nInDescFin, numérico, (Descrição do parâmetro)
@param nA1DESC, numérico, (Descrição do parâmetro)
@return nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExec070(cE1PREFIXO,cE1NUM,cE1PARCELA,cE1TIPO,nInDescFin,nA1DESC)

	Local 	aBaixa 		:= {}
	Local	aAreaOld	:= GetArea()

	aBaixa := {{"E1_PREFIXO"  ,cE1PREFIXO         ,Nil    },;
		{"E1_NUM"      ,cE1NUM           	  ,Nil    },;
		{"E1_PARCELA"  ,cE1PARCELA             ,Nil    },;
		{"E1_TIPO"     ,cE1TIPO                ,Nil    },;
		{"AUTMOTBX"    ,"NOR"                  ,Nil    },;
		{"AUTBANCO"    ,"950"                  ,Nil    },;
		{"AUTAGENCIA"  ,"00000"                ,Nil    },;
		{"AUTCONTA"    ,"0000000000"           ,Nil    },;
		{"AUTDTBAIXA"  ,dDataBase              ,Nil    },;
		{"AUTDTCREDITO",dDataBase              ,Nil    },;
		{"AUTHIST"     ,"F&I " + cValToChar(nA1DESC)+"%"              ,Nil    },;
		{"AUTDESCONT"  ,0                      ,Nil,   },;
		{"AUTJUROS"    ,0                      ,Nil,   },;
		{"AUTVALREC"   ,nInDescFin             ,Nil    }}

	MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3)

	RestArea(aAreaOld)

Return
