#INCLUDE "rwmake.ch"
#INCLUDE "TOPCONN.CH"
//#INCLUDE "protheus.ch"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Calculo de Frete º Autor ³ Rafael Meyerº Data ³  05/03/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Calcula o frete da Venda / Faturamento                     º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP6 IDE                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//COLOCAR FUNCAO SCHEDULER

User Function DIS125()
	
	Private cDtini 		:= FirstDay(dDataBase)
	Private cDtfim 		:= LastDay(dDataBase)
	Private cTranspIni 	:= "      "
	Private cTranspFim	:= "ZZZZZZ"
	
	// Executa gravação do Log de Uso da rotina
	U_BFCFGM01()
	
	@ 200,1 TO 380,395 DIALOG oLeTxt TITLE OemToAnsi("Informações da NF.")
	@ 02,10 TO 070,190
	@ 10,018 Say "Data Inicial"
	@ 10,075 Get cDtini Size 50,10
	@ 20,018 Say "Data Final"
	@ 20,075 Get cDtfim Size 50,10
	@ 30,018 Say "Transp.Inicial"
	@ 30,075 Get cTranspIni F3 "SA4" Size 50,10
	@ 40,018 Say "Transp.Final"
	@ 40,075 Get cTranspFim F3 "SA4" Size 50,10
	@ 72,133 BMPBUTTON TYPE 01 ACTION (U_DIS125A(),Close(oLeTxt))
	@ 72,163 BMPBUTTON TYPE 02 ACTION Close(oLeTxt)
	
	Activate Dialog oLeTxt Centered
	
Return

ACTIVATE MSDIALOG oDlg086 CENTERED //ON INIT IIF(nOpcao == 2 ,Processa({|| CriaTree(oTree,nOpcao,aArraySetor,aArrayVeic,cCarga) },"Processando Monta Carga"),nil)

Return

Return

User Function DIS125DC()
	
	
	Local aOpenTable := {"SF2","SA4","SC5","SD2"}
	
	Private cDtini
	Private cDtfim
	Private cTranspIni 	:= "      "
	Private cTranspFim	:= "ZZZZZZ"
	
	RPCSetType(3)
	
	RPCSetEnv("01","01","","","","",aOpenTable) // Abre todas as tabelas.
	
	cDtini :=dDataBase
	cDtfim := dDataBase
	// Executa para DCondor
	U_DIS125A() // Chama a mesma rotina mas com as tabelas abertas pelo Schedule.
	
	RpcClearEnv() // Limpa o environment
	
	
	RPCSetType(3)
	
	RPCSetEnv("02","01","","","","",aOpenTable) // Abre todas as tabelas.
	
	cDtini :=dDataBase
	cDtfim := dDataBase
	// Executa para HBL
	U_DIS125A() // Chama a mesma rotina mas com as tabelas abertas pelo Schedule.
	
	
Return


User Function DIS125A()
	
	Local 	nFrete 		:= 0
	Local 	nOrd   		:= 0
	Local 	cCliente 		:= Space(8)
	Local 	nConta 		:= 0
	Local 	aNf 			:= {}
	Local	cEstUf      	:= ""
	Local 	x 
	Local 	w 
	Local 	z 

	CursorWait()
	
	// criar SA1_COBEXTR
	
	nDiasdif := (cDtfim-cDtini)+1
	
	
	For z := 1 To nDiasdif
		
		// Zera variaveis
		aNf := {}
		nOrd	:= 0   // Variavel para controlar ordenação do array
		
		cQry := "SELECT F2_DOC,F2_SERIE,F2_CLIENTE,F2_LOJA,F2_VALBRUT,F2_VALFAT,CASE WHEN F2_PBRUTO = 0 THEN F2_PLIQUI ELSE F2_PBRUTO END  F2_PBRUTO,F2_TRANSP,F2_EMISSAO,F2_EST "
		cQry += "  FROM " + RetSqlName("SF2")
		cQry += " WHERE D_E_L_E_T_ = ' ' "
		cQry += "   AND F2_FILIAL = '" + xFilial("SF2") + "' "
		//cQry += "   AND F2_EMISSAO BETWEEN '"+DTOS(cDtini)+"' AND '"+DTOS(cDtfim)+"'  "
		cQry += "   AND F2_TRANSP BETWEEN '"+cTranspIni+"' AND '"+cTranspFim+"' "
		cQry += "   AND F2_EMISSAO = '"+DTOS(cDtini)+"' "
		cQry += " ORDER BY F2_CLIENTE,F2_LOJA,F2_DOC DESC "
		
		TCQUERY cQry NEW ALIAS "QRP"
		
		cDtIni 	 := cDtIni+1
		
		dbselectarea("QRP")
		DbGotop()
		While !Eof()
			nOrd++
			AADD(aNf,{	QRP->F2_DOC,;		// 1
			QRP->F2_SERIE,;		// 2
			QRP->F2_CLIENTE,;	// 3
			QRP->F2_LOJA,; 		// 4
			QRP->F2_VALBRUT,; 	// 5
			QRP->F2_VALFAT,; 	// 6
			QRP->F2_PBRUTO,; 	// 7
			QRP->F2_TRANSP,; 	// 8
			0,;					// 9
			nOrd,;				// 10
			QRP->F2_EMISSAO,;	// 11
			QRP->F2_EST})		// 12
			
			dbSelectArea("QRP")
			dbSkip()
		Enddo
		
		QRP->(DbCloseArea())
		
		For w:= 1 To Len(aNf)
			
			nFrete 	:= 0
			If aNf[w][3]+aNf[w][4] <> cCliente
				nValmerc := aNf[w][5]
				nPeso    := aNf[w][7]
				nConta 	 := 0
				cEstUf	 := aNf[w][12]
			Else
				nValmerc += aNf[w][5]
				nPeso    += aNf[w][7]
				nConta ++
			Endif
			
			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+aNf[w][3]+aNf[w][4])
			
			// Posiciona na tabela  Transportadora X Estado X Cidades
			cQry := "SELECT ZK_CLIENTE,ZK_LOJA,R_E_C_N_O_ ZKRECNO "
			cQry += "  FROM " + RetSqlName("SZK")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND '"+aNf[w,11]+"' BETWEEN ZK_DTINI AND ZK_DTFIM "
			cQry += "   AND ZK_CODMUN = '"+SA1->A1_COD_MUN+"' "
			cQry += "   AND ZK_EST = '"+SA1->A1_EST+"' "
			cQry += "   AND ZK_TRANSP = '"+aNf[w,8]+"' "
			cQry += "   AND ZK_FILIAL = '"+xFilial("SZK")+"' "
			cQry += " ORDER BY ZK_CLIENTE,ZK_LOJA "
			
			DbSelectArea("SZK")
			DbSetOrder(1)
			
			TCQUERY cQry NEW ALIAS "QSZK"
			
			While !Eof()
				// Se houver cliente cadastrado para a cidade, verifica se o cliente for diferente do cliente em cursor - Para localizar taxas especificas por cliente
				
				If (!Empty(QSZK->ZK_CLIENTE) .And. QSZK->ZK_CLIENTE+QSZK->ZK_LOJA <> SA1->A1_COD+SA1->A1_LOJA)
					QSZK->(DbSkip())
					Loop
				Endif
				aBlock	:= {}
				DbSelectArea("SA4")
				DbSetOrder(1)
				If DbSeek(xFilial("SA4")+aNf[w,8])
					If Empty(SA4->A4_DIS125)
						MsgAlert("Não há fórmula de cálculo de frete para a transportadora '"+ SA4->A4_COD+"-"+SA4->A4_NREDUZ+ " Solicite o cadastro junto ao departamento de logística!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
						CursorArrow()
						QSZK->(DbCloseArea())
						Return 
					Endif
					Aadd(aBlock,&(SA4->A4_DIS125))
					DbSelectArea("SZK")
					DbGoto(QSZK->ZKRECNO)
					For x := 1 To Len(aBlock)
						Eval(aBlock[x])
					Next
				Endif
				DbSelectArea("QSZK")
				QSZK->(DbSkip())
			Enddo
			QSZK->(DbCloseArea())
			//ConOut(aNf[w][1]+aNf[w][3]+aNf[w][4])
			// Atualiza o valor do frete em cada linha de nota fiscal
			
			aNf[w,9] := nFrete
			cCliente := aNf[w][3]+aNf[w][4]
		Next
		
		// Executa um loop invertido que irá atualizar SF2
		cCliente := Space(8)
		// Ordena em ordem decrescente o array
		aNf := aSort(aNf,,,{|x,y| x[10] > y[10]} )
		
		For w := 1 To Len(aNf)
			
			dbSelectArea("SF2")
			dbSetOrder(2)
			dbSeek(xFilial("SF2")+aNf[w,3]+aNf[w,4]+aNf[w,1]+aNf[w,2])
			RecLock("SF2",.F.)
			If cCliente <> aNf[w,3]+aNf[w,4]
				SF2->F2_CUSTOFR := aNf[w,9]
			Else
				SF2->F2_CUSTOFR := 0.00
			Endif
			msUnLock("SF2")
			cCliente := aNf[w,3]+aNf[w,4]
		Next
	Next
	CursorArrow()
Return
