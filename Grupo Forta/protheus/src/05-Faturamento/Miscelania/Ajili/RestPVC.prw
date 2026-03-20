#include "totvs.ch"
#include "tbiconn.ch"

User Function Rest1Pvc(cInNumPed)

Private cNomRot		:= "RESTPVC_"+cFilAnt


Return sfRodaPVC(cInNumPed)



User function RestPVC(aParam)

	Local	lRet 		:= .F.
	Local	nWaitSec	:= 0
	Default	cInCodLj	:= ""
	Private lDebug		:= .F.
	Private cNomRot		:= "RESTPVC_"+cFilAnt

	/// Mensagem de saída no Consol
	ConOut("+-"+Replicate("-",100)+"+")
	ConOut("| "+Padr(cNomRot + " " + FunName() + "." + ProcName(0) + "-" + Alltrim(Str(ProcLine(0))) ,100) +"|")
	ConOut("| "+Padr(cNomRot + " Inicio " + DTOC(Date()) + " " + Time(),100) +"|")
	ConOut("| "+Padr(cNomRot + " Empresa Logada: " + cEmpAnt,100)+"|")
	ConOut("| "+Padr(cNomRot + " Filial Logada : " + cFilAnt,100)+"|")
	VarInfo(cNomRot+".Valores passados via aParam",aParam)

	//If GetNewPar("GF_AJILIOK",.T.)

	While !lRet


		If lRet	:= LockByName(cNomRot,.T.,.T.)
			Processa({|| sfRodaPVC() },"Processando pedidos...")
			UnLockByName(cNomRot,.T.,.T.)

		Else
			MsAguarde({|| Sleep( 1 * 1000) }, "Aguarde " + cValToChar(10-nWaitSec) + " segundos! Exportação pedidos já em execução!")
			nWaitSec ++
			ConOut("|"+Padr("["+cNomRot+"]Job ja esta em execucao. Tentativa " + cValToChar(nWaitSec) ,100)+"|")

			// Havendo mais de 10 tentativas de espera por 1 segundos cada, aborta o processo
			If nWaitSec  >= 10
				lRet	:= .T.
				Exit
			Endif
		Endif
	Enddo
	//Endif
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


Static Function sfRodaPVC(cInNumPed)

	Local 	cURL		    := Alltrim(GetNewPar("GF_AJ_URL",""))
	Local 	cAcesso         := "/api/pedidos/"
	Local 	cAcess2			:= "/status"
	Local	cApiKey			:= "?api_key=" + Alltrim(GetNewPar("GF_AJ_KEY",""))

	Local 	aHeader         := {}
	Local 	cHeaderGet      := ""
	Local 	nRec			:= 0
	Local 	nRecAtu			:= 0
	Default cInNumPed		:= ""

	//aadd(aHeader,'Content-Type: application/json')
	//Aadd(aHeader, "Accept: application/json")

	// Monta o header HTTP de saída, comum a todas as requisições
	aadd(aHeader,'Content-Type: application/x-www-form-urlencoded')
	aadd(aHeader,'Accept-Charset: UTF-8')
	aadd(aHeader,'User-Agent: Mozilla/4.0 (compatible; Protheus '+GetBuild()+')')

	_xFil := xFilial("SC5")


	dbSelectArea("SC5")
	dbSetOrder(1)
	If !Empty(cInNumPed) .And. DbSeek(_xFil+cInNumPed)

		cJsonPVC := sfCriaJson()

		ConOut("["+cNomRot+"][httppost]["+ cURL+cAcesso+ cValToChar(SC5->C5_IDAJILI) + cAcess2 + cApiKey + cJsonPVC+ "][JSON HTTPPOST]["+cJsonPVC+"]}")

		//MsgAlert(JsonPVC)

		//MemoWrite("c:\edi\restpvc.txt",cURL+cAcesso+ cValToChar(SC5->C5_IDAJILI) + cAcess2 + cApiKey + cJsonPVC )

		//cRetorno := HttpPost( cURL+cAcesso+ cValToChar(SC5->C5_IDAJILI) + cAcess2 + cApiKey + encodeUTF8(cJsonPVC),"",,200,aHeader,@cHeaderGet)

		cRetorno := HttpPost( cURL+cAcesso+ cValToChar(SC5->C5_IDAJILI) + cAcess2 + cApiKey + cJsonPVC,"",,200,aHeader,@cHeaderGet)

		ConOut("["+cNomRot+"][RETORNO]["+cRetorno+"]")

		_cStatus := Substr(cHeaderGet,10,3)

		If _cStatus=="200"
			Conout("***[RESTPVC]*[Cadastrado com Sucesso!]*****************************************************************")
			RecLock("SC5",.F.)
			SC5->C5_MSEXP	:= DTOS(dDataBase)
			MsUnLock()

		EndIf
		Conout("***[RESTPVC]**********************************************************************************************")
	Else
		// Pedidos dos últimos 30 dias e com Id Ajili
		Set Filter To C5_FILIAL == _xFil .And. !Empty(C5_IDAJILI) .And. C5_EMISSAO > (Date()-120)

		Count To nRec

		ProcRegua(nRec)

		SC5->(DbGotop())

		While !Eof() .And. SC5->C5_FILIAL == _xFil

			nRecAtu ++
			IncProc("Registro " + cValToChar(nRecAtu) + " de " + cValToChar(nRec)  )

			cJsonPVC := sfCriaJson()

			ConOut("["+cNomRot+"][JSON HTTPPOST]["+cJsonPVC+"]}")

			cRetorno := HttpPost( cURL+cAcesso+ cValToChar(SC5->C5_IDAJILI) + cAcess2 + cApiKey + cJsonPVC,"",,200,aHeader,@cHeaderGet)
			//msgalert(cRetorno)

			//If msgyesno("deseja sair?")
			//	Return
			//Endif

			ConOut("["+cNomRot+"][RETORNO]["+cRetorno+"]")


			_cStatus := Substr(cHeaderGet,10,3)

			If _cStatus=="200"
				Conout("***[RESTPVC]*[Cadastrado com Sucesso!]*****************************************************************")
				RecLock("SC5",.F.)
				SC5->C5_MSEXP	:= DTOS(dDataBase)
				MsUnLock()
			EndIf
			Conout("***[RESTPVC]**********************************************************************************************")

			dbSelectArea("SC5")
			dbSkip()

		Enddo
	Endif
Return


Static Function sfCriaJson()

	Local 	cRetJson	:= ''
	Local 	cMsgPed		:= ""
	//Local 	cMsgInt		:= ""

	/*
	cRetJson += '{'
	cRetJson += '"order": { '
	//cRetJson += '"approvalStatus": '+cStatus+','
	cRetJson += '"notes": "teste",'
	cRetJson += '"notesErp": "teste" '
	cRetJson += '         }'
	cRetJson += '}'
	*/
	DbSelectArea("SA4")
	DbSetOrder(1)
	DbSeek(xFilial("SA4")+SC5->C5_TRANSP)

	cMsgPed	:= "Transportadora: " + SC5->C5_TRANSP + "-" + Alltrim(SA4->A4_NREDUZ) + "<br>"

	
	DbSelectArea("SX5")
	DbSetOrder(1)
	If DbSeek(xFilial("SX5")+ "XA" + SC5->C5_ZSTATS )	
		cMsgPed += "Status Atual Pedido: " + SC5->C5_ZSTATS  +"-" + Alltrim(SX5->X5_DESCRI)+"<br>"
	Endif 
	// select z0_filial,z0_tipo,z0_conteud,count(*)
	//from sz0010
	//WHERE Z0_TIPO IN('IP','CN','NF','CP','ER','EP')
	//AND Z0_FILIAL = '0101'
	//group by z0_filial,z0_tipo,z0_conteud
	cAliasDp	:= GetNextAlias()

	BeginSql Alias cAliasDp
		COLUMN Z0_DATA AS DATE
		SELECT Z0_DATA,Z0_HORA,Z0_TIPO,Z0_CONTEUD
		  FROM %Table:SZ0% SZ0
         WHERE Z0_FILIAL = %xFilial:SZ0%
           AND SZ0.%NotDel%
		   AND Z0_TIPO IN('IP','CN','NF','CP','ER','EP','BT','BF','BA','LC','LR')
           AND Z0_PEDIDO =  %Exp:SC5->C5_NUM%
		 ORDER BY Z0_DATA,Z0_HORA 
	EndSql

	While !Eof()
		cMsgPed += DTOC((cAliasDp)->Z0_DATA) + "-" + (cAliasDp)->Z0_HORA + " " +  (cAliasDp)->Z0_TIPO+"/" + Alltrim((cAliasDp)->Z0_CONTEUD) + "<br>"
		(cAliasDp)->(DbSkip())
	Enddo
	(cAliasDp)->(DbCloseArea())

	//ER - Eliminação de Resíduos
	//CP - Conferência/Emissão Etiquetas
	//CN - Cancelamento NotaFiscal/Pedido
	//NF - Gerada Nota Fiscal Doc.Saída
	//EP - Exclusão do Pedido
	//IP - Inclusão de Pedido
	//BT - Bloqueio/Pendência Comercial
	//BF - Bloqueio/Pendência Financeira
	//BA - Bloqueio/Pagto Antecipado"	
	//LA - Liberação/Pgto Antecipado
	//LC - Liberação Crédito
	//LR - Pedido Rejeitado

	BeginSql Alias cAliasDp
		COLUMN F2_EMISSAO AS DATE
		COLUMN XML_EMISSA AS DATE 
		SELECT DISTINCT F2_DOC,F2_SERIE,F2_FILIAL,F2_EMISSAO,F2_TRANSP,F2_VALBRUT,
		       XCN_CHVCTE,XCN_NUMCTE,
			   XML_EMISSA,XML_EMIT,XML_NOMEMT,
			   XEV_EVENT,XEV_SEQEVE,XEV_DESEVE,XEV_EMTNOM,COALESCE(XEV_DTAUT,' ') XEV_DTAUT,XEV_HRAUT,COALESCE(XEV_DTENTR,' ') XEV_DTENTR,XEV_HRENTR
          FROM %Table:SF2% F2 
         INNER JOIN %Table:SD2% D2
            ON D2.D_E_L_E_T_ =' '
           AND D2_CLIENTE = F2_CLIENTE
           AND D2_LOJA = F2_LOJA 
		   AND D2_SERIE = F2_SERIE
           AND D2_DOC = F2_DOC
           AND D2_FILIAL = %xFilial:SD2%
	      LEFT JOIN CONDORCTEXNFS XA
            ON XCN_CHVNFS = F2_CHVNFE
          LEFT JOIN CONDORXML XB
            ON XML_CHAVE = XCN_CHVCTE
          LEFT JOIN CONDOREVENTOS XC
            ON XEV_CHAVE = XCN_CHVCTE 
           AND XB.D_E_L_E_T_ =' '
         WHERE F2.D_E_L_E_T_  = ' '
           AND F2_FILIAL = %xFilial:SF2%
           AND D2_PEDIDO =  %Exp:SC5->C5_NUM%
	     ORDER BY F2_DOC,XEV_DTAUT,XEV_HRAUT,XEV_EVENT,XEV_SEQEVE
	EndSql

	If !Eof()
		cMsgPed += "Nota Fiscal: " + (cAliasDp)->F2_DOC + " Emissão: " + DTOC((cAliasDp)->F2_EMISSAO) + " R$ " + Alltrim(Transform((cAliasDp)->F2_VALBRUT,"@E 999,999.99"))+ "<br>"

		While !Eof()
			If !Empty((cAliasDp)->XEV_DTENTR)
				cMsgPed += DTOC(STOD((cAliasDp)->XEV_DTENTR)) + "-" + (cAliasDp)->XEV_HRENTR + " " +  (cAliasDp)->XEV_EVENT+ "-"+(cAliasDp)->XEV_SEQEVE +"/" + Alltrim((cAliasDp)->XEV_DESEVE) + Chr(13) + Chr(10)
			ElseIf !Empty((cAliasDp)->XEV_DTAUT)
				cMsgPed += DTOC(STOD((cAliasDp)->XEV_DTAUT)) + "-" + (cAliasDp)->XEV_HRAUT + " " +  (cAliasDp)->XEV_EVENT + "-"+(cAliasDp)->XEV_SEQEVE+"/" + Alltrim((cAliasDp)->XEV_DESEVE) + Chr(13) + Chr(10)
			Endif 
			(cAliasDp)->(DbSkip())
		Enddo
	Endif

	(cAliasDp)->(DbCloseArea())

	//cMsgInt	 := SC5->C5_ZMSGINT
	// Monta os parametros para URL / GET
	//cRetJson := '&notes=' + UrlEncode(EncodeUtf8(cMsgInt)) // Não sobe informação devolta 
	cRetJson += '&notesErp=' + UrlEncode(EncodeUtf8(cMsgPed))  // + UrlEncode(EncodeUtf8(" Msg.Interna: "+cMsgInt))
	If !Empty(SC5->C5_ZSTATS) .And.  sfStsDePara(SC5->C5_ZSTATS) > 0 
		cRetJson += '&customApprovalStatusId=' + UrlEncode(EncodeUtf8(cValToChar(sfStsDePara(SC5->C5_ZSTATS)))) 
	Else 
		cRetJson += '&customApprovalStatusId=' + UrlEncode(EncodeUtf8(cValToChar(sfStsDePara("999"))))
	Endif 
	
Return cRetJson


Static Function sfStsDePara(cInMotErp)

	Local 	aStsVellis 		:= {} 
	Local 	nOutMotVellis 	:= 0

	If cFilAnt $ "0601" // Baume - baume.ajili.com.br 
		//	ID	Nome	Baseado no status de aprovação	ID ERP
		Aadd(aStsVellis,{6,"Em avaliação de Crédito"		,"Aguardando aprovação"	,"200"})
		Aadd(aStsVellis,{7,"F-AG. LIB CLIENTE"				,"Aguardando aprovação"	,"201"})
		Aadd(aStsVellis,{5,"F-CRÉDITO BLOQUEADO"			,"Reprovado"			,"202"})
		Aadd(aStsVellis,{8,"F-EM CLASSIFICAÇÃO"				,"Aguardando aprovação"	,"000"})
		Aadd(aStsVellis,{2,"F-FALTA ESTOQUE"				,"Reprovado"			,"004"})
		Aadd(aStsVellis,{9,"F-FATURADO"						,"Aprovado"				,"002"})
		Aadd(aStsVellis,{3,"F-LIBERADO FATURAMENTO"			,"Aprovado"				,"001"})
		Aadd(aStsVellis,{15,"INDEFINIDO"					,"Aguardando aprovação"	,"999"})
		Aadd(aStsVellis,{1,"RES-CREDITO NEGADO"				,"Reprovado"			,"102"})
		Aadd(aStsVellis,{11,"RES-DESISTÊNCIA CLIENTE"		,"Reprovado"			,"103"})
		Aadd(aStsVellis,{12,"RES-FALTA DE ESTOQUE"			,"Reprovado"			,"106"})
		Aadd(aStsVellis,{4,"RES-FORTA REGRAS CML"			,"Aprovado"				,"105"})
		Aadd(aStsVellis,{13,"RES-SALDO INSUFICIENTE PAGTO"	,"Reprovado"			,"104"})
		Aadd(aStsVellis,{10,"RES-TESTE SISTEMA"				,"Reprovado"			,"101"})
		Aadd(aStsVellis,{14,"S-EM ASSISTÊNCIA TÉCNICA"		,"Reprovado"			,"400"})
	
	ElseIf cFilAnt $ "0201" // fta condor1.ajili.com.br 
		Aadd(aStsVellis,{14,"Em Avaliação de Crédito"		,"Aguardando aprovação"	,"200"})
		Aadd(aStsVellis,{1,"F-AG. LIB.CLIENTE"				,"Aguardando aprovação"	,"201"})
		Aadd(aStsVellis,{4,"F-AG.ESTOQUE"					,"Reprovado"			,"004"})
		Aadd(aStsVellis,{2,"F-CREDITO BLOQUEADO"			,"Reprovado"			,"202"})
		Aadd(aStsVellis,{3,"F-EM CLASSIFICACAO"				,"Aguardando aprovação"	,"000"})
		Aadd(aStsVellis,{5,"F-FATURADO"						,"Aprovado"				,"002"})
		Aadd(aStsVellis,{6,"F-LIBERADO FATURAMENTO"			,"Aprovado"				,"001"})
		Aadd(aStsVellis,{15,"INDEFINIDO"					,"Aguardando aprovação"	,"999"})
		Aadd(aStsVellis,{8,"RES-CREDITO NEGADO"				,"Reprovado"			,"102"})
		Aadd(aStsVellis,{9,"RES-DESISTENCIA CLIENTE"		,"Reprovado"			,"103"})
		Aadd(aStsVellis,{10,"RES-FALTA ESTOQUE"				,"Reprovado"			,"106"})
		Aadd(aStsVellis,{11,"RES-PED FORA REG CML"			,"Reprovado"			,"105"})
		Aadd(aStsVellis,{12,"RES-SALDO INSUF PGTO"			,"Reprovado"			,"104"})
		Aadd(aStsVellis,{7,"RES-TESTE SISTEMA"				,"Reprovado"			,"101"})
		Aadd(aStsVellis,{13,"S-ASS TECNICA"					,"Reprovado"			,"400"})
	ElseIf cFilAnt $ "0101" // tech tech.ajili.com.br 
		Aadd(aStsVellis,{6,"Em avaliação de Credito"		,"Aguardando aprovação"	,"200"})
		Aadd(aStsVellis,{7,"F-AG. LIB CLIENTE"				,"Aguardando aprovação"	,"201"})
		Aadd(aStsVellis,{5,"F-CREDITO BLOQUEADO"			,"Reprovado"			,"202"})
		Aadd(aStsVellis,{8,"F-EM CLASSIFICAÇÃO"				,"Aguardando aprovação"	,"000"})
		Aadd(aStsVellis,{2,"F-FALTA ESTOQUE"				,"Reprovado"			,"004"})
		Aadd(aStsVellis,{9,"F-FATURADO"						,"Aprovado"				,"002"})
		Aadd(aStsVellis,{3,"F-LIBERADO FATURAMENTO"			,"Aprovado"				,"001"})
		Aadd(aStsVellis,{15,"INDEFINIDO"					,"Aguardando aprovação"	,"999"})
		Aadd(aStsVellis,{1,"RES-CREDITO NEGADO"				,"Reprovado"			,"102"})
		Aadd(aStsVellis,{11,"RES-DESISTENCIA CLIENTE"		,"Reprovado"			,"103"})
		Aadd(aStsVellis,{12,"RES-FALTA ESTOQUE"				,"Reprovado"			,"106"})
		Aadd(aStsVellis,{4,"RES-FORTA REGRAS CML"			,"Aprovado"				,"105"})
		Aadd(aStsVellis,{13,"RES-SALDO INSUFICIENTE PGTO"	,"Reprovado"			,"104"})
		Aadd(aStsVellis,{10,"RES-TESTE SISTEMA"				,"Reprovado"			,"101"})
		Aadd(aStsVellis,{14,"S-EM ASSISTENCIA TECNICA"		,"Reprovado"			,"400"})
	ElseIf cFilAnt $ "0401" // DC condor2.ajili.com.br 
		Aadd(aStsVellis,{9,"DESISTENCIA CLIENTE"			,"Reprovado"			,"103"})
		Aadd(aStsVellis,{1,"F01-AG. LIB CLIENTE"			,"Aguardando aprovação"	,"201"})
		Aadd(aStsVellis,{2,"F02-CREDITO BLOQUEADO"			,"Reprovado"			,"202"})
		Aadd(aStsVellis,{3,"F03-EM CALSSIFICAÇÃO"			,"Aguardando aprovação"	,"000"})
		Aadd(aStsVellis,{4,"F04-FALTA ESTOQUE"				,"Reprovado"			,"004"})
		Aadd(aStsVellis,{5,"F05-FATURADO"					,"Aprovado"				,"002"})
		Aadd(aStsVellis,{6,"F06-LIBERADO FATURAMENTO"		,"Aprovado"				,"001"})
		Aadd(aStsVellis,{8,"R01-CREDITO NEGADO"				,"Reprovado"			,"102"})
		Aadd(aStsVellis,{10,"R02-FALTA ESTOQUE"				,"Reprovado"			,"106"})
		Aadd(aStsVellis,{11,"R03-REJEICAO COMERCIAL"		,"Reprovado"			,"105"})	
		Aadd(aStsVellis,{12,"R04-SALDO INSUFICIENTE PAGAMENTO","Reprovado"			,"104"})
		Aadd(aStsVellis,{7,"R05-TESTE SISTEMA"				,"Reprovado"			,"101"})
		Aadd(aStsVellis,{13,"S-EM ASSISTENCIA TECNICA"		,"Reprovado"			,"400"})
	Endif 

	// Verifica se existe o registro e retorna o id Vellis 
	If aScan( aStsVellis , { |x| AllTrim( x[4] ) == cInMotErp  } ) > 0 
		nOutMotVellis	:= aStsVellis[aScan( aStsVellis , { |x| AllTrim( x[4] ) == cInMotErp  } )][1]
	Endif 

Return nOutMotVellis

/*/{Protheus.doc} URLEncode
Função para converter string no formato URLCode 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 24/02/2022
@param cValue, character, param_description
@return variant, return_description
/*/
Static Function URLEncode(cValue)

	Local nI , cRet := '', cChar
	
	For nI := 1 to len(cValue)
		cChar := substr(cValue,nI,1)
		IF asc(cChar) < 32
			IF asc(cChar) == 13 // ( CR - Ignora )
				LOOP
			ElseIF asc(cChar) == 10 // ( LF - TRoca para "\n" )
				cRet += '**'
				// Converte para hexadecimal, formato %HH
				cRet += '%'+PADL(Upper(__DecToHex(asc(cChar))),2,'0')
			Else
				// Converte para hexadecimal, formato %HH
				cRet += '%'+PADL(Upper(__DecToHex(asc(cChar))),2,'0')
			Endif
		ElseIf cChar >= ' ' .and. cChar <= '/'
			// Converte para hexadecimal, formato %HH
			cRet += '%'+PADL(Upper(__DecToHex(asc(cChar))),2,'0')
		ElseIf cChar >= '0' .and. cChar <= '9'
			cRet += cChar
		ElseIf cChar >= 'A' .and. cChar <= 'Z'
			cRet += cChar
		ElseIf cChar >= 'a' .and. cChar <= 'z'
			cRet += cChar
		Else
			// Converte para hexadecimal, formato %HH
			cRet += '%'+PADL(Upper(__DecToHex(asc(cChar))),2,'0')
		Endif
	Next
Return cRet
