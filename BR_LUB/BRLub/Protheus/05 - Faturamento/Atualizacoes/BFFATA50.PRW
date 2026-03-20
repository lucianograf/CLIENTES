#include "rwmake.ch"


/*/{Protheus.doc} BFFATA50
(Altera Codigo barra e conversao SB1 ATRAVES DE TELA)
@author MarceloLauschner
@since 15/03/2016
@version 1.0
@return Nil 
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA50()
	
Return U_BIG007()

User Function BIG007
	
	
	Private cSenhaAtu := "200411" //SubStr(DTOC(dDataBase),2,1)+SubStr(DTOC(dDataBase),1,1)+SubStr(DTOC(dDataBase),5,1)+SubStr(DTOC(dDataBase),4,1)+SubStr(DTOC(dDataBase),8,1)+SubStr(DTOC(dDataBase),7,1)
	Private cSenhadi    := Space(6)
	Private cCodpro   := Space(15)
	Private cCodproa   := Space(15)
	Private cEanloc := Space(15)
	Private cCoddesc  := Space (45)
	Private cCodBarra := Space (15)
	Private cCodbaux  := Space (15)
	Private cCodbcx   := Space (15)
	Private nConv     := 0.00
	Private nConvaux  := 0.00
	Private cMiudeza  := Space (1)
	Private cEnd      := Space (6)
	Private nPeso	  := 0.00
	Private aItems := {"","S","N"}
	Private cCombo := Space(1)
	Private cMiudz    := Space(1)
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	/*
	@ 001,001 TO 100,400 DIALOG oDlg TITLE "Senha"
	
	@ 005,005 Say "Digite a senha do dia" Color 255
	@ 005,065 Get cSenhadi Valid Senha() PASSWORD
	
	@ 020,010 BUTTON "Avancar-->" SIZE 40,10 Action(Close(oDlg),Avancar())
	
	ACTIVATE MSDIALOG oDlg CENTERED
	
Return

Static Function Senha
	
	If cSenhadi <> cSenhaAtu
		MsgInfo("Senha invalida. Verifique","Informacao","STOP")
		Return .F.
	Endif
	
Return

Static Function Avancar       /*/
	
	
	@ 200,1 TO 380,395 DIALOG oLeTxt TITLE OemToAnsi("Alterar dados logísticos para separação,conferência e organização.")
	@ 02,10 TO 070,190
	@ 10,018 Say "Código produto:"
	@ 10,070 Get cCodpro F3 "SB1" size 50,10
	@ 30,018 Say "Digite o código de barra: "
	@ 30,100 Get cEanloc size 60,10
	@ 72,133 BMPBUTTON TYPE 01 ACTION OkLeTxt()
	@ 72,163 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)
	
	Activate Dialog oLeTxt Centered
	
Return

Static Function OkLeTxt()
	
	If !Empty(cEanloc) .and. empty(cCodpro)
		dbselectarea("SB1")
		dbsetorder(5)
		If dbseek(xFilial("SB1")+cEanloc,.F.)
			cCodproa := SB1->B1_COD
			okalt()
		Else
			MsgAlert("Código de barra não cadastrado!!!","Atencao!")
			Close(oLeTxt)
		endif
	Elseif empty(cEanloc) .and. !empty(cCodpro)
		Dbselectarea("SB1")
		dbsetorder(1)
		If Dbseek(xFilial("SB1")+cCodpro,.F.)
			cCodproa := SB1->B1_COD
			okalt()
		Else
			MsgAlert("Código de produto inexistente. Favor consulte novamente!! Utilize F3 para pesquisar.","Atencao!")
			Close(oLeTxt)
		Endif
	Elseif !empty(cEanloc) .and. !empty(cCodpro)
		Close(oLeTxt)
	Elseif !empty(cEanloc) .and. !empty(cCodpro)
		MsgAlert("Favor entre só com uma informação. Código do produto ou só código de Barra.","Atencao!")
		Close(oLeTxt)
	Endif
	
Return


Static function okalt()
	
	cCodproa   := SB1->B1_COD
	
	@ 270,1 TO 490,595 DIALOG aLtTxt TITLE OemToAnsi("Alterar dados logísticos.")
	@ 02,10 TO 080,260
	@ 10,018 Say SB1->B1_COD
	@ 10,060 Say SB1->B1_DESC
	@ 20,018 Say "Código de barra: "
	@ 20,060 Say SB1->B1_CODBAR
	@ 20,110 Get cCodBarra size 50,10 When .F. 
	@ 20,168 Say "Bloqueado p/Alteração nesta rotina!"
	If SB1->(FieldPos("B1_DUN14A")) > 0 
		@ 32,018 Say "Dun14 A:"
		@ 32,060 Say SB1->B1_DUN14A
		@ 32,110 Get cCodbaux  size 50,10
	Endif 
	@ 32,170 Say "Conv 14 A:"
	@ 32,205 Say SB1->B1_CONVA
	@ 32,220 Get nConvaux Picture "@E 999,999" size 20,10
	@ 44,018 Say "Cód.Dun 14 B:"
	@ 44,060 SAY SB1->B1_DUN14
	@ 44,110 Get cCodbcx size 50,10
	If SB1->(FieldPos("B1_CONVB")) > 0 
		@ 44,170 Say "Conv 14 B:"
		@ 44,205 SAY SB1->B1_CONVB
		@ 44,220 Get nConv Picture "@E 999,999" size 20,10
	Endif 
	@ 56,018 Say "Miudeza:"
	@ 56,050 SAY SB1->B1_MIUD
	@ 56,070 COMBOBOX cMiudeza ITEMS aItems size 20,10
	@ 56,120 Say "Peso:"
	@ 56,150 SAY SB1->B1_PESO
	@ 56,180 Get nPeso Picture "@E 999,999.999" size 40,10
	@ 68,018 Say "Endereço:"
	If SB1->(FieldPos("B1_LOCAL")) > 0 
		@ 68,050 SAY SB1->B1_LOCAL
		@ 68,070 Get cEnd size 20,10
	ElseIf SB1->(FieldPos("B1_XLOCAL")) > 0 
		@ 68,050 SAY SB1->B1_XLOCAL
		@ 68,070 Get cEnd size 20,10
	Endif 
	@ 82,133 BMPBUTTON TYPE 01 ACTION (Close(aLtTxt),OkaltTxt())
	@ 82,163 BMPBUTTON TYPE 02 ACTION (Close(aLtTxt),Close(oLeTxt))
	
	Activate Dialog aLtTxt Centered
	
	
Return


/*/{Protheus.doc} OkaLtTxt
(long_description)
@author MarceloLauschner
@since 15/03/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function OkaLtTxt()
	
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbGotop()
	If DbSeek(xFilial("SB1")+cCodproa,.T.)
		dbSelectArea("SB1")
		RecLock("SB1",.F.)
		if !Empty(nPeso)
			SB1->B1_PESO   := nPeso
		Endif
		if !Empty(cCodBarra)
			SB1->B1_CODBAR := cCodBarra
		Endif
		if !Empty(cMiudeza)
			SB1->B1_MIUD   := cMiudeza
		Endif
		if !Empty(nConv) .And. SB1->(FieldPos("B1_CONVB")) > 0 
			SB1->B1_CONVB  := nConv
		Endif
		if !Empty(cCodbcx)
			SB1->B1_DUN14  := cCodbcx
		Endif
		if !Empty(cCodbaux) .And. SB1->(FieldPos("B1_DUN14A")) > 0 
			SB1->B1_DUN14A := cCodbaux
		Endif
		if !Empty(nConvaux)
			SB1->B1_CONVA  := nConvaux
		Endif
		if !Empty(cEnd) .And. SB1->(FieldPos("B1_LOCAL")) > 0 
			SB1->B1_LOCAL  := cEnd
		Elseif !Empty(cEnd) .And. SB1->(FieldPos("B1_XLOCAL")) > 0 
			SB1->B1_XLOCAL  := cEnd
		Endif
		MSUnLock("SB1")
		
		MsgAlert("Entrada de Dados Realizada com sucesso!!","Informação!")
	Else
		MsgAlert("Erro na alteração. Favor contate CPD ","Atenção!")
	Endif
	SB1->(DbCloseArea())
	Close(oLeTxt)
Return
