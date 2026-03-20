#Include 'Protheus.ch'


/*/{Protheus.doc} BFCFGA04
(Função que valida o campo CEP no cadastro de clientes/vendedores/transportadoras/fornecedores)
@type function
@author marce
@since 26/04/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCFGA04(cInCPO)

	Local	lRet		:= .T.
	Private	lExistPAB	:= .F.
	Default	cInCPO		:= ReadVar()

	DbSelectArea("SX2")
	DbSetOrder(1) // X2_CHAVE
	If DbSeek("PAB")
		lExistPAB	:= .T.
	Endif
	// Sequencia de array
	// 1- Endereço
	// 2- Bairro
	// 3- Municipio
	// 4- Estado
	// 5- Código Ibge
	// 6- Código Municipio CC2
	// 7- Complemento
	// 8- CEP
	// 9- Código Transportadora 

	If cInCPO == "M->A1_CEP"
		MsAguarde({||  lRet	:=	sfCep(M->A1_CEP,{"M->A1_END","M->A1_BAIRRO","M->A1_MUN","M->A1_EST","M->A1_IBGE","M->A1_COD_MUN","M->A1_COMPLEM","","M->A1_TRANSP"},;
			{"M->A1_ENDCOB","M->A1_BAIRROC","M->A1_MUNC","M->A1_ESTC","","","","A1_CEPC"},;
			{"M->A1_ENDENT","M->A1_BAIRROE","M->A1_MUNE","M->A1_ESTE","","","","M->A1_CEPE"})},;
			"Aguarde!", "Aguarde a localização dos dados informados!")
	ElseIf cInCPO == "M->A2_CEP"
		MsAguarde({||  lRet	:=	sfCep(M->A2_CEP,{"M->A2_END","M->A2_BAIRRO","M->A2_MUN","M->A2_EST","M->A2_IBGE","M->A2_COD_MUN","M->A2_COMPLEM","",""})},;
			"Aguarde!", "Aguarde a localização dos dados informados!")

	Endif

Return lRet



Static Function sfCep(cCep,aArray,aArray2,aArray3)

	Local	aAreaOld	:= GetArea()
	Local	cUrlGet		:= "http://viacep.com.br/ws/"+ Alltrim(StrTran(cCep,"-","")) + "/piped"
	Local	cCepRet		:= ""
	Local	aCepRet		:= {}
	Local	nZ
	Local	nPosAux		:= 0
	Local	cVarAux		:= ""
	Local	cQry		:= ""
	Local	cNxAlias	:= GetNextAlias()
	Local	lGrava		:= .F.
	Local	cMensagem	:= ""
	Local	cRecebe		:= ""
	Local	cAssunto	:= ""
	Local	lSendMail	:= .F.
	Default	aArray		:= {"","","","","","","","",""}
	Default	aArray2		:= {"","","","","","","",""}
	Default	aArray3		:= {"","","","","","","",""}

	//cep:89066-000|logradouro:Rua Doutor Pedro Zimmermann|complemento:de 1452 a 2600 - lado par|bairro:Itoupavazinha|localidade:Blumenau|uf:SC|unidade:|ibge:4202404|gia:

	//cCepRet	:= HttpGet(cUrlGet)
	//HTTPSGet( < cURL >, < cCertificate >, < cPrivKey >, < cPassword >, [ cGETParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderRet ], [ lClient ] )
	cCepRet := HTTPGet( cUrlGet )


	//MsgAlert(cUrlGet + "|" + cCepRet)

	If Substr(cCep,6,3) $ "899#"
		// Força pegar o CEP da Agência dos correios da Cidade
		If (Empty(cCepRet) .Or. "erro:true" $ cCepRet .Or. Empty(cCep))
			cCepRet := HTTPGet( "http://viacep.com.br/ws/"+ Alltrim(StrTran(Substr(cCep,1,5)+"970","-","")) + "/piped" )
			cCepRet	:= StrTran(cCepRet,"-970","-899")
			cCepRet	:= StrTran(cCepRet,"logradouro:","lgrd:")
		Endif
	ElseIf (Empty(cCepRet) .Or. "erro:true" $ cCepRet .Or. Empty(cCep))

		MsgInfo("Código de Endereçamento Postal '" + cCep + "' informado não existe na Base dos Correios! Favor Verifique'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

		If lExistPAB
			DbSelectArea("PAB")
			DbSetOrder(1)

			If dbSeek( xFilial("PAB") + cCep )
				RecLock("PAB",.F.)
				DbDelete()
				MsUnlock()
			Endif
		Endif
		Return .F.
	Endif
	cCepRet	:= sfDecodeUtf(cCepRet)
	cCepRet	:= sfNoAcento(cCepRet)

	aCepRet	:= StrTokArr(cCepRet,"|")

	If Len(aCepRet) < 8

		MsgInfo("Código de Endereçamento Postal '" + cCep + "' informado não existe na Base dos Correios! Favor Verifique'" + CRLF + cCepRet,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

		Return .F.
	Endif

	If lExistPAB



		DbSelectArea("PAB")
		DbSetOrder(1)
		If dbSeek( xFilial("PAB") + cCep )
			lGrava	:= .F.
		Else
			lGrava	:= .T.
		Endif

		DbSelectArea("PAB")
		RecLock("PAB",lGrava)

		For nZ 	:= 1 To Len(aCepRet)
			nPosAux	:= At(":",aCepRet[nZ])
			cVarAux	:= Upper(Substr(aCepRet[nZ],nPosAux+1))

			If "cep:" $ aCepRet[nZ]
				cVarAux	:= StrTran(cVarAux,"-","")
				PAB->PAB_CEP	:= AllTrim(cVarAux)
				If !Empty(aArray[8])
					&(aArray[8])    := PadR(AllTrim(cVarAux),Len(&(aArray[8])))
				Endif
				If !Empty(aArray2[8])
					&(aArray2[8])    := PadR(AllTrim(cVarAux),Len(&(aArray2[8])))
				Endif
				If !Empty(aArray3[8])
					&(aArray3[8])    := PadR(AllTrim(cVarAux),Len(&(aArray3[8])))
				Endif
			ElseIf "logradouro:" $ aCepRet[nZ]
				PAB->PAB_END	:= AllTrim(cVarAux)
				If !Empty(aArray[1])
					&(aArray[1])    := IIF(Empty(&(aArray[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray[1]))),&(aArray[1]))
				Endif
				If !Empty(aArray2[1])
					&(aArray2[1])    := IIF(Empty(&(aArray2[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray2[1]))),&(aArray2[1]))
				Endif
				If !Empty(aArray3[1])
					&(aArray3[1])    := IIF(Empty(&(aArray3[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray3[1]))),&(aArray3[1]))
				Endif
			ElseIf "complemento:" $ aCepRet[nZ]
				PAB->PAB_LOGRAD	:= AllTrim(cVarAux)
				If !Empty(aArray[7])
					&(aArray[7])    := IIF(Empty(&(aArray[7])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray[7]))),&(aArray[7]))
				Endif
				If !Empty(aArray2[7])
					&(aArray2[7])    := IIF(Empty(&(aArray2[7])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray2[7]))),&(aArray2[7]))
				Endif
				If !Empty(aArray3[7])
					&(aArray3[7])    := IIF(Empty(&(aArray3[7])) .Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray3[7]))),&(aArray3[7]))
				Endif
			ElseIf "bairro:" $ aCepRet[nZ]
				PAB->PAB_BAIINI	:= AllTrim(cVarAux)
				If !Empty(aArray[2])
					&(aArray[2])    := IIF(Empty(&(aArray[2])) .Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray[2]))),&(aArray[2]))
				Endif
				If !Empty(aArray2[2])
					&(aArray2[2])    := IIF(Empty(&(aArray2[2])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray2[2]))),&(aArray2[2]))
				Endif
				If !Empty(aArray3[2])
					&(aArray3[2])    := IIF(Empty(&(aArray3[2])).Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray3[2]))),&(aArray3[2]))
				Endif
			ElseIf "localidade:" $ aCepRet[nZ]
				PAB->PAB_MUN	:= AllTrim(cVarAux)
				If !Empty(aArray[3])
					&(aArray[3])    := PadR(AllTrim(cVarAux),Len(&(aArray[3])))
				Endif
				If !Empty(aArray2[3])
					&(aArray2[3])    := PadR(AllTrim(cVarAux),Len(&(aArray2[3])))
				Endif
				If !Empty(aArray3[3])
					&(aArray3[3])    := PadR(AllTrim(cVarAux),Len(&(aArray3[3])))
				Endif
			ElseIf "uf:" $ aCepRet[nZ]
				PAB->PAB_UF		:= AllTrim(cVarAux)
				If !Empty(aArray[4])
					&(aArray[4])    := PadR(AllTrim(cVarAux),Len(&(aArray[4])))
				Endif
				If !Empty(aArray2[4])
					&(aArray2[4])    := PadR(AllTrim(cVarAux),Len(&(aArray2[4])))
				Endif
				If !Empty(aArray3[4])
					&(aArray3[4])    := PadR(AllTrim(cVarAux),Len(&(aArray3[4])))
				Endif
			ElseIf "unidade:" $ aCepRet[nZ]

			ElseIf "ibge:" $ aCepRet[nZ]
				PAB->PAB_IBGE	:= AllTrim(cVarAux)
				If !Empty(aArray[5])
					&(aArray[5])    := PadR(AllTrim(cVarAux),Len(&(aArray[5])))
				Endif
				If !Empty(aArray[6])
					// Verifica se o Munícipio está cadastrado
					DbSelectArea("CC2")
					DbSetOrder(1)
					If DbSeek(xFilial("CC2")+&(aArray[4])+ Substr(cVarAux,3))
						&(aArray[6])    := PadR(AllTrim(Substr(cVarAux,3)),Len(&(aArray[6])))
					Else
						cRecebe		:= "marcelo@centralxml.com.br"
						cAssunto	:= "Cadastro de Municipios "+Substr(cVarAux,3)+" inexistente. Cidade "+ &(aArray[3])
						cMensagem	:= "Cadastro de Municipios "+Substr(cVarAux,3)+" inexistente. Cidade "+ &(aArray[3])
						MsgAlert(cMensagem, ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						sfSendMail( cRecebe, cAssunto, cMensagem, .F./*lExibSend*/, /*cArqAttAch*/, /*cAttachName*/ )
					Endif
				Endif
			Endif
		Next Nz
		// Se for inclusão - força ajuste de codificação Sequencial
		If lGrava
			PAB->PAB_CODSEQ	:= GETSX8NUM("PAB","PAB_CODSEQ")
			If __lSx8
				ConfirmSX8()
			Endif
		Endif

		MsUnlock()

		If lGrava
			cQry := "SELECT PAB_FILIAL,PAB_MUN,PAB_ROTA,PAB_TRANSP,PAB_PRAZO,PAB_UF
			cQry += "  FROM " + RetSqlName("PAB")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND PAB_MUN = '" + StrTran(PAB->PAB_MUN,"'","''") + "'"
			cQry += "   AND PAB_UF = '" + PAB->PAB_UF + "'"
			cQry += "   AND PAB_FILIAL = '" + xFilial("PAB") +"'"
			cQry += "   AND PAB_ROTA != ' ' "
			cQry += "   AND PAB_TRANSP != '  ' "
			cQry += "   AND PAB_CEP != '" + PAB->PAB_CEP+ "'" // Não considera o próprio CEP na validação
			cQry += " GROUP BY PAB_FILIAL,PAB_ROTA,PAB_TRANSP,PAB_PRAZO,PAB_UF,PAB_MUN "
			cQry += " ORDER BY PAB_MUN,PAB_UF"

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),cNxAlias, .F., .T.)

			If !Eof()
				DbSelectArea("PAB")
				RecLock("PAB",.F.)
				PAB->PAB_ROTA	:= (cNxAlias)->PAB_ROTA
				PAB->PAB_TRANSP	:= (cNxAlias)->PAB_TRANSP
				PAB->PAB_PRAZO	:= (cNxAlias)->PAB_PRAZO
				MsUnlock()
			Endif
			(cNxAlias)->(DbCloseArea())
		Endif

		If cEmpAnt+cFilAnt == "0201" // sc
			cRecebe	:= "expedicaosc4@atrialub.com.br"
		Elseif cEmpAnt+cFilAnt == "0204"
			cRecebe	:= "expedicaosc3@atrialub.com.br"
		Elseif cEmpAnt+cFilAnt == "0204"
			cRecebe	:= "expedicaosc3@atrialub.com.br"
		Elseif cEmpAnt+cFilAnt == "0205"
			cRecebe	:= "faturamentors1@atrialub.com.br"
		Elseif cEmpAnt+cFilAnt == "0207"
			cRecebe	:= "expedicaosc1@atrialub.com.br"
		Elseif cEmpAnt+cFilAnt == "0208"
			cRecebe	:= "faturamentomg1@atrialub.com.br"
		Elseif cEmpAnt+cFilAnt == "0209"
			cRecebe	:= "expedicaosc1@atrialub.com.br"
		Endif

		cAssunto	:= "Cadastro de CEP "+PAB->PAB_CEP+" incompleto. Cidade "+ PAB->PAB_MUN
		cMensagem	+= "Cadastro de CEP "+PAB->PAB_CEP+" incompleto."+CRLF
		cMensagem	+= "Cidade '" + PAB->PAB_UF + "/" + Alltrim(PAB->PAB_MUN)+ "'!"+CRLF

		If Empty(PAB->PAB_ROTA)
			cMensagem 	+= "Sem informação de Rota!"+CRLF
			lSendMail	:= .T.
		Endif

		If Empty(PAB->PAB_TRANSP)
			cMensagem	+= "Sem informação de Transportadora!"+CRLF
			lSendMail	:= .T.
		Else
			If !Empty(aArray[9]) // Transportadora 
				&(aArray[9])    := PadR(AllTrim(PAB->PAB_TRANSP),Len(&(aArray[9])))
			Endif
		Endif

		If Empty(PAB->PAB_PRAZO)
			cMensagem	+= "Sem informação de Prazo de Entrega!"+CRLF
			lSendMail	:= .T.
		Endif

		If lSendMail
			MsgAlert(cMensagem, ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			sfSendMail( cRecebe, cAssunto, cMensagem, .F./*lExibSend*/, /*cArqAttAch*/, /*cAttachName*/ )
		Endif

	Else
		For nZ 	:= 1 To Len(aCepRet)
			nPosAux	:= At(":",aCepRet[nZ])
			cVarAux	:= Upper(Substr(aCepRet[nZ],nPosAux+1))

			If "cep:" $ aCepRet[nZ]
				cVarAux	:= StrTran(cVarAux,"-","")
				If !Empty(aArray[8])
					&(aArray[8])    := PadR(AllTrim(cVarAux),Len(&(aArray[8])))
				Endif
				If !Empty(aArray2[8])
					&(aArray2[8])    := PadR(AllTrim(cVarAux),Len(&(aArray2[8])))
				Endif
				If !Empty(aArray3[8])
					&(aArray3[8])    := PadR(AllTrim(cVarAux),Len(&(aArray3[8])))
				Endif
			ElseIf "logradouro:" $ aCepRet[nZ]
				If !Empty(aArray[1])
					&(aArray[1])    := IIF(Empty(&(aArray[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray[1]))),&(aArray[1]))
				Endif
				If !Empty(aArray2[1])
					&(aArray2[1])    := IIF(Empty(&(aArray2[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray2[1]))),&(aArray2[1]))
				Endif
				If !Empty(aArray3[1])
					&(aArray3[1])    := IIF(Empty(&(aArray3[1])).Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray3[1]))),&(aArray3[1]))
				Endif
			ElseIf "complemento:" $ aCepRet[nZ]
				If !Empty(aArray[7])
					&(aArray[7])    := IIF(Empty(&(aArray[7])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray[7]))),&(aArray[7]))
				Endif
				If !Empty(aArray2[7])
					&(aArray2[7])    := IIF(Empty(&(aArray2[7])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray2[7]))),&(aArray2[7]))
				Endif
				If !Empty(aArray3[7])
					&(aArray3[7])    := IIF(Empty(&(aArray3[7])) .Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray3[7]))),&(aArray3[7]))
				Endif
			ElseIf "bairro:" $ aCepRet[nZ]
				If !Empty(aArray[2])
					&(aArray[2])    := IIF(Empty(&(aArray[2])) .Or. !Empty(cVarAux),PadR(AllTrim(cVarAux),Len(&(aArray[2]))),&(aArray[2]))
				Endif
				If !Empty(aArray2[2])
					&(aArray2[2])    := IIF(Empty(&(aArray2[2])) .Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray2[2]))),&(aArray2[2]))
				Endif
				If !Empty(aArray3[2])
					&(aArray3[2])    := IIF(Empty(&(aArray3[2])).Or. !Empty(cVarAux) ,PadR(AllTrim(cVarAux),Len(&(aArray3[2]))),&(aArray3[2]))
				Endif
			ElseIf "localidade:" $ aCepRet[nZ]
				If !Empty(aArray[3])
					&(aArray[3])    := PadR(AllTrim(cVarAux),Len(&(aArray[3])))
				Endif
				If !Empty(aArray2[3])
					&(aArray2[3])    := PadR(AllTrim(cVarAux),Len(&(aArray2[3])))
				Endif
				If !Empty(aArray3[3])
					&(aArray3[3])    := PadR(AllTrim(cVarAux),Len(&(aArray3[3])))
				Endif
			ElseIf "uf:" $ aCepRet[nZ]
				If !Empty(aArray[4])
					&(aArray[4])    := PadR(AllTrim(cVarAux),Len(&(aArray[4])))
				Endif
				If !Empty(aArray2[4])
					&(aArray2[4])    := PadR(AllTrim(cVarAux),Len(&(aArray2[4])))
				Endif
				If !Empty(aArray3[4])
					&(aArray3[4])    := PadR(AllTrim(cVarAux),Len(&(aArray3[4])))
				Endif
			ElseIf "unidade:" $ aCepRet[nZ]

			ElseIf "ibge:" $ aCepRet[nZ]
				If !Empty(aArray[5])
					&(aArray[5])    := PadR(AllTrim(cVarAux),Len(&(aArray[5])))
				Endif
				If !Empty(aArray[6])
					// Verifica se o Munícipio está cadastrado
					DbSelectArea("CC2")
					DbSetOrder(1)
					If DbSeek(xFilial("CC2")+&(aArray[4])+ Substr(cVarAux,3))
						&(aArray[6])    := PadR(AllTrim(Substr(cVarAux,3)),Len(&(aArray[6])))
					Else
						cRecebe		:= "marcelo@centralxml.com.br"
						cAssunto	:= "Cadastro de Municipios "+Substr(cVarAux,3)+" inexistente. Cidade "+ &(aArray[3])
						cMensagem	:= "Cadastro de Municipios "+Substr(cVarAux,3)+" inexistente. Cidade "+ &(aArray[3])
						MsgAlert(cMensagem, ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						sfSendMail( cRecebe, cAssunto, cMensagem, .F./*lExibSend*/, /*cArqAttAch*/, /*cAttachName*/ )
					Endif
				Endif
			Endif
		Next Nz
	Endif

	RestArea(aAreaOld)

Return .T.


Static Function sfNoAcento(cString)

	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÏÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ"
	Local cTio   := "ãõÃÕ"
	Local cCecid := "çÇ"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"



	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cAgudo)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCircu)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cTrema)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCrase)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr("aoAO",nY,1),cTio)
				cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf
		Endif
	Next

	If cMaior$ cString
		cString := strTran( cString, cMaior, "" )
	EndIf
	If cMenor$ cString
		cString := strTran( cString, cMenor, "" )
	EndIf

	cString := StrTran( cString, CRLF, " " )

	For nX:=1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		If (Asc(cChar) < 32 .Or. Asc(cChar) > 123) .and. !cChar $ '|'
			cString:=StrTran(cString,cChar,".")
		Endif
	Next nX
Return cString

Static Function sfDecodeUtf(xString)
	//cep:89041-003|logradouro:Rua General OsÃ³rio|complemento:de 751 a 1799 - lado Ã­mpar|bairro:Velha|localidade:Blumenau|uf:SC|unidade:|ibge:4202404|gia:

	Local	cBuffer		:= ""  //Ã‰ Ã€ Ãü Ãë Ãç
	Local	aAcento		:= {"á" , "à", "â", "ã", "ä", "é", "è", "ê", "ë", "í", "ì", "î", "ï", "ó", "ò", "ô", "õ", "ö", "ú", "ù", "û", "ü", "ç","Á", "À", "Â", "Ã", "Ä", "É", "È", "Ê", "Ë" , "Í" ,"Í"			, "Ì" , "Î","Ï" ,"Ó", "Ò" , "Ô", "Õ", "Ö","Ú" ,"Ù" ,"Û", "Ü" ,"Ç"          , "Ç" ,"Á" ,"É" ,"Ç"	 ,"Á"				,"Ã"  ,"Õ" ,"Á"  ," "	}
	Local	aUtf8 		:= {"Ã¡","Ã ","Ã¢","Ã£","Ã¤","Ã©","Ã¨","Ãª","Ã«","Ã­","Ã¬","Ã®","Ã¯","Ã³","Ã²","Ã´","Ãµ","Ã¶","Ãº","Ã¹","Ã»","Ã¼","Ã§","Ã?","Ã€","Ã‚","Ãƒ","Ã„","Ã‰","Ãˆ","ÃŠ","Ã‹","Ã?" ,"Ã"+chr(141), "ÃŒ","ÃŽ","Ã?","Ã“","Ã’","Ã”","Ã•","Ã–","Ãš","Ã™","Ã›","Ãœ","Ç"+Chr(135) , "Ã‡","Ãü","Ãë","Ãç" ,"Ã"+chr(129)+"S"  ,"Ãâ", "Ãò","Ãü",""	}
	Local	iC,iU
	Local	lExistUtf8	:= .F.

	Aadd(aAcento,"É" )
	Aadd(aUtf8  ,"Ã‰")

	Aadd(aAcento,"Á")
	Aadd(aUtf8  ,"Ã" + Chr(129))

	//0xA0 0x20 0x4b 0x4D

	Do Case
	Case ValType(xString) == "C"
		For iC := 1 To Len(xString)
			lExistUtf8		:= .F.
			For iU := 1 To Len(aAcento)
				If Substr(xString,iC,2) == aUtf8[iU]
					cBuffer	+= aAcento[iU]
					lExistUtf8		:= .T.
					iC++ // Acrescenta 1 ao contador por que são 2 caracteres substituidos
				Endif
			Next
			If !lExistUtf8
				cBuffer	+= Substr(xString,iC,1)
			Endif
		Next
	Case ValType(xString) == "N"
		cBuffer	:= Str(xString)
	EndCase
	//If lIsDebug
	//	Aviso(ProcName(1)+ "." + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),cBuffer,{"Ok"},3)
	//Endif

Return cBuffer

//#include "rwmake.ch"        // incluido pelo assistente de conversao do AP6 IDE em 16/05/03

//--------------------------------+
// Favor Documentar alterações.   |
// Data - Analista - Descrição	  |
//--------------------------------+
//-------------------------------------------------------------------------------------------------
// 26/03/2010 - Marcelo Lauschner - Revisão do rdmake
//
//-------------------------------------------------------------------------------------------------


User Function Shellcep()        // incluido pelo assistente de conversao do AP6 IDE em 16/05/03

Return U_BFCFGA04()



Static Function sfSendMail( cRecebe, cAssunto, cMensagem, lExibSend, cArqAttAch, cAttachName )

	Local		aAreaOld	:= GetArea()
	Local		oMessageA1
	Local		oSendSrv
	Local		cCorpoM		:= ""
	Default 	lExibSend	:= .F.
	Default		cArqAttAch	:= ""
	Default		cAttachName	:= ""

	If Empty(cRecebe)
		Return
	Endif

	//Crio a conexão com o server STMP ( Envio de e-mail )
	oSendSrv := TMailManager():New()


	// Usa SSL na conexao
	If GetMv("XM_SMTPSSL")
		oSendSrv:setUseSSL(.T.)
	Endif

	// Usa TLS na conexao
	If GetNewPar("XM_SMTPTLS",.F.)
		oSendSrv:SetUseTLS(.T.)
	Endif

	oSendSrv:Init( ""		,Alltrim(GetMv("XM_SMTP")), Alltrim(GetMv("XM_SMTPUSR"))	,Alltrim(GetMv("XM_PSWSMTP")),	0			, GetMv("XM_SMTPPOR") )

	//seto um tempo de time out com servidor de 1min
	If oSendSrv:SetSmtpTimeOut( GetMv("XM_SMTPTMT") ) != 0
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao setar o time out"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		RestArea(aAreaOld)
		Return .F.
	EndIf

	//realizo a conexão SMTP
	If oSendSrv:SmtpConnect() != 0
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Falha ao conectar"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		RestArea(aAreaOld)
		Return .F.
	EndIf

	// Realiza autenticacao no servidor
	If GetMv("XM_SMTPAUT")
		nErr := oSendSrv:smtpAuth(Alltrim(GetMv("XM_SMTPUSR")), Alltrim(GetMv("XM_PSWSMTP")))
		If nErr <> 0
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "[ERROR]Falha ao autenticar: " + oSendSrv:getErrorString(nErr)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			If lExibSend
				MsgAlert("[ERROR]Falha ao autenticar: " + oSendSrv:getErrorString(nErr),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
			oSendSrv:smtpDisconnect()
			RestArea(aAreaOld)
			Return .F.
		Endif
	Endif
	//Apos a conexão, crio o objeto da mensagem
	oMessageA1 := TMailMessage():New()
	//Limpo o objeto
	oMessageA1:Clear()
	//Populo com os dados de envio
	oMessageA1:cFrom 		:= GetMv("XM_SMTPDES")
	oMessageA1:cTo 			:= cRecebe
	oMessageA1:cSubject 	:= cAssunto
	cMensagem 		:= StrTran(cMensagem,Chr(13)+ Chr(10),"<br>")
	cMensagem		:= StrTran(cMensagem,Chr(13),"<br>")
	cMensagem		:= StrTran(cMensagem,CRLF,"<br>")

	cCorpoM += "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'> "
	cCorpoM += "<html xmlns='www.w3.org/1999/xhtml'> "
	cCorpoM += "<head> "
	cCorpoM += "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1' /> "
	cCorpoM += "<style type='text/css'> "
	cCorpoM += "<!-- "
	cCorpoM += "body,td,th { "
	cCorpoM += "	font-family: Arial, Helvetica, sans-serif; "
	cCorpoM += "	font-size: 12pt; "
	cCorpoM += "} "
	cCorpoM += "--> "
	cCorpoM += "</style></head> "
	cCorpoM += "<body> "
	cCorpoM += "<br>"
	cCorpoM += AllTrim(cMensagem)
	cCorpoM += "<br>"
	cCorpoM += "<br>"
	cCorpoM += "<br>"
	cCorpoM += "<br>"
	cCorpoM += "Este email é disparado automaticamente pela rotina de Cadastro de CEPs - Favor não Responder."
	cCorpoM += "<br>"
	cCorpoM += "________________________________________________________________________"
	cCorpoM += "<br>"


	cCorpoM += "Powered by Atrialub. "
	cCorpoM += "Usuário: " + UsrRetName(RetCodUsr())
	cCorpoM += "<br>"
	cCorpoM += "Data/Hora: "+ DTOC(Date()) + " / " + Time()
	cCorpoM += "Empresa/Filial:" + cEmpAnt+"/" + cFilAnt
	cCorpoM += "<br>"
	cCorpoM += "</body> "
	cCorpoM += "</html>"

	oMessageA1:MsgBodyType( "text/html" )

	oMessageA1:cBody 		:= cCorpoM //cMensagem

	//Adiciono um attach
	If !Empty(cArqAttAch)
		If oMessageA1:AttachFile( cArqAttAch) < 0
			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro ao atachar o arquivo " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			
		Else
			//adiciono uma tag informando que é um attach e o nome do arq
			oMessageA1:AddAtthTag( 'Content-Disposition: attachment; filename='+Alltrim(cAttachName))
		EndIf
	Endif

	//Envio o e-mail
	If oMessageA1:Send( oSendSrv ) != 0
		RestArea(aAreaOld)
		Return .F.
	Else
		If lExibSend
			MsgAlert("Email enviado com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Concluído")
		Endif
	EndIf

	//Disconecto do servidor
	If oSendSrv:SmtpDisconnect() != 0
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro ao disconectar do servidor SMTP"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		RestArea(aAreaOld)
		Return .F.
	EndIf

Return



Static Function St()
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
	//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
	//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
	//³ Incluido pelo assistente de conversao do AP6 IDE                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	SetPrvt("LOKCEP,NCEP,ATELA,M->A1_END,M->A1_ENDCOB,M->A1_ENDENT")
	SetPrvt("LREFRESH,M->A1_CEP,M->A1_CEPCOB,M->A1_CEPENT,M->A1_MUN,M->A1_MUNCOB")
	SetPrvt("M->A1_MUNENT,M->A1_BAIRRO,M->A1_BAICOB,M->A1_BAIENT,M->A1_EST,M->A1_ESTCOB")
	SetPrvt("M->A1_ESTENT,M->A1_LOGRADO,")

	/*/
	ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
	±³Fun‡…o    ³ SHELLCEP ³ Autor ³                       ³ Data ³ 22/09/00 ³±±
	±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
	±³Sintaxe e ³ Void SHELLCEP(void)                                        ³±±
	±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
	±³Descri‡…o ³ Pesquisa de CEP                                            ³±±
	±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
	±³Parametros³                                                            ³±±
	±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
	±³ Uso      ³ SHELL                                                      ³±±
	±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
	±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
	/*/

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	lOkCep:=.F.
	IF READVAR()=="M->A1_END"
		dbSelectArea("PAB")
		dbSetOrder(2)
		If dbSeek( xFilial() + M->A1_END )
			lOkCep:=.T.
		Endif
	ELSEIF READVAR()=="M->A1_CEP"
		dbSelectArea("PAB")
		dbSetOrder(1)
		If dbSeek( xFilial("PAB") + M->A1_CEP )
			lOkCep:=.T.
		Else
			MsgAlert(M->A1_CEP+ " CEP INEXISTENTE NO CADASTRO DE CEPS")
			If !File("ceps_invalidos.txt")
				Memowrite("ceps_invalidos.txt", M->A1_CEP)
			Else
				cTexto := MemoRead("ceps_invalidos.txt")
				cTexto += "','" + M->A1_CEP
				memowrite("ceps_invalidos.txt", cTexto)
			Endif
			Return(.F.)
		Endif
	ENDIF

	If lOkCep
		IF READVAR()=="M->A1_CEP"
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Atualiza o campo de END                                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_END" } )
			If nCep > 0
				aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := PAB_END
			EndIf
			M->A1_END		:= Subs(PAB_LOGRAD,1,3) + " " + PAB_END
			M->A1_ENDCOB 	:= Subs(PAB_LOGRAD,1,3) + " " + PAB_END //Atualiza endereco de cobranca
			M->A1_ENDENT 	:= Subs(PAB_LOGRAD,1,3) + " " + PAB_END	//Atualiza endereco de entrega
			lRefresh:=.T.
		ENDIF
		IF READVAR()=="M->A1_END"
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Atualiza o campo de CEP                                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_CEP" } )
			If nCep > 0
				aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := TransForm(PAB_CEP,"@R 99999-999")
			EndIf
			M->A1_CEP		:= PAB_CEP
			M->A1_CEPCOB	:= PAB_CEP
			M->A1_CEPENT	:= PAB_CEP
			lRefresh		:= .T.
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualiza o campo de CIDADE                                   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_MUN" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := PAB_MUN
		EndIf
		M->A1_MUN		:= PAB_MUN
		M->A1_MUNCOB 	:= PAB_MUN
		M->A1_MUNENT 	:= PAB_MUN
		lRefresh		:= .T.

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualiza o campo de BAIRRO                                   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nCep := Ascan(aGets,{ |x| Subs(x,9,9) == "A1_BAIRRO" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := PAB_BAIINI
		EndIf
		M->A1_BAIRRO	:= PAB_BAIINI
		M->A1_BAICOB	:= PAB_BAIINI //Atualiza bairro de cobranca
		M->A1_BAIENT	:= PAB_BAIINI // Atualiza bairro de entrega
		lRefresh		:= .T.

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualiza o campo de ESTADO                                   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_EST" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := PAB_UF
		EndIf
		M->A1_EST		:= PAB_UF
		M->A1_ESTCOB 	:= PAB_UF
		M->A1_ESTENT 	:= PAB_UF
		lRefresh		:= .T.
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualiza o campo de LOGRADOURO                               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nCep := Ascan(aGets,{ |x| Subs(x,9,10) == "A1_LOGRADO" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := PAB_LOGRADO
		EndIf
		M->A1_LOGRADO	:= PAB_LOGRADO
		lRefresh		:= .T.
	Else
		IF READVAR()!="M->A1_CEP"
			nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_CEP" } )
			If nCep > 0
				aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := Space(8)
			EndIf
		ENDIF
		IF READVAR()!="M->A1_END"
			nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_END" } )
			If nCep > 0
				aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := Space(40)
			EndIf
		ENDIF

		nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_MUN" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := Space(15)
		EndIf

		nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_BAIRRO" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := Space(15)
		EndIf

		nCep := Ascan(aGets,{ |x| Subs(x,9,6) == "A1_EST" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := Space(2)
		EndIf

		nCep := Ascan(aGets,{ |x| Subs(x,9,10) == "A1_LOGRADO" } )
		If nCep > 0
			aTela[Val(Subs(aGets[nCep],1,2))][Val(Subs(aGets[nCep],3,1))*2] := Space(5)
		EndIf

		lRefresh:=.T.
	EndIf

Return(.T.)

