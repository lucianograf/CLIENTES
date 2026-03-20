
/*/{Protheus.doc} MT089TOK
(Ponto de entrada no cadastro de TES inteligente - Se criados novos campos, precisa adicionar no cUnico   )
@author MarceloLauschner
@since 19/07/2012
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function MT089TOK()
	
	Local	lRet	:= .T.
	Local	cUnico 	:= "FM_FILIAL+FM_TIPO+FM_CLIENTE+FM_LOJACLI+FM_FORNECE+FM_LOJAFOR+FM_GRTRIB+FM_PRODUTO+FM_GRPROD+FM_EST+FM_POSIPI"//SX2->X2_UNICO
	Local	cChave	:= ""
	Local	cChave2	:= ""
	Local	nRecContr	:= 0
	
	// Efetua verifica豫o se esta valida豫o deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MT089TOK")
		Return .T.
	Endif
	
	// Executa grava豫o do Log de Uso da rotina
	U_BFCFGM01()
	

	DbSelectArea("SFM")
	DbSetOrder(1)
	
	If (INCLUI .or. ALTERA) .And. dbSeek(xFilial("SFM")+M->FM_TIPO+M->FM_PRODUTO+M->FM_CLIENTE+M->FM_LOJACLI+M->FM_FORNECE+M->FM_LOJAFOR)
		
		While !Eof() .And. SFM->(FM_FILIAL+FM_TIPO+FM_PRODUTO+M->FM_CLIENTE+FM_LOJACLI+FM_TE+FM_TS) ==;
				(xFilial("SFM")+M->FM_TIPO+M->FM_PRODUTO+M->FM_CLIENTE+M->FM_LOJACLI+M->FM_TE+M->FM_TS)
			
			//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
			//� Macro executa a chave unica                                            �
			//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
			If M->FM_GRTRIB =="ZZZ"
				M->FM_GRTRIB	:= Space(Len(SFM->FM_GRTRIB))
			Endif
			cChave  	:= SFM->(&cUnico)
			cChave2 	:= xFilial("SFM")+SubStr(M->(&cUnico),3)
			nRecContr	:= SFM->(Recno())
			
			If (INCLUI .OR. ALTERA) .AND. Alltrim(cChave) == Alltrim(cChave2) .And. ((ALTERA .And. nRecContr<>SFM->(Recno())) .Or. !ALTERA)
				Help(" ",1,"JAGRAVADO")
				lRet := .F.
				Exit
			Endif
			dbSkip()
		EndDo
		
	Endif
	
Return lRet
