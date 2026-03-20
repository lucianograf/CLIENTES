#include 'totvs.ch'
#include 'topconn.ch'

#define TIT_TIPO    'FOL'       // Tipo do título que será gerado na inclusão do registro na tabela do CP
#define TIT_PREFIXO 'SAL'       // Indica o prefixo que o sistema deve utilizar para inclusão dos títulos de salários a pagar
#define TIT_IRRF    'IRF'       // Tipo utilizado para inclusão dos títulos de IRRF
#define TIT_FGTS    'FGT'       // Tipo utilizado para inclusão dos títulos de FGTS 
#define DIA_FGTS    "07"        // Dia em que deve ser provisionado o pagamento do FGTS     
#define DIA_IR      "20"        // Dia em que deve ser provisionado o pagamento do IR
#define CTB_LOTE    "008850"    // Lote contábil para lançamento dos dados da folha na contabilidade
#define CTB_SUBLOTE "001"       // Sublote contábil para lançamento dos dados da folha na contabilidade
#define DIA_PAGTO   "05"        // Dia para pagamento da folha dos colaboradores

/*/{Protheus.doc} BFFINA09
Rotina de importação de movimentação de pagamento de folha por meio de arquivo texto
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/4/2022
/*/
user function BFFINA09()

    local cFileName  := ""  as character
    local aFields    := {}  as array
    local aButtons   := getButtons()
    local oDialog           as object
    local lDone      := .F. as logical
    local bValid     :={|| .T. }
    local bConfirm   :={|| Processa({|| lDone := Confirma( aFile )},'Aguarde!','Processando inclusão de títulos...'),;
                           iif( lDone .and. AskClose(), oDialog:End(), nil )}
    local bCancel    :={|| oDialog:End() }
    local bInit      :={|| EnchoiceBar( oDialog, bConfirm, bCancel,,aButtons )} // EnchoiceBar
    local oPanel            as object
    local aBrwCol    := {}  as array
    local nCol       := 0   as numeric
    local aSize      := MsAdvSize()
    
    Private nColCGC    := 0  as numeric
    Private nColPagto  := 0  as numeric
    Private nColNome   := 0  as numeric
    Private nColCPF    := 0  as numeric
    Private nColCdFun  := 0  as numeric
    Private nColFuncao := 0  as numeric
    Private nColEvCr   := 0  as numeric
    private nColEvCrd  := 0  as numeric
    private nColVlCrd  := 0  as numeric
    private nColEvDb   := 0  as numeric
    private nColEvDbD  := 0  as numeric
    private nColVlDeb  := 0  as numeric
    private nColIndTT  := 0  as numeric
    private nColVlLiq  := 0  as numeric
    private nColVlFGT  := 0  as numeric
    Private oBrowse          as object
    Private aFile      := {} as array
    Private cMVFORFG := AllTrim( SuperGetMv( 'MV_X_FORFG' ,,"" ) ) // Fornecedor padrão para lançamento dos títulos de FGTS
    Private cMVFORIR := AllTrim( SuperGetMv( 'MV_X_FORIR' ,,"" ) ) // Fornecedor padrão para lançamento dos títulos de IRRF

    // Valida configuração do parâmetro que indica quem é o fornecedor padrão para os títulos de FGTS
    if Empty( cMVFORFG )
        Hlp( 'Fornecedor FGTS', 'O fornecedor padrão para lançamento dos títulos de FGTS não foi configurado.',;
        'Solicite ao departamento de TI para que o parâmetro MV_X_FORFG seja configurado para que você possa prosseguir.' )
        return Nil
    endif

    // Valida configuração do parâmetro que indica quem  é o fornecedor padrão para o lançamento dos títulos de IRRF
    if Empty( cMVFORIR )
        Hlp( 'Fornecedor IRRF', 'O fornecedor padrão para lançamento dos títulos de IRRF não foi configurado.',;
        'Solicite o cadastramento e configuração do fornecedor por meio do parâmetro interno MV_X_FORIR para poder prosseguir.' )
        return Nil
    endif
    // Chama função para setar os atalhos de teclado
    setHotKey()
    // Captura arquivo via smartclient no terminal do usuário
    cFileName := cGetFile( 'Arquivo de Excel CSV (*.csv) | *.csv' /* cMascara */,;
                            'Selecione o arquivo para impotar...' /* cTitulo */,;
                            Nil /* uCompat */,;
                            "" /* cLocalIni */,;
                            .F. /* lSaveDlg */,;
                            GETF_LOCALHARD,;
                            .T. /* lTree */ )
    // Valida se usuário configou seleção de algum arquivo
    if Empty( cFileName )
        return Nil
    else
        if ! File( cFileName )        // verifica se é um arquivo válido
            Hlp( 'Arquivo inválido','O arquivo selecionado/informado ['+ AllTrim( cFileName ) +'] não foi localizado!',;
                'Selecione ou informe um arquivo válido para que seja possível prosseguir' )
            Return Nil
        endif
    endif

    // Abre e realiza a leitura do arquivo
    Processa({|| setDataPos( cFileName ) }, 'Aguarde!', 'Mapeando colunas do arquivo...')
    Processa({|| aFile := getDataFile( cFileName ) }, 'Aguarde!','Realizando leitura do arquivo...' )
    Processa({|| aFile := revFile( aFile ) }, 'Aguarde!','Verificando titulos já incluidos...')
    
    // Verifica se existem informações armazenadas na variável aFile
    if len( aFile ) > 0
        
        // Campos a serem exibidos no FWBrowse
        aAdd( aFields, { 'CPF'        ,{|| aFile[ oBrowse:nAt ][01] },'@R 999.999.999-99'   , 11, 00, 1 } )
        aAdd( aFields, { 'Colaborador',{|| aFile[ oBrowse:nAt ][02] },'@!'                  , 20, 00, 1 } )
        aAdd( aFields, { 'Função'     ,{|| aFile[ oBrowse:nAt ][03] },'@x'                  , 20, 00, 1 } )
        aAdd( aFields, { 'Dt.Vcto'    ,{|| aFile[ oBrowse:nAt ][04] },'@D'                  , TAMSX3('E2_VENCTO' )[1],TAMSX3('E2_VENCTO' )[2], 0 } )
        aAdd( aFields, { 'Valor'      ,{|| aFile[ oBrowse:nAt ][05] },'@E 9,999,999.99'     , TAMSX3('E2_VALOR'  )[1],TAMSX3('E2_VALOR'  )[2], 2 } )
        aAdd( aFields, { 'Prf.'       ,{|| aFile[ oBrowse:nAt ][06] }, '@!'                 , TAMSX3('E2_PREFIXO')[1],TAMSX3('E2_PREFIXO')[2], 1 } )
        aAdd( aFields, { 'Numero'     ,{|| aFile[ oBrowse:nAt ][07] }, '@!'                 , TAMSX3('E2_NUM'    )[1],TAMSX3('E2_NUM'    )[2], 1 } )
        aAdd( aFields, { 'Parcela'    ,{|| aFile[ oBrowse:nAt ][08] }, '@!'                 , TAMSX3('E2_PARCELA')[1],TAMSX3('E2_PARCELA')[2], 1 } )
        aAdd( aFields, { 'Tipo'       ,{|| aFile[ oBrowse:nAt ][09] }, '@!'                 , TAMSX3('E2_TIPO'   )[1],TAMSX3('E2_TIPO'   )[2], 1 } )
        aAdd( aFields, { 'Tp. Mov.'   ,{|| aFile[ oBrowse:nAT ][10] }, '@!'                 , 05, 00, 1 } )
        
        for nCol := 1 to len( aFields )
            aAdd( aBrwCol, FWBrwColumn():New() )
            aBrwCol[ len( aBrwCol ) ]:SetData( aFields[nCol][2] )
            aBrwCol[ len( aBrwCol ) ]:SetTItle( aFields[nCol][1] )
            aBrwCol[ len( aBrwCol ) ]:SetPicture( aFields[nCol][3] )
            aBrwCol[ len( aBrwCol ) ]:SetSize( aFields[nCol][4] )
            aBrwCol[ len( aBrwCol ) ]:SetDecimal( aFields[nCol][5] )
            aBrwCol[ len( aBrwCol ) ]:SetAlign( aFields[nCol][6] )
        next nCol

        // Monta tela de interação com o usuário
        oDialog := TDialog():New( 0,0,aSize[6],aSize[5],'Importação de Registros da Folha',,,,,CLR_BLACK,CLR_WHITE,,,.T. )
        
        // Cria um panel para comportar o FWBrowse
        oPanel := TPanel():New( 34, 4, '', oDialog,Nil,.T.,,,,aSize[5]/2, aSize[6]/2-30 )
        oPanel:Align := CONTROL_ALIGN_ALLCLIENT

        // Define o browse para importação dos dados
        oBrowse := FWBrowse():New( oPanel )
        oBrowse:SetDataArray()
        oBrowse:SetArray( aFile )
        oBrowse:DisableConfig()
        oBrowse:DisableFilter()
        oBrowse:DisableLocate()
        oBrowse:DisableSeek()
        oBrowse:DisableReport()
        oBrowse:AddLegend( "!Empty( aFile[oBrowse:nAt][7] )", "RED"  , 'Título incluídos'  )
        oBrowse:AddLegend( "Empty( aFile[oBrowse:nAt][7] )" , "GREEN", 'Título não gerado' ) 
        oBrowse:SetColumns( aBrwCol )
        oBrowse:Activate()

        oDialog:Activate( ,,,.T., bValid, Nil, bInit )

    endif

return Nil

/*/{Protheus.doc} AskClose
Pergunta para o usuário ao final do processamento com sucesso se deseja encerrar a rotina ou manter aberta
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/28/2022
@return logical, lClose
/*/
static function AskClose()
    local lClose := .T. as logical
    lClose := Aviso( 'Processo finalizado!','Processamento finalizado com sucesso! O que deseja fazer agora?', {"Terminar","Manter Rotina Aberta"}, 3 ) == 1
return lClose

/*/{Protheus.doc} setHotKey
Função para setar as hot-keys da rotina
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/28/2022
/*/
static function setHotKey()
    SetKey( VK_F8,  {|| DeleteAll()   } )
    SetKey( VK_F7,  {|| DeleteOne()   } )
    SetKey( VK_F6,  {|| DeleteLine()  } )
    SetKey( VK_F5,  {|| U_CCxFun()    } )
    SetKey( VK_F4,  {|| U_CTAxEvent() } )
    SetKey( VK_F9,  {|| EventsVis()   } )
    SetKey( VK_F10, {|| EventsVis(.T. /* lAll */) } )
return Nil

/*/{Protheus.doc} confirma
Função que confirma gravação dos dados lidos do arquivo no contas a pagar
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@param aRegs, array, vetor com os dados para geração dos títulos no CP
@return logical, lDone
/*/
static function confirma( aRegs )

    local aArea    := getArea()
    local lDone    := .T.
    local aTitulo  := {} as array
    local nX       := 0 as numeric
    local aForn    := {} as array
    local cForn    := "" as character
    local cLoja    := "" as character
    local nSuccess := 0 as numeric
    local cNumero  := "" as character
    local aFalhas  := {} as array
    local aValCont := {} as array
    local cFalhas  := "" as character
    local cTipo    := "" as character
    local dLastDay := Nil as date
    local cNatIRF  := &( AllTrim( SuperGetMv( 'MV_IRF',,'"IRF"' ) ) )
    local cPeriodo := "" as character

    private lMsErroAuto := .F.          // Variável de controle para execução do msExecAuto

    default aRegs := {}

    if len( aRegs ) > 0  

        // Define tamanho da régua de processamento
        ProcRegua( len( aRegs ) )
            
        for nX := 1 to len( aRegs )
            
            incProc( 'Analisando/gerando título a pagar '+ cValToChar( nX ) +'/'+ cValToChar( len( aRegs ) ) )
            
            aTitulo := {}
            aForn   := getForn( aRegs[nX][1], aRegs[nX][10] )
            
            // Dá sequência apenas se enontrou fornecedor para o CPF e se o título já não foi gerado
            if Len( aForn ) > 0 .and. Empty( aRegs[nX][ 7 ] )

                // Valida preenchimento dos dados contábeis
                aValCont := validCont( aRegs[nX] )
                if len( aValCont ) > 0
                    aEval( aValCont, {|x| aAdd( aFalhas, x ) } )
                endif

                // Se validou as movimentações contábeis, prossegue com a inclusão dos títulos
                if len( aValCont ) == 0
                
                    cForn    := aForn[1]            // Codigo do fornecedor
                    cLoja    := aForn[2]            // Loja do fornecedor
                    cNaturez := aForn[3]            // Natureza automática do fornecedor
                    if Trim( aRegs[nX][10] ) == 'FOLHA'
                        cTipo := TIT_TIPO
                    elseif Trim( aRegs[nX][10] ) == 'FGTS'
                        cTipo := TIT_FGTS
                    elseif Trim( aRegs[nX][10] ) == 'IRRF'
                        cTipo := TIT_IRRF
                        // Quando a natureza do fornecedor estiver vazia, utiliza a natureza default do parâmetro MV_IRF
                        if Empty( cNaturez )
                            cNaturez := cNatIRF
                        endif
                    endif
                    cNumero := newSE2Num( TIT_PREFIXO, cTipo )
                    
                    // Identifica o último dia do mês referente ao período que está sendo pago
                    dLastDay := aRegs[nX][04] - Day(aRegs[nX][04])
                    // Monta período de referência da movimentação com base na data do último dia do mês anterior a data do pagamento
                    cPeriodo := MesExtenso( Month( dLastDay ) ) +'/'+ StrZero( Year( dLastDay ), 4 )

                    aAdd( aTitulo, { "E2_FILIAL" , FWxFilial( "SA2" ), Nil } )
                    aAdd( aTitulo, { "E2_PREFIXO", TIT_PREFIXO, Nil } )
                    aAdd( aTitulo, { "E2_NUM"    , cNumero, Nil } )
                    aAdd( aTitulo, { "E2_PARCELA", Space( TAMSX3('E2_PARCELA')[1] ), Nil } )
                    aAdd( aTitulo, { "E2_TIPO"   , cTipo, Nil } )
                    aAdd( aTitulo, { "E2_EMISSAO", dLastDay, Nil } )
                    aAdd( aTitulo, { "E2_FORNECE", cForn, Nil } )
                    aAdd( aTitulo, { "E2_LOJA"   , cLoja, Nil } )
                    aAdd( aTitulo, { "E2_VENCTO" , aRegs[nX][4], Nil } )
                    aAdd( aTitulo, { "E2_VALOR"  , aRegs[nX][5], Nil } )
                    aAdd( aTitulo, { "E2_HIST"   , cTipo +" ref. "+ cPeriodo, Nil } )
                    aAdd( aTitulo, { "E2_NATUREZ", cNaturez, Nil } )

                    Begin Transaction
                        
                        lMsErroAuto := .F.
                        MsExecAuto( {|x,y,z| FINA050( x,y,z ) }, aTitulo,,3 )
                        if lMsErroAuto
                            aAdd( aFalhas, "O titulo referente ao colaborador <b>"+ aRegs[nX][2] +"</b> não pode ser incluído, mensagem exibida durante a execução" )
                            MostraErro()
                            DisarmTransaction()
                        else
                            nSuccess++
                        endif
                    
                    End Transaction

                endif

            elseif len( aForn ) == 0 .and. Trim( aRegs[nX][10] ) == 'FOLHA'         // Se não encontrou fornecedor, essa variável vai estar sem conteúdo
                aAdd( aFalhas, "O colaborador <b>"+ aRegs[nX][2] +"</b> ("+ aRegs[nX][3] +") não foi localizado no cadastro de fornecedores" )
            elseif len( aForn ) == 0 .and. Trim( aRegs[nX][10] ) == 'FGTS'          // Se não encontrou fornecedor do FGTS, adiciona mensagem de falha
                aAdd( aFalhas, "O fornecedor para lançamento dos títulos de FGTS (Cod. <b>"+ cMVFORFG +"</b>) não foi encontrado" )
            elseif len( aForn ) == 0 .and. Trim( aRegs[nX][10] ) == 'IRRF'          // Se não encontrou fornecedor do IRRF, adiciona mensagem de falha
                aAdd( aFalhas, "O fornecedor para lançamento dos títulos de IRRF (Cod. <b>"+ cMVFORIR +"</b>) não foi encontrado" )
            endif

        next nX

    endif

    Processa({|| aFile := revFile( aFile ) }, 'Aguarde!','Verificando titulos já incluidos...')
    oBrowse:Refresh(.T.)

    if len( aFalhas ) > 0
        lDone   := .F.
        cFalhas := ""
        for nX := 1 to len( aFalhas )
            cFalhas += aFalhas[nX] + chr(13) + chr(10)
            if nX != len( aFalhas )
                cFalhas += Replicate( ' -', 20 ) + chr(13)+chr(10)
            endif
        next nX
        MsgAlert( cFalhas, 'F A L H A S ' )
    endif
    if nSuccess > 0     // Verifica se houveram casos em que foi possível incluir títulos
        MsgInfo( '<b>'+ cValToChar( nSuccess ) +'</b> títulos foram gerados!', 'Titulos Incluidos' )
    endif

    restArea( aArea )
return lDone

/*/{Protheus.doc} lancCont
Função que efetiva os lançamentos contábeis ligados aos eventos da folha de pagamento
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/26/2022
@param aReg, array, Registro atual do arquivo lido
@param aEvents, array, Eventos da folha
@return logical, lDone
/*/
static function lancCont( aReg, aEvents )
    
    local lDone    := .T. as logical
    local nX       := 0   as numeric
    local aCab     := {}  as array
    local aItens   := {}  as array
    local cItem    := Replicate( "0", TAMSX3( 'CT2_LINHA' )[1] )
    local cHist    := ""  as character
    local aLinha   := {}  as array
    local cPeriodo := ""  as character
    local dLastDay := aReg[4] - Day(aReg[4])
    local cKey     := ""  as character

    Private lMsErroAuto := .F. as logical

    default aEvents := {}

    if len( aEvents ) > 0

        // Monta período de referência da movimentação com base na data do último dia do mês anterior a data do pagamento
        cPeriodo := StrZero( Month( dLastDay ), 2 ) + StrZero( Year( dLastDay ), 4 )

        // Forma o cabeçalho do lançamento
        aadd(aCab, {"DDATALANC", dLastDay   , Nil})
        aadd(aCab, {"CLOTE"    , CTB_LOTE   , Nil})
        aadd(aCab, {"CSUBLOTE" , CTB_SUBLOTE, Nil})
        //cDoc := getNumDoc( dLastDay )
        //aadd(aCab, {"CDOC"      , cDoc, Nil})
        aadd(aCab, {"CPADRAO"   , ''  , Nil})
        aadd(aCab, {"NTOTINF"   , 0   , Nil})
        aadd(aCab, {"NTOTINFLOT", 0   , Nil})

        for nX := 1 to len( aEvents )
            
            cItem := Soma1( cItem )
            
            // Monta string com histórico do lançamento no formato FOLHA COLAB.: NOME_DO_COLABORADOR EV.: HORAS NORMAIS PER.: 062022
            cHist := aReg[10] +" EV.: " + aEvents[nX][03] +" PER.: "+ cPeriodo 
            cKey  := cPeriodo + aEvents[nX][07] + aEvents[nX][08] + PADR( aEvents[nX][2], TAMSX3('ZJ2_COD')[1], ' ' )

            aadd(aLinha, {"CT2_FILIAL", FWxFilial( "CT2" ), Nil})
            aadd(aLinha, {"CT2_LINHA" , cItem             , Nil})
            aadd(aLinha, {"CT2_MOEDLC", "01"              , Nil})
            aadd(aLinha, {"CT2_DC"    , "3"               , Nil})
            aadd(aLinha, {"CT2_DEBITO", aEvents[nX][05]   , Nil})       // Conta débito
            aadd(aLinha, {"CT2_CREDIT", aEvents[nX][06]   , Nil})       // Conta crédito
            aAdd(aLinha, {"CT2_CCD"   , aEvents[nX][07]   , Nil})       // Centro de custo débito
            aAdd(aLinha, {"CT2_CCC"   , aEvents[nX][08]   , Nil})       // Centro de custo crédito
            aAdd(aLinha, {"CT2_CLVLDB", cFilAnt           , Nil})       // Conceito de segmento não é utilizado, mas a entidade é obrigatória e foi criado o segmento conforme o código da filial
            aAdd(aLinha, {"CT2_CLVLCR", cFilAnt           , Nil})       // Conceito de segmento não é utilizado, mas a entidade é obrigatória e foi criado o segmento conforme o código da filial
            aadd(aLinha, {"CT2_VALOR" , aEvents[nX][04]   , Nil})
            aadd(aLinha, {"CT2_HP"    , ""                , Nil})
            aadd(aLinha, {"CT2_HIST"  , cHist             , Nil})
            aAdd(aLinha, {"CT2_X_KEY" , cKey              , Nil})

            aAdd( aItens, aClone( aLinha ) )
            aLinha := {}
        next nX

        // Valida preenchimento dos dois vetores para garantir integridade da execução
        if len( aCab ) > 0 .and. len( aItens ) > 0
            lMsErroAuto := .F.
            MsExecAuto( {|x,y,z| CTBA102(x,y,z) }, aCab, aItens, 3 )
            if lMsErroAuto != Nil
                if lMsErroAuto
                    lDone := .F.
                    MostraErro()
                endif
            endif
        else
            lDone := .F.
        endif
    else
        lDone := .F.
    endif

    if lDone
        // Força atualização dos dados do browse
        oBrwVis:Refresh(.T.)
        MsgInfo( 'Lançamentos Contábeis incluídos com sucesso!', 'S U C E S S O !' )
    endif

return lDone

/*/{Protheus.doc} validCont
Valida as informações dos eventos se estão Ok
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/26/2022
@param aReg, array, vetor contendo a linha do título posicionada e o sub-vetor de eventos relacionado
@return array, aFalhas
/*/
static function validCont( aReg )
    
    local aFalhas := {} as array
    local aEvents := aReg[11]       // Eventos do título
    local nX := 0 as numeric

    if len( aEvents ) > 0 
        for nX := 1 to len( aEvents )
            // Valida preenchimento da conta débito
            if Empty( aEvents[nX][ 05 ] )
                aAdd( aFalhas, aReg[10] + ": Evento "+ aEvents[nX][03] +" não tem relação com uma conta DÉBITO" )
            endif
            // Valida preenchimento da conta crédito
            if Empty( aEvents[nX][06] )
                aAdd( aFalhas, aReg[10] + ": Evento "+ aEvents[nX][03] +" não tem relação com uma conta CRÉDITO" )
            endif
        next nX
    else
        aAdd( aFalhas, "Eventos da folha ligados ao título não foram localizados" )
    endif

return aFalhas

/*/{Protheus.doc} newSE2Num
Função para retornar o próximo número disponível com prefixo e tipo configurados na rotina para geração dos títulos da folha
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@param cPrefixo, character, Prefixo 
@param cTipo, character, Tipo de título
@return character, cNewNum
/*/
static function newSE2Num( cPrefixo, cTipo )
    
    local cNewNum := StrZero( 0, TAMSX3('E2_NUM')[1] )
    local cQuery  := "" as character

    // Encontra o último número utilizado
    cQuery := "SELECT COALESCE( MAX( E2_NUM ), '"+ cNewNum +"' ) ULTIMO FROM "+ RetSqlname( "SE2" ) +" E2 "
    cQuery += "WHERE E2_FILIAL = '"+ FWxFilial( 'SE2' ) +"' "
    cQuery += "  AND E2_PREFIXO = '"+ cPrefixo +"' "
    cQuery += "  AND E2_TIPO    = '"+ cTipo +"' "
    cQuery += "  AND D_E_L_E_T_ = ' ' "
    
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'NUMTMP', .F., .T. )
    cNewNum := Soma1( NUMTMP->ULTIMO )
    NUMTMP->( DBCloseArea() )

return cNewNum

/*/{Protheus.doc} getForn
Função que busca o fornecedor por meio do CPF e retorna código e loja num vetor
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@param cCPF, character, String com CPF do colaborador (Obrigatório)
@param cTipoReg, character, tipo do registro que está sendo processado (obrigatório)
@return array, aRet
/*/
static function getForn( cCPF, cTipoReg )
    
    local aArea  := getArea()
    local aRet   := {}
    
    Default cCPF := ""

    if Trim( cTipoReg ) == 'FOLHA'
        if ! Empty( cCPF )
            DbSelectArea( 'SA2' )
            SA2->( DBSetOrder( 3 ) )        // A2_FILIAL + A2_CGC
            if SA2->( DBSeek( FWxFilial( 'SA2' ) + PADR( cCPF, TAMSX3('A2_CGC')[1], ' ' ) ) )
                aRet := { SA2->A2_COD, SA2->A2_LOJA, SA2->A2_NATUREZ }
            endif
        endif
    elseif Trim( cTipoReg ) == 'FGTS'
        DBSelectArea( 'SA2' )
        SA2->( DBSetOrder( 1 ) )        // A2_FILIAL + A2_COD
        if SA2->( DBSeek( FWxFilial( 'SA2' ) + cMVFORFG ) )
            aRet := { SA2->A2_COD, SA2->A2_LOJA, SA2->A2_NATUREZ }
        endif
    elseif Trim( cTipoReg ) == 'IRRF'
        DBSelectArea( 'SA2' )
        SA2->( DBSetOrder( 1 ) )        // A2_FILIAL + A2_COD
        if SA2->( DBSeek( FWxFilial( 'SA2' ) + cMVFORIR ) )
            aRet := { SA2->A2_COD, SA2->A2_LOJA, SA2->A2_NATUREZ }
        endif
    endif
    restArea( aArea )
return aRet


/*/{Protheus.doc} revFile
Função que revisa o arquivo e verifica se algum título já foi incluido no sistema 
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@param aFilePar, array, vetor contendo as linhas de títulos a serem inseridas
@param nLine, numeric, número da linha que deseja reavaliar (opcional, se não for enviado, todas as linhas serão reavaliadas)
@return array, aFileRev
/*/
static function revFile( aFilePar, nLine )

    local aFileRev   := {} as array
    local nX         := 0  as numeric
    local aTit       := {} as array
    Local aFalhas := {} as array
    local cFalhas := "" as character
    local aValCont  := {} as array

    default aFilePar := {}
    default nLine    := 0
    
    // Inicializa o aFileRev com o conteúdo recebido via parâmetro
    aFileRev := aFilePar
    
    if len( aFileRev ) > 0
        
        if nLine > 0
            ProcRegua(1)
            IncProc( 'Avaliando título '+ aFileRev[nLine][7] +'...' )
            aTit := getTit( aFileRev[ nLine ] )
            if len( aTit ) > 0
                aFileRev[nLine][6] := aTit[1]
                aFileRev[nLine][7] := aTit[2]
                aFileRev[nLine][8] := aTit[3]
                aFileRev[nLine][9] := aTit[4]
            else
                // Esvazia conteúdo dos campos do número do título
                aFileRev[nLine][6] := CriaVar( 'E2_PREFIXO', .F. )
                aFileRev[nLine][7] := CriaVar( 'E2_NUM'    , .F. )
                aFileRev[nLine][8] := CriaVar( 'E2_PARCELA', .F. )
            endif
            // Atualiza informações contábeis
            aFileRev[nLine][11] := revEvents( aFileRev[nLine] /* aLine */ )
            
            // Valida informações contábeis apenas quando o título ainda não foi incluído
            if Empty( aFileRev[nLine][8] )
                // Valida informações contábeis
                aValCont := validCont( aFileRev[nLine] )
                if len( aValCont ) > 0
                    aEval( aValCont, {|x| aAdd( aFalhas, x ) } )
                endif
            endif
        else
            ProcRegua( len( aFileRev ) )
            for nX := 1 to len( aFileRev )
                IncProc( 'Buscando titulo '+ cValToChar( nX ) +'/'+ cValToChar( len( aFileRev ) ) )
                
                // Busca se já existe título gerado no CP para a linha do arquivo
                aTit := getTit( aFileRev[nX] )
                if len( aTit ) > 0
                    aFileRev[nX][6] := aTit[1]
                    aFileRev[nX][7] := aTit[2]
                    aFileRev[nX][8] := aTit[3]
                    aFileRev[nX][9] := aTit[4]
                else
                    // Esvazia conteúdo dos campos do número do título
                    aFileRev[nX][6] := CriaVar( 'E2_PREFIXO', .F. )
                    aFileRev[nX][7] := CriaVar( 'E2_NUM'    , .F. )
                    aFileRev[nX][8] := CriaVar( 'E2_PARCELA', .F. )
                endif
                // Atualiza informações contábeis
                aFileRev[nX][11] := revEvents( aFileRev[nX] /* aLine */ )

                // Valida informações contábeis apenas quando o título ainda não foi incluído
                if Empty( aFileRev[nX][8] )
                    // Valida informações contábeis
                    aValCont := validCont( aFileRev[nX] )
                    if len( aValCont ) > 0
                        aEval( aValCont, {|x| aAdd( aFalhas, x ) } )
                    endif
                endif
            next nX
        endif

        if len( aFalhas ) > 0
            cFalhas := "Ausência de informações contábeis: " + chr(13)+chr(10)
            for nX := 1 to len( aFalhas )
                cFalhas += aFalhas[nX] + chr(13)+chr(10)
                cFalhas += Replicate( ' -', 20 ) + chr(13) + chr(10)
            next nX
            MsgAlert( cFalhas, 'A T E N Ç Ã O !' )
        endif

    endif

return aFileRev

/*/{Protheus.doc} revEvents
Função para rever os lançamentos contábeis de acordo com as tabelas de de/para
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/22/2022
@param cType, character, tipo do título em que o sistema está posicionado
@param aEvents, array, vetor contendo os eventos ligados ao título
@return array, aEventsRet
/*/
static function revEvents( aLine )
    
    local aArea := getArea()
    local aRet  := aClone( aLine[11] )
    local nX    := 0 as numeric
    local nRec  := 0 as numeric

    if len( aRet ) > 0
        
        // Abre e seta o índice 1 para a tabela de funções x Centro de Custo
        DBSelectArea( "ZJ1" )
        ZJ1->( DBSetOrder( 1 ) )        // ZJ1_FILIAL + ZJ1_COD
        
        // Abre e seta o índice 1 para a tabela de Eventos x Conta Contábil
        DBSelectArea( "ZJ2" )
        ZJ2->( DBSetOrder( 1 ) )        // ZJ2_FILIAL + ZJ2_COD

        DBSelectArea( "CT2" )

        for nX := 1 to len( aRet )

            // Captura o registro da tabela CT2 quando o mesmo já tiver sido gerado
            nRec := getRecCT2( aLine, aRet[nX] )
            if nRec == 0
                // Tenta posicionar na ZJ1 para identificar o centro de custos ligado à função do colaborador
                if ZJ1->( DBSeek( FWxFilial( "ZJ1" ) + PADR( aLine[12], TAMSX3('ZJ1_COD')[1], ' ' ) ) )
                    // Se o centro de custo de débito e/ou crédito estiverem diferente do conteúdo do vetor, atualiza as informações
                    // de acordo com as configurações atuais
                    if ! ZJ1->ZJ1_CCC == aRet[nX][08] .or. ! ZJ1->ZJ1_CCD == aRet[nX][07]
                        aRet[nX][08] := ZJ1->ZJ1_CCC
                        aRet[nX][07] := ZJ1->ZJ1_CCD
                    endif
                endif

                // Tenta posicionar na ZJ2 para identificar as contas contábeis ligadas a cada evento da folha do colaborador
                if ZJ2->( DBSeek( FWxFilial( "ZJ2" ) + PADR( aRet[nX][02], TAMSX3('ZJ2_COD')[1], ' ' ) ) )
                    // Se as contas contábeis relacionadas ao evento forem diferentes do conteúdo atual do vetor,
                    // atualiza as informações de acordo com os dados encontrados
                    if ! ZJ2->ZJ2_CC == aRet[nX][06] .or. ! ZJ2->ZJ2_CD == aRet[nX][05]
                        aRet[nX][06] := ZJ2->ZJ2_CC
                        aRet[nX][05] := ZJ2->ZJ2_CD
                    endif
                endif
            else
                // Guarda no vetor o registro único da tabela CT2
                aRet[nX][10] := nRec

                // Posiciona e recupera informação da CT2
                CT2->( DBGoTo( nRec ) )
                aRet[nX][08] := CT2->CT2_CCC
                aRet[nX][07] := CT2->CT2_CCD
                aRet[nX][06] := CT2->CT2_CREDIT
                aRet[nX][05] := CT2->CT2_DEBITO
            endif

        next nX

    endif
    
    restArea( aArea )
return aRet

/*/{Protheus.doc} getRecCT2
Função para retornar o ID do registro na tabela CT2 referente aos eventos já lançados
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/27/2022
@param aReg, array, vetor com o registro completo
@param aEvent, array, evento em que está sendo analisado
@return numeric, nRecCT2
/*/
static function getRecCT2( aReg, aEvent )

    local aArea := getArea()
    local nRec := 0 as numeric
    local dLastDay := aReg[04] - Day(aReg[04])
    local cPeriodo := StrZero( Month( dLastDay ), 2 ) + StrZero( Year( dLastDay ), 4 )
    local cEvent   := PADR( aEvent[02], TAMSX3('ZJ2_COD')[1], ' ' )

    DBSelectArea( "CT2" )
    CT2->( DBOrderNickName( "CT2FOLHA" ) )      // CT2_FILIAL + CT2_X_KEY
    if CT2->( DBSeek( FWxFilial( "CT2" ) + cPeriodo + aEvent[7] + aEvent[8] + cEvent ) )
        nRec := CT2->( Recno() )
    endif

    restArea( aArea )
return nRec

/*/{Protheus.doc} getTit
Pesquisa pelo título no contas a pagar
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@param aLine, array, vetor com a linha lida do arquivo
@return array, aTitulo
/*/
static function getTit( aLine )
    
    local aArea  := getArea()
    local aTit   := {} as array
    local cQuery := "" as character
    local cTipo  := "" as character

    // Pesquisa pelo tipo de acordo com o tipo do registro
    if Trim(aLine[10]) == 'FOLHA'
        cTipo := TIT_TIPO
    elseif Trim(aLine[10]) == 'FGTS'
        cTipo := TIT_FGTS
    elseif Trim( aLine[10] ) == 'IRRF'
        cTipo := TIT_IRRF
    endif
    
    // Query para identificação do título a pagar caso o mesmo já tenha sido incluido anteriormente
    cQuery := "SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO FROM "+ RetSqlName( "SE2" ) +" E2 "
    
    cQuery += "INNER JOIN "+ RetSqlname( 'SA2' ) +" A2 "
    cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' "
    cQuery += "AND A2.A2_COD     = E2.E2_FORNECE "
    cQuery += "AND A2.A2_LOJA    = E2.E2_LOJA "
    if cTipo == 'FGT'
        cQuery += "AND CONCAT( A2.A2_COD, A2.A2_LOJA ) = '"+ cMVFORFG +"' "
    elseif cTipo == 'IRF'
        cQuery += "AND CONCAT( A2.A2_COD, A2.A2_LOJA ) = '"+ cMVFORIR +"' "
    elseif cTipo == 'FOL'
        cQuery += "AND A2.A2_CGC     = '"+ PADR( aLine[ 01 ], TAMSX3('A2_CGC')[1], ' ' ) +"' "
    endif
    cQuery += "AND A2.D_E_L_E_T_ = ' ' "

    cQuery += "WHERE E2.E2_FILIAL  = '"+ FWxFilial( 'SE2' ) +"' "
    cQuery += "  AND E2.E2_TIPO    = '"+ cTipo +"' "                                // Apenas títulos do tipo FOL
    cQuery += "  AND E2.E2_VENCTO  = '"+ DtoS( aLine[ 4 ] ) +"' "
    cQuery += "  AND E2.E2_VALOR   = "+ cValToChar( aLine[ 5 ] ) +" "
    cQuery += "  AND E2.D_E_L_E_T_ = ' ' "

    DBUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), 'TITTMP', .F. /* lShared */, .T. /* lReadOnly */ )
    if ! TITTMP->( EOF() )
        aTit := { TITTMP->E2_PREFIXO,;
                TITTMP->E2_NUM,;
                TITTMP->E2_PARCELA,;
                TITTMP->E2_TIPO }
    endif
    TITTMP->( DBCloseArea() )

    restArea( aArea )
return aTit

/*/{Protheus.doc} getDataFile
FUnção para realizar a leitura do arquivo texto e atribuir os valores a um vetor
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@param cFileName, character, path completo do arquivo capturado via smartclient
@return array, aFile
/*/
static function getDataFile( cFileName )

    local cLine     := "" as character
    local aLine     := {} as array
    local aReg      := {} as array
    local oFile           as object
    local nTamanho  := 0  as numeric
    local nLido     := 0  as numeric
    local nRegua    := 0  as numeric
    local nAPagar   := 0  as numeric
    local nPercent  := 0  as numeric
    local aEvent    := {} as array
    local cContaDeb := "" as character
    local cContaCrd := "" as character
    local cCCCrd    := "" as character
    local cCCDeb    := "" as character
    local aTitEve   := {} as array
    local nLineQtd  := 0 as numeric

    // Realiza a abertura do arquivo pelo smartclient e realiza a leitura das linhas
    aFile := {}
    oFile := FWFileReader():New( cFileName )
    if oFile:Open()
        nTamanho := oFile:getFileSize()
        ProcRegua( nTamanho )
        while oFile:hasLine()
            cLine := oFile:GetLine()
            nLineQtd++
            nLido := oFile:getBytesRead()
            While nRegua < nLido
                nRegua++
                nPercent := Round((nRegua/nTamanho)*100,0)
                IncProc( 'Lendo dados do arquivo '+ cValToChar( nPercent ) +'%' )
            enddo
            // Desconsidera o cabeçalho do arquivo
            if nLineQtd > 1
                aLine := StrTokArr2( cLine, ';', .T.)
                if AllTrim( aLine[ nColCGC ] ) == AllTrim( SM0->M0_CGC )
                    
                    // Verifica se está posicionado nas linhas dos eventos
                    if !Empty( aLine[ nColEvCr ] ) .or. !Empty( aLine[ nColEvDb ] )
                        
                        DBSelectArea( 'ZJ1' )
                        ZJ1->( DBSetOrder( 1 ) )        // ZJ1_FILIAL + ZJ1_COD
                        if ZJ1->( DBSeek( FWxFilial( "ZJ1" ) + PADR( aLine[ nColCdFun ], TAMSX3('ZJ1_COD')[1], ' ' ) ) )
                            cCCCrd := ZJ1->ZJ1_CCC
                            cCCDeb := ZJ1->ZJ1_CCD
                        else
                            RecLock( "ZJ1", .T. )
                            ZJ1->ZJ1_FILIAL := FWxFilial( 'ZJ1' )
                            ZJ1->ZJ1_COD    := PADR( aLine[ nColCdFun ], TAMSX3('ZJ1_COD')[1], ' ' )
                            ZJ1->ZJ1_DESC   := PADR( aLine[ nColFuncao ], TAMSX3('ZJ1_DESC')[1], ' ' )
                            ZJ1->ZJ1_CCD    := CriaVar( 'ZJ1_CCD', .T. /* lIniPad */ )
                            ZJ1->ZJ1_CCC    := CriaVar( 'ZJ1_CCC', .T. /* lIniPad */ )
                            ZJ1->( MsUnlock() )
                            cCCCrd := ZJ1->ZJ1_CCC
                            cCCDeb := ZJ1->ZJ1_CCD
                        endif

                        // Abre tabela de conta contábil por evento
                        DBSelectArea( 'ZJ2' )
                        ZJ2->( DBSetOrder( 1 ) )        // ZJ2_FILIAL + ZJ2_COD

                        if !Empty( aLine[ nColEvCr ] )
                            
                            // Verifica se consegue localizar o cadastro do evento x conta-contabil
                            if ZJ2->( DBSeek( FWxFilial( "ZJ2" ) + PADR( aLine[ nColEvCr ], TAMSX3('ZJ2_COD')[1], ' ' ) ) )
                                cContaDeb := ZJ2->ZJ2_CD
                                cContaCrd := ZJ2->ZJ2_CC
                            else
                                RecLock( "ZJ2", .T. )
                                ZJ2->ZJ2_FILIAL := FWxFilial( "ZJ2" )
                                ZJ2->ZJ2_COD    := PADR( aLine[ nColEvCr ], TAMSX3('ZJ2_COD')[1], ' ' )
                                ZJ2->ZJ2_DESC   := PADR( aLine[ nColEvCrd ], TAMSX3('ZJ2_DESC')[1], ' ' )
                                ZJ2->ZJ2_CC     := CriaVar( 'ZJ2_CC', .T. /* lIniPad */ )
                                ZJ2->ZJ2_CD     := CriaVar( 'ZJ2_CD', .T. /* lIniPad */ )
                                ZJ2->( MsUnlock() )
                                cContaDeb := ZJ2->ZJ2_CD
                                cContaCrd := ZJ2->ZJ2_CD
                            endif

                            aAdd( aEvent, { StrTran(StrTran( aLine[ nColCPF ],'.',''),'-'),;                // 01 - CPF do colaborador
                                            aLine[ nColEvCr ],;                                            // 02 - Código do evento de crédito
                                            aLine[ nColEvCrd ],;                                           // 03 - Descrição do evento de crédito
                                            Val(StrTran(StrTran(aLine[ nColVlCrd ],'.',''),',','.')),;     // 04 - Valor do evento
                                            cContaDeb,;                                                     // 05 - Conta contábil de débito
                                            cContaCrd,;                                                     // 06 - Conta contábil de crédito
                                            cCCDeb,;                                                        // 07 - Centro de Custo de débito
                                            cCCCrd,;                                                        // 08 - Centro de custo de crédito
                                            "P",;                                                           // 09 - P=Pagamento ou D=Desconto
                                            0 } )                                                           // 10 - Recno da tabela CT2
                        endif

                        if !Empty( aLine[ nColEvDb ] )
                            // Verifica se consegue localizar o cadastro do evento x conta-contabil
                            if ZJ2->( DBSeek( FWxFilial( "ZJ2" ) + PADR( aLine[ nColEvDb ], TAMSX3('ZJ2_COD')[1], ' ' ) ) )
                                cContaDeb := ZJ2->ZJ2_CD
                                cContaCrd := ZJ2->ZJ2_CC
                            else
                                RecLock( "ZJ2", .T. )
                                ZJ2->ZJ2_FILIAL := FWxFilial( "ZJ2" )
                                ZJ2->ZJ2_COD    := PADR( aLine[ nColEvDb ], TAMSX3('ZJ2_COD')[1], ' ' )
                                ZJ2->ZJ2_DESC   := PADR( aLine[ nColEvDbD ], TAMSX3('ZJ2_DESC')[1], ' ' )
                                ZJ2->ZJ2_CC     := CriaVar( 'ZJ2_CC', .T. /* lIniPad */ )
                                ZJ2->ZJ2_CD     := CriaVar( 'ZJ2_CD', .T. /* lIniPad */ )
                                ZJ2->( MsUnlock() )
                                cContaDeb := ZJ2->ZJ2_CD
                                cContaCrd := ZJ2->ZJ2_CD
                            endif
                            aAdd( aEvent, { StrTran(StrTran( aLine[ nColCPF ],'.',''),'-'),;                // 01 - CPF do colaborador
                                            aLine[ nColEvDb ],;                                            // 02 - Código do evento de débito
                                            aLine[ nColEvDbD ],;                                           // 03 - Descrição do evento de débito
                                            Val(StrTran(StrTran(aLine[ nColVlDeb ],'.',''),',','.')),;     // 04 - Valor do evento de débito
                                            cContaDeb,;                                                     // 05 - Conta contábil de débito
                                            cContaCrd,;                                                     // 06 - Conta contábil de crédito
                                            cCCDeb,;                                                        // 07 - Centro de Custo de débito
                                            cCCCrd,;                                                        // 08 - Centro de custo de crédito
                                            "D",;                                                           // 09 - P=Pagamento ou D=Desconto
                                            0  } )                                                          // 10 - Recno da tabela CT2
                        endif

                    endif

                    if len( aLine ) >= nColIndTT .and. AllTrim( aLine[ nColIndTT ] ) == '4'      // Busca pela linha do total líquido a ser pago
                        // Executa apenas quando o valor a pagar é maior do que zero
                        // Isso foi feito para ignorar as folhas de pagamento referente as demissões ocorridas durante o mês
                        nAPagar := Val(StrTran(StrTran(aLine[ nColVlLiq ],'.',''),',','.'))
                        if nAPagar > 0
                            aTitEve := getTitEve( aEvent, 'FOLHA', StrTran(StrTran( aLine[ nColCPF ],'.',''),'-') )
                            aReg := { StrTran(StrTran( aLine[ nColCPF ],'.',''),'-'),;              // 01 - CPF do colaborador
                                    aLine[ nColNome   ],;                                           // 02 - Nome do colaborador
                                    aLine[ nColFuncao ],;                                           // 03 - Descrição da função do colaborador
                                    DataValida( CtoD( DIA_PAGTO + SubStr( aLine[ nColPagto  ], 03 ) ), .T. ),;  // 04 - Data prevista para pagamento
                                    Val(StrTran(StrTran(aLine[ nColVlLiq ],'.',''),',','.')),;     // 05 - Valor a pagar
                                    Space( TAMSX3( 'E2_PREFIXO' )[1] ),;                            // 06 - Prefixo do título gerado
                                    Space( TAMSX3( 'E2_NUM'     )[1] ),;                            // 07 - Número do título gerado
                                    Space( TAMSX3( 'E2_PARCELA' )[1] ),;                            // 08 - Parcela do título gerado
                                    Space( TAMSX3( 'E2_TIPO'    )[1] ),;                            // 09 - Tipo do título gerado
                                    'FOLHA',;                                                       // 10 - Classificação interna do registro
                                    aClone( aTitEve ),;                                             // 11 - Vetor de eventos da folha
                                    aLine[ nColCdFun ] }                                           // 12 - Código da função do colaborador
                            aAdd( aFile, aClone( aReg ) )
                        endif
                    elseif len( aLine ) >= nColIndTT .and. AllTrim( aLine[ nColIndTT ] ) == '5'    // Busca pela linha do total para capturar o valor do FGTS
                        // Vericica se o campo do valor do FGTS é maior do que zero
                        if Val(StrTran(StrTran(aLine[ nColVlFGT ],'.',''),',','.')) > 0 .and. nAPagar > 0
                            
                            cContaCrd := getCtaFGTS()[1]        // Conta Credito
                            cContaDeb := getCtaFGTS()[2]        // Conta Débito
                            aTitEve := {{ StrTran(StrTran( aLine[ nColCPF ],'.',''),'-'),;                  // 01 - CPF do colaborador
                                            'FGTS',;                                                        // 02 - Código do evento
                                            'FGTS',;                                                        // 03 - Descrição do evento
                                            Val(StrTran(StrTran(aLine[ nColVlFGT ],'.',''),',','.')),;     // 04 - Valor do evento
                                            cContaDeb,;                                                     // 05 - Conta contabil de débito
                                            cContaCrd,;                                                     // 06 - Conta contábil de crédito
                                            cCCDeb,;                                                        // 07 - Centro de custo de débito
                                            cCCCrd,;                                                        // 08 - Centro de custo de crédito
                                            "P",;                                                           // 09 - P=Pagamento ou D=Desconto
                                            0 }}                                                            // 10 - Recno da tabela CT2

                            aReg := { StrTran(StrTran( aLine[ nColCPF ],'.',''),'-'),;              // 01 - CPF do colaborador
                                    aLine[ nColNome   ],;                                           // 02 - Nome do colaborador
                                    aLine[ nColFuncao ],;                                           // 03 - Descrição da função do colaborador
                                    DataValida( CtoD( DIA_FGTS + SubStr( aLine[ nColPagto  ], 03 ) ), .F. ),;   // 04 - Data prevista para pagamento
                                    Val(StrTran(StrTran(aLine[ nColVlFGT ],'.',''),',','.')),;     // 05 - Valor a pagar
                                    Space( TAMSX3( 'E2_PREFIXO' )[1] ),;                            // 06 - Prefixo do título gerado no CP
                                    Space( TAMSX3( 'E2_NUM'     )[1] ),;                            // 07 - Número do título gerado no CP
                                    Space( TAMSX3( 'E2_PARCELA' )[1] ),;                            // 08 - Parcela do título gerado no CP
                                    Space( TAMSX3( 'E2_TIPO'    )[1] ),;                            // 09 - Tipo do título gerado no CP
                                    'FGTS',;                                                        // 10 - Classificação interna do registro
                                    aClone( aTitEve ),;                                             // 11 - Vetor de eventos da folha
                                    aLine[ nColCdFun ] }                                           // 12 - Código da função do colaborador
                            aAdd( aFile, aClone( aReg ) )
                        endif 
                    elseif len( aLine ) >= nColEvDb .and. AllTrim( aLine[ nColEvDb ] ) $ '999/856' // Busca pela posição do lançamento do IR
                        // Valida se o campo do valor do IR é maior do que zero
                        if Val(StrTran(StrTran(aLine[ nColVlDeb ],'.',''),',','.')) > 0 
                            aTitEve := getTitEve( aEvent, 'IRRF', StrTran(StrTran( aLine[ nColCPF ],'.',''),'-') )
                            aReg := { StrTran(StrTran( aLine[ nColCPF ],'.',''),'-'),;              // 01 - CPF do colaborador
                                    aLine[ nColNome   ],;                                           // 02 - Nome do colaborador
                                    aLine[ nColFuncao ],;                                           // 03 - Descrição da função do colaborador
                                    DataValida( CtoD( DIA_IR + SubStr( aLine[ nColPagto  ], 03 ) ), .F. ),; // 04 - Data prevista para pagamento
                                    Val(StrTran(StrTran(aLine[ nColVlDeb ],'.',''),',','.')),;     // 05 - Valor a pagar
                                    Space( TAMSX3( 'E2_PREFIXO' )[1] ),;                            // 06 - Prefixo do título gerado no CP
                                    Space( TAMSX3( 'E2_NUM'     )[1] ),;                            // 07 - Número do título gerado no CP
                                    Space( TAMSX3( 'E2_PARCELA' )[1] ),;                            // 08 - Parcela do título gerado no CP
                                    Space( TAMSX3( 'E2_TIPO'    )[1] ),;                            // 09 - Tipo do título gerado no CP
                                    'IRRF',;                                                        // 10 - Classificação interna do registro
                                    aClone( aTitEve ),;                                             // 11 - Vetor de eventos da folha
                                    aLine[ nColCdFun ] }                                           // 12 - Código da função do colaborador
                            aAdd( aFile, aClone( aReg ) )
                        endif    
                    endif
                else
                    Hlp( 'ID EMPRESA', 'O CGC da empresa pagadora ('+ aLine[ nColCGC ] +') difere do CGC da empresa na qual você está logado(a) no sistema',;
                    'Verifique se está importando o arquivo correto' )
                    Exit
                endif
            endif
            aLine := {}
        enddo
        oFile:Close()
    else
        Hlp( 'Falha na abertura do arquivo','Não foi possível abrir o arquivo '+ AllTrim( cFileName ),;
             'Verifique se o arquivo está em uso ou as permissões de leitura do sistema operacional.' )
        return Nil
    endif

return aFile

/*/{Protheus.doc} getCtaFGTS
Função para retornar código da conta contábil de débito e crédito para lançamento contábil dos valores de FGTS
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/22/2022
@return array, aContas
/*/
static function getCtaFGTS()
    
    local aArea   := getArea()
    local aContas := {} as array
    
    DBSelectArea( "ZJ2" )
    ZJ2->( DBSetOrder( 1 ) )    // ZJ2_FILIAL + ZJ2_COD
    if ZJ2->( DBSeek( FWxFilial( "ZJ2" ) + PADR( 'FGTS',TAMSX3('ZJ2_COD')[1], ' ' ) ) )
        aContas := { ZJ2->ZJ2_CD, ZJ2->ZJ2_CC }
    else
        RecLock( "ZJ2", .T. )
        ZJ2->ZJ2_FILIAL := FWxFilial( "ZJ2" )
        ZJ2->ZJ2_COD    := PADR( 'FGTS',TAMSX3('ZJ2_COD')[1], ' ' )
        ZJ2->ZJ2_DESC   := "FGTS"
        ZJ2->ZJ2_CC     := CriaVar( 'ZJ2_CC', .T. /* lIniPad */ )
        ZJ2->ZJ2_CD     := CriaVar( 'ZJ2_CD', .T. /* lIniPad */ )
        ZJ2->( MsUnlock() )
        aContas := { ZJ2->ZJ2_CC, ZJ2->ZJ2_CD }
    endif

    restArea( aArea )
return aContas

/*/{Protheus.doc} getTitEve
Função para identificar os eventos contábeis que deverão ser feitos para cada um dos tipos de títulos gerados
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/22/2022
@param aEvents, array, vetor com todos os eventos lidos até então
@param cTipo, character, tipo do título lido no momento da chamada da função
@param cCPF, character, string com o CPF do colaborador
@return array, aTitEve
/*/
static function getTitEve( aEvents, cTipo, cCPF )
    
    local aTitEve := {} as array

    if cTipo == "FOLHA"     // Agrupa os eventos ligados ao pagamento da folha
        aEval( aEvents, {|x| iif( x[1] == cCPF .and. ! AllTrim( x[2] ) $ '999/856', aAdd( aTitEve, aClone(x) ), Nil ) } )
    elseif cTipo == "IRRF"  // Agrupa os eventos ligados ao pagamento do IRRF
        aEval( aEvents, {|x| iif( x[1] == cCPF .and. AllTrim( x[2] ) $ '999/856', aAdd( aTitEve, aClone(x) ), Nil ) } )
    endif

return aTitEve

/*/{Protheus.doc} Hlp
Função para facilitar apresentação de help sem necessidade de informar tantos parâmetros
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/4/2022
@param cTitulo, character, Titulo da mensagem (obrigatório)
@param cFalha, character, Descrição da falha (opcional)
@param cHelp, character, Texto de ajuda para o usuário saber o que fazer (Opcional)
/*/
static function Hlp( cTitulo, cFalha, cHelp )
    default cFalha := ""
    default cHelp  := ""
return Help( Nil, Nil, cTitulo, Nil, cFalha, 1, 1, .F. /* lPop */, Nil /* hWnd */, Nil, Nil,;
         .F. /* lGravaLog */, { cHelp } )

/*/{Protheus.doc} getButtons
Função para retornar os botões a serem adicionados ao menu Outras Açoes da EnchoiceBar
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@return array, aButtons
/*/
static function getButtons()

    local aButtons := {}
    aAdd( aButtons, {"BMPEXCLUIR", {|| DeleteAll()   }, 'Excluir Titulos (Todos) - F8'} )
    aAdd( aButtons, {"BMPEXCLUIR", {|| DeleteOne()   }, 'Excluir Titulo (Linha Posicionada) - F7' } )
    aAdd( aButtons, {"BMPEXCLUIR", {|| DeleteLine()  }, 'Excluir Linha - F6' } )
    aAdd( aButtons, {"BMPEDIT"   , {|| U_CCxFun()    }, 'Centro de Custo x Função - F5'} )
    aAdd( aButtons, {"BMPEDIT"   , {|| U_CTAxEvent() }, 'Conta Contábil x Evento - F4'} )
    aAdd( aButtons, {"BMPVISUAL" , {|| EventsVis()   }, 'Visualiza Eventos Individuais - F9'} )
    aAdd( aButtons, {"BMPCONTAB" , {|| EventsVis(.T. /* lAll */)   }, 'Visualiza Eventos Aglutinados - F10'} )
    aAdd( aButtons, {"LEGEND"    , {|| MainLegend()  }, 'Legenda' } )

return aButtons

/*/{Protheus.doc} MainLegend
Função para exibição da legenda na tela principal
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/26/2022
/*/
static function MainLegend()
    local aLegendas := {{"BR_VERDE", "Título não incluído no Módulo de Contas a Pagar"},;
                        {"BR_VERMELHO","Título já incluído no Módulo de Contas a Pagar"}}
return BrwLegenda( 'Legendas', 'Legenda dos Títulos', aLegendas )

/*/{Protheus.doc} EventsVis
Função para visualizar os eventos vinculados ao registro posicionado no browse principal 
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@param lAll, logical, Indica se deve exibir todos os eventos aglutinados (.T.) ou exibir eventos individuais para cada título (.F.)
@since 7/25/2022
/*/
static function EventsVis( lAll )
    
    local aArea    := getArea()
    local oDlgVis         as object
    local cCabec   := ""  as character
    local bValid   :={|| .T. }
    local lConfirm := .F. as logical
    local bConfirm :={|| lConfirm := .T., oDlgVis:End()}
    local bCancel  :={|| oDlgVis:End() }
    local aButtons := { {"LEGEND"   , {|| EventLeg() }  , 'Legendas'},;
                        {"BMPCONTAB", {|| LancCont( aFile[oBrowse:nAt], aData ) }, 'Executa Lançamentos Contábeis'},;
                        {"BMPCANCEL", {|| DelCtb( aFile[oBrowse:nAt], aData ) }, 'Exclui Lançamentos Contábeis'}}
    local bInit    :={|| EnchoiceBar( oDlgVis, bConfirm, bCancel,,aButtons )}
    local aColumns := {}
    local aHeader  := {} as array
    local aAglut   := {} as array
    local aLine    := {} as array
    local nX       := 0 as numeric
    local nY       := 0 as numeric
    
    Private aData    := {} as array
    Private oBrwVis as object

    default lAll := .F.             // Por padrão, exibe eventos indivuduais

    // Define o título do Dialog
    if lAll
        cCabec := " x Centro de Custo"
        if len( aFile ) > 0
            for nX := 1 to len( aFile )
                aLine := aClone( aFile[nX][11] )
                for nY := 1 to len( aLine )
                    if len( aAglut ) == 0 .or. aScan( aAglut, {|x| x[2] == aLine[nY][2] .and. x[6] == aLine[nY][6] .and. x[7] == aLine[nY][7] } ) == 0
                        aAdd( aAglut, aClone( aLine[nY] ) )
                    else
                        aAglut[aScan( aAglut, {|x| x[2] == aLine[nY][2] .and. x[6] == aLine[nY][6] .and. x[7] == aLine[nY][7] } )][4] += aLine[nY][4]
                    endif
                next nY
            next nX
        endif
        aData := aClone( aAglut )
    else
        aData  := aFile[ oBrowse:nAt ][11]
        cCabec := ' ref. '+ aFile[ oBrowse:nAt ][10] + ' do colaborador ' + aFile[ oBrowse:nAt ][ 02 ]
    endif
    
    // Ordena os registros para que o pagamento seja exibido antes dos descontos
    aSort( aData,,,{|x,y| StrTran(StrTran(x[09],'D','1'),'P','0') + x[02] < StrTran(StrTran(y[09],'D','1'),'P','0') + y[02] } )

    aAdd( aHeader, "LEGEND" )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[ len( aColumns ) ]:SetTitle( "Cod.Evento" )
    aColumns[ len( aColumns ) ]:SetData( {|| aData[ oBrwVis:nAt ][2] } )
    aColumns[ len( aColumns ) ]:SetSize( TAMSX3( 'ZJ2_COD' )[1] )
    aAdd( aHeader, "ZJ2_COD" )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[ len( aColumns ) ]:SetTitle( "Desc.Evento" )
    aColumns[ len( aColumns ) ]:SetData( {|| aData[ oBrwVis:nAt ][3] } )
    aColumns[ len( aColumns ) ]:SetSize( TAMSX3('ZJ2_DESC')[1] )
    aAdd( aHeader, "ZJ2_DESC" )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[ len( aColumns ) ]:SetTitle( "Valor" )
    aColumns[ len( aColumns ) ]:SetData( {|| aData[ oBrwVis:nAt ][4] } )
    aColumns[ len( aColumns ) ]:SetSize( 11 )
    aColumns[ len( aColumns ) ]:SetDecimal( 2 )
    aColumns[ len( aColumns ) ]:SetPicture( "@E 999,999.99" )
    aColumns[ len( aColumns ) ]:SetAlign( 2 )       // Alinhado à direita
    aAdd( aHeader, "VALOR" )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[ len( aColumns ) ]:SetTitle( "Ct.Debito" )
    aColumns[ len( aColumns ) ]:SetData( {|| aData[ oBrwVis:nAt ][5] } )
    aColumns[ len( aColumns ) ]:SetSize( TAMSX3('ZJ2_CD')[1] )
    aColumns[ len( aColumns ) ]:SetF3( "CT1" )
    aAdd( aHeader, "ZJ2_CD" )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[ len( aColumns ) ]:SetTitle( "Ct.Credito" )
    aColumns[ len( aColumns ) ]:SetData( {|| aData[ oBrwVis:nAt ][6] } )
    aColumns[ len( aColumns ) ]:SetSize( TAMSX3('ZJ2_CC')[1] )
    aColumns[ len( aColumns ) ]:SetF3( "CT1" )
    aAdd( aHeader, "ZJ2_CC" )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[ len( aColumns ) ]:SetTitle( "C. Custo Deb." )
    aColumns[ len( aColumns ) ]:SetData( {|| aData[ oBrwVis:nAt ][7] } )
    aColumns[ len( aColumns ) ]:SetSize( TAMSX3('ZJ1_CCD')[1] )
    aColumns[ len( aColumns ) ]:SetF3( "CTT" )
    aAdd( aHeader, "ZJ1_CCD" )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[ len( aColumns ) ]:SetTitle( "C. Custo Crd." )
    aColumns[ len( aColumns ) ]:SetData( {|| aData[ oBrwVis:nAt ][8] } )
    aColumns[ len( aColumns ) ]:SetSize( TAMSX3('ZJ1_CCC')[1] )
    aColumns[ len( aColumns ) ]:SetF3( "CTT" )
    aAdd( aHeader, "ZJ1_CCC" )

    if lAll
        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[ len( aColumns ) ]:SetTitle( "Reg. CT2" )
        aColumns[ len( aColumns ) ]:SetData( {|| getRecCT2( aFile[oBrowse:nAt], aData[ oBrwVis:nAt ] ) } )
        aColumns[ len( aColumns ) ]:SetSize( 11 )
        aColumns[ len( aColumns ) ]:SetDecimal( 0 )
        aColumns[ len( aColumns ) ]:SetPicture( "@E 999,999,999" )
        aColumns[ len( aColumns ) ]:SetAlign( 2 )       // Alinhado à direita
        aAdd( aHeader, "RECCT2" )
    endif

    // Monta caixa de diálogo para visualizar os eventos
    oDlgVis := TDialog():New( 0, 0, 500, 900,'Eventos Contábeis '+ cCabec ,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    
    // Implementa browse para visualizar os dados
    oBrwVis := FWBrowse():New( oDlgVis )
    oBrwVis:SetDataArray()
    oBrwVis:SetArray( aData )
    oBrwVis:DisableConfig()
    oBrwVis:DisableFilter()
    oBrwVis:DisableReport()
    oBrwVis:DisableSeek()
    oBrwVis:DisableLocate()
    oBrwVis:SetEditCell( .T. )      // Torna o Browse Editável
    oBrwVis:AddLegend( "aData[oBrwVis:nAt][09]=='P'" , "GREEN", 'Pagamentos' )
    oBrwVis:AddLegend( "aData[oBrwvis:nAt][09]=='D'" , "RED", "Descontos" )
    aEval( aColumns, {|x| oBrwVis:SetColumns( { x } ) } )
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ2_CD" } ) ]:lEdit := .T.
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ2_CD" } ) ]:cReadVar := 'aData[oBrwVis:nAt]['+ cValToChar( aScan( aHeader, {|x| AllTrim( x ) == "ZJ2_CD" } ) ) +']'
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ2_CC" } ) ]:lEdit := .T.
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ2_CC" } ) ]:cReadVar := 'aData[oBrwVis:nAt]['+ cValToChar( aScan( aHeader, {|x| AllTrim( x ) == "ZJ2_CC" } ) ) +']'
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ1_CCD" } ) ]:lEdit := .T.
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ1_CCD" } ) ]:cReadVar := 'aData[oBrwVis:nAt]['+ cValToChar( aScan( aHeader, {|x| AllTrim( x ) == "ZJ1_CCD" } ) ) +']'
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ1_CCC" } ) ]:lEdit := .T.
    oBrwVis:aColumns[ aScan( aHeader, {|x| AllTrim( x ) == "ZJ1_CCC" } ) ]:cReadVar := 'aData[oBrwVis:nAt]['+ cValToChar( aScan( aHeader, {|x| AllTrim( x ) == "ZJ1_CCC" } ) ) +']'
    oBrwVis:Activate()

    oDlgVis:Activate(,,,.T., bValid,, bInit )

    // Se o usuário confirmou a operação, salva as informações definidas manualmente
    if lConfirm .and. !lAll
        aFile[ oBrowse:nAt ][11] := aClone( aData )
    endif

    restArea( aArea )
return nil

/*/{Protheus.doc} EventLeg
Função para exibição de diálogo das legendas da tela de eventos
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/26/2022
/*/
static function EventLeg()
    local aLegendas := {{"BR_VERDE", "Pagamentos"},;
                        {"BR_VERMELHO","Descontos"}}
return BrwLegenda( 'Eventos', 'Legenda de Eventos', aLegendas )

/*/{Protheus.doc} CCxFun
Função para editar o relacionamento entre Contas Contábeis x Evento
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/23/2022
/*/
user function CCxFun()

    local aArea   := getArea()
    local oBrwAux as object
    local cAlias  := "ZJ1"
    local cFunOld := FunName()

    Private cCadastro := "Centro de Custos x Função"
    Private INCLUI    := .F.
    Private ALTERA    := .F.
    Private aRotina   := {}

    // Seta o nome da nova função
    SetFunName( "CCxFun" )

    // Adiciona botões no browse por meio do vetor aRotina
    aAdd( aRotina, { '&Visualizar', "AxVisual", 0, 2 } )
    aAdd( aRotina, { '&Incluir', "AxInclui", 0, 3 } )
    aAdd( aRotina, { '&Alterar', "AxAltera", 0, 4 } )
    aAdd( aRotina, { '&Excluir', "AxDeleta", 0, 5 } )

    // Define o browse para importação dos dados
    oBrwAux := FWMBrowse():New()
    oBrwAux:SetAlias( cAlias )
    oBrwAux:SetDescription( cCadastro )
    oBrwAux:Activate()

    // Devolve o nome anterior da função
    SetFunName( cFunOld )

    // Quando a chamada for feita diretamente pela tela de importação da folha, reprocessa os registros existentes para verificar se 
    // houveram alterações nas amarrações
    if isInCallStack( "U_BFFINA09" )
        Processa({|| aFile := revFile( aFile ) }, 'Aguarde!','Revalidando dados lidos...')
        setHotKey()
    endif

    restArea( aArea )
return Nil

/*/{Protheus.doc} CTAxEvent
Função para editar o relacionamento entre Contas Contábeis x Evento
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/23/2022
/*/
user function CTAxEvent()

    local aArea   := getArea()
    local oBrwAux as object
    local cAlias  := "ZJ2"
    local cFunOld := FunName()

    Private aRotina := {} as array
    Private cCadastro := "Contas Contábeis x Evento"
    Private INCLUI    := .F.
    Private ALTERA    := .F.

    // Seta o nome da nova função
    SetFunName( "CTAxEvent" )

    // Adiciona botões no browse por meio do vetor aRotina
    aAdd( aRotina, { '&Visualizar', "AxVisual", 0, 2 } )
    aAdd( aRotina, { '&Incluir', "AxInclui", 0, 3 } )
    aAdd( aRotina, { '&Alterar', "AxAltera", 0, 4 } )
    aAdd( aRotina, { '&Excluir', "AxDeleta", 0, 5 } )

    // Define o browse para importação dos dados
    oBrwAux := FWMBrowse():New()
    oBrwAux:SetAlias( cAlias )
    oBrwAux:SetDescription( cCadastro )
    oBrwAux:Activate()

    // Devolve o nome anterior da função
    SetFunName( cFunOld )

    // Quando a chamada for feita diretamente pela tela de importação da folha, reprocessa os registros existentes para verificar se 
    // houveram alterações nas amarrações
    if isInCallStack( "U_BFFINA09" )
        Processa({|| aFile := revFile( aFile ) }, 'Aguarde!','Revalidando dados lidos...')
        setHotKey()
    endif

    restArea( aArea )
return Nil

/*/{Protheus.doc} DeleteLine
Função para deletar linha importada do arquivo, bem como os lançamentos contábeis ligados à ela
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/23/2022
@return logical, lDone
/*/
static function DeleteLine()
    
    local lDone := .T. as logical

    // Valida se o título já não foi gerado antes de permitir a exclusão da linha
    if Empty( aFile[oBrowse:nAt][7] )
        if MsgYesNo( 'Está certo(a) de que deseja eliminar esse lançamento? '+ chr(13)+chr(10) +;
                    chr(13)+chr(10)+;
                    '<b>Importante</b>: a linha eliminada apenas será apagada apenas da tela atual, não influenciando em absolutamente nada '+;
                    'na integridade do arquivo. Se houver uma nova tentativa de abertura do arquivo, essa informação será lida e carregada novamente '+;
                    'para esta tela.', 'Eliminar Linha?' )
            aFile := aDel( aFile, oBrowse:nAt )
            aSize( aFile, len( aFile )-1 )
            oBrowse:Refresh(.T.)
        else
            lDone := .F.
        endif
    else
        lDone := .F.
        Hlp( 'Título já gerado', 'O título apagar referente à linha atual já foi incluído',;
            'Não é permitido realizar a exclusão de uma linha de movimento cujo título já tenha sido gerado. '+;
            'Faça a exclusão do título primeiro e depois tente novamente. ' )
    endif

return lDone

/*/{Protheus.doc} DeleteAll
Função para deletar títulos já incluidos no sistema
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
/*/
static function DeleteAll()

    local aArea   := getArea()
    local lDone   := .T. as logical
    local nLine   := 0 as numeric

    aEval( aFile, {|x| nLine++,; 
                    iif( lDone, Processa({|| lDone := DeleteOne( nLine ) },;
                                'Excluindo...',;
                                'Eliminando título '+ cValToChar( nLine ) + '/'+ cValToChar( len( aFile ) ) ), Nil ) } )

    restArea( aArea )
return lDone

/*/{Protheus.doc} DeleteOne
Função para fazer a exclusão do título referente a linha importada do arquivo da folha
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/6/2022
@param nLine, numeric, número da linha (opcional, se não informado, o sistema vai usar a linha posicionada no browse)
@return logical, lDone
/*/
static function DeleteOne( nLine )
    
    local aArea   := getArea()
    local lDone   := .T. as logical
    local aTitulo := {} as array
    
    private lMsErroAuto := .F. as logical

    default nLine := oBrowse:nAt 

    // Quando chamada for automática, posiciona na linha que vier via parâmetro
    if nLine > 0
        oBrowse:GoTo( nLine )
    endif

    Begin Transaction
        if lDone
            DBSelectArea( 'SE2' )
            SE2->( DBSetOrder( 1 ) )            // E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO
            if SE2->( DBSeek( FWxFilial( "SE2" ) +; 
                            PADR(aFile[oBrowse:nAt][6],TAMSX3('E2_PREFIXO')[1],' ') +;
                            PADR(aFile[oBrowse:nAt][7],TAMSX3('E2_NUM'    )[1],' ') +; 
                            PADR(aFile[oBrowse:nAt][8],TAMSX3('E2_PARCELA')[1],' ') +; 
                            PADR(aFile[oBrowse:nAt][9],TAMSX3('E2_TIPO'   )[1],' ') ) )
                
                aAdd( aTitulo, { "E2_FILIAL" , SE2->E2_FILIAL  , Nil } )
                aAdd( aTitulo, { "E2_PREFIXO", SE2->E2_PREFIXO , Nil } )
                aAdd( aTitulo, { "E2_NUM"    , SE2->E2_NUM     , Nil } )
                aAdd( aTitulo, { "E2_PARCELA", SE2->E2_PARCELA , Nil } )
                aAdd( aTitulo, { "E2_TIPO"   , SE2->E2_TIPO    , Nil } )
                aAdd( aTitulo, { "E2_FORNECE", SE2->E2_FORNECE , Nil } )
                aAdd( aTitulo, { "E2_LOJA"   , SE2->E2_LOJA    , Nil } )

                lMsErroAuto := .F.
                MsExecAuto( {|x,y,z| FINA050( x,y,z ) }, aTitulo,,5 )

                if lMsErroAuto
                    lDone := .F.
                    MostraErro()
                    DisarmTransaction()
                else
                    // Chama função que 
                    Processa({|| aFile := revFile( aFile, nLine ) }, 'Aguarde!','Verificando se o título foi excluído...')
                    oBrowse:Refresh(.T.)
                endif

            endif
        endif
    End Transaction

    restArea( aArea )
return lDone

/*/{Protheus.doc} delCtb
Função para deletar as informações referente ao processo de contabilização da folha
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/27/2022
@param aReg, array, registro completo da linha lido do arquivo
@param aEvent, array, eventos da folha
@return logical, lDone
/*/
static function delCtb( aReg, aEvent )
    
    local aArea   := getArea()
    local lDone   := .T. as logical
    local aCab    := {}  as array
    local aItens  := {}  as array
    local aLinha  := {}  as array
    local nRecCT2 := 0   as numeric
    local nX      := 0   as numeric
    
    Private lMsErroAuto := .F. as logical

    DBSelectArea( "CT2" )
    if len( aEvent ) > 0

        for nX := 1 to len( aEvent )
            
            // Posiciona no registro de contabilização
            nRecCT2 := getRecCT2( aReg, aEvent[nX] )
            if nRecCT2 > 0
                CT2->( DBGoTo( nRecCT2 ) )

                // Verifica se o cabeçalho já foi preenchido e se existe registro de contabilização
                if len( aCab ) == 0 
                    aadd(aCab, {"DDATALANC", CT2->CT2_DATA  , Nil})
                    aadd(aCab, {"CLOTE"    , CT2->CT2_LOTE  , Nil})
                    aadd(aCab, {"CSUBLOTE" , CT2->CT2_SBLOTE, Nil})
                    aadd(aCab, {"CDOC"     , CT2->CT2_DOC   , Nil})
                endif

                aadd(aLinha, {"CT2_FILIAL", CT2->CT2_FILIAL, Nil})
                aadd(aLinha, {"CT2_LINHA" , CT2->CT2_LINHA , Nil})
                aadd(aLinha, {"CT2_MOEDLC", CT2->CT2_MOEDLC, Nil})
                aadd(aLinha, {"CT2_DC"    , CT2->CT2_DC    , Nil})
                aAdd(aItens, aClone( aLinha ) )
                aLinha := {}
            endif
            
            if len( aCab ) > 0 .and. len( aItens ) > 0
                lMsErroAuto := .F.
                MsExecAuto( {|x,y,z| CTBA102(x,y,z) }, aCab, aItens, 5 )        // Exclusão 
                if lMsErroAuto != Nil
                    if lMsErroAuto
                        lDone := .F.
                        MostraErro()
                    endif
                endif
            endif

        next nX

    endif

    if lDone
        // Força refresh no browse
        oBrwVis:Refresh(.T.)
        MsgInfo( 'Exclusão finalizada com sucesso!', 'S E C E S S O !' )
    endif

    restArea( aArea )
return lDone

/*/{Protheus.doc} setDataPos
Seta posição de cada coluna conforme leitura do cabeçalho do arquivo
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/3/2022
@param cFile, character, path completo do arquivo escolhido pelo usuário
/*/
static function setDataPos( cFile )
    
    local oFile := FWFileReader():New( cFile )
    local aCab := {} as array

    if oFile:Open()     // Verifica se conseguiu abrir o arquivo
        if oFile:hasLine()  // Verifica se é uma linha válida
            aCab := StrTokArr2( oFile:GetLine(), ';', .T. /* lEmptyCol */ )     // Captura as informações da primeira linha do arquivo como cabeçalho
        endif
        oFile:Close()
    endif

    nColCGC    := aScan( aCab, {|x| AllTrim( x ) == 'cgce_emp' } )
    nColPagto  := aScan( aCab, {|x| AllTrim( x ) == 'cp_data_hora' } )
    nColNome   := aScan( aCab, {|x| AllTrim( x ) == 'cp_nome_epr' } )
    nColCPF    := aScan( aCab, {|x| AllTrim( x ) == 'cp_cpf' } )
    nColCdFun  := aScan( aCab, {|x| AllTrim( x ) == 'cp_codi_car' } )
    nColFuncao := aScan( aCab, {|x| AllTrim( x ) == 'cp_nome_car' } )
    nColEvCr   := aScan( aCab, {|x| AllTrim( x ) == 'cp_codi_eve_p' } )
    nColEvCrd  := aScan( aCab, {|x| AllTrim( x ) == 'cp_nome_eve_p' } )
    nColVlCrd  := aScan( aCab, {|x| AllTrim( x ) == 'cp_eve_val_p' } )
    nColEvDb   := aScan( aCab, {|x| AllTrim( x ) == 'cp_codi_eve_d' } )
    nColEvDbD  := aScan( aCab, {|x| AllTrim( x ) == 'cp_nome_eve_d' } )
    nColVlDeb  := aScan( aCab, {|x| AllTrim( x ) == 'cp_eve_val_d' } )
    nColIndTT  := aScan( aCab, {|x| AllTrim( x ) == 'cp_tipo_linha' } )
    nColVlLiq  := aScan( aCab, {|x| AllTrim( x ) == 'cp_tot_liq' } )
    nColVlFGT  := aScan( aCab, {|x| AllTrim( x ) == 'cp_val_fgts' } )
return Nil
