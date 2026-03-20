#include 'protheus.ch'
#include 'parmtype.ch'

/*
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Programa    | integração de dados  | Autor | William Souza - Loranto Tech Knowledge   | Data | Maio./2024  |
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Descricao   | Job - processamento de WS de saída de dados para o datafrete          		 			     |
+-------------+----------------------------------------------------------------------------------------------+
| Uso         |                                                                                              |
+-------------+----------------------------------------------------------------------------------------------+
*/
User Function DTJOB002(cAPI)
	RPCSetType(3)
	RpcSetEnv( "01" , "0101" , "" , "" , 'FAT' )

	//StartJob("u_DTJOB02A", GetEnvServer(), .F., cAPI )   //job dados enviado   DATAFRETE
	u_DTJOB02A(cAPI)
	RpcClearEnv()

Return

//------------------------------------------------*
//	Rotina de Processamento
//------------------------------------------------*
User Function DTJOB02A(cAPI)
	//Local _lJob      := .t.//GetMV("MV_XDFJOB")
	Local _cAliasP01 := GetNextAlias()
	Local _oResponse := JsonObject():New()
	Local _aRet      := {}
	Local _cStatus   := ""

	//Habilita o job para processamento
	/*if !_lJob
		Return .t.
	Endif*/

	BeginSql Alias _cAliasP01
		SELECT top 10 R_E_C_N_O_ AS P01RECNO 
		FROM %Table:P01%
		WHERE %NotDel%
		AND P01_DATPRO = ''
		AND P01_API    = %exp:cAPI%
		AND P01_HORPRO = ''
		AND P01_STATUS = '0'
		AND P01_OPERAC = '2'
	EndSql

	//marco os registros para evitar o reprocessamento
	/*While !(_cAliasP01 )->(Eof())
		u_GEN0003((_cAliasP01 )->P01RECNO,'',"1")
		(_cAliasP01 )->(dbSkip())
	end*/

	DbSelectArea("P01")

	While (_cAliasP01 )->(!Eof())

		P01->(DBGOTO((_cAliasP01)->P01RECNO))

		_aRet := u_WSCLI001(P01->P01_INPUT,ALLTRIM(P01->P01_ENDPON),ALLTRIM(P01->P01_API))
		
		if  _aRet[1] == "1"
			u_GEN0003((_cAliasP01 )->P01RECNO,_aRet[2],"1")
		else
			u_GEN0003((_cAliasP01 )->P01RECNO,_aRet[2],"2")
		EndIf

		(_cAliasP01 )->(dbSkip())

	End

	(_cAliasP01)->(dbCloseArea())
Return

