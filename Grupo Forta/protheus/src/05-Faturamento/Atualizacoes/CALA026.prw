#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'
/*/{Protheus.doc} CALA026

- Rotina chamada no Ponto de Entrada MA410MNU para alterar campos enquando o
pedido de venda nao estiver faturado.
- Dessa forma o pedido nao volta todo o seu processo de lib. cred. esto.. etc..
- Para adicionar mais campos utilize a variavel cCampoAlt
- Cuidado ao colocar campos alteraveis, pois alguns possuem regra na alteracao,
somente coloque campos que não irão influenciar em tratativas do sistema. Como
a condição de pagamento, que possua suas devidas regras na alteração do pedido de venda

@author TSC679 - CHARLES REITZ
@since 02/08/2019
/*/

/*/{Protheus.doc} ModelDef

Modelo de Dados

@author TSC679 - CHARLES REITZ
@since 06/08/2015
/*/
Static Function ModelDef()
	Local oStructA := FWFormStruct( 1, 'SC5',/*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('CALA026', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
	oModel:AddFields( 'SC5MASTER', /*cOwner*/, oStructA, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
	oModel:SetDescription( 'Pedido de Venda' )
	oModel:GetModel( 'SC5MASTER' ):SetDescription( 'Pedido de Venda - '+SC5->C5_NUM )
	oModel:SetVldActivate( {|| MdlVldAct() } )

Return oModel

/*/{Protheus.doc} ViewDef

ViewDef

@author TSC679 - CHARLES REITZ
@since 06/08/2015
/*/
Static Function ViewDef()

	Local cCampoAlt	:=	"C5_TRANSP/C5_VOLUME1/C5_ESPECI1/C5_MENNOTA/C5_TRANSP/C5_TPFRETE/C5_REDESP/C5_DESPESA/C5_PESOL/C5_PBRUTO/C5_ZMSGINT" //Colocar aqui campos que podem ser alterados
	Local oModel   := FWLoadModel( 'CALA026' ) // Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oStructA := FWFormStruct( 2, 'SC5', { |cCampo| Alltrim(cCampo)$cCampoAlt} )
	Local oView
	Local cCampos := {}

	oView := FWFormView():New() // Cria o objeto de View
	oView:SetModel( oModel )// Define qual o Modelo de dados ser· utilizado
	oView:AddField( 'VIEW_A', oStructA, 'SC5MASTER' )//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:CreateHorizontalBox( 'TELA' , 100 )// Criar um "box" horizontal para receber algum elemento da view
	oView:SetOwnerView( 'VIEW_A', 'TELA' )// Relaciona o ID da View com o "box" para exibicao

Return oView

/*/{Protheus.doc} MdlVldAct


@author VM-TOTVS
@since 02/08/2019
@version undefined
@param aParams, array, descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
static function MdlVldAct(aParams)
	Local lRet	:=	.F.

	Begin Sequence

		If !Empty(SC5->C5_NOTA)
			Help(,, 'HELP',, 'Pedido de venda faturado ou eliminado resíduo', 1, 0)
			Break
		EndIf


		lRet	:=	.T.
	End Sequence


return lRet
