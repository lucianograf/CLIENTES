#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'
#include 'colors.ch'

/*/{Protheus.doc} MLFATR01
// Relatório de impressão de Pedido de venda para Expedição
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User function MLFATR01()

	Local	cQry	
	Local	nSldSB8
	Local	nContSB8
	Local	cImpLtSB8 
	Local	lGrvCB8		:= .T. 
	Local	lFirst		:= .T. 
	Local	nContLin	:= 020
	Local	cPerg		:= "MLFATR01"
	Local	nCONTNF   	:= 1
	Local	nItens    	:= 0
	Local	nTotItens 	:= 10
	Local	nCred 		:= 0.00
	Local	nEst  		:= 0.00
	Local	nLib  		:= 0.00
	Local	nTotal		:= 0.00
	Local	nPag		:= 0
	Local	cNumPed		:= ""
	Local	cMsgInt		:= ""
	Local	cMsgNota	:= ""
	Local	cObsCli		:= ""
	Local	oObsInt		:= ""
	Local	nZ
	Local	nSubTot		:= 0
	Private oFont01  	:= TFont():New( "Courier New" ,,09,,.t.,,,,,.f. )
	Private	oFont02		:= TFont():New( "Arial"       ,,04,,.T.,,,,,.f. )
	Private oFont03		:= TFont():New( "Arial"       ,,06,,.f.,,,,,.f. )
	Private oFont04		:= TFont():New( "Arial"       ,,07,,.T.,,,,,.f. )
	Private oFont05		:= TFont():New( "Arial"       ,,09,,.F.,,,,,.f. )
	Private oFont06		:= TFont():New( "Arial"       ,,09,,.T.,,,,,.f. )
	Private oFont07		:= TFont():New( "Arial"       ,,10,,.t.,,,,,.f. )
	Private oFont08		:= TFont():New( "Arial"       ,,12,,.f.,,,,,.f. )
	Private oFont09		:= TFont():New( "Arial"       ,,13,,.T.,,,,,.f. )
	Private oFont10		:= TFont():New( "Arial Black" ,,16,,.t.,,,,,.f. )
	Private oFont11		:= TFont():New( "Arial"       ,,18,,.t.,,,,,.f. )
	Private	oPrn	

	If !Pergunte(cPerg,.T.)
		Return
	Endif


	DbSelectArea ("SA1")
	DbSetOrder(1)               // filial+cod para      CLIENTES
	DbSelectArea ("SA2")
	DbSetOrder(1)               // filial+cod para      FORNECEDORES
	DbSelectArea ("SA4")
	DbSetOrder(1)               // filial+cod para      TRANSPORTADORAS
	DbSelectArea ("SB1")
	DbSetOrder(1)               // filial+cod para      PRODUTOS
	DbSelectArea ("SB2")
	DbSetOrder(1)               // filial+cod para      PRODUTOS
	DbSelectArea ("SC6")
	DbSetOrder(1)
	DbSelectArea ("SC5")
	DbSetOrder(1)
	DbSelectArea ("SC9")
	DbSetOrder(1)
	DbSelectArea ("SA3")
	DbSetOrder(1)


	oPrn := TMSPrinter():New()
	oPrn:Setup()
	oPrn:StartPage()

	cQry :=	""
	cQry += "SELECT C5_NUM,C5_EMISSAO,C5_CONDPAG,C5_CLIENTE,C5_LOJACLI,C5_VEND1,C5_TRANSP"
	cQry += "  FROM " + RetSqlName("SC5") + " C5," + RetSqlName("SC6") + " C6 "
	cQry += " WHERE C6.D_E_L_E_T_ =  ' ' "
	cQry += "   AND C5.D_E_L_E_T_ = ' ' " 
	If MV_PAR06 == 1 // Todos 
		
	ElseIf MV_PAR06 == 2 // Em Aberto  
		cQry += "  AND C6_QTDENT < C6_QTDVEN "
		cQry += "  AND C6_BLQ <> 'R' "
	ElseIf MV_PAR06 == 3 // Faturado
		cQry += "  AND C6_QTDENT > 0 "
	Endif
	cQry += "   AND C6_NUM = C5_NUM "
	cQry += "   AND C6_FILIAL = '" + xFilial("SC6") + "' "
	cQry += "   AND C5_NUM >= '" +mv_par01+ "' "
	cQry += "   AND C5_NUM <= '"+mv_par02+"' "
	cQry += "   AND C5_VEND1 >= '" +mv_par03+ "' "
	cQry += "   AND C5_VEND1 <= '" +mv_par04+ "' "
	cQry += "   AND C5_FILIAL = '" + xFilial("SC5") + "' "
	
	// Criar novas condições para que determinadas usuários possam ver todos os pedidos no relatório 
	/*If __cUserId $ "000130"
		cQry += "   AND COALESCE((SELECT SUM(C9_QTDLIB*C9_PRCVEN)  "  
		cQry += "              FROM " + RetSqlName("SC9") + " SC9 "
		cQry += "             WHERE SC9.D_E_L_E_T_ = ' ' "
		cQry += "   	        AND SC9.C9_PEDIDO = C5_NUM "
		cQry += "   		    AND SC9.C9_NFISCAL = ' ' "
		cQry += "               AND SC9.C9_BLCRED = '  ' "
		cQry += "   	 	    AND SC9.C9_FILIAL = '" + xFilial("SC9") + "' ),0) > 0 "
		cQry += "   AND COALESCE((SELECT SUM(C9_QTDLIB*C9_PRCVEN)   "  
		cQry += "              FROM " + RetSqlName("SC9") + " SC9 "
		cQry += "             WHERE SC9.D_E_L_E_T_ = ' ' "
		cQry += "   	        AND SC9.C9_PEDIDO = C5_NUM "
		cQry += "   		    AND SC9.C9_NFISCAL = ' ' "
		cQry += "               AND SC9.C9_BLCRED <> '  ' "
		cQry += "   		    AND SC9.C9_FILIAL = '" + xFilial("SC9") + "' ),0) = 0 "
	Endif*/
	
	cQry += " GROUP BY C5_NUM,C5_EMISSAO,C5_CONDPAG,C5_CLIENTE,C5_LOJACLI,C5_VEND1,C5_TRANSP"
	cQry += " ORDER BY C5_NUM "
	
	TCQUERY cQry NEW ALIAS "QRC"
	While QRC->(!Eof())
		DbSelectArea ("SA1")
		dbSetOrder(1)
		If DbSeek(xFilial("SA1")+QRC->C5_CLIENTE+QRC->C5_LOJACLI)

			If nContLin > oPrn:nVertRes() -700 .Or. ((!Empty(cNumPed) .Or. nPag > 0) .And.  MV_PAR05 == 1) // Verifica se atingiu limite da página ou quebra página por pedido
				nContLin	:= 20
				oPrn:EndPage()
				nPag++	
				oPrn:StartPage()
			Endif

			cNumPed		:= QRC->C5_NUM
			nSubTot		:= 0
			lFirst		:= .T. // Atualiza o registro de controle para gravação da CB7 
			lGrvCB8		:= .F.
			
			oPrn:Say(nContLin,0420, "ESPELHO DE PEDIDO" ,	oFont08	,100 )
			cLogoD := GetSrvProfString("Startpath","") + "DANFE" + cEmpAnt + cFilAnt + ".BMP"
			If !File(cLogoD)
				cLogoD	:= GetSrvProfString("Startpath","") + "DANFE" + cEmpAnt + ".BMP"
			Endif 
			oPrn:SayBitmap(005,005,cLogoD,195,195)
			
			nContLin += 95

			dbSelectArea ("SC5")
			dbSeek(xFilial("SC5")+QRC->C5_NUM)
			dbSelectArea("SE4")
			dbSeek(xFilial("SE4")+QRC->C5_CONDPAG)
			DbSelectArea ("SA3")
			DbSeek(xFilial("SA3")+QRC->C5_VEND1)	

			oPrn:Say(nContLin,0520	, "Número: " + SC5->C5_NUM  					,	oFont11	, 100 )
			
			//MSBAR3("CODE128",2.8,0.8,cOrdSep,oPr,Nil,Nil,Nil,nWidth,nHeigth,.t.,Nil,"B",Nil,Nil,Nil,.f.)
			
			MSBAR3(	"CODE128"/*cTypeBar*/,;
					00.32/*nRow*/,;
					013/*nCol*/,;
					AllTrim(cNumPed)/*cCode*/,;
					oPrn/*oPrint*/,;
					.F./*lCheck*/,;
					/*Color*/,;
					/*lHorz*/,;
					0.040/*nWidth*/,;
					0.65/*nHeigth*/,;
					/*lBanner*/.T.,;
					/*cFont*/,;
					"B"/*cMode*/,;
					.F./*lPrint*/,;
					/*nPFWidth*/,;
					/*nPFHeigth*/,;
					.F./*lCmtr2Pix*/)
					
			nContLin += 80
			oPrn:Say(nContLin,020	, "Emissão: " + DTOC(SC5->C5_EMISSAO)  			,	oFont08	, 90 )
			//oPrn:Say(nContLin,450	, "Data Programada: " + DTOC(SC5->C5_DTPROGM) 	,	oFont08	, 90 )
			oPrn:Say(nContLin,970	, "Impressão: " + DTOC(Date())				 	,	oFont08	, 90 )
			oPrn:Say(nContLin,1850	, "Cond: " + SE4->E4_CODIGO + "-"+SE4->E4_DESCRI 	,	oFont08	, 90 )

			dbSelectArea ("SA4") //Cad. de Transportadoras
			dbSeek(xFilial("SA4")+QRC->C5_TRANSP)
			nContLin += 80
			oPrn:Say(nContLin,020	, "Transp: " + Substr(SA4->A4_NOME,1,30)+" - "+SA4->A4_COD + "/"+SA4->A4_NREDUZ	,	oFont08	, 90 )

			oPrn:Say(nContLin,1100	, "Tel-Contato: (" + Alltrim(SA1->A1_DDD) + ") " + SA1->A1_TEL + " - " + SA1->A1_CONTATO	,	oFont08	, 100 )

			//oPrn:Say(nContLin,020	, 	,	oFont08	, 100 )
			nContLin += 80
			oPrn:Say(nContLin,020	, AllTrim(SA1->A1_NOME) + " (" + AllTrim(SA1->A1_COD) + "/" + SA1->A1_LOJA  + ")"	,	oFont08	, 100 )

			nContLin += 80
			If Len(Alltrim(SA1->A1_CGC)) == 11
				oPrn:Say(nContLin,020	, Transform(SA1->A1_CGC, "@R 999.999.999-99")	,	oFont08	, 90 )
			Endif
			If LEN(ALLTRIM(SA1->A1_CGC)) == 14
				oPrn:Say(nContLin,020	, Transform(SA1->A1_CGC, "@R 99.999.999/9999-99")	,	oFont08	, 90 )
			Endif
			oPrn:Say(nContLin,490	, "End:" + SA1->A1_END	,	oFont08	, 90 )
			oPrn:Say(nContLin,2020	, "CEP:"+Transform(SA1->A1_CEP,"@R 99999-999")	,	oFont08	, 90 )
			nContLin += 80
			oPrn:Say(nContLin,020	, "Bairro: " + SA1->A1_BAIRRO,	oFont08	, 100 )
			oPrn:Say(nContLin,820	, "Cidade: " + SA1->A1_MUN	,	oFont08	, 100 )
			oPrn:Say(nContLin,2020	, "UF: " + SA1->A1_EST	,	oFont08	, 100 )
			nContLin += 80
			oPrn:Say(nContLin,020	, "Vendedor: " +SA3->A3_NREDUZ,	oFont08	, 100 )

			nContLin += 50
			oPrn:line( nContLin, 0, nContLin+1, oPrn:nHorzRes() )
			oPrn:Say(nContLin,020	, "Item"			,	oFont08	, 95 )
			oPrn:Say(nContLin,120	, "Código"			,	oFont08	, 95 )
			oPrn:Say(nContLin,320	, "Armz - Descrição",	oFont08	, 95 )
			oPrn:Say(nContLin,1020	, "UM"				,	oFont08	, 95 )
			oPrn:Say(nContLin,1150	, "Estoque"			,	oFont08	, 95 )
			oPrn:Say(nContLin,1320	, "Quantidade"		,	oFont08	, 95 )
			oPrn:Say(nContLin,1580	, "Status"			,	oFont08	, 95 )
			oPrn:Say(nContLin,1780	, "R$ Venda"		,	oFont08	, 95 )
			oPrn:Say(nContLin,1990	, "Valor Total"		,	oFont08	, 95 )
			oPrn:Say(nContLin,2200	, "Serial"			,	oFont08	, 95 )
			nContLin += 50
			oPrn:line( nContLin, 0, nContLin+1, oPrn:nHorzRes() )
			nContLin += 50

			nCONTNF   	:= 1
			nItens    	:= 0
			nTotItens 	:= 10
			nCred 		:= 0.00
			nEst  		:= 0.00
			nLib  		:= 0.00
			nTotal		:= 0.00



			cQry := "SELECT C6_ITEM,"
			cQry += "       C6_PRODUTO,"
			cQry += "       C6_LOCAL + ' - ' + B1_DESC AS C6_DESCRI,"
			cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN C9_QTDLIB ELSE C6_QTDVEN-C6_QTDENT END AS C6_QTDVEN,"
			cQry += "       C6_PRCVEN,"
			cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN CASE WHEN C6_QTDVEN = 0 THEN C6_VALOR ELSE (C6_VALOR/C6_QTDVEN)*C9_QTDLIB END ELSE (C6_QTDVEN-C6_QTDENT)*C6_PRCVEN END AS C6_VALOR,"
			cQry += "       B2_QATU-B2_RESERVA+(CASE WHEN C9_BLCRED + C9_BLEST = '    ' THEN C9_QTDLIB ELSE 0 END) SALDOATUAL,"
			cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN C9_SEQUEN ELSE ' ' END C9_SEQUEN, "
			cQry += "       C6_LOTECTL,"
			cQry += "       C6_LOCALIZ,"
			cQry += "       C6_NUMSERI,"
			cQry += "       C6_LOCAL,"
			cQry += "       CASE "
			cQry += "         WHEN C6_BLQ = 'S' AND C9_SEQUEN IS NULL THEN 'Alçada/A Liberar' "
			cQry += "         WHEN C6_BLQ = 'R' AND C9_SEQUEN IS NULL THEN 'Residuo' "
			cQry += "         WHEN C9_SEQUEN IS NULL THEN 'A Liberar' "
			cQry += "         WHEN C9_NFISCAL !=  '  ' THEN 'Faturado' "
			cQry += "         WHEN C9_BLCRED NOT IN('  ','10') AND C9_BLEST NOT IN('  ','10') THEN 'Crédito/Estoque' "
			cQry += "         WHEN C9_BLCRED NOT IN('  ','10') THEN 'Crédito' "
			cQry += "         WHEN C9_BLEST NOT IN('  ','10') THEN 'Estoque' "
			cQry += "        ELSE "
			cQry += "         'Ok' "
			cQry += "        END AS STATUS "
			cQry += "  FROM "+RetSqlName("SC6")+ " C6 "
			cQry += " INNER JOIN "+RetSqlName("SB2") + " B2 " 
			cQry += "    ON B2.D_E_L_E_T_ =' ' "
			cQry += "   AND B2_LOCAL = C6_LOCAL "
			cQry += "   AND B2_COD = C6_PRODUTO "
			cQry += "   AND B2_FILIAL = '"+xFilial("SB2") + "' "
			cQry += " INNER JOIN " + RetSqlName("SB1")+" B1 "
			cQry += "    ON B1.D_E_L_E_T_ = ' ' "
			cQry += "   AND B1_COD = C6_PRODUTO "
			cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
			cQry += "  LEFT JOIN " + RetSqlName("SC9") + " C9 "
			cQry += "    ON C9.D_E_L_E_T_ = ' ' "
			cQry += "   AND C9_ITEM = C6_ITEM "
			cQry += "   AND C9_PRODUTO = C6_PRODUTO "
			cQry += "   AND C9_PEDIDO = C6_NUM "
			cQry += "   AND C9_FILIAL = '"+xFilial("SC9")+"' "
			cQry += " WHERE C6.D_E_L_E_T_ =' ' "
			cQry += "   AND C6_NUM = '"+QRC->C5_NUM+"' "
			cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
			cQry += "UNION "
			cQry += "SELECT C6_ITEM,"
			cQry += "       C6_PRODUTO,"
			cQry += "       C6_LOCAL + ' - ' + B1_DESC AS C6_DESCRI,"
			cQry += "       C6_QTDVEN - C6_QTDENT - C6_QTDEMP AS C6_QTDVEN,"
			cQry += "       C6_PRCVEN,"
			cQry += "       (C6_QTDVEN - C6_QTDENT - C6_QTDEMP )* C6_PRCVEN AS C6_VALOR,"
			cQry += "       B2_QATU-B2_RESERVA SALDOATUAL,"
			cQry += "       ' ' C9_SEQUEN, "
			cQry += "       C6_LOTECTL,"
			cQry += "       C6_LOCALIZ,"
			cQry += "       C6_NUMSERI,"
			cQry += "       C6_LOCAL,"
			cQry += "       CASE "
			cQry += "         WHEN C6_BLQ = 'S' THEN 'Alçada/A Liberar' "
			cQry += "         WHEN C6_BLQ = 'R' THEN 'Residuo' "
			cQry += "        ELSE "
			cQry += "         'A Liberar' "
			cQry += "        END AS STATUS "				
			cQry += "  FROM "+RetSqlName("SC6")+ " C6, "+RetSqlName("SB2") + " B2,"+RetSqlName("SB1")+" B1 "
			cQry += " WHERE B2.D_E_L_E_T_ =' ' "
			cQry += "   AND B2_LOCAL = C6_LOCAL "
			cQry += "   AND B2_COD = C6_PRODUTO "
			cQry += "   AND B2_FILIAL = '"+xFilial("SB2") + "' "
			cQry += "   AND B1.D_E_L_E_T_ = ' ' "
			cQry += "   AND B1_COD = C6_PRODUTO "
			cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
			cQry += "   AND C6_QTDVEN > COALESCE((SELECT SUM(C9_QTDLIB) "
			cQry += "                          FROM "+RetSqlName("SC9")  + " C9 "
			cQry += "                  	      WHERE D_E_L_E_T_ = ' ' "
			cQry += "                           AND C9_ITEM = C6_ITEM "
			cQry += "                           AND C9_PRODUTO = C6_PRODUTO "
			cQry += "                           AND C9_PEDIDO = C6_NUM "
			cQry += "                           AND C9_FILIAL = '"+xFilial("SC9")+"'),0) "
			cQry += "   AND C6_QTDENT < C6_QTDVEN "
			cQry += "   AND C6.D_E_L_E_T_ =' ' "
			cQry += "   AND C6_NUM = '"+QRC->C5_NUM+"' "
			cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
			cQry += " ORDER BY C6_ITEM,C9_SEQUEN "

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRY', .F., .T.)	

			While !Eof()

				DbSelectArea ("SB1") //Descricao do produto
				DbSeek(xFilial("SB1")+QRY->C6_PRODUTO)   // PRODUTO
				DbSelectArea ("SB2") //Descricao do produto
				DbSeek(xFilial("SB2")+QRY->C6_PRODUTO + "01")   // ESTOQUE
				DbSelectArea ("SC9")
				DbSeek(xFilial("SC9")+QRC->C5_NUM+QRY->C6_ITEM+QRY->C9_SEQUEN)  

				oPrn:Say(nContLin,020	, QRY->C6_ITEM			,	oFont08	, 100 )
				oPrn:Say(nContLin,120	, QRY->C6_PRODUTO		,	oFont08	, 100 )
				oPrn:Say(nContLin,320	, Substr(QRY->C6_DESCRI,1,25),	oFont08	, 100 )
				oPrn:Say(nContLin,1020	, SB1->B1_UM		    ,	oFont08	, 100 )
				oPrn:Say(nContLin,1150	, Transform(QRY->SALDOATUAL,"@E 99,999.999")	,	oFont08	, 100 )
				oPrn:Say(nContLin,1350	, Transform(QRY->C6_QTDVEN,"@E 99,999.999")		,	oFont08	, 100 )
				oPrn:Say(nContLin,1580	, QRY->STATUS			,	oFont08	, 100 )

				oPrn:Say(nContLin,1750	, Transform(QRY->C6_PRCVEN ,"@E 999,999.99")	,	oFont08	, 100 )
				oPrn:Say(nContLin,1990	, Transform(QRY->C6_VALOR  ,"@E 999,999.99")	,	oFont08	, 100 )
				nSubTot		+= QRY->C6_VALOR
				
				nSldSB8		:= 0
				nContSB8	:= 0
				cImpLtSB8	:= ""

				If Empty(QRY->C6_NUMSERI)
					/*
					cQry := "SELECT B8_DTVALID,B8_SALDO,B8_LOTECTL,B8_DFABRIC "
					cQry += "  FROM " + RetSqlName("SB8") + " B8 " 
					cQry += " WHERE D_E_L_E_T_ =' ' " 
					cQry += "   AND B8_PRODUTO = '" + QRY->C6_PRODUTO + "' "
					cQry += "   AND B8_FILIAL = '" + xFilial("SB8") + "'
					cQry += "   AND B8_LOCAL ='" + QRY->C6_LOCAL + "'"
					cQry += "   AND B8_SALDO > 0 "
					If SA1->A1_XPRLOTE = "U" // UEPS 
						cQry += " ORDER BY B8_DFABRIC DESC "
					Else
						cQry += " ORDER BY B8_DFABRIC "
					Endif 

					TcQuery cQry New Alias "QSB8" 

					While !Eof()
						If nContSB8 == 1
							cImpLtSB8	:= Alltrim(QSB8->B8_LOTECTL)
						Else
							If nSldSB8 < QRY->C6_QTDVEN
								cImpLtSB8	+= "|" + Alltrim(QSB8->B8_LOTECTL)
							Endif
						Endif
						nSldSB8	+= QSB8->B8_SALDO
						nContSB8++
						QSB8->(DbSkip())
					Enddo
					QSB8->(DbCloseArea())
					*/
				Else
					cImpLtSB8	:= QRY->C6_NUMSERI
					nContSB8	:= QRY->C6_QTDVEN
				Endif
				If nContSB8 > 0 
					oPrn:Say(nContLin,2200	, cImpLtSB8	,	oFont08	, 100 )
				Endif

				nItens := nItens+1
				nTotal += QRY->C6_VALOR

				// Verifico se já foi gravada uma Ordem de Separação para o Pedido
				DbSelectArea("CB7")
				DbSetOrder(2) // CB7_FILIAL+CB7_PEDIDO+CB7_LOCAL+CB7_STATUS+CB7_CLIENT+CB7_LOJA
				If DbSeek(xFilial("CB7")+SC5->C5_NUM+QRY->C6_LOCAL  )
					lGrvCB8	:= .F. 
					If Empty(QRY->C6_LOTECTL)
						DbSelectArea("CB7")
						RecLock("CB7",.F.)
						CB7->CB7_VOLEMI		:= "0"					// Volume Emitido		0=Nao;1=Sim
						MsUnlock()
					Endif
				Else
					If lFirst
						// Atualiza a sequencia correta do SC5 no SXE e SXF,
						DbSelectArea("CB7")
						DbSetOrder(1)
						Do While .T.
							cNewOrdSep := GetSxeNum("CB7","CB7_ORDSEP")
							If dbSeek( xFilial( "CB7" ) + cNewOrdSep )

							Else
								Exit
							EndIf
							If __lSx8
								ConfirmSx8()
							EndIf
						EndDo

						DbSelectArea("CB7")
						RecLock("CB7",.T.)
						CB7->CB7_FILIAL 	:= xFilial("CB7")
						CB7->CB7_ORDSEP 	:= cNewOrdSep    		// Numero Ordem
						CB7->CB7_PEDIDO		:= SC5->C5_NUM			// Pedido Venda
						CB7->CB7_CLIENT		:= SC5->C5_CLIENTE		// Cliente
						CB7->CB7_LOJA		:= SC5->C5_LOJACLI		// Loja Cliente
						CB7->CB7_LOJENT		:= SC5->C5_LOJAENT		// Loja Entrega
						CB7->CB7_DTEMIS		:= dDatabase			// Data Emissão
						CB7->CB7_LOCAL		:= QRY->C6_LOCAL		// Armazém
						CB7->CB7_HREMIS		:= Time()			    // Hora Emissão
						CB7->CB7_STATUS		:= "0"				 	// Status 				0-Inicio;1-Separando;2-Sep.Final;3-Embalando;4-Emb.Final;5-Gera Nota;6-Imp.nota;7-Imp.Vol;8-Embarcado;9-Embarque Finalizado
						CB7->CB7_ORIGEM		:= "1"					// Origem separação		1=Pedido;2=Nota Fiscal;3=Producao
						CB7->CB7_TIPEXP		:= "00-Separacao"		// Tipo Expedição		00-Separcao,01-Separacao/Embalagem,02-Embalagem,03-Gera Nota 04-embarque
						CB7->CB7_TRANSP		:= SC5->C5_TRANSP		// Transportadora
						CB7->CB7_COND		:= SC5->C5_CONDPAG		// Condição Pagamento
						CB7->CB7_VOLEMI		:= "0"					// Volume Emitido		0=Nao;1=Sim
						CB7->CB7_PRIORI		:= "9"
						MsUnlock()
						lGrvCB8		:= .T.
						lFirst		:= .F.
						// Coloca no Pedido de Venda o número da ordem de separação
						DbSelectArea("SC5")
						RecLock("SC5",.F.)
						SC5->C5_COTACAO 	:= cNewOrdSep
						MsUnlock()
						
						
				
						// Grava Log da Geração da Nota 
						U_MLCFGM01("IM",SC5->C5_NUM,"Impressão de Pedido / Ordem Separação  "+ cNewOrdSep ,FunName())
					Endif
				Endif	
				If lGrvCB8
					DbSelectArea("CB8")
					RecLock("CB8",.T.)
					CB8->CB8_FILIAL		:= xFilial("CB8")
					CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
					CB8->CB8_ITEM		:= 	QRY->C6_ITEM		// Item Pedido
					CB8->CB8_SEQUEN		:= 	QRY->C9_SEQUEN		// Sequencia
					CB8->CB8_PEDIDO		:= 	SC5->C5_NUM			// Pedido de Venda
					CB8->CB8_PROD		:= 	QRY->C6_PRODUTO		// Código Produto
					CB8->CB8_LOCAL		:= 	QRY->C6_LOCAL		// Armazém
					CB8->CB8_QTDORI		:= 	QRY->C6_QTDVEN		// Quantidade Original
					CB8->CB8_SALDOS		:=  QRY->C6_QTDVEN		// Saldo a Separar
					CB8->CB8_SALDOE		:= 	QRY->C6_QTDVEN		// Saldo a embalar
					CB8->CB8_SEQUEN		:= 	"01"				// Sequencia
					CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
					CB8->CB8_LCALIZ		:= QRY->C6_LOCALIZ		// Endereço
					//CB8->CB8_LOTECT		:= ""				// Lote
					CB8->CB8_NUMSER		:= QRY->C6_NUMSERI		// Numero de Série
					MsUnlock()
					// Atualiza total de itens a separar
					DbSelectArea ("SC9")
					If DbSeek(xFilial("SC9")+QRC->C5_NUM+QRY->C6_ITEM+QRY->C9_SEQUEN)   // ESTOQUE
						RecLock("SC9",.F.)
						SC9->C9_ORDSEP	:= cNewOrdSep
						MsUnlock()
					Endif
					DbSelectArea("CB7")
					DbSetOrder(2) // CB7_FILIAL+CB7_PEDIDO+CB7_LOCAL+CB7_STATUS+CB7_CLIENT+CB7_LOJA
					If DbSeek(xFilial("CB7")+SC5->C5_NUM+QRY->C6_LOCAL  )
						DbSelectArea("CB7")
						RecLock("CB7",.F.)
						CB7->CB7_NUMITE   += 1
						MsUnlock()
					Endif
				Endif
				If nContLin > oPrn:nVertRes() -100
					nContLin	:= 20
					oPrn:EndPage()
					nPag++	
					oPrn:StartPage()
				Endif

				If Len(Alltrim(QRY->C6_DESCRI)) > 25 
					nContLin += 50
					oPrn:Say(nContLin,320	, Substr(QRY->C6_DESCRI,26,25),	oFont08	, 100 )
				Endif
				If Len(Alltrim(QRY->C6_DESCRI)) > 50
					nContLin += 50
					oPrn:Say(nContLin,320	, Substr(QRY->C6_DESCRI,51,25),	oFont08	, 100 )
				Endif
				nContLin += 50
				oPrn:line( nContLin, 0, nContLin+1, oPrn:nHorzRes() )


				dbSelectArea("QRY")
				dbSkip()
			Enddo

			QRY->(DbCloseArea())
			
			nContLin += 50
			oPrn:Say(nContLin,0020	, "Valor do Frete " + Transform(SC5->C5_FRETE  ,"@E 999,999.99")	,	oFont08	, 100 )
			oPrn:Say(nContLin,1580	, "Total dos Produtos " + Transform(nSubTot  ,"@E 999,999.99")	,	oFont08	, 100 )
			nContLin += 50			
			oPrn:Say(nContLin,1580	, "Total do Pedido " + Transform(nSubTot+SC5->C5_FRETE  ,"@E 999,999.99")	,	oFont08	, 100 )
		
			
			cMsgInt		:= Alltrim(SC5->C5_ZMSGINT)
			cMsgInt		:= StrTran(cMsgInt,Chr(13)," ")
			cMsgInt		:= StrTran(cMsgInt,Chr(10)," ")
			cMsgNota	:= Alltrim(SC5->C5_MENNOTA)
			//cMsgNota 	+= IIf(Empty(SC5->C5_XPEDCLI),"", Alltrim("Ordem Compra: "+SC5->C5_XPEDCLI))
			dbSelectArea("SA1")
			cObsCli		:= Alltrim(MSMM(SA1->A1_OBS,60))
			oObsInt		+= Alltrim(SA1->A1_PRF_OBS)
			oObsInt		:= StrTran(oObsInt,Chr(13)," ")
			oObsInt		:= StrTran(oObsInt,Chr(10)," ")
			
			For nZ := 1 To Len(cMsgInt) Step 75
				nContLin += 50
				If nZ == 1
					oPrn:Say(nContLin,050	, "Msg.Interna: " + Substr(cMsgInt,nZ,75)	,	oFont08	, 100 )
				Else
					oPrn:Say(nContLin,050	, Substr(cMsgInt,nZ,75)	,	oFont08	, 100 )
				Endif
			
			Next
			
			For nZ := 1 To Len(cMsgNota) Step 75
				nContLin += 50
				If nZ == 1
					oPrn:Say(nContLin,050	, "Msg.Nota: " + Substr(cMsgNota,nZ,75)	,	oFont08	, 100 )
				Else
					oPrn:Say(nContLin,050	, Substr(cMsgNota,nZ,75)	,	oFont08	, 100 )
				Endif
			
			Next
			
			For nZ := 1 To Len(cObsCli) Step 75
				nContLin += 50
				If nZ == 1
					oPrn:Say(nContLin,050	,  "Msg Cliente p/Nf: " + Substr(cObsCli,nZ,75)	,	oFont08	, 100 )
				Else
					oPrn:Say(nContLin,050	, Substr(cObsCli,nZ,75)	,	oFont08	, 100 )
				Endif
			
			Next
			
			For nZ := 1 To Len(oObsInt) Step 75
				nContLin += 50
				If nZ == 1
					oPrn:Say(nContLin,050	,  "Obs.Int.Cliente: " + Substr(oObsInt,nZ,75)	,	oFont08	, 100 )
				Else
					oPrn:Say(nContLin,050	, Substr(oObsInt,nZ,75)	,	oFont08	, 100 )
				Endif
			
			Next
			
			
			nContLin += 350

		Endif
		QRC->(DbSkip())
	Enddo
	QRC->(DbCloseArea())		

	oPrn:EndPage()

	oPrn:Preview()
	MS_Flush()

Return
