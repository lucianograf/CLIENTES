#include 'totvs.ch'

/*/{Protheus.doc} BFFINM31
Função para utilização no cálculo do sequencial de linha das configurações dos arquivos CNAB 240 do Contas a Receber
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 6/20/2022
@return character, cSeq
/*/
user function BFFINM31()
	
	Local cRet := ""
	Local nQt  := iif( Type( "PARAMIXB[01]" ) != "U", PARAMIXB[01], 1 )
	Local lFim := iif( Type( "PARAMIXB[02]" ) != "U", PARAMIXB[02], .F. )
	
	if Type( "cSqSic" ) == "U"
		Public cSqSic := StrZero( 1, 5 )
	Else
		cSqSic := StrZero( Val( cSqSic )+ nQt, 5 )
	EndIf  
	
	cRet := cSqSic
	
	if lFim
		cSqSic := Nil
	EndIf
	
Return ( cRet )
