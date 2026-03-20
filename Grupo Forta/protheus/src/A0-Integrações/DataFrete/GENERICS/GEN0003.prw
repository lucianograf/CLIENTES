#INCLUDE "totvs.ch"

/*
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Programa    | inclusao de dados    | Autor | William Souza - TOTVS S/A                | Data | ABR./2023   |
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Descricao   | GENERICO - Gravação de dados na tabela P01     			            		 			     |
+-------------+----------------------------------------------------------------------------------------------+
| Uso         |                                                                                              |
+-------------+----------------------------------------------------------------------------------------------+
*/

User Function GEN0003(_nRecP01,_cJson,_cStatus)

	DbSelectArea("P01")
	P01->(dbGoTo(_nRecP01))

	RecLock("P01",.F.)

	P01->P01_STATUS := _cStatus
	P01->P01_DATPRO := DDATABASE
	P01->P01_HORPRO := TIME()
	P01->P01_OUTPUT := _cJson

	MsUnlock()

Return
