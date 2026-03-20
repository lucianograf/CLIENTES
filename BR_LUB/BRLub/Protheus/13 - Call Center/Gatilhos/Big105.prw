
/*/{Protheus.doc} BIG105
(Gatilho para avisar que o clientes é do grupo NEA )
	
@author Marcelo Lauschner
@since 10/03/2005
@version 1.0		

@return character, Loja do cliente

@example
(examples)

@see (links_or_references)
/*/
User Function BIG105()

	Local	aAreaOld	:= 	GetArea()
	Local 	cCliente	:=  M->UA_CLIENTE
	Local	cLoja    	:=  M->UA_LOJA
	Local	cNea     	:= 	Space(6)
	Local	cReembBk	:=  M->UA_REEMB

	dbselectarea("SA1")
	dbsetorder(1)
	MsSeek(xFilial("SA1")+cCliente+cLoja)
	cNea  := SA1->A1_SATFORT

	If 	cNea >= "R4020V" .and. cNea <= "R40999"
		Alert("Cliente cadastrado como sendo integrante do OM NEA.!","Informação","INFO")
		M->UA_REEMB	:=	"S"
	Else
		M->UA_REEMB := 	cReembBk
	Endif

	RestArea(aAreaOld)

Return (M->UA_LOJA)
