#Include 'totvs.ch'
#Include 'TopConn.ch'
/*/{Protheus.doc} U_MLTMKG01
Interface com alerta ao usuário sobre dados do Cliente
@type function
@version
@author Marcelo Alberto Lauschner
@since 01/10/2020
@return return_type, return_description
/*/
Function U_MLTMKG01()

    Local oDlgCl
    Local aArea	    :=	GetArea()
    Local aAreaCl   := GetArea("SB1")
    Local cRestr    := ""
    Local cObser    := ""
    Local aVenc	    := {}
    Local aAber	    := {}
    Local lOk	    := .F.
    Local lErro	    := .F.

    // Verifico se é rotina automática para não gerar interface
    If Type("l410Auto") <> "U" .And. l410Auto
       lOk	 := .T.
        RestArea(aArea)
        RestArea(aAreaCl)
        Return lOk
    Endif 

    dbselectarea("SA1")
    dbSetOrder(1)
    dbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,.T.)

    Private cClie	:= SA1->A1_COD
    Private cLoja	:= SA1->A1_LOJA


    If !Empty(SA1->A1_OBSMEMO)
        lErro := .T.
        cObser := SA1->A1_OBSMEMO
    Else
        cObser := "NENHUMA"
    EndIf

    If SA1->A1_ZSTS <> "  "
        lErro := .T.
        aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_ZSTS', 'X3CBox()' ),,, Len(SA1->A1_ZSTS) )
        cRestr	+= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_ZSTS} ), 3 ])
    Endif

    If !Empty(SA1->A1_GRPVEN)

        If !Empty(cRestr)
            cRestr += CRLF
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

    // Se não houve nenhuma alteração para mostrar mensagem, fecha a rotina
    If !lErro
        lOk	 := .T.
        RestArea(aArea)
        RestArea(aAreaCl)
        Return lOk
    Endif


    DEFINE DIALOG oDlgCl TITLE "Alerta sobre dados do Cliente" FROM 000,000 TO 410,720 PIXEL

    oPanelAll:= TPanel():New(0,0,"",oDlgCl,,.F.,.F.,,,200,200,.T.,.F.)
    oPanelAll:Align := CONTROL_ALIGN_ALLCLIENT

    oFont := TFont():New('Courier new',,-14,.T.)

    //Motivo Bloqueio Restrição Venda
    oSay1	:= TSay():New(001,005,{||'Restrição venda:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
    oSay2	:= TSay():New(010,005,{||cRestr},oPanelAll,,,,,,.T.,,,400,20)

    //Observação Cliente
    oSay3	:= TSay():New(030,005,{||'Observações:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
    oSay4	:= TSay():New(040,005,{||cObser},oPanelAll,,,,,,.T.,,,400,70)


    //Titulos Vencidos
    oSay5	:= TSay():New(110,005,{||'Títulos Vencidos / Créditos:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
    nList1 	:= 1
    oList1 	:= TListBox():New(120,001,{|u|if(Pcount()>0,nList1 := u,nList1)},aVenc,180,50,,oPanelAll,,,,.T.)

    //Pedidos Aberto
    oSay6	:= TSay():New(110,185,{||'Pedidos em aberto:'},oPanelAll,,oFont,,,,.T.,CLR_RED,,200,20)
    nList2 	:= 1
    oList2 	:= TListBox():New(120,180,{|u|if(Pcount()>0,nList2 := u,nList2)},aAber,180,50,,oPanelAll,,,,.T.)

    
    ACTIVATE DIALOG oDlgCl CENTERED ON INIT (EnchoiceBar(oDlgCl,{||lOk := .T.,oDlgCl:End()},{||oDlgCl:End()},/*lMsgDel*/,/*aButtons*/,/*nRecno*/,/*cAlias*/,.F./*lMashups*/,.F./*lImpCad*/,.F./*lPadrao*/,/*lHasOk*/,.F./*lWalkThru*/))

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
    cQry += "   AND E1_TIPO NOT IN('NCC','RA') "
    cQry += "   AND E1_SALDO > 0 "
    cQry += "   AND E1_VENCREA < '" + DTOS(Date()) + "' "
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
    cQry += "   AND E1_TIPO IN('NCC','RA') "
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
    cQry += "  FROM "+ RetSqlName("SC5") + " C5 " 
    cQry += " INNER JOIN " + RetSqlName("SC6") + " C6 "
    cQry += "    ON C6.D_E_L_E_T_ = ' ' "
    cQry += "   AND C6_NUM = C5_NUM "
    cQry += "   AND C6_BLQ NOT IN('S','R') "
    cQry += "   AND C6_QTDVEN > C6_QTDENT "
    cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"'"
    cQry += " INNER JOIN " + RetSqlName("SB1") +" B1 "
    cQry += "    ON B1.B1_FILIAL = '"+xFilial("SB1")+"' "
    cQry += "   AND B1.B1_COD = C6.C6_PRODUTO"
    cQry += "   AND B1.D_E_L_E_T_ = ' '"
    cQry += " WHERE C5.D_E_L_E_T_ = ' ' "
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

