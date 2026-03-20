#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} RLCFGM03
//Efetua o ajuste forçado dos valores de preço unitário no controle de poder de Terceiros
@author Marcelo Alberto Lauschner
@since 27/02/2018
@version 6

@type function
/*/
User function RLCFGM03()
	
	 //[ cRpcEmp ] [ cRpcFil ] [ cEnvUser ] [ cEnvPass ] [ cEnvMod ] [ cFunName ] [ aTables ] [ lShowFinal ] [ lAbend ] [ lOpenSX ] [ lConnect ] ) --> lRet
	
	
	Local	cQry 		:= ""
	Local	cTmpAlias	
	Local	cCodPrd,nVunit,cIdentB6
	Local	nTmD1Vuni	
	
	RPCSetEnv("06","01","admin","",,,{"SX2","SX6","SD1","SB6","SC6","SD2"})
	
	cTmpAlias	:= GetNextAlias()
	nTmD1Vuni	:= TamSX3("D1_VUNIT")[2]
	
	cQry += "SELECT D1_COD,D1_VUNIT,D1_IDENTB6,D1_TOTAL,D1_QUANT,D1_VALDESC,R_E_C_N_O_ D1RECNO "
	cQry += "  FROM "+ RetSqlName("SD1")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND D1_FORNECE = '000012'"
	cQry += "   AND D1_FILIAL = '" + xFilial("SD1")+ "'"
	//cQry += "   AND D1_COD = 'JP183RE' "
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cTmpAlias,.T.,.T.)
	
	While !Eof()
		cCodPrd		:= (cTmpAlias)->D1_COD
		cIdentB6	:= (cTmpAlias)->D1_IDENTB6
		nVunit		:= Round(((cTmpAlias)->D1_TOTAL - (cTmpAlias)->D1_VALDESC) / (cTmpAlias)->D1_QUANT,nTmD1Vuni)
		
		// Só atualiza se for diferente o preço unitário 
		If (cTmpAlias)->D1_VUNIT <> nVunit
			sfAtuSD1(cCodPrd,cIdentB6,nVunit,(cTmpAlias)->D1RECNO)
		Endif
		
		sfAtuSC6(cCodPrd,cIdentB6,nVunit)
		
		sfAtuSD2(cCodPrd,cIdentB6,nVunit)
		
		sfAtuSB6(cCodPrd,cIdentB6,nVunit)
		
		DbSelectArea(cTmpAlias)
		DbSkip()
	Enddo
	(cTmpAlias)->(DbCloseArea())

	
Return


/*/{Protheus.doc} sfAtuSD1
//Ajusta o preço unitário na nota de entrada
@author Marcelo Alberto Lauschner
@since 27/02/2018
@version 6
@param cCodPrd, characters, descricao
@param cIdentB6, characters, descricao
@param nVunit, numeric, descricao
@param nD1RECNO, numeric, descricao
@type function
/*/
Static Function sfAtuSD1(cCodPrd,cIdentB6,nVunit,nD1RECNO)
	
	Local	aAreaOld	:= GetArea()
	
	DbSelectArea("SD1")
	DbGoto(nD1Recno)
	If !Eof()
		RecLock("SD1",.F.)
		SD1->D1_VUNIT 	:= nVunit
		MsUnlock()
	Endif
	
	RestArea(aAreaOld)

Return 



/*/{Protheus.doc} sfAtuSC6
//Ajusta o preço unitário no Pedido de Venda 
@author Marcelo Alberto Lauschner
@since 27/02/2018
@version 6
@param cCodPrd, characters, descricao
@param cIdentB6, characters, descricao
@param nVunit, numeric, descricao
@type function
/*/
Static Function sfAtuSC6(cCodPrd,cIdentB6,nVunit)
	
	Local	aAreaOld	:= GetArea()
	Local	cQry 		:= ""
	Local	cTmpAlias	:= GetNextAlias()
	
	cQry += "SELECT R_E_C_N_O_ C6RECNO "
	cQry += "  FROM "+ RetSqlName("SC6")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND C6_PRODUTO = '"+cCodPrd+"' "
	cQry += "   AND C6_IDENTB6 = '" + cIdentB6 + "'"
	cQry += "   AND C6_FILIAL = '" + xFilial("SC6")+ "'"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cTmpAlias,.T.,.T.)
	
	While !Eof()
		DbSelectArea("SC6")
		DbGoto((cTmpAlias)->C6RECNO)
		If !Eof()
			RecLock("SC6",.F.)
			SC6->C6_PRCVEN 	:= nVunit
			MsUnlock()
		Endif
		
		DbSelectArea(cTmpAlias)
		DbSkip()
	Enddo
	(cTmpAlias)->(DbCloseArea())
	
	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfAtuSD2
//Ajusta o preço unitário na Nota fiscal de saída
@author Marcelo Alberto Lauschner
@since 27/02/2018
@version 6
@param cCodPrd, characters, descricao
@param cIdentB6, characters, descricao
@param nVunit, numeric, descricao
@type function
/*/
Static Function sfAtuSD2(cCodPrd,cIdentB6,nVunit)
	
	Local	aAreaOld	:= GetArea()
	Local	cQry 		:= ""
	Local	cTmpAlias	:= GetNextAlias()
	
	cQry += "SELECT R_E_C_N_O_ D2RECNO "
	cQry += "  FROM "+ RetSqlName("SD2")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND D2_COD = '"+cCodPrd+"' "
	cQry += "   AND D2_IDENTB6 = '" + cIdentB6 + "'"
	cQry += "   AND D2_FILIAL = '" + xFilial("SD2")+ "'"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cTmpAlias,.T.,.T.)
	
	While !Eof()
		DbSelectArea("SD2")
		DbGoto((cTmpAlias)->D2RECNO)
		If !Eof()
			RecLock("SD2",.F.)
			SD2->D2_PRCVEN 	:= nVunit
			MsUnlock()
		Endif
		
		DbSelectArea(cTmpAlias)
		DbSkip()
	Enddo
	(cTmpAlias)->(DbCloseArea())
	
	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfAtuSB6
//Ajusta o preço unitário na SB6 - Controle Poder Terceiros
@author Marcelo Alberto Lauschner
@since 27/02/2018
@version 6
@param cCodPrd, characters, descricao
@param cIdentB6, characters, descricao
@param nVunit, numeric, descricao
@type function
/*/
Static Function sfAtuSB6(cCodPrd,cIdentB6,nVunit)
	
	Local	aAreaOld	:= GetArea()
	Local	cQry 		:= ""
	Local	cTmpAlias	:= GetNextAlias()
	
	cQry += "SELECT R_E_C_N_O_ B6RECNO "
	cQry += "  FROM "+ RetSqlName("SB6")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND B6_PRODUTO = '"+cCodPrd+"' "
	cQry += "   AND B6_IDENT = '" + cIdentB6 + "'"
	cQry += "   AND B6_FILIAL = '" + xFilial("SB6")+ "'"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cTmpAlias,.T.,.T.)
	
	While !Eof()
		DbSelectArea("SB6")
		DbGoto((cTmpAlias)->B6RECNO)
		If !Eof()
			RecLock("SB6",.F.)
			SB6->B6_PRUNIT 	:= nVunit
			MsUnlock()
		Endif
		
		DbSelectArea(cTmpAlias)
		DbSkip()
	Enddo
	(cTmpAlias)->(DbCloseArea())
	
	RestArea(aAreaOld)

Return

