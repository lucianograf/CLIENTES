#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} M410VRES
//Ponto de entrada para validação de Eliminição de residuos diretamente na rotina de pedido de venda. 
@author Marcelo Alberto Lauschner
@since 22/05/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function M410VRES()
	
	Local	lRet		:= .T.
	Local	aAreaOld	:= GetArea()
	
	//MLCFGM01(cTipo,cPedido,cObserv,cResp,lBtnCancel,cMotDef,lAutoExec,cInUserAuto,cInDestMail)
	lRet	:= U_MLCFGM01("ER",SC5->C5_NUM,FunName())[2] // 
		
		
Return lRet