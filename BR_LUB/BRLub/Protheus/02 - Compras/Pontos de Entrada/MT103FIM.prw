#include "totvs.ch"
#include 'FWPrintSetup.ch'
#INCLUDE "RPTDEF.CH"

/*/{Protheus.doc} MT103FIM
Ponto de Entrada ao finalizar a inclusão da nota de Entrada - fora da transação
@type function
@version 1.0
@author Marcelo Alberto Lauschner
@since 25/11/2020
/*/
User Function MT103FIM()

	Local aAreaOld  	:= GetArea()
	Local nOpcao 		:= PARAMIXB[1]
	Local nConfirma 	:= PARAMIXB[2]
	Local aParam    	:= PARAMIXB
	Local cFunCall  	:= SubStr(ProcName(0),3)
	Local lPEICMAIS 	:= ExistBlock( 'T'+ cFunCall ) .And. GetNewPar("BL_ICMAIOK",.F.)
	local cQuery        := "" as character

	If AllTrim(SF1->F1_FORMUL) == "S" .And. Alltrim(SF1->F1_ESPECIE) == "SPED"

		//Inclusao ou classificacao
		If (nOpcao == 3 .Or. nOpcao==4)  .And. nConfirma == 1

			// Chamado 25.351 - Fazer Transmissão e Impressão da nota logo após emissão
			If MsgYesNo("Deseja fazer a transmissão da NF-e agora e impressão do Danfe?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " Transmissão/Impressão Danfe")
				sfTransNFe(SF1->F1_DOC/*cInNota*/,SF1->F1_SERIE/*cInSerie*/,SF1->F1_FORNECE/*cInFornece*/,SF1->F1_LOJA/*cInLoja*/)
			Endif
		ElseIf (nOpcao == 2)  .And. nConfirma == 1

			// Chamado 25.351 - Fazer Transmissão e Impressão da nota logo após emissão
			If MsgYesNo("Deseja fazer a transmissão da NF-e agora e impressão do Danfe?",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) + " Transmissão/Impressão Danfe")
				sfTransNFe(SF1->F1_DOC/*cInNota*/,SF1->F1_SERIE/*cInSerie*/,SF1->F1_FORNECE/*cInFornece*/,SF1->F1_LOJA/*cInLoja*/)
			Endif

		Endif
	Endif

	// Verifica se é a empresa Redelog para que seja feito o Endereçamento sem esquecimento do usuário, já não lembram de fazer isso
	If "16755479" $ SM0->M0_CGC .And. AllTrim(SF1->F1_FORMUL) <> "S" .And. Alltrim(SF1->F1_ESPECIE) == "SPED" .And. SF1->F1_TIPO == "B"
		U_RLESTA01()
	Endif

	
	// Quando tipo do documento for devolução, grava o custo standart do produto conforme o custo da venda
	if SF1->F1_TIPO == 'D' .and. nOpcao == 3 /* nInclui */  .And. nConfirma == 1
		cQuery := "SELECT D1.R_E_C_N_O_ RECSD1, "
		cQuery += "  CASE WHEN D2.D2_XCUSTO > 0 THEN ROUND( D2.D2_XCUSTO / D2.D2_QUANT, 2) ELSE 0 END CUSTOSTD "
		cQuery += "  FROM "+ RetSqlName( 'SD1' ) +" D1 "
		
		cQuery += "INNER JOIN "+ RetSqlName( 'SD2' ) +" D2 "
		cQuery += " ON D2.D2_FILIAL  = '"+ FWxFilial( 'SD2' ) +"' "
		cQuery += "AND D2.D2_DOC     = RTRIM(D1.D1_NFORI) "
		cQuery += "AND D2.D2_SERIE   = D1.D1_SERIORI "
		cQuery += "AND D2.D2_CLIENTE = '"+ SF1->F1_FORNECE +"' "
		cQuery += "AND D2.D2_LOJA    = '"+ SF1->F1_LOJA +"' "
		cQuery += "AND D2.D2_ITEM    = D1.D1_ITEMORI "
		cQuery += "AND D2.D_E_L_E_T_ = ' ' "
		
		cQuery += "WHERE D1.D1_FILIAL  = '"+ FWxFilial( 'SD1' ) +"' "
		cQuery += "  AND D1.D1_DOC     = '"+ SF1->F1_DOC +"' "
		cQuery += "  AND D1.D1_SERIE   = '"+ SF1->F1_SERIE +"' "
		cQuery += "  AND D1.D1_FORNECE = '"+ SF1->F1_FORNECE +"' "
		cQuery += "  AND D1.D1_LOJA    = '"+ SF1->F1_LOJA +"' "
		cQuery += "  AND D1.D1_TIPO    = '"+ SF1->F1_TIPO +"' "
		cQuery += "  AND D1.D_E_L_E_T_ = ' ' "

		DBUseArea( .T. /* lNew */, "TOPCONN" /* cDriver */, TcGenQry(,,cQuery), 'TMPDEV' /* cAlias */, .F. /* lShared */, .T. /* lReadOnly */ )
		if ! TMPDEV->( EOF() )
			DBSelectArea( 'SD1' )
			while ! TMPDEV->( EOF() )
				
				// Posiciona nos registros de itens da devolução
				SD1->( DBGoTo( TMPDEV->RECSD1 ) )
				RecLock( 'SD1', .F. )
				SD1->D1_XCUSTO := Round( TMPDEV->CUSTOSTD * SD1->D1_QUANT, TAMSX3('D1_XCUSTO')[2] )
				SD1->( MsUnlock() )

				TMPDEV->( DBSkip() )
			enddo
		endif
		TMPDEV->( DBCloseArea() )

	endif

	// Manter o trexo de código a seguir no final do fonte
	If lPEICMAIS
		ExecBlock( 'T'+ cFunCall, .F., .F., aParam )
	Endif

	RestArea(aAreaOld)

Return



/*/{Protheus.doc} sfTransNFe
Função para fazer a Transmissão da Nota
@type function
@version
@author Marcelo Alberto Lauschner
@since 24/11/2020
@param cInNota, character, param_description
@param cInSerie, character, param_description
@param cInFornece, character, param_description
@param cInLoja, character, param_description
@return return_type, return_description
/*/
Static Function sfTransNFe(cInNota,cInSerie,cInFornece,cInLoja)

	Local	aAreaOld	:= GetArea()

	Local	cIdEnt		:= U_MLTSSENT()
	Local	cAmbiente
	Local	cModalidade
	Local	cVersao
	Local	lOk			:= .F.
	Local	lEnd		:= .F.
	Local	cError		:= ""
	Local	cModelo		:= "55"
	Local	cErrorTrans	:= ""

	cAmbiente	:= getCfgAmbiente(@cError, cIdEnt, cModelo)

	if( !empty(cAmbiente))

		cModalidade := getCfgModalidade(@cError, cIdEnt, cModelo)

		if( !empty(cModalidade) )
			cVersao		:= getCfgVersao(@cError, cIdEnt, cModelo)

			lOk := !empty(cVersao)

		endif
	endif

	DbSelectArea("SF1")
	DbSetOrder(1) // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	DbSeek(xFilial("SF2")+cInNota+cInSerie+cInFornece+cInLoja)

	// Se necessário poderá ser ativado a funcionalidade de já transmitir e monitorar a nota para enviar a chave para o WMS

	//Function SpedNFeRe2(cSerie,cNotaIni,cNotaFim,lCTe,lRetorno)
	//AutoNfeEnv(/*cEmpresa*/,/*cFilProc*/,/*cWait*/,/*cOpc*/,SF1->F1_SERIE,SF1->F1_DOC,SF1->F1_DOC)
	//	SpedNFeRe2(SF2->F2_SERIE,SF2->F2_DOC,SF2->F2_DOC,.F./*lCTe*/,@lRetTrans)
	cRetorno := SpedNFeTrf("SF1",;
		SF1->F1_SERIE/*cSerie*/,;
		SF1->F1_DOC/*cNotaIni*/,;
		SF1->F1_DOC/*cNotaFim*/,;
		cIdEnt,;
		cAmbiente,;
		cModalidade,;
		cVersao,;
		@lEnd,;
		.F./*lCte*/,;
		.T.)

	If !("Você concluíu com sucesso a transmissão do Protheus para o TOTVS Services SPED." $ cRetorno)
		cErrorTrans	+= cRetorno
	Endif

	//Sleep(8000)// Espera 8 segundos

	SpedNFe6Mnt( SF1->F1_SERIE/*cSerie*/,SF1->F1_DOC/*cNotaIni*/,SF1->F1_DOC/*cNotaFim*/,.T. /*lCTe*/)


	// Imprime a nota
	sfImpDanfe(SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_EMISSAO)


	RestArea(aAreaOld)

Return

/*/{Protheus.doc} sfImpDanfe
Função para fazer a impressão do Danfe
@type function
@version
@author Marcelo Alberto Lauschner
@since 24/11/2020
@param cNumNota, character, param_description
@param cSerie, character, param_description
@return return_type, return_description
/*/
Static Function sfImpDanfe(cNumNota,cSerie,dDataEmis)


	Local aAreaOld		:= GetArea()
	Local oDanfe
	Local cFilePrint 	:= ""
	Local oSetup
	Local aDevice  		:= {}
	Local cSession     	:= GetPrinterSession()
	Local nRet 			:= 0
	Local cIdEnt        := U_MLTSSENT() 


	If !Empty(cNumNota)
		// Grava as perguntas
		DbSelectArea("SX1")
		DbSetOrder(1)
		cPerg := "NFSIGW"
		cPerg :=  PADR(cPerg,10)

		U_GravaSX1(cPerg,"01",cNumNota)	// Numero De
		U_GravaSX1(cPerg,"02",cNumNota) // Numero Até
		U_GravaSX1(cPerg,"03",cSerie)	// Serie
		U_GravaSX1(cPerg,"04",1)		// Tipo operação 2-Saída
		U_GravaSX1(cPerg,"05",2) 		// Imprime no Verso - 2=Não
		U_GravaSX1(cPerg,"06",2) 		// Danfe simplificado - 2=Não
		U_GravaSX1(cPerg,"07",dDataEmis)// Emissão De
		U_GravaSX1(cPerg,"08",dDataEmis)// Emissão Ate


	Endif

	If findfunction("U_DANFE_V")
		nRet := U_Danfe_v()
	Elseif findfunction("U_DANFE_VI") // Incluido esta validação pois o cliente informou que não utiliza o DANFEII
		nRet := U_Danfe_vi()
	EndIf

	AADD(aDevice,"DISCO") // 1
	AADD(aDevice,"SPOOL") // 2
	AADD(aDevice,"EMAIL") // 3
	AADD(aDevice,"EXCEL") // 4
	AADD(aDevice,"HTML" ) // 5
	AADD(aDevice,"PDF"  ) // 6

	cFilePrint := "DANFE_"+cIdEnt+Dtos(MSDate())+StrTran(Time(),":","")

	nLocal       	:= If(fwGetProfString(cSession,"LOCAL","SERVER",.T.)=="SERVER",1,2 )
	nOrientation 	:= If(fwGetProfString(cSession,"ORIENTATION","PORTRAIT",.T.)=="PORTRAIT",1,2)
	cDevice     	:= If(Empty(fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.)),"PDF",fwGetProfString(cSession,"PRINTTYPE","SPOOL",.T.))
	nPrintType      := aScan(aDevice,{|x| x == cDevice })


	lAdjustToLegacy := .F. // Inibe legado de resolução com a TMSPrinter
	oDanfe := FWMSPrinter():New(cFilePrint, IMP_PDF, lAdjustToLegacy, /*cPathInServer*/, .T.)

	// ----------------------------------------------
	// Cria e exibe tela de Setup Customizavel
	// OBS: Utilizar include "FWPrintSetup.ch"
	// ----------------------------------------------
	//nFlags := PD_ISTOTVSPRINTER+ PD_DISABLEORIENTATION + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
	nFlags := PD_ISTOTVSPRINTER + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN
	If ( !oDanfe:lInJob )
		oSetup := FWPrintSetup():New(nFlags, "DANFE")
		// ----------------------------------------------
		// Define saida
		// ----------------------------------------------
		oSetup:SetPropert(PD_PRINTTYPE   , nPrintType)
		oSetup:SetPropert(PD_ORIENTATION , nOrientation)
		oSetup:SetPropert(PD_DESTINATION , nLocal)
		oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
		oSetup:SetPropert(PD_PAPERSIZE   , 2)

	EndIf

	// ----------------------------------------------
	// Pressionado botão OK na tela de Setup
	// ----------------------------------------------
	If oSetup:Activate() == PD_OK // PD_OK =1
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Salva os Parametros no Profile             ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

		fwWriteProfString( cSession, "LOCAL"      , If(oSetup:GetProperty(PD_DESTINATION)==1 ,"SERVER"    ,"CLIENT"    ), .T. )
		fwWriteProfString( cSession, "PRINTTYPE"  , If(oSetup:GetProperty(PD_PRINTTYPE)==2   ,"SPOOL"     ,"PDF"       ), .T. )
		fwWriteProfString( cSession, "ORIENTATION", If(oSetup:GetProperty(PD_ORIENTATION)==1 ,"PORTRAIT"  ,"LANDSCAPE" ), .T. )

		// Configura o objeto de impressão com o que foi configurado na interface.
		oDanfe:setCopies( val( oSetup:cQtdCopia ) )

		If oSetup:GetProperty(PD_ORIENTATION) == 1
			
			//³Danfe Retrato DANFEII.PRW 
			Pergunte( cPerg, .F. )
			MV_PAR01 := cNumNota
			MV_PAR02 := cNumNota
			MV_PAR03 := cSerie
			MV_PAR04 := 2
			MV_PAR05 := 2
			MV_PAR06 := 2
			MV_PAR07 := dDataEmis
			MV_PAR08 := dDataEmis

			u_PrtNfeSef(cIdEnt,,,oDanfe, oSetup, cFilePrint)

		ElseIf FindFunction("U_DANFE_P1")
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Danfe Paisagem DANFEIII.PRW                ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			u_DANFE_P1(cIdEnt,,,oDanfe, oSetup)
		Else
			MsgInfo("Não foi possível imprimir o Danfe!")
		EndIf

	Else
		MsgInfo("Relatório cancelado pelo usuário.")
		Return
	Endif

	oSetup := Nil
	oDanfe := Nil

	RestArea(aAreaOld)

Return
