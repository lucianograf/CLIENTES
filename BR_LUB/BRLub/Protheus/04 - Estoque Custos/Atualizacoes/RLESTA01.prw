#Include 'Protheus.ch'


/*/{Protheus.doc} RLESTA01
(Efetua a alocação de endereços de estoque para os produtos pendentes)
@type function
@author marce
@since 06/10/2016
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function RLESTA01()
	Local	aAreaSA1	:= SA1->(GetArea())
	
	//EXEMPLO PARA ENDEREÇAR UM ITEM *********
	DbSelectArea("SA1")
	DbSetOrder(1)
	Set Filter To !Empty(A1_XLOCPAD) 
	DbGotop()
	While !Eof() 
		sfEndereca(SA1->A1_COD,SA1->A1_LOJA,SA1->A1_XLOCPAD)
		DbSelectArea("SA1")
		DbSkip()
	Enddo
	
	DbSelectArea("SA1")
	DbSetOrder(1)
	Set Filter To 
	RestArea(aAreaSA1)
	
Return 


Static Function sfEndereca(cInCli,cInLoja,cInLocPad)

	Local	cQry		:= ""
	Local 	aCabSDA    	:= {}
	Local 	aItSDB    	:= {}
	Local 	_aItensSDB 	:= {}
	Local	cLocalizPd	:= "  "
	Local	nContSBE	:= 0
	Local	nSvRecSBE	:= 0
	Private	lMsErroAuto := .F.

	If !MsgYesNo("Deseja realmente executar o processo de endereçamento automático para o cliente '"+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME+"'")
		Return 
	Endif
	
	DbSelectArea("SBE")
	DbSetOrder(1)
	nSvRecSBE	:= SBE->(Recno())
	If DbSeek(xFilial("SBE")+cInLocPad)
		cLocalizPd	:= SBE->BE_LOCALIZ
		While !Eof() .And. SBE->BE_FILIAL == xFilial("SBE") .And. SBE->BE_LOCALIZ == cLocalizPd 
			nContSBE++
			SBE->(DbSkip())
		Enddo
		DbSelectArea("SBE")
		DbGoto(nSvRecSBE)
	Else
		MsgAlert("Não foi encontrado endereço padrão para o armazém "+ cInLocPad)
		Return
	Endif
	//Cabeçalho com a informação do item e NumSeq que sera endereçado.

	cQry := "SELECT DA_PRODUTO,DA_NUMSEQ,DA_DATA,DA_SALDO,DA_NUMSEQ"
	cQry += "  FROM " + RetSqlName("SDA") + " DA "
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND DA_SALDO > 0 " 
	cQry += "   AND DA_FILIAL = '" + xFilial("SDA") + "'"
	cQry += "   AND DA_LOCAL = '"+ cInLocPad+"'"
	cQry += "   AND DA_LOJA = '" + cInLoja+ "'"
	cQry += "   AND DA_CLIFOR = '" + cInCli + "' " // Especifico para a Atrialub e filiais 

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QSDA",.T.,.F.)

	While !Eof()

		aCabSDA := {{"DA_PRODUTO" ,QSDA->DA_PRODUTO	,Nil},;
		{"DA_NUMSEQ"  ,QSDA->DA_NUMSEQ	,Nil}}

		//Dados do item que será endereçado
		aItSDB := {	{"DB_ITEM"	  	,"0001"	,Nil},;
		{"DB_ESTORNO"  	," "	      		,Nil},;
		{"DB_LOCALIZ"  	,cLocalizPd		   	,Nil},;
		{"DB_DATA"	   	,STOD(QSDA->DA_DATA),Nil},;
		{"DB_QUANT"  	,QSDA->DA_SALDO     ,Nil}}

		Aadd(_aItensSDB,aitSDB)
		lMsErroAuto := .F.
		//Executa o endereçamento do item
		Begin Transaction
			MATA265( aCabSDA, _aItensSDB, 3)
		End Transaction
		_aItensSDB	:= {}

		If lMsErroAuto
			DisarmTransaction()
			MostraErro()
		Else
			//MsgAlert("Processamento Ok!" + QSDA->DA_PRODUTO + " - " + QSDA->DA_NUMSEQ)
		Endif

		DbSelectArea("QSDA")
		DbSkip()
	Enddo
	QSDA->(DbCloseArea())

Return






//EXEMPLO PARA ESTORNAR UM ITEM *********

Static Function TMATA265()

	Local aCabSDA    	:= {}
	Local aItSDB        := {}
	Local _aItensSDB 	:= {}
	Private	lMsErroAuto := .F.

	cQry := "SELECT DA_PRODUTO,DA_NUMSEQ,DA_DATA,DA_SALDO,DA_NUMSEQ"
	cQry += "  FROM " + RetSqlName("SDA") + " DA "
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND DA_SALDO > 0 " 
	cQry += "   AND DA_FILIAL = '" + xFilial("SDA") + "'"
	cQry += "   AND DA_CLIFOR = '000002' " // Especifico para a Atrialub e filiais 

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"QSDA",.T.,.F.)

	While !Eof()

		aCabSDA := {{"DA_PRODUTO" ,QSDA->DA_PRODUTO	,Nil},;
		{"DA_NUMSEQ"  ,QSDA->DA_NUMSEQ	,Nil}}

		//Dados do item que será endereçado
		aItSDB := {	{"DB_ITEM"	  	,"0001"	      	,Nil},;
		{"DB_ESTORNO"  	," "	      		,Nil},;
		{"DB_LOCALIZ"  	,"ATRIA PICK"    	,Nil},;
		{"DB_DATA"	   	,STOD(QSDA->DA_DATA),Nil},;
		{"DB_QUANT"  	,QSDA->DA_SALDO     ,Nil}}

		Aadd(_aItensSDB,aitSDB)
		lMsErroAuto := .F.
		//Executa o endereçamento do item
		Begin Transaction
			MATA265( aCabSDA, _aItensSDB, 3)
		End Transaction
		_aItensSDB	:= {}

		If lMsErroAuto
			DisarmTransaction()
			MostraErro()
		Else
			MsgAlert("Processamento Ok!" + QSDA->DA_PRODUTO + " - " + QSDA->DA_NUMSEQ)
		Endif

		DbSelectArea("QSDA")
		DbSkip()
	Enddo

	//Cabeçalho com a informação do item e NumSeq que sera endereçado.
	aCabSDA := {{"DA_PRODUTO" ,"PROD-ENDER",Nil},;
	{"DA_NUMSEQ"  ,"001419",Nil}}

	//Dados do item que será endereçado
	aItSDB := {	{"DB_ITEM"	  ,"0001"	      ,Nil},;
	{"DB_ESTORNO"  ,"S "	      ,Nil},;
	{"DB_LOCALIZ"  ,"LOCAL"    ,Nil},;
	{"DB_DATA"	  ,dDataBase    ,Nil},;
	{"DB_QUANT"  ,20                  ,Nil}}

	aadd(_aItensSDB,aitSDB)
	//Executa o estorno do item
	MATA265( aCabSDA, _aItensSDB, 4)

	If lMsErroAuto
		MostraErro()
	Else
		MsgAlert("Processamento Ok!")
	Endif
	Return


Return

