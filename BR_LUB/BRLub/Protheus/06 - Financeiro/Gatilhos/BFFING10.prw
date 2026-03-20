#Include 'Protheus.ch'

/*/{Protheus.doc} BFFING10
(long_description)
	
@author MarceloLauschner
@since 18/03/2014
@version 1.0 - Chamado 6936 - Configurar Centro de custo a crédito na geração de cheques.		

@return character, Código do centro de custo

@example
(examples)

@see (links_or_references)
/*/
User Function BFFING10(cInConta)

Local		cCustRet		:= ""
Local		aAreaOld		:= GetArea()

DbSelectArea("CT1")
DbSetOrder(1)
If DbSeek(xFilial("CT1")+cInConta)
	If CT1->CT1_CCOBRG == "1" // Verifica se o Centro de custo é Obrigatório
		DbSelectArea("SA2")
		DbSetOrder(1)
		If DbSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA)
			cCustRet	:= SA2->A2_CC
		Endif
	Endif
Endif

RestArea(aAreaOld)

Return cCustRet

