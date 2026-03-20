#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

user function DECAZFL()

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZFL")
	oBrowse:SetDescription('Linha de Produtos')
	oBrowse:Activate()
	
return

Static Function MenuDef()

	Local aRotina := {}
	
	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECAZFL' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECAZFL' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECAZFL' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECAZFL' OPERATION 5 ACCESS 0
	//ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECAZFL' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECAZFL' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZFL := FWFormStruct(1,"ZFL")

	oModel := MPFormModel():New("DECAZFLM")
	oModel:addFields('FORMZFL',,oStruZFL)
	oModel:SetPrimaryKey({'ZFL_FILIAL','ZFL_COD'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Linha de Produtos")
	
	oModel:getModel('FORMZFL'):SetDescription('Formulario de Cadastro de Linha de Produtos')
	
Return oModel

Static Function ViewDef()
	
	Local oModel := ModelDef()//FwLoadModel()   
	Local oView
	Local oStrZFL:= FWFormStruct(2, 'ZFL')
	
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_ZFL',oStrZFL,'FORMZFL' ) 
	oView:CreateHorizontalBox( 'Linha de Produtos', 100)
	oView:SetOwnerView('VIEW_ZFL','Linha de Produtos')
	
Return oView
