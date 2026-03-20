#Include "PROTHEUS.CH"
//--------------------------------------------------------------
/*/{Protheus.doc} ButFilter
Função Cria filtro genérico inteligente.                                                    

Retorno cRet 
Data 09/04/2014                                                   
/*/                                                             
//--------------------------------------------------------------//

User Function YudFilter(cTabela,aCamGrid,aCamFil,cCondicao)

	Local oFiltra
	Local oSay1 
	Local oSay2
	Local oSButton1
	Local oSButton2
	Local oSButton3
	Local aArea
	Private oMsGet
	Private cCodigo := Space(80) //teste
	Private cDescr  := Space(80)
	Private aCampGr := aCamGrid

	//Private cRetCod := ''
	Private aRetDecFil := {}
	Private oDlgFil
	Private cFilArmz := GetMv("MV_ZFILARM")

	aArea             := GetArea()

	DEFINE MSDIALOG oDlgFil TITLE "Consulta - Produtos" FROM 000, 000  TO 500, 950 COLORS 0, 16777215 PIXEL

	@ 005, 019 SAY oSay1 PROMPT "Pesquisa  " SIZE 030, 007 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 035, 019 SAY oSay2 PROMPT "Descrição " SIZE 030, 007 OF oDlgFil COLORS 0, 16777215 PIXEL

	@ 003, 055 MSGET oCodigo VAR cCodigo SIZE 110, 010 OF oDlgFil COLORS 0, 16777215 PIXEL
	@ 033, 055 MSGET oDescr VAR cDescr SIZE 110, 010 OF oDlgFil COLORS 0, 16777215 PIXEL

	DEFINE SBUTTON oFiltra FROM 004, 170 TYPE 17 OF oDlgFil ENABLE ;
	ACTION YudFiltra(cTabela,aCamGrid,aCamFil,cCodigo,cCodigo,cCondicao)
	DEFINE SBUTTON oLimpa FROM 004, 200 TYPE 03 OF oDlgFil ENABLE ACTION ButLimpF()

	MontaGrid(cTabela,aCamGrid,cCondicao)
	DEFINE SBUTTON oOk FROM 231, 020 TYPE 01 OF oDlgFil ENABLE  ACTION YudRetCo()
	DEFINE SBUTTON oCancela FROM 231, 053 TYPE 02 OF oDlgFil ENABLE  ACTION oDlgFil:end() 

	ACTIVATE MSDIALOG oDlgFil CENTERED

	RestArea(aArea)

//Return cRetCod
Return aRetDecFil

//--------------------------------------------------------------
/*/{Protheus.doc} YudRetCo
Função que dá o retorno do filtro.                                                    

Retorno cRetCod                                           
Data 09/04/2014                                                   
/*/                                                             
//--------------------------------------------------------------
Static Function YudRetCo()

	//cRetCod := oMsGet:aCols[oMsGet:nAt][1]
	
	aAdd(aRetDecFil,oMsGet:aCols[oMsGet:nAt][1])
	aAdd(aRetDecFil,oMsGet:aCols[oMsGet:nAt][3])
	
	oDlgFil:end()

Return

//--------------------------------------------------------------
/*/{Protheus.doc} ButEsto
Função que abre tela de informações de estoque.                                                    

Retorno cRetCod                                            
Data 09/04/2014                                                   
/*/                                                             
//--------------------------------------------------------------
Static Function ButEsto()
	Local aArea := GetArea()
	Local cRetCod := oMsGet:aCols[oMsGet:nAt][1]

	Set Key VK_F4 TO
	If FWModeAccess("SB1")=="E"
		cFilAnt := SB1->B1_FILIAL
	EndIf	
	MaViewSB2(cRetCod)
	//cRetCod := ""
	RestArea(aArea)
Return

//--------------------------------------------------------------
/*/{Protheus.doc} MontaGrid
Função que cria a grid de pesquisa.                                                    

Data 09/04/2014                                                   
/*/                                                             
//--------------------------------------------------------------
Static Function MontaGrid(cTabela,aCamGrid,cCondicao)

	Local nX
	Local aHeaderEx := {}
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFieldl := {}
	Local aFields := aCamGrid
	Local aAlterFields := {}
	Local cSql := ''
	Local nTam := 0
	Local cPesq	:= "|"
	Local nA 

	//Local cTabPre := GETNEWPAR( "FT_TABPRE","001")
	Private cTab := GetNextAlias()

	// Define field properties
	DbSelectArea("SX3")
	SX3->(DbSetOrder(2))
	For nX := 1 to Len(aFields)
		If SX3->(DbSeek(aFields[nX]))
			Aadd(aHeaderEx, {AllTrim(X3Titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,;
			SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO})
		Endif
	Next nX

	// Define field values
	For nX := 1 to Len(aFields)
		If DbSeek(aFields[nX])
			Aadd(aFieldFill, CriaVar(SX3->X3_CAMPO))
		Endif
	Next nX
	Aadd(aFieldFill, .F.)

	cSql := "SELECT B1_COD,B1_DESC,SB2.B2_LOCAL,"
	cSql += "       SUM(SB2.B2_QATU - SB2.B2_QACLASS) B2_QATU, (SB2.B2_QATU-SB2.B2_QEMP-SB2.B2_RESERVA-SB2.B2_QPEDVEN-SB2.B2_QACLASS) AS AA3_SLDDIS " 
	cSql += "  FROM " + RetSqlName("SB1") + " SB1 " //+ ",SB2010 SB2 "  
	cSql += "  LEFT JOIN "+ RetSqlName("SB2") + " SB2 "
	cSql += "    ON SB1.B1_COD = SB2.B2_COD "
	cSql += "   AND SB1.D_E_L_E_T_ = SB2.D_E_L_E_T_
	cSql += "   AND SB2.B2_FILIAL = '"+xFilial("SB2")+"'"
	/*
	TSCB56 - Rafael de Souza 04/09/19
	Adicionado esta condição para verificar se tem algum armazem no parametro MV_ZFILARM
	para inibir a exibição em tela.
	*/
	If !Empty(cFilArmz) 
		cFilArmz := STRTRAN(cFilArmz, cPesq, "','")
		cSql += " AND SB2.B2_LOCAL NOT IN ('"+cFilArmz+"') "
	EndIf
	cSql += " WHERE SB1.D_E_L_E_T_ = ' ' "
	cSql += "   AND B1_MSBLQL <> '1' "
	cSql += "   AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
	cSql += "   AND B1_TIPO NOT IN('GN' ) "
	If !Empty(cCondicao)
		cSql += " AND B1_COD LIKE '%"+AllTrim(cCondicao)+"%'"
	EndIf

	cSql += " GROUP BY SB1.B1_COD, SB1.B1_DESC, SB2.B2_LOCAL, (B2_QATU-B2_QEMP-B2_RESERVA-B2_QPEDVEN-SB2.B2_QACLASS)"

	cSql := ChangeQuery(cSql)

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cSql),cTab,.T.,.T.)
	
	(cTab)->( dbGoTop() )
	while ( (cTab)->(!Eof()) )
		aFieldl := aclone(aFieldFill)
		For na := 1 To len(aFields) 
			nPos := aScan(aHeaderEx,{|x| AllTrim(x[2]) == aFields[na]})
			If nPos > 0
				ny   := "(cTab)->" + aFields[na]  
				aFieldl[nPos] := &ny
			EndIf   
		Next na

		Aadd(aColsEx, aFieldl)

		aFieldl := {}
		(cTab)->(dbSkip())
	end

	if len(aColsEx) < 1
		Aadd(aColsEx, aFieldFill)
	endif

	DBCLOSEAREA(cTab)
	// 354
	oMsGet := MsNewGetDados():New( 020, 020, 222, 470, GD_INSERT+GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgFil, aHeaderEx, aColsEx)
	oMsGet :oBrowse:bLDblClick := {|| YudRetCo()}

Return

//--------------------------------------------------------------
/*/{Protheus.doc} YudFiltra
Função que filtra a grid de pesquisa.            MT010F4()                                        

Data 09/04/2014                                                   
/*/                                                             
//--------------------------------------------------------------
Static Function YudFiltra(cTabela,aCamGrid,aCamFil,cCodigo,cDescr,cCondicao)

	Local cCondCod := STRTRAN(trim(cCodigo),"%","")
	Local cCondDes := STRTRAN(trim(cDescr),"%","")
	Local cSql := ''
	Local aColsEx := {}
	Local aHeaderEx := oMsGet:aHeader
	Local aColsEx := {}
	Local aFieldFill := {}
	Local aFieldl := {}
	Local aFields := aCamGrid
	Local aAlterFields := {}
	Local lAsteri := if(At("*",cCodigo)>0,.T.,.F.)
	Local cTabPre := GETNEWPAR( "FT_TABPRE","001")
	Local cPesq	:= "|"
	Local nX 
	Local nA 
	Private cTab := GetNextAlias()

	cCondCod := STRTRAN(trim(cCondCod),"*","%")
	cCondDes := STRTRAN(trim(cCondDes),"*","%")
	cCondCod := upper(cCondCod)
	cCondDes  := upper(cCondDes)

	DbSelectArea("SX3")
	SX3->(DbSetOrder(2))
	For nX := 1 to Len(aFields)
		If DbSeek(aFields[nX])
			Aadd(aFieldFill, CriaVar(SX3->X3_CAMPO))
		Endif
	Next nX
	Aadd(aFieldFill, .F.)


	cSql := "SELECT SB1.B1_COD, SB1.B1_DESC, "
	cSql += "       SB2.B2_LOCAL,SUM(SB2.B2_QATU - SB2.B2_QACLASS) B2_QATU, (SB2.B2_QATU-SB2.B2_QEMP-SB2.B2_RESERVA-SB2.B2_QPEDVEN-SB2.B2_QACLASS) AS AA3_SLDDIS " 
	cSql += "  FROM " + RetSqlName("SB1") + " SB1 " 
	cSql += "  LEFT JOIN " + RetSqlName("SB2") + " SB2 "
	cSql += "    ON SB1.B1_COD = SB2.B2_COD "
	cSql += "   AND SB1.D_E_L_E_T_ = ' '  "
	cSql += "   AND SB2.B2_FILIAL = '"+xFilial("SB2")+"'"
	/*
	TSCB56 - Rafael de Souza 04/09/19
	Adicionado esta condição para verificar se tem algum armazem no parametro MV_ZFILARM
	para inibir a exibição em tela.
	*/
	If !Empty(cFilArmz) 
		cFilArmz := STRTRAN(cFilArmz, cPesq, "','")
		cSql += " AND SB2.B2_LOCAL NOT IN ('"+cFilArmz+"') "
	EndIf
	
	cSql += " WHERE SB1.D_E_L_E_T_ = ' ' "
	cSql += "   AND B1_MSBLQL <> '1' "
	cSql += "   AND B1_TIPO NOT IN('GN' ) "
	cSql += "   AND SB1.B1_FILIAL = '"+xFilial("SB1")+"'"
	If !Empty(cCondicao)
		cSql += " AND B1_COD LIKE '%"+AllTrim(cCondicao)+"%'"
	EndIf
	If trim(cCondDes) != '' 
		If !lAsteri 
			cSql += " and (  "
		Else            
			cSql += " and "
		EndIf  
	EndIf   
	cConCod := ""       
	if trim(cCondCod) != '' .and. !lAsteri
		cConCod := " UPPER(" + cTabela + "." + aCamGrid[1] + ") like UPPER('%" + cCondCod + "%') "
	endif 
	if trim(cConCod) != '' .and. !lAsteri
		cSql += cConCod + " or "
	endif
	if trim(cCondDes) != '' 
		cSql += " UPPER(" + cTabela + "." + aCamGrid[2] + ") like UPPER('%" + cCondDes + "%') "
	endif    
	If !lAsteri .and. trim(cCondDes) != ''
		cSql += " )  "
	EndIf

	
	
	cSql += " GROUP BY SB1.B1_COD, SB1.B1_DESC, SB2.B2_LOCAL, (SB2.B2_QATU-SB2.B2_QEMP-SB2.B2_RESERVA-SB2.B2_QPEDVEN-SB2.B2_QACLASS) "


	cSql := ChangeQuery(cSql)

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cSql),cTab,.T.,.T.)
	
	(cTab)->( dbGoTop() )
	while ( (cTab)->(!Eof()) )
		aFieldl := aclone(aFieldFill)
		For na := 1 To len(aFields) 
			nPos := aScan(aHeaderEx,{|x| AllTrim(x[2]) == aFields[na]})
			If nPos > 0
				ny   := "(cTab)->" + aFields[na]  
				aFieldl[nPos] := &ny
			EndIf   
		Next na

		Aadd(aColsEx, aFieldl)

		aFieldl := {}
		(cTab)->(dbSkip())
	end

	if len(aColsEx) < 1
		Aadd(aColsEx, aFieldFill)
		aColsEx[1][1]:=''
	endif

	DBCLOSEAREA(cTab)

	oMsGet:aCols := aColsEx

return

//--------------------------------------------------------------
/*/{Protheus.doc} ButLimpF
Função que limpa o filtro de pesquisa.                                                    

Data 09/04/2014                                                   
/*/                                                             
//--------------------------------------------------------------
Static Function ButLimpF()

	cCodigo := Space(80)
	cDescr  := Space(80)
	cPesq   := Space(80)
	cGrupo  := space(80)
	cNcm    := space(80)
	cGrupoTr:= space(80)

return

//Static cRetFiltro := ''
Static aRetFiltro := {}

//-------------------------------------------------------------------
/*/{Protheus.doc} FilProd
Faz a chamada da Função de pesquisa. 
Cria o array com os campos a serem utilizados na grid e na pesquisa.                                                   

Data 09/04/2014                                                   
/*/                                                             
//-------------------------------------------------------------------
User Function FilProd(cCondicao,cProduto)

	Local cTabela   := 'SB1'
	Local aCamGrid  := {'B1_COD','B1_DESC','B2_LOCAL','AA3_SLDDIS'}
	Local aCamFil   := {'B1_COD','B1_DESC','B2_LOCAL','AA3_SLDDIS'}
	Local cRet      := ''   
	Local cFiltro   := "" 
	Local cSistema1 := ''  // aberto ou fechado

	If cCondicao = 'BIC'


		If aRetInc[2] = '1'
			cSistema1 := '1'
		Else
			cSistema1 := '2'  	
		Endif

		IF aRetInc[1] = '1' // BICO SINGLE
			cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("2")+"' AND SB1.B1_SINGLE = '1'  AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "+  "  AND SB1.B1_TPSISTE= " +  "'"+cSistema1+"'"   
		EndIf 

		IF aRetInc[1] = '2' // HRS
			cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("2")+"' AND SB1.B1_HRS = '1'  AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "+  "  AND SB1.B1_TPSISTE= " +  "'"+cSistema1+"'"   
		EndIf 

		IF aRetInc[1] = '3' // ECO
			cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("2")+"' AND SB1.B1_ECOMODU = '1'  AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "+  "  AND SB1.B1_TPSISTE= " +  "'"+cSistema1+"'"   
		EndIf 

		IF aRetInc[1] = '4' // HOT HALF HRS 
			cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("2")+"' AND SB1.B1_HOTHRS = '1'  AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "+  "  AND SB1.B1_TPSISTE= " +  "'"+cSistema1+"'"   
		EndIf 

		IF aRetInc[1] = '5' //  HOT HALF ECO MODU
			cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("2")+"' AND SB1.B1_HOTHREC = '1'  AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "+  "  AND SB1.B1_TPSISTE= " +  "'"+cSistema1+"'"   
		EndIf 



		// cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("2")+"' AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "

	EndIf        

	If cCondicao = 'CON'
		cFiltro := " AND SB1.B1_TPORCAM = '8' AND  SB1.B1_YUUSO = '" + U_YuFilBic() + "' "
	EndIf
	If cCondicao = 'CSE'
		cFiltro := " AND SB1.B1_TPORCAM = '5' "
	EndIf
	If cCondicao = 'CTE'
		cFiltro := " AND SB1.B1_TPORCAM = '4' "
	EndIf
	If cCondicao = 'ECO'
		cFiltro := " AND SB1.B1_TPORCAM = '" +U_YuFilTod("7") + "' "
	EndIf 
	If cCondicao = 'HOT'
		cFiltro := " AND SB1.B1_TPORCAM = '6' "
	EndIf                                  

	If cCondicao = 'MAN'
		//   cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("1")+"' AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "  //  - ALTERADO PARA BUSCA
		cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilTod("1")+"' AND  SB1.B1_YUUSO IN(1,2) "//  - ALTERADO PARA BUSCAR 1=BALA E 2=TINA 
	EndIf  

	If cCondicao = 'OUT'
		cFiltro := " AND SB1.B1_TPORCAM = '9' "
	EndIf                                  
	If cCondicao = 'SOL'
		cFiltro := " AND SB1.B1_TPORCAM = '"+U_YuFilSol()+"' AND  SB1.B1_YUUSO = '"+U_YuFilBic()+"' "
	EndIf  

	cFiltro := M->C6_PRODUTO

	//cRetFiltro := u_YudFilter(cTabela,aCamGrid,aCamFil,cFiltro)
	aRetFiltro := u_YudFilter(cTabela,aCamGrid,aCamFil,cFiltro)
	
	//if empty(cRetFiltro)
	//	cRetFiltro := cProduto
	//endif    
	If Len(aRetFiltro) == 0
		aAdd(aRetFiltro,cProduto)
	EndIf

return .T.

// ALTERNATIVOS
//-------------------------------------------------------------------
/*/                                                 
/*/                                                             
//-------------------------------------------------------------------
Static Function CVSAlter(cCondicao,cProduto)

	Local cTabela   := 'SB1'
	Local aCamGrid  := {'B1_COD','B1_DESC','B2_LOCAL','B2_QATU'}
	Local aCamFil   := {'B1_COD','B1_DESC','B2_LOCAL','B2_QATU'}
	Local cRet      := ''   
	Local cFiltro   := "" 
	Local cSistema1 := ''  // aberto ou fechado

	cFiltro := 'GI_PRODORI'

	cRetFiltro := u_YudFilter(cTabela,aCamGrid,aCamFil,cFiltro)
	if empty(cRetFiltro)
		cRetFiltro := cProduto
	endif    

return .T.


//-------------------------------------------------------------------
/*/{Protheus.doc} RetFilt
Função de retorno da consulta padrão.                                                    

Data 09/04/2014                                                   
/*/                                                             
//-------------------------------------------------------------------
User Function RetFilt()
	
	Local cRetFil := ""
	//ajuste filipe - Está retornando espacos e dando erro
	//cRetFiltro := AllTrim(cRetFiltro)
	If Len(aRetFiltro) > 0
		cRetFil := AllTrim(aRetFiltro[1])
	EndIf
	If Len(aRetFiltro) > 1
		GdFieldPut("C6_LOCAL",aRetFiltro[2],N) //cRetFil := AllTrim(aRetFiltro[2])
	EndIf
	
return cRetFil

/*/{Protheus.doc} YudFLoc
Funcao para gatilhar o armazem correto conforme selecionado na consulta especifica
Gatilho C6_PRODUTO para ele mesmo com essa funcao como condição.
@author TSCB57 - william.farias
@since 17/12/2019
@version 1.0
@example
(examples)
@see (links_or_references)
/*/
User Function YudFLoc()

	If Len(aRetFiltro) > 1
		GDFieldPut("C6_LOCAL",aRetFiltro[2],N)
	EndIf
	
Return .T.
