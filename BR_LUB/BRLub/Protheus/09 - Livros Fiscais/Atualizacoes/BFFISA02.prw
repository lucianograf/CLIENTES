#include 'protheus.ch'

#define CEOL chr(13)+chr(10)        // ENTER

/*/{Protheus.doc} BFFISA02
Rotina de apuração dos registros de compra e venda de combustíveis para geração do registro 0206 da GIA-RS
@type function
@version 1.0
@author Jean Carlos P. Saggin
@since 6/14/2022
/*/
user function BFFISA02()

    local cPerg := "BFFISA02"
    local aRes  := {0,0,0} as array
    local nChoice := 0 as numeric

    // Perguntas:
    // MV_PAR01 - Data de
    // MV_PAR02 - Data até
    // MV_PAR03 - Doc de
    // MV_PAR04 - Doc Até
    // MV_PAR05 - Tipo (Entrada,Saída,Ambas)

    nChoice := Aviso( 'A T E N Ç A O ','Defina o que gostaria de fazer:' + CEOL +;
                                        '- Pressione o botão IMPORTAR para importar um arquivo .csv contendo a relação dos códigos ' + CEOL +;
                                        'da ANP e suas respectivas descrições;' + CEOL +;
                                        '- Pressione o botão REPROCESSAR para apurar as entradas e saídas para geração do registro 0206;' + CEOL +;
                                        '- Pressione o botão SAIR para cancelar.',;
                                        {'Importar','Reprocessar', 'Sair'}, 3 )
    if nChoice == 1         // Importar
        Processa( {|| fileImport() }, 'Aguarde!','Processando importação do arquivo...' )
    elseif nChoice == 2     // Reprocessar
        if Pergunte( cPerg, .T. )
            Processa( {|| aRes := runProc() }, 'Aguarde!','Reprocessando informações...' )
            if len( aRes ) > 0
                MsgInfo( 'Resultado do processamento: ' + CEOL +;
                        '- Registros incluídos: <b>'+ cValToChar( aRes[1] ) +'</b>'+ CEOL +;
                        '- Registros alterados: <b>'+ cValToChar( aRes[2] ) +'</b>'+ CEOL +;
                        '- Registros excluídos: <b>'+ cValToChar( aRes[3] ) +'</b>',;
                        'Processamento concluído!' )
            endif
        endif
    endif

return Nil

/*/{Protheus.doc} fileImport
Função para importar a relação de códigos e descrições para compor os códigos da ANP em tabela personalizada
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/11/2022
/*/
static function fileImport()
    
    local aArea     := getArea()
    local oFile           as object
    local cFileName := "" as character
    local nQuant    := 0  as numeric    // Quantidade de bytes do arquivo
    local nQtdRead  := 0  as numeric    // Quantidade de bytes já lidos do arquivo
    local nPercent  := 0  as numeric    // Quantidade do arquivo já processada em %
    local nRegua    := 0  as numeric    // Variável para controle de régua de processamento
    local cLinha    := "" as character
    local aLinha    := {} as array
    local aFile     := {} as array
    local nX        := 0 as numeric
    local nLineImp  := 0 as numeric
    local nLineIgn  := 0 as numeric

    cFileName := cGetFile( 'Arquivo de texto (*.csv) | *.csv',;
                            'Selecione o arquivo dos códigos da ANP',;
                            Nil,;
                            '',;
                            .F.,;
                            GETF_LOCALHARD,;
                            .T. )
    if Empty( cFileName )           // Valida se o usuário apertou no Ok
        return Nil
    elseif !File( cFileName )       // Valida se o arquivo é inválido
        MsgStop( 'O arquivo <b>'+ AllTrim( cFileName ) +'</b> não é válido!','A T E N Ç A O !' ) 
        return Nil
    endif
    
    // Instancia função para leitura do arquivo de texto
    oFile := FWFileReader():new( cFileName )
    if oFile:Open()
        nQuant := oFile:GetFileSize()
        ProcRegua( nQuant )
        nRegua := 0
        aFile  := {}
        while oFile:hasLine()
            cLinha := oFile:getLine()
            nQtdRead := oFile:getBytesRead()
            while nRegua < nQtdRead
                nRegua++
                nPercent := Round( ( nRegua / nQuant ) * 100, 0 )
                IncProc( 'Lendo arquivo [ '+ cValToChar( nPercent ) +'% ]' )
            enddo
            aLinha := StrTokArr2( cLinha, ';', .T. )
            aAdd( aFile, aClone( aLinha ) )
            aLinha := {}
        enddo
        oFile:Close()
    endif

    if len( aFile ) > 0

        ProcRegua( len( aFile ) )
        DBSelectArea( 'ZJ0' )
        ZJ0->( DBSetOrder( 1 ) )        // ZJ0_CODIGO + ZJ0_DESCRI
        for nX := 1 to len( aFile )
            IncProc( 'Populando tabela ZJ0 - Codigos ANP...' )
            if ! ZJ0->( DBSeek( FWxFilial( 'ZJ0' ) + PADR( AllTrim( aFile[nX][1] ), TAMSX3('ZJ0_CODIGO')[1], ' ' ) ) )
                RecLock( 'ZJ0', .T. )
                ZJ0->ZJ0_FILIAL := FWxFilial( 'ZJ0' )
                ZJ0->ZJ0_CODIGO := PADR( AllTrim( aFile[nX][1] ), TAMSX3('ZJ0_CODIGO')[1], ' ' )
                ZJ0->ZJ0_DESCRI := PADR( AllTrim( aFile[nX][2] ), TAMSX3('ZJ0_DESCRI')[1], ' ' )
                ZJ0->( MsUnlock() )
                nLineImp++
            else
                nLineIgn++
            endif
        next nX
    endif

    // Exibe o resultado do processamento dos dados lidos no arquivo
    if nLineImp > 0 .or. nLineIgn > 0
        MsgInfo( 'Resultado do processamento: '+ CEOL +;
                 '- Linhas processadas: <b>'+ cValToChar( nLineImp ) +'</b>' + CEOL +;
                 '- Linhas ignoradas: <b>'+ cValToChar( nLineIgn ) +'</b>', 'R E S U L T A D O' )
    endif

    restArea( aArea )
return nil

/*/{Protheus.doc} runProc
Função que executa a leitura dos dados e o reprocessamento dos registros para alimentar a 
tabela CD6 (Complemento de Combustíveis)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/14/2022
@return array, aResult
/*/
static function runProc()

    local aArea   := getArea()
    local aResult := {0,0,0} as array
    local cQuery  := "" as character
    local aRet    := {} as array

    // Executa reprocessamento das entradas
    if MV_PAR05 == 3 .or. MV_PAR05 == 1

        cQuery := "SELECT " + CEOL
        cQuery += "  'E'            CD6_TPMOV, " + CEOL
        cQuery += "  F1.F1_ESPECIE  CD6_ESPEC, " + CEOL
        cQuery += "  F1.F1_DOC      CD6_DOC, " + CEOL
        cQuery += "  F1.F1_SERIE    CD6_SERIE, "+ CEOL
        cQuery += "  D1.D1_ITEM     CD6_ITEM, " + CEOL
        cQuery += "  F1.F1_FORNECE  CD6_CLIFOR, " + CEOL
        cQuery += "  F1.F1_LOJA     CD6_LOJA, " + CEOL
        cQuery += "  D1.D1_COD      CD6_COD, " + CEOL
        cQuery += "  F1.F1_EST      CD6_UFCONS, " + CEOL
        cQuery += "  D1.D1_QUANT    CD6_QTAMB, " + CEOL
        cQuery += "  B1.B1_CODSIMP  CD6_CODANP, " + CEOL
        cQuery += "  ZJ0.ZJ0_DESCRI CD6_DESANP " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
        
        // Fornecedor
        cQuery += "INNER JOIN "+ RetSQLName( 'SF1' ) +" F1 " + CEOL
        cQuery += " ON F1.F1_FILIAL  = '"+ FWxFilial( 'SF1' ) +"' " + CEOL
        cQuery += "AND F1.F1_DOC     = D1.D1_DOC " + CEOL
        cQuery += "AND F1.F1_SERIE   = D1.D1_SERIE " + CEOL
        cQuery += "AND F1.F1_FORNECE = D1.D1_FORNECE " + CEOL
        cQuery += "AND F1.F1_LOJA    = D1.D1_LOJA " + CEOL
        cQuery += "AND F1.F1_TIPO    = D1.D1_TIPO " + CEOL
        cQuery += "AND F1.D_E_L_E_T_ = ' ' " + CEOL

        // Produto
        cQuery += "INNER JOIN "+ RetSQLName( 'SB1' ) +" B1 " + CEOL
        cQuery += " ON B1.B1_FILIAL  = '"+ FWxFilial( "SB1" ) +"' " + CEOL
        cQuery += "AND B1.B1_COD     = D1.D1_COD " + CEOL
        cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL

        // Classificação do produto derivado de petróleo
        cQuery += "INNER JOIN "+ RetSqlName( "ZJ0" ) +" ZJ0 " + CEOL
        cQuery += " ON ZJ0.ZJ0_FILIAL = '"+ FWxFilial( "ZJ0" ) +"' " + CEOL
        cQuery += "AND ZJ0.ZJ0_CODIGO = B1.B1_CODSIMP " + CEOL
        cQuery += "AND ZJ0.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "WHERE D1.D1_FILIAL = '"+ FwxFilial( "SD1" ) +"' " + CEOL
        cQuery += "  AND D1.D1_EMISSAO BETWEEN '"+ DtoS( MV_PAR01 ) +"' AND '"+ DtoS( MV_PAR02 ) +"' " + CEOL
        cQuery += "  AND D1.D1_DOC BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' " + CEOL
        cQuery += "  AND D1.D_E_L_E_T_ = ' ' " + CEOL
        // Apenas produtos com código da ANP preenchidos
        cQuery += "  AND B1.B1_CODSIMP <> '"+ Space( TAMSX3('B1_CODSIMP')[1] ) +"' " + CEOL
        
        // Apenas espécie SPED
        cQuery += "  AND F1.F1_ESPECIE = 'SPED' "

        DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), 'ENTR', .F. /* lShared */, .T. /* lReadOnly */ )
        Processa( { || aRet := gravaDados( 'ENTR'/* cTab */ ) }, 'Aguarde!', 'Reprocessando entradas...' )
        aResult[1] += aRet[1]
        aResult[2] += aRet[2]
        aResult[3] += aRet[3]

    endif

    // Processa as saídas
    if MV_PAR05 == 3 .or. MV_PAR05 == 2

        cQuery := "SELECT " + CEOL
        cQuery += "  'S'            CD6_TPMOV, " + CEOL
        cQuery += "  F2.F2_ESPECIE  CD6_ESPEC, " + CEOL
        cQuery += "  F2.F2_DOC      CD6_DOC, " + CEOL
        cQuery += "  F2.F2_SERIE    CD6_SERIE, "+ CEOL
        cQuery += "  D2.D2_ITEM     CD6_ITEM, " + CEOL
        cQuery += "  F2.F2_CLIENTE  CD6_CLIFOR, " + CEOL
        cQuery += "  F2.F2_LOJA     CD6_LOJA, " + CEOL
        cQuery += "  D2.D2_COD      CD6_COD, " + CEOL
        cQuery += "  F2.F2_EST      CD6_UFCONS, " + CEOL
        cQuery += "  D2.D2_QUANT    CD6_QTAMB, " + CEOL
        cQuery += "  B1.B1_CODSIMP  CD6_CODANP, " + CEOL
        cQuery += "  ZJ0.ZJ0_DESCRI CD6_DESANP " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
        
        // Cliente
        cQuery += "INNER JOIN "+ RetSQLName( 'SF2' ) +" F2 " + CEOL
        cQuery += " ON F2.F2_FILIAL  = '"+ FWxFilial( 'SF2' ) +"' " + CEOL
        cQuery += "AND F2.F2_DOC     = D2.D2_DOC " + CEOL
        cQuery += "AND F2.F2_SERIE   = D2.D2_SERIE " + CEOL
        cQuery += "AND F2.F2_CLIENTE = D2.D2_CLIENTE " + CEOL
        cQuery += "AND F2.F2_LOJA    = D2.D2_LOJA " + CEOL
        cQuery += "AND F2.F2_TIPO    = D2.D2_TIPO " + CEOL
        cQuery += "AND F2.D_E_L_E_T_ = ' ' " + CEOL

        // Produto
        cQuery += "INNER JOIN "+ RetSQLName( 'SB1' ) +" B1 " + CEOL
        cQuery += " ON B1.B1_FILIAL  = '"+ FWxFilial( "SB1" ) +"' " + CEOL
        cQuery += "AND B1.B1_COD     = D2.D2_COD " + CEOL
        cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL

        // Classificação do produto derivado de petróleo
        cQuery += "INNER JOIN "+ RetSqlName( "ZJ0" ) +" ZJ0 " + CEOL
        cQuery += " ON ZJ0.ZJ0_FILIAL = '"+ FWxFilial( "ZJ0" ) +"' " + CEOL
        cQuery += "AND ZJ0.ZJ0_CODIGO = B1.B1_CODSIMP " + CEOL
        cQuery += "AND ZJ0.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "WHERE D2.D2_FILIAL = '"+ FwxFilial( "SD1" ) +"' " + CEOL
        cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( MV_PAR01 ) +"' AND '"+ DtoS( MV_PAR02 ) +"' " + CEOL
        cQuery += "  AND D2.D2_DOC BETWEEN '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' " + CEOL
        cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL
        // Apenas produtos com código da ANP preenchidos
        cQuery += "  AND B1.B1_CODSIMP <> '"+ Space( TAMSX3('B1_CODSIMP')[1] ) +"' " + CEOL
        // Apenas tipo SPED
        cQuery += "  AND F2.F2_ESPECIE = 'SPED' "

        DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), 'SAID', .F. /* lShared */, .T. /* lReadOnly */ )
        Processa( { || aRet := gravaDados( 'SAID'/* cTab */ ) }, 'Aguarde!', 'Reprocessando saídas...' )
        aResult[1] += aRet[1]       // Incluídos
        aResult[2] += aRet[2]       // Alterados
        aResult[3] += aRet[3]       // Excluidos

    endif

    restArea( aArea )
return aResult

/*/{Protheus.doc} gravaDados
Função para gravar os dados lidos por meio da consulta na tabela lida pelo processo de geração de arquivo do SPED
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 6/14/2022
@param cTab, character, alias da tabela temporária
@return array, aReturn
/*/
static function gravaDados( cTab )
    
    local nQuant  := 0   as numeric
    local nAtual  := 0   as numeric
    local nPerc   := 0   as numeric
    local aReturn := {0,0,0}  as array
    local lSeek   := .F. as logical
    local nQtdAlt := 0 as numeric
    local nQtdInc := 0 as numeric
    local nQtdExc := 0 as numeric

    DBSelectArea( cTab )
    Count to nQuant
    ( cTab )->( DBGoTop() )

    if ! ( cTab )->( EOF() )

        DBSelectArea( 'CD6' )
        CD6->( DBSetOrder( 1 ) )        // CD6_FILIAL + CD6_TPMOV + CD6_SERIE + CD6_DOC + CD6_CLIFOR + CD6_LOJA + CD6_ITEM + CD6_COD

        While ! ( cTab )->( EOF() )
            nAtual++
            nPerc := Round( ( nAtual / nQuant ) * 100, 0 )
            IncProc( 'Gravando dados do registro 0206 '+ cValToChar( nPerc ) +'% ' )
            lSeek := CD6->( DBSeek( FWxFilial( 'CD6' ) +;
                                    ( cTab )->CD6_TPMOV +;
                                    ( cTab )->CD6_SERIE +;
                                    PADR(( cTab )->CD6_DOC, TAMSX3('CD6_DOC')[1], ' ' ) +;
                                    ( cTab )->CD6_CLIFOR +;
                                    ( cTab )->CD6_LOJA +;
                                    PADR(( cTab )->CD6_ITEM, TAMSX3('CD6_ITEM')[1], ' ' ) +;
                                    ( cTab )->CD6_COD ) )
            
            //The duplicate key value is (01, S, 1  , 000573   , 307228, 01, 01  , 24             ,        ,    , 0)
            RecLock( 'CD6', !lSeek )
            if !lSeek
                CD6->CD6_FILIAL := FWxFilial( 'CD6' )
                CD6->CD6_TPMOV  := ( cTab )->CD6_TPMOV
                CD6->CD6_SERIE  := ( cTab )->CD6_SERIE
                CD6->CD6_DOC    := PADR(( cTab )->CD6_DOC, TAMSX3('CD6_DOC')[1], ' ' )
                CD6->CD6_CLIFOR := ( cTab )->CD6_CLIFOR
                CD6->CD6_LOJA   := ( cTab )->CD6_LOJA
                CD6->CD6_ITEM   := PADR(( cTab )->CD6_ITEM, TAMSX3('CD6_ITEM')[1], ' ' )
                CD6->CD6_COD    := ( cTab )->CD6_COD
            endif
            CD6->CD6_CODANP := ( cTab )->CD6_CODANP
            CD6->CD6_QTAMB  := ( cTab )->CD6_QTAMB
            CD6->CD6_UFCONS := ( cTab )->CD6_UFCONS
            CD6->CD6_DESANP := ( cTab )->CD6_DESANP
            CD6->CD6_ESPEC  := ( cTab )->CD6_ESPEC
            CD6->( MsUnlock() )
            ( cTab )->( DBSkip() )

            if lSeek
                nQtdAlt++
            else
                nQtdInc++
            endif
        end
    endif
    ( cTab )->( DBCloseArea() )

    aReturn := { nQtdInc, nQtdAlt, nQtdExc }
return aReturn
