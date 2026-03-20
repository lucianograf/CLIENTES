#include "totvs.ch"
/*
Marcelo Alberto Lauschner
Função genérica responsável por gravar o log de uso dos Rdmakes do sistema
*/
User Function BFCFGM01(cInRdmake)

	Local _i      		:= 0
	Local _sPilha 		:= cUserName+chr (13) + chr (10) +DTOC(Date())+" " + Time() +chr (13) + chr (10) + "Pilha de chamadas:"
	Local cFileProc		:= ""
	Default	cInRdmake	:= FunName() + ProcName()
	
	cFileProc	:= Alltrim(cInRdmake)  +"_"+__cUserId+".txt"

	While Procname (_i) != ""
		_sPilha += chr (13) + chr (10) + procname (_i)
		_i++
	Enddo

	MemoWrite("\log_rdmakes\" + cFileProc,_sPilha)
    

Return
