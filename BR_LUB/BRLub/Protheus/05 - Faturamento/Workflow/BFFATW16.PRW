#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


/*/{Protheus.doc} BFFATW16
(Mapa de Vendas - Industrial )
@author MarceloLauschner
@since 30/11/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATW16()
	
Return U_BG011IND()



/*/{Protheus.doc} BG011IND
(Mapa de Vendas Industria - Compatibilidade )
@author MarceloLauschner
@since 30/11/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BG011IND()
	
	
	Local aOpenTable := {"SE1","SA3","SCT","SC5","SC6","SF2","SD2","SD1","SF4","SZ8","SB1"}
	
	If Select("SM0") == 0
		
		RPCSetType(3)
		RPCSetEnv("02","01","","","","",aOpenTable) // Abre todas as tabelas.
	Else
		If !(SM0->M0_CODIGO == '02')
			MsgAlert("Esse mapa deve ser gerado apenas nas empresas BigForta!")
			Return
		Endif
		
		If !MsgNoYes("Deseja realmente rodar mapa??")
			Return
		Endif
		
	Endif
	
	MsgInfo("Workflow desativado por solicitação chamado 21.429")

Return 

Static Function sfNoExec()
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	Private 	aMeta 		:= {}
	Private		aMetaUF 	:= {}
	Private		aFaturado 	:= {}
	Private 	aPrazo 		:= {}
	Private 	aElimina 	:= {}
	Private 	aVendido 	:= {}
	Private  	aDevolvi 	:= {}
	Private 	aPendente 	:= {}
	Private 	cMsg 		:= time()
	
	Private 	aMetaT 		:= {}
	Private 	aMetaUFT 	:= {}
	Private 	aFaturadoT	:= {}
	Private		aPrazoT 	:= {}
	Private 	aEliminaT 	:= {}
	Private 	aVendidoT 	:= {}
	Private 	aDevolviT 	:= {}
	Private 	aPendenteT	:= {}
	Private 	dDataIni 	:= DTOS(FirstDay(dDataBase))
	Private 	dDataFim 	:= DTOS(dDataBase)
	Private 	dDtfin 		:= LastDay(dDatabase)
	Private 	dDtini 		:= dDataBase
	Private 	dDtPriDia 	:= STOD(DataMapa(dDatabase, 'P'))
	
	stSQLInd()
	
	stMontaWF()
	
	
Return




/*/{Protheus.doc} stSQLInd
(Executa processo de montagem dos sqls e dados)
@author MarceloLauschner
@since 08/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stSQLInd()
	
	
	// Inicia Sql das metas e montagem da matriz
	Local	nY
	
	cQra := ""
	cQra += "SELECT SUM(SCT.CT_VALOR)AS META, SUM(SCT.CT_QUANT)AS MTLIT, A3_EST AS GRUPO,SA3.A3_COD,SA3.A3_NREDUZ FROM "//modificado Daniel (CASE SUBSTR(SA3.A3_COD,3,2)WHEN '11' THEN '10' ELSE SUBSTR(SA3.A3_COD,3,2) END) AS GRUPO
	cQra += RetSqlName("SCT") + " SCT, "
	cQra += RetSqlName("SA3") + " SA3 "
	cQra += "WHERE SA3.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQra += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQra += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQra += "AND SA3.A3_COD = SCT.CT_VEND "
	cQra += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	cQra += "AND SA3.A3_XSEGEMP <> 'LL' "
	//cQra += "AND SCT.CT_REGIAO <> ' ' "
	cQra += "AND SCT.D_E_L_E_T_ = ' ' "
	cQra += "AND SCT.CT_DATA BETWEEN '" + dDataIni + "' AND '" + DTOS(dDtfin) + "' "
	//cQra += "AND SCT.CT_DATA BETWEEN '20130401' AND '20130430' "
	cQra += "AND SCT.CT_VEND NOT BETWEEN '001300' AND '001399' "
	cQra += "AND SCT.CT_FILIAL BETWEEN '  ' AND 'ZZ' "
	cQra += "GROUP BY A3_EST, SA3.A3_COD, SA3.A3_NREDUZ "
	cQra += "ORDER BY A3_EST, SA3.A3_COD "
	
	// tabela SA3 de vendedores e compartilhada
	// tabela SCT de metas exclusiva
	// foi usado group by por filial para futuras filiais somar as metas dos vendedores em todas as filiais
	
	cQra := ChangeQuery(cQra)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQra),'QRA', .F., .T.)
	
	
	Dbselectarea("QRA")
	Dbgotop()
	While !Eof()
		nPos := aScan(aMetaT,{|x| x[1] == QRA->A3_COD })
		If nPos == 0
			Aadd(aMetaT,{QRA->A3_COD,QRA->META,QRA->GRUPO,QRA->A3_NREDUZ,QRA->MTLIT})
			
		Else
			aMetaT[nPos,2] += QRA->META
			aMetaT[nPos,5] += QRA->MTLIT
		Endif
		Dbselectarea("QRA")
		Dbskip()
	Enddo
	IncProc("Metas ok")
	QRA->(dbCLoseArea())
	
	// Metas encerrado
	
	
	cMsg += chr(10)+chr(13)+" meta "+time()
	
	// Inicia Sql das vendas e monta matriz
	cQrb := ""
	cQrb += "SELECT SUM(SC6.C6_VALOR) AS VENDA,SC5.C5_VEND1, SUM(SC6.C6_QTDVEN * SB1.B1_QTELITS) AS LITVEN FROM "
	cQrb += RetSqlName("SC5") + " SC5, "
	cQrb += RetSqlName("SC6") + " SC6, "
	cQrb += RetSqlName("SF4") + " SF4, "
	cQrb += RetSqlName("SB1") + " SB1, "
	cQrb += RetSqlName("SA3") + " SA3 "
	cQrb += "WHERE SA3.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQrb += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQrb += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQrb += "AND SA3.A3_COD = SC5.C5_VEND1 "
	cQrb += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	//cQrb += "AND SB1.B1_GRUPO <> '1150' "
	//cQrb += "AND SB1.B1_PROC = '000468' "
	cQrb += "AND SB1.D_E_L_E_T_ = ' ' "
	cQrb += "AND SB1.B1_COD = SC6.C6_PRODUTO "
	cQrb += "AND SB1.B1_FILIAL = SC6.C6_FILIAL "
	cQrb += "AND SF4.F4_DUPLIC = 'S'
	cQrb += "AND SF4.D_E_L_E_T_ = ' ' "
	cQrb += "AND SF4.F4_CODIGO = SC6.C6_TES "
	cQrb += "AND SF4.F4_FILIAL = SC5.C5_FILIAL "
	cQrb += "AND SC6.D_E_L_E_T_ = ' ' "
	cQrb += "AND SC6.C6_NUM = SC5.C5_NUM "
	cQrb += "AND SC6.C6_FILIAL = SC5.C5_FILIAL  "
	cQrb += "AND SC5.C5_DTPROGM <= '" + DTOS(LastDay(dDataBase)) + "' "
	cQrb += "AND SC5.C5_VEND1 NOT BETWEEN '001300' AND '001399' "
	cQrb += "AND SC5.D_E_L_E_T_ = ' ' "
	cQrb += "AND SC5.C5_NUM BETWEEN ' ' AND 'ZZZZZZ' "
	cQrb += "AND SC5.C5_EMISSAO BETWEEN '" + dDataIni + "' AND '" + DTOS(dDataBase) + "' "
	cQrb += "AND SC5.C5_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQrb += "GROUP BY SC5.C5_VEND1 " //, SC5.C5_FILIAL
	
	// tabela SC5 exclusiva
	// tabela SC6 exclusiva
	// tabela SF4 exclusiva
	// agrupamento por filial para nao misturar pedidos e valores.
	
	cQrb  := ChangeQuery(cQrb)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrb),'QRB', .F., .T.)
	
	While !Eof()
		nPos := aScan(aVendidoT,{|x| x[1] == QRB->C5_VEND1 })
		If nPos == 0
			Aadd(aVendidoT,{QRB->C5_VEND1,QRB->VENDA,QRB->LITVEN})
		Else
			aVendidoT[nPos,2] += QRB->VENDA
			aVendidoT[nPos,3] += QRB->LITVEN
		Endif
		
		nPos := aScan(aMetaT,{|x| x[1] == QRB->C5_VEND1 })
		If nPos == 0
			Posicione("SA3",1,xFilial("SA3")+QRB->C5_VEND1,"A3_COD")
			Aadd(aMetaT,{QRB->C5_VEND1,0,SA3->A3_EST,SA3->A3_NREDUZ,0})
		Endif
		
		Dbselectarea("QRB")
		Dbskip()
	Enddo
	
	QRB->(dbCLoseArea())
	IncProc("Vendas ok")
	
	// Vendas encerrado
	
	cMsg += chr(10)+chr(13)+" venda "+time()
	
	// Inicia Sql da pendencia e monta matriz
	cQrc := ""
	cQrc += "SELECT SUM((SC6.C6_QTDVEN - SC6.C6_QTDENT)*SC6.C6_PRCVEN) AS PENDF, SUM((SC6.C6_QTDVEN - SC6.C6_QTDENT)*SB1.B1_QTELITS) AS LITPEN, SC5.C5_VEND1 FROM "
	cQrc += RetSqlName("SC5") + " SC5, "
	cQrc += RetSqlName("SC6") + " SC6, "
	cQrc += RetSqlName("SF4") + " SF4, "
	cQrc += RetSqlName("SB1") + " SB1, "
	cQrc += RetSqlName("SA3") + " SA3 "
	cQrc += "WHERE SA3.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQrc += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQrc += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQrc += "AND SA3.A3_COD = SC5.C5_VEND1 "
	cQrc += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	cQrc += "AND SB1.D_E_L_E_T_ = ' ' "
	cQrc += "AND SB1.B1_COD = SC6.C6_PRODUTO "
	cQrc += "AND SB1.B1_FILIAL = SC6.C6_FILIAL "
	cQrc += "AND SF4.F4_DUPLIC = 'S' "
	cQrc += "AND SF4.D_E_L_E_T_ = ' ' "
	cQrc += "AND SF4.F4_CODIGO = SC6.C6_TES "
	cQrc += "AND SF4.F4_FILIAL = SC5.C5_FILIAL "
	cQrc += "AND SC6.C6_QTDENT < SC6.C6_QTDVEN "
	cQrc += "AND SC6.C6_BLQ <> 'R' "
	cQrc += "AND SC6.D_E_L_E_T_ = ' ' "
	cQrc += "AND SC6.C6_PRODUTO BETWEEN ' ' AND 'ZZZZZZZZZZZZZZ' "
	cQrc += "AND SC6.C6_ITEM BETWEEN ' ' AND 'ZZ' "
	cQrc += "AND SC6.C6_NUM = SC5.C5_NUM "
	cQrc += "AND SC6.C6_FILIAL = SC5.C5_FILIAL "
	cQrc += "AND SC5.C5_VEND1 NOT BETWEEN '001300' AND '001399' "
	cQrc += "AND SC5.C5_TIPO = 'N' "
	cQrc += "AND SC5.C5_DTPROGM <= '" + DTOS(LastDay(dDataBase)) + "' "
	cQrc += "AND SC5.D_E_L_E_T_ = ' ' "
	cQrc += "AND SC5.C5_NUM BETWEEN ' ' AND 'ZZZZZZ' "
	cQrc += "AND SC5.C5_EMISSAO BETWEEN '" + DTOS(dDataBase - 180) + "' AND '" + DTOS(dDataBase) + "' "
	cQrc += "AND SC5.C5_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQrc += "GROUP BY SC5.C5_VEND1 " //,SC5.C5_FILIAL
	
	// tabela SC5 exclusiva
	// tabela SC6 exclusiva
	// tabela SF4 exclusiva
	// agrupamento por filial para nao misturar pedidos e valores.
	
	cQrc  := ChangeQuery(cQrc)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrc),'QRC', .F., .T.)
	
	While !Eof()
		nPos := aScan(aPendenteT,{|x| x[1] == QRC->C5_VEND1 })
		If nPos == 0
			Aadd(aPendenteT,{QRC->C5_VEND1,QRC->PENDF,QRC->LITPEN,0,0})
		Else
			aPendenteT[nPos,2] += QRC->PENDF
			aPendenteT[nPos,3] += QRC->LITPEN
		Endif
		
		nPos := aScan(aMetaT,{|x| x[1] == QRC->C5_VEND1 })
		If nPos == 0
			Posicione("SA3",1,xFilial("SA3")+QRC->C5_VEND1,"A3_COD")
			Aadd(aMetaT,{SA3->A3_COD,0,SA3->A3_EST,SA3->A3_NREDUZ,0})
		Endif
		
		Dbselectarea("QRC")
		Dbskip()
	Enddo
	
	QRC->(dbCloseArea())
	
	cQrx := ""
	cQrx += "SELECT SUM(C9_QTDLIB*C9_PRCVEN) AS PENDF,"
	cQrx += "       SUM(C9_QTDLIB * B1_QTELITS) AS LITPEN,"
	cQrx += "       C5_VEND1 "
	cQrx += "  FROM " +RetSqlName("SC5") + " SC5," +RetSqlName("SC6") + " SC6, "+ RetSqlName("SF4") + " SF4, "
	cQrx +=           RetSqlName("SB1") + " SB1, "+ RetSqlName("SA3") + " SA3, "+RetSqlName("SC9") + " C9 "
	cQrx += " WHERE SA3.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQrx += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQrx += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQrx += "AND SA3.A3_COD = SC5.C5_VEND1 "
	cQrx += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	//cQrx += "   AND SB1.B1_PROC = '000468' "
	cQrx += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQrx += "   AND SB1.B1_COD = SC6.C6_PRODUTO "
	cQrx += "   AND SB1.B1_FILIAL = SC6.C6_FILIAL "
	cQrx += "   AND SF4.F4_DUPLIC = 'S' "
	cQrx += "   AND SF4.D_E_L_E_T_ = ' ' "
	cQrx += "   AND SF4.F4_CODIGO = SC6.C6_TES "
	cQrx += "   AND SF4.F4_FILIAL = SC5.C5_FILIAL "
	cQrx += "   AND SC6.D_E_L_E_T_ = ' ' "
	cQrx += "   AND C6_ITEM = C9_ITEM "
	cQrx += "   AND SC6.C6_NUM = SC5.C5_NUM "
	cQrx += "   AND SC6.C6_FILIAL = SC5.C5_FILIAL "
	cQrx += "   AND C9.D_E_L_E_T_ =' ' "
	cQrx += "   AND C9_BLEST = '  ' "
	cQrx += "   AND C9_FLGENVI !=' ' "
	cQrx += "   AND C9_PEDIDO = C5_NUM "
	cQrx += "   AND C9_FILIAL = C5_FILIAL "
	cQrx += "   AND SC5.C5_TIPO = 'N' "
	cQrx += "   AND SC5.C5_VEND1 NOT BETWEEN '001300' AND '001399' "
	cQrx += "   AND SC5.C5_DTPROGM <= '" + DTOS(LastDay(dDataBase)) + "' "
	cQrx += "   AND SC5.D_E_L_E_T_ = ' ' "
	cQrx += "   AND SC5.C5_EMISSAO BETWEEN '" + DTOS(dDataBase - 180) + "' AND '" + DTOS(dDataBase) + "' "
	cQrx += "   AND SC5.C5_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQrx += " GROUP BY SC5.C5_VEND1 " //,SC5.C5_FILIAL
	
	cQrx  := ChangeQuery(cQrx)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrx),'QRX', .F., .T.)
	
	While !Eof()
		nPos := aScan(aPendenteT,{|x| x[1] == QRX->C5_VEND1 })
		If nPos == 0
			Aadd(aPendenteT,{QRX->C5_VEND1,0,0,QRX->PENDF,QRX->LITPEN})
		Else
			aPendenteT[nPos,4] += QRX->PENDF
			aPendenteT[nPos,5] += QRX->LITPEN
		Endif
		
		nPos := aScan(aMetaT,{|x| x[1] == QRX->C5_VEND1 })
		If nPos == 0
			Posicione("SA3",1,xFilial("SA3")+QRX->C5_VEND1,"A3_COD")
			Aadd(aMetaT,{SA3->A3_COD,0,SA3->A3_EST,SA3->A3_NREDUZ,0})
		Endif
		
		Dbselectarea("QRX")
		Dbskip()
	Enddo
	QRX->(dbCloseArea())
	IncProc("Pendencia ok")
	// finaliza pendencia
	
	cMsg += chr(10)+chr(13)+" pendencia "+time()
	
	// Inicia Sql do eliminado e monta matriz
	cQrd := ""
	cQrd += "SELECT SUM((SC6.C6_QTDVEN - SC6.C6_QTDENT)* SC6.C6_PRCVEN) AS ELIM, SUM((SC6.C6_QTDVEN - SC6.C6_QTDENT) * SB1.B1_QTELITS) AS LITELIM, SC5.C5_VEND1 FROM "
	cQrd += RetSqlName("SC5") + " SC5, "
	cQrd += RetSqlName("SC6") + " SC6, "
	cQrd += RetSqlName("SF4") + " SF4, "
	cQrd += RetSqlName("SB1") + " SB1, "
	cQrd += RetSqlName("SA3") + " SA3 "
	cQrd += "WHERE SA3.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQrd += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQrd += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQrd += "AND SA3.A3_COD = SC5.C5_VEND1 "
	cQrd += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	//cQrd += "AND SB1.B1_GRUPO <> '1150' "
	//cQrd += "AND SB1.B1_PROC = '000468' "
	cQrd += "AND SB1.D_E_L_E_T_ = ' ' "
	cQrd += "AND SB1.B1_COD = SC6.C6_PRODUTO "
	cQrd += "AND SB1.B1_FILIAL = SC6.C6_FILIAL "
	cQrd += "AND SF4.F4_DUPLIC = 'S' "
	cQrd += "AND SF4.D_E_L_E_T_ = ' ' "
	cQrd += "AND SF4.F4_CODIGO = SC6.C6_TES "
	cQrd += "AND SF4.F4_FILIAL = SC6.C6_FILIAL "
	cQrd += "AND SC6.C6_BLQ = 'R' "
	cQrd += "AND SC6.D_E_L_E_T_ = ' ' "
	cQrd += "AND SC6.C6_PRODUTO BETWEEN ' ' AND 'ZZZZZZZZZZZZZZ' "
	cQrd += "AND SC6.C6_ITEM BETWEEN ' ' AND 'ZZ' "
	cQrd += "AND SC6.C6_NUM = SC5.C5_NUM "
	cQrd += "AND SC6.C6_FILIAL = SC5.C5_FILIAL "
	cQrd += "AND SC5.C5_VEND1 NOT BETWEEN '001300' AND '001399' "
	cQrd += "AND SC5.C5_TIPO = 'N' "
	//cQrb += "AND SC5.C5_CLIENTE <> '258928' "
	cQrd += "AND SC5.D_E_L_E_T_ = ' ' "
	cQrd += "AND SC5.C5_NUM BETWEEN ' ' AND 'ZZZZZZ' "
	cQrd += "AND SC5.C5_EMISSAO BETWEEN '" + dDataIni + "' AND '" + DTOS(dDataBase) + "' "
	//cQrd += "AND SC5.C5_EMISSAO BETWEEN '20130401' AND '20130430' "
	cQrd += "AND SC5.C5_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQrd += "GROUP BY SC5.C5_VEND1 "   //,SC5.C5_FILIAL
	
	// tabela SC5 exclusiva
	// tabela SC6 exclusiva
	// tabela SF4 exclusiva
	// agrupamento por filial para nao misturar pedidos e valores.
	
	cQrd  := ChangeQuery(cQrd)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrd),'QRD', .F., .T.)
	
	While !Eof()
		nPos := aScan(aEliminaT,{|x| x[1] == QRD->C5_VEND1 })
		If nPos == 0
			Aadd(aEliminaT,{QRD->C5_VEND1,QRD->ELIM,QRD->LITELIM})
		Else
			aEliminaT[nPos,2] += QRD->ELIM
			aEliminaT[nPos,3] += QRD->LITELIM
		Endif
		
		nPos := aScan(aMetaT,{|x| x[1] == QRD->C5_VEND1 })
		If nPos == 0
			Posicione("SA3",1,xFilial("SA3")+QRD->C5_VEND1,"A3_COD")
			Aadd(aMetaT,{SA3->A3_COD,0,SA3->A3_EST,SA3->A3_NREDUZ,0})
		Endif
		
		Dbselectarea("QRD")
		Dbskip()
	Enddo
	
	QRD->(dbClosearea())
	IncProc("Residuo ok")
	
	//Finaliza eliminado
	
	cMsg += chr(10)+chr(13)+" eliminado "+time()
	
	// Inicia Sql faturado e monta matriz
	
	cQre := ""
	cQre += "SELECT SUM(SD2.D2_TOTAL) AS FATURADO, COUNT(DISTINCT(SD2.D2_CLIENTE||SD2.D2_LOJA))AS NCLIF , "
	cQre +=	"SUM((SD2.D2_QUANT * SB1.B1_PRMINFO)+SD2.D2_CUSTO1+SD2.D2_XCUSTO+SD2.D2_XVALPAG+SD2.D2_VALICM+D2_ICMSCOM+D2_DIFAL+SD2.D2_VALIMP5+SD2.D2_VALPROM+SD2.D2_VALIMP6+(SD2.D2_TOTAL*("+ Alltrim(Str(U_BFFATM02())) +")/100)) AS CUSTO, "
	cQre +=	"SUM((SD2.D2_QUANT * SB1.B1_PRMINFO)+SD2.D2_CUSTO1+SD2.D2_XCUSTO+SD2.D2_VALICM+D2_ICMSCOM+D2_DIFAL+SD2.D2_VALIMP5+SD2.D2_VALIMP6) AS CUSTO2, "
	cQre += "SF2.F2_VEND1, SD2.D2_FILIAL, SUM(SD2.D2_QUANT * SB1.B1_QTELITS) AS LITROS FROM "
	cQre += RetSqlName("SD2") + " SD2, "
	cQre += RetSqlName("SF2") + " SF2, "
	cQre += RetSqlName("SF4") + " SF4, "
	cQre += RetSqlName("SB1") + " SB1, "
	cQre += RetSqlName("SA1") + " SA1, "
	cQre += RetSqlName("SA3") + " SA3 "
	cQre += "WHERE SA3.D_E_L_E_T_ = ' ' "
	cQre += "AND SA3.A3_COD = SF2.F2_VEND1 "
	cQre += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	cQre += "AND SA1.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQre += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQre += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQre += "AND SA1.A1_LOJA = SD2.D2_LOJA "
	cQre += "AND SA1.A1_COD = SD2.D2_CLIENTE "
	cQre += "AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
	//cQre += "AND SB1.B1_GRUPO <> '1150' "
	//cQre += "AND SB1.B1_PROC = '000468' "
	cQre += "AND SB1.D_E_L_E_T_ = ' ' "
	cQre += "AND SB1.B1_COD = SD2.D2_COD "
	cQre += "AND SB1.B1_FILIAL = SD2.D2_FILIAL "
	cQre += "AND SF4.F4_DUPLIC = 'S'"
	cQre += "AND SF4.D_E_L_E_T_ = ' ' "
	cQre += "AND SF4.F4_CODIGO = SD2.D2_TES "
	cQre += "AND SF4.F4_FILIAL = SD2.D2_FILIAL  "
	cQre += "AND SD2.D_E_L_E_T_ = ' ' "
	cQre += "AND SD2.D2_EMISSAO = SF2.F2_EMISSAO "
	cQre += "AND SD2.D2_SERIE = SF2.F2_SERIE "
	cQre += "AND SD2.D2_DOC = SF2.F2_DOC "
	cQre += "AND SD2.D2_LOJA = SF2.F2_LOJA "
	cQre += "AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
	cQre += "AND SD2.D2_FILIAL = SF2.F2_FILIAL "
	cQre += "AND SF2.F2_VEND1 NOT BETWEEN '001300' AND '001399' "
	cQre += "AND SF2.D_E_L_E_T_ = ' ' "
	cQre += "AND SF2.F2_SERIE IN ('1','2','3') "
	cQre += "AND SF2.F2_EMISSAO BETWEEN '" + dDataIni + "' AND '" + DTOS(dDataBase) + "' "
	//cQre += "AND SF2.F2_EMISSAO BETWEEN '20130401' AND '20130430' "
	cQre += "AND SF2.F2_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQre += "GROUP BY SF2.F2_VEND1, SD2.D2_FILIAL "   //
	
	// tabela SD2 exclusiva
	// tabela SF2 exclusiva
	// tabela SF4 exclusiva
	// tabela SB1 compartilhada
	// tabela SA1 compartilhada
	
	
	cQre  := ChangeQuery(cQre)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQre),'QRE', .F., .T.)
	
	While !Eof()
		nPos := aScan(aFaturadoT,{|x| x[1] == QRE->F2_VEND1 })
		If nPos == 0
			Aadd(aFaturadoT,{QRE->F2_VEND1,QRE->FATURADO,QRE->CUSTO,QRE->NCLIF,QRE->LITROS,QRE->CUSTO2})
		Else
			aFaturadoT[nPos,2] += QRE->FATURADO
			aFaturadoT[nPos,3] += QRE->CUSTO
			aFaturadoT[nPos,4] += QRE->NCLIF
			aFaturadoT[nPos,5] += QRE->LITROS
			aFaturadoT[nPos,6] += QRE->CUSTO2
		Endif
		
		nPos := aScan(aMetaT,{|x| x[1] == QRE->F2_VEND1 })
		If nPos == 0
			Posicione("SA3",1,xFilial("SA3")+QRE->F2_VEND1,"A3_COD")
			Aadd(aMetaT,{SA3->A3_COD,0,SA3->A3_EST,SA3->A3_NREDUZ,0})
		Endif
		
		Dbselectarea("QRE")
		Dbskip()
	Enddo
	
	QRE->(dbClosearea())
	IncProc("Faturamento ok")
	// Encerrado faturado
	
	
	cQrp := ""
	cQrp += "SELECT (SUM(SF2.F2_VALFAT * SE4.E4_PRZMEDI)) AS PRAZO, SUM(SF2.F2_VALFAT) AS VFATU, SF2.F2_VEND1, "
	cQrp += "SUM(CASE WHEN D2_XISPRTB = '0' THEN (D2_QUANT * (D2_PRUNIT - D2_PRCVEN)) ELSE 0 END) AS DESCONTO, SUM(CASE WHEN D2_XISPRTB = '0' THEN (D2_QUANT * D2_PRUNIT) ELSE 0 END) AS FATBRU FROM "
	cQrp += RetSqlName("SD2") + " SD2, "
	cQrp += RetSqlName("SF2") + " SF2, "
	cQrp += RetSqlName("SF4") + " SF4, "
	cQrp += RetSqlName("SB1") + " SB1, "
	cQrp += RetSqlName("SE4") + " SE4, "
	cQrp += RetSqlName("SA3") + " SA3 "
	cQrp += "WHERE SA3.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQrp += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQrp += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQrp += "AND SA3.A3_COD = SF2.F2_VEND1 "
	cQrp += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	cQrp += "AND SE4.D_E_L_E_T_ = ' ' "
	cQrp += "AND SE4.E4_CODIGO = SF2.F2_COND "
	//cQrp += "AND SB1.B1_GRUPO <> '1150' "
	//cQrp += "AND SB1.B1_PROC = '000468'  "
	cQrp += "AND SB1.D_E_L_E_T_ = ' ' "
	cQrp += "AND SB1.B1_COD = SD2.D2_COD "
	cQrp += "AND SB1.B1_FILIAL = SD2.D2_FILIAL "
	cQrp += "AND SF4.F4_DUPLIC = 'S'"
	cQrp += "AND SF4.D_E_L_E_T_ = ' ' "
	cQrp += "AND SF4.F4_CODIGO = SD2.D2_TES "
	cQrp += "AND SF4.F4_FILIAL = SD2.D2_FILIAL  "
	cQrp += "AND SD2.D_E_L_E_T_ = ' ' "
	cQrp += "AND SD2.D2_EMISSAO = SF2.F2_EMISSAO "
	cQrp += "AND SD2.D2_SERIE = SF2.F2_SERIE "
	cQrp += "AND SD2.D2_DOC = SF2.F2_DOC "
	cQrp += "AND SD2.D2_LOJA = SF2.F2_LOJA "
	cQrp += "AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
	cQrp += "AND SD2.D2_FILIAL = SF2.F2_FILIAL "
	cQrp += "AND SF2.F2_VEND1 NOT BETWEEN '001300' AND '001399' "
	cQrp += "AND SF2.D_E_L_E_T_ = ' ' "
	cQrp += "AND SF2.F2_SERIE IN ('1','2','3') "
	cQrp += "AND SF2.F2_EMISSAO BETWEEN '" + dDataIni + "' AND '" + DTOS(dDataBase) + "' "
	//cQrp += "AND SF2.F2_EMISSAO BETWEEN '20130401' AND '20130430' "
	cQrp += "AND SF2.F2_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQrp += "GROUP BY SF2.F2_VEND1 "  //,SF2.F2_FILIAL
	
	cQrp  := ChangeQuery(cQrp)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrp),'QRP', .F., .T.)
	
	While !Eof()
		nPos := aScan(aPrazoT,{|x| x[1] == QRP->F2_VEND1 })
		If nPos == 0
			Aadd(aPrazoT,{QRP->F2_VEND1,QRP->PRAZO,QRP->VFATU,QRP->DESCONTO,QRP->FATBRU})
		Else
			aPrazoT[nPos,2] += QRP->PRAZO
			aPrazoT[nPos,3] += QRP->VFATU
			aPrazoT[nPos,4] += QRP->DESCONTO
			aPrazoT[nPos,5] += QRP->FATBRU
		Endif
		
		nPos := aScan(aMetaT,{|x| x[1] == QRP->F2_VEND1})
		If nPos == 0
			Posicione("SA1",1,xFilial("SA3")+QRP->F2_VEND1,"A3_COD")
			Aadd(aMetaT,{SA3->A3_COD,0,SA3->A3_EST,SA3->A3_NREDUZ,0})
		Endif
		
		Dbselectarea("QRP")
		Dbskip()
	Enddo
	
	QRP->(dbClosearea())
	IncProc("Prazo ok")
	
	
	cMsg += chr(10)+chr(13)+" faturado "+time()
	
	// Inicia Sql das devolucoes e monta matriz
	
	cQrf := ""
	cQrf += "SELECT SUM(SD1.D1_TOTAL - SD1.D1_VALDESC) AS DEVOLVIDO, SUM(SD1.D1_QUANT * SB1.B1_QTELITS) AS LITDEV, "
	cQrf += "COUNT(DISTINCT(SD1.D1_DOC||SD1.D1_SERIE)) AS NDEV,SF2.F2_VEND1 FROM "
	cQrf += RetSqlName("SD1") + " SD1, "
	cQrf += RetSqlName("SF4") + " SF4, "
	cQrf += RetSqlName("SF2") + " SF2, "
	cQrf += RetSqlName("SB1") + " SB1, "
	cQrf += RetSqlName("SA3") + " SA3 "
	cQrf += "WHERE SA3.D_E_L_E_T_ = ' ' "
	If SM0->M0_CODIGO == '02'
		cQrf += "AND SA3.A3_GEREN = '000900' "
	ELSE
		cQrf += "AND SA3.A3_GEREN = '000400' "
	Endif
	cQrf += "AND SA3.A3_COD = SF2.F2_VEND1 "
	cQrf += "AND SA3.A3_FILIAL BETWEEN ' ' AND 'ZZ' "
	//cQrf += "AND SB1.B1_GRUPO <> '1150' "
	//cQrf += "AND SB1.B1_PROC = '000468' "
	cQrf += "AND SB1.D_E_L_E_T_ = ' ' "
	cQrf += "AND SB1.B1_COD = SD1.D1_COD "
	cQrf += "AND SB1.B1_FILIAL = SD1.D1_FILIAL "
	cQrf += "AND SF2.F2_VEND1 NOT BETWEEN '001300' AND '001399' "
	cQrf += "AND SF2.D_E_L_E_T_ = ' ' "
	cQrf += "AND SF2.F2_SERIE = SD1.D1_SERIORI "
	cQrf += "AND SF2.F2_DOC = SD1.D1_NFORI "
	cQrf += "AND SF2.F2_LOJA = SD1.D1_LOJA "
	cQrf += "AND SF2.F2_CLIENTE = SD1.D1_FORNECE "
	cQrf += "AND SF2.F2_FILIAL = SD1.D1_FILIAL  "
	cQrf += "AND SF4.F4_DUPLIC <> 'R' "
	cQrf += "AND SF4.F4_ESTOQUE = 'S' "
	cQrf += "AND SF4.D_E_L_E_T_ = ' ' "
	cQrf += "AND SF4.F4_CODIGO = SD1.D1_TES "
	cQrf += "AND SF4.F4_FILIAL = SD1.D1_FILIAL  "
	cQrf += "AND SD1.D1_TIPO = 'D' "
	cQrf += "AND SD1.D1_TES NOT IN ('194','482','229','292','489') "
	//cQrf += "AND SD1.D1_FORNECE <> '258928' "
	cQrf += "AND SD1.D_E_L_E_T_ = ' ' "
	cQrf += "AND SD1.D1_NUMSEQ BETWEEN ' ' AND 'ZZ' "
	cQrf += "AND SD1.D1_DTDIGIT BETWEEN '" + dDataIni + "' AND '" + DTOS(dDataBase) + "' "
	//cQrf += "AND SD1.D1_DTDIGIT BETWEEN '20130401' AND '20130430' "
	cQrf += "AND SD1.D1_FILIAL IN "+FormatIN(GetMv("BF_FILIAIS"),"/")
	cQrf += "GROUP BY SF2.F2_VEND1 "           //,SD1.D1_FILIAL
	
	// tabela SD1 exclusiva
	// tabela SF2 exclusiva
	
	cQrf  := ChangeQuery(cQrf)
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrf),'QRF', .F., .T.)
	
	Dbselectarea("QRF")
	Dbgotop()
	While !Eof()
		nPos := aScan(aDevolviT,{|x| x[1] == QRF->F2_VEND1 })
		If nPos == 0
			Aadd(aDevolviT,{QRF->F2_VEND1,QRF->DEVOLVIDO,QRF->NDEV,QRF->LITDEV})
		Else
			aDevolviT[nPos,2] += QRF->DEVOLVIDO
			aDevolviT[nPos,3] += QRF->NDEV
			aDevolviT[nPos,4] += QRF->LITDEV
		Endif
		
		nPos := aScan(aMetaT,{|x| x[1] == QRF->F2_VEND1})
		If nPos == 0
			Posicione("SA1",1,xFilial("SA3")+QRF->F2_VEND1,"A3_COD")
			Aadd(aMetaT,{SA3->A3_COD,0,SA3->A3_EST,SA3->A3_NREDUZ,0})
		Endif
		
		
		Dbselectarea("QRF")
		Dbskip()
	Enddo
	
	QRF->(dbClosearea())
	IncProc("Devolucao ok")
	
	// Encerrado devolucoes
	
	cMsg += chr(10)+chr(13)+" devolvido "+time()
	
	For ny := 1 to len(aMetaT)
		Aadd(aMeta,aMetaT[ny])
	Next
	For ny := 1 to len(aMetaUFT)
		Aadd(aMetaUF,aMetaUFT[ny])
	Next
	For ny := 1 to len(aFaturadoT)
		Aadd(aFaturado,aFaturadoT[ny])
	Next
	For ny := 1 to len(aPrazoT)
		Aadd(aPrazo,aPrazoT[ny])
	Next
	For ny := 1 to len(aEliminaT)
		Aadd(aElimina,aEliminaT[ny])
	Next
	For ny := 1 to len(aVendidoT)
		Aadd(aVendido,aVendidoT[ny])
	Next
	For ny := 1 to len(aDevolviT)
		Aadd(aDevolvi,aDevolviT[ny])
	Next
	For ny := 1 to len(aPendenteT)
		Aadd(aPendente,aPendenteT[ny])
	Next
	
	aMetaT 		:= {}
	aMetaUFT 		:= {}
	aFaturadoT 	:= {}
	aPrazoT 		:= {}
	aEliminaT 		:= {}
	aVendidoT 		:= {}
	aDevolviT 		:= {}
	aPendenteT 	:= {}
	
Return

//+==========================================+++++++++++++++++++++++=============================++++++++++++++++++++++++++++===================++++++++++++++++++++======================+++++++++++++++++

/*/{Protheus.doc} stMontaWF
(long_description)
@author MarceloLauschner
@since 08/07/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stMontaWF()
	Local	y,x
	
	cMes := DataMapa(dDatabase, 'M')
	
	aFeriados := {}
	nDiasp   := 0
	nDiasf   := 0
	nFalt    := 0
	lFeriado := .F.
	nPass := 0
	
	// Inicia processa para verificar a quantidade de dias uteis restantes no mes
	
	
	
	Dbselectarea("SP3")
	Dbsetorder(1)
	Dbgotop()
	While !Eof()
		If SP3->P3_FIXO == 'S'
			aadd(aFeriados,{Substr(DTOS(SP3->P3_DATA),5,4)})
		Else
			If Substr(DTOS(SP3->P3_DATA),1,6) == Substr(DTOS(dDatabase),1,6)
				aadd(aFeriados,{Substr(DTOS(SP3->P3_DATA),5,4)})
			Endif
		Endif
		Dbselectarea("SP3")
		Dbskip()
	Enddo
	
	nDiasf := dDtfin - dDataBase
	
	For x := 1 To nDiasf
		If dDtini < dDtfin
			dDtini += 1
			If Dow(dDtini) < 7 .and. Dow(dDtini) > 1
				For y := 1 To Len(aFeriados)
					If Substr(DTOS(dDtini),5,4) == aFeriados[y][1]
						lFeriado := .T.
						Exit
					Endif
				Next
				If Empty(lFeriado)
					nFalt += 1
				Endif
				lFeriado := .F.
			Endif
		Endif
	Next
	
	lFeriado := .F.
	nDiasp := dDataBase - dDtPriDia
	
	For x := 1 To nDiasp
		If dDtPriDia < dDataBase
			dDtPriDia += 1
			If Dow(dDtPriDia) < 7 .and. Dow(dDtPriDia) > 1
				For y := 1 To Len(aFeriados)
					If Substr(DTOS(dDtPriDia),5,4) == aFeriados[y][1]
						lFeriado := .T.
						Exit
					Endif
				Next
				If Empty(lFeriado)
					nPass += 1
				Endif
				lFeriado := .F.
			Endif
		Endif
	Next
	
	// Finaliza processo de dias uteis restantes
	
	// Cria um novo processo...
	cProcess := "100002"
	cStatus  := "100002"
	oProcess := TWFProcess():New(cProcess,OemToAnsi("Envio diário do Mapa de Vendas Industrial"))
	//Abre o HTML criado
	oProcess:NewTask(cStatus,"\WORKFLOW\mapa_BF_ind.HTM")
	oProcess:cSubject := "Mapa de Vendas Industrial - BigForta " + cMes
	oProcess:bReturn  := ""
	oHTML := oProcess:oHTML
	nTotal := 0
	cReg  := space(3)
	
	// declara variaveis locais usadas no workflow
	
	cRegiao := ""
	cGrupo  := ""
	nMeta 	:= 0.00
	nMtLit  := 0.00
	nVend 	:= 0.00
	nLitVen := 0.00
	nPend	:= 0.00
	nLitPen := 0.00
	nPendX	:= 0.00
	nLPenX 	:= 0.00
	nElim 	:= 0.00
	nLElim 	:= 0.00
	nFatu 	:= 0.00
	nLitr   := 0.00
	nPrazo  := 0.00
	nFatpr  := 0.00
	nCust	:= 0.00
	nCust2	:= 0.00
	nClie	:= 0
	nDevo	:= 0.00
	nNdev	:= 0
	nLitDevo := 0.00
	nDescon := 0.00
	nFatBru := 0.00
	
	
	
	
	aSort(aMeta,,,{|x,y| x[3]+x[1] < y[3]+y[1]})
	
	For x := 1 To Len(aMeta)
		
		If aMeta[x,3] <> cGrupo .AND. x <> 1
			
			AAdd((oHtml:ValByName("l.vend" )),'<u><font color=#FF0000 >'+"Total-> "+cGrupo+'</font></u>')
			AAdd((oHtml:ValByName("l.meta" )),'<u><font color=#FF0000 >'+transform(nMeta,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.mtlit" )),'<u><font color=#FF0000 >'+transform(nMtLit,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.vendid" )),'<u><font color=#FF0000 >'+transform(nVend,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.litven" )),'<u><font color=#FF0000 >'+transform(nLitVen,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.rsl" )),'<u><font color=#FF0000 >'+transform(nVend/nLitVen,"@E 999,999.99")+'</font></u>')
			AAdd((oHtml:ValByName("l.liqmli" )),'<u><font color=#FF0000 >'+transform(((nLitVen)/(nMtLit/(nFalt+nPass)*nPass))*100,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.pend" )),'<u><font color=#FF0000 >'+transform(nPend-nPendX,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.litpen" )),'<u><font color=#FF0000 >'+transform(nLitPen-nLPenX,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.pendX" )),'<u><font color=#FF0000 >'+transform(nPendX,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.lpenX" )),'<u><font color=#FF0000 >'+transform(nLPenX,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.elim" )),'<u><font color=#FF0000 >'+transform(nElim,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.lelim" )),'<u><font color=#FF0000 >'+transform(nLElim,"@E 999,999,999")+'</font></u>')
			//AAdd((oHtml:ValByName("l.fatb" )),'<u><font color=#FF0000 >'+transform(nFatu,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.prazo" )),'<u><font color=#FF0000 >'+transform(nPrazo/nFatpr,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.cliat" )),'<u><font color=#FF0000 >'+transform(nClie,"@E 99999")+'</font></u>')
			AAdd((oHtml:ValByName("l.dev" )),'<u><font color=#FF0000 >'+transform(nDevo,"@E 999,999,999")+'</font></u>')
			//AAdd((oHtml:ValByName("l.litdev" )),'<u><font color=#FF0000 >'+transform(nLitDevo,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.ndev" )),'<u><font color=#FF0000 >'+transform(nNdev,"@E 9,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.litli" )),'<u><font color=#FF0000 >'+transform(nLitr - nLitDevo,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.fatli" )),'<u><font color=#FF0000 >'+transform(nFatu - nDevo,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.liqmet" )),'<u><font color=#FF0000 >'+transform(((nFatu - nDevo)/(nMeta))*100,"@E 999,999,999")+'</font></u>')
			//AAdd((oHtml:ValByName("l.liqmet" )),'<u><font color=#FF0000 >'+transform(((nFatu - nDevo)/(nMeta/(nPass+nFalt)*nPass))*100,"@E 999,999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.mtd" )),'<u><font color=#FF0000 >'+transform((nMtLit - nLitVen)/nFalt,"@E 999,999")+'</font></u>')
			AAdd((oHtml:ValByName("l.mg2" )),'<u><font color=#FF0000 >'+transform(nDescon/nFatBru*100,"@E 9,999.9")+'</font></u>')
			//AAdd((oHtml:ValByName("l.mb1" )),'<u><font color=#FF0000 >'+transform((nFatu - nCust2)/nFatu*100,"@E 9,999.9")+'</font></u>')
			//AAdd((oHtml:ValByName("l.mg2" )),'<u><font color=#FF0000 >'+transform((100-U_BFFATM02()-GetNewPar("BF_ACR_IR",2)) + (nFatu - (nCust+nFatu*((1.00066030548229^(nPrazo/nFatpr))-1)))/nFatu*100,"@E 9,999.9")+'</font></u>')
			//			AAdd((oHtml:ValByName("l.mgvl" )),'<u><font color=#FF0000 >'+transform((nFatu - (nCust+nFatu*((1.00066030548229^(nPrazo/nFatpr))-1))),"@E 999,999,999")+'</font></u>')
			// zera variaveis para o proximo subtotal por tmk
			nMeta 	:= 0.00
			nMtLit  := 0.00
			nVend 	:= 0.00
			nLitVen := 0.00
			nPend	:= 0.00
			nLitPen := 0.00
			nPendX	:= 0.00
			nLPenX 	:= 0.00
			nElim 	:= 0.00
			nLElim 	:= 0.00
			nFatu 	:= 0.00
			nLitr  := 0.00
			nPrazo  := 0.00
			nFatpr  := 0.00
			nDescon := 0.00
			nFatBru := 0.00
			nCust	:= 0.00
			nCust2  := 0.00
			nClie	:= 0
			nDevo	:= 0.00
			nNdev	:= 0
			nLitDevo := 0.00
		Endif
		
		AAdd((oHtml:ValByName("l.vend" )),SUBSTR(aMeta[x,1],3,4)+"-"+aMeta[x,4])   				// Código vendedor e nome
		AAdd((oHtml:ValByName("l.meta" )),transform(aMeta[x,2],"@E 999,999,999"))              // Meta
		AAdd((oHtml:ValByName("l.mtlit" )),transform(aMeta[x,5],"@E 999,999,999"))              // Meta Litros
		nMeta += aMeta[x,2] // soma variavel de metas
		nMtLit += aMeta[x,5] // soma variavel de metas litros
		
		// Localiza vendido do vendedor em cursor
		nPosVend := aScan(aVendido,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If nPosVend == 0
			AAdd((oHtml:ValByName("l.vendid" )), 0.00 )
			AAdd((oHtml:ValByName("l.litven" )), 0.00 )
			AAdd((oHtml:ValByName("l.liqmli" )), 0.00 )
			AAdd((oHtml:ValByName("l.mtd" )), 0.00 )
			AAdd((oHtml:ValByName("l.rsl" )), 0.00 )
		Else
			AAdd((oHtml:ValByName("l.vendid" )),transform(aVendido[nPosVend,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.litven" )),transform(aVendido[nPosVend,3],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.liqmli" )),transform(((aVendido[nPosVend,3])/(aMeta[x,5]))*100,"@E 999,999,999"))
			//AAdd((oHtml:ValByName("l.liqmli" )),transform(((aVendido[nPosVend,3])/(aMeta[x,5]/(nPass+nFalt)*nPass))*100,"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.mtd" )),transform((aMeta[x,5] - aVendido[nPosVend,3])/nFalt,"@E 999,999"))
			AAdd((oHtml:ValByName("l.rsl" )),transform(aVendido[nPosVend,2]/aVendido[nPosVend,3],"@E 999,999.99"))
			nVend += aVendido[nPosVend,2] // soma variavel de vendido
			nLitVen += aVendido[nPosVend,3] // soma variavel de litro vendido
			
		Endif
		
		// Localiza Pendencia do vendedor em cursor
		nPosPend := aScan(aPendente,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If nPosPend == 0
			AAdd((oHtml:ValByName("l.pend" )), 0.00 )
			AAdd((oHtml:ValByName("l.litpen" )), 0.00 )
			AAdd((oHtml:ValByName("l.pendX" )), 0.00 )
			AAdd((oHtml:ValByName("l.lpenX" )), 0.00 )
		Else
			AAdd((oHtml:ValByName("l.pend" )),TRANSFORM(aPendente[nPosPend,2]-aPendente[nPosPend,4],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.litpen" )),TRANSFORM(aPendente[nPosPend,3]-aPendente[nPosPend,5],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.pendX" )),TRANSFORM(aPendente[nPosPend,4],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lpenX" )),TRANSFORM(aPendente[nPosPend,5],"@E 999,999,999"))
			nPend += aPendente[nPosPend,2]  // soma variavel pendente
			nLitPen += aPendente[nPosPend,3]  // soma variavel litros pendentes
			nPendX += aPendente[nPosPend,4]  // soma variavel pendente
			nLPenX += aPendente[nPosPend,5]  // soma variavel litros pendentes
		Endif
		
		// Localiza Eliminado do vendedor em cursor
		nPosElim := aScan(aElimina,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If nPosElim == 0
			AAdd((oHtml:ValByName("l.elim" )), 0.00 )
			AAdd((oHtml:ValByName("l.lelim" )), 0.00 )
		Else
			AAdd((oHtml:ValByName("l.elim" )),TRANSFORM(aElimina[nPosElim,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.lelim" )),TRANSFORM(aElimina[nPosElim,3],"@E 999,999,999"))
			nElim += aElimina[nPosElim,2]  // soma variavel pendente
			nLElim += aElimina[nPosElim,3]  // soma variavel pendente
		Endif
		
		
		// Localiza Faturado,clientes atendidos e custo do vendedor em cursor
		nPosFat := aScan(aFaturado,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If nPosFat == 0
			//AAdd((oHtml:ValByName("l.fatb" )), 0.00 )
			AAdd((oHtml:ValByName("l.cliat" )), 0.00 )
			nVlrFat := 0.00
			nLitro := 0.00
			nVlrCus := 0.00
			nVlrCus2 := 0.00
			
		Else
			//AAdd((oHtml:ValByName("l.fatb" )),TRANSFORM(aFaturado[nPosFat,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.cliat" )),TRANSFORM(aFaturado[nPosFat,4],"@E 99999"))
			nVlrFat := aFaturado[nPosFat,2]  // declara variavel valor faturado para comparar com o devolvido
			nVlrCus := aFaturado[nPosFat,3]  // declara variavel valor custo
			nVlrCus2 := aFaturado[nPosFat,6]  // declara variavel valor custo
			NLitro :=  aFaturado[nPosFat,5]
			nFatu += aFaturado[nPosFat,2]    // soma variavel faturado bruto
			nCust += aFaturado[nPosFat,3]    // soma variavel do custo
			nCust2 += aFaturado[nPosFat,6]    // soma variavel do custo
			nClie += aFaturado[nPosFat,4]    // soma variavel de clientes atendidos
			NLitr += aFaturado[nPosfat,5]
			
		Endif
		
		// Localiza Prazo do vendedor em cursor
		nPosFat := aScan(aPrazo,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If nPosFat == 0
			AAdd((oHtml:ValByName("l.prazo" )), 0.00 )
			AAdd((oHtml:ValByName("l.mg2" )), 0.00 )
			nPrz := 0.00
			nFtprz := 0.00
			nDesconV := 0.00
			nFatBruV := 0.00
		Else
			AAdd((oHtml:ValByName("l.prazo" )),TRANSFORM(aPrazo[nPosFat,2]/aPrazo[nPosFat,3],"@E 99999"))
			AAdd((oHtml:ValByName("l.mg2" )),transform(aPrazo[nPosFat,4]/aPrazo[nPosFat,5]*100,"@E 9,999.9"))
			nPrz := aPrazo[nPosFat,2]
			nFtprz := aPrazo[nPosFat,3]
			nDesconV := aPrazo[nPosFat,4]
			nFatBruV := aPrazo[nPosFat,5]
			nPrazo += aPrazo[nPosFat,2]
			nFatpr += aPrazo[nPosFat,3]
			nDescon += aPrazo[nPosFat,4]
			nFatBru += aPrazo[nPosFat,5]
			
		Endif
		
		
		
		// Localiza Quantidade e numero de Devolucoes do vendedor em cursor
		nPosDevo := aScan(aDevolvi,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If nPosDevo == 0
			AAdd((oHtml:ValByName("l.dev" )), 0.00)
			AAdd((oHtml:ValByName("l.ndev" )), 0.00)
			//AAdd((oHtml:ValByName("l.litdev" )), 0.00)
			nVlrDev := 0.00
			nLitDev := 0.00
		Else
			AAdd((oHtml:ValByName("l.dev" )),transform(aDevolvi[nPosDevo,2],"@E 999,999,999"))
			AAdd((oHtml:ValByName("l.ndev" )),aDevolvi[nPosDevo,3])
			//AAdd((oHtml:ValByName("l.litdev" )),transform(aDevolvido[nPosDevo,4],"@E 999,999,999"))
			nVlrDev := aDevolvi[nPosDevo,2]   // declara variavel valor devolvido para comparar no Abaixo.
			nLitDev := aDevolvi[nPosDevo,4]
			nDevo += aDevolvi[nPosDevo,2]     // soma variavel devolvido
			nNdev += aDevolvi[nPosDevo,3]     // soma variavel numero de devolucoes
			nLitDevo += aDevolvi[nPosDevo,4]     // soma variavel devolvido
			
		Endif
		
		If ((nVlrFat - nVlrDev)/aMeta[x,2]*100) >=100  // se alcancado 100% da meta no faturamento liquido , imprime em azul
			AAdd((oHtml:ValByName("l.fatli" )),'<font color=#0000FF >'+transform(nVlrFat - nVlrDev,'@E 999,999')+'</font>')
			AAdd((oHtml:ValByName("l.litli" )),'<font color=#0000FF >'+transform(nLitro - nLitDev,'@E 999,999')+'</font>')
			AAdd((oHtml:ValByName("l.liqmet" )),'<font color=#0000FF >'+transform(((nVlrFat - nVlrDev)/(aMeta[x,2]))*100,"@E 999,999")+'</font>')
			//AAdd((oHtml:ValByName("l.liqmet" )),'<font color=#0000FF >'+transform(((nVlrFat - nVlrDev)/(aMeta[x,2]/(nPass+nFalt)*nPass))*100,"@E 999,999")+'</font>')
		Else
			AAdd((oHtml:ValByName("l.fatli" )),transform(nVlrFat - nVlrDev,'@E 999,999'))
			AAdd((oHtml:ValByName("l.litli" )),transform(nLitro - nLitDev,'@E 999,999'))
			AAdd((oHtml:ValByName("l.liqmet" )),transform(((nVlrFat - nVlrDev)/(aMeta[x,2]))*100,"@E 999,999"))
			//AAdd((oHtml:ValByName("l.liqmet" )),transform(((nVlrFat - nVlrDev)/(aMeta[x,2]/(nPass+nFalt)*nPass))*100,"@E 999,999"))
		Endif
		//AAdd((oHtml:ValByName("l.mb1" )),transform((nVlrFat - nVlrCus2)/nVlrFat * 100,"@E 9,999.9"))
		//AAdd((oHtml:ValByName("l.mg2" )),transform((100-U_BFFATM02()-GetNewPar("BF_ACR_IR",2)) + (nVlrFat - (nVlrCus+nVlrFat*((1.00066030548229^(nPrz/nFtprz))-1)))/nVlrFat * 100,"@E 9,999.9"))
		//	AAdd((oHtml:ValByName("l.mgvl" )),transform((nVlrFat - (nVlrCus+nVlrFat*((1.00066030548229^(nPrz/nFtprz))-1))),"@E 999,999,999"))
		cGrupo  := aMeta[x,3]
		
	Next
	
	If !Empty(cGrupo)
		AAdd((oHtml:ValByName("l.vend" )),'<u><font color=#FF0000 >'+"Total-> "+cGrupo+'</font></u>')
		AAdd((oHtml:ValByName("l.meta" )),'<u><font color=#FF0000 >'+transform(nMeta,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.mtlit" )),'<u><font color=#FF0000 >'+transform(nMtLit,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.vendid" )),'<u><font color=#FF0000 >'+transform(nVend,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.litven" )),'<u><font color=#FF0000 >'+transform(nLitVen,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.rsl" )),'<u><font color=#FF0000 >'+transform(nVend/nLitVen,"@E 999,999.99")+'</font></u>')
		AAdd((oHtml:ValByName("l.liqmli" )),'<u><font color=#FF0000 >'+transform(((nLitVen)/(nMtLit))*100,"@E 999,999,999")+'</font></u>')
		//AAdd((oHtml:ValByName("l.liqmli" )),'<u><font color=#FF0000 >'+transform(((nLitVen)/(nMtLit/(nPass+nFalt)*nPass))*100,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.pend" )),'<u><font color=#FF0000 >'+transform(nPend-nPendX,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.litpen" )),'<u><font color=#FF0000 >'+transform(nLitPen-nLPenX,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.pendX" )),'<u><font color=#FF0000 >'+transform(nPendX,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.lpenX" )),'<u><font color=#FF0000 >'+transform(nLPenX,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.elim" )),'<u><font color=#FF0000 >'+transform(nElim,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.lelim" )),'<u><font color=#FF0000 >'+transform(nLElim,"@E 999,999,999")+'</font></u>')
		//AAdd((oHtml:ValByName("l.fatb" )),'<u><font color=#FF0000 >'+transform(nFatu,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.prazo" )),'<u><font color=#FF0000 >'+transform(nPrazo/nFatpr,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.cliat" )),'<u><font color=#FF0000 >'+transform(nClie,"@E 99999")+'</font></u>')
		aadd((oHtml:ValByName("l.dev" )),'<u><font color=#FF0000 >'+transform(nDevo,"@E 999,999,999")+'</font></u>')
		//aadd((oHtml:ValByName("l.litdev" )),'<u><font color=#FF0000 >'+transform(nLitDevo,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.ndev" )),'<u><font color=#FF0000 >'+transform(nNdev,"@E 9,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.litli" )),'<u><font color=#FF0000 >'+transform(nLitr - nLitDevo,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.fatli" )),'<u><font color=#FF0000 >'+transform(nFatu - nDevo,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.liqmet" )),'<u><font color=#FF0000 >'+transform(((nFatu - nDevo)/(nMeta))*100,"@E 999,999,999")+'</font></u>')
		//AAdd((oHtml:ValByName("l.liqmet" )),'<u><font color=#FF0000 >'+transform(((nFatu - nDevo)/(nMeta/(nPass+nFalt)*nPass))*100,"@E 999,999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.mtd" )),'<u><font color=#FF0000 >'+transform((nMtLit - nLitVen)/nFalt,"@E 999,999")+'</font></u>')
		AAdd((oHtml:ValByName("l.mg2" )),'<u><font color=#FF0000 >'+transform(nDescon/nFatBru*100,"@E 9,999.9")+'</font></u>')
		//AAdd((oHtml:ValByName("l.mb1" )),'<u><font color=#FF0000 >'+transform((nFatu - nCust2)/nFatu*100,"@E 9,999.9")+'</font></u>')
		//AAdd((oHtml:ValByName("l.mg2" )),'<u><font color=#FF0000 >'+transform((100-U_BFFATM02()-GetNewPar("BF_ACR_IR",2)) + (nFatu - (nCust+nFatu*((1.00066030548229^(nPrazo/nFatpr))-1)))/nFatu*100,"@E 9,999.9")+'</font></u>')
		//	AAdd((oHtml:ValByName("l.mgvl" )),'<u><font color=#FF0000 >'+transform((nFatu - (nCust+nFatu*((1.00066030548229^(nPrazo/nFatpr))-1))),"@E 999,999,999")+'</font></u>')
		
		// zera variaveis
		nMeta 	:= 0.00
		nMtLit  := 0.00
		nVend 	:= 0.00
		nLitVen := 0.00
		nPend	:= 0.00
		nLitPen := 0.00
		nPendX	:= 0.00
		nLPenX 	:= 0.00
		nElim 	:= 0.00
		nLElim 	:= 0.00
		nFatu 	:= 0.00
		nLitr  := 0.00
		nCust	:= 0.00
		nCust2	:= 0.00
		nClie	:= 0
		nDevo	:= 0.00
		nNdev	:= 0
		nPrazo  := 0.00
		nFatpr  := 0.00
		nDescon := 0.00
		nFatBru := 0.00
		nLitDevo := 0.00
	Endif
	
	
	
	
	For x := 1 To Len(aMeta)
		nMeta += aMeta[x,2] // soma variavel de metas
		nMtLit += aMeta[x,5] // soma variavel de metas litros
		nPosVend := aScan(aVendido,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If !Empty(nPosVend)
			nVend += aVendido[nPosVend,2] // soma variavel de vendido
			nLitVen += aVendido[nPosVend,3] // soma variavel de litro vendido
		Endif
		
		nPosPend := aScan(aPendente,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If !Empty(nPosPend)
			nPend += aPendente[nPosPend,2]  // soma variavel pendente
			nLitPen += aPendente[nPosPend,3]  // soma variavel pendente
			nPendX += aPendente[nPosPend,4]  // soma variavel pendente
			nLPenX += aPendente[nPosPend,5]  // soma variavel pendente
		Endif
		
		nPosElim := aScan(aElimina,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If !Empty(nPosElim)
			nElim += aElimina[nPosElim,2] // soma variavel eliminado
			nLElim += aElimina[nPosElim,3] // soma variavel eliminado
		Endif
		
		nPosFat := aScan(aFaturado,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If !Empty(nPosFat)
			nFatu += aFaturado[nPosFat,2]    // soma variavel faturado bruto
			nCust += aFaturado[nPosFat,3]    // soma variavel do custo
			nCust2 += aFaturado[nPosFat,6]    // soma variavel do custo
			nClie += aFaturado[nPosFat,4]    // soma variavel de clientes atendidos
			nLitr += aFaturado[nPosFat,5]
		Endif
		
		nPosFat := aScan(aFaturado,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If !Empty(nPosFat)
			nPrazo += aPrazo[nPosFat,2]
			nFatpr += aPrazo[nPosFat,3]
			nDescon += aPrazo[nPosFat,4]
			nFatBru += aPrazo[nPosFat,5]
		Endif
		
		nPosDevo := aScan(aDevolvi,{|y| Alltrim(y[1]) == Alltrim(aMeta[x][1])})
		If !Empty(nPosDevo)
			nDevo += aDevolvi[nPosDevo,2]     // soma variavel devolvido
			nNdev += aDevolvi[nPosDevo,3]     // soma variavel numero de devolucoes
			nLitDevo += aDevolvi[nPosDevo,4]     // soma variavel numero de devolucoes
		Endif
		
	Next
	
	// Inicia linha totalizadora
	
	AAdd((oHtml:ValByName("l.vend" )),'<b><font size =1 face =Verdana color=#0000FF >'+"TOTAL GERAL BF"+'</font></b>')
	AAdd((oHtml:ValByName("l.meta" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nMeta,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.mtlit" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nMtLit,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.vendid" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nVend,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.litven" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nLitVen,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.rsl" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nVend/nLitVen,"@E 999,999.99")+'</font></b>')
	AAdd((oHtml:ValByName("l.liqmli" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(((nLitVen)/(nMtLit))*100,"@E 999,999,999")+'</font></b>')
	//AAdd((oHtml:ValByName("l.liqmli" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(((nLitVen)/(nMtLit/(nPass+nFalt)*nPass))*100,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.pend" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nPend-nPendX,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.litpen" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nLitPen-nLPenX,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.pendX" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nPendX,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.lpenX" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nLPenX,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.elim" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nElim,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.lelim" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nLElim,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.prazo" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nPrazo/nFatpr,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.cliat" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nClie,"@E 99999")+'</font></b>')
	aadd((oHtml:ValByName("l.dev" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nDevo,"@E 999,999,999")+'</font></b>')
	//aadd((oHtml:ValByName("l.litdev" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nLitDevo,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.ndev" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nNdev,"@E 9999")+'</font></b>')
	AAdd((oHtml:ValByName("l.litli" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nLitr - nLitDevo,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.fatli" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nFatu - nDevo,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.liqmet" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(((nFatu - nDevo )/(nMeta))*100,"@E 999,999,999")+'</font></b>')
	//AAdd((oHtml:ValByName("l.liqmet" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(((nFatu - nDevo )/(nMeta/(nPass+nFalt)*nPass))*100,"@E 999,999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.mtd" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform((nMtLit - nLitVen)/nFalt,"@E 999,999")+'</font></b>')
	AAdd((oHtml:ValByName("l.mg2" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform(nDescon/nFatBru*100,"@E 9,999.9")+'</font></b>')
	//AAdd((oHtml:ValByName("l.mb1" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform((nFatu - nCust2)/nFatu * 100,"@E 9,999.9")+'</font></b>')
	//AAdd((oHtml:ValByName("l.mg2" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform((100-U_BFFATM02()-GetNewPar("BF_ACR_IR",2)) + (nFatu - (nCust+nFatu*((1.00066030548229^(nPrazo/nFatpr))-1)))/nFatu * 100,"@E 9,999.9")+'</font></b>')
	//AAdd((oHtml:ValByName("l.mgvl" )),'<b><font size =1 face =Verdana color=#0000FF >'+transform((nFatu - (nCust+nFatu*((1.00066030548229^(nPrazo/nFatpr))-1))),"@E 999,999,999")+'</font></b>')
	
	// Finaliza linha totalizadora
	
	oProcess:ClientName(Substr(cUsuario,7,15))
	//oProcess:cTo := "daniel@gmeyer.com.br"
	// Controle de destinatarios sera feito pelo S4 ( Favor conferir no apelido em contas de email para remover\adicionar destinatarios)
	oProcess:cTo := U_BFFATM15("mapaindustrial@atrialub.com.br","BIG011IL")
	
	
	oProcess:Start()
	oProcess:Finish()

	// Força disparo dos e-mails pendentes do workflow
	WFSENDMAIL()
	
	cMsg += chr(10)+chr(13)+" finalizado "+time()
	
	MsgInfo(cMsg)
	
Return


Static Function DATAMAPA(dDataAtu,cRetorno)
	
	Local dInicial := dDatabase
	Local dFinal := dDatabase
	Local cMesAno := ''
	
	/*if Day(dDataBase) <= 30
	cMesAno := substr(dtos(LastDay(dDatabase)+1),5,2) + "/" + substr(dtos(LastDay(dDatabase)+1),1,4)
	cInicial := substr(dtos(dDatabase),1,6) + "28"
	dFinal := LastDay(dDatabase)+30
else
	cMesAno := substr(dtos(dDatabase),5,2) + "/" + substr(dtos(dDatabase),1,4)
	cInicial := substr(DTOS(FirstDay(dDataBase)-1),1,6) + "31"
	dFinal := LastDay(dDatabase)+30//FirstDay(dDatabase)+29
	//endif */
	
	dInicial  := DTOS(FirstDay(dDataBase))
	dFinal    := LastDay(dDatabase)
	cMesAno   := substr(dtos(dDatabase),5,2) + "/" + substr(dtos(dDatabase),1,4)
	
	if cRetorno = 'M'
		Return (cMesAno)
	elseif cRetorno = 'P'
		Return (dInicial)
	elseif cRetorno = 'U'
		Return (dFinal)
	EndIf
