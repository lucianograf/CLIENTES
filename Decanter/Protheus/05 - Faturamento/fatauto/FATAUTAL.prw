#include "TOTVS.CH"
#INCLUDE "TOPCONN.ch"
#include 'parmtype.ch'
#Include "RptDef.CH"
#INCLUDE "FWPrintSetup.ch"
//#DEFINE IMP_SPOOL     2	

User Function FATAUTAL(aInEmp)
	//U_FATAUTAL({'01','0101','000000','000056000091'})
	Local 	_cEmp	:= cEmpAnt //aInEmp[1]
	Local 	_cFil	:= cFilAnt // aInEmp[2]"

	Local 	_lEmp	:= veremp(_cEmp,_cFil)

	If LockByName("FATAUTAL"+_cEmp+_cFil,.F.,.F.,.T.)
		// Primeira tarefa - GErar as notas Fiscais
		ConOut("FATAUTAL - sfGerNfs")
		sfGerNfs()
		// Aguarda 5 segundos
		Sleep(5*1000)
		// Segunda tarefa - Transmissão das notas
		ConOut("FATAUTAL - sfTrsNfs")
		sfTrsNfs()
		// Aguarda 20 Segundos
		Sleep(20*1000)
		// Terceira Tarefa - Monitora as notas
		ConOut("FATAUTAL - sfMonNfs")
		sfMonNfs()

		// Quarta Tarefa - Impressão das notas
		//sfPrtNfs() - impressão irá ocorrer por outra chamada

		UnLockByName("FATAUTAL"+_cEmp+_cFil,.F.,.F.,.T.)
	Endif
	fechemp(_lEmp)
Return

Static Function SchedDef()
	// aReturn[1] - Tipo
	// aReturn[2] - Pergunte
	// aReturn[3] - Alias
	// aReturn[4] - Array de ordem
	// aReturn[5] - Titulo
Return { "P", "FATAUTAL", "", {}, "" }

//Fat
//#####################
User Function FATAUT0(_aEmp)
	Local _lEmp:= .F.
	Default _aEmp:={"01","0101"}
	_cEmp:=_aEmp[1]
	_cFil:=_aEmp[2]
	_lEmp:= veremp(_cEmp,_cFil)
	If GlbLock()
		sfGerNfs()
		GlbUnlock()
	endif
	fechemp(_lEmp)
Return
//Transmite
//#####################
User Function FATAUT1(_aEmp)
	Local _lEmp:= .F.
	Default _aEmp:={"01","0101"}
	_cEmp:=_aEmp[1]
	_cFil:=_aEmp[2]
	_lEmp:= veremp(_cEmp,_cFil)
	If GlbLock()
		sfTrsNfs()
		GlbUnlock()
	endif
	fechemp(_lEmp)
Return
//Monitora
//#####################
User Function FATAUT2(_aEmp)
	Local _lEmp:= .F.
	Default _aEmp:={"01","0101"}
	_cEmp:=_aEmp[1]
	_cFil:=_aEmp[2]

	_lEmp:= veremp(_cEmp,_cFil)
	If GlbLock()
		sfMonNfs()
		GlbUnlock()
	endif
	fechemp(_lEmp)
Return
//Imprime
//#####################
// User Function FATAUT3(_cEmp,_cFil)
User Function FATAUT3(_aEmp)
	Local _lEmp:= .F.
	// Default _cEmp:="01"
	// Default _cFil:="0101"
	Default _aEmp:={"01","0101"}
	_cEmp:=_aEmp[1]
	_cFil:=_aEmp[2]
	
	conout("FATAUT3")
	conout(_cEmp)
	conout(_cFil)
	_lEmp:= veremp(_cEmp,_cFil)
	If GlbLock()
		sfPrtNfs()
		GlbUnlock()
	endif
	fechemp(_lEmp)
Return

/*/{Protheus.doc} veremp
	(long_description)
/*/
Static Function veremp(_cEmp,_cFil)
	Local _lSetEnv := .F.
	Default _cEmp:="01"
	Default _cFil:="0101"

	if Type("cEmpAnt")=="U"
		_lSetEnv := .T.
		RpcSetType(3)
		RPCSetEnv(_cEmp,_cFil, "FILIAL")
	endif
Return _lSetEnv

/*/{Protheus.doc} fechemp
	(long_description)
/*/
Static Function fechemp(_lSetEnv)
	if _lSetEnv
		RpcClearEnv()
	endif
Return

/*/{Protheus.doc} executa
  (long_description)
  @type  Static Function
  @author user
  @since 19/09/2022
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)-
  @see (links_or_references)
/*/
Static Function executa()

	Local cRetSef:= ""
	Default cGrupo:= "01"
	Default cCodFil:="0101"
	Default cSerie:=Padr(SUPERGETMV("DC_SERFATA",.F.,"1  "),3)
	Default nQtdCop:=1
	Default _cDoc:= "068703   "//SF2->F2_DOC

	//_oTimer1:Activate()

	sfGerNfs()


	AtuMsg("Aguardando..")

Return nil

/*/{Protheus.doc} GerNf
	(long_description)
	@type  Static Function
	@author user
	@since 10/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function sfGerNfs()

	Local 	_cQuery		:=" "
	Local 	_cAlias
	Local 	_cNumPed 	:= ""
	Local 	lExecRot	:= GetNewPar("DE_FATAUTL",.T.)

	If lExecRot // Executa Rotina se o parâmetro estiver liberado
		_cQuery += "SELECT C5_NUM, R_E_C_N_O_ REC "
		_cQuery += "  FROM "+RetSqlName("SC5")+" C5 "
		_cQuery += " WHERE C5_FILIAL  = '"+xFilial("SC5")+"' "
		_cQuery += "   AND C5_SITDEC  = '1' "
		_cQuery += "   AND C5_TIPO    = 'N' "
		_cQuery += "   AND C5_EMISSAO >= '"+ DTOS(Date()-7 )+ "' "
		_cQuery += "   AND C5.D_E_L_E_T_ = ' ' "

		_cAlias:= U_ExeQry(_cQuery)

		While !(_cAlias)->(Eof())
			_cNumPed	:= (_cAlias)->C5_NUM
			DbSelectArea("SC5")
			DbGoTo((_cAlias)->REC)

			// Efetua a geração da nota fiscal a partir do pedido informado
			U_GerNFPed(_cNumPed)

			(_cAlias)->(DbSkip())
		Enddo

		U_GCLOSEA(_cAlias)
	Endif

Return

/*/{Protheus.doc} GerNFAut
Program para gerar a nota fiscal de saída conforme o pedido de venda da filial de transferência.
@type User Function
@author comercial@codecrafters.com.br
@since 26/08/2020
@version 1.0
@param aStep, array, array com os registro da etapa.
@param nPos, numeric, posição inicial do array.
@param cEmp, character, empresa.
@return aStep, array, array com os registro da etapa e seu respectivo status atualizado.
/*/
User Function GerNFPed(_cNumPed)

	Local aPVL      := {}
	Local cNF       := ""
	Local cSerie	:= ""
	Local _cStatus  := ""
	Local _cMsg  	:= ""
	Local _lSeek	:= .T.

	cSerie	:= Padr(SUPERGETMV("DC_SERFATA",.F.,"1  "),3)

	Begin Sequence

		If !xFilial("SC5")+_cNumPed == SC5->(C5_FILIAL+C5_NUM)
			_lSeek := U_GSEEK("SC5", 1, xFilial("SC5")+_cNumPed)
		Endif

		If  _lSeek .And. SC5->C5_SITDEC == '1' //Liberado aguardando faturamento


			aPVL := sfGetPVL(_cNumPed)

			If !Empty(aPVL)
				// Prepara o documento de saída.
				Pergunte("MT460A", .F.)
				cNF := PadR(MaPvlNfs(aPVL, cSerie, .F., .F., .F., .T., .F., 0, 0, .F., .F.), TamSX3("F2_DOC")[1])
				If Empty(cNF)
					_cStatus 	:= "0E1"
					_cMsg 		:= "Não foi possível faturar o pedido de venda."
					Break
				Else
					// Executa ponto de entrada para geração dos boletos.
					If ExistBlock("M460NOTA")
						ExecBlock("M460NOTA", .F., .F.,)
					EndIf
					_cStatus 	:= '0'
					Break
				EndIf
			Else//If !SC5->C5_XSTNFE == "0E0"
				_cStatus := "0E0"
				_cMsg := "Não foi possível coletar itens liberados para faturar (SC9)."
				Break
			EndIf
		EndIf
		Recover
		// Atualiza o status.
		If _cStatus == "0"
			RecLock("SF2",.F.)
			SF2->F2_XSTNFE := _cStatus 	//TAM 3
			SF2->F2_XLGNFE := _cMsg 	//TAM 250
			MsUnlock()
		Else
			//Dispara email avisando que não conseguiu gerar a NF
		Endif
	End Sequence

Return


/*/{Protheus.doc} sfGetPVL
Program validar o pedido de venda.
/*/
Static Function sfGetPVL(_cNumPed, _cStatus, _cMsg)

	Local aBloq     := {}
	Local aPvlNfs	:= {}

	// Verifica se há bloqueios no pedido de venda.
	Ma410LbNfs(1, @aPvlNfs, @aBloq)

	If !Empty(aBloq)
		// Limpa array para evitar faturamento parcial.
		aPvlNfs := {}
	EndIf

Return aPvlNfs

/*/{Protheus.doc} sfTrsNfs
	(long_description)
	@type  Static Function
	@author user
	@since 10/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function sfTrsNfs()

	Local _cQuery	:= " "
	Local _cAlias
	Local 	lExecRot	:= GetNewPar("DE_FATAUTL",.T.)

	If lExecRot // Executa Rotina se o parâmetro estiver liberado
		_cQuery += "SELECT F2_DOC, F2_SERIE , R_E_C_N_O_ REC "
		_cQuery += "  FROM "+RetSqlName("SF2")+" F2 "
		_cQuery += " WHERE F2_FILIAL  = '"+xFilial("SF2")+"' "
		_cQuery += "   AND F2_TIPO    = 'N' "
		_cQuery += "   AND F2_XSTNFE  = '0' "
		_cQuery += "   AND F2_EMISSAO >= '"+ DTOS(Date()-3 )+ "' "
		_cQuery += "   AND F2.D_E_L_E_T_ = ' ' "

		_cAlias:= U_ExeQry(_cQuery)

		While !(_cAlias)->(Eof())
			DbSelectArea("SF2")
			DbGoTo((_cAlias)->REC)
			// Efetua a transmissão da nota
			U_TrsNfU(SF2->F2_DOC, SF2->F2_SERIE)

			(_cAlias)->(DbSkip())
		Enddo

		U_GCLOSEA(_cAlias)
	Endif

Return


/*/{Protheus.doc} TrsNfU
	(long_description)
	@type  User Function
	@author user
	@since 10/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
User Function TrsNfU(_cDoc, _cSerie)

	Local _lSeek:= .T.
	Local cVersao   := ""
	Local cAmbiente := ""
	Local cError    := ""
	Local cIDEnti   := ""
	Local cModalid  := ""
	Local cRetorno	:= ""

	Begin Sequence

		If !xFilial("SF2")+_cDoc+_cSerie == SF2->(F2_FILIAL+F2_DOC+F2_SERIE)
			_lSeek := U_GSEEK("SF2", 1, xFilial("SF2")+_cDoc+_cSerie)
		Endif

		If  _lSeek .And. Alltrim(SF2->F2_XSTNFE)=='0'//Nf gerada aguardando transmissão

			If Empty(cIDEnti := RetIDEnti()) .Or. Empty(cVersao := GetCfgVersao(@cError, cIDEnti, "55")) .Or. Empty(cAmbiente := GetCfgAmbiente(@cError, cIDEnti, "55")) .Or. Empty(cModalid := GetCfgModalidade(@cError, cIDEnti, "55"))
				_cStatus := "0E0"
				_cMsg 	 := "Erro ao coletar parâmetros do TSS: " + cError
				Break
			EndIf

			cRetorno := SpedNFeTrf("SF2", _cSerie, _cDoc, _cDoc, cIDEnti, cAmbiente, cModalid, cVersao, .T., .F., .T.)

			If At("Foram transmitidas 1 nota", cRetorno) > 0
				_cStatus := "1"
				_cMsg 	 :="Integrado com sucesso."
				Break
				// erro na transmissão
			Else
				_cStatus := "0E1"
				_cMsg 	 :="Erro na transmissão: "+cRetorno
				Break
			EndIf
		EndIf

		Recover
		// Atualiza o status.
		RecLock("SF2",.F.)
		SF2->F2_XSTNFE := _cStatus
		SF2->F2_XLGNFE := _cMsg
		MsUnlock()
	End Sequence

Return

/*/{Protheus.doc} sfMonNfs
	(long_description)
	@type  Static Function
	@author user
	@since 10/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function sfMonNfs()

	Local _cQuery	:= " "
	Local _cAlias
	Local 	lExecRot	:= GetNewPar("DE_FATAUTL",.T.)

	If lExecRot // Executa Rotina se o parâmetro estiver liberado
		_cQuery += "SELECT F2_DOC, F2_SERIE , R_E_C_N_O_ REC "
		_cQuery += "  FROM "+RetSqlName("SF2")+" F2 "
		_cQuery += " WHERE F2_FILIAL  = '"+xFilial("SF2")+"' "
		_cQuery += "   AND F2_TIPO    = 'N' "
		_cQuery += "   AND F2_XSTNFE  = '1' "
		_cQuery += "   AND F2_EMISSAO >= '"+ DTOS(Date()-3 )+ "' "
		_cQuery += "   AND F2.D_E_L_E_T_ = ' ' "

		_cAlias:= U_ExeQry(_cQuery)

		While !(_cAlias)->(Eof())
			DbSelectArea("SF2")
			DbGoTo((_cAlias)->REC)
			// Efetua o monitoramento
			U_MonNfU(SF2->F2_DOC, SF2->F2_SERIE)
			(_cAlias)->(DbSkip())
		Enddo

		U_GCLOSEA(_cAlias)
	Endif

Return


/*/{Protheus.doc} MonNfU
	(long_description)
	@type  User Function
	@author user
	@since 10/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
User Function MonNfU(_cDoc, _cSerie)

	Local _lSeek	:= .T.
	Local cRetSef   := ""

	Begin Sequence

		If !xFilial("SF2")+_cDoc+_cSerie == SF2->(F2_FILIAL+F2_DOC+F2_SERIE)
			_lSeek := U_GSEEK("SF2", 1, xFilial("SF2")+_cDoc+_cSerie)
		Endif
		If  _lSeek .And. Alltrim( SF2->F2_XSTNFE) =='1' //Nf gerada aguardando transmissão

			If sfGetStatusNF(SF2->F2_SERIE, SF2->F2_DOC, @cRetSef)
				_cStatus := "2" //Autorizada
				_cMsg 	 := "Nfe Autorizada."
				Break
			Else
				_cStatus := "1E0"
				_cMsg 	 := "Retorno do SEFAZ: " + cRetSef
				Break
			EndIf

		EndIf

		Recover
		// Atualiza o status.
		RecLock("SF2",.F.)
		SF2->F2_XSTNFE := _cStatus
		SF2->F2_XLGNFE := _cMsg
		MsUnlock()
	End Sequence

Return

/*/{Protheus.doc} sfGetStatusNF
Verifica se a NF está autorizada no SEFAZ.
@type Static Function
@since 26/08/2020
@version 1.0
@param cSerie, characters, serie.
@param cDoc, characters, documento.
@param cRetSef, characters, mensagem de retorno do SEFAZ.
@type function
/*/
Static Function sfGetStatusNF(cSerie, cDoc, cRetSef)

	Local aStatus   := {}
	Local cURL      := SuperGetMV("MV_SPEDURL", .F., "")
	Local lOk       := .T.

	// Coleta retorno do status da nota pela rotina padrão.
	aStatus := ProcMonitorDoc(RetIdEnti(), cUrl, {cSerie, cDoc, cDoc}, 1 , , , @cRetSef , )
	// Valida se ocorreu erro.
	If (lOk := Empty(cRetSef))
		// Verifica se a nota não está autorizada para coletar o erro se verdadeiro.
		If aStatus[1][5] != "100"
			lOk 		:= .F.
			cRetSef 	:= aStatus[1][9]
		EndIf
	EndIf

Return lOk


/*/{Protheus.doc} sfPrtNfs
	(long_description)
	@type  Static Function
	@author user
	@since 10/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function sfPrtNfs()

	Local _cQuery	:=" "
	Local _cAlias
	Local cIDEnti
	Local cImpDefDan

	_cQuery += "SELECT F2_DOC, F2_SERIE , R_E_C_N_O_ REC "
	_cQuery += "  FROM "+RetSqlName("SF2")+" F2 "
	_cQuery += " WHERE F2_FILIAL   = '"+xFilial("SF2")+"' "
	_cQuery += "   AND F2_TIPO     = 'N' "
	_cQuery += "   AND F2_XSTNFE   = '2' "
	_cQuery += "   AND F2_EMISSAO >= '"+ DTOS(Date()-3 )+ "' "
	_cQuery += "   AND F2.D_E_L_E_T_=' ' "

	_cAlias:= U_ExeQry(_cQuery)

	if !(_cAlias)->(Eof())
		cIDEnti		:= RetIDEnti()
		cImpDefDan	:= SuperGetMV("DC_NOMIMP",,"LOGISTICA_DANFE_BNU")
	endif

	While !(_cAlias)->(Eof())
		DbSelectArea("SF2")
		DbGoTo((_cAlias)->REC)
		// Efetua a impressão do Danfe
		U_PrtNfU(cIDEnti,cImpDefDan, SF2->F2_DOC, SF2->F2_SERIE, .F.)

		(_cAlias)->(DbSkip())
	Enddo

	U_GCLOSEA(_cAlias)

Return
/*/{Protheus.doc} PrtNfU
Impressao da danfe de forma automatica
@since 06/12/2017
@version undefined
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function PrtNfU(cIDEnti,cImpDefDan, cNota,cSerie, lEntrada)

	Local lFindSF1	:=	.F.
	Local cCaminho	:=	"\spool\"//GetTempPath(.F.)//"\spool\"
	Local cFilPrtPDF
	Local cFilePrint
	Local oPrint    := Nil
	Local aRetImpS
	Local nPosImp
	Local _lSeek	:= .T.

	Default cIDEnti		:= RetIDEnti()
	Default cImpDefDan	:=	SuperGetMV("DC_NOMIMP",,"Logistica_BNU_DANFE")
	Default lEntrada 	:= .F.

	cNota	:= PADR(cNota,9)
	cSerie	:= PADR(cSerie,3)

	oPrint    := Nil

	Begin Sequence

		If !xFilial("SF2")+cNota+cSerie == SF2->(F2_FILIAL+F2_DOC+F2_SERIE)
			_lSeek := U_GSEEK("SF2", 1, xFilial("SF2")+cNota+cSerie)
		Endif
		If  _lSeek .and. Alltrim(SF2->F2_XSTNFE) == '2' //Nf Autorizada

			//SF1
			If lEntrada
				cChaveSF3	:= FWxFilial("SF3")+dtos(SF1->F1_EMISSAO)+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA
			Else
				cChaveSF3	:= FWxFilial("SF3")+dtos(SF2->F2_EMISSAO)+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA
			EndIf

			dbSelectArea("SF3")
			dbSetOrder(1)
			If !MSSeek(cChaveSF3)
				_cStatus := "2E0"
				_cMsg 	 :=	"Documento Não localizado  (SF3) Doc:"+cNota+" Serie:"+cSerie
				Break
			EndIf

			//Somente imprime caso a nota estiver autorizada
			If Empty(SF3->F3_CHVNFE)
				_cStatus := "2E0"
				_cMsg	 :=	"Danfe não impressa de forma automática pois não está autorizada"
				Break
			Endif

			aRetImpS	:=	GetImpWindows(.T.)
			nPosImp		:=	aScan(aRetImpS,{|x| Alltrim(x) == Alltrim(cImpDefDan) })

			If nPosImp == 0
				_cStatus := "2E1"
				_cMsg	 :=	"Impressora não localizada no servidor para impressão da danfe automática. Impressora (Parâmetro: DC_NOMIMP, caso não existir, criar. ):"+cImpDefDan
				Break
			EndIf

			cFilePrint	:= Alltrim(SF3->F3_CHVNFE)+"-nfe"//+dtos(msdate())+StrTran(time(),":","")
			cFilPrtPDF	:= cFilePrint+".rel"

			If File(cCaminho+cFilPrtPDF)
				FERASE(cCaminho+cFilPrtPDF)
			EndIf

			__WebExec	:=	.T.
			oPrint := FWMsPrinter():New(cFilPrtPDF, IMP_SPOOL, .F., cCaminho, .T., , , cImpDefDan, .F., , .F.)

			oPrint:SetResolution(78)
			oPrint:SetPortrait()
			oPrint:SetPaperSize(DMPAPER_A4)
			oPrint:SetMargin(60, 60, 60, 60)

			If IsBlind()
				oPrint:lServer	:=	.T.
				oPrint:lInJob	:=	.T.
			EndIf

			Pergunte("NFSIGW", .F.)
			MV_PAR01 := SF3->F3_NFISCAL
			MV_PAR02 := SF3->F3_NFISCAL
			MV_PAR03 := SF3->F3_SERIE
			MV_PAR04 := If(lFindSF1,1,2) //2-Saida /1-Entrada
			MV_PAR05 := 2
			MV_PAR06 := 2
			MV_PAR07 := stoD('20170101')
			MV_PAR08 := stoD('20500101')

			U_DANFEProc(@oPrint, , cIDEnti, , , , .F., 0)

			If oPrint:cPrinter == "none"
				oPrint:cPrinter := cImpDefDan
			EndIf

			If !oPrint==nil
				oPrint:Print()
			Endif

			_cStatus := "3"//Danfe Impressa
			_cMsg 	 :=	"Danfe Impressa"
			Break
		Endif

		Recover
		// Atualiza o status.
		RecLock("SF2",.F.)
		SF2->F2_XSTNFE := _cStatus
		SF2->F2_XLGNFE := _cMsg
		MsUnlock()
	End Sequence

Return


/*/{Protheus.doc} Nfs(cSerie)

	@type  Static Function
	@author user
	@since 23/06/2022
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function Nfs(cSerie)
	Local _cAlias:="QRYRTO"
	Local _cQuery:=" "
	Local _aRecs:={}

	AtuMsg("Selecionando NFS")

	_cQuery+=" Select R_E_C_N_O_ REC "
	_cQuery+=" from "+RetSqlName("SF2")+" F2  "
	_cQuery+=" Where F2_FILIAL='"+xFilial("SF2")+"'  "
	_cQuery+=" and F2_XDIMP='A' AND F2_SERIE='"+cSerie+"' and F2_ESPECIE='SPED' and F2.D_E_L_E_T_<>'*' "

	If select(_cAlias) > 0
		dbSelectArea(_cAlias)
		dbCloseArea()
	EndIf

	//_cQuery:= ChangeQuery(_cQuery)
	TcQuery _cQuery New Alias (_cAlias)

	DbSelectArea(_cAlias)
	DbGoTop()

	_nConta:=0
	_cNum:=""
	While (!(_cAlias)->(Eof()))
		AADD(_aRecs,(_cAlias)->REC)
		(_cAlias)->(DbSkip())
	EndDo

	If select(_cAlias) > 0
		dbSelectArea(_cAlias)
		dbCloseArea()
	EndIf

Return _aRecs

/*/{Protheus.doc} AtuMsg
  (long_description)
  @type  Static Function
  @author user
  @since 19/09/2022
  @version version
  @param param_name, param_type, param_descr
  @return return_var, return_type, return_description
  @example
  (examples)
  @see (links_or_references)
/*/
Static Function AtuMsg(_cMsg)

	_chMsg := _cMsg
//_ohMsg:Refresh()

Return
