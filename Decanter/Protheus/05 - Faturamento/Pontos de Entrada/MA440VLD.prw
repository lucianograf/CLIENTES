#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} MA440VLD

Valida se pode executar a liberação do pedido de venda

@author charles.totvs
@since 04/06/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
user function MA440VLD()
	Local lRet	:=	.T.
 
	Begin Sequence

		//Não libera para cliente bloqueado
		dbSelectArea("SA1")
		dbSetOrder(1)
		If dbSeek(FWXFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI) .AND. SA1->A1_MSBLQL == '1'
			lRet := .F.
			MsgStop("Cliente bloqueado, realize a liberação do cliente. ","Atenção - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

	End Sequence


return lRet
