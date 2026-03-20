#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} BIG037
(Browse cadastro de produtos com consultas personalizadas)
@author MarceloLauschner
@since 20/05/2005
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BIG037()

	Private cCadastro 	:= "Cadastro de Produto"
	Private cprod   	:= Space(15)
	Private cNomeUser 	:= SubStr(cUsuario,7,15)
	Private aRotina 	:= {}
	Private	cLocPad		:= ""
	Private nOpcLoc		:= 0

	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()


	If __cUserId $ GetNewPar("BF_BIG037A","000000#000130")
		aRotina := { 	{"Pesquisar"			,"AxPesqui",0,1} ,;
			{"Visualizar"			,"AxVisual",0,2} ,;
			{"Alt.Dados Log."		,"U_BIG007",0,6} ,;
			{"Enderecamento"		,"U_BIG016",0,6} ,;
			{"Consulta"			,"U_BIG037B",0,7} }
	Else
		aRotina := { 	{"Pesquisar","AxPesqui",0,1} ,;
			{"Visualizar"	,"AxVisual",0,2} ,;
			{"Consulta"	,"U_BIG037B",0,4} }
	Endif

	dbSelectArea("SB1")
	dbSetOrder(1)

	mBrowse( 6,1,22,75,"SB1")

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	If(Type('oTmpTable2') <> 'U')
		oTmpTable2:Delete()
		FreeObj(oTmpTable2)
	EndIf

Return


/*/{Protheus.doc} BIG037B
(Monta tela de consultas )
@author MarceloLauschner
@since 25/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User function BIG037B()


	Local 		aCampos 	:= {}
	Local 		aStru   	:= {}
	Local 		oTmpTable   := NIL
	Private 	nCompras 	:= 0


	If Type("cLocPad") <> "C"
		cLocPad		:= ""
	Endif

	cProd := SB1->B1_COD

	aStru:={}

	Aadd(aStru,{ "ENTREGA" 	,"D", 08, 0 } )
	Aadd(aStru,{ "NUM"		,"C", 06, 0 } )
	Aadd(aStru,{ "SALDO"		,"N", 08, 0 } )
	Aadd(aStru,{ "PRCCONF"	,"N", 10, 2 } )
	Aadd(aStru,{ "EMISSAO"	,"D", 08, 0 } )


	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	cArq := GetNextALias()

	oTmpTable := FWTemporaryTable():New(cArq,aStru)
	oTmpTable:Create()

	cQrs := ""
	cQrs += "SELECT (C7_QUANT - C7_QUJE) AS QTE,C7_NUM,C7_DATPRF,C7_EMISSAO,C7_PRECO "
	cQrs += "  FROM " + RetSqlName("SC7") + " "
	cQrs += " WHERE D_E_L_E_T_ = ' ' "
	cQrs += "   AND C7_FILIAL = '" + xFilial("SC7") + "' "
	If !Empty(cLocPad)
		cQrs += " AND C7_LOCAL = '"+cLocPad+"' "
	Endif
	cQrs += "   AND C7_PRODUTO = '" + cProd + "' "
	cQrs += "   AND C7_ENCER = ' ' "
	cQrs += "   AND C7_RESIDUO = ' ' "
	cQrs += "   AND C7_QUJE < C7_QUANT "
	cQrs += " ORDER BY C7_DATPRF "

	TCQUERY cQrs NEW ALIAS "QC7"

	While !Eof()
		If !Empty(QC7->C7_NUM)
			dbSelectArea(cArq)
			RecLock(cArq,.T.)
			(cArq)->ENTREGA := STOD(QC7->C7_DATPRF)
			(cArq)->NUM     := QC7->C7_NUM
			(cArq)->SALDO   := QC7->QTE
			(cArq)->PRCCONF := QC7->C7_PRECO
			(cArq)->EMISSAO := STOD(QC7->C7_EMISSAO)
			MsUnLock(cArq)
			nCompras += QC7->QTE
		Endif
		dbSelectArea("QC7")
		dbSkip()
	EndDo

	QC7->(DbCloseArea())

	cRealName := oTmpTable:GetRealName()

	dbSelectArea(cArq)
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "ENTREGA" ,"Dt Entrega" } )
	Aadd(aCampos,{ "NUM"     ,"Nº Pedido " } )
	Aadd(aCampos,{ "SALDO"   ,"Saldo","@E 999,999" } )
	Aadd(aCampos,{ "PRCCONF" ,"Prc.Conf","@E 999,999.99" } )
	Aadd(aCampos,{ "EMISSAO" ,"Emissão"})

	@ 200,1 TO 600,700 DIALOG oConsulta TITLE OemToAnsi("Dados de giro do produto -> "+cProd+" -> "+SB1->B1_DESC)
	@ 005,005 TO 170,340 BROWSE cArq OBJECT oBrw FIELDS aCampos
	@ 175,015 Say "Saldo compras"
	@ 175,060 Get nCompras size 50,13 picture "@E 999,999.99" When .F.
	@ 185,015  Button "Faturamento" size 37,13 action sfFatur()
	@ 185,060  Button "Preços Tab." size 37,13 action sfPrecos()
	@ 185,105  Button "N.F. Entrada" size 37,13 action sfCompras()
	@ 185,150  Button "Ped. Vendas" size 37,13 action sfVendas()
	@ 185,195  Button "Estoques   " size 37,13 action sfEstoques()
	@ 185,240  button "Fechar "     size 37,13 Action Close(oConsulta)

	ACTIVATE DIALOG oConsulta CENTERED

	//(COMP)->(DbCloseArea())
	//FErase(cArq + GetDbExtension()) // Deleting file
	//FErase(cArq + OrdBagExt()) // Deleting index

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

Return


/*/{Protheus.doc} sfVendas
(long_description)
@author MarceloLauschner
@since 25/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static function sfVendas()

	Local nVendas := 0
	Local aCampos := {}
	Local aStru   := {}
	Local oTmpTable	:= NIL

	aStru:={}

	Aadd(aStru,{ "NUM"		, "C", 06, 0 } )
	Aadd(aStru,{ "ITEM"		, "C", 05, 0 } )
	Aadd(aStru,{ "SALDO"	, "N", 08, 0 } )
	Aadd(aStru,{ "STATUS"	, "C", 13, 0 } )
	Aadd(aStru,{ "LOCAL"	, "C", 02, 0 } )
	Aadd(aStru,{ "PRCVEN"	, "N", 10, 2 } )
	Aadd(aStru,{ "EMISSAO"	, "D", 08, 0 } )
	Aadd(aStru,{ "HORA"		, "C", 25, 0 } )
	Aadd(aStru,{ "ENTREGA" 	, "D", 08, 0 } )
	Aadd(aStru,{ "VENDEDOR"	, "C", 15, 0 } )
	Aadd(aStru,{ "TMK"     	, "C", 15, 0 } )
	Aadd(aStru,{ "CODLJ"  	, "C", 11, 0 } )
	Aadd(aStru,{ "NOME"   	, "C", 40, 0 } )

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	cArq := GetNextALias()

	oTmpTable := FWTemporaryTable():New(cArq,aStru)
	oTmpTable:Create()

	cQri := ""
	cQri += "SELECT (C6_QTDVEN - C6_QTDENT) AS SALDO,C6_NUM,C6_PRCVEN "
	cQri += "  FROM "+RetSqlName("SC6") + " C6, " + RetSqlName("SF4")+" F4 "
	cQri += " WHERE F4.D_E_L_E_T_ = ' ' "
	cQri += "   AND F4_ESTOQUE = 'S' "
	cQri += "   AND F4_CODIGO = C6_TES "
	cQri += "   AND F4_FILIAL = C6_FILIAL "
	cQri += "   AND C6.D_E_L_E_T_ = ' ' "
	If !Empty(cLocPad)
		cQri += "  AND C6_LOCAL = '"+cLocPad+"' "
	Endif
	cQri += "   AND C6_FILIAL = '" + xFilial("SC6") + "' "
	cQri += "   AND C6_PRODUTO = '" + cProd + "' "
	cQri += "   AND C6_BLQ <> 'R' "
	cQri += "   AND C6_QTDENT < C6_QTDVEN "
	cQri += " ORDER BY C6_NUM ASC "

	cQry := "SELECT C6_NUM ,"
	cQry += "       C6_LOCAL,"
	cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN C6_ITEM || '-' || C9_SEQUEN ELSE C6_ITEM END C6ITEM,"
	cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN C9_QTDLIB ELSE C6_QTDVEN END SALDO,"
	cQry += "       C6_PRCVEN,"
	cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN (C6_VALOR/C6_QTDVEN)*C9_QTDLIB ELSE C6_VALOR END C6_VALOR,"
	cQry += "       CASE "
	cQry += "         WHEN C6_BLQ = 'S' AND C9_SEQUEN IS NULL THEN 'Pendente' "
	cQry += "         WHEN C6_BLQ = 'R' AND C9_SEQUEN IS NULL THEN 'Residuo' "
	cQry += "         WHEN C9_SEQUEN IS NULL THEN 'Liberado' "
	cQry += "         WHEN C9_NFISCAL !=  '  ' THEN 'Faturado' "
	cQry += "         WHEN C9_BLCRED NOT IN('  ','10') AND C9_BLEST NOT IN('  ','10') THEN 'Cred/Estoque' "
	cQry += "         WHEN C9_BLCRED NOT IN('  ','10') THEN 'Credito' "
	cQry += "         WHEN C9_BLEST NOT IN('  ','10') THEN 'Estoque' "
	cQry += "        ELSE "
	cQry += "         'Liberado' "
	cQry += "        END STATUS,"
	cQry += "      NVL((SELECT MAX(Z0_HORA || '-'|| Z0_USER) "
	cQry += "             FROM "+RetSqlName("SZ0") + " Z0 "
	cQry += "            WHERE D_E_L_E_T_ = ' ' "
	cQry += "              AND Z0_TIPO = 'IP' "
	cQry += "              AND Z0_PEDIDO = C6_NUM "
	cQry += "              AND Z0_FILIAL = '"+ xFilial("SC6") + "'),' ') HORA_USER "
	cQry += "  FROM "+RetSqlName("SC6")+ " C6, "+ RetSqlName("SC9") + " C9, " + RetSqlName("SF4")  + " F4 "
	cQry += " WHERE C9.D_E_L_E_T_(+) = ' ' "
	cQry += "   AND C9_ITEM(+) = C6_ITEM "
	cQry += "   AND C9_PRODUTO(+) = C6_PRODUTO "
	cQry += "   AND C9_PEDIDO(+) = C6_NUM "
	cQry += "   AND C9_FILIAL(+) = '"+xFilial("SC9")+"' "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_ESTOQUE = 'S' "
	cQry += "   AND F4_CODIGO = C6_TES "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	If!Empty(cLocPad)
		cQry += "  AND C6_LOCAL = '"+cLocPad+"' "
	Endif
	cQry += "   AND C6.D_E_L_E_T_ =' ' "
	cQry += "   AND C6_PRODUTO = '"+cProd +"' "
	cQry += "   AND C6_BLQ <> 'R' "
	cQry += "   AND C6_QTDENT < C6_QTDVEN "
	cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
	cQry += "UNION "
	cQry += "SELECT C6_NUM,"
	cQry += "       C6_LOCAL,"
	cQry += "       C6_ITEM C6ITEM,"
	cQry += "       C6_QTDVEN - C6_QTDENT SALDO,"
	cQry += "       C6_PRCVEN,"
	cQry += "       (C6_QTDVEN - C6_QTDENT)*C6_PRCVEN C6_VALOR,"
	cQry += "       CASE "
	cQry += "         WHEN C6_BLQ = 'S' THEN 'Pendente' "
	cQry += "         WHEN C6_BLQ = 'R' THEN 'Residuo' "
	cQry += "        ELSE "
	cQry += "         'Pendente' "
	cQry += "        END STATUS, "
	cQry += "      NVL((SELECT MAX(Z0_HORA || '-'|| Z0_USER) "
	cQry += "             FROM "+RetSqlName("SZ0") + " Z0 "
	cQry += "            WHERE D_E_L_E_T_ = ' ' "
	cQry += "              AND Z0_TIPO = 'IP' "
	cQry += "              AND Z0_PEDIDO = C6_NUM "
	cQry += "              AND Z0_FILIAL = '"+ xFilial("SC6") + "'),' ') HORA_USER "
	cQry += "  FROM "+RetSqlName("SC6")+ " C6, "+RetSqlName("SF4")+ " F4 "
	cQry += " WHERE C6_QTDVEN > NVL((SELECT SUM(C9_QTDLIB) "
	cQry += "                          FROM "+RetSqlName("SC9")  + " C9 "
	cQry += "                  	      WHERE D_E_L_E_T_ = ' ' "
	cQry += "                           AND C9_ITEM = C6_ITEM "
	cQry += "                           AND C9_PRODUTO = C6_PRODUTO "
	cQry += "                           AND C9_PEDIDO = C6_NUM "
	cQry += "                           AND C9_FILIAL = '"+xFilial("SC9")+"'),0) "
	cQry += "   AND F4.D_E_L_E_T_ = ' ' "
	cQry += "   AND F4_ESTOQUE = 'S' "
	cQry += "   AND F4_CODIGO = C6_TES "
	cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	If !Empty(cLocPad)
		cQry += "  AND C6_LOCAL = '"+cLocPad+"' "
	Endif
	cQry += "   AND C6_QTDENT < C6_QTDVEN "
	cQry += "   AND C6_BLQ <> 'R' "
	cQry += "   AND C6.D_E_L_E_T_ =' ' "
	cQry += "   AND C6_PRODUTO = '"+cProd+"' "
	cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
	cQry += " ORDER BY C6_NUM DESC "

	TCQUERY cQry NEW ALIAS "QC6"

	While !Eof()
		Dbselectarea("SC5")
		dbsetorder(1)
		If !dbseek(xFilial("SC5")+QC6->C6_NUM)
			Alert("Pedido não encontrado -->> "+QC6->C6_NUM)
		Endif

		If !Empty(QC6->C6_NUM)


			dbSelectArea(cArq)
			RecLock(cArq,.T.)
			(cArq)->NUM     := QC6->C6_NUM
			(cArq)->SALDO   := QC6->SALDO
			(cArq)->LOCAL	:= QC6->C6_LOCAL
			(cArq)->PRCVEN  := QC6->C6_PRCVEN
			(cArq)->EMISSAO := SC5->C5_EMISSAO
			(cArq)->ENTREGA := SC5->C5_DTPROGM
			(cArq)->STATUS	:= QC6->STATUS
			(cArq)->ITEM	:= QC6->C6ITEM


			(cArq)->CODLJ := SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI

			If SC5->C5_TIPO $"B#D"
				Dbselectarea("SA2")
				dbsetorder(1)
				dbseek(xFilial("SA")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
				(cArq)->NOME := SC5->C5_TIPO +"/"+SA2->A2_NOME
				(cArq)->HORA		:= SC5->C5_USUPED
				(cArq)->TMK  := SC5->C5_USUPED
			Else
				Dbselectarea("SA3")
				dbsetorder(1)
				dbseek(xFilial("SA3")+SC5->C5_VEND1)

				(cArq)->HORA		:= QC6->HORA_USER

				Dbselectarea("SA1")
				dbsetorder(1)
				dbseek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
				(cArq)->NOME := SA1->A1_NOME
				(cArq)->VENDEDOR := SA3->A3_NREDUZ

				Dbselectarea("SA3")
				dbsetorder(1)
				dbseek(xFilial("SA3")+SC5->C5_VEND2)
				(cArq)->TMK  := SA3->A3_NREDUZ

			Endif

			MsUnLock(cArq)
			nVendas += QC6->SALDO
		Endif
		dbSelectArea("QC6")
		dbSkip()
	End
	QC6->(DbCloseArea())

	dbSelectArea(cArq)
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "NUM"    	,"Nº Pedido " } )
	Aadd(aCampos,{ "ITEM" 		,"Item-Seq" })
	Aadd(aCampos,{ "SALDO"  	,"Saldo" ,"@E 999,999" } )
	Aadd(aCampos,{ "STATUS" 	,"Status" , })
	Aadd(aCampos,{ "LOCAL" 		,"Local" , })
	Aadd(aCampos,{ "PRCVEN" 	,"Prc.Venda","@E 999,999.99" } )
	Aadd(aCampos,{ "EMISSAO"	,"Emissão"})
	Aadd(aCampos,{ "HORA"		,"Hora-Usuário"})
	Aadd(aCampos,{ "ENTREGA"	,"Dt Programada" } )
	Aadd(aCampos,{ "VENDEDOR"	,"Vendedor" })
	Aadd(aCampos,{ "TMK"    	,"Telemarketing"})
	Aadd(aCampos,{ "CODLJ"  	,"Cód.Lj"  })
	Aadd(aCampos,{ "NOME"   	,"Nome Cliente"})

	@ 200,1 TO 600,700 DIALOG oVendas TITLE OemToAnsi("Consulta de pedidos não faturados")
	@ 005,005 TO 170,340 BROWSE cArq OBJECT oBrw1 FIELDS aCampos
	@ 176,015 Say "Saldo Vendas"
	@ 175,060 Get nVendas size 50,13 picture "@E 999,999.99" when .f.

	@ 185,195 button "Fechar "     size 37,13 Action Close(oVendas)

	ACTIVATE DIALOG oVendas CENTERED

	//VEND->(DbCloseArea())
	//FErase(cArq + GetDbExtension()) // Deleting file
	//FErase(cArq + OrdBagExt()) // Deleting index
	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

Return



/*/{Protheus.doc} sfFatur
(long_description)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static function sfFatur()

	Local nMedven := 0
	Local nMedfat := 0
	Local nMeses  := 0
	Local aCampos := {}
	Local aStru   := {}
	Local cDataini := ""
	Local aMeses  := {{"01"},{"02"},{"03"},{"04"},{"05"},{"06"},{"07"},{"08"},{"09"},{"10"},{"11"},{"12"}}
	Local aDatas  := {}
	Local x
	Local oTmpTable	:= NIL

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


	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	cArq := GetNextALias()

	oTmpTable := FWTemporaryTable():New(cArq,aStru)
	oTmpTable:Create()

	For x := 1 To len(aDatas)
		If Alltrim(aDatas[x,1]+"01") >= cDataini .and. Alltrim(aDatas[x,1]) <= alltrim(substr(dtos(dDatabase),1,6))

			cQrb := ""
			cQrb += "SELECT SUM(C6_QTDVEN) AS CONSUMO "
			cQrb += "  FROM " + RetSqlName("SC6") + " SC6," + RetSqlName("SC5") + " SC5, " + RetSqlName("SF4") + " SF4 "
			cQrb += " WHERE SF4.D_E_L_E_T_ = ' ' "
			cQrb += "   AND F4_ESTOQUE = 'S' "
			cQrb += "   AND F4_CODIGO = C6_TES "
			cQrb += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
			cQrb += "   AND SC6.D_E_L_E_T_ = ' ' "
			If !Empty(cLocPad)
				cQrb += "  AND C6_LOCAL = '"+cLocPad+"' "
			Endif
			cQrb += "   AND SC6.C6_PRODUTO = '" + cProd + "' "
			cQrb += "   AND SC6.C6_NUM = SC5.C5_NUM "
			cQrb += "   AND SC6.C6_FILIAL = '" + xFilial("SC6") + "' "
			cQrb += "   AND SC5.D_E_L_E_T_ = ' ' "
			cQrb += "   AND C5_TIPO = 'N' "
			cQrb += "   AND SUBSTR(SC5.C5_EMISSAO,1,6) = '"+aDatas[x][1]+"' "
			cQrb += "   AND SC5.C5_FILIAL = '" + xFilial("SC5") + "' "


			TCQUERY cQrb NEW ALIAS "QVEN"

			cQrc := ""
			cQrc += "SELECT SUM(D2_QUANT) AS CONS,COUNT(DISTINCT(D2_CLIENTE||D2_LOJA)) AS CLI "
			cQrc += "  FROM " + RetSqlName("SD2") + " SD2, " + RetSqlName("SF4") + " SF4 "
			cQrc += " WHERE SF4.D_E_L_E_T_ = ' ' "
			cQrc += "   AND F4_ESTOQUE = 'S' "
			cQrc += "   AND SF4.F4_CODIGO = SD2.D2_TES "
			cQrc += "   AND SF4.F4_FILIAL = '" + xFilial("SF4") + "' "
			cQrc += "   AND SD2.D_E_L_E_T_ = ' ' "
			If !Empty(cLocPad)
				cQrc += "  AND D2_LOCAL = '"+cLocPad+"' "
			Endif
			cQrc += "   AND SUBSTR(SD2.D2_EMISSAO,1,6)= '" + aDatas[x][1]+ "' "
			cQrc += "   AND SD2.D2_COD = '" + cProd +"' "
			cQrc += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "' "


			TCQUERY cQrc NEW ALIAS "QRC"

			dbSelectArea(cArq)
			RecLock(cArq,.T.)
			(cArq)->MESANO := Substr(aDatas[x][1],5,2)+"/"+Substr(aDatas[x][1],1,4)
			(cArq)->VEND   := QVEN->CONSUMO
			(cArq)->FATU   := QRC->CONS
			(cArq)->CLI    := QRC->CLI
			MsUnLock()
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

	dbSelectArea(cArq)
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "MESANO"     ,"Mês Ano" } )
	Aadd(aCampos,{ "VEND"       ,"Vendido","@E 999,999" } )
	Aadd(aCampos,{ "FATU"       ,"Faturado","@E 999,999" } )
	Aadd(aCampos,{ "CLI"        ,"Clientes","@E 999,999"})

	@ 200,1 TO 600,700 DIALOG oConsumo TITLE OemToAnsi("Consumo mês a mês Vendido e Faturado")
	@ 005,005 TO 170,340 BROWSE cArq OBJECT oBrw2 FIELDS aCampos
	@ 173,015 Say "Média de venda"
	@ 173,060 Get nMedven size 50,13 picture "@E 999,999.99" when .f.
	@ 173,130 Say "Média de faturamento"
	@ 173,200 Get nMedfat size 50,13 picture "@E 999,999.99" when .f.

	@ 185,195 button "Fechar "     size 37,13 Action Close(oConsumo)

	ACTIVATE DIALOG oConsumo CENTERED

	//FATU->(DbCloseArea())
	//FErase(cArq + GetDbExtension()) // Deleting file
	//FErase(cArq + OrdBagExt()) // Deleting index
	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

Return


/*/{Protheus.doc} sfPrecos
(long_description)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static function sfPrecos()

	Local aCampos := {}
	Local aStru   := {}
	Local oTmpTable	:= NIL

	aStru:={}

	Aadd(aStru,{ "TAB",  "C", 03, 0 } )
	Aadd(aStru,{ "DESCRI",  "C", 30, 0 } )
	Aadd(aStru,{ "PRCVEN","N", 10, 2 } )
	Aadd(aStru,{ "ITEM","C", 04, 0 } )

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	cArq := GetNextALias()

	oTmpTable := FWTemporaryTable():New(cArq,aStru)
	oTmpTable:Create()

	cQri := ""
	cQri += "SELECT DA1_PRCVEN,DA1_CODTAB,DA1_ITEM,DA0_DESCRI "
	cQri += "  FROM "+RetSqlName("DA1") + " DA1, " + RetSqlName("DA0") + " DA0 "
	cQri += " WHERE DA1.D_E_L_E_T_ = ' ' "
	cQri += "   AND DA0.D_E_L_E_T_ = ' ' "
	cQri += "   AND DA0_FILIAL = '" +xFilial("DA0") + "' "
	cQri += "   AND DA1_FILIAL = '" +xFilial("DA1") + "' "
	cQri += "   AND DA1.DA1_CODPRO = '" + cProd + "' "
	cQri += "   AND DA1.DA1_CODTAB = DA0.DA0_CODTAB "
	cQri += " ORDER BY DA1.DA1_CODTAB ASC "


	TCQUERY cQri NEW ALIAS "QDA1"

	While !Eof()

		dbSelectArea(cArq)
		RecLock(cArq,.T.)
		(cArq)->TAB     := QDA1->DA1_CODTAB
		(cArq)->DESCRI  := QDA1->DA0_DESCRI
		(cArq)->PRCVEN  := QDA1->DA1_PRCVEN
		(cArq)->ITEM    := QDA1->DA1_ITEM
		MsUnLock()

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
	@ 005,005 TO 170,340 BROWSE cArq OBJECT oBrw3 FIELDS aCampos

	@ 185,195 button "Fechar "     size 37,13 Action Close(oPrecos)

	ACTIVATE DIALOG oPrecos CENTERED

	//PRC->(DbCloseArea())
	//FErase(cArq + GetDbExtension()) // Deleting file
	//FErase(cArq + OrdBagExt()) // Deleting index

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

Return


/*/{Protheus.doc} sfCompras
(long_description)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static function sfCompras()

	Local aCampos := {}
	Local aStru   := {}
	Local oTmpTable	:= NIL

	aStru:={}

	Aadd(aStru,{ "NUM",  "C", TamSX3("D1_DOC")[1], 0 } )
	Aadd(aStru,{ "QTE",  "N", 08, 0 } )
	Aadd(aStru,{ "PRCCONF","N", 10, 2 } )
	Aadd(aStru,{ "EMISSAO","D", 08, 0 } )
	Aadd(aStru,{ "ENTREGA" , "D", 08, 0 } )
	Aadd(aStru,{ "CONDPAG" , "C", 30,0 } )

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	cArq := GetNextALias()

	oTmpTable := FWTemporaryTable():New(cArq,aStru)
	oTmpTable:Create()

	cQri := ""
	cQri += "SELECT D1_VUNIT,D1_DOC,D1_EMISSAO,D1_DTDIGIT,D1_QUANT,F1_COND "
	cQri += "  FROM "+ RetSqlName("SD1") + " SD1, " + RetSqlName("SF1") + " SF1, "+RetSqlName("SF4")+ " F4 "
	cQri += " WHERE SD1.D_E_L_E_T_ = ' ' "
	cQri += "   AND SF1.D_E_L_E_T_ = ' ' "
	cQri += "   AND F4.D_E_L_E_T_ = ' ' "
	cQri += "   AND F4_ESTOQUE = 'S' "
	cQri += "   AND F4_CODIGO = D1_TES "
	cQri += "   AND F4_FILIAL = '"+xFilial("SF4")+"' "
	cQri += "   AND SD1.D1_FILIAL = '" + xFilial("SD1") + "' "
	cQri += "   AND SF1.F1_FILIAL = '" + xFilial("SF1") + "' "
	cQri += "   AND SD1.D1_COD = '" + cProd + "' "
	If !Empty(cLocPad)
		cQri += "  AND D1_LOCAL = '"+cLocPad+"' "
	Endif
	cQri += "   AND SD1.D1_TIPO = 'N' "
	cQri += "   AND SD1.D1_DOC = SF1.F1_DOC "
	cQri += "   AND SD1.D1_SERIE = SF1.F1_SERIE "
	cQri += "ORDER BY SD1.D1_DTDIGIT DESC, SD1.D1_DOC DESC "


	TCQUERY cQri NEW ALIAS "QD1"

	While !Eof()
		Dbselectarea("SE4")
		dbsetorder(1)
		dbseek(xFilial("SE4")+QD1->F1_COND)
		If !Empty(QD1->D1_DOC)
			dbSelectArea(cArq)
			RecLock(cArq,.T.)
			(cArq)->NUM     := QD1->D1_DOC
			(cArq)->QTE     := QD1->D1_QUANT
			(cArq)->PRCCONF := QD1->D1_VUNIT
			(cArq)->EMISSAO := STOD(QD1->D1_EMISSAO)
			(cArq)->ENTREGA := STOD(QD1->D1_DTDIGIT)
			(cArq)->CONDPAG := QD1->F1_COND+" - " + SE4->E4_DESCRI
			MsUnLock(cArq)
		Endif
		dbSelectArea("QD1")
		dbSkip()
	EndDo
	QD1->(DbCloseArea())


	dbSelectArea(cArq)
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "NUM"     ,"Nº NF" } )
	Aadd(aCampos,{ "QTE"   ,"Qte","@E 999,999" } )
	Aadd(aCampos,{ "PRCCONF"  ,"Prc.Conf","@E 999,999.99" } )
	Aadd(aCampos,{ "EMISSAO" ,"Emissão"})
	Aadd(aCampos,{ "ENTREGA" ,"Dt Entrada" } )
	Aadd(aCampos,{ "CONDPAG" , "Cond.Pgto" })
	@ 200,1 TO 600,700 DIALOG oCompras TITLE OemToAnsi("Consulta de notas fiscais de entrada normais")
	@ 005,005 TO 170,340 BROWSE cArq OBJECT oBrw4 FIELDS aCampos

	@ 185,195 button "Fechar "     size 37,13 Action Close(oCompras)

	ACTIVATE DIALOG oCompras CENTERED

	//VEND->(DbCloseArea())

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

Return


/*/{Protheus.doc} sfEstoques
(long_description)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static function sfEstoques()

	Local aCampos := {}
	Local aStru   := {}
	Local oTmpTable	:= NIL

	If Type("cProd") <> "C"
		cProd	:= SB1->B1_COD
	Endif

	aStru:={}

	Aadd(aStru,{ "ARMAZ"  , "C", 02, 0 } )
	Aadd(aStru,{ "QATU"   , "N", 10, 0 } )
	Aadd(aStru,{ "RESERVA", "N", 10, 0 } )
	Aadd(aStru,{ "DISP"   , "N", 10, 0 } )


	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

	cArq := GetNextALias()

	oTmpTable := FWTemporaryTable():New(cArq,aStru)
	oTmpTable:Create()

	cQri := ""
	cQri += "SELECT B2_LOCAL,B2_QATU,B2_RESERVA,B2_USAI,(B2_QATU - B2_RESERVA)AS DISP "
	cQri += "  FROM "+RetSqlName("SB2") + " SB2 "
	cQri += " WHERE D_E_L_E_T_ = ' ' "
	cQri += "   AND B2_FILIAL = '" + xFilial("SB2")+ "' "
	cQri += "   AND B2_COD = '" + cProd + "' "
	cQri += " ORDER BY B2_LOCAL ASC "

	TCQUERY cQri NEW ALIAS "QEST"

	While !Eof()
		// Se for Atrialub / Filial PR e Armazém 03 não exibe na tela
		If cEmpAnt+cFilAnt $ "0204"
			If QEST->B2_LOCAL $ GetNewPar("BF_VIEWB2N","03") .And. !(__cUserId $ GetNewPar("BF_VIEWB2L","000130#000000"))
				dbSelectArea("QEST")
				dbSkip()
				Loop
			Endif
		Endif
		dbSelectArea(cArq)
		RecLock(cArq,.T.)
		(cArq)->ARMAZ     := QEST->B2_LOCAL
		(cArq)->QATU      := QEST->B2_QATU
		(cArq)->RESERVA   := QEST->B2_RESERVA
		(cArq)->DISP      := QEST->DISP
		MsUnLock()
		dbSelectArea("QEST")
		dbSkip()
	End
	QEST->(DbCloseArea())

	dbSelectArea(cArq)
	dbGotop()

	aCampos := {}
	Aadd(aCampos,{ "ARMAZ"     ,"Armaz" } )
	Aadd(aCampos,{ "QATU"      ,"Est Fisico","@E 999,999" } )
	Aadd(aCampos,{ "RESERVA"   ,"Lib Pedido","@E 999,999" } )
	Aadd(aCampos,{ "DISP"      ,"Disponível","@E 999,999" } )

	@ 200,1 TO 600,700 DIALOG oEst TITLE OemToAnsi("Consulta posição de estoque")
	@ 005,005 TO 170,340 BROWSE cArq OBJECT oBrw4 FIELDS aCampos

	@ 185,195 button "Fechar "     size 37,13 Action Close(oEst)

	ACTIVATE DIALOG oEst CENTERED

	//EST->(DbCloseArea())
	//FErase(cArq + GetDbExtension()) // Deleting file
	//FErase(cArq + OrdBagExt()) // Deleting index

	If(Type('oTmpTable') <> 'U')
		oTmpTable:Delete()
		FreeObj(oTmpTable)
	EndIf

Return
