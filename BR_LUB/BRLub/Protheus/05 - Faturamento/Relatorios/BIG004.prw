#include "rwmake.ch"
#INCLUDE "TOPCONN.CH"
//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 05/04/2010 - Marcelo Lauschner - Codigo Revisado
//
//-------------------------------------------------------------------------------------------------

User Function BIG004

	If cEmpAnt == "05"
		U_FZFATR01()
	Else
		sfExecRel()
	Endif
	
Return 
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma ³BIG004 ºAutor ³ Marcelo                 º Data ³  01/11/04   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Impressao do relatorio de pedido saida                     º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Sigafat Posição 131 limite coluna                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function sfExecRel()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Local 	cDesc1  := "Este programa tem como objetivo imprimir relatorio "
Local 	cDesc2  := "de acordo com os parametros informados pelo usuario."
Local 	cDesc3  := ""
Local 	cPict   := ""
Local 	titulo  := "Espelho de pedido Separação"
Local 	nLin    := 80
Local 	Cabec1  := ""
Local 	Cabec2  := ""
Local 	imprime := .T.
Local 	aOrd    := {}

Private lEnd        := .F.
Private lAbortPrint := .F.
Private CbTxt       := ""
Private limite      := 80
Private tamanho     := "P"
Private nomeprog    := "BIG004"
Private nTipo       := 18
Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey    := 0
Private cPerg       := "BIG004"
Private cbtxt       := Space(10)
Private cbcont      := 00
Private CONTFL      := 01
Private m_pag       := 01
Private wnrel       := "BIG004"
Private cString     := "SC5"

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

// ValidPerg()

pergunte(cPerg,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia controle para a funcao SETPRINT                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
Endif

VerImp()

nTipo := If(aReturn[4]==1,15,18)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Inicio do Processamento da Nota Fiscal                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return

Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Selecao de Chaves para os arquivos                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DbSelectArea ("SA1")
DbSetOrder(1)               // filial+cod para      CLIENTES
DbSelectArea ("SA2")
DbSetOrder(1)               // filial+cod para      FORNECEDORES
DbSelectArea ("SA4")
DbSetOrder(1)               // filial+cod para      TRANSPORTADORAS
DbSelectArea ("SB1")
DbSetOrder(1)               // filial+cod para      PRODUTOS
DbSelectArea ("SB2")
DbSetOrder(1)               // filial+cod para      PRODUTOS
DbSelectArea ("SC6")
DbSetOrder(1)
DbSelectArea ("SC5")
DbSetOrder(1)
DbSelectArea ("PAB")
DbSetOrder(1)
DbSelectArea ("SC9")
DbSetOrder(1)
DbSelectArea ("SA3")
DbSetOrder(1)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Salva posicoes para movimento da regua de processamento      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DbSelectArea ("SC5")
SetRegua(SC5->(RECCOUNT()))

aPEDIDO   := {}
nPRI      := 0
nCONTNF   := 1
TOTAL     := 0
cRow      := ""


If mv_par04 == 1 // Pedido completo
	
	cQry :=	""
	cQry += "SELECT DISTINCT C9_PEDIDO,C9_NFISCAL,C5_NUM,C5_EMISSAO,C5_DTPROGM,C5_CONDPAG,C5_CLIENTE,C5_LOJACLI,C5_TRANSP,C5_VEND1 "
	cQry += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SC5") + " SC5 "
	cQry += " WHERE SC9.D_E_L_E_T_ = ' ' "
	cQry += "   AND SC5.D_E_L_E_T_ = ' ' "
	cQry += "   AND SC5.C5_VEND2 >= '" +mv_par03+ "' "
	cQry += "   AND SC5.C5_VEND2 <= '" +mv_par05+ "' "
	cQry += "   AND SC5.C5_NUM = SC9.C9_PEDIDO "
	cQry += "   AND SC5.C5_FILIAL = '" + xFilial("SC5") + "' "
	cQry += "   AND SC9.C9_NFISCAL = ' ' "
	cQry += "   AND SC9.C9_PEDIDO >= '" +mv_par01+ "' "
	cQry += "   AND SC9.C9_PEDIDO <= '"+mv_par02+"' "
	cQry += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") + "' "
	
	
	TCQUERY cQry NEW ALIAS "QRC"
	
	dbSelectArea("QRC")
	dbGoTop()
	While !Eof()
		
		IncRegua()
		@ pRow() ,015 psay "ESPELHO DE PEDIDO LIBERADO PARA SEPARAÇÃO BIG FORTA"
		DbSelectArea ("SA1")
		dbSetOrder(1)
		If DbSeek(xFilial("SA1")+QRC->C5_CLIENTE+QRC->C5_LOJACLI)
			@ prow()+1,001 psay "Pedido:"
			dbSelectArea ("SC5")
			dbSeek(xFilial("SC5")+QRC->C5_NUM)
			dbSelectArea("SE4")
			dbSeek(xFilial("SE4")+QRC->C5_CONDPAG)
			dbSelectArea("PAB")
			dbSeek(xFilial("PAB")+SA1->A1_CEP)
			DbSelectArea ("SA3")
			DbSeek(xFilial("SA3")+QRC->C5_VEND1)			
			
			nNf := 0
			
			dbSelectArea("SC9")
			dbSeek(xFilial("SC9")+QRC->C5_NUM)
			While !Eof() .and. SC9->C9_PEDIDO == QRC->C5_NUM .and. SC9->C9_ITEM >= "01"
				IF SC9->C9_NFISCAL <> " "
					nNf := nNf + 1
				else
					nNf := nNf + 0
				Endif
				
				dbSelectArea("SC9")
				dbSkip()
			Enddo
			
			
			cCliente := QRC->C5_CLIENTE
			cLoja    := QRC->C5_LOJACLI
			cCEP		:=" "
			cRota		:=" "
			nDiaAtu  := 0
			nDiaEnt  := 0
			dData    := dDataBase
			aRota    := {}
			aDias    := {1,2,3,4,5,6,7}
			
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica da de entrega                                              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			
			dbSelectArea("SA1")
			dbSetOrder(1)
			If dbSeek(xFilial("SA1")+cCliente+cLoja)
				cCEP := SA1->A1_CEP
				
				IF SA1->A1_ROTA <> " "
					cRota := SA1->A1_ROTA
				endif
				
				dbSelectArea("PAB")
				dbSetOrder(1)
				If dbSeek(xFilial("PAB")+cCEP)
					cRota := PAB->PAB_ROTA
					For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
						AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
					Next
				Endif
				
				IF SA1->A1_ROTA <> " "
					For x := 1 To Len(AllTrim(SA1->A1_ROTA)) Step 1
						AADD(aRota,{SubStr(SA1->A1_ROTA,x,1)})
					Next
				Endif
				//Endif
			Endif
			
			nDia := Dow(dDatabase)
			If Len(aRota) > 0
				While .T.
					If nDia > 7
						nDia := 1
					Endif
					nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
					If !Empty(nPos)
						nDiaEnt := Val(aRota[nPos][1])
						If nDiaEnt == Dow(dDatabase)
							dData := dDatabase
						Elseif (nDiaEnt - Dow(dDatabase)) > 0
							dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
						Else
							dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
						Endif
						Exit
					Endif
					nDia++
				End
			Endif
			
			
			@ prow()  ,008 psay SC5->C5_NUM
			@ prow()  ,015 psay "Emissao"
			@ PROW()  ,023 PSAY SC5->C5_EMISSAO
			@ PROW()  ,033 PSAY "Programado:"
			@ PROW()  ,045 PSAY SC5->C5_DTPROGM
			@ prow()  ,054 psay "Prox fatu:"
			@ pRow()  ,065 PSAY dData
			@ prow()  ,075 psay "Cond:"
			@ prow()  ,081 psay SE4->E4_DESCRI
			IF  nNf >= 1
				@ prow()  ,100 psay "SALDO PEDIDO"
			ELSE
				@ PROW()  ,100 PSAY "PEDIDO NOVO"
			Endif
			dbSelectArea ("SA4") //Cad. de Transportadoras
			dbSeek(xFilial("SA4")+QRC->C5_TRANSP)
			@ prow()+1, 001 psay "Transp:"
			@ pRow()  , 009 PSAY substr(SA4->A4_NOME,1,30)+" - "+SA4->A4_COD
			@ prow()  , 050 PSAY SA4->A4_NREDUZ
			@ prow()  ,074 psay PAB->PAB_ROTA
			@ prow()  ,080 psay Dow(dDatabase)
			@ prow()  ,083 psay SA1->A1_DDD + " " + SA1->A1_TEL + "   " + SA1->A1_CONTATO
			
			
			
			@ pRow()+1, 001 PSAY AllTrim(SA1->A1_NOME) + " (" + AllTrim(SA1->A1_COD) + ")"
			If LEN(ALLTRIM(SA1->A1_CGC)) == 11
				@ pRow(), 055 PSAY transform(SA1->A1_CGC, "@R 999.999.999-99")
			Endif
			If LEN(ALLTRIM(SA1->A1_CGC)) == 14
				@ pRow(), 055 PSAY transform(SA1->A1_CGC, "@R 99.999.999/9999-99")
			Endif
			@ pRow()  , 080 PSAY SA1->A1_INSCR
			@ pRow()+1, 001 PSAY SUBSTR(SA1->A1_END ,1,30)
			@ pRow()  , 033 PSAY SUBSTR(SA1->A1_BAIRRO ,1,20)
			@ pRow()  , 056 PSAY TRANSFORM(SA1->A1_CEP,"@R 99999-999")
			@ pRow()  , 066 PSAY SUBSTR(SA1->A1_MUN ,1,25)
			@ pRow()  , 092 PSAY SA1->A1_EST
			@ prow()  , 095 PSAY SA3->A3_NREDUZ
		Endif
		@ PROW()+1, 001 PSAY "Item Codigo"
		@ prow()  , 023 psay "Descricao"
		@ prow()  , 064 psay "UM"
		@ prow()  , 067 psay "Est"
		@ prow()  , 073 psay "Lib"
		@ prow()  , 078 psay "STS"
		@ prow()  , 082 psay "P.Tab"
		@ prow()  , 091 psay "P.Ven"
		@ prow()  , 100 psay "Desc"
		@ prow()  , 109 psay "Total"
		nCONTNF   :=1
		nItens    := 0
		nTotItens := 10
		nCred := 0.00
		nEst  := 0.00
		nLib  := 0.00
		nTotal:= 0.00
		
		cQry := ""
		cQry += "SELECT DISTINCT C9_ITEM,C9_SEQUEN,C9_PRODUTO,C9_FLGENVI,C9_QTDLIB,C9_PRCVEN,C9_BLEST,C9_BLCRED,C9_NFISCAL,C9_PEDIDO "
		cQry += "  FROM " + RetSqlName("SC9")
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND C9_PEDIDO = '" +QRC->C9_PEDIDO + "' "
		cQry += "   AND C9_NFISCAL = ' ' "
		cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
		
		TCQUERY cQry NEW ALIAS "QRY"
		
		dbSelectArea("QRY")
		dbGoTop()
		While !Eof()
			
			DbSelectArea ("SB1") //Descricao do produto
			DbSeek(xFilial("SB1")+QRY->C9_PRODUTO)   // PRODUTO
			DbSelectArea ("SB2") //Descricao do produto
			DbSeek(xFilial("SB2")+QRY->C9_PRODUTO + "01")   // ESTOQUE
			DbSelectArea ("SC6") //Descricao do produto
			DbSeek(xFilial("SC6")+QRY->C9_PEDIDO+QRY->C9_ITEM)   // ESTOQUE
			
			@ prow()+1,001 psay SUBSTR(QRY->C9_ITEM,1,2)
			@ prow()  ,004 psay SUBSTR(QRY->C9_SEQUEN,1,2)
			@ prow()  ,007 PSAY SUBSTR(QRY->C9_PRODUTO,1,15)
			@ prow()  ,023 PSAY SUBSTR(SB1->B1_DESC,1,40)
			@ pRow()  ,064 PSAY SUBSTR(SB1->B1_UM,1,2)
			@ prow()  ,067 PSAY SB2->B2_QATU
			@ pRow()  ,073 PSAY QRY->C9_QTDLIB
			IF QRY->C9_NFISCAL <> " "
				@ PROW()  ,078 PSAY "FATURADO"
			ELSE
				IF  QRY->C9_BLCRED <> " "
					@ PROW()  ,078 PSAY "CRD"
					nCred := nCred + QRY->C9_QTDLIB * QRY->C9_PRCVEN
				ELSE
					IF QRY->C9_BLEST <> " "
						@ PROW()  ,078 PSAY "BLE "
						nEst := nEst + QRY->C9_QTDLIB * QRY->C9_PRCVEN
					Else
						@ prow()  ,078 psay "OK"
						nLib := nLib + QRY->C9_QTDLIB * QRY->C9_PRCVEN
					Endif
				Endif
			ENDIF
			@ PROW()  ,082 PSAY TRANSFORM(SC6->C6_PRUNIT , "@E 9,999.99")
			@ prow()  ,091 psay transform(QRY->C9_PRCVEN , "@E 9,999.99")
			@ prow()  ,100 psay transform(( SC6->C6_PRUNIT - QRY->C9_PRCVEN )/ SC6->C6_PRUNIT *100 , "@E 999.99")
			@ pRow()  ,107 PSAY transform(QRY->C9_QTDLIB * QRY->C9_PRCVEN , "@E 9,999.99")
			@ prow()  ,117 psay QRY->C9_FLGENVI
			nItens := nItens+1
			nTotal := nTotal + QRY->C9_QTDLIB * QRY->C9_PRCVEN
			dbSelectArea("QRY")
			dbSkip()
		Enddo
		QRY->(DbCloseArea())
		
		//@ PROW()+(nTotItens - nItens)+1,000 psay " "
		@ prow() +1, 000 psay ""
		@ prow()   , 001 psay "Bloqueado Crédito:"
		@ prow()   , 020 psay Transform(nCred , "@E 999,999.99")
		@ prow()   , 035 psay "Mens interna:"
		@ prow()   , 050 psay SC5->C5_MSGINT
		@ PROW() +1, 001 PSAY "Estoque:"
		@ prow()   , 020 psay transform(nEst , "@E 999,999.99")
		@ prow()   , 035 psay "Mens Nota:   "
		@ prow()   , 050 psay SC5->C5_MENNOTA
		@ prow() +1, 001 psay "Liberado:"
		@ prow()   , 020 psay transform(nLib , "@E 999,999.99")
		@ prow()   , 035 psay "Obs cliente"
		@ prow()   , 050 psay SA1->A1_OBSCLI
		@ prow() +1, 001 psay "Total pendente:"
		@ prow()   , 020 psay transform(nTotal , "@E 999,999.99")
		@ PROW()   , 035 psay "do pedido:"
		@ pRow()   , 050 PSAY QRC->C5_NUM
		@ prow()+2, 000 psay ""
		
		dbSelectArea("QRC")
		dbSkip()
	Enddo
	QRC->(DbCloseArea())
Else
	
	
	cQry :=	""
	cQry += "SELECT DISTINCT C5_NUM,C5_EMISSAO,C5_DTPROGM,C5_CONDPAG,C5_CLIENTE,C5_LOJACLI,C5_VEND1,C5_TRANSP"
	cQry += "  FROM " + RetSqlName("SC5")
	cQry += " WHERE D_E_L_E_T_ =  ' ' "
	cQry += "   AND C5_NUM >= '" +mv_par01+ "' "
	cQry += "   AND C5_NUM <= '"+mv_par02+"' "
	cQry += "   AND C5_VEND2 >= '" +mv_par03+ "' "
	cQry += "   AND C5_VEND2 <= '" +mv_par05+ "' "
	cQry += "   AND C5_FILIAL = '" + xFilial("SC5") + "' "
	
	TCQUERY cQry NEW ALIAS "QRC"
	
	dbSelectArea("QRC")
	dbGoTop()
	While !Eof()
		IncRegua()
		@ pRow() ,015 psay "ESPELHO DE PEDIDO LIBERADO PARA SEPARAÇÃO BIG FORTA"
		DbSelectArea ("SA1")
		dbSetOrder(1)
		If DbSeek(xFilial("SA1")+QRC->C5_CLIENTE+QRC->C5_LOJACLI)
			@ prow()+1,001 psay "Pedido:"
			dbSelectArea ("SC5")
			dbSeek(xFilial("SC5")+QRC->C5_NUM)
			dbSelectArea("SE4")
			dbSeek(xFilial("SE4")+QRC->C5_CONDPAG)
			dbSelectArea("PAB")
			dbSeek(xFilial("PAB")+SA1->A1_CEP)
			DbSelectArea ("SA3")
			DbSeek(xFilial("SA3")+QRC->C5_VEND1)
			
			@ prow()  ,008 psay SC5->C5_NUM
			@ prow()  ,015 psay "Emissao"
			@ PROW()  ,023 PSAY SC5->C5_EMISSAO
			@ PROW()  ,033 PSAY "Programado:"
			@ PROW()  ,045 PSAY SC5->C5_DTPROGM
			@ prow()  ,054 psay "Impressao:"
			@ pRow()  ,065 PSAY Date()
			@ prow()  ,075 psay "Cond:"
			@ prow()  ,081 psay SE4->E4_DESCRI
			
			
			dbSelectArea ("SA4") //Cad. de Transportadoras
			dbSeek(xFilial("SA4")+QRC->C5_TRANSP)
			@ prow()+1, 001 psay "Transp:"
			@ pRow()  , 009 PSAY substr(SA4->A4_NOME,1,30)+" - "+SA4->A4_COD
			@ prow()  , 050 PSAY SA4->A4_NREDUZ
			@ prow()  ,074 psay PAB->PAB_ROTA
			@ prow()  ,080 psay Dow(dDatabase)
			@ prow()  ,083 psay SA1->A1_DDD + " " + SA1->A1_TEL + "   " + SA1->A1_CONTATO
			
			
			
			@ pRow()+1, 001 PSAY AllTrim(SA1->A1_NOME) + " (" + AllTrim(SA1->A1_COD) + ")"
			If LEN(ALLTRIM(SA1->A1_CGC)) == 11
				@ pRow(), 055 PSAY transform(SA1->A1_CGC, "@R 999.999.999-99")
			Endif
			If LEN(ALLTRIM(SA1->A1_CGC)) == 14
				@ pRow(), 055 PSAY transform(SA1->A1_CGC, "@R 99.999.999/9999-99")
			Endif
			@ pRow()  , 080 PSAY SA1->A1_INSCR
			@ pRow()+1, 001 PSAY SUBSTR(SA1->A1_END ,1,30)
			@ pRow()  , 033 PSAY SUBSTR(SA1->A1_BAIRRO ,1,20)
			@ pRow()  , 056 PSAY TRANSFORM(SA1->A1_CEP,"@R 99999-999")
			@ pRow()  , 066 PSAY SUBSTR(SA1->A1_MUN ,1,25)
			@ pRow()  , 092 PSAY SA1->A1_EST
			@ prow()  , 095 PSAY SA3->A3_NREDUZ
		Endif
		
		@ PROW()+1, 001 PSAY "Item Codigo"
		@ prow()  , 020 psay "Descricao"
		@ prow()  , 064 psay "UM"
		@ prow()  , 067 psay "Est"
		@ prow()  , 073 psay "Lib"
		@ prow()  , 078 psay "STS"
		@ prow()  , 082 psay "P.Tab"
		@ prow()  , 091 psay "P.Ven"
		@ prow()  , 100 psay "Desc"
		@ prow()  , 109 psay "Total"
		nCONTNF   :=1
		nItens    := 0
		nTotItens := 10
		nCred := 0.00
		nEst  := 0.00
		nLib  := 0.00
		nTotal:= 0.00
		
		cQry := ""
		cQry += "SELECT DISTINCT C6_ITEM,C6_NUM,C6_PRODUTO,C6_PRCVEN,C6_PRUNIT,C6_QTDVEN "
		cQry += "  FROM " + RetSqlName("SC6")
		cQry += " WHERE D_E_L_E_T_ = ' '  "
		cQry += "   AND C6_NUM = '" +QRC->C5_NUM + "' "
		cQry += "   AND C6_BLQ <> 'R'"
		cQry += "   AND C6_FILIAL = '" + xFilial("SC6") + "' "
		
		TCQUERY cQry NEW ALIAS "QRY"
		
		cQry := ""
		cQry += "SELECT DISTINCT C9_ITEM,C9_SEQUEN,C9_PEDIDO,C9_BLEST,C9_BLCRED,C9_NFISCAL,C9_PRODUTO,C9_PRCVEN,C9_QTDLIB "
		cQry += "  FROM " + RetSqlName("SC9")
		cQry += " WHERE D_E_L_E_T_ = ' '  "
		cQry += "   AND C9_PEDIDO = '" +QRC->C5_NUM + "'"
		cQry += "   AND C9_FILIAL = '" + xFilial("SC9") + "' "
		
		TCQUERY cQry NEW ALIAS "QRD"
		
		dbSelectArea("QRY")
		dbGoTop()
		dbSelectArea("QRD")
		dbGoTop()
		
		IF QRD->C9_PEDIDO # QRY->C6_NUM
			
			dbSelectArea("QRY")
			dbGoTop()
			While !Eof()
				
				DbSelectArea ("SB1") //Descricao do produto
				DbSeek(xFilial("SB1")+QRY->C6_PRODUTO)   // PRODUTO
				DbSelectArea ("SB2") //Descricao do produto
				DbSeek(xFilial("SB2")+QRY->C6_PRODUTO + "01")   // ESTOQUE
				DbSelectArea ("SC9")
				DbSeek(xFilial("SC9")+QRY->C6_NUM+QRY->C6_ITEM)   // ESTOQUE
				
				@ prow()+1,001 psay SUBSTR(QRY->C6_ITEM,1,2)
				@ prow()  ,004 PSAY SUBSTR(QRY->C6_PRODUTO,1,15)
				@ prow()  ,020 PSAY SUBSTR(SB1->B1_DESC,1,40)
				@ pRow()  ,064 PSAY SUBSTR(SB1->B1_UM,1,2)
				@ prow()  ,067 PSAY SB2->B2_QATU
				@ pRow()  ,073 PSAY QRY->C6_QTDVEN
				@ PROW()  ,078 PSAY "A LIB"
				@ PROW()  ,082 PSAY TRANSFORM(QRY->C6_PRUNIT , "@E 9,999.99")
				@ prow()  ,091 psay transform(QRY->C6_PRCVEN , "@E 9,999.99")
				@ prow()  ,100 psay transform(( QRY->C6_PRUNIT - QRY->C6_PRCVEN )/ QRY->C6_PRUNIT *100 , "@E 999.99")
				@ pRow()  ,107 PSAY transform(QRY->C6_QTDVEN * QRY->C6_PRCVEN , "@E 9,999.99")
				nItens := nItens+1
				nTotal := nTotal + QRY->C6_QTDVEN * QRY->C6_PRCVEN
				
				dbSelectArea("QRY")
				dbSkip()
			Enddo
			
		ELSE
			dbSelectArea("QRD")
			dbGoTop()
			While !Eof()
				DbSelectArea ("SB1") //Descricao do produto
				DbSeek(xFilial("SB1")+QRD->C9_PRODUTO)   // PRODUTO
				DbSelectArea ("SB2")
				DbSeek(xFilial("SB2")+QRD->C9_PRODUTO + "01")
				DbSelectArea ("SC6")
				DbSeek(xFilial("SC6")+QRD->C9_PEDIDO+QRD->C9_ITEM)
				
				@ prow()+1,000 psay SUBSTR(QRD->C9_ITEM,1,2)
				@ prow()  ,002 psay substr(QRD->C9_SEQUEN,2,1)
				@ prow()  ,004 PSAY SUBSTR(QRD->C9_PRODUTO,1,15)
				@ prow()  ,020 PSAY SUBSTR(SB1->B1_DESC,1,40)
				@ pRow()  ,064 PSAY SUBSTR(SB1->B1_UM,1,2)
				@ prow()  ,067 PSAY SB2->B2_QATU
				@ pRow()  ,073 PSAY QRD->C9_QTDLIB
				IF QRD->C9_NFISCAL <> " "
					@ PROW()  ,078 PSAY "FAT"
				ELSE
					IF  QRD->C9_BLCRED <> " "
						@ PROW()  ,078 PSAY "CRD"
						nCred := nCred + QRD->C9_QTDLIB * QRD->C9_PRCVEN
					ELSE
						IF QRD->C9_BLEST <> " "
							@ PROW()  ,078 PSAY "BLE "
							nEst := nEst + QRD->C9_QTDLIB * QRD->C9_PRCVEN
						Else
							@ prow()  ,078 psay "OK"
							nLib := nLib + QRD->C9_QTDLIB * QRD->C9_PRCVEN
						Endif
					Endif
				ENDIF
				
				@ PROW()  ,082 PSAY TRANSFORM(SC6->C6_PRUNIT , "@E 9,999.99")
				@ prow()  ,091 psay transform(QRD->C9_PRCVEN , "@E 9,999.99")
				@ prow()  ,100 psay transform(( SC6->C6_PRUNIT - QRD->C9_PRCVEN )/ SC6->C6_PRUNIT *100 , "@E 999.99")
				@ pRow()  ,107 PSAY transform(QRD->C9_QTDLIB * QRD->C9_PRCVEN , "@E 9,999.99")
				@ PROW()  ,116 PSAY QRD->C9_NFISCAL
				nItens := nItens+1
				nTotal := nTotal + QRD->C9_QTDLIB * QRD->C9_PRCVEN
				
				dbSelectArea("QRD")
				dbSkip()
			EndDO
		ENDIF
		QRD->(DbCloseArea())
		QRY->(DbCloseArea())
		//@ PROW()+(nTotItens - nItens)+1,000 psay " "
		@ prow() +1, 000 psay ""
		@ prow()   , 001 psay "Bloqueado Crédito:"
		@ prow()   , 020 psay Transform(nCred , "@E 999,999.99")
		@ prow()   , 035 psay "Mens interna:"
		@ prow()   , 050 psay SC5->C5_MSGINT
		@ PROW() +1, 001 PSAY "Estoque:"
		@ prow()   , 020 psay transform(nEst , "@E 999,999.99")
		@ prow()   , 035 psay "Mens Nota:   "
		@ prow()   , 050 psay SC5->C5_MENNOTA
		@ prow() +1, 001 psay "Liberado:"
		@ prow()   , 020 psay transform(nLib , "@E 999,999.99")
		@ prow()   , 035 psay "Obs cliente"
		@ prow()   , 050 psay SA1->A1_OBSCLI
		@ prow() +1, 001 psay "Total pendente:"
		@ prow()   , 020 psay transform(nTotal , "@E 999,999.99")
		@ PROW()   , 035 psay "do pedido:"
		@ pRow()   , 050 PSAY QRC->C5_NUM
		@ prow()+2, 000 psay ""
		@ prow()+2, 000 psay ""
		dbSelectArea("QRC")
		dbSkip()
	Enddo
	QRC->(DbCloseArea())
Endif


SetPgEject(.F.)
If ( aReturn[5] == 1 )
	Set Printer TO
	DbcommitAll()
	OurSpool(wnrel)
EndIf
MS_FLUSH()
Return



Static Function VerImp()

SetPrc(0,0)
@ pRow(), 000 PSAY chr(27)+chr(48)  //Impressao 1/8

If aReturn[5]==2
	nOpc       := 1
	DbCommitAll()
	While .T.
		If MsgYesNo("Fomulario esta posicionado ? ")
			nOpc := 1
		Elseif MsgYesNo("Tenta Novamente ? ")
			nOpc := 2
		Else
			nOpc := 3
		Endif
		
		Do Case
			Case nOpc==1
				lContinua:=.T.
				Exit
			Case nOpc==2
				Loop
			Case nOpc==3
				lContinua:=.F.
				Return
		EndCase
	EndDo
Endif
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFun‡„o    ³VALIDPERG º Autor ³ AP5 IDE            º Data ³  16/04/02   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescri‡„o ³ Verifica a existencia das perguntas criando-as caso seja   º±±
±±º          ³ necessario (caso nao existam).                             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Programa principal                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

// Static Function ValidPerg

// Local _sAlias := Alias()
// Local aRegs := {}
// Local i,j

// dbSelectArea("SX1")
// dbSetOrder(1)
// cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))

// AADD(aRegs,{cPerg,"01","Do pedido ?","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// AADD(aRegs,{cPerg,"02","Até pedido?","","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// AADD(aRegs,{cPerg,"03","Código madrinha?","","","mv_ch3","C",06,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
// AADD(aRegs,{cPerg,"04","Tipo pedido    ?","","","mv_ch4","N",01,0,0,"C","","mv_par04","Liberado para Faturar","","","","","Digitado para consulta","","","","","","","","","","","","","","","","","","","","","","",""})
// AADD(aRegs,{cPerg,"05","Código madrinha final?","","","mv_ch5","C",06,0,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})

// For i:=1 to Len(aRegs)
// 	If !dbSeek(cPerg+aRegs[i,2])
// 		RecLock("SX1",.T.)
// 		For j:=1 to FCount()
// 			If j <= Len(aRegs[i])
// 				FieldPut(j,aRegs[i,j])
// 			Endif
// 		Next
// 		MsUnlock("SX1")
// 	Endif
// Next

// dbSelectArea(_sAlias)

// Return 
