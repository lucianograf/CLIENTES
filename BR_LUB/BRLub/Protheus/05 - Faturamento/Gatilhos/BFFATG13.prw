#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} BFFATG13
// Retorna a Descrição da Razão Social do Cliente ou Fornecedor conforme o Tipo de Nota
@author Marcelo Alberto Lauschner 
@since 12/09/2018
@version 1.0
@return ${return}, ${return_description}
@param nInAlias, numeric, descricao
@type function
/*/
User function BFFATG13(nInAlias,cOpcOut)
	
	Local	aAreaOld	:= GetArea()
	Local	cNomRet		:= ""
	Local	cQry		:= ""
	Default	nInAlias	:= 2 // SF2
	Default	cOpcOut		:= "_NOME"
	// SF1
	If nInAlias == 1
		If SF1->F1_TIPO $ "D#B"
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SF1->F1_FORNECE+SF1->F1_LOJA)
			cNomRet	:= &("SA1->A1"+cOpcOut) //"_NOME
		Else
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA)
			cNomRet	:= &("SA2->A2"+cOpcOut) //"_NOME
		Endif
	// SF2
	ElseIf nInAlias == 2
		If SF2->F2_TIPO $ "D#B"
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+SF2->F2_CLIENTE+SF2->F2_LOJA)
			cNomRet	:= &("SA2->A2"+cOpcOut) //"_NOME
		Else
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)
			cNomRet	:= &("SA1->A1"+cOpcOut) //"_NOME	
		Endif
	ElseIf nInAlias == 3
		If SD2->D2_TIPO $ "D#B"
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+SD2->D2_CLIENTE+SD2->D2_LOJA)
			cNomRet	:= &("SA2->A2"+cOpcOut) //"_NOME
		Else
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SD2->D2_CLIENTE+SD2->D2_LOJA)
			cNomRet	:= &("SA1->A1"+cOpcOut) //"_NOME	
		Endif
	ElseIf nInAlias == 4
		If SD1->D1_TIPO $ "D#B"
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SD1->D1_FORNECE+SD1->D1_LOJA)
			cNomRet	:= &("SA1->A1"+cOpcOut) //"_NOME
		Else
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+SD1->D1_FORNECE+SD1->D1_LOJA)
			cNomRet	:= &("SA2->A2"+cOpcOut) //"_NOME
		Endif
	ElseIf nInAlias == 5
		If SC5->C5_TIPO $ "D#B"
			DbSelectArea("SA2")
			DbSetOrder(1)
			DbSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
			cNomRet	:= &("SA2->A2"+cOpcOut) //"_NOME
		Else
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
			cNomRet	:= &("SA1->A1"+cOpcOut) //"_NOME	
		Endif
	ElseIf nInAlias == 6
		If SC5->C5_BLQ == '1'
			cNomRet	:= "Pedido Bloqueado por Regra"
		ElseIf SC5->C5_BLQ == '2'
			cNomRet	:= "Pedido bloqueado por Verba"
		ElseIf Empty(SC5->C5_LIBEROK).And.Empty(SC5->C5_NOTA) .And. Empty(SC5->C5_BLQ)
			cNomRet	:= "Pedido em Aberto"
		ElseIf !Empty(SC5->C5_NOTA) .Or. SC5->C5_LIBEROK=='E' .And. Empty(SC5->C5_BLQ)
			cNomRet	:= "Pedido Encerrado"
		ElseIf !Empty(SC5->C5_LIBEROK) .And. Empty(SC5->C5_NOTA).And. Empty(SC5->C5_BLQ)
			cNomRet	:= "Pedido Liberado"
		
			cQry := "SELECT DISTINCT "
			cQry += "       CASE "
			cQry += "         WHEN C9_BLEST = '  ' AND C9_BLCRED = '  ' AND C9_BLTMS = ' ' THEN 'Liberado' "
			cQry += "         WHEN (C9_BLCRED = '10' AND C9_BLEST = '10' ) OR (C9_BLCRED ='ZZ' AND C9_BLEST = 'ZZ') THEN 'Faturado' "
			cQry += "         WHEN C9_BLCRED NOT IN('  ','09','10','ZZ') THEN 'Bloqueado - Credito'"
			cQry += "         WHEN C9_BLCRED = '09' THEN 'Bloqueado - Credito'"	
			cQry += "         WHEN C9_LOTECTL = ' ' AND C9_BLEST NOT IN('  ','10','ZZ') THEN 'Blq.Estoque Falta Conferir'"
			cQry += "         WHEN C9_BLEST NOT IN('  ','10','ZZ') THEN 'Bloqueado - Estoque'"
			cQry += "         WHEN C9_BLWMS <= '05' AND C9_BLWMS <> '  ' THEN 'Bloqueado - WMS'"
			cQry += "         WHEN C9_BLTMS <> '  ' THEN 'Bloqueado - TMS'" 	
			cQry += "      END STATUS_SC9 "
			cQry += "  FROM " + RetSqlName("SC9") + " SC9 "
			cQry += " WHERE SC9.D_E_L_E_T_ = ' ' "
			cQry += "   AND SC9.C9_PEDIDO = '"+SC5->C5_NUM+"'"
			cQry += "   AND SC9.C9_FILIAL = '" + xFilial("SC9") + "' "
			
			DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QSC9",.T.,.T.)
			
			If !Eof()
				cNomRet	:= ""
			Endif
			While QSC9->(!Eof())
			
				cNomRet		+= QSC9->STATUS_SC9
				QSC9->(DbSkip())
			Enddo
			QSC9->(DbCloseArea())
			
		Endif
		 
		
	Endif
	RestArea(aAreaOld)
	
Return cNomRet