#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} BFCFGM25
//Função que verifica se o programa deve ser executado para esta empresa ou não. Compatibilização nova para Frimazo 
@author Marcelo Alberto Lauschner
@since 06/04/2018
@version 6
@return ${return}, ${return_description}
@param cInFunc, characters, descricao
@type function
/*/
User Function BFCFGM25(cInFunc)

	Local	aAreaOld	:= GetArea()
	Local	aFuncOk		:= {}	
	Local	lRet		:= .T. 
	Local	iQ
	
	// Padroniza a descrição da função que será validada
	cInFunc	:= AllTrim(Upper(cInFunc))
	
	If cEmpAnt+cFilAnt $ "0601#0602#0603" 
		lRet	:= .F. 
		// Cria lista de Exceções que pode ser executadas  
		Aadd(aFuncOk,{"XXXXXX",cEmpAnt+cFilAnt})
		Aadd(aFuncOk,{"MS520VLD",cEmpAnt+cFilAnt}) 	// 15/8/18 - Liberada a rotina de exclusão de Lançamento contábil
	Endif

	// Se for falso o retorno, verifico exceções 
	If !lRet
		For iQ := 1 To Len(aFuncOk)
			If cInFunc == aFuncOk[iQ][1] .And. cEmpAnt+cFilAnt == aFuncOk[iQ][2]
				lRet	:= .T.
				Exit
			Endif
		Next iQ
	Endif	
	RestArea(aAreaOld)

Return lRet

