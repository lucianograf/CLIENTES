#include 'protheus.ch'
#include 'parmtype.ch'


User Function MT500ANT()

	Local	lRet		:= .T.
	Local	aAreaOld	:= GetArea()
	
	If Type("cAntNumC5") == "U"
		Public 	cAntNumC5	:= ""
	Endif
	
	If cAntNumC5 <> SC5->C5_NUM
		//MLCFGM01(cTipo,cPedido,cObserv,cResp,lBtnCancel,cMotDef,lAutoExec,cInUserAuto,cInDestMail)
		lRet	:= U_MLCFGM01("ER",SC5->C5_NUM,FunName())[2] // 
	Endif
	
Return lRet