#INCLUDE "rwmake.ch"
 
/*/{Protheus.doc} BIG100
(Verifica data de entrega)
	
@author MarceloLauschner
@since 02/12/2013
@version 1.0		

@return cPrazo , Prazo para entrega

@example
(examples)

@see (links_or_references)
/*/
User Function BIG100()

Local 	aAreaOld	:=	GetArea()
Local 	cCliente 	:= 	M->UA_CLIENTE
Local 	cLoja    	:= 	M->UA_LOJA
Local 	cPrazo   	:= 	" "
Local 	cCEP		:=	" "		

dbSelectArea("SA1")
dbSetOrder(1)
If 	MsSeek(xFilial("SA1")+cCliente+cLoja)
	cCEP := SA1->A1_CEP

	dbSelectArea("PAB")
	dbSetOrder(1)
	If 	MsSeek(xFilial("PAB")+cCEP)
		cPrazo:= PAB->PAB_PRAZO
	Endif
Endif        

RestArea(aAreaOld)

Return (cPrazo)
