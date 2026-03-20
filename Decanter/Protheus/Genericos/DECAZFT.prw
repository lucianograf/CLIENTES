#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

user function DECAZFT()

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZFT")
	oBrowse:SetDescription('Ficha Tecnica')
	oBrowse:Activate()

return

Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECAZFT' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECAZFT' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECAZFT' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECAZFT' OPERATION 5 ACCESS 0
	//ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECAZFT' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECAZFT' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZFT := FWFormStruct(1,"ZFT")

	oModel := MPFormModel():New("DECAZFTM")
	oModel:addFields('FORMZFT',,oStruZFT)
	oModel:SetPrimaryKey({'ZFT_FILIAL','ZFT_COD'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Ficha Tecnica")

	oModel:getModel('FORMZFT'):SetDescription('Formulario de Cadastro de Ficha Tecnica')
	//FWFORMMODEL():SetDeActivate([ bBloco ])-> NIL
	//FWFORMMODEL():SetVldActivate([ bBloco ])-> NIL
	//FWFORMMODEL():SetCommit     ([ bBloco ], [ lAcumula ])-> NIL
	oModel:SetCommit( { |oModel| MOD1ACT( oModel ) },.T. )

Return oModel

Static Function MOD1ACT( oModel )  // Passa o model sem dados

	Local lRet       := .T.
	Local nOperation := oModel:GetOperation()

	If cValtoChar(nOperation) $ "4#3#9"
		RecLock( "ZFT",.F.)
		ZFT->ZFT_LOGALT := cUsername
		ZFT->ZFT_DTALT := dDataBase
		MsUnLock()
	EndIf

Return lRet


Static Function ViewDef()

	Local oModel := ModelDef()//FwLoadModel()
	Local oView
	Local oStrZFT:= FWFormStruct(2, 'ZFT')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_ZFT',oStrZFT,'FORMZFT' )
	oView:CreateHorizontalBox( 'Ficha Tecnica', 100)
	oView:SetOwnerView('VIEW_ZFT','Ficha Tecnica')


Return oView
