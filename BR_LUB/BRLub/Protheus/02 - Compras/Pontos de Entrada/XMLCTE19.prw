#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} XMLCTE18
//TODO Ponto de Entrada da Central XML para adicionar campos na criao do cadastro de Fornecedor via Central XML
@author  Marcelo Alberto Lauschner
@since 15/11/2018
@version 1.0
@return aNaoExiste, Array com os campos que sero inseridos via ExecAuto do MATA020
@type User Function
/*/
User function XMLCTE19()
	
	Local	aNaoExiste	:= ParamIxb[1]
	Local	oEmitente	:= ParamIxb[2]
	Local	cA2XCCPASV	:= ' '
	Local	cA2NOME		:= ' '
	Local	cA2COD		:= Padr(' ',TamSX3("A2_COD")[1])
	
	// Atrialub e Frimazo  / Onix 
	
	cA2XCCPASV	:= Space(TamSX3("A2_XCCPASV")[1])
	cA2NOME		:= Padr(Transform(oEmitente:_xNome:TEXT,PesqPict("SA2","A2_NOME")),TamSX3("A2_NOME")[1])
		
	U_BFCTBM24(@cA2XCCPASV,cA2COD,cA2NOME)
	
	Aadd(aNaoExiste,{"A2_XCCPASV" 	,cA2XCCPASV		,Nil})
	Aadd(aNaoExiste,{"A2_NATUREZ"   ,Padr("NORMAL",TamSX3("A2_NATUREZ")[1])})
	Aadd(aNaoExiste,{"A2_EMAIL"   	,Padr("fiscal@brlub.com.br",TamSX3("A2_EMAIL")[1])})
	
Return aNaoExiste 
