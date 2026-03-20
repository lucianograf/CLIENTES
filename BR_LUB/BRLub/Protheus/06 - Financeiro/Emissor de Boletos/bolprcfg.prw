#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} BOLPRCFG
Função principal para controle de garantias e prioridades de banco no momento da emissão de novos boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 02/09/2022
/*/
user function BOLPRCFG()
    
    local aArea    := getArea()
    local oDlgPri        as object
    local aSize    := MsAdvSize()
    local bValid   :={|| .T. }
    local bConfirm :={|| iif( Confirma(), oDlgPri:End(), Nil )}
    local bCancel  :={|| oDlgPri:End() }
    local aButtons := {} as array
    local bInit    :={|| EnchoiceBar( oDlgPri, bConfirm, bCancel,,aButtons,,,.F. /*lMashups*/, .F. /*lImpCad*/, .F. /*lBotPad*/, .F. /*lConfirma*/, .F. /*lWalkthru*/ )}
    local oLayer         as object
    local cTitulo  := AllTrim(SM0->M0_FILIAL) + ' | Configurador de Prioridades do Emissor de Boletos'
    local nPerc    := Round((30/(aSize[5]/2))*100,2)
    local oWin01         as object
    local oWin02         as object
    local oBrwPri        as object
    local aHdrPri  := {} as array
    local aHdrGar  := {} as array
    local aFields  := {} as array
    local nX       := 0  as numeric
    local oBrwGar        as object
    local aFldGar  := {} as array
    local oWin03         as object
    local oWin04         as object
    local oBtEd1         as object
    local oBtEd2         as object
    local oBtNew         as object
    local oBtDel         as object
    local cOptions := "" as character

    Private cMVALPRI  := AllTrim( SuperGetMV( 'MV_X_BLPRI',,'' ) )
    Private cMVALGAR  := AllTrim( SuperGetMV( 'MV_X_BLGAR',,'' ) )
    Private cCadastro := "Critérios de Prioridade para Emissão de Boletos"

    // Valida conteúdo do parâmetro que vai definir o alias da tabela de prioridades na emissão dos boletos
    if Empty( cMVALPRI )
        Hlp( 'Critérios de Priorização', 'Alias para configurações de prioridades não configurado',;
        'Utilize o parâmetro MV_X_BLPRI para definir o alias da tabela onde as prioridades serão configuradas.'  )
        return Nil
    endif

    // Valida a configuração do parâmetro que vai definir o alias da tabela para controle das garantias
    if Empty( cMVALGAR )
        Hlp( 'Controle de Garantias', 'Alias para configurações e controle das garantias não configurado',;
        'Utilize o parâmetro MV_X_BLGAR para definir o alias da tabela onde serão feitas as configurações e controles das garantias.' )
        return Nil
    endif

    DBSelectArea( cMVALPRI )
    ( cMVALPRI )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR

    DBSelectArea( cMVALGAR )
    ( cMVALGAR )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR

    // Função que faz o pré-cadastro dos critérios para que o usuário apenas defina a prioridade entre os critérios
    Processa( {|| defaultInfo() }, 'Aguarde!','Verificando dados do ambiente...' )

    // Prepara os campos do cabeçalho do grid
    aFields := FWSX3Util():GetAllFields( cMVALPRI, .T. /* lVirtuais */)
    for nX := 1 to len( aFields )
        if ! "FILIAL" $ aFields[nX]
            aAdd( aHdrPri, FWBrwColumn():New() )
            aHdrPri[Len( aHdrPri )]:SetTitle( AllTrim( GetSX3Cache( aFields[nX], 'X3_TITULO' ) ) )
            aHdrPri[Len( aHdrPri )]:SetType( GetSX3Cache( aFields[nX], 'X3_TIPO' ) )
            aHdrPri[Len( aHdrPri )]:SetSize( GetSX3Cache( aFields[nX], 'X3_TAMANHO' ) )
            aHdrPri[Len( aHdrPri )]:SetDecimal( GetSX3Cache( aFields[nX], 'X3_DECIMAL' ) )
            aHdrPri[Len( aHdrPri )]:SetPicture( GetSX3Cache( aFields[nX], 'X3_PICTURE' ) )
            aHdrPri[Len( aHdrPri )]:SetData( &('{||'+ cMVALPRI +'->'+ aFields[nX]+' }' ) )
            if !Empty( GetSX3Cache( aFields[nX], 'X3_CBOX' ) )
                if Trim(aFields[nX]) == cMVALPRI +'_ID'
                    aHdrPri[Len( aHdrPri )]:SetOptions( StrTokArr( U_BLCBOID(), ';' ) )
                    aHdrPri[Len( aHdrPri )]:SetSize( MaxTamOpt( U_BLCBOID() ) )
                else
                    aHdrPri[Len( aHdrPri )]:SetOptions( StrTokArr( GetSX3Cache( aFields[nX], 'X3_CBOX' ), ';' ) )
                    aHdrPri[Len( aHdrPri )]:SetSize( MaxTamOpt( GetSX3Cache( aFields[nX], 'X3_CBOX' ) ) )
                endif
            endif
        endif
    next nX

    // Prepara os campos do cabeçalho do grid de controle de garantias
    aFldGar := FWSX3Util():GetAllFields( cMVALGAR, .T. /* lVirtuais */)
    for nX := 1 to len( aFldGar )
        if ! "FILIAL" $ aFldGar[nX]
            aAdd( aHdrGar, FWBrwColumn():New() )
            aHdrGar[Len( aHdrGar )]:SetTitle( AllTrim( GetSX3Cache( aFldGar[nX], 'X3_TITULO' ) ) )
            aHdrGar[Len( aHdrGar )]:SetType( GetSX3Cache( aFldGar[nX], 'X3_TIPO' ) )
            aHdrGar[Len( aHdrGar )]:SetSize( GetSX3Cache( aFldGar[nX], 'X3_TAMANHO' ) )
            aHdrGar[Len( aHdrGar )]:SetDecimal( GetSX3Cache( aFldGar[nX], 'X3_DECIMAL' ) )
            aHdrGar[Len( aHdrGar )]:SetPicture( GetSX3Cache( aFldGar[nX], 'X3_PICTURE' ) )
            aHdrGar[Len( aHdrGar )]:SetData( &('{||'+ cMVALGAR +'->'+ aFldGar[nX]+' }' ) )
            if !Empty( GetSX3Cache( aFldGar[nX], 'X3_CBOX' ) )
                // Quando houver função para retornar o conteúdo do combo, trata manualmente
                if '#' $ GetSX3Cache( aFldGar[nX], 'X3_CBOX' )
                    cOptions := &( StrTran( AllTrim( GetSX3Cache( aFldGar[nX], 'X3_CBOX' ) ), '#','') )
                    aHdrGar[Len( aHdrGar )]:SetOptions( StrTokArr( cOptions, ';' ) )
                else
                    aHdrGar[Len( aHdrGar )]:SetOptions( StrTokArr( &(GetSX3Cache( aFldGar[nX], 'X3_CBOX' )), ';' ) )
                endif
                aHdrGar[Len( aHdrGar )]:SetSize( MaxTamOpt( GetSX3Cache( aFldGar[nX], 'X3_CBOX' ) ) )
            endif
        endif
    next nX

    // Define criação de um Dialog utilizando toda a área de tela disponível
    oDlgPri := TDialog():New( aSize[1],aSize[2],aSize[6],aSize[5],cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    
    // Monta recurso de camadas para facilitar acomodação dos objetos
    oLayer := FWLayer():new()
    oLayer:Init( oDlgPri )
    oLayer:AddColumn( 'Col01', 100-((30/(aSize[6]/2))*100), .T. )
    oLayer:AddColumn( 'Col02', ((30/(aSize[6]/2))*100), .T. )
    oLayer:AddWindow( 'Col01', 'Win01', 'Critérios de Priorização', 50-nPerc, .F., .T., {|| },,)
    oLayer:AddWindow( 'Col01', 'Win02', 'Controle de Garantias', 50-nPerc, .F., .T., {|| },,)
    oLayer:AddWindow( 'Col02', 'Btn01', 'Menu', 50-nPerc, .F., .T., {|| },, )
    oLayer:AddWindow( 'Col02', 'Btn02', 'Menu', 50-nPerc, .F., .T., {|| },, )
    oWin01 := oLayer:GetWinPanel( 'Col01', 'Win01' )        // Grid superior
    oWin02 := oLayer:GetWinPanel( 'Col01', 'Win02' )        // Grid inferior
    oWin03 := oLayer:GetWinPanel( 'Col02', 'Btn01' )        // Botões do lado direito superior
    oWin04 := oLayer:GetWinPanel( 'Col02', 'Btn02' )        // Botões do lado direiti inferior

    // Monta grid para edição das prioridades em relação ao critério
    oBrwPri := FWBrowse():New( oWin01 )
    oBrwPri:SetDataTable()
    oBrwPri:SetAlias( cMVALPRI )
    oBrwPri:DisableConfig()
    oBrwPri:DisableSeek()
    oBrwPri:DisableSaveConfig()
    oBrwPri:DisableReport()
    oBrwPri:AddStatusColumns( {|| "UP_MDI.PNG"  }, {|| changePos( oBrwPri, "+" ) } )
    oBrwPri:AddStatusColumns( {|| "DOWN_MDI.PNG" }, {|| changePos( oBrwPri, "-" ) } )
    oBrwPri:SetColumns( aHdrPri )
    oBrwPri:Activate(.T.)

    // Define o grid da edição dos valores de garantias a serem controlados
    oBrwGar := FWBrowse():New( oWin02 )
    oBrwGar:SetDataTable()
    oBrwGar:SetAlias( cMVALGAR )
    oBrwGar:DisableConfig()
    oBrwGar:DisableSeek()
    oBrwGar:DisableSaveConfig()
    oBrwGar:DisableReport()
    oBrwGar:AddStatusColumns( { || "UP_MDI.PNG" }, {|| changePos( oBrwGar, "+" ) } )
    oBrwGar:AddStatusColumns( { || "DOWN_MDI.PNG" }, {|| changePos( oBrwGar, "-" ) } )
    oBrwGar:SetColumns( aHdrGar )
    oBrwGar:Activate(.T.)

    // Botões do browse superior para aumentar/diminuir prioridade
    oBtEd1 := TButton():New( 002, 002, "&Editar",oWin03,{|| cCadastro := "Critérios de Prioridade - Editar Prioridade",;
                                                        AxAltera( oBrwPri:GetAlias(), (oBrwPri:GetAlias())->(Recno()), 4 ),;
                                                        oBrwPri:Refresh(.T.) }, (oWin03:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )
    
    // Botões do browse inferior para aumentar/diminuir prioridade em relação aos demais registros
    oBtNew := TButton():New( 002, 002, "&Incluir" ,oWin04,{|| cCadastro := "Controle de Garantias - Incluir",;
                                                        AxInclui( oBrwGar:GetAlias(), (oBrwGar:GetAlias())->(Recno()), 3 ),;
                                                        oBrwGar:Refresh(.T.) }, (oWin04:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtEd2 := TButton():New( 020, 002, "&Alterar" ,oWin04,{|| cCadastro := "Controle de Garantias - Alterar",;
                                                        AxAltera( oBrwGar:GetAlias(), (oBrwGar:GetAlias())->(Recno()), 4 ),;
                                                        oBrwGar:Refresh(.T.) }, (oWin04:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtDel := TButton():New( 038, 002, "E&xcluir" ,oWin04,{|| cCadastro := "Controle de Garantias - Excluir",;
                                                        AxDeleta( oBrwGar:GetAlias(), (oBrwGar:GetAlias())->(Recno()), 5 ),;
                                                        (oBrwGar:GoBottom(.T.)),; 
                                                        (oBrwGar:GoTop(.T.)),; 
                                                        oBrwGar:Refresh(.T.),;
                                                        oDlgPri:Refresh() }, (oWin04:NWIDTH/2)-4, 16,,,.F.,.T.,.F.,,.F.,,,.F. )

    oDlgPri:Activate(,,,.T., bValid,,bInit )

    restArea( aArea )
return Nil

/*/{Protheus.doc} BOLVALID
Valid dos campos da tabela de critérios de prioridades
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2022
@param cField, character, ID de identificação interna dos campos
@return logical, lValidated
/*/
user function BOLVALID( cField )
    local lValidated := .T.
    if cField == 'BCO'
        if Empty( &( 'M->' + cMVALPRI + '_BCO' ) )
            &( 'M->' + cMVALPRI + '_AGE' ) := " "
            &( 'M->' + cMVALPRI + '_CTA' ) := " "
            &( 'M->' + cMVALPRI + '_SUB' ) := " "
        else
            lValidated := ExistCpo( "SEE", &( 'M->' + cMVALPRI + '_BCO' ), 1 )
        endif
    endif
return lValidated

/*/{Protheus.doc} BOLWHEN
When dos campos da tabela de critérios de priorização
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2022
@param cField, character, ID de identificaçao interna dos campos
@return logical, lWhen
/*/
user function BOLWHEN( cField )
    local lWhen := .T.
    if cField == 'BCO'
        // Libera edição do banco apena quando for para o Banco Padrão definido pelo Financeiro
        lWhen := &( 'M->' + cMVALPRI + '_ID' ) == 'BF'
    endif
return lWhen

/*/{Protheus.doc} MaxTamOpt
Função para encontrar o tamanho máximo de um campo do tipo combo para setar tamanho do campo no browse
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/09/2022
@param cOptions, character, conteúdo do combo
@return numeric, nMax
/*/
static function MaxTamOpt( cOptions )
    local nMax := 1 as numeric
    local aOptions := StrTokArr(AllTrim( iif( '#' $ cOptions, &( StrTran( cOptions, '#','' ) ), cOptions ) ),";")
    aEval( aOptions, {|x| nMax := iif( nMax > len( AllTrim(StrTokArr( x, '=' )[2]) ), nMax, len( AllTrim(StrTokArr( x, '=' )[2]) ) ) } )
return nMax

/*/{Protheus.doc} changePos
Função para aumentar/diminuir prioridade em relação aos demais registros do browse posicionado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 03/09/2022
@param oBrowse, object, Objeto do browse que deve receber a alteração
@param cUpDown, character, + (deve aumentar a prioridade) - (deve diminuir a prioridade)
/*/
static function changePos( oBrowse, cUpDown )
    
    local cAli := oBrowse:GetAlias()
    local cPrior  := &( cAli +'->'+ cAli + '_PRIOR' )
    local cNewPrior := "" as chracter
    local nRecAtu := ( cAli )->( Recno() )
    
    if !( cAli )->( EOF() ) .or. !Empty( cPrior )

        ( cAli )->( DBSkip( iif( cUpDown == "+", -1, 1 ) ) )
        
        if ( cAli )->( Recno() ) != nRecAtu .and. ! ( cAli )->( EOF() ) 
            
            cNewPrior := &( cAli +'->'+ cAli +'_PRIOR' )
            nRecNext  := ( cAli )->( Recno() )
            
            RecLock( cAli, .F. )
            &( cAli +'->'+ cAli +'_PRIOR' ) := cPrior
            ( cAli )->( MsUnlock() )
            
            ( cAli )->( DBGoTo( nRecAtu ) )
            RecLock( cAli, .F. )
            &( cAli +'->'+ cAli +'_PRIOR' ) := cNewPrior
            ( cAli )->( MsUnlock() )

        endif

        ( cAli )->( DbGoTop() )
        oBrowse:Refresh(.T.)
        
        if nRecAtu > 0
            ( cAli )->( DbGoTo( nRecAtu ) )
            oBrowse:GoTo( nRecAtu )
        endif

    endif
    

return Nil

/*/{Protheus.doc} defaultInfo
Função para cadastrar automaticamente os critérios de prioridade na tabela 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 02/09/2022
/*/
static function defaultInfo()

    local aDefault := {} as array
    local cID      := "" as character
    local nX       := 0  as numeric
    local cPrior   := LastPrior()
    
    // Captura informações do combo
    aDefault := StrTokArr( AllTrim( U_BLCBOID() ), ';' )
    
    // Define o tamanho da régua de processamento
    ProcRegua( len( aDefault ) )

    DBSelectArea( cMVALPRI )
    ( cMVALPRI )->( DBSetOrder( 1 ) )       // FILIAL + ID

    if len( aDefault ) > 0
        for nX := 1 to len( aDefault )
            
            // Comando evolução da régua de processamento
            IncProc('Avaliando critério '+ cValToChar(nX) +'/'+ cValToChar( len( aDefault ) ) )

            // Formata o ID com o tamanho necessário para o campo
            cID   := PADR(StrTokArr( aDefault[nX],'=' )[1],TAMSX3( cMVALPRI +'_ID' )[1], ' ')

            // Verifica se consegue encontrar o critério cadastrado na tabela
            if ! ( cMVALPRI )->( DBSeek( FWxFilial( cMVALPRI ) + cID ) )
                
                // Incrementa sequencial
                cPrior := Soma1( cPrior )

                RecLock( cMVALPRI, .T. )
                &(cMVALPRI +'->'+ cMVALPRI +'_FILIAL') := FWxFilial( cMVALPRI )
                &(cMVALPRI +'->'+ cMVALPRI +'_ID')     := cID
                &(cMVALPRI +'->'+ cMVALPRI +'_PRIOR')  := cPrior
                ( cMVALPRI )->( MsUnlock() )

            endif

        next nX

    endif

    // Devolve o indice utilizado para correta ordenação dos registros no browse
    ( cMVALPRI )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR

return Nil

/*/{Protheus.doc} LastPrior
Seleciona a maior prioridade gravada na tabela de critérios
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 02/09/2022
@return character, cLast
/*/
static function LastPrior()
    
    local cLast := "" as character
    
    DBSelectArea( cMVALPRI )
    ( cMVALPRI )->( DBSetOrder(2))      // FILIAL + PRIOR
    ( cMVALPRI )->( LastRec() )
    cLast := &( cMVALPRI +'->'+ cMVALPRI +'_PRIOR' )
    
return cLast

/*/{Protheus.doc} BLLSTGAR
Função para identificar a última prioridade cadastrada no grid de controle de garantias
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/09/2022
@return character, cLastGar
/*/
user function BLLSTGAR()
    
    local cLastGar := StrZero( 0, TAMSX3( cMVALGAR +'_PRIOR' )[1] )
    
    // Posiciona na tabela de controle de garantias com o índice setado por prioridade
    DBSelectArea( cMVALGAR )
    ( cMVALGAR )->( DBSetOrder( 2 ) )       // FILIAL + PRIOR
    ( cMVALGAR )->( LastRec() )
    
    // Se retornar conteúdo vazio é porque a tabela está vazia
    if !Empty( &( cMVALGAR +'->'+ cMVALGAR + '_PRIOR' ) )
        cLastGar := &( cMVALGAR +'->'+ cMVALGAR + '_PRIOR' )
    endif

return cLastGar

/*/{Protheus.doc} Confirma
Função de confirmação do Dialog de configuração das prioridades do emissor de boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 01/09/2022
@return logical, lConfirm
/*/
static function Confirma()
    local lConfirm := .T.
return lConfirm

/*/{Protheus.doc} hlp
FUnção simplificada para apresentação do help
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/19/2022
@param cTitulo, character, título da mensagem
@param cMensagem, character, descricao da mensagem
@param cHelp, character, texto de ajuda
/*/
static function hlp( cTitulo, cMensagem, cHelp )
return Help( ,, cTitulo,, cMensagem, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )

/*/{Protheus.doc} U_BOLGARCT
Função para adicionar ou remover valor do controle de garantias
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@param aRatedTit, array, vetor contendo os dados do título com banco, agencia e conta definidos para impressão do boleto
@param lSum, logical, indica se deve somar ou subtrair (.T. Somar ou .F. Subtrair) (default .T.)
@since 03/10/2022
/*/
function U_BOLGARCT( aRatedTit, lSum )

    local aArea := getArea()
    
    private cMVALGAR := AllTrim( SuperGetMV( 'MV_X_BLGAR',,'' ) )       // Alias da tabela de controle de garantias

    default aRatedTit := {}
    default lSum      := .T.

    // Executa apenas se existir definição para o alias de controle de garantias e se o parâmetro do título veio preenchido
    if !Empty( cMVALGAR ) .and. len( aRatedTit ) > 0 .and. gt( aRatedTit, 'banco' ) != Nil

        // Controle de garantias, verifica se tem controle de garantia ativa para a conta utilizada para emitir o boleto
        DBSelectArea( cMVALGAR )
        ( cMVALGAR )->( DBSetOrder( 1 ) )       // FILIAL + BCO + AGE + CTA + SUB
        if ( cMVALGAR )->( DBSeek( FWxFilial( cMVALGAR ) + gt( aRatedTit, 'banco' ) + gt( aRatedTit, 'agencia' ) +;
            gt( aRatedTit, 'conta' ) + gt( aRatedTit, 'subconta' ) ) )

            // Verifica se o registro do controle de garantias está dentro da faixa de datas programada para o controle
            if &( cMVALGAR +'->'+ cMVALGAR + '_DTINI' ) <= dDataBase .and.;
                ( Empty( &( cMVALGAR +'->'+ cMVALGAR + '_DTFIM' ) ) .or. &( cMVALGAR +'->'+ cMVALGAR + '_DTFIM' ) >= dDataBase ) 
                
                // Verifica se é impressão de novo boleto ou exclusão de novo boleto
                if !lSum                            // Exclusão ou cancelamento de operação somada anteriormente
                    RecLock( cMVALGAR, .F. )
                    &( cMVALGAR +'->'+ cMVALGAR + '_VLATI' ) -= gt( aRatedTit, 'valor' )
                    ( cMVALGAR )->( MsUnlock() )
                    ConOut( 'BOLGARCT - '+ DtoC( date() ) +' '+ Time() +' - BCO: '+ gt( aRatedTit, 'banco' ) +;
                                                                       ' AGE: '+ gt( aRatedTit, 'agencia' ) +;
                                                                       ' CTA: '+ gt( aRatedTit, 'conta' ) +;
                                                                       ' SUB: '+ gt( aRatedTit, 'subconta' ) +;
                                                                       ' R$: '+ AllTrim( Transform( gt( aRatedTit, 'valor' )*-1, '@E 999,999,999.99' ) ) )
                elseif &( cMVALGAR +'->'+ cMVALGAR + '_VLATI' ) < &( cMVALGAR +'->'+ cMVALGAR + '_VLALVO' )     // Valor atingido ainda é menor do que o valor alvo
                    // Verifica se não é uma reimpressão
                    if gt( aRatedTit, 'reimpressao' ) == Nil .or. ( gt( aRatedTit, 'reimpressao' ) <> Nil .and. ! gt( aRatedTit, 'reimpressao' ) )
                        RecLock( cMVALGAR, .F. )
                        &( cMVALGAR +'->'+ cMVALGAR + '_VLATI' ) += gt( aRatedTit, 'valor' )
                        ( cMVALGAR )->( MsUnlock() )
                        ConOut( 'BOLGARCT - '+ DtoC( date() ) +' '+ Time() +' - BCO: '+ gt( aRatedTit, 'banco' ) +;
                                                                       ' AGE: '+ gt( aRatedTit, 'agencia' ) +;
                                                                       ' CTA: '+ gt( aRatedTit, 'conta' ) +;
                                                                       ' SUB: '+ gt( aRatedTit, 'subconta' ) +;
                                                                       ' R$: '+ AllTrim( Transform( gt( aRatedTit, 'valor' ), '@E 999,999,999.99' ) ) )
                    endif
                endif

            endif

        endif

    endif

    restArea( aArea )
return Nil

/*/{Protheus.doc} gt
Função para retornar informação de uma posicao de um vetor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 03/10/2022
@param aRef, array, vetor de referenncia
@param cKey, variant, chave a ser retornada
@return variadic, xInfo
/*/
static function gt( aRef, cKey )
return iif( aScan( aRef, {|x| AllTrim( x[1] ) == cKey } ) > 0,;
            aRef[ aScan( aRef, {|x| AllTrim( x[1] ) == cKey } ) ][2],;
            Nil )

/*/{Protheus.doc} BLCBOID
Função responsável pela exibição das informações do combo de IDs de critérios de prioridade
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 01/09/2022
@return character, cOptions
/*/
user function BLCBOID()
    local cOptions := "" as character
    cOptions := "BC=Banco Preferencial do Cliente;"+;
                "BU=Banco Escolhido pelo Usuário;"+;
                "CG=Cobertura de Garantias;"+;
                "BF=Banco Escolhido pelo Financeiro"
return cOptions
