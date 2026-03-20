#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} BFFATA65
- Rotina chamada no Ponto de Entrada MA410MNU para alterar campos enquando o
pedido de venda nao estiver faturado.
- Dessa forma o pedido nao volta todo o seu processo de lib. cred. esto.. etc..
- Para adicionar mais campos utilize a variavel cCampoAlt
- Cuidado ao colocar campos alteraveis, pois alguns possuem regra na alteracao,
somente coloque campos que não irão influenciar em tratativas do sistema. Como
a condição de pagamento, que possua suas devidas regras na alteração do pedido de venda

@type function
@version  
@author Marcelo Alberto Lauschner
@since 19/12/2020
@return return_type, return_description
/*/


/*/{Protheus.doc} ModelDef
MVC para edição dos campos da SC5
@type function
@version  
@author Marcelo Alberto Lauschner
@since 19/12/2020
@return return_type, return_description
/*/
Static Function ModelDef()


	Local oStructA := FWFormStruct( 1, 'SC5',/*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('BFFATA65', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
	oModel:AddFields( 'SC5MASTER', /*cOwner*/, oStructA, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
	oModel:SetDescription( 'Pedido de Venda' )
	oModel:GetModel( 'SC5MASTER' ):SetDescription( 'Pedido de Venda - '+SC5->C5_NUM )
	oModel:SetVldActivate( {|| MdlVldAct() } )

Return oModel

/*/{Protheus.doc} ViewDef
Campos que podem ser alterados 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 19/12/2020
@return return_type, return_description
/*/
Static Function ViewDef()

	Local cCampoAlt	:=	"C5_TRANSP/C5_VOLUME1/C5_ESPECI1/C5_MENNOTA/C5_TPFRETE/C5_PESOL/C5_PBRUTO/C5_CONDPAG/C5_VEICULO/C5_XPEDCLI/C5_XMENOTA" //Colocar aqui campos que podem ser alterados
	Local oModel   := FWLoadModel( 'BFFATA65' ) // Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oStructA := FWFormStruct( 2, 'SC5', { |cCampo| Alltrim(cCampo)$cCampoAlt} )
	Local oView

	oView := FWFormView():New() // Cria o objeto de View
	oView:SetModel( oModel )// Define qual o Modelo de dados ser· utilizado
	oView:AddField( 'VIEW_A', oStructA, 'SC5MASTER' )//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:CreateHorizontalBox( 'TELA' , 100 )// Criar um "box" horizontal para receber algum elemento da view
	oView:SetOwnerView( 'VIEW_A', 'TELA' )// Relaciona o ID da View com o "box" para exibicao

Return oView

/*/{Protheus.doc} MdlVldAct
Função que valida a alteração/edição do cabeçalho do pedido 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 19/12/2020
@param aParams, array, param_description
@return return_type, return_description
/*/
Static Function MdlVldAct(aParams)

	Local lRet	:=	.F.

	Begin Sequence

		If !Empty(SC5->C5_NOTA)
			Help(,, 'HELP',, 'Pedido de venda faturado ou eliminado resíduo', 1, 0)
			Break
		EndIf
		lRet	:=	.T.
	End Sequence


Return lRet
