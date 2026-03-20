#include 'protheus.ch'
#include 'parmtype.ch'

User Function STGenCli()

	cCgcCli	:= PARAMIXB[1]
	cTpCli	:= PARAMIXB[2]

	cCodCli	:= Substr(cCgcCli,1,8)
	cLojCli	:= "9999"

Return { cCodCli, cLojCli }
