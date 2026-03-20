#INCLUDE "totvs.ch"
#include 'json.ch'


 /*/{Protheus.doc} GetSales
(long_description)
@type  Function
@author LWM INOVAÇÃO
@since 22/04/2023
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
	/*/
User Function DEFATI01()


// 0108 / 0103 / 0101
	If Select("SM0") == 0 
		RpcSetType(3)
		RpcSetEnv("01","0101")
		Sleep(5000)

		If Select("SM0") == 0
			Return
		Endif

		sfExec()
		RpcClearEnv()

		RpcSetType(3)
		RpcSetEnv("01","0103")
		Sleep(5000)

		If Select("SM0") == 0
			Return
		Endif

		sfExec()
		RpcClearEnv()

		RpcSetType(3)
		RpcSetEnv("01","0108")
		Sleep(5000)

		If Select("SM0") == 0
			Return
		Endif

		sfExec()
		RpcClearEnv()
	Else 
		sfExec()
	Endif

Return
/*/{Protheus.doc} sfExec
Função que executa a integração
@type function
@version  
@author marcelo
@since 10/29/2023
@return variant, return_description
/*/
Static Function sfExec()


	Local cArqLog       := "intQero_" + dToS(Date()) + "_" + StrTran(Time(), ':' , '-' ) + ".log"
	Private bObject     :={|| JsonObject():New()}
	Private oJson       := Eval(bObject)
	Private oObj        := NIL
	Private oRestClient as object
	Private cPath       := "/client"
	Private cBody       := ""
	Private cURL        := "https://qero-cdp.e-goi.com/public-api"
	Private aHeadOut    := {}
	Private sPostRetCli := """
	Private sPostRetPro := ""
	Private sPostRetVen	:= ""
	Private _cError     := ""
	Private cDirLog     := "\Loq_Quero\"
	Private lIsBlind    := isBlind()
	Private _cNota      := ""
	Private _cCliente   := ""



	//Se a pasta de log não existir, cria ela
	If ! ExistDir(cDirLog)
		MakeDir(cDirLog)
	EndIf

	Aadd(aHeadOut, "Content-Type: application/json")
	Aadd(aHeadOut, "APIKEY: ZQmwkRp9qEC7BvIUtyxDOTfl4gnAuX8cjh6bLdrJ")//pode se colocar em parametro

	// -- Pega as vendas para integrar
	sfGetSales()

	//-- Ocorreu erros no processamento
	if !Empty( _cError )
		_cError := "Processamento finalizado, abaixo as mensagens de log: " + CRLF + _cError
		MemoWrite(cDirLog + cArqLog, _cError)
		//ShellExecute("OPEN", cArqLog, "", cDirLog, 1)
	Endif

	
Return

/*/{Protheus.doc} sfGetSales
Função responsável para obter as vendas reaslizadas para integra-las a QERO 
@type function
@version  
@author LWM INOVAÇÃO
@since 7/20/2023
@return variant, return_description
/*/
Static Function sfGetSales()

	Local 	lRetCli    	 	:= .T.
	Local 	lRetProd    	:= .T.
	Local 	lRetVendas  	:= .T.
	//Local 	dDataFiltro 	:= (dDatabase -6) // -- Pega as vendas do dia anterior
	Private cLockName		:=	ProcName()+Alltrim(SM0->M0_CODIGO)+Alltrim(SM0->M0_CODFIL)


	// -- Verifica concorrencia da rotina
	If !LockByName(cLockName,.T.,.F.)
		_cError +="Rotina esta sendo processada por outro usuario"+ CRLF
		sfGetUsrLock(cLockName)
		Return
	EndIf


	sfPutUsrLock(cLockName)

	// -- Sql para pegar as vendas
	Private cAliasSC5 := GetNextAlias()
	beginSQL Alias cAliasSC5
 
		SELECT  SA1.R_E_C_N_O_ AS RECNOSA1, 
		        SB1.R_E_C_N_O_ AS RECNOSB1, 
				SF2.R_E_C_N_O_ AS RECNOSF2, 
				SD2.R_E_C_N_O_ AS RECNOSD2,
				ZFT.R_E_C_N_O_ AS RECNOZFT,
				Z03.R_E_C_N_O_ AS RECNOZ03,
				Z03_PAIS,
				YA_DESCR,
				F2_DOC,
				F2_SERIE,
				F2_CLIENTE,
				F2_LOJA,
				F2_FILIAL,
				D2_ITEM,
				D2_COD,
				D2_QUANT,
				D2_PRCVEN,
				D2_VALBRUT 
		   FROM %table:SF2% SF2
		  INNER JOIN %Table:SD2% SD2 
		     ON SD2.D_E_L_E_T_ = ' ' 
			AND D2_LOJA = F2_LOJA 
			AND D2_CLIENTE  = F2_CLIENTE 
			AND D2_SERIE = F2_SERIE 
			AND D2_DOC = F2_DOC 
			AND D2_QUANT > 0 
			AND D2_FILIAL = %xFilial:SD2% 
		  INNER JOIN %table:SB1% SB1
		     ON SB1.D_E_L_E_T_ = ' ' 
			AND B1_COD = D2_COD 
			AND B1_FILIAL = %xFilial:SB1%
		  INNER JOIN %table:SF4% SF4
		     ON SF4.D_E_L_E_T_ = ' '
			AND F4_DUPLIC = 'S'  
			AND F4_CODIGO = D2_TES 
			AND F4_FILIAL = %xFilial:SF4%
		  INNER JOIN %table:SA1% SA1
		     ON SA1.D_E_L_E_T_ = ' ' 
			AND A1_LOJA = F2_LOJA 
			AND A1_CGC <>  ' ' 
			AND A1_COD = F2_CLIENTE
			AND A1_PESSOA = 'F' 
			AND A1_FILIAL = %xFilial:SA1%		
           LEFT JOIN %table:ZFT% ZFT 
			 ON ZFT.D_E_L_E_T_ = ' '
			AND ZFT_COD = B1_ZFT
			AND ZFT_FILIAL = %xFilial:ZFT%			
		   LEFT JOIN %table:Z03% Z03 
			 ON Z03.D_E_L_E_T_ = ' '
			AND Z03_CODIGO = ZFT_PRODUT 
			AND Z03_FILIAL = %xFilial:SZ03%
		   LEFT JOIN %table:SYA% SYA 
			 ON SYA.D_E_L_E_T_ =  ' '
			AND YA_CODGI = Z03_PAIS
			AND YA_FILIAL = %xFilial:SYA%
		  WHERE F2_TIPO = 'N'		  
			AND F2_VALFAT > 0 
			//AND F2_EMISSAO= %Exp:dDataFiltro%	
			AND F2_FILIAL = %xFilial:SF2%
			AND NOT EXISTS (SELECT Z07_CHVINT 
			                  FROM %Table:Z07% Z07 
							 WHERE Z07.D_E_L_E_T_ =  ' ' 
							   AND Z07_ENTIDA = 'SF2' 
							   AND Z07_CHVINT = F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA
							   AND Z07_FILIAL = %xFilial:Z07% )
		  ORDER BY F2_DOC,F2_SERIE,F2_CLIENTE,F2_LOJA,D2_ITEM 
	EndSQL

	Count to nCount

	(cAliasSC5)->(dbGotop())

	If (cAliasSC5)->(Eof())
		_cError += "Não existem registros para a integracao" + CRLF
		return
	EndIf

	//-- Percorre todas as vendas
	While !(cAliasSC5)->(EOF())

		//-- Integra o Cliente da Venda
		lRetCli    := sfAtuCli((cAliasSC5)->RECNOSA1)
		//-- Integra o Produto da Venda
		// Produto é integrado dentro da função sfAtuVenda
		//lRetProd   := sfAtuProd((cAliasSC5)->RECNOSB1,(cAliasSC5)->RECNOZFT )

		//-- Integra a NF de Venda
		lRetVendas := sfAtuVenda((cAliasSC5)->RECNOSF2,(cAliasSC5)->RECNOSA1)

		//-- Verifica se houve erro na integracao
		if !lRetCli
			_cError += "Erro Integracao Cliente " + SA1->A1_COD +" - "+SA1->A1_NREDUZ + "- Retorno:"+ sPostRetCli + CRLF
		endif

		if !lRetProd
			_cError += "Erro Integracao Produto " + SB1->B1_COD +" - "+SB1->B1_DESC + "- Retorno:"+ sPostRetPro + CRLF
		endif

		if !lRetVendas
			_cError += "Erro Integração Vendas NF: " + _cNota + "-" +"do Cliente - " + _cCliente +"- Retorno:"+ sPostRetVen + CRLF
		endif

		(cAliasSC5)->(DbSkip())
	ENDDO

	//-- Forco o fechamento da tabela
	IF Select("cAliasSC5")>0
		(cAliasSC5)->(dbCloseArea())
	EndIf
Return

/*/{Protheus.doc} sfAtuCli
Função para integra os clientes com a QERO 
@type function
@version  
@author marcelo
@since 7/20/2023
@param RECNOSA1, variant, param_description
@return variant, return_description
/*/
Static Function sfAtuCli(nInRecSA1)
	Local lIntegra 	:= .F.
	Local lRet 		:= .T.
	Local cError
	Local nStatus
	Local cBody
	//-- define a rota
	cPath :="/client"

	If !Empty(nInRecSA1)

		//--Posiciono no cliente
		DbSelectArea( "SA1" )
		DbGoto( nInRecSA1 )

		//Verifica se o cliente ja foi integrado
		DbSelectArea("Z07")
		DbSetOrder(1)
		If DbSeek(xFilial("Z07") + "SA1" +  SA1->A1_CGC)
			lIntegra	:=.F.
		Else
			lIntegra	:=.T.
		Endif
		//-- Se nao foi integrado, integra
		if lIntegra
			oJson       := Eval(bObject)
			oJson["secondary_id"] := "55-"+Alltrim(SA1->A1_CGC)
			oJson["name"]         := Alltrim(NoAcento(SA1->A1_NREDUZ))
			If Alltrim(Upper(SA1->A1_EMAIL)) $ "VERA@DECANTER.COM.BR#CLIENTEANTIGO@DECANTER.COM.BR#ENOTECABLUMENAU@DECANTER.COM.BR#INCOMPLETOCLIENTE@DECANTER.COM#ENOTECADECANTER@DECANTER.COM.BR"
				oJson["email"]        := "fake"+Alltrim(SA1->A1_CGC)+"@decanter.com.br"
			Else
				oJson["email"]        := Alltrim(SA1->A1_EMAIL)
			Endif

			oRestClient := FWRest():New(cUrl)
			oRestClient:SetPath(cPath)

			cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
			oRestClient:SetPostParams(EncodeUTF8(cBody, "cp1252"))
			oRestClient:SetChkStatus(.F.)

			ConOut(cBody)
			oRestClient:Post(aHeadOut)
			cError 		:= ""
			nStatus 	:= HTTPGetStatus(@cError)
			sPostRetCli := oRestClient:GetResult()

			ConOut(sPostRetCli)

			If "Email already registered" $ sPostRetCli

				oJson       := Eval(bObject)
				oJson["secondary_id"] := "55-"+Alltrim(SA1->A1_CGC)
				oJson["name"]         := Alltrim(NoAcento(SA1->A1_NREDUZ))
				oJson["email"]        := "fake"+Alltrim(SA1->A1_COD)+Alltrim(SA1->A1_LOJA)+Alltrim(SA1->A1_CGC)+"@decanter.com.br"
				
				oRestClient := FWRest():New(cUrl)
				oRestClient:SetPath(cPath)

				cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
				oRestClient:SetPostParams(EncodeUTF8(cBody, "cp1252"))
				oRestClient:SetChkStatus(.F.)

				ConOut(cBody)
				oRestClient:Post(aHeadOut)
				cError 		:= ""
				nStatus 	:= HTTPGetStatus(@cError)
				sPostRetCli := oRestClient:GetResult()

				ConOut(sPostRetCli)
			Endif
			//-- Verifica se houve erro de comunicacao
			If nStatus <> 200

				lRet := .F.
			Else

				DbSelectArea("Z07")
				RecLock("Z07",.T.)
				Z07->Z07_FILIAL 	:= xFilial("Z07")
				Z07->Z07_ENTIDA		:= "SA1"
				Z07->Z07_CHVINT 	:= SA1->A1_CGC
				Z07->Z07_DTINC		:= Date()
				Z07->Z07_HORA 		:= Time()
				MsUnlock()
			Endif
			FreeObj(oJson)

		Endif
	Endif
Return lRet


//-- Funcao responsavel por integrar os Produtos das vendas ao sistema Qero

//User Function qroProd(RECNOSB1,RECNOZFT,Z03_PAIS)
/*/{Protheus.doc} sfAtuProd
Função para integrar os produtos das vendas ao sistema QERO 
@type function
@version  
@author marcelo
@since 7/21/2023
@param nInRecSB1, numeric, param_description
@param nInRecZFT, numeric, param_description
@return variant, return_description
/*/
Static Function sfAtuProd(nInRecSB1,nInRecZFT)

	Local lIntegra 		:= .F.
	Local lRet 			:= .T.
	Local cError
	Local nStatus
	Local cBody
	//-- define a rota
	cPath :="/product"

	If !Empty(nInRecSB1)

		//-- Posiciono no Produto
		DbSelectArea( "SB1" )
		DbGoto( nInRecSB1 )

		//-- Verifica se o cliente ja foi integrado
		DbSelectArea("Z07")
		DbSetOrder(1)
		If DbSeek(xFilial("Z07") + "SB1" +  SB1->(B1_FILIAL+B1_COD))
			lIntegra	:=.F.
		Else
			lIntegra	:=.T.
		Endif


		//-- Se nao foi integrado, integra
		If lIntegra
			DbSelectArea("ZFT")
			ZFT->(DbGoto(nInRecZFT))
			oJson       := Eval(bObject)
			oJson["name"]             := Alltrim(SB1->B1_DESC)
			oJson["identifier"]       := Alltrim(SB1->B1_COD)
			oJson["manufacturer"]     := Alltrim(SB1->B1_DESC)
			oJson["country"]          := Alltrim((cAliasSC5)->YA_DESCR) // nome do pais
			oJson["composition"]      := Alltrim(SB1->B1_COD)
			oJson["typology"]        := ""	//Iif(!Empty(ZFT->ZFT_SEGMEN),ZFT->ZFT_SEGME,"")
			oJson["classification"]   := ""	//Iif(!Empty(ZFT_DESCCL),ZFT_DESCCL,"")

			oRestClient := FWRest():New(cUrl)
			oRestClient:SetPath(cPath)

			cBody := EncodeUTF8(oJson:ToJson(), "cp1252")
			oRestClient:SetPostParams(EncodeUTF8(cBody, "cp1252"))
			oRestClient:SetChkStatus(.F.)

			ConOut(cBody)
			oRestClient:Post(aHeadOut)

			cError 		:= ""
			nStatus 	:= HTTPGetStatus(@cError)
			sPostRetPro	:= oRestClient:GetResult()
			ConOut(sPostRetPro)
			//-- Verifica se houve erro de integracao
			If nStatus <> 200
				lRet := .F.
			Else
				//--  Marca o produto como integrado
				DbSelectArea("Z07")
				RecLock("Z07",.T.)
				Z07->Z07_FILIAL 	:= xFilial("Z07")
				Z07->Z07_ENTIDA		:= "SB1"
				Z07->Z07_CHVINT 	:= SB1->(B1_FILIAL+B1_COD)
				Z07->Z07_DTINC		:= Date()
				Z07->Z07_HORA 		:= Time()
				MsUnlock()
			Endif
			FreeObj(oJson)
		Endif
	Endif

return lRet


/*/{Protheus.doc} PostSales
	Metodo responsavel por enviar para a Qero as vendas D-1
	@type  Function
	@author user
	@since 06/05/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
Static Function sfAtuVenda(nInRecSF2,nInRecSA1)

	local aItens   	:= {}
	local cPath    	:= "/client/"
	local cRota    	:= ""
	local lIntegra 	:= .F.
	local lRet     	:= .T.
	Local nSumF2 	:= 0
	Local cHash    	:= "0"
	Local n 	  	:= 0
	Local oJsonB   	:= JsonObject():New()
	Local cChvSF2	:= ""

	SF2->(DbSelectArea( "SF2" ))
	SF2->(DbGoto( nInRecSF2 ))

	cChvSF2	:= SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA

	DbSelectArea("Z07")
	DbSetOrder(1)
	If DbSeek(xFilial("Z07") + "SF2" + cChvSF2)
		lIntegra	:=.F.
	Else
		lIntegra	:=.T.
	Endif


	If lIntegra
		//-- Posiciono no cliente
		DbSelectArea( "SA1" )
		DbGoto( nInRecSA1 )
		aItens   	:= {}

		//------------------------------------------------------------------------
		//-- PEGAR O HASH

		//cRotaBalance := "https://qero-cdp.e-goi.com/public-api/client/tele-55-"+SA1->A1_CGC+"/balance"
		cRotaBalance := "/client/tele-55-"+Alltrim(SA1->A1_CGC)+"/balance"
		oRestClient := FWRest():New(cUrl)
		oRestClient:SetPath(cRotaBalance)
		//https://qero-cdp.e-goi.com/public-api/client/tele-55-21981241930/balance

		If oRestClient:Get(aHeadOut)
			//ConOut(oRestClient:GetResult())
			FWJsonDeserialize(oRestClient:CRESULT,@oJsonB)
			cHash := oJsonB:HASH
		Else
			ConOut(oRestClient:GetLastError())
		Endif
		//------------------------------------------------------------------------

		//-- Monta Json da Venda

		oVend := JsonObject():New()
		oResponse := JsonObject():New()
		//cria o array da Venda
		oResponse["venda"]     := {}

		//cria o cabecalho do pedido
		//oVend["secondary_id"]  := "55-"+SA1->A1_CGC
		oVend["secondary_id"]  	:= SF2->F2_FILIAL+ Alltrim(SF2->F2_SERIE) + Alltrim(SF2->F2_DOC)
		//oVend["referral"]     := SF2->F2_DOC
		oVend["type"]          	:= "BUY"

		_cDate:= FWTimeStamp(3)
		oVend["external_date"] := StrTran(_cDate,"T"," ")

		oVend["identity_name"] := xFilial("SF2")
		oVend["credit_out"]    := 0
		oVend["hash"]          := cHash

		nSumF2	:= 0
		// Faz o loop nos itens da nota
		While !(cAliasSC5)->(EOF()) .And. (cAliasSC5)->F2_FILIAL+(cAliasSC5)->F2_DOC+(cAliasSC5)->F2_SERIE+(cAliasSC5)->F2_CLIENTE+(cAliasSC5)->F2_LOJA == cChvSF2

			//-- Integra o Produto da Venda
			aAreaRet 	:= (cAliasSC5)->(GetArea())
			sfAtuProd((cAliasSC5)->RECNOSB1,(cAliasSC5)->RECNOZFT )

			RestArea(aAreaRet)

			Aadd(aItens, JsonObject():New())
			//cria o "amount"
			oAmount := JsonObject():New()
			n++
			//aItens[n]["id"] 			:= Alltrim((cAliasSC5)->D2_COD) + ";\u001b;" + Alltrim(Posicione("SB1",1,xFilial("SB1") + ALLTRIM((cAliasSC5)->D2_COD),"B1_DESC"))
			aItens[n]["id"] 			:= Alltrim(Posicione("SB1",1,xFilial("SB1") + ALLTRIM((cAliasSC5)->D2_COD),"B1_DESC")) +  ";\u001b;" + Alltrim((cAliasSC5)->D2_COD)
			aItens[n]["separator"] 		:= ";\u001b;"
			aItens[n]["quantity"]  		:= (cAliasSC5)->D2_QUANT
			aItens[n]["promotion"] 		:= 0
			aItens[n]["iva"] 			:= 0
			aItens[n]["description"] 	:= "inteiro"

			oAmount["gross"]      		:= ((cAliasSC5)->D2_PRCVEN * 100 )
			oAmount["net"]        		:= ((cAliasSC5)->D2_PRCVEN * 100 )
			nSumF2 += (cAliasSC5)->D2_VALBRUT
			aItens[n]['amount_unit'] 	:= oAmount

			DbSelectArea(cAliasSC5)
			(cAliasSC5)->(dbSkip()) //Próximo registro
		EndDo

		oVend["amount_gross"]  := nSumF2 * 100 //(SF2->F2_VALBRUT * 100)
		oVend["amount_net"]    := nSumF2 * 100 //(SF2->F2_VALBRUT * 100)

		oVend["products"] 		:=  aItens


		//https://qero-cdp.e-goi.com/public-api/client/tele-55-21981241930/movement

		cRota := "tele-55-"+Alltrim(SA1->A1_CGC)+"/movement"
		oRestClient := FWRest():New(cUrl)
		oRestClient:SetPath(cPath+cRota)


		cBody := EncodeUTF8(oVend:ToJson(), "cp1252")
		oRestClient:SetPostParams(EncodeUTF8(cBody, "cp1252"))
		oRestClient:SetChkStatus(.F.)

		ConOut(cBody)
		oRestClient:Post(aHeadOut)

		cError := ""
		nStatus := HTTPGetStatus(@cError)
		sPostRetVen := oRestClient:GetResult()
		ConOut(sPostRetVen)
		//-- Verifica se houve erro de integracao
		If nStatus <> 200
			lRet 		:= .F.
			_cCliente 	:=  SF2->F2_CLIENTE
			_cNota	  	:=  SF2->F2_DOC
		Else
			//--  Marca a nota como integrado
			lRet 		:= .T.
			DbSelectArea("Z07")
			RecLock("Z07",.T.)
			Z07->Z07_FILIAL 	:= xFilial("Z07")
			Z07->Z07_ENTIDA		:= "SF2"
			Z07->Z07_CHVINT 	:= cChvSF2
			Z07->Z07_DTINC		:= Date()
			Z07->Z07_HORA 		:= Time()
			MsUnlock()
		Endif

	Endif

	FreeObj(oJsonB)


//Retorno o lRet, de acordo com o sucesso na busca do pedido de venda
Return lRet



/*/{Protheus.doc} SchedDef
Função para permitir rotina via schedule 
@type function
@version  
@author marcelo
@since 7/21/2023
@return variant, return_description
/*/
Static Function SchedDef()
	// aReturn[1] - Tipo
	// aReturn[2] - Pergunte
	// aReturn[3] - Alias
	// aReturn[4] - Array de ordem
	// aReturn[5] - Titulo

Return { "P", "DEFATI01", "", {}, "" }



/*/{Protheus.doc} sfPutUsrLock
Grava usurio que est com lock no arquivo
@author charles.reitz
@since 31/08/2017
@version undefined
@param cLockName, characters, descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function sfPutUsrLock(cLockName)

	//aInfoUsr := PswRet()
	If File("\semaforo\"+cLockName+".lck")
		FERASE("\semaforo\"+cLockName+".lck")
	EndIf
	nHandle := FCREATE("\semaforo\"+cLockName+".lck", 0)
	If nHandle <> -1
		fopen("\semaforo\"+cLockName+".lck",64)
		FWrite(nHandle,cUserName, 25) // Insere texto no arquivo
		fclose(nHandle) // Fecha arquivo
	EndIf
Return


/*/{Protheus.doc} sfGetUsrLock
Pega o usurio que est com lock e apresenta
@type function
@version  
@author marcelo
@since 7/21/2023
@param cLockName, character, param_description
@return variant, return_description
/*/
Static Function sfGetUsrLock(cLockName)

	Local cUsuArq	:=	""

	nHandle := fopen("\semaforo\"+cLockName+".lck", 64 )
	If nHandle <> -1
		FRead( snHandle, cUsuArq, 25 )
		fclose(nHandle) // Fecha arquivo
	EndIf
	MsgInfo("Rotina est"+chr(65533)+" sendo utilizada pelo usuário "+cUsuArq,"Atenção - "+FunName())

Return


/*/{Protheus.doc} sfDelUsrLock
Deleta o controle de semafaro
@author charles.reitz
@since 31/08/2017
@version undefined
@param cLockName, characters, descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function sfDelUsrLock(cLockName)

	Local cUsuArq	:=	""

	nHandle := fopen("\semaforo\"+cLockName+".lck", 64 )

	If nHandle <> -1
		FRead( nHandle, cUsuArq, 25 )
		fclose(nHandle) // Fecha arquivo
		If Alltrim(cUsuArq) == Alltrim(cUserName)
			FERASE("\semaforo\"+cLockName+".lck")
		EndIf
	Endif
Return

