#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} RLFATA04
Função para conferência de notas fiscais - clientes Redelog - Operação logística
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
User Function RLFATA04()

	Local 	lContinua	:= .T.
	Local 	cSenhaAtu	:= GetNewPar("RL_PSWFT04","#$98jk")
	Local 	cSenhadi	:= Space(10)
	Private cPedido     := Space(9)
	Private cProduto    := Space(15)
	Private nQuant      := 1
	Private lFixaMain   := .F.
	Private oProduto
	Private oBrw
	Private aEtiqueta   := {}
	Private lVer        := .F.
	Private nDiversos   := 0
	Private nConv       := 0
	Private nConta      := 0
	Private cNota       := Space(9)
	Private cSerie      := Space(3)
	Private cCliente    := Space(6)
	Private cCodLojRem	:= ""
	Private cLoja       := Space(3)
	Private cMsg        := ""
	Private cTipo       := Space(1)
	Private cChvNfe     := Space(44)

	If !cEmpAnt $ "06#16"
		MsgAlert("Rotina específica da empresa 06-Redelog","Conferência Notas")
		Return
	Endif

	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Conferência física de Nota Fiscal")
	@ 02,10 TO 070,190
	@ 10,018 Say "Nota"
	@ 10,070 Get cPedido Picture "@!" Size 40,10
	@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION Close(oDlg1)

	ACTIVATE MSDIALOG oDlg1 CENTERED

	cQry := ""
	cQry += "SELECT Z1_DTHRENV,Z1_DTHRCON,Z1_CHAVE,Z1_NOTA,Z1_SERIE,Z1_EMISSAO,Z1_FILIAL,Z1_CHAVE,A1B.A1_COD,A1B.A1_LOJA,A1B.A1_NOME,A1A.A1_COD A1COD,A1A.A1_LOJA A1LOJA"
	cQry += "  FROM " + RetSqlName("SZ1") + " Z1," + RetSqlName("SA1") + " A1A,  " +  RetSqlName("SA1") + " A1B  "
	cQry += " WHERE A1A.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1A.A1_CGC = Z1_EMIT "
	cQry += "   AND A1A.A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND A1B.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1B.A1_CGC = Z1_DEST "
	cQry += "   AND A1B.A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND Z1.D_E_L_E_T_ = ' ' "
	cQry += "   AND Z1_NOTA = '" + cPedido + "' "
	cQry += "   AND Z1_FILIAL = '"+xFilial("SZ1")+"' "

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"_SZ1",.T.,.F.)

	If _SZ1->(Eof())
		MsgAlert("Nao existem registros relacionados a este número de nota","Validação de nota!")
		_SZ1->(DbCloseArea())
		Return
	Endif

	If !Empty(_SZ1->Z1_DTHRCON)

		lContinua := .F.

		@ 001,001 TO 100,400 DIALOG oDlg6 TITLE "Nota fiscal já Conferida. Digita a Senha!"
		@ 005,005 Say "Digite a senha do dia" Color 255
		@ 005,065 Get cSenhadi Valid (lContinua := Alltrim(cSenhadi) == Alltrim(cSenhaAtu)) PASSWORD Size 40,12

		@ 030,010 BUTTON "Avancar-->" SIZE 40,10 Action(Close(oDlg6))

		ACTIVATE MSDIALOG oDlg6 CENTERED
	Endif

	If Empty(_SZ1->Z1_DTHRENV)
		MsgAlert("A nota fiscal não impressa ainda para separação.","Validação de nota!")
		lContinua	:= .F.
	Endif

	If !lContinua
		_SZ1->(DbCloseArea())
		Return
	Endif

	cCliente    := _SZ1->A1_COD     // Cliente final
	cLoja       := _SZ1->A1_LOJA
	cTipo       := "N" // Tipo de pedido - Sempre N=Normal
	cChvNfe     := _SZ1->Z1_CHAVE
	cCodLojRem	:= _SZ1->A1COD+_SZ1->A1LOJA

	aStru:={}

	cNota     := _SZ1->Z1_NOTA
	cSerie    := _SZ1->Z1_SERIE

	lFixaMain := .F.

	_SZ1->(DbCloseArea())

	aStru:={}

	Aadd(aStru,{ "PRODUTO", "C", 15, 0 } )
	Aadd(aStru,{ "DESCR"   , "C", 50, 0 } )
	Aadd(aStru,{ "QUANTID", "N", 12, 2 } )
	Aadd(aStru,{ "UM"     , "C", 02, 0 } )


	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf


	cAlias := GetNextALias()

	//IndRegua(cAlias, cArq,"PRODUTO",,,"Selecionando registros...")

	oTmpTable := FWTemporaryTable():New(cAlias,aStru)
	oTmpTable:AddIndex( "01", {"PRODUTO"})
	oTmpTable:Create()

	@ 01,01 TO 530,755 DIALOG oDlg TITLE "Liberacao Fisica da nota ---> " + cPedido

	aCampos := {}
	aAdd(aCampos,{ "PRODUTO"  , "Produto"})
	aAdd(aCampos,{ "DESCR"    , "Descricao"})
	aAdd(aCampos,{ "QUANTID"  , "Quantidade"})
	aAdd(aCampos,{ "UM"       , "UM"})

	dbSelectArea(cAlias)
	dbGotop()


	@ 05,010 Get nQuant Picture "@E 99999" Size 10,10
	@ 05,035 SAY " X "
	@ 05,050 SAY "Produto: "
	@ 05,080 Get cProduto Valid Processa({|| sfValProd() },"Processando...") Size 50,10 Object oProduto


	@ 025,005 TO 233,370 BROWSE cAlias OBJECT oBrw FIELDS aCampos

	oBrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}

	@ 239,210 BUTTON "Confirma" SIZE 40,15 ACTION Processa({|| sfConfirma() },"Processando...")
	@ 239,290 BUTTON "Fechar" SIZE 40,15 ACTION sfSair()
	@ 239,110 BUTTON "Alterar produto" SIZE 60,15 Action  sfProduto()

	ACTIVATE MSDIALOG oDlg CENTERED Valid lFixaMain

	//TRB->(DbCloseArea())
	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf


Return

/*/{Protheus.doc} sfFechar
Função para fechar a tela
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
Static Function sfFechar()

	lFixaMain := .T.
	Close(oDlg)

Return


/*/{Protheus.doc} sfSair
Confirmação para saída da rotina
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
Static Function sfSair()

	If MsgYesNo("Confirma Saida ? ","Escolha")
		lFixaMain := .T.
		Close(oDlg)
	Endif

Return


/*/{Protheus.doc} Produto
Validação para acessar cadastro de produto
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
Static Function sfProduto()

	// ANO + HORA + DIA
	Local cSenhaval     := Alltrim(Substr(dtos(dDatabase),3,2)+Substr(time(),1,2)+Substr(dtos(dDatabase),7,2))
	Local cSei          := Space(6)

	@ 01,01 TO 130,255 DIALOG oProd TITLE "Informe a senha de supervisor"
	@ 010,005 Say "Digite a senha-->>"
	@ 010,055 Get cSei PASSWORD Size 60,15
	@ 030,060 Button "Continua" size 40,15 action (IIf(cSei==cSenhaval,(sfAltProduto(),oProd:End()),oProd:End()))
	@ 030,005 Button "Cancela" size 40,15 action oProd:End()

	ACTIVATE DIALOG oProd CENTERED

Return


/*/{Protheus.doc} sfValProd
Validação do produto informado
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
Static Function sfValProd()

	Local   x

	If !Empty(cProduto)

		cQry := ""
		cQry += "SELECT B1_COD,B1_CODBAR,B1_DUN14,B1_MIUD,B1_CONVA,B1_DESC "
		cQry += "  FROM " + RetSqlName("SB1")
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_MSBLQL != '1' "
		cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
		cQry += "   AND (B1_COD = '"+cProduto+"' OR B1_DUN14 = '" + cProduto + "' OR B1_CODBAR = '" + cProduto + "' ) "

		TCQUERY cQry NEW ALIAS "QRY"

		dbSelectArea("QRY")
		dbGoTop()
		If Eof()
			cMsg := "Produto sem codigo de barras ou nao Cadastrado: " + cProduto
			sfMsgAlert(cMsg)
			cProduto := Space(15)
			QRY->(DbCloseArea())
			Return(.F.)
		Endif

		cQrp := ""
		cQrp += "SELECT SUM(Z2_QUANT) QTE,Z2_PRODUTO,B1_DESC,B1_UM "
		cQrp += "  FROM "+RetSqlName("SZ2") + " Z2,"+RetSqlName("SB1") + " B1,"+RetSqlName("SZ1") + " Z1 ,"+RetSqlName("SA1") + " A1 ,"+RetSqlName("SA7") + " A7  "
		cQrp += " WHERE B1.D_E_L_E_T_ = ' ' "
		cQrp += "   AND B1_COD = A7_PRODUTO  "
		cQrp += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "

		cQrp += "   AND A7.D_E_L_E_T_ = ' ' "
		cQrp += "   AND A7_CODCLI = Z2_PRODUTO  "
		cQrp += "   AND A7_PRODUTO = '" + QRY->B1_COD + "' "
		cQrp += "   AND A7_LOJA = A1_LOJA  "
		cQrp += "   AND A7_CLIENTE = A1_COD  "
		cQrp += "   AND A7_FILIAL = '"+xFilial("SA7")+"' "

		cQrp += "   AND A1.D_E_L_E_T_ = ' ' "
		cQrp += "   AND A1_MSBLQL <>  '1' "
		cQrp += "   AND A1_CGC = Z1_EMIT  "
		cQrp += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "

		cQrp += "   AND Z2.D_E_L_E_T_ = ' ' "
		cQrp += "   AND Z2_CHAVE = Z1_CHAVE "
		cQrp += "   AND Z2_FILIAL = '"+xFilial("SZ2")+"' "

		cQrp += "   AND Z1.D_E_L_E_T_ = ' ' "
		cQrp += "   AND Z1_CHAVE = '"+cChvNfe+"' "
		cQrp += "   AND Z1_FILIAL = '"+xFilial("SZ1")+"' "
		cQrp += " GROUP BY Z2_PRODUTO,B1_DESC,B1_UM "


		TCQUERY cQrp NEW ALIAS "CONF"

		dbSelectArea("CONF")

		If Eof()
			cMsg := "Produto nao Pertence a Nota Fiscal: " + CONF->Z2_PRODUTO
			sfMsgAlert(cMsg)

			cProduto    := Space(15)
			QRY->(DbCloseArea())
			CONF->(DbCloseArea())

			Return(.F.)
		Else
			dbSelectArea(cAlias)
			dbGoTop()
			If dbSeek(CONF->Z2_PRODUTO)
				nConv := 0
				If QRY->B1_DUN14 == cProduto
					nConv := QRY->B1_CONVA * nQuant
					lVer  := .T.
				Elseif QRY->B1_CODBAR == cProduto
					nConv := 1  * nQuant
					lVer  := .F.
				Endif
				If lVer
					If QRY->B1_MIUD == "N" .And. ((CONF->QTE / nConv) >= 1)
						If (cAlias)->QUANTID >= Mod(CONF->QTE,nConv)
							lVer := .T.
							For x := 1 To Len(aEtiqueta)
								If aEtiqueta[x][3] == CONF->Z2_PRODUTO
									lVer := .F.
								Endif
							Next
							If lVer
								AADD(aEtiqueta,{cCliente,cLoja,CONF->Z2_PRODUTO,((CONF->QTE-Mod(CONF->QTE,nConv))/nConv),QRY->B1_COD,cNota,cSerie})
							Endif
							cMsg := "Produto excedeu a quantidade liberada. " + CONF->Z2_PRODUTO
							sfMsgAlert(cMsg)
							cProduto := Space(15)
							QRY->(DbCloseArea())
							CONF->(DbCloseArea())
							Return(.F.)
						Endif
					Endif
				Endif

				If (cAlias)->QUANTID + nConv > CONF->QTE
					cMsg := "Produto excedeu a quantidade liberada. " + CONF->Z2_PRODUTO
					sfMsgAlert(cMsg)
					cProduto := Space(15)
					QRY->(DbCloseArea())
					CONF->(DbCloseArea()) 
					Return(.F.)
				Endif
				RecLock(cAlias,.F.)
				(cAlias)->QUANTID += 1 * nConv
			Else
				nConv := 0
				If QRY->B1_DUN14 == cProduto
					nConv := QRY->B1_CONVA * nQuant
				Elseif QRY->B1_CODBAR == cProduto
					nConv := 1 * nQuant
				Endif
				If nConv > CONF->QTE
					cMsg := "Produto excedeu a quantidade liberada. " + CONF->Z2_PRODUTO
					sfMsgAlert(cMsg)
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					cProduto := Space(15)
					Return(.F.)
				Endif

				If QRY->B1_MIUD == "N" .And. nConv > (Mod(CONF->QTE,IIf(QRY->B1_CONVA==0,1,QRY->B1_CONVA)))
					cMsg := "Excede qtde produto como caixa aberta " +Chr(13)
					cMsg += "Produto: " +  CONF->Z2_PRODUTO
					sfMsgAlert(cMsg)
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif
				RecLock(cAlias,.T.)
				(cAlias)->QUANTID := 1 * nConv
			Endif
			(cAlias)->PRODUTO 	:= CONF->Z2_PRODUTO
			(cAlias)->DESCR	 	:= QRY->B1_DESC
			(cAlias)->UM		:= CONF->B1_UM
			MsUnLock(cAlias)

		Endif
		QRY->(DbCloseArea())
		CONF->(DbCloseArea())

	Endif

	dbSelectArea(cAlias)
	dbGoTop()

	cProduto := Space(15)

	oBrw:oBrowse:Refresh()
	oBrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}

	nQuant := 1

Return

Static Function sfConfirma()

	Local x


	cQrp := ""
	cQrp += "SELECT SUM(Z2_QUANT) QTE,B1_COD,Z2_PRODUTO,B1_DESC,B1_UM "
	cQrp += "  FROM "+RetSqlName("SZ2") + " Z2,"+RetSqlName("SB1") + " B1,"+RetSqlName("SZ1") + " Z1 ,"+RetSqlName("SA1") + " A1 ,"+RetSqlName("SA7") + " A7  "
	cQrp += " WHERE B1.D_E_L_E_T_ = ' ' "
	cQrp += "   AND B1_COD = A7_PRODUTO  "
	cQrp += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "

	cQrp += "   AND A7.D_E_L_E_T_ = ' ' "
	cQrp += "   AND A7_CODCLI = Z2_PRODUTO  "
	cQrp += "   AND A7_LOJA = A1_LOJA  "
	cQrp += "   AND A7_CLIENTE = A1_COD  "
	cQrp += "   AND A7_FILIAL = '"+xFilial("SA7")+"' "

	cQrp += "   AND A1.D_E_L_E_T_ = ' ' "
	cQrp += "   AND A1_MSBLQL <>  '1' "
	cQrp += "   AND A1_CGC = Z1_EMIT  "
	cQrp += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "

	cQrp += "   AND Z2.D_E_L_E_T_ = ' ' "
	cQrp += "   AND Z2_CHAVE = Z1_CHAVE "
	cQrp += "   AND Z2_FILIAL = '"+xFilial("SZ2")+"' "

	cQrp += "   AND Z1.D_E_L_E_T_ = ' ' "
	cQrp += "   AND Z1_CHAVE = '"+cChvNfe+"' "
	cQrp += "   AND Z1_FILIAL = '"+xFilial("SZ1")+"' "
	cQrp += " GROUP BY Z2_PRODUTO,B1_COD,B1_DESC,B1_UM "

	TCQUERY cQrp NEW ALIAS "OKC"

	DbSelectArea("OKC")
	While !Eof()

		DbSelectArea("SB1")
		DbSetOrder(1)
		If Dbseek(xFilial("SB1")+OKC->B1_COD)

			If SB1->B1_MIUD == "S"
				DbSelectArea(cAlias)
				DbGoTop()
				If DbSeek(OKC->Z2_PRODUTO)
					If OKC->QTE > (cAlias)->QUANTID
						cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->Z2_PRODUTO
						sfMsgAlert(cMsg)
						DbSelectArea(cAlias)
						DbGoTop()
						cProduto := Space(15)
						OKC->(DbCloseArea())
						Return
					Endif
				Else
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->Z2_PRODUTO
					sfMsgAlert(cMsg)
					cProduto := Space(15)
					DbSelectArea(cAlias)
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
			Elseif SB1->B1_MIUD == "N" .And. ((OKC->QTE / SB1->B1_CONVA) >= 1)
				DbSelectArea(cAlias)
				DbGoTop()
				If DbSeek(OKC->Z2_PRODUTO)
					If Mod(OKC->QTE,SB1->B1_CONVA) <> (cAlias)->QUANTID
						cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->Z2_PRODUTO
						sfMsgAlert(cMsg)
						cProduto := Space(15)
						DbSelectArea(cAlias)
						DbGoTop()
						OKC->(DbCloseArea())
						Return
					Endif
				Elseif Mod(OKC->QTE,SB1->B1_CONVA) <> 0
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->Z2_PRODUTO
					sfMsgAlert(cMsg)
					cProduto := Space(15)
					DbSelectArea(cAlias)
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
				lVer := .T.
				For x := 1 To Len(aEtiqueta)
					If aEtiqueta[x][3] == OKC->Z2_PRODUTO
						If aEtiqueta[x][4] < ((OKC->QTE - Mod(OKC->QTE,SB1->B1_CONVA))/SB1->B1_CONVA)
							cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->Z2_PRODUTO
							sfMsgAlert(cMsg)
							cProduto := Space(15)
							dbSelectArea(cAlias)
							dbGoTop()
							OKC->(DbCloseArea())
							Return
						Else
							lVer := .F.
						Endif
					Endif
				Next
				If lVer
					AADD(aEtiqueta,{cCliente,cLoja,OKC->Z2_PRODUTO,((OKC->QTE-Mod(OKC->QTE,SB1->B1_CONVA))/SB1->B1_CONVA),SB1->B1_COD,cNota,cSerie})
				Endif
			Elseif SB1->B1_MIUD == "N" .And. ((OKC->QTE / SB1->B1_CONVA) < 1)
				DbSelectArea(cAlias)
				DbGoTop()
				If dbSeek(OKC->Z2_PRODUTO)
					If OKC->QTE <> (cAlias)->QUANTID
						cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->Z2_PRODUTO
						sfMsgAlert(cMsg)
						cProduto := Space(15)
						DbSelectArea(cAlias)
						DbGoTop()
						OKC->(DbCloseArea())
						Return
					Endif
				Else
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->Z2_PRODUTO
					sfMsgAlert(cMsg)
					cProduto := Space(15)
					DbSelectArea(cAlias)
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
			Endif
		Endif

		DbSelectArea("OKC")
		DbSkip()
	Enddo
	OKC->(DbCloseArea())

	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Volumes diversos")
	@ 02,10 TO 070,190
	@ 10,018 Say "Informe o numero de volumes diversos:"
	@ 10,120 Get nDiversos Picture "@E 99999" Size 30,10
	@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION (sfPrint(),oDlg1:End(),sfFechar())

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return

/*/{Protheus.doc} sfPrint
Função para chamada da impressão de etiquetas
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
Static Function sfPrint()

	If Len(aEtiqueta) <> 0 .Or. !Empty(nDiversos)
		sfPrtEtq(aEtiqueta,nDiversos,cPedido,cNota,cSerie,cCliente,cLoja,cTipo)//LABEL

		DbSelectArea("SZ1")
		DbSetOrder(1)
		If DbSeek(xFilial("SZ1")+cChvNfe)
			RecLock("SZ1",.F.)
			SZ1->Z1_DTHRCON		:= DTOC(Date()) + " " + Substr(Time(),1,5)
			MsUnlock()
		Endif
		MsgInfo("Pedido liberado com sucesso","Informacao")
	Endif

Return

/*/{Protheus.doc} sfMsgAlert
Exibe tela de alertas conforme mensagem passada como parâmetro
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@param cMsg, character, param_description
@return variant, return_description
/*/
Static Function sfMsgAlert(cMsg)

	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Informação")
	@ 02,10 TO 070,190
	@ 10,018 Say cMsg color 128

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return

/*/{Protheus.doc} sfAltProduto
Tela para alteração de cadastro de produto
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
Static Function sfAltProduto()

	Local   oDglAltPrd
	Private cCodpro     := Space(15)
	Private cCodproa    := Space(15)
	Private cEanloc     := Space(15)
	Private cCodBarra   := Space (15)
	Private cCodbcx     := Space (15)
	Private nConvaux    := 0.00
	Private cMiudeza    := Space (1)
	Private cEnd        := Space (15)
	Private nPeso	    := 0.00
	Private aItems      := {"","S","N"}
	Private cCombo      := Space(1)
	Private cMiudz      := Space(1)


	@ 200,1 TO 380,395 DIALOG oDglAltPrd TITLE OemToAnsi("Alterar dados logísticos para separação,conferência e organização.")
	@ 02,10 TO 070,190
	@ 10,018 Say "Código produto:"
	@ 10,070 Get cCodpro F3 "SB1" size 50,10
	@ 30,018 Say "Digite o código de barra: "
	@ 30,100 Get cEanloc size 60,10
	@ 72,133 BMPBUTTON TYPE 01 ACTION (sfAltPrd(),Close(oDglAltPrd))
	@ 72,163 BMPBUTTON TYPE 02 ACTION Close(oDglAltPrd)

	Activate Dialog oDglAltPrd Centered

Return

/*/{Protheus.doc} sfAltPrd
Função para alterar cadastro de produtos
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/10/2021
@return variant, return_description
/*/
Static Function sfAltPrd()

	If !Empty(cEanloc) .and. empty(cCodpro)
		dbselectarea("SB1")
		dbsetorder(5)
		If dbseek(xFilial("SB1")+cEanloc,.F.)
			cCodproa := SB1->B1_COD
			sfTelaAltB1()
		Else
			MsgAlert("Código de barra não cadastrado!!!","Atencao!")
		endif
	Elseif empty(cEanloc) .and. !empty(cCodpro)
		Dbselectarea("SB1")
		dbsetorder(1)
		If Dbseek(xFilial("SB1")+cCodpro,.F.)
			cCodproa := SB1->B1_COD
			sfTelaAltB1()
		Else
			MsgAlert("Código de produto inexistente. Favor consulte novamente!! Utilize F3 para pesquisar.","Atencao!")
		Endif
	Elseif !empty(cEanloc) .and. !empty(cCodpro)

	Elseif !empty(cEanloc) .and. !empty(cCodpro)
		MsgAlert("Favor entre só com uma informação. Código do produto ou só código de Barra.","Atencao!")
	Endif

Return


Static function sfTelaAltB1()

	Local       oDlgAlt

	cCodproa   := SB1->B1_COD

	@ 270,1 TO 490,595 DIALOG oDlgAlt TITLE OemToAnsi("Alterar dados logísticos.")
	@ 02,10 TO 075,260
	@ 10,018 Say SB1->B1_COD
	@ 10,060 Say SB1->B1_DESC
	@ 20,018 Say "Código de barra: "
	@ 20,060 Say SB1->B1_CODBAR
	@ 20,110 Get cCodBarra size 50,10 When .F.
	@ 20,168 Say "Bloqueado p/Alteração nesta rotina!"

	@ 32,018 Say "Dun14 A:"
	@ 32,060 Say SB1->B1_DUN14
	@ 32,110 Get cCodbcx  size 50,10

	@ 32,170 Say "Conv 14 A:"
	@ 32,205 Say SB1->B1_CONVA
	@ 32,220 Get nConvaux Picture "@E 999,999" size 20,10

	@ 44,018 Say "Miudeza:"
	@ 44,050 SAY SB1->B1_MIUD
	@ 44,070 COMBOBOX cMiudeza ITEMS aItems size 35,10

	@ 44,120 Say "Peso:"
	@ 44,150 SAY SB1->B1_PESO
	@ 44,180 Get nPeso Picture "@E 999,999.999" size 40,10

	@ 56,018 Say "Endereço:"
	@ 56,050 SAY SB1->B1_XLOCAL
	@ 56,070 Get cEnd size 30,10

	@ 82,133 BMPBUTTON TYPE 01 ACTION (sfGrvAltPrd(),Close(oDlgAlt))
	@ 82,163 BMPBUTTON TYPE 02 ACTION Close(oDlgAlt)

	Activate Dialog oDlgAlt Centered


Return


/*/{Protheus.doc} sfGrvAltPrd
(long_description)
@author MarceloLauschner
@since 15/03/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrvAltPrd()

	dbSelectArea("SB1")
	dbSetOrder(1)
	If DbSeek(xFilial("SB1")+cCodproa,.T.)
		dbSelectArea("SB1")
		RecLock("SB1",.F.)
		If !Empty(nPeso)
			SB1->B1_PESO   := nPeso
		Endif
		If !Empty(cCodBarra)
			SB1->B1_CODBAR := cCodBarra
		Endif
		If !Empty(cMiudeza)
			SB1->B1_MIUD   := cMiudeza
		Endif

		If !Empty(cCodbcx)
			SB1->B1_DUN14  := cCodbcx
		Endif
		If !Empty(nConvaux)
			SB1->B1_CONVA  := nConvaux
		Endif
		If !Empty(cEnd)
			SB1->B1_XLOCAL  := cEnd
		Endif
		MSUnLock()

		MsgAlert("Entrada de Dados Realizada com sucesso!!","Informação")
	Else
		MsgAlert("Erro na alteração. Favor contate CPD ","Atencao!")
	Endif

Return



Static Function sfPrtEtq(aEtiqueta,nDiversos,cPedido,cNota,cSerie,cCliente,cLoja,cTipo)

	Local nConta     := 0
	Local nTotal     := 0
	Local nVolumes   := 0
	Local x , y

	nTotal += nDiversos

	For x := 1 To Len(aEtiqueta)
		nTotal += aEtiqueta[x][4]
	Next

	For x := 1 To Len(aEtiqueta)

		For y := 1 To aEtiqueta[x][4]
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Inicio de impressao                                                 ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			_cPorta := Alltrim(GetNewPar("GM_PORTLPT","LPT1:9600,n,8,1"))

			MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
			MSCBCHKSTATUS(.F.)
			MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta

			nVolumes++

			MSCBSAY(45,34,DTOC(Date()) + "  " + Time(),"N","9","001,001")//Imprime Texto

			If cEmpAnt == "06"
				DbSelectArea("SA1")
				DbSetOrder(1)
				If DbSeek(xFilial("SA1")+cCodLojRem)
					MSCBSAY(02,32,SA1->A1_NREDUZ,"N","9","002,002") //Imprime Texto
				Endif
			Endif

			If cTipo <> "B" .or. cTipo <> "D"
				DbSelectArea("SA1")
				DbSetOrder(1)
				If DbSeek(xFilial("SA1")+aEtiqueta[x][1]+aEtiqueta[x][2],.T.)
					MSCBSAY(02,28,SA1->A1_NOME,"N","9","002,002") //Imprime Texto
					MSCBSAY(02,22,SA1->A1_MUN,"N","9","002,002") //Imprime Texto
				Endif
			Else
				DbSelectArea("SA2")
				DbSetOrder(1)
				If DbSeek(xFilial("SA2")+aEtiqueta[x][1]+aEtiqueta[x][2],.T.)
					MSCBSAY(02,28,SA2->A2_NOME,"N","9","002,002") //Imprime Texto
					MSCBSAY(02,22,SA2->A2_MUN,"N","9","002,002") //Imprime Texto
				Endif
			Endif

			MSCBSAY(15,16,"Nr.NF: " ,"N","9","001,001")
			MSCBSAY(25,14,aEtiqueta[x][6],"N","9","006,004") //Imprime pedido e nota fiscal

			DbSelectArea("SB1")
			DbSetOrder(1)
			If dbSeek(xFilial("SB1")+aEtiqueta[x][5])


				MSCBSAY(02,09,AllTrim(aEtiqueta[x][5]) + " - " + SB1->B1_UM + " - " + Substr(SB1->B1_DESC,1,25),"N","9","002,002") //Imprime Texto
				If !Empty(Substr(SB1->B1_DESC,26,Len(SB1->B1_DESC)-25))
					MSCBSAY(02,03,Substr(SB1->B1_DESC,31,Len(SB1->B1_DESC)-30),"N","9","002,001") //Imprime Texto
				Endif

				MSCBSAY(02,01,"Endereco: "+ SB1->B1_XLOCAL + " - " + AllTrim(Transform(y,"@E 9999")) + "/" + AllTrim(Transform(aEtiqueta[x][4],"@E 9999")) + " Cx c/ " + AllTrim(Transform(SB1->B1_CONVA,"@E 9999")),"N","9","002,001") //Imprime Texto
				nConta++
				MSCBSAY(75,01,AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal)),"N","9","003,002") //Imprime Texto
			Endif

			cResult := MSCBEND()
			// MsgAlert(cResult)
			//MemoWrit('DIS010',cResult)

		Next

	Next

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Etiquetas diversas                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	For y := 1 To nDiversos

		nVolumes++

		_cPorta := Alltrim(GetNewPar("GM_PORTLPT","LPT1:9600,n,8,1"))

		MSCBPRINTER("ALLEGRO",_cPorta,Nil,) //Seta tipo de impressora
		MSCBCHKSTATUS(.F.)
		MSCBBEGIN(1,4) //Inicio da Imagem da Etiqueta

		MSCBSAY(45,34,DTOC(Date()) + "  " + Time(),"N","9","001,001")//Imprime Texto

		If cEmpAnt $ "06#16"
			DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1")+cCodLojRem)
				MSCBSAY(01,32,SA1->A1_NREDUZ,"N","9","002,002") //Imprime Texto
			Endif
		Endif

		If cTipo <> "B" .or. cTipo <> "D"
			DbSelectArea("SA1")
			DbSetOrder(1)
			If DbSeek(xFilial("SA1")+cCliente+cLoja)
				MSCBSAY(02,28,SA1->A1_NOME,"N","9","002,002") //Imprime Texto
				MSCBSAY(02,18,SA1->A1_MUN,"N","9","002,002") //Imprime Texto
			Endif
		Else
			DbSelectArea("SA2")
			DbSetOrder(1)
			If DbSeek(xFilial("SA2")+cCliente+cLoja)
				MSCBSAY(02,28,SA2->A2_NOME,"N","9","002,002") //Imprime Texto
				MSCBSAY(02,18,SA2->A2_MUN,"N","9","002,002") //Imprime Texto
			Endif
		Endif

		MSCBSAY(15,12,"Nr.NF: " ,"N","9","001,001")
		MSCBSAY(25,10,cNota,"N","9","006,004") //Imprime pedido e nota fiscal
		MSCBSAY(07,05,"VOLUMES DIVERSOS","N","9","002,002") //Imprime Texto
		nConta++
		MSCBSAY(75,01,AllTrim(Str(nConta))+"/"+AllTrim(Str(nTotal)),"N","9","003,002") //Imprime Texto

		cResult := MSCBEND()
		//msgAlert(cResult)
		//MemoWrit('DIS010',cResult)
	Next


Return
