#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} M440STTS
(Registrar no Z0 a hora de liberação do Pedido   )
	
@author Leonardo J Koerich Jr 
@since 27/11/2003
@version 1.0		

@return Sem retorno esperado

@example
(examples)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784166)
/*/
User Function M440STTS()

	local x := 0 as numeric 
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M440STTS")
		Return .T. 
	Endif
	
	// Grava Log
	U_GMCFGM01("LP",SC5->C5_NUM,"",FunName())

	
	If SC5->C5_DTPROGM < Date() .Or. Empty(SC5->C5_DTPROGM)
	
		cCEP		:=" "
		cRota		:=" "
		nDiaAtu  := 0
		nDiaEnt  := 0
		dData    := dDataBase
		aRota    := {}
		aDias    := {1,2,3,4,5,6,7}
	
		dbSelectArea("SA1")
		dbSetOrder(1)
		If MsSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
			cCEP := SA1->A1_CEP
		
			dbSelectArea("PAB")
			dbSetOrder(1)
			If MsSeek(xFilial("PAB")+cCEP)
				cRota := PAB->PAB_ROTA
				IF SA1->A1_ROTA <> " "
					For x := 1 To Len(AllTrim(SA1->A1_ROTA)) Step 1
						AADD(aRota,{SubStr(SA1->A1_ROTA,x,1)})
					Next
				Else
					For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
						AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
					Next
				Endif
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
		
		DbSelectArea("SC5")
		RecLock("SC5",.F.)
		SC5->C5_DTPROGM   := dData
		MsUnLock()
		
	Endif

Return
