#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} DIS064
(Enviar workflow da confirmacao do pedido de compras )
@author Leonardo J Koerich Jr
@since 13/11/2002 
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function DIS064()
		
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Private aCampos   := {}
	Private cCadastro := OemToAnsi("Workflow de Aprovacao de Pedido de Compra")
	Private cMarca
	Private cObs   := Space(100)
	Private aItems := {"Sim","Nao"}
	Private cCombo := ""
	Private cEnvi  := ""
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria arquivo de trabalho                                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	
	CriaArq()
	
	aRotina := {{"Enviar","U_PRJ006A", 0 , 2}}
	cMarca  := GetMark()
	MarkBrow("TRB","OK",,aCampos,,cMarca)
	
Return


/*/{Protheus.doc} PRJ006A
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function PRJ006A()
	
	
	@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Informacoes Gerais")
	@ 02,10 TO 070,190
	@ 10,018 Say "Enviar Preco de Compra? "
	@ 10,100 COMBOBOX cCombo ITEMS aItems SIZE 40,10
	@ 25,018 Say "Enviar para Fornecedor ? "
	@ 25,100 combobox cEnvi Items aItems size 40,10
	@ 40,018 Say "Observacoes: "
	@ 40,070 Get cObs Size 120,10
	@ 75,050 BUTTON "Avancar--->" SIZE 40,10 ACTION Envia()
	@ 75,150 BUTTON "Fechar" SIZE 40,10 ACTION Close(oDlg1)
	
	ACTIVATE MSDIALOG oDlg1 CENTERED
	
Return



/*/{Protheus.doc} Envia
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Envia()
	
	Local iW 

	dbSelectArea("TRB")
	dbGotop()
	While !Eof()
		
		If !Marked("OK")
			dbSelectArea("TRB")
			dbSkip()
			Loop
		Endif
		
		dbSelectArea("SC7")
		dbSetOrder(1)
		If dbSeek(xFilial("SC7")+TRB->NUM)
			
			// Cria um novo processo...
			cProcess := "100001"
			cStatus  := "100001"
			oProcess := TWFProcess():New(cProcess,OemToAnsi("Confirmacao do Pedido de Compra"))
			
			//Abre o HTML criado
			If cCombo == "Sim"
				
				If IsSrvUnix()
					If File("/workflow/pedido_de_compras.htm")
						oProcess:NewTask("Gerando HTML","/workflow/pedido_de_compras.htm")
					Else
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/pedido_de_compras.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Return
					Endif
				Else
					oProcess:NewTask("Gerando HTML","\workflow\pedido_de_compras.htm")
				Endif
			Else
				
				If IsSrvUnix()
					If File("/workflow/pedido_de_compras1.htm")
						oProcess:NewTask("Gerando HTML","/workflow/pedido_de_compras1.htm")
					Else
						FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Não localizou arquivo  /workflow/pedido_de_compras1.htm"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Return
					Endif
				Else
					oProcess:NewTask("Gerando HTML","\workflow\pedido_de_compras1.htm")
				Endif
			Endif
			
			oProcess:cSubject := "Confirmacao do Pedido de Compra Nº --> "  + AllTrim(TRB->NUM)
			oProcess:bReturn  := ""
			oHTML := oProcess:oHTML
			
			oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
			oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
			oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
			oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
			oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
			oHtml:ValByName("INSC","Inscrição Estadual: " + SM0->M0_INSC)
			
			// Preenche os dados do cabecalho
			oHtml:ValByName("EMISSAO"   ,SC7->C7_EMISSAO)
			oHtml:ValByName("FORNECEDOR",SC7->C7_FORNECE)
			
			
			dbSelectArea('SA2')
			dbSetOrder(1)
			If dbSeek(xFilial('SA2')+SC7->C7_FORNECE+SC7->C7_LOJA)
				oHtml:ValByName("lb_nome",SA2->A2_NOME)
				//
				dbSelectArea("SE4")
				dbSetOrder(1)
				If dbSeek(xFilial("SE4")+SC7->C7_COND)
					oHtml:ValByName("lb_cond","(" + AllTrim(SC7->C7_COND) + ") " + SE4->E4_DESCRI)
				Else
					oHtml:ValByName("lb_cond","")
				Endif
				//
				//	oHtml:ValByName("lb_cond",SC7->C7_COND)
			Endif
			
			oHtml:ValByName("PEDIDO",SC7->C7_NUM)
			
			oProcess:fDesc := "Pedido de Compras Nº "+ SC7->C7_NUM
			
			IncProc("Processando itens do Pedido...")
			nTotal := 0
			nValImp	:= 0
			
			dbSelectArea("SC7")
			While !Eof() .And. xFilial("SC7") == SC7->C7_FILIAL .And. SC7->C7_NUM == TRB->NUM
				If cEnvi == "Sim"
					DbSelectArea("SC7")
					RecLock("SC7",.F.)
					SC7->C7_ENVIADO := "S"
					MsUnLock()
				Endif
				nTotal	 += SC7->C7_TOTAL
				nValImp	 += SC7->C7_VALSOL
				nValImp	 += SC7->C7_VALIPI
				
				dbSelectArea("SB1")
				dbSetOrder(1)
				dbSeek(xFilial('SB1')+SC7->C7_PRODUTO)
				
				AAdd((oHtml:ValByName("produto.item" )),SC7->C7_ITEM)
				If Empty(SB1->B1_FABRIC)
					AAdd((oHtml:ValByName("produto.codigo" )),SC7->C7_PRODUTO)
				Else
					AAdd((oHtml:ValByName("produto.codigo" )),SB1->B1_FABRIC)
				Endif
				AAdd((oHtml:ValByName("produto.descricao")),SB1->B1_DESC)
				
				If Empty(SC7->C7_QTSEGUM)
					AAdd((oHtml:ValByName("produto.quant")),TRANSFORM(SC7->C7_QUANT,'@E 999,999.99'))
				Else
					AAdd((oHtml:ValByName("produto.quant")),TRANSFORM( SC7->C7_QTSEGUM,'@E 999,999.99'))
				Endif
				
				If cCombo == "Sim"
					If !Empty(SB1->B1_CONV)
						AAdd((oHtml:ValByName("produto.preco")),TRANSFORM(Round(SC7->C7_PRECO * SB1->B1_CONV,2),'@E 999,999.99'))
					Else
						AAdd((oHtml:ValByName("produto.preco")),TRANSFORM(Round(SC7->C7_PRECO,2),'@E 999,999.99'))
					Endif
					AAdd((oHtml:ValByName("produto.total")),TRANSFORM(Round(SC7->C7_TOTAL,2),'@E 999,999.99'))
				Endif
				
				If Empty(SC7->C7_SEGUM)
					AAdd((oHtml:ValByName("produto.unid")),SB1->B1_UM)
				Else
					AAdd((oHtml:ValByName("produto.unid")),SC7->C7_SEGUM)
				Endif
				
				AAdd((oHtml:ValByName("produto.entrega")),DTOC(SC7->C7_DATPRF))
				
				dbSelectArea("SC7")
				dbSkip()
			Enddo
			
			oHtml:ValByName("lbValor",TRANSFORM(nTotal,'@E 99,999,999.99'))
			oHtml:ValByName("lbTotal",TRANSFORM(nTotal+nValImp,'@E 99,999,999.99'))
			oHtml:ValByName("observacao",cObs)
			If cCombo == "Sim"
				oHtml:ValByName("lbFrete",TRANSFORM(0,'@E 99,999.99'))
			Endif
			oProcess:ClientName(Substr(cUsuario,7,15))
			
			IncProc("Enviando Email para --> " + SA2->A2_EMAIL )
			If cEnvi == "Sim"
				cRecebe := U_BFFATM15(UsrRetMail(__cUserId) +";"+SA2->A2_EMAIL,"DIS064")
			Else
				cRecebe :=  U_BFFATM15(UsrRetMail(__cUserId) +";","DIS064")
			Endif
			// Trata a limpeza dos e-mails repetidos 
			cRecebe := IIf(!Empty(cRecebe),cRecebe+";","")	
			aOutMails	:= StrTokArr(cRecebe,";")
			cRecebe	:= ""
			For iW := 1 To Len(aOutMails)
				If !Empty(cRecebe)
					cRecebe += ";"
				Endif
				If IsEmail(aOutMails[iW]) .And. !(Alltrim(Upper(aOutMails[iW])) $ cRecebe)
					cRecebe	+= Upper(aOutMails[iW])
				Endif
			Next
			oProcess:cTo := cRecebe
			oProcess:Start()
			oProcess:Finish()

			// Força disparo dos e-mails pendentes do workflow
			WFSENDMAIL()
		Endif
		
		dbSelectArea("TRB")
		dbSkip()
	End
	
	MsgInfo("Processo Finalizado com Sucesso.")
	
	Close(oDlg1)
	CriaArq()
	
Return


/*/{Protheus.doc} CriaArq
(long_description)
@author MarceloLauschner
@since 14/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function CriaArq()

	// Local 	cCampo		:= ""
	Local 	cAlias		:= ""
	Local 	oTmpTable
	
	aCampos := {}
	aAdd(aCampos,{ "NUM"    ,"C", 06 , 0})
	aAdd(aCampos,{ "EMISSAO","D", 08 , 0})
	aAdd(aCampos,{ "FORNECE","C", 30 , 0})
	aAdd(aCampos,{ "TOTAL"  ,"N", 12 , 2})
	aAdd(aCampos,{ "OK"     ,"C", 02 , 0})
	
	If (Select("TRB") <> 0)
		dbSelectArea("TRB")
		dbCloseArea("TRB")
	Endif
	
	// cTrab := CriaTrab(aCampos)
	// dbUseArea(.T.,__localdriver,cTrab,"TRB",nil,.F.)
	// IndRegua("TRB",cTrab,"NUM",,,"Selecionando registros...")

	cAlias := "TRB"
	oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
	oTmpTable:Create()

	dbSelectArea(cAlias)
	
	cQry := ""
	cQry += "SELECT SUM(C7_TOTAL) AS TOTAL,C7_NUM,C7_EMISSAO,C7_FORNECE,C7_LOJA "
	cQry += "  FROM " + RetSqlName("SC7")
	cQry += " WHERE D_E_L_E_T_ <> '*' "
	cQry += "   AND C7_ENCER <> 'E' "
	cQry += "   AND C7_ENVIADO <> 'S' "
	cQry += "   AND C7_FILIAL = '"+ xFilial("SC7")+ "' "
	cQry += " GROUP BY C7_NUM,C7_EMISSAO,C7_FORNECE,C7_LOJA "
	
	If (Select("QRY") <> 0 )
		dbSelectArea("QRY")
		dbCloseArea("QRY")
	Endif
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	dbSelectArea("QRY")
	dbGoTop()
	While !Eof()
		
		dbSelectArea("TRB")
		RecLock("TRB",.T.)
		TRB->NUM     := QRY->C7_NUM
		TRB->EMISSAO := STOD(QRY->C7_EMISSAO)
		TRB->FORNECE := QRY->C7_FORNECE+QRY->C7_LOJA
		TRB->TOTAL   := QRY->TOTAL
		MsUnlock("TRB")
		
		dbSelectArea("QRY")
		dbSkip()
	Enddo
	
	QRY->(DbCloseArea())
	
	aCampos := {}
	aAdd(aCampos,{ "OK"     ,""," "})
	aadd(aCampos,{ "NUM"    ,"","Pedido"})
	aadd(aCampos,{ "EMISSAO","","Emissao"})
	aadd(aCampos,{ "FORNECE","","Fornecedor"})
	aadd(aCampos,{ "TOTAL"  ,"","Total Ped.","@E 999,999,999.99"})
	
	dbSelectArea("TRB")
	dbGotop()
	
Return
