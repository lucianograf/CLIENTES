#include "totvs.ch"
#include "tbiconn.ch"
#include "topconn.ch"

User function RestFpg()

	Local	lRet 	:= LockByName("RESTFPG",.T.,.F.,.T.)

	If lRet

		Conout("***[Inicio RESTFPG "+time()+"]************************************************************************")

		sfRodaFpg()		

		Conout("***[Fim RESTFPG "+time()+"]****************************************************************************")

	Else
		Conout("*****[Job RESTFPG ja esta em execucao]***********************************************")  			
	Endif

Return

Static Function sfRodaFpg()

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/paymentForms?"
	Local	cApiKey			:= "api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))
	Local 	aHeader         := {}	
	Local 	cHeaderGet      := ""
	Local aFormasPgto		 := {{"341","Banco","Cobrança Bancária"}}
	Local iX 
	
	Aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader, "Accept: application/json")

	
	For iX := 1 To Len(aFormasPgto)

		nIdAjili		:= 0

		DbSelectArea("Z00")
		DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
		If DbSeek(xFilial("Z00") + "SA6" + xFilial("SA6") + aFormasPgto[iX,1])
			nIdAjili		:= Z00->Z00_IDAJIL
		Endif
		//sfMontaJson(nIdAjili,cInName,cInDescricao)
		JsonFpg := sfMontaJson(nIdAjili,aFormasPgto[iX,2],aFormasPgto[iX,3])
		Conout(JsonFpg)

		Conout("***[RESTFPG]*[Vai enviar via HTTP Post o Json]*************************************************************")

		cRetorno := HttpPost( cURL+cAcesso+cApiKey,"",encodeUTF8(JsonFpg),200,aHeader,@cHeaderGet)

		wrk := JsonObject():new()
		wrk:fromJson(cRetorno)

		cRet := wrk:GetJsonText("id")
		
		Conout(cRetorno)
 
				
		ConOut("***[RESTFPG]*["+cRetorno+"]***********************************************************************************************************")   

		nSA6IdAjili := Val(cRet)

		Conout("***[RESTFPG]*[Id Ajili: "+Str(nSA6IdAjili,11,0)+"]**********************************************************************************************")

		Conout(cHeaderGet)

		_cStatus := Substr(cHeaderGet,10,3)

		Conout("Status da Inclusao: "+_cStatus)


		If _cStatus $ "200#500#404" .And. nSA6IdAjili > 0 // Inclusão / Alteração / Reativação 
			Conout("***[RESTUSR]*[Cadastrado com Sucesso!]*****************************************************************")
			DbSelectArea("Z00")
			DbSetOrder(1)//Z00_FILIAL+Z00_ENTIDA+Z00_CHAVE
			If DbSeek(xFilial("Z00") + "SA6" + xFilial("SA6") + aFormasPgto[iX,1])
				//nIdAjili		:= Z00->Z00_IDAJIL
				RecLock("Z00",.F.)
			Else
				RecLock("Z00",.T.)

			Endif
			Z00->Z00_FILIAL 	:= xFilial("Z00")	//- Filial
			Z00->Z00_ENTIDA 	:= "SA6"			//- Entidade
			Z00->Z00_NCHAVE 	:= 1				//- Indice da Entidade 
			Z00->Z00_CHAVE  	:= xFilial("SA6")+ aFormasPgto[iX,1]	//- Chave de pesquisa/relação 
			Z00->Z00_INTEGR 	:= "X"				//- Status Integração
			Z00->Z00_IDAJIL 	:= nSA6IdAjili		//- Id de Integração Ajili
			MsUnlock()

		ElseIf _cStatus == "500"

		Else
			MsgAlert("Status " + _cStatus + " para banco " + cFilAnt + aFormasPgto[iX,1])
		EndIf    		
	Next

Return


Static Function sfMontaJson(nIdAjili,cInName,cInDescricao)

	Local JsonFpg			 := ""
	
	Conout("***[RESTFPG]*[Entrou na Rotina de Monta Json]*******************************************************************")

	JsonFpg := '{'
	JsonFpg += '"active": true,'
	JsonFpg += '"description": "'+cInDescricao+'",
	If !Empty(nIdAjili)
		JsonFpg += '"id": '+Str(nIdAjili)+','
	EndIF
	JsonFpg += '"name": "'+cInName+'"'
	JsonFpg += '}'
	Conout("***[RESTFPG]*[Montou o Json do Forma de Pgto]***********************************************************************")

Return JsonFpg


