#include "rwmake.ch"
#include "protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} BFFINM02
(Interface para lan็amento de rateios offline externos e fazer o lan็amento Contas a pagar mensais    )
@author MarceloLauschner
@since 27/05/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFINM02()

	Local		lContinua	:= .F.
	Local		aItemsOper	:= {}
	Local		aAreaOld	:= GetArea()
	Local		oPerg
	Private		cTipOper	:= "D"
	Private		cCodSZR		:= " "//GetSXENum("SZR","ZR_CODRATE")

	// Adicionada checagem para evitar que seja usada indevidamente a fun็ใo
	If !cEmpAnt $ "02#11"
		MsgInfo("Fun็ใo nใo deve ser usada por empresas diferentes da 02-Atrialub 11-Onix")
		Return 
	Endif
	// Executa grava็ใo do Log de Uso da rotina
	U_BFCFGM01()

	// For็o o ajuste do controle de numera็ใo dos rateios, para que cada lan็amento tenha um c๓digo
	DbSelectArea("SZR")
	DbSetOrder(1)
	Do While .T.
		cCodSZR		:= GetSXENum("SZR","ZR_CODRATE")
		If !dbSeek( xFilial( "SZR" ) + cCodSZR )
			Exit
		Else
			ConfirmSX8()
		EndIf
	EndDo


	DEFINE MSDIALOG oPerg FROM 001,001 TO 150,350 OF oMainWnd PIXEL TITLE OemToAnsi("Selecione uma op็ใo")
	@ 035,010 Say "Opera็ใo" Of oPerg Pixel

	Aadd(aItemsOper,"D=Desmembrar/Ratear Tํtulo")
	Aadd(aItemsOper,"C=Gerar Contas a Pagar")
	If cEmpAnt == "02"
		Aadd(aItemsOper,"R=Incluir/Alterar Rateios Off-line")
	Endif

	@ 035,045 Combobox cTipOper Items aItemsOper Size 100,10 Of oPerg Pixel
	@ 050,010 Say "C๓d.Rateio" Of oPerg Pixel
	@ 050,045 MsGet cCodSZR Picture "@!" Size 60,10 F3 "SZR" Of oPerg Pixel

	ACTIVATE MSDIALOG oPerg ON INIT EnchoiceBar(oPerg,{|| lContinua	:= .T. /*true*/,oPerg:End()},{|| oPerg:End()},,) CENTERED


	If lContinua
		// Ao desmembrar tํtulo confirmo numera็ใo usada
		If cTipOper == "D"
			ConfirmSX8()
		ElseIf cTipOper == "R"
			// Inclusใo ou altera็ใo de Rateio
			// Verifica se o n๚mero informado jแ existe, executa Rollback na numera็ใo
			DbSelectArea("SZR")
			DbSetOrder(1)
			If dbSeek( xFilial( "SZR" ) + cCodSZR )
				RollBackSX8()
			Else
				ConfirmSX8()
			Endif
		Else
			// Para gera็ใo de contas a pagar nใo grava registro novo na SZR
			// Executa rollback na numera็ใo
			RollBackSX8()
		Endif
		sfAuxCadas()
	Else
		RollBackSX8()
	Endif

	RestArea(aAreaOld)

Return



/*/{Protheus.doc} sfAuxCadas
(Interface com cabe็alho e grid de fornecedores/vendedores )
@author MarceloLauschner
@since 27/05/2012 
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAuxCadas()

	Local	oRateios
	Local	aSize 			:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Local	aInfo 			:= { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ],3,3 }
	Local	aPosObj,aPosGet,nGetLin
	Local	aObjects		:= {}
	Local	aHeader			:= {}
	Local	aCols			:= {}
	Local	bChangeSZR		:= {|| sfAtuDados()}
	Local	aOpcEmpRom		:= {"NA=Nใo Usado","SL=Superlog"}
	Local	lGrava			:= .F.
	Private	lAlteraSZR		:= .F.
	Private oGetTot1,oGetTot2,oGetTot3,oValRateio
	Private	aTextTotais		:= {{RetTitle("ZR_VALMERC",30),0},{RetTitle("ZR_PERCRAT",30),0},{RetTitle("ZR_VALRATE",30),0}}

	Private nValRateio		:= 0
	Private cRatOrig		:= ""
	Private aButtons		:= IIf(cTipOper == "C",{{"VERDE"		,{|| U_BFFINM03()}  ,"Contas Pagar"}},IIf(cTipOper == "R",{{"AZUL",{|| U_BFFINM09()}  ,"Novo Rateio"},{"VERMELHO",{|| U_BFFINM10()}  ,"Ver agrupamentos"}},{}))
	Private cRatTipo		:= "V"
	Private cEmpOrig		:= "NA"
	Private	nPosCols		:= 1
	Private cNumRomaneio	:= Space(300)
	Private nPxITEM,nPxCCUSORI,nPxDEBCRED,nPxCODVEND,nPxCODFORN,nPxLOJA,nPxNOME,nPxCUSTDES,nPxPERCRAT,nPxVALRATE,nPxKEYSE2
	Private nPxCODRATE,nPxRAMAL,nPxVALMERC,nPxVALORI,nPxDTINI,nPxDTFIM
	Private	cKeySE2			:= ""
	Private dDataIni		:= dDataBase
	Private dDataFim		:= dDataBase
	Private lRetCarrega		:= .T.
	Private lSortOrd		:= .F.


	If cEmpAnt == "02"
		Aadd(aOpcEmpRom,"BF=BigForta")
	ElseIf cEmpAnt == "03"
		Aadd(aOpcEmpRom,"LL=LLUst")
	Elseif cEmpant == "04"
		Aadd(aOPcEmprom,"AT=Atria")
	Endif
	Aadd(aOpcEmpRom,"FT=Freteiros - Superlog")

	// Serแ utilizado tr๊s แreas na janela // 1ช - Enchoice, sendo 80 pontos pixel // 2ช - MsGetDados, o que sobrar em pontos pixel ้ para este objeto // 3ช - Rodap้ que ้ a pr๓pria janela, sendo 15 pontos pixel AADD( aObj, { 100, 080, .T., .F. }) AADD( aObj, { 100, 100, .T., .T. }) AADD( aObj, { 100, 015, .T., .F. })   // Cแlculo automแtico da dimens๕es dos objetos (altura/largura) em pixel aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 3, 3 } aPObj := MsObjSize( aInfo, aObj )   // Cแlculo automแtico de dimens๕es dos objetos MSGET aPGet := MsObjGetPos( (aSize[3] - aSize[1]), 315, { {004, 024, 240, 270} } )
	//ณ          ณ    1 - Tamanho X    / 2 - Tamanho Y  / 3 - Dimensiona X    ณ
	//ณ          ณ    4 - Dimensiona Y / 5 - Retorna dimensoes X e Y ao inves ณ

	AAdd( aObjects, { 100,050, .T., .F. } )
	AAdd( aObjects, { 100,700, .T., .T. } )
	AAdd( aObjects, { 100,080, .T., .F. } )
	//AAdd( aObjects, { 300,100, .T., .F. } )
	aPosObj := MsObjSize( aInfo, aObjects )
	// 1 - Limite superior
	// 2 - Limite esquerdo
	// 3 - Limite inferior
	// 4 - Limite direito
	aPosGet := MsObjGetPos(aSize[3]-aSize[1]   ,315  ,{{003,033,160,200}} )

	nGetLin := aPosObj[3,1]

	Processa({|| lRetCarrega := sfCarrega(@aCols,@aHeader,1) },"Localizando registros...")

	If !lRetCarrega
		MsgAlert("C๓digo de rateio invแlido para este tipo de opera็ใo!","C๓digo invแlido!")
		Return
	Endif

	DEFINE MSDIALOG oRateios FROM 001,001 TO aSize[6] , aSize[5] OF oMainWnd PIXEL TITLE OemToAnsi("Desmembramento de Faturas para Rateio " - "'" + cCodSZR + "'" )

	//TScrollBox(): New ( [ oWnd], [ nTop], [ nLeft], [ nHeight], [ nWidth], [ lVertical], [ lHorizontal], [ lBorder] ) --> oObjeto

	Private oCabec	:= TScrollBox():New(oRateios,aPosObj[1,1],aPosObj[1,2],aPosObj[1,3]-15,aPosObj[1,4]-3,.F., .T.,.T.)

	//@ aPosObj[1,1],aPosObj[1,2] TO aPosObj[1,3],aPosObj[1,4] Of oRateios Pixel
	@ 003,010 Say "Ratear por " Of oCabec Pixel
	@ 002,045 Combobox cRatTipo Items Iif(cTipOper == "C",{"F=Funcionario"},IIf(cTipOper == "R",{"C=Centro de Custo","N=Nenhum"},{"V=Vendedor","F=Funcionแrio"})) Size 70,10 Of oCabec Pixel Valid sfVldRatTipo() When !lAlteraSZR
	@ 003,130 Say "R$ a Ratear" Of oCabec Pixel
	@ 002,165 MsGet oValRateio Var nValRateio Picture "@E 999,999,999.99" Size 60,10 Of oCabec Pixel When cTipOper == "C" Valid sfValRateio()
	@ 003,235 Say "Emp.Rat.Frete" Of oCabec Pixel
	@ 002,280 Combobox cEmpOrig Items aOpcEmpRom Size 60,10 Of oCabec Pixel When (cRatTipo == "V" .And. !lAlteraSZR .And. cTipOper # "R") Valid sfVldEmpOri()
	@ 003,355 Say OemToAnsi("Nฐ Romaneio") Of oCabec Pixel
	@ 002,390 MsGet cNumRomaneio Picture "@!" Size 100,10 Of oCabec Pixel When ( cEmpOrig <> "NA".And. cTipOper # "R") Valid sfVldNumRom()

	//@ aPosObj[4,1],aPosObj[4,2] TO aPosObj[4,3],aPosObj[4,4] Of oRateios Pixel


	Private oMulti := MsNewGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],GD_INSERT+GD_DELETE+GD_UPDATE,"U_BFFINM07()"/*cLinhaOk*/,;
	"U_BFFINM08()"/*cTudoOk*/,"+ZR_ITEM",;
	,4/*nFreeze*/,10000/*nMax*/,/*cCampoOk*/,/*cSuperApagar*/,;
	/*cApagaOk*/,oRateios,@aHeader,@aCols,bChangeSZR)


	oMulti:oBrowse:bHeaderClick := {|| nColPos :=oMulti:oBrowse:ColPos,lSortOrd := !lSortOrd, aSort(oMulti:aCols,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),oMulti:oBrowse:Refresh() }

	If cTipOper == "R"
		@ 015,010 Say "Data Inicial" Of oCabec Pixel
		@ 014,045 MsGet oDataIni Var dDataIni  Size 40,10 Of oCabec Pixel Valid sfValData()
		@ 015,130 Say "Data Final" Of oCabec Pixel
		@ 014,165 MsGet oDataFim Var dDataFim  Size 40,10 Of oCabec Pixel Valid sfValData()
	Endif


	Private oPTotais	:= TScrollBox():New(oRateios,aPosObj[3,1],aPosObj[3,2],aPosObj[3,3]-15,aPosObj[3,4]-3,.T., .T.,.T. )
	@ 010,010 Say aTextTotais[1,1] of oPTotais Pixel
	@ 025,010 Say aTextTotais[2,1] of oPTotais Pixel
	@ 010,140 Say aTextTotais[3,1] of oPTotais Pixel

	@ 010,070 MsGet oGetTot1 Var aTextTotais[1,2] Picture PesqPict("SZR","ZR_VALMERC",14) Size 60,10 of oPTotais Pixel When .F.
	@ 025,070 MsGet oGetTot2 Var aTextTotais[2,2] Picture PesqPict("SZR","ZR_PERCRAT",14) Size 60,10 of oPTotais Pixel When .F.
	@ 010,210 MsGet oGetTot3 Var aTextTotais[3,2] Picture PesqPict("SZR","ZR_VALRATE",14) Size 60,10 of oPTotais Pixel When .F.

	ACTIVATE MSDIALOG oRateios ON INIT EnchoiceBar(oRateios,{|| IIf(U_BFFINM08(),(lGrava := .T. /*true*/,oRateios:End()),Nil)},{|| oRateios:End()},,aButtons) CENTERED

	If lGrava
		Begin Transaction
			sfGrava()
		End Transaction
	Endif

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfCarrega บAutor  ณMarcelo A Lauschner บ Data ณ27/05/2012   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Efetua a montagem do aHeader e aCols                       บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfCarrega(aCols,aHeader,nRefrBox)

	Local	nUsado	:= 0
	Local 	aFields 	:= {}
	Local	cQry
	Local	nI, iX
	Local	nColuna

	aCols			:= 	{}
	// DbSelectArea("SX3")
	// DbSetOrder(1)
	// DbSeek("SZR01")
	// While !Eof() .And. SX3->X3_ARQUIVO == "SZR"
	// 	If X3USO(SX3->X3_USADO)
	// 		Aadd(aHeader,{ AllTrim(X3Titulo()),;
	// 		SX3->X3_CAMPO	,;
	// 		SX3->X3_PICTURE,;
	// 		SX3->X3_TAMANHO,;
	// 		SX3->X3_DECIMAL,;
	// 		SX3->X3_VALID	,;
	// 		SX3->X3_USADO	,;
	// 		SX3->X3_TIPO	,;
	// 		SX3->X3_F3 		,;
	// 		SX3->X3_CONTEXT,;
	// 		SX3->X3_CBOX	,;
	// 		SX3->X3_RELACAO })
	// 		nUsado++
	// 		If nRefrBox == 1
	// 			&("nPx"+Substr(SX3->X3_CAMPO,4,7)) := nUsado
	// 		Endif
	// 	Endif
	// 	SX3->(DbSkip())
	// Enddo

	aFields := FWSX3Util():GetAllFields("SZR", .F. /*/lVirtual/*/)
	For iX := 1 To Len(aFields)
		cCampo := aFields[iX]
		If X3Uso(GetSx3Cache(cCampo,"X3_USADO"))
			Aadd(aHeader,{GetSx3Cache(cCampo,"X3_TITULO")			,;	//	1
				GetSx3Cache(cCampo,"X3_CAMPO")						,;	//	2
				GetSx3Cache(cCampo,"X3_PICTURE")					,;	//	3
				GetSx3Cache(cCampo,"X3_TAMANHO")					,;	//	4
				GetSx3Cache(cCampo,"X3_DECIMAL")					,;	//	5
				GetSx3Cache(cCampo,"X3_VALID")						,;	//	6
				GetSx3Cache(cCampo,"X3_USADO")						,;	//	7
				GetSx3Cache(cCampo,"X3_TIPO")						,;	//	8
				GetSx3Cache(cCampo,"X3_F3")							,;	//	9
				GetSx3Cache(cCampo,"X3_CONTEXT")					,;	//	10
				GetSx3Cache(cCampo,"X3_CBOX")						,;	//	11
				GetSx3Cache(cCampo,"X3_RELACAO")					})	// 	12
				nUsado++
				If nRefrBox == 1
					&("nPx"+Substr(GetSx3Cache(cCampo,"X3_CAMPO"),4,7)) := nUsado
				Endif
		EndIf
	Next

	If nRefrBox == 1
		If cTipOper == "D"
			cKeySE2			:= 	SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA
			cRatOrig		:= SE2->E2_CC
			nValRateio		:= SE2->E2_SALDO
			DbSelectArea("SZR")
			DbSetOrder(2)   // ZR_FILIAL+ZR_KEYSE2
			If DbSeek(xFilial("SZR")+SE2->E2_FILIAL+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_PARCELA+SE2->E2_TIPO+SE2->E2_FORNECE+SE2->E2_LOJA)
				nValRateio		:= SZR->ZR_VALORI
				cRatOrig		:= SZR->ZR_CCUSORI
				cRatTipo		:= SZR->ZR_ORIGEM
				lAlteraSZR		:= .T.
				cCodSZR			:= SZR->ZR_CODRATE
			Else
				nValRateio	:= SE2->E2_VALOR//+SE2->E2_ACRESC-SE2->E2_DECRESC
			Endif
			cAliasSZR := GetNextAlias()
			BeginSql Alias cAliasSZR
				SELECT ZR_ITEM,ZR_CCUSORI,ZR_DEBCRED,ZR_CODVEND,ZR_CODFORN,ZR_LOJA,ZR_NOME,ZR_CUSTDES,ZR_PERCRAT,ZR_VALRATE,R_E_C_N_O_ ZRRECNO
				FROM %Table:SZR% SZR
				WHERE ZR_FILIAL = %xFilial:SZR%
				AND ZR_KEYSE2 = %Exp:cKeySE2%
				AND SZR.%NotDel%
				ORDER BY ZR_ITEM
			EndSql
		ElseIf cTipOper == "R"
			cKeySE2			:= 	" "
			cRatOrig		:=  Space(TamSX3("ZR_CCUSORI")[1])
			nValRateio		:=  0
			DbSelectArea("SZR")
			DbSetOrder(1)   // ZR_FILIAL+ZR_CODRATE
			If DbSeek(xFilial("SZR")+cCodSZR)
				nValRateio		:= SZR->ZR_VALORI
				cRatOrig		:= SZR->ZR_CCUSORI
				cRatTipo		:= SZR->ZR_ORIGEM
				dDataIni		:= SZR->ZR_DTINI
				dDataFim		:= SZR->ZR_DTFIM
				lAlteraSZR		:= .T.
			Endif
			cAliasSZR := GetNextAlias()
			BeginSql Alias cAliasSZR
				SELECT ZR_ITEM,ZR_CCUSORI,ZR_DEBCRED,ZR_CODVEND,ZR_CODFORN,ZR_LOJA,ZR_NOME,ZR_CUSTDES,ZR_PERCRAT,ZR_VALRATE,R_E_C_N_O_ ZRRECNO
				FROM %Table:SZR% SZR
				WHERE ZR_FILIAL = %xFilial:SZR%
				AND ZR_CODRATE = %Exp:cCodSZR%
				AND ZR_TIPOPER = 'R'
				AND ZR_KEYSE2 = ' '
				AND SZR.%NotDel%
				ORDER BY ZR_ITEM
			EndSql
		Else
			cKeySE2			:= 	" "
			cRatOrig		:=  " "
			nValRateio		:=  0
			DbSelectArea("SZR")
			DbSetOrder(1)   // ZR_FILIAL+ZR_CODRATE
			If DbSeek(xFilial("SZR")+cCodSZR)
				nValRateio		:= SZR->ZR_VALORI
				cRatOrig		:= SZR->ZR_CCUSORI
				cRatTipo		:= SZR->ZR_ORIGEM
				lAlteraSZR		:= .T.
			Endif
			cAliasSZR := GetNextAlias()
			BeginSql Alias cAliasSZR
				SELECT ZR_ITEM,ZR_CCUSORI,ZR_DEBCRED,ZR_CODVEND,ZR_CODFORN,ZR_LOJA,ZR_NOME,ZR_CUSTDES,ZR_PERCRAT,ZR_VALRATE,R_E_C_N_O_ ZRRECNO
				FROM %Table:SZR% SZR
				WHERE ZR_FILIAL = %xFilial:SZR%
				AND ZR_CODRATE = %Exp:cCodSZR%
				AND SZR.%NotDel%
				ORDER BY ZR_ITEM
			EndSql
		Endif


	ElseIf nRefrBox == 2
		cAliasSZR	:= "QZR"
		cQry := ""
		cQry += "SELECT TRIM(SUBSTR(LPAD(ROWNUM,3,'0'),1,3)) ZR_ITEM,"
		cQry += "       ZR_CODVEND,"
		cQry += "       ZR_CODFORN,"
		cQry += "       ZR_LOJA,"
		cQry += "       ZR_NOME,"
		cQry += "       ZR_CUSTDES,"
		cQry += "       ZR_RAMAL"
		cQry += "  FROM (SELECT A2_COD ZR_CODFORN,"
		cQry += "               A2_LOJA ZR_LOJA,"
		cQry += "               A2_NOME ZR_NOME,"
		cQry += "               A2_CC ZR_CUSTDES,"
		cQry += "               A2_NUMFUNC ZR_CODVEND,"
		cQry += "               A2_FAX ZR_RAMAL "
		cQry += "          FROM "+RetSqlName("SA2") + " A2 "
		cQry += "         WHERE D_E_L_E_T_ = ' ' "
		cQry += "           AND A2_MSBLQL != '1' "
		cQry += "           AND A2_NUMFUNC != ' ' "
		If cTipOper == "R"
			cQry += "		AND A2_CC NOT LIKE '1014%' "
		Endif
		cQry += "           AND A2_FILIAL = '"+xFilial("SA2") + "' "
		cQry += "         ORDER BY A2_NOME) "

		TCQUERY cQry NEW ALIAS "QZR"

	ElseIf nRefrBox == 3
		cAliasSZR	:= "QZR"
		cQry := ""
		cQry += "SELECT TRIM(SUBSTR(LPAD(ROWNUM,3,'0'),1,3)) ZR_ITEM,"
		cQry += "       ZR_CODVEND,"
		cQry += "       ZR_CODFORN,"
		cQry += "       ZR_LOJA,"
		cQry += "       ZR_NOME,"
		cQry += "       ZR_CUSTDES"
		cQry += "  FROM (SELECT A3_COD ZR_CODVEND,"
		cQry += "               A3_FORNECE ZR_CODFORN,"
		cQry += "               A3_LOJA ZR_LOJA,"
		cQry += "               A3_NOME ZR_NOME,"
		cQry += "               A3_CC ZR_CUSTDES "
		cQry += "          FROM "+RetSqlName("SA3") + " A3 "
		cQry += "         WHERE D_E_L_E_T_ = ' ' "
		cQry += "           AND A3_MSBLQL != '1' "
		If cTipOper == "R"
			cQry += "		AND A3_CC NOT LIKE '1014%' "
		Endif
		cQry += "           AND A3_CC != ' ' "
		cQry += "           AND A3_FILIAL = '"+xFilial("SA3") + "' "
		cQry += "         ORDER BY A3_NOME) "

		TCQUERY cQry NEW ALIAS "QZR"
	ElseIf nRefrBox == 4
		cAliasSZR	:= "QZR"
		cQry := ""
		If cEmpOrig $ "BF#LL#AT"

			cQry += "SELECT SUBSTR(LPAD(ROWNUM,3,'0'),1,3) ZR_ITEM,"
			cQry += "       ZR_CODVEND,"
			cQry += "       ZR_CODFORN,"
			cQry += "       ZR_LOJA,"
			cQry += "       ZR_NOME,"
			cQry += "       ZR_CUSTDES,"
			cQry += "       ZR_VALMERC "
			cQry += "  FROM (SELECT A3_COD ZR_CODVEND,"
			cQry += "               A3_FORNECE ZR_CODFORN,"
			cQry += "               A3_LOJA ZR_LOJA,"
			cQry += "               A3_NOME ZR_NOME,"
			cQry += "               A3_CC ZR_CUSTDES,"
			cQry += "               SUM(F2_VALBRUT) ZR_VALMERC "
			cQry += "          FROM "+RetSqlName("SA3") + " A3, "+RetSqlName("SF2") + " F2, "+RetSqlName("SZ1") + " Z1 "
			cQry += "         WHERE A3.D_E_L_E_T_ = ' ' "
			cQry += "           AND A3_MSBLQL != '1' "
			cQry += "           AND A3_COD = F2_VEND1 "
			cQry += "           AND A3_FILIAL = '"+xFilial("SA3") + "' "
			cQry += "           AND F2.D_E_L_E_T_ = ' ' "
			cQry += "           AND F2_LOJA = Z1_LOJA "
			cQry += "           AND F2_CLIENTE = Z1_CLIENTE "
			cQry += "           AND F2_SERIE = Z1_SERIE "
			cQry += "           AND F2_DOC = Z1_NOTAFIS "
			cQry += "           AND F2_FILIAL = '"+xFilial("SF2") + "' "
			cQry += "           AND Z1.D_E_L_E_T_ = ' ' "
			cQry += "           AND Z1_ROMANEI IN('"+StrTran(StrTran(StrTran(Alltrim(cNumRomaneio),"/",";")," ",";"),";","','")+"') "
			cQry += "           AND Z1_FILIAL = '"+xFilial("SZ1")+"' "
			cQry += "         GROUP BY A3_COD,A3_FORNECE,A3_LOJA,A3_NOME,A3_CC "
			cQry += "         ORDER BY A3_NOME) "
		ElseIf cEmpOrig == "SL"
			cQry += "SELECT SUBSTR(LPAD(ROWNUM,3,'0'),1,3) ZR_ITEM,"
			cQry += "       ZR_CODVEND,"
			cQry += "       ZR_CODFORN,"
			cQry += "       ZR_LOJA,"
			cQry += "       ZR_NOME,"
			cQry += "       ZR_CUSTDES,"
			cQry += "       ZR_VALMERC "
			cQry += "   FROM(
			cQry += "SELECT ZR_CODVEND,"
			cQry += "       ZR_CODFORN,"
			cQry += "       ZR_LOJA,"
			cQry += "       ZR_NOME,"
			cQry += "       ZR_CUSTDES,"
			cQry += "       SUM(ZR_VALMERC) ZR_VALMERC "
			cQry += " FROM ("
			cQry += "SELECT A3_COD ZR_CODVEND,"
			cQry += "       A3_FORNECE ZR_CODFORN,"
			cQry += "       A3_LOJA ZR_LOJA,"
			cQry += "       A3_NOME ZR_NOME,"
			cQry += "       A3_CC ZR_CUSTDES, "
			cQry += "       DT6_VALFAT ZR_VALMERC"
			cQry += "  FROM "+RetSqlname("SA3")+" A3,"+RetSqlName("SF2")+" F2, SUPERLOG_DT6 DT6 "
			cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
			cQry += "   AND A3_MSBLQL != '1' "
			cQry += "   AND A3_COD = F2_VEND1 "
			cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"'"
			cQry += "   AND F2.D_E_L_E_T_ = ' ' "
			cQry += "   AND F2_SERIE = DTC_SERNFC "
			cQry += "   AND LPAD(RTRIM(F2_DOC),'9','0') = LPAD(RTRIM(DTC_NUMNFC),'9','0') "
			cQry += "   AND F2_FILIAL = '"+xFilial("SF2")+"' "
			cQry += "   AND DTC_SERIE = DT6_SERIE "
			cQry += "   AND DTC_DOC = DT6_DOC "
			cQry += "   AND DTC_FILIAL = '  '  "
			cQry += "   AND DT6_NUM IN('"+StrTran(StrTran(StrTran(Alltrim(cNumRomaneio),"/",";")," ",";"),";","','")+"') "
			cQry += "   AND DT6_FILIAL = '  ' )"
			cQry += " GROUP BY ZR_CODVEND,ZR_CODFORN,ZR_LOJA,ZR_NOME,ZR_CUSTDES) 	 "
		ElseIf cEmpOrig == "FT"

			cQry += "SELECT SUBSTR(LPAD(ROWNUM,3,'0'),1,3) ZR_ITEM,"
			cQry += "       ZR_CODVEND,"
			cQry += "       ZR_CODFORN,"
			cQry += "       ZR_LOJA,"
			cQry += "       ZR_NOME,"
			cQry += "       ZR_CUSTDES,"
			cQry += "       ZR_VALMERC "
			cQry += "  FROM ( "
			cQry += "SELECT ZR_CODVEND,"
			cQry += "       ZR_CODFORN,"
			cQry += "       ZR_LOJA,"
			cQry += "       ZR_NOME,"
			cQry += "       ZR_CUSTDES,"
			cQry += "       SUM(ZR_VALMERC) ZR_VALMERC "
			cQry += " FROM ("
			cQry += "SELECT A3_COD ZR_CODVEND,"
			cQry += "       A3_FORNECE ZR_CODFORN,"
			cQry += "       A3_LOJA ZR_LOJA,"
			cQry += "       A3_NOME ZR_NOME,"
			cQry += "       A3_CC ZR_CUSTDES, "
			cQry += "       DT6_VALFAT ZR_VALMERC"
			cQry += "  FROM "+RetSqlname("SA3")+" A3,"+RetSqlName("SF2")+" F2, SUPERLOG_DT6 DT6 "
			cQry += " WHERE A3.D_E_L_E_T_ = ' ' "
			cQry += "   AND A3_MSBLQL != '1' "
			cQry += "   AND A3_COD = F2_VEND1 "
			cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"'"
			cQry += "   AND F2.D_E_L_E_T_ = ' ' "
			cQry += "   AND F2_SERIE = DTC_SERNFC "
			cQry += "   AND LPAD(RTRIM(F2_DOC),'9','0') = LPAD(RTRIM(DTC_NUMNFC),'9','0') "
			cQry += "   AND F2_FILIAL = '"+xFilial("SF2")+"' "
			cQry += "   AND DTC_SERIE = DT6_SERIE "
			cQry += "   AND DTC_DOC = DT6_DOC "
			cQry += "   AND DTC_FILIAL = '  '  "
			cQry += "   AND DT6_NUMVGA IN('"+StrTran(StrTran(StrTran(Alltrim(cNumRomaneio),"/",";")," ",";"),";","','")+"') "
			cQry += "   AND DT6_FILIAL = '  ' "
			cQry += " GROUP BY A3_COD,A3_FORNECE,A3_LOJA,A3_NOME,A3_CC,DT6_VALFAT "
			cQry += " ORDER BY A3_NOME )"
			cQry += " GROUP BY ZR_CODVEND,ZR_CODFORN,ZR_LOJA,ZR_NOME,ZR_CUSTDES )	 "
		Endif
		TCQUERY cQry NEW ALIAS "QZR"
	ElseIf nRefrBox == 5
		cAliasSZR	:= "QZR"
		cQry := ""
		cQry += "SELECT TRIM(SUBSTR(LPAD(ROWNUM,3,'0'),1,3)) ZR_ITEM,"
		cQry += "       ' ' ZR_CODVEND,"
		cQry += "       ' ' ZR_CODFORN,"
		cQry += "       ' ' ZR_LOJA,"
		cQry += "       CTT_DESC01 ZR_NOME,"
		cQry += "       CTT_CUSTO ZR_CUSTDES"
		cQry += "  FROM (SELECT CTT_DESC01,CTT_CUSTO "
		cQry += "          FROM "+RetSqlName("CTT") + " CTT "
		cQry += "         WHERE D_E_L_E_T_ = ' ' "
		cQry += "           AND CTT_BLOQ != '1' "
		If cRatTipo == "N"
			cQry += "           AND ROWNUM = 1 "
		Endif
		cQry += "           AND CTT_CUSTO NOT LIKE '1014%' "
		cQry += "           AND CTT_CLASSE != '1'"
		cQry += "           AND CTT_FILIAL = '"+xFilial("CTT") + "' "
		cQry += "      ORDER BY CTT_CUSTO ) "

		TCQUERY cQry NEW ALIAS "QZR"

	Endif

	DbSelectArea(cAliasSZR)
	DbGotop()
	While !Eof()

		AADD(aCols,Array(Len(aHeader)+1))

		For nI := 1 To Len(aHeader)
			If IsHeadRec(aHeader[nI][2])
				aCols[Len(aCols)][nI] := (cAliasSZR)->ZRRECNO
			ElseIf IsHeadAlias(aHeader[nI][2])
				aCols[Len(aCols)][nI] := "SZR"
			ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
				If FieldPos(aHeader[nI][2]) > 0
					aCols[Len(aCols)][nI] := FieldGet(FieldPos(aHeader[nI][2]))
				Else
					aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
				Endif
			Else
				If aHeader[nI][10] $ "V#M"
					aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
				Else
					aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
				Endif
			Endif
		Next nI
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
		DbSelectArea(cAliasSZR)
		DbSkip()
	Enddo

	(cAliasSZR)->(DbCloseArea())

	If Len(aCols) == 0
		// Se for rateio offline e nใo achou dados, nใo pode retornar
		If cTipOper == "R" .And. lAlteraSZR
			Return .F.
		Endif

		AADD(aCols,Array(Len(aHeader)+1))
		For nColuna := 1 to Len( aHeader )

			If aHeader[nColuna][8] == "C"
				aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
			ElseIf aHeader[nColuna][8] == "D"
				aCols[Len(aCols)][nColuna] := dDataBase
			ElseIf aHeader[nColuna][8] == "M"
				aCols[Len(aCols)][nColuna] := ""
			ElseIf aHeader[nColuna][8] == "N"
				aCols[Len(aCols)][nColuna] := 0
			Else
				aCols[Len(aCols)][nColuna] := .F.
			Endif
			If !Empty(aHeader[nColuna][12])
				aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
			Endif
			If Alltrim(aHeader[nColuna][2]) == "ZR_ITEM"
				aCols[Len(aCols)][nColuna]	:= "001"
			Endif

		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif
	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
	Endif


Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณBFFINM03  บAutor  ณMarcelo A Lauschner บ Data ณ 27/05/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Interface para gera็ใo de tํtulos a pagar por rateio       บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/


User Function  BFFINM03()

	Local	aAreaOld	:= GetArea()
	Local	lCont		:= .T.
	Local	cE2PREFIXO	:= Space(TamSX3("E2_PREFIXO")[1])
	Local	cE2NUM		:= Space(TamSX3("E2_NUM")[1])
	Local	cE2NATUREZ	:= Space(TamSX3("E2_NATUREZ")[1])
	Local	dE2VENCTO	:= dDataBase
	Local	cE2HIST		:= Space(TamSX3("E2_HIST")[1])
	Local	cE2TIPO		:= Space(TamSX3("E2_TIPO")[1])
	Local	lContinua	:= .F.
	Local 	cCampo 		:= ""
	Local	oPerg
	Local	nI
	Local	aGrvSE2
	Private lMsHelpAuto := .F.
	Private lMsErroAuto := .F.


	DEFINE MSDIALOG oPerg FROM 001,001 TO 270,450 OF oMainWnd PIXEL TITLE OemToAnsi("Parโmetros para gera็ใo de Tํtulos a pagar")
	@ 035,010 Say  RetTitle("E2_PREFIXO",30) Of oPerg Pixel
	@ 035,055 MsGet cE2PREFIXO Picture PesqPict("SE2","E2_PREFIXO") Size 60,10 Of oPerg Pixel

	@ 050,010 Say  RetTitle("E2_NUM",30) Of oPerg Pixel
	@ 050,055 MsGet cE2NUM Picture PesqPict("SE2","E2_NUM") Size 60,10 Of oPerg Pixel
	// DbSelectArea("SX3")
	// DbSetOrder(2)
	cCampo := "E2_TIPO"
	@ 065,010 Say  RetTitle("E2_TIPO",30) Of oPerg Pixel
	@ 065,055 MsGet cE2TIPO Picture PesqPict("SE2","E2_TIPO") F3 GetSx3Cache(cCampo,"X3_F3") Size 60,10 Of oPerg Pixel Valid &(GetSx3Cache(cCampo,"X3_VALID")+GetSx3Cache(cCampo,"X3_VLDUSER"))

	// DbSelectArea("SX3")
	// DbSetOrder(2)
	cCampo := "E2_NATUREZ"
	@ 080,010 Say  RetTitle("E2_NATUREZ",30) Of oPerg Pixel
	@ 080,055 MsGet cE2NATUREZ Picture PesqPict("SE2","E2_NATUREZ") F3 GetSx3Cache(cCampo,"X3_F3") Size 60,10 Of oPerg Pixel Valid ExistCpo("SED",cE2NATUREZ) //Valid &(SX3->X3_VALID+SX3->X3_VLDUSER)

	// DbSelectArea("SX3")
	// DbSetOrder(2)
	cCampo := "E2_VENCTO"

	@ 095,010 Say  RetTitle("E2_VENCTO",30) Of oPerg Pixel
	@ 095,055 MsGet dE2VENCTO  Size 60,10 Of oPerg Pixel Valid &(GetSx3Cache(cCampo,"X3_VALID")+GetSx3Cache(cCampo,"X3_VLDUSER"))

	@ 110,010 Say  RetTitle("E2_HIST",30) Of oPerg Pixel
	@ 110,055 MsGet cE2HIST Picture PesqPict("SE2","E2_HIST")Size 60,10 Of oPerg Pixel

	ACTIVATE MSDIALOG oPerg ON INIT EnchoiceBar(oPerg,{|| lContinua	:= .T. /*true*/,oPerg:End()},{|| oPerg:End()},,) CENTERED

	If !lContinua
		RestArea(aAreaOld)
		Return
	Endif


	For nI := 1 To Len(oMulti:aCols)
		DbSelectArea("SA2")
		DbSetOrder(1)
		If DbSeek(xFilial("SA2")+oMulti:aCols[nI,nPxCODFORN]+oMulti:aCols[nI,nPxLOJA])
			IF !oMulti:Acols[nI,Len(oMulti:aHeader)+1] .And. oMulti:Acols[nI,nPxVALRATE] > 0
				aGrvSe2	:=	{	{ "E2_FILIAL"	, xFilial("SE2")								, Nil },;
				{ "E2_PREFIXO"	, cE2PREFIXO													, Nil },;
				{ "E2_NUM"		, cE2NUM														, Nil },;
				{ "E2_TIPO"		, cE2TIPO														, Nil },;
				{ "E2_FORNECE"	, oMulti:aCols[nI,nPxCODFORN]								, Nil },;
				{ "E2_LOJA"   	, oMulti:aCols[nI,nPxLOJA]									, Nil },;
				{ "E2_NOMFOR"	, oMulti:aCols[nI,nPxNOME]									, Nil },;
				{ "E2_NATUREZ"	, cE2NATUREZ													, Nil },;
				{ "E2_EMISSAO"	, dDataBase													, Nil },;
				{ "E2_VENCTO"	, dE2VENCTO													, Nil },;
				{ "E2_VENCORI"	, dE2VENCTO													, Nil },;
				{ "E2_VENCREA"	, DataValida(dE2VENCTO)										, Nil },;
				{ "E2_VALOR"  	, oMulti:aCols[nI,nPxVALRATE]								, Nil },;
				{ "E2_SALDO"  	, oMulti:aCOls[nI,nPxVALRATE]								, Nil },;
				{ "E2_EMIS1"  	, dDataBase													, Nil },;
				{ "E2_MOEDA"	, 1																, Nil },;
				{ "E2_VLCRUZ" 	, xMoeda((oMulti:aCols[nI,nPxVALRATE]),1,1,dDataBase)	, Nil },;
				{ "E2_HIST"   	, cE2HIST														, Nil }}

				//MsExecAuto({ | a,b,c | Fina050(a,b,c) },aGrvSe2,,3)
				//Begin Transaction
				MsExecAuto({ | a,b,c,d,e,f,g | Fina050(a,b,c,d,e,f,g) }, aGrvSe2,, 3,,, .T./*lExibeLanc*/,.T./* lOnline*/ )
				If lMsErroAuto
					MostraErro()
					//DisarmTransaction()
				Endif
				//End Transaction
			Endif
			lMsHelpAuto := .F.
			lMsErroAuto := .F.
		Endif
	Next
	Restarea(aAreaOld)

	MsgAlert("Processo finalizado de grava็a๕ de tํtulos!","T้rmino da grava็ใo!")

Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณBFFINM04  บAutor  ณMarcelo A Lauschner บ Data ณ 27/05/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Fun็ใo gen้rica para validar os Campos da SZR              บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function BFFINM04()

	Local	iX
		
	If ReadVar() == "M->ZR_CODFORN"
		DbSelectArea("SA2")
		DbSetorder(1)
		If DbSeek(xFilial("SA2")+M->ZR_CODFORN+SA2->A2_LOJA)
			oMulti:aCols[oMulti:nAt,nPxLOJA]		:= SA2->A2_LOJA
			oMulti:aCols[oMulti:nAt,nPxNOME]		:= SA2->A2_NOME
			If cRatTipo == "F"
				oMulti:aCols[oMulti:nAt,nPxCUSTDES]	:= SA2->A2_CC
			Endif
		Else
			Return .F.
		Endif
	ElseIf ReadVar() == "M->ZR_LOJA"
		DbSelectArea("SA2")
		DbSetorder(1)
		If DbSeek(xFilial("SA2")+oMulti:aCols[oMulti:nAt,5]+M->ZR_LOJA)
			oMulti:aCols[oMulti:nAt,nPxNOME]		:= SA2->A2_NOME
			If cRatTipo == "F"
				oMulti:aCols[oMulti:nAt,nPxCUSTDES]	:= SA2->A2_CC
			Endif
		Else
			Return .F.
		Endif
	ElseIf ReadVar() == "M->ZR_PERCRAT"
		If oMulti:aCols[oMulti:nAt,nPxDEBCRED] == "D"
			If aTextTotais[2,2] - oMulti:aCols[oMulti:nAt,nPxPERCRAT] + M->ZR_PERCRAT > 100
				MsgAlert("O percentual digitado irแ estourar o limite de 100%","Somat๓ria excede 100%")
				Return .F.
			Endif
			oMulti:aCols[oMulti:nAt,nPxPERCRAT]	:= M->ZR_PERCRAT
			oMulti:aCols[oMulti:nAt,nPxVALRATE]	:= Round(nValRateio * M->ZR_PERCRAT / 100 ,TamSX3("ZR_VALRATE")[2])
		Else

		Endif
	ElseIf ReadVar() == "M->ZR_VALRATE"
		If oMulti:aCols[oMulti:nAt,nPxDEBCRED] == "D"

			If cTipOper == "C"
				nValRateio += M->ZR_VALRATE - oMulti:aCols[oMulti:nAt,nPxVALRATE]
				oMulti:aCols[oMulti:nAt,nPxPERCRAT]	:= Round(M->ZR_VALRATE / nValRateio * 100 ,TamSX3("ZR_PERCRAT")[2])
			Endif

			If aTextTotais[3,2] - oMulti:aCols[oMulti:nAt,nPxVALRATE] + M->ZR_VALRATE > nValRateio
				MsgAlert("O valor digitado irแ estourar o limite do valor a Ratear","Somat๓ria excede o valor a ratear")
				Return .F.
			Endif
			If cTipOper == "D"
				oMulti:aCols[oMulti:nAt,nPxPERCRAT]	:= Round(M->ZR_VALRATE / nValRateio * 100 ,TamSX3("ZR_PERCRAT")[2])
			Endif

			If cTipOper == "R"
				oMulti:aCols[oMulti:nAt,nPxPERCRAT]	:= Round(M->ZR_VALRATE / nValRateio * 100 ,TamSX3("ZR_PERCRAT")[2])
			Endif

			oMulti:aCols[oMulti:nAt,nPxVALRATE]	:= M->ZR_VALRATE


		Else

		Endif
	ElseIf ReadVar() == "M->ZR_CCUSORI"
		DbSelectArea("CTT")
		DbSetorder(1)
		If !DbSeek(xFilial("CTT")+M->ZR_CCUSORI)
			Help(" ",1,"NVAZIO",,"Centro de Custo de Origem nใo existe!",1,11)
			Return .F.
		Else
			If CTT->CTT_CLASSE <> "2"
				Help(" ",1,"NVAZIO",,"Centro de Custo de Origem nใo pode ser Sint้tico",1,11)
				Return .F.
			Endif
		Endif
		If M->ZR_CCUSORI <> cRatOrig .Or. Empty(oMulti:aCols[oMulti:nAt,nPxCCUSORI])

			If MsgYesNo("O Centro de custo digitado ้ diferente do que estแ armazenado no controle da variavel 'cRatOrig'. Deseja aplicar o novo valor para todas as linhas?","Replica็ใo de Centro de Custo")
				For iX := 1 To Len(oMulti:aCols)
					oMulti:aCols[iX,nPxCCUSORI]	:= M->ZR_CCUSORI
					cRatOrig	:= M->ZR_CCUSORI
				Next
				If cTipOper == "R"
					If !sfValData()
						For iX := 1 To Len(oMulti:aCols)
							oMulti:aCols[iX,nPxCCUSORI]	:= " "
							cRatOrig	:= Space(TamSX3("ZR_CCUSORI")[1])
						Next
						Return .F.
					Endif
				Endif
			Else
				Return .F.
			Endif
		Else
			If cTipOper == "R"
				Return sfValData()
			Endif
		Endif
	ElseIf ReadVar() == "M->ZR_CUSTDES"
		DbSelectArea("CTT")
		DbSetorder(1)
		If !DbSeek(xFilial("CTT")+M->ZR_CUSTDES)
			Help(" ",1,"NVAZIO",,"Centro de Custo de destino nใo existe!",1,11)
			Return .F.
		Else
			If CTT->CTT_CLASSE <> "2"
				Help(" ",1,"NVAZIO",,"Centro de Custo de Destino nใo pode ser Sint้tico",1,11)
				Return .F.
			Endif
		Endif
	Endif

	sfAtuDados()

Return .T.



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfVldRatTipoบAutorณMarcelo A Lauschner บ Data ณ 27/05/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Fun็ใo que valida o combobox de Tipo de Rateio por         บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfVldRatTipo

	Local	aHeader	:= {}

	If cRatTipo == "V"
		Processa({|| sfCarrega(@oMulti:aCols,@aHeader,3) },"Localizando registros...")
	ElseIf cRatTipo == "F"
		cEmpOrig 		:= "NA"
		cNumRomaneio	:= Space(100)
		Processa({|| sfCarrega(@oMulti:aCols,@aHeader,2) },"Localizando registros...")
	ElseIf cRatTipo == "C"
		Processa({|| sfCarrega(@oMulti:aCols,@aHeader,5) },"Localizando registros...")
	Endif

	sfAtuDados()


Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfVldEmpOriบAutor ณMarcelo A Lauschner บ Data ณ  27/05/2012 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Valida a origem do rateio de Fretes                        บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfVldEmpOri

	If cEmpOrig <> "NA"
		cRatTipo := "V"
	Else
		sfVldRatTipo()
	Endif

	sfAtuDados()

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfvldNumromบAutor ณMarcelo A Lauschner บ Data ณ 27/05/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Valida o campo N๚mero Romaneio quando for Rateio de frete  บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfVldNumRom

	Local	aHeader		:= {}

	Processa({|| sfCarrega(@oMulti:aCols,@aHeader,4) },"Localizando registros...")

	sfAtuDados(.T.)

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfAtuDadosบAutor  ณMarcelo A Lauschner บ Data ณ 27/05/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Efetua a atualiza็ใo dos Gets na Tela                      บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfAtuDados(lRatMerc)

	Local		nTotMerc	:= 0
	Local		nDecPerc	:= TamSX3("ZR_PERCRAT")[2]
	Local		nDecVlrR	:= TamSX3("ZR_VALRATE")[2]
	Local		iX
	Default	lRatMerc	:= .F.

	aTextTotais[1,2] := 0
	aTextTotais[2,2] := 0
	aTextTotais[3,2] := 0

	For iX := 1 To Len(oMulti:aCols)
		If !(oMulti:aCols[iX,Len(oMulti:aHeader)+1])
			nTotMerc	+= oMulti:aCols[iX,nPxVALMERC]
			aTextTotais[1,2] 	+= oMulti:aCols[iX,nPxVALMERC]
		Endif
	Next

	For iX := 1 To Len(oMulti:aCols)
		If !(oMulti:aCols[iX,Len(oMulti:aHeader)+1])
			If lRatMerc
				oMulti:aCols[iX,nPxPERCRAT]		:= Round(oMulti:aCols[iX,nPxVALMERC] / nTotMerc * 100,nDecPerc)
				oMulti:aCols[iX,nPxVALRATE]  	:= Round(oMulti:aCols[iX,nPxVALORI] * oMulti:aCols[iX,nPxPERCRAT] / 100,nDecVlrR)
			Endif
			If cTipOper == "C"
				oMulti:aCols[iX,nPxPERCRAT]		:= Round(oMulti:aCols[iX,nPxVALRATE] / nValRateio * 100,nDecPerc)
			Endif
			aTextTotais[2,2] 	+= 	oMulti:aCols[iX,nPxPERCRAT]
			aTextTotais[3,2] 	+= oMulti:aCols[iX,nPxVALRATE]
		Endif
	Next

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
	Endif
	oGetTot1:Refresh()
	oGetTot2:Refresh()
	oGetTot3:Refresh()
	oValRateio:Refresh()

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfGrava   บAutor  ณMarcelo A Lauschner บ Data ณ 27/05/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Efetua a grava็ใo dos dados na Base                        บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/


Static Function sfGrava()

	Local nX		:= 0
	Local nI 		:= 0
	Local lGrava	:= .F.
	Local cAlias	:= "SZR"
	Local cItem		:= "001"


	For nX := 1 To Len(oMulti:aCols)
		lGrava	:= .T.
		If cTipOper == "D"
			DbSelectArea("SZR")
			DbSetOrder(2)   // ZR_FILIAL+ZR_KEYSE2
			If DbSeek(xFilial("SZR")+oMulti:aCols[nX,nPxKEYSE2]+oMulti:aCols[nX,nPxITEM])
				lGrava := .F.
			Endif
		Else
			DbSelectArea("SZR")
			DbSetOrder(1)   // ZR_FILIAL+ZR_CODRATE
			If DbSeek(xFilial("SZR")+oMulti:aCols[nX,nPxCODRATE]+oMulti:aCols[nX,nPxITEM])
				lGrava := .F.
			Endif
		Endif
		If (oMulti:Acols[nX,Len(oMulti:aHeader)+1] .And. !lGrava ) .Or. ((cTipOper == "R" .And. oMulti:Acols[nX,nPxPERCRAT] == 0 .And. !lGrava) .Or. (cTipOper # "R" .And. oMulti:Acols[nX,nPxVALRATE] == 0 .And. !lGrava))
			RecLock(cAlias,lGrava)
			( cAlias )->( dbDelete() )
			MsUnlock()
		ElseIf !oMulti:Acols[nX,Len(oMulti:aHeader)+1] .And. (oMulti:Acols[nX,nPxVALRATE] > 0 .Or. (cTipOper == "R" .And. oMulti:Acols[nX,nPxPERCRAT] > 0) )
			RecLock(cAlias,lGrava)
			(cAlias)->ZR_FILIAL := xFilial(cAlias)
			For nI:= 1 to Len(oMulti:aHeader)
				(cAlias)->(FieldPut(FieldPos(Trim(oMulti:aHeader[nI,2])),oMulti:aCols[nX,nI]))
			Next nI
			(cAlias)->ZR_ITEM	:= cItem
			cItem	:= Soma1(cItem)
			MsUnLock()
		Endif
	Next nX

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfValRateioบAutor ณMarcelo A Lauschner บ Data ณ 27/05/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณValida o campo valor a Ratear                               บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfValRateio()

	Local	iX 
	
	aTextTotais[1,2] := 0
	aTextTotais[2,2] := 0
	aTextTotais[3,2] := 0

	For iX := 1 To Len(oMulti:aCols)
		If !(oMulti:aCols[iX,Len(oMulti:aHeader)+1])
			oMulti:aCols[iX,nPxVALORI]		:= nValRateio
			oMulti:aCols[iX,nPxVALRATE]  	:= Round(oMulti:aCols[iX,nPxVALORI] * oMulti:aCols[iX,nPxPERCRAT] / 100,TamSX3("ZR_VALRATE")[2])
			aTextTotais[2,2] 	+= 	oMulti:aCols[iX,nPxPERCRAT]
			aTextTotais[3,2] 	+= oMulti:aCols[iX,nPxVALRATE]
		Endif
	Next

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
	Endif
	oGetTot1:Refresh()
	oGetTot2:Refresh()
	oGetTot3:Refresh()

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณsfValData บAutor  ณMarcelo Lauschner   บ Data ณ  18/08/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Valida as datas, para evitar que seja lan็ado um valor     บฑฑ
ฑฑบ          ณ num intervalo que jแ tenha um rateio cadastrado.           บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function sfValData()

	Local	lRet		:= .T.
	Local	aAreaOld	:= GetArea()
	Local	iX 

	For iX := 1 To Len(oMulti:aCols)
		If !oMulti:Acols[oMulti:nAt,Len(oMulti:aHeader)+1] .And. lRet .And. !Empty(oMulti:aCols[iX,nPxCCUSORI])

			cAliasSZR := GetNextAlias()
			BeginSql Alias cAliasSZR
				//COLUMN E2_VENCORI AS DATE
				SELECT ZR_DTINI,ZR_DTFIM,ZR_CODRATE
				FROM %Table:SZR% SZR
				WHERE ZR_FILIAL = %xFilial:SZR%
				AND ZR_DTINI <= %Exp:dDataFim%
				AND ZR_DTFIM >= %Exp:dDataIni%
				AND ZR_CODRATE != %Exp:cCodSZR%
				AND ZR_CCUSORI = %Exp:oMulti:aCols[iX,nPxCCUSORI]%
				AND ZR_TIPOPER = 'R'
				AND SZR.%NotDel%
			EndSql

			If !Eof()
				Help(" ",1,"NVAZIO",,"Data jแ estแ dentro de outro rateio "+(cAliasSZR)->ZR_CODRATE,1,11)
				lRet	:= .F.
			Endif
			(cAliasSZR)->(DbCloseArea())
		Endif
	Next

	If lRet

		For iX := 1 To Len(oMulti:aCols)
			If !oMulti:Acols[oMulti:nAt,Len(oMulti:aHeader)+1]
				oMulti:aCols[iX,nPxDTINI]	:= dDataIni
				oMulti:aCols[iX,nPxDTFIM] 	:= dDataFim
			Endif
		Next
	Endif

	oMulti:oBrowse:Refresh()


	RestArea(aAreaOld)

Return lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณBFFINM07  บAutor  ณMarcelo Lauschner   บ Data ณ  18/08/12   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Valida linha na tela de rateios                            บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function BFFINM07()

	Local		lRet		:= .T.

	If cTipOper == "R"
		If Empty(oMulti:aCols[oMulti:nAt,nPxCCUSORI]) .And. !oMulti:Acols[oMulti:nAt,Len(oMulti:aHeader)+1]
			lRet	:= .F.
			Help(" ",1,"NVAZIO",,"Centro de Custo de Origem preenchido",1,11)
		ElseIf Substr(oMulti:aCols[oMulti:nAt,nPxCCUSORI],1,6) <> "101410"
			lRet	:= .F.
			Help(" ",1,"NVAZIO",,"Centro de Custo nใo permitido para Rateio",1,11)
		Endif

		If !oMulti:Acols[oMulti:nAt,Len(oMulti:aHeader)+1] .And. Substr(oMulti:aCols[oMulti:nAt,nPxCUSTDES],1,6) == "101410"
			lRet	:= .F.
			Help(" ",1,"NVAZIO",,"Centro de Custo de Destino nใo permitido para Rateio",1,11)
		Endif

	Endif

Return lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณBFFINM08  บAutor  ณMarcelo A Lauschner บ Data ณ 19/08/2012  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณValida a tela de rateios                                    บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function BFFINM08

	Local		lRet		:= .T.
	Local		iX 

	If cTipOper $ "D#R" .And. aTextTotais[2,2] < 99.91 .And. aTextTotais[2,2] > 0
		MsgAlert("O percentual de rateio nใo estแ em 100%. Portanto nใo ้ permitido fazer o rateio!!","Percentual incompleto!")
		lRet	:= .F.
	Endif

	If cTipOper == "R"
		For iX := 1 To Len(oMulti:aCols)
			If !oMulti:Acols[iX,Len(oMulti:aHeader)+1]
				If Empty(oMulti:aCols[iX,nPxCCUSORI]) .And. !oMulti:Acols[iX,Len(oMulti:aHeader)+1]
					lRet	:= .F.
					Help(" ",1,"NVAZIO",,"Centro de Custo de Origem preenchido",1,11)
					Exit
				ElseIf Substr(oMulti:aCols[iX,nPxCCUSORI],1,6) <> "101410"
					lRet	:= .F.
					Help(" ",1,"NVAZIO",,"Centro de Custo nใo permitido para Rateio",1,11)
					Exit
				Endif

				If !oMulti:Acols[iX,Len(oMulti:aHeader)+1] .And. Substr(oMulti:aCols[iX,nPxCUSTDES],1,6) == "101410"
					lRet	:= .F.
					Help(" ",1,"NVAZIO",,"Centro de Custo de Destino nใo permitido para Rateio",1,11)
					Exit
				Endif
			Endif
		Next
	Endif

Return lRet



User Function BFFINM09

	Local	lContinua	:= .F.
	Local	cNewCodRat	:= ""
	Local	oPerg

	// For็o o ajuste do controle de numera็ใo dos rateios, para que cada lan็amento tenha um c๓digo
	DbSelectArea("SZR")
	DbSetOrder(1)
	Do While .T.
		cNewCodRat		:= GetSXENum("SZR","ZR_CODRATE")
		If !dbSeek( xFilial( "SZR" ) + cNewCodRat )
			RollBackSX8()
			Exit
		EndIf
		If __lSx8
			ConfirmSx8()
		EndIf
	EndDo


	DEFINE MSDIALOG oPerg FROM 001,001 TO 150,350 OF oMainWnd PIXEL TITLE OemToAnsi("C๓pia de rateio")
	@ 015,010 Say "Este c๓digo serแ atribuido ao lan็amento na tela"
	@ 024,010 Say "Nใo irแ alterar nada do Rateio anterior"
	@ 045,010 Say "C๓d.Rateio" Of oPerg Pixel
	@ 045,045 MsGet cNewCodRat Picture "@!" Size 60,10 F3 "SZR" Of oPerg Pixel When .F.

	ACTIVATE MSDIALOG oPerg ON INIT EnchoiceBar(oPerg,{|| lContinua	:= .T. /*true*/,oPerg:End()},{|| oPerg:End()},,) CENTERED

	If lContinua

		DbSelectArea("SZR")
		DbSetOrder(1)
		Do While .T.
			cNewCodRat		:= GetSXENum("SZR","ZR_CODRATE")
			If !dbSeek( xFilial( "SZR" ) + cNewCodRat )
				RollBackSX8()
				Exit
			EndIf
			If __lSx8
				ConfirmSx8()
			EndIf
		EndDo
		If __lSx8
			ConfirmSx8()
		EndIf

		cCodSZR	:= cNewCodRat

		For iX := 1 To Len(oMulti:aCols)
			oMulti:aCols[iX,nPxCODRATE]		:= cCodSZR
			oMulti:aCols[iX,nPxCCUSORI] 	:= Space(TamSX3("ZR_CCUSORI")[1])
		Next
		MsgAlert("Novo c๓digo de rateio atribuํdo.","C๓pia de rateio!")
	Endif

Return


User Function BFFINM10

	Local	aList1	:= {}
	Local	aList2	:= {}
	Local	aList3	:= {}
	Local	aList4	:= {}
	Local	aList5 	:= {}
	Local	cCcSup	:= ""
	Local	iX
	Local	cQry 
	Local	nPos
	

	For iX := 1 To Len(oMulti:aCols)
		If !oMulti:Acols[iX,Len(oMulti:aHeader)+1]
			DbSelectArea("CTT")
			DbSetorder(1)
			If DbSeek(xFilial("CTT")+oMulti:aCols[iX,nPxCUSTDES])
				cCcSup	:= CTT->CTT_CCSUP
				DbSelectArea("CTT")
				DbSetorder(1)
				If DbSeek(xFilial("CTT")+cCcSup)
					nPos := aScan(aList5,{|x| x[1] == Alltrim(CTT->CTT_CUSTO)})
					If nPos == 0
						cQry := "SELECT COUNT(*) NCCSUP "
						cQry += "  FROM "+RetSqlName("CTT")
						cQry += " WHERE D_E_L_E_T_ = ' ' "
						cQry += "   AND CTT_CUSTO LIKE '"+Alltrim(CTT->CTT_CUSTO)+"%' "
						cQry += "   AND CTT_CLASSE = '2' "
						cQry += "   AND CTT_FILIAL = '"+xFilial("CTT")+"' "
						TCQUERY cQry NEW ALIAS "QCTT"

						Aadd(aList5,{Alltrim(CTT->CTT_CUSTO),Alltrim(CTT->CTT_DESC01),oMulti:aCols[iX,nPxPERCRAT],1,QCTT->NCCSUP})
						QCTT->(DbCloseArea())
					Else
						aList5[nPos,3] += oMulti:aCols[iX,nPxPERCRAT]
						aList5[nPos,4]++
					Endif
					cCcSup	:= CTT->CTT_CCSUP
					DbSelectArea("CTT")
					DbSetorder(1)
					If DbSeek(xFilial("CTT")+cCcSup)
						nPos := aScan(aList4,{|x| x[1] == Alltrim(CTT->CTT_CUSTO)})
						If nPos == 0
							cQry := "SELECT COUNT(*) NCCSUP "
							cQry += "  FROM "+RetSqlName("CTT")
							cQry += " WHERE D_E_L_E_T_ = ' ' "
							cQry += "   AND CTT_CUSTO LIKE '"+Alltrim(CTT->CTT_CUSTO)+"%' "
							cQry += "   AND CTT_CLASSE = '2' "
							cQry += "   AND CTT_FILIAL = '"+xFilial("CTT")+"' "
							TCQUERY cQry NEW ALIAS "QCTT"
							Aadd(aList4,{Alltrim(CTT->CTT_CUSTO),Alltrim(CTT->CTT_DESC01),oMulti:aCols[iX,nPxPERCRAT],1,QCTT->NCCSUP})
							QCTT->(DbCloseArea())
						Else
							aList4[nPos,3] += oMulti:aCols[iX,nPxPERCRAT]
							aList4[nPos,4]++
						Endif
						cCcSup	:= CTT->CTT_CCSUP
						DbSelectArea("CTT")
						DbSetorder(1)
						If DbSeek(xFilial("CTT")+cCcSup)
							nPos := aScan(aList3,{|x| x[1] == Alltrim(CTT->CTT_CUSTO)})
							If nPos == 0
								cQry := "SELECT COUNT(*) NCCSUP "
								cQry += "  FROM "+RetSqlName("CTT")
								cQry += " WHERE D_E_L_E_T_ = ' ' "
								cQry += "   AND CTT_CUSTO LIKE '"+Alltrim(CTT->CTT_CUSTO)+"%' "
								cQry += "   AND CTT_CLASSE = '2' "
								cQry += "   AND CTT_FILIAL = '"+xFilial("CTT")+"' "
								TCQUERY cQry NEW ALIAS "QCTT"
								Aadd(aList3,{Alltrim(CTT->CTT_CUSTO),Alltrim(CTT->CTT_DESC01),oMulti:aCols[iX,nPxPERCRAT],1,QCTT->NCCSUP})
								QCTT->(DbCloseArea())
							Else
								aList3[nPos,3] += oMulti:aCols[iX,nPxPERCRAT]
								aList3[nPos,4]++
							Endif
							cCcSup	:= CTT->CTT_CCSUP
							DbSelectArea("CTT")
							DbSetorder(1)
							If DbSeek(xFilial("CTT")+cCcSup)
								nPos := aScan(aList2,{|x| x[1] == Alltrim(CTT->CTT_CUSTO)})
								If nPos == 0
									cQry := "SELECT COUNT(*) NCCSUP "
									cQry += "  FROM "+RetSqlName("CTT")
									cQry += " WHERE D_E_L_E_T_ = ' ' "
									cQry += "   AND CTT_CUSTO LIKE '"+Alltrim(CTT->CTT_CUSTO)+"%' "
									cQry += "   AND CTT_CLASSE = '2' "
									cQry += "   AND CTT_FILIAL = '"+xFilial("CTT")+"' "
									TCQUERY cQry NEW ALIAS "QCTT"
									Aadd(aList2,{Alltrim(CTT->CTT_CUSTO),Alltrim(CTT->CTT_DESC01),oMulti:aCols[iX,nPxPERCRAT],1,QCTT->NCCSUP})
									QCTT->(DbCloseArea())
								Else
									aList2[nPos,3] += oMulti:aCols[iX,nPxPERCRAT]
									aList2[nPos,4]++
								Endif
								cCcSup	:= CTT->CTT_CCSUP
								DbSelectArea("CTT")
								DbSetorder(1)
								If DbSeek(xFilial("CTT")+cCcSup)
									nPos := aScan(aList1,{|x| x[1] == Alltrim(CTT->CTT_CUSTO)})
									If nPos == 0
										cQry := "SELECT COUNT(*) NCCSUP "
										cQry += "  FROM "+RetSqlName("CTT")
										cQry += " WHERE D_E_L_E_T_ = ' ' "
										cQry += "   AND CTT_CUSTO LIKE '"+Alltrim(CTT->CTT_CUSTO)+"%' "
										cQry += "   AND CTT_CLASSE = '2' "
										cQry += "   AND CTT_FILIAL = '"+xFilial("CTT")+"' "
										TCQUERY cQry NEW ALIAS "QCTT"
										Aadd(aList1,{Alltrim(CTT->CTT_CUSTO),Alltrim(CTT->CTT_DESC01),oMulti:aCols[iX,nPxPERCRAT],1,QCTT->NCCSUP})
										QCTT->(DbCloseArea())
									Else
										aList1[nPos,3] += oMulti:aCols[iX,nPxPERCRAT]
										aList1[nPos,4]++
									Endif
								Endif
							Endif
						Endif
					Endif
				Endif
			Endif

		Endif
	Next

	DEFINE MSDIALOG oRatSum FROM 001,001 TO 550,1220 OF oMainWnd PIXEL TITLE OemToAnsi("Demonstrativo do Rateio por contas Sint้ticas")

	@ 015,005 LISTBOX oList1 FIELDS TITLE OemtoAnsi("Conta"),OemtoAnsi("Empresa"),OemToAnsi("Soma %"),OemToAnsi("N.Linhas"),OemToAnsi("N.CCusto") SIZE 300,70 PIXEL
	oList1:SetArray(aList1)
	oList1:bLine := {|| aList1[oList1:nAt] }

	@ 015,310 LISTBOX oList2 FIELDS TITLE OemtoAnsi("Conta"),OemtoAnsi("Opera็ใo"),OemToAnsi("Soma %"),OemToAnsi("N.Linhas"),OemToAnsi("N.CCusto") SIZE 300,70 PIXEL
	oList2:SetArray(aList2)
	oList2:bLine := {|| aList2[oList2:nAt] }

	@ 090,005 LISTBOX oList3 FIELDS TITLE OemtoAnsi("Conta"),OemtoAnsi("Estado"),OemToAnsi("Soma %"),OemToAnsi("N.Linhas"),OemToAnsi("N.CCusto") SIZE 300,70 PIXEL
	oList3:SetArray(aList3)
	oList3:bLine := {|| aList3[oList3:nAt] }

	@ 090,310 LISTBOX oList4 FIELDS TITLE OemtoAnsi("Conta"),OemtoAnsi("Departamento"),OemToAnsi("Soma %"),OemToAnsi("N.Linhas"),OemToAnsi("N.CCusto") SIZE 300,70 PIXEL
	oList4:SetArray(aList4)
	oList4:bLine := {|| aList4[oList4:nAt] }

	@ 165,005 LISTBOX oList5 FIELDS TITLE OemtoAnsi("Conta"),OemtoAnsi("Supervisor"),OemToAnsi("Soma %"),OemToAnsi("N.Linhas"),OemToAnsi("N.CCusto") SIZE 605,100 PIXEL
	oList5:SetArray(aList5)
	oList5:bLine := {|| aList5[oList5:nAt] }





	ACTIVATE MSDIALOG oRatSum ON INIT EnchoiceBar(oRatSum,{|| lContinua	:= .T. /*true*/,oRatSum:End()},{|| oRatSum:End()},,) CENTERED


Return

