#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} XMLCTE08
// Ponto de entrada para preencher automaticamente número de Lote para lançamento de notas da Frimazo e Redelog
@author Marcelo Alberto Lauschner
@since 07/09/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function XMLCTE08()

	Local	aAreaOld	:= GetArea()

	Local	nPosCodPr		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_COD"} )
	Local	nPosLtCtl		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_LOTECTL"} )
	Local	nPosNumLt		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_NUMLOTE"} )
	Local	nPosQtSeg		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_QTSEGUM"} )

	// Se Empresa Redelog
	If cEmpAnt == "06" .And. Rastro(aLinha[nPosCodPr][2])
		// Verifica se já existe a coluna no vetor - Atualiza ou insere 
		If nPosLtCtl > 0 .And. Empty(aLinha[nPosLtCtl][2])
			aLinha[nPosLtCtl][2]	:=  DTOS(CONDORXML->XML_EMISSA)
		ElseIf nPosLtCtl == 0
			Aadd(aLinha,{"D1_LOTECTL"	, DTOS(CONDORXML->XML_EMISSA)		,Nil,Nil})	
		Endif	

		// Verifica se já existe a coluna no vetor - Atualiza ou insere 
		If nPosNumLt > 0 .And. aLinha[nPosNumLt][2]
			aLinha[nPosNumLt][2]	:=  cNumDoc
		ElseIf nPosNumLt == 0
			Aadd(aLinha,{"D1_NUMLOTE"	,cNumDoc		,Nil,Nil})	
		Endif	
	ElseIf cEmpAnt == "05" .And. Rastro(aLinha[nPosCodPr][2]) .And. CONDORXML->XML_TIPODC == "N"
		// Verifica se já existe a coluna no vetor - Atualiza ou insere 
		If nPosLtCtl > 0 .And. Empty(aLinha[nPosLtCtl][2])
			aLinha[nPosLtCtl][2]	:=  cValToChar( Day(CONDORXML->XML_EMISSA)) + cValToChar( Month(CONDORXML->XML_EMISSA)) + Substr( DTOS(CONDORXML->XML_EMISSA),3,2) 
		ElseIf nPosLtCtl == 0
			Aadd(aLinha,{"D1_LOTECTL"	, cValToChar( Day(CONDORXML->XML_EMISSA)) + cValToChar( Month(CONDORXML->XML_EMISSA)) + Substr( DTOS(CONDORXML->XML_EMISSA),3,2)		,Nil,Nil})	
		Endif	

		// Verifica se já existe a coluna no vetor - Atualiza ou insere 
		If nPosNumLt > 0 .And. aLinha[nPosNumLt][2]
			aLinha[nPosNumLt][2]	:=  cNumDoc
		ElseIf nPosNumLt == 0
			Aadd(aLinha,{"D1_NUMLOTE"	,cNumDoc		,Nil,Nil})	
		Endif	
	ElseIf cEmpAnt == "05" .And. Rastro(aLinha[nPosCodPr][2]) .And. CONDORXML->XML_TIPODC == "D"
		// Verifica se já existe a coluna no vetor - Atualiza ou insere 
		If nPosQtSeg > 0 .And. Empty(aLinha[nPosQtSeg][2])
			aLinha[nPosQtSeg][2]	:=  SD2->D2_QTSEGUM 
		ElseIf nPosQtSeg == 0
			Aadd(aLinha,{"D1_QTSEGUM"	, SD2->D2_QTSEGUM 		,Nil,Nil})	
		Endif	

		
	Endif
	RestArea(aAreaOld)

Return
