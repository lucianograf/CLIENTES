#include 'protheus.ch'

/*/{Protheus.doc} PEBOLSEE
Modelo de PE para manipulação dos dados de parâmetros de bancos da rotina de emissão de boletos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 17/06/2022
@return array, aNewParams
/*/
user function PEBOLSEE()
    
    local aRetPE := PARAMIXB[1]

    if aRetPE[01] == '341'      // Itaú
        aRetPE[06] := SubStr( aRetPE[05], len( aRetPE[05] ), 1 )
        aRetPE[05] := SubStr( aRetPE[05], 1, len( aRetPE[05] )-1 )
    endif

return aRetPE
