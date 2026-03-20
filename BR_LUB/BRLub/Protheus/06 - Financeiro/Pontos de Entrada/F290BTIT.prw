#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F290BTIT
//Ponto de entrada Rotina de Faturas a Pagar 
@author marce
@since 24/04/2018
@version 6
@return ${return}, ${return_description}

@type function
/*/
User function F290BTIT()
	Local	aInCampos	:= aClone(ParamIxb)
	Local	nZ 	
	Local	aCmpPrior	:= {"E2_PREFIXO","E2_NUM","E2_PARCELA","E2_TIPO","E2_NATUREZA","E2_VALOR","E2_SALDO","E2_FORNECE","E2_LOJA","E2_NOMFOR","E2_EMISSAO","E2_VENCTO","E2_VENCREA"}
	Local	aOutCampos	:= {}
	Local	nLenItem	:= Len(aInCampos)
	
	// Adiciona a primeira coluna 
	Aadd(aOutCampos,aInCampos[1])
	aDel(aInCampos,1)
	aSize(aInCampos,nLenItem-1)
	
	
			
	// Primeiro percorre o vetor e só adicionada pela sequência dos campos definidos como prioridade
	For nZ := 1 To Len(aCmpPrior)
		nPosCpo := aScan(aInCampos,{|x| AllTrim(x[1]) == aCmpPrior[nZ]})
		If nPosCpo <> 0
			nLenItem	:= Len(aInCampos)
			Aadd(aOutCampos,aInCampos[nPosCpo])
			aDel(aInCampos,nPosCpo)
			aSize(aInCampos,nLenItem-1)
		Endif
	Next nZ 
	
	// Percorre novamente adicionando os campos que não foram adicionados anteriormente 
	For nZ := 1 To Len(aInCampos)
		Aadd(aOutCampos,aInCampos[nZ])
	Next nZ 
	
	
Return aOutCampos