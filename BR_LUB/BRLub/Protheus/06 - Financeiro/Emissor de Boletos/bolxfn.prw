#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} BOLXFN
Retorno vai depender de onde a função estiver sendo chamada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/12/2022
@param cID, character, ID do local onde a função está sendo chamada
@return variadic, xRet
/*/
user function BOLXFN( cID )
    
    local xRet := Nil
    local aSubVet := {} as array
    
    default cID := "" 

    if cID == '740BRW'
        xRet := {}      // Retorno será um vetor de novos botões da rotina FINA740 - Funções do Contas a Receber
        
        // SubMenu do botão Boleto
        aAdd( aSubVet, { 'Imprimir Boleto', 'U_B1740BRW', 0, 3 } )

        // Botão Boleto
        aAdd( xRet, { 'Boletos', aSubVet, 0, 4 } )

    endif

return xRet

/*/{Protheus.doc} B1740BRW
Botão Imprimir Boleto da rotina FINA740
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/12/2022
/*/
user function B1740BRW()
    
    local aArea := getArea()
    
    // Chama impressão de boletos
    U_BOLRULES( 'SE1' )

    restArea( aArea )
return Nil

