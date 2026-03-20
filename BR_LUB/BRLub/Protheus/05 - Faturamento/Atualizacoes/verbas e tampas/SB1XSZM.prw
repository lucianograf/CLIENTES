#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

User Function SB1XSZM(cContrato,cCli,cLoja)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³SB1XSZM    ºAutor  ³Daniel		          Data ³  08/02/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Vincular produtos a contratos de compras                     ±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SIGACOM                                                   º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

	Private lGravar  	:= .T.
	Private cCod	 	:= Space(15)
	Private aCols		:= {}
	Private aHeader		:= {}
	Private cDesc       := Space(75)
	Private aAlter		:= {}

// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	If INCLUI .OR. ALTERA
	
		dbselectarea("SA1")
		Dbsetorder(1)
		Dbseek(xFilial("SA1")+ cCli + cLoja )
	
		cNome := SA1->A1_NOME
	
	
		cQre := ""
		cQre += "SELECT ZO_PRODUTO, B1_DESC,ZO_CHAPA "
		cQre += "  FROM " + RetSqlName("SB1") + " SB1, " + RetSqlName("SZO") + " SZO "
		cQre += " WHERE SB1.D_E_L_E_T_ = ' ' "
		cQre += "   AND SB1.B1_COD = SZO.ZO_PRODUTO "
		cQre += "   AND SB1.B1_FILIAL = SZO.ZO_FILIAL "
		cQre += "   AND SZO.D_E_L_E_T_ = ' ' "
		cQre += "   AND SZO.ZO_CONTRAT = '" + cContrato +"' "
		cQre += "   AND SZO.ZO_FILIAL = '"+xFilial("SZO") + "' "
	
		TCQUERY cQre NEW ALIAS "QRE"
	
		dbSelectArea("QRE")
		dbGoTop()
		While !Eof()
			AADD(aCols,{QRE->ZO_PRODUTO,QRE->B1_DESC,QRE->ZO_CHAPA,.F.})
			dbSelectArea("QRE")
			dbSkip()
		End
		QRE->(DbCloseArea())
	
		DbSelectArea("SX3")
		DbSetOrder(2)
		DbSeek("B1_COD")
	
	// /*01*/AADD(aHeader,{ "Cod Prod"      		, "B1_COD"     	, SX3->X3_PICTURE , SX3->X3_TAMANHO, SX3->X3_DECIMAL ,"ExistCpo('SB1',M->B1_COD) .AND. U_VERPROD(M->B1_COD)", "û", "C","SB1", ""})
	/*01*/AADD(aHeader,{ "Cod Prod"      		, "B1_COD"     	, GetSx3Cache("B1_COD","X3_PICTURE"), GetSx3Cache("B1_COD","X3_TAMANHO"), GetSx3Cache("B1_COD","X3_DECIMAL"),"ExistCpo('SB1',M->B1_COD) .AND. U_VERPROD(M->B1_COD)", "û", "C","SB1", ""})
	Aadd(aAlter,"B1_COD")
	DbSeek("B1_DESC")
	// /*02*/AADD(aHeader,{ "Descricao"      		, "cDesc"     	, SX3->X3_PICTURE , SX3->X3_TAMANHO, SX3->X3_DECIMAL ,"", "û", "C", ""})
	/*02*/AADD(aHeader,{ "Descricao"      		, "cDesc"     	, GetSx3Cache("B1_COD","X3_PICTURE"), GetSx3Cache("B1_COD","X3_TAMANHO"), GetSx3Cache("B1_COD","X3_DECIMAL") ,"", "û", "C", ""})
	DbSeek("ZO_CHAPA")
	// /*03*/AADD(aHeader,{ "Num.Patrimonio"  		, "ZO_CHAPA"   	, SX3->X3_PICTURE , SX3->X3_TAMANHO, SX3->X3_DECIMAL ,"", "û", "C","", ""})
	/*03*/AADD(aHeader,{ "Num.Patrimonio"  		, "ZO_CHAPA"   	, GetSx3Cache("B1_COD","X3_PICTURE"), GetSx3Cache("B1_COD","X3_TAMANHO"), GetSx3Cache("B1_COD","X3_DECIMAL") ,"", "û", "C","", ""})
	Aadd(aAlter,"ZO_CHAPA")
	
	//AADD(aCols,{Space(15),Space(55),Space(20),.F.})
	//               1       2
	
	@ 001,001 TO 400,700 DIALOG oDlgProd TITLE OemToAnsi("Vincular produtos ao contrato.")
	
	@ 010,010 Say "Contrato"
	@ 010,051 Get cContrato Picture "@!" Size 40,10 When .F.
	
	@ 010,092 Say "Codigo"  //of oDlg1 pixel                                                   
	
	@ 010,132 Get cCli Picture "@!" Size 40,10 When .F.
	
	@ 010,175 Say "Loja" //of oDlg1 pixel
	@ 010,190 Get cLoja Picture "@!" Size 15,10 When .F.
	
	@ 030,010 Say "Cliente"
	@ 030,050 Get cNome Picture "@!" Size 180,10 When .F.
	
	oItems := MsNewGetDados():New(050,005,160,350,GD_INSERT+GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,"AllwaysTrue()"/*cTudoOk*/,,;
	aAlter,,100/*nMax*/,/*cCampoOk*/,"AllwaysTrue()"/*cSuperApagar*/,/*cApagaOk*/,oDlgProd,@aHeader,@aCols)
	
	@ 180,050 BUTTON "Salvar Itens" Size 90,15 ACTION (Processa({|| U_ItSZO(cContrato,cCli,cLoja)},"Gravando itens..."),oDlgProd:End()) Object oGravar
	
	@ 180,150 BUTTON "Sair" Size 50,15 ACTION Close(oDlgProd)
	
	Activate Dialog oDlgProd Centered
Else
	cQre := ""
	cQre += "SELECT ZO_PRODUTO,ZO_CHAPA, B1_DESC "
	cQre += "  FROM " + RetSqlName("SB1") + " SB1, " + RetSqlName("SZO") + " SZO "
	cQre += " WHERE SB1.D_E_L_E_T_ = ' ' "
	cQre += "   AND SB1.B1_COD = SZO.ZO_PRODUTO "
	cQre += "   AND SB1.B1_FILIAL = SZO.ZO_FILIAL "
	cQre += "   AND SZO.D_E_L_E_T_ = ' ' "
	cQre += "   AND SZO.ZO_CONTRAT = '" + cContrato +"' "
	cQre += "   AND SZO.ZO_FILIAL = '"+xFilial("SZO") + "' "
	
	TCQUERY cQre NEW ALIAS "QRE"
	
	dbSelectArea("QRE")
	dbGoTop()
	While !Eof()
		dbSelectArea("SZO")
		If  DbSeek(xFilial("SZO")+ cContrato + QRE->ZO_PRODUTO+QRE->ZO_CHAPA)
			RecLock("SZO",.F.)
			DbDelete()
			MsUnlock()
		Endif
		Dbselectarea("QRE")
		Dbskip()
	Enddo
	QRE->(DbCloseArea())
	
	
EndIf

Return .T.

User Function VERPROD(cProduto)

For nY := 1 To Len(oItems:aCols)
	If nY # n .And. Alltrim(cProduto) == Alltrim(oItems:aCols[nY,1])
		MsgAlert("Produto já está digitado na linha "+Alltrim(Str(nY)) )
		oItems:aCols[n,2] 	:= " "
		Return .F.
	Endif
Next

oItems:aCols[n][2]	:= Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_DESC")



Return .T.

/*User Function ItSZO(aItems)
If !(aItems == NIL)
AADD(aItSZO,aItems)
Else
MsgAlert("Nenhum produto vinculado!" )
Return .F.
EndIf
Return*/

	User Function ItSZO(cContrat,cCli,cLoja)
		For x := 1 To Len(oItems:aCols)
			If !oItems:aCols[x][Len(aHeader)+1]
				dbSelectArea("SZO")
				If !DbSeek(xFilial("SZO")+ cContrat + cCli + cLoja + oItems:aCols[x][1] + oItems:aCols[x][3]) .AND. !Empty(oItems:aCols[x][1])
					RecLock("SZO",.T.)
					SZO->ZO_FILIAL   := xFilial("SZO")
					SZO->ZO_CONTRAT  := cContrat
					SZO->ZO_PRODUTO  := Alltrim(oItems:aCols[x][1])
					SZO->ZO_CLIENTE  := cCli
					SZO->ZO_LOJA	 := cLoja
					SZO->ZO_CHAPA	 := Alltrim(oItems:aCols[x][3])
					MsUnLock()
				Endif
			Else
				dbSelectArea("SZO")
				If  DbSeek(xFilial("SZO")+ cContrat + cCli + cLoja + oItems:aCols[x][1] + oItems:aCols[x][3])
					RecLock("SZO",.F.)
					DbDelete()
					MsUnlock()
				Endif
			Endif
		Next
	Return .T.

