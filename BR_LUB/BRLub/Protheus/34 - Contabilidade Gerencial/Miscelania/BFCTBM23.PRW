#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"


User Function DIS073
	
Return U_BFCTBM23()


/*/{Protheus.doc} BFCTBM23
(Importacao dos valores da folha )
@author Leonardo J Koerich Jr
@since 06/04/2004
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function BFCTBM23()
	
	Local oTmpTable, a
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	cPathori := "C:\IMPORTA\FOLHA\ATUAL\"
	cTipo    := "*.txt"
	aFiles   := Directory(cPathOri + cTipo)
	
	Private cPerg       := "DIS073"
	
	// ValidPerg()
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	If !Pergunte(cPerg,.T.)
		Return
	Endif
	
	If Empty(mv_par01)
		MsgInfo("Informe a Data de Pagamento!","Paramêtro em branco")
		Return
	Endif
	
	dDtaven  := mv_par01
	cPref    := Substr(mv_par02,1,3)
	If Empty(mv_par03)
		cMes := DTOS(dDataBase) // StrZero(Month(dDataBase),2)+SubStr(DTOS(dDataBase),1,4)
	Else
		cMes := SubStr(mv_par03,1,9)
	Endif
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Abertura do arquivo texto                                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	For a := 1 To Len(aFiles)
		
		aCampos:={}
		AADD(aCampos,{ "LINHA" ,"C",100,0})
		
		// cNomArq := CriaTrab(aCampos)
		
		If (Select("QTEMP") <> 0)
			dbSelectArea("QTEMP")
			dbCloseArea("QTEMP")
		Endif
		// dbUseArea(.T.,,cNomArq,"QTEMP",nil,.F.)

		oTmpTable := FWTemporaryTable():New("QTEMP",aCampos)
		oTmpTable:Create()
		
		If !File(Alltrim("C:\IMPORTA\FOLHA\ATUAL\" + aFiles[a][1]))
			MsgInfo("Arquivo texto nao existente.Programa cancelado","Informa‡ao")
			Return
		Endif
		
		dbSelectArea("QTEMP")
		Append From (Alltrim("C:\IMPORTA\FOLHA\ATUAL\" + aFiles[a][1])) SDF
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicializa a regua de processamento                                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Importado Arquivo --> " + AllTrim(aFiles[a][1])/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Processa({|| RunCont() },"Processando...")
		FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Importacao de Dados Realizada com sucesso!!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Copia o arquivo de trabalho e depois apaga                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		
		If File("C:\IMPORTA\FOLHA\ATUAL\" + aFiles[a][1])
			__CopyFile("C:\IMPORTA\FOLHA\ATUAL\" + aFiles[a][1],"C:\IMPORTA\FOLHA\ANTIGOS\" + aFiles[a][1])
			Ferase("C:\IMPORTA\FOLHA\ATUAL\" + aFiles[a][1])
		Endif
		
	Next
	
	MsgInfo("Processo finalizado! Execute o relatório de Contas a Pagar para conferência dos títulos lançados.","Concluído")
	
Return

/*/{Protheus.doc} RunCont
(long_description)
@author MarceloLauschner
@since 08/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function RunCont()
	
	dbSelectArea("QTEMP")
	ProcRegua(RecCount()) // Numero de registros a processar
	dbGoTop()
	
	While !Eof()
		
		cQvs := ""
		cQvs += "SELECT A2_COD, A2_LOJA, A2_BANCO,A2_NUMFUNC "
		cQvs += "  FROM " + RetSqlName("SA2")
		cQvs += " WHERE D_E_L_E_T_ = ' ' "
		cQvs += "   AND A2_NUMFUNC = '"+SubStr(QTEMP->LINHA,3,6)+"' "
		cQvs += "   AND A2_FILIAL = '" + xFilial("SA2") + "' "
		
		If Select("QVS") <> 0
			dbSelectArea("QVS")
			dbCloseArea("QVS")
		Endif
		
		TCQUERY cQvs NEW ALIAS "QVS"
		
		If Empty(QVS->A2_COD)
			Alert("Funcionario nao cadastrado ==> " + SubStr(QTEMP->LINHA,3,6) + " " + SubStr(QTEMP->LINHA,9,29))
			dbSelectArea("QTEMP")
			dbSkip()
			Loop
		Endif
		
		IncProc("Funcionario: " + QVS->A2_NUMFUNC)
		
		
		If Empty(Val(SubStr(QTEMP->LINHA,43,8)))
			Alert("Valor informado invalido ==> " + Transform(Val(SubStr(QTEMP->LINHA,43,8)),"@E 999,999,999.99"))
			dbSelectArea("QTEMP")
			dbSkip()
			Loop
		Else
			_FINA050()
		Endif
		
		dbSelectArea("QTEMP")
		dbSkip()
	End
	
	QVS->(dbCloseArea())
	QTEMP->(dbCloseArea())
	
Return

/*/{Protheus.doc} _FINA050
(Gera título a pagar)
@author MarceloLauschner
@since 08/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function _FINA050()
	
	Local aTitulo := {}
	
	Private lMsHelpAuto := .F.
	Private lMsErroAuto := .F.
	
	cBanco := Space(3)
	
	cBanco := QVS->A2_BANCO
	
	Begin Transaction
		nValor := Val(SubStr(QTEMP->LINHA,43,5)+SubStr(QTEMP->LINHA,49,2))/100
		
		//+StrZero(Month(dDataBase),2)
		aTitulo := {{"E2_PREFIXO",cPref,Nil},;
			{"E2_NUM"     ,cMes                       ,Nil},;
			{"E2_PARCELA" ,"1"                        ,Nil},;
			{"E2_TIPO"	  ,"FOL"                      ,Nil},;
			{"E2_NATUREZ" ,UPPER(MV_PAR04)            ,Nil},;
			{"E2_FORNECE" ,QVS->A2_COD                ,Nil},;
			{"E2_LOJA"	  ,QVS->A2_LOJA               ,Nil},;
			{"E2_EMISSAO" ,dDataBase                  ,Nil},;
			{"E2_VENCTO"  ,dDtaven                    ,Nil},;
			{"E2_PORTADO" ,cBanco                     ,Nil},;
			{"E2_VALOR"   ,nValor					  ,Nil}}
		
		MSExecAuto({|x,y| FINA050(x,y)},aTitulo,3)
		
	End Transaction
	
	If lMsErroAuto
		MostraErro()
		DisarmTransaction()
	Endif
	
	
Return 


/*/{Protheus.doc} ValidPerg
(Validação das perguntas)
@author MarceloLauschner
@since 08/10/2015
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
// Static Function ValidPerg()
	
// 	Local _sAlias := Alias()
// 	Local aRegs := {}
// 	Local i,j
	
// 	dbSelectArea("SX1")
// 	dbSetOrder(1)
// 	cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))
	
// 	aAdd(aRegs,{cPerg,"01","Dt. Pagamento ","","","mv_ch1","D",8,0,0,"G","","mv_par01","","","","","","","","","","","","","",""})
// 	aAdd(aRegs,{cPerg,"02","Prefixo a Imp ","","","mv_ch2","C",3,0,0,"G","","mv_par02","","","","","","","","","","","","","",""})
// 	aAdd(aRegs,{cPerg,"03","Numero a  Imp ","","","mv_ch3","C",9,0,0,"G","","mv_par03","","","","","","","","","","","","","",""})
// 	//           "X1_GRUPO" 		,"X1_ORDEM"	,"X1_PERGUNT"   	,"X1_PERSPA"	,"X1_PERENG"	,"X1_VARIAVL"	,"X1_TIPO"	,"X1_TAMANHO"		,"X1_DECIMAL"		,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5"	,"X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
	
// 	aAdd(aRegs,{cPerg				,"04"		,"Natureza      "	,""				,""				,"mv_ch4"		,"C"		,10					,0					,0				,"G"		,""			,"mv_par04"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,"SED"})
	
	
// 	For i:=1 to Len(aRegs)
// 		If !dbSeek(cPerg+aRegs[i,2])
// 			RecLock("SX1",.T.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif
// 			Next
// 			MsUnlock()
// 		Endif
// 	Next
	
// 	dbSelectArea(_sAlias)
	
// Return
