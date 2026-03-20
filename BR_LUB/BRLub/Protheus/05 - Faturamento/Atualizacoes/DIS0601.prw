#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 26/03/2010 - Marcelo Lauschner - Revisão do código
//
//-------------------------------------------------------------------------------------------------

User Function DIS0601

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³DIS060 º Autor ³ Leonardo J Koerich Jr º Data ³  05/11/02   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Liberacao fisica do pedido via leitor otico                º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Sigafat                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Private cPedido   := Space(6)
Private cProduto  := Space(15)
Private nQuant    := 1
Private lFixaMain := .F.
Private oProduto
Private oBrw
Private aEtiqueta := {}
Private lVer      := .F.
Private nDiversos := 0
Private nConv     := 0
Private nConta    := 0
Private cNota     := Space(9)
Private cSerie    := Space(3)
Private cCliente  := Space(6)
Private cLoja     := Space(3)
Private cMsg      := ""
Private cTipo     := Space(1)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Exibe tela solicitando numero do pedido                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
// Executa gravação do Log de Uso da rotina
U_BFCFGM01()


@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Liberacao Fisica do Pedido")
@ 02,10 TO 070,190
@ 10,018 Say "Pedido" picture "@E 999999999"
@ 10,070 Get cPedido Picture "@!" Size 30,10
@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION Close(oDlg1)

ACTIVATE MSDIALOG oDlg1 CENTERED

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se o pedido existe                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

dbSelectArea("SC5")
dbSetOrder(1)
If !dbSeek(xFilial("SC5")+cPedido)
	Alert("Nao existem registros relacionados a este pedido")
	Return
Endif

cCliente := SC5->C5_CLIENTE
cLoja    := SC5->C5_LOJACLI
cTipo    := SC5->C5_TIPO
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria Arquivo temporario                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

aStru:={}

Aadd(aStru,{ "NOTA" , "C", 09, 0 } )
Aadd(aStru,{ "SERIE", "C", 03, 0 } )

If (Select("NOTA") <> 0)
	dbSelectArea("NOTA")
	dbCloseArea("NOTA")
Endif

cArq := CriaTrab(aStru,.t.)
dbUseArea ( .T.,"TOPCONN", cArq, "NOTA", NIL, .F. )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica notas fiscais                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

cQry := ""
cQry += "SELECT DISTINCT C6_NOTA,C6_SERIE "
cQry += "  FROM "+ RetSqlName("SC6")
cQry += " WHERE D_E_L_E_T_ = ' ' "
cQry += "   AND C6_NUM = '" + cPedido + "' "
cQry += "   AND C6_FILIAL = '" + xFilial("SC6") + "' "
cQry += " ORDER BY C6_NOTA,C6_SERIE "

TCQUERY cQry NEW ALIAS "QRY"

While !Eof()
	If !Empty(QRY->C6_NOTA)
		dbSelectArea("NOTA")
		RecLock("NOTA",.T.)
		NOTA->NOTA  := QRY->C6_NOTA
		NOTA->SERIE := QRY->C6_SERIE
		MsUnLock("NOTA")
		nConta++
	Endif
	dbSelectArea("QRY")
	dbSkip()
End
QRY->(DbCloseArea())

dbSelectArea("NOTA")
dbGotop()

If nConta > 1
	aCampos := {}
	aAdd(aCampos,{ "NOTA" , "Nota"})
	aAdd(aCampos,{ "SERIE", "Serie"})
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exibe arquivos a serem liberados                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	@ 001,001 TO 200,300 DIALOG oDlg TITLE "Selecione uma nota fiscal ---> "
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Existe historicos ja gravados                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	@ 005,005 TO 080,150 BROWSE "NOTA" OBJECT oBrw FIELDS aCampos
	
	@ 090,110 BUTTON "Confirma" SIZE 40,10 ACTION Fechar()
	
	ACTIVATE MSDIALOG oDlg CENTERED Valid lFixaMain
	
Endif

cNota     := NOTA->NOTA
cSerie    := NOTA->SERIE
lFixaMain := .F.

NOTA->(DbCloseArea())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria Arquivo temporario                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

aStru:={}

Aadd(aStru,{ "PRODUTO", "C", 15, 0 } )
Aadd(aStru,{ "DESC"   , "C", 50, 0 } )
Aadd(aStru,{ "QUANTID", "N", 12, 2 } )
Aadd(aStru,{ "UM"     , "C", 02, 0 } )

If ( Select ( "TRB" ) <> 0 )
	dbSelectArea ("TRB")
	dbCloseArea("TRB")
Endif

cArq := CriaTrab(aStru,.t.)
dbUseArea ( .T.,"TOPCONN", cArq, "TRB", NIL, .F. )
IndRegua("TRB", cArq,"PRODUTO",,,"Selecionando registros...")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Exibe arquivos a serem liberados                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

@ 01,01 TO 530,755 DIALOG oDlg TITLE "Liberacao Fisica do Pedido ---> " + cPedido

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

oBrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}

@ 239,250 BUTTON "Confirma" SIZE 40,15 ACTION Processa({|| Confirma() },"Processando...")
@ 239,290 BUTTON "Fechar" SIZE 40,15 ACTION Sair()
@ 239,150 BUTTON "Alterar produto" SIZE 60,15 Action  Produto()

ACTIVATE MSDIALOG oDlg CENTERED Valid lFixaMain

TRB->(DbCloseArea())


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



Static Function Produto()
                                                // ANO + HORA + DIA 
Local cSenhaval := Alltrim(Substr(dtos(dDatabase),3,2)+Substr(time(),1,2)+Substr(dtos(dDatabase),7,2))
Local cSei := Space(6)
@ 01,01 TO 130,255 DIALOG oProd TITLE "Informe a senha de supervisor"
@ 010,005 Say "Digite a senha-->>"
@ 010,055 Get cSei PASSWORD
@ 030,060 Button "Continua" size 40,15 action (IIf(cSei==cSenhaval,(U_BIG007(),oProd:End()),oProd:End()))
@ 030,005 Button "Cancela" size 40,15 action oProd:End()

ACTIVATE DIALOG oProd CENTERED

Return



Static Function ValProd()

If !Empty(cProduto)
	
	cQry := ""
	cQry += "SELECT B1_COD,B1_CODBAR,B1_DUN14,B1_DUN14A,B1_MIUD,B1_CONVB,B1_CONVA,B1_DESC "
	cQry += "  FROM " + RetSqlName("SB1")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND B1_MSBLQL != '1' "
	cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry += "   AND B1_COD != '"+cProduto+"' "
	cQry += "   AND ( B1_DUN14 = '" + cProduto + "' OR B1_DUN14A = '" + cProduto + "' OR B1_CODBAR = '" + cProduto + "' ) "
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	dbSelectArea("QRY")
	dbGoTop()
	If Eof()
		cMsg := "Produto sem codigo de barras ou nao Cadastrado: " + cProduto
		Mensagem(cMsg)
		cProduto := Space(15)
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
		cMsg := "Produto nao Pertence a Nota Fiscal: " + QRY->B1_COD
		Mensagem(cMsg)
		cProduto := Space(15)
		QRY->(DbCloseArea())
		CONF->(DbCloseArea())
		Return(.F.)
	Else
		dbSelectArea("TRB")
		dbGoTop()
		If dbSeek(QRY->B1_COD)
			nConv := 0
			If QRY->B1_DUN14 == cProduto
				nConv := QRY->B1_CONVB * nQuant
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
							If aEtiqueta[x][3] == CONF->D2_COD
								lVer := .F.
							Endif
						Next
						If lVer
							AADD(aEtiqueta,{cCliente,cLoja,CONF->D2_COD,((CONF->QTE-Mod(CONF->QTE,nConv))/nConv),CONF->D2_PEDIDO,cNota,cSerie})
						Endif
						cMsg := "Produto excedeu a quantidade liberada. " + QRY->B1_COD
						Mensagem(cMsg)
						cProduto := Space(15)
						QRY->(DbCloseArea())
						CONF->(DbCloseArea())
						Return(.F.)
					Endif
				Endif
			Endif
			
			If TRB->QUANTID + nConv > CONF->QTE
				cMsg := "Produto excedeu a quantidade liberada. " + QRY->B1_COD
				Mensagem(cMsg)
				cProduto := Space(15)
				QRY->(DbCloseArea())
				CONF->(DbCloseArea())
				Return(.F.)
			Endif
			RecLock("TRB",.F.)
			TRB->QUANTID += 1 * nConv
		Else
			nConv := 0
			If QRY->B1_DUN14 == cProduto
				nConv := QRY->B1_CONVB * nQuant
			Elseif QRY->B1_DUN14A == cProduto
				nConv := QRY->B1_CONVA * nQuant
			Elseif QRY->B1_CODBAR == cProduto
				nConv := 1 * nQuant
			Endif
			If nConv > CONF->QTE
				cMsg := "Produto excedeu a quantidade liberada. " + QRY->B1_COD
				Mensagem(cMsg)
				QRY->(DbCloseArea())
				CONF->(DbCloseArea())
				cProduto := Space(15)
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
		TRB->UM		 := CONF->D2_UM
		MsUnLock("TRB")
		
	Endif
	QRY->(DbCloseArea())
	CONF->(DbCloseArea())
	
Endif

dbSelectArea("TRB")
dbGoTop()

cProduto := Space(15)

oBrw:oBrowse:Refresh()
oBrw:oBrowse:bGotFocus := {|| oProduto:SetFocus()}

nQuant := 1

Return

Static Function Confirma()

Local nSaldo := 0

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
	
	DbSelectArea("SB1")
	DbSetOrder(1)
	If Dbseek(xFilial("SB1")+OKC->D2_COD)
		
		If SB1->B1_MIUD == "S"
			DbSelectArea("TRB")
			DbGoTop()
			If DbSeek(OKC->D2_COD)
				If OKC->QTE > TRB->QUANTID
					cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
					Mensagem(cMsg)
					DbSelectArea("TRB")
					DbGoTop()
					cProduto := Space(15)
					OKC->(DbCloseArea())
					Return
				Endif
			Else
				cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
				Mensagem(cMsg)
				cProduto := Space(15)
				DbSelectArea("TRB")
				DbGoTop()
				OKC->(DbCloseArea())
				Return
			Endif
		Elseif SB1->B1_MIUD == "N" .And. ((OKC->QTE / SB1->B1_CONVB) >= 1)
			DbSelectArea("TRB")
			DbGoTop()
			If DbSeek(OKC->D2_COD)
				If Mod(OKC->QTE,SB1->B1_CONVB) <> TRB->QUANTID
					cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->D2_COD
					Mensagem(cMsg)
					cProduto := Space(15)
					DbSelectArea("TRB")
					DbGoTop()       
					OKC->(DbCloseArea())
					Return
				Endif
			Elseif Mod(OKC->QTE,SB1->B1_CONVB) <> 0
				cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
				Mensagem(cMsg)
				cProduto := Space(15)
				DbSelectArea("TRB")
				DbGoTop()               
				OKC->(DbCloseArea())
				Return
			Endif
			lVer := .T.
			For x := 1 To Len(aEtiqueta)
				If aEtiqueta[x][3] == OKC->D2_COD
					If aEtiqueta[x][4] < ((OKC->QTE - Mod(OKC->QTE,SB1->B1_CONVB))/SB1->B1_CONVB)
						cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
						Mensagem(cMsg)
						cProduto := Space(15)
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
				AADD(aEtiqueta,{cCliente,cLoja,OKC->D2_COD,((OKC->QTE-Mod(OKC->QTE,SB1->B1_CONVB))/SB1->B1_CONVB),OKC->D2_PEDIDO,cNota,cSerie})
			Endif
		Elseif SB1->B1_MIUD == "N" .And. ((OKC->QTE / SB1->B1_CONVB) < 1)
			DbSelectArea("TRB")
			DbGoTop()
			If dbSeek(OKC->D2_COD)
				If OKC->QTE <> TRB->QUANTID
					cMsg := "A qtd separada esta divergente da qtd faturada"+ Chr(13) + "Produto: " + OKC->D2_COD
					Mensagem(cMsg)
					cProduto := Space(15)
					DbSelectArea("TRB")
					DbGoTop()               
					OKC->(DbCloseArea())
					Return
				Endif
			Else
				cMsg := "A qtd separada esta menor que a qtd faturada" + Chr(13) + "Produto: " + OKC->D2_COD
				Mensagem(cMsg)
				cProduto := Space(15)
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
@ 10,120 Get nDiversos Picture "@E 99999" Size 30,10
@ 75,150 BUTTON "Avancar--->" SIZE 40,10 ACTION (imprime(),oDlg1:End(),fechar())

ACTIVATE MSDIALOG oDlg1 CENTERED

Return

Static function imprime

If Len(aEtiqueta) <> 0 .Or. !Empty(nDiversos)
  	U_DIS010(aEtiqueta,nDiversos,cPedido,cNota,cSerie,cCliente,cLoja,cTipo)//LABEL
//  Alert(Len(aEtiqueta))
	MsgInfo("Pedido liberado com sucesso","Informacao")
Endif

Return


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Exibe tela com mensagem de nao conformidade                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Static Function Mensagem(cMsg)

@ 200,1 TO 380,395 DIALOG oDlg1 TITLE OemToAnsi("Informacao")
@ 02,10 TO 070,190
@ 10,018 Say cMsg color 128

ACTIVATE MSDIALOG oDlg1 CENTERED

Return
//7891055326213
