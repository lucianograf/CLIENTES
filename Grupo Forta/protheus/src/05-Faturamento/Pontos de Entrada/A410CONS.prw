#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} A410CONS
//TODO Ponto de Entrada para adicionar botões na tela do Pedido de Venda
@author Marcelo Alberto Lauschner
@since 05/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function A410CONS()

	Local aBtnSup := {}  
	
	Aadd(aBtnSup,{"AMARELO",{|| U_MLFATC6A()()},"Ação Tmk" })
	
	Aadd(aBtnSup,{"AZUL",{|| sfBonus()},"Promoção" })

Return aBtnSup


/*/{Protheus.doc} sfBonus
//Interface para seleção de combos
@author Administrator
@since 19/05/2017
@version undefined

@type function
/*/
Static Function sfBonus()

	Local		aAreaOld	:= GetArea()
	Local 		aBonus   	:= {}      							// Array com os bonus que o cliente tem direito
	Local 		aSize    	:= MsAdvSize(.T.,.F.,400)			// Tamanho da Janela
	Local 		oDlg											// Janela Bonus
	Local 		oLbx											// Listbox com os bonus
	Local 		aInfo    	:= {}								// Informacoes para a divisao da area de trabalho
	Local 		aObjects 	:= {}								// Definicoes dos objetos
	Local 		aPosLabel	:= {}								// Posicao do Objeto Label
	Local 		lRet	   	:= .F.								// Retorno da funcao
	Local		aButtons	:= {}
	Local 		nLinha    	:= Len(aCols)					// Contador do total de linhas adicionadas
	Local 		nCont	   	:= 0          				// Contador de Linhas do Acols
	Local 		nUsado    	:= Len(aHeader)				// Total de campos (colunas)
	Local 		nPProd    	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})			// Posicao do Produto
	Local 		nPQtd     	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})  			// Posicao da Quantidade
	Local 		nPVrUnit  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})			// Posicao do Valor unitario
	Local		nPVlrItem 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})				// Valor do item
	Local		nPDesc 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})			// % Desconto
	Local		nPValDesc 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})			// $ Desconto em Valor
	Local 		nPTES	   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})			// Posicao do TES
	Local 		nPCf		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})			// Posicao do CFO
	Local 		nPItem		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})			// Posicao do número do item
	Local		nPPrcTab 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})			// Preço Tabela
	Local		nPOper		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_OPER"})
	Local		nPRegBnf	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_XREGBNF"})
	Local		cCodReg		:= ""
	Local 		cItem		:= "00"						// Número do item a ser adicionado
	Local 		cEstado   	:= SuperGetMv("MV_ESTADO")	// Estado da empresa atual
	Local		nQteBrinde	:= 1
	Local		nPrcCombo	:= 0
	Local		aCodRegBon	:= {}
	Local		iQ
	Local		aRegCombo	:= {}
	Local		aItemCombo	:= {}
	Local		nPosCb		:= 0
	Local		oPrcCombo
	Local		nCol,nAux
	Local		cTesItem	:= ""
	If M->C5_TIPO # "N"
		Help( " ", 1, "TLVROTINA" )
		Return(lRet)
	Endif

	If n == nLinha .And. Empty(aCols[n][nPProd]) .And. nLinha > 1 .And. ReadVar() <> "M->C6_PRODUTO"
		MsgStop("Não é permitido selecionar um Combo com uma linha nova e vazia no GetDados!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return lRet
	Endif
	For iQ := 1 To Len(aCols)
		If !aCols[iQ][nUsado+1] .And. !Empty(aCols[iQ][nPRegBnf])
			Aadd(aCodRegBon,aCols[iQ][nPRegBnf])
		Endif
	Next

	// Lista Bonificações/promoções disponíveis - Tipo 1
	aBonus	:= U_BFFATA43(aCodRegBon,M->C5_CLIENTE,M->C5_LOJACLI,M->C5_TABELA,M->C5_CONDPAG,Nil,Nil,"1"/*cTipoRet*/)

	For iQ := 1 To Len(aBonus)
		nPosCb	:= Ascan(aRegCombo, {|x| AllTrim(x[1]) == Substr(aBonus[iQ,2],1,6)})
		If nPosCb == 0	
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+aBonus[iQ,3])
			Aadd(aRegCombo,{Substr(aBonus[iQ,2],1,6),; 
			aBonus[iQ,3],;
			aBonus[iQ,4],;
			SB1->B1_DESC,;
			MaTabPrVen(M->C5_TABELA,aBonus[iQ,3],1,M->C5_CLIENTE,M->C5_LOJACLI,1/*nMoeda*/,M->C5_EMISSAO/*dDataVld*/,1/*nTipo*/,.F. /*lExec*/,,.F./*lProspect*/),;
			SB1->B1_ZCLCOM,;
			aBonus[iQ,14]})
		Endif
	Next

	//aBonus:= FtRgrBonus(aCols,{nPProd,nPQuant,nPTes},M->UA_CLIENTE,M->UA_LOJA,M->UA_TABELA,M->UA_CONDPG,NIL,NIL)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Se nao tiver nenhum bonus exibe o help SEMDADOS ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If (Len(aBonus) == 0)
		Help( " ", 1, "SEMDADOS" )
		Return(lRet)
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajusta o tamanho do Label	       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aObjects := {}

	AAdd( aObjects, { 01, 01, .T., .T. , .F.} )

	aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 0, 0 }
	aPosLabel:= MsObjSize( aInfo, aObjects,  , .T. )

	DEFINE MSDIALOG oDlg FROM  0,0 TO aSize[6],aSize[5] TITLE "Promoções" PIXEL OF oMainWnd //"Bonus"


	//@aPosLabel[1,1] 	, aPosLabel[1,2] 	TO aPosLabel[1,3] , aPosLabel[1,4] LABEL "" OF oDlg  PIXEL

	@aPosLabel[1,1]  	, aPosLabel[1,2]+2  LISTBOX oLbxCombo FIELDS ;
	HEADER;
	"Cód.Regra",;		//	1
	"Cód.Prod",;		//	2
	"Nome Combo",;		//	3
	"Descrição",;		// 	4
	"Preço Combo",;		//	5
	"Faixa Comissão",;	//  6
	"Desc.Máximo";		//  7
	SIZE aPosLabel[1,4]-4 ,190 OF oDlg PIXEL

	oLbxCombo:SetArray(aRegCombo)
	oLbxCombo:bLine:={|| aRegCombo[oLbxCombo:nAt] }
	oLbxCombo:bChange := {|| sfItensCombo(aRegCombo[oLbxCombo:nAt,1],aBonus,@aItemCombo),oLbx:SetArray(aItemCombo),oLbx:bLine:={|| aItemCombo[oLbx:nAt] },oLbx:Refresh(),nPrcCombo := aRegCombo[oLbxCombo:nAt,5],oPrcCombo:Refresh() }

	sfItensCombo(aRegCombo[oLbxCombo:nAt,1],aBonus,@aItemCombo)

	nPrcCombo := aRegCombo[oLbxCombo:nAt,5]

	@aPosLabel[1,1]+197 	, aPosLabel[1,2]+2 Say "Informe Quantidade" of oDlg Pixel
	@aPosLabel[1,1]+195 	, aPosLabel[1,2]+60 MsGet nQteBrinde Size 40,10 Picture "@E 999,999" Valid nQteBrinde > 0  of oDlg Pixel

	@aPosLabel[1,1]+197 	, aPosLabel[1,2]+115 Say "Preço Negociado" of oDlg Pixel
	@aPosLabel[1,1]+195 	, aPosLabel[1,2]+160 MsGet oPrcCombo Var nPrcCombo	Picture "@E 999,999.99" Size 50,10 Valid sfVldPrc(@oPrcCombo,@nPrcCombo,@oLbx,@aItemCombo,aRegCombo[oLbxCombo:nAt,5],aRegCombo[oLbxCombo:nAt,7])  of oDlg Pixel

	@aPosLabel[1,1]+220  	, aPosLabel[1,2]+2  LISTBOX oLbx FIELDS ;
	HEADER;
	" ",;			//	1
	"Cód.Regra",;		//	2
	"Cód.Prod",;		//	3
	"Nome",;			//	4
	"Produto",;			//	5
	"Descricao",;		// 	6
	"Quantidade",;		//	7
	"Tipo Oper.",;		//	8
	"Preço Unitário",;	//	9
	"Soma Combo?",;		//	10
	"Cód.Tabela",;		//  11
	"Preço Venda",;		//  12
	"% Fração",;		//  13
	"Desconto Máximo";	//  14
	SIZE aPosLabel[1,4]-4 ,aPosLabel[1,3]-250 OF oDlg PIXEL

	oLbx:SetArray(aItemCombo)
	oLbx:bLine:={|| aItemCombo[oLbx:nAt] }

	ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| lRet := .T. ,cCodReg	:= aRegCombo[oLbxCombo:nAt,1] ,oDlg:End()},{||oDlg:End()},,aButtons)

	If lRet

		If Empty(M->C5_CLIENTE)
			MsgAlert("Não há cliente informado ainda para validar a regra de promoção!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			RestArea(aAreaOld)
			Return .F.
		Endif

		nTotal := Len(aItemCombo)

		cItem  := Alltrim(aCols[Len(aCols),nPItem])

		For nAux := 1 To nTotal
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1") + aItemCombo[nAux][5]) .And.  Substr(aItemCombo[nAux][2],1,6) == cCodReg
				// Se for o primeiro item e não tiver produto
				If n > 1 .Or. !Empty(aCols[nLinha,nPProd]) 	
					
					cItem	:= Soma1( cItem )
					AAdd(aCols,Array(nUsado+1))
					nLinha ++

					For nCol := 1 To nUsado
						If IsHeadRec(aHeader[nCol,2])
							aCols[nLinha,nCol] :=	 0
						ElseIf IsHeadAlias(aHeader[nCol,2])
							aCols[nLinha,nCol] := "SC6"
						Else
							aCols[nLinha,nCol] := CriaVar(aHeader[nCol,2],.T.)
						EndIf
					Next nCol
					aCols[nLinha,nUsado+1] 	:= .F.
					aCols[nLinha,nPItem]	:= cItem
				Endif

				n := nLinha
				
				A410Produto(aItemCombo[nAux][5],.F.)
				A410MultT("M->C6_PRODUTO",aItemCombo[nAux][5])
				aCols[nLinha,nPProd] 	:= aItemCombo[nAux][5]
				
				aCols[nLinha,nPOper]	:= aItemCombo[nAux][8]// Tipo de operação
				cTesItem				:= MaTesInt(2,aCols[nLinha,nPOper],M->C5_CLIENTE,M->C5_LOJACLI,"C",aCols[nLinha,nPProd],"C6_TES")
				
				A410MultT("M->C6_TES",cTesItem)
				aCols[nLinha,nPTes] 	:= cTesItem
				
 				If ExistTrigger("C6_PRODUTO")
					RunTrigger(2,nLinha)
				Endif	
				
				If ExistTrigger("C6_TES    ")
   					RunTrigger(2,Len(aCols))
				Endif
				
				A410MultT("C6_QTDVEN",aItemCombo[nAux][7]*nQteBrinde,.F.)
				aCols[nLinha,nPQtd]  	:= aItemCombo[nAux][7]*nQteBrinde
				
				
				nXPrcAux	:= aItemCombo[nAux][12]				
				// Soma-se o valor de Tampas do clientes
				
				aCols[nLinha][nPVrUnit] := A410Arred(nXPrcAux  ,"D2_PRCVEN")

				nXPrcAux	:= aCols[nLinha][nPPrcTab]

				
				aCols[nLinha][nPRegBnf]	:= aItemCombo[nAux][2]

				// Recalcula o Valor de Desconto
				aCols[nLinha][nPValDesc] := Round( (nXPrcAux - aCols[nLinha][nPVrUnit]) * aCols[nLinha][nPQtd],TamSX3("C6_VALDESC")[2])
				If aCols[nLinha][nPValDesc] < 0
					aCols[nLinha][nPValDesc]	:= 0
				Endif
				// Recalcula o Percentual de desconto
				aCols[nLinha][nPDesc] := Round( aCols[nLinha][nPValDesc] / (nXPrcAux * aCols[nLinha][nPQtd]) * 100,TamSX3("C6_DESCONT")[2])

				aCols[nLinha][nPVlrItem]:= A410Arred(aCols[nLinha][nPQtd] * aCols[nLinha][nPVrUnit],"D2_PRCVEN")

				If Type('oGetDad:oBrowse')<>"U"
					oGetDad:oBrowse:Refresh()
					Ma410Rodap()
				Endif

			Endif

		Next nAux
	Endif

Return(lRet)


/*/{Protheus.doc} sfItensCombo
// Atualização de itens do combo
@author Marcelo Alberto Lauschner	
@since 19/05/2017
@version undefined
@param cCodReg, characters, descricao
@param aBonus, array, descricao
@param aItemCombo, array, descricao
@type function
/*/
Static Function sfItensCombo(cCodReg,aBonus,aItemCombo)

	Local	iE
	aItemCombo	:= {}
	For iE := 1 To Len(aBonus)
		If Substr(aBonus[iE][2],1,6) == cCodReg
			Aadd(aItemCombo,aClone(aBonus[iE]))
		Endif
	Next

Return 

Static Function sfVldPrc(oPrcCombo,nPrcCombo,oLbx,aItemCombo,nPrcTab,nDescMax)
	Local	iZ
	Local	lRet	:= .T.

	If nPrcCombo <   (Round(nPrcTab * (100-nDescMax)/100,2))
		lRet	:= .F.		
		MsgAlert("O valor informado excede o desconto máximo " + AllTrim(Transform(nDescMax,"@E 999.99")) + "% permitido para o Combo!")
	Else
		For iZ := 1 To Len(aItemCombo)
			If aItemCombo[iZ,10] == "1"
				aItemCombo[iZ,12] := Round(nPrcCombo * aItemCombo[iZ,13] / 100 /  aItemCombo[iZ,7],2)
			Endif
		Next
		oLbx:Refresh()
	Endif

Return lRet 
