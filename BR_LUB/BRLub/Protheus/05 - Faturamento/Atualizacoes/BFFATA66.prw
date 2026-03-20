#Include 'Protheus.ch'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} BFFATA66
- Rotina chamada no Ponto de Entrada MA030ROT para alterar campos do cadastro de cliente sem precisar validar todo os valores
- Para adicionar mais campos utilize a variavel cCampoAlt
- Cuidado ao colocar campos alteraveis, pois alguns possuem regra na alteracao,
somente coloque campos que não irão influenciar em tratativas do sistema. Como
a condição de pagamento, que possua suas devidas regras na alteração do pedido de venda
*/
/*/{Protheus.doc} ModelDef
Função para alteração de alguns campos do cadastro de cliente - específico para Financeiro 
@type function
@author Marcelo Alberto Lauschner
@since 01/11/2021
/*/
Static Function ModelDef()


	Local oStructA := FWFormStruct( 1, 'SA1',/*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('BFFATA66', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )
	oModel:AddFields( 'SA1MASTER', /*cOwner*/, oStructA, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )
	oModel:SetDescription( 'Cadastro de cliente' )
	oModel:GetModel( 'SA1MASTER' ):SetDescription( 'Cadastro de cliente- '+SA1->A1_COD + "/"+SA1->A1_LOJA + "-" +SA1->A1_NOME )
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

	Local cCampoAlt	:=	"A1_OBSMEMO/A1_BCO1/A1_RISCO/A1_LC/A1_LCFIN/A1_VENCLC" //Colocar aqui campos que podem ser alterados
	Local oModel   := FWLoadModel( 'BFFATA66' ) // Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oStructA := FWFormStruct( 2, 'SA1', { |cCampo| Alltrim(cCampo)$cCampoAlt} )
	Local oView

	oView := FWFormView():New() // Cria o objeto de View
	oView:SetModel( oModel )// Define qual o Modelo de dados ser· utilizado
	oView:AddField( 'VIEW_A', oStructA, 'SA1MASTER' )//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
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

		If SA1->A1_MSBLQL == "1"
			Help(,, 'HELP',, 'Cliente bloqueado!', 1, 0)
			Break
		EndIf
		lRet	:=	.T.
	End Sequence


Return lRet
