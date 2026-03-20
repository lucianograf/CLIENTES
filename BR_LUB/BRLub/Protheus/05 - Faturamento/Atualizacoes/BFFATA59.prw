#INCLUDE "totvs.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} BFFATA59
Rotina para cadastro e controle de Promoções / Tampinhas / Reembolsos
@type function
@version 
@author Marcelo Alberto Lauschner
@since 12/11/2020
@return return_type, return_description
/*/
User function BFFATA59()
	
Return U_BIG046() 

/*/{Protheus.doc} BIG046
(Controle de Pagamento de Promocoes )
@author Rafael Meyer
@since 15/05/06
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BIG046()
	
	Local   nI 
	local cUsrPag       := SuperGetMv( 'MV_X_PGPR',,'' )

	Private lGravar  	:= .F.
	Private cQry     	:= ""
	Private cRotina 	:= ""
	Private aHeader  	:= {}
	Private aCols    	:= {}
	Private aCapAlt  	:= {}
	Private aRotina  	:= {{"Pesquisar", "AxPesqui", 0, 1},;
		{"Visualizar", "AxVisual", 0, 2},;
		{"Incluir"   , "AxInclui", 0, 3},;
		{"Alterar"   , "AxAltera", 0, 4},;
		{"Excluit"   , "AxDeleta", 0, 5}}
	Private cRefer 		:= Space(1)
	Private cMovi  		:= Space(1)
	Private cTabT  		:= Space(3)
	Private cData  		:= Space(8)
	Private cDoc   		:= Space(9)
	Private cCod   		:= Space(15)
	Private cDesc  		:= Space(55)
	Private cObs   		:= Space(75)
	Private nVlrU  		:= 0.00
	Private nQuant 		:= 0.00
	Private nVlrTot		:= 0.00
	Private nFI			:= 0.00
	Private nVlrTam		:= 0.00
	Private nVlrOpe		:= 0.00
	Private nVlrMkt		:= 0.00
	Private oPesqd
	Private oPesq
	Private oGravar
	Private oCliente
	Private cAcli 		:= Space(6)
	Private cAloja 		:= Space(2)
	Private cAVend 		:= Space(6)
	Private cNum 		:= TamSX3("ZA_DOC")[1]
	Private	cAuxNum		:= cNum
	Private cAlojfo 	:= Space(2)
	Private cAforn 		:= Space(6)
	Private oFornec
	Private dDatavenc 	:= dDatabase+7
	Private dDataOp  	:= dDatabase-180
	Private	dDataFinal	:= dDataBase
	Private lMsHelpAuto := .F.
	Private lMsErroAuto := .F.
	Private oTotal
	Private nTotal 		:= 0
	Private	oPendTamp
	Private	oPendFI
	Private oPendMkt
	Private oSaldTamp
	Private oSaldFI
	Private oSaldMkt
	Private oCredTamp
	Private oCredFI
	Private oCredMkt
	Private oDebiTamp
	Private oDebiFI
	Private oDebiMkt
	Private nPendTamp  	:= 0
	Private nPendFI  	:= 0
	Private nPendMkt  	:= 0
	Private	nSaldTamp	:= 0
	Private	nSaldFI		:= 0
	Private	nSaldMkt	:= 0
	Private	nCredTamp	:= 0
	Private	nCredFI		:= 0
	Private	nCredMkt	:= 0
	Private	nDebiTamp	:= 0
	Private	nDebiFI		:= 0
	Private	nDebiMkt	:= 0
	Private cReferen    := ""
	Private aReferen    := {"Tampas"} //,"F&I","Market"}
	Private cTipoOp    	:= ""
	Private aTipoOp     := {"Tampas"}//{"Ambos","Tampas","F&I","Market"}
	Private cOperac    	:= ""
	Private aOperac     := {"Ambos","Credito","Debito"}
	Private cNome   	:= ""
	
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	// Verificar se o usuário tem permissão para realizar manutenções dos pagamentos das promoções                                         
	if RetCodUsr() $ cUsrPag .or. FWIsAdmin()
		lGravar := .T.
	else
		MsgInfo("Você tem permissão apenas para simulação!","Informação!")
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Exibe tela inicial                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//Aadd(aHeadXml	,{ 	GetSx3Cache(cCampo,"X3_CAMPO")	,GetSx3Cache(cCampo,"X3_PICTURE")	,GetSx3Cache(cCampo,"X3_TAMANHO")	,GetSx3Cache(cCampo,"X3_DECIMAL")	,SX3->X3_VALID	,GetSx3Cache(cCampo,"X3_USADO"),GetSx3Cache(cCampo,"X3_TIPO")	,GetSx3Cache(cCampo,"X3_F3")	,GetSx3Cache(cCampo,"X3_CONTEXT"),GetSx3Cache(cCampo,"X3_CBOX"),SX3->X3_RELACAO })
	cCampo1 := "ZA_REFEREN"
	/*01*/AADD(aHeader,{GetSx3Cache(cCampo1,"X3_TITULO"),GetSx3Cache(cCampo1,"X3_CAMPO"),GetSx3Cache(cCampo1,"X3_PICTURE"),GetSx3Cache(cCampo1,"X3_TAMANHO"),GetSx3Cache(cCampo1,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo1,"X3_USADO"),GetSx3Cache(cCampo1,"X3_TIPO"),GetSx3Cache(cCampo1,"X3_F3"),GetSx3Cache(cCampo1,"X3_CONTEXT"),GetSx3Cache(cCampo1,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	cCampo2 := "ZA_TIPOMOV"
	/*02*/AADD(aHeader,{ GetSx3Cache(cCampo2,"X3_TITULO"),GetSx3Cache(cCampo2,"X3_CAMPO"),GetSx3Cache(cCampo2,"X3_PICTURE"),GetSx3Cache(cCampo2,"X3_TAMANHO"),GetSx3Cache(cCampo2,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo2,"X3_USADO"),GetSx3Cache(cCampo2,"X3_TIPO"),GetSx3Cache(cCampo2,"X3_F3"),GetSx3Cache(cCampo2,"X3_CONTEXT"),GetSx3Cache(cCampo2,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	cCampo3 := "ZA_VALUNIT"
	/*03*/AADD(aHeader,{ GetSx3Cache(cCampo3,"X3_TITULO"),GetSx3Cache(cCampo3,"X3_CAMPO"),GetSx3Cache(cCampo3,"X3_PICTURE"),GetSx3Cache(cCampo3,"X3_TAMANHO"),GetSx3Cache(cCampo3,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo3,"X3_USADO"),GetSx3Cache(cCampo3,"X3_TIPO"),GetSx3Cache(cCampo3,"X3_F3"),GetSx3Cache(cCampo3,"X3_CONTEXT"),GetSx3Cache(cCampo3,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	cCampo4 := "ZA_QTDORI"
	/*04*/AADD(aHeader,{ GetSx3Cache(cCampo4,"X3_TITULO"),GetSx3Cache(cCampo4,"X3_CAMPO"),GetSx3Cache(cCampo4,"X3_PICTURE"),GetSx3Cache(cCampo4,"X3_TAMANHO"),GetSx3Cache(cCampo4,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo4,"X3_USADO"),GetSx3Cache(cCampo4,"X3_TIPO"),GetSx3Cache(cCampo4,"X3_F3"),GetSx3Cache(cCampo4,"X3_CONTEXT"),GetSx3Cache(cCampo4,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	/*05*/AADD(aHeader,{ "Vlr Tot"       		, "nVlrTot"  	, "@E 999,999.99"      	, 08,  2,"", "û", "N", ""})
	/*06*/AADD(aHeader,{ "%F&I"    		  	 	, "nFI"     	, "@E 999,999.99"      	, 08,  2,"", "û", "N", ""})
	/*07*/AADD(aHeader,{ "Vlr Tamp"       		, "nVlrTam"  	, "@E 999,999.99"      	, 08,  2,"", "û", "N", ""})
	/*08*/AADD(aHeader,{ "% Mkt" 	      		, "nVlrMkt"  	, "@E 999,999.99"      	, 08,  2,"", "û", "N", ""})
	/*09*/AADD(aHeader,{ "Vlr Opera"      	 	, "nVlrOpe"  	, "@E 999,999.99"      	, 08,  2,"", "û", "N", ""})
	cCampo5 := "ZA_TABTAMP"
	/*10*/AADD(aHeader,{ GetSx3Cache(cCampo5,"X3_TITULO"),GetSx3Cache(cCampo5,"X3_CAMPO"),GetSx3Cache(cCampo5,"X3_PICTURE"),GetSx3Cache(cCampo5,"X3_TAMANHO"),GetSx3Cache(cCampo5,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo5,"X3_USADO"),GetSx3Cache(cCampo5,"X3_TIPO"),GetSx3Cache(cCampo5,"X3_F3"),GetSx3Cache(cCampo5,"X3_CONTEXT"),GetSx3Cache(cCampo5,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	cCampo6 := "ZA_DATA"
	/*11*/AADD(aHeader,{ GetSx3Cache(cCampo6,"X3_TITULO"),GetSx3Cache(cCampo6,"X3_CAMPO"),GetSx3Cache(cCampo6,"X3_PICTURE"),GetSx3Cache(cCampo6,"X3_TAMANHO"),GetSx3Cache(cCampo6,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo6,"X3_USADO"),GetSx3Cache(cCampo6,"X3_TIPO"),GetSx3Cache(cCampo6,"X3_F3"),GetSx3Cache(cCampo6,"X3_CONTEXT"),GetSx3Cache(cCampo6,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	cCampo7 := "ZA_DOC"
	/*12*/AADD(aHeader,{ GetSx3Cache(cCampo7,"X3_TITULO"),GetSx3Cache(cCampo7,"X3_CAMPO"),GetSx3Cache(cCampo7,"X3_PICTURE"),GetSx3Cache(cCampo7,"X3_TAMANHO"),GetSx3Cache(cCampo7,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo7,"X3_USADO"),GetSx3Cache(cCampo7,"X3_TIPO"),GetSx3Cache(cCampo7,"X3_F3"),GetSx3Cache(cCampo7,"X3_CONTEXT"),GetSx3Cache(cCampo7,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	cCampo8 := "ZA_PRODUTO"
	/*13*/AADD(aHeader,{ GetSx3Cache(cCampo8,"X3_TITULO"),GetSx3Cache(cCampo8,"X3_CAMPO"),GetSx3Cache(cCampo8,"X3_PICTURE"),GetSx3Cache(cCampo8,"X3_TAMANHO"),GetSx3Cache(cCampo8,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo8,"X3_USADO"),GetSx3Cache(cCampo8,"X3_TIPO"),GetSx3Cache(cCampo8,"X3_F3"),GetSx3Cache(cCampo8,"X3_CONTEXT"),GetSx3Cache(cCampo8,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	/*14*/AADD(aHeader,{ "Descricao"      		, "cDesc"     , "@!"     			, 55,  0,"", "û", "C", ""})	//DbSeek("ZA_OBSERV")
	cCampo9 := "ZA_OBSERV"
	/*15*/AADD(aHeader,{ GetSx3Cache(cCampo9,"X3_TITULO"),GetSx3Cache(cCampo9,"X3_CAMPO"),GetSx3Cache(cCampo9,"X3_PICTURE"),GetSx3Cache(cCampo9,"X3_TAMANHO"),GetSx3Cache(cCampo9,"X3_DECIMAL"),"AllwaysTrue()"/*SX3->X3_VALID*/,GetSx3Cache(cCampo9,"X3_USADO"),GetSx3Cache(cCampo9,"X3_TIPO"),GetSx3Cache(cCampo9,"X3_F3"),GetSx3Cache(cCampo9,"X3_CONTEXT"),GetSx3Cache(cCampo9,"X3_CBOX"),""/*SX3->X3_RELACAO*/ })
	/*16*/AADD(aHeader,{ "Recno"     			, " "      	, ""                	, 10,  0,"", "û", "N", ""})
	
	
	aCols	:= {Array(Len(aHeader)+1)}
	aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	
	For nI := 1 To Len(aHeader)
		If Alltrim(aHeader[nI][8]) == "C"
			aCols[Len(aCols)][nI] := Space(aHeader[nI][4])
		ElseIf Alltrim(aHeader[nI][8]) == "N"
			aCols[Len(aCols)][nI] := 0
		Else
			aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
		Endif
	Next
	
	Define MsDialog oDlgPromo From 0,0 TO 600 , 1010  Of oMainWnd Pixel Title OemToAnsi("Pagamento de Promoções")
	oDlgPromo:lMaximized := .T.
	
	Private oPaneMenu := TPanel():New(0,0,"",oDlgPromo,,.F.,.F.,,,75,40,.T.,.F.)
	oPaneMenu:align := CONTROL_ALIGN_TOP
	
	Private oPaneDados := TPanel():New(0,0,"",oDlgPromo,,.F.,.F.,,,200,200,.T.,.F.)
	oPaneDados:align := CONTROL_ALIGN_ALLCLIENT
	
	// Cria painel
	Private oFolder := TFolder():New(001,001,{"Totais","Pagamentos"},{"HEADER"},oDlgPromo,,,, .T., .F.,200,100)
	oFolder:Align := CONTROL_ALIGN_BOTTOM
	
	
	@ 011,010 Say "Informe Cliente" of oPaneMenu Pixel
	@ 010,052 MsGet cAcli F3 "SA1" Picture "@!" Valid sfVldCli(.T.) Size 30,10 of oPaneMenu Pixel
	
	@ 011,087 Say "Loja" of oPaneMenu Pixel
	@ 010,100 MsGet oCliente Var cAloja Valid sfVldCli(.F.) Size 15,10 of oPaneMenu Pixel
	oCliente:bValid := {|| Processa({|| sfBuscaCli()},"Buscando Cliente") }
	
	@ 011,125 Say "Nome" of oPaneMenu Pixel
	@ 010,150 MsGet oNomCli Var cNome Picture "@!" Size 180,10 When .F. of oPaneMenu Pixel
	
	@ 011,340 Say "Vendedor"  of oPaneMenu Pixel
	@ 010,375 MsGet cAVend F3 "SA3Z8" Picture "@!" Valid VldVend(.T.) Size 30,10 of oPaneMenu Pixel  When !Empty(cAcli)
	
	@ 026,010 Say "Tipo de Oper" color 255 of oPaneMenu Pixel
	@ 025,052 MsCombobox cTipoOp Items aTipoOp Size 40,10 of oPaneMenu Pixel
	
	@ 026,125 Say "Cred/Deb" color 255 of oPaneMenu Pixel
	@ 025,150 MsCombobox cOperac Items aOperac Size 40,10 of oPaneMenu Pixel
	
	@ 026,195 Say "Desde a Data" color 255 of oPaneMenu Pixel
	@ 025,235 MsGet dDataOp Size 40,10 of oPaneMenu Pixel
	
	@ 026,280 Say "Até a Data" color 255 of oPaneMenu Pixel
	@ 025,320 MsGet dDataFinal Size 40,10 Valid sfVldDtFim() of oPaneMenu Pixel
	
	@ 025,375 BUTTON "Processar" Size 40,10 ACTION Processa({|| Promo()},"Processando Promocoes") of oPaneMenu Pixel
	
	oItems := MsGetDados():New(040,005,240,505,4,,,"+cCod",.F.,,7,.F.,Len(aCols),"AllwaysFalse()",,,,oPaneDados,.F.)
	oItems:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	@ 005,330 Button "Exporta Excel" size 50,10 action stExporta() of oFolder:aDialogs[1] Pixel
	
	@ 006,005 Say "Saldo Ant.Tampas" of oFolder:aDialogs[1] Pixel
	@ 005,060 MsGet oSaldTamp Var nSaldTamp Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 006,110 Say "Saldo Ant. F&I" of oFolder:aDialogs[1] Pixel
	@ 005,165 MsGet oSaldFI Var nSaldFI Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 006,215 Say "Saldo Ant. Market" of oFolder:aDialogs[1] Pixel
	@ 005,270 MsGet oSaldMkt Var nSaldMkt Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 018,005 Say "Crédito Tampas" of oFolder:aDialogs[1] Pixel
	@ 017,060 MsGet oCredTamp Var nCredTamp Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 018,110 Say "Crédito F&I" of oFolder:aDialogs[1] Pixel
	@ 017,165 MsGet oCredFi Var nCredFI Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 018,215 Say "Crédito Market" of oFolder:aDialogs[1] Pixel
	@ 017,270 MsGet oCredMkt VAr nCredMkt Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 030,005 Say "Débito Tampas" of oFolder:aDialogs[1] Pixel
	@ 029,060 MsGet oDebiTamp Var nDebiTamp Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 030,110 Say "Débito F&I" of oFolder:aDialogs[1] Pixel
	@ 029,165 MsGet oDebiFI Var nDebiFI Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 030,215 Say "Débito Market" of oFolder:aDialogs[1] Pixel
	@ 029,270 MsGet oDebiMkt Var nDebiMkt Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 042,005 Say "Saldo Atual Tampas" of oFolder:aDialogs[1] Pixel
	@ 041,060 MsGet oPendTamp Var nPendTamp Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 042,110 Say "Saldo Atual F&I" of oFolder:aDialogs[1] Pixel
	@ 041,165 MsGet oPendFI Var nPendFI Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	@ 042,215 Say "Saldo Atual Market" of oFolder:aDialogs[1] Pixel
	@ 041,270 MsGet oPendMkt Var nPendMkt Size 40,10 Picture "@E 999,999.99" When .F. of oFolder:aDialogs[1] Pixel
	
	
	If __cUserId $ GetMv("BF_BIG046A")
		@ 050,010 Say "Autorização"  //of oDlg1 pixel
		
		cNum	:=GetSxeNum("SZA","ZA_DOC")
		DbSelectArea("SZA")
		DbSetOrder(1)
		If DbSeek(xFilial("SZA") + cNum )
			While .T.
				ConfirmSX8()
				cNum	:=	GetSxeNum("SZA","ZA_DOC")
				If !DbSeek(xFilial("SZA") + cNum )
					Exit
				Endif
			EndDo
		Endif
		
		@ 006,005 Say "Núm.Seq."  of oFolder:aDialogs[2] Pixel
		@ 005,050 Get cNum Size 30,10 of oFolder:aDialogs[2] Pixel When .F.
		
		@ 006,095 Say "Observação"  of oFolder:aDialogs[2] Pixel
		@ 005,140 Get cObs Size 180,10 of oFolder:aDialogs[2] Pixel
		
		@ 018,005 Say "Tipo da Baixa" color 255 of oFolder:aDialogs[2] Pixel
		@ 017,050 Combobox cReferen Items aReferen Size 40,10 of oFolder:aDialogs[2] Pixel
		
		@ 018,095 Say "Valor a Pagar" of oFolder:aDialogs[2] Pixel
		@ 017,140 Get nTotal Size 40,10 Picture "@E 999,999.99" Valid sfVldPagar() of oFolder:aDialogs[2] Pixel
		
		@ 017,200 BUTTON "Gerar Pagamento" Size 90,10 ACTION (Processa({|| sfGravar()},"Gerando Pagamento")) of oFolder:aDialogs[2] Pixel When lGravar
		
		@ 030,200 BUTTON "Reimprimir Pagamento" Size 90,10 Action sfReimprimir() of oFolder:aDialogs[2] Pixel When lGravar
	EndIf
	
	@ 005,390 BUTTON "Sair"   Size 50,10 ACTION oDlgPromo:End() of oFolder:aDialogs[1] Pixel
	
	Activate Dialog oDlgPromo Centered
	
	ConfirmSX8()
	
	
Return


/*/{Protheus.doc} sfVldCli
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@param lCliente, ${param_type}, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldCli(lCliente)
	
	If lCliente
		cAloja := Iif(SA1->A1_COD == cAcli,SA1->A1_LOJA,Posicione("SA1",1,xFilial("SA1") + cAcli,"A1_LOJA"))
		oCliente:Refresh()
	Endif
	
Return ExistCpo("SA1",cAcli+cAloja,1,"Não existe Cliente com este Código!")


/*/{Protheus.doc} sfBuscaCli
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfBuscaCli()
	
	dbselectarea("SA1")
	Dbsetorder(1)
	Dbseek(xFilial("SA1")+ cAcli + cAloja )
	
	cNome 	:= SA1->A1_NOME
	cAVend 	:= Iif(Empty(SA1->A1_SATIV3),SA1->A1_VEND,SA1->A1_VEND3)
	oNomCli:Refresh()
	
Return

/*/{Protheus.doc} VldVend
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function VldVend()
	
	If !Empty(cAVend)
		DbSelectArea("SA3")
		DbSetOrder(1)
		If !DbSeek(xFilial("SA3")+cAVend)
			MsgAlert("Não existe Vendedor com este código!","Registro inexistente!")
			Return .F.
		Endif
		Return .T.
		//Return ExistCpo("SA3",cAVend,1,"Não existe Vendedor com este Código!")
	Endif
	
Return .T.


/*/{Protheus.doc} sfVldPagar
(long_description)
@author MarceloLauschner
@since 23/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVldPagar()
	
	Local	lRet	:= .T.
	
	If Substr(cReferen,1,1) == "F"
		If nTotal > nPendFI
			MsgAlert("O valor informado R$" + Transform(nTotal,"@E 999,999.99") +" para pagamento de F&I é maior que o saldo acumulado de R$ " + Transform(nPendFI,"@E 999,999.99") +". Corrija o valor para continuar!")
			lRet	:= .F.
		Endif
	ElseIf Substr(cReferen,1,1) == "M"
		If nTotal > nPendMkt
			MsgAlert("O valor informado R$" + Transform(nTotal,"@E 999,999.99") +" para pagamento de Verba de Marketing é maior que o saldo acumulado de R$ " + Transform(nPendMkt,"@E 999,999.99") +". Corrija o valor para continuar!")
			lRet	:= .F.
		Endif
	ElseIf Substr(cREferen,1,1) == "T"
		If nTotal > nPendTamp
			MsgAlert("O valor informado R$" + Transform(nTotal,"@E 999,999.99") +" para pagamento de Tampinhas é maior que o saldo acumulado de R$ " + Transform(nPendTamp,"@E 999,999.99") +". Corrija o valor para continuar!")
			lRet	:= .F.
		Endif
	Endif
	
Return lRet

/*/{Protheus.doc} sfVldDtFim
Função para validar data final 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 13/11/2020
@return return_type, return_description
/*/
Static Function sfVldDtFim()
	
	Local	lRet	:= .T.
	
	If dDataFinal < dDataOp
		MsgInfo("Não é permitido informar data menor que a data inicial!","Data incorreta!")
		lRet	:= .F.
	Endif
	
Return lRet

/*/{Protheus.doc} Promo
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function Promo()
	
	Local nReg  	:= 0
	Local nI 		:= 0
	nPendTamp 		:= 0
	nPendFI   		:= 0
	nPendMkt  		:= 0
	nSaldTamp		:= 0
	nSaldFI			:= 0
	nSaldMkt		:= 0
	nCredTamp		:= 0
	nCredFI			:= 0
	nCredMkt		:= 0
	nDebiTamp		:= 0
	nDebiFI			:= 0
	nDebiMkt		:= 0
	n				:= 1
	
	If Empty(cACli)
		Alert("Falta Selecionar o Cliente!!")
		Return
	Endif
	
	If Empty(cnUM)
		Alert("Falta Numero de Autorização!!")
		Return
	Endif
	
	If Empty(cnUM)
		Alert("Falta Especificar Tipo de Reembolso!!")
		Return
	Endif
	
	IncProc("Calculando valores...")
	
	aCols := {}
	
	cQre := ""
	cQre += " SELECT ZA_REFEREN REFERENCIA, "
	cQre += "        ZA_TIPOMOV MOVIMENTO, "
	cQre += "        ZA_TABTAMP TABELA, "
	cQre += "        ZA_DATA EMISSAO, "
	cQre += "        ZA_DOC DOCUMENTO, "
	cQre += "        ZA_PRODUTO CODPRO, "
	cQre += "        B1_DESC DESCRICAO, "
	cQre += "        ZA_OBSERV OBSERVACAO, "
	cQre += "        D2_PRCVEN VALUNIT, "
	cQre += "        D2_QUANT QUANTFAT, "
	cQre += "        D2_TOTAL TOTALFAT, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'F' THEN "
	cQre += "           Round(ZA_VALOR / D2_TOTAL *100,0) "
	cQre += "          ELSE "
	cQre += "           0 "
	cQre += "        END FI, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'T' THEN "
	cQre += "           (ZA_VALOR / D2_QUANT) "
	cQre += "          ELSE "
	cQre += "           0 "
	cQre += "        END VALTAMP, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'M' THEN "
	cQre += "            (ZA_VALOR / D2_TOTAL * 100 )"
	cQre += "          ELSE "
	cQre += "           0"
	cQre += "        END VALMKT,"
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'T' THEN "
	cQre += "           ZA_VALOR "
	cQre += "          WHEN ZA_REFEREN = 'F' THEN "
	cQre += "           ZA_VALOR "
	cQre += "          ELSE "
	cQre += "           ZA_VALOR "
	cQre += "        END VALOPERA ,"
	cQre += "        SZA.R_E_C_N_O_ ZARECNO "
	cQre += "   FROM " + RetSqlName("SZA") + " SZA, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SD2") + " SD2 "
	cQre += "  WHERE SB1.D_E_L_E_T_ = ' ' "
	cQre += "    AND SB1.B1_COD = SD2.D2_COD "
	cQre += "    AND SB1.B1_FILIAL = SD2.D2_FILIAL "
	cQre += "    AND SD2.D_E_L_E_T_ = ' ' "
	cQre += "    AND SD2.D2_ITEM = SZA.ZA_ITEM "
	cQre += "    AND SD2.D2_COD = SZA.ZA_PRODUTO "
	cQre += "    AND SD2.D2_LOJA = SZA.ZA_LOJA "
	cQre += "    AND SD2.D2_CLIENTE = SZA.ZA_CLIENTE "
	cQre += "    AND SD2.D2_DOC = SZA.ZA_DOC "
	cQre += "    AND SD2.D2_SERIE IN ('1', '2', '3') "
	cQre += "    AND SD2.D2_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQre += "    AND SZA.ZA_PRODUTO NOT IN (' ', 'PAGAMENTO') "
	IF  (SubStr(cOperac,1,1) $ "A|C")
		cQre += "    AND ZA_TIPOMOV = 'C' "
	Else
		cQre += "    AND ZA_TIPOMOV = 'X' "
	Endif
	cQre += "    AND SZA.D_E_L_E_T_ = ' ' "
	IF  !(SubStr(cTipoOp,1,1) $ "A")
		cQre += "    AND ZA_REFEREN = '" + SubStr(cTipoOp,1,1) +"' "
	EndIf
	cQre += "    AND SZA.ZA_DATA >= '" + DTOS(dDataOp) +"' "
	cQre += "    AND SZA.ZA_DATA <= '" + DTOS(dDataFinal)+ "' "
	cQre += "    AND SZA.ZA_LOJA = '" + cAloja +"' "
	cQre += "    AND SZA.ZA_CLIENTE = '" + cAcli + "' "
	cQre += "    AND SZA.ZA_FILIAL = '"+xFilial("SZA") + "' "
	cQre += " UNION ALL "
	cQre += " SELECT ZA_REFEREN REFERENCIA, "
	cQre += "        ZA_TIPOMOV MOVIMENTO, "
	cQre += "        ZA_TABTAMP TABELA, "
	cQre += "        ZA_DATA EMISSAO, "
	cQre += "        ZA_DOC DOCUMENTO, "
	cQre += "        ZA_PRODUTO CODPRO, "
	cQre += "        B1_DESC DESCRICAO, "
	cQre += "        ZA_OBSERV OBSERVACAO, "
	cQre += "        D1_VUNIT VALUNIT, "
	cQre += "        D1_QUANT QUANTFAT, "
	cQre += "        D1_TOTAL TOTALFAT, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'F' THEN "
	cQre += "           Round(ZA_VALOR / D1_TOTAL *100,0) "
	cQre += "          ELSE "
	cQre += "           0  "
	cQre += "        END FI, "
	cQre += "        CASE  "
	cQre += "          WHEN ZA_REFEREN = 'T' THEN "
	cQre += "           (ZA_VALOR / D1_QUANT) "
	cQre += "          ELSE "
	cQre += "           0 "
	cQre += "        END VALTAMP, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'M' THEN "
	cQre += "            (ZA_VALOR / D1_TOTAL * 100 ) "
	cQre += "          ELSE "
	cQre += "           0"
	cQre += "        END VALMKT,"
	cQre += "        ZA_VALOR VALOPERA, "
	cQre += "        SZA.R_E_C_N_O_ ZARECNO "
	cQre += "   FROM " + RetSqlName("SZA") + " SZA, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SD1") + " SD1 "
	cQre += "  WHERE SB1.D_E_L_E_T_ = ' ' "
	cQre += "    AND SB1.B1_COD = SD1.D1_COD "
	cQre += "    AND SB1.B1_FILIAL = SD1.D1_FILIAL "
	cQre += "    AND SD1.D_E_L_E_T_ = ' ' "
	cQre += "    AND SD1.D1_ITEM = SZA.ZA_ITEM "
	cQre += "    AND SD1.D1_COD = SZA.ZA_PRODUTO "
	cQre += "    AND SD1.D1_LOJA = SZA.ZA_LOJA "
	cQre += "    AND SD1.D1_FORNECE = SZA.ZA_CLIENTE "
	cQre += "    AND SD1.D1_DOC = SZA.ZA_DOC "
	cQre += "    AND SD1.D1_SERIE BETWEEN '   ' AND 'ZZZ' "
	cQre += "    AND SD1.D1_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQre += "    AND SZA.ZA_PRODUTO NOT IN (' ', 'PAGAMENTO') "
	IF  (SubStr(cOperac,1,1) $ "A|D")
		cQre += "    AND ZA_TIPOMOV = 'D' "
	Else
		cQre += "    AND ZA_TIPOMOV = 'X' "
	Endif
	cQre += "    AND SZA.D_E_L_E_T_ = ' ' "
	IF  !(SubStr(cTipoOp,1,1) $ "A")
		cQre += "    AND ZA_REFEREN = '" + SubStr(cTipoOp,1,1) +"' "
	EndIf
	cQre += "    AND SZA.ZA_DATA >= '" + DTOS(dDataOp) +"' "
	cQre += "    AND SZA.ZA_DATA <= '" + DTOS(dDataFinal)+ "' "
	cQre += "    AND SZA.ZA_LOJA = '" + cAloja +"' "
	cQre += "    AND SZA.ZA_CLIENTE = '" + cAcli + "' "
	cQre += "    AND SZA.ZA_FILIAL = '"+xFilial("SZA") + "' "
	cQre += " UNION ALL "
	cQre += " SELECT ZA_REFEREN REFERENCIA, "
	cQre += "        ZA_TIPOMOV MOVIMENTO, "
	cQre += "        ZA_TABTAMP TABELA, "
	cQre += "        ZA_DATA EMISSAO, "
	cQre += "        ZA_DOC DOCUMENTO, "
	cQre += "        ZA_PRODUTO CODPRO, "
	cQre += "        ' ' DESCRICAO, "
	cQre += "        ZA_OBSERV OBSERVACAO, "
	cQre += "        0 VALUNIT, "
	cQre += "        0 QUANTFAT, "
	cQre += "        0 TOTALFAT, "
	cQre += "        0 FI, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'T' THEN "
	cQre += "           ZA_VALUNIT "
	cQre += "          ELSE "
	cQre += "           0 "
	cQre += "        END VALTAMP, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'M' THEN "
	cQre += "            ZA_VALUNIT "
	cQre += "          ELSE "
	cQre += "           0"
	cQre += "        END VALMKT,"
	cQre += "        ZA_VALOR VALOPERA,"
	cQre += "        SZA.R_E_C_N_O_ ZARECNO "
	cQre += "   FROM " + RetSqlName("SZA") + " SZA "
	cQre += "  WHERE SZA.ZA_PRODUTO IN (' ', 'PAGAMENTO') "
	IF  (SubStr(cOperac,1,1) $ "A|C")
		cQre += "    AND ZA_TIPOMOV = 'C' "
	Else
		cQre += "    AND ZA_TIPOMOV = 'X' "
	Endif
	cQre += "    AND SZA.D_E_L_E_T_ = ' ' "
	IF  !(SubStr(cTipoOp,1,1) $ "A")
		cQre += "    AND ZA_REFEREN = '" + SubStr(cTipoOp,1,1) +"' "
	EndIf
	cQre += "    AND SZA.ZA_DATA >= '" + DTOS(dDataOp) +"' "
	cQre += "    AND SZA.ZA_DATA <= '" + DTOS(dDataFinal)+ "' "
	cQre += "    AND SZA.ZA_LOJA = '" + cAloja +"' "
	cQre += "    AND SZA.ZA_CLIENTE = '" + cAcli + "' "
	cQre += "    AND SZA.ZA_FILIAL = '"+xFilial("SZA") + "' "
	cQre += " UNION ALL "
	cQre += " SELECT ZA_REFEREN REFERENCIA, "
	cQre += "        ZA_TIPOMOV MOVIMENTO, "
	cQre += "        ZA_TABTAMP TABELA, "
	cQre += "        ZA_DATA EMISSAO, "
	cQre += "        ZA_DOC DOCUMENTO, "
	cQre += "        ZA_PRODUTO CODPRO, "
	cQre += "        ' ' DESCRICAO, "
	cQre += "        ZA_OBSERV OBSERVACAO, "
	cQre += "        0 VALUNIT,  "
	cQre += "        0 QUANTFAT, "
	cQre += "        0 TOTALFAT, "
	cQre += "        0 FI, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'T' THEN "
	cQre += "           ZA_VALUNIT "
	cQre += "          ELSE  "
	cQre += "           0  "
	cQre += "        END VALTAMP, "
	cQre += "        CASE "
	cQre += "          WHEN ZA_REFEREN = 'M' THEN "
	cQre += "            ZA_VALUNIT "
	cQre += "          ELSE "
	cQre += "           0"
	cQre += "        END VALMKT,"
	cQre += "        ZA_VALOR VALOPERA, "
	cQre += "        SZA.R_E_C_N_O_ ZARECNO "
	cQre += "   FROM " + RetSqlName("SZA") + " SZA "
	cQre += "  WHERE LEFT(SZA.ZA_OBSERV,9) <> 'DEVOLUCAO' "
	IF  (SubStr(cOperac,1,1) $ "A|D")
		cQre += "    AND ZA_TIPOMOV = 'D' "
	Else
		cQre += "    AND ZA_TIPOMOV = 'X' "
	Endif
	cQre += "    AND SZA.D_E_L_E_T_ = ' ' "
	IF  !(SubStr(cTipoOp,1,1) $ "A")
		cQre += "    AND ZA_REFEREN = '" + SubStr(cTipoOp,1,1) +"' "
	EndIf
	cQre += "    AND SZA.ZA_DATA >= '" + DTOS(dDataOp) +"' "
	cQre += "    AND SZA.ZA_DATA <= '" + DTOS(dDataFinal)+ "' "
	cQre += "    AND SZA.ZA_LOJA = '" + cAloja +"' "
	cQre += "    AND SZA.ZA_CLIENTE = '" + cAcli + "' "
	cQre += "    AND SZA.ZA_FILIAL = '"+xFilial("SZA") + "' "
	cQre += " ORDER BY EMISSAO, DOCUMENTO, CODPRO ASC "
	
	TCQUERY cQre NEW ALIAS "QRE"
	
	TcSetField( "QRE", "EMISSAO", "D" )
	
	
	dbSelectArea("QRE")
	dbGoTop()
	ProcRegua(nReg)
	While !Eof()
		AADD(aCols,{QRE->REFERENCIA,;	// 	1-Referência
		QRE->MOVIMENTO,;			//	2-Movimento
		QRE->VALUNIT,;				//	3-Valor Unitário
		QRE->QUANTFAT,;				//	4-Quantidade Faturada
		QRE->TOTALFAT,;				//	5-Total Faturado
		QRE->FI,;					//	6-Valor F&I
		QRE->VALTAMP,;				// 	7-Valor Tampas
		QRE->VALMKT,;				// 	8-VAlor Marketing
		QRE->VALOPERA,;				//	9-Valor da Operação
		QRE->TABELA,;				//	10-Tabela
		QRE->EMISSAO,;				// 	11-Emissão
		QRE->DOCUMENTO,;			//  12-Documento
		QRE->CODPRO,;				// 	13-Código Produto
		QRE->DESCRICAO,;			//	14-Descrição
		QRE->OBSERVACAO,;			//	15-Observação
		QRE->ZARECNO,;				//  16-Recno da SZA
		.F.})
		
		dbSelectArea("QRE")
		dbSkip()
	End
	
	QRE->(DbCloseArea())
	
	
	If Len(aCols) <= 0
		aCols	:= {Array(Len(aHeader)+1)}
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
		
		For nI := 1 To Len(aHeader)
			If Alltrim(aHeader[nI][8]) == "C"
				aCols[Len(aCols)][nI] := Space(aHeader[nI][4])
			ElseIf Alltrim(aHeader[nI][8]) == "N"
				aCols[Len(aCols)][nI] := 0
			Else
				aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
			Endif
		Next
	
	Endif
	
	cQry := " "
	cQry += "SELECT "
	cQry += "       SUM(CASE WHEN ZA_REFEREN = 'T' THEN ZA_VALOR ELSE 0 END) AS VALTAMPAS, "
	cQry += "       SUM(CASE WHEN ZA_REFEREN = 'M' THEN ZA_VALOR ELSE 0 END) AS VALMKT, "
	cQry += "       SUM(CASE WHEN ZA_REFEREN = 'F' THEN ZA_VALOR ELSE 0 END) AS VALFI,"
	cQry += "       SUM(CASE WHEN ZA_DATA < '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'T' THEN ZA_VALOR ELSE 0 END) AS SALTAMPAS, "
	cQry += "       SUM(CASE WHEN ZA_DATA < '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'M' THEN ZA_VALOR ELSE 0 END) AS SALMKT, "
	cQry += "       SUM(CASE WHEN ZA_DATA < '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'F' THEN ZA_VALOR ELSE 0 END) AS SALFI,"
	cQry += "       SUM(CASE WHEN ZA_DATA >= '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'T' AND ZA_TIPOMOV = 'C' AND ZA_DATA <= '" + DTOS(dDataFinal)+ "' THEN ZA_VALOR ELSE 0 END) AS CRDTAMPAS, "
	cQry += "       SUM(CASE WHEN ZA_DATA >= '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'M' AND ZA_TIPOMOV = 'C' AND ZA_DATA <= '" + DTOS(dDataFinal)+ "' THEN ZA_VALOR ELSE 0 END) AS CRDMKT, "
	cQry += "       SUM(CASE WHEN ZA_DATA >= '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'F' AND ZA_TIPOMOV = 'C' AND ZA_DATA <= '" + DTOS(dDataFinal)+ "' THEN ZA_VALOR ELSE 0 END) AS CRDFI,"
	cQry += "       SUM(CASE WHEN ZA_DATA >= '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'T' AND ZA_TIPOMOV = 'D' AND ZA_DATA <= '" + DTOS(dDataFinal)+ "' THEN ZA_VALOR ELSE 0 END) AS DEBTAMPAS, "
	cQry += "       SUM(CASE WHEN ZA_DATA >= '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'M' AND ZA_TIPOMOV = 'D' AND ZA_DATA <= '" + DTOS(dDataFinal)+ "' THEN ZA_VALOR ELSE 0 END) AS DEBMKT, "
	cQry += "       SUM(CASE WHEN ZA_DATA >= '" + DTOS(dDataOp) +"' AND ZA_REFEREN = 'F' AND ZA_TIPOMOV = 'D' AND ZA_DATA <= '" + DTOS(dDataFinal)+ "' THEN ZA_VALOR ELSE 0 END) AS DEBFI,"
	cQry += "       ZA_CLIENTE,  ZA_LOJA "
	cQry += "  FROM " + RetSqlName("SZA") + "  SZA "
	cQry += " WHERE SZA.D_E_L_E_T_ =' '  "
	cQry += "   AND ZA_LOJA = '" + cAloja +"' "
	cQry += "   AND ZA_CLIENTE = '" + cAcli + "' "
	cQry += "   AND ZA_FILIAL = '"+xFilial("SZA") + "' "
	cQry += " GROUP BY  ZA_CLIENTE,  ZA_LOJA "
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	If !Eof()
		nPendTamp += QRY->VALTAMPAS
		nPendFI   += QRY->VALFI
		nPendMkt  += QRY->VALMKT
		nSaldTamp += QRY->SALTAMPAS
		nSaldFI   += QRY->SALFI
		nSaldMkt  += QRY->SALMKT
		nCredTamp += QRY->CRDTAMPAS
		nCredFI   += QRY->CRDFI
		nCredMkt  += QRY->CRDMKT
		nDebiTamp += QRY->DEBTAMPAS
		nDebiFI   += QRY->DEBFI
		nDebiMkt  += QRY->DEBMKT
	EndIf
	QRY->(dbCloseArea())
	
	//Alterado 25/09/13
	//######################
	cNum	:=GetSxeNum("SZA","ZA_DOC")
	DbSelectArea("SZA")
	DbSetOrder(1)
	If DbSeek(xFilial("SZA") + cNum )
		While .T.
			ConfirmSX8()
			cNum	:=	GetSxeNum("SZA","ZA_DOC")
			If !DbSeek(xFilial("SZA") + cNum )
				RollBackSX8()
				Exit
			Endif
		EndDo
	Endif
	
	
	cObs 		:= Space(75)
	cReferen 	:= "Tampas"
	nTotal   	:= 0
	
	
	//######################
	
	oItems:Refresh()
	oPendTamp:Refresh()
	oPendFI:Refresh()
	oPendMkt:Refresh()
	oSaldTamp:Refresh()
	oSaldFI:Refresh()
	oSaldMkt:Refresh()
	oCredTamp:Refresh()
	oCredFI:Refresh()
	oCredMkt:Refresh()
	oDebiTamp:Refresh()
	oDebiFI:Refresh()
	oDebiMkt:Refresh()
	oItems:oBrowse:SetFocus()
	
Return

/*/{Protheus.doc} sfGravar
description
@type function
@version 
@author Marcelo Alberto Lauschner
@since 13/09/2014
@return return_type, return_description
/*/
Static Function sfGravar()
	

	If Empty(cAVend)
		Alert("Preencha o vendedor responsável pelo pagamento!")
		Return
	EndIf
	
	If nTotal <= 0
		MsgInfo("Não é possível gerar pagamento com valor Zerado!","Valor zerado.")
		Return
	Endif
	
	If !MsgYesNo("Deseja realmente prosseguir?","Informacao")
		Return
	Endif
	
	dbSelectArea("SZA")
	RecLock("SZA",.T.)
	SZA->ZA_FILIAL 	:= xFilial("SZA")// aCols[x][7]
	SZA->ZA_DOC  	:= cNum
	SZA->ZA_VEND	:= cAVend
	SZA->ZA_PRODUTO := "PAGAMENTO"
	SZA->ZA_DATA 	:= dDataBase
	SZA->ZA_CLIENTE := cAcli
	SZA->ZA_LOJA 	:= cAloja
	SZA->ZA_QTDORI 	:= 0
	SZA->ZA_VALOR  	:= nTotal * (-1)
	SZA->ZA_OBSERV 	:= "PAG: " + cObs//QRA->D2_PEDIDO
	SZA->ZA_TIPOMOV := "D"
	SZA->ZA_ORIGEM  := "L"
	SZA->ZA_REFEREN := SubStr(cReferen,1,1)
	
	MsUnLock()
	
	cAuxNum	:= SZA->ZA_DOC
	
	stComprovante()
	
	Alert("Processo finalizado com Sucesso!!")
	
	//Alterado 25/09/13
	//######################
	
	Promo()
	
	//######################
	
Return

/*/{Protheus.doc} stExporta
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stExporta()
	
	If FindFunction("RemoteType") .And. RemoteType() == 1
		DlgToExcel({{"GETDADOS","Extrato Tampas Cliente: "+cAcli+"-"+cAloja+"-"+Alltrim(cNome)+" # De "+DTOC(dDataOp)+" Ate "+DTOC(dDatabase),aHeader,aCols}})
	EndIf
	
Return


Static Function sfReimprimir()
	
	DbSelectArea("SZA")
	DbGoto(aCols[n,16])
	If SZA->ZA_TIPOMOV == "D" .And. SZA->ZA_ORIGEM =="L"
		cAuxNum	:= SZA->ZA_DOC
		stComprovante()
	Else
		MsgInfo("Posicione na linha do registro de Pagamento que deseja Reimprimir!","Registro posicionado não é pagamento!")
	Endif
Return


/*/{Protheus.doc} stComprovante
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stComprovante()
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Local cDesc1        := "Este programa tem como objetivo imprimir relatorio "
	Local cDesc2        := "de acordo com os parametros informados pelo usuario."
	Local cDesc3        := "Comprovante de Pagamento"
	Local titulo       	:= "Comprovante de Pagamento"
	Local nLin         	:= 80
	
	Local Cabec1       	:= "Comprovamente de Pagamento Promocional"
	Local Cabec2       	:= ""
	Local aOrd := {}
	Private lEnd        := .F.
	Private lAbortPrint := .F.
	Private CbTxt       := ""
	Private limite      := 80
	Private tamanho     := "P"
	Private nomeprog    := "ComprovPag" // Coloque aqui o nome do programa para impressao no cabecalho
	Private nTipo       := 18
	Private aReturn     := { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
	Private nLastKey    := 0
	Private cbcont     	:= 00
	Private CONTFL     	:= 01
	Private m_pag      	:= 01
	Private wnrel      	:= "ComprovantePag" // Coloque aqui o nome do arquivo usado para impressao em disco
	
	Private cString := "SZA"
	
	dbSelectArea("SZA")
	dbSetOrder(1)
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta a interface padrao com o usuario...                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	wnrel := SetPrint(cString,NomeProg,"",@titulo,cDesc1,cDesc2,cDesc3,.F.,aOrd,.F.,Tamanho,,.F.)
	
	If nLastKey == 27
		Return
	Endif
	
	SetDefault(aReturn,cString)
	
	If nLastKey == 27
		Return
	Endif
	
	nTipo := If(aReturn[4]==1,15,18)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Processamento. RPTSTATUS monta janela com a regua de processamento. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)
	
Return

/*/{Protheus.doc} RunReport
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@param Cabec1, ${param_type}, (Descrição do parâmetro)
@param Cabec2, ${param_type}, (Descrição do parâmetro)
@param Titulo, ${param_type}, (Descrição do parâmetro)
@param nLin, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)
	
	
	If lAbortPrint
		@nLin,00 PSAY "*** CANCELADO PELO OPERADOR ***"
		Return
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Impressao do cabecalho do relatorio. . .                            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	If nLin > 55 // Salto de Página. Neste caso o formulario tem 55 linhas...
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 8
	Endif
	
	
	
	DbSelectArea( "SZA" )
	DbSetOrder(3)  // ZA_DOC + ZA_CLIENTE + ZA_LOJA
	If DbSeek( xFilial("SZA") + cAuxNum + cAcli + cAloja)
		
		
		@nLin,00 PSAY "#-----------------------------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# TIPO DE PREMIACAO  | " + IIf(SZA->ZA_REFEREN == "T","TAMPAS",IIf(SZA->ZA_REFEREN == "F","F&I","MARKETING"))
		nLin := nLin + 1
		@nLin,00 PSAY "#--------------------|--------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# CODIGO - LOJA      | " + SZA->ZA_CLIENTE+"-"+SZA->ZA_LOJA
		nLin := nLin + 1
		@nLin,00 PSAY "#--------------------|--------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# NOME CLIENTE       | " + Posicione("SA1",1,xFilial("SA1")+SZA->ZA_CLIENTE+SZA->ZA_LOJA,"A1_NOME")
		nLin := nLin + 1
		@nLin,00 PSAY "#--------------------|--------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# VENDEDOR           | " + Posicione("SA3",1,xFilial("SA3")+SA1->A1_VEND,"A3_NREDUZ")
		nLin := nLin + 1
		@nLin,00 PSAY "#--------------------|--------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# DOCUMENTO          | " + SZA->ZA_DOC
		nLin := nLin + 1
		@nLin,00 PSAY "#--------------------|--------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# DATA LANCAMENTO    | " + DTOC(SZA->ZA_DATA)
		nLin := nLin + 1
		@nLin,00 PSAY "#--------------------|--------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# DESCRICAO          | " + Substr(SZA->ZA_OBSERV,1,50)
		nLin := nLin + 1
		If Len(alltrim(SZA->ZA_OBSERV)) > 50
			@nLin,00 PSAY "#                    | " + Substr(SZA->ZA_OBSERV,51)
			nLin := nLin + 1
		EndIf
		@nLin,00 PSAY "#--------------------|--------------------------------------------------------#"
		nLin := nLin + 1
		@nLin,00 PSAY "# VALOR              | "  + Transform(SZA->ZA_VALOR, "@E 999,999,999.99")
		nLin := nLin + 1
		@nLin,00 PSAY "#-----------------------------------------------------------------------------# "
		nLin := nLin + 6
		@nLin,00 PSAY "->>> PAGAMENTO LANCADO PELO OPERADOR: " + FWLeUserlg("ZA_USERLGI", 1)
		
	EndIf
	
	// Coloque aqui a logica da impressao do seu programa...
	// Utilize PSAY para saida na impressora. Por exemplo:
	// @nLin,00 PSAY SA1->A1_COD
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a execucao do relatorio...                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	SET DEVICE TO SCREEN
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se impressao em disco, chama o gerenciador de impressao...          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	If aReturn[5]==1
		dbCommitAll()
		SET PRINTER TO
		OurSpool(wnrel)
	Endif
	
	MS_FLUSH()
	
Return


//############################################################################
//FAZ A VERIFICAÇÃO PARA EVITAR REGISTROS DUPLICADOS OU VIGENCIAS SOBREPOSTAS#
//############################################################################

/*/{Protheus.doc} SZ8TudOk
(long_description)
@author MarceloLauschner
@since 13/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function SZ8TudOk()
	
	Local lRet     := .T.
	Local nRecAtu  := 0
	Local aAreaOld	:= GetArea()
	Local cQry 
	
	//MsgAlert("Entrou na validação")
	
	If M->Z8_REEMB == "P" 		
		M->Z8_VALOR		:= 0	// Zera o campo valor por que para o Padrão Texaco só vale os preços Z8_VLR1/2/3/4/5/6
	ElseIf M->Z8_REEMB == "T"
		M->Z8_VLR1	:= 0
		M->Z8_VLR2	:= 0
		M->Z8_VLR3	:= 0
		M->Z8_VLR4	:= 0
		M->Z8_VLR5	:= 0
		M->Z8_VLR6	:= 0
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+M->Z8_CLIENTE+M->Z8_LOJA)
			If SA1->A1_REEMB <> M->Z8_REEMB 
				lRet	:= .F.
				MsgAlert("A opção de reembolso de tampas no cadastro do cliente não condiz com a opção de Reembolso selecionada.","Diferença Reebolso!")
			Endif
		Else
			lRet	:= .F.
			MsgAlert("Cliente informado não cadastrado!")
		Endif

		If M->Z8_VALOR	<= 0 
			MsgAlert("Valor de tampinha não pode ficar zerado.","Valor Zerado de tampinha")
			lRet 	:= .F. 
		Endif 
	ElseIf M->Z8_REEMB == "W"
		M->Z8_VLR1	:= 0
		M->Z8_VLR2	:= 0
		M->Z8_VLR3	:= 0
		M->Z8_VLR4	:= 0
		M->Z8_VLR5	:= 0
		M->Z8_VLR6	:= 0
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+M->Z8_CLIENTE+M->Z8_LOJA)
			If SA1->A1_REEMB <> M->Z8_REEMB 
				lRet	:= .F.
				MsgAlert("A opção de reembolso de tampas no cadastro do cliente não condiz com a opção de Reembolso selecionada.","Diferença Reebolso!")
			Endif
		Else
			lRet	:= .F.
			MsgAlert("Cliente informado não cadastrado!")
		Endif

		If M->Z8_VALOR	<= 0 
			MsgAlert("Valor de tampinha não pode ficar zerado.","Valor Zerado de tampinha")
			lRet 	:= .F. 
		Endif 
		
	Endif
	
	If lRet
		If ALTERA
			nRecAtu  := SZ8->(Recno())
		EndIF
		
		cQry := " "
		cQry += "SELECT Z8_CLIENTE, Z8_LOJA, Z8_CODPROD, Z8_REEMB, Z8_DATCAD, Z8_DATFIM, SZ8.R_E_C_N_O_ "
		cQry += "  FROM " + RetSqlName("SZ8") + " SZ8 "
		cQry += " WHERE SZ8.D_E_L_E_T_ = ' '  "
		cQry += "   AND SZ8.Z8_CLIENTE = '" + M->Z8_CLIENTE + "' "
		cQry += "   AND SZ8.Z8_LOJA = '" + M->Z8_LOJA + "' "
		cQry += "   AND SZ8.Z8_CODPROD = '" + M->Z8_CODPROD + "' "
		cQry += "   AND SZ8.Z8_REEMB = '" + M->Z8_REEMB + "' "
		cQry += "   AND '" + DTOS(M->Z8_DATCAD) + "' <= SZ8.Z8_DATFIM AND '" + DTOS(M->Z8_DATFIM) + "' >= SZ8.Z8_DATCAD "
		
		If ALTERA
			cQry += "   AND SZ8.R_E_C_N_O_ <> " + Alltrim(Str(nRecAtu)) + " "
		EndIf
		cQry += "   AND SZ8.Z8_FILIAL = '" + xFilial("SZ8") + "' "
		
		TCQUERY cQry NEW ALIAS "QRY"
		
		If !Eof()
			MsgAlert("Reembolso/Cliente/Loja/Produto já cadastrados com estas configurações de valores dentro dessa vigência! Favor verificar.")
			lRet := .F.
		End
		QRY->(dbCloseArea())
	EndIF
	
	RestArea(aAreaOld)
	
Return(lRet)
