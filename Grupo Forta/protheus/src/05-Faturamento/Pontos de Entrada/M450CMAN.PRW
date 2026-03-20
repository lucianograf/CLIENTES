/*/{Protheus.doc} M450CMAN
Ponto de entrada na liberação manual de crédito do cliente
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/07/2021
@return variant, return_description
/*/
User Function M450CMAN()

	Local		aAreaOld	:= GetArea()
	Local		nOpcLib		:= ParamIxb[1]
	Local		nReturn		:= 0
	Private		aPedLog		:= {}


	If nOpcLib	== 3 	// Rejeita
		sfLog("202","Rejeição de Crédito")
	ElseIf nOpcLib == 1 // Libera
		sfLog("200","Liberação de Crédito")
	Endif

	nReturn	:= nOpcLib

	RestArea(aAreaOld)

Return nReturn > 0


Static Function sfLog(cInTipo,cInDesc)

	Local 	cQry 	

	cQry := "SELECT DISTINCT C9_PEDIDO "
	cQry += "  FROM "+RetSqlName("SC9")+" SC9 " 
	cQry += " WHERE C9_FILIAL='"+xFilial("SC9")+"' "
	cQry += "   AND C9_CLIENTE='"+SA1->A1_COD+"' "
	If ( SuperGetMv("MV_CREDCLI")=="L" )
		cQry += " AND C9_LOJA='"+SA1->A1_LOJA+"' "
	EndIf
	cQry += "   AND C9_BLCRED <>'  ' "
	cQry += "   AND C9_BLCRED <> '09' "
	cQry += "   AND C9_BLCRED <> '10' "
	cQry += "   AND C9_BLCRED <> 'ZZ' "
	cQry += "   AND D_E_L_E_T_=' ' "
	

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QSC9M",.T.,.F.)

	While !Eof() 
		
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+QSC9M->C9_PEDIDO)

		U_MLFATP01(cInTipo,cInDesc + " Pedido: "+SC5->C5_NUM)
 
		DbSelectArea("QSC9M")
		DbSkip()
	Enddo 
	QSC9M->(DbCloseArea())

Return 

