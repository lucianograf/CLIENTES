#include "rwmake.ch"
#INCLUDE "TOPCONN.CH"
//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 05/04/2010 - Marcelo Lauschner - Codigo revisado
//
//-------------------------------------------------------------------------------------------------

User Function BIG006

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma ³BIG006 ºAutor ³ Marcelo                 º Data ³  12/11/04   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Impressao do relatorio de pedido deposito                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Sigafat Posição 80 limite coluna                          º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

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
Private nomeprog    := "BIG006"
Private nTipo       := 18
Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey    := 0
Private cPerg       := "BIG006"
Private cbtxt       := Space(10)
Private cbcont      := 00
Private CONTFL      := 01
Private m_pag       := 01
Private wnrel       := "BIG006"
Private cString     := "SC5"

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

ValidPerg()

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
cImpEnv   := Space(1)
If mv_par03 == 1
	cImpEnv := "'S'"
Else
	cImpEnv := "'M'"
Endif


cQry :=	""
cQry += "SELECT DISTINCT * "
cQry += "  FROM " + RetSqlName("SC5") + " "
cQry += " WHERE D_E_L_E_T_ = ' ' "
cQry += "   AND C5_NUM >= '" +mv_par01+ "'"
cQry += "   AND C5_NUM <= '" +mv_par02+ "'"
cQry += "   AND C5_BLPED IN(" +cImpEnv+ ") "
cQry += "   AND C5_TIPO = 'N' "
cQry += "   AND C5_FILIAL = '" + xFilial("SC5") + "' "
cQry += " ORDER BY C5_NUM "

TCQUERY cQry NEW ALIAS "QRC"

dbSelectArea("QRC")
dbGoTop()
While !Eof()
	
	IncRegua()
	@ pRow() ,015 psay "ESPELHO DE PEDIDO LIBERADO PARA SEPARACAO BIG FORTA"
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
		
		IF  nNf == 0
			if (SM0->M0_CODIGO == '02' .AND. SM0->M0_CODFIL == '04') .OR. (SM0->M0_CODIGO == '03' .AND. SM0->M0_CODFIL == '01')
		   		U_ENVILG(SM0->M0_CODIGO,SM0->M0_CODFIL, QRC->C5_NUM)                                      
			endif
		Endif
		
		
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
		
		
		@ prow()  ,008 psay "## " +SC5->C5_NUM + " ##"
		@ prow()+1,015 psay "Emissao"
		@ PROW()  ,023 PSAY SC5->C5_EMISSAO
		@ PROW()  ,033 PSAY "Programado:"
		@ PROW()  ,045 PSAY SC5->C5_DTPROGM
		@ prow()  ,054 psay "Prox fatu:"
		@ pRow()  ,065 PSAY dData
		
		IF  nNf >= 1
			@ prow()  ,075 psay "SALDO"
		ELSE
			@ PROW()  ,075 PSAY "NOVO"
		Endif
		dbSelectArea ("SA4") //Cad. de Transportadoras
		dbSeek(xFilial("SA4")+QRC->C5_TRANSP)
		@ prow()+1, 001 psay "Transp:"
		@ pRow()  , 009 PSAY substr(SA4->A4_NOME,1,30)+" - "+SA4->A4_COD
		@ prow()  , 050 PSAY SA4->A4_NREDUZ
		@ prow()  ,065 psay PAB->PAB_ROTA
		@ prow()  ,080 psay Dow(dDatabase)
		
		@ pRow()+1, 001 PSAY AllTrim(SA1->A1_NOME) + " (" + AllTrim(SA1->A1_COD) + ")"
		@ PROW()  , 050 PSAY "Vendedor"
		@ prow()  , 060 PSAY SA3->A3_NREDUZ
		@ pRow()+1, 001 PSAY SUBSTR(SA1->A1_END ,1,30)
		@ pRow()  , 033 PSAY SUBSTR(SA1->A1_BAIRRO ,1,15)
		@ pRow()  , 050 PSAY TRANSFORM(SA1->A1_CEP,"@R 99999-999")
		@ pRow()  , 060 PSAY SUBSTR(SA1->A1_MUN ,1,20)
		@ pRow()  , 081 PSAY SA1->A1_EST
		@ PROW()+2, 001 PSAY "End Item Codigo"
		@ prow()  , 025 psay "Descricao"
		@ prow()  , 061 psay "UM"
		@ prow()  , 064 psay "Est"
		@ prow()  , 070 psay "Lib"
		@ prow()  , 076 psay "STS"
		@ prow()  , 080 psay "M"
		nCONTNF   :=1
		nItens    := 0
		nTotItens := 62
		nCred := 0.00
		nEst  := 0.00
		nLib  := 0.00
		nTotal:= 0.00
		
		cQry := ""
		cQry += "SELECT DISTINCT B1_COD,B1_DESC,B1_MIUD,B1_CONVB,B1_UM,B1_LOCAL,"
		cQry += "       C9_ITEM,C9_SEQUEN,C9_PRODUTO,C9_FLGENVI,C9_QTDLIB,C9_PRCVEN,C9_BLEST,C9_BLCRED,C9_NFISCAL,C9_PEDIDO "
		cQry += "  FROM " + RetSqlName("SC9") + " SC9, " + RetSqlName("SB1") + " SB1 "
		cQry += " WHERE SC9.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_COD = SC9.C9_PRODUTO "
		cQry += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQry += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
		cQry += "   AND SC9.C9_NFISCAL = ' ' "
		cQry += "   AND SC9.C9_BLEST = ' '  "
		cQry += "   AND SC9.C9_BLCRED = ' ' "
		cQry += "   AND SC9.C9_PEDIDO = '" +QRC->C5_NUM + "' "
		cQry += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") + "' "
		cQry += "ORDER BY B1_LOCAL "
		
		TCQUERY cQry NEW ALIAS "QRY"
		
		dbSelectArea("QRY")
		dbGoTop()
		While !Eof()
			
			DbSelectArea ("SB2") //Descricao do produto
			DbSeek(xFilial("SB2")+QRY->C9_PRODUTO + "01")   // ESTOQUE
			DbSelectArea ("SC6") //Descricao do produto
			DbSeek(xFilial("SC6")+QRY->C9_PEDIDO+QRY->C9_ITEM)   // ESTOQUE
			
			@ prow()+1,000 psay SUBSTR(QRY->B1_LOCAL,1,6)
			@ prow()  ,008 psay SUBSTR(QRY->C9_ITEM,1,2)
			@ prow()  ,011 PSAY SUBSTR(QRY->C9_PRODUTO,1,14)
			@ prow()  ,025 PSAY SUBSTR(QRY->B1_DESC,1,35)
			@ pRow()  ,061 PSAY SUBSTR(QRY->B1_UM,1,2)
			@ prow()  ,064 PSAY SB2->B2_QATU
			@ pRow()  ,070 PSAY QRY->C9_QTDLIB
			IF QRY->C9_NFISCAL <> " "
				@ PROW()  ,076 PSAY "FATURADO"
			ELSE
				IF  QRY->C9_BLCRED <> " "
					@ PROW()  ,076 PSAY "CRD"
					nCred := nCred + QRY->C9_QTDLIB * QRY->C9_PRCVEN
				ELSE
					IF QRY->C9_BLEST <> " "
						@ PROW()  ,076 PSAY "BLE "
						nEst := nEst + QRY->C9_QTDLIB * QRY->C9_PRCVEN
					Else
						@ prow()  ,076 psay "OK"
						nLib := nLib + QRY->C9_QTDLIB * QRY->C9_PRCVEN
					Endif
				Endif
			ENDIF
			
			If QRY->B1_MIUD <> "N"
				@ PROW()  , 080 PSAY "XX"
			Else
				If (QRY->C9_QTDLIB/QRY->B1_CONVB)- ROUND((QRY->C9_QTDLIB/QRY->B1_CONVB),2)  <> 0
					@ PROW() , 080 PSAY "X"
				ELSE
					@ PROW() , 080 PSAY ""
				ENDIF
			ENDIF
			
			
			@ prow() +1, 000 psay "----------------------------------------------------------------------------------"
			nItens := nItens+2
			nTotal := nTotal + QRY->C9_QTDLIB * QRY->C9_PRCVEN
			
			If nItens >62
				DbSelectArea ("QRY")
				nReg:=recno()
				nCONTNF:=nCONTNF+1
				Continua()
				nItens :=0
				nItens := nItens+1
				@ prow() +1,002 psay "Continuacao.."
				@ prow() +1,012 psay " "
			Endif
			
			dbSelectArea("QRY")
			dbSkip()
		Enddo
		QRY->(DbCloseArea())
		
		@ prow() +1, 000 psay ""
		@ prow()   , 001 psay "M.int:"
		@ prow()   , 009 psay substr(SC5->C5_MSGINT,1,71)
		@ prow() +1, 001 psay "M.Nota:"
		@ prow()   , 009 psay substr(SC5->C5_MENNOTA,1,71)
		@ prow() +1, 001 psay "Obs cliente"
		@ prow()   , 013 psay substr(SA1->A1_OBSCLI,1,60)
		@ prow() +1, 001 psay "Total"
		@ prow()   , 020 psay transform(nTotal , "@E 999,999.99")
		@ PROW()   , 035 psay "do pedido:"
		@ pRow()   , 050 PSAY QRC->C5_NUM
		@ prow() +2, 001 psay "Box"
		@ prow()   , 015 psay "Sep"
		@ prow()   , 030 psay "Mesa"
		@ prow()   , 035 psay "Encx"
		@ prow()   , 060 psay "Conf"
		@ prow()+12, 000 psay ""
		@ PROW()+(nTotItens - nItens)+1,000 psay " "
		
		If mv_par03 == 1
			
			RecLock("SC5",.F.)
			SC5->C5_BLPED := "M"
			MsUnlock("SC5")
			// Grava Log da impressão do pedido
			U_GMCFGM01("IM",SC5->C5_NUM,,FunName())
			
		Endif
		
		dbSelectArea("QRC")
		dbSkip()
	End
	
End
QRC->(DbCloseArea())

SetPgEject(.F.)
If ( aReturn[5] == 1 )
	Set Printer TO
	DbcommitAll()
	OurSpool(wnrel)
EndIf
MS_FLUSH()
Return

Static Function Continua()

@ prow()+1,012 psay "Continua..."
@ prow()+18, 000 psay " "

DbSelectArea ("SC9")
DbGoTo(nREG)
@ PROW()+1, 000 PSAY " "
@ prow()+1,001 psay "Pedido:"
@ prow()  ,008 psay SC5->C5_NUM
@ prow()  ,015 psay "Emissao"
@ PROW()  ,023 PSAY SC5->C5_EMISSAO
@ PROW()  ,033 PSAY "Programado:"
@ PROW()  ,045 PSAY SC5->C5_DTPROGM
@ prow()  ,054 psay "Impressao:"
@ pRow()  ,065 PSAY Date()
@ PROW()+1, 001 PSAY "End Item Codigo"
@ prow()  , 025 psay "Descricao"
@ prow()  , 061 psay "UM"
@ prow()  , 064 psay "Est"
@ prow()  , 070 psay "Lib"
@ prow()  , 076 psay "STS"
@ PROW()+4, 000 PSAY " "


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

Static Function ValidPerg

Local _sAlias := Alias()
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)
// cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))
cPerg :=  PADR(cPerg,Len("X1_GRUPO"))

AADD(aRegs,{cPerg,"01","Do pedido ","","","mv_ch1","C",06,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"02","Até pedido ","","","mv_ch2","C",06,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"03","Enviado ou Impresso? ","","","mv_ch3","N",01,0,0,"C","","mv_par03","Enviado","","","","","Impresso","","","","","","","","","","","","","","","","","","","","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock("SX1")
	Endif
Next

dbSelectArea(_sAlias)

Return
