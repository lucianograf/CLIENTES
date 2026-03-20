#include "protheus.ch"
#include "totvs.ch"

/*/{Protheus.doc} USAVEN3
(Retornar vendedor por segmento negocio  )

@author MarceloLauschner
@since 16/01/2013
@version 1.0

@param lUseSUA, logico, (Descrição do parâmetro)

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
User Function USAVEN3(lUseSUA,lIsVend03)
	
	Local 	aAreaOld	:=	GetArea()
	Local   cVend		:= ""
	Local 	cCliente 	:= ""
	Local 	cLoja    	:= ""
	Default	lUseSUA		:= .T.
	Default	lIsVend03	:= .F.	// 17/11/2015 - Se for Gatilho para Vendedor 03 
	
	If lUseSUA
		cCliente 	:= M->UA_CLIENTE
		cLoja    	:= M->UA_LOJA
	Else
		cCliente 	:= M->C5_CLIENTE
		cLoja    	:= M->C5_LOJACLI
	Endif
	
	dbSelectArea("SA1")
	dbSetOrder(1)
	If DbSeek(xFilial("SA1")+cCliente+cLoja)
		If RetCodUsr() $ GetNewPar("BF_USAVEN3","000000")
			cVend := SA1->A1_VEND3
		Elseif RetCodUsr() $ GetNewPar("BF_USAVEN2","000000")
			cVend := SA1->A1_VEND2
		Elseif RetCodUsr() $ GetNewPar("BF_USAVEN4","000000")
			cVend := SA1->A1_VEND4
		Else
			// Não sendo Wynns/Michelin verifica se o gatilho é para atualizar Vendedor 1 ou 3 
			If lIsVend03
				cVend	:= SA1->A1_VEND03
			Else
				cVend 	:= SA1->A1_VEND	
			Endif		
		Endif
		
		If lUseSUA 
			If M->UA_CONDPG <> SA1->A1_COND
				M->UA_CONDPG	:= SA1->A1_COND
			Endif
		Endif
					
		If !lIsVend03 
			
			// Adicionado em 16/01/2013 para montar informação de segmentação de negócio e tipo de vendedor
			DbSelectarea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3")+cVend)
				// Atualiza atendimento ou pedido, com informação do segmento de negocio e tipo de vendedor
				If lUseSUA
					M->UA_XEMPFXC	:= SA3->A3_XSEGEMP+SA3->A3_XTPVEND
				Else
					M->C5_XEMPFXC	:= SA3->A3_XSEGEMP+SA3->A3_XTPVEND
				Endif
			Endif
		Endif
	Endif
	
	RestArea(aAreaOld)
	
Return(cVend)


