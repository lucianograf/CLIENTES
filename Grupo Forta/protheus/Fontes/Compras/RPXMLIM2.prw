#Include "Protheus.ch"
#Include "Topconn.ch"
#Include "XmlxFun.ch"
//teste
/*======================================================================*\
|| #################################################################### ||
|| # Programa: NOR02A01                                               # ||
|| # Desc:     Importacao de Notas para tabelas auxiliares            # ||
|| # Autor:    Gustavo Henrique Baptista                              # ||
|| # Data:     07/08/2014                                             # ||
|| # Cliente:  		                                                  # ||     
|| #################################################################### ||
\*======================================================================*/

User Function RPXMLIM2(_cArq)
	Local lfor, lItens, _x
	Local cXml, cXml1
	Local oXml := Nil
	Local oXml1 := Nil
	Local nHdlMod, nHdlMod1
	Local cDir := "" //getmv("MV_DIRXML")
	Local aArquivos := {}//Directory( Alltrim(cDir)+"*.XML" )
	Local aArquivosTmp := {}
	Local cChTmp := ""
	Local cChTmp1 := ""
	Private _lGravado := .F.
	PUBLIC cChave := ""
	//Chama fun็ใo para receber por email os XML que deverใo ser importados.
	//U_saveAttach()
	//aArquivos := Directory( Alltrim(cDir)+"*.XML", "D" )
	//U_saveAttach()   

	cDir :=  Alltrim(GetMV("MV_ZDIRXML"))
	aArquivosTmp := Directory( Alltrim(cDir)+"*.XML" )
	
	/*
	//Verifico se existe a pasta temp e pasta processados. Caso nใo tenha eu crio as duas:
	If !ExistDir( Alltrim(cDir) )
		MakeDir( Alltrim(cDir) )
		If !ExistDir( Alltrim(cDir)+"Processados")
			MakeDir( Alltrim(cDir)+"Processados")
		EndIf
	EndIf
	*/
	
	For n := 1 to Len(aArquivosTmp)
		If Substr(aArquivosTmp[n,1],1,RAT('.',aArquivosTmp[n,1])-1) = UPPER(_cArq)
			aadd(aArquivos,aArquivosTmp[n]) //:= Directory( Alltrim(cDir)+_cArq+".XML", "D" )
		Else
			nHdlMod1 := FT_FUse(Alltrim(Alltrim(cDir)+aArquivosTmp[n,1]))

			If nHdlMod1 == -1
				conout("O arquivo de nome"+Alltrim(Alltrim(cDir)+aArquivosTmp[n,1])+"  nao pode ser aberto!!!.","Atencao")
				MsgAlert("O arquivo de nome"+Alltrim(Alltrim(cDir)+aArquivosTmp[n,1])+"  nao pode ser aberto!")
				Return
			Endif
	
			// Varro o arquivo Modelo e vou alimentando o novo arquivo.
			/////////////////////////////////////////////////////////////////////////////
			cXml1 := ""
			FT_FGOTOP()
			While !FT_FEOF()
				cXml1 += FT_FREADLN()
				FT_FSKIP()
			EndDo
			FT_FUSE()
	
			cAviso1	:= ""
			cErro1	:= ""
			oXml1	:= XmlParser(cXml1,"_",@cAviso1,@cErro1)					
			
			If !Empty(cAviso1)
				conout(">>> Falha ("+Alltrim(cAviso1)+") na cria็ใo do XML!!!")
				MsgAlert(">>> Falha ("+Alltrim(cAviso1)+") na cria็ใo do XML!!!")
				Return
			EndIf
			If !Empty(cErro1)
				conout(">>> Falha ("+Alltrim(cErro1)+") na cria็ใo do XML!!!")
				MsgAlert(">>> Falha ("+Alltrim(cErro1)+") na cria็ใo do XML!!!")
				Return
			EndIf
			
			//Verifico 	se foi possivel criar o objeto oXML
			///////////////////////////////////////////////////
			If (oXml1 == Nil)
				conout(">>> Arquivo XML ("+Alltrim(aArquivosTmp[n,1])+") invalido!!!")
				MsgAlert(">>> Arquivo XML ("+Alltrim(aArquivosTmp[n,1])+") invalido!!!")
				Return
			Endif
	
			If XmlChildEx ( oXml1,"_NFEPROC") <> NIL
				cChTmp1 := oXml1:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT
			elseIF XmlChildEx ( oXml1,"_CTEPROC") <> NIL
				cChTmp1 := oXml1:_CTEPROC:_PROTCTE:_INFPROT:_CHCTE:TEXT
			EndIf
			
			If cChTmp1 == _cArq
				aadd(aArquivos,aArquivosTmp[n])
				_cArq := Substr(aArquivosTmp[n,1],1,RAT('.',aArquivosTmp[n,1])-1)
			EndIf
		EndIf
	Next n
	
	//aadd(aArquivos,_cArq)

	conout("Inicio da rotina que grava os XML nas tabelas auxiliares. Dir:"+cDir)
	for lfor := 1 to Len(aArquivos)

		nHdlMod := FT_FUse(Alltrim(Alltrim(cDir)+aArquivos[lfor,1]))

		If nHdlMod == -1
			conout("O arquivo de nome"+Alltrim(Alltrim(cDir)+aArquivos[lfor,1])+"  nao pode ser aberto!!!.","Atencao")
			MsgAlert("O arquivo de nome"+Alltrim(Alltrim(cDir)+aArquivos[lfor,1])+"  nao pode ser aberto!!!.")
			Return
		Endif

		// Varro o arquivo Modelo e vou alimentando o novo arquivo.
		/////////////////////////////////////////////////////////////////////////////
		cXml := ""
		FT_FGOTOP()
		While !FT_FEOF()
			Incproc(">>> Lendo arquivo XML...")
			cXml += FT_FREADLN()
			FT_FSKIP()
		EndDo
		FT_FUSE()

		cAviso	:= ""
		cErro	:= ""
		oXml	:= XmlParser(cXml,"_",@cAviso,@cErro)					

		If !Empty(cAviso)
			conout(">>> Falha ("+Alltrim(cAviso)+") na cria็ใo do XML!!!")
			MsgAlert(">>> Falha ("+Alltrim(cAviso)+") na cria็ใo do XML!!!")
			Return
		EndIf
		If !Empty(cErro)
			conout(">>> Falha ("+Alltrim(cErro)+") na cria็ใo do XML!!!")
			MsgAlert(">>> Falha ("+Alltrim(cErro)+") na cria็ใo do XML!!!")
			Return
		EndIf

		//Verifico 	se foi possivel criar o objeto oXML
		///////////////////////////////////////////////////
		If (oXml == Nil)
			conout(">>> Arquivo XML ("+Alltrim(aArquivos[lFor,1])+") invalido!!!")
			MsgAlert(">>> Arquivo XML ("+Alltrim(aArquivos[lFor,1])+") invalido!!!")
			Return
		Endif

		//If Alltrim(cChTmp) == Alltrim(_cArq) //Verifico dentro do arquivo se a chave do XML ้ a mesma

			//Verifica se o arquivo ้ de CTE ou NFE
			If XmlChildEx ( oXml,"_NFEPROC") <> NIL
				cChTmp := oXml:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT
				Processa( { || NOR02NFE(oXml) })
			elseIF XmlChildEx ( oXml,"_CTEPROC") <> NIL
				cChTmp := oXml:_CTEPROC:_PROTCTE:_INFPROT:_CHCTE:TEXT
				Processa( { || NOR02CTE(oXml) })
			elseif XmlChildEx ( oXml,"_procEventoCTe") <> NIL
				Processa( { || NOR02CAN(oXml) })
			endif

			If _lGravado == .T.
				If __CopyFile( Alltrim(cDir)+ Alltrim(aArquivos[lFor,1]) , Alltrim(cDir)+ "Processados\" + Alltrim(_cArq)+".XML")
					//Deleta arquivo ap๓s copiado
					FERASE(Alltrim(cDir)+ Alltrim(aArquivos[lFor,1]) )  
				EndIF
			EndIf

		//EndIf
	next
	conout("Fim da rotina de grava็ใo de tabelas auxiliares.")
Return cChTmp

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ NOR02NFEบAutor  ณ Gustavo Baptista    บ Data ณ             บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao que le o XML e Grava nas tabelas auxiliares	      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ NOR02A01                                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function NOR02NFE(oXml)
	***************************
	Local aItem :={}
	Local nICMS:= 0
	Local nIPI := 0 
	Local nAliIPI := 0
	Local bICMSST := 0
	Local vICMSST := 0
	Local nBaseST := 0
	Local nValST  := 0
	Local vDesc   := 0
	Local vOutro  := 0
	Local vFrete  := 0
	Local vSeg	  := 0
	Local cCst    := 0
	Private lReturn := .F.
	//Crio objeto XML com o conteudo do arquivo
	
	if XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_EMIT,"_CNPJ") <> NIL
  		cCgcFor		:= oXml:_NFEPROC:_NFE:_INFNFE:_EMIT:_CNPJ:TEXT
	Elseif XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_EMIT,"_CPF") <> NIL
	cCgcFor		:= oXml:_NFEPROC:_NFE:_INFNFE:_EMIT:_CPF:TEXT
  	EndIF
	cCgcDest    := oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_CNPJ:TEXT
	cDoc:= ""
	dEmissao:=""
	if XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_IDE,"_DEMI") <> NIL
		dEmissao	:= Stod(StrTran(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_DEMI:TEXT,"-",""))
		cDoc		:= StrZero(Val(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NNF:TEXT),9)
	elseif XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_IDE,"_DHEMI") <> NIL
		dEmissao	:= Stod(StrTran(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_DHEMI:TEXT,"-",""))
		cDoc		:= StrZero(Val(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_CNF:TEXT),9)
		if XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_IDE,"_NNF") <> NIL
			cDoc		:= StrZero(Val(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_nNF:TEXT),9)
		endif
	endif
	cSerie		:= Padr(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_SERIE:TEXT,3)
	cChave      := oXml:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT

	if XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL,"_ICMSTOT") <> NIL
		nBaseST:= Val(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_vBCST:TEXT)
		nValST := Val(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_vST:TEXT)
	endif

	nItens:=0
	aItem :={}
	// Busco os itens da pre-nota direto no objetivo XML.
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	If ValType(oxml:_NFEPROC:_NFE:_INFNFE:_DET) == "A"
		For _x := 1 To Len(oxml:_NFEPROC:_NFE:_INFNFE:_DET)
			cProdFor	:= oxml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_CPROD:TEXT
			nQtdItem	:= Val(oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_QCOM:TEXT)
			nVUnit		:= Val(oxml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_VUNCOM:TEXT)
			nTotItem	:= (nQtdItem * nVUnit)
			cDesc		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_XPROD:TEXT
			cNCM		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_NCM:TEXT

			If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD,"_VDESC")<>Nil)
				vDesc		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_VDESC:TEXT
			endif

			If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD,"_VOUTRO")<>Nil)
				vOutro		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_VOUTRO:TEXT
			endif
			If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD,"_VFRETE")<>Nil)
				vFrete		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_VFRETE:TEXT
			endif
			If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD,"_VSEG")<>Nil)
				vSeg		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_PROD:_VSEG:TEXT
			endif

			oIpi		:= oXml
			oIcms		:= oXml
			nICMS	:= 0
			pICMS	:= 0
			pICMSST := 0
			bICMSST	:= 0
			vICMSST	:= 0
			nBasICM := 0
			//Verifica se hแ algum tipo de ICMS
			If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_IMPOSTO,"_ICMS")<>Nil)
				oIcms := XmlGetChild(oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_IMPOSTO:_ICMS,1)
				If(XmlChildEx ( oIcms,"_VICMS")<>Nil)
					nICMS:= Val(oIcms:_VICMS:TEXT)
					pICMS:= Val(oIcms:_PICMS:TEXT)
					nBasICM := Val(oIcms:_VBC:TEXT)
					cCst	:= Val(oIcms:_CST:TEXT)
				EndIf
				If(XmlChildEx ( oIcms,"_PICMSST")<>Nil)
					pICMSST := Val(oIcms:_PICMSST:TEXT)
					vICMSST := Val(oIcms:_VICMSST:TEXT)
					bICMSST := Val(oIcms:_vBCST:TEXT)
					cCst	:= Val(oIcms:_CST:TEXT)
				EndIf
				If(XmlChildEx ( oIcms,"_CSOSN")<>Nil)
					cCst	:= 090
				EndIf
			EndIf
			//Verifica de hแ algum tipo de IPI
			If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_IMPOSTO,"_IPI")<>Nil)

				oIpi := XmlGetChild(oXml:_NFEPROC:_NFE:_INFNFE:_DET[_x]:_IMPOSTO:_IPI,2)
				//Verifica se hแ IPI
				If(XmlChildEx ( oIpi ,"_VIPI")<>Nil)
					nIPI:= Val(oIpi:_VIPI:TEXT)
					nAliIPI := Val(oIpi:_PIPI:TEXT)
				Else
					nIPI:= 0
				EndIf
			Else
				nIPI:= 0
				nAliIPI := 0
			EndIF
			aadd(aItem, {{cProdFor	},;
			{nQtdItem	},;
			{nVUnit    	},;
			{nTotItem 	},;
			{cDesc 	},;
			{cNCM  	},;
			{nICMS 	},;
			{bICMSST},;
			{vICMSST},;
			{nIPI 	},;
			{nBasICM},;
			{pICMS},;
			{PICMSST},;
			{vDesc},;
			{vOutro},;
			{vFrete},;
			{vSeg},;
			{cCst},;
			{nAliIPI}})
		Next _x
	Else
		cProdFor	:= oxml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_CPROD:TEXT
		nQtdItem	:= Val(oxml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_QCOM:TEXT)
		nVUnit		:= Val(oxml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VUNCOM:TEXT)
		nTotItem	:= (nQtdItem * nVUnit)
		// Variaveis novas -- Rodrigo Nogueira de Lima -------------------------------
		cDesc		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_XPROD:TEXT
		cNCM		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_NCM:TEXT

		If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD,"_VDESC")<>Nil)
			vDesc		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VDESC:TEXT
		endif

		If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD,"_VOUTRO")<>Nil)
			vOutro		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VOUTRO:TEXT
		endif

		If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD,"_VFRETE")<>Nil)
			vFrete		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VFRETE:TEXT
		endif

		If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD,"_VSEG")<>Nil)
			vSeg		:= oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VSEG:TEXT
		endif

		oIpi		:= oXml
		oIcms		:= oXml 
		oIcmsST		:= oXml 
		nICMS	:= 0
		pICMS	:= 0
		pICMSST := 0
		bICMSST	:= 0
		vICMSST	:= 0
		nBasICM := 0
		cCst:=0
		//Verifica se hแ algum tipo de ICMS
		If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO,"_ICMS")<>Nil)
			oIcms := XmlGetChild(oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_ICMS,1)
			//Verifica se ICMS
			If(XmlChildEx ( oIcms,"_VICMS")<>Nil)
				nICMS:= Val(oIcms:_VICMS:TEXT)
				pICMS:= Val(oIcms:_PICMS:TEXT)
				nBasICM := Val(oIcms:_VBC:TEXT)
				cCst	:= Val(oIcms:_CST:TEXT)
			EndIf
			If(XmlChildEx ( oIcms,"_PICMSST")<>Nil)
				pICMSST := Val(oIcms:_PICMSST:TEXT)
				vICMSST := Val(oIcms:_VICMSST:TEXT)
				bICMSST := Val(oIcms:_vBCST:TEXT)
				cCst	:= Val(oIcms:_CST:TEXT)
			endif
		EndIf
		//Verifica de hแ algum tipo de IPI
		If (XmlChildEx ( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO,"_IPI")<>Nil)

			oIpi := XmlGetChild(oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_IPI,2)
			//Verifica se hแ IPI
			If(XmlChildEx ( oIpi ,"_VIPI")<>Nil)
				nIPI :=	Val(oIpi:_VIPI:TEXT)
				nAliIPI := Val(oIpi:_PIPI:TEXT)
			Else
				nIPI := 0
				nAliIPI := 0
			EndIf
		Else
			nIPI := 0
		EndIF
		aadd(aItem, 	{{cProdFor	},;
		{nQtdItem	},;
		{nVUnit    	},;
		{nTotItem 	},;
		{cDesc 	},;
		{cNCM  	},;
		{nICMS 	},;
		{bICMSST},;
		{vICMSST},;
		{nIPI 	},;
		{nBasICM},;
		{pICMS},;
		{pICMSST},;
		{vDesc},;
		{vOutro},;
		{vFrete},;
		{vSeg},;
		{cCst},;
		{nAliIPI}})
	EndIf

	//Grava as tabelas auxiliares
	dbselectarea("ZZ3")
	dbsetorder(1)
	if !dbseek(xFilial("ZZ3")+Padr(Alltrim(cChave),TamSx3("ZZ3_CHV")[1])+Padr(Alltrim(cDoc),TamSx3("ZZ3_DOC")[1])+Alltrim(cSerie))
		reclock("ZZ3",.T.)
		ZZ3->ZZ3_FILIAL	:= xFilial("ZZ3")
		ZZ3->ZZ3_CHV	:= Alltrim(cChave)
		ZZ3->ZZ3_DOC	:= Alltrim(cDoc)
		ZZ3->ZZ3_SERIE	:= Alltrim(cSerie)
		ZZ3->ZZ3_EMISS	:= dEmissao //CtoD(SubStr(dEmissao,5,2)+"/"+SubStr(dEmissao,7,2)+"/"+SubStr(dEmissao,1,4))
		ZZ3->ZZ3_CGC	:= Alltrim(cCgcFor)
		ZZ3->ZZ3_CGCDES := Alltrim(cCgcDest)
		ZZ3->ZZ3_TIPO	:= "NFE"
		ZZ3->ZZ3_BCST	:= nBaseST
		ZZ3->ZZ3_VCST	:= nValST
		msunlock()  
		conout("Tabela zz3 gravada. Chave:"+Alltrim(cChave))
		dbclosearea()
		for lItens := 1 to Len(aItem)
			reclock("ZZ4",.T.)
			ZZ4->ZZ4_FILIAL	:= xFilial("ZZ4")
			ZZ4->ZZ4_CHV	:= Alltrim(cChave)
			ZZ4->ZZ4_ITEM	:= lItens
			ZZ4->ZZ4_CODPRO	:= aItem[lItens,1,1]
			ZZ4->ZZ4_QTD	:= aItem[lItens,2,1]
			ZZ4->ZZ4_VUNIT	:= aItem[lItens,3,1]
			ZZ4->ZZ4_TOTAL	:= aItem[lItens,4,1]
			ZZ4->ZZ4_DESPRD	:= aItem[lItens,5,1]
			//ZZ4->ZZ4_NCM	:= aItem[lItens,6,1]
			if Valtype(aItem[lItens,6,1]) = 'N' 
				ZZ4->ZZ4_NCM	:= STR(aItem[lItens,6,1])
			else
				ZZ4->ZZ4_NCM	:= aItem[lItens,6,1]
			endif

			if Valtype(aItem[lItens,7,1]) = 'C'
				ZZ4->ZZ4_ICMS	:= Val(aItem[lItens,7,1])
				ZZ4_BICM		:= Val(aItem[lItens,11,1])
				ZZ4_PICM		:= Val(aItem[lItens,12,1])
				ZZ4_PICMST		:= vAL(aItem[lItens,13,1])
			else
				ZZ4->ZZ4_ICMS	:= aItem[lItens,7,1]
				ZZ4_BICM		:= aItem[lItens,11,1]
				ZZ4_PICM		:= aItem[lItens,12,1]
				ZZ4_PICMST		:= aItem[lItens,13,1]
			endif

			if Valtype(aItem[lItens,8,1]) = 'C' 
				ZZ4->ZZ4_BCST	:= Val(aItem[lItens,8,1])
				ZZ4->ZZ4_VCST	:= Val(aItem[lItens,9,1])
			else
				ZZ4->ZZ4_BCST	:= aItem[lItens,8,1]
				ZZ4->ZZ4_VCST	:= aItem[lItens,9,1]
			endif

			if ValType(aItem[lItens,10,1]) = 'C' 
				ZZ4->ZZ4_IPI	:= Val(aItem[lItens,10,1])
				ZZ4->ZZ4_PIPI	:= Val(aItem[lItens,19,1])
			else
				ZZ4->ZZ4_IPI	:= aItem[lItens,10,1]
				ZZ4->ZZ4_PIPI	:= aItem[lItens,19,1]
			endif

			if ValType(aItem[lItens,14,1]) = 'C' 
				ZZ4->ZZ4_DESC	:= Val(aItem[lItens,14,1])
			else
				ZZ4->ZZ4_DESC	:= aItem[lItens,14,1]
			endif

			if ValType(aItem[lItens,15,1]) = 'C' 
				ZZ4->ZZ4_OUTROS	:= Val(aItem[lItens,15,1])
			else
				ZZ4->ZZ4_OUTROS	:= aItem[lItens,15,1]
			endif

			if ValType(aItem[lItens,16,1]) = 'C' 
				ZZ4->ZZ4_VALFRE	:= Val(aItem[lItens,16,1])
			else
				ZZ4->ZZ4_VALFRE	:= aItem[lItens,16,1]
			endif

			if ValType(aItem[lItens,17,1]) = 'C' 
				ZZ4->ZZ4_VALSEG	:= Val(aItem[lItens,17,1])
			else
				ZZ4->ZZ4_VALSEG	:= aItem[lItens,17,1]
			endif

			if ValType(aItem[lItens,18,1]) = 'C' 
				ZZ4->ZZ4_CST	:= aItem[lItens,18,1]
			else
				ZZ4->ZZ4_CST	:= Str(aItem[lItens,18,1])
			endif

			msunlock()
		next
		dbclosearea()
		_lGravado := .T.
	Endif
Return 
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ 3บAutor  ณ Gustavo Baptista    บ Data ณ             บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao que le o XML e Marca o conhecimento como cancelado  บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ NOR02CAN                                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function NOR02CAN(oXml)
	***************************
	cChaveDoc := oXml:_procEventoCte:_eventoCTE:_infEvento:_chCTe:TEXT
	/*
	dbselectarea("ZZ3")
	dbsetorder(1)
	if dbseek(xFilial+cChaveDoc)
	reclock("ZZ3",.F.)
	ZZ3_CANCE := .T.
	msunlock()
	endif
	*/
Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ 3บAutor  ณ Gustavo Baptista    บ Data ณ             บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Funcao que le o XML e Grava nas tabelas auxiliares	      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ NOR02A01                                                   บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function NOR02CTE(oXml)
	***************************
	Local cProdCte := Alltrim(GetMV("MV_ZCTEXML"))
	cCgcFor		:= oXml:_CTEPROC:_CTE:_INFCTE:_EMIT:_CNPJ:TEXT
	dEmissao	:= Stod(StrTran(oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_DHEMI:TEXT,"-",""))
	cDoc		:= StrZero(Val(oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_NCT:TEXT),9)
	cSerie		:= Padr(oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_SERIE:TEXT,3)
	cChave      := oXml:_CTEPROC:_PROTCTE:_INFPROT:_CHCTE:TEXT
	nQtdItem	:= 1
	nVUnit		:= Val(oxml:_CTEPROC:_CTE:_INFCTE:_VPREST:_VTPREST:TEXT)
	nTotItem	:= Val(oxml:_CTEPROC:_CTE:_INFCTE:_VPREST:_VTPREST:TEXT)
	oIpi		:= oXml
	oIcms		:= oXml
	
	//Verifica se hแ algum tipo de ICMS
	If (XmlChildEx ( oXml:_CTEPROC:_CTE:_INFCTE:_IMP,"_ICMS")<>Nil)
		oIcms := XmlGetChild(oXml:_CTEPROC:_CTE:_INFCTE:_IMP:_ICMS,1)
		//Verifica se ICMS
		If(XmlChildEx ( oIcms,"_VICMS")<>Nil)
			nICMS:= oIcms:_VICMS:TEXT
		Else
			nICMS := 0
		EndIf
	Else
		nICMS := 0
	EndIf              
	//Verifica de hแ algum tipo de IPI
	If (XmlChildEx ( oXml:_CTEPROC:_CTE:_INFCTE:_IMP,"_IPI")<>Nil)
		oIpi := XmlGetChild(oXml:_CTEPROC:_CTE:_INFCTE:_IMP:_IPI,2)
		//Verifica se hแ IPI
		If(XmlChildEx ( oIpi ,"_VIPI")<>Nil)
			nIPI:= oIpi:_VIPI:TEXT
		Else
			nIPI:= 0
		EndIf
	Else
		nIPI:= 0
	EndIF
	//Deve ser definido o produto padrใo do cliente para frete... Caso tenha mais de um, deverแ ser criado as condi็๕es.
	DbSelectArea("SB1")
	SB1->(DbSetOrder(1))
	If SB1->(DbSeek(xFilial("SB1")+PADR(cProdCte,TamSX3("B1_COD")[1])))
		cNCM 		:= ""
		cProdFor 	:= PADR(cProdCte,TamSX3("B1_COD")[1])
		cDesc		:= Posicione("SB1",1,xFilial("SB1")+cProdFor,"B1_DESC")
	Else
		MsgAlert("ษ necessแrio verificar o produto frete no parโmetro MV_ZCTEXML. A importa็ใo nใo continuarแ.")
		Return
	EndIf
	//Grava as tabelas auxiliares
	dbselectarea("ZZ3")
	dbsetorder(1)
	if !dbseek(xFilial("ZZ3")+Padr(Alltrim(cChave),TamSx3("ZZ3_CHV")[1])+Padr(Alltrim(cDoc),TamSx3("ZZ3_DOC")[1])+Alltrim(cSerie))
		reclock("ZZ3",.T.)
		ZZ3->ZZ3_FILIAL	:= xFilial("ZZ3")
		ZZ3->ZZ3_CHV	:= Alltrim(cChave)
		ZZ3->ZZ3_DOC	:= Alltrim(cDoc)
		ZZ3->ZZ3_SERIE	:= Alltrim(cSerie)
		ZZ3->ZZ3_EMISS	:= dEmissao//CtoD(DtoC(dEmissao))//CtoD(SubStr(dEmissao,5,2)+"/"+SubStr(dEmissao,7,2)+"/"+SubStr(dEmissao,1,4))
		ZZ3->ZZ3_CGC	:= Alltrim(cCgcFor)
		ZZ3->ZZ3_TIPO	:= "CTE"
		msunlock()
		conout("Tabela zz3 gravada. Chave:"+Alltrim(cChave))
		dbclosearea()
		//
		reclock("ZZ4",.T.)
		ZZ4->ZZ4_FILIAL	:= xFilial("ZZ4")
		ZZ4->ZZ4_CHV	:= Alltrim(cChave)
		ZZ4->ZZ4_ITEM	:= 1
		ZZ4->ZZ4_CODPRO	:= cProdFor
		ZZ4->ZZ4_QTD	:= nQtdItem
		ZZ4->ZZ4_VUNIT	:= nVUnit
		ZZ4->ZZ4_TOTAL	:= nTotItem
		ZZ4->ZZ4_DESPRD	:= cDesc
		if Valtype(cNCM) = 'N' 
			ZZ4->ZZ4_NCM	:= STR(cNCM)
		else
			ZZ4->ZZ4_NCM	:= cNCM
		endif

		if Valtype(nICMS) = 'C' 
			ZZ4->ZZ4_ICMS	:= Val(nICMS)
		else
			ZZ4->ZZ4_ICMS	:= nICMS
		endif    

		if Valtype(nIPI) = 'C' 
			ZZ4->ZZ4_IPI	:= Val(nIPI)
		else
			ZZ4->ZZ4_IPI	:= nIPI
		endif
		msunlock()
		dbclosearea()
	Endif
Return
