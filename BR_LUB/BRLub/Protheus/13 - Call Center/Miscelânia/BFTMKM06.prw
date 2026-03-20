#Include 'Protheus.ch'

User Function BFTMKM06()
	
	Local	nContCli	:= 0
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	
	cQry := "SELECT A1_COD,A1_LOJA "
	cQry += "  FROM " + RetSqlName("SA1") + " "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND A1_VEND in( '000408','001253') "
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "' "
	
	
	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QA1', .F., .T.)
	
	Count To nRecCount
	
	nCont		:= 1
	cNumSU6		:= ""
	cNumSU4		:= ""
	cSU4Lista	:= ""
	cDescNV 	:= Space(30)
	cVendTMK	:= Space(3)
	cContato	:= Space(6)
	cLista		:= Space(6)
	dDataVis	:= dDatabase
	cNFantas	:= Space(50)
	cCodC		:= Space(6)
	cLojaC		:= Space(2)
	cGera		:= Space(1)
	cNRedV		:= Space(15)
	
	
	dbSelectArea("QA1")
	dbGoTop()
	ProcREgua(nRecCount)
	While !Eof()
		
		
		
		//	Atualiza o cadastro do cliente com o retorno da nao venda
		DbselectArea("SA1")
		DbSetOrder(1)
		If	DbSeek(xFilial("SA1")+QA1->A1_COD+QA1->A1_LOJA)
			
			//Atualiza a agenda de operadores com o retorno da nao venda
			cNFantas	:= SA1->A1_NOME
			cCodC 		:= SA1->A1_COD
			cLojaC 		:= SA1->A1_LOJA
			cGera 		:= SA1->A1_MSBLQL
		EndIf
		//cVendTMK	:= Posicione("SA1",1,xFilial("SA1")+QA1->ZB_CODCLI+QA1->ZB_LOJACLI,"A1_OPERADO")
		cVendTMK := '000003' //Posicione("SA3",1,xFilial("SA3")+SA1->A1_VEND,"A3_OPERADO")
		
		cContato	:= U_BFTMKG01(cCodC,cLojaC)
		
		nContCli++
		
		
		cNRedV:=Posicione("SA3",1,xFilial("SA3")+SA1->A1_VEND,"A3_NREDUZ")
		
		
		If cGera <> '1'
			
			If nContCli >= 20
				nContCli	:= 1
				nCont := 1
				dDataVis++
				//Verifica se data é valida, ou seja, se nao cai em um final de semana ou feriado.
				While dDataVis <> DataValida( dDataVis )
					dDataVis++
				EndDo
				
				DbselectArea("SU4")
				Dbsetorder(1)
				
				cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
				ConfirmSX8()
				
				While DbSeek(xFilial() + cSU4Lista )
					cSU4Lista	:=	GetSxeNum( "SU4" ,"U4_LISTA")
					ConfirmSX8()
				EndDo
				
				DbselectArea("SU4")
				RecLock("SU4",.T.)
				SU4->U4_FILIAL	:= xFilial("SU4")
				SU4->U4_STATUS 	:= "1" 										//	Ativa
				SU4->U4_TIPO 	:= "3" 										//	Vendas
				SU4->U4_LISTA 	:= cSU4Lista								//	GetSxeNum("SU4","U4_LISTA") //	Codigo do atendimento
				SU4->U4_DESC 	:= ALLTRIM(cNRedV)+" / "+ALLTRIM(cCodC)+"-"+ALLTRIM(cLojaC)+" - "+ALLTRIM(cNFantas)
				SU4->U4_DATA 	:= dDataVis
				SU4->U4_HORA1 	:= "08:00:00"
				SU4->U4_FORMA 	:= "1" 										//	VOZ
				SU4->U4_TELE  	:= "2" 										//	TELEVENDAS
				SU4->U4_OPERAD 	:= cVendTMK
				SU4->U4_TIPOTEL := "1" 										//	RESIDENCIAL
				SU4->U4_DTVISIT := SA1->A1_ULTCOM
				SU4->U4_OBSVEN  := SA1->A1_OBSNVEN + " - "+ALLTRIM(cDescNV)
				
				MsUnlock()
				cLista	:= SU4->U4_LISTA
			Endif
			
			cNumSU6	:= StrZero(nCont,6)
			
			DbSelectArea("SU6")
			RecLock("SU6", .T.)
			SU6->U6_FILIAL	:= xFilial("SU6")
			SU6->U6_LISTA	:= cLista   								//	Codigo do atendimento
			SU6->U6_CODIGO	:= cNumSU6									//	GetSxeNum("SU6","U6_CODIGO")
			SU6->U6_FILENT	:= xFilial( "SA1" )				 			//	xFilial("SA1")
			SU6->U6_ENTIDA	:= "SA1"									//	"SA1"
			SU6->U6_CODENT	:= SA1->A1_COD + SA1->A1_LOJA
			SU6->U6_ORIGEM	:= "3"  									//	Atendimento
			SU6->U6_CONTATO	:= cContato
			SU6->U6_DATA	:= dDataVis
			SU6->U6_HRINI 	:= "08:00"
			SU6->U6_HRFIM	:= "23:59"
			SU6->U6_STATUS	:= "1"   									//	Nao enviado
			
			MsUnLock()
			
			
			nCont += 1
		Endif
		dbSelectArea("QA1")
		DbSkip()
	EndDo
	QA1->( dbCloseArea())
	
	
Return
