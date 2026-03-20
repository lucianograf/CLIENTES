#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MTVLDACE
//Efetua validação de acesso a rotina de Banco de Conhecimento
@author Marcelo A Lauschner
@since 22/10/2017
@version 6

@type function
/*/
User function MTVLDACE()

	Local	lRet	:= .T.
	// Se for na rotina de Cadastro de Clientes ou Consulta Especifica
	If IsInCallStack("MATA030") .Or. IsInCallStack("U_FC010CON")
		If !(__cUserId $ GetMv("BF_USRSERA")) 
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
							{"Rotina com restrição de informações financeiras.",;
							"Dados inseridos pelo financeiro não estarão visíveis."},;
							5,;
							{"Verificar junto com Financeiro necessidade",;
							"de acesso à alguma informação específica."},;
							5) 
		Endif
	Endif
	
Return lRet