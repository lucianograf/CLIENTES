#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"


/*/{Protheus.doc} RestUsr
//TODO Rotina para integração de Vendedores - Ajili x Protheus
@author Marcelo Alberto Lauschner
@since 19/02/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User function RestUsr()

	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	cInCodLj	:= ""
	Private lDebug		:= .F. 

	sfListUsr()


	If GetNewPar("GF_AJILIOK",.T.) .And. MsgYesNo("Deseja rodar integração de Vendedores?")
		// Função para só para criar os parametros por filial quando necessário implementar
		// é necessário acessar o portal para criar a ApiKey 
		sfAjustSX6()

		While !lRet


			If lRet	:= LockByName("RESTUSR_"+cFilAnt,.T.,.T.)

				Conout("***[Inicio RESTUSR_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]************************************************************************")

				Processa({|| sfRodaUsr() },"Processando usuários...")		

				UnLockByName("RESTUSR_"+cFilAnt,.T.,.T.)

				Conout("***[Fim RESTUSR_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]****************************************************************************")

			Else

				MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Exportação usuários já em execução!")

				nWaitSec ++ 

				Conout("*****[Job RESTUSR ja esta em execucao]***********************************************")

				// Havendo mais de 10 tentativas de espera por 1 segundos cada, aborta o processo 
				If nWaitSec  >= 10 
					lRet	:= .T.
					Exit
				Endif						
			Endif
		Enddo
	Endif

Return


/*/{Protheus.doc} sfAjustSX6
//TODO Função para criação de parâmetros de uso da Rotina. Facilitar a criação de novas empresas. 
@author Marcelo Alberto Lauschner 
@since 19/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfAjustSX6()

	Local	aAreaOld	:= GetArea()

	DbSelectARea("SX6")
	DbSetOrder(1)
	If !DbSeek(cFilAnt+"GF_AJ_URL")
		RecLock("SX6",.T.)
		SX6->X6_FIL     	:= cFilAnt 
		SX6->X6_VAR     	:= "GF_AJ_URL"
		SX6->X6_TIPO    	:= "C"
		SX6->X6_DESCRIC 	:= "Integração Ajili x Protheus"
		SX6->X6_DESC1		:= "URL de Conexão da Filial"
		SX6->X6_DESC2		:= ""
		MsUnLock()

		If cFilAnt == "0101" // Forta Eqt
			PutMv("GF_AJ_URL","http://condor.ajili.com.br")
		ElseIf cFilAnt == "0201" // Forta FTA 
			PutMv("GF_AJ_URL","http://condor1.ajili.com.br")
		ElseIf cFilAnt == "0301" // Forta IMP
			PutMv("GF_AJ_URL","http://condor3.ajili.com.br")
		ElseIf cFilAnt == "0401" // Condor
			PutMv("GF_AJ_URL","http://condor2.ajili.com.br")
		ElseIf cFilAnt == "0601" // Bauem
			PutMv("GF_AJ_URL","https://baume.ajili.com.br")
		Endif
		



	EndIf

	If !DbSeek(cFilAnt+"GF_AJ_KEY")
		RecLock("SX6",.T.)
		SX6->X6_FIL     	:= cFilAnt 
		SX6->X6_VAR     	:= "GF_AJ_KEY"
		SX6->X6_TIPO    	:= "C"
		SX6->X6_DESCRIC 	:= "Integração Ajili x Protheus"
		SX6->X6_DESC1		:= "Api Key para integração"
		SX6->X6_DESC2		:= ""
		MsUnLock()
		If cFilAnt == "0101"
			PutMv("GF_AJ_KEY","$2a$10$woZDXrsKk0pgCrhBvz1kLeh1Dh1kCiw179nTtu/P.I/o0nEQnQ4YS")
		ElseIf cFilAnt == "0201"
			PutMv("GF_AJ_KEY","")
		ElseIf cFilAnt == "0301"
			PutMv("GF_AJ_KEY","$2a$10$QlBhPku9AGNpoMLi3paMJ.fe7KxH12p8RQ7ew8Ly.B3OaGStGyb3O")
		ElseIf cFilAnt == "0401"
			PutMv("GF_AJ_KEY","")
		ElseIf cFilAnt == "0601"
			PutMv("GF_AJ_KEY","$2a$10$aIRm.fANgW5dus5XjV8XieJjIyLS3SX5hxwp2/EetJIEcdH.N5te.")			
		Endif
	EndIf

Return 


/*/{Protheus.doc} sfRodaUsr
//TODO Rotina para geração dos dados da integração. Cria o Json e integra 
@author Marcelo Alberto Lauschner 
@since 19/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfRodaUsr()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/users?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	Local 	aHeader         := {}
	Local 	aHeadOut        := {}
	Local 	cHeaderGet      := ""
	Local 	xRet
	Local 	cMsg	 		:= ""
	Local 	cJsonCon		:= ""
	Local 	nTypeStamp		:= 4					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
	Local	cQry 	
	Local	nIdAjili		:= 0

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cQry := "SELECT A3_FILIAL, A3_EMAIL,A3_COD,CASE WHEN A3_ZAGRUP <> ' ' THEN A3_ZAGRUP ELSE A3_COD END A3_ZAGRUP,"
	cQry += "       A3_NOME,A3_DDDTEL,A3_TEL,A3_COMIS,A3_GEREN,"
	cQry += "       A3.R_E_C_N_O_ AS A3RECNO,COALESCE(Z00_IDAJIL,-1) IDAJILI "
	cQry += "  FROM " + RetSqlName("SA3") + " A3 "
	cQry += "  LEFT JOIN " + RetSqlName("Z00") + " Z00 " 
	cQry += "    ON Z00.D_E_L_E_T_ =' ' " 
	cQry += "   AND Z00_FILIAL = '" + xFilial("Z00") + "'" 
	cQry += "   AND Z00_ENTIDA = 'SA3' " 
	cQry += "   AND Z00_CHAVE = (A3_FILIAL+A3_ZAGRUP)" 
	cQry += " WHERE A3.D_E_L_E_T_ =' ' " 
	cQry += "   AND A3_FILIAL = '" + xFilial("SA3") + "' "
	cQry += "   AND A3_HAND = '1' " // ALTEREI
	cQry += U_MLFATG05(3) // Monta filtro SQL de intervalo de vendedores 
	cQry += "   AND COALESCE(Z00_IDAJIL,-1) < 0 " // Filtra só que não integrou 
	cQry += " ORDER BY A3_COD"
	
	MemoWrit("c:\edi\getusr_qry_"+cFilAnt+".txt", cQry)

	TcQuery cQry New Alias "QSA3"
	If Eof()
		MsgAlert(cQry,"Sem dados")
	Endif 
	While QSA3->(!Eof())  

		If !Empty(QSA3->A3_GEREN)
			dbSelectArea("QSA3")
			dbSkip()
			Loop
		Endif

		nIdAjili		:= 0

		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA3" + QSA3->(A3_FILIAL+A3_ZAGRUP))
			nIdAjili		:= Z00->Z00_IDAJIL
		Endif

		JsonUsr := sfMontaJson(nIdAjili)
		Conout("***[RESTUSR]*[Json criado]********************************************************************************")
		Conout(JsonUsr)

		Conout("***[RESTUSR]*[Vai enviar via HTTP Post o Json]*************************************************************")

		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(JsonUsr),200,aHeader,@cHeaderGet)
		Conout("***[RESTUSR]*[Enviou via HTTP Post o Json]*****************************************************************")

		Conout("***[RESTUSR]***********************************************************************************************")
		Conout(cRetorno)
		MsgAlert(cRetorno , QSA3->(A3_FILIAL+A3_ZAGRUP))
		wrk := JsonObject():new()
		wrk:fromJson(cRetorno)

		cRet := wrk:GetJsonText("id")

		ConOut("***[RESTUSR]*["+cRet+"]***********************************************************************************************************")   

		nSA3IdAjili := Val(cRet)

		Conout("***[RESTUSR]*[Id Ajili: "+Str(nSA3IdAjili,11,0)+"]**********************************************************************************************")

		Conout(cHeaderGet)

		_cStatus := Substr(cHeaderGet,10,3)

		Conout("Status da Inclusao: "+_cStatus)

		Conout("***[RESTUSR]**********************************************************************************************")

		If _cStatus $ "200" .And. nSA3IdAjili > 0 // Inclusão / Alteração / Reativação 
			Conout("***[RESTUSR]*[Cadastrado com Sucesso!]*****************************************************************")
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA3" + QSA3->(A3_FILIAL+A3_ZAGRUP))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA3"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= QSA3->(A3_FILIAL+A3_ZAGRUP)	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA3IdAjili		//- Id de Integração Ajili
			MsUnlock()

		ElseIf _cStatus $ "500"  // Inclusão / Alteração / Reativação 

			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA3" + QSA3->(A3_FILIAL+A3_ZAGRUP))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA3"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= QSA3->(A3_FILIAL+A3_ZAGRUP)	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "E"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA3IdAjili		//- Id de Integração Ajili
			MsUnlock()
			MsgAlert("Status " + _cStatus + " para vendedor " + QSA3->A3_COD + " Retorno " + cRetorno)
		Else
			MsgAlert("Status " + _cStatus + " para vendedor " + QSA3->A3_COD + " Retorno " + cRetorno)
		EndIf    
		Conout("***[RESTUSR]**********************************************************************************************")

		dbSelectArea("QSA3")
		dbSkip()
	Enddo

	dbSelectArea("QSA3")
	dbGoTop()

	While QSA3->(!Eof()) 

		If Empty(QSA3->A3_GEREN)
			dbSelectArea("QSA3")
			dbSkip()
			Loop
		Endif

		nIdAjili		:= 0

		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA3" + QSA3->(A3_FILIAL+A3_ZAGRUP))
			nIdAjili		:= Z00->Z00_IDAJIL
		Endif

		JsonUsr := sfMontaJson(nIdAjili)

		Conout("***[RESTUSR]*[Json criado]********************************************************************************")
		Conout(JsonUsr)

		Conout("***[RESTUSR]*[Vai enviar via HTTP Post o Json]*************************************************************")

		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(JsonUsr),200,aHeader,@cHeaderGet)

		Conout("***[RESTUSR]*[Enviou via HTTP Post o Json]*****************************************************************")

		Conout("***[RESTUSR]***********************************************************************************************")
		Conout(cRetorno)

		wrk := JsonObject():new()
		wrk:fromJson(cRetorno)

		cRet := wrk:GetJsonText("id")

		ConOut("***[RESTUSR]*["+cRet+"]***********************************************************************************************************")   

		nSA3IdAjili := Val(cRet)

		Conout("***[RESTUSR]*[Id Ajili: "+Str(nSA3IdAjili,11,0)+"]**********************************************************************************************")

		Conout(cHeaderGet)

		_cStatus := Substr(cHeaderGet,10,3)

		Conout("Status da Inclusao: "+_cStatus)

		Conout("***[RESTUSR]**********************************************************************************************")

		If _cStatus $ "200" .And. nSA3IdAjili > 0// Inclusão / Alteração / Reativação 
			Conout("***[RESTUSR]*[Cadastrado com Sucesso!]*****************************************************************")

			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA3" + QSA3->(A3_FILIAL+A3_ZAGRUP))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA3"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= QSA3->(A3_FILIAL+A3_ZAGRUP)	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA3IdAjili		//- Id de Integração Ajili
			MsUnlock()
		ElseIf _cStatus $ "500" .And. nSA3IdAjili > 0 // Inclusão / Alteração / Reativação 

			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA3" + QSA3->(A3_FILIAL+A3_ZAGRUP))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA3"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= QSA3->(A3_FILIAL+A3_ZAGRUP)	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "E"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA3IdAjili		//- Id de Integração Ajili
			MsUnlock()
			MsgAlert("Status " + _cStatus + " para vendedor " + QSA3->A3_COD + " Retorno " + cRetorno)

		Else
			MsgAlert("Status " + _cStatus + " para vendedor " + QSA3->A3_ZAGRUP )
		EndIf    
		Conout("***[RESTUSR]**********************************************************************************************")

		dbSelectArea("QSA3")
		dbSkip()
	Enddo
	QSA3->(DbCloseArea())

Return


Static Function sfMontaJson(nIdAjili)

	Local cJsonUsr			 := ""
	Local nTypeStamp		 := 4					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
	Local cTimeStAtual 		 := FWTimeStamp(nTypeStamp,Date(),Time()) 
	Local cCodVend           := 0
	Local nVendGer           := 3
	Local cCodGerente        := QSA3->A3_GEREN
	Local nGerente           := 0

	If Empty(QSA3->A3_GEREN)
		nVendGer := 2
	Else
		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA3" + QSA3->(A3_FILIAL+A3_GEREN))
			nGerente		:= Z00->Z00_IDAJIL
		Endif
	EndIf

	Conout("***[RESTUSR]*[Entrou na Rotina de Monta Json]*******************************************************************")

	JsonUsr := '{'
	JsonUsr += '"active": true,'
	//JsonUsr += '"addressId": 0,'
	//JsonUsr += '"balanceFlex": 0,'
	//JsonUsr += '"bankAccount": "string",'
	//JsonUsr += '"bankAgency": "string",'
	//JsonUsr += '"bankNumber": "string",'
	JsonUsr += '"email": "'+AllTrim(QSA3->A3_EMAIL)+'",'
	If !Empty(nIdAjili)
		JsonUsr += '"id": '+Str(nIdAjili)+','
	EndIF
	JsonUsr += '"idErp": "'+AllTrim(QSA3->A3_ZAGRUP)+'",'
	JsonUsr += '"name": "'+Alltrim(QSA3->A3_ZAGRUP) +"-"+AllTrim(QSA3->A3_NOME)+'",'
	JsonUsr += '"phone": "'+AllTrim(QSA3->A3_DDDTEL)+"-"+AllTrim(QSA3->A3_TEL)+'",'
	JsonUsr += '"role": '+Alltrim(Str(nVendGer))+','
	//JsonUsr += '"salaryCosts": 0,'
	If nGerente<>0
		JsonUsr += '"salesComissionPct": '+STR(QSA3->A3_COMIS,5,2)+','
		JsonUsr += '"superiorId": '+STR(nGerente,11,0)+''
	Else
		JsonUsr += '"salesComissionPct": '+STR(QSA3->A3_COMIS,5,2)+' '
	EndIf
	JsonUsr += '}'

	Conout("***[RESTUSR]*[Montou o Json de Usuarios]***********************************************************************")

Return JsonUsr



/*/{Protheus.doc} sfListUsr
// Efetua a leitura de Usuários no Ajili para sincronizar com os dados no Protheus 
@author Marcelo Alberto Lauschner 
@since 18/05/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfListUsr()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/users?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))

	Local 	aHeader         := {}
	Local 	cHeaderGet      := ""
	Local 	nTimeOut 		:= 120
	Local 	cGetParms       := ""
	Local 	iD1

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cRetorno := HttpGet( cUrl+cAcesso+cApiKey , cGetParms, nTimeOut, aHeader, @cHeaderGet )

	MemoWrit("c:\edi\getusr_"+cFilAnt+".txt", cUrl+cAcesso+cApiKey + "-" + cRetorno)

	oJson 		:= tJsonParser():New()
	nRetParser	:= 0
	strJson 	:= cRetorno
	lenStrJson 	:= Len(cRetorno)
	jsonfields	:= {}
	lRet := oJson:Json_Parser(strJson, lenStrJson, @jsonfields, @nRetParser)

	If ( lRet == .F. )
		msgAlert("##### [JSON][ERR] " + "Parser 1 com erro" + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		msgAlert("Erro a partir: " + SubStr(strJson, (nRetParser+1)))
	Else
		//		msgAlert("[JSON] "+ "+++++ PARSER 1 OK num campos: " + AllTrim(Str(Len(jsonfields))) + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		//		printJson(jsonfields, "| ")
	EndIf
	ConOut("-------------------------------------------------------", "")

	For iD1 := 1 To Len(jsonfields[1])
		aVetIdVend		:= sfGetVal (jsonfields[1],"#_OBJECT_#","",iD1)
		cIdErp		:= sfGetVal (aVetIdVend,"idErp","")
		
		If !Empty(cIdErp)
			
			nSA3IdAjili	:= sfGetVal(aVetIdVend,"id","")
			
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA3" + xFilial("SA3") + cIdErp )
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)
			Endif

			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA3"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= xFilial("SA3") + cIdErp	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA3IdAjili		//- Id de Integração Ajili
			MsUnlock()
		Endif
	Next

Return 



Static Function sfGetVal (aJson, cTag,cTag2,nPosIni)

	Local xRet 		:= ''
	Local nPos	 	:= 0
	Default	nPosIni	:= 1

	For nPos := nPosIni To Len(aJson)
		If ValType(aJson[nPos][1]) == "C" .And. aJson[nPos][1] == cTag
			// Verifica se procura pelo nome do Ojecto anterior 
			If !Empty(cTag2) 
				If cTag2 == aJson[nPos-1][1]
					xRet	:= aJson[nPos][2]
				Endif
			Else
				xRet	:= aJson[nPos][2]
				Exit // Sai na primeira iteração
			Endif
		Endif
	Next

Return xRet

/*/{Protheus.doc} SchedDef
//TODO Função para Agendamento no Schedule 
@author Marcelo Alberto Lauschner
@since 19/02/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function SchedDef()

	Local	aOrd	:= {}
	Local	aParam	:= {}

	Aadd(aParam,"P")
	Aadd(aParam,"PARAMDEF")
	Aadd(aParam,"")
	Aadd(aParam,aOrd)
	Aadd(aParam,)	

Return aParam
