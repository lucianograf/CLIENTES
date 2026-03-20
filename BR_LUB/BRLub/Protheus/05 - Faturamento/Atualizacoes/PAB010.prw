#INCLUDE "rwmake.ch"

/*/{Protheus.doc} PAB010
(CADASTRO DE CEP)
@type function
@author RAFAEL MEYER 
@since 13/08/2003
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function PAB010()
	
	cVldAlt := ".T." // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
	cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
	
	Private cString := "PAB"
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	Processa({|| sfAtuSXE()},"Atualizando registro SXE/SXF para controle de código de sequencias...")
	
	DbSelectArea("PAB")
	DbSetOrder(1)
	
	AxCadastro(cString,"Cadastros de CEPs - [PAB]",cVldAlt,cVldExc)
	
Return

/*/{Protheus.doc} sfAtuSXE
(Atualiza sequencia de númeração)
@type function
@author marce
@since 27/04/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuSXE()
	
	
	// Atualiza a sequencia correta do PAB no SXE e SXF,
	DbSelectArea("PAB")
	DbSetOrder(3)
	
	While .T.
		cNumPed := GetSxeNum("PAB","PAB_CODSEQ")
		DbSelectArea("PAB")
		DbSetOrder(3)
		If !DbSeek( xFilial( "PAB" ) + cNumPed )
			RollBackSX8()
			Exit
		EndIf
		If __lSx8
			ConfirmSx8()
		EndIf
	EndDo
	
	
	
Return
