#include "rwmake.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F100TOK   ºAutor  ³Microsiga           º Data ³  04/25/06   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³  Ponto de entrada para validar amarracao de centro de      º±±
±±º          ³  custo X conta contabil no movim. bancario a pagar (SE5)   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function F100TOK()

	cContaD  := M->E5_DEBITO
	cCCD     := M->E5_CCD
	cItemD   := M->E5_ITEMD
	cClvlD   := M->E5_CLVLDB

	cContaC  := M->E5_CREDITO
	cCCC     := M->E5_CCC
	cItemC   := M->E5_ITEMC
	cClvlC   := M->E5_CLVLCR

	cContab  := M->E5_CONTAB
	cTp      := M->E5_TIPOLAN

//Alert("TP: " + cTp + "Contab: " + cContab)
	lRet := .T.

	IF cContab == "1"
		if cTp == "C"
			if EMPTY(cContaC)
				lRet := .F.
				MsgStop('A Conta Contábil Credito deve ser preenchida.')
			endif

			IF lRet  //Verifica se as amarracoes entre C'onta Contabil  e Centro de Custo sao permitidas conforme cadastro de Amarracoes do CTB
				lRet := CtbAmarra(cContaC,cCCC,cItemC,cClvlC,.T.)
			EndIf
			IF lRet //Verifica se a conta aceita CC ou se o CC eh obrigatorio para a Conta Contabil conforme cadastro de plano de Contas.
				lRet := CtbObrig(cContaC,cCCC,cItemC,cClvlC,.T.)
			EndIf
		ENDIF

		if cTp == "D"
			if EMPTY(cContaD)
				lRet := .F.
				MsgStop('A Conta Contábil Debito deve ser preenchida.')
			endif

			IF lRet  //Verifica se as amarracoes entre C'onta Contabil  e Centro de Custo sao permitidas conforme cadastro de Amarracoes do CTB
				lRet := CtbAmarra(cContaD,cCCD,cItemD,cClvlD,.T.)
			EndIf
			IF lRet //Verifica se a conta aceita CC ou se o CC eh obrigatorio para a Conta Contabil conforme cadastro de plano de Contas.
				lRet := CtbObrig(cContaC,cCCD,cItemD,cClvlD,.T.)
			EndIf
		ENDIF

	Endif

Return (lRet)
