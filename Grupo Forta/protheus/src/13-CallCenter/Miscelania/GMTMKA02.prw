#include "totvs.ch"
#include "rwmake.ch"
#INCLUDE "TOPCONN.CH"

// MudanÁas de campos necess·rios - Criado compatilibizador GMTMKAUP() que efetua todas as atualizaÁıes envolvidas no processo
// E1_HIST 		- Tamanho para 250 caracteres
// K1_XSTATUS 	- Caractere tamanho 1 titulo=Situacao  Combo "1=Serasa","2=Inad.Nova","3=Retornar LigaÁ„o","4=Novo c/HistÛrico","5=CartÛrio","6=Agendado DepÛsito","7=Protestado","8=Sem Status"
// ACG_XSTATU	- Caractere tamanho 1 titulo=Situacao  Combo "1=Serasa","2=Inad.Nova","3=Retornar LigaÁ„o","4=Novo c/HistÛrico","5=CartÛrio","6=Agendado DepÛsito","7=Protestado","8=Sem Status"
// CriaÁ„o do Gatilho
// ACG_TITULO - Retornando o campo ACG_XSTATU e conteudo U_GMTMKA03() // para auto preenchimento do Status

/*/{Protheus.doc} GMTMKA02
Interface de Gerenciamento InadimplÍncia Grupo Forta
@type function
@version 
@author Marcelo Alberto Lauschner
@since 07/07/2011
@return return_type, return_description
/*/
User Function GMTMKA02()
	
	Local		oDlg
	Local		nUsado		:= 0
	Local		nQteDias	:= 0
	Local 		y 
	
	Private dDataVld	:= Date() - 1 // dDataBase-1
	Private dAuxdtBase 	:= Date()
	lExistX7	:= .F.
	DbSelectArea("SX7")
	DbSetOrder(1)
	Dbseek("ACG_TITULO")
	While !Eof() .And. SX7->X7_CAMPO == "ACG_TITULO"
		If Alltrim(SX7->X7_CDOMIN) =="ACG_XSTATU"
			lExistX7	:= .T.
		Endif
		DbSelectArea("SX7")
		DbSkip()
	Enddo
	If !lExistX7
		MsgInfo("N„o foi localizado o Gatilho para preenchimento do campo ACG_XSTATU. Rotina abortada!")
		Return
	Endif
	DbSelectArea("ACG")
	DbSetOrder(1)
	If ACG->(FieldPos("ACG_XSTATU")) == 0
		MsgInfo("N„o foi localidao o campo 'ACG_XSTATU' para rodar nesta empresa!")
		Return
	Endif
	DbSelectArea("SK1")
	DbSetOrder(1)
	If SK1->(FieldPos("K1_XSTATUS")) == 0
		MsgInfo("N„o foi localidao o campo 'K1_XSTATUS' para rodar nesta empresa!")
		Return
	Endif
	//If TamSX3("E1_HIST")[1] <> 150
	//	MsgAlert("O tamanho do Campo 'E1_HIST' n„o est· com o tamanho recomendado de 150 caracteres	para permitir mais informaÁıes!")
	//Endif
	
	
	For y := 2 To 6
		If DataValida(dDataVld) > DataValida(dDataVld-y)
			nQteDias++
			dDataVld	:= DataValida(dDataVld-y)
			Exit
		Endif
		If nQteDias >= GetNewPar("GM_DIAINAD",1)
			Exit
		Endif
	Next
	
	If MsgNoYes("Deseja fazer a atualizaÁ„o da lista de clientes inadimplentes? Esta rotina È um pouco demorada!","A T E N « √ O")
		sfCargaDados()
	Endif
	
	Private  cPergXml	:= "GMTMKA02"
	
	Private aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Private nAltura 	:= aSize[6]/2.2
	Private nMetade 	:= aSize[6]/5
	Private	oVermelho	:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	Private	oAzul 		:= LoaDbitmap( GetResources(), "BR_AZUL" )
	Private	oAmarelo	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private	oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private	oPreto		:= LoaDbitmap( GetResources(), "BR_PRETO" )
	Private	oLaranja	:= LoaDbitmap( GetResources(), "BR_LARANJA" )
	Private	oPink		:= LoaDbitmap( GetResources(), "BR_PINK" )
	Private	oVioleta	:= LoaDbitmap( GetResources(), "BR_VIOLETA" )
	Private	oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Private	oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	Private aCampos   	:= {}
	Private	aArqXml		:= {}
	Private	oArqXml
	Private cArqXml
	Private	aArqSE1		:= {}
	Private	oArqSE1
	Private cArqSE1
	Private	cVarPesq	:= space(09)
	Private aHeader 	:= {}
	Private aCols		:= {}
	Private n			:= 1
	Private oMulti
	Private cObserv	:= ""
	Private nNumInad	:= 0
	Private nTotInad	:= 0
	Private nSaldPer	:= 0
	Private oNumInad,oTotInad,oObserv,oSaldPer,oCbMemo,oBtnSend
	Private oCbSituacao
	Private cComb		:= ""
	Private cCboxMemo	:= "1"
	Private bRefrXmlT	:= {|| Iif(Pergunte(cPergXml,.T.),(lSelBox	:= .F.,Processa({|| stRefresh() },"Aguarde, procurando registros ...."),Processa({|| stRefrItens() },"Aguarde carregando itens....")),Nil)}
	Private bRefrXmlF	:= {|| Pergunte(cPergXml,.F.),(Processa({|| stRefresh() },"Aguarde, procurando registros ...."),Processa({|| stRefrItens() },"Aguarde carregando itens...."))}
	Private bRefrItens	:= {|| Processa({|| stRefrItens() },"Aguarde carregando itens....")}
	Private nFocus1		:= 0
	Private nFocus2		:= 0
	Private INCLUI		:= .F. // Necess·rio declarar para manter compatibilidade dos Inicializadores do ACF
	Private lSelBox		:= .T.
	Private lSortOrd	:= .T.
	ValidPerg()
	If !Pergunte(cPergXml,.T.)
		REturn
	Endif
	
	DbSelectArea("ACF")
	DbSetOrder(1)
	
	Define MsDialog oDlg From 0,0 TO aSize[6] , aSize[5]  Pixel Title OemToAnsi("Controle de gerenciamento de InadimplÍncia") + SM0->M0_NOMECOM
	
	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,25,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP
	

	@ 002, 005 Button oBtnTlcob PROMPT "TelecobranÁa" Size 70,10 Action(sfTMKA271()) Of oPanel1 Pixel
	@ 002, 090 Button oBtnRefr PROMPT "Filtrar dados" Size 70,10 Action(Eval(bRefrXmlT)) Of oPanel1 Pixel
	@ 015, 005 Button oBtnPosCli PROMPT "PosiÁ„o Cliente" Size 70,10 Action(sfPosCliente()) Of oPanel1 Pixel
	@ 015, 090 Button oBtnSend PROMPT "Enviar Email" Size 70,10 Action(sfSendMail()) Of oPanel1 Pixel
	@ 003, 175 Say "Filtro SituaÁ„o" of oPanel1 Pixel
	@ 002, 210 Combobox oCbSituacao Var cComb ITEMS {"0=Sem Filtro","1=Serasa","2=Inad.Nova","3=Retornar LigaÁ„o","4=Novo c/HistÛrico","5=CartÛrio","6=Agendado DepÛsito","7=Protestado","8=Sem Status"} Valid sfCbox() of oPanel1 Pixel Size 80,11
	@ 003, 295 Say "Habilita HistÛrico" of oPanel1 Pixel
	@ 002, 340 Combobox oCbMemo Var cCboxMemo ITEMS {"1=Sim","2=N„o"} of oPanel1 Pixel Size 30,11
	@ 002, 375 Button oBtnSair PROMPT "Sair" Size 50,10 Action(oDlg:End()) Of oPanel1 Pixel
	@ 002, 435 Button oBtnTlcob PROMPT "Rel.TÌtulos Aberto" Size 70,10 Action(U_MLFINR01()) Of oPanel1 Pixel
	oBtnSend:Disable()
	
	//Aadd(aHeader,{Trim(X3Titulo()), SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,"",SX3->X3_TIPO,"","" })
	
	aSX3Add	:= {"ACF_CODIGO","ACF_DATA","ACF_OBS","ACF_CODCON","ACF_DESCNT","ACF_PENDEN","ACF_HRPEND","ACF_PRAZO","ACF_DESCMO","ACF_OBSCAN","ACF_ULTATE","ACF_OPERAD","ACF_DESCOP"}
	For iX := 1 To Len(aSX3Add)
		DbSelectArea("SX3")
		DbSetOrder(2)
		If DbSeek(aSX3Add[iX])
			If X3USO(SX3->X3_USADO)
				Aadd(aHeader,{ AllTrim(X3Titulo()),;
					SX3->X3_CAMPO	,;
					SX3->X3_PICTURE,;
					SX3->X3_TAMANHO,;
					SX3->X3_DECIMAL,;
					SX3->X3_VALID	,;
					SX3->X3_USADO	,;
					SX3->X3_TIPO	,;
					SX3->X3_F3 		,;
					SX3->X3_CONTEXT,;
					SX3->X3_CBOX	,;
					SX3->X3_RELACAO })
				nUsado++
			Endif
		Endif
	Next
	
	
	@ nMetade+05, 0250 Say "InadimplÍncia" of oDlg Pixel
	@ nMetade+05, 0320 MsGet oNumInad Var nNumInad Picture "@E 999,999,999.99" Size 50,10 READONLY COLOR CLR_BLUE noborder of oDlg Pixel
	@ nMetade+05, 0380 Say "Saldo PerÌdo" of oDlg Pixel
	@ nMetade+05, 0450 MsGet oSaldPer Var nSaldPer Picture "@E 999,999,999.99" Size 50,10 READONLY COLOR CLR_BLUE noborder of oDlg Pixel
	
	//oNumInad,oTotInad
	//sfTMKA271()
	
	
	@ 025,005 ListBox oArqXml VAR cArqXml ;
		Fields HEADER " ",;    		// 1
	"Cliente",; 		   		// 2
	"Loja",;    		   		// 3
	"Nome",;				    // 4
	"UF-Fantasia",;	            // 5
	"Valor Inadimplente",;      // 6
	"N∫ Titulos",;				// 7
	"Saldo PerÌodo",;			// 8
	"Retorno",;					// 9
	"Agend.DepÛsito" ,;			// 10
	"⁄lt.TelecobranÁa", ;		// 11
	"N∫ Tit.Serasa",;			// 12
	"⁄lt.Serasa",;				// 13
	"Vendedor",;				// 14
	"Contratos";				// 15
	SIZE aSize[5]/2.01,nMetade-20;
		ON DBLClick (Alert("Teste")) OF oDlg PIXEL
	
	oArqXml:bChange := {|| Pergunte(cPergXml,.F.),Processa({|| stRefrItens() },"Aguarde carregando itens....")}
	
	oArqXml:bHeaderClick := {|| nColPos :=oArqXml:ColPos,lSortOrd := !lSortOrd, aSort(aArqXml,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),oArqXml:Refresh()}
	
	
	@ nAltura-40,110 To nAltura+15,250 of oDlg Pixel
	@ nAltura+15,110 Say "ObservaÁıes ⁄ltimo Atendimento" of oDlg Pixel
	@ nAltura-40,110 Get oObserv Var cObserv of oDlg MEMO Size 140,55 Pixel READONLY
	
	@ nAltura-40,005 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura-40,012 SAY "-Enviado Serasa" of oDlg pixel
	@ nAltura-32,005 BITMAP oBmp RESNAME "BR_VERDE" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura-32,012 SAY "-InadimplÍncia Nova s/Historico" of oDlg pixel
	@ nAltura-24,005 BITMAP oBmp RESNAME "BR_AMARELO" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura-24,012 SAY "-Retornar LigaÁ„o" of oDlg pixel
	@ nAltura-16,005 BITMAP oBmp RESNAME "BR_AZUL" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura-16,012 SAY "-Inadimp.Nova c/HistÛrico" of oDlg pixel
	@ nAltura-08,005 BITMAP oBmp RESNAME "BR_PINK" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura-08,012 SAY "-Agendado DepÛsito" of oDlg pixel
	@ nAltura   ,005 BITMAP oBmp RESNAME "BR_PRETO" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura   ,012 SAY "-CartÛrio" of oDlg pixel
	@ nAltura+08,005 BITMAP oBmp RESNAME "BR_LARANJA" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura+08,012 SAY "-Protestado" of oDlg pixel
	@ nAltura+16,005 BITMAP oBmp RESNAME "BR_VIOLETA" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura+16,012 SAY "-TÌtulo Sem Status" of oDlg pixel
	
	@ (nAltura-nMetade)*0.4+(nMetade+015), 005 To nAltura-42, aSize[5]/2.01+005 Multiline Valid Object oMulti
	
	oMulti:oBrowse:bChange := {|| DbSelectArea("ACF"),cObserv	:= 	MSMM(aCols[n,aScan(aHeader,{|x| Alltrim(x[2]) == "ACF_OBS"})],TamSx3("ACF_OBS")[1]),oObserv:Refresh()}
	oMulti:oBrowse:bLClicked := {|| DbSelectArea("ACF"),cObserv	:= 	MSMM(aCols[n,aScan(aHeader,{|x| Alltrim(x[2]) == "ACF_OBS"})],TamSx3("ACF_OBS")[1]),oObserv:Refresh()}
	
	
	@ nMetade+014,005 ListBox oArqSE1 VAR cArqSE1 ;
		Fields HEADER " ",;    		// 1
	"Prefixo",; 		   		// 2
	"N˙mero",;    		   		// 3
	"Parcela",;				    // 4
	"Tipo",;	        	    // 5
	"Emiss„o",;			        // 6
	"Vencimento Real",;  		// 7
	"Valor",;					// 8
	"Saldo" ,;					// 9
	"HistÛrico", ;				// 10
	"Portador",;				// 11
	"Dias Atraso",;				// 12
	"Recno";					// 13
	SIZE aSize[5]/2.01,(nAltura-nMetade)*0.4;
		ON DBLClick (sfAlterSE1()) OF oDlg PIXEL
	
	Processa({|| stRefresh() },"Aguarde procurando registros ....")
	Processa({|| stRefrItens() },"Aguarde carregando itens....")
	
	oArqXml:SetFocus()
	nFocus1	:= GetFocus()
	oMulti:oBrowse:SetFocus()
	nFocus2	:= GetFocus()
	SetFocus(nFocus1)
	
	Set Key VK_F6 TO sfAlterBrw()
	
	Activate MsDialog oDlg Centered
	
Return

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: sfAlterBrw
// Parametros :
// Objetivo   : Atternar foco entre objetos
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
Static Function sfAlterBrw
	
	If GetFocus() == nFocus1
		SetFocus(nFocus2)
	ElseIf GetFocus() == nFocus2
		SetFocus(nFocus1)
	Endif
	
Return

Static Function sfCbox()
	lSelBox	:= .T.
	Eval(bRefrXmlF)
Return .T.


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: sfAlterSE1
// Parametros :
// Objetivo   : Chama rotina Fina040 na opÁ„o de alterar Titulo
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
Static Function sfAlterSE1()
	
	Local   aHeadBk		:= aHeader
	Local	aColsBk		:= aCols
	Local	nModBk      := nModulo
	Local	cModBk		:= cModulo
	Local	aAreaOld	:= GetArea()
	
	If !__cUserId $ GetNewPar("GF_USRSERA","000000") // Mantenho a compatibilidade entre os dois nomes de parametros
		MsgAlert("VocÍ n„o tem permiss„o para alterar TÌtulos!","A T E N « √ O!!")
		Return
	Endif
	
	DbSelectArea("SE1")
	DbSetOrder(1)
	DbGoto(aArqSE1[oArqSE1:nAt,13])
	
	nModulo	:= 6
	cModulo	:= "FIN"
	
	FinA040(, 4 )
	
	aHeader	:=   aHeadBk
	aCols	:= 	 aColsBk
	nModulo	:= 	 nModBk
	cModulo	:= 	 cModBk
	
	RestArea(aAreaOld)
	
	Eval(bRefrItens)
	//Eval(bRefrXmlF)
	
Return



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: sfTMKA271
// Parametros :
// Objetivo   : Chama rotina TMKA271 analisando se o usu·rio tem perfil de TelecobranÁa
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
Static Function sfTMKA271()
	
	Local	aAreaOld	:= GetArea()
	Local   aHeadBk		:= aHeader
	Local	aColsBk		:= aCols
	Local	nModBk      := nModulo
	Local	cModBk		:= cModulo
	Local	aItens		:= {}
	
	If AllTrim(TkGetTipoAte()) <> "3"
		MsgAlert("VocÍ n„o est· cadastrado como usu·rio exclusivo de TelecobranÁa! Solicite ao CPD o cadastro de usu·rio com permissıes de TelecobranÁa!","Acesso Negado")
		Return
	Endif
	
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3])
	
	If !MsgYesNo("Confirma sucesso na ligaÁ„o para o n˙mero de telefone ("+Alltrim(SA1->A1_DDD)+") "+Alltrim(SA1->A1_TEL)+" ? ","LigaÁ„o TelecobranÁa!")
		Return
	Endif
	
	cModulo := "TMK"
	nModulo := 13
	
	
	DbSelectArea("SE1")
	DbSetOrder(8)
	Set Filter To (SE1->E1_FILIAL == xFilial("SE1") .And. ;
		SE1->E1_CLIENTE == aArqXml[oArqXml:nAt,2] .And.;
		SE1->E1_LOJA == aArqXml[oArqXml:nAt,3] .And.;
		SE1->E1_STATUS == "A" .And.;
		SE1->E1_VENCREA <= dDataBase-GetNewPar("GM_DIAINAD",1))
	DbGotop()
	While !Eof()
		If SE1->E1_TIPO $ MV_CRNEG + "/" + MVRECANT
			MsgAlert("TÌtulo '"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"' do Tipo '"+SE1->E1_TIPO+"' que n„o È InadimplÍncia!","TÌtulos de Abatimento")
		Endif
		
		Aadd(aItens, {	SE1->E1_PREFIXO,;
			SE1->E1_NUM,;
			SE1->E1_PARCELA,;
			SE1->E1_TIPO,;
			SE1->E1_FILIAL} )
		DbSelectArea("SE1")
		DbSkip()
	Enddo
	
	DbSelectArea("SE1")
	Set Filter to
	
	
	DbSelectArea("AC8")
	DbSetOrder(2)
	DbSeek(xFilial("AC8")+"SA1"+xFilial("SA1")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3])
	
	INCLUI := .T.
	
	Tk380CallCenter(AC8->AC8_CODCON,"SA1",aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3],ACF->(Recno()),3,aItens)
	
	aHeader	:=   aHeadBk
	aCols	:= 	 aColsBk
	nModulo	:= 	 nModBk
	cModulo	:= 	 cModBk
	
	RestArea(aAreaOld)
	
	Eval(bRefrXmlF)
	
	Set Key VK_F6 TO sfAlterBrw()
	
	SetFocus(nFocus1)
	
Return

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: sfRefresh
// Parametros :
// Objetivo   : Efetua a carga dos dados no listbox de clientes e posterior chamada para
//              e depois chama o refresh dos titulos e chamados
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
Static Function stRefresh()
	
	Local	cFornece	:= ""
	Local	aDestino	:= {}
	Local	nRecSM0		:= 0
	Local	lExistSF1	:= .F.
	Local	cF1Status	:= ""
	Local	bFiltxml	:= Nil
	
	aArqXml := {}
	
	nNumInad	:= 0
	nSaldPer	:= 0
	If !Empty(MV_PAR03) .Or. !Empty(MV_PAR10)
		oBtnSend:Enable()
	Else
		oBtnSend:Disable()
	Endif
	// Se a tabela estiver aberta, efetuo o fechamento
	U_MLDBSLCT("CONDORTMKC",.T.,1)
	If !lSelBox
		cComb := "0"
	Endif
	//cQryIn	:= "%"+FormatIN(MV_CRNEG + "/" + MVRECANT,"/")+"%"
	cExpAux		:= "%" + Iif(SA1->(FieldPos("A1_OBCONTR")) > 0 , "A1_OBCONTR","' ' A1_OBCONTR")+"%"
	 
	IncProc("Fazendo consulta no Banco de dados")
	
	BeginSql Alias "CONDORTMKC"
		COLUMN CTC_DATA AS DATE
		COLUMN CTC_RETORN AS DATE
		COLUMN CTC_AGEDEP AS DATE
		COLUMN CTC_ULTACF AS DATE
		COLUMN CTC_DTSERA AS DATE
		COLUMN CTC_DTMIN AS DATE
		COLUMN CTC_DTMAX AS DATE
		SELECT CTC_EMPRES,CTC_FILIAL,CTC_CLIENT,CTC_LOJA,CTC_NATRAS,CTC_ATRASO,CTC_DATA,CTC_RETORN,CTC_AGEDEP,CTC_ULTACF,
		CTC_NSERAS,CTC_DTSERA,CTC_STATUS,CTC_DTMIN,CTC_DTMAX,A1_NOME,A1_NREDUZ,A1_EST,A1_VEND,%Exp:cExpAux%
		FROM CONDORTMKC CTC,%Table:SA1% SA1
		WHERE SA1.%NotDel%
		AND A1_LOJA = CTC_LOJA
		AND A1_COD = CTC_CLIENT
		AND CTC_FILIAL = %Exp:cFilAnt%
		AND A1_EST = (CASE WHEN %Exp:MV_PAR09% != ' ' THEN %Exp:MV_PAR09% ELSE A1_EST END)
		AND CTC_CLIENT = (CASE WHEN %Exp:MV_PAR01% != ' ' THEN %Exp:MV_PAR01% ELSE CTC_CLIENT END)
		AND CTC_LOJA = (CASE WHEN %Exp:MV_PAR02% != ' ' THEN %Exp:MV_PAR02% ELSE CTC_LOJA END)
		AND CTC_AGEDEP = (CASE WHEN %Exp:DTOS(MV_PAR05)% != ' ' THEN %Exp:DTOS(MV_PAR05)% ELSE CTC_AGEDEP END)
		AND CTC_RETORN = (CASE WHEN %Exp:DTOS(MV_PAR06)% != ' ' THEN %Exp:DTOS(MV_PAR06)% ELSE CTC_RETORN END)
		AND CTC_STATUS = (CASE WHEN %Exp:cComb% != '0' THEN %Exp:cComb% ELSE CTC_STATUS END)
		AND CTC_ATRASO >= (CASE WHEN %Exp:MV_PAR04% > 0 AND %Exp:DTOS(MV_PAR07)% = '        ' THEN %Exp:MV_PAR04% ELSE CTC_ATRASO END)
		AND (CASE WHEN %Exp:DTOS(MV_PAR07)% != ' ' THEN %Exp:DTOS(MV_PAR07)% ELSE CTC_DTMAX END ) <= CTC_DTMAX
		AND (CASE WHEN %Exp:DTOS(MV_PAR08)% != ' ' THEN %Exp:DTOS(MV_PAR08)% ELSE CTC_DTMIN END ) >= CTC_DTMIN
		AND CTC_EMPRES = %Exp:cEmpAnt%
		AND CTC.%NotDel%
			
	EndSql
//		ORDER BY CTC_ATRASO DESC
	
	Count to nRec
	ProcRegua(nRec)
	DbGotop()
	While !Eof()
		
		IncProc("Lendo registros..."+CONDORTMKC->CTC_CLIENT)
		// Valido o parametro de Vendedor, para n„o considerar
		If !Empty(MV_PAR03)
			If CONDORTMKC->A1_VEND <> MV_PAR03
				DbSelectArea("CONDORTMKC")
				DbSkip()
				Loop
			Endif
		Endif
		// Valido o parametro de Supervisor, para n„o considerar
		If !Empty(MV_PAR10)
			If Posicione("SA3",1,xFilial("SA3")+CONDORTMKC->A1_VEND,"A3_SUPER") <> MV_PAR10
				DbSelectArea("CONDORTMKC")
				DbSkip()
				Loop
			Endif
		Endif
		
		lAdd	:= .F.
		nSalCli	:= 0
		
		If !Empty(MV_PAR08) .And. !Empty(MV_PAR07) .And. Empty(MV_PAR04)
			cQry := "SELECT SUM(CASE WHEN E1_TIPO IN "+FormatIN(MV_CRNEG + "/" + MVRECANT,"/") + " THEN E1_SALDO * -1 ELSE E1_SALDO END) SALDO,SUM(E1_SALDO) DEBITO "
			cQry += "  FROM "+RetSqlName("SE1") + " E1 "
			cQry += " WHERE E1.D_E_L_E_T_ = ' ' "
			cQry += "   AND E1_LOJA = '"+CONDORTMKC->CTC_LOJA+"' "
			cQry += "   AND E1_CLIENTE = '"+CONDORTMKC->CTC_CLIENT+"' "
			cQry += "   AND E1_VENCREA BETWEEN '"+DTOS(MV_PAR07)+"' AND '"+DTOS(MV_PAR08)+"'  "
			cQry += "   AND E1_SALDO > 0 "
			cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+ "' "
			
			TCQUERY cQry NEW ALIAS "QSE1S"
			nSalCli	:= QSE1S->SALDO
			// Valido o parametro 4
			If !Empty(MV_PAR04)
				// Saldo de cliente maior que o valor informado
				If nSalCli > MV_PAR04
					lAdd	:= .T.
				Endif
			Else
				If QSE1S->DEBITO > 0
					lAdd	:= .T.
				Endif
			Endif
			
			QSE1S->(DbCloseArea())
		Else
			If	CONDORTMKC->CTC_NATRAS	 > 0
				lAdd	:= .T.
			Endif
		Endif
		
		If lAdd
			
			Aadd(aArqXml,{Val(CONDORTMKC->CTC_STATUS),;				// 1 Status
			CONDORTMKC->CTC_CLIENT,;								// 2 Cliente
			CONDORTMKC->CTC_LOJA,;									// 3 Loja
			CONDORTMKC->A1_NOME,;									// 4 Nome
			CONDORTMKC->A1_EST+"-"+CONDORTMKC->A1_NREDUZ,;			// 5 Fantasia
			CONDORTMKC->CTC_ATRASO,;								// 6 Valor Inadimplente
			CONDORTMKC->CTC_NATRAS,; 								// 7 Qte titulos em Atraso
			nSalCli,;												// 8 Saldo do Periodo
			CONDORTMKC->CTC_RETORN,;								// 9 Data do Retorno LigaÁ„o
			CONDORTMKC->CTC_AGEDEP,;								// 10 Data do Agendamento Deposito
			CONDORTMKC->CTC_ULTACF,;								// 11 Data do ultimo atdo Telecobranca
			CONDORTMKC->CTC_NSERAS,;								// 12 Qte titulos no serasa
			CONDORTMKC->CTC_DTSERA,;								// 13 Data Ultima NegativaÁ„o Serasa
			CONDORTMKC->A1_VEND+"-"+Posicione("SA3",1,xFilial("SA3")+CONDORTMKC->A1_VEND,"A3_NREDUZ")+"-"+SA3->A3_SUPER,;// 14 CÛdigo do Vendedor
			CONDORTMKC->A1_OBCONTR })								// 15 Observacao de contrato do cadastro de cliente
			nSaldPer	+= nSalCli
			nNumInad	+= CONDORTMKC->CTC_ATRASO
		Endif
		
		DbSelectArea("CONDORTMKC")
		DbSkip()
	Enddo
	
	U_MLDBSLCT("CONDORTMKC",.T.,1)
	
	oNumInad:Refresh()
	oSaldPer:Refresh()
	
	cObserv	:= 	""
	oObserv:Refresh()
	
	If Len(aArqXml) == 0
		MsgAlert("N„o houveram registros para este filtro!")
		Aadd(aArqXml,{	1,;		// 1
		"",;    // 2
		"",;	// 3
		"",;	// 4
		"",;	// 5
		0,;		// 6
		0,;		// 7
		0,;		// 8
		CTOD("  /  /    "),; 	// 9
		CTOD("  /  /    "),;	// 10
		CTOD("  /  /    "),;	// 11
		0,;		// 12
		CTOD("  /  /    "),;	// 13
		" "	,;	// 14
		" "})	// 15
		oArqXml:nAt := 1
	Endif
	
	If oArqXml:nAt > Len(aArqXml)
		oArqXml:nAt := Len(aArqXml)
	Endif
	
	// Reordeno por Valor
	aSort(aArqXml,,,{|x,y| x[6] > y[6]})
	
	
	oArqXml:SetArray(aArqXml)
	oArqXml:bLine:={ ||{stLegenda(aArqXml[oArqXml:nAt,1]),;
		aArqXml[oArqXml:nAT,02],;
		aArqXml[oArqXml:nAT,03],;
		aArqXml[oArqXml:nAT,04],;
		aArqXml[oArqXml:nAT,05],;
		Transform(aArqXml[oArqXml:nAT,06],"@E 999,999,999.99"),;
		Transform(aArqXml[oArqXml:nAT,07],"@E 999,999,999.99"),;
		Transform(aArqXml[oArqXml:nAT,08],"@E 999,999,999.99"),;
		aArqXml[oArqXml:nAT,09],;
		aArqXml[oArqXml:nAT,10],;
		aArqXml[oArqXml:nAT,11],;
		aArqXml[oArqXml:nAT,12],;
		aArqXml[oArqXml:nAT,13],;
		aArqXml[oArqXml:nAt,14],;
		aArqXml[oArqXml:nAt,15]}}
	oArqXml:Refresh()
	
	//U_MLDBSLCT("CONDORTMKC",.F.,1)
	//DbSeek(cEmpAnt+xFilial("SA1")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3])
	
Return


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: stLegenda
// Parametros :
// Objetivo   : Retornar o objeto para legenda dos listbox
// Retorno    : Objeto com a cor do status
// AlteraÁıes :
//---------------------------------------------------------------------------------------

Static Function stLegenda(nInLegenda)
	
	Local	oRet	:= oVermelho
	
	If Len(aArqXml) <= 0
		Return oRet
	Endif
	
	If	nInLegenda == 1
		oRet	:= oVermelho
	ElseIf nInLegenda == 2
		oRet	:= oVerde
	ElseIf	nInLegenda == 3
		oRet	:= oAmarelo
	ElseIf	nInLegenda == 4
		oRet	:= oAzul
	ElseIf	nInLegenda == 5
		oRet 	:= oPreto
	ElseIf	nInLegenda == 6
		oRet 	:= oPink
	ElseIf nInLegenda == 7
		oRet 	:= oLaranja
	ElseIf nInLegenda == 8
		oRet	:= oVioleta
	EndIf
	
Return(oRet)


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: ValidPerg
// Parametros :
// Objetivo   : Criar as perguntas para a rotina
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
Static Function ValidPerg()
	
	Local aRegs := {}
	Local i,j
	
	dbSelectArea("SX1")
	dbSetOrder(1)
	cPergXml :=  PADR(cPergXml,Len(SX1->X1_GRUPO))
	//     "X1_GRUPO" ,"X1_ORDEM","X1_PERGUNT"    			,"X1_PERSPA"		,"X1_PERENG"		,"X1_VARIAVL","X1_TIPO"	,"X1_TAMANHO"	,"X1_DECIMAL"	,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
	Aadd(aRegs,{cPergXml ,"01"		,"Cliente"				,"Cliente	"	 	,"Cliente  "		,"mv_ch1"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par01"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA1" 		,"S"		,""			,""})
	Aadd(aRegs,{cPergXml ,"02"		,"Loja "				,"Loja "			,"Loja "			,"mv_ch2"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	Aadd(aRegs,{cPergXml ,"03"		,"Vendedor"				,"Vendedor"		 	,"Vendedor"			,"mv_ch3"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par03"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA3" 		,"S"		,""			,""})
	Aadd(aRegs,{cPergXml ,"04"		,"Acima do Valor "		,"Acima do Valor"	,"SituaÁ„o"			,"mv_ch4"	,"N"		,12				,2				,0				,"G"		,""			,"mv_par04"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""				,""})
	AADD(aRegs,{cPergXml ,"05"      ,"Agendado Deposito"    ,""                 ,""                 ,"mv_ch5"   ,"D"        ,08             ,0				,0				,"G"		,""			,"mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPergXml ,"06"      ,"Retorno LigaÁ„o"      ,""                 ,""                 ,"mv_ch6"   ,"D"        ,08             ,0				,0				,"G"		,""			,"mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPergXml ,"07"      ,"Data Inicial"         ,""                 ,""                 ,"mv_ch7"   ,"D"        ,08             ,0				,0				,"G"		,""			,"mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPergXml ,"08"      ,"Data Final"           ,""                 ,""                 ,"mv_ch8"   ,"D"        ,08             ,0				,0				,"G"		,""			,"mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	Aadd(aRegs,{cPergXml ,"09"		,"Estado"				,""			 		,""					,"mv_ch9"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par09"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"12" 		,"S"		,""			,""})
	Aadd(aRegs,{cPergXml ,"10"		,"Supervisor"			,"Supervisor"	 	,"Supervisor"		,"mv_chA"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par10"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA3" 		,"S"		,""			,""})
	
	For i:=1 to Len(aRegs)
		If !dbSeek(cPergXml+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock("SX1")
		Else
			/*		RecLock("SX1",.F.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif             '
			Next
			MsUnlock("SX1")*/
		Endif
	Next
	
Return

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: sfRefrItens
// Parametros :
// Objetivo   : Efetua a atualizaÁ„o do ListBox de Titulos e Grid dos Atendimentos TelecobranÁa
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
Static Function  stRefrItens()
	
	Local	cQry		:= ""
	Local	lConvProd	:= .F.
	
	//U_MLDBSLCT("CONDORTMKC",.F.,1)
	//DbSeek(cEmpAnt+xFilial("SA1")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3])
	
	aCols	:= {}
	DbSelectArea("ACF")
	DbSetOrder(2)
	
	lQuery  := .T.
	cAliasACF := GetNextAlias()
	BeginSql Alias cAliasACF
		COLUMN ACF_DATA AS DATE
		COLUMN ACF_PENDEN AS DATE
		COLUMN ACF_INICIO AS DATE
		COLUMN ACF_DTINI AS DATE
		COLUMN ACF_ULTATE AS DATE
		SELECT ACF_FILIAL,ACF_CODIGO,ACF_CLIENT,ACF_LOJA,ACF_CODCON,ACF_OPERAD,ACF_OPERA,ACF_MOTIVO,ACF_DATA,ACF_MOTIVO,
		ACF_CODOBS,ACF_PENDEN,ACF_HRPEND,ACF_INICIO,ACF_FIM,ACF_DIASDA,ACF_HORADA,ACF_CODCAM,ACF_STATUS,
		ACF_DTINI,ACF_QTDATE,ACF_CCANC,ACF_OPERAT,ACF_CODENC,ACF_CODMOT,ACF_ULTATE
		FROM %Table:ACF% ACF
		WHERE ACF_FILIAL = %xFilial:ACF%
		AND ACF_CLIENT = %Exp:aArqXml[oArqXml:nAt,2]%
		AND ACF_LOJA = %Exp:aArqXml[oArqXml:nAt,3]%
		AND ACF.%NotDel%
		ORDER BY R_E_C_N_O_ DESC
	EndSql
	
	While !Eof() .And. (cAliasACF)->ACF_FILIAL+(cAliasACF)->ACF_CLIENT+(cAliasACF)->ACF_LOJA == xFilial("ACF")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3]
		AADD(aCols,Array(Len(aHeader)+1))
		
		For nI := 1 To Len(aHeader)
			If IsHeadRec(aHeader[nI][2])
				aCols[Len(aCols)][nI] := QRY->R_E_C_N_O_
			ElseIf IsHeadAlias(aHeader[nI][2])
				aCols[Len(aCols)][nI] := "ACF"
			ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
				aCols[Len(aCols)][nI] := FieldGet(FieldPos(aHeader[nI][2]))
			Else
				If aHeader[nI][10] $ "V#M"
					If Alltrim(aHeader[nI][2]) == "ACF_OBS"
						aCols[Len(aCols)][nI]	:= (cAliasACF)->ACF_CODOBS//	MSMM((cAliasACF)->ACF_CODOBS,TamSx3("ACF_OBS")[1])
					ElseIf	Alltrim(aHeader[nI][2]) == "ACF_OBSMOT"
						aCols[Len(aCols)][nI]	:= MSMM((cAliasACF)->ACF_CODMOT,TamSx3("ACF_OBSMOT")[1])
					ElseIf	Alltrim(aHeader[nI][2]) == "ACF_OBSCAN"
						aCols[Len(aCols)][nI]	:= MSMM((cAliasACF)->ACF_CCANC,TamSx3("ACF_OBSCAN")[1])
					ElseIf Alltrim(aHeader[nI][2]) == "ACF_DESC"
						aCols[Len(aCols)][nI]	:= TkDCliente((cAliasACF)->ACF_CLIENT,ACF->ACF_LOJA)
					ElseIf Alltrim(aHeader[nI][2]) == "ACF_DESCNT"
						aCols[Len(aCols)][nI]	:= Posicione("SU5",1,xFilial("SU5") + (cAliasACF)->ACF_CODCON, "U5_CONTAT")
					ElseIf Alltrim(aHeader[nI][2]) == "ACF_DESCMO"
						aCols[Len(aCols)][nI]	:= Posicione("SU9",2,xFilial("SU9") + (cAliasACF)->ACF_MOTIVO, "U9_DESC")
					ElseIf Alltrim(aHeader[nI][2]) == "ACF_DESCOP"
						aCols[Len(aCols)][nI]	:= Posicione("SU7",1,xFilial("SU7") + (cAliasACF)->ACF_OPERAD, "U7_NOME")
					Else
						aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
					Endif
					
				Else
					aCols[Len(aCols)][nI] := CriaVar(aHeader[nI][2],.T.)
				Endif
			Endif
		Next nI
		
		DbSelectArea(cAliasACF)
		DbSkip()
	Enddo
	(cAliasACF)->(DbCloseArea())
	n	:= Len(aCols)
	
	If n == 0
		AADD(aCols,Array(Len(aHeader)+1))
		For nColuna := 1 to Len( aHeader )
			
			If aHeader[nColuna][8] == "C"
				aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
			ElseIf aHeader[nColuna][8] == "D"
				aCols[Len(aCols)][nColuna] := dDataBase
			ElseIf aHeader[nColuna][8] == "M"
				aCols[Len(aCols)][nColuna] := ""
			ElseIf aHeader[nColuna][8] == "N"
				aCols[Len(aCols)][nColuna] := 0
			Else
				aCols[Len(aCols)][nColuna] := .F.
			Endif
		Next nColuna
	Endif
	n	:= Len(aCols)
	
	oMulti:oBrowse:Refresh()
	oMulti:Refresh()
	DbSelectArea("ACF")
	If cCboxMemo == "1"
		cObserv	:= MSMM(aCols[n,aScan(aHeader,{|x| Alltrim(x[2]) == "ACF_OBS"})],TamSx3("ACF_OBS")[1])
	Else
		cObserv := ""
	Endif
	oObserv:Refresh()
	
	aArqSE1:= {}
	
	cE1_STATUS	:= "A"
	
	cAliasSE1 := GetNextAlias()
	BeginSql Alias cAliasSE1
		COLUMN E1_EMISSAO AS DATE
		COLUMN E1_VENCREA AS DATE
		SELECT E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_EMISSAO,E1_VENCREA,E1_HIST,E1_PORTADO,E1_AGEDEP,E1_CONTA,E1_NUMBCO,E1_VALOR,(E1_SALDO +E1_ACRESC-E1_DECRESC) E1_SALDO,R_E_C_N_O_ AS RECNOSE1
		FROM %Table:SE1% SE1
		WHERE E1_FILIAL = %xFilial:SE1%
		AND E1_STATUS = %Exp:cE1_STATUS%
		AND E1_SALDO > 0
		AND E1_CLIENTE = %Exp:aArqXml[oArqXml:nAt,2]%
		AND E1_LOJA = %Exp:aArqXml[oArqXml:nAt,3]%
		AND SE1.%NotDel%
		ORDER BY E1_VENCREA,E1_EMISSAO,E1_NUM
	EndSql
	DbGotop()
	While !Eof()
		
		DbSelectArea("SK1")
		DbSetOrder(1)                             //ACG_PREFIX+ACG_TITULO+ACG_PARCEL+ACG_TIPO+ACG_FILORI
		DbSeek(xFilial("SK1")+(cAliasSE1)->E1_PREFIXO+;
			(cAliasSE1)->E1_NUM+;
			(cAliasSE1)->E1_PARCELA+;
			(cAliasSE1)->E1_TIPO)
		cStatus	:= SK1->K1_XSTATUS
		If Empty(cStatus)
			cStatus 	:= "8"
		Endif
		Aadd(aArqSE1,{Val(cStatus),;							// 1 Status
		(cAliasSE1)->E1_PREFIXO,;								// 2 Prefixo
		(cAliasSE1)->E1_NUM,;									// 3 N˙mero
		(cAliasSE1)->E1_PARCELA,;								// 4 Parcela
		(cAliasSE1)->E1_TIPO,;									// 5 Tipo
		(cAliasSE1)->E1_EMISSAO,;								// 6 Emissao
		(cAliasSE1)->E1_VENCREA,; 								// 7 Vencimento Real
		Transform((cAliasSE1)->E1_VALOR,"@E 999,999,999.99"),;	// 8 Valor
		Transform((cAliasSE1)->E1_SALDO,"@E 999,999,999.99"),;	// 9 Saldo titulo
		(cAliasSE1)->E1_HIST,;									// 10 Historico
		(cAliasSE1)->E1_PORTADO +"-"+ Posicione("SA6",1,xFilial("SA6")+(cAliasSE1)->E1_PORTADO+(cAliasSE1)->E1_AGEDEP+(cAliasSE1)->E1_CONTA,"A6_NREDUZ"),;					// 11 Portador
		dDataBase - (cAliasSE1)->E1_VENCREA,;					// 12 Dias Atraso
		(cAliasSE1)->RECNOSE1})									// 13 Recno
		DbSelectArea(cAliasSE1)
		DbSkip()
	Enddo
	(cAliasSE1)->(DbCloseArea())
	
	If Len(aArqSE1) == 0
		Aadd(aArqSE1,{	1,;		// 1
		"",;    // 2
		"",;	// 3
		"",;	// 4
		"",;	// 5
		CTOD("  /  /    "),;		// 6
		CTOD("  /  /    "),;		// 7
		0,; 	// 8
		0,;	// 9
		"",;	// 10
		0,;		// 11
		""})	// 12
		oArqSE1:nAt := 1
	Endif
	
	If oArqSE1:nAt > Len(aArqSE1)
		oArqSE1:nAt := Len(aArqSE1)
	Endif
	
	//CONDORXML->(DbCloseArea())
	
	oArqSE1:SetArray(aArqSE1)
	oArqSE1:bLine:={ ||{stLegenda(aArqSE1[oArqSE1:nAt,1]),;
		aArqSE1[oArqSE1:nAT,02],;
		aArqSE1[oArqSE1:nAT,03],;
		aArqSE1[oArqSE1:nAT,04],;
		aArqSE1[oArqSE1:nAT,05],;
		aArqSE1[oArqSE1:nAT,06],;
		aArqSE1[oArqSE1:nAT,07],;
		aArqSE1[oArqSE1:nAT,08],;
		aArqSE1[oArqSE1:nAT,09],;
		aArqSE1[oArqSE1:nAT,10],;
		aArqSE1[oArqSE1:nAT,11],;
		aArqSE1[oArqSE1:nAT,12]}}
	oArqSE1:Refresh()
	
Return

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: sfCargaDados
// Parametros :
// Objetivo   : Efetua a carga de clientes inadimplentes na Tabela CONDORTMKC
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
Static Function sfCargaDados()
	
	Local		cQry		:= ""
	
	
	// Localizo todos os titulos em aberto no sistema
	//U_MLDBSLCT("CONDORTMKC",.F.,1)
	
	cQry := "SELECT E1_CLIENTE,E1_LOJA,COUNT(DISTINCT(CASE WHEN E1_VENCREA <= '"+DTOS(dDataVld)+"' THEN E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO END)) NTITULOS, "
	cQry += "       CAST(MIN(CASE WHEN E1_VENCREA <= '"+DTOS(dDataVld)+"' THEN GETDATE() - CAST(E1_VENCREA AS DATETIME)  ELSE 0 END ) AS INT) NMINIMO, "
	cQry += "       CAST(MAX(CASE WHEN E1_VENCREA <= '"+DTOS(dDataVld)+"' THEN GETDATE() - CAST(E1_VENCREA AS DATETIME) ELSE 0 END )AS INT) NMAXIMO,"
	cQry += "       SUM(CASE WHEN E1_VENCREA >= '"+DTOS(dDataVld)+"' AND CAST(E1_VENCREA AS DATETIME) < GETDATE() THEN 1 ELSE 0 END ) NNEW, "
	cQry += "       MIN(E1_VENCREA) DMINIMO,MAX(E1_VENCREA) DMAXIMO, "
	cQry += "       SUM(CASE WHEN E1_VENCREA <= '"+DTOS(dDataVld)+"' THEN CASE WHEN E1_TIPO IN "+FormatIN(MV_CRNEG + "/" + MVRECANT,"/") + " THEN (E1_SALDO +E1_ACRESC-E1_DECRESC) * -1 ELSE (E1_SALDO +E1_ACRESC-E1_DECRESC) END ELSE 0 END) SALDO "
	cQry += "  FROM "+RetSqlName("SE1") + " E1 "
	cQry += " WHERE E1.D_E_L_E_T_ = ' ' "
	//cQry += "   AND E1_VENCREA <= GETDATE()-3 "
	cQry += "   AND E1_SALDO > 0 "
	cQry += "   AND E1_FILIAL = '"+xFilial("SE1")+ "' "
	cQry += " GROUP BY E1_CLIENTE,E1_LOJA "
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	While !Eof()
		U_MLDBSLCT("CONDORTMKC",.F.,1)
		
		lNewRec	:= DbSeek(cEmpAnt+cFilAnt+QRY->E1_CLIENTE+QRY->E1_LOJA)
		
		cSts	:= "8" // Sem status - Default
		
		// Se j· existe o cliente, mantÈm o Status
		If lNewRec
			cSts	:= CONDORTMKC->CTC_STATUS
			// Se h· titulos em Atraso com titulos de inadimplencia no intervalo de dias considerado novo e n„o houve atualizaÁ„o no dia ainda.
			If  QRY->NNEW > 0 .And. CONDORTMKC->CTC_DATA < dAuxdtBase .And. (CONDORTMKC->CTC_AGEDEP < dAuxdtBase .And. CONDORTMKC->CTC_RETORN < dAuxdtBase .And. !CONDORTMKC->CTC_STATUS $ "3#5" ) // Adicionada
				cSts	:= "2"	// Inad.Nova sem telecobranÁa
				DbSelectArea("SK1")
				DbSetOrder(4)
				DbSeek(xFilial("SK1")+QRY->E1_CLIENTE+QRY->E1_LOJA)
				While !Eof() .And. SK1->K1_FILIAL+SK1->K1_CLIENTE+SK1->K1_LOJA == xFilial("SK1")+QRY->E1_CLIENTE+QRY->E1_LOJA
					If SK1->K1_VENCREA < dDataVld .And. SK1->K1_SALDO > 0 .And. !SK1->K1_XSTATUS $ " #8"
						cSts := "4" // Inad.Nova com Historico
						//Exit
					Endif
					DbSelectArea("SK1")
					DbSkip()
				Enddo
			Endif
			U_MLDBSLCT("CONDORTMKC",.F.,1)
			DbSeek(cEmpAnt+cFilAnt+QRY->E1_CLIENTE+QRY->E1_LOJA)
			RecLock("CONDORTMKC",.F.)
			// Se n„o houverem titulos em atraso do cliente zero a data de agendado e retorno
			If QRY->NMAXIMO == 0
				CONDORTMKC->CTC_RETORN   := CTOD("")
				CONDORTMKC->CTC_AGEDEP   := CTOD("")
			Endif
			
		Else
			//MsgAlert(cEmpAnt+xFilial("SA1")+QRY->E1_CLIENTE+QRY->E1_LOJA,"dados dbseek ")
			
			If QRY->NMINIMO > 0 .And. QRY->NNEW > 0
				cSts	:= "2"	// Inad.Nova sem telecobranÁa
				DbSelectArea("SK1")
				DbSetOrder(4)
				DbSeek(xFilial("SK1")+QRY->E1_CLIENTE+QRY->E1_LOJA)
				While !Eof() .And. SK1->K1_FILIAL+SK1->K1_CLIENTE+SK1->K1_LOJA == xFilial("SK1")+QRY->E1_CLIENTE+QRY->E1_LOJA
					If SK1->K1_VENCREA < dDataVld .And. SK1->K1_SALDO > 0 .And. !SK1->K1_XSTATUS $ " #8"
						cSts := "4" // Inad.Nova com Historico
						//Exit
					Endif
					DbSelectArea("SK1")
					DbSkip()
				Enddo
			Endif
			RecLock("CONDORTMKC",.T.)
			CONDORTMKC->CTC_EMPRES  := cEmpAnt
			CONDORTMKC->CTC_FILIAL  := cFilAnt
			CONDORTMKC->CTC_CLIENT	:= QRY->E1_CLIENTE
			CONDORTMKC->CTC_LOJA 	:= QRY->E1_LOJA
		Endif
		CONDORTMKC->CTC_NATRAS	:= QRY->NTITULOS
		CONDORTMKC->CTC_ATRASO	:= QRY->SALDO
		CONDORTMKC->CTC_DATA	:= dDataVld+1 // Soma de volta 
		CONDORTMKC->CTC_STATUS	:= cSts
		CONDORTMKC->CTC_DTMIN	:= STOD(QRY->DMINIMO)	// Menor dia de Vencimento
		CONDORTMKC->CTC_DTMAX	:= STOD(QRY->DMAXIMO)	// Maior Dia de Vencimento
		MsUnlock()
		DbSelectArea("QRY")
		DbSkip()
	Enddo
	QRY->(DbCloseArea())
	
	// FaÁa a atualizaÁ„o forÁada dos clientes que n„o est„o mais na lista de inadimplentes
	cQry := "UPDATE CONDORTMKC "
	cQry += "   SET D_E_L_E_T_ = '*' "
	cQry += "       ,R_E_C_D_E_L_ = R_E_C_N_O_ "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND CAST(CTC_DATA AS DATETIME) < GETDATE()-1 "
	cQry += "   AND CTC_FILIAL = '"+cFilAnt+"' "
	cQry += "   AND CTC_EMPRES = '"+cEmpAnt+"' "
	
	TcSqlExec(cQry)
	
	// FaÁa a atualizaÁ„o forÁada dos clientes que n„o est„o mais na lista de inadimplentes
	cQry := "UPDATE CONDORTMKC "
	cQry += "   SET D_E_L_E_T_ = '*' "
	cQry += "       ,R_E_C_D_E_L_ = R_E_C_N_O_ "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND NOT EXISTS (SELECT E1_CLIENTE  "
	cQry += "                     FROM "+RetSqlName("SE1") + " E1 "
	cQry += "                    WHERE E1.D_E_L_E_T_ = ' ' "
	cQry += "                      AND E1_LOJA = CTC_LOJA "
	cQry += "                      AND E1_CLIENTE = CTC_CLIENT "
	cQry += "                      AND E1_SALDO > 0 "
	cQry += "                      AND E1_STATUS = 'A' "
	cQry += "                      AND E1_FILIAL = '"+xFilial("SE1")+"' ) "
	cQry += "   AND CTC_FILIAL = '"+cFilAnt+"' "
	cQry += "   AND CTC_EMPRES = '"+cEmpAnt+"' "
	
	TcSqlExec(cQry)
	
	TcRefresh("CONDORTMKC")
	
	// Executo chamada da rotina que atualiza os titulos na cobranÁa
	Tk180Atu()
	
	
Return


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: GMTMKA03
// Parametros :
// Objetivo   : FunÁ„o de validaÁ„o para retornar o Status do Titulo j· salvo na SK1
// 				Usado no Gatilho do campo ACG_TITULO-ACG_XSTATU
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------

User Function GMTMKA03()

	Local	cRet		:= ""
	Local	cQry 		:= "" 	
	Local	aAreaOld	:= GetArea()
	//If (Type("INCLUI") <> "U" .And. INCLUI)
	DbSelectArea("SE1")
	//MsgAlert(SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	cQry += "SELECT K1_XSTATUS "
	cQry += "  FROM "+ RetSqlName("SK1")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND K1_PREFIXO = '"+SE1->E1_PREFIXO+"' "
	cQry += "   AND K1_PARCELA = '"+SE1->E1_PARCELA+"' "
	cQry += "   AND K1_TIPO = '"+SE1->E1_TIPO+"' "
	cQry += "   AND K1_NUM = '"+SE1->E1_NUM+"' "
	cQry += "   AND K1_FILIAL = '"+xFilial("SK1")+"' "
	
	TcQuery cQry New Alias "QSK1"
	
	If !Eof()
		cRet	:= QSK1->K1_XSTATUS
	Endif
	QSK1->(DbCloseArea())
	RestArea(aAreaOld)
	
Return cRet


//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 07/07/2011
// Nome funÁ„o: GMTMKA3V
// Parametros :
// Objetivo   : ValidaÁ„o do Campo ACG_XSTATU para permitir replicar status para demais
//              titulos da tela e se for Serasa j· invocar rotina de adiÁ„o ao Serasa
// Retorno    :
// AlteraÁıes :
//---------------------------------------------------------------------------------------
User Function GMTMKA3V()
	
	Local	nPosSts	:= Ascan(aHeader, {|x|AllTrim(x[2]) == "ACG_XSTATU"})
	Local	lEmpty	:= .F.
	
	If nPosSts == 0
		Return .T.
	Endif
	// Verifico se o h· titulos sem situaÁ„o
	For xI := 1 To Len(aCols)
		If Empty(aCols[xI,nPosSts]) .And. xI # n
			lEmpty	:= .T.
		Endif
	Next
	If lEmpty
		If MsgYesNo("Deseja replicar o mesmo Status para os demais tÌtulos sem 'SituaÁ„o'?","AtualizaÁ„o Status")
			For xI := 1 To Len(aCols)
				If Empty(aCols[xI,nPosSts]) .And. xI # n
					aCols[xI,nPosSts]	:= M->ACG_XSTATU
				Endif
			Next
		Endif
	Endif
	// Se for Serasa, j· chamo a rotina de Inclus„o de tÌtulos no Serasa
	If M->ACG_XSTATU == "1" .And. FindFunction("U_SERPEFIN")
		U_SERPEFIN(.T.,SA1->A1_COD,SA1->A1_COD,3)
	Endif
	// FaÁo atualizaÁ„o do campo hora de retorno a cada interaÁ„o, facilitando a saida da rotina
	M->ACF_HRPEND	:= Time()
	
Return .T.
/*
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥sfSendMail∫Autor  ≥Marcelo A Lauschner ∫ Data ≥ 30/11/2011  ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Desc.     ≥ Efetua o envio via email em HTML da inadimplencia do       ∫±±
±±∫          ≥ vendedor selecionado com todo historico de telecobranÁa    ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ AP                                                         ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
*/


Static Function sfSendMail()
	
	Local	aAreaOld	:= GetArea()
	Local	lSend		:= .F.
	Local	oDlgEmail
	Local	lPerg		:= Pergunte(cPergXml,.F.)
	Local	cTo			:= Iif(!Empty(MV_PAR10),Padr(Posicione("SA3",1,xFilial("SA3")+MV_PAR10,"A3_EMAIL"),500),Padr(Posicione("SA3",1,xFilial("SA3")+MV_PAR03,"A3_EMAIL"),500))
	Local	cSubject	:= "Gerenciamento de InadimplÍncia -> "+Iif(!Empty(MV_PAR10),"Supervisor - ","Vendedor - " )+SA3->A3_COD+"-"+SA3->A3_NREDUZ
	Local	cBody		:= ""
	Local	cMsg		:= ""
	Local	aCodACF		:= {}
	Local	nPartMail	:= 1
	
	
	DEFINE MSDIALOG oDlgEmail FROM 001,001 TO 380,620 Pixel Title OemToAnsi("Enviar email para o Vendedor ")
	@ 010,010 Say "Para: " Pixel of oDlgEmail
	@ 010,050 MsGet cTo Size 180,10 Pixel Of oDlgEmail
	@ 025,010 Say "Assunto" Pixel of oDlgEmail
	@ 025,050 MsGet cSubject Size 250,10 Pixel Of oDlgEmail
	@ 040,050 Get cBody of oDlgEmail MEMO Size 250,100 Pixel
	@ 160,050 BUTTON "Envia Email" Size 70,10 Action (lSend := .T.,oDlgEmail:End())	Pixel Of oDlgEmail
	@ 160,130 BUTTON "Cancela" Size 70,10 Action (oDlgEmail:End())	Pixel Of oDlgEmail
	
	ACTIVATE MsDialog oDlgEmail Centered
	
	If lSend
		//oHtml:ValByName("NOMECOM",AllTrim(SM0->M0_NOMECOM))
		//oHtml:ValByName("ENDEMP",Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		//oHtml:ValByName("COMEMP",Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		//oHtml:ValByName("FONE","Fone/Fax: " + SM0->M0_TEL + " / " + SM0->M0_FAX)
		//oHtml:ValByName("CGC","CNPJ: " +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))
		//oHtml:ValByName("INSC","InscriÁ„o Estadual: " + SM0->M0_INSC)
		
		
		cMsg += '<html>'
		cMsg += '	<head>'
		cMsg += '		<meta http-equiv="Content-Language" content="pt-br">'
		cMsg += '		<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">'
		cMsg += '			<title>Cliente/Loja</title>'
		cMsg += '	</head>'
		cMsg += '	<body>'
		cMsg += '		<table border="0" width="100%" cellpadding="0" cellspacing="0" height="30">'
		// Montagem do CabeÁalho do Email informando a Empresa
		cMsg += '			<tr>'
		cMsg += '				<td width="46%"><p align="center"><font size="5"><b>'+AllTrim(SM0->M0_NOMECOM)+'</b></font></td>'
		cMsg += '				<td width="48%" valign="top" height="48" style="border-top: 2 solid #C0C0C0">'
		cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">'+Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT)+'</p>'
		cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">'+Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT+'</p>'
		cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">Fone/Fax: ' + SM0->M0_TEL + ' / ' + SM0->M0_FAX+'</p>'
		cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">CNPJ: ' +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")+'</p>'
		cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">InscriÁ„o Estadual: ' + SM0->M0_INSC+'</p>
		cMsg += '               </td>'
		cMsg += '			</tr>'
		cMsg += '		</table>'
		// Montagem do Campo ObservaÁ„o escrita pela Retaguarda
		cMsg += '		<table border="1" width="100%" height="31">'
		cMsg += '			<tr>'
		cMsg += '				<td><b>'+StrTran(cBody,'"',"")+'</b></td>'
		cMsg += '			</tr>'
		cMsg += '		</table>'
		// Montagem do cabeÁalho do cliente
		For iX := 1 To Len(aArqXml)
			
			
			
			cAliasSE1 := GetNextAlias()
			
			BeginSql Alias cAliasSE1
				COLUMN E1_EMISSAO AS DATE
				COLUMN E1_VENCREA AS DATE
				SELECT E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_EMISSAO,E1_VENCREA,E1_HIST,E1_PORTADO,E1_AGEDEP,E1_CONTA,E1_NUMBCO,E1_VALOR,E1_SALDO,R_E_C_N_O_ AS RECNOSE1
				FROM %Table:SE1% SE1
				WHERE E1_FILIAL = %xFilial:SE1%
				AND E1_SALDO > 0
				AND E1_VENCREA <= %Exp:dDataVld%
				AND E1_CLIENTE = %Exp:aArqXml[iX,2]%
				AND E1_LOJA = %Exp:aArqXml[iX,3]%
				AND SE1.%NotDel%
				ORDER BY E1_VENCREA,E1_EMISSAO,E1_NUM
			EndSql
			If !Eof()
				
				
				cMsg += '		<table border="1" width="100%" >'
				cMsg += '			<tr>'
				cMsg += '				<td height="19"  align="left" bgcolor="#C0C0C0"><font size="1">Cliente/Loja</font></td>'
				cMsg += '				<td height="19"  align="left" bgcolor="#C0C0C0"><font size="1">Nome</font></td>'
				cMsg += '				<td height="19"  align="left" bgcolor="#C0C0C0"><font size="1">Estado-Nome Fantasia-Vendedor-Supervisor</font></td>'
				cMsg += '				<td height="19"  align="right" bgcolor="#C0C0C0"><font size="1">R$ Inadimplente</font></td>'
				cMsg += '				<td height="19"  align="center" bgcolor="#C0C0C0"><font size="1">N∫ TÌtulos</font></td>'
				cMsg += '				<td height="19"  align="center" bgcolor="#C0C0C0"><font size="1">Data p/Retorno</font></td>'
				cMsg += '				<td height="19"  align="center" bgcolor="#C0C0C0"><font size="1">Data Agenda DepÛsito</font></td>'
				cMsg += '				<td height="19"  align="center" bgcolor="#C0C0C0"><font size="1">⁄ltima TelecobranÁa</font></td>'
				cMsg += '			</tr>'
				// Dados do cliente
				cMsg += '			<tr>'
				cMsg += '				<td height="23"  align="left"><font size="1">'+aArqXml[iX,2]+"/"+aArqXml[iX,3]+'</font></td>'
				cMsg += '				<td height="23"  align="left"><font size="1">'+aArqXml[iX,4]+'</font></td>'
				cMsg += '				<td height="23"  align="left"><font size="1">'+aArqXml[iX,5]+"-"+aArqXml[iX,14]+'</font></td>'
				cMsg += '				<td height="23"  align="right"><font size="1">'+Transform(aArqXml[iX,6],"@E 99,999,999.99")+'</font></td>'
				cMsg += '				<td height="23"  align="center"><font size="1">'+Transform(aArqXml[iX,7],"@E 999,999")+'</font></td>'
				cMsg += '				<td height="23"  align="center"><font size="1">'+DTOC(aArqXml[iX,9])+'</font></td>'
				cMsg += '				<td height="23"  align="center"><font size="1">'+DTOC(aArqXml[iX,10])+ '</font></td>'
				cMsg += '				<td height="23"  align="center"><font size="1">'+DTOC(aArqXml[iX,11])+'</font></td>'
				cMsg += '			</tr>'
				// Montagem do cabeÁalho dos titulos
				cMsg += '			<tr>'
				cMsg += '				<td height="20" width="100%" colspan="8">'
				cMsg += '					<table border="1" width="100%">'
				cMsg += '						<tr>'
				cMsg += '							<td width="8%" bgcolor="#C0C0C0"><font size="1">Prefixo</font></td>'
				cMsg += '							<td width="9%" bgcolor="#C0C0C0"><font size="1">N˙mero</font></td>'
				cMsg += '							<td width="5%" bgcolor="#C0C0C0"><font size="1">Parcela</font></td>'
				cMsg += '							<td width="8%" bgcolor="#C0C0C0"><font size="1">Tipo</font></td>'
				cMsg += '							<td width="10%" bgcolor="#C0C0C0"><font size="1">Emiss„o</font></td>'
				cMsg += '							<td width="10%" bgcolor="#C0C0C0"><font size="1">Vencimento</font></td>'
				cMsg += '							<td width="10%" align="right" bgcolor="#C0C0C0"><font size="1">Valor</font></td>'
				cMsg += '							<td align="right" width="10%" bgcolor="#C0C0C0"><font size="1">Saldo</font></td>'
				cMsg += '							<td bgcolor="#C0C0C0"><font size="1">HistÛrico</font></td>'
				cMsg += '						</tr>'
				// Montagem dos Titulos do cliente
				DbGotop()
				While !Eof()
					
					
					cMsg += '						<tr>'
					//		<td width="38"><b><font size="1" color="#006600">NF</font></b></td>
					If (cAliasSE1)->E1_TIPO $ "NCC"
						
						cMsg += '							<td width="8%" height="23"><b><font size="2" color="#006600">'+(cAliasSE1)->E1_PREFIXO+'</font></b></td>'
						cMsg += '							<td width="9%" height="23"><b><font size="2" color="#006600">'+(cAliasSE1)->E1_NUM+'</font></b></td>'
						cMsg += '							<td width="5%" height="23"><b><font size="2" color="#006600">'+(cAliasSE1)->E1_PARCELA+ '</font></b></td>'
						cMsg += '							<td width="8%" height="23"><b><font size="2" color="#006600">'+(cAliasSE1)->E1_TIPO+'</font></b></td>'
						cMsg += '							<td width="10%" height="23"><b><font size="2" color="#006600">'+DTOC((cAliasSE1)->E1_EMISSAO)+'</font></b></td>'
						cMsg += '							<td width="10%" height="23"><b><font size="2" color="#006600">'+DTOC((cAliasSE1)->E1_VENCREA)+'</font></b></td>'
						cMsg += '							<td width="10%" align="right" height="23"><b><font size="2" color="#006600">'+Transform((cAliasSE1)->E1_VALOR,"@E 999,999,999.99")+'</font></b></td>'
						cMsg += '							<td width="10%" align="right" height="23"><b><font size="2" color="#006600">'+Transform((cAliasSE1)->E1_SALDO,"@E 999,999,999.99")+'</font></b></td>'
						cMsg += '							<td height="23"><b><font size="2" color="#006600">'+Alltrim((cAliasSE1)->E1_HIST)+'</font></b></td>'
					Else
						cMsg += '							<td width="8%" height="23"><font size="2">'+(cAliasSE1)->E1_PREFIXO+'</font></td>'
						cMsg += '							<td width="9%" height="23"><font size="2">'+(cAliasSE1)->E1_NUM+'</font></td>'
						cMsg += '							<td width="5%" height="23"><font size="2">'+(cAliasSE1)->E1_PARCELA+ '</font></td>'
						cMsg += '							<td width="8%" height="23"><font size="2">'+(cAliasSE1)->E1_TIPO+'</font></td>'
						cMsg += '							<td width="10%" height="23"><font size="2">'+DTOC((cAliasSE1)->E1_EMISSAO)+'</font></td>'
						cMsg += '							<td width="10%" height="23"><font size="2">'+DTOC((cAliasSE1)->E1_VENCREA)+'</font></td>'
						cMsg += '							<td width="10%" align="right" height="23"><font size="2">'+Transform((cAliasSE1)->E1_VALOR,"@E 999,999,999.99")+'</font></td>'
						cMsg += '							<td width="10%" align="right" height="23"><font size="2">'+Transform((cAliasSE1)->E1_SALDO,"@E 999,999,999.99")+'</font></td>'
						cMsg += '							<td height="23"><font size="2">'+Alltrim((cAliasSE1)->E1_HIST)+'</font></td>'
					Endif
					cMsg += '						</tr>'
					
					cQry := "SELECT DISTINCT ACG_CODIGO "//,ACG_FILIAL,ACG_PREFIX,ACG_PARCEL,ACG_TIPO,ACG_TITULO "
					cQry += "  FROM "+RetSqlName("ACG")
					cQry += " WHERE D_E_L_E_T_ = ' ' "
					cQry += "   AND ACG_TIPO = '"+(cAliasSE1)->E1_TIPO+"' "
					cQry += "   AND ACG_PARCEL = '"+(cAliasSE1)->E1_PARCELA+"' "
					cQry += "   AND ACG_TITULO = '"+(cAliasSE1)->E1_NUM+"' "
					cQry += "   AND ACG_PREFIX = '"+(cAliasSE1)->E1_PREFIXO+"' "
					cQry += "   AND ACG_FILIAL = '"+xFilial("ACG")+"' "
					
					
					TCQUERY cQry NEW ALIAS "QACG"
					
					While !Eof()
						If aScan(aCodACF,QACG->ACG_CODIGO) <= 0
							Aadd(aCodACF,QACG->ACG_CODIGO)
						Endif
						DbSelectArea("QACG")
						DbSkip()
					Enddo
					QACG->(DBCloseArea())
					
					DbSelectArea(cAliasSE1)
					DbSkip()
				Enddo
				(cAliasSE1)->(DbCloseArea())
				
				// Montagem das observaÁıes dos atendimentos
				cMsg += '					</table>'
				cMsg += '					<table border="1" width="100%">'
				cMsg += '						<tr>'
				cMsg += '							<td width="114" bgcolor="#C0C0C0"><font size="1">N∫ Atendimento</font></td>'
				cMsg += '							<td width="83" bgcolor="#C0C0C0"><font size="1">Data</font></td>'
				cMsg += '							<td bgcolor="#C0C0C0"><font size="1">ObservaÁ„o do Atendimento</font></td>'
				cMsg += '						</tr>'
				aSort(aCodACF,,,{|x,y| x < y })
				For iW := 1 To Len(aCodACF)
					DbSelectArea("ACF")
					DbSetOrder(1)
					If DbSeek(xFilial("ACF")+aCodACF[iW])
						
						cMsg += '						<tr>'
						cMsg += '							<td width="114"><font size="1">'+aCodACF[iW]+'</font></td>'
						cMsg += '							<td width="83"><font size="1">'+DTOC(ACF->ACF_DATA)+'</font></td>'
						cMsg += '							<td><font size="1">'+MSMM(ACF->ACF_CODOBS,TamSx3("ACF_OBS")[1])+'</font></td>'
						cMsg += '						</tr>'
					Endif
				Next
				// Zero Variavel
				aCodACF	:= {}
				
				//	cMsg += '						<tr>
				//	cMsg += '							<td width="114"><font size="1">004760</font></td>
				//	cMsg += '							<td width="83"><font size="1">04/08/2011</font></td>
				//	cMsg += '							<td><font size="1">08/07/2011 TODA SEGUNDA FEIRA GLORINHA VAI ESTAR PAGANDO 2.000,00 E NOS VAMOS LIBERAR MAIS 1.000,00</font></td>
				//	cMsg += '						</tr>
				//	cMsg += '						<tr>
				//	cMsg += '							<td width="114"><font size="1">004301</font></td>
				//	cMsg += '							<td width="83"><font size="1">08/07/2011</font></td>
				//	cMsg += '							<td><font size="1">25/10/2010 VAI SER PAGO APENAS NA TER«A FEIRA</font></td>
				//	cMsg += '						</tr>
				cMsg += '					</table>'
				cMsg += '				</td>'
				cMsg += '			</tr>'
				cMsg += '		</table>'
				cMsg += '		<table border="1" width="100%">'
				cMsg += '			<tr>'
				cMsg += '				<td>&nbsp;</td>'
				cMsg += '			</tr>'
				cMsg += '		</table>'
			Endif
			
			If Len(cMsg) > 1000000
				cMsg += '	</body>'
				cMsg += '</html>'
				
				//StaticCall(TMKCFIM,stSendMail,cTo,Alltrim(cSubject)+" Parte "+Alltrim(Str(nPartMail)) ,cMsg)
				
				nPartMail++
				
				cMsg := '<html>'
				cMsg += '	<head>'
				cMsg += '		<meta http-equiv="Content-Language" content="pt-br">'
				cMsg += '		<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">'
				cMsg += '			<title>Cliente/Loja</title>'
				cMsg += '	</head>'
				cMsg += '	<body>'
				cMsg += '		<table border="0" width="100%" cellpadding="0" cellspacing="0" height="30">'
				// Montagem do CabeÁalho do Email informando a Empresa
				cMsg += '			<tr>'
				cMsg += '				<td width="46%"><p align="center"><font size="5"><b>'+AllTrim(SM0->M0_NOMECOM)+'</b></font></td>'
				cMsg += '				<td width="48%" valign="top" height="48" style="border-top: 2 solid #C0C0C0">'
				cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">'+Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT)+'</p>'
				cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">'+Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT+'</p>'
				cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">Fone/Fax: ' + SM0->M0_TEL + ' / ' + SM0->M0_FAX+'</p>'
				cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">CNPJ: ' +Transform(SM0->M0_CGC,"@R 99.999.999/9999-99")+'</p>'
				cMsg += '					<p style="text-indent: 0; word-spacing: 0; line-height: 100%; margin: 0">InscriÁ„o Estadual: ' + SM0->M0_INSC+'</p>'
				cMsg += '               </td>'
				cMsg += '			</tr>'
				cMsg += '		</table>'
				// Montagem do Campo ObservaÁ„o escrita pela Retaguarda
				cMsg += '		<table border="1" width="100%" height="31">'
				cMsg += '			<tr>'
				cMsg += '				<td><b>'+StrTran(cBody,'"',"")+'</b></td>'
				cMsg += '			</tr>'
				cMsg += '		</table>'
				
			Endif
		Next
		
		cMsg += '	</body>'
		cMsg += '</html>'
		
		//StaticCall(TMKCFIM,stSendMail,cTo,Alltrim(cSubject)+" Parte "+Alltrim(Str(nPartMail)) ,cMsg)
		
		MsgStop("Email enviado!","Finalizado!")
		
	Endif
	
	
Return


/*
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥sfPosClien∫Autor  ≥Marcelo Lauschner   ∫ Data ≥22/04/2012   ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Desc.     ≥                                                            ∫±±
±±∫          ≥                                                            ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Uso       ≥ AP                                                         ∫±±
±±»ÕÕÕÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
*/

Static Function sfPosCliente()
	
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3])
	
	Finc010(2) //{STR0003, "FC010CON" , 0 , 2},;  //"Consultar"
	
Return

