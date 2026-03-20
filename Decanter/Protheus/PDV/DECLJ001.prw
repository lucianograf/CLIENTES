#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} DECLJ001
Consulta personalizada de produto aplicando tabela de preço e regra de descontos

@author Carlos Eduardo Reinert 
@since 23/12/2019
/*/

User Function DECLJ001()

	Private aBoxPrd := {}
	Private bBoxPrd,oBoxPrd
	
	Private cCodFil := Space(200)
	Private cCodPrd := ""
	Private cDtVal := DToC(StoD(""))
	Private cPrcFim := "0"
	Private oCodFil
	Private oCodGet
	Private oDtValGet
	Private oPrcFimGet
	Private oBold
		
	// Carrega filtro de produtos
	fFilPrd()
	
	// Montagem da tela de consulta
	aSize  	 := MsAdvSize( .F. )
	aObjects := {} 
	AAdd( aObjects, { 100, 20,  .t., .f., .t. } )
	AAdd( aObjects, { 100, 100 , .t., .t. } )
	AAdd( aObjects, { 100, 42 , .t., .f. } )

	aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 } 
	aPosObj1 := MsObjSize( aInfo, aObjects) 
	
	DEFINE FONT oBold NAME "Arial" SIZE 0, -20 BOLD
	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Consulta Produtos") from aSize[7],0 TO aSize[6],(aSize[5]-30) of oMainwnd PIXEL

	@ 05,015 SAY "Filtrar: " OF oDlg1 Pixel
	@ 05,050 MsGet oCodFil Var cCodFil Valid fFilPrd() SIZE (aPosObj1[1,3]-70),15 FONT oBold OF oDlg1 PIXEL
	
	// Lista de Produtos
	oBoxPrd := TWBrowse():New( aPosObj1[2,1],aPosObj1[2,2]+05,(aPosObj1[1,3]-30),aPosObj1[2,3]-30,,;
	{"Produto", "Descrição", "Cod.Barras", "UM", "Prç. Unitário", "Prç. Final", "Dt. Validade"},;
	{50,200,50,30,50,50,30},oDlg1,,,,,{||},,,,,,,.F.,,.T.,,.F.,,.t.,.t.)

	oBoxPrd:SetArray(aBoxPrd)
	bBoxPrd := { || { 	aBoxPrd[oBoxPrd:nAt,1], aBoxPrd[oBoxPrd:nAt,2], ;
	aBoxPrd[oBoxPrd:nAt,3], aBoxPrd[oBoxPrd:nAt,4], aBoxPrd[oBoxPrd:nAt,5], ;
	aBoxPrd[oBoxPrd:nAt,6], aBoxPrd[oBoxPrd:nAt,7] } }
	oBoxPrd:bLine := bBoxPrd
	oBoxPrd:bChange := {|| fChangePrd()} 
	
	// Rodapé
	@ aPosObj1[3,1],015 SAY "Produto: " SIZE 035,15 OF oDlg1 PIXEL
	@ aPosObj1[3,1],050 MsGet oCodGet Var cCodPrd WHEN .F. SIZE (aPosObj1[1,3]-70),15 OF oDlg1 FONT oBold COLOR CLR_HBLUE PIXEL
	
	@ aPosObj1[3,1]+20,015 SAY "Dt.Val.Preço: " SIZE 035,15 OF oDlg1 PIXEL
	@ aPosObj1[3,1]+20,050 MsGet oDtValGet Var cDtVal WHEN .F. SIZE 060,15 FONT oBold COLOR CLR_HBLUE OF oDlg1 PIXEL
	@ aPosObj1[3,1]+20,120 SAY "Preço Final: " SIZE 035,15 OF oDlg1 PIXEL
	@ aPosObj1[3,1]+20,165 MsGet oPrcFimGet Var cPrcFim WHEN .F. SIZE 090,15 FONT oBold COLOR CLR_HBLUE OF oDlg1 PIXEL
	
	DEFINE SBUTTON FROM aPosObj1[3,1]+25,(aPosObj1[1,3]-50) TYPE 1 ENABLE OF oDlg1 ACTION ( oDlg1:End() )

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return

// Função na alteração de linha do grid de produto
Static Function fChangePrd()

	cCodPrd := aBoxPrd[oBoxPrd:nAt,1] + " - " + aBoxPrd[oBoxPrd:nAt,2]
	cDtVal := aBoxPrd[oBoxPrd:nAt,7]
	cPrcFim := aBoxPrd[oBoxPrd:nAt,6]
	oCodGet:Refresh()
	oDtValGet:Refresh()
	oPrcFimGet:Refresh()
	
Return

// Função para filtro de produtos
Static Function fFilPrd()
	
	Local nPrcUnit := 0
	Local aFilStr := {}
	Local nIdx := 0
	Local cFiltro := ""
	Local aItDesc := {}
	
	cCodFil := Upper(AllTrim(cCodFil))
	
	// Limpa grid de produtos
	aBoxPrd := {}

	If !Empty(cCodFil)
	
		// Monta filtro dinâmico
		aFilStr := StrTokArr(cCodFil, "*")
		For nIdx := 1 To Len(aFilStr)
			cFiltro += ".and. ('"+AllTrim(aFilStr[nIdx])+"' $ (AllTrim(SB1->B1_COD)+'|'+AllTrim(SB1->B1_DESC)+'|'+AllTrim(SB1->B1_CODBAR)))"
		Next
		cFiltro := AllTrim(SubStr(cFiltro, 6))
	
		// Carrega dados gerais do produto
		dbSelectArea("SB1")
		SB1->(DBGoTop())
				
		While SB1->(!EOF())
		
			If &cFiltro
				
				/*/
				Preço de Tabela
				/*/
				nPrcUnit := fValTbPr(SB1->B1_COD, ""/*SA1->A1_COD*/)
				
				If nPrcUnit > 0
					
					// Regra de Desconto
					/*/
					AADD( aRet , lApplyRule 			)
					AADD( aRet , nNewValueItem 		)
					AADD( aRet , nTotValueDiscount 	)
					AADD( aRet , nDiscPerTotal 		)
					AADD( aRet , nValueItem 			)
					AADD( aRet , dRuleDate			)	
					/*/		
					aItDesc := fItemRlDi( 	/*nItemLine*/	, SB1->B1_COD 	, nPrcUnit 	, /*nAmount*/ ,	/*cTypeProd*/	, ""/*SA1->A1_COD*/, ""/*SA1->A1_LOJA*/	)
					
					aAdd(aBoxPrd, {;
						SB1->B1_COD ,;
						SB1->B1_DESC ,;
						SB1->B1_CODBAR ,;
						SB1->B1_UM ,;
						Transform(aItDesc[5],"@E 99,999,999.99")	,;
						Transform(aItDesc[2],"@E 99,999,999.99")	,;
						DToC(aItDesc[6]) ;
						} )
				
				EndIf
				
			EndIf
			
			SB1->(dbSkip())
		
		End
		
		SB1->(dbCloseArea())
		
	EndIf
	
	// Caso não tenha nenhum produto no filtro, carrega uma linha vazia
	If Len(aBoxPrd) == 0
		aAdd(aBoxPrd, {;
		Space(Len(SB1->B1_COD)) ,;
		Space(Len(SB1->B1_DESC)) ,;
		Space(Len(SB1->B1_CODBAR)) ,;
		Space(Len(SB1->B1_UM)) ,;
		Transform(0,"@E 99,999,999.99")	,;
		Transform(0,"@E 99,999,999.99")	,;
		DToC(StoD("")) ;
		} )
	Endif
	
	If Type("oBoxPrd") == "O"
		
		oBoxPrd:SetArray(aBoxPrd)
		oBoxPrd:bLine := bBoxPrd
		oBoxPrd:Refresh()
		
		fChangePrd()
		
	EndIf
	
	cCodFil := Space(200)
	
Return

//--------------------------------------------------------
/*/{Protheus.doc} ValueTablePrice
Retorna o preco do item conforme esta na tabela, considerando quando retornar
o maior ou menor preco conforme o parametro MV_LJRETVL
@param cItemCode	Codigo do item
@param cCustomer	cliente
@param cFil			Filial
@param cStore		Loja
@param nMoeda		Moeda
@author  	Varejo
@version 	P11.8
@since   	30/03/2012
@return  	nReturnPrice   Preco
@obs     Função original STBValTbPr (TOTVSPDV)
@sample
/*/
//--------------------------------------------------------
Static Function fValTbPr( cItemCode, cCustomer, cFil, cStore	,nMoeda , nQtde)

Local nX 				:= 0										//Variavel para o laco For
Local nRet			:= 	0										//Verifica se foi retornado o valor do item
Local aValues			:= {}										//Armazena temporariamente os valores do item
Local aArea			:= GetArea()								//Salva a area
Local nReturnPrice	:= 0										//Retorna o resultado da funcao
Local cTabPad			:= Pad(SuperGetMv("MV_TABPAD"),TamSx3("DA0_CODTAB")[1])			// Parametro da tabela de preco padrao	
Local lCenVen			:= SuperGetMv("MV_LJCNVDA")				//Cenario de vendas
Local aTabsPrecos		:= {}										//tabelas de preço
Local nPos		:=0
Local cParam := STBParam()[1] //Retorna o valor dos parametros para preco e se Retorna preco maior ou menor

Default cItemCode	:= ""
Default cCustomer	:= ""
Default cFil			:= ""
Default cStore		:= ""
Default nMoeda		:= 0
Default nQtde			:= 1

ParamType 0 Var 	cItemCode 	As Character	Default 	""
ParamType 1 Var 	cCustomer 	As Character	Default 	""
ParamType 2 Var 	cFil 		As Character	Default 	""
ParamType 3 Var 	cStore 	As Character	Default 	""
ParamType 4 Var 	nMoeda 	As Numeric		Default 	0
ParamType 5 Var	nQtde		As Numeric		Default	1

If lCenVen //.And. FindFunction("STDTabsPre")
	
	aTabsPrecos := fTabsPre(cItemCode) 
	
	For nX := 1 To Len(aTabsPrecos)
				
		nRet := MaTabPrVen(/*cTabPada */aTabsPrecos[nX]		,		cItemCode	,	nQtde				,	cCustomer		,; 
								cStore			,  		nMoeda		, 	/*dDataVld*/	,	/*nTipo*/		,;
								/*lExec*/		)

		If nRet > 0
		  aAdd( aValues,{aTabsPrecos[nX] ,nRet} )
		EndIf
	Next nX
	
	CoNout('Cenario de vendas ativo, tabela de preco: ' + AllTrim(cTabPad))
	
EndIf

//Sendo o aValores maior que um, significa que existe mais de 
//um preco possivel para um unico produto na venda           

If Len(aValues) > 0
	
	//Retornando os valores, ordena do menor para o maior para 
	//ser tomada a decisao posteriormente                     
	
	ASort(aValues,,,{|x,y| x[2]< y[2]})
	
	//Verifica o parametro MV_LJRETVL 
  	If cParam == "1" //utilizara o menor preco encontrado
  		nReturnPrice := aValues[1][2]
  	ElseIf cParam == "2" //utilizara o maior valor encontrado
		nReturnPrice := aValues[Len(aValues)][2]	
	elseIf cParam == "3" //utilizará a tbl de preço infoRmada no parÂmetro "MV_TABPAD"
		nPos := Ascan(aValues,{|x| x[1]== cTabPad})
		If ( nPos <> 0 )
			nReturnPrice := aValues[nPos,2]	
		EndIf	  		
  	EndIf  		 
EndIf			
	
RestArea(aArea)
	
Return nReturnPrice

//--------------------------------------------------------
/*/{Protheus.doc} STDTabsPre
Funcao para recuperar as tabelas de preço do produto.
@param   	Produto a ser consultado.
@author  	Yuri Porto
@version 	P11.8
@since   	24/06/2016
@return  	Tabelas DA1 (Tabelas de peço), onde o produto exista
@obs		Função original STDTabsPre TOTVSPDV
/*/
//--------------------------------------------------------
Static Function fTabsPre(cItemCode,cMvLjRetVl) 

Local aAreaDA1 		:= {}	//Guarda area
Local aAreaDA0 		:= {}	//Guarda area
Local aRet		 		:= {}	//retorno
Local cSeek			:= ""	//Seek de busca DA0
Local cTabPad	    	:= ""  //Tabela de preco padrao

Default cItemCode 	:= " "	
Default cMvLjRetVl 	:= SuperGetMV("MV_LJRETVL",,"3") // 1=Retorna o menor preco de uma tabela | 2=Retorna o maior preco de uma tabela | 3=Considera preco da tabela configurada no parametro MV_TABPAD

//Quando configurado para retornar preco da MV_TABPAD(cMvLjRetVl=3), 
//nao realiza a busca na DA1, apenas retorna o conteudo do TABPAD
If cMvLjRetVl == "3"
	cTabPad	:= Padr(AllTrim(SuperGetMv("MV_TABPAD",,"")),TamSX3("DA0_CODTAB")[1])		// Tabela de preco padrao
	aAdd(aRet, cTabPad)		
Else
	aAreaDA1 := DA1->(GetArea())
	aAreaDA0 := DA0->(GetArea())
	
	DbSelectArea ("DA0")
	DA0->(DbSetOrder(1))	//DA0_FILIAL+DA0_CODTAB

	cSeek	:= xFilial("DA0")
	LjGrvLog( cItemCode, "Ira pesquisar tabelas da DA0 onde o produto possui cadastro na DA1(MV_LJRETVL <> 3)")
	
	If DA0->(DbSeek(cSeek))
				
		While DA0->(!Eof()) .AND. DA0->DA0_FILIAL == cSeek	//percorre todas as tabelas cadastradas ativas/vigentes (Regra padrao fica centralizada na rotina MaTabPrVen), nesse ponto é realizado validacao basica			
			DA1->(DbSetOrder(1))	//DA1_FILIAL+DA1_CODTAB+DA1_CODPRO+DA1_INDLOT+DA1_ITEM
			
			If DA1->(DbSeek(DA0->DA0_FILIAL+DA0->DA0_CODTAB+cItemCode))	//Verifica se item cadastrado na tabela	
				aAdd(aRet, DA0->DA0_CODTAB )	
			EndIf		
						
			DA0->(DbSkip())	
		EndDo 
	EndIf
	
	LjGrvLog( cItemCode, "Tabelas encontradas com item na DA1:",aRet)
	
	RestArea(aAreaDA1)
	RestArea(aAreaDA0)
	
EndIf

Return(aRet)

 
//-------------------------------------------------------------------
/*/{Protheus.doc} STBItemRlDi
Function Regra de Desconto

@param 	 nItemLine			Número do Item
@param 	 cItemCode			Codigo Produto
@param 	 nValueItem			Valor
@param 	 nAmount			Quantidade
@param 	 cTypeProd			Tipo do Produto Mostruario/Saldao
@param 	 cCliCode			Código do Cliente
@param 	 cCliStore			Codigo da Loja
@author  Varejo
@version P11.8 
@since   29/03/2012
@return  aRet[1]	   		LRULEAPPLY		   			1 // Alguma regra foi aplicada?
@return  aRet[2]	   		NNEWTOTAL			 		2 // Valor total despois da aplicada(s) a(s) regra(s)
@return  aRet[3]	  		NPERDESCTO					3 // Percentual de desconto total aplicado em relacao ao valor total antigo
@return  aRet[4]	  		NOLDTOTAL					4 // Valor total antes da aplicada(s) a(s) regra(s) 
@obs     					
@sample
/*/
//-------------------------------------------------------------------
Static Function fItemRlDi( 	nItemLine	, cItemCode 	, nValueItem 	, nAmount ,	cTypeProd	, cCliCode		, cCliStore				)
                                                                          
Local aRet					:= {}			// Retorno da Funcao
Local lApplyRule			:= .F.			// Aplicou alguma Regra de Desconto?  
Local nNewValueItem			:= 0			// Novo valor do Item
Local nValueDiscount		:= 0			// Valor do desconto que foi aplicado
Local nDiscPerTotal			:= 0			// Percentual total do desconto pela(s) regras(s). Pode ocorrer mais de uma regra.
Local nTotValueDiscount		:= 0			// Valor total dos descontos aplicados acumulados
Local aRules				:= {}			// Regras de Desconto no Total 
Local aAppRules				:= {}			// Armazena Informacoes das Regras Aplicadas
Local nI					:= 0 			// Contador
Local nQuantBuy				:= 0            // Contador da quantidade de produtos já comprados e que estao na cesta
Local lDel 					:= .F.          // Variavel de controle de itens cancelados da cesta
Local nTotBrinde            := 0            // Quantidade total de brindes 
Local yI					:= 0 			// Contador
Local xI					:= 0 			// Contador
Local nX					:= 0 			// Contador
Local nTotRegras            := 0            // Total de regras de desconto
Local aProduto 				:= {}           // Array com as informações do produto a ser consultado se existe estoque 
Local aLocal   				:= {}			// Array com as informações sobre a loja do produto que devera ser consultado se existe estoque
Local aSldEst               := {}			// Array de retorno da função "Lj7SldEst" que consta as informações sobre o estoque 
Local aBrindes              := {}           // Array com os brindes disponiveis em estoque
Local aBonificados          := {}           // Array com as bonificacoes da regra
Local nReGRAQTDE            := 0            // Quantidade de produtos necessarios comprar para ganhar o brinde.
Local nCont 				:= 0            // Contador do array que armazena o brindes disponiveis no estoque
Local nPrice 				:= 0            // preco do item bonificado
Local cTPRegra              := ""           // Tipo de regra (Item ou Total)
Local cRefGrid              := ""           // referencia do item(produto ou regra do total) na grid
Local cProduto              := ""           // Produto da grid MB8
Local nSumRegraQtde         := 0            // Variavel para controle de regra acumulativa por item - MB8
Local lOK                   := .T.          // Controla a aplicacao das regras de Desconto
Local lGrava           	    := .T.          // Controle sobre a gravacao do brinde
Local nPosQuant	   			:= 0			// Posição Quantidade (*)
Local nQuant				:= 0			// Quantidade (*)
local nRegMulti				:= 0			// Utilizado para verificar se regra é multipla
local nItemMult				:= 0			// Verifica se quantidade é multipla da regra
local nItemRest				:= 0			// Verifica com a quantidade do item atual
local nxRest				:= 0			// Contador do For do Resto da divisão
local nTotRes				:= 0			// Resto da divisão de todos os intes do aCols
local nDesTotal				:= ""			// Desconto no total dos itens
local nDescTo				:= .T. 			// Valida se existe o campo
Local aSTItRlDisc			:= {}			//Retorno ponto de entrada

Local dRuleDate				:= SToD("")
Local dDateTmp				:= SToD("")

// Posições do retorno da função STDItemRlDi()
LOCAL MEI_CODREG := 1
LOCAL MEJ_PRINUM := 2
LOCAL MEI_ACUMUL := 3
LOCAL MEI_DESCRI := 4
LOCAL MB8_DESCPR := 5
LOCAL MB8_DESCVL := 6
LOCAL MB8_CODPRO := 7
//"PRO" // define se regra por PROduto ou por TOTal
LOCAL MB8_TPREGR := 9
//, // Usado para regras por total
//, // Usado para regras por total
//lCategory // define se tem categoria 

Default nItemLine  		:= 0	
Default cItemCode  		:= ""	
Default nValueItem 		:= 0
Default nAmount 		:= 1
Default cTypeProd  		:= ""
Default cCliCode   		:= ""
Default cCliStore  		:= ""

ParamType 0 Var  nItemLine 	As Numeric		Default 0
ParamType 1 Var  cItemCode 	As Character	Default ""
ParamType 2 Var  nValueItem		As Numeric		Default 0
ParamType 3 Var  nAmount		As Numeric		Default 1
ParamType 4 Var  cTypeProd		As Character	Default ""
ParamType 5 Var  cCliCode		As Character	Default ""
ParamType 6 Var  cCliStore		As Character	Default ""
    	
nValueItem 		:= nValueItem * nAmount 
nNewValueItem 	:= nValueItem

// Verifica regras ativas para o produto	
aRules := fRegrasIt( 	cItemCode 	, nValueItem , cTypeProd , cCliCode , cCliStore, "I"	)

If Len(aRules) > 0 

	/*/	
		Ordena o array pelo segundo campo MEJ->MEJ_PRINUM
	/*/ 
	aRules := aSort(aRules,,,{|x,y| x[MEJ_PRINUM] < y[MEJ_PRINUM]}) 
	
	nTotRegras := Len(aRules)
    
	For nI := 1 To Len(aRules)
	
		dDateTmp := Posicione("MEI", 1, xFilial("MEI")+aRules[nI][1], "MEI_DATATE")
		If dRuleDate > dDateTmp .Or. Empty(dRuleDate)
			dRuleDate := dDateTmp		
		EndIf
	
		If aRules[nI][8] == "PRO"
		
			DbSelectArea("MB8")
			MB8->(DbSetOrder(4))//Filial+Regra de desconto+Produto
			If MB8->(DbSeek(xFilial("MB8")+aRules[nI][1]+aRules[nI][7])) 
				If MB8->(FieldPos("MB8_TPREGR"))>0
					Do Case
						Case MB8->MB8_TPREGR = '1'//DESCONTO
							cTPRegra := '1'
						Case MB8->MB8_TPREGR = '2'//BONIFICACAO     					
							cTPRegra := '2'
						Case MB8->MB8_TPREGR = '3'//BRINDE	
							cTPRegra := '3'
					EndCase
				Else
					cTpRegra := ''
				Endif
		          
				cRefGrid := PADL(MB8->MB8_REFGRD, TamSX3("MB8_REFGRD")[1], "0")+"MB8"
				If Empty(cProduto)
					cProduto:= MB8->MB8_CODPRO  
				Endif  

				If Empty(alltrim(cProduto)) .And. (aRules[nI][12] == .T.)//Produto de Categoria
					cProduto := alltrim(cItemCode)
				Endif 
			Else
				//Regra de negocio por Categoria
				MB8->(DbSetOrder(1))//Filial+Regra de desconto+Produto
				If MB8->(DbSeek(xFilial("MB8")+aRules[nI][1])) 
					If MB8->(FieldPos("MB8_TPREGR"))>0
						Do Case
							Case MB8->MB8_TPREGR = '1'//DESCONTO
								cTPRegra := '1'
							Case MB8->MB8_TPREGR = '2'//BONIFICACAO     					
								cTPRegra := '2'
							Case MB8->MB8_TPREGR = '3'//BRINDE	
								cTPRegra := '3'
						EndCase
					Else
						cTpRegra := ''
					Endif
					cRefGrid := PADL(MB8->MB8_REFGRD, TamSX3("MB8_REFGRD")[1], "0")+"MB8"
					cProduto := alltrim(cItemCode)
				Endif
			Endif
		Else
			
			cTPRegra := aRules[nI][9]  //que corresponde ao campo MB2_TPREGR
			cRefGrid := aRules[nI][10]+"MB2" //que corresponde ao campo MB2_REFGRD
			cProduto := ""// quando a regra for por total nao existe produto
		
		EndIf
		
		// Verifica campo MB8_DESCTO
		nDescTo := MB8->(ColumnPos("MB8_DESCTO")) > 0 
		If nDescTo
			nDesTotal := MB8->MB8_DESCTO
		Endif	
		
		Do Case
			Case cTPRegra = '1'//DESCONTO     
				/*/	
					Calculo dos valores da regra. (Acumulativo para mais de uma regra)
				/*/ 											
				//Validacao por quantidade
				If !Empty(MB8->MB8_QTDPRO)
					lOK := .F.
					nItemMult := Mod((nQuantBuy +1), MB8->MB8_QTDPRO)
					nItemRest := 1 //Mod(oModelSL2:GetValue("L2_QUANT"), MB8->MB8_QTDPRO)
					
					/*/ Considera desconto no total de todos os itens. Desconto aplicado somente ao utilizar o campo MB8_DESCTO prenchido com "1".
					EX: Item 001 - Preço 100,00 - Desconto 50,00. Adicionado: 5*001 (Sistema irá conceder um desconto de R$ 250,00 reais) /*/
					If nDesTotal == "1" .and. nPosQuant > 0
						// Multiplo de Quantidade.
						/*/Concede o desconto no total dos itens toda vez que a quantidade de itens for maior ou igual a Qtd. Venda./*/
						If MB8->MB8_QTDMUL $ "1/S" .and. nQuant >= MB8->MB8_QTDPRO  
								lOK := .T.				
						// Não é múltiplo de quantidade 
						Elseif ( MB8->MB8_QTDMUL $ "2/N" .OR. Empty(MB8->MB8_QTDMUL) ) 
							nSumRegraQtde := MB8->MB8_QTDPRO 
						   	If ((nQuantBuy+1) == nSumRegraQtde) .or. nQuant >= MB8->MB8_QTDPRO 
								lOK := .T.
						   	Endif
						Endif
					/*/ Considera desconto somente no último item, apos atingir a quantidade definida no campo MB8->MB8_QTDPRO /*/  
					Elseif nDesTotal <> "1"
						//Regra por Compra acumulativa do mesmo produto, verifica se produto é multiplo
						If MB8->MB8_QTDMUL $ "1/S" .and. nPosQuant <= 1 .and. nItemMult == 0
							If (nQuantBuy + 1) >= MB8->MB8_QTDPRO
								lOK := .T.	
							Endif					
						//É multiplo e quantidade foi digitada por (*)				
						ElseIf MB8->MB8_QTDMUL $ "1/S" .and. (nQuant + nItemRest) >= MB8->MB8_QTDPRO  
							// Verifica todos os itens lançados e analisa o resto da divisão
							For nxRest := 1 to oModelSL2:Length()
								nTotRes += oModelSL2:GetValue("L2_QUANT", nxRest)			
							Next nxRest
							If Mod((nTotRes + nQuant), MB8->MB8_QTDPRO) == 0 .or. (Mod(nTotRes, MB8->MB8_QTDPRO) == 0 .and. nQuant  >= MB8->MB8_QTDPRO);
								.or. Mod((nTotRes), MB8->MB8_QTDPRO) + nQuant  >= MB8->MB8_QTDPRO
								lOK := .T.
							EndIf		
						//Não é Multiplo de Quantidade
						ElseIf ( MB8->MB8_QTDMUL $ "2/N" .OR. Empty(MB8->MB8_QTDMUL) ) 
					        nSumRegraQtde := MB8->MB8_QTDPRO 
						    If ((nQuantBuy+1) == nSumRegraQtde) .or. nQuant >= MB8->MB8_QTDPRO 
								lOK := .T.
						    Endif
						Else
							lOK := .F.								  
						Endif 
					Endif 
				Endif

				If lOK       
					Do Case
						Case aRules[nI][MB8_DESCPR] > 0 // PERCENTUAL
														
							If !((nValueItem - (nValueItem * (aRules[nI][MB8_DESCPR] / 100 ))) < 0.01)
									
					   			lApplyRule := .T. 
					   			/*/	
									Realizar calculos sempre por valor						   			
								/*/ 
								nRegMulti := (nQuant + nItemRest) / MB8->MB8_QTDPRO
				
								// Produto multiplo digitado através do (*)
								If nQuant > 1 .and. MB8->MB8_QTDMUL $ "1/S" .and. nDesTotal <> "1"								
									nValueDiscount 	:= ((nValueItem/nAmount) * ( aRules[nI][MB8_DESCPR] / 100 )) * Int(nRegMulti)
								// Não é multiplo e desconto no total dos itens ativo
								Elseif ( MB8->MB8_QTDMUL $ "2/N" .OR. Empty(MB8->MB8_QTDMUL) ) .and. nDesTotal == "1"								
									nValueDiscount 	:=  (((nValueItem/nAmount) * MB8->MB8_QTDPRO) * ( aRules[nI][MB8_DESCPR] / 100 ))
								// É multiplo e desconto no total dos itens ativo
								Elseif MB8->MB8_QTDMUL $ "1/S" .and. nDesTotal == "1"								
									nValueDiscount 	:=  nValueItem * ( aRules[nI][MB8_DESCPR] / 100 )	
								Else
									nValueDiscount 	:= ((nValueItem/nAmount) * ( aRules[nI][MB8_DESCPR] / 100 ))
								EndIf
							   	nTotValueDiscount 	:= nTotValueDiscount + nValueDiscount
							   	nNewValueItem 		:= nValueItem - nValueDiscount
								   			
							   	AADD( aAppRules , { aRules[nI] } ) 
					   			
				   			EndIf
			
						Case aRules[nI][MB8_DESCVL] > 0 // VALOR
						
							If !(( aRules[nI][MB8_DESCVL] * nAmount ) > nNewValueItem ) .AND. !((nNewValueItem - ( aRules[nI][MB8_DESCVL] * nAmount )) < 0.01)					
								
								lApplyRule := .T.
					   			/*/	
									Realizar calculos sempre por valor						   			
								/*/														 						   								   		   
								nRegMulti := (nQuant + nItemRest) / MB8->MB8_QTDPRO
							
								// Produto multiplo digitado através do (*)
								If nQuant > 1 .and. MB8->MB8_QTDMUL $ "1/S" .and. nDesTotal <> "1"	
									nValueDiscount 	:= aRules[nI][MB8_DESCVL] * Int(nRegMulti)
								// Produto não multiplo e desconto no total dos itens ativo
								Elseif ( MB8->MB8_QTDMUL $ "2/N" .OR. Empty(MB8->MB8_QTDMUL) ) .and. nDesTotal == "1"								
									nValueDiscount 	:=  (aRules[nI][MB8_DESCVL] * nQuant)
								// Produto multiplo e desconto no total dos itens ativo	 
								Elseif MB8->MB8_QTDMUL $ "1/S" .and. nDesTotal == "1"								
									nValueDiscount 	:=  (aRules[nI][MB8_DESCVL] * nQuant)
								Else										 						   								   		   
									nValueDiscount 	:= aRules[nI][MB8_DESCVL]
								EndIf
						   			nTotValueDiscount	:= nTotValueDiscount + nValueDiscount
						   			nNewValueItem 		:= nValueItem - nValueDiscount						   			
						   			
						   			AADD( aAppRules , { aRules[nI] , aRules[nI] } )
					   		
							EndIf
							
			    	EndCase
			    	
			    	Exit
			    	                                
		    	Endif
	   
		EndCase  
		
	Next nI
	
EndIf


AADD( aRet , lApplyRule 			)
AADD( aRet , nNewValueItem 		)
AADD( aRet , nTotValueDiscount 	)
AADD( aRet , nDiscPerTotal 		)
AADD( aRet , nValueItem 			)
AADD( aRet , dRuleDate			)	
		
																													
Return aRet		

//-------------------------------------------------------------------
/*/{Protheus.doc} STDItemRlDi
Function Busca Regras de Desconto do Tipo Item

@param 	 cItemCode			Codigo do Item
@param 	 nValueItem			Valor do Item
@param 	 cTypeProd			Tipo Saldão ou mostruário
@param	 cCliCode			Codigo do cliente
@param	 cCliStore			Loja do Cliente
@author  Varejo
@version P11.8
@since   29/03/2012
@return  aRet[1] MEI_CODREG					1 Codigo da Regra
@return  aRet[2] MEJ_PRINUM	  				2 Prioridade da Regra
@return  aRet[3] MEI_ACUMUL					3 Indica se a Regra é acumulativa
@return  aRet[4] MEI_DESCRI					4 Descrição da Regra
@obs										Verifica condicoes de Filial, Hora/Data/Semana e Cliente. Nao verifica o Range de Valores
@sample
/*/
//-------------------------------------------------------------------
Static Function fRegrasIt( 	cItemCode 	, nValueItem , cTypeProd , cCliCode , cCliStore, cTyPeCall	)

Local aArea			:= GetArea()		// Guarda Alias Corrente
Local aRet 			:= {}           // Retorna regras validas  
Local aRange			:= {}				// Armazena Range de valores
Local lCategory		:= .F.				// Indica se existe categoria para o produto
Local cCategory		:= ""				// Armazena categoria do produto
Local nI            := 0                // Variavel contador

Default cItemCode 	:= ""	
Default nValueItem 	:= 0
Default cTypeProd 	:= ""
Default cCliCode 	:= ""
Default cCliStore 	:= ""
Default cTyPeCall   := "I" //"I" = Item, "T" = Total 

ParamType 0 var  cItemCode 	As Character Default ""
ParamType 1 var  nValueItem		As Numeric	   Default 0
ParamType 2 var  cTypeProd		As Character Default ""
ParamType 3 var  cCliCode		As Character Default ""
ParamType 4 var  cCliStore		As Character Default ""

/*/	
	Se existir categoria no produto, vai pesquisar nas regras por categoria
/*/ 
DbSelectArea("ACV")                              
DbSetOrder(5) //ACV_FILIAL+ACV_CODPRO+ACV_CATEGO
If DbSeek(xFilial("ACV") + alltrim(cItemCode))
	cCategory 	:= ACV->ACV_CATEGO 
	lCategory	:= .T.
EndIf

/*/	
	Busca regra por Categoria
/*/ 
If lCategory
	DbSelectArea("MB8")
	DbSetOrder(3)//MB8_FILIAL+MB8_CATEGO
	If DbSeek(xFilial("MB8") + cCategory ) //MB8_FILIAL+MB8_CATEGO
		While !MB8->(Eof()) .AND. AllTrim(MB8->MB8_CATEGO) == AllTrim(cCategory)
			DbSelectArea("MEI")
			DbSetOrder(1)//MEI_FILIAL+MEI_CODREG
			If DbSeek(xFilial("MEI") + MB8->MB8_CODREG )
			
				If (MEI->MEI_TPIMPD == cTyPeCall) .And. (MEI->MEI_ATIVA = "1") //só irá consultar regras ATIVAS
	
					If fValRule( cCliCode , cCliStore ) // Validacao generica por Data, Ativa, Cliente, Grupo de cliente, Filial e Prioridade
		        		
	                    cPriority := fPriority( MEI->MEI_CODREG ) // Busca prioridade (MEJ_PRINUM)
	                    
	          			AADD( aRet , { 	MEI->MEI_CODREG , cPriority 		, MEI->MEI_ACUMUL , MEI->MEI_DESCRI , ;
	          			 				MB8->MB8_DESCPR , MB8->MB8_DESCVL	, "","PRO",MB8->MB8_TPREGR,,,lCategory} )          			 				
		          			   
					EndIf	
				Endif	
			EndIf
			MB8->(DbSkip())
		EndDo
	EndIf
EndIf

/*/	
	Busca regra por produto
/*/ 
DbSelectArea("MB8")
DbSetOrder(2) //MB8_FILIAL+MB8_CODPRO
If DbSeek(xFilial("MB8") + cItemCode ) //MB8_FILIAL+MB8_CODPRO      
	While !MB8->(EOF()) .AND. AllTrim(MB8->MB8_CODPRO) == AllTrim(cItemCode)
		DbSelectArea("MEI")
		DbSetOrder(1)//MEI_FILIAL+MEI_CODREG
		If DbSeek(xFilial("MEI")+ MB8->MB8_CODREG )
		
        	If (MEI->MEI_TPIMPD == cTyPeCall) .And. (MEI->MEI_ATIVA = "1") //só irá consultar regras ATIVAS
        	
	        	If fValRule( cCliCode , cCliStore ) // Validacao generica
	        		
                    cPriority := fPriority( MEI->MEI_CODREG ) // Busca prioridade (MEJ_PRINUM)
                    
          			AADD( aRet , { 	MEI->MEI_CODREG , cPriority	, MEI->MEI_ACUMUL , MEI->MEI_DESCRI , ;
          			 				MB8->MB8_DESCPR , MB8->MB8_DESCVL, MB8->MB8_CODPRO,"PRO",MB8->MB8_TPREGR,,,lCategory	} )          			 				
	          			   
				EndIf
			EndIf
		EndIf  
		MB8->(DbSkip())		
	EndDo
EndIf

/*/	
	Busca regra por Range(Todos os produtos desde que pertenca ao Range)
/*/ 
DbSelectArea("MEI")
DbSetOrder(3) //ME1_FILIAL+ME1_TIPO
If DbSeek(xFilial("MEI") + "I")
	While !MEI->(Eof()) 
	  		    
		    If MEI->MEI_ATIVA = "1" .And. (MEI->MEI_TPIMPD == cTyPeCall) 
		/*/	
			Busca Range para a regra.
		/*/ 
		aRange := STDIteRang( MEI->MEI_CODREG , nValueItem )
		
		If Len(aRange) > 0
		
			If fValRule( cCliCode , cCliStore ) // Validacao generica	
			    
				cPriority := fPriority( MEI->MEI_CODREG ) // Busca prioridade (MEJ_PRINUM)
				
						For nI := 1 to len(aRange)
							AADD( aRet , { 	MEI->MEI_CODREG , cPriority , MEI->MEI_ACUMUL , MEI->MEI_DESCRI , ;
		          						aRange[nI][3]	, aRange[nI][4]	, ,"TOT", aRange[nI][5], aRange[nI][6],aRange[nI][2],lCategory} )
		          		Next nI				
					EndIf			
				EndIf		
			Endif
		MEI->(DbSkip())		
	EndDo
EndIf	

RestArea( aArea )

Return aRet


//-------------------------------------------------------------------
/*/{Protheus.doc} STDValRule
Function Validacao da Regra de Desconto

@param 	 cCliCode			Código do cliente
@param 	 cCliStore			Loja do cliente
@author  Varejo
@version P11.8
@since   29/03/2012
@return  lRet				Retorna se a regra é válida
@obs     					Verifica condicoes de Filial, Hora/Data/Semana e Cliente. Nao verifica o Range de Valores
@sample
/*/
//-------------------------------------------------------------------
Static Function fValRule( cCliCode , cCliStore )

Local aArea		   			:= GetArea()		// Alias Corrente
Local lRet		   			:= .T.				// Retorna se a regra eh valida 
Local aFilMB3				:= {}				// Filiais da regra de desconto
Local lA1_CLIFUN			:= SA1->(ColumnPos("A1_CLIFUN")) > 0 //Importante: esta validação deve ser mantida, pois este campo existe no compatibilizador da 11.80 e não existe no dicionário da 12
Local cCliFun				:= "" //Cliente Funcionario?
Local lAI0_CLIFU			:= AI0->(ColumnPos("AI0_CLIFUN")) > 0 //Foi protegido este campo pois este programa vai subir na release 12.1.16 e campo na posterior


Default cCliCode				:= ""				
Default cCliStore			:= ""				

ParamType 0 var  cCliCode 		As Character	Default ""				
ParamType 1 var  cCliStore		As Character	Default ""	

/*/	
	ATIVA
/*/
If lRet
	If (MEI->MEI_ATIVA <> "1")
		lRet := .F.
	EndIf
EndIf
/*/	
	CLIENTE LOJA
/*/
If lRet 
	If !Empty(AllTrim( MEI->MEI_CODCLI + MEI->MEI_LOJA )) .AND. ( AllTrim( MEI->MEI_CODCLI + MEI->MEI_LOJA ) <> AllTrim( cCliCode + cCliStore ) )
		lRet := .F.
	EndIf
EndIf

/*/	
	GRUPO CLIENTE
/*/	
If lRet         	    
	If !Empty(AllTrim(MEI->MEI_GRPVEN))
		DbSelectArea("SA1")
		DbSetOrder(1) 
		If DbSeek(xFilial("SA1")+ cCliCode + cCliStore)	
			If SA1->A1_GRPVEN <> MEI->MEI_GRPVEN
				lRet := .F.
			Endif	
		Endif
	Endif		
EndIf	

/*/	
	Se a regra for por desconto de funcionario, porem no cad de cliente nao estiver como desconto de funcionario nao se aplica a regra
/*/ 

If lRet
	If (MEI->MEI_DESFUN == "S") 
	
		If lAI0_CLIFU
			cCliFun := GetAdvFVal("AI0","AI0_CLIFUN",xFilial("AI0")+cCliCode + cCliStore,1,"2")
		EndIf
		
		If Empty(cCliFun) .AND. lA1_CLIFUN
			cCliFun := GetAdvFVal("SA1","A1_CLIFUN",xFilial("SA1")+cCliCode + cCliStore,1,"2")
		EndIf
		If !(cCliFun  == "1")
			lRet := .F.
		EndIf 
	EndIf	
EndIf 

/*/	
	DIA, DATA E HORA
/*/
If lRet 
	If !(fValidPer( MEI->MEI_DATDE , MEI->MEI_DATATE , MEI->MEI_CODREG ))
		lRet := .F.
	EndIf
EndIf  

/*/	
	FILIAL
	Valida tambem Grupo de Filiais
/*/
If lRet	
	
	DbSelectArea("MB3")
	DbSetOrder(3) // MB3_FILIAL+MB3_CODREG+MB3_TIPO+MB3_CODGRU+MB3_CODEMP+MB3_CODFIL
	
	If DbSeek( xFilial("MB3") + MEI->MEI_CODREG ) 
	
		While MB3->( !Eof() .And. MB3_FILIAL+MB3_CODREG == xFilial("MB3")+MEI->MEI_CODREG )
		
			// 1. Tipo Filial
			// 2. Tipo Grupo de Filiais
			
			IF MB3->MB3_TIPO == "1"
	
				If MB3->MB3_CODEMP == SubStr(cNumEmp,1,2)

					aAdd( aFilMB3 , MB3->MB3_CODFIL )
				
				Endif
			
			ElseIF MB3->MB3_TIPO == "2"
			
				// Explode o grupo de filiais
				SAU->(dbSetOrder(1))
				IF SAU->( dbSeek( xFilial("SAU") + MB3->MB3_CODGRU ) )             
				
					While SAU->( !EOF() .And. SAU->AU_FILIAL+RTrim(SAU->AU_CODGRUP) == xFilial("SAU")+RTrim(MB3->MB3_CODGRU) )
						
						If Ascan( aFilMB3 , SAU->AU_CODFIL ) == 0  						
							aAdd( aFilMB3 , SAU->AU_CODFIL )
						Endif					
						SAU->( DbSkip() )
										
					End
								
				Endif
				
			Endif
		
			MB3->( DbSkip() )
			
		End
		
		
		// Verifica se a filial esta entre as filiais permitidas
		If Ascan( aFilMB3 , FWCodFil() ) == 0
			lRet := .F.			
		Endif		
	
	Else
		lRet := .F.	
	EndIf

EndIf
  	
/*/	
	PRIORIDADE
/*/
If lRet
	DbSelectArea("MEJ")
	DbSetOrder(2) //MEJ_FILIAL+MEJ_CODREG
	If !(DbSeek(xFilial("MEJ") + MEI->MEI_CODREG))
		lRet := .F.
	EndIf
EndIf						
				
RestArea( aArea )

Return lRet


//-------------------------------------------------------------------
/*/{Protheus.doc} STDValidPer
Function Valida o período da regra.

@param 	 dDatDe		 		Data inicial da regra
@param 	 dDatAte			Data final da regra
@param 	 cCodReg			Codigo da regra

@author  Varejo
@version P11.8
@since   29/03/2012
@return  lRet				Retorna se a regra é válida
@obs     					Verifica condicoes de Data, Hora e Dia da Semana
@sample
/*/
//-------------------------------------------------------------------
Static Function fValidPer( dDatDe, dDatAte, cCodReg )   

Local aArea		:= GetArea()		// Posicionamento atual
Local lRet     	:= .F.				// Retorno da Funcao
Local cTime    	:= Time()			// Horario atual da chamada da funcao para validar com horario da regra
Local dData    	:= Date()			// Armazena a data atual para validar a data da regra
Local cDiaSem  	:= CDOW(dData)		// Converte data para um dia da semana   
Local aHora    	:= {}				// Armazena a hora da regra para validar horario   

Default dDatDe 	:= CTOD(" ")	
Default dDatAte := CTOD(" ")	
Default cCodReg := ""			

ParamType 0 var  dDatDe 		As Date			Default CTOD(" ")				
ParamType 1 var  dDatAte		As Date			Default CTOD(" ")	
ParamType 2 var  cCodReg		As Character		Default ""	

/*/	
	Valida se a data informada e permitida para aplicar a regra de acordo com a data atual
/*/ 
If (dData >= dDatDe) .And. (dData <= dDatAte)
	DbSelectArea("MB7")
	DbSetOrder(1) //MB7_FILIAL+MB7_CODREG
	If DbSeek(xFilial("MB7") + cCodReg)  
		Do Case   
		Case Upper(cDiaSem) == "SUNDAY"		//Domingo
			aHora := {AllTrim(MB7->MB7_HRDOMI), AllTrim(MB7->MB7_HRDOMF)}
		Case Upper(cDiaSem) == "MONDAY"		//Segunda
			aHora := {AllTrim(MB7->MB7_HRSEGI), AllTrim(MB7->MB7_HRSEGF)}
		Case Upper(cDiaSem) == "TUESDAY"	//Terca
			aHora := {AllTrim(MB7->MB7_HRTERI), AllTrim(MB7->MB7_HRTERF)}
		Case Upper(cDiaSem) == "WEDNESDAY" //Quarta
			aHora := {AllTrim(MB7->MB7_HRQUAI), AllTrim(MB7->MB7_HRQUAF)}
		Case Upper(cDiaSem) == "THURSDAY"	//Quinta
			aHora := {AllTrim(MB7->MB7_HRQUII), AllTrim(MB7->MB7_HRQUIF)}
		Case Upper(cDiaSem) == "FRIDAY"		//Sexta
			aHora := {AllTrim(MB7->MB7_HRSEXI), AllTrim(MB7->MB7_HRSEXF)} 
		Case Upper(cDiaSem) == "SATURDAY"	//Sabado
			aHora := {AllTrim(MB7->MB7_HRSABI), AllTrim(MB7->MB7_HRSABF)}
		End
	EndIf
	MB7->(DbCloseArea())
EndIf


// Valida se a hora da regra e permitida para ser aplicada de acordo  
// com a data atual.                                                 

If Len(aHora) < 1
	lRet := .F. 
Else
	If cTime > aHora[1] .And. cTime < aHora[2]
		lRet := .T.	
	EndIf
EndIf

RestArea(aArea)	

Return lRet 


//-------------------------------------------------------------------
/*/{Protheus.doc} STDPriority
Function Busca Prioridade da Regra

@param 	 cCodRule			Código da regra de desconto
@author  Varejo
@version P11.8
@since   29/03/2012
@return  cPriority				Retorna prioridade da regra
@obs     					
@sample
/*/
//-------------------------------------------------------------------
Static Function fPriority( cCodRule )

Local aArea		 		:= GetArea()			// Armazena alias corrente
Local aAreaMEJ			:= MEJ->(GetArea())    // Armazena Posicao MEJ
Local cPriority			:= ""	   				// Retorno funcao

Default cCodRule 		:= ""	 	  	

ParamType 0 Var  cCodRule As Character Default ""

If !Empty( cCodRule )
	DbSelectArea("MEJ")
	DbSetOrder(2)//MEJ_FILIAL+MEJ_CODREG
	If DbSeek( xFilial("MEJ") + cCodRule )
		cPriority := MEJ->MEJ_PRINUM
	EndIf
EndIf

RestArea(aAreaMEJ)
RestArea(aArea)
				
Return cPriority