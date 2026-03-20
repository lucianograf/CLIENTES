#include 'rwmake.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MLCFGM03
// Função para acionar qualquer Função ou expressão Advpl
@author Marcelo Alberto Lauschner
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function MLCFGM03()

	Private cFunc := Space(50)
	Private cProg := Space(10)
	Private cForm := space(250)
	Private aTabelas := {"SC5","SA1","SB1","SC6","DA1","DA0","SX1","SX2","SX3"}


	If (Select("SM0") == 0)
		RPCSetEnv("01","0101","Marcelo","943716" ,"COM"/*cEnvMod*/,/*cFunName*/,aTabelas)
	Endif


	@ 001,001 TO 140,280 DIALOG oDlg1 TITLE OemToAnsi("Digite o nome da Função.")
	@ 005,005 TO 049,140
	@ 010,006 Say "Função "
	@ 023,006 Say "Programa"
	@ 036,006 Say "Expressão Advpl"
	@ 010,035 Get cfunc picture "@!" Size 50,10
	@ 022,035 Get cProg Picture "@!" size 50,10
	@ 035,035 Get cForm Picture "@!" size 100,10
	@ 052,010 BUTTON "&Continua" SIZE 40,10 ACTION (ExecFun(cfunc,cProg))
	@ 052,060 BUTTON "&Abandona" SIZE 40,10 ACTION Close(oDlg1)

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return


/*/{Protheus.doc} ExecFun
// Executa Função 
@author marce
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function  ExecFun()

	//HTTPGet ( < cUrl>, [ cGETParms], [ nTimeOut], [ aHeadStr], [ @cHeaderRet] ) --> cResponse
	//http://www.bigforta.com.br/api/email/valida.php?e=
	//cEmail := HttpGet('www.bigforta.com.br/api/email/valida.php?e='+Alltrim(cEmail))

	If !Empty(cFunc)
		If !Empty(cProg)
			MsgInfo("Somente uma função pode ser executada por vez","Erro ")
			Return
		Endif
		//	u_XMLDCONDOR(cEmpAnt,cFilAnt,"000130")

		&("U_"+cfunc+IIf(At("(",cFunc)==0,"()",""))
	Endif

	If !Empty(cProg)
		&(cProg+"()")
	Endif

	If !Empty(cForm)
		fExecuta()
	Endif

Return


/*/{Protheus.doc} fExecuta
// Executa Expressão Advpl
@author marce
@since 21/08/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function fExecuta()

	Local aArea    := GetArea()
	Local cFormula := Alltrim(cForm)
	Local cError   := ""
	Local bError   := ErrorBlock({ |oError| cError := oError:Description})

	//Se tiver conteúdo digitado
	If ! Empty(cFormula)
		//Inicio a utilização da tentativa
		Begin Sequence
			&(cFormula)
		End Sequence

		//Restaurando bloco de erro do sistema
		ErrorBlock(bError)

		//Se houve erro, será mostrado ao usuário
		If ! Empty(cError)
			MsgStop("Houve um erro na fórmula digitada: "+CRLF+CRLF+cError, "Atenção")
		EndIf
	EndIf

	RestArea(aArea)
Return
