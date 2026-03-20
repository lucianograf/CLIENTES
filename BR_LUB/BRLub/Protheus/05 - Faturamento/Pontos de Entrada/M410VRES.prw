#Include "Protheus.ch"
#Include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} M410VRES

Ponto de entrada eliminação de residuo do pedido de venda

@author  Rafael Pianezzer de Souza
@since   25/02/22
@version version
/*/
//-------------------------------------------------------------------
User Function M410VRES()

    If FWCodEmp() == '10'
        U_PPEDCANC(SC5->C5_NUM)
    EndIf

Return
