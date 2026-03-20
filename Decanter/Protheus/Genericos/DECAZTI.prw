#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

user function DECAZTI()

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZTI")
	oBrowse:SetDescription('Transportadora Inteligente')
	oBrowse:Activate()
	
return

Static Function MenuDef()

	Local aRotina := {}
	
	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECAZTI' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECAZTI' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECAZTI' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECAZTI' OPERATION 5 ACCESS 0
	//ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECAZTI' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECAZTI' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZTI := FWFormStruct(1,"ZTI")

	oModel := MPFormModel():New("DECAZTIM")
	oModel:addFields('FORMZTI',,oStruZTI)
	oModel:SetPrimaryKey({'ZTI_FILIAL','ZTI_COD'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Transportadora Inteligente")
	
	oModel:getModel('FORMZTI'):SetDescription('Formulario de Cadastro de Transportadora Inteligente')
	
Return oModel

Static Function ViewDef()
	
	Local oModel := ModelDef()//FwLoadModel()   
	Local oView
	Local oStrZTI:= FWFormStruct(2, 'ZTI')
	
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_ZTI',oStrZTI,'FORMZTI' ) 
	oView:CreateHorizontalBox( 'Transportadora Inteligente', 100)
	oView:SetOwnerView('VIEW_ZTI','Transportadora Inteligente')
	
Return oView