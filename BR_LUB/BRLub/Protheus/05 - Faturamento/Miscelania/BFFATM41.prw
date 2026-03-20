#include 'totvs.ch'
#include 'topconn.ch'

#define CEOL chr(13)+chr(10)

/*/{Protheus.doc} BFFATM41
Função responsável pela importação dos dados referente ao processo de exportação do histórico
de clientes da Onix para a BRLub
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/5/2022
/*/
user function BFFATM41()

    local aArea    := getArea()
    local cFile    := ""  as character
    local cDirSrv  := "/transitoria/"
    local lSuccess := .T. as logical
    local cDrive := "" as character
    local cPath := "" as character
    local cArq := "" as character
    local cExt := "" as character

    Private cAliHist := AllTrim(SuperGetMv( 'MV_X_ALIH',,'' ))      // Alias referente ao histórico de movimentações da Onix

    // Valida configuração do alias da tabela de histórico antes de prosseguir
    if Empty( cAliHist )
        Hlp( 'MV_X_ALIH','Tabela de histórico de clientes não definido!',;
        'É necessário definir um alias por meio do parâmetro MV_X_ALIH para '+;
        'que o sistema saiba qual é a tabela de onde deve ler os dados históricos dos clientes.' )
        return Nil
    endif
    //SplitPath( cPatharq, @cDrive, @cDir, @cArq, @cExt )
    
    // Captura path local do arquivo para importar
    cFile := AllTrim( cGetFile( 'Arquivo de Texto .CSV | *.csv ','Selecione o arquivo para importar...', 1,"",;
                        .F./* lSave */, GETF_LOCALHARD ) )
    // Se o conteúdo retornou vazio, é porque usuário pressionou o botão de cancelar
    if ! Empty( cFile )
        // Valida existência do arquivo selecionado ou digitado
        if File( cFile )
            // Chama função interna que copia os dados do remote para o server
            SplitPath( cFile, @cDrive, @cPath, @cArq, @cExt )
            lSuccess := CPYT2S( cFile, cDirSrv, .T. /* lCompact */ )
            if lSuccess
                lSuccess := runImport( Lower( cDirSrv + cArq + cExt ) )
            else
                MsgStop( "Não foi possível copiar o arquivo <b>"+ cArq + cExt +"</b> para o diretório <b>"+ cDirSrv +"</b> do servidor !","F A L H A !" )                
            endif
        else
            MsgStop( "O arquivo selecionado/informado <b>"+ cFile +"</b> não é válido!","F A L H A !" )
        endif
    endif

    restArea( aArea )
return Nil

/*/{Protheus.doc} Hlp
Função para facilitar apresentação de help sem necessidade de informar tantos parâmetros
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/4/2022
@param cTitulo, character, Titulo da mensagem (obrigatório)
@param cFalha, character, Descrição da falha (obrigatório)
@param cHelp, character, Texto de ajuda para o usuário saber o que fazer (Obrigatório)
/*/
static function Hlp( cTitulo, cFalha, cHelp )
return Help( Nil, Nil, cTitulo, Nil, cFalha, 1, 1, .F. /* lPop */, Nil /* hWnd */, Nil, Nil,;
         .F. /* lGravaLog */, { cHelp } )

/*/{Protheus.doc} runImport
Função responsável pela importação dos dados
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/5/2022
@param cPathSrv, character, path completo do arquivo no servidor
@return logical, lSuccess
/*/
static function runImport( cPathSrv )
    
    local lSuccess := .T. as logical
    local oFile    := FWFileReader():New(cPathSrv )
    local aHeader  := {} as array
    local nLnFile  := 0 as numeric
    local cLine    := "" as character
    local aLine    := {} as array
    local aFile    := {} as array

    // Valida se conseguiu abrir o arquivo para leitura
    if oFile:Open()
        while oFile:hasLine()
            cLine := oFile:getLine()
            nLnFile++
            if nLnFile == 1     // Quando ler a primeira linha do arquivo, interpreta como cabeçalho
                aHeader := StrTokArr2( cLine, ';', .T. /* lEmptyCell */ )
            else
                aLine := StrTokArr2( cLine, ';', .T. )
                aAdd( aFile, aClone( aLine ) )
                aLine := {} 
            endif
        end
        oFile:Close()

        // Verifica se o arquivo tem conteúdo e se o cabeçalho também está prenchido
        if len( aFile ) > 0 .and. len( aHeader ) > 0
            Processa( {|| lSuccess := runInsert( aFile, aHeader ) }, 'Aguarde!', 'Processando informações...' )
        endif

    else
        lSuccess := .F.
    endif

return lSuccess

/*/{Protheus.doc} runInsert
Função de inserção dos dados na tabela de histórico de clientes
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/15/2022
@param aFile, array, vetor com os dados do arquivo
@param aHeader, array, vetor com os campos do cabeçalho
@param aDePara, array, vetor com o de/para dos campos do cabeçalho do arquivo x campos da tabela
@return logical, lSuccess
/*/
static function runInsert( aFile, aHeader )
    
    local lSuccess := .T. as logical
    local nX := 0 as numeric
    local nHdr := 0 as numeric
    local nPerc := 0 as numeric

    DBSelectArea( cAliHist )
    ( cAliHist )->( DBSetOrder( 1 ) )
    if !( cAliHist )->(EOF())
        While ! ( cAliHist )->( EOF() )
            
            RecLock( cAliHist, .F. )
            ( cAliHist )->( DBDelete() )
            ( cAliHist )->( MsUnlock() )
            
            ( cAliHist )->( DBSkip() )
        enddo
    endif

    /*
    // Campos contendo informações em excel
    aFields := { "A1_NOME","A4_NREDUZ","B1_DESC","B1_QTELITS","C5_PROPRI","C5_XPEDCLI","D2_CF","D2_CLIENTE",;
                "D2_COD", "D2_DOC","D2_EMISSAO","D2_FILIAL","D2_LOJA","D2_PEDIDO","D2_PRCVEN","D2_QUANT",;
                "D2_SERIE","D2_TES","D2_TOTAL","D2_VALBRUT","D2_VALPROM","E4_DESCRI","F2_CLIENTE","F2_COND",;
                "F2_DOC","F2_DUPL","F2_EMISSAO","F2_FILIAL","F2_LOJA","F2_SERIE","F2_TRANSP","F2_VALBRUT",;
                "F4_TEXTO" } 
    */
    ProcRegua( len( aFile ) )

    DBSelectArea( cAliHist )
    ( cAliHist )->( DBSetOrder( 1 ) )

    for nX := 1 to len( aFile )
        nPerc := Round((nX/len( aFile ))*100,0)
        IncProc( 'Processando importação de dados: '+ cValToChar( nPerc ) +' %' )
        RecLock( cAliHist, .T. )
        &( cAliHist +'->'+ cAliHist +'_FILIAL' ) := deParaFil( aFile[nX][aScan(aHeader,{|x| AllTrim(x) == 'D2_FILIAL' })] )
        for nHdr := 1 to len( aHeader )
            // Verifica se conseguiu encontrar o campo do cabeçalho do arquivo no vetor de de/para
            if ( cAliHist )->( FieldPos( fn( aHeader[nHdr] ) ) ) > 0
                // Quando  estiver gravando informação do campo filial, é necessário fazer de/para
                if "FILIAL" $ aHeader[nHdr]
                    &( cAliHist +'->'+ fn( aHeader[nHdr] ) ) := deParaFil( aFile[nX][nHdr] )
                else
                    &( cAliHist +'->'+ fn( aHeader[nHdr] ) ) := changeType( aFile[nX][nHdr] /* cConteudo */, fn( aHeader[nHdr] ) /* cField */ )
                endif
            endif
        next nHdr
        ( cAliHist )->( MsUnlock() )
    next nX

return lSuccess

/*/{Protheus.doc} deParaFil
Função para fazer o de/para de filial pois a filial 02 e 04 foram criadas de forma invertida no novo ambiente
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/16/2022
@param cFilHist, character, filial que veio no movimento histórico
@return character, cNewFil
/*/
static function deParaFil( cFilHist )
    local cNewFil := "" as character
    if cFilHist == '02'     // SC
        cNewFil := '04'
    elseif cFilHist == '04' // MG
        cNewFil := "02"
    else
        cNewFil := cFilHist
    endif
return cNewFil

/*/{Protheus.doc} changeType
Converte o conteúdo capturado durante a leitura do arquivo para o formato correto do campo no sistema
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/15/2022
@param cConteudo, character, conteúdo do arquivo (obrigatório)
@param cField, character, campo da tabela de histórico do cliente (obrigatório)
@return variadic, xCont
/*/
static function changeType( cConteudo, cField )
    
    local xCont := Nil
    local cFieldType := FWSX3Util():GetFieldType( cField )
    
    if cFieldType == 'N'                // Numérico
        xCont := Val( StrTran( StrTran( cConteudo, '.', '' ), ',', '.' ) )
    elseif cFieldType == 'D'            // Data
        xCont := StoD( cConteudo )
    elseif cFieldType == 'L'            // Lógico
        xCont := (cConteudo == 'T' .or. cConteudo == '.T.')
    else
        xCont := cConteudo
    endif
return xCont

/*/{Protheus.doc} fn
Função para retornar o nome do campo de acordo com a tabela de histórico
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 8/15/2022
@param cField, character, nome do campo da tabela original (obrigatório)
@return character, cNameNewField 
/*/
static function fn( cField )
return cAliHist +"_"+ SubStr( StrTran( cField, '_', '' ), 01, 06 )
