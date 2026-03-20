#INCLUDE "topconn.ch"
#include "rwmake.ch"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} FPDC_001
(Selecionar e enviar Pedidos para separação )
@author MarceloLauschner
@since 10/09/2009
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FPDC_001()

	Local aAreaOld			:= GetArea()
	Local cTitulo	 		:= OemToAnsi("Envio de pedidos para separação na Expedição!")

	Private oSC9
	Private aSC9 			:= {}
	Private oDlg
	Private oVermelho		:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	Private oAzul 			:= LoaDbitmap( GetResources(), "BR_AZUL" )
	Private oAmarelo		:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private oVerde			:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private oPreto			:= LoaDbitmap( GetResources(), "BR_PRETO" )
	Private oPink			:= LoaDbitmap( GetResources(), "BR_PINK" )
	Private oBranco     	:= LoaDbitmap( GetResources(), "BR_BRANCO" )
	Private oNoMarked  		:= LoadBitmap( GetResources(), "LBNO" )
	Private oMarked    		:= LoadBitmap( GetResources(), "LBOK" )
	Private aSize 			:= MsAdvSize()
	Private aObjects 		:= {}
	Private aPosObj			:= {}
	Private aPosGet     	:= {}
	Private cVarPesq		:= Space(6)
	Private oTotVol,oTotPeso,oTotValor,oTotPedidos
	Private nTotVol		:= nTotPeso		:= nTotValor 	:= nTotPedidos	:= 0
	Private nColPos 		:= 1
	Private lSortOrd		:= .F.
	Private aResumo			:= {}
	Private nOpcLoc			:= 0
	Private lTransp			:= .F.

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	// Efetuo validação para ter certeza de que o campo existe, garantindo integridade do programa.
	DbSelectArea("SC9")
	DbSetOrder(1)
	If SC9->(FieldPos("C9_XWMSPED")) == 0
		MsgAlert("O Campo de controle 'C9_XWMSPED-Pedido WMS' não existe no dicionário de dados desta empresa. É necessário rodar o compatibilizador FPDC_005!","Validação de dicionário de dados!!")
		Return
	Endif

	DbSelectArea("SC9")
	DbSetOrder(1)
	If SC9->(FieldPos("C9_XWMSQTE")) == 0
		MsgAlert("O Campo de controle 'C9_XWMSQTE-Separadoo WMS' não existe no dicionário de dados desta empresa.É necessário rodar o compatibilizador FPDC_005!","Validação de dicionário de dados!!")
		Return
	Endif

	Processa({|| stCriaArq() },"Aguarde! Selecionando pedidos aptos a separar...")

	If Len(aSC9) < 1  // Evita que abra a tela se não houver pedidos a serem faturados.
		MsgInfo("Não há pedidos enviados ao depósito disponíveis para faturamento.","Não há pedidos!")
		AAdd( aSC9, { 1,;		// 1
		.F.,;		// 2
		1,;			// 3
		"",;		// 4
		"",;		// 5
		"",; 		// 6
		"",; 		// 7
		"",;		// 8
		"",;		// 9
		0,;			// 10
		0,;			// 11
		"",;		// 12
		0,;			// 13
		"",;		// 14
		"",;		// 15
		"",;        // 16
		'N'} )		// 17
	Endif

	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 015, .t., .f. } )

	aInfo := {aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects )

	aPosGet := MsObjGetPos(aSize[3]-aSize[1],315,{{003,033,160,200,240,263}} )

	DEFINE MSDIALOG oDlg TITLE cTitulo From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

	oDlg:lMaximized := .T.

	//oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	//oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,80,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM

	@ 0, 0 LISTBOX oSC9 VAR cSc9 Fields HEADER ;
		" ",;                  //1
	" ",;                  // 2
	" ",;				   // 3
	"Pedido",;             // 4
	"Liberação",;          // 5
	"CNPJ - Nome Cliente",;  // 6
	"Dt. Fat.",;           // 7
	"Cidade",;             // 8
	"Transportadora",;     // 9
	"Valor Pedido",;       // 10
	"Peso Mercadoria",;	   // 11
	"Cálculo de Frete",;   // 12
	"Volumes Estimados",;  // 13
	"Mensagens",;          // 14
	"Obs.Entrega",;		   // 15
	"Box",;                // 16
	"Envia";               // 17
	SIZE aPosObj[2,4], aPosObj[2,3]-30;
		ON DBLCLICK (stDblClick()) OF oPanel2 PIXEL
	oSC9:Align := CONTROL_ALIGN_ALLCLIENT

	oSC9:nFreeze := 3
	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{stStsRota(),;
		Iif(aSC9[oSC9:nAT,02],oMarked,oNoMarked),;
		stStsObs(),;
		aSC9[oSC9:nAT,04],;
		aSC9[oSC9:nAT,05],;
		aSC9[oSC9:nAT,06],;
		aSC9[oSC9:nAT,07],;
		aSC9[oSC9:nAT,08],;
		aSC9[oSC9:nAT,09],;
		Transform(aSC9[oSC9:nAT,10],"@E 999,999,999.99"),;
		Transform(aSC9[oSC9:nAT,11],"@E 999,999,999.9999"),;
		aSC9[oSC9:nAT,12],;
		aSC9[oSC9:nAT,13],;
		aSC9[oSC9:nAT,14],;
		aSC9[oSC9:nAT,15],;
		aSC9[oSC9:nAT,16],;
		aSC9[oSC9:nAT,17]}}
	oSC9:Refresh()

	oSC9:bHeaderClick := {|| Iif(oSC9:ColPos == 2 ,sfMarkAll(),(cVarPesq := aSC9[oSC9:nAt,4],nColPos :=oSC9:ColPos,lSortOrd := !lSortOrd, aSort(aSC9,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),stVldPesC9()))}


	@ 005,010 BITMAP oBmp RESNAME "BR_VERDE" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,020 SAY "- A Separar " of oPanel3 pixel
	@ 020,010 BITMAP oBmp RESNAME "BR_PRETO" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 020,020 SAY "- Pedido com Mensagem" of oPanel3 pixel
	@ 005,080 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,090 SAY "- Nao recebe na sexta" of oPanel3 pixel
	@ 020,080 BITMAP oBmp RESNAME "BR_AZUL" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 020,090 SAY "- Não tem Rota" of oPanel3 pixel

	@ 035,010 SAY "Pesquisar Pedido" of oPanel3 pixel
	@ 035,060 MSGET cVarPesq Valid stVldPesC9() of oPanel3 pixel

	@ 005,160 Say "Volumes" of oPanel3 Pixel
	@ 020,160 Say "Peso" of oPanel3 Pixel
	@ 035,160 Say "Valor" of oPanel3 Pixel
	@ 050,160 Say "Pedidos" of oPanel3 Pixel

	@ 005,185 MsGet oTotVol Var nTotVol  Picture "@E 999,999.9999" Size 50,10  READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 020,185 MsGet oTotPeso Var nTotPeso  Picture "@E 999,999.9999" Size 50,10  READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 035,185 MsGet oTotValor Var nTotValor Picture "@E 999,999,999.99" Size 50,10 READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 050,185 MsGet oTotPedidos Var nTotPedidos Picture "@E 999,999" Size 50,10 READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 020,236 Say "Kg" of oPanel3 Pixel
	@ 035,236 Say "Reais" of oPanel3 Pixel


	@ 010,280 BUTTON "&Envia" 	 of oPanel3 pixel SIZE 60,13 ACTION (Processa({|| stExpSC9() },"Exportando pedidos..."),oDlg:End() ) When !lTransp
	@ 010,350 BUTTON "&Cancela" of oPanel3 pixel SIZE 60,13 ACTION (oDlg:End() )
	@ 010,420 Button "&Posição Pedidos"  Of oPanel3 Pixel Size 60,13 Action sfVerColetor()
	@ 010,490 Button "&Espelho Pedido"  Of oPanel3 Pixel Size 60,13 Action &("StaticCall(BIG005,Espelho,aSC9[oSc9:nAt,4])")
	@ 010,560 Button "Exportar Excel" of oPanel3 Pixel Size 60,13 Action stExpExcel()
	@ 010,630 Button "Alterar Transp." of oPanel3 Pixel Size 60,12 Action sfAltInverte()

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
Static Function sfMarkAll()

	Local 	nX 
	Local 	nBx 	:= oSC9:nAt 

	For nX  := 1 To Len(aSC9)
		oSC9:nAt	:= nX 
		stDblClick()
	Next
	oSC9:nAt 	:= nBx 
	oSC9:Refresh()

Return 


/*/{Protheus.doc} stCriaArq
Montar array para o ListBox dos pedidos a serem selecionados para separação
@type function
@version 
@author Marcelo Alberto Lauschner
@since 10/09/2009
@return return_type, return_description
/*/
Static Function stCriaArq()

	Local cCliente,cLoja,cCEP,cRota,nDiaAtu,nDiaEnt,dData,aRota,aDias
	Local nReg 			:= 0
	Local nStatus 		:= 0
	Local cSigTp		:= ""
	Local lExistLust	:= .F.
	Local cQry
	Local x
	Local nVlrFrete		:= 0


	cQry := ""
	cQry += "SELECT C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_FLGENVI,C9_XWMSPED, C9_LIBFAT, C9_BLINF, SUM(C9_PRCVEN*C9_QTDLIB) AS TOT, "
	cQry += "       SUM(C9_QTDLIB*B1_PESBRU) PESOPEDIDO, "
	If SB1->(FieldPos("B1_CONVB")) <> 0
		cQry += "       SUM(CASE WHEN B1_MIUD = 'N' THEN ROUND(C9_QTDLIB/ CASE WHEN B1_CONVB = 0 THEN 1 ELSE B1_CONVB END,0) ELSE 0 END) AS VOLUMES"
	Else
		cQry += "       0 VOLUMES "
	Endif
	cQry += "  FROM " + RetSqlName("SC9") + " C9, " + RetSqlName("SB1") + " B1, " + retSqlName("SC5") + " C5"
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = C9_PRODUTO "
	cQry += "   AND C5_FILIAL = C9_FILIAL "
	cQry += "   AND C5.D_E_L_E_T_ <> '*' "
	cQry += "   AND C5_NUM = C9_PEDIDO "
	//cQry += "   AND C5_XFLAG = ' ' "
	cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry += "   AND C9.D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_FLGENVI = 'E' "

	If cEmpAnt+cFilAnt $ "0205"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial RS é necessário escolher entre o armazém Texaco ou Continental",{"01-Texaco","02-Continental","03-Pneus Agro"},3)
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
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial SC é necessário escolher entre o armazém Texaco ou Continental",{"01-Texaco","02-Continental","03-Pneus Agro"},3)
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
			nOpcLoc	:= Aviso("Escolha local de saída!","Para a filial BF-PR é necessário escolher entre o armazém da Texaco ou Michelin!",{"01-Texaco","02-Michelin","03-Pneus Agro"},3)
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

	cQry += "   AND C9_XWMSPED = 0 " // Campo WMS PEDIDO informa se o pedido já foi enviado para separação ou não via EDI
	cQry += "   AND C9_BLEST = ' ' "
	cQry += "   AND C9_BLCRED = ' ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	cQry += "   AND C9_SERIENF = '   ' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") +"' "
	cQry += " GROUP BY C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_FLGENVI,C9_XWMSPED, C9_LIBFAT, C9_BLINF "
	cQry += " ORDER BY C9_LIBFAT, C9_BLINF "

	TCQUERY cQry NEW ALIAS "QRP"

	Count to nReg

	dbselectarea("QRP")
	dbGotop()
	ProcRegua(nReg)
	While !Eof()
		lExistLust	:= .F.

		IncProc("Processando Pedido Nº-> "+QRP->C9_PEDIDO)

		dbSelectArea("SC5")
		dbSetOrder(1)
		dbSeek(xFilial("SC5")+QRP->C9_PEDIDO)

		If SC5->C5_TIPO $ "D#B" // Devolução ou Beneficiamento
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+QRP->C9_CLIENTE+QRP->C9_LOJA)
			cCEP	:= SA2->A2_CEP

		Else
			dbSelectArea("SA1")
			dbSetOrder(1)
			dbSeek(xFilial("SA1")+QRP->C9_CLIENTE+QRP->C9_LOJA)
			cCEP 	:= SA1->A1_CEP
		Endif

		cCliente := QRP->C9_CLIENTE
		cLoja    := QRP->C9_LOJA
		nDiaAtu  := 0
		nDiaEnt  := 0
		dData    := dDataBase
		aRota    := {}
		aDias    := {1,2,3,4,5,6,7}

		dbSelectArea("PAB")
		dbSetOrder(1)
		If dbSeek(xFilial("PAB")+cCEP)
			cRota := PAB->PAB_ROTA
			For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
				AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
			Next
		Endif

		nDia := Dow(dDatabase)
		If Len(aRota) > 0
			While .T.
				If nDia > 7
					nDia := 1
				Endif
				nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
				If !Empty(nPos)
					nDiaEnt := Val(aRota[nPos][1])
					If nDiaEnt == Dow(dDatabase)
						dData := dDatabase
					Elseif (nDiaEnt - Dow(dDatabase)) > 0
						dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
					Else
						dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
					Endif
					Exit
				Endif
				nDia++
			End
		Endif


		dbselectarea("SA4")
		dbsetorder(1)
		dbseek(xFilial("SA4")+SC5->C5_TRANSP)

		nStatus	:= 2

		// PEDIDO ENVIADO TMK NÃO ENVIADO COLETOR/VS
		If Substr(QRP->C9_FLGENVI,1,1) == "E"
			nStatus	:= 2   //VERDE
		EndIf

		If dData > dDataBase //fora de rota
			nStatus    := 4 //azul
		Endif

		// Verifica se o dia é quinta-feira, o dia de faturamento é quinta-feira e o pedido não é de fornecedor e existe o campo de não recebe nas sextas-feiras
		If Dow(dDatabase) == 5 .And. dData == dDatabase .And. !SC5->C5_TIPO $"D#B" .And. SA1->(FieldPos("A1_RESEX")) > 0 .And. SA1->A1_RESEX == 'N'  // cliente nao recebe sexta
			nStatus	:= 1   //vermelho
		Endif
		If Empty(QRP->C9_LIBFAT)
			nStatus	:= 5
		Endif

		// Validação adicionada em 19/12/2012 afins de verifica se há produtos que devam ser faturados pela série 3 de NFe
		If SM0->M0_CGC $ "06032022000110"
			cQry := ""
			cQry += "SELECT COUNT(*) TEM_LUST "
			cQry += "  FROM " + RetSqlName("SC9") + " C9 "
			cQry += " WHERE C9_FILIAL = '"+xFilial("SC9") +"' "
			cQry += "   AND C9.D_E_L_E_T_ = ' ' "
			cQry += "   AND C9_PEDIDO = '"+QRP->C9_PEDIDO+"' "
			//cQry += "   AND C9_GRUPO IN('1050','1055','1060','1065','1070','1075','1160','1161','1162','1163','1170','1180')
			cQry += "   AND '"+Alltrim(GetNewPar("BF_GRPIMPT","1135#1160#1161#1162#1163#1170#1180"))+"' LIKE C9_GRUPO "
			cQry += "   AND SUBSTR(C9_PRODUTO,1,1) = '1' "

			TCQUERY cQry NEW ALIAS "QLUST"
			If QLUST->TEM_LUST > 0
				lExistLust	:= .T.
			Endif
			QLUST->(DbCloseArea())
		Endif

		If SC5->C5_TPFRETE $ "S#F" 	// Sem frete/FOB
			nVlrFrete		:= 0
		Else
			nVlrFrete	:= U_BFFATM22(SC5->C5_EMISSAO/*dInData*/,SC5->C5_CLIENTE/*cInCodCli*/,SC5->C5_LOJACLI/*cInLojCli*/,SC5->C5_TRANSP/*cInTransp*/,QRP->TOT/*nInVlrMerc*/,QRP->PESOPEDIDO/*nInPeso*/,SC5->C5_FRETE/*nInVlrFrete*/)
		Endif

		cSigTp	:= 	U_FPDC_007(SC5->C5_TIPO,SC5->C5_CLIENTE,SC5->C5_LOJACLI)

		AAdd( aSC9, { 	nStatus,;							// 1
		.F.,;												// 2
		IIf(lExistLust,2,Iif(!Empty(Alltrim(SC5->C5_MSGINT)),1,0)),;          // 3
		QRP->C9_PEDIDO,;									// 4
		Substr(QRP->C9_LIBFAT,7,2)+"/"+Substr(QRP->C9_LIBFAT,5,2)+"/"+Substr(QRP->C9_LIBFAT,3,2)+"-"+Substr(QRP->C9_BLINF,1,5),;//SC5->C5_EMISSAO,;	//5
		Iif(SC5->C5_TIPO $ "D#B",Transform(SA2->A2_CGC,"@R 99.999.999/9999-99") + " - " + Alltrim(SA2->A2_NREDUZ), Transform(SA1->A1_CGC,"@R 99.999.999/9999-99") + " - " + Alltrim(SA1->A1_NREDUZ)),;	// 6
		SC5->C5_DTPROGM,; 									// 7
		Iif(SC5->C5_TIPO $"D#B",SA2->A2_MUN,SA1->A1_MUN),;	// 8
		cSigTp + "-"+SC5->C5_TRANSP+" - "+SA4->A4_NREDUZ,;  // 9
		QRP->TOT,;								 			// 10
		QRP->PESOPEDIDO,;									// 11
		"Frete Devido: R$ " + Alltrim( Transform(nVlrFrete,"@E 999,999.99")) + " - " + Transform(nVlrFrete/QRP->TOT*100,"@E 999.99") + "% " + IIf(SC5->C5_FRETE > 0," Frete Destacado: R$ " + Alltrim( Transform(SC5->C5_FRETE,"@E 999,999.99")),"") ,;	// 12
		QRP->VOLUMES,;										// 13
		Alltrim(SC5->C5_MSGINT)+Space(100),;    			// 14
		SA1->A1_REFCOM1,;									// 15
		SA4->A4_ENDPAD,;		                            // 16
		'N'} )												// 17

		dbSelectArea("QRP")
		dbSkip()
	Enddo

	QRP->(DbCloseArea())
	ProcRegua(1)
	IncProc("Finalizando...")

Return


/*/{Protheus.doc} stDblClick
Marca e desmarca linha do ListBox
@type function
@version 
@author Marcelo Alberto Lauschner
@since 10/09/2009
@return return_type, return_description
/*/
Static Function stDblClick()

	Local 	cCliLoj	:= ""
	Local	cPed    := aSC9[oSc9:nAt,4]
	Local 	iW
	Local 	iX

	nTotVol		:= 0
	nTotPeso	:= 0
	nTotValor	:= 0
	nTotPedidos	:= 0


	Dbselectarea("SC5")
	Dbsetorder(1)
	Dbseek(xFilial("SC5")+cPed)
	cCliLoj	:= SC5->C5_CLIENTE+SC5->C5_LOJACLI

	For iW := 1 To Len(aSC9)
		Dbselectarea("SC5")
		Dbsetorder(1)
		If Dbseek(xFilial("SC5")+aSC9[iW,4]) .And. SC5->C5_CLIENTE+SC5->C5_LOJACLI == cCliLoj .And. iW <> oSc9:nAt
			If !aSC9[oSc9:nAt,2]
				If !aSC9[iW,2]
					MsgAlert("Você deverá marcar o pedido "+aSC9[iW,4]+" também para envio para o faturamento, pois é do mesmo cliente!!","Junção de pedidos!")
				Endif
			Else
				If aSC9[iW,2]
					MsgAlert("Favor desmarcar o pedido "+aSC9[iW,4]+" pois é do mesmo cliente. Não deve ser enviado pedidos separados para o faturamento !!","Junção de pedidos!")
				Endif
			Endif
		Endif
	Next

	aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .And. (aSC9[oSc9:nAt,1]>=1 .And. aSC9[oSc9:nAt,1] < 5) ,.T., .F.)
	
	For iX := 1 To Len(aSC9)
		If aSC9[iX,2]
			nTotPeso	+= aSC9[iX,11]
			nTotValor	+= aSC9[iX,10]
			nTotVol		+= aSC9[iX,13]
			nTotPedidos += 1
		Endif
	Next
	oTotPeso:Refresh()
	oTotValor:Refresh()
	oTotPedidos:Refresh()
	oTotVol:Refresh()

Return

/*/{Protheus.doc} stStsRota
Legenda do status da Rota
@type function
@version 
@author Marcelo Alberto Lauschner
@since 23/10/2020
@return return_type, return_description
/*/
Static Function stStsRota()

	nRet := 1

	If aSC9[oSc9:nAt,1] == 1
		nRet	:= oVermelho
	ElseIf	aSC9[oSc9:nAt,1] == 2
		nRet	:= oVerde
	ElseIf	aSC9[oSc9:nAt,1] == 3
		nRet	:= oAmarelo
	ElseIf	aSC9[oSc9:nAt,1] == 5
		nRet	:= oPink
	Else
		nRet	:= oAzul
	EndIf

Return nRet


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 10/09/2009
// Nome função:
// Parametros :
// Objetivo   :
// Retorno    : Legenda se tem Observação ou não
// Alterações :
//---------------------------------------------------------------------------------------
Static Function stStsObs()

	nRet := 1

	If aSC9[oSc9:nAt,3] == 1
		nRet	:= oPreto
	ElseIf aSC9[oSc9:nAt,3] == 2
		nRet	:= oAmarelo
	Else
		nRet    := oBranco
	EndIf

Return nRet

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 10/09/2009
// Nome função: stVldPesC9
// Parametros :
// Objetivo   : Posicionar no ListBox o numero do pedido pesquisado
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------

Static Function stVldPesC9

	Local nAscan := Ascan(aSC9,{|x|x[4]==cVarPesq})

	If nAscan <=0
		nAscan	:= 1
	Endif
	oSC9:nAT 	:= nAscan
	cVarPesq	:= space(06)
	oSC9:Refresh()
	oSC9:SetFocus()

Return

/*/{Protheus.doc} stExpSC9
description
@type function
@version 
@author Marcelo Alberto Lauschner
@since 23/10/2020
@return return_type, return_description
/*/
Static Function stExpSC9

	Local lContinua	:= .F.
	Local x			:= 1



	//verifica se existem pedidos marcados para continuar
	For x := 1 To Len(aSC9)
		If aSC9[x,2]
			lContinua  := .T.
			Exit
		Endif
	Next

	// Executa uma pergunta para garantir uma opção abortar o processo
	If !MsgYesNo("Deseja realmente enviar os pedidos selecionados para a separação?")
		Return
	Endif

	If lContinua

		For x := 1 To Len(aSC9)

			If 	aSC9[x,2]

				// Inicia proteção na Gravação dos Dados
				// Se houver algum erro durante o processo será executa um RollBack no Banco de Dados

				//Begin Transaction
				BeginTran()

				// Envia pedido para tabelas de EDI
				If stVS_Col(aSC9[x,4]) < 0
					DisarmTransaction()
				Else
					sfGvs(aSC9[x,4])
					EndTran()
				Endif

			Endif
		Next

		MsgAlert("Exportação de Dados Realizada com Sucesso!","Informação.")

		If Len(aResumo) > 0
			If MsgYesNo("A impressora está configurada corretamente??","Atenção. Verificação.")
				Impr() // Chama a impressão do resumo dos pedidos faturados e exportados para uso do deposito.
			Endif
		Endif
	Else
		MsgAlert("Não houveram pedidos selecionados para exportação! ","Atenção.")
	Endif


Return

/*/{Protheus.doc} stExpExcel
Rotina para exportar Listbox em Excel
@type function
@version  
@author Marcelo Alberto Lauschner
@since 12/08/2021
@return variant, return_description
/*/
Static Function stExpExcel()

	Local 	aCabSC9	:= {" ",;                  //1
	" ",;                  // 2
	" ",;				   // 3
	"Pedido",;             // 4
	"Liberação",;          // 5
	"CNPJ - Nome Cliente",;  // 6
	"Dt. Fat.",;           // 7
	"Cidade",;             // 8
	"Transportadora",;     // 9
	"Valor Pedido",;       // 10
	"Peso Mercadoria",;	   // 11
	"Cálculo de Frete",;   // 12
	"Volumes Estimados",;  // 13
	"Mensagens",;          // 14
	"Obs.Entrega",;		   // 15
	"Box",;                // 16
	"Envia"}              // 17

	If FindFunction("RemoteType") .And. RemoteType() == 1
		DlgToExcel({{"ARRAY","Envio de Pedidos para Separação - Empresa/Filial: " + cEmpAnt + "/" + cFilAnt,aCabSC9,aSC9}})
	EndIf

Return

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 12/09/2009
// Nome função: stVS_Col
// Parametros : Numero do Pedido de Venda que está em cursor
// Objetivo   : Gerar dados para a GVS e Coletores
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------

Static Function stVS_Col(cPedFat)

	Local 	cQry 			:= ""
	Local	lFirst			:= .T.
	Local	nCdPedido		:= 1
	Local	nLoteEdi		:= 1
	Local	nRet			:= 0
	Local	cNewOrdSep		:= ""
	Local	nQteItens		:= 0
	Local 	nSumVolumes		:= 0
	Local 	lCxFechada		:= .T.

	nCdPedido	:= sfRetCdPedido()
	nLoteEdi	:= sfRetLoteEdi()

	// Posiciona apenas uma vez na Tabela para evitar excesso de select
	Dbselectarea("SC5")
	Dbsetorder(1)
	Dbseek(xFilial("SC5")+cPedFat)

	If SC5->C5_TIPO $ "D#B"
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
	Else
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
	Endif

	cQry := "SELECT C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_LOCAL,C9_ITEM,C9_PRODUTO,C9_QTDLIB,C9_SEQUEN "
	cQry += "  FROM " + RetSqlName("SC9") + " C9 "
	cQry += " WHERE C9.D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_FLGENVI = 'E' "
	cQry += "   AND C9_XWMSPED = 0  " // Campo WMS Pedido informa se o pedido já foi enviado para separação ou não via EDI
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	cQry += "   AND C9_SERIENF = '   ' "
	cQry += "   AND C9_PEDIDO =  '" +cPedFat+ "' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
	cQry += " ORDER BY C9_ITEM,C9_SEQUEN"

	TCQUERY cQry NEW ALIAS "QC9"

	//MemoWrite("\A\FPDC_001.sql",cQry)

	While !Eof()
		If lFirst
			// Atualiza a sequencia correta do SC5 no SXE e SXF,
			DbSelectArea("CB7")
			DbSetOrder(1)
			Do While .T.
				cNewOrdSep := GetSxeNum("CB7","CB7_ORDSEP")
				If !dbSeek( xFilial( "CB7" ) + cNewOrdSep )
					Exit
				EndIf
				If __lSx8
					ConfirmSx8()
				EndIf
			EndDo

			DbSelectArea("CB7")
			RecLock("CB7",.T.)
			CB7->CB7_FILIAL 	:= xFilial("CB7")
			CB7->CB7_ORDSEP 	:= cNewOrdSep    		// Numero Ordem
			CB7->CB7_PEDIDO		:= QC9->C9_PEDIDO		// Pedido Venda
			CB7->CB7_CLIENT		:= QC9->C9_CLIENTE		// Cliente
			CB7->CB7_LOJA		:= QC9->C9_LOJA			// Loja Cliente
			CB7->CB7_LOJENT		:= SC5->C5_LOJAENT		// Loja Entrega
			CB7->CB7_DTEMIS		:= dDatabase			// Data Emissão
			CB7->CB7_LOCAL		:= QC9->C9_LOCAL		// Armazém
			CB7->CB7_HREMIS		:= Time()			    // Hora Emissão
			CB7->CB7_STATUS		:= "0"				 	// Status 				0-Inicio;1-Separando;2-Sep.Final;3-Embalando;4-Emb.Final;5-Gera Nota;6-Imp.nota;7-Imp.Vol;8-Embarcado;9-Embarque Finalizado
			CB7->CB7_ORIGEM		:= "1"					// Origem separação		1=Pedido;2=Nota Fiscal;3=Producao
			CB7->CB7_TIPEXP		:= "00-Separacao"		// Tipo Expedição		00-Separcao,01-Separacao/Embalagem,02-Embalagem,03-Gera Nota 04-embarque
			CB7->CB7_TRANSP		:= SC5->C5_TRANSP		// Transportadora
			CB7->CB7_COND		:= SC5->C5_CONDPAG		// Condição Pagamento
			CB7->CB7_VOLEMI		:= "0"					// Volume Emitido		0=Nao;1=Sim
			MsUnlock()
			lFirst	:= .F.
		Endif
		DbSelectArea("CB8")
		RecLock("CB8",.T.)
		CB8->CB8_FILIAL		:= xFilial("CB8")
		CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
		CB8->CB8_ITEM		:= 	QC9->C9_ITEM		// Item Pedido
		CB8->CB8_PEDIDO		:= 	QC9->C9_PEDIDO		// Pedido de Venda
		CB8->CB8_PROD		:= 	QC9->C9_PRODUTO		// Código Produto
		CB8->CB8_LOCAL		:= 	QC9->C9_LOCAL		// Armazém
		CB8->CB8_QTDORI		:= 	QC9->C9_QTDLIB		// Quantidade Original
		CB8->CB8_SALDOS		:= 	QC9->C9_QTDLIB		// Saldo a Separar
		CB8->CB8_SALDOE		:= 	QC9->C9_QTDLIB		// Saldo a embalar
		CB8->CB8_SEQUEN		:= 	QC9->C9_SEQUEN		// Sequencia
		CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
		MsUnlock()
		nQteItens++

		If cEmpAnt+cFilAnt $ "0207#0209#0208"
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+QC9->C9_PRODUTO)
			// Se o produto for miudeza
			If SB1->B1_MIUD == "S"
				lCxFechada 	:= .F.
				// Se o produto não for miudeza mas tiver fração de divisão
			ElseIf SB1->B1_MIUD == "N" .And. Mod(QC9->C9_QTDLIB,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)) > 0
				lCxFechada 	:= .F.
			Else
				nSumVolumes += (QC9->C9_QTDLIB / IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB) )
			Endif
		Endif

		DbSelectArea("QC9")
		DbSkip()
	Enddo
	// Atualiza total de itens a separar
	DbSelectArea("CB7")
	RecLock("CB7",.F.)
	CB7->CB7_NUMITE   := nQteItens
	MsUnlock()

	QC9->(DbCloseArea())

	cQry := "UPDATE  " + RetSqlName("SC9") + "  "
	cQry += "   SET C9_XWMSPED = "+Alltrim(Str(nCdPedido))+" "
	cQry += "      ,C9_XWMSEDI = "+Alltrim(Str(nLoteEdi))+" "
	cQry += "      ,C9_ORDSEP = '"+cNewOrdSep+"' "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_FLGENVI = 'E' "
	cQry += "   AND C9_XWMSPED = 0 " // Campo WMS Pedido informa se o pedido já foi enviado para separação ou não via EDI
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	cQry += "   AND C9_SERIENF = '   ' "
	cQry += "   AND C9_PEDIDO =  '" +cPedFat+ "' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "

	nRet += TcSqlExec(cQry)

	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cPedFat)
	If SC5->(FieldPos("C5_BOX")) > 0
		RecLock("SC5",.F.)
		SC5->C5_BOX		:= Chr(Randomize(65,90))+Chr(Randomize(65,90))+Chr(Randomize(65,90))+Chr(Randomize(65,90))+Chr(Randomize(65,90))+Chr(Randomize(65,90))
		MsUnlock()
	Endif

	// Se o pedido só teve caixa fechada  - Grava os volumes
	If cEmpAnt+cFilAnt $ "0207#0209#0208" .And. lCxFechada .And. nSumVolumes > 0 

		dbSelectArea("SC5")
		dbSetOrder(1)
		If dbSeek(xFilial("SC5")+cPedFat)
			RecLock("SC5",.F.)
			SC5->C5_VOLUME1 := nSumVolumes
			SC5->C5_VOLUME2 := 0
			SC5->C5_VOLUME3 := 0
			SC5->C5_ESPECI1	:= "DIVERSOS"
			SC5->C5_ESPECI2	:= ""  //cBox+cSep+cMesa+cConf
			SC5->C5_ESPECI3	:= ""
			SC5->C5_ESPECI4	:= ""
			MsUnLock()
		Endif

		// Verifica se há dados na rotina de separação de coletor para que não h
		DbSelectArea("CB7")
		DbSetOrder(1)
		If DbSeek(xFilial("CB7")+cNewOrdSep) .And. CB7->CB7_VOLEMI # "1"

			RecLock("CB7",.F.)
			CB7->CB7_VOLEMI	:= "1"
			CB7->CB7_STATUS	:= "9"
			CB7->CB7_DIVERG	:= ""
			MsUnlock()

			cQry := "UPDATE "+RetSqlName("CB6")
			cQry += "   SET CB6_STATUS = '3' "
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND CB6_PEDIDO = '"+cPedFat+"' "
			cQry += "   AND CB6_STATUS IN('1','2') "
			cQry += "   AND CB6_FILIAL = '"+xFilial("CB6")+"' "

			nRet += TcSqlExec(cQry)

			// Atualiza a quantidade já como separada 
			cQry := "UPDATE  " + RetSqlName("SC9") + " C9 "
			cQry += "   SET C9_XWMSQTE = C9_QTDLIB "
			cQry += " WHERE C9.D_E_L_E_T_ = ' ' "
			cQry += "   AND C9_BLEST = '  ' "
			cQry += "   AND C9_BLCRED = '  ' "
			cQry += "   AND C9_NFISCAL = '      ' "
			cQry += "   AND C9_SERIENF = '   ' "
			cQry += "   AND C9_PEDIDO =  '" +cPedFat+ "' "
			cQry += "   AND C9_ORDSEP = '"+cNewOrdSep+"'"
			cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "

			nRet += TcSqlExec(cQry)
		Endif

		U_GMCFGM01("CP",cPedFat,"Pedido conferido automático:" + cUserName + " Volumes:"+Str(nSumVolumes),FunName())

	Endif

Return nRet

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 18/06/2011
// Nome função: sfVerColetor
// Parametros :
// Objetivo   : Exibir tela com informações dos pedidos já enviados para separação
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sfVerColetor

	Local cQry  		:= ""
	Local oDlg2
	Local aZH			:= {}
	Local oZH
	Local cZH

	cQry += "SELECT TRANSP,A1_MUN,COUNT(DISTINCT(C9_PEDIDO))NUMPEDIDOS,COUNT(*) QTEITENS,SUM(C9_QTDLIB*B1_PESO) PESO,SUM(C9_PRCVEN*C9_QTDLIB) TOTAL "
	cQry += "  FROM ( "
	cQry += "SELECT C5_TRANSP + '-' + A4_NREDUZ TRANSP,
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
	cQry += "  FROM "+RetSqlName("SC9") + " C9 "
	cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 " 
	cQry += "    ON B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = C9_PRODUTO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1") + "' "
	cQry += " INNER JOIN " + RetSqlName("SC5") + " C5 " 
	cQry += "    ON C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_NUM = C9_PEDIDO "
	cQry += "   AND C5_FILIAL = '"+xFilial("SC5") + "' "
	cQry += " INNER JOIN " + RetSqlName("SA4") + " A4 "
	cQry += "    ON A4.D_E_L_E_T_ = ' ' "
	cQry += "   AND A4_COD = C5_TRANSP "
	cQry += "   AND A4_FILIAL  = '"+xFilial("SA4") + "' "
	
	cQry += " WHERE C9.D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_FLGENVI = 'E' "
	cQry += "   AND C9_XWMSPED > 0 " // Campo WMS Pedido informa se o pedido já foi enviado para separação ou não
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	cQry += "   AND C9_SERIENF = '   ' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "') TBL "
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



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 22/09/2009
// Nome função: stConvC9It
// Parametros : Numero Item C9
// Objetivo   : Transformar em formato numérico um valor alfanumerico
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------
Static Function stConvC9It(cItem)
	Local 	nItem	:= 99
	Local 	cItAux 	:= "99"

	// Se item for menor que 9A transforma o proprio valor em numero
	If cItem <= cItAux
		Return Val(cItem)
	Endif


	While .T.
		cItAux	:= Soma1(cItAux)
		nItem++
		If cItem == cItAux
			Exit
		Endif
	Enddo

Return nItem

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 18/06/2011
// Nome função: sfRetCdPedido
// Parametros :
// Objetivo   : Verificar se existe a sequence no schema SA e retornar o proximo valor
// Retorno    : Retorna um valor da sequence
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sfRetCdPedido()

	Local	nCdPedido   := GetNewPar("BR_SEQC9PD",1)

	DbSelectArea("SX6")
	DbSetOrder(1)
	If !DbSeek(xFilial("SX6")+"BR_SEQC9PD")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := xFilial("SX6")
		SX6->X6_VAR     := "BR_SEQC9PD"
		SX6->X6_TIPO    := "N"
		SX6->X6_DESCRIC := "sequencia pedidos"
		MsUnLock()
	Endif 
	nCdPedido++
	
	PutMv("BR_SEQC9PD",nCdPedido)

	
Return nCdPedido

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 18/06/2011
// Nome função: sfRetLoteEdi
// Parametros :
// Objetivo   : Verificar se existe a sequence no schema SA e retornar o proximo valor
// Retorno    : Sequencia de valor para usar em controle de lote
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sfRetLoteEdi()

	Local	nLoteEdi   := GetNewPar("BR_SEQC9LD",1)

	DbSelectArea("SX6")
	DbSetOrder(1)
	If !DbSeek(xFilial("SX6")+"BR_SEQC9LD")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := xFilial("SX6")
		SX6->X6_VAR     := "BR_SEQC9LD"
		SX6->X6_TIPO    := "N"
		SX6->X6_DESCRIC := "sequencia pedidos"
		MsUnLock()
	Endif 
	nLoteEdi++
	
	PutMv("BR_SEQC9LD",nLoteEdi)

Return nLoteEdi




/*/{Protheus.doc} sfGvs
Montagem dos dados para o relatório 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 23/10/2020
@param cPedFat, character, param_description
@param lAtuSZA, logical, param_description
@return return_type, return_description
/*/
Static Function sfGvs(cPedFat,lAtuSZA)

	Local nConta  := 0
	Local cQry    := ""
	Local cNota   := ""
	Local cItem   := "00"
	Local cFlg    := ""
	Local nQuebra := 0
	local lCanEDI := SuperGetMV( 'MV_X_ENEDI' ,,.F. )

	Default lAtuSZA := .T.



	cQry += "SELECT C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_PRODUTO,C9_GRUPO,C9_LOCAL,C9_ORDSEP,SUM(C9_QTDLIB) C9_QTDLIB,SUM(B1_PESO*C9_QTDLIB) PESO,"
	cQry += "       B1_DESC,B1_UM,B1_CODBAR,B1_DUN14,"
	cQry += "       B1_CONVB,B1_DUN14A,B1_CONVA,B1_LOCAL,B1_MIUD,B1_FABRIC,B1_PROC "
	cQry += "  FROM " + RetSqlName("SC9") + " C9, " + RetSqlName("SB1") + " B1  "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1.B1_COD = C9.C9_PRODUTO "
	cQry += "   AND B1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry += "   AND C9_FLGENVI = 'E' "
	cQry += "   AND C9_XWMSPED > 0 " // Campo WMS Pedido informa se o pedido já foi enviado para separação ou não
	cQry += "   AND C9_BLEST = '  ' "
	cQry += "   AND C9_BLCRED = '  ' "
	cQry += "   AND C9_NFISCAL = '      ' "
	cQry += "   AND C9_SERIENF = '   ' "
	cQry += "   AND C9.D_E_L_E_T_ = ' ' "
	cQry += "   AND C9.C9_PEDIDO =  '" +cPedFat+ "' "
	cQry += "   AND C9.C9_FILIAL = '" + xFilial("SC9") + "' "
	cQry += " GROUP BY C9_PEDIDO,C9_CLIENTE,C9_LOJA,C9_PRODUTO,C9_GRUPO,C9_LOCAL,C9_ORDSEP,B1_DESC,B1_UM,B1_CODBAR,B1_DUN14,"
	cQry += "       B1_CONVB,B1_DUN14A,B1_CONVA,B1_LOCAL,B1_MIUD,B1_FABRIC,B1_PROC "
	cQry += " ORDER BY C9_PEDIDO, B1.B1_LOCAL"


	TCQUERY cQry NEW ALIAS "ITEM"


	While !Eof()

		// Se for o item 01 envia arquivo EDI da ordem de separação
		// Adicionado em 11/09/2013 para enviar arquivo Edi para OlLogistica
		// IAGO 09/10/2017 Chamado(19150) Comentado armazem
		If lCanEDI .and. cItem == "00"
			U_BFFATM11(/*cNumNf*/,/*cSerNf*/,"P",cPedFat,ITEM->C9_ORDSEP)
		Endif

		cItem	:= Soma1(cItem)


		If ITEM->B1_MIUD == "S"
			nQuebra := ITEM->C9_QTDLIB          // se o produto for miudeza, GVS irá separar tudo.
		Else
			nQuebra := Mod(ITEM->C9_QTDLIB,Iif(ITEM->B1_CONVB<=0,1,ITEM->B1_CONVB))
		Endif

		If nQuebra > 0
			nconta++
			cFlg 	:= "F" // Flag de que o produto mesmo operado pela VS excedeu a capacidade
		Else
			cFlg	:= "C"
			nconta++
		Endif


		If cFlg == "F"
			cFlg := "F - Quantidade Fracionada"
		Elseif cFlg == "C"
			cFlg := "C - Caixa Fechada"
		Endif

		// Se for fornecedor Chevron e tiver código de fabricante no cadastro de produto, assume o novo código
		// IAGO 09/10/2017 Chamado(19152) Adicionado .And. Filial PR
		If ITEM->B1_PROC == "000468" .And. !Empty(ITEM->B1_FABRIC) .And. (cEmpAnt+cFilAnt != "0204")
			cProd := AllTrim(ITEM->B1_FABRIC)
		Else
			cProd := Alltrim(ITEM->C9_PRODUTO)
		EndIf

		If Select("QRY") > 0
			QRY->(DbCloseArea())
		Endif

		aDados	:= {	cNota,;					// 1
						cPedFat,;					// 2
						cItem,;					// 3
						Iif(nQuebra > 0 ,"X"," "),;// 4
						Iif(Empty(cFlg)," ",cFlg),;// 5
						cProd,;					// 6
						ITEM->B1_DESC,;			// 7
						ITEM->C9_QTDLIB,;			// 8
						ITEM->B1_LOCAL,;			// 9
						nQuebra,;					// 10
						ITEM->C9_ORDSEP}			// 11 Ordem de separaçao

		Aadd(aResumo,aDados)
		cFlg := ""
		
		dbSelectArea("ITEM")
		dbSkip()
	Enddo

	ITEM->(DbCloseArea())

	// Grava Log
	U_GMCFGM01("EC",cPedFat,IIf(SC5->(FieldPos("C5_BOX")) > 0,"Contra-prova "+SC5->C5_BOX,""),FunName())



Return

/*/{Protheus.doc} Impr
Impressão do relatório 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 23/10/2020
@param lInReimp, logical, param_description
@return return_type, return_description
/*/
Static Function Impr(lInReimp)

	Private cDesc1  := "Este programa tem como objetivo imprimir relatorio "
	Private cDesc2  := "de acordo com os parametros informados pelo usuario."
	Private cDesc3  := "Arquivos Carregados"
	Private cPict   := ""
	Private titulo  := "Impressao Pedidos para Separacao"
	Private nLin    := 80
	//           1         2         3         4   		 5 	       6         7         8
	//  012345678901234567890123456789012345678901234567890123456789012345678901234567890
	Private Cabec1  := "  Cod.Produto      Descricao                                 Quantidade Endereco"
	Private Cabec2  := "  Etq.Patrimonio   Descricao                                 Qte Tambor N.Lacre "
	Private imprime := .T.
	Private aOrd    := {}

	Private lEnd        := .F.
	Private lAbortPrint := .F.
	Private limite      := 80
	Private tamanho     := "P"
	Private nomeprog    := "FPDC_001"
	Private nTipo       := 18
	Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey    := 0
	Private cPerg       := "DIS086"
	Private cbtxt       := Space(10)
	Private cbcont      := 00
	Private CONTFL      := 01
	Private m_pag       := 01
	Private wnrel       := "FPDC_001"
	Default lInReimp	:= .F.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta a interface padrao com o usuario...                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	wnrel := SetPrint(,NomeProg,,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

	If nLastKey == 27
		Return
	Endif

	SetDefault(aReturn,)

	If nLastKey == 27
		Return
	Endif

	nTipo := If(aReturn[4]==1,15,18)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin,lInReimp) },Titulo)
Return


/*/{Protheus.doc} RunReport
Função para impressão do relatório 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 23/10/2020
@param Cabec1, character, param_description
@param Cabec2, character, param_description
@param Titulo, param_type, param_description
@param nLin, numeric, param_description
@param lInReimp, logical, param_description
@return return_type, return_description
/*/
Static Function RunReport(Cabec1,Cabec2,Titulo,nLin,lInReimp)

	Local cNumPed	 	:= ""
	Local cFlag    	 	:= ""
	Local nFlg    		:= 0
	Local y,x,i
	Local	cNomAsses		:= ""

	aSort(aResumo,,,{|x,y| x[2]+x[5]+x[9] < y[2]+y[5]+y[9]})

	For x:= 1 to len(aResumo)

		If cNumPed <> Alltrim(aResumo[x,2])

			nLin := Cabec(Titulo,"","",NomeProg,Tamanho,nTipo)

			dbSelectArea("SC5")
			dbSetOrder(1)
			dbSeek(xFilial("SC5")+aResumo[x,2])

			cNomAsses	:= ""
			DbSelectArea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3")+SC5->C5_VEND1)

				DbSelectArea("SU7")
				DbSetOrder(1)
				If DbSeek(xFilial("SU7")+SA3->A3_OPERADO)
					cNomAsses := 	"Assessora: "+SU7->U7_COD+"-"+SU7->U7_NOME
				Endif
			Endif

			dbSelectArea("SA1")
			dbSetOrder(1)
			dbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

			dbselectarea("SA4")
			dbsetorder(1)
			dbseek(xFilial("SA4")+SC5->C5_TRANSP)

			// Chama Função que valida a Sigla corretamente - 02/04/2011
			cSig	:= U_FPDC_007(SC5->C5_TIPO,SC5->C5_CLIENTE,SC5->C5_LOJACLI)


			nLin++
			@nLin,000 PSAY "Ordem de Separacao: **********  " + aResumo[x,11] + "  ********** "
			If lInReimp

				nLin++
				@nLin,000 PSAY "+--------------------------------------------------------------+"
				nLin++
				@nLin,000 PSAY "|                REIMPRESSAO DE PEDIDO                         |"
				nLin++
				@nLin,000 PSAY "+--------------------------------------------------------------+"

			Endif
			If !Empty(cNomAsses)
				nLin++
				@nLin,000 Psay cNomAsses
			Endif

			nLin++
			@nLin,000 PSAY "Pedido: " + SC5->C5_NUM + " - Bairro: "+Alltrim(SA1->A1_BAIRRO)+" - Cidade: " + Alltrim(SA1->A1_MUN)
			nLin++
			@nLin,000 Psay "Transp: " +cSig+"-"+ SC5->C5_TRANSP +"-"+SA4->A4_NREDUZ
			nLin++
			@nLin,000 Psay "Cliente: "+ SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+"  "+SA1->A1_NOME
			nLin++
			@nLin,000 PSAY Padr("MsgCli: " + SA1->A1_REFCOM1,80)
			nLin++
			@nLin,000 PSAY Padr("MsgNF: " + SC5->C5_MENNOTA,80)
			nLin++
			@nLin,000 PSAY Padr("MsgInt: "+ Substr(SC5->C5_MSGINT,1,72),80)
			nLin++
			@nLin,000 PSAY Padr("MsgInt: "+ Substr(SC5->C5_MSGINT,73,72),80)
			nLin++
			@nLin,000 Psay Cabec1
			nLin++
			@nLin,000 psay "--------------------------------------------------------------------------------"
			nLin++

			For y := 1 To Len(aResumo)
				If Alltrim(aResumo[y,2]) == Alltrim(aResumo[x,2])
					If cFlag <> Alltrim(aResumo[y,2])+Alltrim(aResumo[y,5])

						If  Alltrim(aResumo[y,5]) == "T - Tambor 159 litros"
							@nLin,000 Psay Cabec2
							nLin++
						Endif
						For i := 1 To Len(aResumo)
							If Alltrim(aResumo[i,2]) == Alltrim(aResumo[y,2]) .and. Alltrim(aResumo[i,5]) == Alltrim(aResumo[y,5])

								nFlg += 1

								If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
									Cabec(Titulo,Cabec1,"",NomeProg,Tamanho,nTipo)
									nLin := 8
								Endif

								@nLin,000 Psay Substr(aResumo[i,4],1,2)
								@nLin,002 Psay Substr(aResumo[i,6],1,20)
								@nLin,019 psay Substr(aResumo[i,7],1,40)
								@nLin,061 psay Transform(aResumo[i,8],"@E 999,999.99")
								@nLin,072 Psay aResumo[i,9]
								nLin++
								// Chamado 24.546 - Impressão completa do produto
								If Len(Alltrim(aResumo[i,7])) > 40
									@nLin,019 psay Substr(aResumo[i,7],41,40)
									nLin++
								Endif
								@nLin,000 Psay repli("-",80)
								@nLin++

								If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
									Cabec(Titulo,Cabec1,"",NomeProg,Tamanho,nTipo)
									nLin := 8
								Endif

							Endif
						Next
						@nLin,000 Psay ("Total de itens enviados para ->>"+Alltrim(aResumo[y,5])+ " é de: "+Alltrim(Str(nFlg)))
						nLin++
						@nLin,000 psay "----------------------------------------------------------------------------------"
						nLin++
						nLin++
						nFlg := 0
						If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
							Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
							nLin := 8
						Endif

					Endif
					If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
						Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
						nLin := 8
					Endif
					cFlag := Alltrim(aResumo[y,2])+Alltrim(aResumo[y,5])
				Endif

			Next

			@nLin++
			@nLin,000 psay "__________"
			@nLin,015 psay "__________"
			@nLin,030 psay "__________"
			@nLin++
			@nLin,000 psay "Box"
			@nLin,015 psay "Sep"
			@nLin,030 psay "Mesa"
			@nLin++
			@nLin++

			@nLin,000 psay "Legenda: X=Miudeza/Fracionado ;T=Tambor detalhado"
			@nLin++

			If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
				Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
				nLin := 8
			Endif
		Endif
		cNumPed := Alltrim(aResumo[x,2])

	Next

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a execucao do relatorio...                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	SET DEVICE TO SCREEN

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se impressao em disco, chama o gerenciador de impressao...          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif

	MS_FLUSH()

Return





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
				If DbSeek(xFilial("SC5")+aSC9[x,4])
					cAlte := "Transportadora de: " + SC5->C5_TRANSP + " para: " +cTransp
					RecLock("SC5",.F.)
					SC5->C5_TRANSP	:= cTransp
					MsUnlock()

					// Grava Log
					U_GMCFGM01("AC",SC5->C5_NUM,cAlte,FunName())

					cSigTp	:= 	U_FPDC_007(SC5->C5_TIPO,SC5->C5_CLIENTE,SC5->C5_LOJACLI)
					aSC9[x,9]	:= cSigTp+"-"+SC5->C5_TRANSP+" - "+SA4->A4_NREDUZ
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
