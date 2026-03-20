#include 'totvs.ch'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'FONT.CH'
#INCLUDE 'COLORS.CH'

/*/{ProtUserheus.doc} DECAT004
    Função para gerar ou excluir indicadores na tabela de registro de itens deletados.
    @type Function
    @author Jonivani Pereira
    @since 03/11/2023
    @version 1.0
/*/
User Function DECAT004()
    Local lAction     := .T.                      as logical
    Local lDltd       := acols[n][len(aheader)+1] as logical
    Local lExist      := .F.                      as logical
    Local lGrIndic    := .T.                      as logical
    Local lRet        := .F.                      as logical
    Local nPosItem    := aScan(aHeader,{|x| AllTrim(x[2])=='C6_ITEM'})    as numeric
	Local nPosProd    := aScan(aHeader,{|x| AllTrim(x[2])=='C6_PRODUTO'}) as numeric
    Local nPosQtd     := aScan(aHeader,{|x| AllTrim(x[2])=='C6_QTDVEN'})  as numeric
    Local nPosVal     := aScan(aHeader,{|x| AllTrim(x[2])=='C6_PRCVEN'})  as numeric
    Local nPosTot     := aScan(aHeader,{|x| AllTrim(x[2])=='C6_VALOR'})   as numeric
    Private aMotivo   :={"Falta Estoque"}   as array
    Private cBox4     := ""                 as Character
    Private cCliente  := ""                 as Character
    Private cCodCli   := M->C5_CLIENTE      as Character
    Private cCodProd  := acols[n][nPosProd] as Character
    Private cCodVend  := M->C5_VEND1        as Character
    Private cCopia    := Space(250)         as Character
    Private cDescProd := ""                 as Character
    Private cEmailVd  := ""                 as Character
    Private cEnviar   := ""                 as Character
    Private cHrExcl   := Time()             as Character
    Private cItem     := acols[n][nPosItem] as Character
    Private cLoja     := M->C5_LOJA         as Character
    Private cMGet1    := ""                 as Character
    Private cObserv   := ""                 as Character
    Private cPedido   := M->C5_NUM          as Character
    Private cUserExcl := ""                 as Character
    Private cVendedor := ""                 as Character
    Private dDtExcl   := dDataBase          as date
    Private dDtPed    := M->C5_EMISSAO      as date
    Private nPrcVen   := acols[n][nPosVal]  as numeric
    Private nQtdVend  := acols[n][nPosQtd]  as numeric
    Private nQtdFalta := nQtdVend           as numeric
    Private nValor    := acols[n][nPosTot]  as numeric

    cUserExcl := AllTrim(__cUserId) + "-" + AllTrim(cUserName)

    // Posicionar no cliente
    SA1->(DBSetOrder(1))
    If SA1->(DBSeek(xFilial("SA1") + cCodCli))
        cCliente := SA1->A1_NOME
    EndIf

    // Posicionar no vendedor
    SA3->(DBSetOrder(1))
    If SA3->(DBSeek(xFilial("SA3") + cCodVend ))
        cVendedor := SA3->A3_NOME
        cEmailVd := SA3->A3_EMAIL
    EndIf

    // Posicionar no produto
    SB1->(DBSetOrder(1))
    If SB1->(DBSeek(xFilial("SB1") + cCodProd ))
        cDescProd := SB1->B1_DESC
    EndIf

    // Posicionar na tabela e verificar se o produto excluido ja existe.
    DbSelectArea("ZZO")
    ZZO->(DBSetOrder(1)) // ZZO_FILIAL+ZZO_PEDIDO+ZZO_ITEM+ZZO_CODROD
    If ZZO->(DBSeek(xFilial("ZZO") + Padr(cPedido ,TamSX3("ZZO_PEDIDO")[1]) + Padr(cItem ,TamSX3("ZZO_ITEM")[1]) + Padr(cCodProd ,TamSX3("ZZO_CODROD")[1])))
        lExist := .T.
    EndIf

    // Se existe detelar o item 
    If lExist
        lAction := .F. // .T. := Incluir , .F. := Excluir
        lRet := DECFAT4A(lAction)   
        Return 
    EndIf
    
    // Pergunta se gera indicador 
    If !lDltd
        // Pergunta se quer gerar indicador
        lGrIndic := FWAlertYesNo("Deseja gerar indicador de falta de estoque?", "Item Excluído!") 
        If !lGrIndic
            lRet:= .F.
            Return 
        EndIf

        If DECFAT4T() //  Tela para colocar a validação dos dados excluidos.
            lAction := .T.
            // Gravar registros ou exclui
            lRet := DECFAT4A(lAction)
        EndIf

    EndIf    

Return lRet


/*/{Protheus.doc} DECFAT4T
    Função para abrir a tela.
    @type Function
    @author Jonivani Pereira
    @since 03/11/2023
    @version 1.0
/*/
Static Function DECFAT4T()
    Local lRet     := .F. as logical

    // Setando a vairiaveis de objeto como Private
    SetPrvt("oDlg1","oGrp1","oSay1","oSay2","oSay3","oSay4","oSay5","oSay6","oSay7","oSay8","oSay9","oSay10","oSay11")
    SetPrvt("oSay13","oSay14","oSay16","oSay15","oSay17","oSay18","oSay19","oSay20","oGet1","oCBox1","oGet2")
    SetPrvt("oBtn1","oBtn2")

    oDlg1      := MSDialog():New( 110,2315,485,2721,"GERAR INDICADOR",,,.F.,nOr(DS_MODALFRAME,WS_DLGFRAME),,,,,.T.,,,.T. )
    oGrp1      := TGroup():New( 004,006,175,200,"",oDlg1,CLR_BLACK,CLR_WHITE,.T.,.F. )
    oSay1      := TSay():New( 008,012,{||"Data:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay2      := TSay():New( 008,052,{||dDtExcl},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay3      := TSay():New( 017,012,{||"Usuário:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay4      := TSay():New( 017,052,{||cUserExcl},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay5      := TSay():New( 026,012,{||"Cliente:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay6      := TSay():New( 026,052,{||cCodCli + "-" + cCliente},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay7      := TSay():New( 034,012,{||"Vendedor:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay8      := TSay():New( 034,052,{||cCodVend + "-" + cVendedor},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay9      := TSay():New( 043,012,{||"Pedido:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay10     := TSay():New( 043,052,{||cPedido},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay11     := TSay():New( 051,012,{||"Produto:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay12     := TSay():New( 051,052,{||AllTrim(cCodProd) + "-" + PadR(cDescProd,35)},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay13     := TSay():New( 060,012,{||"Qtd Vendida:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay14     := TSay():New( 059,052,{||nQtdVend},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay16     := TSay():New( 070,012,{||"Qtd Falta:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay15     := TSay():New( 080,012,{||"Enviar E-mail?"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay17     := TSay():New( 090,012,{||"Para: "},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay18     := TSay():New( 090,052,{||cEmailVd},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,140,008)
    oSay19     := TSay():New( 100,012,{||"Cópia:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oSay20     := TSay():New( 111,081,{||"Observação:"},oGrp1,,,.F.,.F.,.F.,.T.,CLR_BLUE,CLR_WHITE,037,008)
    oGet1      := TGet():New( 068,052,{|u| If(PCount()>0,nQtdFalta:=u,nQtdFalta)},oGrp1,032,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","nQtdFalta",,)
    oCBox1     := TComboBox():New( 078,052,{|u| If(PCount()>0,cEnviar:=u,cEnviar)},{"Sim", "Não"},032,010,oGrp1,,,,CLR_BLACK,CLR_WHITE,.T.,,"",,,,,,,cEnviar )
    oGet2      := TGet():New( 099,052,{|u| If(PCount()>0,cCopia:=u,cCopia)},oGrp1,140,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cCopia",,)
    oMGet1     := TMultiGet():New( 120,012,{|u| If(PCount()>0,cObserv:=u,cObserv)},oGrp1,180,032,,,CLR_BLACK,CLR_WHITE,,.T.,"",,,.F.,.F.,.F.,,,.F.,,  )
    oBtn1      := TButton():New( 156,040,"Confirmar",oGrp1,{||lRet:= .T., oDlg1:End()},037,012,,,,.T.,,"",,,,.F. )
    oBtn2      := TButton():New( 156,109,"Cancelar",oGrp1,{||lRet:= .F., oDlg1:End()},037,012,,,,.T.,,"",,,,.F. )

    oDlg1:Activate(,,,.T.)

Return lRet


/*/{Protheus.doc} DECAT004C
    Função para habilitar campos
    @type Function
    @author Jonivani Pereira
    @since 09/11/2023
    @version 1.0
/*/
Static Function DECFAT4B()
    Local lRet := .T. as logical
    If cEnviar == "Sim"
        oGet2:Enable()
        oMGet1:Enable()
    EndIf

    If cEnviar == "Não"
        oGet2:Disable()
        oMGet1:Disable()
    EndIf

    oGet2:Refresh()
    oGet2:Refresh()
Return lRet


/*/{Protheus.doc} DECFAT4A
    Função para incluir/deletar o registro da tabela de indicadores..
    @type Function
    @author Jonivani Pereira
    @since 03/11/2023
    @version 1.0
/*/
Static Function DECFAT4A(lAction)
    Local lRet      := .T. as logical
   
    If lAction
        DbSelectArea("ZZO")
        ZZO->(DBSetOrder(1))
        Begin Transaction
            // Incluir o registro
            RecLock("ZZO", .T.)
                ZZO->ZZO_FILIAL := xFilial("ZZO")
                ZZO->ZZO_ID     := GETSXENUM("ZZO","ZZO_ID")
                ZZO->ZZO_CODCLI := cCodCli
                ZZO->ZZO_CLIENT := cCliente
                ZZO->ZZO_PEDIDO := cPedido
                ZZO->ZZO_ITEM   := cItem
                ZZO->ZZO_CODROD := cCodProd
                ZZO->ZZO_DESPRO := cDescProd
                ZZO->ZZO_QUANT  := nQtdVend
                ZZO->ZZO_PRCVEN := nPrcVen
                ZZO->ZZO_VALOR  := nValor
                ZZO->ZZO_DTPED  := dDtPed
                ZZO->ZZO_USREXC := cUserExcl
                ZZO->ZZO_DTEXCL := dDtExcl
                ZZO->ZZO_HREXCL := cHrExcl
                ZZO->ZZO_OBSERV := cObserv
                ZZO->ZZO_VEND   := cCodVend
                ZZO->ZZO_NOMEVD := cVendedor
                ZZO->ZZO_EMAILV := cEmailVd
                ZZO->ZZO_ENVMAI := IIF(cEnviar == "Sim" , "1", "2") // 1 enviar, 2 não enviar
                ZZO->ZZO_QTDFAL := nQtdFalta
                ZZO->ZZO_EMACOP := cCopia
                ZZO->ZZO_MTEXCL := aMotivo[1] // Falta Estoque
                ZZO->ZZO_STATUS := "1" // 1 - Digitando, 2 - Enviado 
            ZZO->(MsUnlock())
        End Transaction
    Else
        DbSelectArea("ZZO")
        ZZO->(DBSetOrder(1)) // ZZO_FILIAL+ZZO_PEDIDO+ZZO_ITEM+ZZO_CODROD
        If ZZO->(DBSeek(xFilial("ZZO") + Padr(cPedido ,TamSX3("ZZO_PEDIDO")[1]) + Padr(cItem ,TamSX3("ZZO_ITEM")[1]) + Padr(cCodProd ,TamSX3("ZZO_CODROD")[1])))
            //Deletar o registro
            Begin Transaction
                RecLock('ZZO', .F.)
                    DbDelete()
                ZZO->(MsUnlock())
            End Transaction
        EndIf
    EndIf
Return lRet