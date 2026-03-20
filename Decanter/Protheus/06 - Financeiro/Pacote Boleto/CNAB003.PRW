#INCLUDE "RWMAKE.CH"

/*/{Protheus.doc} CNAB003

Retorna chave DANFE para uso no CNAB 444 posições 

@author TSCC47 - Arthur Voltolini
@since 26/02/2024
@version 1.0
@return return, return_description
/*/                          

USER FUNCTION CNAB003
	_lDesc := ""
    _cNF := ""    
    DBSelectArea("SF2")
    DBSetOrder(1)
    _lDesc := Posicione("SF2",4,SE1->E1_FILORIG+PadR(SUBSTR(SE1->E1_PREFIXO, 1, 1),3,"")+DTOS(SE1->E1_EMISSAO)+SE1->E1_NUM+SE1->E1_CLIENTE+SE1->E1_LOJA,"F2_CHVNFE")
    IF !Empty(_lDesc) 
       _cNF := _lDesc 
    ELSE
        _cNF := StrZero(0,44)
    ENDIF
Return _cNF
