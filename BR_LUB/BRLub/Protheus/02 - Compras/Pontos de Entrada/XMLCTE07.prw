#Include 'totvs.ch'


/*/{Protheus.doc} XMLCTE07
(Ponto de entrada Central XML para adicionar mais botões em Ações Relacionadas)
@type function
@author marce
@since 14/06/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function XMLCTE07()

	Local	aUsrBtn	:= ParamIxb[1]

	If "16755479" $ SM0->M0_CGC
		Aadd(aUsrBtn,{"PRETO"	,{|| U_RLESTA01(), Eval(bRefrPerg)  }, "Endereçar"})
	Endif

	//Aadd(aUsrBtn,{"PRETO"	,{|| MATA120(), Eval(bRefrPerg)  }, "Ped.Compra"})

Return aUsrBtn

