#INCLUDE "totvs.ch"

User Function VTEX_ORDER()



	If Select("SM0") == 0
		RpcSetType(3)
		RpcSetEnv("01")
		Sleep(5000)

		If Select("SM0") == 0
			Return
		Endif
	Endif
	U_VTEX002()



Return

User Function VTEX002()

	Local cDescDet	:=	""

	Local cLockName	:=	ProcName()+Alltrim(SM0->M0_CODIGO)+Alltrim(SM0->M0_CODFIL)
	Private lIsBlind	:=	isBlind()

	If !LockByName(cLockName,.T.,.F.)
		MsgStop("Rotina está sendo processada por outro usuário")
		U_GetUsrLock(cLockName)
		Return
	EndIf
	U_PutUsrLock(cLockName)

	oActLog	:=	ACTXLOG():New()
	oActLog:Start("VTEX002"," Iniciando integração com vtex",)
	FWLogMsg("INFO","",'1',"VTEX002",,"vtex"," Iniciando integração com vtex")

	oActLog:Inf("VTEX002",If(lIsBlind,"Executado VIA JOB","Executado manualmente com interface"))
	FWLogMsg("INFO","LAST",'1',"VTEX002",,"vtex",If(lIsBlind,"Executando via JOB","Executando em tela"))

	If lIsBlind
		U_VTEX002P()
	Else
		cDescDet	:= "Rotina responsável por realizar o consumo de clientes e pedidos do vtex"
		oGrid		:=	FWGridProcess():New(   "VTEX002",  "Buscar Clientes e Pedidos do vtex", cDescDet, {|| U_VTEX002P()}, "")
		oGrid:SetMeters(2)
		oGrid:SetAbort(.T.)
		oGrid:Activate()
	EndIf

	oActLog:Fin()
	FWLogMsg("INFO","LAST",'1',"VTEX002",,"vtex","Finalizada integração com vtex")

	UnLockByName(cLockName,.T.,.F.)
	U_DelUsrLock(cLockName)

Return

User Function VTEX002P()

	Local aAreaAnt := GETAREA()
	Local lRet			:= .F.
	Local nX			:= 0
	Local iX
	Local cPedId		:= ""
	Local cAliasSC5		:= GetNextAlias()

	Local cAliasSA1		:= GetNextAlias()
	Local aRotAuto 		:= {}
	Local cItem			:= "00"
	Local aItens		:= {}
	Local oJson
	Local oObj   		:= NIL

	local oRestClient	as object
	local cPath 		:= "/api/OMS/pvt/orders/"
	local aHeadOut 		as array


	Private cURL  	    	:= GetMv("MA_VTEXURL"	,,"https://decantervinhos.myvtex.com")
	Private cCdTabPrc 		:= GETMV("MA_CODTABP"	,,"107")	//Tab Preço
	Private cCdNatu 		:= GETMV("MA_CODNAT"	,,"10109")	//Natureza
	Private cVendEcm		:= GETMV("MA_VENDECM"  	,,"000138") //Vendedor
	Private cCondPag		:= "001" //Condição Pagto
	Private cTranspEcm		:= "999" //GETMV("MA_TRANECM"  	,,"378")	//"378") //Transportadora
	Private cTpOper			:= GETMV("MV_ZTOPER"  	,,"02")		//Tipo operação fiscal
	Private cCliRisco		:= GETMV("MA_CRISCO"  	,,"E")		//Fator de risco do cliente
	Private lMsErroAuto 	:= .F. //necessario a criacao, pois sera atualizado quando houver
	Private lAutoErrNoFile	:= .T.
	Private aAutoErro		:= {}

	aHeadOut := {}
	Aadd(aHeadOut, "Content-Type: application/json")
	Aadd(aHeadOut, "X-VTEX-API-AppKey: vtexappkey-decantervinhos-JQBAGL")
	Aadd(aHeadOut, "X-VTEX-API-AppToken: KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")

	oRestClient := FWRest():New(cUrl)
	oRestClient:SetPath(cPath+"?f_status=ready-for-handling") //pega pedido pronto para manuseio
	If oRestClient:Get(aHeadOut)
		sPostRet := oRestClient:GetResult()
		If FWJsonDeserialize(sPostRet,@oObj)
			If SubStr(oRestClient:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O" .And. Len(oObj:LIST) > 0
				cPedId := oObj:LIST[1]:orderId
			EndIf
		EndIf

		If ValType(oObj) == "O" .And. Len(oObj:LIST) > 0
			For iX := 1 To Len(oObj:LIST)
				cPedId := oObj:LIST[iX]:orderId

				// Somente se conseguiu obter o Id de Pedido
				If !Empty(cPedId)
					//validar pedido ja importado
					BeginSql alias cAliasSC5
						SELECT C5_NUM  
						FROM %table:SC5% SC5
						WHERE SC5.C5_FILIAL	= %exp:FWxFilial("SC5")%
						AND SC5.C5_ZNUMMGT	= %exp:cPedId%
					EndSql

					If (cAliasSC5)->(Eof())
						oRestClient:SetPath(cPath+cPedId)
						if oRestClient:Get(aHeadOut)
							// Cria o objeto JSON e popula ele a partir da string
							oJson := JSonObject():New()
							cErr  := oJSon:fromJson(oRestClient:GetResult())

							If !empty(cErr)
								MsgStop(cErr,"JSON PARSE ERROR")
								Return
							Endif

							//validar cliente
							//cliente
							cCCgc := oJson["clientProfileData"]["document"]

							cCFName := oJson["clientProfileData"]["firstName"]
							cCFName	:= DecodeUTF8(cCFName)
							If ValType(cCFName) <> "C"
								cCFName := oJson["clientProfileData"]["firstName"]
							Endif
							cCFName := NoAcento(Upper(StrTran(cCFName,"'","")))

							cCLName := oJson["clientProfileData"]["lastName"]
							If !Empty(cCLName)
								cCLName	:= DecodeUTF8(cCLName)
								If ValType(cCFName) <> "C"
									cCLName := oJson["clientProfileData"]["lastName"]
								Endif
							Endif
							cCLName := NoAcento(Upper(StrTran(cCLName,"'","")))

							cETel 	:= oJson["clientProfileData"]["phone"]
							cETel 	:= StrTran(cETel,"+","")
							cCEmail := oJson["clientProfileData"]["email"]
							//endereço
							cECep 	:= StrTran(oJson["shippingData"]["selectedAddresses"][1]["postalCode"], "-","")

							// 12/01/2023 - Obtém o nome da pessoa de Entrega do pedido
							cENome 	:= oJson["shippingData"]["selectedAddresses"][1]["receiverName"]
							cENome 	:= DecodeUTF8(cENome)
							If ValType(cENome) <> "C"
								cENome 	:= oJson["shippingData"]["selectedAddresses"][1]["receiverName"]
							Endif 
							
							cEEnd := oJson["shippingData"]["selectedAddresses"][1]["street"] + ", " + oJson["shippingData"]["selectedAddresses"][1]["number"]
							cEEnd	:= DecodeUTF8(cEEnd)
							If ValType(cEEnd) <> "C"
								cEEnd := oJson["shippingData"]["selectedAddresses"][1]["street"] + ", " + oJson["shippingData"]["selectedAddresses"][1]["number"]
							Endif
							cEEnd := NoAcento(Upper(StrTran(cEEnd,"'","´")))

							cCompEnd := oJson["shippingData"]["selectedAddresses"][1]["complement"]
							If cCompEnd <> Nil
								cCompEnd	:= DecodeUTF8(cCompEnd)
								If ValType(cCompEnd) <> "C"
									cCompEnd := oJson["shippingData"]["selectedAddresses"][1]["complement"]
								Endif
								cCompEnd := NoAcento(Upper(cCompEnd))
							Else
								cCompEnd	:= " "
							Endif

							cECity := oJson["shippingData"]["selectedAddresses"][1]["city"]
							cECity	:= DecodeUTF8(cECity)
							If ValType(cEEnd) <> "C"
								cECity := oJson["shippingData"]["selectedAddresses"][1]["city"]
							Endif
							cECity := NoAcento(Upper(cECity))


							cEBairro := oJson["shippingData"]["selectedAddresses"][1]["neighborhood"]
							cEBairro	:= DecodeUTF8(cEBairro)
							If ValType(cEEnd) <> "C"
								cEBairro := oJson["shippingData"]["selectedAddresses"][1]["neighborhood"]
							Endif
							cEBairro := NoAcento(Upper(cEBairro))


							cECodEst := oJson["shippingData"]["selectedAddresses"][1]["state"]

							//Busca os registros na base pelo CGC
							BeginSql alias cAliasSA1
								SELECT A1_COD,A1_LOJA,A1_NOME,A1_ZBOLETO,A1_CONTRIB,A1_IENCONT,A1_RISCO,A1_TRANSP,A1_TEL,A1_CEP,A1_END,A1_EMAIL 
								FROM %table:SA1% SA1
								WHERE SA1.D_E_L_E_T_ <> '*'
								AND SA1.A1_FILIAL = %exp:FWxFilial("SA1")%
								AND SA1.A1_CGC 	  = %exp:cCCgc%						  
								AND ( (A1_TIPO = 'F' AND A1_LOJA = '9999' 
									AND SA1.A1_CEP = %Exp:Upper(cECep)%
									AND UPPER(A1_END) = %Exp:Upper(cEEnd)%   
								AND SA1.A1_EST	  = %exp:cECodEst% ) OR A1_TIPO = 'J')
								ORDER BY A1_LOJA 
							EndSql
							// A ordenação pelo campo A1_LOJA se faz

							//Tipo pessoa
							If Len(cCCgc) == 11
								cCTipPes := "F"
							Else
								cCTipPes := "J"
							EndIf

							aRotAuto	:= {}

							If (cAliasSA1)->(Eof()) //Inclusão
								aadd(aRotAuto,{"A1_PESSOA"		,upper(cCTipPes),NIL})
								aadd(aRotAuto,{"A1_NOME"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})
								aadd(aRotAuto,{"A1_NREDUZ"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})

								aadd(aRotAuto,{"A1_CEP"			,cECep			,NIL})

								aadd(aRotAuto,{"A1_END"			,upper(cEEnd)	,NIL})
								Aadd(aRotAuto,{"A1_COMPLEM" 	,Padr(Upper(cCompEnd),TamSX3("A1_COMPLEM")[1]),Nil})
								Aadd(aRotAuto,{"A1_BAIRRO"		,Padr(Upper(cEBairro),TamSX3("A1_BAIRRO")[1]),NIL})
								Aadd(aRotAuto,{"A1_EST"			,cECodEst		,NIL})
								Aadd(aRotAuto,{"A1_MUN"			,cECity			,NIL})

								dbSelectArea("CC2")
								dbSetOrder(4)
								If DbSeek(FWXFilial("CC2")+cECodEst+cECity)
									Aadd(aRotAuto,{"A1_COD_MUN"		,CC2->CC2_CODMUN		,NIL})
								Else
									//Aadd(aRotAuto,{"A1_COD_MUN"		,CC2->CC2_CODMUN		,NIL})
								Endif

								aadd(aRotAuto,{"A1_TIPO"		,upper("F")		,NIL})
								If cECodEst $ "SP,MG,RJ,ES"
									aadd(aRotAuto,{"A1_DSCREG"	,"SUDESTE"		,Nil})
								ElseIf cECodEst $ "PR,SC,RS"
									aadd(aRotAuto,{"A1_DSCREG"	,"SUL"			,Nil})
								ElseIf cECodEst $ "AL,BA,CE,PI,SE,PE,PB,RN,MA"
									aadd(aRotAuto,{"A1_DSCREG"	,"NORDESTE"		,Nil})
								ElseIf cECodEst $ "AC,AM,RR,RO,AP,PA,TO"
									aadd(aRotAuto,{"A1_DSCREG"	,"NORTE"		,Nil})
								ElseIf cECodEst $ "GO,DF,MT,MS"
									aadd(aRotAuto,{"A1_DSCREG"	,"CENTRO OESTE"	,Nil})
								EndIf
								aadd(aRotAuto,{"A1_CGC"			,cCCgc			,NIL})
								aadd(aRotAuto,{"A1_TEL"			,cETel			,NIL})
								aadd(aRotAuto,{"A1_EMAIL"		,cCEmail		,NIL})
								aadd(aRotAuto,{"A1_VEND"		,cVendEcm		,NIL})
								aadd(aRotAuto,{"A1_PAIS"		,"105"			,NIL})
								aadd(aRotAuto,{"A1_CODPAIS"		,"01058"		,NIL})
								aadd(aRotAuto,{"A1_SIMPLES"		,"2"			,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_SIMPNAC"		,"2"			,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_TRANSP"		,cTranspEcm		,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_TPFRET"		,'C'			,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_RISCO"		,cCliRisco		,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_IENCONT"		,"2"			,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_CONTRIB"		,"2"			,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_ZBOLETO"		,"N"			,NIL})//OBRIGATÓRIO
								aadd(aRotAuto,{"A1_ZCANPRA"		,"V"			,NIL})//OBRIGATÓRIO
								Aadd(aRotAuto,{"A1_CONTA"		,"110201001"	,NIL})
								aadd(aRotAuto,{"A1_ZSEG"		,"C"			,NIL})//OBRIGATÓRIO - Segmento - C-Consumidor final 
								
								MSExecAuto({|x,y| Mata030(x,y)},aRotAuto,3) //3- Inclusão, 4- Alteração, 5- Exclusão

								If lMsErroAuto
									aAutoErro 	:= GETAUTOGRLOG()
									cMsgErr 	:= "Falha ao INCLUIR cliente pela rotina Mata030. [ERRO]: "+chr(13)+chr(10)+alltrim(ArrTokStr(aAutoErro))
									oActLog:Err(cMsgErr)
									MsgStop(cMsgErr,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
									Break
								Else
									aCliRet := {.T.,SA1->A1_COD, SA1->A1_LOJA} //Inclusao = .T., Cod Cli, Loja Cli
								EndIf

							Else
								//Alteração
								//Primeiro verifica se precisa alterar
								lChgCli := .F.
								While !Eof()
									If PadR(UPPER(rtrim(cCFName)+" "+ltrim(cCLName)),TamSx3("A1_NOME")[1]) <> UPPER((cAliasSA1)->A1_NOME)
										lChgCli := .T.
									EndIf
									//Verifica Email
									If PadR(UPPER(cCEmail),TamSx3("A1_EMAIL")[1]) <> UPPER((cAliasSA1)->A1_EMAIL)
										lChgCli := .T.
									EndIf
									//Verifica Cidade e Estado pelo Código IBGE
									//						If PadR(UPPER(cECodCid),TamSx3("A1_CODMUN")[1]) <> UPPER((cAliasSA1)->A1_COD_MUN)
									//							lChgCli := .T.
									//						EndIf
									//Verifica Endereço
									If PadR(UPPER(cEEnd),TamSx3("A1_END")[1]) <> UPPER((cAliasSA1)->A1_END)
										lChgCli := .T.
									EndIf
									//Verifica Bairro
									//						If PadR(UPPER(cEBairro),TamSx3("A1_END")[1]) <> UPPER((cAliasSA1)->A1_BAIRRO)
									//							lChgCli := .T.
									//						EndIf
									//Verifica CEP
									If PadR(UPPER(cECep),TamSx3("A1_CEP")[1]) <> UPPER((cAliasSA1)->A1_CEP)
										lChgCli := .T.
									EndIf
									//Verifica Telefone
									If PadR(UPPER(cETel),TamSx3("A1_TEL")[1]) <> UPPER((cAliasSA1)->A1_TEL)
										lChgCli := .T.
									EndIf

									//Adicionado validacao para lojas 9999 apenas a pedido do André em 31/05/2020.
									//Pois o cliente pode ter cadastros de outros estados e gera atualizacao em todos eles.
									If AllTrim((cAliasSA1)->A1_LOJA) <> '9999'
										lChgCli := .F.
									EndIf

									If lChgCli
										aAdd(aRotAuto,{"A1_COD"			,(cAliasSA1)->A1_COD	,Nil})
										aAdd(aRotAuto,{"A1_LOJA"		,(cAliasSA1)->A1_LOJA	,Nil})
										aadd(aRotAuto,{"A1_PESSOA"		,upper(cCTipPes)		,NIL})
										aadd(aRotAuto,{"A1_NOME"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})
										aadd(aRotAuto,{"A1_NREDUZ"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})
										aadd(aRotAuto,{"A1_CEP"			,cECep					,NIL})
										aadd(aRotAuto,{"A1_END"			,upper(cEEnd)			,NIL})
										aadd(aRotAuto,{"A1_TIPO"		,upper("F")				,NIL})	//OBRIGATORIO	//TODO: Verificar
										If cECodEst $ "SP,MG,RJ,ES"
											//aadd(aRotAuto,{"A1_REGIAO","008"					,Nil})
											aadd(aRotAuto,{"A1_DSCREG","SUDESTE"				,Nil})
										ElseIf cECodEst $ "PR,SC,RS"
											//aadd(aRotAuto,{"A1_REGIAO","002"					,Nil})
											aadd(aRotAuto,{"A1_DSCREG","SUL"					,Nil})
										ElseIf cECodEst $ "AL,BA,CE,PI,SE,PE,PB,RN,MA"
											//aadd(aRotAuto,{"A1_REGIAO","007"					,Nil})
											aadd(aRotAuto,{"A1_DSCREG","NORDESTE"				,Nil})
										ElseIf cECodEst $ "AC,AM,RR,RO,AP,PA,TO"
											//aadd(aRotAuto,{"A1_REGIAO","001"					,Nil})
											aadd(aRotAuto,{"A1_DSCREG","NORTE"					,Nil})
										ElseIf cECodEst $ "GO,DF,MT,MS"
											//aadd(aRotAuto,{"A1_REGIAO","006"					,Nil})
											aadd(aRotAuto,{"A1_DSCREG","CENTRO OESTE"			,Nil})
										EndIf
										aadd(aRotAuto,{"A1_TEL"			,cETel					,NIL})
										aadd(aRotAuto,{"A1_EMAIL"		,cCEmail				,NIL})
										aadd(aRotAuto,{"A1_VEND"		,cVendEcm				,NIL})
										aadd(aRotAuto,{"A1_PAIS"		,"105"					,NIL})
										aadd(aRotAuto,{"A1_CODPAIS"		,"01058"				,NIL})
										aadd(aRotAuto,{"A1_SIMPLES"		,"2"					,NIL})//OBRIGATÓRIO
										aadd(aRotAuto,{"A1_SIMPNAC"		,"2"					,NIL})//OBRIGATÓRIO
										aadd(aRotAuto,{"A1_TRANSP"		,Iif(!EMPTY((cAliasSA1)->A1_TRANSP)	,(cAliasSA1)->A1_TRANSP	,cTranspEcm),NIL})//OBRIGATÓRIO
										aadd(aRotAuto,{"A1_RISCO"		,Iif(!EMPTY((cAliasSA1)->A1_RISCO)	,(cAliasSA1)->A1_RISCO	,cCliRisco)	,NIL})//OBRIGATÓRIO
										aadd(aRotAuto,{"A1_IENCONT"		,Iif(!EMPTY((cAliasSA1)->A1_IENCONT),(cAliasSA1)->A1_IENCONT,"2")		,NIL})//OBRIGATÓRIO
										aadd(aRotAuto,{"A1_CONTRIB"		,Iif(!EMPTY((cAliasSA1)->A1_CONTRIB),(cAliasSA1)->A1_CONTRIB,"2")		,NIL})//OBRIGATÓRIO
										aadd(aRotAuto,{"A1_ZBOLETO"		,Iif(!EMPTY((cAliasSA1)->A1_ZBOLETO),(cAliasSA1)->A1_ZBOLETO,"N")		,NIL})//OBRIGATÓRIO
										aadd(aRotAuto,{"A1_ZSEG"		,"C"			,NIL})//OBRIGATÓRIO - Segmento - C-Consumidor final 

										If GetNewPar("MA_XALTCLI",.F.) // Somente será ativada a alteração de clientes mediante criação do parâmetro e ativação do mesmo
											MSExecAuto({|x,y| Mata030(x,y)},aRotAuto,4) //3- Inclusão, 4- Alteração, 5- Exclusão

											If lMsErroAuto
												If IsBlind()
													cArqLog := cCCgc + "" +Alltrim(SubStr(Time(),1,5 )) + ".log"
													_cObs := MostraErro("\system", cArqLog)
												Else
													_cObs := MostraErro() //TODO: Verificar melhor maneira de tratar o erro.V
												Endif
												cMsgError	:=	 "Falha ao ALTERAR cliente pela rotina Mata030. [ERRO]: "+_cObs
												FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"vtex",cMsgError)
												//MsgAlert(cMsgError,Procname())
												Break
											EndIf
										Endif
									EndIf

									aCliRet := {.F.,(cAliasSA1)->A1_COD, (cAliasSA1)->A1_LOJA}  //Alteração = .F., CodCli, LojCli

									dbSelectArea(cAliasSA1)
									dbSkip()
								EndDo
							EndIf
							(cAliasSA1)->(DbCloseArea())
							
							// Calcula o valor do pedido para depois fazer atualização no faturamento 
							// VTEX considera o campo Descontos com o valor negativo para aplicar desconto e por isso precisa somar o Desconto para assim subtrair 
							// Valor Itens ( 150,00) + Valor Frete ( 0,00) + Valor Desconto ( -10,00) = 140,00
							nVlrPedido	:= (oJson["totals"][3]["value"] + oJson["totals"][1]["value"] + oJson["totals"][2]["value"]) / 100 

							nPDesc := ((oJson["totals"][2]["value"]*-1) / oJson["totals"][1]["value"])*100
							nVlrFrt := oJson["totals"][3]["value"] / 100
							if oJson["paymentData"]["transactions"][1]["payments"][1]["paymentSystem"] == "6" //boleto
								cCondPg := "181"
							elseif oJson["paymentData"]["transactions"][1]["payments"][1]["paymentSystem"] == "125" //pix
								cCondPg := "182"
							elseif oJson["paymentData"]["transactions"][1]["payments"][1]["installments"] == 1 //1x
								cCondPg := "008"
							elseif oJson["paymentData"]["transactions"][1]["payments"][1]["installments"] == 2 //2x
								cCondPg := "007"
							elseif oJson["paymentData"]["transactions"][1]["payments"][1]["installments"] == 3 //3x
								cCondPg := "001"
							elseif oJson["paymentData"]["transactions"][1]["payments"][1]["installments"] == 4 //4x
								cCondPg := "074"
							elseif oJson["paymentData"]["transactions"][1]["payments"][1]["installments"] == 5 //5x
								cCondPg := "077"
							elseif oJson["paymentData"]["transactions"][1]["payments"][1]["installments"] == 6 //6x
								cCondPg := "078"
							endif

							// 19/04/2023 - pega a TID da transação de pagamento 
							cTid 	:= oJson["paymentData"]["transactions"][1]["payments"][1]["tid"] 
							
							//payments string?null Provider's unique identifier for the transaction.
							 
							//cCondPg := fBuscaCond(oJson["paymentData"]["transactions"][1]["payments"][1]["paymentSystem"])
							//////////////////////////////////////////
							////		INICIO CABEÇALHO		  ////
							//////////////////////////////////////////
							aCabPV:={	{"C5_TIPO"   	,"N"        		,Nil},;
								{"C5_CLIENTE"	,aCliRet[2]					,Nil},;
								{"C5_LOJACLI"	,aCliRet[3]					,Nil},;
								{"C5_CLIENT"	,aCliRet[2]   				,Nil},;
								{"C5_LOJAENT"	,aCliRet[3]		   			,Nil},;
								{"C5_TRANSP"	,cTranspEcm        			,Nil},;
								{"C5_TIPOCLI"	,cCTipPes					,Nil},;
								{"C5_CONDPAG"	,cCondPg					,Nil},;
								{"C5_TABELA"	,cCdTabPrc					,Nil},;
								{"C5_VEND1"		,'000138'					,Nil},;
								{"C5_DESC2"		,nPDesc				        ,Nil},;
								{"C5_EMISSAO"	,Date() 					,Nil},;
								{"C5_MOEDA"   	,1							,Nil},;
								{"C5_NATUREZ"	,cCdNatu					,Nil},;
								{"C5_FRETE"		,nVlrFrt					,Nil},;
								{"C5_TPFRETE"	,"C"						,Nil},;
								{"C5_ZMENNOT"	,cPedId						,Nil},;
								{"C5_ZVLRLIB"	,nVlrPedido					,Nil},;
								{"C5_ZNUMMGT"	,cPedId						,Nil}}

							// Adiciona informação na mensagem da nota do Destinatário do produto
							If !Empty(cENome)
								Aadd(aCabPV,{"C5_MENNOTA"	,"Nome Destinatário: "+Alltrim(cENome), Nil })
							Endif
							
							// 19/04/2023 - Adição do ID de pagamento 
							If !Empty(cTid)
								Aadd(aCabPV,{"C5_XTID"	,cTid, Nil })
							Endif 
							
							//////////////////////////////////////////
							////		 	INICIO ITEM			  ////
							//////////////////////////////////////////

							//Inicia função para calcular valor unit do item
							//MaFisEnd()
							/*MaFisIni(aCliRet[2],;			// 1-Codigo Cliente
							aCliRet[3],;			// 2-Loja do Cliente
							"C",;				// 3-C:Cliente , F:Fornecedor
							"N",;				// 4-Tipo da NF
							cCTipPes,;			// 5-Tipo do Cliente/Fornecedor
							Nil,;
								Nil,;
								Nil,;
								Nil,;
								"MATA410")*/

							nX := 0
							aItens	:= {}  // Zera variável de itens
							For nX := 1 to Len(oJson["items"])

								cItem := Soma1(cItem)
								cProd := oJson["items"][nX]["refId"]

								dbSelectArea("SB1")
								dbSetOrder(1)//Codigo do Produto
								dbGoTop()
								If !dbSeek(xFilial("SB1")+cProd)
									cMsgError	:=	 "Produto do pedido no vtex não encontrado no Protheus. Cód. Produto (SKU): "+cProd
									FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"vtex",cMsgError)
									oActLog:Err(cMsgError)
									MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
									Break
								EndIf

								//Busca a TES conforme o tipo de operação. //TODO: Verificar
								If cTpOper <> ""
									cTes	:=	MaTESInt(2,cTpOper,aCliRet[2],aCliRet[3],"C",SB1->B1_COD/*,"C6_TES",cTipoCli*/) //							MaTesInt(nEntSai,cTpOper,cClieFor,cLoja,cTipoCF,cProduto,cCampo,cTipoCli) --> cTesRet
								Else
									//				cTes := "506"
									cMsgError	:=	 "Tipo de operação não encontrada no parametro (MV_ZTPOPER). Tipo Operação: "+cTpOper
									FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"vtex",cMsgError)
									oActLog:Err(cMsgError)
									MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
									Break
								EndIf

								dbSelectArea("SF4")
								dbSetOrder(1)
								If Empty(cTes)
									cMsgError	:=	 "Tes não localizada com a operação (TES Int.) informada. Item: "+cItem+" Produto: "+SB1->B1_COD+" Cliente: "+aCliRet[2]+" Loja: "+aCliRet[3]+" Operação: "+cTpOper
									FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"vtex",cMsgError)
									oActLog:Err(cMsgError)
									MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
									Break
								EndIf

								If !SF4->(dbSeek(FwXFilial("SF4")+cTes))
									cMsgError	:=	 "Tes não localizada. Item:"+cItem+" Produto:"+SB1->B1_COD+" Cliente: "+aCliRet[2]+" Loja: "+aCliRet[3]+" Operação: "+cTpOper
									FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"vtex",cMsgError)
									oActLog:Err(cMsgError)
									MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
									Break
								EndIf

								If SF4->F4_DUPLIC <> "S"
									cMsgError	:=	 "TES deve ser configurada para gerar financeiro: "+cTes
									FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"vtex",cMsgError)
									oActLog:Err(cMsgError)
									MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
									Break
								EndIf

								//Calcula valor liquido unitario (sem imposto)
								nQtdVen	:= oJson["items"][nX]["quantity"]
								nPrcVen	:= oJson["items"][nX]["price"] / 100
								nPrcVen	:= nPrcVen * (1 - (nPDesc/100 ))

								//Adiciona itens no array
								aItemPV:={	{"C6_ITEM"		,cItem			,Nil},;
									{"C6_PRODUTO"	,SB1->B1_COD	,Nil},;
									{"C6_OPER"		,cTpOper		,Nil},;
									{"C6_TES"		,cTes			,Nil},;
									{"C6_QTDVEN"	,nQtdVen		,Nil},;
									{"C6_QTDLIB"	,nQtdVen		,Nil},;
									{"C6_PRUNIT" 	,ROUND(nPrcVen,7)  	 ,Nil},;
									{"C6_PRCVEN" 	,ROUND(nPrcVen,7)  	 ,Nil},;
									{"C6_UM"		,SB1->B1_UM		,Nil},;
									{"C6_VALDESC"	,0	   			,Nil},;
									{"C6_ENTREG"	,Date()			,Nil},;
									{"C6_LOCAL"		,"02"			,Nil},;
									{"C6_XUPRCVE"	,nPrcVen 		,Nil},;
									{"C6_ZVTEX"		,"S" 			,Nil}}
								AADD(aItens,aItemPV)

								CPRODUTO := SB1->B1_COD

								If cFilAnt == "0101"
									CPRODUTO := Padr(CPRODUTO,TamSX3("B2_COD")[1])
									DbSelectArea("SB2")
									SB2->(DbSetOrder(1))
									If DbSeek("0101"+CPRODUTO+"02")
										//ALERT("já existe sb2 de: "+CPRODUTO+"/"+cFilAnt)
									Else
										CriaSb2(CPRODUTO,"02")
									Endif
								EndIf


							Next nX

							//Verifica valor total vtex x protheus
							//nRetVTot := MaFisRet(,"NF_TOTAL")
							///MaFisEnd()

							If LEN(aCabPV)>0 .AND. LEN(aItens)>0
								lRetTran := .F.
								Begin Transaction

									DbSelectArea("SA1"); DbSetOrder(1)
									DbSelectArea("SA3"); DbSetOrder(1)
									DbSelectArea("SA4"); DbSetOrder(1)
									DbSelectArea("SB1"); DbSetOrder(1)
									DbSelectArea("SE4"); DbSetOrder(1)
									DbSelectArea("SC5"); DbSetOrder(1)
									//TRY EXCEPTION
									 MSExecAuto({|x,y,z|Mata410(x,y,z)},aCabPV,aItens,3)
									//CATCHEXCEPTION USING oTryError
									 
									//END EXCEPTIOIN 

									If Type("oTryError") == "O"
										cTryError	:= oTryError:Description
										cTryError	+= oTryError:ErrorStack

										Aviso( "Erro em " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))), cTryError, { "Ok" }, 2 )
										CursorArrow()
									Endif
									If lMSErroAuto
										DisarmTransaction()
										aAutoErro 	:= GETAUTOGRLOG()
										cMsgErr 	:= "Erro na execução da rotina MATA410: "+chr(13)+chr(10)+alltrim(ArrTokStr(aAutoErro))
										oActLog:Err(cMsgErr)
										MsgStop(cMsgErr,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
										//Break
									else
										oRestClient := FWRest():New(cUrl)
										oRestClient:SetPath(cPath+cPedId+"/start-handling")
										oRestClient:SetPostParams("")
										If !oRestClient:Post(aHeadOut)
											sPostRet := oRestClient:oResponseH:cStatusCode
										endif
									EndIf

									lRetTran := .T.
								End Transaction
								If !lRetTran
									cMsgErr 	:= "Erro na transação, saindo da sequência de inclusão do pedido."
									oActLog:Err(cMsgErr)
									MsgStop(cMsgErr,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
									//Break
								EndIf
							EndIf
							//Somente bloqueia cliente para revisão quando for inclusão.
							// If lIncCli
							// 	SA1->(RecLock("SA1",.F.))
							// 	SA1->A1_MSBLQL	:=	"2"
							// 	SA1->(msUnlock())
							// EndIf
						Endif
					Else //pedido ja importado
						oRestClient := FWRest():New(cUrl)
						oRestClient:SetPath(cPath+cPedId+"/start-handling")
						oRestClient:SetPostParams("")
						If !oRestClient:Post(aHeadOut)
							sPostRet := oRestClient:oResponseH:cStatusCode
						Endif
					Endif
					(cAliasSC5)->(DbCloseArea())

				Endif
			Next
		Endif
	Endif
	FreeObj(oRestClient)

	RESTAREA(aAreaAnt)

Return lRet

Static function fBuscaCond(cCondicao)
	LOCAL cRet := "001"
	Local cAliasSE4	:= GetNextAlias()

	BeginSql alias cAliasSE4
		SELECT E4_CODIGO
			FROM %table:SE4% SE4
			WHERE SE4.E4_ZCODVTE =  %exp:cCondicao%
	EndSql

	If !(cAliasSE4)->(Eof())
		cRet := (cAliasSE4)->E4_CODIGO
	ENDIF

return cRet

/*/{Protheus.doc} SchedDef

Função responsavel por disponibilizar a rotina via Schedule

@author charles.totvs
@since 27/05/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function SchedDef()
	// aReturn[1] - Tipo
	// aReturn[2] - Pergunte
	// aReturn[3] - Alias
	// aReturn[4] - Array de ordem
	// aReturn[5] - Titulo
Return { "P", "VTEX002", "", {}, "" }



/* Exemplo de Order 
https://developers.vtex.com/docs/api-reference/orders-api#get-/api/oms/pvt/orders/-orderId-
{
  "emailTracked": "a27499cad31f42b7a771ae34f57c8358@ct.vtex.com.br",
  "approvedBy": "Person's name",
  "cancelledBy": "Person's name",
  "cancelReason": "Explanation for cancellation",
  "orderId": "v5195004lux-01",
  "sequence": "502556",
  "marketplaceOrderId": "",
  "marketplaceServicesEndpoint": "http://oms.vtexinternal.com.br/api/oms?an=luxstore",
  "sellerOrderId": "00-v5195004lux-01",
  "origin": "Marketplace",
  "affiliateId": "",
  "salesChannel": "1",
  "merchantName": null,
  "status": "handling",
  "statusDescription": "Preparando Entrega",
  "value": 1160,
  "creationDate": "2019-01-28T20:09:43.899958+00:00",
  "lastChange": "2019-02-06T20:46:11.7010747+00:00",
  "orderGroup": null,
  "totals": [
    {
      "id": "Items",
      "name": "Total dos Itens",
      "value": 3290
    },
    {
      "id": "Discounts",
      "name": "Total dos Descontos",
      "value": 0
    },
    {
      "id": "Shipping",
      "name": "Total do Frete",
      "value": 1160
    },
    {
      "id": "Tax",
      "name": "Total da Taxa",
      "value": 0
    },
    {
      "id": "Change",
      "name": "Total das mudanças",
      "value": -3290
    }
  ],
  "items": [
    {
      "uniqueId": "87F0945396994B349158C7D9C9941442",
      "id": "1234568358",
      "productId": "9429485",
      "ean": null,
      "lockId": "00-v5195004lux-01",
      "itemAttachment": {
        "content": {},
        "name": null
      },
      "attachments": [],
      "quantity": 1,
      "seller": "1",
      "name": "Bay Max L",
      "refId": "BIGHEROBML",
      "price": 3290,
      "listPrice": 3290,
      "manualPrice": null,
      "priceTags": [],
      "imageUrl": "http://luxstore.vteximg.com.br/arquivos/ids/159263-55-55/image-cc1aed75cbfa424a85a94900be3eacec.jpg?v=636795432619830000",
      "detailUrl": "/bay-max-9429485/p",
      "components": [],
      "bundleItems": [],
      "params": [],
      "offerings": [],
      "sellerSku": "1234568358",
      "priceValidUntil": null,
      "commission": 0,
      "tax": 0,
      "preSaleDate": null,
      "additionalInfo": {
        "brandName": "VTEX",
        "brandId": "2000023",
        "categoriesIds": "/1/",
        "productClusterId": "135,142",
        "commercialConditionId": "5",
        "dimension": {
          "cubicweight": 0.7031,
          "height": 15,
          "length": 15,
          "weight": 15,
          "width": 15
        },
        "offeringInfo": "Fragile.",
        "offeringType": null,
        "offeringTypeId": null
      },
      "measurementUnit": "un",
      "unitMultiplier": 1,
      "sellingPrice": 3290,
      "isGift": false,
      "shippingPrice": null,
      "rewardValue": 0,
      "freightCommission": 0,
      "priceDefinitions": null,
      "taxCode": null,
      "parentItemIndex": null,
      "parentAssemblyBinding": null
    }
  ],
  "marketplaceItems": [],
  "clientProfileData": {
    "id": "clientProfileData",
    "email": "rodrigo.cunha@vtex.com.br",
    "firstName": "Rodrigo",
    "lastName": "VTEX",
    "documentType": "cpf",
    "document": "11047867702",
    "phone": "+5521972321094",
    "corporateName": null,
    "tradeName": null,
    "corporateDocument": null,
    "stateInscription": null,
    "corporatePhone": null,
    "isCorporate": false,
    "userProfileId": "5a3692de-358a-4bea-8885-044bce33bb93",
    "customerClass": null
  },
  "giftRegistryData": null,
  "marketingData": null,
  "ratesAndBenefitsData": {
    "id": "ratesAndBenefitsData",
    "rateAndBenefitsIdentifiers": []
  },
  "shippingData": {
    "id": "shippingData",
    "address": {
      "addressType": "residential",
      "receiverName": "Rodrigo Cunha",
      "addressId": "-1425945657910",
      "postalCode": "22250-040",
      "city": "Rio de Janeiro",
      "state": "RJ",
      "country": "BRA",
      "street": "Praia de Botafogo",
      "number": "300",
      "neighborhood": "Botafogo",
      "complement": "3",
      "reference": null,
      "geoCoordinates": []
    },
    "logisticsInfo": [
      {
        "itemIndex": 0,
        "selectedSla": "Normal",
        "lockTTL": "10d",
        "price": 1160,
        "listPrice": 1160,
        "sellingPrice": 1160,
        "deliveryWindow": null,
        "deliveryCompany": "Todos os CEPS",
        "shippingEstimate": "5bd",
        "shippingEstimateDate": "2019-02-04T20:33:46.4595004+00:00",
        "slas": [
          {
            "id": "Normal",
            "name": "Normal",
            "shippingEstimate": "5bd",
            "deliveryWindow": null,
            "price": 1160,
            "deliveryChannel": "delivery",
            "pickupStoreInfo": {
              "additionalInfo": null,
              "address": null,
              "dockId": null,
              "friendlyName": null,
              "isPickupStore": false
            },
            "polygonName": null
          },
          {
            "id": "Expressa",
            "name": "Expressa",
            "shippingEstimate": "5bd",
            "deliveryWindow": null,
            "price": 1160,
            "deliveryChannel": "delivery",
            "pickupStoreInfo": {
              "additionalInfo": null,
              "address": null,
              "dockId": null,
              "friendlyName": null,
              "isPickupStore": false
            },
            "polygonName": null
          },
          {
            "id": "Quebra Kit",
            "name": "Quebra Kit",
            "shippingEstimate": "2bd",
            "deliveryWindow": null,
            "price": 1392,
            "deliveryChannel": "delivery",
            "pickupStoreInfo": {
              "additionalInfo": null,
              "address": null,
              "dockId": null,
              "friendlyName": null,
              "isPickupStore": false
            },
            "polygonName": null
          },
          {
            "id": "Sob Encomenda",
            "name": "Sob Encomenda",
            "shippingEstimate": "32bd",
            "deliveryWindow": null,
            "price": 1392,
            "deliveryChannel": "delivery",
            "pickupStoreInfo": {
              "additionalInfo": null,
              "address": null,
              "dockId": null,
              "friendlyName": null,
              "isPickupStore": false
            },
            "polygonName": null
          }
        ],
        "shipsTo": [
          "BRA"
        ],
        "deliveryIds": [
          {
            "courierId": "197a56f",
            "courierName": "Todos os CEPS",
            "dockId": "1",
            "quantity": 1,
            "warehouseId": "1_1"
          }
        ],
        "deliveryChannel": "delivery",
        "pickupStoreInfo": {
          "additionalInfo": null,
          "address": null,
          "dockId": null,
          "friendlyName": null,
          "isPickupStore": false
        },
        "addressId": "-1425945657910",
        "polygonName": null
      }
    ],
    "trackingHints": null,
    "selectedAddresses": [
      {
        "addressId": "-1425945657910",
        "addressType": "residential",
        "receiverName": "Rodrigo Cunha",
        "street": "Praia de Botafogo",
        "number": "518",
        "complement": "10",
        "neighborhood": "Botafogo",
        "postalCode": "22250-040",
        "city": "Rio de Janeiro",
        "state": "RJ",
        "country": "BRA",
        "reference": null,
        "geoCoordinates": []
      }
    ]
  },
  "paymentData": {
    "transactions": [
      {
        "isActive": true,
        "transactionId": "418213DE29634837A63DD693A937A696",
        "merchantName": "luxstore",
        "payments": [
          {
            "id": "D3DEECAB3C6C4B9EAF8EF4C1FE062FF3",
            "paymentSystem": "6",
            "paymentSystemName": "Boleto Bancário",
            "value": 4450,
            "installments": 1,
            "referenceValue": 4450,
            "cardHolder": null,
            "firstDigits": null,
            "cvv2": null,
            "expireMonth": null,
            "expireYear": null,
            "lastDigits": null,
            "url": "https://luxstore.vtexpayments.com.br:443/BankIssuedInvoice/Transaction/418213DE29634837A63DD693A937A696/Payment/D3DEECAB3C6C4B9EAF8EF4C1FE062FF3/Installment/{Installment}",
            "giftCardId": null,
            "cardNumber": null,
            "giftCardName": null,
            "giftCardCaption": null,
            "redemptionCode": null,
            "group": "bankInvoice",
            "tid": null,
            "dueDate": "2019-02-02",
            "connectorResponses": {}
          }
        ]
      }
    ]
  },
  "packageAttachment": {
    "packages": []
  },
  "sellers": [
    {
      "id": "1",
      "name": "Loja do Suporte",
      "logo": ""
    }
  ],
  "callCenterOperatorData": null,
  "followUpEmail": "7bf3a59bbc56402c810bda9521ba449e@ct.vtex.com.br",
  "lastMessage": null,
  "hostname": "luxstore",
  "invoiceData": null,
  "changesAttachment": {
    "id": "changeAttachment",
    "changesData": [
      {
        "reason": "Blah",
        "discountValue": 3290,
        "incrementValue": 0,
        "itemsAdded": [],
        "itemsRemoved": [
          {
            "id": "1234568358",
            "name": "Bay Max L",
            "quantity": 1,
            "price": 3290,
            "unitMultiplier": null
          }
        ],
        "receipt": {
          "date": "2019-02-06T20:46:04.4003606+00:00",
          "orderId": "v5195004lux-01",
          "receipt": "029f9ab8-751a-4b1e-bf81-7dd25d14b49b"
        }
      }
    ]
  },
  "openTextField": null,
  "roundingError": 0,
  "orderFormId": "caae7471333e403f959fa5fd66951340",
  "commercialConditionData": null,
  "isCompleted": true,
  "customData": null,
  "storePreferencesData": {
    "countryCode": "BRA",
    "currencyCode": "BRL",
    "currencyFormatInfo": {
      "CurrencyDecimalDigits": 2,
      "CurrencyDecimalSeparator": ",",
      "CurrencyGroupSeparator": ".",
      "CurrencyGroupSize": 3,
      "StartsWithCurrencySymbol": true
    },
    "currencyLocale": 1046,
    "currencySymbol": "R$",
    "timeZone": "E. South America Standard Time"
  },
  "allowCancellation": false,
  "allowEdition": false,
  "isCheckedIn": false,
  "marketplace": {
    "baseURL": "http://oms.vtexinternal.com.br/api/oms?an=luxstore",
    "isCertified": null,
    "name": "luxstore"
  },
  "authorizedDate": "2019-01-28T20:33:04+00:00",
  "invoicedDate": null
}
*/
