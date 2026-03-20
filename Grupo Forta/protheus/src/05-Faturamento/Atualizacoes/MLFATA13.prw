#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "REPORT.CH"
#include "topconn.ch"


/*/{Protheus.doc} MLFATA13
// Rotina de Cadastro de Gestão de Contratos - Grupo Forta
@author Marcelo Alberto Lauschner
@since 22/04/2020
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User Function MLFATA13()
	Private	oBrowse		:= Nil
	Private aRotina		:= MenuDef()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('ZZ5')

	oBrowse:SetDescription("Gestão Produtos Unificados")

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
	ADD OPTION aRotina TITLE "Visualizar" ACTION 'VIEWDEF.MLFATA13'	OPERATION 2	ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"    ACTION 'VIEWDEF.MLFATA13'	OPERATION 3	ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    ACTION 'VIEWDEF.MLFATA13'	OPERATION 4	ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    ACTION 'VIEWDEF.MLFATA13'	OPERATION 5	ACCESS 0

Return (aRotina)



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
	Local oStruZZ5		:= FWFormStruct(1,'ZZ5',/*bAvalCampo*/,/*lViewUsado*/) //monta a estrutra
	Local bPosValidacao := {|oMdl|sfVldPos(oMdl)}		//Validacao da tela
	Local bCommit		:= {|oMdl|sfGrvComt(oMdl)}		//Gravacao dos dados

	oModel 		:= MPFormModel():New('MODEL_MLFATA13',{|oModel| sfVldModel(oModel)}/*bPreValidacao*/,bPosValidacao,bCommit,/*bCancel*/)

	oModel:AddFields('ZZ5MASTER', /*cOwner*/,oStruZZ5, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	oModel:SetPrimaryKey( { "ZZ5_FILIAL", "ZZ5_CODUNI","ZZ5_PROC","ZZ5_LOJPRO"} ) // chave unica de registro

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

	Local oModel  	:= FWLoadModel('MLFATA13')
	Local oStruZZ5 	:= FWFormStruct(2,'ZZ5')
	

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('VIEW_ZZ5', oStruZZ5, 'ZZ5MASTER' )

	
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
	ElseIf oModel:GetOperation()==MODEL_OPERATION_UPDATE 
		//MsgInfo("Alteração não permitida pois a Ordem de Serviço tem processos posteriores à sua Inclusão/Alteração no Sistema! ",FunName()+"."+ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	ElseIf oModel:GetOperation()==MODEL_OPERATION_DELETE 
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
	
		ElseIf nOperation == 4
	
		Endif
	EndIf

	If nOperation == 5
		FWModelActive(oMdl)
		FWFormCommit(oMdl)	
	EndIf


Return(lRet)

