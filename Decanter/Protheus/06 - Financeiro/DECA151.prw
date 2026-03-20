#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} DECA151

Tela para definir qual o banco utilizado para emissão de boleto no dia.

@author TSCB57 - William Farias
@since 13/08/2019
@version 1.0
@return return, return_description
/*/
User Function DECA151()
	Local cQuery		:=	""
	Local aCposBrw		:=	{/*"EE_ZBCODIA",*/"EE_CODIGO","EE_OPER","EE_AGENCIA","EE_DVAGE","EE_CONTA","EE_DVCTA","EE_SUBCTA"}
	Local aColumns		:=	{}
	Private cAliasSql	:=	GetNextAlias()
	Private oBrowseComp	:=	nil
	Private oActLog		:=	ACTXLOG():New()

	cCamposNF	:=	""
	For Ni := 1 TO Len(aCposBrw)
		cCamposNF += aCposBrw[nI]

		If Ni < Len(aCposBrw)
			cCamposNF += ","
		EndIf
	Next

	cQuery := " SELECT CASE WHEN EE_ZBCODIA = 'S' THEN 'SIM' WHEN EE_ZBCODIA = 'N' OR EE_ZBCODIA = '' THEN 'NÃO' END EE_ZBCODIA, "
	cQuery += +cCamposNF+", EE_OK, R_E_C_N_O_ RECNO "
	cQuery += " FROM "+RetSqlName("SEE")+" SEE "
	cQuery += " WHERE D_E_L_E_T_ = '' "
	cQuery += " AND EE_FILIAL	= '"+FWXFilial("SEE")+"' "
	cQuery += " ORDER BY RECNO "

	CursorWait()

	oBrowseComp := FWMarkBrowse():New()
	oBrowseComp:SetDataQuery()
	oBrowseComp:SetQuery(cQuery)
	oBrowseComp:SetDescription("Banco do Dia")
	oBrowseComp:SetIgnoreARotina(.T.)	//Ignora aRotina
	oBrowseComp:SetMenuDef("")			//Limpa menu aRotina
	oBrowseComp:SetFieldMark( "EE_OK" )
	oBrowseComp:DisableFilter()
	oBrowseComp:bMark := {|| U_DECA151C()}
	oBrowseComp:AddButton("Marcar", {|| Processa({|lEnd| U_DECA151R(oBrowseComp,lEnd) },"Aguarde...","Marcando banco...",.T.) })
	oBrowseComp:AddButton("Sair", {||Self:End()})
	FWMsgRun(/*oComponent*/,{|| oBrowseComp:SetAlias(cAliasSql)  },,"Carregando Dados")
	
	oColumn	:=	FWBrwColumn():New()
	oColumn:SetData(&("{|| (cAliasSql)->EE_ZBCODIA }"))
	oColumn:SetType( 	GetSX3Cache("EE_ZBCODIA","X3_TIPO"))
	oColumn:SetTitle(	"Banco do Dia")
	oColumn:SetSize(3)
	oColumn:SetDecimal(	GetSX3Cache("EE_ZBCODIA","X3_DECIMAL"))
	oColumn:SetEdit(.F.)
	oColumn:SetPicture(GetSX3Cache("EE_ZBCODIA","X3_PICTURE"))
	oColumn:SETAUTOSIZE(.T.)
	aadd(aColumns,oColumn)
	
	For nI	:=	1 To Len(aCposBrw)
		dbSelectArea("SX3")
		dbSetOrder(2)
		If msSeek(aCposBrw[nI])
			oColumn	:=	FWBrwColumn():New()
			If GetSX3Cache(aCposBrw[nI],"X3_TIPO") == "D"
				oColumn:SetData(&("{||stod((cAliasSql)->"+aCposBrw[nI]+") }"))
			Else
				oColumn:SetData(&("{|| (cAliasSql)->"+aCposBrw[nI]+" }"))
			EndIf
			oColumn:SetType( 	GetSX3Cache(aCposBrw[nI],"X3_TIPO"))
			oColumn:SetTitle(	GetSX3Cache(aCposBrw[nI],"X3_TITULO"))
			oColumn:SetSize(	GetSX3Cache(aCposBrw[nI],"X3_TAMANHO"))
			oColumn:SetDecimal(	GetSX3Cache(aCposBrw[nI],"X3_DECIMAL"))
			oColumn:SetEdit(.F.)
			oColumn:SetPicture(GetSX3Cache(aCposBrw[nI],"X3_PICTURE"))
			oColumn:SETAUTOSIZE(.T.)
			aadd(aColumns,oColumn)
		EndIf
	Next

	oBrowseComp:SetColumns(aColumns)
	oBrowseComp:Activate()

Return

/*/{Protheus.doc} DECA151R

Regra para os registros selecionados.

@author TSCB57 - William Farias
@since 13/08/2019
@version 1.0
@return return, return_description
/*/
User Function DECA151R(oBrowse,lEnd)
	Local lRet		:=	.F.
	Local nTotalReg	:=	0
	LOcal nIncTotal	:=	0
	Local cAlias	:=	oBrowse:Alias()()
	
	oActLog:Start("DECA151"," Iniciando marcação de banco do dia",)

	Begin Sequence

		dbSelectArea(cAlias)
		Count to nTotalReg
		(cAlias)->(dbGoTop())
		ProcRegua(nTotalReg)

		CursorWait()

		nLastRec := nTotalReg
		oBrowse:GoTop(.T.)

		While .T.
			nAliasRec := oBrowse:At()
			ProcessMessage()
			nIncTotal++

			If nIncTotal > nLastRec
				Exit
			EndIf

			If !oBrowse:IsMark()
				
				dbSelectArea("SEE")
				dbGoTo((cAlias)->RECNO)
				RecLock("SEE", .F.)
				SEE->EE_ZBCODIA := "N"
				SEE->(MsUnlock())
				
				oBrowse:GoDown(1)
				Loop
			EndIf

			iF KillApp()
				Break
			EndIf

			If lEnd
				Break
			EndIf
			
			dbSelectArea("SEE")
			dbGoTo((cAlias)->RECNO)
			
			RecLock("SEE", .F.)
			SEE->EE_ZBCODIA := "S"
			SEE->(MsUnlock())

			oBrowse:GoDown(1)
			
		EndDo

		CursorArrow()

		lRet	:=	.T.
		
	End Sequence

	CursorWait()
	oBrowse:Refresh(.T.)
	CursorArrow()
	If lRet
		cMsg	:=	" marcado com sucesso."
		MsgInfo(cMsg,"Fim do Processo - "+ProcName())
	Else
		cMsg	:=	"Não foi possível marcar o banco do dia."
		MsgInfo(cMsg,"Fim do Processo - "+ProcName())
	EndIf
	FWMsgRun(/*oComponent*/,{|| oBrowseComp:SetAlias(cAliasSql)  },,"Carregando Dados")

Return

/*/{Protheus.doc} DECA151C
Permite apenas uma marcação no Browse.

@author TSCB57 - William Farias
@since 13/08/2019
@version 1.0
@return return, return_description
/*/
User Function DECA151C()
	
	Local aArea := GetArea()
	Local cAlias := oBrowseComp:Alias()()
	Local nCt := 0
	
	(cAlias)->( dbGoTop() )
	While !(cAlias)->( EOF() )
	    If oBrowseComp:IsMark()
	        nCt++
	    EndIf
	    (cAlias)->( dbSkip() )
	EndDo
	
	If nCt == 0
		(cAlias)->( dbGoTop() )
		While !(cAlias)->( EOF() )
			RecLock(cAlias,.f.)
			(cAlias)->EE_OK := " "
			(cAlias)->(MsUnlock())
		    (cAlias)->( dbSkip() )
		EndDo
		oBrowseComp:Refresh(.T.)
	ElseIf nCt > 1
		(cAlias)->( dbGoTop() )
		While !(cAlias)->( EOF() )
			RecLock(cAlias,.f.)
			(cAlias)->EE_OK := " "
			(cAlias)->(MsUnlock())
		    (cAlias)->( dbSkip() )
		EndDo
		MsgAlert("Apenas um registro deve ser selecionado.","Atenção - "+ProcName())
		oBrowseComp:Refresh(.T.)
	EndIf

	RestArea(aArea)

Return nil
