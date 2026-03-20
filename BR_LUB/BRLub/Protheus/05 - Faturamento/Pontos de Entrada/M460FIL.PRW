#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} M460FIL
(Filtra pedidos na tela de Faturamento Manual Padrão MATA460A)
@author MarceloLauschner
@since 04/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M460FIL()
	
	Local aAliasOld := GetArea()
	Local cFiltroC9 := ""
	Local lPedLiber := !(__cUserId $ GetNewPar("BF_M460FIL"))
	local lContOnline := GetNewPar("GM_CTBONLN",.T.)
	
	
	// Força a contabilização Online - Chamado 21.591
	If lContOnline
		//³ mv_par01 Mostra Lan‡.Contab     ?  Sim/Nao                         ³
		U_GravaSx1("MT460A","01",2)
		//³ mv_par02 Aglut. Lan‡amentos     ?  Sim/Nao                         ³
		U_GravaSx1("MT460A","02",1)
		//³ mv_par03 Lan‡.Contab.On-Line    ?  Sim/Nao                         ³
		U_GravaSx1("MT460A","03",1)
		
	Endif
	
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M460FIL")
		Return ".T."
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If lPedLiber
		cFiltroC9 += "(Alltrim(C9_FLGENVI) == 'E') "  //"(!Empty(C9_FLGENVI)) "
	Else
		cFiltroC9 += " .T. "
	endif
	
	RestArea( aAliasOld )
	
Return cFiltroC9

