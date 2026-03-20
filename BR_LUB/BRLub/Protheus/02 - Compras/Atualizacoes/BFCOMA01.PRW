#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#include "protheus.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} BFCOMA01
Simulação de Compras - Compatibilidade
@type function
@version 1.0 
@author Marcelo Lauschner
@since 1/24/2005
/*/
User Function BFCOMA01()
	
Return U_BIG018()

/*/{Protheus.doc} BIG018
Função referente ao processo de simulação de compra
@type function
@version 1.0 
@author Marcelo Lauschner
@since 1/24/2005
/*/
User Function BIG018()
	
	Local	aSize 			:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Local	aInfo 			:= { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ],3,3 }
	Local	aPosObj,aPosGet,nGetLin
	Local	aObjects		:= {}
	Local	iZ
	Local	nSeq			:= 0
	Local 	cCampo			:= ""
	local   cUserGrv        := AllTrim( SuperGetMV( 'BF_GRVPDCO',,'' ) )
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	Private lGravar  		:= .T.
	Private aCondpag 		:= {}
	Private oConsulta
	
	Private aHeader 		:= {}
	Private aCols   		:= {}
	Private aCapAlt 		:= {}
	Private aRotina  		:= {{"Pesquisar", "AxPesqui", 0, 1},;
		{"Visualizar", "AxVisual", 0, 2},;
		{"Incluir"   , "AxInclui", 0, 3},;
		{"Alterar"   , "AxAltera", 0, 4},;
		{"Excluit"   , "AxDeleta", 0, 5}}
	Private cCod       	:= Space(15)  // Código Produto
	Private cDesc      	:= Space(45)  // Descrição Produto
	Private cSts       	:= Space(1)   // Status do Produto
	Private cUm        	:= Space(3)   // Unidade de medida
	Private nAno     		:= Year(dDataBase)
	Private nMes     		:= Month(dDatabase)
	Private cMes     		:= Space(4)
	Private cAno     		:= Space(4)
	Private cMes1 			:= Space(6)
	Private cMes2 			:= Space(6)
	Private cMes3 			:= Space(6)
	Private cMes4 			:= Space(6)
	Private cMes5 			:= Space(6)
	Private cMes6 			:= Space(6)
	Private cMes7 			:= Space(6)
	Private cMes8 			:= Space(6)
	Private cMes9  			:= Space(6)
	Private cMes10  		:= Space(6)
	Private cMes11  		:= Space(6)
	Private cMes12  		:= Space(6)
	Private cAno1 			:= Space(4)
	Private cAno2 			:= Space(4)
	Private cAno3 			:= Space(4)
	Private cAno4 			:= Space(4)
	Private nMes1      		:= 0          // Faturamento mês anterior
	Private nMes2      		:= 0          // Faturamento há dois meses
	Private nMes3      		:= 0         // Faturamento há três meses
	Private nMes4      		:= 0          // Faturamento há quatro meses
	Private nMes5      		:= 0          // Faturamento há 5 meses
	Private nMes6      		:= 0          // Faturamento há 6 meses
	Private nMes7      		:= 0          // Faturamento há 7 meses
	Private nMes8      		:= 0          // Faturamento há 8 meses
	Private nMes9      		:= 0          // Faturamento há 9 meses
	Private nMes10     		:= 0          // Faturamento há 10 meses
	Private nMes11     		:= 0          // Faturamento há 11 meses
	Private nMes12      	:= 0          // Faturamento há 12 meses
	Private nConsAtu   		:= 0          // Consumo mês atual
	Private nComp      		:= 0          // Saldo em pedidos de compra
	Private nPreviem   		:= 0			 // Previsão de faturamento para o período escolhido
	Private nAcomp	   		:= 0 		 // A comprar baseado na média do faturamento,estoque e previsão
	Private nAcomp1     	:= 0
	Private nSubcomp   		:= 0.00       // Valor do item para pedido de compra
	Private nMin       		:= 0		     // Quantidade minima para pedido de compra
	Private nConv      		:= 0          // Fator conversão
	Private nEst	   		:= 0			 // Estoque fisico
	Private nEstl      		:= 0          // Estoque liquido- baseado no estoque fisico subraindo todos os pedidos de venda em aberto
	Private nEstm	   		:= 0			 // Estoque mínimo de segurança
	Private nDiasEst   		:= 0          // Dias de estoque - baseado no estoque líquido divido pela previsão de venda
	Private nPrcConf   		:= 0.00	     // Preço de conferência cadastro SB1
	Private nTotcomp   		:= 0.00
	Private nPrccm1    		:= 0.00       // Custo médio SB2
	Private nPeso      		:= 0.000	     // Peso produto
	Private nLtMin     		:= 0.000      // Lote Minimo
	Private nSubPeso   		:= 0.000      // Subtotal Peso a comprar
	Private nSubPBruto 		:= 0.000 		// Subtotal peso bruto
	Private nTotPeso   		:= 0.000
	Private nTotBruto		:= 0.00
	Private nDest      		:= 0          // Dias de estoque cadastro SB1
	Private cFornece    	:= ""
	Private aFornOpc		:= {}
	Private oFornece
	Private aFornece    	:= {}
	Private nDias      		:= 0        // número de dias de estoque desejado
	Private nCons      		:= 0       // consumo reduzido de dias
	Private nPerc      		:= 0.00    // Percentual de acréscimo sobre o estoque desejado
	Private oPerc
	Private cObs  			:= Space (100)
	Private nQteCx 			:= 0
	Private cGera  			:= Space(4)
	Private aCab   			:= {}
	Private aItem   		:= {}
	Private aTotItem 		:= {}
	Private dEntrega  		:= dDatabase
	Private cTabPrc			:= Space(TamSX3("AIA_CODTAB")[1])
	Private cCondpag   		:= Space(3)
	Private aOrd   			:= {"Consumo Desc","Código","Descrição"}
	Private cOrd   			:= ""
	Private cTabela 		:= Substr(Dtos(dDatabase),3,4)
	private dNCPC     		:= DataValida(dDataBase)
	Private cPesq     		:= Space(15)
	Private cPesqd    		:= Space(40)
	Private oPesqd
	Private oPesq
	Private cSeq   			:= ""
	Private oSeq
	Private aSeq   			:= {"A comprar","Estoque Liquido","Consumo Atual"}
	Private nSq    			:= 0
	Private cLocPad		:= ""
	Private nOpcLoc		:= 0
	
	//³ Verificar se usuário vai acessar com nível de gravação ou apenas simulação
	PSWOrder(2)
	
	// Pesquisa se usuário existe
	If PSWSeek(cUserName,.T.)
		lGravar := __cUserID $ cUserGrv
	Else
		Alert("Usuario "+ AllTrim( cUserName ) +"invalido!!", 'Usuário inválido')
		Return		
	Endif
	
	If !lGravar
		MsgInfo("Voce tem permissao apenas para simulacao","Informacao")
	Endif
	
	Processa({|| Fornecedor()},"Processando Fornecedores")
	
	cMes  := Substr(DTOS(dDataBase),1,6)
	cMes1 := Substr(DTOS(FirstDay(dDataBase)-1),1,6)
	cMes2 := Substr(DTOS(STOD(cMes1+"01")-1),1,6)
	cMes3 := Substr(DTOS(STOD(cMes2+"01")-1),1,6)
	cMes4 := Substr(DTOS(STOD(cMes3+"01")-1),1,6)
	cMes5 := Substr(DTOS(STOD(cMes4+"01")-1),1,6)
	cMes6 := Substr(DTOS(STOD(cMes5+"01")-1),1,6)
	cMes7 := Substr(DTOS(STOD(cMes6+"01")-1),1,6)
	cMes8 := Substr(DTOS(STOD(cMes7+"01")-1),1,6)
	cMes9 := Substr(DTOS(STOD(cMes8+"01")-1),1,6)
	cMes10 := Substr(DTOS(STOD(cMes9+"01")-1),1,6)
	cMes11 := Substr(DTOS(STOD(cMes10+"01")-1),1,6)
	cMes12 := Substr(DTOS(STOD(cMes11+"01")-1),1,6)
	
	nCons    := Day(dDatabase)
	nSeq	:= 1
	//AADD(aHeadSE2,{ TRIM(x3titulo()),;SX3->X3_CAMPO,;SX3->X3_PICTURE,;SX3->X3_TAMANHO,;SX3->X3_DECIMAL,;".F.",;SX3->X3_USADO,;SX3->X3_TIPO,;SX3->X3_F3,;SX3->X3_CONTEXT,;SX3->X3_CBOX,;	SX3->X3_RELACAO,;		".T."})
	
	Private nPosCod		:= nSeq++
	/* 1 */AADD(aHeader,{ "Cód"										, "cCod"     	,"@!"		,15	,0	,"","û","C",""})
	Private nPosDesc	:= nSeq++
	/* 2 */AADD(aHeader,{ "Descricao" 								, "cDesc"    	,"@!" 		,40	,0	,"","û","C",""})
	Private nPosStatus  := nSeq++
	// DbSelectArea("SX3")
	// DbSetOrder(2)
	// DbSeek("B1_STS")
	// /* 3 */ AADD(aHeader,{ TRIM(x3titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,".T.",SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO,".T."})
	cCampo := "B1_STS"
	Aadd(aHeader,{AllTrim(GetSx3Cache(cCampo,"X3_TITULO")),;
		GetSx3Cache(cCampo,"X3_CAMPO")		,;
		GetSx3Cache(cCampo,"X3_PICTURE")	,;
		GetSx3Cache(cCampo,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo,"X3_DECIMAL")	,;
		".T."								,;
		GetSx3Cache(cCampo,"X3_USADO")		,;
		GetSx3Cache(cCampo,"X3_TIPO")		,;
		GetSx3Cache(cCampo,"X3_F3") 		,;
		GetSx3Cache(cCampo,"X3_CONTEXT")	,;
		GetSx3Cache(cCampo,"X3_CBOX")		,;
		GetSx3Cache(cCampo,"X3_RELACAO") 	,;
		".T."								})

	
	///* 3 */AADD(aHeader,{ "Status"									, "B1_STS"  	, ""        ,01	,0	,"","û","C",""})
	
	Private nPosMes12	:= nSeq++
	/* 4 */AADD(aHeader,{ Substr(cMes12,5,2)+"/"+Substr(cMes12,3,2)	, "nMes12"     	, ""        ,04	,0	,"","û","C",""})
	//Private nPosMes11	:= nSeq++
	///* 5 */AADD(aHeader,{ Substr(cMes11,5,2)+"/"+Substr(cMes11,3,2)	, "nMes11"     	, ""        ,04	,0	,"","û","C",""})
	//Private nPosMes10	:= nSeq++
	///* 6 */AADD(aHeader,{ Substr(cMes10,5,2)+"/"+Substr(cMes10,3,2)	, "nMes10"    	, ""        ,04	,0	,"","û","C",""})
	//Private nPosMes09	:= nSeq++
	///* 7 */AADD(aHeader,{ Substr(cMes9,5,2)+"/"+Substr(cMes9,3,2)	, "nMes9"     	, ""        ,04	,0	,"","û","C",""})
	//Private nPosMes08	:= nSeq++
	///* 8 */AADD(aHeader,{ Substr(cMes8,5,2)+"/"+Substr(cMes8,3,2)	, "nMes8"     	, ""        ,04	,0	,"","û","C",""})
	////Private nPosMes07	:= nSeq++
	///* 9 */AADD(aHeader,{ Substr(cMes7,5,2)+"/"+Substr(cMes7,3,2)	, "nMes7"     	, ""        ,04	,0	,"","û","C",""})
	Private nPosMes06	:= nSeq++
	/* 10 */AADD(aHeader,{ Substr(cMes6,5,2)+"/"+Substr(cMes6,3,2)	, "nMes6"     	, ""        ,04	,0	,"","û","C",""})
	Private nPosMes05	:= nSeq++
	/* 11 */AADD(aHeader,{ Substr(cMes5,5,2)+"/"+Substr(cMes5,3,2)	, "nMes5"     	, ""        ,04	,0	,"","û","C",""})
	Private nPosMes04	:= nSeq++
	/* 12 */AADD(aHeader,{ Substr(cMes4,5,2)+"/"+Substr(cMes4,3,2)	, "nMes4"     	, ""        ,04	,0	,"","û","C",""})
	Private nPosMes03	:= nSeq++
	/* 13 */AADD(aHeader,{ Substr(cMes3,5,2)+"/"+Substr(cMes3,3,2)	, "nMes3"   	, ""		,04	,0	,"","û","C",""})
	Private nPosMes02	:= nSeq++
	/* 14 */AADD(aHeader,{ Substr(cMes2,5,2)+"/"+Substr(cMes2,3,2)	, "nMes2"   	, ""        ,04	,0	,"","û","C",""})
	Private nPosMes01	:= nSeq++
	/* 15 */AADD(aHeader,{ Substr(cMes1,5,2)+"/"+Substr(cMes1,3,2)	, "nMes1"   	, ""        ,04	,0	,"","û","C",""})
	Private nPosCAtu	:= nSeq++
	/* 16 */AADD(aHeader,{ "C.Atu", "nConsAtu", ""          ,04,0,"","û","C",""})
	Private nPosnComp	:= nSeq++
	/* 17 */AADD(aHeader,{ "S.Com", "nComp"  , "@E 9,999"   ,04,0,"","û","N",""})
	Private nPosaComp	:= nSeq++
	/* 18 */AADD(aHeader,{ "Acp.", "nAcomp" , "@E 99,999"  ,05,0,'Execblock("BIG018A",.F.,.F.)',"û","N",""})
	Private nPosGera	:= nSeq++
	/* 19 */AADD(aHeader,{ "Com" , "cGera" , ""            ,01,0,,"û","C",})
	Private nPosnNewPr	:= nSeq++
	/* 20 */AADD(aHeader,{ "N.Prev" ,"nNewPre" , "@E 99,999"     ,05,0,'Execblock("BIG018B",.F.,.F.)',"û","N",})
	Private nPosEstLiq	:= nSeq++
	/* 21 */AADD(aHeader,{ "E.Liq", "nEstl"   ,"@E 99,999"   , 05, 0,, "û","N",})
	Private nPosAlvo	:= nSeq++
	// DbSelectArea("SX3")
	// DbSetOrder(2)
	// DbSeek("B1_EMAX")
	// /* 22 */ AADD(aHeader,{ "Alvo",SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,".T.",SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO,".T."})
	cCampo := "B1_EMAX"
	Aadd(aHeader,{"Alvo",;
		GetSx3Cache(cCampo,"X3_CAMPO")		,;
		GetSx3Cache(cCampo,"X3_PICTURE")	,;
		GetSx3Cache(cCampo,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo,"X3_DECIMAL")	,;
		".T."								,;
		GetSx3Cache(cCampo,"X3_USADO")		,;
		GetSx3Cache(cCampo,"X3_TIPO")		,;
		GetSx3Cache(cCampo,"X3_F3") 		,;
		GetSx3Cache(cCampo,"X3_CONTEXT")	,;
		GetSx3Cache(cCampo,"X3_CBOX")		,;
		GetSx3Cache(cCampo,"X3_RELACAO") 	,;
		".T."								})
	
	
	Private nPosLtMin	:= nSeq++
	/* 23 */AADD(aHeader,{ "Lt.Min", "nLtMin"   ,"@E 99,999"   , 05, 0,, "û","N",})
	Private nPosEstMin	:= nSeq++
	/* 24 */AADD(aHeader,{ "E.Min", "nEstm"   ,"@E 99,999"   , 05, 0,, "û","N",})
	Private nPosDiaEst	:= nSeq++
	/* 25 */AADD(aHeader,{ "D.Est"   , "nDiasest", "@E 999" , 04, 0,, "û", "N",})
	Private nPosPrcConf	:= nSeq++
	/* 26 */AADD(aHeader,{ "PrcConf"   , "nPrcConf" , "@E 9,999.99" , 04, 2,'Execblock("BIG018C",.F.,.F.)',"û","C",})
	Private nPosnMin	:= nSeq++
	/* 27 */AADD(aHeader,{ "Mín"    , "nMin"   , "@E 9,999"     , 04, 0,'Execblock("BIG018D",.F.,.F.)', "û","C",})
	Private nPosPeso	:= nSeq++
	/* 28 */AADD(aHeader,{ "Peso"       , "nPeso"       , "@E 99,999.999" ,08,3,,"û","C",})
	Private nPosSubPeso	:= nSeq++
	/* 29 */AADD(aHeader,{ "SubPeso"    , "nSubPeso"       , "@E 99,999.999" ,08,3,,"û","C",})
	Private nPosLitros	:= nSeq++
	/* 30 */AADD(aHeader,{ "Qte Litros" , "nLitros"       , "@E 99,999.999" ,08,3,,"û","C",})
	Private nPosCm1		:= nSeq++
	/* 31 */AADD(aHeader,{ "Custo médio", "nPrccm1"     , "@E 9,999.99" ,06,2,,"û","C",})
	Private nPosConv	:= nSeq++
	/* 32 */AADD(aHeader,{ "Conv"       , "nConv"   , "@E 999"     , 03, 0,, "û","C",})
	Private nPosEstDias	:= nSeq++
	// DbSelectArea("SX3")
	// DbSetOrder(2)
	// DbSeek("B1_DIASEST")
	// /* 33 */ AADD(aHeader,{ TRIM(x3titulo()),SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,".T.",SX3->X3_USADO,SX3->X3_TIPO,SX3->X3_F3,SX3->X3_CONTEXT,SX3->X3_CBOX,SX3->X3_RELACAO,".T."})
	
	cCampo := "B1_DIASEST"
	Aadd(aHeader,{AllTrim(GetSx3Cache(cCampo,"X3_TITULO")),;
		GetSx3Cache(cCampo,"X3_CAMPO")		,;
		GetSx3Cache(cCampo,"X3_PICTURE")	,;
		GetSx3Cache(cCampo,"X3_TAMANHO")	,;
		GetSx3Cache(cCampo,"X3_DECIMAL")	,;
		".T."								,;
		GetSx3Cache(cCampo,"X3_USADO")		,;
		GetSx3Cache(cCampo,"X3_TIPO")		,;
		GetSx3Cache(cCampo,"X3_F3") 		,;
		GetSx3Cache(cCampo,"X3_CONTEXT")	,;
		GetSx3Cache(cCampo,"X3_CBOX")		,;
		GetSx3Cache(cCampo,"X3_RELACAO") 	,;
		".T."								})

	///* 33 */AADD(aHeader,{ "Dias p/Est" , "B1_DIASEST"       , "@!" , 02, 0,, "û", "C",})
	Private nPosEstoq	:= nSeq++
	/* 34 */AADD(aHeader,{ "Est.Fisico" , "nEst"    , "@E 999,999"    , 06, 0,, "û", "C",})
	Private nPosUM		:= nSeq++
	/* 35 */AADD(aHeader,{ "UM"         , "nUm"      , "@!"           , 03, 0,"", "û", "C","" })
	Private nPosSubComp	:= nSeq++
	/* 36 */AADD(aHeader,{ "SubR$"      , "nSubcomp" , "@E 99,999.99" , 08, 2,,"û","C",})
	Private nPosObserv	:= nSeq++
	/* 37 */AADD(aHeader,{ "Observação " ,"cObs "    , "@! "        ,  100, 0,"", "û", "C",""})
	Private nPosCondPag	:= nSeq++
	/* 38 */AADD(aHeader,{ "Cond.Pag"    , "Z7_PRAZO" , ""             , 03, 0,'Execblock("BIG018E",.F.,.F.)', "û", "C","SF4"})
	Private nPosSeq		:= nSeq++
	/* 39 */AADD(aHeader,{ "Sequencia"             , "nSq "      , ""             , 01, 0,, "û", "N",})
	Private nPosSequ	:= nSeq++
	/* 40 */AADD(aHeader,{ "Curva ABC"    , "cCurva"        , "@!" ,01,0,,"û","C",})
	Private nPosABC		:= nSeq++
	/* 41 */AADD(aHeader,{ "Consumo Médio", "nConsMedio"     , "@E 999,999.99" ,10,2,,"û","N",})
	Private nPosLocal	:= nSeq++
	

	Private cPrintCdFab	:= "N"
	
	// Será utilizado três áreas na janela // 1ª - Enchoice, sendo 80 pontos pixel // 2ª - MsGetDados, o que sobrar em pontos pixel é para este objeto // 3ª - Rodapé que é a própria janela, sendo 15 pontos pixel AADD( aObj, { 100, 080, .T., .F. }) AADD( aObj, { 100, 100, .T., .T. }) AADD( aObj, { 100, 015, .T., .F. })   // Cálculo automático da dimensões dos objetos (altura/largura) em pixel aInfo := { aSize[1], aSize[2], aSize[3], aSize[4], 3, 3 } aPObj := MsObjSize( aInfo, aObj )   // Cálculo automático de dimensões dos objetos MSGET aPGet := MsObjGetPos( (aSize[3] - aSize[1]), 315, { {004, 024, 240, 270} } )
	//³          ³    1 - Tamanho X    / 2 - Tamanho Y  / 3 - Dimensiona X    ³
	//³          ³    4 - Dimensiona Y / 5 - Retorna dimensoes X e Y ao inves ³
	
	AAdd( aObjects, { 100,030, .T., .F. } )
	AAdd( aObjects, { 100,700, .T., .T. } )
	AAdd( aObjects, { 100,030, .T., .F. } )
	//AAdd( aObjects, { 300,100, .T., .F. } )
	aPosObj := MsObjSize( aInfo, aObjects )
	// 1 - Limite superior
	// 2 - Limite esquerdo
	// 3 - Limite inferior
	// 4 - Limite direito
	aPosGet := MsObjGetPos(aSize[3]-aSize[1]   ,315  ,{{003,033,160,200}} )
	
	nGetLin := aPosObj[3,1]
	
	
	
	
	AADD(aCols,Array(Len(aHeader)+1))
	For iZ := 1 To Len(aHeader)
		aCols[Len(aCols),iZ]	:= IIf(aHeader[iZ,8] == "N",0,IIf(aHeader[iZ,8] == "D",CTOD(""),""))
	Next
	
	aCols[Len(aCols),Len(aHeader)+1] := .F.

	DEFINE MSDIALOG oDlg FROM 001,001 TO aSize[6] , aSize[5] OF oMainWnd PIXEL TITLE OemToAnsi("Simula compras "+ IIf(!Empty(cLocPad)," Filial "+cFilAnt+" somente armazém '"+cLocPad+"' ",""))
	oDlg:lMaximized := .T. 
	
	/*oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP
	
	oPanel2 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT
	
	oPanel3 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM*/
	
	
	//Private oCabec	:= TScrollBox():New(oPanel1,aPosObj[1,1],aPosObj[1,2],aPosObj[1,3]-15,aPosObj[1,4]-3,.F., .T.,.T.)
	Private oCabec  := oPanel1 := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,35,.T.,.T. )  
	oCabec:Align := CONTROL_ALIGN_TOP
	
	@ 005,005 COMBOBOX cFornece ITEMS aFornece SIZE 90,10 of oCabec Pixel
	@ 005,100 Say "Dias de estoque" of oCabec Pixel
	@ 005,150 Get nDias picture "@E 999" size 30,10 of oCabec Pixel
	@ 005,196 Say "Ordem desejada" of oCabec Pixel
	@ 005,260 Combobox cOrd Items aOrd size 50,10 of oCabec Pixel
	@ 005,313 Say "Data Programada Ped." color 255 of oCabec Pixel
	@ 005,370 Get dNCPC size 40,10 of oCabec Pixel
	@ 005,430 Say "Acréscimo" of oCabec Pixel
	@ 005,499 Say "%" of oCabec Pixel
	@ 005,460 Msget nPerc picture "@E 99.99" size 35,10 of oCabec Pixel Valid Processa({|| Item()},"Processando Itens...")
	
	aCapAlt :={"B1_STS","nAcomp","nNewPre","nPrcConf","nMin","B1_EMAX","B1_DIASEST","cObs","Z7_PRAZO"}
	
	oPItens := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPItens:Align := CONTROL_ALIGN_ALLCLIENT
	
	oItems := MsNewGetDados():New(034, 005, 226, 415, 4,;
							/* cLinOk */,/* cTudoOk */,/* cIniCpos */,aCapAlt,/* nFreeze */,len( aCols ),/* cFieldOk */, /* cSuperDel */,;
							/* cDelOk */, oPItens, aHeader, aCols)
	//oItems := MsGetDados():New(034, 005, 226, 415,4,,,"+cCod",.T.,aCapAlt,,.F.,Len(aCols),,,,,oPItens)
	oItems:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	@ 005,520 Say "Exibe Cód.Fabricante?" of oCabec Pixel
	@ 005,580 Combobox cPrintCdFab Items {"N=Não","S=Sim"} size 50,10 of oCabec Pixel
	
	//Private oPTotais	:= TScrollBox():New(oPanel1,aPosObj[3,1],aPosObj[3,2],aPosObj[3,3]-15,aPosObj[3,4]-3,.T., .T.,.T. )
	Private oPTotais := TPanel():New(0,0,'',oDlg, oDlg:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPTotais:Align := CONTROL_ALIGN_BOTTOM
	
	@ 005,010 Say "Pesquisa Produto por código" color 255 of oPTotais Pixel
	@ 005,085 MsGet cPesq Size 50,10 of oPTotais Pixel Valid  Processa({|| PESQC()},"Buscando")
	@ 005,145 Say "Pesquisa Produto Descrição" color 255 of oPTotais Pixel
	@ 005,218 Get cPesqd Size 60,10 of oPTotais Pixel Valid  Processa({|| PESQD()},"Buscando")
	
	@ 018,020 Say "Valor Total do Pedido sem impostos" color 128 of oPTotais Pixel
	@ 018,110 Say "Total Peso Pedido" color 32768 of oPTotais Pixel
	@ 018,180 Say "Total Peso Bruto" color 32768 of oPTotais Pixel
	@ 018,250 Say "Total Qtes " color 16711680 of oPTotais Pixel
	@ 025,020 Get nTotcomp Picture "@E 999,999,999.99" Size 80,10 When .f.  of oPTotais Pixel
	@ 025,110 Get nTotpeso Picture "@E 999,999.999" size 60,10    When .f. of oPTotais Pixel
	@ 025,180 Get nTotBruto Picture "@E 999,999.999" size 60,10    When .f. of oPTotais Pixel
	@ 025,250 Get nQteCx Picture "@E 999,999" size 30,10          When .f. of oPTotais Pixel
	@ 005,290 BUTTON "Atualizar Valor pedido "  SIZE 70,10 action  Atualizar() of oPTotais Pixel
	@ 005,370 BUTTON "Gerar Pedido de Compra" Size 70,10 Action  Processa({|| GerarPedido()},"Gerando Pedido") of oPTotais Pixel When lGravar
	@ 005,450 BUTTON "Gravar dados produto" Size 70,10 ACTION Processa({|| Gravar()},"Gravando Informacoes") of oPTotais Pixel When lGravar
	@ 005,530 BUTTON "Sair"   Size 40,10 ACTION Close(oDlg)  of oPTotais Pixel
	@ 027,290 Say "Ordenar por:" color 255 of oPTotais Pixel
	@ 025,330 Combobox cSeq Items aSeq Size 50,10 of oPTotais Pixel Valid Processa({|| ORD()},"Buscando")
	
	@ 025,450 Button "Exporta" size 30,10 action stExporta() of oPTotais Pixel
	@ 025,400 Button "Consulta" size 30,10 action VERPRODUTO() of oPTotais Pixel
	
	Activate Dialog oDlg Centered
	
Return

/*/{Protheus.doc} Fornecedor
Processa informações do fornecedor
@type function
@version 1.0 
@author Marcelo Lauschner
@since 1/24/2005
/*/
Static Function Fornecedor()

	Local	cQry 
	
	cQry := ""
	cQry += "SELECT DISTINCT B1_PROC,B1_LOJPROC,A2_NREDUZ "
	cQry += "  FROM "  + RetSqlName("SA2") + " SA2," + RetSqlName("SB1") + " SB1 "
	cQry += " WHERE SA2.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SA2.A2_FILIAL = '" + xFilial("SA2") + "' "
	cQry += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry += "   AND SB1.B1_BLOQFAT = 'N' "//B1_TIPO = 'PA'
	If !Empty(cLocPad)
		cQry += "   AND B1_LOCPAD = '"+cLocPad+"' "
	Endif 
	cQry += "   AND SB1.B1_STS NOT IN ('F','Z') "
	cQry += "   AND SB1.B1_PROC = SA2.A2_COD "
	cQry += "   AND SB1.B1_LOJPROC = SA2.A2_LOJA "
	cQry += " ORDER BY SB1.B1_PROC,SB1.B1_LOJPROC "
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	While !Eof()
		
		aadd(aFornece,QRY->B1_PROC + QRY->B1_LOJPROC + " " + QRY->A2_NREDUZ)
		dbSelectArea("QRY")
		dbSkip()
	Enddo
	QRY->(DbCloseArea())
	
	aadd(aFornece,"Chevron")
	aadd(aFornece,"Michelin")
	aadd(aFornece,"2R-Michelin")
	Aadd(aFornece,"Levorin")
	aadd(aFornece,"Houhgton")
	aadd(aFornece,"Rocol")
	aadd(aFornece,"Mann")
	aadd(aFornece,"* Todos")
	
Return

/*/{Protheus.doc} Item
Processa produtos do fornecedor e calcula previsão baseada nos parâmetros
@type function
@version 1.0 
@author Marcelo Lauschner
@since 1/24/2005
/*/
Static Function Item()
	
	Local 	nqt 		:= 0
	Local	nB2Reserva	:= 0
	Local	cQry 		:= ""
	Local	cQri 		:= ""
	Local	cQrb		:= ""
	Local	cQrc		:= ""
	Local	cQrs		:= ""
	
	aCols := {}
	nTotcomp := 0.00
	nTotpeso := 0.000
	nTotBruto := 0
	nQteCx   := 0
	
	cQry := ""
	cQry += "SELECT DISTINCT B1_COD,B1_QE,B1_CUSTD,B1_DESC,B1_FABRIC,B1_PESO,B1_PESBRU,B1_LM,B1_STS,B1_EMAX,B1_ESTSEG,B1_QTELITS,B1_CONV,B1_DIASEST,B1_CABO,"
	cQry += "       B1_PROC,B1_LOJPROC,B1_UM,B1_OBSERV,B1_SEGUM,B1_TIPCONV,COALESCE(B3_MEDIA,0) B3_MEDIA "
	cQry += "  FROM "+RetSqlName("SB1") + " SB1 "

	cQry += "LEFT JOIN "+ RetSqlName( "SB3" ) +" SB3 "
	cQry += " ON SB3.B3_FILIAL  = '"+ FWxFilial( "SB3" ) +"' "
	cQry += "AND SB3.B3_COD     = SB1.B1_COD "
	cQry += "AND SB3.D_E_L_E_T_ = ' ' "

	cQry += " WHERE SB1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SB1.B1_FILIAL  = '" + xFilial("SB1") + "' "
	cQry += "   AND SB1.B1_BLOQFAT = 'N' " // B1_TIPO = 'PA' "
	cQry += "   AND SB1.B1_STS NOT IN ('F','Z') "
	If !(cFornece $ "* Todos#Chevron#Michelin#Mann#Houhgton#Rocol#2R-Michelin#Levorin" )
		cQry += "AND SB1.B1_PROC = '" + SubStr(cFornece,1,6) + "' "
		cQry += "AND SB1.B1_LOJPROC = '" + SubStr(cFornece,7,2) + "' "
		aFornOpc	:= {SubStr(cFornece,1,6),SubStr(cFornece,7,2)}
	ElseIf cFornece $ "Chevron"
		cQry += " AND B1_PROC = '000468' "
		aFornOpc	:= {"000468","10"}
	ElseIf cFornece == "Levorin"
		cQry += " AND B1_PROC = '004502' AND B1_CABO = 'MOT' "
		aFornOpc	:= {"004502","01"}
	ElseIf cFornece == "2R-Michelin"
		cQry += " AND B1_PROC = '000473' AND B1_CABO = 'MOT' "
		aFornOpc	:= {"000473","01"}
	ElseIf cFornece == "Michelin"
		cQry += " AND B1_PROC = '000473' AND B1_CABO NOT IN('MOT') "
		aFornOpc	:= {"000473","01"}
	ElseIf cFornece $ "Pirelli"
		cQry += " AND B1_PROC = '001155' "
		aFornOpc	:= {"001155","68"}
	ElseIf cFornece $ "Mann"
		cQry += " AND B1_PROC = '000005' "
		aFornOpc	:= {"000005","01"}
	ElseIf cFornece $ "Houhgton"
		cQry += " AND B1_CABO = 'HOU' "
		aFornOpc	:= {"004748","01"}
	ElseIf cFornece $ "Rocol"
		cQry += " AND B1_CABO = 'ROC' "
		aFornOpc	:= {"000449","01"}
	Endif
	
	cQry += "   AND B1_MSBLQL != '1' "
	
	If cOrd == "Código"
		cQry += "ORDER BY SB1.B1_COD ASC "
	Elseif cOrd == "Descrição"
		cQry += "ORDER BY SB1.B1_DESC ASC "
	Else
		cQry += "ORDER BY SB1.B1_STS DESC,B1_OBSERV DESC "
	Endif
	
	TCQUERY cQry NEW ALIAS "QRY"
	
	While !Eof()
		nqt += 1
		dbSelectArea("QRY")
		dbSkip()
	End
	
	dbSelectArea("QRY")
	dbGoTop()
	ProcRegua(nqt)
	While !Eof()
		
		nB2Reserva	:= 0
		
		dbselectarea("SB2")
		dbsetorder(1)
		If Empty(cLocPad)
			
			If dbseek(xFilial("SB2")+QRY->B1_COD+"01")
				nEst 	:= SB2->B2_QATU
				nPrccm1 := Round(SB2->B2_CM1,2)
				nB2Reserva	+= SB2->B2_RESERVA
			Else
				nEst 	:= 0.00
				nPrccm1 := 0.00
			Endif
			If dbseek(xFilial("SB2")+QRY->B1_COD+"02")
				nEst 	+= SB2->B2_QATU
				nPrccm1 += Round(SB2->B2_CM1,2)
				nPrcCm1 := Round(nPrcCm1/2,2)
			Endif
			
		Else
			If dbseek(xFilial("SB2")+QRY->B1_COD+IIf(Empty(cLocPad),"01",cLocPad))
				nEst := SB2->B2_QATU
				nPrccm1 := Round(SB2->B2_CM1,2)
			Else
				nEst := 0.00
				nPrccm1 := 0.00
			Endif
		Endif
		nMin := QRY->B1_QE
		
		cQri := ""
		// Ajuste feito para que produtos Rocol e Houghton somente gerem demanda se liberado no crédito o pedido. 
		If QRY->B1_CABO $"HOU#ROC"
			cQri += "SELECT SUM(C9_QTDLIB) AS DIGITADO "
			cQri += "  FROM "+ RetSqlName("SC6") + " SC6, " + RetSqlName("SF4") + " SF4, "+ RetSqlName("SC9") + " SC9 "
			cQri += " WHERE	SC6.D_E_L_E_T_ = ' '"
			cQri += "   AND SC9.D_E_L_E_T_ =' ' "
			cQri += "   AND C9_PEDIDO = C6_NUM "
			cQri += "   AND C9_ITEM = C6_ITEM "
			cQri += "   AND C9_PRODUTO = C6_PRODUTO "
			cQri += "   AND C9_NFISCAL = '  ' "
			cQri += "   AND C9_FLGENVI != 'F' "
			cQri += "   AND C9_BLCRED = ' ' "
			cQri += "   AND C9_FILIAL = '"  + xFilial("SC9")+ "'"
		Else
			cQri += "SELECT SUM(C6_QTDVEN - C6_QTDENT) AS DIGITADO "
		
			cQri += "  FROM "+ RetSqlName("SC6") + " SC6, " + RetSqlName("SF4") + " SF4 "
			cQri += " WHERE SC6.D_E_L_E_T_ = ' ' "
		Endif
		cQri += "   AND SF4.F4_ESTOQUE = 'S' "
		cQri += "   AND SF4.D_E_L_E_T_ = ' ' "
		cQri += "   AND SF4.F4_CODIGO = SC6.C6_TES "
		cQri += "   AND SF4.F4_FILIAL = '" + xFilial("SF4") + "' "
		
		If nOpcLoc == 3
			cQri += " AND EXISTS (SELECT A1_COD,A1_LOJA "
			cQri += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
			cQri += "              WHERE CC2.D_E_L_E_T_ = ' ' "
			cQri += "                AND CC2_ARMPAD = '  ' "
			cQri += "                AND CC2_CODMUN = A1_COD_MUN  "
			cQri += "                AND CC2_EST = A1_EST  "
			cQri += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
			cQri += "                AND A1.D_E_L_E_T_ = ' ' "
			cQri += "                AND A1_LOJA = C6_LOJA "
			cQri += "                AND A1_COD = C6_CLI "
			cQri += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
		ElseIf nOpcLoc == 4
			cQri += " AND EXISTS (SELECT A1_COD,A1_LOJA "
			cQri += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
			cQri += "              WHERE CC2.D_E_L_E_T_ = ' ' "
			cQri += "                AND CC2_ARMPAD = '"+cLocPad+"' "
			cQri += "                AND CC2_CODMUN = A1_COD_MUN  "
			cQri += "                AND CC2_EST = A1_EST  "
			cQri += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
			cQri += "                AND A1.D_E_L_E_T_ = ' ' "
			cQri += "                AND A1_LOJA = C6_LOJA "
			cQri += "                AND A1_COD = C6_CLI "
			cQri += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
		ElseIf !Empty(cLocPad)
			cQri += " AND C6_LOCAL = '"+cLocPad+"' "
		Endif
		
		cQri += "   AND SC6.C6_BLQ <> 'R' "
		cQri += "   AND EXISTS (SELECT C5_NUM "
		cQri += "                 FROM "+RetSqlName("SC5") + " SC5 "
		cQri += "                WHERE D_E_L_E_T_ = ' ' "
		cQri += "                 AND C5_NUM = C6_NUM "
		cQri += "                 AND C5_DTPROGM <= '" + DTOS(dNCPC) + "' "
		cQri += "                 AND C5_FILIAL = '"+xFilial("SC5")+"' )"
		cQri += "   AND SC6.C6_PRODUTO = '" + QRY->B1_COD + "' "
		cQri += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' "
		
		TCQUERY cQri NEW ALIAS "QRI"

		nEstl := nEst - QRI->DIGITADO
		
		QRI->(DbCloseArea())
		
		cQrb := ""
		cQrb += "SELECT SUM(D2_QUANT) AS CONSUMO "
		cQrb += "  FROM " + RetSqlName("SD2") + " SD2, " + RetSqlName("SF4") + " SF4 "
		cQrb += " WHERE SF4.F4_ESTOQUE = 'S' "
		cQrb += "   AND F4_PODER3 != 'S' "
		cQrb += "   AND SF4.D_E_L_E_T_ = ' ' "
		cQrb += "   AND SF4.F4_CODIGO = SD2.D2_TES "
		cQrb += "   AND SF4.F4_FILIAL = '" + xFilial("SF4") + "' "
		cQrb += "   AND SD2.D_E_L_E_T_ = ' ' "
		cQrb += "   AND SD2.D2_NUMSEQ BETWEEN ' ' AND 'ZZZZZZ' "
		cQrb += "   AND SD2.D2_EMISSAO >= '"+ DTOS(FirstDay(dDataBase)) + "' "
		If nOpcLoc == 3
			cQrb += " AND EXISTS (SELECT A1_COD,A1_LOJA "
			cQrb += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
			cQrb += "              WHERE CC2.D_E_L_E_T_ = ' ' "
			cQrb += "                AND CC2_ARMPAD = '  ' "
			cQrb += "                AND CC2_CODMUN = A1_COD_MUN  "
			cQrb += "                AND CC2_EST = A1_EST  "
			cQrb += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
			cQrb += "                AND A1.D_E_L_E_T_ = ' ' "
			cQrb += "                AND A1_LOJA = D2_LOJA "
			cQrb += "                AND A1_COD = D2_CLIENTE "
			cQrb += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
		ElseIf nOpcLoc == 4
			cQrb += " AND EXISTS (SELECT A1_COD,A1_LOJA "
			cQrb += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
			cQrb += "              WHERE CC2.D_E_L_E_T_ = ' ' "
			cQrb += "                AND CC2_ARMPAD = '"+cLocPad+"' "
			cQrb += "                AND CC2_CODMUN = A1_COD_MUN  "
			cQrb += "                AND CC2_EST = A1_EST  "
			cQrb += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
			cQrb += "                AND A1.D_E_L_E_T_ = ' ' "
			cQrb += "                AND A1_LOJA = D2_LOJA "
			cQrb += "                AND A1_COD = D2_CLIENTE "
			cQrb += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
		ElseIf !Empty(cLocPad)
			cQrb += " AND D2_LOCAL ='"+cLocPad+"' "
		Endif
		cQrb += "   AND D2_TIPO = 'N' "
		cQrb += "   AND SD2.D2_COD = '"+ QRY->B1_COD +"' "
		cQrb += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "' "
		
		TCQUERY cQrb NEW ALIAS "QRB"
		
		nConsAtu := QRB->CONSUMO
		
		QRB->(DbCloseArea())
		
		cQrc := "" 
		cQrc += "SELECT SUBSTRING(SD2.D2_EMISSAO,1,6) AS MES, SUM(D2_QUANT) AS CONS FROM "
		cQrc += RetSqlName("SD2") + " SD2, "
		cQrc += RetSqlName("SF4") + " SF4 "
		cQrc += "WHERE SF4.F4_ESTOQUE = 'S' "
		cQrc += "  AND F4_PODER3 !='S' "
		cQrc += "  AND SF4.D_E_L_E_T_ = ' ' "
		cQrc += "  AND SF4.F4_CODIGO = SD2.D2_TES "
		cQrc += "  AND SF4.F4_FILIAL = '" + xFilial("SF4") + "' "
		cQrc += "  AND SD2.D_E_L_E_T_ = ' ' "
		cQrc += "  AND SD2.D2_NUMSEQ BETWEEN ' ' AND 'ZZZZZZ' "
		cQrc += "  AND (SD2.D2_EMISSAO BETWEEN '" +Alltrim(cMes6+"01")+ "' AND '" + Alltrim(cMes1+"31")+ "'  OR SD2.D2_EMISSAO BETWEEN '" +Alltrim(cMes12+"01")+ "' AND '" + Alltrim(cMes12+"31")+ "')"
		If nOpcLoc == 3
			cQrc += " AND EXISTS (SELECT A1_COD,A1_LOJA "
			cQrc += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
			cQrc += "              WHERE CC2.D_E_L_E_T_ = ' ' "
			cQrc += "                AND CC2_ARMPAD = '  ' "
			cQrc += "                AND CC2_CODMUN = A1_COD_MUN  "
			cQrc += "                AND CC2_EST = A1_EST  "
			cQrc += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
			cQrc += "                AND A1.D_E_L_E_T_ = ' ' "
			cQrc += "                AND A1_LOJA = D2_LOJA "
			cQrc += "                AND A1_COD = D2_CLIENTE "
			cQrc += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
		ElseIf nOpcLoc == 4
			cQrc += " AND EXISTS (SELECT A1_COD,A1_LOJA "
			cQrc += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
			cQrc += "              WHERE CC2.D_E_L_E_T_ = ' ' "
			cQrc += "                AND CC2_ARMPAD = '"+cLocPad+"' "
			cQrc += "                AND CC2_CODMUN = A1_COD_MUN  "
			cQrc += "                AND CC2_EST = A1_EST  "
			cQrc += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
			cQrc += "                AND A1.D_E_L_E_T_ = ' ' "
			cQrc += "                AND A1_LOJA = D2_LOJA "
			cQrc += "                AND A1_COD = D2_CLIENTE "
			cQrc += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
		ElseIf !Empty(cLocPad)
			cQrc += " AND D2_LOCAL = '"+cLocPad+"' "
		Endif
		cQrc += "   AND D2_TIPO = 'N' "
		cQrc += "   AND SD2.D2_COD = '"+ QRY->B1_COD +"' " 
		cQrc += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "' "
		cQrc += " GROUP BY SUBSTRING(SD2.D2_EMISSAO,1,6) "
		
		
		TCQUERY cQrc NEW ALIAS "QRC"
		
		While !Eof()
			If Alltrim(QRC->MES) == cMes1
				nMes1 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes2
				nMes2 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes3
				nMes3 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes4
				nMes4 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes5
				nMes5 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes6
				nMes6 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes7
				nMes7 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes8
				nMes8 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes9
				nMes9 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes10
				nMes10 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes11
				nMes11 := QRC->CONS
			elseif  Alltrim(QRC->MES) == cMes12
				nMes12 := QRC->CONS
			Endif
			Dbselectarea("QRC")
			Dbskip()
		Enddo
		QRC->(dbClosearea())
		
		cQrs := ""
		cQrs += "SELECT SUM(C7_QUANT - C7_QUJE) AS COMPRAS "
		cQrs += "  FROM " + RetSqlName("SC7") + " "
		cQrs += " WHERE D_E_L_E_T_ = ' ' "
		cQrs += "   AND C7_FILIAL = '" + xFilial("SC7") + "' "
		cQrs += "   AND C7_PRODUTO = '" + QRY->B1_COD + "'"
		If !Empty(cLocPad)
			cQrs += " AND C7_LOCAL = '"+cLocPad+"' "
		Endif
		cQrs += "   AND C7_ENCER = ' ' "
		cQrs += "   AND C7_RESIDUO = ' ' "
		cQrs += "   AND C7_QUJE < C7_QUANT "
		
		TCQUERY cQrs NEW ALIAS "QRS"
		
		nComp := QRS->COMPRAS
		QRS->(DbCloseArea())
		
		
		cQrs := ""
		cQrs += "SELECT COALESCE(SUM(C0_QUANT),0) RESERVAS "
		cQrs += "  FROM " + RetSqlName("SC0") + " "
		cQrs += " WHERE D_E_L_E_T_ = ' '  "
		If !Empty(cLocPad)
			cQrs += " AND C0_LOCAL = '"+cLocPad+"' "
		Endif
		cQrs += "   AND C0_FILIAL = '" + xFilial("SC0") + "' "
		cQrs += "   AND C0_QUANT > 0 "
		cQrs += "   AND C0_PRODUTO = '" + QRY->B1_COD + "' "
		
		TCQUERY cQrs NEW ALIAS "QRR"
		
		nEstl -=	QRR->RESERVAS
		
		QRR->(DbCloseArea())
		
		dbSelectArea("SZ7")
		dbSetOrder(2)
		If dbSeek(xFilial("SZ7")+QRY->B1_PROC+QRY->B1_LOJPROC+QRY->B1_COD+cTabela)
			nPrcConf := Round(QRY->B1_CUSTD,2)
			cCondpag := Alltrim(Str(SZ7->Z7_PRAZO))
		Else
			nPrcConf := QRY->B1_CUSTD
		Endif
		
		//nPreviem := round(((nMes1+nMes2+nMes3+nMes4+(nConsAtu/nCons*30))/5),2)Alterado para a linha abaixo em 01/08/05 a pedido do Fábio.
		nPreviem 	:= round(((nMes1+nMes2+nMes3+nMes4)/4),2)
		nPeso    	:= QRY->B1_PESO
		nLtMin   	:= QRY->B1_LM
		nNewPre 	:= Round((nPreviem /30 * nDias) * (1+(nPerc/100)),0)
		
		If QRY->B1_STS <> 'D'
			nAcomp   := Round((nNewPre - nEstl - nComp),2)
		Else
			If nEstl < 0
				nAcomp:= Round((-nEstl - nComp),2)
			Else
				nAcomp := 0
			Endif
		Endif
		nDiasEst := round(nEstl/(nPreviem/30),0)
		If nAcomp <= 0
			nAcomp1 := 0
		Else
			nAcomp1 := (nAcomp/nMin) - Round(nAcomp/nMin,0)
			If (nAcomp1 > 0 ) .And. (nAcomp1 < 0.1)
				nAcomp1 := Round(nAcomp/nMin,0)
				nAcomp1 := nAcomp1 * nMin
			Else
				nAcomp1 := Round(nAcomp/nMin,0) +1
				nAcomp1 := nAcomp1 * nMin
			Endif
		Endif
		nAcomp := Round(nAcomp1,0)
		nSubPeso := Round(nAcomp * nPeso,2)
		nSubPBruto	:= Round(nAComp * QRY->B1_PESBRU,2)
		nSubComp := Round(nAcomp * nPrcConf,2)
		
		
		If  nAcomp > 0
			cGera := "X"
		Else
			cGera := " "
		Endif
		IncProc("Incluindo produto ----->>" + QRY->B1_COD)
		nSq += 1
		
		AADD(aCols,{QRY->B1_COD,;		// 1
		IIf(cPrintCdFab == "S",QRY->B1_FABRIC+" | ","") + QRY->B1_DESC,;		// 2
		QRY->B1_STS,;      	// 3
		nMes12,;			// 4
		nMes6,;             // 5
		nMes5,;             // 6
		nMes4,;             // 7
		nMes3,;             // 8
		nMes2,;             // 9
		nMes1,;             // 10
		nConsAtu,;          // 11
		nComp,;             // 12
		nAcomp,;            // 13
		cGera,;             // 14
		nNewPre,;           // 15
		nEstl,;             // 16
		QRY->B1_EMAX,;		// 17
		nLtMin,;            // 18
		QRY->B1_ESTSEG,;    // 19
		Round(nDiasEst,0),; // 20
		nPrcConf,;          // 21
		nMin,;              // 22
		nPeso,;             // 23
		nSubPeso,;          // 24
		QRY->B1_QTELITS,;   // 25
		nPrccm1,;           // 26
		QRY->B1_CONV,;      // 27
		QRY->B1_DIASEST,;   // 28
		nEst,;              // 29
		QRY->B1_UM,;        // 30
		nSubComp,;          // 31
		QRY->B1_OBSERV,;    // 32
		cCondpag,;          // 33
		nSq,;               // 34
		Posicione("SB3",1,xFilial("SB3")+QRY->B1_COD,"B3_CLASSE"),;	 		// 40
		SB3->B3_MEDIA,;				// 41
		.F.})
		
		If nAcomp > 0
			nTotpeso += nSubpeso
			nTotBruto += nSubPBruto
			nTotcomp += nSubcomp
			If QRY->B1_SEGUM == ' '
				nQteCx += nAcomp
			else
				If QRY->B1_TIPCONV == 'D'
					nQteCx += (nAcomp/QRY->B1_CONV)
				Else
					nQteCx += (nAcomp*QRY->B1_CONV)
				Endif
			Endif
		Else
			nQteCx += 0
			nTotpeso += 0
			nTotcomp += 0
		Endif
		
		
		
		dbSelectArea("QRY")
		dbSkip()
		
		nSubComp := 0
		nEst := 0
		nPrcConf := 0
		nMin := 0
		nPeso := 0
		nLtMin := 0
		nSubPeso := 0
		nPrccm1 := 0
		nDiasEst := 0
		cStatus :=" "
		nMes12 := 0
		nMes11 := 0
		nMes10 := 0
		nMes9 := 0
		nMes8 := 0
		nMes7 := 0
		nMes6 := 0
		nMes5 := 0
		nMes4 := 0
		nMes3 := 0
		nMes2 := 0
		nMes1 := 0
		nConsAtu := 0
		nComp := 0
		nAcomp := 0
		cGera :=" "
		nNewPre := 0
		nEstl := 0
		
	Enddo
	QRY->(DbCloseArea())
	
	if valType( oItems ) == "O"
		oItems:ACOLS := aClone( aCols )
		oItems:ForceRefresh()
	endif
Return



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Executa consulta do produto selecionado na linha Get Dados³	`			Static function VERPRODUTO
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


Static function VERPRODUTO
	
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+oItems:aCols[oItems:nAt][nPosCod])
	
	U_BIG037B()
	
Return

Static Function sfOld

	Local aCampos 		:= {}
	Local aStru   		:= {}
	Local cAlias		:= ""
	Local oTmpTable
	Private nCompras	:= 0
	Private cprod   	:= Space(15)
	cProd := aCols[n][nPosCod]
	
	aStru:={}
	
	Aadd(aStru,{ "ENTREGA" , "D", 08, 0 } )
	Aadd(aStru,{ "NUM",  "C", 06, 0 } )
	Aadd(aStru,{ "SALDO",  "N", 08, 0 } )
	Aadd(aStru,{ "PRCCONF","N", 10, 2 } )
	Aadd(aStru,{ "EMISSAO","D", 08, 0 } )
	
	If (Select("COMP") <> 0)
		dbSelectArea("COMP")
		COMP->(dbCloseArea())
	Endif
	
	// cArq := CriaTrab(aStru,.t.)
	// dbUseArea ( .T.,"TOPCONN", cArq, "COMP", NIL, .F. )

	cAlias := "COMP"
	oTmpTable := FWTemporaryTable():New(cAlias,aStru)
	oTmpTable:Create()

	dbSelectArea(cAlias)
	
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica todos os saldos de pedidos de compra para a consulta por produto³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	
	cQrs := ""
	cQrs += "SELECT (C7_QUANT - C7_QUJE) AS QTE,C7_NUM,C7_DATPRF,C7_EMISSAO,C7_PRECO "
	cQrs += "  FROM " + RetSqlName("SC7") + " "
	cQrs += " WHERE D_E_L_E_T_ = ' ' "
	cQrs += "   AND C7_FILIAL = '" + xFilial("SC7") + "' "
	cQrs += "   AND C7_PRODUTO = '" + aCols[n][nPosCod] + "' "
	cQrs += "   AND C7_ENCER = ' ' "
	If !Empty(cLocPad)
		cQrs += " AND C7_LOCAL = '"+cLocPad+"' "
	Endif
	cQrs += "   AND C7_RESIDUO = ' ' "
	cQrs += "   AND C7_QUJE < C7_QUANT "
	cQrs += "ORDER BY C7_DATPRF "
	
	
	If (Select("QC7") <> 0 )
		dbSelectArea("QC7")
		QC7->(dbCloseArea())
	Endif
	
	TCQUERY cQrs NEW ALIAS "QC7"
	
	dbSelectArea("QC7")
	dbGoTop()
	While !Eof()
		If !Empty(QC7->C7_NUM)
			dbSelectArea("COMP")
			RecLock("COMP",.T.)
			COMP->ENTREGA := STOD(QC7->C7_DATPRF)
			COMP->NUM     := QC7->C7_NUM
			COMP->SALDO   := QC7->QTE
			COMP->PRCCONF := QC7->C7_PRECO
			COMP->EMISSAO := STOD(QC7->C7_EMISSAO)
			MsUnLock("COMP")
			nCompras += QC7->QTE
		Endif
		dbSelectArea("QC7")
		dbSkip()
	End
	QC7->(DbCloseArea())
	
	dbSelectArea("COMP")
	dbGotop()
	
	aCampos := {}
	Aadd(aCampos,{ "ENTREGA" ,"Dt Entrega" } )
	Aadd(aCampos,{ "NUM"     ,"Nº Pedido " } )
	Aadd(aCampos,{ "SALDO"   ,"Saldo","@E 999,999" } )
	Aadd(aCampos,{ "PRCCONF" ,"Prc.Conf","@E 999,999.99" } )
	Aadd(aCampos,{ "EMISSAO" ,"Emissão"})
	
	@ 200,1 TO 600,700 DIALOG oConsulta TITLE OemToAnsi("Dados de giro do produto -> "+aCols[n][nPosCod]+"-> "+aCols[n][nPosDesc])
	@ 005,005 TO 170,340 BROWSE "COMP" OBJECT oBrw FIELDS aCampos
	@ 175,015 Say "Saldo compras"
	@ 175,060 Get nCompras size 30,13 picture "@E 999,999.99" when .f.
	@ 185,015  Button "Faturamento" size 37,13 action Fatur()
	@ 185,060  Button "Preços Tab." size 37,13 action Precos()
	@ 185,105  Button "N.F. Entrada" size 37,13 action Compras()
	@ 185,150  Button "Ped. Vendas" size 37,13 action Vendas()
	@ 185,195  Button "Estoques   " size 37,13 action Estoques()
	@ 185,240  button "Fechar "     size 37,13 Action Close(oConsulta)
	
	ACTIVATE DIALOG oConsulta CENTERED
	COMP->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index
	
Return

// Executa consulta que verifica pedidos de vendas alocados com o produto selecionado
Static function Vendas
	
	Local nVendas 	:= 0
	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local cAlias	:= ""
	
	aStru:={}
	
	Aadd(aStru,{ "NUM",  "C", 06, 0 } )
	Aadd(aStru,{ "SALDO",  "N", 08, 0 } )
	Aadd(aStru,{ "PRCVEN","N", 10, 2 } )
	Aadd(aStru,{ "EMISSAO","D", 08, 0 } )
	Aadd(aStru,{ "ENTREGA" , "D", 08, 0 } )
	Aadd(aStru,{ "VENDEDOR", "C", 15, 0 } )
	Aadd(aStru,{ "TMK"     , "C", 15, 0 } )
	Aadd(aStru,{ "CODLJ"  , "C", 11, 0 })
	Aadd(aStru,{ "NOME"   , "C", 40, 0 })
	
	// cArq := CriaTrab(aStru,.t.)
	// dbUseArea ( .T.,"TOPCONN", cArq, "VEND", NIL, .F. )

	cAlias := "VEND"
	oTmpTable := FWTemporaryTable():New(cAlias,aStru)
	oTmpTable:Create()

	dbSelectArea(cAlias)
	
	cQri := ""
	cQri += "SELECT (C6_QTDVEN - C6_QTDENT) AS SALDO,C6_NUM,C6_PRCVEN "
	cQri += "  FROM "+RetSqlName("SC6") + " SC6 "
	cQri += " WHERE D_E_L_E_T_ = ' ' "
	If nOpcLoc == 3
		cQri += " AND EXISTS (SELECT A1_COD,A1_LOJA "
		cQri += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
		cQri += "              WHERE CC2.D_E_L_E_T_ = ' ' "
		cQri += "                AND CC2_ARMPAD = '  ' "
		cQri += "                AND CC2_CODMUN = A1_COD_MUN  "
		cQri += "                AND CC2_EST = A1_EST  "
		cQri += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
		cQri += "                AND A1.D_E_L_E_T_ = ' ' "
		cQri += "                AND A1_LOJA = C6_LOJA "
		cQri += "                AND A1_COD = C6_CLI "
		cQri += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
	ElseIf nOpcLoc == 4
		cQri += " AND EXISTS (SELECT A1_COD,A1_LOJA "
		cQri += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
		cQri += "              WHERE CC2.D_E_L_E_T_ = ' ' "
		cQri += "                AND CC2_ARMPAD = '"+cLocPad+"' "
		cQri += "                AND CC2_CODMUN = A1_COD_MUN  "
		cQri += "                AND CC2_EST = A1_EST  "
		cQri += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
		cQri += "                AND A1.D_E_L_E_T_ = ' ' "
		cQri += "                AND A1_LOJA = C6_LOJA "
		cQri += "                AND A1_COD = C6_CLI "
		cQri += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
	ElseIf !Empty(cLocPad)
		cQri += "  AND C6_LOCAL = '"+cLocPad+"' "
	Endif
	cQri += "   AND C6_FILIAL = '" + xFilial("SC6") + "' "
	cQri += "   AND C6_PRODUTO = '" + cProd + "' "
	cQri += "   AND C6_BLQ <> 'R' "
	cQri += "   AND C6_QTDENT < C6_QTDVEN "
	cQri += " ORDER BY C6_NUM ASC "
	
	TCQUERY cQri NEW ALIAS "QC6"
	
	While !Eof()
		Dbselectarea("SC5")
		dbsetorder(1)
		If !dbseek(xFilial("SC5")+QC6->C6_NUM)
			Alert("Pedido não encontrado -->> "+QC6->C6_NUM)
		Endif
		If !Empty(QC6->C6_NUM)
			dbSelectArea("VEND")
			RecLock("VEND",.T.)
			VEND->NUM     := QC6->C6_NUM
			VEND->SALDO   := QC6->SALDO
			VEND->PRCVEN  := QC6->C6_PRCVEN
			VEND->EMISSAO := SC5->C5_EMISSAO
			VEND->ENTREGA := SC5->C5_DTPROGM
			Dbselectarea("SA3")
			dbsetorder(1)
			dbseek(xFilial("SA3")+SC5->C5_VEND1)
			VEND->VENDEDOR := SA3->A3_NREDUZ
			Dbselectarea("SA3")
			dbsetorder(1)
			dbseek(xFilial("SA3")+SC5->C5_VEND2)
			VEND->TMK  := SA3->A3_NREDUZ
			VEND->CODLJ := SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI
			Dbselectarea("SA1")
			dbsetorder(1)
			dbseek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
			VEND->NOME := SA1->A1_NOME
			MsUnLock("VEND")
			nVendas += QC6->SALDO
		Endif
		dbSelectArea("QC6")
		dbSkip()
	Enddo
	QC6->(DbCloseArea())
	
	
	dbSelectArea("VEND")
	dbGotop()
	
	aCampos := {}
	Aadd(aCampos,{ "NUM"     ,"Nº Pedido " } )
	Aadd(aCampos,{ "SALDO"   ,"Saldo" ,"@E 999,999" } )
	Aadd(aCampos,{ "PRCVEN"  ,"Prc.Venda","@E 999,999.99" } )
	Aadd(aCampos,{ "EMISSAO" ,"Emissão"})
	Aadd(aCampos,{ "ENTREGA" ,"Dt Programada" } )
	Aadd(aCampos,{ "VENDEDOR","Vendedor" })
	Aadd(aCampos,{ "TMK"     ,"Telemarketing"})
	Aadd(aCampos,{ "CODLJ"   ,"Cód.Lj"  })
	Aadd(aCampos,{ "NOME"    ,"Nome Cliente"})
	
	@ 200,1 TO 600,700 DIALOG oVendas TITLE OemToAnsi("Consulta de pedidos não faturados")
	@ 005,005 TO 170,340 BROWSE "VEND" OBJECT oBrw1 FIELDS aCampos
	@ 175,015 Say "Saldo Vendas"
	@ 175,060 Get nVendas size 30,13 picture "@E 999,999.99" when .f.
	
	@ 185,195 button "Fechar "     size 37,13 Action Close(oVendas)
	
	ACTIVATE DIALOG oVendas CENTERED
	
	VEND->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index
	
Return


// Verifica faturamentos e vendas nos últimos 12 meses
Static function Fatur
	
	Local nMedven 	:= 0
	Local nMedfat 	:= 0
	Local nMeses  	:= 0
	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local cDataini 	:= ""
	Local aMeses  	:= {{"01"},{"02"},{"03"},{"04"},{"05"},{"06"},{"07"},{"08"},{"09"},{"10"},{"11"},{"12"}}
	Local aDatas  	:= {}
	Local cAlias	:= ""
	Local x, oTmpTable
	
	
	cDataini := Alltrim(str(Year(ddatabase)-1)+substr(dtos(ddatabase),5,2)+"01")
	
	For x:= 1 to len(aMeses)
		aadd(aDatas,{Alltrim(str(Year(ddatabase)-1))+aMeses[x][1]})
		aadd(aDatas,{Alltrim(str(Year(ddatabase)))+aMeses[x][1]})
	Next x
	
	aSort(aDatas,,,{|x,y| x[1] > y[1]})
	
	
	
	
	aStru:={}
	
	Aadd(aStru,{ "MESANO",  "C", 08, 0 } )
	Aadd(aStru,{ "VEND  ",  "N", 08, 0 } )
	Aadd(aStru,{ "FATU  ",  "N", 08, 0 } )
	Aadd(aStru,{ "CLI   ",  "N", 08, 0 } )
	
	// cArq := CriaTrab(aStru,.t.)
	// dbUseArea ( .T.,"TOPCONN", cArq, "FATU", NIL, .F. )

	cAlias := "FATU"
	oTmpTable := FWTemporaryTable():New(cAlias,aStru)
	oTmpTable:Create()

	dbSelectArea(cAlias)
	
	For x := 1 To len(aDatas)
		If Alltrim(aDatas[x,1]+"01") >= cDataini .and. Alltrim(aDatas[x,1]) <= alltrim(substr(dtos(dDatabase),1,6))
			
			cQrb := ""
			cQrb += "SELECT SUM(C6_QTDVEN) AS CONSUMO "
			cQrb += "  FROM " + RetSqlName("SC6") + " SC6," + RetSqlName("SC5") + " SC5 "
			cQrb += " WHERE SC6.D_E_L_E_T_ = ' ' AND SC5.D_E_L_E_T_ = ' ' "
			cQrb += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' "
			cQrb += "   AND SC5.C5_FILIAL = '" + xFilial("SC5") + "' "
			If nOpcLoc == 3
				cQrb += " AND EXISTS (SELECT A1_COD,A1_LOJA "
				cQrb += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
				cQrb += "              WHERE CC2.D_E_L_E_T_ = ' ' "
				cQrb += "                AND CC2_ARMPAD = '  ' "
				cQrb += "                AND CC2_CODMUN = A1_COD_MUN  "
				cQrb += "                AND CC2_EST = A1_EST  "
				cQrb += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
				cQrb += "                AND A1.D_E_L_E_T_ = ' ' "
				cQrb += "                AND A1_LOJA = C5_LOJACLI "
				cQrb += "                AND A1_COD = C5_CLIENTE "
				cQrb += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
			ElseIf nOpcLoc == 4
				cQrb += " AND EXISTS (SELECT A1_COD,A1_LOJA "
				cQrb += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
				cQrb += "              WHERE CC2.D_E_L_E_T_ = ' ' "
				cQrb += "                AND CC2_ARMPAD = '"+cLocPad+"' "
				cQrb += "                AND CC2_CODMUN = A1_COD_MUN  "
				cQrb += "                AND CC2_EST = A1_EST  "
				cQrb += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
				cQrb += "                AND A1.D_E_L_E_T_ = ' ' "
				cQrb += "                AND A1_LOJA = C5_LOJACLI "
				cQrb += "                AND A1_COD = C5_CLIENTE "
				cQrb += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
			ElseIf !Empty(cLocPad)
				cQrb +=  " AND C6_LOCAL = '"+cLocPad+"' "
			Endif
			cQrb += "   AND SC6.C6_PRODUTO = '" + cProd + "' "
			cQrb += "   AND SC6.C6_NUM = SC5.C5_NUM "
			cQrb += "   AND SUBSTRING(SC5.C5_EMISSAO,1,6) = '"+aDatas[x][1]+"' "
			
			TCQUERY cQrb NEW ALIAS "QVEN"
			
			
			cQrc := ""
			cQrc += "SELECT SUM(D2_QUANT) AS CONS,COUNT(DISTINCT(D2_CLIENTE||D2_LOJA)) AS CLI "
			cQrc += "  FROM " + RetSqlName("SD2") + " SD2, "+ RetSqlName("SF4") + " SF4 "
			cQrc += " WHERE SF4.F4_ESTOQUE = 'S' "
			cQrc += "   AND F4_PODER3 != 'S' "
			cQrc += "   AND SF4.D_E_L_E_T_ = ' ' "
			cQrc += "   AND SF4.F4_CODIGO = SD2.D2_TES "
			cQrc += "   AND SF4.F4_FILIAL = '" + xFilial("SF4") + "' "
			cQrc += "   AND SD2.D_E_L_E_T_ = ' ' "
			cQrc += "   AND SUBSTRING(SD2.D2_EMISSAO,1,6)= '" + aDatas[x][1]+ "' "
			If nOpcLoc == 3
				cQrc += " AND EXISTS (SELECT A1_COD,A1_LOJA "
				cQrc += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
				cQrc += "              WHERE CC2.D_E_L_E_T_ = ' ' "
				cQrc += "                AND CC2_ARMPAD = '  ' "
				cQrc += "                AND CC2_CODMUN = A1_COD_MUN  "
				cQrc += "                AND CC2_EST = A1_EST  "
				cQrc += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
				cQrc += "                AND A1.D_E_L_E_T_ = ' ' "
				cQrc += "                AND A1_LOJA = D2_LOJA "
				cQrc += "                AND A1_COD = D2_CLIENTE "
				cQrc += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
			ElseIf nOpcLoc == 4
				cQrc += " AND EXISTS (SELECT A1_COD,A1_LOJA "
				cQrc += "               FROM "+RetSqlName("SA1")+ " A1," +RetSqlName("CC2") + " CC2 "
				cQrc += "              WHERE CC2.D_E_L_E_T_ = ' ' "
				cQrc += "                AND CC2_ARMPAD = '"+cLocPad+"' "
				cQrc += "                AND CC2_CODMUN = A1_COD_MUN  "
				cQrc += "                AND CC2_EST = A1_EST  "
				cQrc += "                AND CC2_FILIAL = '"+xFilial("CC2")+"' "
				cQrc += "                AND A1.D_E_L_E_T_ = ' ' "
				cQrc += "                AND A1_LOJA = D2_LOJA "
				cQrc += "                AND A1_COD = D2_CLIENTE "
				cQrc += "                AND A1_FILIAL = '"+xFilial("SA1")+"') "
			ElseIf !Empty(cLocPad)
				cQrc  += "AND D2_LOCAL ='"+cLocPad+"' "
			Endif
			cQrc += "   AND SD2.D2_COD = '" + cProd +"' "
			cQrc += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "' "
			
			TCQUERY cQrc NEW ALIAS "QRC"
			
			
			dbSelectArea("FATU")
			RecLock("FATU",.T.)
			FATU->MESANO := Substr(aDatas[x][1],5,2)+"/"+Substr(aDatas[x][1],1,4)
			FATU->VEND   := QVEN->CONSUMO
			FATU->FATU   := QRC->CONS
			FATU->CLI    := QRC->CLI
			MsUnLock("FATU")
			nMedven += QVEN->CONSUMO
			nMedfat += QRC->CONS
			If !Empty(QVEN->CONSUMO)
				nMeses  += 1
			Endif
			QVEN->(DbCloseArea())
			QRC->(DbCloseArea())
		Endif
	Next
	nMedven := (nMedven/nMeses)
	nMedfat := (nMedfat/nMeses)
	
	dbSelectArea("FATU")
	dbGotop()
	
	aCampos := {}
	Aadd(aCampos,{ "MESANO"     ,"Mês Ano" } )
	Aadd(aCampos,{ "VEND"       ,"Vendido","@E 999,999" } )
	Aadd(aCampos,{ "FATU"       ,"Faturado","@E 999,999" } )
	Aadd(aCampos,{ "CLI"        ,"Clientes","@E 999,999"})
	
	@ 200,1 TO 600,700 DIALOG oConsumo TITLE OemToAnsi("Consumo mês a mês Vendido e Faturado")
	@ 005,005 TO 170,340 BROWSE "FATU" OBJECT oBrw2 FIELDS aCampos
	@ 173,015 Say "Média de venda"
	@ 173,060 Get nMedven size 30,13 picture "@E 999,999.99" when .f.
	@ 173,110 Say "Média de faturamento"
	@ 173,190 Get nMedfat size 30,13 picture "@E 999,999.99" when .f.
	
	@ 185,195 button "Fechar "     size 37,13 Action Close(oConsumo)
	
	ACTIVATE DIALOG oConsumo CENTERED
	FATU->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index
	
Return


//³Executa consulta e apresenta tela com preço de tabela                                           
Static function Precos
	
	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local cAlias	:= ""
	Local oTmpTable
	
	aStru:={}
	
	Aadd(aStru,{ "TAB",  "C", 03, 0 } )
	Aadd(aStru,{ "DESCRI",  "C", 30, 0 } )
	Aadd(aStru,{ "PRCVEN","N", 10, 2 } )
	Aadd(aStru,{ "ITEM","C", 04, 0 } )
	
	// cArq := CriaTrab(aStru,.t.)
	// dbUseArea ( .T.,"TOPCONN", cArq, "PRC", NIL, .F. )

	cAlias := "PRC"
	oTmpTable := FWTemporaryTable():New(cAlias,aStru)
	oTmpTable:Create()

	dbSelectArea(cAlias)
	
	
	cQri := ""
	cQri += "SELECT DA1_PRCVEN,DA1_CODTAB,DA1_ITEM,DA0_DESCRI FROM "
	cQri += RetSqlName("DA1") + " DA1, " + RetSqlName("DA0") + " DA0 "
	cQri += "WHERE DA1.D_E_L_E_T_ = ' ' AND DA0.D_E_L_E_T_ = ' ' "
	cQri += "AND DA0.DA0_FILIAL = '" + xFilial("DA0")+ "' "
	cQri += "AND DA1.DA1_FILIAL = '" + xFilial("DA1")+ "' "
	cQri += "AND DA1.DA1_CODPRO = '" + cProd + "' "
	cQri += "AND DA1.DA1_CODTAB = DA0.DA0_CODTAB "
	cQri += "ORDER BY DA1.DA1_CODTAB ASC "
	
	TCQUERY cQri NEW ALIAS "QDA1"
	
	While !Eof()
		
		dbSelectArea("PRC")
		RecLock("PRC",.T.)
		PRC->TAB     := QDA1->DA1_CODTAB
		PRC->DESCRI  := QDA1->DA0_DESCRI
		PRC->PRCVEN  := QDA1->DA1_PRCVEN
		PRC->ITEM    := QDA1->DA1_ITEM
		MsUnLock("PRC")
		
		dbSelectArea("QDA1")
		dbSkip()
	Enddo
	
	QDA1->(DbCloseArea())
	
	
	dbSelectArea("PRC")
	dbGotop()
	
	aCampos := {}
	Aadd(aCampos,{ "TAB"     ,"Cód.Tab" } )
	Aadd(aCampos,{ "DESCRI"   ,"Descrição" } )
	Aadd(aCampos,{ "PRCVEN"  ,"Preço","@E 999,999.99" } )
	Aadd(aCampos,{ "ITEM" ,"Item"})
	
	@ 200,1 TO 600,700 DIALOG oPrecos TITLE OemToAnsi("Consulta de preços de tabela")
	@ 005,005 TO 170,340 BROWSE "PRC" OBJECT oBrw3 FIELDS aCampos
	
	@ 185,195 button "Fechar "     size 37,13 Action Close(oPrecos)
	
	ACTIVATE DIALOG oPrecos CENTERED
	PRC->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index
	
Return

Static function Compras
	
	Local aCampos := {}
	Local aStru   := {}
	
	aStru:={}
	
	Aadd(aStru,{ "NUM",  "C", TamSX3("D1_DOC")[1], 0 } )
	Aadd(aStru,{ "QTE",  "N", 08, 0 } )
	Aadd(aStru,{ "PRCCONF","N", 10, 2 } )
	Aadd(aStru,{ "EMISSAO","D", 08, 0 } )
	Aadd(aStru,{ "ENTREGA" , "D", 08, 0 } )
	Aadd(aStru,{ "CONDPAG" , "C", 30,0 } )
	
	// cArq := CriaTrab(aStru,.t.)
	// dbUseArea ( .T.,"TOPCONN", cArq, "VEND", NIL, .F. )

	cAlias := "TRB"
	oTmpTable := FWTemporaryTable():New(cAlias,aCampos)
	oTmpTable:Create()

	dbSelectArea(cAlias)
	
	cQri := ""
	cQri += "SELECT D1_VUNIT,D1_DOC,D1_EMISSAO,D1_DTDIGIT,D1_QUANT,F1_COND "
	cQri += "  FROM "+ RetSqlName("SD1") + " SD1, " + RetSqlName("SF1") + " SF1 "
	cQri += " WHERE SD1.D_E_L_E_T_ = ' ' AND SF1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SD1.D1_FILIAL = '" + xFilial("SD1") + "' "
	cQri += "   AND SF1.F1_FILIAL = '" + xFilial("SF1") + "' "
	If !Empty(cLocPad)
		cQri += " AND D1_LOCAL = '"+cLocPad+"' "
	Endif
	cQri += "   AND SD1.D1_COD = '" + cProd + "' "
	cQri += "   AND SD1.D1_TIPO = 'N' "
	cQri += "   AND SD1.D1_DOC = SF1.F1_DOC "
	cQri += "   AND SD1.D1_SERIE = SF1.F1_SERIE "
	cQri += " ORDER BY SD1.D1_DTDIGIT DESC, SD1.D1_DOC DESC "
	
	TCQUERY cQri NEW ALIAS "QD1"
	
	While !Eof()
		Dbselectarea("SE4")
		dbsetorder(1)
		dbseek(xFilial("SE4")+QD1->F1_COND)
		
		If !Empty(QD1->D1_DOC)
			dbSelectArea("VEND")
			RecLock("VEND",.T.)
			VEND->NUM     := QD1->D1_DOC
			VEND->QTE     := QD1->D1_QUANT
			VEND->PRCCONF := QD1->D1_VUNIT
			VEND->EMISSAO := STOD(QD1->D1_EMISSAO)
			VEND->ENTREGA := STOD(QD1->D1_DTDIGIT)
			VEND->CONDPAG := QD1->F1_COND+" - " + SE4->E4_DESCRI
			MsUnLock("VEND")
		Endif
		dbSelectArea("QD1")
		dbSkip()
	Enddo
	QD1->(DbCloseArea())
	
	dbSelectArea("VEND")
	dbGotop()
	
	aCampos := {}
	Aadd(aCampos,{ "NUM"     ,"Nº NF" } )
	Aadd(aCampos,{ "QTE"   ,"Qte","@E 999,999" } )
	Aadd(aCampos,{ "PRCCONF"  ,"Prc.Conf","@E 999,999.99" } )
	Aadd(aCampos,{ "EMISSAO" ,"Emissão"})
	Aadd(aCampos,{ "ENTREGA" ,"Dt Entrada" } )
	Aadd(aCampos,{ "CONDPAG" , "Cond.Pgto" })
	@ 200,1 TO 600,700 DIALOG oCompras TITLE OemToAnsi("Consulta de notas fiscais de entrada normais")
	@ 005,005 TO 170,340 BROWSE "VEND" OBJECT oBrw4 FIELDS aCampos
	
	@ 185,195 button "Fechar "     size 37,13 Action Close(oCompras)
	
	ACTIVATE DIALOG oCompras CENTERED
	VEND->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index
	
Return


Static function Estoques
	
	Local aCampos 	:= {}
	Local aStru   	:= {}
	Local cAlias	:= ""
	Local oTmpTable
	
	aStru:={}
	
	Aadd(aStru,{ "ARMAZ"  , "C", 02, 0 } )
	Aadd(aStru,{ "QATU"   , "N", 10, 0 } )
	Aadd(aStru,{ "RESERVA", "N", 10, 0 } )
	Aadd(aStru,{ "DISP"   , "N", 10, 0 } )
	
	// cArq := CriaTrab(aStru,.t.)
	// dbUseArea ( .T.,"TOPCONN", cArq, "EST", NIL, .F. )
	
	cAlias := "EST"
	oTmpTable := FWTemporaryTable():New(cAlias,aStru)
	oTmpTable:Create()

	dbSelectArea(cAlias)
	
	cQri := ""
	cQri += "SELECT B2_LOCAL,B2_QATU,B2_RESERVA,B2_USAI,(B2_QATU - B2_RESERVA)AS DISP FROM "
	cQri += RetSqlName("SB2") + " SB2 "
	cQri += "WHERE D_E_L_E_T_ = ' ' AND B2_FILIAL = '" + xFilial("SB2")+ "' "
	cQri += "AND B2_COD = '" + cProd + "' "
	cQri += "ORDER BY B2_LOCAL ASC "
	
	
	TCQUERY cQri NEW ALIAS "QEST"
	
	While !Eof()
		
		dbSelectArea("EST")
		RecLock("EST",.T.)
		EST->ARMAZ     := QEST->B2_LOCAL
		EST->QATU      := QEST->B2_QATU
		EST->RESERVA   := QEST->B2_RESERVA
		EST->DISP      := QEST->DISP
		MsUnLock("EST")
		dbSelectArea("QEST")
		dbSkip()
	Enddo
	QEST->(DbCloseArea())
	
	
	dbSelectArea("EST")
	dbGotop()
	
	aCampos := {}
	Aadd(aCampos,{ "ARMAZ"     ,"Armaz" } )
	Aadd(aCampos,{ "QATU"      ,"Est Fisico","@E 999,999" } )
	Aadd(aCampos,{ "RESERVA"   ,"Lib Pedido","@E 999,999" } )
	Aadd(aCampos,{ "DISP"      ,"Disponível","@E 999,999" } )
	
	@ 200,1 TO 600,700 DIALOG oEst TITLE OemToAnsi("Consulta posição de estoque")
	@ 005,005 TO 170,340 BROWSE "EST" OBJECT oBrw4 FIELDS aCampos
	
	@ 185,195 button "Fechar "     size 37,13 Action Close(oEst)
	
	ACTIVATE DIALOG oEst CENTERED
	EST->(DbCloseArea())
	FErase(cArq + GetDbExtension()) // Deleting file
	FErase(cArq + OrdBagExt()) // Deleting index
	
Return


User Function BIG018A
	
	If nAcomp > 0
		aCols[n][nPosGera] := "X"
	Else
		aCols[n][nPosGera] := " "
	Endif
	
	aCols[n][nPosSubComp] := nAcomp * aCols[n][nPosPrcConf]
	aCols[n][nPosSubPeso] := nAcomp * aCols[n][nPosPeso]
	
Return(.T.)


/*
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Valida Previsão nova³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
User Function BIG018B
	Local nAcomp1 := 0
	Local nAcomp := 0
	
	nAcomp := (nNewPre - aCols[n][nPosEstLiq] - aCols[n][nPosnComp])
	If nAcomp <= 0
		nAcomp1 = 0
	Else
		nAcomp1 := (nAcomp/aCols[n][nPosnMin]) - Round(nAcomp/aCols[n][nPosnMin],0)
		If (nAcomp1 > 0 ) .And. (nAcomp1 < 0.3)
			nAcomp1 := Round(nAcomp/aCols[n][nPosnMin],0)
			nAcomp1 := nAcomp1 * aCols[n][]
		Else
			nAcomp1 := Round(nAcomp/aCols[n][nPosnMin],0)+1
			nAcomp1 := nAcomp1 * aCols[n][nPosnMin]
		Endif
	Endif
	
	If nAcomp1 > 0
		aCols[n][nPosGera] := "X"
	Else
		aCols[n][nPosGera] := " "
	Endif
	aCols[n][nPosaComp] := Round(nAcomp1,0)
	aCols[n][nPosSubComp] := Round(nAcomp1,0) * aCols[n][nPosPrcConf]
	aCols[n][nPosSubPeso] := Round(nAcomp1,0) * aCols[n][nPosPeso]
	
	
Return(.T.)


User function BIG018C
	
	aCols[n][nPosSubComp] := nPrcConf * aCols[n][nPosaComp]
	
Return(.T.)


User Function BIG018D
	
	Local nAcomp1 := 0
	Local nAcomp := 0
	
	nAcomp := (aCols[n][nPosnNewPr] - aCols[n][nPosEstLiq] - aCols[n][nPosnComp])
	If nAcomp <= 0
		nAcomp1 := 0
	Else
		nAcomp1 := (nAcomp/aCols[n][nPosnMin]) - Round(nAcomp/aCols[n][nPosnMin],0)
		If (nAcomp1 > 0 ) .And. (nAcomp1 < 0.3)
			nAcomp1 := Round(nAcomp/nMin,0)
			nAcomp1 := nAcomp1 * nMin
		Else
			nAcomp1 := Round(nAcomp/nMin,0)+1
			nAcomp1 := nAcomp1 * nMin
		Endif
	Endif
	
	
	If nAcomp1 > 0
		aCols[n][nPosGera] := "X"
	Else
		aCols[n][nPosGera] := " "
	Endif
	
	aCols[n][nPosaComp] := nAcomp1
	aCols[n][nPosSubComp] := nAcomp1 * aCols[n][nPosPrcConf]
	aCols[n][nPosSubPeso] := nAcomp1 * aCols[n][nPosPeso]
	
	
Return(.T.)

User Function BIG018E
	
	
	
	Dbselectarea("SE4")
	dbsetorder(1)
	If !Dbseek(xFilial("SE4")+cCondpag)
		Alert("Condição de pagamento inexistente")
		Return(.F.)
	Endif
	
Return(.T.)

Static Function Atualizar
	
	Local	x
	
	nTotpeso := 0.000
	nTotBruto := 0
	nTotcomp := 0.00
	nQteCx   := 0
	
	For x := 1 to Len(aCols)
		dbSelectArea("SB1")
		dbSetOrder(1)
		If dbSeek(xFilial("SB1")+aCols[x][nPosCod])
			If aCols[x][nPosGera] == "X"
				nTotpeso += aCols[x][nPosSubPeso]
				nTotBruto += aCols[x][nPosaComp]*SB1->B1_PESBRU
				nTotcomp += aCols[x][nPosSubComp]
				If SB1->B1_SEGUM == " "
					nQteCx += aCols[x][nPosaComp]
				else
					If SB1->B1_TIPCONV == "D"
						nQteCx += (aCols[x][nPosaComp]/SB1->B1_CONV)
					Else
						nQteCx += (aCols[x][nPosaComp]*SB1->B1_CONV)
					Endif
				Endif
			Else
				nTotpeso += 0
				nTotcomp += 0
				nQteCx   += 0
			Endif
		Endif
	Next
	aSort(aCols,,,{|x,y| x[nPosSeq] < y[nPosSeq]})
	oItems:Refresh()
	
	
Return
Static Function PESQC
	
	Local	nQ
	
	For nQ := 1 To Len(aCols)
		If Alltrim(cPesq) $ aCols[nQ,1]
			oItems:oBrowse:nAT 	:= nQ
			Exit
		Endif
	Next
	oItems:oBrowse:SetFocus()
	oItems:oBrowse:Refresh()
	oItems:Refresh()
	cPesq := Space(15)
	
Return

Static Function PESQD()
	
	local nQ := 0 as numeric
	
	For nQ := 1 To Len(aCols)
		If Alltrim(cPesqd) $ aCols[nQ,2]
			oItems:oBrowse:nAT 	:= nQ
			Exit
		Endif
	Next
	oItems:oBrowse:SetFocus()
	oItems:oBrowse:Refresh()
	oItems:Refresh()
	cPesqd := Space(40)
	
Return

Static Function ORD
	
	//"A comprar","Estoque Liquido","Consumo Atual"
	If cSeq == "A comprar"
		aSort(aCols,,,{|x,y| x[nPosaComp] > y[nPosaComp]})
		oItems:Refresh()
	Elseif cSeq == "Estoque Liquido"
		aSort(aCols,,,{|x,y| x[nPosEstLiq] > y[nPosEstLiq]})
		oItems:Refresh()
	Elseif cSeq == "Consumo Atual"
		aSort(aCols,,,{|x,y| x[nPosCAtu] > y[nPosCAtu]})
		oItems:Refresh()
	Endif
	
Return


Static Function Gravar()
	Local	x
	
	If !MsgYesNo("Deseja realmente prosseguir?","Continuar?")
		Return
	Endif
	
	For x := 1 To Len(aCols)
		dbSelectArea("SB1")
		dbSetOrder(1)
		If dbSeek(xFilial("SB1")+aCols[x][nPosCod])
			RecLock("SB1",.F.)
			SB1->B1_CUSTD 	:= aCols[x][nPosPrcConf]
			SB1->B1_QE 		:= aCols[x][nPosnMin]
			SB1->B1_OBSERV  := aCols[x][nPosObserv]
			SB1->B1_EMAX	:= aCols[x][nPosAlvo]
			SB1->B1_STS 	:= aCols[x][nPosStatus]
			SB1->B1_DIASEST	:= aCols[x][nPosEstDias]
			MsUnLock("SB1")
		Else
			Alert("Produto não encontrado"+aCols[x][1])
		Endif
		dbSelectArea("SZ7")
		dbSetOrder(2)
		If dbSeek(xFilial("SZ7")+SubStr(cFornece,1,6)+SubStr(cFornece,7,2)+aCols[x][nPosCod]+cTabela)
			RecLock("SZ7",.F.)
			SZ7->Z7_PRAZO := Val(Alltrim(aCols[x][nPosCondPag]))
			MsUnlock("SZ7")
		Endif
		
	Next
	Alert("Dados alterados no cadastro de produto")
Return


Static Function GerarPedido
	
	Local	lConfirma	:= .F.
	
	If !MsgYesNo("Deseja realmente prosseguir?","Informação")
		Return
	Endif
	
	
	
	DEFINE MSDIALOG oDlg3 FROM 001,001 TO 180,350 OF oMainWnd PIXEL TITLE OemToAnsi("Defina a data programada")
	
	@ 020,010 Say "Data programada para entrega: " of oDlg3 Pixel
	@ 018,085 MsGet dEntrega SIZE 40,10 of oDlg3 Pixel
	
	@ 035,010 Say "Tabela Preços" of oDlg3 Pixel
	@ 033,085 MsGet cTabPrc SIZE 40,10 F3 "AIA" of oDlg3 Pixel Valid ExistCpo("AIA",aFornOpc[1]+aFornOpc[2]+cTabPrc)
	
	@ 050,010 Say "Cond.Pagamento" of oDlg3 Pixel
	@ 048,085 MsGet cCondPag SIZE 40,10 F3 "SE4" of oDlg3 Pixel
	
	ACTIVATE MSDIALOG oDlg3 ON INIT EnchoiceBar(oDlg3,{|| lConfirma	:= .T. /*true*/,oDlg3:End()},{|| oDlg3:End()},,) CENTERED
	
	
	If lConfirma
		EfetivarPedido()
	Endif
	
	
Return


Static Function EfetivarPedido
	
	Local	x
	
	aCab     := {}
	aTotItem := {}
	nItem    := ""
	aItem   := {}
	//aFornOpc	:= {"000468",""}
	If Empty(aFornOpc[1])
		
	Endif
	
	DbSelectArea("SA2")
	DbSetOrder(1)
	DbSeek(xFilial("SA2")+ aFornOpc[1]+aFornOpc[2])
	
	For x := 1 To Len(aCols)
		
		If !Empty(aCols[x][nPosGera])
			aCab := {;
				{"C7_FILIAL"	,SM0->M0_CODFIL	,Nil},; // Numero do Pedido
			{"C7_NUM",           			,Nil},; // Numero do Pedido
			{"C7_EMISSAO" 	,dDataBase  	,Nil},; // Data de Emissao
			{"C7_FORNECE" 	,aFornOpc[1] 	,Nil},; // Fornecedor
			{"C7_LOJA"    	,aFornOpc[2]	,Nil},; // Loja do Fornecedor
			{"C7_COND"    	,cCondpag       ,Nil},; // Condicao de pagamento
			{"C7_TES"     	,Space(3)       ,Nil},; // TES
			{"C7_CONTATO" 	,SA2->A2_CONTATO,Nil},; // Contato
			{"C7_FILENT"  	,SM0->M0_CODFIL	,Nil}}  // Filial Entrega
			
			If Len(aItem) <> 0
				nItem := SomaIt(aItem[1][2])
			Else
				nItem := "0001"
			Endif
			aItem:={;
				{"C7_ITEM"		,Alltrim(nItem)			,Nil},; //Numero do Item
			{"C7_CODTAB"	,cTabPrc  				,Nil},; // Codigo da tabela de precos
			{"C7_PRODUTO"	,aCols[x][nPosCod]   	,Nil},; //Codigo do Produto
			{"C7_QUANT"  	,aCols[x][nPosaComp]  	,Nil},; //Quantidade
			{"C7_DATPRF" 	,dDatabase				,Nil},; //Data De Entrega
			{"C7_FLUXO"  	,"S"					,Nil},; //Fluxo de Caixa (S/N)
			{"C7_DATPRF" 	,dEntrega      			,Nil},;
				{"C7_LOCAL"  	,IIf(Empty(cLocPad),"01",cLocPad)   ,Nil}}  //Localizacao
			AADD(aTotItem,aItem)
		Endif
	Next
	
	If !Empty(aTotItem)
		_MATA120()
	Else
		MsgInfo("Nao existem registros para o pedido!! Verifique os parametros.","Informacao")
	Endif
	
	
Return

Static Function _MATA120
	
	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.
	
	
	Mata120(1,aCab,aTotItem,3,.T.)
	
	
	If lMsErroAuto
		MostraErro()
		DisarmTransaction()
	Endif
	
Return


Static Function stExporta()
	
	If FindFunction("RemoteType") .And. RemoteType() == 1
		DlgToExcel({{"GETDADOS","Simula Compras",aHeader,aCols}})
	EndIf
	
Return




