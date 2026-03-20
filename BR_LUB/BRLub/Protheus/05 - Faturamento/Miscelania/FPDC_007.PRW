
/*/{Protheus.doc} FPDC_007
(Rotina para retornar sigla de cidade)
@author MarceloLauschner
@since 02/04/2011
@version 1.0
@param cTipo, character, (Descrição do parâmetro)
@param cCliente, character, (Descrição do parâmetro)
@param cLoja, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function FPDC_007(cTipo,cCliente,cLoja)
	
	Local	aAreaOld	:= GetArea()
	Local	aCidades	:= {}
	Local	cNomfil
	Local	cCodFil
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If !cTipo $ "B#D"
		
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+cCliente+cLoja)
		
		
		DbSelectArea("PAB")
		DbSetOrder(1)
		If dbSeek(xFilial("PAB")+SA1->A1_CEP)
			cNomfil := PAB->PAB_CTRFIL
			cCodFil := PAB->PAB_NTRFIL
			nPosCid	:= 0
			
			// Faço a Tratativa para as cidades Atendidas pela Alirio
			For nX := 1 To Len(aCidades)
				If Alltrim(SA1->A1_MUN) == Alltrim(aCidades[nX])
					nPosCid	:= nX
					Exit
				Endif
			Next
			If nPosCid > 0 
				cCodFil	:= ""
				cNomFil	:= ""
			Endif
		Else
			cNomfil := ""
			cCodFil := ""
		Endif
	Else
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+cCliente+cLoja)
		
		DbSelectArea("PAB")
		DbSetOrder(1)
		If dbSeek(xFilial("PAB")+SA2->A2_CEP)
			cNomfil := PAB->PAB_CTRFIL
			cCodFil := PAB->PAB_NTRFIL
		Else
			cNomfil := ""
			cCodFil := ""
		Endif
	Endif
	
	RestArea(aAreaOld)
	
Return Alltrim(cNomFil + " "+cCodFil)

