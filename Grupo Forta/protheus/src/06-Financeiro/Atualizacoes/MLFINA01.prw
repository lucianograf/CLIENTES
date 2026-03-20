#include 'protheus.ch'
#include 'parmtype.ch'
#include "TOPCONN.CH"


/*/{Protheus.doc} MLFINA01
// Impressão de Boletos - Itaú
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return Nil
@param lAuto, logical, Define se é automático
@param nOpc, numeric, Opção de Impressão
@param nRecSe1, numeric, Recno da SE1 para Reimpressão
@param lWhen, logical, Define de abre a tela 
@param aRecSE1, array, Vetor dos Recnos da SE1 para impressão
@type User Function
/*/
User function MLFINA01(lAuto,nOpc,nRecSe1,lWhen,aRecSE1)

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
	Private cContaItau	:= Space(6)
	Private cDvCta		:= Space(1)
	Private cCedente	:= Space(10)
	Private cVencAjust	:= "Não"
	Private cMultaAjust	:= "Sim"
	Private nE1_Saldo	:= 0
	Private nE1_ValJu	:= 0
	Private nE1_VlMulta	:= 0
	Private cRadical	:= ""
	Private cMatricula  := ""
	Private cAgBic		:= ""
	Private aBanco		:= {}
	Private aNewBco		:= {}
	Private cBanco		:= "   "

	If Type("cBancoImp") == "U"
		Private cBancoImp   := Space(8)
		Private cLocImp     := "F"
	Endif

	
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


/*/{Protheus.doc} sfSEEOpc
// Gera lista de Bancos habilitados 
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfSEEOpc()

	Local	aAreaOld	:= GetArea()

	DbSelectArea("SEE")
	DbSetOrder(1)
	If DbSeek(xFilial("SEE"))
		While !Eof() .And. SEE->EE_FILIAL == xFilial("SEE")
			// Se a configuração de banco for do tipo REM-Remessa
			If SEE->EE_EXTEN == "REM" .Or. (SEE->EE_EXTEN == "XXX" .And. cTipo == "REIMPRESSAO" )
				//If (SEE->EE_CODIGO == "033" .And. RetCodUsr() $ GetNewPar("GF_IDBL033","000000") ) .Or. SEE->EE_CODIGO <> "033"
					Aadd(aBanco,SEE->EE_OPER + "|" + SEE->EE_CODIGO + "|" + SEE->EE_AGENCIA + "|" + SEE->EE_CONTA + "|" + SEE->EE_SUBCTA)
				Endif 
				//aBanco     := {"ITAU|341|2938 |37576     |001|"} // Banco + Agencia + Conta + Sub-conta
			//Endif
			DbSkip()
		Enddo
	Endif
	RestArea(aAreaOld)

Return 


/*/{Protheus.doc} sfStart
// Inicio da rotina. 
@author marce
@since 14/08/2019
@version 1.0
@return 
@param lAuto, logical, descricao
@param nRecSe1, numeric, descricao
@param lWhen, logical, descricao
@param aRecSE1, array, descricao
@type function
/*/
Static Function sfStart(lAuto,nRecSe1,lWhen,aRecSE1)

	Local	aAreaSE1	:= SE1->(GetArea())

	// Seleciona os bancos conforme o tipo de selecionado 
	sfSEEOpc()

	If cTipo == "REIMPRESSAO"

		If lAuto
			DbSelectArea("SE1")
			DbGoto(nRecSe1)

			cBanco   	:= SE1->E1_PORTADO
			cAgencia 	:= AllTrim(SE1->E1_AGEDEP)
			cAgsiga  	:= SE1->E1_AGEDEP
			cConta   	:= SE1->E1_CONTA
			dbSelectArea("SA6")
			dbsetorder(1)
			dbseek(xFilial("SA6")+cBanco+cAgsiga+cConta)
			cDvCta		:= SA6->A6_DVCTA
			cContaItau	:= Substr(cConta,1,5) + cDvCta
			cBancoImp	:= Posicione("SEE",1,xFilial("SEE") + SA6->A6_COD + SA6->A6_AGENCIA+SA6->A6_NUMCON + "001","EE_OPER")
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
		@ nAltura,020 SAY "- Sem portador ( Pendente )" of oDlg pixel
		@ nAltura+010,010 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER of oDlg pixel
		@ nAltura+010,020 SAY "- Vendor/Antecipado ( Sem Boletos )" of oDlg pixel
		@ nAltura,110 BITMAP oBmp RESNAME "BR_AMARELO" SIZE 16,16 NOBORDER of oDlg pixel
		@ nAltura,120 SAY "- Enviado p/Banco ( Borderô )" of oDlg pixel
		@ nAltura+010,110 BITMAP oBmp RESNAME "BR_AZUL" SIZE 16,16 NOBORDER of oDlg pixel
		@ nAltura+010,120 SAY "- Impresso ( Título com Nosso Número)" of oDlg pixel

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
		cQry += "SELECT E1_PEDIDO,E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,E1_ORIGEM,E1_NUMBOR,E1_NUMBCO,A1_BCO1 "
		cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1 "
		cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
		cQry += "   AND SA1.D_E_L_E_T_ = ' ' "
		cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
		cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"' "
		cQry += "   AND SE1.E1_CLIENTE = SA1.A1_COD "
		cQry += "   AND SE1.E1_LOJA = SA1.A1_LOJA "
		cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-','CC') "
		cQry += "   AND SE1.E1_NUMBOR = ' ' "
		cQry += "   AND SE1.E1_SALDO > 0 "
		cQry += "   AND SE1.E1_SITUACA = '0' "
		cQry += "   AND SE1.E1_NUMBCO <> ' ' "
		cQry += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "
	Elseif cTipo == "IMPRESSAO"
		If !lAuto .And. MsgYesNo("Impressão de boletos à partir de notas fiscais já impressas ?")
			cQry := ""
			cQry += "SELECT E1_PEDIDO,E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,E1_ORIGEM,E1_NUMBOR,E1_NUMBCO,A1_BCO1"
			cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1, "+ RetSqlName("SF2") +" SF2 "
			cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
			cQry += "   AND A1_LOJA= E1_LOJA "
			cQry += "   AND A1_COD = E1_CLIENTE "
			cQry += "   AND SF2.D_E_L_E_T_ = ' ' "
			cQry += "   AND SF2.F2_CHVNFE <> ' ' " // Danfe impressa já gerou a Chave eletronica  
			cQry += "   AND F2_PREFIXO = E1_PREFIXO "
			cQry += "   AND SF2.F2_DOC = SE1.E1_NUM "
			cQry += "   AND SF2.F2_FILIAL = '" + xFilial("SF2") +"' "
			cQry += "   AND SE1.D_E_L_E_T_ = ' ' "
			cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-','CC') "
			cQry += "   AND SE1.E1_NUMBOR = ' ' "
			cQry += "   AND SE1.E1_PORTADO = ' ' "
			cQry += "   AND SE1.E1_NUMBCO = ' ' "
			cQry += "   AND SE1.E1_SALDO >0 "
			cQry += "   AND SE1.E1_SITUACA = '0' "
			cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"' "
			cQry += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA " 

		Else
			cQry := ""
			cQry += "SELECT E1_PEDIDO,E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,E1_ORIGEM,E1_NUMBOR,E1_NUMBCO,A1_BCO1 "
			cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1  "
			cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.D_E_L_E_T_ = ' '  "
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
			cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-','CC') "
			cQry += "   AND E1_NUMBCO = ' ' "
			cQry += "   AND SE1.E1_PORTADO = ' ' "
			cQry += "   AND SE1.E1_NUMBOR = ' ' "
			cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"' "
			cQry += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "
		Endif

	Elseif cTipo == "REIMPRESSAO"
		If !lAuto .And. MsgYesNo("Reimpressão de boletos à partir de notas fiscais?")
			cQry := ""
			cQry += "SELECT E1_PEDIDO,E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,E1_ORIGEM,E1_NUMBOR,E1_NUMBCO,A1_BCO1 "
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
			cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-','IS-','CC') "
			cQry += "   AND E1_PORTADO = '" + cBanco + "'"
			cQry += "   AND E1_AGEDEP = '" + cAgsiga + "'"
			cQry += "   AND E1_CONTA = '" +  cConta + "'"
			cQry += "   AND SE1.E1_SALDO > 0 "
			cQry += "   AND SE1.E1_EMISSAO BETWEEN '" + DTOS(dDataini)+ "' AND '" + DTOS(dDatafin)+ "' "
			cQry += "   AND SE1.E1_FILIAL = '"+ xFilial("SE1") +"'  "
			cQry += "ORDER BY SE1.E1_NUM, SE1.E1_PARCELA "
		Else

			cQry := ""
			cQry += "SELECT E1_PEDIDO,E1_NUM,E1_PARCELA,E1_PORTADO,A1_NREDUZ,E1_EMISSAO,E1_VENCTO,E1_VENCREA,A1_MUN,E1_SALDO,E1_PREFIXO,E1_TIPO,E1_ORIGEM,E1_NUMBOR,E1_NUMBCO,A1_BCO1 "
			cQry += "  FROM "+ RetSqlName("SE1") + " SE1, "+ RetSqlName("SA1") +" SA1 "
			cQry += " WHERE SE1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.D_E_L_E_T_ = ' ' "
			cQry += "   AND SA1.A1_LOJA = SE1.E1_LOJA "
			cQry += "   AND SA1.A1_COD =  SE1.E1_CLIENTE "
			cQry += "   AND SA1.A1_FILIAL = '" + xFilial("SA1") +"' "
			If lAuto
				If Len(aRecSE1) > 0
					cQry += " AND  " 
					cQry += " SE1.R_E_C_N_O_ IN( "
					For iS	:= 1 To Len(aRecSE1)
						If iS > 1
							cQry += ","
						Endif 
						cQry += Alltrim(Str(aRecSE1[iS]))
					Next
					cQry += " ) "
				Else
					cQry += " AND SE1.R_E_C_N_O_ = "+Alltrim(Str(nRecSE1))
				Endif
				
			Else
				cQry += "   AND E1_PORTADO = '" + cBanco + "'"
				cQry += "   AND E1_AGEDEP = '" + cAgsiga + "'"
				cQry += "   AND E1_CONTA = '" +  cConta + "'"
				cQry += "   AND E1_TIPO NOT IN('NCC','CH','JR','IR-','CF-','PI-','CS-', 'IS-','CC') "
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
		nSts	:= 2    
		// Verifica se já foi enviado para banco
		If !Empty(QRP->E1_NUMBOR)
			nSts	:= 3
		ElseIf !Empty(QRP->E1_NUMBCO) // Se já houve geração de boleto
			nSts	:= 4
		Endif

		If QRP->E1_ORIGEM == "MATA460 "
			DbSelectArea("SC5")
			DbSetOrder(1)
			If DbSeek(xFilial("SC5")+QRP->E1_PEDIDO)
				If SC5->C5_CONDPAG $ GetNewPar("GF_CPNBOLT","V01#000#099") .Or. SC5->C5_BANCO $ GetNewPar("GF_BCNBOLT","888#777") // Se for um título de Vendor ou cobrança 888 
					nSts	:= 1
				Endif 
			Endif
		Endif
		AAdd( aSE1, { 	nSts,;		// 1
		lAuto,;						// 2
		QRP->E1_NUM,;				//3
		QRP->E1_PARCELA,;			//4
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

			If SC5->C5_CONDPAG $ "V01" 
				MsgAlert("Este título foi gerado a partir de uma venda com Vendor! Não permitida a impressão de boletos.")
				aSE1[oSE1:nAt,2]	:= .F. 
				Return
			Endif

			If SC5->C5_CONDPAG $ "000#099" 
				MsgAlert("Este título foi gerado a partir de uma venda como Antecipado! Não permitida a impressão de boletos.")
				aSE1[oSE1:nAt,2]	:= .F. 
				Return
			Endif

			If SC5->C5_BANCO $ "888" 
				MsgAlert("Este título está com portador '888'. Não permitida a impressão de boletos.")
				aSE1[oSE1:nAt,2]	:= .F. 
				Return
			Endif
		Endif
	ElseIf aSE1[oSE1:nAt,1] == 1
		MsgAlert("Este título setado como Vendor ou Antecipado! Não permitida a impressão de boletos.")
		aSE1[oSE1:nAt,2]	:= .F. 
		Return
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
	ElseIf aSE1[oSe1:nAt,1] == 4
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
	@ 010,080 COMBOBOX cBancoImp ITEMS aBanco size 90,12 of oDlg2 pixel
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

	Local	oDlg2

	DEFINE MSDIALOG oDlg2 FROM 000,000 TO 180,400 OF oMainWnd PIXEL TITLE OemToAnsi("Informacao para Impressao")
	@ 02,10 TO 060,190 of oDlg2 pixel
	@ 010,018 Say "Informe o Banco:" of oDlg2 pixel
	@ 010,080 COMBOBOX cBancoImp ITEMS aBanco size 90,12 of oDlg2 pixel
	@ 025,018 Say "Local Impressão:" of oDlg2 pixel
	@ 025,080 Combobox cLocImp Items {"E","F","C"} Size 20,10 of oDlg2 pixel
	@ 045,018 Say "Data de: "
	@ 045,080 Get dDataini of oDlg2 pixel
	@ 045,105 Say "Até dia: "
	@ 045,130 Get dDatafin of oDlg2 pixel
	@ 070,090 BUTTON "Continua" size 40,15 of oDlg2 pixel ACTION (oDlg2:End() )
	@ 070,018 BUTTON "Aborta" size 40,15 of oDlg2 pixel ACTION (oDlg2:End())

	Activate MsDialog oDlg2 Centered

	aNewBco		:= StrTokArr(cBancoImp,"|")
	cBancoImp 	:= aNewBco[1]
	cBanco   	:= aNewBco[2]
	cAgencia 	:= AllTrim(aNewBco[3])
	cAgsiga  	:= aNewBco[3]
	cConta   	:= aNewBco[4]

	dbSelectArea("SA6")
	dbsetorder(1)
	dbseek(xFilial("SA6")+cBanco+cAgsiga+cConta)
	cDvCta		:= SA6->A6_DVCTA
	cContaItau	:= Substr(cConta,1,5) + cDvCta

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
		While !LockByName("MLFINA01"+cKeyLock,.F.,.F.,.T.)
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
		UnLockByName("MLFINA01"+cKeyLock,.F.,.F.,.T.)
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

	cBancoImp	:= Alltrim(cBancoImp)

	If cTipo == "IMPRESSAO"		
		aNewBco		:= StrTokArr(cBancoImp,"|")
		cBancoImp 	:= aNewBco[1]
		cBanco   	:= aNewBco[2]
		cAgencia 	:= AllTrim(aNewBco[3])
		cAgsiga  	:= aNewBco[3]
		cConta   	:= aNewBco[4]
		dbSelectArea("SA6")
		dbsetorder(1)
		dbseek(xFilial("SA6")+cBanco+cAgsiga+cConta)
		cDvCta		:= SA6->A6_DVCTA
		cContaItau	:= Substr(cConta,1,5) + cDvCta

		
	Endif

	// Verifica se pode ser feito o Lock de impressão 
	If !sfChekLock(.T.,cBanco)
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
			
			cCedente	:= SA6->A6_CODCED // Código do Cedente 

			dbSelectArea("SEE")
			dbSetOrder(1)
			If !dbSeek(xFilial("SEE")+SA6->A6_COD+SA6->A6_AGENCIA+SA6->A6_NUMCON+"001")
				Alert("Nao achou configuracao de banco")
				Loop
			Endif

			
			dbSelectArea("SE1")
			dbsetorder(1)
			If !Dbseek(xFilial("SE1")+aSE1[mr,5]+aSE1[mr,3]+aSE1[mr,4]+aSE1[mr,13]) // Filial+Prefixo+Numero+Parcela+Tipo
				Alert("Nao achou o título chave " +xFilial("SE1")+aSE1[mr,5]+aSE1[mr,3]+aSE1[mr,4]+aSE1[mr,13]  )			
				Loop 
			Endif 

			If Empty(SE1->E1_PORTADO+SE1->E1_AGEDEP+SE1->E1_CONTA+SE1->E1_NUMBCO ) .Or. cTipo == "NOVO_BANCO"
				If cTipo == "NOVO_BANCO"
					MsgInfo("Descarte o boleto anterior!","Atenção!")
				Endif
				Dbselectarea("SE1")
				RecLock("SE1",.F.)
				SE1->E1_PORTADO := cBanco
				SE1->E1_AGEDEP 	:= cAgsiga //cAgencia
				SE1->E1_CONTA 	:= cConta
				If SE1->(FieldPos("E1_BCOIMP")) > 0
					SE1->E1_BCOIMP 	:= Substr(cBancoImp,1,5)
				Endif
				SE1->E1_NUMBCO 	:= ' '
				MsUnLock()
			Endif

			If cBanco == "341"
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
			Endif

			If Val(SEE->EE_FAXFIM) - Val(SEE->EE_FAXATU) < 1000 .And. !FwIsInCallStack("U_MLFATA5X")
				MsgAlert("Favor avisar ao financeiro pois a Faixa atual de Nosso Número está com menos de 1000 (Um Mil) números disponíveis para emissão de boletos para este Banco!","A T E N Ç Ã O!!!")
			Endif

			DbSelectArea("SA1")
			DbSetOrder(1)
			SA1->(dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,.F.))

			// Cobra taxa de emissão de boleto
			// 15/05/2017 - Chamado 18157 
			nAcreVal		:= 0
			//	If SA1->(FieldPos("A1_XCOBBOL")) > 0 .And. SEE->(FieldPos("EE_XVALBOL")) > 0 .And. SA1->A1_XCOBBOL $ " #1" .And. SEE->EE_XVALBOL > 0
			//		nAcreVal	:= SEE->EE_XVALBOL

			//	Endif

			nDescFin		:= 0
			nDescFin		:= (SE1->E1_VALOR*SE1->E1_DESCFIN)/100
			If cVencAjust == "Não"
				nE1_ValJu		:= Iif(SE1->E1_VALJUR > 0,SE1->E1_VALJUR,SE1->E1_SALDO*0.0020)
				nTotAbImp		:= SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"V",SE1->E1_BAIXA)
				nE1_Saldo		:= SE1->E1_SALDO+SE1->E1_ACRESC-SE1->E1_DECRESC - nTotAbImp //(Iif(SA1->A1_RECIRRF $ "1",SE1->E1_IRRF,0)+Iif(SA1->A1_RECISS $ "1",SE1->E1_ISS,0))
				nE1_Saldo 		+= nAcreVal
				If SEE->(FieldPos("EE_XPMULTA")) > 0
					nE1_VlMulta		:= Round(SEE->EE_XPMULTA * nE1_Saldo / 100, 2)
				Else
					nE1_VlMulta		:= 0
				Endif
			Else
				nE1_ValJu		:= Iif(SE1->E1_VALJUR > 0,SE1->E1_VALJUR,SE1->E1_SALDO*0.0020)
				nTotAbImp		:= SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"V",SE1->E1_BAIXA)
				nE1_Saldo		:= SE1->E1_SALDO +SE1->E1_ACRESC-SE1->E1_DECRESC - nTotAbImp //(Iif(SA1->A1_RECIRRF $ "1",SE1->E1_IRRF,0)+Iif(SA1->A1_RECISS $ "1",SE1->E1_ISS,0))
				nE1_Saldo 		+= nAcreVal

				If SE1->E1_VENCREA >= dDataReimp
					If SEE->(FieldPos("EE_XPMULTA")) > 0
						nE1_VlMulta		:= Round(SEE->EE_XPMULTA * nE1_Saldo / 100, 2)
					Else
						nE1_VlMulta		:= 0
					Endif					
				Else
					If cMultaAjust == "Sim"
						If SEE->(FieldPos("EE_XPMULTA")) > 0
							nE1_VlMulta		:= Iif(SE1->E1_VLMULTA == 0,Round(SEE->EE_XPMULTA * nE1_Saldo / 100, 2),SE1->E1_VLMULTA)
						Else
							nE1_VlMulta		:= SE1->E1_VLMULTA
						Endif
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
				cInstr03      := "Sujeito a protesto se nao pago" //MV_PAR08
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

			cInstr04	:= "(TODAS AS INFORMAÇÕES DESTE BOLETO SÃO DE EXCLUSIVA RESPONSABILIDADE DO BENEFICIÁRIO)"
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

			If cBanco == "341"

				cDigVer := sf341DV()  // calculo dos digitos verificadores do nosso numero.

				If Empty(SE1->E1_numbco)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_numbco   	:= cNossoNum+cDigVer
					If SE1->(FieldPos("E1_NRBCORI")) > 0 
						SE1->E1_NRBCORI 	:= cNossoNum+cDigVer
					Endif
					MsUnlock("SE1")
				Endif
				//341 9 1 7272 0000350000 109 00000001 4 1293 216865 000
				cBarra	:=SE1->E1_PORTADO
				cBarra	+= If(SE1->E1_MOEDA==1,'9','0')
				cBarra 	+= Strzero(nFatorVen,4)
				cBarra  += StrZero(nE1_Saldo*100,10)						// 5 - Pos 10a19	Valor nominal
				cBarra 	+= SEE->EE_CODCART
				cBarra 	+= Substr(cNossoNum,1,8)+cDigVer
				cBarra	+= cAgencia + Substr(cContaItau,1,6)
				cBarra 	+= "000"  

				sf341DAC()

				sf341Bar()

				// Grava o código de barras 
				DbSelectarea("SE1")
				RecLock("SE1",.F.)
				SE1->E1_CODBAR    	:= cBarraFim
				SE1->E1_CODDIG		:= StrTran(StrTran(cLinha ,".","")," ","")
				SE1->(MsUnlock())

				cBMapABN        := "\imagens\logoitau.bmp"
			ElseIf cBanco == "033"   // SANTANDER

				cDigVer	:= sf033_DV(cNossoNum,0)  // calculo do digito verificador - Nosso número conforme Faixa Disponivel e 0(zero) pois para resto igual a 1 ou 0 o digito será zero

				If Empty(SE1->E1_numbco)
					dbSelectarea("SE1")
					RecLock("SE1",.F.)
					SE1->E1_numbco    := cNossoNum+cDigVer
					If SE1->(FieldPos("E1_NRBCORI")) > 0
						SE1->E1_NRBCORI   := cNossoNum+cDigVer
					Endif
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
				cBarra += "101"																// 42-44 - Tipo Modalidade Carteira - 101-Cobranca Simples Rápida COM registro
				//																												- 102-Cobrança Simples - SEM Registro
				//                                  																			- 201-Penhor Rápida com Registro
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
				cBar2  += Substr(cNossoNum,1,7)						// 14-20 7 Primeiros campos do Nosso Número
				cBar2  += sf033DvLD(cBar2)							// Digito verificador do 2º campo da linha digitavel

				cBar3  := Substr(cNossoNum,8,5)+cDigVer				// 22-27 Restante do Nosso Número+DigitoVerificador
				cBar3  += "0"										// 28-28 IOS Seguradoras - Demais Clientes Fixo "0"
				cBar3  += "101"										// 29-31 Tipo de Modalidade Carteira	- 101- Cobrança Simples Rápida COM Registro
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

				// Grava o código de barras 
				DbSelectarea("SE1")
				RecLock("SE1",.F.)
				SE1->E1_CODBAR    	:= cBarraFim
				SE1->E1_CODDIG		:= cBar1 + cBar2 + cBar3 + cBar4 + cBar5 
				SE1->(MsUnlock())

				cBMapABN        := "\imagens\logosantander.bmp"
			Endif

			cBMapEmp		:= "\imagens\grupoforta.bmp"

			oPrn:Say ( 000 , 0000, " ", oFont07,100 ) // startando a impressora
			oPrn:Say ( 050 , 1800, "RECIBO DO PAGADOR", oFont07,100)
			oPrn:Box ( 090 , 0200, 1900, 2180)
			oPrn:SayBitmap( 95, 210,cBMapEmp,300,160 )
			oPrn:Say ( 160, 550, SM0->M0_NOMECOM,oFont09,100)
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
			oPrn:Say( 1235, 1730, "Codigo Beneficiário"		,oFont03,100 )	

			oPrn:Say( 1310, 1730, "Nº. Documento "         ,oFont03,100  )
			oPrn:Say( 1385, 1730, "Nosso Número "          ,oFont03,100  )  //adicionado
			oPrn:Say( 1455, 1730, "Valor do Documento "    ,oFont03,100  )

			If cBanco == "341"

				oPrn:Say( 1265, 1800, ALLTRIM(SA6->A6_AGENCIA) + '/' + Substr(SA6->A6_NUMCON,1,5) + "-" + cDvCta ,oFont01,100 )   //Codigo do Cedente "2232-/0004778-3"
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )   //Vencimento do Titulo
				oPrn:Say( 1410, 1800, SEE->EE_CODCART+ "/"+cNossoNum+"-"+cDigVer                , oFont01,100  )
			ElseIf cBanco == "033"
				oPrn:Say( 1265, 1800, Alltrim(SA6->A6_AGENCIA)+'/'+cCedente,oFont01,100 )   // Codigo do Cedente "0083-3/1007041"
				oPrn:Say( 1340, 1800, SE1->E1_PREFIXO+" "+SE1->E1_NUM+" "+SE1->E1_PARCELA           ,oFont01,100  )
				oPrn:Say( 1410, 1800, StrZero(Val(cNossoNum),7)+" "+cDigVer							,oFont01,100 )

			Endif

			oPrn:Say( 1480, 1870, Iif(cBanco == "399","R$","")+Transform(nE1_Saldo,"@E 999,999.99") , oFont01,100  )   // Valor do Documento
			If nDescFin > 0
				oPrn:Say( 1550, 1870, Transform(nDescFin,"@E 999,999.99"), oFont01,100 ) // Valor do Desconto
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
				oPrn:Say( 1755, 0240, "Referente " + Alltrim(SE1->E1_TIPO) + " " + Alltrim(SE1->E1_SERIE) + "/" + SE1->E1_NUM + "-" + SE1->E1_PARCELA ,oFont06,100  )
			Endif

			oPrn:Say( 1525, 1730, "(-) Desconto/Abatimento "          ,oFont03,100  )
			oPrn:Say( 1595, 1730, "(-) Outras deduções "   ,oFont03,100  )
			oPrn:Say( 1665, 1730, "(+) Mora/Multa/Juros "  ,oFont03,100  )
			oPrn:Say( 1735, 1730, "(+) Outros Acrecimos "  ,oFont03,100  )
			oPrn:Say( 1805, 1730, "(=) Valor Cobrado "     ,oFont03,100  )

			If cBanco == "341"
				oPrn:Say( 1815, 0220, "Banco Itaú SA",oFont10,100)
				oPrn:Say( 1815, 1100, "341-7",oFont11,100)
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

			oPrn:Line(2360+nAjuste, 0500, 2501+nAjuste, 0500)
			oPrn:Line(2360+nAjuste, 0900, 2501+nAjuste, 0900)
			oPrn:Line(2360+nAjuste, 1100, 2431+nAjuste, 1100)
			oPrn:Line(2360+nAjuste, 1400, 2501+nAjuste, 1400)
			oPrn:Line(2430+nAjuste, 0700, 2501+nAjuste, 0700)

			If cBanco == "341"
				oPrn:SayBitmap( 2060+nAjuste, 0220,cBMapABN,95,95)
				oPrn:Say( 2105+nAjuste, 0320, "Banco Itaú SA",oFont06,100)
				oPrn:Say( 2105+nAjuste, 0560, "341-7"                  ,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   ,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, ALLTRIM(SA6->A6_AGENCIA)+'/'+ Substr(SA6->A6_NUMCON,1,5) + "-" + cDvCta, oFont01,100  )   //Codigo do Cedente "2232-2/0004778-3"
				oPrn:Say( 2390+nAjuste, 1800, SEE->EE_CODCART + "/"+cNossoNum+"-"+cDigVer            , oFont01,100  )
				oPrn:Say( 2460+nAjuste, 0560, SEE->EE_CODCART , oFont01,100  )   //Carteira
			
			ElseIf cBanco == "033"
				oPrn:SayBitmap( 2090+nAjuste, 0200,cBMapABN,300,85 )
				oPrn:Say( 2105+nAjuste, 0560, "033-7"                  	,oFont11,100)
				oPrn:Say( 2105+nAjuste, 0745, cLinha                   	,oFont09,150)
				oPrn:Say( 2320+nAjuste, 1800, Alltrim(SA6->A6_AGENCIA)+'/'+cCedente, oFont01,100  )
				oPrn:Say( 2390+nAjuste, 1800, StrZero(Val(cNossoNum),7)+" "+cDigVer, oFont01,100   )
				oPrn:Say( 2460+nAjuste, 0220, "Carteria Rapida c/ Registro - CRC"      		, oFont01,100  )   //Uso do Banco

			Endif


			oPrn:Say( 2185+nAjuste, 0220, "Local de Pagamento "       	,oFont03,100  )
			oPrn:Say( 2185+nAjuste, 1730, "Vencimento "               	,oFont03,100  )
			oPrn:Say( 2235+nAjuste, 0240, SEE->EE_LOCPAG				,oFont07,100  )   //Cedente

			If cVencAjust == "Não"
				oPrn:Say( 2235+nAjuste, 1900, DTOC(SE1->E1_VENCREA)         ,oFont07,100  )   //Vencimento do Titulo
			Else
				oPrn:Say( 2235+nAjuste, 1900, DTOC(dDataReimp)             	,oFont07,100  )   //Vencimento do Titulo
			Endif

			oPrn:Say( 2295+nAjuste, 0220, "Beneficiário"				,oFont03,100 )
			oPrn:Say( 2295+nAjuste, 1730, "Codigo Beneficiário"			,oFont03,100 )

			oPrn:Say( 2320+nAjuste, 0240, SM0->M0_NOMECOM,oFont01,100  )   			//Cedente

			oPrn:Say( 2365+nAjuste, 0220, "Data Documento "        ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 0510, "Nº. Documento "         ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 0910, "Espécie Doc. "          ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 1110, "Aceite "                ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 1410, "Data do Processamento " ,oFont03,100  )
			oPrn:Say( 2365+nAjuste, 1730, "Nosso Número "          ,oFont03,100  )

			oPrn:Say( 2390+nAjuste, 0240, DTOC(SE1->E1_EMISSAO)       , oFont01,100  )
			oPrn:Say( 2390+nAjuste, 0530, SE1->E1_PREFIXO+SE1->E1_NUM+" "+SE1->E1_PARCELA , oFont01,100  )
			oPrn:Say( 2390+nAjuste, 1440, DTOC(DDATABASE)        	    	, oFont01,100  )
			oPrn:Say( 2390+nAjuste, 0970, "DM"                    		, oFont01,100  )
			oPrn:Say( 2390+nAjuste, 1230, "N"                       	, oFont01,100  )			


			oPrn:Say( 2435+nAjuste, 0220, "Uso do Banco "      ,oFont03,100  )
			oPrn:Say( 2435+nAjuste, 0510, "Carteira "          ,oFont03,100  )
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

			For wI := 1 To Len(aInstrucoes)
				oPrn:Say( 2495+(wI*40)+nAjuste, 0240, aInstrucoes[wI,1]				,aInstrucoes[wI,2],100  )
			Next wI 

			oPrn:Say( 2800+nAjuste, 0240, "Referente " + Alltrim(SE1->E1_TIPO) + " " + Alltrim(SE1->E1_SERIE) + "/" + SE1->E1_NUM + "-" + SE1->E1_PARCELA  ,oFont06,100  )

			oPrn:Say( 2575+nAjuste, 1730, "(-) Outras deduções "   ,oFont03,100  )
			oPrn:Say( 2645+nAjuste, 1730, "(+) Mora/Multa/Juros "  ,oFont03,100  )
			oPrn:Say( 2715+nAjuste, 1730, "(+) Outros Acrecimos "  ,oFont03,100  )
			oPrn:Say( 2785+nAjuste, 1730, "(=) Valor Cobrado "     ,oFont03,100  )

			oPrn:Say( 2845+nAjuste, 0220, "Pagador", 					oFont03,100 ) 
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


			oPrn:Say( 3110+nAjuste, 1800, "AUTENTICACAO MECANICA",oFont04,100  )
			oPrn:Say( 3140+nAjuste, 1750, "FICHA DE COMPENSAÇÃO",oFont05,100  )


			//colocacao do codigo de barras incorreto
			If cLocImp =="F"
				MSBAR("INT25",27.7,2.10,AllTrim(cBarraFim),oPrn,.F.,NIL,.T.,NIL,NIL,NIL,oFont02,NIL,.F.)//rafael
			Else
				MSBAR("INT25",14.2,1.3,AllTrim(cBarraFim),oPrn,.F.,NIL,.T.,0.011,1,.F.,oFont02,NIL,.F.)//rafael
			Endif
			oPrn:EndPage()
		Endif

	Next nForA

	// Libera só depois de imprimir todos os boletos 
	sfChekLock(.F.,cBanco)
	
	//TMSPrinter(): SaveAllAsJpeg ( [ cFilePath], [ nWidthPage], [ nHeightPage], [ nZoom], [ nQuality] ) --> lOk
	
	//oPrn:SaveAllAsJPEG("\treport\boletoz",1050,1450,160,100)   		
	
	If Type("lFirstDF") == "L"
		oPrn:Print()
	Else
		oPrn:Preview()
		MS_Flush()
	Endif

Return 




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
