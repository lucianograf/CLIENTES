#INCLUDE "rwmake.ch"
#INCLUDE "tbiconn.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} MT440GR
(Ponto de entrada na liberação de pedidos de venda. Irá avaliar reserva de estoque para o Produto X Vendedor no conceito de Cota por vendedor)
	
@author MarceloLauschner
@since 03/01/2014
@version 1.0		

@return Logico, 

@example
(examples)

@see (links_or_references)
/*/
User function MT440GR()

	Local		aAreaOld	:= GetArea()
	Local		cQry		:= ""
	Local 		nItem  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	Local 		nProduto 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local 		nQtdLib  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDLIB"})
	Local 		nALiberar 	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_SLDALIB"})
	Local		nLocal		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
	Local		nQuant    	:= 0
	Local		lBloqC6		:= .F.
	Local 		x 
	
	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("MT440GR")
		Return .T.
	Endif
	
	

// Se botão Pressionado for o Confirma
	If ParamIxb[1] ==  1 .And. nLocal > 0 .And. nALiberar > 0 .And. nQtdLib > 0 .And. nProduto > 0 .And. nItem > 0 
	
		DbSelectArea("SA1")
		Dbsetorder(1)
		Dbseek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)

		Dbselectarea("SB1")
		Dbsetorder(1)
		Dbselectarea("SB2")
		Dbsetorder(1)
		DbSelectArea("SC6")
		DbSetOrder(1)
	
		For x := 1 To Len(aCols)
			// Posiciona no item do pedido
			SC6->(DbSeek(xFilial("SC6")+M->C5_NUM + aCols[x][nItem] + aCols[x][nProduto]))
        
        	// Evita que pedidos bloqueados e/ou com Residuo sejam liberados mesmo que a quantidade a liberar tenha sido digitada manualmente na tela de liberação
			If Alltrim(SC6->C6_BLQ) $ "R#S"
				aCols[x][nQtdLib] := 0
			Endif
		
		
			If Empty(aCols[x][nQtdLib]) .And. aCols[x][nALiberar] > 0 .And. !Alltrim(SC6->C6_BLQ) $ "N# "
				lBloqC6		:= .T.
			Endif
        
        	// Apenas baixa reservas se o item for realmente liberado
			If !Empty(aCols[x][nQtdLib]) .And. !lBloqC6
				cQry := ""
				cQry += "SELECT C0_NUM,C0_TIPO,C0_DOCRES,C0_SOLICIT,C0_PRODUTO,C0_LOCAL,C0_QUANT,C0_VALIDA,C0_FILRES,C0_LOCALIZ,C0_NUMSERI,C0_LOTECTL,C0_NUMLOTE "
				cQry += "  FROM " + RetSqlName("SC0")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND C0_TIPO = 'CL' "
				cQry += "   AND C0_DOCRES = '" + M->C5_CLIENTE+M->C5_LOJACLI + "' "
				cQry += "   AND C0_VALIDA >= '" + DTOS(dDataBase)+ "' "
				cQry += "   AND C0_QUANT > 0 "
				cQry += "   AND C0_LOCAL = '"+aCols[x][nLocal]+"' "
				cQry += "   AND C0_PRODUTO = '" + aCols[x][nProduto] +  "' "
				cQry += "   AND C0_FILIAL = '"+ xFilial("SC0") + "' "
			
				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRC0', .F., .T.)
				
				If !Empty(QRC0->C0_QUANT)
					If QRC0->C0_QUANT >=  aCols[x][nQtdLib]
						nQuant := QRC0->C0_QUANT - aCols[x][nQtdLib]
						nOpc 	:= 2
					Else
						nQuant := 0
						nOpc 	:= 2
					Endif
				
					aOperacao := {	nOpc,;
						QRC0->C0_TIPO,;
						QRC0->C0_DOCRES,;
						QRC0->C0_SOLICIT,;
						QRC0->C0_FILRES,;
						" "}
					aLote    := {	QRC0->C0_NUMLOTE,;
						QRC0->C0_LOTECTL,;
						QRC0->C0_LOCALIZ,;
						QRC0->C0_NUMSERI}
				
					A430Reserv(aOperacao,QRC0->C0_NUM,QRC0->C0_PRODUTO,QRC0->C0_LOCAL,nQuant,aLote,{},{},) // funcao que substitui o msexecauto do mata430
						
					Dbselectarea("SC0")
					DbsetOrder(1)
					If Dbseek(xFilial("SC0")+QRC0->C0_NUM+QRC0->C0_PRODUTO)
						RecLock("SC0",.F.)
						SC0->C0_VALIDA := STOD(QRC0->C0_VALIDA)
						MsUnlock()
					Endif
					SC0->(dbCloseArea())
				Endif
				QRC0->(DbCloseArea())
			
				// Zera solicitações de reserva do produto em cursor caso a data de validade esteja vencida
				cQry := ""
				cQry += "SELECT C0_NUM,C0_TIPO,C0_DOCRES,C0_SOLICIT,C0_PRODUTO,C0_LOCAL,C0_QUANT,C0_VALIDA,C0_FILRES,C0_LOCALIZ,C0_NUMSERI,C0_LOTECTL,C0_NUMLOTE "
				cQry += "  FROM "+RetSqlName("SC0")
				cQry += " WHERE D_E_L_E_T_ = ' ' "
				cQry += "   AND C0_TIPO = 'VD'  "
				cQry += "   AND C0_VALIDA < '" + DTOS(dDataBase)+ "' "
				cQry += "   AND C0_QUANT > 0 "
				cQry += "   AND C0_LOCAL = '"+aCols[x][nLocal]+"' "
				cQry += "   AND C0_PRODUTO = '" + aCols[x][nProduto] +  "' "
				cQry += "   AND C0_FILIAL = '"+ xFilial("SC0") + "' "
			
				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRC0', .F., .T.)
		
				While !Eof()
				
					nQuant := 0
					nOpc 	:= 2
			
					aOperacao := {	nOpc,;
						QRC0->C0_TIPO,;
						QRC0->C0_DOCRES,;
						QRC0->C0_SOLICIT,;
						QRC0->C0_FILRES,;
						" "}
				
					aLote    := {	QRC0->C0_NUMLOTE,;
						QRC0->C0_LOTECTL,;
						QRC0->C0_LOCALIZ,;
						QRC0->C0_NUMSERI}
					
					A430Reserv(aOperacao,QRC0->C0_NUM,QRC0->C0_PRODUTO,QRC0->C0_LOCAL,nQuant,aLote,{},{},) // funcao que substitui o msexecauto do mata430
				
					Dbselectarea("QRC0")
					Dbskip()
				Enddo
				QRC0->(dbCloseArea())
			Endif
		Next
	Endif

	If lBloqC6
		MsgAlert("Este pedido não foi liberado por alçada ainda!","Pedido pendente de liberação!")
		RestArea(aAreaOld)
		Return .F.
	Endif
	
	RestArea(aAreaOld)

Return .T.
