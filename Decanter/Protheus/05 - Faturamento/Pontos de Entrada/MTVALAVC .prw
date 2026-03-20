
/*
ExecBLock("MTValAvC",.F.,.F.,{'A440GERAC9',SC6->C6_PRCVEN*nQtdLib,Nil})
nValAv	:=	ExecBLock("MTValAvC",.F.,.F.,{'MAAVALSC9',(cAliasSC9)->C9_QTDLIB*(cAliasSC9)->C9_PRCVEN,nEvento})

 Codigo do Evento                                     ³±±
±±³          ³       [1] Implantacao do SC9                               ³±±
±±³          ³       [2] Estorno do SC9                                   ³±±
±±³          ³       [3] Liberacao de Credito do SC9                      ³±±
±±³          ³       [4] Estorno da Liberacao de Credito do SC9           ³±±
±±³          ³       [5] Liberacao de Estoque do SC9                      ³±±
±±³          ³       [6] Estorno da Liberacao de Estoque do SC9           ³±±
±±³          ³       [7] Montagem de Carga do SC9                         ³±±
±±³          ³       [8] Estorno da Montagem de Carga do SC9              ³±±
±±³          ³       [9] Liberacao WMS do SC9                             ³±±
±±³          ³       [10]Estorno WMS do SC9                               ³±±
±±³          ³       [11]Geracao do Documento de Saida                    ³±±
±±³          ³       [12]Estorno do Documento de Saida     
*/
/*/{Protheus.doc} MTValAvC
Ponto de entrada para avaliar o valor do item que será submetido ao crédito 
@type function
@version  
@author marcelo
@since 12/1/2022
@return variant, return_description
/*/
User Function MTValAvC()

	Local   aAreaOld    := GetArea()
	Local   nValRet     := 0
	Local   cRotOri     := ParamIxb[1]
	Local   nValItem    := ParamIxb[2]
	Local   nEventoC9   := ParamIxb[3]

    // Atribui valor para devolver mesmo valor recebido 
	nValRet := nValItem

	If cEmpAnt == "01" .And. FwIsInCallStack("U_VTEX_ORDER") // Decanter
		// Se for o evento de liberação do item ou inclusão do item na SC9
		If nEventoC9 == 3 .Or. cRotOri == "A440GERAC9"
			// Se a condição de pagamento do pedido for ( )
			If SC5->C5_CONDPAG $ "008#007#001#074#077#078" 
				nValRet     := 0
			Endif
		Endif	
	Endif

	RestArea(aAreaOld)

Return nValRet
