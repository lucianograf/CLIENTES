#Include 'Protheus.ch'

/*/{Protheus.doc} BFFATM28
(Rotina que envia novo Link para aprovação da Diretoria quando da solicitação do Gerente)
@author MarceloLauschner
@since 18/08/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/

User Function BFFATM28(lInAuto)

	Local	cQry 	:= ""
	Default lInAuto	:= .T.

	cQry := "SELECT Z9_DESCR,Z9_USER,Z9_ORIGEM,Z9_NUM,Z9_PRCRET,R_E_C_N_O_ Z9RECNO"
	cQry += "  FROM "+ RetSqlName("SZ9")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND Z9_FILIAL = '" +xFilial("SZ9")+ "'"
	cQry += "   AND Z9_EVENTO IN('8','9')"
	cQry += "   AND Z9_PRCRET IN('A','D')"
	cQry += "   AND Z9_DATA >= '" + DTOS(Date()-30) + "' "

	If Select("QRZ9") > 0
		QRZ9->(DbCloseArea())
	Endif

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QRZ9', .F., .T.)

	While !Eof()
		DbGoto(QRZ9->Z9RECNO)
		// Verifica se não aconteceu a validação por outra sessão 
		If SZ9->Z9_PRCRET <> "S"
		
			U_BFFATA30(.T./*lAuto*/,QRZ9->Z9_NUM/*cInPed*/,Iif(QRZ9->Z9_ORIGEM == "P",1,2)/*nInPedOrc*/,QRZ9->Z9_PRCRET,Padr(QRZ9->Z9_USER,6),QRZ9->Z9_DESCR)

			DbSelectArea("SZ9")
			DbGoto(QRZ9->Z9RECNO)
			RecLock("SZ9",.F.)
			SZ9->Z9_PRCRET	:= "S"
			MsUnlock()

			If !lInAuto
				MsgInfo("Solicitada aprovação da Diretoria para o " + Iif(QRZ9->Z9_ORIGEM == "P","Pedido: ","Orçamento: ") + QRZ9->Z9_NUM,"BFFATM28 - Solicitação diretoria")
			Endif
		Endif
		DbSelectArea("QRZ9")
		DbSkip()
	Enddo

	QRZ9->(DbCloseArea())

Return
