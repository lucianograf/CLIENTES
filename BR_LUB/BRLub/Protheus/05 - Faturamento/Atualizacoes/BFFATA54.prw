#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BFFATA54
(long_description)
@type function
@author Iago Luiz Raimondi
@since 28/12/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATA54()

	Local oDlg,oPanelTop,oPanelAll,oPanelBot
	Local cCodVen	:= Space(6)
	Local cCodOpe 	:= Space(6)
	Local cNomAge	:= Space(50)
	Local dDataDe 	:= Date()
	Local dDataAte 	:= Date()
	Local aTpAgend	:= {"1=Normal","2=Top 100 SN","3=Top 100 Sem Compra"}
	Local lOk 		:= .F.
	Local nI
	Private oTGet1
	Private oTGet2
	Private oTGet3
	Private oTGet4
	Private oTGet5
	Private oTGet6
	Private oTGet7
	Private cNomVen	:= Space(1)
	Private cNomOpe	:= Space(1)
	Private cCombo := ""
	Private oBrowse
	Private aBrowse := {{CToD("  /  /  ")," "," "," "," "}}

	DEFINE MSDIALOG oDlg TITLE "Incluir" FROM 000,000 TO 768,1024 PIXEL
	oDlg:lMaximized := .T.
	
	// Painel SUPERIOR
	oPanelTop 	:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,75,50,.T.,.F.)
	oPanelTop:align := CONTROL_ALIGN_TOP
	
	oTGet1 		:= TGet():New(05,05,{|u| IIf(PCount()>0,cCodVen := u,cCodVen)},oPanelTop,030,09,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA3",cCodVen,,,,,,,"Vendedor: ",2)
	oTGet1:bLostFocus := {|| sfVldVen(cCodVen) }
	oTGet2 		:= TGet():New(05,70,{||cNomVen},oPanelTop,120,09,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cNomVen,,,,,,,"Nome: ",2)
	oTGet3 		:= TGet():New(05,210,{|u| IIf(PCount()>0,cCodOpe := u,cCodOpe)},oPanelTop,030,09,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SU7",cCodOpe,,,,,,,"Operador: ",2)
	oTGet3:bLostFocus := {|| sfVldOpe(cCodOpe) }
	oTGet4 		:= TGet():New(05,275,{||cNomOpe},oPanelTop,120,09,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,cNomOpe,,,,,,,"Nome: ",2)
	
	oTCombo 	:= TComboBox():New(05,420,{|u|if(PCount() > 0, cCombo := u, cCombo)},aTpAgend,57,30,oPanelTop,,{||},,,,.T.,,,,,,,,,"cCombo","Tipo Agenda: ")
	oTGet5 		:= TGet():New(30,05,{|u| IIf(PCount()>0,cNomAge := u,cNomAge)},oPanelTop,220,09,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"cNomAge",,,,,,,"Nome Agenda: ",2)
	oTGet6 		:= TGet():New(30,270,{|u| IIf(PCount()>0,dDataDe := u,dDataDe)},oPanelTop,40,09,"@D",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"dDataDe",,,,,,,"Data de: ",2)
	oTGet7 		:= TGet():New(30,340,{|u| IIf(PCount()>0,dDataAte := u,dDataAte)},oPanelTop,40,09,"@D",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"dDataAte",,,,,,,"Data até: ",2)
		
	oButton1 	:= TButton():New(30,470," Gerar ",oPanelTop,{|| sfGeraDados(cCodVen,dDataDe,dDataAte) },037,012,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	// Painel CENTRAL
	oPanelAll 	:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,200,200,.T.,.F.)
	oPanelAll:align := CONTROL_ALIGN_ALLCLIENT
	oBrowse 	:= TWBrowse():New(01,01,260,184,,{"Data","Código","Loja","Nome","Ult.Atend"},{20,25,15,200,50},oPanelAll,,,,,{||},,,,,,,.F.,,.T.,,.F.,,,)

	// Atualiza browser
	oBrowse:SetArray(aBrowse)
	oBrowse:bLine := {||{aBrowse[oBrowse:nAt,1],;
		aBrowse[oBrowse:nAt,2],;
		aBrowse[oBrowse:nAt,3],;
		aBrowse[oBrowse:nAt,4],;
		aBrowse[oBrowse:nAt,5]}}
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrowse:Refresh()

	ACTIVATE MSDIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg,{||lOk := .T.,oDlg:End()},{||lOk := .F.,oDlg:End()}))

	If lOk
	
		lFirst	:= .T.
		aCab	:= {}
		aItens	:= {}
		dTemp 	:= ""
		cLinha 	:= "000000"
		cSU4Lista	:= ""
		For nI := 1 To Len(aBrowse)
	
			If Empty(dTemp) .OR. dTemp !=  aBrowse[nI][1]
			
				DbselectArea("SU4")
				Dbsetorder(1)
				cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
				ConfirmSX8()
				
				While DbSeek(xFilial() + cSU4Lista )
					cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
					ConfirmSX8()
				EndDo
				
				DbselectArea("SU4")
				RecLock("SU4",.T.)
				SU4->U4_FILIAL	:= xFilial("SU4")
				SU4->U4_STATUS 	:= "1" 										//	Ativa
				SU4->U4_TIPO 	:= "3" 										//	Vendas
				SU4->U4_LISTA 	:= cSU4Lista								//	GetSxeNum("SU4","U4_LISTA") //	Codigo do atendimento
				SU4->U4_DESC 	:= cNomAge
				SU4->U4_DATA 	:= aBrowse[nI][1]				
				SU4->U4_FORMA 	:= "1" 										//	VOZ
				SU4->U4_TELE  	:= "2" 										//	TELEVENDAS
				SU4->U4_OPERAD 	:= cCodOpe
				SU4->U4_TIPOTEL := "1" 										//	RESIDENCIAL
				MsUnlock()
				
				cLista	:= SU4->U4_LISTA
				cLinha 	:= "000000"
				dTemp	:= aBrowse[nI][1]
				
			EndIf
			
			cContato	:= U_BFTMKG01(aBrowse[nI][2],aBrowse[nI][3])
			cLinha := Soma1(cLinha)
			
			DbSelectArea("SU6")
			RecLock("SU6", .T.)
			SU6->U6_FILIAL	:= xFilial("SU6")
			SU6->U6_LISTA	:= cLista   								//	Codigo do atendimento
			SU6->U6_CODIGO	:= cLinha									//	GetSxeNum("SU6","U6_CODIGO")
			SU6->U6_FILENT	:= xFilial( "SA1" )				 			//	xFilial("SA1")
			SU6->U6_ENTIDA	:= "SA1"									//	"SA1"
			SU6->U6_CODENT	:= aBrowse[nI][2]+aBrowse[nI][3]
			SU6->U6_ORIGEM	:= "3"  									//	Atendimento
			SU6->U6_CONTATO	:= cContato
			SU6->U6_DATA	:= aBrowse[nI][1]
			SU6->U6_HRINI 	:= "08:00"
			SU6->U6_HRFIM	:= "23:59"
			SU6->U6_STATUS	:= "1"   									//	Nao enviado
			
			MsUnLock()
		
		Next
	
	EndIf

Return


/*/{Protheus.doc} sfGeraCart
(long_description)
@type function
@author iago.raimondi
@since 29/11/2016
@version 1.0
@param cVend, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldVen(cVend)

	dbSelectArea("SA3")
	dbSetOrder(1)
	If dbSeek(xFilial("SA3")+cVend)
		cNomVen	:= SA3->A3_NOME
		Return .T.
	Else
		MsgAlert("Vendedor não foi encontrado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf

Return .F.

/*/{Protheus.doc} sfGeraCart
(long_description)
@type function
@author iago.raimondi
@since 29/11/2016
@version 1.0
@param cVend, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldOpe(cOper)

	dbSelectArea("SU7")
	dbSetOrder(1)
	If dbSeek(xFilial("SU7")+cOper)
		cNomOpe	:= SU7->U7_NOME
		Return .T.
	Else
		MsgAlert("Operador não foi encontrado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	EndIf

Return .F.

/*/{Protheus.doc} sfGeraDados
(long_description)
@type function
@author iago.raimondi
@since 29/11/2016
@version 1.0
@param cVend, character, (Descrição do parâmetro)
@param dDataDe, data, (Descrição do parâmetro)
@param dDataAte, data, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGeraDados(cVend,dDataDe,dDataAte)

	Local dDateAtual := dDataDe
	Local dDataDe	 := dDataDe
	Local dDataAte	 := dDataAte
	
	aBrowse := {}
	While dDateAtual <= dDataAte
		
		If (Select("QRY") <> 0)
			QRY->(dbCloseArea())
		Endif
		
		cQry := "SELECT A1.A1_COD AS CODIGO, A1.A1_LOJA AS LOJA, A1.A1_NOME AS NOME, A1.A1_ULTVIS AS ULTVIS"
		cQry += "  FROM SA1020 A1"
		cQry += " WHERE A1.D_E_L_E_T_ = ' '"
		cQry += "   AND CASE"
		cQry += "         WHEN MOD(TO_NUMBER(TO_CHAR(TO_DATE('"+ DToS(dDateAtual) +"', 'YYYYMMDD'), 'IW')) -"
		cQry += "                  DECODE(A1.A1_SEMTMK, ' ', '0', A1.A1_SEMTMK),"
		cQry += "                  (A1.A1_TEMVIS / 7)) = 0 THEN"
		cQry += "          CASE"
		cQry += "            WHEN MOD((TO_NUMBER(TO_CHAR(TO_DATE('"+ DToS(dDateAtual) +"', 'YYYYMMDD'), 'IW'))),"
		cQry += "                     4) = 0 THEN"
		cQry += "             4"
		cQry += "            ELSE"
		cQry += "             MOD((TO_NUMBER(TO_CHAR(TO_DATE('"+ DToS(dDateAtual) +"', 'YYYYMMDD'), 'IW'))), 4)"
		cQry += "          END"
		cQry += "         ELSE"
		cQry += "          0"
		cQry += "       END <> 0"
		cQry += "   AND TO_CHAR(TO_DATE('"+ DToS(dDateAtual) +"', 'YYYYMMDD'), 'D') = A1.A1_DIAWEEK"
		cQry += "   AND A1.A1_FILIAL = '  '"
		// Agenda normal
		If cCombo == "1"
			cQry += "   AND A1_VEND = '"+ cVend +"'"
			cQry += " ORDER BY A1_SEQVIST"
		// Top 100 SN
		ElseIf cCombo == "2"
			cQry += "   AND (A1.A1_COD, A1.A1_LOJA) IN"
			cQry += "       (SELECT A1_COD, A1_LOJA"
			cQry += "          FROM SA1020 A1"
			cQry += "         WHERE D_E_L_E_T_ = ' '"
			cQry += "           AND A1_VEND = '001243'"
			cQry += "           AND A1_FILIAL = '  ')"
			cQry += " ORDER BY A1_SEQVIST"
		// Top 100 Sem compra
		Else
			cQry += "   AND (A1.A1_COD, A1.A1_LOJA) IN"
			cQry += "       (SELECT A1_COD, A1_LOJA"
			cQry += "          FROM SA1020 A1"
			cQry += "         WHERE D_E_L_E_T_ = ' '"
			cQry += "           AND A1_VEND = '001243'"
			cQry += "           AND A1_FILIAL = '  ')"
			cQry += " ORDER BY A1_SEQVIST"
			
		EndIf
	 
		TCQUERY cQry NEW ALIAS "QRY"
		
		If QRY->(!EOF())
						
			While QRY->(!EOF())
			
				If (Select("QRY2") <> 0)
					QRY2->(dbCloseArea())
				Endif
				
				//Verifica se possui agendamento para os proximos 7 dias		
				cQry2 := "SELECT U6_CODENT"
				cQry2 += "    FROM SU6020 U6"
				cQry2 += "   WHERE U6.D_E_L_E_T_ = ' '"
				cQry2 += "     AND U6.U6_FILIAL = '"+ xFilial("SU6") +"'"
				cQry2 += "     AND U6.U6_CODENT = '"+ QRY->CODIGO + QRY->LOJA +"'"
				cQry2 += "     AND U6.U6_ENTIDA = 'SA1'"
				cQry2 += "     AND U6.U6_STATUS != '3'"
				cQry2 += "     AND U6.U6_DATA BETWEEN"
				cQry2 += "         TO_CHAR(TO_DATE('"+ DToS(dDateAtual) +"', 'YYYYMMDD') - 7, 'YYYYMMDD') AND"
				cQry2 += "         TO_CHAR(TO_DATE('"+ DToS(dDateAtual) +"', 'YYYYMMDD') + 7, 'YYYYMMDD')"
				
				TCQUERY cQry2 NEW ALIAS "QRY2"
				
				If QRY2->(EOF())
					aTmp := {}
					Aadd(aTmp,dDateAtual)
					Aadd(aTmp,QRY->CODIGO)
					Aadd(aTmp,QRY->LOJA)
					Aadd(aTmp,QRY->NOME)
					Aadd(aTmp,SToD(QRY->ULTVIS))
					Aadd(aBrowse,aTmp)
				
				EndIf
							
				If (Select("QRY2") <> 0)
					QRY2->(dbCloseArea())
				Endif
				
				QRY->(dbSkip())
			End
			
		EndIf
		
		If (Select("QRY") <> 0)
			QRY->(dbCloseArea())
		Endif
	
		dDateAtual += 1
	End
	
	oBrowse:SetArray(aBrowse)
	oBrowse:bLine := {||{aBrowse[oBrowse:nAt,1],;
		aBrowse[oBrowse:nAt,2],;
		aBrowse[oBrowse:nAt,3],;
		aBrowse[oBrowse:nAt,4],;
		aBrowse[oBrowse:nAt,5]}}
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oBrowse:Refresh()

Return