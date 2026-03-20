#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"

/*/{Protheus.doc} RestCli
//TODO Rotina que gera exportação de dados do cliente
@author Edson / Marcelo Alberto Lauschner
@since 11/12/2019
@version 1.0 
@return ${return}, ${return_description}
@param cInCodLj, characters, descricao
@type function
/*/
User Function RestCli(aParam,cInCodLj)

	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	aParam		:= {}
	Default	cInCodLj	:= ""
	Private lDebug		:= .F.

	/// Mensagem de saída no Consol
	ConOut("+"+Replicate("-",50)+"+")
	ConOut("|"+Padr(ProcName(1)+"." + ProcName(0) + "-" + Alltrim(Str(ProcLine(0))) + DTOC(Date()) + " " + Time(),50) +"|")
	ConOut("|"+Padr("Empresa Logada: " + cEmpAnt,50)+"|")
	ConOut("|"+Padr("Filial Logada : " + cFilAnt,50)+"|")
	//VarInfo("|Valores passados via aParam",aParam)
	ConOut("+"+Replicate("-",50)+"+")

	If GetNewPar("GF_AJILIOK",.T.)

		// Chama função que procura por clientes sem Id ERP
		If Empty(cInCodLj)
			sfNoIdErp()
		Endif

		While !lRet

			If lRet	:= LockByName("RESTCLI_"+cFilAnt+Alltrim(cInCodLj),.T.,.T.)

				Conout("***[Inicio RESTCLI_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]************************************************************************")

				Processa({|| sfRodaCli(cInCodLj) },"Processando clientes...")

				UnLockByName("RESTCLI_"+cFilAnt+Alltrim(cInCodLj),.T.,.T.)

				Conout("***[Fim RESTCLI_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]****************************************************************************")

			Else
				MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Exportação Clientes já em execução!")
				nWaitSec ++
				Conout("*****[Job RESTCLI ja esta em execucao]***********************************************")
				// Havendo mais de 10 tentativas de espera por 1 segundos cada, aborta o processo
				If nWaitSec  >= 10
					lRet	:= .T.
					Exit
				Endif
			Endif
		Enddo
	Endif
Return


/*/{Protheus.doc} SchedDef
//TODO Função que permite agendar a rotina no Schedule do Protheus
@author Marcelo Alberto Lauschner
@since 21/02/2020
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


Static Function sfRodaCli(cInCodLj)

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/customers?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	local 	aHeader            := {}
	local 	cHeaderGet         := ""
	Local nSA1IdAjili        := 0
	local wrk
	Local nRecAtu			:= 0

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cQry := "SELECT A1.R_E_C_N_O_ AS A1RECNO,A3.R_E_C_N_O_ AS A3RECNO,A1_FILIAL,A1_COD,A1_LOJA,COALESCE(Z00_IDAJIL,-1) IDAJILI "
	cQry += "  FROM " + RetSqlName("SA1") + " A1 "
	cQry += "  LEFT JOIN " + RetSqlName("Z00") + " Z00 "
	cQry += "    ON Z00.D_E_L_E_T_ =' ' "
	cQry += "   AND Z00_FILIAL = '" + xFilial("Z00") + "'"
	cQry += "   AND Z00_ENTIDA = 'SA1' "
	cQry += "   AND Z00_CHAVE = (A1_FILIAL+A1_COD+A1_LOJA)"
	cQry += " INNER JOIN " + RetSqlName("SA3") + " A3 "
	cQry += "    ON A3.D_E_L_E_T_ =' ' "

	// Verifica se deve buscar o campo de vendedor específico
	If SA1->(FieldPos(U_MLFATG05(1))) > 0
		cQry += "   AND "+ U_MLFATG05(1) + " = A3_COD "
	Else
		cQry += "   AND A1_VEND = A3_COD "
	Endif
	cQry += "   AND A3_FILIAL = '" + xFilial("SA3") + "'"
	cQry += U_MLFATG05(3) // Monta filtro SQL de intervalo de vendedores

	// Linka com o código agrupador do vendedor para verificar se o mesmo exporta para o Ajili
	cQry += " INNER JOIN " + RetSqlName("SA3") + " A3B "
	cQry += "    ON A3B.D_E_L_E_T_ =' ' "
	cQry += "   AND A3B.A3_COD = A3.A3_ZAGRUP "
	cQry += "   AND A3B.A3_HAND = '1' " // ALTEREI
	cQry += "   AND A3B.A3_FILIAL = '" + xFilial("SA3") + "'"

	cQry += " WHERE A1.D_E_L_E_T_ =' ' "
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "'"
	cQry += "   AND A1_CGC NOT IN(' ') "
	If !Empty(cInCodLj)
		cQry += "   AND (A1_COD+A1_LOJA) = '" + cInCodLj + "'"
	Else
		cQry += "  AND ( A1_MSEXP = ' ' OR COALESCE(Z00_IDAJIL,0) = 0 )" // Só leva clientes novos ou que foram alterados
	Endif
	cQry += " ORDER BY A1_COD,A1_LOJA"

	TcQuery cQry New Alias "QSA1"

	Count To nRec

	ProcRegua(nRec)

	QSA1->(DbGotop())

	If lDebug .And. !Empty(cInCodLj)
		If Eof()
			MsgInfo("Consulta sem dados " + cQry,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Endif
	Endif

	While QSA1->(!Eof())
		nRecAtu ++
		nIdAjili		:= 0
		IncProc("Registro " + cValToChar(nRecAtu) + " de " + cValToChar(nRec)  )
		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA1" + QSA1->(A1_FILIAL+A1_COD+A1_LOJA))
			nIdAjili		:= Z00->Z00_IDAJIL

			If Z00->Z00_INTEGR == "E"
				dbSelectArea("QSA1")
				dbSkip()
				Loop
			Endif
		Endif

		// Posiciona no cadastro de clientes
		DbSelectArea("SA1")
		DbGoto(QSA1->A1RECNO)

		JsonCli := sfMontaJson(nIdAjili)

		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(JsonCli),200,aHeader,@cHeaderGet)
		If lDebug
			MsgInfo(cRetorno,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			MemoWrit("c:\edi\restcli"+ QSA1->(A1_FILIAL+A1_COD+A1_LOJA)+".txt", "query: " + cQry + " conexão: " + cUrl+cAcesso+cApiKey + " | cheaderget : " +cHeaderGet + " | JsonCli: " + JsonCli + " | Retorno: " + cRetorno)
		Endif

		wrk := JsonObject():new()
		wrk:fromJson(cRetorno)

		cRet := wrk:GetJsonText("id")

		cRetorno := DecodeUtf8(cRetorno)

		nSA1IdAjili := Val(cRet)

		_cStatus := Substr(cHeaderGet,10,3)

		If lDebug
			MsgAlert("Status " + _cStatus + " para cliente " + QSA1->A1_COD + " Retorno: "+ cRetorno + " HeaderGet "+cHeaderGet)
		Endif

		If _cStatus $ "200" .And. nSA1IdAjili > 0 // Inclusão / Alteração / Reativação
			Conout("***[RESTUSR]*[Cadastrado com Sucesso!]*****************************************************************")
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA1" + QSA1->(A1_FILIAL+A1_COD+A1_LOJA))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
			Z00->Z00_CHAVE  	:= QSA1->(A1_FILIAL+A1_COD+A1_LOJA)	//- Chave de pesquisa/relação
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA1IdAjili		//- Id de Integração Ajili
			Z00->Z00_MSEXP		:= DTOS(Date())
			MsUnlock()

			// Gravo flag da data de exportação
			DbSelectArea("SA1")
			RecLock("SA1",.F.)
			SA1->A1_MSEXP	:= DTOS(Date())
			MsUnlock()

		ElseIf _cStatus == "500"
			MsgAlert("Status " + _cStatus + " para cliente " + QSA1->A1_COD + " Retorno: "+ cRetorno + " HeaderGet "+cHeaderGet)
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA1" + QSA1->(A1_FILIAL+A1_COD+A1_LOJA))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)
			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
			Z00->Z00_CHAVE  	:= QSA1->(A1_FILIAL+A1_COD+A1_LOJA)	//- Chave de pesquisa/relação
			Z00->Z00_INTEGR 	:= "E"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA1IdAjili		//- Id de Integração Ajili
			Z00->Z00_MSEXP		:= DTOS(Date())
			MsUnlock()

			// Gravo flag da data de exportação
			DbSelectArea("SA1")
			RecLock("SA1",.F.)
			SA1->A1_MSEXP	:= DTOS(Date())
			MsUnlock()

			MsgAlert("Status " + _cStatus + " para cliente " + QSA1->A1_COD + " Retorno: " + cRetorno)

		ElseIf _cStatus == "400"
			MsgAlert("Status " + _cStatus + " para cliente " +QSA1->A1_COD+"/"+QSA1->A1_LOJA  + " Retorno: " + cRetorno + " Json Envio: " + JsonCli )
			// Gravo flag da data de exportação
			DbSelectArea("SA1")
			RecLock("SA1",.F.)
			SA1->A1_MSEXP	:= DTOS(Date())
			MsUnlock()
		ElseIf _cStatus == "200"
			// Gravo flag da data de exportação
			DbSelectArea("SA1")
			RecLock("SA1",.F.)
			SA1->A1_MSEXP	:= DTOS(Date())
			MsUnlock()
			//	MsgAlert("Status " + _cStatus + " para cliente " + QSA1->A1_COD + " Retorno: " + cRetorno)
		Else
			MsgAlert("Status " + _cStatus + " para cliente " + QSA1->A1_COD + " Retorno: "+ cRetorno + " HeaderGet "+cHeaderGet)
			// Gravo flag da data de exportação
			DbSelectArea("SA1")
			RecLock("SA1",.F.)
			SA1->A1_MSEXP	:= DTOS(Date())
			MsUnlock()
		EndIf
		Conout("***[RESTCLI]**********************************************************************************************")

		dbSelectArea("QSA1")
		dbSkip()
	Enddo
	QSA1->(DbCloseArea())

Return

Static Function sfMontaJson(nIdAjili)


	Local cCity          	 := sfRemoveTab("A1_MUN",SA1->A1_MUN) //SA1->A1_MUN
	Local cComplement        := sfRemoveTab("A1_COMPLEM",SA1->A1_COMPLEM) //SA1->A1_COMPLEM
	Local cCountry           := Iif(SA1->A1_EST $ "EX"," ",Iif(Empty(SA1->A1_PAIS),"105",SA1->A1_PAIS))
	Local cDistrict          := sfRemoveTab("A1_BAIRRO",SA1->A1_BAIRRO) //SA1->A1_BAIRRO
	Local cNumber            := "" //AllTrim(Substr(SA1->A1_END,AT(SA1->A1_END,",")+1,5))
	Local cState             := SA1->A1_EST
	Local cStreet            := sfRemoveTab("A1_END",SA1->A1_END) //AllTrim(SA1->A1_END)    //,1,AT(SA1->A1_END,",")-1)
	Local cZip               := SA1->A1_CEP
	Local cBirthDate         := IIF(EMPTY(SA1->A1_DTNASC),"",Substr(DtoS(SA1->A1_DTNASC),1,4)+"-"+Substr(DtoS(SA1->A1_DTNASC),5,2)+"-"+Substr(DtoS(SA1->A1_DTNASC),7,2)+" 00:00")
	Local cBloqueado         := IIF(SA1->A1_MSBLQL=="1","true","false")
	Local cCorporateName     := sfRemoveTab("A1_NOME",SA1->A1_NOME) //SA1->A1_NOME
	LOcal cCreatedBy         := ""
	Local cCreateTime        := IIF(EMPTY(SA1->A1_DTCAD),"1980-01-01 12:00",Substr(DtoS(SA1->A1_DTCAD),1,4)+"-"+Substr(DtoS(SA1->A1_DTCAD),5,2)+"-"+Substr(DtoS(SA1->A1_DTCAD),7,2)+" 00:00")
	Local cCreditLimit       := Str(SA1->A1_LC,12,2)
	Local cName              := sfRemoveTab("A1_NREDUZ",SA1->A1_NREDUZ)  + " (Cód/Lj:" + SA1->A1_COD+"/"+ SA1->A1_LOJA+  ")"
	Local cEmail             := sfRemoveTab("A1_EMAIL",SA1->A1_EMAIL) //SA1->A1_EMAIL
	Local cFax               := SA1->A1_FAX
	Local cFederalId         := SA1->A1_CGC
	Local cFiliation         := SA1->A1_FILIAL
	Local cInscricaoEstadual := SA1->A1_INSCR
	Local cLastSalesOrdemTime:= IIF(EMPTY(SA1->A1_ULTCOM),"",Substr(DtoS(SA1->A1_ULTCOM),1,4)+"-"+Substr(DtoS(SA1->A1_ULTCOM),5,2)+"-"+Substr(DtoS(SA1->A1_ULTCOM),7,2)+" 00:00")
	Local cLastVisitTime     := IIF(EMPTY(SA1->A1_ULTVIS),"",Substr(DtoS(SA1->A1_ULTVIS),1,4)+"-"+Substr(DtoS(SA1->A1_ULTVIS),5,2)+"-"+Substr(DtoS(SA1->A1_ULTVIS),7,2)+" 00:00")
	Local cNotes             := ""
	Local cPhone             := SA1->A1_TEL
	Local cDescPricing       := ""
	Local cPrinceTableId     := '""'
	Local cRG                := SA1->A1_RG

	Conout("***[RESTCLI]*[Entrou na Rotina de Monta Json]*******************************************************************")

	Jsoncli := '{'
	JsonCli += '"billingAddress": {'
	JsonCli += '"city": "'+cCity+'",'
	JsonCli += '"complement": "'+cComplement+'",'
	JsonCli += '"country": "'+cCountry+'",'
	JsonCli += '"district": "'+cDistrict+'",'
	JsonCli += '"number": "'+cNumber+'",'
	JsonCli += '"state": "'+cState+'",'
	JsonCli += '"street": "'+cStreet+'",'
	JsonCli += '"zip": "'+cZip+'"'
	JsonCli += '},'
	JsonCli += '"billingAddressId": "",'
	JsonCli += '"birthDate": "'+cBirthDate+'",'
	JsonCli += '"blocked": '+cBloqueado+','
	JsonCli += '"corporateName": "'+cCorporateName+'",'
	JsonCli += '"createdBy": "'+cCreatedBy+'",'
	JsonCli += '"creationTime": "'+cCreateTime+'",'
	JsonCli += '"creditLimit": '+cCreditLimit+','
	JsonCli += '"customerCategory": null,'
	//{'
	//JsonCli += '"description": "'+cDescCategory+'",'
	//JsonCli += '"enabled": true,'
	//JsonCli += '"idErp": "",'
	//JsonCli += '"name": "'+cName+'",'
	//JsonCli += '"pricingTableId": ""'
	//JsonCli += '},'
	JsonCli += '"customerCategoryId": null,'
	JsonCli += '"defaultPaymentFormsId": null,'
	JsonCli += '"defaultPaymentTermsId": null,'
	JsonCli += '"email": "'+cEmail+'",'
	JsonCli += '"fax": "'+cFax+'",'
	JsonCli += '"federalId": "'+cFederalId+'",'
	JsonCli += '"filiation": "'+cFiliation+'",'
	If !Empty(nIdAjili)
		JsonCli += '"id": '+Str(nIdAjili)+','
	EndIF
	JsonCli += '"idErp": "'+SA1->A1_COD+SA1->A1_LOJA+'",'
	JsonCli += '"inscricaoEstadual": "'+cInscricaoEstadual+'",'
	JsonCli += '"lastSalesOrderTime": "'+cLastSalesOrdemTime+'",'
	JsonCli += '"lastVisitTime": "'+cLastVisitTime+'",'
	JsonCli += '"name": "'+cName+'",'
	JsonCli += '"notes": "'+cNotes+'",'
	JsonCli += '"phone": "'+cPhone+'",'
	JsonCli += '"pipeline": {'
	JsonCli += '"description": "",'
	JsonCli += '"enabled": true,' // + Iif(SA1->A1_MSBLQL <> '1','true','false') +','
	JsonCli += '"name": "",'
	JsonCli += '"probability": ""'
	JsonCli += '},'
	JsonCli += '"pipelineId": "",'
	JsonCli += '"pipelineRemoved": true, '
	JsonCli += '"pricingTable": {'
	JsonCli += '"description": "'+cDescPricing+'",'
	JsonCli += '"discount": 0,'
	JsonCli += '"email": "'+cEmail+'",'
	JsonCli += '"enabled": true,'
	JsonCli += '"idErp": "",'
	JsonCli += '"maxDiscount": 0,'
	JsonCli += '"name": ""'
	JsonCli += '},'
	JsonCli += '"pricingTableId": '+cPrinceTableId+','
	JsonCli += '"rg": "'+cRG+'",'
	JsonCli += '"shippingAddress": {'
	JsonCli += '"city": "'+cCity+'",'
	JsonCli += '"complement": "'+cComplement+'",'
	JsonCli += '"country": "'+cCountry+'",'
	JsonCli += '"district": "'+cDistrict+'",'
	JsonCli += '"number": "'+cNumber+'",'
	JsonCli += '"state": "'+cState+'",'
	JsonCli += '"street": "'+cStreet+'",'
	JsonCli += '"zip": "'+cZip+'"'
	JsonCli += '},'
	JsonCli += '"shippingAddressId": "",'
	JsonCli += '"status": 2'
	JsonCli += '}'

	Conout("***[RESTCLI]*[Montou o Json do Cliente]***********************************************************************")

Return JsonCli

Static Function sfRemoveTab(cInCpo,xInValue)

	Local 	xValueAux	:= xInValue

	If Chr(9) $ xInValue
		xValueAux	:= StrTran(xInValue,Chr(9),"")
		DbSelectArea("SA1")
		RecLock("SA1",.F.)
		&("SA1->"+cInCpo)	:= xValueAux
		MsUnlock()
	Endif

	If Chr(10) $ xInValue
		xValueAux	:= StrTran(xInValue,Chr(10),"")
		DbSelectArea("SA1")
		RecLock("SA1",.F.)
		&("SA1->"+cInCpo)	:= xValueAux
		MsUnlock()
	Endif


	xValueAux	:= Alltrim(xValueAux)

Return xValueAux
//-----------------------------------------------




Static Function sfNoIdErp()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso	        := "/api/customers/no-id-erp?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	Local 	cGetParms       := ""
	Local 	nTimeOut 		:= 120
	Local 	aHeader         := {}
	Local 	cHeaderGet      := ""
	Local 	cRetorno
	Local 	oJson
	Local 	nRetParser
	Local 	jsonfields
	Local 	strJson
	Local 	lenStrJson
	Local   nX


	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cRetorno := HttpGet( cUrl+cAcesso+cApiKey , cGetParms, nTimeOut, aHeader, @cHeaderGet )

	If ValType(cRetorno) <> "C"
		MsgAlert("Erro de acesso a página de Pedidos '" +cURL +"'. Favor contatar o TI.", ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Return
	Endif

	MemoWrite("c:\edi\getcli_no_id_erp.txt", cUrl+cAcesso+cApiKey + "-" + cRetorno + " - " + cHeaderGet)

	cRetorno	:= DecodeUtf8(cRetorno)

	oJson 		:= tJsonParser():New()
	nRetParser	:= 0
	strJson 	:= cRetorno
	lenStrJson 	:= Len(cRetorno)
	jsonfields	:= {}
	lRet := oJson:Json_Parser(strJson, lenStrJson, @jsonfields, @nRetParser)

	//VarInfo("jsonfields[1]",jsonfields[1])

	For nX := 1 To Len(jsonfields[1])

		// Obtém o Id Ajili
		aVetCli		:= sfGetVal (jsonfields[1],"#_OBJECT_#","",nX)

		//VarInfo("aVetCli",aVetCli)

		nCodCli		:= sfGetVal (aVetCli,"id","")

		cIdA1Cod	:= sfGetVal (aVetCli,"idErp","")

		cCnpjCli	:= sfGetVal (aVetCli,"federalId","")

		If cCnpjCli == Nil .Or. Empty(cCnpjCli)
			// Cliente sem CNPJ no Ajili
			//MsgInfo("Id Ajili " + cValToChar(nCodCli) + " Sem informação de CNPJ para validar com Protheus",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
		Else

			DbSelectArea("SA1")
			DbSetOrder(3)
			If DbSeek(xFilial("SA1")+cCnpjCli)
				cIdA1Cod	:= SA1->A1_COD+SA1->A1_LOJA
				RecLock("SA1",.F.)
				SA1->A1_MSEXP	:=  " "
				MsUnlock()

				DbSelectArea("Z00")
				DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
				If DbSeek(xFilial("Z00") + "SA1" + SA1->(A1_FILIAL+A1_COD+A1_LOJA))
					//nIdAjili		:= Z00->Z00_IDAJIL
					RecLock("Z00",.F.)
				Else
					RecLock("Z00",.T.)
				Endif
				Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
				Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
				Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
				Z00->Z00_CHAVE  	:= SA1->(A1_FILIAL+A1_COD+A1_LOJA)	//- Chave de pesquisa/relação
				Z00->Z00_INTEGR 	:= "X"				//- Status Integração
				Z00->Z00_IDAJIL 	:= nCodCli			//- Id de Integração Ajili
				MsUnlock()


				// Efetua chamada para forçar atualização do cliente no Ajili
				//U_RestCli({},cIdA1Cod)
				If lDebug
					MsgInfo("Atualizando cliente " + SA1->A1_COD+"/"+SA1->A1_LOJA + " Id Ajili " + cValToChar(nCodCli),ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
				Endif

				sfRodaCli(cIdA1Cod)

			Else
				sfNewCli(aVetCli)
				//MsgInfo("Não localizado cadastro de cliente para o CNPJ " + cCnpjCli,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			Endif
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




/*/{Protheus.doc} sfNewCli
Rotina que cria um novo cliente na base 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 27/05/2021
@return return_type, return_description
/*/
Static Function sfNewCli(aVetCustomer)


	Local	lRet		:= .F.
	Local	aCab		:= {}
	Local	xVarAux		:= ""
	Local 	cLogErro	:= ""
	Local	cVarCodMun	:= ""
	Local 	cVarUf 		:= ""
	Local 	nCount
	Local 	iNN
	Local	aBillAddres	:=  sfGetVal (aVetCustomer,"#_OBJECT_#","billingAddress",)

	xVarAux		:= sfGetVal (aVetCustomer,"federalId","")
	// Se um CPF ou em branco não faz o cadastro
	If Len(Alltrim(xVarAux)) < 14
		Return .F.
	Endif

	aAdd(aCab , {"A1_CGC"		,xVarAux		,Nil})

	// Preenche os dados baseado na Consulta Sefaz
	If sfReceita(xVarAux,@aCab)

		// Se não adicionou o Nome Fantasia
		If  aScan(aCab,{|x| x[1] == "A1_NREDUZ"}) == 0
			xVarAux		:= Padr(StrTran(sfGetVal (aVetCustomer,"name",""),"'",""),TamSX3("A1_NREDUZ")[1])
			Aadd(aCab , {"A1_NREDUZ"	,xVarAux		,Nil})
		Endif

		If  aScan(aCab,{|x| x[1] == "A1_NOME"}) == 0
			xVarAux		:= Padr(StrTran(sfGetVal (aVetCustomer,"corporateName",""),"'",""),TamSX3("A1_NOME")[1])
			Aadd(aCab , {"A1_NOME"		,xVarAux		,Nil})
		Endif

		xVarAux		:= Padr(sfGetVal (aBillAddres,"state",""),TamSX3("A1_EST")[1])
		cVarUf		:= xVarAux
	Else
		If sfGetVal (aVetCustomer,"corporateName","") <> Nil

			xVarAux		:= Padr(StrTran(sfGetVal (aVetCustomer,"corporateName",""),"'",""),TamSX3("A1_NOME")[1])
			If Empty(xVarAux)
				xVarAux	:= Padr(StrTran(sfGetVal (aVetCustomer,"name",""),"'",""),TamSX3("A1_NOME")[1])
			Endif
			Aadd(aCab , {"A1_NOME"		,xVarAux		,Nil})

			// Fixo como CNPJ
			xVarAux		:= "J"
			aadd(aCab , {"A1_PESSOA"  	,xVarAux		,Nil})


			xVarAux		:= Padr(sfGetVal (aVetCustomer,"name",""),TamSX3("A1_NREDUZ")[1])
			If Empty(xVarAux)
				xVarAux	:= Padr(sfGetVal (aVetCustomer,"corporateName",""),TamSX3("A1_NREDUZ")[1])
			Endif
			Aadd(aCab , {"A1_NREDUZ"	,xVarAux		,Nil})

			xVarAux		:= Padr(sfGetVal (aBillAddres,"zip",""),TamSX3("A1_CEP")[1])
			If Empty(xVarAux)
				xVarAux	:= "89010000"
			Endif
			Aadd(aCab , {"A1_CEP"		,xVarAux		,Nil})

			xVarAux		:= AllTrim(sfGetVal (aBillAddres,"street",""))
			If !Empty(sfGetVal (aBillAddres,"number",""))
				xVarAux 	+= ", "
				xVarAux		+= sfGetVal (aBillAddres,"number","")
			Endif
			xVarAux		:= Padr(xVarAux,TamSX3("A1_END")[1])
			If Empty(xVarAux)
				xVarAux	:= "SEM INFORMACAO DE ENDERECO, 00"
			Endif
			Aadd(aCab , {"A1_END"		,xVarAux		,Nil})

			xVarAux		:= Padr(sfGetVal (aBillAddres,"complement",""),TamSX3("A1_COMPLEM")[1])
			aAdd(aCab , {"A1_COMPLEM"	,xVarAux		,Nil})

			xVarAux		:= Padr(sfGetVal (aBillAddres,"city",""),TamSX3("A1_MUN")[1])

			cVarMun		:= Upper(xVarAux)
			cVarMun		:= sfAjust(cVarMun,,.T.)
			Aadd(aCab , {"A1_MUN"		,xVarAux		,Nil})

			xVarAux		:= Padr(sfGetVal (aBillAddres,"district",""),TamSX3("A1_BAIRRO")[1])
			If Empty(xVarAux)
				xVarAux	:= "CASA DO VENDEDOR"
			Endif
			aAdd(aCab , {"A1_BAIRRO"	,xVarAux		,Nil})

			xVarAux		:= Padr(sfGetVal (aBillAddres,"state",""),TamSX3("A1_EST")[1])
			cVarUf		:= xVarAux
			Aadd(aCab , {"A1_EST"		,xVarAux		,Nil})


			//	MsgAlert(xFilial("CC2")+AllTrim(cVarMun),"dbSeek(xFilial(CC2)+AllTrim(cVarMun))")
			dbSelectArea("CC2")
			CC2->(dbSetOrder(2))
			If CC2->(dbSeek(xFilial("CC2")+AllTrim(cVarMun)))

				While CC2->(!Eof()) .And. xFilial("CC2") == CC2->CC2_FILIAL .AND. ;
						AllTrim(cVarMun) == AllTrim(CC2->CC2_MUN)

					If CC2->CC2_EST == cVarUf
						cVarCodMun := CC2->CC2_CODMUN
						Exit
					Endif

					CC2->(dbSkip())
				Enddo
			Else
				MsgAlert("Não encontrou o Cadastro de Cidades para a UF '"+cVarUf+"' e cidade '"+cVarMun+"' ","Erro de Cidades" )
			Endif

			CC2->(dbSetOrder(1))

			If !Empty(cVarCodMun)
				aadd(aCab , {"A1_COD_MUN"	,cVarCodMun		, Nil })
			Else
				Return .F.
			Endif
		Else
			Return .F.
		Endif
	Endif


	xVarAux		:= sfGetVal (aVetCustomer,"phone","")
	If xVarAux == Nil
		xVarAux	:= "99999999999"
	Endif

	xVarAux		:= StrTran(xVarAux,"(","")
	xVarAux		:= StrTran(xVarAux,")","")
	xVarAux		:= StrTran(xVarAux," ","")

	// Efetua limpeza para só considerar valores numéricos
	xAuxVar	:= ""
	For iNN := 1 To Len(xVarAux)
		If Substr(xVarAux,iNN,1) $ "0123456789"
			xAuxVar	+= Substr(xVarAux,iNN,1)
		Endif
	Next

	aAdd(aCab , {"A1_DDD"		,Substr(xAuxVar,1,2)		,Nil})

	Aadd(aCab , {"A1_TEL"		,Padr(Substr(xAuxVar,3),TamSx3("A1_TEL")[1])		,Nil})

	xVarAux		:= Padr(sfGetVal (aVetCustomer,"email",""),TamSX3("A1_EMAIL")[1])
	If Empty(xVarAux)
		xVarAux	:= "vendedor_nao_pegou_email_com_cliente@naotem.email.fk"
	Endif
	Aadd(aCab , {"A1_EMAIL"		,xVarAux			,Nil})

	xVarAux	:= "000100"
	AAdd(aCab , {"A1_VEND"		,xVarAux			,Nil})

	// Obtém o nome do campo do código do vendedor específico por empresa
	If SA1->(FieldPos(U_MLFATG05(1))) > 0
		Aadd(aCab , {U_MLFATG05(1)  ,xVarAux 			,Nil})
	Endif

	// Sempre como Tipo Consumidor Final na Importação
	// Processo desativado em 10/05/2023 - pois foram criados gatilhos direto no cadastro do cliente
	//Aadd(aCab , {"A1_TIPO"      ,"F"			,Nil})
	//Aadd(aCab , {"A1_CONTRIB"	,"2"			,Nil })

	// Grava com ISENTO so para importação de Cadastro
	xVarAux		:= sfGetVal (aVetCustomer,"inscricaoEstadual","")
	If xVarAux == Nil
		xVarAux	:= "ISENTO"
	Else
		If !IE(xVarAux,cVarUf)
			xVarAux	:= "ISENTO"
		Endif
	Endif


	Aadd(aCab , {"A1_INSCR"		,xVarAux		,Nil })

	Aadd(aCab , {"A1_SATIV1"	,"999999"		,Nil })

	lMSErroAuto := .F.

	Begin Transaction


		MSExecAuto({|x,y|MATA030(x,y)},aCab,3)

		If lMSErroAuto
			MostraErro()
			aErroAuto := GetAutoGRLog()
			cLogErro	:= ""
			For nCount := 1 To Len(aErroAuto)
				cLogErro += StrTran(StrTran(aErroAuto[nCount], "<", ""), "-", "") + " "
				ConOut(cLogErro)
			Next nCount
			If !Empty(cLogErro)
				MsgAlert(cLogErro)
			Endif

			cAssunto 	:= "Importação Ajili - Empresa:" + cEmpAnt+"/" + cFilAnt + " " + Capital(SM0->M0_NOME)
			cMensagem	:= "Erro na inclusão de novo cliente via importação Ajili " + CRLF
			cMensagem 	+= cLogErro + CRLF
			cMensagem	+= "Usuário:  " + cUserName + "-" + UsrFullName(__cUserId) + CRLF
			cMensagem	+= "Data/Hora: " + Dtoc( Date() ) + " as " + Time() + CRLF

			U_WFGERAL(	"rafael@grupoforta.com.br;ml-servicos@outlook.com"/*cEmail*/,cAssunto/*cTitulo*/,cMensagem/*cTexto*/,"GETPVC"/*cRotina*/,/*cAnexo*/)
		Else
			lRet	:= .T.
		EndIf
	End Transaction
Return  lRet



/*/{Protheus.doc} sfReceita
//Faz a consulta do CNPJ no Webservice para ter retorno mais completo
@author Marcelo Alberto Lauschner
@since 11/07/2018
@version 1.0
@return ${return}, ${return_description}
@param cInCgc, characters, descricao
@param aInACab, array, descricao
@type function
/*/
Static Function sfReceita(cInCgc,aInACab)

	// Variável Caractere
	Local	cUrlRec		:=	'https://www.receitaws.com.br/v1/cnpj/' + cInCgc
	Local	cJsonRet	:=  HttpGet(cUrlRec)
	Local	cQry
	Local	cVarAux
	// Variável Objeto
	Private oParseJSON 	:= Nil

	FWJsonDeserialize(cJsonRet, @oParseJSON)

	If Type("oParseJSON:situacao") <> "U"
		If oParseJSON:situacao <> "ATIVA"
			Return .F.
		Endif
	Endif

	If Type("oParseJSON:status") <> "U"
		If oParseJSON:status <> "OK"
			Return .F.
		Endif

	Endif


	If Type("oParseJSON:nome") <> "U" .And. !Empty(oParseJSON:nome)
		Aadd(aInACab,{"A1_NOME",Padr(StrTran(NoAcento(Upper(oParseJSON:nome)),"'",""),TamSX3("A1_NOME")[1]) , Nil} )
	Else
		//MsgAlert("Não encontrou informação de Razão Social ao consultar a URL "+cUrlRec )
		Return .F.
	Endif

	// Fixo como CNPJ
	xVarAux		:= "J"
	aadd(aInACab , {"A1_PESSOA"  	,xVarAux		,Nil})

	If Type("oParseJSON:fantasia") <> "U" .And. !Empty(oParseJSON:fantasia)
		Aadd(aInACab,{"A1_NREDUZ",Padr(StrTran(NoAcento(Upper(oParseJSON:fantasia)),"'",""),TamSX3("A1_NREDUZ")[1]),Nil})
	Endif


	If Type("oParseJSON:cep") <> "U"
		Aadd(aInACab,{"A1_CEP",Padr(StrTran(StrTran(oParseJSON:cep,".",""),"-",""),TamSX3("A1_CEP")[1]),Nil})
	Endif


	If Type("oParseJSON:abertura") <> "U"
		Aadd(aInACab,{"A1_DTNASC", CTOD(oParseJSON:abertura),Nil})
	Endif

	If Type("oParseJSON:logradouro") <> "U"
		cVarAux		:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A1_END")[1])
		If Type("oParseJSON:numero") <> "U"
			cVarAux	:= Padr(cVarAux + "," + NoAcento(Upper(oParseJSON:numero)),TamSX3("A1_END")[1])
		Endif
		Aadd(aInACab,{"A1_END",cVarAux,Nil})
	Else
		MsgAlert("Não encontrou informação de Endereço ao consultar a URL "+cUrlRec )
		Return .F.
	Endif


	If Type("oParseJSON:bairro") <> "U"
		Aadd(aInACab,{"A1_BAIRRO",Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A1_BAIRRO")[1]),Nil})
	Else
		MsgAlert("Não encontrou informação de Bairro ao consultar a URL "+cUrlRec )
		Return .F.
	Endif

	If Type("oParseJSON:complemento") <> "U"
		Aadd(aInACab,{"A1_COMPLEM",Padr(NoAcento(Upper(oParseJSON:complemento)),TamSX3("A1_COMPLEM")[1]),Nil})
	Endif

	If Type("oParseJSON:municipio") <> "U"
		Aadd(aInACab,{"A1_MUN", Padr(NoAcento(Upper(oParseJSON:municipio)),TamSX3("A1_MUN")[1]),Nil})
	Else
		MsgAlert("Não encontrou informação de Municipio ao consultar a URL "+cUrlRec )
		Return .F.
	Endif

	If Type("oParseJSON:uf") <> "U"
		Aadd(aInACab,{"A1_EST",Padr(NoAcento(Upper(oParseJSON:uf)),TamSX3("A1_EST")[1]),Nil})
	Else
		MsgAlert("Não encontrou informação de Estado ( UF ) ao consultar a URL "+cUrlRec )
		Return .F.
	Endif

	If Type("oParseJSON:uf") <> "U"  .And. Type("oParseJSON:municipio") <> "U"
		cQry := "SELECT CC2_CODMUN "
		cQry += "  FROM " + RetSqlName("CC2")
		cQry += " WHERE D_E_L_E_T_ =' ' "
		cQry += "   AND CC2_EST = '"+oParseJSON:uf+"' "
		cQry += "   AND CC2_MUN = '"+ StrTran(oParseJSON:municipio,"'","''") + "' "
		cQry += "   AND CC2_FILIAL = '"+xFilial("CC2") + "' "

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBLEXIST",.T.,.T.)
		If TBLEXIST->(!Eof())
			Aadd(aInACab,{"A1_COD_MUN", TBLEXIST->CC2_CODMUN,Nil})
		Else
			TBLEXIST->(DbCloseArea())
			MsgAlert("Não encontrou informação de Código Municipio ao consultar a query  "+cQry )
			Return .F.
		Endif
		TBLEXIST->(DbCloseArea())
	Endif

Return .T.




Static Function sfAjust(cInChar,lOutJson,lUpper)

	Local	cOut		:= cInChar
	Local	aOut		:= {}
	Local	nO
	Default lOutJson	:= .F.
	Default	lUpper		:= .F.

	Aadd(aOut,{"á","\u00e1","a"})
	Aadd(aOut,{"à","\u00e0","a"})
	Aadd(aOut,{"â","\u00e2","a"})
	Aadd(aOut,{"ã","\u00e3","a"})
	Aadd(aOut,{"ä","\u00e4","a"})
	Aadd(aOut,{"Á","\u00c1","a"})
	Aadd(aOut,{"À","\u00c0","a"})
	Aadd(aOut,{"Â","\u00c2","a"})
	Aadd(aOut,{"Ã","\u00c3","a"})
	Aadd(aOut,{"Ä","\u00c4","a"})
	Aadd(aOut,{"é","\u00e9","e"})
	Aadd(aOut,{"è","\u00e8","e"})
	Aadd(aOut,{"ê","\u00ea","e"})
	Aadd(aOut,{"ê","\u00ea","e"})
	Aadd(aOut,{"É","\u00c9","e"})
	Aadd(aOut,{"È","\u00c8","e"})
	Aadd(aOut,{"Ê","\u00ca","e"})
	Aadd(aOut,{"Ë","\u00cb","e"})
	Aadd(aOut,{"í","\u00ed","i"})
	Aadd(aOut,{"ì","\u00ec","i"})
	Aadd(aOut,{"î","\u00ee","i"})
	Aadd(aOut,{"ï","\u00ef","i"})
	Aadd(aOut,{"Í","\u00cd","i"})
	Aadd(aOut,{"Ì","\u00cc","i"})
	Aadd(aOut,{"Î","\u00ce","i"})
	Aadd(aOut,{"Ï","\u00cf","i"})
	Aadd(aOut,{"ó","\u00f3","o"})
	Aadd(aOut,{"ò","\u00f2","o"})
	Aadd(aOut,{"ô","\u00f4","o"})
	Aadd(aOut,{"õ","\u00f5","o"})
	Aadd(aOut,{"ö","\u00f6","o"})
	Aadd(aOut,{"Ó","\u00d3","o"})
	Aadd(aOut,{"Ò","\u00d2","o"})
	Aadd(aOut,{"Ô","\u00d4","o"})
	Aadd(aOut,{"Õ","\u00d5","o"})
	Aadd(aOut,{"Ö","\u00d6","o"})
	Aadd(aOut,{"ú","\u00fa","u"})
	Aadd(aOut,{"ù","\u00f9","u"})
	Aadd(aOut,{"û","\u00fb","u"})
	Aadd(aOut,{"ü","\u00fc","u"})
	Aadd(aOut,{"Ú","\u00da","u"})
	Aadd(aOut,{"Ù","\u00d9","u"})
	Aadd(aOut,{"Û","\u00db","u"})
	Aadd(aOut,{"ç","\u00e7","c"})
	Aadd(aOut,{"Ç","\u00c7","c"})
	Aadd(aOut,{"ñ","\u00f1","n"})
	Aadd(aOut,{"Ñ","\u00d1","n"})
	Aadd(aOut,{"®","\u00d1","r"})
	Aadd(aOut,{"°","\u00d1"," "})
	Aadd(aOut,{"ª","\u00d1"," "})
	Aadd(aOut,{Chr(186),"\u00d1"," "})
	Aadd(aOut,{"´","\u00b4"," "})
	Aadd(aOut,{Chr(13),"\u0013"," "})
	Aadd(aOut,{Chr(10),"\u0010"," "})
	Aadd(aOut,{"/","\u0010","-"})

	Aadd(aOut,{"&","\u0026"," ","&amp;"})
	Aadd(aOut,{"<","\u0010"," ","&lt;"})
	Aadd(aOut,{">","\u0010"," ","&gt;"})
	Aadd(aOut,{'"',"\u0010"," ","&quot;"})
	Aadd(aOut,{"'","\u0027"," ","&#39;"})
	Aadd(aOut,{"Ø","\u00d8"," "," "})
	Aadd(aOut,{"½","\u00d8"," "," "})

	//ConOut("+------------------------------------+")
	//ConOut(cOut)
	If lOutJson
		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,2])
		Next nO
	Else
		//cOut	:= DecodeUTF8(cOut)
		//ConOut(cOut)

		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,3])
		Next nO

		cOut	:= Alltrim(Upper(cOut))
	Endif
	If lUpper
		cOut	:= Upper(cOut)
	Endif
	cOut	:= StrTran(cOut,"PALHOC6","PALHOCA")
	//ConOut(cInChar)
	//ConOut(cOut)
	//ConOut("+++------------------------------------+")

Return cOut
