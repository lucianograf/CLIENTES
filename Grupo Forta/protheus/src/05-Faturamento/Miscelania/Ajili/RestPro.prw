#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"


/*/{Protheus.doc} RestPro
//TODO Rotina de exportação de dados de Produtos para integração com o Ajili
@author Marcelo Alberto Lauschner 
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}
@param aParam, array, descricao
@type function
/*/
User function RestPro(aParam)

	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	cInCodLj	:= ""
	Default	aParam		:= {}
	Private lDebug		:= .F.
	Private cNomRot		:= "RESTPRO_"+cFilAnt

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

				Processa({|| sfRodaPro() },"Processando produtos...")

				UnLockByName(cNomRot,.T.,.T.)


			Else

				MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Exportação Produtos já em execução!")

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



/*/{Protheus.doc} sfRodaPro
//TODO Rotina de Execução da integração
@author Marcelo Alberto Lauschner 
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function sfRodaPro()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/products?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	local 	aHeader         := {}
	//local 	aHeadOut        := {}
	local 	cHeaderGet      := ""
	//Local 	xRet

	//Local 	nTimeOut 		:= 120
	//Local 	cMsg	 		:= ""
	//Local 	cJsonCli		:= ""
	//Local 	nTypeStamp		:= 6					//	estampa de tempo em milissegundos desde 01/01/1970 00:00:00
	Local 	nRecAtu			:= 0
	Local	nRec

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cQry := "SELECT B1_FILIAL,B1_MSBLQL, B1.R_E_C_N_O_ AS B1RECNO,B1_COD,B1_DESC,B1_CODBAR,B1_CLASFIS,B1_TIPO,B1_ZSTS,B1_UM,"
	cQry += "       B1_PESO,B1_PESBRU,B1_PICM,B1_IPI,B1_TS,B1_LOCPAD,COALESCE(Z00_IDAJIL,0) B1_IDAJILI,"
	cQry += "       COALESCE(B2_MSEXP,' ') B2_MSEXP ,COALESCE(B2_QATU,0) B2_QATU,COALESCE(B2_RESERVA,0) B2_RESERVA, COALESCE(B2_CM1,0)B2_CM1,B2.R_E_C_N_O_ B2RECNO "
	cQry += "  FROM " + RetSqlName("SB1") + " B1 "
	cQry += "  LEFT JOIN " + RetSqlName("Z00") + " Z00 "
	cQry += "    ON Z00.D_E_L_E_T_ =' ' "
	cQry += "   AND Z00_FILIAL = '" + xFilial("Z00") + "'"
	cQry += "   AND Z00_ENTIDA = 'SB1' "
	cQry += "   AND Z00_CHAVE = (B1_FILIAL+B1_COD)"
	cQry += "  LEFT JOIN " + RetSqlName("SB2") + " B2 "
	cQry += "    ON B2.D_E_L_E_T_ =' ' "
	cQry += "   AND B2_LOCAL = B1_LOCPAD "
	cQry += "   AND B2_COD = B1_COD "
	cQry += "   AND B2_FILIAL = '" + xFilial("SB2") + "' "
	cQry += " WHERE B1.D_E_L_E_T_ =' ' "
	cQry += "   AND B1_FILIAL = '" + xFilial("SB1") + "'"
	cQry += "   AND B1_XINTEGR = 'S' "
	cQry += "   AND B1_TIPO IN('ME','PA','GN','MP','OI','KT','SV')  "
	cQry += "   AND (B1_MSEXP = ' ' OR COALESCE(B2_MSEXP,' ') = ' ')"
	cQry += " ORDER BY B1_COD"

	TcQuery cQry New Alias "QSB1"
	MemoWrite("C:\edi\restpro.sql",cQry)
	Count To nRec

	ProcRegua(nRec)

	QSB1->(DbGotop())

	While QSB1->(!Eof())

		nIdAjili		:= QSB1->B1_IDAJILI

		nRecAtu ++
		IncProc("Registro " + cValToChar(nRecAtu) + " de " + cValToChar(nRec)  )


		cJsonPro := sfMontaJson(nIdAjili)

		ConOut("["+cNomRot+"][JSON HTTPPOST]["+cJsonPro+"]}")

		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(cJsonPro),200,aHeader,@cHeaderGet)

		ConOut("["+cNomRot+"][RETORNO]["+cRetorno+"]")

		wrk := JsonObject():new()
		wrk:fromJson(cRetorno)

		cRet := wrk:GetJsonText("id")

		nSB1IdAjili := Val(cRet)

		_cStatus := Substr(cHeaderGet,10,3)

		If _cStatus $ "200#" .And. nSB1IdAjili > 0 // Inclusão / Alteração / Reativação

			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SB1" + QSB1->(B1_FILIAL+B1_COD))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SB1"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade
			Z00->Z00_CHAVE  	:= QSB1->(B1_FILIAL+B1_COD)	//- Chave de pesquisa/relação
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSB1IdAjili		//- Id de Integração Ajili
			Z00->Z00_MSEXP		:= DTOS(Date())
			MsUnlock()

			// Atualiza controle de exportação de registro
			DbSelectArea("SB1")
			DbGoto(QSB1->B1RECNO)
			RecLock("SB1",.F.)
			SB1->B1_MSEXP 	:= DTOS(Date())
			MsUnlock()

			// Se existir o estoque atualiza como exportado
			If QSB1->B2RECNO > 0
				DbSelectArea("SB2")
				DbGoto(QSB1->B2RECNO)
				RecLock("SB2",.F.)
				SB2->B2_MSEXP 	:= DTOS(Date())
				MsUnlock()
			Endif

		Else
			MsgAlert("Status " + _cStatus + " para produto " + QSB1->B1_COD + " remessa:" + encodeUTF8(cJsonPro) + " retorno: " + cRetorno)
		EndIf

		dbSelectArea("QSB1")
		dbSkip()

	End
	QSB1->(DbCloseArea())

Return


/*/{Protheus.doc} sfMontaJson
//TODO Monta o Json para envio do Produto ao Ajili
@author Marcelo Alberto Lauschner 
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}
@param nIdAjili, numeric, descricao
@type function
/*/
Static Function sfMontaJson(nIdAjili)


	Local cJsonPro			 := ""
	Local cAtivo			 := IIf(QSB1->B1_MSBLQL == "1" .Or. QSB1->B1_ZSTS $ "E",'false',Iif(QSB1->B1_TIPO $ "ME#PA#KT#OI#SV",'true','false')) //cQry += "   AND B1_ZSTS NOT IN('E') "
	Local cCodBar            := QSB1->B1_CODBAR
	//Local cCfopId            := "0" //  "cfopId": 0,
	//Local cClasFis           := AllTrim(Str(Val(QSB1->B1_CLASFIS)))  //"classificacaoFiscalId": 0,
	Local cCode              := QSB1->B1_COD  //"code": "string",
	//Local cCstId             := "0" //SB1->B1_CST //  "cstId": 0,
	Local cDescricao         := QSB1->B1_DESC //  "description": "string",
	//Local cIcms              := Str(QSB1->B1_PICM) //  "icmsPercent": 0,
	//Local cRedIcms           := Str(QSB1->B1_PICM) //  "icmsReductionPercent": 0,
	//Local cId                := "0" //  "id": 0,
	//Local cIdErp             := QSB1->B1_COD //  "idErp": "string",
	Local cIPI               := cValToChar(QSB1->B1_IPI/100) //  "ipiPercent": 0,
	//Local cLoteId            := "0"  //lotId": 0,
	//Local cMarkupMin         := "0" //  "markupMinimum": 0,
	//Local cMinValor          := "0" //  "minimumValue": 0,
	//Local cNome              := QSB1->B1_DESC //  "name": "string",
	Local cTabPadrao         := SuperGetMv("MV_XTABPAD",.F.,"601")

	nCustoM := QSB1->B2_CM1
	nQATU   := (QSB1->B2_QATU - QSB1->B2_RESERVA)

	If cFilAnt == "0101" 
		nQATU 	:= 0 

		cQry := "SELECT SUM(B2_QATU - B2_RESERVA) EST_AUX "
		cQry += "  FROM " + RetSqlName("SB2") + " B2 "
		cQry += " WHERE B2.D_E_L_E_T_ = '  ' "
		cQry += "   AND B2_LOCAL IN('01','02','20') "
		cQry += "   AND B2_FILIAL = '"+xFilial("SB2")+ "' " 
		cQry += "   AND B2_COD = '"+QSB1->B1_COD + "' "

		TcQuery cQry New Alias "QSB2"
		If !Eof() 
			nQATU	+= QSB2->EST_AUX 
		Endif 
		QSB2->(DbCloseArea())

		// Soma estoque da Importadora 
		cQry := "SELECT SUM(B2_QATU - B2_RESERVA) EST_AUX "
		cQry += "  FROM " + RetSqlName("SB2") + " B2 "
		cQry += " INNER JOIN " + RetSqlName("SB5") + " B5 "
		cQry += "    ON B5.D_E_L_E_T_ =' ' " 
		cQry += "   AND B5_COD = '"+QSB1->B1_COD + "' "
		cQry += "   AND B5_FILIAL = '01' " // Fixa a filial 
		cQry += " WHERE B2.D_E_L_E_T_ = '  ' "
		cQry += "   AND B2_LOCAL IN('01','02','20') " // Fixa o armazém de busca 
		cQry += "   AND B2_FILIAL = '0301' " // Fixa a filial 
		cQry += "   AND B2_COD = B5_XCODINT "
		
		TcQuery cQry New Alias "QSB5"

		If !Eof() 
			nQATU	+= QSB5->EST_AUX 
		Endif 
		QSB5->(DbCloseArea())
	Endif 


	dbSelectArea("DA1")
	dbSetOrder(1)
	If dbSeek(xFilial("DA1")+cTabPadrao+QSB1->B1_COD,.F.)
		nPreco := DA1->DA1_PRCVEN
	Else
		nPreco := 0.00
	EndIf

	cJsonPro := '{'
	cJsonPro +=  '"active": '+cAtivo+','
	cJsonPro +=  '"barcode": "'+cCodBar+'",'
	//cJsonPro +=  '"campaignId": 0,'
	//cJsonPro +=  '"cfopId": '+cCfopId+','
	//cJsonPro +=  '"classificacaoFiscalId": '+cClasFis+','
	cJsonPro +=  '"code": "'+cCode+'",'
	//cJsonPro +=  '"cstId": '+cCstId+','

	//cJsonPro +=  '"description": "'+cDescricao+'",'
	// 27/05/2021 - Alteração feita para levar o código do produto junto com a Descrição para o Ajili
	cJsonPro +=  '"description": "'+Alltrim(cDescricao)+ ' (' + Alltrim(cCode)+ ')",'

	//cJsonPro +=  '"icmsPercent": '+cIcms+','
	//cJsonPro +=  '"icmsReductionPercent": '+cRedIcms+','
	If !Empty(nIdAjili)
		cJsonPro += '"id": ' + Alltrim(Str(nIdAjili))+','
	EndIF
	cJsonPro +=  '"idErp": "'+cCode+'",'
	If cFilAnt == "0301"
		cJsonPro +=  '"ipiPercent": '+cIPI+','
	Else
		cJsonPro +=  '"ipiPercent": null,'
	Endif
	//cJsonPro +=  '"lotId": '+cLoteId+','
	//cJsonPro +=  '"markupMinimum": 0,'
	//cJsonPro +=  '"minimumValue": 0,'
	cJsonPro +=  '"name": "'+Alltrim(cDescricao)+ ' (' + Alltrim(cCode)+ ')",'
	cJsonPro +=  '"perishable": false,'
	cJsonPro +=  '"presentation": "'+QSB1->B1_UM+'",'
	//cJsonPro +=  '"promotionalValue": 0,'
	cJsonPro +=  '"stockAverageCost": '+STR(nCustoM,12,2)+','
	//cJsonPro +=  '"stockGrid1Id": 0,'
	//cJsonPro +=  '"stockGrid2Id": 0,'
	cJsonPro +=  '"stockTotal": '+STR(nQATU,10,3)+','
	//cJsonPro +=  '"url": "",'
	cJsonPro +=  '"value": '+STR(nPreco,12,2)+' '

	cJsonPro +=  ',"weight": ' +Str(QSB1->B1_PESBRU,10,2)
	cJsonPro +=  ',"weightNet": ' +Str(QSB1->B1_PESO,10,2)
	
	// Se tiver informações de produto quanto a peso e medidas 
	DbSelectArea("SB5")
	DbSetOrder(1)
	If DbSeek(xFilial("SB5")+QSB1->B1_COD)
		cJsonPro +=  ',"depth": ' +Str(SB5->B5_COMPR,10,2)
		cJsonPro +=  ',"height": ' +Str(SB5->B5_ALTURA,10,2)
		cJsonPro +=  ',"width": ' +Str(SB5->B5_LARG,10,2)
	Endif
	cJsonPro += '}'

Return cJsonPro

//-----------------------------------------------
