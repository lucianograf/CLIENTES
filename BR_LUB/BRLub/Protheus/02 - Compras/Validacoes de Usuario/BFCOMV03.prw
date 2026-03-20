#include "protheus.ch"

/*/{Protheus.doc} BFCOMV03 (Marcas utilizadas no B1_CABO )
@type function
@author Iago Luiz Raimondi
@since 10/05/2021
@version 1.0
@return ${return}, ${return_description}
@see (links_or_references)
/*/
User Function BFCOMV03()


	Local cMarcas := ""
    /*
    If cEmpAnt == "02"
        cMarcas := "TEX=Texaco;IPI=Ipiranga;MIC=Michelin;CON=Continental;MOT=Motos;LUS=Wynns;ROC=Rocol;HOU=Houghton;ADT=Aditivos;CAR=Carcare;"
        cMarcas += "REL=Kit Relacao Motos;BIK=Pneus Bike;"
    ElseIf cEmpAnt =="11"
        cMarcas := "TEX=Texaco;IPI=Ipiranga;MIC=Michelin;CON=Continental;MOT=Motos;LUS=Lust;ROC=Rocol;HOU=Houghton;ADT=Aditivos;CAR=Carcare;"
        cMarcas += "WEG=Wega;EXT=Extron;MTR=Motrio;MAX=Maxon;"    
        cMarcas += "PTB=Petrobras;"    
        cMarcas += "VAL=Valvoline;GUL=Gulf;REP=Repsol;"
    Else
    */
    cMarcas := "MIC=Michelin;CON=Continental;MOT=Motos;LUS=Wynns;"
    //Endif 
    // Marcelo 17/08/2021 Novas Marcas 
    cMarcas += "AGR=Agronegocios;"
    cMarcas += "OUT=Outros;"
    cMarcas += "HOU=Houghton;"
    cMarcas += "ROC=Rocol"

Return cMarcas
