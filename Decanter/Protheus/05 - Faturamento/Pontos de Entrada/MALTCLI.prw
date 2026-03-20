#Include 'totvs.ch'
#Include "FWMVCDEF.ch"

/*/{Protheus.doc} MALTCLI
MALTCLI - Executado na alteração do cadastro de clientes
Automatizar o cadastro de classe de valor, baseado na alteração do cliente
@type function
@version 1.0
@author TSC681 - Thiago Mota
@since 23/06/2014
/*/
User Function MALTCLI(nInOper)

	Local		aCpoRep		:= {}
	Local 		aRet		:= {.F.,"Sem Execução"}
	Default		nInOper		:= 0
	// Cria automaticamente a classe de valor
	U_AUTOCLVL( "C", SA1->A1_COD, SA1->A1_LOJA )

	// Integração Máxima
	If GetNewPar("DC_INMAXOK",.F.)
		U_XFLAG("SA1")
	Endif
//
	//Atualiza data de alteração do cadastro

	RecLock('SA1',.F.)
	SA1->A1_DECDATA := dDataBase
	SA1->(MsUnlock())


	// Se for a Empresa 01-Decanter e apenas na Inclusão - Chama replicação de cadastro.
	If cEmpAnt == "01" .And. ((nInOper == 0  .And. !GetMv("MV_MVCSA1")) .Or. (nInOper == 4 .And. GetMv("MV_MVCSA1")))

		Aadd(aCpoRep,{"A1_CGC"		, SA1->A1_CGC		,Nil	})
		Aadd(aCpoRep,{"A1_COD"		, SA1->A1_COD		,Nil	})
		Aadd(aCpoRep,{"A1_LOJA"		, SA1->A1_LOJA		,Nil 	})
		Aadd(aCpoRep,{"A1_PESSOA"	, SA1->A1_PESSOA	,Nil 	})
		Aadd(aCpoRep,{"A1_NOME"		, SA1->A1_NOME 		,Nil 	})
		Aadd(aCpoRep,{"A1_CEP"		, SA1->A1_CEP		,Nil  	})
		Aadd(aCpoRep,{"A1_END"		, SA1->A1_END 		,Nil 	})
		Aadd(aCpoRep,{"A1_COMPLEM"	, SA1->A1_COMPLEM	,Nil 	})
		Aadd(aCpoRep,{"A1_NREDUZ"	, SA1->A1_NREDUZ 	,Nil 	})
		Aadd(aCpoRep,{"A1_BAIRRO"	, SA1->A1_BAIRRO	,Nil 	})
		Aadd(aCpoRep,{"A1_TIPO"		, SA1->A1_TIPO		,Nil 	})
		Aadd(aCpoRep,{"A1_EST"		, SA1->A1_EST		,Nil 	})
		Aadd(aCpoRep,{"A1_COD_MUN"	, SA1->A1_COD_MUN	,Nil 	})
		Aadd(aCpoRep,{"A1_MUN"		, SA1->A1_MUN		,Nil 	})
		Aadd(aCpoRep,{"A1_REGIAO"	, SA1->A1_REGIAO	,Nil 	})
		Aadd(aCpoRep,{"A1_DSCREG"	, SA1->A1_DSCREG	,Nil 	})
		Aadd(aCpoRep,{"A1_NATUREZ"	, SA1->A1_NATUREZ	,Nil	})
		Aadd(aCpoRep,{"A1_DDD"		, SA1->A1_DDD		,Nil 	})
		Aadd(aCpoRep,{"A1_DDI"		, SA1->A1_DDI		,Nil 	})
		Aadd(aCpoRep,{"A1_TEL"		, SA1->A1_TEL		,Nil 	})
		Aadd(aCpoRep,{"A1_CONTATO"	, SA1->A1_CONTATO 	,Nil 	})
		Aadd(aCpoRep,{"A1_INSCR"	, SA1->A1_INSCR		,Nil 	})
		Aadd(aCpoRep,{"A1_PAIS"		, SA1->A1_PAIS		,Nil 	})
		Aadd(aCpoRep,{"A1_INSCRM"	, SA1->A1_INSCRM	,Nil 	})
		Aadd(aCpoRep,{"A1_COMIS"	, SA1->A1_COMIS		,Nil 	})
		Aadd(aCpoRep,{"A1_VEND"		, SA1->A1_VEND		,Nil	})
		Aadd(aCpoRep,{"A1_CONTA"	, SA1->A1_CONTA		,Nil 	})
		Aadd(aCpoRep,{"A1_TRANSP"	, SA1->A1_TRANSP	,Nil 	})
		Aadd(aCpoRep,{"A1_TPFRET"	, SA1->A1_TPFRET	,Nil 	})
		Aadd(aCpoRep,{"A1_COND"		, SA1->A1_COND		,Nil 	})
		Aadd(aCpoRep,{"A1_RISCO"	, SA1->A1_RISCO		,Nil 	})
		Aadd(aCpoRep,{"A1_SUFRAMA"	, SA1->A1_SUFRAMA	,Nil 	})
		Aadd(aCpoRep,{"A1_RG"		, SA1->A1_RG		,Nil 	})
		Aadd(aCpoRep,{"A1_OBSERV"	, SA1->A1_OBSERV	,Nil 	})
		Aadd(aCpoRep,{"A1_DTNASC"	, SA1->A1_DTNASC	,Nil 	})
		Aadd(aCpoRep,{"A1_CODPAIS"	, SA1->A1_CODPAIS	,Nil 	})
		Aadd(aCpoRep,{"A1_EMAIL"	, SA1->A1_EMAIL		,Nil 	})
		Aadd(aCpoRep,{"A1_CNAE"		, SA1->A1_CNAE		,Nil 	})
		Aadd(aCpoRep,{"A1_CONDPAG"	, SA1->A1_CONDPAG	,Nil 	})
		Aadd(aCpoRep,{"A1_OBS"		, SA1->A1_OBS		,Nil 	})
		Aadd(aCpoRep,{"A1_MSBLQL"	, SA1->A1_MSBLQL	,Nil 	})
		Aadd(aCpoRep,{"A1_HRCAD"	, SA1->A1_HRCAD		,Nil 	})
		Aadd(aCpoRep,{"A1_DTCAD"	, SA1->A1_DTCAD		,Nil 	})
		Aadd(aCpoRep,{"A1_CLIPRI"	, SA1->A1_CLIPRI	,Nil 	})
		Aadd(aCpoRep,{"A1_LOJPRI"	, SA1->A1_LOJPRI	,Nil 	})
		Aadd(aCpoRep,{"A1_SIMPLES"	, SA1->A1_SIMPLES	,Nil 	})
		Aadd(aCpoRep,{"A1_CONTRIB"	, SA1->A1_CONTRIB	,Nil 	})
		Aadd(aCpoRep,{"A1_SIMPNAC"	, SA1->A1_SIMPNAC	,Nil 	})
		Aadd(aCpoRep,{"A1_ZVEND2"	, SA1->A1_ZVEND2	,Nil 	})
		Aadd(aCpoRep,{"A1_ZCOMIS2"	, SA1->A1_ZCOMIS2	,Nil 	})
		Aadd(aCpoRep,{"A1_ZBOLETO"	, SA1->A1_ZBOLETO	,Nil 	})
		Aadd(aCpoRep,{"A1_ZERACOM"	, SA1->A1_ZERACOM	,Nil 	})
		Aadd(aCpoRep,{"A1_IENCONT"	, SA1->A1_IENCONT	,Nil 	})
		If SA1->(FieldPos("A1_MENSAGE")) > 0
			Aadd(aCpoRep,{"A1_MENSAGE"	, SA1->A1_MENSAGE	,Nil 	})
		Endif

		Aadd(aCpoRep,{"A1_ZPARCMI"	, SA1->A1_ZPARCMI	,Nil 	})
		Aadd(aCpoRep,{"A1_ZPEDMIN"	, SA1->A1_ZPEDMIN	,Nil 	})
		Aadd(aCpoRep,{"A1_GRPVEN"	, SA1->A1_GRPVEN	,Nil 	})
		Aadd(aCpoRep,{"A1_ZAUTO"	, SA1->A1_ZAUTO		,Nil 	})
		Aadd(aCpoRep,{"A1_ZMENNOT"	, SA1->A1_ZMENNOT	,Nil 	})


		// Replica somente para a Empresa 02 - Hermann
		MsgRun( "Replicando cadastro, aguarde...", "Replicação de Cadastro", {|| aRet := StartJob("U_DCREPCLI",GetEnvServer(),.T.,"02","0201",SA1->A1_COD,SA1->A1_LOJA,aCpoRep) } )

		If !aRet[1]
			MsgAlert(aRet[2],"Replicação de Cadastro.")
		Endif
	Endif

Return .t.

/*/{Protheus.doc} DCREPCLI
description
@type function
@version  
@author Marcelo Alberto Lauschner
@since 17/02/2021
@param cInEmp, character, Código da Empresa 
@param cInFil, character, Código da Filial 
@param cInCod, character, Código do Cliente 
@param cInloja, character, Loja do Cliente 
@param aVetSA1, array, Vetor com valores da SA1
@return return_type, return_description
/*/
User Function DCREPCLI(cInEmp,cInFil,cInCod,cInloja,aVetSA1)


	Local	nOpc			:= 3
	Local 	lRet			:= .F.
	Local 	cMensagem		:= ""
	Local 	nX
	Local 	aLog

	Private lMSErroAuto		:= .F.
	PRIVATE lAutoErrNoFile 	:= .T.

	RpcSetType(3)
	RPCSetEnv(cInEmp,cInFil,/*cUsrLog*/,/*cPswLog*/,/*cEnvMod*/,"MATA030"/*cFunName*/,{"SX2","SM0","C00","SF1"}/*aTables*/,/*lShowFinal*/,/*lAbend*/,.T./*lOpenSX*/)

	FwLogMsg('INFO',; 		// cSeverity
	,;				//cTransactionId
	'M030INC',;		//cGroup
	FunName(),;		//cCategory
	'',;			//cStep
	"",;			//cMsgId
	"Replicação de Cadastro de Cliente via StartJob Empresa " + cInEmp + "  / Filial " + cInFil,;//cMessage
	0,;				//nMensure
	0,;				//nElapseTime
	{})				//aMessage

	Sleep(5 * 1000) // Tempo para abertura


	DbSelectArea("SA1")
	DbSetOrder(1)
	If DbSeek(xFilial("SA1") + cInCod+cInloja)
		nOpc		:= 4
		nLenVetA1	:= Len(aVetSA1)
		aDel(aVetSA1,1) // Elimina a posição do CGC
		aSize(aVetSA1,nLenVetA1-1)
		nLenVetA1	:= Len(aVetSA1)
	Endif

	Begin Transaction

		MSExecAuto({|x,y|MATA030(x,y)},aVetSA1,nOpc)

		If lMSErroAuto

			If !IsBlind()
				MostraErro()
			Else
				cMensagem	:= "Não houve replicação de cadastro" + CRLF
				aLog := GetAutoGRLog()
				For nX := 1 To Len(aLog)
					cMensagem += aLog[nX]+CHR(13)+CHR(10)
				Next nX
			Endif
			ConOut(cMensagem)

			DisarmTransaction()
			If __lSx8
				RollBackSX8()
			Endif
		Else
			If __lSx8
				ConfirmSx8()
			EndIf
			lRet	:= .T.
		EndIf
	End Transaction

	RpcClearEnv()

Return {lRet,cMensagem}


/*/{Protheus.doc} CRMA980
Ponto de entrada do Cadastro de Clientes MVC 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 17/02/2021
@return return_type, return_description
/*/
User Function CRMA980()

	Local aParam     := PARAMIXB
	Local xRet       := .T.
	Local oObj       := ""
	Local cIdPonto   := ""
	Local cIdModel   := ""
	Local lIsGrid    := .F.
	Local nLinha     := 0
	Local nQtdLinhas := 0
	Local cMsg       := ""
	Local nOp

	If (aParam <> NIL)
		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
		lIsGrid := (Len(aParam) > 3)

		nOpc := oObj:GetOperation() // PEGA A OPERAÇÃO

		If (cIdPonto == "MODELPOS")
			cMsg := "Chamada na validação total do modelo." + CRLF
			cMsg += "ID " + cIdModel + CRLF
			IF nOp == 3
				Alert('inclusão')
			ENDIF
			If nOp == 3
				U_MALTCLI(nOp)
			Endif
			//xRet := MsgYesNo(cMsg + "Continua?")
		ElseIf (cIdPonto == "MODELVLDACTIVE")
			cMsg := "Chamada na ativação do modelo de dados."

			//xRet := MsgYesNo(cMsg + "Continua?")
		ElseIf (cIdPonto == "FORMPOS")
			cMsg := "Chamada na validação total do formulário." + CRLF
			cMsg += "ID " + cIdModel + CRLF

			If (lIsGrid == .T.)
				cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
				cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
			Else
				cMsg += "É um FORMFIELD" + CRLF
			EndIf


			//xRet := MsgYesNo(cMsg + "Continua?")
		ElseIf (cIdPonto =="FORMLINEPRE")
			If aParam[5] =="DELETE"
				cMsg := "Chamada na pré validação da linha do formulário." + CRLF
				cMsg += "Onde esta se tentando deletar a linha" + CRLF
				cMsg += "ID " + cIdModel + CRLF
				cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
				cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF

				//xRet := MsgYesNo(cMsg + " Continua?")
			EndIf
		ElseIf (cIdPonto =="FORMLINEPOS")
			cMsg := "Chamada na validação da linha do formulário." + CRLF
			cMsg += "ID " + cIdModel + CRLF
			cMsg += "É um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
			cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF

			//xRet := MsgYesNo(cMsg + " Continua?")
		ElseIf (cIdPonto =="MODELCOMMITTTS")
			//MsgInfo("Chamada após a gravação total do modelo e dentro da transação.")
            /*
            Integração com CRM Simples
            */
            IF cEmpAnt == "02" .and. cFilAnt == "0204"
                // Inclusão ou Alteracao
                If nOpc == 3 .or. nOpc == 4 
                    FwMsgRun(NIL, {|| U_PTCRM903(nOpc)}, "Aguarde", "Processando integração com CRM")
                EndIf
            Endif
            /*
            FIM Integração com CRM Simples
            */
		ElseIf (cIdPonto =="MODELCOMMITNTTS")
			//MsgInfo("Chamada após a gravação total do modelo e fora da transação.")
			U_MALTCLI(4) // Passa como se fosse alteração para sempre verificar se tem cadastro no destino
		ElseIf (cIdPonto =="FORMCOMMITTTSPRE")
			//MsgInfo("Chamada após a gravação da tabela do formulário.")
		ElseIf (cIdPonto =="FORMCOMMITTTSPOS")
			//MsgInfo("Chamada após a gravação da tabela do formulário.")
		ElseIf (cIdPonto =="MODELCANCEL")
			cMsg := "Deseja realmente sair?"

			//xRet := MsgYesNo(cMsg)
		ElseIf (cIdPonto =="BUTTONBAR")
			//xRet := {{"Botão", "BOTÃO", {|| MsgInfo("Buttonbar")}}}

			xRet	:= { {"Consulta Receita","AMARELO",{|| sfReceita() }} }

		EndIf
	EndIf
Return (xRet)




/*/{Protheus.doc} sfReceita
//Função que verifica via HTTPS os dados do cadastro do CNPJ 
@author Marcelo Alberto Lauschner
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfReceita()

	// Variável Caractere
	Local	cUrlRec		:=	'https://www.receitaws.com.br/v1/cnpj/' + M->A1_CGC
	Local	cJsonRet	:=  HttpGet(cUrlRec)
	Local	cQry
	Local	cVarAux
	Local	oModelA1 	:= FWModelActive()
	// Variável Lógica
	Local	lRetCep		:= .F.
	// Variável Objeto
	Private oParseJSON 	:= Nil

	FWJsonDeserialize(cJsonRet, @oParseJSON)

	If Type("oParseJSON:situacao") <> "U"
		If oParseJSON:situacao <> "ATIVA"
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
				{"CNPJ com Situação Cadastral diferente de 'Ativa'."},;
				5,;
				{"Dados devem ser preenchidos manualmente se necessário fazer o cadastro."},;
				5)
			Return
		Endif
	Else
		ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
			{"Erro na chamada. Retorno: "+cJsonRet},;
			5,;
			{"Efetue o cadastro do cliente manualmente a partir da consulta no Sintegra!"},;
			5)
		Return
	Endif

	If Type("oParseJSON:status") <> "U"
		If oParseJSON:status <> "OK"
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
				{"CNPJ com Status diferente de 'OK'."},;
				5,;
				{"Dados devem ser preenchidos manualmente se necessário fazer o cadastro."},;
				5)
			Return
		Endif

	Endif

	//If oModelA1 <> Nil .And. oModelA1:GetModel('SA2MASTER') <> Nil
	//	oModelA1:GetModel('SA2MASTER'):SetValue('A2_XCCPASV',cA2XCCPASV)
	//Endif
	//If Type("M->A2_XCCPASV") == "C"
	//	M->A2_XCCPASV	:= cA2XCCPASV
	//Endif


	If Type("oParseJSON:nome") <> "U"
		M->A1_NOME	:= Padr(NoAcento(Upper(oParseJSON:nome)),TamSX3("A1_NOME")[1])

		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_NOME',M->A1_NOME)
		Endif
	Endif

	If Type("oParseJSON:fantasia") <> "U"
		M->A1_NREDUZ	:= Padr(NoAcento(Upper(oParseJSON:fantasia)),TamSX3("A1_NREDUZ")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_NREDUZ',M->A1_NREDUZ)
		Endif
	Endif

	If Type("oParseJSON:email") <> "U"
		M->A1_EMAIL	:= Padr(oParseJSON:email,TamSX3("A1_EMAIL")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_EMAIL',M->A1_EMAIL)
		Endif
	Endif

	If Type("oParseJSON:cep") <> "U"
		M->A1_CEP	:= Padr(StrTran(StrTran(oParseJSON:cep,".",""),"-",""),TamSX3("A1_CEP")[1])
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_CEP',M->A1_CEP)
		Endif
		//lRetCep	    := Se necessário criar uma regra própria para preenchimetno do CEP
		// Aciona gatilhos do campo CEP
		If ExistTrigger('A1_CEP')
			RunTrigger(1,nil,nil,,'A1_CEP')
		Endif
	Endif


	If Type("oParseJSON:abertura") <> "U"
		M->A1_DTNASC	:= CTOD(oParseJSON:abertura)
		If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
			oModelA1:GetModel('SA1MASTER'):SetValue('A1_DTNASC',M->A1_DTNASC)
		Endif
	Endif

	// Se a validação do CEP não ocorreu, preenche os dados a partir da RECEITA
	If !lRetCep
		If Type("oParseJSON:logradouro") <> "U"
			M->A1_END	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= M->A1_END
			M->A1_ENDENT	:= M->A1_END
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
		Endif

		If Type("oParseJSON:numero") <> "U"
			cVarAux		:= Alltrim(M->A1_END)
			M->A1_END	:= Padr(cVarAux + "," + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= M->A1_END
			M->A1_ENDENT	:= M->A1_END
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
		Endif

		If Type("oParseJSON:bairro") <> "U"
			M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
			M->A1_BAIRROE	:= M->A1_BAIRRO
			M->A1_BAIRROC	:= M->A1_BAIRRO
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRRO',M->A1_BAIRRO)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROE',M->A1_BAIRRO)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROC',M->A1_BAIRRO)
			Endif
		Endif

		If Type("oParseJSON:complemento") <> "U"
			M->A1_COMPLEM	:= Padr(NoAcento(Upper(oParseJSON:complemento)),TamSX3("A1_COMPLEM")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_COMPLEM',M->A1_COMPLEM)
			Endif
		Endif

		If Type("oParseJSON:municipio") <> "U"
			M->A1_MUN	:= Padr(NoAcento(Upper(oParseJSON:municipio)),TamSX3("A1_MUN")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_MUN',M->A1_MUN)
			Endif
		Endif

		If Type("oParseJSON:uf") <> "U"
			M->A1_EST	:= Padr(NoAcento(Upper(oParseJSON:uf)),TamSX3("A1_EST")[1])
			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_EST',M->A1_EST)
			Endif
		Endif

		cQry := "SELECT CC2_CODMUN "
		cQry += "  FROM " + RetSqlName("CC2")
		cQry += " WHERE D_E_L_E_T_ =' ' "
		cQry += "   AND CC2_EST = '"+oParseJSON:uf+"' "
		cQry += "   AND CC2_MUN LIKE '%"+ oParseJSON:municipio + "%' "
		cQry += "   AND CC2_FILIAL = '"+xFilial("CC2") + "' "

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBLEXIST",.T.,.T.)
		If TBLEXIST->(!Eof())
			M->A1_COD_MUN	:=  TBLEXIST->CC2_CODMUN
		Endif
		TBLEXIST->(DbCloseArea())

	Else
		If Type("oParseJSON:numero") <> "U"
			cVarAux			:= Alltrim(M->A1_END)
			If Empty(cVarAux)
				If Type("oParseJSON:logradouro") <> "U"
					cVarAux	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
				Endif
			Endif
			M->A1_END		:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
			M->A1_ENDCOB	:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_ENDCOB")[1])
			M->A1_ENDENT	:= Padr(Alltrim(cVarAux) + ", " + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_ENDENT")[1])

			If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_END',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDCOB',M->A1_END)
				oModelA1:GetModel('SA1MASTER'):SetValue('A1_ENDENT',M->A1_END)
			Endif
			cVarAux			:= Alltrim(M->A1_BAIRRO)

			If Empty(cVarAux) .And. Type("oParseJSON:bairro") <> "U"
				M->A1_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1])
				M->A1_BAIRROE	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROE")[1])
				M->A1_BAIRROC	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRROC")[1])
				If oModelA1 <> Nil .And. oModelA1:GetModel('SA1MASTER') <> Nil
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRRO',M->A1_BAIRRO)
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROE',M->A1_BAIRRO)
					oModelA1:GetModel('SA1MASTER'):SetValue('A1_BAIRROC',M->A1_BAIRRO)
				Endif
			Endif

		Endif
	Endif
Return


/*/{Protheus.doc} sfAjust
//Ajusta o texto do JSON 
@author Marcelo Alberto Lauschneer
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}
@param cInChar, characters, descricao
@param lOutJson, logical, descricao
@type function
/*/
Static Function sfAjust(cInChar,lOutJson)

	Local	cOut		:= DecodeUTF8(cInChar, "iso8859-1")
	Local	aOut		:= {}
	Local	nO
	Default lOutJson	:= .F.
	Aadd(aOut,{"á","\u00e1","a"})
	Aadd(aOut,{"à","\u00e0","a"})
	Aadd(aOut,{"â","\u00e2","a"})
	Aadd(aOut,{"ã","\u00e3","a"})
	Aadd(aOut,{"ä","\u00e4","a"})
	Aadd(aOut,{"Á","\u00c1","a"})
	Aadd(aOut,{"À","\u00c0","a"})
	Aadd(aOut,{"Â","\u00c2","a"})
	Aadd(aOut,{"Ã","\u00c3","a"})
	Aadd(aOut,{"Ä","\u00c4","a"})
	Aadd(aOut,{"é","\u00e9","e"})
	Aadd(aOut,{"è","\u00e8","e"})
	Aadd(aOut,{"ê","\u00ea","e"})
	Aadd(aOut,{"ê","\u00ea","e"})
	Aadd(aOut,{"É","\u00c9","e"})
	Aadd(aOut,{"È","\u00c8","e"})
	Aadd(aOut,{"Ê","\u00ca","e"})
	Aadd(aOut,{"Ë","\u00cb","e"})
	Aadd(aOut,{"í","\u00ed","i"})
	Aadd(aOut,{"ì","\u00ec","i"})
	Aadd(aOut,{"î","\u00ee","i"})
	Aadd(aOut,{"ï","\u00ef","i"})
	Aadd(aOut,{"Í","\u00cd","i"})
	Aadd(aOut,{"Ì","\u00cc","i"})
	Aadd(aOut,{"Î","\u00ce","i"})
	Aadd(aOut,{"Ï","\u00cf","i"})
	Aadd(aOut,{"ó","\u00f3","o"})
	Aadd(aOut,{"ò","\u00f2","o"})
	Aadd(aOut,{"ô","\u00f4","o"})
	Aadd(aOut,{"õ","\u00f5","o"})
	Aadd(aOut,{"ö","\u00f6","o"})
	Aadd(aOut,{"Ó","\u00d3","o"})
	Aadd(aOut,{"Ò","\u00d2","o"})
	Aadd(aOut,{"Ô","\u00d4","o"})
	Aadd(aOut,{"Õ","\u00d5","o"})
	Aadd(aOut,{"Ö","\u00d6","o"})
	Aadd(aOut,{"ú","\u00fa","u"})
	Aadd(aOut,{"ù","\u00f9","u"})
	Aadd(aOut,{"û","\u00fb","u"})
	Aadd(aOut,{"ü","\u00fc","u"})
	Aadd(aOut,{"Ú","\u00da","u"})
	Aadd(aOut,{"Ù","\u00d9","u"})
	Aadd(aOut,{"Û","\u00db","u"})
	Aadd(aOut,{"ç","\u00e7","c"})
	Aadd(aOut,{"Ç","\u00c7","c"})
	Aadd(aOut,{"ñ","\u00f1","n"})
	Aadd(aOut,{"Ñ","\u00d1","n"})
	Aadd(aOut,{"&","\u0026"," "})
	Aadd(aOut,{"'","\u0027"," "})
	Aadd(aOut,{"´","\u00b4"," "})
	Aadd(aOut,{Chr(13),"\u0013"," "})
	Aadd(aOut,{Chr(10),"\u0010"," "})
	//ConOut("+------------------------------------+")
	//ConOut(cOut)
	If lOutJson
		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,2])
		Next nO

	Else
		cOut	:= DecodeUTF8(cOut)
		//ConOut(cOut)

		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,3])
		Next nO

		cOut	:= Alltrim(Upper(cOut))
	Endif
	//ConOut(cInChar)
	//ConOut(cOut)
	//ConOut("+++------------------------------------+")

Return cOut

