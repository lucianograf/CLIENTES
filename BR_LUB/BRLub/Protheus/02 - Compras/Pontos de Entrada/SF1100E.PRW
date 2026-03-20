#INCLUDE "rwmake.ch"

/*/{Protheus.doc} SF1100E
(Ponto de entrada na exclusão de notas fiscais de entrada)
@author Rafael Meyer
@since  28/08/06
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function SF1100E()
	
	Local aAreaOld	:= GetArea()
	
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("SF1100E")
		Return .T. 
	Endif
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	dbSelectArea("SZA")
	dbSetOrder(3)
	dbSeek(xFilial("SZA")+SF1->F1_DOC+SF1->F1_FORNECE+SF1->F1_LOJA)
	While !Eof() .And.;
			SZA->ZA_DOC == SF1->F1_DOC .And.;
			SZA->ZA_CLIENTE == SF1->F1_FORNECE .And.;
			SZA->ZA_LOJA == SF1->F1_LOJA .And.;
			SZA->ZA_TIPOMOV == "D"		// Posiciona Nota/Cliente/Loja e Tipo Movimento evitando exclusão de outros registros
		RecLock("SZA",.F.)
		dbDelete()
		MsUnLock("SZA")
		DbSelectArea("SZA")
		DbSkip()
	Enddo
	
	RestArea(aAreaOld)
	
Return(.T.)
