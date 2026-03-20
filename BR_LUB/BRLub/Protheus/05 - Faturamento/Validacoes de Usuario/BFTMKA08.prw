#Include 'Protheus.ch'

/*/{Protheus.doc} BFTMKA08
(Calcula F&I e Verba Marketing)
@author MarceloLauschner
@since 09/09/2014
@version 1.0
@param cInCliente, character, (Descrição do parâmetro)
@param cInLoja, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function BFTMKA08(cInCliente,cInLoja,cInProduto)
	
	Local		aAreaOld		:= GetArea()
	Local		cQry
	Local		nPercFI			:= 0
	Local		nPercMKT		:= 0
	Local		nPercRet		:= 0
	
	// Se não existir a tabela de Fretes na base 
	DbSelectArea("SX2")
	DbSetOrder(1)
	If !DbSeek("SZP")
		Return {nPercFI,nPercMKT,nPercRet}
	Endif
	
	cQry := ""
	cQry += "SELECT ZP_FI_PERC, ZP_VERBMKT,ZP_PRETENC "
	cQry += "  FROM " +RetSqlName("SB1") + " SB1, " +RetSqlName("SZP") + " SZP "
	cQry += " WHERE SZP.D_E_L_E_T_ = ' ' "
	cQry += "   AND '" + DTOS(dDataBase) + "' BETWEEN SZP.ZP_DATAINI AND SZP.ZP_DATAFIN "
	cQry += "   AND SZP.ZP_GRUPO = SB1.B1_GRUPO "
	cQry += "   AND SZP.ZP_LOJA = '" + cInloja + "' "
	cQry += "   AND SZP.ZP_CLIENTE = '" + cInCliente + "' "
	cQry += "   AND SZP.ZP_FILIAL = '" + xFilial("SZP") + "' "
	cQry += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SB1.B1_BLOQFAT = 'N' " 
	cQry += "   AND SB1.B1_COD = '" + cInProduto + "' "
	cQry += "   AND SB1.B1_FILIAL = '" + xFilial("SB1") + "' "
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRY', .F., .T.)
	
	If !Eof()		
		nPercFI 	:= QRY->ZP_FI_PERC
		nPercMKT 	:= QRY->ZP_VERBMKT		
		nPercRet	:= QRY->ZP_PRETENC
	Endif
	QRY->(dbCloseArea())
	
Return {nPercFI,nPercMKT,nPercRet}

