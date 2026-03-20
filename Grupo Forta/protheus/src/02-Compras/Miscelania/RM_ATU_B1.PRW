#include "totvs.ch"
#include "protheus.ch"

/*/{Protheus.doc} xATU_SB1
Rotina para importar dados de produtos e atualizar SB1 e SB5 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/09/2022
@return variant, return_description
/*/
User Function xATU_SB1()

	Local cArq    	:= "c:\temp\sb1.txt"
	Local cLinha  	:= ""
	Local lPrim   	:= .T.
	Local aCampos 	:= {}
	Local aDados  	:= {}
	Local j,i
	Local aDadosSB1 := {}
	Local aDadosSB5 := {}
	Local lTemSB5 	:= .F.

	Private aErro := {}

	If !File(cArq)
		MsgStop("O arquivo "+ cArq + " não foi encontrado. A importação será abortada!","[ATU_SB1] - ATENCAO")
		Return
	EndIf

	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()

		IncProc("Lendo arquivo texto...")

		cLinha := FT_FREADLN()

		If lPrim
			aCampos := Separa(cLinha,";",.T.)
			lPrim := .F.
		Else
			AADD(aDados,Separa(StrTran(StrTran(cLinha,".",""),",","."),";",.T.))
		EndIf

		FT_FSKIP()
	EndDo

	Begin Transaction
		ProcRegua(Len(aDados))
		For i:=1 to Len(aDados)

			IncProc("Importando Produtos...")
			aDadosSB1 := {}
			aDadosSB5 := {}
			lTemSB5 	:= .F.

			dbSelectArea("SB1")
			dbSetOrder(1)
			If dbSeek(xFilial("SB1")+aDados[i,1])

				For j := 2 to Len(aCampos) // Pesquisa a partir da segunda coluna - pois a primeira sempre terá fixo o código do produto B1_COD
					If Substr(aCampos[j],1,3) == "B5_" // Se for um campo da SB5
						Aadd(aDadosSB5,{aCampos[j],aDados[i,j]})
						lTemSB5 	:= .T.
					ElseIf  Substr(aCampos[j],1,3) == "B1_" // Se for um campo da SB1
						Aadd(aDadosSB1,{aCampos[j],aDados[i,j]})
					Endif
				Next j

				sfGrvSB1(aDadosSB1) // Grava os dados da SB1

				// Set teve campos da SB5 na planilha - grava SB5
				If lTemSB5
					sfGrvSB5(SB1->B1_COD,aDadosSB5)
				Endif

			EndIf
		Next i
	End Transaction

	FT_FUSE()

	ApMsgInfo("Importação dos Produtos concluída com sucesso!","[ATU_SB1] - SUCESSO")

Return

/*/{Protheus.doc} sfGrvSB1
Função para atualizar o cadastro do produto conforme campos recebidos do CSV 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/09/2022
@param aIndadSB1, array, param_description
@return variant, return_description
/*/
Static Function sfGrvSB1(aIndadSB1)

	Local 	i

	Begin Transaction
		// SB1 já está posicionado
		dbSelectArea("SB1")
		dbSetOrder(1)
		Reclock("SB1",.F.)
		For i := 1 To Len(aIndadSB1)
			cCampo  := "SB1->" + aIndadSB1[i,1]
			If GetSx3Cache(aIndadSB1[i,1],"X3_TIPO") == "N"
				&cCampo := Val(aIndadSB1[i,2])
			ElseIf GetSx3Cache(aIndadSB1[i,1],"X3_TIPO") == "D"
				&cCampo := STOD(aIndadSB1[i,2])
			Else
				&cCampo := aIndadSB1[i,2]
			Endif
		Next i
		SB1->(MsUnlock())

	End Transaction

Return

/*/{Protheus.doc} sfGrvSB5
Função para atualizar ou criar registro na SB5 conforme campos recebidos no CSV 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/09/2022
@param cInCod, character, param_description
@param aIndadSB5, array, param_description
@return variant, return_description
/*/
Static Function sfGrvSB5(cInCod,aIndadSB5)

	Local 	i

	Begin Transaction


		// SB1 já está posicionado
		dbSelectArea("SB5")
		dbSetOrder(1)
		If DbSeek(xFilial("SB5")+cInCod)
			Reclock("SB5",.F.)
		Else
			Reclock("SB5",.T.)
			SB5->B5_FILIAL 	:= xFilial("SB5") // se não existir o registro ainda, atualiza o campo da Filial
			SB5->B5_COD 	:= cInCod
		Endif

		For i := 1 To Len(aIndadSB5)
			cCampo  := "SB5->" + aIndadSB5[i,1]
			If GetSx3Cache(aIndadSB5[i,1],"X3_TIPO") == "N"
				&cCampo := Val(aIndadSB5[i,2])
			ElseIf GetSx3Cache(aIndadSB5[i,1],"X3_TIPO") == "D"
				&cCampo := STOD(aIndadSB5[i,2])
			Else
				&cCampo := aIndadSB5[i,2]
			Endif
		Next i
		SB5->(MsUnlock())

	End Transaction

Return
