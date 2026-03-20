#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} BFFINA03
(long_description)
	
@author Marcelo Lauschner
@since 09/12/2013
@version 1.0		

@return logico

@example
(examples)

@see (links_or_references)
/*/
User Function RLFINA03()

	Local		lRet	:= .T.

	If ReadVar() == "M->E2CODBAR"

		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+oMulti:aCols[oMulti:nAt,nPxPREFIXO]+oMulti:aCols[oMulti:nAt,nPxNUM]+oMulti:aCols[oMulti:nAt,nPxPARCELA]+oMulti:aCols[oMulti:nAt,nPxTIPO]+oMulti:aCols[oMulti:nAt,nPxFORNECE]+oMulti:aCols[oMulti:nAt,nPxLOJA])
	
			lRet		:= VldCodBar(M->E2CODBAR)
			aRetSE2	:= U_CodBar(M->E2CODBAR)
	
			If lRet .And. aRetSE2[1]
				lRet			:= .T.
				M->E2CODBAR	:= aRetSE2[4]
			// Valida se o valor do título confere com o valor informado no código de barras
				If Round(aRetSE2[3],2) <> Round(oMulti:aCols[oMulti:nAt,nPxVALOR],2)
					MsgAlert("Foi encontrada diferença de valor do título!","Diferença no valor título")
				Endif
			Else
				lRet	:= .F.
			Endif
		Else
	
		Endif
	ElseIf ReadVar() == "M->E2_LOJA"
		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+oMulti:aCols[oMulti:nAt,nPxPREFIXO]+oMulti:aCols[oMulti:nAt,nPxNUM]+oMulti:aCols[oMulti:nAt,nPxPARCELA]+oMulti:aCols[oMulti:nAt,nPxTIPO]+oMulti:aCols[oMulti:nAt,nPxFORNECE]+M->E2_LOJA)
			oMulti:aCols[oMulti:nAt,nPxEMISSAO]	:= SE2->E2_EMISSAO
			oMulti:aCols[oMulti:nAt,nPxVENCORI]	:= SE2->E2_VENCORI
			oMulti:aCols[oMulti:nAt,nPxVENCREA]	:= SE2->E2_VENCREA
			oMulti:aCols[oMulti:nAt,nPxVALOR]		:= SE2->E2_VALOR
			oMulti:aCols[oMulti:nAt,nPxSALDO]		:= SE2->E2_SALDO
			oMulti:aCols[oMulti:nAt,nPxCODBAR]		:= Padr(SE2->E2_CODBAR,48)
		Endif
		//IAGO 22/01/2015 Chamado(10020)
		dbSelectArea("SA2")
		DbSetOrder(1)
		If dbSeek(xFilial("SA2")+oMulti:aCols[oMulti:nAt,nPxFORNECE]+oMulti:aCols[oMulti:nAt,nPxLOJA])
			oMulti:aCols[oMulti:nAt,nPxBANCO] 		:= SA2->A2_BANCO
			oMulti:aCols[oMulti:nAt,nPxAGENCIA] 	:= SA2->A2_AGENCIA
			oMulti:aCols[oMulti:nAt,nPxNUMCON] 	:= SA2->A2_NUMCON
		EndIf
	Endif

Return lRet

