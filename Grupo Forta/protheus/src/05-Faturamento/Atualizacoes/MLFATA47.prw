#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} MLFATA47
(Gerar romaneio na tabela SZ2)
@author MarceloLauschner
@since 15/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MLFATA47()


	Local		nOpcX			:= 0
	Private 	cRomaneio   	:= GetMv("GF_ROMANUM")
	Private 	cTransp     	:= Space(6)
	Private 	cDescMoto   	:= Space(40)
	Private 	cRespons    	:= Space(6)
	Private 	cPlaca      	:= Space(8)
	Private 	cLocRetirada 	:= "01"
	Private 	cDescLocRet		:= ""
	Private		cAlsSZ			:= "SZ2"
	Private		cAlsSZAux		:= "SZ2->Z2" //IIf(cEmpAnt == "05","SZ2->Z2","SZ1->Z1")

	cRomaneio   := StrZero(Val(cRomaneio)+1,6)

	// Montagem da Tela
	dbselectarea("DA3")
	dbselectarea("DA4")
	dbselectarea("DAU")
	dbselectarea("SA4")

	DEFINE MSDIALOG oDlgPerg FROM 0,0  TO 300,480 TITLE OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Geração de Romaneio") Of oMainWnd PIXEL

	oPanel1 := TPanel():New(0,0,'',oDlgPerg, oDlgPerg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_ALLCLIENT

	// Selecionando o arquivo de cliente
	@ 15,15 Say "Romaneio:" Of oPanel1 Pixel
	@ 15,65 Say cRomaneio  Of oPanel1 Pixel

	@ 032,015 Say "Transportadora" Of oPanel1 Pixel
	@ 030,065 MsGet cTransp Picture "@!" Valid (Iif(!Empty(cTransp),(Posicione("SA4",1,xFilial("SA4")+cTransp,"A4_NOME"),ExistCpo("SA4",cTransp,1,"N. INVALIDO")),.T.)) F3 "SA4" Size 40,10 Of oPanel1 Pixel
	@ 030,115 MsGet SA4->A4_NOME Size 115,10 Of oPanel1 Pixel When .F.
	@ 047,015 Say "Placa" Of oPanel1 Pixel
	@ 045,065 Get cPlaca Picture "AAA-9999" Size 60,10 Of oPanel1 Pixel
	@ 062,015 Say "Motorista" Of oPanel1 Pixel
	@ 060,065 Get cDescMoto Picture "@!" Size 115,10 Of oPanel1 Pixel
	@ 077,015 Say "Responsável"  Of oPanel1 Pixel
	@ 075,065 MsGet cRespons Picture "@!"  Valid (Posicione("DAU",1,xFilial("DAU")+cRespons,"DAU_NOME"),ExistCpo("DAU",cRespons,1,"N. INVALIDO")) F3 "DAU" Size 40,10 Of oPanel1 Pixel
	@ 075,115 MsGet DAU->DAU_NOME Size 115,10 Of oPanel1 Pixel  When .f.
	
	ACTIVATE MSDIALOG oDlgPerg CENTERED ON INIT EnchoiceBar(oDlgPerg,{|| Iif(Empty(cRespons),(MsgAlert("Não foi informado um responsável!","Responsável")),( nOpcX:=1,oDlgPerg:End()))},{||oDlgPerg:End()},,)

	If nOpcX == 1
		sfSelect()
	Endif

Return



/*/{Protheus.doc} sfSelect
(long_description)
@author MarceloLauschner
@since 16/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSelect()


	Local		nOpcX 		:= 0
	Local		aBrw
	Local 		oOK 		:= LoadBitmap(GetResources(),'br_verde')
	Local 		oNO 		:= LoadBitmap(GetResources(),'br_vermelho')
	Private		aList		:= {}

	cQry := " "
	cQry += "SELECT F2_DOC,F2_SERIE,F2_CLIENTE,F2_LOJA,F2_EMISSAO,F2_TRANSP,F2_OK,A1_NOME,D2_PEDIDO,A1_CEP,A1_MUN"
	cQry += "  FROM " + RetSqlName("SF2") + " F2, " + RetSqlName("SD2") + " D2, " + RetSqlName("SA1")+" A1 "
	cQry += " WHERE D2.D_E_L_E_T_ =  ' ' "
	cQry += "   AND D2_LOJA = F2_LOJA "
	cQry += "   AND D2_CLIENTE = F2_CLIENTE "
	cQry += "   AND D2_SERIE = F2_SERIE "
	cQry += "   AND D2_DOC = F2_DOC "
	cQry += "   AND D2_FILIAL = '"+xFilial("SD2") + "' "
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_LOJA = F2_LOJA "
	cQry += "   AND A1_COD = F2_CLIENTE "
	cQry += "   AND A1_FILIAL = '"+xFilial("SA1")+"' "
	cQry += "   AND F2.D_E_L_E_T_ = ' ' "
	cQry += "   AND F2_EMISSAO > '" + DTOS(Date()-30) + "' "
	cQry +="    AND F2_FILIAL = '" + xFilial("SF2") + "' "
	If !Empty(cTransp)
		cQry += " AND F2_EXPSLOG = ' ' "
		cQry += " AND F2_TRANSP ='"+cTransp+"'"
	Else
		cQry += " AND F2_EXPSLOG = ' ' "//
	Endif
	cQry += "   AND F2_TIPO = 'N' "
	cQry += " GROUP BY F2_DOC,F2_SERIE,F2_CLIENTE,F2_LOJA,F2_EMISSAO,F2_TRANSP,F2_OK,A1_NOME,D2_PEDIDO,A1_CEP,A1_MUN "
	cQry += " ORDER BY F2_DOC "

	TCQUERY cQry NEW ALIAS "QRY"

	While !Eof()

		Aadd(aList,{.F.,;
			QRY->F2_SERIE,;
			QRY->F2_DOC,;
			QRY->F2_CLIENTE,;
			QRY->F2_LOJA,;
			QRY->A1_NOME,;
			DTOC(STOD(QRY->F2_EMISSAO)),;
			QRY->F2_TRANSP,;
			Posicione("SA4",1,xFilial("SA4")+QRY->F2_TRANSP,"A4_NOME"),;
			QRY->D2_PEDIDO,;
			QRY->A1_CEP + " - " + QRY->A1_MUN})
		dbSelectArea("QRY")
		dbSkip()
	Enddo
	QRY->(DbCloseArea())

	If Len(aList) == 0
		MsgAlert("Não houveram notas pendentes de manifestação!")
		Return
	Endif

	aBRW := {{},{}}
	Aadd(aBRW[1]," ")				; Aadd(aBRW[2],10)
	Aadd(aBRW[1],"Série")			; Aadd(aBRW[2],30)
	Aadd(aBRW[1],"NF Cliente")		; Aadd(aBRW[2],50)
	Aadd(aBRW[1],"Cliente")			; Aadd(aBRW[2],30)
	Aadd(aBRW[1],"Loja")			; Aadd(aBRW[2],20)
	Aadd(aBRW[1],"Nome")			; Aadd(aBRW[2],160)
	Aadd(aBRW[1],"Emissão")		    ; Aadd(aBRW[2],30)
	Aadd(aBRW[1],"Cód.Transp")		; Aadd(aBRW[2],30)
	Aadd(aBRW[1],"Nome Transportadora")	; Aadd(aBRW[2],150)
	Aadd(aBRW[1],"Pedido")			; Aadd(aBRW[2],40)
	Aadd(aBRW[1],"CEP - Cidade " )			; Aadd(aBRW[2],50)

	DEFINE MSDIALOG oDlgTra FROM 0,0  TO 270,480 TITLE OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+"Marque as Notas p/ geracao do Romaneio " + cDescLocRet) Of oMainWnd PIXEL
	oDlgTra:lMaximized 	:= .T.

	oBrowse := TWBrowse():New( 01 , 01, 260,184,,aBRW[1],aBRW[2],oDlgTra,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )


	oBrowse:SetArray(aList)
	oBrowse:bLine := {||{If(aList[oBrowse:nAt,01],oOK,oNO),;
		aList[oBrowse:nAt,02],;
		aList[oBrowse:nAt,03],;
		aList[oBrowse:nAt,04],;
		aList[oBrowse:nAt,05],;
		aList[oBrowse:nAt,06],;
		aList[oBrowse:nAt,07],;
		aList[oBrowse:nAt,08],;
		aList[oBrowse:nAt,09],;
		aList[oBrowse:nAt,10],;
		aList[oBrowse:nAt,11] } }
	// Troca a imagem no duplo click do mouse
	oBrowse:bLDblClick := {|| aList[oBrowse:nAt][1] := !aList[oBrowse:nAt][1],oBrowse:DrawSelect()}

	oBrowse:align := CONTROL_ALIGN_ALLCLIENT


	ACTIVATE MSDIALOG oDlgTra CENTERED ON INIT (EnchoiceBar(oDlgTra,{|| nOpcX:=1,oDlgTra:End()},{||oDlgTra:End()},,),oBrowse:DrawSelect(),oBrowse:Refresh())

	If nOpcX == 1
		sfGrava()
	Endif
    
Return

/*/{Protheus.doc} sfGrava
(Gravação da seleção de notas para o Romaneio)
@author MarceloLauschner
@since 16/02/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrava()

	Local 	i
	Local	lInc		:=	.F.

	If !MsgYesNo("Tem Certeza que quer Gerar Romaneio das notas Marcadas?","Confirmação de Geração do Romaneio")
		MsgStop("Cancelado pelo Operador","Encerramento")
	Else


		For i := 1 to Len(aList)

			If aList[i,1] // Verifica se está marcado
				DbSelectarea("SF2")
				DbSetorder(2) //3 F2_CLIENTE+F2_LOJA+F2_DOC+F2_SERIE
				If DbSeek(xFilial("SF2")+aList[i][4]+aList[i][5]+aList[i][3]+aList[i][2])
					Reclock("Sf2",.F.)
					SF2->F2_EXPSLOG	:=	"S"
					MsUnlock()

					//grava Romaneio
					DbSelectArea("SA1")
					DbSetOrder(1)
					Dbseek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)

					DbSelectarea(cAlsSZ)
					Reclock(cAlsSZ,.T.)
					&(cAlsSZAux+"_FILIAL") 	:= xFilial(cAlsSZ)
					&(cAlsSZAux+"_ROMANEI")	:= cRomaneio
					&(cAlsSZAux+"_EMISSAO")	:= dDataBase
					&(cAlsSZAux+"_HORA")   	:= Time()
					&(cAlsSZAux+"_NOTAFIS")	:= SF2->F2_DOC
					&(cAlsSZAux+"_SERIE")  	:= SF2->F2_SERIE
					&(cAlsSZAux+"_PLACA")	:= cPlaca
					&(cAlsSZAux+"_NOMEMOT")	:= cDescMoto
					&(cAlsSZAux+"_CODRESP")	:= cRespons
					&(cAlsSZAux+"_NOMERES")	:= Posicione("DAU",1,xFilial("DAU")+AllTrim(cRespons),"DAU_NOME")
					&(cAlsSZAux+"_TRANSP") 	:= cTransp
					&(cAlsSZAux+"_CLIENTE")	:= SA1->A1_COD
					&(cAlsSZAux+"_LOJA")   	:= SA1->A1_LOJA
					&(cAlsSZAux+"_NOMECLI")	:= Substr(SA1->A1_NOME,1,20)+" "+Substr(SA1->A1_NREDUZ,1,9)
					&(cAlsSZAux+"_VOLUMES")	:= SF2->F2_VOLUME1
					&(cAlsSZAux+"_CNPJ")   	:= SA1->A1_CGC
					MsUnlock()
					lInc	:= .T.
				Else
					MsgAlert("Nao achou o Documento fiscal para Gravar o Romaneio da Nota "+aList[i][4]+aList[i][5]+aList[i][3]+aList[i][2],"Nota fiscal não encontrada!")
				Endif
			Endif
		Next i

		If lInc
			PutMv("GF_ROMANUM",cRomaneio)
			MsgInfo("Romaneio '" + cRomaneio + "' gerado com sucesso!","Concluído!")
			U_MLFATR06() 
		Endif
	Endif

Return
