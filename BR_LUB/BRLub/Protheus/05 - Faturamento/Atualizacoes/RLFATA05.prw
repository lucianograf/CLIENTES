#INCLUDE "topconn.ch"
#include "rwmake.ch"
#INCLUDE "PROTHEUS.CH"

User Function RLFATA05()

	Local aAreaOld			:= GetArea()
	Local cTitulo	 		:= OemToAnsi("Envio de notas para separação na Expedição!")

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
	Private cVarPesq		:= Space(9)
	Private oTotVol,oTotPeso,oTotValor,oTotPedidos
	Private nTotVol		:= nTotPeso		:= nTotValor 	:= nTotPedidos	:= 0
	Private nColPos 		:= 1
	Private lSortOrd		:= .F.
	Private aResumo			:= {}
	Private nOpcLoc			:= 0


	If !cEmpAnt $ "06#16"
		MsgAlert("Rotina específica da empresa 06-Redelog","Conferência Notas")
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
		" ",;                   // 1
	" ",;                   // 2
	"Nota",;                    // 3
	"Emissão",;                 // 4
	"CNPJ - Nome Cliente",;     // 5
	"Cidade",;                  // 6
	"Volumes Estimados",;  		// 7
	"Data/Hora Envio",;         // 8
	"Data/Hora Conferência",;   // 9
	"Chave Eletrônica";			// 10
	SIZE aPosObj[2,4], aPosObj[2,3]-30;
		ON DBLCLICK (stDblClick()) OF oPanel2 PIXEL
	oSC9:Align := CONTROL_ALIGN_ALLCLIENT

	oSC9:nFreeze := 3
	oSC9:SetArray(aSC9)
	oSC9:bLine:={ ||{ Iif(Empty(aSC9[oSC9:nAT,08]+aSC9[oSC9:nAT,09]),oVerde,(Iif(!Empty(aSC9[oSC9:nAT,09]),oAzul,Iif(Empty(aSC9[oSC9:nAT,08]),oVerde,oVermelho)))),;
		Iif(aSC9[oSC9:nAT,02],oMarked,oNoMarked),;
		aSC9[oSC9:nAT,03],;
		aSC9[oSC9:nAT,04],;
		aSC9[oSC9:nAT,05],;
		aSC9[oSC9:nAT,06],;
		Transform(aSC9[oSC9:nAT,07],"@E 999,999,999"),;
		aSC9[oSC9:nAT,08],;
		aSC9[oSC9:nAT,09],;
		aSC9[oSC9:nAt,10]}}
	oSC9:Refresh()

	oSC9:bHeaderClick := {|| cVarPesq := aSC9[oSC9:nAt,3],nColPos :=oSC9:ColPos,lSortOrd := !lSortOrd, aSort(aSC9,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),stVldPesC9()}


	@ 005,010 BITMAP oBmp RESNAME "BR_VERDE" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,020 SAY "- A Separar " of oPanel3 pixel
	@ 005,080 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 005,090 SAY "- Enviado Separação" of oPanel3 pixel
	@ 020,080 BITMAP oBmp RESNAME "BR_AZUL" SIZE 50,10 NOBORDER of oPanel3 pixel
	@ 020,090 SAY "- Conferido" of oPanel3 pixel

	@ 035,010 SAY "Pesquisar Nota" of oPanel3 pixel
	@ 035,060 MSGET cVarPesq Valid stVldPesC9() of oPanel3 pixel

	@ 005,160 Say "Volumes" of oPanel3 Pixel
	@ 050,160 Say "Pedidos" of oPanel3 Pixel

	@ 005,185 MsGet oTotVol Var nTotVol  Picture "@E 999,999.9999" Size 50,10  READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel
	@ 050,185 MsGet oTotPedidos Var nTotPedidos Picture "@E 999,999" Size 50,10 READONLY COLOR CLR_BLACK NOBORDER of oPanel3 pixel


	@ 010,280 BUTTON "&Envia" 	 of oPanel3 pixel SIZE 60,13 ACTION (Processa({|| stExpSC9() },"Exportando pedidos..."),oDlg:End() )
	@ 010,350 BUTTON "&Cancela" of oPanel3 pixel SIZE 60,13 ACTION (oDlg:End() )
	@ 010,560 Button "Exportar Excel" of oPanel3 Pixel Size 60,13 Action stExpExcel()

	ACTIVATE MSDIALOG oDlg CENTERED

	RestArea(aAreaOld)

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

	Local nStatus 		:= 0
	Local cQry



	cQry := ""
	cQry += "SELECT Z1_CHAVE,Z1_NOTA,Z1_SERIE,Z1_EMISSAO,Z1_FILIAL,Z1_CHAVE,Z1_DTHRCON,Z1_DTHRENV,"
	cQry += "       A1B.A1_COD,A1B.A1_LOJA,A1B.A1_CGC,A1B.A1_NOME,A1B.A1_MUN, "

	If SB1->(FieldPos("B1_CONVA")) <> 0
		cQry += "   (SELECT SUM(CASE WHEN B1_MIUD = 'N' THEN TRUNC(Z2_QUANT/ CASE WHEN B1_CONVA= 0 THEN 1 ELSE B1_CONVA END) ELSE 0 END) "
		cQry += "      FROM " + RetSqlName("SZ2") + " Z2," + RetSqlName("SB1") + " B1, " + RetSqlName("SA7")  + " A7 "
		cQry += "     WHERE B1.D_E_L_E_T_ = ' ' "
		cQry += "       AND B1_COD = A7_PRODUTO "
		cQry += "       AND B1_FILIAL = '"+xFilial("SB1") + "' "
		cQry += "       AND A7.D_E_L_E_T_ = ' ' "
		cQry += "       AND A7_LOJA = A1A.A1_LOJA "
		cQry += "       AND A7_CLIENTE = A1A.A1_COD "
		cQry += "       AND A7_CODCLI = Z2_PRODUTO "
		cQry += "       AND A7_FILIAL = '" + xFilial("SA7") + "' "
		cQry += "       AND Z2.D_E_L_E_T_ =' ' "
		cQry += "       AND Z2_CHAVE = Z1_CHAVE "
		cQry += "       AND Z2_FILIAL = '" + xFilial("SZ2") + "' ) AS VOLUMES "
	Else
		cQry += "       0 VOLUMES "
	Endif
	cQry += "  FROM " + RetSqlName("SZ1") + " Z1 " 
	cQry += "  LEFT JOIN " + RetSqlName("SA1") + " A1A  " 
	cQry += "    ON A1A.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1A.A1_CGC = Z1_EMIT "
	cQry += "   AND A1A.A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "  LEFT JOIN " + RetSqlName("SA1") + " A1B  "
	cQry += "    ON A1B.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1B.A1_CGC = Z1_DEST "
	cQry += "   AND A1B.A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += " WHERE Z1.D_E_L_E_T_ = ' ' "
	cQry += "   AND Z1_FILIAL = '"+xFilial("SZ1")+"' "
	cQry += "   AND Z1_EMISSAO >= '" +DTOS(Date()-7) + "' "
	
	If MsgYesNo("Filtrar notas não enviadas para separação?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		cQry += "   AND Z1_DTHRENV = ' ' "
	ElseIf MsgYesNo("Filtrar notas sem conferência?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		cQry += "   AND Z1_DTHRCON = ' ' "
	Endif 
	cQry += " ORDER BY Z1_EMISSAO DESC,Z1_NOTA"

	TCQUERY cQry NEW ALIAS "QRP"

	Count to nReg

	dbselectarea("QRP")
	dbGotop()
	ProcRegua(nReg)
	While !Eof()
		lExistLust	:= .F.

		IncProc("Processando Pedido Nº-> "+QRP->Z1_NOTA)

		nStatus	:= 1

		If Empty(QRP->Z1_DTHRENV)
			nStatus	:= 2   //VERDE
		EndIf

		AAdd( aSC9, { 	nStatus,;							// 1
		.F.,;												// 2
		QRP->Z1_NOTA,;										// 3 Nota
		STOD(QRP->Z1_EMISSAO),;								// 4 Emissão
		Transform(QRP->A1_CGC,"@R 99.999.999/9999-99") + " / " + QRP->A1_NOME,;					// 5 Cliente
		QRP->A1_MUN,;	 									// 6 Cidade
		QRP->VOLUMES,;										// 7 Volumes
		QRP->Z1_DTHRENV,; 						   			// 8 Dt/Hr Envio
		QRP->Z1_DTHRCON,;									// 9 Dt/Hr Conferência
		QRP->Z1_CHAVE})										// 10 Chave

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

	Local 	iX

	nTotVol		:= 0
	nTotPeso	:= 0
	nTotValor	:= 0
	nTotPedidos	:= 0

	aSC9[oSc9:nAt,2] := Iif(!aSC9[oSc9:nAt,2] .And. (aSC9[oSc9:nAt,1]>=1 .And. aSC9[oSc9:nAt,1] < 5) ,.T., .F.)

	For iX := 1 To Len(aSC9)
		If aSC9[iX,2]
			nTotVol		+= aSC9[iX,7]
			nTotPedidos += 1
		Endif
	Next
	oTotPedidos:Refresh()
	oTotVol:Refresh()

Return


Static Function stVldPesC9()

	Local nAscan := Ascan(aSC9,{|x|x[3]==cVarPesq})

	If nAscan <=0
		nAscan	:= 1
	Endif
	oSC9:nAT 	:= nAscan
	cVarPesq	:= Space(9)
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
	If !MsgYesNo("Deseja realmente enviar as notas selecionadas para a separação?")
		Return
	Endif

	If lContinua

		For x := 1 To Len(aSC9)

			If 	aSC9[x,2]

				// Inicia proteção na Gravação dos Dados
				// Se houver algum erro durante o processo será executa um RollBack no Banco de Dados

				//Begin Transaction
				BeginTran()

				sfGvs(aSC9[x,10],aSC9[x,3])

				DbSelectArea("SZ1")
				DbSetOrder(1)
				If DbSeek(xFilial("SZ1")+aSC9[x,10])
					RecLock("SZ1",.F.)
					SZ1->Z1_DTHRENV		:= DTOC(Date()) + " " + Substr(Time(),1,5)
					MsUnlock()
				Endif 

				EndTran()

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
Static Function sfGvs(cInChave,cInNota)

	Local		nConta   := 0
	Local		cQry 	:= ""
	Local		cItem	:= "00"
	Local		cFlg	:= ""
	Local		nQuebra	:= 0


	cQry := ""
	cQry += "SELECT Z2_PRODUTO,Z2_QUANT,Z2_ITEM,"
	cQry += "       COALESCE(B1_MIUD,'N') B1_MIUD,COALESCE(B1_CONVA,0) B1_CONVA,COALESCE(B1_XLOCAL,' ') B1_XLOCAL,COALESCE(B1_DESC,' ' ) B1_DESC , "
	cQry += "       A1B.A1_NOME,A1B.A1_MUN "
	cQry += "  FROM " + RetSqlName("SZ2") + " Z2 "
	cQry += " INNER JOIN " + RetSqlName("SZ1") + " Z1 " 
	cQry += "    ON Z1.D_E_L_E_T_ =' ' "
	cQry += "   AND Z1_CHAVE = '"+cInChave + "' " 
	cQry += "   AND Z1_FILIAL = '"+ xFilial("SZ1") + "'" 
	cQry += "  LEFT JOIN " + RetSqlName("SA1") + " A1A  " 
	cQry += "    ON A1A.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1A.A1_CGC = Z1_EMIT "
	cQry += "   AND A1A.A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "  LEFT JOIN " + RetSqlName("SA1") + " A1B  "
	cQry += "    ON A1B.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1B.A1_CGC = Z1_DEST "
	cQry += "   AND A1B.A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "  LEFT JOIN " + RetSqlName("SA7")  + " A7 "
	cQry += "    ON A7.D_E_L_E_T_ = ' ' "
	cQry += "   AND A7_LOJA = A1A.A1_LOJA "
	cQry += "   AND A7_CLIENTE = A1A.A1_COD "
	cQry += "   AND A7_CODCLI = Z2_PRODUTO "
	cQry += "   AND A7_FILIAL = '" + xFilial("SA7") + "' "
	cQry += "  LEFT JOIN " + RetSqlName("SB1") + " B1 "
	cQry += "    ON B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = A7_PRODUTO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1") + "' "
	cQry += " WHERE Z2.D_E_L_E_T_ =' ' "
	cQry += "   AND Z2_CHAVE ='"+cInChave+"' "
	cQry += "   AND Z2_FILIAL = '" + xFilial("SZ2") + "' "
	cQry += " ORDER BY Z2_ITEM"

	TCQUERY cQry NEW ALIAS "ITEM"

	While !Eof()


		cItem	:= Soma1(cItem)


		If ITEM->B1_MIUD == "S"
			nQuebra := ITEM->Z2_QUANT          // se o produto for miudeza, GVS irá separar tudo.
		Else
			nQuebra := Mod(ITEM->Z2_QUANT,Iif(ITEM->B1_CONVA<=0,1,ITEM->B1_CONVA))
		Endif

		If nQuebra > 0
			nConta++
			cFlg 	:= "F"
		Else
			cFlg	:= "C"
			nconta++
		Endif


		If cFlg == "F"
			cFlg := "F - Quantidade Fracionada"
		Elseif cFlg == "C"
			cFlg := "C - Caixa Fechada"
		Endif

		cProd := AllTrim(ITEM->Z2_PRODUTO)


		aDados	:= {	cInNota,;	// 1
		ITEM->Z2_ITEM,;				// 2
		Iif(nQuebra > 0 ,"X"," "),;	// 3
		Iif(Empty(cFlg)," ",cFlg),;	// 4
		cProd,;						// 5
		ITEM->B1_DESC,;				// 6
		ITEM->Z2_QUANT,;			// 7
		ITEM->B1_XLOCAL,;			// 8
		nQuebra,;					// 9
		ITEM->A1_NOME,;				// 10 
		ITEM->A1_MUN}				// 11


		Aadd(aResumo,aDados)


		cFlg := ""

		dbSelectArea("ITEM")
		dbSkip()
	Enddo

	ITEM->(DbCloseArea())


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
	Private Cabec1  := "   Cod.Produto     Descricao                                 Quantidade Endereco"
	Private imprime := .T.
	Private aOrd    := {}

	Private lEnd        := .F.
	Private lAbortPrint := .F.
	Private limite      := 80
	Private tamanho     := "P"
	Private nomeprog    := "RFFATA05"
	Private nTipo       := 18
	Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey    := 0
	Private cPerg       := "RFFATA05"
	Private cbtxt       := Space(10)
	Private cbcont      := 00
	Private CONTFL      := 01
	Private m_pag       := 01
	Private wnrel       := "RFFATA05"
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

	RptStatus({|| RunReport(Cabec1,Titulo,nLin,lInReimp) },Titulo)
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
Static Function RunReport(Cabec1,Titulo,nLin,lInReimp)

	Local cNumPed	 	:= ""
	Local nFlg    		:= 0
	Local y,x


	aSort(aResumo,,,{|x,y| x[1]+x[2] < y[1]+y[2]})

	For x:= 1 to len(aResumo)

		If cNumPed <> Alltrim(aResumo[x,1])

			nLin := Cabec(Titulo,"","",NomeProg,Tamanho,nTipo)


			nLin++
			@nLin,000 PSAY "Nota Fiscal : " + aResumo[x,1] + " - Cidade: " + Alltrim(aResumo[x,11])
			nLin++
			@nLin,000 Psay "Cliente: "+ aResumo[x,10]
			nLin++
			@nLin,000 Psay Cabec1
			nLin++
			@nLin,000 psay "--------------------------------------------------------------------------------"
			nLin++

			For y := 1 To Len(aResumo)
				If Alltrim(aResumo[y,1]) == Alltrim(aResumo[x,1])

					nFlg += 1

					If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
						Cabec(Titulo,Cabec1,"",NomeProg,Tamanho,nTipo)
						nLin := 8
					Endif

					@nLin,000 Psay Substr(aResumo[y,2],2,2) 	// Item
					@nLin,003 Psay Substr(aResumo[y,5],1,20)	// Produto
					@nLin,019 psay Substr(aResumo[y,6],1,40)	// Descrição
					@nLin,061 psay Transform(aResumo[y,7],"@E 999,999.99")	// Quantidade
					@nLin,072 Psay aResumo[y,8]					// Endereço
					nLin++
					// Chamado 24.546 - Impressão completa do produto
					If Len(Alltrim(aResumo[y,6])) > 40
						@nLin,019 psay Substr(aResumo[y,6],41,40)
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
			nLin++
			@nLin,000 Psay ("Total de itens enviados é de: "+Alltrim(Str(nFlg)))
			nLin++
			@nLin,000 psay "----------------------------------------------------------------------------------"
			nLin++
			nLin++
			nFlg := 0
			If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
				Cabec(Titulo,Cabec1,,NomeProg,Tamanho,nTipo)
				nLin := 8
			Endif

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

			@nLin,000 psay "Legenda: X=Miudeza/Fracionado"
			@nLin++

			If nLin > 62 // Salto de Página. Neste caso o formulario tem 55 linhas...
				Cabec(Titulo,Cabec1,,NomeProg,Tamanho,nTipo)
				nLin := 8
			Endif
		Endif
		cNumPed := Alltrim(aResumo[x,1])

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

