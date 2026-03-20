#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*/{Protheus.doc} M410PVNF
//Ponto de entrada para validar Faturamento de pedido na rotina Mata410 - Preparar Doc.Saída.
@author Marcelo Alberto Lauschner
@since 22/08/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function M410PVNF ()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T. 
	Local 	cNumPed  	:= SC5->C5_NUM
	
	
	// Verifica o status do Pedido antes de poder faturar 
	U_MLFATC07(@lRet)

	RestArea(aAreaOld)

Return lRet	