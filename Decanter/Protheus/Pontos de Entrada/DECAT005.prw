#include 'totvs.ch'
#include 'PROTHEUS.CH'
#include 'FWMVCDEF.CH'
#Include 'TBICONN.CH'
#Include 'COLORS.CH'
#Include "FWMBROWSE.CH"
#Include "RWMAKE.CH"

//Variveis Estaticas
Static cTitulo := "Item(s) Excluído(s) do pedido de venda"
Static cAliasMVC := "ZZO"

/*/{Protheus.doc} User Function DECAT005
Itens Excluido do Pedido de Vendas
@author Jonivani Pereira
@since 04/11/2023
@version 2210
@type function
/*/

User Function DECAT005()
	Local oBrowse                  as object
    Local aArea     := FWGetArea() as array
	Private aRotina := {}          as array

	//Definicao do menu
	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAliasMVC)
	oBrowse:SetDescription(cTitulo)
	//oBrowse:DisableDetails()
	//oBrowse:DisableReport()

	//Adicionando as Legendas
	oBrowse:AddLegend( "ZZO->ZZO_STATUS == '1' .AND. empty(ZZO->ZZO_DTENV)" , "RED"   , "Digitando" )
	oBrowse:AddLegend( "ZZO->ZZO_STATUS == '2' .AND. empty(ZZO->ZZO_DTENV)" , "YELLOW", "Pendente" )
	oBrowse:AddLegend( "ZZO->ZZO_STATUS == '3' .AND. !empty(ZZO->ZZO_DTENV)", "GREEN" , "Finalizado" )
	//oBrowse:AddLegend( "ZZO->ZZO_STATUS == '2' .AND. ZZO->ZZO_ENVMAI == '2' .AND. empty(ZZO->ZZO_DTENV)", "BLUE" , "Não Enviar E-mail" )

	//Ativa a Browseb
	oBrowse:Activate()

	FWRestArea(aArea)
Return Nil


/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao DECAT005
@author Jonivani Pereira
@since 04/11/2023
@version 2210
@type function
/*/

Static Function MenuDef()
	Local aRotina := {} as array

	//Adicionando opcoes do menu
	//ADD OPTION aRotina TITLE "Pesquisar"  ACTION "AxPesqui"          OPERATION 1 ACCESS 0 
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.DECAT005" OPERATION 1 ACCESS 0
	//ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.DECAT005" OPERATION 3 ACCESS 0
	//ADD OPTION aRotina TITLE "Alterar" 	  ACTION "VIEWDEF.DECAT005" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.DECAT005"  OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE "Legendas"   ACTION "U_DEC05LEG()"     OPERATION 6 ACCESS 0

Return aRotina

/*/{Protheus.doc} DECFATLEG
	Legenda de dos itens
	@type  Function
	@author Jonivani Pereira
	@since 21/11/2023
	@version 2210
/*/
User Function DEC05LEG()
	Local aLegenda := {}
	 
	//Monta as cores
	AADD(aLegenda,{"BR_VERMELHO" , "Digitando"  })
	AADD(aLegenda,{"BR_AMARELO"  , "Pendente"   })
	AADD(aLegenda,{"BR_VERDE"    , "Finalizado" })

 	BrwLegenda("", "Status do Item", aLegenda)
	
Return

/*/{Protheus.doc} ModelDef
Modelo de dados na funcao DECAT005
@author Jonivani Pereira
@since 04/11/2023
@version 2210
@type function
/*/

Static Function ModelDef()
	Local oStruct := FWFormStruct(1, cAliasMVC) as object
	Local oModel as object
	Local bPre    := Nil
	Local bPos    := Nil
	Local bCancel := Nil


	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("DECAT05M", bPre, bPos, /*bCommit*/, bCancel)
	oModel:AddFields("ZZOMASTER", /*cOwner*/, oStruct)	
	oModel:SetDescription(cTitulo)
	oModel:GetModel("ZZOMASTER"):SetDescription(cTitulo)
	oModel:SetPrimaryKey({})
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao DECAT005
@author Jonivani Pereira
@since 04/11/2023
@version 2210
@type function
/*/

Static Function ViewDef()
	Local oModel  := FWLoadModel("DECAT005") as object
	Local oStruct := FWFormStruct(2, cAliasMVC) as object
	Local oView as object

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZZO", oStruct, "ZZOMASTER")

	// Agrupamento de campos
	oStruct:AddGroup( "GRP001", ""  	           , "", 1)
	oStruct:AddGroup( "GRP002", "Cliente/Vendedor" , "", 2)
	oStruct:AddGroup( "GRP003", "Pedido/Item"      , "", 3)
	oStruct:AddGroup( "GRP004", "Status"           , "", 4)

	// ID
	oStruct:SetProperty( "ZZO_ID"     , MVC_VIEW_GROUP_NUMBER, "GRP001")
	oStruct:SetProperty( "ZZO_USREXC" , MVC_VIEW_GROUP_NUMBER, "GRP001")
	oStruct:SetProperty( "ZZO_DTEXCL" , MVC_VIEW_GROUP_NUMBER, "GRP001")
	oStruct:SetProperty( "ZZO_HREXCL" , MVC_VIEW_GROUP_NUMBER, "GRP001")
	oStruct:SetProperty( "ZZO_OBSERV" , MVC_VIEW_GROUP_NUMBER, "GRP001")
	oStruct:SetProperty( "ZZO_MTEXCL" , MVC_VIEW_GROUP_NUMBER, "GRP001")

	//Cliente/Vendedor   
	oStruct:SetProperty( "ZZO_CODCLI" , MVC_VIEW_GROUP_NUMBER, "GRP002")
	oStruct:SetProperty( "ZZO_CLIENT" , MVC_VIEW_GROUP_NUMBER, "GRP002")
	oStruct:SetProperty( "ZZO_VEND"   , MVC_VIEW_GROUP_NUMBER, "GRP002")
	oStruct:SetProperty( "ZZO_NOMEVD" , MVC_VIEW_GROUP_NUMBER, "GRP002")
	oStruct:SetProperty( "ZZO_EMAILV" , MVC_VIEW_GROUP_NUMBER, "GRP002")
	
	//Pedido/Item
	oStruct:SetProperty( "ZZO_PEDIDO" , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_DTPED"  , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_ITEM"   , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_CODROD" , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_DESPRO" , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_QUANT"  , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_PRCVEN" , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_VALOR"  , MVC_VIEW_GROUP_NUMBER, "GRP003")
	oStruct:SetProperty( "ZZO_QTDFAL" , MVC_VIEW_GROUP_NUMBER, "GRP003")

	// Status
	oStruct:SetProperty( "ZZO_STATUS" , MVC_VIEW_GROUP_NUMBER, "GRP004")
	oStruct:SetProperty( "ZZO_DTENV"  , MVC_VIEW_GROUP_NUMBER, "GRP004")
	oStruct:SetProperty( "ZZO_HRENV"  , MVC_VIEW_GROUP_NUMBER, "GRP004")
	oStruct:SetProperty( "ZZO_ENVMAI" , MVC_VIEW_GROUP_NUMBER, "GRP004")
	oStruct:SetProperty( "ZZO_EMACOP" , MVC_VIEW_GROUP_NUMBER, "GRP004")

	oView:CreateHorizontalBox("TELA" , 100 )
	oView:SetOwnerView("VIEW_ZZO", "TELA")

Return oView

