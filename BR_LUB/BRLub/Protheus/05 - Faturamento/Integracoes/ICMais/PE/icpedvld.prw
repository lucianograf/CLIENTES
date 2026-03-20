#include 'totvs.ch'

/*/{Protheus.doc} ICPEDVLD
PE implementado para tratativa do processo de lançamento de valores de tampinhas via app
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 09/08/2024
@return array, aReturn[lSuccess,cError]
/*/
user function ICPEDVLD()
    
    local aArea    := getArea()
    local aReturn  := { .T. /* lValidated */, "" /* cError */ }
    // local cRot     := PARAMIXB[1]        // Interface que será utilizada para execução da integração do pedido
    local aCab     := PARAMIXB[2]        // Vetor do cabeçalho do pedido no modelo do execauto
    local aItens   := PARAMIXB[3]        // Vetor dos itens do pedido no modelo do execauto
    local cID      := getData( aCab, 'UA_X_NCENT' )
    local nX       := 0 as numeric
    local cProd    := "" as character
    local nValor   := 0 as numeric
    local cCli     := PADR(AllTrim(getData( aCab, 'UA_CLIENTE' )),TAMSX3('UA_CLIENTE')[1], ' ' )
    local cLoja    := PADR(AllTrim(getData( aCab, 'UA_LOJA' )), TAMSX3('UA_LOJA')[1], ' ' )
    local cItem    := "" as character
    local lSuccess := .T. as logical

    // Verifica se conseguiu obter o ID do pedido do center do ICvendas
    if ValType( cID ) == 'C' .and. !Empty( cID )

        if len( aItens ) > 0
            
            DBSelectArea( 'SZ8' )
            SZ8->( DBSetOrder( 1 ) )        // FILIAL + CLIENTE + LOJA + CODPRO

            DBSelectArea( 'ZI2' )
            ZI2->( DBSetOrder(1) )          // FILIAL + NCENTER + NITEM

            BEGIN TRANSACTION
                
                for nX := 1 to len( aItens )
                    
                    nValor := 0
                    // Obtém o código do produto
                    cProd  := AllTrim( getData( aItens[nX], 'UB_PRODUTO' ) )
                    cItem  := PADR(cValToChar(Val(getData( aItens[nX], 'UB_ITEM' ))),TAMSX3('UB_ITEM')[1], ' ')

                    // Verifica se consegue encontrar o pedido e os produtos
                    if ZI2->( DBSeek( FWxFilial( 'ZI2' ) + cID + cItem ) )
                        nValor := ZI2->ZI2_VTAMPA
                    endif

                    if nValor > 0
                        
                        // Verifica se connsegue identificar cadastro de tampa pré-definido
                        if SZ8->( DBSeek( FWxFilial( 'SZ8' ) + cCli + cLoja + cProd ) )
                            if nValor <= SZ8->Z8_VALOR
                                if nValor < SZ8->Z8_VALOR
                                    RecLock( 'SZ8', .F. )
                                    SZ8->Z8_OBS := "Valor alterado de "+ AllTrim( Transform( SZ8->Z8_VALOR, '@E 99,999,999.99' ) ) +;
                                                " para "+ AllTrim( Transform( nValor, "@E 99,999,999.99" ) )
                                    SZ8->Z8_VALOR := nValor
                                    SZ8->( MsUnlock() )
                                endif
                            elseif nValor > SZ8->Z8_VALOR
                                lSuccess := .F.
                                aReturn  := { lSuccess, "O valor de tampa EXCEDIDO para o produto "+ cProd +;
                                                    " - "+ AllTrim(RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProd, 'B1_DESC' )) +". "+;
                                                    "Valor permitido: R$ "+ AllTrim( Transform( SZ8->Z8_VALOR, "@ EE,999,999.99" ) ) }
                            endif
                        else
                            RecLock( 'SZ8', .T. )
                            SZ8->Z8_FILIAL  := FWxFilial( 'SZ8' )
                            SZ8->Z8_REEMB   := 'T'
                            SZ8->Z8_CLIENTE := cCli
                            SZ8->Z8_LOJA    := cLoja
                            SZ8->Z8_CODPROD := cProd
                            SZ8->Z8_VALOR   := nValor
                            SZ8->Z8_DATCAD  := date()
                            SZ8->Z8_DATFIM  := StoD('20501231' )
                            SZ8->Z8_OBS     := "Cadastrado via ICmais"
                            SZ8->Z8_PONTOS  := 25
                            SZ8->( MsUnlock() )
                        endif
                    endif
                    
                    // Verifica se a variável permanece com conteúdo do retorno .T.=TudoOk
                    if ! aReturn[1]
                        // Destrava a transação abortando o processo
                        DisarmTransaction()
                        Exit
                    endif

                next nX
            
            END TRANSACTION

        endif

    endif

    restArea( aArea ) 
return aReturn

/*/{Protheus.doc} getPos
Retorna posição do campo no vetor
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 08/08/2024
@param aData, array, vetor com os dados do registro em que a informação será obtida (formato execauto)
@param cFieldID, character, ID do campo a ser retornado
@return numeric, nFieldPos
/*/
static function getPos( aData, cFieldID )
return aScan( aData, {|x| AllTrim( x[1] ) == AllTrim( cFieldID ) } )

/*/{Protheus.doc} getData
Retorna informação de um campo em vetor 
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 08/08/2024
@param aData, array, vetor de dados (formato execauto)
@param cFieldID, character, ID do campo
@return variadic, xData
/*/
static function getData( aData, cFieldID )
return iif( getPos(aData,cFieldID)==0, nil,aData[getPos(aData,cFieldID)][2])
