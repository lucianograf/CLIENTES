#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

/*{Protheus.doc} DTC002
//Constroi Modelo 1 do MVC para geração de tela de cadastro de região.
@author luis.balsini
@since 03/05/2019
@version 1.0
/*/


user function DECA002()
	
	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("Z02")
	oBrowse:SetDescription('Região')
	oBrowse:Activate()
	
return

Static Function MenuDef()

	Local aRotina := {}
	
	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECA002' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECA002' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECA002' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECA002' OPERATION 5 ACCESS 0
	//ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECA002' OPERATION 8 ACCESS 0
	//ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECA002' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZ02 := FWFormStruct(1,"Z02")

	oModel := MPFormModel():New("DECA002M")
	oModel:addFields('FORMZ02',,oStruZ02)
	oModel:SetPrimaryKey({'Z02_FILIAL','Z02_CODIGO'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Região")
	
	oModel:getModel('FORMZ02'):SetDescription('Formulario de Cadastro de Região')
	
Return oModel

Static Function ViewDef()
	
	Local oModel := ModelDef()//FwLoadModel()   
	Local oView
	Local oStrZ02:= FWFormStruct(2, 'Z02')
	
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_Z02',oStrZ02,'FORMZ02' ) 
	oView:CreateHorizontalBox( 'Regiao', 100)
	oView:SetOwnerView('VIEW_Z02','Regiao')
	
Return oView