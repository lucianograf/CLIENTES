#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MT089UNC
//TODO MT089UNC - Tratamento da Chave Única da TES Inteligente
@author Marcelo Alberto Lauschner
@since 29/05/2019
@version 1.0
@return  cUnico, String, Conteúdo do X2_UNICO
@type User Function
/*/
User function MT089UNC()

	Local cUnico	:= PARAMIXB[1] // Chave Única Padrão
	// Se o campo existe na tabela SFM 
	If SFM->(FieldPos("FM_XTESORI")) <> 0                
		cUnico := "FM_FILIAL+FM_TIPO+FM_CLIENTE+FM_LOJACLI+FM_FORNECE+FM_LOJAFOR+FM_GRTRIB+FM_PRODUTO+FM_GRPROD+FM_EST+FM_POSIPI+FM_XTESORI"//SX2->X2_UNICO
	Endif

Return 	cUnico