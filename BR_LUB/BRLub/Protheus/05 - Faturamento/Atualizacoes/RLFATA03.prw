#Include 'Protheus.ch'


/*/{Protheus.doc} RLFATA03
// Rotina auxiliar de CAdastro de Produto x Cliente - Para atender os casos de códigos de produtos que saem diferente no XML - Dpaschoal
@author marce
@since 27/09/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function RLFATA03()

	
	If !cEmpAnt $ "06#16"
		MsgInfo("Empresa errada para executar esta rotina!")
		Return 
	Endif
	
	
	Private cString := "SZ3"

	sfPopSZ3()

	dbSelectArea("SZ3")
	dbSetOrder(1)
	
	AxCadastro(cString,"Cadastro auxiliar de Produto X Clientes",".T."/*cVldExc*/,".T."/*cVldAlt*/)

Return


Static Function sfPopSZ3()
	
	Local	cQry := ""
	Local	cAliasSZ3	:= "QSZ3"

	cQry := ""
	cQry += "SELECT Z1_EMIT,"
	cQry += "       Z1_DEST,"
	cQry += "       Z2_PRODUTO,"
	cQry += "       COALESCE((SELECT A7_PRODUTO"
	cQry += "                   FROM " + RetSqlName("SA7") + " A7 "
	cQry += "                  WHERE A7.D_E_L_E_T_ = ' ' "
	cQry += "                    AND A7_CLIENTE = A1_COD "
	cQry += "                    AND A7_LOJA = A1_LOJA"
	cQry += "                    AND A7_CODCLI = Z2_PRODUTO"
	cQry += "                    AND A7_FILIAL = '" + xFilial("SA7")+ "'),"
	cQry += "           COALESCE ((SELECT Z3_PRODUTO "
	cQry += "                        FROM " + RetSqlName("SZ3")+ " Z3 "
	cQry += "                       WHERE D_E_L_E_T_ =' ' "
	cQry += "                         AND Z3_CODCLI = Z2_PRODUTO "
	cQry += "                         AND Z3_CGCEMIT = A1_CGC "
	cQry += "                         AND Z3_CGCDEST = Z1_DEST "
	cQry += "                         AND Z3_FILIAL = '" + xFilial("SZ3")+ "'), 'XXX')) A7_PRODUTO"
	cQry += "  FROM " + RetSqlName("SZ1") + " Z1," + RetSqlName("SZ2") + " Z2," + RetSqlName("SA1") + " A1 "
	cQry += " WHERE Z1.D_E_L_E_T_ = ' ' "
	cQry += "   AND Z1_FILIAL = '" + xFilial("SZ1") + "' "
	cQry += "   AND Z1_STATUS <> '5' "
	cQry += "   AND Z1_TIPNF = '1' " // Apenas notas de saída
	cQry += "   AND Z1_DEST <> '" + SM0->M0_CGC + "'"
	cQry += "   AND A1.D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_CGC = Z1_EMIT"
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1")+ "'"
	cQry += "   AND Z2.D_E_L_E_T_ = ' '"
	cQry += "   AND Z2_ESTOQUE <> 'N' "
	cQry += "   AND Z2_CF NOT IN('5663','1921','1661','5906','5907','5905','5920')"
	cQry += "   AND Z2_QUANT > Z2_QTDDEV " // Verifica somente o que tem saldo a devolver
	cQry += "   AND Z2_CHAVE = Z1_CHAVE"
	cQry += "   AND Z2_FILIAL = '" + xFilial("SZ2")+ "'"
	cQry += "   AND EXISTS (SELECT F1_DOC"
	cQry += "                 FROM " + RetSqlName("SF1") + " F1 "
	cQry += "                WHERE F1_FORNECE = A1_COD "
	cQry += "                  AND F1_LOJA = A1_LOJA"
	cQry += "                  AND F1.D_E_L_E_T_ = ' '"
	cQry += "                  AND F1_FILIAL = '" +xFilial("SF1")+ "')"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasSZ3,.T.,.T.)
	
	While !Eof()
		If Alltrim((cAliasSZ3)->A7_PRODUTO) == "XXX"
			DbSelectArea("SZ3")
			RecLock("SZ3",.T.)
			SZ3->Z3_FILIAL	:= xFilial("SZ3")
			SZ3->Z3_CGCEMIT	:= (cAliasSZ3)->Z1_EMIT
			SZ3->Z3_CGCDEST	:= (cAliasSZ3)->Z1_DEST
			SZ3->Z3_CODCLI	:= (cAliasSZ3)->Z2_PRODUTO
			MsUnlock()
		Endif 	
		dbSelectArea(cAliasSZ3)
		dbSkip()
	EndDo
	
	(cAliasSZ3)->(DbCloseArea())
Return 
