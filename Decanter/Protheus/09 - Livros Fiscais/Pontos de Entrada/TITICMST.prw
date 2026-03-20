

/*/{Protheus.doc} TITICMST
Ponto de entrada para atualizar dados do título a pagar de impostos 
@type function
@version  
@author Diana Kistner 
@since 05/02/2021
@return return_type, return_description
/*/
User Function TITICMST()

	Local   cOrigem         := PARAMIXB[1]
	Local   cTipoImp        := PARAMIXB[2]
	Local   lDifal          := PARAMIXB[3]

	If AllTrim(cOrigem)== "MATA460A"
		//EXEMPLO 2 (cTipoImp)
		If AllTrim(cTipoImp) =='3' // ICMS ST
			SE2->E2_VENCTO      := DataValida(dDataBase,.T.)
			SE2->E2_VENCREA     := DataValida(dDataBase,.T.)
			SE2->E2_HIST        :=  "Guia ST - NF - "+SF2->F2_DOC
		EndIf

		//EXEMPLO 3 (lDifal)
		If lDifal // DIFAL
			SE2->E2_VENCTO      := DataValida(dDataBase,.T.)
			SE2->E2_VENCREA     := DataValida(dDataBase,.T.)
			SE2->E2_HIST        :=  "Guia Difal - NF - "+SF2->F2_DOC
		EndIf
	Endif

Return {SE2->E2_NUM,SE2->E2_VENCTO}
