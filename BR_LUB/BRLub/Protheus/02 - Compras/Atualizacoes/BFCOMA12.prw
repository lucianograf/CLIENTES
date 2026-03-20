#Include "Protheus.ch"
#Include "FwCommand.ch"

/*/{Protheus.doc} BFCOMA12
Programa para replicar a inclusão/alteração/exclusão do cadastro do produto nas empresas e filiais informadas no parâmetro.
@author Marcelo Alberto Lauschner
@since 01/11/2018
@version 1.0
@type function
/*/
User Function BFCOMA12()


	sfExec()

Return

Static Function sfExec()

	Local aAreaOld		:= GetArea()
	Local aCopySB1 		:= {}
	Local aFolders		:= {"Erros","Sucesso"}
	Local aResult		:= {}
	Local aSM0To 		:= {}
	Local cTitulo		:= "Resultado do Processamento - "
	Local lResult		:= GetNewPar("BF_COMA12B",.T.) 	//Exibe tela com o resultado do execauto.
	Local nCount		:= 1
	Local nHeight		:= 0
	Local nOpc			:= 0
	Local nWidth		:= 0
	Local oDlg			:= Nil
	Local oFolder		:= Nil
	Local oGetErr		:= Nil
	Local oGetOk		:= Nil
	Local cInIDEmpFil	:= GetNewPar("BF_COMA12A","02=04/")	//Empresas e filiais que será replicado a manutenção do produto.

	If !MsgYesNo("Deseja executar a replicação do cadastro do Produto " + SB1->B1_COD + " para as demais filiais? ","BFCOMA12")
		Return
	Endif

	If Type("INCLUI") == "U"
		Private INCLUI	:= .F.
		Private ALTERA	:= .T.
	Endif

	//	Coleta empresas/filiais para replicar a manuteção do produto.
	aSM0To := GetSM0Dest(cInIDEmpFil)

	If !Empty(aSM0To)
		//		Coleta opção do execauto.
		Do Case
		Case INCLUI
			nOpc := 3
			cTitulo += "Inclusão"
		Case ALTERA
			nOpc := 4
			cTitulo += "Alteração"
		OtherWise
			nOpc := 5
			cTitulo += "Exclusão"
		EndCase

		//		Preenche o array com os dados do produto cadastrado para uso no MsExecAuto().
		DBSelectArea("SB1")
		For nCount := 1 To SB1->(FCount())
			//			Desconsidera alguns campos.
			If !(AllTrim(SB1->(FieldName(nCount))) $ "B1_FILIAL") .And. !Empty(SB1->(FieldGet(nCount)))
				//	Desativa o controle de endereçamento.
				If (AllTrim(SB1->(FieldName(nCount))) $ "B1_LOCALIZ")
					aAdd(aCopySB1,{SB1->(FieldName(nCount)),"N",Nil})
				Else
					aAdd(aCopySB1,{SB1->(FieldName(nCount)),SB1->(FieldGet(nCount)),Nil})
				EndIf
			EndIf
		Next nCount

		//		Ordena array conforme SX3.
		aCopySB1 := FWVetByDic(aCopySB1,"SB1")

		//		Replica manuteção realizada no cadastro de produtos para as demais filiais informadas.

		aResult := StartJob('U_MNTPROD',GetEnvServer(),.T.,aClone(aCopySB1),aSM0To,nOpc,__cUserId,cEmpAnt,cFilAnt) //U_MNTPROD(aClone(aCopySB1),aSM0To,nOpc) //


		If lResult .And. (!Empty(aResult[1]) .Or. !Empty(aResult[2]))
			//			Cria Dialog para apresentar as informações.
			oDlg := TDialog():New(001,001,590,543,cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
			nHeight := 0.465 * oDlg:nClientHeight
			nWidth := 0.493 * oDlg:nClientWidth
			oFolder := TFolder():New(1,1,aFolders,,oDlg,,,,.T.,,nWidth,nHeight)
			//			Processamento com erro.
			oGetErr := TMultiGet():New(0,0,{|u| IIf(PCount() == 0,aResult[1],aResult[1] := u)},oFolder:aDialogs[1],nWidth - 2,nHeight - 14,,,,,,.T.)
			//			Processamento com sucesso.
			oGetOk := TMultiGet():New(0,0,{|u| IIf(PCount() == 0,aResult[2],aResult[2] := u)},oFolder:aDialogs[2],nWidth - 2,nHeight - 14 ,,,,,,.T.)
			//			Ativa Dialog.
			oDlg:Activate()
		EndIf
	EndIf
	RestArea(aAreaOld)

Return

/*/{Protheus.doc} GetSM0Dest
Função para retornar as empresas e filiais para replicar as informações do produto conforme parametrizado.
@author JMPS
@since 18/01/2018
@version 1.0
@param cMV_JMPS001, characters, empresas/filiais.
@type function
/*/
Static Function GetSM0Dest(cMV_JMPS001)

	Local aSM0 		:= FWLoadSM0()
	Local aSM0To	:= {}
	Local nCount	:= 1
	Local nEmp		:= 1
	Local nFil		:= 1

	//	Cria um array com todas as empresas informadas.
	aSM0To := StrTokArr(cMV_JMPS001,"/")
	VarInfo("am0to",aSM0To)
	//	Separa as empresas das filiais.
	For nCount := 1 To Len(aSM0To)
		aSM0To[nCount] := StrTokArr(aSM0To[nCount],"=")
		VarInfo("aSM0To[]",aSM0to[nCount])
		//		Cria um array para cada empresa com suas respectivas filiais informadas.
		aSM0To[nCount][2] := StrTokArr(aSM0To[nCount][2],";")
	Next nCount

	For nEmp := 1 To Len(aSM0To)
		//		Somente seleciona a empresa informada por parâmetro.
		If (AScan(aSM0,{|x| x[SM0_GRPEMP] == aSM0To[nEmp][1]}) > 0)
			For nFil := 1 To Len(aSM0To[nEmp][2])

				//Valida se a filial existe na SM0.
				If (AScan(aSM0,{|x| x[SM0_GRPEMP] == aSM0To[nEmp][1] .And. x[SM0_CODFIL] == aSM0To[nEmp][2][nFil]}) == 0)
					//					Verifica se faz em todas as filiais cadastradas na SM0.
					If aSM0To[nEmp][2][nFil] == '*'
						//						Limpa array para montar novamente apenas com as filiais da empresa.
						aSM0To[nEmp][2] := {}
						AEval(aSM0,{|x| IIf(x[SM0_GRPEMP] == aSM0To[nEmp][1] .And. !(x[SM0_GRPEMP] == cEmpAnt .And. x[SM0_CODFIL] == cFilAnt),aAdd(aSM0To[nEmp][2],x[SM0_CODFIL]),Nil)})
						Loop
					Else
						Help(,,"FilVld",,"Verifique o preenchimento do parâmetro BF_COMA12A, filial informada inválida: " + aSM0To[nEmp][2][nFil] + ".",1,0)
						Break
					EndIf
				EndIf
			Next nFil
		Else
			Help(,,"EmpVld",,"Verifique o preenchimento do parâmetro BF_COMA12A, empresa informada inválida: " + aSM0To[nEmp][1] + ".",1,0)
			Break
		EndIf
	Next nEmp

Return aSM0To

/*/{Protheus.doc} MntProd
Função para cadastrar/alterar/excluir a cópia do produto em cada empresa e filial informada. 
@author JMPS
@since 16/01/2018
@version 1.0
@param aCopySB1, array, dados do produto.
@param aSM0To, array, empresas e filiais para repliar a informação.
@param nOpc, numeric, opção para informar no execauto (3=Inclusão, 4=Alteração e 5=Exclusão).
@type function
/*/
User Function MntProd(aCopySB1,aSM0To,nOpc,cInIdUser,cInEmp,cInFil)

	Local aResult			:= {}
	Local cError			:= ""
	Local cOk				:= ""
	Local nEmp				:= 1
	Local nFil				:= 1
	Local nPosCod			:= AScan(aCopySB1,{|x| x[1] == "B1_COD"})
	Local aVetSB1			:= {}
	Private lMsErroAuto		:= .F.
	Private	lAutoErrNoFile	:= .T.
	Private lMsHelpAuto 	:= .T.

	For nEmp := 1 To Len(aSM0To)
		For nFil := 1 To Len(aSM0To[nEmp][2])
			//			Prepara o ambiente na empresa e filial para realizar a cópia.
			// Não processa a própria empresa e filial 
			If aSM0To[nEmp][1] + aSM0To[nEmp][2][nFil]  <> cInEmp+cInFil
				RPCClearEnv()
				RpcSetType(3)
				RPCSetEnv(aSM0To[nEmp][1],aSM0To[nEmp][2][nFil],cInIdUser)

				__cUserId	:= cInIdUser

				DBSelectArea("SB1")
				SB1->(DBSetOrder(1))

				//Remove os campos que não possuem no dicionário de dados.
				ValidDic(@aCopySB1)

				aVetSB1			:= aClone(aCopySB1)

				Aadd(aVetSB1,{"B1_FILIAL" , xFilial("SB1"),Nil})

				nPosCod			:= AScan(aVetSB1,{|x| Alltrim(x[1]) == "B1_COD"})

				//	Se não for inclusão, pesquisa o cadastro na filial antes de realizar a manutenção.
				If nOpc == 4 .And. !SB1->(DBSeek(xFilial("SB1") + aVetSB1[nPosCod][2]))
					nOpc := 3
				Endif

				If SB1->(DBSeek(xFilial("SB1") + aVetSB1[nPosCod][2])) .And. nOpc == 3
					nOpc := 4
				Endif

				If (nOpc != 3 .And. SB1->(DBSeek(xFilial("SB1") + aVetSB1[nPosCod][2]))) .Or. nOpc == 3
					// Verifica se é alteração mas o produto não existe na filial e altera o tipo de operação para Inclusão
					lMsErroAuto		:= .F.
					Begin Transaction
						VarInfo("aCopySB1",aVetSB1)

						MSExecAuto({|x,y| Mata010(x,y)}, aVetSB1, nOpc)

						//					Se houver erro no ExecAuto, coleta o mesmo para posterior exibição.
						If lMSErroAuto
							DisarmTransaction()
							//						Coleta os erros.
							cError += "Operação: " + cValToChar(nOpc) + " Produto: " +  aVetSB1[nPosCod][2] + CRLF
							cError += "Empresa: " + cEmpAnt + " Filial: " + cFilAnt + CRLF

							AEVal(GetAutoGRLog(),{|x| cError += x + CRLF})
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, cError/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						Else
							cOk += "Empresa: " + cEmpAnt + " Filial: " + cFilAnt + " - " + AllTrim(SB1->B1_COD) + " -> " + AllTrim(SB1->B1_DESC) + CRLF
							FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, cOk/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						EndIf
					End Transaction
				EndIf
			Endif
		Next nFil
	Next nEmp
	RPCClearEnv()
	aResult := {cError,cOk}

Return aResult

/*/{Protheus.doc} ValidDic
Função para remover campos não existentes no dicionário de dados.
@author paulo.silva
@since 03/02/2018
@version 1.0
@param aCopySB1, array, dados do produto.
@type function
/*/
Static Function ValidDic(aCopySB1)

	Local nCount := 1

	For nCount := 1 To Len(aCopySB1)
		If SB1->(FieldPos(aCopySB1[nCount][1])) == 0
			ADel(aCopySB1,nCount)
		EndIf
	Next nCount

Return
