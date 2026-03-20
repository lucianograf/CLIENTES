#include 'protheus.ch'
#include "Rwmake.ch"
#include "Topconn.ch"

User Function MA410DEL()


	Local lRet 		:= .T.

	cQry := "DELETE FROM " + RetSqlName("ZCC")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND ZCC_NUM  = '"+SC5->C5_NUM + "' "
	cQry += "   AND ZCC_FILIAL = '" + xFilial("ZCC") + "' "
	Begin Transaction
		Iif(TcSqlExec(cQry) < 0,ConOut(TcSqlError()),TcSqlExec("COMMIT"))
	End Transaction

Return
