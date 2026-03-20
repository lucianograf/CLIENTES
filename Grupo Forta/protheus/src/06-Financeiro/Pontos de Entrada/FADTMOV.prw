#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} FADTMOV
// Ponto de entrada para validar a data Financeira da movimentação no sistema. 
@author Marcelo Alberto Lauschner 
@since 11/11/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function FADTMOV()

	Local	lRet	:= .T. 
	Local 	dData 	:= ParamIxb[ 1 ] //Data informada pela função DtMovFin


	If IsInCallStack("FA070TIT") // Baixa de Títulos a Receber 
		If dData < SE1->E1_EMIS1 // Database menor que a data do lançametno
			MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é menor que a data de entrada do título no sistema " + DTOC(SE1->E1_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
			lRet := .F.
		Endif

	ElseIf IsInCallStack("FA080TIT") // Baixa de Títulos a Pagar 
		If dData < SE2->E2_EMIS1 // Database menor que a data do lançamento 
			MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é menor que a data de entrada do título no sistema " + DTOC(SE2->E2_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
			lRet := .F.
		Endif
	ElseIf IsInCallStack("FA340COMP") // Compensação Contas a Pagar 
		If dData < SE2->E2_EMIS1 // Database menor que a data do lançamento 
			MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é menor que a data de entrada do título no sistema " + DTOC(SE2->E2_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
			lRet := .F.
		Endif
	ElseIf IsInCallStack("FA330COMP") // Baixa de Títulos a Receber 
		If dData < SE1->E1_EMIS1 // Database menor que a data do lançametno
			MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é menor que a data de entrada do título no sistema " + DTOC(SE1->E1_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
			lRet := .F.
		Endif	
	ElseIf IsInCallStack("FA050Delet") // Exclusão de Títulos a Pagar 
		// Valida tipo PA 
		If Alltrim(SE2->E2_TIPO) == "PA"
			If dData <> SE2->E2_EMIS1 // Database menor que a data do lançamento 
				MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é diferente da data de entrada do título no sistema " + DTOC(SE2->E2_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
				lRet := .F.
			Endif
		Else
			If dData < SE2->E2_EMIS1 // Database menor que a data do lançamento 
				MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é menor que a data de entrada do título no sistema " + DTOC(SE2->E2_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
				lRet := .F.
			Endif
		Endif
	ElseIf IsInCallStack("FA040Delet") // Exclusão de Títulos a Receber 
		// Valida tipo RA
		If Alltrim(SE1->E1_TIPO) == "RA"
			If dData <> SE1->E1_EMIS1 // Database menor que a data do lançamento 
				MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é diferente da data de entrada do título no sistema " + DTOC(SE1->E1_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
				lRet := .F.
			Endif
		Else
			If dData < SE1->E1_EMIS1 // Database menor que a data do lançamento 
				MsgAlert("Você está utilizando a data base " + DTOC(dData) + " que é menor que a data de entrada do título no sistema " + DTOC(SE1->E1_EMIS1),ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Operação não permitida!")
				lRet := .F.
			Endif
		Endif
	Endif


Return lRet