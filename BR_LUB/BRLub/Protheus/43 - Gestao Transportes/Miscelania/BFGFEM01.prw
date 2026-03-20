/*/{Protheus.doc} BFGFEM01
Tracking pedidos faturados
@type function
@version 1
@author Iago Luiz Raimondi
@since 20/07/2022
@return 
/*/
User Function BFGFEM01()

	Local 	aParam    	:= {}
	Private cLink   	:= ""

	If sfPerg(@aParam) // [1] NF, [2] SERIE

		dbSelectArea("SF2")
		dbSetOrder(1)
		If SF2->(MsSeek(xFilial("SF2")+aParam[1]+aParam[2]))

			Do Case
			Case ( SF2->F2_TRANSP == "003249" .Or. SF2->F2_TRANSP == "003211") //adicionar nova SC
				cLink  := "https://ssw.inf.br/2/rastreamento_danfe?danfe="+AllTrim(SF2->F2_CHVNFE)
				ShellExecute("Open", cLink, "", "", 1)
			OtherWise
				MsgInfo("A transportadora desta NFe ainda não possui tracking configurado!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			EndCase

		Else
			MsgAlert("Nota fiscal não encontrada!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		EndIf
	Endif

Return

/*/{Protheus.doc} Perg
ParamBox 
@type function
@version 1
@author Iago Luiz Raimondi
@since 20/07/2022
@return variant, aRet[1] NF, aRet[2] Serie
/*/
Static Function sfPerg(aRet)

	Local 	aPergPar	:=	{}
	Local 	cNota	    := Space(TamSX3("F2_DOC")[1])
	Local 	cSerie	    := Space(TamSX3("F2_SERIE")[1])
	Local 	lRet 		:= .F. 

	aadd(aPergPar,{1, "Número NFe", cNota ,"","","","",50,.T.})
	aadd(aPergPar,{1, "Série  NFe", cSerie,"","","","",30,.T.})

	lRet	:= ParamBox(@aPergPar,"Parametros ",@aRet, , ,.T.,)

Return lRet

