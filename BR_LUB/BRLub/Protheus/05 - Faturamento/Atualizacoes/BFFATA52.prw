#Include 'Protheus.ch'


/*/{Protheus.doc} BFFATA52
(Rotina de Gerenciamento de dados para RMV Atrialub)
@type function
@author marce
@since 03/06/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA52()
	
	Local	aTFolderCab		:= {}
	Local 	aObjCoords		:= {}
	Local	aAdvSize		:= {}
	Local	aInfoAdvSize	:= {}
	Local 	aObjSize		:= {}
	Local 	aButtons		:= {}
	Local	lOk				:= .F.
	Local	oDialogo
		
	Local	aHedSa3			:= {}
	Local	aColsA3			:= {}
	
	Local	aHedSa1A		:= {}
	Local	aColsA1A		:= {}
	Local	aHedSa1B		:= {}
	Local	aColsA1B		:= {}
	Local	aHedPAE1		:= {}
	Local	aColsPAE1		:= {}
	Local	aHedPAE2		:= {}
	Local	aColsPAE2		:= {}
	Local	aHedPAE3		:= {}
	Local	aColsPAE3		:= {}
	Local	aHedSZN			:= {}
	Local	aColsZN			:= {}
	Local	aCpoCols		:= {}
	Local	cInAlias		:= ""
	
	Private	oTFolderCab

	
	aAdvSize    :=	MsAdvSize( NIL , .F. )
	aInfoAdvSize:=	{aAdvSize[1],aAdvSize[2],aAdvSize[3],aAdvSize[4],0,0}
	aAdd( aObjCoords , { 100 , 170 , .T. , .F. , .F. } )
	aAdd( aObjCoords , { 100 , 260 , .T. , .F. , .F. } )
	aObjSize:= MsObjSize( aInfoAdvSize , aObjCoords )
	DEFINE MSDIALOG oDialogo TITLE OemToAnsi("Manutenção RMV ") From 0,0 TO 100,100 OF GetWndDefault() PIXEL
	oDialogo:lMaximized := .T.
	aTFolderCab	:=	{	"Cad.Vendedores",;
		"Comissão",;
		"Clientes Top",;
		"Clientes X Tabelas",;
		"1-RMV Prazo",;
		"2-RMV Quinzena",;
		"3-RMV Mensal"}
	
	oTFolderCab	:=	TFolder():new(aObjSize[1,1],aObjSize[1,2],aTFolderCab,,oDialogo,,,,.T.,.F.,aObjSize[1,4]-aObjSize[1,2],aObjSize[1,3]-aObjSize[1,1],)
	oTFolderCab:Align := CONTROL_ALIGN_TOP
	
	aCpoCols	:= {"A3_COD","A3_NOME","A3_NREDUZ","A3_DESREG","A3_XTPVEND","A3_TIPO","A3_COMIS","A3_ALEMISS","A3_ALBAIXA","A3_DIA","A3_ICM","A3_ISS","A3_IPI","A3_FRETE","A3_ACREFIN","A3_ICMSRET","A3_DDD","A3_PISCOF","A3_GERASE2","A3_FORNECE","A3_LOJA"}
	cInAlias	:= "SA3"
	sfaCols(@aHedSa3,@aColsA3,cInAlias,aCpoCols,"","A3_FILIAL")
	
	Private oGetSA3 := MsNewGetDados():New(0,0,600,600,GD_UPDATE, "AllwaysTrue", "AllwaysTrue", ""/*cIniCpos*/, ,0, Len(aColsA3), "AllwaysTrue", , "AllwaysTrue", oTFolderCab:aDialogs[1], aHedSa3,aColsA3 )
	oGetSA3:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGetSA3:oBrowse:Refresh()
	
	aCpoCols	:= {"A1_COD","A1_LOJA","A1_NOME","A1_NREDUZ","A1_MUN","A1_EST","A1_VEND","A1_TABELA","A1_XFXCOMI"}
	cInAlias	:= "SA1"
	sfaCols(@aHedSA1A,@aColsA1A,cInAlias,aCpoCols,'A1_XFXCOMI <> "Z"',"A1_FILIAL")
	
	Private oGetSA1A := MsNewGetDados():New(0,0,600,600,0, "AllwaysTrue", "AllwaysTrue", ""/*cIniCpos*/, ,0, Len(aColsA1A), "AllwaysTrue", , "AllwaysTrue", oTFolderCab:aDialogs[3], aHedSa1A,aColsA1A )
	oGetSA1A:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGetSA1A:oBrowse:Refresh()
	
	
	aCpoCols	:= {"A1_TABELA","A1_COD","A1_LOJA","A1_CGC","A1_NOME","A1_NREDUZ","A1_MUN","A1_EST","A1_VEND","A1_VEND2","A1_VEND3"}
	cInAlias	:= "SA1"
	sfaCols(@aHedSA1B,@aColsA1B,cInAlias,aCpoCols,'A1_TABELA <> " "',"A1_FILIAL")
	
	Private oGetSA1B := MsNewGetDados():New(0,0,600,600,0, "AllwaysTrue", "AllwaysTrue", ""/*cIniCpos*/, ,0, Len(aColsA1B), "AllwaysTrue", , "AllwaysTrue", oTFolderCab:aDialogs[4], aHedSa1B,aColsA1B )
	oGetSA1B:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGetSA1B:oBrowse:Refresh()
	
	
	sfSZN(@aHedSZN,@aColsZN)
	
	Private oGetSZN := MsNewGetDados():New(0,0,600,600,0, "AllwaysTrue", "AllwaysTrue", ""/*cIniCpos*/, ,0, Len(aColsZN), "AllwaysTrue", , "AllwaysTrue", oTFolderCab:aDialogs[2], aHedSZN,aColsZN )
	oGetSZN:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGetSZN:oBrowse:Refresh()
	
	
	aCpoCols	:= {"PAE_TABELA","PAE_TIPAPU","PAE_VIGINI","PAE_VIGFIM","PAE_1GATIL","PAE_1PRAZO","PAE_1PERC"}
	cInAlias	:= "PAE"
	sfaCols(@aHedPAE1,@aColsPAE1,cInAlias,aCpoCols,'PAE_TABELA =="1"',"PAE_FILIAL")
	
	Private oGetPAE1 := MsNewGetDados():New(0,0,600,600,0, "AllwaysTrue", "AllwaysTrue", ""/*cIniCpos*/, ,0, Len(aColsPAE1), "AllwaysTrue", , "AllwaysTrue", oTFolderCab:aDialogs[5], aHedPAE1,aColsPAE1 )
	oGetPAE1:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGetPAE1:oBrowse:Refresh()
	
	
	aCpoCols	:= {"PAE_TABELA","PAE_TIPAPU","PAE_VIGINI","PAE_VIGFIM","PAE_2GATIL","PAE_2FORNE","PAE_2PMETA","PAE_2PERC"}
	cInAlias	:= "PAE"
	sfaCols(@aHedPAE2,@aColsPAE2,cInAlias,aCpoCols,'PAE_TABELA =="2"',"PAE_FILIAL")
	
	Private oGetPAE2 := MsNewGetDados():New(0,0,600,600,0, "AllwaysTrue", "AllwaysTrue", ""/*cIniCpos*/, ,0, Len(aColsPAE2), "AllwaysTrue", , "AllwaysTrue", oTFolderCab:aDialogs[6], aHedPAE2,aColsPAE2 )
	oGetPAE2:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGetPAE2:oBrowse:Refresh()
	
	
	aCpoCols	:= {"PAE_TABELA","PAE_TIPAPU","PAE_VIGINI","PAE_VIGFIM","PAE_3GATIL","PAE_3PMETA","PAE_3PERC"}
	cInAlias	:= "PAE"
	sfaCols(@aHedPAE3,@aColsPAE3,cInAlias,aCpoCols,'PAE_TABELA =="3"',"PAE_FILIAL")
	
	Private oGetPAE3 := MsNewGetDados():New(0,0,600,600,0, "AllwaysTrue", "AllwaysTrue", ""/*cIniCpos*/, ,0, Len(aColsPAE3), "AllwaysTrue", , "AllwaysTrue", oTFolderCab:aDialogs[7], aHedPAE3,aColsPAE3 )
	oGetPAE3:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oGetPAE3:oBrowse:Refresh()
	
	
	Aadd( aButtons, {"Cad.RMV", {||  sfCadPAE() }, "Cad.RMV", "Cad.RMV" , {|| .T.}} )
	
	Aadd( aButtons, {"Salvar Vendedores", {||  sfSaveGets(1) }, "Grv.SA3", "Grv.SA3" , {|| .T.}} )
	
	Aadd( aButtons, {"Rec.Off", {|| Processa({|| U_BFFATM33(oGetSA3:aCols[oGetSA3:nAt,1]) },"Processando...") }, "Rec.Com Off", "Rec.Com Off" , {|| .T.}} )
	
	Aadd( aButtons, {"Rec Comissão", {||  FINA440() }, "Rec Comissão", "Rec Comissão" , {|| .T.}} )
	
	Aadd( aButtons, {"Relatório Premiação", {||  U_BFFATR14() }, "Rel.Premiação", "Rel.Premiação" , {|| .T.}} )
	
	
		
	ACTIVATE MSDIALOG oDialogo ON INIT EnchoiceBar(oDialogo,{|| oDialogo:End() },{||oDialogo:End()},,@aButtons)
	
	
Return


Static Function sfSZN(aInHead,aInAcols)

	Local	cQry		:= ""
	Local	aCpoCols	:= {"ZN_FILIAL","ZN_CLIENTE","ZN_LOJACLI","ZN_GRUPO","ZN_CODPROD","ZN_CODTAB","ZN_FAIXINI","ZN_FAIXFIM","ZN_TPVEND"}
	cInAlias	:= GetNextAlias()
	
		
	cQry += "SELECT ZN_CLIENTE,ZN_LOJACLI,ZN_GRUPO,ZN_CODPROD,ZN_CODTAB,ZN_FAIXINI,ZN_FAIXFIM,ZN_FILIAL,"
	cQry += "       ZN_TPVEND,"
    cQry += "       MAX(CASE "
    cQry += "           WHEN ZN_FXCOMIS = 'A' THEN "
    cQry += "            ZN_PCOMIS "
	cQry += "           ELSE "
	cQry += "            0 "
	cQry += "           END) FAIXA_A,"
    cQry += "       MAX(CASE "
    cQry += "           WHEN ZN_FXCOMIS = 'B' THEN "
    cQry += "            ZN_PCOMIS "
	cQry += "           ELSE "
	cQry += "            0 "
	cQry += "           END) FAIXA_B,"
	cQry += "       MAX(CASE "
    cQry += "           WHEN ZN_FXCOMIS = 'C' THEN "
    cQry += "            ZN_PCOMIS "
	cQry += "           ELSE "
	cQry += "            0 "
	cQry += "           END) FAIXA_C,"
	cQry += "       MAX(CASE "
    cQry += "           WHEN ZN_FXCOMIS = 'D' THEN "
    cQry += "            ZN_PCOMIS "
	cQry += "           ELSE "
	cQry += "            0 "
	cQry += "           END) FAIXA_D,"
	cQry += "       MAX(CASE "
    cQry += "           WHEN ZN_FXCOMIS = 'X' THEN "
    cQry += "            ZN_PCOMIS "
	cQry += "           ELSE "
	cQry += "            0 "
	cQry += "           END) FAIXA_X,"
	cQry += "           SUM(CASE "
	cQry += "               WHEN ZN_FXCOMIS = 'A' THEN "
	cQry += "                1 "
	cQry += "               ELSE "
	cQry += "                0 "
	cQry += "             END) QTE_A,"
	cQry += "       SUM(CASE "
	cQry += "               WHEN ZN_FXCOMIS = 'B' THEN "
	cQry += "                1 "
	cQry += "               ELSE "
	cQry += "                0 "
	cQry += "             END) QTE_B,"
	cQry += "       SUM(CASE "
	cQry += "               WHEN ZN_FXCOMIS = 'C' THEN "
	cQry += "                1 "
	cQry += "               ELSE "
	cQry += "                0 "
	cQry += "             END) QTE_C,"
	cQry += "       SUM(CASE "
	cQry += "               WHEN ZN_FXCOMIS = 'D' THEN "
	cQry += "                1 "
	cQry += "               ELSE "
	cQry += "                0 "
	cQry += "             END) QTE_D "
  	cQry += "  FROM " + RetSqlName("SZN") + " ZN "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND ZN_FILIAL = '" + xFilial("SZN")+ "' "
	cQry += " GROUP BY ZN_FILIAL,"
	cQry += "          ZN_CLIENTE,"
	cQry += "          ZN_LOJACLI,"
	cQry += "          ZN_GRUPO,"
	cQry += "          ZN_CODPROD,"
	cQry += "          ZN_CODTAB,"
	cQry += "          ZN_FAIXINI,"
	cQry += "          ZN_FAIXFIM," 
	cQry += "          ZN_TPVEND "
	cQry += " ORDER BY ZN_FILIAL,ZN_TPVEND DESC ,ZN_FAIXFIM, ZN_FAIXINI, ZN_CLIENTE, ZN_LOJACLI, ZN_GRUPO"

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cInAlias,.T.,.F.)"
	
	sfMntX3(cInAlias,@aInHead,aCpoCols)
	
	DbSelectArea("SX3")
	SX3->(DbSetOrder(2))
	
	SX3->(DbSeek("ZN_FILIAL"))
	cUsado := GetSx3Cache("ZN_FILIAL","X3_USADO")	
	
	AADD( aInHead, { "Faixa A","FAIXA_A", "", 09, 0,, cUsado, "N", "", "R"} )
	AADD( aInHead, { "Faixa B","FAIXA_B", "", 09, 0,, cUsado, "N", "", "R"} )
	AADD( aInHead, { "Faixa C","FAIXA_C", "", 09, 0,, cUsado, "N", "", "R"} )
	AADD( aInHead, { "Faixa D","FAIXA_D", "", 09, 0,, cUsado, "N", "", "R"} )
	AADD( aInHead, { "Cliente Top","FAIXA_X", "", 09, 0,, cUsado, "N", "", "R"} )
	
	DbSelectArea(cInAlias)
	While !Eof()
		
			Aadd(aInAcols,Array(Len(aInHead)+1))
		
			For nY := 1 to Len(aInHead)
				If IsHeadRec(aInHead[nY][2])
					aInAcols[Len(aInAcols)][nY] := (cInAlias)->(RecNo())
				ElseIf IsHeadAlias(aInHead[nY][2])
					aInAcols[Len(aInAcols)][nY] := cInAlias
				ElseIf ( aInHead[nY][10] <> "V")
					aInAcols[Len(aInAcols)][nY] := (cInAlias)->(FieldGet(FieldPos(aInHead[nY][2])))
				Else
					aInAcols[Len(aInAcols)][nY] := (cInAlias)->(CriaVar(aInHead[nY][2]))
				EndIf
				aInAcols[Len(aInAcols)][Len(aInHead)+1] := .F.
			Next nY
		DbSelectArea(cInAlias)
		DbSkip()
	Enddo
	
	
	
Static Function sfAcols(aInHead,aInAcols,cInAlias,aCpoCols,cFiltro,cInCpoFil)
	
	Local	cValFil		:= xFilial(cInAlias)
	// Monta SX3
	sfMntX3(cInAlias,@aInHead,aCpoCols)
	
	DbSelectArea(cInAlias)
	DbSetOrder(1)	
	If !Empty(cFiltro)
		Set Filter To &cFiltro 
	Endif
	
	DbGotop()
	DbSeek(xFilial(cInAlias))
	While !Eof() .And. cValFil == (cInAlias)->(FieldGet(FieldPos(cInCpoFil)))
		
		If RegistroOk(cInAlias,.F.)
			Aadd(aInAcols,Array(Len(aInHead)+1))
		
			For nY := 1 to Len(aInHead)
				If IsHeadRec(aInHead[nY][2])
					aInAcols[Len(aInAcols)][nY] := (cInAlias)->(RecNo())
				ElseIf IsHeadAlias(aInHead[nY][2])
					aInAcols[Len(aInAcols)][nY] := cInAlias
				ElseIf ( aInHead[nY][10] <> "V")
					aInAcols[Len(aInAcols)][nY] := (cInAlias)->(FieldGet(FieldPos(aInHead[nY][2])))
				Else
					aInAcols[Len(aInAcols)][nY] := (cInAlias)->(CriaVar(aInHead[nY][2]))
				EndIf
				aInAcols[Len(aInAcols)][Len(aInHead)+1] := .F.
			Next nY
		Endif
		DbSelectArea(cInAlias)
		DbSkip()
	Enddo
	
	DbSelectArea(cInAlias)
	DbSetOrder(1)
	Set Filter To 
Return



Static Function sfMntX3(cInAlias,aInHeaX3,aInCPo)

	Local	iX 		:= 0
	Local	cUsado	:= ""
	Local	aFields	:= {}
	
		
	//DbSelectArea("SX3")
	//SX3->(DbSetOrder(2))
	
	//SX3->(DbSeek(cInAlias + "_FILIAL"))

	aFields := FWSX3Util():GetAllFields(cInAlias, .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cUsado := GetSx3Cache(cCampo,"X3_USADO")
		
		For iX := 1 To Len(aInCpo)
		
			If DbSeek(aInCPo[iX])
				Aadd(aInHeaX3, {AllTrim(X3Titulo()),;
					GetSx3Cache(cCampo,"X3_CAMPO"),;
					GetSx3Cache(cCampo,"X3_PICTURE"),;
					GetSx3Cache(cCampo,"X3_TAMANHO"),;
					GetSx3Cache(cCampo,"X3_DECIMAL"),;
					Iif(GetSx3Cache(cCampo,"X3_CAMPO") $"A3_ALEMISS#A3_ALBAIXA","",GetSx3Cache(cCampo,"X3_VALID")),;
					GetSx3Cache(cCampo,"X3_USADO"),;
					GetSx3Cache(cCampo,"X3_TIPO"),;
					GetSx3Cache(cCampo,"X3_F3"),;
					GetSx3Cache(cCampo,"X3_CONTEXT")})
			Endif
		Next iX
	Next nX
	
	DbSelectArea("SX2")
	DbSetOrder(1)
	If DbSeek(cInAlias)
		AADD( aInHeaX3, { "Alias WT",cInAlias + "_ALI_WT", "", 09, 0,, cUsado, "C", cInAlias, "V"} )
		AADD( aInHeaX3, { "Recno WT",cInAlias + "_REC_WT", "", 09, 0,, cUsado, "N", cInAlias, "V"} )
	Endif
	
Return


Static Function sfSaveGets(nOpcSave)

	// Se Estiver na Aba de Cadastro de Vendedores
	If nOpcSave == 1	
		sfGrvDados(oGetSA3,"SA3")
	Else
	
	Endif

Return 

Static Function sfGrvDados(oInGet,cInAlias)

	Local	nLenCols	:= 0
	Local	nLenHead	:= 0
	Local	oGetNz
	
		// Cria valores dinânimcos
		// Número de linha do Getdados
	nLenCols	:= Len(oInGet:aCols)
		// Número de colunas do Getdados
	nLenHead	:= Len(oInGet:aHeader)
		
	For nX := 1 To nLenCols
		DbSelectArea(cInAlias)
		If !(oInGet:aCols[nX,Len(oInGet:aHeader)+1])
			
				// Procura se o registro já existe na tabela ou não	
			For nY := 1 To nLenHead
				If IsHeadRec(oInGet:aHeader[nY][2])
					If oInGet:aCols[nX,nY] > 0
						(cInAlias)->(MsGoto(oInGet:aCols[nX,nY]))
						RecLock(cInAlias,.F.)
					Else
						RecLock(cInAlias,.T.)
					EndIf
					Exit
				Endif
			Next nY
			
				// Se for exclusão
			If (oInGet:aCols[nX,Len(oInGet:aHeader)+1] .And. oInGet:aCols[nX,nY] > 0)
				(cInAlias)->(dbDelete())
			Else
				For nY := 1 To nLenHead
					If oInGet:aHeader[nY][10] # "V"
						(cInAlias)->(FieldPut(FieldPos(oInGet:aHeader[nY][2]),oInGet:aCols[nX][nY]))
					EndIf
				Next nY
			Endif
			MsUnlock()
		Endif
	Next nX
	
	MsgInfo("Dados gravados com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	
Return


Static Function sfCargaCols(cInAlias,aInHead,aInAcols)

	
	DbSelectArea(cInAlias)
	DbOrderNickName(cInAlias+"APURAC")
	DbSeek(xFilial(cInAlias)+cApurac)
	While !Eof() .And. &(cInAlias+"->"+cInAlias+"_APURAC") == cApurac
		
		Aadd(aInAcols,Array(Len(aInHead)+1))
	
		For nY := 1 to Len(aInHead)
			If IsHeadRec(aInHead[nY][2])
				aInAcols[Len(aInAcols)][nY] := (cInAlias)->(RecNo())
			ElseIf IsHeadAlias(aInHead[nY][2])
				aInAcols[Len(aInAcols)][nY] := cInAlias
			ElseIf ( aInHead[nY][10] <> "V")
				aInAcols[Len(aInAcols)][nY] := (cInAlias)->(FieldGet(FieldPos(aInHead[nY][2])))
			Else
				aInAcols[Len(aInAcols)][nY] := (cInAlias)->(CriaVar(aInHead[nY][2]))
			EndIf
			aInAcols[Len(aInAcols)][Len(aInHead)+1] := .F.
		Next nY
		DbSelectArea(cInAlias)
		DbSkip()
	Enddo
	
Return

Static Function sfCadPAE()
	
	Local	aAreaOld	:= GetArea()

	//AxCadastro("SA1", "Clientes"						, "U_DelOk()", "U_COK()", aRotAdic	, bPre	, bOK		, bTTS	, bNoTTS	, , , aButtons, , )
	DbSelectArea("PAE")
	DbSetOrder(1)
	
	AxCadastro("PAE","Cadastro de Variáveis RMV"	,".T."		 ,".T."		,			,		,  ,		,			, , ,         , , )
	
	RestArea(aAreaOld)

Return
