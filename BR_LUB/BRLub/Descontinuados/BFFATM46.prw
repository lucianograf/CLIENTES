#include 'totvs.ch'

/*/{Protheus.doc} BFFATM46
Função para buscar o cliente pelo CNPJ e ajustar a data de cadastro conforme informação do arquivo .csv
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 9/8/2022
/*/
user function BFFATM46()
    
    local nAdjust := 0  as numeric
    local nEqual  := 0  as numeric
    local nLine   := 0  as numeric
    local cFile   := "" as character
    local aLine   := {} as array
    local cLine   := "" as character
    local oFile         as object
    local cCGC    := "" as character

    cFile := AllTrim( CGETFILE( "Arquivo *.csv | *.csv", 'Busque o arquivo a ser lido...', 0, 'c:/',;
     .F. /* lSave */, GETF_LOCALHARD, .F. /* lShowTreeServer */, .T./* lKeepCase */ ) )

    if !Empty( cFile )
        if File( cFile )
            oFile := FWFileReader():New( cFile )
            if oFile:Open()
                
                DBSelectArea( 'SA1' )
                SA1->( DBSetOrder( 3 ) )

                while oFile:hasLine()
                    cLine := StrTran(StrTran(StrTran(oFile:getLine(),'"',''),'.',''),'-','')
                    nLine++
                    if nLine > 3
                        aLine := StrTokArr2( cLine, ';', .T. /* lEmptyCell */ )
                        cCGC := PADR( StrTran(AllTrim(aLine[1]),'/',''), TAMSX3('A1_CGC')[1], ' ' )
                        // Se localizou o cliente, verifica data de cadastro se está preenchida. Se não estiver, atualiza com a informação que consta no arquivo
                        if SA1->( DBSeek( FWxFilial( 'SA1' ) + cCGC ) )
                            if Empty( SA1->A1_DTCAD ) .and. !Empty( CtoD( aLine[3] ) )
                                RecLock( 'SA1', .F. )
                                SA1->A1_DTCAD := CtoD( aLine[3] )
                                SA1->( MsUnlock() )
                                nAdjust++
                            elseif SA1->A1_DTCAD == CtoD( aLine[3] )
                                nEqual++
                            endif
                        endif
                    endif
                enddo
                oFile:Close()
                MsgInfo( 'Arquivo '+ cFile +' processado com sucesso!' +chr(13)+chr(10)+;
                        '<b>' +cValToChar( nAdjust ) +'</b> clientes ajustados!'+chr(13)+chr(10)+;
                        '<b>' +cValToChar( nEqual ) +'</b> clientes com data de cadastro idênticas.', 'S U C E S S O ! ' )
            endif
        else
            MsgStop( 'O arquivo informado '+ cFile +' não foi localizado!', 'I N V A L I D O ! ' )
        endif
    endif

return Nil
