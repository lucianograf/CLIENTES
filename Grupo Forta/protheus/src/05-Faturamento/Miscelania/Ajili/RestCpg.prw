#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"

User function RestCpg()

	lRet 	:= LockByName("RESTCPG",.T.,.F.,.T.)

	If lRet

		Conout("***[Inicio RESTCPG " + DTOC( Date() ) + " " + Time() +"]************************************************************************")

		sfRodaCpg()		

		Conout("***[Fim RESTCPG " + DTOC( Date() ) + " " + Time() +"]****************************************************************************")

	Else
		Conout("*****[Job RESTCPG ja esta em execucao]***********************************************")  			
	Endif

Return


Static Function sfRodaCpg()


	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/paymentTerms?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	local 	aHeader         := {}
	local 	aHeadOut        := {}
	local 	cHeaderGet      := ""
	Local 	xRet

	aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	cQry := "SELECT E4_FILIAL,E4_MSBLQL, E4.R_E_C_N_O_ AS E4RECNO,E4_CODIGO,E4_ZFATFIN,E4_DESCRI,COALESCE(Z00_IDAJIL,-1) IDAJILI "
	cQry += "  FROM " + RetSqlName("SE4") + " E4 "
	cQry += "  LEFT JOIN " + RetSqlName("Z00") + " Z00 " 
	cQry += "    ON Z00.D_E_L_E_T_ =' ' " 
	cQry += "   AND Z00_FILIAL = '" + xFilial("Z00") + "'" 
	cQry += "   AND Z00_ENTIDA = 'SE4' " 
	cQry += "   AND Z00_CHAVE = (E4_FILIAL+E4_CODIGO)" 
	cQry += " WHERE E4.D_E_L_E_T_ =' ' AND E4_ZEXPAJI = 'S'" 
	cQry += "   AND E4_FILIAL = '" + xFilial("SE4") + "'"
	cQry += " ORDER BY E4_CODIGO "

	TcQuery cQry New Alias "QSE4"

	While QSE4->(!Eof())  

		nIdAjili		:= 0

		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SE4" + QSE4->(E4_FILIAL+E4_CODIGO))
			nIdAjili		:= Z00->Z00_IDAJIL
		Endif

		jSonCpg := sfMontaJson(nIdAjili)


		Conout(jSonCpg)

		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(JsonCpg),200,aHeader,@cHeaderGet)

		Conout("***[RESTCPG]***********************************************************************************************")

		Conout(cRetorno)

		wrk := JsonObject():new()
		wrk:fromJson(cRetorno)

		cRet := wrk:GetJsonText("id")

		ConOut("***[RESTCPG]*["+cRet+"]***********************************************************************************************************")   

		nSE4IdAjili := Val(cRet)

		Conout("***[RESTCPG]*[Id Ajili: "+Str(nSE4IdAjili,11,0)+"]**********************************************************************************************")

		Conout(cHeaderGet)

		_cStatus := Substr(cHeaderGet,10,3)

		Conout("Status da Inclusao: "+_cStatus)

		Conout("***[RESTCPG]**********************************************************************************************")

		If _cStatus $ "200#500#404" .And. nSE4IdAjili > 0 // Inclusão / Alteração / Reativação 
			Conout("***[RESTUSR]*[Cadastrado com Sucesso!]*****************************************************************")
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SE4" + QSE4->(E4_FILIAL+E4_CODIGO))
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SE4"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= QSE4->(E4_FILIAL+E4_CODIGO)	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= IIf(_cStatus=="500","Y","X")				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSE4IdAjili		//- Id de Integração Ajili
			MsUnlock()

		ElseIf _cStatus == "500"

		Else
			MsgAlert("Status " + _cStatus + " para condicao pagamento " + QSE4->E4_CODIGO )
		EndIf    
		Conout("***[RESTCPG]**********************************************************************************************")

		dbSelectArea("QSE4")
		dbSkip()
	Enddo
	QSE4->(DbCloseArea())

return 

Static Function sfMontaJson(nIdAjili)


	Local JsonCpg			 := ""

	Conout("***[RESTCPG]*[Entrou na Rotina de Monta Json]*******************************************************************")

	nFator := IIF(((QSE4->E4_ZFATFIN-1)*-1)==1,0,(QSE4->E4_ZFATFIN-1)*-1)

	JsonCpg := '{'
	JsonCpg += '"active": true,'
	JsonCpg += '"description": "'+QSE4->E4_CODIGO+"-"+QSE4->E4_DESCRI+'",'
	JsonCpg += '"discount": '+ cValToChar(nFator)+','
	If !Empty(nIdAjili)
		JsonCpg += '"id": ' + Alltrim(Str(nIdAjili)) + ','
	EndIF
	JsonCpg += '"idErp": "'+QSE4->E4_CODIGO+'",'
	JsonCpg += '"name": "'+QSE4->E4_CODIGO+"-"+QSE4->E4_DESCRI+'",'
	JsonCpg += '"rules": ""'
	JsonCpg += '}'

	Conout("***[RESTCPG]*[Montou o Json do Cond. de Pgto]***********************************************************************")

Return JsonCpg

//-----------------------------------------------
