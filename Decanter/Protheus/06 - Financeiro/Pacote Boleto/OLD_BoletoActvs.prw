#INCLUDE "TOPCONN.CH"
#Include "totvs.ch"
#INCLUDE "RPTDEF.CH"
#Include "AP5MAIL.CH"

/*/{Protheus.doc} BOLETOACTVS
Impress�o de Boletos - Actvs
@type function
@version  
@author Actvs
@since 10/06/2021
@param aBoletos, array, param_description
@param lReimpre, logical, param_description
/*/
User Function BOLETOACTVS(aBoletos,lReimpre)

	Local   nOpc 		:= 1
	Local	nX			:= 0
	Local	nJ			:= 0
	Local	aCabec		:= {}
	Local   aMarked 	:= {}
	Local 	cQuery		:= ""
	Local 	_oDlg
	Local	oBrowse
	Local	oImgMark
	Local	oImgDMark
	Local 	aSize		:= MsAdvSize()		//Tamanhos da tela
	Local 	nI
	//Local	cTiposTit := SuperGetMv("MV_ZTIPTIT",,"")
	Local	cCondsPag 	:= SuperGetMv("MV_ZCNDPAG",,"")
	Local 	lContSel 	:= .T.
	Private BB			:= .F.
	Private BRADESCO	:= .F.
	Private SAFRA    	:= .F.
	Private ITAU		:= .F.
	Private SANTANDER   := .F.
	Private SOFISA		:= .F.
	Private CAIXAEF     := .F.
	Private HSBC        := .F. // TSC022 07/07/2016
	Private SICOOB      := .F. // TSC022 07/07/2016
	Private SICREDI     := .F. // TSCC47 - Arthur Voltolini 04/10/2024
	Private BANRISUL    := .F. // TSC 422
	Private PINE 		:= .f. // TSC679 - CHARLES REITZ - 14/02/2020
	Private DAYCOVAL	:= .f. // TSC679 - CHARLES REITZ - 14/02/2020
	Private BANCOABC	:= .f. // TSC679 - CHARLES REITZ - 11/03/2020
	Private C6BANK  	:= .f. // TSCC47 - ARTHUR VOLTOLINI - 20/02/2024
	Private aTitulos	:= {}
	Private cLocPagto	:= ""
	Private Exec    	:= .F.
	Private lMarcar		:= .T.
	Private cIndexName 	:= ''
	Private cIndexKey  	:= ''
	Private cFilter    	:= ''
	Private cPerg		:= "ACTBOL1"
	Private cAliasSE1
	Private lAutoExec
	Private lAutoDanf 	:= .F.
	Private _MV_PAR01
	Private _MV_PAR02
	Private _MV_PAR03
	Private _MV_PAR04
	Private _MV_PAR05
	Private _MV_PAR06
	Private _MV_PAR07
	Private _MV_PAR08
	Private _MV_PAR09
	Private _MV_PAR10
	Private _MV_PAR11
	Private _MV_PAR12
	Private _MV_PAR13
	Private _MV_PAR14
	Private _MV_PAR15
	Private _MV_PAR16
	Private _MV_PAR17
	Private _MV_PAR18
	Private _MV_PAR19
	Private _MV_PAR20
	Private _MV_PAR21
	Private _MV_PAR22
	Private _MV_PAR23
	Private _MV_PAR24
	Private _MV_PAR25
	Private _MV_PAR26
	Private _MV_PAR27

	aBoletos := IIF(aBoletos==Nil,{},aBoletos)

	lAutoExec := Len(aBoletos) > 0

	dbSelectArea("SE1")


	If !lAutoExec

		If !ExistDir( "\boleto\" )
			MakeDir( "\boleto\" )
		EndIf

		If !Pergunte (cPerg,.T.)
			Return
		EndIf

		//Configura os parametros
		_MV_PAR01 := MV_PAR01 //Do Prefixo:
		_MV_PAR02 := MV_PAR02 //Ate o Prefixo:
		_MV_PAR03 := MV_PAR03 //Do Titulo:
		_MV_PAR04 := MV_PAR04 //Ate o Titulo:
		_MV_PAR05 := MV_PAR05 //Da Parcela:
		_MV_PAR06 := MV_PAR06 //Ate a Parcela:
		_MV_PAR07 := MV_PAR07 //Do Banco:
		_MV_PAR08 := MV_PAR08 //Agencia:
		_MV_PAR09 := MV_PAR09 //Conta:
		_MV_PAR10 := MV_PAR10 //SubConta:
		_MV_PAR11 := MV_PAR11 //Do Cliente:
		_MV_PAR12 := MV_PAR12 //Ate o Cliente:
		_MV_PAR13 := MV_PAR13 //Da Loja:
		_MV_PAR14 := MV_PAR14 //Ate a Loja:
		_MV_PAR15 := MV_PAR15 //Da Data de Vencimento:
		_MV_PAR16 := MV_PAR16 //Ate a Data de Vencimento:
		_MV_PAR17 := MV_PAR17 //Da Data Emissao:
		_MV_PAR18 := MV_PAR18 //Ate a Data de Emissao:
		_MV_PAR19 := MV_PAR19 //Do :
		_MV_PAR20 := MV_PAR20 //Ate o :
		_MV_PAR21 := MV_PAR21 //Selecionar Titulos:
		_MV_PAR22 := MV_PAR22 //Gerar
		_MV_PAR23 := MV_PAR23 //Tipo Impressao 1-Padrao/2-PDF/3-EMAIL (ainda em desenv)
		_MV_PAR24 := MV_PAR24 //Diretorio dos arquivos PDF


		If Empty(MV_PAR04) .Or. Empty(MV_PAR06) .Or. Empty(MV_PAR12) .Or. Empty(MV_PAR18) .Or. Empty(MV_PAR16) .Or. Empty(MV_PAR14) .Or. Empty(MV_PAR20)
			VerParam("Voce deve selecionar um intervalo de valores em todos os parametros!")
			Return
		EndIf

		nOpc := 1//Aviso("Impressao do Boleto Laser",cDesc,{"Ok","Cancelar"})
	Else
		//COnfigura os parametros
		_MV_PAR21 := IIF(FWIsInCallStack("U_PrtNfU"),2,1)
		_MV_PAR22 := If(lReimpre,2,1) //Gerar Bordero
		//_MV_PAR22 := 1 //Gerar
		//TSCB57 - William Farias - 28/08/2019 - INICIO
		//Utilizado para impressao do boleto automatico apos impressao da danfe
		_MV_PAR23 := MV_PAR23 //Setado no fonte DECA152
		//TSCB57 - FIM

		//Dados do Banco
		_MV_PAR07 := MV_PAR01
		_MV_PAR08 := MV_PAR02
		_MV_PAR09 := MV_PAR03
		_MV_PAR10 := MV_PAR04

	EndIf

	If nOpc == 1

		dbSelectArea("SE1")
		aStruTRB := dbStruct()

		If !lAutoExec

			cQuery := "SELECT  "

			For nI:=1 To Len(aStruTRB)
				cQuery += aStruTRB[nI][1]+","
			Next nI
			//RA/NCC/CC/CD/R$/VA


			cQuery += " SE1.R_E_C_N_O_  AS NREG "
			cQuery += " FROM "+	RetSqlName("SE1") + " SE1 "
			cQuery += " LEFT JOIN "+	RetSqlName("SC5") + " SC5 "
			cQuery += " 			ON SC5.D_E_L_E_T_ = '' "
			cQuery += " 			AND C5_NUM		= E1_PEDIDO "
			cQuery += " 			AND C5_CLIENTE	= E1_CLIENTE "
			cQuery += " 			AND C5_LOJACLI	= E1_LOJA "
			cQuery += " 			AND C5_FILIAL	= E1_MSFIL "
			cQuery += " WHERE E1_NUM   >= '" 	+ _MV_PAR03 		+ "' And E1_NUM     <= '" 	+ _MV_PAR04 + "'  "
			cQuery += " AND E1_PARCELA >= '" 	+ _MV_PAR05 		+ "' And E1_PARCELA <= '"	+ _MV_PAR06 + "'  "
			cQuery += " AND E1_PREFIXO >= '" 	+ _MV_PAR01 		+ "' And E1_PREFIXO <= '"	+ _MV_PAR02 + "'  "
			cQuery += " AND E1_CLIENTE >= '" 	+ _MV_PAR11 		+ "' And E1_CLIENTE <= '"	+ _MV_PAR12 + "' "
			cQuery += " AND E1_EMISSAO >= '" 	+ DTOS(_MV_PAR17)	+ "' And E1_EMISSAO <= '"	+ DTOS(_MV_PAR18) + "' "
			cQuery += " AND E1_VENCTO  >= '" 	+ DTOS(_MV_PAR15)	+ "' And E1_VENCTO  <= '" 	+ DTOS(_MV_PAR16) + "' "
			cQuery += " AND E1_LOJA    >= '"	+ _MV_PAR13			+ "' And E1_LOJA    <= '"	+ _MV_PAR14 + "' "
			If _MV_PAR22 == 2 //Nao gera
				cQuery += " AND E1_NUMBOR  >= '"	+ _MV_PAR19			+ "' And E1_NUMBOR  <= '"	+ _MV_PAR20 + "' "
				If !Empty(_MV_PAR07)
					cQuery += " AND E1_PORTADO = '" + _MV_PAR07 + "' "
				Endif
			Else
				cQuery += " AND E1_NUMBCO = '' AND E1_NUMBOR = '' " //Se gera , somente selecionara os titulos sem boleto
			Endif
			cQuery += " AND E1_FILIAL = '"		+ fwxFilial("SE1")	+ "' And E1_SALDO > 0  "
			cQuery  += " AND E1_TIPO NOT IN " + FormatIn(MVABATIM,"|")
			cQuery  += " AND E1_TIPO NOT IN " + FormatIn(MV_CRNEG,"|")
			cQuery  += " AND E1_TIPO NOT IN " + FormatIn(MVPROVIS,"|")
			cQuery  += " AND E1_TIPO NOT IN " + FormatIn(MVRECANT,"|")
			cQuery  += " AND ((C5_NUM IS NOT NULL AND C5_CONDPAG NOT IN "+FormatIn(cCondsPag,"/")+") OR C5_NUM IS NULL)"
			cQuery  += " AND ((C5_NUM IS NOT NULL AND C5_ZNUMMGT = '' ) OR C5_NUM IS NULL)"
			//cQuery += " AND SUBSTRING(E1_TIPO,3,1) != '-' "
			cQuery += " AND SE1.D_E_L_E_T_ = ' ' "
			cQuery += " ORDER BY E1_PREFIXO, E1_NUM, E1_PARCELA, E1_EMISSAO, E1_NOMCLI, E1_PORTADO"
			//cQuery += " ORDER BY E1_NOMCLI,E1_PORTADO, E1_CLIENTE, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_EMISSAO "
		EndIf

		If Select("TRB1") <> 0
			dbSelectArea("TRB1")
			dbCloseArea()
		EndIf

		cAliasSE1 := "TRB1"
		cNomeArq:=CriaTrab( aStruTRB, .T. )
		dbUseArea(.T.,__LocalDriver,cNomeArq,cAliasSE1,.T.,.F.)

		If !lAutoExec
			MsAguarde({|| SqlToTrb(cQuery, aStruTRB, cAliasSE1 )},OemToAnsi("Executando Query..."))
		Else
			//Criado no ponto de entrada M460NOTA
			For nX:=1 To Len(aBoletos)
				RecLock(cAliasSE1, .T.)
				For nJ:=1 To Len(aBoletos[nX])
					aDados := aBoletos[nX][nJ]
					&(cAliasSE1+"->"+aDados[1]) := aDados[2]
				Next
				MsUnlock()
			Next
		EndIf

		DbSelectArea(cAliasSE1)
		DbGoTOp()

		

			dbSelectArea(cAliasSe1)
			dbGoTop()


			While !EoF()
				aTemp := {}
				lContSel := .T.


				AADD(aTemp, Iif(FwIsInCallStack("U_UNIM007") .Or. FwIsInCallStack("U_DECA152B"),lMarcar,!lMarcar))
				AADD(aTemp, (cAliasSe1)->E1_PREFIXO)
				AADD(aTemp, (cAliasSe1)->E1_NUM)
				AADD(aTemp, (cAliasSe1)->E1_PARCELA)
				AADD(aTemp, (cAliasSe1)->E1_TIPO)
				AADD(aTemp, (cAliasSe1)->E1_NOMCLI)
				AADD(aTemp, (cAliasSe1)->E1_EMISSAO)
				AADD(aTemp, (cAliasSe1)->E1_VENCTO)
				AADD(aTemp, Transform((cAliasSe1)->E1_SALDO,x3Picture("E1_SALDO")))

				AADD(aTitulos, aTemp)
				dbSelectArea(cAliasSe1)
				(cAliasSe1)->(DbSkip())
			EndDo

			If Len(aTitulos) == 0
				Alert("Nao foram encontrados titulos com os parametros informados!")
				DbSelectArea("SE1")
				RetIndex("SE1")
				FErase(cIndexName+OrdBagExt())
				Return
			EndIf
		If _mv_par21 == 1
			AADD(aCabec, "")
			AADD(aCabec, "Prefixo")
			AADD(aCabec, "Documento")
			AADD(aCabec, "Parcela")
			AADD(aCabec, "Tipo")
			AADD(aCabec, "Cliente")
			AADD(aCabec, "Emissao")
			AADD(aCabec, "Vencimento")
			AADD(aCabec, "Valor")

			DEFINE MSDIALOG _oDlg TITLE "Selecao de titulos para geracao de boletos" From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL

			oImgMark 	:= LoadBitmap(GetResources(),'LBTIK')
			oImgDMark	:= LoadBitmap(GetResources(),'LBNO')

			oBrowse:= TCBROWSE():New(001,001,350,170,,aCabec,{},_oDlg,,,,,{||},,_oDlg:oFont,,,,,.F.,,.T.,,.F.,,,)

			oBrowse:SetArray(aTitulos)
			oBrowse:lAdjustColSize 	:= .T.
			oBrowse:bLDblClick		:= {|nRow, nCol| aTitulos[oBrowse:nAt,01] := !aTitulos[oBrowse:nAt,01]}
			oBrowse:bChange			:= {||SetFocus(oBrowse:hWnd)}
			oBrowse:bHeaderClick	:= {|nRow, nCol| If(nCol == 1,(lMarcacao(),oBrowse:Refresh()),Nil) }
			oBrowse:nAt				:= 1
			oBrowse:Align			:= CONTROL_ALIGN_ALLCLIENT //Tela inteira
			oBrowse:bLine 			:= {||{ If(	aTitulos[oBrowse:nAt,01],oImgMark,oImgDMark),;
				aTitulos[oBrowse:nAt,02],;
				aTitulos[oBrowse:nAt,03],;
				aTitulos[oBrowse:nAT,04],;
				aTitulos[oBrowse:nAT,05],;
				Padr(aTitulos[oBrowse:nAT,06],50),;
				aTitulos[oBrowse:nAT,07],;
				aTitulos[oBrowse:nAT,08],;
				aTitulos[oBrowse:nAT,09]}}


			ACTIVATE DIALOG _oDlg CENTERED ON INIT EnchoiceBar(_oDlg,{|| Exec := .T.,_oDlg:End()},{|| Exec := .F.,_oDlg:End()})
		EndIf
	EndIf

	//Execucao automatica
	If _mv_par21 == 2
		Exec := .T.
	EndIf

	For nX:=1 To Len(aTitulos)
		AADD(aMarked,IIF(_mv_par21 == 2,.T.,aTitulos[nX][1]))
	Next

	// TSCC34 - Diego Oliveira - 17/02/2025
	// If Exec 
	If Exec .and. !isBlind()
		Processa({|lEnd| MontaRel(aMarked)})
	Else
		MontaRel(aMarked)
	Endif

	DbSelectArea("SE1")
	RetIndex("SE1")
	FErase(cIndexName+OrdBagExt())

	If !lAutoDanf
		MsgInfo("Processo finalizado!",Procname())
	EndIf

Return

//------------------------------------------------------------------------------------
// Inverte marcacao
//------------------------------------------------------------------------------------
Static Function lMarcacao()
	Local nX:= 0
	For nX:= 1 To Len(aTitulos)
		aTitulos[nX][1] := lMarcar
	Next
	lMarcar := !lMarcar

Return

/*/{Protheus.doc} MontaRel
Montagem do relat�rio para impress�o de Boletos
@type function
@version  
@author Actvs 
@since 10/06/2021
@param aMarked, array, param_description
@return return_type, return_description
/*/
Static Function MontaRel(aMarked)

	Local aDatPagador
	Local aBolText
	Local lMark			:= .F.
	Local CB_RN_NN  	:= {}
	Local i        		:= 1
	Local n 			:= 0
	Local nX        	:= 0
	Local nRec      	:= 0

	Local aBitmap   	:= {"" ,"\Bitmaps\Logo_Siga.bmp"}  //Logo da empresa
	Local aBMP			:= aBitMap
	Local cNomImpTmp 	:= ""
	Local nPagImpTmp 	:= 0
	Local cDecAuto	 	:= ""
	Local nDeviceImp	:= 0
	Local cE1CliNum		:= ""
	Local cE1Num		:= ""
	Local cCliDest		:= ""
	Local cLojDest		:= ""
	Local aFilE1Cli		:= {}


	Private aDadosEmp	:= {SM0->M0_NOMECOM                                	,; //Nome da Empresa
	AllTrim(SM0->M0_ENDCOB)                                          		,; //Endereco
	AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB 	,; //Complemento
	"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             ,; //CEP
	"PABX/FAX: "+SM0->M0_TEL                                              ,; //Telefones
	"CNPJ: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+           	;
		Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+                    	;
		Subs(SM0->M0_CGC,13,2)                                             	,; //CGC
	"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+      		;
		Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                      	}  //I.E


	Private aDadosTit
	Private aDadosBanco
	Private nFatorH := 1
	Private nFatorV := 1
	Private nAddSay := 0
	Private nAddLin := 0
	Private nAddBco := 0


	DbSelectArea(cAliasSE1)
	dbGoTop()

	For nX:=1 To Len(aMarked)
		If !lMark
			lMark := aMarked[nX]
		EndIf
	Next

	If !lMark
		Alert("Voc� n�o marcou nenhum t�tulo!")
		Return
	EndIf

	If _MV_PAR23 == 1 //Se for gera��o em tela
		oPrint:= TMSPrinter():New( "Boleto Laser" )
		oPrint:setPortrait()
		oPrint:setPaperSize(DMPAPER_A4)
		oPrint:Setup()
		oPrint:SetPortrait() 	// ou SetLandscape()
		oPrint:SetPaperSize(DMPAPER_A4)	// tamanho A4
		oPrint:StartPage()   	// Inicia uma nova pagina
	EndIf

	ProcRegua(nRec)

	While !EOF()

		If !aMarked[i]
			i++
			dbSkip()
			Loop
		Endif

		//Posiciona o SA6 (Bancos)
		SA6->(DbSetOrder(1))
		cSeekMS	:=	""
		If !Empty((caliasSE1)->E1_AGEDEP) .And. _MV_PAR22 == 2
			cSeekMS	:=	fwxFilial("SA6")+(caliasSE1)->E1_PORTADO+(caliasSE1)->E1_AGEDEP+(caliasSE1)->E1_CONTA
		Else
			cSeekMS := fwxFilial("SA6")+_MV_PAR07+_MV_PAR08+_MV_PAR09
		Endif

		If !SA6->(msSeek(cSeekMS))
			MsgStop("Banco/Agencia nao Encontrado",ProcName())
			Return
		Endif


		SEA->(DbSetOrder(1))
		SEA->(msSeek(xFilial("SEA")+(caliasSE1)->E1_NUMBOR+(caliasSE1)->E1_PREFIXO+(caliasSE1)->E1_NUM+(caliasSE1)->E1_PARCELA+(caliasSE1)->E1_TIPO))

		//Posiciona o SEE (Parametros banco)
		SEE->(DbSetOrder(1))
		cSeekMS	:=	""
		If !Empty((caliasSE1)->E1_AGEDEP) .And. _MV_PAR22 == 2
			cSeekMS	:= FWxFilial("SEE")+(caliasSE1)->(E1_PORTADO+E1_AGEDEP+E1_CONTA)+SEA->EA_SUBCTA
		Else
			cSeekMS	:= FWxFilial("SEE")+_MV_PAR07+_MV_PAR08+_MV_PAR09+_MV_PAR10
		Endif

		If !SEE->(DBSeek(cSeekMS))
			MsgStop("Parametros Bancos Nao Encontrado",ProcName())
			Return
		EndIf

		// TSC679 CHARLES REITZ - 11/03/2020
		// Verifica se trata o banco oficial
		If !Empty(SEE->EE_CTAOFI)
			nRecA6	:= SA6->(recno()) // salva banco atual
			If !SA6->(msSeek(FWxFilial("SA6")+SEE->(EE_CODOFI+EE_AGEOFI+EE_CTAOFI) )) //A6_FILIAL, A6_COD, A6_AGENCIA, A6_NUMCON, R_E_C_N_O_, D_E_L_E_T_
				IF !isBlind()
					MsgStop("N�o localizado o banco Oficial no cadastro de bancos",ProcName())
				Else
					ConOut("N�o localizado o banco Oficial no cadastro de bancos",ProcName())
				EndIf
				Return
			EndIf
			SA6->(dbGoTO(nRecA6))
		EndIf


		cA6_COD := SA6->A6_COD
		cA6_AGE := SA6->A6_AGENCIA
		cA6_CON := SA6->A6_NUMCON
		cA6_NOM := SA6->A6_NREDUZ
		cA6_DIG := SA6->A6_DVCTA
		cA6_DAG := SA6->A6_DVAGE
		cA6_POS := SEE->EE_CODPROD // ESPECIFICO SICREDI

		If SEE->(FieldPos("EE_BANCORR")) > 0 .and. SEE->(FieldPos("EE_AGECORR")) > 0 .and. SEE->(FieldPos("EE_CONCORR")) > 0 .and.;
				!Empty(SEE->EE_BANCORR) .and. !Empty(SEE->EE_AGECORR) .and. !Empty(SEE->EE_CONCORR)

			aOldSA6 := SA6->(GetArea())
			DbSelectArea("SA6")
			DbSetOrder(1)
			If msSeek(xFilial("SA6")+SEE->EE_BANCORR+SEE->EE_AGECORR+SEE->EE_CONCORR)
				cA6_COD := SEE->EE_BANCORR
				cA6_AGE := SEE->EE_AGECORR
				cA6_CON := SEE->EE_CONCORR
				cA6_NOM := SA6->A6_NREDUZ
				cA6_DIG := SA6->A6_DVCTA
				cA6_DAG := SA6->A6_DVAGE
				cA6_POS := SEE->EE_CODPROD // ESPECIFICO SICREDI
			Endif
			RestArea(aOldSA6)
		Endif

		//Posiciona o SA1 (Cliente)
		DbSelectArea("SA1")
		SA1->(DbSetOrder(1))
		SA1->(msSeek(xFilial("SA1")+(caliasSE1)->(E1_CLIENTE+E1_LOJA)))
		zdesc:=SA1->A1_ZDESC
		If Len(Alltrim(SA1->A1_CGC))== 14
			cCpfCnpj:="CNPJ "+Transform(SA1->A1_CGC,"@R 99.999.999/9999-99")
		Else
			cCpfCnpj:="CPF "+Transform(SA1->A1_CGC,"@R 999.999.999-99")
		Endif

		DbSelectArea("SE1")

		aDadosBanco  := {cA6_COD                                       ,;               //Numero do Banco
		cA6_NOM                                       ,;               //Nome do Banco
		Iif(cA6_COD=="479",StrZero(Val(AllTrim(cA6_AGE)),7),SubStr(StrZero(Val(AllTrim(cA6_AGE)),4),1,4)+Iif(Empty(cA6_DAG),"","-"+cA6_DAG)),;   //Agencia
		Iif(cA6_COD=="479",AllTrim(SEE->EE_CODEMP),AllTrim(cA6_CON)),;   //Conta Corrente
		Iif(cA6_COD=="479","",If(Empty(cA6_DIG),"",cA6_DIG))  ,;               //Digito da conta corrente
		AllTrim(SEE->EE_CARTEIR)+Iif(!Empty(AllTrim(SEE->EE_VARIACA)),"-"+SEE->EE_VARIACA,"") }                //Carteira

		aDatPagador   := {AllTrim(SA1->A1_NOME)+" - "+cCpfCnpj             ,;      //Razao Social
		AllTrim(SA1->A1_COD )                            ,;      //Codigo
		Iif(!Empty(SA1->A1_ENDCOB),AllTrim(SA1->A1_ENDCOB)+" - "+SA1->A1_BAIRROC,AllTrim(SA1->A1_END)+"-"+SA1->A1_BAIRRO) ,;      //Endereco
		Iif(!Empty(SA1->A1_MUNC), AllTrim(SA1->A1_MUNC ), AllTrim(SA1->A1_MUN )) ,;      //Cidade
		Iif(!Empty(SA1->A1_ESTC), SA1->A1_ESTC, SA1->A1_EST) ,;      //Estado
		Iif(!Empty(SA1->A1_CEPC), SA1->A1_CEPC, SA1->A1_CEP)  }       //CEP

		_nSaldo := 0
		_nSaldo := (caliasSE1)->E1_SALDO+(caliasSE1)->E1_SDACRES-(caliasSE1)->E1_SDDECRE
		_nSaldo -= SomaAbat((caliasSE1)->E1_PREFIXO,(caliasSE1)->E1_NUM,(caliasSE1)->E1_PARCELA,"R",1,,(caliasSE1)->E1_CLIENTE,(caliasSE1)->E1_LOJA)

		//Monta o
		If lAutoExec .Or. _MV_PAR22 == 1

			cAliasTmp 	:= Alias()
			cRecTmp		:= Recno()
			cBordero 	:= Iif(!Empty((caliasSE1)->E1_NUMBOR),(caliasSE1)->E1_NUMBOR,BuscaBorde())

			If Empty(cBordero)
				cBordero := GetMv("MV_NUMBORR",.F.)
				If Empty(cBordero)
					cBordero := "000001"
				Endif
				PutMv("MV_NUMBORR",Soma1(cBordero))
			Endif

			If Empty( (caliasSE1)->E1_NUMBOR )
				BEGIN TRANSACTION
					RecLock("SEA",.T.)
					SEA->EA_FILIAL		:= (caliasSE1)->E1_FILIAL
					SEA->EA_PREFIXO 	:= (caliasSE1)->E1_PREFIXO
					SEA->EA_NUM 		:= (caliasSE1)->E1_NUM
					SEA->EA_PARCELA 	:= (caliasSE1)->E1_PARCELA
					SEA->EA_PORTADO 	:= SA6->A6_COD
					SEA->EA_AGEDEP 		:= SA6->A6_AGENCIA
					SEA->EA_SUBCTA 		:= _MV_PAR10
					SEA->EA_DATABOR 	:= (dDataBase)
					SEA->EA_TIPO 		:= (caliasSE1)->E1_TIPO
					SEA->EA_LOJA 		:= (caliasSE1)->E1_LOJA
					SEA->EA_NUMCON 		:= SA6->A6_NUMCON
					SEA->EA_SALDO 		:= (caliasSE1)->E1_SALDO
					SEA->EA_FILORIG 	:= (caliasSE1)->E1_FILORIG
					SEA->EA_CART 		:= "R"
					SEA->EA_NUMBOR 		:= cBordero
					SEA->EA_SITUACA		:= "1"
					SEA->EA_SITUANT     := "0"
					SEA->(MsUnlock())

					DbSelectArea("SE1")
					DbSetOrder(1) //incluido pelo sadiomar em 22/04/2013
					msSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))

					RecLock("SE1",.F.)
					SE1->E1_NUMBOR	:= cBordero
					SE1->E1_MOVIMEN	:= dDataBase
					SE1->E1_DATABOR	:= dDataBase
					SE1->E1_SITUACA	:= "1"
					SE1->E1_PORTADO := SA6->A6_COD
					SE1->E1_AGEDEP  := SA6->A6_AGENCIA
					SE1->E1_CONTA   := SA6->A6_NUMCON
					SE1->(MsUnlock())
				END TRANSACTION
			Endif

			DbSelectArea("SE1")
			DbSetOrder(1)
			msSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))

			DbSelectArea(cAliasTmp)
			DbGoTo(cRecTmp)

		EndIf

		//Tamanho do NOSSO NUMERO
		nTam_NN := Iif( SEE->EE_TAM_NN == 0 , 11 , SEE->EE_TAM_NN )

		If Empty((caliasSE1)->E1_NUMBCO)
			SEE->(DBSeek(cSeekMS))
			cNosso_Num :=  StrZero( Val(SEE->EE_FAXATU), nTam_NN )

			//TSCB57 - William Farias em 24/01/2020 - Verifica se codigo do NOSSO NUMERO esta sendo usado e pega novo
			While .T.
				iF KillApp()
					Break
				EndIf

				cWhereF	:=	"% AND  SUBSTRING(LTRIM(E1_NUMBCO),1,"+cValToChar(nTam_NN)+") = '"+cNosso_Num+"' %"
				// Verifica se n�o est� duplicado o nosso numero
				Beginsql alias "TRBE1BCO"
									SELECT COUNT(1) 
									FROM %table:SE1%
									WHERE D_E_L_E_T_ 	= ''
									AND E1_FILIAL 		= %xFilial:SE1%
									%exp:cWhereF%
									AND E1_PORTADO 		= %exp:SA6->A6_COD%
									AND E1_AGEDEP 		= %exp:SA6->A6_AGENCIA%
									AND E1_CONTA 		= %exp:SA6->A6_NUMCON%
				EndSql


				If TRBE1BCO->(Eof())
					TRBE1BCO->(dbCloseArea())
					cNosso_Num := Soma1(cNosso_Num)
					Loop
				EndIf
				TRBE1BCO->(dbCloseArea())

				If MayIUseCode("EE_FAXATU"+SA6->(A6_COD+A6_AGENCIA+A6_NUMCON)+cNosso_Num)
					Exit
				Else
					cNosso_Num := Soma1(cNosso_Num)
				EndIf
			EndDo
			//TSCB57 - FIM

			BEGIN TRANSACTION
				DbSelectArea("SEE")
				RecLock("SEE",.f.)
				SEE->EE_FAXATU := StrZero( Val(cNosso_Num) + 1, nTam_NN )
				SEE->(MsUnlock())

				//TSCB57 - William Farias em 28/01/2020 - Libera o codigo para nao gerar fila.
				//Evita mensagem: N�mero de C�digos Reservados maior que 20.
				Leave1Code("EE_FAXATU"+SA6->(A6_COD+A6_AGENCIA+A6_NUMCON)+cNosso_Num)
				//TSCB57 - FIM
			END TRANSACTION

		Else
			cNosso_Num := StrZero( Val( Substr((caliasSE1)->E1_NUMBCO,1,nTam_NN) )  , nTam_NN )
		EndIf

		If Val(cNosso_Num) == 0
			cNosso_Num := StrZero( 1, nTam_NN )
		Endif



		//montando codigo de barras
		//Caso o titulo ja tenha sido impresso sera pego o nosso numero do campo E1_NUMBCO
		CB_RN_NN    := Ret_cBarra(;
			Substr(aDadosBanco[1],1,3)+"9",;
			Subs(aDadosBanco[3],1,4),;
			aDadosBanco[4],;
			aDadosBanco[5],;
			Iif(cA6_COD=="643",aLLTRIM(aDadosBanco[6]),SubStr(aDadosBanco[6],1,2)),;
			AllTrim((caliasSE1)->E1_NUM)+AllTrim((caliasSE1)->E1_PARCELA),;
			_nSaldo,;
			(caliasSE1)->E1_VENCREA,;
			SEE->EE_CODEMP,;
			cNosso_Num,;
			SEE->EE_CARTEIR)

		//aDadosTit    :=  {AllTrim((caliasSE1)->E1_NUM)+AllTrim((caliasSE1)->E1_PARCELA)  ,;             //Numero do titulo
		aDadosTit    :=  {;
			AllTrim((caliasSE1)->E1_NUM)  ,;             //Numero do titulo
		(caliasSE1)->E1_EMISSAO      ,;             //Data da emissao do titulo
		MsDate()    ,;             //Data da emissao do boleto
		(caliasSE1)->E1_VENCREA  ,;             //Data do vencimento
		_nSaldo,;             //Valor do titulo
		SubStr(CB_RN_NN[3],1,Len(CB_RN_NN[3])-1)+"-"+SubStr(CB_RN_NN[3],Len(CB_RN_NN[3]),1) ,; //Nosso numero (Ver formula para calculo)
		AllTrim((caliasSE1)->E1_TIPO)  ,;//TIPO DO TITULO
		AllTrim((caliasSE1)->E1_PARCELA),; //PARCELA DO TITULO
		SEE->EE_CODEMP,;//Cod Empresa
		AllTrim(SEE->EE_CODEMP)+SubStr(CB_RN_NN[3],1,Len(CB_RN_NN[3])-1)+SubStr(CB_RN_NN[3],Len(CB_RN_NN[3]),1),;
			CB_RN_NN[3] }

		//Mensagens boleto
		aBolText  := 	{}

		//Mensagem de desconto
		If (caliasSE1)->E1_DESCFIN > 0
			nValDesc := ((caliasSE1)->E1_DESCFIN * (caliasSE1)->E1_SALDO) / 100
			cDesconto := "DESCONTO DE R$ "+Alltrim(TransForm(nValDesc,"@E 9999,999,999.99"))+" P/ PAGTO ATE O VENCIMENTO"
			aAdd( aBolText , cDesconto )
		Endif
		//19-04-22 - DIANA ajustado para tratar clientes com desconto financeiro so no boleto, o padrao foi desconsiderado
		If zdesc > 0
			nValDesc := (zdesc * (caliasSE1)->E1_SALDO) / 100
			cDesconto := "DESCONTO DE R$ "+Alltrim(TransForm(nValDesc,"@E 9999,999,999.99"))+" P/ PAGTO ATE O VENCIMENTO"
			aAdd( aBolText , cDesconto )
		Endif

		//Mensagem de juros
		If (caliasSE1)->E1_VALJUR > 0
			cJuros := "JUROS DE MORA POR DIA - R$ "+Alltrim(TransForm((caliasSE1)->E1_VALJUR,"@E 9999,999,999.99"))
			aAdd( aBolText , cJuros )
		ElseIf (caliasSE1)->E1_PORCJUR > 0
			nValJuros := ((caliasSE1)->E1_PORCJUR * (caliasSE1)->E1_SALDO) / 100
			cJuros    := "JUROS DE MORA POR DIA - R$ "+Alltrim(TransForm(nValJuros,"@E 9999,999,999.99"))
			aAdd( aBolText , cJuros )
		Endif
		//Mensagem para protesto/Negativacao
		If SubStr(SEE->EE_INSTPRI,1,2) == "66"
			cProtesto := "NEGATIVAR NO "+SEE->EE_DIASPRO+"o DIA APOS O VENCIMENTO"
			aAdd( aBolText , cProtesto )
		Else
			If Alltrim(SEE->EE_DIASPRO) <> "00" .And. !Empty(SEE->EE_DIASPRO)
				cProtesto := "Titulo sujeito a Protesto apos "+SEE->EE_DIASPRO+" dias de vencimento."
				aAdd( aBolText , cProtesto )
			EndIf
		EndIf
		//Outras Mensagens de instrucao
		aAdd( aBolText , SEE->EE_MSG1 ) //Instrucao 1
		aAdd( aBolText , SEE->EE_MSG2 ) //Instrucao 2
		aAdd( aBolText , SEE->EE_MSG3 ) //Instrucao 3

		cLocPagto := SEE->EE_LOCPAG //Local para pagamento
		cEspecieD := SEE->EE_ESPDOC //Especie Doc
		cAceite   := SEE->EE_ACEITE //Aceite
		BB		:= Substr(aDadosBanco[1],1,3) == "001"
		BRADESCO	:= Substr(aDadosBanco[1],1,3) == "237"
		ITAU 		:= Substr(aDadosBanco[1],1,3) $ "341/655"
		SAFRA    	:= Substr(aDadosBanco[1],1,3) == "422"
		SANTANDER := Substr(aDadosBanco[1],1,3) == "033"
		SOFISA 	:= Substr(aDadosBanco[1],1,3) == "637"
		CAIXAEF   := Substr(aDadosBanco[1],1,3) == "104"
		BANRISUL  := Substr(aDadosBanco[1],1,3) == "041"
		HSBC      := Substr(aDadosBanco[1],1,3) == "399"
		SICOOB    := Substr(aDadosBanco[1],1,3) == "756"
		SICREDI   := Substr(aDadosBanco[1],1,3) == "748"
		CECRED    := Substr(aDadosBanco[1],1,3) == "085"
		PINE  	:= Substr(aDadosBanco[1],1,3) == "643"
		DAYCOVAL  	:= Substr(aDadosBanco[1],1,3) == "707"
		BANCOABC  	:= Substr(aDadosBanco[1],1,3) == "246"
		C6BANK  	:= Substr(aDadosBanco[1],1,3) == "336"

		cValCIP   := SEE->EE_VALCIP

		If Empty(AllTrim((caliasSE1)->E1_NUMBCO)) //AINDA NAO FOI IMPRESSO O TITULO
			SE1->(dbSetOrder(1))
			If SE1->(msSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))
				RecLock("SE1",.F.)
				SE1->E1_OCORREN	:= "01" //Registro de Titulos
				SE1->E1_INSTR1	:= IIf(Empty(SEE->EE_INSTPRI),"00",SubStr(SEE->EE_INSTPRI,1,2)) //"00" //05-Protestar no 5o. Dia Util (1o. Intrs cod.)
				SE1->E1_INSTR2 	:= "00" //00-Ausencia de Instrucoes (2a. Intr. cod.)
				SE1->E1_NUMBCO 	:= CB_RN_NN[3] //Nosso numero com ou sem digito verificador (depende da configuracao do banco)
				SE1->E1_PORTADO	:= SA6->A6_COD
				SE1->(MsUnlock())
			EndIf
		Endif

		// WALTER - 21/09/2018
		//If _MV_PAR23 <> 1 //Se for gerar PDF

		nFatorH := 0.9
		nFatorV := 0.8
		nAddSay := 70
		nAddLin := 50
		nAddBco := 40

		//Define o nome do arquivo a ser gerado em PDF
		SE1->(msSeek(xFilial("SE1")+(cAliasSE1)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))
		If !Empty(SE1->E1_PARCELA)
			cFatura := Alltrim(SE1->E1_PREFIXO)+AllTrim(SE1->E1_NUM)+"_"+AllTrim(SE1->E1_PARCELA)
		Else
			cFatura := Alltrim(SE1->E1_PREFIXO)+AllTrim(SE1->E1_NUM)
		EndIf

		//Verifica se o boleto j� est� no diretorio e exclui
		
		// /TSCC34 - Diego Oliveira - 17/02/2024
		// cDirTmpFat := ALLTRIM(GETTEMPPATH()) //"\boleto\"
		
		// If !isBlind()
			// cDirTmpFat := ALLTRIM(GETTEMPPATH(.F.)) //"\boleto\"
			cDirTmpFat := "\spool\"
		// Else
		// 	cDirTmpFat := "\boleto\"
		// EndIF
		
		If File(cDirTmpFat+"\totvsprinter\"+cFatura+".rel")
			FERASE(cDirTmpFat+"\totvsprinter\"+cFatura+".rel")
		EndIf
		If File(cDirTmpFat+"\totvsprinter\"+cFatura+".pdf")
			FERASE(cDirTmpFat+"\totvsprinter\"+cFatura+".pdf")
		EndIf

		nResol := 72

		//TSCB57 - William Farias - 28/08/2019 - INICIO
		//Imprime boleto automatico apos impressao da danfe
		If sfValAtrib("cDecImpAut") == "U" .And. !FwIsInCallStack("U_DECA152B")
			If !Empty( _MV_PAR24)
				cDecAuto := "IMP_PDF"
			EndIf
		Else
			If !FwIsInCallStack("U_DECA152B")
				cDecAuto := cDecImpAut
			EndIf
			lAutoDanf := .T.
		EndIf

		// Verifica se mudou o clinente e t�tulo
		If !Empty(cE1CliNum) .And. cE1CliNum <>  (cAliasSE1)->(E1_CLIENTE+E1_LOJA+E1_NUM)
			// Efetua envio do Boleto
			DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1")+cCliDest+cLojDest)
				// Verifica se o campo existe e se est� ativo o cliente para enviar o boleto
				If SA1->(FieldPos("A1_ZBLMAIL")) > 0 .And. SA1->A1_ZBLMAIL == "1"
					sfEnvioMail(sfObtEmail(cCliDest,cLojDest), aFilE1Cli,cE1Num)
				Endif
			Endif

			aFilE1Cli		:= {}
		Endif

		Aadd(aFilE1Cli,"\boleto\"+cFatura+".pdf")

		if Type("_oPrtDanf")=="O"
			cNomImpTmp:= _oPrtDanf:cPrinter

			If isBlind()
				cNomImpTmp	:=	SuperGetMV("DC_NOMIMP",,"Logistica_BNU_DANFE")
			EndIF

			nDeviceImp:= _oPrtDanf:nDevice
			oPrintA := FWMSPrinter():New(cFatura,IMP_SPOOL,.T.,,.T.)
			// oPrintA := FWMsPrinter():New(cFatura, IMP_SPOOL  , .F., cDirTmpFat, .T., , , cNomImpTmp, .F., , .F.)
			// oPrintA := FWMSPrinter():New(cFatura+".pdf", IMP_SPOOL, .F. ,cDirTmpFat  , .T., , ,           , , .F., ,.F. , )

			oPrintA:SetResolution(nResol)
			oPrintA:SetPortrait()
			
			// If !isBlind()
			// 	oPrintA:cPathPDF := _oPrtDanf:cPathPDF
			// Else
			// 	oPrintA:cPathPDF := cDirTmpFat
			// EndIf
			oPrintA:SetPaperSize(DMPAPER_A4)
			oPrintA:SetMargin(60,60,60,60)

			oPrintA:nDevice := _oPrtDanf:nDevice
			
			// If !isBlind()
				oPrintA:lServer	:=	.F.
			// Else
			// 	oPrintA:lServer	:=	.T.
			// 	oPrintA:lInJob	:=	.T.
			// EndIf

			aRetImpS	:=	GetImpWindows(.T.)
			nPosImp		:=	aScan(aRetImpS,{|x| Alltrim(x) == Alltrim(cNomImpTmp) })
			If nPosImp == 0 .And. nDeviceImp == IMP_SPOOL
				cMsgRet	:=	"Impressora n�o localizada para impress�o do boleto autom�tico. Impressora:"+cNomImpTmp
				msgInfo(cMsgRet,"Aten��o - "+Procname()+"/"+cValToChar(ProcLine()))
				U_xMPad("BOLETOACTVS","ERROR","",cMsgRet)
				Break
			EndIf

			oPrintA:cPrinter := cNomImpTmp
			If nDeviceImp == IMP_PDF
				oPrintA:SetViewPDF(.T.)
			Else
				oPrintA:SetViewPDF(.F.)
			Endif
		elseIf cDecAuto <> "IMP_PDF"
			nPagImpTmp++
			If nPagImpTmp == 1
				oPrintA := FWMSPrinter():New(cFatura,IMP_SPOOL,.T.,,.T.)
				oPrintA:SetResolution(nResol)
				oPrintA:SetPortrait()
				oPrintA:cPathPDF := cDirTmpFat
				oPrintA:SetPaperSize(DMPAPER_A4)
				oPrintA:SetMargin(60,60,60,60)
				oPrintA:nDevice := IMP_SPOOL //IMP_PDF
				oPrintA:lServer	:=	.F.
				oPrintA:Setup()

				If oPrintA:nDevice == IMP_PDF
					oPrintA:SetViewPDF(.T.)
				Else
					oPrintA:SetViewPDF(.F.)
				Endif
				cNomImpTmp 	:= oPrintA:cPrinter
				nDeviceImp	:= oPrintA:nDevice

				oPrintC := FWMSPrinter():New(cFatura,6,.T.,,.T.) //FWMSPrinter():New(cFatura,IMP_PDF,.T.,cDirTmpFat,.T.,,@oPrint,,.T.,,,.F.)
				oPrintC:SetResolution(nResol)
				oPrintC:SetPortrait()
				If sfValAtrib("cDecLocPdf") <> "U"
					oPrintC:cPathPDF := cDecLocPdf
				Else
					oPrintC:cPathPDF := cDirTmpFat
				EndIf
				oPrintC:SetPaperSize(DMPAPER_A4)
				oPrintC:SetMargin(60,60,60,60)
				oPrintC:SetViewPDF(.F.)

				//cNomImpTmp := GetProfString(GetPrinterSession(), "DEFAULT", "", .T.)
			ElseIf nPagImpTmp > 1
				oPrintB := FWMSPrinter():New(cFatura,nDeviceImp,.T.,,.T.)
				oPrintB:SetResolution(nResol)
				oPrintB:SetPortrait()
				oPrintB:cPathPDF := cDirTmpFat
				oPrintB:SetPaperSize(DMPAPER_A4)
				oPrintB:SetMargin(60,60,60,60)
				oPrintB:nDevice := nDeviceImp
				oPrintB:lServer	:=	.F.

				aRetImpS	:=	GetImpWindows(.T.)
				nPosImp		:=	aScan(aRetImpS,{|x| Alltrim(x) == Alltrim(cNomImpTmp) })
				If nPosImp == 0 .And. nDeviceImp == IMP_SPOOL
					cMsgRet	:=	"Impressora n�o localizada para impress�o do boleto autom�tico. Impressora:"+cNomImpTmp
					msgInfo(cMsgRet,"Aten��o - "+Procname()+"/"+cValToChar(ProcLine()))
					U_xMPad("BOLETOACTVS","ERROR","",cMsgRet)
					Break
				EndIf

				oPrintB:cPrinter := cNomImpTmp
				If nDeviceImp == IMP_PDF
					oPrintB:SetViewPDF(.T.)
				Else
					oPrintB:SetViewPDF(.F.)
				Endif

				oPrintC := FWMSPrinter():New(cFatura,6,.T.,,.T.) //FWMSPrinter():New(cFatura,IMP_PDF,.T.,cDirTmpFat,.T.,,@oPrint,,.T.,,,.F.)
				oPrintC:SetResolution(nResol)
				oPrintC:SetPortrait()
				If sfValAtrib("cDecLocPdf") <> "U"
					oPrintC:cPathPDF := cDecLocPdf
				Else
					oPrintC:cPathPDF := cDirTmpFat
				EndIf
				oPrintC:SetPaperSize(DMPAPER_A4)
				oPrintC:SetMargin(60,60,60,60)
				oPrintC:SetViewPDF(.F.)

			EndIf
			//TSCB57 - FIM
		Else

			oPrintC := FWMSPrinter():New(cFatura,6,.T.,,.T.) //FWMSPrinter():New(cFatura,IMP_PDF,.T.,cDirTmpFat,.T.,,@oPrint,,.T.,,,.F.)
			oPrintC:SetResolution(nResol)
			oPrintC:SetPortrait()
			If sfValAtrib("cDecLocPdf") <> "U"
				oPrintC:cPathPDF := cDecLocPdf
			Else
				oPrintC:cPathPDF := cDirTmpFat
			EndIf
			oPrintC:SetPaperSize(DMPAPER_A4)
			oPrintC:SetMargin(60,60,60,60)
			oPrintC:SetViewPDF(.F.)
		EndIf
		//Endif
		//FIM

		If aMarked[i]

			If sfValAtrib("oPrint") <> "U"
				Impress(oPrint,aBMP,aDadosEmp,aDadosTit,aDadosBanco,aDatPagador,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)
			Endif

			If sfValAtrib("oPrintA") <> "U"
				Impress(@oPrintA,aBMP,aDadosEmp,aDadosTit,aDadosBanco,aDatPagador,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)
				oPrintA:Print()   //Gerar em PDF
				//move o PDF para o servidor
				If !isBlind()
					CpyT2S( cDirTmpFat+cFatura+".PDF", "\boleto" )
				Else
					__CopyFile(cDirTmpFat+cFatura+".PDF", "\boleto"+cFatura+".PDF")
				EndIF

				//move para o diretorio do parametro
				If !Empty(_MV_PAR24)
					CpyS2T("\boleto\"+cFatura+".PDF", AllTrim(_MV_PAR24) )
				EndIF
				oPrintA	:= Nil
			Endif

			If sfValAtrib("oPrintB") <> "U"
				Impress(@oPrintB,aBMP,aDadosEmp,aDadosTit,aDadosBanco,aDatPagador,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)
				oPrintB:Print()   //Gerar em PDF
				//move o PDF para o servidor
				If !isBlind()
					CpyT2S( cDirTmpFat+cFatura+".PDF", "\boleto" )
				Else
					__CopyFile(cDirTmpFat+cFatura+".PDF", "\boleto"+cFatura+".PDF")
				EndIf

				//move para o diretorio do parametro
				If !Empty(_MV_PAR24)
					CpyS2T("\boleto\"+cFatura+".PDF", AllTrim(_MV_PAR24) )
				EndIF
				oPrintB := Nil
			Endif

			If sfValAtrib("oPrintC") <> "U"
				Impress(oPrintC,aBMP,aDadosEmp,aDadosTit,aDadosBanco,aDatPagador,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)
				oPrintC:Print()   //Gerar em PDF

				//move o PDF para o servidor
				If !IsBlind()
					CpyT2S( cDirTmpFat+cFatura+".PDF", "\boleto" )
				Else
					__CopyFile(cDirTmpFat+cFatura+".PDF", "\boleto"+cFatura+".PDF")
				EndIf

				//move para o diretorio do parametro
				If !Empty(_MV_PAR24)
					CpyS2T("\boleto\"+cFatura+".PDF", AllTrim(_MV_PAR24) )
				EndIF
				oPrintC := Nil
			Endif

			n := n + 1
		EndIf


		cDecAuto := ""
		cE1CliNum	:= (cAliasSE1)->(E1_CLIENTE+E1_LOJA+E1_NUM)
		cE1Num		:= (cAliasSE1)->E1_NUM
		cCliDest	:= (cAliasSE1)->E1_CLIENTE
		cLojDest	:= (cAliasSE1)->E1_LOJA

		IncProc()
		i++
		DbSelectArea(cAliasSE1)
		dbSkip()
	EndDo

	If !Empty(cE1CliNum)

		// Efetua envio do Boleto
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+cCliDest+cLojDest)
			// Verifica se o campo existe e se est� ativo o cliente para enviar o boleto
			If SA1->(FieldPos("A1_ZBLMAIL")) > 0 .And. SA1->A1_ZBLMAIL == "1"
				sfEnvioMail(sfObtEmail(cCliDest,cLojDest), aFilE1Cli,cE1Num)
			Endif
		Endif
		aFilE1Cli		:= {}
	Endif

	If _MV_PAR23 == 1 //Se for gera��o em tela
		oPrint:EndPage() //Finaliza a p�gina
		oPrint:Preview() //Visualiza antes de imprimir
	Endif

Return

/*/{Protheus.doc} Impress
Imprime a p�gina
@type function
@version  
@author Marcelo Alberto Lauschner
@since 10/06/2021
@param oPrint, object, param_description
@param aBitmap, array, param_description
@param aDadosEmp, array, param_description
@param aDadosTit, array, param_description
@param aDadosBanco, array, param_description
@param aDatPagador, array, param_description
@param aBolText, array, param_description
@param CB_RN_NN, character, param_description
@param cLocPagto, character, param_description
@param cValCIP, character, param_description
@param cEspecieD, character, param_description
@param cAceite, character, param_description
@return return_type, return_description
/*/
Static Function Impress(oPrint,aBitmap,aDadosEmp,aDadosTit,aDadosBanco,aDatPagador,aBolText,CB_RN_NN,cLocPagto,cValCIP,cEspecieD,cAceite)

	Local oFont8,nBol
	Local oFont10
	Local oFont16
	Local oFont16n
	Local oFont20
	Local oFont24
	Local i := 0
	Local aCoords1 := {150,1900,250,2300}   // FICHA DO PAGADOR
	Local aCoords2 := {420,1900,490,2300}   // FICHA DO PAGADOR
	Local aCoords3 := {1270,1900,1370,2300} // FICHA DO CAIXA
	Local aCoords4 := {1540,1900,1610,2300} // FICHA DO CAIXA
	Local aCoords5 := {2390,1900,2490,2300} // FICHA DE COMPENSACAO
	Local aCoords6 := {2660,1900,2730,2300} // FICHA DE COMPENSACAO
	Local oBrush


	//Parametros de TFont.New()
	//1.Nome da Fonte (Windows)
	//3.Tamanho em Pixels
	//5.Bold (T/F)
	oFont8  	:= TFont():New("Arial",9, 8,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont09 	:= TFont():New("Arial",9, 9,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10 	:= TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10n 	:= TFont():New("Arial",9,10,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14		:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14n	:= TFont():New("Arial",9,13,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont16 	:= TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n	:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont20		:= TFont():New("Arial",9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont20n	:= TFont():New("Arial",9,20,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont24 	:= TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)

	oBrush := TBrush():New("",4)

	oPrint:StartPage()   // Inicia uma nova pagina

	//UÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ficha do Caixa                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	o_Line (@oPrint,150,100,150,2300)
	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		o_SayBitMap(@oPrint,84-50,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
	Else
		o_Say  (@oPrint,84,100,aDadosBanco[2],oFont16 )  //Nome Banco
	Endif
	o_Say  (@oPrint,84,1850,"Comprovante de Entrega"                              ,oFont10)

	o_Line (@oPrint,250,100,250,1300 )
	o_Line (@oPrint,350,100,350,1300 )
	o_Line (@oPrint,420,100,420,2300 )
	o_Line (@oPrint,490,100,490,2300 )

	o_Line (@oPrint,350,400,420,400)
	o_Line (@oPrint,420,500,490,500)
	o_Line (@oPrint,350,725,420,725)
	o_Line (@oPrint,350,850,420,850)

	o_Line (@oPrint,150,1300,490,1300 )
	o_Line (@oPrint,150,2300,490,2300 )
	o_Say  (@oPrint,150,1310 ,"MOTIVOS DE NAO ENTREGA (para uso do entregador)"                             ,oFont8)
	o_Say  (@oPrint,200,1310 ,"|   | Mudou-se"                             ,oFont8)
	o_Say  (@oPrint,270,1310 ,"|   | Recusado"                             ,oFont8)
	o_Say  (@oPrint,340,1310 ,"|   | Desconhecido"                             ,oFont8)

	o_Say  (@oPrint,200,1580 ,"|   | Ausente"                             ,oFont8)
	o_Say  (@oPrint,270,1580 ,"|   | Nao Procurado"                             ,oFont8)
	o_Say  (@oPrint,340,1580 ,"|   | Endereco insuficiente"                             ,oFont8)

	o_Say  (@oPrint,200,1930 ,"|   | Nao existe o Numero"                             ,oFont8)
	o_Say  (@oPrint,270,1930 ,"|   | Falecido"                             ,oFont8)
	o_Say  (@oPrint,340,1930 ,"|   | Outros(anotar no verso)"                             ,oFont8)

	o_Say  (@oPrint,420,1310 ,"Recebi(emos) o bloqueto"                             ,oFont8)
	o_Say  (@oPrint,450,1310 ,"com os dados ao lado."                             ,oFont8)
	o_Line (@oPrint,420,1700,490,1700)
	o_Say  (@oPrint,420,1705 ,"Data"                             ,oFont8)
	o_Line (@oPrint,420,1900,490,1900)
	o_Say  (@oPrint,420,1905 ,"Assinatura"                             ,oFont8)

	o_Say  (@oPrint,150,100 ,"Beneficiario"            	,oFont8)

	// TSC679 - CHARLES REITZ - TRATAMENTO PARA O BANCO SOFISA E RED - 11/03/2020
	If Empty(SEE->EE_CTAOFI)
		o_Say  (@oPrint,150,300 ,aDadosEmp[6]         	,oFont10n)
		o_Say  (@oPrint,185,100 ,AllTrim(aDadosEmp[1])	,oFont10)
		o_Say  (@oPrint,220,100 ,aDadosEmp[2]+", "+aDadosEmp[3]+", "+aDadosEmp[4],oFont8)
	Else
		nRecA6	:= SA6->(recno()) // salva banco atual
		SA6->(msSeek(FWxFilial("SA6")+SEE->(EE_CODOFI+EE_AGEOFI+EE_CTAOFI) )) //A6_FILIAL, A6_COD, A6_AGENCIA, A6_NUMCON, R_E_C_N_O_, D_E_L_E_T_

		o_Say  (@oPrint,150,300 ,Transform(SA6->A6_CGC,"@R 99.999.999/9999-99")        	,oFont10n)
		o_Say  (@oPrint,185,100 ,CapitalACE(Alltrim(SA6->A6_NOME))	,oFont10)
		o_Say  (@oPrint,220,100 ,CapitalACE(Alltrim(SA6->A6_END))+", "+capitalACE(Alltrim(SA6->A6_BAIRRO))+", "+capitalACE(Alltrim(SA6->A6_MUN))+", "+Alltrim(SA6->A6_EST)+", "+Alltrim(SA6->A6_CEP),oFont8)

		SA6->(dbGOTO(nRecA6)) // restore do banco atual
	EndIf

	cIndTmp := At("-",aDatPagador[1])
	cCGCTmp := SubStr(aDatPagador[1], At("-", aDatPagador[1])+2, Len(aDatPagador[1]))
	cPagador := SubStr(aDatPagador[1],1, At("-", aDatPagador[1])-2)

	o_Say  (@oPrint,250,100 ,"Pagador"            	,oFont8)

	o_Say  (@oPrint,250,300 ,cCGCTmp		,oFont10n)
	o_Say  (@oPrint,290,100 ,cPagador    	,oFont10)

	o_Say  (@oPrint,350,100 ,"Data do Vencimento"                              ,oFont8)
	o_Say  (@oPrint,380,100 ,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10)

	o_Say  (@oPrint,350,405 ,"Nro.Documento"                                  ,oFont8)
	o_Say  (@oPrint,380,405 ,aDadosTit[1]+Iif(!Empty(aDadosTit[8]),"-"+aDadosTit[8],"")                         ,oFont10)

	o_Say  (@oPrint,350,730,"Moeda"                                           ,oFont8)
	If HSBC
		o_Say  (@oPrint,380,755,"REAL"                                   ,oFont10)
	Else
		o_Say  (@oPrint,380,755,GetMv("MV_SIMB1")                         ,oFont10)
	EndIf

	o_Say  (@oPrint,350,855,"Valor/Quantidade"                               ,oFont8)
	o_Say  (@oPrint,380,855,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)

	o_Say  (@oPrint,420,100 ,"Agencia/Codigo do Beneficiario"                      ,oFont8)
	If CAIXAEF   //LAIANA
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(Transform(SEE->EE_CODEMP,"@R 999999-9")),oFont10)
	ElseIf SANTANDER .OR. SOFISA
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf PINE
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"-"+Alltrim(SEE->EE_DVAGE)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf HSBC //LAIANA
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+" "+aDadosBanco[4]+aDadosBanco[5],oFont10)
	Elseif SICOOB   //LAIANA
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf SICREDI
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"."+Alltrim(SEE->EE_CODPROD)+"."+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf ITAU
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"/"+aDadosBanco[4]+"-"+aDadosBanco[5],oFont10)
	ElseIf BANRISUL
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf C6BANK
		o_Say  (@oPrint,450,100,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	Else
		o_Say  (@oPrint,450,100,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10)
	Endif
	o_Say  (@oPrint,420,505,"Nosso Numero"                                   ,oFont8)
	If BRADESCO
		o_Say  (@oPrint,450,505,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)        ,oFont10)
	ElseIf BB
		//o_Say  (@oPrint,450,520,Alltrim(Substr(aDadosTit[9],1,7))+aDadosTit[6],oFont10)
		o_Say  (@oPrint,450,505,Alltrim(Substr(aDadosTit[9],1,7))+SUBSTR(aDadosTit[6],1,10),oFont10)  //LAIANA
	ElseIf ITAU
		o_Say  (@oPrint,450,505,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6]))        ,oFont10)
	ElseIf CAIXAEF
		o_Say  (@oPrint,450,505,"14/0000"+substr(aDadosTit[6],1,13),oFont10) //laiana	
	ElseIf BANRISUL
		o_Say (@oPrint,450,505,aDadosTit[11],oFont10)
	ElseIf DAYCOVAL .OR. BANCOABC
		o_Say  (@oPrint,450,505,Alltrim(SEE->EE_AGENCIA)+Alltrim(SEE->EE_DVAGE)+"/"+Alltrim(SEE->EE_CARTEIR)+"/"+aDadosTit[6],oFont10)
	Elseif CECRED
		//NOSSO NUMERO = CONTA CORRENTE + DV COOPERADO +  NUMERO DO BOLETO E1_NUMBCO
		_cNossoNr := aDadosBanco[4] + aDadosBanco[5] + substr(aDadosTit[6],1,9)
		o_Say  (@oPrint,450,520,AllTrim(_cNossoNr),oFont10)
		//PINE
	Else
		o_Say  (@oPrint,450,505,aDadosTit[6],oFont10)
	EndIf

	For i := 100 to 2300 step 50
		o_Line( @oPrint,520, i, 520, i+30)
	Next i

	For i := 100 to 2300 step 50
		o_Line(@oPrint, 1080, i, 1080, i+30)
	Next i

	//UÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ficha do Pagador                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	o_Line (@oPrint,1270,100,1270,2300)
	o_Line (@oPrint,1270,650,1170,650 )
	o_Line (@oPrint,1270,900,1170,900 )
	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		o_SayBitMap(@oPrint,1204-50,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
	Else
		o_Say  (@oPrint,1204,100,aDadosBanco[2],oFont16 ) //Nome Banco (ou imagem)
	Endif
	If BRADESCO
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-2",oFont20 )
	ElseIf ITAU
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-7",oFont20 )
	ElseIf SAFRA
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-7",oFont20 )
	ElseIf HSBC
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-9",oFont20 )
	ElseIf SICOOB
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-0",oFont20 )
	ElseIf DAYCOVAL
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-2",oFont20 )
	ElseIf C6BANK
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-1",oFont20 )
	ElseIf SICREDI
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-X",oFont20 )
	ElseIf CAIXAEF
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20n )
	ElseIf BANRISUL
		o_Say (@oPrint,1182,680,aDadosBanco[1]+"-8",oFont20 )
	Else
		o_Say  (@oPrint,1182,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )
	EndIf

	o_Line (@oPrint,1370,100,1370,2300 )
	o_Line (@oPrint,1470,100,1470,2300 )
	o_Line (@oPrint,1540,100,1540,2300 )
	o_Line (@oPrint,1610,100,1610,2300 )

	o_Line (@oPrint,1470,500,1610,500)
	o_Line (@oPrint,1540,750,1610,750)
	o_Line (@oPrint,1470,1000,1610,1000)
	o_Line (@oPrint,1470,1350,1540,1350)
	o_Line (@oPrint,1470,1550,1610,1550)

	o_Say  (@oPrint,270,100 ,"Local de Pagamento"                             ,oFont8)
	o_Say  (@oPrint,1310,100 ,cLocPagto        ,oFont10)

	o_Say  (@oPrint,1270,1910,"Vencimento"                                     ,oFont8)

	//nFieldSize := CalcFieldSize("C",10,0,"@R XX/XX/XXXX","Vencimento",oFont10)
	o_Say  (@oPrint,1310,2090,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10,150,,1)

	o_Say  (@oPrint,1370,100 ,"Beneficiario"                                        ,oFont8)
	// TSC679 - CHARLES REITZ - TRATAMENTO PARA O BANCO SOFISA E RED - 11/03/2020
	If Empty(SEE->EE_CTAOFI)
		o_Say  (@oPrint,1405,100 ,AllTrim(aDadosEmp[1])+" - "+aDadosEmp[6]                                     ,oFont10)
		o_Say  (@oPrint,1440,100 ,aDadosEmp[2]+", "+aDadosEmp[3]+", "+aDadosEmp[4],oFont8)
	Else
		nRecA6	:= SA6->(recno()) // salva banco atual
		SA6->(msSeek(FWxFilial("SA6")+SEE->(EE_CODOFI+EE_AGEOFI+EE_CTAOFI) )) //A6_FILIAL, A6_COD, A6_AGENCIA, A6_NUMCON, R_E_C_N_O_, D_E_L_E_T_

		o_Say  (@oPrint,1405,100 ,CapitalACE(Alltrim(SA6->A6_NOME))	,oFont10)
		o_Say  (@oPrint,1440,100 ,CapitalACE(Alltrim(SA6->A6_END))+", "+capitalACE(Alltrim(SA6->A6_BAIRRO))+", "+capitalACE(Alltrim(SA6->A6_MUN))+", "+Alltrim(SA6->A6_EST)+", "+Alltrim(SA6->A6_CEP),oFont8)

		SA6->(dbGOTO(nRecA6)) // restore do banco atual
	EndIf

	o_Say  (@oPrint,1370,1910,"Agencia/Codigo do Beneficiario"                         ,oFont8)
	If SAFRA
		o_Say  (@oPrint,1410,2050,PadL(aDadosBanco[3],5,"0")+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,150,,1)
	Elseif CAIXAEF   //LAIANA
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(Transform(SEE->EE_CODEMP,"@R 999999-9")),oFont10,150,,1)
	Elseif SANTANDER .OR. SOFISA
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10,150,,1)
	ElseIf PINE
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"-"+Alltrim(SEE->EE_DVAGE)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf HSBC //LAIANA
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+" "+aDadosBanco[4]+aDadosBanco[5],oFont10,150,,1)
	Elseif SICOOB   //LAIANA
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10,150,,1)
	ElseIf SICREDI
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"."+Alltrim(SEE->EE_CODPROD)+"."+Alltrim(SEE->EE_CODEMP),oFont10,150,,1)
	ElseIf ITAU
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"/"+aDadosBanco[4]+"-"+aDadosBanco[5],oFont10)
	ElseIf BANRISUL
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf C6BANK
		o_Say  (@oPrint,1410,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	Else
		o_Say  (@oPrint,1410,2050,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,150,,1)
	Endif

	//o_Say(nLinha,2200,Transform(nValor,"@E 999,999.99"),oFont8,,,,0) // alinha a direita (default)

	o_Say  (@oPrint,1470,100 ,"Data do Documento"                              ,oFont8)
	o_Say  (@oPrint,1500,100 ,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4),oFont10)

	o_Say  (@oPrint,1470,505 ,"Nro.Documento"                                  ,oFont8)
	o_Say  (@oPrint,1500,505 ,aDadosTit[1]+Iif(!Empty(aDadosTit[8]),"-"+aDadosTit[8],"")                       ,oFont10)

	o_Say  (@oPrint,1470,1005,"Especie Doc."                                   ,oFont8)
	If HSBC
		o_Say  (@oPrint,1500,1155 ,"PD"                                   ,oFont10)
	ElseIf SICOOB
		o_Say  (@oPrint,1500,1155 ,"DM"		                                ,oFont10)
	ElseIf CAIXAEF
		o_Say  (@oPrint,1500,1155 ,"DMI"		                                ,oFont10)
	Else
		o_Say  (@oPrint,1500,1155,cEspecieD                                       ,oFont10)
	Endif
	o_Say  (@oPrint,1470,1355 ,"Aceite"                                         ,oFont8)
	If HSBC
		o_Say  (@oPrint,1500,1415 ,"NAO"		                                ,oFont10)
	ElseIf SICOOB
		o_Say  (@oPrint,1500,1415 ,"N"		                                ,oFont10)
	Else
		o_Say  (@oPrint,1500,1415,cAceite                                         ,oFont10)
	EndIf

	o_Say  (@oPrint,1470,1555,"Data do Processamento"                          ,oFont8)
	o_Say  (@oPrint,1500,1655,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4)                               ,oFont10)

	o_Say  (@oPrint,1470,1910,"Nosso Numero"                                   ,oFont8)
	If BRADESCO
		//o_Say  (@oPrint,1470,1910,"Cart / Nosso Numero"                                   ,oFont8)
		o_Say  (@oPrint,1500,2010,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)       ,oFont10,150,,1)
	ElseIf BB
		//o_Say  (@oPrint,1500,1930,Alltrim(Substr(aDadosTit[9],1,7))+aDadosTit[6],oFont10)
		o_Say  (@oPrint,1500,2010,Alltrim(Substr(aDadosTit[9],1,7))+SUBSTR(aDadosTit[6],1,10),oFont10,150,,1)  //LAIANA
	ElseIf ITAU
		o_Say  (@oPrint,1500,2010,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6]))        ,oFont10,150,,1)
	ElseIf CAIXAEF
		o_Say  (@oPrint,1500,1900,"14/0000"+substr(aDadosTit[6],1,13),oFont10,150,,1) //laiana
	ElseIf SICREDI
		o_Say  (@oPrint,1500,2010,SubStr(DTOS(aDadosTit[2]),3,2)+"/"+AllTrim(SEE->EE_BOLETO)+SubStr(AllTrim(aDadosTit[6]),1,5)+SubStr(AllTrim(aDadosTit[6]),6,2),oFont10,150,,1)
	ElseIf BANRISUL
		o_Say (@oPrint,1500,2010,aDadosTit[11],oFont10)
	Elseif CECRED
		//NOSSO NUMERO = CONTA CORRENTE + DV COOPERADO +  NUMERO DO BOLETO E1_NUMBCO
		o_Say  (@oPrint,1500,1930,ALLTRIM(_cNossoNr),oFont10)
		// PINE
	ElseIf DAYCOVAL .OR. BANCOABC
		o_Say  (@oPrint,1500,1930,Alltrim(SEE->EE_AGENCIA)+Alltrim(SEE->EE_DVAGE)+"/"+Alltrim(SEE->EE_CARTEIR)+"/"+aDadosTit[6],oFont10)
	Else
		o_Say  (@oPrint,1500,2010,aDadosTit[6],oFont10,150,,1)
	EndIf

	o_Say  (@oPrint,1540,100 ,"Uso do Banco"                                   ,oFont8)

	If !Empty(cValCIP)
		o_Line(@oPrint,1540,405,1610,405)
		o_Say(@oPrint,1540,410,"CIP")
		o_Say(@oPrint,1570,435,cValCIP,oFont10)
	EndIf

	o_Say  (@oPrint,1540,505 ,"Carteira"                                       ,oFont8)
	If HSBC
		o_Say  (@oPrint,1570,505 ,"CSB"                                   ,oFont10)
	ElseIf SICOOB
		o_Say  (@oPrint,1570,505 ,"1"                                   ,oFont10)
	ElseIf SICREDI
		o_Say  (@oPrint,1570,505 ,"11"                                   ,oFont10)
	Else
		o_Say  (@oPrint,1570,505 ,aDadosBanco[6]                                   ,oFont10)
	EndIf

	If CAIXAEF //LAIANA
		o_Say  (@oPrint,1540,755 ,"Moeda"                                        ,oFont8) //LAIANA
	Else //LAIANA
		o_Say  (@oPrint,1540,755 ,"Especie"                                        ,oFont8)
	Endif
	If HSBC
		o_Say  (@oPrint,1570,755 ,"REAL"		                                ,oFont10)
	Else
		o_Say  (@oPrint,1570,755 ,GetMv("MV_SIMB1")                                ,oFont10)
	EndIf

	o_Say  (@oPrint,1540,1005,"Quantidade"                                     ,oFont8)

	o_Say  (@oPrint,1540,1555,"Valor"                                          ,oFont8)

	o_Say  (@oPrint,1540,1910,"( = ) Valor do Documento"                          ,oFont8)
	o_Say  (@oPrint,1570,2170,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10,150,,1)

	o_Say  (@oPrint,1610,100 ,"Instrucoes (Texto de Responsabilidade do Beneficiario): ",oFont8)
	For nBol := 1 To 6
		If Len(aBolText) >= nBol
			o_Say  (@oPrint,1630+(40*nBol),100 ,aBolText[nBol],oFont09)
		Endif
	Next nBol

	o_Say  (@oPrint,1610,1910,"( - ) Desconto/Abatimento"                         ,oFont8)
	o_Say  (@oPrint,1680,1910,"( - ) Outras Deducoes"                             ,oFont8)
	o_Say  (@oPrint,1750,1910,"( + ) Mora/Multa/Juros "                           ,oFont8)
	o_Say  (@oPrint,1820,1910,"( + ) Outros Acrescimos"                           ,oFont8)
	o_Say  (@oPrint,1890,1910,"( = ) Valor Cobrado"                               ,oFont8)

	If SAFRA
		o_Say  (@oPrint,1960 ,100 ,"Sacador/Avalista:"                                         ,oFont8)
	ElseIF BANRISUL
		o_Say  (@oPrint,1960 ,100 ,"Pagador:"		                                           ,oFont8)
	Else
		o_Say  (@oPrint,1960 ,100 ,"Pagador/Avalista:"                                         ,oFont8)
		If !Empty(SEE->EE_CTAOFI)
			o_Say  (@oPrint,1960 ,280 ,CapitalACE(Alltrim(SM0->M0_NOMECOM)) + "CNPJ: "+ Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")+ " - "+AllTrim(SM0->M0_ENDCOB)+", "+AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB+", "+Transform(AllTrim(SM0->M0_CEPCOB),"99999-999")                                    ,oFont8)
		EndIf
	Endif


	o_Say  (@oPrint,1988 ,210 ,aDatPagador[1]+" ("+aDatPagador[2]+")"             ,oFont8)
	o_Say  (@oPrint,2030 ,210 ,aDatPagador[3]                                    ,oFont8)
	o_Say  (@oPrint,2070 ,210 ,aDatPagador[6]+"  "+aDatPagador[4]+" - "+aDatPagador[5] ,oFont8)

	//o_Say  (@oPrint,1925,100 ,"Pagador/Avalista"                               ,oFont8)
	//o_Say  (@oPrint,1925,100 ,"Sacador/Avalista"                               ,oFont8)
	o_Say  (@oPrint,2110,1500,"Autenticacao Mecanica "                        ,oFont8)
	If CAIXAEF  //LAIANA
		o_Say  (@oPrint,2150,100,"SAC CAIXA: 0800 726 0101 (informa��es, reclama��es, sugest�es e elogios). Para pessoas com defici�ncia auditiva ou de fala: 0800 726 2492."  ,oFont8) //LAIANA
		o_Say  (@oPrint,2190,100,"Ouvidoria: 0800 725 7474 (reclama��es n�o solucionadas e den�ncias). www.caixa.gov.br" ,oFont8) //LAIANA
	Endif  // LAIANA

	o_Say  (@oPrint,1204,1850,"Recibo do Pagador"                              ,oFont10)


	o_Line (@oPrint,1270,1900,1960,1900 )
	o_Line (@oPrint,1680,1900,1680,2300 )
	o_Line (@oPrint,1750,1900,1750,2300 )
	o_Line (@oPrint,1820,1900,1820,2300 )
	o_Line (@oPrint,1890,1900,1890,2300 )
	o_Line (@oPrint,1960,100 ,1960,2300 )

	o_Line (@oPrint,2105,100,2105,2300  )

	For i := 100 to 2300 step 50
		o_Line(@oPrint, 2270, i, 2270, i+30)
	Next i

	//UÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ficha de Compensacao                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	o_Line (@oPrint,2390,100,2390,2300)
	o_Line (@oPrint,2390,650,2290,650 )
	o_Line (@oPrint,2390,900,2290,900 )

	If File(Alltrim(aDadosBanco[1])+".bmp") //Verifica se existe imagem com o logo do banco -> A6_COD + ".bmp"
		o_SayBitMap(@oPrint,2324-50,100,Alltrim(aDadosBanco[1])+".bmp",332,82 )  //imagem
	Else
		o_Say  (@oPrint,2324,100,aDadosBanco[2],oFont16 )  //Nome do Banco
	Endif

	If BRADESCO
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-2",oFont20 )
	ElseIf ITAU
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-7",oFont20 )
	ElseIf SAFRA
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-7",oFont20 )
	ElseIf HSBC
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-9",oFont20 )
	ElseIf SICREDI
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-X",oFont20 )
	ElseIf DAYCOVAL
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-2",oFont20 )
	ElseIf C6BANK
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-1",oFont20 )
	ElseIf BANRISUL
		o_Say (@oPrint,2302,680,aDadosBanco[1]+"-8",oFont20 )
	ElseIf CAIXAEF
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20n )
	Else
		o_Say  (@oPrint,2302,680,aDadosBanco[1]+"-"+Modulo11(aDadosBanco[1],aDadosBanco[1]),oFont20 )
	EndIf
	o_Say  (@oPrint,2324,920,CB_RN_NN[2],oFont14n) //linha digitavel

	o_Line (@oPrint,2490,100,2490,2300 )
	o_Line (@oPrint,2590,100,2590,2300 )
	o_Line (@oPrint,2660,100,2660,2300 )
	o_Line (@oPrint,2730,100,2730,2300 )

	o_Line (@oPrint,2590,500,2730,500)
	o_Line (@oPrint,2660,750,2730,750)
	o_Line (@oPrint,2590,1000,2730,1000)
	o_Line (@oPrint,2590,1350,2660,1350)
	o_Line (@oPrint,2590,1550,2730,1550)

	o_Say  (@oPrint,2390,100 ,"Local de Pagamento"                             ,oFont8)
	o_Say  (@oPrint,2430,100 ,cLocPagto        ,oFont10)

	o_Say  (@oPrint,2390,1910,"Vencimento"                                     ,oFont8)
	o_Say  (@oPrint,2430,2090,Substr(DTOS(aDadosTit[4]),7,2)+"/"+Substr(DTOS(aDadosTit[4]),5,2)+"/"+Substr(DTOS(aDadosTit[4]),1,4),oFont10,150,,1)

	o_Say  (@oPrint,2490,100 ,"Beneficiario"                                        ,oFont8)
	// TSC679 - CHARLES REITZ - TRATAMENTO PARA O BANCO SOFISA E RED - 11/03/2020
	If Empty(SEE->EE_CTAOFI)
		o_Say  (@oPrint,2525,100 ,AllTrim(aDadosEmp[1])+" - "+aDadosEmp[6]                                     ,oFont10)
		o_Say  (@oPrint,2560,100 ,aDadosEmp[2]+", "+aDadosEmp[3]+", "+aDadosEmp[4],oFont8)
	Else
		nRecA6	:= SA6->(recno()) // salva banco atual
		SA6->(msSeek(FWxFilial("SA6")+SEE->(EE_CODOFI+EE_AGEOFI+EE_CTAOFI) )) //A6_FILIAL, A6_COD, A6_AGENCIA, A6_NUMCON, R_E_C_N_O_, D_E_L_E_T_

		o_Say  (@oPrint,2525,100 ,CapitalACE(Alltrim(SA6->A6_NOME))	,oFont10)
		o_Say  (@oPrint,2560,100 ,CapitalACE(Alltrim(SA6->A6_END))+", "+capitalACE(Alltrim(SA6->A6_BAIRRO))+", "+capitalACE(Alltrim(SA6->A6_MUN))+", "+Alltrim(SA6->A6_EST)+", "+Alltrim(SA6->A6_CEP),oFont8)

		SA6->(dbGOTO(nRecA6)) // restore do banco atual
	EndIf

	o_Say  (@oPrint,2490,1910,"Agencia/Codigo do Beneficiario"                         ,oFont8)
	If SAFRA
		o_Say  (@oPrint,2530,2050,PadL(aDadosBanco[3],5,"0")+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,150,,1)
	Elseif CAIXAEF   //LAIANA
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(Transform(SEE->EE_CODEMP,"@R 999999-9")),oFont10,150,,1)
	Elseif SANTANDER .OR. SOFISA
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10,150,,1)
	ElseIf PINE
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"-"+Alltrim(SEE->EE_DVAGE)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf HSBC //LAIANA
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+" "+aDadosBanco[4]+aDadosBanco[5],oFont10,150,,1)
	Elseif SICOOB   //LAIANA
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10,150,,1)
	ElseIf SICREDI
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"."+Alltrim(SEE->EE_CODPROD)+"."+Alltrim(SEE->EE_CODEMP),oFont10,150,,1)
	ElseIf ITAU
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"/"+aDadosBanco[4]+"-"+aDadosBanco[5],oFont10)
	ElseIf BANRISUL
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	ElseIf C6BANK
		o_Say  (@oPrint,2530,2050,Alltrim(SEE->EE_AGENCIA)+"/"+Alltrim(SEE->EE_CODEMP),oFont10)
	Else
		o_Say  (@oPrint,2530,2050,aDadosBanco[3]+"/"+aDadosBanco[4]+Iif(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""),oFont10,150,,1)
	Endif
	o_Say  (@oPrint,2590,100 ,"Data do Documento"                              ,oFont8)
	o_Say  (@oPrint,2620,100 ,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4),oFont10,150,,1)

	o_Say  (@oPrint,2590,505 ,"Nro.Documento"                                  ,oFont8)
	o_Say  (@oPrint,2620,505 ,aDadosTit[1]+Iif(!Empty(aDadosTit[8]),"-"+aDadosTit[8],"")                       ,oFont10)

	o_Say  (@oPrint,2590,1005,"Especie Doc."                                   ,oFont8)
	If HSBC
		o_Say  (@oPrint,2620,1155,"PD"                                            ,oFont10)
	ElseIf SICOOB
		o_Say  (@oPrint,2620,1155 ,"DM"		                                   ,oFont10)
	ElseIf CAIXAEF
		o_Say  (@oPrint,2620,1155 ,"DMI"		                                   ,oFont10)
	Else
		o_Say  (@oPrint,2620,1155,cEspecieD                                       ,oFont10)
	Endif

	o_Say  (@oPrint,2590,1355 ,"Aceite"                                         ,oFont8)

	If HSBC
		o_Say  (@oPrint,2620,1415 ,"NAO"		                                    ,oFont10)
	ElseIf SICOOB
		o_Say  (@oPrint,2620,1415 ,"N"		                                ,oFont10)
	Else
		o_Say  (@oPrint,2620,1415,cAceite                                          ,oFont10)
	EndIf

	o_Say  (@oPrint,2590,1555,"Data do Processamento"                          ,oFont8)
	o_Say  (@oPrint,2620,1655,Substr(DTOS(aDadosTit[2]),7,2)+"/"+Substr(DTOS(aDadosTit[2]),5,2)+"/"+Substr(DTOS(aDadosTit[2]),1,4)                               ,oFont10)

	o_Say  (@oPrint,2590,1910,"Nosso Numero"                                   ,oFont8)
	If BRADESCO
		o_Say  (@oPrint,2620,2010,aDadosBanco[6]+"/"+SubStr(aDadosTit[6], Len(aDadosTit[6])-12, 13)        ,oFont10,150,,1)
	ElseIf BB
		//o_Say  (@oPrint,2620,1930,Alltrim(Substr(aDadosTit[9],1,7))+aDadosTit[6],oFont10)
		o_Say  (@oPrint,2620,2010,Alltrim(Substr(aDadosTit[9],1,7))+SUBSTR(aDadosTit[6],1,10),oFont10,150,,1)  //LAIANA
	ElseIf ITAU
		o_Say  (@oPrint,2620,2010,aDadosBanco[6]+"/"+substr(aDadosTit[6],1,len(aDadosTit[6]))        ,oFont10,150,,1)
	ElseIf CAIXAEF
		o_Say  (@oPrint,2620,1900,"14/0000"+substr(aDadosTit[6],1,13),oFont10,150,,1) //laiana
	ElseIf SICREDI
		o_Say  (@oPrint,2620,2010,SubStr(DTOS(aDadosTit[2]),3,2)+"/"+AllTrim(SEE->EE_BOLETO)+SubStr(AllTrim(aDadosTit[6]),1,5)+SubStr(AllTrim(aDadosTit[6]),6,2),oFont10,150,,1)
	ElseIf BANRISUL
		o_Say (@oPrint,2620,1910,aDadosTit[11],oFont10)
	Elseif CECRED

		//NOSSO NUMERO = CONTA CORRENTE + DV COOPERADO +  NUMERO DO BOLETO E1_NUMBCO
		o_Say  (@oPrint,2620,1930,ALLTRIM(_cNossoNr),oFont10)
	ElseIf DAYCOVAL .OR. BANCOABC
		o_Say  (@oPrint,2620,1930,Alltrim(SEE->EE_AGENCIA)+Alltrim(SEE->EE_DVAGE)+"/"+Alltrim(SEE->EE_CARTEIR)+"/"+aDadosTit[6],oFont10)
	Else
		o_Say  (@oPrint,2620,2010,aDadosTit[6],oFont10,150,,1)
	EndIf

	o_Say  (@oPrint,2660,100 ,"Uso do Banco"                                   ,oFont8)

	If !Empty(cValCIP)
		o_Line(@oPrint,2660,405,2730,405)
		o_Say(@oPrint,2660,410,"CIP")
		o_Say(@oPrint,2690,435,cValCIP,oFont10)
	EndIf

	o_Say  (@oPrint,2660,505 ,"Carteira"                                       ,oFont8)
	If HSBC
		o_Say  (@oPrint,2690,505 ,"CSB"                                   	,oFont10)
	ElseIf SICOOB
		o_Say  (@oPrint,2690,505 ,"1"                                   ,oFont10)
	ElseIf SICREDI
		o_Say  (@oPrint,2690,505 ,"11"                                   ,oFont10)
	Else
		o_Say  (@oPrint,2690,505 ,aDadosBanco[6]                                   ,oFont10)
	EndIf

	If CAIXAEF //LAIANA
		o_Say  (@oPrint,2660,755 ,"Moeda"                                        ,oFont8)    //LAIANA
	Else     //LAIANA
		o_Say  (@oPrint,2660,755 ,"Especie"                                        ,oFont8)
	Endif
	If HSBC
		o_Say  (@oPrint,2690,755 ,"REAL"		                                ,oFont10)
	Else
		o_Say  (@oPrint,2690,755 ,GetMv("MV_SIMB1")                                ,oFont10)
	EndIf

	o_Say  (@oPrint,2660,1005,"Quantidade"                                     ,oFont8)

	o_Say  (@oPrint,2660,1555,"Valor"                                          ,oFont8)

	o_Say  (@oPrint,2660,1910,"( = ) Valor do Documento"                          ,oFont8)
	o_Say  (@oPrint,2690,2170,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10,150,,1)

	o_Say  (@oPrint,2730,100 ,"Instrucoes (Texto de Responsabilidade do Beneficiario): ",oFont8)


	For nBol := 1 To 6
		If Len(aBolText) >= nBol
			o_Say  (@oPrint,2750+(40*nBol),100 ,aBolText[nBol],oFont09)
		Endif
	Next nBol

	//o_Say  (@oPrint,2800,100 ,"Cod.Barras: "+CB_RN_NN[1],oFont09) // WALTER

	If CAIXAEF   //LAIANA
		o_Say  (@oPrint,2730,1910,"( - ) Desconto"			                         	,oFont8)
	else
		o_Say  (@oPrint,2730,1910,"( - ) Desconto/Abatimento"                         	,oFont8)
	Endif
	If CAIXAEF
		o_Say  (@oPrint,2800,1910,"( - ) Outras Deducoes/Abatimentos"                 	,oFont8)
	else
		o_Say  (@oPrint,2800,1910,"( - ) Outras Deducoes"                             	,oFont8)
	Endif        //LAIANA

	o_Say  (@oPrint,2870,1910,"( + ) Mora/Multa/Juros "                           	,oFont8)
	o_Say  (@oPrint,2940,1910,"( + ) Outros Acrescimos"                           	,oFont8)
	o_Say  (@oPrint,3010,1910,"( = ) Valor Cobrado"                               	,oFont8)

	o_Say  (@oPrint,3080,100 ,"Pagador"                                        	,oFont8)

	o_Say  (@oPrint,3108,210 ,aDatPagador[1]+" ("+aDatPagador[2]+")"             	,oFont8)
	o_Say  (@oPrint,3148,210 ,aDatPagador[3]                                   	,oFont8)
	o_Say  (@oPrint,3188,210 ,aDatPagador[6]+"  "+aDatPagador[4]+" - "+aDatPagador[5]	,oFont8)

	If SAFRA
		o_Say  (@oPrint,3228,100 ,"Sacador/Avalista"                               	,oFont8)
	ElseIf BANRISUL
		o_Say  (@oPrint,3228,100 ,"Pagador"                                      	,oFont8)
	Else
		o_Say  (@oPrint,3228,100 ,"Pagador/Avalista"                               	,oFont8)
		If !Empty(SEE->EE_CTAOFI)
			o_Say  (@oPrint,3228 ,280 ,CapitalACE(Alltrim(SM0->M0_NOMECOM)) + "CNPJ: "+ Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")+ " - "+AllTrim(SM0->M0_ENDCOB)+", "+AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB+", "+Transform(AllTrim(SM0->M0_CEPCOB),"99999-999")                                    ,oFont8)
		EndIf
	Endif

	o_Say  (@oPrint,3270,1500,"Autenticacao Mecanica"                           	,oFont8)
	o_Say  (@oPrint,3270,1850,"Ficha de Compensacao"                           	,oFont10)


	o_Line(@oPrint,2390,1900,3080,1900)
	o_Line(@oPrint,2800,1900,2800,2300)
	o_Line(@oPrint,2870,1900,2870,2300)
	o_Line(@oPrint,2940,1900,2940,2300)
	o_Line(@oPrint,3010,1900,3010,2300)
	o_Line(@oPrint,3080,100 ,3080,2300)

	o_Line (@oPrint,3265,100,3265,2300)

	If _MV_PAR23 == 1 //Se for imprimir em tela
		MSBAR("INT25"  ,27.9,1.3,CB_RN_NN[1],oPrint,.F.,,,0.025,1.3,,,,.F.)
	Else
		nPosicao := 3285/1.2 //788
		nColBar  := 150 //30
		nWidth   := 0.80
		nHeigth  := 36
		oPrint:Int25(nPosicao,nColBar,CB_RN_NN[1],nWidth,nHeigth,.F.,.F.)
	Endif



	oPrint:EndPage() // Finaliza a pagina

Return Nil

//------------------------------------------------------------------------------------
// Calcula modulo 10 
//------------------------------------------------------------------------------------
Static Function Modulo10(cData)

	Local L,D,P	:= 0
	Local B    	:= .F.

	L := Len(cData)
	B := .T.
	D := 0

	While L > 0
		P := Val(SubStr(cData, L, 1))
		If (B)
			P := P * 2
			If P > 9
				P := P - 9
			End
		End
		D := D + P
		L := L - 1
		B := !B
	End

	D := 10 - (Mod(D,10))

	If D = 10
		D := 0
	End

Return(D)

//------------------------------------------------------------------------------------
// Calcula modulo 11 
//------------------------------------------------------------------------------------
Static Function Modulo11(cData,cBanc,cCarteira,cBanDIGVC)

	Local L, D, P, X := 0, nH
	Local aPeso := {}
	Local nCnt  := 0
	Private nBase
	Default cBanc = ""
	Default cBanDIGVC	:= ""


	If cBanc == "001" //Banco do Brasil
		L := Len(cdata)
		D  := 0
		DS := 0
		P := 6
		X := 0
		for X=1 to L
			P := P + 1
			if P = 10
				P := 2
			end

			DS := DS + (Val(SubStr(cData, X, 1)) * P)
			//L := L - 1
		next

		D := int( (DS / 11) )
		D := DS - (D * 11)

		If D == 10
			D := "X"
		Else
			D := AllTrim(Str(D))
		End

	ElseIf cBanc == "237" //Bradesco

		nSoma1 := val(subs(cCarteira,01,1))*2
		nSoma2 := val(subs(cCarteira,02,1))*7
		nSoma3 := val(subs(cData,01,1))   *6
		nSoma4 := val(subs(cData,02,1))   *5
		nSoma5 := val(subs(cData,03,1))   *4
		nSoma6 := val(subs(cData,04,1))   *3
		nSoma7 := val(subs(cData,05,1))   *2
		nSoma8 := val(subs(cData,06,1))   *7
		nSoma9 := val(subs(cData,07,1))   *6
		nSomaA := val(subs(cData,08,1))   *5
		nSomaB := val(subs(cData,09,1))   *4
		nSomaC := val(subs(cData,10,1))   *3
		nSomaD := val(subs(cData,11,1))   *2

		cDigito := mod(nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8+nSoma9+nSomaA+nSomaB+nSomaC+nSomaD,11)

		D := iif(cDigito == 1, "P", iif(cDigito == 0 , "0", strzero(11-cDigito,1)))

	ElseIf cBanc == "336" //C6BANK

		nSoma1 := val(subs(cCarteira,01,1))*7
		nSoma2 := val(subs(cCarteira,02,1))*6
		nSoma3 := val(subs(cData,01,1))   *5
		nSoma4 := val(subs(cData,02,1))   *4
		nSoma5 := val(subs(cData,03,1))   *3
		nSoma6 := val(subs(cData,04,1))   *2
		nSoma7 := val(subs(cData,05,1))   *7
		nSoma8 := val(subs(cData,06,1))   *6
		nSoma9 := val(subs(cData,07,1))   *5
		nSomaA := val(subs(cData,08,1))   *4
		nSomaB := val(subs(cData,09,1))   *3
		nSomaC := val(subs(cData,10,1))   *2

		cDigito := mod(nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8+nSoma9+nSomaA+nSomaB+nSomaC,11)

		D := iif(cDigito == 1, "P", iif(cDigito == 0 , "0", strzero(11-cDigito,1)))

	ElseIf cBanc == "422" //.Or. cBanc == "104" //SAFRA ou CAIXA (CEF) // RETIRADO WALTER TSC022 13/07/2016

		nCnt	:= 0
		cDigito:= 0
		nSoma	:= 0
		nBase	:= 0
		aPeso	:= {9,8,7,6,5,4,3,2};

		nBase := Len(aPeso)+1

		FOR nCnt := Len(cData) TO 1 STEP -1
			nBase := IF(--nBase = 0,Len(aPeso),nBase)
			nSoma += Val(SUBS(cData,nCnt,01)) * aPeso[nBase]
		NEXT

		nResto	:= (nSoma % 11)

		//CARLOS - Regra de exce��o do digito modulo 11
		If nResto == 0 .Or. nResto == 1 .Or. nResto == 10
			cDigito := 1
		Else
			cDigito := 11 - nResto
		EndIf

		D := cDigito

	ElseIf cBanc == "341" //ITAU
		L := Len(cdata)
		D := 0
		C := 0

		D1 := Space(1)
		D2 := Space(1)
		_X1:= 0

		P := "12121212121212121212" // Constante Conforme Manual Itau
		While L > 0
			C := (Val(SubStr(cData, L, 1)) * Val(SubStr(P, L, 1)))
			If C > 9
				_X1 := StrZero(C,2)
				D1 := SubStr(_X1,1,1)
				D2 := SubStr(_X1,2,1)
				D  := D + (Val(D1) + Val(D2))
			Else
				D := D + (Val(SubStr(cData, L, 1)) * Val(SubStr(P, L, 1)))
			EndIf
			L := L - 1
		End

		D := Mod(D,10)
		D := 10 - D
		If D == 10
			D := 0
		Else
			D := AllTrim(Str(D))
		EndIf

		//ElseIf cBanc == "341" .Or. cBanc == "655" //ITAU ou VOTORANTIM
	ElseIf cBanc == "655"

		nCnt	:= 0
		cDigito:= 0
		nSoma	:= 0
		nBase	:= 0
		aPeso	:= {9,8,7,6,5,4,3,2};

		nBase := Len(aPeso)+1

		FOR nCnt := Len(cData) TO 1 STEP -1
			nBase := IF(--nBase = 0,Len(aPeso),nBase)
			nSoma += Val(SUBS(cData,nCnt,01)) * aPeso[nBase]
		NEXT

		cDigito := 11 - (nSoma % 11)

		DO CASE
		CASE cDigito = 0
			cDigito := "1"
		CASE cDigito > 9
			cDigito := "1"
		OTHERWISE
			cDigito := STR( cDigito, 1, 0 )
		ENDCASE

		D := cDigito

	ElseIf cBanc == "479"
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			If P = 9
				P := 1
			End
			L := L - 1
		End
		D := Mod(D*10,11)
		If D == 10
			D := 0
		End
		D := AllTrim(Str(D))

	ElseIf cBanc == "399" //HSBC
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			If P = 7
				P := 1
			End
			L := L - 1
		End
		D := Mod(D,11)
		If D == 0 .Or. D == 1
			D := 0
			D := AllTrim(Str(D))
		Else
			D := 11 - D
			D := AllTrim(Str(D))
		EndIf

	ElseIf cBanc == "104" //CEF WALTER TSC022 13/07/2016
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			If P = 9
				P := 1
			EndIf
			L := L - 1
		End
		D := Mod(D,11)
		D := 11 - D
		If D > 9
			D := 0
		EndIf
		D := AllTrim(Str(D))

	ElseIf cBanc == "756" //SICOOB
		L := Len(cdata)
		D := 0
		P := "319731973197319731973" // Constante Conforme Manual Sicoob
		While L > 0
			D := D + (Val(SubStr(cData, L, 1)) * Val(SubStr(P, L, 1)))
			L := L - 1
		End
		D  := Mod(D,11)
		If D == 0 .Or. D == 1
			D := 0
		Else
			D := 11 - D
		Endif
		D := AllTrim(Str(D))

	ElseIf cBanc == "748" //SICREDI TSCC47 Arthur Voltolini 
		L := Len(cdata)
		D := 0
		If Len(cdata) == 24
			P := "987654329876543298765432" // Constante Conforme Manual Sicredi
			While L > 0
				D := D + (Val(SubStr(cData, L, 1)) * Val(SubStr(P, L, 1)))
				L := L - 1
			End
			D  := Mod(D,11)
			If D == 0 .Or. D == 1
				D := 0
			Else
				D := 11 - D
			Endif
			D := AllTrim(Str(D))
		ElseIf Len(cdata) == 19
			P := "4329876543298765432"
			While L > 0
				D := D + (Val(SubStr(cData, L, 1)) * Val(SubStr(P, L, 1)))
				L := L - 1
			End
			D  := Mod(D,11)
			D := 11 - D
			If D == 10 .Or. D == 11
				D := 0
			EndIf
			D := AllTrim(Str(D))
		EndIf
	ElseIf cBanc == "033" .OR. cBanc == "637"
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			If P = 9
				P := 1
			End
			L := L - 1
		End
		R := (mod(D,11))
		Do Case
		Case R == 10
			D := 1
		Case R == 0
			D := 0
		Case R == 1
			D := 0
		OtherWise
			D := (11 - R )
		EndCase
		D := AllTrim(Str(D))

	ElseIf cBanc == "041"
		nCnt	:= 0
		cDigito := 0
		nSoma	:= 0
		nBase	:= 0
		cMod10  := ''
		aPeso	:= {4,3,2,7,6,5,4,3,2}
		nPeso   := 2

		nBase := Len(aPeso)+1
		If len(cData) < 24
			cMod10:= Str( Modulo10(cData), 1, 0 )
			cData := cData+cMod10
		Else
			cMod10:= Substr(cData, Len(cData), 1)
		EndIf

		nPos := len(cData)
		FOR nCnt := 1 to Len(cData)
			nSoma += Val(SUBS(cData,nPos,1)) * nPeso
			nPeso ++
			If nPeso > 7
				nPeso := 2
			EndIf
			nPos --
		NEXT

		If nSoma < 11
			cDigito := 11 - nSoma
		Else
			cDigito := 11 - (nSoma % 11)  // cDigito = RESTO
			If cDigito = 11 // Se resto igual a zero digito fica igual a zero
				cDigito := 0
			ElseIF cDigito = 10  //Se resto igual a 1 tem que recalcular os valores dos digitos
				cDigito := 10
			EndIf
		EndIf

		DO CASE
		CASE cDigito = 10
			cNC01   := Substr(cData, Len(cData), 1)
			cNC01   := IIF( Val(cNC01)+1 >= 10, '0',  Str( Val(cNC01)+1, 1, 0 ) )
			cData := substr(cData,1,Len(cData)-1) + cNC01
			cDigito := Modulo11( cData, '041' )[2]    // deve processar novamente, acrescentando +1 no 1Â° NC
		OTHERWISE
			cDigito := STR( cDigito, 1, 0 )
		ENDCASE

		D := {cMod10,AllTrim(cDigito)}

	ElseIf cBanc == "085" //CECRED  THIAGO - TSC959

		nSoma1	:= val(subs(cData,1,1))	*	4
		nSoma2	:= val(subs(cData,2,1))	*	3
		nSoma3	:= val(subs(cData,3,1))	*	2
		nSoma4	:= val(subs(cData,4,1))	*	9
		nSoma5	:= val(subs(cData,5,1))	*	8
		nSoma6	:= val(subs(cData,6,1))	*	7
		nSoma7	:= val(subs(cData,7,1))	*	6
		nSoma8	:= val(subs(cData,8,1))	*	5
		nSoma9	:= val(subs(cData,9,1))	*	4
		nSoma10	:= val(subs(cData,10,1))*	3
		nSoma11	:= val(subs(cData,11,1))*	2
		nSoma12	:= val(subs(cData,12,1))*	9
		nSoma13	:= val(subs(cData,13,1))*	8
		nSoma14	:= val(subs(cData,14,1))*	7
		nSoma15	:= val(subs(cData,15,1))*	6
		nSoma16	:= val(subs(cData,16,1))*	5
		nSoma17	:= val(subs(cData,17,1))*	4
		nSoma18	:= val(subs(cData,18,1))*	3
		nSoma19	:= val(subs(cData,19,1))*	2
		nSoma20	:= val(subs(cData,20,1))*	9
		nSoma21	:= val(subs(cData,21,1))*	8
		nSoma22	:= val(subs(cData,22,1))*	7
		nSoma23	:= val(subs(cData,23,1))*	6
		nSoma24	:= val(subs(cData,24,1))*	5
		nSoma25	:= val(subs(cData,25,1))*	4
		nSoma26	:= val(subs(cData,26,1))*	3
		nSoma27	:= val(subs(cData,27,1))*	2
		nSoma28	:= val(subs(cData,28,1))*	9
		nSoma29	:= val(subs(cData,29,1))*	8
		nSoma30	:= val(subs(cData,30,1))*	7
		nSoma31	:= val(subs(cData,31,1))*	6
		nSoma32	:= val(subs(cData,32,1))*	5
		nSoma33	:= val(subs(cData,33,1))*	4
		nSoma34	:= val(subs(cData,34,1))*	3
		nSoma35	:= val(subs(cData,35,1))*	2
		nSoma36	:= val(subs(cData,36,1))*	9
		nSoma37	:= val(subs(cData,37,1))*	8
		nSoma38	:= val(subs(cData,38,1))*	7
		nSoma39	:= val(subs(cData,39,1))*	6
		nSoma40	:= val(subs(cData,40,1))*	5
		nSoma41	:= val(subs(cData,41,1))*	4
		nSoma42	:= val(subs(cData,42,1))*	3
		nSoma43	:= val(subs(cData,43,1))*	2

		cDigito := mod(nSoma1+nSoma2+nSoma3+nSoma4+nSoma5+nSoma6+nSoma7+nSoma8+nSoma9+nSoma10+nSoma11+nSoma12+nSoma13+nSoma14+nSoma15+nSoma16+nSoma17+nSoma18+nSoma19+nSoma20+nSoma21+nSoma22+nSoma23+nSoma24+nSoma25+nSoma26+nSoma27+nSoma28+nSoma29+nSoma30+nSoma31+nSoma32+nSoma33+nSoma34+nSoma35+nSoma36+nSoma37+nSoma38+nSoma39+nSoma40+nSoma41+nSoma42+nSoma43,11)

		if cDigito <= 1 .OR.  cDigito >= 10
			D:= 1
		ELSE
			D:= 11 - cDigito
		ENDIF

		D := AllTrim(Str(D))
		//BANCO PINE - DAYCOVAL - BANCO ABC - SAUDO NO CALCULO DO MODULO 11 PARA O NOSSO NUMERO
	elseIF cBanc == "643" .OR.  cBanc == "707" .OR.  cBanc == "246"
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P += 1
			nSumD := Val(SubStr(cData, L, 1)) * P
			If nSumD  > 9
				cValX	:=	Alltrim(Str(nSumD))
				For nH := 1 To Len(cValX)
					D += Val(SubStr(cValX, nH, 1))
				Next
			Else
				D += nSumD
			EndIf
			If P = 2
				P := 0
			End
			L -= 1
		End
		nRetDiv	:=	int(mod(D,10))
		If nRetDiv == 0
			D := nRetDiv
		else
			D := 10 - nRetDiv
		EndIF
		D := cValTochar(D)
	Else
		L := Len(cdata)
		D := 0
		P := 1
		While L > 0
			P := P + 1
			D := D + (Val(SubStr(cData, L, 1)) * P)
			If P = 9
				P := 1
			End
			L := L - 1
		End
		nRest	 :=  mod(D,11)
		D := 11 - nRest
		If cBanc == "SANTANDER" .OR. cBanc == "SOFISA" //.Or. cBanc == "CAIXA"
			IF (D == 0 .Or. D == 1 .Or. D == 10 .Or. D == 11)
				D := 1
			End
			// pine
		ElseIf cBanDIGVC == "643" .OR. cBanDIGVC == "246" // PINE - BANCO ABC
			IF (nRest == 0 .Or. nRest == 1 .Or. nRest == 10)
				D := 1
			End
			// banco daycoval

		ElseIf cBanDIGVC == "707"
			IF (nRest == 0 .Or. nRest == 1 )
				D := 1
			End
		Else
			If (D == 10 .Or. D == 11)
				D := 1
			End
		Endif
		D := AllTrim(Str(D))
	Endif

Return D

//------------------------------------------------------------------------------------
// Calcula modulo 11 base 7 
//------------------------------------------------------------------------------------
Static Function Mod11B7(cData,cBanc)

	Local L, D, P, X := 0, nH
	Local aPeso := {}
	Local nCnt  := 0
	Private nBase

//------------------------------------------------------------------------------------
//Retorna os strings para inpressao do Boleto
//CB = String para o cod.barras, RN = String com o numero digitavel
//Cobranca nao identificada, numero do boleto = Titulo + Parcela
//------------------------------------------------------------------------------------
Static Function Ret_cBarra(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,cCarBank)

	Local cCodEmp 		:= IIf(SubStr(cBanco,1,3)=="399",AllTrim(cConvenio),StrZero(Val(SubStr(cConvenio,1,7)),7))
	Local cNumSeq 		:= Strzero(val(cSequencial),nTam_NN)
	Local bldocnufinal 	:= Strzero(val(cNroDoc),9)
	Local blvalorfinal 	:= Strzero(Round(nValor,2)*100,10) //strzero(int(nValor*100),10)
	Local cNNumSDig 	:= cCpoLivre := cCBSemDig := cCodBarra := cNNum := cFatVenc := ''
	Local cDvn          := " "
	Local dDataReset := CtoD("22/02/2025")

	//Fator Vencimento - POSICAO DE 06 A 090

	If dVencimento < dDataReset
		cFatVenc := STRZERO(dvencimento - CtoD("07/10/1997"),4)
	Else
        // Calcula o fator ap�s o reset
        cFatVenc := STRZERO(1000 + (dvencimento - CtoD("22/02/2025")),4)	
	EndIf
	
	//Prefixo Nosso Numero
	//Nosso Numero
	cNNum := cNumSeq

	//Campo Livre (Definir campo livre com cada banco)
	If Substr(cBanco,1,3) == "001" //BB
		cCpoLivre := StrZero(0,6) + cCodEmp + cNumSeq + PadR(cCarBank,2) //cCarBank -> Carteira
		//cDvn := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)+cCarBank+cNumSeq))
		cDvn := cValToChar(Modulo11((AllTrim(cConvenio)+cNumSeq),SubStr(cBanco,1,3),cCarteira) )
		//6 + 7 + 10 + 2 = 25

	ElseIf Substr(cBanco,1,3) == "399" // HSBC
		_NumHSBC := cNumSeq //AllTrim(cCodEmp) + cNumSeq
		cDvn := Modulo11(_NumHSBC,SubStr(cBanco,1,3))
		cCpoLivre := _NumHSBC + cDvn + SubStr(aDadosBanco[3],1,4) + aDadosBanco[4] + aDadosBanco[5] + cCarteira + "1"
		// 			2169300009  1	   AGENCIA                      CONTA            DIG.CONTA

	ElseIf SubStr(cBanco,1,3) == "756" // SICOOB
		_NumSICOOB := AllTrim(cAgencia) + StrZero(Val(AllTrim(cCodEmp)),10) + AllTrim(cNumSeq) // WALTER 08/09/2016
		//cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3),cCarteira) //LAIANA

		_Parc     := IIF(Empty((caliasSE1)->E1_PARCELA),"001",STRZERO(VAL((caliasSE1)->E1_PARCELA),3)) // WALTER 11/04/2018

		cDvn      := modulo11(_NumSICOOB,SubStr(cBanco,1,3)) // WALTER 08/09/2016
		cCpoLivre := cCarteira + AllTrim(cAgencia) + ALLTRIM(SEE->EE_CODCART) + StrZero(Val(AllTrim(cCodEmp)),7) + AllTrim(cNumSeq) + cDvn + _Parc  //LAIANA
		//1 3084 01 0222372
		
	ElseIf SubStr(cBanco,1,3) == "748" // SICREDI
		//_NumSICREDI := AllTrim(cAgencia) + AllTrim(cA6_POS)+ AllTrim(cConvenio) + SUBSTR(DTOS(SE1->E1_EMISSAO),3,2) + "2" + AllTrim(cNumSeq)
		_NumSICREDI := AllTrim(cAgencia) + AllTrim(cA6_POS)+ AllTrim(cConvenio) + SUBSTR(DTOS(dvencimento),3,2) + "2" + AllTrim(cNumSeq)
		cDvn        := cValToChar(Modulo11(_NumSICREDI,SubStr(cBanco,1,3)))
		//cCpoLivreP  := "1" + "1" + SUBSTR(DTOS(SE1->E1_EMISSAO),3,2) + "2" +AllTrim(cNumSeq) + cDvn + AllTrim(cAgencia) + AllTrim(cA6_POS) + AllTrim(cConvenio) + "1" + "0"
		cCpoLivreP  := "1" + "1" + SUBSTR(DTOS(dvencimento),3,2) + "2" +AllTrim(cNumSeq) + cDvn + AllTrim(cAgencia) + AllTrim(cA6_POS) + AllTrim(cConvenio) + "1" + "0"
		cDvC        := cValToChar(modulo11(cCpoLivreP,SubStr(cBanco,1,3)))
		cCpoLivre   := cCpoLivreP + cDvC		
	ElseIf Substr(cBanco,1,3) == "237" //BRADESCO
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3),cCarteira)
		cCpoLivre := StrZero(Val(cAgencia),4) + cCarteira + cNumSeq + StrZero(Val(cConta),7) + "0"
		//4 + 2 + 11 + 8 = 25

	ElseIf Substr(cBanco,1,3) == "336" //C6BANK
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3),cCarteira)
		cCpoLivre := cConvenio + AllTrim(cNumSeq) + cCarteira + "4"
		//12 + 10 + 2 + 1 = 25

	ElseIf SubStr(cBanco,1,3) $ "341/655" //ITAU ou VOTORANTIM
		//cDvn := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)+cCarBank+cNumSeq)) // COMENTADO WALTER 30/11/16
		_NumItau := AllTrim(cAgencia)+AllTrim(cConta)+ALLTRIM(SEE->EE_CARTEIR)+AllTrim(cNumSeq)
		cDvn      := cValToChar(Modulo11(_NumItau,SubStr(cBanco,1,3),ALLTRIM(SEE->EE_CARTEIR)))
		//cCpoLivre := ALLTRIM(SEE->EE_CARTEIR) + _NumItau + cDvn + AllTrim(cAgencia) + AllTrim(cConta) + aDadosBanco[5] + "000"
		cDvC := cValToChar(Modulo10(AllTrim(cAgencia)+AllTrim(cConta)))
		cCpoLivre := Alltrim(cCarBank) + cNumSeq + cDvn + strzero(val(cAgencia),4)+AllTrim(cConta)+cDvC+"000"
		//2 + 8 + 1 + 4 + 10 = 25
	ElseIf SubStr(cBanco,1,3) == "422" //SAFRA
		//cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		//cCpoLivre := "7" + PadL( Strzero(Val(cAgencia),5)+ PadL(AllTrim(cConta)+cDacCC,9,"0") , 14 ) + cNumSeq + cDvn + "2"
		//cCpoLivre := StrTran(cCpoLivre," ","0")
		cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3),.F.)
		cCpoLivre := "70" + cAgencia + AllTrim(cConta) + ALLTRIM(SEE->EE_DVCTA) + cNumSeq + cValToChar(cDvn) + "2"
		cCpoLivre := StrTran(cCpoLivre," ","0")
		//1 + 14 + 8 + 2 = 25
	ElseIf SubStr(cBanco,1,3) == "033" .OR.  SubStr(cBanco,1,3) == "637"//SANTANDER e SOFISA
		If Empty(SEE->EE_CTAOFI)
			_NumSant := "00000"+AllTrim(right(cNumSeq,7))
			cDvn := modulo11("0000"+_NumSant,SubStr(cBanco,1,3))
			cCpoLivre := "9" + ALLTRIM(cCodEmp) + _NumSant + cDvn + "0" + cCarBank
		Else
			cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
			cCpoLivre := "9" + ALLTRIM(cCodEmp) + cNumSeq + cDvn + "0" + cCarBank
		EndIf
		//_NumSant := "00000"+AllTrim(cNumSeq)
		//cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		//cCpoLivre := "9" + ALLTRIM(cCodEmp) + cNumSeq + cDvn + "0" + cCarBank
		//_NumSant := "00000"+AllTrim(right(cNumSeq,7))
		//cDvn := modulo11("0000"+_NumSant,SubStr(cBanco,1,3))
		//cCpoLivre := "9" + ALLTRIM(cCodEmp) + _NumSant + cDvn + "0" + cCarBank
	ElseIf SubStr(cBanco,1,3) == "104" //CAIXA E.F.

		//CONFIGURACAO ANTERIOR
		//10 - Nosso Numero sem digito verificador (nosso numero deve comecar sempre com 9 no cad. parametro do banco)
		//04 - Agencia
		//04 - Operacao
		//07 - Codigo Beneficiario
		//Total 25

		//cCpoLivre := cNumSeq + Strzero(Val(cAgencia),4) + "8700" + cCodEmp
		//MsgInfo(cCpoLivre)
		//cDvn := modulo11(cNumSeq,SubStr(cBanco,1,3))
		// FIM CONFIGURACAO ANTERIOR


		// Configura��o de Acordo com o Manual do Banco
		// WALTER TSC022 13/07/2016

		_NumCEF   := IIf(AllTrim(cCarteira)=="RG","1"," ") + "4" + StrZero(Val(cNumSeq),15) // nosso n�mero
		cDvn      := Modulo11(_NumCEF,SubStr(cBanco,1,3))  // dv do nosso n�mero

		_NumCEF1  := AllTrim(cCodEmp) + substr(_NumCEF,3,3) + substr(_NumCEF,1,1) + substr(_NumCEF,6,3) + substr(_NumCEF,2,1) + substr(_NumCEF,9,9) // campo livre do cod de barras
		cDvn1     := Modulo11(_NumCEF1,SubStr(cBanco,1,3)) //dv do campo livre
		cCpoLivre := _NumCEF1 + cDvn1

	ElseIf SubStr(cBanco,1,3) == "041" //BANRISUL
		/*
		Posicao 20 a 20 Produto: 
		"1" Cobranca Normal, Fichario emitido pelo BANRISUL
		"2" Cobranca Direta, Fichario emitido pelo CLIENTE.
		Posicao 21 a 21 Constante "1"
		Posicao 22 a 24 Agencia Beneficiario (tres ultimos digitos) sem Numero de Controle.
		Ex.: Se o cod da Agencia for �??0015�?? suprimindo o zero a esquerda fica �??015�??. 
		Posicao 25 a 31	Codigo do Beneficiario sem Numero de Controle.
		Posicao 32 a 39	Nosso Numero sem Numero de Controle.
		Posicao 40 a 42	Constante "041".
		Posicao 43 a 44	Duplo Digito referente às posicoes 20 a 42 (modulos 10 e 11).
		*/

		aDv041 := sfMod041('000000000000000'+substr(cNumSeq,1,8))
		cDvn :=	aDv041[1]+aDv041[2]
		If cDvn = substr(cNumSeq,9,2)
			//            20  21  22                    25                    32       40     43       44
			//cCpoLivre := "2"+"1"+StrZero(Val(cAgencia),4)+StrZero(Val(cConta),7)+substr(cNumSeq,3,10)+"40"
			cCpoLivre := "2"+"1"+StrZero(val(cAgencia),4)+StrZero(Val(substr(cConta,3,7)),7)+substr(cNumSeq,1,8)+"40"
			aDv041 := sfMod041(cCpoLivre)
			cCpoLivre += aDv041[1]+aDv041[2]
			cDvn := substr(cNumSeq,9,2)
		else
			// Calcula Nosso N�mero
			aDv041 := sfMod041('000000000000000'+substr(cNumSeq,3,len(cNumSeq)))
			cDvn :=	aDv041[1]+aDv041[2]
			cNumSeq := substr(cNumSeq,3,len(cNumSeq))+cDvn
			//            20  21  22                    25                    32       40     43       44
			//cCpoLivre := "2"+"1"+StrZero(Val(cAgencia),4)+StrZero(Val(cConta),7)+substr(cNumSeq,3,len(cNumSeq))+"40"
			cCpoLivre := "2"+"1"+StrZero(Val(cAgencia),4)+StrZero(Val(substr(cConta,3,7)),7)+substr(cNumSeq,1,8)+"40"
			aDv041 := sfMod041(cCpoLivre)
			cCpoLivre += aDv041[1]+aDv041[2]
		endif

	ElseIf SubStr(cBanco,1,3) == "085" //CECRED
		cCpoLivre := alltrim(cConvenio)+SubStr(aDadosBanco[4],1,7) + SubStr(aDadosBanco[5],1,1) +STRZERO(VAL(cNosso_Num),9,0)+SubStr(aDadosBanco[6],1,2)

	ElseIf SubStr(cBanco,1,3) == "643"  .OR.  SubStr(cBanco,1,3) == "707" .OR.  SubStr(cBanco,1,3) == "246" //PINE - DAYCOVAL - BANCO ABC
		If SEE->(FieldPos("EE_ZCODOPE")) == 0
			Final("Aten��o - "+ProcName(),"Para o banco Pine/Daycoval/ABC � preciso existir o campo: C�digo da Opera��o - EE_ZCODOPR - Caracter - Posi��es 7, na base de dados ")
		EndIf
		//Campo Livre
		//01 � 04 4 C�digo da Ag�ncia (Sem DV)
		//05 � 07 3 N�mero da Carteira do T�tulo
		//08-14 7 N�mero da Opera��o - Fornecido pelo Banco
		//15-25 11 Nosso N�mero (Com DV)
		//cAgencia	:=	"0001"
		//cCarteira	:=	"110"
		//cNumSeq	:= "0000822085"
		cDvn := cValToChar(Modulo11(PADl(cAgencia,4,"0")+PADl(SEE->EE_CARTEIR,3,"0")+cNumSeq,SubStr(cBanco,1,3),PADl(SEE->EE_CARTEIR,3,"0")) )
		cCpoLivre	:=	PADl(cAgencia,4,"0")+PADl(SEE->EE_CARTEIR,3,"0")+PADl(SEE->EE_ZCODOPE,7,"0")+cNumSeq+cDvn
	Else
		cCpoLivre := ""
	Endif

	//Dados para Calcular o Dig Verificador Geral
	cCBSemDig := cBanco + cFatVenc + blvalorfinal + cCpoLivre

	//Codigo de Barras Completo
	if SubStr(cBanco,1,3) $ "085"
		cCodBarra := cBanco +  Modulo11(cCBSemDig,SubStr(cBanco,1,3)) + cFatVenc + blvalorfinal + cCpoLivre
	ElseIf SubStr(cBanco,1,3) $ "643" //PINE
		cCodBarra := cBanco +  Modulo11(cCBSemDig,,,SubStr(cBanco,1,3)) + cFatVenc + blvalorfinal + cCpoLivre
	ElseIf SubStr(cBanco,1,3) $ "707" //DAYCOVAL
		cCodBarra := cBanco +  Modulo11(cCBSemDig,,,SubStr(cBanco,1,3)) + cFatVenc + blvalorfinal + cCpoLivre
	Else
		cCodBarra := cBanco +  Modulo11(cCBSemDig) + cFatVenc + blvalorfinal + cCpoLivre
	Endif

	//Dados para Calcular o Dig Verificador Geral
	//cCBSemDig := cBanco + cFatVenc + blvalorfinal + cCpoLivre  //WALTER 24/04/2017

	//Codigo de Barras Completo
	//cCodBarra := cBanco +  Modulo11(cCBSemDig, If(SANTANDER .OR. CAIXAEF,"SANTANDER/CAIXA","SEM_BANCO")) + cFatVenc + blvalorfinal + cCpoLivre
	//cCodBarra := cBanco +  Modulo11(cCBSemDig, If(SANTANDER,"SANTANDER","SEM_BANCO")) + cFatVenc + blvalorfinal + cCpoLivre  //WALTER 24/04/2017
	//

	//4 + 1 + 4 + 10 + 6 + 7 + 10 + 2
	//MsgInfo(cCodBarra)
	//Digito Verificador do Primeiro Campo
	cPrCpo := cBanco + SubStr(cCodBarra,20,5)
	cDvPrCpo := AllTrim(Str(Modulo10(cPrCpo)))

	//Digito Verificador do Segundo Campo
	cSgCpo := SubStr(cCodBarra,25,10)
	cDvSgCpo := AllTrim(Str(Modulo10(cSgCpo)))

	//Digito Verificador do Terceiro Campo
	cTrCpo := SubStr(cCodBarra,35,10)
	cDvTrCpo := AllTrim(Str(Modulo10(cTrCpo)))

	//Digito Verificador Geral
	cDvGeral := SubStr(cCodBarra,5,1)

	//Linha Digitavel
	cLindig := SubStr(cPrCpo,1,5) + "." + SubStr(cPrCpo,6,4) + cDvPrCpo + " "   //primeiro campo
	cLinDig += SubStr(cSgCpo,1,5) + "." + SubStr(cSgCpo,6,5) + cDvSgCpo + " "   //segundo campo
	cLinDig += SubStr(cTrCpo,1,5) + "." + SubStr(cTrCpo,6,5) + cDvTrCpo + " "   //terceiro campo
	cLinDig += " " + cDvGeral              //dig verificador geral
	cLinDig += "  " + SubStr(cCodBarra,6,4)+SubStr(cCodBarra,10,10)  // fator de vencimento e valor nominal do titulo

	If SubStr(cBanco,1,3) == "041" //BANRISUL
		cRetNNum := cNumSeq
	Else
		cRetNNum := cNNum+PadR(cDvn,1)
	Endif

Return({cCodBarra,cLinDig,cRetNNum})

/*
Static Function ValidPerg()

	PutSx1(cPerg,"01","Do Prefixo:"				,"","","mv_ch1" ,"C",03,0,0,"G","",""		,"","","mv_par01",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"02","Ate o Prefixo:"			,"","","mv_ch2" ,"C",03,0,0,"G","",""		,"","","mv_par02",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"03","Do Titulo:"				,"","","mv_ch3" ,"C",09,0,0,"G","",""		,"","","mv_par03",""				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"04","Ate o Titulo:"			,"","","mv_ch4" ,"C",09,0,0,"G","",""		,"","","mv_par04",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"05","Da Parcela:"				,"","","mv_ch5" ,"C",02,0,0,"G","",""		,"","","mv_par05",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"06","Ate a Parcela:"			,"","","mv_ch6" ,"C",02,0,0,"G","",""		,"","","mv_par06",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"07","Do Banco:"				,"","","mv_ch7" ,"C",03,0,0,"G","","SA6"	,"","","mv_par07",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"08","Agencia:"				,"","","mv_ch8" ,"C",05,0,0,"G","",""		,"","","mv_par08",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"09","Conta:"					,"","","mv_ch9" ,"C",10,0,0,"G","",""		,"","","mv_par09",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"10","SubConta:" 				,"","","mv_ch10","C",03,0,0,"G","",""		,"","","mv_par10",""  				,"","","","" 			,"","","","","","","","","","","")
	PutSx1(cPerg,"11","Do Cliente:"				,"","","mv_ch11","C",06,0,0,"G","","SA1"	,"","","mv_par11",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"12","Ate o Cliente:"			,"","","mv_ch12","C",06,0,0,"G","","SA1"	,"","","mv_par12",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"13","Da Loja:"				,"","","mv_ch13","C",02,0,0,"G","",""		,"","","mv_par13",""   				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"14","Ate a Loja:"				,"","","mv_ch14","C",02,0,0,"G","",""		,"","","mv_par14",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"15","Da Dt. Venc.:"			,"","","mv_ch15","D",08,0,0,"G","",""		,"","","mv_par15",""  				,"","","",""  			,"","","","","","","","","","","")
	PutSx1(cPerg,"16","Ate a Dt. Venc:"			,"","","mv_ch16","D",08,0,0,"G","",""		,"","","mv_par16",""  				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"17","Da Dt. Emissao:"			,"","","mv_ch17","D",08,0,0,"G","",""		,"","","mv_par17",""   				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"18","Ate a Dt. Emis:"			,"","","mv_ch18","D",08,0,0,"G","",""		,"","","mv_par18",""   				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"19","Do :"				,"","","mv_ch19","C",06,0,0,"G","",""		,"","","mv_par19",""				,"","","",""   			,"","","","","","","","","","","")
	PutSx1(cPerg,"20","Ate o :"			,"","","mv_ch20","C",06,0,0,"G","",""		,"","","mv_par20",""				,"","","",""			,"","","","","","","","","","","")
	PutSx1(cPerg,"21","Selecionar titulos:"		,"","","mv_ch21","N",01,0,0,"C","",""		,"","","mv_par21","Sim"				,"","","","Nao"			,"","","","","","","","","","","")
	PutSx1(cPerg,"22","Gerar :"			,"","","mv_ch22","N",01,0,0,"C","",""		,"","","mv_par22","Sim"				,"","","","Nao"			,"","","","","","","","","","","")
Return*/


Static Function VerParam(mensagem)
	Alert(mensagem)
	U_BOLETOACTVS()
Return

//Busca um  com a data atual que nao tenha sido transferido
Static Function BuscaBorde()

	Local cRet	:= ""
	Local cQuery:= ""
	Local Temp
	Local cIniBord := "A00001"

	cQuery += "Select EA_NUMBOR From "	+ RetSqlName("SEA")	+ " As SEA "
	cQuery += "Where SEA.EA_AGEDEP = '"	+ _MV_PAR08 		+ "' "
	cQuery += "And SEA.EA_NUMCON = '" 	+ _MV_PAR09 		+ "' "
	cQuery += "And SEA.EA_PORTADO = '" 	+ _MV_PAR07 		+ "' "
	cQuery += "And SEA.EA_SUBCTA = '" 	+ _MV_PAR10 		+ "' "
	cQuery += "And SEA.EA_FILIAL = '" 	+ xFilial("SEA") 	+ "' "
	cQuery += "And SEA.EA_DATABOR = '" 	+ dToS(dDataBase) 	+ "' "
	cQuery += "And SEA.EA_TRANSF = '' "
	cQuery += "And SEA.EA_CART = 'R' "
	cQuery += "And SEA.EA_NUMBOR <> '' "
	cQuery += "And SEA.D_E_L_E_T_ = '' "
	cQuery += "And Not Exists (Select * from "	+ RetSqlName("SEA")	+ " As SEA_2 "
	cQuery += " Where SEA_2.D_E_L_E_T_=' ' AND SEA_2.EA_NUMBOR = SEA.EA_NUMBOR AND SEA_2.EA_FILIAL = SEA.EA_FILIAL AND SEA_2.EA_TRANSF <> ' ' )"


	TCQUERY cQuery NEW ALIAS (Temp:=GetNextAlias())

	While (Temp)->(!EoF())
		cRet := (Temp)->EA_NUMBOR
		(Temp)->(DbSkip())
	EndDo

	(Temp)->(DbCloseArea())

Return cRet


/*/{Protheus.doc} sfMod041
Fun��o para c�lculo do N�mero de Controle 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 10/06/2021
@param cNumSeq, character, param_description
@return return_type, return_description
/*/
Static Function sfMod041(cNumSeq)

	Local cNc01 := "", cNc02 := ""

	//cNc01 := Str( Modulo10(cNumSeq), 1, 0 )
	//cNc02 := Modulo11(cNumSeq,'041')
	aRet := Modulo11(cNumSeq,'041')
	cNc01 := aRet[1]
	cNc02 := aRet[2]

Return ({cNc01,cNc02})

Static Function o_Say(oPrint,xPar1,xPar2,xPar3,xPar4,xPar5)
	oPrint:Say( nAddSay+(xPar1*nFatorV) , xPar2*nFatorH , xPar3, xPar4, xPar5 )
Return

Static Function o_Line(oPrint,xPar1,xPar2,xPar3,xPar4)
	oPrint:Line( nAddLin+(xPar1*nFatorV) , xPar2*nFatorH , nAddLin+(xPar3*nFatorV) , xPar4*nFatorH )
Return

Static Function o_SayBitMap(oPrint,xPar1,xPar2,xPar3,xPar4,xPar5)
	oPrint:SayBitMap( 40+(xPar1*nFatorV) , xPar2*nFatorH , xPar3 , xPar4 , xPar5 )
Return


/*/{Protheus.doc} EnvioMail
Fun��o para enviar Boleto por Email 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 10/06/2021
@param cEmailC, character, param_description
@param aAnexo, array, param_description
@return return_type, return_description
/*/
Static Function sfEnvioMail(cEmailC, aAnexo,cInE1Num)

	Local lResult 	:= .F.
	Local cServer	:= GetMV("MV_RELSERV",,"" ) //Nombre de servidor de envio de E-mail utilizado en los informes.
	Local cEmail	:= GetMV("MV_RELACNT",,"" ) //Cuenta a ser utilizada en el envio de E-Mail para los informes
	Local cPassword	:= GetMV("MV_RELPSW",,""  ) //Contrasena de cta. de E-mail para enviar informes
	Local lAuth		:= GetMv("MV_RELAUTH",,.F.)	//Servidor de E-Mail necessita de Autenticacao? Determina se o Servidor necessita de Autenticacao;
		Local lUseSSL	:= GetMv("MV_RELSSL",,.F.)	//Define se o envio e recebimento de E-Mail na rotina SPED utilizara conexao segura (SSL);
		Local lTls		:= GetMV("MV_RELTLS",,.F.)	//Informe si el servidor de SMTP tiene conexion del tipo segura ( SSL/TLS ).
	Local nPort		:= GetMv("MV_SRVPORT",,0)	//Puerto de conexion con el servidor de correo
	Local nErr		:= 0
	Local ctrErr	:= ""
	Local oMailServer := Nil
	Local cAttach  	:= ""
	Local nI 		:= 0
	Local cMsg		:= ""
	Local nX		:= 0
	Local cFromMail := Iif(cEmpAnt=="01","Boletos Decanter",IIf(cEmpAnt=="02","Boletos Hermann","Boletos Decanter")) + "<"+Alltrim(cEmail)+">"
	Local cSubjMail := Iif(cEmpAnt=="01","Boletos Decanter",IIf(cEmpAnt=="02","Boletos Hermann","Boletos Decanter"))
	Local cCorpoM	:= ""

	cCorpoM += "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'> "
	cCorpoM += "<html xmlns='www.w3.org/1999/xhtml'> "
	cCorpoM += "<head> "
	cCorpoM += "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1' /> "
	cCorpoM += "<style type='text/css'> "
	cCorpoM += "<!-- "
	cCorpoM += "body,td,th { "
	cCorpoM += "	font-family: Arial, Helvetica, sans-serif; "
	cCorpoM += "	font-size: 12pt; "
	cCorpoM += "} "
	cCorpoM += "--> "
	cCorpoM += "</style></head> "
	cCorpoM += "<body> "
	cCorpoM += "<br><br>"
	cCorpoM := "Anexo PDF dos boletos gerados para NF "+cInE1Num + "<br><br>"
	cCorpoM += "Favor n�o responder esta mensagem, caixa postal n�o monitorada.<br><br>"
	cCorpoM += "Em caso de d�vidas contate atrav�s do email: contas.receber@decanter.com.br ou pelo telefone (47) 3326-0111<br><br>"
	cCorpoM += "Obrigado.<br><br>"
	cCorpoM += "Decanter Vinhos Finos LTDA<br>"
	cCorpoM += "<br>"
	cCorpoM += "<br>"
	cCorpoM += "Este email � disparado automaticamente - Favor n�o Responder."
	cCorpoM += "<br>"
	cCorpoM += "________________________________________________________________________"
	cCorpoM += "<br>"

	cCorpoM += "</body> "
	cCorpoM += "</html>"


	// Verifica se a porta foi concatenada no endere�o do smtp
	If At(":",cServer ) > 0
		nPort	:= Val(Substr(cServer,At(":",cServer)+1))
		cServer	:= Substr(cServer,1,At(":",cServer)-1)
	Endif

	If Empty(cServer)
		cMsg += "Configure par�metro " + "MV_RELSERV"  + CHR(13) + CHR(10)
	EndIf
	If Empty(cEmail)
		cMsg += "Configure par�metro " + "MV_RELACNT" + CHR(13) + CHR(10)
	EndIf
	If Empty(cPassword)
		cMsg += "Configure par�metro " + "MV_RELPSW" + CHR(13) + CHR(10)
	EndIf
	If Empty(cEmailC)
		cMsg += "Configure email del cliente." + CHR(13) + CHR(10)
	EndIf

	If !empty(cMsg)
		return .F.
	EndIf

	If !Empty(cEmailC)
		For nI:= 1 to Len(aAnexo)
			cAttach += aAnexo[nI] + "; "
		Next nI

		If !lAuth .And. !lUseSSL .And.!lTls
			CONNECT SMTP SERVER cServer ACCOUNT cEmail PASSWORD cPassword RESULT lResult

			If lResult
				SEND MAIL FROM cEmail ;
					TO      	cEmailC;
					BCC     	"";
					SUBJECT 	"Envio de Boleto";
					BODY    	"Boleto";
					ATTACHMENT  cAttach  ;
					RESULT lResult

				If !lResult
					//Erro no envio do email
					GET MAIL ERROR cError
					Help(" ",1,"Aviso",,cError,4,5)
				EndIf

			Else
				//Erro na conexao com o SMTP Server
				GET MAIL ERROR cError
				Help(" ",1,"Aviso",,cError,4,5) //--- Aviso

			EndIf

			DISCONNECT SMTP SERVER
		Else
			//Instancia o objeto do MailServer
			oMailServer:= TMailManager():New()
			oMailServer:SetUseSSL(lUseSSL)    //Obs: Apenas se servidor de e-mail utiliza autenticacao SSL para envio
			oMailServer:SetUseTLS(lTls)       //Obs: Apenas se servidor de e-mail utiliza autenticacao TLS para recebimento

			If Empty(nPort)
				oMailServer:Init("",cServer,cEmail,cPassword,0)
			Else
				oMailServer:Init("",cServer,cEmail,cPassword,0,nPort)
			EndIf

			//Defini��o do timeout do servidor
			If oMailServer:SetSmtpTimeOut(120) != 0
				Help(" ",1,"Aviso",,OemToAnsi("Timeout de Servidor") ,4,5)
				Return .F.
			EndIf

			//Conex�o com servidor
			nErr := oMailServer:smtpConnect()
			If nErr <> 0
				cTrErr:= oMailServer:getErrorString(nErr)
				oMailServer:smtpDisconnect()

				// Intenta (varias veces) el env�o a trav�s de otra clase de conexi�n
				lResult := EnvioMail2(cServer, cEmail, cPassword, lAuth, cEmailC, aAnexo, @cTrErr)

				If !lResult
					Help(" ",1,"Aviso",,ctrErr,4,5)
				EndIf

				Return lResult
			EndIf

			//Autentica��o com servidor smtp
			nErr := oMailServer:smtpAuth(cEmail, cPassword)
			If nErr <> 0
				cTrErr := OemToAnsi("Autentica��o com servidor SMTP") + CRLF + oMailServer:getErrorString(nErr)
				oMailServer:smtpDisconnect()

				// Intenta (varias veces) el env�o a trav�s de otra clase de conexi�n
				lResult := EnvioMail2(cServer, cEmail, cPassword, lAuth, cEmailC, aAnexo, @cTrErr)

				If !lResult
					Help(" ",1,"Aviso",,cTrErr ,4,5)
				EndIf

				Return lResult
			EndIf

			//Cria objeto da mensagem+
			oMessage := tMailMessage():new()
			oMessage:clear()
			oMessage:cFrom 	:= cFromMail //cEmail
			oMessage:cTo 	:= cEmailC
			oMessage:cSubject := cSubjMail + "-Envio de Boleto da Nota Fiscal " + cInE1Num
			oMessage:cBody := cCorpoM

			For nX := 1 to Len(aAnexo)
				oMessage:AddAttHTag("Content-ID: <" + aAnexo[nX] + ">") //Essa tag, � a referecia para o arquivo ser mostrado no corpo, o nome declarado nela deve ser o usado no HTML
				oMessage:AttachFile(aAnexo[nX])                       //Adiciona um anexo, nesse caso a imagem esta no root
			Next nX

			//Dispara o email
			nErr := oMessage:send(oMailServer)
			If nErr <> 0
				cTrErr := oMailServer:getErrorString(nErr)
				Help(" ",1,"Aviso",,OemToAnsi("Erro ao enviar o Email") + CRLF + cTrErr ,4,5)//"Aviso" ## "Error en el Envio del Email"
				oMailServer:smtpDisconnect()
				Return .F.
			Else
				lResult := .T.
				ConOut("[BoletoActvs] - Envio de boletos pdf da nota "+cInE1Num + " para "+cEmailC )
			EndIf

			//Desconecta do servidor
			oMailServer:smtpDisconnect()
		EndIf
	EndIf
Return lResult

/*/{Protheus.doc} sfObtEmail
Fun��o para obter o email do cliente 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 10/06/2021
@param cInCod, character, param_description
@param cInLoja, character, param_description
@return return_type, return_description
/*/
Static Function sfObtEmail(cInCod,cInLoja)

	Local cEmailCli := "ml-servicos@outlook.com"
	Local aArea 	:= GetArea()

	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))
	If SA1->(dbSeek(xFilial("SA1") + cInCod + cInLoja))
		If SA1->(FieldPos("A1_ZMAILBQ")) > 0
			cEmailCli := SA1->A1_ZMAILBQ
		Endif
	EndIf

	RestArea(aArea)

Return cEmailCli

/*/{Protheus.doc} EnvioMail2
//TODO Descri��o auto-gerada.
@author arodriguez
@since 10/01/2020
@version 1.0
@return l�gico, env�o correcto?
@param cMailServer, characters, direcci�n de servidor de correo
@param cMailConta, characters, usuario de conexi�n / cuenta de correo remitente
@param cMailSenha, characters, contrase�a del usuario
@param lAutentica, logical, requiere autenticaci�n?
@param cEmail, characters, correo destinatario (cliente)
@param cEMailAst, characters, asunto
@param cMensGral, characters, contenido
@param aAnexo, array, array de anexos
@param cErr, characters, (@referencia) variable para mensaje de error
@type function
/*/
Static Function EnvioMail2(cMailServer, cMailConta, cMailSenha, lAutentica, cEmail, cEMailAst, cMensGral, aAnexo, cErr)

	Local cAcAut	:= GetMV("MV_RELAUSR",,"" )		//Usuario para autenticacion en el servidor de email
	Local cPwAut 	:= GetMV("MV_RELAPSW",,""  )	//Contrase�a para autenticacion en servidor de email
	Local lResult	:= .F.
	Local nIntentos	:= 0

	If lAutentica .And. Empty(cAcAut+cPwAut)
		Return lResult
	EndIf

	Do While !lResult .And. nIntentos < 11
		nIntentos++
		lResult := MailSmtpOn(cMailServer,cMailConta,cMailSenha)

		// Verifica se o E-mail necessita de Autenticacao
		If lResult .And. lAutentica
			lResult := MailAuth(cAcAut,cPwAut)
		Endif

		If lResult
			lResult := MailSend(cMailConta, {cEmail}, {" "}, {" "}, cEMailAst, cMensGral, aAnexo)
		EndIf

		If !lResult
			cErr := MailGetErr()
		EndIf

		MailSmtpOff()
	EndDo

Return lResult

Static Function sfValAtrib(xInAtributo)
Return (Type(xInAtributo) )
