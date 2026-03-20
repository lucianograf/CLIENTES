#include "rwmake.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FA050INC  ºAutor  ³Microsiga           º Data ³  04/25/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³  Ponto de entrada para validar amarracao de                º±±
±±º          ³  centro de custo X conta contabil no CONTAS A PAGAR (SE2)  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function FA050INC()

	cContaC := M->E2_CONTAD
	cCC     := M->E2_CCD
	cItemC  := M->E2_ITEMD
	cClvl   := M->E2_CLVLDB
	cRateio := M->E2_RATEIO
	cContab := M->E2_CONTAB

	lRet := .T.

	If cContab == "1"

		if EMPTY(cContaC).and.cRATEIO=="N"
			lRet := .F.
			MsgStop('A Conta Contábil deve ser preenchida.')
		endif

		If cRATEIO =="N"
			IF lRet  //Verifica se as amarracoes entre C'onta Contabil  e Centro de Custo sao permitidas conforme cadastro de Amarracoes do CTB
				lRet := CtbAmarra(cContaC,cCC,cItemC,cClvl,.T.)
			EndIf
			IF lRet //Verifica se a conta aceita CC ou se o CC eh obrigatorio para a Conta Contabil conforme cadastro de plano de Contas.
				lRet := CtbObrig(cContaC,cCC,cItemC,cClvl,.T.)
			EndIf
		EndIf
	Endif 

Return (lRet)
