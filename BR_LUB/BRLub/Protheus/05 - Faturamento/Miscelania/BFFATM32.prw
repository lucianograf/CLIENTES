#Include 'Protheus.ch'


/*/{Protheus.doc} BFFATM32
(Função para calcular comissão de todos os itens do pedido baseado no desconto médio)
@author MarceloLauschner
@since 07/07/2016
@version 1.0
@param lIsSC5, ${param_type}, (Descrição do parâmetro)
@param lIsSUA, ${param_type}, (Descrição do parâmetro)
@param cInVend1, character, (Descrição do parâmetro)
@param cInVend2, character, (Descrição do parâmetro)
@param aInAcols, array, (Descrição do parâmetro)
@param cInCli, character, (Descrição do parâmetro)
@param cInLoja, character, (Descrição do parâmetro)
@param dInEmissao, data, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATM32(lIsSC5,lIsSUA,cInVend1,cInVend2,aInAcols,cInCli,cInLoja,dInEmissao)
	
	Local	nPComis1	:= 0
	Local	nPComis2	:= 0
	Local	nPProd
	Local	nPPrcTab
	Local	nPVrUnit
	Local	nPVlrTampa
	Local	nPxFlex
	Local	nPCodTab
	Local	nPTes
	Local	nPxComis1
	Local	nPxComis2
	Local	nPxQuant
	Local	nDescMed	:= 0
	Local	nTotBrut	:= 0
	Local	nTotLiq		:= 0
	Local	iX
	
	If lIsSC5
		nPProd  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
		nPTes	  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
		nPCodTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XCODTAB"})
		nPVrUnit   		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
		nPVlrTampa		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XVLRTAM"})
		nPxComis1		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_COMIS1"})
		nPxComis2		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_COMIS2"})
		nPPrcTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
		nPxFlex			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XFLEX"})
		nPxQuant		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	ElseIf lIsSUA
		nPProd  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_PRODUTO"})
		nPTes	  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_TES"})
		nPCodTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XCODTAB"})
		nPVrUnit   		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_VRUNIT"})
		nPVlrTampa		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XVLRTAM"})
		nPxComis1		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS1"})
		nPxComis2		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_COMIS2"})
		nPPrcTab		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_PRCTAB"})
		nPxFlex			:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_XFLEX"})
		nPxQuant		:= aScan(aHeader,{|x| AllTrim(x[2]) == "UB_QUANT"})
	Endif
	
	// Sumarizo o pedido - Total Preço de Tabela e Total Preço de Venda liquido
	For iX := 1 To Len(aInAcols)
		If !aInAcols[iX,Len(aHeader)+1]
			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4")+aInAcols[iX][nPTes])
			If SF4->F4_DUPLIC == "S"
				nTotBrut	+= Round(aInAcols[iX][nPPrcTab] * aInAcols[iX][nPxQuant],2)
				nTotLiq		+= Round(aInAcols[iX][nPVrUnit] * aInAcols[iX][nPxQuant],2)
				// Subtrai o valor das Tampas e Custos do valor liquido do produto para escalonar percentual de desconto
				nTotLiq		-= Round((Iif(nPVlrTampa > 0, aInAcols[iX][nPVlrTampa],0) + Iif(nPxFlex > 0 ,aInAcols[iX][nPxFlex],0)) * aInAcols[iX][nPxQuant],2)
			Endif
		Endif
	Next
	
	nDescMed	:= 100 - (Round(nTotLiq/nTotBrut*100,2))
	
	If lIsSC5
		M->C5_XPDESMD	:= nDescMed
	Endif
	
	For iX := 1 To Len(aInAcols)
		
		nPComis1	:= 0
		If !Empty(cInVend1)
		Endif
		aInAcols[iX][nPxComis1]:= nPComis1
		
		
		nPComis2	:= 0
		If !Empty(cInVend2) .And. cInVend2 <> cInVend1
		Endif
		
		aCols[iX][nPxComis2]:= nPComis2
		
	Next
	
Return

