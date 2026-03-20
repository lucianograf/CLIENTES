#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"


/*/{Protheus.doc} RestPor
//TODO Geração de carga de amarração de Vendedor x Clientes
@author Edson / Marcelo Lauschner
@since 12/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function RestPor()
	
	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	cInCodLj	:= ""
	Private lDebug		:= .F. 
	
	If GetNewPar("GF_AJILIOK",.T.)
		While !lRet
			
			
			If lRet	:= LockByName("RESTPOR_"+cFilAnt,.T.,.T.)
			
				Conout("***[Inicio RESTPOR_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]************************************************************************")
				Processa({|| sfRodaPor() },"Processando portfólio...")
				UnLockByName("RESTPOR_"+cFilAnt,.T.,.T.)
				Conout("***[Fim RESTPOR_"+cFilAnt + " " + DTOC( Date() ) + " " + Time() + "]****************************************************************************")
	
			Else
				
				MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Portfólio já em execução!")
				nWaitSec ++ 
				Conout("*****[Job RESTPOR_ ja esta em execucao]***********************************************")
				// Havendo mais de 10 tentativas de espera por 1 segundos cada, aborta o processo 
				If nWaitSec  >= 10 
					lRet	:= .T.
					Exit 
					//MsgAlert("Semáforo - Job RESTPOR_"+cFilAnt+" já está em execução! ")
				Endif						
			Endif
		Enddo
	Endif

Return


Static Function sfRodaPor()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/portfolio/"
	Local	cApiKey			:= "?api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	local 	aHeader         := {}
	local 	cHeaderGet      := ""
	Local 	cAcessVend      := ""
	Local 	nRecAtu			:= 0
	Local	nRec
	
	Private nCodVend        := 0

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cQry := "SELECT A1.R_E_C_N_O_ AS A1RECNO,A3.R_E_C_N_O_ AS A3RECNO,A1_FILIAL,A1_COD,A1_LOJA,"
	cQry += "       A3.A3_FILIAL,A3.A3_COD, CASE WHEN A3.A3_ZAGRUP <> ' ' THEN A3.A3_ZAGRUP ELSE A3.A3_COD END A3_ZAGRUP, "
	cQry += "       COALESCE(Z00_IDAJIL,-1) IDAJILI "
	cQry += "  FROM " + RetSqlName("SA1") + " A1 "
	cQry += " INNER JOIN " + RetSqlName("SA3") + " A3 "
	cQry += "    ON A3.D_E_L_E_T_ = ' '"
	cQry += "   AND A3.A3_ZAGRUP <> ' ' " // ALTEREI
	// Linka com o código agrupador do vendedor para verificar se o mesmo exporta para o Ajili 
	cQry += " INNER JOIN " + RetSqlName("SA3") + " A3B "
	cQry += "    ON A3B.D_E_L_E_T_ =' ' "
	cQry += "   AND A3B.A3_COD = A3.A3_ZAGRUP "
	cQry += "   AND A3B.A3_HAND = '1' " // ALTEREI
	cQry += "   AND A3B.A3_FILIAL = '" + xFilial("SA3") + "'"
	
	cQry += " INNER JOIN " + RetSqlName("Z00") + " Z00 " 
	cQry += "    ON Z00.D_E_L_E_T_ =' ' " 
	cQry += "   AND Z00_FILIAL = '" + xFilial("Z00") + "'" 
	cQry += "   AND Z00_ENTIDA = 'SA1' " 
	cQry += "   AND Z00_CHAVE = (A1_FILIAL+A1_COD+A1_LOJA) " 
	cQry += " WHERE A1.D_E_L_E_T_ =' ' " 
	cQry += "   AND A1_FILIAL = '" + xFilial("SA1") + "'"
	// Verifica se deve buscar o campo de vendedor específico 
	If SA1->(FieldPos(U_MLFATG05(1))) > 0 
		cQry += "   AND "+ U_MLFATG05(1) + " = A3.A3_COD "
	Else 
		cQry += "   AND A1_VEND = A3.A3_COD "
	Endif 
	cQry += "   AND A1_CGC NOT IN(' ') "
	cQry += "   AND Z00_INTEGR NOT IN('E','V') " // Diferente de Integrado com Portifólio , assim só pega novos e alterações 
	cQry += " ORDER BY A1_COD,A1_LOJA"

	TcQuery cQry New Alias "QSA1"
	Count To nRec
	
	ProcRegua(nRec)
	
	QSA1->(DbGotop())
	
	While QSA1->(!Eof())  

		nRecAtu ++ 
		IncProc("Registro " + cValToChar(nRecAtu) + " de " + cValToChar(nRec)  )
		
		nSA3IdAjili	:= 0
		nSA1IdAjili	:= 0

		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA3" + QSA1->(A3_FILIAL+A3_ZAGRUP))// ALTERADO
			nSA3IdAjili		:= Z00->Z00_IDAJIL
		Else
			MsgAlert("Vendedor " +QSA1->(A3_FILIAL+A3_ZAGRUP) + " ainda não cadastrado no Ajili","Ajili - Vendedor")
		Endif

		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA1" + QSA1->(A1_FILIAL+A1_COD+A1_LOJA))
			nSA1IdAjili		:= Z00->Z00_IDAJIL
		Else
			MsgAlert("Cliente " +QSA1->(A1_FILIAL+A1_COD+A1_LOJA) +  " - Vendedor " + QSA1->A3_ZAGRUP + " ainda não cadastrado no Ajili","Ajili - Cliente")
		Endif

		If nSA1IdAjili == 0 .Or. nSA3IdAjili == 0
			dbSelectArea("QSA1")
			dbSkip()
			Loop
		Endif

		cAcessVend := AllTrim(STR(nSA3IdAjili,11,0)) + "-" + AllTrim(Str(nSA1IdAjili,11,0)) 


		JsonPor := sfMontaJson(nSA1IdAjili,nSA3IdAjili)

		Conout("***[RESTPOR]*[Json criado]********************************************************************************")
		Conout(JsonPor) 

		Conout("***[RESTPOR]*[Vai enviar via HTTP Post o Json]*************************************************************")
		
		cRetorno := HttpPost( cURL+cAcesso+cAcessVend+cApiKey,"",encodeUTF8(JsonPor),200,aHeader,@cHeaderGet)

		Conout("***[RESTPOR]*[Enviou via HTTP Post o Json]*****************************************************************")

		Conout("***[RESTPOR]***********************************************************************************************")

		Conout(cRetorno)
		Conout(cHeaderGet)

		_cStatus := Substr(cHeaderGet,10,3)

		Conout("Status da Inclusao: "+_cStatus)

		Conout("***[RESTPOR]**********************************************************************************************")


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
			Z00->Z00_INTEGR 	:= "V"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA1IdAjili		//- Id de Integração Ajili
			Z00->Z00_MSEXP		:= DTOS(Date())
			MsUnlock()

		ElseIf _cStatus == "500" .And. nSA1IdAjili > 0 
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
			Z00->Z00_INTEGR 	:= "V"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA1IdAjili		//- Id de Integração Ajili
			Z00->Z00_MSEXP		:= DTOS(Date())
			MsUnlock()
			//MsgAlert("Status " + _cStatus + " para cliente " + QSA1->A1_COD + " Retorno: " + cRetorno)
		ElseIf _cStatus $ "500"
			// Sem mensagens pois erro 500 é duplicidade de registro 
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
		Else
			//MsgAlert("Status " + _cStatus + " para cliente " + QSA1->A1_COD + " Retorno: " + cRetorno)
		EndIf  
		Conout("***[RESTPOR]**********************************************************************************************")

		dbSelectArea("QSA1")
		dbSkip()
	Enddo
	QSA1->(DbCloseArea())

Return 

Static Function sfMontaJson(nIdCustomer,nIdSalesMan)

	Local JsonPor			 := ""

	Conout("***[RESTPOR]*[Entrou na Rotina de Monta Json]*******************************************************************")

	JsonPor := ''
	JsonPor := '{'
	JsonPor += '"customerId": '+Alltrim(Str(nIdCustomer,11,0))+','
	JsonPor += '"salesmanId": '+Alltrim(Str(nIdSalesMan,11,0))+''
	JsonPor += '}'

	Conout("***[RESTPOR]*[Montou o Json de Portfolio]***********************************************************************")

Return JsonPor




Static Function sfListPor(cIdVend)

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/portfolio/"+cIdVend+"?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))

	Local 	aHeader         := {}
	Local   iD1

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	//cRetorno := HttpPost( cUrl+cAcesso+cApiKey , cGetParms, nTimeOut, aHeader, @cHeaderGet )
	//http://condor.ajili.com.br/api/portfolio/495?api_key=$2a$10$woZDXrsKk0pgCrhBvz1kLeh1Dh1kCiw179nTtu/P.I/o0nEQnQ4YS
	
	MemoWrit("c:\edi\getpor_"+cIdVend+".txt", cUrl+cAcesso+cApiKey + "-" + cRetorno)

	oJson 		:= tJsonParser():New()
	nRetParser	:= 0
	strJson 	:= cRetorno
	lenStrJson 	:= Len(cRetorno)
	jsonfields	:= {}
	lRet := oJson:Json_Parser(strJson, lenStrJson, @jsonfields, @nRetParser)

	If !lRet
		MsgAlert("##### [JSON][ERR] " + "Parser 1 com erro" + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		MsgAlert("Erro a partir: " + SubStr(strJson, (nRetParser+1)))
	Else
		//		msgAlert("[JSON] "+ "+++++ PARSER 1 OK num campos: " + AllTrim(Str(Len(jsonfields))) + " MSG len: " + AllTrim(Str(lenStrJson)) + " bytes lidos: " + AllTrim(Str(nRetParser)))
		//		printJson(jsonfields, "| ")
	EndIf	

	For iD1 := 1 To Len(jsonfields[1])
		aVetIdVend	:= sfGetVal (jsonfields[1],"#_OBJECT_#","",iD1)
		cIdErp		:= sfGetVal (aVetIdVend,"customerId","")
		
		If !Empty(cIdErp)
			
			
			DbSelectArea("Z00")
			DbSetOrder(2)//Z00_FILIAL+Z00_ENTIDA+STR(Z00_IDAJIL,11,0)
			If DbSeek(xFilial("Z00") + "SA1" + Str(Val(cIdErp),11,0))
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)
			Endif

			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA1"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= xFilial("SA1") + cIdErp	//- Chave de pesquisa/relação 
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
