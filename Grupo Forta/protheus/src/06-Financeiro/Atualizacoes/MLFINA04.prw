#Include 'totvs.ch'

/*/{Protheus.doc} MLFINA04
(Interface para lançamento de Código de barras de títulos a pagar)
@author MarceloLauschner
@since 09/12/2013
@version 1.0
@return Sem Retorno
@example
(examples)

@see (links_or_references)
/*/
User Function MLFINA04()

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
	Private 	nPxPREFIXO,nPxNUM,nPxPARCELA,nPxFORNECE,nPxLOJA,nPxNOMFOR,nPxEMISSAO,nPxVENCORI,nPxVENCREA,nPxVALOR,nPxSALDO,nPxCODBAR,nPxLINDIG
	Private     nPxTIPO,nPxBANCO,nPxAGENCIA,nPxNUMCON,nPxCODRET,nPxHIST,nPxNATUREZ,nPxOK
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
		"U_MLFINA4A()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,;
		"",;
		,4/*nFreeze*/,;
		10000/*nMax*/,;
		"U_MLFINA4B()"/*cCampoOk*/,;
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
	Local       nConInc     := 0
	Local       nX

	For nX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[nX,Len(oMulti:aHeader)+1]
			DbSelectArea("SE2")
			DbSetOrder(1)
			If DbSeek(xFilial("SE2")+oMulti:aCols[nX,nPxPREFIXO]+oMulti:aCols[nX,nPxNUM]+oMulti:aCols[nX,nPxPARCELA]+oMulti:aCols[nX,nPxTIPO]+oMulti:aCols[nX,nPxFORNECE]+oMulti:aCols[nX,nPxLOJA])
				If !Empty(oMulti:aCols[nX,nPxCODBAR])
					RecLock("SE2",.F.)
					SE2->E2_CODBAR	:= oMulti:aCols[nX,nPxCODBAR]
					SE2->E2_LINDIG  := oMulti:aCols[nX,nPxLINDIG]
					MsUnlock()
					nContAtu++
				Endif
			ElseIf oMulti:aCols[nX,nPxOK] == "XX"
				If sfGrvSE2(nX)
					nConInc++
				Endif
			Endif
		Endif
	Next

	If nContAtu > 0
		MsgInfo("Atualização de '"+AllTrim(Str(nContAtu))+"' registros feito com sucesso!","Atualização concluída!")
	Endif
	If nConInc > 0
		MsgInfo("Inclusão de '"+AllTrim(Str(nConInc))+"' registros feito com sucesso!","Atualização concluída!")
	Endif
	If nConInc == 0 .And. nContAtu == 0
		MsgAlert("Não houve atualização de dados!","Atualização finalizada!")
	Endif

Return

Static Function sfGrvSE2(nLin)

	Local   lRet    := .F.
	Private lMsHelpAuto := .F.
	Private lMsErroAuto := .F.

	Begin Transaction


		//+StrZero(Month(dDataBase),2)
		aTitulo := {;
			{"E2_PREFIXO" , oMulti:aCols[nLin,nPxPREFIXO]     ,Nil},;
			{"E2_NUM"     , oMulti:aCols[nLin,nPxNUM]         ,Nil},;
			{"E2_PARCELA" , oMulti:aCols[nLin,nPxPARCELA]     ,Nil},;
			{"E2_TIPO"	  , oMulti:aCols[nLin,nPxTIPO]        ,Nil},;
			{"E2_NATUREZ" , oMulti:aCols[nLin,nPxNATUREZ]     ,Nil},;
			{"E2_FORNECE" , oMulti:aCols[nLin,nPxFORNECE]     ,Nil},;
			{"E2_LOJA"	  , oMulti:aCols[nLin,nPxLOJA]        ,Nil},;
			{"E2_EMISSAO" , oMulti:aCols[nLin,nPxEMISSAO]     ,Nil},;
			{"E2_VENCTO"  , oMulti:aCols[nLin,nPxVENCORI]     ,Nil},;
			{"E2_VENCREA" , oMulti:aCols[nLin,nPxVENCREA]     ,Nil},;
			{"E2_VALOR"   , oMulti:aCols[nLin,nPxVALOR]       ,Nil},;
			{"E2_CODBAR"  , oMulti:aCols[nLin,nPxCODBAR]      ,Nil},;
			{"E2_LINDIG"  , oMulti:aCols[nLin,nPxLINDIG]      ,Nil},;
			{"E2_HIST"    , "COD.RET/REC:"+oMulti:aCols[nLin,nPxCODRET] + "/" + oMulti:aCols[nLin,nPxHIST]        ,Nil} }

		//{"E2_CODRET"  , oMulti:aCols[nLin,nPxCODRET]      ,Nil},;

		MSExecAuto({|x,y| FINA050(x,y)},aTitulo,3)

	End Transaction

	If lMsErroAuto
		MostraErro()
		DisarmTransaction()
		lRet    := .F.
	Else
		lRet    := .T.
	Endif

Return lRet

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
	Local	aCpo		:= 	{"E2_OK","E2_PREFIXO","E2_NUM","E2_PARCELA","E2_TIPO","E2_NATUREZ","E2_FORNECE","E2_LOJA","E2_NOMFOR","E2_EMISSAO","E2_VENCORI","E2_VENCREA","E2_VALOR","E2_SALDO","E2_CODBAR","E2_LINDIG","E2_CODRET","E2_HIST"}
	Local   aCpo2		:= {"A2_BANCO","A2_AGENCIA","A2_NUMCON"}
	Local	cNextAlias
	Local	cExpSelect	:= ""
	Local	iX,nX,nColuna
	Local	aRetSE2		:= {}
	Local	lFindSe2	:= .F.
	Local	lDupCodBar	:= .T.
	Local	nPosCodBar	:= 0
	Local   nPosLinDig  := 0
	Local	lAddSe2		:= .F.
	Local 	cParcela	:= " "

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
		DbSelectArea("SX3")
		DbSetOrder(2)
		For iX := 1 To Len(aCpo)
			If DbSeek(aCpo[iX])
				Aadd(aHeader,{ AllTrim(X3Titulo()),;	//	1
				Iif(Alltrim(SX3->X3_CAMPO) == "E2_CODBAR","E2CODBAR",Iif(Alltrim(SX3->X3_CAMPO) == "E2_LINDIG","E2LINDIG",SX3->X3_CAMPO))	,;						//	2
				SX3->X3_PICTURE,;						//	3
				SX3->X3_TAMANHO,;						//	4
				SX3->X3_DECIMAL,;						//	5
				"",;//SX3->X3_VALID	,;				//	6
				SX3->X3_USADO	,;						//	7
				SX3->X3_TIPO	,;						//	8
				Iif(aCpo[iX]=="E2_PREFIXO","SE2CB",SX3->X3_F3) 		,;					//	9
				SX3->X3_CONTEXT,;						//	10
				SX3->X3_CBOX	,;						//	11
				""})//SX3->X3_RELACAO })					//	12
				nUsado++
				&("nPx"+Substr(SX3->X3_CAMPO,4,7)) := nUsado
			Endif
		Next

		For iX := 1 To Len(aCpo2)
			If DbSeek(aCpo2[iX])
				Aadd(aHeader,{ AllTrim(X3Titulo()),;	//	1
				SX3->X3_CAMPO,;						//	2
				SX3->X3_PICTURE,;						//	3
				SX3->X3_TAMANHO,;						//	4
				SX3->X3_DECIMAL,;						//	5
				"",;//SX3->X3_VALID	,;				//	6
				SX3->X3_USADO	,;						//	7
				SX3->X3_TIPO	,;						//	8
				SX3->X3_F3,;					//	9
				SX3->X3_CONTEXT,;						//	10
				SX3->X3_CBOX	,;						//	11
				""})//SX3->X3_RELACAO })					//	12
				nUsado++
				&("nPx"+Substr(SX3->X3_CAMPO,4,7)) := nUsado
			Endif
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
				AND (E2_VENCORI = %Exp:aRetSE2[2]% OR E2_VENCREA = %Exp:aRetSE2[2]%)
				AND E2_VALOR = %Exp:aRetSE2[3]%
				ORDER BY E2_CODBAR DESC
				EndSql
				If !Eof()
					While !Eof()

						If Len(aCols) == 1 .And. Empty(aCols[1,nPxNUM])
							aCols	:= {}
						Endif

						If Alltrim((cNextAlias)->E2_CODBAR) == Alltrim(aRetSE2[4])
							lFindSe2	:= .T.
							MsgAlert("O código de barras informado já está atribuído a outro título. '"+(cNextAlias)->E2_PREFIXO+"/"+(cNextAlias)->E2_NUM+"-"+(cNextAlias)->E2_PARCELA+"'","Dados já existentes!")
						Else
							If DataValida(STOD(aRetSE2[2])) < (cNextAlias)->E2_VENCREA
								If MsgYesNo("Data de Vencimento Real no Título (" + DTOC((cNextAlias)->E2_VENCREA )+") está maior que a data do Vencimento do Código de Barras (" + DTOC(STOD(aRetSE2[2]))+")!" +CRLF+" Deseja lançar ? ")
									lAddSe2	:= .T.
								Endif
							Else
								lAddSe2	:= .T.
							Endif
						Endif

						If lAddSe2
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

								If !Empty(aHeader[nColuna][12]) .And. Empty(aCols[Len(aCols)][nColuna])
									aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
								Endif

								If Alltrim(aHeader[nColuna][2]) == "E2CODBAR"
									nPosCodBar := nColuna
								Endif

								If Alltrim(aHeader[nColuna][2]) == "E2LINDIG"
									nPosLinDig := nColuna
								Endif

							Next nColuna
							// Garante que a coluna do código de barra se alimentada
							If nPosCodBar > 0
								aCols[Len(aCols)][nPosCodBar] 	:= aRetSE2[4]
							Endif

							If Substr(aRetSE2[4],1,1) <> "8" .And. Len(aRetSE2[4]) == 44
								aCols[Len(aCols)][nPosLinDig]  := sfCalcBDig(aRetSE2[4])
							ElseIf Substr(aRetSE2[4],1,1) =="8" .And. Len(aRetSE2[6]) == 48
								aCols[Len(aCols)][nPosLinDig]  := aRetSE2[6]
							Endif

							aCols[Len(aCols),Len(aHeader)+1]	:= .F.
						Endif
						DbSelectArea(cNextAlias)
						DbSkip()
					Enddo
				ElseIf MsgYesNo("Deseja incluir a linha para cadastrar o título como um contas a pagar? ")
					If Len(aCols) == 1 .And. Empty(aCols[1,nPxNUM])
						aCols	:= {}
					Endif

					Aadd(aCols,Array(Len(aHeader)+1))

					lFindSe2	:= .T.

					For nColuna := 1 to Len( aHeader )

						If aHeader[nColuna][8] == "C"
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

						If !Empty(aHeader[nColuna][12]) .And. Empty(aCols[Len(aCols)][nColuna])
							aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
						Endif

						If Alltrim(aHeader[nColuna][2]) == "E2CODBAR"
							nPosCodBar := nColuna
						Endif

						If Alltrim(aHeader[nColuna][2]) == "E2LINDIG"
							nPosLinDig := nColuna
						Endif

					Next nColuna
					// Garante que a coluna do código de barra se alimentada
					If nPosCodBar > 0
						aCols[Len(aCols)][nPosCodBar] 	:= aRetSE2[4]
					Endif

					If Substr(aRetSE2[4],1,1) <> "8" .And. Len(aRetSE2[4]) == 44
						aCols[Len(aCols)][nPosLinDig]  := sfCalcBDig(aRetSE2[4])
					ElseIf Substr(aRetSE2[4],1,1) =="8" .And. Len(aRetSE2[6]) == 48
						aCols[Len(aCols)][nPosLinDig]  := aRetSE2[6]
					Endif
                    /*
                    POSIÇÃO TAMANHO CONTEÚDO
                    01 – 01 1   Identificação do Produto
                            Constante “8” para identificar arrecadação 
                    02 – 02 1   Identificação do Segmento
                            Identificará o segmento e a forma de identificação da Empresa/Órgão:
                            1. Prefeituras;
                            2. Saneamento;
                            3. Energia Elétrica e Gás;
                            4. Telecomunicações;
                            5. Órgãos Governamentais;
                            6. Carnes e Assemelhados ou demais
                            Empresas / Órgãos que serão identificadas através do CNPJ.
                            7. Multas de trânsito
                            9. Uso exclusivo do banco 
                    03 – 03 1   Identificação do valor real ou referência
                            “6”- Valor a ser cobrado efetivamente em reais
                            com dígito verificador calculado pelo módulo 10 na quarta
                            posição do Código de Barras e valor com 11 posições (versão
                            2 e posteriores) sem qualquer alteração;
                            “7”- Quantidade de moeda
                            Zeros – somente na impossibilidade de utilizar o valor;
                            Valor a ser reajustado por um índice
                            com dígito .verificador calculado pelo módulo 10 na quarta
                            posição do Código de Barras e valor com 11 posições (versão 2 e
                            posteriores).
                            “8” – Valor a ser cobrado efetivamente em reais
                            com dígito verificador calculado pelo módulo 11 na quarta
                            posição do Código de Barras e valor com 11 posições (versão 2
                            e posteriores) sem qualquer alteração.
                            “9” – Quantidade de moeda
                            Zeros – somente na impossibilidade de utilizar o valor;
                            Valor a ser reajustado por um índice
                            com dígito .verificador calculado pelo módulo 11 na quarta
                            posição do Código de Barras e valor com 11 posições (versão 2 e
                            posteriores).
                    04 – 04 1   Dígito verificador geral (módulo 10 ou 11)
                            Dígito de auto conferência dos dados contidos no Código de Barras. 
                    05 – 15 11  Valor
                            Se o campo “03 – Código de Moeda” indicar valor efetivo, este campo
                            deverá conter o valor a ser cobrado.
                            Se o campo “03 - Código de Moeda” indicado valor de referência, neste
                            campo poderá conter uma quantidade de moeda, zeros, ou um valor a ser
                            reajustado por um índice, etc... 
                    16 – 19 4   Identificação da Empresa/Órgão
                            O campo identificação da Empresa/Órgão terá uma codificação especial
                            para cada segmento.
                            Será um código de quatro posições atribuído e controlado pela Febraban,
                            ou as primeiras oito posições do cadastro geral de contribuintes do
                            Ministério da Fazenda.
                            É através desta informação que o banco identificará a quem repassar as
                            informações e o crédito.
                            Se for utilizado o CNPJ para identificar a Empresa/Órgão, haverá uma
                            redução no seu campo livre que passará a conter 21 posições.
                            No caso de utilização do Segmento 9, este campo deverá conter o código
                            de compensação do mesmo, com quatro dígitos.
                            Cada banco definirá a forma de identificação da empresa a partir da 20ª
                            posição. 
                    20 – 44 25  Campo livre de utilização da Empresa/Órgão
                    16 – 23 8   CNPJ / MF
                    24 – 44 21  Campo livre de utilização da Empresa/Órgão
                            Este campo é de uso exclusivo da Empresa/Órgão e será devolvido
                            inalterado.
                            Se existir data de vencimento no campo livre, ela deverá vir em primeiro
                            lugar e em formato AAAAMMDD. 
                    */
					// Se for um documento de Arrecadação
					If Substr(aRetSE2[4],1,1) =="8"

						//1. Prefeituras;
						If Substr(aRetSE2[4],2,1) =="1"

							// Identifica o Fornecedor
							If Substr(aRetSE2[4],16,4) == "1656"  // DARM - PREFEITURA GASPAR

								aCols[Len(aCols)][nPxFORNECE]   := Padr("001533",TamSX3("E2_FORNECE")[1])
								aCols[Len(aCols)][nPxLOJA]      := Padr("01",TamSX3("E2_LOJA")[1])
								aCols[Len(aCols)][nPxNOMFOR]    := Posicione("SA2",1,xFilial("SA1")+aCols[Len(aCols)][nPxFORNECE]+aCols[Len(aCols)][nPxLOJA],"A2_NREDUZ")

								// Identifica o Código da Receita
								aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"25"))
								aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
								aCols[Len(aCols)][nPxTIPO]      := Padr("ISS",TamSX3("E2_TIPO")[1])
								aCols[Len(aCols)][nPxNUM]       := Padr("ISS"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
								aCols[Len(aCols)][nPxPREFIXO]   := Padr("ISS",TamSX3("E2_PREFIXO")[1])
								aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARM","")),TamSX3("E2_HIST")[1])


							Endif

						//2. Saneamento;
						ElseIf Substr(aRetSE2[4],2,1) =="2"

						//3. Energia Elétrica e Gás;
						ElseIf Substr(aRetSE2[4],2,1) =="3"

						//4. Telecomunicações;
						ElseIf Substr(aRetSE2[4],2,1) =="4"

						//5. Órgãos Governamentais;
						ElseIf Substr(aRetSE2[4],2,1) =="5"

							// Identifica o Fornecedor
							If Substr(aRetSE2[4],16,4) =="0064"  // DARF

								aCols[Len(aCols)][nPxFORNECE]   := Padr("UNIAO",TamSX3("E2_FORNECE")[1])
								aCols[Len(aCols)][nPxLOJA]      := Padr("00",TamSX3("E2_LOJA")[1])
								aCols[Len(aCols)][nPxNOMFOR]    := Posicione("SA2",1,xFilial("SA1")+aCols[Len(aCols)][nPxFORNECE]+aCols[Len(aCols)][nPxLOJA],"A2_NREDUZ")
								// Identifica o Código da Receita
								If Substr(aRetSE2[4],37,4) $ "6912#8109"  // PIS
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("PIS",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"25"))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("PIS"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("PIS",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])

								ElseIf Substr(aRetSE2[4],37,4) $ "5856#2172"  // COFINS
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("COFINS",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"25"))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("COF"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("COF",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])

								ElseIf Substr(aRetSE2[4],37,4) =="0580"  // INSS
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("INSS",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"20"))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("INS"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("INS",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])


								ElseIf Substr(aRetSE2[4],37,4) $ "8045#0561"  // IR SOBRE SALARIOS
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("IRF",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),LastDay(dDataBase))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("IRF"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("IRF",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])
								
								ElseIf Substr(aRetSE2[4],37,4) =="8614"  // FGTS
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("FGTS",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"07"))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("FGT"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("FGT",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])

								ElseIf Substr(aRetSE2[4],37,4) =="8368"  // FGTS RESCISÓRIO 
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("FGTS",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"07"))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("FGT"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("FGT",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])

								ElseIf Substr(aRetSE2[4],37,4) =="5993"  // IRPJ
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("IRRF",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),LastDay(dDataBase))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("IRJ"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("IRJ",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])


								ElseIf Substr(aRetSE2[4],37,4) =="2484"  // CSLL
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("CSLL",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),LastDay(dDataBase))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("CSL"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("CSL",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])

								ElseIf Substr(aRetSE2[4],37,4) =="5952"  // CSRF
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("CSRF",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),LastDay(dDataBase))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("CSR"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("CSR",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])

								ElseIf Substr(aRetSE2[4],37,4) =="3926"  // DARF 3926
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("DARF",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),LastDay(dDataBase))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("DRF"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("DRF",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])
								ElseIf Substr(aRetSE2[4],37,4) =="1233"  // DARF 1233
									aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],37,4)
									aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("DARF",TamSX3("E2_NATUREZ")[1])
									aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),LastDay(dDataBase))
									aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
									aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
									aCols[Len(aCols)][nPxNUM]       := Padr("DRF"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
									aCols[Len(aCols)][nPxPREFIXO]   := Padr("DRF",TamSX3("E2_PREFIXO")[1])
									aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF","")),TamSX3("E2_HIST")[1])
								Endif


						
							ElseIf Substr(aRetSE2[4],17,4) =="3852"  // GPS 
								aCols[Len(aCols)][nPxFORNECE]   := Padr("UNIAO",TamSX3("E2_FORNECE")[1])
								aCols[Len(aCols)][nPxLOJA]      := Padr("00",TamSX3("E2_LOJA")[1])
								aCols[Len(aCols)][nPxNOMFOR]    := Posicione("SA2",1,xFilial("SA1")+aCols[Len(aCols)][nPxFORNECE]+aCols[Len(aCols)][nPxLOJA],"A2_NREDUZ")
								aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],17,4)
								aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("GPS",TamSX3("E2_NATUREZ")[1])
								aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"20"))
								aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
								aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
								aCols[Len(aCols)][nPxNUM]       := Padr("GPS"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
								aCols[Len(aCols)][nPxPREFIXO]   := Padr("GPS",TamSX3("E2_PREFIXO")[1])
								aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF-GPS","")),TamSX3("E2_HIST")[1])

							ElseIf Substr(aRetSE2[4],20,4) =="1201"  // GPS  Recalculada
								aCols[Len(aCols)][nPxFORNECE]   := Padr("UNIAO",TamSX3("E2_FORNECE")[1])
								aCols[Len(aCols)][nPxLOJA]      := Padr("00",TamSX3("E2_LOJA")[1])
								aCols[Len(aCols)][nPxNOMFOR]    := Posicione("SA2",1,xFilial("SA1")+aCols[Len(aCols)][nPxFORNECE]+aCols[Len(aCols)][nPxLOJA],"A2_NREDUZ")
								aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],17,4)
								aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("GPS",TamSX3("E2_NATUREZ")[1])
								aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"20"))
								aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
								aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
								aCols[Len(aCols)][nPxNUM]       := Padr("GPS"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
								aCols[Len(aCols)][nPxPREFIXO]   := Padr("GPS",TamSX3("E2_PREFIXO")[1])
								aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF-GPS","")),TamSX3("E2_HIST")[1])
						
							ElseIf Substr(aRetSE2[4],20,4) =="2100"  // GPS  
								aCols[Len(aCols)][nPxFORNECE]   := Padr("UNIAO",TamSX3("E2_FORNECE")[1])
								aCols[Len(aCols)][nPxLOJA]      := Padr("00",TamSX3("E2_LOJA")[1])
								aCols[Len(aCols)][nPxNOMFOR]    := Posicione("SA2",1,xFilial("SA1")+aCols[Len(aCols)][nPxFORNECE]+aCols[Len(aCols)][nPxLOJA],"A2_NREDUZ")
								aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],17,4)
								aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("GPS",TamSX3("E2_NATUREZ")[1])
								aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),STOD(Substr(DTOS(LastDay(dDataBase)+1),1,6)+"20"))
								aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
								aCols[Len(aCols)][nPxTIPO]      := Padr("DRF",TamSX3("E2_TIPO")[1])
								aCols[Len(aCols)][nPxNUM]       := Padr("GPS"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
								aCols[Len(aCols)][nPxPREFIXO]   := Padr("GPS",TamSX3("E2_PREFIXO")[1])
								aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARF-GPS","")),TamSX3("E2_HIST")[1])
						
							ElseIf Substr(aRetSE2[4],16,4) =="0179"  // GRF

							ElseIf Substr(aRetSE2[4],16,4) =="0385"  // DARF RECEITA FEDERAL

							ElseIf Substr(aRetSE2[4],16,4) =="0024"  // DARE SC
								aCols[Len(aCols)][nPxFORNECE]   := Padr("001666",TamSX3("E2_FORNECE")[1])
								aCols[Len(aCols)][nPxLOJA]      := Padr("01",TamSX3("E2_LOJA")[1])
								aCols[Len(aCols)][nPxNOMFOR]    := Posicione("SA2",1,xFilial("SA1")+aCols[Len(aCols)][nPxFORNECE]+aCols[Len(aCols)][nPxLOJA],"A2_NREDUZ")
								aCols[Len(aCols)][nPxCODRET]    := Substr(aRetSE2[4],40,4)
								aCols[Len(aCols)][nPxNATUREZ]  	:= Padr("DARE",TamSX3("E2_NATUREZ")[1])
								aCols[Len(aCols)][nPxVENCORI]   := Iif(!Empty(aRetSE2[2]),STOD(aRetSE2[2]),LastDay(dDataBase))
								aCols[Len(aCols)][nPxVENCREA]   := sfAntData(aCols[Len(aCols)][nPxVENCORI])
								aCols[Len(aCols)][nPxTIPO]      := Padr("DAR",TamSX3("E2_TIPO")[1])
								aCols[Len(aCols)][nPxNUM]       := Padr("DAR"+DTOS(aCols[Len(aCols)][nPxVENCREA]),TamSX3("E2_NUM")[1])
								aCols[Len(aCols)][nPxPREFIXO]   := Padr("DAR",TamSX3("E2_PREFIXO")[1])
								aCols[Len(aCols)][nPxHIST]      := Padr(Alltrim(FwInputBox("Digite o histórico para esta DARE","")),TamSX3("E2_HIST")[1])
							Endif

							//6. Carnes e Assemelhados ou demais  Empresas / Órgãos que serão identificadas através do CNPJ.
						ElseIf Substr(aRetSE2[4],2,1) =="6"

							//7. Multas de trânsito
						ElseIf Substr(aRetSE2[4],2,1) =="7"

							//9. Uso exclusivo do banco
						ElseIf Substr(aRetSE2[4],2,1) =="9"

						Endif

						//  05 – 15 11  Valor
						aCols[Len(aCols)][nPxVALOR]    := Val(Substr(aRetSE2[4],5,11))/100
						aCols[Len(aCols)][nPxSALDO]    := Val(Substr(aRetSE2[4],5,11))/100

						aCols[Len(aCols)][nPxOK]       := "XX"

						// Verifica se já não existe o prefixo / título / parcela
						cParcela	:= SuperGetMV("MV_1DUP   ")
						While .T.

							DbSelectArea("SE2")
							DbSetOrder(1)
							If DbSeek(xFilial("SE2")+aCols[Len(aCols)][nPxPREFIXO]+aCols[Len(aCols)][nPxNUM]+aCols[Len(aCols)][nPxPARCELA]+aCols[Len(aCols)][nPxTIPO]+aCols[Len(aCols)][nPxFORNECE]+aCols[Len(aCols)][nPxLOJA])
								aCols[Len(aCols)][nPxPARCELA]	:= MaParcela(cParcela)
							Else
								Exit
							Endif
						Enddo


					Endif

					aCols[Len(aCols),Len(aHeader)+1]	:= .F.
				Endif

				(cNextAlias)->(DbCloseArea())
			Endif
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

Return

Static Function sfAntData(dInData)

	Local   dDataOut    := dInData

	While DataValida(dDataOut) > dInData
		dDataOut--
	Enddo

Return DataValida(dDataOut)

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

/*/{Protheus.doc} MLFINA4A
description
@type function
@version
@author Marcelo Alberto Lauschner
@since 09/12/2013
@return return_type, return_description
/*/
User Function MLFINA4A()

	Local	lRet		:= .F.
	Local	aRetSE2	:= {}

	If !oMulti:aCols[oMulti:nAt,Len(oMulti:aHeader)+1]
		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+oMulti:aCols[oMulti:nAt,nPxPREFIXO]+oMulti:aCols[oMulti:nAt,nPxNUM]+oMulti:aCols[oMulti:nAt,nPxPARCELA]+oMulti:aCols[oMulti:nAt,nPxTIPO]+oMulti:aCols[oMulti:nAt,nPxFORNECE]+oMulti:aCols[oMulti:nAt,nPxLOJA])
			If VldCodBar(oMulti:aCols[oMulti:nAt,nPxCODBAR])
				aRetSE2	:= U_CodBar(oMulti:aCols[oMulti:nAt,nPxCODBAR])
				If aRetSE2[1]
					lRet	:= .T.
					oMulti:aCols[oMulti:nAt,nPxCODBAR]	:= aRetSE2[4]
					If Empty(oMulti:aCols[oMulti:nAt,nPxLINDIG]) .And. Substr(aRetSE2[4],1,1) <> "8" .And. Len(aRetSE2[4]) == 44
						oMulti:aCols[oMulti:nAt,nPxLINDIG] := sfCalcBDig(aRetSE2[4])
					ElseIf Empty(oMulti:aCols[oMulti:nAt,nPxLINDIG]) .And. Substr(aRetSE2[4],1,1) == "8" .And. Len(aRetSE2[6]) == 48
						oMulti:aCols[oMulti:nAt,nPxLINDIG] := aRetSE2[6]
					Endif
				Else
					MsgAlert("O código de barras informado não foi validado!","Dados incorretos 'U_CodBar'")
				Endif
			Else
				MsgAlert("O código de barras informado não é válido!","Dados incorretos 'VldCodBar'")
			Endif
		ElseIf oMulti:aCols[oMulti:nAt,nPxOK] == "XX"
			lRet    := .T.
		Else
			MsgAlert("Não existe título com os dados informados!","Sem registro")
		Endif
	Else
		lRet	:= .T.
	Endif

Return lRet


Return .T.

/*/{Protheus.doc} MLFINA4B
description
@type function
@version
@author Marcelo Alberto Lauschner
@since 09/12/2013
@return return_type, return_description
/*/
User Function MLFINA4B()

	Local		lRet	:= .T.

	If ReadVar() == "M->E2CODBAR"

		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+oMulti:aCols[oMulti:nAt,nPxPREFIXO]+oMulti:aCols[oMulti:nAt,nPxNUM]+oMulti:aCols[oMulti:nAt,nPxPARCELA]+oMulti:aCols[oMulti:nAt,nPxTIPO]+oMulti:aCols[oMulti:nAt,nPxFORNECE]+oMulti:aCols[oMulti:nAt,nPxLOJA])

			lRet		:= VldCodBar(M->E2CODBAR)
			aRetSE2	    := U_CodBar(M->E2CODBAR)

			If lRet .And. aRetSE2[1]
				lRet			:= .T.
				M->E2CODBAR	:= aRetSE2[4]
				If Substr(aRetSE2[4],1,1) <> "8" .And. Len(aRetSE2[4]) == 44
					M->E2LINDIG := sfCalcBDig(aRetSE2[4])
				ElseIf Substr(aRetSE2[4],1,1) =="8" .And. Len(aRetSE2[6]) == 48
					M->E2LINDIG := aRetSE2[6]
				Endif

				// Valida se o valor do título confere com o valor informado no código de barras
				If Round(aRetSE2[3],2) <> Round(oMulti:aCols[oMulti:nAt,nPxVALOR],2)
					MsgAlert("Foi encontrada diferença de valor do título!","Diferença no valor título")
				Endif
			Else
				lRet	:= .F.
			Endif
		Else

		Endif
	ElseIf ReadVar() == "M->E2_LOJA"
		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+oMulti:aCols[oMulti:nAt,nPxPREFIXO]+oMulti:aCols[oMulti:nAt,nPxNUM]+oMulti:aCols[oMulti:nAt,nPxPARCELA]+oMulti:aCols[oMulti:nAt,nPxTIPO]+oMulti:aCols[oMulti:nAt,nPxFORNECE]+M->E2_LOJA)
			oMulti:aCols[oMulti:nAt,nPxEMISSAO]	    := SE2->E2_EMISSAO
			oMulti:aCols[oMulti:nAt,nPxVENCORI]	    := SE2->E2_VENCORI
			oMulti:aCols[oMulti:nAt,nPxVENCREA]	    := SE2->E2_VENCREA
			oMulti:aCols[oMulti:nAt,nPxVALOR]		:= SE2->E2_VALOR
			oMulti:aCols[oMulti:nAt,nPxSALDO]		:= SE2->E2_SALDO
			oMulti:aCols[oMulti:nAt,nPxCODBAR]		:= Padr(SE2->E2_CODBAR,48)
		Endif
		//IAGO 22/01/2015 Chamado(10020)
		dbSelectArea("SA2")
		DbSetOrder(1)
		If dbSeek(xFilial("SA2")+oMulti:aCols[oMulti:nAt,nPxFORNECE]+oMulti:aCols[oMulti:nAt,nPxLOJA])
			oMulti:aCols[oMulti:nAt,nPxBANCO] 		:= SA2->A2_BANCO
			oMulti:aCols[oMulti:nAt,nPxAGENCIA] 	:= SA2->A2_AGENCIA
			oMulti:aCols[oMulti:nAt,nPxNUMCON] 	    := SA2->A2_NUMCON
		EndIf
	Endif

Return lRet



/*/{Protheus.doc} MLFINA4C
Validação do campo E2_CODBAR direta
@type function
@version
@author Marcelo Alberto Lauschner
@since 18/12/2013
@return return_type, return_description
/*/
User Function MLFINA4C()
	Local		lRet	:= .T.

	If ReadVar() == "M->E2_CODBAR"
		lRet		:= VldCodBar(M->E2_CODBAR)
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


Static Function sfCalcBDig(cBarra)

	Local   cDigBarra   := ""
	Local   cBar1
	Local   cBar2
	Local   cBar3
	Local   cBar4
	Local   cLinha
	Local   cBarraFim

	cDigBarra 	:= sf_DAC(Substr(cBarra,1,4) + Substr(cBarra,6,43))	  	// calculo dos digito verificador do codigo barra para a posicao 5 do codigo de barra

	// Não precisa calcula o DAC pois ele já consta no código passado
	cBarraFim  	:= cBarra   //Substr(cBarra,1,4) + cDigBarra + Substr(cBarra,5,43)

	//Posição 01-03 = Identificação do banco (001 = Banco do Brasil)
	cBar1	:= Substr(cBarraFim,1,3)					//
	//Posição 04-04 = Código de moeda (9 = Real)
	cBar1	+= Substr(cBarraFim,4,1)					//
	//Posição 05-09 = 5 primeiras posições do campo livre (posições 20 a 24 do código de barras)
	cBar1 	+= Substr(cBarraFim,20,5)					// Cinco primeiras posições do Campo Livre
	//Posição 10-10 = Dígito verificador do primeiro campo
	cBar1   += sfDvLD(cBar1)							// Digito verificador da 1º campo da linha digitavel

	//Posição 11-20 = 6ª a 15ª posições do campo livre (posições 25 a 34 do código de barras)
	cBar2	:= Substr(cBarraFim,25,10)					// Posição 6 a 15 do Campo Livre
	//Posição 21-21 = Dígito verificador do segundo campo
	cBar2   += sfDvLD(cBar2)							// Digito verificador do 2º campo da linha digitavel

	//Posição 22-31 = 16ª a 25ª posições do campo livre (posições 35 a 44 do código de barras)
	cBar3   := Substr(cBarraFim,35,10)					// Posicao 16 a 25 do Campo Livre
	//Posição 32-32 = Dígito verificador do terceiro campo
	cBar3   += sfDvLD(cBar3)							// Digito verificador do 3º campo da linha digitavel

	//Posição 33-33 = Dígito verificador geral (posição 5 do código de barras)
	cBar4	:= cDigBarra								// Digito Verificador Codigo Barras

	//Posição 34-37 = Fator de vencimento (posições 6 a 9 do código de barras)
	cBar5   := Substr(cBarraFim,6,4)					//
	//Posição 38-47 = Valor nominal do título (posições 10 a 19 do código de barras)
	cBar5	+= Substr(cBarraFim,10,10)					// Valor do titulo


	cLinha := Substr(cBar1,1,5)  + Substr(cBar1,6,5)
	cLinha += Substr(cBar2,1,5)  + Substr(cBar2,6,6)
	cLinha += Substr(cBar3,1,5) + Substr(cBar3,6,6)
	cLinha += cBar4
	cLinha += cBar5

Return cLinha

//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 05/01/2012
// Nome função: sf_DAC
// Parametros : Codigo a calcular digito verificador do DAC
// Objetivo   : Retornar digito verificador Modulo 11 do Codigo Barras
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sf_DAC(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)

	While .T.
		nSumDv  += Val(Substr(cInCod,nSubr--,1)) * nPeso++
		If nPeso > 9
			nPeso := 2
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,11)
	// Se o resto for igual 0,1 ou 10 o digito será = 1(um)

	If nSumDv > 9   	// Igual a 10
		nSumDv := 1		// Sempre será um
	ElseIf nSumDv <= 1  // Igual a Zero ou Um
		nSumDv := 1 	// Sempre será um
	Else
		nSumDv	:= 11 - nSumDv
	Endif

Return StrZero(nSumDv,1)



//---------------------------------------------------------------------------------------
// Analista   : Marcelo Alberto Lauschner - 05/01/2012
// Nome função: sf320
// Parametros : Codigo a calcular digito verificador
// Objetivo   : Retornar digito verificador Modulo 10 da Linha Digitavel do Banco BicBanco
// Retorno    : Digito Verificador
// Alterações :
//---------------------------------------------------------------------------------------

Static Function sfDvLD(cInCod)

	Local	nSumDv	:= 0
	Local   nPeso	:= 2
	Local   nSubr   := Len(cInCod)
	Local   nResult	:= 0

	While .T.
		nResult := Val(Substr(cInCod,nSubr--,1)) * nPeso++
		// Se o Resultado for maior ou igual a 10 soma os digitos
		If nResult >= 10
			nResult := Val(Substr(StrZero(nResult,2),1,1)) + Val(Substr(StrZero(nResult,2),2,1))
		Endif
		nSumDv += nResult

		If nPeso > 2
			nPeso := 1
		Endif
		If nSubr <= 0
			Exit
		Endif
	Enddo

	nSumDv	:= Mod(nSumDv,10)

	If nSumDv <= 0
		nSumDv := 0
	Else
		nSumDv	:= 10 - nSumDv
	Endif

Return StrZero(nSumDv,1)
