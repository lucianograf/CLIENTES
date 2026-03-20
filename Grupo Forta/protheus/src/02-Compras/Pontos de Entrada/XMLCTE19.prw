#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} XMLCTE19
// Ponto de entrada para popular campos obrigatórios do cadastro de Fornecedor 
@author Marcelo Alberto Lauschner
@since 09/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function XMLCTE19()

	Local	aNaoExiste	:= ParamIxb[1]
	Local	oEmitente	:= ParamIxb[2]
	Local	cA2XCCPASV	:= ' '
	Local	cA2NOME		:= ' '
	Local	cA2COD		:= IIf(Type("oEmitente:_CNPJ") <> "U", Padr(oEmitente:_CNPJ:TEXT,8),IIf(Type("oEmitente:_CPF") <> "U", Padr(oEmitente:_CPF:TEXT,""),9))
	Local	cA2CONTRIB	:= IIf(Type("oEmitente:_IE") <> "U", "1","2")

	cA2XCCPASV	:= Space(TamSX3("A2_CONTA")[1])
	cA2NOME		:= Padr(Transform(oEmitente:_xNome:TEXT,PesqPict("SA2","A2_NOME")),TamSX3("A2_NOME")[1])

	U_MLCTBM02(@cA2XCCPASV,cA2COD,cA2NOME)

	Aadd(aNaoExiste,{"A2_CONTA" 	,cA2XCCPASV		,Nil})
	Aadd(aNaoExiste,{"A2_NATUREZ"   ,"3101"})
	Aadd(aNaoExiste,{"A2_CONTRIB"   ,cA2CONTRIB})

Return aNaoExiste 
