#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} M460FIM
(Ponto de entrada ao gerar nota fiscal - Grava tampinhas)
@author MarceloLauschner
@since 26/01/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function M460FIM()


	Local aAreaOld 	:= GetArea()
	Local aArea     := GetArea()
	Local aParam    := PARAMIXB
	Local cFunCall  := "M460FIM" // SubStr(ProcName(0),3)
	Local lPEICMAIS := ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)

	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M460FIM")
		Return .T.
	Endif

	// Manter o trexo de código a seguir no final do fonte
	If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
	EndIf
	RestArea( aArea )

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)
	//Verifica se o cliente possue acordo comercial de reembolso e grava no D2_VALPROM e na tabela de extrato de promoções.

	// Corrigido falha que deixa o arquivo temporário QRZ em aberto em outra rotina - Adicionado em 20/02/2013 - Marcelo Lauschner
	If Select("QRZ") > 0
		QRZ->(DbCloseArea())
	Endif

	// Inicio trecho de gravação de Reembolso F&I / Marketing
	cQrZ := ""
	cQrZ += "SELECT * "
	cQrZ += "  FROM " +RetSqlName("SZP") + " ZP "
	cQrZ += " WHERE ZP.D_E_L_E_T_ = ' ' "
	cQrZ += "   AND ZP.ZP_LOJA = '" + SF2->F2_LOJA + "' "
	cQrZ += "   AND ZP.ZP_CLIENTE = '" + SF2->F2_CLIENTE + "' "
	cQrZ += "   AND ZP.ZP_FILIAL = '" + xFilial("SZP") + "' "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQrZ),'QRZ', .F., .T.)

	If !Empty(QRZ->ZP_GRUPO)

		cQra := ""
		cQra += "SELECT D2_DOC, D2_SERIE, D2_PEDIDO, D2_CLIENTE, D2_LOJA, D2_COD, D2_ITEM, D2_QUANT, (D2_TOTAL+D2_VALIPI+D2_ICMSRET) AS D2_TOTAL, D2_PRCVEN, ZP_FI_PERC,ZP_PRETENC, ZP_VERBMKT "
		cQra += "  FROM " +RetSqlName("SD2") + " SD2, " +RetSqlName("SF4") + " SF4, " +RetSqlName("SB1") + " SB1, " +RetSqlName("SZP") + " SZP "
		cQra += " WHERE SF4.D_E_L_E_T_ = ' ' "
		cQra += "   AND SF4.F4_DUPLIC = 'S' "
		cQra += "   AND F4_ESTOQUE = 'S' "
		cQra += "   AND SF4.F4_CODIGO = SD2.D2_TES "
		cQra += "   AND SF4.F4_FILIAL = SD2.D2_FILIAL "
		cQra += "   AND SZP.D_E_L_E_T_ = ' ' "
		cQra += "   AND SD2.D2_EMISSAO >= SZP.ZP_DATAINI "
		cQra += "   AND SD2.D2_EMISSAO <= SZP.ZP_DATAFIN "
		cQra += "   AND SZP.ZP_GRUPO = SB1.B1_GRUPO "
		cQra += "   AND SZP.ZP_LOJA = SD2.D2_LOJA "
		cQra += "   AND SZP.ZP_CLIENTE = SD2.D2_CLIENTE "
		cQra += "   AND SZP.ZP_FILIAL = '" + xFilial("SZP") + "' "
		cQra += "   AND SB1.D_E_L_E_T_ = ' ' "
		cQra += "   AND SB1.B1_BLOQFAT = 'N' " //B1_TIPO = 'PA' "
		cQra += "   AND SB1.B1_COD = SD2.D2_COD "
		cQra += "   AND SB1.B1_FILIAL = SD2.D2_FILIAL "
		cQra += "   AND SD2.D_E_L_E_T_ = ' ' "
		cQra += "   AND SD2.D2_LOJA = '" + SF2->F2_LOJA + "' "
		cQra += "   AND SD2.D2_CLIENTE = '" + SF2->F2_CLIENTE + "' "
		cQra += "   AND SD2.D2_SERIE = '" +SF2->F2_SERIE + "' "
		cQra += "   AND SD2.D2_DOC = '"+SF2->F2_DOC+"' "
		cQra += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "' "

		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQra),'QRA', .F., .T.)

		While !Eof()

			If QRA->ZP_FI_PERC > 0	//Verifica se há percentual de F&I cadastrada para o clienteXgrupo e grava na SZA com a referencia "F"
				// Grava registro na Tabela
				DbSelectArea("SZA")
				RecLock("SZA",.T.)
				SZA->ZA_DOC			:= SF2->F2_DOC
				SZA->ZA_VEND		:= SF2->F2_VEND1
				SZA->ZA_DATA 		:= SF2->F2_EMISSAO
				SZA->ZA_CLIENTE 	:= SF2->F2_CLIENTE
				SZA->ZA_LOJA 		:= SF2->F2_LOJA
				SZA->ZA_VALOR  		:= Round(QRA->D2_TOTAL*(QRA->ZP_FI_PERC/100),2)
				SZA->ZA_PONTOS 		:= 0
				SZA->ZA_OBSERV 		:= "FATUR. NF " + SF2->F2_DOC + " COM REEMBOLSO FI "
				SZA->ZA_TIPOMOV 	:= "C"
				SZA->ZA_ITEM    	:= QRA->D2_ITEM
				SZA->ZA_PRODUTO 	:= QRA->D2_COD
				SZA->ZA_QTDORI 		:= QRA->D2_QUANT
				SZA->ZA_VALUNIT 	:= Round(QRA->D2_PRCVEN*(QRA->ZP_FI_PERC/100),2)
				SZA->ZA_PTOUNIT 	:= 0
				SZA->ZA_REFEREN 	:= "F"
				SZA->ZA_ORIGEM  	:= "F"
				MsUnLock("SZA")
			EndIf
			/* // Comentado o trecho pois não deve gerar mais um Crédito a Retenção, pois a Retenção é o conceito de pagamento de Tampinhas e F&I para alguns clientes. 
			If QRA->ZP_PRETENC > 0	//Verifica se há percentual de F&I cadastrada para o clienteXgrupo e grava na SZA com a referencia "F"
				// Grava registro na Tabela
				DbSelectArea("SZA")
				RecLock("SZA",.T.)
				SZA->ZA_DOC			:= SF2->F2_DOC
				SZA->ZA_VEND		:= SF2->F2_VEND1
				SZA->ZA_DATA 		:= SF2->F2_EMISSAO
				SZA->ZA_CLIENTE 	:= SF2->F2_CLIENTE
				SZA->ZA_LOJA 		:= SF2->F2_LOJA
				SZA->ZA_VALOR  		:= Round(QRA->D2_TOTAL*(QRA->ZP_PRETENC/100),2)
				SZA->ZA_PONTOS 		:= 0
				SZA->ZA_OBSERV 		:= "FATUR. NF " + SF2->F2_DOC + " COM RETENCAO "
				SZA->ZA_TIPOMOV 	:= "C"
				SZA->ZA_ITEM    	:= QRA->D2_ITEM
				SZA->ZA_PRODUTO 	:= QRA->D2_COD
				SZA->ZA_QTDORI 		:= QRA->D2_QUANT
				SZA->ZA_VALUNIT 	:= Round(QRA->D2_PRCVEN*(QRA->ZP_PRETENC/100),2)
				SZA->ZA_PTOUNIT 	:= 0
				SZA->ZA_REFEREN 	:= "F"
				SZA->ZA_ORIGEM  	:= "F"
				MsUnLock("SZA")
			EndIf
			*/
			If QRA->ZP_VERBMKT > 0 //Verifica se há percentual de verba de marketing cadastrada para o clienteXgrupo e grava na SZA com a referencia "M"
				DbSelectArea("SZA")
				RecLock("SZA",.T.)
				SZA->ZA_DOC			:= SF2->F2_DOC
				SZA->ZA_VEND		:= SF2->F2_VEND1
				SZA->ZA_DATA 		:= SF2->F2_EMISSAO
				SZA->ZA_CLIENTE 	:= SF2->F2_CLIENTE
				SZA->ZA_LOJA 		:= SF2->F2_LOJA
				SZA->ZA_VALOR  		:= Round(QRA->D2_TOTAL*(QRA->ZP_VERBMKT/100),2)
				SZA->ZA_PONTOS 		:= 0
				SZA->ZA_OBSERV 		:= "FATUR. NF " + SF2->F2_DOC + " COM VERBA MKT"
				SZA->ZA_TIPOMOV 	:= "C"
				SZA->ZA_ITEM    	:= QRA->D2_ITEM
				SZA->ZA_PRODUTO 	:= QRA->D2_COD
				SZA->ZA_QTDORI 		:= QRA->D2_QUANT
				SZA->ZA_VALUNIT 	:= Round(QRA->D2_PRCVEN*(QRA->ZP_VERBMKT/100),2)
				SZA->ZA_PTOUNIT 	:= 0
				SZA->ZA_REFEREN 	:= "M"
				SZA->ZA_ORIGEM  	:= "F"
				MsUnLock("SZA")
			EndIf

			// Atualiza registro no SD2
			DbSelectArea("SD2")
			DbSetOrder(3)
			DbSeek(xFilial("SD2")+QRA->D2_DOC+QRA->D2_SERIE+QRA->D2_CLIENTE+QRA->D2_LOJA+QRA->D2_COD+QRA->D2_ITEM)
			Reclock("SD2",.F.)
			If QRA->ZP_FI_PERC > 0
				SD2->D2_XVALPAG := Round(QRA->D2_TOTAL*(QRA->ZP_FI_PERC/100),2)
			EndIf
			If QRA->ZP_PRETENC > 0
				SD2->D2_XRETENC := Round(QRA->D2_TOTAL*(QRA->ZP_PRETENC/100),2)
			Endif
			If QRA->ZP_VERBMKT > 0
				SD2->D2_XVALMKT := Round(QRA->D2_TOTAL*(QRA->ZP_VERBMKT/100),2)
			EndIf
			MSUnLock()

			DbSelectArea("QRA")
			DbSkip()
		Enddo
		QRA->(dbCloseArea())
	EndIf
	QRZ->(dbCloseArea())
	// Fim trecho de F&I / Marketing / Retenção


	//====ALIMENTA O CAMPO D2_XCUSTO COM O CUSTO STANDART DO PRODUTO=========

	cQra := ""
	cQra += "SELECT SD2.R_E_C_N_O_ RECSD2, SB1.R_E_C_N_O_ RECSB1  "
	cQra += "  FROM " +RetSqlName("SD2") + " SD2, " +RetSqlName("SB1") + " SB1 "
	cQra += " WHERE SD2.D2_FILIAL = '"+ FWxFilial( 'SD2' ) +"' "
	cQra += "   AND SD2.D2_LOJA = '" + SF2->F2_LOJA + "' "
	cQra += "   AND SD2.D2_CLIENTE = '" + SF2->F2_CLIENTE + "' "
	cQra += "   AND SD2.D2_SERIE = '" +SF2->F2_SERIE + "' "
	cQra += "   AND SD2.D2_DOC = '"+SF2->F2_DOC+"' "
	cQra += "   AND SD2.D_E_L_E_T_ = ' ' "
	cQra += "   AND SB1.B1_FILIAL = '" + FWxFilial("SB1") + "' "
	cQra += "   AND SB1.B1_COD = SD2.D2_COD "
	cQra += "   AND SB1.D_E_L_E_T_ = ' ' "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQra),'QRA', .F., .T.)

	While !QRA->(Eof())

		DBSelectArea( 'SB1' )
		SB1->( DbGoTo( QRA->RECSB1 ) )

		// Atualiza registro no SD2
		DbSelectArea("SD2")
		SD2->( DBGoTo( QRA->RECSD2 ) )

		Reclock("SD2",.F.)
		SD2->D2_XCUSTO := Round(SB1->B1_CUSTD*SD2->D2_QUANT,2)
		MSUnLock("SD2")

		QRA->(DbSkip())
	Enddo
	QRA->(dbCloseArea())

	// Restaura a area Anterior
	RestArea(aAreaOld)

Return



/*/{Protheus.doc} XREFSZA
(Refaz valores de F&I e Verbas de notas fiscais que não foram calculadas)
@type function
@author Marcelo Alberto Lauschner
@since 03/02/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function XREFSZA()

	Local 		aOpenTable 		:= {"SF2","SA1","SZP","SZA","SB1","SD2"}
	Local 		cIdUser 		:= "marcelo"
	Local 		cIdPswd 		:= "brlub#2024"

	If Select("SM0") == 0

		RPCSetEnv("14","01",cIdUser,cIdPswd,"FAT",,aOpenTable) // Abre todas as tabelas.
		sfRefaz()
		RpcClearEnv()

		RPCSetEnv("14","02",cIdUser,cIdPswd,"FAT",,aOpenTable) // Abre todas as tabelas.
		sfRefaz()
		RpcClearEnv()

		RPCSetEnv("14","03",cIdUser,cIdPswd,"FAT",,aOpenTable) // Abre todas as tabelas.
		sfRefaz()
		RpcClearEnv()

		RPCSetEnv("14","04",cIdUser,cIdPswd,"FAT",,aOpenTable) // Abre todas as tabelas.
		sfRefaz()
		RpcClearEnv()

	Endif


Return


/*/{Protheus.doc} sfRefaz
(Executa gravação offline)
@type function
@author marce
@since 03/02/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRefaz()

	Local	cQry := ""

	cQry += "SELECT DISTINCT D2.R_E_C_N_O_ D2RECNO "
	cQry += "  FROM " + RetSqlName("SD2") + " D2," + RetSqlName("SZ8") + " Z8 "
	cQry += " WHERE D2_EMISSAO BETWEEN Z8_DATCAD AND Z8_DATFIM "
	cQry += "   AND Z8_REEMB = 'T' "
	cQry += "   AND Z8.D_E_L_E_T_ = ' ' "
	cQry += " 	AND Z8_LOJA = D2_LOJA "
	cQry += "   AND Z8_CLIENTE = D2_CLIENTE "
	cQry += "   AND Z8_CODPROD = D2_COD  "
	cQry += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "'"
	cQry += "   AND D2.D_E_L_E_T_ =' ' "
	cQry += "   AND D2_EMISSAO >='20240201' "
	cQry += "   AND D2_TIPO = 'N' "
	cQry += "   AND D2_VALPROM = 0 "
	cQry += "   AND D2_FILIAL = '" + xFilial("SD2") + "' "
	cQry += "UNION "
	cQry += "SELECT DISTINCT D2.R_E_C_N_O_ D2RECNO "
	cQry += "  FROM " + RetSqlName("SD2") + " D2," + RetSqlName("SZ8") + " Z8 "
	cQry += " WHERE D2_EMISSAO BETWEEN Z8_DATCAD AND Z8_DATFIM "
	cQry += "   AND Z8_REEMB = 'P' "
	cQry += "   AND Z8.D_E_L_E_T_ = ' ' "
	cQry += "   AND Z8_CODPROD = D2_COD  "
	cQry += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "'"
	cQry += "   AND D2.D_E_L_E_T_ =' ' "
	cQry += "   AND D2_EMISSAO >='20240201' "
	cQry += "   AND D2_TIPO = 'N' "
	cQry += "   AND D2_VALPROM = 0 "
	cQry += "   AND D2_FILIAL = '" + xFilial("SD2") + "' "


	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QD2', .F., .T.)

	While !Eof()
		DbSelectArea("SD2")
		DbGoto(QD2->D2RECNO)

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5") + SD2->D2_PEDIDO)

		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6") + SD2->D2_PEDIDO + SD2->D2_ITEMPV )
		
		DbSelectArea("SF4")
		DbSetOrder(1)
		DbSeek(xFilial("SF4") + SD2->D2_TES)

		DbSelectArea("SA1")
		DbSetOrder(1)	
		DbSeek(xFilial("SA1")+SD2->D2_CLIENTE+SD2->D2_LOJA)
		
		sfAtuSZA()

		DbSelectArea("QD2")
		DbSkip()
	Enddo
	QD2->(DbCloseArea())

Return


/*/{Protheus.doc} sfAtuSZA
(Gera registros na SZA e atualiza SD2)
@type function
@author marce
@since 03/02/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuSZA()

	Local 	aAreaOld 	:= GetArea() 

	// Só roda para pedido tipo Normal - que ainda não tinha cálculo de tampinha , que gera duplicata e atualiza estoque
	If SC5->C5_TIPO == "N" .And. SF4->F4_DUPLIC == "S" .And. SF4->F4_ESTOQUE == "S"

		// Inicio gravação Tampas
		If SA1->A1_REEMB == "P" //P=Padrao Texaco

			// Verifica se o cadastro ainda é vigente
			cQra := ""
			cQra += "SELECT Z8.R_E_C_N_O_  Z8RECNO"
			cQra += "  FROM " + RetSqlName("SZ8") + " Z8 "
			cQra += " WHERE " + DTOS(SD2->D2_EMISSAO) + " BETWEEN Z8_DATCAD AND Z8_DATFIM "
			cQra += "   AND Z8.D_E_L_E_T_ = ' ' "
			cQra += "   AND Z8_CODPROD = '" + SD2->D2_COD + "' "
			cQra += "   AND Z8_REEMB = 'P' "
			cQra += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQra),'QRA', .F., .T.)

			If !Eof()

				DbSelectArea("SC5")
				RecLock("SC5",.F.)
				SC5->C5_REEMB 	:= SA1->A1_REEMB
				MsUnlock()

				aArrTamp	:= U_BFTMKA07(SD2->D2_CLIENTE,SD2->D2_LOJA ,SD2->D2_COD,SC5->C5_REEMB,,,3)

				DbSelectArea("SC6")
				RecLock("SC6",.F.)
				SC6->C6_XVLRTAM		:= aArrTamp[1]
				SC6->C6_XFLEX 		:= aArrTamp[2]
				MsUnlock()

				DbSelectArea("SZ8")
				DbGoto(QRA->Z8RECNO)
				// Grava registro na Tabela
				DbSelectArea("SZA")
				RecLock("SZA",.T.)
				SZA->ZA_DOC			:= SD2->D2_DOC
				SZA->ZA_VEND		:= SC5->C5_VEND1
				SZA->ZA_DATA 		:= SD2->D2_EMISSAO
				SZA->ZA_CLIENTE 	:= SD2->D2_CLIENTE
				SZA->ZA_LOJA 		:= SD2->D2_LOJA
				SZA->ZA_VALOR  		:= Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SZA->ZA_OBSERV 		:= "FATURAMENTO NF - PEDIDO:" + SC5->C5_NUM + " - P=TAMPA PADRAO"
				SZA->ZA_TIPOMOV 	:= "C"
				SZA->ZA_ITEM    	:= SD2->D2_ITEM
				SZA->ZA_PRODUTO 	:= SD2->D2_COD
				SZA->ZA_QTDORI 		:= SD2->D2_QUANT
				SZA->ZA_VALUNIT 	:= SC6->C6_XVLRTAM
				SZA->ZA_REFEREN 	:= "T"
				SZA->ZA_ORIGEM  	:= "F"
				SZA->ZA_PONTOS 		:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MsUnLock("SZA")

				Reclock("SD2",.F.)
				SD2->D2_VALPROM := Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SD2->D2_VALPTOS	:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MSUnLock()

			EndIf
			QRA->(dbCloseArea())

		ElseIf  SA1->A1_REEMB == "T" //P=Padrao Texaco



			// Verifica se o cadastro ainda é vigente
			cQra := ""
			cQra += "SELECT Z8.R_E_C_N_O_ Z8RECNO "
			cQra += "  FROM " + RetSqlName("SZ8") + " Z8 "
			cQra += " WHERE " + DTOS(SD2->D2_EMISSAO) + " BETWEEN Z8_DATCAD AND Z8_DATFIM "
			cQra += "   AND Z8.D_E_L_E_T_ = ' ' "
			cQra += "   AND Z8_CODPROD = '" + SD2->D2_COD + "' "
			cQra += "   AND Z8_LOJA = '" + SD2->D2_LOJA + "'"
			cQra += "   AND Z8_CLIENTE = '" + SD2->D2_CLIENTE + "'"
			cQra += "   AND Z8_REEMB = 'T' "
			cQra += "   AND Z8_FILIAL = '" + xFilial("SZ8") + "' "

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQra),'QRA', .F., .T.)

			If !Eof()
				DbSelectArea("SC5")
				RecLock("SC5",.F.)
				SC5->C5_REEMB 	:= SA1->A1_REEMB
				MsUnlock()

				aArrTamp	:= U_BFTMKA07(SD2->D2_CLIENTE,SD2->D2_LOJA ,SD2->D2_COD,SC5->C5_REEMB,,,3)

				DbSelectArea("SC6")
				RecLock("SC6",.F.)
				SC6->C6_XVLRTAM		:= aArrTamp[1]
				SC6->C6_XFLEX 		:= aArrTamp[2]
				MsUnlock()

				DbSelectArea("SZ8")
				DbGoto(QRA->Z8RECNO)
				// Grava registro na Tabela
				DbSelectArea("SZA")
				RecLock("SZA",.T.)
				SZA->ZA_DOC			:= SD2->D2_DOC
				SZA->ZA_VEND		:= SC5->C5_VEND1
				SZA->ZA_DATA 		:= SD2->D2_EMISSAO
				SZA->ZA_CLIENTE 	:= SD2->D2_CLIENTE
				SZA->ZA_LOJA 		:= SD2->D2_LOJA
				SZA->ZA_VALOR  		:= Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SZA->ZA_OBSERV 		:= "FATURAMENTO NF - PEDIDO:" + SC5->C5_NUM + " - " + SA1->A1_REEMB + "=TAMPA CUSTOMIZADO"
				SZA->ZA_TIPOMOV 	:= "C"
				SZA->ZA_ITEM    	:= SD2->D2_ITEM
				SZA->ZA_PRODUTO 	:= SD2->D2_COD
				SZA->ZA_QTDORI 		:= SD2->D2_QUANT
				SZA->ZA_VALUNIT 	:= SC6->C6_XVLRTAM
				SZA->ZA_REFEREN 	:= "T"
				SZA->ZA_ORIGEM  	:= "F"
				SZA->ZA_PONTOS 		:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MsUnLock("SZA")

				Reclock("SD2",.F.)
				SD2->D2_VALPROM := Round(SC6->C6_XVLRTAM*SD2->D2_QUANT,2)
				SD2->D2_VALPTOS	:= Round(SC6->C6_XFLEX * SD2->D2_QUANT,2)
				MSUnLock()

			EndIf
			QRA->(dbCloseArea())
		Endif
	Endif
	// Restaura a area Anterior
	RestArea(aAreaOld)

Return

