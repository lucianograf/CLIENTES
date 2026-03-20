#INCLUDE "PROTHEUS.CH"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} FPDC_002
Selecionar pedidos separados e gerar Documento Saida
@type function
@version 1
@author Marcelo Alberto Lauschner
@since 19/06/2011
@param lOnlyView, logical, param_description
/*/
User Function FPDC_002(lOnlyView)

	Local aAreaOld		:= GetArea()
	Local cTitulo	 	:= OemToAnsi("Monitoramento de Pedidos - Tela de Faturamento!")

	Private oSC9
	Private aSC9 		:= {}
	Private oDlg

	Private oVermelho	:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	Private oAzul 		:= LoaDbitmap( GetResources(), "BR_AZUL" )
	Private oAmarelo	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private oPreto		:= LoaDbitmap( GetResources(), "BR_PRETO" )
	Private oBranco     := LoaDbitmap( GetResources(), "BR_BRANCO" )
	Private oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Private oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	Private aSize 		:= MsAdvSize()
	Private aObjects 	:= {}
	Private aPosGet     := {}
	Private cVarPesq	:= Space(6)
	Private nColPos 	:= 1
	Private lSortOrd	:= .F.
	Private dDtProg		:= dDataBase
	Private nOpcLoc		:= 0
	Private aRecPA2		:= {}
	Private lTransp		:= .F.
	Private oTotPeso,oTotValor,oTotPedidos
	Private nTotPeso	:= nTotValor 	:= nTotPedidos	:= 0

	Default lOnlyView	:= .F.

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	// Verifica se o usuário está com a database correta.
	If dDataBase <> Date()
		If !MsgNoYes("Você está logado no sistema com a database diferente do dia atual. DESEJA CONTINUAR ASSIM MESMO??????????")
			Return
		Endif
	Endif

	If !(cEmpAnt $ "14")
		MsgAlert("Rotina não liberada para uso nesta empresa!")
		Return
	Endif

	// Efetua validação para ter certeza de que o parametro será criado
	//DbSelectArea("SX6")
	//DbSetOrder(1)
	//If !DbSeek(cFilAnt+"GM_SERIENF")
	//	RecLock("SX6",.T.)
	//	SX6->X6_FIL     := cFilAnt
	//	SX6->X6_VAR     := "GM_SERIENF"
	//	SX6->X6_TIPO    := "C"
	//	SX6->X6_DESCRIC := "Série de Nota Fiscal default"
	//	MsUnLock()
	//	PutMv("GM_SERIENF","2")
	//	MsgAlert("Foi necessário criar o paramêtro 'GM_SERIENF' para informar a série de nota fiscal padrão para a empresa/filial Atual","Paramêtro criado!!")
	//EndIf

	DbSelectArea("SC5")
	If SC5->(FieldPos("C5_DTPROGM")) > 0
		lContinua 	:= .F.

		DEFINE MSDIALOG oPerg FROM 001,001 TO 180,350 OF oMainWnd PIXEL TITLE OemToAnsi("Defina a data limite de programados")

		oPanela := TPanel():New(0,0,'',oPerg, oPerg:oFont, .T., .T.,, ,200,40,.T.,.T. )
		oPanela:Align := CONTROL_ALIGN_ALLCLIENT

		@ 005,020 SAY "Data Programada até " of oPanela pixel
		@ 003,085 MSGET dDtProg of oPanela pixel

		ACTIVATE MSDIALOG oPerg ON INIT EnchoiceBar(oPerg,{|| lContinua	:= .T. /*true*/,oPerg:End()},{|| oPerg:End()},,) CENTERED

		If !lContinua
			Return
		Endif
	Endif

	Processa({|| stCriaArq() },"Aguarde! Selecionando pedidos aptos a separar...")

	If Len(aSC9) < 1  // Evita que abra a tela se não houver pedidos a serem faturados.
		MsgInfo("Não há pedidos enviados ao depósito disponíveis para faturamento.","Não há pedidos!")
		Return
	Endif

	DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

	oDlg:lMaximized := .T.

	//oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	//oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM

	@ 005,005 LISTBOX oSC9 VAR cSc9 Fields HEADER ;
		" ",; 				//  1
	" ",;   			//  2
	"Pedido",;          //  3
	"Status Wms",;		//  4
	"Nome Cliente",;    //  5
	"Cidade",;          //  6
	"Transportadora",;  //  7
	"Valor",;           //  8
	"Envio Separação",;  //  9
	"Conf.Etiquetas",;  // 10
	"Mensagens",;       //  11
	"Nº NF Gerado";     //  12
	SIZE 200,200;
		ON DBLCLICK (stDblClick(lOnlyView)) OF oPanel2 PIXEL
	oSC9:nFreeze := 3
	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{stStsSepar(),;
		Iif(aSC9[oSC9:nAT,02],oMarked,oNoMarked),;
		aSC9[oSC9:nAT,03],;
		aSC9[oSC9:nAT,04],;
		aSC9[oSC9:nAT,05],;
		aSC9[oSC9:nAT,06],;
		aSC9[oSC9:nAT,07],;
		aSC9[oSC9:nAT,08],;
		aSC9[oSC9:nAT,09],;
		aSC9[oSC9:nAT,10],;
		aSC9[oSC9:nAT,11],;
		aSC9[oSC9:nAT,12],;
		aSC9[oSC9:nAT,13],;
		aSC9[oSC9:nAT,14]}}

	oSC9:Align := CONTROL_ALIGN_ALLCLIENT
	
	oSC9:Refresh()

	oSC9:bHeaderClick := {|| Iif(oSC9:ColPos == 2 ,sfMarkAll(lOnlyView),(cVarPesq := aSC9[oSC9:nAt,3],nColPos :=oSC9:ColPos,lSortOrd := !lSortOrd, aSort(aSC9,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),stVldPesC9() )) }

	@ 005,010 BITMAP oBmp RESNAME "BR_VERDE" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,020 SAY "- Separado Completo " of oPanel3 pixel
	@ 020,010 BITMAP oBmp RESNAME "BR_AMARELO" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 020,020 SAY "- Pedido em Separação" of oPanel3 pixel
	@ 005,080 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,090 SAY "- A separar" of oPanel3 pixel
	@ 020,080 BITMAP oBmp RESNAME "BR_AZUL" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 020,090 SAY "- Separado com Divegência" of oPanel3 pixel

	@ 005,160 SAY "Pesquisar Pedido Nº" of oPanel3 pixel
	@ 005,210 MSGET cVarPesq Valid stVldPesC9() of oPanel3 pixel

	@ 005,260 MsGet oTotPeso Var nTotPeso  Picture "@E 999,999.9999" Size 50,10  READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 018,260 MsGet oTotValor Var nTotValor Picture "@E 999,999,999.99" Size 50,10 READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 031,260 MsGet oTotPedidos Var nTotPedidos Picture "@E 999,999" Size 50,10 READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 006,315 Say "Kg" of oPanel3 Pixel
	@ 019,315 Say "Reais" of oPanel3 Pixel
	@ 032,315 Say "Pedidos" of oPanel3 Pixel

	If !lOnlyView
		@ 005,350 BUTTON "&Gerar Notas" of oPanel3 pixel SIZE 60,12 ACTION (Processa({|| stExpSC9() },"Gerando Notas fiscais..."),oDlg:End() ) When !lTransp
		@ 005,485 BUTTON "&Reimprimir Pedido" of oPanel3 pixel SIZE 60,12 ACTION sfReimp() When !lTransp
		@ 020,350 Button "Alterar Transp." of oPanel3 Pixel Size 60,12 Action sfAltInverte()
	Endif
	@ 020,420 Button "Posição Pedidos" Of oPanel3 Pixel Size 60,12 Action sfVerColetor()
	@ 005,420 BUTTON "&Cancela" of oPanel3 pixel SIZE 60,12 ACTION (oDlg:End() )


	ACTIVATE MSDIALOG oDlg CENTERED

	RestArea(aAreaOld)

Return



/*/{Protheus.doc} sfMarkAll
Função para marcar todas as notas de uma só vez 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 08/11/2021
@return variant, return_description
/*/
Static Function sfMarkAll(lOnlyView)

	Local 	nX 
	Local 	nBx 	:= oSC9:nAt 

	For nX  := 1 To Len(aSC9)
		oSC9:nAt	:= nX 
		stDblClick(lOnlyView)
	Next
	oSC9:nAt 	:= nBx 
	oSC9:Refresh()

Return 

/*/{Protheus.doc} stCriaArq
(long_description)
@author MarceloLauschner
@since  17/09/2009
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stCriaArq()

	Local cQry 		:= ""
	Local nReg 		:= 0
	Local nStatus 	:= 0
	Local cSigTp	:= ""
	Local cStsWms	:= ""
	Local cLogEnv	:= ""
	Local cLogRet	:= ""

	cQry := ""
	cQry += "SELECT C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_XWMSPED,C9_XWMSEDI,C9_ORDSEP,SUM(C9_PRCVEN*C9_QTDLIB) AS TOT , "
	cQry += "       SUM(C9_QTDLIB*B1_PESO) PESOPEDIDO "
	cQry += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SB1") + " SB1 "
	cQry += " WHERE SB1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = C9_PRODUTO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1") + "' "
	cQry += "   AND SC9.D_E_L_E_T_ = ' ' "
	// Customização para filtrar pedidos por local de saída, 02/08/2013
	If cEmpAnt+cFilAnt $ "0205"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial RS é necessário escolher entre o armazém Texaco ou Continental",{"01-Atria","02-Continental","03-Pneus Agro"},3)
		Endif

		If nOpcLoc == 2
			cQry += " AND C9_LOCAL = '02' "
			cQry += " AND NOT EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = C9_PRODUTO AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"			
		ElseIf nOpcLoc == 1
			cQry += " AND C9_LOCAL = '01' "
		Elseif nOpcLoc == 3
			cQry += "  AND EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = C9_PRODUTO AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"			
		Else
			nOpcLoc := 4
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0201"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial SC é necessário escolher entre o armazém Texaco ou Continental",{"01-Atria","02-Continental","03-Pneus Agro"},3)
		Endif

		If nOpcLoc == 2
			cQry += " AND C9_LOCAL = '02' "
			cQry += " AND NOT EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = C9_PRODUTO AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"			
		ElseIf nOpcLoc == 1
			cQry += " AND C9_LOCAL = '01' "
		Elseif nOpcLoc == 3
			cQry += "  AND EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = C9_PRODUTO AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"			
		Else
			nOpcLoc := 4
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0208"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial MG é necessário escolher entre o armazém de Lubrificante ou Pneus!",{"01-Lubrificantes","02-Pneus"},3)
		Endif

		If nOpcLoc == 2
			cQry += " AND C9_LOCAL = '02' "
		ElseIf nOpcLoc == 1
			cQry += " AND C9_LOCAL = '01' "
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0204"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial PR é necessário escolher entre o armazém da Texaco ou Michelin!",{"01-Texaco","02-Michelin","03-Pneus Agro"},3)
		Endif

		If nOpcLoc == 2
			cQry += " AND C9_LOCAL = '02' "
			cQry += " AND NOT EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = C9_PRODUTO AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"			
		ElseIf nOpcLoc == 1
			cQry += " AND C9_LOCAL = '01' "
		Elseif nOpcLoc == 3
			cQry += "  AND EXISTS(SELECT B1_COD FROM " + RetSqlName("SB1") + " B1 WHERE B1.D_E_L_E_T_ =' ' AND B1_COD = C9_PRODUTO AND B1_CABO = 'AGR' AND B1_FILIAL = '"+xFilial("SB1")+ "' )"
		Else
			nOpcLoc := 4
		Endif
	Endif 
	cQry += "   AND C9_FLGENVI = 'E' "
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	cQry += "   AND C9_SERIENF = '   ' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") +"' "
	cQry += " GROUP BY C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_XWMSPED,C9_XWMSEDI,C9_ORDSEP "
	cQry += " ORDER BY C9_PEDIDO"

	TCQUERY cQry NEW ALIAS "QRP"

	Count to nReg

	dbselectarea("QRP")
	dbGotop()
	ProcRegua(nReg)
	While !Eof()

		IncProc("Processando Pedido Nº-> "+QRP->C9_PEDIDO)


		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+QRP->C9_PEDIDO)
		If ( SC5->(FieldPos("C5_DTPROGM")) > 0 .And. SC5->C5_DTPROGM > dDtProg )
			dbSelectArea("QRP")
			dbSkip()
			Loop
		Endif

		If SC5->C5_TIPO $ "D#B"
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+QRP->C9_CLIENTE+QRP->C9_LOJA)
		Else
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+QRP->C9_CLIENTE+QRP->C9_LOJA)
			// Chama função que executa a verificação se o cliente está cadastrado como Item contábil
			// Objetivo desta regra é que qualquer cliente cadastrado novo que venha a ter pedido já esteja cadastrado
			// Chamada adicionada em 04/10/2014
			U_BFCTBM21()

		Endif

		Dbselectarea("SA4")
		Dbsetorder(1)
		Dbseek(xFilial("SA4")+SC5->C5_TRANSP)

		nStatus	:= 1	// Vermelho

		cQry := ""
		cQry += "SELECT SUM(CASE WHEN C9_XWMSPED = 0 THEN 0 ELSE 1 END) EDIWMS," 	// Verifica se o pedido foi enviado para EDI
		cQry += "       SUM(C9_QTDLIB) QTDLIB,"					// Quantidade liberada
		cQry += "       SUM(C9_XWMSQTE) SEPARADOS "				// Quantidade Separada pelo WMS
		cQry += "  FROM " + RetSqlName("SC9")
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND C9_FLGENVI <> ' ' "
		cQry += "   AND C9_BLEST = '  ' "
		cQry += "   AND C9_BLCRED = '  ' "
		cQry += "   AND C9_NFISCAL = '      ' "
		cQry += "   AND C9_SERIENF = '   ' "
		cQry += "   AND C9_PEDIDO =  '" +QRP->C9_PEDIDO+"' "
		cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "

		TCQUERY cQry NEW ALIAS "QCOL"

		// Se todos os itens já foram exportados

		If QCOL->EDIWMS > 0

			If QCOL->QTDLIB == QCOL->SEPARADOS
				nStatus 	:= 2 	// Verde
				cStsWms		:= ""
			ElseIf QRP->C9_XWMSPED == 9999999
				nStatus 	:= 2	// Verde
				cStsWms		:= "NÃO USA WMS"
			ElseIf QCOL->SEPARADOS == 0
				nStatus 	:= 3 	// Amarelo
				cStsWms		:= ""
			Else
				nStatus		:= 4 	// Azul
				cStsWms		:= ""
			Endif
			DbSelectArea("CB7")
			DbSetOrder(1)
			If DbSeek(xFilial("CB7")+QRP->C9_ORDSEP)
				If CB7->CB7_STATUS == "1"
					cStsWms	:= "EM SEPARAÇÃO"
				ElseIf CB7->CB7_STATUS == "2"
					cStsWms	:= "SEPARADO"
					If CB7->CB7_VOLEMI <> "1"
						nStatus	:= 3
						cStsWms	:= "FALTA ETIQUETA"
					Endif
				Endif
			Endif

		Endif
		QCOL->(DbCloseArea())

		cSigTp	:= 	U_FPDC_007(SC5->C5_TIPO,SC5->C5_CLIENTE,SC5->C5_LOJACLI)

		cLogEnv	:= ""
		cLogRet	:= ""
		DbSelectArea("SZ0")
		DbSetOrder(1)
		DbSeek(xFilial("SZ0")+QRP->C9_PEDIDO)
		While !Eof() .And. SZ0->Z0_PEDIDO == QRP->C9_PEDIDO
			// Envio para Separação
			If SZ0->Z0_TIPO == "EC"
				If Alltrim(SZ0->Z0_DEST) $ "DIS086#FPDC_001"
					cLogEnv 	+= "|"+DTOC(SZ0->Z0_DATA)+" "+SZ0->Z0_HORA +" "+ Iif(SZ0->(FieldPos("Z0_OBS")) <> 0 ,Alltrim(SZ0->Z0_OBS),"")
				Endif
			ElseIf SZ0->Z0_TIPO == "CP"
				cLogRet	+= "|"+DTOC(SZ0->Z0_DATA)+" "+SZ0->Z0_HORA
			Endif
			SZ0->(DbSkip())
		Enddo

		//nStatus := 2
		AAdd( aSC9, { 	nStatus,;				// 1 Legenda
		.F.,;									// 2 Falso
		QRP->C9_PEDIDO,;						// 3 Pedido
		cStsWms,;                               // 4
		QRP->C9_CLIENTE+"/"+QRP->C9_LOJA +" - "+ Iif(SC5->C5_TIPO$"D#B",SA2->A2_NREDUZ,SA1->A1_NREDUZ),;	// 5 Codigo/Loja Nome Cliente
		Iif(SC5->C5_TIPO$"D#B",SA2->A2_MUN,SA1->A1_MUN),;							// 6 Cidade
		cSigTp+"-"+SC5->C5_TRANSP+" - "+SA4->A4_NREDUZ,;  	// 7 Transportadora
		Transform(QRP->TOT,"@E 99,999,999.99"),;// 8 Total Pedido
		cLogEnv,;								// 9  Envio
		cLogRet,;								// 10 - Retorno
		Alltrim(SC5->C5_MSGINT),; 			    // 11 Mensagem
		'         ',;							// 12 Número de Nota para Controle do ListBox
		QRP->TOT,;                              // 13 Valor Pedido
		QRP->PESOPEDIDO})						// 14 Peso

		dbSelectArea("QRP")
		dbSkip()
	Enddo

	QRP->(DbCloseArea())
	ProcRegua(1)
	IncProc("Finalizando...")

Return


/*/{Protheus.doc} stStsSepar
(Legenda do status da Rota)
@author MarceloLauschner
@since 18/09/2009
@version 1.0
@return objeto cor da legenda
@example
(examples)
@see (links_or_references)
/*/
Static Function stStsSepar()

	nRet := 1

	If aSC9[oSc9:nAt,1] == 1
		nRet	:= oVermelho
	ElseIf	aSC9[oSc9:nAt,1] == 2
		nRet	:= oVerde
	ElseIf	aSC9[oSc9:nAt,1] == 3
		nRet	:= oAmarelo
	Else
		nRet	:= oAzul
	EndIf

Return nRet


/*/{Protheus.doc} stVldPesC9
(Posicionar no ListBox o numero do pedido pesquisado)
@author MarceloLauschner
@since 18/09/2009
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stVldPesC9()

	Local nAscan := Ascan(aSC9,{|x|x[3]==cVarPesq})

	If nAscan <=0
		nAscan	:= 1
	Endif
	oSC9:nAT 	:= nAscan
	cVarPesq	:= space(06)
	oSC9:Refresh()
	oSC9:SetFocus()

Return

/*/{Protheus.doc} stDblClick
( Marca e desmarca linha do ListBox)
@author MarceloLauschner
@since 18/09/2009
@version 1.0
@param ${param}, ${param_type}, ${param_descr}
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stDblClick(lOnlyView)

	Local	iX

	If lOnlyView
		Return
	Endif



	If !lTransp .And. aSC9[oSc9:nAt,1] == 1
		MsgAlert("Não é permitido faturar pedido que ainda não tenha sido enviado para separação.","Pedido não separado!!")
		Return
	ElseIf !lTransp .And. aSC9[oSc9:nAt,1] == 3
		MsgAlert("Não é permitido faturar pedido que ainda não tenha sido conferido.","Pedido não conferido!")
		Return
	Endif

	nTotPeso	:= 0
	nTotValor	:= 0
	nTotPedidos	:= 0

	aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .and. aSC9[oSc9:nAt,1]>=1 ,.T., .F.)

	For iX := 1 To Len(aSC9)
		If aSC9[iX,2]
			nTotPeso	+= aSC9[iX,14]
			nTotValor	+= aSC9[iX,13]
			nTotPedidos += 1
		Endif
	Next
	oTotPeso:Refresh()
	oTotValor:Refresh()
	oTotPedidos:Refresh()


Return

/*/{Protheus.doc} stExpSC9
(long_description)
@author MarceloLauschner
@since 13/06/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stExpSC9()

	Local lContinua	:= .F.
	Local x			:= 1
	Local cNumNota  := Space(TamSX3("F2_DOC")[1])
	Local cNfFats	:= ""
	Local iZ

	//verifica se existem pedidos marcados para continuar
	For x := 1 To Len(aSC9)
		If aSC9[x,2]
			lContinua  := .T.
			Exit
		Endif
	Next

	// Executa uma pergunta para garantir uma opção abortar o processo
	If !MsgYesNo("Deseja realmente gerar Nota Fiscal dos pedidos pedidos selecionados?")
		Return
	Endif

	If lContinua


		For x := 1 To Len(aSC9)

			If 	aSC9[x,2]

				// Inicia Proteção de Gravação
				// É necessário ficar atendo por que todos os registros envolvidos estarão Bloqueados
				//Begin Transaction


				// Executa verificação de divergencia na separação para efetuar nova liberação de itens divergentes
				stAjustaErrC9(aSC9[x,3])

				// Envia pedido para Vertical e Coletor
				aRecPA2		:= {}
				aRetFat		:= stGravaF2(aSC9[x,3])  // 1-Nota+serie 2-Pedido 3-T/F se gera pedido remessa

				cNumNota	:= aRetFat[1]
				cNfFats 	+= cNumNota + " / "
				// Grava Log
				// Não precisa mais gravar log por aqui pois o ponto de entrada SF2460I já efetua isso
				//U_GMCFGM01("EC",aSC9[x,3],"Num.NF:"+cNumNota,FunName())

				// Commita transações
				//End Transaction

				//Begin Transaction
				// Se gera pedido de remessa de vasilhame
				If aRetFat[3]

					//{cSerie +"-"+cNota,cNewPedRem,lExistRem,cNota,cSerie}
					cNumPedRem	:= aRetFat[2]
					aRetFat		:= stGravaF2(cNumPedRem,.T.)
					cNumNota	:= aRetFat[1]
					cNfFats += cNumNota + " / "
					// Grava Log
					// Não precisa mais gravar log por aqui
					//U_GMCFGM01("EC",cNumPedRem,"Num.NF:"+cNumNota,FunName())


					DbSelectArea("SC5")
					DbSetOrder(1)
					MsSeek(xFilial("SC5")+cNumPedRem)
					If SC5->C5_TIPO $ "D#B"
						DbSelectArea("SA2")
						DbSetOrder(1)
						MsSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
					Else
						DbSelectArea("SA1")
						DbSetOrder(1)
						MsSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
					Endif
					For iZ := 1 To Len(aRecPA2)
						DbSelectArea("PA2")
						DbGoto(aRecPA2[iZ])
						RecLock("PA2",.F.)
						PA2->PA2_NUMNF	:= aRetFat[4]
						PA2->PA2_SERIE	:= aRetFat[5]
						PA2->PA2_CGCREM	:= Iif(SC5->C5_TIPO $ "D#B",SA2->A2_CGC,SA1->A1_CGC)
						MsUnlock()
					Next

				Endif

				// Gera o documento de saída automático 
				If aRetFat[6]

					//{cSerie +"-"+cNota,cNewPedRem,lExistRem,cNota,cSerie}
					cNumPedRem	:= aRetFat[7]
					aRetFat		:= stGravaF2(cNumPedRem,.T.)
					cNumNota	:= aRetFat[1]
					cNfFats += cNumNota + " / "
					// Grava Log
					// Não precisa mais gravar log por aqui
					//U_GMCFGM01("EC",cNumPedRem,"Num.NF:"+cNumNota,FunName()

				Endif
				//End Transaction
			Endif
		Next

		Aviso("Geração de Notas!","As seguintes notas foram geradas: "+CRLF+CRLF+cNfFats,{"Ok"},3)

	Else
		MsgAlert("Não houveram pedidos selecionados para exportação! ","Atenção.")
	Endif


Return


/*/{Protheus.doc} stAjustaErrC9
(Verificar se há divergencias na separação para ajustar SC9 e faturar diretor)
@author MarceloLauschner
@since 20/09/2009
@version 1.0
@param Numero do Pedido a verificar liberação
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stAjustaErrC9(cPedFat)

	Local 	cQry 	 := ""
	Local 	nQteLib  := 0
	Local   nQteBlq	 := 0
	Local 	nVlrCred := 0
	Local 	aLib	 := {.T.,.T.,.F.,.F.}  //

	cQry += "SELECT C9_XWMSQTE,C9_QTDLIB,C9_PEDIDO,C9_ITEM,C9_SEQUEN,C9_PRODUTO,C9_XWMSEDI,C9_XWMSPED,C9_XWMSQTE,C9_BLINF,C9_LIBFAT,C9_ORDSEP "
	cQry += "  FROM " + RetSqlName("SC9")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_FLGENVI <> ' ' "
	cQry += "   AND C9_XWMSPED <> 9999999 " // Evita que seja feito o ajuste de pedidos que foram manualmente para a separação
	cQry += "   AND C9_NFISCAL = '  ' "
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_PEDIDO =  '" +cPedFat+"' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "

	TCQUERY cQry NEW ALIAS "QRC9"

	While !Eof()

		nQteLib	:= QRC9->C9_XWMSQTE
		nQteBlq 	:= QRC9->C9_QTDLIB

		// Se houver diferença entre a quantidade liberada e a quantidade separada e conferida
		If QRC9->C9_QTDLIB <> nQteLib
			DbSelectArea ("SC9")
			DbSetOrder(1)
			If DbSeek(xfilial("SC9")+QRC9->C9_PEDIDO+QRC9->C9_ITEM+QRC9->C9_SEQUEN+QRC9->C9_PRODUTO)

				// Executa Estorno do Item
				SC9->(A460Estorna(/*lMata410*/,/*lAtuEmp*/,@nVlrCred))
				// Cad. item do pedido de venda
				DbSelectArea("SC6")
				SC6->(DbSetOrder(1))
				SC6->(DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM

				// Se a quantidade conferida for maior que zero -- evita que quantidades zeradas possam ser liberadas.
				If nQteLib > 0	// Garante que o Flag de separação vá para o novo item liberado
					MaLibDoFat(SC6->(RecNo()),nQteLib,aLib[1],aLib[2],aLib[3],aLib[4],.F.,.F.,/*aEmpenho*/,{|| SC9->C9_XWMSEDI := QRC9->C9_XWMSEDI,SC9->C9_XWMSPED := QRC9->C9_XWMSPED,SC9->C9_BLINF := QRC9->C9_BLINF,SC9->C9_FLGENVI := "E",SC9->C9_LIBFAT := STOD(QRC9->C9_LIBFAT),SC9->C9_XWMSQTE := QRC9->C9_XWMSQTE,SC9->C9_ORDSEP := QRC9->C9_ORDSEP }/*bBlock*/,/*aEmpPronto*/,/*lTrocaLot*/,/*lOkExpedicao*/,nVlrCred,/*nQtdalib2*/)
				Endif
				// A quantidade não separada é liberada com bloqueio de estoque
				nQteBlq	-= nQteLib
				If nQteBlq > 0
					MaLibDoFat(SC6->(RecNo()),nQteBlq,.T./*lCredito*/,.F./*lEstoque*/,.F./*lAvCred*/,.F./*lAvEst*/,.F./*lLibPar*/,.F./*lTrfLocal*/,/*aEmpenho*/,/*bBlock*/,/*aEmpPronto*/,/*lTrocaLot*/,/*lOkExpedicao*/,nVlrCred,/*nQtdalib2*/)
				Endif
				SC6->(MaLiberOk({SC9->C9_PEDIDO},.F.))

			Endif
		Endif
		DbSelectArea("QRC9")
		DbSkip()
	Enddo
	QRC9->(DbCloseArea())
Return

/*/{Protheus.doc} stGravaF2
(Gerar nota Fiscal a partir do pedido informado)
@author MarceloLauschner
@since 18/09/2009
@version 1.0
@param cPedFat - Numero do Pedido de Venda
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stGravaF2(cPedFat,lFatRemessa)

	Local 	cQry 			:= ""
	Local 	nReg 			:= 0
	Local 	cNota			:= ""
	Local	cNfBon			:= ""
	Local 	cSerie			:= GetMv("GM_SERIENF")
	Local	cNewPedRem		:= ""
	Local 	cNewPedVas		:= ""
	Local	lContOnLine	    := GetNewPar("GM_CTBONLN",.T.) // Chamado 26183 - Adicionado Onix para contabilizar online 
	Local	lExistRem		:= .F.
	Local 	lExistb5Vas		:= .F. 
	Local 	aRegB5Vas		:= {}
	Local	aRegSC9PedRem	:= {}
	Private aPvlNfs 		:= {}
	Private aPvlBon			:= {}
	Private aPvlSer3		:= {}

	Private lMsHelpAuto 	:= .T.
	Private lMsErroAuto 	:= .F.
	Default lFatRemessa	:= .F.

	cQry := ""
	cQry += "SELECT C9_PEDIDO,C9_ITEM,C9_PRODUTO,C9_QTDLIB,C9_SEQUEN "
	cQry += "  FROM " + RetSqlName("SC9")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	//cQry += "   AND C9_COLETOR != '   ' " // Este flag não pode ser retirado
	If !lFatRemessa
		cQry += "   AND (C9_XWMSPED = 9999999 OR C9_XWMSQTE > 0 )"
	Endif
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_PEDIDO =  '" +cPedFat+"' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
	cQry += " ORDER BY C9_PEDIDO, C9_ITEM, C9_SEQUEN "

	TCQUERY cQry NEW ALIAS "QRYC9"

	Count to nReg

	dbSelectArea("QRYC9")
	dbGoTop()
	ProcREgua(nReg)
	While !Eof()

		IncProc("Processando pedido -> "+cPedFat+" item -> "+QRYC9->C9_ITEM+" - "+QRYC9->C9_PRODUTO)

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+QRYC9->C9_PEDIDO)

		DbSelectArea ("SC9")
		DbSetOrder(1)
		If DbSeek(xfilial("SC9")+QRYC9->C9_PEDIDO+QRYC9->C9_ITEM+QRYC9->C9_SEQUEN+QRYC9->C9_PRODUTO)

			// Cad. item do pedido de venda
			SC6->(DbSetOrder(1))
			SC6->(DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM


			// Verifica se existe o campo que controla lote de produção e se houve preenchimento da informação de produção
			If SC6->(FieldPos("C6_XPA2LIN")) > 0 .And. !Empty(SC6->C6_XPA2NUM) .And. QRYC9->C9_PRODUTO $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
				// Se a quantidade não for exatamente os 159 litros , não irá mais faturar parcial o Granel
				If QRYC9->C9_QTDLIB <> 159
					Dbselectarea("QRYC9")
					Dbskip()
					Loop
				ElseIf SC5->C5_TIPO == "N"
					lExistRem	:=	.T.
				Endif
			Endif

			// Chamado 25.866 - Verifica se o produto precisa gerar nota auxiliar de remessa de vasilhame
			DbSelectArea("SB5")
			DbSetorder(1)
			If SB5->(FieldPos("B5_XPRDVAS")) > 0 .And. SC5->C5_TIPO == "N"
				If SB5->(DbSeek(xFilial("SB5") + QRYC9->C9_PRODUTO ))
					If !Empty(SB5->B5_XPRDVAS)
						Aadd(aRegB5Vas,{SB5->B5_XPRDVAS,SC9->(Recno()) , QRYC9->C9_PRODUTO ,QRYC9->C9_QTDLIB})
					Endif
				Endif
			Endif


			// 05/03/2016 - Marcelo Lauschner - Adiciona os itens liberados da SC9 que irão gerar nota para localizar corretamente o Granel
			DbSelectArea ("SC9")
			Aadd(aRegSC9PedRem,SC9->(Recno()))

			// 09/08/2013 - Marcelo Lauschner - Verifica se o pedido tem tambores com remessa de vasilhame

			cPedini := QRYC9->C9_PEDIDO
			//Cad. pedido de venda cab.
			SC5->(DbSetOrder(1))
			SC5->(DbSeek(xFilial("SC5")+SC9->C9_PEDIDO) )                  //FILIAL+NUMERO
			// Cad. item do pedido de venda
			SC6->(DbSetOrder(1))
			SC6->(DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM
			// Força ajuste de preço de tabela
			If SC6->C6_PRUNIT == 0
				DbSelectArea("SC6")
				RecLock("SC6",.F.)
				SC6->C6_PRUNIT	:= SC6->C6_PRCVEN
				MsUnlock()
			Endif


			// Cad. Condicao de Pgto
			SE4->(DbSetOrder(1))
			SE4->(DbSeek(xFilial("SE4")+SC5->C5_CONDPAG) )               //FILIAL+NUMERO+ITEM+PRODUTO
			// Cad. Produtos
			SB1->(DbSetOrder(1))
			SB1->(DbSeek(xFilial("SB1")+SC6->C6_PRODUTO) )                //FILIAL+PRODUTO
			// Cadastro Saldos Estoque
			SB2->(DbSetOrder(1))
			SB2->(DbSeek(xFilial("SB2")+SC6->C6_PRODUTO+SC6->C6_LOCAL) )  //FILIAL+PRODUTO+LOCAL
			// Cadastro TES
			SF4->(DbSetOrder(1))
			SF4->(DbSeek(xFilial("SF4")+SC6->C6_TES) )                   //FILIAL+CODIGO


			// Validação adicionada em 19/12/2012 afins de verifica se há produtos que devam ser faturados pela série 3 de NFe
			If cEmpAnt+cFilAnt $ "0201" .And. Substr(SC9->C9_PRODUTO,1,1) == "I" .And. SC9->C9_GRUPO $ GetNewPar("BF_GRPIMPT","1135#1160#1161#1162#1163#1170#1180")

				Aadd(aPvlSer3,{SC6->C6_NUM,;
					SC6->C6_ITEM,;
					SC9->C9_SEQUEN,;
					SC9->C9_QTDLIB,;
					SC6->C6_PRCVEN,;
					SC6->C6_PRODUTO,;
					.F.,;
					SC9->(RecNo()),;
					SC5->(RecNo()),;
					SC6->(RecNo()),;
					SE4->(RecNo()),;
					SB1->(RecNo()),;
					SB2->(RecNo()),;
					SF4->(RecNo()),;
					sb2->B2_LOCAL,;
					0,;
					SC9->C9_QTDLIB2})
			Else

				// Se gera duplicata agrupa numa nota fiscal, demais itens vão para outra nota
				// Chamado 8302 - Leandro Mazonetto
				// Separar Brindes em nota diferente
				If SF4->F4_DUPLIC = "S"
					Aadd(aPvlNfs,{SC6->C6_NUM,;
						SC6->C6_ITEM,;
						SC9->C9_SEQUEN,;
						SC9->C9_QTDLIB,;
						SC6->C6_PRCVEN,;
						SC6->C6_PRODUTO,;
						.F.,;
						SC9->(RecNo()),;
						SC5->(RecNo()),;
						SC6->(RecNo()),;
						SE4->(RecNo()),;
						SB1->(RecNo()),;
						SB2->(RecNo()),;
						SF4->(RecNo()),;
						sb2->B2_LOCAL,;
						0,;
						SC9->C9_QTDLIB2})

				Else
					Aadd(aPvlBon,{SC6->C6_NUM,;
						SC6->C6_ITEM,;
						SC9->C9_SEQUEN,;
						SC9->C9_QTDLIB,;
						SC6->C6_PRCVEN,;
						SC6->C6_PRODUTO,;
						.F.,;
						SC9->(RecNo()),;
						SC5->(RecNo()),;
						SC6->(RecNo()),;
						SE4->(RecNo()),;
						SB1->(RecNo()),;
						SB2->(RecNo()),;
						SF4->(RecNo()),;
						sb2->B2_LOCAL,;
						0,;
						SC9->C9_QTDLIB2})
				Endif
			Endif
		Else
			MsgAlert("Item não encontrado na liberacao do pedido - "+QRYC9->C9_PEDIDO+"-"+QRYC9->C9_ITEM,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Sem registros!")
			Return
		EndIF
		Dbselectarea("QRYC9")
		Dbskip()
	Enddo

	QRYC9->(DbCloseArea())

	// Efetua a geração de nota fiscal de produtos que geram duplicata
	If Len(aPvlNfs) > 0

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ mv_par01 Mostra Lan‡.Contab     ?  Sim/Nao                         ³
		//³ mv_par02 Aglut. Lan‡amentos     ?  Sim/Nao                         ³
		//³ mv_par03 Lan‡.Contab.On-Line    ?  Sim/Nao                         ³
		//³ mv_par04 Contb.Custo On-Line    ?  Sim/Nao                         ³
		//³ mv_par05 Reaj. na mesma N.F.    ?  Sim/Nao                         ³
		//³ mv_par06 Taxa deflacao ICMS     ?  Numerico                        ³
		//³ mv_par07 Metodo calc.acr.fin    ?  Taxa defl/Dif.lista/% Acrs.ped  ³
		//³ mv_par08 Arred.prc unit vist    ?  Sempre/Nunca/Consumid.final     ³
		//³ mv_par09 Agreg. liberac. de     ?  Caracter                        ³
		//³ mv_par10 Agreg. liberac. ate    ?  Caracter                        ³
		//³ mv_par11 Aglut.Ped. Iguais      ?  Sim/Nao                         ³
		//³ mv_par12 Valor Minimo p/fatu    ?                                  ³
		//³ mv_par13 Transportadora de      ?                                  ³
		//³ mv_par14 Transportadora ate     ?                                  ³
		//³ mv_par15 Atualiza Cli.X Prod    ?                                  ³
		//³ mv_par16 Emitir                 ?  Nota / Cupom Fiscal             ³
		//³ mv_par17 Gera Titulo            ?  Sim/Nao                         ³
		//³ mv_par18 Gera guia recolhimento ?  Sim/Nao                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Pergunte("MT460A",.F.)


		cNota   := MaPvlNfs(aPvlNfs,cSerie	, .F.      , .T.     , lContOnLine, .F.     , .F.     , 0      , 0          , .T.   , .F. )
		//cNota := MaPvlNfs(aPvlNfs,cSerie  ,lMostraCtb,lAglutCtb,lCtbOnLine  ,lCtbCusto,lReajusta,nCalAcrs,nArredPrcLis,lAtuSA7,lECF,cembexp)

		//If lMsErroAuto
		//	DisarmTransaction()
		//	break
		//EndIf
	Endif

	// Efetua a geração de nota somente dos itens que não geram Duplicata
	If Len(aPvlBon) > 0

		Pergunte("MT460A",.F.)

		cNfBon   := MaPvlNfs(aPvlBon,cSerie	, .F.      , .T.     , lContOnLine, .F.     , .F.     , 0      , 0          , .T.   , .F. )

		If !Empty(cNota)
			cNota	+= " / "
		Endif
		cNota	+= cNfBon
		// 	Zero os volumes herdados da SC5 para evitar duplicidade de volumes na expedição de notas
		If Len(aPvlNfs) > 0
			DbSelectArea("SF2")
			DbSetOrder(1)
			If DbSeek(xFilial("SF2")+Padr(cNfBon,Len(SF2->F2_DOC))+cSerie)
				RecLock("SF2",.F.)
				SF2->F2_ESPECI1	:= ""
				SF2->F2_VOLUME1	:= 0
				MsUnlock()
			Endif
		Endif
	Endif

	// Efetua o faturamento somente de produtos importados como série 3
	If Len(aPvlSer3) > 0

		Pergunte("MT460A",.F.)
		cSerie	:= "3"
		MsgAlert("Será gerada nota fiscal na Série '3'. Favor atentar para a transmissão e autorização na Sefaz!","Nota fiscal Série '3'")
		If !Empty(cNota)
			cNota	+= " / "
		Endif
		cNota   += MaPvlNfs(aPvlSer3,cSerie	, .F.      , .T.     , lContOnLine, .F.     , .F.     , 0      , 0          , .T.   , .F. )
	Endif


	If lExistRem
		cNewPedRem	:= sfGeraPvRm(cPedFat,aRegSC9PedRem)
		If Empty(cNewPedRem)
			cMensagem := "Pedido "+cPedFat + " não gerou pedido de remessa de Vasilhame"
			U_WFGERAL("informatica1@atrialub.com.br;marcelo@centralxml.com.br","Erro de geração de pedido Remessa Granel",cMensagem,"FPDC_002")
		Endif
	Endif

	If Len(aRegB5Vas) > 0
		cNewPedVas	:= sfGerPdVas(cPedFat,aRegB5Vas)
		lExistb5Vas	:= .T. 
		If Empty(cNewPedVas)
			cMensagem := "Pedido "+cPedFat + " não gerou pedido de remessa de Vasilhame"
			U_WFGERAL("informatica1@atrialub.com.br;marcelo@centralxml.com.br","Erro de geração de pedido Remessa Granel",cMensagem,"FPDC_002")
		Endif

	Endif


Return {cSerie +"-"+cNota,cNewPedRem,lExistRem,Substr(cNota,1,TamSX3("F2_DOC")[1]),cSerie,lExistb5Vas,cNewPedVas}



/*/{Protheus.doc} sfReimp
(Efetua a reimpressão de pedido padrão de separação   )
@author MarceloLauschner
@since 18/06/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfReimp()

	Private aResumo		:= {}
	Private cNumLote	:= ""

	&("StaticCall(FPDC_001,sfLoteSZA)")

	// Chama função de envio para separação, para manter compatibilidade de dados e aparencia
	&("StaticCall(FPDC_001,sfGvs,aSC9[oSC9:nAt,3],.F.)")

	If Len(aResumo) > 0
		If MsgYesNo("A impressora está configurada corretamente??","Atenção. Verificação.")
			&("StaticcALL(FPDC_001,Impr,.T.)") // Chama a impressão do resumo dos pedidos faturados e exportados para uso do deposito.
		Endif
	Endif

Return


/*/{Protheus.doc} FPDC002A
(Função que permite gerar o pedido de venda e faturamento quando não aconteceu a remessa de vasilhames)
@author MarceloLauschner
@since 05/11/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FPDC002A()

	RpcSetType(3)
	//RpcSetEnv - Abertura do ambiente em rotinas automáticas ( [ cRpcEmp ] [ cRpcFil ] [ cEnvUser ] [ cEnvPass ] [ cEnvMod ] [ cFunName ] [ aTables ] [ lShowFinal ] [ lAbend ] [ lOpenSX ] [ lConnect ] ) --> lRet
	RPCSetEnv("02","01","marcelo alberto","943716","FAT",,{"SC5","SC6","SB5"})


	sfGrRem("212405")

Return

/*/{Protheus.doc} sfGrRem
(Executa a criação do pedido de venda de remessa e seu respectivo faturamento)
@author MarceloLauschner
@since 05/11/2014
@version 1.0
@param cInPed, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrRem(cInPed)
	Local	iZ

	aRecPA2	:= {}
	cNfFats	:= ""

	cNumPedRem	:= sfGeraPvRm(cInPed)

	cNumPedRem	:= sfGerPdVas(cInPed)


	aRetFat		:= stGravaF2(cNumPedRem,.T.)
	cNumNota	:= aRetFat[1]
	cNfFats += cNumNota + " / "
	// Grava Log
	U_GMCFGM01("EC",cNumPedRem,"Num.NF:"+cNumNota,FunName())

	//MsgAlert(cNfFats)

	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cNumPedRem)
	If SC5->C5_TIPO $ "D#B"
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
	Else
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
	Endif

	For iZ := 1 To Len(aRecPA2)
		DbSelectArea("PA2")
		DbGoto(aRecPA2[iZ])
		RecLock("PA2",.F.)
		PA2->PA2_NUMNF	:= aRetFat[4]
		PA2->PA2_SERIE	:= aRetFat[5]
		PA2->PA2_CGCREM	:= Iif(SC5->C5_TIPO $ "D#B",SA2->A2_CGC,SA1->A1_CGC)
		MsUnlock()
	Next

Return

/*/{Protheus.doc} sfGeraPvRm
(Gerar pedido de venda para Remessa de Vasilhame   )
@author MarceloLauschner
@since 08/08/2013
@version 1.0
@param cInPed, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGeraPvRm(cInPed,aRegSC9PedRem)

	Local	aAreaOld		:= GetArea()
	Local	lFirst			:= .T.
	Local	aCabPv			:= {}
	Local	aItemPv			:= {}
	Local	cRetPed			:= ""
	Local	cItem			:= "00"
	Local	cMsgNfe			:= "Identificacao tambores="
	Local	is
	Local	cMensagem
	Local	cNextAlias
	Local	aItem
	Local	cArqLog

	Default	aRegSC9PedRem	:= {}
	Private lMsHelpAuto 	:= .F.
	Private lMsErroAuto 	:= .F.

	// Força a rotina a aceitar a quantidade sugerida para liberar o pedido automaticamente
	U_GRAVASX1("MTA410","01",1)

	If Type("aRecPA2") <> "A"
		aRecPA2	:= {}
	Endif

	// Se existirem os registros da SC9 irá pegar somente o que de fato foi faturado, para evitar envio de vasilhames de itens que tenha bloqueio de estoque.
	If Len(aRegSC9PedRem) > 0
		For iS := 1 To Len(aRegSC9PedRem)

			DbSelectArea("SC9")
			DbGoto(aRegSC9PedRem[iS])
			DbSelectArea("SC6")
			DbSetOrder(1)
			If DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM+SC9->C9_PRODUTO)

				If lFirst
					DbSelectArea("SC5")
					DbSetOrder(1)
					DbSeek(xFilial("SC5")+cInPed)
					aCabPV := {	{"C5_TIPO"			,"N"			             ,Nil},; // Tipo de pedido
					{"C5_CLIENTE"       ,SC5->C5_CLIENTE		    			 ,Nil},; // Codigo do cliente
					{"C5_LOJACLI"       ,SC5->C5_LOJACLI		    			 ,Nil},; // Loja do cliente
					{"C5_TIPOCLI"       ,SC5->C5_TIPOCLI            			 ,Nil},; // Tipo do cliente
					{"C5_PROPRI"        ,SC5->C5_PROPRI             			 ,Nil},; // Tipo do cliente
					{"C5_CONDPAG"       ,"128"									 ,Nil},; // Codigo da condicao de pagamanto*
					{"C5_TPFRETE"       ,SC5->C5_TPFRETE   			 			 ,Nil},; // Tipo Frete
					{"C5_TRANSP"        ,SC5->C5_TRANSP							 ,Nil},; // Transportadora
					{"C5_VEND1"         ,SC5->C5_VEND1            			 	 ,Nil},; // Vendedor
					{"C5_VEND2"         ,SC5->C5_VEND2               		  	 ,Nil},; // Vendedor2
					{"C5_REEMB"			,"N"						 			 ,Nil},; // Reembolso de Tampa
					{"C5_MSGINT"        ,"Remessa de vasilhame. Acompanha Pedido '"+SC5->C5_NUM+"'" ,Nil}} // Tipo de Liberacao
					lFirst	:= .F.
				Endif

				cNextAlias	:= GetNextAlias()
				BeginSql Alias cNextAlias
					SELECT N1_PRODUTO,N1_CHAPA,N1_DESCRIC,PA2_CHAPA,PA2_LACRE,PA2.R_E_C_N_O_ PA2RECNO
					FROM %Table:SN1% SN1, %Table:PA2% PA2
					WHERE SN1.%NotDel%
					AND N1_CHAPA = PA2_CHAPA
					AND N1_BAIXA = ' '
					AND N1_FILIAL = %xFilial:SN1%
					AND PA2.%NotDel%
					AND PA2_FILIAL = %xFilial:PA2%
					AND PA2_LINHA = %Exp:SC6->C6_XPA2LIN%
					AND PA2_NUM = %Exp:SC6->C6_XPA2NUM%
					UNION ALL
					SELECT ATB_CODIGO,ATB_CHAPA,ATB_DESCRI,PA2_CHAPA,PA2_LACRE,PA2.R_E_C_N_O_ PA2RECNO
					FROM BIGFORTA_ATFTB AT, %Table:PA2% PA2
					WHERE ATB_CHAPA = PA2_CHAPA
					AND ATB_FIL = %xFilial:SN1%
					AND PA2.%NotDel%
					AND PA2_FILIAL = %xFilial:PA2%
					AND PA2_LINHA = %Exp:SC6->C6_XPA2LIN%
					AND PA2_NUM = %Exp:SC6->C6_XPA2NUM%
			
				EndSql
				If !Eof()
					cItem	:= Soma1(cItem)
					DbSelectArea("SB1")
					DbSetOrder(1)
					DbSeek(xFilial("SB1")+(cNextAlias)->N1_PRODUTO)

					aItem := {	{"C6_ITEM"		 ,cItem								,Nil},;	// Item
					{"C6_PRODUTO"  	,(cNextAlias)->N1_PRODUTO	             		,Nil},; // Codigo do Produto
					{"C6_QTDVEN"   	,1												,Nil},; // Quantidade Vendida
					{"C6_QTDLIB"	,1												,Nil},;  // Quantidade Liberada
					{"C6_OPER"		,"VS"											,Nil},;	// TES inteligente
					{"C6_PRCVEN"	,SB1->B1_PRV1									,Nil},;
						{"C6_VALDESC"	,0												,Nil},;	// Valor do Desconto
					{"C6_XPA2NUM"	,SC6->C6_XPA2NUM								,Nil},;
						{"C6_XPA2LIN"	,SC6->C6_XPA2LIN								,Nil}}

					cMsgNfe	+= Alltrim((cNextAlias)->PA2_CHAPA)+"/"
					Aadd(aItemPV,aItem)
					// Alimento variavel que controlará a baixa da produção
					Aadd(aRecPA2,(cNextAlias)->PA2RECNO)
				Endif

				(cNextAlias)->(DbCloseArea())
			Endif
		Next

	Else

		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+cInPed)
		While !Eof() .And. SC6->C6_NUM == cInPed

			If lFirst
				DbSelectArea("SC5")
				DbSetOrder(1)
				DbSeek(xFilial("SC5")+cInPed)
				aCabPV := {	{"C5_TIPO"			,"N"			             ,Nil},; // Tipo de pedido
				{"C5_CLIENTE"       ,SC5->C5_CLIENTE		    			 ,Nil},; // Codigo do cliente
				{"C5_LOJACLI"       ,SC5->C5_LOJACLI		    			 ,Nil},; // Loja do cliente
				{"C5_TIPOCLI"       ,SC5->C5_TIPOCLI            			 ,Nil},; // Tipo do cliente
				{"C5_PROPRI"        ,SC5->C5_PROPRI             			 ,Nil},; // Tipo do cliente
				{"C5_CONDPAG"       ,"128"									 ,Nil},; // Codigo da condicao de pagamanto*
				{"C5_TPFRETE"       ,SC5->C5_TPFRETE   			 			 ,Nil},; // Retirar transportadora
				{"C5_TRANSP"        ,SC5->C5_TRANSP							 ,Nil},; // Transportadora
				{"C5_VEND1"         ,SC5->C5_VEND1            			 	 ,Nil},; // Vendedor
				{"C5_VEND2"         ,SC5->C5_VEND2               		  	 ,Nil},; // Vendedor2
				{"C5_REEMB"			,"N"						 			 ,Nil},; // Reembolso de Tampa
				{"C5_MSGINT"        ,"Remessa de vasilhame. Acompanha Pedido '"+SC5->C5_NUM+"'" ,Nil}} // Tipo de Liberacao
				lFirst	:= .F.
			Endif

			cNextAlias	:= GetNextAlias()
			BeginSql Alias cNextAlias
				SELECT N1_PRODUTO,N1_CHAPA,N1_DESCRIC,PA2_CHAPA,PA2_LACRE,PA2.R_E_C_N_O_ PA2RECNO
				FROM %Table:SN1% SN1, %Table:PA2% PA2
				WHERE SN1.%NotDel%
				AND N1_CHAPA = PA2_CHAPA
				AND N1_BAIXA = '  '
				AND N1_FILIAL = %xFilial:SN1%
				AND PA2.%NotDel%
				AND PA2_FILIAL = %xFilial:PA2%
				AND PA2_LINHA = %Exp:SC6->C6_XPA2LIN%
				AND PA2_NUM = %Exp:SC6->C6_XPA2NUM%
				UNION ALL
				SELECT ATB_CODIGO,ATB_CHAPA,ATB_DESCRI,PA2_CHAPA,PA2_LACRE,PA2.R_E_C_N_O_ PA2RECNO
				FROM BIGFORTA_ATFTB AT, %Table:PA2% PA2
				WHERE ATB_CHAPA = PA2_CHAPA
				AND ATB_FIL = %xFilial:SN1%
				AND PA2.%NotDel%
				AND PA2_FILIAL = %xFilial:PA2%
				AND PA2_LINHA = %Exp:SC6->C6_XPA2LIN%
				AND PA2_NUM = %Exp:SC6->C6_XPA2NUM%
			
			EndSql
			If !Eof()
				cItem	:= Soma1(cItem)
				DbSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+(cNextAlias)->N1_PRODUTO)

				aItem := {	{"C6_ITEM"		 ,cItem								,Nil},;	// Item
				{"C6_PRODUTO"  	,(cNextAlias)->N1_PRODUTO	             		,Nil},; // Codigo do Produto
				{"C6_QTDVEN"   	,1												,Nil},; // Quantidade Vendida
				{"C6_QTDLIB"	,1												,Nil},;  // Quantidade Liberada
				{"C6_OPER"		,"VS"											,Nil},;	// TES inteligente
				{"C6_PRCVEN"	,SB1->B1_PRV1									,Nil},;
					{"C6_VALDESC"	,0												,Nil},;	// Valor do Desconto
				{"C6_XPA2NUM"	,SC6->C6_XPA2NUM								,Nil},;
					{"C6_XPA2LIN"	,SC6->C6_XPA2LIN								,Nil}}

				cMsgNfe	+= Alltrim((cNextAlias)->PA2_CHAPA)+"/"
				Aadd(aItemPV,aItem)
				// Alimento variavel que controlará a baixa da produção
				Aadd(aRecPA2,(cNextAlias)->PA2RECNO)

			Else
				MsgAlert("Não achou registro na PA2 '" + SC6->C6_XPA2NUM + "/" + SC6->C6_XPA2LIN + "'.")
			Endif

			(cNextAlias)->(DbCloseArea())
			DbSelectArea("SC6")
			DbSkip()
		Enddo
	Endif
	// IAGO 27/07/2015 Chamado(11044)
	Aadd(aCabPV,{"C5_MENNOTA"	,cMsgNfe	,Nil})

	If Len(aItemPv) > 0

		Begin Transaction
			MSExecAuto({|x,y,z|Mata410(x,y,z)},aCabPV,aItemPV,3)
		End Transaction

		If lMsErroAuto
			//MostraErro()
			cArqLog := cInPed + "" +Alltrim(SubStr(Time(),1,5 )) + ".log"

			cMensagem	:= "Erro geração de pedido de remessa vasilhame para acompanhar o pedido" +cInPed+" em "+DTOC(dDataBase) + " às " + Time()+ CRLF
			cMensagem += MostraErro("\logs", cArqLog)

			U_WFGERAL("informatica1@atrialub.com.br;marcelo@centralxml.com.br","Erro geração de pedido de remessa vasilhame",cMensagem,"FPDC_002")
			//DisarmTransaction()
		Else
			cRetPed	:= SC5->C5_NUM
		Endif
	Else
		MsgAlert("Não foi possível gerar automaticamente o pedido de Venda para Remessa de vasilhame!. É necessário informar o departamento fiscal","Remessa de vasilhame")

	Endif

	RestArea(aAreaOld)

Return cRetPed



/*/{Protheus.doc} sfGerPdVas
Função para gerar Remessa de vasilhame de pedidos que contém produtos que precisam da remessa auxiliar 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/05/2021
@param cInPed, character, Pedido original 
@param aRegB5Vas, array, Array com dados dos itens do pedido que precisam de remessa 
@return return_type, return_description
/*/
Static Function sfGerPdVas(cInPed,aRegB5Vas)

	Local	aAreaOld		:= GetArea()
	Local	lFirst			:= .T.
	Local	aCabPv			:= {}
	Local	aItemPv			:= {}
	Local	cRetPed			:= ""
	Local	cItem			:= "00"
	Local	cMsgNfe			:= "Identificação Produtos="
	Local	is
	Local	cMensagem
	Local	aItem
	Local	cArqLog

	Default	aRegB5Vas		:= {}
	Private lMsHelpAuto 	:= .F.
	Private lMsErroAuto 	:= .F.

	// Força a rotina a aceitar a quantidade sugerida para liberar o pedido automaticamente
	U_GRAVASX1("MTA410","01",1)

	// Verifica que foi passado vazio o valor e procura no pedido com os itens já faturados 
	If Len(aRegB5Vas) == 0

		cQry := ""
		cQry += "SELECT C9_PEDIDO,C9_ITEM,C9_PRODUTO,C9_QTDLIB,C9_SEQUEN "
		cQry += "  FROM " + RetSqlName("SC9")
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND C9_NFISCAL <>  '      ' "
		cQry += "   AND C9_BLEST = '10' "
		cQry += "   AND C9_BLCRED = '10' "
		cQry += "   AND C9_PEDIDO =  '" +cInPed+"' "
		cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
		cQry += " ORDER BY C9_PEDIDO, C9_ITEM, C9_SEQUEN "

		TCQUERY cQry NEW ALIAS "QRYC9"

		While !Eof()


			DbSelectArea ("SC9")
			DbSetOrder(1)
			If DbSeek(xfilial("SC9")+QRYC9->C9_PEDIDO+QRYC9->C9_ITEM+QRYC9->C9_SEQUEN+QRYC9->C9_PRODUTO)

				DbSelectArea("SB5")
				DbSetorder(1)
				If SB5->(FieldPos("B5_XPRDVAS")) > 0
					If SB5->(DbSeek(xFilial("SB5") + QRYC9->C9_PRODUTO ))
						If !Empty(SB5->B5_XPRDVAS)
							Aadd(aRegB5Vas,{SB5->B5_XPRDVAS,SC9->(Recno()) , QRYC9->C9_PRODUTO ,QRYC9->C9_QTDLIB})
						Endif
					Endif
				Endif
			Endif
			Dbselectarea("QRYC9")
			Dbskip()
		Enddo
		QRYC9->(DbCloseArea())
	Endif

	If Len(aRegB5Vas) > 0
		For iS := 1 To Len(aRegB5Vas)

			DbSelectArea("SC9")
			DbGoto(aRegB5Vas[iS,2]) // Posiciona no Recno da SC9
			DbSelectArea("SC6")
			DbSetOrder(1)
			If DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM+SC9->C9_PRODUTO)

				If lFirst
					DbSelectArea("SC5")
					DbSetOrder(1)
					DbSeek(xFilial("SC5")+cInPed)
					aCabPV := {	{"C5_TIPO"			,"N"			             ,Nil},; // Tipo de pedido
					{"C5_CLIENTE"       ,SC5->C5_CLIENTE		    			 ,Nil},; // Codigo do cliente
					{"C5_LOJACLI"       ,SC5->C5_LOJACLI		    			 ,Nil},; // Loja do cliente
					{"C5_TIPOCLI"       ,SC5->C5_TIPOCLI            			 ,Nil},; // Tipo do cliente
					{"C5_PROPRI"        ,SC5->C5_PROPRI             			 ,Nil},; // Tipo do cliente
					{"C5_CONDPAG"       ,"128"									 ,Nil},; // Codigo da condicao de pagamanto*
					{"C5_TPFRETE"       ,SC5->C5_TPFRETE   			 			 ,Nil},; // Tipo Frete
					{"C5_TRANSP"        ,SC5->C5_TRANSP							 ,Nil},; // Transportadora
					{"C5_VEND1"         ,SC5->C5_VEND1            			 	 ,Nil},; // Vendedor
					{"C5_VEND2"         ,SC5->C5_VEND2               		  	 ,Nil},; // Vendedor2
					{"C5_REEMB"			,"N"						 			 ,Nil},; // Reembolso de Tampa
					{"C5_MSGINT"        ,"Remessa de vasilhame. Acompanha Pedido "+SC5->C5_NUM ,Nil}} // Tipo de Liberacao
					lFirst	:= .F.
				Endif

				cItem	:= Soma1(cItem)
				DbSelectArea("SB1")
				DbSetOrder(1)
				If DbSeek(xFilial("SB1")+aRegB5Vas[iS,1]) // Posiciona no Produto Vasilhame

					aItem := {	;
					{"C6_ITEM"		,cItem											,Nil},;	// Item
					{"C6_PRODUTO"  	,SB1->B1_COD				             		,Nil},; // Codigo do Produto
					{"C6_QTDVEN"   	,aRegB5Vas[iS,4]								,Nil},; // Quantidade Vendida
					{"C6_QTDLIB"	,aRegB5Vas[iS,4]								,Nil},; // Quantidade Liberada
					{"C6_OPER"		,"VS"											,Nil},;	// TES inteligente
					{"C6_PRCVEN"	,SB1->B1_PRV1									,Nil},;
					{"C6_VALDESC"	,0												,Nil}}	// Valor do Desconto

					cMsgNfe	+= Alltrim(aRegB5Vas[iS,3])+"/" // Produto original que gerou a necessidade do Vasilhame
					Aadd(aItemPV,aItem)
				Endif

			Endif
		Next
		Aadd(aCabPV,{"C5_MENNOTA"	,cMsgNfe	,Nil})

		If Len(aItemPv) > 0

			Begin Transaction
				MSExecAuto({|x,y,z|Mata410(x,y,z)},aCabPV,aItemPV,3)
			End Transaction

			If lMsErroAuto
				//MostraErro()
				cArqLog := cInPed + "" +Alltrim(SubStr(Time(),1,5 )) + ".log"

				cMensagem	:= "Erro geração de pedido de remessa vasilhame para acompanhar o pedido " +cInPed+" em "+DTOC(dDataBase) + " às " + Time()+ CRLF
				cMensagem += MostraErro("\logs", cArqLog)

				U_WFGERAL("informatica1@atrialub.com.br;marcelo@centralxml.com.br","Erro geração de pedido de remessa vasilhame",cMensagem,"FPDC_002")
				//DisarmTransaction()
			Else
				cRetPed	:= SC5->C5_NUM
			Endif
		Else
			MsgAlert("Não foi possível gerar automaticamente o pedido de Venda para Remessa de vasilhame!. É necessário informar o departamento fiscal","Remessa de vasilhame")

		Endif
	Endif

	RestArea(aAreaOld)

Return cRetPed


/*/{Protheus.doc} sfAltInverte
(long_description)
@author MarceloLauschner
@since 13/06/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAltInverte()

	Local	cTransp		:= Space(6)
	Local	lContinua	:= .F.
	Local	x

	If lTransp

		lTransp	:= .F.

		DEFINE MSDIALOG oPerg FROM 001,001 TO 150,350 OF oMainWnd PIXEL TITLE OemToAnsi("Defina a transportadora para os pedidos Selecionados")

		oPanelc := TPanel():New(0,0,'',oPerg, oPerg:oFont, .T., .T.,, ,200,40,.T.,.T. )
		oPanelc:Align := CONTROL_ALIGN_ALLCLIENT

		@ 005,020 SAY "Transportadora" of oPanelc pixel
		@ 003,085 MSGET cTransp F3 "SA4" of oPanelc Pixel

		ACTIVATE MSDIALOG oPerg ON INIT EnchoiceBar(oPerg,{|| lContinua	:= .T. /*true*/,oPerg:End()},{|| oPerg:End()},,) CENTERED

		//verifica se existem pedidos marcados para continuar
		If !lContinua
			For x := 1 To Len(aSC9)
				aSC9[x,2]	:= .F.
			Next
			nTotPeso	:= 0
			nTotValor	:= 0
			nTotPedidos	:= 0

			oTotPeso:Refresh()
			oTotValor:Refresh()
			oTotPedidos:Refresh()
			Return
		Endif

		// Executa uma pergunta para garantir uma opção abortar o processo
		If !MsgYesNo("Deseja realmente alterar a transportadora dos pedidos pedidos selecionados?")
			Return
		Endif


		Dbselectarea("SA4")
		Dbsetorder(1)
		Dbseek(xFilial("SA4")+cTransp)

		For x := 1 To Len(aSC9)
			If 	aSC9[x,2]
				DbSelectArea("SC5")
				DbSetOrder(1)
				If DbSeek(xFilial("SC5")+aSC9[x,3])
					cAlte := "Transportadora de: " + SC5->C5_TRANSP + " para: " +cTransp
					RecLock("SC5",.F.)
					SC5->C5_TRANSP	:= cTransp
					MsUnlock()

					// Grava Log
					U_GMCFGM01("AC",SC5->C5_NUM,cAlte,FunName())

					cSigTp	:= 	U_FPDC_007(SC5->C5_TIPO,SC5->C5_CLIENTE,SC5->C5_LOJACLI)
					aSC9[x,7]	:= cSigTp+"-"+SC5->C5_TRANSP+" - "+SA4->A4_NREDUZ
					aSC9[x,2]	:= .F.
				Endif
			Endif
		Next

		nTotPeso	:= 0
		nTotValor	:= 0
		nTotPedidos	:= 0

		oTotPeso:Refresh()
		oTotValor:Refresh()
		oTotPedidos:Refresh()

	Else
		If !MsgYesNo("Deseja usar a tela somente para alterar transportadora dos pedidos que você irá marcar?","Alterar transportadora")
			Return
		Endif
		lTransp	:= .T.

	Endif


Return

/*/{Protheus.doc} sfVerColetor
(Exibir tela com informações dos pedidos já enviados para separação)
@author MarceloLauschner
@since 18/06/2011
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVerColetor()

	Local cQry  		:= ""
	Local oDlg2
	Local aZH			:= {}
	Local oZH
	Local cZH

	cQry += "SELECT TRANSP,A1_MUN,COUNT(DISTINCT(C9_PEDIDO))NUMPEDIDOS,COUNT(*) QTEITENS,SUM(C9_QTDLIB*B1_PESO) PESO,SUM(C9_PRCVEN*C9_QTDLIB) TOTAL "
	cQry += "  FROM ( "
	cQry += "SELECT C5_TRANSP + '-' +  A4_NREDUZ TRANSP,
	cQry += "       CASE "
	cQry += "        WHEN C5_TIPO IN('D','B') THEN "
	cQry += "         (SELECT A2_MUN "
	cQry += "            FROM "+RetSqlName("SA2") + " A2 "
	cQry += "           WHERE A2.D_E_L_E_T_ = ' ' "
	cQry += "             AND A2_LOJA = C5_LOJACLI "
	cQry += "             AND A2_COD = C5_CLIENTE "
	cQry += "             AND A2_FILIAL = '"+xFilial("SA2")+"') "
	cQry += "        ELSE "
	cQry += "         (SELECT A1_MUN "
	cQry += "            FROM "+RetSqlName("SA1") +" A1 "
	cQry += "           WHERE A1.D_E_L_E_T_ = ' ' "
	cQry += "             AND A1_LOJA = C5_LOJACLI "
	cQry += "             AND A1_COD = C5_CLIENTE "
	cQry += "             AND A1_FILIAL = '"+xFilial("SA1")+"') "
	cQry += "        END A1_MUN, "
	cQry += "       C9_PEDIDO,C9_QTDLIB,B1_PESO,C9_PRCVEN "
	cQry += "  FROM "+RetSqlName("SC9") + " C9, "+RetSqlName("SB1") + " B1," + RetSqlName("SC5") + " C5," + RetSqlName("SA4") + " A4 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = C9_PRODUTO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1") + "' "
	cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_NUM = C9_PEDIDO "
	cQry += "   AND C5_FILIAL = '"+xFilial("SC5") + "' "
	cQry += "   AND A4.D_E_L_E_T_(+) = ' ' "
	cQry += "   AND A4_COD(+) = C5_TRANSP "
	cQry += "   AND A4_FILIAL(+) = '"+xFilial("SA4") + "' "
	If cEmpAnt+cFilAnt $ "0205"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial BF-RS é necessário escolher entre o armazém Atria ou Flexsil",{"01-Atria","02-Flexsil"},3)
		Endif
		If nOpcLoc == 2
			cQry += " AND C9_LOCAL = '02' "
		ElseIf nOpcLoc == 1
			cQry += " AND C9_LOCAL = '01' "
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	Endif
	cQry += "   AND C9.D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_FLGENVI = 'E' "
	cQry += "   AND C9_XWMSPED > 0 " // Campo WMS Pedido informa se o pedido já foi enviado para separação ou não
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	cQry += "   AND C9_SERIENF = '   ' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "') "
	cQry += " GROUP BY TRANSP,A1_MUN "
	cQry += " ORDER BY 1,2 "

	TcQuery cQry NEW ALIAS "QC9"

	DbSelectArea("QC9")
	DbGoTop()
	While !Eof()
		Aadd(aZH,{QC9->TRANSP,QC9->A1_MUN,QC9->NUMPEDIDOS,QC9->QTEITENS,QC9->PESO,QC9->TOTAL})
		QC9->(DbSkip())
	Enddo
	QC9->(DbCloseArea())

	If Len(aZH) <= 0
		MsgInfo( "Não há pedidos enviados para o WMS pendente de faturamento!", "Aviso" )
	Else

		DEFINE MSDIALOG oDlg2 TITLE OemToAnsi("Consulta de pedidos no WMS por Transportadora X Municipio") From 0,0 to 300,700 of oMainWnd PIXEL

		@ 005,005 LISTBOX oZH VAR cZH Fields HEADER ;
			"Transportadora",; 		// 1
		"Cidade",;				// 2
		"Pedidos",;             // 3
		"Itens",;                 // 4
		"Peso",;                // 5
		"R$ Total";             // 6
		SIZE 340,140;
			OF oDlg2 Pixel
		oZH:SetArray(aZH)
		oZH:bLine:={ || { aZH[oZH:nAT,01],;
			aZH[oZH:nAT,02],;
			aZH[oZH:nAT,03],;
			aZH[oZH:nAT,04],;
			aZH[oZH:nAT,05],;
			Transform(aZH[oZH:nAT,06],"@E 999,999,999.99")}}
		oZH:Refresh()
		ACTIVATE DIALOG oDlg2 Centered
	Endif

Return


/*/{Protheus.doc} FPDC_008
(Efetua a chamada da rotina sem permitir que notas sejam geradas)
@author MarceloLauschner
@since 13/06/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FPDC_008()

Return U_FPDC_002(.T.)




