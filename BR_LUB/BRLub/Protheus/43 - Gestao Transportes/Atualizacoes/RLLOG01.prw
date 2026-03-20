#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

user function RLLOG01()



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cCadastro := "Cadastro de Operações"


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta um aRotina proprio                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Incluir","AxInclui",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5} }

	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

	Private cString := "Z20"

	dbSelectArea("Z20")
	dbSetOrder(1)


	dbSelectArea(cString)
	mBrowse( 6,1,22,75,cString)

Return



user function RLLOG01A()



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cCadastro := "Cadastro de Serviços"


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta um aRotina proprio                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Incluir","AxInclui",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5} }

	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

	Private cString := "Z21"

	dbSelectArea("Z21")
	dbSetOrder(1)


	dbSelectArea(cString)
	mBrowse( 6,1,22,75,cString)

Return


user function RLLOG01B()



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cCadastro := "Cadastro de Operações x Serviços"


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta um aRotina proprio                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Incluir","AxInclui",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5} }

	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

	Private cString := "Z22"

	dbSelectArea("Z22")
	dbSetOrder(1)


	dbSelectArea(cString)
	mBrowse( 6,1,22,75,cString)

Return



user function RLLOG01C()



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cCadastro := "Cadastro de Clientes x  Operações x Serviços"


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta um aRotina proprio                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Incluir","AxInclui",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5} }

	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

	Private cString := "Z23"

	dbSelectArea("Z23")
	dbSetOrder(1)


	dbSelectArea(cString)
	mBrowse( 6,1,22,75,cString)

Return


//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 31/07/2018
// Nome função: RLLOG01D
// Parametros :
// Objetivo   : Registro de estadias
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------


user function RLLOG01D()



//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cCadastro := "Registro de Estadias"


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta um aRotina proprio                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Registrar Saída","U_RLLOG01F()",0,2} ,;
		{"Incluir","AxInclui",0,3} }


	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

	Private cString := "Z25"

	dbSelectArea("Z25")
	dbSetOrder(1)


	dbSelectArea(cString)
	mBrowse( 6,1,22,75,cString)

Return

//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 31/07/2018
// Nome função: RLLOG01F
// Parametros :
// Objetivo   : Registro do fim da estadia do Container
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------

user function RLLOG01F()



	Private  cPerg	:= "RLLOG01"
	// ValidPerg()

	If !Pergunte(cPerg,.T.)
		REturn
	Endif

	Processa({|| sfRegFim() },"Efetuando registro do fim....")

Return


Static function sfRegFim()

	If (!Empty(Z25->Z25_DTSAID))
		MsgAlert("Já foi registrada saída desta estadia!")
		Return
	EndIf

	reclock("Z25", .F.)
	Z25->Z25_DTSAID := MV_PAR01
	Z25->Z25_HRSAID := MV_PAR02
	Z25->Z25_NRESTA := MV_PAR01 - Z25->Z25_DATA
	Z25->Z25_TOTAL  := Z25->Z25_NRESTA * Z25->Z25_VALOR
	Z25->Z25_TOTPAG  := Z25->Z25_NRESTA * Z25->Z25_VALPAG
	msunlock("Z25")


	dbSelectArea("Z23")
	dbSetOrder(1)

	if ! dbseek(Z25->Z25_FILIAL +  Z25->Z25_CLIENT +  Z25->Z25_LOJA + Z25->Z25_OPER +  Z25->Z25_SERVIC +  "0" + DTOS(Z25->Z25_DATA) +  Z25->Z25_HORA  +  Z25->Z25_USUARI +   Z25->Z25_NRCONT )
		reclock("Z23", .T. )
		Z23->Z23_FILIAL		:= Z25->Z25_FILIAL
		Z23->Z23_OPER  		:= Z25->Z25_OPER
		Z23->Z23_SERVIC		:= Z25->Z25_SERVIC
		Z23->Z23_CLIENT		:= Z25->Z25_CLIENT
		Z23->Z23_LOJA 		:= Z25->Z25_LOJA
		Z23->Z23_NOMCLI		:= Z25->Z25_NOMCLI
		Z23->Z23_VALOR 		:= Z25->Z25_TOTAL
		Z23->Z23_STATUS		:= '0'
		Z23->Z23_DATA 		:= Z25->Z25_DATA
		Z23->Z23_HORA 		:= Z25->Z25_HORA
		Z23->Z23_USUARI		:= Z25->Z25_USUARI
		Z23->Z23_NRCONT		:= Z25->Z25_NRCONT
		Z23->Z23_FORNEC		:= Z25->Z25_FORNEC
		Z23->Z23_LJFORN		:= Z25->Z25_LJFORN
		Z23->Z23_VALPAG		:= Z25->Z25_TOTPAG
		msunlock("Z23")
	else
		reclock("Z23", .F. )
		Z23->Z23_FILIAL		:= Z25->Z25_FILIAL
		Z23->Z23_OPER  		:= Z25->Z25_OPER
		Z23->Z23_SERVIC		:= Z25->Z25_SERVIC
		Z23->Z23_CLIENT		:= Z25->Z25_CLIENT
		Z23->Z23_LOJA 		:= Z25->Z25_LOJA
		Z23->Z23_NOMCLI		:= Z25->Z25_NOMCLI
		Z23->Z23_VALOR 		:= Z25->Z25_TOTAL
		Z23->Z23_STATUS		:= '0'
		Z23->Z23_DATA 		:= Z25->Z25_DATA
		Z23->Z23_HORA 		:= Z25->Z25_HORA
		Z23->Z23_USUARI		:= Z25->Z25_USUARI
		Z23->Z23_NRCONT		:= Z25->Z25_NRCONT
		Z23->Z23_FORNEC		:= Z25->Z25_FORNEC
		Z23->Z23_LJFORN		:= Z25->Z25_LJFORN
		Z23->Z23_VALPAG		:= Z25->Z25_TOTPAG
		msunlock("Z23")
	endif

return



//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 31/07/2018
// Nome função: ValidPerg
// Parametros :
// Objetivo   : Criar as perguntas para a rotina
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------
// Static Function ValidPerg()

// 	Local aRegs := {}
// 	Local i,j

// 	dbSelectArea("SX1")
// 	dbSetOrder(1)
// 	cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))
// 	//     "X1_GRUPO" ,"X1_ORDEM","X1_PERGUNT"    			,"X1_PERSPA"		,"X1_PERENG"		,"X1_VARIAVL","X1_TIPO"	,"X1_TAMANHO"	,"X1_DECIMAL"	,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
// 	Aadd(aRegs,{cPerg ,"01"		,"Data"				,"Data	"	 	,"Data  "		,"mv_ch1"	,"D"		,8				,0				,0				,"G"		,""			,"mv_par01"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPerg ,"02"		,"Hora"				,"Hora	"	 	,"Hora  "	    ,"mv_ch2"	,"C"		,5				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})

// 	For i:=1 to Len(aRegs)
// 		If !dbSeek(cPerg+aRegs[i,2])
// 			RecLock("SX1",.T.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif
// 			Next
// 			MsUnlock("SX1")
// 		Else
// 			RecLock("SX1",.F.)
// 			IF  aRegs[i,2] == "01"
// 				SX1->X1_CNT01 := DTOS(DDATABASE)
// 			ELSEIF aRegs[i,2] == "02"
// 				SX1->X1_CNT01 := SUBSTR(TIME(), 1,5)
// 			ENDIF
// 			MsUnlock("SX1")
// 		Endif
// 	Next

// Return

// CONTROLE DE FATURAS 01/08/18
user function RLLOG01G()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de Variaveis                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private cCadastro := "Faturas operações"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Monta um aRotina proprio                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","U_RLLOG01I()",0,4} ,;
		{"Exc Pedido","U_RLLOG01J()",0,2} ,;
		{"Gerar Ped. Venda","U_RLLOG01H()",0,2} }



	Private cDelFunc := ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock

	Private cString := "Z26"

	dbSelectArea("Z26")
	dbSetOrder(1)


	dbSelectArea(cString)
	mBrowse( 6,1,22,75,cString)

Return

//geração pedido de venda 
User Function RLLOG01H
	Private  cPerg	:= "RLLOG0H"
	// CriaPerg()
	If !Pergunte(cPerg,.T.)
		REturn
	Endif
	nOpc :=  3
	Processa({|| sfGeraPed(nOpc) },"Efetuando inclusão do pedido...")

return


//exclusão pedido de venda 
User Function RLLOG01J

	nOpc :=  5
	Processa({|| sfGeraPed(nOpc) },"Efetuando exclusão do pedido...")

return

//Chama rotina automática
Static function sfGeraPed(nOpc)

	Local	aArea	:= GetArea()
	dbSelectArea("SA1")
	SA1->(dbGotop())
	SA1->(dbSetOrder(1))

	If SA1->(DbSeek(xFilial("SA1")+Z26->Z26_CLIENT+Z26->Z26_LOJA))



		aCabec   := {}
		aItens   := {}
		aLinha   := {}
		nQtdVen  := 1
		nPrcVen  := ( Z26->Z26_VALOR +  Z26->Z26_VLRACR ) -  Z26->Z26_DESC
		nValor   := nPrcVen * nQtdVen



		If nOpc == 5


			dbSelectArea("SC5")
			dbSetOrder(1)
			dbseek(xFilial("SC5") + Z26->Z26_PEDIDO)
			sNumPed := SC5->C5_NUM
			MV_PAR03 := SC5->C5_CONDPAG

			dbSelectArea("SC6")
			dbSetOrder(1)
			dbseek(xFilial("SC6") + Z26->Z26_PEDIDO)


			MV_PAR01 := SC6->C6_PRODUTO
			MV_PAR02 := SC6->C6_TES

		else
			sNumPed := GetSX8Num("SC5")
		endif


		dbSelectArea("SF4")
		dbSetOrder(1)
		dbSeek(xFilial("SF4") + MV_PAR02)

		dbSelectArea("SE4")
		dbSetOrder(1)
		dbSeek(xFilial("SE4") + MV_PAR03)


		aadd(aCabec ,{"C5_NUM"       ,sNumPed              ,Nil})
		aadd(aCabec ,{"C5_TIPO"      ,"N"               ,Nil})
		aadd(aCabec ,{"C5_CLIENTE"   ,SA1->A1_COD       ,Nil})
		aadd(aCabec ,{"C5_LOJACLI"   ,SA1->A1_LOJA      ,Nil})
		aadd(aCabec ,{"C5_DESCCLI"   ,SA1->A1_NOME      ,Nil})
		aadd(aCabec ,{"C5_TIPOCLI"   ,SA1->A1_TIPO      ,Nil})
		aadd(aCabec ,{"C5_CONDPAG"   ,SE4->E4_CODIGO ,Nil})
		aadd(aCabec ,{"C5_DESCPAG"   ,Posicione("SE4",1,xFilial("SE4")+SE4->E4_CODIGO,"E4_DESCRI"),Nil})

		dbSelectArea("SB1")
		SB1->(dbSetOrder(1))
		SB1->(DbSeek(xFilial("SB1")+MV_PAR01))

		dbSelectArea("SB2")
		SB2->(dbSetOrder(1))
		If !SB2->(DBSEEK(xFilial("SB2")+SB1->B1_COD+SB1->B1_LOCPAD))
			CriaSB2(SB1->B1_COD,SB1->B1_LOCPAD)
		Endif

		aLinha  := {}
		aadd(aLinha,{"C6_NUM"       ,sNumPed            ,Nil})
		aadd(aLinha,{"C6_ITEM"      ,StrZero(1,2)        ,Nil})
		aadd(aLinha,{"C6_PRODUTO"   ,SB1->B1_COD        ,Nil})
		aadd(aLinha,{"C6_DESCRI"    ,SB1->B1_DESC       ,Nil})
		aadd(aLinha,{"C6_UM"        ,SB1->B1_UM         ,Nil})
		aadd(aLinha,{"C6_LOCAL"     ,SB1->B1_LOCPAD     ,Nil})
		aadd(aLinha,{"C6_QTDVEN"    ,nQtdVen            ,Nil})
		aadd(aLinha,{"C6_PRCVEN"    ,nPrcVen            ,Nil})
		aadd(aLinha,{"C6_PRUNIT"    ,nPrcVen            ,Nil})
		aadd(aLinha,{"C6_VALOR"     ,Round(nValor,2)    ,Nil})
		aadd(aLinha,{"C6_TES"       ,SF4->F4_CODIGO     ,Nil})
		aadd(aLinha,{"C6_DESCTES"   ,SF4->F4_TEXTO      ,Nil})
		aadd(aLinha,{"C6_CF"        ,IIF(SA1->A1_EST==GetMv("MV_ESTADO"),'5','6')+Right(AllTrim(SF4->F4_CF),3),Nil})
		aadd(aLinha,{"C6_QTDLIB"    ,nQtdVen            ,Nil})


		aadd(aItens,aLinha)

		lMSHelpAuto := .T.
		lMsErroAuto := .F.

		MSExecAuto({ |X, Y, Z| MATA410(X, Y, Z) }, aCabec, aItens, nOpc)

		If lMsErroAuto
			RollBackSX8()
			MostraErro()
		Else
			if nOpc == 3
				Reclock("Z26", .F.)
				Z26->Z26_PEDIDO :=  sNumPed
				MsUnLock("Z26")
				ConfirmSX8()
				MsgInfo("Pedido Gerado--> " +  sNumPed , "RLOG01")
			elseif  nOpc == 5
				Reclock("Z26", .F.)
				Z26->Z26_PEDIDO :=  " "
				MsUnLock("Z26")
				MsgInfo("Pedido Excluído" , "RLOG01")
			endif

		EndIf
	ENDIF


	RestArea(aArea)

return

//exclusão fatura
User Function RLLOG01I

	IF ALLTRIM(Z26->Z26_PEDIDO) ==  ""

		cSQL := "UPDATE "+RetSqlName("Z23") +" SET Z23_NUMFAT = ' ', Z23_STATUS = '0' WHERE Z23_FILIAL = '"+Z26->Z26_FILIAL+"' AND Z23_NUMFAT = '"+Z26->Z26_NUMFAT+"' AND R_E_C_D_E_L_ = 0 "
		TcSqlExec(cSQL)

		RecLock("Z26", .F.)
		DbDelete()
		MsUnLock("Z26")
	ELSE

		ALERT("Pedido Gerado, necessário excluir o pedido para poder excluir a fatura!")

	ENDIF

return

//CRIA PERGUNTAS PARA GERAÇÃO DO PEDIDO DE VENDA TES, PRODUTO, CONDIÇÃO DE PAGAMENTO
// Static Function CriaPerg()

// 	Local aRegs := {}
// 	Local i,j

// 	dbSelectArea("SX1")
// 	dbSetOrder(1)
// 	cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))
// 	//     "X1_GRUPO" ,"X1_ORDEM","X1_PERGUNT"    			,"X1_PERSPA"		,"X1_PERENG"		,"X1_VARIAVL","X1_TIPO"	,"X1_TAMANHO"	,"X1_DECIMAL"	,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
// 	Aadd(aRegs,{cPerg ,"01"		,"Produto"				,"Produto"	 	,"Produto"		,"mv_ch1"	,"C"		,tamsx3("B1_COD")[1]				,0				,0				,"G"		,""			,"mv_par01"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SB1" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPerg ,"02"		,"Tes"				    ,"Tes"	 	    ,"Tes"		    ,"mv_ch2"	,"C"		,tamsx3("F4_CODIGO")[1]				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SF4" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPerg ,"03"		,"Cond Pag"				,"Cond Pag"	 	,"Cond Pag"	    ,"mv_ch3"	,"C"		,tamsx3("E4_CODIGO")[1]				,0				,0				,"G"		,""			,"mv_par03"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SE4" 		,"S"		,""			,""})


// 	For i:=1 to Len(aRegs)
// 		If !dbSeek(cPerg+aRegs[i,2])
// 			RecLock("SX1",.T.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif
// 			Next
// 			MsUnlock("SX1")
// 		Else

// 		/*
// 			RecLock("SX1",.F.)
// 				IF  aRegs[i,2] == "01"
// 					SX1->X1_CNT01 := DTOS(DDATABASE)
// 				ELSEIF aRegs[i,2] == "02"
// 					SX1->X1_CNT01 := SUBSTR(TIME(), 1,5)
// 				ENDIF
// 			MsUnlock("SX1")
			
// 			*/
// 		Endif
// 	Next

// Return
