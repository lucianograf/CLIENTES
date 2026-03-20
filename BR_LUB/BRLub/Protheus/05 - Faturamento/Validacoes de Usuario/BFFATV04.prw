#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} BFFATV04
//Validação de usuário para os campos C5_BANCO / UA_BANCO 
@author Marcelo Alberto Lauschner
@since 17/08/2018
@version 1.0
@return logical , .F. / .T. 
@param cInBanco, characters, Código do banco 
@type function
/*/
User function BFFATV04(cInBanco)

	Local	lRet		:= .T. 
	Local	aAreaOld	:= GetArea()

	Default	cInBanco	:= ""

	If !IsBlind()
		
		// Se já tem conteúdo, apenas mantém 
		If !Empty(cInBanco)
		
		// Senão valida conforme variável posicionada	
		ElseIf ReadVar() == "M->C5_BANCO"
			cInBanco	:= M->C5_BANCO
		ElseIf ReadVar() == "M->UA_BANCO"
			cInBanco	:= M->UA_BANCO
		Endif

		// Verifica restrição - Chamado 21.521 
		If cInBanco $ "900"
			If __cUserId $ GetNewPar("BF_FATV04A","000417#000180#000264#000077#000073") // Viviane/Thiago/Joice/Silvana/Leandro

			Else
				MsgAlert("Usuário sem permissão para usar o Banco '" + cInBanco + "'","BFFATV04 - Validação Portador!")
				lRet	:= .F. 
			Endif  
		Endif

	Endif

	RestArea(aAreaOld)


Return lRet