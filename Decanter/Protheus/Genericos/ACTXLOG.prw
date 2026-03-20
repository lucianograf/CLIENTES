#include 'protheus.ch'
#include 'parmtype.ch'
#include "fileio.ch"
/*/{Protheus.doc} ACTXLOG
Classe responsavel por criar um lote
@author administrador
@since 21/05/2018
@version undefined
@example



@see (links_or_references)
/*/
CLASS ACTXLOG

METHOD New() CONSTRUCTOR
METHOD Start()
METHOD Inf() //adiciona uma informacao
METHOD War() //adicionar um warning
METHOD Err() //adiciona um erro
METHOD Fin() //finaliza classe e tempos
METHOD OpenLog() //finaliza classe e tempos
METHOD DefMsg()


DATA cGroupLog 	As String //Agrupador do loga
DATA cTimeIni 	As String
DATA cTimeEnd	As String
DATA lConsoleLog AS Logical
DATA lSavTrLog	AS Logical
DATA cMsgFullF	AS String
DATA cFileLog 	AS String
DATA cFileId 	AS String


ENDCLASS

METHOD New() CLASS ACTXLOG
	::cGroupLog	:=	""
	::cTimeIni	:= Time()
	::cTimeEnd	:=	""
	//Verifica se ira apresentar as mensagens no console de transacoes de funcoes
	::lConsoleLog	:=	If(GetPvProfString("general","TraceLogZ","",GetADV97())=="1",.T.,.F.)
	::lSavTrLog		:=	If(GetPvProfString("general","TraceSaveLogZ","",GetADV97())=="1",.T.,.F.)
	::cFileLog	:=	""
	::cFileId	:=	FWUUIDV4()
Return Self

METHOD Start(cGroupLog,cMsgOne,cMsgTwo) CLASS ACTXLOG
	Default cGroupLog	:=	""
	Default cMsgOne	:=	""
	Default cMsgTwo	:=	""


	If !Empty(cGroupLog)
		::cGroupLog := cGroupLog
	EndIf

	::DefMsg("Sta",cMsgOne,cMsgTwo)

Return Self

METHOD Inf(cMsgOne,cMsgTwo) CLASS ACTXLOG
	Default cMsgOne	:=	""
	Default cMsgTwo	:=	""
	::DefMsg("Inf",cMsgOne,cMsgTwo)
Return Self

METHOD War(cMsgOne,cMsgTwo) CLASS ACTXLOG
	Default cMsgOne	:=	""
	Default cMsgTwo	:=	""
	::DefMsg("War",cMsgOne,cMsgTwo)
Return Self


METHOD Err(cMsgOne,cMsgTwo) CLASS ACTXLOG
	Default cMsgOne	:=	""
	Default cMsgTwo	:=	""
	::DefMsg("Err",cMsgOne,cMsgTwo)
Return Self


METHOD Fin(cMsgOne,cMsgTwo) CLASS ACTXLOG
	Default cMsgOne	:=	""
	Default cMsgTwo	:=	""
	::DefMsg("End",cMsgOne+" Ini:"+::cTimeIni+"|Fim:"+Time()+"|Elaptime:"+elaptime(::cTimeIni,Time()),cMsgTwo)


	//Abre o arquivo caso estiver com tela
	If FIle(::cFileLog) .AND. !IsBlind()
		If CpyS2T( ::cFileLog, GetTempPath(.T.), .T. )
			cDrive	:=	""
			cDir	:=	""
			cNome	:=	""
			cExt	:= ""
			SplitPath(::cFileLog, @cDrive, @cDir, @cNome, @cExt )
			If ShellExecute("Open",cNome+cExt,"", GetTempPath(.T.),3) == 0
				MsgStop("Não foi possível abrir o arquivo de LOG, verifique no caminho ->"+GetTempPath(.T.)+'\'+::cFileLog,"Atenção - "+Procname()+" - "+cvaltochar(procLine()))
			EndIf
		Else
			MsgStop("Não foi possível copiar o arquivo para máquina local","Atenção - "+Procname()+" - "+cvaltochar(procLine()))
		EndIf
	EndIf

	//FreeObj(Self) //finaliza objetvo
Return nil

METHOD DefMsg(cTipMSG,cMsgOne,cMsgTwo) CLASS ACTXLOG
	Local cMsg	:= ""
	Default cMsgOne	:=	""
	Default cMsgTwo	:=	""
	Default cTipMSG	:=	""

	//msg start ended info erro
	cMsg	+=	"["+cTipMSG+"]"//aMsg[&(_cTipM)]
	//thread
	cMsg	+=	"[Thread "+cvaltochar(ThreadID())+"]"
	//Monta a Data na Linha
	cMsg	+=	"["+DTOC(DATE())+" "+Time()+"]"
	//Funcao que esta sendo rodada ou agrupador
	cMsg	+=	"["+::cGroupLog+"] "
	//Mensagem 1
	cMsg	+=	cMsgOne+If(Empty(cMsgTwo),"","-")
	//Mensagem 2
	cMsg	+=	cMsgTwo

	//If ::lConsoleLog
	//	conout(cMsg)
	//EndIF

	//Save em um log separado
	If ::lSavTrLog
		cPath	:= "\log"
		cPath2	:= "\xmpad"
		cFile	:= ::cGroupLog+"_"+::cFileId+".log"
		cFilePath	:=	cPath+cPath2+"\"+cFile
		If !ExistDir(cPath)
			MakeDir(cPath)
		EndIf
		If !ExistDir(cPath+cPath2)
			MakeDir(cPath+cPath2)
		EndIf
		nHandle := FOPEN(cFilePath, FO_WRITE)
		If nHandle <> -1//escreve no arquivo
			fSeek(nHandle,0,FS_END)
			FWrite(nHandle,cMsg+chr(13)+chr(10))
		Else//criar o arquivo caso nao achar
			nHandle := FCREATE(cFilePath)
			if nHandle <> -1
				FWrite(nHandle,cMsg+chr(13)+chr(10))
			EndIf
		EndIf
		::cFileLog	:=	cFilePath

		FClose(nHandle)

	EndIf

	::cMsgFullF	:=	cMsg
Return self

