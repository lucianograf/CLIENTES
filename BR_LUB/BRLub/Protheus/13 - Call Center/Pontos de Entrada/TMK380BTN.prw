#Include 'Protheus.ch'

User Function TMK380BTN()
	
	Local	aBtnUser	:= {}
	
	//aUserBtn := U_TMK380BTN()
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Formato do Array de Retorno.³
	//³                            ³
	//³aUserBtn[nBtn,1]  RESOURCE  ³
	//³aUserBtn[nBtn,2]  ACTION    ³
	//³aUserBtn[nBtn,3]  TOOLTIP   ³
	//³aUserBtn[nBtn,4]  CTITLE    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Insere botoes de usuario na barra de ferramentas.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//If ValType(aUserBtn) == "A"
	//	If Len(aUserBtn) > 0
	//		For nBtn := 1 To Len(aUserBtn)
	//			AAdd(aButtons,{ aUserBtn[nBtn][1],	&( "aUserBtn["+STRZERO(nBtn,2)+"][2]"),aUserBtn[nBtn][3],aUserBtn[nBtn][4]})
	//			//AAdd(aButtons,&("{ aUserBtn["+Str(nBtn)+"][1],	{|| aUserBtn["+STRZERO(nBtn,2)+"][2]},aUserBtn["+Str(nBtn)+"][3],aUserBtn["+Str(nBtn)+"][4]}"))
	//		Next nBtn
	//	EndIf
	//EndIf
	
	Aadd(aBtnUser,{"AMARELO"		,{|| sfHist()	},"Histórico","Histórico"})
	
	
Return aBtnUser



Static Function sfHist()
	
	Local	aAreaOld	:= GetArea()
	Local	cCliEnt		:= Substr(oGetDados:aCols[oGetDados:nAt,aScan(oGetDados:aHeader,{|x| Alltrim(x[2]) == "U6_CODENT"})],1,TamSX3("A1_COD")[1])
	Local	cLojEnt		:= Substr(oGetDados:aCols[oGetDados:nAt,aScan(oGetDados:aHeader,{|x| Alltrim(x[2]) == "U6_CODENT"})],TamSX3("A1_COD")[1]+1,TamSX3("A1_LOJA")[1])
	
	U_BIG0381(cCliEnt,cLojEnt)
	
	RestArea(aAreaOld)
	
Return
