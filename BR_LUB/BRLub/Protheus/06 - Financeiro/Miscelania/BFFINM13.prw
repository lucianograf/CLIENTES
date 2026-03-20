#Include 'Protheus.ch'


/*/{Protheus.doc} BFFINM13
(Retorna saldo do título considerando abatimentos )
@type function
@author marce
@since 17/03/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFINM13()

	Local	nTotAbImp	:= 0
	Local	nE1Saldo	:= 0
	Local	nDescFin	:= 0
	
	// Calcula do Saldo do Título para geração de arquivos de remessa bancária
	nTotAbImp	:= SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"V",SE1->E1_BAIXA)
	nE1Saldo	:= SE1->E1_SALDO +SE1->E1_ACRESC-SE1->E1_DECRESC - nTotAbImp 
	nDescFin 	:= Round((nE1Saldo*SE1->E1_DESCFIN )/100,2)
	nE1Saldo	-= nDescFin			
	
Return nE1Saldo

