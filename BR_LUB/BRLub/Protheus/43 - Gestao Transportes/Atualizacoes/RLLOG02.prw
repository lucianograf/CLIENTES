#include "rwmake.ch"
#include "protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "TBICONN.CH"



//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 17/07/18
// Nome função: RLLOG02
// Parametros :
// Objetivo   : Interface de Gerenciamento Registros de Operações Logisticas
// 				Projeto CROSS DOCKING
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------



User Function RLLOG02

	Local		oDlg
	Local		nUsado		:= 0
	Local		nQteDias	:= 0
	Local		cCampo 		:= ""
	Local 		iX
	Local nLin				:= 002
	Local nCol				:= 005
	Local nNewLin			:= 013
	Local nNewCol			:= 085
	Local cOpcExcel			:= SuperGetMV("BF_GEREXC",.F.,"0603")


	Private  cPergXml	:= "RLLOG02"

	Private aSize 		:= MsAdvSize( .T., .F., 400 )		// Size da Dialog
	Private nAltura 	:= aSize[6]/2.2
	Private nMetade 	:= aSize[6]/7
	Private	oVermelho	:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	Private	oAmarelo	:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private	oVerde		:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private	oNoMarked  	:= LoadBitmap( GetResources(), "LBNO" )
	Private	oMarked    	:= LoadBitmap( GetResources(), "LBOK" )
	Private aCampos   	:= {}
	Private	aArqXml		:= {}
	Private	oArqXml
	Private cArqXml
	Private	aArqSE1		:= {}
	Private	oArqSE1
	Private cArqSE1
	Private	cVarPesq	:= space(09)
	Private aHeader 	:= {}
	Private aCols		:= {}
	Private n			:= 1
	Private oMulti
	Private cObserv	:= ""
	Private nNumInad	:= 0
	Private nTotInad	:= 0
	Private nSaldPer	:= 0
	Private oNumInad,oTotInad,oObserv,oSaldPer,oCbMemo,oBtnSend
	Private oCbSituacao
	Private cComb		:=  0 //"0"
	Private cCboxMemo	:= "1"
	Private bRefrXmlT	:= {|| Iif(Pergunte(cPergXml,.T.),(lSelBox	:= .F.,Processa({|| stRefresh() },"Aguarde, procurando registros ...."),Processa({|| stRefrItens(cComb) },"Aguarde carregando itens....")),Nil)}
	Private bRefrXmlF	:= {|| Pergunte(cPergXml,.F.),(Processa({|| stRefresh() },"Aguarde, procurando registros ...."),Processa({|| stRefrItens(cComb) },"Aguarde carregando itens...."))}
	Private bRefrItens	:= {|| Processa({|| stRefrItens(cComb) },"Aguarde carregando itens....")}
	Private nFocus1		:= 0
	Private nFocus2		:= 0

	Private lSelBox		:= .T.
	Private lSortOrd	:= .T.


	//cria grupo de perguntas para para carregar os dados dos clientes na interface
	// ValidPerg()
	If !Pergunte(cPergXml,.T.)
		REturn
	Endif

	DbSelectArea("Z23")
	DbSetOrder(1)

	//browser com os dados dos clientes e interfaces para criar e controlar operações

	Define MsDialog oDlg From 0,0 TO aSize[6] , aSize[5]  Pixel Title OemToAnsi("Controle de Operações ") + SM0->M0_NOMECOM

	@ nLin			, nCol Button oBtnTlcob PROMPT  "Registrar Operações" Size 70,10 Action(sfIncReg()) Of oDlg Pixel
	@ nLin+nNewLin	, nCol Button oBtnPosCli PROMPT "Geração Fatura"            Size 70,10 Action(sfGeraFatura()) Of oDlg Pixel

	nCol += nNewCol

	@ nLin			, nCol Button oBtnRefr PROMPT   "Filtrar dados"     Size 70,10 Action(Eval(bRefrXmlT)) Of oDlg Pixel
	@ nLin+nNewLin	, nCol Button oBtnSend PROMPT   "Gerar Relatorio"   Size 70,10 Action(GerarArq()) Of oDlg Pixel

	If Alltrim(FWCodEmp())+Alltrim(FWCodFil()) $ Alltrim(cOpcExcel)
		nCol += nNewCol
		@ nLin			, nCol Button oBtnSend PROMPT   "Excel Prd S/ Peso"   Size 70,10 Action(fExporExc()) Of oDlg Pixel
		@ nLin+nNewLin	, nCol Button oBtnSend PROMPT   "Peso Tp x Oper"   Size 70,10 Action(fUpdPes()) Of oDlg Pixel
	EndIf

	nCol += nNewCol

	//@ 003, 175 Say "Filtro Situação" of oDlg Pixel
	@ nLin			, nCol Combobox oCbSituacao Var cComb ITEMS {"0=Em Aberto","1=Faturado","2=Todos"} Valid sfCbox() of oDlg Pixel Size 80,11

	nCol += nNewCol

	@ nLin			, nCol Button oBtnSair PROMPT "Sair" Size 70,10 Action(oDlg:End()) Of oDlg Pixel

	//oBtnSend:Disable()

	//Aadd(aHeader,{Trim(X3Titulo()), SX3->X3_CAMPO,SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID,"",SX3->X3_TIPO,"","" })

	// aSX3Add	:= {"Z23_STATUS", "Z23_OPER","Z23_SERVIC","Z23_CLIENT","Z23_LOJA","Z23_NOMCLI","Z23_VALOR","Z23_DATA","Z23_HORA","Z23_USUARI","Z23_NRCONT"}
	// For iX := 1 To Len(aSX3Add)
	// 	DbSelectArea("SX3")
	// 	DbSetOrder(2)
	// 	If DbSeek(aSX3Add[iX])
	// 		If X3USO(SX3->X3_USADO)
	// 			Aadd(aHeader,{ AllTrim(X3Titulo()),;
	// 				SX3->X3_CAMPO	,;
	// 				SX3->X3_PICTURE,;
	// 				SX3->X3_TAMANHO,;
	// 				SX3->X3_DECIMAL,;
	// 				SX3->X3_VALID	,;
	// 				SX3->X3_USADO	,;
	// 				SX3->X3_TIPO	,;
	// 				SX3->X3_F3 		,;
	// 				SX3->X3_CONTEXT,;
	// 				SX3->X3_CBOX	,;
	// 				SX3->X3_RELACAO })
	// 			nUsado++
	// 		Endif
	// 	Endif
	// Next

	aSX3Add	:= {"Z23_STATUS", "Z23_OPER","Z23_SERVIC","Z23_CLIENT","Z23_LOJA","Z23_NOMCLI","Z23_VALOR","Z23_DATA","Z23_HORA","Z23_USUARI","Z23_NRCONT"}
	For iX := 1 To Len(aSX3Add)
		cCampo := aSX3Add[iX]
		If X3USO(GetSx3Cache(cCampo,"X3_USADO"))
			Aadd(aHeader,{GetSx3Cache(cCampo,"X3_TITULO"),;
				GetSx3Cache(cCampo,"X3_CAMPO")		,;
				GetSx3Cache(cCampo,"X3_PICTURE")	,;
				GetSx3Cache(cCampo,"X3_TAMANHO")	,;
				GetSx3Cache(cCampo,"X3_DECIMAL")	,;
				GetSx3Cache(cCampo,"X3_VALID")	,;
				GetSx3Cache(cCampo,"X3_USADO")		,;
				GetSx3Cache(cCampo,"X3_TIPO")		,;
				GetSx3Cache(cCampo,"X3_F3") 		,;
				GetSx3Cache(cCampo,"X3_CONTEXT")	,;
				GetSx3Cache(cCampo,"X3_CBOX")		,;
				GetSx3Cache(cCampo,"X3_RELACAO") 	})
			nUsado++
		Endif
	Next

	//@ nMetade+05, 0380 Say "Saldo Período" of oDlg Pixel
	//@ nMetade+05, 0450 MsGet oSaldPer Var nSaldPer Picture "@E 999,999,999.99" Size 50,10 READONLY COLOR CLR_BLUE noborder of oDlg Pixel



	@ 025,005 ListBox oArqXml VAR cArqXml ;
		Fields HEADER "Cliente",;    		   		// 1
		"Loja",;				    // 2
		"Nome";				// 3
		SIZE aSize[5]/2.01,nMetade-20;
		ON DBLClick (Alert("Teste")) OF oDlg PIXEL

	oArqXml:bChange := {|| Pergunte(cPergXml,.F.),Processa({|| stRefrItens(0) },"Aguarde carregando itens....")}

	oArqXml:bHeaderClick := {|| nColPos :=oArqXml:ColPos,lSortOrd := !lSortOrd, aSort(aArqXml,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),oArqXml:Refresh()}


	//@ nAltura-40,110 To nAltura+15,250 of oDlg Pixel
	//@ nAltura+15,110 Say "Observações Último Atendimento" of oDlg Pixel
	//@ nAltura-40,110 Get oObserv Var cObserv of oDlg MEMO Size 140,55 Pixel READONLY

	@ nAltura-18,005 BITMAP oBmp RESNAME "BR_VERMELHO" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura-18,012 SAY "-Faturado" of oDlg pixel
	@ nAltura-10,005 BITMAP oBmp RESNAME "BR_VERDE" SIZE 16,16 NOBORDER of oDlg pixel
	@ nAltura-10,012 SAY "-Em aberto" of oDlg pixel


	//@ (nAltura-nMetade)*0.4+(nMetade+015), 005 To nAltura-42, aSize[5]/2.01+005 Multiline Valid Object oMulti

	//oMulti:oBrowse:bChange := {|| DbSelectArea("ACF"),cObserv	:= 	MSMM(aCols[n,aScan(aHeader,{|x| Alltrim(x[2]) == "ACF_OBS"})],TamSx3("ACF_OBS")[1]),oObserv:Refresh()}
	//oMulti:oBrowse:bLClicked := {|| DbSelectArea("ACF"),cObserv	:= 	MSMM(aCols[n,aScan(aHeader,{|x| Alltrim(x[2]) == "ACF_OBS"})],TamSx3("ACF_OBS")[1]),oObserv:Refresh()}

	//"Cod Cliente",;
	//"Loja",;
	//"Nome do Cliente",;

	@ nMetade+014,005 ListBox oArqSE1 VAR cArqSE1 ;
		Fields HEADER " ",;
		"Operação",;
		"Desc Operação",;
		"Serviço",;
		"Desc Serviço",;
		"Data",;
		"Hora",;
		"Usuario" ,;
		"Nr Container", ;
		"Valor",;
		"Recno";
		SIZE aSize[5]/2.01,(nAltura-nMetade) * 0.8;
		ON DBLClick (sfAlter()) OF oDlg PIXEL


	//aHoBrw := MtAHeader(noBrw)

	//aArqSE1 := MtACols(noBrw)

	//oArqSE1       := MsNewGetDados():New(nMetade+014,005,aSize[5]/2.01,(nAltura-nMetade)*0.6,GD_INSERT+GD_DELETE+GD_UPDATE,'AllwaysTrue()','AllwaysTrue()','',,0,999,'AllwaysTrue()','','AllwaysTrue()',oDlg,aHoBrw,aArqSE1 )

	Processa({|| stRefresh() },"Aguarde procurando registros ....")

	oArqXml:SetFocus()
	nFocus1	:= GetFocus()
	//	oArqSE1:SetFocus()
	//nFocus2	:= GetFocus()
	SetFocus(nFocus1)

	Set Key VK_F6 TO sfAlter()

	Activate MsDialog oDlg Centered

Return

//-------------------------------------------------------------------------------------------------
// Analista   : Júnior Conte  - 17/07/2018
// Nome função: sfIncReg
// Parametros :
// Objetivo   : Função para incluir registro na Z23, tabela de operações de serviços e armazenagem
// Retorno    :
// Alterações :
//-------------------------------------------------------------------------------------------------
Static Function sfIncReg

	LOCAL aCores := {}
	Local aIndex := {}
	AADD(aCores,{"Z23_STATUS == '0' ", "VERDE" }) //chamado em aberto
	AADD(aCores,{"Z23_STATUS == '1' ", "VERMELHO" })//chamado em analise





	Private cCadastro := "Registro de Operações."

	Private aRotina := { {"Pesquisar","AxPesqui",0,1} ,;
		{"Visualizar","AxVisual",0,2} ,;
		{"Incluir","AxInclui",0,3} ,;
		{"Alterar","AxAltera",0,4} ,;
		{"Excluir","AxDeleta",0,5} }


	//aAutoCab := {}
	//MBrowseAuto(3,aRotina,"Z23")

	Private cString := "Z23"

	dbSelectArea("Z23")
	dbSetOrder(1)


	dbSelectArea("SA1")
	dbSetOrder(1)
	dbSeek(xFilial("SA1") + aArqXml[oArqXml:nAt,1] + aArqXml[oArqXml:nAt,2] )
	//na tela de operações filtro somente os clientes que estou posicionado
	cFilBrw := "Z23_CLIENT == '"+aArqXml[oArqXml:nAt,1]+"' .AND. Z23_LOJA == '"+aArqXml[oArqXml:nAt,2]+"' "

	Private bFiltraBrw := { || FilBrowse( "Z23" , @aIndex , @cFilBrw ) } //Determina a Expressao do Filtro

	//alert(cFilBrw)
	dbSelectArea(cString)

	Eval( bFiltraBrw )

	mBrowse( 6,1,22,75,cString,,,,,, aCores)

	stRefrItens()

	EndFilBrw( "Z23" , @aIndex ) //Finaliza o Filtro


Return



//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte  - 17/07/2018
// Nome função: sfAlter
// Parametros :
// Objetivo   : Consulta lista detalhada dos produtos quando der F6 ou duplo clique no item
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------
Static Function sfAlter()

	Z23->(MSGoto(aArqSE1[oArqSE1:nAt,11]))
	U_RLLOG05()

Return

Static Function sfCbox()
	lSelBox	:= .T.
	Eval(bRefrXmlF)
Return .T.


//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 17/07/2018
// Nome função: sfRefresh
// Parametros :
// Objetivo   : Efetua a carga dos dados no listbox de clientes
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------
Static Function stRefresh()


	Local	aDestino	:= {}
	Local	nRecSM0		:= 0
	Local	lExistSF1	:= .F.
	Local	cF1Status	:= ""
	Local	bFiltxml	:= Nil

	aArqXml := {}

	IncProc("Fazendo consulta no Banco de dados")
	cAliasZ2 := GetNextAlias()
	BeginSql Alias cAliasZ2
		SELECT
			DISTINCT Z22_CLIENT,
			Z22_LOJA,
			Z22_NOMCLI
		FROM
			%Table:Z22% Z22
		WHERE
			Z22.%NotDel%
			AND Z22_CLIENT Between %Exp:MV_PAR01% AND %Exp:MV_PAR02%
			AND Z22_LOJA Between %Exp:MV_PAR03% AND %Exp:MV_PAR04%
	EndSql

	Count to nRec
	ProcRegua(nRec)
	DbGotop()
	While !Eof()

		IncProc("Lendo registros..."+(cAliasZ2)->Z22_CLIENT)


		Aadd(aArqXml,{	(cAliasZ2)->Z22_CLIENT,;					    // 1 Cliente
			(cAliasZ2)->Z22_LOJA,;									        // 2 Loja
			(cAliasZ2)->Z22_NOMCLI})									    // 3 Nome

		DbSelectArea(cAliasZ2)
		DbSkip()
	Enddo

	(cAliasZ2)->(DbCloseArea())

	If Len(aArqXml) == 0
		MsgAlert("Não houveram registros para este filtro!")
		Aadd(aArqXml,{	"",;    // 2
			"",;	// 3
			""})

		oArqXml:nAt := 1
	Endif

	If oArqXml:nAt > Len(aArqXml)
		oArqXml:nAt := Len(aArqXml)
	Endif

	// Reordeno por Valor
	aSort(aArqXml,,,{|x,y| x[3] > y[3]})


	oArqXml:SetArray(aArqXml)
	oArqXml:bLine:={ ||{aArqXml[oArqXml:nAT,01],;
		aArqXml[oArqXml:nAT,02],;
		aArqXml[oArqXml:nAT,03]}}
	oArqXml:Refresh()

	//U_MLDBSLCT("CONDORTMKC",.F.,1)
	//DbSeek(cEmpAnt+xFilial("SA1")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3])

Return


//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 17/07/2018
// Nome função: stLegenda
// Parametros :
// Objetivo   : Retornar o objeto para legenda dos listbox
// Retorno    : Objeto com a cor do status
// Alterações :
//---------------------------------------------------------------------------------------

Static Function stLegenda(nInLegenda)

	Local	oRet	:= oVermelho

	If Len(aArqXml) <= 0
		Return oRet
	Endif

	If	nInLegenda == 0
		oRet	:= oVerde //oVermelho
	ElseIf nInLegenda == 1
		oRet	:= oVermelho  //oVerde
	EndIf

Return(oRet)


//---------------------------------------------------------------------------------------
// Analista   : Júnior Conte - 17/07/2018
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
// 	cPergXml :=  PADR(cPergXml,Len(SX1->X1_GRUPO))
// 	//     "X1_GRUPO" ,"X1_ORDEM","X1_PERGUNT"    			,"X1_PERSPA"		,"X1_PERENG"		,"X1_VARIAVL","X1_TIPO"	,"X1_TAMANHO"	,"X1_DECIMAL"	,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
// 	Aadd(aRegs,{cPergXml ,"01"		,"Cliente De"				,"Cliente De	"	 	,"Cliente De  "		,"mv_ch1"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par01"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA1" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"02"		,"Cliente Ate"				,"Cliente Ate	"	 	,"Cliente Ate  "	,"mv_ch2"	,"C"		,6				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"SA1" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"03"		,"Loja    De "				,"Loja    De "			,"Loja    De "		,"mv_ch3"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par03"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"04"		,"Loja    Ate"				,"Loja    Ate"			,"Loja    Ate"		,"mv_ch4"	,"C"		,2				,0				,0				,"G"		,""			,"mv_par04"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})

// 	For i:=1 to Len(aRegs)
// 		If !dbSeek(cPergXml+aRegs[i,2])
// 			RecLock("SX1",.T.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif
// 			Next
// 			MsUnlock("SX1")
// 		Else
// 			/*		RecLock("SX1",.F.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif             '
// 			Next
// 			MsUnlock("SX1")*/
// 		Endif
// 	Next

// Return


/*/{Protheus.doc} PergRel
description
@type function
@version
@author Iago Luiz Raimondi
@since 18/10/2021
@param cPerg, character, nome da pergunta
@return variant, null
/*/
// Static Function PergRel(cPerg)

// 	Local aRegs := {}
// 	Local i,j

// 	dbSelectArea("SX1")
// 	dbSetOrder(1)

// 	cPerg :=  PADR(cPerg,Len(SX1->X1_GRUPO))
// 	Aadd(aRegs,{cPerg ,"01","Emissão de","Emissão de ","Emissão de","mv_ch1","D",8,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","","S","",""})
// 	Aadd(aRegs,{cPerg ,"02","Emissão até","Emissão até","Emissão até","mv_ch2","D",8,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","","S","",""})
// 	Aadd(aRegs,{cPerg ,"03","Lista já faturado?","","","mv_ch3","N",01,0,0,"C","","mv_par03","Não","","","","","Sim","","","","","","","","","","","","","","","","","","","","",""})
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

// Return



//---------------------------------------------------------------------------------------
// Analista   :Júnior Conte - 17/07/2018
// Nome função: sfRefrItens
// Parametros :
// Objetivo   : Efetua a atualização do ListBox de operações
// Retorno    :
// Alterações :
//---------------------------------------------------------------------------------------
Static Function  stRefrItens(cComb)

	Local	cQry		:= ""
	Local	lConvProd	:= .F.
	Local 	nI
	Local   nColuna

	aCols	:= {}
	DbSelectArea("Z23")
	DbSetOrder(1)

	lQuery  := .T.
	cAliasZ23 := GetNextAlias()

	if valtype(cComb) == 'N'
		xComb := cComb
	elseif valtype(cComb) == 'C'
		xComb := val(cComb)
	elseif valtype(cComb) <> 'C' .and. valtype(cComb) <> 'N'
		xComb := 0 //val(cComb)
	endif

	//alert(valtype(cComb))

	if xComb == 0 //"0=Em Aberto"
		BeginSql Alias cAliasZ23
			COLUMN Z23_DATA AS DATE
			SELECT
				Z23_FILIAL,
				Z23_STATUS,
				Z23_OPER,
				Z23_SERVIC,
				Z23_CLIENT,
				Z23_LOJA,
				Z23_NOMCLI,
				Z23_VALOR,
				Z23_DATA,
				Z23_HORA,
				Z23_USUARI,
				Z23_NRCONT,
				R_E_C_N_O_ AS RECNOZ23
			FROM
				%Table:Z23% Z23
			WHERE
				Z23_FILIAL = %xFilial:Z23%
				AND Z23_CLIENT = %exp:aArqXml[oArqXml:nAt,1] %
				AND Z23_LOJA = %exp:aArqXml[oArqXml:nAt,2] %
				AND Z23_NUMFAT = %Exp:' '%
				AND Z23.%NotDel%
			ORDER BY
				R_E_C_N_O_ DESC
		EndSql
	elseif xComb == 1  //"1=Faturado"
		BeginSql Alias cAliasZ23
			COLUMN Z23_DATA AS DATE
			SELECT
				Z23_FILIAL,
				Z23_STATUS,
				Z23_OPER,
				Z23_SERVIC,
				Z23_CLIENT,
				Z23_LOJA,
				Z23_NOMCLI,
				Z23_VALOR,
				Z23_DATA,
				Z23_HORA,
				Z23_USUARI,
				Z23_NRCONT,
				R_E_C_N_O_ AS RECNOZ23
			FROM
				%Table:Z23% Z23
			WHERE
				Z23_FILIAL = %xFilial:Z23%
				AND Z23_CLIENT = %exp:aArqXml[oArqXml:nAt,1] %
				AND Z23_LOJA = %exp:aArqXml[oArqXml:nAt,2] %
				AND Z23_NUMFAT <> %Exp:' '%
				AND Z23.%NotDel%
			ORDER BY
				R_E_C_N_O_ DESC
		EndSql
	elseif  xComb == 2
		BeginSql Alias cAliasZ23
			COLUMN Z23_DATA AS DATE
			SELECT
				Z23_FILIAL,
				Z23_STATUS,
				Z23_OPER,
				Z23_SERVIC,
				Z23_CLIENT,
				Z23_LOJA,
				Z23_NOMCLI,
				Z23_VALOR,
				Z23_DATA,
				Z23_HORA,
				Z23_USUARI,
				Z23_NRCONT,
				R_E_C_N_O_ AS RECNOZ23
			FROM
				%Table:Z23% Z23
			WHERE
				Z23_FILIAL = %xFilial:Z23%
				AND Z23_CLIENT = %exp:aArqXml[oArqXml:nAt,1] %
				AND Z23_LOJA = %exp:aArqXml[oArqXml:nAt,2] %
				AND Z23.%NotDel%
			ORDER BY
				R_E_C_N_O_ DESC
		EndSql
	endif



	While !Eof() .And. (cAliasZ23)->Z23_FILIAL+(cAliasZ23)->Z23_CLIENT+(cAliasZ23)->Z23_LOJA == xFilial("Z23")+aArqXml[oArqXml:nAt,2]+aArqXml[oArqXml:nAt,3]
		AADD(aCols,Array(Len(aHeader)+1))

		For nI := 1 To Len(aHeader)
			If IsHeadRec(aHeader[nI][2])
				//	aCols[Len(aCols)][nI] := QRY->R_E_C_N_O_
			ElseIf IsHeadAlias(aHeader[nI][2])
				aCols[Len(aCols)][nI] := "Z23"
			ElseIf ( aHeader[nI][10] <> "V") .AND. (aHeader[nI][08] <> "M")
				aCols[Len(aCols)][nI] := FieldGet(FieldPos(aHeader[nI][2]))
			Endif
		Next nI

		DbSelectArea(cAliasZ23)
		DbSkip()
	Enddo
	(cAliasZ23)->(DbCloseArea())
	n	:= Len(aCols)

	If n == 0
		AADD(aCols,Array(Len(aHeader)+1))
		For nColuna := 1 to Len( aHeader )

			If aHeader[nColuna][8] == "C"
				aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
			ElseIf aHeader[nColuna][8] == "D"
				aCols[Len(aCols)][nColuna] := dDataBase
			ElseIf aHeader[nColuna][8] == "M"
				aCols[Len(aCols)][nColuna] := ""
			ElseIf aHeader[nColuna][8] == "N"
				aCols[Len(aCols)][nColuna] := 0
			Else
				aCols[Len(aCols)][nColuna] := .F.
			Endif
		Next nColuna
	Endif
	n	:= Len(aCols)

	//	oMulti:oBrowse:Refresh()
	//	oMulti:Refresh()
	DbSelectArea("Z23")
	//oObserv:Refresh()

	aArqSE1:= {}

	//cE1_STATUS	:= "A"
	if xComb == 0 //"0=Em Aberto"
		cAliasZ23 := GetNextAlias()
		BeginSql Alias cAliasZ23
			COLUMN Z23_DATA AS DATE
			SELECT
				Z23_STATUS,
				Z23_OPER,
				Z23_SERVIC,
				Z23_CLIENT,
				Z23_LOJA,
				Z23_NOMCLI,
				Z23_VALOR,
				Z23_DATA,
				Z23_HORA,
				Z23_USUARI,
				Z23_NRCONT,
				R_E_C_N_O_ AS RECNOZ23
			FROM
				%Table:Z23% Z23
			WHERE
				Z23_FILIAL = %xFilial:Z23%
				AND Z23_CLIENT = %exp:aArqXml[oArqXml:nAt,1] %
				AND Z23_LOJA = %exp:aArqXml[oArqXml:nAt,2] %
				AND Z23.%NotDel%
				AND Z23_NUMFAT = %Exp:' '%
			ORDER BY
				Z23_DATA
		EndSql
	elseif  xComb == 1 //"1=Faturado"
		cAliasZ23 := GetNextAlias()
		BeginSql Alias cAliasZ23
			COLUMN Z23_DATA AS DATE
			SELECT
				Z23_STATUS,
				Z23_OPER,
				Z23_SERVIC,
				Z23_CLIENT,
				Z23_LOJA,
				Z23_NOMCLI,
				Z23_VALOR,
				Z23_DATA,
				Z23_HORA,
				Z23_USUARI,
				Z23_NRCONT,
				R_E_C_N_O_ AS RECNOZ23
			FROM
				%Table:Z23% Z23
			WHERE
				Z23_FILIAL = %xFilial:Z23%
				AND Z23_CLIENT = %exp:aArqXml[oArqXml:nAt,1] %
				AND Z23_LOJA = %exp:aArqXml[oArqXml:nAt,2] %
				AND Z23.%NotDel%
				AND Z23_NUMFAT <> %Exp:' '%
			ORDER BY
				Z23_DATA
		EndSql
	elseif xComb == 2
		cAliasZ23 := GetNextAlias()
		BeginSql Alias cAliasZ23
			COLUMN Z23_DATA AS DATE
			SELECT
				Z23_STATUS,
				Z23_OPER,
				Z23_SERVIC,
				Z23_CLIENT,
				Z23_LOJA,
				Z23_NOMCLI,
				Z23_VALOR,
				Z23_DATA,
				Z23_HORA,
				Z23_USUARI,
				Z23_NRCONT,
				R_E_C_N_O_ AS RECNOZ23
			FROM
				%Table:Z23% Z23
			WHERE
				Z23_FILIAL = %xFilial:Z23%
				AND Z23_CLIENT = %exp:aArqXml[oArqXml:nAt,1] %
				AND Z23_LOJA = %exp:aArqXml[oArqXml:nAt,2] %
				AND Z23.%NotDel%
			ORDER BY
				Z23_DATA
		EndSql
	endif


	DbGotop()
	While !Eof()


		Aadd(aArqSE1,{Val((cAliasZ23)->Z23_STATUS),;
			(cAliasZ23)->Z23_OPER,;
			POSICIONE("Z20", 1, XFILIAL("Z20") + (cAliasZ23)->Z23_OPER, "Z20_DESCRI"),;
			(cAliasZ23)->Z23_SERVIC,;
			POSICIONE("Z21", 1, XFILIAL("Z21") + (cAliasZ23)->Z23_SERVIC, "Z21_DESCSE"),;
			(cAliasZ23)->Z23_DATA,;
			(cAliasZ23)->Z23_HORA,;
			(cAliasZ23)->Z23_USUARI,;
			(cAliasZ23)->Z23_NRCONT,;
			Transform((cAliasZ23)->Z23_VALOR,"@E 999,999,999.99"),;
			(cAliasZ23)->RECNOZ23})

		DbSelectArea(cAliasZ23)
		DbSkip()
	Enddo
	(cAliasZ23)->(DbCloseArea())
	*/
	If Len(aArqSE1) == 0
		Aadd(aArqSE1,{	1,;
			"",;
			"",;
			"",;
			"",;
			CTOD("  /  /    "),;
			"",;
			"",;
			"",;
			"",;
			0})
		oArqSE1:nAt := 1
	Endif

	If oArqSE1:nAt > Len(aArqSE1)
		oArqSE1:nAt := Len(aArqSE1)
	Endif



	oArqSE1:SetArray(aArqSE1)
	oArqSE1:bLine:={ ||{stLegenda(aArqSE1[oArqSE1:nAt,1]),;
		aArqSE1[oArqSE1:nAT,02],;
		aArqSE1[oArqSE1:nAT,03],;
		aArqSE1[oArqSE1:nAT,04],;
		aArqSE1[oArqSE1:nAT,05],;
		aArqSE1[oArqSE1:nAT,06],;
		aArqSE1[oArqSE1:nAT,07],;
		aArqSE1[oArqSE1:nAT,08],;
		aArqSE1[oArqSE1:nAT,09],;
		aArqSE1[oArqSE1:nAT,10],;
		aArqSE1[oArqSE1:nAT,11]}}

	oArqSE1:Refresh()

Return // aArqSE1



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³sfGeraFatura      ³Júnior Conte         º Data ³17/07/2018  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function sfGeraFatura()

	U_RLLOG03()

Return

/*Gera planilha em excel*/

Static Function GerarArq()

	Local oFwMsEx := NIL
	Local cArq := ""
	Local cDir := GetSrvProfString("Startpath","")
	Local cWorkSheet := ""
	Local cTable := ""
	Local cDirTmp := GetTempPath()
	Local aHeader := {}
	//IAGO 18/10/2021 Chamado 26661
	Local cPergRel := "RLLOG02A"

	// PergRel(cPergRel)
	If !Pergunte(cPergRel,.T.)
		Return
	Endif

	oFwMsEx := FWMsExcel():New()

	cWorkSheet := "Operações Cliente " + aArqXml[oArqXml:nAt,1]
	cWork2 := "Operações A Pagar "

	cCadastro  := "Operações Cliente " + aArqXml[oArqXml:nAt,1]
	cTable     := "Operações A Receber Cliente : "+  aArqXml[oArqXml:nAt,1]
	cTable2     := "Operações A Pagar"

	ProcRegua(0)

	oFwMsEx:AddWorkSheet( cWorkSheet )
	oFwMsEx:AddWorkSheet( cWork2 )
	oFwMsEx:AddTable( cWorkSheet, cTable )
	oFwMsEx:AddTable( cWork2, cTable2 )

	oFwMsEx:AddColumn( cWorkSheet, cTable , "Status"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Operacao"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Servico"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Desc. Servico"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Usuario"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Cliente"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Loja"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Nome do Cliente"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Dt Registro"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Documento"   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Peso Bru."   , 1,1)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Valor Operação"   , 3,3)
	oFwMsEx:AddColumn( cWorkSheet, cTable , "Nr Container"   , 1,1)

	oFwMsEx:AddColumn( cWork2, cTable2 , "Status"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Operacao"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Servico"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Desc. Servico"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Usuario"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Cliente"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Loja"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Nome do Cliente"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Dt Registro"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Documento"   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Peso Bru."   , 1,1)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Valor Operação"   , 3,3)
	oFwMsEx:AddColumn( cWork2, cTable2 , "Nr Container"   , 1,1)

	cAliasZ23 := GetNextAlias()
	BeginSql Alias cAliasZ23
		COLUMN Z23_DATA AS DATE
		SELECT
			Z23_STATUS,
			Z23_OPER,
			Z23_SERVIC,
			Z23_CLIENT,
			Z23_LOJA,
			Z23_NOMCLI,
			Z23_VALOR,
			Z23_DATA,
			Z23_HORA,
			Z23_USUARI,
			Z23_NRCONT,
			Z23_ADVALO,
			Z23_VALPAG,
			R_E_C_N_O_ AS RECNOZ23,
			Z23_DOC,
			Z23_PESOB
		FROM
			%Table:Z23% Z23
		WHERE
			Z23_FILIAL = %xFilial:Z23%
			AND Z23_CLIENT = %exp:aArqXml[oArqXml:nAt,1] %
			AND Z23_LOJA = %exp:aArqXml[oArqXml:nAt,2] %
			AND Z23_DATA BETWEEN %Exp:DToS(MV_PAR01)% AND %Exp:DToS(MV_PAR02)%
			AND Z23_STATUS = %exp:Iif(MV_PAR03 == 1,'0','1') %
			AND Z23.%NotDel%
		ORDER BY
			Z23_DATA
	EndSql

	DbGotop()
	While !Eof()

		IncProc()
		aTab := {}

		cDescServ := posicione("Z21", 1, XFILIAL("Z21") +  (cAliasZ23)->Z23_SERVIC, "Z21_DESCSE" )
		oFwMsEx:AddRow( cWorkSheet, cTable, { iif(Val((cAliasZ23)->Z23_STATUS) == 0, 'Aberto', 'Faturado'), (cAliasZ23)->Z23_OPER, (cAliasZ23)->Z23_SERVIC, cDescServ,(cAliasZ23)->Z23_USUARI, (cAliasZ23)->Z23_CLIENT, (cAliasZ23)->Z23_LOJA, (cAliasZ23)->Z23_NOMCLI, (cAliasZ23)->Z23_DATA, (cAliasZ23)->Z23_DOC, (cAliasZ23)->Z23_PESOB, (cAliasZ23)->Z23_VALOR, (cAliasZ23)->Z23_NRCONT } )
		oFwMsEx:AddRow( cWork2, cTable2, { iif(Val((cAliasZ23)->Z23_STATUS) == 0, 'Aberto', 'Faturado'), (cAliasZ23)->Z23_OPER, (cAliasZ23)->Z23_SERVIC, cDescServ,(cAliasZ23)->Z23_USUARI, (cAliasZ23)->Z23_CLIENT, (cAliasZ23)->Z23_LOJA, (cAliasZ23)->Z23_NOMCLI, (cAliasZ23)->Z23_DATA, (cAliasZ23)->Z23_DOC, (cAliasZ23)->Z23_PESOB, (cAliasZ23)->Z23_VALPAG, (cAliasZ23)->Z23_NRCONT} )

		DbSelectArea(cAliasZ23)
		DbSkip()
	Enddo



	oFwMsEx:Activate()

	cArq :=  GetNextALias()+ ".xml" //CriaTrab( NIL, .F. ) + ".xml"
	LjMsgRun( "Gerando o arquivo, aguarde...", cCadastro, {|| oFwMsEx:GetXMLFile( cArq ) } )
	If __CopyFile( cArq, cDirTmp + cArq )
		//If aRet[3]
		oExcelApp := MsExcel():New()
		oExcelApp:WorkBooks:Open( cDirTmp + cArq )
		oExcelApp:SetVisible(.T.)
		//Else
		MsgInfo( "Arquivo " + cArq + " gerado com sucesso no diretório " + cDir )
		//Endif
	Else
		MsgInfo( "Arquivo não copiado para temporário do usuário." )
	Endif


Return


/*  retorna o numero de notas fiscais do cliente */
User Function  RLLOG02Z(CCODCLI, CLOJACLI, ddtest, ddtest, CTIPO)

	//cria grupo de perguntas para para carregar os dados dos clientes na interface



	xValor := 0
	//NOTAS DE ENTRADA.
	IF CTIPO == '4'
		xValor := U_RLLOG02X(CCODCLI, CLOJACLI, ddtest, ddtest, CTIPO)
		RETURN  xValor
	ENDIF


	IF CTIPO <> '5'	 .AND. CTIPO <> '3'

		RETURN 0

	ENDIF

	If Select("QRYF2") <> 0
		dbSelectArea("QRYF2")
		QRYF2->(dbCloseArea())
	EndIf



	//NOTAS DE SAÍDA.

	if  CTIPO == '3'
		cQuery := " Select COUNT(*) NRNOTAS FROM ("
		cQuery += "SELECT  DISTINCT SD2.D2_FILIAL, SD2.D2_DOC, SD2.D2_SERIE "
		cQuery += "FROM "+RetSqlName("SD2")+ " SD2 "
		cQuery += "INNER JOIN  "+RetSqlName("SF4")+ " SF4 ON SF4.F4_CODIGO = SD2.D2_TES "
		cQuery += "WHERE SD2.D_E_L_E_T_ = ' '  AND SF4.D_E_L_E_T_ = ' '  AND  SF4.F4_ESTOQUE  = 'S' "
		cQuery += "AND SD2.D2_CLIENTE = '"+CCODCLI+"' "
		cQuery += "AND SD2.D2_LOJA    = '"+CLOJACLI+"' "
		cQuery += "AND SD2.D2_EMISSAO BETWEEN '"+DTOS(ddtest)+"' AND '"+DTOS(ddtest)+"'  "
		cQuery += " ) "
		cQuery := ChangeQuery(cQuery)

		TcQuery cQuery New Alias "QRYF2"

		dbSelectArea("QRYF2")
		QRYF2->(dbGoTop())

		xValor  := 0
		xValor  := QRYF2->NRNOTAS
		Return  { xValor, 0 }
	else

		cQuery := "SELECT   SD2.D2_FILIAL, SD2.D2_CLIENTE, SD2.D2_LOJA, SD2.D2_FILIAL,SD2.D2_CLIENTE, SD2.D2_LOJA,SUM((D2_QUANT * A7_CUBM3 ) ) NRNOTAS, SUM(D2_QUANT  *  SD1.D1_VUNIT )  NCUSTO "
		cQuery += "FROM "+RetSqlName("SD2")+ " SD2 "
		cQuery += "INNER JOIN  "+RetSqlName("SF4")+ " SF4 ON SF4.F4_CODIGO = SD2.D2_TES "
		cQuery += "INNER JOIN  "+RetSqlName("SA7")+ " SA7 ON SA7.A7_PRODUTO = SD2.D2_COD AND SA7.A7_CLIENTE = SD2.D2_CLIENTE  AND  SA7.A7_LOJA = SD2.D2_LOJA  "
		cQuery += "INNER JOIN  "+RetSqlName("SD1")+ " SD1 ON SD1.D1_COD = SD2.D2_COD "
		cQuery += "WHERE SD2.D_E_L_E_T_ = ' '  AND SF4.D_E_L_E_T_ = ' '  AND SD1.D_E_L_E_T_ = ' '  AND SA7.D_E_L_E_T_ = ' '  AND  SF4.F4_ESTOQUE  = 'S' "
		cQuery += "AND SD2.D2_CLIENTE = '"+CCODCLI+"' "
		cQuery += "AND SD2.D2_LOJA    = '"+CLOJACLI+"' "
		cQuery += "AND SD2.D2_EMISSAO BETWEEN '"+DTOS(ddtest)+"' AND '"+DTOS(ddtest)+"'  "
		cQuery += "AND SD1.R_E_C_N_O_ =  (  SELECT  MAX( R_E_C_N_O_)  FROM "+RetSqlName("SD1")+ " SD1 WHERE  SD1.D_E_L_E_T_ = ' ' AND SD1.D1_COD = SD2.D2_COD     ) "
		cQuery += " GROUP BY SD2.D2_FILIAL, SD2.D2_CLIENTE, SD2.D2_LOJA  "

	endif




	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYF2"

	dbSelectArea("QRYF2")
	QRYF2->(dbGoTop())


	xValor  := 0
	nxCusto := 0
	xValor  := QRYF2->NRNOTAS
	if !empty(QRYF2->NCUSTO)
		nxCusto := QRYF2->NCUSTO
	endif

Return  { xValor, nxCusto }



// Static Function CriaPerg()

// 	Local aRegs := {}
// 	Local i,j

// 	dbSelectArea("SX1")
// 	dbSetOrder(1)
// 	cPergXml :=  PADR("RLLOG0A",Len(SX1->X1_GRUPO))
// 	//     "X1_GRUPO" ,"X1_ORDEM","X1_PERGUNT"    			,"X1_PERSPA"		,"X1_PERENG"		,"X1_VARIAVL","X1_TIPO"	,"X1_TAMANHO"	,"X1_DECIMAL"	,"X1_PRESEL"	,"X1_GSC"	,"X1_VALID"	,"X1_VAR01"	,"X1_DEF01"	,"X1_DEFSPA1"	,"X1_DEFENG1"	,"X1_CNT01"	,"X1_VAR02"	,"X1_DEF02"		,"X1_DEFSPA2"		,"X1_DEFENG2"		,"X1_CNT02"	,"X1_VAR03"	,"X1_DEF03"	,"X1_DEFSPA3"	,"X1_DEFENG3"	,"X1_CNT03"	,"X1_VAR04"	,"X1_DEF04"	,"X1_DEFSPA4"	,"X1_DEFENG4"	,"X1_CNT04"	,"X1_VAR05"	,"X1_DEF05"	,"X1_DEFSPA5","X1_DEFENG5"	,"X1_CNT05"	,"X1_F3"	,"X1_PYME"	,"X1_GRPSXG"	,"X1_HELP"
// 	Aadd(aRegs,{cPergXml ,"01"		,"Data De"				,"Cliente De	"	 	,"Cliente De  "		,"mv_ch1"	,"D"		,8				,0				,0				,"G"		,""			,"mv_par01"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})
// 	Aadd(aRegs,{cPergXml ,"02"		,"Data Ate"				,"Cliente Ate	"	 	,"Cliente Ate  "	,"mv_ch2"	,"D"		,8				,0				,0				,"G"		,""			,"mv_par02"	,""			,""				,""				,""			,""			,""				,""					,""					,""			,""			,""			,""				,""				,""			,""			,""			,""				,""				,""			,""			,""			,""			,""				,""			,"" 		,"S"		,""			,""})

// 	For i:=1 to Len(aRegs)
// 		If !dbSeek(cPergXml+aRegs[i,2])
// 			RecLock("SX1",.T.)
// 			For j:=1 to FCount()
// 				If j <= Len(aRegs[i])
// 					FieldPut(j,aRegs[i,j])
// 				Endif
// 			Next
// 			MsUnlock("SX1")
// 		Else

// 		Endif
// 	Next

// Return

/*  retorna o numero de notas fiscais do cliente */
User Function  RLLOG02X(CCODCLI, CLOJACLI, MV_PAR01, MV_PAR02)

	//cria grupo de perguntas para para carregar os dados dos clientes na interface

	If Select("QRYF2") <> 0
		dbSelectArea("QRYF2")
		QRYF2->(dbCloseArea())
	EndIf


	/*
	cQuery := " Select COUNT(*) NRNOTAS FROM ("
	cQuery += "SELECT  DISTINCT SD1.D1_FILIAL, SD1.D1_DOC, SD1.D1_SERIE  "
	cQuery += "FROM "+RetSqlName("SD1")+ " SD1 "
	cQuery += "INNER JOIN  "+RetSqlName("SF4")+ " SF4 ON SF4.F4_CODIGO = SD1.D1_TES "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' '  AND SF4.D_E_L_E_T_ = ' '  AND  SF4.F4_ESTOQUE  = 'S' "
	cQuery += "AND SD1.D1_FORNECE = '"+CCODCLI+"' "
	cQuery += "AND SD1.D1_LOJA    = '"+CLOJACLI+"' "
	cQuery += "AND SD1.D1_EMISSAO BETWEEN '"+DTOS(MV_PAR01)+"' AND '"+DTOS(MV_PAR02)+"'  ) "

	*/

	cQuery := "SELECT   SD1.D1_FILIAL, SD1.D1_FORNECE, SD1.D1_LOJA, SUM( (D1_QUANT * A7_CUBM3 ) )   NRNOTAS, SUM(D1_QUANT) NRPROD "
	cQuery += "FROM "+RetSqlName("SD1")+ " SD1 "
	cQuery += "INNER JOIN  "+RetSqlName("SF4")+ " SF4 ON SF4.F4_CODIGO = SD1.D1_TES "
	cQuery += "INNER JOIN  "+RetSqlName("SA7")+ " SA7 ON SA7.A7_PRODUTO = SD1.D1_COD AND SA7.A7_CLIENTE = SD1.D1_FORNECE  AND  SA7.A7_LOJA = SD1.D1_LOJA  "
	cQuery += "WHERE SD1.D_E_L_E_T_ = ' '  AND SF4.D_E_L_E_T_ = ' '  AND SA7.D_E_L_E_T_ = ' '  AND  SF4.F4_ESTOQUE  = 'S' "
	cQuery += "AND SD1.D1_FORNECE = '"+CCODCLI+"' "
	cQuery += "AND SD1.D1_LOJA    = '"+CLOJACLI+"' "
	cQuery += "AND SD1.D1_EMISSAO BETWEEN '"+DTOS(MV_PAR01)+"' AND '"+DTOS(MV_PAR02)+"'  "
	cQuery += " GROUP BY SD1.D1_FILIAL, SD1.D1_FORNECE, SD1.D1_LOJA  "

	//MEMOWRITE("C:\home\TESTE.TXT",  cQuery )


	cQuery := ChangeQuery(cQuery)

	TcQuery cQuery New Alias "QRYF2"

	dbSelectArea("QRYF2")
	QRYF2->(dbGoTop())


	xValor := 0
	xValor :=  QRYF2->NRNOTAS



Return  {xValor, QRYF2->NRPROD}


/*  Gatilho para atualizar valor  */
User Function  RLLOG02Y(NVALOR, NQUANT)
	xValor := 0

	xValor := NVALOR * NQUANT

Return  xValor



/* validação tipo  chamado do gatilho seq 2 Z23_DTATE  */
User Function  RLLOG02W(CTIPO)
	LRET := .T.
	IF CTIPO == '3' //.or. CTIPO == '4' .or. CTIPO == '5'
		LRET := .T.
	ELSE
		LRET := .F.
	ENDIF

Return  LRET


//-------------------------------------------------------------------
/*/{Protheus.doc} fExporExc

Função que faz a montagem do array para exportação excel.

@author  Rafael Pianezzer de Souza
@since   11/05/2022
@version version
/*/
//-------------------------------------------------------------------
Static Function fExporExc()

	Local aItens		:= {}
	Local aCab			:= {"B1_FILIAL",;
		"B1_COD",;
		"B1_DESC",;
		"B1_PESO",;
		"B1_PESBRU"}
	Local cTit			:= "Exportação de arquivo em excel"
	Local aRodape		:= {}

	If Select('cEmptyPes') <> 0
		cEmptyPes->(DBCloseArea())
	EndIf

	BeginSql Alias 'cEmptyPes'
		SELECT
			B1.B1_FILIAL,
			B1.B1_COD,
			B1.B1_DESC,
			B1.B1_PESO,
			B1.B1_PESBRU,
			B1_TIPO
		FROM
			%table:SB1% B1
		INNER JOIN %table:SA7% A7
		ON (
				A7.A7_FILIAL = %xFilial:SA7%
				AND A7.A7_PRODUTO = B1.B1_COD
				AND A7.A7_CLIENTE = '000013'
				AND A7.A7_LOJA = '33'
				AND A7.%notDel%
			)
		WHERE
			B1.B1_FILIAL = %xFilial:SB1%
			AND B1.B1_PESBRU = 0
			AND B1.B1_TIPO <> 'SV'
			AND B1.%notDel%
	EndSql

	While !cEmptyPes->(Eof())

		aAdd(aItens,{Alltrim(cEmptyPes->B1_FILIAL),;
			Alltrim(cEmptyPes->B1_COD),;
			Alltrim(cEmptyPes->B1_DESC),;
			cEmptyPes->B1_PESO,;
			cEmptyPes->B1_PESBRU})

		cEmptyPes->(DBSkip())
	EndDo


	U_RtFExcel({{aCab,;
		aItens,;
		cTit,;
		aRodape}})

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} fUpdPes

Função que permite o usuario procurar o produto que deseja atualizar o peso e tipo operação.

@author  Rafael Pianezzer de Souza
@since   11/05/2022
@version version
/*/
//-------------------------------------------------------------------
Static Function fUpdPes()

	Local cTitulo           := "Informar peso x tipo operação"
	Local nLin				:= 015
	Local nCol				:= 005
	Local nNewLin			:= 015
	Local nNewCol			:= 085

	Private oConso14N		:= TFont():New("Arial"	,,14,,.T.,,,,,.F.,.F.)
	Private _cCodPrd        := Space(TamSX3('B1_COD')[1])
	Private _cTpOer         := Space(TamSX3('A7_XCODOPE')[1])
	Private _nPeso			:= 0
	Private oCodPrd
	Private oTpOer
	Private oBTN
	Private oDlgBox


	DEFINE DIALOG oDlgBox TITLE cTitulo PIXEL
	oDlgBox:nWidth := 400
	oDlgBox:nHeight := 280
	oPanel2:= tPanel():New(2,2,,,,.T.,,,,300,150)
	oSay2:= TSay():New(nLin-10,nCol,{||'Código do produto: '},oDlgBox,,oConso14N,,,,.T.,,,200,020)
	@ nLin, nCol MSGET oCodPrd VAR _cCodPrd  SIZE 180,010 OF oDlgBox  F3 "SB1" COLORS 0, 16777215 PIXEL
	nLin+=nNewLin+nNewLin

	oSay2:= TSay():New(nLin-10,nCol,{||'Informe o peso bruto: '},oDlgBox,,oConso14N,,,,.T.,,,200,020)
	@ nLin, nCol MSGET oTpOer VAR _nPeso PICTURE "@E 99,999.9999" SIZE 050,010 OF oDlgBox /*When .F.*/ COLORS 0, 16777215 PIXEL

	nLin+=nNewLin+nNewLin
	oSay2:= TSay():New(nLin-10,nCol,{||'Informe o tipo da operação: '},oDlgBox,,oConso14N,,,,.T.,,,200,020)
	@ nLin, nCol MSGET oTpOer VAR _cTpOer  SIZE 180,010 OF oDlgBox F3 "Z201" /*When .F.*/ COLORS 0, 16777215 PIXEL

	nLin+=nNewLin+nNewLin
	@ nLin, nCol BUTTON oBTN PROMPT "Confirmar" SIZE 062, 015  OF oDlgBox  ACTION {|| ValidVazio(_cCodPrd,_cTpOer,_nPeso) }  PIXEL
	nCol+=nNewCol
	@ nLin, nCol BUTTON oBTN PROMPT "Sair" SIZE 062, 015  OF oDlgBox  ACTION {|| oDlgBox:End() }  PIXEL
	ACTIVATE DIALOG oDlgBox CENTER

Return



//-------------------------------------------------------------------
/*/{Protheus.doc} ValidVazio

Validação e gravação dos campos.

@author  Rafael Pianezzer de Souza
@since   11/05/2022
@version version
/*/
//-------------------------------------------------------------------
Static Function ValidVazio(_cCodPrd,_cTpOer,_nPeso)

	Local lRet          := .T.
	Local cCliLoj		:= "00001333"
	Local lB1,lA7		:= .F.


	If Empty(_cCodPrd)
		lRet := .F.
		MsgStop("Você deve selecionar um produto válido.",FunName())
	EndIf

	If Empty(_cTpOer)
		lRet := .F.
		MsgStop("Você deve selecionar o tipo de operação.",FunName())
	EndIf

	If _nPeso == 0
		lRet := .F.
		MsgStop("Você preencher o peso do produto.",FunName())
	EndIf

	If lRet

		DbSelectArea('SB1')
		DbSetOrder(1)
		If DbSeek(xFilial('SB1')+_cCodPrd)
			RecLock('SB1', .F.)
			SB1->B1_PESBRU := _nPeso
			SB1->(MsUnlock())
			lB1 := .T.
		EndIf

		DbSelectArea('SA7')
		DbSetOrder(1)
		If DbSeek(xFilial('SA7')+cCliLoj+_cCodPrd)
			RecLock('SA7', .F.)
			SA7->A7_XCODOPE := _cTpOer
			SA7->(MsUnlock())
			lA7 := .T.
		EndIf

		If lA7 .AND. lB1
		MsgAlert("Produto atualizado com sucesso!", FunName())
		oDlgBox:End()
		EndIf

	EndIf

Return lRet
