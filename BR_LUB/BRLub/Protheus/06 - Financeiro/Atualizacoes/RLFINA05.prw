#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} RLFINA05
(long_description)
	
@author MarceloLauschner
@since 09/12/2013
@version 1.0		

@return logico

@example
(examples)

@see (links_or_references)
/*/
User Function RLFINA05()

	Local	lRet		:= .F.
	Local	aRetSE2	:= {}
	
	If !oMulti:aCols[oMulti:nAt,Len(oMulti:aHeader)+1]
		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+oMulti:aCols[oMulti:nAt,nPxPREFIXO]+oMulti:aCols[oMulti:nAt,nPxNUM]+oMulti:aCols[oMulti:nAt,nPxPARCELA]+oMulti:aCols[oMulti:nAt,nPxTIPO]+oMulti:aCols[oMulti:nAt,nPxFORNECE]+oMulti:aCols[oMulti:nAt,nPxLOJA])
			If VldCodBar(oMulti:aCols[oMulti:nAt,nPxCODBAR])
				aRetSE2	:= U_CodBar(oMulti:aCols[oMulti:nAt,nPxCODBAR])
				If aRetSE2[1]
					lRet	:= .T.
					oMulti:aCols[oMulti:nAt,nPxCODBAR]	:= aRetSE2[4]
				Else
					MsgAlert("O código de barras informado não foi validado!","Dados incorretos 'U_CodBar'")
				Endif
			Else
				MsgAlert("O código de barras informado não é válido!","Dados incorretos 'VldCodBar'")
			Endif
		Else
			MsgAlert("Não existe título com os dados informados!","Sem registro")
		Endif
	Else
		lRet	:= .T.
	Endif
	
Return lRet
	
