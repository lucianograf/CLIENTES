#include 'protheus.ch'
#include 'parmtype.ch'

/*/==========================================================================
{Protheus.doc} VBJOB000
//TODO Job Master que iniciará os demais processos - WS SERVER.
@author thiago.reis
@since 07/06/2019
@version 1.0
@type function
==========================================================================/*/
User Function DTJOB000(cParm1, cParm2)

	Local _aJobs 	:= {}
	Local _aRotina	:= {}
	Local _nJob     := 0

	RpcSetEnv( "01" , "0101" , "" , "" , 'FAT' )

	_aRotina := ExecQry()

	if !Empty(_aRotina)

		if aScan(_aRotina, "WSDTNF") > 0
			aAdd(_aJobs,'u_DTJOB002')		//envia dados ao datafrete
		endif

	endif

	aAdd(_aJobs  ,'u_DTJOB001')			//Extrai XML NFe e alimenta tabela P01
	aAdd(_aRotina,"")



	For _nJob := 1 To Len(_aJobs)
		StartJob('u_DTJOB001', GetEnvServer(), .F.,_aRotina[_nJob])
	Next


	RpcClearEnv()

Return

/*/==========================================================================
	{Protheus.doc} ExecQry
//TODO Query para realizar um pré-filtro para evitar a chamada de jobs em multiplas threads
	@version 1.0
	@type function
==========================================================================/*/
Static Function ExecQry()

	Local _cAliasP01 	:= GetNextAlias()
	Local _aRotina		:= {}

	BeginSql Alias _cAliasP01
		SELECT DISTINCT P01_API
		FROM %Table:P01%
		WHERE %NotDel%
		AND P01_STATUS = '0'
		AND P01_ORIGEM = '2'
	EndSql

	While !(_cAliasP01)->(Eof())
		aAdd(_aRotina, AllTrim((_cAliasP01)->P01_API))
		(_cAliasP01)->(dbSkip())
	End

	(_cAliasP01)->(dbCloseArea())

Return (_aRotina)
