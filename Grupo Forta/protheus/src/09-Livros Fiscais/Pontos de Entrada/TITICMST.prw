/*/{Protheus.doc} TITICMST
Ponto de entrada para gerar observações no título gerado de impostos sobre o faturamento 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 07/12/2021
@return variant, return_description
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
