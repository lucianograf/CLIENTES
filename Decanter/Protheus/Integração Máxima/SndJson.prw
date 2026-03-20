#Include "aarray.ch"
#Include "json.ch"
#Include "shash.ch"

User Function SndJson(aDados, cVerbo, cEndPoint, CPATH,CDADOS)
	Local cJson := ""
	Local aaJson := Array(#)
	Local _I := 0
	Local _J := 0
	Local cField := Nil
	Local cDado := Nil
	Local oObj := Nil
	Local cUrl := ""
	Local cToken := ""
	Local oRestClient := Nil
	Local aHeadOut := {}
	Local lTryAgain := .T.
	Local nTry := 0
	Local cRet := ""
	Local lRet := .F.
	
	If ValType(cDados) == "U" .AND. Len(aDados) <= 0
		Return
	EndIf
    
	IF CVERBO == "GET"
		cUrl := SuperGetMv("XX_MAXGET",.f.,"")
	ELSE              
		IF CVERBO == "PUT"
			cUrl := SuperGetMv("XX_MAXGET",.f.,"")//cUrl := "http://intpdvv.solucoesmaxima.com.br:8081/api/v1/"
		ELSE
			cUrl := SuperGetMv("XX_MAXURL",.f.,"")
		ENDIF
	ENDIF
	
	//cUrl := GetNewPar("XX_MAXURL","http://c0505ee7.ngrok.io")
	cToken := U_MaxAuth()
	oRestClient := FWRest():New(cUrl)
	
	If Len(AllTrim(cToken)) <= 0
		ConOut("Não autenticado...")
		Return(cJson)
	EndIf
	
	IF CVERBO == "GET" .OR. CVERBO == "DELETE"
		CDADOS := ""
	ENDIF
	
	If ValType(cDados) == "U"
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
	Else
		cJson := cDados
	EndIf
	
//	IF cEndPoint == "RetornoStatus"
//	   CJSON :=	STRTRAN(cJson,'"ITENS":"[{\"CODIGO\":0,\"DESCRICAO\":\"Pedido Importado com Sucesso\",\"ORDEM\":0}]"','"ITENS":[{"CODIGO":0,"DESCRICAO":"Pedido Importado com Sucesso","ORDEM":0}]')   
//	ENDIF
	
	oRestClient:nTimeOut := 120
	//oRestClient:setPath("/"+AllTrim(cEndPoint))
	//oRestClient:setPath(SuperGetMv("XX_MAXVER",.f.,'')+"/"+ALLTRIM(CPATH)+"/")//"/Login/")
	oRestClient:setPath(ALLTRIM(CPATH)+"/")//"/Login/")
		
	If cVerbo == "POST" //.OR. CVERBO == "PUT"
		oRestClient:SetPostParams("body")
		oRestClient:SetPostParams(cJson)
	EndIf
	
	//TRATAR QUESTÃO DA GERAÇÃO DO JSON OU NÃO - CRIAR UM PARAMETRO - AINDA VAMOS VER SE PRECISA FAZER ISSO
	//IF FUNNAME
	Memowrite("C:\temp\json-"+ALLTRIM(cEndPoint)+"-"+STRTRAN(TIME(),":","-")+".txt", cJson)
	
	While lTryAgain .AND. nTry <= 3
		nTry++
		lTryAgain := .F.
		aHeadOut := {}
		ConOut("Tentativa "+StrZero(nTry,1))
		aadd(aHeadOut,'Authorization: Bearer '+cToken)
		aadd(aHeadOut,'Content-Type: application/json')
		
		If cVerbo == "POST"
			lRet := oRestClient:Post(aHeadOut)
		ElseIf cVerbo == "PUT"
			lRet := oRestClient:Put(aHeadOut, cJson)
		ElseIf cVerbo == "DELETE"
			lRet := oRestClient:Delete(aHeadOut, cJson)
		ElseIf cVerbo == "GET"
			lRet := oRestClient:GET(aHeadOut)			
		EndIf

		If lRet
			cRet := oRestClient:GetResult()
//			MSGINFO(oRestClient:GetResult())
			//ALERT("OK")
			ConOut(oRestClient:GetResult())
			MemoWrite("C:\temp\ok-"+ALLTRIM(cEndPoint)+"-"+STRTRAN(TIME(),":","-")+".txt",oRestClient:GetResult())
		Else
			Conout("Erro")
			cRet := oRestClient:GetLastError()
//			MSGINFO(oRestClient:GetLastError())
//			MSGINFO(oRestClient:GetResult())
			conout(oRestClient:GetLastError())
			conout(oRestClient:GetResult())  
			IF ALLTRIM(cRet) != "Unauthorized"
				MemoWrite("C:\temp\erro-"+ALLTRIM(cEndPoint)+"-"+STRTRAN(TIME(),":","-")+".txt",CRET)//oRestClient:GetResult())
			ELSE
				MemoWrite("C:\temp\erro-"+ALLTRIM(cEndPoint)+"-"+STRTRAN(TIME(),":","-")+".txt",CRET)	
			ENDIF                 
			
			If "UNAUTHORIZED" $ Upper(AllTrim(oRestClient:GetLastError())) .OR. "UNAUTHORIZED" $ Upper(AllTrim(oRestClient:GetResult()))
				cToken := U_MaxAuth(.T.)
				lTryAgain := .T.
			EndIf
		EndIf
	EndDo

Return(cRet)
