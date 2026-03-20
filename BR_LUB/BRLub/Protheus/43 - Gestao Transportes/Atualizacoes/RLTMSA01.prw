#Include 'Protheus.ch'
#include "topconn.ch"

/*/{Protheus.doc} RLTMSA01
(Importador XML de Notas fiscais para Entrada Nf.Cliente para Gravação de dados na rotina TMSA050)
@type function
@author Marcelo Alberto Lauschner
@since 04/03/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function RLTMSA01()

	Private		aTotRdpe 	:= {{0,0,0,0},{0,0,0,0}}
	Private 	dDataLanc	:= dDataBase
	Private 	cArqImp		:= Space(150)
	Private 	oArqIMp,oDescEnt
	Private		aCols,aHeader
	Private 	aButton		:= {{"VERDE"		,{|| TMSA050()}  ,"Entrada NF Cliente","Entrada NF Cliente"},{"AZUL",{ || TMSA200()},"Calcula Frete","Calcula Lote Frete"} }
	Private 	aSize := MsAdvSize(,.F.,400)
	Private 	nPxFILORI,nPxLOTNFC,nPxDATENT,nPxCLIREM,nPxLOJREM,nPxCLIDES,nPxLOJDES,nPxDEVFRE,nPxCLIDEV
	Private 	nPxLOJDEV,nPxCLICAL,nPxLOJCAL,nPxTIPFRE,nPxSERTMS,nPxTIPTRA,nPxSERVIC,nPxTIPNFC,nPxSELORI
	Private 	nPxCDRORI,nPxCDRDES,nPxCDRCAL,nPxDISTIV,nPxOBS,nPxNUMNFC,nPxSERNFC, nPxCODNEG
	Private 	nPxCODPRO,nPxCODEMB,nPxEMINFC,nPxQTDVOL,nPxPESO,nPxPESOM3,nPxVALOR ,nPxEDI,nPxNFENTR,nPxNFEID,nPxEMINFE
	Private		nPxCTRDPC,nPxTIPANT,nPxDPCEMI,nPxCTEANT,nPxSERDPC //Campos para CTE redespacho
	Private 	cRootPath	:= GetSrvProfString ("RootPath","\indefinido")
	Private		cDirNfe    	:= GetNewPar("XM_DIRXML",IIf(IsSrvUnix(),"/Nf-e/", "\Nf-e\"))
	Private		cDirSchema 	:= IIf(IsSrvUnix(),"/schemas/", "\schemas\")
	Private		INCLUI		:= .T.
	Private		ALTERA		:= .F.


	DEFINE MSDIALOG oDlgXml TITLE OemToAnsi("Importar Arquivos XML de Notas fiscais de clientes Redelog") From aSize[7],0 to aSize[6],aSize[5] OF oMainWnd PIXEL

	oDlgXml:lMaximized := .T.

	oPanel1 := TPanel():New(0,0,'',oDlgXml, oDlgXml:oFont, .T., .T.,, ,200,35,.T.,.T. )
	oPanel1:Align := CONTROL_ALIGN_TOP

	oPanel2 := TPanel():New(0,0,'',oDlgXml, oDlgXml:oFont, .T., .T.,, ,200,40,.T.,.T. )
	oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

	oPanel3 := TPanel():New(0,0,'',oDlgXml, oDlgXml:oFont, .T., .T.,, ,200,60,.T.,.T. )
	oPanel3:Align := CONTROL_ALIGN_BOTTOM


	DEFINE FONT oFnt 	NAME "Arial" SIZE 0, -11 BOLD

	@ 012 ,005  	Say OemToAnsi("Data Lançamento") SIZE 30,9 PIXEl OF oPanel1 FONT oFnt					//"Data"
	@ 011 ,023  	MSGET dDataLanc  Picture "99/99/9999" PIXEl SIZE 55, 10 OF oPanel1 HASBUTTON

	@ 012 ,083   	Say OemToAnsi("Arquivo") SIZE 30,9 PIXEl	OF oPanel1 FONT oFnt 				//"Lote"
	@ 011 ,121		MSGET oArqIMp VAR cArqImp Picture "@!" PIXEl SIZE 132, 10 OF oPanel1 Valid (cArqImp := cGetFile( "", OemToAnsi("Selecione o diretório"),0,"C:\Nf-e",.T.,GETF_RETDIRECTORY+GETF_LOCALHARD),Processa({|| sfCarrega(@oMulti:aCols,@oMulti:aHeader,2)},"Carregando dados..."))


	Processa({|| sfCarrega(@aCols,@aHeader,1) },"Localizando registros...")

	Private oMulti := MsNewGetDados():New(034, 005, 226, 415,GD_INSERT+GD_DELETE+GD_UPDATE,"U_RLTMSM02()"/*cLinhaOk*/,;
		"AllwaysTrue()"/*cTudoOk*/,"",;
		,4/*nFreeze*/,10000/*nMax*/,"AllwaysTrue()"/*cCampoOk*/,/*cSuperApagar*/,;
	/*cApagaOk*/,oPanel2,@aHeader,@aCols)

	oMulti:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	@ 040 ,008  SAY OemToAnsi("Quantidade Notas   :") Of oPanel3 PIXEL	FONT oFnt
	@ 040 ,065 	MSGET oDig 	VAR aTotRdpe[1][1]	Picture "@E 999,999" Of oPanel3 READONLY SIZE 75 ,9 PIXEL
	@ 020 ,190 	SAY OemToAnsi("Total R$ Mercadoria:") Of oPanel3 PIXEL	FONT oFnt
	@ 040 ,190	SAY OemToAnsi("Total Peso KG	  :") Of oPanel3 PIXEL FONT oFnt
	@ 020 ,250	MSGET oDeb 	VAR aTotRdPe[1][2]	Picture "@E 999,999.99" Of oPanel3 READONLY SIZE 75 ,9 PIXEL
	@ 040 ,250	MSGET oCred VAR aTotRdPe[1][3] Picture "@E 999,999.999" Of oPanel3 READONLY SIZE 75 ,9 PIXEL

	ACTIVATE MSDIALOG oDlgXml ON INIT (oMulti:oBrowse:Refresh(),EnchoiceBar(oDlgXml,{|| Processa({||sfGrava()},"Gerando lançamentos de entrada...")},{|| oDlgXml:End()},,aButton))

Return


/*/{Protheus.doc} sfCarrega
(Montagem do aCols e aHeader do objeto GetDados  )
@type function
@author marce
@since 04/03/2017
@version 1.0
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@param nRefrBox, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCarrega(aCols,aHeader,nRefrBox)

	Local	nUsado		:=  0
	Local	aCpo		:=  {	"DTC_FILORI"	,"DTC_LOTNFC"	,"DTC_DATENT"	,"DTC_CLIREM"	,"DTC_LOJREM"	,"DTC_CLIDES",;
		"DTC_LOJDES"	,"DTC_DEVFRE"	,"DTC_CLIDEV"	,"DTC_LOJDEV"	,"DTC_CLICAL"	,"DTC_LOJCAL",;
		"DTC_TIPFRE"	,"DTC_SERTMS"	,"DTC_TIPTRA"	,"DTC_SERVIC"	,"DTC_TIPNFC"	,"DTC_SELORI",;
		"DTC_CDRORI"	,"DTC_CDRDES"	,"DTC_CDRCAL"	,"DTC_DISTIV"	,"DTC_OBS"	 	,"DTC_CODNEG",;
		"DTC_NUMNFC"	,"DTC_SERNFC"	,"DTC_CODPRO"	,"DTC_CODEMB"	,"DTC_EMINFC"	,"DTC_QTDVOL",;
		"DTC_PESO"		,"DTC_PESOM3" 	,"DTC_VALOR"	,"DTC_EDI"		,"DTC_NFENTR"	,"DTC_NFEID",	"DTC_EMINFE",;
		"DTC_CTRDPC"	,"DTC_TIPANT"	,"DTC_DPCEMI"	,"DTC_CTEANT"	,"DTC_SERDPC"} //Campos para CTE redespacho
	Local	iX
	Local	a
	Local	nColuna
	aCols	:= 	{}
	aHeader	:=	{}


	// DbSelectArea("SX3")
	// DbSetOrder(2)
	// For iX := 1 To Len(aCpo)
	// 	If DbSeek(aCpo[iX])
	// 		Aadd(aHeader,{ AllTrim(X3Titulo()),;
	// 			SX3->X3_CAMPO	,;
	// 			SX3->X3_PICTURE,;
	// 			SX3->X3_TAMANHO,;
	// 			SX3->X3_DECIMAL,;
	// 			"",;//SX3->X3_VALID	,;
	// 			SX3->X3_USADO	,;
	// 			SX3->X3_TIPO	,;
	// 			SX3->X3_F3 		,;
	// 			SX3->X3_CONTEXT,;
	// 			SX3->X3_CBOX	,;
	// 			SX3->X3_RELACAO })
	// 		nUsado++
	// 		If nRefrBox == 1
	// 			&("nPx"+Substr(SX3->X3_CAMPO,5,6)) := nUsado
	// 		Endif
	// 	Endif
	// Next

	For iX := 1 To Len(aCpo)
		cCampo := aCpo[iX]
		Aadd(aHeader,{AllTrim(GetSx3Cache(cCampo,"X3_TITULO")),;
			GetSx3Cache(cCampo,"X3_CAMPO")		,;
			GetSx3Cache(cCampo,"X3_PICTURE")	,;
			GetSx3Cache(cCampo,"X3_TAMANHO")	,;
			GetSx3Cache(cCampo,"X3_DECIMAL")	,;
			""									,;
			GetSx3Cache(cCampo,"X3_USADO")		,;
			GetSx3Cache(cCampo,"X3_TIPO")		,;
			GetSx3Cache(cCampo,"X3_F3") 		,;
			GetSx3Cache(cCampo,"X3_CONTEXT")	,;
			GetSx3Cache(cCampo,"X3_CBOX")		,;
			GetSx3Cache(cCampo,"X3_RELACAO") 	})
		nUsado++
		If nRefrBox == 1
			&("nPx"+Substr(GetSx3Cache(cCampo,"X3_CAMPO"),5,6)) := nUsado
		Endif
	Next

	If nRefrBox == 2 .And. cArqImp <> Nil

		cTipo    := "*.xml"
		aFiles   := Directory(cArqImp + cTipo)

		// Crio o diretorio caso não exista ainda
		If IsSrvUnix()
			MakeDir(cDirNfe+DTOS(Date())+"/")
		Else
			MakeDir(cDirNfe+DTOS(Date())+"\")
		Endif

		ProcRegua(Len(aFiles))

		For a := 1 To Len(aFiles)

			If !File(Alltrim(cArqImp+ aFiles[a][1]))
				MsgBox("Arquivo texto nao existente(1)."+ aFiles[a][1])
				Loop
			Endif
			cText	:= ""

			If File(cArqImp + aFiles[a][1])
				cText := FsLoadTXT(cArqImp+aFiles[a][1])
				__CopyFile(cArqImp + aFiles[a][1],cRootPath+cDirNfe+DTOS(Date())+IIf(IsSrvUnix(),"/","\")+aFiles[a][1])
				Ferase(cArqImp + aFiles[a][1])
			Endif

			IncProc()

			AADD(aCols,Array(Len(aHeader)+1))

			For nColuna := 1 to Len( aHeader )
				If aHeader[nColuna][8] == "C"
					aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
				ElseIf aHeader[nColuna][8] == "D"
					aCols[Len(aCols)][nColuna] := dDataBase
				ElseIf aHeader[nColuna][8] == "M"
					aCols[Len(aCols)][nColuna] := ""
				ElseIf aHeader[nColuna][8] == "N"
					aCols[Len(aCols)][nColuna] := 0
				Else
					aCols[Len(aCols)][nColuna] := .F.
				Endif
				If !Empty(aHeader[nColuna][12])
					aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
				Endif

			Next nColuna
			aCols[Len(aCols),Len(aHeader)+1]	:= .F.

			If !sfGrvXmlNfe(cText,@aCols,@aHeader)
				aCols[Len(aCols),Len(aHeader)+1]	:= .T.
				aCols[Len(aCols),nPxOBS   ] 		:= cText
				MsgAlert("A nota fiscal a seguir deverá ser digitada manualmente!","Erro ao importar XML")
				MemoWrite("C:\Temp_Nf-e\"+aFiles[a][1],cText)
				//ShellExecute("open",cLocDir+'nf_erro.xml',"",cLocDir,1)
			Endif

		Next
	Endif

	If Len(aCols) == 0
		AADD(aCols,Array(Len(aHeader)+1))
		For nColuna := 1 to Len( aHeader )
			If aHeader[nColuna][8] == "C"
				aCols[Len(aCols)][nColuna] := Space(aHeader[nColuna][4])
			ElseIf aHeader[nColuna][8] == "D"
				aCols[Len(aCols)][nColuna] := dDataBase
			ElseIf aHeader[nColuna][8] == "M"
				aCols[Len(aCols)][nColuna] := ""
			ElseIf aHeader[nColuna][8] == "N"
				aCols[Len(aCols)][nColuna] := 0
			Else
				aCols[Len(aCols)][nColuna] := .F.
			Endif
			If !Empty(aHeader[nColuna][12])
				aCols[Len(aCols)][nColuna] := &(aHeader[nColuna][12])
			Endif

		Next nColuna
		aCols[Len(aCols),Len(aHeader)+1]	:= .F.
	Endif

	aSort(aCols,,,{|x,y| x[6]<y[6]})

	If Type("oMulti") <> "U"
		oMulti:oBrowse:Refresh()
		sfAtuRodp()
	Endif

Return


/*/{Protheus.doc} FsLoadTXT
(long_description)
@type function
@author marce
@since 04/03/2017
@version 1.0
@param cFileXml, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function FsLoadTXT(cFileXml)

	Local	nHdl    := fOpen(cFileXml)
	Local	cTexto	:= ""
	// Se foi possível abrir
	If nHdl <> -1
		// Leitura do Arquivo atribuindo o texto do xml a variavel cbuffer
		nTamFile := fSeek(nHdl,0,2)
		fSeek(nHdl,0,0)
		cBuffer  := Space(nTamFile)
		nBtLidos := fRead(nHdl,@cTexto,nTamFile)
		fClose(nHdl)
	Endif

Return(cTexto)

/*/{Protheus.doc} sfAtuRodp
(Atualiza dados do Rodapé)
@type function
@author marce
@since 04/03/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuRodp
	Local	iX

	aTotRdpe[1][1]	:= 0
	aTotRdpe[1][2]	:= 0
	aTotRdpe[1][3]	:= 0

	For iX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[iX,Len(oMulti:aHeader)+1]
			aTotRdpe[1][1]++
			aTotRdpe[1][2]	+= oMulti:aCols[iX,nPxVALOR ]
			aTotRdpe[1][3]	+= oMulti:aCols[iX,nPxPESO  ]
		Endif
	Next

	oDeb:Refresh()
	oDig:Refresh()
	oCred:Refresh()

Return



/*/{Protheus.doc} sfGrvXmlNfe
(Efetua leitura do XML informado e monta o array aCols )
@type function
@author marce
@since 04/03/2017
@version 1.0
@param cText, character, (Descrição do parâmetro)
@param aCols, array, (Descrição do parâmetro)
@param aHeader, array, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrvXmlNfe(cText,aCols,aHeader)

	Local	cTxtGrv	:= cText
	Local	cVldSch	:= cText
	Local	cAviso	:= ""
	Local	cErro	:= ""

	// Se encontrada apenas a tag <NFe> adiciona Atributo
	// Solução adicionada em 21/03/12 para resolver problema de validação de Schema do Microsiga
	If ( nPosIni := At("<NFe>",cVldSch)) > 0
		//<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe
		cVldSch := '<NFe xmlns="http://www.portalfiscal.inf.br/nfe">'+Substr(cVldSch,nPosINi+5)
	Endif

	If ( nPosIni := At("<NFe",cVldSch)) > 0
		//<NFe xmlns="http://www.portalfiscal.inf.br/nfe"><infNFe
		cVldSch := Substr(cVldSch,nPosINi)
	Endif
	If ( nPosIni := At("</infNFe>",cVldSch)) > 0
		cVldSch := Substr(cVldSch,1,nPosINi+8)
		cVldSch += "</NFe>"
	Endif

	cAviso	:= ""
	cErro	:= ""


	oNfe := XmlParser(cText,"_",@cAviso,@cErro)

	If !Empty(cErro)
		MsgAlert(cErro+chr(13)+cAviso,"Erro de XMLParser")
		cMsgRetMail	+= "Erro de XmlParser - '"+cErro+"' "
		//StaticCall(XMLDCONDOR,stSendMail,"iago@atrialub.com.br","Importação xml - "+cErro ,'"'+cTxtGrv+'"')
		Return .F.
	Endif

	If At(Chr(10),cVldSch) > 0 .And. At("<NFe>",cVldSch) > 0
		Aviso("Arquivo XML contém caracter de quebra de linha!",cText,{"Ok"},3)
		cMsgRetMail	+= "Arquivo XML contém caracter de quebra de linha"
		Return .F.
	Endif

	If !Empty(cAviso) .Or. (Type("oNFe:_NfeProc")== "U" .And. Type("oNFe:_NFe")== "U")

		cErro	:= ""
		cAviso	:= ""
		oNfe := XmlParser(cTxtGrv,"_",@cAviso,@cErro)

		If !Empty(cErro)
			MsgAlert(cErro+chr(13)+cAviso,"Erro ao validar schema do Xml")
			cMsgRetMail	+= "Erro XmlParser '"+cErro+"' "
			//StaticCall(XMLDCONDOR,stSendMail,"iago@atrialub.com.br","Importação xml - "+cErro ,'"'+cTxtGrv+'"')
			Return .F.
		Endif

		If !Empty(cAviso)
			MsgAlert(cErro+chr(13)+cAviso,"Aviso ao validar schema do Xml")
		Endif

	Endif

	If Type("oNFe:_NfeProc")<> "U"
		oNF := oNFe:_NFeProc:_NFe
	ElseIf Type("oNFe:_NFe")<> "U"
		oNF := oNFe:_NFe
	Else
		//StaticCall(XMLDCONDOR,stSendMail,"iago@atrialub.com.br","Importação xml - Erro de oNFe " ,'"'+cTxtGrv+'"')
		Return .F.
	Endif


	oIdent     	:= oNF:_InfNfe:_IDE
	oEmitente  	:= oNF:_InfNfe:_Emit
	oDestino   	:= oNF:_InfNfe:_Dest
	oTotal		:= oNF:_InfNfe:_Total
	oTransp		:= oNF:_InfNfe:_Transp

	If Type("oNFe:_NfeProc:_protNFe:_infProt:_chNFe")<> "U"
		oNF := oNFe:_NFeProc:_NFe
		cChave	:= oNFe:_NfeProc:_protNFe:_infProt:_chNFe:TEXT
	Endif

	//IAGO 13/10/2021 Chamado 26661 - Nao gerar cte para cnpj atria
	If Type("oDestino:_CNPJ") <> "U" .And. oDestino:_CNPJ:TEXT == "06032022000110"
		Return .F.
	EndIf

	nPosLinha	:= Len(aCols)

	// Avalia se o emitente da nota fiscal esta cadastrado com cliente da Redelog
	If !sfAvalSA1(	oEmitente:_CNPJ:TEXT,;
			"J",;
			oEmitente:_xNome:TEXT,;
			Iif(Type("oEmitente:_xFant") <> "U",oEmitente:_xFant:TEXT,oEmitente:_xNome:TEXT),;
			"F",;
			oEmitente:_enderEmit:_xLgr:TEXT+", "+oEmitente:_enderEmit:_nro:TEXT,;
			oEmitente:_enderEmit:_xMun:TEXT,;
			oEmitente:_enderEmit:_UF:TEXT,;
			oEmitente:_enderEmit:_xBairro:TEXT,;
			oEmitente:_enderEmit:_CEP:TEXT,;
			IIf(Type("oEmitente:_enderEmit:_fone")<>"U",Substr(oEmitente:_enderEmit:_fone:TEXT,1,2),""),;
			IIf(Type("oEmitente:_enderEmit:_fone")<>"U",Substr(oEmitente:_enderEmit:_fone:TEXT,3),""),;
			IIf(Type("oEmitente:_enderEmit:_fone")<>"U",oEmitente:_enderEmit:_fone:TEXT,""),;
			Iif(Type("oEmitente:_IE")<>"U",oEmitente:_IE:TEXT,"ISENTO"),;
			sfAvalRegiao(	oEmitente:_enderEmit:_CEP:TEXT,;
			oEmitente:_enderEmit:_xMun:TEXT,;
			oEmitente:_enderEmit:_xBairro:TEXT,;
			oEmitente:_enderEmit:_xLgr:TEXT+", "+oEmitente:_enderEmit:_nro:TEXT,;
			oEmitente:_enderEmit:_UF:TEXT,;
			oEmitente:_enderEmit:_cMun:TEXT),;
			oEmitente:_enderEmit:_cMun:TEXT)

		Return .F.
	Endif

	aCols[nPosLinha,nPxFILORI]	:= cFilAnt 				// Fil.Origem
	aCols[nPosLinha,nPxLOTNFC]	:= " "					// No.Lote
	aCols[nPosLinha,nPxDATENT]	:= dDataLanc			// Data Entrada

	DbSelectArea("SA1")
	DbSetOrder(3)
	DbSeek(xFilial("SA1")+oEmitente:_CNPJ:TEXT)

	aCols[nPosLinha,nPxCLIREM]	:= SA1->A1_COD			// Remetente
	aCols[nPosLinha,nPxLOJREM]	:= SA1->A1_LOJA			// Loja Remet.
	aCols[nPosLinha,nPxDEVFRE]	:= "1"					// Dev.Frete 1=Remetente/2=Destinatário/3=Consignatário/4=Despachante
	aCols[nPosLinha,nPxCLIDEV]	:= SA1->A1_COD			// Devedor
	aCols[nPosLinha,nPxLOJDEV]	:= SA1->A1_LOJA			// Loja Devedor
	aCols[nPosLinha,nPxCLICAL]	:= SA1->A1_COD			// Cli.Calculo
	aCols[nPosLinha,nPxLOJCAL]	:= SA1->A1_LOJA			// Loja Calculo
	aCols[nPosLinha,nPxCDRORI]	:= "O05902"		// Gaspar

	// Avalia se o destinatario da nota fiscal esta cadastrado com cliente da Redelog
	If !sfAvalSA1(	Iif(Type("oDestino:_CNPJ") <> "U",oDestino:_CNPJ:TEXT,oDestino:_CPF:TEXT),;
			Iif(Type("oDestino:_CNPJ") <> "U","J","F"),;
			oDestino:_xNome:TEXT,;
			oDestino:_xNome:TEXT,;
			"F",;
			oDestino:_enderDest:_xLgr:TEXT+", "+oDestino:_enderDest:_nro:TEXT,;
			oDestino:_enderDest:_xMun:TEXT,;
			oDestino:_enderDest:_UF:TEXT,;
			oDestino:_enderDest:_xBairro:TEXT,;
			oDestino:_enderDest:_CEP:TEXT,;
			IIf(Type("oDestino:_enderDest:_fone")<>"U",Substr(oDestino:_enderDest:_fone:TEXT,1,2),""),;
			IIf(Type("oDestino:_enderDest:_fone")<>"U",Substr(oDestino:_enderDest:_fone:TEXT,3),""),;
			IIf(Type("oDestino:_enderDest:_fone")<>"U",oDestino:_enderDest:_fone:TEXT,""),;
			Iif(Type("oDestino:_IE")<>"U",oDestino:_IE:TEXT,"ISENTO"),;
			sfAvalRegiao(	oDestino:_enderDest:_CEP:TEXT,;
			oDestino:_enderDest:_xMun:TEXT,;
			oDestino:_enderDest:_xBairro:TEXT,;
			oDestino:_enderDest:_xLgr:TEXT+", "+oDestino:_enderDest:_nro:TEXT,;
			oDestino:_enderDest:_UF:TEXT,;
			oDestino:_enderDest:_cMun:TEXT),;
			oDestino:_enderDest:_cMun:TEXT)
		Return .F.
	Endif

	DbSelectArea("SA1")
	DbSetOrder(3)
	DbSeek(xFilial("SA1")+IIf(Type("oDestino:_CNPJ") <> "U",oDestino:_CNPJ:TEXT,oDestino:_CPF:TEXT))

	aCols[nPosLinha,nPxCLIDES]	:= SA1->A1_COD			// Destinatário
	aCols[nPosLinha,nPxLOJDES]	:= SA1->A1_LOJA			// Loja Dest.
	aCols[nPosLinha,nPxTIPFRE]	:= "1"
	aCols[nPosLinha,nPxTIPTRA] 	:= "1"					// Tipo Transp. 1=Rodoviário/2=Aéreo/3=Fluvial/4=Rodoviário Internacional
	aCols[nPosLinha,nPxTIPNFC]	:= "0"					// Tipo Nf.Cli 	0=Normal/1=Devolução/2=SubContratação/3=Não Fiscal/4=Exportação/5=Redespacho/6=Nota Fiscal1/7=Nota Fiscal2/8=Serv.Vinc.Multimodal
	aCols[nPosLinha,nPxSELORI]	:= "1"					// Selec.Origem 1=Transportadora/2=Cliente Remetente/3=Local Coleta
	aCols[nPosLinha,nPxCDRDES]	:= SA1->A1_CDRDES		// Cod.Reg.Des.
	aCols[nPosLinha,nPxCDRCAL]	:= SA1->A1_CDRDES		// Cod.Reg.Cal.
	aCols[nPosLinha,nPxDISTIV] 	:= "2"
	aCols[nPosLinha,nPxCODNEG]	:= "03"
	aCols[nPosLinha,nPxOBS   ] 	:= Iif(Type("oNF:_InfNfe:_infAdic:_infCpl") <> "U",oNF:_InfNfe:_infAdic:_infCpl:TEXT," ")

	dbSelectArea("DUY")
	dbSetOrder(1)
	dbSeek(xFilial("DUY")+SA1->A1_CDRDES)
	//TODO Adequar os campos
	aCols[nPosLinha,nPxSERTMS]	:= "3"
	aCols[nPosLinha,nPxSERVIC]	:= "010"
	//aCols[nPosLinha,nPxCOMAGE] 	:= DUY->DUY_CODRE

	// Monta dados para a DTC - GetDados
	aCols[nPosLinha,nPxNUMNFC]	:= Right("000000000"+Alltrim(OIdent:_nNF:TEXT),TamSX3("DTC_NUMNFC")[1])		//  Doc.Cliente
	aCols[nPosLinha,nPxSERNFC]	:= Padr(OIdent:_serie:TEXT,TamSX3("DTC_SERNFC")[1])							//  Serie Dc.Cli
	//aCols[nPosLinha,nPxCODPRO]	:= Iif(!Empty(SA1->A1_XCODFRE),SA1->A1_XCODFRE,'CALC.ATRS')					// 	Cod.Produto
	aCols[nPosLinha,nPxCODPRO]	:= "0000000000005"
	aCols[nPosLinha,nPxCODEMB]	:= "CX"																		// 	Embalagem

	// Identifica novo formato de Data e Hora - Nota Versão 3.10
	If Type("oIdent:_dhEmi") <> "U"
		// <dhEmi>2014-04-15T12:02:46-03:00
		cData 	:=	Alltrim(Substr(oIdent:_dhEmi:TEXT,1,10))
	Else
		//<dEmi>2014-04-10
		cData	:=	Alltrim(oIdent:_dEmi:TEXT)
	Endif
	cData	:= 	StrTran(cData,"-","")
	dData	:=	STOD(cData)

	aCols[nPosLinha,nPxEMINFC]	:= dData																	// 	DT Emissao
	aCols[nPosLinha,nPxEMINFE]	:= dData																	//	Emissao NF-e
	aCols[nPosLinha,nPxQTDVOL]	:= IIf(Type("oTransp:_vol:_qVol") <> "U",Val(oTransp:_vol:_qVol:TEXT),0)	//	Qtd.Volumes
	aCols[nPosLinha,nPxPESO  ]	:= IIf(Type("oTransp:_vol:_pesoB") <> "U",Val(oTransp:_vol:_pesoB:TEXT),0)	// 	Peso
	aCols[nPosLinha,nPxPESOM3]	:= 0																		//	Peso Cubado
	aCols[nPosLinha,nPxVALOR ]	:= Val(oTotal:_ICMSTot:_vNF:TEXT)											//	Valor

	aTotRdpe[1][1]++
	aTotRdpe[1][2]				+= Val(oTotal:_ICMSTot:_vNF:TEXT)
	aTotRdpe[1][3]				+= IIf(Type("oTransp:_vol:_pesoB") <> "U",Val(oTransp:_vol:_pesoB:TEXT),0)

	aCols[nPosLinha,nPxEDI   ]	:= "2"
	aCols[nPosLinha,nPxNFENTR]	:= "2"
	aCols[nPosLinha,nPxNFEID ]	:= cChave																	//	Chave NF-e

	oMulti:oBrowse:Refresh()

Return .T.



/*/{Protheus.doc} sfAvalSA1
(Avalia o Cadastro de cliente conforme parametros    )
@type function
@author marce
@since 04/03/2017
@version 1.0
@param cCnpj, character, (Descrição do parâmetro)
@param cTpess, character, (Descrição do parâmetro)
@param cNomeCli, character, (Descrição do parâmetro)
@param cNRedCli, character, (Descrição do parâmetro)
@param cTipoCli, character, (Descrição do parâmetro)
@param cEndCli, character, (Descrição do parâmetro)
@param cMunCli, character, (Descrição do parâmetro)
@param cEstCli, character, (Descrição do parâmetro)
@param cBaiCli, character, (Descrição do parâmetro)
@param cCepCli, character, (Descrição do parâmetro)
@param cDDDCli, character, (Descrição do parâmetro)
@param cTelCli, character, (Descrição do parâmetro)
@param cFaxCli, character, (Descrição do parâmetro)
@param cInsCli, character, (Descrição do parâmetro)
@param cRegiao, character, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAvalSA1(cCnpj,cTpess,cNomeCli,cNRedCli,cTipoCli,cEndCli,cMunCli,cEstCli,cBaiCli,cCepCli,cDDDCli,cTelCli,cFaxCli,cInsCli,cRegiao,cCodMun)
	Local	lRet		:= .F.
	Local	aAreaOld	:= GetArea()
	IF Empty(cInsCli)
		cInsCli:='000000000'   //ajuste feito pois xml da Deuqech esta vindo com a Inscrição estadual em branca para o destinatário 17/02
	EndIF


	dbSelectArea("SA1")
	dbSetOrder(3)
	If dbSeek(xFilial("SA1")+cCnpj)
		lRet	:= .T.
	Else

		aCliente := {{"A1_PESSOA"  	  	,cTpess            	,Nil},; // TIPO DO CLIENTE
		{"A1_CGC"   	  	,cCnpj          	,Nil},; // ENDERECO COBRANCA
		{"A1_NOME"  	  	,cNomeCli        	,Nil},; // NOME DO CLIENTE
		{"A1_NREDUZ"  	  	,cNredCli        	,Nil},; // NOME REDUZIDO
		{"A1_TIPO"  	  	,cTipoCli        	,Nil},; // Nome do Cliente
		{"A1_END"  	  		,cEndCli         	,Nil},; // ENDERECO
		{"A1_EST"  	  		,cEstCli	    	,Nil},; // ESTADO
		{"A1_MUN"   	  	,cMunCli         	,Nil},; // MUNICIPIO
		{"A1_COD_MUN"		,Substr(cCodMun,3)	,Nil},; // CÓDIGO MUNICIPIO
		{"A1_BAIRRO"  	  	,cBaiCli         	,Nil},; // BAIRRO
		{"A1_CEP"   	  	,cCepCli	       	,Nil},; // CEP
		{"A1_DDD"   	  	,cDDDCli         	,Nil},; // DDD
		{"A1_TEL"   	  	,cTelCli         	,Nil},; // TELEFONE
		{"A1_FAX"  	  		,cFaxCli         	,Nil},; // FAX
		{"A1_INSCR"   	  	,cInsCli         	,Nil},; // IE
		{"A1_CDRDES"   	  	,cRegiao           	,Nil}}	// INSCRICAO

		lRet	:= sfGravaCLI()
	EndIf

	RestArea(aAreaOld)

Return lRet

/*/{Protheus.doc} GravaCLI
(Efetua gravação do novo cadastro de cliente)
@type function
@author marce
@since 04/03/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGravaCLI()

	Local	lRet		:= .F.
	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.
	DbSelectArea("SA1")
	DbSetOrder(1)

	Begin Transaction

		MSExecAuto({|x,y,z| mata030(x,y,z)},aCliente,3)//Inclusao

	End Transaction

	aCliente  := {}

	If lMsErroAuto
		MostraErro()
	Else
		lRet	:= .T.
	Endif

Return lRet


/*/{Protheus.doc} sfAtualCLI
(Efetua atualização do cadastro do cliente   )
@type function
@author marce
@since 04/03/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtualCLI()


	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.

	dbSelectArea("SA1")
	dbSetOrder(1)

	Begin Transaction

		MSExecAuto({|x,y,z| mata030(x,y,z)},aCliente,4)//Atualização

	End Transaction

	aCliente  := {}

	If lMsErroAuto
		MostraErro()
	Endif

Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³sfAvalRegiºAutor  ³Marcelo Lauschner   º Data ³  09/09/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Verifica se a região existe e força o cadastro             º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function sfAvalRegiao(cCep,cMun,cBai,cEnd,cUf,cCodMun)

	Local	cRegiao		:= Space(6)
	Local	lContinua	:= .F.


	cQry := " "
	cQry += "SELECT DUY_GRPVEN "
	cQry += "  FROM "+RetSqlName("DUY")
	cQry += " WHERE D_E_L_E_T_ = ' ' "
	cQry += "   AND DUY_CODMUN = '"+ Substr(cCodMun,3)+"'  "
	cQry += "   AND DUY_EST = '"+cUf+"' "
	cQry += "   AND DUY_CATGRP = '3' " // 3º NIVEL
	cQry += "   AND DUY_FILIAL = '" + xFilial("SZ9") + "' "

	TCQUERY cQry NEW ALIAS "QRW"
	If !Eof()
		cRegiao := QRW->DUY_GRPVEN
	Endif

	QRW->(DbCloseArea())

	If Empty(cRegiao)

		DEFINE MSDIALOG oDlg4 FROM 000,000 TO 300,400 OF oMainWnd PIXEL TITLE OemToAnsi("Dados para cadastrar nova Região")
		//@ 200,001 TO 500,395 DIALOG oDlg1 TITLE OemToAnsi("Percentual de Compras")
		@ 002,010 TO 135,190 of oDlg4 pixel
		@ 010,018 Say "Cep:"of oDlg4 pixel
		@ 010,050 Get cCep Size 30,10 of oDlg4 pixel
		@ 025,018 Say "Municipio" of oDlg4 pixel
		@ 025,050 Get cMun Size 60,10 of oDlg4 pixel
		@ 040,018 Say "Bairro:" of oDlg4 pixel
		@ 040,050 Get cBai Size 60,10 of oDlg4 pixel
		@ 055,018 Say "Endereco:" of oDlg4 pixel
		@ 055,050 Get cEnd Size 100,10 of oDlg4 pixel
		@ 070,018 Say "Uf" of oDlg4 pixel
		@ 070,050 Get cUf Size 20,10 of oDlg4 pixel
		@ 085,018 Say "Reg. Int.(Obrigatorio):" of oDlg4 pixel
		@ 085,090 MsGet cRegiao F3 "DUY" Size 30,10 of oDlg4 pixel
		@ 135,150 BUTTON "Continuar" SIZE 40,10 of oDlg4 pixel ACTION (lContinua := .T.,oDlg4:End())
		@ 135,110 BUTTON "Ignorar" SIZE 40,10 of oDlg4 pixel ACTION (lContinua := .F.,oDlg4:End())

		ACTIVATE MSDIALOG oDlg4 CENTERED

		If lContinua
			//TODO - Ajustar o que fazer ao onfirmar cadastro de região

		Endif
	Endif

Return(cRegiao)


/*/{Protheus.doc} RLTMSM02
(Função que valida a linha OK do getdados )
@type function
@author marce
@since 04/03/2017
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function RLTMSM02()

	sfAtuRodp()

Return .T.

/*/{Protheus.doc} sfGrava
(Insere os registros por execauto na rotina TMSA050 )
@type function
@author marce
@since 04/03/2017	
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfGrava()

	Local	nConta	:=  0
	Local	iX

	For iX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[iX,Len(oMulti:aHeader)+1]
			nConta++
		Endif
	Next

	cLoteDtc	:= sfCrialote(nConta)
	// Zero o contador novamente para agora contar os digitados
	nConta		:= 0

	ProcRegua(Len(oMulti:aCols))

	For iX := 1 To Len(oMulti:aCols)
		If !oMulti:aCols[iX,Len(oMulti:aHeader)+1]
			aItemDTC	:= {}
			oMulti:aCols[iX,nPxLOTNFC]	:= cLoteDtc

			IncProc()

			aCabDTC := {{"DTC_FILORI"   	,oMulti:aCols[iX,nPxFILORI]		,Nil},;
				{"DTC_LOTNFC"	,oMulti:aCols[iX,nPxLOTNFC]		,Nil},;
				{"DTC_DATENT"	,oMulti:aCols[iX,nPxDATENT]		,Nil},;
				{"DTC_CLIREM"	,oMulti:aCols[iX,nPxCLIREM]		,Nil},;
				{"DTC_LOJREM"	,oMulti:aCols[iX,nPxLOJREM]		,Nil},;
				{"DTC_CLIDES"	,oMulti:aCols[iX,nPxCLIDES]		,Nil},;
				{"DTC_LOJDES"	,oMulti:aCols[iX,nPxLOJDES]		,Nil},;
				{"DTC_DEVFRE"	,oMulti:aCols[iX,nPxDEVFRE]		,Nil},;
				{"DTC_CLIDEV"	,oMulti:aCols[iX,nPxCLIDEV]		,Nil},;
				{"DTC_LOJDEV"	,oMulti:aCols[iX,nPxLOJDEV]		,Nil},;
				{"DTC_CLICAL"	,oMulti:aCols[iX,nPxCLICAL]		,Nil},;
				{"DTC_LOJCAL"	,oMulti:aCols[iX,nPxLOJCAL]		,Nil},;
				{"DTC_TIPFRE"	,oMulti:aCols[iX,nPxTIPFRE]		,Nil},;
				{"DTC_SERTMS"	,oMulti:aCols[iX,nPxSERTMS]		,Nil},;
				{"DTC_TIPTRA"	,oMulti:aCols[iX,nPxTIPTRA]		,Nil},;
				{"DTC_SERVIC"	,oMulti:aCols[iX,nPxSERVIC]		,Nil},;
				{"DTC_CODNEG"	,oMulti:aCols[iX,nPxCODNEG]		,Nil},;
				{"DTC_TIPNFC"	,oMulti:aCols[iX,nPxTIPNFC]		,Nil},;
				{"DTC_SELORI"	,oMulti:aCols[iX,nPxSELORI]		,Nil},;
				{"DTC_CDRORI"	,oMulti:aCols[iX,nPxCDRORI]		,Nil},;
				{"DTC_CDRDES"	,oMulti:aCols[iX,nPxCDRDES]		,Nil},;
				{"DTC_CDRCAL"	,oMulti:aCols[iX,nPxCDRCAL]		,Nil},;
				{"DTC_DISTIV"	,oMulti:aCols[iX,nPxDISTIV]		,Nil},;
				{"DTC_OBS"		,oMulti:aCols[iX,nPxOBS]		,Nil}}


			aItens := {{"DTC_FILORI"   	,oMulti:aCols[iX,nPxFILORI]		,Nil},;
				{"DTC_LOTNFC"	,oMulti:aCols[iX,nPxLOTNFC]		,Nil},;
				{"DTC_NUMNFC"	,oMulti:aCols[iX,nPxNUMNFC]		,Nil},;
				{"DTC_SERNFC"	,oMulti:aCols[iX,nPxSERNFC]		,Nil},;
				{"DTC_CODPRO"	,oMulti:aCols[iX,nPxCODPRO]		,Nil},;
				{"DTC_CODEMB"	,oMulti:aCols[iX,nPxCODEMB]		,Nil},;
				{"DTC_EMINFC"	,oMulti:aCols[iX,nPxEMINFC] 	,Nil},;
				{"DTC_QTDVOL"	,oMulti:aCols[iX,nPxQTDVOL]		,Nil},;
				{"DTC_PESO"		,oMulti:aCols[iX,nPxPESO]		,Nil},;
				{"DTC_VALOR"	,oMulti:aCols[iX,nPxVALOR]		,Nil},;
				{"DTC_EDI"		,oMulti:aCols[iX,nPxEDI]		,Nil},;
				{"DTC_NFENTR"	,oMulti:aCols[iX,nPxNFENTR]		,Nil},;
				{"DTC_EMINFE"	,oMulti:aCols[iX,nPxEMINFE]		,Nil},;
				{"DTC_NFEID"	,oMulti:aCols[iX,nPxNFEID]		,Nil},;
				{"DTC_CTRDPC"	,oMulti:aCols[iX,nPxCTRDPC]		,Nil},;
				{"DTC_TIPANT"	,oMulti:aCols[iX,nPxTIPANT]		,Nil},;
				{"DTC_DPCEMI"	,oMulti:aCols[iX,nPxDPCEMI]		,Nil},;
				{"DTC_CTEANT"	,oMulti:aCols[iX,nPxCTEANT]		,Nil},;
				{"DTC_SERDPC"	,oMulti:aCols[iX,nPxSERDPC]		,Nil}}

			Aadd(aItemDTC,aClone(aItens))

			// Chama função que executa gravação
			If !stTmsa050(aCabDTC,aItemDTC)
				oMulti:aCols[iX,Len(oMulti:aHeader)+1]	:= .T.
				nConta++
			Endif

		Endif
	Next

	sfAtuLote(cLoteDTC,nConta)

Return sfAtuRodp()



/*/{Protheus.doc} sfCrialote
(Função que cria lote para a entrada de Documentos do Cliente)
@type function
@author marce
@since 04/03/2017
@version 1.0
@param nConta, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfCrialote(nConta)

	//Local cHora := substr(time(),1,2)+Substr(time(),4,2)

	If nConta > 0

		DbSelectArea("DTP")
		DbSetOrder(1)

		Begin Transaction

			aLote := {{"DTP_FILORI", cFilAnt,Nil},;
				{"DTP_DATLOT" ,dDataBase         ,Nil},;
				;//{"DTP_HORLOT" ,cHora             ,Nil},; Atualizacao 06/12/21 nao aceita mais o campo preenchido
				{"DTP_QTDLOT" ,nConta            ,Nil},;
				{"DTP_STATUS" ,"1"               ,Nil},;
				{"DTP_QTDDIG" ,0	             ,Nil},;
				{"DTP_TIPLOT" ,"3"               ,Nil}} // Tipo Lote Eletronico

			MSExecAuto({|x,y| TMSA170(x,y)},aLote,3)

		End Transaction
		DbSelectArea("DTP")
		DBGoBottom() // 06/12/2021 IAGO execauto nao esta posicionando no registro apos atualizacao
		cLoteDTC := DTP->DTP_LOTNFC
	EndIf
Return cLoteDTC


/*/{Protheus.doc} sfAtuLote
(Função que atualiza o lote depois de lançar os documentos de entrada)
@type function
@author marce
@since 04/03/2017
@version 1.0
@param cLoteDTC, character, (Descrição do parâmetro)
@param nConta, numérico, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function sfAtuLote(cLoteDTC,nConta)

	If nConta > 0

		DbSelectArea("DTP")
		DbSetOrder(1)
		DbSeek(xFilial("DTP")+cLoteDTC)

		Begin Transaction

			aLote := {{"DTP_FILORI",cFilAnt,Nil},;
				{"DTP_LOTNFC" ,cLoteDTC        ,Nil},;
				{"DTP_QTDLOT" ,nConta		   ,Nil},;
				{"DTP_STATUS" ,"2"			   ,Nil},;
				{"DTP_QTDDIG" ,nConta          ,Nil}}

			MSExecAuto({|x,y| TMSA170(x,y)},aLote,4)

		End Transaction


	Endif

Return

/*/{Protheus.doc} stTmsa050
(Executa função TMSA050 para lançar o Documento do Cliente)
@type function
@author marce
@since 04/03/2017
@version 1.0
@param aCabDTC, array, (Descrição do parâmetro)
@param aItemDTC, array, (Descrição do parâmetro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
Static Function stTmsa050(aCabDTC,aItemDTC)

	Local	aAreaOld := GetArea()

	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.

	Begin Transaction
		DbSelectArea("DTC")
		DbSetOrder(1)
		//
		// Parametros da TMSA050 (notas fiscais do cliente)
		// xAutoCab - Cabecalho da nota fiscal
		// xAutoItens - Itens da nota fiscal
		// xItensPesM3 - acols de Peso Cubado
		// xItensEnder - acols de Enderecamento
		// nOpcAuto - Opcao rotina automatica

		MSExecAuto({|u,v,x,y,z| TMSA050(u,v,x,y,z)},aCabDTC,aItemDTC,,,3)

		If lMsErroAuto
			MostraErro()
			DisarmTransaction()
			Break
		Endif

	End Transaction

	RestARea(aAreaOld)

Return lMsErroAuto
