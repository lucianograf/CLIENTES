#include 'protheus.ch'
#include "Rwmake.ch"
#include "Topconn.ch"

/*
+----------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! A410EXC                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada criado para atender a necessidade de   !
!                  ! excluir uma reserva realizada pelo pedido de venda inclu!
!                  ! ido no protheus                                         !
+------------------+---------------------------------------------------------+
!Autor             ! TSCB56 - Rafael de Souza                                !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/09/19                                                !
+------------------+---------------------------------------------------------+
*/
User Function A410EXC()

	// Necessï¿½rio retorno lï¿½gico para o PE.
	// https://tdn.totvs.com/pages/releaseview.action?pageId=6784034
	Local lOk	:= .T.

	Begin Sequence
		Monitor_log.U_Record_Log(SC5->C5_NUM, ProcName() , "Inicio da execução - Linha 26" , .T.)
	End Sequence
	
	cQry := "DELETE FROM " + RetSqlName("ZCC")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND ZCC_NUM  = '"+SC5->C5_NUM + "' "
	cQry += "   AND ZCC_FILIAL = '" + xFilial("ZCC") + "' "

	Begin Transaction
		Iif(TcSqlExec(cQry) < 0,ConOut(TcSqlError()),TcSqlExec("COMMIT"))
	End Transaction

	// ---------------------------- aFill ----------------------------------- //
	If GetNewPar("DC_AFILLOK",.F.)
		Begin Sequence
			If !Empty(SC5->C5_XPROCIM) .And. !IsInCallStack("U_UZXIMP")
				ShowHelpDlg("aFill";
					,{"Pedido de venda não poderá ser excluído pela rotina padrão pois foi gerado pelo aFill."},1;
					,{"Realize a exclusão do pedido pela rotina de pedido de venda do aFill."},1)
				Break
			EndIf
			Recover
			lOk := .F.
		End Sequence
	Endif
	// ---------------------------- aFill ----------------------------------- //

	Begin Sequence
		Monitor_log.U_Record_Log(SC5->C5_NUM, ProcName() , "Depois da execução - Linha 1147" , .T.)
	End Sequence
Return lOk
