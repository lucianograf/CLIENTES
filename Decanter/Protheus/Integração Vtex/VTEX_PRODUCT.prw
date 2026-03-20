#INCLUDE "totvs.ch"
#include 'json.ch'
/*/{Protheus.doc} VTEX_PRODUCT
Rotina de integração de Produtos para o VTEX 
@type function
@version  
@author marcelo
@since 7/29/2023
@return variant, return_description
/*/
User Function VTEX_PRODUCT()

	RpcSetType(3)
	RpcSetEnv("01")

	U_VTEX001()

	RpcClearEnv()

Return

/*/{Protheus.doc} VTEX001
Função para rodar a carga dos produtos
@type function
@version  
@author marcelo
@since 7/29/2023
@return variant, return_description
/*/
User Function VTEX001()

	Local cDescDet		:=	""
	Local lEnd			:= .F.
	Local cLockName		:=	ProcName()+Alltrim(SM0->M0_CODIGO)+Alltrim(SM0->M0_CODFIL)
	Private lIsBlind	:=	isBlind()

	If !LockByName(cLockName,.F.,.F.)
		MsgStop("Rotina está sendo processada por outro usuário")
		U_GetUsrLock(cLockName)
		Return
	EndIf
	U_PutUsrLock(cLockName)
	

	oActLog	:=	ACTXLOG():New()

	oActLog:Start("VTEX001',' Iniciando integração com Vtex",)
	FWLogMsg("INFO','",'1',"VTEX001",,"Vtex',' Iniciando integração com Vtex")

	oActLog:Inf("VTEX001",If(lIsBlind,"Executado VIA JOB","Executado manualmente com interface"))
	FWLogMsg("INFO","LAST",'1',"VTEX001",,"Vtex",If(lIsBlind,"Executando via JOB","Executando em tela"))

	If lIsBlind

		U_RunV001()

	Else

		cDescDet	:= "Rotina responsável por realizar o envio a atualização dos produtos para o Vtex"
		oGrid		:=	FWGridProcess():New(   "VTEX001",  "Enviar Produtos para Vtex", cDescDet, {|lEnd| U_RunV001(@lEnd)}, "")
		oGrid:SetMeters(2)
		oGrid:SetAbort(.T.)
		oGrid:Activate()

	EndIf

	oActLog:Fin()
	FWLogMsg("INFO','LAST",'1',"VTEX001",,"Vtex','Finalizado integração com Vtex")

	UnLockByName(cLockName,.F.,.F.)
	U_DelUsrLock(cLockName)

Return
/*
função de integração protheus e vtex
*/
User Function RunV001(lEnd)

	Local cMsgError 	:= ''

	Local nCount		:=	0
	Local nTotSucess	:=	0
	Local nTotError		:= 0

	Local bObject := {|| JsonObject():New()}
	Local oJson   := Eval(bObject)
	Local oObj   := NIL

	local oRestClient, oRestSpec as object
	local cPath := "/api/catalog/pvt/product"
	local aHeadOut as array
	local cBody := ""
	//Local cUrCatalog	:= "/api/catalog/pvt/stockkeepingunit"

	Private cURL  	    := GetMv("MA_VTEXURL"	,,"https://decantervinhos.myvtex.com")
	// Private cAppKey	    := GetMv("MA_VTEXKEY"	,,"vtexappkey-decantervinhos-JQBAGL")
	// Private cAppToken	:= GetMv("MA_VTEXTOKEN"	,,"KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")

	Begin Sequence
		//É aberta uma unica sessao para realizar o processamento no Vtex

		If !lIsBlind
			oGrid:SetMaxMeter(4,1,"Excluindo Logs antigos")
			oGrid:SetIncMeter(1)
			ProcessMessage()
		EndIf

		If !lIsBlind
			oGrid:SetMaxMeter(4,1,"Realizando autenticação com Vtex")
			oGrid:SetIncMeter(1)
			ProcessMessage()
		EndIf

		If !lIsBlind
			oGrid:SetIncMeter(1,"Verificando produtos a serem enviados ao Vtex")
			oGrid:SetIncMeter(2,"")
			ProcessMessage()
		EndIf


		//realiza varedura de produtos na base do sistema, trazendo todos
		beginSQL Alias "SB1TMP"
 
			SELECT ZFT_DESCR AS Descricao
				   ,B1_SAFRA AS Safra
				   ,CAST(ZFT_SUSTEN AS VARCHAR(2000)) AS Sustentabilidade
				   ,B1_COD AS Codigo
				   ,Z04_DESCRI AS Tipo
				   ,Z04_CTVTEX AS Cat_Vtex
				   ,CAST(ZFT_APRESE AS VARCHAR(2000)) AS Apresentacao
				   ,z03_apelid AS Produtor
				   ,Z03_VTEX AS IDProdutor
				   ,YA_DESCR AS Pais
				   ,ZFT_DTLREG AS Regiao
				   ,ZFT_CASTA as Uva1
				    ,CASE
					 WHEN ZFT_CORPO = 'C'
					  THEN 'De Corpo'
				 	 WHEN ZFT_CORPO = 'R'
					  THEN 'Robusto'
					 WHEN ZFT_CORPO = 'L'
					  THEN 'Leve'
					 WHEN ZFT_CORPO = '1'
					  THEN 'Corpo Leve'
					 WHEN ZFT_CORPO = '2'
					  THEN 'Corpo Médio'
					 WHEN ZFT_CORPO = '3'
					  THEN 'Encorpado'
					 ELSE ' '
				    END AS Corpo1
					,ZFT_VOLUME AS Volume
					,ZFT_ALCOOL AS Alcool
					,CAST(ZFT_CRITIC AS VARCHAR(2000)) AS Depoimentos
					,CAST(ZFT_CLIMA AS VARCHAR(2000)) AS Clima
					,CAST(ZFT_SOLO AS VARCHAR(2000)) AS Solo
					,CAST(ZFT_ENOGAS AS VARCHAR(2000)) AS Harmonizacao
					,ZFT_TEMPER AS Temperatura
					,ZFT_GUARDA AS Guarda
					,CAST(ZFT_DICAS AS VARCHAR(2000)) AS Dicas
					,CASE
					  WHEN ZFT_ROSCA = '2'
				 	   THEN 'Não'
					  ELSE 'Sim'
					 END AS Tampa_Rosca
					,CAST(ZFT_INFO AS VARCHAR(2000)) AS Informacoes_Gerais
					,DA1_PRCVEN AS Preco_de_Venda_Normal
					,B2_QATU - B2_RESERVA AS Estoque
					,B1_PESO AS Peso_Unitario
					,ISNULL(B5_COMPRLC,0) AS Comprimento
					,ISNULL(B5_LARGLC,0)  AS Largura
					,ISNULL(B5_ALTURLC,0) AS Altura
					,B1_PESBRU AS PesoBruto 
					,B2_LOCAL AS ARMAZEM
					,CAST(ZFT_AMADUR AS VARCHAR(2000)) AS Amadurecimento
					,CAST(ZFT_PREMIO AS VARCHAR(2000)) AS Premio
					,CAST(ZFT_SOBREP AS VARCHAR(2000)) AS Sobre_produto
					,CAST(ZFT_HISTOR AS VARCHAR(2000)) AS Sobre_vinho
					,CAST(ZFT_ELABOR AS VARCHAR(2000)) AS Elaboracao
					,B1_CODGTIN B1EAN 
					,ZFT_JAMES
					,ZFT_PARKER
					,ZFT_SPECTA
					,ZFT_WINE
					,ZFT_VINOUS
					,ZFT_DECA
					,ZFT_TIM
					,ZFT_DESCOR
					,ZFT_PENIN
					,ZFT_JANCIS
					,ZFT_REVIST
					,ZFT_GRANDE
					,ZFT_ROSSO
					,ZFT_ADEGA
			   FROM %table:SB1% SB1
			  INNER JOIN %table:ZFT% ZFT 
			     ON ZFT.D_E_L_E_T_ <> '*'
				AND ZFT_COD = B1_ZFT
				AND ZFT_FILIAL = %xFilial:ZFT%
			  INNER JOIN %table:SB2% SB2 
			     ON SB2.D_E_L_E_T_ <> '*'
				AND B2_FILIAL = '0101'
				AND B2_COD = B1_COD
				AND B2_LOCAL = '02'
			  INNER JOIN %table:DA0% DA0 ON DA0.D_E_L_E_T_ <> '*'
				AND DA0_ATIVO = '1'
				AND DA0_CODTAB = '301'
				AND DA0_FILIAL = %xFilial:DA0%
			  INNER JOIN %table:DA1% DA1 ON DA1.D_E_L_E_T_ <> '*'
				AND DA1_CODTAB = DA0_CODTAB
				AND DA1_CODPRO = B1_COD
				AND DA1_PRCVEN <> 0
				AND DA1_ATIVO = '1'
				AND DA1_FILIAL = %xFilial:DA1%
			  INNER JOIN %table:Z03% Z03 
			     ON Z03.D_E_L_E_T_ <> '*'
				AND ZFT_PRODUT = Z03_CODIGO
				AND Z03_FILIAL = %xFilial:SZ03%
			  INNER JOIN %table:Z02% Z02 
			     ON Z02.D_E_L_E_T_ <> '*'
				AND Z02_CODIGO = Z03_REGIAO
				AND Z02_FILIAL = %xFilial:Z02%
			  INNER JOIN %table:Z04% Z04 
			     ON Z04.D_E_L_E_T_ <> '*'
				AND ZFT_CLASSI = Z04_CODIGO
				AND ZFT_FILIAL = %xFilial:ZFT%
			  INNER JOIN %table:SYA% SYA 
				 ON SYA.D_E_L_E_T_ <> '*'
				AND YA_CODGI = Z03_PAIS
				AND YA_FILIAL = %xFilial:SYA%
			  INNER JOIN %Table:SB5% B5 
				 ON B5.D_E_L_E_T_ <> '*'
				AND B5_COD = B1_COD 
				AND B5_FILIAL = %xFilial:SB5%
			  WHERE SB1.D_E_L_E_T_ <> '*'
				AND B1_TIPO = 'ME'
				AND B1_MSBLQL = '2' 
				//AND B1_COD IN('00249622') //, '00902123','00098520')
			 ORDER BY SB1.R_E_C_N_O_ DESC 
		EndSQL
		Count to nCount
		SB1TMP->(dbGotop())

		If SB1TMP->(Eof())
			oActLog:Inf("VTEX001','Nenhum produto localizado para atualizar ou incluir")
			lRet	:=	.T.
			Break
		EndIf

		If !lIsBlind
			oGrid:SetMaxMeter(nCount,2)
			ProcessMessage()
		EndIf

		aHeadOut := {}
		//Aadd(aHeadOut, "Content-Type: application/json; charset=utf-8")
		Aadd(aHeadOut, "Content-Type: application/json")
		Aadd(aHeadOut, "X-VTEX-API-AppKey: vtexappkey-decantervinhos-JQBAGL")
		Aadd(aHeadOut, "X-VTEX-API-AppToken: KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")

		While !SB1TMP->(EOF())
			cProdID:=""

			oJson["Name"]           	:= AllTrim(SB1TMP->Descricao)
			oJson["Title"]				:= NoAcento(AllTrim(SB1TMP->Descricao))
			oJson["CategoryId"]     	:= Iif(Empty(SB1TMP->Cat_Vtex),1,Val(SB1TMP->Cat_Vtex)) //1
			oJson["BrandId"]        	:= SB1TMP->IDProdutor
			oJson["LinkId"]				:= sfAjust(SB1TMP->Descricao)
			oJson["DepartmentId"]   	:= 1
			oJson["BrandName"]      	:= Alltrim(SB1TMP->Produtor)
			oJson["IsVisible"]      	:= .T.
			oJson["IsActive"]       	:= .T.
			oJson["TaxCode"]        	:= AllTrim(SB1TMP->Codigo)
			oJson["MetaTagDescription"]	:= AllTrim(SB1TMP->Sobre_vinho)
			oJson["Description"]		:= AllTrim(SB1TMP->Sobre_vinho)
			oJson["RefId"]          	:= AllTrim(SB1TMP->Codigo)
			oJson["ShowWithoutStock"]	:= .T.
			oJson["Score"]				:= 1
			//{"Id":295,
			//"Name":"Bouza Tempranillo Tannat",
			//"DepartmentId":1,
			//"CategoryId":1,
			//"BrandId":2000008,
			//"LinkId":"Bouza-Tempranillo-Tannat",
			//"RefId":"00030420",
			//"IsVisible":true,
			//"Description":null,
			//"DescriptionShort":null,
			//"ReleaseDate":null,
			//"KeyWords":null,
			//"Title":null,
			//"IsActive":true,
			//"TaxCode":"00030420",
			//"MetaTagDescription":null,
			//"SupplierId":null,
			//"ShowWithoutStock":true,
			//"AdWordsRemarketingCode":null,
			//"LomadeeCampaignCode":null,
			//"Score":1}"

			cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
			oRestClient := FWRest():New(cUrl)
			ConOut(cBody)
			//INCLUSÃO DE PRODUTO
			oRestClient:setPath("/api/catalog_system/pvt/products/productgetbyrefid/"+alltrim(SB1TMP->Codigo))
			If oRestClient:Get(aHeadOut)  .Or. "Product not found by refId:" $  oRestClient:GetResult()
				sPostRet := oRestClient:GetResult()
				If FWJsonDeserialize(sPostRet,@oObj)
					If SubStr(oRestClient:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O" //produto existe deve ser atualizado (PUT)
						cProdID := oObj:Id

						oRestClient:setPath("/api/catalog/pvt/product/"+alltrim(str(cProdID)))
						If oRestClient:Put(aHeadOut, cBody)
							ConOut("PUT", oRestClient:GetResult())
						Else
							ConOut("PUT", oRestClient:GetLastError())
						EndIf
					ELSE //novo produto
						oRestClient:SetPath(cPath)
						oRestClient:SetPostParams(EncodeUTF8(cBody, "cp1252"))

						If oRestClient:Post(aHeadOut)
							sPostRet := oRestClient:GetResult()
							If FWJsonDeserialize(sPostRet,@oObj)
								If SubStr(oRestClient:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O"
									cProdID := oObj:Id
									nTotSucess++
								Else
									varinfo("HttpPost Failed.", sPostRet)
									nTotSucess--
								EndIf
							Else
								Count("Erro no Deserialize!")
							EndIf
						Else
							ConOut(sPostRet := oRestClient:GetResult())
						Endif
					endif
				endif
			Else
				ConOut("PUT", oRestClient:GetResult())
			EndIf

			iF !EMPTY(cProdID)
				//incluir especificações
				cBody := '['
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Tipo)+'"],"Id":19,"Name":"Tipo"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Sustentabilidade)+'"],"Id":20,"Name":"Sustentabilidade"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Produtor)+'"],"Id":21,"Name":"Produtor"}, '
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Pais)+'"],"Id":22,"Name":"País"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Regiao)+'"],"Id":23,"Name":"Região"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Uva1)+'"],"Id":24,"Name":"Uvas"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Corpo1)+'"],"Id":25,"Name":"Corpo"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Volume)+'"],"Id":26,"Name":"Volume da garrafa"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Alcool)+'"],"Id":27,"Name":"Teor alcoólico"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Sobre_vinho)+'"],"Id":28,"Name":"Introdução produtor e região"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Harmonizacao)+'"],"Id":29,"Name":"Harmonização"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Temperatura)+'"],"Id":30,"Name":"Temperatura de serviço"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Guarda)+'"],"Id":31,"Name":"Estimativa de guarda"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Dicas)+'"],"Id":32,"Name":"Dica do nosso sommelier"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Informacoes_Gerais)+'"],"Id":34,"Name":"Informação sobre país, região, uva"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Amadurecimento)+'"],"Id":35,"Name":"Amadurecimento"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Tampa_Rosca)+'"],"Id":36,"Name":"Vedação"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Sobre_vinho)+'"],"Id":37,"Name":"Caracteristicas MKT"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Elaboracao)+'"],"Id":39,"Name":"Elaboração"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Clima)+'"],"Id":40,"Name":"Característica do clima"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Solo)+'"],"Id":41,"Name":"Características do solo"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Premio)+'"],"Id":42,"Name":"Premiações"},'
				cBody += '{"Value": ["'+sfStrTran(SB1TMP->Safra)+'"],"Id":43,"Name":"Safra"}'

				If !Empty(SB1TMP->ZFT_JAMES) //ZFT_JAMES	JAMES	53		James Suckling (53)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100   
					cVarAux 	:= SB1TMP->ZFT_JAMES
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_JAMES', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)

					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":53,"Name":"James Suckling"}'
				Endif
				If !Empty(SB1TMP->ZFT_PARKER) //ZFT_PARKER	PARKER	54		Robert Parker (54)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_PARKER
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_PARKER', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)

					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":54,"Name":"Robert Parker"}'
				Endif
				If !Empty(SB1TMP->ZFT_SPECTA) //ZFT_SPECTA	SPECTATOR	51	Wine Spectator (51)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_SPECTA
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_SPECTA', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":51,"Name":"Wine Spectator"}'
				Endif
				If !Empty(SB1TMP->ZFT_WINE) // 	ZFT_WINE	WINE ENTHUSIAST	50 Wine Enthusiast (50)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_WINE
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_WINE', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":50,"Name":"Wine Enthusiast"}'
				Endif
				If !Empty(SB1TMP->ZFT_VINOUS) //ZFT_VINOUS	VINOUS	56			Vinous (56)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_VINOUS
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_VINOUS', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":56,"Name":"Vinous"}'
				Endif
				If !Empty(SB1TMP->ZFT_DECA) //	ZFT_DECA	DECANTER	78		Decanter (78)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_DECA
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_DECA', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":78,"Name":"Decanter"}'
				Endif
				If !Empty(SB1TMP->ZFT_TIM) // ZFT_TIM	TIM ATKIN	79			Tim Atkin (79)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_TIM
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_TIM', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":79,"Name":"Tim Atkin"}'
				Endif
				If !Empty(SB1TMP->ZFT_DESCOR) // ZFT_DESCOR	DESCORCHADOS	49	Descorchados (49)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_DESCOR
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_DESCOR', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":49,"Name":"Descorchados"}'
				Endif
				If !Empty(SB1TMP->ZFT_PENIN)  // ZFT_PENIN	PENIN	80			Peñin (80)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                  
					cVarAux 	:= SB1TMP->ZFT_PENIN
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_PENIN', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":80,"Name":"Peñin"}'
				Endif
				If !Empty(SB1TMP->ZFT_JANCIS) // ZFT_JANCIS	JANCIS	52			Jancis Robinson (52)
					//01=15;02=15,5;03=16;04=16,5;05=17;06=17,5;07=18;08=18,5;09=19;10=19,5;11=20                                                     
					cVarAux 	:= SB1TMP->ZFT_JANCIS
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_JANCIS', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":52,"Name":"Jancis Robinson"}'
				Endif
				If !Empty(SB1TMP->ZFT_REVIST) // ZFT_REVIST	REVISTA	81			Revista de Vinhos (81)
					//01=15;02=15,5;03=16;04=16,5;05=17;06=17,5;07=18;08=18,5;09=19;10=19,5;11=20                                                     
					cVarAux 	:= SB1TMP->ZFT_REVIST
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_REVIST', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":81,"Name":"Revista de Vinhos"}'
				Endif
				If !Empty(SB1TMP->ZFT_GRANDE) // ZFT_GRANDE	GRANDES	82			Grandes Escolhas (82)
					//01=15;02=15,5;03=16;04=16,5;05=17;06=17,5;07=18;08=18,5;09=19;10=19,5;11=20                                                     
					cVarAux 	:= SB1TMP->ZFT_GRANDE
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_GRANDE', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":82,"Name":"Grandes Escolhas"}'
				Endif
				If !Empty(SB1TMP->ZFT_ROSSO) //  ZFT_ROSSO	ROSSO	83			Gambero Rosso (83)
					//1=1_Bicchiere;2=2_Bicchieri;3=2_Bicchieri Rossi;4=3_Bicchieri                                                                   
					cVarAux 	:= SB1TMP->ZFT_ROSSO
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_ROSSO', "X3_CBOX"),,, 1)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":86,"Name":"Gambero Rosso"}'
				Endif
				If !Empty(SB1TMP->ZFT_ADEGA) //  ZFT_ADEGA	ADEGA	91			Adega (91)
					//01=88;02=89;03=90;04=91;05=92;06=93;07=94;08=95;09=96;10=97;11=98;12=99;13=100                                                                   
					cVarAux 	:= SB1TMP->ZFT_ADEGA
					aCombo  	:= RetSX3Box(GetSX3Cache('ZFT_ADEGA', "X3_CBOX"),,, 2)
                	nPos    	:= AScan(aCombo, {|x| x[2] = cVarAux})
                	cVarAux 	:= iIf(nPos > 0, aCombo[nPos,3], cVarAux)
					cBody += ',{"Value": ["'+sfStrTran(cVarAux)+'"],"Id":91,"Name":"Adega"}'
				Endif

				cBody += ']'

				oRestSpec := FWRest():New(cUrl)
				oRestSpec:SetPath("/api/catalog_system/pvt/products/"+alltrim(str(cProdID))+"/specification")
				oRestSpec:SetPostParams(EncodeUTF8(cBody, "cp1252"))
				ConOut("/api/catalog_system/pvt/products/"+alltrim(str(cProdID))+"/specification" + " Json:" + cBody)

				If oRestSpec:Post(aHeadOut)
					sPostRet := oRestSpec:GetResult()
					nTotSucess++
				Else
					ConOut("oRestSpec:Post(" + cValToChar(oRestSpec:GetResult()) )
					nTotSucess--
				Endif

				//trade policies / politicas comerciais
				cBody := ''
				oRestSpec:SetPath("/api/catalog/pvt/product/"+alltrim(str(cProdID))+"/salespolicy/1")			//sales policies está fixo 1 - criar parametro
				ConOut("/api/catalog/pvt/product/"+alltrim(str(cProdID))+"/salespolicy/1")

				If oRestSpec:Post(aHeadOut)
					sPostRet := oRestSpec:GetResult()
					ConOut(sPostRet)
				Else
					ConOut("oRestSpec:Post(" + cValToChar(oRestSpec:GetResult()) )
				Endif

			


				//create SKU
				cSKUId := 0
				oJson   := Eval(bObject)
				oJson["ProductId"]			:= AllTrim(Str(cProdID))
				oJson["Name"]     			:= AllTrim(SB1TMP->Descricao)//"SKU"
				oJson["RefId"]     			:= AllTrim(SB1TMP->Codigo)
				//oJson["IsActive"]       	:= .T.
				oJson["PackagedHeight"] 	:= SB1TMP->Altura
				oJson["PackagedLength"] 	:= SB1TMP->Comprimento
				oJson["PackagedWidth"]  	:= SB1TMP->Largura
				oJson["PackagedWeightKg"]	:= SB1TMP->PesoBruto
				oJson["ActivateIfPossible"]	:= .T.
				cBody := EncodeUTF8(oJson:ToJson(), "cp1252")

				//verificar primeiro se já existe
				oRestClient:setPath("/api/catalog/pvt/stockkeepingunit?refId="+alltrim(SB1TMP->Codigo))
				If oRestClient:Get(aHeadOut)
					//SKU existe deve atualizar
					sPostRet := oRestClient:GetResult()
					If FWJsonDeserialize(sPostRet,@oObj)
						If SubStr(oRestClient:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O"
							cSKUId := oObj:Id
							oRestSpec:SetPath("/api/catalog/pvt/stockkeepingunit/"+alltrim(str(cSKUId)))

							if oRestSpec:Put(aHeadOut, cBody)
								sPostRet := oRestSpec:GetResult()
								ConOut("stockkeepingunit " +cBody + " "+sPostRet)
								If FWJsonDeserialize(sPostRet,@oObj)
									If SubStr(oRestSpec:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O"
										cSKUId := oObj:Id
									Else
										varinfo("HttpPost Failed.", sPostRet)
									EndIf
								Else
									Count("Erro no Deserialize!")
								EndIf
							else
								sPostRet := oRestSpec:GetResult()
								ConOut("erro "+sPostRet)
							endif
						Else

						Endif
					Else
						ConOut("erro "+sPostRet)
					Endif
				else
					oJson   := Eval(bObject)
					oJson["ProductId"]			:= AllTrim(Str(cProdID))
					oJson["Name"]     			:= AllTrim(SB1TMP->Descricao)//"SKU"
					oJson["RefId"]     			:= AllTrim(SB1TMP->Codigo)
					oJson["IsActive"]       	:= .T.
					oJson["PackagedHeight"] 	:= SB1TMP->Altura
					oJson["PackagedLength"] 	:= SB1TMP->Comprimento
					oJson["PackagedWidth"]  	:= SB1TMP->Largura
					oJson["PackagedWeightKg"]	:= SB1TMP->PesoBruto
					oJson["ActivateIfPossible"]	:= .T.
					cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
					//criar SKU
					oRestSpec:SetPath("/api/catalog/pvt/stockkeepingunit")
					oRestSpec:SetPostParams(cBody)
					ConOut("/api/catalog/pvt/stockkeepingunit - "+cBody)
					if oRestSpec:Post(aHeadOut)
						sPostRet := oRestSpec:GetResult()
						If FWJsonDeserialize(sPostRet,@oObj)
							If SubStr(oRestSpec:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O"
								cSKUId := oObj:Id
								ConOut("Cadastro Sku /api/catalog/pvt/stockkeepingunit" + cValToChar(cSKUId) )
							Else
								ConOut("Erro de Sku /api/catalog/pvt/stockkeepingunit" + sPostRet)
							EndIf
						Else
							Count("Erro no Deserialize -  /api/catalog/pvt/stockkeepingunit")
						EndIf
					Else 
						sPostRet := oRestSpec:GetResult()
						ConOut("Cadastro Sku /api/catalog/pvt/stockkeepingunit" + sPostRet)
					endif
				endif

				// Criar Ean
				///api/catalog_system/pvt/sku/stockkeepingunitbyean/{ean}

				//verificar primeiro se já existe
				oRestClient:setPath("/api/catalog/pvt/stockkeepingunit/"+AllTrim(Str(cProdID))+"/ean")
				If oRestClient:Get(aHeadOut)
					//SKU existe deve atualizar
					sPostRet := oRestClient:GetResult()

					If FWJsonDeserialize(sPostRet,@oObj)
						If SubStr(oRestClient:GetLastError(),1,3) == '200'
							ConOut(oRestClient:GetLastError())
							oRestSpec:SetPath("/api/catalog/pvt/stockkeepingunit/"+AllTrim(Str(cProdID))+"/ean/")
							///api/catalog/pvt/stockkeepingunit/{skuId}/ean
							//If oRestSpec:Delete(aHeadOut,"")
							//	sPostRet := oRestSpec:GetResult()
							//	ConOut("stockkeepingunit "+sPostRet)
							//Else
							//	sPostRet := oRestSpec:GetResult()
							//	ConOut("erro "+sPostRet)
							//Endif
						Else
							ConOut("erro "+sPostRet)
						Endif
					Else
						ConOut("erro "+sPostRet)
					Endif
				Else
					ConOut("Sem cadastro de Ean")
				Endif

				If !Empty(SB1TMP->B1Ean)
					
					oRestSpec:SetPath("/api/catalog/pvt/stockkeepingunit/"+AllTrim(Str(cProdID))+"/ean/"+Alltrim(SB1TMP->B1Ean))
					
					oRestSpec:SetPostParams("")
					
					//if oRestSpec:Put(aHeadOut, cBody)
					If oRestSpec:Post(aHeadOut)
						sPostRet := oRestSpec:GetResult()
						ConOut("Cadastro Ean - /api/catalog/pvt/stockkeepingunit/"+AllTrim(Str(cProdID))+"/ean/"+Alltrim(SB1TMP->B1Ean))
					Else 
						sPostRet := oRestSpec:GetResult()
						ConOut("Erro ao cadastrar Ean /api/catalog/pvt/stockkeepingunit/"+AllTrim(Str(cProdID))+"/ean/"+Alltrim(SB1TMP->B1Ean))
					Endif
				Endif
				
				//Removido em 18/09/23 por LWM INOVAÇÃO
				//Funcao migrada para o fonte OMSA010.prw
				//preço
				oRestSpec := FWRest():New("https://api.vtex.com")
				oJson   := Eval(bObject)
				oJson["basePrice"]	:= SB1TMP->Preco_de_Venda_Normal
				oJson["listPrice"]  := SB1TMP->Preco_de_Venda_Normal
				oJson["costPrice"] 	:= SB1TMP->Preco_de_Venda_Normal
				cBody := EncodeUTF8(oJson:ToJson(), "cp1252")

				oRestSpec:SetPath("/decantervinhos/pricing/prices/"+alltrim(str(cSKUId)))

				if oRestSpec:Put(aHeadOut,cBody)
					sPostRet := oRestSpec:GetResult()
					//ConOut(sPostRet)
					nTotSucess++
				else
					ConOut("Erro oRestSpec:Put(aHeadOut cBody:" + cBody)
					nTotSucess--
				endif
				
				//ESTOQUE
				oRestSpec := FWRest():New(cUrl)
				oJson   := Eval(bObject)
				oJson["unlimitedQuantity"]	:= .F.
				oJson["quantity"] 	:= SB1TMP->Estoque
				cBody := EncodeUTF8(oJson:ToJson(), "cp1252")

				oRestSpec:SetPath("/api/logistics/pvt/inventory/skus/"+alltrim(str(cSKUId))+"/warehouses/1fd47f1") //criar parametro para warehouse (1fd47f1)

				if oRestSpec:Put(aHeadOut, cBody)
					sPostRet := oRestSpec:GetResult()
					nTotSucess++
				Else
					nTotSucess--
				endif
			EndIf

			SB1TMP->(DbSkip())
			FreeObj(oRestClient)
		EndDo

	End Sequence

	cMsgLog	:=	"Total Produtos Enviados: "+cValToChar(nCount)+"   =>    Sucesso:"+cValToChar(nTotSucess)+"      Erro:"+cValToChar(nTotError)
	FWLogMsg("INFO','LAST",'1',"VTEX001','Vtex",cMsgError)
	ConOut(cMsgLog)
	oActLog:Inf(cMsgLog)

	IF Select("SB1TMP")>0
		SB1TMP->(dbCloseArea())
	EndIf

return nil


Static Function sfStrTran(cInText)

	Local 	cOut 	:= cInText

	cOut := StrTran(cOut,Chr(13),"")
	cOut := StrTran(cOut,Chr(10),"")
	cOut := StrTran(cOut,Chr(19),"")
	cOut := StrTran(cOut,'"',"")
	cOut := Alltrim(cOut)

Return cOut


Static Function sfAjust(cInText)

	Local 	cOut 	:= cInText

	cOut 	:= sfStrTran(cOut)
	cOut 	:= NoAcento(cOut)
	cOut 	:= StrTran(cOut,"Ñ","N")
	cOut 	:= StrTran(cOut,"ñ","n")
	cOut 	:= StrTran(cOut," ","-")
	cOut 	:= StrTran(cOut,"/","-")
	cOut 	:= StrTran(cOut,"\","-")
	cOut 	:= StrTran(cOut,">","-")
	cOut 	:= StrTran(cOut,"<","-")
	cOut 	:= StrTran(cOut,"&","-")
	cOut 	:= StrTran(cOut,"#","-")
	cOut 	:= StrTran(cOut,"*","-")
	cOut 	:= StrTran(cOut,"+","-")
	cOut 	:= StrTran(cOut,"%","-")
	cOut 	:= StrTran(cOut,"@","-")
	cOut 	:= StrTran(cOut,"|","-")
	cOut 	:= StrTran(cOut,";","-")
	cOut 	:= StrTran(cOut,"º","-")
	cOut 	:= StrTran(cOut,"ª","-")
	cOut 	:= StrTran(cOut,"°","-")

Return cOut

/*/{Protheus.doc} SchedDef
SchedDef para gerar agendamentos no Schedule 
@type function
@version  1
@author marcelo
@since 5/25/2023
@return Array, Array com dados 
/*/
Static Function SchedDef()
	// aReturn[1] - Tipo
	// aReturn[2] - Pergunte
	// aReturn[3] - Alias
	// aReturn[4] - Array de ordem
	// aReturn[5] - Titulo
Return { "P", "VTEX_PRODUCT", "", {}, "" }
