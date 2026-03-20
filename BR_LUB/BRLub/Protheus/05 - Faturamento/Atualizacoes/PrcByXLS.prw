#include 'topconn.ch'
#include 'totvs.ch'

/*/{Protheus.doc} prcByXls
Função para realizar importação de arquivo de alteração de preços via excel utilizando planilha base
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/09/2021
/*/
user function prcByXls()
                        
    Local oFind            as object
    Local oGetXLS          as object
    Local cGetXLS   := Space(200) // Get do path + arquivo + extensão
    Local oGrpDes          as object
    Local oLabel1          as object
    Local oLabel2          as object
    local oDlgImp          as object
    local aButtons  := {}  as array
    local aRet      := {}  as array
    local aResult   := {}  as array
    local cResult   := ""  as character
    local cError    := ""  as character
    local oGetTok          as object
    local oLblTok          as object
    local aCombo    := {}  as array
    local cCombo    := ""  as character
    local aHdrDP    := {}  as array
    local aAlter    := {"RELATION" }
    local nX        := 0   as numeric
    local cEOL      := chr( 13 ) + chr( 10 )
 
    private aDePara := {}  as array
    private cGetTok := ";" as character
    private oDePara        as object

    aCombo := {"PRD=Cod.Produto",;
               "DES=Descrição Produto",;
               "CUS=Custo do Produto"}

    // Adiciona os códigos das tabelas de preço ao combo para que o usuário possa utilizá-las no relacionamento
    DBSelectArea( "DA0" )
    DA0->( DBSetOrder( 1 ) )
    if DA0->( DBSeek( FwxFilial( 'DA0' ) ) )
        while ! DA0->( EOF() ) .and. DA0->DA0_FILIAL == FWxFilial( 'DA0' )
            if DA0->DA0_ATIVO == '1' .and. DA0->DA0_DATDE <= dDataBase .and. ( DA0->DA0_DATATE >= dDataBase .or. DA0->DA0_DATATE == StoD(Space(8)) )
                aAdd( aCombo, AllTrim( DA0->DA0_CODTAB ) +'='+ Capital(AllTrim(DA0->DA0_DESCRI)) )
            endif
            DA0->( DBSkip() )
        enddo  
    endif

    // Define a string do combo para exibir no campo do grid
    aEval( aCombo, {|x| cCombo += iif(!Empty(cCombo),";","") + x } )

    // Define a estrutura dos campos do grid
    aAdd( aHdrDP, {"Coluna Arquivo","COLUNA","@x",20,0,,,"C",,"V",, } )
    aAdd( aHdrDP, {"Relacionar com...","RELATION","@x",03,0,,,"C",,"V",cCombo, } )

    // Exibe a tela para usuário selecionar arquivo e fazer as configurações
    DEFINE MSDIALOG oDlgImp TITLE "Ajuste de Custos e Preços via Excel" FROM 000, 000  TO 600, 500 COLORS 0, 16777215 PIXEL

    @ 031, 002 GROUP oGrpDes TO 064, 249 OF oDlgImp COLOR 0, 16777215 PIXEL
    @ 039, 006 SAY oLabel1 PROMPT "Essa rotina tem por objetivo permitir que sejam realizadas alterações em custos" SIZE 228, 007 OF oDlgImp COLORS 0, 16777215 PIXEL
    @ 049, 006 SAY oLabel2 PROMPT "e preços de venda, com base em uma planilha de excel estruturada" SIZE 228, 007 OF oDlgImp COLORS 0, 16777215 PIXEL

    @ 073, 002 MSGET oGetXLS VAR cGetXLS SIZE 212, 012 OF oDlgImp COLORS 0, 16777215 WHEN .F. PIXEL
    
    @ 087, 002 SAY oLblTok PROMPT "Separador" SIZE 030, 007 OF oDlgImp COLORS 0, 16777215 PIXEL
    @ 096, 002 MSGET oGetTok VAR cGetTok SIZE 012, 012 OF oDlgImp COLORS 0, 16777215 WHEN .T. ON CHANGE iif( file(cGetXLS), loadHeader( cGetXLS ), nil ) PIXEL

    // Get dados com os dados do grid
    oDePara := MsNewGetDados():New( 096, 018, 298, 248, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "", aAlter,, len(aDePara), "AllwaysTrue", "", "AllwaysTrue", oDlgImp, aHdrDP, aDePara )

    @ 073, 216 BUTTON oFind PROMPT "..." SIZE 034, 013 OF oDlgImp ACTION Processa( {||cGetXLS := getFile() }, 'Aguarde!','Identificando excel para importar...' ) PIXEL

    ACTIVATE MSDIALOG oDlgImp CENTERED ON INIT (EnchoiceBar(oDlgImp,{|| Processa({|| aRet := btnOk( AllTrim( cGetXLS) ) }, 'Executando...','Importando '+ AllTrim(cGetXLS) +'...' ), oDlgImp:End() },{||oDlgImp:End()},,@aButtons)) 

    if len( aRet ) > 0

        cResult := ""
        cError  := ""
        aResult := aRet[4]      // Totais de registros processados

        if aRet[1]      // Arquivo processado com sucesso
            if len( aResult ) > 0   
                for nX := 1 to len( aResult )
                    if aResult[nX][1] == 'ERR'
                        cError += iif( !Empty(cError), cEOL, '') +AllTrim( aResult[nX][2] )
                    elseif aResult[nX][1] == "CUS"      // Alteração de custo
                        if aResult[nX][3] > 0
                            cResult += cEOL + AllTrim(Transform(aResult[nX][3],'@E 999,999')) +' custos alterados'
                        endif
                    else
                        cResult += iif( !Empty(cResult), cEOL, '' )+ "<b>"+ Capital( AllTrim( retField( "DA0", 1, FWxFilial('DA0') + aResult[nX][1], 'DA0_DESCRI' ) ) ) +"</b>"
                        if aResult[nX][2] > 0
                            cResult += cEOL + AllTrim(Transform(aResult[nX][2],'@E 999,999')) +' preços incluídos'
                        endif
                        if aResult[nX][3] > 0
                            cResult += cEOL + AllTrim(Transform(aResult[nX][3],'@E 999,999')) +' preços alterados'
                        endif
                    endif

                next nX
                if !Empty( cResult ) .and. !Empty( cError )
                    cResult += cEOL
                    cResult += '<b>Falhas Durante Processamento:</b>'
                    cResult += cEOL
                elseif !Empty( cError )
                    cResult += '<b>Falhas Durante Processamento:</b>'
                    cResult += cEOL
                endif
                cResult += cError
            endif
            
            MsgInfo( cResult, 'S U C E S S O !' )
        else
            Help( Nil,Nil,'F A L H A !',Nil,aRet[2],1,0,,,,,,{ aRet[3] } )
        endif
    endif
return ( nil )

/*/{Protheus.doc} getFile
Função para tratar a busca do arquivo no computador do usuário
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/09/2021
@return character, cPatchFile
/*/
static function getFile()
    local cNewFile := "" as character

    aDePara := {}
    cNewFile := cGetFile( "Arquivo Excel (csv) |*.csv", 'Buscando arquivo...', 0,,.F., GETF_LOCALHARD, .F. )
    if ! file( cNewFile )
        cNewFile := Space(200)
    else
        loadHeader( cNewFile )
    endif 
return ( cNewFile )

/*/{Protheus.doc} loadHeader
Função para carregar cabeçalho do arquivo a ser importado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2021
@param cFile, character, patch do arquivo a ser lido
/*/
static function loadHeader( cFile )
    
    local oFile       as object
    local cLine := "" as character
    local nX    := 1  as numeric
    local aTmp  := {} as array
    
    aDePara := {}
    oFile := FWFileReader():New( cFile )
    if oFile:Open()
        
        // Valida se existe conteúdo dentro do arquivo
        if oFile:HasLine()
            // lê a primeira linha
            cLine := oFile:GetLine()
        endif
        oFile:Close()

        // Monta o cabeçalho
        aTmp := StrTokArr2( StrTran( cLine, '"', ''), cGetTok, .T. )
        if len( aTmp ) > 0
            for nX := 1 to len( aTmp )
                aAdd( aDePara, { aTmp[nX], '   ', .F. } )
            next nX
        endif

        // Atualiza o grid com os dados da primeira linha do arquivo
        if oDePara != nil
            oDePara:aCols := aDePara
            oDePara:ForceRefresh()
        endif

    endif

return 

/*/{Protheus.doc} btnOk
Função utilizada quando pressionado botão Ok
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/09/2021
@param cFile, character, path do arquivo
@return array, aResult
/*/
static function btnOk( cFile )
    
    local oFile           as object
    local aResult  := {}  as array
    local lSuccess := .T. as logical
    local cMsgFail := ""  as character
    local cInstruc := ""  as character
    local aTotais  := {}  as array
    local aFile    := {}  as array
    local cLine    := ""  as character
    local nLine    := 0   as numeric
    local aLine    := {}  as array
    local nX       := 0   as numeric
    local nY       := 0   as numeric
    local cItem    := ""  as character

    default cFile := ""

    aTotais := {}

    if file( cFile )
        oFile := FWFileReader():New( cFile )
        if oFile:Open()
            nLine := 0
            aFile := {}
            // Enquanto houver linha no arquivo, continua lendo
            while oFile:HasLine()

                cLine := oFile:GetLine()
                aLine := adjustLine( StrTokArr2( cLine, cGetTok, .T. ) )
                
                // Se retornou conteúdo, adiciona na variável que vai receber o processamento posteriormente
                if len( aLine ) > 0
                    aAdd( aFile, aClone( aLine ) )
                    aLine := {}
                endif  

            enddo
            oFile:Close()

            if len( aFile ) > 0
                
                DBSelectArea( 'SB1' )
                SB1->( DBSetOrder( 1 ) )

                for nX := 1 to len( aFile )
                    
                    // Posiciona na tabela de cadastro de produtos
                    if SB1->( DBSeek( FWxFilial( 'SB1' ) + PADR(AllTrim(aFile[nX][1]),TAMSX3('B1_COD')[1],' ') ) )
                        
                        if len( aFile[nX] ) > 1
                            
                            for nY := 2 to len( aFile[nX] )

                                // Verifica se tem alteração de custo do produto
                                if aFile[nX][nY][1] == "CUS"
                                    
                                    DBSelectArea( "SB1" )
                                    SB1->( DBSetOrder( 1 ) )        
                                    if SB1->( DBSeek( FWxFilial( "SB1" ) + PADR(AllTrim(aFile[nX][1]),TAMSX3('B1_COD')[1],' ') ) ) .and. aFile[nX][nY][2] > 0
                                        RecLock( "SB1", .F. )
                                        SB1->B1_CUSTD := aFile[nX][nY][2]
                                        SB1->( MsUnlock() )
                                        doCount( @aTotais, aFile[nX][nY][1], .F. /* lInc */ )
                                    endif
                                 
                                else

                                    DBSelectArea( 'DA0' )
                                    DA0->( DBSetOrder( 1 ) )    //DA0_FILIAL + DA0_CODTAB
                                    
                                    // Procura pelo cadastro da tabela de preço, se encontrou, segue com o processo de adequação do preço
                                    if DA0->( DBSeek( FWxFilial( 'DA0' ) + aFile[nX][nY][1] ) ) .and. aFile[nX][nY][2] > 0
                                        
                                        DBSelectArea( 'DA1' )
                                        DA1->( DBSetOrder( 1 ) )    // DA1_FILIAL + DA1_CODTAB + DA1_CODPRO
                                        if DA1->( DBSeek( FWxFilial( 'DA1' ) + aFile[nX][nY][1] + PADR(AllTrim(aFile[nX][1]),TAMSX3('B1_COD')[1],' ') ) )
                                            RecLock( 'DA1', .F. )
                                            DA1->DA1_PRCANT := DA1->DA1_PRCVEN
                                            DA1->DA1_PRCVEN := aFile[nX][nY][2]
                                            DA1->DA1_DTALT  := dDatabase
                                            // Ajusta campos do ICmais para que o sistema ententa a instrução de alteração de preço
                                            if DA1->( FieldPos( 'DA1_X_DULT' ) ) > 0 .and. DA1->( FieldPos( 'DA1_X_HULT' ) ) > 0
                                                DA1->DA1_X_DULT := date()
                                                DA1->DA1_X_HULT := time()
                                            endif
                                            DA1->( MsUnlock() )
                                            doCount( @aTotais, aFile[nX][nY][1], .F. /* lInc */ )
                                        else
                                            cItem := Soma1( getLast( aFile[nX][nY][1] /* cTab */ ) )
                                            RecLock( 'DA1', .T. )
                                            DA1->DA1_FILIAL := FWxFilial( 'DA1' )
                                            DA1->DA1_ITEM   := cItem
                                            DA1->DA1_CODTAB := aFile[nX][nY][1]
                                            DA1->DA1_CODPRO := PADR(AllTrim(aFile[nX][1]),TAMSX3('B1_COD')[1],' ')
                                            DA1->DA1_PRCVEN := aFile[nX][nY][2]
                                            DA1->DA1_ATIVO  := '1'  // 1=Sim 2=Nao
                                            DA1->DA1_TPOPER := '4'  // 4=Todos
                                            DA1->DA1_QTDLOT := 999999.99
                                            DA1->DA1_MOEDA  := 1
                                            DA1->DA1_DATVIG := dDataBase
                                            DA1->DA1_DTALT  := dDatabase
                                            // Ajusta campos do ICmais para que o sistema ententa a instrução de alteração de preço
                                            if DA1->( FieldPos( 'DA1_X_DULT' ) ) > 0 .and. ;
                                            DA1->( FieldPos( 'DA1_X_HULT' ) ) > 0 .and. ;
                                            DA1->( FieldPos( 'DA1_X_ENIC' ) ) > 0
                                                
                                                DA1->DA1_X_DULT := date()
                                                DA1->DA1_X_HULT := time()
                                                
                                                // Sinaliza o registro pra enviar apenas quando estiver pra enviar para o ICmais também no cabeçalho
                                                if DA0->( FieldPos( 'DA0_X_ENIC' ) ) > 0 .and. DA0->DA0_X_ENIC == 'S'
                                                    DA1->DA1_X_ENIC := 'S'
                                                endif

                                            endif
                                            DA1->( MsUnlock() )
                                            doCount( @aTotais, aFile[nX][nY][1], .T. /* lInc */ )
                                        endif

                                    endif
                                
                                endif

                            next nY
                        
                        endif

                    endif

                next nX
            endif

        else
            lSuccess := .F.
            cMsgFail := "Não foi possível abrir o arquivo "+ cFile
            cInstruc := "Verifique se o arquivo pode estar sendo utilizado por outro processo"
        endif
    else
        lSuccess := .F.
        cMsgFail := "O arquivo "+ cFile + " não foi localizado"
        cInstruc := "Informe um arquivo válido para importação"
    endif

    aResult := { lSuccess, cMsgFail, cInstruc, aTotais }

return aResult

/*/{Protheus.doc} doCount
Função para manipular conteúdo da variável aTotais realizando contagem de registros processados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/09/2021
@param aTotais, array, vetor com o resultado atual dos totalizadores
@param cGroup, character, ID do grupo dos tipos de registros
@param lInc, logical, Indica se é inclusao ou alteração
@param cMessage, character, Mensagem adicional quando o grupo for ERR=Erro
/*/
static function doCount( aTotais, cGroup, lInc, cMessage  )
    default aTotais := {}

    // Verifica se encontrou o grupo dentro do vetor, se não encontrar, deve criar um novo registro
    if aScan( aTotais, {|x| x[1] == cGroup } ) == 0
        if cGroup == 'ERR'
            aAdd( aTotais, { cGroup, cMessage } )
        else
            aAdd( aTotais, { cGroup, iif(lInc,1,0), iif(!lInc,1,0) } )
        endif
    else
        if cGroup == 'ERR'
            aAdd( aTotais, { cGroup, cMessage } )
        else
            aTotais[aScan( aTotais, {|x| x[1] == cGroup } )][iif(lInc,2,3)]++
        endif
    endif
return Nil

/*/{Protheus.doc} getLast
Função para retornar o último conteúdo gravado no campo do item da tabela de preços
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/09/2021
@param cTab, character, ID da tabela de preços (obrigatório)
@return character, cItem
/*/
static function getLast( cTab )
    
    local cQuery := "" as character
    local cItem  := "0000"

    // Query para leitura da última gravação de linha de item na tabela de preço em questão
    cQuery := "SELECT COALESCE(MAX(DA1_ITEM),'"+ replicate('0',TAMSX3('DA1_ITEM')[1]) +"') DA1_ITEM FROM "+ retSqlName( 'DA1' ) +" "
    cQuery += "WHERE DA1_FILIAL = '"+ FWxFilial( 'DA1' ) +"' "
    cQuery += "  AND DA1_CODTAB = '"+ cTab +"' "
    cQuery += "  AND D_E_L_E_T_ = ' ' "
    DBUseArea(.T. /* lNew */,"TOPCONN" /* cDriver */,TcGenQry(,,cQuery) /* uQuery */,"LAST" /* cAlias */,.F. /* lShared */, .T. /* lReadOnly */)
    cItem := LAST->DA1_ITEM
    LAST->( DBCloseArea() )

return cItem

/*/{Protheus.doc} adjustLine
Função para converter o resultado obtido pela leitura da linha do arquivo em informações estruturadas prontas para 
execução dos ajustes na base de dados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2021
@param aLine, array, vetor com os campos da linha atual lida do arquivo
@return array, aNormalizedData
/*/
static function adjustLine( aLine )
    
    local aNewLine := {} as array
    local nPosID   := 0 as numeric
    local nX       := 0 as numeric

    default aLine := {}

    aDePara := aClone( oDePara:aCols )

    nPosID  := aScan( aDePara, {|x| AllTrim(x[2]) == 'PRD' } )

    if len( aLine ) > 0 .and. nPosID > 0 .and. isProd( aLine[nPosID] )
        
        aAdd( aNewLine, aLine[nPosID] )

        // percorre o de/para e identifica as tabelas de preços que foram relacionadas
        if len( aDePara ) > 0
            for nX := 1 to len( aDePara )
                if !Empty( aDePara[nX][2] ) .and. isTab( aDePara[nX][2] )
                    aAdd( aNewLine, { aDePara[nX][2], toNumber( aLine[ aScan( aDePara, {|x| AllTrim(x[2]) == AllTrim(aDePara[nX][2] ) } ) ] ) } )
                elseif aDePara[nX][2] == 'CUS'      // Ajuste de custo
                    aAdd( aNewLine, {  aDePara[nX][2], toNumber( aLine[ aScan( aDePara, {|x| AllTrim(x[2]) == AllTrim(aDePara[nX][2] ) } ) ] ) } )
                endif
            next nX
        endif
        
    endif

return aNewLine

/*/{Protheus.doc} isProd
Função para verificar se a linha tem um código de produto válido
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2021
@param cValue, character, valor obtido do arquivo texto
@return logical, lIsProduct
/*/
static function isProd( cValue )
    
    local lIsProd := .F. as logical
    local cKey    := "" as character

    default cValue := ""

    cKey := PADR(AllTrim(cValue),TAMSX3('B1_COD')[1])

    DBSelectArea( 'SB1' )
    SB1->( DBSetOrder( 1 ) )
    lIsProd := SB1->( DBSeek( FWxFilial( 'SB1' ) + cKey ) )

return lIsProd

/*/{Protheus.doc} isTab
Função que verifica se o conteúdo recebido por parâmetro é uma tabela de preço
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2021
@param cValue, character, conteudo do campo texto
@return logical, lIsTab
/*/
static function isTab( cValue )
    
    local lIsTab := .F. as logical
    default cValue := "XXX"
    
    DBSelectArea( 'DA0' )
    DA0->( DBSetOrder(1) )
    lIsTab := DA0->( DBSeek( FWxFilial( 'DA0' ) + cValue ) )

return lIsTab

/*/{Protheus.doc} toNumber
Função para converter texto em número e adequar formato
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2021
@param cValue, character, informação do campo obtida do arquivo
@return numeric, nNormalizedNumber
/*/
static function toNumber( cValue )
    
    local nNumber := 0 as numeric
    local cTemp   := "" as character
    
    default cValue := ""

    if !Empty( cValue )
        cTemp := StrTran(StrTran(StrTran(StrTran( StrTran( cValue, '"' ),'R$',''),' ',''),'.',''),',','.')
        nNumber := val( cTemp )
    endif

return nNumber
