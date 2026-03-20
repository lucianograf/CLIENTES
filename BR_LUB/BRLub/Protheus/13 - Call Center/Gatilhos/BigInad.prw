#Include 'Protheus.ch'
#Include 'TopConn.ch'

/*/{Protheus.doc} BigInad
(Envia alertas para usuario avisando se o cliente informado
BigInad  	Possui titulos com atraso
sfSalPed 	Possui saldo de pedido
sfCreDev   	Possui credito de devolucao)

@author MarceloLauschner
@since 04/12/2013
@version 1.0

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function BigInad()

Return sfTelaCli()

/***************************************************** DESATIVADO
	Local	aAreaOld	:=	GetArea()
	Local	cCdCli		:=	StrTran(M->UA_CLIENTE,"'","")
	Local	cLoja		:=	M->UA_LOJA
	Local	cQry		:=  ""
	Local	lRet		:= .T.

	// Não é necessário gerar avisos e alertas se a rotina for automática
	If !IsBlind()

	cQry += "SELECT SUM(E1_SALDO+E1_SDACRES-E1_SDDECRE) NVALOR "
	cQry += "  FROM " + RetSqlName("SE1")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND E1_TIPO != 'NCC' "
	cQry += "   AND E1_SALDO > 0 "
	cQry += "   AND E1_VENCREA < TO_CHAR(SYSDATE,'YYYYMMDD') "
	cQry += "   AND E1_LOJA = '"+cLoja+ "'"
	cQry += "   AND E1_CLIENTE = '"+cCdCli +"' "
	cQry += "   AND E1_FILIAL = '" + xFilial("SE1") +"'"

	TCQUERY cQry NEW ALIAS "QRY"

	If QRY->NVALOR > 0
	MsgInfo("Cliente Inadimplente! Possui o valor em atraso de R$" + Transform(QRY->NVALOR,"@E 999,999.99"))
	EndIf
	QRY->(DbCloseArea())

	// Verifica o saldo de pedidos em aberto do cliente
	sfSalPed(cCdCli,cLoja)

	// Posiciona no cliente e verifica se possui direito ao pagamento de tampinhas
	dbselectarea("SA1")
	Dbsetorder(1)
	DbSeek(xFilial("SA1")+cCdCli+cLoja)

	// Se o cliente for Texaco ou Wynns Customizado
	If SA1->A1_REEMB $ "T#W"
	// Se for customizado procura na SZ8
	sfPagTamp(cCdCli,cLoja)
	Endif

	// 20/10/2015 - Adicionada verificação se o cliente tem restrição de bloqueio de venda
	If SA1->A1_BLOQCAD <> "1"
	//1=Ativo;2=Inadimp/Bloq Fin;3=Faliu/Fechou;4=Posto Bandeirado;5=Nao Compra Oleos;6=Cadastro Incorreto;7=Outro Cadastro;8=Texaco
	aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_BLOQCAD', 'X3CBox()' ),,, Len(SA1->A1_BLOQCAD) )
	cRet	:= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_BLOQCAD} ), 3 ])
	If IsBlind()
	lRet	:= .T.
	Else
	lRet := MsgNoYes("Bloqueio: " + cRet + Chr(13)+ Chr(10) + Chr(13)+ Chr(10) + " Observação: " + SA1->A1_OBSCLI + Chr(13)+ Chr(10) + "Deseja continuar assim mesmo??",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " Bloqueio cadastro!")
	Endif
	Endif

	// 11/11/2015 - Adicionada verificação
	If SA1->A1_GERAT $ "B#T#E#F"
	//D=Direto;I=Indireto;B=Bloqueado;T=Texaco;E=Excluídos;F=Filial;M=Email Marketing
	aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_GERAT', 'X3CBox()' ),,, Len(SA1->A1_GERAT) )
	cRet	:= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_GERAT} ), 3 ])
	If IsBlind()
	lRet	:= .T.
	Else
	lRet := MsgNoYes("Vend.ou Tmk? : " + cRet + Chr(13)+ Chr(10) + Chr(13)+ Chr(10) + " Observação: " + SA1->A1_OBSCLI + Chr(13)+ Chr(10) + "Deseja continuar assim mesmo??",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " Bloqueio cadastro!")
	Endif
	Endif

	Endif

	RestArea(aAreaOld)

Return lRet
***********************************************************/

/*/{Protheus.doc} sfSalPed
(Envia alertas para usuario avisando se o cliente informado)

@author Odair Garcia Arouca
@since 10/07/2007
@version 1.0

@param cCdCli, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
/*
Static Function sfSalPed(cCdCli,cLoja)

	Local	cQry	:= ""

	cQry += "SELECT COUNT(DISTINCT(C5_NUM)) NPEDIDOS "
	cQry += "  FROM "+ RetSqlName("SC5") + " C5,"+RetSqlName("SC6") + " C6 "
	cQry += " WHERE C6.D_E_L_E_T_ = ' ' "
	cQry += "   AND C6_NUM = C5_NUM "
	cQry += "   AND C6_BLQ NOT IN('S','R') "
	cQry += "   AND C6_QTDVEN > C6_QTDENT "
	cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"'"
	cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_NOTA = '"+Space(TamSx3("C5_NOTA")[1])+"' "
	cQry += "   AND C5_LOJACLI = '"+cLoja+"'"
	cQry += "   AND C5_CLIENTE = '" + cCdCli+"' "
	cQry += "   AND C5_FILIAL = '"+ xFilial("SC5")+"' "

	TCQUERY cQry NEW ALIAS "QRY"

	If	QRY->NPEDIDOS > 0 .And. !IsBlind()
		MsgInfo("Este cliente possui " + Transform(QRY->NPEDIDOS,"@E 99999")+" pedidos com saldo.")
	EndIf
	QRY->(DbCloseArea())

	sfCreDev(cCdCli,cLoja)

Return
*/
/*/{Protheus.doc} sfCreDev
(Envia alertas para usuario avisando se o cliente informado)

@author Odair Garcia Arouca
@since 10/07/2007
@version 1.0

@param cCdCli, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
/*
Static Function sfCreDev(cCdCli,cLoja)

	Local	cQry  := ""

	cQry += "SELECT COUNT(E1_PREFIXO || E1_NUM || E1_PARCELA) NTITULOS,SUM(E1_SALDO) NVALOR "
	cQry += "  FROM " + RetSqlName("SE1")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND E1_TIPO = 'NCC' "
	cQry += "   AND E1_SALDO > 0 "
	cQry += "   AND E1_LOJA = '"+cLoja+ "'"
	cQry += "   AND E1_CLIENTE = '"+cCdCli +"' "
	cQry += "   AND E1_FILIAL = '" + xFilial("SE1") +"'"

	TCQUERY cQry NEW ALIAS "QRY"

	If QRY->NTITULOS > 0 .And. !IsBlind()
		MsgInfo("Este cliente possui "+ Transform(QRY->NTITULOS,"@E 99999")+" Titulos de crédito para devolução no valor de R$ " + Transform(QRY->NVALOR,"@E 999,999.99") )
	EndIf
	QRY->(DbCloseArea())

Return
*/
/*/{Protheus.doc} sfPagTamp
(Avisa se cliente trabalha com tampinhas	)

@author  Christian Daniel Costa
@since 04/12/2013
@version 1.0

@param cCdCli, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
/*
Static Function sfPagTamp(cCdCli,cLoja)

	Local	cQry	:= ""

	cQry += "SELECT COUNT(DISTINCT(Z8_CODPROD)) NPRODUTOS "
	cQry += "  FROM "+ RetSqlName("SZ8")
	cQry += " WHERE D_E_L_E_T_ = ' '
	cQry += "   AND '" + DTOS(dDataBase) + "' BETWEEN Z8_DATCAD AND Z8_DATFIM "
	cQry += "   AND Z8_LOJA = '"+cLoja+"' "
	cQry += "   AND Z8_REEMB = '" + SA1->A1_REEMB + "'"
	cQry += "   AND Z8_CLIENTE = '" + cCdCli+"' "
	cQry += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "

	TCQUERY cQry NEW ALIAS "QRY"

	If	QRY->NPRODUTOS > 0
		MsgInfo("Cliente tem pagamento de tampinha!!")
	EndIf

	QRY->(DbCloseArea())

Return
*/









/*/{Protheus.doc} sfTelaCli
(Nova tela para apresentar todos os alertas possíveis na customização BIGINAD)
@type function
@author Iago Luiz Raimondi
@since 11/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTelaCli()

	Local oDlgCl
	Local aArea	 :=	GetArea()
	Local aAreaCl := GetArea("SB1")
	Local cRestr := ""
	Local cObser := ""
	Local aVenc	 := {}
	Local aAber	 := {}
	Local aTamp	 := {}
	Local lOk	 := .F.
	Local lErro	 := .F.

	dbselectarea("SA1")
	dbSetOrder(1)
	dbSeek(xFilial("SA1")+M->UA_CLIENTE+M->UA_LOJA,.T.)

	Private cClie	:= SA1->A1_COD
	Private cLoja	:= SA1->A1_LOJA
	Private cReemb	:= SA1->A1_REEMB


	If !Empty(SA1->A1_OBSCLI)
		lErro := .T.
		cObser := SA1->A1_OBSCLI
	Else
		cObser := "NENHUMA"
	EndIf

	If SA1->A1_BLOQCAD <> "1"
		lErro := .T.
		//1=Ativo;2=Inadimp/Bloq Fin;3=Faliu/Fechou;4=Posto Bandeirado;5=Nao Compra Oleos;6=Cadastro Incorreto;7=Outro Cadastro;8=Texaco
		aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_BLOQCAD', 'X3CBox()' ),,, Len(SA1->A1_BLOQCAD) )
		cRestr	+= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_BLOQCAD} ), 3 ])
	Endif

	If SA1->A1_GERAT $ "B#T#E#F"
		lErro := .T.
		//D=Direto;I=Indireto;B=Bloqueado;T=Texaco;E=Excluídos;F=Filial;M=Email Marketing
		aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_GERAT', 'X3CBox()' ),,, Len(SA1->A1_GERAT) )
		If !Empty(cRestr)
			cRestr += chr(13)+ chr(10)
		EndIf
		cRestr	+= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_GERAT} ), 3 ])
	Endif

	If !Empty(SA1->A1_GRPVEN)

		If !Empty(cRestr)
			cRestr += chr(13)+ chr(10)
		EndIf
		DbSelectArea("ACY")
		DbSetOrder(1)
		DbSeek(xFilial("ACY")+SA1->A1_GRPVEN)
		cRestr += "Grupo Clientes: " + ACY->ACY_DESCRI
		lErro := .T.
	Endif
	If Empty(cRestr)
		cRestr := "NENHUMA"
	EndIf

	// Valida tudo e verifica se deve montar a tela ou não.
	aVenc 	:= sfTitVenc(cClie,cLoja)
	If Len(aVenc) > 0
		lErro := .T.
	EndIf
	aAber 	:= sfPedAber(cClie,cLoja)
	If Len(aAber) > 0
		lErro := .T.
	EndIf
	aTamp 	:= sfTampin(cClie,cLoja,cReemb)
	If Len(aTamp) > 0
		lErro := .T.
	EndIf
	// Se não houve nenhuma alteração para mostrar mensagem, fecha a rotina
	If !lErro
		lOk	 := .T.
		RestArea(aArea)
		RestArea(aAreaCl)

		Return lOk
	Endif


	DEFINE DIALOG oDlgCl TITLE "Dados Cliente" FROM 000,000 TO 410,720 PIXEL

	oPanelAll:= TPanel():New(0,0,"",oDlgCl,,.F.,.F.,,,200,200,.T.,.F.)
	oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT

	oFont := TFont():New('Courier new',,-14,.T.)

	//Motivo Bloqueio Restrição Venda
	oSay1	:= TSay():New(001,005,{||'Restrição venda:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
	oSay2	:= TSay():New(010,005,{||cRestr},oPanelAll,,,,,,.T.,,,400,20)


	//Observação Cliente
	oSay3	:= TSay():New(030,005,{||'Observações:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
	oSay4	:= TSay():New(040,005,{||cObser},oPanelAll,,,,,,.T.,,,400,20)


	//Titulos Vencidos
	oSay5	:= TSay():New(060,005,{||'Títulos vencidos / Créditos:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
	nList1 	:= 1
	oList1 	:= TListBox():New(070,001,{|u|if(Pcount()>0,nList1 := u,nList1)},aVenc,180,50,,oPanelAll,,,,.T.)

	//Pedidos Aberto
	oSay6	:= TSay():New(060,185,{||'Pedidos em aberto:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
	nList2 	:= 1
	oList2 	:= TListBox():New(070,180,{|u|if(Pcount()>0,nList2 := u,nList2)},aAber,180,50,,oPanelAll,,,,.T.)

	//Tampinha
	oSay7	:= TSay():New(130,005,{||'Pagamento Tampa:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
	nList3 	:= 1
	oList3 	:= TListBox():New(140,001,{|u|if(Pcount()>0,nList3 := u,nList3)},aTamp,360,50,,oPanelAll,,,,.T.)

	ACTIVATE DIALOG oDlgCl CENTERED ON INIT (EnchoiceBar(oDlgCl,{||lOk := .T.,oDlgCl:End()},{||oDlgCl:End()}))

	If !IsBlind()
		If SA1->A1_BLOQCAD $ "3#6" // //1=Ativo;2=Inadimp/Bloq Fin;3=Faliu/Fechou;4=Posto Bandeirado;5=Nao Compra Oleos;6=Cadastro Incorreto;7=Outro Cadastro;8=Texaco
			lOk	:= .F.
		Endif
	Endif
	
	RestArea(aArea)
	RestArea(aAreaCl)

Return lOk


/*/{Protheus.doc} sfTitVenc
(Busca titulos vencidos e crédito de dev.)
@type function
@author Iago Luiz Raimondi
@since 11/10/2016
@version 1.0
@param cCliente, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTitVenc(cCliente,cLoja)

	Local aRet := {}
	Local cQry := ""

	/********************************/
	/*          VENCIDOS            */
	/********************************/

	cQry += "SELECT E1_NUM AS NUMERO,E1_VENCREA AS VENCTO,E1_SALDO+E1_SDACRES-E1_SDDECRE AS SALDO "
	cQry += "  FROM " + RetSqlName("SE1")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND E1_TIPO != 'NCC' "
	cQry += "   AND E1_SALDO > 0 "
	cQry += "   AND E1_VENCREA < TO_CHAR(SYSDATE,'YYYYMMDD') "
	cQry += "   AND E1_LOJA = '"+ cLoja +"'"
	cQry += "   AND E1_CLIENTE = '"+ cCliente +"' "
	cQry += "   AND E1_FILIAL = '" + xFilial("SE1") +"'"

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	TCQUERY cQry NEW ALIAS "QRY"

	While QRY->(!EOF())
		Aadd(aRet,"Título: "+ cValToChar(QRY->NUMERO) +" Vencimento: "+ DtoC(StoD(QRY->VENCTO)) +" Saldo: R$ "+ Alltrim(Transform(QRY->SALDO,"@E 999,999,999.99")))
		QRY->(dbSkip())
	End

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	/********************************/
	/*          CREDITOS            */
	/********************************/

	cQry := ""
	cQry += "SELECT E1_NUM AS NUMERO, E1_SALDO SALDO "
	cQry += "  FROM " + RetSqlName("SE1")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND E1_TIPO = 'NCC' "
	cQry += "   AND E1_SALDO > 0 "
	cQry += "   AND E1_LOJA = '"+ cLoja + "'"
	cQry += "   AND E1_CLIENTE = '"+ cCliente +"' "
	cQry += "   AND E1_FILIAL = '" + xFilial("SE1") +"'"

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	TCQUERY cQry NEW ALIAS "QRY"

	While QRY->(!EOF())
		Aadd(aRet,"Título: "+ cValToChar(QRY->NUMERO) +" Crédito Dev.: R$ "+ Alltrim(Transform(QRY->SALDO,"@E 999,999.99")))
		QRY->(dbSkip())
	End

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

Return aRet


/*/{Protheus.doc} sfPedAber
(Busca pedidos em aberto)
@type function
@author Iago Luiz Raimondi
@since 11/10/2016
@version 1.0
@param cCliente, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfPedAber(cCliente,cLoja)

	Local aRet := {}
	Local cQry := ""

	cQry += "SELECT C5_NUM AS NUMERO,C6_PRODUTO AS PRODUTO, C6_QTDVEN - C6_QTDENT AS QTD  "
	cQry += "  FROM "+ RetSqlName("SC5") + " C5,"+RetSqlName("SC6") + " C6 "
	cQry += " INNER JOIN "+ RetSqlName("SB1") +" B1 ON B1.B1_FILIAL = C6.C6_FILIAL"
	cQry += "					 				   AND B1.B1_COD = C6.C6_PRODUTO"
	cQry += "					 				   AND B1.D_E_L_E_T_ = ' '"
	cQry += " WHERE C6.D_E_L_E_T_ = ' ' "
	cQry += "   AND C6_NUM = C5_NUM "
	cQry += "   AND C6_BLQ NOT IN('S','R') "
	cQry += "   AND C6_QTDVEN > C6_QTDENT "
	cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"'"
	cQry += "   AND C5.D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_LOJACLI = '"+cLoja+"'"
	cQry += "   AND C5_CLIENTE = '" + cCliente+"' "
	cQry += "   AND C5_FILIAL = '"+ xFilial("SC5")+"' "

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	TCQUERY cQry NEW ALIAS "QRY"

	While QRY->(!EOF())
		Aadd(aRet,"Pedido: "+ QRY->NUMERO +" Produto: "+ QRY->PRODUTO +" Quantidade: "+ cValToChar(QRY->QTD))
		QRY->(dbSkip())
	End

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

Return aRet


/*/{Protheus.doc} sfTampin
(Busca produtos que paga tampinha)
@type function
@author iago.raimondi
@since 11/10/2016
@version 1.0
@param cCliente, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)
@param cReemb, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTampin(cCliente,cLoja,cReemb)

	Local aRet := {}
	Local cQry := ""

	cQry += "SELECT Z8_CODPROD||B1.B1_DESC AS PRODUTO,Z8_DATCAD AS INICIO, Z8_DATFIM AS FIM"
	cQry += "  FROM "+ RetSqlName("SZ8") +" Z8"
	cQry += " INNER JOIN "+ RetSqlName("SB1") +" B1 ON B1.B1_FILIAL = Z8.Z8_FILIAL"
	cQry += "					 				   AND B1.B1_COD = Z8.Z8_CODPROD"
	cQry += "					 				   AND B1.D_E_L_E_T_ = ' '"
	cQry += " WHERE Z8.D_E_L_E_T_ = ' '"
	cQry += "   AND '" + DTOS(dDataBase) + "' BETWEEN Z8.Z8_DATCAD AND Z8.Z8_DATFIM "
	cQry += "   AND Z8.Z8_LOJA = '"+cLoja+"' "
	cQry += "   AND Z8.Z8_REEMB = '" + cReemb + "'"
	cQry += "   AND Z8.Z8_CLIENTE = '" + cCliente+"' "
	cQry += "   AND Z8.Z8_FILIAL = '" + xFilial("SZ8") + "'"

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

	TCQUERY cQry NEW ALIAS "QRY"

	While QRY->(!EOF())
		Aadd(aRet,"Produto: "+ QRY->PRODUTO +" Inicío: "+ DtoC(StoD(QRY->INICIO)) +" Fim: "+ DtoC(StoD(QRY->FIM)))
		QRY->(dbSkip())
	End

	If (Select("QRY") <> 0)
		QRY->(dbCloseArea())
	Endif

Return aRet
