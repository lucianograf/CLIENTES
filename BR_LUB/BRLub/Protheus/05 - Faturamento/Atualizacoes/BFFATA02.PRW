#include "topconn.ch"
#include "protheus.ch"

/*/{Protheus.doc} BFFATA02
(Consulta de produtos em movimentacao de comodatos Filtra entradas e saidas , listando como Kardex CC e RC    )
@author MarceloLauschner
@since 01/11/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA02()

	Local	cQry
	Local	aCpPer  	:= Array(4,4)
	Local	cNomeArq
	Local	aArray 		:= {}
	Private cCadastro  	:= OemToAnsi("Visualização de Cadastro de Produtos")
	Private aRotina    	:= { {OemToAnsi("Pesquisar"),'ExecBlock("BFFATA05",.F.,.T.)',0,1} ,;
		{OemToAnsi("Cadastro"),'ExecBlock("BFFATA03",.F.,.T.)',0,3},;
		{OemToAnsi("Histórico"),'ExecBlock("BFFATA04",.F.,.T.)',0,2},;
		{OemToAnsi("Consulta"),'ExecBlock("BFFATA06",.F.,.T.)',0,2}}

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()


	sfCreateTbl()

	DbSelectArea("SX3")
	DbSetOrder(2)
	DbSeek("B1_COD")

	cCampo1 := "B1_COD"
	cCampo2 := "B1_DESC"
	cCampo3 := "B2_QATU"
	cCampo4 := "B2_USAI"

	Aadd(aCpPer,{GetSx3Cache(cCampo1,"X3_CAMPO")		,;
		GetSx3Cache(cCampo1,"X3_TIPO")		,;
		GetSx3Cache(cCampo1,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo1,"X3_DECIMAL")	})

	Aadd(aCpPer,{GetSx3Cache(cCampo2,"X3_CAMPO")		,;
		GetSx3Cache(cCampo2,"X3_TIPO")		,;
		GetSx3Cache(cCampo2,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo2,"X3_DECIMAL")	})

	Aadd(aCpPer,{GetSx3Cache(cCampo3,"X3_CAMPO")		,;
		GetSx3Cache(cCampo3,"X3_TIPO")		,;
		GetSx3Cache(cCampo3,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo3,"X3_DECIMAL")	})

	Aadd(aCpPer,{GetSx3Cache(cCampo4,"X3_CAMPO")		,;
		GetSx3Cache(cCampo4,"X3_TIPO")		,;
		GetSx3Cache(cCampo4,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo4,"X3_DECIMAL")	})


	If(Select("TRB")<>0)
		dbSelectArea ( "TRB" )
		dbCloseArea ()
	End

	//cNomeArq := CriaTrab ( aCpPer )

	//dbUseArea ( .T.,, cNomeArq, "TRB", NIL, .F. )
	cAlias := "TRB"
	oTmpTable := FWTemporaryTable():New(cAlias,aCpPer)
	oTmpTable:Create()
	dbSelectArea(cAlias)

	IndRegua("TRB",cNomeArq,"B1_COD",,,"Selecionando Registros...")

	cQry := "SELECT B1_COD,B1_DESC,SUM(QTE) QTE,MAX(USAI) USAI "
	cQry += "  FROM ( "
	cQry += "SELECT B1_COD,B1_DESC,F4_XTPMOV,SUM(D1_QUANT) QTE,MAX(D1_DTDIGIT) USAI "
	cQry += "  FROM "+RetSqlName("SB1")+ " B1,"+RetSqlName("SD1")+" D1,"+RetSqlName("SF4")+" F4 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = D1_COD "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "   AND D1.D_E_L_E_T_ = ' ' "
	cQry += "   AND D1_DTDIGIT >='20120101' "
	cQry += "   AND D1_TES = F4_CODIGO "
	cQry += "   AND D1_FILIAL = '"+xFilial("SD1")+"' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_XTPMOV IN('CC','DT','TA') "
	cQry += "   AND F4_ESTOQUE = 'N' "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	cQry += " GROUP BY B1_COD,B1_DESC,F4_XTPMOV "
	cQry += "UNION ALL "
	cQry += "SELECT B1_COD,B1_DESC,F4_XTPMOV,SUM(D2_QUANT)*-1 QTE,MAX(D2_EMISSAO) USAI "
	cQry += "  FROM "+RetSqlName("SB1")+" B1,"+RetSqlName("SD2")+" D2,"+RetSqlName("SF4")+" F4 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = D2_COD "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "   AND D2.D_E_L_E_T_ = ' ' "
	cQry += "   AND D2_TES = F4_CODIGO "
	cQry += "   AND D2_EMISSAO >='20120101' "
	cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_XTPMOV IN('RC','TA') "
	cQry += "   AND F4_ESTOQUE = 'N' "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	cQry += " GROUP BY B1_COD,B1_DESC,F4_XTPMOV  "
	cQry += "UNION ALL "
	cQry += "SELECT CMC_CODIGO,B1_DESC,'AC' F4_XTPMOV,SUM(CMC_QUANT)*-1 QTE,MAX(CMC_DATA) USAI "
	cQry += "  FROM BIGFORTA.CONDOR_MOV_COMODATO A,"+RetSqlName("SB1")+" B1 "
	cQry += " WHERE CMC_EMP = '"+cEmpAnt+"' "
	cQry += "   AND CMC_FIL = '"+cFilAnt+"' "
	cQry += "   AND CMC_TPMOV ='S' "
	cQry += "   AND D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = CMC_CODIGO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += " GROUP BY CMC_CODIGO,B1_DESC,3  "
	cQry += "UNION ALL "
	cQry += "SELECT CMC_CODIGO,B1_DESC,'AC' F4_XTPMOV,SUM(CMC_QUANT) QTE,MAX(CMC_DATA) USAI "
	cQry += "  FROM BIGFORTA.CONDOR_MOV_COMODATO A,"+RetSqlName("SB1")+" B1 "
	cQry += " WHERE CMC_EMP = '"+cEmpAnt+"' "
	cQry += "   AND CMC_FIL = '"+cFilAnt+"' "
	cQry += "   AND CMC_TPMOV ='E' "
	cQry += "   AND D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = CMC_CODIGO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += " GROUP BY CMC_CODIGO,B1_DESC,3) "
	cQry += " GROUP BY B1_COD,B1_DESC "

	MemoWrite("log_rdmakes\BFFATA02.SQL",cQry)
	TcQuery cQry NEW ALIAS "QRY"

	While !Eof()

		DbSelectarea("TRB")
		Reclock("TRB",.T.)
		TRB->B1_COD  	:= QRY->B1_COD
		TRB->B1_DESC  	:= QRY->B1_DESC
		TRB->B2_QATU	:= QRY->QTE
		TRB->B2_USAI	:= STOD(QRY->USAI)
		MsUnlock()
		DbSelectArea("QRY")
		DbSkip()
	Enddo
	QRY->(DbCloseArea())

	dbSelectArea("TRB")
	dbSetorder(1)

	DbSelectArea("SX3")
	DbSetOrder(2)

	Aadd(aArray,{GetSx3Cache(cCampo1,"X3_CAMPO")		,;
		GetSx3Cache(cCampo1,"X3_TIPO")		,;
		GetSx3Cache(cCampo1,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo1,"X3_DECIMAL")	})

	Aadd(aArray,{GetSx3Cache(cCampo2,"X3_CAMPO")		,;
		GetSx3Cache(cCampo2,"X3_TIPO")		,;
		GetSx3Cache(cCampo2,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo2,"X3_DECIMAL")	})

	Aadd(aArray,{GetSx3Cache(cCampo3,"X3_CAMPO")		,;
		GetSx3Cache(cCampo3,"X3_TIPO")		,;
		GetSx3Cache(cCampo3,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo3,"X3_DECIMAL")	})

	Aadd(aArray,{GetSx3Cache(cCampo4,"X3_CAMPO")		,;
		GetSx3Cache(cCampo4,"X3_TIPO")		,;
		GetSx3Cache(cCampo4,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo4,"X3_DECIMAL")	})

	mBrowse(06, 01, 22, 75, "TRB", aArray,,,,1)

	TRB->(DbCloseArea())
	FErase(cNomeArq + GetDbExtension()) // Deleting file
	FErase(cNomeArq + OrdBagExt()) // Deleting index

Return

/*/{Protheus.doc} BFFATA03
(Chamada para consulta do Cadastro do Produto )
@author MarceloLauschner
@since 01/11/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA03()

	Local	aAreaOld	:= GetArea()

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+TRB->B1_COD)

	A010Visul("SB1",SB1->(Recno()),2)

	RestArea(aAreaOld)

Return



/*/{Protheus.doc} BFFATA04
(Chamada para consulta do Kardex Comodato do Produto )
@author MarceloLauschner
@since 01/11/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA04()

	Local	aAreaOld	:= GetArea()
	Local	cQry
	Local	cCodProd	:= TRB->B1_COD
	Private oMovim
	Private	aMovim		:= {}

	cQry := "SELECT B1_COD,B1_DESC,ENT_SAIDA,D1_TES,D1_CF,QTE,USAI,ENTIDADE,DOC,CHAVE_NF,TIPO_MOV,"
	cQry += "       SUM(CASE WHEN ENT_SAIDA = 'ENTRADA' THEN QTE ELSE QTE * -1 END) OVER(ORDER BY ROWNUM) SALDO  "
	cQry += "  FROM ( "
	cQry += "SELECT 'ENTRADA' ENT_SAIDA,B1_COD,B1_DESC,D1_TES,D1_CF,D1_QUANT QTE,F4_XTPMOV || '-' || X5_DESCRI TIPO_MOV,"
	cQry += "       D1_DTDIGIT USAI, D1_DTDIGIT || 'E',A2_COD||'/'||A2_LOJA ||'-'||A2_NOME ENTIDADE, "
	cQry += "       D1_SERIE || '/' || D1_DOC DOC ,'E'||D1_FILIAL||D1_DOC||D1_SERIE||D1_FORNECE||D1_LOJA||D1_TIPO CHAVE_NF "
	cQry += "  FROM "+RetSqlName("SB1")+ " B1,"+RetSqlName("SD1") + " D1,"+RetSqlName("SF4")+" F4, "+RetSqlName("SA2")+" A2, "+RetSqlName("SX5")+" X5 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = D1_COD "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "   AND X5.D_E_L_E_T_ = ' ' "
	cQry += "   AND X5_CHAVE = F4_XTPMOV "
	cQry += "   AND X5_TABELA = 'DJ' "
	cQry += "   AND X5_FILIAL = '"+xFilial("SX5") + "' "
	cQry += "   AND A2.D_E_L_E_T_ = ' ' "
	cQry += "   AND A2_LOJA = D1_LOJA "
	cQry += "   AND A2_COD = D1_FORNECE "
	cQry += "   AND A2_FILIAL = '"+xFilial("SA2")+"' "
	cQry += "   AND D1.D_E_L_E_T_ = ' ' "
	cQry += "   AND D1_TES = F4_CODIGO "
	cQry += "   AND D1_TIPO  = 'N' "
	cQry += "   AND D1_DTDIGIT >='20120101' "
	cQry += "   AND D1_FILIAL = '"+xFilial("SD1")+"' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_XTPMOV IN('CC','TA','DT') "
	cQry += "   AND B1_COD ='"+cCodProd+"' "
	cQry += "   AND F4_ESTOQUE = 'N' "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	cQry += "UNION ALL "
	cQry += "SELECT 'ENTRADA' ENT_SAIDA,B1_COD,B1_DESC,D1_TES,D1_CF,D1_QUANT QTE,F4_XTPMOV || '-' || X5_DESCRI TIPO_MOV,"
	cQry += "       D1_DTDIGIT USAI, D1_DTDIGIT || 'E',A1_COD||'/'||A1_LOJA ||'-'||A1_NOME ENTIDADE, "
	cQry += "       D1_SERIE || '/' || D1_DOC DOC ,'E'||D1_FILIAL||D1_DOC||D1_SERIE||D1_FORNECE||D1_LOJA||D1_TIPO CHAVE_NF "
	cQry += "  FROM "+RetSqlName("SB1")+ " B1,"+RetSqlName("SD1") + " D1,"+RetSqlName("SF4")+" F4, "+RetSqlName("SA1")+" A1, "+RetSqlName("SX5")+" X5 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = D1_COD "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "   AND X5.D_E_L_E_T_ = ' ' "
	cQry += "   AND X5_CHAVE = F4_XTPMOV "
	cQry += "   AND X5_TABELA = 'DJ' "
	cQry += "   AND X5_FILIAL = '"+xFilial("SX5") + "' "
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_LOJA = D1_LOJA "
	cQry += "   AND A1_COD = D1_FORNECE "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND D1.D_E_L_E_T_ = ' ' "
	cQry += "   AND D1_TES = F4_CODIGO "
	cQry += "   AND D1_TIPO IN('D','B') "
	cQry += "   AND D1_DTDIGIT >='20120101' "
	cQry += "   AND D1_FILIAL = '"+xFilial("SD1")+"' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_XTPMOV IN('CC','TA','DT') "
	cQry += "   AND B1_COD ='"+cCodProd+"' "
	cQry += "   AND F4_ESTOQUE = 'N' "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	cQry += "UNION ALL "
	cQry += "SELECT 'SAIDA' ENT_SAIDA,B1_COD,B1_DESC,D2_TES,D2_CF,D2_QUANT QTE,F4_XTPMOV || '-' || X5_DESCRI TIPO_MOV,"
	cQry += "       D2_EMISSAO USAI,D2_EMISSAO || 'S',A1_COD||'/'||A1_LOJA ||'-'||A1_NOME ENTIDADE, "
	cQry += "       D2_SERIE || '/' || D2_DOC DOC,'S'||D2_FILIAL||D2_DOC||D2_SERIE||D2_CLIENTE||D2_LOJA CHAVE_NF "
	cQry += "  FROM "+RetSqlName("SB1")+ " B1,"+RetSqlName("SD2") + " D2,"+RetSqlName("SF4")+" F4, "+RetSqlName("SA1")+" A1, "+RetSqlName("SX5")+" X5 "
	cQry += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD = D2_COD "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "   AND X5.D_E_L_E_T_ = ' ' "
	cQry += "   AND X5_CHAVE = F4_XTPMOV "
	cQry += "   AND X5_TABELA = 'DJ' "
	cQry += "   AND X5_FILIAL = '"+xFilial("SX5") + "' "
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_LOJA = D2_LOJA "
	cQry += "   AND A1_COD = D2_CLIENTE "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND D2.D_E_L_E_T_ = ' ' "
	cQry += "   AND D2_TES = F4_CODIGO "
	cQry += "   AND D2_EMISSAO >='20120101' "
	cQry += "   AND B1_COD ='"+cCodProd+"' "
	cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_XTPMOV IN('RC','TA') "
	cQry += "   AND F4_ESTOQUE = 'N' "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	cQry += "UNION ALL "
	cQry += "SELECT 'SAIDA' ENT_SAIDA,CMC_CODIGO,B1_DESC,'RAC','5999',CMC_QUANT QTE,'XX-ACERTO ESTOQUE SAIDA' TIPO_MOV,"
	cQry += "       CMC_DATA USAI,CMC_DATA || 'S','000000/00-AJUSTE DE SAIDA COMODATO' ENTIDADE,"
	cQry += "       'Z/ZZZZZZ' DOC,'A' CHAVE_NF "
	cQry += "  FROM BIGFORTA.CONDOR_MOV_COMODATO A,"+RetSqlName("SB1")+" B1 "
	cQry += " WHERE CMC_EMP = '"+cEmpAnt+"' "
	cQry += "   AND CMC_FIL = '"+cFilAnt+"' "
	cQry += "   AND CMC_TPMOV = 'S' "
	cQry += "   AND D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD ='"+cCodProd+"' "
	cQry += "   AND B1_COD = CMC_CODIGO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += "UNION ALL "
	cQry += "SELECT 'ENTRADA' ENT_SAIDA,CMC_CODIGO,B1_DESC,'EAC','1999',CMC_QUANT QTE,'XX-ACERTO ESTOQUE ENTRADA' TIPO_MOV,"
	cQry += "       CMC_DATA USAI,CMC_DATA || 'E','000000/00-AJUSTE DE ENTRADA COMODATO' ENTIDADE,"
	cQry += "       'Z/ZZZZZZ' DOC,'A' CHAVE_NF "
	cQry += "  FROM BIGFORTA.CONDOR_MOV_COMODATO A,"+RetSqlName("SB1")+" B1 "
	cQry += " WHERE CMC_EMP = '"+cEmpAnt+"' "
	cQry += "   AND CMC_FIL = '"+cFilAnt+"' "
	cQry += "   AND CMC_TPMOV = 'E' "
	cQry += "   AND D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_COD ='"+cCodProd+"' "
	cQry += "   AND B1_COD = CMC_CODIGO "
	cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQry += " ORDER BY 8  "
	cQry += " ) "

	MemoWrite("log_rdmakes\BFFATA02A.SQL",cQry)

	TcQuery cQry NEW ALIAS "QRY"

	While !Eof()

		Aadd(aMovim,{STOD(QRY->USAI),;
			QRY->ENTIDADE,;
			QRY->DOC,;
			QRY->D1_TES,;
			QRY->D1_CF,;
			QRY->QTE,;
			QRY->SALDO,;
			QRY->CHAVE_NF,;
			QRY->TIPO_MOV })

		DbSelectArea("QRY")
		DbSkip()
	Enddo
	QRY->(DbCloseArea())


	DEFINE MSDIALOG oDlgKd From 000,000 To 365,1200 Of oMainWnd Pixel Title OemToAnsi("Kardex das movimentações de Comodato do Produto '"+TRB->B1_COD+"-"+TRB->B1_DESC)
	If Len(aMovim) == 0
		aMovim := {{CTOD(""),"","","",0,0}}
	Endif
	@ 005,005 LISTBOX oMovim FIELDS TITLE ;
		OemtoAnsi("Data Movimento"),;
		OemToAnsi("Fornecedor/Cliente"),;
		OemToAnsi("Série/Num Nf"),;
		OemtoAnsi("Código TES"),;
		OemToAnsi("CFOP"),;
		OemToAnsi("Quantidade"),;
		OemToAnsi("Saldo "),;
		OemToAnsi("Chave NF"),;
		OemToAnsi("Tipo Movimentação") SIZE 590,160 PIXEL
	oMovim:SetArray(aMovim)
	oMovim:bLine := {|| aMovim[oMovim:nAt] }

	DEFINE SBUTTON FROM 170,260 TYPE 1 PIXEL ACTION (oDlgKd:End()) ENABLE OF oDlgKd Pixel
	@170,290 Button "Visualiza Nota" ACTION sfViewNF() of oDlgKd Pixel

	ACTIVATE MSDIALOG oDlgKd CENTERED

	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfViewNF
(Visualiza a nota de entrada ou saida        )
@author MarceloLauschner
@since  01/11/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfViewNF()

	Local	aAreaOld	:= GetArea()

	If Substr(aMovim[oMovim:nAt,8],1,1) == "E"
		DbSelectArea("SF1")
		DbSetOrder(1)
		If DbSeek(Substr(aMovim[oMovim:nAt,8],2))
			cBkMod	:= cModulo
			nBkMod	:= nModulo
			cModulo	:= "COM"
			nModulo	:= 02
			Mata103( , , 2 ,)
			cModulo	:= cBkMod
			nModulo := nBkMod
		Endif
	ElseIf Substr(aMovim[oMovim:nAt,8],1,1) == "S"
		DbSelectArea("SF2")
		DbSetOrder(1)
		If DbSeek(Substr(aMovim[oMovim:nAt,8],2))
			Mc090Visual("SF2",SF2->(Recno()),2)
		Endif
	Endif

	RestArea(aAreaOld)

Return


/*/{Protheus.doc} BFFATA05
(Auxilia pesquisa com F3 padrão para uso em Browse Query  )
@author MarceloLauschner
@since 01/11/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA05()

	Local	cGetPesq		:= Space(TamSX3("B1_COD")[1])
	Local	lContinua		:= .F.

	DEFINE MSDIALOG oPerg FROM 001,001 TO 150,350 OF oMainWnd PIXEL TITLE OemToAnsi("Pesquisa produtos")

	@ 020,010 Say "Código a pesquisar" Of oPerg Pixel
	@ 020,055 MsGet cGetPesq Picture "@!" Size 60,10 F3 "SB1" Of oPerg Pixel

	ACTIVATE MSDIALOG oPerg ON INIT EnchoiceBar(oPerg,{|| lContinua	:= .T. /*true*/,oPerg:End()},{|| oPerg:End()},,) CENTERED

	If lContinua
		DbSelectArea("TRB")
		DbSetOrder(1)
		DbSeek(cGetPesq)
	Endif

Return


/*/{Protheus.doc} sfCreateTbl
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCreateTbl()

	Local	cQry	:= ""

	cQry := "SELECT NVL(COUNT(*),0) NREG "
	cQry += "  FROM USER_TABLES "
	cQry += " WHERE TABLE_NAME = 'CONDOR_MOV_COMODATO' "

	TCQUERY cQry NEW ALIAS "QRLG"

	If QRLG->NREG == 0

		cQry := 'CREATE TABLE "BIGFORTA"."CONDOR_MOV_COMODATO" '
		cQry += '  ("CMC_EMP" 		CHAR(2) NOT NULL,'
		cQry += '	"CMC_FIL"		CHAR(2) NOT NULL,'
		cQry += '	"CMC_CODIGO" 	CHAR(15) NOT NULL,'
		cQry += '	"CMC_DESCRI"	CHAR(50) NOT NULL,'
		cQry += '   "CMC_QUANT"     NUMBER NOT NULL,'
		cQry += '   "CMC_DATA"      CHAR(8) NOT NULL,'
		cQry += '   "CMC_TPMOV"     CHAR(1) NOT NULL)'
		cQry += '    TABLESPACE "BIG_D" '

		TcSQLExec(cQry)

	Endif
	QRLG->(DbCloseArea())


Return



/*/{Protheus.doc} BFFATA06
(long_description)
@author MarceloLauschner
@since 29/09/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA06()

	Local		aAreaOld	:= GetArea()

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+TRB->B1_COD)

	If Type("aRotina") <> "A"
		aRotina   := {{ ,"A103NFiscal", 0, 2}}
	Endif

	MaComView(SB1->B1_COD)

	RestArea(aAreaOld)

Return

