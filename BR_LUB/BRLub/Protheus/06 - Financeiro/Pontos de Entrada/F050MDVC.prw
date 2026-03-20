#include 'totvs.ch'

/*/{Protheus.doc} F050MDVC
PE para calcular a data de vencimento do PCC de maneira customizada para atender a necessidade da BrasilLub
@type function
@version 1.0
@author Jean Carlos P. Saggin
@since 5/26/2022
@return date, dNextDay
/*/
User function F050MDVC()
    
    Local dNextDay := ParamIxb[1] //data calculada pelo sistema
    Local cImposto := ParamIxb[2]
    Local dEmissao := ParamIxb[3]
    // Local dEmis1   := ParamIxb[4]
    // Local dVencRea := ParamIxb[5]
    Local nNextMes := Month(dEmissao)+1

    If cImposto $ "PIS,CSLL,COFINS"//Calcula data 20 do próximo mes 
        dNextDay := CTOD("20/"+Iif(nNextMes==13,"01",StrZero(nNextMes,2))+"/"+; 
        Substr(Str(Iif(nNextMes==13,Year(dEmissao)+1,Year(dEmissao))),2))//Acho o ultimo dia util do periodo desejado 
        dNextday := DataValida(dNextday,.F.)
    EndIf  

Return dNextDay
