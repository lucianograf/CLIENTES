#Include "Protheus.ch"

/*/{Protheus.doc} PEVTE001
Ponto de entrada permite a manipulação dos arrays de cabeçalho e itens enviados para o execauto de inclusao do pedido de venda MATA410
Executado na geração de pedidos Tray x Protheus, executado na interface e no job automático a cada pedido.
@type function
@author Anderson - Vamilly
@since 27/11/2023
@param aPEVTE001, Array, Array a ser manipulado.
@return array, Array atualizado
/*/
User Function PEVTE001()
    Local aPeCabec   as Array
    Local aPeItens   as Array
    Local nPTABPos   as Numeric
    Local nPePos     as Numeric
    Local aPeArea    as Array
    Local nX         as Numeric
    Local nPosDesc   as Numeric
    Local nPosPrc    as Numeric
    Local nPosQtd    as Numeric
    Local nValorDesc as Numeric

    aPeArea  := GetArea()
    aPeCabec := aPEVTE001[1]  // Cabeçalho
    aPeItens := aPEVTE001[2]  // Itens

    // Efetua procedimentos especificos - Exemplo:
    nPTABPos := ASCAN(aPeCabec, { |x| x[1]== "C5_TABELA" }) // Verifica se ja esta informado no array.
    nPePos   := ASCAN(aPeCabec, { |x| x[1]== "C5_VEND1"  }) // Verifica se ja esta informado no array.

    // Tratativa para preencher a tabela de preço.
    If nPTABPos > 0
        aPeCabec[nPTABPos][2] := "110"
    Else
        aAdd(aPeCabec, {"C5_TABELA", "110", Nil})
    EndIf

    // Tratativa para prencher o vendedor do e-commerce.
    If nPePos > 0
        aPeCabec[nPePos][2] := "000412"
    Else
        aAdd(aPeCabec, {"C5_VEND1", "000412" , Nil})
    EndIf

    // Tratativa para preencher o valor do desconto no campo customizado do item.
    For nX := 1 to Len(aPeItens)
        //Pego a posição do valor do Desconto.
        nPosDesc   := ASCAN(aPeItens[nX], { |x| x[1] == "C6_VALDESC" }) // Verifica se ja esta informado no array.

        //Pego a posição do desconto.
        If nPosDesc > 0
            nValorDesc := 0 
            nValorDesc := aPeItens[nX][nPosDesc][2]
            
            //Pego o valor do desconto.
            If nValorDesc > 0
                //Pego a posição da quantidade e do preço.
                nPosQtd   := ASCAN(aPeItens[nX], { |x| x[1] == "C6_QTDVEN" })
                nPosPrc   := ASCAN(aPeItens[nX], { |x| x[1] == "C6_PRCVEN" })

                //Pego o valor total do item.
                nValorTotal := aPeItens[nX][nPosQtd][2] * aPeItens[nX][nPosPrc][2]

                //Faço o calculo da porcentagem do desconto.
                nPorcDesc := Round((nValorDesc / nValorTotal) * 100 , 2)

                aAdd(aPeItens[nX], {"C6_ZDESITE", nPorcDesc, Nil})
            EndIf
        EndIf
    Next nX

    RestArea(aPeArea)
Return( {aPeCabec, aPeItens} )
