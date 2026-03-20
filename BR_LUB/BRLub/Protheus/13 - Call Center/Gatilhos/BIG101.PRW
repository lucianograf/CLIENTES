#INCLUDE "rwmake.ch"


/*/{Protheus.doc} BIG101
(long_description)
	
@author ODAIR GARCIA AROUCA
@since 21/08/2007
@version 1.0		

@return data,data de faturamento

@example
(examples)

@see (links_or_references)
/*/
User Function BIG101()

	Local 	aAreaOld	:= 	GetArea()
	Local 	cCEP		:=	" "
	Local 	cRota		:=	" "
	Local 	nDiaEnt  	:=	0
	Local 	dData    	:= 	dDataBase
	Local 	aRota    	:= 	{}
	Local	nx			:= 0
	
	dbSelectArea("SA1")
	dbSetOrder(1)
	If MsSeek(xFilial("SA1")+M->UA_CLIENTE+M->UA_LOJA)
		cCEP := SA1->A1_CEP
	
		If SA1->A1_ROTA <> " "
			cRota := SA1->A1_ROTA
		Endif
	
		dbSelectArea("PAB")
		dbSetOrder(1)
		If MsSeek(xFilial("PAB")+cCEP)
			cRota := PAB->PAB_ROTA
		
			For nx := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
				AADD(aRota,{SubStr(PAB->PAB_ROTA,nx,1)})
			Next
		Endif
	
		IF SA1->A1_ROTA <> " "
			For nx := 1 To Len(AllTrim(SA1->A1_ROTA)) Step 1
				AADD(aRota,{SubStr(SA1->A1_ROTA,nx,1)})
			Next
		Endif
	
	Endif

	nDia := Dow(dDatabase)
	If Len(aRota) > 0
		While .T.
			If nDia > 7
				nDia := 1
			Endif
			nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
			If !Empty(nPos)
				nDiaEnt := Val(aRota[nPos][1])
				If nDiaEnt == Dow(dDatabase)
					dData := dDatabase
				Elseif (nDiaEnt - Dow(dDatabase)) > 0
					dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
				Else
					dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
				Endif
				Exit
			Endif
			nDia++
		End
	Endif

	RestArea(aAreaOld)

Return(dData)
