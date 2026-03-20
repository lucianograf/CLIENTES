#Include 'Protheus.ch'


/*/{Protheus.doc} XMLCTE09
(Ponto de entrada Central XML - no lançamento de Frete sobre Vendas - permite customização)
@type function
@author marce
@since 11/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function XMLCTE09()
	// Recebe o registro posicionada da SF2 
	Private	aNfOri	:= ParamIxb

	If "06032022" $ SM0->M0_CGC
		sfExecAtria()
	Endif

Return




/*/{Protheus.doc} sfExecAtria
//Efetua verificação de ajustes de código de produto conforme origem/destino Frete
@author marce
@since 11/07/2017
@version 6

@type function
/*/
Static Function sfExecAtria()

	Local	nPosCod		:= 	aScan(aItem,{|x| AllTrim(x[1]) == "D1_COD"})
	Local	nPosTes		:= 	aScan(aItem,{|x| AllTrim(x[1]) == "D1_TES"})
	Local	nPosOper	:= 	aScan(aItem,{|x| AllTrim(x[1]) == "D1_OPER"})
	Local	nPosCtaCtb	:=  aScan(aItem,{|x| AllTrim(x[1]) == "D1_CONTA"})
	Local	nPosCC		:=  aScan(aItem,{|x| AllTrim(x[1]) == "D1_CC"})
	Local	nPosValor	:=  aScan(aItem,{|x| AllTrim(x[1]) == "D1_TOTAL"})
	Local	cCCusto		:= ""
	Local	lIsCliAtria	:= .F. 
	Local	cCgcCli		:= ""
	Local	nLenItem	:=  Len(aItem)

	// Se habilitado os parâmetros para informar a UF de origem e Destino e sendo um frete Interestadual, efetua a alteração do código do produto
	// 11/07/2017 - Chamado 18546 - Marcelo
	If !(GetNewPar("XM_CTEUFA2",.F.)) .And. GetNewPar("XM_CTEUFA3",.F.) .And. cFilAnt == "09"
		If cEstOriXml <>  cEstDesXml 							
			If nPosCod <> 0 .And. Alltrim(aItem[nPosCod,2]) == "FRETE"
				aItem[nPosCod,2] := "FRETE FORA EST"		
			Endif
		Endif
	Endif

	// Se for empresa 02-Atria 11-Onix
	// 02/12/2021 - Ajuste de tes automática para fretes de 1 centavo 
	If cEmpAnt $ "02#11"
		// Abaixo de 10 centavos usar TES 
		If aItem[nPosValor,2]  <= 0.10
			aItem[nPosTes,2] 	:= "164"
		Endif 
	Endif 
	
	// Se o Remetente for ICONIC 
	If Type("oRemetente:_CNPJ") <> "U" .And. (Substr(oRemetente:_CNPJ:TEXT,1,8) $ "05524572")

		If Type("oDestino:_CNPJ") <> "U"
			DbSelectArea("SA1")
			DbSetOrder(3)
			If DbSeek(xFilial("SA1")+oDestino:_CNPJ:TEXT)
				lIsCliAtria	:= .T. 
				cCgcCli		:= SA1->A1_CGC
			Endif
		ElseIf Type("oDestino:_CPF") <> "U"
			DbSelectArea("SA1")
			DbSetOrder(3)
			If DbSeek(xFilial("SA1")+oDestino:_CPF:TEXT)
				lIsCliAtria	:= .T.
				cCgcCli		:= SA1->A1_CGC
			Endif
		Endif

		If lIsCliAtria
			// Ajusta o código do Produto
			If nPosCod <> 0 .And. Alltrim(aItem[nPosCod,2]) == "FRETE"
				aItem[nPosCod,2] := "FRETE BROKER"		
				// Ajusta o código do TES 
				If nPosTes <> 0 
					aItem[nPosTes,2] := "164"	
				Else
					Aadd(aItem,{"D1_TES"  	,"164"  	,Nil})	
					nPosTes		:=	aScan(aItem,{|x| AllTrim(x[1]) == "D1_TES"})
					nLenItem	:= Len(aItem)
				Endif

			Endif

			If nPosOper <> 0			
				aDel(aItem,nPosOper)
				aSize(aItem,nLenItem-1)
			Endif

			// Conta Contábil	
			// Se precisar um dia forçar o preenchimento é só ativar este trecho do código e informar o código da Conta contábil que deverá ser usado
			If nPosCtaCtb <> 0
				aItem[nPosCtaCtb,2]	:= "510209014" // despesa de logística Broker )
			Else
				Aadd(aItem,{"D1_CONTA" 	,"510209014"		                ,Nil})
				nLenItem	:= Len(aItem)
			Endif

			If cFilAnt == "01"
				cCCusto		:= "101410160008        " // DESPESAS LOGISTICA SC                   
			ElseIf cFilAnt == "04"
				cCCusto		:= "101410160010        " // DESPESAS LOGISTICA PR                   
			ElseIf cFilAnt == "05"
				cCCusto		:= "101410160009        " // DESPESAS LOGISTICA RS                   
			ElseIf cFilAnt == "07"
				cCCusto		:= "101410160011        " // DESPESAS DE LOGISTICA SP                
			ElseIf cFilAnt == "08"
				cCCusto		:= "101410160035        " // DESPESAS LOGISTICA MG                   
			ElseIf cFilAnt == "09"
				cCCusto		:= "101410160049        " // DESPESAS DE LOGISTICA RJ                
			Endif
			// Centro de Custo
			If nPosCC <> 0
				aItem[nPosCC,2]		:= cCCusto
			Else 
				Aadd(aItem,{"D1_CC" 	,cCCusto	               		,Nil})
				nLenItem	:= Len(aItem)
			Endif	
		Endif
	Endif

Return 
