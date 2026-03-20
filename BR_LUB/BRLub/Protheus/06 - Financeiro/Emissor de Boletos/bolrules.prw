#include 'totvs.ch'
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

#define CLOCPDF GetTempPath(.T.)

/*/{Protheus.doc} BOLRULES
Analisa regras definidas pelo financeiro para emissão de boletos automática 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/06/2022
@param cOri, character, alias de onde a emissão de boletos está sendo chamada
@param aBcoUsr, array, vetor com o banco escolhido pelo usuário nas perguntas da rotina de impressão de boletos
@param oDanfe, object, objeto do danfe quando chamado de forma automática na impressao de nota (não obrigatório)
@return array, aTitulos
/*/
user function BOLRULES( cOri, oDanfe )

    local aArea    := getArea()
    local aTitulos := {} as array
    local cTitulo  := "" as character
    local cPrefixo := "" as character
    local aTemp    := {} as array
    local nParc    := 0  as numeric
    local cParcAtu := "" as character
    local cTipoAtu := "" as character
    local nX       := 0 as numeric
    local aBcoUsr  := {} as array
    local aTitCR   := {} as array
    local aTitBOL  := {} as array
    local lSendRe  as logical
    local aParDnf  := {} as array
    local oObjeto  as object

    default cOri    := Alias()
    default oDanfe  := Nil

    if cOri == "SF2"        // Tabela de notas de saída

        // Guarda os parâmetros do emissor de danfe para restaurá-los posteriormente
        aAdd( aParDnf, MV_PAR01 )
        aAdd( aParDnf, MV_PAR02 )
        aAdd( aParDnf, MV_PAR03 )
        aAdd( aParDnf, MV_PAR04 )
        aAdd( aParDnf, MV_PAR05 )
        aAdd( aParDnf, MV_PAR06 )
        aAdd( aParDnf, MV_PAR07 )
        aAdd( aParDnf, MV_PAR08 )

        cTitulo  := SF2->F2_DOC
        cPrefixo := SF2->F2_PREFIXO

        DBSelectArea( "SE1" )
        SE1->( DBSetOrder( 1 ) )
        if SE1->( DBSeek( FWxFilial( "SE1" ) + cPrefixo + cTitulo ) )
            while ! SE1->( EOF() ) .and. SE1->E1_FILIAL + SE1->E1_PREFIXO + SE1->E1_NUM == FWxFilial( "SE1" ) + cPrefixo + cTitulo
                // Considera apenas titulos com saldo em aberto
                if SE1->E1_SALDO > 0 .and. ! Trim( SE1->E1_TIPO ) $ 'RA/NCC'
                    aTitCR := U_BOLTITCR( SE1->(Recno()), cOri )
                    If Len( aTitCR ) > 0
                        aAdd( aTitulos, aClone( aTitCr ) )
                    endif
                endif            
                DbSelectArea("SE1")
                SE1->( DBSkip() )
            enddo

        endif

    elseif cOri == "SE1"    // Títulos a receber
        
        cTitulo  := SE1->E1_NUM
        cPrefixo := SE1->E1_PREFIXO
        cParcAtu := SE1->E1_PARCELA
        cTipoAtu := SE1->E1_TIPO
        nParc    := 0
        
        DBSelectArea( "SE1" )
        SE1->( DBSetOrder( 1 ) )
        if SE1->( DBSeek( FWxFilial( "SE1" ) + cPrefixo + cTitulo ) )
            while ! SE1->( EOF() ) .and. SE1->E1_FILIAL + SE1->E1_PREFIXO + SE1->E1_NUM == FWxFilial( "SE1" ) + cPrefixo + cTitulo
                if SE1->E1_SALDO > 0 .and. ! Trim( SE1->E1_TIPO ) $ 'RA/NCC'
                    nParc++
                    aTitCR := U_BOLTITCR( SE1->(Recno()), Nil )
                    if len( aTitCR ) > 0
                        aAdd( aTemp, aClone( aTitCR ) )
                    endif
                endif
                SE1->( DBSkip() )
            enddo
            
            if nParc > 1
                
                if Aviso( 'Imprimir todas as parcelas?',;
                 'Foram identificadas '+ cValToChar( nParc ) +' parcelas para o títulos selecionado, deseja emitir boleto para todas?',;
                 { 'Sim', 'Apenas esta parcela' } ) == 2
                    
                    DBSelectArea( "SE1" )
                    SE1->( DBSetOrder( 1 ) )
                    if SE1->(DBSeek( FWxFilial( "SE1" ) + cPrefixo + cTitulo + cParcAtu + cTipoAtu ))
                        if SE1->E1_SALDO > 0 .and. ! Trim( SE1->E1_TIPO ) $ 'RA/NCC'
                            aTemp := {}
                            aTitCR := U_BOLTITCR( SE1->(Recno()), Nil )
                            if len( aTitCR ) > 0
                                aAdd( aTemp, aClone( aTitCR ) )
                            endif
                        endif

                    endif

                endif

            endif

            aTitulos := aClone( aTemp )
            aTemp := {}

        endif

    endif

    if len( aTitulos ) > 0
        for nX := 1 to len( aTitulos )
            aTitulos[nX] := U_BOLPRIOR( aTitulos[nX], @aBcoUsr )
            // Scaneia o vetor para saber se o banco para impressao do boleto foi definido
            if gt( aTitulos[nX], 'banco' ) != Nil .and. !Empty( gt( aTitulos[nX], 'banco' ) )
                
                if cOri == 'SF2'            // Faturamento

                    // Chama rotina responsável pela emissao do boleto
                    U_BOLETOS( gt( aTitulos[nX], 'cliente' ),;
                                gt( aTitulos[nX], 'loja' ),;
                                gt( aTitulos[nX], 'numero' ),;
                                gt( aTitulos[nX], 'prefixo' ),;
                                gt( aTitulos[nX], 'banco' ),;
                                gt( aTitulos[nX], 'agencia' ),;
                                gt( aTitulos[nX], 'conta' ),;
                                gt( aTitulos[nX], 'subconta' ),;
                                .T. /* lAuto */,;
                                @oDanfe,;
                                gt( aTitulos[nX], 'parcela' ) )
                
                elseif cOri == 'SE1'        // Contas a receber
                    
                    if nX == 1
                        oObjeto := genObject( .T. /* lPreview */ )
                    endif 

                    // Chama rotina responsável pela emissao do boleto
                    U_BOLETOS( gt( aTitulos[nX], 'cliente' ),;
                                gt( aTitulos[nX], 'loja' ),;
                                gt( aTitulos[nX], 'numero' ),;
                                gt( aTitulos[nX], 'prefixo' ),;
                                gt( aTitulos[nX], 'banco' ),;
                                gt( aTitulos[nX], 'agencia' ),;
                                gt( aTitulos[nX], 'conta' ),;
                                gt( aTitulos[nX], 'subconta' ),;
                                .T. /* lAuto */,;
                                @oObjeto,;
                                gt( aTitulos[nX], 'parcela' ) )
                endif

                DBSelectArea( 'SA1' )
                SA1->( DBSetOrder( 1 ) )        // A1_FILIAL + A1_COD + A1_LOJA
                if SA1->( DBSeek( FWxFilial( 'SA1' ) + gt( aTitulos[nX], 'cliente' ) + gt( aTitulos[nX], 'loja' ) ) )
                    
                    // Verifica se o cliente está com o campo de envio de boletos igual a Sim
                    if SA1->(FieldPos('A1_BLEMAIL')) > 0 .and. SA1->A1_BLEMAIL == '1'       // 1=Sim

                        // Verifica se o usuário quer enviar boletos já impressos anteriormente para o cliente
                        if valType( lSendRe ) != 'L'
                            lSendRe := MsgYesNo( 'Alguns boletos já foram impressos anteriormente, gostaria de enviar por email para o cliente mesmo assim?', 'Reimprimir?' )
                        endif

                        // Títulos que tiveram seu boleto emitido
                        if ! gt( aTitulos[nX], 'reimpressao' ) .or. ( ValType( lSendRe ) == 'L' .and. lSendRe )
                            aAdd( aTitBOL, aClone( aTitulos[nX] ) )
                        endif

                    endif

                endif

            endif

        next nX
        
        // Imprime quando a chamada do emissor de boletos for feita por meio de tabela do CR - SE1
        if cOri == 'SE1' .and. oObjeto <> Nil
                
            // Imprime os boletos
            oObjeto:Print()
            FreeObj( oObjeto )
            oObjeto := Nil
        
        endif
        
        if len( aTitBOL ) > 0
            U_BLENVMAIL( aTitBOL )
        endif

    endif

    // Quando a origem for do emissor de danfe, restaura as perguntas do danfe para evitar problemas
    if cOri == 'SF2'
        Pergunte("NFSIGW",.F.)
        MV_PAR01 := aParDnf[1] 
        MV_PAR02 := aParDnf[2]
        MV_PAR03 := aParDnf[3]
        MV_PAR04 := aParDnf[4]
        MV_PAR05 := aParDnf[5]
        MV_PAR06 := aParDnf[6] 
        MV_PAR07 := aParDnf[7]
        MV_PAR08 := aParDnf[8]
    endif

    restArea( aArea )
return aTitulos

/*/{Protheus.doc} gt
Função para retornar o conteudo de uma posição do vetor enviado via parâmetro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 01/11/2022
@param aVetor, array, vetor
@param cKey, character, chave a ser retornada
@return variadic, xInfo
/*/
static function gt( aVetor, cKey )
return iif( aScan( aVetor, {|x| AllTrim( x[1] ) == AllTrim( cKey ) } ) == 0, Nil, aVetor[ aScan( aVetor, {|x| AllTrim( x[1] ) == AllTrim( cKey ) } ) ][02] )

/*/{Protheus.doc} BOLPRIOR
Função para definir o banco prioritário para impressão de acordo com as regras da empresa
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2022
@param aTitulo, array, vetor com os dados do título a ser impresso
@param aBcoUsr, array, vetor de banco escolhido pelo usuário (a variável deve ser passada por referência)
@return array, aRatedTit
/*/
user function BOLPRIOR( aTitulo, aBcoUsr )
    
    local aRatedTit := {} as array
    local cMVALPRI  := AllTrim( SuperGetMV( 'MV_X_BLPRI',,'' ) )
    local cMVALGAR  := AllTrim( SuperGetMV( 'MV_X_BLGAR',,'' ) )
    local cMVBCFAT  := AllTrim( SuperGetMV( 'MV_X_BCFAT',,'' ) )     // banco default definido internamente
    local aBanco    := {} as array
    local cCriterio := "" 
    local cPrgUsr   := PADR( "BLPRGUS", 10, ' ' )

    default aTitulo := {}
    default aBcoUsr := {}

    aRatedTit := aClone( aTitulo )

    if !Empty( cMVALPRI )
        
        DBSelectArea( cMVALPRI )
        ( cMVALPRI )->( DBSetOrder( 2 ) )       // filial + prior
        ( cMVALPRI )->( DBGoTop() )

        if ! ( cMVALPRI )->( EOF() ) .and. len( aBanco ) == 0
            aBanco := {}
            while ! ( cMVALPRI )->( EOF() ) .and. len( aBanco ) == 0

                if &( cMVALPRI +'->'+ cMVALPRI +'_ID' ) == 'BC'     // banco preferencial do cliente
                    
                    // Valida existência física do campo com o banco preferencial do cliente para emissão de boletos
                    if SA1->( FieldPos( 'A1_X_BCBOL' ) ) > 0 
                        
                        DBSelectArea( 'SA1' )
                        SA1->( DBSetOrder( 1 ) )
                        if SA1->( DBSeek( FWxFilial( 'SA1' ) + getData( 'cliente', aTitulo ) + getData( 'loja', aTitulo ) ) )
                            
                            // Verifica se o banco de preferência está preenchido
                            if !Empty( SA1->A1_X_BCBOL )

                                DBSelectArea( 'SEE' )
                                SEE->( DBSetOrder( 1 ) )
                                if SEE->( DBSeek( FWxFilial( "SEE" ) + SA1->A1_X_BCBOL ) )

                                    // Percorre a tabela SEE para verificar se o banco preferencial do cliente tem configuração para
                                    // impressão de boletos
                                    while ! SEE->( EOF() ) .and. SEE->EE_FILIAL + FWxFilial( "SEE" ) + SA1->A1_X_BCBOL

                                        // Verifica se o banco tem configuração habilitada para geração de boletos
                                        if SEE->( FieldPos( 'EE_X_EMBOL' ) ) > 0 .and. SEE->EE_X_EMBOL
                                            aBanco := { SEE->EE_CODIGO,;
                                                        SEE->EE_AGENCIA,;
                                                        SEE->EE_CONTA,;
                                                        SEE->EE_SUBCTA }
                                            cCriterio := 'Preferencia do Cliente'
                                        endif

                                        SEE->( DBSkip() )
                                    enddo
                                endif

                            endif

                        endif

                    endif

                elseif &( cMVALPRI +'->'+ cMVALPRI +'_ID' ) == 'BU'     // Banco escolhido pelo usuário
                    
                    // Verifica se o usuário já escolheu o banco anteriormente
                    if Len( aBcoUsr ) == 0
                        // Grupo de perguntas onde o usuário poderá escolher o banco de sua preferência para emitir os boletos
                        if Pergunte( cPrgUsr, .T. )
                            aBcoUsr := { MV_PAR01 /* cBanco */,;
                                         MV_PAR02 /* cAgencia */,;
                                         MV_PAR03 /* cConta */,;
                                         MV_PAR04 /* cSubConta */ }
                        endif
                    endif

                    if len( aBcoUsr ) > 0

                        DBSelectArea( 'SEE' )
                        SEE->( DBSetOrder( 1 ) )
                        if SEE->( DBSeek( FWxFilial( "SEE" ) + aBcoUsr[1] + aBcoUsr[2] + aBcoUsr[3] + aBcoUsr[4] ) )

                            // Verifica se o banco tem configuração habilitada para geração de boletos
                            if SEE->( FieldPos( 'EE_X_EMBOL' ) ) > 0 .and. SEE->EE_X_EMBOL
                                aBanco := { SEE->EE_CODIGO,;
                                            SEE->EE_AGENCIA,;
                                            SEE->EE_CONTA,;
                                            SEE->EE_SUBCTA }
                                cCriterio := 'Escolhido pelo Usuario'
                            endif

                        endif

                    endif

                elseif &( cMVALPRI +'->'+ cMVALPRI +'_ID' ) == 'CG'     // Cobertura de garantias

                    DBSelectArea( cMVALGAR )
                    ( cMVALGAR )->( DBSetOrder( 2 ) )   // FILIAL + PRIOR
                    ( cMVALGAR )->( DBGoTop() )

                    if ( cMVALGAR )->( DBSeek( FWxFilial( cMVALGAR ) ) )
                        while ! ( cMVALGAR )->( EOF() ) .and. &( cMVALGAR +'->'+ cMVALGAR + '_FILIAL' ) == FWxFilial( cMVALGAR ) .and. len( aBanco ) == 0
                            
                            // Valida faixa de data de controle das garantias
                            if &( cMVALGAR +'->'+ cMVALGAR + '_DTINI' ) <= dDataBase .and.;
                             ( Empty( &( cMVALGAR +'->'+ cMVALGAR + '_DTFIM' ) ) .or. &( cMVALGAR +'->'+ cMVALGAR + '_DTFIM' ) >= dDataBase ) .and.;
                             &( cMVALGAR +'->'+ cMVALGAR + '_VLATI' ) < &( cMVALGAR +'->'+ cMVALGAR + '_VLALVO' )
                                
                                DBSelectArea( 'SEE' )
                                SEE->(DBSetOrder( 1 ) )
                                if SEE->( DBSeek( FWxFilial( 'SEE' ) +; 
                                    &( cMVALGAR +'->'+ cMVALGAR + '_BCO' ) +;
                                    &( cMVALGAR +'->'+ cMVALGAR + '_AGE' ) +;
                                    &( cMVALGAR +'->'+ cMVALGAR + '_CTA' ) +;
                                    &( cMVALGAR +'->'+ cMVALGAR + '_SUB' ) ) )
                                    
                                    // Verifica se o banco tem configuração habilitada para geração de boletos
                                    if SEE->( FieldPos( 'EE_X_EMBOL' ) ) > 0 .and. SEE->EE_X_EMBOL
                                        aBanco := { SEE->EE_CODIGO,;
                                                    SEE->EE_AGENCIA,;
                                                    SEE->EE_CONTA,;
                                                    SEE->EE_SUBCTA }
                                        cCriterio := 'Controle de Garantias'
                                    endif

                                endif
                                
                            endif

                            ( cMVALGAR )->( DBSkip() )
                        enddo

                    endif

                elseif &( cMVALPRI +'->'+ cMVALPRI +'_ID' ) == 'BF'     // Banco escolhido pelo financeiro

                    // Verifica se o banco preferencial do financeiro foi preenchido
                    if !Empty( &( cMVALPRI +'->'+ cMVALPRI +'_BCO' ) )

                        DBSelectArea( 'SEE' )
                        SEE->( DBSetOrder( 1 ) )    // FILIAL + BANCO + AGENCIA + CONTA + SUBCTA
                        if SEE->( DBSeek( FWxFilial( 'SEE' ) +; 
                            &( cMVALPRI +'->'+ cMVALPRI +'_BCO' ) +;
                            &( cMVALPRI +'->'+ cMVALPRI +'_AGE' ) +;
                            &( cMVALPRI +'->'+ cMVALPRI +'_CTA' ) +;
                            &( cMVALPRI +'->'+ cMVALPRI +'_SUB' ) ) )
                            
                            // Verifica se o banco tem configuração habilitada para geração de boletos
                            if SEE->( FieldPos( 'EE_X_EMBOL' ) ) > 0 .and. SEE->EE_X_EMBOL
                                aBanco := { SEE->EE_CODIGO,;
                                            SEE->EE_AGENCIA,;
                                            SEE->EE_CONTA,;
                                            SEE->EE_SUBCTA }
                                cCriterio := "Escolhido pelo Financeiro"
                            endif

                        endif

                    endif
                    
                endif

                ( cMVALPRI )->( DBSkip() )
            enddo

        endif

    endif
    
    // Se nenhum banco veio preenchido, utiliza o banco default do parâmetro interno
    if len( aBanco ) == 0 .and. !Empty( cMVBCFAT )
        aBanco := StrTokArr( cMVBCFAT, '/' )
        // Se mesmo o parâmetro interno não estiver preenchido corretamente, mantém o vetor vazio
        if len( aBanco ) == 4
            aBanco[1] := PADR( AllTrim(aBanco[1]), TAMSX3( 'EE_CODIGO'  )[1], ' ' )
            aBanco[2] := PADR( AllTrim(aBanco[2]), TAMSX3( 'EE_AGENCIA' )[1], ' ' )
            aBanco[3] := PADR( AllTrim(aBanco[3]), TAMSX3( 'EE_CONTA'   )[1], ' ' )
            aBanco[4] := PADR( AllTrim(aBanco[4]), TAMSX3( 'EE_SUBCTA'  )[1], ' ' )
            cCriterio := "Parâmetro Interno MV_X_BCFAT"
        else
            aBanco := {}
        endif
    endif

    // Atribui código de banco, agencia e conta para impressão do boleto
    if len( aBanco ) > 0
        ConOut( 'BOLRULES - '+ DtoC(Date()) +' '+ Time() +' - BANCO SELECIONADO ('+ cCriterio +') '+ aBanco[1] +'|'+ aBanco[2]+ '|'+ aBanco[3] +'|'+ aBanco[4] )
        
        // Adiciona ao vetor o banco, agencia e conta selecionados na regra de prioridades
        aAdd( aRatedTit, {"banco"   , aBanco[1] } )
        aAdd( aRatedTit, {"agencia" , aBanco[2] } )
        aAdd( aRatedTit, {"conta"   , aBanco[3] } )
        aAdd( aRatedTit, {"subconta", aBanco[4] } )

        U_BOLGARCT( aRatedTit, /* lSum (default .T.) */ )
    else
        ConOut( 'BOLRULES - '+ DtoC(Date()) +' '+ Time() +' - BANCO NAO DEFINIDO!' )
    endif

return aRatedTit

/*/{Protheus.doc} GetPos
Função que retorna a posição de um campo no vetor de dados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2022
@param cField, character, campo a ser pesquisado
@param aInfo, array, vetor de informações
@return numeric, nPos
/*/
static function GetPos( cField, aInfo )
return aScan( aInfo, {|x| AllTrim( x[1] ) == AllTrim( cField ) } )

/*/{Protheus.doc} GetData
Função para retornar a informação do campo referente ao registro atual
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2022
@param cField, character, identificador do campo
@param aInfo, array, vetor de informações
@return variadic, xData
/*/
static function GetData( cField, aInfo )
    local xData := Nil
    xData := aInfo[ getPos( cField, aInfo ) ][02]
return xData

/*/{Protheus.doc} U_BOLRLTST
Função para testar as regras de prioridade da rotina de emissão de boleto com base nos critérios definidos pelo financeiro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 04/10/2022
/*/
Function U_BOLRLTST()
    
    local aArea    := getArea()
    local aTitulos := {} as array
    local nX       := 0  as numeric
    local aTitCR   := {} as array

    DBSelectArea( 'SE1' )
    SE1->( DBSetOrder( 1 ) )
    SE1->( DBSeek( FWxFilial( 'SE1' ) + "TST000001   01NF " ) )

    aTitCR := U_BOLTITCR( SE1->(Recno()) )
    if len( aTitCR ) > 0  
        aAdd( aTitulos, aClone( aTitCR ) )
    endif

    SE1->( DBSeek( FWxFilial( 'SE1' ) + "TST000002   01NF " ) )

    aTitCR := U_BOLTITCR( SE1->(Recno()) )
    if len( aTitCR ) > 0
        aAdd( aTitulos, aClone( aTitCR ) )
    endif
    
    if len( aTitulos ) > 0
        for nX := 1 to len( aTitulos )
            aTitulos[nX] := U_BOLPRIOR( aTitulos[nX] )
        next nX
    endif

    MsgInfo( varInfo( 'Titulos', aTitulos ), 'Resultado' )    

    restArea( aArea )
return Nil

/*/{Protheus.doc} U_BOLTITCR
Função padrão para montagem do vetor do titulo de onde sairão as informações para impressão do boleto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 02/11/2022
@param nRecSE1, numeric, Recno da tabela SE1
@param cOrigem, character, indica a origem de onde a função está sendo chamada (não obrigatorio)
@return array, aTitStruct
/*/
Function U_BOLTITCR( nRecSE1, cOrigem )
    
    Local aArea := getArea()
    Local aTitStruct := {} as array
    local aFilters
    local lEvalFil := .T. as logical
    local nX := 0 as numeric

    Default nRecSE1 := 0
    Default cOrigem := "SE1"

    // PE para o cliente aplicar uma regra de filtro específica na hora de imprimir os boletos
    // Exemplo: {{"E1_TIPO != 'FT ' "},{"E1_PREFIXO == 'BOL'"}}
    // O sistema vai aplicar todos os filtros e, sendo ao menos um deles verdadeiro, o boleto não será impresso
    if ExistBlock( "BOLFILCR" )
        aFilters := ExecBlock( "BOLFILCR",.F.,.F.,{cOrigem} )
        if ValType( aFilters ) != "A"
            Help( ,, 'BOLFILCR',, 'Ponto de Entrada implementado de maneira incorreta!', 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{ 'Verifique com a equipe técnica responsável pelo sistema para que o Ponto de Entrada seja corrigido!' } )
            restArea( aArea )
            return aTitStruct
        endif
    endif

    if nRecSE1 > 0
        
        // Posiciona no titulo CR
        DBSelectArea( 'SE1' )
        SE1->( DBGoTo( nRecSE1 ) )

        // Avalia todos os filtros para saber se o boleto pode ser impresso
        if ValType( aFilters ) == 'A' .and. len( aFilters ) > 0
            for nX := 1 to len( aFilters )
                lEvalFil := iif( lEvalFil, &( aFilters[nX] ), lEvalFil )
            next nX
        endif

        if lEvalFil
            aAdd( aTitStruct, {"prefixo", SE1->E1_PREFIXO } )
            aAdd( aTitStruct, {"numero" , SE1->E1_NUM } )
            aAdd( aTitStruct, {"parcela", SE1->E1_PARCELA } )
            aAdd( aTitStruct, {"tipo"   , SE1->E1_TIPO } )
            aAdd( aTitStruct, {"cliente", SE1->E1_CLIENTE } )
            aAdd( aTitStruct, {"loja"   , SE1->E1_LOJA } )
            aAdd( aTitStruct, {"reimpressao", !Empty( SE1->E1_NUMBCO ) } )
            aAdd( aTitStruct, {"recno"  , SE1->( Recno() ) } )
            aAdd( aTitStruct, {"valor"  , SE1->E1_SALDO } )
            aAdd( aTitStruct, {"emissao", SE1->E1_EMISSAO } )
            aAdd( aTitStruct, {"vencimento", SE1->E1_VENCREA } )
            if cOrigem == 'SF2'     // Faturamento Doc. de Saída
                aAdd( aTitStruct, { "condicao", SF2->F2_COND } )
            endif
        endif
    endif

    restArea( aArea )
return aTitStruct

/*/{Protheus.doc} genObject
Função para criar um objeto FWMSPrinter para imprimir os boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/12/2022
@param lPreview, logical, indica se deve visualizar o arquivo PDF após a geração ou não
@return object, oNewObj
/*/
static function genObject( lPreview )
 
    local oBoletos               as object
    local cNomePDF        := cEmpAnt + cFilAnt + FWTimeStamp() + '.rel'
    local lAdjustToLegacy := .F. as logical
    local lDisableSetup   := .T. as logical

    default lPreview := .F.

    // Instancia um objeto da classe FWMSPrinter
    oBoletos := FWMSPrinter():New(cNomePDF, IMP_PDF, lAdjustToLegacy, , lDisableSetup, , , , .F., , .F.)
    oBoletos:SetResolution(78)
    oBoletos:SetPortrait()
    oBoletos:SetPaperSize(DMPAPER_A4) 
    oBoletos:SetMargin(10,10,10,10)
    oBoletos:linjob   := .F. 
    oBoletos:cPathPDF := CLOCPDF
    oBoletos:SetDevice(IMP_PDF)
    oBoletos:SetViewPDF( lPreview )

return oBoletos
