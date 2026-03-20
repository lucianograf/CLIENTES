
#Include 'Totvs.ch'
/*/{Protheus.doc} DCVTXI04
Função para integrar Especificações do Produto 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/05/2024
@param cInCodPro, character, param_description
@param cInIdVtex, character, param_description
@return variant, return_description
/*/
User Function DCVTXI04(cInCodPro,cInIdVtex,nInOpc)

	Local   aConectVtx      := U_DCVTXI01()
	Local   cUrlVtx         := aConectVtx[1]
	Local   aHeadOut        := aConectVtx[2]
	Local   cPath           := "/api/catalog_system/pvt/products/"
	Local   cCorpo1         := ""
	Local   oRestSpec
	Local   lRet            := .F.
	Default nInOPc          := 0
	Default cInIdVtex       := U_DCVTXI03(cInCodPro,2)

	// Cadastrp de Produto
	DbSelectArea("SB1")
	DbSetOrder(1)
	If !MsSeek(xFilial("SB1") + cInCodPro)
		//MsgAlert("Não há produto cadastrado para o código informado '" + cInCodPro + "' ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há produto cadastrado para o código informado '" + cInCodPro + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Ficha Técnica
	DbSelectArea("ZFT")
	DbSetOrder(1) //ZFT_FILIAL+ZFT_COD
	If !MsSeek(xFilial("ZFT") + SB1->B1_ZFT ) .Or. Empty(SB1->B1_ZFT)
		//MsgAlert("Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" , "Não há Ficha Técnica cadastrada para o código informado '" + SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Produtor
	DbSelectArea("Z03")
	DbSetOrder(1) //Z03_FILIAL+Z03_CODIGO
	If !MsSeek(xFilial("Z03") + ZFT->ZFT_PRODUT )  .Or. Empty(ZFT->ZFT_PRODUT)
		//MsgAlert("Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Produtor cadastrado para o código informado '" + ZFT->ZFT_PRODUT  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' ", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Categorias de Uvas
	DbSelectArea("Z04")
	DbSetOrder(1) //Z04_FILIAL+Z04_CODIGO
	If !MsSeek(xFilial("Z03") + ZFT->ZFT_CLASSI )  .Or. Empty(ZFT->ZFT_PRODUT)  //ZFT_CLASSI = Z04_CODIGO
		//MsgAlert("Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há Categoria cadastrada para o código informado '" + ZFT->ZFT_CLASSI  + "' da ficha '"+ SB1->B1_ZFT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	// Cadastro de Países
	DbSelectArea("SYA")
	DbSetOrder(1) //YA_FILIAL+YA_CODGI
	If !MsSeek(xFilial("SYA") + Z03->Z03_PAIS )  .Or. Empty(Z03->Z03_PAIS)  //YA_CODGI = Z03_PAIS
		//MsgAlert("Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		ProcLogAtu( "ERRO" ,"Não há País cadastrado para o código informado '" +Z03->Z03_PAIS + "' do produtor '"+ ZFT->ZFT_PRODUT + "' do produto '" + SB1->B1_COD + "' " , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) ,,.F. )
		Return .F.
	Endif

	If !Empty(cInIdVtex)
		//incluir especificações
		cBody := '['
		cBody += '{"Value": ["'+sfStrTran(Z04->Z04_DESCRI)  +'"],"Id":19,"Name":"Tipo"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_SUSTEN)  +'"],"Id":20,"Name":"Sustentabilidade"},'
		cBody += '{"Value": ["'+sfStrTran(Z03->Z03_APELID)  +'"],"Id":21,"Name":"Produtor"}, '
		cBody += '{"Value": ["'+sfStrTran(SYA->YA_DESCR)    +'"],"Id":22,"Name":"País"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_DTLREG)  +'"],"Id":23,"Name":"Região"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_CASTA)   +'"],"Id":24,"Name":"Uvas"},'

		If ZFT->ZFT_CORPO == 'C'
			cCorpo1     := 'De Corpo'
		ElseIf ZFT->ZFT_CORPO = 'R'
			cCorpo1     := 'Robusto'
		ElseIf ZFT->ZFT_CORPO = 'L'
			cCorpo1     := 'Leve'
		ElseIf ZFT->ZFT_CORPO == '1'
			cCorpo1     :=  'Corpo Leve'
		ElseIf ZFT->ZFT_CORPO == '2'
			cCorpo1     :=  'Corpo Médio'
		ElseIf ZFT->ZFT_CORPO == '3'
			cCorpo1     := 'Encorpado'
		Else
			cCorpo1     := ' '
		Endif

		cBody += '{"Value": ["'+sfStrTran(cCorpo1)          +'"],"Id":25,"Name":"Corpo"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_VOLUME)  +'"],"Id":26,"Name":"Volume da garrafa"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_ALCOOL)  +'"],"Id":27,"Name":"Teor alcoólico"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_HISTOR)  +'"],"Id":28,"Name":"Introdução produtor e região"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_ENOGAS)  +'"],"Id":29,"Name":"Harmonização"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_TEMPER)  +'"],"Id":30,"Name":"Temperatura de serviço"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_GUARDA)  +'"],"Id":31,"Name":"Estimativa de guarda"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_DICAS)   +'"],"Id":32,"Name":"Dica do nosso sommelier"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_INFO)    +'"],"Id":34,"Name":"Informação sobre país, região, uva"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_AMADUR)  +'"],"Id":35,"Name":"Amadurecimento"},'
		cBody += '{"Value": ["'+sfStrTran(Iif(ZFT->ZFT_ROSCA == "2","Não","Sim"))+'"],"Id":36,"Name":"Vedação"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_HISTOR)  +'"],"Id":37,"Name":"Caracteristicas MKT"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_ELABOR)  +'"],"Id":39,"Name":"Elaboração"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_CLIMA)   +'"],"Id":40,"Name":"Característica do clima"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_SOLO)    +'"],"Id":41,"Name":"Características do solo"},'
		cBody += '{"Value": ["'+sfStrTran(ZFT->ZFT_PREMIO)  +'"],"Id":42,"Name":"Premiações"},'
		cBody += '{"Value": ["'+sfStrTran(SB1->B1_SAFRA)    +'"],"Id":43,"Name":"Safra"}'

		If !Empty(ZFT->ZFT_DESCOR) // ZFT_DESCOR	DESCORCHADOS	49	Descorchados (49)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_DESCOR
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_DESCOR', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":49,"Name":"Descorchados"}'
		Endif
		If !Empty(ZFT->ZFT_WINE) // 	ZFT_WINE	WINE ENTHUSIAST	50 Wine Enthusiast (50)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_WINE
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_WINE', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":50,"Name":"Wine Enthusiast"}'
		Endif
		If !Empty(ZFT->ZFT_SPECTA) //ZFT_SPECTA	SPECTATOR	51	Wine Spectator (51)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_SPECTA
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_SPECTA', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":51,"Name":"Wine Spectator"}'
		Endif
		If !Empty(ZFT->ZFT_JANCIS) // ZFT_JANCIS	JANCIS	52			Jancis Robinson (52)
			//01=15;02=15,5;03=16;04=16,5;05=17;06=17,5;07=18;08=18,5;09=19;10=19,5;11=20
			cVarAux 	:= ZFT->ZFT_JANCIS
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_JANCIS', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":52,"Name":"Jancis Robinson"}'
		Endif
		If !Empty(ZFT->ZFT_JAMES) //ZFT_JAMES	JAMES	53		James Suckling (53)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_JAMES
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_JAMES', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":53,"Name":"James Suckling"}'
		Endif
		If !Empty(ZFT->ZFT_PARKER) //ZFT_PARKER	PARKER	54		Robert Parker (54)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_PARKER
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_PARKER', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)

			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":54,"Name":"Robert Parker"}'
		Endif
		If !Empty(ZFT->ZFT_VINOUS) //ZFT_VINOUS	VINOUS	56			Vinous (56)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_VINOUS
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_VINOUS', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":56,"Name":"Vinous"}'
		Endif
		If !Empty(ZFT->ZFT_DECA) //	ZFT_DECA	DECANTER	78		Decanter (78)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_DECA
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_DECA', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":78,"Name":"Decanter"}'
		Endif
		If !Empty(ZFT->ZFT_TIM) // ZFT_TIM	TIM ATKIN	79			Tim Atkin (79)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_TIM
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_TIM', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":79,"Name":"Tim Atkin"}'
		Endif
		If !Empty(ZFT->ZFT_PENIN)  // ZFT_PENIN	PENIN	80			Peñin (80)
			//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100
			cVarAux 	:= ZFT->ZFT_PENIN
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_PENIN', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":80,"Name":"Peñin"}'
		Endif
		If !Empty(ZFT->ZFT_REVIST) // ZFT_REVIST	REVISTA	81			Revista de Vinhos (81)
			//01=15;02=15,5;03=16;04=16,5;05=17;06=17,5;07=18;08=18,5;09=19;10=19,5;11=20
			cVarAux 	:= ZFT->ZFT_REVIST
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_REVIST', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":81,"Name":"Revista de Vinhos"}'
		Endif
		If !Empty(ZFT->ZFT_GRANDE) // ZFT_GRANDE	GRANDES	82			Grandes Escolhas (82)
			//01=15;02=15,5;03=16;04=16,5;05=17;06=17,5;07=18;08=18,5;09=19;10=19,5;11=20
			cVarAux 	:= ZFT->ZFT_GRANDE
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_GRANDE', "X3_CBOX"),,, 2)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":82,"Name":"Grandes Escolhas"}'
		Endif
		If !Empty(ZFT->ZFT_ROSSO) //  ZFT_ROSSO	ROSSO	83			Gambero Rosso (83)
			//1=1_Bicchiere;2=2_Bicchieri;3=2_Bicchieri Rossi;4=3_Bicchieri
			cVarAux 	:= ZFT->ZFT_ROSSO
			aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_ROSSO', "X3_CBOX"),,, 1)
			nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
			cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
			cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":83,"Name":"Gambero Rosso"}'
		Endif
		If !Empty(ZFT->ZFT_ADEGA) //  ZFT_ADEGA	ADEGA	91			Adega (91)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                                   
					cVarAux 	:= ZFT->ZFT_ADEGA
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_ADEGA', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":91,"Name":"Adega"}'
				Endif

		cBody += ']'

		oRestSpec := FWRest():New(cUrlVtx)
		oRestSpec:SetPath(cPath + cInIdVtex + "/specification")
		If nInOpc == 0
			oRestSpec:SetPostParams(EncodeUTF8(cBody, "cp1252"))

			If oRestSpec:Post(aHeadOut)
				//MsgInfo(oRestSpec:GetResult(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				ProcLogAtu( "MENSAGEM" , cUrlVtx + cPath + cInIdVtex + "/specification" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " +DecodeUtf8(oRestSpec:GetResult()),,.F. )
				lRet    := .T.
			Else
				ProcLogAtu( "ERRO" , cUrlVtx + cPath + cInIdVtex + "/specification" , ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " " + oRestSpec:GetLastError(),,.F. )
				//MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
		ElseIf nInOpc == 1
            If oRestSpec:Get(aHeadOut)
		        MsgInfo(DecodeUtf8(oRestSpec:GetResult()),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			    lRet   := .T. 
            Else 
                MsgAlert(oRestSpec:GetLastError(),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			    lRet    := .F.
            Endif 
        Endif
	Endif

Return lRet


/*/{Protheus.doc} sfStrTran
Função para efetuar ajustes de Texto para integração 
@type function
@version  
@author marcelo
@since 01/05/2024
@param cInText, character, param_description
@return variant, return_description
/*/
Static Function sfStrTran(cInText)

	Local 	cOut 	:= cInText

	cOut := StrTran(cOut,Chr(13),"")
	cOut := StrTran(cOut,Chr(10),"")
	cOut := StrTran(cOut,Chr(19),"")
	cOut := StrTran(cOut,'"',"")
	cOut := Alltrim(cOut)

Return cOut
