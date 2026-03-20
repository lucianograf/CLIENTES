#include 'totvs.ch'
#include 'topconn.ch'
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

#define CLOCPDF GetTempPath(.T.)        // Diretório temporário onde o sistema vai salvar os arquivos em PDF
#define CDIRSRV "/boletos/"             // Diretório dentro da pasta protheus_data para armazenar temporariamente os boletos em pdf

/*/{Protheus.doc} BLENVMAIL
função para envio de boletos por e-mail para o cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 24/11/2022
@param aTitBOL, array, vetor com os títulos referente aos boletos que acabaram de ser impressos
/*/
user function BLENVMAIL( aTitBOL )

    local aArea    := getArea()
    local cKeyCli  := "" as character
    local nX       := 1  as numeric
    local aEnv     := {}
    local oBoletos       as object
    local cPathBOL := "" as characterZ  

    default aTitBOL := {}

    if len( aTitBOL ) > 0

        // Monta o objeto que vai ser o responsável pela geração do PDF com os boletos do cliente
        oBoletos := GenObject()

        for nX := 1 to len( aTitBOL )
            // Verifica se mudou o cliente
            if ! gt( aTitBOL[nX], 'cliente' ) + gt( aTitBOL[nX], 'loja' ) == cKeyCli
                if len( aEnv ) > 0
                    
                    oBoletos:Print()
                    // Verifica se a estrutura existe no server
                    if ! ExistDir( CDIRSRV )
                        MakeDir( CDIRSRV )
                    endif
                    
                    // Valida existência do PDF logo após a conclusão da geração do arquivo
                    if File( oBoletos:cPathPDF + StrTran(oBoletos:cFileName,'.rel','.pdf' ) )
                        // Manda copiar arquivo para diretório no servidor
                        if CpyT2S( oBoletos:cPathPDF + StrTran(oBoletos:cFileName,'.rel','.pdf' ), CDIRSRV, .F.)
                            if file( CDIRSRV + StrTran(oBoletos:cFileName,'.rel','.pdf' ) )
                                cPathBOL := CDIRSRV + StrTran(oBoletos:cFileName,'.rel','.pdf' )
                                if file( cPathBOL )
                                    U_BolSndWf( aEnv, cPathBOL )
                                endif
                            endif
                        EndIf
                    EndIf

                    FreeObj(oBoletos)
	                oBoletos := nil
                    aEnv := {}
                endif
                oBoletos := GenObject()
            endif

            // Chama rotina responsável pela emissao do boleto
            U_BOLETOS( gt( aTitBOL[nX], 'cliente' ),;
                        gt( aTitBOL[nX], 'loja' ),;
                        gt( aTitBOL[nX], 'numero' ),;
                        gt( aTitBOL[nX], 'prefixo' ),;
                        gt( aTitBOL[nX], 'banco' ),;
                        gt( aTitBOL[nX], 'agencia' ),;
                        gt( aTitBOL[nX], 'conta' ),;
                        gt( aTitBOL[nX], 'subconta' ),;
                        .T. /* lAuto */,;
                        @oBoletos,;
                        gt( aTitBOL[nX], 'parcela' ) )
            
            aAdd( aEnv, aClone( aTitBOL[nX] ) )

            // Anota a chave do último cliente 
            cKeyCli := gt( aTitBOL[nX], 'cliente' ) + gt( aTitBOL[nX], 'loja' )

        next nX

        if len( aEnv ) > 0
            
            oBoletos:Print()
            
            // Verifica se a estrutura existe no server
            if ! ExistDir( CDIRSRV )
                MakeDir( CDIRSRV )
            endif
            
            // Valida existência do PDF logo após a conclusão da geração do arquivo
            if File( oBoletos:cPathPDF + StrTran(oBoletos:cFileName,'.rel','.pdf' ) )
                // Manda copiar arquivo para diretório no servidor
                if CpyT2S( oBoletos:cPathPDF + StrTran(oBoletos:cFileName,'.rel','.pdf' ), CDIRSRV, .F.)
                    if file( CDIRSRV + StrTran(oBoletos:cFileName,'.rel','.pdf' ) )
                        cPathBOL := CDIRSRV + StrTran(oBoletos:cFileName,'.rel','.pdf' )
                        if file( cPathBOL )
                            U_BolSndWf( aEnv, cPathBOL )
                        endif
                    endif
                EndIf
            EndIf

            FreeObj(oBoletos)
            oBoletos := nil
            aEnv     := {}

        endif
    endif
    
    restArea( aArea )
return Nil

/*/{Protheus.doc} BolSndWf
Função responsável pelo consumo do workflow e disparo do email para o cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/11/2022
@param aBoletos, array, vetor contendo os boletos que estão sendo enviados
@param cPath, character, caminho do arquivo em PDF
/*/
user function BolSndWf( aBoletos, cPath )
    
    local aArea    := getArea()
    local nX       := 1  as numeric
    local oProc          as object
    local oHTML          as object
    local cAssunto := "" as character
    local cFileWF  := '/workflow/wf-boleto.html'
    local cCabHRef := "" as character
    local cCabAlt  := "" as character
    local cCabSRC  := "" as character
    local cColor   := "" as character

    if len( aBoletos ) > 0
        
        // Posiciona no cliente
        DBSelectArea( 'SA1' )
        SA1->( DBSetOrder( 1 ) )
        SA1->( DBSeek( FWxFilial( 'SA1' ) + gt(aBoletos[1],'cliente') + gt(aBoletos[1],'loja') ) )

        // Monta o assunto do email
        cAssunto := '['+ AllTrim( SM0->M0_FILIAL ) +'] Boletos emitidos para '+ AllTrim( SubStr( SA1->A1_NOME, 01, 30 ) ) +;
        ' em '+ DtoC( date() ) + ' as '+ time()  

        // Valida existência do modelo do workflow e do preenchimento do e-mail do cliente
        if file( cFileWF ) .and. !Empty( SA1->A1_EMAIL )
            
            // Parâmetro do HREF para direcionar o click do usuário sobre a logo da empresa
            if GetMv( 'MV_X_BL001',.T. /* lCheck */ )
                cCabHRef := AllTrim( GetMv( 'MV_X_BL001' ) )
            endif

            // Parâmetro ALT do componente de imagem para exibir nos casos de falha durante o carregamento da imagem
            if GetMv( 'MV_X_BL002',.T. /* lCheck */)
                cCabAlt := AllTrim( GetMv( 'MV_X_BL002') )
            endif

            // Parâmetro SRC com o path da imagem do cliente que vai no cabeçalho do workflow
            if GetMv( 'MV_X_BL003', .T. /* lCheck */ )
                cCabSRC := AllTrim( GetMv( 'MV_X_BL003' ) )
            else
                cCabSRC := ""
                cCabAlt := "Logomarca não Encontrada"
            endif

            // Instancia um objeto com o modelo de workflow
            oProc := TWFProcess():New("BL0001",OemToAnsi("Workflow de Boletos"))
            oProc:NewTask("BLENVMAIL",cFileWF )
            
            // Tratamento do assunto do e-mail de acordo com o status do pedido
            oProc:cSubject := cAssunto
            
            // Preenche o e-mail do destinatário
            oProc:cTo  := SA1->A1_EMAIL

            // Obtem o objeto do HTML para preenchimento das variáveis
            oHTML := oProc:oHTML
            
            // Atribui conteúdo as variáveis do HTML
            oHTML:ValByName("EMPRESA"           , OemToAnsi( AllTrim( SM0->M0_FILIAL ) ) )
            oHTML:ValByName("CABHREF"           , OemToAnsi( cCabHRef ) )
            oHTML:ValByName("CABALT"            , OemToAnsi( cCabAlt ) )
            oHTML:ValByName("CABSRC"            , OemToAnsi( cCabSRC ) )
            oHTML:ValByName("RAZAOSOCIAL"       , OemToAnsi( AllTrim( SM0->M0_FULNAME ) ) )
            if !Empty( SM0->M0_TEL )
                oHTML:ValByName("TELEFONE"          , OemToAnsi( AllTrim( SM0->M0_TEL ) ) ) 
            else
                oHTML:ValByName("TELEFONE"          , OemToAnsi( ' ' ) ) 
            endif
            oHTML:ValByName("CIDADE"            , OemToAnsi( AllTrim( SM0->M0_CIDENT ) +' - '+ SM0->M0_ESTENT ) )
            oHTML:ValByName("CLIENTE"           , OemToAnsi( AllTrim( SA1->A1_NOME ) ) )
            
            for nX := 1 to len( aBoletos )
                    
                if nX % 2 != 0
                    cColor := "#dcdcdc"
                Else
                    cColor := "#fff"
                EndIf
                
                aAdd((oHTML:ValByName( "IT.CLNUMERO"        )), cColor  )
                aAdd((oHTML:ValByName( "IT.NUMERO"          )), AllTrim( gt(aBoletos[nX],'numero') ) +'/'+ AllTrim( gt(aBoletos[nX],'parcela') ) )

                aAdd((oHTML:ValByName( "IT.CLDTEMISSAO"     )), cColor  )
                aAdd((oHTML:ValByName( "IT.DTEMISSAO"       )), AllTrim( DtoC( gt(aBoletos[nX],'emissao') ) ) )
                
                aAdd((oHTML:ValByName( "IT.CLDTVENC"        )), cColor  )
                aAdd((oHTML:ValByName( "IT.DTVENC"          )), AllTrim( DtoC( gt(aBoletos[nX],'vencimento') ) ) )
                
                aAdd((oHTML:ValByName( "IT.CLVALOR"         )), cColor  )
                aAdd((oHTML:ValByName( "IT.VALOR"           )), AllTrim( Transform( gt(aBoletos[nX],'valor'), PesqPict( 'SE1', 'E1_SALDO' ) ) ) )
                
            next nX

            // Anexa o PDF com os boletos gerados
            oProc:AttachFile( cPath )

            oProc:Start()
            oProc:Finish()

            // Chama função que faz o disparo dos e-mails pendentes de envio
            WFSENDMAIL()
            
        endif
    endif
    
    restArea( aArea )
return Nil

/*/{Protheus.doc} genObject
Gera um objeto novo da classe FWMsPrinter
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 24/11/2022
@return object, oNewMsPrinter
/*/
static function genObject()
    
    local oBoletos               as object
    local cNomePDF        := cEmpAnt + cFilAnt + FWTimeStamp() + '.rel'
    local lAdjustToLegacy := .F. as logical
    local lDisableSetup   := .T. as logical

    // Instancia um objeto da classe FWMSPrinter
    oBoletos := FWMSPrinter():New(cNomePDF, IMP_PDF, lAdjustToLegacy, , lDisableSetup, , , , .F., , .F.)
    oBoletos:SetResolution(78)
    oBoletos:SetPortrait()
    oBoletos:SetPaperSize(DMPAPER_A4) 
    oBoletos:SetMargin(10,10,10,10)
    oBoletos:linjob   := .F. 
    oBoletos:cPathPDF := CLOCPDF
    oBoletos:SetDevice(IMP_PDF)
    oBoletos:SetViewPDF( .F. )

return oBoletos

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
