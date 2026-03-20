#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MLCFGV01
// Retorna lista de opções do x3_cbox para o campo da tabela SZ0 - Log Pedidos
@author Marcelo Alberto Lauschner
@since 09/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function MLCFGV01()
	
	Local	cRet	:= ""
	
	//CP=Conf.Exp;ED=Envio Fat;LC=Lib.Crd;LF=Alcada;AP=Alterado;IP=Incluido;CN=ExclusaoNF;LP=Liberado;IM=Impressao                    
	cRet += "IP=Inclusão de Pedido;"
	cRet += "AP=Alteração de Pedido;"
	cRet += "AC=Alteração Cabeçalho de Pedido;"
	cRet += "FL=Follwo-up de Pedido;"
	cRet += "LF=Liberação de Alçada;"
	cRet += "LP=Liberação de Pedido;"
	cRet += "BT=Bloqueio/Pendência Comercial;"
	cRet += "BF=Bloqueio/Pendência Financeira;"
	cRet += "BA=Bloqueio/Pagto Antecipado;"
	cRet += "LA=Liberação/Pgto Antecipado;"
	cRet += "LC=Liberação Crédito;"
	cRet += "LR=Pedido Rejeitado;"
	cRet += "ED=Enviado p/Expedição;"
	cRet += "IM=Impressão Pedido p/Separação;"
	cRet += "EC=Enviado p/Separação/Emissão NF;"
	cRet += "CP=Conferência/Emissão Etiquetas;"
	cRet += "ET=Exportado para Arquivo EDI;"
	cRet += "ST=Atualização Status Pedido;"
	cRet += "CN=Cancelamento NotaFiscal/Pedido;"
	cRet += "NF=Gerada Nota Fiscal Doc.Saída;"
	cRet += "IN=Geração/Impressão da Danfe;"
	cRet += "EF=Pedido Retornado ao TMK;"
	cRet += "DB=Lançamento Box/Sep/Conf/Mes;"
	cRet += "ER=Eliminação de Resíduos;"
	cRet += "EP=Exclusão do Pedido;"
	cRet += "LE=Liberação de Estoque;"
	cRet += "EL=Exclusao de Lote Contábil;"
	cRet += "WF=Workflow Cotação;"
	
Return cRet