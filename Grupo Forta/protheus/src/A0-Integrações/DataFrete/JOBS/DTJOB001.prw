#include 'protheus.ch'
#include 'parmtype.ch'

/*
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Programa    | Job                  | Autor | William Souza - Loranto Tech knowledge   | Data | MAIO/2024   |
+-------------+----------------------+-------+------------------------------------------+------+-------------+
| Descricao   | Job - Alimentar tabela P01 com dados dados da NFE                   		 			     |
+-------------+----------------------------------------------------------------------------------------------+
| Uso         |                                                                                              |
+-------------+----------------------------------------------------------------------------------------------+
*/
User Function DTJOB001()

	Local _cAliasP01 := GetNextAlias()
	Local _aRet      := {}
	Local _cJson     := {}
	Local _cFUUID := FWUUID(cvaltochar(Randomize( 10, 1000 )))

	RpcSetEnv( "01" , "0101" , "" , "" , 'FAT' )

	BeginSql Alias _cAliasP01
		select 
			b.f2_doc, 
			b.f2_serie,
			b.R_E_C_N_O_ as 'RECID',
			c.c5_num 
		from 
			%table:SF3% a 
		inner join 
			%table:SF2% b 
		on 
			b.F2_CHVNFE = a.F3_CHVNFE and 
			b.%NOTDEL% 
		inner join 
			%table:sc5% c 
		on 
			b.f2_doc   = c.c5_nota and
			b.f2_serie = c.c5_serie 
		where 
			a.%NOTDEL%          and 
			a.F3_PROTOC  <> ' ' and 
			b.f2_xdfrete = ' '  and
			b.f2_emissao > '20240101' and
			b.f2_especie = 'SPED'
	EndSql

	While !(_cAliasP01 )->(Eof())

		_aRet := u_GEN0004((_cAliasP01 )->f2_doc, (_cAliasP01 )->f2_serie)

		If _aRet[1] == 1 // TROUXE O XML DA DANFE

			_cJson := '{"xml":"' + encode64(_aRet[2]) + '","infComp":{"numero_pedido": "'+alltrim((_cAliasP01 )->c5_num)+'"}}'

			u_GEN0002("WSDTNF","/nota-fiscal","SF2",_cFUUID,_cJson,"2")

			dbSelectArea("SF2")
			SF2->(dbGoTo((_cAliasP01 )->RECID))
			RecLock("SF2",.F.)
			SF2->F2_XDFRETE := "X"
			//SF2->F2_XDFID   := _cFUUID
			SF2->(MsUnlock())

		EndIf

		(_cAliasP01 )->(dbSkip())
	End

	(_cAliasP01)->(dbCloseArea())

	RpcClearEnv()
Return
