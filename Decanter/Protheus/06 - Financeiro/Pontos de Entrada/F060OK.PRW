//Bibliotecas
#Include "Protheus.ch"
 
/*---------------------------------------------------------------------*
 | P.E.:  F060OK                                                       |
 | Desc:  P.E. que valida dados ao confirmar Tranferência Financeira   |
 | Link:  http://tdn.totvs.com/display/public/mp/F060OK                |
 *---------------------------------------------------------------------*/
 
User Function F060OK()
    Local aArea := GetArea()
    Local lRet := .T.
    Local aAux := aClone(ParamIxb) 
     
    //Conteudo de aAux
    //[01]    cSituacao    = Situacao para a qual esta sendo transferido o titulo
    //[02]    cPort060    = Banco para o qual esta sendo transferido o titulo
    //[03]    cAgen060    = Agencia para a qual esta sendo transferido o titulo
    //[04]    cConta060    = Conta para a qual esta sendo transferido o titulo
    //[05]    lDesc        = Informa se a carteira para a qual esta sendo transferido o titulo eh 2 (descontada) ou 7 (Descontada caucionada)
    //[06]    cCliente    = Cliente, Loja e Nome do Cliente do titulo
    //[07]    cTitulo    =`Prefixo, Numero e Parcela do titulo
    //[08]    cSituAnt    = Situacao de cobranca anterior
    //[09]    cContrato    = Numero do contrato bancário
    //[10]    cPortador    = Portador anterior do titulo
     
        cPort:= UPPER(aAux[02])
    if cport <> aAux[02]
        lret:=.F.
        alert('Portador invalido-VERIFIQUE!!!!!')
    ENDIF
    RestArea(aArea)
Return lRet
