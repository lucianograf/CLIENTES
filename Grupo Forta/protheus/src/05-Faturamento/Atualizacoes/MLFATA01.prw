#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'
#DEFINE MAXPASSO 4

/*/{Protheus.doc} MLFATA01
//Rotina para seleção de pedidos para emissão de Nota e Impressão de pré-nota para Expedição
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User function MLFATA01()

	Local aAreaOld			:= GetArea()

	Local cTitulo	 		:= OemToAnsi("Faturamento de Pedidos para Separação na Expedição!")

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



	Private cVarPesq		:= Space(6)
	Private oTotVol,oTotPeso,oTotValor,oTotPedidos
	Private nTotVol		:= nTotPeso		:= nTotValor 	:= nTotPedidos	:= 0
	Private nColPos 		:= 1
	Private lSortOrd		:= .F.
	Private aResumo			:= {}
	Private nOpcLoc			:= 0

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
		0,;			// 12
		0,;			// 13
		0,;			// 14
		0,;			// 15
		"",;        // 16
		"",;		// 17
		"",;		// 18
		'N'} )		// 19
	Endif



	DEFINE MSDIALOG oDlg TITLE cTitulo From  100,0 To 100,100 of oMainWnd PIXEL

	oDlg:lMaximized := .T. 

	//oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	//oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,80,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM

	@ 0, 0 LISTBOX oSC9 VAR cSc9 Fields HEADER ;
	" ",;                  	// 1 Legenda Pedido
	" ",;                  	// 2 Mark
	" ",;				   	// 3 Legenda Observações
	"Pedido",;             	// 4 Número Pedido
	"Liberação",;          	// 5 Informação Liberação
	"CNPJ - Nome Cliente",; // 6 CGC-Cliente
	"Dt.Emissão",;         	// 7 Data 
	"Cidade",;             	// 8 Cidade
	"Transportadora",;     	// 9 
	"R$ Liberado",;       	// 10
	"R$ Estoque",;			// 11
	"R$ Crédito",;			// 12
	"R$ Faturado",;			// 13
	"R$ Total Pedido",;		// 14
	"Volumes Estimados",;  	// 15	
	"Peso Mercadoria",;	   	// 16
	"Mensagem Interna",;   	// 17
	"Mensagem Nota",;	   	// 18
	"Enviado?";            	// 19	
	SIZE 10, 10;
	ON DBLCLICK (stDblClick()) OF oPanel2 PIXEL
	oSC9:Align := CONTROL_ALIGN_ALLCLIENT

	oSC9:nFreeze := 3
	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{ sfLegenda(),;
	Iif(aSC9[oSC9:nAT,02],oMarked,oNoMarked),;
	IIf(!aSC9[oSC9:nAt,3],oPink,oBranco),;
	aSC9[oSC9:nAT,04],;
	aSC9[oSC9:nAT,05],;
	aSC9[oSC9:nAT,06],;
	aSC9[oSC9:nAT,07],;
	aSC9[oSC9:nAT,08],;
	aSC9[oSC9:nAT,09],;
	Alltrim( Transform(aSC9[oSC9:nAT,10],"@E 999,999,999.99")),;
	Alltrim( Transform(aSC9[oSC9:nAT,11],"@E 999,999,999.99")),;
	Alltrim( Transform(aSC9[oSC9:nAT,12],"@E 999,999,999.99")),;
	Alltrim( Transform(aSC9[oSC9:nAT,13],"@E 999,999,999.99")),;
	Alltrim( Transform(aSC9[oSC9:nAT,14],"@E 999,999,999.99")),;
	Alltrim( Transform(aSC9[oSC9:nAT,15],"@E 999,999,999.99")),;
	Alltrim( Transform(aSC9[oSC9:nAT,16],"@E 999,999.99")),;
	aSC9[oSC9:nAT,17],;
	aSC9[oSC9:nAT,18],;
	aSC9[oSC9:nAT,19]} }
	oSC9:Refresh()

	oSC9:bHeaderClick := {|| cVarPesq := aSC9[oSC9:nAt,4],nColPos :=oSC9:ColPos,lSortOrd := !lSortOrd, Iif(nColPos > 0 ,aSort(aSC9,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),Nil),stVldPesC9()}


	@ 005,010 BITMAP oBmp RESNAME "BR_VERDE" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,020 SAY "- Liberado " of oPanel3 pixel
	@ 020,010 BITMAP oBmp RESNAME "BR_PRETO" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 020,020 SAY "- Blq.Crédito/Rejeitado" of oPanel3 pixel
	@ 005,080 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,090 SAY "- Faturado" of oPanel3 pixel
	@ 020,080 BITMAP oBmp RESNAME "BR_AZUL" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 020,090 SAY "- Blq.Estoque" of oPanel3 pixel
	
	@ 035,010 BITMAP oBmp RESNAME "BR_PINK" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 035,020 SAY "- Ped.c/Mensagem Nota " of oPanel3 pixel
	
	@ 050,010 SAY "Pesquisar Pedido" of oPanel3 pixel
	@ 050,060 MSGET cVarPesq Valid stVldPesC9() of oPanel3 pixel

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


	@ 010,280 BUTTON "&Envia" 	 of oPanel3 pixel SIZE 60,13 ACTION (Processa({|| stExpSC9() },"Exportando pedidos..."),oDlg:End() )
	@ 010,350 BUTTON "&Cancela" of oPanel3 pixel SIZE 60,13 ACTION (oDlg:End() )
	@ 010,420 Button "&Espelho Pedido"  Of oPanel3 Pixel Size 60,13 Action sfEspelho(aSC9[oSc9:nAt,4])

	ACTIVATE MSDIALOG oDlg CENTERED

Return



/*/{Protheus.doc} stCriaArq
// Rotina que cria a lista de pedidos 
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function stCriaArq()

	Local		cQry
	Local		nReg

	cQry := ""
	cQry += "SELECT C9_PEDIDO,"
	cQry += "       C9_CLIENTE,"
	cQry += "       C9_LOJA,"
	cQry += "       MAX(C9_BLINF) AS C9_BLINF,"
	cQry += "       SUM(C9_PRCVEN*C9_QTDLIB) AS TOTAL, "
	cQry += "       SUM(CASE WHEN C9_BLEST = ' ' AND C9_BLCRED = ' ' THEN C9_PRCVEN * C9_QTDLIB ELSE 0 END ) AS LIBERADO,"
	cQry += "       SUM(CASE WHEN C9_BLCRED NOT IN('10','09','  ') THEN C9_PRCVEN * C9_QTDLIB ELSE 0 END ) AS CREDITO,"
	cQry += "       SUM(CASE WHEN C9_BLCRED = '09' THEN C9_PRCVEN * C9_QTDLIB ELSE 0 END ) AS REJEITADO,"
	cQry += "       SUM(CASE WHEN C9_BLEST NOT IN('  ','10') AND C9_BLCRED = ' ' THEN C9_PRCVEN * C9_QTDLIB ELSE 0 END ) AS ESTOQUE,"
	cQry += "       SUM(CASE WHEN C9_NFISCAL <> ' ' THEN C9_PRCVEN * C9_QTDLIB ELSE 0 END ) AS FATURADO,"
	cQry += "       SUM(C9_QTDLIB*B1_PESO) PESOPEDIDO "
	cQry += "  FROM " + RetSqlName("SC9") + " C9, " + RetSqlName("SB1") + " B1, " + retSqlName("SC5") + " C5"
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = C9_PRODUTO "
	cQry += "   AND C5_FILIAL = C9_FILIAL "
	cQry += "   AND C5.D_E_L_E_T_ <> '*' "
	cQry += "   AND C5_NUM = C9_PEDIDO "
	//TODO Definir valores para o campo C5_BLPED	
	//cQry += "   AND C5_BLPED NOT IN('X') "
	cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry += "   AND C9.D_E_L_E_T_ = ' ' "

	If Alltrim(cEmpAnt)+Alltrim(cFilAnt) $ "010101"
		If nOpcLoc == 0
			nOpcLoc	:= Aviso("Escolha local de saída!","É necessário escolher entre o armazém 01 ou 02",{"01-Arm.Gaspar","02-Arm.Blumenau"},3)
		Endif

		If nOpcLoc == 2
			cQry += " AND C9_LOCAL = '02' "
		ElseIf nOpcLoc == 1
			cQry += " AND C9_LOCAL = '01' "
		ElseIf nOpcLoc <> 3
			nOpcLoc := 3
		Endif
	Endif
	cQry += "   AND C9_NFISCAL = '  ' "
	cQry += "   AND C9_FILIAL = '" + xFilial("SC9") +"' "
	cQry += " GROUP BY C9_PEDIDO,C9_CLIENTE,C9_LOJA "
	cQry += " ORDER BY C9_PEDIDO DESC "

	TCQUERY cQry NEW ALIAS "QRP"

	Count to nReg

	ProcRegua(nReg)

	dbselectarea("QRP")
	dbGotop()

	While !Eof()

		IncProc("Processando Pedido Nº-> "+QRP->C9_PEDIDO)

		dbSelectArea("SC5")
		dbSetOrder(1)
		dbSeek(xFilial("SC5")+QRP->C9_PEDIDO)

		If SC5->C5_TIPO $ "D#B" // Devolução ou Beneficiamento
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+QRP->C9_CLIENTE+QRP->C9_LOJA)

		Else
			dbSelectArea("SA1")
			dbSetOrder(1)
			dbSeek(xFilial("SA1")+QRP->C9_CLIENTE+QRP->C9_LOJA)
		Endif

		dbselectarea("SA4")
		dbsetorder(1)
		dbseek(xFilial("SA4")+SC5->C5_TRANSP)

		nStatus	:= 0

		If QRP->CREDITO >  0 
			nStatus	:= 1
		ElseIf QRP->ESTOQUE > 0 
			nStatus := 2
		ElseIf QRP->REJEITADO > 0 
			nStatus := 3
		ElseIf QRP->LIBERADO > 0
			nStatus := 4
		ElseIf QRP->FATURADO > 0
			nStatus := 5
		Endif

		/*" ",;                  	// 1 Legenda Pedido
		" ",;                  	// 2 Mark
		" ",;				   	// 3 Legenda Observações
		"Pedido",;             	// 4 Número Pedido
		"Liberação",;          	// 5 Informação Liberação
		"CNPJ - Nome Cliente",; // 6 CGC-Cliente
		"Dt.Emissao.",;         // 7 Data
		"Cidade",;             	// 8 Cidade
		"Transportadora",;     	// 9 
		"R$ Liberado",;       	// 10
		"R$ Estoque",;			// 11
		"R$ Crédito",;			// 12
		"R$ Faturado",;			// 13
		"R$ Total Pedido",;		// 14
		"Volumes Estimados",;  	// 15	
		"Peso Mercadoria",;	   	// 16
		"Mensagem Interna",   	// 17
		"Mensagem Nota",;	   	// 18
		"Enviado?";            	// 19	
		*/
		AAdd( aSC9, { 	nStatus,;							// 1
		.F.,;												// 2
		Empty(SC5->C5_MENNOTA),;							// 3
		QRP->C9_PEDIDO,;									// 4
		QRP->C9_BLINF,;										// 5
		Iif(SC5->C5_TIPO $ "D#B",Transform(SA2->A2_CGC,"@R 99.999.999/9999-99") + " - " + Alltrim(SA2->A2_NREDUZ), Transform(SA1->A1_CGC,"@R 99.999.999/9999-99") + " - " + Alltrim(SA1->A1_NREDUZ)),;	// 6
		SC5->C5_EMISSAO,; 									// 7
		Iif(SC5->C5_TIPO $"D#B",SA2->A2_EST +"/"+SA2->A2_MUN,SA1->A1_EST+"/"+SA1->A1_MUN),;	// 8
		SC5->C5_TRANSP+" - "+SA4->A4_NREDUZ,;  				// 9
		QRP->LIBERADO,;							 			// 10
		QRP->ESTOQUE,;										// 11
		QRP->CREDITO,;										// 12
		QRP->FATURADO,;										// 13
		QRP->TOTAL,;						    			// 14
		0,;													// 15
		QRP->PESOPEDIDO,;									// 16
		SC5->C5_ZMSGINT,;		                            // 17
		SC5->C5_MENNOTA,;									// 18
		'N'} )												// 19

		dbSelectArea("QRP")
		dbSkip()
	Enddo

	QRP->(DbCloseArea())
	ProcRegua(1)
	IncProc("Finalizando...")

Return


/*/{Protheus.doc} sfLegenda
// Função que retorna as legendas dos Pedidos
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static Function sfLegenda()

	Local	oColor	

	// Credito	
	If aSC9[oSC9:nAT,01] == 1
		oColor	:= oPreto
		// Estoque
	ElseIf aSC9[oSC9:nAT,01] == 2
		oColor	:= oAzul
		// Rejeitado 
	ElseIf aSC9[oSC9:nAT,01] == 3
		oColor	:= oPreto
		// Liberado
	ElseIf aSC9[oSC9:nAT,01] == 4
		oColor	:= oVerde
		// Faturado 
	ElseIf aSC9[oSC9:nAT,01] == 5
		oColor	:= oVermelho 
	Endif

Return oColor


/*/{Protheus.doc} stDblClick
// Função do evento de Duplo click na tela de Pedidos
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static Function stDblClick()
	Local	lRet	:= .T. 

	nTotVol		:= 0
	nTotPeso	:= 0
	nTotValor	:= 0
	nTotPedidos	:= 0


	aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .And. aSC9[oSc9:nAt,10] > 0 ,.T., .F.)
	
	// Se o pedido foi marcado, verifica os itens, exibe tela 
	If aSC9[oSc9:nAt,2] 
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+aSC9[oSc9:nAt,4] )
		U_MLFATC07(@lRet)
		If !lRet
			aSC9[oSc9:nAt,2] := .F. 
		Endif
	Endif
	
	For iX := 1 To Len(aSC9)
		If aSC9[iX,2]
			nTotPeso	+= aSC9[iX,16]
			nTotValor	+= aSC9[iX,10]
			nTotVol		+= aSC9[iX,15]
			nTotPedidos += 1
		Endif
	Next
	oTotPeso:Refresh()
	oTotValor:Refresh()
	oTotPedidos:Refresh()
	oTotVol:Refresh()
	
	
	

Return



/*/{Protheus.doc} stVldPesC9
// Função para pesquisar um pedido na tela de Pedidos
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static Function stVldPesC9()

	Local nAscan := Ascan(aSC9,{|x|x[4]==cVarPesq})

	If nAscan <=0
		nAscan	:= 1
	Endif
	oSC9:nAT 	:= nAscan
	cVarPesq	:= space(06)
	oSC9:Refresh()
	oSC9:SetFocus()

Return


/*/{Protheus.doc} sfEspelho
// Função para chamar a régua de processamento durante a montagem da tela do espelho de pedido
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@param cPed, characters, descricao
@type Static Function
/*/
Static function sfEspelho(cPed)
	oProcess := MsNewProcess():New({|lEnd|sfPrcEsp(oProcess,cPed)},"Espelho de pedido está sendo gerado","",.F.)
	oProcess:Activate()
Return

Static Function sfPrcEsp(oObj,cInPed)

	Local oProcess
	Local oBlq , oPed , cBlq  ,nPrunit
	Local 	aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Local   nAltura := aSize[6]/2.3
	Local	z

	Private aBlq := {}
	Private cPed	:= cInPed
	nSomafat := 0
	nSomast  := 0

	DEFINE MSDIALOG oPed FROM 000,000 TO 180,370 OF oMainWnd PIXEL TITLE OemToAnsi("Confirma o numero do pedido-> "+ cPed + "?")
	@ 020,020 Say ("Confirma o pedido número " + cPed+ " ?") Of oPed Pixel
	@ 035,020 Get cPed Picture "@!" of oPed Pixel
	@ 060,020 BUTTON "&Avança" of oPed pixel SIZE 40,15 ACTION (oPed:End() )

	ACTIVATE msDIALOG oPed CENTERED

	lSofat := .F.
	oObj:SetRegua1(MAXPASSO)
	oObj:IncRegua1("Consulta itens liberados e bloqueados")

	cQri := ""
	cQri += "SELECT C9_QTDLIB,C9_ITEM,C9_SEQUEN,C9_PRODUTO,B1_DESC,B2_RESERVA,B2_QATU,C9_FILIAL + C9_PEDIDO + C9_ITEM + C9_SEQUEN C9POS,"
	cQri += "       C9_NFISCAL,C9_PRCVEN,C9_BLEST,C9_BLCRED, B1_COD "
	cQri += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SB2") + " SB2 "
	cQri += " WHERE SB2.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB2.B2_LOCAL = C9_LOCAL "
	cQri += "   AND SB2.B2_COD = SC9.C9_PRODUTO "
	cQri += "   AND SB2.B2_FILIAL = '" + xFilial("SB2") + "' "
	cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SB1.B1_COD = SC9.C9_PRODUTO "
	cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	If MsgYesNo("Somente a Faturar ?")
		cQri += "AND SC9.C9_NFISCAL = ' ' "
		lSofat := .T.
	Endif
	cQri += "   AND SC9.D_E_L_E_T_ = ' '  "
	cQri += "   AND SC9.C9_PEDIDO = '" + cPed + "'  "
	cQri += "   AND SC9.C9_FILIAL = '" +xFilial("SC9") + "'  "
	cQri += " ORDER BY SC9.C9_ITEM ASC "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQri),'QC6', .F., .T.)

	Count to nRecCount

	oObj:SetRegua2(nREcCount)


	If nRecCount == 0
		//	QC6->(dbClosearea())
		//	Return
	Endif

	Dbselectarea("QC6")
	dbgotop()
	While !Eof()
		oObj:IncRegua2("Processando item "+QC6->C9_ITEM+" do pedido "+cPed)
		If !Empty(QC6->C9_NFISCAL)
			cStatus := "FAT"
		Else
			If !Empty(QC6->C9_BLCRED)
				cStatus := "CRD"
			Elseif !Empty(QC6->C9_BLEST) .And. Empty(QC6->C9_BLCRED)
				cStatus := "BLE"
			Else
				cStatus := "OK"
				nSomafat += (QC6->C9_QTDLIB * QC6->C9_PRCVEN)
				nSomast  += 0
			Endif
		Endif
		Dbselectarea("SC6")
		Dbsetorder(1)
		If Dbseek(xFilial("SC6")+cped+QC6->C9_ITEM)
			nPrunit := SC6->C6_PRUNIT
		Else
			nPrunit := 0.00
		Endif
		Aadd(aBlq,{ QC6->C9_ITEM,;			// 1
		QC6->C9_SEQUEN,;		// 2
		QC6->C9_PRODUTO,;		// 3
		QC6->B1_DESC,;			// 4
		Transform(QC6->B2_QATU - QC6->B2_RESERVA,"@E 999,999.99"),;	// 5
		Transform(QC6->C9_QTDLIB,"@E 999,999.99"),;	//6
		cStatus ,;				// 7
		Transform(QC6->C9_PRCVEN,"@E 999,999.99"),;	// 8
		Transform(QC6->C9_QTDLIB * QC6->C9_PRCVEN,"@E 999,999.99"),; //	9
		QC6->C9_QTDLIB,;		// 10
		Iif(cStatus $ "CRD#BLE",QC6->C9POS,""),;			// 11
		QC6->C9_QTDLIB * QC6->C9_PRCVEN,;	//	12
		nPrunit*QC6->C9_QTDLIB,;				// 13
		QC6->C9_QTDLIB,;					// 14
		Iif(SC6->C6_CF $ "5910 #6910","Bonificada",IIf(SC6->C6_CF $ "5949 #6949","Outras Saidas","Faturamento")),;
		QC6->C9_NFISCAL})

		dbSelectArea("QC6")
		dbSkip()
	EndDo
	QC6->(dbClosearea())

	If !lSofat 

		oObj:IncRegua1("Localizando itens não liberados.")
		oObj:SetRegua2(0)

		cQri := ""
		cQri += "SELECT C6_QTDVEN,C6_ITEM,C6_PRODUTO,B1_DESC,B2_RESERVA,B2_QATU,C6_BLQ,C6_CF,C6_NOTA,"
		cQri += "       C6_PRCVEN,C6_PRUNIT "
		cQri += "  FROM " + RetSqlName("SC6") + " SC6, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SB2") + " SB2 "
		cQri += " WHERE SB2.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB2.B2_LOCAL = C6_LOCAL "
		cQri += "   AND SB2.B2_COD = SC6.C6_PRODUTO "
		cQri += "   AND SB2.B2_FILIAL = '" + xFilial("SB2") + "' "
		cQri += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQri += "   AND SB1.B1_COD = SC6.C6_PRODUTO "
		cQri += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
		cQri += "   AND SC6.D_E_L_E_T_ = ' ' "
		cQri += "   AND SC6.C6_NUM = '" + cPed + "' "
		cQri += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' "

		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQri),'QC61', .F., .T.)

		Count to nRecCount

		oObj:SetRegua2(nREcCount+Len(aBlq))

		If nRecCount == 0
			QC61->(dbClosearea())
		Else
			aItems := aClone(aBlq)
			nLib := 0
			nVar  := 0
			Dbselectarea("QC61")
			dbgotop()
			ProcRegua(nReccount)
			While !Eof()
				oObj:IncRegua2("Processando itens "+QC61->C6_ITEM)
				For z := 1 To Len(aItems)
					If aItems[z,1] == QC61->C6_ITEM
						nVar := aItems[z,10]
						nLib += nVar
					Endif
					oObj:IncRegua2("Procurando..")
				Next

				If nLib < QC61->C6_QTDVEN
					cStatus := "A LIB"
					If Alltrim(QC61->C6_BLQ) == "R"
						cStatus	:= "RES"
					Endif
					Aadd(aBlq,{ QC61->C6_ITEM,;  			// 1
					"  ",;						// 2
					QC61->C6_PRODUTO,;			// 3
					QC61->B1_DESC,;				// 4
					Transform(QC61->B2_QATU - QC61->B2_RESERVA,"@E 999,999.99"),;	// 5
					Transform(QC61->C6_QTDVEN - nLib,"@E 999,999.99"),;	// 6
					cStatus ,;					// 7
					Transform(QC61->C6_PRCVEN,"@E 999,999.99"),;	// 8
					Transform((QC61->C6_QTDVEN - nLib) * QC61->C6_PRCVEN,"@E 999,999.99"),;	// 9
					QC61->C6_QTDVEN - nLib,;	// 10
					" ",;
					(QC61->C6_QTDVEN - nLib) * QC61->C6_PRCVEN,;	//	12
					qc61->C6_PRUNIT * (QC61->C6_QTDVEN - nLib),;				// 13
					(QC61->C6_QTDVEN - nLib),;					// 14
					Iif(QC61->C6_CF $ "5910 #6910","Bonificada",IIf(QC61->C6_CF $ "5949 #6949","Outras Saidas","Faturamento")),;
					QC61->C6_NOTA})
				Endif
				nLib := 0
				dbSelectArea("QC61")
				dbSkip()
			End
			QC61->(dbClosearea())
		Endif
	Endif


	If Len(aBlq) <= 0
		MsgAlert("Não houverem itens para esta situação","Atenção!")
		Return
	Endif

	aSort(aBlq,,,{|x,y| x[1]+x[2] < y[1]+y[2]})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Faz o calculo automatico de dimensoes de objetos     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cPed)
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

	aSize := MsAdvSize()
	aObjects := {}
	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 100, .t., .t. } )
	AAdd( aObjects, { 100, 015, .t., .f. } )
	aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects )
	aPosGet := MsObjGetPos(aSize[3]-aSize[1],315,{{003,033,160,200,240,263}} )
	nGetLin := aPosObj[3,1]

	DEFINE MSDIALOG oVendas TITLE OemToAnsi("Espelho do pedido "+cPed) From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

	EnChoice( "SC5", SC5->(Recno()), 2, , , , , aPosObj[1],,3,,,"",,,)

	//DEFINE MSDIALOG oVendas FROM 001,001 TO aSize[6] , aSize[5] OF oMainWnd PIXEL TITLE OemToAnsi("Espelho do pedido "+cPed)

	//aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4]
	@ aPosObj[2,1],aPosObj[2,2] LISTBOX oBlq VAR cBlq ;
	Fields HEADER ;
	"Item",;		// 1
	"Seq",;			// 2
	"Código",;		// 3
	"Descrição",;	// 4
	"Saldo Estoque",;// 5
	"Qtd Lib",;		// 6
	"Sts",;			// 7
	"Preço Venda",;	// 8
	"Total",;		// 9
	"Qte Lib",;		// 10
	"PosSC9",;      // 11
	"Tipo Faturamento",; //12
	"Nº Nota";
	SIZE aPosObj[2,4],aPosObj[2,3]-aPosObj[2,1] OF oVendas PIXEL
	oBlq:SetArray(aBlq)
	oBlq:bLine:={ ||{aBlq[oBlq:nAT,01],aBlq[oBlq:nAT,02],aBlq[oBlq:nAT,03],aBlq[oBlq:nAT,04],aBlq[oBlq:nAT,05],;
	aBlq[oBlq:nAT,06],aBlq[oBlq:nAT,07],aBlq[oBlq:nAT,08],aBlq[oBlq:nAT,09],aBlq[oBlq:nAT,10],aBlq[oBlq:nAT,11],aBlq[oBlq:nAT,15],aBlq[oBlq:nAT,16]}}
	oBlq:Refresh()
	aButtons	:= {}

	aadd(aButtons,{"BUDGET",{||stVerLog(cPed)},"Ver Log","Ver logs do pedido"  })

	ACTIVATE msDIALOG oVendas ON INIT EnchoiceBar(oVendas,{|| oVendas:End()},{|| oVendas:End()},,aButtons) CENTERED


Return



/*/{Protheus.doc} stVerLog
// Função que aciona o Browser da tabela de Logs de Pedidos
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@param cInPedido, characters, descricao
@type function
/*/
Static Function stVerLog(cInPedido)

	Private cPedSZ0		:= cInPedido

	dbSelectArea("SZ0")
	dbSetOrder(1)
	Set Filter To Z0_PEDIDO == cPedSZ0 .And. Z0_FILIAL == xFilial("SZ0")

	AxCadastro("SZ0","Historico Pedido",".F.",".F.")

	dbSelectArea("SZ0")
	dbSetOrder(1)
	Set Filter To

Return


/*/{Protheus.doc} stExpSC9
// Rotina ao confirmar a seleção de pedidos. Inicia o faturamento dos pedidos e impressão do relatório de Prenota
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static Function stExpSC9()

	
	Local lContinua	:= .F.
	Local cQry 		:= ""
	Local x			:= 1
	Local cNumNota  := Space(TamSX3("F2_DOC")[1])
	Local cNfFats	:= ""
	Local iZ 
	Local aDadosSF2	:= {}
	Local lFirstNfe	:= .T. 
	/*
	MV_PAR01 - Serie
	MV_PAR02 - Nota Inicial
	MV_PAR03 - Nota Final 
	MV_PAR04 - Vendedor Inicial
	MV_PAR05 - Vendedor Final
	MV_PAR06 - Emissao Inicial
	MV_PAR07 - Emissao Final 
	MV_PAR08 - Quebra página por nota 
	*/
	
	
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
				
				aRetFat		:= stGravaF2(aSC9[x,4])  // 1=Série,2=Nota,3=NF Bonificação
				cNfFats 	+= aRetFat[2] + " / "
				If !Empty(aRetFat[3])
					cNfFats 	+= aRetFat[3] + " / "
					If lFirstNfe
						aDadosSF2	:= {aRetFat[1],aRetFat[2],aRetFat[2]," ","zzzzzz",dDataBase,dDataBase}
					Else
						aDadosSF2[3]	:= aRetFat[2]
					Endif
					lFirstNfe	:= .F.
				Endif
			Endif
		Next
		
		Aviso("Geração de Notas!","As seguintes notas foram geradas: "+CRLF+CRLF+cNfFats,{"Ok"},3)
		
		// Efetua a chamada do relatório de impressão de Pedidos para conferência
		U_MLFATR02(aDadosSF2,.F.)
		
	Else
		MsgAlert("Não houveram pedidos selecionados para exportação! ","Atenção.")
	Endif
	
	
Return



/*/{Protheus.doc} stGravaF2
// Função que gera a nota fiscal a partir do número do pedido de venda passado como parâmetro. 
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@param cPedFat, characters, descricao
@type Static Function
/*/
Static Function stGravaF2(cPedFat)

	Local 	cQry 			:= ""
	Local 	nReg 			:= 0
	Local 	cNota			:= ""
	Local	cNfBon			:= ""
	Local 	cSerie			:= GetNewPar("GF_SERIENF","1")
	Local	cNewPedRem		:= ""
	Local	lContOnLine		:= GetNewPar("GF_CTBONLN",.F.)
	Local	lExistRem		:= .F.
	Local	aRegSC9PedRem	:= {}
	Local	lFatSep			:= GetNewPar("GF_FTBONSP",.F.) // Criar o parâmetro se necessário usar regra de Faturar itens sem duplicata em nota separada e ativar o parâmetro
	Private aPvlNfs 		:= {}
	Private aPvlBon			:= {}
	

	Private lMsHelpAuto 	:= .T.
	Private lMsErroAuto 	:= .F.

	cQry := ""
	cQry += "SELECT C9_PEDIDO,C9_ITEM,C9_PRODUTO,C9_QTDLIB,C9_SEQUEN "
	cQry += "  FROM " + RetSqlName("SC9")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND C9_NFISCAL = '      ' "
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

		DbSelectArea ("SC9")
		DbSetOrder(1)
		If DbSeek(xfilial("SC9")+QRYC9->C9_PEDIDO+QRYC9->C9_ITEM+QRYC9->C9_SEQUEN+QRYC9->C9_PRODUTO)

			// Cad. item do pedido de venda
			SC6->(DbSetOrder(1))
			SC6->(DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM



			cPedini := QRYC9->C9_PEDIDO
			//Cad. pedido de venda cab.
			SC5->(DbSetOrder(1))
			SC5->(DbSeek(xFilial("SC5")+SC9->C9_PEDIDO) )                  //FILIAL+NUMERO
			// Cad. item do pedido de venda
			SC6->(DbSetOrder(1))
			SC6->(DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM) )     //FILIAL+NUMERO+ITEM
			// Força ajuste de preço de tabela

			If SC6->C6_PRUNIT == 0
				Begin Transaction 
					DbSelectArea("SC6")
					RecLock("SC6",.F.)
					SC6->C6_PRUNIT	:= SC6->C6_PRCVEN
					MsUnlock()
				End Transaction 
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

			// Verifica se o faturamento de Bonificação/Duplicata é separado ou não 
			If !lFatSep .Or. (SF4->F4_DUPLIC = "S" .And. lFatSep )
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

		Else
			MsgAlert("Item não encontrado na liberacao do pedido - "+QRYC9->C9_PEDIDO+"-"+QRYC9->C9_ITEM,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Sem registros!")
			Return{"","",""}
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

	Endif

Return {cSerie,cNota,cNfBon}

