#Include 'Protheus.ch'
#Include "TopConn.ch"

/*/{Protheus.doc} BFFATM30
(Rotina para aprovação e consulta de RecargaWEB. Rotina depende do vendedor incluir registro (RecargaWEB) para visualização.)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
User Function BFFATM30()

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	sfCriaTela()
	
Return

/*/{Protheus.doc} sfCriaTela
(Cria tela principal para monitorar e aprovar recargas)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfCriaTela()

	Local oDlg
	Local oPanelTop,oPanelAll,oPanelBot
	Private aHeader := {}
	Private oSay1,oSay2,oSay3,oSay4,oGrp1,oGrp2,oGrp4,oBrowse,oCheck1,oCheck2,oCheck3,oCheck4
	Private oTGet1,oTGet2,oTGet3,oTGet4,oTGet5,oTGet6,oTGet7,oTGet8,oTButton1,oTButtT1
	Private oTButt1,oTButt2,oTButt3,oSayT1,oTGetT1,oSayT2,oTGetT2,oSayT3,oTGetT3,oSayT4,oTGetT4


	// Variaveis Parametros Painel Superior
	Private dDataDe 	:= (dDataBase-90)
	Private dDataAte 	:= dDataBase
	Private cVendDe		:= "      "
	Private cVendAte	:= "ZZZZZZ"
	Private cCliDe		:= "      "
	Private cCliAte		:= "ZZZZZZ"
	Private cLojDe		:= "  "
	Private cLojAte		:= "ZZ"
	Private lEnviado	:= .T.
	Private lAprovado	:= .F.
	Private lPago		:= .F.
	Private lRejeitado	:= .F.
	// Variaveis Totais Painel Inferior
	Private nTotEnv		:= 0
	Private nTotApr		:= 0
	Private nTotPag		:= 0
	Private nTotRej		:= 0


	DEFINE DIALOG oDlg TITLE "Monitor RECARGAWEB" FROM 000,000 TO 800,1200 PIXEL

	/************************************************************************************/
	/* PAINEL SUPERIOR																	*/
	/************************************************************************************/
	oPanelTop := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,100,.T.,.F.)
	oPanelTop:Align := CONTROL_ALIGN_TOP

	oGrp1   := TGroup():New(5,5,90,160," Parâmetros ",oPanelTop,,,.T.)
	oSay1	:= TSay():New(16,12,{||"Emissão:"},oPanelTop,,,,,,.T.,CLR_BLACK,,200,20)
	oTGet1 	:= TGet():New(15,45,{|u| IIf(PCount()>0,dDataDe := u,dDataDe)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,{||.T.},.F.,.F.,,.F.,.T.,,,,,,.T.)
	oTGet2 	:= TGet():New(15,105,{|u| IIf(PCount()>0,dDataAte := u,dDataAte)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,{||.T.},.F.,.F.,,.F.,.T.,,,,,,.T.)
	oSay2	:= TSay():New(31,12,{||"Vendedor:"},oPanelTop,,,,,,.T.,CLR_BLACK,,200,20)
	oTGet3 	:= TGet():New(30,45,{|u| IIf(PCount()>0,cVendDe := u,cVendDe)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA3",cVendDe,,,,)
	oTGet4 	:= TGet():New(30,105,{|u| IIf(PCount()>0,cVendAte := u,cVendAte)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA3",cVendAte,,,,)
	oSay3	:= TSay():New(46,12,{||"Cliente:"},oPanelTop,,,,,,.T.,CLR_BLACK,,200,20)
	oTGet5 	:= TGet():New(45,45,{|u| IIf(PCount()>0,cCliDe := u,cCliDe)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA1",cCliDe,,,,)
	oTGet6 	:= TGet():New(45,105,{|u| IIf(PCount()>0,cCliAte := u,cCliAte)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA1",cCliAte,,,,)
	oSay4	:= TSay():New(61,12,{||"Loja:"},oPanelTop,,,,,,.T.,CLR_BLACK,,200,20)
	oTGet7 	:= TGet():New(60,45,{|u| IIf(PCount()>0,cLojDe := u,cLojDe)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,cLojDe,,,,)
	oTGet8 	:= TGet():New(60,105,{|u| IIf(PCount()>0,cLojAte := u,cLojAte)},oPanelTop,050,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,cLojAte,,,,)


	oGrp2   := TGroup():New(5,180,90,430," Opções ",oPanelTop,,,.T.)
	oCheck1	:= TCheckBox():New(15,200,"Enviado/Aguard.Aprov",{||lEnviado},oPanelTop,100,210,,{||lEnviado := !lEnviado},,,,,,.T.,,,)
	oCheck2 := TCheckBox():New(15,300,"Aprovado/Aguard.Pag",{||lAprovado},oPanelTop,100,210,,{||lAprovado := !lAprovado},,,,,,.T.,,,)
	oCheck3 := TCheckBox():New(30,200,"Pagamento Efetuado",{||lPago},oPanelTop,100,210,,{||lPago := !lPago},,,,,,.T.,,,)
	oCheck4 := TCheckBox():New(30,300,"Recarga Rejeitada",{||lRejeitado},oPanelTop,100,210,,{||lRejeitado := !lRejeitado},,,,,,.T.,,,)

	oGrp4   := TGroup():New(5,450,90,595," Ações ",oPanelTop,,,.T.)
	oTButt1 := TButton():New(20,470,"Atualizar",oPanelTop,{||MsgRun("Atualizando registros...","Processando...",{||sfDadosGet(@oBrowse)})},105,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oTButt2 := TButton():New(35,470,"Relatório",oPanelTop,{||U_BFFATR12()},105,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oTButt3 := TButton():New(50,470,"Pagar Recarga",oPanelTop,{||sfPagar(),sfDadosGet(@oBrowse)},105,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	

	/************************************************************************************/
	/* PAINEL CENTRAL																	*/
	/************************************************************************************/
	oPanelAll:= TPanel():New(0,0,"",oDlg,,.F.,.F.,,,200,200,.T.,.F.)
	oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT

	oBrowse := TWBrowse():New(01,01,260,184,,{"","Id","Código","Loja","Nome","Vendedor","Inclusão","Aprovação","Pagamento","Rejeição","Valor"},{20,30,30},oPanelAll,,,,,{||},,,,,,,.F.,,.T.,,.F.,,,)
	oBrowse:bLDblClick := {|| IIf(!Empty(oBrowse:aArray[oBrowse:nAt][2]),(sfDadosRec(oBrowse:aArray[oBrowse:nAt]),MsgRun("Atualizando registros...","Processando...",{||sfDadosGet(@oBrowse)})),MsgAlert("boi")) }
	oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	sfDadosGet(@oBrowse)
 
	
	/************************************************************************************/
	/* PAINEL INFERIOR																	*/
	/************************************************************************************/
	oPanelBot := TPanel():New(0,0,"",oDlg,,.F.,.F.,,,0,50,.T.,.F.)
	oPanelBot:Align := CONTROL_ALIGN_BOTTOM

	oTButtT1 := TButton():New(20,470,"Legenda",oPanelBot,{||sfLegenda()},105,10,,,.F.,.T.,.F.,,.T.,,,.F. )

	oSayT1	:= TSay():New(05,5,{||"Total Aguard.Aprov"},oPanelBot,,,,,,.T.,CLR_RED,,200,20)
	oTGetT1	:= TGet():New(15,5,{||nTotEnv},oPanelBot,050,008,"@E 999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"nTotEnv",,,,)

	oSayT2	:= TSay():New(05,65,{||"Total Aguard.Pag"},oPanelBot,,,,,,.T.,CLR_RED,,200,20)
	oTGetT2	:= TGet():New(15,65,{||nTotApr},oPanelBot,050,008,"@E 999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"nTotApr",,,,)

	oSayT3	:= TSay():New(05,125,{||"Pagamento Efetuado"},oPanelBot,,,,,,.T.,CLR_RED,,200,20)
	oTGetT3	:= TGet():New(15,125,{||nTotPag},oPanelBot,050,008,"@E 999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"nTotPag",,,,)

	oSayT4	:= TSay():New(05,185,{||"Recarga Rejeitada"},oPanelBot,,,,,,.T.,CLR_RED,,200,20)
	oTGetT4	:= TGet():New(15,185,{||nTotRej},oPanelBot,050,008,"@E 999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"nTotRej",,,,)

	ACTIVATE DIALOG oDlg CENTERED

Return

/*/{Protheus.doc} sfDadosGet
(Força atualizar oBrowse da tela principal)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfDadosGet(oBrowse)

	Local oGreen   	:= LoadBitmap( GetResources(), "BR_VERDE")
	Local oYellow	:= LoadBitmap( GetResources(), "BR_AMARELO")
	Local oRed    	:= LoadBitmap( GetResources(), "BR_VERMELHO")
	Local oBlack	:= LoadBitmap( GetResources(), "BR_PRETO")
	Local aCols 	:= {}
	Local cQry		:= ""
	Local aBrowse 	:= {}

	nTotEnv		:= 0
	nTotApr		:= 0
	nTotPag		:= 0
	nTotRej		:= 0

	cWhere := ""

	If lEnviado
		cWhere += IIf(Empty(cWhere),"1",",1")
	EndIf

	If lAprovado
		cWhere += IIf(Empty(cWhere),"2",",2")
	EndIf

	If lPago
		cWhere += IIf(Empty(cWhere),"3",",3")
	EndIf

	If lRejeitado
		cWhere += IIf(Empty(cWhere),"4",",4")
	EndIf

	// Evita error.log quando não marcou alguma opção.
	If !lEnviado .AND. !lAprovado .AND. !lPago .AND. !lRejeitado
		cWhere += "0"
	EndIf

	cQry := ""
	cQry += "SELECT STATUS,"
	cQry += "       ID,"
	cQry += "       COD_CLI,"
	cQry += "       LOJA_CLI,"
	cQry += "       A1.A1_NOME AS A1_NOME,"
	cQry += "       COD_VEND,"
	cQry += "       TO_CHAR(DATA_INC,'YYYYMMDD') AS DATA_INC,"
	cQry += "       TO_CHAR(DATA_APR,'YYYYMMDD') AS DATA_APR,"
	cQry += "       TO_CHAR(DATA_PAG,'YYYYMMDD') AS DATA_PAG,"
	cQry += "       TO_CHAR(DATA_REJ,'YYYYMMDD') AS DATA_REJ,"
	cQry += "       SUM(VALOR) AS VALOR"
	cQry += "  FROM RECARGAWEB.RECARGA_ENVIO"
	cQry += " INNER JOIN "+ RetSqlName("SA1") +" A1 ON A1.A1_COD = COD_CLI"
	cQry += "                     AND A1.A1_LOJA = LOJA_CLI"
	cQry += "   WHERE STATUS IN ("+ cWhere +")"
	cQry += "   AND COD_CLI BETWEEN '"+ cCliDe +"' AND '"+ cCliAte +"'"
	cQry += "   AND LOJA_CLI BETWEEN '"+ cLojDe +"' AND '"+ cLojAte +"'"
	cQry += "   AND COD_VEND BETWEEN '"+ cVendDe +"' AND '"+ cVendAte +"'"
	cQry += "   AND TO_CHAR(DATA_INC, 'YYYYMMDD') BETWEEN '"+DTOS(dDataDe)+"' AND '"+DTOS(dDataAte)+"'"
	cQry += "	AND A1.D_E_L_E_T_ = ' '"
	cQry += " GROUP BY STATUS,"
	cQry += "          ID,"
	cQry += "          COD_CLI,"
	cQry += "          LOJA_CLI,"
	cQry += "          A1.A1_NOME,"
	cQry += "          COD_VEND,"
	cQry += "          TO_CHAR(DATA_INC, 'YYYYMMDD'),"
	cQry += "          TO_CHAR(DATA_APR, 'YYYYMMDD'),"
	cQry += "          TO_CHAR(DATA_PAG, 'YYYYMMDD'),"
	cQry += "          TO_CHAR(DATA_REJ, 'YYYYMMDD')"
	cQry += "  ORDER BY ID DESC"

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	TCQUERY cQry NEW ALIAS "QRY"

	While QRY->(!EOF())

		aCols := {}
	
		If QRY->STATUS == 1
			Aadd(aCols,oRed)
			nTotEnv	+= QRY->VALOR
		ElseIf QRY->STATUS == 2
			Aadd(aCols,oYellow)
			nTotApr	+= QRY->VALOR
		ElseIf QRY->STATUS == 3
			Aadd(aCols,oGreen)
			nTotPag	+= QRY->VALOR
		Else
			Aadd(aCols,oBlack)
			nTotRej	+= QRY->VALOR
		EndIf
	
		Aadd(aCols,QRY->ID)
		Aadd(aCols,QRY->COD_CLI)
		Aadd(aCols,QRY->LOJA_CLI)
		Aadd(aCols,QRY->A1_NOME)
		Aadd(aCols,QRY->COD_VEND)
		Aadd(aCols,QRY->DATA_INC)
		Aadd(aCols,QRY->DATA_APR)
		Aadd(aCols,QRY->DATA_PAG)
		Aadd(aCols,QRY->DATA_REJ)
		Aadd(aCols,QRY->VALOR)
	
		Aadd(aBrowse,aCols)
	
		QRY->(dbSkip())
	End

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif
	
	If Len(aBrowse) = 0
		aBrowse := {{oRed,"","","","","",SToD(""),SToD(""),SToD(""),SToD(""),0}}
	EndIf

	// Atualiza oBrowse 
	oBrowse:SetArray(aBrowse)
	oBrowse:bLine := {||{aBrowse[oBrowse:nAt,01],;
		aBrowse[oBrowse:nAt,02],;
		aBrowse[oBrowse:nAt,03],;
		aBrowse[oBrowse:nAt,04],;
		aBrowse[oBrowse:nAt,05],;
		aBrowse[oBrowse:nAt,06],;
		aBrowse[oBrowse:nAt,07],;
		aBrowse[oBrowse:nAt,08],;
		aBrowse[oBrowse:nAt,09],;
		aBrowse[oBrowse:nAt,10],;
		aBrowse[oBrowse:nAt,11]}}
	
	oBrowse:Refresh()
	
Return

/*/{Protheus.doc} sfDadosRec
(Carrega tela baseado no registro posicionado. Tela para aprovação da recarga)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfDadosRec(aRegistro)

	Local 	oDlgRec,oPaneRTop,oPaneRAll,oPaneRBot,oGrpRT1,oSayRT1,oTGetRT1,oSayRT2,oTGetRT2,oSayRT3,oTGetRT3,oSayRT4,oTGetRT4,oSayRT5,oTGetRT5
	Local	oSayRT6,oTGetRT6,oTGetRT7,oSayRT7,oSayRT8,oTGetRT8,oSayRT9,oTGetRT9,oGrpRT2,oTButtR1,oTButtR2
	Local	oSayRB1,oTGetRB1,oSayRB2,oTGetRB2,oSayRB3,oTGetRB3,oSayRB4,oTGetRB4	
	Local 	oReBrowse
	Local 	aReBrowse := {}
	Local 	cQry := ""
	Local 	nSt := 1
	Local 	nId := 2
	Local 	nCl := 3
	Local 	nLo := 4
	Local 	nNo := 5
	Local 	nVe := 6
	Local 	nDI := 7
	Local 	nDA := 8
	Local 	nDP := 9
	Local 	nDR := 10
	
	Local nTotRecarga 	:= 0
	Local lEnviado	 	:= Upper(aRegistro[nSt]:CNAME) == "BR_VERMELHO"
	Local cObs 			:= "RECARGA TRADECOM: "+Space(150)
	
	DEFINE DIALOG oDlgRec TITLE "Monitor RECARGAWEB" FROM 000,000 TO 600,800 PIXEL
	
	/************************************************************************************/
	/* PAINEL SUPERIOR																	*/
	/************************************************************************************/
	oPaneRTop := TPanel():New(0,0,"",oDlgRec,,.F.,.F.,,,10,100,.T.,.F.)
	oPaneRTop:Align := CONTROL_ALIGN_TOP
	
	oGrpRT1   	:= TGroup():New(5,5,90,240," Informações ",oPaneRTop,,,.T.)
	oSayRT1		:= TSay():New(15,15,{||"Cliente"},oPaneRTop,,,,,,.T.,,,200,20)
	oTGetRT1	:= TGet():New(25,15,{||aRegistro[nCl]},oPaneRTop,035,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	oSayRT2		:= TSay():New(15,45,{||"Loja"},oPaneRTop,,,,,,.T.,,,200,20)
	oTGetRT2	:= TGet():New(25,45,{||aRegistro[nLo]},oPaneRTop,05,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	oSayRT3		:= TSay():New(15,58,{||"Nome"},oPaneRTop,,,,,,.T.,,,200,20)
	oTGetRT3	:= TGet():New(25,58,{||aRegistro[nNo]},oPaneRTop,177,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	oSayRT4		:= TSay():New(40,15,{||"Vendedor"},oPaneRTop,,,,,,.T.,,,200,20)
	oTGetRT4	:= TGet():New(50,15,{||aRegistro[nVe]},oPaneRTop,035,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	oSayRT5		:= TSay():New(40,45,{||"Nome"},oPaneRTop,,,,,,.T.,,,200,20)
	oTGetRT5	:= TGet():New(50,45,{||Posicione("SA3",1,xFilial("SA3")+aRegistro[nVe],"A3_NOME")},oPaneRTop,190,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	
	oSayRT6		:= TSay():New(65,15,{||"Data Inclusão"},oPaneRTop,,,,,,.T.,CLR_RED,,200,20)
	oTGetRT6	:= TGet():New(75,15,{||SToD(aRegistro[nDI])},oPaneRTop,050,008,"@D",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	oSayRT7		:= TSay():New(65,72,{||"Data Aprovação"},oPaneRTop,,,,,,.T.,CLR_RED,,200,20)
	oTGetRT7	:= TGet():New(75,72,{||SToD(aRegistro[nDA])},oPaneRTop,050,008,"@D",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	oSayRT8		:= TSay():New(65,127,{||"Data Pagamento"},oPaneRTop,,,,,,.T.,CLR_RED,,200,20)
	oTGetRT8	:= TGet():New(75,127,{||SToD(aRegistro[nDP])},oPaneRTop,050,008,"@D",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	oSayRT9		:= TSay():New(65,184,{||"Data Rejeição"},oPaneRTop,,,,,,.T.,CLR_RED,,200,20)
	oTGetRT9	:= TGet():New(75,184,{||SToD(aRegistro[nDR])},oPaneRTop,050,008,"@D",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
	
	If lEnviado .AND. RetCodUsr() $ GetMv("BF_BIG046A")
		oGrpRT2  := TGroup():New(5,250,90,395," Ações ",oPaneRTop,,,.T.)
		oTButtR1 := TButton():New(20,270,"Aprovar",oPaneRTop,{||sfAprRec(aRegistro[nId],aRegistro[nVe],aRegistro[nCl],aRegistro[nLo],(nTotRecarga + (nTotRecarga * 0.05 )),cObs),oDlgRec:End()},105,10,,,.F.,.T.,.F.,,.T.,,,.F. )
		oTButtR2 := TButton():New(35,270,"Rejeitar",oPaneRTop,{||sfRejRec(aRegistro[nId],aRegistro[nVe],aRegistro[nCl],aRegistro[nLo],cObs),oDlgRec:End()},105,10,,,.F.,.T.,.F.,,.T.,,,.F. )
	EndIf
	
	/************************************************************************************/
	/* PAINEL CENTRAL																	*/
	/************************************************************************************/
	oPaneRAll:= TPanel():New(0,0,"",oDlgRec,,.F.,.F.,,,200,200,.T.,.F.)
	oPaneRAll:Align := CONTROL_ALIGN_ALLCLIENT
	oReBrowse := TWBrowse():New(01,01,260,184,,{"Código","CPF","Nome","Valor"},{30,50,100},oPaneRAll,,,,,{||},,,,,,,.F.,,.T.,,.F.,,,)
	
	cQry := ""
	cQry += "SELECT COD_CONT, U5.U5_CPF, U5.U5_CONTAT, VALOR"
	cQry += "  FROM RECARGAWEB.RECARGA_ENVIO"
	cQry += " INNER JOIN "+ RetSqlName("SU5") +" U5 ON COD_CONT = U5.U5_CODCONT AND U5.D_E_L_E_T_ = ' '"
	cQry += " WHERE ID = "+ cValToChar(aRegistro[nId])
	cQry += "   AND COD_CLI = '"+ aRegistro[nCl] +"'"
	cQry += "   AND LOJA_CLI = '"+ aRegistro[nLo] +"'"
	cQry += "   AND COD_VEND = '"+ aRegistro[nVe] +"'"
	
	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif
	
	TCQUERY cQry NEW ALIAS "QRY"

	While QRY->(!EOF())
		aTmp := {}
		Aadd(aTmp,QRY->COD_CONT)
		Aadd(aTmp,QRY->U5_CPF)
		Aadd(aTmp,QRY->U5_CONTAT)
		Aadd(aTmp,QRY->VALOR)
		nTotRecarga += QRY->VALOR
		
		Aadd(aReBrowse,aTmp)
		
		QRY->(dbSkip())
	End
	
	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif
	
	oReBrowse:SetArray(aReBrowse)
	oReBrowse:bLine := {||{aReBrowse[oReBrowse:nAt,01],;
		aReBrowse[oReBrowse:nAt,02],;
		aReBrowse[oReBrowse:nAt,03],;
		aReBrowse[oReBrowse:nAt,04]}}
		
	oReBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	oReBrowse:Refresh()
	
	/************************************************************************************/
	/* PAINEL INFERIOR																	*/
	/************************************************************************************/
	oPaneRBot := TPanel():New(0,0,"",oDlgRec,,.F.,.F.,,,0,30,.T.,.F.)
	oPaneRBot:Align := CONTROL_ALIGN_BOTTOM
	
	If lEnviado
		oSayRB1		:= TSay():New(05,5,{||"Total Recarga"},oPaneRBot,,,,,,.T.,CLR_RED,,200,20)
		oTGetRB1	:= TGet():New(15,5,{||nTotRecarga},oPaneRBot,050,008,"@E 999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"nTotRecarga",,,,)
		oSayRB4		:= TSay():New(05,65,{||"Total c/Taxa 5%"},oPaneRBot,,,,,,.T.,CLR_RED,,200,20)
		oTGetRB4	:= TGet():New(15,65,{||(nTotRecarga+(nTotRecarga*.05))},oPaneRBot,050,008,"@E 999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
		oSayRB2		:= TSay():New(05,125,{||"Saldo Tampa"},oPaneRBot,,,,,,.T.,CLR_RED,,200,20)
		oTGetRB2	:= TGet():New(15,125,{||sfSaldoTampa(aRegistro[nCl],aRegistro[nLo])},oPaneRBot,050,008,"@E 999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.T.,.F.,,"",,,,)
		oSayRB3		:= TSay():New(05,185,{||"Observação"},oPaneRBot,,,,,,.T.,CLR_RED,,200,20)
		oTGetRB3	:= TGet():New(15,185,{|u| IIf(PCount()>0,cObs:= u,cObs)},oPaneRBot,205,008,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"cObs",,,,)
	EndIf
	
	ACTIVATE DIALOG oDlgRec CENTERED
		
Return

/*/{Protheus.doc} sfLegenda
(Function para apresentar legenda)
@author Iago Luiz Raimondi
@since 25/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfLegenda()

Private cCadastro := "Monitor RECARGAWEB"
Private aLegenda

aLegenda := {{"BR_VERMELHO","Aguard.Aprov"},;
 			 {"BR_AMARELO","Aguard.Pag"},;
 			 {"BR_VERDE","Pagamento Efetuado"},;
             {"BR_PRETO","Recarga Rejeitada"}}

BRWLEGENDA( cCadastro, "Legenda", aLegenda )
   
Return

/*/{Protheus.doc} sfAprRec
(Function aprovar recarga do vendedor)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfAprRec(nId,cVend,cCliente,cLoja,nTotal,cObs)
	
	Local	cQryUpd,cQry
	Local	cMensagem	:= ""
	Local	cMsgAux		:= ""
	Local	cEmail		:= ""
	Local	cNomeCont	:= ""
	
	If (nTotal > sfSaldoTampa(cCliente,cLoja))
		MsgAlert("Cliente não possui saldo suficiente para aprovar esta recarga!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf
	
	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+cCliente+cLoja)
		If SA1->A1_MSBLQL == "1"
			MsgAlert("O cliente está bloqueado, não será possível aprovar esta recarga!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		EndIf
	EndIf
		
	If MsgNoYes("Deseja APROVAR recarga solicitada pelo vendedor?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		
		dbSelectArea("SZA")
		RecLock("SZA",.T.)
		SZA->ZA_FILIAL 	:= xFilial("SZA")
		SZA->ZA_DOC  	:= GetSxeNum("SZA","ZA_DOC");ConfirmSX8()
		SZA->ZA_VEND	:= cVend
		SZA->ZA_PRODUTO := "PAGAMENTO"
		SZA->ZA_DATA 	:= dDataBase
		SZA->ZA_CLIENTE := cCliente
		SZA->ZA_LOJA 	:= cLoja
		SZA->ZA_QTDORI 	:= 0
		SZA->ZA_VALOR  	:= nTotal * (-1)
		SZA->ZA_OBSERV 	:= "APROVADO PAG.VEND: "+SubStr(AllTrim(cObs),1,( Len(CriaVar("ZA_OBSERV"))- 20 ))
		SZA->ZA_TIPOMOV := "D"
		SZA->ZA_ORIGEM  := "V"
		SZA->ZA_REFEREN := "T"
		MsUnLock()
		
		cQryUpd := ""
		cQryUpd += " UPDATE RECARGAWEB.RECARGA_ENVIO"
		cQryUpd += "    SET STATUS = 2,"
		cQryUpd += "        USER_APR = '"+ RetCodUsr() +"-"+ Alltrim(cUserName) +"',"
		cQryUpd += "    	DATA_APR = SYSDATE,"
		cQryUpd += "    	RECNO_SZA = "+ cValToChar(SZA->(RECNO())) +","
		cQryUpd += "    	OBS = '"+ AllTrim(cObs) +"'"
		cQryUpd += "  WHERE STATUS = '1'"
		cQryUpd += "    AND ID = "+cValToChar(nId)
		cQryUpd += "    AND COD_VEND = '"+ cVend +"'"
		cQryUpd += "    AND COD_CLI = '"+ cCliente +"'"
		cQryUpd += "    AND LOJA_CLI = '"+ AllTrim(cLoja) +"'"
	
		Begin Transaction
			TCSQLExec(cQryUpd)
		End Transaction
		
	
		cQry := "SELECT C.U5_CPF,C.U5_CONTAT,A.VALOR,A.OBS " 
		cQry += "  FROM RECARGAWEB.RECARGA_ENVIO A, " + RetSqlName("AC8") + " B, " + RetSqlName("SU5") + " C "
		cQry += "  WHERE A.STATUS IN('3','2') "
		cQry += "    AND A.ID = "+cValToChar(nId)
		cQry += "    AND A.COD_VEND = '"+ cVend +"'"
		cQry += "    AND A.COD_CLI = '"+ cCliente +"'"
		cQry += "    AND A.LOJA_CLI = '"+ AllTrim(cLoja) +"'"
		cQry += "    AND C.D_E_L_E_T_ = ' ' "
		cQry += "    AND C.U5_CODCONT = A.COD_CONT "
		cQry += "    AND C.U5_FILIAL = '" + xFilial("SU5") + "' "
		cQry += "    AND B.D_E_L_E_T_ = ' ' "
		cQry += "    AND B.AC8_ENTIDA = 'SA1' "
		cQry += "    AND B.AC8_CODENT = A.COD_CLI || A.LOJA_CLI "
		cQry += "    AND B.AC8_CODCON = COD_CONT "  
		cQry += "    AND B.AC8_FILIAL = '" + xFilial("AC8") + "' "
  
		TcQuery cQry New Alias "QRCONT"
		
		While QRCONT->(!EOF())
			cMsgAux 	+= Transform(QRCONT->U5_CPF,"@R XXX.XXX.XXX-XX") + " - " 
			cMsgAux		+= QRCONT->U5_CONTAT 
			cMsgAux		+= " R$ " + Alltrim( Transform(QRCONT->VALOR,"@E 999,999.99"))
			//cMsgAux 	+= " Obs:" + Alltrim(QRCONT->OBS ) + CRLF 
			QRCONT->(dbSkip())
		EndDo
		QRCONT->(DbCloseArea())
		
		
		// Chamado 22.980 - Enviar Alerta 
		cEmail += AllTrim(Posicione("SA3",1,xFilial("SA3")+cVend,"A3_MENS1")) // A3_MENS1 contém o email do Supervisor 
		
		cMensagem += "Aprovada Recarga "+cValToChar(nId)+" do cliente "+cCliente+"/"+cLoja + "-" + Alltrim(SA1->A1_NOME) + CRLF 
		cMensagem += "Para o(s) Contato(s): " + CRLF
		cMensagem += cMsgAux + CRLF + CRLF 
		cMensagem += "Valor Total de R$ " + Alltrim( Transform(nTotal,"@E 999,999,999.99"))  + " consumido do saldo do cliente." + CRLF 
		cMensagem += "Solicitada via Portal do Vendedor " + cVend + "-" + Alltrim(SA3->A3_NREDUZ) 
		//cEmail	:= "ml-servicos@outlook.com"
		U_WFGERAL(cEmail,"RecargaWEB - Aprovação",cMensagem,"BFFATM30")
		
		MsgInfo("Recarga APROVADA com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		
		
	EndIf

Return

/*/{Protheus.doc} sfRejRec
(Function rejeitar recarga do vendedor)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfRejRec(nId,cVend,cCliente,cLoja,cObs)

	Local cEmail 	:= "eliane@atrialub.com.br;"
	Local cMensagem := ""
	Local cQryUpd	

	If MsgNoYes("Deseja REJEITAR recarga solicitada pelo vendedor?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

		cQryUpd := ""
		cQryUpd += " UPDATE RECARGAWEB.RECARGA_ENVIO"
		cQryUpd += "    SET STATUS = 4,"
		cQryUpd += "        USER_REJ = '"+ RetCodUsr() +"-"+ Alltrim(cUserName) +"',"
		cQryUpd += "    	DATA_REJ = SYSDATE,"
		cQryUpd += "    	OBS = '"+ AllTrim(cObs) +"'"
		cQryUpd += "  WHERE STATUS = '1'"
		cQryUpd += "    AND ID = "+cValToChar(nId)
		cQryUpd += "    AND COD_VEND = '"+ cVend +"'"
		cQryUpd += "    AND COD_CLI = '"+ cCliente +"'"
		cQryUpd += "    AND LOJA_CLI = '"+ cLoja +"'"
	
		Begin Transaction
			TCSQLExec(cQryUpd)
		End Transaction
		
		cEmail += AllTrim(Posicione("SA3",1,xFilial("SA3")+cVend,"A3_EMAIL"))
		cMensagem += "Recarga "+cValToChar(nId)+" do cliente "+cCliente+"/"+cLoja+", acaba de ser rejeitada pelo usuário "+Alltrim(cUserName)+"."
		U_WFGERAL(cEmail,"RecargaWEB - Rejeição",cMensagem,"BFFATM30")
	
		MsgInfo("Recarga REJEITADA com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

	EndIf

Return

/*/{Protheus.doc} sfSaldoTampa
(Busca e retorna saldo de tampa referente ao cliente)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfSaldoTampa(cCliente,cLoja)

	Local 	nSaldo := 0
	Local	cQry

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif
	
	cQry := ""
	cQry += "SELECT SUM(ZA.ZA_VALOR) AS TAMPA"
	cQry += "  FROM "+ RetSqlName("SZA") +" ZA"
	cQry += " WHERE ZA.D_E_L_E_T_ = ' '"
	cQry += "   AND ZA.ZA_REFEREN = 'T'"
	cQry += "   AND ZA.ZA_CLIENTE = '"+ AllTrim(cCliente) +"'"
	cQry += "   AND ZA.ZA_LOJA = '"+ AllTrim(cLoja) +"'"
	cQry += "   AND ZA.D_E_L_E_T_ = ' '"

	TCQUERY cQry NEW ALIAS "QRY"

	If QRY->(!EOF())
		nSaldo := QRY->TAMPA
	EndIf

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

Return nSaldo

/*/{Protheus.doc} sfPagar
(Gera informações para pagar e gerar excel)
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfPagar()

	Local cLocal := "c:\edi\"+StrTran(DToS(dDataBase)+cValToChar(Seconds()),".")+"_TRADECOM.xml"
	Local aPagar := {}
	Local aPergs := {}
	Local aRet 	 := {}
	Local cQry
	Local cQryUpd

	aAdd(aPergs,{1,"Data De",Ctod(Space(8)),"","","","",70,.F.})
	aAdd(aPergs,{1,"Data Até",dDataBase,"","","","",70,.F.})

	If !ParamBox(@aPergs,"Parametros ",aRet)
		MsgAlert("Operação cancelada!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	EndIf

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	cQry := ""
	cQry += "SELECT U5.U5_CPF, U5.U5_CONTAT, R.VALOR, R.OBS"
	cQry += "  FROM RECARGAWEB.RECARGA_ENVIO R"
	cQry += " INNER JOIN "+ RetSqlName("SU5") +" U5 ON U5.U5_CODCONT = R.COD_CONT"
	cQry += " WHERE R.STATUS = 2" //Status 1=Enviado,2=Aguard.Pag,3=Pago
	cQry += " AND TO_CHAR(R.DATA_INC,'YYYYMMDD') BETWEEN '"+ DtoS(MV_PAR01) +"' AND '"+ DtoS(MV_PAR02) +"'"
	TCQUERY cQry NEW ALIAS "QRY"
	
	While QRY->(!EOF())
		aTmp := {}
		Aadd(aTmp,Transform(QRY->U5_CPF,"@R XXX.XXX.XXX-XX")) // IAGO 09/05/2016
		Aadd(aTmp,QRY->U5_CONTAT)
		Aadd(aTmp,QRY->VALOR)
		Aadd(aTmp,QRY->OBS)
		Aadd(aPagar,aTmp)
		QRY->(dbSkip())
	End

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	If MsgNoYes("Confirma o pagamento/geração excel, para o período solicitado?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		If !sfGerarExcel(cLocal,aPagar)
			MsgAlert("Ocorreu algum erro na geração do arquivo Excel, processo foi abortado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		Else
			cQryUpd := ""
			cQryUpd += "UPDATE RECARGAWEB.RECARGA_ENVIO"
			cQryUpd += " SET USER_PAG = '"+ RetCodUsr() +"-"+ Alltrim(cUserName) +"',"
			cQryUpd += "     DATA_PAG = SYSDATE,"
			cQryUpd += "     STATUS = 3"
			cQryUpd += "  WHERE STATUS = '2'"
			cQryUpd += "    AND TO_CHAR(DATA_INC,'YYYYMMDD') BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DtoS(MV_PAR02) +"'"
		
			Begin Transaction
				TCSQLExec(cQryUpd)
			End Transaction
		
			
			MsgInfo("Excel gerado com sucesso! Disponível em: "+cLocal,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		EndIf
		
	EndIf

Return


/*/{Protheus.doc} sfGerarExcel
(Cria arquivo excel conforme padrão TRADECOM obtido pela Eliane )
@author Iago Luiz Raimondi
@since 01/04/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://www.atrialub.com.br/recargaweb)
/*/
Static Function sfGerarExcel(cLocal,aPagar)

	Local cXml := ""
	Local nI
	Default aPagar := {}
	Default cLocal := "c:\edi\xml_recarga.xml"

	// Modelo padrão da TRADECOM obtido pela Eliane
	cXml := '<?xml version="1.0"?>'
	cXml += Chr(13) + Chr(10) + '<?mso-application progid="Excel.Sheet"?>'
	cXml += Chr(13) + Chr(10) + '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'
	cXml += Chr(13) + Chr(10) + 'xmlns:o="urn:schemas-microsoft-com:office:office"'
	cXml += Chr(13) + Chr(10) + 'xmlns:x="urn:schemas-microsoft-com:office:excel"'
	cXml += Chr(13) + Chr(10) + 'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'
	cXml += Chr(13) + Chr(10) + 'xmlns:html="http://www.w3.org/TR/REC-html40">'
	cXml += Chr(13) + Chr(10) + '<DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'
	cXml += Chr(13) + Chr(10) + '<Author>simonesantos</Author>'
	cXml += Chr(13) + Chr(10) + '<LastAuthor>Atrialub</LastAuthor>'
	cXml += Chr(13) + Chr(10) + '<LastPrinted>2015-02-02T19:22:53Z</LastPrinted>'
	cXml += Chr(13) + Chr(10) + '<Created>2013-12-02T17:54:08Z</Created>'
	cXml += Chr(13) + Chr(10) + '<LastSaved>2016-01-04T16:38:20Z</LastSaved>'
	cXml += Chr(13) + Chr(10) + '<Version>15.00</Version>'
	cXml += Chr(13) + Chr(10) + '</DocumentProperties>'
	cXml += Chr(13) + Chr(10) + '<OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">'
	cXml += Chr(13) + Chr(10) + '<AllowPNG/>'
	cXml += Chr(13) + Chr(10) + '<Colors>'
	cXml += Chr(13) + Chr(10) + '<Color>'
	cXml += Chr(13) + Chr(10) + '<Index>47</Index>'
	cXml += Chr(13) + Chr(10) + '<RGB>#B3B3B3</RGB>'
	cXml += Chr(13) + Chr(10) + '</Color>'
	cXml += Chr(13) + Chr(10) + '</Colors>'
	cXml += Chr(13) + Chr(10) + '</OfficeDocumentSettings>'
	cXml += Chr(13) + Chr(10) + '<ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'
	cXml += Chr(13) + Chr(10) + '<WindowHeight>12435</WindowHeight>'
	cXml += Chr(13) + Chr(10) + '<WindowWidth>28800</WindowWidth>'
	cXml += Chr(13) + Chr(10) + '<WindowTopX>0</WindowTopX>'
	cXml += Chr(13) + Chr(10) + '<WindowTopY>0</WindowTopY>'
	cXml += Chr(13) + Chr(10) + '<TabRatio>108</TabRatio>'
	cXml += Chr(13) + Chr(10) + '<ActiveSheet>1</ActiveSheet>'
	cXml += Chr(13) + Chr(10) + '<FirstVisibleSheet>1</FirstVisibleSheet>'
	cXml += Chr(13) + Chr(10) + '<ProtectStructure>True</ProtectStructure>'
	cXml += Chr(13) + Chr(10) + '<ProtectWindows>False</ProtectWindows>'
	cXml += Chr(13) + Chr(10) + '</ExcelWorkbook>'
	cXml += Chr(13) + Chr(10) + '<Styles>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="Default" ss:Name="Normal">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s48" ss:Name="Moeda 12">'
	cXml += Chr(13) + Chr(10) + '<NumberFormat'
	cXml += Chr(13) + Chr(10) + 'ss:Format="_(&quot;R$ &quot;* #,##0.00_);_(&quot;R$ &quot;* \(#,##0.00\);_(&quot;R$ &quot;* &quot;-&quot;??_);_(@_)"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s51" ss:Name="Normal 11">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s53" ss:Name="Normal 13">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s54" ss:Name="Normal 2">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s55" ss:Name="Normal 2 10">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s57" ss:Name="Normal 2 8">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s58" ss:Name="Normal 2 9">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s73">'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s74">'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s75">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s76">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s77">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s78">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s79">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s80">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s81">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s82">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s83">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s84">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="\x"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s85">'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s86">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FF6600" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s87">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Right" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="0.00;0.00"/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s88">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s89">'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s90">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s91">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s92">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#B3B3B3" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s93">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s94">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Size="18" ss:Color="#FFFFFF"'
	cXml += Chr(13) + Chr(10) + 'ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s95">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Size="18" ss:Color="#FFFFFF"'
	cXml += Chr(13) + Chr(10) + 'ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="[$R$-416]\ #,##0.00;[Red]\-[$R$-416]\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '<Protection x:HideFormula="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s96">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#FFFFFF"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Color="#FFFFFF"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s97">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#B3B3B3" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s98">'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#B3B3B3" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<Protection x:HideFormula="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s99">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#0000FF" ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#B3B3B3" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="[$R$-416]\ #,##0.00;[Red]\-[$R$-416]\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '<Protection x:HideFormula="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s100">'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FF0000" ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#B3B3B3" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<Protection x:HideFormula="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s101">'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FFFFFF" ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s102">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FFFFFF" ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s103">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s104">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s105">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s106">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s107">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s108">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s109">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s110">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s111">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s112">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s113">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s114">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s115">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s116">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s117">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s118">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s119">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s120">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s121" ss:Parent="s54">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s122" ss:Parent="s54">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s123" ss:Parent="s54">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s124" ss:Parent="s54">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s125" ss:Parent="s54">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s126">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#FFFFFF"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Color="#FFFFFF"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="&quot;R$&quot;\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s127">'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Color="#FFFFFF" ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="&quot;R$&quot;\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s128">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="&quot;R$&quot;\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s129">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="&quot;R$&quot;\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s130">'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="&quot;R$&quot;\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s131">'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="&quot;R$&quot;\ #,##0.00"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s132" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s133" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s134" ss:Parent="s48">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s135" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s136" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s137" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s138">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s139">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s140">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s141">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s142">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s143">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s144">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s145">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s146">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s147" ss:Parent="s57">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s148" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s149" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s150" ss:Parent="s58">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s151" ss:Parent="s48">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s152" ss:Parent="s55">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s153" ss:Parent="s51">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s154" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s155" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s156" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s181" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s182" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="#,##0"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s183" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s184" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s185" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s186" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s187" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s188" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Interior/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s189" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="#,##0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s190" ss:Parent="s53">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s191">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s192">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Size="12" ss:Bold="1"'
	cXml += Chr(13) + Chr(10) + 'ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s193">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s194">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Protection/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s195">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="0\ ;\(0\)"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s196">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="dd\/mm\/yy;@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s197">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s199">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s200">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s201">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="000000000\-00"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s202">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s205">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Right" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s206">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#000000" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s207">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s208">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="dd\/mm\/yy;@"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s209">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#FF6600" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s210">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s211">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s212">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom" ss:WrapText="1"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s213">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Bitstream Vera Sans" x:Family="Swiss"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s214">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Right" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat/>'
	cXml += Chr(13) + Chr(10) + '<Protection ss:Protected="0"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s215">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Right" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="3"'
	cXml += Chr(13) + Chr(10) + 'ss:Color="#000000"/>'
	cXml += Chr(13) + Chr(10) + '</Borders>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s216">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Bold="1" ss:Italic="1"/>'
	cXml += Chr(13) + Chr(10) + '<Interior ss:Color="#C0C0C0" ss:Pattern="Solid"/>'
	cXml += Chr(13) + Chr(10) + '<NumberFormat ss:Format="@"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '<Style ss:ID="s218">'
	cXml += Chr(13) + Chr(10) + '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'
	cXml += Chr(13) + Chr(10) + '<Borders/>'
	cXml += Chr(13) + Chr(10) + '<Font ss:FontName="Arial" x:Family="Swiss" ss:Size="13" ss:Color="#FF0000"'
	cXml += Chr(13) + Chr(10) + 'ss:Bold="1"/>'
	cXml += Chr(13) + Chr(10) + '</Style>'
	cXml += Chr(13) + Chr(10) + '</Styles>'
	cXml += Chr(13) + Chr(10) + '<Worksheet ss:Name="Formulário">'
	cXml += Chr(13) + Chr(10) + '<Table ss:ExpandedColumnCount="16" ss:ExpandedRowCount="35" x:FullColumns="1"'
	cXml += Chr(13) + Chr(10) + 'x:FullRows="1" ss:StyleID="s73" ss:DefaultColumnWidth="48.75">'
	cXml += Chr(13) + Chr(10) + '<Column ss:Index="2" ss:StyleID="s74" ss:AutoFitWidth="0" ss:Width="6.75"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="45.75"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:Index="6" ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="50.25"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="38.25"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="39.75"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:Index="10" ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="45.75"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="12"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="39"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s73" ss:AutoFitWidth="0" ss:Width="39.75"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:Index="16" ss:StyleID="s74" ss:AutoFitWidth="0" ss:Width="7.5"/>'
	cXml += Chr(13) + Chr(10) + '<Row ss:Height="15">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeDown="32" ss:StyleID="s191"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="12" ss:StyleID="s192"><ss:Data ss:Type="String"'
	cXml += Chr(13) + Chr(10) + 'xmlns="http://www.w3.org/TR/REC-html40"><B><I>TRADE<Font html:Color="#FF0000">COM</Font><Font> COMUNICAÇÃO</Font></I></B></ss:Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeDown="33" ss:StyleID="s193"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s77">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s76"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s191"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="2" ss:StyleID="s194"><Data ss:Type="String">Código do Pedido :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="5" ss:StyleID="s195"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s78"><Data ss:Type="String">Data:</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s196"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s77">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s76"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s197"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="2" ss:StyleID="s78"><Data ss:Type="String">Razão Social :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="9" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s77">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s76"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s197"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="2" ss:StyleID="s200"><Data ss:Type="String">Inscrição no CNPJ :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="4" ss:StyleID="s201"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:StyleID="s202"><Data ss:Type="String">Insc. Estadual :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s77">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s76"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s197"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="1" ss:StyleID="s79"><Data ss:Type="String">Endereço :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="10" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s77">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s76"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:StyleID="s79"><Data ss:Type="String">Bairro:</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s79"><Data ss:Type="String">Cidade:</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s79"><Data ss:Type="String">Estado</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s81"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s79"><Data ss:Type="String">CEP :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s77">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s76"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="1" ss:StyleID="s79"><Data ss:Type="String">Telefone :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s79"><Data ss:Type="String">FAX :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="3" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s79"><Data ss:Type="String">DDD :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:StyleID="s199"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s77">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s76"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s206"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s207"><Data ss:Type="String">INFORMAÇÕES COMERCIAIS E FINANCEIRAS</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s191"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="4" ss:StyleID="s79"><Data ss:Type="String">Data de Vencimento da Nota Fiscal</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:StyleID="s208"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s79"><Data ss:Type="String">Data de Premiaca	o:</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s196"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="2" ss:StyleID="s210"><Data ss:Type="String">Tipo de Entrega :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:StyleID="s214"><Data ss:Type="String">Centralizada</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s82"><Data ss:Type="String">x</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:StyleID="s215"><Data ss:Type="String">Descentralizada</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s83"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="8" ss:StyleID="s216"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:StyleID="s205"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s84"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s85"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s86"><Data ss:Type="String">Taxa:</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s87"><Data ss:Type="String">5.0%</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="2" ss:StyleID="s209"><Data ss:Type="String">Percento</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s80"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s210"><Data ss:Type="String">Observações :</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:StyleID="s211"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s89">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s88"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:MergeAcross="12" ss:MergeDown="5" ss:StyleID="s212"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s75"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s90"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="12" ss:StyleID="s213"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="16" ss:StyleID="s91"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '</Table>'
	cXml += Chr(13) + Chr(10) + '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'
	cXml += Chr(13) + Chr(10) + '<PageSetup>'
	cXml += Chr(13) + Chr(10) + '<Header x:Margin="0.78749999999999998"'
	cXml += Chr(13) + Chr(10) + 'x:Data="&amp;C&amp;&quot;Times New Roman,Regular&quot;&amp;12&amp;A"/>'
	cXml += Chr(13) + Chr(10) + '<Footer x:Margin="0.78749999999999998"'
	cXml += Chr(13) + Chr(10) + 'x:Data="&amp;C&amp;&quot;Times New Roman,Regular&quot;&amp;12Página &amp;P"/>'
	cXml += Chr(13) + Chr(10) + '<PageMargins x:Bottom="1.0527777777777778" x:Left="0.78749999999999998"'
	cXml += Chr(13) + Chr(10) + 'x:Right="0.78749999999999998" x:Top="1.0527777777777778"/>'
	cXml += Chr(13) + Chr(10) + '</PageSetup>'
	cXml += Chr(13) + Chr(10) + '<Print>'
	cXml += Chr(13) + Chr(10) + '<ValidPrinterInfo/>'
	cXml += Chr(13) + Chr(10) + '<PaperSizeIndex>9</PaperSizeIndex>'
	cXml += Chr(13) + Chr(10) + '<HorizontalResolution>300</HorizontalResolution>'
	cXml += Chr(13) + Chr(10) + '<VerticalResolution>300</VerticalResolution>'
	cXml += Chr(13) + Chr(10) + '</Print>'
	cXml += Chr(13) + Chr(10) + '<Panes>'
	cXml += Chr(13) + Chr(10) + '<Pane>'
	cXml += Chr(13) + Chr(10) + '<Number>3</Number>'
	cXml += Chr(13) + Chr(10) + '<ActiveRow>19</ActiveRow>'
	cXml += Chr(13) + Chr(10) + '<ActiveCol>13</ActiveCol>'
	cXml += Chr(13) + Chr(10) + '</Pane>'
	cXml += Chr(13) + Chr(10) + '</Panes>'
	cXml += Chr(13) + Chr(10) + '<ProtectObjects>False</ProtectObjects>'
	cXml += Chr(13) + Chr(10) + '<ProtectScenarios>False</ProtectScenarios>'
	cXml += Chr(13) + Chr(10) + '<EnableSelection>NoSelection</EnableSelection>'
	cXml += Chr(13) + Chr(10) + '</WorksheetOptions>'
	cXml += Chr(13) + Chr(10) + '</Worksheet>'
	cXml += Chr(13) + Chr(10) + '<Worksheet ss:Name="Prêmios">'
	cXml += Chr(13) + Chr(10) + '<Table ss:ExpandedColumnCount="250" ss:ExpandedRowCount="65536"'
	cXml += Chr(13) + Chr(10) + 'x:FullColumns="1" x:FullRows="1" ss:DefaultColumnWidth="61.5">'
	cXml += Chr(13) + Chr(10) + '<Column ss:AutoFitWidth="0" ss:Width="106.5"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:AutoFitWidth="0" ss:Width="230.25"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s131" ss:AutoFitWidth="0" ss:Width="80.25"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:AutoFitWidth="0" ss:Width="153"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:StyleID="s92" ss:AutoFitWidth="0" ss:Span="31"/>'
	cXml += Chr(13) + Chr(10) + '<Column ss:Index="37" ss:StyleID="s93" ss:AutoFitWidth="0" ss:Span="213"/>'
	cXml += Chr(13) + Chr(10) + '<Row ss:Height="23.25" ss:StyleID="s97">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s94"><Data ss:Type="String">CNPJ:</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s95"><Data ss:Type="String">06.032.022/0001-10</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s126"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s96"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s97">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s98"><Data ss:Type="String">Valor da Premiacao</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s99" ss:Formula="=SUM(R[6]C[1]:R[499]C[1])"><Data'
	cXml += Chr(13) + Chr(10) + 'ss:Type="Number">1</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s126"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s96"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="31" ss:MergeDown="65534" ss:StyleID="s92"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s97">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s98"><Data ss:Type="String">Taxa Administrativa</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s99" ss:Formula="=R[-1]C*0.05"><Data ss:Type="Number">1</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s126"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s96"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s97">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s100"><Data ss:Type="String">Total da Fatura</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s99" ss:Formula="=R[-2]C+R[-1]C"><Data ss:Type="Number">1</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s126"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s96"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s97">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:MergeAcross="1" ss:MergeDown="1" ss:StyleID="s218"><Data'
	cXml += Chr(13) + Chr(10) + 'ss:Type="String">Full Card</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s126"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s96"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s97">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:Index="3" ss:StyleID="s126"/>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s96"/>'
	cXml += Chr(13) + Chr(10) + '</Row>'
	cXml += Chr(13) + Chr(10) + '<Row ss:StyleID="s97">'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s101"><Data ss:Type="String">CPF</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s101"><Data ss:Type="String">NOME</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s127"><Data ss:Type="String">VALOR</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s102"><Data ss:Type="String">OBSERVACAO</Data></Cell>'
	cXml += Chr(13) + Chr(10) + '</Row>'

	For nI := 1 To Len(aPagar)
		cXml += Chr(13) + Chr(10) + '<Row ss:AutoFitHeight="0" ss:StyleID="s97">'
		cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s154"><Data ss:Type="String">'+ aPagar[nI][1] +'</Data></Cell>'
		cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s156"><Data ss:Type="String">'+ aPagar[nI][2] +'</Data></Cell>'
		cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s134"><Data ss:Type="Number">'+ cValToChar(aPagar[nI][3]) +'</Data></Cell>'
		cXml += Chr(13) + Chr(10) + '<Cell ss:StyleID="s104"><Data ss:Type="String">'+ aPagar[nI][4] +'</Data></Cell>'
		cXml += Chr(13) + Chr(10) + '</Row>'
	Next

	cXml += Chr(13) + Chr(10) + '</Table>'
	cXml += Chr(13) + Chr(10) + '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'
	cXml += Chr(13) + Chr(10) + '<PageSetup>'
	cXml += Chr(13) + Chr(10) + '<Layout x:StartPageNumber="1"/>'
	cXml += Chr(13) + Chr(10) + '<Header x:Margin="0.78749999999999998"'
	cXml += Chr(13) + Chr(10) + 'x:Data="&amp;C&amp;&quot;Times New Roman,Regular&quot;&amp;12&amp;A"/>'
	cXml += Chr(13) + Chr(10) + '<Footer x:Margin="0.78749999999999998"'
	cXml += Chr(13) + Chr(10) + 'x:Data="&amp;C&amp;&quot;Times New Roman,Regular&quot;&amp;12Página &amp;P"/>'
	cXml += Chr(13) + Chr(10) + '<PageMargins x:Bottom="1.0527777777777778" x:Left="0.78749999999999998"'
	cXml += Chr(13) + Chr(10) + 'x:Right="0.78749999999999998" x:Top="1.0527777777777778"/>'
	cXml += Chr(13) + Chr(10) + '</PageSetup>'
	cXml += Chr(13) + Chr(10) + '<Print>'
	cXml += Chr(13) + Chr(10) + '<FitHeight>0</FitHeight>'
	cXml += Chr(13) + Chr(10) + '<ValidPrinterInfo/>'
	cXml += Chr(13) + Chr(10) + '<PaperSizeIndex>9</PaperSizeIndex>'
	cXml += Chr(13) + Chr(10) + '<Scale>80</Scale>'
	cXml += Chr(13) + Chr(10) + '<HorizontalResolution>600</HorizontalResolution>'
	cXml += Chr(13) + Chr(10) + '<VerticalResolution>300</VerticalResolution>'
	cXml += Chr(13) + Chr(10) + '</Print>'
	cXml += Chr(13) + Chr(10) + '<PageBreakZoom>60</PageBreakZoom>'
	cXml += Chr(13) + Chr(10) + '<Selected/>'
	cXml += Chr(13) + Chr(10) + '<Panes>'
	cXml += Chr(13) + Chr(10) + '<Pane>'
	cXml += Chr(13) + Chr(10) + '<Number>3</Number>'
	cXml += Chr(13) + Chr(10) + '<ActiveRow>4</ActiveRow>'
	cXml += Chr(13) + Chr(10) + '<ActiveCol>3</ActiveCol>'
	cXml += Chr(13) + Chr(10) + '</Pane>'
	cXml += Chr(13) + Chr(10) + '</Panes>'
	cXml += Chr(13) + Chr(10) + '<ProtectObjects>False</ProtectObjects>'
	cXml += Chr(13) + Chr(10) + '<ProtectScenarios>False</ProtectScenarios>'
	cXml += Chr(13) + Chr(10) + '<EnableSelection>NoSelection</EnableSelection>'
	cXml += Chr(13) + Chr(10) + '</WorksheetOptions>'
	cXml += Chr(13) + Chr(10) + '<PageBreaks xmlns="urn:schemas-microsoft-com:office:excel">'
	cXml += Chr(13) + Chr(10) + '<ColBreaks>'
	cXml += Chr(13) + Chr(10) + '<ColBreak>'
	cXml += Chr(13) + Chr(10) + '<Column>4</Column>'
	cXml += Chr(13) + Chr(10) + '</ColBreak>'
	cXml += Chr(13) + Chr(10) + '</ColBreaks>'
	cXml += Chr(13) + Chr(10) + '</PageBreaks>'
	cXml += Chr(13) + Chr(10) + '</Worksheet>'
	cXml += Chr(13) + Chr(10) + '</Workbook>'
	
Return MemoWrite(cLocal,cXml)