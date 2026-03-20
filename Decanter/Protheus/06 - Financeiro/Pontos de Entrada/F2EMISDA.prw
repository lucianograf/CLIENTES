#Include "Protheus.ch"
/*/{Protheus.doc} User Function F2EMISDA
Retorna a data de emissao para o cliente decanter
@type  Function
@author TSC679 - CHARLES RIETZ
@since 24/02/2020
/*/
User Function F2EMISDA()
    SF2->(dbSetOrder(1))
    SF2->(msSeek(SE1->(E1_MSFIL+E1_NUM)+PADR(SubString(SE1->E1_PREFIXO,1,1),GetSX3Cache("F2_SERIE","X3_TAMANHO"))))
    //POSICIONE("SF2",1,SE1->(E1_MSFIL+E1_NUM)+PADR(SubString(SE1->E1_PREFIXO,1,1),GetSX3Cache("F2_SERIE","X3_TAMANHO")),"F2_EMISSAO") 
Return Day2Str(SF2->F2_EMISSAO)+Month2Str(SF2->F2_EMISSAO)+Year2Str(SF2->F2_EMISSAO)//SF2->F2_EMISSAO
