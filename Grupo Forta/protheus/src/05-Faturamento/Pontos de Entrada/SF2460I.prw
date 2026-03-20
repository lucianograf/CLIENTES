#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} SF2460I
//  Ponto de Entrada na Geração da Nota Fiscal
@author Marcelo Alberto Lauschner
@since 14/08/2019
@version 1.0
@return Nil 
@type User Function
/*/
User function SF2460I()

	// Grava Log da Geração da Nota 
	U_MLCFGM01("NF",,"Geração de nota fiscal "+SF2->F2_DOC,FunName())

Return