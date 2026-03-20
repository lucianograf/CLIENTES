#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} BFCTBG01
//TODO Função para retornar o Histórico do lançamento padrão 597 - Contabilização da Compensação do Contas a Pagar.
@author Marcelo Alberto Lauschner 
@since 29/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function BFCTBG01()

	Local aSaveSE5 	:= SE5->(GetArea())
	Local aSaveSE2 	:= SE2->(GetArea()) 
	Local xRet    	:= Nil

	If REGVALOR <> 0
		SE2->(dbGoto(REGVALOR))
		
		//xRet:= "TESTE TIPO: "+ SE2->E2_TIPO + " RECNO: "+ ALLTRIM(STR(SE2->(RECNO())))
		xRet:= Padr("COMP.PAGAR NF." + Alltrim(SE2->(E2_PREFIXO+E2_NUM+E2_PARCELA)) + "-" + AllTrim(SE2->E2_NOMFOR) + " DOC ORIG:" + AllTrim(STRLCTPAD),80) 
	Else
		//xRet:= "TESTE TIPO: "+ SE5->E5_TIPO + " TIPODOC: "+SE5->E5_TIPODOC + " RECNO: "+ ALLTRIM(STR(SE5->(RECNO())))
		xRet := Padr("COMP.PAGAR NF." + Alltrim(SE5->(E5_PREFIXO+E5_NUMERO+E5_PARCELA)) + "-" + AllTrim(SE5->E5_BENEF) + " DOC ORIG:" + AllTrim(STRLCTPAD ),80) 
	Endif

	RestArea(aSaveSE2)
	RestArea(aSaveSE5)

Return(xRet)