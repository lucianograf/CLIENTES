#Include 'Protheus.ch'

/*/{Protheus.doc} BFFINA01
(Interface para lançamento de Código de barras de títulos a pagar)
	
@author MarceloLauschner
@since 09/12/2013
@version 1.0		

@return Sem Retorno 

@example
(examples)

@see (links_or_references)
/*/
User Function RLFINA01()

	Local		oDlg
	Local		aButton		:= {}
	Private	aHeadAux		:= {}
	Private	aColsAux		:= {}
	Private	cCodInput		:= Space(48)
	Private	oCodInput,oQteTit,oTotTit
	Private 	aTamDlg 		:= MsAdvSize(,.F.,400)
	Private	oPanel1,oPanel2,oPanel3
	//IAGO 22/01/2015 Chamado(10020)
	//Private 	nPxPREFIXO,nPxNUM,nPxPARCELA,nPxFORNECE,nPxLOJA,nPxNOMFOR,nPxEMISSAO,nPxVENCORI,nPxVENCREA,nPxVALOR,nPxSALDO,nPxCODBAR,nPxTIPO
	Private 	nPxPREFIXO,nPxNUM,nPxPARCELA,nPxFORNECE,nPxLOJA,nPxNOMFOR,nPxEMISSAO,nPxVENCORI,nPxVENCREA,nPxVALOR,nPxSALDO,nPxCODBAR,nPxTIPO,nPxBANCO,nPxAGENCIA,nPxNUMCON
	Private	aTotRdPe		:= {0,0}
	
	DEFINE MSDIALOG oDlg Title OemToAnsi("Lançar códigos de barra") From aTamDlg[7],0 To aTamDlg[6],aTamDlg[5] OF oMainWnd PIXEL

	oDlg:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM


	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	@ 012 ,005 	Say OemToAnsi("Código de Barra") SIZE 50,9 Pixel	Of oPanel1 FONT oFnt 				//"Lote"
	@ 011 ,070		MSGET oCodInput Var cCodInput Pixel Size 182, 10 Of oPanel1 Valid sfVldGet()


	Processa({|| sfCarrega(@aColsAux,@aHeadAux,1) },"Localizando registros...")

	Private oMulti := MsNewGetDados():New(034,;
		005,;
		226,;
		415,;
		GD_INSERT+GD_DELETE+GD_UPDATE,;
		"U_RLFINA05()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,;
		"",;
		,4/*nFreeze*/,;
		10000/*nMax*/,;
		"U_RLFINA03()"/*cCampoOk*/,;
		"AllwaysTrue()"/*cSuperApagar*/,;
		"AllwaysTrue()"/*cApagaOk*/,;
		oPanel2,;
		aHeadAux,;
		aColsAux,;
		{|| sfAtuRodp() })

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	@ 006 ,008 Say OemToAnsi("Quantidade de Títulos")	Of oPanel3 PIXEL 	FONT oFnt		//"Descri‡„o da Entidade"
	@ 006 ,100	MsGet oQteTit Var aTotRdPe[1] Picture "@E 999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL
	
	@ 026 ,008 Say OemToAnsi("Valor de Títulos")	Of oPanel3 PIXEL 	FONT oFnt		//"Descri‡„o da Entidade"
	@ 026 ,100	MsGet oTotTit Var aTotRdPe[2] Picture "@E 999,999.99" Of oPanel3 READONLY SIZE 95 ,9 PIXEL

	Activate MsDialog oDlg On Init (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlg,{|| Processa({||sfGrava()},"Gravando dados..."),oDlg:End()},{|| oDlg:End()},,aButton))


Return


/*/{Protheus.doc} sfVldGet
(long_description)
	
@author MarceloLauschner
@since 09/12/2013
@version 1.0		

@return logico

@example
(examples)

@see (links_or_references)
/*/
Static Function sfVldGet()
	Local		lRet		:= .T.
	
	If !Empty(cCodInput)
		lRet	:= VldCodBar(cCodInput)
		If lRet
			Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados...")
		ElseIf !Empty(cCodInput)
			MsgInfo("O código de barras informado não é válido!!","Código de barras")
		Else
			lRet	:= .T.
		Endif
	Endif

Return lRet


/*/{Protheus.doc} sfGrava
(long_description)
	
@author MarceloLauschner
@since 09/12/2013
@version 1.0		

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfGrava()

	Local		nContAtu	:= 0
	Local		nX 
	
	For nX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[nX,Len(oMulti:aHeader)+1]
			DbSelectArea("SE2")
			DbSetOrder(1)
			If DbSeek(xFilial("SE2")+oMulti:aCols[nX,nPxPREFIXO]+oMulti:aCols[nX,nPxNUM]+oMulti:aCols[nX,nPxPARCELA]+oMulti:aCols[nX,nPxTIPO]+oMulti:aCols[nX,nPxFORNECE]+oMulti:aCols[nX,nPxLOJA])
				If !Empty(oMulti:aCols[nX,nPxCODBAR])
					RecLock("SE2",.F.)
					SE2->E2_CODBAR	:= oMulti:aCols[nX,nPxCODBAR]
					MsUnlock()
					nContAtu++
				Endif
			Endif
		Endif
	Next
	If nContAtu > 0
		MsgInfo("Atualização de '"+AllTrim(Str(nContAtu))+"' registros feito com sucesso!","Atualização concluída!")
	Else
		MsgAlert("Não atualização de dados!","Atualização finalizada!")
	Endif

Return



/*/{Protheus.doc} sfCarrega
(long_description)
	
@author MarceloLauschner
@since 09/12/2013
@version 1.0
		
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@param nRefrBox, numerico, (Descrição do parâmetro)

@return Sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfCarrega(aCols,aHeader,nRefrBox)

	Local	nUsado		:= 	0
	Local	aAreaOld	:= GetArea()
	Local	aCpo		:= 	{"E2_PREFIXO","E2_NUM","E2_PARCELA","E2_TIPO","E2_FORNECE","E2_LOJA","E2_NOMFOR","E2_EMISSAO","E2_VENCORI","E2_VENCREA","E2_VALOR","E2_SALDO","E2_CODBAR"}
	//IAGO 22/01/2015 Chamado(10020) aCpo2
	Local  aCpo2		:= {"A2_BANCO","A2_AGENCIA","A2_NUMCON"}
	Local	nColuna	:= 	0
	Local	cNextAlias
	Local	cExpSelect	:= ""
	Local	iX
	Local	aRetSE2	:= {}
	Local	lFindSe2	:= .F.
	Local	lDupCodBar	:= .T.
	Local	nPosCodBar	:= 0
	Local	cCampo		:= ""

	If nRefrBox	== 1
		aCols				:= 	{}
		aHeader			:=	{}
		Aadd(aHeader,{"Ok",; //	1
		"OK",;			// 	2
		"@BMP" ,;		// 	3
		1,;				// 	4
		0,;				// 	5
		"",;			//	6
		,;				//	7
		"C",;			//	8
		"",;			//	9
		"",;			//	10
		"",;			//	11
		""})			//	12
		nUsado++
		// DbSelectArea("SX3")
		// DbSetOrder(2)

		For iX := 1 To Len(aCpo)
			cCampo := aCpo[iX]
			Aadd(aHeader,{AllTrim(GetSx3Cache(cCampo,"X3_TITULO"))														,;	//	1
				Iif(Alltrim(GetSx3Cache(cCampo,"X3_CAMPO")) == "E2_CODBAR","E2CODBAR",GetSx3Cache(cCampo,"X3_CAMPO"))	,;	//	2
				GetSx3Cache(cCampo,"X3_PICTURE")																		,;	//	3
				GetSx3Cache(cCampo,"X3_TAMANHO")																		,;	//	4
				GetSx3Cache(cCampo,"X3_DECIMAL")																		,;	//	5
				"",;//SX3->X3_VALID																						,;	//	6
				GetSx3Cache(cCampo,"X3_USADO")																			,;	//	7
				GetSx3Cache(cCampo,"X3_TIPO")																			,;	//	8
				Iif(aCpo[iX]=="E2_PREFIXO","SE2CB",GetSx3Cache(cCampo,"X3_F3") ) 										,; 	//	9
				GetSx3Cache(cCampo,"X3_CONTEXT")																		,;	//	10
				GetSx3Cache(cCampo,"X3_CBOX")																			,;	//	11
				""																										})	//SX3->X3_RELACAO })					//	12
			nUsado++
			&("nPx"+Substr(GetSx3Cache(cCampo,"X3_CAMPO"),4,7)) := nUsado
		Next iX

		//IAGO 22/01/2015 Chamado(10020)
		
		For iX := 1 To Len(aCpo2)
			cCampo := aCpo2[iX]
			Aadd(aHeader,{ AllTrim(GetSx3Cache(cCampo,"X3_TITULO"))	,;	//	1
				GetSx3Cache(cCampo,"X3_CAMPO")						,;	//	2
				GetSx3Cache(cCampo,"X3_PICTURE")					,;	//	3
				GetSx3Cache(cCampo,"X3_TAMANHO")					,;	//	4
				GetSx3Cache(cCampo,"X3_DECIMAL")					,;	//	5
				""													,;	//	SX3->X3_VALID	,;	//	6
				GetSx3Cache(cCampo,"X3_USADO")						,;	//	7
				GetSx3Cache(cCampo,"X3_TIPO")						,;	//	8
				GetSx3Cache(cCampo,"X3_F3")							,;	//	9
				GetSx3Cache(cCampo,"X3_CONTEXT")					,;	//	10
				GetSx3Cache(cCampo,"X3_CBOX")						,;	//	11
				""													})	//SX3->X3_RELACAO })					//	12
				nUsado++
				&("nPx"+Substr(GetSx3Cache(cCampo,"X3_CAMPO"),4,7)) := nUsado
		Next

	Else
		
		If Empty(cCodInput)
			Return .T.
		Endif
		
		
		
		cExpSelect := "%"
	
		For iX := 1 To Len(aCpo)
			If iX > 1
				cExpSelect	+= ","+aCpo[iX]
			Else
				cExpSelect += aCpo[iX]
			Endif
		Next
		
		//IAGO 22/01/2015 Chamado(10020)
		For iX := 1 To Len(aCpo2)
			cExpSelect	+= ","+aCpo2[iX]
		Next
		
		cExpSelect += "%"
		
		
		aRetSE2	:= U_CodBar(cCodInput,.T./*lForceDate*/)
		
		If aRetSE2[1]
		
			// Verifica se há o código já digitado em outra linha na tela
			For nX := 1 To Len(oMulti:aCols)
				If !oMulti:aCols[nX,Len(oMulti:aHeader)+1]
					If Alltrim(aRetSE2[4]) == Alltrim(oMulti:aCols[nX,nPxCODBAR])
						MsgAlert("Código de barras já informado na linha '"+cValToChar(nX)+"'","Duplicidade!")
						lDupCodBar	:= .F.
					Endif
				Endif
			Next
	
			If lDupCodBar
			
				cNextAlias	:= GetNextAlias()
			
				BeginSql Alias cNextAlias
					COLUMN E2_EMISSAO AS DATE
					COLUMN E2_VENCORI AS DATE
					COLUMN E2_VENCREA AS DATE
					SELECT %Exp:cExpSelect%
					FROM %Table:SE2% E2
					INNER JOIN %Table:SA2% A2
					ON A2.A2_COD = E2.E2_FORNECE
					AND A2.A2_LOJA = E2.E2_LOJA
					WHERE E2.%NotDel%
					AND E2_TIPO NOT IN('NDF','CHQ','FOL','TX','ADI')
					AND E2_FILIAL = %xFilial:SE2%
					AND E2_VENCORI = %Exp:aRetSE2[2]%
					AND E2_VALOR = %Exp:aRetSE2[3]%
				EndSql
			
				While !Eof()
			
					If Len(aCols) == 1 .And. Empty(aCols[1,nPxNUM])
						aCols	:= {}
					Endif
					
					If Alltrim((cNextAlias)->E2_CODBAR) == Alltrim(aRetSE2[4])
						lFindSe2	:= .T.
						MsgAlert("O código de barras informado já está atribuído a outro título. '"+(cNextAlias)->E2_PREFIXO+"/"+(cNextAlias)->E2_NUM+"-"+(cNextAlias)->E2_PARCELA+"'","Dados já existentes!")
					Else
					
						Aadd(aCols,Array(Len(aHeader)+1))
				
						lFindSe2	:= .T.
				
						For nColuna := 1 to Len( aHeader )
					
							If (cNextAlias)->(FieldPos(aHeader[nColuna,2])) > 0
								aCols[Len(aCols)][nColuna] 	:= 	(cNextAlias)->(FieldGet(FieldPos(aHeader[nColuna,2])))
							ElseIf aHeader[nColuna][8] == "C"
								aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
							ElseIf aHeader[nColuna][8] == "D"
								aCols[Len(aCols)][nColuna] := dDataBase
							ElseIf aHeader[nColuna][8] == "M"
								aCols[Len(aCols)][nColuna] := ""
							ElseIf aHeader[nColuna][8] == "N"
								aCols[Len(aCols)][nColuna] := 0
							Else
								aCols[Len(aCols)][nColuna] := .F.
							Endif
							
							If !Empty(aHeader[nColuna][12])
								aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
							Endif
							
							If Alltrim(aHeader[nColuna][2]) == "E2CODBAR"
								nPosCodBar := nColuna
							Endif
							
							
						Next nColuna
						// Garante que a coluna do código de barra se alimentada
						If nPosCodBar > 0
							aCols[Len(aCols)][nPosCodBar] 	:= aRetSE2[4]
						Endif
				
						aCols[Len(aCols),Len(aHeader)+1]	:= .F.
					Endif
					DbSelectArea(cNextAlias)
					DbSkip()
				Enddo
				(cNextAlias)->(DbCloseArea())
			Endif
			
			RestArea(aAreaOld)
		
			If !lFindSe2
				MsgAlert("Não foram encontrados registros de títulos do Contas a Pagar com os dados de vencimento e valor informados","Sem registro de títulos")
			Endif
		Endif
			
		cCodInput	:= Space(48)
		oCodInput:Refresh()
		oCodInput:SetFocus()
		If Type("oMulti") <> "U"
			oMulti:oBrowse:Refresh()
			sfAtuRodp()
		Endif
	Endif

Return


/*/{Protheus.doc} sfAtuRodp
(long_description)
	
@author MarceloLauschner
@since 09/12/2013
@version 1.0		

@return sem retorno

@example
(examples)

@see (links_or_references)
/*/
Static Function sfAtuRodp()

	Local	nX		:= 0
	aTotRdPe[1]	:= 0
	aTotRdPe[2]	:= 0

	For nX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[nX,Len(oMulti:aHeader)+1]
			aTotRdPe[1]	++
			aTotRdPe[2]	+= oMulti:aCols[nX,nPxVALOR]
		Endif
	Next

	oTotTit:Refresh()
	oQteTit:Refresh()


Return




/*/{Protheus.doc} BFFINA04
(Validação do campo E2_CODBAR direta)
	
@author MarceloLauschner
@since 18/12/2013
@version 1.0		

@return logico, se validou o campo 

@example
(examples)

@see (links_or_references)
/*/
User Function RLFINA04()
	Local		lRet	:= .T.
	
	If ReadVar() == "M->E2_CODBAR"
		lRet	:= VldCodBar(M->E2_CODBAR)
		aRetSE2	:= U_CodBar(M->E2_CODBAR)
	
		If lRet .And. aRetSE2[1]
			lRet			:= .T.
			M->E2_CODBAR	:= aRetSE2[4]
			// Valida se o valor do título confere com o valor informado no código de barras
			If Round(aRetSE2[3],2) <> M->E2_VALOR
				MsgAlert("Foi encontrada diferença de valor do título!","Diferença no valor título")
			Endif
		Else
			lRet	:= .F.
		Endif
	Endif
Return lRet
