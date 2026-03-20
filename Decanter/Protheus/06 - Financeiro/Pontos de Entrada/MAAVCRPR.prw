#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MAAVCRPR
Este ponto de entrada pertence à rotina de avalização de crédito de clientes, 
MaAvalCred() – FATXFUN(). Ele permite que, após a avaliação padrão do sistema, 
o usuário possa fazer a sua própria.

Parâmetros. 
ParamIxb[1]=Código do cliente 
ParamIxb[2]=Código da filial 
ParamIxb[3]=Valor da venda
ParamIxb[4]=Moeda da venda 
ParamIxb[5]=Considera acumulados de Pedido de Venda do SA1
ParamIxb[6]=Tipo de crédito (“L” - Código cliente + Filial; “C” - código do cliente) 
ParamIxb[7]=Indica se o credito será liberado ( Lógico ) 
ParamIxb[8]=Indica o código de bloqueio do credito ( Caracter )
Eventos
@type function
@author Jefferson de Souza
@since 
@version 1.0
@param lEndereco,
    @example
    MAAVCRPR
/*/
 
 User Function MAAVCRPR()
 
 //Local aAreaOld	:= GetArea()
 Local lRet     := ParamIxb[7]
 L//ocal cCondPad := GetMV("MV_ZLBCRD") // Condição que ao ser usada, o cliente não passa pela análise de crédito.  

//If FunName() <> 'ACTVS05A10'
    //If  M->C5_FILIAL $ ("0101/0102/0103/0104/0105/0107/0201/0202")
//    if  M->C5_CONDPAG $ cCondPad
//        lRet := .T.
//    endif    
    //Endif
//Endif

//RestArea(aAreaOld)

Return lRet
