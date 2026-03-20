#Include "Protheus.ch
#Include "Totvs.ch"

/*/{Protheus.doc} sfProduto
Escolhe diretorio para salvar arquivo EDI
@type function
@version 1
@author Iago Luiz Raimondi
@since 24/09/2021
@return character, diretorio para salvar arquivo EDI
/*/

User Function TMSEDIDR

	Local aArea		:= GetArea()
	Local cLocal 	:= "\"

	cLocal := cGetFile( '*.*|*.*' , 'Diretório', 1, 'C:\edi\', .F., nOR( GETF_LOCALHARD, GETF_RETDIRECTORY ),.T., .T. )

	RestArea(aArea)

Return cLocal
