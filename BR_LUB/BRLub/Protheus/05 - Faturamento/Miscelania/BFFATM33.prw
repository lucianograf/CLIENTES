#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATM33
(Calcula comissão novo modelo Julho/2016 de forma Offline para o pedido e notas - Necessário rodar FINA440 manualmente depois ou implementar )
@author MarceloLauschner
@since 07/07/2016
@version 1.0
@param cInVend, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFFATM33(cInVend)
	
	
	Local	cQry	:= ""
	Local	cFilBk	:= cFilAnt
	

	If cEmpAnt == "05"
		sfFrimazo(cInVend)
		Return 
	Endif
	
	Default	cInVend	:= ""
	If Select("SM0") == 0
		RpcSetType(3)
		//RpcSetEnv - Abertura do ambiente em rotinas automáticas ( [ cRpcEmp ] [ cRpcFil ] [ cEnvUser ] [ cEnvPass ] [ cEnvMod ] [ cFunName ] [ aTables ] [ lShowFinal ] [ lAbend ] [ lOpenSX ] [ lConnect ] ) --> lRet
		RPCSetEnv("02","01")
		Sleep(5000)
	Else
	
		If !MsgYesNO("Deseja recalcular comissões do vendedor '" + cInVend+ "' ?","BFFATM33")
			Return 
		Endif
	Endif
	
	cQry := "SELECT C5_NUM,C5_FILIAL "
	cQry += "  FROM " + RetSqlName("SC5")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND C5_EMISSAO >= '20170101' " //BETWEEN '20160601' AND '20160630' "
	cQry += "   AND C5_VEND1 = '" + cInVend + "' "
	cQry += "   AND C5_FILIAL IN "+ FormatIN(GetMv("BF_FILIAIS"),"/")
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QC5",.T.,.T.)
	
	While !Eof()
		// Altera a filial 
		cFilAnt	:= QC5->C5_FILIAL
		sfAtuPed(QC5->C5_NUM)
		DbSelectARea("QC5")
		DbSkip()
	Enddo
	QC5->(DbCloseArea())
	cFilAnt := cFilBk
	
Return


Static Function sfAtuPed(cInPed)
	
	Local	nPComis1	:= 0
	Local	nPComis2	:= 0
	Local	nDescMed	:= 0
	Local	nTotBrut	:= 0
	Local	nTotLiq		:= 0	
	Local	cQry	
	
	cQry := "SELECT SUM(C6_PRUNIT*C6_QTDVEN) PRCTAB, SUM((C6_PRCVEN*C6_QTDVEN)-((C6_XVLRTAM+C6_XFLEX)*C6_QTDVEN)) PRCLIQ "
	cQry += "  FROM " + RetSqlName("SC6") + " C6," + RetSqlName("SF4") + " F4 "
	cQry += " WHERE F4.D_E_L_E_T_ =' ' "
	cQry += "   AND F4_DUPLIC = 'S' "
	cQry += "   AND F4_CODIGO = C6_TES "
	cQry += "   AND F4_FILIAL = '" + xFilial("SF4")+ "'"
	cQry += "   AND C6.D_E_L_E_T_ =' ' "
	cQry += "   AND C6_NUM = '" + cInPed + "'"
	cQry += "   AND C6_FILIAL = '" + xFilial("SC6") + "'"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QC6T",.T.,.T.)
	
	If !Eof()
		nTotBrut	:= QC6T->PRCTAB
		nTotLiq		:= QC6T->PRCLIQ
	Endif
	QC6T->(DbCloseArea())
	
	nDescMed	:= 100 - (Round(nTotLiq/nTotBrut*100,2))
	
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cInPed)
	RecLock("SC5",.F.)
	SC5->C5_XPDESMD	:= nDescMed
	MsUnlock()
	
	
	DbSelectArea("SC6")
	DbSetOrder(1)
	DbSeek(xFilial("SC6")+cInPed)
	While !Eof() .And. SC6->C6_FILIAL +SC6->C6_NUM == xFilial("SC6") + cInPed
		
		nTotBrut	:= SC6->C6_PRUNIT
		nTotLiq		:= SC6->C6_PRCVEN
		nPComis1	:= 0
		If !Empty(SC5->C5_VEND1)
		Endif
		
		
		nPComis2	:= 0
		If !Empty(SC5->C5_VEND2)
		Endif
		
		DbSelectArea("SC6")
		RecLock("SC6",.F.)
		SC6->C6_COMIS1	:= nPcomis1
		SC6->C6_COMIS2	:= nPComis2
		SC6->C6_COMIS3	:= 0
		MsUnlock()
		
		DbSelectArea("SD2")
		DbSetOrder(8) // D2_FILIAL, D2_PEDIDO, D2_ITEMPV, R_E_C_N_O_, D_E_L_E_T_
		DbSeek(xFilial("SD2")+SC6->C6_NUM+SC6->C6_ITEM)
		While !Eof() .And. SD2->D2_FILIAL+SD2->D2_PEDIDO+SD2->D2_ITEMPV == xFilial("SC6")+SC6->C6_NUM+SC6->C6_ITEM
			RecLock("SD2",.F.)
			SD2->D2_COMIS1	:= nPcomis1
			SD2->D2_COMIS2	:= nPComis2
			SD2->D2_COMIS3	:= 0
			MsUnlock()
			SD2->(DbSkip())
		Enddo
		DbSelectArea("SC6")
		DbSkip()
	Enddo
	
Return



Static Function sfFrimazo(cInVend)
	
	
	Local	cQry	:= ""
	Local	cFilBk	:= cFilAnt
	
	Default	cInVend	:= ""
	If Select("SM0") == 0
		RpcSetType(3)
		//RpcSetEnv - Abertura do ambiente em rotinas automáticas ( [ cRpcEmp ] [ cRpcFil ] [ cEnvUser ] [ cEnvPass ] [ cEnvMod ] [ cFunName ] [ aTables ] [ lShowFinal ] [ lAbend ] [ lOpenSX ] [ lConnect ] ) --> lRet
		RPCSetEnv("02","01")
		Sleep(5000)
	Else
	
		If !MsgYesNO("Deseja recalcular comissões do vendedor '" + cInVend+ "' ?","BFFATM33")
			Return 
		Endif
	Endif
	
	cQry := "SELECT C5_NUM,C5_FILIAL "
	cQry += "  FROM " + RetSqlName("SC5")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	If IsInCallStack("U_FZMATR54")
		cQry += "   AND C5_EMISSAO >= '" + Dtos(mv_par02) + "' "
		cQry += "   AND C5_EMISSAO <= '" + Dtos(mv_par03) + "'" 
		cQry += "   AND C5_VEND1 >= '" + MV_PAR04 + "' "
		cQry += "   AND C5_VEND1 <= '" + MV_PAR05 + "' "
	Else
		cQry += "   AND C5_EMISSAO >= '20180501' " //BETWEEN '20160601' AND '20160630' "
		cQry += "   AND C5_VEND1 = '" + cInVend + "' "
	Endif
	cQry += "   AND C5_FILIAL = '"+xFilial("SC5")+"' "
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QC5",.T.,.T.)
	
	While !Eof()
		// Altera a filial 
		cFilAnt	:= QC5->C5_FILIAL
		sfAtuPedFz(QC5->C5_NUM)
		DbSelectARea("QC5")
		DbSkip()
	Enddo
	QC5->(DbCloseArea())
	cFilAnt := cFilBk
	
Return


Static Function sfAtuPedFz(cInPed)
	
	Local	nPComis1	:= 0
	Local	nPComis2	:= 0
	Local	nDescMed	:= 0
	Local	nTotBrut	:= 0
	Local	nTotLiq		:= 0	
	Local	cQry	
	
	cQry := "SELECT SUM(C6_PRUNIT*C6_QTDVEN) PRCTAB, SUM(C6_PRCVEN*C6_QTDVEN) PRCLIQ "
	cQry += "  FROM " + RetSqlName("SC6") + " C6," + RetSqlName("SF4") + " F4 "
	cQry += " WHERE F4.D_E_L_E_T_ =' ' "
	cQry += "   AND F4_DUPLIC = 'S' "
	cQry += "   AND F4_CODIGO = C6_TES "
	cQry += "   AND F4_FILIAL = '" + xFilial("SF4")+ "'"
	cQry += "   AND C6.D_E_L_E_T_ =' ' "
	cQry += "   AND C6_NUM = '" + cInPed + "'"
	cQry += "   AND C6_FILIAL = '" + xFilial("SC6") + "'"
	
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QC6T",.T.,.T.)
	
	If !Eof()
		nTotBrut	:= QC6T->PRCTAB
		nTotLiq		:= QC6T->PRCLIQ
	Endif
	QC6T->(DbCloseArea())
	
	nDescMed	:= 100 - (Round(nTotLiq/nTotBrut*100,2))
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cInPed)
	
	
	DbSelectArea("SC6")
	DbSetOrder(1)
	DbSeek(xFilial("SC6")+cInPed)
	While !Eof() .And. SC6->C6_FILIAL +SC6->C6_NUM == xFilial("SC6") + cInPed
		
		nTotBrut	:= SC6->C6_PRUNIT
		nTotLiq		:= SC6->C6_PRCVEN
		nPComis1	:= 0
		If !Empty(SC5->C5_VEND1)
			
		Endif
		
		
		nPComis2	:= 0
		If !Empty(SC5->C5_VEND2)
		Endif
		
		DbSelectArea("SC6")
		RecLock("SC6",.F.)
		SC6->C6_COMIS1	:= nPcomis1
		SC6->C6_COMIS2	:= nPComis2
		SC6->C6_COMIS3	:= 0
		SC6->C6_COMIS4	:= 0
		SC6->C6_COMIS5	:= 0
		MsUnlock()
		
		DbSelectArea("SD2")
		DbSetOrder(8) // D2_FILIAL, D2_PEDIDO, D2_ITEMPV, R_E_C_N_O_, D_E_L_E_T_
		DbSeek(xFilial("SD2")+SC6->C6_NUM+SC6->C6_ITEM)
		While !Eof() .And. SD2->D2_FILIAL+SD2->D2_PEDIDO+SD2->D2_ITEMPV == xFilial("SC6")+SC6->C6_NUM+SC6->C6_ITEM
			RecLock("SD2",.F.)
			SD2->D2_COMIS1	:= nPcomis1
			SD2->D2_COMIS2	:= nPComis2
			SD2->D2_COMIS3	:= 0
			SD2->D2_COMIS4	:= 0
			SD2->D2_COMIS5	:= 0
			MsUnlock()
			SD2->(DbSkip())
		Enddo
		DbSelectArea("SC6")
		DbSkip()
	Enddo
	
Return

