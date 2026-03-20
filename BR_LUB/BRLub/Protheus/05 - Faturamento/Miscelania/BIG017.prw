#INCLUDE "topconn.ch"
#include "totvs.ch"

/*/{Protheus.doc} BIG017
(Alterar itens cabeçalho SC5 )
@author MarceloLauschner
@since 20/01/2005
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BIG017(cInPed,nInVlrPed)
	
	
	Local		aAreaOld	:= GetArea()
	Local	 	oDlgAlt,oNumPed,oSenha
	Local		lContinua	:= .F.
	Local	 	cSenhaval 	:= Alltrim(Substr(DTOS(dDatabase),3,2)+Substr(Time(),1,2)+Substr(DTOS(dDatabase),7,2))
	Local	 	cSei 		:= cSenhaval// Space(6)
	// Chamado 26.062 - Liberado acesso para edição do cabeçalho de pedido por que todos pedem para ser inclusos na rotina 
	Private	lIsGerente	:= .T. //__cUserId $ GetNewPar("BF_BIG017G","000000")	// Se for usuário com acesso full aos campos
	Private	lIsCoorden	:= .T. //__cUserId $ GetNewPar("BF_BIG017C","000000")	// Se for usuário com acesso médio
	Private	nVlrPED		:= 0
	Default	cInPed		:= Space(TamSX3("C5_NUM")[1])
	Private aBkC5Cond	:= {}
	Default	nInVlrPed	:= 1
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	nVlrPED	:= nInVlrPed
	
	DEFINE MSDIALOG oDlgAlt Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Alterar dados cabeçalho do pedido") FROM 001,001 TO 150,350 Pixel
	@ 010,018 Say ("Número Pedido") Pixel of oDlgAlt
	@ 010,070 MsGet oNumPed Var cInPed Size 40,10 Picture "@!" Valid ExistCpo("SC5",cInPed) Pixel Of oDlgAlt
	
	//@ 030,018 Say ("Digite a senha-->>") Pixel of oDlgAlt
	//@ 030,070 MsGet oSenha Var cSei Size 40,10 Password Valid(cSei==cSenhaval) Pixel Of oDlgAlt
	
	@ 052,018 BUTTON "Confirma" Size 40,10 Action (IIf(cSei==cSenhaval,lContinua := .T.,Nil),oDlgAlt:End())	Pixel Of oDlgAlt
	@ 052,070 BUTTON "Cancela" Size 40,10 Action (oDlgAlt:End())	Pixel Of oDlgAlt
	
	ACTIVATE MsDialog oDlgAlt Centered
	
	If !lContinua
		RestArea(aAreaOld)
		Return
	Endif
	
	
	If !Empty(cInPed)
		dbselectarea("SC5")
		dbsetorder(1)
		If dbseek(xFilial("SC5")+cInPed)
			If !Empty(SC5->C5_BOX)	.And. __cUserId $ GetMv("BF_USRSERA") .And. !SC5->C5_BLPED $ "P#T" .And. SC5->C5_BANCO == "987" 
				Aadd(aBkC5Cond,Substr(SC5->C5_BOX,1,3))
				Aadd(aBkC5Cond,Substr(SC5->C5_BOX,4,3))				
			Endif
			dbselectarea("SA3")
			dbsetorder(1)
			dbseek(xFilial("SA3")+SC5->C5_VEND1)
			dbselectarea("SE4")
			dbsetorder(1)
			dbseek(xFilial("SE4")+SC5->C5_CONDPAG)
			dbselectarea("SA4")
			dbsetorder(1)
			dbseek(xFilial("SA4")+SC5->C5_TRANSP)
			DbSelectArea("SA6")
			DbSetOrder(1)
			DbSeek(xFilial("SA6")+SC5->C5_BANCO)
			sfAltPed()
		Else
			MsgAlert("Número de pedido inexistente!!!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Não há registro!")
		Endif
		
	Endif
	
Return


/*/{Protheus.doc} sfAltPed
(long_description)
@author MarceloLauschner
@since 30/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static function sfAltPed()
	
	Local		oDlgAlt,oTpFrete,oGroup1,oGroup2,oGroup3,oGroup4,oGroup5,oGroup6,oGroup7,oGroup8,oGroup9
	Local		aAreaOld	:= GetArea()
	Local	 	dDtprogm 	:= date()
	Local	 	cMsgint  	:= Space(100)
	Local	 	cMennota 	:= Space(140)
	Local	 	cAlte 		:= ""
	Local		lContinua	:= .F.
	Local 		lVldTransp	:= SC5->C5_BLPED $ "S#M" // Identifica que o pedido está na Expedição 	
	Local 		lVldEstAvc	:= Iif(SC5->(FieldPos("C5_XESTAVC")) > 0, Empty(SC5->C5_XESTAVC),.T. ) 
	Private 	cCondpag 	:= Space(3)
	Private 	cTpFrete 	:= Space(1)
	Private 	cVend1   	:= Space(6)
	Private 	cVend2   	:= Space(6)
	Private 	cCodBco   	:= Space(3)
	Private 	cTransp  	:= Space(6)
	Private		cOrdCompra	:= Space(TamSX3("C5_XPEDCLI")[1])
	
	
	cTpFrete 	:= SC5->C5_TPFRETE
	cTransp  	:= SC5->C5_TRANSP
	dDtprogm 	:= SC5->C5_DTPROGM
	cCondPag 	:= SC5->C5_CONDPAG
	cOrdCompra	:= SC5->C5_XPEDCLI
	cMsgint		:= SC5->C5_MSGINT
	cMennota	:= SC5->C5_MENNOTA
	If Len(aBkC5Cond) >= 2
		cCondPag	:= aBkC5Cond[1]
		cCodBco		:= aBkC5Cond[2]
	Endif
	
	DEFINE MSDIALOG oDlgAlt Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Alterar dados cabeçalho do pedido "+SC5->C5_NUM) FROM 001,001 TO 540,550 Pixel
	
	// Transportadora somente Perfil de Gerente/Coordenador para alterar 
	oGroup1:= TGroup():New(005,005,032,270,'Transportadora',oDlgAlt,,,.T.)
	@ 015,010 MsGet cTransp Valid (Vazio() .Or. ExistCpo("SA4",cTransp)) F3 "SA4" Size 35,09 Pixel of oGroup1 When (lIsGerente .Or. lIsCoorden) .And. !lVldTransp
	@ 015,065 Say SA4->A4_COD+" - "+SA4->A4_NREDUZ Pixel of oGroup1
	// Chamado 
	If lVldTransp
		@023,015 Say "Pedido já enviado para Expedição - Não é permitido alterar transportadora! Solicite para a Logística!"  Pixel of oGroup1 
	Endif 
	
	// Tipo de Frete somente perfil de Gerente/Coordenador para alterar 
	oGroup2:= TGroup():New(035,005,062,120,'Frete',oDlgAlt,,,.T.)
	@ 045,010 MsCombobox oTpFrete Var cTpFrete Items GetAVPCombo("C5_TPFRETE") of oGroup2 Pixel Size 30,10 When (lIsGerente .Or. lIsCoorden) .And. !lVldTransp
	
	// Banco somente perfil de Gerente/Coordernador para alterar 
	oGroup3:= TGroup():New(035,130,062,270,'Banco',oDlgAlt,,,.T.)
	@ 045,135 MsGet cCodBco Valid (Vazio() .Or. ExistCpo("SA6",cCodBco)) F3 "SA6" Size 20,09 Pixel of oGroup3 When lIsGerente
	@ 046,180 Say SA6->A6_COD+"-"+SA6->A6_NREDUZ Pixel of oGroup3
	
	// Data programada liberada para qualquer usuário 
	oGroup4:= TGroup():New(065,005,092,120,'Data Programada',oDlgAlt,,,.T.)
	@ 075,010 MsGet dDtprogm Size 40,09 Valid (dDtProgm >= dDataBase .Or. dDtprogm == SC5->C5_DTPROGM ) of oGroup4 Pixel When lVldEstAvc
	@ 076,065 Say SC5->C5_DTPROGM Pixel of oGroup4
	
	// Condição de pagamento somente libera se for saldo de pedido, caso contrário será necessário editar o pedido
	// Validação do campo também restringe que somente poderá diminuir o prazo médio e número de parcelas na alteração de saldo de pedido
	If SC5->C5_BANCO == "987" .And. __cUserId $ GetNewPar("BF_USRSERA","000000") .And. MsgYesNo("Deseja alterar o cabeçalho do pedido restaurando à Condição de Pagamento e Banco originais? ")
		// Banco somente perfil de Gerente/Coordernador para alterar 
		oGroup3:= TGroup():New(035,130,062,270,'Banco',oDlgAlt,,,.T.)
		@ 045,135 MsGet cCodBco Valid (Vazio() .Or. ExistCpo("SA6",cCodBco)) F3 "SA6" Size 20,09 Pixel of oGroup3 When .F. 
		@ 046,180 Say SA6->A6_COD+"-"+SA6->A6_NREDUZ Pixel of oGroup3
	
		oGroup5:= TGroup():New(065,130,092,270,'Condição Pagamento',oDlgAlt,,,.T.)
		@ 075,135 MsGet cCondpag Valid (ExistCpo("SE4",cCondpag) .And. U_BFFATM16(cCondPag)) F3 "SE4FIL" Size 30,09 Pixel of oGroup5 When .F. //When (!sfVernf())
		@ 076,180 Say SE4->E4_CODIGO + "-"+SE4->E4_DESCRI Pixel of oGroup5
	Else
		// Banco somente perfil de Gerente/Coordernador para alterar 
		oGroup3:= TGroup():New(035,130,062,270,'Banco',oDlgAlt,,,.T.)
		@ 045,135 MsGet cCodBco Valid (Vazio() .Or. ExistCpo("SA6",cCodBco)) F3 "SA6" Size 20,09 Pixel of oGroup3 When lIsGerente
		@ 046,180 Say SA6->A6_COD+"-"+SA6->A6_NREDUZ Pixel of oGroup3
		
		oGroup5:= TGroup():New(065,130,092,270,'Condição Pagamento',oDlgAlt,,,.T.)
		@ 075,135 MsGet cCondpag Valid (ExistCpo("SE4",cCondpag) .And. U_BFFATM16(cCondPag)) .And. sfVldSE4(cCondPag,SC5->C5_CONDPAG) F3 "SE4FIL" Size 30,09 Pixel of oGroup5 //When (!sfVernf())
		@ 076,180 Say SE4->E4_CODIGO + "-"+SE4->E4_DESCRI Pixel of oGroup5
	
	Endif
	// Vendedor somente se não houve emissão de nota ainda e se for Gerente/Coordenador
	oGroup6:= TGroup():New(095,005,122,120,'Vendedor',oDlgAlt,,,.T.)
	@ 105,010 MsGet cVend1 F3 "SA3" Size 30,09 Valid (Vazio() .Or. ExistCpo("SA3",cVend1)) Pixel of oGroup6 When (sfVernf() .And. (lIsGerente .Or. lIsCoorden))
	@ 105,065 Say SC5->C5_VEND1  Pixel of oGroup6
	
	// Vendedor somente se não houve emissão de nota ainda e se for Gerente/Coordenador
	oGroup7:= TGroup():New(095,130,122,270,'Madrinha',oDlgAlt,,,.T.)	
	@ 105,135 MsGet cVend2 F3 "SA3" Size 30,09 Valid (Vazio() .Or. ExistCpo("SA3",cVend2)) Pixel of oGroup7 When (sfVernf() .And. (lIsGerente .Or. lIsCoorden))
	@ 105,180 Say SC5->C5_VEND2 Pixel of oGroup7
	
	// Mensagem interna liberada para alterações
	oGroup8:= TGroup():New(125,005,162,270,'Mensagem Interna',oDlgAlt,,,.T.)	
	@ 135,010 Say SC5->C5_MSGINT Pixel of oGroup8
	@ 145,010 MsGet cMsgint Size 200,09 Pixel of oGroup8
	
	// Mensagem na nota liberada para alterações
	oGroup9:= TGroup():New(165,005,202,270,'Mensagem nota',oDlgAlt,,,.T.)	
	@ 175,010 Say SC5->C5_MENNOTA Pixel of oGroup9
	@ 185,010 MsGet cMennota size 200,09 Pixel of oGroup9
	
	// Ordem de compra liberada para alterações
	oGroup9:= TGroup():New(205,005,242,120,'Ordem Compra',oDlgAlt,,,.T.)	
	@ 215,010 Say SC5->C5_XPEDCLI Pixel of oGroup9
	@ 225,010 MsGet cOrdCompra size 80,09 Pixel of oGroup9
	
	
	@ 250,080 BUTTON "Confirma" Size 50,10 Action (lContinua := .T.,oDlgAlt:End())	Pixel Of oDlgAlt
	@ 250,135 BUTTON "Cancela" Size 50,10 Action (oDlgAlt:End())	Pixel Of oDlgAlt
	
	
	Activate MsDialog oDlgAlt Centered
	
	If !lContinua
		RestArea(aAreaOld)
		Return
	Endif
	
	If !Empty(cTransp) .And. !ExistCpo("SA4",cTransp,1,Nil,.F.)
		MsgAlert("Transportadora incorreta na alteração!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Inconsistência!")
		Return
	Endif
	
	If !Empty(cCodBco) .And. !ExistCpo("SA6",cCodBco,1,Nil,.F.)
		MsgAlert("Código Banco incorreto na alteração!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Inconsistência!")
		Return
	Endif
	
	If !ExistCpo("SE4",cCondpag,1,Nil,.F.) .Or. !U_BFFATM16(cCondPag)
		MsgAlert("Condição de pagamento incorreta na alteração!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Inconsistência!")
		Return
	Endif
	
	
	
	
	dbSelectArea("SC5")
	RecLock("SC5",.F.)
	If !(cTransp == SC5->C5_TRANSP)
		cAlte += "Transportadora de: " + SC5->C5_TRANSP + " para: " +cTransp +Chr(13)+Chr(10)
		SC5->C5_TRANSP   := cTransp
	Endif
	If !(cTpFrete == SC5->C5_TPFRETE)
		cAlte += "Tipo de frete de: " + SC5->C5_TPFRETE + " para: " + cTpFrete +Chr(13)+Chr(10)
		SC5->C5_TPFRETE  := cTpFrete
	Endif
	If !Empty(cCodBco) .And. SC5->C5_BANCO <> cCodBco
		cAlte += "Banco de: " + SC5->C5_BANCO + " para: " + cCodBco +Chr(13)+Chr(10)
		SC5->C5_BANCO   := cCodBco
	Endif
	If !Empty(cVend1) .And. cVend1 <> SC5->C5_VEND1
		cAlte += "Vendedor1 de: " + SC5->C5_VEND1 + " para: " + cVend1 +Chr(13)+Chr(10)
		SC5->C5_VEND1   := cVend1
		sfVernf(@cAlte)
	Endif
	If !Empty(cVend2) .And. cVend2 <> SC5->C5_VEND2
		cAlte += "Vendedor2 de: " + SC5->C5_VEND2 + " para: " + cVend2 +Chr(13)+Chr(10)
		SC5->C5_VEND2  := cVend2
	Endif
	If cMsgint <> SC5->C5_MSGINT
		cAlte += "Mensagem Interna de:" + SC5->C5_MSGINT + " para: " + cMsgint +Chr(13)+Chr(10)
		SC5->C5_MSGINT  := cMsgint
	Endif
	If cMennota <> SC5->C5_MENNOTA 
		cAlte += "Mensagem Nota: " + SC5->C5_MENNOTA + " para: " + cMennota  +Chr(13)+Chr(10)
		SC5->C5_MENNOTA := cMennota
	Endif
	If cCondpag <> SC5->C5_CONDPAG
		cAlte += "Condição de: " + SC5->C5_CONDPAG + " para: " + cCondpag +Chr(13)+Chr(10)
		SC5->C5_CONDPAG := cCondpag
	Endif
	If SC5->C5_DTPROGM <> dDtprogm
		cAlte += "Data Programada de: " + DTOC(SC5->C5_DTPROGM) + " para: " + DTOC(dDtprogm) +Chr(13)+Chr(10)
		SC5->C5_DTPROGM := dDtprogm
	Endif
	
	If SC5->C5_XPEDCLI <> cOrdCompra
		cAlte += "Ordem de Compra: " + SC5->C5_XPEDCLI + " para: " + cOrdCompra +Chr(13)+Chr(10)
		SC5->C5_XPEDCLI := cOrdCompra
	Endif
	
	SC5->(MSUnLock())
	
	// Grava Log
	U_GMCFGM01("AC",SC5->C5_NUM,cAlte,FunName())
	
	If !Empty(cAlte)
		MsgInfo("Dados Alterados!"+Chr(13)+Chr(10)+cAlte,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação!")
	Else
		MsgInfo("Não houve alteração de dados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Informação!")
	Endif
	
	RestArea(aAreaOld)
	
Return



/*/{Protheus.doc} sfVerNf
(long_description)
@author MarceloLauschner
@since 30/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVerNf(cAlte)
	
	Local		lRet	:= .T.
	Default	cAlte	:= ""
	cQra := ""
	cQra += "SELECT DISTINCT D2_CLIENTE,D2_LOJA,D2_DOC,D2_SERIE"
	cQra += "  FROM "+ RetSqlName("SD2")
	cQra += " WHERE D2_FILIAL = '" + xFilial("SD2") + "' "
	cQra += "   AND D2_PEDIDO = '"+ SC5->C5_NUM +"' "
	cQra += "   AND D_E_L_E_T_ = ' ' "
	
	TCQUERY cQra NEW ALIAS "SEL"
	
	dbSelectArea("SEL")
	dbGoTop()
	While !Eof()
		DbSelectArea("SF2")
		DbSetOrder(1)
		If dbSeek(xFilial("SF2")+SEL->D2_DOC+SEL->D2_SERIE+SEL->D2_CLIENTE+SEL->D2_LOJA)
			cAlte	+= "Nota fiscal: "+SF2->F2_DOC + "/"+SF2->F2_SERIE + " deverá ser alterada o vendedor via chamado!" + Chr(13)+Chr(10)
		Endif
		lRet	:= .F.
		dbSelectArea("SEL")
		dbSkip()
	End
	SEL->(DbCloseArea())
	
Return lRet

/*/{Protheus.doc} sfVldSE4
(long_description)
@author MarceloLauschner
@since 09/02/2015
@version 1.0
@param cInCondNew, character, (Descrição do parâmetro)
@param cInCondOld, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

Static Function sfVldSE4(cInCondNew,cInCondOld)
	
	Local	lRet		:= .T.
	Local	aCondOld	:= Condicao(nVlrPED,cInCondOld,0,dDataBase)
	Local	aCondNew	:= Condicao(nVlrPED,cInCondNew,0,dDataBase)
	Local	nPrzNew	:= 0
	Local	nPrzOld	:= 0
	Local	nNParNew	:= Len(aCondNew)
	Local	nPParOld	:= Len(aCondOld)
	Local	nX	
	// Calcula Prazo Médio da condição pagamento antiga
	For nX := 1 To nPParOld
		nPrzOld 	+= aCondOld[nX][1] - dDatabase		
	Next
	nPrzOld	:= Int(nPrzOld/nPParOld)
	
	// Calcula Prazo Médio da nova condição de pagamento
	For nX := 1 To nNParNew
		nPrzNew 	+= aCondNew[nX][1] - dDatabase	
		// Chamado 12098 - Verifica se o valor por parcela não fica abaixo do mínimo
		//If aCondNew	[nX][2] < GetNewPar("BF_VMINDUP",250)
		//	MsgAlert("Não é permitida a alteração para uma condição de pagamento em que o valor da parcela fique abaixo de R$ " + Transform(GetNewPar("BF_VMINDUP",250),"@E 999,999.99") + "!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Condição inválida")
		//	lRet	:= .F.
		//Endif
	Next
	nPrzNew	:= Int(nPrzNew/nNParNew)
	
	// Verifica se a nova condição de pagamento tem mais parcelas do que a anterior 
	If !lIsCoorden .And. nNParNew > nPParOld
		MsgAlert("Não é permitida a alteração para uma condição de pagamento com MAIS PARCELAS do que a condição antiga!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Condição inválida")
		lRet	:= .F. 
	Endif 
	
	If nPrzNew > nPrzOld
		MsgAlert("Não é permitida a alteração para uma condição de pagamento com PRAZO MÉDIO maior do que a condição antiga!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Condição inválida")
		lRet	:= .F.	
	Endif 
	
Return lRet
