#Include 'totvs.ch'
#Include "TopConn.ch"

/*/{Protheus.doc} BFFATA30
Tela de análise de orçamentos e Pedidos de Venda
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 4/11/2014
@param lAuto, logical, indica se a operação é automática
@param cInPed, character, id do epdido
@param nInPedOrc, numeric, indica se é pedido ou orçamento
@param cFlgAlc, character, flag de alçada
@param cInIdUser, character, usuário
@param cInMotAlcada, character, id motivo alçada
@param cInRecebe, character, e-mail para disparo de workflow
/*/
User Function BFFATA30(lAuto,cInPed,nInPedOrc,cFlgAlc,cInIdUser,cInMotAlcada,cInRecebe)
	//U_BFFATA30(.T./*lAuto*/,SUA->UA_NUM/*cInPed*/,2/*nInPedOrc*/)
	Default		cFlgAlc		:= "G"

	If IsBlind()
		MsgAlert("Passou automatico linha 23")
		//BatchProcess("Atenção","Executando tarefa automática"," ",{ || sfExec(lAuto,cInPed,nInPedOrc) })
		//DEFINE WINDOW oMainWnd FROM aSize[1],aSize[2] TO aSize[3] , aSize[4] TITLE OemToAnsi("Validação de pedidos")

		//ACTIVATE WINDOW oMainWnd On Init
		sfExec(lAuto,cInPed,nInPedOrc,cFlgAlc,cInIdUser,cInMotAlcada,cInRecebe)
		//BatchProcess("Testec",OemToAnsi("Teste"),"BFFATA30  ",{ || sfExec(lAuto,cInPed,nInPedOrc,cFlgAlc)})


	Else
		sfExec(lAuto,cInPed,nInPedOrc,cFlgAlc,cInIdUser,cInMotAlcada,cInRecebe)
	Endif

Return


Static Function SchedDef()

	Local aParam

	Local aOrd     := {OemToAnsi(" Por Codigo         ")}

	aParam := { "P",;                      //Tipo R para relatorio P para processo
		"BFFATA30  ",;// Pergunte do relatorio, caso nao use passar ParamDef
		"",;  // Alias
		aOrd,;   //Array de ordens
		"Teste SchedDef"}

Return aParam

/*/{Protheus.doc} sfExec
Função que executa a rotina
@type function
@version 12.1.33
@author Marcelo Lauschner
@since 2/18/2015
@param lAuto, logical, indica se a chamada está sendo feita por rotina automática
@param cInPed, character, número do pedido
@param nInPedOrc, numeric, indica se é pedido ou orçamento
@param cInFlgRetAlc, character, alçadas para aprovação
@param cInIdUser, character, id usuário
@param cInMotAlcada, character, motivo alçada
@param cInRecebe, character, e-mail workflow
/*/
Static Function sfExec(lAuto,cInPed,nInPedOrc,cInFlgRetAlc,cInIdUser,cInMotAlcada,cInRecebe)

	Local		aButton		:= {}
	Local		nSeqC		:= 1
	Local		aAlter		:= {}
	Local		nC			:= 0
	//Local		nBkMvpar07	:= 0
	//Local		cBkMvPar10	:= ""
	//local       cBkMvPar03  := "" as character
	//local		cBkMvPar04  := "" as character
	//local       cBkMvPar05  := "" as character
	//local 		cBkMvPar06  := "" as character
	Local		iSet
	Private 	oDlgBf
	Default	lAuto			:= .F.
	Default	cInPed			:= ""
	Default	nInPedOrc		:= 1
	Default	cInFlgRetAlc	:= Iif(lAuto,"N","")
	Default	cInIdUser		:= __cUserId
	Default	cInMotAlcada	:= ""
	Default cInRecebe		:= ""
	Private	aLoopPedido		:= {}
	Private	cFlgRetAlc		:= cInFlgRetAlc
	Private	aSetKey			:= {}
	Private oArqPed,oPesqNF
	Private	cVarPesq		:= Space(TamSX3("C6_NUM")[1])
	Private	lSortOrd		:= .F.
	Private aSize 			:= MsAdvSize(,.F.,400)
	Private	cPergFATA30		:= "BFFATA30  "
	Private	aListPed		:= {}
	Private	aColsPed		:= {}
	Private	aHeadPed		:= {}
	Private	bRefrXmlT		:= {|| Iif(Pergunte(cPergFATA30,.T.),(Processa({|| sfGetDados() },"Aguarde, procurando registros ...."),Processa({|| stRefrItens() },"Aguarde carregando itens....")),Nil)}
	Private bRefrXmlF		:= {|| (Processa({|| sfGetDados() },"Aguarde, procurando registros ...."),Processa({|| stRefrItens() },"Aguarde carregando itens...."))}
	Private oVermelho		:= LoaDbitmap( GetResources(), "BR_VERMELHO" )
	Private oAzul 			:= LoaDbitmap( GetResources(), "BR_AZUL" )
	Private oAmarelo		:= LoaDbitmap( GetResources(), "BR_AMARELO" )
	Private oVerde			:= LoaDbitmap( GetResources(), "BR_VERDE" )
	Private oPreto			:= LoaDbitmap( GetResources(), "BR_PRETO" )
	Private oPink			:= LoaDbitmap( GetResources(), "BR_PINK" )
	Private oVioleta		:= LoaDbitmap( GetResources(), "BR_VIOLETA" )
	Private oLaranja		:= LoadBitmap( GetResources(), "BR_LARANJA" )
	Private oGrey			:= LoadBitmap( GetResources(), "BR_CINZA" )
	Private oMarrom			:= LoadBitmap( GetResources(), "BR_MARROM" )
	Private oColorCTe		:= LoadBitmap( GetResources(), "BR_CANCEL" )
	Private oAntecipa		:= LoadBitmap( GetResources(), "LBNO" )
	Private	cTit1			:= "'BFFATA30' - Análise de Orçamentos/Pedidos"
	Private	oEndCli,oTransp,oDtProg,oBlqCom,oTabCli,oMsgInt,oMsgNota,oCondPag,oMsgExp,oOrdemCompra
	Private	cEndCli,cTransp,dDtProg,cBlqCom,cTabCli,cMsgInt,cMsgNota,cCondPag,cMsgExp,cOrdemCompra
	Private oDataRota,oStsRota,oDiasFat
	Private aDadEntrega		:= {"2x",CTOD(""),"32","12"}
	Private	aSubValores		:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	Private oSubValores 	:= { , , , , , , , , , , , , , , , , , , , , , }
	Private aHistCli		:= {CTOD(""),CTOD(""),0,0}
	Private oHistCli		:= { , , ,}
	Private	lIsAprovador	:= IIf(lAuto,.T.,IIf(__cUserId $ "000002",MsgYesNo("Perfil de Aprovador?"),__cUserId $ GetNewPar("BF_BFTA30A","00000"))) .or. FWIsAdmin() // Lista de aprovadores
	Private	nPrzMed			:= 0
	Private	nPCusFixo		:= U_BFFATM02(cEmpAnt)
	Private aCabPeds		:= {" ",;    		// 1
		"Tipo",;			      			// 2
		"Número",;    		   				// 3
		"Emissão ",;						// 4
		"Valor",;							// 5
		"Resíduo",;							// 6
		"Pendente",;						// 7
		"Alçada",;							// 8
		"Liberado",;						// 9
		"Blq.Estoque",;						// 10
		"Blq.Crédito",;						// 11
		"Expedição",;						// 12
		"Faturado",;						// 13
		"Cliente/Loja-Nome",;		 		// 14
		"Cidade",;  		           		// 15
		"Estado",;			            	// 16
		"Vendedor",;						// 17
		"Supervisor",;						// 18
		"Assessor(a)",;						// 19
		"Ativo",;							// 20
		"Mensagens"}						//	21

	Private	aTamPeds		:= {05,20,30,30,30,30,30,30,30,30,30,30,30,150,110,20,80,50,80,80,150}

	Private	aCabLog		:= {	"Data",;		//	1
		"Hora",;		// 	2
		"Evento",;		//	3
		"Operador",;	// 	4
		"Observações",;	//	5
		"E-mails",;		//	6
		"Recno"}
	Private	aTamLog		:= {30,30,100,50,200,100,30}
	Private	aListLog		:= {}

	// Forço o aRotina para permitir consulta de posição de clientes
	Private aRotina 	:= {{"Pesquisar","PesqBrw"	, 0 , 1,0,.F.},;	// "Pesquisar"
		{"Automatica","A450LibAut", 0 , 0,0,NIL},;	// "Autom tica"
		{"Manual","A450LibMan", 0 , 0,0,NIL},;	// "Manual"
		{"Legenda","A450Legend", 0 , 3,0,.F.}}	// "Legenda"Private aRotina		:= {}
	Private	cCadastro	:= "Analise de Cotações/Pedidos"

	AjustaSX1()

	cFlgRetAlc	:=  IIf(lAuto,cFlgRetAlc,IIf(__cUserId $ "000002#000204",Iif(MsgYesNo("Perfil de Diretoria?"),"D",cFlgRetAlc),cFlgRetAlc))
	
	// Função  para ajustar profile de usuário que estiver gravado com problema no grupo de perguntas
	profAdjust( __cUserId, cPergFATA30 )

	// Se a rotina for automática força o ajuste da pergunta
	If lAuto

		Pergunte( cPergFATA30,.F.)
		MV_PAR03 := Space( TAMSX3('A3_COD')[1] )
		MV_PAR04 := Replicate( 'Z', TAMSX3('A3_COD')[1] )
		MV_PAR05 := Space( TAMSX3('U7_COD')[1] )
		MV_PAR06 := Replicate( 'Z', TAMSX3('U7_COD')[1] )
		MV_PAR07 := nInPedOrc
		MV_PAR08 := 5		// Todos
		MV_PAR09 := 3		// Ambos
		MV_PAR10 := cInPed	// Pedido

		//cBkMvPar03      := MV_PAR03
		//cBkMvPar04      := MV_PAR04
		//cBkMvPar05      := MV_PAR05
		//cBkMvPar06      := MV_PAR06
		//nBkMvPar07		:= MV_PAR07
		//cBkMvPar10		:= MV_PAR10
		
		//U_GravaSX1(cPergFATA30,"03", PADR( cBkMvPar03, TAMSX3('A3_COD')[1], ' ' ) )	//	03-Vendedor de
		//U_GravaSX1(cPergFATA30,"04", PADR( cBkMvPar04, TAMSX3('A3_COD')[1], ' ' ) )	//	04-Vendedor até
		//U_GravaSX1(cPergFATA30,"05", PADR( cBkMvPar05, TAMSX3('U7_COD')[1], ' ' ) )	//	05-Operador de
		//U_GravaSX1(cPergFATA30,"06", PADR( cBkMvPar06, TAMSX3('U7_COD')[1], ' ' ) )	//	06-Operador até
		//U_GravaSX1(cPergFATA30,"07", nInPedOrc)			//	07-Pedido/Cotação			1-Pedido 2-Orçamento
		//U_GravaSX1(cPergFATA30,"08", 5 )				//	08-Restrição				1-Alçada 2-Crédito 3-Estoque/Liberado 4-Pendente 5-Todos
		//U_GravaSX1(cPergFATA30,"09", 3 )				//	09-Enviado p/ Expedição 	1-Não Enviado 2-Enviado 3-Ambos
		//U_GravaSX1(cPergFATA30,"10", cInPed )			//	10-Num.Pedido

		//Pergunte(cPergFATA30,.F.)
	Else
		//Pergunte(cPergFATA30,.F.)
		//U_GravaSX1(cPergFATA30,"02",MV_PAR01 + 31)
		//U_GravaSX1(cPergFATA30,"03",PADR(MV_PAR03,TAMSX3('A3_COD')[1],' ') )
		//U_GravaSX1(cPergFATA30,"04",PADR(MV_PAR04,TAMSX3('A3_COD')[1],' ') )
		//U_GravaSX1(cPergFATA30,"05",PADR(MV_PAR05,TAMSX3('U7_COD')[1],' ') )
		//U_GravaSX1(cPergFATA30,"06",PADR(MV_PAR06,TAMSX3('U7_COD')[1],' ') )
		if ! Pergunte(cPergFATA30,.T.)
			return Nil
		endif

		If (MV_PAR11 == 5 .Or. !( MV_PAR03 == MV_PAR04 .Or. MV_PAR05 == MV_PAR06)) .And. MV_PAR02 - MV_PAR01 > 31
			MsgAlert("O intervalo de data não pode ser superior a 31 dias entre a Data Inicial e Final de Emissão senão houver um segmento selecionado ou código de assessora informado ou código de vendedor. Favor refaça os filtros selecionando Texaco/Wynns/Michelin ou ajustando o intervalo de dias!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Data excessiva!")
			MV_PAR02 := MV_PAR01 + 31
			//U_GravaSX1(cPergFATA30,"02",MV_PAR01 + 31)
			//U_GravaSX1(cPergFATA30,"03",PADR(MV_PAR03,TAMSX3('A3_COD')[1],' ') )
			//U_GravaSX1(cPergFATA30,"04",PADR(MV_PAR04,TAMSX3('A3_COD')[1],' ') )
			//U_GravaSX1(cPergFATA30,"05",PADR(MV_PAR05,TAMSX3('U7_COD')[1],' ') )
			//U_GravaSX1(cPergFATA30,"06",PADR(MV_PAR06,TAMSX3('U7_COD')[1],' ') )
			if ! Pergunte(cPergFATA30,.T.)
				return Nil
			endif
		Endif
	Endif


	Aadd(aButton,{"PRETO"	,{|| sfTmkObs() } , "1-Follow-up"})
	AAdd(aSetKey,{K_CTRL_1,{|| sfTmkObs() } })

	Aadd(aButton,{"VERDE"	,{|| Eval(bRefrXmlT)}  ,"2-Filtra"})
	AAdd(aSetKey,{K_CTRL_2,{|| sfRefF(2)}})

	If lIsAprovador
		Aadd(aButton,{"AZUL"		,{|| sfMat455() },"3-Alçada"})
		AAdd(aSetKey,{K_CTRL_3,{|| sfMat455() } })

		Aadd(aButton,{"VERMELHO"	,{|| sfConProd() },"4-Produto"})
		AAdd(aSetKey,{K_CTRL_4,{|| sfConProd() }})

		Aadd(aButton,{"PRETO"	,{|| (sfSendWF(),sfRefF())	 	},"Q-WF Aprov."})
		AAdd(aSetKey,{K_CTRL_Q	,{|| (sfSendWF(),sfRefF())	 	}})

		// Marcelo 12/01/2016 - Adicionado relatório de Televendas
		Aadd(aButton,{"PRETO"	,{|| U_TMKR025(),sfRefF() }, "Rel.Televendas"})

	Endif

	//IAGO 17/02/2021 Chamado 25606
	//If lIsAprovador .or. __cUserId $ SuperGetMv("BF_BLQREMA",.F.,"000001")
	// Chamado 26.062 - Retirada restrição pois todas as TMks estava inclusas na opção de remanejar
	Aadd(aButton,{"VERDE", {|| U_BFFATA45(),sfRefF()},"Remanejar Estoque"})

	Aadd(aButton,{"PRETO"	,{|| (sfAltCabec(),sfRefF())	 	},"Alt.Cabec"})
	Aadd(aButton,{"AZUL"		,{|| stVerLog() 		},"5-Log"})
	AAdd(aSetKey,{K_CTRL_5,{|| stVerLog() 		}})

	Aadd(aButton,{"AZUL"		,{|| sf450F4Con() 	},"6-Posição"})
	AAdd(aSetKey,{K_CTRL_6,{|| sf450F4Con()	}})

	Aadd(aButton,{"AMARELO" 	,{|| sfVerPedido() 	},"7-Visualiza"})
	AAdd(aSetKey,{K_CTRL_7,{|| sfVerPedido() 	}})

	Aadd(aButton,{"AMARELO" 	,{|| sfIncPedido() 	},"8-Incluir"})
	AAdd(aSetKey,{K_CTRL_8,{|| sfIncPedido() 	}})

	Aadd(aButton,{"AMARELO" 	,{|| sfAltPedido() 	},"9-Altera"})
	AAdd(aSetKey,{K_CTRL_9,{|| sfAltPedido() 	}})

	Aadd(aButton,{"AMARELO" 	,{|| sfSendCot() 	},"Email Cotação"})

	Aadd(aButton,{"PRETO"	,{|| sfResiduo() 	 	},"Q-Resíduo"})
	AAdd(aSetKey,{K_CTRL_Q,{|| sfResiduo() 	 	}})

	Aadd(aButton,{"PRETO"	,{|| sfSendExp() 	},"W-Envia Fat."})
	AAdd(aSetKey,{K_CTRL_W,{|| sfSendExp()	 	}})

	Aadd(aButton,{"PRETO"	,{|| (U_GMGETXML(),sfRefF())	 	},"Y-Xml NFe"})
	AAdd(aSetKey,{K_CTRL_Y,{|| (U_GMGETXML(),sfRefF())	 	}})

	Aadd(aButton,{"PRETO"	,{|| (stExpExcel(),sfRefF())	 	},"Exporta Excel"})

	// IAGO 03/07/2015 Adicionado relatório pedidos por status;
	Aadd(aButton,{"PRETO"	,{|| U_BFFATR07(),sfRefF() }, "Rel.Ped.Status"})

	Aadd(aButton,{"PRETO"	,{|| sfMATR260(),sfRefF() }, "Rel.Estoque"})

	Aadd(aButton,{"PRETO"	,{|| sfMATR255(),sfRefF() }, "Rel.Estoque P/Caixa"})
	

	// Adiciono botão para o cadastro de Motivos de alçadas e aprovadores por filial
	If	!lAuto
		If PswAdmin( , ,RetCodUsr()) == 0
			Aadd(aButton,{"PRETO"	,{|| 	U_BFFATA37()},"Cadastro Aprovadores"})
		Endif
		Aadd(aButton,{"PRETO"	,{|| 	U_BFFATM28(.F.) },"Processar Solicitações Diretoria"})

	Endif

	cCampo1		:= "C6_ITEM"
	cCampo2		:= "C9_SEQUEN"
	cCampo3		:= "C6_PRODUTO"
	cCampo4		:= "C6_DESCRI"
	cCampo5		:= "B2_QATU"
	cCampo6		:= "C6_QTDVEN"
	cCampo7		:= "C6_PRUNIT"
	cCampo8		:= "C6_PRCVEN"
	cCampo9		:= "C6_VALDESC"
	cCampo10 	:= "C6_DESCONT"
	cCampo11 	:= "C6_VALOR"
	cCampo12 	:= "C6_XVLRTAM"
	cCampo13 	:= "C6_XFLEX"
	cCampo15 	:= "C6_XCODTAB"
	cCampo16 	:= "C6_COMIS1"
	cCampo17 	:= "C6_COMIS2"
	cCampo18 	:= "B2_CM1"
	cCampo19 	:= "D2_VALICM"
	cCampo20 	:= "D2_VALIMP6"
	cCampo21 	:= "D2_VALIMP5"
	cCampo22 	:= "D2_VALFRE"
	cCampo23 	:= "D2_DESPESA"
	cCampo24 	:= "C6_TES"
	cCampo25 	:= "C6_CF"
	cCampo26 	:= "D2_XVALMKT"
	cCampo27 	:= "D2_XVALPAG"
	cCampo28 	:= "D2_XRETENC"
	cCampo29 	:= "D2_XCUSTO"
	cCampo30 	:= "C6_XFLEX"
	cCampo31 	:= "D2_CUSTO1"
	cCampo32 	:= "D2_PESO"
	cCampo33 	:= "D2_QUANT"
	cCampo34 	:= "D2_PRCVEN"
	cCampo35 	:= "D2_EMISSAO"
	cCampo36 	:= "C5_CONDPAG"

	// 1
	Aadd(aHeadPed		,{"Ok"					,"OK"		   		,"@BMP"     		,1					,0					,""					,				,"C"			,""				,""})

	DbSelectArea("SX3")
	DbSetOrder(2)

	// 2
	// Item

	Aadd(aHeadPed		,{Trim("Item"),GetSx3Cache(cCampo1,"X3_CAMPO"),GetSx3Cache(cCampo1,"X3_PICTURE"),GetSx3Cache(cCampo1,"X3_TAMANHO"),GetSx3Cache(cCampo1,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo1,"X3_TIPO"),GetSx3Cache(cCampo1,"X3_F3"),""})
	Private	nPxItem	:= ++nSeqC


	// 3
	// Sequencia
	//DbSeek("C9_SEQUEN")
	Aadd(aHeadPed		,{Trim("Seq."),GetSx3Cache(cCampo2,"X3_CAMPO"),GetSx3Cache(cCampo2,"X3_PICTURE"),GetSx3Cache(cCampo2,"X3_TAMANHO"),GetSx3Cache(cCampo2,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo2,"X3_TIPO"),GetSx3Cache(cCampo2,"X3_F3"),""})
	Private	nPxSequenc	:= ++nSeqC

	// 4
	// Código Produto no Protheus
	//DbSeek("C6_PRODUTO")
	Aadd(aHeadPed		,{Trim("Produto"),GetSx3Cache(cCampo3,"X3_CAMPO"),GetSx3Cache(cCampo3,"X3_PICTURE"),GetSx3Cache(cCampo3,"X3_TAMANHO"),GetSx3Cache(cCampo3,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo3,"X3_TIPO"),GetSx3Cache(cCampo3,"X3_F3"),""})
	Private nPxProd	    := ++nSeqC

	// 5
	// Descrição
	//DbSeek("C6_DESCRI")
	Aadd(aHeadPed		,{"Armazém - " + Trim("Descrição"),GetSx3Cache(cCampo4,"X3_CAMPO"),GetSx3Cache(cCampo4,"X3_PICTURE"),60,GetSx3Cache(cCampo4,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo4,"X3_TIPO"),GetSx3Cache(cCampo4,"X3_F3"),""})
	Private nPxDescri	    := ++nSeqC

	// 6
	// Status
	Aadd(aHeadPed		,{"Status"					,"STATUS"		   		,"@!"     		,20		,0		,""					,				,"C"			,""				,""})
	Private nPxStatus		:= ++nSeqC

	// 7
	// Estoque
	//DbSeek("B2_QATU")
	Aadd(aHeadPed		,{Trim("Saldo"),GetSx3Cache(cCampo5,"X3_CAMPO"),GetSx3Cache(cCampo5,"X3_PICTURE"),GetSx3Cache(cCampo5,"X3_TAMANHO"),GetSx3Cache(cCampo5,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo5,"X3_TIPO"),GetSx3Cache(cCampo5,"X3_F3"),""})
	Private nPxEstoque    := ++nSeqC

	// 8
	// Quantidade
	//DbSeek("C6_QTDVEN")
	Aadd(aHeadPed		,{Trim("Quantidade"),GetSx3Cache(cCampo6,"X3_CAMPO"),GetSx3Cache(cCampo6,"X3_PICTURE"),GetSx3Cache(cCampo6,"X3_TAMANHO"),GetSx3Cache(cCampo6,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo6,"X3_TIPO"),GetSx3Cache(cCampo6,"X3_F3"),""})
	Private nPxQtdVen	    := ++nSeqC

	// 9
	// Preço Tabela
	//DbSeek("C6_PRUNIT")
	Aadd(aHeadPed		,{Trim("Preço Tabela"),GetSx3Cache(cCampo7,"X3_CAMPO"),GetSx3Cache(cCampo7,"X3_PICTURE"),GetSx3Cache(cCampo7,"X3_TAMANHO"),GetSx3Cache(cCampo7,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo7,"X3_TIPO"),GetSx3Cache(cCampo7,"X3_F3"),""})
	Private nPxPrunit	    := ++nSeqC

	// 10
	// Preço Venda
	//DbSeek("C6_PRCVEN")
	Aadd(aHeadPed		,{Trim("Preço Venda"),GetSx3Cache(cCampo8,"X3_CAMPO"),GetSx3Cache(cCampo8,"X3_PICTURE"),GetSx3Cache(cCampo8,"X3_TAMANHO"),GetSx3Cache(cCampo8,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo8,"X3_TIPO"),GetSx3Cache(cCampo8,"X3_F3"),""})
	Private nPxPrcVen    := ++nSeqC
	Aadd(aAlter,"C6_PRCVEN")

	// 11
	// Valor Desconto
	//DbSeek("C6_VALDESC")
	Aadd(aHeadPed		,{Trim("Valor Desconto"),GetSx3Cache(cCampo9,"X3_CAMPO"),GetSx3Cache(cCampo9,"X3_PICTURE"),GetSx3Cache(cCampo9,"X3_TAMANHO"),GetSx3Cache(cCampo9,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo9,"X3_TIPO"),GetSx3Cache(cCampo9,"X3_F3"),""})
	Private nPxValDesc	:= ++nSeqC


	//DbSeek("C6_DESCONT")
	Aadd(aHeadPed		,{Trim("% Desconto"),GetSx3Cache(cCampo10,"X3_CAMPO"),GetSx3Cache(cCampo10,"X3_PICTURE"),GetSx3Cache(cCampo10,"X3_TAMANHO"),GetSx3Cache(cCampo10,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo10,"X3_TIPO"),GetSx3Cache(cCampo10,"X3_F3"),""})
	Private nPxPDesc	:= ++nSeqC

	// 12
	// Total Item
	//DbSeek("C6_VALOR")
	Aadd(aHeadPed		,{Trim("Total Item"),GetSx3Cache(cCampo11,"X3_CAMPO"),GetSx3Cache(cCampo11,"X3_PICTURE"),GetSx3Cache(cCampo11,"X3_TAMANHO"),GetSx3Cache(cCampo11,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo11,"X3_TIPO"),GetSx3Cache(cCampo11,"X3_F3"),""})
	Private nPxValor	    := ++nSeqC

	// 13
	// Valor Tampinha
	//DbSeek("C6_XVLRTAM")
	Aadd(aHeadPed		,{Trim("R$ Tampa"),GetSx3Cache(cCampo12,"X3_CAMPO"),GetSx3Cache(cCampo12,"X3_PICTURE"),GetSx3Cache(cCampo12,"X3_TAMANHO"),GetSx3Cache(cCampo12,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo12,"X3_TIPO"),GetSx3Cache(cCampo12,"X3_F3"),""})
	Private nPxValTamp  	:= ++nSeqC

	If lIsAprovador
		// 13
		// Valor Margem 1
		//DbSeek("C6_XFLEX")
		Aadd(aHeadPed		,{Trim("R$ Margem"),GetSx3Cache(cCampo13,"X3_CAMPO"),GetSx3Cache(cCampo13,"X3_PICTURE"),GetSx3Cache(cCampo13,"X3_TAMANHO"),GetSx3Cache(cCampo13,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo13,"X3_TIPO"),GetSx3Cache(cCampo13,"X3_F3"),""})
		Private nPxVMg1	:= ++nSeqC

		// 14 % Margem 1
		Aadd(aHeadPed		,{Trim("% Margem"),GetSx3Cache(cCampo13,"X3_CAMPO"),GetSx3Cache(cCampo13,"X3_PICTURE"),GetSx3Cache(cCampo13,"X3_TAMANHO"),GetSx3Cache(cCampo13,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo13,"X3_TIPO"),GetSx3Cache(cCampo13,"X3_F3"),""})
		Private nPxPMg1  := ++nSeqC

		// 15
		// Valor Margem 2
		//DbSeek("C6_XFLEX")
		Aadd(aHeadPed		,{Trim("R$ IR"),GetSx3Cache(cCampo13,"X3_CAMPO"),GetSx3Cache(cCampo13,"X3_PICTURE"),GetSx3Cache(cCampo13,"X3_TAMANHO"),GetSx3Cache(cCampo13,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo13,"X3_TIPO"),GetSx3Cache(cCampo13,"X3_F3"),""})
		Private nPxVFlex 	:= ++nSeqC

		// 16
		Aadd(aHeadPed		,{Trim("% IR"),GetSx3Cache(cCampo13,"X3_CAMPO"),GetSx3Cache(cCampo13,"X3_PICTURE"),GetSx3Cache(cCampo13,"X3_TAMANHO"),GetSx3Cache(cCampo13,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo13,"X3_TIPO"),GetSx3Cache(cCampo13,"X3_F3"),""})
		Private nPxPFlex  := ++nSeqC

		// 18
		// Código Tabela
		//DbSeek("C6_XCODTAB")
		Aadd(aHeadPed		,{Trim("Cód.Tabela"),GetSx3Cache(cCampo15,"X3_CAMPO"),GetSx3Cache(cCampo15,"X3_PICTURE"),GetSx3Cache(cCampo15,"X3_TAMANHO"),GetSx3Cache(cCampo15,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo15,"X3_TIPO"),GetSx3Cache(cCampo15,"X3_F3"),""})
		Private nPxCodTab	    := ++nSeqC

		// 19
		// Comissão
		//DbSeek("C6_COMIS1")
		Aadd(aHeadPed		,{Trim("Comissão 1"),GetSx3Cache(cCampo16,"X3_CAMPO"),"@E 999,999.99",10,2	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo16,"X3_TIPO"),GetSx3Cache(cCampo16,"X3_F3"),""})
		Private nPxComis1  	:= ++nSeqC

		// 20
		// Comissão 2
		//DbSeek("C6_COMIS2")
		Aadd(aHeadPed		,{Trim("Comissão 2"),GetSx3Cache(cCampo17,"X3_CAMPO"),"@E 999,999.99",10,2	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo17,"X3_TIPO"),GetSx3Cache(cCampo17,"X3_F3"),""})
		Private nPxComis2  	:= ++nSeqC

		// 21
		// Custo Estoque
		//DbSeek("B2_CM1")
		Aadd(aHeadPed		,{Trim("Custo Estoque"),GetSx3Cache(cCampo18,"X3_CAMPO"),GetSx3Cache(cCampo18,"X3_PICTURE"),GetSx3Cache(cCampo18,"X3_TAMANHO"),GetSx3Cache(cCampo18,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo18,"X3_TIPO"),GetSx3Cache(cCampo18,"X3_F3"),""})
		Private nPxCusto	   	:= ++nSeqC

		// 22
		// Valor ICMS
		//DbSeek("D2_VALICM")
		Aadd(aHeadPed		,{Trim("Valor ICMS"),GetSx3Cache(cCampo19,"X3_CAMPO"),GetSx3Cache(cCampo19,"X3_PICTURE"),GetSx3Cache(cCampo19,"X3_TAMANHO"),GetSx3Cache(cCampo19,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo19,"X3_TIPO"),GetSx3Cache(cCampo19,"X3_F3"),""})
		Private nPxICMS	   	:= ++nSeqC

		// 23
		//  Valor PIS
		//DbSeek("D2_VALIMP6")
		Aadd(aHeadPed		,{Trim("R$ Pis"),GetSx3Cache(cCampo20,"X3_CAMPO"),GetSx3Cache(cCampo20,"X3_PICTURE"),GetSx3Cache(cCampo20,"X3_TAMANHO"),GetSx3Cache(cCampo20,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo20,"X3_TIPO"),GetSx3Cache(cCampo20,"X3_F3"),""})
		Private nPxPIS	   	:= ++nSeqC

		// 24
		//  Valor Cofins
		//DbSeek("D2_VALIMP5")
		Aadd(aHeadPed		,{Trim("R$ Cofins"),GetSx3Cache(cCampo21,"X3_CAMPO"),GetSx3Cache(cCampo21,"X3_PICTURE"),GetSx3Cache(cCampo21,"X3_TAMANHO"),GetSx3Cache(cCampo21,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo21,"X3_TIPO"),GetSx3Cache(cCampo21,"X3_F3"),""})
		Private nPxCofins	   	:= ++nSeqC

		// 25
		//  Valor Frete
		//DbSeek("D2_VALFRE")
		Aadd(aHeadPed		,{Trim("Frete"),GetSx3Cache(cCampo22,"X3_CAMPO"),GetSx3Cache(cCampo22,"X3_PICTURE"),GetSx3Cache(cCampo22,"X3_TAMANHO"),GetSx3Cache(cCampo22,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo22,"X3_TIPO"),GetSx3Cache(cCampo22,"X3_F3"),""})
		Private nPxFrete	   	:= ++nSeqC

		// 26
		//  Valor Despesas
		//DbSeek("D2_DESPESA")
		Aadd(aHeadPed		,{Trim("Despesa"),GetSx3Cache(cCampo23,"X3_CAMPO"),GetSx3Cache(cCampo23,"X3_PICTURE"),GetSx3Cache(cCampo23,"X3_TAMANHO"),GetSx3Cache(cCampo23,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo23,"X3_TIPO"),GetSx3Cache(cCampo23,"X3_F3"),""})
		Private nPxDespesa	:= ++nSeqC

		// 27
		//  Código TES
		//DbSeek("C6_TES")
		Aadd(aHeadPed		,{Trim("TES"),GetSx3Cache(cCampo24,"X3_CAMPO"),GetSx3Cache(cCampo24,"X3_PICTURE"),GetSx3Cache(cCampo24,"X3_TAMANHO"),GetSx3Cache(cCampo24,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo24,"X3_TIPO"),"SF4",""})
		Private nPxTES		:= ++nSeqC
		Aadd(aAlter,"C6_TES")

		// 28
		//  Código CFOP
		//DbSeek("C6_CF")
		Aadd(aHeadPed		,{Trim("CFOP"),GetSx3Cache(cCampo25,"X3_CAMPO"),GetSx3Cache(cCampo25,"X3_PICTURE"),GetSx3Cache(cCampo25,"X3_TAMANHO"),GetSx3Cache(cCampo25,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo25,"X3_TIPO"),GetSx3Cache(cCampo25,"X3_F3"),""})
		Private nPxCFOP		:= ++nSeqC

		// 29
		// Valor Marketing
		//DbSeek("D2_XVALMKT")
		Aadd(aHeadPed		,{Trim("Verba"),GetSx3Cache(cCampo26,"X3_CAMPO"),GetSx3Cache(cCampo26,"X3_PICTURE"),GetSx3Cache(cCampo26,"X3_TAMANHO"),GetSx3Cache(cCampo26,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo26,"X3_TIPO"),GetSx3Cache(cCampo26,"X3_F3"),""})
		Private nPxValMkt	:= ++nSeqC

		//30
		// Valor de F&I
		//DbSeek("D2_XVALPAG")
		Aadd(aHeadPed		,{Trim("Tampinha"),GetSx3Cache(cCampo27,"X3_CAMPO"),GetSx3Cache(cCampo27,"X3_PICTURE"),GetSx3Cache(cCampo27,"X3_TAMANHO"),GetSx3Cache(cCampo27,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo27,"X3_TIPO"),GetSx3Cache(cCampo27,"X3_F3"),""})
		Private nPxValPag	:= ++nSeqC

		//31
		// Valor de Retenção
		//DbSeek("D2_XRETENC")
		Aadd(aHeadPed		,{Trim("F&I"),GetSx3Cache(cCampo28,"X3_CAMPO"),GetSx3Cache(cCampo28,"X3_PICTURE"),GetSx3Cache(cCampo28,"X3_TAMANHO"),GetSx3Cache(cCampo28,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo28,"X3_TIPO"),GetSx3Cache(cCampo28,"X3_F3"),""})
		Private nPxRetenc	:= ++nSeqC

		// 32
		// Custo Financeiro
		//DbSeek("D2_XCUSTO")
		Aadd(aHeadPed		,{Trim("Financeiro"),GetSx3Cache(cCampo29,"X3_CAMPO"),GetSx3Cache(cCampo29,"X3_PICTURE"),GetSx3Cache(cCampo29,"X3_TAMANHO"),GetSx3Cache(cCampo29,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo29,"X3_TIPO"),GetSx3Cache(cCampo29,"X3_F3"),""})
		Private nPxXCusto	:= ++nSeqC

		// 33
		// Custo adicional de Tampas
		//DbSeek("C6_XFLEX")
		Aadd(aHeadPed		,{Trim("Custo Adicional Tampas"),GetSx3Cache(cCampo30,"X3_CAMPO"),GetSx3Cache(cCampo30,"X3_PICTURE"),GetSx3Cache(cCampo30,"X3_TAMANHO"),GetSx3Cache(cCampo30,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo30,"X3_TIPO"),GetSx3Cache(cCampo30,"X3_F3"),""})
		Private nPxAddTamp 	:= ++nSeqC

		// 34
		// Custo Estoque
		//DbSeek("D2_CUSTO1")
		Aadd(aHeadPed		,{Trim("CMV1"),GetSx3Cache(cCampo31,"X3_CAMPO"),GetSx3Cache(cCampo31,"X3_PICTURE"),GetSx3Cache(cCampo31,"X3_TAMANHO"),GetSx3Cache(cCampo31,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo31,"X3_TIPO"),GetSx3Cache(cCampo31,"X3_F3"),""})
		Private nPxCm1	   	:= ++nSeqC
	Endif
	// 14 35
	//DbSeek("D2_PESO")
	Aadd(aHeadPed		,{Trim("Peso"),GetSx3Cache(cCampo32,"X3_CAMPO"),GetSx3Cache(cCampo32,"X3_PICTURE"),GetSx3Cache(cCampo32,"X3_TAMANHO"),GetSx3Cache(cCampo32,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo32,"X3_TIPO"),GetSx3Cache(cCampo32,"X3_F3"),""})
	Private nPxPeso	:= ++nSeqC

	//IAGO 25/10/2016 Chamado(16138)
	// 15 36
	//DbSeek("D2_QUANT")
	Aadd(aHeadPed		,{"Ult.Qtd",GetSx3Cache(cCampo33,"X3_CAMPO"),GetSx3Cache(cCampo33,"X3_PICTURE"),GetSx3Cache(cCampo33,"X3_TAMANHO"),GetSx3Cache(cCampo33,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo33,"X3_TIPO"),GetSx3Cache(cCampo33,"X3_F3"),""})
	Private nPxUQtd	:= ++nSeqC
	// 16 37
	//DbSeek("D2_PRCVEN")
	Aadd(aHeadPed		,{"Ult.Prc",GetSx3Cache(cCampo34,"X3_CAMPO"),GetSx3Cache(cCampo34,"X3_PICTURE"),GetSx3Cache(cCampo34,"X3_TAMANHO"),GetSx3Cache(cCampo34,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo34,"X3_TIPO"),GetSx3Cache(cCampo34,"X3_F3"),""})
	Private nPxUPrc	:= ++nSeqC
	// 17 38
	//DbSeek("D2_EMISSAO")
	Aadd(aHeadPed		,{"Ult.Data",GetSx3Cache(cCampo35,"X3_CAMPO"),GetSx3Cache(cCampo35,"X3_PICTURE"),GetSx3Cache(cCampo35,"X3_TAMANHO"),GetSx3Cache(cCampo35,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo35,"X3_TIPO"),GetSx3Cache(cCampo35,"X3_F3"),""})
	Private nPxUDat	:= ++nSeqC

	// 18 39 - 14/12/2024 Última Cond.Pgto
	Aadd(aHeadPed		,{"Ult.Cond.Pagto",GetSx3Cache(cCampo36,"X3_CAMPO"),GetSx3Cache(cCampo36,"X3_PICTURE"),GetSx3Cache(cCampo36,"X3_TAMANHO"),GetSx3Cache(cCampo36,"X3_DECIMAL")	,""/*SX3->X3_VALID*/,,GetSx3Cache(cCampo36,"X3_TIPO"),GetSx3Cache(cCampo36,"X3_F3"),""})
	Private nPxUCndPg	:= ++nSeqC
	

	//	Aadd(aAlter,"D1_COD")
	// Monto um vetor padrão para o Acols permitindo uma dinamica nas colunas
	aColsPed	:= Array(Len(aHeadPed)+1)
	For nC := 1 To Len(aHeadPed)
		aColsPed[nC]	:= IIf(aHeadPed[nc,8]=="N",0,Iif(aHeadPed[nC,8] == "D",CTOD(""),""))
	Next nC
	aColsPed[Len(aHeadPed)+1]	:= .F.

	DEFINE MSDIALOG oDlgBf TITLE OemToAnsi(cTit1) From aSize[7],0 to aSize[6],aSize[5] PIXEL

	oDlgBf:lMaximized := .T.
	// 1 Painel
	oPanel1 := TPanel():New(0,0,'',oDlgBf, oDlgBf:oFont, .T., .T.,, ,200,65,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oArqPed	:= TWBrowse():New( 	001/*<nRow>*/,;
		001/* <nCol>*/,;
		30/*<nWidth>*/,;
		110/* <nHeigth>*/,;
		/*[\{|| \{<Flds> \} \}]*/, ;
		aCabPeds,;					// 18}/*[\{<aHeaders>\}]*/,;
		aTamPeds/* [\{<aColSizes>\}]*/, ;
		oPanel1/*<oDlg>*/,;
		/* <(cField)>*/,;
		/* <uValue1>*/, ;
		/*<uValue2>*/,;
		/*[<{uChange}>]*/,;
		/*[\{|nRow,nCol,nFlags|<uLDblClick>\}]*/,;
		/*[\{|nRow,nCol,nFlags|<uRClick>\}]*/,;
		/*<oFont>*/,;
		/* <oCursor>*/,;
		/* <nClrFore>*/,;
		/* <nClrBack>*/,;
		/* <cMsg>*/,;
		/*<.update.>*/,;
		/*<cAlias>*/,;
		.T./* <.pixel.>*/,;
		/* <{uWhen}>*/,;
		/*<.design.>*/,;
		/* <{uValid}>*/,;
		/*<{uLClick}>*/,;
		/*[\{<{uAction}>\}]*/)


	oArqPed:Align := CONTROL_ALIGN_ALLCLIENT

	oArqPed:bChange := {|| Processa({|| stRefrItens() },"Aguarde carregando itens....")}

	oArqPed:bHeaderClick := { || cVarPesq := aListPed[oArqPed:nAt,3] , nColPos :=oArqPed:ColPos, lSortOrd := !lSortOrd, aSort(aListPed,,,{|x,y| Iif(lSortOrd,x[nColPos] > y[nColPos],x[nColPos] < y[nColPos]) }),sfPesquisa()}

	// 2 Painel
	oPanel2 := TPanel():New(0,0,'',oDlgBf, oDlgBf:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT
	// Painel auxiliar
	oPanel2A := TPanel():New(0,0,'',oPanel2, oDlgBf:oFont, .T., .T.,, ,200,64,.T.,.T. )
	oPanel2A:Align := CONTROL_ALIGN_TOP

	@ 003,001 Say "Tabela Cliente" Of oPanel2A Pixel
	@ 002,055 MsGet oTabCli Var cTabCli Size 100,10 noborder Of oPanel2A Pixel When .F.
	@ 015,001 Say "Transportadora" Of oPanel2A Pixel
	@ 014,055 MsGet oTransp Var cTransp Size 100,10 noborder Of oPanel2A Pixel When .F.
	@ 027,001 Say "Data Programada" Of oPanel2A Pixel
	@ 026,055 MsGet oDtProg Var dDtProg noborder Of oPanel2A Pixel When .F.
	@ 039,001 Say "Bloq.Comercial" Of oPanel2A Pixel
	@ 038,055 MsGet oBlqCom Var cBlqCom Size 100,10 noborder Of oPanel2A Pixel When .F.
	@ 003,160 Say "Endereço" Of oPanel2A Pixel
	@ 002,225 MsGet oEndCli Var cEndCli Size 250,10 noborder Of oPanel2A Pixel When .F.
	@ 015,160 Say "Mens.Interna" Of oPanel2A Pixel
	@ 014,225 MsGet oMsgInt Var cMsgInt Size 250,10 noborder Of oPanel2A Pixel When .F.
	@ 027,160 Say "Mens.Nota" Of oPanel2A Pixel
	@ 026,225 MsGet oMsgNota Var cMsgNota Size 250,10 noborder Of oPanel2A Pixel When .F.
	@ 039,160 Say "Cond.Pagamento" Of oPanel2A Pixel
	@ 038,225 MsGet oCondPag Var cCondPag Size 250,10 noborder Of oPanel2A Pixel When .F.

	@ 051,001 Say OemToAnsi("Pesquisar Pedido") SIZE 40,9 PIXEl OF oPanel2A
	@ 050,055 MsGet oPesqNf Var cVarPesq Valid sfPesquisa(.T./*lPesqManual*/) of oPanel2A pixel

	Private lCheckPen := .T.
	Private oCheckPen := TCheckBox():New(052,103,'Filtra Faturado',{|u| If(PCount()>0,lCheckPen:=u,lCheckPen) },oPanel2A,100,210,,,, {|| Processa({|| stRefrItens() },"Aguarde carregando itens....")},,,,.T.,,,)

	@ 051,160 Say "Próximo Faturamento: " of oPanel2A pixel
	@ 050,225 MSGET oDataRota Var aDadEntrega[2] noborder of oPanel2A pixel When .F.
	@ 050,265 MSGET oStsRota Var (aDadEntrega[3]+" - " + aDadEntrega[1]) Size 65,10   noborder of oPanel2A pixel  When .F.
	@ 050,330 MSGET oDiasFat Var aDadEntrega[4] Size 20,10  noborder of oPanel2A pixel When .F.

	@ 051,360 Say "Ordem Compra: " of oPanel2A pixel
	@ 050,415 MSGET oOrdemCompra Var cOrdemCompra Size 60,10 noborder of oPanel2A pixel When .F.

	// Painel para Getdados
	oPanel2B := TPanel():New(0,0,'',oPanel2, oDlgBf:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2B:Align := CONTROL_ALIGN_ALLCLIENT

	//MsGetDAuto(aAutoItens,"A410LinOk",{|| A410VldTOk(nOpc) .and. A410TudOk()},aAutoCab,aRotina[nOpc][4])

	Private oMulti := MsNewGetDados():New(000,000,0150,0250,GD_INSERT+GD_DELETE+GD_UPDATE,"AllwaysTrue()"/*cLinhaOk*/,"AllwaysTrue()"/*cTudoOk*/,,;
		aAlter,1/*nFreeze*/,10000/*nMax*/,/*cCampoOk*/,"AllwaysTrue()"/*cSuperApagar*/,/*cApagaOk*/,oPanel2B,aHeadPed,,)
	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	//ConOut("Passou automatica linha 523")

	// 3 Painel - Rodapé
	oFolder := TFolder():New(001,001,{"Totais","Follow-ups","Históricos"},{"HEADER"},oDlgBf,,,, .T., .F.,200,70)
	oFolder:Align := CONTROL_ALIGN_BOTTOM

	@ 002,001 Say "Vendido" of oFolder:aDialogs[1] pixel
	@ 001,027 MSGET oSubValores[1] Var aSubValores[1] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 012,001 Say "Residuo" of oFolder:aDialogs[1] pixel
	@ 011,027 MSGET oSubValores[2] Var aSubValores[2] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 022,001 Say "Pendente" of oFolder:aDialogs[1] pixel
	@ 021,027 MSGET oSubValores[3] Var aSubValores[3] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 032,001 Say "Alçada" of oFolder:aDialogs[1] pixel
	@ 031,027 MSGET oSubValores[4] Var aSubValores[4] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 002,080 Say "Liberado" of oFolder:aDialogs[1] pixel
	@ 001,106 MSGET oSubValores[5] Var aSubValores[5] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 012,080 Say "Blq.Estq" of oFolder:aDialogs[1] pixel
	@ 011,106 MSGET oSubValores[6] Var aSubValores[6] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 022,080 Say "Blq.Créd." of oFolder:aDialogs[1] pixel
	@ 021,106 MSGET oSubValores[7] Var aSubValores[7] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 032,080 Say "Faturado" of oFolder:aDialogs[1] pixel
	@ 031,106 MSGET oSubValores[8] Var aSubValores[8] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 002,160 Button oBtnLeg PROMPT "Leg.Pedidos" Size 45,10 Action sfLegCab(1) Of oFolder:aDialogs[1] Pixel



	@ 002,210 Say "R$ Total" of oFolder:aDialogs[1] pixel
	@ 001,236 MSGET oSubValores[9] Var aSubValores[9] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	// Somente aprovador poderá enxergar dados sobre liberação do Pedido
	If lIsAprovador

		@ 012,210 Say "R$ Custos" of oFolder:aDialogs[1] pixel
		@ 011,236 MSGET oSubValores[10] Var aSubValores[10] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.


		@ 022,210 Say "R$ IR" of oFolder:aDialogs[1] pixel
		@ 021,236 MSGET oSubValores[11] Var aSubValores[11] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 032,210 Say "% IR" of oFolder:aDialogs[1] pixel
		@ 031,236 MSGET oSubValores[12] Var aSubValores[12] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 012,290 Say "R$ Custos" of oFolder:aDialogs[1] pixel
		@ 011,316 MSGET oSubValores[14] Var aSubValores[14] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 022,290 Say "R$ Margem" of oFolder:aDialogs[1] pixel
		@ 021,316 MSGET oSubValores[15] Var aSubValores[15] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 032,290 Say "% Margem" of oFolder:aDialogs[1] pixel
		@ 031,316 MSGET oSubValores[16] Var aSubValores[16] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 002,370 Say "R$ Frete" of oFolder:aDialogs[1] pixel
		@ 001,396 MSGET oSubValores[18] Var aSubValores[18] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 012,370 Say "% Frete" of oFolder:aDialogs[1] pixel
		@ 011,396 MSGET oSubValores[19] Var aSubValores[19] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 022,370 Say "Mg1 c/Frt" of oFolder:aDialogs[1] pixel
		@ 021,396 MSGET oSubValores[20] Var aSubValores[20] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

		@ 032,370 Say "%Mg1 c/Frt" of oFolder:aDialogs[1] pixel
		@ 031,396 MSGET oSubValores[21] Var aSubValores[21] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	Endif


	@ 002,450 Say "Frete Pedido" of oFolder:aDialogs[1] pixel
	@ 011,450 MSGET oSubValores[22] Var aSubValores[22] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.

	@ 002,290 Say "Peso Kg" of oFolder:aDialogs[1] pixel
	@ 001,316 MSGET oSubValores[13] Var aSubValores[13] Picture "@E 99,999,999.99" Size 48,09 noborder of oFolder:aDialogs[1] pixel When .F.


	//@ 002,001 Say "Mens.Log" Of oFolder:aDialogs[2] Pixel
	//@ 002,027 MsGet oMsgExp Var cMsgExp Size 250,09 noborder Of oFolder:aDialogs[2] Pixel When .F.

	Private oArqLog	:= TWBrowse():New( 	001/*<nRow>*/,;
		001/* <nCol>*/,;
		30/*<nWidth>*/,;
		110/* <nHeigth>*/,;
		/*[\{|| \{<Flds> \} \}]*/, ;
		aCabLog,;					// 18}/*[\{<aHeaders>\}]*/,;
		aTamLog/* [\{<aColSizes>\}]*/, ;
		oFolder:aDialogs[2]/*<oDlg>*/,;
		/* <(cField)>*/,;
		/* <uValue1>*/, ;
		/*<uValue2>*/,;
		/*[<{uChange}>]*/,;
		{|| 	sfVerFollow()}/*[\{|nRow,nCol,nFlags|<uLDblClick>\}]*/,;
		/*[\{|nRow,nCol,nFlags|<uRClick>\}]*/,;
		/*<oFont>*/,;
		/* <oCursor>*/,;
		/* <nClrFore>*/,;
		/* <nClrBack>*/,;
		/* <cMsg>*/,;
		/*<.update.>*/,;
		/*<cAlias>*/,;
		.T./* <.pixel.>*/,;
		/* <{uWhen}>*/,;
		/*<.design.>*/,;
		/* <{uValid}>*/,;
		/*<{uLClick}>*/,;
		/*[\{<{uAction}>\}]*/)


	oArqLog:Align := CONTROL_ALIGN_ALLCLIENT

	// Monta 3 aba com informações sumarizadas do Cliente

	@ 002,001 Say "Primeira Compra" of oFolder:aDialogs[3] pixel
	@ 001,042 MSGET oHistCli[1] Var aHistCli[1] Size 48,09 noborder of oFolder:aDialogs[3] pixel When .F.

	@ 012,001 Say "Última Compra" of oFolder:aDialogs[3] pixel
	@ 011,042 MSGET oHistCli[2] Var aHistCli[2] Size 48,09 noborder of oFolder:aDialogs[3] pixel When .F.


	@ 022,001 Say "Número Compras" of oFolder:aDialogs[3] pixel
	@ 021,042 MSGET oHistCli[3] Var aHistCli[3] Size 48,09 noborder of oFolder:aDialogs[3] pixel When .F.

	@ 011,095 MSGET oHistCli[4] Var aHistCli[4] Size 30,09 noborder of oFolder:aDialogs[3] pixel When .F.
	@ 012,130 Say "Dias sem Compra" of oFolder:aDialogs[3] pixel

	//oPanel3 := TPanel():New(0,0,'',oDlgBf, oDlgBf:oFont, .T., .T.,, ,200,60,.T.,.T. )
	//oPanel3:Align := CONTROL_ALIGN_BOTTOM
	
	sfGetDados( lAuto )

	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],aSetKey[iSet,2])
	Next

	If lAuto
		// Precisa carregar os itens de maneira forçada
		stRefrItens()

		sfSendWF(lAuto,cFlgRetAlc,cInIdUser,cInMotAlcada,cInRecebe)
		//Pergunte( cPergFATA30, .F. )
		// Restaura as duas perguntas do usuário
		//U_GravaSX1(cPergFATA30,"03", Space( TAMSX3('A3_COD')[1] ) )			//	03-Vendedor de
		//U_GravaSX1(cPergFATA30,"04", Replicate('Z',TAMSX3('A3_COD')[1] ) )	//	04-Vendedor até
		//U_GravaSX1(cPergFATA30,"05", Space( TAMSX3('U7_COD')[1] ))			//	05-Operador de
		//U_GravaSX1(cPergFATA30,"06", Replicate('Z',TAMSX3('U7_COD')[1] ))	//	06-Operador até
		//U_GravaSX1(cPergFATA30,"07", nBkMvPar07 )		//	07-Pedido/Cotação			1-Pedido 2-Orçamento
		//U_GravaSX1(cPergFATA30,"08", 5 )				//	08-Restrição				1-Alçada 2-Crédito 3-Estoque/Liberado 4-Pendente 5-Todos
		//U_GravaSX1(cPergFATA30,"09", 3 )				//	09-Enviado p/ Expedição 	1-Não Enviado 2-Enviado 3-Ambos
		//U_GravaSX1(cPergFATA30,"10", cBkMvPar10 )		//	10-Num.Pedido

	Else
		Processa({|| stRefrItens() },"Aguarde carregando itens....")
	Endif

	ACTIVATE MSDIALOG oDlgBf Centered On Init (sfStartIni(lAuto,aButton))


	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],{|| })
	Next

Return

/*/{Protheus.doc} sfStartIni
Função para montagem do EnchoiceBar da tela do rotina
@type function
@version 1.0
@author Marcelo Alberto Lauschner
@since 24/09/2020
@param lAuto, logical, indica se o processo é automático
@param aButton, array, vetor com botões da rotina
/*/
Static Function sfStartIni(lAuto,aButton)

	If lAuto
		oDlgBf:End()
	Else
		EnchoiceBar(oDlgBf,{|| Processa({||sfGrava()},"Aguarde...")},{|| oDlgBf:End()},,aButton,/*nRecno*/,/*cAlias*/ ,.F./*lMashups*/,.F./*lImpCad*/,.F./*lPadrao*/,.F./*lHasOk*/,.F./*lWalkThru*/)
	Endif

Return


/*/{Protheus.doc} sfGrava
(Função do botão Confirma)
@type function
@author MarceloLauschner
@since 4/22/2014
@version 1.0
/*/
Static Function sfGrava()

	Local		lRet		:= .T.
	Local		aAreaOld	:= GetArea()

	oDlgBf:End()

	RestArea(aAreaOld)
Return lRet


/*/{Protheus.doc} sfRefF
Executa refresh da tela sem chamar a tela de perguntas
@type function
@author MarceloLauschner
@since 22/04/2014
@version 1.0
@param nOpc, numeric, opção
/*/
Static Function sfRefF(nOpc)

	Default	nOpc	:= 1

	If nOpc == 1
		Eval(bRefrXmlF)
	ElseIf nOpc == 2
		Eval(bRefrXmlT)
	Endif

Return


/*/{Protheus.doc} sfAltPedido
(Chamada para alterar pedido de Venda)
@type function
@author MarceloLauschner
@since 15/04/2014
@version 1.0
/*/
Static Function sfAltPedido()

	Local		aAreaOld	:= GetArea()
	Local		aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		iSet
	Private	ALTERA		:= .T.
	Private	INCLUI		:= .F.

	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],{|| })
	Next

	If MV_PAR07 == 1
		DbSelectArea("SC5")
		DbSetOrder(1)
		If DbSeek(xFilial("SC5")+aListPed[oArqPed:nAt,3]	)

			If Type("cCondOld") == "U"
				Public 	cCondOld	:= SC5->C5_CONDPAG
			Endif
			cCondOld	:= SC5->C5_CONDPAG

			//IAGO 06/08/2021 Projeto Estoque Avançado
			If FieldPos("C5_XESTAVC") > 0 .And. SC5->C5_XESTAVC == "S" .And. SC5->C5_TIPO == "N"
				MsgAlert("O pedido não pode ser alterado depois de integrado na ICONIC. Para alterar você deve eliminar resíduo e colocar novo pedido.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Pedido bloqueado para alteração!")
			Else
				MATA410(/*xAutoCab*/,/*xAutoItens*/,4/*nOpcAuto*/,/*lSimulacao*/,"A410Altera"/*cRotina*/,/*cCodCli*/,/*cLoja*/)
			EndIf
		Endif
	Else
		DbSelectArea("SUA")
		DbSetOrder(1)
		If DbSeek(xFilial("SUA")+aListPed[oArqPed:nAt,3]	)

			If Type("cCondOld") == "U"
				Public 	cCondOld	:= SUA->UA_CONDPG
			Endif
			cCondOld	:= SUA->UA_CONDPG

			Tk380CallCenter(	SUA->UA_CODCONT,;					//	Codigo do contato
				"SA1",;							//	Entidade (alias)
				SUA->UA_CLIENTE+SUA->UA_LOJA,;	//	Chave primaria da entidade
				SUA->(Recno()),;					//	Registro
				4,;									//	Opcao da tela de atendimento.
				Nil)
		Endif

	Endif
	
	// 18/08/2025 - A cada inclusão de outros orçamentos, chama rotina de verificação se tem orçamento com solicitação de diretoria.	
	U_BFFATM28() 
	

	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)

	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],aSetKey[iSet,2])
	Next
	RestArea(aAreaOld)
	// Executa refresh
	sfRefF(1)

Return



/*/{Protheus.doc} sfVerPedido
(Efetua Chamada para visualizar o atendimento ou pedido de venda)
@type function
@author MarceloLauschner
@since 21/04/2014
@version 1.0
/*/
Static Function sfVerPedido()

	Local		aAreaOld	:= GetArea()
	Local		aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		iSet
	Private	ALTERA		:= .F.
	Private	INCLUI		:= .F.

	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],{|| })
	Next

	If MV_PAR07 == 1
		DbSelectArea("SC5")
		DbSetOrder(1)
		If DbSeek(xFilial("SC5")+aListPed[oArqPed:nAt,3]	)
			MATA410(/*xAutoCab*/,/*xAutoItens*/,2/*nOpcAuto*/,/*lSimulacao*/,"A410Visual"/*cRotina*/,/*cCodCli*/,/*cLoja*/)
		Endif
	Else
		DbSelectArea("SUA")
		DbSetOrder(1)
		If DbSeek(xFilial("SUA")+aListPed[oArqPed:nAt,3]	)

			Tk380CallCenter(	SUA->UA_CODCONT,;					//	Codigo do contato
				"SA1",;							//	Entidade (alias)
				SUA->UA_CLIENTE+SUA->UA_LOJA,;	//	Chave primaria da entidade
				SUA->(Recno()),;					//	Registro
				2,;									//	Opcao da tela de atendimento.
				Nil)
		Endif

	Endif
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],aSetKey[iSet,2])
	Next
	RestArea(aAreaOld)

	// Executa refresh
	sfRefF(1)

Return

/*/{Protheus.doc} sfIncPedido
(Efetua a chamada para inclusão de Pedido ou Orçamento)
@type function
@author MarceloLauschner
@since 21/04/2014
@version 1.0
/*/
Static Function sfIncPedido()

	Local		aAreaOld	:= GetArea()
	Local		aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		nOpcInc		:= 0
	Local		iSet
	Local		lBkIsAprv	:= lIsAprovador
	Private	ALTERA			:= .F.
	Private	INCLUI			:= .T.

	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],{|| })
	Next

	nOpcInc := Aviso(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Escolha uma opção","Selecione uma opção",{"Faturamento","CallCenter","Cancelar"})
	If nOpcInc == 2
		Tk380CallCenter(	,;					//	Codigo do contato
			"SA1",;			//	Entidade (alias)
			"        ",;		//	Chave primaria da entidade
			,;					//	Registro
			3,;					//	Opcao da tela de atendimento.
			Nil)
		lIsAprovador	:= lBkIsAprv	// Restaura variável para evitar erro de posicionamento
	ElseIf nOpcInc == 1
		MATA410(/*xAutoCab*/,/*xAutoItens*/,3/*nOpcAuto*/,/*lSimulacao*/,"A410Inclui"/*cRotina*/,/*cCodCli*/,/*cLoja*/)
		lIsAprovador	:= lBkIsAprv	// Restaura variável para evitar erro de posicionamento
	Endif

	// 18/08/2025 - A cada inclusão de outros orçamentos, chama rotina de verificação se tem orçamento com solicitação de diretoria.	
	U_BFFATM28() 
	
	
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	For iSet := 1 To Len(aSetKey)
		SetKey(aSetKey[iSet,1],aSetKey[iSet,2])
	Next

	RestArea(aAreaOld)

	// Executa refresh
	sfRefF(1)

Return


/*/{Protheus.doc} sf450F4Con
(Consulta posição do cliente)
@type function
@author MarceloLauschner
@since 05/05/2014
@version 1.0
/*/
Static Function sf450F4Con()
	Local		aAreaOld	:= GetArea()
	Local		aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		oDlgCli
	Local		cCliF4		:= SA1->A1_COD
	Local		cLojF4		:= SA1->A1_LOJA
	Local		lOk			:= .F.
	Local		oPanelHist
	DEFINE MSDIALOG oDlgCli FROM 000,000 TO 130,400 Of oMainWnd Pixel Title OemToAnsi("Consulta Posição de Cliente" )

	oPanelHist := TPanel():New(0,0,'',oDlgCli, oDlgCli:oFont, .T., .T.,, ,200,65,.T.,.T. )
	oPanelHist:Align := CONTROL_ALIGN_ALLCLIENT

	@ 010,005 Say "Cliente/Loja" of oPanelHist Pixel
	@ 010,050 MsGet cCliF4	Size 40,10 Valid ExistCpo("SA1",cCliF4+cLojF4) F3 "SA1" Size 30,10 of oPanelHist Pixel
	@ 010,090 MsGet cLojF4	Size 40,10 Valid ExistCpo("SA1",cCliF4+cLojF4)  Size 15,10 of oPanelHist Pixel

	Activate MsDialog oDlgCli On Init EnchoiceBar(oDlgCli,{|| lOk := .T., oDlgCli:End() },{|| oDlgCli:End()},,)

	If lOk
		a450F4Con()
	Endif

	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	RestArea(aAreaOld)
Return

/*/{Protheus.doc} sfPesquisa
Função de pesquisa
@type function
@author MarceloLauschner
@since 15/04/2014
@version 1.0
@param lPesqManual, logical, (Se a pesquisa foi iniciado num get de pesquisa ou ordenação do array)
@return logical, True
/*/
Static Function sfPesquisa(lPesqManual)

	Local		lFind		:= .F.
	Local		lExistFind	:= !Empty(cVarPesq)
	Local		nQ

	Default	lPesqManual	:= .F.

	For nQ := 1 To Len(aListPed)
		If Alltrim(cVarPesq) $ aListPed[nQ,3]
			oArqPed:nAT 	:= nQ
			oArqPed:Refresh()
			lFind	:= .T.
			Exit
		Endif
	Next

	cVarPesq		:= Space(TamSX3("C6_NUM")[1])
	Eval(oArqPed:bChange)
	If lFind
		oArqPed:SetFocus()
	ElseIf lPesqManual .And. lExistFind
		oPesqNf:SetFocus()
	Endif

Return (.T.)



/*/{Protheus.doc} sfAltCabec
(Efetua chamada para alteração de cabeçalho de pedido)
@type function
@author MarceloLauschner
@since 30/05/2014
@version 1.0
/*/
Static Function sfAltCabec()


	If MV_PAR07 == 1
		// Passa o número do pedido, Valor Pendente do Pedido - para validar condição de pagamento
		U_BIG017(aListPed[oArqPed:nAt,3],aListPed[oArqPed:nAt,7])

	Endif

Return


/*/{Protheus.doc} sfSendExp
(Efetua o envio do pedido para a expedição)
@type function
@author MarceloLauschner
@since 28/10/2014
@version 1.0
/*/
Static Function sfSendExp()

	Local	cIE
	Local	cUF


	If MV_PAR07 == 1

		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+aListPed[oArqPed:nAt,3])
		If aListPed[oArqPed:nAt,12] > 0 .Or. SC5->C5_BLPED == "S"
			MsgInfo("Pedido já enviado para expedição!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Return
		Endif


		dbselectarea("SA1")
		dbsetorder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		// 19/03/2017 - Melhoria que avalia se o cliente está com o Cadastro OK na Sefaz para faturar
		cIE	:= StrTran(StrTran(StrTran(SA1->A1_INSCR,"-",""),"/",""),".","")
		cUF	:= SA1->A1_EST

		If !sfConsCad(cIE,cUF)
			Return
		Endif

		If SA1->A1_BLOQCAD $ "3#6"
			//1=Ativo;2=Inadimp/Bloq Fin;3=Faliu/Fechou;4=Posto Bandeirado;5=Nao Compra Oleos;6=Cadastro Incorreto;7=Outro Cadastro;8=Texaco
			aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_BLOQCAD', 'X3CBox()' ),,, Len(SA1->A1_BLOQCAD) )

			cTxtPad	:= 	"Cliente: "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME + CRLF
			cTxtPad += "Restrição de venda: "
			cTxtPad	+= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_BLOQCAD} ), 3 ])
			MsgAlert(cTxtPad,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" - Aviso sobre E-mail ")
			Return
		Endif
		cTxtPad	:= 	"Cliente: "+SA1->A1_COD+"/"+SA1->A1_LOJA+"-"+SA1->A1_NOME + CRLF +;
			"E-mail: "+SA1->A1_EMAIL+ CRLF +;
			IIf(SA1->(FieldPos("A1_REFCOM3"))<>0,"E-mail Antigo ou Auxiliar : "+SA1->A1_REFCOM3+CRLF,"")+;
			"Se o e-mail não for corrigido corretamente, o XML e PDF da nota fiscal deste pedido não serão enviados para o cliente!"

		If !U_GMTMKM01(SA1->A1_EMAIL/*cInEmail*/,/*cInOldEmail*/,SA1->A1_MSBLQL/*cA1MSBLQL*/,.F./*lValdAlcada*/,.T./*lExibeAlerta*/,cTxtPad)
			If !IsBlind()
				MsgAlert(cTxtPad,ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" - Aviso sobre E-mail ")
			Endif
		Endif

		// IAGO 05/04/2017 Chamado(17720)
		// Verifica se alguem está usando remanejamento estoque.
		If !U_BFCFGM23(.T.,"BFFATA45"+cEmpAnt+cFilAnt+"001","Alguém está enviando pedido exp. ou remanejando estoque.")
			If PswAdmin( , ,RetCodUsr()) == 0
				// Remove exclusividade antes de realizar processo de envio... assim não trava ninguém.
				U_BFCFGM23(.F.,"BFFATA45"+cEmpAnt+cFilAnt+"001")
			Else
				Return
			Endif
		EndIf
		// Remove exclusividade antes de realizar processo de envio... assim não trava ninguém.
		U_BFCFGM23(.F.,"BFFATA45"+cEmpAnt+cFilAnt+"001")

		If MsgYesNo("Deseja realmente enviar o pedido para expedição?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			If !lIsAprovador .And. Time() > GetNewPar("BF_FTA30HR","15:00:00")
				MsgAlert("Horário de corte excedido! Limite para envio de pedidos é até "+GetNewPar("BF_FTA30HR","15:00:00")+" hs. Somente aprovadores poderão enviar pedidos fora do horário!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			ElseIf lIsAprovador .And. Time() > GetNewPar("BF_FTA30HR","15:00:00")
				If MsgYesNo("Horário de corte excedido! Limite para envio de pedidos é até "+GetNewPar("BF_FTA30HR","15:00:00")+" hs. Deseja enviar assim mesmo?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
					U_Big005(.T./*lIsExterno*/,.T./*lInAuto*/,__cUserId/*cInIdUser*/,aListPed[oArqPed:nAt,3]/*cInNumPed*/,lIsAprovador)
					sfRefF()
				Endif
			Else
				U_Big005(.T./*lIsExterno*/,.T./*lInAuto*/,__cUserId/*cInIdUser*/,aListPed[oArqPed:nAt,3]/*cInNumPed*/,lIsAprovador)
				sfRefF()
			Endif
		Endif
	Else
		MsgInfo("Opção válida somente para Pedidos de Venda!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	Endif
Return


/*/{Protheus.doc} sfGetDados
(Localiza os dados para analise dos pedidos ou cotações)
@type function
@author MarceloLauschner
@since 15/04/2014
@version 1.0
@return logical, lDone
/*/
Static Function sfGetDados(lAuto)

	Local		aAreaOld	:= GetArea()
	Local		lRet		:= .T.
	Local		cQry		:= ""

	default lAuto := .F.

	aListPed	:= {}
	aSubValores	:= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

	if ! lAuto
	
		Pergunte(cPergFATA30,.F.)	
	
	endif
	// Se for todos os segmentos força intervalo de data
	If (MV_PAR11 == 5 .Or. !( MV_PAR03 == MV_PAR04 .Or. MV_PAR05 == MV_PAR06)) .And. MV_PAR02 - MV_PAR01 > 31
		//Pergunte(cPergFATA30,.F.)
		MV_PAR02 := MV_PAR01 + 31
		//U_GravaSX1(cPergFATA30,"02",MV_PAR01 + 31)
		//U_GravaSX1(cPergFATA30,"03",PADR(MV_PAR03,TAMSX3('A3_COD')[1],' ') )
		//U_GravaSX1(cPergFATA30,"04",PADR(MV_PAR04,TAMSX3('A3_COD')[1],' ') )
		//U_GravaSX1(cPergFATA30,"05",PADR(MV_PAR05,TAMSX3('U7_COD')[1],' ') )
		//U_GravaSX1(cPergFATA30,"06",PADR(MV_PAR06,TAMSX3('U7_COD')[1],' ') )
	Endif

	If MV_PAR07 == 1 // Pedido

		cQry += "SELECT C5_NUM PEDIDO,"
		cQry += "       C5_BLPED BLPED,"
		cQry += "       C5_EMISSAO EMISSAO,"
		cQry += "       TRIM(C5_CLIENTE + '/' + C5_LOJACLI + '-' + A1_NOME) CLIENTE,"
		cQry += "       A1_MUN CIDADE,"
		cQry += "       A1_EST ESTADO,"
		cQry += "       C5_VEND1 + '-' + TRIM(A3_NREDUZ) VENDEDOR, "
		cQry += "       A3_OPERADO + '-'+TRIM(U7_NREDUZ) OPERADOR,"
		cQry += "       A3_SUPER	SUPERVISOR,"
		cQry += "       C5_VEND3 ATIVO,"
		cQry += "       C5_MSGEXP MSGEXP,"
		cQry += "       C5_TRANSP TRANSP,"
		cQry += "       A1_CEP    CEP,"
		cQry += "       A1_ROTA   ROTA,"
		cQry += "       SUM(C6_VALOR) VALOR,"
		cQry += "       SUM(CASE WHEN C6_BLQ = 'R' THEN (C6_QTDVEN-C6_QTDENT)*C6_PRCVEN ELSE 0 END) RESIDUO,"
		cQry += "       SUM(CASE WHEN C6_BLQ = 'S' THEN (C6_QTDVEN-C6_QTDENT)*C6_PRCVEN ELSE 0 END) ALCADA,"
		cQry += "       SUM(CASE WHEN C6_BLQ != 'R' THEN (C6_QTDVEN-C6_QTDENT)*C6_PRCVEN ELSE 0 END) PENDENTE,"
		cQry += "       ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQry += "              FROM "+RetSqlName("SC9") + " C9 "
		cQry += "             WHERE C9.D_E_L_E_T_ = ' ' "
		cQry += "               AND C9_BLEST NOT IN('10','  ') "
		cQry += "               AND C9_PEDIDO = C5_NUM "
		cQry += "               AND C9_FILIAL = '"+xFilial("SC9")+"' ),0) ESTOQUE, "
		cQry += "       ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQry += "              FROM "+RetSqlName("SC9") + " C9 "
		cQry += "             WHERE C9.D_E_L_E_T_ = ' ' "
		cQry += "               AND C9_BLCRED NOT IN('10','  ') "
		cQry += "               AND C9_PEDIDO = C5_NUM "
		cQry += "               AND C9_FILIAL = '"+xFilial("SC9")+"' ),0) CREDITO, "
		cQry += "       ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN)"
		cQry += "              FROM "+RetSqlName("SC9") + " C9 "
		cQry += "             WHERE C9.D_E_L_E_T_ = ' ' "
		cQry += "               AND C9_FLGENVI = ' '"
		cQry += "               AND C9_BLCRED = '09' "
		cQry += "               AND C9_PEDIDO = C5_NUM "
		cQry += "               AND C9_FILIAL = '"+xFilial("SC9")+"' ),0) BLQREJEITADO, "
		cQry += "       ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQry += "              FROM "+RetSqlName("SC9") + " C9 "
		cQry += "             WHERE C9.D_E_L_E_T_ = ' ' "
		cQry += "               AND C9_BLEST = '  ' "
		cQry += "               AND C9_BLCRED = '  ' "
		cQry += "               AND C9_PEDIDO = C5_NUM "
		cQry += "               AND C9_FILIAL = '"+xFilial("SC9")+"' ),0) LIBERADO, "
		cQry += "       ISNULL((SELECT SUM(C9_QTDLIB*C9_PRCVEN) "
		cQry += "              FROM "+RetSqlName("SC9") + " C9 "
		cQry += "             WHERE C9.D_E_L_E_T_ = ' ' "
		cQry += "               AND C9_FLGENVI = 'E' "
		cQry += "               AND C9_BLEST = '  ' "
		cQry += "               AND C9_BLCRED = '  ' "
		cQry += "               AND C9_PEDIDO = C5_NUM "
		cQry += "               AND C9_FILIAL = '"+xFilial("SC9")+"' ),0) EXPEDICAO, "
		cQry += "       SUM(ROUND(C6_QTDENT*C6_PRCVEN,2)) FATURADO "
		cQry += "  FROM "+RetSqlName("SC5") + " C5 " 
		cQry += " INNER JOIN " + RetSqlName("SA1")+ " A1 " 
		cQry += "    ON A1.D_E_L_E_T_ =' '  "
		cQry += "   AND A1_LOJA = C5_LOJACLI "
		cQry += "   AND A1_COD = C5_CLIENTE "
		cQry += "   AND A1_FILIAL = '"+xFilial("SA1") + "' "
		cQry += " INNER JOIN " + RetSqlName("SC6")+ " C6 "
		cQry += "    ON C6.D_E_L_E_T_ =' ' "
		cQry += "   AND C6_NUM = C5_NUM "
		cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
		cQry += " INNER JOIN " + RetSqlName("SB1")+ " B1 "
		cQry += "    ON B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_COD = C6_PRODUTO "
		cQry += "   AND B1_FILIAL = '"+ xFilial("SB1") + "' "
		cQry += "  LEFT JOIN " + RetSqlName("SA3")+ " A3 "
		cQry += "    ON A3.D_E_L_E_T_ = ' ' "
		cQry += "   AND A3_COD  = C5_VEND1 "
		cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"' "
		cQry += "  LEFT JOIN " + RetSqlName("SU7")+ " U7 " 
		cQry += "    ON U7.D_E_L_E_T_ = ' ' "
		cQry += "   AND U7_COD  = A3_OPERADO "
		cQry += "   AND U7_FILIAL = '"+xFilial("SU7")+"' "

		If Empty(MV_PAR10)
			cQry += " WHERE C5_EMISSAO BETWEEN '"+ DTOS(MV_PAR01) + "' AND '"+ DTOS(MV_PAR02) + "' "
			If mv_par09 == 2
				cQry += "   AND C5_BLPED IN('S','M') "
			ElseIf mv_par09 == 1
				cQry += "   AND C5_BLPED NOT IN('S','M') "
			Endif
			cQry += "   AND ((C5_VEND1 BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"') OR (C5_VEND3 BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"' )) "

			If !Empty(MV_PAR05)
				cQry += "   AND ((A3_OPERADO BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"') "				
				// IAGO 03/07/2015 Adicionado novo campo Assessor
				If !Empty(MV_PAR12)
					cQry += "  OR A3_OPERADO = '"+MV_PAR12+"') "					
				Else
					cQry += ") "
				EndIf
			Endif

			

			If lIsAprovador .And. MV_PAR08 == 1 // Se for somente aprovadores e com filtro de pedidos presos por alçadas
				cQry += "   AND (( SELECT COUNT(ZS_MOTIVO) "
				cQry += "            FROM "+RetSqlName("SZS") + " ZS, "+RetSqlName("SC6") + " C6B, "+ RetSqlName("SB1") + " B1B "
				cQry += "           WHERE ZS.D_E_L_E_T_ = ' ' "
				cQry += "             AND C6B.D_E_L_E_T_ = ' ' "
				cQry += "             AND C6B.C6_NUM = C5_NUM "
				cQry += "             AND C6B.C6_FILIAL = '" + xFilial("SC6")+ "' "
				cQry += "             AND B1B.D_E_L_E_T_ = ' ' "
				cQry += "             AND B1B.B1_COD = C6B.C6_PRODUTO "
				cQry += "             AND B1B.B1_FILIAL = '" + xFilial("SB1") + "' "
				//cQry += "             AND ZS_CODFORN = B1B.B1_PROC "
				//cQry += "             AND ZS_LOJAFOR = B1B.B1_LOJPROC "
				cQry += "             AND C6_XALCADA != ' '  " // Pendente
				cQry += "             AND ZS_TIPPROD = B1B.B1_CABO " // TEX/ROC/HOU/OUT/MIC/LUS
				cQry += "             AND CHARINDEX(ZS_MOTIVO,C6B.C6_XALCADA) > 0  "
				cQry += "             AND ZS_IDUSR1 = '"+RetCodUsr()+"' "	// Usuário logado no Sistema
				cQry += "             AND ZS_FILIAL = '"+xFilial("SZS")+"' ) > 0 "
				cQry += "   OR ( SELECT COUNT(ZS_MOTIVO) "
				cQry += "          FROM "+RetSqlName("SZS") + " ZS, "+RetSqlName("SC6") + " C6B "
				cQry += "         WHERE ZS.D_E_L_E_T_ = ' ' "
				cQry += "           AND C6B.D_E_L_E_T_ = ' ' "
				cQry += "           AND C6B.C6_NUM = C5_NUM "
				cQry += "           AND C6B.C6_FILIAL = '" + xFilial("SC6")+ "' "
				//cQry += "           AND ZS_CODFORN = ' ' "
				//cQry += "           AND ZS_LOJAFOR = ' ' "
				cQry += "           AND C6_XALCADA != ' '  " // Pendente
				cQry += "           AND ZS_TIPPROD = ' ' " // TEX/ROC/HOU/OUT/MIC/LUS
				cQry += "           AND CHARINDEX(ZS_MOTIVO,C6B.C6_XALCADA) > 0  "
				cQry += "           AND ZS_IDUSR1 = '"+RetCodUsr()+"' "	// Usuário logado no Sistema
				cQry += "           AND ZS_FILIAL = '"+xFilial("SZS")+"' ) > 0)"
			Endif

			If mv_par11 <= 4
				cQry += "   AND (SELECT COUNT(C6_PRODUTO) "
				cQry += "          FROM "+RetSqlName("SC6") + " C6B, "+ RetSqlName("SB1") + " B1B "
				cQry += "         WHERE C6B.D_E_L_E_T_ = ' ' "
				cQry += "           AND C6_NUM = C5_NUM "
				cQry += "           AND C6_FILIAL = '" + xFilial("SC6")+ "' "
				cQry += "           AND B1B.D_E_L_E_T_ = ' ' "
				cQry += "           AND B1_COD = C6_PRODUTO "

				If mv_par11 == 1 // Texaco/Outros
					cQry += "        AND B1_PROC NOT IN('000473','000475','000449','000455','002334')"
					cQry += "	     AND B1_CABO NOT IN('MIC','MOT','CON','REL','AGR','BIK') "
					cQry += "        AND B1_GRUPO NOT IN('CARC') "
				ElseIf mv_par11 == 2 //  Michelin
					cQry += "	      AND B1_CABO IN ('MIC')"
				ElseIf mv_par11 == 3 // Wynns
					cQry += "	      AND B1_PROC IN('000449','000455','002334')"
				ElseIf mv_par11 == 4 //  Carcare ou 2R
					cQry += "	      AND (B1_GRUPO = 'CARC' OR B1_CABO IN('MOT','CON','REL','AGR','BIK') )"
				Endif
				cQry += "           AND B1_FILIAL = '"+xFilial("SB1")+"') > 0 "
			Endif
		Else
			cQry += " WHERE C5_NUM = '"+ MV_PAR10 + "' "
		Endif

		cQry += "   AND C5.D_E_L_E_T_ =' ' "
		cQry += "   AND C5_TIPO NOT IN('B','D','C','I') "
		cQry += "   AND C5_FILIAL = '"+xFilial("SC5")+ "' "
		cQry += " GROUP BY C5_NUM,C5_EMISSAO,C5_CLIENTE,C5_LOJACLI,C5_TRANSP,A1_NOME,A1_MUN,A1_EST,A1_CEP,A1_ROTA,C5_VEND1,A3_OPERADO,A3_SUPER,U7_NREDUZ,A3_NREDUZ,C5_BLPED,C5_MSGEXP,C5_VEND3 "
		cQry += " ORDER BY C5_NUM DESC "
	Else
		cQry += "SELECT UA_NUM PEDIDO,"
		cQry += "       ' ' BLPED,"
		cQry += "       UA_EMISSAO EMISSAO,"
		cQry += "       TRIM(UA_CLIENTE+'/'+UA_LOJA+'-'+A1_NOME) CLIENTE,"
		cQry += "       A1_MUN CIDADE,"
		cQry += "       A1_EST ESTADO,"
		cQry += "       UA_VEND + '-' + TRIM(A3_NREDUZ) VENDEDOR, "
		cQry += "       A3_OPERADO + '-'+TRIM(U7_NREDUZ) OPERADOR,"
		cQry += "       A3_SUPER	SUPERVISOR,"
		cQry += "       ' ' MSGEXP,"
		cQry += "       UA_TRANSP TRANSP,"
		cQry += "       A1_CEP    CEP,"
		cQry += "       A1_ROTA   ROTA,"
		cQry += "       ' ' ATIVO,"
		cQry += "       SUM(UB_VLRITEM) VALOR,"
		cQry += "       SUM(0) RESIDUO,"
		cQry += "       SUM(0) ALCADA,"
		cQry += "       SUM(0) PENDENTE,"
		cQry += "       SUM(0) ESTOQUE, "
		cQry += "       SUM(0) CREDITO, "
		cQry += "       SUM(0) BLQREJEITADO, "
		cQry += "       SUM(0) LIBERADO, "
		cQry += "       SUM(0) EXPEDICAO,"
		cQry += "       SUM(0) FATURADO "
		cQry += "  FROM "+RetSqlName("SUA") + " UA " 
		cQry += " INNER JOIN " + RetSqlName("SA1")+ " A1 " 
		cQry += "    ON A1.D_E_L_E_T_ =' '  "
		cQry += "   AND A1_LOJA = UA_LOJA "
		cQry += "   AND A1_COD = UA_CLIENTE "
		cQry += "   AND A1_FILIAL = '"+xFilial("SA1") + "' "
		cQry += " INNER JOIN " + RetSqlName("SUB")+ " UB "
		cQry += "    ON UB.D_E_L_E_T_ =' ' "
		cQry += "   AND UB_NUM = UA_NUM "
		cQry += "   AND UB_FILIAL = '"+xFilial("SUB")+"' "
		cQry += "  LEFT JOIN " + RetSqlName("SA3")+ " A3 "
		cQry += "    ON A3.D_E_L_E_T_ = ' ' "
		cQry += "   AND A3_COD = UA_VEND "
		cQry += "   AND A3_FILIAL = '"+xFilial("SA3")+"' "
		cQry += "  LEFT JOIN " + RetSqlName("SU7")+ " U7 "
		cQry += "    ON U7.D_E_L_E_T_ = ' ' "
		cQry += "   AND U7_COD = A3_OPERADO "
		cQry += "   AND U7_FILIAL = '"+xFilial("SU7")+"' "
		cQry += " WHERE UA.D_E_L_E_T_ =' ' "
		// Se houver número especifico, ignora filtros de Assessora/Vendedor/Data
		If !Empty(MV_PAR10)
			cQry += "   AND UA_NUM = '"+ MV_PAR10 + "' "
		Else
			If !Empty(MV_PAR05)
				cQry += "   AND ((A3_OPERADO BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"') "
				
				// IAGO 03/07/2015 Adicionado novo campo Assessor
				If !Empty(MV_PAR12)
					cQry += "  OR A3_OPERADO = '"+MV_PAR12+"' )
				Else
					cQry += ") "
				EndIf
			Endif

			cQry += "   AND UA_EMISSAO BETWEEN '"+ DTOS(MV_PAR01) + "' AND '"+ DTOS(MV_PAR02) + "' "
			cQry += "   AND (UA_VEND BETWEEN '"+MV_PAR03+"' AND '"+MV_PAR04+"') "

			If lIsAprovador .And. MV_PAR08 == 1 // Se for somente aprovadores e com filtro de pedidos presos por alçadas
				cQry += "   AND (( SELECT COUNT(ZS_MOTIVO) "
				cQry += "            FROM "+RetSqlName("SZS") + " ZS, "+RetSqlName("SUB") + " UBB, "+ RetSqlName("SB1") + " B1B "
				cQry += "           WHERE ZS.D_E_L_E_T_ = ' ' "
				cQry += "             AND UBB.D_E_L_E_T_ = ' ' "
				cQry += "             AND UBB.UB_NUM = UA_NUM "
				cQry += "             AND UBB.UB_FILIAL = '" + xFilial("SUB")+ "' "
				cQry += "             AND B1B.D_E_L_E_T_ = ' ' "
				cQry += "             AND B1B.B1_COD = UBB.UB_PRODUTO "
				cQry += "             AND B1B.B1_FILIAL = '" + xFilial("SB1") + "' "
				//cQry += "             AND ZS_CODFORN = B1B.B1_PROC "
				//cQry += "             AND ZS_LOJAFOR = B1B.B1_LOJPROC "
				cQry += "             AND UB_XALCADA != ' '  " // Pendente
				cQry += "             AND ZS_TIPPROD = B1B.B1_CABO " // TEX/ROC/HOU/OUT/MIC/LUS
				cQry += "             AND CHARINDEX(ZS_MOTIVO,UBB.UB_XALCADA) > 0  "
				cQry += "             AND ZS_IDUSR1 = '"+RetCodUsr()+"' "	// Usuário logado no Sistema
				cQry += "             AND ZS_FILIAL = '"+xFilial("SZS")+"' ) > 0 "
				cQry += "   OR ( SELECT COUNT(ZS_MOTIVO) "
				cQry += "          FROM "+RetSqlName("SZS") + " ZS, "+RetSqlName("SUB") + " UBB "
				cQry += "         WHERE ZS.D_E_L_E_T_ = ' ' "
				cQry += "           AND UBB.D_E_L_E_T_ = ' ' "
				cQry += "           AND UBB.UB_NUM = UA_NUM "
				cQry += "           AND UBB.UB_FILIAL = '" + xFilial("SUB")+ "' "
				//cQry += "           AND ZS_CODFORN = ' ' "
				//cQry += "           AND ZS_LOJAFOR = ' ' "
				cQry += "           AND UB_XALCADA != ' '  " // Pendente
				cQry += "           AND ZS_TIPPROD = ' ' " // TEX/ROC/HOU/OUT/MIC/LUS
				cQry += "           AND CHARINDEX(ZS_MOTIVO,UBB.UB_XALCADA) > 0  "
				cQry += "           AND ZS_IDUSR1 = '"+RetCodUsr()+"' "	// Usuário logado no Sistema
				cQry += "           AND ZS_FILIAL = '"+xFilial("SZS")+"' ) > 0)"
			Endif

			If mv_par11 <= 4

				cQry += "   AND (SELECT COUNT(UB_PRODUTO) "
				cQry += "          FROM "+RetSqlName("SUB") + " UBB, "+ RetSqlName("SB1") + " B1B "
				cQry += "         WHERE UBB.D_E_L_E_T_ = ' ' "
				cQry += "           AND UB_NUM = UA_NUM "
				cQry += "           AND UB_FILIAL = '" + xFilial("SUB")+ "' "
				cQry += "           AND B1B.D_E_L_E_T_ = ' ' "
				cQry += "           AND B1_COD = UB_PRODUTO "

				If mv_par11 == 1 // Texaco/Outros
					cQry += "        AND B1_PROC NOT IN('000473','000475','000449','000455','002334')"
					cQry += "	     AND B1_CABO NOT IN('MIC','MOT','CON','REL','AGR','BIK') "
					cQry += "	     AND B1_GRUPO NOT IN('CARC') "
				ElseIf mv_par11 == 2 //  Michelin
					cQry += "	      AND B1_CABO IN('MIC') "
				ElseIf mv_par11 == 3 // Wynns
					cQry += "	      AND B1_PROC IN('000449','000455','002334')"
				ElseIf mv_par11 == 4 //  Carcare
					cQry += "	      AND (B1_GRUPO = 'CARC' OR B1_CABO IN('MOT','CON','REL','AGR','BIK'))"
				Endif
				cQry += "           AND B1_FILIAL = '"+xFilial("SB1")+"') > 0 "
			Endif

		Endif
		cQry += "   AND UA_OPER = '2' " // 2=Orçamento
		cQry += "   AND UA_PROSPEC = 'F' " // Somente para cliente
		cQry += "   AND UA_FILIAL = '"+xFilial("SUA")+ "' "
		cQry += " GROUP BY UA_NUM,UA_EMISSAO,UA_CLIENTE,UA_LOJA,UA_TRANSP,A1_NOME,A1_MUN,A1_EST,A1_CEP,A1_ROTA,UA_VEND,A3_OPERADO,A3_SUPER,U7_NREDUZ,A3_NREDUZ "
		cQry += " ORDER BY UA_NUM DESC "

	Endif

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSC5', .F., .T.)

	TcSetField("QSC5","EMISSAO","D")

	While !Eof()

		If Empty(MV_PAR10) .And. MV_PAR07 == 1 .And. MV_PAR08 == 1	// Restrição por Alçada
			If QSC5->ALCADA == 0
				DbSelectArea("QSC5")
				DbSkip()
				Loop
			Endif
		ElseIf Empty(MV_PAR10) .And. MV_PAR07 == 1 .And. MV_PAR08 == 2 // Restrição por Crédito
			If QSC5->CREDITO == 0
				DbSelectArea("QSC5")
				DbSkip()
				Loop
			Endif

		ElseIf Empty(MV_PAR10) .And. MV_PAR07 == 1 .And. MV_PAR08 == 3 // Restrição por Estoque Ou Liberado
			If (QSC5->ESTOQUE == 0 .And.  QSC5->LIBERADO == 0) .Or. QSC5->CREDITO > 0 .Or. QSC5->ALCADA > 0
				DbSelectArea("QSC5")
				DbSkip()
				Loop
			Endif
		ElseIf Empty(MV_PAR10) .And. MV_PAR07 == 1 .And. MV_PAR08 == 4 // Pendente
			If QSC5->PENDENTE == 0
				DbSelectArea("QSC5")
				DbSkip()
				Loop
			Endif
		Endif

		If MV_PAR13 == 2 // Somente rota no dia
			aDadEntrega	:= sfCalcRota(QSC5->TRANSP,QSC5->CEP,QSC5->ROTA)
			If aDadEntrega[2] <> dDataBase
				//{cStsRota,dData,cDiasFat,cPrzEnt}
				DbSelectArea("QSC5")
				DbSkip()
				Loop
			Endif
		ElseIf MV_PAR13 == 3 // Somente rota no dia
			aDadEntrega	:= sfCalcRota(QSC5->TRANSP,QSC5->CEP,QSC5->ROTA)
			If aDadEntrega[2] == dDataBase
				//{cStsRota,dData,cDiasFat,cPrzEnt}
				DbSelectArea("QSC5")
				DbSkip()
				Loop
			Endif
		Endif
		nStatus	:= 0

		If QSC5->BLPED == 'F' .And. QSC5->PENDENTE > 0
			nStatus 	:= 10
		ElseIf QSC5->FATURADO == QSC5->VALOR
			nStatus 	:= 1
		ElseIf QSC5->ALCADA > 0
			nStatus	:= 2
		ElseIf QSC5->BLQREJEITADO > 0
			nStatus	:= 5
		ElseIf QSC5->RESIDUO > 0
			nStatus	:= 6
		ElseIf QSC5->CREDITO > 0 .And. QSC5->BLPED == "P"
			nStatus	:= 7
		ElseIf QSC5->CREDITO > 0 .And. QSC5->BLPED == "T"
			nStatus	:= 8
		ElseIf QSC5->CREDITO > 0
			nStatus	:= 3
		ElseIf QSC5->ESTOQUE > 0
			nStatus	:= 4
		ElseIf QSC5->PENDENTE == QSC5->VALOR .And. QSC5->ALCADA <= 0 .And. (QSC5->LIBERADO + QSC5->ESTOQUE + QSC5->CREDITO ) < QSC5->VALOR
			nStatus 	:= 9
		ElseIf QSC5->PENDENTE == QSC5->VALOR .And. QSC5->LIBERADO <= 0
			nStatus 	:= 9
		Endif

		aSubValores[1] += QSC5->VALOR
		oSubValores[1]:Refresh()
		aSubValores[2] += QSC5->RESIDUO
		oSubValores[2]:Refresh()
		aSubValores[3] += QSC5->PENDENTE
		oSubValores[3]:Refresh()
		aSubValores[4] += QSC5->ALCADA
		oSubValores[4]:Refresh()
		aSubValores[5] += QSC5->LIBERADO
		oSubValores[5]:Refresh()
		aSubValores[6] += QSC5->ESTOQUE
		oSubValores[6]:Refresh()
		aSubValores[7] += QSC5->CREDITO
		oSubValores[7]:Refresh()
		aSubValores[8] += QSC5->FATURADO
		oSubValores[8]:Refresh()

		Aadd(aListPed,{nStatus,;					//	1
			Iif(MV_PAR07==1,"Pedido","Orçamento"),;	//2
			QSC5->PEDIDO,;			//	3
			QSC5->EMISSAO,;			//	4
			QSC5->VALOR,;			//	5
			QSC5->RESIDUO,;			//	6
			QSC5->PENDENTE,;		//	7
			QSC5->ALCADA,;			//	8
			QSC5->LIBERADO,;		//	9
			QSC5->ESTOQUE,;			//	10
			QSC5->CREDITO,;			//	11
			QSC5->EXPEDICAO,;		//	12
			QSC5->FATURADO,;		//	13
			Alltrim(QSC5->CLIENTE),;//	14
			Alltrim(QSC5->CIDADE),;	//	15
			QSC5->ESTADO,;			//	16
			QSC5->VENDEDOR,;		//	17
			QSC5->SUPERVISOR,;		//	18
			QSC5->OPERADOR,;		//	19
			QSC5->ATIVO,;			//	20
			QSC5->MSGEXP})			// 	21


		DbSelectArea("QSC5")
		DbSkip()
	Enddo
	QSC5->(DbCloseArea())

	If Len(aListPed) == 0
		aListPed	:= {{0,"","",CTOD(""),0,0,0,0,0,0,0,0,0,"","","","","","","",""}}
	Endif

	If oArqPed:nAt > Len(aListPed)
		oArqPed:nAt	:= Len(aListPed)
	Endif

	oArqPed:SetArray(aListPed)
	oArqPed:bLine:= { || {sfLegenda(),;
		aListPed[oArqPed:nAT,2],;
		aListPed[oArqPed:nAT,3],;
		aListPed[oArqPed:nAT,4],;
		Transform(aListPed[oArqPed:nAT,5],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,6],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,7],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,8],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,9],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,10],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,11],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,12],"@E 9,999,999.99"),;
		Transform(aListPed[oArqPed:nAT,13],"@E 9,999,999.99"),;
		aListPed[oArqPed:nAT,14],;
		aListPed[oArqPed:nAT,15],;
		aListPed[oArqPed:nAT,16],;
		aListPed[oArqPed:nAT,17],;
		aListPed[oArqPed:nAT,18],;
		aListPed[oArqPed:nAT,19],;
		aListPed[oArqPed:nAt,20],;
		aListPed[oArqPed:nAt,21]} }
	oArqPed:Refresh()

	RestArea(aAreaOld)


Return lRet



/*/{Protheus.doc} sfSC5Impostos
(long_description)
@author MarceloLauschner
@since 21/04/2014
@version 1.0
@param cNumPed, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSC5Impostos(cNumPed)

	Local		cValid
	Local		nPosIni
	Local		nLen
	Local		cReferencia
	Local		aFisGet
	Local		aFisGetSC5
	Local		nValMerc	:= 0
	Local		nPrcLista	:= 0
	Local		nAcresUnit	:= 0
	Local		nAcresFin	:= 0
	Local		nDesconto	:= 0
	Local		nItemFis	:= 0
	Local		aAreaOld	:= GetArea()
	Local		aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		nY,iZ,nX
	Local 		aFields		:= {}
	Default	cNumPed	:=  aListPed[oArqPed:nAt,3]

	aSubValores[9]	:= 0
	aSubValores[10]	:= 0
	aSubValores[11]	:= 0
	aSubValores[12]	:= 0
	aSubValores[13]	:= 0
	aSubValores[14]	:= 0
	aSubValores[15]	:= 0
	aSubValores[16]	:= 0
	aSubValores[17]	:= 0
	aSubValores[18]	:= 0
	aSubValores[19]	:= 0
	aSubValores[20]	:= 0
	aSubValores[21]	:= 0
	aSubValores[22] := 0

	aFisGet	:= {}
	
	aFields := FWSX3Util():GetAllFields("SC6", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cValid := UPPER(GetSx3Cache(cCampo,"X3_VALID")+GetSx3Cache(cCampo,"X3_VLDUSER"))

		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGet,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGet,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf


	Next nX


	aSort(aFisGet,,,{|x,y| x[3]<y[3]})

	aFisGetSC5	:= {}
	
	aFields := {}
	aFields := FWSX3Util():GetAllFields("SC5", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cValid := UPPER(GetSx3Cache(cCampo,"X3_VALID")+GetSx3Cache(cCampo,"X3_VLDUSER"))

		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf

	Next nX

	aSort(aFisGetSC5,,,{|x,y| x[3]<y[3]})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicializa a funcao fiscal                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cNumPed)

	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+SC5->C5_VEND1)

	nPCusFixo		:= U_BFFATM02(cEmpAnt)
	
	MaFisSave()
	MaFisEnd()

	MaFisIni(	Iif(Empty(SC5->C5_CLIENT),SC5->C5_CLIENTE,SC5->C5_CLIENT),;	// 1-Codigo Cliente/Fornecedor
		SC5->C5_LOJAENT,;								// 2-Loja do Cliente/Fornecedor
		IIf(SC5->C5_TIPO$'DB',"F","C"),;			// 3-C:Cliente , F:Fornecedor
		SC5->C5_TIPO,;								// 4-Tipo da NF
		SC5->C5_TIPOCLI,;								// 5-Tipo do Cliente/Fornecedor
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		"MATA461",;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		Nil,;
		{"",""})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Realiza alteracoes de referencias do SC5         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aFisGetSC5) > 0
		dbSelectArea("SC5")
		For nY := 1 to Len(aFisGetSC5)
			If !Empty(&("SC5->"+Alltrim(aFisGetSC5[ny][2])))
				MaFisAlt(aFisGetSC5[ny][1],&("SC5->"+Alltrim(aFisGetSC5[ny][2])),,.F.)
			EndIf
		Next nY
	Endif


	// Efetua um primeiro laço para atualizar dados para calculo do frete
	For iZ := 1 To Len(oMulti:aCols)

		If !oMulti:aCols[iZ,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[iZ,nPxItem])
			aSubValores[13] += oMulti:aCols[iZ,nPxPeso]
		Endif

	Next
	// Se estiver setado no pedido que não tem frete por que cliente retira, deduz o custo do transporte da margem
	If !SC5->C5_TPFRETE $ "S#F" 	// Sem frete/FOB
		aSubValores[18] := U_BFFATM22(SC5->C5_EMISSAO/*dInData*/,SC5->C5_CLIENTE/*cInCodCli*/,SC5->C5_LOJACLI/*cInLojCli*/,SC5->C5_TRANSP/*cInTransp*/,aListPed[oArqPed:nAt,7]+Iif(!lCheckPen,aListPed[oArqPed:nAt,13],0)/*nInVlrMerc*/,aSubValores[13]/*nInPeso*/,SC5->C5_FRETE/*nInVlrFrete*/)
	Endif

	

	For iZ := 1 To Len(oMulti:aCols)

		If !oMulti:aCols[iZ,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[iZ,nPxItem])



			DbSelectArea("SF4")
			SF4->(dbSetOrder(1))
			SF4->(DbSeek(xFilial("SF4")+oMulti:aCols[iZ,nPxTES]))

			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+oMulti:aCols[iZ,nPxProd])
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Calcula o preco de lista                     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			nValMerc  := (oMulti:aCols[iZ,nPxQtdVen])*oMulti:aCols[iZ,nPxPrcVen]
			nPrcLista := oMulti:aCols[iZ,nPxPrunit]

			nAcresUnit:= A410Arred(oMulti:aCols[iZ,nPxPrcVen]*SC5->C5_ACRSFIN/100,"D2_PRCVEN")
			nAcresFin := A410Arred(oMulti:aCols[iZ,nPxQtdVen]*nAcresUnit,"D2_TOTAL")
			nValMerc  += nAcresFin
			nDesconto := a410Arred(nPrcLista*oMulti:aCols[iZ,nPxQtdVen],"D2_DESCON")-nValMerc
			nDesconto := IIf(nDesconto<=0,oMulti:aCols[iZ,nPxValDesc],nDesconto)
			nDesconto := Max(0,nDesconto)
			nPrcLista += nAcresUnit
			//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
			If cPaisLoc=="BRA" .or. GetNewPar('MV_DESCSAI','1') == "2"
				nValMerc  += nDesconto
			Endif

			nItemFis++
			MaFisAdd(	SB1->B1_COD,;  			// 1-Codigo do Produto ( Obrigatorio )
				oMulti:aCols[iZ,nPxTES],;			// 2-Codigo do TES ( Opcional )
				oMulti:aCols[iZ,nPxQtdVen],; 		// 3-Quantidade ( Obrigatorio )
				oMulti:aCols[iZ,nPxPrunit],;		// 4-Preco Unitario ( Obrigatorio )
				nDesconto,;	 						// 5-Valor do Desconto ( Opcional )
				"",;	   							// 6-Numero da NF Original ( Devolucao/Benef )
				"",;								// 7-Serie da NF Original ( Devolucao/Benef )
				0,;									// 8-RecNo da NF Original no arq SD1/SD2
				0,;									// 9-Valor do Frete do Item ( Opcional )
				0,;									// 10-Valor da Despesa do item ( Opcional )
				0,;									// 11-Valor do Seguro do item ( Opcional )
				0,;									// 12-Valor do Frete Autonomo ( Opcional )
				nValMerc,;							// 13-Valor da Mercadoria ( Obrigatorio )
				0,;									// 14-Valor da Embalagem ( Opiconal )
				,;									// 15
				,;									// 16
				oMulti:aCols[iZ,nPxItem],; 			// 17
				0,;									// 18-Despesas nao tributadas - Portugal
				0,;									// 19-Tara - Portugal
				oMulti:aCols[iZ,nPxCFOP],; 			// 20-CFO
				{},;	           					// 21-Array para o calculo do IVA Ajustado (opcional)
				"")
			oMulti:aCols[iZ,nPxPIS]		:= MaFisRet(nItemFis,"IT_VALPS2")
			oMulti:aCols[iZ,nPxCofins]	:= MaFisRet(nItemFis,"IT_VALCF2")
			oMulti:aCols[iZ,nPxICMS]	:= MaFisRet(nItemFis,"IT_VALICM")
			// Chamado 17927 - Agregar o valor do ICMS Complementar e o Diferencial de Aliquota(DIFAL) no valor do ICMS como custo para cálculo de margem
			oMulti:aCols[iZ,nPxICMS]	+= MaFisRet(nItemFis,"IT_VALCMP") + MaFisRet(nItemFis,"IT_DIFAL")

			oMulti:aCols[iZ,nPxDespesa]	:= (nPCusFixo * (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) / 100)//MaFisRet(nItemFis,"IT_DESPESA")
			oMulti:aCols[iZ,nPxFrete]	:= Round(aSubValores[18]*(oMulti:aCols[iZ,nPxValor]/(aListPed[oArqPed:nAt,7]+Iif(!lCheckPen,aListPed[oArqPed:nAt,13],0))),2)	//MaFisRet(nItemFis,"IT_FRETE")
			oMulti:aCols[iZ,nPxXCusto]	:= Iif(SF4->F4_DUPLIC =="S",Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * ((1.00066030548229^nPrzMed)-1),2),0)

			oMulti:aCols[iZ,nPxComis1]	:=	Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * oMulti:aCols[iZ,nPxComis1] / 100,2)
			oMulti:aCols[iZ,nPxComis2]	:=	Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * oMulti:aCols[iZ,nPxComis2] / 100,2)

			// Função padrão para calculo do F&I e Verba Marketing
			aRetTmka08	:= U_BFTMKA08(SC5->C5_CLIENTE,SC5->C5_LOJACLI,oMulti:aCols[iZ,nPxProd])
			nPercFI		:= aRetTmka08[1]
			nPercMKT	:= aRetTmka08[2]
			nPercRet	:= aRetTmka08[3]

			//Verifica se há percentual de F&I cadastrada para o clienteXgrupo
			oMulti:aCols[iZ,nPxValPag]	:= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * nPercFI / 100,2)

			//Verifica se há percentual de verba de marketing cadastrada para o clienteXgrupo
			oMulti:aCols[iZ,nPxValMkt]	:= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * nPercMKT / 100,2)

			//Verifica se há percentual de Retenção cadastrada para o clienteXgrupo
			oMulti:aCols[iZ,nPxRetenc]	:= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * nPercRet / 100,2)


			If SF4->F4_DUPLIC =="S"
				oMulti:aCols[iZ,nPxVFlex]	:= (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])+MaFisRet(nItemFis,"IT_FRETE")+MaFisRet(nItemFis,"IT_DESPESA")
				oMulti:aCols[iZ,nPxVMg1]	:= (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])+MaFisRet(nItemFis,"IT_FRETE")+MaFisRet(nItemFis,"IT_DESPESA")

				// Subtraio somente valores que estão envolvidos quando houver geração de contas a receber
				If cFlgRetAlc <> "D"
					// Comissão 1
					oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxComis1]
					aSubValores[10] += oMulti:aCols[iZ,nPxComis1]

					// Comissão 2
					oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxComis2]
					aSubValores[10] += oMulti:aCols[iZ,nPxComis2]
				Endif

				// Custo do financeiro prazo médio
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxXCusto]
				aSubValores[10] += oMulti:aCols[iZ,nPxXCusto]

				// Custo administrativo
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxDespesa]
				aSubValores[10] += oMulti:aCols[iZ,nPxDespesa]

				// Soma o valor somente de Receitas - Valor é obtido pelo retorno da MatxFis
				//aSubValores[17] += (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])

			Endif
			// Valor PIS
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxPIS]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxPIS]
			aSubValores[10] += oMulti:aCols[iZ,nPxPIS]
			aSubValores[14] += oMulti:aCols[iZ,nPxPIS]

			// Valor Custo Estoque
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,Iif( cFlgRetAlc == "D",nPxCM1,nPxCusto)]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxCusto]
			aSubValores[10] += oMulti:aCols[iZ,Iif( cFlgRetAlc == "D",nPxCM1,nPxCusto)]
			aSubValores[14] += oMulti:aCols[iZ,nPxCusto]

			// Valor Cofins
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxCofins]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxCofins]
			aSubValores[10] += oMulti:aCols[iZ,nPxCofins]
			aSubValores[14] += oMulti:aCols[iZ,nPxCofins]

			// Valor ICMS
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxICMS]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxICMS]
			aSubValores[10] += oMulti:aCols[iZ,nPxICMS]
			aSubValores[14] += oMulti:aCols[iZ,nPxICMS]

			// Valor Frete informado Pedido
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxFrete]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxFrete]
			aSubValores[10] += oMulti:aCols[iZ,nPxFrete]
			aSubValores[14] += oMulti:aCols[iZ,nPxFrete]

			// Valor Tampas
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxValTamp]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxValTamp]
			aSubValores[10] += oMulti:aCols[iZ,nPxValTamp]
			aSubValores[14] += oMulti:aCols[iZ,nPxValTamp]

			// Valor Adicional Custo de Tampas
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxAddTamp]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxAddTamp]
			aSubValores[10] += oMulti:aCols[iZ,nPxAddTamp]
			aSubValores[14] += oMulti:aCols[iZ,nPxAddTamp]

			If cFlgRetAlc <> "D"
				// Valor Marketing
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxValMkt]
				aSubValores[10] += oMulti:aCols[iZ,nPxValMkt]

				// Valor F&I
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxValPag]
				aSubValores[10] += oMulti:aCols[iZ,nPxValMkt]

				// Valor Retenção - Retenção não deve ser desconto pois é o pagamento de tampinhas para alguns clientes.
				//oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxRetenc]
				//aSubValores[10] += oMulti:aCols[iZ,nPxRetenc]

				// Subtrai o percentual de ajuste do cadastro de produto
				oMulti:aCols[iZ,nPxVFlex]	-= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * Iif(SB1->(FieldPos("B1_PRMINFO"))<> 0,SB1->B1_PRMINFO,1) / 100 , 2 )

			Endif
			// Subtrai o percentual de ajuste do cadastro de produto
			oMulti:aCols[iZ,nPxVMg1]	-= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * Iif(SB1->(FieldPos("B1_PRMINFO"))<> 0,SB1->B1_PRMINFO,1) / 100 , 2 )

			oMulti:aCols[iZ,nPxPFlex]	:= Round(oMulti:aCols[iZ,nPxVFlex]/(oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])*100,2)

			oMulti:aCols[iZ,nPxPMg1]	:= Round(oMulti:aCols[iZ,nPxVMg1]/(oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])*100,2)


			aSubValores[11] += oMulti:aCols[iZ,nPxVFlex]+oMulti:aCols[iZ,nPxFrete]
			aSubValores[15] += oMulti:aCols[iZ,nPxVMg1]+oMulti:aCols[iZ,nPxFrete] // Soma o frete devolta para exibir margem sem frete
			aSubValores[20] += oMulti:aCols[iZ,nPxVMg1]
		Endif
	Next
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Indica os valores do cabecalho               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MaFisAlt("NF_FRETE"		,SC5->C5_FRETE)
	aSubValores[22] := SC5->C5_FRETE
	MaFisAlt("NF_VLR_FRT"	,SC5->C5_VLR_FRT)
	MaFisAlt("NF_SEGURO"	,SC5->C5_SEGURO)
	MaFisAlt("NF_AUTONOMO"	,SC5->C5_FRETAUT)
	MaFisAlt("NF_DESPESA"	,SC5->C5_DESPESA)

	//If SC5->C5_DESCONT > 0
	//	MaFisAlt("NF_DESCONTO",Min(MaFisRet(,"NF_VALMERC")-0.01,nTotDesc+SC5->C5_DESCONT),/*nItem*/,/*lNoCabec*/,/*nItemNao*/,GetNewPar("MV_TPDPIND","1")=="2" )
	//EndIf
	//If SC5->C5_PDESCAB > 0
	//	MaFisAlt("NF_DESCONTO",A410Arred(MaFisRet(,"NF_VALMERC")*SC5->C5_PDESCAB/100,"C6_VALOR")+MaFisRet(,"NF_DESCONTO"))
	//EndIf

	aSubValores[9] := MaFisRet(,"NF_TOTAL")//+= (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])

	// Calcula percentual de Margem e IR somente pela Receita do pedido
	aSubValores[17] := MaFisRet(,"NF_BASEDUP")
	aSubValores[12] := Round(aSubValores[11] / aSubValores[17] * 100,2)
	aSubValores[16] := Round(aSubValores[15] / aSubValores[17] * 100,2)
	aSubValores[21] := Round(aSubValores[20] / aSubValores[17] * 100,2)
	aSubValores[19] := Round(aSubValores[18]/MaFisRet(,"NF_TOTAL")*100,2)


	oSubValores[9]:Refresh()
	oSubValores[10]:Refresh()
	oSubValores[11]:Refresh()
	oSubValores[12]:Refresh()
	oSubValores[13]:Refresh()
	oSubValores[14]:Refresh()
	oSubValores[15]:Refresh()
	oSubValores[16]:Refresh()
	oSubValores[18]:Refresh()
	oSubValores[19]:Refresh()
	oSubValores[20]:Refresh()
	oSubValores[21]:Refresh()
	oSubValores[22]:Refresh()

	MaFisEnd()
	MaFisRestore()
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfSUAIMpostos
(long_description)
@author MarceloLauschner
@since 08/05/2014
@version 1.0
@param cNumPed, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSUAIMpostos(cNumPed)

	Local		cValid
	Local		nPosIni
	Local		nLen
	Local		cReferencia
	Local		aFisGet
	Local		aFisGetSC5
	Local		lProspect
	Local		cTipo
	Local		nValMerc	:= 0
	Local		nPrcLista	:= 0
	Local		nAcresUnit	:= 0
	Local		nAcresFin	:= 0
	Local		nDesconto	:= 0
	Local		nItemFis	:= 0
	Local		aAreaOld	:= GetArea()
	Local		aRestPerg	:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		nY,iZ,nX
	Default	cNumPed	:=  aListPed[oArqPed:nAt,3]

	aSubValores[9]	:= 0
	aSubValores[10]	:= 0
	aSubValores[11]	:= 0
	aSubValores[12]	:= 0
	aSubValores[13]	:= 0
	aSubValores[14]	:= 0
	aSubValores[15]	:= 0
	aSubValores[16]	:= 0
	aSubValores[17]	:= 0
	aSubValores[18]	:= 0
	aSubValores[19]	:= 0
	aSubValores[20]	:= 0
	aSubValores[21]	:= 0
	aSubValores[22] := 0

	aFisGet	:= {}


	aFields := {}
	aFields := FWSX3Util():GetAllFields("SUB", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cValid := UPPER(GetSx3Cache(cCampo,"X3_VALID")+GetSx3Cache(cCampo,"X3_VLDUSER"))

		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGet,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGet,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf

	Next nX


	aSort(aFisGet,,,{|x,y| x[3]<y[3]})

	aFisGetSC5	:= {}
	

	aFields := {}
	aFields := FWSX3Util():GetAllFields("SUA", .F. /*/lVirtual/*/)

	For nX := 1 to Len(aFields)

		cCampo := aFields[nx]

		cValid := UPPER(GetSx3Cache(cCampo,"X3_VALID")+GetSx3Cache(cCampo,"X3_VLDUSER"))
		
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGetSC5,{cReferencia,GetSx3Cache(cCampo,"X3_CAMPO"),MaFisOrdem(cReferencia)})
		EndIf

	Next nX

	aSort(aFisGetSC5,,,{|x,y| x[3]<y[3]})

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicializa a funcao fiscal                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SUA")
	DbSetOrder(1)
	DbSeek(xFilial("SUA")+cNumPed)

	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+SUA->UA_VEND)

	nPCusFixo		:= U_BFFATM02(cEmpAnt)
	
	lProspect := SUA->UA_PROSPEC

	If lProspect
		cTipo := Posicione("SUS",1,xFilial("SUS") + SUA->UA_CLIENTE + SUA->UA_LOJA,"US_TIPO")
	Else
		cTipo := Posicione("SA1",1,xFilial("SA1") + SUA->UA_CLIENTE + SUA->UA_LOJA,"A1_TIPO")
	Endif


	MaFisSave()
	MaFisEnd()

	MaFisIni(SUA->UA_CLIENTE,;	// 1-Codigo Cliente/Fornecedor
		SUA->UA_LOJA,;		// 2-Loja do Cliente/Fornecedor
		"C",;				// 3-C:Cliente , F:Fornecedor
		"N",;				// 4-Tipo da NF
		cTipo,;				// 5-Tipo do Cliente/Fornecedor
		Nil,;				// 6-Relacao de Impostos que suportados no arquivo
		Nil,;				// 7-Tipo de complemento
		Nil,;				// 8-Permite Incluir Impostos no Rodape .T./.F.
		Nil,;				// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
		"MATA461",;			// 10-Nome da rotina que esta utilizando a funcao
		Nil,;				// 11-Tipo de documento
		Nil,;  				// 12-Especie do documento
		IIF(lProspect,SUA->UA_CLIENTE+SUA->UA_LOJA,""))// 13- Codigo e Loja do Prospect

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Realiza alteracoes de referencias do SC5         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aFisGetSC5) > 0
		dbSelectArea("SUA")
		For nY := 1 to Len(aFisGetSC5)
			If !Empty(&("SUA->"+Alltrim(aFisGetSC5[ny][2])))
				MaFisAlt(aFisGetSC5[ny][1],&("SUA->"+Alltrim(aFisGetSC5[ny][2])),,.F.)
			EndIf
		Next nY
	Endif


	// Efetua um primeiro laço para atualizar dados para calculo do frete
	For iZ := 1 To Len(oMulti:aCols)

		If !oMulti:aCols[iZ,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[iZ,nPxItem])
			aSubValores[13] += oMulti:aCols[iZ,nPxPeso]
		Endif

	Next
	// Se estiver setado no pedido que não tem frete por que cliente retira, deduz o custo do transporte da margem
	If !(SUA->UA_TPFRETE) $ "S#F" 	// Sem frete/FOB
		// Efetua calculo do frete
		aSubValores[18] := U_BFFATM22(SUA->UA_EMISSAO/*dInData*/,SUA->UA_CLIENTE/*cInCodCli*/,SUA->UA_LOJA/*cInLojCli*/,SUA->UA_TRANSP/*cInTransp*/,aListPed[oArqPed:nAt,5]/*nInVlrMerc*/,aSubValores[13]/*nInPeso*/,SUA->UA_FRETE/*nInVlrFrete*/)
	Endif

	For iZ := 1 To Len(oMulti:aCols)

		If !oMulti:aCols[iZ,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[iZ,nPxItem])

			DbSelectArea("SF4")
			SF4->(dbSetOrder(1))
			SF4->(MsSeek(xFilial("SF4")+oMulti:aCols[iZ,nPxTES]))

			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+oMulti:aCols[iZ,nPxProd])
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Calcula o preco de lista                     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			nValMerc  := (oMulti:aCols[iZ,nPxQtdVen])*oMulti:aCols[iZ,nPxPrcVen]
			nPrcLista := oMulti:aCols[iZ,nPxPrunit]

			nAcresUnit:= A410Arred(oMulti:aCols[iZ,nPxPrcVen]*SUA->UA_PDESCAB/100,"D2_PRCVEN")
			nAcresFin := A410Arred(oMulti:aCols[iZ,nPxQtdVen]*nAcresUnit,"D2_TOTAL")
			nValMerc  += nAcresFin
			nDesconto := a410Arred(nPrcLista*oMulti:aCols[iZ,nPxQtdVen],"D2_DESCON")-nValMerc
			nDesconto := IIf(nDesconto<=0,oMulti:aCols[iZ,nPxValDesc],nDesconto)
			nDesconto := Max(0,nDesconto)
			nPrcLista += nAcresUnit
			//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
			If cPaisLoc=="BRA" .or. GetNewPar('MV_DESCSAI','1') == "2"
				nValMerc  += nDesconto
			Endif
			nItemFis++
			MaFisAdd(	SB1->B1_COD,;  		// 1-Codigo do Produto ( Obrigatorio )
				oMulti:aCols[iZ,nPxTES],;		// 2-Codigo do TES ( Opcional )
				oMulti:aCols[iZ,nPxQtdVen],; 	// 3-Quantidade ( Obrigatorio )
				oMulti:aCols[iZ,nPxPrunit],;	// 4-Preco Unitario ( Obrigatorio )
				nDesconto,;	 					// 5-Valor do Desconto ( Opcional )
				"",;	   						// 6-Numero da NF Original ( Devolucao/Benef )
				"",;							// 7-Serie da NF Original ( Devolucao/Benef )
				0,;								// 8-RecNo da NF Original no arq SD1/SD2
				Round(SUA->UA_FRETE*(oMulti:aCols[iZ,nPxValor]/aListPed[oArqPed:nAt,5]),2),;	// 9-Valor do Frete do Item ( Opcional )
				0,;								// 10-Valor da Despesa do item ( Opcional )
				0,;								// 11-Valor do Seguro do item ( Opcional )
				0,;								// 12-Valor do Frete Autonomo ( Opcional )
				nValMerc,;						// 13-Valor da Mercadoria ( Obrigatorio )
				0,;								// 14-Valor da Embalagem ( Opiconal )
				,;								// 15
				,;								// 16
				oMulti:aCols[iZ,nPxItem],; 		// 17
				0,;								// 18-Despesas nao tributadas - Portugal
				0,;								// 19-Tara - Portugal
				oMulti:aCols[iZ,nPxCFOP],; 		// 20-CFO
				{},;	           				// 21-Array para o calculo do IVA Ajustado (opcional)
				"")
			oMulti:aCols[iZ,nPxPIS]		:= MaFisRet(nItemFis,"IT_VALPS2")
			oMulti:aCols[iZ,nPxCofins]	:= MaFisRet(nItemFis,"IT_VALCF2")
			oMulti:aCols[iZ,nPxICMS]	:= MaFisRet(nItemFis,"IT_VALICM")
			// Chamado 17927 - Soma ao valor do ICMS o valor do ICMS Complementar e o DIFAL (Diferencial de Aliquota ) para calculo correto da margem
			oMulti:aCols[iZ,nPxICMS]	+= MaFisRet(nItemFis,"IT_VALCMP") + MaFisRet(nItemFis,"IT_DIFAL")

			oMulti:aCols[iZ,nPxDespesa]	:= MaFisRet(nItemFis,"IT_DESPESA")+(nPCusFixo * (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) / 100)
			oMulti:aCols[iZ,nPxFrete]	:= Round(aSubValores[18]*(oMulti:aCols[iZ,nPxValor]/aListPed[oArqPed:nAt,5]),2)	//MaFisRet(nItemFis,"IT_FRETE")
			oMulti:aCols[iZ,nPxXCusto]	:= Iif(SF4->F4_DUPLIC =="S",Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * ((1.00066030548229^nPrzMed)-1),2),0)

			oMulti:aCols[iZ,nPxComis1]	:=	Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * oMulti:aCols[iZ,nPxComis1] / 100,2)
			oMulti:aCols[iZ,nPxComis2]	:=	Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * oMulti:aCols[iZ,nPxComis2] / 100,2)

			// Função padrão para calculo do F&I e Verba Marketing
			aRetTmka08	:= U_BFTMKA08(SUA->UA_CLIENTE,SUA->UA_LOJA,oMulti:aCols[iZ,nPxProd])
			nPercFI		:= aRetTmka08[1]
			nPercMKT	:= aRetTmka08[2]
			nPercRet	:= aRetTmka08[3]

			//Verifica se há percentual de F&I cadastrada para o clienteXgrupo
			oMulti:aCols[iZ,nPxValPag]	:= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * nPercFI / 100,2)

			//Verifica se há percentual de verba de marketing cadastrada para o clienteXgrupo
			oMulti:aCols[iZ,nPxValMkt]	:= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * nPercMKT / 100,2)

			//Verifica se há percentual de Retenção cadastrada para o clienteXgrupo
			oMulti:aCols[iZ,nPxRetenc]	:= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * nPercRet / 100,2)


			If SF4->F4_DUPLIC =="S"
				oMulti:aCols[iZ,nPxVFlex]	:= (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])
				oMulti:aCols[iZ,nPxVMg1]	:= (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])

				If cFlgRetAlc <> "D"
					// Comissão 1
					oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxComis1]
					aSubValores[10] += oMulti:aCols[iZ,nPxComis1]

					// Comissão 2
					oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxComis2]
					aSubValores[10] += oMulti:aCols[iZ,nPxComis2]


					// Soma o valor somente de Receitas - valor é obtido pela função MatxFis
					//aSubValores[17] += (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])
				Endif

				// Custo do financeiro prazo médio
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxXCusto]
				aSubValores[10] += oMulti:aCols[iZ,nPxXCusto]
				// Custo administrativo
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxDespesa]
				aSubValores[10] += oMulti:aCols[iZ,nPxDespesa]

			Endif

			// Valor PIS
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxPIS]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxPIS]
			aSubValores[10] += oMulti:aCols[iZ,nPxPIS]
			aSubValores[14] += oMulti:aCols[iZ,nPxPIS]

			// Valor Custo Estoque
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,Iif(cFlgRetAlc == "D",nPxCM1,nPxCusto)]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxCusto]
			aSubValores[10] += oMulti:aCols[iZ,Iif(cFlgRetAlc == "D",nPxCM1,nPxCusto)]
			aSubValores[14] += oMulti:aCols[iZ,nPxCusto]

			// Valor Cofins
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxCofins]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxCofins]
			aSubValores[10] += oMulti:aCols[iZ,nPxCofins]
			aSubValores[14] += oMulti:aCols[iZ,nPxCofins]

			// Valor ICMS
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxICMS]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxICMS]
			aSubValores[10] += oMulti:aCols[iZ,nPxICMS]
			aSubValores[14] += oMulti:aCols[iZ,nPxICMS]

			// Valor Frete informado Pedido
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxFrete]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxFrete]
			aSubValores[10] += oMulti:aCols[iZ,nPxFrete]
			aSubValores[14] += oMulti:aCols[iZ,nPxFrete]

			// Valor Tampas
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxValTamp]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxValTamp]
			aSubValores[10] += oMulti:aCols[iZ,nPxValTamp]
			aSubValores[14] += oMulti:aCols[iZ,nPxValTamp]

			// Valor Adicional Custo de Tampas
			oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxAddTamp]
			oMulti:aCols[iZ,nPxVMg1]	-= oMulti:aCols[iZ,nPxAddTamp]
			aSubValores[10] += oMulti:aCols[iZ,nPxAddTamp]
			aSubValores[14] += oMulti:aCols[iZ,nPxAddTamp]

			If cFlgRetAlc <> "D"
				// Valor Marketing
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxValMkt]
				aSubValores[10] += oMulti:aCols[iZ,nPxValMkt]

				// Valor F&I
				oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxValPag]
				aSubValores[10] += oMulti:aCols[iZ,nPxValMkt]

				// Retenção não deve subtrair da margem pois Retenção é o conceito de pagamento dos créditos de Tampinhas e F&I
				// Valor Retenção
				//oMulti:aCols[iZ,nPxVFlex]	-= oMulti:aCols[iZ,nPxRetenc]
				//aSubValores[10] += oMulti:aCols[iZ,nPxRetenc]

				// Subtrai o percentual de ajuste do cadastro de produto
				oMulti:aCols[iZ,nPxVFlex]	-= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * Iif(SB1->(FieldPos("B1_PRMINFO"))<> 0,SB1->B1_PRMINFO,1) / 100 , 2 )
			Endif

			// Subtrai o percentual de ajuste do cadastro de produto
			oMulti:aCols[iZ,nPxVMg1]		-= Round((oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen]) * Iif(SB1->(FieldPos("B1_PRMINFO"))<> 0,SB1->B1_PRMINFO,1) / 100 , 2 )

			oMulti:aCols[iZ,nPxPFlex]	:= Round(oMulti:aCols[iZ,nPxVFlex]/(oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])*100,2)

			oMulti:aCols[iZ,nPxPMg1]	:= Round(oMulti:aCols[iZ,nPxVMg1]/(oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])*100,2)

			aSubValores[9] += (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])
			aSubValores[11] += oMulti:aCols[iZ,nPxVFlex]
			aSubValores[15] += oMulti:aCols[iZ,nPxVMg1]+oMulti:aCols[iZ,nPxFrete] // Soma o frete devolta para exibir margem sem frete
			aSubValores[20] += oMulti:aCols[iZ,nPxVMg1]

		Endif
	Next
	// Calcula percentual de Margem e IR somente pela Receita do pedido
	aSubValores[17] := MaFisRet(,"NF_BASEDUP")
	aSubValores[22] := MaFisRet(,"NF_FRETE")
	aSubValores[12] := aSubValores[11] / aSubValores[17] * 100
	aSubValores[16] := aSubValores[15] / aSubValores[17] * 100
	aSubValores[21] := aSubValores[20] / aSubValores[17] * 100
	aSubValores[19] := Round(aSubValores[18]/MaFisRet(,"NF_TOTAL")*100,2)

	oSubValores[9]:Refresh()
	oSubValores[10]:Refresh()
	oSubValores[11]:Refresh()
	oSubValores[12]:Refresh()
	oSubValores[13]:Refresh()
	oSubValores[14]:Refresh()
	oSubValores[15]:Refresh()
	oSubValores[16]:Refresh()
	oSubValores[18]:Refresh()
	oSubValores[19]:Refresh()
	oSubValores[20]:Refresh()
	oSubValores[21]:Refresh()
	oSubValores[22]:Refresh()

	MaFisEnd()
	MaFisRestore()
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfLegenda
(Monta legenda do array de Pedidos)
@author MarceloLauschner
@since 15/04/2014
@version 1.0
@return Bitmap, nome do objeto cor para a legenda
@example
(examples)
@see (links_or_references)
/*/
Static Function sfLegenda()

	Local	oRet := 0

	If Len(aListPed) <= 0
		Return oVermelho
	Endif

	If oArqPed:nAt > Len(aListPed)
		oArqPed:nAt := Len(aListPed)
	ElseIf oArqPed:nAt == 0 .And. Len(aListPed) > 0
		oArqPed:nAt := 1
	Endif

	If	aListPed[oArqPed:nAt,1] == 1
		oRet	:= oVermelho
	ElseIf	aListPed[oArqPed:nAt,1] == 2
		oRet	:= oVerde
	ElseIf	aListPed[oArqPed:nAt,1] == 3
		oRet	:= oAmarelo
	ElseIf aListPed[oArqPed:nAt,1] == 4
		oRet	:= oAzul
	ElseIf aListPed[oArqPed:nAt,1] == 5
		// IAGO 03/06/2015 Variavel não existe.
		//oRet	:= oCinza
		oRet	:= oGrey
	ElseIf aListPed[oArqPed:nAt,1] == 6
		oRet	:= oPink
	ElseIf aListPed[oArqPed:nAt,1] == 7
		oRet	:= oLaranja
	ElseIf aListPed[oArqPed:nAt,1] == 8
		oRet	:= oPreto
	ElseIf aListPed[oArqPed:nAt,1] == 9
		oRet	:= oColorCTe
	ElseIf aListPed[oArqPed:nAt,1] == 10
		oRet	:= oAntecipa
	Else
		oRet	:= oVioleta
	EndIf

Return(oRet)


/*/{Protheus.doc} stRefrItens
(long_description)
@author MarceloLauschner
@since 15/04/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stRefrItens()

	Local		lRet		:= .T.
	Local		cQry		:= ""
	Local		cQryU
	Local		cNumPed		:= aListPed[oArqPed:nAt,3]
	Local		nSubCfop	:= 0
	Local 		nSubDesc	:= 0
	Local 		nSubPrcTab	:= 0
	Local		cCfopSub	:= ""
	Local		lAdd		:= .T.
	Local		nLinAdd	:= 0
	Local		nX,iZ
	Local 		cFilSX5 	:= FWxFilial("SX5")
	oMulti:aCols := {}


	If MV_PAR07 == 1 // Pedido

		// Alçada = 0  e 5=Valor - 13=Faturado - 6=Residuo - 9=Liberado - 10=Bloq.Estoque - 11=Credito > 0
		If aListPed[oArqPed:nAt,8] == 0 .And. (aListPed[oArqPed:nAt,5]-aListPed[oArqPed:nAt,13]-aListPed[oArqPed:nAt,6]-aListPed[oArqPed:nAt,9]-aListPed[oArqPed:nAt,10]-aListPed[oArqPed:nAt,11]) > 0

			If aScan(aLoopPedido,{|x| x == cNumPed}) == 0
				Aadd(aLoopPedido,cNumPed)

				DbSelectArea("SC5")
				DbSetOrder(1)
				If DbSeek(xFilial("SC5")+cNumPed)


					Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)

					U_GMCFGM01(	"LP"/*cTipo*/,cNumPed/*cPedido*/,/*cObserv*/,FunName()/*cResp*/,/*lBtnCancel*/,/*cMotDef*/,/*lAutoExec*/,)

					U_BFFATA35("P"/*cZ9ORIGEM*/,cNumPed/*cZ9NUM*/,"5"/*cZ9EVENTO*/,FunName()/*cZ9DESCR*/,/*cZ9DEST*/,/*cZ9USER*/)

					Eval(bRefrXmlF)

					cVarPesq := aListPed[oArqPed:nAt,3]

					sfPesquisa()

					Return
				Endif
			Endif
		Endif

		cQry += "SELECT C6_ITEM,"
		cQry += "       C6_PRODUTO,"
		cQry += "       C6_COMIS1,"
		cQry += "       C6_COMIS2,"
		cQry += "       C6_LOCAL + ' - ' +B1_DESC C6_DESCRI,"
		cQry += "       C6_LOCAL ARMAZEM,"
		cQry += "       C6_TES,"
		cQry += "       C6_CF,"
		cqry += "       C6_VALDESC,"
		cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN C9_QTDLIB ELSE C6_QTDVEN END C6_QTDVEN,"
		cQry += "       C6_PRUNIT,"
		cQry += "       C6_PRCVEN,"
		cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN CASE WHEN C6_QTDVEN = 0 THEN C6_VALOR ELSE (C6_VALOR/C6_QTDVEN)*C9_QTDLIB END ELSE C6_VALOR END C6_VALOR,"
		cQry += "       C6_XCODTAB,"
		cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN C6_XVLRTAM*C9_QTDLIB ELSE C6_XVLRTAM*C6_QTDVEN END C6_XVLRTAM,"
		cQry += "       CASE WHEN C9_SEQUEN IS NOT NULL THEN C6_XFLEX*C9_QTDLIB ELSE C6_XFLEX*C6_QTDVEN END C6_XFLEX,"
		cQry += "       (B2_CM1 * (CASE WHEN C9_SEQUEN IS NOT NULL THEN C9_QTDLIB ELSE C6_QTDVEN END)) B2_CM1 ,"
		cQry += "       B2_QATU-B2_RESERVA+(CASE WHEN C9_BLCRED+C9_BLEST = '    ' THEN C9_QTDLIB ELSE 0 END) SALDOATUAL,"
		cQry += "       C9_SEQUEN, "
		cQry += "       CASE "
		cQry += "         WHEN C6_BLQ = 'S' AND C9_SEQUEN IS NULL THEN 'Alçada/A Liberar' "
		cQry += "         WHEN C6_BLQ = 'R' AND C9_SEQUEN IS NULL THEN 'Residuo' "
		cQry += "         WHEN C9_SEQUEN IS NULL THEN 'A Liberar' "
		cQry += "         WHEN C9_NFISCAL !=  '  ' THEN 'Faturado' "
		cQry += "         WHEN C9_BLCRED NOT IN('  ','10') AND C9_BLEST NOT IN('  ','10') THEN 'Crédito/Estoque' "
		cQry += "         WHEN C9_BLCRED NOT IN('  ','10') THEN 'Crédito' "
		cQry += "         WHEN C9_BLEST NOT IN('  ','10') AND C9_FLGENVI = 'E' THEN 'Blq/Estoque+Expedição:' + SUBSTRING(C9_LIBFAT,7,2)+'/'+SUBSTRING(C9_LIBFAT,5,2)+'/'+SUBSTRING(C9_LIBFAT,3,2) + ' ' + C9_BLINF "
		cQry += "         WHEN C9_BLEST NOT IN('  ','10') THEN 'Estoque' "
		cQry += "         WHEN C9_FLGENVI = 'E' THEN 'Ok+Expedição:' + SUBSTRING(C9_LIBFAT,7,2)+'/'+SUBSTRING(C9_LIBFAT,5,2)+'/'+SUBSTRING(C9_LIBFAT,3,2) + ' ' + C9_BLINF "
		cQry += "        ELSE "
		cQry += "         'Ok' "
		cQry += "        END STATUS, "
		cQry += "        B1_PESBRU B1_PESO,"
		cQry += "        B1_PROC,"
		cQry += "        B1_LOJPROC,"
		cQry += "        B1_CUSTD,"
		// IAGO 26/10/2016 Chamado(16138)
		cQry += "        C6.C6_CLI,"
		cQry += "        C6.C6_LOJA"

		cQry += "  FROM "+RetSqlName("SC6")+ " C6 "
		cQry += " LEFT JOIN " + RetSqlName("SB2") + " B2 "
		cQry += "    ON B2.D_E_L_E_T_ =' ' "
		cQry += "   AND B2_LOCAL = C6_LOCAL "
		cQry += "   AND B2_COD = C6_PRODUTO "
		cQry += "   AND B2_FILIAL = '"+xFilial("SB2") + "' "
		cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 " 
		cQry += "    ON B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_COD = C6_PRODUTO "
		cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
		cQry += " INNER JOIN " + RetSqlName("SC9") + " C9 "
		cQry += "    ON C9.D_E_L_E_T_ = ' ' "
		cQry += "   AND C9_ITEM = C6_ITEM "
		cQry += "   AND C9_PRODUTO = C6_PRODUTO "
		cQry += "   AND C9_PEDIDO = C6_NUM "
		cQry += "   AND C9_FILIAL = '"+xFilial("SC9")+"' "		
		cQry += " WHERE C6.D_E_L_E_T_ =' ' "
		cQry += "   AND C6_NUM = '"+cNumPed+"' "
		cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "

		cQry += "UNION "
		cQry += "SELECT C6_ITEM,"
		cQry += "       C6_PRODUTO,"
		cQry += "       C6_COMIS1,"
		cQry += "       C6_COMIS2,"
		cQry += "       C6_LOCAL +' - '+B1_DESC C6_DESCRI,"
		cQry += "       C6_LOCAL ARMAZEM,"
		cQry += "       C6_TES,"
		cQry += "       C6_CF,"
		cqry += "       C6_VALDESC,"
		cQry += "       C6_QTDVEN - C6_QTDENT - C6_QTDEMP C6_QTDVEN,"
		cQry += "       C6_PRUNIT,"
		cQry += "       C6_PRCVEN,"
		cQry += "       (C6_QTDVEN - C6_QTDENT - C6_QTDEMP )*C6_PRCVEN C6_VALOR,"
		cQry += "       C6_XCODTAB,"
		cQry += "       (C6_QTDVEN - C6_QTDENT - C6_QTDEMP )* C6_XVLRTAM C6_XVLRTAM,"
		cQry += "       (C6_QTDVEN - C6_QTDENT - C6_QTDEMP )* C6_XFLEX C6_XFLEX,"
		cQry += "       (B2_CM1 * (C6_QTDVEN - C6_QTDENT - C6_QTDEMP )) B2_CM1 ,"
		cQry += "       B2_QATU-B2_RESERVA SALDOATUAL,"
		cQry += "       '' C9_SEQUEN, "
		cQry += "       CASE "
		cQry += "         WHEN C6_BLQ = 'S' THEN 'Alçada/A Liberar' "
		cQry += "         WHEN C6_BLQ = 'R' THEN 'Residuo' "
		cQry += "        ELSE "
		cQry += "         'A Liberar' "
		cQry += "        END STATUS, "
		cQry += "        B1_PESBRU B1_PESO,"
		cQry += "        B1_PROC,"
		cQry += "        B1_LOJPROC, "
		cQry += "        B1_CUSTD,"
		// IAGO 26/10/2016 Chamado(16138)
		cQry += "        C6.C6_CLI,"
		cQry += "        C6.C6_LOJA"

		cQry += "  FROM "+RetSqlName("SC6")+ " C6 "
		cQry += " LEFT JOIN "+ RetSqlName("SB2") + " B2 "		
		cQry += "  ON B2.D_E_L_E_T_ =' ' "
		cQry += " AND B2_LOCAL = C6_LOCAL "
		cQry += " AND B2_COD = C6_PRODUTO "
		cQry += " AND B2_FILIAL = '"+xFilial("SB2") + "' "

		cQry += " INNER JOIN "+ RetSqlName("SB1")+" B1 "
		cQry += "  ON B1.D_E_L_E_T_ = ' ' "
		cQry += " AND B1_COD = C6_PRODUTO "
		cQry += " AND B1_FILIAL = '"+xFilial("SB1")+"' "

		cQry += " WHERE C6_QTDVEN > ISNULL((SELECT SUM(C9_QTDLIB) "
		cQry += "                          FROM "+RetSqlName("SC9")  + " C9 "
		cQry += "                  	      WHERE D_E_L_E_T_ = ' ' "
		cQry += "                           AND C9_ITEM = C6_ITEM "
		cQry += "                           AND C9_PRODUTO = C6_PRODUTO "
		cQry += "                           AND C9_PEDIDO = C6_NUM "
		cQry += "                           AND C9_FILIAL = '"+xFilial("SC9")+"'),0) "
		cQry += "   AND C6_QTDENT < C6_QTDVEN "
		cQry += "   AND C6.D_E_L_E_T_ =' ' "
		cQry += "   AND C6_NUM = '"+cNumPed+"' "
		cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
		cQry += " ORDER BY C6_CF,C6_ITEM,C9_SEQUEN "

		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSC6', .F., .T.)

		While !Eof()

			// IAGO 26/10/2016 Chamado(16138)
			cQryU := "SELECT D2.D2_QUANT   AS ULTQTD,"
			cQryU += "       D2.D2_PRCVEN  AS ULTPRCVEN,"
			cQryU += "       D2.D2_EMISSAO AS ULTEMISSAO,"
			cQryU += "       (SELECT C5_CONDPAG "
			cQryU += "          FROM " + RetSqlName("SC5") + " C5 "
			cQryU += "         WHERE C5.D_E_L_E_T_ =' ' "
			cQryU += "           AND C5_NUM = D2_PEDIDO "
			cQryU += "           AND C5_FILIAL = '" + xFilial("SC5") + "') ULTCONDPG"
			cQryU += "  FROM "+RetSqlName("SD2")+ " D2"
			cQryU += " WHERE D2.R_E_C_N_O_ = (SELECT MAX(D22.R_E_C_N_O_)"
			cQryU += "                          FROM "+RetSqlName("SD2")+ " D22"
			cQryU += "                         INNER JOIN "+RetSqlName("SF4")+ " F4 "
			cQryU += "                            ON F4.F4_FILIAL = D22.D2_FILIAL"
			cQryU += "                           AND F4.F4_CODIGO = D22.D2_TES"
			cQryU += "                           AND F4.F4_ESTOQUE = 'S'"
			cQryU += "                           AND F4.F4_DUPLIC = 'S'"
			cQryU += "                           AND F4.D_E_L_E_T_ = ' '"
			cQryU += "                         WHERE D22.D2_FILIAL = '"+ xFilial("SD2") +"'"
			cQryU += "                           AND D22.D2_CLIENTE = '"+ QSC6->C6_CLI +"'"
			cQryU += "                           AND D22.D2_LOJA = '"+ QSC6->C6_LOJA +"'"
			cQryU += "                           AND D22.D_E_L_E_T_ = ' '"
			cQryU += "                           AND D22.D2_COD = '"+ QSC6->C6_PRODUTO +"'"
			cQryU += "                           AND D22.D2_EMISSAO >= '"+DTOS(Date()-360)+"' )"

			If Select("QRYU") <> 0
				QRYU->(dbCloseArea())
			EndIf

			TCQuery cQryU New Alias "QRYU"

			lAdd		:= .T.


			If !Empty(cCfopSub) .And. cCfopSub <> QSC6->C6_CF .And. nSubCfop > 0
				//dbSelectArea("SX5")
				//dbSetOrder(1)

				aRetSX5 := FWGetSX5("13",cCfopSub)
				For nX := 1 to Len(aRetSX5)
					If aRetSX5[nX][1] == cFilSX5
						cNumSx5 := Alltrim(aRetSX5[nX][4])
					EndIf
				Next nX

				If  !Empty(cNumSx5)//dbSeek(xFilial("SX5")+"13"+cCfopSub)
					Aadd(oMulti:aCols,aClone(aColsPed))
					nLinAdd++
					If lIsAprovador
						oMulti:aCols[nLinAdd,1] 		:= oColorCTe
						oMulti:aCols[nLinAdd,nPxDescri]	:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
						oMulti:aCols[nLinAdd,nPxValor]	:= nSubCfop
						oMulti:aCols[nLinAdd,nPxCFOP]	:= cCfopSub
						oMulti:aCols[nLinAdd,nPxValDesc]:= nSubDesc
						oMulti:aCols[nLinAdd,nPxPDesc]	:= Round(nSubDesc/nSubPrcTab*100,4)
					Else
						oMulti:aCols[nLinAdd,1] 		:= oColorCTe
						oMulti:aCols[nLinAdd,nPxDescri]	:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
						oMulti:aCols[nLinAdd,nPxValor]	:= nSubCfop
						oMulti:aCols[nLinAdd,nPxValDesc]:= nSubDesc
						oMulti:aCols[nLinAdd,nPxPDesc]	:= Round(nSubDesc/nSubPrcTab*100,4)
					Endif
					oMulti:Refresh()
				Endif
				nSubCfop	:= 0
				nSubDesc	:= 0
				nSubPrcTab	:= 0
			Endif

			If lIsAprovador
				If lCheckPen
					If Alltrim(QSC6->STATUS) == 'Faturado'
						lAdd	:= .F.
					Endif
				Endif
				If lAdd
					cCfopSub	:= QSC6->C6_CF
					nSubCfop	+= QSC6->C6_VALOR
					nSubPrcTab	+= QSC6->C6_PRUNIT * QSC6->C6_QTDVEN
					nSubDesc 	+= (QSC6->C6_PRUNIT - QSC6->C6_PRCVEN ) * QSC6->C6_QTDVEN
					Aadd(oMulti:aCols,aClone(aColsPed))
					nLinAdd++
					oMulti:aCols[nLinAdd,1]				:= IIf(Empty(QSC6->C6_XCODTAB),oVermelho,Iif(QSC6->C6_PRCVEN>=QSC6->C6_PRUNIT,oVerde,oAmarelo) )
					oMulti:aCols[nLinAdd,nPxItem]		:= QSC6->C6_ITEM				//	2
					oMulti:aCols[nLinAdd,nPxSequenc]	:= QSC6->C9_SEQUEN			//	3
					oMulti:aCols[nLinAdd,nPxProd]		:= QSC6->C6_PRODUTO			//	4
					oMulti:aCols[nLinAdd,nPxDescri]		:= QSC6->C6_DESCRI			//	5
					oMulti:aCols[nLinAdd,nPxStatus]		:= QSC6->STATUS				//	6
					oMulti:aCols[nLinAdd,nPxEstoque]	:= QSC6->SALDOATUAL			//	7
					oMulti:aCols[nLinAdd,nPxQtdVen]		:= QSC6->C6_QTDVEN			//	8
					oMulti:aCols[nLinAdd,nPxPrunit]		:= QSC6->C6_PRUNIT			//	9
					oMulti:aCols[nLinAdd,nPxPrcVen]		:= QSC6->C6_PRCVEN			//	10
					oMulti:aCols[nLinAdd,nPxValDesc]	:= (QSC6->C6_PRUNIT - QSC6->C6_PRCVEN ) * QSC6->C6_QTDVEN		//	11

					oMulti:aCols[nLinAdd,nPxPDesc]		:= Round((QSC6->C6_PRUNIT - QSC6->C6_PRCVEN ) / QSC6->C6_PRUNIT * 100,4)				//

					oMulti:aCols[nLinAdd,nPxValor]		:= QSC6->C6_VALOR			//	12
					oMulti:aCols[nLinAdd,nPxValTamp]	:= QSC6->C6_XVLRTAM			//	15
					oMulti:aCols[nLinAdd,nPxCodTab]		:= QSC6->C6_XCODTAB			//	16
					oMulti:aCols[nLinAdd,nPxComis1] 	:= QSC6->C6_COMIS1			//	17
					oMulti:aCols[nLinAdd,nPxComis2]		:= QSC6->C6_COMIS2			//	18
					oMulti:aCols[nLinAdd,nPxCusto]		:= sfCustD(QSC6->C6_PRODUTO,QSC6->C6_QTDVEN,QSC6->SALDOATUAL,QSC6->B2_CM1,QSC6->B1_PROC,QSC6->B1_LOJPROC,QSC6->B1_CUSTD,.F.,QSC6->ARMAZEM)//	19
					oMulti:aCols[nLinAdd,nPxTES]		:= QSC6->C6_TES				//	25
					oMulti:aCols[nLinAdd,nPxCFOP]		:= QSC6->C6_CF				//	26
					oMulti:aCols[nLinAdd,nPxPeso]		:= QSC6->C6_QTDVEN * QSC6->B1_PESO	//	30 D2_PESO
					oMulti:aCols[nLinAdd,nPxAddTamp]	:= QSC6->C6_XFLEX			//	33
					oMulti:aCols[nLinAdd,nPxCm1]		:= sfCustD(QSC6->C6_PRODUTO,QSC6->C6_QTDVEN,QSC6->SALDOATUAL,QSC6->B2_CM1,QSC6->B1_PROC,QSC6->B1_LOJPROC,QSC6->B1_CUSTD,.T.,QSC6->ARMAZEM)// 	34

					// IAGO 26/10/2016 Chamado(16138)
					oMulti:aCols[nLinAdd,nPxUQtd]		:= QRYU->ULTQTD				//	36
					oMulti:aCols[nLinAdd,nPxUPrc]		:= QRYU->ULTPRCVEN			//	37
					oMulti:aCols[nLinAdd,nPxUDat]		:= StoD(QRYU->ULTEMISSAO)	//	38
					oMulti:aCols[nLinAdd,nPxUCndPg]		:= QRYU->ULTCONDPG + "-" + Posicione("SE4",1,xFilial("SE4")+QRYU->ULTCONDPG,"E4_DESCRI")	//	39

					oMulti:Refresh()
				Endif
			Else
				If lCheckPen
					If Alltrim(QSC6->STATUS) == 'Faturado'
						lAdd	:= .F.
					Endif
				Endif
				If lAdd
					cCfopSub	:= QSC6->C6_CF
					nSubCfop	+= QSC6->C6_VALOR
					nSubPrcTab	+= QSC6->C6_PRUNIT * QSC6->C6_QTDVEN
					nSubDesc 	+= (QSC6->C6_PRUNIT - QSC6->C6_PRCVEN ) * QSC6->C6_QTDVEN
					Aadd(oMulti:aCols,aClone(aColsPed))
					nLinAdd++
					oMulti:aCols[nLinAdd,1]				:= IIf(Empty(QSC6->C6_XCODTAB),oVermelho,Iif(QSC6->C6_PRCVEN>=QSC6->C6_PRUNIT,oVerde,oAmarelo) )
					oMulti:aCols[nLinAdd,nPxItem]		:= QSC6->C6_ITEM				//	2
					oMulti:aCols[nLinAdd,nPxSequenc]	:= QSC6->C9_SEQUEN			//	3
					oMulti:aCols[nLinAdd,nPxProd]		:= QSC6->C6_PRODUTO			//	4
					oMulti:aCols[nLinAdd,nPxDescri]		:= QSC6->C6_DESCRI			//	5
					oMulti:aCols[nLinAdd,nPxStatus]		:= QSC6->STATUS				//	6
					oMulti:aCols[nLinAdd,nPxEstoque]	:= QSC6->SALDOATUAL			//	7
					oMulti:aCols[nLinAdd,nPxQtdVen]		:= QSC6->C6_QTDVEN			//	8
					oMulti:aCols[nLinAdd,nPxPrunit]		:= QSC6->C6_PRUNIT			//	9
					oMulti:aCols[nLinAdd,nPxPrcVen]		:= QSC6->C6_PRCVEN			//	10
					oMulti:aCols[nLinAdd,nPxPDesc]		:= Round((QSC6->C6_PRUNIT - QSC6->C6_PRCVEN ) / QSC6->C6_PRUNIT * 100,4)				//
					oMulti:aCols[nLinAdd,nPxValDesc]	:= (QSC6->C6_PRUNIT - QSC6->C6_PRCVEN ) * QSC6->C6_QTDVEN		//	11
					oMulti:aCols[nLinAdd,nPxValor]		:= QSC6->C6_VALOR				//	12
					oMulti:aCols[nLinAdd,nPxValTamp]	:= QSC6->C6_XVLRTAM			//	15
					oMulti:aCols[nLinAdd,nPxPeso]		:= QSC6->C6_QTDVEN * QSC6->B1_PESO	//	30 D2_PESO
					// IAGO 26/10/2016 Chamado(16138)
					oMulti:aCols[nLinAdd,nPxUQtd]		:= QRYU->ULTQTD				//	15
					oMulti:aCols[nLinAdd,nPxUPrc]		:= QRYU->ULTPRCVEN			//	16
					oMulti:aCols[nLinAdd,nPxUDat]		:= StoD(QRYU->ULTEMISSAO)	//	17					
					oMulti:aCols[nLinAdd,nPxUCndPg]		:= QRYU->ULTCONDPG + "-" + Posicione("SE4",1,xFilial("SE4")+QRYU->ULTCONDPG,"E4_DESCRI")//	18
					oMulti:Refresh()
				Endif
			Endif
			DbSelectArea("QSC6")
			DbSkip()

			// IAGO 26/10/2016 Chamado(16138)
			If Select("QRYU") <> 0
				QRYU->(dbCloseArea())
			EndIf
		Enddo
		QSC6->(DbCloseArea())
		If !Empty(cCfopSub) .And. nSubCfop > 0
			dbSelectArea("SX5")
			dbSetOrder(1)

			aRetSX5 := FWGetSX5("13",cCfopSub)
			For nX := 1 to Len(aRetSX5)
				If aRetSX5[nX][1] == cFilSX5
					cNumSx5 := Alltrim(aRetSX5[nX][4])
				EndIf
			Next nX

			If !Empty(cNumSx5)//dbSeek(xFilial("SX5")+"13"+cCfopSub)
				Aadd(oMulti:aCols,aClone(aColsPed))
				nLinAdd++
				If lIsAprovador
					oMulti:aCols[nLinAdd,1] 				:= oColorCTe
					oMulti:aCols[nLinAdd,nPxDescri]		:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
					oMulti:aCols[nLinAdd,nPxValor]		:= nSubCfop
					oMulti:aCols[nLinAdd,nPxCFOP]		:= cCfopSub
					oMulti:aCols[nLinAdd,nPxValDesc]	:= nSubDesc
					oMulti:aCols[nLinAdd,nPxPDesc]		:= Round(nSubDesc/nSubPrcTab*100,4)
				Else
					oMulti:aCols[nLinAdd,1] 				:= oColorCTe
					oMulti:aCols[nLinAdd,nPxDescri]		:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
					oMulti:aCols[nLinAdd,nPxValor]		:= nSubCfop
					oMulti:aCols[nLinAdd,nPxValDesc]	:= nSubDesc
					oMulti:aCols[nLinAdd,nPxPDesc]		:= Round(nSubDesc/nSubPrcTab*100,4)

				Endif
				oMulti:Refresh()
			Endif
			nSubCfop	:= 0
			nSubPrcTab	:= 0
			nSubDesc 	:= 0
		Endif
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cNumPed)

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)

		If SA1->(FieldPos("A1_REFCOM1")) <> 0
			cMsgInt	:= IIf(Empty(SA1->A1_REFCOM1),"","Obs.Log:"+Alltrim(SA1->A1_REFCOM1)+"|") + SC5->C5_MSGINT
		Else
			cMsgInt	:= SC5->C5_MSGINT
		Endif
		oMsgInt:Refresh()
		cMsgNota	:= SC5->C5_MENNOTA
		oMsgNota:Refresh()
		dDtProg	:= SC5->C5_DTPROGM
		oDtProg:Refresh()
		cOrdemCompra	:= SC5->C5_XPEDCLI
		oOrdemCompra:Refresh()

		// Atribui informação do bloqueio comercial
		If SA1->(FieldPos("A1_GERAT")) <> 0
			aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_GERAT', 'X3CBox()' ),,, Len(SA1->A1_GERAT) )
			cRetBox	:= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_GERAT} ), 3 ])
			cBlqCom	:= SA1->A1_GERAT+" - "+cRetBox
		Else
			cBlqCom	:= ""
		Endif
		oBlqCom:Refresh()
		cEndCli	:= Alltrim(SA1->A1_END)+ " Bairro: "+SA1->A1_BAIRRO
		oEndCli:Refresh()

		aDadEntrega	:= sfCalcRota(SC5->C5_TRANSP,SA1->A1_CEP,SA1->A1_ROTA)
		oDiasFat:Refresh()
		oStsRota:Refresh()
		oDataRota:Refresh()


		// Atribui informação da Tabela padrão do Cliente
		DbSelectArea("DA0")
		DbSetOrder(1)
		DbSeek(xFilial("DA0")+SA1->A1_TABELA)
		If SA1->(FieldPos("A1_XTOPCLI")) <> 0
			cTabCli	:= Iif(SA1->A1_XTOPCLI $ "A","CLIENTE TOP<=>","") + SA1->A1_TABELA+" - " + DA0->DA0_DESCRI
		Else
			cTabCli	:= SA1->A1_TABELA+" - " + DA0->DA0_DESCRI
		Endif
		oTabCli:Refresh()

		DbSelectArea("SA4")
		DbSetOrder(1)
		DbSeek(xFilial("SA4")+SC5->C5_TRANSP)
		cTransp := Iif(SC5->C5_TPFRETE == "S","S=Sem Frete ","") + SC5->C5_TRANSP+"-"+SA4->A4_NREDUZ
		oTransp:Refresh()

		cCondPag	:= ""
		DbSelectArea("SE4")
		DbSetOrder(1)
		If dbSeek(xFilial("SE4")+SC5->C5_CONDPAG)
			nQteParc	:= 0
			nDias		:= 0
			aCond 		:= {}
			cCondPag	:= SC5->C5_CONDPAG+"-"+Alltrim(SE4->E4_DESCRI)

			If SC5->C5_CONDPAG == '999'
				If !Empty(SC5->C5_DATA1)
					nQteParc := 1
					nDias := SC5->C5_DATA1 - SC5->C5_EMISSAO
					Aadd(aCond,{SC5->C5_DATA1,1})
				EndIf

				If !Empty(SC5->C5_DATA2)
					nQteParc += 1
					nDias += SC5->C5_DATA2 - SC5->C5_EMISSAO
					Aadd(aCond,{SC5->C5_DATA2,1})
				EndIf

				If !Empty(SC5->C5_DATA3)
					nQteParc += 1
					nDias += SC5->C5_DATA3 - SC5->C5_EMISSAO
					Aadd(aCond,{SC5->C5_DATA3,1})
				EndIf

				If !Empty(SC5->C5_DATA4)
					nQteParc += 1
					nDias += SC5->C5_DATA4 - SC5->C5_EMISSAO
					Aadd(aCond,{SC5->C5_DATA4,1})
				EndIf
				nPrzMed := round(nDias/nQteParc,0)
			Else
				aCond 	:= Condicao(1,SC5->C5_CONDPAG,0,dDataBase)
			Endif

			For nX := 1 to Len(aCond)
				nDias 	+= aCond[nX][1] - dDatabase
				cCondPag	+= " " + DTOC(aCond[nX][1])
			Next
			nPrzMed := Round(nDias / Len(aCond),0)
			cCondPag	+= " Média: " + Transform(nPrzMed,"@E 999")+" Dias"
		Endif
		oCondPag:Refresh()

		If lIsAprovador
			sfSC5Impostos(cNumPed)
		Else
			// Zero variavel de R$ Total
			aSubValores[9]	:= 0
			// Zero variavel de Peso Kg
			aSubValores[13]	:= 0
			For iZ := 1 To Len(oMulti:aCols)
				If !oMulti:aCols[iZ,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[iZ,nPxItem])
					aSubValores[9] 	+= (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])
					aSubValores[13] 	+= oMulti:aCols[iZ,nPxPeso]
				Endif
			Next
			oSubValores[9]:Refresh()
			oSubValores[13]:Refresh()
			aSubValores[22]:= SC5->C5_FRETE
			oSubValores[22]:Refresh()
		Endif

	Else
		cQry += "SELECT UB_ITEM,"
		cQry += "       UB_PRODUTO,"
		cQry += "       UB_COMIS1,"
		cQry += "       UB_COMIS2,"
		cQry += "       UB_LOCAL + ' - ' + B1_DESC B1_DESC,
		cQry += "       UB_LOCAL ARMAZEM,
		cQry += "       UB_QUANT,"
		cQry += "       UB_PRCTAB,"
		cQry += "       UB_VALDESC,"
		cQry += "       UB_VRUNIT,"
		cQry += "       UB_VLRITEM,"
		cQry += "       UB_XCODTAB,"
		cQry += "       (UB_QUANT*UB_XVLRTAM) UB_XVLRTAM,"
		cQry += "       (UB_QUANT*UB_XFLEX) UB_XFLEX,"
		cQry += "       (UB_QUANT*ISNULL(B2_CM1,B1_CUSTD)) B2_CM1," // Se não existir custo de estoque assume
		cQry += "       UB_CF,"
		cQry += "       UB_TES,"
		cQry += "       ISNULL(B2_QATU-B2_RESERVA,0) SALDOATUAL,"
		cQry += "       '  ' SEQUEN, "
		cQry += "       CASE WHEN UB_XALCADA = ' ' THEN 'Ok' ELSE 'Alçada/A Liberar' END STATUS, "
		cQry += "       B1_PESBRU B1_PESO, "
		cQry += "       B1_PROC,"
		cQry += "       B1_LOJPROC, "
		cQry += "       B1_CUSTD, "
		cQry += "       UA.UA_CLIENTE,"
		cQry += "       UA.UA_LOJA"
		cQry += "  FROM "+RetSqlName("SUB")+ " UB "
		cQry += " INNER JOIN " + RetSqlName("SB1") + " B1 " 
		cQry += "    ON B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_COD = UB_PRODUTO "
		cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
		cQry += " INNER JOIN " + RetSqlName("SUA") + " UA "
		cQry += "    ON UA.UA_FILIAL = UB.UB_FILIAL"
		cQry += "   AND UA.UA_NUM = UB.UB_NUM"
		cQry += "   AND UA.D_E_L_E_T_ = ' '"
		cQry += "  LEFT JOIN " + RetSqlName("SB2") + " B2 "
		cQry += "    ON B2.D_E_L_E_T_  =' ' "
		cQry += "   AND B2_LOCAL  = UB_LOCAL "
		cQry += "   AND B2_COD  = UB_PRODUTO "
		cQry += "   AND B2_FILIAL  = '"+xFilial("SB2") + "' "
		cQry += " WHERE UB.D_E_L_E_T_ =' ' "
		cQry += "   AND UB_NUM = '"+cNumPed+"' "
		cQry += "   AND UB_FILIAL = '"+xFilial("SUB")+"' "
		cQry += " ORDER BY UB_CF,UB_ITEM "


		dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSC6', .F., .T.)

		While !Eof()

			// IAGO 26/10/2016 Chamado(16138)
			cQryU := "SELECT D2.D2_QUANT   AS ULTQTD,"
			cQryU += "       D2.D2_PRCVEN  AS ULTPRCVEN,"
			cQryU += "       D2.D2_EMISSAO AS ULTEMISSAO,"
			cQryU += "       (SELECT C5_CONDPAG "
			cQryU += "          FROM " + RetSqlName("SC5") + " C5 "
			cQryU += "         WHERE C5.D_E_L_E_T_ =' ' "
			cQryU += "           AND C5_NUM = D2_PEDIDO "
			cQryU += "           AND C5_FILIAL = '" + xFilial("SC5") + "') ULTCONDPG"
			cQryU += "  FROM "+RetSqlName("SD2")+ " D2"
			cQryU += " WHERE D2.R_E_C_N_O_ = (SELECT MAX(D22.R_E_C_N_O_)"
			cQryU += "          FROM "+RetSqlName("SD2")+ " D22"
			cQryU += "         INNER JOIN "+RetSqlName("SF4")+ " F4 "
			cQryU += "            ON F4.F4_FILIAL = D22.D2_FILIAL"
			cQryU += "           AND F4.F4_CODIGO = D22.D2_TES"
			cQryU += "           AND F4.F4_ESTOQUE = 'S'"
			cQryU += "           AND F4.F4_DUPLIC = 'S'"
			cQryU += "           AND F4.D_E_L_E_T_ = ' '"
			cQryU += "         WHERE D22.D2_FILIAL = '"+ xFilial("SD2") +"'"
			cQryU += "           AND D22.D2_CLIENTE = '"+ QSC6->UA_CLIENTE +"'"
			cQryU += "           AND D22.D2_LOJA = '"+ QSC6->UA_LOJA +"'"
			cQryU += "           AND D22.D_E_L_E_T_ = ' '"
			cQryU += "           AND D22.D2_COD = '"+ QSC6->UB_PRODUTO +"'"
			cQryU += "           AND D22.D2_EMISSAO >= '"+DTOS(Date()-360)+"')"

			If Select("QRYU") <> 0
				QRYU->(dbCloseArea())
			EndIf

			TCQuery cQryU New Alias "QRYU"

			If !Empty(cCfopSub) .And. cCfopSub <> QSC6->UB_CF
				//dbSelectArea("SX5")
				//dbSetOrder(1)
				aRetSX5 := FWGetSX5("13",cCfopSub)
				For nX := 1 to Len(aRetSX5)
					If aRetSX5[nX][1] == cFilSX5
						cNumSx5 := Alltrim(aRetSX5[nX][4])
					EndIf
				Next nX

				If !Empty(cNumSx5)//dbSeek(xFilial("SX5")+"13"+cCfopSub)
					Aadd(oMulti:aCols,aClone(aColsPed))
					nLinAdd++
					If lIsAprovador
						oMulti:aCols[nLinAdd,1] 		:= oColorCTe
						oMulti:aCols[nLinAdd,nPxDescri]	:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
						oMulti:aCols[nLinAdd,nPxValor]	:= nSubCfop
						oMulti:aCols[nLinAdd,nPxCFOP]	:= cCfopSub
						oMulti:aCols[nLinAdd,nPxValDesc]:= nSubDesc
						oMulti:aCols[nLinAdd,nPxPDesc]	:= Round(nSubDesc/nSubPrcTab*100,4)
					Else
						oMulti:aCols[nLinAdd,1] 		:= oColorCTe
						oMulti:aCols[nLinAdd,nPxDescri]	:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
						oMulti:aCols[nLinAdd,nPxValor]	:= nSubCfop
						oMulti:aCols[nLinAdd,nPxValDesc]:= nSubDesc
						oMulti:aCols[nLinAdd,nPxPDesc]	:= Round(nSubDesc/nSubPrcTab*100,4)
					Endif
					oMulti:Refresh()
				Endif
				nSubCfop	:= 0
			Endif

			cCfopSub	:= QSC6->UB_CF
			nSubCfop	+= QSC6->UB_VLRITEM
			nSubPrcTab	+= QSC6->UB_PRCTAB * QSC6->UB_QUANT
			nSubDesc 	+= (QSC6->UB_PRCTAB-QSC6->UB_VRUNIT) * 	QSC6->UB_QUANT
			Aadd(oMulti:aCols,aClone(aColsPed))
			nLinAdd++
			If lIsAprovador
				oMulti:aCols[nLinAdd,1]				:= IIf(Empty(QSC6->UB_XCODTAB),oVermelho,Iif(QSC6->UB_VRUNIT>=QSC6->UB_PRCTAB,oVerde,oAmarelo) )
				oMulti:aCols[nLinAdd,nPxItem]		:= QSC6->UB_ITEM			//	2
				oMulti:aCols[nLinAdd,nPxSequenc]	:= QSC6->SEQUEN				//	3
				oMulti:aCols[nLinAdd,nPxProd]		:= QSC6->UB_PRODUTO			//	4
				oMulti:aCols[nLinAdd,nPxDescri]		:= QSC6->B1_DESC			//	5
				oMulti:aCols[nLinAdd,nPxStatus]		:= QSC6->STATUS				//	6
				oMulti:aCols[nLinAdd,nPxEstoque]	:= QSC6->SALDOATUAL			//	7
				oMulti:aCols[nLinAdd,nPxQtdVen]		:= QSC6->UB_QUANT			//	8
				oMulti:aCols[nLinAdd,nPxPrunit]		:= QSC6->UB_PRCTAB			//	9
				oMulti:aCols[nLinAdd,nPxPrcVen]		:= QSC6->UB_VRUNIT			//	10
				oMulti:aCols[nLinAdd,nPxValDesc]	:= (QSC6->UB_PRCTAB-QSC6->UB_VRUNIT) * 	QSC6->UB_QUANT			//	11
				oMulti:aCols[nLinAdd,nPxPDesc]		:= Round( (QSC6->UB_PRCTAB-QSC6->UB_VRUNIT) / QSC6->UB_PRCTAB * 100,4)
				oMulti:aCols[nLinAdd,nPxValor]		:= QSC6->UB_VLRITEM			//	12
				oMulti:aCols[nLinAdd,nPxValTamp]	:= QSC6->UB_XVLRTAM			//	15
				oMulti:aCols[nLinAdd,nPxCodTab]		:= QSC6->UB_XCODTAB			//	16
				oMulti:aCols[nLinAdd,nPxComis1] 	:= QSC6->UB_COMIS1			//	17
				oMulti:aCols[nLinAdd,nPxComis2]		:= QSC6->UB_COMIS2			//	18
				oMulti:aCols[nLinAdd,nPxCusto]		:= sfCustD(QSC6->UB_PRODUTO,QSC6->UB_QUANT,QSC6->SALDOATUAL,QSC6->B2_CM1,QSC6->B1_PROC,QSC6->B1_LOJPROC,QSC6->B1_CUSTD,.F.,QSC6->ARMAZEM)//	19 QSC6->B2_CM1				//	19
				oMulti:aCols[nLinAdd,nPxTES]		:= QSC6->UB_TES				//	25
				oMulti:aCols[nLinAdd,nPxCFOP]		:= QSC6->UB_CF				//	26
				oMulti:aCols[nLinAdd,nPxPeso]		:= QSC6->UB_QUANT*QSC6->B1_PESO	//	30 D2_PESO
				oMulti:aCols[nLinAdd,nPxAddTamp]	:= QSC6->UB_XFLEX			//	33
				oMulti:aCols[nLinAdd,nPxCm1]		:= sfCustD(QSC6->UB_PRODUTO,QSC6->UB_QUANT,QSC6->SALDOATUAL,QSC6->B2_CM1,QSC6->B1_PROC,QSC6->B1_LOJPROC,QSC6->B1_CUSTD,.T.,QSC6->ARMAZEM)// 	34

				// IAGO 26/10/2016 Chamado(16138)
				oMulti:aCols[nLinAdd,nPxUQtd]		:= QRYU->ULTQTD				//	36
				oMulti:aCols[nLinAdd,nPxUPrc]		:= QRYU->ULTPRCVEN			//	37
				oMulti:aCols[nLinAdd,nPxUDat]		:= StoD(QRYU->ULTEMISSAO)	//	38
				oMulti:aCols[nLinAdd,nPxUCndPg]		:= QRYU->ULTCONDPG + "-" + Posicione("SE4",1,xFilial("SE4")+QRYU->ULTCONDPG,"E4_DESCRI")	//	39

				oMulti:Refresh()

			Else
				oMulti:aCols[nLinAdd,1]				:= IIf(Empty(QSC6->UB_XCODTAB),oVermelho,Iif(QSC6->UB_VRUNIT>=QSC6->UB_PRCTAB,oVerde,oAmarelo) )
				oMulti:aCols[nLinAdd,nPxItem]		:= QSC6->UB_ITEM				//	2
				oMulti:aCols[nLinAdd,nPxSequenc]	:= QSC6->SEQUEN				//	3
				oMulti:aCols[nLinAdd,nPxProd]		:= QSC6->UB_PRODUTO			//	4
				oMulti:aCols[nLinAdd,nPxDescri]		:= QSC6->B1_DESC				//	5
				oMulti:aCols[nLinAdd,nPxStatus]		:= QSC6->STATUS				//	6
				oMulti:aCols[nLinAdd,nPxEstoque]	:= QSC6->SALDOATUAL			//	7
				oMulti:aCols[nLinAdd,nPxQtdVen]		:= QSC6->UB_QUANT				//	8
				oMulti:aCols[nLinAdd,nPxPrunit]		:= QSC6->UB_PRCTAB			//	9
				oMulti:aCols[nLinAdd,nPxPrcVen]		:= QSC6->UB_VRUNIT			//	10
				oMulti:aCols[nLinAdd,nPxPDesc]		:= Round( (QSC6->UB_PRCTAB-QSC6->UB_VRUNIT) / QSC6->UB_PRCTAB * 100,4)
				oMulti:aCols[nLinAdd,nPxValDesc]	:= (QSC6->UB_PRCTAB-QSC6->UB_VRUNIT) * 	QSC6->UB_QUANT			//	11
				oMulti:aCols[nLinAdd,nPxValor]		:= QSC6->UB_VLRITEM			//	12
				oMulti:aCols[nLinAdd,nPxValTamp]	:= QSC6->UB_XVLRTAM			//	15
				oMulti:aCols[nLinAdd,nPxPeso]		:= QSC6->UB_QUANT*QSC6->B1_PESO	//	30 D2_PESO

				// IAGO 26/10/2016 Chamado(16138)
				oMulti:aCols[nLinAdd,nPxUQtd]		:= QRYU->ULTQTD				//	15
				oMulti:aCols[nLinAdd,nPxUPrc]		:= QRYU->ULTPRCVEN			//	16
				oMulti:aCols[nLinAdd,nPxUDat]		:= StoD(QRYU->ULTEMISSAO)	//	17
				oMulti:aCols[nLinAdd,nPxUCndPg]		:= QRYU->ULTCONDPG + "-" + Posicione("SE4",1,xFilial("SE4")+QRYU->ULTCONDPG,"E4_DESCRI")	//	18

				oMulti:Refresh()

			Endif
			If Select("QRYU") <> 0
				QRYU->(dbCloseArea())
			EndIf

			DbSelectArea("QSC6")
			DbSkip()			
		Enddo
		QSC6->(DbCloseArea())

		If !Empty(cCfopSub)
			//dbSelectArea("SX5")
			//dbSetOrder(1)
			aRetSX5 := FWGetSX5("13",cCfopSub)
			For nX := 1 to Len(aRetSX5)
				If aRetSX5[nX][1] == cFilSX5
					cNumSx5 := Alltrim(aRetSX5[nX][4])
				EndIf
			Next nX

			If !Empty(cNumSx5)//dbSeek(xFilial("SX5")+"13"+cCfopSub)
				Aadd(oMulti:aCols,aClone(aColsPed))
				nLinAdd++
				If lIsAprovador
					oMulti:aCols[nLinAdd,1] 		:= oColorCTe
					oMulti:aCols[nLinAdd,nPxDescri]	:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
					oMulti:aCols[nLinAdd,nPxValor]	:= nSubCfop
					oMulti:aCols[nLinAdd,nPxCFOP]	:= cCfopSub
					oMulti:aCols[nLinAdd,nPxValDesc]	:= nSubDesc
					oMulti:aCols[nLinAdd,nPxPDesc]		:= Round(nSubDesc/nSubPrcTab*100,4)
				Else
					oMulti:aCols[nLinAdd,1] 			:= oColorCTe
					oMulti:aCols[nLinAdd,nPxDescri]	:= cCfopSub+"--"+cNumSx5//SX5->X5_DESCRI
					oMulti:aCols[nLinAdd,nPxValor]	:= nSubCfop
					oMulti:aCols[nLinAdd,nPxValDesc]	:= nSubDesc
					oMulti:aCols[nLinAdd,nPxPDesc]		:= Round(nSubDesc/nSubPrcTab*100,4)
				Endif
				oMulti:Refresh()
			Endif
			nSubCfop	:= 0
			nSubPrcTab	:= 0
			nSubDesc 	:= 0
		Endif
		DbSelectArea("SUA")
		DbSetOrder(1)
		DbSeek(xFilial("SUA")+cNumPed)

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA)

		If SA1->(FieldPos("A1_REFCOM1")) <> 0
			cMsgInt	:= IIf(Empty(SA1->A1_REFCOM1),"","Obs.Log:"+Alltrim(SA1->A1_REFCOM1)+"|") + SUA->UA_MSGINT
		Else
			cMsgInt	:= SUA->UA_MSGINT
		Endif
		oMsgInt:Refresh()
		cMsgNota	:= SUA->UA_MENNOTA
		oMsgNota:Refresh()
		dDtProg	:= SUA->UA_DTPROGM
		oDtProg:Refresh()
		cOrdemCompra	:= SUA->UA_XPEDCLI
		oOrdemCompra:Refresh()

		// Atribui informação do bloqueio comercial
		If SA1->(FieldPos("A1_GERAT")) <> 0
			aRetBox := RetSx3Box( Posicione('SX3', 2, 'A1_GERAT', 'X3CBox()' ),,, Len(SA1->A1_GERAT) )
			cRetBox	:= AllTrim( aRetBox[ Ascan( aRetBox, { |x| x[ 2 ] == SA1->A1_GERAT} ), 3 ])
			cBlqCom	:= SA1->A1_GERAT+" - "+cRetBox
		Endif
		oBlqCom:Refresh()
		cEndCli	:= Alltrim(SA1->A1_END)+ " Bairro: "+SA1->A1_BAIRRO
		oEndCli:Refresh()

		aDadEntrega	:= sfCalcRota(SUA->UA_TRANSP,SA1->A1_CEP,SA1->A1_ROTA)
		oDiasFat:Refresh()
		oStsRota:Refresh()
		oDataRota:Refresh()

		// Atribui informação da Tabela padrão do Cliente
		DbSelectArea("DA0")
		DbSetOrder(1)
		DbSeek(xFilial("DA0")+SA1->A1_TABELA)
		If SA1->(FieldPos("A1_XTOPCLI")) <> 0
			cTabCli	:= Iif(SA1->A1_XTOPCLI $ "A","CLIENTE TOP<=>","") + SA1->A1_TABELA+" - " + DA0->DA0_DESCRI
		Else
			cTabCli	:= SA1->A1_TABELA+" - " + DA0->DA0_DESCRI
		Endif
		oTabCli:Refresh()

		DbSelectArea("SA4")
		DbSetOrder(1)
		DbSeek(xFilial("SA4")+SUA->UA_TRANSP)
		cTransp := SUA->UA_TRANSP+"-"+SA4->A4_NREDUZ
		oTransp:Refresh()

		cCondPag	:= ""
		DbSelectArea("SE4")
		DbSetOrder(1)
		If dbSeek(xFilial("SE4")+SUA->UA_CONDPG)
			nQteParc	:= 0
			nDias		:= 0
			aCond 		:= {}
			cCondPag	:= SUA->UA_CONDPG+"-"+Alltrim(SE4->E4_DESCRI)

			If SUA->UA_CONDPG == '999'
				If !Empty(SC5->C5_DATA1)
					nQteParc := 1
					nDias := SUA->UA_DATA1 - SUA->UA_EMISSAO
					Aadd(aCond,{SUA->UA_DATA1,1})
				EndIf

				If !Empty(SUA->UA_DATA2)
					nQteParc += 1
					nDias += SUA->UA_DATA2 - SUA->UA_EMISSAO
					Aadd(aCond,{SUA->UA_DATA2,1})
				EndIf

				If !Empty(SUA->UA_DATA3)
					nQteParc += 1
					nDias += SUA->UA_DATA3 - SUA->UA_EMISSAO
					Aadd(aCond,{SUA->UA_DATA3,1})
				EndIf

				If !Empty(SUA->UA_DATA4)
					nQteParc += 1
					nDias += SUA->UA_DATA4 - SUA->UA_EMISSAO
					Aadd(aCond,{SUA->UA_DATA4,1})
				EndIf
				nPrzMed := round(nDias/nQteParc,0)
			Else
				aCond 	:= Condicao(1,SUA->UA_CONDPG,0,dDataBase)
			Endif

			For nX := 1 to Len(aCond)
				nDias 	+= aCond[nX][1] - dDatabase
				cCondPag	+= " " + DTOC(aCond[nX][1])
			Next
			nPrzMed := Round(nDias / Len(aCond),0)
			cCondPag	+= " Média: " + Transform(nPrzMed,"@E 999")+" Dias"
		Endif
		oCondPag:Refresh()

		If lIsAprovador
			sfSUAImpostos(cNumPed)
		Else
			// Zero variavel de R$ Total
			aSubValores[9]	:= 0
			// Zero variavel de Peso Kg
			aSubValores[13]	:= 0
			For iZ := 1 To Len(oMulti:aCols)
				If !oMulti:aCols[iZ,Len(oMulti:aHeader)+1] .And. !Empty(oMulti:aCols[iZ,nPxItem])
					aSubValores[9] 	+= (oMulti:aCols[iZ,nPxQtdVen]*oMulti:aCols[iZ,nPxPrcVen])
					aSubValores[13] 	+= oMulti:aCols[iZ,nPxPeso]
				Endif
			Next
			oSubValores[9]:Refresh()
			oSubValores[13]:Refresh()
			aSubValores[22] := SUA->UA_FRETE
			oSubValores[22]:Refresh()
		Endif

	Endif
	oMulti:oBrowse:Refresh()

	aHistCli 	:= {SA1->A1_PRICOM,SA1->A1_ULTCOM,SA1->A1_NROCOM,IIf(Empty(SA1->A1_ULTCOM),0,Date() - SA1->A1_ULTCOM)}
	oHistCli[1]:Refresh()
	oHistCli[2]:Refresh()
	oHistCli[3]:Refresh()
	oHistCli[4]:Refresh()


	aListLog	:= {}
	cQry := "SELECT Z9_DATA,Z9_HORA,Z9_EVENTO,Z9_DESCR,Z9_DEST,Z9_USER,Z9.R_E_C_N_O_ Z9RECNO"
	cQry += "  FROM "+RetSqlName("SZ9") + " Z9 "
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND Z9_ORIGEM = '" + Iif( MV_PAR07 == 1,"P","O")+"' "
	cQry += "   AND Z9_NUM = '"+cNumPed+"' "
	cQry += "   AND Z9_FILIAL = '"+xFilial("SZ9")+"' "
	If MV_PAR07 == 1
		cQry += "UNION ALL "
		cQry += "SELECT Z9_DATA,Z9_HORA,Z9_EVENTO,Z9_DESCR,Z9_DEST,Z9_USER,Z9.R_E_C_N_O_ Z9RECNO"
		cQry += "  FROM "+RetSqlName("SZ9") + " Z9, "  + RetSqlName("SUA")  + " UA "
		cQry += " WHERE Z9.D_E_L_E_T_ = ' ' "
		cQry += "   AND Z9_NUM = UA_NUM "
		cQry += "   AND Z9_ORIGEM = 'O' "
		cQry += "   AND Z9_FILIAL = '"+xFilial("SZ9")+"' "
		cQry += "   AND UA.D_E_L_E_T_ =' ' "
		cQry += "   AND UA_NUMSC5 = '"+cNumPed+"' "
		cQry += "   AND UA_FILIAL = '" +xFilial("SUA")+ "' "
	Endif
	cQry += " ORDER BY 7 DESC "

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QZ9', .F., .T.)

	While !Eof()
		Aadd(aListLog,{	STOD(QZ9->Z9_DATA),;
			QZ9->Z9_HORA,;
			sfRetOpc(QZ9->Z9_EVENTO),;
			IIf(QZ9->Z9_USER <"99999" .And. QZ9->Z9_USER >"00000", UsrRetName(QZ9->Z9_USER),QZ9->Z9_USER),;
			QZ9->Z9_DESCR,;
			QZ9->Z9_DEST,;
			QZ9->Z9RECNO})
		DbSelectArea("QZ9")
		QZ9->(DbSkip())
	Enddo
	QZ9->(DbCloseArea())
	If Len(aListLog)== 0
		aListLog	:= {{"","","","","","",0}}
	Endif
	If oArqLog:nAT > Len(aListLog)
		oArqLog:nAT	:= Len(aListLog)
	Endif
	oArqLog:SetArray(aListLog)
	oArqLog:bLine:= { || {aListLog[oArqLog:nAT,1],;
		aListLog[oArqLog:nAT,2],;
		aListLog[oArqLog:nAT,3],;
		aListLog[oArqLog:nAT,4],;
		aListLog[oArqLog:nAT,5],;
		aListLog[oArqLog:nAT,6],;
		aListLog[oArqLog:nAT,7]} }
	oArqLog:Refresh()



Return lRet


/*/{Protheus.doc} sfRetOpc
(Retornar lista de opções de followup de pedidos)
@author MarceloLauschner
@since 03/06/2014
@version 1.0
@param cInOpc, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRetOpc(cInOpc)
	
	Local	aOpcRet	:= {	{"1","1-Envio de e-mail para aprovação"},;
		{"2","2-Follow-up de comunicação"},;
		{"3","3-Rejeição de liberação de Pedido"},;
		{"4","4-Aprovação e liberação de Pedido"},;
		{"5","5-Liberação Pedido"},;
		{"6","6-Envio de Workflow"},;
		{"7","7-Liberação Automática Pedido-Callcenter"},;
		{"8","8-Solicitação de Alçada Price"},;
		{"9","9-Solicitação de Alçada Diretoria"}}
	Local	nV 
	 	
	For nV	:= 1 To Len(aOpcRet)
		If aOpcRet[nV,1] == cInOpc
			Return aOpcRet[nV,2]
		Endif
	Next
	
Return ""

/*/{Protheus.doc} AjustaSX1
(Cria perguntas para uso da Rotina)
@author MarceloLauschner
@since 21/04/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function AjustaSX1()

	DbSelectArea("SX6")
	DbSetOrder(1)

	// Se executado o Wizard, irá limpar o parametro de controle de
	If !DbSeek(cFilAnt+"BF_FTA30HR")
		RecLock("SX6",.T.)
		SX6->X6_FIL     := cFilAnt
		SX6->X6_VAR     := "BF_FTA30HR"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "Horario limite para envio Pedidos BFFATA30"
		MsUnLock()
		PutMv("BF_FTA30HR","15:00:00")
	Endif

Return



/*/{Protheus.doc} sfMat455
(Liberação do Pedido de Venda com chamada da rotina de Liberação de Alçada)
@author MarceloLauschner
@since 21/04/2014
@version 1.0
@return Sem retorno
@example
(examples)
@see (links_or_references)
/*/
Static Function sfMat455()

	Local		aAreaOld	:= GetArea()

	// Declaro o filtro adicional do ponto de entrada M456FIL
	Private 	cFilNumSC9 	:= aListPed[oArqPed:nAt,3]
	Private		cFilCliSC9

	If MV_PAR07==2
		If U_FOR007(cFilNumSC9,"O")
			ConOut("Liberou com sucesso Orçamento "+cFilNumSC9)
		Endif
		// Se o pedido estiver pendente de liberação de alçada
	ElseIf aListPed[oArqPed:nAt,8] > 0
		// Verifica se alçada retornou verdadeiro
		If U_FOR007(cFilNumSC9)
			DbSelectArea("SC5")
			DbSetOrder(1)
			DbSeek(xFilial("SC5")+cFilNumSC9)

			Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)

			U_GMCFGM01("LP"/*cTipo*/,cFilNumSC9/*cPedido*/,/*cObserv*/,FunName()/*cResp*/,/*lBtnCancel*/,/*cMotDef*/,/*lAutoExec*/)

			U_BFFATA35("P"/*cZ9ORIGEM*/,cFilNumSC9/*cZ9NUM*/,"5"/*cZ9EVENTO*/,FunName()/*cZ9DESCR*/,/*cZ9DEST*/,cUserName/*cZ9USER*/)
		Endif
		//cFilCliSC9	:= SC5->C5_CLIENTE
		// Ao liberar a alçada do pedido já chama a liberação do mesmo
		//Mata440()
		// Não estiver na alçada e houver uma pendência para liberação
	ElseIf aListPed[oArqPed:nAt,8] == 0 .And. (aListPed[oArqPed:nAt,7]-aListPed[oArqPed:nAt,9]-aListPed[oArqPed:nAt,10]-aListPed[oArqPed:nAt,11]-aListPed[oArqPed:nAt,12]) > 0
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cFilNumSC9)

		If MsgYesNo("Deseja realmente liberar o pedido?","Liberação de pedido")
			Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)

			U_GMCFGM01(	"LP"/*cTipo*/,cFilNumSC9/*cPedido*/,/*cObserv*/,FunName()/*cResp*/,/*lBtnCancel*/,/*cMotDef*/,/*lAutoExec*/,)

			U_BFFATA35("P"/*cZ9ORIGEM*/,cFilNumSC9/*cZ9NUM*/,"5"/*cZ9EVENTO*/,FunName()/*cZ9DESCR*/,/*cZ9DEST*/,/*cZ9USER*/)

		Endif
		// Alçada = 0  e 5=Valor - 13=Faturado - 6=Residuo - 9=Liberado - 10=Bloq.Estoque - 11=Credito > 0
	ElseIf aListPed[oArqPed:nAt,8] == 0 .And. (aListPed[oArqPed:nAt,5]-aListPed[oArqPed:nAt,13]-aListPed[oArqPed:nAt,6]-aListPed[oArqPed:nAt,9]-aListPed[oArqPed:nAt,10]-aListPed[oArqPed:nAt,11]) > 0
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5")+cFilNumSC9)

		If MsgYesNo("Deseja realmente liberar o pedido?","Liberação de pedido")
			Ma410LbNfs(2/*nTipo*/,/*aPvlNfs*/,/*aBloqueio*/)

			U_GMCFGM01(	"LP"/*cTipo*/,cFilNumSC9/*cPedido*/,/*cObserv*/,FunName()/*cResp*/,/*lBtnCancel*/,/*cMotDef*/,/*lAutoExec*/,)

			U_BFFATA35("P"/*cZ9ORIGEM*/,cFilNumSC9/*cZ9NUM*/,"5"/*cZ9EVENTO*/,FunName()/*cZ9DESCR*/,/*cZ9DEST*/,/*cZ9USER*/)

		Endif

		//cFilCliSC9	:= SC5->C5_CLIENTE
		// Ao liberar a alçada do pedido já chama a liberação do mesmo
		//Mata440()
	Else
		MsgAlert("Pedido não tem pendência de liberação alçada!","'BFFATA30.PRW.sfMat455' - A T E N Ç Ã O!")
	Endif


	Eval(bRefrXmlF)

	RestArea(aAreaOld)

Return




/*/{Protheus.doc} stVerLog
(long_description)
@author MarceloLauschner
@since 15/04/2014
@version 1.0
@param cInPedido, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stVerLog()

	Local		oPed2
	Local		lOk			:= .F.
	Private	cZ0Filial	:= xFilial("SZ0")

	If MV_PAR07==1

		Private cPedSZ0		:= aListPed[oArqPed:nAt,3]

		DEFINE MSDIALOG oPed2 FROM 000,000 TO 0120,400 Of oMainWnd Pixel Title OemToAnsi("Consulta Log pedidos" )
		@ 035,005 Say "Número Pedido" of oPed2 Pixel
		@ 035,050 MsGet cPedSZ0	Size 40,10 Valid ExistCpo("SC5",cPedSZ0)  of oPed2 Pixel

		Activate MsDialog oPed2 On Init EnchoiceBar(oPed2,{|| lOk := .T., oPed2:End() },{|| oPed2:End()},,)

		If lOk
			dbSelectArea("SZ0")
			dbSetOrder(1)
			Set Filter To (SZ0->Z0_FILIAL == cZ0Filial .And. SZ0->Z0_PEDIDO == cPedSZ0)

			AxCadastro("SZ0","Historico Pedido - Workflow",".F.",".F.")

			dbSelectArea("SZ0")
			dbSetOrder(1)
			Set Filter To
		Endif

	Endif

Return



/*/{Protheus.doc} sfCalcRota
(Devolve informação de rota de faturamento)
@author MarceloLauschner
@since 15/04/2014
@version 1.0
@param cCodTransp, character, (Descrição do parâmetro)
@param cCEP, character, (Descrição do parâmetro)
@param cA1_ROTA, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCalcRota(cCodTransp,cCEP,cA1_ROTA)


	Local	cStsRota 	:= Space(10)
	//Local	cRota		:=" "
	//Local	nDiaAtu  	:= 0
	Local	nDiaEnt  	:= 0
	Local	dData    	:= dDataBase
	Local	aRota    	:= {}
	//Local	aDias    	:= {1,2,3,4,5,6,7}
	Local	cDiasFat 	:= "     "
	Local	cPrzEnt	:= "      "
	Local	x
	Dbselectarea("SA4")
	dbsetorder(1)
	Dbseek(xFilial("SA4")+cCodTransp)

	dbSelectArea("PAB")
	dbSetOrder(1)
	If DbSeek(xFilial("PAB")+cCEP)
		For x := 1 To Len(AllTrim(PAB->PAB_ROTA)) Step 1
			AADD(aRota,{SubStr(PAB->PAB_ROTA,x,1)})
		Next
		cDiasFat := PAB->PAB_ROTA
		cPrzEnt  := PAB->PAB_PRAZO
	Endif

	If cA1_ROTA <> Nil .And. cA1_ROTA <> " "
		For x := 1 To Len(AllTrim(QRG->A1_ROTA)) Step 1
			AADD(aRota,{SubStr(cA1_ROTA,x,1)})
		Next
	Endif

	nDia := Dow(dDatabase)
	If Len(aRota) > 0
		While .T.
			If nDia > 7
				nDia := 1
			Endif
			nPos := aScan(aRota,{|x| Val(x[1]) == nDia})
			If !Empty(nPos)
				nDiaEnt := Val(aRota[nPos][1])
				If nDiaEnt == Dow(dDatabase)
					dData := dDatabase
				Elseif (nDiaEnt - Dow(dDatabase)) > 0
					dData   := dDatabase + (nDiaEnt - Dow(dDatabase))
				Else
					dData   := (7 - Dow(dDatabase)) + nDiaEnt + dDatabase
				Endif
				Exit
			Endif
			nDia++
		End
	Endif

	If dData == dDatabase
		cStsRota := "É ROTA"
	Else
		cStsRota := "NÃO É ROTA"
	Endif

Return {cStsRota,dData,cDiasFat,cPrzEnt}


/*/{Protheus.doc} sfLegCab
(Legenda do Listbox e Getdados)
@author MarceloLauschner
@since 21/04/2014
@version 1.0
@param nOpcLeg, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@examples
(examples)
//@see (links_or_references)
/*/
Static Function sfLegCab(nOpcLeg)

	Local	aCores := {}

	If MV_PAR07 == 1 .And. nOpcLeg == 1
		Aadd(aCores,{"BR_VIOLETA"	,"Pedido Sem Restrições"})
		Aadd(aCores,{"BR_VERMELHO"	,"Pedido Totalmente Faturado"})
		Aadd(aCores,{"BR_VERDE"		,"Pedido c/Pendência Alçada"})
		Aadd(aCores,{"BR_AMARELO"	,"Pedido c/Bloqueio Crédito"})
		Aadd(aCores,{"BR_AZUL"		,"Pedido c/Bloqueio Estoque"})
		Aadd(aCores,{"BR_CINZA"		,"Pedido c/Crédito Rejeitado"})
		Aadd(aCores,{"BR_PINK"		,"Pedido c/Resíduo Eliminado"})
		Aadd(aCores,{"BR_LARANJA"	,"Pedido c/Pendência Financeira"})
		Aadd(aCores,{"BR_PRETO"		,"Pedido c/Pendência Comercial"})
		Aadd(aCores,{"BR_CANCEL"		,"Pedido Pendente"})
		Aadd(aCores,{"LBNO"		,"Pedido c/Pagamento Antecipado"})
	ElseIf MV_PAR07 == 1 .And. nOpcLeg == 2

	ElseIf MV_PAR07 == 2 .And. nOpcLeg == 1
		Aadd(aCores,{"BR_VIOLETA"	,"Orçamentos CallCenter"})
	ElseIf MV_PAR07 == 2 .And. nOpcLeg == 2


	Endif

	BrwLegenda("'BFFATA30.PRW.sfLegCab' - Análise Pedidos/Cotações","Legenda",aCores)

	oArqPed:SetFocus()

Return (.T.)


/*/{Protheus.doc} sfResiduo
(Eliminar resíduo do pedido de venda posicionada)
@author MarceloLauschner
@since 21/04/2014
@version 1.0
@param cPedRes, character, (Número do pedido)
@return Nil
@example
(examples)
@see (links_or_references)
/*/
Static Function sfResiduo(cPedRes)

	Local 		aAreaOld		:= GetArea()
	Local		aSC6Bk			:= {}
	//Local		cMotBlq		:= ""
	Local		cPergMta		:= ""
	Local		aRestPerg		:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)
	Local		iZ
	Default	cPedRes		:=  aListPed[oArqPed:nAt,3]

	// Caso não esteja trabalhando com pedidkos de venda, não executa a rotina, retorna avisando
	If MV_PAR07 <> 1
		MsgAlert("A opção de eliminar resíduos é somente para pedidos de venda!","'BFFATA30.PRW.sfResiduo' - Não permitido!")
		sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
		RestArea(aAreaOld)
		Return
	Endif

	// Efetua verificação se o pedido não está em expedição
	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSeek(xFilial("SC5")+cPedRes)
	If SC5->C5_BLPED $ "S#M"
		MsgAlert("Pedido enviado ao Faturamento! Não é permitida a eliminação de resíduos!","'BFFATA30.PRW.sfResiduo' - Rotina negada!")
		sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
		RestArea(aAreaOld)
		Return
	Endif

	// Pergunta se deseja eliminar realmente os resíduos do pedido
	If MsgYesNo("Confirma o Estorno da liberação para todos os itens liberados do pedido para eliminação de resíduo?","'BFFATA30.PRW.sfResiduo' - Atenção!")
		U_GMCFGM01("ER",cPedRes,,FunName(),,)
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+cPedRes)
		While !SC6->(Eof()) .And. SC6->C6_NUM == cPedRes
			If SC6->C6_QTDENT < SC6->C6_QTDVEN
				Aadd(aSC6Bk,{SC6->(Recno()),SC6->C6_BLQ})

				DbSelectArea("SC9")
				DbSetOrder(1)
				If !DbSeek(xFilial("SC9")+SC6->C6_NUM+SC6->C6_ITEM)
					RecLock("SC6",.F.)
					If SC6->C6_QTDEMP > 0
						SC6->C6_QTDEMP	:= 0
					Endif
					If SC6->C6_QTDEMP2 > 0
						SC6->C6_QTDEMP2	:= 0
					Endif
					MsUnlock()
				Endif

				RecLock("SC6",.F.)
				SC6->C6_BLQ 	:= " "
				MsUnlock()
			Endif
			DbSelectArea("SC6")
			SC6->(dbSkip())
		EndDo

		// Localiza istens liberados e efetua estorno
		DbSelectArea("SC9")
		DbSetOrder(1)
		DbSeek(xFilial("SC9")+cPedRes)
		While !Eof() .And. SC9->C9_PEDIDO == cPedRes
			If SC9->C9_BLEST <> "10" .And. SC9->C9_BLCRED <> "10" //.And. !(Alltrim(SC9->C9_FLGENVI) $ "E")
				DbSelectArea("SC6")
				DbSetOrder(1)
				If DbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM)
					SC9->(a460Estorna())
				Endif
			EndIf
			DbSelectArea("SC9")
			dbSkip()
		EndDo


		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+cPedRes)
		While !Eof() .And. SC6->C6_NUM == cPedRes
			If SC6->C6_QTDENT < SC6->C6_QTDVEN

				RecLock("SC6",.F.)
				If SC6->C6_QTDEMP > 0
					SC6->C6_QTDEMP	:= 0
				Endif
				If SC6->C6_QTDEMP2 > 0
					SC6->C6_QTDEMP2	:= 0
				Endif
				MsUnlock()
			Endif
			DbSelectArea("SC6")
			dbSkip()
		EndDo

		//IAGO 06/08/2021 Projeto Estoque Avançado
		DbSelectArea("SC5")
		DbSetOrder(1)
		If FieldPos("C5_XESTAVC") > 0 .And. DbSeek(xFilial("SC5")+cPedRes)
			RecLock("SC5",.F.)
			SC5->C5_XESTAVC	:= "N"
			MsUnlock()
		EndIf


	Else
		sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
		RestArea(aAreaOld)
		Return
	Endif

	// Atualiza perguntas da rotina MATA500
	cPergMta := ("MTA500")
	U_GravaSX1(cPergMta,"01",100)
	U_GravaSX1(cPergMta,"02",CTOD("  /  /   "))
	U_GravaSX1(cPergMta,"03",dDataBase	+7)
	U_GravaSX1(cPergMta,"04",cPedRes)
	U_GravaSX1(cPergMta,"05",cPedRes)
	U_GravaSX1(cPergMta,"06",1)
	U_GravaSX1(cPergMta,"07"," ")
	U_GravaSX1(cPergMta,"08","ZZZ")
	U_GravaSX1(cPergMta,"09",1)
	U_GravaSX1(cPergMta,"10",CTOD("  /  /   "))
	U_GravaSX1(cPergMta,"11",dDataBase+30)

	Mata500()
	// Efetua leitura dos itens da SC6 caso não tenha sido eliminado o resíduo, restaurando o bloqueio C6_BLQ para evitar liberações
	// por causa de ter chamado a MATA500
	For iZ := 1 To Len(aSC6Bk)
		DbSelectArea("SC6")
		DbGoto(aSC6Bk[iZ,1])
		If Alltrim(SC6->C6_BLQ) <> "R" .And. SC6->C6_QTDENT < SC6->C6_QTDVEN
			RecLock("SC6",.F.)
			SC6->C6_BLQ := aSC6Bk[iZ,2]
			MsUnlock()
		Endif
	Next
	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfMATR260
//TODO Efetua chamada de posição de estoque com dados pré preenchidos para consulta de armazém 03
@author Marcelo Alberto Lauschner
@since 14/12/2018
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfMATR260()

	Local 		aAreaOld		:= GetArea()
	Local		cPergMta		:= ""
	Local		aRestPerg		:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)

	cPergMta := "MTR260"
	U_GravaSX1(cPergMta,"01",1) 				// Agrupa Por 1-Armazém 2-Filial 3-Empresa
	U_GravaSX1(cPergMta,"02",cFilAnt)			// Filial De
	U_GravaSX1(cPergMta,"03",cFilAnt)			// Filial Até
	If cFilAnt == "04"
		U_GravaSX1(cPergMta,"04","03")				// Armazém De
		U_GravaSX1(cPergMta,"05","03")				// Armazém Ate
	Else
		U_GravaSX1(cPergMta,"04","  ")				// Armazém De
		U_GravaSX1(cPergMta,"05","ZZ")				// Armazém Ate
	Endif
	U_GravaSX1(cPergMta,"06"," ")				// Produto de
	U_GravaSX1(cPergMta,"07","ZZZZZZZ")			// Produto ate
	U_GravaSX1(cPergMta,"08"," ")				// Tipo de
	U_GravaSX1(cPergMta,"09","ZZ")				// Tipo Ate
	U_GravaSX1(cPergMta,"10","  ") 				// Grupo de
	U_GravaSX1(cPergMta,"11","ZZZZ")			// Grupo Ate
	U_GravaSX1(cPergMta,"12","  ")				// Descrição De
	U_GravaSX1(cPergMta,"13","ZZZZ")			// Descrição ate
	U_GravaSX1(cPergMta,"14",1)					// Lista quais produtos 1-Todos
	U_GravaSX1(cPergMta,"15",1)					// Saldo a considerar 1-Atual
	U_GravaSX1(cPergMta,"16",1)					// Moeda
	U_GravaSX1(cPergMta,"17",2)					// Aglutina por UM
	U_GravaSX1(cPergMta,"18",2)					// Lista produto c/saldo zerado
	U_GravaSX1(cPergMta,"19",1)					// Imprime valor 1-Custo
	U_GravaSX1(cPergMta,"20",dDataBase)			// data referencia
	U_GravaSX1(cPergMta,"21",2)					// lista produtos valor zerado
	U_GravaSX1(cPergMta,"22",2)					// Qte segunda um
	U_GravaSX1(cPergMta,"23",2)					// imprime descrição armazem


	MATR260()

	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	RestArea(aAreaOld)

Return



/*/{Protheus.doc} sfMATR255
//TODO Efetua chamada de posição de estoque com dados pré preenchidos
@author Marcelo Alberto Lauschner
@since 13/06/2019
@version 1.0
@return Nil
@type Static Function
/*/
Static Function sfMATR255()

	Local 		aAreaOld		:= GetArea()
	Local		cPergMta		:= ""
	Local		aRestPerg		:= sfRestPerg(.T./*lSalvaPerg*/,/*aPerguntas*/,9/*nTamSx1*/)

	cPergMta :="MTR255"

	U_GravaSX1(cPergMta,"01"," ") 				// 01 - Produto de
	U_GravaSX1(cPergMta,"02","zzzz")			// 02 - Produto Até
	U_GravaSX1(cPergMta,"03"," ")				// 03 - Situação de
	U_GravaSX1(cPergMta,"04","ZZ")				// 04 - Situação Até
	U_GravaSX1(cPergMta,"05",1)					// 05 - Imprimir
	U_GravaSX1(cPergMta,"06",Iif(cEmpAnt=="05","02","  "))				// 06 - Armazém
	U_GravaSX1(cPergMta,"07",Iif(cEmpAnt=="05","02","ZZ"))				// 07 - Armazém até
	U_GravaSX1(cPergMta,"08"," ")				// 08 - Endereço
	U_GravaSX1(cPergMta,"09","ZZ")				// 09 - Endereço Até

	MATR255()

	sfRestPerg(/*lSalvaPerg*/,aRestPerg/*aPerguntas*/,/*nTamSx1*/)
	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfRestPerg
(Salva e restaura perguntas para controle da Rotina)
@author MarceloLauschner
@since 22/04/2014
@version 1.0
@param lSalvaPerg, ${param_type}, (Descrição do parâmetro)
@param aPerguntas, array, (Descrição do parâmetro)
@param nTamSx1, numérico, (Descrição do parâmetro)
@return array, Perguntas num vetor
@example
(examples)
@see (links_or_references)
/*/
Static Function sfRestPerg(lSalvaPerg,aPerguntas,nTamSx1)

	Local ni
	DEFAULT lSalvaPerg	:=.F.
	Default nTamSX1		:= 40
	DEFAULT aPerguntas	:=Array(nTamSX1)

	For ni := 1 to Len(aPerguntas)
		If lSalvaPerg
			aPerguntas[ni] := &("mv_par"+StrZero(ni,2))
		Else
			&("mv_par"+StrZero(ni,2)) :=	aPerguntas[ni]
		EndIf
	Next ni

Return(aPerguntas)


/*/{Protheus.doc} sfConProd
(Consulta Histórico do Produto)
@author MarceloLauschner
@since 22/04/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/Static Function sfConProd()

Local	nOpcSb1	:= Aviso("Escolha uma opção","Selecione uma opção",{"Histórico","Cadastro"})
Local	aAreaOld	:= GetArea()

If nOpcSB1	== 1
	If Len(oMulti:aCols) > 0 .And. !Empty(oMulti:aCols[oMulti:nAt,nPxProd])
		If Type("aRotina") <> "A"
			aRotina   := {{ ,"A103NFiscal", 0, 2}}
		Endif
		MaComView(oMulti:aCols[oMulti:nAt][nPxProd])
	Else
		MsgAlert("Não há produto digitado!","XML Dcondor!")
	Endif
ElseIf nOpcSB1 == 2 .And. Len(oMulti:aCols) > 0 .And. oMulti:nAt <= Len(oMulti:aCols)
	DbSelectArea("SB1")
	Set Filter To B1_COD == oMulti:aCols[oMulti:nAt,nPxProd]
	Mata010()
	// Restaura sem filtro
	DbSelectArea("SB1")
	Set Filter To
	RestArea(aAreaOld)
Endif

Return Nil


/*/{Protheus.doc} sfTmkObs
(long_description)
@author MarceloLauschner
@since 08/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfTmkObs()

	Local 	oDlgEmail
	Local	cRecebe 	:= Space(200)
	Local	cPed    	:= aListPed[oArqPed:nAt,3]
	Local	lSend		:= .F.
	Local	cSubject	:= Padr("Follow-up "+Iif(MV_PAR07==1, "pedido-> ","orçamento->")+ cPed,60)
	Local	cBody		:= Space(255)

	DEFINE MSDIALOG oDlgEmail Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Observação TMK para o "+ Iif(MV_PAR07==1, "pedido-> ","orçamento->")+ cPed ) FROM 001,001 TO 380,620 PIXEL

	@ 010,010 Say "Para: " Pixel of oDlgEmail
	@ 010,050 MsGet cRecebe Size 180,10 Valid {|| cRecebe := U_BFCFGA02(cRecebe),.T.} Pixel Of oDlgEmail
	@ 025,010 Say "Assunto" Pixel of oDlgEmail
	@ 025,050 MsGet cSubject Size 250,10 Pixel Of oDlgEmail
	@ 040,050 Get cBody of oDlgEmail MEMO Size 250,100 Pixel

	@ 160,050 BUTTON "Envia Email" Size 70,10 Action (lSend := .T.,oDlgEmail:End())	Pixel Of oDlgEmail
	@ 160,130 BUTTON "Cancela" Size 70,10 Action (oDlgEmail:End())	Pixel Of oDlgEmail

	ACTIVATE MsDialog oDlgEmail Centered

	If !lSend
		Return
	Endif

	If MV_PAR07==1
		U_BFFATA35("P"/*cZ9ORIGEM*/,cPed/*cZ9NUM*/,"2"/*cZ9EVENTO*/,Padr(Alltrim(cSubject)+"-"+Alltrim(cBody),250)/*cZ9DESCR*/,cRecebe/*cZ9DEST*/,cUserName/*cZ9USER*/)
	Else
		U_BFFATA35("O"/*cZ9ORIGEM*/,cPed/*cZ9NUM*/,"2"/*cZ9EVENTO*/,Padr(Alltrim(cSubject)+"-"+Alltrim(cBody),250)/*cZ9DESCR*/,cRecebe/*cZ9DEST*/,cUserName/*cZ9USER*/)
	Endif

	stSendMail( cRecebe, cSubject, cBody ,.T./*lExibSend*/ )

	// Executa um refresh da tela
	sfRefF()

Return



/*/{Protheus.doc} stExpExcel
(Exporta pedido para Excel)
@author MarceloLauschner
@since 26/05/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stExpExcel()
	Local	aExpXml

	If FindFunction("RemoteType") .And. RemoteType() == 1
		aExpXml	:= {aClone(aListPed[oArqPed:nAt])}
		DlgToExcel({{"ARRAY","Cabeçalho Pedido",aCabPeds,aExpXml},{"GETDADOS","Itens do Pedido",aHeadPed,oMulti:aCols}})
	EndIf

Return



/*/{Protheus.doc} sfSendWF
(long_description)
@author MarceloLauschner
@since 29/10/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSendWF(lInIsAuto,cFlgRetAlc,cInIdUser,cInMotAlcada,cInRecebe)

	Local	cNumPed			:= aListPed[oArqPed:nAt,3]
	Local 	oProcess      	:= Nil                                	//Objeto da classe TWFProcess.
	Local 	cMailId       	:= ""                                 	//ID do processo gerado.
	Local 	cHostWFExt    	:= GetNewPar("BF_URLWFEX",'http://177.200.213.138:8082')	//URL configurado no ini para WF Link.
	Local 	cHostWFInt    	:= GetNewPar("BF_URLWFIN",'http://192.168.1.2:8081')		   	//URL configurado no ini para WF Link.
	Local	nTotValor		:= 0
	Local	nTotVMargem		:= 0
	Local	nTotTampas		:= 0
	Local	nTotAddTampas	:= 0
	Local	nTotPMargem		:= 0
	Local	nTotVIR			:= 0
	Local	nTotImpostos	:= 0
	Local	nTotPIR			:= 0
	Local	nTotMkt			:= 0
	Local	nTotBruto		:= 0
	Local	nTotDesc		:= 0
	Local	lSend			:= .F.
	Local	oDlgEmail
	Local	cRecebe			:= Padr(GetNewPar("BF_BFTA30B","daniel@brlub.com.br;"),200)
	Local	cSubject		:= Padr(IIf(MV_PAR07==1,"Aprovação de Pedido de Vendas --> ","Aprovação de Orçamento Televendas --> ") + cNumPed,150)
	Local	cBody			:= Space(500)
	Local	cQry			:= ""
	Local	aRecebe			:= {}
	Local	aAuxRec			:= {}
	Local	iQ				:= 0
	Local	cBkProcess		:= ""
	Local	lAddDiretoria	:= .F.
	Local	lAddAnalista	:= .F.
	Local	aArrSZS			:= {}
	Local	nI,iL
	Local 	iW 
	Local	aLinhas
	Local	cUAOBS			:= ""
	Local	cMsgFrete		:= ""
	Default	cFlgRetAlc		:= ""
	Default	lInIsAuto		:= .F.
	Default	cInIdUser		:= __cUserId
	Default	cInMotAlcada	:= ""
	Default cInRecebe		:= ""
	Private	cUsrSendWf		:= ""

	DbSelectArea("SZS")
	DbSetOrder(1)
	If MV_PAR07==1
		// Monta lista de usuários diferente de Gerente
		cQry := "SELECT DETAIL.* FROM ( "
		cQry += "SELECT DISTINCT ZS_IDUSR1,ZS_NIVEL ,ZS_MOTIVO,'2' ORD_GER "
		cQry += "       ,CASE WHEN ZS_NIVEL = 'G' THEN '3' "
		cQry += "            WHEN ZS_NIVEL = 'A' THEN '1' "
		cQry += "            WHEN ZS_NIVEL = 'S' THEN '2' "
		cQry += "            WHEN ZS_NIVEL = 'D' THEN '4' "
		cQry += "       END ORD_NIVEL "
		cQry += "  FROM " + RetSqlName("SZS") + " ZS," + RetSqlName("SC6") + " C6," + RetSqlName("SB1") +  " B1 "
		cQry += " WHERE C6.D_E_L_E_T_ =' ' "
		cQry += "   AND CHARINDEX(ZS_MOTIVO,C6_XALCADA) > 0 "
		cQry += "   AND C6_QTDENT < C6_QTDVEN "
		cQry += "   AND C6_BLQ != 'R' "
		cQry += "   AND C6_XALCADA != ' ' "
		cQry += "   AND C6_NUM = '"+cNumPed+"' "
		cQry += "   AND C6_FILIAL = '" +xFilial("SC6")+ "' "
		cQry += "   AND B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND ((ZS_TIPPROD = ' ' ) OR (ZS_TIPPROD = B1_CABO)) " // TEX/ROC/HOU/OUT/MIC/LUS
		cQry += "   AND B1_COD = C6_PRODUTO "
		cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
		// Se for rotina automática
		If lInIsAuto .And. cFlgRetAlc == "S"
			cQry += "  AND ZS_NIVEL = 'S' "
		ElseIf lInIsAuto .And. cFlgRetAlc == "D" // Diretoria
			cQry += "  AND ZS_NIVEL = 'D' "
			If SZS->(FieldPos("ZS_GERENT")) > 0
				cQry += "  AND (ZS_GERENT = '" + cInIdUser + "' OR ZS_GERENT = ' ')"
			Endif
		ElseIf lInIsAuto .And. cFlgRetAlc == "A" // Analista comercial
			cQry += "  AND ZS_NIVEL = 'A' "
		Else
			cQry += "  AND ZS_NIVEL != 'G' "
		Endif
		cQry += "   AND ZS_IDUSR1 != '"+cInIdUser + "' "
		cQry += "   AND ZS.D_E_L_E_T_ =' ' "
		cQry += "   AND ZS_FILIAL = '" +xFilial("SZS")+ "' "

		cQry += "UNION "
		cQry += "SELECT DISTINCT ZS_IDUSR1,ZS_NIVEL,ZS_MOTIVO,'1' ORD_GER"
		cQry += "       ,CASE WHEN ZS_NIVEL = 'G' THEN '3' "
		cQry += "            WHEN ZS_NIVEL = 'A' THEN '1' "
		cQry += "            WHEN ZS_NIVEL = 'S' THEN '2' "
		cQry += "            WHEN ZS_NIVEL = 'D' THEN '4' "
		cQry += "       END ORD_NIVEL "
		cQry += "  FROM "+RetSqlName("SZS")+" ZS,"+RetSqlName("SC6")+" C6,"+RetSqlName("SB1")+" B1,"
		cQry +=           RetSqlName("SC5")+" C5,"+RetSqlName("SA3")+" A3A "
		cQry += " WHERE C6.D_E_L_E_T_ = ' ' "
		cQry += "   AND CHARINDEX(ZS_MOTIVO,C6_XALCADA) > 0 "
		cQry += "   AND C6_QTDENT < C6_QTDVEN "
		cQry += "   AND C6_BLQ != 'R' "
		cQry += "   AND C6_XALCADA != ' ' "
		cQry += "   AND C6_NUM = C5_NUM "
		cQry += "   AND C6_FILIAL = '"+xFilial("SC6")+"' "
		cQry += "   AND A3A.D_E_L_E_T_ = ' ' "
		cQry += "   AND A3A.A3_XCODUSR = ZS_IDUSR1 "
		cQry += "   AND A3A.A3_COD  = C5_VEND1 "
		cQry += "   AND A3A.A3_FILIAL = '"+xFilial("SA3")+"' "
		cQry += "   AND C5.D_E_L_E_T_ = ' ' "
		cQry += "   AND C5_NUM = '"+cNumPed+"' "
		cQry += "   AND C5_FILIAL = '"+xFilial("SC5")+"' "
		cQry += "   AND B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_COD = C6_PRODUTO "
		cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
		If lInIsAuto .And. cFlgRetAlc == "S"
			cQry += "  AND ZS_NIVEL = 'S' "
		ElseIf lInIsAuto .And. cFlgRetAlc == "D" // Diretoria
			cQry += "  AND ZS_NIVEL = 'D' "
			If SZS->(FieldPos("ZS_GERENT")) > 0
				cQry += "  AND (ZS_GERENT = '" + cInIdUser + "' OR ZS_GERENT = ' ')"
			Endif
		ElseIf lInIsAuto .And. cFlgRetAlc == "A" // Analista comercial
			cQry += "  AND ZS_NIVEL = 'A' "
		Else
			cQry += "   AND ZS_NIVEL = 'G' "
		Endif
		cQry += "   AND ((ZS_TIPPROD = ' ' ) OR (ZS_TIPPROD = B1_CABO)) " // TEX/ROC/HOU/OUT/MIC/LUS
		cQry += "   AND ZS_IDUSR1 != '"+cInIdUser + "' "
		cQry += "   AND ZS.D_E_L_E_T_ = ' ' "
		cQry += "   AND ZS_FILIAL = '"+xFilial("SZS")+"' ) DETAIL "
 		cQry += " ORDER BY DETAIL.ORD_GER, DETAIL.ORD_NIVEL,DETAIL.ZS_NIVEL,DETAIL.ZS_MOTIVO "
	Else
		cQry := "SELECT DETAIL.* FROM ( "
		cQry += "SELECT DISTINCT ZS_IDUSR1,ZS_NIVEL,ZS_MOTIVO,'2' ORD_GER"
		cQry += "       ,CASE WHEN ZS_NIVEL = 'G' THEN '3' "
		cQry += "            WHEN ZS_NIVEL = 'A' THEN '1' "
		cQry += "            WHEN ZS_NIVEL = 'S' THEN '2' "
		cQry += "            WHEN ZS_NIVEL = 'D' THEN '4' "
		cQry += "       END ORD_NIVEL "
		cQry += "  FROM " + RetSqlName("SZS") + " ZS," + RetSqlName("SUB") + " UB," + RetSqlName("SB1") +  " B1 "
		cQry += " WHERE UB.D_E_L_E_T_ =' ' "
		cQry += "   AND CHARINDEX(ZS_MOTIVO,UB_XALCADA) > 0 "
		cQry += "   AND UB_XALCADA != ' ' "
		cQry += "   AND UB_NUM = '"+cNumPed+"' "
		cQry += "   AND UB_FILIAL = '" +xFilial("SUB")+ "' "
		cQry += "   AND B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND ((ZS_TIPPROD = ' ' ) OR (ZS_TIPPROD = B1_CABO)) " // TEX/ROC/HOU/OUT/MIC/LUS	cQry += "   AND ZS_TIPPROD = B1_CABO " // TEX/ROC/HOU/OUT/MIC/LUS
		cQry += "   AND B1_COD = UB_PRODUTO "
		cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "' "
		If lInIsAuto .And. cFlgRetAlc == "S"
			cQry += "  AND ZS_NIVEL = 'S' "
		ElseIf lInIsAuto .And. cFlgRetAlc == "D" // Diretoria
			cQry += "  AND ZS_NIVEL = 'D' "
			If SZS->(FieldPos("ZS_GERENT")) > 0
				cQry += "  AND (ZS_GERENT = '" + cInIdUser + "' OR ZS_GERENT = ' ')"
			Endif
		ElseIf lInIsAuto .And. cFlgRetAlc == "A" // Analista comercial
			cQry += "  AND ZS_NIVEL = 'A' "
		Else
			cQry += "  AND ZS_NIVEL != 'G' "
		Endif
		cQry += "   AND ZS_IDUSR1 != '"+cInIdUser + "' "
		cQry += "   AND ZS.D_E_L_E_T_ =' ' "
		cQry += "   AND ZS_FILIAL = '" +xFilial("SZS")+ "' "

		cQry += "UNION "
		cQry += "SELECT DISTINCT ZS_IDUSR1,ZS_NIVEL ,ZS_MOTIVO, '1' ORD_GER"
		cQry += "       ,CASE WHEN ZS_NIVEL = 'G' THEN '3' "
		cQry += "            WHEN ZS_NIVEL = 'A' THEN '1' "
		cQry += "            WHEN ZS_NIVEL = 'S' THEN '2' "
		cQry += "            WHEN ZS_NIVEL = 'D' THEN '4' "
		cQry += "       END ORD_NIVEL "
		cQry += "  FROM "+RetSqlName("SZS")+" ZS,"+RetSqlName("SUB")+" UB,"+RetSqlName("SB1")+" B1,"
		cQry +=           RetSqlName("SUA")+" UA,"+RetSqlName("SA3")+" A3A "
		cQry += " WHERE UB.D_E_L_E_T_ = ' ' "
		cQry += "   AND CHARINDEX(ZS_MOTIVO,UB_XALCADA) > 0 "
		cQry += "   AND UB_XALCADA != ' ' "
		cQry += "   AND UB_NUM = UA_NUM "
		cQry += "   AND UB_FILIAL = '"+xFilial("SUB")+"' "
		cQry += "   AND A3A.D_E_L_E_T_ = ' ' "
		cQry += "   AND A3A.A3_XCODUSR = ZS_IDUSR1 "
		cQry += "   AND A3A.A3_COD  = UA_VEND "
		cQry += "   AND A3A.A3_FILIAL = '"+xFilial("SA3")+"' "
		cQry += "   AND UA.D_E_L_E_T_ = ' ' "
		cQry += "   AND UA_NUM = '"+cNumPed+"' "
		cQry += "   AND UA_FILIAL = '"+xFilial("SUA")+"' "
		cQry += "   AND B1.D_E_L_E_T_ = ' ' "
		cQry += "   AND B1_COD = UB_PRODUTO "
		cQry += "   AND B1_FILIAL = '"+xFilial("SB1")+"' "
		If lInIsAuto .And. cFlgRetAlc == "S"
			cQry += "  AND ZS_NIVEL = 'S' "
		ElseIf lInIsAuto .And. cFlgRetAlc == "D" // Diretoria
			cQry += "  AND ZS_NIVEL = 'D' "
			If SZS->(FieldPos("ZS_GERENT")) > 0
				cQry += "  AND (ZS_GERENT = '" + cInIdUser + "' OR ZS_GERENT = ' ')"
			Endif
		ElseIf lInIsAuto .And. cFlgRetAlc == "A" // Analista comercial
			cQry += "  AND ZS_NIVEL = 'A' "
		Else
			cQry += "   AND ZS_NIVEL = 'G' "
		Endif
		cQry += "   AND ((ZS_TIPPROD = ' ') OR (ZS_TIPPROD = B1_CABO)) " // TEX/ROC/HOU/OUT/MIC/LUS
		cQry += "   AND ZS_IDUSR1 != '"+cInIdUser + "' "
		cQry += "   AND ZS.D_E_L_E_T_ = ' ' "
		cQry += "   AND ZS_FILIAL = '"+xFilial("SZS")+"' ) DETAIL "
 		cQry += "ORDER BY DETAIL.ORD_GER, DETAIL.ORD_NIVEL,DETAIL.ZS_NIVEL,DETAIL.ZS_MOTIVO "
	Endif

	MemoWrite("/log_sqls/bffata30_sendwf.sql",cQry)

	dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSZS', .F., .T.)

	While !Eof()
		// Monta vetor apenas com usuários diferentes por alçadas - Ordenado primeiro pelo Gerente e depois Analista e Diretoria
		//If !lInIsAuto
		nPos := aScan(aArrSZS,{|x|  x[1]+ x[3] == QSZS->ZS_IDUSR1+QSZS->ZS_MOTIVO})
		//Else
		//	nPos := aScan(aArrSZS,{|x|  x[3] == QSZS->ZS_MOTIVO})
		//Endif
		If nPos == 0
			Aadd(aArrSZS,{QSZS->ZS_IDUSR1,QSZS->ZS_NIVEL,QSZS->ZS_MOTIVO,QSZS->ZS_IDUSR1 + "-"+ Alltrim(UsrRetMail(QSZS->ZS_IDUSR1))})
			// Quando for homologação monto texto para saber quais usuários tem permissão e por qual código de alçada para liberar o pedido
			If AllTrim(Lower(GetEnvServer())) == "homologacao"
				cBody	+= "Nível: " +QSZS->ZS_NIVEL + " Motivo: "+QSZS->ZS_MOTIVO + " Usuário: "+QSZS->ZS_IDUSR1 + "-"+ Alltrim(UsrRetMail(QSZS->ZS_IDUSR1)) + CRLF
			Endif
		Endif
		QSZS->(DbSkip())
	Enddo

	QSZS->(DbCloseArea())

	For iQ := 1 To Len(aArrSZS)

		nPos := aScan(aAuxRec,{|x| x[1] == aArrSZS[iQ,1]})

		If cFlgRetAlc == "D" .And. aArrSZS[iQ,2] == "D"
			If nPos == 0
				Aadd(aRecebe, aArrSZS[iQ,4] )
				Aadd(aAuxRec,{aArrSZS[iQ,1],aArrSZS[iQ,2]})
			Endif
		ElseIf cFlgRetAlc == "A" .And. aArrSZS[iQ,2] == "A"
			If nPos == 0
				Aadd(aRecebe, aArrSZS[iQ,4] )
				Aadd(aAuxRec,{aArrSZS[iQ,1],aArrSZS[iQ,2]})
			Endif
		Else

			If aArrSZS[iQ,2] == "D"
				If !lInIsAuto
					If nPos == 0
						Aadd(aRecebe, aArrSZS[iQ,4] )
						Aadd(aAuxRec,{aArrSZS[iQ,1],aArrSZS[iQ,2]})
						// Verifica se o motivo da Diretoria ainda não foi encontrado anteriormente
						//If aScan(aAuxRec,{|x| x[2] == aArrSZS[iQ,2]}) == 0
						lAddDiretoria	:= .T.
						//Endif
					Endif
				Else
					lAddDiretoria	:= .T.
				Endif
			ElseIf aArrSZS[iQ,2] == "G"
				If nPos == 0
					Aadd(aRecebe, aArrSZS[iQ,4] )
					Aadd(aAuxRec,{aArrSZS[iQ,1],aArrSZS[iQ,2]})
				Endif
			ElseIf aArrSZS[iQ,2] == "S"
				If !lInIsAuto
					If nPos == 0
						Aadd(aRecebe, aArrSZS[iQ,4] )
						Aadd(aAuxRec,{aArrSZS[iQ,1],aArrSZS[iQ,2]})
					Endif
				Endif
			ElseIf aArrSZS[iQ,2] == "A"
				If !lInIsAuto
					If nPos == 0
						Aadd(aRecebe, aArrSZS[iQ,4] )
						Aadd(aAuxRec,{aArrSZS[iQ,1],aArrSZS[iQ,2]})
					Endif
				Endif
				lAddAnalista	:= .T. // Comentado em 01/05/2018 - Não gerará Alçada de Price
			Endif

			// 30/09/2015 - Se não encontrou G=Gerente para liberar pedido e há perfil de Analista/Diretoria - adiciona destinatário
			If (lAddAnalista .Or. lAddDiretoria) .And. Len(aRecebe) <= 0
				If nPos == 0
					Aadd(aRecebe, aArrSZS[iQ,4] )
					Aadd(aAuxRec,{aArrSZS[iQ,1],aArrSZS[iQ,2]})
				Endif
			Endif
		Endif
	Next



	If !lInIsAuto

		DEFINE MSDIALOG oDlgEmail Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Enviar email para solicitação de aprovação!") FROM 001,001 TO 380,620 PIXEL

		@ 010,010 Say "Para: " Pixel of oDlgEmail
		@ 010,050 MsComboBox cRecebe Items aRecebe Size 180,10 Pixel Of oDlgEmail
		@ 025,010 Say "Assunto" Pixel of oDlgEmail
		@ 025,050 MsGet cSubject Size 250,10 Pixel Of oDlgEmail
		@ 040,050 Get cBody of oDlgEmail MEMO Size 250,100 Pixel

		@ 160,050 BUTTON "Envia Email" Size 70,10 Action (lSend := .T.,oDlgEmail:End())	Pixel Of oDlgEmail
		@ 160,130 BUTTON "Cancela" Size 70,10 Action (oDlgEmail:End())	Pixel Of oDlgEmail

		ACTIVATE MsDialog oDlgEmail Centered

		If !lSend
			Return
		Endif
	Else 
		If MV_PAR07==1
			cQry := "SELECT Z9_DESCR"
			cQry += "  FROM "+RetSqlName("SZ9")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND Z9_EVENTO = '6' "
			cQry += "   AND Z9_NUM = '"+SC5->C5_NUM+"'"
			cQry += "   AND Z9_ORIGEM = 'P' "
			cQry += "   AND Z9_FILIAL = '"+xFilial("SZ9")+"' "
			cQry += " ORDER BY R_E_C_N_O_ DESC "

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSZ9', .F., .T.)

			If !Eof()
				cBody += StrTran(QSZ9->Z9_DESCR,Chr(13)+Chr(10),"<p></p>")
			Endif
			QSZ9->(DbCloseArea())
		Else 
			cQry := "SELECT Z9_DESCR"
			cQry += "  FROM "+RetSqlName("SZ9")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND Z9_EVENTO = '6' "
			cQry += "   AND Z9_NUM = '"+SUA->UA_NUM+"'"
			cQry += "   AND Z9_ORIGEM = 'O' "
			cQry += "   AND Z9_FILIAL = '"+xFilial("SZ9")+"' "
			cQry += " ORDER BY R_E_C_N_O_ DESC "

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSZ9', .F., .T.)

			If !Eof()
				cBody += StrTran(QSZ9->Z9_DESCR,Chr(13)+Chr(10),"<p></p>")
			Endif
			QSZ9->(DbCloseArea())
		
		Endif
	Endif
	//ConOut("Passou automatico linha 3983")
	For iL := 1 To Len(aRecebe)
		// Se for automático mando o link para todos
		If lInIsAuto
			//cRecebe	:= GetNewPar("BF_FT30APR","000204-jonathan@atrialub.com.br")	// 000204-jonathan@atrialub.com.br
			If Empty(cInRecebe)
				cRecebe	:= aRecebe[iL]
			Else
				cRecebe	:= cInRecebe
			Endif
		Else
			// Se for manual paro no primeiro Loop
			If iL > 1
				Exit
			Endif
		Endif

		// Zera variaveis totalizadoras por causa do loop dos destinatários
		nTotValor		:=	0
		nTotVMargem		:=	0
		nTotTampas		:=	0
		nTotAddTampas	:=  0
		nTotVIR			:=	0
		nTotImpostos	:=	0
		nTotMkt			:=	0
		nTotBruto		:=	0

		cUsrSendWf	:= Substr(cRecebe,1,6)

		// Código extraído do cadastro de processos.
		cCodProcesso := "PED003" // SOLICITACAO DE APROVACAO DE PEDIDO A DIRETORIA

		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			If MV_PAR07==1
				If lInIsAuto
					If lAddDiretoria
						cHtmlModelo	:= "/workflow/aprovacao_pedido_diretoria.htm"
						nPos := aScan(aAuxRec,{|x| x[1] == cUsrSendWf})
						If nPos > 0 .And. aAuxRec[nPos,2] == "D"
							cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
							// 18/11/2015 - Efetua chamada recursiva - Workflow de diretoria contém uma análise diferenciada por causa do
							U_BFFATA30(.T. /*lAuto*/,cNumPed /*cInPed*/,1 /*nInPedOrc*/,"D"/*cFlgRetAlc*/,__cUserId /*cInIdUser*/,cBody/*cInMotAlcada*/)
							Return
						Endif

					ElseIf lAddAnalista
						cHtmlModelo	:= "/workflow/aprovacao_pedido_price.htm"
					Else
						cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
					Endif
				Else
					nPos := aScan(aAuxRec,{|x| x[1] == cUsrSendWf})
					If nPos == 0
						cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
					ElseIf aAuxRec[nPos,2] == "D"
						cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
						// 25/09/2015 - Efetua chamada recursiva - Workflow de diretoria contém uma análise diferenciada por causa do
						U_BFFATA30(.T. /*lAuto*/,cNumPed /*cInPed*/,1 /*nInPedOrc*/,"D"/*cFlgRetAlc*/,__cUserId /*cInIdUser*/,cBody/*cInMotAlcada*/,cRecebe)
						Return
					ElseIf aAuxRec[nPos,2] == "A" .And. !lAddDiretoria
						cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
					ElseIf lAddDiretoria
						cHtmlModelo	:= "/workflow/aprovacao_pedido_diretoria.htm"
					ElseIf lAddAnalista
						cHtmlModelo	:= "/workflow/aprovacao_pedido_price.htm"
					Else
						cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
					Endif
				Endif
			Else
				DbSelectArea("SUA")
				DbSetOrder(1)
				DbSeek(xFilial("SUA")+cNumPed)

				aLinhas := TkMemo(SUA->UA_CODOBS, 195)
				For nI := 1 to Len(aLinhas)
					cUAOBS += aLinhas[nI] + "<br>"
				Next nI
				If lInIsAuto
					If lAddDiretoria
						cHtmlModelo	:= "/workflow/aprovacao_orcamento_diretoria.htm"
						nPos := aScan(aAuxRec,{|x| x[1] == cUsrSendWf})
						If nPos > 0 .And. aAuxRec[nPos,2] == "D"
							cHtmlModelo	:= "/workflow/aprovacao_pedido.htm"
							// 18/11/2015 - Efetua chamada recursiva - Workflow de diretoria contém uma análise diferenciada por causa do
							U_BFFATA30(.T. /*lAuto*/,cNumPed /*cInPed*/,2 /*nInPedOrc*/,"D"/*cFlgRetAlc*/,__cUserId /*cInIdUser*/,cBody/*cInMotAlcada*/)
							Return
						Endif
					ElseIf lAddAnalista
						cHtmlModelo	:= "/workflow/aprovacao_orcamento_price.htm"
					Else
						cHtmlModelo	:= "/workflow/aprovacao_orcamento.htm"
					Endif
				Else
					nPos := aScan(aAuxRec,{|x| x[1] == cUsrSendWf})
					If nPos == 0
						cHtmlModelo	:= "/workflow/aprovacao_orcamento.htm"
					ElseIf aAuxRec[nPos,2] == "D"
						cHtmlModelo	:= "/workflow/aprovacao_orcamento.htm"
						// 25/09/2015 - Efetua chamada recursiva - Workflow de diretoria contém uma análise diferenciada por causa do
						U_BFFATA30(.T. /*lAuto*/,cNumPed /*cInPed*/,2 /*nInPedOrc*/,"D"/*cFlgRetAlc*/,__cUserId /*cInIdUser*/,cBody/*cInMotAlcada*/,cRecebe)
						Return
					ElseIf aAuxRec[nPos,2] == "A" .And. !lAddDiretoria
						cHtmlModelo	:= "/workflow/aprovacao_orcamento.htm"
					ElseIf lAddDiretoria
						cHtmlModelo	:= "/workflow/aprovacao_orcamento_diretoria.htm"
					ElseIf lAddAnalista
						cHtmlModelo	:= "/workflow/aprovacao_orcamento_price.htm"
					Else
						cHtmlModelo	:= "/workflow/aprovacao_orcamento.htm"
					Endif
				Endif
			Endif
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			If MV_PAR07==1
				If lAddDiretoria
					cHtmlModelo	:= "\workflow\aprovacao_pedido_diretoria.htm"
				ElseIf lAddAnalista
					cHtmlModelo	:= "\workflow\aprovacao_pedido_price.htm"
				Else
					cHtmlModelo	:= "\workflow\aprovacao_pedido.htm"
				Endif
			Else
				If lAddDiretoria
					cHtmlModelo	:= "\workflow\aprovacao_orcamento_diretoria.htm"
				ElseIf lAddAnalista
					cHtmlModelo	:= "\workflow\aprovacao_orcamento_price.htm"
				Else
					cHtmlModelo	:= "\workflow\aprovacao_pedido.htm"
				Endif
			Endif
		Endif


		// Assunto da mensagem
		cAssunto 	:= cSubject

		If lInIsAuto
			DbSelectArea("SA3")
			DbOrderNickName("A3XCODUSR")
			//DbSetOrder(7) // A3_XCODUSR
			DbSeek(cInIdUser) 
			cBody	:= cInIdUser  + " / Solicitou a aprovação de alçada com os seguintes argumentos: " + cInMotAlcada			
		Endif

		cEmail		:= Substr(cRecebe,8)
		cEmail		:= U_BFFATM15(cEmail,"BFFATA30")
		oProcess := TWFProcess():New(cCodProcesso, cAssunto )

		oProcess:NewTask(cAssunto, cHtmlModelo)

		ConOut("(INICIO|BFFATA30)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )

		// Efetua a gravação de um log para Workflow para saber o valor das variáveis e identificar possíveis erros
		//MemoWrite("/log_sqls/bffata30_"+ Alltrim(oProcess:fProcessID)+".txt","Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID +" - cNumPed " + cNumPed + " - cHtmlModelo " + cHtmlModelo +" - cFlgRetAlc "+cFlgRetAlc + " - lInIsAuto " + Iif(lInIsAuto,".T.",".F.") + " - cUsrSendWf " + cUsrSendWf + " -  |")

		cBkProcess	:= oProcess:fProcessID
		// Repasse o texto do assunto criado para a propriedade especifica do processo.


		oProcess:oHTML:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
		oProcess:oHTML:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oProcess:oHTML:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oProcess:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oProcess:oHTML:ValByName("USUARIO"		,cUsrSendWf			)
		oProcess:oHtml:ValByName("EMAILUSER"	,U_BFFATM15(Iif(MV_PAR07==1,Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_EMTMK"),Posicione("SA3",1,xFilial("SA3")+SUA->UA_VEND,"A3_EMTMK"))+";"+UsrRetMail(cInIdUser),"BFFATA30"))
		oProcess:oHTML:ValByName("C5_NUM"		,Iif(MV_PAR07==1,SC5->C5_NUM,SUA->UA_NUM)		)
		oProcess:oHTML:ValByName("C5_EMISSAO"	,Iif(MV_PAR07==1,SC5->C5_EMISSAO,SUA->UA_EMISSAO)	)
		oProcess:oHTML:ValByName("C5_CLIENTE"	,Iif(MV_PAR07==1,SC5->C5_CLIENTE,SUA->UA_CLIENTE)	)
		oProcess:oHTML:ValByName("C5_LOJACLI"	,Iif(MV_PAR07==1,SC5->C5_LOJACLI,SUA->UA_LOJA)	)
		oProcess:oHTML:ValByName("A1_NOME"		,SA1->A1_NOME		)
		oProcess:oHTML:ValByName("A1_END"		,SA1->A1_END		)

		oProcess:oHTML:ValByName("A1_COMPLEM"	,SA1->A1_COMPLEM		)
		oProcess:oHTML:ValByName("C5_TRANSP"	,Iif(MV_PAR07==1,SC5->C5_TRANSP,SUA->UA_TRANSP)		)
		oProcess:oHTML:ValByName("A4_NREDUZ"	,SA4->A4_NREDUZ		)
		oProcess:oHTML:ValByName("A1_BAIRRO"	,SA1->A1_BAIRRO		)
		oProcess:oHTML:ValByName("A1_MUN"		,SA1->A1_MUN		)
		oProcess:oHTML:ValByName("A1_EST"		,SA1->A1_EST		)
		oProcess:oHTML:ValByName("C5_DTPROGM"	,Iif(MV_PAR07==1,SC5->C5_DTPROGM,SUA->UA_DTPROGM)		)
		oProcess:oHTML:ValByName("NEXTFAT"		,aDadEntrega[2]		)
		oProcess:oHTML:ValByName("C5_VEND1"		,Iif(MV_PAR07==1,SC5->C5_VEND1 + "-" + Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NREDUZ"),SUA->UA_VEND + "-" + Posicione("SA3",1,xFilial("SA3")+SUA->UA_VEND,"A3_NREDUZ"))	)
		oProcess:oHTML:ValByName("C5_VEND2"		,Iif(MV_PAR07==1,SC5->C5_VEND2 + "-" + Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_NREDUZ"),"")	)
		oProcess:oHTML:ValByName("PAB_PRAZO"	,aDadEntrega[4]+" - " + aDadEntrega[3]+" - " + aDadEntrega[1]		)
		oProcess:oHTML:ValByName("C5_CONDPAG"	,cCondPag	)
		oProcess:oHTML:ValByName("A1_GERAT"		,cBlqCom	)

		oProcess:oHTML:ValByName("C5_USUPED"	,Iif(MV_PAR07==1,SC5->C5_USUPED,SUA->UA_USUATEN)	)
		oProcess:oHTML:ValByName("A1_TABELA"	,cTabCli	)
		oProcess:oHTML:ValByName("C5_MSGINT"	,IIf( SA1->(FieldPos("A1_REFCOM1")) <> 0 ,IIf(Empty(SA1->A1_REFCOM1),"","Obs.Log:"+Alltrim(SA1->A1_REFCOM1)+"|"),"") + Iif(Empty(cOrdemCompra),"","Ordem Compra:"+cOrdemCompra) + Iif(MV_PAR07==1,SC5->C5_MSGINT,Alltrim(SUA->UA_MSGINT) + "<br>Observações: "+cUAOBS))
		oProcess:oHTML:ValByName("C5_MENNOTA"	,Iif(MV_PAR07==1,SC5->C5_MENNOTA,SUA->UA_MENNOTA)	)


		For iQ := 1 To Len(oMulti:aCols)

			If !oMulti:aCols[iQ,Len(oMulti:aHeader)+1]
				If !Empty(oMulti:aCols[iQ,nPxItem])
					nTotValor		+= oMulti:aCols[iQ,nPxValor]
					nTotVMargem		+= oMulti:aCols[iQ,nPxVMg1]
					nTotTampas		+= oMulti:aCols[iQ,nPxValTamp]
					nTotAddTampas	+= oMulti:aCols[iQ,nPxAddTamp]
					nTotVIR			+= oMulti:aCols[iQ,nPxVFlex]
					nTotImpostos	+= oMulti:aCols[iQ,nPxICMS] + oMulti:aCols[iQ,nPxPIS] + oMulti:aCols[iQ,nPxCofins]
					nTotMkt			+= oMulti:aCols[iQ,nPxValMkt] + oMulti:aCols[iQ,nPxValPag]
					nTotBruto		+= oMulti:aCols[iQ,nPxPrunit]*oMulti:aCols[iQ,nPxQtdVen]

					RecLock("SZT",.T.)
					SZT->ZT_FILIAL	:= xFilial("SZT")									//  CHAR(2)           '  '
					SZT->ZT_ID      	:= cBkProcess										//	CHAR(16)          '                '
					SZT->ZT_TIPO    	:= Iif(MV_PAR07==1,"P","O")						//	CHAR(1)           ' '
					SZT->ZT_NUM     	:= Iif(MV_PAR07==1,SC5->C5_NUM,SUA->UA_NUM)	//	CHAR(6)           '      '
					SZT->ZT_ITEM    	:= oMulti:aCols[iQ,nPxItem]						//	CHAR(2)           '  '
					SZT->ZT_PRODUTO 	:= oMulti:aCols[iQ,nPxProd]						//	CHAR(15)          '               '
					SZT->ZT_SALDOB2 	:= oMulti:aCols[iQ,nPxEstoque]					//	NUMBER            0.0
					SZT->ZT_QUANT   	:= oMulti:aCols[iQ,nPxQtdVen]					//	NUMBER            0.0
					SZT->ZT_PRCTAB  	:= oMulti:aCols[iQ,nPxPrunit]					//	NUMBER            0.0
					SZT->ZT_PRCVEN 		:= oMulti:aCols[iQ,nPxPrcVen]					//	NUMBER            0.0
					SZT->ZT_TOTAL  		:= oMulti:aCols[iQ,nPxValor]					//	NUMBER            0.0
					SZT->ZT_MG1     	:= oMulti:aCols[iQ,nPxVMg1]						//	NUMBER            0.0
					SZT->ZT_PMG1    	:= oMulti:aCols[iQ,nPxPMg1]						//	NUMBER            0.0
					SZT->ZT_IR      	:= oMulti:aCols[iQ,nPxVFlex]					//	NUMBER            0.0
					SZT->ZT_PIR     	:= oMulti:aCols[iQ,nPxPFlex]					//	NUMBER            0.0
					SZT->ZT_TAMPAS  	:= oMulti:aCols[iQ,nPxValTamp]					//	NUMBER            0.0
					SZT->ZT_MKT     	:= oMulti:aCols[iQ,nPxValMkt]					//	NUMBER            0.0
					SZT->ZT_FI			:= oMulti:aCols[iQ,nPxValPag]			      	//	NUMBER            0.0
					SZT->ZT_VIMCS   	:= oMulti:aCols[iQ,nPxICMS]						//	NUMBER            0.0
					SZT->ZT_VPIS    	:= oMulti:aCols[iQ,nPxPIS]						//	NUMBER            0.0
					SZT->ZT_VCOF    	:= oMulti:aCols[iQ,nPxCofins]					//	NUMBER            0.0
					SZT->ZT_VFRETE  	:= oMulti:aCols[iQ,nPxFrete]					//	NUMBER            0.0
					SZT->ZT_DESPESA 	:= oMulti:aCols[iQ,nPxDespesa]					//	NUMBER            0.0
					SZT->ZT_CMV    		:= oMulti:aCols[iQ,nPxCusto]	 				//	NUMBER            0.0
					SZT->ZT_VLRFIN  	:= oMulti:aCols[iQ,nPxXCusto]					//	NUMBER            0.0
					SZT->ZT_COMIS1  	:= oMulti:aCols[iQ,nPxComis1]					//	NUMBER            0.0
					SZT->ZT_COMIS2  	:= oMulti:aCols[iQ,nPxComis2]					//	NUMBER            0.0
					SZT->ZT_TMG1    	:= aSubValores[20]								//	NUMBER            0.0
					SZT->ZT_PTMG1   	:= aSubValores[21]								//	NUMBER            0.0
					SZT->ZT_TIR     	:= aSubValores[11]								//	NUMBER            0.0
					SZT->ZT_PTIR    	:= aSubValores[12]								//	NUMBER            0.0
					SZT->ZT_USUARIO		:= cUsrSendWf
					SZT->ZT_DATA		:= Date()
					SZT->ZT_HORA		:= Time()
					SZT->ZT_OBSERV		:= oMulti:aCols[iQ,nPxStatus]
					MsUnlock()

				Endif

				AAdd((oProcess:oHtml:ValByName("it.item"))		,oMulti:aCols[iQ,nPxItem])
				AAdd((oProcess:oHtml:ValByName("it.cod"))		,oMulti:aCols[iQ,nPxProd])
				AAdd((oProcess:oHtml:ValByName("it.desc"))		,oMulti:aCols[iQ,nPxDescri])
				AAdd((oProcess:oHtml:ValByName("it.sts"))		,oMulti:aCols[iQ,nPxStatus])
				//IAGO 25/10/2016 Chamado(16138)
				AAdd((oProcess:oHtml:ValByName("it.uqtd"))		,oMulti:aCols[iQ,nPxUQtd])
				AAdd((oProcess:oHtml:ValByName("it.uprc"))		,Transform(oMulti:aCols[iQ,nPxUPrc],oMulti:aHeader[nPxUPrc,3]))
				AAdd((oProcess:oHtml:ValByName("it.udat"))		,oMulti:aCols[iQ,nPxUDat])
				AAdd((oProcess:oHtml:ValByName("it.ucpg"))		,oMulti:aCols[iQ,nPxUCndPg])

				AAdd((oProcess:oHtml:ValByName("it.saldo"))		,oMulti:aCols[iQ,nPxEstoque])
				AAdd((oProcess:oHtml:ValByName("it.qte"))		,oMulti:aCols[iQ,nPxQtdVen])
				AAdd((oProcess:oHtml:ValByName("it.prctab"))	,Transform(oMulti:aCols[iQ,nPxPrunit],oMulti:aHeader[nPxPrunit,3]))


				nDescItem  	:=  oMulti:aCols[iQ,nPxPrcVen]
				nDescItem  	-= 	Round((oMulti:aCols[iQ,nPxAddTamp] + oMulti:aCols[iQ,nPxValTamp]) / oMulti:aCols[iQ,nPxQtdVen],4)
				nDescItem 	:=  nDescItem / oMulti:aCols[iQ,nPxPrunit] * 100
				nDescItem 	:= 100 - nDescItem
				If Empty(oMulti:aCols[iQ,nPxItem])
					nDescItem := 0
				Endif

				AAdd((oProcess:oHtml:ValByName("it.desconto")),Transform(nDescItem,"@E 999.99"))

				AAdd((oProcess:oHtml:ValByName("it.prcven"))	,Transform(oMulti:aCols[iQ,nPxPrcVen],oMulti:aHeader[nPxPrcVen,3]))

				AAdd((oProcess:oHtml:ValByName("it.total"))		,Transform(oMulti:aCols[iQ,nPxValor],oMulti:aHeader[nPxValor,3]))
				AAdd((oProcess:oHtml:ValByName("it.vlrmg"))		,Transform(oMulti:aCols[iQ,nPxVMg1],oMulti:aHeader[nPxVMg1,3]))
				AAdd((oProcess:oHtml:ValByName("it.pmg"))		,Transform(oMulti:aCols[iQ,nPxPMg1],oMulti:aHeader[nPxPMg1,3]))
				AAdd((oProcess:oHtml:ValByName("it.vlrir"))		,Transform(oMulti:aCols[iQ,nPxVFlex],"@E 99,999,999.99"))
				AAdd((oProcess:oHtml:ValByName("it.pir"))		,Transform(oMulti:aCols[iQ,nPxPFlex],oMulti:aHeader[nPxPFlex,3]))
				AAdd((oProcess:oHtml:ValByName("it.tampa"))		,Transform(oMulti:aCols[iQ,nPxValTamp],oMulti:aHeader[nPxValTamp,3]))
				AAdd((oProcess:oHtml:ValByName("it.mkt"))		,Transform(oMulti:aCols[iQ,nPxValMkt],oMulti:aHeader[nPxValMkt,3]))
				AAdd((oProcess:oHtml:ValByName("it.fandi"))		,Transform(oMulti:aCols[iQ,nPxValPag],oMulti:aHeader[nPxValPag,3]))
				AAdd((oProcess:oHtml:ValByName("it.peso"))		,Transform(oMulti:aCols[iQ,nPxPeso],oMulti:aHeader[nPxPeso,3]))
			Endif
		Next

		nTotPIR			:= nTotVIR / aSubValores[17] * 100 //nTotValor * 100
		nTotPMargem		:= nTotVMargem / aSubValores[17] * 100 //nTotValor * 100
		//nTotDesc		:= (nTotBruto - (nTotValor -  nTotTampas - nTotAddTampas ) ) /  nTotBruto * 100

		nTotDesc		:= (aSubValores[9] - aSubValores[17]) // Subtrai a diferença do que é bonificado  - Valor Total (-) Base Duplicata
		nTotDesc		+= nTotTampas
		nTotDesc 		+= nTotAddTampas

		nTotDesc := 100 - ((aSubValores[17] -  nTotDesc ) /  (aSubValores[17] + nTotBruto - aSubValores[9]) * 100)
		oProcess:oHTML:ValByName("TOTBRUTO"		,Transform(nTotBruto	,oMulti:aHeader[nPxValor,3])	)
		oProcess:oHTML:ValByName("TOTDESC"		,Transform(nTotDesc		,oMulti:aHeader[nPxValor,3])	)
		oProcess:oHTML:ValByName("TOTVALOR"		,Transform(nTotValor	,oMulti:aHeader[nPxValor,3])	)
		oProcess:oHTML:ValByName("TOTVMARGEM"	,Transform(nTotVMargem	,oMulti:aHeader[nPxVMg1,3])	)
		oProcess:oHTML:ValByName("TOTTAMPAS"	,Transform(nTotTampas	,oMulti:aHeader[nPxValTamp,3])	)
		oProcess:oHTML:ValByName("TOTPMARGEM"	,Transform(nTotPMargem	,oMulti:aHeader[nPxPMg1,3])	)
		oProcess:oHTML:ValByName("TOTVIR"		,Transform(nTotVIR		,oMulti:aHeader[nPxVFlex,3])		)
		oProcess:oHTML:ValByName("TOTIMPOSTOS"	,Transform(nTotImpostos	,oMulti:aHeader[nPxICMS,3])	)
		oProcess:oHTML:ValByName("TOTPIR"		,Transform(nTotPIR		,oMulti:aHeader[nPxPFlex,3])		)
		oProcess:oHTML:ValByName("TOTMKT"		,Transform(nTotMkt		,oMulti:aHeader[nPxValMkt,3])		)
		DbSelectArea("SA4")
		DbSetOrder(1)
		If dbSeek(xFilial("SA4")+Iif(MV_PAR07==1,SC5->C5_TRANSP,SUA->UA_TRANSP)	)
			If nTotBruto < 500 .And. Empty(aSubValores[22]) // SA4->A4_VLRMIN
				cMsgFrete	:= '<font color="#FF0000">PEDIDO ABAIXO DO MÍNIMO SEM COBRAR FRETE DESTACADO</font>'
			Endif
		Endif
		oProcess:oHTML:ValByName("TOTFRETE"		,Transform(aSubValores[18],oMulti:aHeader[nPxFrete,3]) + Iif(Empty(aSubValores[22]),cMsgFrete,"  / Frete destacado: R$ " + Transform(aSubValores[22],"@E 999.99")))
		oProcess:oHTML:ValByName("TOTPFRETE"	,Transform(aSubValores[19],"@E 999.99")				)
		oProcess:oHTML:ValByName("TOTPESO"		,Transform(aSubValores[13],"@E 999,999.999")			)

		oProcess:oHTML:ValByName("TOTRENTAB"	,Transform(nTotPMargem - GetNewPar("BF_FTA30MG",16)	,oMulti:aHeader[nPxPMg1,3])			)

		oProcess:oHTML:ValByname("OBSERV"		,cBody			)
		If MV_PAR07==1
			cQry := "SELECT Z9_DESCR"
			cQry += "  FROM "+RetSqlName("SZ9")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND Z9_EVENTO = '6' "
			cQry += "   AND Z9_NUM = '"+SC5->C5_NUM+"'"
			cQry += "   AND Z9_ORIGEM = 'P' "
			cQry += "   AND Z9_FILIAL = '"+xFilial("SZ9")+"' "
			cQry += " ORDER BY R_E_C_N_O_ DESC "

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSZ9', .F., .T.)

			If !Eof()
				oProcess:oHTML:ValByname("BLQALCADAS",	StrTran(QSZ9->Z9_DESCR,Chr(13)+Chr(10),"<p></p>"))
			Else
				oProcess:oHTML:ValByname("BLQALCADAS",	"")
			Endif
			QSZ9->(DbCloseArea())
		Else 
			cQry := "SELECT Z9_DESCR"
			cQry += "  FROM "+RetSqlName("SZ9")
			cQry += " WHERE D_E_L_E_T_ = ' ' "
			cQry += "   AND Z9_EVENTO = '6' "
			cQry += "   AND Z9_NUM = '"+SUA->UA_NUM+"'"
			cQry += "   AND Z9_ORIGEM = 'O' "
			cQry += "   AND Z9_FILIAL = '"+xFilial("SZ9")+"' "
			cQry += " ORDER BY R_E_C_N_O_ DESC "

			dbUseArea(.T.,"TOPCONN", TCGenQry(,,cQry),'QSZ9', .F., .T.)

			If !Eof()
				oProcess:oHTML:ValByname("BLQALCADAS",	StrTran(QSZ9->Z9_DESCR,Chr(13)+Chr(10),"<p></p>"))
			Else
				oProcess:oHTML:ValByname("BLQALCADAS",	"")
			Endif
			QSZ9->(DbCloseArea())
		
		Endif
		oProcess:oHTML:ValByName("data"			,Date()		)
		oProcess:oHTML:ValByName("hora"			,Time()		)
		oProcess:oHTML:ValByName("rdmake"		,FunName()+"."+ProcName(0)	)

		oProcess:cTo	:= cInIdUser//cUsuarioProtheus

		oProcess:oHTML:ValByName("DESTINATARIOS"		,cEmail)

		oProcess:aParams := {{'01',cInIdUser},{'02',cEmail}}


		// Informamos qual função será executada no evento de timeout.
		oProcess:bTimeOut        := {{"U_BFFATA34(1)", 0, 0, 5 }}
		// Informamos qual função será executada no evento de retorno.
		oProcess:bReturn        := Iif(MV_PAR07==1,"U_BFFATA34(2)","U_BFFATA34(3)")
		// Iniciamos a tarefa e recuperamos o nome do arquivo gerado.
		cMailID := oProcess:Start()

		// Força o disparo do e-mail com o link de aprovação
		WFSENDMAIL()

		// Atualiza registro do nome do arquivo
		DbSelectArea("SZT")
		DbSetOrder(1)
		DbSeek(xFilial("SZT")+cBkProcess)
		While !SZT->(Eof()) .And. SZT->ZT_ID == Padr(cBkProcess,Len(SZT->ZT_ID))
			RecLock("SZT",.F.)
			SZT->ZT_FILE		:= "/workflow/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm"
			MsUnlock()
			SZT->(DbSkip())
		Enddo

		If IsSrvUnix()
			// Arquivo html template utilizado para montagem da aprovação
			If MV_PAR07==1
				cHtmlModelo	:= "/workflow/aprovacao_pedido_link.htm"
			Else
				cHtmlModelo	:= "/workflow/aprovacao_orcamento_link.htm"
			Endif
			If !File(cHtmlModelo)
				ConOut("Não localizou arquivo "+cHtmlModelo)
				Return
			Endif
		Else
			If MV_PAR07==1
				cHtmlModelo	:= "\workflow\aprovacao_pedido_link.htm"
			Else
				cHtmlModelo	:= "\workflow\aprovacao_orcamento_link.htm"
			Endif
		Endif

		// Crie uma tarefa.
		oProcess:NewTask(cAssunto, cHtmlModelo)

		ConOut("(INICIO|WFLINK)Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )
		// Repasse o texto do assunto criado para a propriedade especifica do processo.


		oHTML := oProcess:oHTML

		oHtml:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
		oHtml:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
		oHtml:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
		oHtml:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
		oHtml:ValByName("EMAILUSER"		,U_BFFATM15(Posicione("SA3",1,xFilial("SA3") + Iif(MV_PAR07==1,SC5->C5_VEND1,SUA->UA_VEND),"A3_EMTMK")+";"+UsrRetMail(cInIdUser),"BFFATA30"))

		oHtml:ValByName("C5_NUM"		,Iif(MV_PAR07==1,SC5->C5_NUM,SUA->UA_NUM)		)
		oHtml:ValByName("C5_CLIENTE"	,Iif(MV_PAR07==1,SC5->C5_CLIENTE,SUA->UA_CLIENTE)	)
		oHtml:ValByName("C5_LOJACLI"	,Iif(MV_PAR07==1,SC5->C5_LOJACLI,SUA->UA_LOJA)	)
		oHtml:ValByName("A1_NOME"		,SA1->A1_NOME		)
		oHtml:ValByname("OBSERV"		,cBody				)
		oHtml:ValByName("proc_link_ext"	,cHostWFExt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")
		oHtml:ValByName("nome_link_ext"	,cHostWFExt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")

		oHtml:ValByName("proc_link_int"	,cHostWFInt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")
		oHtml:ValByName("nome_link_int"	,cHostWFInt + "/messenger/emp" + cEmpAnt + "/"+cInIdUser+"/" + cMailId + ".htm")

		oHtml:ValByName("data"			,Date()		)
		oHtml:ValByName("hora"			,Time()		)
		oHtml:ValByName("rdmake"		,FunName()+"."+ProcName(0)	)


		cEmail := U_BFFATM15(cEmail,"BFFATA30")
		// Trata a limpeza dos e-mails repetidos 
		cRecebe := IIf(!Empty(cEmail),cEmail+";","")	
		aOutMails	:= StrTokArr(cRecebe,";")
		cRecebe	:= ""
		For iW := 1 To Len(aOutMails)
			If !Empty(cRecebe)
				cRecebe += ";"
			Endif
			If IsEmail(aOutMails[iW]) .And. !(Alltrim(Upper(aOutMails[iW])) $ cRecebe)
				cRecebe	+= Upper(aOutMails[iW])
			Endif
		Next
		oProcess:cTo := cRecebe
		oHtml:ValByName("DESTINATARIOS"		,cRecebe)

		oProcess:cSubject := cAssunto

		// Efetua a gravação do Follow-up do pedido para consulta de históricos
		If MV_PAR07==1
			U_BFFATA35("P"/*cZ9ORIGEM*/,cNumPed/*cZ9NUM*/,"1"/*cZ9EVENTO*/,cBody/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUserName/*cZ9USER*/)
			U_GMCFGM01(	"FL"/*cTipo*/,;
				cNumPed/*cPedido*/,;
				cBody /*cObserv*/,;
				FunName()/*cResp*/,;
				/*lBtnCancel*/,;
				oProcess:cTo/*cMotDef*/,;
				.T./*lAutoExec*/)
		Else
			U_BFFATA35("O"/*cZ9ORIGEM*/,cNumPed/*cZ9NUM*/,"1"/*cZ9EVENTO*/,cBody/*cZ9DESCR*/,cEmail/*cZ9DEST*/,cUserName/*cZ9USER*/)
		Endif


		oProcess:Start()
		// Força o disparo dos emails pendentes
		WFSENDMAIL()
	Next
	If lInIsAuto
	//	MsgInfo("E-mail enviado para solicitar liberação " + cNumPed + "'","E-mail enviado!")
	Endif

Return




/*/{Protheus.doc} stSendMail
(Envio de email de Follow-up da Tela de gerenciamento de pedidos)
@author MarceloLauschner
@since 04/11/2014
@version 1.0
@param cRecebe, character, (Descrição do parâmetro)
@param cAssunto, character, (Descrição do parâmetro)
@param cMensagem, character, (Descrição do parâmetro)
@param lExibSend, ${param_type}, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stSendMail( cRecebe, cAssunto, cMensagem ,lExibSend )

	Local		aAreaOld	:= GetArea()
	Default 	lExibSend	:= .F.

	If Empty(cRecebe)
		Return
	Endif

	//Crio a conexão com o server STMP ( Envio de e-mail )
	oServer := TMailManager():New()


	// Usa SSL na conexao
	If GetMv("XM_SMTPSSL")
		oServer:setUseSSL(.T.)
	Endif

	// Usa TLS na conexao
	If GetNewPar("XM_SMTPTLS",.F.)
		oServer:SetUseTLS(.T.)
	Endif

	oServer:Init( ""		,Alltrim(GetMv("XM_SMTP")), Alltrim(GetMv("XM_SMTPUSR"))	,Alltrim(GetMv("XM_PSWSMTP")),	0			, GetMv("XM_SMTPPOR") )

	//seto um tempo de time out com servidor de 1min
	If oServer:SetSmtpTimeOut( GetMv("XM_SMTPTMT") ) != 0
		Conout( "Falha ao setar o time out" )
		RestArea(aAreaOld)
		Return .F.
	EndIf

	//realizo a conexão SMTP
	If oServer:SmtpConnect() != 0
		Conout( "Falha ao conectar" )
		RestArea(aAreaOld)
		Return .F.
	EndIf

	// Realiza autenticacao no servidor
	If GetMv("XM_SMTPAUT")
		nErr := oServer:smtpAuth(Alltrim(GetMv("XM_SMTPUSR")), Alltrim(GetMv("XM_PSWSMTP")))
		If nErr <> 0
			ConOut("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr))
			If lExibSend
				MsgAlert("[ERROR]Falha ao autenticar: " + oServer:getErrorString(nErr),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
			oServer:smtpDisconnect()
			RestArea(aAreaOld)
			Return .F.
		Endif
	Endif
	//Apos a conexão, crio o objeto da mensagem
	oMessage := TMailMessage():New()
	//Limpo o objeto
	oMessage:Clear()
	//Populo com os dados de envio
	oMessage:cFrom 		:= UsrRetMail(__cUserId)//GetMv("XM_SMTPDES")
	oMessage:cTo 		:= cRecebe
	//		oMessage:cCc 		:= "nfe@gmeyer.com.br"
	oMessage:cSubject 	:= cAssunto
	oMessage:cBody 		:= StrTran(cMensagem,Chr(13)+Chr(10),"<br>")
	oMessage:MsgBodyType( "text/html" )

	//Envio o e-mail
	If oMessage:Send( oServer ) != 0
		Conout( "Erro ao enviar o e-mail" )
		RestArea(aAreaOld)
		Return .F.
	Else
		If lExibSend
			MsgAlert("Email enviado com sucesso!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Concluído")
		Endif
	EndIf

	//Disconecto do servidor
	If oServer:SmtpDisconnect() != 0
		Conout( "Erro ao disconectar do servidor SMTP" )
		RestArea(aAreaOld)
		Return .F.
	EndIf

Return




/*/{Protheus.doc} sfSendCot
(Enviar Workflow de Cotação para cliente)
@author MarceloLauschner
@since 08/09/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfSendCot()

	Local		aAreaOld		:= GetArea()

	Local	cNumPed			:= aListPed[oArqPed:nAt,3]
	Local 	oProcess     	:= Nil                                	//Objeto da classe TWFProcess.
	Local	lSend			:= .F.
	Local	nTotValor		:= 0
	Local	oDlgEmail
	Local	cRecebe			:= Padr(UsrRetMail(RetCodUsr()),200)
	Local	cSubject		:= Padr(IIf(MV_PAR07==2,"Cotação: ","Pedido: ") + cNumPed + " " + AllTrim(SM0->M0_NOMECOM),150)
	Local	cBody			:= Space(500)
	Local	iZ
	Local 	iW 
	Local	cCodProcesso
	Local	cHtmlModelo
	Local	cAssunto

	If MV_PAR07==2
		DbSelectArea("SUA")
		DbSetOrder(1)
		If !DbSeek(xFilial("SUA")+cNumPed)
			RestArea(aAreaOld)
			Return
		Endif
	Else
		DbSelectArea("SC5")
		DbSetOrder(1)
		If !DbSeek(xFilial("SC5")+cNumPed)
			RestArea(aAreaOld)
			Return
		Endif
	Endif


	DEFINE MSDIALOG oDlgEmail Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Enviar email de cotação!") FROM 001,001 TO 380,620 PIXEL

	@ 010,010 Say "Para: " Pixel of oDlgEmail
	@ 010,050 MsGet cRecebe Size 180,10 Pixel Of oDlgEmail
	@ 025,010 Say "Assunto" Pixel of oDlgEmail
	@ 025,050 MsGet cSubject Picture "@#" Size 250,10 Pixel Of oDlgEmail
	@ 040,050 Get cBody of oDlgEmail MEMO Size 250,100 Pixel

	@ 160,050 BUTTON "Envia Email" Size 70,10 Action (lSend := .T.,oDlgEmail:End())	Pixel Of oDlgEmail
	@ 160,130 BUTTON "Cancela" Size 70,10 Action (oDlgEmail:End())	Pixel Of oDlgEmail

	ACTIVATE MsDialog oDlgEmail Centered

	If !lSend
		Return
	Endif


	// Código extraído do cadastro de processos.
	cCodProcesso := "ORC003" // SOLICITACAO DE APROVACAO DE PEDIDO A DIRETORIA

	If IsSrvUnix()
		// Arquivo html template utilizado para montagem da aprovação
		cHtmlModelo	:= "/workflow/orcamento_tmk_cliente.htm"
		If !File(cHtmlModelo)
			Return
		Endif
	Else
		cHtmlModelo	:= "\workflow\orcamento_tmk_cliente.htm"
	Endif

	// Assunto da mensagem
	cAssunto 	:= cSubject


	oProcess := TWFProcess():New(cCodProcesso, cAssunto )

	oProcess:NewTask(cAssunto, cHtmlModelo)

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+ IIF(MV_PAR07==1,SC5->C5_CLIENTE+SC5->C5_LOJACLI,SUA->UA_CLIENTE+SUA->UA_LOJA))

	oProcess:oHTML:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
	oProcess:oHTML:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oProcess:oHTML:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oProcess:oHTML:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)
	oProcess:oHtml:ValByName("EMAILUSER"	,UsrRetMail(RetCodUsr()))
	oProcess:oHTML:ValByName("ORCAMENTO"	,cNumPed			)
	oProcess:oHTML:ValByName("EMISSAO"		,IIF(MV_PAR07==1,SC5->C5_EMISSAO,SUA->UA_EMISSAO)	)
	oProcess:oHTML:ValByName("CLIENTE"		,IIF(MV_PAR07==1,SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI,SUA->UA_CLIENTE+"/"+SUA->UA_LOJA)	)
	oProcess:oHTML:ValByName("CGC"			,Transform(SA1->A1_CGC,"@R 99.999.999/9999-99")		)
	oProcess:oHTML:ValByName("NOME"			,SA1->A1_NOME		)

	oProcess:oHTML:ValByName("CONDPAG"		,cCondPag	)
	oProcess:oHTML:ValByName("ENDERECO"		,Alltrim(SA1->A1_END) + Alltrim(SA1->A1_COMPLEM)	)
	oProcess:oHTML:ValByName("BAIRRO"		,Alltrim(SA1->A1_BAIRRO))
	oProcess:oHTML:ValByName("CIDADE"		,Alltrim(SA1->A1_MUN))
	oProcess:oHTML:ValByName("ESTADO"		,SA1->A1_EST		)


	For iZ := 1 To Len(oMulti:aCols)

		If !oMulti:aCols[iZ,Len(oMulti:aHeader)+1]
			AAdd((oProcess:oHtml:ValByName("it.item"))	,oMulti:aCols[iZ,nPxItem]+"-"+oMulti:aCols[iZ,nPxSequenc])
			AAdd((oProcess:oHtml:ValByName("it.cod"))		,oMulti:aCols[iZ,nPxProd])
			AAdd((oProcess:oHtml:ValByName("it.desc"))	,oMulti:aCols[iZ,nPxDescri])

			If !Empty(oMulti:aCols[iZ,nPxItem])
				nTotValor		+= oMulti:aCols[iZ,nPxValor]
				AAdd((oProcess:oHtml:ValByName("it.qte"))		,oMulti:aCols[iZ,nPxQtdVen])
				AAdd((oProcess:oHtml:ValByName("it.prcven"))	,Transform(oMulti:aCols[iZ,nPxPrcVen],oMulti:aHeader[nPxPrcVen,3]))
			Else
				AAdd((oProcess:oHtml:ValByName("it.qte"))		,""	)
				AAdd((oProcess:oHtml:ValByName("it.prcven"))	,""	)
			Endif
			AAdd((oProcess:oHtml:ValByName("it.total"))	,Transform(oMulti:aCols[iZ,nPxValor],oMulti:aHeader[nPxValor,3]))


		Endif
	Next

	oProcess:oHTML:ValByName("TOTVALOR"	,Transform(nTotValor	,oMulti:aHeader[nPxValor,3])	)

	oProcess:oHTML:ValByname("OBSERV"		,cBody			)
	oProcess:oHTML:ValByName("data"			,Date()		)
	oProcess:oHTML:ValByName("hora"			,Time()		)
	oProcess:oHTML:ValByName("rdmake"		,FunName()+"."+ProcName(0)	)

	oProcess:cSubject := cSubject

	
	cEmail := U_BFFATM15(cRecebe+";"+UsrRetMail(RetCodUsr()),"BFFATA30")
	// Trata a limpeza dos e-mails repetidos 
	cRecebe := IIf(!Empty(cEmail),cEmail+";","")	
	aOutMails	:= StrTokArr(cRecebe,";")
	cRecebe	:= ""
	For iW := 1 To Len(aOutMails)
		If !Empty(cRecebe)
			cRecebe += ";"
		Endif
		If IsEmail(aOutMails[iW]) .And. !(Alltrim(Upper(aOutMails[iW])) $ cRecebe)
			cRecebe	+= Upper(aOutMails[iW])
		Endif
	Next
	oProcess:cTo := cRecebe

	oProcess:Start()
	oProcess:Finish()

	// Força o disparo dos emails pendentes do workflow
	WFSENDMAIL()
	
	MsgInfo("Mensagem enviada com cópia para '"+UsrRetMail(RetCodUsr())+"'",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Workflow")

	RestArea(aAreaOld)

Return



/*/{Protheus.doc} sfVerFollow
(Visualizar descrição completa do Follow-up de pedidos)
@author MarceloLauschner
@since 04/11/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfVerFollow()


	DbSelectArea("SZ9")
	DbGoto(aListLog[oArqLog:nAT,7])
	//	AxVisual("SZ9",SZ9->(Recno()),2)

	DEFINE MSDIALOG oDlgZ9 Title OemToAnsi(ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Dados Follow-up!") FROM 001,001 TO 300,620 PIXEL

	@ 010,010 Say RetTitle("Z9_DEST",30) Pixel of oDlgZ9
	@ 010,050 MsGet SZ9->Z9_DEST Size 180,10 Pixel Of oDlgZ9 When .F.
	@ 025,010 Say RetTitle("Z9_DESCR",30) Pixel of oDlgZ9
	@ 025,050 Get SZ9->Z9_DESCR of oDlgZ9 MEMO Size 250,100 Pixel When .F.

	@ 135,130 BUTTON "Cancela" Size 70,10 Action (oDlgZ9:End())	Pixel Of oDlgZ9

	ACTIVATE MsDialog oDlgZ9 Centered

	/*
	SZ9->Z9_ORIGEM	:= cZ9ORIGEM
	SZ9->Z9_NUM		:= cZ9NUM
	SZ9->Z9_DATA		:= Date()
	SZ9->Z9_HORA		:= Time()
	SZ9->Z9_EVENTO	:= cZ9EVENTO
	SZ9->Z9_DESCR		:= cZ9DESCR
	SZ9->Z9_DEST		:= cZ9DEST
	SZ9->Z9_USER		:= cZ9USER*/

Return




User Function BFFT30B3(cInCodPrd,nInQte,nInSaldB2,nInCusto,cInFor,cInLoj,nInCustD,lInIsAprvDir,cInArmzem)

Return sfCustD(cInCodPrd,nInQte,nInSaldB2,nInCusto,cInFor,cInLoj,nInCustD,lInIsAprvDir,cInArmzem)

/*/{Protheus.doc} sfCustD
(Calcula o custo de estoque médio e de reposição conforme disponibilidade do estoque)
@author MarceloLauschner
@since 12/06/2015
@version 1.0
@param cInCodPrd, character, (Descrição do parâmetro)
@param nInQte, numérico, (Descrição do parâmetro)
@param nInSaldB2, numérico, (Descrição do parâmetro)
@param nInCusto, numérico, (Descrição do parâmetro)
@param cInFor, character, (Descrição do parâmetro)
@param cInLoj, character, (Descrição do parâmetro)
@param nInCustD, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCustD(cInCodPrd,nInQte,nInSaldB2,nInCusto,cInFor,cInLoj,nInCustD,lInIsAprvDir,cInArmzem)

	Local	aAreaOld		:= GetArea()
	Local	nRetCust		:= 0
	Local	nCustRep		:= 0
	Default	lInIsAprvDir	:= .F.
	Default cInArmzem		:= "01"

	nInCusto	:= Iif((nInCustD*nInQte) > nInCusto, (nInCustD * nInQte),nInCusto )
	
	If nInSaldB2 >= nInQte
		nRetCust	:= nInCusto
	Else
		// Se ainda tem algum saldo de estoque assume como custo parcial
		If nInSaldB2 > 0
			nRetCust 	:=	Round((nInCusto / nInQte) * nInSaldB2,2)
		Endif

		// Se o custo de reposição for zerado, irá assumir o valor de Custo Standard passado como parametro
		If nCustRep	<= 0
			nCustRep	:= nInCustD
		Endif

		//Evita que se o custo de retorno for zero, gere uma margem muito alta por que o estoque está zerado
		If nCustRep	<= 0
			nCustRep	:= (nInCusto/nInQte) * 1.10
		Endif

		// Atribui o valor de estoque de reposição no custo de retorno
		nRetCust 	+= Round(nCustRep * ( nInQte - nInSaldB2 ),2)
	Endif

	RestArea(aAreaOld)

Return nRetCust




/*/{Protheus.doc} sfConsCad
Função que realiza a consulta do Contribuinte junto a Sefaz - Sintegra
@type function
@version
@author Eduardo Silva
@since 13/06/2011
@param cIE, character, Inscrição Estadual
@param cUF, character,  Unidade Federativa (Estado)
@return logical, return_description
/*/
Static Function sfConsCad(cIE,cUF)

	Local aAreaOld		:= GetArea()
	Local cURL     		:= PadR(GetNewPar("MV_SPEDURL","http://"),250)
	Local cIdEnt    	:= ""
	Local cRazSoci 		:= ""
	Local cRegApur    	:= ""
	Local cCnpj	      	:= ""
	Local cCpf	      	:= ""
	Local cSituacao   	:= ""
	Local cPictCNPJ		:= ""

	Local dIniAtiv    	:= Date()
	Local dAtualiza		:= Date()
	Local lRet			:= .T.
	Local nX	    	:= {}

	Private oWS

	cIdEnt		:=  U_MLTSSENT()


	oWs:= WsNFeSBra() :New()
	oWs:cUserToken    	:= "TOTVS"
	oWs:cID_ENT			:= cIdEnt
	oWs:cUF				:= cUF
	oWs:cCNPJ			:= ""
	oWs:cCPF			:= ""
	oWs:cIE				:= Alltrim(cIE)
	oWs:_URL          	:= AllTrim(cURL)+"/NFeSBRA.apw"

	If oWs:CONSULTACONTRIBUINTE()

		If Type("oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE") <> "U"
			If ( Len(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE) > 0 )
				nX := Len(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE)

				If ValType(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dInicioAtividade) <> "U"
					dIniAtiv  := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dInicioAtividade
				Else
					dIniAtiv  := ""
				EndIf
				cRazSoci  	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cRazaoSocial
				cRegApur  	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cRegimeApuracao
				cCnpj	    := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cCNPJ
				cCpf	    := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cCPF
				cIe       	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cIE
				cUf	    	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cUF
				cSituacao 	:= oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:cSituacao

				If ValType(oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dUltimaSituacao) <> "U"
					dAtualiza := oWs:OWSCONSULTACONTRIBUINTERESULT:OWSNFECONSULTACONTRIBUINTE[nX]:dUltimaSituacao
				Else
					dAtualiza := ""
				EndIf

				If ( cSituacao == "1" )
					cSituacao := "1 - Habilitado"
				ElseIf ( cSituacao == "0" )
					cSituacao := "0 - Não Habilitado"
				EndIf


				If ( !Empty(cCnpj) )
					cCnpj		:= cCnpj
					cPictCNPJ	:= "@R 99.999.999/9999-99"
				Else
					cCnpj		:= cCPF
					cPictCNPJ	:= "@R 999.999.999-99"
				EndIf


				If cSituacao == "0 - Não Habilitado"
					lRet	:= .F.

					DEFINE FONT oFont BOLD

					DEFINE MSDIALOG oDlgKey TITLE "Retorno do Consulta Contribuinte" FROM 0,0 TO 200,355 PIXEL OF GetWndDefault()  //"Retorno do Consulta Contribuinte"

					@ 008,010 SAY "Início das Atividades:"		 PIXEL FONT oFont OF oDlgKey    	//"Início das Atividades:"
					@ 008,072 SAY If(Empty(dIniAtiv),"",DtoC(dIniAtiv))	 PIXEL OF oDlgKey
					@ 008,115 SAY "UF:" 		 PIXEL FONT oFont OF oDlgKey		//"UF:"
					@ 008,124 SAY cUf			 PIXEL OF oDlgKey
					@ 020,010 SAY "Razão Social:"		 PIXEL FONT oFont OF oDlgKey 		//"Razão Social:"
					@ 020,048 SAY cRazSoci		 PIXEL OF oDlgKey
					@ 032,010 SAY "CNPJ/CPF:"		 PIXEL FONT oFont OF oDlgKey  	//"CNPJ/CPF:"
					@ 032,040 SAY cCnpj		 PIXEL PICTURE cPictCNPJ OF oDlgKey
					@ 032,115 SAY "IE:"		 PIXEL FONT oFont OF oDlgKey  	//"IE:"
					@ 032,123 SAY cIe			 PIXEL OF oDlgKey
					@ 044,010 SAY "Regime:"		 PIXEL FONT oFont OF oDlgKey  	//"Regime:"
					@ 044,035 SAY cRegApur		 PIXEL OF oDlgKey
					@ 056,010 SAY "Situação:"		 PIXEL FONT oFont OF oDlgKey  	//"Situação:"
					@ 056,038 SAY cSituacao		 PIXEL OF oDlgKey
					@ 068,010 SAY "Atualizado em:"   	 PIXEL FONT oFont OF oDlgKey  	 //"Atualizado em:"
					@ 068,055 SAY If(Empty(dAtualiza),"",DtoC(dAtualiza))	 PIXEL OF oDlgKey

					@ 80,137 BUTTON oBtnCon PROMPT "Ok" SIZE 38,11 PIXEL ACTION oDlgKey:End()	//"Ok"

					ACTIVATE DIALOG oDlgKey CENTERED
				Endif
			EndIf
		EndIf
	Else
		//Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"Erro Sped TSS"},3)
	EndIf

	RestArea(aAreaOld)
Return lRet

/*/{Protheus.doc} profAdjust
Função para ajustar profile do usuário que estiver com problema nos parâmetros
@type function
@version 12.1.33
@author Jean Carlos Pandolfo Saggin
@since 9/5/2022
@param cID, character, ID único do usuário no sistema
@param cGrp, character, grupo de perguntas a ser ajustada no profile
@return logical, lDone
/*/
static function profAdjust( cID, cGrp )
	
	local lDone    := .T. as logical
	local cP_NAME  := PADR( cID, 20, ' ' )
	local cP_PROG  := PADR( cGrp, 10, ' ' )
	local cP_TASK  := "PERGUNTE "
	local cP_TYPE  := "MV_PAR "
	local cCont    := ""  as character
	local nCont    := 0   as numeric
	local aCont    := {}  as array
	local cLine    := ""  as character
	local cNewMemo := ""  as character
	local nX       := 0   as numeric
	local cAli     := "ProfAlias"
	local lNeedChg := .F. as logical

	DBSelectArea( "SX1" )
	SX1->( DBSetOrder( 1 ) )		// X1_GRUPO + X1_ORDEM

	if Select( cAli ) > 0
		DBSelectArea( cAli )
		( cAli )->( DBSetOrder( 1 ) )		// P_NAME + P_PROG + P_TASK + P_TYPE
		if ( cAli )->( DBSeek( cP_NAME + cP_PROG + cP_TASK + cP_TYPE ) )
			while ( cAli )->P_NAME + ( cAli )->P_PROG + ( cAli )->P_TASK + ( cAli )->P_TYPE ==;
				cP_NAME + cP_PROG + cP_TASK + cP_TYPE
				cCont := ( cAli )->P_DEFS
				nCont := MLCount( cCont )
				if nCont > 0
					For nX := 1 to nCont
						cLine := MemoLine( cCont,,nX )
						if SX1->( DBSeek( cP_PROG + StrZero( nX, 2 ) ) )
							if SubStr( cLine, 01, 01 ) == "C" .and. SubStr( cLine, 01, 01 ) == SX1->X1_TIPO
								cLine := SubStr( cLine, 01, 04 ) + PADR( StrTokArr2( AllTrim(cLine), '#', .T. )[3], SX1->X1_TAMANHO, ' ' )
								lNeedChg := .T.
							endif
						endif
						aAdd( aCont, cLine )
					next nX
				endif
				( cAli )->( DBSkip() )
			enddo
			//VarInfo( 'Profile', aCont )
			if lNeedChg
				aEval( aCont, {|x| cNewMemo += (x + chr(13) + chr(10)) } )
				WriteProfDef(cP_NAME, cP_PROG, cP_TASK, cP_TYPE,; // Chave antiga
							cP_NAME, cP_PROG, cP_TASK, cP_TYPE, ; // Chave nova
							cNewMemo)
			endif
		endif
	Endif
return lDone
