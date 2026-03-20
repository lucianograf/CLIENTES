#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

user function DECA004()

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("Z04")
	oBrowse:SetDescription('Classificação')
	oBrowse:Activate()
	
return

Static Function MenuDef()

	Local aRotina := {}
	
	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECA004' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECA004' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECA004' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECA004' OPERATION 5 ACCESS 0
	//ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECA001' OPERATION 8 ACCESS 0
	//ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECA001' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZ04 := FWFormStruct(1,"Z04")

	oModel := MPFormModel():New("DECA004M")
	oModel:addFields('FORMZ04',,oStruZ04)
	oModel:SetPrimaryKey({'Z04_FILIAL','Z04_CODIGO'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Classificação de bebidas")
	
	oModel:getModel('FORMZ04'):SetDescription('Formulario de Cadastro de Classificação de bebidas')
	
Return oModel

Static Function ViewDef()
	
	Local oModel := ModelDef()//FwLoadModel()   
	Local oView
	Local oStrZ04:= FWFormStruct(2, 'Z04')
	
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_Z04',oStrZ04,'FORMZ04' ) 
	oView:CreateHorizontalBox( 'Classificacao', 100)
	oView:SetOwnerView('VIEW_Z04','Classificacao')
	
Return oView