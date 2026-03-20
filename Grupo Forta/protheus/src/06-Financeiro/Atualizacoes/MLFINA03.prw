#INCLUDE "rwmake.ch"
#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*/{Protheus.doc} MLFINA03
//TODO Importação de folha de pagamento para geração de Contas a Pagar. 
@author Marcelo Alberto Lauschner
@since 05/02/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function MLFINA03()


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Declaracao de Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	cPathori := "C:\IMPORTA\FOLHA\ATUAL\"
	cTipo    := "*.txt"
	aFiles   := Directory(cPathOri + cTipo)

	Private cPerg       := "MLFINA03"

	ValidPerg()

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

		cNomArq := CriaTrab(aCampos)

		If (Select("QTEMP") <> 0)
			dbSelectArea("QTEMP")
			dbCloseArea()
		Endif
		dbUseArea(.T.,,cNomArq,"QTEMP",nil,.F.)

		If !File(Alltrim("C:\IMPORTA\FOLHA\ATUAL\" + aFiles[a][1]))
			MsgInfo("Arquivo texto nao existente.Programa cancelado","Informa‡ao")
			Return
		Endif

		dbSelectArea("QTEMP")
		Append From (Alltrim("C:\IMPORTA\FOLHA\ATUAL\" + aFiles[a][1])) SDF

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicializa a regua de processamento                                 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		ConOut("")
		ConOut("==========================================")
		ConOut("Processando importacao da folha")
		ConOut("Importado Arquivo --> " + AllTrim(aFiles[a][1]))
		Processa({|| RunCont() },"Processando...")
		ConOut("Importacao de Dados Realizada com sucesso!!")
		ConOut("===========================================")
		ConOut("")

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

	Local	aOpcForn	:= {}
	Local	nOpcForn	:= 0
	Private cCodigo 	:= ""
	Private	cLoja   	:= ""
	Private cBanco 		:= ""

	dbSelectArea("QTEMP")
	ProcRegua(RecCount()) // Numero de registros a processar
	dbGoTop()

	While QTEMP->(!Eof())
		
		aOpcForn	:= {}
		cCodigo 	:= ""
		cLoja   	:= ""
		
		cQvs := ""
		cQvs += "SELECT A2_COD, A2_LOJA,A2_NOME,A2_ULTCOM,A2_BANCO,A2_XCODRUB "
		cQvs += "  FROM " + RetSqlName("SA2")
		cQvs += " WHERE D_E_L_E_T_ = ' ' "
		//right(replicate('0',10)+cast(@num as varchar(15)),10)
		cQvs += "   AND (A2_XCODRUB = '"+SubStr(QTEMP->LINHA,3,6)+"' "
		cQvs += "        OR SUBSTRING(A2_NOME,1,30) = '" +SubStr(QTEMP->LINHA,9,30) + "')"
		cQvs += "   AND A2_FILIAL = '" + xFilial("SA2") + "' "

		If Select("QVS") <> 0
			dbSelectArea("QVS")
			dbCloseArea()
		Endif

		TCQUERY cQvs NEW ALIAS "QVS"

		If Eof()
			QVS->(DbCloseArea())
			Alert("Funcionario nao cadastrado ==> " + SubStr(QTEMP->LINHA,3,6) + " " + SubStr(QTEMP->LINHA,9,29))
			dbSelectArea("QTEMP")
			dbSkip()
			Loop
		Endif

		While !QVS->(Eof())
			cCodigo := QVS->A2_COD
			cLoja   := QVS->A2_LOJA
			cBanco 	:= QVS->A2_BANCO
			Aadd(aOpcForn,{cCodigo,cLoja,QVS->A2_NOME,DTOC(STOD(QVS->A2_ULTCOM)),cBanco})
			QVS->(DbSkip())
		Enddo
		QVS->(dbCloseArea())

		If Len(aOpcForn) > 1 

			DEFINE MSDIALOG oDlgA2 TITLE OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Selecione um código e loja de Fornecedor '" +  SubStr(QTEMP->LINHA,3,6) + " " +  SubStr(QTEMP->LINHA,9,30)+"'") FROM 09,00 TO 28,80

			@ 005,004 Say " Selecione um código e loja de fornecedor para '"+  SubStr(QTEMP->LINHA,3,6) + " " +  SubStr(QTEMP->LINHA,9,30) +"'" Pixel Of oDlgA2
			@ 018,004 LISTBOX oOpcForn FIELDS TITLE OemtoAnsi("Código"),OemtoAnsi("Loja"),OemToAnsi("Razão Social"),OemToAnsi("Última Movimentação"),OemToAnsi("Banco") SIZE 310,100 PIXEL Of oDlgA2
			oOpcForn:SetArray(aOpcForn)
			oOpcForn:bLine := {|| aOpcForn[oOpcForn:nAt] }


			DEFINE SBUTTON FROM 130 ,280 TYPE 1 PIXEL ACTION (nOpcForn	:= oOpcForn:nAt, oDlgA2:End()) ENABLE OF oDlgA2 Pixel

			ACTIVATE MSDIALOG oDlgA2 CENTERED Valid nOpcForn > 0

			If nOpcForn > 0
				cCodigo := aOpcForn[nOpcForn,1]
				cLoja   := aOpcForn[nOpcForn,2]
				cBanco	:= aOpcForn[nOpcForn,5]
			Endif
		Endif

		IncProc("Funcionario: " + SubStr(QTEMP->LINHA,3,6))


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

	

	Begin Transaction
		nValor := Val(SubStr(QTEMP->LINHA,43,5)+SubStr(QTEMP->LINHA,49,2))/100

		//+StrZero(Month(dDataBase),2)
		aTitulo := {{"E2_PREFIXO",cPref,Nil},;
		{"E2_NUM"     ,cMes                       ,Nil},;
		{"E2_PARCELA" ,"1"                        ,Nil},;
		{"E2_TIPO"	  ,"FOL"                      ,Nil},;
		{"E2_NATUREZ" ,UPPER(MV_PAR04)            ,Nil},;
		{"E2_FORNECE" ,cCodigo		              ,Nil},;
		{"E2_LOJA"	  ,cLoja		              ,Nil},;
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
Static Function ValidPerg()

	Local _sAlias := Alias()
	Local aRegs := {}
	Local i,j

	dbSelectArea("SX1")
	dbSetOrder(1)
	cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))

	aAdd(aRegs,{cPerg,"01","Dt. Pagamento ","","","mv_ch1","D",8,0,0,"G","","mv_par01","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"02","Prefixo a Imp ","","","mv_ch2","C",3,0,0,"G","","mv_par02","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"03","Numero a  Imp ","","","mv_ch3","C",9,0,0,"G","","mv_par03","","","","","","","","","","","","","",""})
	//           "X1_GRUPO" 		,"X1_ORDEM"	,"X1_PERGUNT"   	,"X1_PERSPA"	,"X1_PERENG"	,"X1_VARIAVL"	,"X1_TIPO"	,"X1_TAMANHO"		,"X1_DECIMAL"		,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5"	,"X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"

	aAdd(aRegs,{cPerg				,"04"		,"Natureza      "	,""				,""				,"mv_ch4"		,"C"		,10					,0					,0				,"G"		,""			,"mv_par04"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,"SED"})


	For i:=1 to Len(aRegs)
		If !dbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j <= Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next

	dbSelectArea(_sAlias)

Return
