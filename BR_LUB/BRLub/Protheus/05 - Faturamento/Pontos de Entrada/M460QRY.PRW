#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} M460QRY
(Filtra pedidos na tela de Faturamento Manual Padrão MATA460A)
@author MarceloLauschner
@since 04/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M460QRY()
	
	Local aAreaOld  := GetArea()
	Local cFilterC9 := ""
	Local lPedLibs  := !(__cUserId $ GetNewPar("BF_M460FIL","000130"))
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M460QRY")
		Return  ParamIXB[1]
	Endif
	
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If lPedLibs
		cFilterC9 += "(C9_FLGENVI = 'E' ) "
	Endif
	
	RestArea( aAreaOld )
	
	If Len( cFilterC9 ) > 0
		cFilterC9 := ParamIXB[1] + " AND " + cFilterC9
	Else
		cFilterC9 := ParamIXB[1]
	Endif
	
Return cFilterC9


