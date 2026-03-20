#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} DECINUTI

Rotina para realizar inutilização de documentos.

@author TSCB57 - william.farias
@since 04/03/2020
@version 1.0
@example
(examples)
@see (links_or_references)
/*/

User Function DECINUTI()
	Local nQtdNfs	:= 0
	Local cNumIni	:= '000018000'
	Local cNumFim	:= '000777599'
	Local nDocIni	:= 0
	Local nDocFim	:= 0
	Local nUltDoc	:= 0
	Local cSerie	:= '1'
	Local nTam		:= 9
	Local cXmlRet	:= ''
	Local lRet 		:= .T. 
	Local nDe
	Local cLockName	:=	ProcName()

 	Local cAviso := "", cIdEnt, cUrl, nTpMonitor, cModelo, lCte, lUsaColab, nI
	Private lMsHelpAuto 		:= .T. //Variavel de controle interno do ExecAuto
	Private lMsErroAuto 		:= .F. //Variavel que informa a ocorrência de erros no ExecAuto

	If Type("cFilAnt") == "U" .OR. ( Type("cFilAnt") <> "U" .AND. cFilAnt <> '0103')
		RPCSETTYPE(3)
		RPCSetEnv("01","0103")
	EndIf

	If !LockByName(cLockName,.T.,.F.)
		conout("Rotina está sendo processada por outro usuário")
		Return
	EndIf
	//U_xMPad("DECINUTI","INFO","","----------- INICIO -----------")




	nQtdNfs	:= 100//Val(SuperGetMV('MV_ZQTINUT',,'1'))
	While lRet

		FwDateUpd(.F.)

		If !(cValToChar(dow(date()))$"6/7")
			conout("auto inutilzacao - não é sabado ou sexta-feira")
			exit 
		EndIf

		BeginSql alias "SF2INUT"
			SELECT max(F2_DOC) F2_DOC
			FROM %TABLE:SF2% SF2
			WHERE
					F2_FILIAL	=	%Exp:xFilial("SF2")%
				AND F2_DOC		>=	%Exp:cNumIni%
				AND F2_DOC		<=	%Exp:cNumFim%
				AND F2_SERIE	=	%Exp:cSerie%
		EndSql

		If SF2INUT->(!EoF())
			nUltDoc := Val(SF2INUT->F2_DOC)
			If  nUltDoc < Val(cNumIni) .Or. nUltDoc >= Val(cNumFim)
				SF2INUT->(dbCloseArea())
				conout("***********************************")
				CONOUT("     NÃO EXISTE MAIS NOTAS  - 1    ")
				conout("***********************************")
				Return
			Else
				nDocIni := nUltDoc+1
				nDocFim := nUltDoc+nQtdNfs
				If nDocFim > Val(cNumFim)
					nDocFim := Val(cNumFim)
				EndIf
			EndIf
		Else
			conout("***********************************")
			CONOUT("     NÃO EXISTE MAIS NOTAS    - 2  ")
			conout("***********************************")
			SF2INUT->(dbCloseArea())
			Return
		EndIf
		SF2INUT->(dbCloseArea())

		/*
		Posicoes do Array aAutoExec, utilizado quando rotina automatica:
		1 Serie da Inutilizacao
		2 Documento inicial
		3 Documento final
		4 Modelo da Nota Eletronica (NF-e, CT-e ou NFC-e)
		5 Rotina de Origem
		6 Flag se Inutilizacao ja transmitida
		7 Protocolo de inutilizacao
		8 Data de Inutilizacao
		9 Horario de Inutilizacao
		10 Retorno da Sefaz/Prefeitura
		*/
		aAutoExec := {cSerie,;
			PadR(StrZero(nDocIni, nTam),TamSx3("F2_DOC")[1]),;
			PadR(StrZero(nDocFim, nTam),TamSx3("F2_DOC")[1]),;
			"NF-e",;
			"DECINUTI",;
			.F.,,,,}

		Begin Transaction
			cXmlRet := "Executando!"+chr(13)+chr(10)+"Inicio: "+PadR(StrZero(nDocIni, nTam),TamSx3("F2_DOC")[1])+chr(13)+chr(10)+"Fim: "+PadR(StrZero(nDocFim, nTam),TamSx3("F2_DOC")[1])
			U_xMPad("DECINUTI","INFO","",cXmlRet)
			
			//FWMsgRun(, {|| MSExecAuto({|a,b,c,d,e| SpedNFeInut(a,b,c,d,e)}, "SF2",, 1,, aAutoExec) }, "Processando", "Inutilizando faixa de "+PadR(StrZero(nDocIni, nTam),TamSx3("F2_DOC")[1])+ " ate" + PadR(StrZero(nDocFim, nTam),TamSx3("F2_DOC")[1]))
			MsgRun("Inutilizando faixa de "+PadR(StrZero(nDocIni, nTam),TamSx3("F2_DOC")[1])+ " ate" + PadR(StrZero(nDocFim, nTam),TamSx3("F2_DOC")[1]) ,"Aguarde",{|| MSExecAuto({|a,b,c,d,e| SpedNFeInut(a,b,c,d,e)}, "SF2",, 1,, aAutoExec) })

			If lMsErroAuto
				DisarmTransaction()
				aErroAuto := GetAutoGrLog()
				//Armazena mensagens de erro
				cXmlRet := "Ocorreu um erro ao efetuar a inutilizacao:"+chr(13)+chr(10)
				cXmlRet := "<![CDATA["
				For nI := 1 To Len(aErroAuto)
					cXmlRet += aErroAuto[nI] + Chr(10)
				Next nI
				cXmlRet += "]]>"
				U_xMPad("DECINUTI","ERROR","",cXmlRet)
				lRet 	:= .F. 
				//MsUnLockAll()
			Else
				cXmlRet := "Inutilizacao efetuada com sucesso!"+chr(13)+chr(10)+"Inicio: "+PadR(StrZero(nDocIni, nTam),TamSx3("F2_DOC")[1])+chr(13)+chr(10)+"Fim: "+PadR(StrZero(nDocFim, nTam),TamSx3("F2_DOC")[1])
				U_xMPad("DECINUTI","INFO","",cXmlRet)
			EndIf
		End Transaction
	EndDo

	// busca notas sem monitoramento
	Beginsql alias "TRMAX"
		SELECT MAX(F3_NFISCAL) ATE,MIN(F3_NFISCAL) DE
		FROM SF3010  (nolock)
		WHERE F3_FILIAL = %xfilial:SF3%
		AND F3_NFISCAL BETWEEN %exp:cNumIni%	AND %exp:cNumFim%
		and F3_SERIE = %exp:cSerie%
		AND F3_DESCRET = ''
		and substring(F3_CFO,1,1) >='5'
	EndSql
	
   
    nDe:= val(TRMAX->DE)
    nAte:= val(TRMAX->ATE)
	nTpMonitor := 1
    cModelo := "55"
    lCte:= .F.
    lUsaColab := .F.
    //cIdEnt 		:= GetIdEnt(lUsaColab)
    cUrl			:= Padr( GetNewPar("MV_SPEDURL",""), 250 )

    oWS := WsSPEDAdm():New()
    oWS:cUSERTOKEN := "TOTVS"

    oWS:oWSEMPRESA:cCNPJ       := IIF(SM0->M0_TPINSC==2 .Or. Empty(SM0->M0_TPINSC),SM0->M0_CGC,"")
    oWS:oWSEMPRESA:cCPF        := IIF(SM0->M0_TPINSC==3,SM0->M0_CGC,"")
    oWS:oWSEMPRESA:cIE         := SM0->M0_INSC
    oWS:oWSEMPRESA:cIM         := SM0->M0_INSCM
    oWS:oWSEMPRESA:cNOME       := SM0->M0_NOMECOM
    oWS:oWSEMPRESA:cFANTASIA   := SM0->M0_NOME
    oWS:oWSEMPRESA:cENDERECO   := FisGetEnd(SM0->M0_ENDENT)[1]
    oWS:oWSEMPRESA:cNUM        := FisGetEnd(SM0->M0_ENDENT)[3]
    oWS:oWSEMPRESA:cCOMPL      := FisGetEnd(SM0->M0_ENDENT)[4]
    oWS:oWSEMPRESA:cUF         := SM0->M0_ESTENT
    oWS:oWSEMPRESA:cCEP        := SM0->M0_CEPENT
    oWS:oWSEMPRESA:cCOD_MUN    := SM0->M0_CODMUN
    oWS:oWSEMPRESA:cCOD_PAIS   := "1058"
    oWS:oWSEMPRESA:cBAIRRO     := SM0->M0_BAIRENT
    oWS:oWSEMPRESA:cMUN        := SM0->M0_CIDENT
    oWS:oWSEMPRESA:cCEP_CP     := Nil
    oWS:oWSEMPRESA:cCP         := Nil
    oWS:oWSEMPRESA:cDDD        := Str(FisGetTel(SM0->M0_TEL)[2],3)
    oWS:oWSEMPRESA:cFONE       := AllTrim(Str(FisGetTel(SM0->M0_TEL)[3],15))
    oWS:oWSEMPRESA:cFAX        := AllTrim(Str(FisGetTel(SM0->M0_FAX)[3],15))
    oWS:oWSEMPRESA:cEMAIL      := UsrRetMail(RetCodUsr())
    oWS:oWSEMPRESA:cNIRE       := SM0->M0_NIRE
    oWS:oWSEMPRESA:dDTRE       := SM0->M0_DTRE
    oWS:oWSEMPRESA:cNIT        := IIF(SM0->M0_TPINSC==1,SM0->M0_CGC,"")
    oWS:oWSEMPRESA:cINDSITESP  := ""
    oWS:oWSEMPRESA:cID_MATRIZ  := ""
    oWS:oWSOUTRASINSCRICOES:oWSInscricao := SPEDADM_ARRAYOFSPED_GENERICSTRUCT():New()
    oWS:_URL := AllTrim(cURL)+"/SPEDADM.apw"
    If oWs:ADMEMPRESAS()
        cIdEnt  := oWs:cADMEMPRESASRESULT
    Else
        conout(IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)))
        return
    EndIf



    For nDe := nDe To nAte STEP nQtdNfs
       FwDateUpd(.F.)
        aParam := {padr('1',3),StrZero(nDe,9),StrZero(nDe+nQtdNfs,9)}
        cTimeIniBB		:=	TIME()
        procMonitorDoc(cIdEnt, cUrl, aParam, nTpMonitor, cModelo, lCte, @cAviso ,lUsaColab)
       
         conout(" monitoramento = "+cValtochar(nDe)+"   "+cValTochar(nDe+nQtdNfs)+"               tempo total:"+ elaptime(cTimeIniBB,Time()))
    Next

	(TRMAX)->(dbCloseArea())
	//U_xMPad("DECINUTI","INFO","","-----------  FIM   -----------")
	
	UnLockByName(cLockName,.T.,.F.)
	
	RpcClearEnv()

Return
