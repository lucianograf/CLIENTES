#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "REPORT.CH"
#include "topconn.ch"


/*/{Protheus.doc} MLFATA10
// Rotina de Cadastro de Gestão de Contratos - Grupo Forta
@author Marcelo Alberto Lauschner
@since 22/04/2020
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User Function MLFATA10()

	Private	oBrowse		:= Nil
	Private aRotina		:= MenuDef()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('Z01')

	oBrowse:SetDescription("Gestão Contratos")

	//oBrowse:AddLegend( "Empty(Z01_CHVNFE)" 		, "BR_AZUL"			, "Pedido Faturado"	)
	//oBrowse:AddLegend( "!Empty(ZD0_CHVNFE)" 	, "BR_PRETO"		, "Sem Chave de Acesso NF-e"	)


	oBrowse:SetAttach(.T.)

	oBrowse:Activate()

Return(.T.)

/*/{Protheus.doc} MenuDef
//Função para criar o Menu da aRotina
@author Marcelo Alberto Lauschner 
@since 22/04/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE "Pesquisar"  ACTION 'PesqBrw' 			OPERATION 1	ACCESS 0
	ADD OPTION aRotina TITLE "Visualizar" ACTION 'VIEWDEF.MLFATA10'	OPERATION 2	ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"    ACTION 'VIEWDEF.MLFATA10'	OPERATION 3	ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    ACTION 'VIEWDEF.MLFATA10'	OPERATION 4	ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    ACTION 'VIEWDEF.MLFATA10'	OPERATION 5	ACCESS 0
	ADD OPTION aRotina TITLE "Anexar PDF" ACTION "MsDocument('Z01',Z01->(RecNo()),4)" OPERATION 9	ACCESS 0
	ADD OPTION aRotina TITLE "Legenda"    ACTION 'StaticCall(MLFATA10,sfLegenda)'	OPERATION 1	ACCESS 0
	ADD OPTION aRotina TITLE "Contas Receber"    ACTION 'StaticCall(MLFATA10,sfSE1Mnt)'	OPERATION 1	ACCESS 0




Return (aRotina)



/*/{Protheus.doc} sfLegenda
// Função da Legenda dos Contratos
@author Marcelo Alberto Lauschner 
@since 22/04/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function sfLegenda()

	Local oLegenda := FWLegend():New() // Objeto FwLegend. 

	oLegenda:Add("","BR_VERDE"		,"Em Aberto")
	oLegenda:Add("","BR_AZUL"		,"Finalizado") 
	oLegenda:Add("","BR_PRETO"		,"Sem Faturamento")

	oLegenda:Activate() 
	oLegenda:View() 
	oLegenda:DeActivate() 

Return( Nil )


/*/{Protheus.doc} ModelDef
// Rotina para montar o Model
@author Marcelo Alberto Lauschner
@since 26/05/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function ModelDef()

	Local oModel 		
	Local oStruZD0 		:= FWFormStruct(1,'Z01',/*bAvalCampo*/,/*lViewUsado*/) //monta a estrutra
	Local oStruZD1		:= FWFormStruct(1,'Z02',/*bAvalCampo*/,/*lViewUsado*/) //monta a estrutra
	Local bPosValidacao := {|oMdl|sfVldPos(oMdl)}		//Validacao da tela
	Local bCommit		:= {|oMdl|sfGrvComt(oMdl)}		//Gravacao dos dados
	Local bPre			:= {|oModelGrid, nLine, cAction, cField, nNewValue, nOldValue| sfVldPre(oModelGrid, nLine, cAction, cField, nNewValue, nOldValue)}
	Local aTrigger		:= {}

	oModel 		:= MPFormModel():New('MODEL_MLFATA10',{|oModel| sfVldModel(oModel)}/*bPreValidacao*/,bPosValidacao,bCommit,/*bCancel*/)

	oModel:AddFields('Z01MASTER', /*cOwner*/,oStruZD0, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )



	aTrigger := FwStruTrigger("Z02_PRODUT", "Z02_DESCRI", 'Posicione("SB1",1,XFILIAL("SB1")+M->Z02_PRODUT,"B1_DESC")')
	oStruZD1:AddTrigger(aTrigger[1], aTrigger[2], aTrigger[3], aTrigger[4])

	oModel:AddGrid( 'Z02DETAIL','Z01MASTER',oStruZD1,/*bLinePre*/,/*bLinePost*/, /*bPreVal*/, /*bPosVal*/)

	oModel:SetRelation( 'Z02DETAIL',{{'Z02_FILIAL','xFilial("Z02")'},{'Z02_NUM','Z01_NUM'}} ,'Z02_FILIAL+Z02_NUM') 	// relacionamento do cabeçãlho com os itens

	oModel:SetDescription("Manutenção de Contratos de Clientes")

	oModel:SetPrimaryKey( { "Z01_FILIAL", "Z01_NUM"} ) // chave unica de registro

	oModel:AddCalc( 'CALC_TOTAL', 'Z01MASTER', 'Z02DETAIL', 'Z02_VLRINV', 'Z02_TBRUT' , 'SUM',  ,,'R$ Total Contrato' )



	oModel:SetVldActivate( { |oModel| sfVldActive( oModel ) } )


Return(oModel)



/*/{Protheus.doc} ViewDef
// Rotina para montar o View 
@author Marcelo Alberto Lauschner
@since 26/05/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function ViewDef()

	Local oView

	Local aCposZ01	:= {}
	Local aCposZ02	:= {"Z02_ITEM","Z02_PRODUT","Z02_DESCRI","Z02_CBASE","Z02_ATFITE","Z02_QUANT","Z02_VLRINV","Z02_PEDSKF"}
	Local oModel  	:= FWLoadModel('MLFATA10')
	Local oStruZ01 	:= FWFormStruct(2,'Z01')
	Local oStruZ02  := FWFormStruct(2,'Z02' , {|cCampo| aScan(aCposZ02 , Alltrim(cCampo)) > 0})
	Local oCalc		:= Nil

	oCalc		:= FWCalcStruct(oModel:GetModel("CALC_TOTAL"))		

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('VIEW_Z01', oStruZ01, 'Z01MASTER' )

	oView:AddGrid('VIEW_Z02' , oStruZ02, "Z02DETAIL") 
	oView:AddField("VIEW_T_ORC", oCalc, "CALC_TOTAL")
	oView:AddIncrementField("VIEW_Z02", "Z02_ITEM")

	oView:CreateHorizontalBox('SUPERIOR', 50 )
	oView:CreateHorizontalBox("MEIO", 40)
	oView:CreateHorizontalBox("TOTAL", 10)


	oView:SetOwnerView('VIEW_Z01','SUPERIOR' )
	oView:SetOwnerView('VIEW_Z02','MEIO')

	oView:SetOwnerView("VIEW_T_ORC", "TOTAL")
	oView:AddUserButton("Imprimir TReport","",{|oView| print(oView)})

Return oView



/*/{Protheus.doc} Print
// Efetua a impressão do formulário dos registros posicionados
@author Marcelo Alberto Lauschner 
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param oView, object, descricao
@type function
/*/
Static Function Print(oView)

	Local oModel := oView:GetModel()
	Local oReport

	oReport := oModel:ReportDef()
	oReport:PrintDialog()

Return


/*/{Protheus.doc} sfVldActive
// Validação do Formulário 
@author Marcelo Alberto Lauschner 
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param oModel, object, descricao
@type function
/*/
Static Function sfVldActive(oModel)

	Local	lRet	:= .T. 

	If oModel:GetOperation()==MODEL_OPERATION_INSERT
		lRet	:= .T. 
	ElseIf oModel:GetOperation()==MODEL_OPERATION_UPDATE  
		//	lRet	:= .F. 
		//	MsgInfo("Alteração no Sistema! ",FunName()+"."+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	ElseIf oModel:GetOperation()==MODEL_OPERATION_DELETE
		//lRet	:= .F. 
		//MsgInfo("Exclusão não permitida! ",FunName()+"."+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	Endif


Return lRet


/*/{Protheus.doc} sfVldPre
// Validação pré abertura do formulário 
@author Marcelo Alberto Lauschner
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param oModelGrid, object, descricao
@param nLinha, numeric, descricao
@param cAcao, characters, descricao
@param cField, characters, descricao
@param nNewValue, numeric, descricao
@param nOldValue, numeric, descricao
@type function
/*/
Static Function sfVldPre(oModelGrid, nLinha, cAcao, cField, nNewValue, nOldValue)

	Local aDA1			:= {}
	Local nSaldo		:= 0
	Local nNewLine	 	:= 0
	Local lOk			:= .T.
	Local oModel		:= FWModelActive()



Return lOk



/*/{Protheus.doc} sfVldModel
// Função para validar o Model
@author Marcelo Alberto Lauschner
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param oModel, object, descricao
@type function
/*/
Static Function sfVldModel(oModel)
	Local	lRet	:= .T. 

	If oModel:GetOperation()==MODEL_OPERATION_INSERT
		lRet	:= .T. 
	ElseIf oModel:GetOperation()==MODEL_OPERATION_UPDATE // .And. oModel:GetModel('ZD0MASTER'):GetValue("ZD0_CHVNFE") <> " "
		//lRet	:= .F. 
		//MsgInfo("Alteração não permitida pois a Ordem de Serviço tem processos posteriores à sua Inclusão/Alteração no Sistema! ",FunName()+"."+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	ElseIf oModel:GetOperation()==MODEL_OPERATION_DELETE //.And. !oModel:GetModel('ZD0MASTER'):GetValue("ZD0_CHVNFE") <> " "
		//lRet	:= .F. 
		//MsgInfo("Exclusão não permitida pois a Ordem de Serviço tem processos posteriores à sua Inclusão no Sistema! ",FunName()+"."+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	Endif


Return lRet


/*/{Protheus.doc} sfVldPos
// Função Pós Validação
@author marce
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param oMdl, object, descricao
@type function
/*/
Static Function sfVldPos(oMdl)

	Local lRet			:= .T.
	Local nOperation	:= oMdl:GetOperation()
	Local oMdlZD11  	:= oMdl:GetModel('Z02DETAIL')
	Local nX := 0

	If nOperation == 3 .OR. nOperation == 4

		For nX := 1 To oMdlZD11:GetQtdLine()
			oMdlZD11:GoLine(nX)
			If oMdlZD11:IsEmpty() .AND. !oMdlZD11:IsDeleted()
				Help(" ",1,"OBRIGAT")  //valida se os campos obrigatorios nao tem conteudo
				lRet := .F.
			Endif
		Next nX


	ElseIf nOperation == 5
		If oMdl:GetModel('Z01MASTER'):GetValue("Z01_DTINI") < dDataBase
			ShowHelpDlg("Exclusão de Contrato",{"Exclusão de Contrato não permitido."},1,{"O status não permite mais exclusão pois a data de vigência já foi iniciada."},1)
			lRet :=	.F.
		Endif
		Return(lRet)
	Endif

Return lRet


/*/{Protheus.doc} sfGrvComt
// Efetua gravação do formulário 
@author Marcelo Alberto Lauschner
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param oMdl, object, descricao
@type function
/*/
Static Function sfGrvComt(oMdl) //salva as informações

	Local lRet		 := .T.
	Local nOperation := oMdl:GetOperation()

	If nOperation == 3 .OR. nOperation == 4

		FWModelActive(oMdl)
		FWFormCommit(oMdl)

		If nOperation == 3
			// Grava Log
			//sfGrvLog(/*cInNum*/,"1"/*cInTpEven*/,/*cInUser*/)
			sfSE1Mnt(nOperation) // Chama tela de Títulos
		ElseIf nOperation == 4
			// Grava Log
			//sfGrvLog(/*cInNum*/,Iif(lModoMec,"6","7")/*cInTpEven*/,/*cInUser*/)
			sfSE1Mnt(nOperation) // Chama a tela de títulos
		Endif


	EndIf

	If nOperation == 5
		// Grava Log
		//sfGrvLog(/*cInNum*/,"G"/*cInTpEven*/,/*cInUser*/)
		MsDocument("Z01", Z01->( RecNo()),2,,3)

		FWModelActive(oMdl)
		FWFormCommit(oMdl)

		sfSE1Mnt(nOperation) // Chama a tela de títulos

	EndIf


Return(lRet)


/*/{Protheus.doc} sfGrvLog
// Rotina de Gravação de Log se necessário 
@author Marcelo Alberto Lauschner 
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param cInNum, characters, descricao
@param cInTpEven, characters, descricao
@param cInUser, characters, descricao
@type function
/*/
Static Function sfGrvLog(cInNum,cInTpEven,cInUser)

	Local	aAreaOld	:= GetArea()

	Default	cInNum		:= ""
	Default	cInTpEven	:= " "
	Default	cInUser		:= cUserName

	RestArea(aAreaOld)

Return 



/*/{Protheus.doc} sfGrvSE1
// Rotina de gravação dos títulos a Receber 
@author Marcelo Alberto Lauscner 
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfGrvSE1(nOpc)

	Local	aTitulo 	:= {}
	Local	nX 
	Local	nPxPrefixo	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_PREFIXO"})
	Local	nPxNum		:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_NUM"})
	Local	nPxTipo		:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_TIPO"})
	Local	nPxParc		:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_PARCELA"})
	Local	nPxCodCli	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_CLIENTE"})
	Local	nPxLojCli	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_LOJA"})
	Local	nPxNaturez	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_NATUREZ"})
	Local	nPxEmissao	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_EMISSAO"})
	Local	nPxVencto	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_VENCTO"})
	Local	nPxValor	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_VALOR"})
	Local	nPxNrBco	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_NUMBCO"})
	Local	nPxBaixa	:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_BAIXA"})
	Local	nPxHist		:= aScan(oCtaRec:aHeader,{|x| AllTrim(x[2]) == "E1_HIST"})
	Local	nContSE1	:= 0
	Local	cE1Num		:= ""
	Local	lRet		:= .T.
	Default	nOpc		:= 2 
	Private	LMSERROAUTO	:= .F. 
	Private lMsHelpAuto := .F.

	If nOpc == 2 .Or. Z01->Z01_GERACR <> "1"
		Return lRet
	Endif

	For nX := 1 To Len(oCtaRec:aCols)


		lMsHelpAuto := .F.

		cE1Num	:= oCtaRec:aCols[nX,nPxNum]	

		// Somente as linhas que não foram marcadas como deletadas 

		aTitulo	:= {;
		{"E1_FILIAL"	, xFilial("SE1")						, 	Nil},;
		{"E1_PREFIXO"	, oCtaRec:aCols[nX,nPxPrefixo]			,	Nil},;
		{"E1_NUM"		, oCtaRec:aCols[nX,nPxNum]				, 	Nil},;
		{"E1_PARCELA"	, oCtaRec:aCols[nX,nPxParc]				,   Nil},;
		{"E1_TIPO"		, oCtaRec:aCols[nX,nPxTipo]				,	Nil},;
		{"E1_NATUREZ"	, oCtaRec:aCols[nX,nPxNaturez]			,	Nil},;
		{"E1_CLIENTE"	, oCtaRec:aCols[nX,nPxCodCli]			,	Nil},;
		{"E1_LOJA"		, oCtaRec:aCols[nX,nPxLojCli]			,	Nil},;
		{"E1_EMISSAO"	, oCtaRec:aCols[nX,nPxEmissao]			,	Nil},;
		{"E1_VENCTO"	, oCtaRec:aCols[nX,nPxVencto]			,	Nil},;
		{"E1_VALOR"		, oCtaRec:aCols[nX,nPxValor]			,	Nil},;
		{"E1_HIST" 		, oCtaRec:aCols[nX,nPxHist]				, 	Nil}}
		
		// Se inclusão e registro não deletado na tela
		// Se Alteração, registro não deletado e existente já na SE1
		// Se Exclusão e sem data de baixa
		If (nOpc == 3 .And. !(oCtaRec:aCols[nX][Len(oCtaRec:aHeader)+1]) ) .Or.;
		 	(nOpc == 4 .And. !(oCtaRec:aCols[nX][Len(oCtaRec:aHeader)+1]) ) .Or.;
		 	 nOpc == 5 .And. Empty(oCtaRec:aCols[nX,nPxBaixa])
		 	
		 	// Se for uma alteração mas tiver um novo registro efetua inclusão 
		 	If oCtaRec:aCols[nX,nPosRec] > 0 .And. nOpc == 4
		 		MsExecAuto({|x,y| FINA040(x,y)}, aTitulo, 3)
		 	Else
		 		MsExecAuto({|x,y| FINA040(x,y)}, aTitulo, nOpc)
			Endif
			
			If lMsErroAuto
				lRet	:= .F. 
				MostraErro()
				Exit
			Else
				//MsgInfo("Gravação de título Ok." + cHisTit)
				nContSE1++
				oCtaRec:aCols[nX][Len(oCtaRec:aHeader)+1] := .T.
			EndIf
		Endif
	Next 

	// Se houve atualização de títulos grava o número do título no controle da Z01
	If nContSE1 > 0 .And. nOpc == 3
		DbSelectArea("Z01")
		RecLock("Z01",.F.)
		Z01->Z01_E1NUM	:= cE1Num
		MsUnlock()
	Endif

Return lRet 


/*/{Protheus.doc} sfSE1Mnt
// Rotina de interface para montagem dos títulos 
@author Marcelo Alberto Lauschner 
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfSE1Mnt(nOpc)

	Local 		aCpoHead  	:= {"E1_VENCTO","E1_VALOR","E1_HIST"}	// Campos Editáveis 
	Local		aHeadSE1	:= {}
	Local		aColsSE1	:= {}
	Local		aButton		:= {}
	Private		lEscape		:= .F. 
	Private		nPosRec		:= 0

	Define MsDialog oDlgApur From 001,001 TO 500,1300 Of oMainWnd Pixel Title OemToAnsi("Consulta e Geração de Títulos a Receber por Contrato de Locação" + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))

	oDlgApur:lMaximized 	:= .T.

	// Cria panel superior 

	Private oPaneDados := TPanel():New(0,0,"",oDlgApur,,.F.,.F.,,,200,200,.T.,.F.)
	oPaneDados:align := CONTROL_ALIGN_ALLCLIENT

	sfHeadSE1(@aHeadSE1)

	Private oCtaRec  := MsNewGetDados():New(090,010,(oPaneDados:nHeight),240,GD_UPDATE+GD_DELETE,"AllwaysTrue()","AllwaysTrue",/*inicpos*/,aCpoHead,/*freeze*/,120,"AllwaysTrue()",/*superdel*/,/*delok*/,oPaneDados,aHeadSE1,aColsSE1)
	oCtaRec:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	sfaColsSE1(aHeadSE1)

	Activate MsDialog oDlgApur Centered On Init (EnchoiceBar(oDlgApur,{|| Processa({|| IIf(sfGrvSE1(nOpc) , eval({|| (lEscape := .T., oDlgApur:End() ,  lExecute := .T. ) }),lExecute := .F.) },"Processando...")	},{|| lEscape := .T., oDlgApur:End()},,aButton),oDlgApur:Refresh()) Valid lEscape

Return 



/*/{Protheus.doc} sfAcolsSE1
//Função para montagem do vetor aCols do Contas a receber 
@author Marcelo Alberto Lauschner
@since 31/05/2020
@version 1.0
@return ${return}, ${return_description}
@param aHeadSE2, array, descricao
@param aColsSE2, array, descricao
@type function
/*/
Static Function sfAcolsSE1()

	Local	aCondVcto	:= {}
	Local	nY,nZ
	Local	cParcela 	:= ""
	Local	cNumContr	:= Padr(IIf(!Empty(Z01->Z01_E1NUM),Z01->Z01_E1NUM,Z01->Z01_NUM),TamSX3("E1_NUM")[1])
	Local	cCodCli		:= Z01->Z01_CLIENT
	Local	cLojCli		:= Z01->Z01_LOJA
	Local	dDtIni		:= Z01->Z01_DTINI
	Local	cVend1		:= Z01->Z01_VEND1
	Local	cTipoSE1	:= Padr("DP",TamSX3("E1_TIPO")[1])
	Local	cPrefSE1	:= Padr(" ",TamSX3("E1_PREFIXO")[1])
	Local	nQteMeses	:= Z01->Z01_NMESES
	Local	nVlrPar		:= Z01->Z01_VLRPAR
	Local	dDtVencto	:= Z01->Z01_VCTO01
	Local	nDiaVencto	:= Z01->Z01_DIAVCT
	Local	dDtAux		:= Z01->Z01_VCTO01
	Local	cNatSE1		:= ""
	Local	cHistSE1	:= ""
	Local	nRecSE1		:= 0
	Local	cNumBco		:= ""

	oCtaRec:aCols	:= {}
	cParcela 	:= Iif(nQteMeses > 1 ,Padr("000",TamSX3("E1_PARCELA")[1]) , Space(TamSX3("E1_PARCELA")[1]) )

	For nZ := 1 To nQteMeses
		Aadd( oCtaRec:aCols,Array(Len(oCtaRec:aHeader)+1))
		cParcela := MaParcela(cParcela)

		DbSelectArea("SE1")
		DbSetOrder(1) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		If DbSeek(xFilial("SE1")+ cPrefSE1 + cNumContr + cParcela + cTipoSE1)
			cHistSE1	:= Alltrim(SE1->E1_HIST) + IIf(!Empty(SE1->E1_BAIXA),"Data Baixa: " + DTOC(SE1->E1_BAIXA),"")
			cNatSE1		:= SE1->E1_NATUREZ
			nRecSE1		:= SE1->(Recno())
			cNumBco		:= SE1->E1_NUMBCO
		Else
			cHistSE1	:= "PARCELA "+cParcela +" DE " + cValToChar(nQteMeses) + " - CONTRATO NUMERO " + cNumContr
			cNatSE1		:= "4001"
			nRecSE1		:= 0	
			cNumBco		:= ""
		Endif

		For nY := 1 To Len(oCtaRec:aHeader)
			If IsHeadRec(oCtaRec:aHeader[nY][2])
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := nRecSE1
				nPosRec	:= nY
			ElseIf IsHeadAlias(oCtaRec:aHeader[nY][2])
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := "SE1"
			ElseIf oCtaRec:aHeader[nY][2] == "E1_PREFIXO"
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	cPrefSE1
			ElseIf oCtaRec:aHeader[nY][2] == "E1_CLIENTE"
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] :=	cCodCli
			ElseIf oCtaRec:aHeader[nY][2] == "E1_LOJA   "
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] :=	cLojCli
			ElseIf oCtaRec:aHeader[nY][2] == "E1_NUM    "
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	cNumContr
			ElseIf oCtaRec:aHeader[nY][2] == "E1_PARCELA"
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] :=	cParcela
			ElseIf oCtaRec:aHeader[nY][2] == "E1_TIPO   "
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] :=	cTipoSE1
			ElseIf oCtaRec:aHeader[nY][2] == "E1_HIST   "
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] :=	cHistSE1
			ElseIf oCtaRec:aHeader[nY][2] == "E1_NATUREZ"
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	cNatSE1
			ElseIf oCtaRec:aHeader[nY][2] == "E1_NUMBCO "
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	cNumBco
			ElseIf oCtaRec:aHeader[nY][2] == "E1_VENCTO "
				If nZ == 1
					dDtAux 	:= dDtVencto
				Else
					//dDtAux	:= LastDay(dDtAux)+1	// Soma 1 dia ao último dia da data salva no item anterior
					dDtAux	:= MonthSum(dDtVencto,nQteMeses) //STOD(Substr(DTOS(dDtAux),1,6) + StrZero(nDiaVencto,2)) 
				Endif
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	Iif(nRecSE1 > 0,SE1->E1_VENCTO , dDtAux)
			ElseIf oCtaRec:aHeader[nY][2] == "E1_EMISSAO"
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	Iif(nRecSE1 > 0,SE1->E1_EMISSAO , dDtIni)
			ElseIf oCtaRec:aHeader[nY][2] == "E1_VALOR  "
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	Iif(nRecSE1 > 0,SE1->E1_VALOR , nVlrPar)
			ElseIf oCtaRec:aHeader[nY][2] == "E1_SALDO  "
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] := 	Iif(nRecSE1 > 0,SE1->E1_SALDO , nVlrPar)
			Else
				oCtaRec:aCols[Len(oCtaRec:aCols)][nY] :=  CriaVar(oCtaRec:aHeader[nY,2])
			EndIf
		Next nY
		oCtaRec:aCols[Len(oCtaRec:aCols)][Len(oCtaRec:aHeader)+1] := .F.


	Next nZ 
	oCtaRec:oBrowse:Refresh()

Return 




/*/{Protheus.doc} sfHeadSE1
//Função para montagem do vetor aHeader do contas a Receber
@author Marcelo Alberto Lauschner 
@since 27/05/2020
@version 1.0
@return ${return}, ${return_description}
@param aHeadSE2, array, descricao
@type function
/*/
Static Function sfHeadSE1(aHeadSE1)

	aHeadSE1	:= {}
	aColsSE1	:= {}

	dbSelectArea("SX3")
	dbSetOrder(2)

	MsSeek("E1_CLIENTE")
	AADD(aHeadSE1,{ TRIM(x3titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".F.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_LOJA")
	AADD(aHeadSE1,{ TRIM(x3titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".F.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_NATUREZ")
	AADD(aHeadSE1,{ TRIM(x3titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".F.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_PREFIXO")
	AADD(aHeadSE1,{ TRIM(x3titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".F.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_NUM")
	AADD(aHeadSE1,{ TRIM(x3titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".F.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_PARCELA")
	AADD(aHeadSE1,{ TRIM(x3titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".F.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_TIPO")
	AADD(aHeadSE1,{ TRIM(x3titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".F.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_EMISSAO")
	AADD(aHeadSE1,{ TRIM(X3Titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".T.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_VENCTO")
	AADD(aHeadSE1,{ TRIM(X3Titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	"M->E1_VENCTO>=M->dDataBase",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_VALOR")
	AADD(aHeadSE1,{ TRIM(X3Titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	"Positivo()",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_SALDO")
	AADD(aHeadSE1,{ TRIM(X3Titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	"Positivo()",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_HIST")
	AADD(aHeadSE1,{ TRIM(X3Titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	30,;//SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".T.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})

	MsSeek("E1_NUMBCO")
	AADD(aHeadSE1,{ TRIM(X3Titulo()),;
	SX3->X3_CAMPO,;
	SX3->X3_PICTURE,;
	SX3->X3_TAMANHO,;
	SX3->X3_DECIMAL,;
	".T.",;
	SX3->X3_USADO,;
	SX3->X3_TIPO,;
	SX3->X3_F3,;
	SX3->X3_CONTEXT,;
	SX3->X3_CBOX,;
	SX3->X3_RELACAO,;
	".T."})


	AADD( aHeadSE1, { "Alias WT","SE1_ALI_WT", "", 09, 0,, SX3->X3_USADO, "C", "SE1", "V"} )
	AADD( aHeadSE1, { "Recno WT","SE1_REC_WT", "", 09, 0,, SX3->X3_USADO, "N", "SE1", "V"} )

Return 

