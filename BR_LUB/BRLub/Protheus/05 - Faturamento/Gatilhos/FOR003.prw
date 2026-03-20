#INCLUDE "rwmake.ch"

//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 05/04/2010 - Marcelo Lauschner - Codigo Revisado
//
//-------------------------------------------------------------------------------------------------

User Function FOR003

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma ³FOR003 º Autor ³ Leonardo J Koerich Jr  º Data ³  12/09/03   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ verificar data de entrega                                  º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Sigafat                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local 	aAreaOld	:= GetArea()
Local 	cCliente 	:= M->C5_CLIENTE
Local 	cLoja    	:= M->C5_LOJACLI
Local 	cCEP		:=" "
Local 	cRota		:=" "
Local 	nDiaAtu  	:= 0
Local 	nDiaEnt  	:= 0
Local 	dData    	:= dDataBase
Local 	aRota    	:= {}
Local 	aDias    	:= {1,2,3,4,5,6,7}

// Executa gravação do Log de Uso da rotina
U_BFCFGM01()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica da de entrega                                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SA1")
dbSetOrder(1)
If dbSeek(xFilial("SA1")+cCliente+cLoja)
	cCEP := SA1->A1_CEP
	
	IF SA1->A1_ROTA <> " "
		cRota := SA1->A1_ROTA
	Endif
	
	dbSelectArea("PAB")
	dbSetOrder(1)
	If dbSeek(xFilial("PAB")+cCEP)
		cRota := PAB->PAB_ROTA
		
		For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
			AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
		Next
	Endif
	
	IF SA1->A1_ROTA <> " "
		For x := 1 To Len(AllTrim(SA1->A1_ROTA)) Step 1
			AADD(aRota,{SubStr(SA1->A1_ROTA,x,1)})
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
