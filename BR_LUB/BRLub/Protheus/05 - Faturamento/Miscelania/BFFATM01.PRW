

/*/{Protheus.doc} BFFATM01
(Função para fazer o Descálculo do preço de venda digitado. Preço final irá descalcular ST e IPI para retornar preço unitário)
@author MarceloLauschner
@since 11/09/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATM01()
	
	Local	aAreaOld		:= GetArea()
	Local	nRet			:= 0
	Local	nPrcUnit		:= 100
	Local	nPercAux		:= 0
	Local	nPosProd		:= 0
	Local	nPrcBrut		:= 0
	Local	nPIPI			:= 0
	Local	nPICMENT		:= 0
	Local	nPerIcm 		:= 0
	Local	nIcmPad			:= GetMv("MV_ICMPAD")
	Local   cMVNORTE    	:= SuperGetMV("MV_NORTE")
	Local   cMVESTADO		:= GetMv("MV_ESTADO")
	Local	lCalcSaida		:= .F.
	Local	cCliente		:= ""
	Local	cLojCli			:= ""
	Local	cTipoCli		:= ""
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If Type("M->AIB_XPRCMV") <> "U"
		nRet		:= M->AIB_XPRCMV
		nPosProd	:= aScan(aHeader,{|x| Alltrim(x[2])=="AIB_CODPRO"})
	ElseIf Type("M->UB_XPRCMV") <> "U"
		nRet		:= M->UB_XPRCMV
		nPosProd	:= aScan(aHeader,{|x| Alltrim(x[2])=="UB_PRODUTO"})
		cCliente	:= M->UA_CLIENTE
		cLojCli		:= M->UA_LOJA
		cTipoCli	:= M->UA_TIPOCLI
		lCalcSaida	:= .T.
	ElseIf Type("M->C6_XPRCMV") <> "U"
		nRet		:= M->C6_XPRCMV
		nPosProd	:= aScan(aHeader,{|x| Alltrim(x[2])=="C6_PRODUTO"})
		cCliente	:= M->C5_CLIENTE
		cLojCli		:= M->C5_LOJACLI
		cTipoCli	:= M->C5_TIPOCLI
		lCalcSaida	:= .T.
	Endif
	nPrcBrut	:= nRet
	
	DbSelectArea("SB1")
	DbSetOrder(1)
	If DbSeek(xFilial("SB1")+aCols[n,nPosProd])
		// Verifico se há MVA de entrada
		If lCalcSaida
			nRet	:= sfRet("C"/*cInTipo*/,cTipoCli/*cInTpCli*/,cCliente,cLojCli,aCols[n,nPosProd],100,SB1->B1_TS)
		Else
			cCliente	:= SB1->B1_PROC
			cLojCli		:= SB1->B1_LOJPROC			
			nRet		:= sfRet("F"/*cInTipo*/,"R"/*cInTpCli*/,cCliente,cLojCli,aCols[n,nPosProd],100,SB1->B1_TE)
		Endif
		
		//nPIPI		:= Iif(SF4->F4_IPI $ "S" ,SB1->B1_IPI,0)
		
		// Somente se houver ST cadastrada para o produto
		//If 	nPICMENT > 0
		//	A	nPrcUnit	PRECO LISTA	100
		//	B	% ICMS EST	18
		//	C	nPerIcm	% ICMS INTER	18
		//	D	nPIPI		% IPI	0
		//	E	nPICMENT	% MVA	61,31
		//	F	nPrcBrut	PRECO FINAL	240,45
		
		//=E4*((1+(E7/100))*(1+(E8/100))*(E5/100))-(E4*(E6/100))+(E4*(1+(E7/100)))
		//nRet	:= (Iif(SF4->F4_BSICMST > 0 ,SF4->F4_BSICMST / 100 , 1 ) * nPrcUnit)*((1+(nPIPI/100))*(1+(nPICMENT/100))*(nIcmPad/100))-((Iif(SF4->F4_BASEICM > 0 ,SF4->F4_BASEICM/100,1) * nPrcUnit)*(nPerIcm/100))+(nPrcUnit*(1+(nPIPI/100)))
		nRet	:= nPrcBrut / (nRet / 100)
		//		X*(1,05)*(1,5663)=197,35
		// Faço o descalculo do preço do item
		//nRet	:= Round(nPrcBrut / (1+ ( (nPerIcm /100) * (1+(nPIPI/100)) * (1+(nPICMENT/100)) ) ),2)
		//Endif
	Else
		MsgAlert("Produto não cadastrado '"+aCols[n,nPosProd]+"' ","A T E N Ç Ã O!!")
	Endif
	
	RestArea(aAreaOld)
	
Return nRet



/*/{Protheus.doc} sfRet
(long_description)
@author MarceloLauschner
@since 11/09/2015
@version 1.0
@param cInTipo, character, (Descrição do parâmetro)
@param cInTpCli, character, (Descrição do parâmetro)
@param cInFor, character, (Descrição do parâmetro)
@param cInLoj, character, (Descrição do parâmetro)
@param cInCodPro, character, (Descrição do parâmetro)
@param nInPrc, numérico, (Descrição do parâmetro)
@param cInTes, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRet(cInTipo,cInTpCli,cInFor,cInLoj,cInCodPro,nInPrc,cInTes)
	
	
	Local	aAreaOld		:= GetArea()
	Local	nCustRet		:= 0
	Local	nItemFis		:= 0
	Local 	nPos       	:= 0
	Local	cTipo			:= "N"
	
	
	MaFisSave()
	MaFisEnd()
	
	
	MaFisIni(cInFor,;													// 1-Codigo Cliente/Fornecedor
	cInLoj,;															// 2-Loja do Cliente/Fornecedor
	cInTipo,;															// 3-C:Cliente , F:Fornecedor
	cTipo,;																// 4-Tipo da NF
	cInTpCli,;															// 5-Tipo do Cliente/Fornecedor
	Iif(cInTipo=="C",Nil,MaFisRelImp("MT100",{"SF1","SD1"})),;			// 6-Relacao de Impostos que suportados no arquivo
	Nil,;																// 7-Tipo de complemento
	Nil,;																// 8-Permite Incluir Impostos no Rodape .T./.F.
	Nil,;																// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
	Iif(cInTipo=="C","MATA461","MATA100"),;								// 10-Nome da rotina que esta utilizando a funcao
	Nil,;																// 11-Tipo de documento
	Nil,;  																// 12-Especie do documento
	Nil)																// 13- Codigo e Loja do Prospect
	
	nItemFis++
	
	MaFisAdd(	cInCodPro,;  					// 1-Codigo do Produto ( Obrigatorio )
	cInTes,;									// 2-Codigo do TES ( Opcional )
	1,; 										// 3-Quantidade ( Obrigatorio )
	nInPrc,;									// 4-Preco Unitario ( Obrigatorio )
	0,;	 										// 5-Valor do Desconto ( Opcional )
	"",;	   									// 6-Numero da NF Original ( Devolucao/Benef )
	"",;										// 7-Serie da NF Original ( Devolucao/Benef )
	0,;											// 8-RecNo da NF Original no arq SD1/SD2
	0,;											// 9-Valor do Frete do Item ( Opcional )
	0,;											// 10-Valor da Despesa do item ( Opcional )
	0,;											// 11-Valor do Seguro do item ( Opcional )
	0,;											// 12-Valor do Frete Autonomo ( Opcional )
	nInPrc,;									// 13-Valor da Mercadoria ( Obrigatorio )
	0,;											// 14-Valor da Embalagem ( Opiconal )
	,;											// 15
	,;											// 16
	,; 											// 17
	0,;											// 18-Despesas nao tributadas - Portugal
	0,;											// 19-Tara - Portugal
	,; 											// 20-CFO
	{},;	           							// 21-Array para o calculo do IVA Ajustado (opcional)
	"")
	
	nCustRet	:= MaFisRet(,"NF_TOTAL")
	
	MaFisRestore()
	
	RestArea(aAreaOld)
	
Return nCustRet


