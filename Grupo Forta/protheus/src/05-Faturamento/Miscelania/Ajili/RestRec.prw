#include "totvs.ch"
#include "tbiconn.ch"


/*/{Protheus.doc} RestRec
//TODO Rotina de integração de Títulos a Receber 
@author Marcelo Alberto Lauschner 
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User function RestRec(aParam)

	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	cInCodLj	:= ""
	Default	aParam		:= {}
	Private lDebug		:= .F. 
	Private cNomRot		:= "RESTREC_"+cFilAnt
	
	/// Mensagem de saída no Consol	
	ConOut("+-"+Replicate("-",100)+"+")
	ConOut("| "+Padr(cNomRot + " " + FunName() + "." + ProcName(0) + "-" + Alltrim(Str(ProcLine(0))) ,100) +"|")
	ConOut("| "+Padr(cNomRot + " Inicio " + DTOC(Date()) + " " + Time(),100) +"|")
	ConOut("| "+Padr(cNomRot + " Empresa Logada: " + cEmpAnt,100)+"|")
	ConOut("| "+Padr(cNomRot + " Filial Logada : " + cFilAnt,100)+"|")
	VarInfo(cNomRot+".Valores passados via aParam",aParam)
	
	If GetNewPar("GF_AJILIOK",.T.)
	
		While !lRet
			
			
			If lRet	:= LockByName(cNomRot,.T.,.T.)
			
				Processa({|| sfRodaRec() },"Processando títulos...")		
				
				UnLockByName(cNomRot,.T.,.T.)
				
	
			Else
				
				MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Exportação títulos já em execução!")
				
				nWaitSec ++ 

				ConOut("|"+Padr("["+cNomRot+"]Job ja esta em execucao. Tentativa " + cValToChar(nWaitSec) ,100)+"|")
				
				// Havendo mais de 10 tentativas de espera por 1 segundos cada, aborta o processo 
				If nWaitSec  >= 10 
					lRet	:= .T.
					Exit
				Endif						
			Endif
		Enddo
	Endif
	ConOut("| "+Padr(cNomRot + " Final " + DTOC(Date()) + " " + Time(),100) +"|")
	ConOut("+-"+Replicate("-",100)+"+")
	
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

/*/{Protheus.doc} sfRodaRec
//TODO Função responsável pela geração dos dados de exportação. 
@author Marcelo Alberto Lauschner 
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfRodaRec()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/receivables?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	
	local 	aHeader         := {}
	local 	aHeadOut        := {}
	local 	cHeaderGet      := ""
	Local 	xRet                                     
	Local 	oObjJson
	Local 	cMsg	 		:= ""
	Local 	cJsonCli		:= ""
	Local 	nTypeStamp		:= 4					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
	local 	wrk
	Local	cFilSA1			:= xFilial("SA1")
	Local	nRec
	Local 	nRecAtu			:= 0
	
	Private nSE1IdAjili        := 0
	Private nSA1IdAjili        := 0

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	_xFil := xFilial("SE1")

	dbSelectArea("SE1")
	dbSetOrder(1)
	// Efetua filtro de registros apenas da Filial específica e que não tenha informação de sincronização ( E1_MSEXP )
	Set Filter To E1_FILIAL == _xFil .And. Empty(E1_MSEXP)
	
	Count To nRec

	ProcRegua(nRec)

	SE1->(DbGotop())
	
	While !Eof() .And. SE1->E1_FILIAL == _xFil 

		nRecAtu ++ 
		IncProc("Registro " + cValToChar(nRecAtu) + " de " + cValToChar(nRec)  )
		
		// Procura pelo Id Ajili do Cadastro de Cliente 
		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA1" + cFilSA1 + SE1->(E1_CLIENTE+SE1->E1_LOJA))
			nSA1IdAjili		:= Z00->Z00_IDAJIL
		Endif
		
		// Se o cliente não tiver sido integrado com o Ajili, não exporta registro do Título a Receber 
		If nSA1IdAjili==0 
			dbSelectArea("SE1")
			dbSkip()
			Loop
		EndIf
		
		nSE1IdAjili	:= 0
		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SE1" + SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
			nSE1IdAjili		:= Z00->Z00_IDAJIL
		Endif
		
		cJsonRec := sfMontaJson()
	
		ConOut("["+cNomRot+"][JSON HTTPPOST]["+cJsonRec+"]}")
		
		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(cJsonRec),200,aHeader,@cHeaderGet)
		
		ConOut("["+cNomRot+"][RETORNO]["+cRetorno+"]")
		
		wrk := JsonObject():new()
		wrk:fromJson(cRetorno)

		cRet := wrk:GetJsonText("id")

		nSE1IdAjili := Val(cRet)

		_cStatus := Substr(cHeaderGet,10,3)

		
		If _cStatus $ "200" .And. nSA1IdAjili > 0  .And. nSE1IdAjili > 0 // Inclusão / Alteração / Reativação 
			
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SE1" + SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SE1"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSE1IdAjili		//- Id de Integração Ajili
			Z00->Z00_MSEXP		:= DTOS(Date())
			MsUnlock()
			
			DbSelectArea("SE1")
			RecLock("SE1",.F.)
			SE1->E1_MSEXP		:= DTOS(Date())
			MsUnlock()
			
		Else
			MsgAlert("Status " + _cStatus + " para titulo " + SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO) + " Retorno: " + cRetorno)
		EndIf 
		
		dbSelectArea("SE1")
		dbSkip()

	Enddo 
	

Return


/*/{Protheus.doc} sfMontaJson
//TODO Monta Json de envio de dados 
@author Marcelo Alberto Lauschner 
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfMontaJson()

	
	Local cMsg	 			 := ""
	Local cJsonCli			 := ""
	Local nTypeStamp		 := 4					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
	Local nTypeStamp		 := 6					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
	Local cJsonRec
	
	cJsonRec := '{'
	cJsonRec += '"accomplishedDate": "'+IIF(EMPTY(SE1->E1_BAIXA)," ",Substr(DtoS(SE1->E1_BAIXA),1,4)+"-"+Substr(DtoS(SE1->E1_BAIXA),5,2)+"-"+Substr(DtoS(SE1->E1_BAIXA),7,2)+" 00:00")+'",'
	cJsonRec += '"customerId": '+STR(nSA1IdAjili,11,0)+','
	cJsonRec += '"document": "'+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+'",'
	cJsonRec += '"expirationDate": "'+IIF(EMPTY(SE1->E1_VENCTO)," ",Substr(DtoS(SE1->E1_VENCTO),1,4)+"-"+Substr(DtoS(SE1->E1_VENCTO),5,2)+"-"+Substr(DtoS(SE1->E1_VENCTO),7,2)+" 00:00")+'",'
	If !Empty(nSE1IdAjili)
		cJsonRec += '"id": '+ AllTrim(cValToChar(nSE1IdAjili)) +','
	EndIF
	cJsonRec += '"idErp": "'+SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)+'",'
	cJsonRec += '"issueDate": "'+IIF(EMPTY(SE1->E1_EMISSAO)," ",Substr(DtoS(SE1->E1_EMISSAO),1,4)+"-"+Substr(DtoS(SE1->E1_EMISSAO),5,2)+"-"+Substr(DtoS(SE1->E1_EMISSAO),7,2)+" 00:00")+'",'
	If SE1->E1_TIPO $ MVRECANT + MV_CRNEG
		cJsonRec += ' "paidValue": '+STR(((SE1->E1_VALOR-SE1->E1_SALDO)*-1),12,2)+','
		cJsonRec += '"rawValue": '+STR((SE1->E1_VALOR*-1),12,2)+''
	Else
		cJsonRec += ' "paidValue": '+STR((SE1->E1_VALOR-SE1->E1_SALDO),12,2)+','
		cJsonRec += '"rawValue": '+STR((SE1->E1_VALOR),12,2)+''
	Endif
	cJsonRec += '}'

	
Return cJsonRec

