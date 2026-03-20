#include 'TOTVS.CH'
#INCLUDE "PROTHEUS.CH"


/*/{Protheus.doc} DECAT007
Chamada de customização para aprovação por Hierarquia.
@type  Function
@author Vamilly - MRBranco
@since 2/11/2023
@version 2210
@param cVend, character , codigo do vendedor do pedido.
/*/
User Function DECAT007(cVend as Character, nDesc As Numeric)
    Local aAreaSC5   := {}  As Array
    Local aAreaSC6   := {}  As Array
    Local nDesApliP  := 0   As Numeric   // Desconto aplicado campo padrão
    Local nDesPercP  := 0   As Numeric   // % aplicado campo padrão
    Local nDesApliC  := 0   As Numeric   // Desconto aplicado campos customizado
    Local nDesPerHie := 0   As Numeric   // Total de desconto aplicado para solcitar aprovação
    Local cGrpAprPV  := ""  As Character
    Local cGrupoVd   := ""  As Character
    Local nDescPerm  := 0   As Numeric   // % de desconto permito
    Local nTotItem   := 0   As Numeric
    Local nValLista  := 0   As Numeric

    Default cVend := ""
    Default nDesc := 0

    // Popula
    aAreaSC5     := SC5->(FWGetArea())
    aAreaSC6     := SC6->(FWGetArea())
    // Capturo o grupo de aprovação do cadastro do vendedor.
    cGrupoVd     := Posicione("SA3",1,XFILIAL("SA3")+cVend,"A3_XGRPAPR")
    // Caso o grupo esteja vazio, pego o grupo padrão contido no parâmetro.
    cGrpAprPV 	 := iif(!Empty(cGrupoVd), cGrupoVd , SuperGetMV("DC_GRAPDG",.F., "000002"))

    // Valor do desconto aplicado
    DBSelectArea("SC6")
    DBSetOrder(1)  //
    DBSeek(xFilial("SC6") + SC5->C5_NUM)
    While SC6->(!Eof()) .And. SC6->(C6_FILIAL + C6_NUM) == SC5->(C5_FILIAL + C5_NUM)

        // Popula
        nTotItem  := SC6->C6_VALOR
        nDesApliP := SC6->C6_VALDESC // Vlr Desconto
        nDesPercP := SC6->C6_DESCONT // % Desconto
        nDesApliC := Iif(nDesc > 0, nDesc, SC6->C6_ZDESITE) // Campo customizado Decanter % 
        nValLista := SC6->C6_PRUNIT  // Preço Lista
        nDescPerm := U_DECAT07C(SC5->C5_VEND1, SC6->C6_PRODUTO)

        // Verifica se o desconto aplicado é maior que o permitido
        If nDesApliC > nDescPerm

            // Enviar o maior desconto aplicado para aprovação por alçadas
            If nDesApliC > nDesPerHie
                nDesPerHie := nDesApliC
            EndIf
        EndIf

        SC6->(DBSkip())
    EndDo

    // Estorna as liberações, se houver
    MaAlcDoc({SC5->C5_NUM,"_A",nDesPerHie,,,cGrpAprPV,,,,MsDate()},MsDate(),3)

    // Insere o registro das aprovações
    MaAlcDoc({SC5->C5_NUM,"_A",nDesPerHie,,,cGrpAprPV,,,,MsDate()},MsDate(),1)

    // PEDIDO , OPÇÃO, DESCONTO,
    cMsg := ""
    cMsg := U_DECAT08WF(SC5->C5_NUM,"10",.T.)
    If !Empty(cMsg)
        RecLock("SC5", .F.)
        SC5->C5_ZBLQCOM := SC5->C5_ZBLQCOM + CRLF + "Aprovador não encontrado para o desconto de [" + cValToChar(nDesPerHie) +"%] fora da campanha -> [" + AllTrim(cMsg) + "]"
        SC5->(MSUnLock())
    EndIf

    // MsgStop("O Pedido só poderá ser faturado após liberado pelas Regras Decanter.")

    RestArea(aAreaSC6)
    RestArea(aAreaSC5)
Return

/*/{Protheus.doc} DECAT07C
Função para buscar o percentual de desconto permitido pela campanha
@type function
@version  2210
@author MRBranco - Vamilly
@since 02/12/2023
@param cVend, character, Vendedor para identificar para identificar o canal do cliente
@param cProd, character, produto para validar se esta na campanha
@param nPerDesc, numeric, % do desconto aplicado no item
/*/
User Function DECAT07C(cVend As Character, cProd As Character)
    Local cAlias    := GetNextAlias()
    Local aArea     := FWGetArea()
    Local aAreaSA3  := SA3->(GetArea())
    Local aAreaSZ2  := SZ2->(GetArea())
    Local aAreaSZ3  := SZ3->(GetArea())
    Local cCanal    := ""
    Local lAchou    := .F.
    Local aCamp     := {}
    Local nX        := 0 As Numeric
    Local nDescPerm := 0 As Numeric
    Local cData     := DtoS(MsDate())

    DBSelectArea("SA3")
    SA3->(DBSetOrder(1))
    IF SA3->(DBSeek(xFilial("SA3") + cVend))
        cCanal := SA3->A3_XCANCLI
    EndIf

    // Verificar se existe uma campanha para o produto
    DBSelectArea("SZ2")
    SZ2->(DbSetOrder(3)) // Z2_FILIAL + Z2_PRODUTO
    If SZ2->(DBSeek(xFilial("SZ2") + cProd))

        BeginSQL Alias cAlias
            SELECT
                Z1_ID ID,
                Z2_PERDESC PERDESC,
                Z2_VALDESC VALDESC,
                Z2_PRODUTO PRODUTO
            FROM
                %Table:SZ1% SZ1
            INNER JOIN %Table:SZ2% SZ2
            ON Z2_FILIAL = Z1_FILIAL
                AND Z2_ID = Z1_ID
                AND Z2_PRODUTO = %Exp:cProd%
                AND SZ2.%notdel%
            WHERE
                Z1_FILIAL = %Exp:xFilial("SZ1")%
                AND Z1_STATUS = '1'
                AND Z1_DTINI <= %Exp:cData%
                AND Z1_DTFIM >= %Exp:cData%
                AND SZ1.%notdel%
            ORDER BY
                Z2_PERDESC DESC
        EndSQL

        // Busca campanhas especificas deste produto
        // para este vendedor ou para este canal de vendas
        DBSelectArea("SZ3") // tabela de campanha
        DBSelectArea(cAlias)
        While (cAlias)->(!Eof())

            // Busca campanha
            SZ3->(DBSetOrder(1)) // Z3_FILIAL + Z3_ID + Z3_VEND
            IF SZ3->(DBSeek(xFilial("SZ3") + (cAlias)->ID))

                // Busca por vendedor
                If SZ3->(DBSeek( xFilial("SZ3") + (cAlias)->ID + cVend)) // Pega caso a campanha seja pro vendedor do pedido
                    Aadd(aCamp, { (cAlias)->ID,;
                        (cAlias)->PERDESC,;
                        (cAlias)->VALDESC,;
                        (cAlias)->PRODUTO})
                    lAchou := .T.
                EndIf

                // Busca por canal de vendas
                SZ3->( DbSetOrder(2) ) // Z3_FILIAL + Z3_ID + Z3_VEND
                If SZ3->(DBSeek( xFilial("SZ3") + (cAlias)->ID + cCanal)) // Pega caso a campanha seja para o canal do vendedor
                    Aadd(aCamp, { (cAlias)->ID,;
                        (cAlias)->PERDESC,;
                        (cAlias)->VALDESC,;
                        (cAlias)->PRODUTO})
                    lAchou := .T.
                EndIf

                // Verifica se achou o registro, caso não tenha encontrado pega o padrão.
                If !lAchou
                    Aadd(aCamp,{(cAlias)->ID,; // Pega caso caso seja uma campanha para todos os vendedores.
                        (cAlias)->PERDESC,;
                        (cAlias)->VALDESC,;
                        (cAlias)->PRODUTO})
                EndIf
            Else
                aAdd(aCamp, {  (cAlias)->ID,; // Pega caso caso seja uma campanha para todos os vendedores.
                    (cAlias)->PERDESC,;
                    (cAlias)->VALDESC,;
                    (cAlias)->PRODUTO})
            EndIf

            (cAlias)->(DBSkip())
        EndDo

        If Len(aCamp) > 0
            For nX := 1 To Len(aCamp)
                nDescPerm := aCamp[nX][2] // Desconto permitido pela campanha
            Next nX
        EndIf
    EndiF

    FWRestArea(aArea)
    FWRestArea(aAreaSA3)
    FWRestArea(aAreaSZ2)
    FWRestArea(aAreaSZ3)
Return nDescPerm
