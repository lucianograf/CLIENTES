#include 'totvs.ch'

/*/{Protheus.doc} F200VAR
PE para manipular informações obtidas por meio de importação do arquivo de retorno CNAB
@type function
@version 12.1.033
@author Jean Carlos Pandolfo Saggin
@since 6/29/2022
@return array, aNewData
/*/
user function F200VAR()

    local aDados := PARAMIXB[01]
    local aArea := GetArea()

    if ValType( aDados ) == 'A' .and. len( aDados ) > 0
        dBaixa    := aDados[02]
        dDataCred := aDados[13]
        // Validação para preenchimento automático das variáveis de data de crédito quando entrada no ponto de entrada for após a leitura da 
        // última linha do arquivo. Nesse momento, não existem mais informações a serem lidas e as variáveis precisam estar preenchidas para
        // que o movimento bancário referente as despesas seja gravado na data correta
        if Empty( aDados[16] ) .and. Empty( dBaixa ) .and. Empty( dDataCred )      // Depois de lida a última linha do arquivo
            dBaixa    := DataValida( dDataBase, .T. )
            dDataCred := DataValida( dDataBase, .T. )
        endif
    endif

    RestArea( aArea )
return aDados
