#INCLUDE "rwmake.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³LOG007    º Autor ³ Rafael Meyer          º Data ³17/06/04  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Cancela romaneio na Sz1 E libera sf2                       º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico super log                                       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

User Function log007

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

Private	 cRomaneio	:= Space(6)
Private  cTransp    := Space(6)
Private  cDescTran  := Space(40)
Private  cVeiculo   := Space(8)
Private  cDescVeic  := Space(30)
Private  cMotorista := Space(6)
Private  cDescMoto  := Space(40)
Private  cRespons   := Space(6)
Private  cDescResp  := Space(40)

Private aArray   :={}

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

// Montagem da Tela
dbselectarea("DA3")
dbselectarea("DA4")
dbselectarea("DAU")
dbselectarea("SA4")

@ 0,0 TO 270,480 DIALOG oDlg TITLE "Cancela Romaneio"
@ 5,5 TO 130,235

@ 30,15 Say "Informe o Romaneio para Cancelamento"
@ 50,65 GET  cRomaneio PICTURE "@!" When .t. size 40,20 VALID if (empty(cRomaneio),.f.,ExistCpo("Sz1",cRomaneio,1,"N. INVALIDO")) 

@ 110,080 BMPBUTTON TYPE 1 ACTION seleciona()//if (!EMPTY(cveiculo),SELECIONA(oDlg),PREENCHE())
@ 110,130 BMPBUTTON TYPE 2 ACTION Close(oDlg)

ACTIVATE DIALOG oDlg CENTERED

Return

Static Function SELECIONA()

aCAMPOS:={}
Aadd(aCampos,{ "DOC"   	,"C",TamSX3("Z1_NOTAFIS")[1],0 } )
Aadd(aCampos,{ "SERIE" 	,"C",3,0 } )
Aadd(aCampos,{ "EMISSAO","C",8,0 } )
Aadd(aCampos,{ "HORA"	,"C",5,0 } )
Aadd(aCampos,{ "FILIAL" ,"C",02,0 } )//OK
Aadd(aCampos,{ "ROMANEI","C",06,0 } )
Aadd(aCampos,{ "TRANSP" ,"C",06,0 } )

// cNomArq := CriaTrab(aCampos)

If !Empty(cRomaneio)
	cCond := 'ROMANEI =="'+cRomaneio+'"'
Else
	cCond := ""
Endif


// dbUseArea(.T.,,cNomArq,"TRB",nil,.F.)
// IndRegua("TRB",cNomArq,"DOC+SERIE",,ccond,"Selecionando Registros...")

cAlias := "TRB"
oTmpTable := FWTemporaryTable():New("TRB",aCampos)
oTmpTable:Create()

aChoice := {}
dbSelectArea("SZ1")
If !Empty(cRomaneio)
	Set filter to SZ1->Z1_ROMANEI	== cRomaneio
Endif
dbGotop()
While !eof()
	dbSelectArea("TRB")
	RecLock("TRB",.t.)
	TRB->DOC       := SZ1->Z1_NOTAFIS
	TRB->SERIE     := SZ1->Z1_SERIE
	TRB->EMISSAO   := DTOC(SZ1->z1_EMISSAO)
	TRB->HORA      := SZ1->Z1_HORA
	TRB->ROMANEI   := SZ1->Z1_ROMANEI
	TRB->TRANSP    := SZ1->Z1_TRANSP
	MsUnlock("TRB")
	
	Aadd(aChoice," ³"+TRB->DOC+"³"+TRB->SERIE+"³"+TRB->EMISSAO+"³"+TRB->HORA+"³"+TRB->ROMANEI+"³"+TRB->filial)//+"³"+TRB->OK)
	
	dbSelectArea("Sz1")
	dbSkip()
Enddo
DbSelectArea("SZ1")
Set Filter to

dbSelectArea("TRB")
dbGotop()

// Para Utilizacao de um arquivo qualquer sem o SX3 em um browse padrao
aBRW := {}
Aadd(aBRW,{"FILIAL"     ," "})//OK
Aadd(aBRW,{"DOC"   ,"Conhecimento"})
Aadd(aBRW,{"SERIE" ,"Serie"})
Aadd(aBRW,{"EMISSAO" ,"Emissao"})
Aadd(aBRW,{"HORA","Hora"})
Aadd(aBRW,{"ROMANEI","Romaneio"})

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Janela Principal                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cTitulo:="Selecao de Romaneios Gerados"
cText1:=""
cText2:=""
cText3:=""
cText4:=""
cText5:=""
//165  115           //500    //625
@ 50,50 TO 600,1000 DIALOG oDlg3 TITLE cTitulo
dbSelectArea("TRB") 
dbGotop()

//Browse para escolha das Notas Faturada
@  10,15 SAY OemToAnsi("Marque os Itens para Cancelar") Size 90, 8
@  20,15 TO 250,460 BROWSE "TRB" FIELDS aBRW ENABLE "!FILIAL" MARK "FILIAL" //140,255

dbSelectArea("TRB") 
dbGotop()
//146
@ 260,180 BUTTON "_Confirmar" SIZE 50,10 ACTION GRAVA()
@ 260,250 BUTTON "_Sair"     SIZE 50,10 ACTION Close(oDlg3).and. close(oDlg)

ACTIVATE DIALOG oDlg3 CENTERED

If Select("TRB") > 0 
	TRB->(DbCloseArea())
Endif

Return

Static function PREENCHE()
MsgAlert("Falta Preencher algum Dado","Alerta")
return

Static FUNCTION GRAVA()

If !MsgYesNo("Tem Certeza que quer Cancelar os Itens Marcados?","Cancelamento de Romaneio")
	MsgStop("Cancelado pelo Operador","Encerramento")	
Else
	
	dbSelectArea("TRB")
	dbGotop()
	arrnotas:={}
	While TRB->(!eof())
		dbSelectArea("TRB")
		
		If Marked("FILIAL") //.Or. Empty(TRB->filial)
			TRB->(dbSkip())
			Loop
		End
		aAdd(arrnotas,{	TRB->doc,;
		TRB->serie,;
		TRB->EMISSAO,;
		TRB->HORA,;
		TRB->ROMANEI,;
		TRB->TRANSP})
		
		TRB->(dbSkip())
	End
	TRB->(DbCloseArea())
	
	For i := 1 To Len(arrnotas)
		
		DbSelectarea("SF2")
		DbSetorder(1) //3
		If DbSeek(xFilial("SF2")+arrnotas[i][1]+arrnotas[i][2])
			Reclock("SF2",.f.)
			SF2->F2_EXPSLOG	:=" "
			MsUnlock("Sf2")		
		Endif
		
		DbSelectArea("SZ1")
		DbSetOrder(1) //3
		If DbSeek(xFilial("sz1")+cRomaneio+arrnotas[i][1])
			Reclock("SZ1",.F.)
			dbdelete()//deleta romaneio
			MsUnlock("SZ1")
		Else
			MsgInfo("Nao achou o Romaneio para Cancelar ","Informação")
		Endif
	Next i
	Close(oDlg3)
	Close(oDlg)
	
Endif  

Return
