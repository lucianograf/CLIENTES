#include 'protheus.ch'
#include 'topconn.ch'

/*/{Protheus.doc} XMLCTE24
// Ponto de entrada para adicionar botões na tela da Central XML
// Este ponto de entrada deve ser usado em conjunto com o XMLCTE07 ( Adiciona botões no vetor aButton que vai para a rotina Outras Ações )
@author Marcelo Alberto Lauschner
@since 03/08/2019
@version 1.0
@return Nil
@type User Function
/*/
User function XMLCTE24()

	Local	cInObj		:= ParamIxb[1]
	Local	oInObj		:= ParamIxb[2]
	Local	aAreaOld	:= GetArea()

	// Grupo Documento Entrada
	If cInObj == 'DOC'

		// Grupo Relatórios
	ElseIf cInObj == 'REL'
		// Grupo Consultas
	ElseIf cInObj == 'CON'
		// Grupo Exportar
	ElseIf cInObj == 'EXP'
		//If !lSuperUsr // Se não for usuário do tipo Fiscal ainda assim permite opção de exportar XMLs
		// Adiciona botão de exportar
		Private oBtnExp11 := TMenuItem():New(oInObj, "Exportar Xml posicionado"	 , , , ,{|| Processa({||stExpXml(),"Gerando exportação dos dados...."})}, , , , , , , , , .T. )
		oInObj:add(oBtnExp11)
		
		Private oBtnExp12 := TMenuItem():New(oInObj, "Exp.XML CTe p/GFE"	 , , , ,{|| Processa({||U_GFEXPGFE(),"Gerando exportação dos dados...."})}, , , , , , , , , .T. )
		oInObj:add(oBtnExp12)

		//Endif
	Endif

	RestArea(aAreaOld)

Return
/*/{Protheus.doc} stExpXml
Função para exportar o XML posicionado 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/09/2022
@return variant, return_description
/*/
Static Function stExpXml()

	cLocDir	:= cGetFile("",OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Selecione Diretório"),0,"c:\temp\",.T.,GETF_RETDIRECTORY+GETF_LOCALHARD,.F.,)

	If Empty(cLocDir)
		oArqXml:SetFocus()
		Return
	Endif

	If !MsgYesNo("Deseja realmente exportar o arquivo XML para o diretório informado?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Exportação de XML´s")
		oArqXml:SetFocus()
		Return
	Endif

	U_MLDBSLCT("CONDORXML",.F.,1)
	If DbSeek(aArqXml[oArqXml:nAt,nPosChvNfe])
		MemoWrite(cLocDir+Alltrim(aArqXml[oArqXml:nAt,nPosChvNfe])+".xml",CONDORXML->XML_ARQ)

		If !Empty(CONDORXML->XML_ATT2)
			MemoWrite(cLocDir+Alltrim(aArqXml[oArqXml:nAt,nPosChvNfe])+".pdf",CONDORXML->XML_ATT2)
		Endif

	Else
		MsgAlert("Não encontrou o arquivo da Chave '"+Alltrim(aArqXml[oArqXml:nAt,nPosChvNfe])+"' para gerar o arquivo XML",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" A T E N Ç Ã O!! ")
	Endif

	shellExecute("Open", cLocDir, "", cLocDir, 1 )

	U_MLDBSLCT("CONDORXML",.F.,1)
	DbSeek(aArqXml[oArqXml:nAt,nPosChvNfe])
	oArqXml:SetFocus()

Return

/*/{Protheus.doc} U_GFEXPGFE
Função pra exportar XMLs de CTEs para integração no GFE 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 21/09/2022
@return variant, return_description
/*/
Function U_GFEXPGFE()

	Local 	aRet 		:= {} 
	Local 	cExpAlias	
	Local 	aAreaOld	:= GetArea()
	Local 	nQteXml		:= 0 
	Local	nContXml 	:= 0 
	Local 	aRestPerg	:= {} 
	Local 	aPergs		:= {} 
	
	aRestPerg	:= U_MLXRTPGR(.T./*lSalvaPerg*/,/*aPerguntas*/,/*nTamSx1*/)

	//aPutMvPar	:= {{"02",CTOD("30/06/2022")},{"04","CT-e"}}
	Aadd(aPergs,{1,"Emissão de"		,dDataBase									,""		,"","",".T.",50,.T.})
	Aadd(aPergs,{1,"Emissão até"	,dDataBase									,""		,"","",".T.",50,.T.})
	Aadd(aPergs,{1,"Fornecedor de"	,Space(TamSX3("F1_FORNECE")[1])     		,""		,"","SA2XML"   ,".T.",70,.F.})
	Aadd(aPergs,{1,"Fornecedor Até"	,Replicate("Z",TamSX3("F1_FORNECE")[1]) 	,""		,"","SA2XML"   ,".T.",70,.T.})	
	Aadd(aPergs,{6,"Diretório"		,Space(50)									,""		,""		,""		,50	,.T.,""	,"",GETF_RETDIRECTORY+GETF_LOCALHARD})
	//MLPRMBOX(cInPergunte,aParametros,cTitle,aRet,bOk,aPutMvPar,lAutomato,nPosx,nPosy, oDlgWizard, cLoad, lCanSave,lUserSave,aHelpPerg)
	If U_MLPRMBOX(,aPergs,"Exportação de arquivos XMLs",@aRet,/*bOk*/,/*aPutMvPar*/,.F./*lAutomato*/,,,,"BFEXPGFE",.T.,.T.)
		
		If Empty(MV_PAR05)			
			If Type("oArqXml") <> "U"
				oArqXml:SetFocus()
			Endif 
			Return
		Endif
		If !MsgYesNo("Deseja realmente exportar os arquivos XML de todas as notas filtradas nesta tela para o diretório informado?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Exportação de XML´s")
			If Type("oArqXml") <> "U"
				oArqXml:SetFocus()
			Endif 
			Return
		Endif

		cQry := "SELECT XM.R_E_C_N_O_ AS XMLRECNO ,XML_CHAVE ,XML_NUMNF "
		cQry += "  FROM CONDORXML XM, "+RetSqlName("SA2") + " A2 "
		cQry += " WHERE A2.D_E_L_E_T_ = ' ' "
		cQry += "   AND A2_COD BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
		cQry += "   AND A2_CGC = XML_EMIT "
		cQry += "   AND XML_EMIT != ' ' "
		cQry += "   AND A2_FILIAL = '"+xFilial("SA2")+"' "
		cQry += "   AND XM.D_E_L_E_T_ = ' ' "
		cQry += "   AND XML_REJEIT = ' ' "
		cQry += "   AND XML_EMISSA BETWEEN '" + DTOS(MV_PAR01) + "' AND '" + DTOS(MV_PAR02) + "' "
		cQry += "   AND XML_DEST = '"+SM0->M0_CGC + "' " // Filial posicionada 
		cQry += "   AND NOT EXISTS (SELECT F1_DOC " 
		cQry += "                     FROM " + RetSqlName("SF1") + " F1 "
		cQry += "                    WHERE F1.D_E_L_E_T_ = ' ' "
		cQry += "                      AND F1_CHVNFE = XML_CHAVE "
		cQry += "                      AND F1_FILIAL = '" + xFilial("SF1") + "' )"
		cQry += "   AND XML_TIPODC IN('T') " // Somente Frete Cif 
		cQry += "   AND XML_VLRDOC > 0.01 " // Acima de 1 Centavo 
		
		cExpAlias	:= GetNextAlias()

		TcQuery cQry New Alias (cExpAlias)

		Count To nQteXml

		ProcRegua(nQteXml)

		(cExpAlias)->(DbGotop())

		While (cExpAlias)->(!Eof())

			U_MLDBSLCT("CONDORXML",.F.,1)
			DbGoto((cExpAlias)->XMLRECNO)
			nContXml++

			IncProc("Exportando "+Alltrim(Str(nContXml))+" / "+Alltrim(Str(nQteXml) ) )
			If CONDORXML->XML_EMISSA > CTOD("01/05/2022")
				MemoWrite(Alltrim(MV_PAR05)+Alltrim((cExpAlias)->XML_CHAVE)+".xml",CONDORXML->XML_ATT3)
			Else
				MemoWrite(Alltrim(MV_PAR05)+Alltrim((cExpAlias)->XML_CHAVE)+".xml",CONDORXML->XML_ARQ)
			Endif

			If !Empty(CONDORXML->XML_ATT2)
				MemoWrite(Alltrim(MV_PAR05)+Alltrim((cExpAlias)->XML_CHAVE)+".pdf",CONDORXML->XML_ATT2)
			Endif

			DbSelectArea(cExpAlias)
			DbSkip()
		Enddo
		(cExpAlias)->(DbCloseArea())

		shellExecute("Open", Alltrim(MV_PAR05), "", Alltrim(MV_PAR05), 1 )

		If FwIsInCallStack("U_XMLCTE24") .And. Type("oArqXml") <> "U"
			U_MLDBSLCT("CONDORXML",.F.,1)
			DbSeek(aArqXml[oArqXml:nAt,nPosChvNfe])
			oArqXml:SetFocus()
		Endif 
	Endif
	U_MLXRTPGR(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)

	RestArea(aAreaOld)

Return
