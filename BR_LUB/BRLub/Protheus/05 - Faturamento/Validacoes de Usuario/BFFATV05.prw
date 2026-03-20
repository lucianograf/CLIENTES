#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} BFFATV05
// Função para validação de e-mail dos campos do cadastro de clinete e outras entidades
@author Marcelo Alberto Lauschner
@since 02/08/2019
@version 1.0
@return lRet , Logical
@type function 
/*/
User Function BFFATV05()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .T.
	Local	aRetAux		:= {}
	Local	cRetEmail	:= ""
	Local	nX
	Local	nTmEmail	:= TamSX3("A1_EMAIL")[1]
	Local	nTmRef		:= Iif(cEmpAnt == "02",TamSX3("A1_REFCOM3")[1],0)

	If nTmRef > 0 .And. ReadVar() == "M->A1_REFCOM3"
		aRetAux		:= StrTokArr( Alltrim(M->A1_REFCOM3) + ";",";")
		For nX := 1 To Len(aRetAux)
			If U_GMTMKM01(Lower(Alltrim(aRetAux[nX])),"",M->A1_MSBLQL,/*lValdAlcada*/,/*lExibeAlerta*/,/*cInTxtPad*/)
				If Len(cRetEmail) + Len(Alltrim(aRetAux[nX]+";")) <= nTmRef
					If !Empty(cRetEmail)
						cRetEmail	+= ";"
					Endif
					cRetEmail	+= Lower(Alltrim(aRetAux[nX]))
				Endif
			Endif
		Next
		M->A1_REFCOM3	:= Padr(cRetEmail,nTmRef)
		lRet	:= .T.
	ElseIf ReadVar() == "M->A1_EMAIL"
		aRetAux		:= StrTokArr( Alltrim(M->A1_EMAIL) + ";",";")
		For nX := 1 To Len(aRetAux)
			If U_GMTMKM01(Lower(Alltrim(aRetAux[nX])),"",M->A1_MSBLQL,/*lValdAlcada*/,/*lExibeAlerta*/,/*cInTxtPad*/)

				If Len(cRetEmail) + Len(Alltrim(aRetAux[nX]+";")) <= nTmEmail
					If !Empty(cRetEmail)
						cRetEmail	+= ";"
					Endif
					cRetEmail	+= Lower(Alltrim(aRetAux[nX]))
				Endif
			Endif
		Next
		M->A1_EMAIL	:= Padr(cRetEmail,nTmEmail)
		lRet	:= .T.
	Endif

	RestArea(aAreaOld)

Return lRet
