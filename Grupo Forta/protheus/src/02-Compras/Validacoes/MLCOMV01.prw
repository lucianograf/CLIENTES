#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MLCOMV01
//TODO Validação de campo de usuário - A2_XCODRUB 
@author Marcelo Alberto Lauschner
@since 08/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MLCOMV01()
	
	Local	lRet	:= .T. 
	
	If M->A2_XCODRUB <> StrZero(Val(M->A2_XCODRUB),6)
		ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
							{"O número de caracteres não está correto",;
							"para que a integração do Rubi com Protheus funcione corretamente."},;
							5,;
							{"Informe o número do código do funcionário Rubi, colocando zeros à esquerda até completar o tamanho de 6 dígitos. Por exemplo: 21 deve ser informado como 000021 "},;
							5) 
		lRet	:= .F. 
	Endif
	
Return lRet