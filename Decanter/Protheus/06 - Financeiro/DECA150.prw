#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} DECA150

Tela para transferir vários títulos da situação 1 (Simples) para 2 (Descontada).

@author TSCB57 - William Farias
@since 13/08/2019
@version 1.0
@return return, return_description
/*/
User Function DECA150()
	Local cQuery		:=	""
	Local aCposBrw		:=	{"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO","E1_NATUREZ","E1_NUMBOR","E1_PORTADO","E1_AGEDEP","E1_CONTA","E1_NUMBCO","E1_CLIENTE","E1_LOJA","E1_NOMCLI","E1_EMISSAO","E1_VENCREA","E1_VALOR","E1_SALDO"}
	Local aCposIndx		:=	{"E1_VALOR","E1_EMISSAO","E1_VENCREA"}
	Local aColumns		:=	{}
	Local aFiltro		:=	{}
	Local aParamBox		:=	{}
	Local aRet			:=	{}
	Local bOk 			:=	{|| .T.}
	Local aButtons 		:=	{}
	Local lCentered 	:=	.T.
	Local nPosx
	Local nPosy
	Local cLoad 		:=	ProcName()
	Local lCanSave 		:=	.T.
	Local lUserSave		:=	.T.
	Local aCoors 		:= FWGetDialogSize(oMainWnd)
	Local oFont			:= TFont():New('Arial',,-12,.T.,.T.)
	Local oFont2		:= TFont():New('Arial',,-12,.T.,.F.)
	Local aSeek			:= {}
	Local aSeelAux    :=  {}
	Private nTotTit		:= 0
	Private cAliasSql	:=	GetNextAlias()
	Private oBrowseComp	:=	nil
	Private oActLog		:=	ACTXLOG():New()
	Private nTaxaDesc	:=	0
	Private nTaxaIof	:=	0
	Private nValJur		:= 0
	Private nValIof		:= 0
	Private nValTAC		:= 0
	Private cBco		:= ""
	Private cAgenc		:= ""
	Private cCont		:= ""
	
	aAdd(aParamBox,{1,"Banco"			,Space(3)	, GetSx3Cache("A6_COD"		,"X3_PICTURE"),"","SA6"	,"",20,.T.})
	aAdd(aParamBox,{1,"Agência"			,Space(5)	, GetSx3Cache("A6_AGENCIA"	,"X3_PICTURE"),"",""	,"",20,.T.})
	aAdd(aParamBox,{1,"Conta"			,Space(10)	, GetSx3Cache("A6_NUMCON"	,"X3_PICTURE"),"",""	,"",40,.T.})
	//aAdd(aParamBox,{1,"Taxa Desc."	,0			, GetSx3Cache("A6_TAXADES"	,"X3_PICTURE"),"",""	,"",20,.T.})
	//aAdd(aParamBox,{1,"Taxa IOF"		,0			, GetSx3Cache("ED_PERCIOF"	,"X3_PICTURE"),"",""	,"",20,.T.})
	aAdd(aParamBox,{1,"Valor Juros"		,0			, GetSx3Cache("E5_VALOR"	,"X3_PICTURE"),"",""	,"",60,.T.})
	aAdd(aParamBox,{1,"Valor IOF"		,0			, GetSx3Cache("E5_VALOR"	,"X3_PICTURE"),"",""	,"",60,.F.})
	aAdd(aParamBox,{1,"Valor TAC"		,0			, GetSx3Cache("E5_VALOR"	,"X3_PICTURE"),"",""	,"",60,.F.})
	aAdd(aParamBox,{1,"Cliente De"		,Space(10)	, GetSx3Cache("E1_CLIENTE"	,"X3_PICTURE"),"",""	,"",40,.F.})
	aAdd(aParamBox,{1,"Cliente Até"		,Space(10)	, GetSx3Cache("E1_CLIENTE"	,"X3_PICTURE"),"",""	,"",40,.F.})
	aAdd(aParamBox,{1,"Loja De"			,Space(4)	, GetSx3Cache("E1_LOJA"		,"X3_PICTURE"),"",""	,"",20,.F.})
	aAdd(aParamBox,{1,"Loja Até"		,Space(4)	, GetSx3Cache("E1_LOJA"		,"X3_PICTURE"),"",""	,"",20,.F.})
	aAdd(aParamBox,{1,"Dt Emissão De"	,STOD("")	, GetSx3Cache("E1_EMISSAO"	,"X3_PICTURE"),"",""	,"",50,.F.})
	aAdd(aParamBox,{1,"Dt Emissão Até"	,STOD("")	, GetSx3Cache("E1_EMISSAO"	,"X3_PICTURE"),"",""	,"",50,.F.})
	aAdd(aParamBox,{1,"Dt Venc. De"		,STOD("")	, GetSx3Cache("E1_VENCREA"	,"X3_PICTURE"),"",""	,"",50,.F.})
	aAdd(aParamBox,{1,"Dt Venc. Até"	,STOD("")	, GetSx3Cache("E1_VENCREA"	,"X3_PICTURE"),"",""	,"",50,.F.})
	If !ParamBox(aParamBox,"Transferência",@aRet,bOk,aButtons,lCentered,nPosx,nPosy,/*oDlgWizard*/,cLoad,lCanSave,lUserSave)
		Return
	EndIf

	cBco		:= aRet[1]
	cAgenc		:= aRet[2]
	cCont		:= aRet[3]
	nTaxaDesc	:= 0 
	nTaxaIof	:= 0 
	nValJur		:= aRet[4]
	nValIof		:= aRet[5]
	nValTAC		:= aRet[6]

	cCamposNF	:=	""
	For Ni := 1 TO Len(aCposBrw)
		cCamposNF += aCposBrw[nI]

		If Ni < Len(aCposBrw)
			cCamposNF += ","
		EndIf
	Next

	cQuery := " SELECT "+cCamposNF+", E1_OK, R_E_C_N_O_ RECNO "
	cQuery += " FROM "+RetSqlName("SE1")+" SE1 "
	cQuery += " WHERE D_E_L_E_T_ = '' "
	cQuery += " AND E1_FILIAL	=	'"+FWXFilial("SE1")+"' "
	cQuery += " AND E1_PORTADO	=	'"+cBco+"' "
	cQuery += " AND E1_AGEDEP	=	'"+cAgenc+"' "
	cQuery += " AND E1_CONTA	=	'"+cCont+"' "
	cQuery += " AND E1_NUMBOR	<>	'' "			//Em borderô
	cQuery += " AND E1_SITUACA	=	'1' "			//Somente na situação 1
	cQuery += " AND E1_SALDO	>	0 "				//Somente títulos com saldo
	cQuery += " AND E1_CLIENTE	>=	'"+aRet[7]+"' "
	cQuery += " AND E1_CLIENTE	<=	'"+aRet[8]+"' "
	cQuery += " AND E1_LOJA		>=	'"+aRet[9]+"' "
	cQuery += " AND E1_LOJA		<=	'"+aRet[10]+"' "
	If !Empty(AllTrim(DTOS(aRet[11]))) .And. !Empty(AllTrim(DTOS(aRet[12])))
		cQuery += " AND E1_EMISSAO BETWEEN '" + DTOS(aRet[11]) + "' AND '" + DTOS(aRet[12]) + "' "
	EndIf
	If !Empty(AllTrim(DTOS(aRet[13]))) .And. !Empty(AllTrim(DTOS(aRet[14])))
		cQuery += " AND E1_VENCREA BETWEEN '" + DTOS(aRet[13]) + "' AND '" + DTOS(aRet[14]) + "' "
	EndIf
	cQuery += " ORDER BY E1_VALOR, E1_EMISSAO, E1_VENCREA "

	CursorWait()

	DEFINE MSDIALOG oDlgPrinc Title "Transf. Títulos em Lote - DECA150" From 0, 0 To aCoors[3]+2, aCoors[4]+4 Pixel//aCoors[1], aCoors[2] To aCoors[3]-2, aCoors[4]-2 Pixel

	aIndex := {}
	For nX := 1 To Len( aCposIndx )
		aAdd(aIndex, aCposIndx[nX] )
	Next nX
	
	aAdd(aSeek,{"Vlr. Titulo"		,{"E1_VALOR"	,"N",TAMSX3("E1_VALOR")[1]		,2,"E1_VALOR" 	,"@E 9,999,999,999,999.99"	,"E1_VALOR"		}})
	aAdd(aSeek,{"DT Emissao"		,{"E1_EMISSAO"	,"D",TAMSX3("E1_EMISSAO")[1]	,0,"E1_EMISSAO" ,""							,"E1_EMISSAO"	}})
	aAdd(aSeek,{"Vencto Real"		,{"E1_VENCREA"	,"D",TAMSX3("E1_VENCREA")[1]	,0,"E1_VENCREA" ,""							,"E1_VENCREA"	}})
	//Aadd(aSeek,{'Vlr. Titulo'		,{"E1_VALOR"	,"N",TAMSX3("E1_VALOR")[1]		,2,"E1_VALOR"	,"@E 9,999,999,999,999.99"}, 1, .T. } )
	
//	aadd(aSeelAux,{"E1_VALOR"	,"N"	,TAMSX3("E1_VALOR")[1]	,	2	,"E1_VALOR"		,"@E 9,999,999,999,999.99"})
//	Aadd(aSeek,{'VlrTitulo',aSeelAux, 1, .T. } )
//	aadd(aSeelAux,{"E1_EMISSAO"	,"D"	,TAMSX3("E1_EMISSAO")[1],	0	,"E1_EMISSAO"	,""})
//	Aadd(aSeek,{'Emissao',aSeelAux, 2, .T. } )
//	aadd(aSeelAux,{"E1_VENCREA"	,"D"	,TAMSX3("E1_VENCREA")[1],	0	,"E1_VENCREA"	,""})
//	Aadd(aSeek,{'Vencimento',aSeelAux, 3, .T. } )
//	aadd(aSeelAux,{"E1_NUM"		,"C"	,TAMSX3("E1_NUM")[1]	,	0	,"E1_NUM"		,"@!"})
//	Aadd(aSeek,{'NoTitulo',aSeelAux, 4, .T. } )

	oFWLayer := FWLayer():New()
	oFWLayer:Init(oDlgPrinc, .T., .T.)
	oFWLayer:AddLine('UP', 93, .T.)					// Cria uma "linha" com 93% da tela
	oFWLayer:AddCollumn('ALL', 99, .T., 'UP')		// Na "linha" criada eu crio uma coluna com 99% da tamanho dela
	oPanelUp := oFWLayer:GetColPanel('ALL', 'UP')	// Pego o objeto desse pedaÁo do container

	oBrowseComp := FWMarkBrowse():New()
	oBrowseComp:SetOwner(oPanelUp)
	oBrowseComp:SetDataQuery(.T.)
	oBrowseComp:SetQuery(cQuery)
	oBrowseComp:SetTemporary(.T.)
	oBrowseComp:oBrowse:SetQueryIndex(aIndex)
	oBrowseComp:SetAlias(cAliasSql)		//Seta alias para Filtro
	oBrowseComp:SetDescription("Transf. em Lote de Situação de Títulos")
	oBrowseComp:SetIgnoreARotina(.T.)			//Ignora aRotina
	oBrowseComp:SetMenuDef("")					//Limpa menu aRotina
	oBrowseComp:SetFieldMark("E1_OK")			//Seta campo de marca
	oBrowseComp:oBrowse:SetSeek(,aSeek)
	oBrowseComp:oBrowse:SetUseFilter(.T.)		//Seta uso do filtro
	oBrowseComp:oBrowse:SetDBFFilter()			//Seta uso do filtro
	oBrowseComp:oBrowse:SetFieldFilter(aFiltro)	//Seta array de campos do filtro
	oBrowseComp:bMark := {|| U_DECA150C()}
	oBrowseComp:IsInvert(.T.)
	oBrowseComp:bAllMark := { || oBrowseComp:AllMark(),U_DECA150C(), oBrowseComp:Refresh(.T.)}
	oBrowseComp:AddButton("Transferir", {|| Processa({|lEnd| U_DECA150R(oBrowseComp,lEnd) },"Aguarde...","Efetuando transferências...",.T.) })
	oBrowseComp:AddButton("Sair", {||Self:End()})
	//FWMsgRun(/*oComponent*/,{|| oBrowseComp:SetAlias(cAliasSql)  },,"Carregando Dados")

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
			oColumn:SetType(GetSX3Cache(aCposBrw[nI],"X3_TIPO"))
			oColumn:SetTitle(GetSX3Cache(aCposBrw[nI],"X3_TITULO"))
			oColumn:SetSize(GetSX3Cache(aCposBrw[nI],"X3_TAMANHO"))
			oColumn:SetDecimal(GetSX3Cache(aCposBrw[nI],"X3_DECIMAL"))
			oColumn:SetEdit(.F.)
			oColumn:SetPicture(GetSX3Cache(aCposBrw[nI],"X3_PICTURE"))
			oColumn:SETAUTOSIZE(.T.)
			aadd(aColumns,oColumn)
			aadd(aFiltro,{aCposBrw[nI];
						,RTrim(GetSx3Cache(aCposBrw[nI],"X3_TITULO"));
						,GetSx3Cache(aCposBrw[nI],"X3_TIPO");
						,GetSx3Cache(aCposBrw[nI],"X3_TAMANHO");
						,GetSx3Cache(aCposBrw[nI],"X3_DECIMAL");
						,GetSx3Cache(aCposBrw[nI],"X3_PICTURE")})
		EndIf
	Next
	
	oBrowseComp:SetColumns(aColumns)
	oBrowseComp:Activate()

	oFWLayer:AddLine('DOWN', 7, .T.)					// Cria uma "linha" com 7% da tela
	oFWLayer:AddCollumn('ALL', 99, .T., 'DOWN')			// Na "linha" criada eu crio uma coluna com 99% da tamanho dela
	oPanelDown := oFWLayer:GetColPanel('ALL', 'DOWN')	// Pego o objeto desse pedaÁo do container
	
	oSay1 := TSay():New(05, 5,{|| "Total dos Títulos:"},oPanelDown,,oFont,,,,.T.,,,500,30,,,,,,.T.)
	oSay2 := TSay():New(05,55,{|| Transform(nTotTit,GetSX3Cache("C6_VALOR","X3_PICTURE"))},oPanelDown,,oFont2,,,,.T.,,,500,30,,,,,,.T.)
	
	ACTIVATE MSDIALOG oDlgPrinc CENTERED

Return

/*/{Protheus.doc} DECA150R

Regra para os registros selecionados

@author TSCB57 - William Farias
@since 13/08/2019
@version 1.0
@return return, return_description
/*/
User Function DECA150R(oBrowse,lEnd)
	LOcal cTimeFIm	:=	nil
	Local nTotalReg	:=	0
	LOcal nIncTotal	:=	0
	Local cTimeIni	:=	TIme()
	Local cAlias	:=	oBrowse:Alias()()
	Local lRetTran	:=	.T.
	Local nErros	:=	0
	Local lRetMovBan := .F.
	Local nMovBan	:= 0
	
	oActLog:Start("DECA150"," Iniciando transferência de títulos",)

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
				oBrowse:GoDown(1)
				Loop
			EndIf

			iF KillApp()
				Break
			EndIf

			If lEnd
				Break
			EndIf

			//Executa transferência para situação: 2
			BEGIN TRANSACTION
				
					lRetTransf := U_DECA150T(cAlias,nAliasRec,"2")
					
					If !lRetTransf
						DisarmTransaction()
						lRetTran := .F.
						Break
					EndIf
					
			END TRANSACTION

			If !lRetTran
				nErros++
				oBrowse:GoDown(1)
				Loop
			EndIf

			oBrowse:MarkRec()
			oBrowse:GoDown(1)
			
		EndDo

		CursorArrow()

		If nErros == 0
			//Executa movimento bancario do valor de juros.
			If nValJur > 0
				lRetMovBan := U_DECA150M(1,nValJur)
			EndIf
			If lRetMovBan
				nMovBan++
			EndIf
			//Executa movimento bancario do valor de IOF.
			If nValIof > 0
				lRetMovBan := U_DECA150M(2,nValIof)
			EndIf
			If lRetMovBan
				nMovBan++
			EndIf

			//Executa movimento bancario do valor de TAC.
			If nValTAC > 0
				lRetMovBan := U_DECA150M(3,nValTAC)
			EndIf
			If lRetMovBan
				nMovBan++
			EndIf

			If nMovBan == 0
				nErros++
			EndIf
		EndIf

	End Sequence

	CursorWait()
	oBrowse:Refresh(.T.)
	CursorArrow()
	cTimeFIm	:=	Time()
	If nErros == 0
		cMsg	:=	"Tempo total:"+elaptime(cTimeIni,cTimeFIm)+chr(13)+chr(10)
		cMsg	+=	chr(13)+chr(10)
		cMsg	+=	"Transferência finalizada com Sucesso!"+chr(13)+chr(10)
		cMsg	+=	chr(13)+chr(10)
		cMsg	+=	cValToChar(nMovBan)+" movimento(s) bancário(s) gerado(s)."+chr(13)+chr(10)
		MsgInfo(cMsg,"Fim do Processo - "+ProcName())
	Else
		cMsg	:=	"Tempo Total:"+elaptime(cTimeIni,cTimeFIm)+chr(13)+chr(10)
		cMsg	+=	chr(13)+chr(10)
		cMsg	+=	"Transferência finalizada com Erros"+chr(13)+chr(10)
		cMsg	+=	chr(13)+chr(10)
		cMsg	+=	"Nenhum movimento bancário gerado."+chr(13)+chr(10)
		MsgInfo(cMsg,"Fim do Processo - "+ProcName())
	EndIf
	FWMsgRun(/*oComponent*/,{|| oBrowseComp:SetAlias(cAliasSql)  },,"Carregando Dados")

Return

/*/{Protheus.doc} DECA150T

Executa a transferência dos registros selecionados

@author TSCB57 - William Farias
@since 14/08/2019
@version 1.0
@return return, return_description
/*/

User function DECA150T(cAlias,nAliasRec,cSituaca)
	
	Local lRet := .T.
	Local aTit :={}
	Local cPrefixo	:= ""
	Local cNumero	:= ""
	Local cParcela	:= ""
	Local cTipo		:= ""
	Local cBancoAnt	:= ""
	Local cAgencAnt	:= ""
	Local cContaAnt	:= ""
	Local cNrBcoAnt	:= ""
	Local dDataMov
	Local nValor	:= 0
	Local nVlrDesc 	:= 0
	Local nVlrIOF	:= 0
	Local nValCred	:= 0

	//-- Variáveis utilizadas para o controle de erro da rotina automática
	Local aErroAuto	:={}
	Local cErroRet	:=""
	Local nCntErr	:=0
	Private lMsErroAuto		:= .F.
	Private lMsHelpAuto		:= .T.
	Private lAutoErrNoFile	:= .T.
	
	//Posiciona o alias
	dbSelectArea(cAlias)
	dbGoTo(nAliasRec)
	
	//Atualiza os dados das variáveis
	cPrefixo	:= (cAlias)->E1_PREFIXO
	cNumero		:= (cAlias)->E1_NUM
	cParcela	:= (cAlias)->E1_PARCELA
	cTipo		:= (cAlias)->E1_TIPO
	cBancoAnt	:= (cAlias)->E1_PORTADO
	cAgencAnt	:= (cAlias)->E1_AGEDEP
	cContaAnt	:= (cAlias)->E1_CONTA
	cNrBcoAnt	:= (cAlias)->E1_NUMBCO
	dDataMov	:= dDataBase

	//Para retornar o título para carteira é necessário informar o banco em "branco"
	If cSituaca = "0"
		cBanco		:= ""
		cAgencia	:= ""
		cConta		:= ""
		cNumBco		:= ""
	ElseIf cSituaca = "2"
		cBanco		:= cBancoAnt
		cAgencia	:= cAgencAnt
		cConta		:= cContaAnt
		cNumBco		:= cNrBcoAnt
		nValor		:= (cAlias)->E1_SALDO
		If nTaxaIOF > 0 .And. nTaxaDesc > 0
			nVlrDesc := (nValor * (nTaxaDesc/100))
			nValCred := (nValor - nVlrDesc)
			nVlrIOF	 := (nValCred * (nTaxaIOF/100))
			nValCred -= nVlrIOF
		ElseIf nTaxaIOF > 0
			nVlrIOF := (nValor * (nTaxaIOF/100))
			nValCred := (nValor - nVlrIOF)
		ElseIf nTaxaDesc > 0			
			nVlrDesc := ((If(nVlrIOF > 0, (nValor-nVlrIOF), nValor) * nTaxaDesc)/100) 
			nValCred := (If(nVlrIOF > 0, (nValor-nVlrIOF), nValor) - nVlrDesc)
		Else
			nValCred := nValor
		EndIf
	EndIf
	
	//Chave do título
	aAdd(aTit, {"E1_PREFIXO", PadR(cPrefixo	, TamSX3("E1_PREFIXO")[1])	,Nil})
	aAdd(aTit, {"E1_NUM"	, PadR(cNumero	, TamSX3("E1_NUM")[1])		,Nil})
	aAdd(aTit, {"E1_PARCELA", PadR(cParcela	, TamSX3("E1_PARCELA")[1])	,Nil})
	aAdd(aTit, {"E1_TIPO"	, PadR(cTipo	, TamSX3("E1_TIPO")[1])		,Nil})
	
	//Informações bancárias
	aAdd(aTit, {"AUTDATAMOV", dDataMov 									,Nil})
	aAdd(aTit, {"AUTBANCO"	, PadR(cBanco	,TamSX3("A6_COD")[1])		,Nil})
	aAdd(aTit, {"AUTAGENCIA", PadR(cAgencia	,TamSX3("A6_AGENCIA")[1])	,Nil})
	aAdd(aTit, {"AUTCONTA"	, PadR(cConta	,TamSX3("A6_NUMCON")[1])	,Nil})
	aAdd(aTit, {"AUTSITUACA", PadR(cSituaca	,TamSX3("E1_SITUACA")[1])	,Nil})
	aAdd(aTit, {"AUTNUMBCO"	, PadR(cNumBco	,TamSX3("E1_NUMBCO")[1])	,Nil})
	
	//Carteira descontada deve ser encaminhado o valor de crédito, desconto e IOF já calculados
	If cSituaca = "2"
		aAdd(aTit, {"AUTDESCONT", nVlrDesc	,Nil})
		aAdd(aTit, {"AUTCREDIT"	, nValCred	,Nil})
		aAdd(aTit, {"AUTIOF"	, nVlrIOF	,Nil})
	EndIf
	
	//Posiciona a SE1 no registro para execauto da FINA060.
	dbSelectArea("SE1")
	SE1->(dbGoTo((cAlias)->RECNO))

	MSExecAuto({|a, b| FINA060(a, b)}, 2,aTit)
	
	If lMsErroAuto
		lRet := .F.
		aErroAuto := GetAutoGRLog()
		For nCntErr := 1 To Len(aErroAuto)
			cErroRet += aErroAuto[nCntErr]
		Next
		oActLog:Err(cErroRet)
		MsgStop("Não foi possível efetuar a transferência do título: "+(cAlias)->E1_NUM+chr(13)+chr(10)+cErroRet, "Atenção - "+ProcName()+"/"+cValToChar(ProcLine()))
	EndIf	
	
Return lRet

/*/{Protheus.doc} DECA150M

Executa a movimentacao bancaria

@author TSCB57 - William Farias
@since 24/01/2020
@version 1.0
@return return, return_description
/*/
User function DECA150M(nTipoVal,nValor)
	
	Local lRet		:= .T.
	Local aFINA100	:= {}
	Local cNat		:= ""
	Local cDoc		:= ""
	Local cHist		:= ""
	Local cCContab	:= ""
	Local cCCusto	:= ""
	Local aErroAuto	:= {}
	Local cErroRet	:= ""
	Local nCntErr	:= 0
	Default	nOpc	:= 0
	Default nValor	:= 0
	Private lMsErroAuto 	:= .F.
	Private lMsHelpAuto		:= .T.
	Private lAutoErrNoFile	:= .T.
	
	//Valor Juros
	If nTipoVal == 1
		cNat		:= SuperGetMv("MV_ZJURNAT",,"")
		cDoc		:= SuperGetMv("MV_ZJURDOC",,"")
		cHist		:= SuperGetMv("MV_ZJURHIS",,"")
		cCContab	:= SuperGetMv("MV_ZJURCON",,"")
		cCCusto		:= SuperGetMv("MV_ZJURCC",,"")
	//Valor IOF
	ElseIf nTipoVal == 2
		cNat		:= SuperGetMv("MV_ZIOFNAT",,"")
		cDoc		:= SuperGetMv("MV_ZIOFDOC",,"")
		cHist		:= SuperGetMv("MV_ZIOFHIS",,"")
		cCContab	:= SuperGetMv("MV_ZIOFCON",,"")
		cCCusto		:= SuperGetMv("MV_ZIOFCC",,"")
	//Valor TAC
	ElseIf nTipoVal == 3
		cNat		:= SuperGetMv("MV_ZTACNAT",,"")
		cDoc		:= SuperGetMv("MV_ZTACDOC",,"")
		cHist		:= SuperGetMv("MV_ZTACHIS",,"")
		cCContab	:= SuperGetMv("MV_ZTACCON",,"")
		cCCusto		:= SuperGetMv("MV_ZTACCC",,"")
	EndIf
	
	aFINA100 := {{"E5_DATA"		,dDataBase	,Nil},;
				{"E5_MOEDA"		,"M1"		,Nil},;
				{"E5_VALOR"		,nValor		,Nil},;
				{"E5_NATUREZ"	,cNat		,Nil},;
				{"E5_BANCO"		,cBco		,Nil},;
				{"E5_AGENCIA"	,cAgenc		,Nil},;
				{"E5_CONTA"		,cCont		,Nil},;
				{"E5_DOCUMEN"	,cDoc		,Nil},;
				{"E5_HISTOR"	,cHist		,Nil},;
				{"E5_DEBITO"	,cCContab	,Nil},;
				{"E5_CCD"		,cCCusto	,Nil}}
	
	MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,3) //3 = Inclusao
	
	If lMsErroAuto
		lRet := .F.
		aErroAuto := GetAutoGRLog()
		For nCntErr := 1 To Len(aErroAuto)
			cErroRet += aErroAuto[nCntErr]
		Next
		oActLog:Err(cErroRet)
		MsgStop("Não foi possível incluir o movimento bancário!"+chr(13)+chr(10)+cErroRet, "Atenção - "+ProcName()+"/"+cValToChar(ProcLine()))
	EndIf 
	
Return lRet

/*/{Protheus.doc} DECA150C
Ajusta totalizador do rodapé

@author TSCB57 - William Farias
@since 13/08/2019
@version 1.0
@return return, return_description
/*/
User Function DECA150C()
	
	Local aArea := GetArea()
	Local cAlias := oBrowseComp:Alias()()
	
	nTotTit := 0
	
	(cAlias)->(dbGoTop())
	While !(cAlias)->( EOF() )
	    If oBrowseComp:IsMark()
	        nTotTit += (cAlias)->E1_VALOR
	    EndIf
	    (cAlias)->( dbSkip() )
	EndDo

	nTotTit := ROUND(nTotTit,2)
	
	oSay2:Refresh()
	
	RestArea(aArea)

Return nil