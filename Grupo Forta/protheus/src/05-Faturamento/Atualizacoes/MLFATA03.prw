#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} MLFATA03
// Interface de conferência física da Nota Fiscal
@author Marcelo Alberto Lauschner
@since 26/09/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User function MLFATA03()

	Private nLenPrd	  	:= TamSX3("B1_COD")[1]
	Private nLenSer	  	:= TamSX3("DB_NUMSERI")[1]
	Private cPedido   	:= Space(6)
	Private cProduto  	:= Space(nLenPrd)
	Private nQuant    	:= 1
	Private lFixaMain 	:= .F.
	Private oProduto
	Private oBrw
	Private aEtiqueta	 := {}
	Private lVer      	:= .F.
	Private nDiversos 	:= 0
	Private nConv     	:= 0
	Private nConta    	:= 0
	Private cNota     	:= Space(9)
	Private cSerie    	:= Space(3)
	Private cCliente  	:= Space(6)
	Private cLoja     	:= Space(3)
	Private cMsg      	:= ""
	Private cTipo     	:= Space(1)
	Private oDlg
	Private cSerUsed	:= ""
	Private nVolCalc	:= 0
	Private nVolDiv 	:= 0
	Private oVolCal

	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Liberacao Fisica da Nota Fiscal")
	@ 02,10 TO 070,190
	@ 10,018 Say "Número Nota"
	@ 10,070 Get cNota Picture "@!" Size 30,10
	@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION Close(oDlg1)

	ACTIVATE MSDIALOG oDlg1 CENTERED

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o pedido existe                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	dbSelectArea("SF2")
	dbSetOrder(1) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
	If dbSeek(xFilial("SF2")+cNota+GetNewPar("GF_SERIENF","1"))

	Else
		Alert("Nao existem registros relacionados a esta nota fiscal!")
		Return
	Endif

	cCliente 	:= SF2->F2_CLIENTE
	cLoja    	:= SF2->F2_LOJA
	cTipo    	:= SF2->F2_TIPO
	cNota    	:= SF2->F2_DOC
	cSerie		:= SF2->F2_SERIE
	lFixaMain 	:= .F.

	// Grava Data e hora do inicio da Separação
	DbSelectArea("CB7")
	DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
	If DbSeek(xFilial("CB7")+Padr(cNota,TamSX3("F2_DOC")[1])+cSerie)
		RecLock("CB7",.F.)
		CB7->CB7_VOLEMI	:= "0"
		CB7->CB7_STATUS	:= "1"
		CB7->CB7_DIVERG	:= ""
		CB7->CB7_DTINIS	:= Date()
		CB7->CB7_HRINIS	:= Time()
		MsUnlock()
	Endif

	aStru:={}

	Aadd(aStru,{ "PRODUTO", "C", TamSX3("B1_COD")[1]	, 0 } )
	Aadd(aStru,{ "DESC"   , "C", TamSX3("B1_DESC")[1]	, 0 } )
	Aadd(aStru,{ "QUANTID", "N", 12						, 2 } )
	Aadd(aStru,{ "UM"     , "C", 02						, 0 } )
	Aadd(aStru,{ "MIUDEZ" , "C", 01                     , 0 } ) // Informa se o produto precisa entrar na 

	If ( Select ( "TRB" ) <> 0 )
		dbSelectArea ("TRB")
		dbCloseArea()
	Endif

	cArq := CriaTrab(aStru,.t.)
	dbUseArea ( .T.,__localdriver, cArq, "TRB", NIL, .F. )
	IndRegua("TRB", cArq,"PRODUTO",,,"Selecionando registros...")


	aStru2:={}
	Aadd(aStru2,{ "PRODUTO", "C", TamSX3("B1_COD")[1]		, 0 } )
	Aadd(aStru2,{ "ENDER"  , "C", TamSX3("DB_LOCALIZ")[1]	, 0 } )
	Aadd(aStru2,{ "QUANTID", "N", 12						, 2 } )
	Aadd(aStru2,{ "NUMSERI", "C", TamSX3("DB_NUMSERI")[1]	, 0 } )

	cArq2 := CriaTrab(aStru2,.t.)
	If Select("TRB2") > 0
		TRB2->(DbCloseArea())
	Endif
	dbUseArea ( .T.,__localdriver, cArq2, "TRB2", NIL, .F. )

	IndRegua("TRB2", cArq2,"NUMSERI",,,"Selecionando registros...")


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exibe arquivos a serem liberados                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 01,01 TO 530,855 DIALOG oDlg TITLE "Liberacao Fisica da Nota ---> " + cNota

	aCampos := {}
	aAdd(aCampos,{ "PRODUTO" , "Produto"})
	aAdd(aCampos,{ "DESC"    , "Descricao"})
	aAdd(aCampos,{ "QUANTID" , "Quantidade"})
	aAdd(aCampos,{ "UM"      , "UM"})
	Aadd(aCampos,{ "MIUDEZ"  , "Miudeza"})

	dbSelectArea("TRB")
	dbGotop()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica o cliente referente ao pedido                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 05,010 Get nQuant Picture "@E 99999" Size 10,10
	@ 05,035 SAY " X "
	@ 05,050 SAY "Produto: "
	@ 05,080 Get cProduto Valid sfValProd()  Size 60,10 Object oProduto

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Existe historicos ja gravados                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 025,005 TO 233,420 BROWSE "TRB" OBJECT oBrw FIELDS aCampos

	oBrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}

	@ 239,150 BUTTON "Alterar produto" SIZE 60,15 Action sfAlterPrd()
	@ 239,250 BUTTON "Confirma" SIZE 50,15 ACTION Processa({|| Confirma() },"Processando...")
	@ 239,315 BUTTON "Fechar" SIZE 50,15 ACTION Sair()

	@ 239,010 Say "Volumes Híbrido:"
	@ 239,050 Get nVolCalc Size 50,10 Object oVolCal When .F. 

 	ACTIVATE MSDIALOG oDlg CENTERED Valid lFixaMain

	TRB->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index

	TRB2->(DbCloseArea())
	FErase(cArq2 + GetDbExtension()) // Deleting file
	FErase(cArq2 + OrdBagExt()) // Deleting index


Return

Static Function Fechar()

	lFixaMain := .T.
	Close(oDlg)

Return

Static Function Sair()

	If MsgYesNo("Confirma Saida ? ","Escolha")
		lFixaMain := .T.
		Close(oDlg)
	Endif

Return

Static Function sfSumVol()

	nVolCalc	:= 0

	DbSelectArea("TRB")
	DbGotop() 
	While !Eof()
		If TRB->MIUDEZ == "H"
			nVolCalc += TRB->QUANTID
		ElseIf TRB->MIUDEZ == "S"
			nVolDiv	+= TRB->QUANTID 
		Endif 
		TRB->(DbSkip())
	Enddo 
	oVolCal:Refresh()

Return 
/*/{Protheus.doc} sfValProd
// Rotina de validação da digitação do código de Produto
@author Marcelo Alberto Lauschner
@since 26/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static Function sfValProd()

	Local x 

	If !Empty(cProduto)

		cProduto	:= StrTran(cProduto,"'","")

		cQry := ""
		cQry += "SELECT B1_COD,B1_UM,B1_CODBAR,B1_XDUN14B,B1_XDUN14A,B1_XMIUDEZ,B1_XNVOLAX,B1_XCONVB,B1_XCONVA,B1_DESC,DB_NUMSERI  "
		cQry += "  FROM " + RetSqlName("SDB") + " DB, " + RetSqlName("SB1") + " B1 "
		cQry += " WHERE B1.D_E_L_E_T_ =' ' "
		cQry += "   AND B1_MSBLQL != '1' "
		cQry += "   AND B1_COD = DB_PRODUTO "
		cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
		cQry += "   AND (DB_NUMSERI = '" + cProduto + "' OR DB_PRODUTO = '"+ cProduto + "') "
		If !Empty(cSerUsed)
			cQry += "   AND DB_NUMSERI NOT IN " + FormatIn(cSerUsed,"/") 
		Endif 
		cQry += "   AND DB.D_E_L_E_T_ =' ' "
		cQry += "   AND DB_ESTORNO = ' ' "
		cQry += "   AND DB_LOJA = '" + cLoja + "'"
		cQry += "   AND DB_CLIFOR = '" + cCliente + "'"
		cQry += "   AND DB_SERIE = '" + cSerie + "'"
		cQry += "   AND DB_DOC = '" + cNota + "' "
		cQry += "   AND DB_FILIAL = '" + xFilial("SDB") + "' "
		cQry += " UNION ALL "
		cQry += "SELECT B1_COD,B1_UM,B1_CODBAR,B1_XDUN14B,B1_XDUN14A,B1_XMIUDEZ,B1_XNVOLAX,B1_XCONVB,B1_XCONVA,B1_DESC,' ' DB_NUMSERI "
		cQry += "  FROM " + RetSqlName("SB1")
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_MSBLQL != '1' "
		cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
		cQry += "   AND B1_COD != '"+cProduto+"' "
		cQry += "   AND ( B1_XDUN14B = '" + cProduto + "' OR B1_XDUN14A = '" + cProduto + "' OR B1_CODBAR = '" + cProduto + "' ) "
	

		TCQUERY cQry NEW ALIAS "QRY"

		dbSelectArea("QRY")
		dbGoTop()
		If Eof()
			cMsg := "Produto '" + cProduto + "' sem código de barras ou não Cadastrado! "
			sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
			cProduto := Space(nLenPrd)
			oProduto:Refresh()
			QRY->(DbCloseArea())
			Return(.F.)
		Endif

		cQrp := ""
		cQrp += "SELECT SUM(D2_QUANT) AS QTE,D2_COD,D2_CLIENTE,D2_UM,D2_PEDIDO,D2_DOC "
		cQrp += "  FROM " + RetSqlName("SD2")
		cQrp += " WHERE D_E_L_E_T_ = ' ' "
		cQrp += "   AND D2_FILIAL = '" + xFilial("SD2") + "' "
		cQrp += "   AND D2_DOC = '" + cNota + "' "
		cQrp += "   AND D2_SERIE = '" + cSerie +  "' "
		cQrp += "   AND D2_CLIENTE = '" + cCliente + "' "
		cQrp += "   AND D2_LOJA = '" + cLoja + "' "
		cQrp += "   AND D2_COD = '" + QRY->B1_COD + "' "
		cQrp += " GROUP BY D2_COD,D2_CLIENTE,D2_UM,D2_PEDIDO,D2_DOC "

		TCQUERY cQrp NEW ALIAS "CONF"

		dbSelectArea("CONF")
		dbGoTop()
		If Eof()
			cMsg := "Produto '" + QRY->B1_COD + "' não Pertence a Nota Fiscal! "
			sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
			cProduto := Space(nLenPrd)
			oProduto:Refresh()
			QRY->(DbCloseArea())
			CONF->(DbCloseArea())
			Return(.F.)
		Else
			cPedido		:= CONF->D2_PEDIDO

			dbSelectArea("TRB")
			dbGoTop()
			If dbSeek(QRY->B1_COD)
				nConv := 0
				If Padr(QRY->B1_XDUN14B,nLenPrd) == cProduto
					nConv := IIf(QRY->B1_XCONVB==0,1,QRY->B1_XCONVB) * nQuant
					lVer  := .T.
				Elseif Padr(QRY->B1_XDUN14A,nLenPrd) == cProduto
					nConv := IIf(QRY->B1_XCONVA==0,1,QRY->B1_XCONVA)  * nQuant
					lVer  := .F.
				Elseif Padr(QRY->B1_CODBAR,nLenPrd) == cProduto
					nConv := 1  * nQuant
					lVer  := .F.
				Endif
				If lVer
					If QRY->B1_XMIUDEZ == "N" .And. ((CONF->QTE / nConv) >= 1) .And. !Localiza(CONF->D2_COD)
						If TRB->QUANTID >= Mod(CONF->QTE,nConv)
							lVer := .T.
							For x := 1 To Len(aEtiqueta)
								If aEtiqueta[x][3] == CONF->D2_COD
									lVer := .F.
								Endif
							Next
							If lVer
								AADD(aEtiqueta,{cCliente,cLoja,CONF->D2_COD,((CONF->QTE-Mod(CONF->QTE,nConv))/nConv),CONF->D2_PEDIDO,cNota,cSerie,QRY->B1_XMIUDEZ,QRY->B1_XNVOLAX})
							Endif
							cMsg := "Produto '" + QRY->B1_COD +"' excedeu a quantidade liberada - Produto configurado como Miudeza = 'Não' "
							sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
							cProduto := Space(nLenPrd)
							oProduto:Refresh()
							QRY->(DbCloseArea())
							CONF->(DbCloseArea())
							Return(.F.)
						Endif
					// Verifica se o item é Hibrido ( Volume fechado mas checkout obrigatório )
					ElseIf QRY->B1_XMIUDEZ == "H" .And. !Localiza(CONF->D2_COD)
						If TRB->QUANTID >= CONF->QTE
							lVer := .T.
							For x := 1 To Len(aEtiqueta)
								If aEtiqueta[x][3] == CONF->D2_COD
									lVer := .F.
								Endif
							Next
							If lVer
								AADD(aEtiqueta,{cCliente,cLoja,CONF->D2_COD,CONF->QTE,CONF->D2_PEDIDO,cNota,cSerie,QRY->B1_XMIUDEZ,QRY->B1_XNVOLAX})
							Endif
							cMsg := "Produto '" + QRY->B1_COD +"' excedeu a quantidade liberada. Produto configurado como Miudeza = 'Hibrido' "
							sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
							cProduto := Space(nLenPrd)
							oProduto:Refresh()
							QRY->(DbCloseArea())
							CONF->(DbCloseArea())
							Return(.F.)
						Endif
					// Verifica se o item é Hibrido ( Volume fechado mas checkout obrigatório )
					ElseIf QRY->B1_XMIUDEZ == "M" 
						If TRB->QUANTID >= CONF->QTE
							lVer := .T.
							For x := 1 To Len(aEtiqueta)
								If aEtiqueta[x][3] == CONF->D2_COD
									lVer := .F.
								Endif
							Next
							If lVer
								AADD(aEtiqueta,{cCliente,cLoja,CONF->D2_COD,CONF->QTE,CONF->D2_PEDIDO,cNota,cSerie,QRY->B1_XMIUDEZ,QRY->B1_XNVOLAX})
							Endif
							cMsg := "Produto '" + QRY->B1_COD +"' excedeu a quantidade liberada. Produto configurado como Miudeza = 'Multiplos' "
							sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
							cProduto := Space(nLenPrd)
							oProduto:Refresh()
							QRY->(DbCloseArea())
							CONF->(DbCloseArea())
							Return(.F.)
						Endif
					Endif
				Endif

				If TRB->QUANTID + nConv > CONF->QTE
					cMsg := "Produto excedeu a quantidade liberada. " + QRY->B1_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					cProduto := Space(nLenPrd)
					oProduto:Refresh()
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif

				// Se houver número serial
				If !Empty(QRY->DB_NUMSERI) .Or. Localiza(CONF->D2_COD)
					sfVldSDB(QRY->B1_COD,QRY->DB_NUMSERI)
					cProduto := Space(nLenPrd)
					oProduto:Refresh()
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif

				RecLock("TRB",.F.)
				TRB->QUANTID += 1 * nConv
			Else
				nConv := 0
				If Padr(QRY->B1_XDUN14B,nLenPrd) == cProduto
					nConv := IIf(QRY->B1_XCONVB==0,1,QRY->B1_XCONVB) * nQuant
				Elseif Padr(QRY->B1_XDUN14A,nLenPrd) == cProduto
					nConv :=IIf(QRY->B1_XCONVA==0,1, QRY->B1_XCONVA) * nQuant
				Elseif Padr(QRY->B1_CODBAR,nLenPrd)== cProduto
					nConv := 1 * nQuant
				Endif
				If nConv > CONF->QTE
					cMsg := "Produto excedeu a quantidade liberada. " + QRY->B1_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					cProduto := Space(nLenPrd)
					oProduto:Refresh()
					Return(.F.)
				Endif

				If QRY->B1_XMIUDEZ == "N" .And. nConv > (Mod(CONF->QTE,IIf(QRY->B1_XCONVB==0,1,QRY->B1_XCONVB))) .And. !Localiza(QRY->B1_COD)
					cMsg := "Excede qtde produto como caixa aberta - Produto configurado como Miudeza = 'Não' " +Chr(13)
					cMsg += "Produto: " +  QRY->B1_COD

					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif

				// Verifica se o item é Hibrido ( Volume fechado mas checkout obrigatório )
				If QRY->B1_XMIUDEZ == "H" .And. nConv > CONF->QTE .And. !Localiza(QRY->B1_COD)
					cMsg := "Excede qtde produto como caixa aberta Produto configurado como Miudeza = 'Hibrido' " +Chr(13)
					cMsg += "Produto: " +  QRY->B1_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif
				
				// Verifica se o item é Multiplo ( Volume fechado mas checkout obrigatório )
				If QRY->B1_XMIUDEZ == "M" .And. nConv > CONF->QTE 
					cMsg := "Excede qtde produto como caixa aberta Produto configurado como Miudeza = 'Múltiplo' " +Chr(13)
					cMsg += "Produto: " +  QRY->B1_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif

				If QRY->B1_XMIUDEZ == "X" 
					cMsg := "Produto configurado Miudeza = 'Software' onde não terá conferência no pedido e nem etiquetas " +Chr(13)
					cMsg += "Produto: " +  QRY->B1_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif

				// Se houver número serial
				If !Empty(QRY->DB_NUMSERI) .Or. Localiza(QRY->B1_COD)
					sfVldSDB(QRY->B1_COD,QRY->DB_NUMSERI)
					cProduto := Space(nLenPrd)
					oProduto:Refresh()
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif

				RecLock("TRB",.T.)
				TRB->QUANTID := 1 * nConv
			Endif
			TRB->PRODUTO 	:= QRY->B1_COD
			TRB->DESC	 	:= QRY->B1_DESC
			TRB->UM		 	:= CONF->D2_UM
			TRB->MIUDEZ		:= QRY->B1_XMIUDEZ
			MsUnLock("TRB")

		Endif
		QRY->(DbCloseArea())
		CONF->(DbCloseArea())

	Endif

	dbSelectArea("TRB")
	dbGoTop()
	cProduto := Space(nLenPrd)
	oProduto:Refresh()
	oBrw:oBrowse:Refresh()
	nRecAtu := TRB->(Recno())
	sfSumVol()
	TRB->(DbGoto(nRecAtu))
	nQuant := 1

Return .T. 

/*/{Protheus.doc} Confirma
// Rotina que valida a finalização da conferência da Nota fiscal.
@author Marcelo Alberto Lauschner
@since 26/09/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function Confirma()

	Local 	x 

	cQrp := ""
	cQrp += "SELECT SUM(D2_QUANT) AS QTE,D2_COD,D2_SERIE,D2_CLIENTE,D2_UM,D2_PEDIDO,D2_DOC "
	cQrp += "  FROM " + RetSqlName("SD2")
	cQrp += " WHERE D_E_L_E_T_ = ' ' "
	cQrp += "   AND D2_FILIAL = '" + xFilial("SD2") + "' "
	cQrp += "   AND D2_DOC = '" + cNota + "' "
	cQrp += "   AND D2_SERIE = '" + cSerie +  "' "
	cQrp += "   AND D2_CLIENTE = '" + cCliente + "' "
	cQrp += "   AND D2_LOJA = '" + cLoja + "' "
	cQrp += " GROUP BY D2_COD,D2_SERIE,D2_CLIENTE,D2_UM,D2_PEDIDO,D2_DOC "


	TCQUERY cQrp NEW ALIAS "OKC"

	DbSelectArea("OKC")
	DbGoTop()
	While !Eof() .And. OKC->D2_DOC == cNota;
			.And. OKC->D2_SERIE == cSerie

		cPedido		:= OKC->D2_PEDIDO

		DbSelectArea("SB1")
		DbSetOrder(1)
		If Dbseek(xFilial("SB1")+OKC->D2_COD)

			If SB1->B1_XMIUDEZ == "S" .Or. Localiza(OKC->D2_COD)
				DbSelectArea("TRB")
				DbGoTop()
				If DbSeek(OKC->D2_COD)
					If OKC->QTE > TRB->QUANTID
						cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
						sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
						DbSelectArea("TRB")
						DbGoTop()
						cProduto := Space(nLenPrd)
						OKC->(DbCloseArea())
						Return
					Endif

					If Localiza(OKC->D2_COD)
						lVer := .T.
						For x := 1 To Len(aEtiqueta)
							If aEtiqueta[x][3] == OKC->D2_COD
								If aEtiqueta[x][4] < TRB->QUANTID
									cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
									sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
									cProduto := Space(nLenPrd)
									dbSelectArea("TRB")
									dbGoTop()
									OKC->(DbCloseArea())
									Return
								Else
									lVer := .F.
								Endif
							Endif
						Next
						If lVer
							AADD(aEtiqueta,{cCliente,;
											cLoja,;
											OKC->D2_COD,;
											TRB->QUANTID,;
											OKC->D2_PEDIDO,;
											cNota,;
											cSerie,;
											SB1->B1_XMIUDEZ,;
											SB1->B1_XNVOLAX})
						Endif
					Endif
				Else
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					cProduto := Space(nLenPrd)
					DbSelectArea("TRB")
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
			Elseif SB1->B1_XMIUDEZ == "N" .And. ((OKC->QTE / IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB)) >= 1)
				DbSelectArea("TRB")
				DbGoTop()
				If DbSeek(OKC->D2_COD)
					If Mod(OKC->QTE,IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB)) <> TRB->QUANTID
						cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->D2_COD
						sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
						cProduto := Space(nLenPrd)
						DbSelectArea("TRB")
						DbGoTop()
						OKC->(DbCloseArea())
						Return
					Endif
				Elseif Mod(OKC->QTE,IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB)) <> 0
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					cProduto := Space(nLenPrd)
					DbSelectArea("TRB")
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
				lVer := .T.
				For x := 1 To Len(aEtiqueta)
					If aEtiqueta[x][3] == OKC->D2_COD
						If aEtiqueta[x][4] < ((OKC->QTE - Mod(OKC->QTE,IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB)))/ IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB))
							cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
							sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
							cProduto := Space(nLenPrd)
							dbSelectArea("TRB")
							dbGoTop()
							OKC->(DbCloseArea())
							Return
						Else
							lVer := .F.
						Endif
					Endif
				Next
				If lVer
					AADD(aEtiqueta,{cCliente,cLoja,OKC->D2_COD,((OKC->QTE-Mod(OKC->QTE,IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB)))/IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB)),OKC->D2_PEDIDO,cNota,cSerie,SB1->B1_XMIUDEZ,SB1->B1_XNVOLAX})
				Endif
			Elseif SB1->B1_XMIUDEZ == "N" .And. ((OKC->QTE / IIf(SB1->B1_XCONVB==0,1,SB1->B1_XCONVB)) < 1) .And. !Localiza(OKC->D2_COD)
				DbSelectArea("TRB")
				DbGoTop()
				If dbSeek(OKC->D2_COD)
					If OKC->QTE <> TRB->QUANTID
						cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->D2_COD
						sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
						cProduto := Space(nLenPrd)
						DbSelectArea("TRB")
						DbGoTop()
						OKC->(DbCloseArea())
						Return
					Endif
				Else
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13)
					cMsg += "Produto: " + OKC->D2_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					cProduto := Space(nLenPrd)
					DbSelectArea("TRB")
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
			// Verifica se o item é Hibrido ( Volume fechado mas checkout obrigatório )
			ElseIf SB1->B1_XMIUDEZ == "H" .And. !Localiza(OKC->D2_COD)
				
				DbSelectArea("TRB")
				DbGoTop()
				If dbSeek(OKC->D2_COD)
					If OKC->QTE <> TRB->QUANTID
						cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->D2_COD
						sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
						cProduto := Space(nLenPrd)
						DbSelectArea("TRB")
						DbGoTop()
						OKC->(DbCloseArea())
						Return
					Endif
				Else
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) 
					cMsg += "Produto: " + OKC->D2_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					cProduto := Space(nLenPrd)
					DbSelectArea("TRB")
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
				lVer := .T.
				For x := 1 To Len(aEtiqueta)
					If aEtiqueta[x][3] == OKC->D2_COD
						If aEtiqueta[x][4] < OKC->QTE - TRB->QUANTID
							cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
							sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
							cProduto := Space(nLenPrd)
							dbSelectArea("TRB")
							dbGoTop()
							OKC->(DbCloseArea())
							Return
						Else
							lVer := .F.
						Endif
					Endif
				Next
				If lVer
					AADD(aEtiqueta,{cCliente,cLoja,OKC->D2_COD,OKC->QTE,OKC->D2_PEDIDO,cNota,cSerie,SB1->B1_XMIUDEZ,SB1->B1_XNVOLAX})
				Endif
			
			ElseIf SB1->B1_XMIUDEZ == "M"// 08/09/2024 - Opção de conferência de item Múltiplos volumes 
				
				DbSelectArea("TRB")
				DbGoTop()
				If dbSeek(OKC->D2_COD)
					If OKC->QTE <> TRB->QUANTID
						cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->D2_COD
						sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
						cProduto := Space(nLenPrd)
						DbSelectArea("TRB")
						DbGoTop()
						OKC->(DbCloseArea())
						Return
					Endif
				Else
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) 
					cMsg += "Produto: " + OKC->D2_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					cProduto := Space(nLenPrd)
					DbSelectArea("TRB")
					DbGoTop()
					OKC->(DbCloseArea())
					Return
				Endif
				lVer := .T.
				For x := 1 To Len(aEtiqueta)
					If aEtiqueta[x][3] == OKC->D2_COD
						If aEtiqueta[x][4] < OKC->QTE - TRB->QUANTID
							cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
							sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
							cProduto := Space(nLenPrd)
							dbSelectArea("TRB")
							dbGoTop()
							OKC->(DbCloseArea())
							Return
						Else
							lVer := .F.
						Endif
					Endif
				Next
				If lVer
					AADD(aEtiqueta,{cCliente,cLoja,OKC->D2_COD,1,OKC->D2_PEDIDO,cNota,cSerie,SB1->B1_XMIUDEZ,SB1->B1_XNVOLAX})
				Endif

			ElseIf SB1->B1_XMIUDEZ == "X" 
				
				DbSelectArea("TRB")
				DbGoTop()
				If dbSeek(OKC->D2_COD)
					cMsg := "Produto configurado como Miudeza = 'Software' e que não precisa de conferência "+ Chr(13) + "Produto: " + OKC->D2_COD
					sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
					cProduto := Space(nLenPrd)
					DbSelectArea("TRB")
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

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exibe tela solicitando numero de etiquetas diversas                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Volumes diversos")
	@ 02,10 TO 070,190
	@ 10,018 Say "Informe o numero de volumes diversos:"
	@ 10,120 Get nDiversos Picture "@E 99999" Size 30,10 Valid sfVldDiv(nDiversos)
	
	//@ 30,018 Say "SOMENTE INFORME A QUANTIDADE VOLUMES DIVERSOS "
	//@ 39,018 Say "PARA OS ITENS QUE TIVERAM QUE SER ENCAIXOTADOS"
	
	@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION Iif(sfVldDiv(nDiversos),(sfPrintEtq(),oDlg1:End(),fechar()),Nil)

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return
/*/{Protheus.doc} sfVldDiv
Função para validar o preenchimento dos volumes diversos
@type function
@version  
@author Marcelo Alberto Lauschner
@since 11/11/2021
@param nInDiv, numeric, param_description
@return variant, return_description
/*/
Static Function sfVldDiv(nInDiv)

	Local 	lRet  	:= .T. 

	If nVolDiv > 0 
		If nInDiv <= 0
			cMsg := "Houve produtos conferidos com perfil Miudeza = Sim, mas não foi informado o número de volumes diversos! Favor informar o número de volumes diversos!"
			sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
			lREt := .F. 
		Endif 
	Endif 

Return lRet 

/*/{Protheus.doc} sfPrintEtq
//  Rotina responsável por chamar a impressão das etiquetas do pedido conferido
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static function sfPrintEtq()

	If Len(aEtiqueta) <> 0 .Or. !Empty(nDiversos)

		U_MLFATA04(aEtiqueta,nDiversos,cPedido,cNota,cSerie,cCliente,cLoja,cTipo)//LABEL
		//  Alert(Len(aEtiqueta))
		MsgInfo("Pedido liberado com sucesso","Informacao")
	Endif

Return

/*/{Protheus.doc} sfMsgAlert
// Gera uma tela de mensagem de Alerta conforme texto passado por parâmetro
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@param cMsg, characters, descricao
@type Static Function
/*/
Static Function sfMsgAlert(cMsg,cInTitle)
	Local	oDlg1

	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Informação. " + cInTitle )
	@ 02,10 TO 070,190
	@ 10,018 Say cMsg color 128

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return


/*/{Protheus.doc} sfVldSDB
Função para validar produto com controle de Série/Localização
@type function
@version
@author Marcelo Alberto Lauschner
@since 21/10/2020
@param cInProd, character, param_description
@return return_type, return_description
/*/
Static Function sfVldSDB(cInProd,cInNumSeri)

	Local	aAreaOld	:= GetArea()
	Local	oDlgConfSDB
	Local	aCamposSDB	:= {}
	Private lVldRet		:= .F.
	Private	oBrw2
	Private	nQteSDB		:= 1
	Private	cCodSDB		:= Padr(" ",TamSX3("DB_NUMSERI")[1])
	Private oCodSDB
	Private aSDBConf	:= {}

	@ 01,01 TO 250,510 DIALOG oDlgConfSDB TITLE "Conferência do produto " + cInProd + " Serial sugerido " + cInNumSeri


	aAdd(aCamposSDB,{ "PRODUTO" 	, "Produto"})
	aAdd(aCamposSDB,{ "ENDER"  		, "Endereço"})
	aAdd(aCamposSDB,{ "QUANTID" 	, "Quantidade"})
	Aadd(aCamposSDB,{ "NUMSERI"   	, "Número Serial"})

	dbSelectArea("TRB2")
	dbGotop()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica o cliente referente ao pedido                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 05,010 Get nQteSDB Picture "@E 99999" Size 10,10 When .F.
	@ 05,035 SAY " X "
	@ 05,050 SAY "Número Serial : "
	@ 05,090 Get cCodSDB Valid sfValSDB(cInProd) Size 50,10 Object oCodSDB

	@ 025,005 TO 100,255 BROWSE "TRB2" OBJECT oBrw2 FIELDS aCamposSDB

	@ 110,140 BUTTON "Confirma" SIZE 40,13 Action (lVldRet := .T.,oDlgConfSDB:End())
	@ 110,190 BUTTON "Fechar" SIZE 40,13 Action (lVldRet := .F.,oDlgConfSDB:End())

	ACTIVATE MSDIALOG oDlgConfSDB CENTERED

	lVldRet := sfGrvSDB(lVldRet)

	RestArea(aAreaOld)

Return lVldRet

/*/{Protheus.doc} sfValSDB
Função para validação do Serial digitado
@type function
@version
@author Marcelo Alberto Lauschner
@since 21/10/2020
@param cInProd, character, param_description
@return return_type, return_description
/*/
Static Function sfValSDB(cInProd)

	Local	cQry
	Local	lRet	:= .T.


	cQry := "SELECT DB_NUMSERI,DB_QUANT,DB_LOCALIZ "
	cQry += "  FROM " + RetSqlName("SDB") + " DB "
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND DB_ESTORNO = ' ' "
	cQry += "   AND DB_LOJA = '" + cLoja + "'"
	cQry += "   AND DB_CLIFOR = '" + cCliente + "'"
	cQry += "   AND DB_SERIE = '" + cSerie + "'"
	cQry += "   AND DB_DOC = '" + cNota + "' "
	cQry += "   AND DB_PRODUTO = '" + cInProd + "' "
	cQry += "   AND DB_NUMSERI = '" + cCodSDB + "' "
	cQry += "   AND DB_FILIAL = '" + xFilial("SDB") + "' "


	TCQUERY cQry NEW ALIAS "QSDB"

	If !Eof()
		dbSelectArea("TRB2")
		If dbSeek(QSDB->DB_NUMSERI)
			cMsg := "Código de Serial já conferido" +Chr(13)
			cMsg += "Serial Número: " + cCodSDB
			sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))) )
			lRet	:= .F.
		Else
			lRet	:= .T.
			Aadd(aSDBConf,{	cInProd,;
				cCodSDB,;
				nQteSDB})
			DbSelectArea("TRB2")
			RecLock("TRB2",.T.)
			TRB2->PRODUTO	:= cInProd
			TRB2->ENDER		:= QSDB->DB_LOCALIZ
			TRB2->QUANTID	:= nQteSDB
			TRB2->NUMSERI	:= QSDB->DB_NUMSERI
			MsUnlock()
			cSerUsed		+= QSDB->DB_NUMSERI+"/"
		Endif
	ElseIf !Empty(cCodSDB)
		cMsg := "Código de Serial não atribuído a esta nota fiscal " +Chr(13)
		cMsg += "Serial Número: " + cCodSDB
		sfMsgAlert(cMsg,FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
		lRet	:= .F.
	Endif
	QSDB->(DbCloseArea())

	If !Empty(cCodSDB)
		oBrw2:oBrowse:Refresh()
		cCodSDB := Space(TamSX3("DB_NUMSERI")[1])
		oCodSDB:SetFocus()
	Endif

Return lRet


/*/{Protheus.doc} sfGrvSDB
Função que efetua a gravação do Serial conferido
@type function
@version
@author Marcelo Alberto Lauschner
@since 21/10/2020
@param lInGrv, logical, param_description
@return return_type, return_description
/*/
Static Function sfGrvSDB(lInGrv)

	Local	lRet	:= lInGrv
	Local 	iX 

	If !lInGrv
		For iX := 1 To Len(aSDBConf)
			dbSelectArea("TRB2")
			If dbSeek(aSDBConf[iX,2])
				DbSelectArea("TRB2")
				RecLock("TRB2",.F.)
				DbDelete()
				MsUnlock()
			Endif
		Next

		dbSelectArea("TRB")
		dbGoTop()
		nQuant := 1
		oBrw:oBrowse:Refresh()
		cProduto := Space(TamSX3("B1_COD")[1])
		oProduto:SetFocus()
	Else
		dbSelectArea("TRB")
		If dbSeek(QRY->B1_COD)
			RecLock("TRB",.F.)
			TRB->QUANTID := 0
			MsUnlock()
		Else
			RecLock("TRB",.T.)
			TRB->QUANTID := 0
			TRB->PRODUTO := QRY->B1_COD
			TRB->DESC	 := QRY->B1_DESC
			TRB->UM		 := QRY->B1_UM
			MsUnLock()
		Endif

		dbSelectArea("TRB2")
		DbGotop()
		While !Eof()
			If TRB2->PRODUTO == TRB->PRODUTO
				dbSelectArea("TRB")
				RecLock("TRB",.F.)
				TRB->QUANTID	+= TRB2->QUANTID
				MsUnlock()
			Endif

			dbSelectArea("TRB2")
			DbSkip()
		Enddo

		dbSelectArea("TRB")
		dbGoTop()
		nQuant := 1
		oBrw:oBrowse:Refresh()
		cProduto := Space(TamSX3("B1_COD")[1])
		oProduto:SetFocus()

	Endif

Return lRet

/*/{Protheus.doc} sfAlterPrd
// Interface para que seja informado o código do produto que se deseja alterar e ajustar
@author Marcelo Alberto Lauschner
@since 18/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static Function sfAlterPrd()

	Local	oDlgNext
	Private cCodpro   		:= Space(nLenPrd)
	Private cCodproa   		:= Space(nLenPrd)
	Private cEanloc 		:= Space(15)

	Private cLocPrd	 		:= Space (10)
	Private cDun14A 		:= Space (15)
	Private cDun14B   		:= Space (15)
	Private nConvA  		:= 0.00
	Private nConvB  		:= 0.00
	Private cMiudeza  		:= Space (1)
	Private nPeso	  		:= 0.00
	Private nPesBru			:= 0.00
	Private nVolAdd			:= 0
	Private aItems 			:= {"","S=Sim","N=Não","H=Híbrido","X=Software","M=Múltiplos Volumes"}
	Private cCombo 			:= Space(1)
	Private cMiudz    		:= Space(1)

	@ 200,1 TO 380,395 DIALOG oDlgNext TITLE OemToAnsi("Alterar dados logísticos para separação,conferência e organização.")
	@ 02,10 TO 070,190
	@ 10,018 Say "Código produto:"
	@ 10,070 Get cCodpro F3 "SB1" size 50,10
	@ 30,018 Say "Digite o código de barra: "
	@ 30,100 Get cEanloc size 60,10
	@ 72,133 BMPBUTTON TYPE 01 ACTION (Close(oDlgNext),sfSearchPrd())
	@ 72,163 BMPBUTTON TYPE 02 ACTION Close(oDlgNext)

	Activate Dialog oDlgNext Centered

Return


/*/{Protheus.doc} sfSearchPrd
// Função para pesquisar o código de produto
@author marce
@since 26/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static Function sfSearchPrd()

	If !Empty(cEanloc) .And. Empty(cCodpro)
		dbselectarea("SB1")
		dbsetorder(5)
		If dbseek(xFilial("SB1")+cEanloc)
			cCodproa := SB1->B1_COD
			sfAltPrd()
		Else
			MsgAlert("Código de barra não cadastrado!!!","Atencao!")
		Endif
	Elseif Empty(cEanloc) .and. !Empty(cCodpro)
		Dbselectarea("SB1")
		dbsetorder(1)
		If Dbseek(xFilial("SB1")+cCodpro)
			cCodproa := SB1->B1_COD
			sfAltPrd()
		Else
			MsgAlert("Código de produto inexistente. Favor consulte novamente!! Utilize F3 para pesquisar.","Atencao!")
		Endif
	Elseif !Empty(cEanloc) .and. !empty(cCodpro)
		MsgAlert("Favor entre só com uma informação. Código do produto ou só código de Barra.","Atencao!")
	Endif

Return


/*/{Protheus.doc} sfAltPrd
// Tela de edição de dados logisticos
@author Marcelo Alberto Lauschner
@since 26/09/2019
@version 1.0
@return ${return}, ${return_description}
@type Static Function
/*/
Static function sfAltPrd()

	Local	oDlgAltPrd
	cCodproa   := SB1->B1_COD

	@ 270,1 TO 490,595 DIALOG oDlgAltPrd TITLE OemToAnsi("Alterar dados logísticos.")
	@ 02,05 TO 080,290
	@ 10,018 Say SB1->B1_COD
	@ 10,060 Say SB1->B1_DESC
	@ 20,018 Say "Endereço: "
	@ 20,060 Say SB1->B1_XLOCAL
	@ 20,110 Get cLocPrd Picture "@R 99.99.9.X" size 50,10

	@ 32,018 Say "Cód.Dun 14 A:"
	@ 32,060 Say SB1->B1_XDUN14A
	@ 32,110 Get cDun14A  size 50,10

	@ 32,170 Say "Conv 14 A:"
	@ 32,205 Say SB1->B1_XCONVA
	@ 32,230 Get nConvA Picture "@E 999,999" size 20,10

	@ 44,018 Say "Cód.Dun 14 B:"
	@ 44,060 SAY SB1->B1_XDUN14B
	@ 44,110 Get cDun14B size 50,10

	@ 44,170 Say "Conv 14 B:"
	@ 44,209 SAY SB1->B1_xCONVB
	@ 44,230 Get nConvB Picture "@E 999,999" size 20,10

	@ 56,018 Say "Miudeza:"
	@ 56,050 SAY SB1->B1_XMIUDEZ
	@ 56,070 COMBOBOX cMiudeza ITEMS aItems size 45,10

	@ 68,018 Say "Qte Volumes:"
	@ 68,050 SAY SB1->B1_XNVOLAX
	@ 68,070 Get nVolAdd Picture "@E 999,999" size 20,10

	@ 56,170 Say "Peso Líquido:"
	@ 56,209 SAY SB1->B1_PESO
	@ 56,230 Get nPeso Picture "@E 999,999.999" size 40,10

	@ 68,170 Say "Peso Bruto:"
	@ 68,209 SAY SB1->B1_PESBRU
	@ 68,230 Get nPesBru Picture "@E 999,999.999" size 40,10

	@ 82,133 BMPBUTTON TYPE 01 ACTION (Close(oDlgAltPrd),sfGrvAlt())
	@ 82,163 BMPBUTTON TYPE 02 ACTION (Close(oDlgAltPrd),Close(oDlgAltPrd))

	Activate Dialog oDlgAltPrd Centered


Return

/*/{Protheus.doc} sfGrvAlt
// Rotina de gravação dos dados logísticos informados.
@author Marcelo Alberto Lauschner
@since 26/09/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function sfGrvAlt()

	dbSelectArea("SB1")
	dbSetOrder(1)
	If DbSeek(xFilial("SB1")+cCodproa)
		dbSelectArea("SB1")
		RecLock("SB1",.F.)
		If !Empty(nPeso)
			SB1->B1_PESO   	:= nPeso
		Endif
		If !Empty(nPesBru) 
			SB1->B1_PESBRU  := nPesBru
		Endif
		If !Empty(cLocPrd) 
			SB1->B1_XLOCAL 	:= cLocPrd
		Endif 
		If !Empty(cMiudeza)
			SB1->B1_XMIUDEZ := cMiudeza
		Endif 
		If !Empty(nConvB)
			SB1->B1_XCONVB  := nConvB
		Endif 
		If !Empty(cDun14B)
			SB1->B1_XDUN14B := cDun14B
		Endif 
		If !Empty(cDun14A)
			SB1->B1_XDUN14A := cDun14A
		Endif 
		If !Empty(nConvA)
			SB1->B1_XCONVA  := nConvA
		Endif 
		If !Empty(nVolAdd)
			SB1->B1_XNVOLAX := nVolAdd
		Endif 
		MSUnLock()

		MsgInfo("Entrada de Dados Realizada com sucesso!!","Informação. " + FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
	Else
		MsgAlert("Erro na alteração. Favor contate CPD ","Informação. " + FunName() + "." + ProcName(0) + "."+ Alltrim(Str(ProcLine(0))))
	Endif
Return
