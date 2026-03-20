#Include 'Protheus.ch'
#include 'topconn.ch'

/*/{Protheus.doc} XMLCTE11
Ponto de entrada que retorna o Código do Produto automaticamente para facilitar a conversão
@type function
@version
@author Marcelo Alberto Lauschner
@since 16/07/2020
@return return_type, return_description
/*/
User Function XMLCTE11()
	//cQry,cInCodForn,cInLojForn,cCodProd,cDescProd,cInCfopXml,cTipoDoc

	Local	aAreaOld	:= GetArea()
	Local	cQryA
	Local	cInQry		:= ParamIxb[1]
	Local	cInXCodForn	:= ParamIxb[2]
	Local	cInXLojForn	:= ParamIxb[3]
	Local	cInXCodProd	:= ParamIxb[4]
	Local	cInXDescPrd	:= ParamIxb[5]
	Local	cInXCfopXml	:= ParamIxb[6]
	Local	cInXcTipoDc	:= ParamIxb[7]
	Local	cQry1		:= ""
	Local	cQry2		:= ""


	If cInXcTipoDc $ "N#C#P#I#S"
		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSelectArea("SA5")
		DbSetOrder(1)
		DbSelectArea("SA2")
		DbSetOrder(1)
		DbSeek(xFilial("SA2")+cInXCodForn+cInXLojForn)

		cQryA := "SELECT A5_CODPRF,"
		cQryA += "       A5_PRODUTO,"
		cQryA += "       A5_NOMPROD,"
		cQryA += "       B1_DESC, "
		cQryA += "       B1_CONV "
		cQryA += "  FROM " + RetSqlName("SA5") + " A5," + RetSqlName("SB1") + " B1 "
		cQryA += " WHERE B1.D_E_L_E_T_ = ' ' "

		If SB1->(FieldPos('B1_MSBLQL')) > 0
			cQryA += "   AND B1_MSBLQL <> '1' "
		Endif
		cQryA += "   AND B1_COD = A5_PRODUTO "
		cQryA += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
		cQryA += "   AND A5.D_E_L_E_T_ =' ' "
		cQryA += "   AND A5_FORNECE = '"+ cInXCodForn+ "' "
		cQryA += "   AND A5_LOJA = '"+cInXLojForn+"' "
		cQryA += "   AND A5_CODPRF ='" + Alltrim(cInXCodProd) + "' "
		cQryA += "   AND A5_FILIAL = '" + xFilial("SA5") + "' "

		cQry1 := cQryA

		TCQUERY cQryA NEW ALIAS "QRYB"

		If Eof()
			cQryA := "SELECT B1_COD AS A5_CODPRF,"
			cQryA += "       B1_COD AS A5_PRODUTO,"
			cQryA += "       B1_DESC AS A5_NOMPROD,"
			cQryA += "       B1_DESC ,"
			cQryA += "       1 AS B1_CONV " // Fator de Conversão será por default 1 quando o código de Produto vier da SB1 invés da SB5
			cQryA += "  FROM " + RetSqlName("SB1") + " B1 "
			cQryA += " WHERE B1.D_E_L_E_T_ = ' ' "
			cQryA += "   AND B1_COD = '" + cInXCodProd + "' "
			cQryA += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"

			// Se o Fornecedor for uma Filial da Empresa retorno o próprio código do produto
			If !Empty(SA2->A2_FILTRF )
				cQry2	:= cQryA
			ElseIf lComprUsr // Se for usuário do compras restaura query original sem customização
				cQryA	:= cInQry
			Endif
		ElseIf !Empty(SA2->A2_FILTRF ) // Se o fornecedor for uma Filial da Empresa

			cQryA := "SELECT B1_COD AS A5_CODPRF,"
			cQryA += "       B1_COD AS A5_PRODUTO,"
			cQryA += "       B1_DESC AS A5_NOMPROD,"
			cQryA += "       B1_DESC ,"
			cQryA += "       1 AS B1_CONV " // Fator de Conversão será por default 1 quando o código de Produto vier da SB1 invés da SB5
			cQryA += "  FROM " + RetSqlName("SB1") + " B1 "
			cQryA += " WHERE B1.D_E_L_E_T_ = ' ' "
			cQryA += "   AND B1_COD = '" + cInXCodProd + "' "
			cQryA += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"
		Endif

		QRYB->(DbCloseArea())

	ElseIf cInXcTipoDc $ "D"

		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+cInXCodForn+cInXLojForn)

		// Popula automaticamente para não criar interface 
		If !Empty(SA1->A1_FILTRF )

			DbSelectArea("SA7")
			DbSetOrder(2) // A7_FILIAL+A7_PRODUTO+A7_CLIENTE+A7_LOJA
			If DbSeek(xFilial("SA7")+Padr(cInXCodProd,TamSX3("A7_PRODUTO")[1])+cInXCodForn+cInXLojForn)
				RecLock("SA7",.F.)
				SA7->A7_CODCLI  	:=	cInXCodProd
				SA7->A7_DESCCLI		:=  cInXDescPrd
				If SA7->(FieldPos("A7_XUNID")) > 0
					SA7->A7_XUNID	:= Posicione("SB1",1,xFilial("SB1")+cInXCodProd,"B1_UM")
				Endif
				If SA7->(FieldPos("A7_XTPCONV")) > 0
					SA7->A7_XTPCONV	:= "D"
				Endif
				If SA7->(FieldPos("A7_XCONV")) > 0
					SA7->A7_XCONV	:= 1
				Endif
				MsUnlock()
			Endif
		Endif

		cQryA := "SELECT A7_PRODUTO,A7_CODCLI,A7_DESCCLI,B1_DESC,' ' D2_DOC , 0 D2_QUANT,A7.R_E_C_N_O_ RECNOA7 "

		If SA7->(FieldPos("A7_XTPCONV")) > 0
			cQryA += " ,A7_XTPCONV "
		Else
			cQryA += " ,' ' A7_XTPCONV "
		Endif

		If SA7->(FieldPos("A7_XCONV")) > 0
			cQryA += " ,A7_XCONV "
		Else
			cQryA += " ,1 A7_XCONV "
		Endif

		cQryA += "  FROM " + RetSqlName("SA7") + " A7, "+ RetSqlName("SB1")+ " B1 "
		cQryA += " WHERE B1.D_E_L_E_T_ = ' ' "
		cQryA += "   AND B1_MSBLQL <> '1' "
		cQryA += "   AND B1_COD = A7_PRODUTO "
		cQryA += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
		cQryA += "   AND A7.D_E_L_E_T_ = ' ' "
		cQryA += "   AND A7_CLIENTE = '"+ cInXCodForn+ "' "
		cQryA += "   AND A7_LOJA = '"+cInXLojForn+"' "
		If !Empty(SA1->A1_FILTRF )
			cQryA += "   AND A7_PRODUTO = '" + Alltrim(cInXCodProd) + "' "
		Endif
		cQryA += "   AND A7_CODCLI ='" + Alltrim(cInXCodProd) + "' "
		cQryA += "   AND A7_FILIAL = '" + xFilial("SA7") + "' "

		cQry1 := cQryA

		TCQUERY cQryA NEW ALIAS "QRYB"

		If Eof()
			cQryA := "SELECT B1_COD AS A7_CODCLI,"
			cQryA += "       B1_COD AS A7_PRODUTO,"
			cQryA += "       B1_DESC AS A7_DESCCLI,"
			cQryA += "       B1_DESC ,"
			cQryA += "       ' ' AS D2_DOC,"
			cQryA += "       0   AS D2_QUANT,"
			cQryA += " 		 'D' AS A7_XTPCONV,"
			cQryA += "       1   AS A7_XCONV," // Fator de Conversão será por default 1 quando o código de Produto vier da SB1 invés da SB5
			cQryA += "       0   AS RECNOA7"
			cQryA += "  FROM " + RetSqlName("SB1") + " B1 "
			cQryA += " WHERE B1.D_E_L_E_T_ = ' ' "
			cQryA += "   AND B1_COD = '" + cInXCodProd + "' "
			cQryA += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"

			// Se o Fornecedor for uma Filial da Empresa retorno o próprio código do produto
			If !Empty(SA1->A1_FILTRF )
				cQry2	:= cQryA
			ElseIf lSuperUsr // Se for usuário do Fiscal restaura query original sem customização
				cQryA	:= cInQry
			Endif
		ElseIf !Empty(SA1->A1_FILTRF ) // Se o fornecedor for uma Filial da Empresa

			cQryA := "SELECT B1_COD AS A7_CODCLI,"
			cQryA += "       B1_COD AS A7_PRODUTO,"
			cQryA += "       B1_DESC AS A7_DESCCLI,"
			cQryA += "       B1_DESC ,"
			cQryA += "       ' ' AS D2_DOC,"
			cQryA += "       0   AS D2_QUANT,"
			cQryA += " 		 'D' AS A7_XTPCONV,"
			cQryA += "       1   AS A7_XCONV," // Fator de Conversão será por default 1 quando o código de Produto vier da SB1 invés da SB5
			cQryA += "       0   AS RECNOA7"
			cQryA += "  FROM " + RetSqlName("SB1") + " B1 "
			cQryA += " WHERE B1.D_E_L_E_T_ = ' ' "
			cQryA += "   AND B1_COD = '" + cInXCodProd + "' "
			cQryA += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"
		Endif

		QRYB->(DbCloseArea())
	Endif

	RestArea(aAreaOld)

Return cQryA

