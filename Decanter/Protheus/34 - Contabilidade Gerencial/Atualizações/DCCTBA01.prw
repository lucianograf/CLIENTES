#Include 'totvs.ch'

/*/{Protheus.doc} DCCTBA01
Rotina para limpeza de Flag de contabilização 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/06/2021
@return return_type, return_description
/*/
User Function DCCTBA01()

	Local	_oDlg 
	Local	_oScrollBox
	Local	_nOpcFlag	:= 0
	Local	_lConfirm	:= .F.
	Local	_aOptions	:= {}
    Private cCadastro   := "Limpeza de Flag"
	Private	aRotina		:= {}
	Private	_cExpr		:= ""

    If !(RetCodUsr() $ GetNewPar("DC_CTBA01L","000000#000144#000032#000117#000006#000122")) // Admin / Marcelo / Fabiana / Flavia / Luciano  
        MsgAlert("Você não tem permissão para executar esta rotina!")
        Return 
    Endif 
	// Monta as opcoes Default
	aAdd(aRotina,{"Pesquisar", "AxPesqui",0,1})
	aAdd(aRotina,{"Visualizar",'AxVisual',0,2})

	// Monta lista das opcoes de acesso
	aAdd(_aOptions,OemToAnsi("Notas Fiscais de Entrada"))
	aAdd(_aOptions,OemToAnsi("Notas Fiscais de Saida"))
	aAdd(_aOptions,OemToAnsi("Titulos a Receber"))
	aAdd(_aOptions,OemToAnsi("Titulos a Pagar"))
	aAdd(_aOptions,OemToAnsi("Movimentação Bancária"))

	// Monta janela para selecao do filtro
	DEFINE MSDIALOG _oDlg TITLE OemToAnsi('Opções de Movimentação ( F5 para Filtrar / F6 para Executar )') From 04,00 To 16,80 OF oMainWnd
	DEFINE FONT _oFontWin  NAME 'Arial' BOLD
	_oScrollBox := TScrollBox():New(_oDlg,002,002,095,212,.t.,.f.,.f.)
	_oRadio:= tRadMenu():New(010,010,_aOptions,{|u|if(PCount()>0,_nOpcFlag:=u,_nOpcFlag)},_oScrollBox,,,,,,,,120,10,,,,.T.)
	DEFINE SBUTTON FROM 70, 075 TYPE 01 ENABLE OF _oDlg Action (_lConfirm := .T. , _oDlg:End())
	DEFINE SBUTTON FROM 70, 108 TYPE 02 ENABLE OF _oDlg Action (_lConfirm := .F. , _oDlg:End())
	ACTIVATE MSDIALOG _oDlg CENTERED

	If	! _lConfirm
		Return
	EndIf

	mv_par01 := FirstDay(FirstDay(dDataBase)-1)
	mv_par02 := Space(9)
	mv_par03 := Space(3)
	mv_par04 := Space(9)
	mv_par05 := Space(3)

	Do Case
	Case _nOpcFlag == 1 // Entradas de Notas Fiscais
		DBSelectArea("SF1")
        cCadastro   := "Notas Fiscais de Entrada"
		SetKey(116, {|| xGC0001Filt("SF1") })
		SetKey(117, {|| xGC0001Flag("SF1") })
		mBrowse(6,1,22,75,"SF1",,"F1_DTLANC<>CTOD('  /  /  ')",20)
		SetMbTopFilter("SF1",_cExpr,.F.,.T.)
		SF1->(DbGoTop())
	Case _nOpcFlag == 2 // Notas Fiscais de saida
		DBSelectArea("SF2")
        cCadastro   := "Notas Fiscais de Saída"
		SetKey(116, {|| xGC0001Filt("SF2") })
		SetKey(117, {|| xGC0001Flag("SF2") })
		mBrowse(6,1,22,75,"SF2",,"F2_DTLANC<>CTOD('  /  /  ')",20)
		SetMbTopFilter("SF2",_cExpr,.F.,.T.)
		SF2->(DbGoTop())
	Case _nOpcFlag == 3 // Titulos a Receber
		DBSelectArea("SE1")
        cCadastro   := "Títulos a Receber"
		SetKey(116, {|| xGC0001Filt("SE1") })
		SetKey(117, {|| xGC0001Flag("SE1") })
		mBrowse(6,1,22,75,"SE1",,"E1_LA",20)
		SetMbTopFilter("SE1",_cExpr,.F.,.T.)
		SE1->(DbGoTop())
	Case _nOpcFlag == 4 // Titulos a Pagar
		DBSelectArea("SE2")
        cCadastro   := "Títulos a Pagar"
		SetKey(116, {|| xGC0001Filt("SE2") })
		SetKey(117, {|| xGC0001Flag("SE2") })
		mBrowse(6,1,22,75,"SE2",,"E2_LA",20)
		SetMbTopFilter("SE2",_cExpr,.F.,.T.)
		SE2->(DbGoTop())
	Case _nOpcFlag == 5 // Movimentacao Bancaria
		DBSelectArea("SE5")
        cCadastro   := "Movimentação Bancária"
		SetKey(116, {|| xGC0001Filt("SE5") })
		SetKey(117, {|| xGC0001Flag("SE5") })
		mBrowse(6,1,22,75,"SE5",,"E5_LA",20)
		SetMbTopFilter("SE5",_cExpr,.F.,.T.)
		SE5->(DbGoTop())
	End Case

	SetKey(116,Nil)
	SetKey(117,Nil)

Return

// Função para altera filtro do MBrowse
Static Function xGC0001Filt(_cAlias)

	Local	_aParam	:= {}
	Local	_aRet	:= {}

	_cExpr := ""

	If	_cAlias $ "SF1|SF2"
		aAdd(_aParam,{1,"Dt. Inicial",mv_par01,"@D","","","",60,.T.})
		aAdd(_aParam,{1,"Forn./Cli.",mv_par02,"@!","","","",60,.f.})
	ElseIf	_cAlias $ "SE1|SE2|SE5"
		If	_cAlias $ "SE1|SE2"
			aAdd(_aParam,{1,"Emissao",mv_par01,"@D","","","",60,.T.})
		Else
			aAdd(_aParam,{1,"Data",mv_par01,"@D","","","",60,.T.})
		EndIf
		aAdd(_aParam,{1,"Forn./Cli.",mv_par02,"@!","","","",60,.f.})
		aAdd(_aParam,{1,"Prefixo",mv_par03,"@!","","","",60,.f.})
		aAdd(_aParam,{1,"Numero",mv_par04,"@!","","","",60,.f.})
		aAdd(_aParam,{1,"Tipo",mv_par05,"@!","","","",60,.f.})
	EndIf

	If	Len(_aParam) > 0
		If	! ParamBox(_aParam,"Filtro de Registros",@_aRet)
			SetMbTopFilter(_cAlias,_cExpr,.F.,.T.)
			Return
		Else
			If	_cAlias = "SF1"
				_cExpr += " F1_DTDIGIT >= '" + DtoS(mv_par01) + "' "
				_cExpr += IIf(!Empty(mv_par02)," AND F1_FORNECE = '" + mv_par02 + "' ","")
			ElseIf	_cAlias = "SF2"
				_cExpr += " F2_EMISSAO >= '" + DtoS(mv_par01) + "' "
				_cExpr += IIf(!Empty(mv_par02)," AND F2_CLIENTE = '" + mv_par02 + "' ","")
			ElseIf	_cAlias = "SE1"
				_cExpr += " E1_EMISSAO >= '" + DtoS(mv_par01) + "' "
				_cExpr += IIf(!Empty(mv_par02)," AND E1_CLIENTE = '" + mv_par02 + "' ","")
				_cExpr += IIf(!Empty(mv_par03)," AND E1_PREFIXO = '" + mv_par03 + "' ","")
				_cExpr += IIf(!Empty(mv_par04)," AND E1_NUM = '" + mv_par04 + "' "    ,"")
				_cExpr += IIf(!Empty(mv_par05)," AND E1_TIPO = '" + mv_par05 + "' "   ,"")
			ElseIf	_cAlias = "SE2"
				_cExpr += " E2_EMISSAO >= '" + DtoS(mv_par01) + "' "
				_cExpr += IIf(!Empty(mv_par02)," AND E2_FORNECE = '" + mv_par02 + "' ","")
				_cExpr += IIf(!Empty(mv_par03)," AND E2_PREFIXO = '" + mv_par03 + "' ","")
				_cExpr += IIf(!Empty(mv_par04)," AND E2_NUM = '" + mv_par04 + "' "    ,"")
				_cExpr += IIf(!Empty(mv_par05)," AND E2_TIPO = '" + mv_par05 + "' "   ,"")
			ElseIf	_cAlias = "SE5"
				_cExpr += " E5_DATA >= '" + DtoS(mv_par01) + "' "
				_cExpr += IIf(!Empty(mv_par02)," AND E5_CLIFOR = '" + mv_par02 + "' " ,"")
				_cExpr += IIf(!Empty(mv_par03)," AND E5_PREFIXO = '" + mv_par03 + "' ","")
				_cExpr += IIf(!Empty(mv_par04)," AND E5_NUMERO = '" + mv_par04 + "' " ,"")
				_cExpr += IIf(!Empty(mv_par05)," AND E5_TIPO = '" + mv_par05 + "' "   ,"")
			EndIf
		EndIf
		SetMbTopFilter(_cAlias,_cExpr,.T.,.F.)
	EndIf

Return

// Altera registro limpando a flag
Static Function xGC0001Flag(_cAlias)
	Local	_bCpoField := ""
	Local	_nNumRec   := Recno()

	// Verifica o nome do campo
	If	_cAlias = "SF1"
		_bCpoField := "F1_DTLANC"
	ElseIf	_cAlias = "SF2"
		_bCpoField := "F2_DTLANC"
	ElseIf	_cAlias = "SE1"
		_bCpoField := "E1_LA"
	ElseIf	_cAlias = "SE2"
		_bCpoField := "E2_LA"
	ElseIf	_cAlias = "SE5"
		_bCpoField := "E5_LA"
	ElseIf	_cAlias = "SEI"
		_bCpoField := "EI_LA"
	EndIf

	// Verifica se o registro está desmarcado.
	If	! Empty(_cAlias) .and. ! Empty(_bCpoField)
		If	! Empty( &(_cAlias+"->"+_bCpoField) )
			If	MsgYesNo(OemToAnsi("Deseja realmente desmarcar o FLAG de contabilização deste registro ? Antes de desmarcar o FLAG tenha certeza de que o registro não esteja contabilizado evitando geração de informações contábeis duplicadas."))
				// Desmarca o FLAG de contabilizacao
				If	RecLock(_cAlias,.F.)
					&(_cAlias+"->"+_bCpoField) := Iif("LANC"$_bCpoField,Ctod("  /  /  ")," ")
					(_cAlias)->(MsUnLock())
					MsgInfo("Registro desmarcado com Sucesso.")
				EndIf
				// Reposiciona o registro.
				DbSelectArea(_cAlias)
				SetMbTopFilter(_cAlias,_cExpr,.T.,.F.)
				(_cAlias)->(DbGoTop())
				DbGoTo(_nNumRec)
			EndIf
		Else
			MsgAlert(OemToAnsi("Este registro não está contabilizado, favor contabiliza-lo."))
		EndIf
	EndIf

Return

