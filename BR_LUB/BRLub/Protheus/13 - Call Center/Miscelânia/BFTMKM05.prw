#Include 'Protheus.ch'
#Include 'TopConn.ch'
#Include 'TOTVS.ch'

/*/{Protheus.doc} BFTMKM05
(Vincula cliente com contato em tabela AC8)
@type function
@author informatica4
@since 31/03/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFTMKM05()

	Local oDlg,oPanelTop,oPanelAll,oPanelBot,oSay1,oTGet1,oSay2,oTGet2
	Local aArea := GetArea()
	
	Private oBrowse
	Private cCodCont 	:= SU5->U5_CODCONT
	Private cDscCont 	:= SU5->U5_CONTAT
	Private cCodCli 	:= Space(Len(CriaVar("A1_COD")))
	Private cLojCli 	:= Space(Len(CriaVar("A1_LOJA")))
	Private cNomCli 	:= Space(Len(CriaVar("A1_NOME")))	
		
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()	

	DEFINE DIALOG oDlg TITLE "Cliente X Contato" FROM 000,000 TO 400,600 PIXEL
	
	/************************************************************************************/
	/* PAINEL SUPERIOR																	*/
	/************************************************************************************/
	oPanelTop := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,20,.T.,.F.)
	oPanelTop:Align := CONTROL_ALIGN_TOP
	
	oSay1	:= TSay():New(07,03,{||"Código"},oPanelTop,,,,,,.T.,,,200,20)
	oTGet1	:= TGet():New(05,23,{|u| IIf(PCount()>0,cCodCont:= u,cCodCont)},oPanelTop,010,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"cCodCont",,,,)
	
	oSay2	:= TSay():New(07,83,{||"Nome"},oPanelTop,,,,,,.T.,,,200,20)
	oTGet2	:= TGet():New(05,103,{|u| IIf(PCount()>0,cDscCont:= u,cDscCont)},oPanelTop,150,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"cDscCont",,,,)
	
	
	/************************************************************************************/
	/* PAINEL CENTRAL																	*/
	/************************************************************************************/
	oPanelAll:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,200,200,.T.,.F.)
	oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT
	
	oBrowse := TCBrowse():New(01,01,100,100,,{'Código','Loja','Nome'},{30,20},oPanelAll,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	sfConsAC8(cCodCont)
	oBrowse:bLDblClick := {|| cCodCli := oBrowse:aArray[oBrowse:nAt][1], cLojCli := oBrowse:aArray[oBrowse:nAt][2], cNomCli := oBrowse:aArray[oBrowse:nAt][3], oButton2:SetFocus() }
	
	
	/************************************************************************************/
	/* PAINEL INFERIOR																	*/
	/************************************************************************************/
	oPanelBot := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,40,.T.,.F.)
	oPanelBot:Align := CONTROL_ALIGN_BOTTOM
	
	oSay3	:= TSay():New(07,03,{||"Código"},oPanelBot,,,,,,.T.,,,200,20)
	oTGet3	:= TGet():New(05,26,{|u| IIf(PCount()>0,cCodCli:= u,cCodCli)},oPanelBot,010,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA1","cCodCli",,,,)
	oTGet3:bLostFocus := {||sfVld2Cli()}
	
	oSay4	:= TSay():New(07,56,{||"Loja"},oPanelBot,,,,,,.T.,,,200,20)
	oTGet4	:= TGet():New(05,73,{|u| IIf(PCount()>0,cLojCli:= u,cLojCli)},oPanelBot,02,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"cLojCli",,,,)
	oTGet4:bLostFocus := {||sfVld2Cli()}
	
	oSay5	:= TSay():New(07,98,{||"Nome"},oPanelBot,,,,,,.T.,,,200,20)
	oTGet5	:= TGet():New(05,118,{|u| IIf(PCount()>0,cNomCli:= u,cNomCli)},oPanelBot,150,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"cNomCli",,,,)
	
	oButton1 := TButton():New(25, 90," Incluir "	,oPanelBot,{|| IIf(sfVldCli(),sfInclAC8(),MsgAlert("Cliente não foi encontrado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))), sfConsAC8(cCodCont) },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton2 := TButton():New(25, 133," Excluir "	,oPanelBot,{|| IIf(sfVldCli(),sfExclAC8(),MsgAlert("Cliente não foi encontrado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))), sfConsAC8(cCodCont) },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	oButton3 := TButton():New(25, 176," Cancelar "	,oPanelBot,{|| oDlg:End() },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	ACTIVATE DIALOG oDlg CENTERED 

	RestArea(aArea)
	
Return

Static Function sfVld2Cli

If !Empty(cCodCli) .AND. !Empty(cLojCli)
	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+cCodCli+cLojCli)
		cNomCli := SA1->A1_NOME
	Else
		cNomCli := Space(Len(CriaVar("A1_NOME")))	
		MsgAlert("Cliente não foi encontrado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf
EndIf

Return


/*/{Protheus.doc} sfVldCli
(long_description)
@type function
@author Iago Luiz Raimondi
@since 17/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldCli

If !Empty(cCodCli) .AND. !Empty(cLojCli) .AND. !Empty(cNomCli)
	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+cCodCli+cLojCli)
		Return .T.
	EndIf
EndIf

Return .F.


/*/{Protheus.doc} sfInclAC8
(long_description)
@type function
@author Iago Luiz Raimondi
@since 17/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfInclAC8

If MsgNoYes("Deseja vincular o Cliente X Contato?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

	dbSelectArea("AC8")
	dbSetOrder(1)
	If !dbSeek(xFilial("AC8") + cCodCont +"SA1"+ xFilial("AC8")+ AllTrim(cCodCli) + AllTrim(cLojCli))
		RecLock("AC8",.T.)
		AC8->AC8_ENTIDA := "SA1"
		AC8->AC8_CODENT := SA1->A1_COD + SA1->A1_LOJA
		AC8->AC8_CODCON := SU5->U5_CODCONT
		MsUnlock()
	Else
		MsgAlert("Vinculo já existe!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf
	
	MsgInfo("Cadastrado com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	
	cCodCli := ""
	cLojCli := ""
	cNomCli := ""
	
EndIf

Return


/*/{Protheus.doc} sfExclAC8
(long_description)
@type function
@author Iago Luiz Raimondi
@since 17/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfExclAC8

If MsgNoYes("Deseja excluir o vinculo do Cliente X Contato?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

	dbSelectArea("AC8")
	dbSetOrder(1)
	If dbSeek(xFilial("AC8") + cCodCont +"SA1"+ xFilial("AC8")+ AllTrim(cCodCli) + AllTrim(cLojCli))
		RecLock("AC8",.F.)
		dbDelete()
		MsUnlock()
	Else
		MsgAlert("Vinculo não existe!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf
	
	MsgInfo("Vinculo excluído com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

	cCodCli := ""
	cLojCli := ""
	cNomCli := ""
	
EndIf

Return

/*/{Protheus.doc} sfConsAC8
(long_description)
@type function
@author Iago Luiz Raimondi
@since 17/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfConsAC8(cCodCont)

Local cQry
Local aBrowse := {}

If (Select("QRY") <> 0)
	QRY->(dbCloseArea())
Endif

cQry := ""
cQry += "SELECT A1.A1_COD AS CODIGO, A1.A1_LOJA AS LOJA, A1.A1_NOME AS NOME"
cQry += "  FROM "+ RetSqlName("AC8") +" AC8"
cQry += " INNER JOIN "+ RetSqlName("SA1020") +" A1 ON A1.A1_FILIAL = AC8.AC8_FILIAL"
cQry += "                     AND A1.A1_COD = SUBSTR(AC8.AC8_CODENT, 1, 6)"
cQry += "                     AND A1.A1_LOJA = SUBSTR(AC8.AC8_CODENT, 7, 2)"
cQry += "                     AND A1.D_E_L_E_T_ = ' '"
cQry += " WHERE AC8.D_E_L_E_T_ = ' '"
cQry += "   AND AC8.AC8_FILIAL = '"+ xFilial("AC8") +"'"
cQry += "   AND AC8.AC8_CODCON = '"+ cCodCont +"'"

TCQUERY cQry NEW ALIAS "QRY"

If QRY->(EOF())
	aTmp := {}
	Aadd(aTmp," ")
	Aadd(aTmp," ")
	Aadd(aTmp," ")
	
	Aadd(aBrowse,aTmp)
Else
	While QRY->(!EOF())
		aTmp := {}
		Aadd(aTmp,QRY->CODIGO)
		Aadd(aTmp,QRY->LOJA)
		Aadd(aTmp,QRY->NOME)
			
		Aadd(aBrowse,aTmp)
	
		QRY->(dbSkip())
	End
EndIf

If (Select("QRY") <> 0)
	QRY->(dbCloseArea())
Endif

oBrowse:SetArray(aBrowse)
oBrowse:bLine := {||{aBrowse[oBrowse:nAt,01],aBrowse[oBrowse:nAt,02],aBrowse[oBrowse:nAt,03]}}
oBrowse:Refresh()

Return aBrowse

