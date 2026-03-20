#Include 'Protheus.ch'

/*/{Protheus.doc} MLFATM03
Rotina para inclusão, alteração ou exclusão de plano de venda automaticamente por planilha em excel. 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 01/02/2021
@return 
/*/
User Function MLFATM03()

	Local aAreaSB1		:= SB1->(GetArea())
	Local aRet	   		:= {}
	Local aDados 		:= {}
	Local aPergs  		:= {}
	Local cPath			:= PadR("",150)
	
	aAdd(aPergs ,{6,OEMToANSI("Importação Planilha"),cPath,"",,"", 90 ,.T.,"Excel(*.xls) |*.xls |","",GETF_LOCALHARD})

	If ParamBox(aPergs ,OEMToANSI("Previsão de Vendas"),aRet)
		cArq := SubStr(aRet[1],RAt("\",aRet[1]) + 1,(RAt(".",aRet[1]) - RAt("\",aRet[1]) - 1))
		cOrigem := Substr(aRet[1],1,RAt("\",aRet[1]))
	Else
		MsgAlert("Processo cancelado.","MLFATM03")
		ConOut("Processo cancelado - MLFATM03.")
		Return
	EndIf

// 	Coleta os dados da planilha.
	aDados := U_XLS2CSV(cArq,cOrigem,1,.F.)

// Valida se o array está vazio.   
	If !Empty(aDados)
		ConOut("Inicio de importacao do previsao de vendas pela rotina MLFATM03.")
		Processa({ || ImportaDados(aDados) }, OEMToANSI("Importando Previsão de Vendas..."))
	EndIf

	RestArea(aAreaSB1)

Return


Static Function ImportaDados(aDados)

	Local aErros			:= {}
	Local aExecInc          := {}
	Local aExecAlt          := {}
	Local aExecExc          := {}
	Local cProduto			:= ""
	Local cAcao				:= ""
	Local dData				:= CToD("")
	Local nQtde				:= 0
	Local nCount			:= 0
	Local oDlg				:= Nil
	Local oLbx				:= Nil
	Private lMsErroAuto		:= .F.

	DBSelectArea("SB1")
	SB1->(DBSetOrder(1))

	DBSelectArea("SC4")
	SC4->(DBSetOrder(1))

	ProcRegua(Len(aDados))

	For nCount := 1 To Len(aDados)

		//Carrega variáveis.
		cProduto    := AllTrim(aDados[nCount][1])
		cLocal      := PadL(aDados[nCount][2],2,"0")
		cDoc        := AllTrim(aDados[nCount][3])
		nQtde       := Val(StrTran(aDados[nCount][4],',','.'))
		nValor      := Val(StrTran(aDados[nCount][5],',','.'))
		dData       := CToD(aDados[nCount][6])
		cObs        := DecodeUTF8(AllTrim(NoAcento(aDados[nCount][7])))

		IncProc("Importando item: " + cProduto)

		//Valida se o produto existe na SB1.
		If SB1->(!DBSeek(xFilial("SB1") + cProduto))
			AAdd(aErros, {cProduto, OEMToANSI("Produto não cadastrado.")})
			Loop
		EndIf

		// Verifica se já existe cadastro da Previsão
		If SC4->(DBSeek(xFilial("SC4") + PadR(cProduto,TamSX3("C4_PRODUTO")[1]) + DToS(dData)))
			// Considera que se estiver zerada a quantidade na planilha deve excluir a previsão
			If nQtde <= 0 .Or. nValor <= 0
				AAdd(aErros, {cProduto, OEMToANSI("Produto será excluído!")})
				aAdd(aExecExc,{;
					{"C4_PRODUTO"		,cProduto		,Nil},;
					{"C4_DATA"		    ,dData			,Nil}})
			Else
				AAdd(aErros, {cProduto, OEMToANSI("Produto será Alterado!")})
				aAdd(aExecAlt	,{;
					{"C4_PRODUTO"		    ,cProduto		,Nil},;
					{"C4_LOCAL"	            ,cLocal		    ,Nil},;
					{"C4_DOC" 		        ,cDoc			,Nil},;
					{"C4_QUANT"	            ,nQtde			,Nil},;
					{"C4_VALOR"	            ,nValor		    ,Nil},;
					{"C4_DATA"		        ,dData			,Nil},;
					{"C4_OBS" 		        ,cObs			,Nil}})
			EndIf
		Else
			If nValor <= 0
				AAdd(aErros, {cProduto, OEMToANSI("Valor Zerado.")})
				Loop
			EndIf
			If nQtde <= 0
				AAdd(aErros, {cProduto, OEMToANSI("Quantidade Zerada.")})
				Loop
			EndIf

			//Carrega array para executar o MsExecAuto.
			aAdd(aExecInc	,{;
				{"C4_PRODUTO"		,cProduto		,Nil},;
				{"C4_LOCAL"	        ,cLocal		    ,Nil},;
				{"C4_DOC" 		    ,cDoc			,Nil},;
				{"C4_QUANT"	        ,nQtde			,Nil},;
				{"C4_VALOR"	        ,nValor		    ,Nil},;
				{"C4_DATA"		    ,dData			,Nil},;
				{"C4_OBS" 		    ,cObs			,Nil}})
		Endif
	Next nCount

	If Len(aErros) > 0
		DEFINE MSDIALOG oDlg TITLE "Validações Encontradas" FROM 0,0 TO 240,500 PIXEL
		@ 10,10 LISTBOX oLbx VAR cVar FIELDS HEADER "Produto", "Erro";
			SIZE 230,095 OF oDlg PIXEL ON dblClick(oLbx:Refresh()) SCROLL
		oLbx:SetArray(aErros)
		oLbx:bLine := {|| { aErros[oLbx:nAt,1],aErros[oLbx:nAt,2]}}
		DEFINE SBUTTON FROM 107,213 TYPE 1 OF oDlg ACTION oDlg:End() ENABLE
		ACTIVATE MSDIALOG oDlg CENTER
	Endif

	If Len(aExecInc) > 0

		lMsErroAuto     := .F.

		Begin Transaction
			cAcao := "Incluindo"
			ProcRegua(Len(aExecInc))
			For nCount := 1 To Len(aExecInc)
				IncProc(cAcao + " item: " + aExecInc[nCount][1][2])
				MSExecAuto({|x,y| MATA700(x,y)}, aExecInc[nCount], 3)
				If lMsErroAuto
					MostraErro()
					Exit
				EndIf
			Next nCount
		End Transaction

		If !lMsErroAuto
			MsgInfo(OEMToANSI("Finalizado com sucesso!"),"MLFATM03")
			ConOut("Finalizado - MLFATM03.")
		EndIf
	EndIf
	If Len(aExecAlt) > 0

		lMsErroAuto     := .F.

		Begin Transaction
			cAcao := "Alterando"
			ProcRegua(Len(aExecAlt))
			For nCount := 1 To Len(aExecAlt)
				IncProc(cAcao + " item: " + aExecAlt[nCount][1][2])
				MSExecAuto({|x,y| MATA700(x,y)}, aExecAlt[nCount], 4)
				If lMsErroAuto
					MostraErro()
					Exit
				EndIf
			Next nCount
		End Transaction

		If !lMsErroAuto
			MsgInfo(OEMToANSI("Finalizado com sucesso!"),"MLFATM03")
			ConOut("Finalizado - MLFATM03.")
		EndIf
	EndIf

	If Len(aExecExc) > 0

		lMsErroAuto     := .F.

		Begin Transaction
			cAcao := "Excluindo"
			ProcRegua(Len(aExecExc))
			For nCount := 1 To Len(aExecExc)
				IncProc(cAcao + " item: " + aExecExc[nCount][1][2])
				MSExecAuto({|x,y| MATA700(x,y)}, aExecExc[nCount], 5)
				If lMsErroAuto
					MostraErro()
					Exit
				EndIf
			Next nCount
		End Transaction

		If !lMsErroAuto
			MsgInfo(OEMToANSI("Finalizado com sucesso!"),"MLFATM03")
			ConOut("Finalizado - MLFATM03.")
		EndIf
	EndIf

Return
