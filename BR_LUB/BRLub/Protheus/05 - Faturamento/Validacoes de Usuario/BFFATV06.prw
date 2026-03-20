#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} BFFATV06
//TODO Validação do campo Z8_VALOR 
@author Marcelo Alberto Lauschner 
@since 11/03/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function BFFATV06()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .F.
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+M->Z8_CODPROD)
	
	If (Vazio().And.M->Z8_REEMB=="P")
		lRet	:= .T.
	ElseIf (M->Z8_REEMB=="W".And.M->Z8_VALOR>0)
		lRet	:= .T.
	ElseIf (SB1->B1_CABO $ "LUS#ADT" .And. M->Z8_VALOR>0)
		lRet	:= .T.
	ElseIf (M->Z8_VALOR> 0.And. M->Z8_VALOR/SB1->B1_QTELITS < 5 )
		lREt	:= .T.
	Else
		MsgAlert("Nenhuma condição atendida para cadastrar o valor por tampa!")
	Endif
	
	RestArea(aAreaOld)
	
Return lRet
