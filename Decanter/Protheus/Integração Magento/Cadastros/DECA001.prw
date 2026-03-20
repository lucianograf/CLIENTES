#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

/*{Protheus.doc} DCT001
//Constroi Modelo 1 do MVC para geração de tela de cadastro de UVAS.
@author luis.balsini
@since 03/05/2019
@version 1.0
*/


user function DECA001()

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("Z01")
	oBrowse:SetDescription('Uva')
	oBrowse:Activate()
	
return

Static Function MenuDef()

	Local aRotina := {}
	
	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECA001' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECA001' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECA001' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECA001' OPERATION 5 ACCESS 0
	//ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECA001' OPERATION 8 ACCESS 0
	//ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECA001' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZ01 := FWFormStruct(1,"Z01")

	oModel := MPFormModel():New("DECA001M")
	oModel:addFields('FORMZ01',,oStruZ01)
	oModel:SetPrimaryKey({'Z01_FILIAL','Z01_CODIGO'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Uvas")
	
	oModel:getModel('FORMZ01'):SetDescription('Formulario de Cadastro de Uvas')
	
Return oModel

Static Function ViewDef()
	
	Local oModel := ModelDef()//FwLoadModel()   
	Local oView
	Local oStrZ01:= FWFormStruct(2, 'Z01')
	
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_Z01',oStrZ01,'FORMZ01' ) 
	oView:CreateHorizontalBox( 'UVA', 100)
	oView:SetOwnerView('VIEW_Z01','UVA')
	
Return oView