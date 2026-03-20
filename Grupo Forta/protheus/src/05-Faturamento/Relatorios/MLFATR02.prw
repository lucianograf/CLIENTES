#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'
#include 'colors.ch'

/*/{Protheus.doc} MLFATR02
// Relatório de impressão de Nota Fiscal para Expedição
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}
@type User Function
/*/
User function MLFATR02(aInParam,lGeraCB7)

	Local	cQry
	Local	lGrvCB8		:= .T.
	Local	lFirst		:= .T.
	Local	nContLin	:= 020
	Local	nCONTNF   	:= 1
	Local	nItens    	:= 0
	Local	nTotItens 	:= 10
	Local	nCred 		:= 0.00
	Local	nEst  		:= 0.00
	Local	nLib  		:= 0.00
	Local	nTotal		:= 0.00
	Local	nPag		:= 0
	Local	cNumNf		:= ""
	Local	cMsgInt		:= ""
	Local	cMsgNota	:= ""
	Local	cObsCli		:= ""
	Local	oObsInt		:= ""
	Local	nZ
	Local	nSldSB8		:= 0
	Local	nContSB8	:= 0
	Local	cImpLtSB8	:= ""
	Local 	lCxFechada	:= .T.
	Local 	nSumVolumes	:= 0
	Private	cPerg		:= "MLFATR02"
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

	Default	aInParam	:= {}
	Default lGeraCB7	:= .F.

	sfValPerg()

	// Verifica que houve chamada automática da rotina
	If Len(aInParam) >= 7

		U_GRAVASX1(cPerg, "01", aInParam[1])
		U_GRAVASX1(cPerg, "02", aInParam[2])
		U_GRAVASX1(cPerg, "03", aInParam[3])
		U_GRAVASX1(cPerg, "04", aInParam[4])
		U_GRAVASX1(cPerg, "05", aInParam[5])
		U_GRAVASX1(cPerg, "06", aInParam[6])
		U_GRAVASX1(cPerg, "07", aInParam[7])

		Pergunte(cPerg,.F.)
	Else
		If !Pergunte(cPerg,.T.)
			Return
		Endif
	Endif


	oPrn := TMSPrinter():New()
	oPrn:Setup()
	oPrn:StartPage()
	/*
	MV_PAR01 - Serie Nota
	MV_PAR02 - Nota Inicial
	MV_PAR03 - Nota Final 
	MV_PAR04 - Vendedor Inicial
	MV_PAR05 - Vendedor Final
	MV_PAR06 - Emissao Inicial
	MV_PAR07 - Emissao Final 
	MV_PAR08 - Quebra página por nota 
	*/
	cQry :=	""
	cQry += "SELECT F2_DOC,F2_SERIE,F2_EMISSAO,F2_COND,F2_CLIENTE,F2_LOJA,F2_VEND1,F2_TRANSP,F2_TIPO"
	cQry += "  FROM " + RetSqlName("SF2") + " F2 " //+ RetSqlName("SD2") + " D2 "
	cQry += " WHERE F2_EMISSAO <= '" + DTOS(MV_PAR07)+ "'"
	cQry += "   AND F2_EMISSAO >= '" + DTOS(MV_PAR06)+ "'"
	cQry += "   AND F2.D_E_L_E_T_ =' ' "
	cQry += "   AND F2_DOC >= '" +mv_par02+ "' "
	cQry += "   AND F2_DOC <= '"+mv_par03+"' "
	cQry += "   AND F2_VEND1 >= '" +mv_par04+ "' "
	cQry += "   AND F2_VEND1 <= '" +mv_par05+ "' "
	cQry += "   AND F2_SERIE = '" + MV_PAR01 + "'"
	cQry += "   AND F2_TIPO IN('D','B','N') "
	cQry += "   AND F2_FILIAL = '" + xFilial("SF2") + "' "
	If FwIsInCallStack("U_MLFATA05") .And. Type("aRecSF2") == "A" .And. Len(aRecSF2) > 0
		cQry += " AND F2.R_E_C_N_O_  IN("

		For nZ  := 1 To Len(aRecSF2)
			If nZ  > 1
				cQry += ","
			Endif
			cQry += cValToChar(aRecSF2[nZ])
		Next
		cQry += ") "
	Endif
	cQry += " GROUP BY F2_DOC,F2_SERIE,F2_EMISSAO,F2_COND,F2_CLIENTE,F2_LOJA,F2_VEND1,F2_TRANSP,F2_TIPO"
	cQry += " ORDER BY F2_DOC "

	TCQUERY cQry NEW ALIAS "QRC"

	While QRC->(!Eof())

		If QRC->F2_TIPO == "N"
			DbSelectArea ("SA1")
			dbSetOrder(1)
			If DbSeek(xFilial("SA1")+QRC->F2_CLIENTE+QRC->F2_LOJA)

				If nContLin > oPrn:nVertRes() -700 .Or. ((!Empty(cNumNf) .Or. nPag > 0) .And.  MV_PAR08 == 1) // Verifica se atingiu limite da página ou quebra página por pedido
					nContLin	:= 20
					oPrn:EndPage()
					nPag++
					oPrn:StartPage()
				Endif

				cNumNf		:= QRC->F2_DOC
				lFirst		:= .T. // Atualiza o registro de controle para gravação da CB7
				lGrvCB8		:= .F.

				oPrn:Say(nContLin,0220, "ESPELHO DE NOTA FISCAL PARA SEPARAÇÃO " ,	oFont08	,100 )



				nContLin += 65

				dbSelectArea("SE4")
				dbSeek(xFilial("SE4")+QRC->F2_COND)
				DbSelectArea ("SA3")
				DbSeek(xFilial("SA3")+QRC->F2_VEND1)

				oPrn:Say(nContLin,0520	, "Num.NF: " + QRC->F2_DOC							,	oFont11	, 100 )

				//MSBAR3("CODE128",2.8,0.8,cOrdSep,oPr,Nil,Nil,Nil,nWidth,nHeigth,.t.,Nil,"B",Nil,Nil,Nil,.f.)

				MSBAR3(	"CODE128"/*cTypeBar*/,;
					00.32/*nRow*/,;
					013/*nCol*/,;
					AllTrim(cNumNf)/*cCode*/,;
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
				oPrn:Say(nContLin,020	, "Emissão: " + DTOC(STOD(QRC->F2_EMISSAO))  			,	oFont08	, 90 )
				//oPrn:Say(nContLin,450	, "Data Programada: " + DTOC(SC5->C5_DTPROGM) 	,	oFont08	, 90 )
				oPrn:Say(nContLin,970	, "Impressão: " + DTOC(Date())				 	,	oFont08	, 90 )
				oPrn:Say(nContLin,1850	, "Cond: " + SE4->E4_CODIGO + "-"+SE4->E4_DESCRI 	,	oFont08	, 90 )

				dbSelectArea ("SA4") //Cad. de Transportadoras
				DbSetOrder(1)
				dbSeek(xFilial("SA4")+QRC->F2_TRANSP)
				nContLin += 80
				oPrn:Say(nContLin,020	, "Transp: " + Substr(SA4->A4_NOME,1,30)+" - "+SA4->A4_COD + "/"+SA4->A4_NREDUZ	,	oFont08	, 90 )

				oPrn:Say(nContLin,1850	, "Tel-Contato: (" + Alltrim(SA1->A1_DDD) + ") " + SA1->A1_TEL + " - " + SA1->A1_CONTATO	,	oFont08	, 100 )

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
				oPrn:Say(nContLin,1580	, "Endereço"		,	oFont08	, 95 )
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
				lCxFechada	:= .T.
				nSumVolumes	:= 0


				cQry := "SELECT D2_ITEM,"
				cQry += "       D2_COD,"
				cQry += "       D2_LOCAL + ' - ' + B1_DESC AS B1_DESCRI,"
				cQry += "       D2_QUANT,"
				cQry += "       D2_PRCVEN,"
				cQry += "       D2_TOTAL,"
				cQry += "       D2_LOTECTL,"
				cQry += "       D2_LOCALIZ,"
				cQry += "       D2_NUMSERI,"
				cQry += "       D2_LOCAL,"
				cQry += "       B1_UM,"
				cQry += "       B1_XLOCAL,"
				cQry += "       D2_PEDIDO,"
				cQry += "       D2_NUMSEQ,"
				cQry += "		B1_XMIUDEZ,"
				cQry += "       B1_XCONVB"
				cQry += "  FROM "+RetSqlName("SD2")+ " D2 "
				cQry += " INNER JOIN " + RetSqlName("SB1")+" B1 "
				cQry += "    ON B1.D_E_L_E_T_ = ' ' "
				cQry += "   AND B1_COD = D2_COD "
				cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
				cQry += " WHERE D2.D_E_L_E_T_ =' ' "
				cQry += "   AND D2_LOJA = '"+QRC->F2_LOJA+"' "
				cQry += "   AND D2_CLIENTE = '"+QRC->F2_CLIENTE+"' "
				cQry += "   AND D2_SERIE = '"+QRC->F2_SERIE+"' "
				cQry += "   AND D2_DOC = '"+QRC->F2_DOC+"' "
				cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
				cQry += " ORDER BY B1_XLOCAL,D2_ITEM "

				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRY', .F., .T.)

				While !Eof()

					// Se o produto for miudeza ou tiver controle de serial
					If QRY->B1_XMIUDEZ == "S" .Or. Localiza(QRY->D2_COD)
						lCxFechada 	:= .F.
					// Se o produto não for miudeza mas tiver fração de divisão 
					ElseIf QRY->B1_XMIUDEZ == "N" .And. Mod(QRY->D2_QUANT, IIf(QRY->B1_XCONVB==0,1,QRY->B1_XCONVB)) > 0  
						lCxFechada 	:= .F.
					ElseIf QRY->B1_XMIUDEZ == "X"  // Produto que não tem conferência Fisica ( Licença Software )
						// Não altera vairável de caixa Fechada e nem soma volumes 
					Else
						nSumVolumes += (QRY->D2_QUANT / IIf(QRY->B1_XCONVB==0,1,QRY->B1_XCONVB)  )
					Endif 


					oPrn:Say(nContLin,020	, QRY->D2_ITEM			,	oFont08	, 100 )
					oPrn:Say(nContLin,120	, QRY->D2_COD		,	oFont08	, 100 )
					oPrn:Say(nContLin,320	, Substr(QRY->B1_DESCRI,1,25),	oFont08	, 100 )
					oPrn:Say(nContLin,1020	, QRY->B1_UM		    ,	oFont08	, 100 )
					//oPrn:Say(nContLin,1150	, Transform(QRY->SALDOATUAL,"@E 99,999.999")	,	oFont08	, 100 )
					oPrn:Say(nContLin,1350	, Transform(QRY->D2_QUANT,"@E 99,999.999")		,	oFont08	, 100 )
					oPrn:Say(nContLin,1580	, Transform(QRY->B1_XLOCAL,"@R 99.99.9.X")		,	oFont08	, 100 )

					oPrn:Say(nContLin,1750	, Transform(QRY->D2_PRCVEN ,"@E 999,999.99")	,	oFont08	, 100 )
					oPrn:Say(nContLin,1990	, Transform(QRY->D2_TOTAL  ,"@E 999,999.99")	,	oFont08	, 100 )




					nItens := nItens+1
					nTotal += QRY->D2_TOTAL

					If lGeraCB7
						// Verifico se já foi gravada uma Ordem de Separação para o Pedido
						DbSelectArea("CB7")
						DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
						If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
							lGrvCB8	:= .F.
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
								CB7->CB7_PEDIDO		:= QRY->D2_PEDIDO		// Pedido Venda
								CB7->CB7_CLIENT		:= QRC->F2_CLIENTE		// Cliente
								CB7->CB7_LOJA		:= QRC->F2_LOJA			// Loja Cliente
								CB7->CB7_LOJENT		:= QRC->F2_LOJA			// Loja Entrega
								CB7->CB7_DTEMIS		:= Date()				// Data Emissão
								CB7->CB7_LOCAL		:= QRY->D2_LOCAL		// Armazém
								CB7->CB7_HREMIS		:= Time()			    // Hora Emissão
								CB7->CB7_STATUS		:= "0"				 	// Status 				0-Inicio;1-Separando;2-Sep.Final;3-Embalando;4-Emb.Final;5-Gera Nota;6-Imp.nota;7-Imp.Vol;8-Embarcado;9-Embarque Finalizado
								CB7->CB7_ORIGEM		:= "1"					// Origem separação		1=Pedido;2=Nota Fiscal;3=Producao
								CB7->CB7_TIPEXP		:= "00-Separacao"		// Tipo Expedição		00-Separcao,01-Separacao/Embalagem,02-Embalagem,03-Gera Nota 04-embarque
								CB7->CB7_TRANSP		:= QRC->F2_TRANSP		// Transportadora
								CB7->CB7_COND		:= QRC->F2_COND			// Condição Pagamento
								CB7->CB7_VOLEMI		:= "0"					// Volume Emitido		0=Nao;1=Sim
								CB7->CB7_PRIORI		:= "9"
								CB7->CB7_NOTA		:= QRC->F2_DOC			// NF de Saída
								CB7->CB7_SERIE		:= QRC->F2_SERIE		// Seria da NF
								MsUnlock()
								lGrvCB8		:= .T.
								lFirst		:= .F.

								// Grava Log da Geração da Nota
								U_MLCFGM01("IM",QRY->D2_PEDIDO,"Impressão de Nota / Ordem Separação  "+ cNewOrdSep ,FunName())
							Endif
						Endif
						nSldSB8		:= 0
						nContSB8	:= 0
						cImpLtSB8	:= ""

						DbSelectArea("CB8")
						DbSetOrder(5) 	//CB8_FILIAL+CB8_NOTA+CB8_SERIE+CB8_ITEM+CB8_SEQUEN+CB8_PROD
						If DbSeek(xFilial("CB8") + QRC->F2_DOC + QRC->F2_SERIE + QRY->D2_ITEM )

						Else
							If Empty(QRY->D2_NUMSERI) .And. Empty(QRY->D2_LOCALIZ)
								nSldSB8		:= 0
								nContSB8	:= 0
								cImpLtSB8	:= ""
								cQry := "SELECT DB_NUMSERI,DB_QUANT,DB_LOCALIZ "
								cQry += "  FROM " + RetSqlName("SDB") + " DB "
								cQry += " WHERE D_E_L_E_T_ =' ' "
								cQry += "   AND DB_ESTORNO = ' ' "
								cQry += "   AND DB_NUMSEQ = '" + QRY->D2_NUMSEQ + "' "
								cQry += "   AND DB_LOCAL ='" + QRY->D2_LOCAL + "'"
								cQry += "   AND DB_LOJA = '" + QRC->F2_LOJA + "'"
								cQry += "   AND DB_CLIFOR = '" + QRC->F2_CLIENTE + "'"
								cQry += "   AND DB_SERIE = '" + QRC->F2_SERIE + "'"
								cQry += "   AND DB_DOC = '" + QRC->F2_DOC + "' "
								cQry += "   AND DB_PRODUTO = '" + QRY->D2_COD + "' "
								cQry += "   AND DB_FILIAL = '" + xFilial("SDB") + "'

								TcQuery cQry New Alias "QSDB"

								If Eof()
									DbSelectArea("CB8")
									RecLock("CB8",.T.)
									CB8->CB8_FILIAL		:= xFilial("CB8")
									CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
									CB8->CB8_ITEM		:= 	QRY->D2_ITEM		// Item Pedido
									CB8->CB8_PEDIDO		:= 	QRY->D2_PEDIDO		// Pedido de Venda
									CB8->CB8_PROD		:= 	QRY->D2_COD			// Código Produto
									CB8->CB8_LOCAL		:= 	QRY->D2_LOCAL		// Armazém
									CB8->CB8_QTDORI		:= 	QRY->D2_QUANT		// Quantidade Original
									CB8->CB8_SALDOS		:=  QRY->D2_QUANT		// Saldo a Separar
									CB8->CB8_SALDOE		:= 	QRY->D2_QUANT		// Saldo a embalar
									CB8->CB8_SEQUEN		:= 	"01"				// Sequencia
									CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
									CB8->CB8_LCALIZ		:=  QRY->D2_LOCALIZ		// Endereço
									CB8->CB8_NOTA		:=  QRC->F2_DOC			// NF de Saída
									CB8->CB8_SERIE		:=  QRC->F2_SERIE		// Seria da NF
									//CB8->CB8_LOTECT		:= ""				// Lote
									CB8->CB8_NUMSER		:=  QRY->D2_NUMSERI		// Numero de Série
									MsUnlock()
									// Verifico se já foi gravada uma Ordem de Separação para o Pedido
									DbSelectArea("CB7")
									DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
									If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
										DbSelectArea("CB7")
										RecLock("CB7",.F.)
										CB7->CB7_NUMITE   += 1
										MsUnlock()
									Endif
								Else
									While !Eof()
										If nContSB8 == 1
											cImpLtSB8	:= Alltrim(QSDB->DB_NUMSERI) + "=" + cValToChar(QSDB->DB_QUANT)
										Else
											If nSldSB8 < QRY->D2_QUANT
												cImpLtSB8	+= "|" + Alltrim(QSDB->DB_NUMSERI) + "=" + cValToChar(QSDB->DB_QUANT)
											Endif
										Endif
										nSldSB8	+= QSDB->DB_QUANT
										nContSB8++
										DbSelectArea("CB8")
										RecLock("CB8",.T.)
										CB8->CB8_FILIAL		:= xFilial("CB8")
										CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
										CB8->CB8_ITEM		:= 	QRY->D2_ITEM		// Item Pedido
										CB8->CB8_PEDIDO		:= 	QRY->D2_PEDIDO		// Pedido de Venda
										CB8->CB8_PROD		:= 	QRY->D2_COD			// Código Produto
										CB8->CB8_LOCAL		:= 	QRY->D2_LOCAL		// Armazém
										CB8->CB8_QTDORI		:= 	QSDB->DB_QUANT		// Quantidade Original
										CB8->CB8_SALDOS		:=  QSDB->DB_QUANT		// Saldo a Separar
										CB8->CB8_SALDOE		:= 	QSDB->DB_QUANT		// Saldo a embalar
										CB8->CB8_SEQUEN		:= 	StrZero(nContSB8,2)	// Sequencia
										CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
										CB8->CB8_LCALIZ		:= QSDB->DB_LOCALIZ		// Endereço
										CB8->CB8_NOTA		:= QRC->F2_DOC			// NF de Saída
										CB8->CB8_SERIE		:= QRC->F2_SERIE		// Seria da NF
										//CB8->CB8_LOTECT		:= ""				// Lote
										CB8->CB8_NUMSER		:= QSDB->DB_NUMSERI		// Numero de Série
										MsUnlock()
										// Verifico se já foi gravada uma Ordem de Separação para o Pedido
										DbSelectArea("CB7")
										DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
										If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
											DbSelectArea("CB7")
											RecLock("CB7",.F.)
											CB7->CB7_NUMITE   += 1
											MsUnlock()
										Endif
										QSDB->(DbSkip())
									Enddo
								Endif
								QSDB->(DbCloseArea())

							Else
								cImpLtSB8	:= QRY->D2_NUMSERI
								nContSB8	:= 1
								DbSelectArea("CB8")
								RecLock("CB8",.T.)
								CB8->CB8_FILIAL		:= xFilial("CB8")
								CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
								CB8->CB8_ITEM		:= 	QRY->D2_ITEM		// Item Pedido
								CB8->CB8_PEDIDO		:= 	QRY->D2_PEDIDO		// Pedido de Venda
								CB8->CB8_PROD		:= 	QRY->D2_COD			// Código Produto
								CB8->CB8_LOCAL		:= 	QRY->D2_LOCAL		// Armazém
								CB8->CB8_QTDORI		:= 	QRY->D2_QUANT		// Quantidade Original
								CB8->CB8_SALDOS		:=  QRY->D2_QUANT		// Saldo a Separar
								CB8->CB8_SALDOE		:= 	QRY->D2_QUANT		// Saldo a embalar
								CB8->CB8_SEQUEN		:= 	"01"				// Sequencia
								CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
								CB8->CB8_LCALIZ		:=  QRY->D2_LOCALIZ		// Endereço
								CB8->CB8_NOTA		:=  QRC->F2_DOC			// NF de Saída
								CB8->CB8_SERIE		:=  QRC->F2_SERIE		// Seria da NF
								//CB8->CB8_LOTECT		:= ""				// Lote
								CB8->CB8_NUMSER		:=  QRY->D2_NUMSERI		// Numero de Série
								MsUnlock()
								// Verifico se já foi gravada uma Ordem de Separação para o Pedido
								DbSelectArea("CB7")
								DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
								If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
									DbSelectArea("CB7")
									RecLock("CB7",.F.)
									CB7->CB7_NUMITE   += 1
									MsUnlock()
								Endif
							Endif

						Endif
					Endif

					If nContSB8 > 0
						oPrn:Say(nContLin,2200	, cImpLtSB8	,	oFont08	, 100 )
					Endif

					If nContLin > oPrn:nVertRes() -100
						nContLin	:= 20
						oPrn:EndPage()
						nPag++
						oPrn:StartPage()
					Endif

					If Len(Alltrim(QRY->B1_DESCRI)) > 25
						nContLin += 50
						oPrn:Say(nContLin,320	, Substr(QRY->B1_DESCRI,26,25),	oFont08	, 100 )
					Endif
					If Len(Alltrim(QRY->B1_DESCRI)) > 50
						nContLin += 50
						oPrn:Say(nContLin,320	, Substr(QRY->B1_DESCRI,51,25),	oFont08	, 100 )
					Endif
					nContLin += 50
					oPrn:line( nContLin, 0, nContLin+1, oPrn:nHorzRes() )

					DbSelectArea("SC5")
					DbSetOrder(1)
					DbSeek(xFilial("SC5") + QRY->D2_PEDIDO)
					dbSelectArea("QRY")
					dbSkip()
				Enddo

				QRY->(DbCloseArea())

				DbSelectArea("SF2")
				DbSetOrder(1)
				DbSeek(xFilial("SF2")+ QRC->F2_DOC + QRC->F2_SERIE) 

				nContLin += 50
				oPrn:Say(nContLin,0020	, "Valor do Frete " + Transform(SF2->F2_FRETE  ,"@E 999,999.99")	,	oFont08	, 100 )
				oPrn:Say(nContLin,1580	, "Total do Pedido " + Transform(nTotal  ,"@E 999,999.99")	,	oFont08	, 100 )

				cMsgInt		:= Alltrim(SC5->C5_ZMSGINT)
				cMsgInt		:= StrTran(cMsgInt,Chr(13)," ")
				cMsgInt		:= StrTran(cMsgInt,Chr(10)," ")
				cMsgNota	:= Alltrim(SC5->C5_MENNOTA)
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

				// Se a nota só teve caixa fechada  - Grava os volumes 
				If lCxFechada
					DbSelectArea("SF2")
					DbSetOrder(1)
					If DbSeek(xFilial("SF2")+ QRC->F2_DOC + QRC->F2_SERIE) 
						RecLock("SF2",.F.)
						SF2->F2_VOLUME1 := nSumVolumes
						SF2->F2_VOLUME3 := 0
						SF2->F2_ESPECI1 := "DIVERSOS"
						MsUnLock()
					Endif

				Endif
			Endif


		Else // Fornecedor
			DbSelectArea ("SA2")
			dbSetOrder(1)
			If DbSeek(xFilial("SA2")+QRC->F2_CLIENTE+QRC->F2_LOJA)

				If nContLin > oPrn:nVertRes() -700 .Or. ((!Empty(cNumNf) .Or. nPag > 0) .And.  MV_PAR08 == 1) // Verifica se atingiu limite da página ou quebra página por pedido
					nContLin	:= 20
					oPrn:EndPage()
					nPag++
					oPrn:StartPage()
				Endif

				cNumNf		:= QRC->F2_DOC
				lFirst		:= .T. // Atualiza o registro de controle para gravação da CB7
				lGrvCB8		:= .F.

				oPrn:Say(nContLin,0220, "ESPELHO DE NOTA FISCAL PARA SEPARAÇÃO " ,	oFont08	,100 )



				nContLin += 65

				dbSelectArea("SE4")
				dbSeek(xFilial("SE4")+QRC->F2_COND)
				DbSelectArea ("SA3")
				DbSeek(xFilial("SA3")+QRC->F2_VEND1)

				oPrn:Say(nContLin,0520	, "Num.NF: " + QRC->F2_DOC							,	oFont11	, 100 )

				//MSBAR3("CODE128",2.8,0.8,cOrdSep,oPr,Nil,Nil,Nil,nWidth,nHeigth,.t.,Nil,"B",Nil,Nil,Nil,.f.)

				MSBAR3(	"CODE128"/*cTypeBar*/,;
					00.32/*nRow*/,;
					013/*nCol*/,;
					AllTrim(cNumNf)/*cCode*/,;
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
				oPrn:Say(nContLin,020	, "Emissão: " + DTOC(STOD(QRC->F2_EMISSAO))  			,	oFont08	, 90 )
				//oPrn:Say(nContLin,450	, "Data Programada: " + DTOC(SC5->C5_DTPROGM) 	,	oFont08	, 90 )
				oPrn:Say(nContLin,970	, "Impressão: " + DTOC(Date())				 	,	oFont08	, 90 )
				oPrn:Say(nContLin,1850	, "Cond: " + SE4->E4_CODIGO + "-"+SE4->E4_DESCRI 	,	oFont08	, 90 )

				dbSelectArea ("SA4") //Cad. de Transportadoras
				DbSetOrder(1)
				dbSeek(xFilial("SA4")+QRC->F2_TRANSP)
				nContLin += 80
				oPrn:Say(nContLin,020	, "Transp: " + Substr(SA4->A4_NOME,1,30)+" - "+SA4->A4_COD + "/"+SA4->A4_NREDUZ	,	oFont08	, 90 )

				oPrn:Say(nContLin,1850	, "Tel-Contato: (" + Alltrim(SA2->A2_DDD) + ") " + SA2->A2_TEL + " - " + SA2->A2_CONTATO	,	oFont08	, 100 )

				//oPrn:Say(nContLin,020	, 	,	oFont08	, 100 )
				nContLin += 80
				oPrn:Say(nContLin,020	, AllTrim(SA2->A2_NOME) + " (" + AllTrim(SA2->A2_COD) + "/" + SA2->A2_LOJA  + ")"	,	oFont08	, 100 )

				nContLin += 80
				If Len(Alltrim(SA2->A2_CGC)) == 11
					oPrn:Say(nContLin,020	, Transform(SA1->A2_CGC, "@R 999.999.999-99")	,	oFont08	, 90 )
				Endif
				If LEN(ALLTRIM(SA2->A2_CGC)) == 14
					oPrn:Say(nContLin,020	, Transform(SA2->A2_CGC, "@R 99.999.999/9999-99")	,	oFont08	, 90 )
				Endif
				oPrn:Say(nContLin,490	, "End:" + SA2->A2_END	,	oFont08	, 90 )
				oPrn:Say(nContLin,2020	, "CEP:"+Transform(SA2->A2_CEP,"@R 99999-999")	,	oFont08	, 90 )
				nContLin += 80
				oPrn:Say(nContLin,020	, "Bairro: " + SA2->A2_BAIRRO,	oFont08	, 100 )
				oPrn:Say(nContLin,820	, "Cidade: " + SA2->A2_MUN	,	oFont08	, 100 )
				oPrn:Say(nContLin,2020	, "UF: " + SA2->A2_EST	,	oFont08	, 100 )
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
				oPrn:Say(nContLin,1580	, "Endereço"		,	oFont08	, 95 )
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



				cQry := "SELECT D2_ITEM,"
				cQry += "       D2_COD,"
				cQry += "       D2_LOCAL + ' - ' + B1_DESC AS B1_DESCRI,"
				cQry += "       D2_QUANT,"
				cQry += "       D2_PRCVEN,"
				cQry += "       D2_TOTAL,"
				cQry += "       D2_LOTECTL,"
				cQry += "       D2_LOCALIZ,"
				cQry += "       D2_NUMSERI,"
				cQry += "       D2_LOCAL,"
				cQry += "       B1_UM,"
				cQry += "       B1_XLOCAL,"
				cQry += "       D2_PEDIDO,"
				cQry += "       D2_NUMSEQ"
				cQry += "  FROM "+RetSqlName("SD2")+ " D2 "
				cQry += " INNER JOIN " + RetSqlName("SB1")+" B1 "
				cQry += "    ON B1.D_E_L_E_T_ = ' ' "
				cQry += "   AND B1_COD = D2_COD "
				cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
				cQry += " WHERE D2.D_E_L_E_T_ =' ' "
				cQry += "   AND D2_LOJA = '"+QRC->F2_LOJA+"' "
				cQry += "   AND D2_CLIENTE = '"+QRC->F2_CLIENTE+"' "
				cQry += "   AND D2_SERIE = '"+QRC->F2_SERIE+"' "
				cQry += "   AND D2_DOC = '"+QRC->F2_DOC+"' "
				cQry += "   AND D2_FILIAL = '"+xFilial("SD2")+"' "
				cQry += " ORDER BY B1_XLOCAL,D2_ITEM "

				dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRY', .F., .T.)

				While !Eof()

					oPrn:Say(nContLin,020	, QRY->D2_ITEM			,	oFont08	, 100 )
					oPrn:Say(nContLin,120	, QRY->D2_COD		,	oFont08	, 100 )
					oPrn:Say(nContLin,320	, Substr(QRY->B1_DESCRI,1,25),	oFont08	, 100 )
					oPrn:Say(nContLin,1020	, QRY->B1_UM		    ,	oFont08	, 100 )
					//oPrn:Say(nContLin,1150	, Transform(QRY->SALDOATUAL,"@E 99,999.999")	,	oFont08	, 100 )
					oPrn:Say(nContLin,1350	, Transform(QRY->D2_QUANT,"@E 99,999.999")		,	oFont08	, 100 )
					oPrn:Say(nContLin,1580	, Transform(QRY->B1_XLOCAL,"@R 99.99.9.X")		,	oFont08	, 100 )

					oPrn:Say(nContLin,1750	, Transform(QRY->D2_PRCVEN ,"@E 999,999.99")	,	oFont08	, 100 )
					oPrn:Say(nContLin,1990	, Transform(QRY->D2_TOTAL  ,"@E 999,999.99")	,	oFont08	, 100 )




					nItens := nItens+1
					nTotal += QRY->D2_TOTAL

					If lGeraCB7
						// Verifico se já foi gravada uma Ordem de Separação para o Pedido
						DbSelectArea("CB7")
						DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
						If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
							lGrvCB8	:= .F.
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
								CB7->CB7_PEDIDO		:= QRY->D2_PEDIDO		// Pedido Venda
								CB7->CB7_CLIENT		:= QRC->F2_CLIENTE		// Cliente
								CB7->CB7_LOJA		:= QRC->F2_LOJA			// Loja Cliente
								CB7->CB7_LOJENT		:= QRC->F2_LOJA			// Loja Entrega
								CB7->CB7_DTEMIS		:= Date() 				// Data Emissão
								CB7->CB7_LOCAL		:= QRY->D2_LOCAL		// Armazém
								CB7->CB7_HREMIS		:= Time()			    // Hora Emissão
								CB7->CB7_STATUS		:= "0"				 	// Status 				0-Inicio;1-Separando;2-Sep.Final;3-Embalando;4-Emb.Final;5-Gera Nota;6-Imp.nota;7-Imp.Vol;8-Embarcado;9-Embarque Finalizado
								CB7->CB7_ORIGEM		:= "1"					// Origem separação		1=Pedido;2=Nota Fiscal;3=Producao
								CB7->CB7_TIPEXP		:= "00-Separacao"		// Tipo Expedição		00-Separcao,01-Separacao/Embalagem,02-Embalagem,03-Gera Nota 04-embarque
								CB7->CB7_TRANSP		:= QRC->F2_TRANSP		// Transportadora
								CB7->CB7_COND		:= QRC->F2_COND			// Condição Pagamento
								CB7->CB7_VOLEMI		:= "0"					// Volume Emitido		0=Nao;1=Sim
								CB7->CB7_PRIORI		:= "9"
								CB7->CB7_NOTA		:= QRC->F2_DOC			// NF de Saída
								CB7->CB7_SERIE		:= QRC->F2_SERIE		// Seria da NF
								MsUnlock()
								lGrvCB8		:= .T.
								lFirst		:= .F.

								// Grava Log da Geração da Nota
								U_MLCFGM01("IM",QRY->D2_PEDIDO,"Impressão de Nota / Ordem Separação  "+ cNewOrdSep ,FunName())
							Endif
						Endif
						nSldSB8		:= 0
						nContSB8	:= 0
						cImpLtSB8	:= ""

						DbSelectArea("CB8")
						DbSetOrder(5) 	//CB8_FILIAL+CB8_NOTA+CB8_SERIE+CB8_ITEM+CB8_SEQUEN+CB8_PROD
						If DbSeek(xFilial("CB8") + QRC->F2_DOC + QRC->F2_SERIE + QRY->D2_ITEM )

						Else
							If Empty(QRY->D2_NUMSERI) .And. Empty(QRY->D2_LOCALIZ)
								nSldSB8		:= 0
								nContSB8	:= 0
								cImpLtSB8	:= ""
								cQry := "SELECT DB_NUMSERI,DB_QUANT,DB_LOCALIZ "
								cQry += "  FROM " + RetSqlName("SDB") + " DB "
								cQry += " WHERE D_E_L_E_T_ =' ' "
								cQry += "   AND DB_ESTORNO = ' ' "
								cQry += "   AND DB_NUMSEQ = '" + QRY->D2_NUMSEQ + "' "
								cQry += "   AND DB_LOCAL ='" + QRY->D2_LOCAL + "'"
								cQry += "   AND DB_LOJA = '" + QRC->F2_LOJA + "'"
								cQry += "   AND DB_CLIFOR = '" + QRC->F2_CLIENTE + "'"
								cQry += "   AND DB_SERIE = '" + QRC->F2_SERIE + "'"
								cQry += "   AND DB_DOC = '" + QRC->F2_DOC + "' "
								cQry += "   AND DB_PRODUTO = '" + QRY->D2_COD + "' "
								cQry += "   AND DB_FILIAL = '" + xFilial("SDB") + "'

								TcQuery cQry New Alias "QSDB"

								If Eof()
									DbSelectArea("CB8")
									RecLock("CB8",.T.)
									CB8->CB8_FILIAL		:= xFilial("CB8")
									CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
									CB8->CB8_ITEM		:= 	QRY->D2_ITEM		// Item Pedido
									CB8->CB8_PEDIDO		:= 	QRY->D2_PEDIDO		// Pedido de Venda
									CB8->CB8_PROD		:= 	QRY->D2_COD			// Código Produto
									CB8->CB8_LOCAL		:= 	QRY->D2_LOCAL		// Armazém
									CB8->CB8_QTDORI		:= 	QRY->D2_QUANT		// Quantidade Original
									CB8->CB8_SALDOS		:=  QRY->D2_QUANT		// Saldo a Separar
									CB8->CB8_SALDOE		:= 	QRY->D2_QUANT		// Saldo a embalar
									CB8->CB8_SEQUEN		:= 	"01"				// Sequencia
									CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
									CB8->CB8_LCALIZ		:=  QRY->D2_LOCALIZ		// Endereço
									CB8->CB8_NOTA		:=  QRC->F2_DOC			// NF de Saída
									CB8->CB8_SERIE		:=  QRC->F2_SERIE		// Seria da NF
									//CB8->CB8_LOTECT		:= ""				// Lote
									CB8->CB8_NUMSER		:=  QRY->D2_NUMSERI		// Numero de Série
									MsUnlock()
									// Verifico se já foi gravada uma Ordem de Separação para o Pedido
									DbSelectArea("CB7")
									DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
									If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
										DbSelectArea("CB7")
										RecLock("CB7",.F.)
										CB7->CB7_NUMITE   += 1
										MsUnlock()
									Endif
								Else
									While !Eof()
										If nContSB8 == 1
											cImpLtSB8	:= Alltrim(QSDB->DB_NUMSERI) + "=" + cValToChar(QSDB->DB_QUANT)
										Else
											If nSldSB8 < QRY->D2_QUANT
												cImpLtSB8	+= "|" + Alltrim(QSDB->DB_NUMSERI) + "=" + cValToChar(QSDB->DB_QUANT)
											Endif
										Endif
										nSldSB8	+= QSDB->DB_QUANT
										nContSB8++
										DbSelectArea("CB8")
										RecLock("CB8",.T.)
										CB8->CB8_FILIAL		:= xFilial("CB8")
										CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
										CB8->CB8_ITEM		:= 	QRY->D2_ITEM		// Item Pedido
										CB8->CB8_PEDIDO		:= 	QRY->D2_PEDIDO		// Pedido de Venda
										CB8->CB8_PROD		:= 	QRY->D2_COD			// Código Produto
										CB8->CB8_LOCAL		:= 	QRY->D2_LOCAL		// Armazém
										CB8->CB8_QTDORI		:= 	QSDB->DB_QUANT		// Quantidade Original
										CB8->CB8_SALDOS		:=  QSDB->DB_QUANT		// Saldo a Separar
										CB8->CB8_SALDOE		:= 	QSDB->DB_QUANT		// Saldo a embalar
										CB8->CB8_SEQUEN		:= 	StrZero(nContSB8,2)	// Sequencia
										CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
										CB8->CB8_LCALIZ		:= QSDB->DB_LOCALIZ		// Endereço
										CB8->CB8_NOTA		:= QRC->F2_DOC			// NF de Saída
										CB8->CB8_SERIE		:= QRC->F2_SERIE		// Seria da NF
										//CB8->CB8_LOTECT		:= ""				// Lote
										CB8->CB8_NUMSER		:= QSDB->DB_NUMSERI		// Numero de Série
										MsUnlock()
										// Verifico se já foi gravada uma Ordem de Separação para o Pedido
										DbSelectArea("CB7")
										DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
										If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
											DbSelectArea("CB7")
											RecLock("CB7",.F.)
											CB7->CB7_NUMITE   += 1
											MsUnlock()
										Endif
										QSDB->(DbSkip())
									Enddo
								Endif
								QSDB->(DbCloseArea())

							Else
								cImpLtSB8	:= QRY->D2_NUMSERI
								nContSB8	:= 1
								DbSelectArea("CB8")
								RecLock("CB8",.T.)
								CB8->CB8_FILIAL		:= xFilial("CB8")
								CB8->CB8_ORDSEP		:=	CB7->CB7_ORDSEP		// Numero Ordem
								CB8->CB8_ITEM		:= 	QRY->D2_ITEM		// Item Pedido
								CB8->CB8_PEDIDO		:= 	QRY->D2_PEDIDO		// Pedido de Venda
								CB8->CB8_PROD		:= 	QRY->D2_COD			// Código Produto
								CB8->CB8_LOCAL		:= 	QRY->D2_LOCAL		// Armazém
								CB8->CB8_QTDORI		:= 	QRY->D2_QUANT		// Quantidade Original
								CB8->CB8_SALDOS		:=  QRY->D2_QUANT		// Saldo a Separar
								CB8->CB8_SALDOE		:= 	QRY->D2_QUANT		// Saldo a embalar
								CB8->CB8_SEQUEN		:= 	"01"				// Sequencia
								CB8->CB8_QTECAN		:= 	0					// Quantidade Cancelada
								CB8->CB8_LCALIZ		:=  QRY->D2_LOCALIZ		// Endereço
								CB8->CB8_NOTA		:=  QRC->F2_DOC			// NF de Saída
								CB8->CB8_SERIE		:=  QRC->F2_SERIE		// Seria da NF
								//CB8->CB8_LOTECT		:= ""				// Lote
								CB8->CB8_NUMSER		:=  QRY->D2_NUMSERI		// Numero de Série
								MsUnlock()
								// Verifico se já foi gravada uma Ordem de Separação para o Pedido
								DbSelectArea("CB7")
								DbSetOrder(4) // CB7_FILIAL+CB7_NOTA+CB7_SERIE+CB7_LOCAL+CB7_STATUS
								If DbSeek(xFilial("CB7")+QRC->F2_DOC+QRC->F2_SERIE)
									DbSelectArea("CB7")
									RecLock("CB7",.F.)
									CB7->CB7_NUMITE   += 1
									MsUnlock()
								Endif
							Endif

						Endif
					Endif

					If nContSB8 > 0
						oPrn:Say(nContLin,2200	, cImpLtSB8	,	oFont08	, 100 )
					Endif

					If nContLin > oPrn:nVertRes() -100
						nContLin	:= 20
						oPrn:EndPage()
						nPag++
						oPrn:StartPage()
					Endif

					If Len(Alltrim(QRY->B1_DESCRI)) > 25
						nContLin += 50
						oPrn:Say(nContLin,320	, Substr(QRY->B1_DESCRI,26,25),	oFont08	, 100 )
					Endif
					If Len(Alltrim(QRY->B1_DESCRI)) > 50
						nContLin += 50
						oPrn:Say(nContLin,320	, Substr(QRY->B1_DESCRI,51,25),	oFont08	, 100 )
					Endif
					nContLin += 50
					oPrn:line( nContLin, 0, nContLin+1, oPrn:nHorzRes() )

					DbSelectArea("SC5")
					DbSetOrder(1)
					DbSeek(xFilial("SC5") + QRY->D2_PEDIDO)
					dbSelectArea("QRY")
					dbSkip()
				Enddo

				QRY->(DbCloseArea())

				cMsgInt		:= Alltrim(SC5->C5_ZMSGINT)
				cMsgInt		:= StrTran(cMsgInt,Chr(13)," ")
				cMsgInt		:= StrTran(cMsgInt,Chr(10)," ")
				cMsgNota	:= Alltrim(SC5->C5_MENNOTA)
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
		Endif
		QRC->(DbSkip())
	Enddo
	QRC->(DbCloseArea())

	oPrn:EndPage()

	oPrn:Preview()
	MS_Flush()

Return



Static Function sfValPerg()
	/*
	MV_PAR01 - Serie 
	MV_PAR02 - Nota Inicial
	MV_PAR03 - Nota Final 
	MV_PAR04 - Vendedor Inicial
	MV_PAR05 - Vendedor Final
	MV_PAR06 - Emissao Inicial
	MV_PAR07 - Emissao Final 
	MV_PAR08 - Quebra página por nota 
	*/
	Local	aSx1Cab		:= {"X1_GRUPO",;	//1
	"X1_ORDEM",;	//2
	"X1_PERGUNT",;	//3
	"X1_VARIAVL",;	//4
	"X1_TIPO",;		//5
	"X1_TAMANHO",;	//6
	"X1_DECIMAL",;	//7
	"X1_PRESEL",;	//8
	"X1_GSC",;		//9
	"X1_VAR01",;	//10
	"X1_F3"}		//11

	Local	aSX1Resp	:= {}

	Aadd(aSX1Resp,{	cPerg,;					//1
	'01',;					//2
	'Série Nota?',;			//3
	'mv_ch1',;				//4
	'C',;					//5
	3,;						//6
	0,;						//7
	0,;						//8
	'G',;					//9
	'mv_par01',;			//10
	' '})					//11

	Aadd(aSX1Resp,{	cPerg,;					//1
	'02',;					//2
	'Nota Fiscal De?',;		//3
	'mv_ch2',;				//4
	'C',;					//5
	9,;						//6
	0,;						//7
	0,;						//8
	'G',;					//9
	'mv_par02',;			//10
	'SF2'})					//11


	Aadd(aSX1Resp,{	cPerg,;					//1
	'03',;					//2
	'Nota Fiscal Até?',;			//3
	'mv_ch3',;				//4
	'C',;					//5
	9,;						//6
	0,;						//7
	0,;						//8
	'G',;					//9
	'mv_par03',;			//10
	'SF2'})					//11

	Aadd(aSX1Resp,{	cPerg,;					//1
	'04',;					//2
	'Vendedor De?',;		//3
	'mv_ch4',;				//4
	'C',;					//5
	6,;						//6
	0,;						//7
	0,;						//8
	'G',;					//9
	'mv_par04',;			//10
	'SA3'})					//11


	Aadd(aSX1Resp,{	cPerg,;					//1
	'05',;					//2
	'Vendedor Até?',;			//3
	'mv_ch5',;				//4
	'C',;					//5
	6,;						//6
	0,;						//7
	0,;						//8
	'G',;					//9
	'mv_par05',;			//10
	'SA3'})					//11

	Aadd(aSX1Resp,{	cPerg,;					//1
	'06',;					//2
	'Emissão De?'	,;		//3
	'mv_ch6',;				//4
	'D',;					//5
	8,;						//6
	0,;						//7
	0,;						//8
	'G',;					//9
	'mv_par06',;			//10
	''})					//11

	Aadd(aSX1Resp,{	cPerg,;					//1
	'07',;					//2
	'Emissão Até?'	,;		//3
	'mv_ch7',;				//4
	'D',;					//5
	8,;						//6
	0,;						//7
	0,;						//8
	'G',;					//9
	'mv_par07',;			//10
	''})					//11

	// Grava Perguntas
	U_MLPUTSX1(aSx1Cab,aSX1Resp,.F./*lForceAtuSx1*/)


	// Reseta as variÃ¡veis para sÃ³ levar o que for necessÃ¡rio
	aSX1Resp	:= {}
	aSx1Cab		:= {"X1_GRUPO",;	//1
	"X1_ORDEM",;	//2
	"X1_PERGUNT",;	//3
	"X1_VARIAVL",;	//4
	"X1_TIPO",;		//5
	"X1_TAMANHO",;	//6
	"X1_DECIMAL",;	//7
	"X1_PRESEL",;	//8
	"X1_GSC",;		//9
	"X1_VAR01",;	//10
	"X1_DEF01",;	//11
	"X1_DEF02",;	//12
	"X1_DEF03",;	//13
	"X1_DEF04",;	//14
	"X1_DEF05"}		//15

	Aadd(aSX1Resp,{	cPerg,;					//1
	'08',;					//2
	'Quebra Página?'	,;			//3
	'mv_ch8',;				//4
	'N',;					//5
	1,;						//6
	0,;						//7
	0,;						//8
	'C',;					//9
	'mv_par08',;			//10
	'Sim',;					//11
	'Não',;					//12
	'',;					//13
	'',;					//14
	''})					//15

	// Grava as perguntas
	U_MLPUTSX1(aSx1Cab,aSX1Resp,.F./*lForceAtuSx1*/)
Return
