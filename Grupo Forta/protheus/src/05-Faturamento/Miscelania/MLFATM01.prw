#include "totvs.ch"
#include "tbiconn.ch"

user function MLFATM01(aparam)

	Private __LFRTCOUNTLICENSE := .F.

	Default aparam := {"01","0201"} // caso nao receba nenhum parametro

	dDtAtu 	:= Date()
	lRet 	:= LockByName("MLFATM01",.T.,.F.,.T.)

	If lRet

		Conout("***[Inicio GETPVC "+time()+"]************************************************************************")

		fGetPvc()		

		Conout("***[Fim GETPVC "+time()+"]****************************************************************************")

	Else
		msgInfo("rotina em execução ainda ")
		Conout("*****[Job GETPVC ja esta em execucao]***********************************************")  			
	Endif


Return

Static Function fGetPvc()

	Local cURL		         := SuperGetMv("CD_RESTCLI", .F., "http://condor1.ajili.com.br")
	local aHeader            := {}
	local aHeadOut           := {}
	local cHeaderGet         := ""
	local cAcesso            := "/api/pedidos/no-id-erp-with-items?api_key=$2a$10$ExnTdKv5KLjbZYi8TUe4wOvVL/j.4Ef7FQqOIj7JwU1wTHOkn/hUi"
	Local xRet                                     
	Local oObjJson
	Local cGetParms          := ""
	Local nTimeOut 			 := 120
	Local nTypeStamp		 := 4					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
	local wrk
	Local _I                 := 0
	Local nPosAchou          := 0
	Local nPosInicial        := 1 
	Local oJson := Nil
	Local lRet               := .F.
	Local lPrimeira:= .T.
	//Cabeçalho
	Private cFIniPed := '"order" :'
	Private cFNumPed := '"id" :'
	Private cNumPed  := ""
	Private cFCodCli := '"customerId" :'
	Private cCodCli  := ""
	Private cFVend   := '"salesmanId" :'
	Private cCodVend := ""
	Private cFCondPag:= '"paymentTermsId" :'
	Private cCondPag := ""
	Private cFFormPag:= '"paymentFormsId" :'
	Private cFormPag := ""
	Private cFTabPrec:= '"pricingTableId" :'
	Private cTabPreco:= ""
	//Itens
	Private cFIniProd:= '"items" : ['
	Private cFSales  := '"salesOrderId" :'
	Private cFCodProd:= '"productId" :'
	Private cCodProd := ""
	Private cFQtde   := '"quantity" :'
	Private cQtde    := ""
	Private cFValUnit:= '"unitValue" :'
	Private cValUnit := ""
	Private cRetorno := ""
	Private cNPedido := ""
	Private oParseJSON 	:= Nil
	
	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cRetorno := HttpGet( cUrl+cAcesso , cGetParms, nTimeOut, aHeader, @cHeaderGet )
	
	While .T.

		nPosAchou   := AT(cFIniPed,cRetorno,nPosInicial)

		If nPosAchou==0  
			MsgInfo("achou 0 caiu fora 86")
			Exit
		EndIf

		nPosInicial := nPosAchou
		nPosAchou   := AT(cFNumPed,cRetorno,nPosInicial)
		nPosInicial := nPosAchou+7
		cNumPed     := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

		nPosAchou   := AT(cFCodCli,cRetorno,nPosInicial)
		nPosInicial := nPosAchou+15
		cCodCli     := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

		nPosAchou   := AT(cFVend,cRetorno,nPosInicial)
		nPosInicial := nPosAchou+15
		cCodVend    := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

		nPosAchou   := AT(cFCondPag,cRetorno,nPosInicial)
		nPosInicial := nPosAchou+19
		cCondPag    := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

		nPosAchou   := AT(cFTabPrec,cRetorno,nPosInicial)
		nPosInicial := nPosAchou+19
		cTabPreco   := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

		nPosAchou   := AT(cFIniProd,cRetorno,nPosInicial)

		If nPosAchou==0  
			MsgInfo("não achou 0 caiu fora 114")
			loop
		EndIf

		aItensPV    :={}

		While .T.

			nPosBkp     := nPosInicial
			nPosAchou   := AT(cFSales,cRetorno,nPosInicial)
			nPosInicial := nPosAchou+17
			cNPedido    := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

			If cNumPed <> cNPedido 
				nPosInicial := nPosBkp
				GeraPedido()
				Exit
			EndIf

			nPosAchou   := AT(cFCodProd,cRetorno,nPosInicial)
			nPosInicial := nPosAchou+14
			cCodProd    := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

			nPosAchou   := AT(cFQtde,cRetorno,nPosInicial)
			nPosInicial := nPosAchou+13
			cQtde       := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

			nPosAchou   := AT(cFValUnit,cRetorno,nPosInicial)
			nPosInicial := nPosAchou+14
			cValUnit    := Substr(cRetorno,nPosInicial,fFim(nPosInicial))

			AADD(aItensPV,{Val(cCodProd),Val(cQtde),Val(cValUnit)})

		End   

	End

Return


Static Function GeraPedido()

	// Local cDoc     := GetSxeNum("SC5", "C5_NUM")
	Local aCabec   := {}
	Local aItens   := {}
	Local aLinha   := {}
	Local xA1Cod   := ""
	Local xA1Loja  := ""
	Local xE4Codigo:= ""
	Local nX       := 0
	Local xB1Cod   := ""
	Local cF4TES   := SuperGetMv("MV_XTESWEB",.F.,"501")
	Local xB1Cod   := ""
	Local xQtde    := 0.000      
	Local xValUnit := 0.00
	Local xTotVal  := 0.00
	Local lMsErroAuto := .F.
	Local aErroAuto := {}
	Local cLogErro := ""
	Local nCount   := 0
	Local cFilBkp  := cFilAnt
	Local _xFilial

	xDA0Codigo:= fBusca(Val(cTabPreco),"DA0","DA0_CODTAB","","DA0_IDAJIL")
	xDA0ZimPem:= fBusca(Val(cTabPreco),"DA0","DA0_ZIMPEM","","DA0_IDAJIL")

	_xFilial := xDA0ZimPem 

	If _xFilial <>'0101'
		cFilBkp := cFilAnt
		cFilAnt := _xFilial 
	EndIf 

	xA1Cod    := Substr(fBusca(Val(cCodCli),"SA1","A1_COD","A1_LOJA","A1_IDAJILI"),1,6) 
	xA1Loja   := Substr(fBusca(Val(cCodCli),"SA1","A1_COD","A1_LOJA","A1_IDAJILI"),7,2)
	xE4Codigo := fBusca(Val(cCondPag),"SE4","E4_CODIGO","","E4_IDAJILI")

	// aadd(aCabec, {"C5_NUM",     cDoc,      Nil})
	aadd(aCabec, {"C5_TIPO",    "N",        Nil})
	aadd(aCabec, {"C5_CLIENTE", xA1Cod,     Nil})
	aadd(aCabec, {"C5_LOJACLI", xA1Loja,    Nil})
	aadd(aCabec, {"C5_LOJAENT", xA1Loja,    Nil})
	aadd(aCabec, {"C5_CONDPAG", xE4Codigo,  Nil})
	aadd(aCabec, {"C5_TABELA",  xDA0Codigo, Nil})

	For nX := 1 To Len(aItensPV)

		xB1Cod   := fBusca(aItensPV[nX][1],"SB1","B1_COD","","B1_IDAJILI")
		xQtde    := aItensPV[nX][2]      
		xValUnit := aItensPV[nX][3]
		xTotVal  := xQtde * xValUnit

		aLinha := {}
		aadd(aLinha,{"C6_ITEM"   , StrZero(nX,2) , Nil})
		aadd(aLinha,{"C6_PRODUTO", xB1Cod        , Nil})
		aadd(aLinha,{"C6_QTDVEN" , xQtde         , Nil})
		aadd(aLinha,{"C6_PRCVEN" , xValUnit      , Nil})
		aadd(aLinha,{"C6_PRUNIT" , xValUnit      , Nil})
		aadd(aLinha,{"C6_VALOR"  , xTotVal       , Nil})
		aadd(aLinha,{"C6_TES"    , cF4TES        , Nil})
		aadd(aItens, aLinha)

	Next nX

	nOpcX := 3
	MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

	If !lMsErroAuto
		ConfirmSx8()
		dbSelectArea("SC5")
		dbGoBottom()
		ConOut("Incluido com sucesso! " + SC5->C5_NUM)
	Else
		ConOut("Erro na inclusao!")
		aErroAuto := GetAutoGRLog()
		For nCount := 1 To Len(aErroAuto)
			cLogErro += StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " "
			ConOut(cLogErro)
		Next nCount
	EndIf

	If cFilAnt<>"0101" 
		cFilAnt := cFilBkp
	EndIf

Return

Static Function fFim(nPosInicial)

	Local _k         := 0
	Local nQtdeLetra := 0

	For _k := nPosInicial to Len(cRetorno)

		If Substr(cRetorno,_k,1)==","
			nQtdeLetra := _k -  nPosInicial
			Exit
		EndIf

	Next _k

Return nQtdeLetra


Static Function fBusca(nId,cTabela,cCampo1,cCampo2,cCompara)

	Local cQuery := ""
	Local xAlias := GetNextAlias()

	cQuery := " SELECT "+AllTrim(cCampo1)+IIF(!Empty(cCampo2),", "+AllTrim(cCampo2)+" "," ")+"FROM "+RetSqlName(cTabela)+" cAlias "
	cQuery += " WHERE D_E_L_E_T_='' "
	cQuery += " AND "+AllTrim(cCompara)+" = "+Str(nId,11,0)+" "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQuery),xAlias, .F., .T.)
	dbSelectArea(xAlias)

	If (xAlias)->(!Eof())
		cCampo1 := (xAlias)->&(cCampo1) 
		cCampo2 := IIF(!Empty(cCampo2),(xAlias)->&(cCampo2),"")
	Else
		cCampo1 := ""
		cCampo2 := ""
	EndIf

Return(cCampo1+cCampo2)