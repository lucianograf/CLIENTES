#include 'totvs.ch'

/*/{Protheus.doc} PEBOLMSG
PE para adicionar mensagens personalizadas no boleto bancário
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 7/15/2022
@return array, aMessages
/*/
user function PEBOLMSG()

    local aArea       := getArea()
    local aDadosBanco := PARAMIXB[1]
    local aMessages   := {} as array
    local cTelefone   := AllTrim( SuperGetMv( 'MV_X_TELEF',,'0800 000 0688' ) )

    if len( aDadosBanco ) >= 14 
        // Mensagem de protesto forçada quando a quantidade de dias não estiver preenchida nos parâmetros de banco
        if Empty( aDadosBanco[14] ) .or. val( aDadosBanco[14] ) == 0
            aAdd( aMessages, "Sujeito a protesto após 05 (cinco) dias do vencimento." )
        endif
        // Adiciona telefone para contato
        if !Empty( cTelefone )
            aAdd( aMessages, "Dúvidas sobre a cobrança? Ligue: "+ cTelefone )
        endif
    endif

    restArea( aArea )
return aMessages
