#INCLUDE "PROTHEUS.CH"
#include "RWMAKE.ch"
#include "Topconn.ch"
#Include "ap5mail.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "TBICODE.CH"
#Include "aarray.ch"
#Include "json.ch"
#Include "shash.ch"

/*/{Protheus.doc} GERA_PED
Integração Máxima - Importação de pedidos 
@type function
@version 1.0
@since 25/03/2021
/*/
User Function GERA_PED()

	//1=Usuario, 2=senha, 3=CÃ³digo Grupo Empresa, 4=CÃ³digo Filial, 5=CÃ³digo UsuÃ¡rio, 6=Id da tarefa.
 
	Local nOpc     		:= 3 // inclusao
	Local aItens        := {}
	Local aCabSC5     	:= {}
	
	LOCAL CTES 				:= SUPERGETMV("XX_TES", .F., "")
	LOCAL COPER 			:= SUPERGETMV("XX_OPER", .F., "")

	LOCAL CTES2 			:= SUPERGETMV("XX_TE2", .F., "")
	LOCAL COPER2			:= SUPERGETMV("XX_OPER2", .F., "")

	LOCAL CTES3 			:= SUPERGETMV("XX_TE3", .F., "")
	LOCAL COPER3			:= SUPERGETMV("XX_OPER3", .F., "")

	Local cTEsNew 			:= "   "
	Local cEmpImpPed		:= ""
	//Local cC6Local			:= ""
	Local cFilMaxima		:= ""
	Local cCCusto 			:= ""
	Local xx 
	Local nx 

	Private aDadosSC5		:= {}
	Private aDadosSC6		:= {}

	Private aFields   		:= {}
	Private cArq
	Private aFields2  		:= {}
	Private cArq2

	PRIVATE lMsErroAuto 	:= .F.	// Variável que define que o Help deve ser gravado no arquivo de Log e que as informações estão vindo à partir da rotina automática.
	Private lMsHelpAuto 	:= .T.
	Private lAutoErrNoFile	:= IsBlind()
	
	cEmpImpPed				:= Substr(oRetorno:Filial:Codigo,1,2)

	// Quando a Empresa do pedido a importar for diferente da empresa em execução - não importa
	If cEmpImpPed <> cEmpAnt
		Return
	Endif

	// Cria controle de semaforo para execução da rotina 
	If !U_DCCFGM01(.T./*lLock*/,"GERAPED_MAXIMA"/*cKey*/,"Importação de Pedidos Máxima - Empresa " + cEmpAnt + " Filial " + cFilAnt  /*cMsg*/,/*lTrvEmp*/,/*lTrvFil*/,lAutoErrNoFile/*lExeAuto*/)
		Return 
	Endif 

	cFilMaxima 		:= ALLTRIM(ORETORNO:FILIAL:CODIGO)
	
	// Se for a filial retira 010202 - muda para 0102 pois não existe no Protheus 
	If cFilMaxima 	== "010202"
		cFilMaxima := "0102" 
	Endif 

	//TRATAR QUESTÃƒO DA FILIAL
	CXFILIAL := ""
	IF cFilMaxima != CFILANT
		CXFILIAL := CFILANT
		CFILANT  := cFilMaxima
	ENDIF


	CCLIENTE := SUBSTR(ORETORNO:CLIENTE:CODIGOPRINCIPAL,1,8)
	CLOJA    := SUBSTR(ORETORNO:CLIENTE:CODIGOPRINCIPAL,9,4)
	CTIPO    := POSICIONE("SA1",1,XFILIAL("SA1")+CCLIENTE+CLOJA,"A1_TIPO")
	CCOND    := ORETORNO:PLANOPAGAMENTO:CODIGO

	// Quando for empresa 02-Hermann retira o H do código 
	If cEmpImpPed == "02"
		CTABELA  := Substr(oRetorno:Cliente:Praca:Regiao:Codigo,2) 
	Else
		CTABELA  := ORETORNO:CLIENTE:PRACA:REGIAO:CODIGO
	Endif

	CTPFRETE := IIF(TYPE("ORETORNO:FRETEDESPACHO")=="C",ORETORNO:FRETEDESPACHO,"F")
	NFRETE   := ORETORNO:VALORFRETE
	CTRANSP  := IIF(TYPE("ORETORNO:CLIENTE:CODFORNECFRETE")=="C",ORETORNO:CLIENTE:CODFORNECFRETE,"")
	IF TYPE("ORETORNO:DATAFECHAMENTOPEDIDO") != "U"
		CDATA    := ORETORNO:DATAFECHAMENTOPEDIDO
		DEMISSAO := STOD(SUBSTR(STRTRAN(ORETORNO:DATAFECHAMENTOPEDIDO,"-",""),1,8))
	ELSE
		CDATA    := ""
		DEMISSAO := DDATABASE
	ENDIF
	CMENSAG  := ORETORNO:OBSERVACAO
	CVEND    := ORETORNO:CODUSUARIO
	CPEDIDO  := CVALTOCHAR(ORETORNO:NUMPEDIDO)
	CFORMA   := ORETORNO:CLIENTE:COBRANCA:CODIGO

	CTIPOPED := ORETORNO:TIPOVENDA:CODIGO

	//CUSTOMIZAÇÃO
	COBS     := ""
	COBSENTR := ""

	COBS     := ORETORNO:OBSERVACAO
	COBSENTR := ORETORNO:OBSERVACAOENTREGA
	CNPEDCLI := CVALTOCHAR(ORETORNO:NumPedidoCliente)

	NDESCCAB := ORETORNO:PercDescontoCabecalho * 100

// -- TESTA SE O PEDIDO JÃ¡ EXISTE NA BASE DE DADOS
//SC5->(DBORDERNICKNAME("XXPEDMA"))
//IF SC5->(DBSEEK(XFILIAL("SC5")+PADL(ALLTRIM(CPEDIDO),10)+PADL(ALLTRIM(CVEND),6)))
//	MSGINFO("Pedido jÃ¡ importado!")
//	RETURN
//ENDIF

	CQUERYX := "SELECT C5_FILIAL,C5_NUM FROM " + RETSQLNAME("SC5")
	CQUERYX += " WHERE D_E_L_E_T_ = ' '"
	CQUERYX += " AND C5_XXPEDMA = '"+CPEDIDO+"'"

	IF SELECT("TMPSC5") > 0
		TMPSC5->(DBCLOSEAREA())
	ENDIF

	TCQUERY CQUERYX NEW ALIAS "TMPSC5"

	IF !TMPSC5->(EOF())
		MSGINFO("Pedido " + CPEDIDO + " já foi importado!")

		NSTATUS := 4
		NTIPOCRITICA := 0
		CTIPO := "Sucesso"
		CPED  := StrZero((Val(TMPSC5->C5_FILIAL)*1000000) + Val(TMPSC5->C5_NUM)) 
		CDESC := '"Pedido Importado com Sucesso"'
		TMPSC5->(DBCLOSEAREA())
		ENVIA_RES()

		RETURN
	ENDIF

	ACABSC5:= {}

	AADD(ACABSC5,{"C5_TIPO"    ,"N"        	,NIL})
	AADD(ACABSC5,{"C5_CLIENTE" ,CCLIENTE	,NIL})
	AADD(ACABSC5,{"C5_LOJACLI" ,CLOJA   	,NIL})
	AADD(ACABSC5,{"C5_CONDPAG" ,CCOND		,NIL})
	AADD(ACABSC5,{"C5_TABELA"  ,CTABELA 	,NIL})
	AADD(ACABSC5,{"C5_TPFRETE" ,"C"			,NIL})

	//AADD(ACABSC5,{"C5_TRANSP"  ,CTRANSP 	,NIL})
	AADD(ACABSC5,{"C5_EMISSAO" ,DEMISSAO	,NIL})
	AADD(ACABSC5,{"C5_CLIENT"  ,CCLIENTE	,NIL})
	AADD(ACABSC5,{"C5_LOJAENT" ,CLOJA   	,NIL})
	AADD(ACABSC5,{"C5_VEND1"   ,CVEND  		,NIL})
	AADD(ACABSC5,{"C5_XXPEDMA" ,CPEDIDO   	,NIL})//CRIAR CAMPO - OK
	AADD(ACABSC5,{"C5_XXTIPO"  ,CVALTOCHAR(CTIPOPED)   	,NIL})//CRIAR CAMPO - OK
	AADD(ACABSC5,{"C5_XXFORMA" ,CFORMA   	,NIL})//CRIAR CAMPO - OK

	AADD(ACABSC5,{"C5_ZBOLETO" ,CFORMA   	,NIL})//CRIAR CAMPO - OK

	AADD(ACABSC5,{"C5_DESC1"  ,NDESCCAB    ,NIL})

	// 21/01/2021 - Marcelo A Lauschner - Adição de campos 
	Aadd(aCabSC5,{"C5_ZDTMAX" 	,Date() 	,Nil })
	Aadd(aCabSC5,{"C5_ZHRMAX"	,Time()		,Nil })
	Aadd(aCabSC5,{"C5_ZOPRMAX"	,StrZero(CTIPOPED,2)	,Nil 	}) 
	Aadd(aCabSC5,{"C5_ZOBPMAX"	,ORETORNO:OBSERVACAO	,Nil	})
	Aadd(aCabSC5,{"C5_ZMSGINT"	,("Cadastro: "+MSMM(SA1->A1_OBS,,,,3,,,"SA1","A1_OBS")+ Chr(13) + Chr(10) +"Mensagem do Vendedor: "+COBS)	,Nil	})
	Aadd(aCabSC5,{"C5_ZOBNMAX"	,ORETORNO:OBSERVACAOENTREGA,Nil	})
	Aadd(aCabSC5,{"C5_ZMENNOT"	,ORETORNO:OBSERVACAOENTREGA,Nil	})
	Aadd(aCabSC5,{"C5_ZXPED"	,CVALTOCHAR(ORETORNO:NumPedidoCliente),Nil	})
	

	CITEM := "00" //Inicia a sequencia do item com 00 para ser incrementada em 1 no inicio do while

	//C5_CLIENTE+C5_LOJACLI+C5_CONDPAG+C5_EMISSAO+C5_XXPEDMA+C5_ZOBSENT+C5_VEND1
	aDadosSC5	:= {CCLIENTE,CLOJA,CCOND,DEMISSAO,CPEDIDO,COBS,CVEND,COBSENTR}

	AITENS := {}

	DbSelectArea("SA3")
	DbSetOrder(1)
	DbSeek(xFilial("SA3")+CVEND)
	cCCusto := SA3->A3_ZCCUSTO //Para Utilização em pedidos de brinde

	FOR XX := 1 TO LEN(ORETORNO:PRODUTOS)
		// Quando for empresa 02-Hermann - Substrai o H do código inicial
		If cEmpImpPed == "02"
			CPRODUTO := Substr(ORETORNO:PRODUTOS[XX]:CODIGO,2)
		Else
			CPRODUTO := ORETORNO:PRODUTOS[XX]:CODIGO
		Endif
		//Quando sufixo do codigo tiver "A", remover
		If RIGHT(TRIM(ORETORNO:PRODUTOS[XX]:CODIGO),1) == "A"
			CPRODUTO := STRTRAN(ORETORNO:PRODUTOS[XX]:CODIGO,"A","")
		Endif
		
		//Se não existir saldo na 0107, criar SB2
		If cFilAnt == "0107"
			CPRODUTO := Padr(CPRODUTO,TamSX3("B2_COD")[1])
			DbSelectArea("SB2")
			SB2->(DbSetOrder(1))
			If DbSeek("0107"+CPRODUTO+"01")
				//ALERT("já existe sb2 de: "+CPRODUTO+"/"+cFilAnt)
			Else 
	  			CriaSb2(CPRODUTO,"01")
			Endif
		EndIf

//fim

		NQUANT   := ORETORNO:PRODUTOS[XX]:QUANTIDADE
		NPRCVEN  := ORETORNO:PRODUTOS[XX]:PrecoVendaSemImpostos//PRECOBASE
		NPRCTAB  := ORETORNO:PRODUTOS[XX]:PrecoTabelaInformado
		NDESCON  := ORETORNO:PRODUTOS[XX]:PercDescontoInformadoTela * 100

		CITEM := SOMA1(CITEM,2)
		AITEM := {}

		cOBSPedido := "Preço Tabela: "+cValtoChar(NPRCTAB)
		cOBSPedido += ", Preço Venda: "+cValtoChar(NPRCVEN)
		cOBSPedido += ", Desconto site: "+cValToChar(NDESCON)

		AADD(AITEM, {"C6_ITEM"   , CITEM		, NIL})
		AADD(AITEM, {"C6_PRODUTO", CPRODUTO 	, NIL})
		AADD(AITEM, {"C6_QTDVEN" , NQUANT		, NIL})
		AADD(AITEM, {"C6_ZDESITE" , NDESCON 	, NIL})  // Desconto produto
		AADD(AITEM, {"C6_VDOBS" , cOBSPedido 	, NIL}) 

		//AADD(AITEM, {"C6_XPDESCO", 0			, NIL})
		//AADD(AITEM, {"C6_PRUNIT" , NPRCTAB		, NIL})
		//AADD(AITEM, {"C6_UNSVEN" , 0			, NIL})
		// Comentado em 09/10/2020 - Afins de não preencher a informação
		//AADD(AITEM, {"C6_ENTREG" , DEMISSAO+10 	, NIL})

		//VERIFICA QUAL O TIPO DO PEDIDO DE VENDA
		DO CASE
		CASE CTIPOPED == 1//VENDA NORMAL
			IF !EMPTY(COPER)
				cTesNew 	:= MaTesInt(2,COPER,CCLIENTE,CLOJA,"C",CPRODUTO)
				If !Empty(cTesNew)
					AADD(AITEM, {"C6_TES"   ,cTesNew			, NIL})
				Else
					IF !EMPTY(CTES)
						AADD(AITEM, {"C6_TES"   ,CTES			, NIL})
					ENDIF
				Endif
				//AADD(AITEM, {"C6_OPER"   ,COPER			, NIL})
				//AADD(ACABSC5,{"C5_XOPER"   ,COPER  		,NIL})
			ELSE
				IF !EMPTY(CTES)
					AADD(AITEM, {"C6_TES"   ,CTES			, NIL})
				ENDIF
			ENDIF
		CASE CTIPOPED == 5//BONIFICAÃ‡ÃƒO
			IF !EMPTY(COPER2)
				cTesNew 	:= MaTesInt(2,COPER2,CCLIENTE,CLOJA,"C",CPRODUTO)
				If !Empty(cTesNew)
					AADD(AITEM, {"C6_TES"   ,cTesNew			, NIL})
					AADD(AITEM, {"C6_CC"	,cCCusto			, NIL})
				Else
					IF !EMPTY(CTES2)
						AADD(AITEM, {"C6_TES"   ,CTES2			, NIL})
						AADD(AITEM, {"C6_CC"	,cCCusto		, NIL})
					ENDIF
				Endif
				//AADD(AITEM, {"C6_OPER"   ,COPER2			, NIL})
				//AADD(ACABSC5,{"C5_XOPER"   ,COPER2  		,NIL})
			ELSE
				IF !EMPTY(CTES2)
					AADD(AITEM, {"C6_TES"   ,CTES2			, NIL})
					AADD(AITEM, {"C6_CC"	,cCCusto		, NIL})
				ENDIF
			ENDIF
		CASE CTIPOPED == 11//TROCA
			IF !EMPTY(COPER3)
				cTesNew 	:= MaTesInt(2,COPER3,CCLIENTE,CLOJA,"C",CPRODUTO)
				If !Empty(cTesNew)
					AADD(AITEM, {"C6_TES"   ,cTesNew			, NIL})
				Else
					IF !EMPTY(CTES)
						AADD(AITEM, {"C6_TES"   ,CTES3			, NIL})
					ENDIF
				Endif
				//AADD(AITEM, {"C6_OPER"   ,COPER3			, NIL})
				//AADD(ACABSC5,{"C5_XOPER"   ,COPER3  		,NIL})
			ELSE
				IF !EMPTY(CTES3)
					AADD(AITEM, {"C6_TES"   ,CTES3			, NIL})
				ENDIF
			ENDIF
		ENDCASE

		AADD(AITEM, {"C6_PRCVEN" , NPRCVEN		, NIL})

		If RIGHT(TRIM(ORETORNO:PRODUTOS[XX]:CODIGO),1) == "A"
			AADD(AITEM, {"C6_LOCAL"   , "02"	, NIL})	
		Endif

		If cFilMaxima == "0101"
			AADD(AITEM, {"C6_LOCAL"   , "01"	, NIL})	
		Endif

//		If ORETORNO:PRODUTOS[XX]:FilialRetira == "010202" //<> cFilAnt
			
	//		cC6Local	:= "02"  
			// Armazém 02 da Filial 0102-Floripa
	//		If ORETORNO:PRODUTOS[XX]:FilialRetira == "010202"
	//			cC6Local	:= "02"
			// Trecho comentado para saber como proceder com outras novas situações 
			//ElseIf ORETORNO:PRODUTOS[XX]:FilialRetira == "010203"
			//	cC6Local	:= "03"
	//		Endif 
			// Se tiver sido atribuído acima, adiciona o armazém na digitação do pedido. 
	//		If !Empty(cC6Local)
				//Aadd(aItem,	{"C6_LOCAL",	cC6Local 		, Nil})
//				AADD(AITEM, {"C6_LOCAL"   , "02"	, NIL})				
	//		Endif 

//		Endif 

		// 21/01/2021 - Marcelo A Lauschner - Adição de campos 
		Aadd(aItem,	{"C6_ZQTDMAX",	nQuant 		, Nil})



		//C6_ITEM+C6_PRODUTO+C6_QTDVEN+C6_PRUNIT+C6_PRCVEN+C6_OPER
		Aadd(aDadosSC6,{CITEM,CPRODUTO,NQUANT,NPRCTAB,NPRCVEN,COPER})

		//Adiciona aItem ao Array de Itens
		AADD(AITENS, AITEM)
	NEXT XX

	BEGIN TRANSACTION

		MSEXECAUTO({|X,Y,Z|MATA410(X,Y,Z)},ACABSC5,AITENS,NOPC) //ACIONA EXEC AUTO PARA INSERIR O NOVO REGISTRO.

		LRET := .F.

		IF LMSERROAUTO
			NSTATUS := 5
			NTIPOCRITICA := 2
			CTIPO := "Erro"
			CPED  := ""
			CDESC := '"Pedido não foi importado"'

			If IsBlind()
				cMensagem 	:= ""
				aLog := GetAutoGRLog()
				For nX := 1 To Len(aLog)
					cMensagem += aLog[nX]+"<br>"
					ConOut(aLog[nX])
				Next nX
				sfSendErro(cMensagem) // Envia WF de erro
			Else
				MOSTRAERRO()
			Endif
			ConOut("Pedido Máxima " + CPEDIDO + " não foi importado!")
			DISARMTRANSACTION()
		ELSE
			NSTATUS := 4
			NTIPOCRITICA := 0
			CTIPO := "Sucesso"
			CPED  := StrZero((Val(SC5->C5_FILIAL)*1000000) + Val(SC5->C5_NUM))
			CDESC := '"Pedido Importado com Sucesso"'
			ConOut("Pedido Máxima " + CPEDIDO + " importado com sucesso!")

		ENDIF

		ENVIA_RES()

	END TRANSACTION

	// Verifica se o pedido foi integrado e efetua o envio de WF de confirmação
	If nStatus == 4
		sfSendWF()
	Endif

	IF !EMPTY(CXFILIAL)
		CFILANT := CXFILIAL
	ENDIF
	
	// Libera Semáforo
	U_DCCFGM01(.F./*lLock*/,"GERAPED_MAXIMA"/*cKey*/,/*cMsg*/,/*lTrvEmp*/,/*lTrvFil*/,/*lExeAuto*/)

RETURN

/*/{Protheus.doc} ENVIA_RES
Envio de Resposta 
@type function
@version  
@since 25/03/2021
@return return_type, return_description
/*/
STATIC FUNCTION ENVIA_RES()

	Local 	_i 
	Local 	_J
	
	aaJson := Array(#)
	oObj   := NIL
	ADADOS  := {}
	ADADOSA := {}

	NNUMERO := VAL(DTOS(DATE())+STRTRAN(TIME(),":",""))//yyyyMMddHHmmss

	AADD(ADADOSA, {"codigo", 0})
	AADD(ADADOSA, {"ordem", 0})
	AADD(ADADOSA, {"descricao", CDESC})

	AADD(ADADOS, ADADOSA)

	aaJson[#'JSON'] := Array(Len(aDados))

	For _I := 1 To Len(aDados)
		aaJson[#'JSON'][_I] := Array(#)
		For _J := 1 To Len(ADADOS[_I])
			cField := ADADOS[_I,_J,1]
			cDado := aDados[_I,_J,2]
			If ValType(cDado) == "C"
				cDado := AllTRim(cDado)
			EndIf
			aaJson[#'JSON'][_I][#cField] := cDado
		Next _J
	Next _I

	cJson := ToJson(aaJson)
	FWJsonDeserialize(cJson,@oObj)
	cJson := FWJsonSerialize(oObj:JSON,.F.,.T.)

	CJSONITEM := cJson

	aaJson := Array(#)
	oObj   := NIL
	ADADOS  := {}
	ADADOSA := {}

	AADD(ADADOSA, {"numPedido", AOBJETO[YY]:NUMPED})
	AADD(ADADOSA, {"codigoPedidoNuvem", ORETORNO:codigoPedidoNuvem})
	AADD(ADADOSA, {"numPedidoERP", CPED})
	AADD(ADADOSA, {"numCritica", NNUMERO})
	AADD(ADADOSA, {"codigoUsuario", VAL(ORETORNO:CODIGOUSUARIOMAXIMA)})
	AADD(ADADOSA, {"data", FWTimeStamp( 5 , DDATABASE ,  TIME() )})//TRATAR A GERAÃ‡ÃƒO DESSA DATA
	AADD(ADADOSA, {"tipo", CTIPO})
	AADD(ADADOSA, {"itens", ""})//TRATAR OS ITENS
	AADD(ADADOSA, {"posicaoPedidoERP", "Pendente"})
	AADD(ADADOSA, {"codigoTipoVenda", 1})
	AADD(ADADOSA, {"statusDaAssinatura", 0})
	AADD(ADADOSA, {"excluirPedido", .F.})
	AADD(ADADOSA, {"salvarCritica", .T.})
	AADD(ADADOSA, {"enviarEmailPedidoAutomaticoParaSupervisor", .F.})
	AADD(ADADOSA, {"salvarJustificativaNaoVendaPrePedido", .F.})
	AADD(ADADOSA, {"atualizacaoPosPedido", .T.})
	AADD(ADADOSA, {"cancelado", .F.})
	AADD(ADADOSA, {"houveExcessao", .F.})
	AADD(ADADOSA, {"packageValida", .F.})

	AADD(ADADOS, ADADOSA)

	aaJson[#'JSON'] := Array(Len(aDados))

	For _I := 1 To Len(aDados)
		aaJson[#'JSON'][_I] := Array(#)
		For _J := 1 To Len(ADADOS[_I])
			cField := ADADOS[_I,_J,1]
			cDado := aDados[_I,_J,2]
			If ValType(cDado) == "C"
				cDado := AllTRim(cDado)
			EndIf
			aaJson[#'JSON'][_I][#cField] := cDado
		Next _J
	Next _I

	cJson := ToJson(aaJson)
	FWJsonDeserialize(cJson,@oObj)
	cJson := FWJsonSerialize(oObj:JSON,.F.,.T.)

	CJSONCRIT := SUBSTR(cJson,2,LEN(cJson)-2)
	CJSONCRIT := STRTRAN(CJSONCRIT,'"ITENS":""','"ITENS":[{"CODIGO":0,"DESCRICAO":"Pedido Importado com Sucesso","ORDEM":0}]')
	//CJSONCRIT := STRTRAN(CJSONCRIT,'"ITENS":""','"ITENS":[{"CODIGO":0,"DESCRICAO":"Pedido '+STATUS_PED()+'","ORDEM":0}]')
	aaJson := Array(#)
	oObj   := NIL
	ADADOS  := {}
	ADADOSA := {}

	AADD(ADADOSA, {"id_Pedido", AOBJETO[YY]:ID_PEDIDO})
	AADD(ADADOSA, {"objeto_Json", })
	AADD(ADADOSA, {"status", NSTATUS})
	AADD(ADADOSA, {"data", AOBJETO[YY]:DATA})
	AADD(ADADOSA, {"critica", CJSONCRIT})
	AADD(ADADOSA, {"tipoPedido", AOBJETO[YY]:tipoPedido})
	AADD(ADADOSA, {"codUsur", AOBJETO[YY]:CODUSUR})
	AADD(ADADOSA, {"codUsuario", AOBJETO[YY]:CODUSUARIO})
	AADD(ADADOSA, {"numPed", AOBJETO[YY]:NUMPED})
	AADD(ADADOSA, {"numPedErp", CPED})
	AADD(ADADOSA, {"numCritica", NNUMERO})
	AADD(ADADOSA, {"tipoCritica", NTIPOCRITICA})

	AADD(ADADOS, ADADOSA)

	U_BENVIA(ADADOS   ,"PUT"    , "RetornoStatus", "StatusPedidos")
RETURN
/*
FunÃ§Ã£o para envio de email
*/
STATIC FUNCTION ENVMAIL(_cSubject, _cDest, _cBody, _cAtach)

	u_fxEnvMail(_cSubject, _cDest, _cBody, _cAtach)

Return

/*
FunÃ§Ã£o que retorna a posiÃ§Ã£o do campo na SX3
*/
STATIC FUNCTION fxPos(cCampo)
	Local nPos  := 0
	nPos := POSICIONE("SX3", 2, cCampo, "X3_ORDEM")
Return nPos

/*
FunÃ§Ã£o que ordena o array de campos para ser passado para CabeÃ§alho e Detalhe
do ExecAuto
*/ 
STATIC FUNCTION fxOrdenaSX3(aCampos)
	Local 	aWithPos 	:= {}
	Local 	aOrdenado	:= {}
	Local 	a

//Le o array passado como parametro e coloca a posiÃ§Ã£o de cada campo
	For a:= 1 to len(aCampos)
		aadd(aWithPos,{aCampos[a,1],aCampos[a,2], aCampos[a,3], fxPos(aCampos[a,1])})
	Next

//Ordena o array de acordo com a posiÃ§Ã£o dos campos
	ASORT(aWithPos, , , { | x,y | x[4] < y[4] } )

//Monta o novo array somente com os campos originais, mas agora ordenado
	For a:=1 to Len(aWithPos)
		aadd(aOrdenado,{aWithPos[a,1],aWithPos[a,2], aWithPos[a,3]})
	Next

Return aOrdenado

STATIC FUNCTION STATUS_PED()

	LOCAL CRET := ""

	DO CASE
	CASE SC5->C5_SITDEC = '6'
		CRET := 'Pedido Rejeitado'
	CASE SC5->C5_SITDEC = '2'
		CRET := 'Pedido Em montagem'
	CASE SC5->C5_SITDEC = '5'
		CRET := 'Pedido Faturado'
	CASE SC5->C5_SITDEC = '1'
		CRET := 'Pedido Liberado Faturamento'
	CASE SC5->C5_SITDEC = ' ' .AND. SC5->C5_LIBEROK = ' '
		CRET := 'Pedido Em Aberto'
	CASE (SC5->C5_SITDEC = ' ' .AND. SC5->C5_LIBEROK = 'S' .AND. SC9->C9_BLCRED <> '' )
		CRET := 'Pedido com Bloq. de Credito'
	CASE (SC5->C5_SITDEC = ' ' .AND. SC5->C5_LIBEROK = 'S' .AND. SC9->C9_BLEST <> '' )
		CRET := 'Pedido com Bloq. de Estoque'
	CASE (SC5->C5_SITDEC = ' ' .AND. SC5->C5_LIBEROK = 'S' .AND. SC9->C9_BLCRED = '' .AND. SC9->C9_BLEST = '')
		CRET := 'Pedido Ag. Montagem'
	ENDCASE

RETURN(CRET)


/*/{Protheus.doc} sfSendWF
Função para enviar WF 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 24/11/2020
@return return_type, return_description
/*/
Static Function sfSendWF()

	Local	cPara		:= "suporte@decanter.com.br"
	Local	nValBrut	:= 0
	Local	nValProd	:= 0
	Local	oProcess 	:= TWFProcess():New("000001",OemToAnsi("Inclusão de Pedido Venda - Máxima"))
	Local	nT 			:= 0
	Local 	nTotDesc	:= 0
	Local 	nY 

	If IsSrvUnix()
		If File("/workflow/decanter_inclusao_pedido.htm")
			oProcess:NewTask("Gerando HTML","/workflow/decanter_inclusao_pedido.htm")
		Else
			ConOut("Não localizou arquivo  /workflow/decanter_inclusao_pedido.htm")
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\decanter_inclusao_pedido.htm")
	Endif

	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI))

	DbSelectArea("SE4")
	DbSetOrder(1)
	DbSeek(xFilial("SE4")+SC5->C5_CONDPAG)

	//oProcess:NewTask(cStatus,"\WORKFLOW\LIBERACAO_PEDIDO.HTM")
	oProcess:cSubject := "Inclusão de Pedido de Vendas --> " + SC5->C5_NUM
	oProcess:bReturn  := ""

	oHTML := oProcess:oHTML

	oHtml:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)

	oHtml:ValByName("EMISSAO"		,DTOC(SC5->C5_EMISSAO))
	oHtml:ValByName("CLIENTE"		,SC5->C5_CLIENTE+"/"+SC5->C5_LOJACLI+ "-" + Alltrim(SA1->A1_NOME) )
	oHtml:ValByName("FANTASIA"		,Alltrim(SA1->A1_NREDUZ) )
	oHtml:ValByName("CONDICAO"		,SC5->C5_CONDPAG + " - " + SE4->E4_DESCRI )

	oHtml:ValByName("NUMMAX"		,SC5->C5_XXPEDMA)

	oHtml:ValByName("NUMPROTHEUS"	,SC5->C5_NUM)

	oHtml:ValByName("ENDERECO"		,Alltrim(SA1->A1_END)+" "+SA1->A1_COMPLEM )
	oHtml:ValByName("MUNICIPIO"		,AllTrim(SA1->A1_MUN) + " / " + SA1->A1_EST + " CEP:" + Transform(SA1->A1_CEP,"@R 99999-999"))
	DbSelectArea("SA4")
	DbSetOrder(1)
	DbSeek(xFilial("SA4")+SC5->C5_TRANSP)
	oHtml:ValByName("TRANSPORTADORA"	,SC5->C5_TRANSP + "-" + SA4->A4_NREDUZ)

	//oHtml:ValByName("OBSERVACAO"	,SC5->C5_ZOBPMAX+SC5->C5_ZOBNMAX)
	oHtml:ValByName("OBSERVACAO"	,"Obs Entrega: "+ SC5->C5_ZOBNMAX+ "- Obs Interna: " + SC5->C5_ZOBPMAX)

	oHtml:ValByName("OBSERVCLIENTE"	,"")

	oHtml:ValByName("DIGITADO"		,cUserName )

	dbSelectArea("SA3")
	dbSetOrder(1)
	If MsSeek(xFilial("SA3")+SC5->C5_VEND1)
		oHtml:ValByName("REPR",SC5->C5_VEND1 + "/"+SA3->A3_NREDUZ)
		If !Empty(SA3->A3_EMAIL)
			cPara	+= ";" + Lower(Alltrim(SA3->A3_EMAIL))
		Endif
	Else
		oHtml:ValByName("REPR","")
	Endif
	

	aFisGet	:= {}
	dbSelectArea("SX3")
	dbSetOrder(1)
	MsSeek("SC6")
	While !Eof().And.X3_ARQUIVO=="SC6"
		cValid := UPPER(X3_VALID+X3_VLDUSER)
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGet,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGet,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		dbSkip()
	EndDo
	aSort(aFisGet,,,{|x,y| x[3]<y[3]})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Busca referencias no SC5                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aFisGetSC5	:= {}
	dbSelectArea("SX3")
	dbSetOrder(1)
	MsSeek("SC5")
	While !Eof().And.X3_ARQUIVO=="SC5"
		cValid := UPPER(X3_VALID+X3_VLDUSER)
		If 'MAFISGET("'$cValid
			nPosIni 	:= AT('MAFISGET("',cValid)+10
			nLen		:= AT('")',Substr(cValid,nPosIni,Len(cValid)-nPosIni))-1
			cReferencia := Substr(cValid,nPosIni,nLen)
			aAdd(aFisGetSC5,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		If 'MAFISREF("'$cValid
			nPosIni		:= AT('MAFISREF("',cValid) + 10
			cReferencia	:=Substr(cValid,nPosIni,AT('","MT410",',cValid)-nPosIni)
			aAdd(aFisGetSC5,{cReferencia,X3_CAMPO,MaFisOrdem(cReferencia)})
		EndIf
		dbSkip()
	EndDo
	aSort(aFisGetSC5,,,{|x,y| x[3]<y[3]})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Inicializa a funcao fiscal                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	MaFisSave()
	MaFisEnd()
	MaFisIni(SC5->C5_CLIENTE,;								// 1-Codigo Cliente/Fornecedor
	SC5->C5_LOJACLI,;								// 2-Loja do Cliente/Fornecedor
	IIf(SC5->C5_TIPO$'DB',"F","C"),;				// 3-C:Cliente , F:Fornecedor
	SC5->C5_TIPO,;									// 4-Tipo da NF
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
			If !Empty(&("M->"+Alltrim(aFisGetSC5[ny][2])))
				MaFisAlt(aFisGetSC5[ny][1],&("M->"+Alltrim(aFisGetSC5[ny][2])),,.F.)
			EndIf
		Next nY
	Endif

	DbSelectArea("SC6")
	DbSetOrder(1)
	DbSeek(xFilial("SC6")+SC5->C5_NUM)
	While !Eof() .And. SC6->(C6_FILIAL+C6_NUM) == xFilial("SC6")+SC5->C5_NUM

		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+SC6->C6_PRODUTO)

		AAdd((oHtml:ValByName("P.IT"))			,SC6->C6_ITEM		)
		AAdd((oHtml:ValByName("P.PRODUTO"))		,SC6->C6_PRODUTO	)
		AAdd((oHtml:ValByName("P.DESCRICAO"))	,SB1->B1_DESC)


		AAdd((oHtml:ValByName("P.QUANT"))		,Transform(SC6->C6_QTDVEN ,'@E 999,999,999'))
		AAdd((oHtml:ValByName("P.PRCTAB"))		,Transform(SC6->C6_PRUNIT ,"@E 999,999,999.99"))
		nValBrut	+= SC6->C6_PRUNIT * SC6->C6_QTDVEN
		nValProd	+= SC6->C6_PRCVEN * SC6->C6_QTDVEN
		AAdd((oHtml:ValByName("P.PRCVEN"))		,Transform(SC6->C6_PRCVEN ,"@E 999,999,999.99"))
		AAdd((oHtml:ValByName("P.PDESC"))		,Transform( (SC6->C6_PRUNIT  - SC6->C6_PRCVEN) / SC6->C6_PRUNIT  * 100  ,"@E 999.99"))

		AAdd((oHtml:ValByName("P.VALOR"))		,Transform(SC6->C6_VALOR  ,"@E 999,999,999.99"))


		SF4->(dbSetOrder(1))
		SF4->(MsSeek(xFilial("SF4")+SC6->C6_TES))

		nValMerc  := SC6->C6_QTDVEN * SC6->C6_PRCVEN
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Calcula o preco de lista                     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nValMerc  := SC6->C6_VALOR
		nPrcLista := SC6->C6_PRUNIT

		nAcresUnit:= A410Arred(SC6->C6_PRCVEN * SC5->C5_ACRSFIN/100,"D2_PRCVEN")
		nAcresFin := A410Arred(SC6->C6_QTDVEN * nAcresUnit,"D2_TOTAL")
		nValMerc  += nAcresFin
		nDesconto := a410Arred(nPrcLista * SC6->C6_QTDVEN,"D2_DESCON") - nValMerc
		nDesconto := IIf(nDesconto<=0,SC6->C6_VALDESC,nDesconto)
		nDesconto := Max(0,nDesconto)
		nPrcLista += nAcresUnit
		//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
		If cPaisLoc=="BRA" .or. GetNewPar('MV_DESCSAI','1') == "2"
			nValMerc  += nDesconto
		Endif
		// Incremento váriavel corretamente
		nT++

		MaFisAdd(	SB1->B1_COD,;  				// 1-Codigo do Produto ( Obrigatorio )
		SC6->C6_TES,;	   						// 2-Codigo do TES ( Opcional )
		SC6->C6_QTDVEN,; 	 					// 3-Quantidade ( Obrigatorio )
		SC6->C6_PRUNIT,;		  					// 4-Preco Unitario ( Obrigatorio )
		nDesconto,;	 							// 5-Valor do Desconto ( Opcional )
		"",;	   								// 6-Numero da NF Original ( Devolucao/Benef )
		"",;									// 7-Serie da NF Original ( Devolucao/Benef )
		0,;										// 8-RecNo da NF Original no arq SD1/SD2
		0,;										// 9-Valor do Frete do Item ( Opcional )
		0,;										// 10-Valor da Despesa do item ( Opcional )
		0,;										// 11-Valor do Seguro do item ( Opcional )
		0,;										// 12-Valor do Frete Autonomo ( Opcional )
		nValMerc,;								// 13-Valor da Mercadoria ( Obrigatorio )
		0,;										// 14-Valor da Embalagem ( Opiconal )
		,;										// 15
		,;										// 16
		SC6->C6_ITEM,; 							// 17
		0,;										// 18-Despesas nao tributadas - Portugal
		0,;										// 19-Tara - Portugal
		SC6->C6_CF,; 							// 20-CFO
		{},;	           						// 21-Array para o calculo do IVA Ajustado (opcional)
		"")
		nTotDesc += MaFisRet(nT,"IT_DESCONTO")

		DbSelectArea("SC6")
		DbSkip()
	Enddo

	MaFisAlt("NF_FRETE"		,SC5->C5_FRETE)
	MaFisAlt("NF_VLR_FRT"	,SC5->C5_VLR_FRT)
	MaFisAlt("NF_SEGURO"	,SC5->C5_SEGURO)
	MaFisAlt("NF_AUTONOMO"	,SC5->C5_FRETAUT)
	MaFisAlt("NF_DESPESA"	,SC5->C5_DESPESA)

	If SC5->C5_PDESCAB > 0
		MaFisAlt("NF_DESCONTO",A410Arred(MaFisRet(,"NF_VALMERC")*SC5->C5_PDESCAB/100,"C6_VALOR")+MaFisRet(,"NF_DESCONTO"))
	EndIf

	If SC5->C5_DESCONT > 0
		MaFisAlt("NF_DESCONTO",Min(MaFisRet(,"NF_VALMERC")-0.01,nTotDesc+SC5->C5_DESCONT),/*nItem*/,/*lNoCabec*/,/*nItemNao*/,GetNewPar("MV_TPDPIND","1")=="2" )
	EndIf

	oHtml:ValByName("MERCADORIAS"		,Transform(MaFisRet(,"NF_VALMERC"),"@E 999,999.99"))
	oHtml:ValByName("DESCONTOS"			,Transform(MaFisRet(,"NF_DESCONTO"),"@E 999,999.99"))
	oHtml:ValByName("ICMSRET"			,Transform(MaFisRet(,"NF_VALSOL"),"@E 999,999.99"))
	oHtml:ValByName("IPI"				,Transform(MaFisRet(,"NF_VALIPI"),"@E 999,999.99"))
	oHtml:ValByName("TOTAL"				,Transform(MaFisRet(,"NF_TOTAL"),"@E 999,999,999.99"))

	oHtml:ValByName("DATA"				,Date())
	oHtml:ValByName("HORA"				,Time())
	oProcess:cTo := cPara

	oProcess:Start()
	oProcess:Finish()
Return

/*/{Protheus.doc} sfSendErro
Função para envio de alerta sobre erro de importação do pedido de venda 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 24/11/2020
@return return_type, return_description
/*/
Static Function sfSendErro(cInLogErro)

	Local	cPara		:= "suporte@decanter.com.br"
	Local	nValBrut	:= 0
	Local	nValProd	:= 0
	Local	nX
	Local	oProcess 	:= TWFProcess():New("000001",OemToAnsi("Erro de Inclusão de Pedido Venda - Máxima"))

	If IsSrvUnix()
		If File("/workflow/decanter_erro_inclusao_pedido.htm")
			oProcess:NewTask("Gerando HTML","/workflow/decanter_erro_inclusao_pedido.htm")
		Else
			ConOut("Não localizou arquivo  /workflow/decanter_erro_inclusao_pedido.htm")
			Return
		Endif
	Else
		oProcess:NewTask("Gerando HTML","\workflow\decanter_erro_inclusao_pedido.htm")
	Endif
	//C5_CLIENTE+C5_LOJACLI+C5_CONDPAG+C5_EMISSAO+C5_XXPEDMA+C5_ZOBSENT+C5_VEND1
	//aDadosSC5	:= {CCLIENTE,CLOJA,CCOND,DEMISSAO,CPEDIDO,COBS,CVEND}



	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial("SA1")+aDadosSC5[1]+aDadosSC5[2])

	DbSelectArea("SE4")
	DbSetOrder(1)
	DbSeek(xFilial("SE4")+aDadosSC5[3])

	//oProcess:NewTask(cStatus,"\WORKFLOW\LIBERACAO_PEDIDO.HTM")
	oProcess:cSubject := "Erro de Inclusão de Pedido de Vendas --> " + aDadosSC5[5]
	oProcess:bReturn  := ""

	oHTML := oProcess:oHTML

	oHtml:ValByName("NOMECOM"		,AllTrim(SM0->M0_NOMECOM))
	oHtml:ValByName("ENDEMP"		,Capital(AllTrim(SM0->M0_ENDENT)) + " - " + Capital(SM0->M0_BAIRENT))
	oHtml:ValByName("COMEMP"		,Transform(SM0->M0_CEPENT,"@R 99999-999") + " - " + Capital(AllTrim(SM0->M0_CIDENT)) + " - " + SM0->M0_ESTENT)
	oHtml:ValByName("FONE"			,"Fone/Fax: " + SM0->M0_TEL)

	oHtml:ValByName("EMISSAO"		,DTOC(aDadosSC5[4]))
	oHtml:ValByName("CLIENTE"		,aDadosSC5[1]+"/"+aDadosSC5[2]+ "-" + Alltrim(SA1->A1_NOME))
	oHtml:ValByName("FANTASIA"		, Alltrim(SA1->A1_NREDUZ))
	oHtml:ValByName("CONDICAO"		,aDadosSC5[3] + " - " + SE4->E4_DESCRI )

	oHtml:ValByName("NUMMAX"		,aDadosSC5[5])

	oHtml:ValByName("ENDERECO"		,Alltrim(SA1->A1_END)+" "+SA1->A1_COMPLEM )
	oHtml:ValByName("MUNICIPIO"		,AllTrim(SA1->A1_MUN) + " / " + SA1->A1_EST + " CEP:" + Transform(SA1->A1_CEP,"@R 99999-999"))

	oHtml:ValByName("OBSERVACAO"	,"Obs Entrega: "+ aDadosSC5[8]+ "- Obs Interna: " + aDadosSC5[6])

	oHtml:ValByName("OBSERVCLIENTE"	,"Erro de Importação: " + cInLogErro )

	oHtml:ValByName("DIGITADO"		,cUserName )

	dbSelectArea("SA3")
	dbSetOrder(1)
	If MsSeek(xFilial("SA3")+aDadosSC5[7])
		oHtml:ValByName("REPR",aDadosSC5[7] + "/"+SA3->A3_NREDUZ)
		If !Empty(SA3->A3_EMAIL)
			cPara	+= ";" + Lower(Alltrim(SA3->A3_EMAIL))
		Endif
	Else
		oHtml:ValByName("REPR","")
	Endif

//C6_ITEM+C6_PRODUTO+C6_QTDVEN+C6_PRUNIT+C6_PRCVEN+C6_OPER
	//Aadd(aDadosSC6,{CITEM,CPRODUTO,NQUANT,NPRCTAB,NPRCVEN,COPER})
	For nX := 1 To Len(aDadosSC6)


		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+aDadosSC6[nX,2])

		AAdd((oHtml:ValByName("P.IT"))			,aDadosSC6[nX,1]		)
		AAdd((oHtml:ValByName("P.PRODUTO"))		,aDadosSC6[nX,2]		)
		AAdd((oHtml:ValByName("P.DESCRICAO"))	,SB1->B1_DESC)


		AAdd((oHtml:ValByName("P.QUANT"))		,Transform(aDadosSC6[nX,3] ,'@E 999,999,999'))
		AAdd((oHtml:ValByName("P.OPER"))		,aDadosSC6[nX,6])
		AAdd((oHtml:ValByName("P.PRCTAB"))		,Transform(aDadosSC6[nX,4] ,"@E 999,999,999.99"))
		nValBrut	+= aDadosSC6[nX,4] * aDadosSC6[nX,3]
		nValProd	+= aDadosSC6[nX,5] * aDadosSC6[nX,3]
		AAdd((oHtml:ValByName("P.PRCVEN"))		,Transform(aDadosSC6[nX,5] ,"@E 999,999,999.99"))

		AAdd((oHtml:ValByName("P.VALOR"))		,Transform(aDadosSC6[nX,5] * aDadosSC6[nX,3]  ,"@E 999,999,999.99"))

	Next

	oHtml:ValByName("TOTAL"				,Transform(nValProd,"@E 999,999.99"))

	oHtml:ValByName("DATA"				,Date())
	oHtml:ValByName("HORA"				,Time())

	oProcess:cTo := cPara

	oProcess:Start()
	oProcess:Finish()
Return
