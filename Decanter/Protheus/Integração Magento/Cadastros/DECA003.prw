#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

/*{Protheus.doc} DECA003
//Constroi Modelo 1 do MVC para geração de tela de cadastro de produtor.
@author luis.balsini
@since 03/05/2019
@version 1.0
/*/


user function DECA003()
	
	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("Z03")
	oBrowse:SetDescription('Produtor')
	oBrowse:Activate()
	
return

Static Function MenuDef()

	Local aRotina := {}
	
	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECA003' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECA003' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECA003' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECA003' OPERATION 5 ACCESS 0
	//ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECA003' OPERATION 8 ACCESS 0
	//ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECA003' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZ03 := FWFormStruct(1,"Z03")

	oModel := MPFormModel():New("DECA003M")
	oModel:addFields('FORMZ03',,oStruZ03)
	oModel:SetPrimaryKey({'Z03_FILIAL','Z03_CODIGO'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Produtor")
	
	oModel:getModel('FORMZ03'):SetDescription('Formulario de Cadastro de Produtor')
	
Return oModel

Static Function ViewDef()
	
	Local oModel := ModelDef()//FwLoadModel()   
	Local oView
	Local oStrZ03:= FWFormStruct(2, 'Z03')
	
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_Z03',oStrZ03,'FORMZ03' ) 
	oView:CreateHorizontalBox( 'Produtor', 100)
	oView:SetOwnerView('VIEW_Z03','Produtor')
	
Return oView