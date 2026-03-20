#include 'protheus.ch'
#include 'parmtype.ch'

User function MLCTBG01(cInLp,cCpoRet)

	Local	aAreaOld	:= GetArea()
	Local	cReturn		:= ""
	
	// Declaro variáveis só para facilitar inclusão de contas contábeis 
	If Type("ALTERA") =="U"
		Private ALTERA	:= .T.
	Endif
	If Type("INCLUI") =="U"
		Private INCLUI	:= .T.
	Endif
	
	
	If cInLp == "610"
		If SD2->D2_TIPO $ "D#B"
			cReturn	:= SA2->A2_XCCPASV
			If Empty(cReturn)
				// Faz o cadastro automática da conta contábil para o cliente 
				U_MLCTBM02(@cReturn /*cA2XCCPASV*/,SA2->A2_COD/*cA2COD*/,SA2->A2_NOME/*cA2NOME*/)
				If !Empty(cReturn)
					// Atualiza o cadastro do cliente com a nova conta 
					DbSelectArea("SA2")
					RecLock("SA2",.F.)
					SA1->A2_XCCPASV	:= cReturn
					MsUnlock()
				Endif
			Endif
			
		Else
			cReturn	:= SA1->A1_CONTA
			If Empty(cReturn)
				// Faz o cadastro automática da conta contábil para o cliente 
				U_MLCTBM03(@cReturn /*cA1CONTA*/,SA1->A1_COD/*cA1COD*/,SA1->A1_NOME /*cA1NOME*/)
				If !Empty(cReturn)
					// Atualiza o cadastro do cliente com a nova conta 
					DbSelectArea("SA1")
					RecLock("SA1",.F.)
					SA1->A1_CONTA	:= cReturn
					MsUnlock()
				Endif
			Endif
		Endif

	ElseIf cInLp == "620"
	
	// Documento de entrada 
	ElseIf cInLp == "650"
		
		If !(SD1->D1_TIPO $ "D#B")
			cReturn	:= SA2->A2_XCCPASV
			If Empty(cReturn)
				// Faz o cadastro automática da conta contábil para o cliente 
				U_MLCTBM02(@cReturn /*cA2XCCPASV*/,SA2->A2_COD/*cA2COD*/,SA2->A2_NOME/*cA2NOME*/)
				If !Empty(cReturn)
					// Atualiza o cadastro do cliente com a nova conta 
					DbSelectArea("SA2")
					RecLock("SA2",.F.)
					SA2->A2_XCCPASV	:= cReturn
					MsUnlock()
				Endif
			Endif
			
		Else
			cReturn	:= SA1->A1_CONTA
			If Empty(cReturn)
				// Faz o cadastro automática da conta contábil para o cliente 
				U_MLCTBM03(@cReturn /*cA1CONTA*/,SA1->A1_COD/*cA1COD*/,SA1->A1_NOME /*cA1NOME*/)
				If !Empty(cReturn)
					// Atualiza o cadastro do cliente com a nova conta 
					DbSelectArea("SA1")
					RecLock("SA1",.F.)
					SA1->A1_CONTA	:= cReturn
					MsUnlock()
				Endif
			Endif
		Endif
			
	Endif
	RestArea(aAreaOld)

Return cReturn