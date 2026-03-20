#INCLUDE "protheus.ch"
#include "topconn.ch"

/*/{Protheus.doc} BFFATA01
(long_description)
	
@author MarceloLauschner
@since 06/02/2014
@version 1.0		

@return number, Preço de venda - Baixa de avaria ou venda Importação

@example
(examples)

@see (links_or_references)
/*/
User Function BFFATA01(lIsAvaria)

	Local 		nCusto 			:= 0
	//Local 		nValicm 		:= 0
	//Local 		nPiscof 		:= 0
	Local		aAreaOld		:= GetArea()
	Local		cQry 			:= " "
	Local		cLastSD1		:= ""
	Local		nVezesSD1		:= 0
	Local		nSumCusto		:= 0
	Local		nSumQte			:= 0
	Local		nPProd  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local		nPQtd   		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local		nPVrUnit   		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRCVEN"})
	Local		nPPrcTab   		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRUNIT"})
	Local		nPVlrItem  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
	Local		nPValDesc  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALDESC"})
	Local		nPDesc			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_DESCONT"})
	//Local		nPTpMov			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_OPER"})
	Local		nPLocal 		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
	Local		cProd 			:= aCols[n][nPProd]
		
	Default 	lIsAvaria		:= .T.

// 	Executa gravação do Log de Uso da rotina
	U_BFCFGM01()

	
	If lIsAvaria

		cQry += "SELECT TOP 3 D1.R_E_C_N_O_ AS REG "
		cQry += "  FROM "+RetSqlName("SD1") + " D1, " + RetSqlName("SF4") + " F4 "
		cQry += " WHERE F4.D_E_L_E_T_ = ' ' "
		If M->C5_TIPO == "N"
			cQry += "   AND F4_DUPLIC = 'S' "
		Endif
		cQry += "   AND F4_ESTOQUE = 'S' " 
		cQry += "   AND F4_CODIGO = D1_TES "
		cQry += "   AND F4_FILIAL = '"+xFilial("SF4")+"'"
		cQry += "   AND D1.D_E_L_E_T_ = ' ' "
		cQry += "   AND D1_COD =  '" + cProd + "' "
		cQry += "   AND D1_QUANT > 0 "
		cQry += "   AND D1_TIPO IN('N') "
		cQry += "   AND D1_LOCAL = '" + aCols[n][nPLocal] + "' "
		cQry += "   AND D1_FILIAL = '" + xFilial("SD1") + "' "
		cQry += " ORDER BY D1.R_E_C_N_O_ DESC "

		TCQUERY cQry NEW ALIAS "QD1"

		cRow := ""
		While !Eof()
			cRow += AllTrim(Str(QD1->REG)) + ","
			dbSelectArea("QD1")
			dbSkip()
		End
		QD1->(DbCloseArea())

		If !Empty(cRow)

			cRow := Substr(cRow,1,Len(cRow)-1)

			cQry := ""
			cQry += "SELECT AVG((D1_TOTAL-D1_VALDESC+D1_VALIPI+D1_ICMSRET+D1_VALFRE+D1_DESPESA)/D1_QUANT) CUSTO_TOTAL "
			cQry += "  FROM "+ RetSqlName("SD1")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND D1_COD = '" + cProd + "' "
			cQry += "   AND R_E_C_N_O_ IN(" + cRow + ") "
			cQry += "   AND D1_FILIAL = '" + xFilial("SD1") + "' "
	
			TCQUERY cQry NEW ALIAS "QD2"
	
			If !Eof()
				nCusto	:= QD2->CUSTO_TOTAL
			Endif
			QD2->(DbCloseArea())
		Endif

		nCusto	:= Round(nCusto,TamSX3("C6_PRCVEN")[2])
	Else
	
		// Busca as entradas do produto
		cQry := "SELECT D1_TIPO TIPO,
		cQry += "       D1_DTDIGIT DIGITADO,
		cQry += "       D1_COD COD,
		cQry += "       D1_QUANT QUANT,
		cQry += "       D1_TOTAL TOTAL,
		cQry += "       CASE WHEN F4.F4_AGRCOF = 'C' THEN  D1_VALIMP5 ELSE 0 END COFINS,
		cQry += "       CASE WHEN F4.F4_AGRPIS = 'P' THEN  D1_VALIMP6 ELSE 0 END PIS,
		cQry += "       CASE WHEN F4.F4_AGREG  = 'I' THEN  D1_VALICM  ELSE 0 END ICMS,
		cQry += "       CASE WHEN F4.F4_DESTACA ='S' THEN  D1_VALIPI  ELSE 0 END IPI,
		cQry += "               D1_VALFRE FRETE,
		cQry += "               D1_DESPESA DESPESA,
		cQry += "               D1_ICMSRET ICMSRET,
		cQry += "               D1_II II,
		cQry += "               D1_CUSTO CUSTO
		cQry += "          FROM "+RetSqlName("SD1") + " D1, " + RetSqlName("SF4") + " F4 "
		cQry += "         WHERE D1_FILIAL = '"+xFilial("SD1")+"' "
		cQry += "           AND D1_LOCAL = '" + aCols[n,nPLocal]+ "'"
		cQry += "           AND D1_COD = '" + cProd + "' "
		cQry += "           AND D1.D_E_L_E_T_ = ' '
		cQry += "           AND F4_ESTOQUE = 'S'
		cQry += "           AND F4_DUPLIC = 'S'
		cQry += "           AND F4.D_E_L_E_T_ = ' '
		cQry += "           AND F4_CODIGO = D1_TES
		cQry += "           AND F4_FILIAL = '"+xFilial("SF4")+"'"
		cQry += "         ORDER BY D1_DTDIGIT DESC,D1_TIPO )
         
		TCQUERY cQry NEW ALIAS "QD1"

		While !Eof()
			// Efetua controle para saber que somente a última data de entrada será considerada
			If !Empty(cLastSD1) .And. cLastSD1 <> QD1->DIGITADO .And. nVezesSD1 > 0
				Exit
			Endif
			If QD1->TIPO =="N"
				nVezesSD1++
			Endif
			cLastSD1		:= QD1->DIGITADO
			nSumCusto		+= QD1->TOTAL + QD1->IPI + QD1->COFINS + QD1->PIS + QD1->ICMS + QD1->FRETE + QD1->DESPESA
			nSumQte		+= QD1->QUANT
			DbSelectArea("QD1")
			DbSkip()
		Enddo
		QD1->(DbCloseArea())
		
		nCusto	:= Round(nSumCusto/nSumQte,TamSX3("C6_PRCVEN")[2])
		
		
		aCols[n][nPPrcTab] 	:= nCusto
		aCols[n][nPVrUnit]	:= nCusto
				
		aCols[n][nPValDesc] 	:= 0
		aCols[n][nPDesc] 		:= 0
				
		aCols[n][nPVlrItem]:= A410Arred(aCols[n][nPQtd] * aCols[n][nPVrUnit],"D2_PRCVEN")
				
		MaFisAlt("IT_QUANT",aCols[n][nPQtd],n)
		MaFisAlt("IT_PRCUNI",aCols[n][nPVrUnit],n)
		MaFisAlt("IT_VALMERC",aCols[n][nPVlrItem],n)
		If Type('oGetDad:oBrowse')<>"U"
			oGetDad:oBrowse:Refresh()
			Ma410Rodap()
		Endif
	Endif
	RestArea(aAreaOld)

Return(nCusto)



