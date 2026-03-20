#Include 'Protheus.ch'

/*/{Protheus.doc} F090AFIL
(Ponto de entrada para substituir trecho do Filtro da Query. Quando filtrado por vencimento, sistema só retornava títulos sem borderô.)
@type function
@author marce
@since 03/05/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (http://tdn.totvs.com/display/public/PROT/F090AFIL+-+Inclui+uma+nova+condicional+no+filtro)
/*/
User Function F090AFIL()
	//Este ponto de entrada será desativado no fonte FINA090 a partir da versão 12.1.17 da data 29/08/2017, sendo o mesmo substituído pelo F090QFIL. 
	
	Local	cFiltro		:= ParamIxb[1]
	// Retira o Filtro de Numero de Bordero em Branco para permitir 
	cFiltro	:= StrTran(cFiltro,'E2_NUMBOR=="'+Space(TamSX3("E2_NUMBOR")[1])+'".and.',"")
	
Return cFiltro


