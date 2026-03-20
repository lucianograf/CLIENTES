#INCLUDE "totvs.ch"

/*
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Programa    | integração de dados  | Autor | William Souza - Loranto Tech Knowledge   | Data | Maio./2024  |
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Descricao   | GENERICO - Gravação de dados na tabela P01     			            		 			     |
+-------------+----------------------------------------------------------------------------------------------+
| Uso         |                                                                                              |
+-------------+----------------------------------------------------------------------------------------------+
*/

User Function GEN0002(_cAPI,_cEndPoint,_cTabela,_cFUUID,_cJson,_cOper)

	DbSelectArea("P01")
	RecLock("P01", .T.)

	P01->P01_STATUS := "0"
	P01->P01_ID     := _cFUUID
	P01->P01_DATA   := DDATABASE
	P01->P01_HORA   := TIME()
	P01->P01_API    := _cAPI
	P01->P01_ALIAS  := _cTabela
	P01->P01_ENDPON := _cEndPoint
	P01->P01_METODO := "POST"
	P01->P01_FILORI := FwFilial("P01")
	P01->P01_OPERAC := _cOper
	P01->P01_ORIGEM := IIF(_cOper == "2","TOTVS","DATAFRETE")
	P01->P01_INPUT  := _cJson

	MsUnlock()

Return
