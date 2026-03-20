#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


User Function DIS060P()

Return U_BFFATA51()


/*/{Protheus.doc} BFFATA51
(Liberacao fisica do pedido via leitor otico )
@author Marcelo Lauschner
@since 19/02/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA51()



	Private cPedido   	:= Space(6)
	Private nLenPrd	  	:= TamSX3("C6_PRODUTO")[1]
	Private cProduto  	:= Space(nLenPrd)
	Private nQuant    	:= 1
	Private lFixaMain 	:= .F.
	Private oProduto
	Private oBrw
	Private aEtiqueta 	:= {}
	Private lVer      	:= .F.
	Private nDiversos 	:= 0
	Private nConv     	:= 0
	Private cCliente  	:= Space(TamSX3("C5_CLIENTE")[1])
	Private cLoja     	:= Space(TamSX3("C5_LOJACLI")[1])
	Private cMsg      	:= ""
	Private cTipo     	:= Space(1)
	Private oDlgConf

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exibe tela solicitando numero do pedido                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Liberacao Fisica do Pedido")
	@ 02,10 TO 070,190
	@ 10,018 Say "Pedido"
	@ 10,070 Get cPedido Picture "@!" Size 30,10
	@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION oDlg1:End()

	ACTIVATE MSDIALOG oDlg1 CENTERED

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o pedido existe                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	dbSelectArea("SC5")
	dbSetOrder(1)
	If !dbSeek(xFilial("SC5")+cPedido)
		MsgAlert("Nao existem registros relacionados a este pedido!","Não existe registro")
		Return
	Endif

	cQrp := ""
	cQrp += "SELECT C9_ORDSEP "
	cQrp += "  FROM "+ RetSqlName("SC9")
	cQrp += " WHERE D_E_L_E_T_ = ' ' "
	cQrp += "   AND C9_FLGENVI <> ' ' "
	cQrp += "   AND C9_XWMSPED > 0 " // Campo WMS PEDIDO informa se o pedido já foi enviado para separação ou não via EDI
	cQrp += "   AND C9_BLEST = ' ' "
	cQrp += "   AND C9_BLCRED = ' ' "
	cQrp += "   AND C9_NFISCAL = '      ' "
	cQrp += "   AND C9_SERIENF = '   ' "
	cQrp += "   AND C9_PEDIDO = '" + cPedido +  "' "
	cQrp += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
	cQrp += " GROUP BY C9_ORDSEP "

	TcQuery cQrp New Alias "QRS"

	// Verifica se há dados na rotina de separação de coletor para que não h
	DbSelectArea("CB7")
	DbSetOrder(1)
	If DbSeek(xFilial("CB7")+QRS->C9_ORDSEP)
		If CB7->CB7_VOLEMI == "1"
			QRS->(DbCloseArea())
			MsgAlert("Este pedido já teve os volumes emitidos pela rotina de Coletor","Etiquetas emitidas")
			Return
		Endif

		RecLock("CB7",.F.)
		CB7->CB7_STATUS	:= "1" // Atualiza o pedido para nào ser lido no Coletor
		MsUnlock()
	Endif
	QRS->(DbCloseArea())

	cCliente := SC5->C5_CLIENTE
	cLoja    := SC5->C5_LOJACLI
	cTipo    := SC5->C5_TIPO

	lFixaMain := .F.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria Arquivo temporario                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	aStru:={}

	Aadd(aStru,{ "PRODUTO", "C", nLenPrd	, 0 } )
	Aadd(aStru,{ "DESC"   , "C", 50		 	, 0 } )
	Aadd(aStru,{ "QUANTID", "N", 12			, 2 } )
	Aadd(aStru,{ "UM"     , "C", 02			, 0 } )

	cArq := CriaTrab(aStru,.t.)
	If Select("TRB") > 0
		TRB->(DbCloseArea())
	Endif
	dbUseArea ( .T.,__localdriver, cArq, "TRB", NIL, .F. )

	IndRegua("TRB", cArq,"PRODUTO",,,"Selecionando registros...")

	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exibe arquivos a serem liberados                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 01,01 TO 530,755 DIALOG oDlgConf TITLE "Liberacao Fisica do Pedido ---> " + cPedido

	aCampos := {}
	aAdd(aCampos,{ "PRODUTO" , "Produto"})
	aAdd(aCampos,{ "DESC"    , "Descricao"})
	aAdd(aCampos,{ "QUANTID" , "Quantidade"})
	aAdd(aCampos,{ "UM"      , "UM"})

	dbSelectArea("TRB")
	dbGotop()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica o cliente referente ao pedido                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 05,010 Get nQuant Picture "@E 99999" Size 10,10
	@ 05,035 SAY " X "
	@ 05,050 SAY "Produto: "
	@ 05,080 Get cProduto Valid Processa({|| ValProd() },"Processando...") Size 50,10 Object oProduto

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Existe historicos ja gravados                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 025,005 TO 233,370 BROWSE "TRB" OBJECT oBrw FIELDS aCampos

	//oBrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}

	@ 239,240 BUTTON "Confirma" SIZE 40,13 ACTION sfConfirma()
	@ 239,290 BUTTON "Fechar" SIZE 40,13 ACTION Sair()
	@ 239,150 BUTTON "Alterar produto" SIZE 60,13 Action  U_BIG007(.T.)

	ACTIVATE MSDIALOG oDlgConf CENTERED Valid lFixaMain

	TRB->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index
	
Return


/*/{Protheus.doc} Fechar
(long_description)
@author MarceloLauschner
@since 28/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Fechar()

	lFixaMain := .T.
	oDlgConf:End()

Return


/*/{Protheus.doc} Sair
(long_description)
@author MarceloLauschner
@since 28/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Sair()

	If MsgYesNo("Confirma Saida ? ","Escolha")
		lFixaMain := .T.
		oDlgConf:End()
	Endif

Return


/*/{Protheus.doc} Produto
(long_description)
@author MarceloLauschner
@since 28/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Produto()

	Local cSenhaval := Alltrim(Substr(dtos(dDatabase),3,2)+Substr(time(),1,2)+Substr(dtos(dDatabase),7,2))
	Local cSei := Space(6)

	@ 01,01 TO 130,255 DIALOG oProd TITLE "Informe a senha de supervisor"
	@ 010,005 Say "Digite a senha-->>"
	@ 010,055 Get cSei PASSWORD
	@ 030,060 Button "Continua" size 40,15 action (IIf(cSei==cSenhaval,(U_BIG007(.T.),oProd:End()),oProd:End()))
	@ 030,005 Button "Cancela" size 40,15 action oProd:End()

	ACTIVATE DIALOG oProd CENTERED

Return


/*/{Protheus.doc} ValProd
(long_description)
@author MarceloLauschner
@since 28/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function ValProd()

	Local 	_aArea   := GetArea()
	Local 	x
	// Remove aspas simples da digitação do código do produto
	cProduto := StrTran(cProduto,"'","")

	If !Empty(cProduto)

		cQry := ""
		cQry += "SELECT B1_COD,B1_UM,B1_CODBAR,B1_DUN14,B1_DUN14A,B1_MIUD,B1_CONVB,B1_CONVA,B1_DESC,B1_LOCAL "
		cQry += "  FROM "+ RetSqlName("SB1")
		cQry += " WHERE D_E_L_E_T_ <> '*' "
		cQry += "   AND B1_COD != '"+cProduto+"' " // Não permite que o código do produto seja usado para conferência
		cQry += "   AND (B1_CODBAR = '" + cProduto + "' OR B1_DUN14 = '" + cProduto + "' OR B1_DUN14A = '" + cProduto + "') "
		cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "

		TCQUERY cQry NEW ALIAS "QRY"

		If Eof()
			cMsg := "Produto sem codigo de barras ou " +Chr(13)
			cMsg += "nao Cadastrado: " + cProduto
			Mensagem(cMsg)
			QRY->(DbCloseArea())
			Return(.F.)
		Endif

		cQrp := ""
		cQrp += "SELECT SUM(C9_QTDLIB) QTE, C9_PRODUTO "
		cQrp += "  FROM "+ RetSqlName("SC9")
		cQrp += " WHERE D_E_L_E_T_ = ' ' "
		cQrp += "   AND C9_FLGENVI <> ' ' "
		cQrp += "   AND C9_XWMSPED > 0 " // Campo WMS PEDIDO informa se o pedido já foi enviado para separação ou não via EDI
		cQrp += "   AND C9_BLEST = ' ' "
		cQrp += "   AND C9_BLCRED = ' ' "
		cQrp += "   AND C9_NFISCAL = '      ' "
		cQrp += "   AND C9_SERIENF = '   ' "
		cQrp += "   AND C9_PEDIDO = '" + cPedido +  "' "
		cQrp += "   AND C9_CLIENTE = '" + cCliente + "' "
		cQrp += "   AND C9_LOJA = '" + cLoja + "' "
		cQrp += "   AND C9_PRODUTO = '" + QRY->B1_COD + "' "
		cQrp += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
		cQrp += " GROUP BY C9_PRODUTO "

		TCQUERY cQrp NEW ALIAS "CONF"

		If Eof()
			cMsg := "Produto nao Pertence a Nota Fiscal: " + QRY->B1_COD
			Mensagem(cMsg)
			QRY->(DbCloseArea())
			CONF->(DbCloseArea())
			Return(.F.)
		Else
			dbSelectArea("TRB")
			If dbSeek(QRY->B1_COD)
				nConv := 0
				If QRY->B1_DUN14 == cProduto
					nConv := IIf(QRY->B1_CONVB==0,1,QRY->B1_CONVB) * nQuant
					lVer  := .T.
				Elseif QRY->B1_DUN14A == cProduto
					nConv := QRY->B1_CONVA  * nQuant
					lVer  := .F.
				Elseif QRY->B1_CODBAR == cProduto
					nConv := 1  * nQuant
					lVer  := .F.
				Endif
				
				If lVer
					If QRY->B1_MIUD == "N" .And. ((CONF->QTE / nConv) >= 1)
						If TRB->QUANTID >= Mod(CONF->QTE,nConv)
							lVer := .T.
							For x := 1 To Len(aEtiqueta)
								If aEtiqueta[x][3] == CONF->C9_PRODUTO
									lVer := .F.
								Endif
							Next
							If lVer
								AADD(aEtiqueta,{	cCliente,;
									cLoja,;
									CONF->C9_PRODUTO,;
									((CONF->QTE-Mod(CONF->QTE,nConv))/nConv),;
									cPedido,;
									"Endereco: "+QRY->B1_LOCAL,;
									nConv})
							Endif
							cMsg := "Produto excedeu a quantidade liberada. " + QRY->B1_COD
							Mensagem(cMsg)
							CONF->(DbCloseArea())
							QRY->(DbCloseArea())
							Return(.F.)
						Endif
					Endif
				Endif
				If QRY->B1_MIUD == "N" .And. nConv > (Mod(CONF->QTE,IIf(QRY->B1_CONVB==0,1,QRY->B1_CONVB)) - TRB->QUANTID )
					cMsg := "Excede qtde produto como caixa aberta " + QRY->B1_COD
					Mensagem(cMsg)
					CONF->(DbCloseArea())
					QRY->(DbCloseArea())
					Return(.F.)
				Endif


				If TRB->QUANTID + nConv > CONF->QTE
					cMsg := "Produto excedeu a qtde liberada. " + QRY->B1_COD
					Mensagem(cMsg)
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif
				
				RecLock("TRB",.F.)
				TRB->QUANTID += 1 * nConv
			Else
				nConv := 0
				If QRY->B1_DUN14 == cProduto
					nConv := IIf(QRY->B1_CONVB==0,1,QRY->B1_CONVB) * nQuant
				Elseif QRY->B1_DUN14A == cProduto
					nConv := QRY->B1_CONVA * nQuant
				Elseif QRY->B1_CODBAR == cProduto
					nConv := 1 * nQuant
				Endif
				
				If nConv > CONF->QTE
					cMsg := "Produto excedeu a qtde liberada. " + QRY->B1_COD
					Mensagem(cMsg)
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif
				If QRY->B1_MIUD == "N" .And. nConv > (Mod(CONF->QTE,IIf(QRY->B1_CONVB==0,1,QRY->B1_CONVB)))
					cMsg := "Excede qtde produto como caixa aberta " +Chr(13)
					cMsg += "Produto: " +  QRY->B1_COD
					Mensagem(cMsg)
					QRY->(DbCloseArea())
					CONF->(DbCloseArea())
					Return(.F.)
				Endif

				
				RecLock("TRB",.T.)
				TRB->QUANTID := 1 * nConv
			Endif
			TRB->PRODUTO := QRY->B1_COD
			TRB->DESC	 := QRY->B1_DESC
			TRB->UM		 := QRY->B1_UM
			MsUnLock()

		Endif
		CONF->(DbCloseArea())
		QRY->(DbCloseArea())

		dbSelectArea("TRB")
		dbGoTop()
		nQuant := 1
		oBrw:oBrowse:Refresh()
		cProduto := Space(nLenPrd)
		oProduto:SetFocus()

	Endif

Return



/*/{Protheus.doc} sfConfirma
(Confirmação do pedido)
@author MarceloLauschner
@since 28/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfConfirma()

	Local 	x
	Local 	iW 
	Private cBox    := Space(2)
	Private cSep   	:= Space(1)
	Private cMesa   := Space(1)
	Private cConf   := Space(1)

	cQrp := ""
	cQrp += "SELECT SUM(C9_QTDLIB) QTE,C9_PRODUTO "
	cQrp += "  FROM "+ RetSqlName("SC9") + "  "
	cQrp += " WHERE D_E_L_E_T_ = ' ' "
	cQrp += "   AND C9_FLGENVI <> ' ' "
	cQrp += "   AND C9_XWMSPED > 0 " // Campo WMS PEDIDO informa se o pedido já foi enviado para separação ou não via EDI
	cQrp += "   AND C9_BLEST = ' ' "
	cQrp += "   AND C9_BLCRED = ' ' "
	cQrp += "   AND C9_NFISCAL = '      ' "
	cQrp += "   AND C9_SERIENF = '   ' "
	cQrp += "   AND C9_PEDIDO = '" + cPedido +  "' "
	cQrp += "   AND C9_LOJA = '" + cLoja + "' "
	cQrp += "   AND C9_CLIENTE = '" + cCliente + "' "
	cQrp += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
	cQrp += " GROUP BY C9_PRODUTO "

	TCQUERY cQrp NEW ALIAS "OKC"

	While !Eof()

		DbSelectArea("SB1")
		DbSetOrder(1)
		If dbseek(xFilial("SB1")+OKC->C9_PRODUTO)

			If SB1->B1_MIUD == "S"
				dbSelectArea("TRB")
				If dbSeek(OKC->C9_PRODUTO)
					If OKC->QTE > TRB->QUANTID
						cMsg := "A qtde separada esta menor que a quantidade faturada"+Chr(13)
						cMsg += "Produto: " + OKC->C9_PRODUTO
						Mensagem(cMsg)
						dbSelectArea("TRB")
						dbGoTop()
						OKC->(DbCloseArea())
						Return .F.
					Endif
				Else
					cMsg := "A qtde separada esta menor que a quantidade faturada"+ Chr(13)
					cMsg += "Produto: " + OKC->C9_PRODUTO
					Mensagem(cMsg)
					dbSelectArea("TRB")
					dbGoTop()
					OKC->(DbCloseArea())
					Return .F.
				Endif
			Elseif SB1->B1_MIUD == "N" .And. ((OKC->QTE / IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)) >= 1)
				dbSelectArea("TRB")
				If dbSeek(OKC->C9_PRODUTO)
					If Mod(OKC->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)) <> TRB->QUANTID
						cMsg := "A qtde sep. esta div. da qtd fat"+ Chr(13)
						CMsg += "Produto: " + OKC->C9_PRODUTO
						Mensagem(cMsg)
						dbSelectArea("TRB")
						dbGoTop()
						OKC->(DbCloseArea())
						Return .F.
					Endif
				Elseif Mod(OKC->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)) <> 0
					cMsg := "A qtde sep. esta menor que a qtde fat"+ Chr(13)
					CMsg += "Produto: "+ OKC->C9_PRODUTO
					Mensagem(cMsg)
					dbSelectArea("TRB")
					dbGoTop()
					OKC->(DbCloseArea())
					Return .F.
				Endif
				lVer := .T.
				For x := 1 To Len(aEtiqueta)
					If aEtiqueta[x][3] == OKC->C9_PRODUTO
						If aEtiqueta[x][4] < ((OKC->QTE - Mod(OKC->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)))/IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB))
							cMsg := "A qtde sep esta menor que a qtde fat"+ Chr(13)
							cMsg +=	"Produto: "+ OKC->C9_PRODUTO
							Mensagem(cMsg)
							dbSelectArea("TRB")
							dbGoTop()
							OKC->(DbCloseArea())
							Return .F.
						Else
							lVer := .F.
						Endif
					Endif
				Next
				If lVer
					AADD(aEtiqueta,{	cCliente,;
						cLoja,;
						OKC->C9_PRODUTO,;
						((OKC->QTE-Mod(OKC->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)))/IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)),;
						cPedido,;
						"Endereco: "+SB1->B1_LOCAL,;
						OKC->QTE-Mod(OKC->QTE,IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB))})
				Endif
			Elseif SB1->B1_MIUD == "N" .And. ((OKC->QTE / IIf(SB1->B1_CONVB==0,1,SB1->B1_CONVB)) < 1)
				dbSelectArea("TRB")
				If dbSeek(OKC->C9_PRODUTO)
					If OKC->QTE <> TRB->QUANTID
						cMsg := "A qtde sep esta divergente da qtde fat"+ Chr(13)
						cMsg += "**Produto: "+ OKC->C9_PRODUTO
						Mensagem(cMsg)
						dbSelectArea("TRB")
						dbGoTop()
						OKC->(DbCloseArea())
						Return .F.
					Endif
				Else
					cMsg := "A qtde sep esta menor que a qtde fat"+ Chr(13)
					cMsg += "Produto: "+ OKC->C9_PRODUTO
					Mensagem(cMsg)
					dbSelectArea("TRB")
					dbGoTop()
					OKC->(DbCloseArea())
					Return .F.
				Endif
			Endif
		Endif

		dbSelectArea("OKC")
		dbSkip()

	Enddo

	OKC->(DbCloseArea())

	

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exibe tela solicitando numero de etiquetas diversas                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	@ 200,1 TO 380,395 DIALOG oDlg2 TITLE OemToAnsi("Volumes diversos")
	@ 02,10 TO 070,190
	@ 10,018 Say "Informe o numero de volumes diversos:"
	@ 10,120 Get nDiversos Picture "@E 99999" Size 30,10

	@ 20,018 Say "Box"
	@ 20,075 Get cBox Picture "@!"
	@ 30,018 Say "Separador"
	@ 30,075 Get cSep Picture "@!"
	@ 40,018 Say "Mesa"
	@ 40,075 Get cMesa Picture "@!"
	@ 50,018 Say "Conferente"
	@ 50,075 Get cConf Picture "@!"

	@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION oDlg2:End()

	ACTIVATE MSDIALOG oDlg2 CENTERED

	If Len(aEtiqueta) <> 0 .Or. !Empty(nDiversos)
		//U_DIS010P(aEtiqueta,nDiversos,cPedido,cCliente,cLoja,ctipo)//LABEL
		U_BFFATA53(aEtiqueta,nDiversos,cPedido,cCliente,cLoja,ctipo)//LABEL
		For iW := 1 To Len(aEtiqueta)
			sfAtuSC9(aEtiqueta[iW,3],aEtiqueta[iW,7])
		Next
		DbSelectArea("TRB")
		DbGotop()
		While !Eof()
			sfAtuSC9(TRB->PRODUTO,TRB->QUANTID)
			DbSelectArea("TRB")
			DbSkip()
		Enddo


	Endif

	MsgInfo("Pedido liberado com sucesso","Concluído")

	Fechar()

Return .T.

/*/{Protheus.doc} Mensagem
( Exibe tela com mensagem de nao conformidade        )
@author MarceloLauschner
@since 28/04/2016
@version 1.0
@param cMsg, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Mensagem(cMsg)

	@ 001,1 TO 180,595 DIALOG oDlg3 TITLE OemToAnsi("Informacao")
	@ 002,10 TO 070,290
	@ 008,018 Say cMsg color 128

	ACTIVATE MSDIALOG oDlg3 CENTERED

	nQuant := 1
	oBrw:oBrowse:Refresh()
	cProduto := Space(nLenPrd)
	oProduto:SetFocus()

Return


/*/{Protheus.doc} sfAtuSC9
(long_description)
@author MarceloLauschner
@since 28/04/2016
@version 1.0
@param cInProd, character, (Descrição do parâmetro)
@param nQteConf, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuSC9(cInProd,nQteConf)

	Local		aAreaOld	:= GetArea()
	Local		nQteLib		:= 0
	Local		nQteSep		:= 0
	Local		nQteAtu		:= nQteConf

	cQrp := ""
	cQrp += "SELECT C9_PEDIDO,C9_ITEM,C9_SEQUEN,C9_QTDLIB,C9_XWMSQTE,C9_ORDSEP "
	cQrp += "  FROM "+ RetSqlName("SC9") + "  "
	cQrp += " WHERE D_E_L_E_T_ = ' ' "
	cQrp += "   AND C9_XWMSQTE < C9_QTDLIB " // Garante que itens que ainda não foram totalmente conferidos
	cQrp += "   AND C9_FLGENVI <> ' ' "
	cQrp += "   AND C9_XWMSPED > 0 " // Campo WMS PEDIDO informa se o pedido já foi enviado para separação ou não via EDI
	cQrp += "   AND C9_BLEST = ' ' "
	cQrp += "   AND C9_BLCRED = ' ' "
	cQrp += "   AND C9_NFISCAL = '      ' "
	cQrp += "   AND C9_SERIENF = '   ' "
	cQrp += "   AND C9_PRODUTO = '"+cInProd+"' "
	cQrp += "   AND C9_PEDIDO = '" + cPedido +  "' "
	cQrp += "   AND C9_LOJA = '" + cLoja + "' "
	cQrp += "   AND C9_CLIENTE = '" + cCliente + "' "
	cQrp += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "

	//C9_XWMSQTE
	TcQuery cQrp NEW ALIAS "QAT"

	While !Eof()
		nQteLib	:= QAT->C9_QTDLIB
		nQteSep	:= QAT->C9_XWMSQTE
		// Se a quantidade informada é menor que o saldo entre o Liberado menos o que já foi separado
		If nQteAtu <= nQteLib - nQteSep
			DbSelectArea("SC9")
			DbSetOrder(1)
			If DbSeek(xFilial("SC9")+QAT->C9_PEDIDO+QAT->C9_ITEM+QAT->C9_SEQUEN)
				RecLock("SC9",.F.)
				SC9->C9_XWMSQTE	+= nQteAtu
				MsUnlock()
			Endif
			nQteAtu	:= 0
		Else
			DbSelectArea("SC9")
			DbSetOrder(1)
			If DbSeek(xFilial("SC9")+QAT->C9_PEDIDO+QAT->C9_ITEM+QAT->C9_SEQUEN)
				RecLock("SC9",.F.)
				SC9->C9_XWMSQTE	+= nQteLib - nQteSep
				MsUnlock()
			Endif
			nQteAtu	-= (nQteLib - nQteSep)
		Endif

		// Verifica se há dados na rotina de separação de coletor para que não h
		DbSelectArea("CB7")
		DbSetOrder(1)
		If DbSeek(xFilial("CB7")+QAT->C9_ORDSEP) .And. CB7->CB7_VOLEMI # "1"

			RecLock("CB7",.F.)
			CB7->CB7_VOLEMI	:= "1"
			CB7->CB7_STATUS	:= "9"
			CB7->CB7_PRESEP	:= cBox+cSep+cMesa+cConf
			CB7->CB7_DIVERG	:= ""
			MsUnlock()

			cQry := "UPDATE "+RetSqlName("CB6")
			cQry += "   SET CB6_STATUS = '3' "
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND CB6_PEDIDO = '"+cPedido+"' "
			cQry += "   AND CB6_STATUS IN('1','2') "
			cQry += "   AND CB6_FILIAL = '"+xFilial("CB6")+"' "

			TcSqlExec(cQry)
		Endif

		DbSelectArea("QAT")
		DbSkip()
	Enddo
	QAT->(DbCloseArea())

	RestArea(aAreaOld)

Return
